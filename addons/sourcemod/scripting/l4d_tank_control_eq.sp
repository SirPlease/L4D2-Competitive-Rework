#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <readyup>
#include <sourcemod>
#include <left4dhooks>

#define TEAM_SPECTATOR          1
#define TEAM_INFECTED           3
#define ZOMBIECLASS_TANK        6
#define IS_SPECTATOR(%1)        (GetClientTeam(%1) == TEAM_SPECTATOR)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == TEAM_INFECTED)
#define IS_VALID_INFECTED(%1)   (IsClientInGame(%1) && IS_INFECTED(%1))
#define IS_VALID_SPECTATOR(%1)  (IsClientInGame(%1) && IS_SPECTATOR(%1))

ArrayList h_whosHadTank;

ConVar 
    hTankPrint, 
    hTankDebug;

GlobalForward
    hForwardOnTryOfferingTankBot,
    hForwardOnTankSelection;

char 
    queuedTankSteamId[64],
    tankInitiallyChosen[64];

int dcedTankFrustration = -1;
float fTankGrace;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("GetTankSelection", Native_GetTankSelection);

    hForwardOnTryOfferingTankBot = new GlobalForward("TankControl_OnTryOfferingTankBot", ET_Ignore, Param_String);
    hForwardOnTankSelection = new GlobalForward("TankControl_OnTankSelection", ET_Ignore, Param_String);

    return APLRes_Success;
}

public int Native_GetTankSelection(Handle plugin, int numParams) { return getInfectedPlayerBySteamId(queuedTankSteamId); }

public Plugin myinfo = 
{
    name = "L4D2 Tank Control",
    author = "arti, (Contributions by: Sheo, Sir, Altair-Sossai)",
    description = "Distributes the role of the tank evenly throughout the team, allows for overrides. (Includes forwards)",
    version = "0.0.21",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
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


/*=========================================================================
|                            Left4Dhooks                                  |
=========================================================================*/


public void L4D2_OnTankPassControl(int iOldTank, int iNewTank, int iPassCount)
{
    /*
    * As the Player switches to AI on disconnect/team switch, we have to make sure we're only checking this if the old Tank was AI.
    * Then apply the previous' Tank's Frustration and Grace Period (if it still had Grace)
    * We'll also be keeping the same Tank pass, which resolves Tanks that dc on 1st pass resulting into the Tank instantly going to 2nd pass.
    */
    if (dcedTankFrustration != -1 && IsFakeClient(iOldTank))
    {
        SetTankFrustration(iNewTank, dcedTankFrustration);
        CTimer_Start(GetFrustrationTimer(iNewTank), fTankGrace);
        L4D2Direct_SetTankPassedCount(L4D2Direct_GetTankPassedCount() - 1);
    }
}

/**
 * Make sure we give the tank to our queued player.
 */
public Action L4D_OnTryOfferingTankBot(int tank_index, bool &enterStatis)
{    
    // Reset the tank's frustration if need be
    if (!IsFakeClient(tank_index)) 
    {
        PrintHintText(tank_index, "Rage Meter Refilled");
        for (int i = 1; i <= MaxClients; i++) 
        {
            if (!IS_VALID_INFECTED(i) && !IS_VALID_SPECTATOR(i))
                continue;

            if (tank_index == i) 
                CPrintToChat(i, "{red}<{default}Tank Rage{red}> {olive}Rage Meter {red}Refilled");
            else 
                CPrintToChat(i, "{red}<{default}Tank Rage{red}> {default}({green}%N{default}'s) {olive}Rage Meter {red}Refilled", tank_index);
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

    if (!StrEqual(sOverrideTank, ""))
        strcopy(queuedTankSteamId, sizeof(queuedTankSteamId), sOverrideTank);
    
    // If we don't have a queued tank, choose one
    if (!strcmp(queuedTankSteamId, ""))
        chooseTank(0);
    
    // Mark the player as having had tank
    if (strcmp(queuedTankSteamId, "") != 0)
    {
        setTankTickets(queuedTankSteamId, 20000);
        h_whosHadTank.PushString(queuedTankSteamId);
    }
    
    return Plugin_Continue;
}


/*=========================================================================
|                                 Events                                  |
=========================================================================*/


/**
 * When a new game starts, reset the tank pool.
 */
public void RoundStart_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    CreateTimer(10.0, newGame);
    dcedTankFrustration = -1;
    tankInitiallyChosen = "";
}

Action newGame(Handle timer)
{
    int teamAScore = L4D2Direct_GetVSCampaignScore(0);
    int teamBScore = L4D2Direct_GetVSCampaignScore(1);

    // If it's a new game, reset the tank pool
    if (teamAScore == 0 && teamBScore == 0)
    {
        h_whosHadTank.Clear();
        queuedTankSteamId = "";
        tankInitiallyChosen = "";
    }

    return Plugin_Stop;
}

/**
 * When the round ends, reset the active tank.
 */
public void RoundEnd_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    queuedTankSteamId = "";
    tankInitiallyChosen = "";
}

/**
 * When a player leaves the start area, choose a tank and output to all.
 */
public void PlayerLeftStartArea_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    tankInitiallyChosen = "";

    chooseTank(0);
    outputTankToAll(0);
}

