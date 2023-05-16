#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>
#include <colors>

#define TEAM_SPECTATOR          1 
#define TEAM_SURVIVOR           2 
#define TEAM_INFECTED           3
#define FLAG_SPECTATOR          (1 << TEAM_SPECTATOR)
#define FLAG_SURVIVOR           (1 << TEAM_SURVIVOR)
#define FLAG_INFECTED           (1 << TEAM_INFECTED)

#define ZC_SMOKER               1
#define ZC_BOOMER               2
#define ZC_HUNTER               3
#define ZC_SPITTER              4
#define ZC_JOCKEY               5
#define ZC_CHARGER              6
#define ZC_WITCH                7
#define ZC_TANK                 8

#define BREV_SI                 1
#define BREV_CI                 2
#define BREV_FF                 4
#define BREV_RANK               8
//#define BREV_???              16
#define BREV_PERCENT            32
#define BREV_ABSOLUTE           64

#define CONBUFSIZE              1024
#define CONBUFSIZELARGE         4096

#define CHARTHRESHOLD           160         // detecting unicode stuff


/**
* Issues:
*  - Add damage received from common
*/

/*
Changelog
---------
0.2c
- added console output table for more stats, fixed it's display
- fixed console display to always display each player on the survivor team

0.1
- fixed common MVP ranks being messed up.
- finally worked in PluginEnabled cvar
- made FF tracking switch to enabled automatically if brevity flag 4 is unset
- fixed a bug that caused FF to always report as "no friendly fire" when tracking was disabled
- adjusted formatting a bit
- made FF stat hidden by default
- made convars actually get tracked (doh)
- added friendly fire tracking (sm_survivor_mvp_trackff 1/0)
- added brevity-flags cvar for changing verbosity of MVP report (sm_survivor_mvp_brevity bitwise, as shown)
- discount FF damage before match is live if RUP is active.
- fixed problem with clients disconnecting before mvp report
- improved consistency after client reconnect (name-based)
- fixed mvp stats double showing in scavenge (round starts)
- now shows if MVP is a bot
- cleaned up code
- fixed for scavenge, now shows stats for every scavenge round
- fixed damage/kills getting recorded for infected players, skewing MVP stats
- added rank display for non-MVP clients
*/
/*
Brevity flags:
1       leave out SI stats
2       leave out CI stats
4       leave out FF stats
8       leave out rank notification
16   (reserved)
32      leave out percentages
64      leave out absolutes

*/

public Plugin:myinfo =
{
    name = "Survivor MVP notification",
    author = "Tabun, Artifacial",
    description = "Shows MVP for survivor team at end of round",
    version = "0.3.1",
    url = "https://github.com/alexberriman/l4d2_survivor_mvp"
};


new     Handle:     hPluginEnabled =    INVALID_HANDLE;

new     Handle:     hCountTankDamage =  INVALID_HANDLE;         // whether we're tracking tank damage for MVP-selection
new     Handle:     hCountWitchDamage = INVALID_HANDLE;         // whether we're tracking witch damage for MVP-selection
new     Handle:     hTrackFF =          INVALID_HANDLE;         // whether we're tracking friendly-fire damage (separate stat)
new     Handle:     hBrevityFlags =     INVALID_HANDLE;         // how verbose/brief the output should be:
new     Handle:     hRUPActive =        INVALID_HANDLE;         // whether the ready up mod is active

new     bool:       bCountTankDamage;
new     bool:       bCountWitchDamage;
new     bool:       bTrackFF;
new                 iBrevityFlags;
new     bool:       bRUPActive;

new     String:     sClientName[MAXPLAYERS + 1][64];            // which name is connected to the clientId?

// Basic statistics
new                 iGotKills[MAXPLAYERS + 1];                  // SI kills             track for each client
new                 iGotCommon[MAXPLAYERS + 1];                 // CI kills
new                 iDidDamage[MAXPLAYERS + 1];                 // SI only              these are a bit redundant, but will keep anyway for now
new                 iDidDamageAll[MAXPLAYERS + 1];              // SI + tank + witch
new                 iDidDamageTank[MAXPLAYERS + 1];             // tank only
new                 iDidDamageWitch[MAXPLAYERS + 1];            // witch only
new                 iDidFF[MAXPLAYERS + 1];                     // friendly fire damage

// Detailed statistics
new                 iDidDamageClass[MAXPLAYERS + 1][ZC_TANK + 1];   // si classes
new                 timesPinned[MAXPLAYERS + 1][ZC_TANK + 1];   // times pinned
new                 totalPinned[MAXPLAYERS + 1];                // total times pinned
new                 pillsUsed[MAXPLAYERS + 1];                  // total pills eaten
new                 boomerPops[MAXPLAYERS + 1];                 // total boomer pops
new                 damageReceived[MAXPLAYERS + 1];             // Damage received

// Tank stats
new                tankSpawned = false;                        // When tank is spawned
new                 commonKilledDuringTank[MAXPLAYERS + 1];     // Common killed during the tank
new                 ttlCommonKilledDuringTank = 0;              // Common killed during the tank
new                 siDmgDuringTank[MAXPLAYERS + 1];            // SI killed during the tank
//new                 ttlSiDmgDuringTank = 0;                     // Total SI killed during the tank
new                tankThrow;                                  // Whether or not the tank has thrown a rock
new                 rocksEaten[MAXPLAYERS + 1];                 // The amount of rocks a player 'ate'.
new                 rockIndex;                                  // The index of the rock (to detect how many times we were rocked)
new                 ttlPinnedDuringTank[MAXPLAYERS + 1];        // The total times we were pinned when the tank was up


new                 iTotalKills;                                // prolly more efficient to store than to recalculate
new                 iTotalCommon;
//new                 iTotalDamage;
//new                 iTotalDamageTank;
//new                 iTotalDamageWitch;
new                 iTotalDamageAll;
new                 iTotalFF;

new                 iRoundNumber;
new                 bInRound;
new                 bPlayerLeftStartArea;                       // used for tracking FF when RUP enabled

