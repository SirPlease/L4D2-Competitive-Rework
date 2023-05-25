#include <colors>
#include <readyup>

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <caster_system>

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_VALID_CASTER(%1)     (IS_VALID_INGAME(%1) && casterSystemAvailable && IsClientCaster(%1))

ArrayList h_whosHadTank;
char queuedTankSteamId[64];
ConVar hTankPrint, hTankDebug;
bool casterSystemAvailable;
Handle hForwardOnTryOfferingTankBot;
Handle hForwardOnTankSelection;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("GetTankSelection", Native_GetTankSelection);

    hForwardOnTryOfferingTankBot = CreateGlobalForward("TankControl_OnTryOfferingTankBot", ET_Ignore, Param_String);
    hForwardOnTankSelection = CreateGlobalForward("TankControl_OnTankSelection", ET_Ignore, Param_String);

    return APLRes_Success;
}

public int Native_GetTankSelection(Handle plugin, int numParams) { return getInfectedPlayerBySteamId(queuedTankSteamId); }

public Plugin myinfo = 
{
    name = "L4D2 Tank Control",
    author = "arti",
    description = "Distributes the role of the tank evenly throughout the team",
    version = "0.0.19",
    url = "https://github.com/alexberriman/l4d2-plugins/tree/master/l4d_tank_control"
}

enum L4D2Team
{
    L4D2Team_None = 0,
    L4D2Team_Spectator,
    L4D2Team_Survivor,
    L4D2Team_Infected
}

enum ZClass
{
    ZClass_Smoker = 1,
    ZClass_Boomer = 2,
    ZClass_Hunter = 3,
    ZClass_Spitter = 4,
    ZClass_Jockey = 5,
    ZClass_Charger = 6,
    ZClass_Witch = 7,
    ZClass_Tank = 8
}

public void OnPluginStart()
{
    // Load translations (for targeting player)
    LoadTranslations("common.phrases");
    
    // Event hooks
    HookEvent("player_left_start_area", PlayerLeftStartArea_Event, EventHookMode_PostNoCopy);
    HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
    HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
    HookEvent("player_team", PlayerTeam_Event, EventHookMode_Post);
    HookEvent("tank_killed", TankKilled_Event, EventHookMode_PostNoCopy);
    HookEvent("player_death", PlayerDeath_Event, EventHookMode_Post);
    
    // Initialise the tank arrays/data values
    h_whosHadTank = new ArrayList(ByteCountToCells(64));
    
    // Admin commands
    RegAdminCmd("sm_tankshuffle", TankShuffle_Cmd, ADMFLAG_SLAY, "Re-picks at random someone to become tank.");
    RegAdminCmd("sm_givetank", GiveTank_Cmd, ADMFLAG_SLAY, "Gives the tank to a selected player");

    // Register the boss commands
    RegConsoleCmd("sm_tank", Tank_Cmd, "Shows who is becoming the tank.");
    RegConsoleCmd("sm_boss", Tank_Cmd, "Shows who is becoming the tank.");
    RegConsoleCmd("sm_witch", Tank_Cmd, "Shows who is becoming the tank.");
    
    // Cvars
    hTankPrint = CreateConVar("tankcontrol_print_all", "0", "Who gets to see who will become the tank? (0 = Infected, 1 = Everyone)");
    hTankDebug = CreateConVar("tankcontrol_debug", "0", "Whether or not to debug to console");
}

public void OnAllPluginsLoaded()
{
    casterSystemAvailable = LibraryExists("caster_system");
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "caster_system")) casterSystemAvailable = true;
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "caster_system")) casterSystemAvailable = false;
}

/*public void OnClientDisconnect(int client) 
{
    char tmpSteamId[64];
    
    if (client)
    {
        GetClientAuthId(client, AuthId_Steam2, tmpSteamId, sizeof(tmpSteamId));
        if (strcmp(queuedTankSteamId, tmpSteamId) == 0)
        {
            chooseTank(0);
            outputTankToAll(0);
        }
    }
}*/

/**
 * When a new game starts, reset the tank pool.
 */
 
public void RoundStart_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    CreateTimer(10.0, newGame);
}