/**
 * When the queued tank switches teams, choose a new one
 */
public void PlayerTeam_Event(Event hEvent, const char[] name, bool dontBroadcast)
{
    int team = hEvent.GetInt("team");
    int oldTeam = hEvent.GetInt("oldteam");
    int client = GetClientOfUserId(hEvent.GetInt("userid"));
    char tmpSteamId[64];

    if (client < 1 || client > MaxClients)
        return;

    if (oldTeam == TEAM_INFECTED)
    {
        /*
        * Triggers for disconnects as well as forced-swaps and whatnot.
        * Allows us to always reliably detect when the current Tank player loses control due to unnatural reasons.
        */
        if (!IsFakeClient(client))
        {
            int zombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
            if (zombieClass == ZOMBIECLASS_TANK)
            {
                dcedTankFrustration = GetTankFrustration(client);
                fTankGrace = CTimer_GetRemainingTime(GetFrustrationTimer(client));

                // Slight fix due to the timer seemingly always getting stuck between 0.5s~1.2s even after Grace period has passed.
                // CTimer_IsElapsed still returns false as well.
                if (fTankGrace < 0.0 || dcedTankFrustration < 100) 
                    fTankGrace = 0.0;
            }
        }

        GetClientAuthId(client, AuthId_Steam2, tmpSteamId, sizeof(tmpSteamId));
        if (strcmp(queuedTankSteamId, tmpSteamId) == 0)
        {
            RequestFrame(chooseTank, 0);
            RequestFrame(outputTankToAll, 0);
        }
    }

    if (team == TEAM_INFECTED && !IsFakeClient(client) && !StrEqual(tankInitiallyChosen, ""))
    {
        GetClientAuthId(client, AuthId_Steam2, tmpSteamId, sizeof(tmpSteamId));
        if (strcmp(tankInitiallyChosen, tmpSteamId) == 0)
        {
            strcopy(queuedTankSteamId, sizeof(queuedTankSteamId), tankInitiallyChosen);
            RequestFrame(outputTankToAll, 0);
        }
    }
}

/**
 * When the tank dies, requeue a player to become tank (for finales)
 */
public void PlayerDeath_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    int victim = GetClientOfUserId(hEvent.GetInt("userid"));
    
    if (victim && IS_VALID_INFECTED(victim)) 
    {
        int zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
        if (zombieClass == ZOMBIECLASS_TANK) 
        {
            if (hTankDebug.BoolValue)
                PrintToConsoleAll("[TC] Tank died(1), choosing a new tank");

            tankInitiallyChosen = "";
            chooseTank(0);
        }
    }
}

public void TankKilled_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    if (hTankDebug.BoolValue)
        PrintToConsoleAll("[TC] Tank died(2), choosing a new tank");

    tankInitiallyChosen = "";
    chooseTank(0);
    dcedTankFrustration = -1;
}


/*=========================================================================
|                               Commands                                  |
=========================================================================*/


/**
 * When a player wants to find out whos becoming tank,
 * output to them.
 */
