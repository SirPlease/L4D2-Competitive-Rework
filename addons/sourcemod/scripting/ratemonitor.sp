#pragma semicolon 1

#define L4D2UTIL_STOCKS_ONLY

#include <sourcemod>
#include <sdktools>
#include <l4d2util>
#include <colors>

#define STEAMID_SIZE  32

new Handle:hCvarAllowedRateChanges;
new Handle:hCvarMinRate;
new Handle:hCvarMinUpd;
new Handle:hCvarMinCmd;
new Handle:hCvarProhibitFakePing;
new Handle:hCvarProhibitedAction;
new Handle:hClientSettingsArray;
new Handle:hCvarPublicNotice;

new iAllowedRateChanges;
new iMinRate;
new iMinUpd;
new iMinCmd;
new iActionUponExceed;

new bool:bPublic;
new bool:bProhibitFakePing;
new bool:bIsMatchLive = false;

enum NetsettingsStruct {
    String:Client_SteamId[STEAMID_SIZE],
    Client_Rate,
    Client_Cmdrate,
    Client_Updaterate,
    Client_Changes
};

public Plugin:myinfo =
{
    name = "RateMonitor",
    author = "Visor, Sir",
    description = "Keep track of players' netsettings",
    version = "2.2.1",
    url = "https://github.com/Attano/smplugins"
};

public OnPluginStart()
{
    hCvarAllowedRateChanges = CreateConVar("rm_allowed_rate_changes", "-1", "Allowed number of rate changes during a live round(-1: no limit)");
    hCvarPublicNotice = CreateConVar ("rm_public_notice", "0", "Print Rate Changes to the Public? (rm_countermeasure 1 and 3 will still be Public Notice)");
    hCvarMinRate = CreateConVar("rm_min_rate", "20000", "Minimum allowed value of rate(-1: none)");
    hCvarMinUpd = CreateConVar("rm_min_upd", "20", "Minimum allowed value of cl_updaterate(-1: none)");
    hCvarMinCmd = CreateConVar("rm_min_cmd", "20", "Minimum allowed value of cl_cmdrate(-1: none)");
    hCvarProhibitFakePing = CreateConVar("rm_no_fake_ping", "0", "Allow or disallow the use of + - . in netsettings, which is commonly used to hide true ping in the scoreboard.");
    hCvarProhibitedAction = CreateConVar("rm_countermeasure", "2", "Countermeasure against illegal actions - change overlimit/forbidden netsettings(1:chat notify,2:move to spec,3:kick)", FCVAR_NONE, true, 1.0, true, 3.0);
    
    iAllowedRateChanges = GetConVarInt(hCvarAllowedRateChanges);
    iMinRate = GetConVarInt(hCvarMinRate);
    iMinUpd = GetConVarInt(hCvarMinUpd);
    iMinCmd = GetConVarInt(hCvarMinCmd);
    bProhibitFakePing = GetConVarBool(hCvarProhibitFakePing);
    iActionUponExceed = GetConVarInt(hCvarProhibitedAction);
    bPublic = GetConVarBool(hCvarPublicNotice);

    HookConVarChange(hCvarAllowedRateChanges, cvarChanged_AllowedRateChanges);
    HookConVarChange(hCvarMinRate, cvarChanged_MinRate);
    HookConVarChange(hCvarMinCmd, cvarChanged_MinCmd);
    HookConVarChange(hCvarProhibitFakePing, cvarChanged_ProhibitFakePing);
    HookConVarChange(hCvarProhibitedAction, cvarChanged_ExceedAction);
    HookConVarChange(hCvarPublicNotice, cvarChanged_PublicNotice);
    
    RegConsoleCmd("sm_rates", ListRates, "List netsettings of all players in game");
    
    HookEvent("player_team", OnTeamChange);
    
    hClientSettingsArray = CreateArray(_:NetsettingsStruct);
}

public OnRoundStart() 
{
    decl player[NetsettingsStruct];
    for (new i = 0; i < GetArraySize(hClientSettingsArray); i++) 
    {
        GetArrayArray(hClientSettingsArray, i, player[0]);
        player[Client_Changes] = _:0;
        SetArrayArray(hClientSettingsArray, i, player[0]);
    }
}

public Action:OnRoundIsLive() 
    bIsMatchLive = true;