new     String:     sTmpString[MAX_NAME_LENGTH];                // just used because I'm not going to break my head over why string assignment parameter passing doesn't work

/*
*      Natives
*      =======
*/

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("SURVMVP_GetMVP", Native_GetMVP);
    CreateNative("SURVMVP_GetMVPDmgCount", Native_GetMVPDmgCount);
    CreateNative("SURVMVP_GetMVPKills", Native_GetMVPKills);
    CreateNative("SURVMVP_GetMVPDmgPercent", Native_GetMVPDmgPercent);
    CreateNative("SURVMVP_GetMVPCI", Native_GetMVPCI);
    CreateNative("SURVMVP_GetMVPCIKills", Native_GetMVPCIKills);
    CreateNative("SURVMVP_GetMVPCIPercent", Native_GetMVPCIPercent);
    
    return APLRes_Success;
}

// simply return current round MVP client
public Native_GetMVP(Handle:plugin, numParams)
{
    new client = findMVPSI();
    return _:client;
}

// return damage percent of client
public Native_GetMVPDmgPercent(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new Float: dmgprc = client && iTotalDamageAll > 0 ? (float(iDidDamageAll[client]) / float(iTotalDamageAll)) * 100 : 0.0;
    return _:dmgprc;
}

// return damage of client
public Native_GetMVPDmgCount(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new dmg = client && iTotalDamageAll > 0 ? iDidDamageAll[client] : 0;
    return _:dmg;
}

// return SI kills of client
public Native_GetMVPKills(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new dmg = client && iTotalKills > 0 ? iGotKills[client] : 0;
    return _:dmg;
}

// simply return current round MVP client (Common)
public Native_GetMVPCI(Handle:plugin, numParams)
{
    new client = findMVPCommon();
    return _:client;
}

// return common kills for client
public Native_GetMVPCIKills(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new dmg = client && iTotalCommon > 0 ? iGotCommon[client] : 0;
    return _:dmg;
}

// return CI percent of client
public Native_GetMVPCIPercent(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new Float: dmgprc = client && iTotalCommon > 0 ? (float(iGotCommon[client]) / float(iTotalCommon)) * 100 : 0.0;
    return _:dmgprc;
}


/*
*      init
*      ====
*/

public OnPluginStart()
{
    // Round triggers
    //HookEvent("door_close", DoorClose_Event);
    HookEvent("finale_vehicle_leaving", FinaleEnd_Event, EventHookMode_PostNoCopy);
    HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
    HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
    HookEvent("map_transition", RoundEnd_Event, EventHookMode_PostNoCopy);
    HookEvent("scavenge_round_start", ScavRoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_left_start_area", PlayerLeftStartArea, EventHookMode_PostNoCopy);
    HookEvent("pills_used", pillsUsedEvent);
    HookEvent("boomer_exploded", boomerExploded);
    HookEvent("charger_carry_end", chargerCarryEnd);
    HookEvent("jockey_ride", jockeyRide);
    HookEvent("lunge_pounce", hunterLunged);
    HookEvent("choke_start", smokerChoke);
    HookEvent("tank_killed", tankKilled);
    HookEvent("tank_spawn", tankSpawn);
    HookEvent("ability_use", abilityUseEvent);
    //HookEvent("tank_frustrated", tankFrustrated);
    
    // Catching data
    HookEvent("player_hurt", PlayerHurt_Event, EventHookMode_Post);
    HookEvent("player_death", PlayerDeath_Event, EventHookMode_Post);
    HookEvent("infected_hurt" ,InfectedHurt_Event, EventHookMode_Post);
    HookEvent("infected_death", InfectedDeath_Event, EventHookMode_Post);
    
    // Cvars
    hPluginEnabled =    CreateConVar("sm_survivor_mvp_enabled", "1", "Enable display of MVP at end of round");
    hCountTankDamage =  CreateConVar("sm_survivor_mvp_counttank", "0", "Damage on tank counts towards MVP-selection if enabled.");
    hCountWitchDamage = CreateConVar("sm_survivor_mvp_countwitch", "0", "Damage on witch counts towards MVP-selection if enabled.");
    hTrackFF =          CreateConVar("sm_survivor_mvp_showff", "1", "Track Friendly-fire stat.");
    hBrevityFlags =     CreateConVar("sm_survivor_mvp_brevity", "0", "Flags for setting brevity of MVP report (hide 1:SI, 2:CI, 4:FF, 8:rank, 32:perc, 64:abs).");
    
    bCountTankDamage =  GetConVarBool(hCountTankDamage);
    bCountWitchDamage = GetConVarBool(hCountWitchDamage);
    bTrackFF =          GetConVarBool(hTrackFF);
    iBrevityFlags =     GetConVarInt(hBrevityFlags);
    
    // for now, force FF tracking on:
    bTrackFF = true;
    
    HookConVarChange(hCountTankDamage, ConVarChange_CountTankDamage);
    HookConVarChange(hCountWitchDamage, ConVarChange_CountWitchDamage);
    HookConVarChange(hTrackFF, ConVarChange_TrackFF);
    HookConVarChange(hBrevityFlags, ConVarChange_BrevityFlags);
    
    if (!(iBrevityFlags & BREV_FF)) { bTrackFF = true; } // force tracking on if we're showing FF
    
    // RUP?
    hRUPActive = FindConVar("l4d_ready_enabled");
    if (hRUPActive != INVALID_HANDLE)
    {
        // hook changes for this, and set state appropriately
        bRUPActive = GetConVarBool(hRUPActive);
        HookConVarChange(hRUPActive, ConVarChange_RUPActive);
    } else {
        // not loaded
        bRUPActive = false;
    }
    bPlayerLeftStartArea = false;
    
    // Commands
    RegConsoleCmd("sm_mvp", SurvivorMVP_Cmd, "Prints the current MVP for the survivor team");
    RegConsoleCmd("sm_mvpme", ShowMVPStats_Cmd, "Prints the client's own MVP-related stats");
    
    RegConsoleCmd("say", Say_Cmd);
    RegConsoleCmd("say_team", Say_Cmd);
}

/*
public OnPluginEnd()
{
// nothing
}
*/

public OnClientPutInServer(client)
{
    decl String:tmpBuffer[64];
    GetClientName(client, tmpBuffer, sizeof(tmpBuffer));
    
    // if previously stored name for same client is not the same, delete stats & overwrite name
    if (strcmp(tmpBuffer, sClientName[client], true) != 0)
    {
        iGotKills[client] = 0;
        iGotCommon[client] = 0;
        iDidDamage[client] = 0;
        iDidDamageAll[client] = 0;
        iDidDamageWitch[client] = 0;
        iDidDamageTank[client] = 0;
        iDidFF[client] = 0;
        
        
        //@todo detailed statistics - set to 0
        for (new siClass = ZC_SMOKER; siClass <= ZC_TANK; siClass++) {
            iDidDamageClass[client][siClass] = 0;
            timesPinned[client][siClass] = 0;
        }
        pillsUsed[client] = 0;
        boomerPops[client] = 0;
        damageReceived[client] = 0;
        totalPinned[client] = 0;
        commonKilledDuringTank[client] = 0;
        siDmgDuringTank[client] = 0;
        rocksEaten[client] = 0;
        ttlPinnedDuringTank[client] = 0;
        
        // store name for later reference
        strcopy(sClientName[client], 64, tmpBuffer);
    }
}

/*
*      convar changes
*      ==============
*/

public ConVarChange_CountTankDamage(Handle:cvar, const String:oldValue[], const String:newValue[]) {
    bCountTankDamage = StringToInt(newValue) != 0;
}
public ConVarChange_CountWitchDamage(Handle:cvar, const String:oldValue[], const String:newValue[]) {
    bCountWitchDamage = StringToInt(newValue) != 0;
}
public ConVarChange_TrackFF(Handle:cvar, const String:oldValue[], const String:newValue[]) {
    //if (StringToInt(newValue) == 0) { bTrackFF = false; } else { bTrackFF = true; }
    // for now, disable FF tracking toggle (always on)
}
public ConVarChange_BrevityFlags(Handle:cvar, const String:oldValue[], const String:newValue[]) {
    iBrevityFlags = StringToInt(newValue);
    if (!(iBrevityFlags & BREV_FF)) { 
        bTrackFF = true; 
    } // force tracking on if we're showing FF
}

public ConVarChange_RUPActive(Handle:cvar, const String:oldValue[], const String:newValue[]) {
    bRUPActive = StringToInt(newValue) != 0;
}

/*
*      map load / round start/end
*      ==========================
*/

public Action:PlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
    // if RUP active, now we can start tracking FF
    bPlayerLeftStartArea = true;
}