Action Tank_Cmd(int client, int args)
{
    // Only output if client is in-game and we have a queued tank
    if (!IsClientInGame(client) || strcmp(queuedTankSteamId, ""))
        return Plugin_Handled;
    
    int tankClientId = getInfectedPlayerBySteamId(queuedTankSteamId);

    if (tankClientId != -1 && (hTankPrint.BoolValue || IS_INFECTED(client) || IS_SPECTATOR(client)))
    {
        if (client == tankClientId) 
            CPrintToChat(client, "{red}<{default}Tank Selection{red}> {green}You {default}will become the {red}Tank{default}!");
        else 
            CPrintToChat(client, "{red}<{default}Tank Selection{red}> {olive}%N {default}will become the {red}Tank!", tankClientId);
    }
    
    return Plugin_Handled;
}

/**
 * Shuffle the tank (randomly give to another player in
 * the pool.
 */
Action TankShuffle_Cmd(int client, int args)
{
    tankInitiallyChosen = "";

    chooseTank(0);
    outputTankToAll(0);
    
    return Plugin_Handled;
}

/**
 * Give the tank to a specific player.
 */
Action GiveTank_Cmd(int client, int args)
{    
    // Who are we targetting?
    char arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    
    // Try and find a matching player
    int target = FindTarget(client, arg1);

    if (target == -1 || !IsClientInGame(target) || IsFakeClient(target))
    {
        CPrintToChat(client, "{green}[{olive}Tank Control{green}] {default}Invalid Target. Unable to give tank");
        return Plugin_Handled;
    }

    // Checking if on our desired team
    if (!IS_INFECTED(target))
    {
        CPrintToChat(client, "{green}[{olive}Tank Control{green}] {olive}%N {default}is not on the infected team. Unable to give tank", target);
        return Plugin_Handled;
    }
    
    // Set the tank
    char steamId[64];
    GetClientAuthId(target, AuthId_Steam2, steamId, sizeof(steamId));

    strcopy(queuedTankSteamId, sizeof(queuedTankSteamId), steamId);
    strcopy(tankInitiallyChosen, sizeof(tankInitiallyChosen), steamId);

    outputTankToAll(0);
    
    return Plugin_Handled;
}


/*=========================================================================
|                                 Stocks                                  |
=========================================================================*/


/**
 * Selects a player on the infected team from random who hasn't been
 * tank and gives it to them.
 */
void chooseTank(any data)
{
    // Allow other plugins to override tank selection.
    char sOverrideTank[64];
    sOverrideTank[0] = '\0';
    Call_StartForward(hForwardOnTankSelection);
    Call_PushStringEx(sOverrideTank, sizeof(sOverrideTank), SM_PARAM_STRING_UTF8, SM_PARAM_COPYBACK);
    Call_Finish();

    if (StrEqual(sOverrideTank, ""))
    {
        // Create our pool of players to choose from.
        ArrayList infectedPool = new ArrayList(ByteCountToCells(64));
        addTeamSteamIdsToArray(infectedPool, TEAM_INFECTED);
        
        // If there is nobody on the infected team, return (otherwise we'd be stuck trying to select forever)
        if (infectedPool.Length == 0)
        {
            delete infectedPool;
            return;
        }

        // Remove players who've already had tank from the pool.
        removeTanksFromPool(infectedPool, h_whosHadTank);
        
        // If the infected pool is empty, remove infected players from pool
        if (infectedPool.Length == 0) // (when nobody on infected ,error)
        {
            ArrayList infectedTeam = new ArrayList(ByteCountToCells(64));
            addTeamSteamIdsToArray(infectedTeam, TEAM_INFECTED);
            if (infectedTeam.Length > 1)
            {
                removeTanksFromPool(h_whosHadTank, infectedTeam);
                chooseTank(0);
            }
            else
                queuedTankSteamId = "";
            
            delete infectedTeam;
            delete infectedPool;
            return;
        }
        
        // Select a random person to become tank
        int rndIndex = GetRandomInt(0, infectedPool.Length - 1);
        infectedPool.GetString(rndIndex, queuedTankSteamId, sizeof(queuedTankSteamId));

        if (StrEqual(tankInitiallyChosen, ""))
            strcopy(tankInitiallyChosen, sizeof(tankInitiallyChosen), queuedTankSteamId);

        delete infectedPool;
    } 
    else
        strcopy(queuedTankSteamId, sizeof(queuedTankSteamId), sOverrideTank);
}