public Action newGame(Handle timer)
{
    int teamAScore = L4D2Direct_GetVSCampaignScore(0);
    int teamBScore = L4D2Direct_GetVSCampaignScore(1);

    // If it's a new game, reset the tank pool
    if (teamAScore == 0 && teamBScore == 0)
    {
        h_whosHadTank.Clear();
        queuedTankSteamId = "";
    }

    return Plugin_Stop;
}

/**
 * When the round ends, reset the active tank.
 */
 
public void RoundEnd_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    queuedTankSteamId = "";
}

/**
 * When a player leaves the start area, choose a tank and output to all.
 */
 
public void PlayerLeftStartArea_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    chooseTank(0);
    outputTankToAll(0);
}

/**
 * When the queued tank switches teams, choose a new one
 */
 
public void PlayerTeam_Event(Event hEvent, const char[] name, bool dontBroadcast)
{
    L4D2Team oldTeam = view_as<L4D2Team>(hEvent.GetInt("oldteam"));
    int client = GetClientOfUserId(hEvent.GetInt("userid"));
    char tmpSteamId[64];

    if (client && oldTeam == view_as<L4D2Team>(L4D2Team_Infected))
    {
        GetClientAuthId(client, AuthId_Steam2, tmpSteamId, sizeof(tmpSteamId));
        if (strcmp(queuedTankSteamId, tmpSteamId) == 0)
        {
            RequestFrame(chooseTank, 0);
            RequestFrame(outputTankToAll, 0);
        }
    }
}

/**
 * When the tank dies, requeue a player to become tank (for finales)
 */
 
public void PlayerDeath_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    int zombieClass = 0;
    int victimId = hEvent.GetInt("userid");
    int victim = GetClientOfUserId(victimId);
    
    if (victimId && IsClientInGame(victim)) 
    {
        zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
        if (view_as<ZClass>(zombieClass) == ZClass_Tank) 
        {
            if (GetConVarBool(hTankDebug))
            {
                PrintToConsoleAll("[TC] Tank died(1), choosing a new tank");
            }
            chooseTank(0);
        }
    }
}

public void TankKilled_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    if (GetConVarBool(hTankDebug))
    {
        PrintToConsoleAll("[TC] Tank died(2), choosing a new tank");
    }
    chooseTank(0);
}

/**
 * When a player wants to find out whos becoming tank,
 * output to them.
 */
 
public Action Tank_Cmd(int client, int args)
{
    if (!IsClientInGame(client)) 
      return Plugin_Handled;

    int tankClientId;
    char tankClientName[128];
    
    // Only output if we have a queued tank
    if (! strcmp(queuedTankSteamId, ""))
    {
        return Plugin_Handled;
    }
    
    tankClientId = getInfectedPlayerBySteamId(queuedTankSteamId);
    if (tankClientId != -1)
    {
        GetClientName(tankClientId, tankClientName, sizeof(tankClientName));
        
        // If on infected, print to entire team
        if (view_as<L4D2Team>(GetClientTeam(client)) == L4D2Team_Infected || (casterSystemAvailable && IsClientCaster(client)))
        {
            if (client == tankClientId) CPrintToChat(client, "{red}<{default}Tank Selection{red}> {green}You {default}will become the {red}Tank{default}!");
            else CPrintToChat(client, "{red}<{default}Tank Selection{red}> {olive}%s {default}will become the {red}Tank!", tankClientName);
        }
    }
    
    return Plugin_Handled;
}

/**
 * Shuffle the tank (randomly give to another player in
 * the pool.
 */
 
public Action TankShuffle_Cmd(int client, int args)
{
    chooseTank(0);
    outputTankToAll(0);
    
    return Plugin_Handled;
}

/**
 * Give the tank to a specific player.
 */
 
public Action GiveTank_Cmd(int client, int args)
{    
    // Who are we targetting?
    char arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    
    // Try and find a matching player
    int target = FindTarget(client, arg1);
    if (target == -1)
    {
        return Plugin_Handled;
    }
    
    // Get the players name
    char name[MAX_NAME_LENGTH];
    GetClientName(target, name, sizeof(name));
    
    // Set the tank
    if (IsClientInGame(target) && ! IsFakeClient(target))
    {
        // Checking if on our desired team
        if (view_as<L4D2Team>(GetClientTeam(target)) != L4D2Team_Infected)
        {
            CPrintToChatAll("{olive}[SM] {default}%s not on infected. Unable to give tank", name);
            return Plugin_Handled;
        }
        
        char steamId[64];
        GetClientAuthId(target, AuthId_Steam2, steamId, sizeof(steamId));

        strcopy(queuedTankSteamId, sizeof(queuedTankSteamId), steamId);
        outputTankToAll(0);
    }
    
    return Plugin_Handled;
}