public OnMapStart()
{
    bPlayerLeftStartArea = false;
}

public OnMapEnd()
{
    iRoundNumber = 0;
    bInRound = false;
}

public void ScavRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    // clear mvp stats
    new i, maxplayers = MaxClients;
    for (i = 1; i <= maxplayers; i++)
    {
        iGotKills[i] = 0;
        iGotCommon[i] = 0;
        iDidDamage[i] = 0;
        iDidDamageAll[i] = 0;
        iDidDamageWitch[i] = 0;
        iDidDamageTank[i] = 0;
        iDidFF[i] = 0;
        
        //@todo detailed statistics - set to 0
        for (new siClass = ZC_SMOKER; siClass <= ZC_TANK; siClass++) {
            iDidDamageClass[i][siClass] = 0;
            timesPinned[i][siClass] = 0;
        }
        pillsUsed[i] = 0;
        boomerPops[i] = 0;
        damageReceived[i] = 0;
        totalPinned[i] = 0;
        commonKilledDuringTank[i] = 0;
        siDmgDuringTank[i] = 0;
        rocksEaten[i] = 0;
        ttlPinnedDuringTank[i] = 0;
    }
    iTotalKills = 0;
    iTotalCommon = 0;
    //iTotalDamage = 0;
    //iTotalDamageTank = 0;
    //iTotalDamageWitch = 0;
    iTotalDamageAll = 0;
    iTotalFF = 0;
    //ttlSiDmgDuringTank = 0;
    ttlCommonKilledDuringTank = 0;
    tankThrow = false;
    
    bInRound = true;
    tankSpawned = false;
}

public RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    bPlayerLeftStartArea = false;
    
    if (!bInRound)
    {
        bInRound = true;
        iRoundNumber++;
    }
    
    // clear mvp stats
    new i, maxplayers = MaxClients;
    for (i = 1; i <= maxplayers; i++)
    {
        iGotKills[i] = 0;
        iGotCommon[i] = 0;
        iDidDamage[i] = 0;
        iDidDamageAll[i] = 0;
        iDidDamageWitch[i] = 0;
        iDidDamageTank[i] = 0;
        iDidFF[i] = 0;
        
        //@todo detailed statistics init to 0
        for (new siClass = ZC_SMOKER; siClass <= ZC_TANK; siClass++) {
            iDidDamageClass[i][siClass] = 0;
            timesPinned[i][siClass] = 0;
        }
        pillsUsed[i] = 0;
        boomerPops[i] = 0;
        damageReceived[i] = 0;
        totalPinned[i] = 0;
        commonKilledDuringTank[i] = 0;
        siDmgDuringTank[i] = 0;
        rocksEaten[i] = 0;
        ttlPinnedDuringTank[i] = 0;
    }
    iTotalKills = 0;
    iTotalCommon = 0;
    //iTotalDamage = 0;
    iTotalDamageAll = 0;
    iTotalFF = 0;
    //ttlSiDmgDuringTank = 0;
    ttlCommonKilledDuringTank = 0;
    //iTotalDamageTank = 0;
    tankThrow = false;
    
    tankSpawned = false;
}

public FinaleEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Co-op modes.
    if (!L4D_HasPlayerControlledZombies())
    {
        if (bInRound)
        {
            if (GetConVarBool(hPluginEnabled))
                CreateTimer(8.0, delayedMVPPrint);
            bInRound = false;
        }
    }

    // No need for versus/other modes as round_end fires just fine on them.
    
    tankSpawned = false;
}


public RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Co-op modes.
    if (!L4D_HasPlayerControlledZombies())
    {
        if (bInRound)
        {
            if (GetConVarBool(hPluginEnabled))
                CreateTimer(0.01, delayedMVPPrint);
            bInRound = false;
        }
    }
    else
    {
        // Any scavenge/versus mode.
        if (bInRound && !StrEqual(name, "map_transition", false))
        {
            // only show / log stuff when the round is done "the first time"
            if (GetConVarBool(hPluginEnabled))
                CreateTimer(2.0, delayedMVPPrint);
            bInRound = false;
        }
    }
    
    tankSpawned = false;
}


/*
*      cmds / reports
*      ==============
*/

public Action:Say_Cmd(client, args)
{
    if (!client) { return Plugin_Continue; }
    
    decl String:sMessage[MAX_NAME_LENGTH];
    GetCmdArg(1, sMessage, sizeof(sMessage));
    
    if (StrEqual(sMessage, "!mvp") || StrEqual(sMessage, "!mvpme")) { return Plugin_Handled; }
    
    return Plugin_Continue;
}

public Action:SurvivorMVP_Cmd(client, args)
{
    decl String:printBuffer[4096];
    new String:strLines[8][192];
    
    GetMVPString(printBuffer, sizeof(printBuffer));
    
    // PrintToChat has a max length. Split it in to individual lines to output separately
    new intPieces = ExplodeString(printBuffer, "\n", strLines, sizeof(strLines), sizeof(strLines[]));
    
    if (client && IsClientConnected(client))
    {
        for (new i = 0; i < intPieces; i++) 
        {
            CPrintToChat(client, "%s", strLines[i]);
        }
    }
    PrintLoserz(true, client);
}

public Action:ShowMVPStats_Cmd(client, args)
{
    PrintLoserz(true, client);
}

public Action:delayedMVPPrint(Handle:timer)
{
    decl String:printBuffer[4096];
    new String:strLines[8][192];
    
    GetMVPString(printBuffer, sizeof(printBuffer));
    
    // PrintToChatAll has a max length. Split it in to individual lines to output separately
    new intPieces = ExplodeString(printBuffer, "\n", strLines, sizeof(strLines), sizeof(strLines[]));
    for (new i = 0; i < intPieces; i++) 
    {
        for (new client = 1; client <= MaxClients; client++)
        {
            if (IsClientInGame(client)) CPrintToChat(client, "{default}%s", strLines[i]);
        }
    }
    
    CreateTimer(0.1, PrintLosers);
}

public Action:PrintLosers(Handle:timer)
{
    PrintLoserz(false, -1);
}

stock PrintLoserz(bool:bSolo, client)
{
    decl String:tmpBuffer[512];
    // also find the three non-mvp survivors and tell them they sucked
    // tell them they sucked with SI
    if (iTotalDamageAll > 0)
    {
        new mvp_SI = findMVPSI();
        new mvp_SI_losers[3];
        mvp_SI_losers[0] = findMVPSI(mvp_SI);                                                   // second place
        mvp_SI_losers[1] = findMVPSI(mvp_SI, mvp_SI_losers[0]);                             // third
        mvp_SI_losers[2] = findMVPSI(mvp_SI, mvp_SI_losers[0], mvp_SI_losers[1]);       // fourth
        
        for (new i = 0; i <= 2; i++)
        {
            if (IsClientAndInGame(mvp_SI_losers[i]) && !IsFakeClient(mvp_SI_losers[i])) 
            {
                if (bSolo)
                {
                    if (mvp_SI_losers[i] == client)
                    {
                        Format(tmpBuffer, sizeof(tmpBuffer), "{blue}Your Rank {green}SI: {olive}#%d - {blue}({default}%d {green}dmg {blue}[{default}%.0f%%{blue}]{olive}, {default}%d {green}kills {blue}[{default}%.0f%%{blue}])", (i + 2), iDidDamageAll[mvp_SI_losers[i]], (float(iDidDamageAll[mvp_SI_losers[i]]) / float(iTotalDamageAll)) * 100, iGotKills[mvp_SI_losers[i]], (float(iGotKills[mvp_SI_losers[i]]) / float(iTotalKills)) * 100);
                        CPrintToChat(mvp_SI_losers[i], "%s", tmpBuffer);
                    }
                }
                else 
                {
                    Format(tmpBuffer, sizeof(tmpBuffer), "{blue}Your Rank {green}SI: {olive}#%d - {blue}({default}%d {green}dmg {blue}[{default}%.0f%%{blue}]{olive}, {default}%d {green}kills {blue}[{default}%.0f%%{blue}])", (i + 2), iDidDamageAll[mvp_SI_losers[i]], (float(iDidDamageAll[mvp_SI_losers[i]]) / float(iTotalDamageAll)) * 100, iGotKills[mvp_SI_losers[i]], (float(iGotKills[mvp_SI_losers[i]]) / float(iTotalKills)) * 100);
                    CPrintToChat(mvp_SI_losers[i], "%s", tmpBuffer);
                }
            }
        }
    }
    
    // tell them they sucked with Common
    if (iTotalCommon > 0)
    {
        new mvp_CI = findMVPCommon();
        new mvp_CI_losers[3];
        mvp_CI_losers[0] = findMVPCommon(mvp_CI);                                                   // second place
        mvp_CI_losers[1] = findMVPCommon(mvp_CI, mvp_CI_losers[0]);                             // third
        mvp_CI_losers[2] = findMVPCommon(mvp_CI, mvp_CI_losers[0], mvp_CI_losers[1]);       // fourth
        
        for (new i = 0; i <= 2; i++)
        {
            if (IsClientAndInGame(mvp_CI_losers[i]) && !IsFakeClient(mvp_CI_losers[i])) 
            {
                if (bSolo)
                {
                    if (mvp_CI_losers[i] == client)
                    {
                        Format(tmpBuffer, sizeof(tmpBuffer), "{blue}Your Rank {green}CI{default}: {olive}#%d {blue}({default}%d {green}common {blue}[{default}%.0f%%{blue}])", (i + 2), iGotCommon[mvp_CI_losers[i]], (float(iGotCommon[mvp_CI_losers[i]]) / float(iTotalCommon)) * 100);
                        CPrintToChat(mvp_CI_losers[i], "%s", tmpBuffer);
                    }
                }
                else
                {
                    Format(tmpBuffer, sizeof(tmpBuffer), "{blue}Your Rank {green}CI{default}: {olive}#%d {blue}({default}%d {green}common {blue}[{default}%.0f%%{blue}])", (i + 2), iGotCommon[mvp_CI_losers[i]], (float(iGotCommon[mvp_CI_losers[i]]) / float(iTotalCommon)) * 100);
                    CPrintToChat(mvp_CI_losers[i], "%s", tmpBuffer);
                }
            }
        }
    }
    
    // tell them they were better with FF (I know, I know, losers = winners)
    if (iTotalFF > 0)
    {
        new mvp_FF = findLVPFF();
        new mvp_FF_losers[3];
        mvp_FF_losers[0] = findLVPFF(mvp_FF);                                                   // second place
        mvp_FF_losers[1] = findLVPFF(mvp_FF, mvp_FF_losers[0]);                             // third
        mvp_FF_losers[2] = findLVPFF(mvp_FF, mvp_FF_losers[0], mvp_FF_losers[1]);       // fourth
        
        for (new i = 0; i <= 2; i++)
        {
            if (IsClientAndInGame(mvp_FF_losers[i]) &&  !IsFakeClient(mvp_FF_losers[i])) 
            {
                if (bSolo)
                {
                    if (mvp_FF_losers[i] == client)
                    {
                        Format(tmpBuffer, sizeof(tmpBuffer), "{blue}Your Rank {green}FF{default}: {olive}#%d {blue}({default}%d {green}friendly fire {blue}[{default}%.0f%%{blue}])", (i + 2), iDidFF[mvp_FF_losers[i]], (float(iDidFF[mvp_FF_losers[i]]) / float(iTotalFF)) * 100);
                        CPrintToChat(mvp_FF_losers[i], "%s", tmpBuffer);
                    }
                }
                else
                {
                    Format(tmpBuffer, sizeof(tmpBuffer), "{blue}Your Rank {green}FF{default}: {olive}#%d {blue}({default}%d {green}friendly fire {blue}[{default}%.0f%%{blue}])", (i + 2), iDidFF[mvp_FF_losers[i]], (float(iDidFF[mvp_FF_losers[i]]) / float(iTotalFF)) * 100);
                    CPrintToChat(mvp_FF_losers[i], "%s", tmpBuffer);
                }
            }
        }
    }    
}
/**
* When an entity is created (which we use to track rocks)
* don't actually need this
*/
public OnEntityCreated(entity, const String:classname[])
{ 
    if(! tankThrow) {
        return;
    }
    
    if(StrEqual(classname, "tank_rock", true))  {
        rockIndex = entity;
        tankThrow = true;
    }
}