public OnRoundEnd()
    bIsMatchLive = false;

public OnMapEnd()
    ClearArray(hClientSettingsArray);

public OnTeamChange(Handle:event, String:name[], bool:dontBroadcast)
{
    if (L4D2_Team:GetEventInt(event, "team") != L4D2Team_Spectator)
    {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (client > 0)
        {
            if (IsClientInGame(client) && !IsFakeClient(client))
                CreateTimer(0.1, OnTeamChangeDelay, client, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action:OnTeamChangeDelay(Handle:timer, any:client)
{
    RegisterSettings(client);
    return Plugin_Handled;
}

public OnClientSettingsChanged(client) 
{
    RegisterSettings(client);
}

public Action:ListRates(client, args) 
{
    decl player[NetsettingsStruct];
    new iClient;
    
    ReplyToCommand(client, "\x01[RateMonitor] List of player netsettings(\x03cmd\x01/\x04upd\x01/\x05rate\x01):");
    
    for (new i = 0; i < GetArraySize(hClientSettingsArray); i++) 
    {
        GetArrayArray(hClientSettingsArray, i, player[0]);
        
        iClient = GetClientBySteamId(player[Client_SteamId]);
        if (iClient < 0) continue;
        
        if (IsClientConnected(iClient) && !IsSpectator(iClient)) 
        {
            ReplyToCommand(client, "\x03%N\x01 : %d/%d/%d", iClient, player[Client_Cmdrate], player[Client_Updaterate], player[Client_Rate]);
        }
    }
    
    return Plugin_Handled;
}

RegisterSettings(client) 
{   
    if (!IsValidClient(client) || IsSpectator(client) || IsFakeClient(client)) 
        return;

    decl player[NetsettingsStruct];
    decl String:sCmdRate[32], String:sUpdateRate[32], String:sRate[32];
    decl String:sSteamId[STEAMID_SIZE];
    decl String:sCounter[32] = "";
    new iCmdRate, iUpdateRate, iRate;
    
    GetClientAuthId(client, AuthId_Steam2, sSteamId, STEAMID_SIZE);

    new iIndex = FindStringInArray(hClientSettingsArray, sSteamId);

    // rate
    iRate = GetClientDataRate(client);
    // cl_cmdrate
    GetClientInfo(client, "cl_cmdrate", sCmdRate, sizeof(sCmdRate));
    iCmdRate = StringToInt(sCmdRate);
    // cl_updaterate
    GetClientInfo(client, "cl_updaterate", sUpdateRate, sizeof(sUpdateRate));
    iUpdateRate = StringToInt(sUpdateRate);
   
    // Punish for fake ping or other unallowed symbols in rate settings
    if (bProhibitFakePing)
    {
        new bool:bIsCmdRateClean, bIsUpdateRateClean;
        
        bIsCmdRateClean = IsNatural(sCmdRate);
        bIsUpdateRateClean = IsNatural(sUpdateRate);

        if (!bIsCmdRateClean || !bIsUpdateRateClean) 
        {
            sCounter = "[bad cmd/upd]";
            Format(sCmdRate, sizeof(sCmdRate), "%s", sCmdRate);
            Format(sUpdateRate, sizeof(sUpdateRate), "%s", sUpdateRate);
            Format(sRate, sizeof(sRate), "%d", iRate);
            
            PunishPlayer(client, sCmdRate, sUpdateRate, sRate, sCounter, iIndex);
            return;
        }
    }
    
     // Punish for low rate settings(if we're good on previous check)
    if ((iCmdRate < iMinCmd && iMinCmd > -1) 
        || (iRate < iMinRate && iMinRate > -1)
        || (iUpdateRate < iMinUpd && iMinUpd > -1)
    ) {
        sCounter = "[low cmd/update/rate]";
        Format(sCmdRate, sizeof(sCmdRate), "%s%d%s", iCmdRate < iMinCmd ? ">" : "", iCmdRate, iCmdRate < iMinCmd ? "<" : "");
        Format(sUpdateRate, sizeof(sCmdRate), "%s%d%s", iUpdateRate < iMinUpd ? ">" : "", iUpdateRate, iUpdateRate < iMinUpd ? "<" : "");
        Format(sRate, sizeof(sRate), "%s%d%s", iRate < iMinRate ? ">" : "", iRate, iRate < iMinRate ? "<" : "");
        
        PunishPlayer(client, sCmdRate, sUpdateRate, sRate, sCounter, iIndex);
        return;
    }

    if (iIndex > -1) 
    {
        GetArrayArray(hClientSettingsArray, iIndex, player[0]);
        
        if (iRate == player[Client_Rate] && 
            iCmdRate == player[Client_Cmdrate] && 
            iUpdateRate == player[Client_Updaterate]
            )   return; // No change

        if (bIsMatchLive && iAllowedRateChanges > -1)
        {
            player[Client_Changes] += 1;
            Format(sCounter, sizeof(sCounter), "[%d/%d]", player[Client_Changes], iAllowedRateChanges);
            
            // If not punished for bad rate settings yet, punish for overlimit rate change(if any)
            if (player[Client_Changes] > iAllowedRateChanges)
            {
                Format(sCmdRate, sizeof(sCmdRate), "%s%d", iCmdRate != player[Client_Cmdrate] ? "*" : "", iCmdRate);
                Format(sUpdateRate, sizeof(sUpdateRate), "%s%d\x01", iUpdateRate != player[Client_Updaterate] ? "*" : "", iUpdateRate);
                Format(sRate, sizeof(sRate), "%s%d\x01", iRate != player[Client_Rate] ? "*" : "", iRate);
            
                PunishPlayer(client, sCmdRate, sUpdateRate, sRate, sCounter, iIndex);
                return;
            }
        }
        
        if (bPublic) CPrintToChatAllEx(client, "{default}<{olive}Rates{default}> {teamcolor}%N{default}'s netsettings changed from {teamcolor}%d/%d/%d {default}to {teamcolor}%d/%d/%d {olive}%s", 
                        client, 
                        player[Client_Cmdrate], player[Client_Updaterate], player[Client_Rate], 
                        iCmdRate, iUpdateRate, iRate,
                        sCounter);
                        
        player[Client_Cmdrate] = _:iCmdRate;
        player[Client_Updaterate] = _:iUpdateRate;
        player[Client_Rate] = _:iRate;
        
        SetArrayArray(hClientSettingsArray, iIndex, player[0]);
    }
    else
    {
        strcopy(player[Client_SteamId], STEAMID_SIZE, sSteamId);
        player[Client_Cmdrate] = _:iCmdRate;
        player[Client_Updaterate] = _:iUpdateRate;
        player[Client_Rate] = _:iRate;
        player[Client_Changes] = _:0;
        
        PushArrayArray(hClientSettingsArray, player[0]);
        if (bPublic) CPrintToChatAllEx(client, "{default}<{olive}Rates{default}> {teamcolor}%N{default}'s netsettings set to {teamcolor}%d/%d/%d", client, player[Client_Cmdrate], player[Client_Updaterate], player[Client_Rate]);
    }
}

PunishPlayer(client, const String:sCmdRate[], const String:sUpdateRate[], const String:sRate[], const String:sCounter[], iIndex)
{
    new bool:bInitialRegister = iIndex > -1 ? false : true;
    
    switch (iActionUponExceed)
    {
        case 1: // Just notify all players(zero punishment)
        {
            if (bInitialRegister) {
                CPrintToChatAllEx(client, "{default}<{olive}Rates{default}> {teamcolor}%N{default}'s netsettings set to illegal values: {teamcolor}%s/%s/%s {olive}%s", 
                                client, 
                                sCmdRate, sUpdateRate, sRate, 
                                sCounter);
            }
            else {
               CPrintToChatAllEx(client, "{default}<{olive}Rates{default}> {teamcolor}%N{default}'s illegaly changed netsettings midgame: {teamcolor}%s/%s/%s {olive}%s", 
                                client, 
                                sCmdRate, sUpdateRate, sRate, 
                                sCounter);
            }
        }
        case 2: // Move to spec
        {
            ChangeClientTeam(client, _:L4D2Team_Spectator);
            
            if (bInitialRegister) {
                if (bPublic) CPrintToChatAllEx(client, "{default}<{olive}Rates{default}> {teamcolor}%N {default}was moved to spectators for illegal netsettings: {teamcolor}%s/%s/%s {olive}%s", 
                                client, 
                                sCmdRate, sUpdateRate, sRate, 
                                sCounter);
                CPrintToChatEx(client, client, "{default}<{olive}Rates{default}> Please adjust your rates to values higher than {olive}%d/%d/%d%s", iMinCmd, iMinUpd, iMinRate, bProhibitFakePing ? " and remove any non-digital characters" : "");
            }
            else {
                decl player[NetsettingsStruct];
                GetArrayArray(hClientSettingsArray, iIndex, player[0]);
                
                if (bPublic) CPrintToChatAllEx(client, "{default}<{olive}Rates{default}> {teamcolor}%N {default}was moved to spectators for illegal netsettings: {teamcolor}%s/%s/%s {olive}%s", 
                                client, 
                                sCmdRate, sUpdateRate, sRate, 
                                sCounter);
                CPrintToChatEx(client, client, "{default}<{olive}Rates{default}> Change your netsettings back to: {teamcolor}%d/%d/%d", player[Client_Cmdrate], player[Client_Updaterate], player[Client_Rate]);
            }
        }
        case 3: // Kick
        {
            if (bInitialRegister) {
                KickClient(client, "Please use rates higher than %d/%d/%d%s", iMinCmd, iMinUpd, iMinRate, bProhibitFakePing ? " and remove any non-digits" : "");
                CPrintToChatAllEx(client, "{default}<{olive}Rates{default}> {teamcolor}%N {default}was kicked for illegal netsettings: {teamcolor}%s/%s/%s {olive}%s", 
                                client, 
                                sCmdRate, sUpdateRate, sRate, 
                                sCounter);
            }
            else {
                decl player[NetsettingsStruct];
                GetArrayArray(hClientSettingsArray, iIndex, player[0]);
                
                KickClient(client, "Change your rates to previous values and remove non-digits: %d/%d/%d", player[Client_Cmdrate], player[Client_Updaterate], player[Client_Rate]);
                CPrintToChatAllEx(client, "{default}<{olive}Rates{default}> {teamcolor}%N {default}was kicked due to illegal netsettings change: {teamcolor}%s/%s/%s {olive}%s", 
                                client, 
                                sCmdRate, sUpdateRate, sRate, 
                                sCounter);
            }
        }
    }
    return;
}

stock GetClientBySteamId(const String:steamID[]) 
{
    decl String:tempSteamID[STEAMID_SIZE];
    
    for (new client = 1; client <= MaxClients; client++) 
    {
        if (!IsClientInGame(client)) continue;
        
        GetClientAuthId(client, AuthId_Steam2, tempSteamID, STEAMID_SIZE);

        if (StrEqual(steamID, tempSteamID))
            return client;
    }
    
    return -1;
}

bool:IsSpectator(client) {
    new L4D2_Team:team = L4D2_Team:GetClientTeam(client);
    if (team != L4D2Team_Survivor && team != L4D2Team_Infected)
        return true;
    return false;
}

stock bool:IsNatural(const String:str[])
{   
    new x = 0;
    while (str[x] != '\0') 
    {
        if (!IsCharNumeric(str[x])) {
            return false;
        }
        x++;
    }

    return true;
}

public cvarChanged_AllowedRateChanges(Handle:cvar, const String:oldValue[], const String:newValue[])
    iAllowedRateChanges = GetConVarInt(hCvarAllowedRateChanges);

public cvarChanged_MinRate(Handle:cvar, const String:oldValue[], const String:newValue[])
    iMinRate = GetConVarInt(hCvarMinRate);
    
public cvarChanged_MinCmd(Handle:cvar, const String:oldValue[], const String:newValue[])
    iMinCmd = GetConVarInt(hCvarMinCmd);

public cvarChanged_ProhibitFakePing(Handle:cvar, const String:oldValue[], const String:newValue[])
    bProhibitFakePing = GetConVarBool(hCvarProhibitFakePing);
    
public cvarChanged_ExceedAction(Handle:cvar, const String:oldValue[], const String:newValue[])
    iActionUponExceed = GetConVarInt(hCvarProhibitedAction);

public cvarChanged_PublicNotice(Handle:cvar, const String:oldValue[], const String:newValue[])
    bPublic = GetConVarBool(hCvarPublicNotice);

bool:IsValidClient(client) 
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client)) return false; 
    return IsClientInGame(client); 
} 