/**
 * Selects a player on the infected team from random who hasn't been
 * tank and gives it to them.
 */
 
public void chooseTank(any data)
{
    //Let other plugins to override tank selection
    char sOverrideTank[64];
    sOverrideTank[0] = '\0';
    Call_StartForward(hForwardOnTankSelection);
    Call_PushStringEx(sOverrideTank, sizeof(sOverrideTank), SM_PARAM_STRING_UTF8, SM_PARAM_COPYBACK);
    Call_Finish();

    if (StrEqual(sOverrideTank, ""))
    {
        // Create our pool of players to choose from
        ArrayList infectedPool = new ArrayList(ByteCountToCells(64));
        addTeamSteamIdsToArray(infectedPool, L4D2Team_Infected);
        
        // If there is nobody on the infected team, return (otherwise we'd be stuck trying to select forever)
        if (GetArraySize(infectedPool) == 0)
        {
            delete infectedPool;
            return;
        }

        // Remove players who've already had tank from the pool.
        removeTanksFromPool(infectedPool, h_whosHadTank);
        
        // If the infected pool is empty, remove infected players from pool
        if (GetArraySize(infectedPool) == 0) // (when nobody on infected ,error)
        {
            ArrayList infectedTeam = new ArrayList(ByteCountToCells(64));
            addTeamSteamIdsToArray(infectedTeam, L4D2Team_Infected);
            if (GetArraySize(infectedTeam) > 1)
            {
                removeTanksFromPool(h_whosHadTank, infectedTeam);
                chooseTank(0);
            }
            else
            {
                queuedTankSteamId = "";
            }
            
            delete infectedTeam;
            delete infectedPool;
            return;
        }
        
        // Select a random person to become tank
        int rndIndex = GetRandomInt(0, GetArraySize(infectedPool) - 1);
        GetArrayString(infectedPool, rndIndex, queuedTankSteamId, sizeof(queuedTankSteamId));
        delete infectedPool;
    } else {
        strcopy(queuedTankSteamId, sizeof(queuedTankSteamId), sOverrideTank);
    }
}

/**
 * Make sure we give the tank to our queued player.
 */
 
public Action L4D_OnTryOfferingTankBot(int tank_index, bool &enterStatis)
{    
    // Reset the tank's frustration if need be
    if (! IsFakeClient(tank_index)) 
    {
        PrintHintText(tank_index, "Rage Meter Refilled");
        for (int i = 1; i <= MaxClients; i++) 
        {
            if (! IsClientInGame(i) || GetClientTeam(i) != 3)
                continue;

            if (tank_index == i) CPrintToChat(i, "{red}<{default}Tank Rage{red}> {olive}Rage Meter {red}Refilled");
            else CPrintToChat(i, "{red}<{default}Tank Rage{red}> {default}({green}%N{default}'s) {olive}Rage Meter {red}Refilled", tank_index);
        }
        
        SetTankFrustration(tank_index, 100);
        L4D2Direct_SetTankPassedCount(L4D2Direct_GetTankPassedCount() + 1);
        
        return Plugin_Handled;
    }

    //Allow third party plugins to override tank selection
    char sOverrideTank[64];
    sOverrideTank[0] = '\0';
    Call_StartForward(hForwardOnTryOfferingTankBot);
    Call_PushStringEx(sOverrideTank, sizeof(sOverrideTank), SM_PARAM_STRING_UTF8, SM_PARAM_COPYBACK);
    Call_Finish();
    if (!StrEqual(sOverrideTank, "")) {
        strcopy(queuedTankSteamId, sizeof(queuedTankSteamId), sOverrideTank);
    }
    
    // If we don't have a queued tank, choose one
    if (! strcmp(queuedTankSteamId, ""))
        chooseTank(0);
    
    // Mark the player as having had tank
    if (strcmp(queuedTankSteamId, "") != 0)
    {
        setTankTickets(queuedTankSteamId, 20000);
        PushArrayString(h_whosHadTank, queuedTankSteamId);
    }
    
    return Plugin_Continue;
}