/**
* When an entity has been destroyed (i.e. when a rock lands on someone)
*/
public OnEntityDestroyed(entity)
{   
    // The rock has been destroyed
    if (rockIndex == entity) {
        tankThrow = false;
    }
}

/**
* When an infected uses their ability
*/
public Action:abilityUseEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    decl String:ability[32];
    GetEventString(event, "ability", ability, 32);
    
    // If tank is throwing a rock
    if(StrEqual(ability, "ability_throw", true)) {
        tankThrow = true;
    }
}

/**
* Track pill usage
*/
public pillsUsedEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid")); 
    if (client == 0 || ! IsClientInGame(client)) {
        return;
    }
    
    pillsUsed[client]++;
}

/**
* Track boomer pops
*/
public boomerExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
    // We only want to track pops where the boomer didn't bile anyone
    new bool:biled = GetEventBool(event, "splashedbile");
    if (! biled) {
        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
        if (attacker == 0 || ! IsClientInGame(attacker)) {
            return;
        }
        boomerPops[attacker]++;
    }
}


/**
* Track when someone gets charged (end of charge for level, or if someone shoots you off etc.)
*/
public chargerCarryEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "victim")); 
    if (client == 0 || ! IsClientInGame(client)) {
        return;
    }
    
    timesPinned[client][ZC_CHARGER]++;
    totalPinned[client]++;
    
    if (tankSpawned) {
        ttlPinnedDuringTank[client]++;
    }
}

/**
* Track when someone gets jockeyed.
*/
public jockeyRide(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "victim")); 
    if (client == 0 || ! IsClientInGame(client)) {
        return;
    }
    
    timesPinned[client][ZC_JOCKEY]++;
    totalPinned[client]++;
    
    if (tankSpawned) {
        ttlPinnedDuringTank[client]++;
    }
}

/** 
* Track when someone gets huntered.
*/
public hunterLunged(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "victim")); 
    if (client == 0 || ! IsClientInGame(client)) {
        return;
    }
    
    timesPinned[client][ZC_HUNTER]++;
    totalPinned[client]++;
    
    if (tankSpawned) {
        ttlPinnedDuringTank[client]++;
    }
}

/**
* Track when someone gets smoked (we track when they start getting smoked, because anyone can get smoked)
*/
public smokerChoke(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "victim")); 
    if (client == 0 || ! IsClientInGame(client)) {
        return;
    }
    
    timesPinned[client][ZC_SMOKER]++;
    totalPinned[client]++;
    
    if (tankSpawned) {
        ttlPinnedDuringTank[client]++;
    }
}

/**
* When the tank spawns
*/
public tankSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
    tankSpawned = true;
}

/**
* When the tank is killed
*/
public tankKilled(Handle:event, const String:name[], bool:dontBroadcast) {
    tankSpawned = false;
}

/*
*      track damage/kills
*      ==================
*/

public PlayerHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    new zombieClass = 0;
    
    // Victim details
    new victimId = GetEventInt(event, "userid");
    new victim = GetClientOfUserId(victimId);
    
    // Attacker details
    new attackerId = GetEventInt(event, "attacker");
    new attacker = GetClientOfUserId(attackerId);
    
    // Misc details
    new damageDone = GetEventInt(event, "dmg_health");
    
    // no world damage or flukes or whatevs, no bot attackers, no infected-to-infected damage
    if (victimId && attackerId && IsClientAndInGame(victim) && IsClientAndInGame(attacker))
    {
        // If a survivor is attacking infected
        if (GetClientTeam(attacker) == TEAM_SURVIVOR && GetClientTeam(victim) == TEAM_INFECTED)
        {
            zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
            
            // Increment the damage for that class to the total
            iDidDamageClass[attacker][zombieClass] += damageDone;
            //PrintToConsole(attacker, "Attacked: %d - Dmg: %d", zombieClass, damageDone);
            //PrintToConsole(attacker, "Total damage for %d: %d", zombieClass, iDidDamageClass[attacker][zombieClass]);
            
            // separately store SI and tank damage
            if (zombieClass >= ZC_SMOKER && zombieClass < ZC_WITCH)
            {
                // If the tank is up, let's store separately
                if (tankSpawned) {
                    siDmgDuringTank[attacker] += damageDone;
                    //ttlSiDmgDuringTank += damageDone;
                }
                
                iDidDamage[attacker] += damageDone;
                iDidDamageAll[attacker] += damageDone;
               // iTotalDamage += damageDone;
                iTotalDamageAll += damageDone;
            }
            else if (zombieClass == ZC_TANK && damageDone != 5000) // For some reason the last attacker does 5k damage?
            {
                // We want to track tank damage even if we're not factoring it in to our mvp result
                iDidDamageTank[attacker] += damageDone;
                //iTotalDamageTank += damageDone;
                
                // If we're factoring it in, include it in our overall damage
                if (bCountTankDamage)
                {
                    iDidDamageAll[attacker] += damageDone;
                    iTotalDamageAll += damageDone;
                }
            }
        }
        
        // Otherwise if friendly fire
        else if (GetClientTeam(attacker) == TEAM_SURVIVOR && GetClientTeam(victim) == TEAM_SURVIVOR && bTrackFF)                // survivor on survivor action == FF
        {
            if (!bRUPActive || GetEntityMoveType(victim) != MOVETYPE_NONE || bPlayerLeftStartArea) {
                // but don't record while frozen in readyup / before leaving saferoom
                iDidFF[attacker] += damageDone;
                iTotalFF += damageDone;
            }
        }
        
        // Otherwise if infected are inflicting damage on a survivor
        else if (GetClientTeam(attacker) == TEAM_INFECTED && GetClientTeam(victim) == TEAM_SURVIVOR) {
            zombieClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");
            
            // If we got hit by a tank, let's see what type of damage it was
            // If it was from a rock throw
            if (tankThrow && zombieClass == ZC_TANK && damageDone == 24) {
                rocksEaten[victim]++;
            }
            damageReceived[victim] += damageDone;
        }
    }
}

/** 
* When the infected are hurt (i.e. when a survivor hurts an SI)
* We want to use this to track damage done to the witch.
*/
public InfectedHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    // catch damage done to witch
    new victimEntId = GetEventInt(event, "entityid");
    
    if (IsWitch(victimEntId))
    {
        new attackerId = GetEventInt(event, "attacker");
        new attacker = GetClientOfUserId(attackerId);
        new damageDone = GetEventInt(event, "amount");
        
        // no world damage or flukes or whatevs, no bot attackers
        if (attackerId && IsClientAndInGame(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR)
        {
            // We want to track the witch damage regardless of whether we're counting it in our mvp stat
            iDidDamageWitch[attacker] += damageDone;
            //iTotalDamageWitch += damageDone;
            
            // If we're counting witch damage in our mvp stat, lets add the amount of damage done to the witch
            if (bCountWitchDamage) 
            {
                iDidDamageAll[attacker] += damageDone;
                iTotalDamageAll += damageDone;
            }
        }
    }
}

public PlayerDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Get the victim details
    new zombieClass = 0;
    new victimId = GetEventInt(event, "userid");
    new victim = GetClientOfUserId(victimId);
    
    // Get the attacker details
    new attackerId = GetEventInt(event, "attacker");
    new attacker = GetClientOfUserId(attackerId);
    
    // no world kills or flukes or whatevs, no bot attackers
    if (victimId && attackerId && IsClientAndInGame(victim) && IsClientAndInGame(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR)
    {
        zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
        
        // only SI, not the tank && only player-attackers
        if (zombieClass >= ZC_SMOKER && zombieClass < ZC_WITCH)
        {
            // store kill to count for attacker id
            iGotKills[attacker]++;
            iTotalKills++;
        }
    }
    
    /**
    * Are we tracking the tank? 
    * This is a secondary measure. For some reason when I test locally in PM, the
    * tank_killed event is triggered, but when I test in a custom config, it's not.
    * Hopefully this should fix it.
    */
    if (victimId && IsClientAndInGame(victim)) {
        zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
        if (zombieClass == ZC_TANK) {
            tankSpawned = false;
        }
    }
}

// Was the zombie a hunter?
public bool:isHunter(zombieClass) {
    return zombieClass == ZC_HUNTER;
}

public InfectedDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    new attackerId = GetEventInt(event, "attacker");
    new attacker = GetClientOfUserId(attackerId);
    
    if (attackerId && IsClientAndInGame(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR)
    {
        // If the tank is up, let's store separately
        if (tankSpawned) {
            commonKilledDuringTank[attacker]++;
            ttlCommonKilledDuringTank++;
        }
        
        iGotCommon[attacker]++;
        iTotalCommon++;
        // if victimType > 2, it's an "uncommon" (of some type or other) -- do nothing with this ftpresent.
    }
}

