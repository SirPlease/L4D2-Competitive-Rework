#include <sourcemod>
#include <left4dhooks>
#include <colors>

#undef REQUIRE_PLUGIN
#include "readyup"

#define L4D2_TEAM_SURVIVOR 2
#define L4D2_TEAM_INFECTED 3

public Plugin:myinfo =
{
    name = "L4D2 Auto-pause",
    author = "Darkid, Griffin",
    description = "When a player disconnects due to crash, automatically pause the game. When they rejoin, give them a correct spawn timer.",
    version = "2.0",
    url = "https://github.com/jbzdarkid/AutoPause"
}

new Handle:g_hCvarEnabled;
new Handle:g_hCvarForce;
new Handle:g_hCvarApdebug;

new Handle:crashedPlayers;
new Handle:infectedPlayers;
new Handle:survivorPlayers;

new bool:readyUpIsAvailable;
new bool:roundEnd;

public OnPluginStart() {
    // Suggestion by Nati: Disable for any 1v1
    g_hCvarEnabled = CreateConVar("autopause_enable", "1", "Whether or not to automatically pause when a player crashes.");
    g_hCvarForce = CreateConVar("autopause_force", "0", "Whether or not to force pause when a player crashes.");
    g_hCvarApdebug = CreateConVar("autopause_apdebug", "0", "Whether or not to debug information.");

    crashedPlayers = CreateTrie();
    infectedPlayers = CreateArray(64);
    survivorPlayers = CreateArray(64);

    HookEvent("round_start", RoundStart_Event);
    HookEvent("round_end", RoundEnd_Event);
    HookEvent("player_team", PlayerTeam_Event);
    HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
}

public OnAllPluginsLoaded()
{
    readyUpIsAvailable = LibraryExists("readyup");
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "readyup")) 
        readyUpIsAvailable = false;
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "readyup")) 
        readyUpIsAvailable = true;
}

public RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast) {
    ClearTrie(crashedPlayers);
    ClearArray(infectedPlayers);
    ClearArray(survivorPlayers);
    roundEnd = false;
}

public RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast) {
    roundEnd = true;
}

public PlayerTeam_Event(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client <= 0 || client > MaxClients) 
        return;

    decl String:steamId[64];
    GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
    if (strcmp(steamId, "BOT") == 0) 
        return;

    new infectedIndex = FindStringInArray(infectedPlayers, steamId);
    if (infectedIndex != -1) {
        RemoveFromArray(infectedPlayers, infectedIndex);

        if (GetConVarBool(g_hCvarApdebug)) 
            LogMessage("[AutoPause] Removed player %s from infected team.", steamId);
    }

    new survivorIndex = FindStringInArray(survivorPlayers, steamId);
    if (survivorIndex != -1) {
        RemoveFromArray(survivorPlayers, survivorIndex);

        if (GetConVarBool(g_hCvarApdebug)) 
            LogMessage("[AutoPause] Removed player %s from survivor team.", steamId);
    }

    new team = GetEventInt(event, "team");

    if (team == L4D2_TEAM_SURVIVOR) {
        PushArrayString(survivorPlayers, steamId);

        if (GetConVarBool(g_hCvarApdebug)) 
            LogMessage("[AutoPause] Added player %s to survivor team.", steamId);

        return;
    }

    if (team == L4D2_TEAM_INFECTED) {
        PushArrayString(infectedPlayers, steamId);

        if (GetConVarBool(g_hCvarApdebug)) 
            LogMessage("[AutoPause] Added player %s to infected team.", steamId);

        decl Float:spawnTime;
        if (GetTrieValue(crashedPlayers, steamId, spawnTime)) {
            new CountdownTimer:spawnTimer = L4D2Direct_GetSpawnTimer(client);
            CTimer_Start(spawnTimer, spawnTime);
            RemoveFromTrie(crashedPlayers, steamId);
            LogMessage("[AutoPause] Player %s rejoined, set spawn timer to %f.", steamId, spawnTime);
        }
    }
}

public PlayerDisconnect_Event(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client <= 0 || client > MaxClients) 
        return;

    decl String:steamId[64];
    GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
    if (strcmp(steamId, "BOT") == 0) 
        return;

    if (FindStringInArray(infectedPlayers, steamId) == -1 && FindStringInArray(survivorPlayers, steamId) == -1)
        return;

    decl String:reason[128];
    GetEventString(event, "reason", reason, sizeof(reason));

    decl String:playerName[128];
    GetEventString(event, "name", playerName, sizeof(playerName));

    decl String:timedOut[256];
    Format(timedOut, sizeof(timedOut), "%s timed out", playerName);

    if (GetConVarBool(g_hCvarApdebug)) 
        LogMessage("[AutoPause] Player %s (%s) left the game: %s", playerName, steamId, reason);

    // If the leaving player crashed, pause.
    if (strcmp(reason, timedOut) == 0 || strcmp(reason, "No Steam logon") == 0)
    {
        if ((!readyUpIsAvailable || !IsInReady()) && !roundEnd && GetConVarBool(g_hCvarEnabled)) 
        {
            if (GetConVarBool(g_hCvarForce)) 
            {
                ServerCommand("sm_forcepause");
            } 
            else 
            {
                FakeClientCommand(client, "sm_pause");
            }
            CPrintToChatAll("{blue}[{default}AutoPause{blue}] {olive}%s {default}crashed.", playerName);
        }
    }

    // If the leaving player was on infected, save their spawn timer.
    if (FindStringInArray(infectedPlayers, steamId) != -1) {
        decl Float:timeLeft;
        new CountdownTimer:spawnTimer = L4D2Direct_GetSpawnTimer(client);
        if (spawnTimer != CTimer_Null) {
            timeLeft = CTimer_GetRemainingTime(spawnTimer);
            LogMessage("[AutoPause] Player %s left the game with %f time until spawn.", steamId, timeLeft);
            SetTrieValue(crashedPlayers, steamId, timeLeft);
        }
    }
}