/**
 * Sets the amount of tickets for a particular player, essentially giving them tank.
 */
 
public void setTankTickets(const char[] steamId, int tickets)
{
    int tankClientId = getInfectedPlayerBySteamId(steamId);
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && ! IsFakeClient(i) && GetClientTeam(i) == 3)
        {
            L4D2Direct_SetTankTickets(i, (i == tankClientId) ? tickets : 0);
        }
    }
}

/**
 * Output who will become tank
 */
 
public void outputTankToAll(any data)
{
    char tankClientName[MAX_NAME_LENGTH];
    int tankClientId = getInfectedPlayerBySteamId(queuedTankSteamId);
    
    if (tankClientId != -1)
    {
        GetClientName(tankClientId, tankClientName, sizeof(tankClientName));
        if (GetConVarBool(hTankPrint))
        {
            CPrintToChatAll("{red}<{default}Tank Selection{red}> {olive}%s {default}will become the {red}Tank!", tankClientName);
        }
        else
        {
            for (int i = 1; i <= MaxClients; i++) 
            {
                if (!IS_VALID_INFECTED(i) && !IS_VALID_CASTER(i))
                continue;

                if (tankClientId == i) CPrintToChat(i, "{red}<{default}Tank Selection{red}> {green}You {default}will become the {red}Tank{default}!");
                else CPrintToChat(i, "{red}<{default}Tank Selection{red}> {olive}%s {default}will become the {red}Tank!", tankClientName);
            }
        }
    }
}

stock void PrintToInfected(const char[] Message, any ... )
{
    char sPrint[256];
    VFormat(sPrint, sizeof(sPrint), Message, 2);

    for (int i = 1; i <= MaxClients; i++) 
    {
        if (!IS_VALID_INFECTED(i) && !IS_VALID_CASTER(i)) 
        { 
            continue; 
        }

        CPrintToChat(i, "{default}%s", sPrint);
    }
}
/**
 * Adds steam ids for a particular team to an array.
 * 
 * @ param Handle:steamIds
 *     The array steam ids will be added to.
 * @param L4D2Team:team
 *     The team to get steam ids for.
 */
 
public void addTeamSteamIdsToArray(ArrayList steamIds, L4D2Team team)
{
    char steamId[64];

    for (int i = 1; i <= MaxClients; i++)
    {
        // Basic check
        if (IsClientInGame(i) && ! IsFakeClient(i))
        {
            // Checking if on our desired team
            if (view_as<L4D2Team>(GetClientTeam(i)) != team)
                continue;
        
            GetClientAuthId(i, AuthId_Steam2, steamId, sizeof(steamId));
            PushArrayString(steamIds, steamId);
        }
    }
}

/**
 * Removes steam ids from the tank pool if they've already had tank.
 * 
 * @param Handle:steamIdTankPool
 *     The pool of potential steam ids to become tank.
 * @ param Handle:tanks
 *     The steam ids of players who've already had tank.
 * 
 * @return
 *     The pool of steam ids who haven't had tank.
 */
 
public void removeTanksFromPool(ArrayList steamIdTankPool, ArrayList tanks)
{
    int index;
    char steamId[64];
    
    int ArraySize = GetArraySize(tanks);
    for (int i = 0; i < ArraySize; i++)
    {
        GetArrayString(tanks, i, steamId, sizeof(steamId));
        index = FindStringInArray(steamIdTankPool, steamId);
        
        if (index != -1)
        {
            RemoveFromArray(steamIdTankPool, index);
        }
    }
}

/**
 * Retrieves a player's client index by their steam id.
 * 
 * @param const String:steamId[]
 *     The steam id to look for.
 * 
 * @return
 *     The player's client index.
 */
 
public int getInfectedPlayerBySteamId(const char[] steamId) 
{
    char tmpSteamId[64];
   
    for (int i = 1; i <= MaxClients; i++) 
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != 3)
            continue;
        
        GetClientAuthId(i, AuthId_Steam2, tmpSteamId, sizeof(tmpSteamId));     
        
        if (strcmp(steamId, tmpSteamId) == 0)
            return i;
    }
    
    return -1;
}

void SetTankFrustration(int iTankClient, int iFrustration) {
    if (iFrustration < 0 || iFrustration > 100) {
        return;
    }
    
    SetEntProp(iTankClient, Prop_Send, "m_frustration", 100-iFrustration);
}