/**
 * Sets the amount of tickets for a particular player, essentially giving them tank.
 */
void setTankTickets(const char[] steamId, int tickets)
{
    int tankClientId = getInfectedPlayerBySteamId(steamId);
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IS_VALID_INFECTED(i) && !IsFakeClient(i))
            L4D2Direct_SetTankTickets(i, (i == tankClientId) ? tickets : 0);
    }
}

/**
 * Output who will become tank
 */
void outputTankToAll(any data)
{
    int tankClientId = getInfectedPlayerBySteamId(queuedTankSteamId);
    
    if (tankClientId != -1)
    {
        for (int i = 1; i <= MaxClients; i++) 
        {
            if (!IsClientInGame(i) || (!hTankPrint.BoolValue && !IS_INFECTED(i) && !IS_SPECTATOR(i)))
                continue;

            if (tankClientId == i) 
                CPrintToChat(i, "{red}<{default}Tank Selection{red}> {green}You {default}will become the {red}Tank{default}!");
            else 
                CPrintToChat(i, "{red}<{default}Tank Selection{red}> {olive}%N {default}will become the {red}Tank!", tankClientId);
        }
    }
}

/**
 * Adds steam ids for a particular team to an array.
 * 
 * @param steamIds
 *     The array steam ids will be added to.
 * @param team
 *     The team to get steam ids for.
 */
void addTeamSteamIdsToArray(ArrayList steamIds, int team)
{
    char steamId[64];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != team)
            continue;
        
        GetClientAuthId(i, AuthId_Steam2, steamId, sizeof(steamId));
        steamIds.PushString(steamId);
    }
}

/**
 * Removes steam ids from the tank pool if they've already had tank.
 * 
 * @param steamIdTankPool
 *     The array containing potential steam ids to become tank.
 * @param tanks
 *     The array containing steam ids of players who've already had tank.
 */
void removeTanksFromPool(ArrayList steamIdTankPool, ArrayList tanks)
{
    int index;
    char steamId[64];
    int ArraySize = tanks.Length;

    for (int i = 0; i < ArraySize; i++)
    {
        tanks.GetString(i, steamId, sizeof(steamId));
        index = steamIdTankPool.FindString(steamId);
        
        if (index != -1)
            steamIdTankPool.Erase(index);
    }
}

/**
 * Retrieves a player's client index by their steam id.
 * 
 * @param steamId
 *     The steam id string to look for.
 * 
 * @return
 *     The player's client index or -1 if not found.
 */
int getInfectedPlayerBySteamId(const char[] steamId) 
{
    char tmpSteamId[64];
   
    for (int i = 1; i <= MaxClients; i++) 
    {
        if (!IS_VALID_INFECTED(i))
            continue;

        GetClientAuthId(i, AuthId_Steam2, tmpSteamId, sizeof(tmpSteamId));
        
        if (strcmp(steamId, tmpSteamId) == 0)
            return i;
    }
    
    return -1;
}

void SetTankFrustration(int iTankClient, int iFrustration) 
{
    if (iFrustration >= 0 && iFrustration <= 100)
        SetEntProp(iTankClient, Prop_Send, "m_frustration", 100-iFrustration);
}

int GetTankFrustration(int iTankClient) 
{
    return 100 - GetEntProp(iTankClient, Prop_Send, "m_frustration");
}

CountdownTimer GetFrustrationTimer(int client)
{
    static int s_iOffs_m_frustrationTimer = -1;

    if (s_iOffs_m_frustrationTimer == -1)
        s_iOffs_m_frustrationTimer = FindSendPropInfo("CTerrorPlayer", "m_frustration") + 4;
    
    return view_as<CountdownTimer>(GetEntityAddress(client) + view_as<Address>(s_iOffs_m_frustrationTimer));
}