/*
*      MVP string & 'sorting'
*      ======================
*/
void GetMVPString(char[] printBuffer, const int iSize)
{
    decl String:tmpBuffer[1024];
    printBuffer[0] = '\0';

    decl String:tmpName[64];
    decl String:mvp_SI_name[64];
    decl String:mvp_Common_name[64];
    decl String:mvp_FF_name[64];
    
    new mvp_SI = 0;
    new mvp_Common = 0;
    new mvp_FF = 0;
    
    // calculate MVP per category:
    //  1. SI damage & SI kills + damage to tank/witch
    //  2. common kills
    
    // SI MVP
    if (!(iBrevityFlags & BREV_SI))
    {
        mvp_SI = findMVPSI();
        if (mvp_SI > 0)
        {
            // get name from client if connected -- if not, use sClientName array
            if (IsClientConnected(mvp_SI))
            {
                GetClientName(mvp_SI, tmpName, sizeof(tmpName));
                if (IsFakeClient(mvp_SI))
                {
                    StrCat(tmpName, 64, " \x01[BOT]");
                }
            } else {
                strcopy(tmpName, 64, sClientName[mvp_SI]);
            }
            mvp_SI_name = tmpName;
        } else {
            mvp_SI_name = "(nobody)";
        }
    }
    
    // Common MVP
    if (!(iBrevityFlags & BREV_CI))
    {
        mvp_Common = findMVPCommon();
        if (mvp_Common > 0)
        {
            // get name from client if connected -- if not, use sClientName array
            if (IsClientConnected(mvp_Common))
            {
                GetClientName(mvp_Common, tmpName, sizeof(tmpName));
                if (IsFakeClient(mvp_Common))
                {
                    StrCat(tmpName, 64, " \x01[BOT]");
                }
            } else {
                strcopy(tmpName, 64, sClientName[mvp_Common]);
            }
            mvp_Common_name = tmpName;
        } else {
            mvp_Common_name = "(nobody)";
        }
    }
    
    // FF LVP
    if (!(iBrevityFlags & BREV_FF) && bTrackFF)
    {
        mvp_FF = findLVPFF();
        if (mvp_FF > 0)
        {
            // get name from client if connected -- if not, use sClientName array
            if (IsClientConnected(mvp_FF))
            {
                GetClientName(mvp_FF, tmpName, sizeof(tmpName));
                if (IsFakeClient(mvp_FF))
                {
                    StrCat(tmpName, 64, " \x01[BOT]");
                }
            } else {
                strcopy(tmpName, 64, sClientName[mvp_FF]);
            }
            mvp_FF_name = tmpName;
        } else {
            mvp_FF_name = "(nobody)";
        }
    }
    
    // report
    
    if (mvp_SI == 0 && mvp_Common == 0 && !(iBrevityFlags & BREV_SI && iBrevityFlags & BREV_CI))
    {
        Format(tmpBuffer, sizeof(tmpBuffer), "{blue}[{default}MVP{blue}]{default} {blue}({default}not enough action yet{blue}){default}\n");
        StrCat(printBuffer, iSize, tmpBuffer);
    }
    else
    {
        if (!(iBrevityFlags & BREV_SI))
        {
            if (mvp_SI > 0)
            {
                if (iBrevityFlags & BREV_PERCENT) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] SI:\x03 %s \x01(\x05%d \x01dmg,\x05 %d \x01kills)\n", mvp_SI_name, iDidDamageAll[mvp_SI], iGotKills[mvp_SI]);
                } else if (iBrevityFlags & BREV_ABSOLUTE) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] SI:\x03 %s \x01(dmg \x04%2.0f%%\x01, kills \x04%.0f%%\x01)\n", mvp_SI_name, (float(iDidDamageAll[mvp_SI]) / float(iTotalDamageAll)) * 100, (float(iGotKills[mvp_SI]) / float(iTotalKills)) * 100);
                } else {
                    Format(tmpBuffer, sizeof(tmpBuffer), "{blue}[{default}MVP{blue}] SI: {olive}%s {blue}({default}%d {green}dmg {blue}[{default}%.0f%%{blue}]{olive}, {default}%d {green}kills {blue}[{default}%.0f%%{blue}])\n", mvp_SI_name, iDidDamageAll[mvp_SI], (float(iDidDamageAll[mvp_SI]) / float(iTotalDamageAll)) * 100, iGotKills[mvp_SI], (float(iGotKills[mvp_SI]) / float(iTotalKills)) * 100);
                }
                StrCat(printBuffer, iSize, tmpBuffer);
            }
            else
            {
                StrCat(printBuffer, iSize, "{blue}[{default}MVP{blue}] SI: {blue}({default}nobody{blue}){default}\n");
            }
        }
        
        if (!(iBrevityFlags & BREV_CI))
        {
            if (mvp_Common > 0)
            {
                if (iBrevityFlags & BREV_PERCENT) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] CI:\x03 %s \x01(\x05%d \x01common)\n", mvp_Common_name, iGotCommon[mvp_Common]);
                } else if (iBrevityFlags & BREV_ABSOLUTE) {
                    Format(tmpBuffer, sizeof(tmpBuffer), "[MVP] CI:\x03 %s \x01(\x04%.0f%%\x01)\n", mvp_Common_name, (float(iGotCommon[mvp_Common]) / float(iTotalCommon)) * 100);
                } else {
                    Format(tmpBuffer, sizeof(tmpBuffer), "{blue}[{default}MVP{blue}] CI: {olive}%s {blue}({default}%d {green}common {blue}[{default}%.0f%%{blue}])\n", mvp_Common_name, iGotCommon[mvp_Common], (float(iGotCommon[mvp_Common]) / float(iTotalCommon)) * 100);
                }
                StrCat(printBuffer, iSize, tmpBuffer);
            }
        }
    }
    
    // FF
    if (!(iBrevityFlags & BREV_FF) && bTrackFF)
    {
        if (mvp_FF == 0)
        {
            Format(tmpBuffer, sizeof(tmpBuffer), "{blue}[{default}LVP{blue}] FF{default}: {green}no friendly fire at all!{default}\n");
            StrCat(printBuffer, iSize, tmpBuffer);
        }
        else
        {
            if (iBrevityFlags & BREV_PERCENT) {
                Format(tmpBuffer, sizeof(tmpBuffer), "[LVP] FF:\x03 %s \x01(\x05%d \x01dmg)\n", mvp_FF_name, iDidFF[mvp_FF]);
            } else if (iBrevityFlags & BREV_ABSOLUTE) {
                Format(tmpBuffer, sizeof(tmpBuffer), "[LVP] FF:\x03 %s \x01(\x04%.0f%%\x01)\n", mvp_FF_name, (float(iDidFF[mvp_FF]) / float(iTotalFF)) * 100);
            } else {
                Format(tmpBuffer, sizeof(tmpBuffer), "{blue}[{default}LVP{blue}] FF{default}: {olive}%s {blue}({default}%d {green}friendly fire {blue}[{default}%.0f%%{blue}]){default}\n", mvp_FF_name, iDidFF[mvp_FF], (float(iDidFF[mvp_FF]) / float(iTotalFF)) * 100);
            }
            StrCat(printBuffer, iSize, tmpBuffer);
        }
    }
}


