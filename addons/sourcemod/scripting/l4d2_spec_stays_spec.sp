#include <sourcemod>
#pragma semicolon 1

#define ACTIVE_SECONDS 	120
/*
* Debug modes:
* 0 = disabled
* 1 = server console
* 2 = fileoutput "l4d2_spec_stays_spec.txt"
*/
#define DEBUG_MODE 0
#define MAX_SPECTATORS 	24
#define PLUGIN_VERSION 	"1.0.1"
#define STEAMID_LENGTH 	32

new Handle:g_hMaxSurvivors            = INVALID_HANDLE;
new Handle:g_hMaxInfected             = INVALID_HANDLE;

/*
* plugin info
* #######################
*/
public Plugin:myinfo =
{
    name = "Spectator stays spectator",
    author = "Die Teetasse",
    description = "Spectator will stay as spectators on mapchange.",
    version = PLUGIN_VERSION,
    url = ""
};

/*
* global variables
* #######################
*/
new lastTimestamp = 0;
new spectatorCount = 0;
new Handle:spectatorTimer[MAX_SPECTATORS];
new String:spectatorSteamIds[MAX_SPECTATORS][STEAMID_LENGTH];

/*
* plugin start - check game
* #######################
*/
public OnPluginStart() {
    decl String:gameFolder[12];
    GetGameFolderName(gameFolder, sizeof(gameFolder));
    if (StrContains(gameFolder, "left4dead") == -1) SetFailState("Spec stays spec work with Left 4 Dead 1 or 2 only!");
    
    HookEvent("round_start", Event_Round_Start);
    
    g_hMaxSurvivors = FindConVar("survivor_limit");
    g_hMaxInfected = FindConVar("z_max_player_zombies");
}

/*
* map start - hook event
* #######################
*/
public OnMapStart() {
    HookEvent("round_end", Event_Round_End);
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
    CreateTimer(15.0, Check4Spec, _, TIMER_REPEAT);
}

public Action:Check4Spec(Handle:timer)
{
    if (GetRealClientCount() != (GetConVarInt(g_hMaxSurvivors) + GetConVarInt(g_hMaxInfected))) return Plugin_Continue;
    
    for (new i = 1; i <= GetMaxClients(); i++) 
    {
        if(IsClientInGame(i) && IsClientConnected(i) && GetClientTeam(i) == 1) FakeClientCommand(i, "say /spectate");   
    }
    return Plugin_Stop;
}


/*
* round end event - save spec steamids
* #######################
*/
public Action:Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast) {
    spectatorCount = 0;
    
    // clear arrays and kill timers
    for (new i = 0; i < MAX_SPECTATORS; i++) {
        spectatorSteamIds[i] = "";
        
        if (spectatorTimer[i] != INVALID_HANDLE) {
            KillTimer(spectatorTimer[i]);
            spectatorTimer[i] = INVALID_HANDLE;
        }
    }
    
    // get steamids
    for (new i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        if (GetClientTeam(i) != 1) continue;
        
        GetClientAuthId(i, AuthId_Steam2, spectatorSteamIds[spectatorCount], STEAMID_LENGTH);
        spectatorCount++;
    }	
    
    // set timestamp
    lastTimestamp = GetTime();
    
    return Plugin_Continue;
}

/*
* client authorisation - check and create timer if neccessary
* #######################
*/
public OnClientAuthorized(client, const String:auth[]) {
    // get timestamp
    new currentTimestamp = GetTime();
    
    // check timestamp
    if ((currentTimestamp - lastTimestamp) > ACTIVE_SECONDS) return;
    
    // find steamid
    new index = Function_GetIndex(auth);
    if (index == -1) return;
    
    // create move timer
    spectatorTimer[index] = CreateTimer(1.0, Timer_MoveToSpec, client, TIMER_REPEAT);
}

/*
* move to spec timer - checks for ingame and move the client
* #######################
*/
public Action:Timer_MoveToSpec(Handle:timer, any:client) {
    // check ingame - if not => repeat
    if (!IsClientInGame(client)) return Plugin_Continue;
    
    // get steamid
    new String:auth[STEAMID_LENGTH];
    GetClientAuthId(client, AuthId_Steam2, auth, STEAMID_LENGTH);
    
    // find index
    new index = Function_GetIndex(auth);
    
    // check index (this should not happen^^)
    if (index == -1) return Plugin_Stop;
    
    // reset timer handle
    spectatorTimer[index] = INVALID_HANDLE;
    
    // check team - if already spec => stop
    new team = GetClientTeam(client);
    if (team == 1)
    {
        CreateTimer(2.0, ReSpec, client);
        return Plugin_Stop;
    }
    
    // get client name
    decl String:name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));
    
    // change team and stop
    ChangeClientTeam(client, 1);
    CreateTimer(2.0, ReSpec, client);
    //PrintToChatAll("[SM] Found %s in %s team. Moved him back to spec team.", name, (team == 2) ? "survivor" : "infected");
    
    return Plugin_Stop;
}

public Action:ReSpec(Handle:timer, any:client)
{
    if(IsValidClient(client) && IsClientInGame(client) && GetClientTeam(client) == 1) FakeClientCommand(client, "say /spectate");
}

/*
* client disconnect - stop timer
* #######################
*/
public OnClientDisconnect(client) {
    // get steamid
    new String:clientSteamId[STEAMID_LENGTH];
    GetClientAuthId(client, AuthId_Steam2, clientSteamId, STEAMID_LENGTH);
    
    // find index
    new index = Function_GetIndex(clientSteamId);
    
    // check index
    if (index == -1) return;
    
    // check timer
    if (spectatorTimer[index] == INVALID_HANDLE) return;
    
    // kill timer
    KillTimer(spectatorTimer[index]);
    spectatorTimer[index] = INVALID_HANDLE;
}

/*
* private function - find steamid in array and return index
* #######################
*/
Function_GetIndex(const String:clientSteamId[]) {
    // loop through steamids
    for (new i = 0; i < spectatorCount; i++) {
        if (StrEqual(spectatorSteamIds[i], clientSteamId)) return i;	
    }
    
    return -1;
}

GetRealClientCount() 
{
    new clients = 0;
    for (new i = 1; i <= GetMaxClients(); i++) 
    {
        if(IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i) && GetClientTeam(i) != 1) clients++;
    }
    return clients;
}

bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return true;
}