findMVPSI(excludeMeA = 0, excludeMeB = 0, excludeMeC = 0)
{
    new i, maxIndex = 0;
    for(i = 1; i < sizeof(iDidDamageAll); i++)
    {
        if(iDidDamageAll[i] > iDidDamageAll[maxIndex]  && i != excludeMeA && i != excludeMeB && i != excludeMeC)
            maxIndex = i;
    }
    return maxIndex;
}

findMVPCommon(excludeMeA = 0, excludeMeB = 0, excludeMeC = 0)
{
    new i, maxIndex = 0;
    for(i = 1; i < sizeof(iGotCommon); i++)
    {
        if(iGotCommon[i] > iGotCommon[maxIndex] && i != excludeMeA && i != excludeMeB && i != excludeMeC)
            maxIndex = i;
    }
    return maxIndex;
}

findLVPFF(excludeMeA = 0, excludeMeB = 0, excludeMeC = 0)
{
    new i, maxIndex = 0;
    for(i = 1; i < sizeof(iDidFF); i++)
    {
        if(iDidFF[i] > iDidFF[maxIndex]  && i != excludeMeA && i != excludeMeB && i != excludeMeC)
            maxIndex = i;
    }
    return maxIndex;
}


/*
*      general functions
*      =================
*/


stock bool:IsClientAndInGame(index)
{
    return (index > 0 && index <= MaxClients && IsClientInGame(index));
}

stock bool:IsSurvivor(client)
{
    return IsClientAndInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR;
}

stock bool:IsInfected(client)
{
    return IsClientAndInGame(client) && GetClientTeam(client) == TEAM_INFECTED;
}

stock bool:IsWitch(iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "witch");
    }
    return false;
}

stock getSurvivor(exclude[4])
{
    for(new i=1; i <= MaxClients; i++) {
        if (IsSurvivor(i)) {
            new tagged = false;
            // exclude already tagged survs
            for (new j=0; j < 4; j++) {
                if (exclude[j] == i) { tagged = true; }
            }
            if (!tagged) {
                return i;
            }
        }
    }
    return 0;
}

public stripUnicode(String:testString[MAX_NAME_LENGTH])
{
    new const maxlength = MAX_NAME_LENGTH;
    //strcopy(testString, maxlength, sTmpString);
    sTmpString = testString;
    
    new uni=0;
    new currentChar;
    new tmpCharLength = 0;
    //new iReplace[MAX_NAME_LENGTH];      // replace these chars
    
    for (new i=0; i < maxlength - 3 && sTmpString[i] != 0; i++)
    {
        // estimate current character value
        if ((sTmpString[i]&0x80) == 0) // single byte character?
        {
            currentChar=sTmpString[i]; tmpCharLength = 0;
        } else if (((sTmpString[i]&0xE0) == 0xC0) && ((sTmpString[i+1]&0xC0) == 0x80)) // two byte character?
        {
            currentChar=(sTmpString[i++] & 0x1f); currentChar=currentChar<<6;
            currentChar+=(sTmpString[i] & 0x3f); 
            tmpCharLength = 1;
        } else if (((sTmpString[i]&0xF0) == 0xE0) && ((sTmpString[i+1]&0xC0) == 0x80) && ((sTmpString[i+2]&0xC0) == 0x80)) // three byte character?
        {
            currentChar=(sTmpString[i++] & 0x0f); currentChar=currentChar<<6;
            currentChar+=(sTmpString[i++] & 0x3f); currentChar=currentChar<<6;
            currentChar+=(sTmpString[i] & 0x3f);
            tmpCharLength = 2;
        } else if (((sTmpString[i]&0xF8) == 0xF0) && ((sTmpString[i+1]&0xC0) == 0x80) && ((sTmpString[i+2]&0xC0) == 0x80) && ((sTmpString[i+3]&0xC0) == 0x80)) // four byte character?
        {
            currentChar=(sTmpString[i++] & 0x07); currentChar=currentChar<<6;
            currentChar+=(sTmpString[i++] & 0x3f); currentChar=currentChar<<6;
            currentChar+=(sTmpString[i++] & 0x3f); currentChar=currentChar<<6;
            currentChar+=(sTmpString[i] & 0x3f);
            tmpCharLength = 3;
        } else 
        {
            currentChar=CHARTHRESHOLD + 1; // reaching this may be caused by bug in sourcemod or some kind of bug using by the user - for unicode users I do assume last ...
            tmpCharLength = 0;
        }
        
        // decide if character is allowed
        if (currentChar > CHARTHRESHOLD)
        {
            uni++;
            // replace this character // 95 = _, 32 = space
            for (new j=tmpCharLength; j >= 0; j--) {
                sTmpString[i - j] = 95; 
            }
        }
    }
}

/*
stock bool:IsCommonInfected(iEntity)
{
if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
{
decl String:strClassName[64];
GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
return StrEqual(strClassName, "infected");
}
return false;
}
*/