#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define ACTIVE_SECONDS 	120
/*
* Debug modes:
* 0 = disabled
* 1 = server console
* 2 = fileoutput "l4d2_spec_stays_spec.txt"
*/
#define DEBUG_MODE 0
#define MAX_SPECTATORS 	24
#define PLUGIN_VERSION 	"1.2"
#define STEAMID_LENGTH 	32

ConVar g_hMaxSurvivors;
ConVar g_hMaxInfected;

/*
* plugin info
* #######################
*/
public Plugin myinfo =
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
int lastTimestamp = 0;
int spectatorCount = 0;
Handle spectatorTimer[MAX_SPECTATORS];
char spectatorSteamIds[MAX_SPECTATORS][STEAMID_LENGTH];

/*
* ask plugin load - check game
* #######################
*/
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead, Engine_Left4Dead2:
		{
			return APLRes_Success;
		}
		default:
		{
			strcopy(error, err_max, "Spec stays spec work with Left 4 Dead 1 or 2 only!");
			return APLRes_SilentFailure;
		}
	}
}

/*
* plugin start - check game
* #######################
*/
public void OnPluginStart() {
    HookEvent("round_start", Event_Round_Start);
    
    g_hMaxSurvivors = FindConVar("survivor_limit");
    g_hMaxInfected = FindConVar("z_max_player_zombies");
}

/*
* map start - hook event
* #######################
*/
public void OnMapStart() {
    HookEvent("round_end", Event_Round_End);
}

public void Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
    CreateTimer(15.0, Check4Spec, _, TIMER_REPEAT);
}

public Action Check4Spec(Handle timer)
{
    if (GetRealClientCount() != (GetConVarInt(g_hMaxSurvivors) + GetConVarInt(g_hMaxInfected))) return Plugin_Continue;
    
    for (int i = 1; i <= MaxClients; i++) 
    {
        if(IsClientInGame(i) && IsClientConnected(i) && GetClientTeam(i) == 1 && !IsClientSourceTV(i)) FakeClientCommand(i, "say /spectate");   
    }
    return Plugin_Stop;
}


/*
* round end event - save spec steamids
* #######################
*/
public void Event_Round_End(Event event, const char[] name, bool dontBroadcast) {
    spectatorCount = 0;
    
    // clear arrays and kill timers
    for (int i = 0; i < MAX_SPECTATORS; i++) {
        spectatorSteamIds[i] = "";
        
        if (spectatorTimer[i] != INVALID_HANDLE) {
            KillTimer(spectatorTimer[i]);
            spectatorTimer[i] = INVALID_HANDLE;
        }
    }
    
    // get steamids
    for (int i = 1; i <= MaxClients; i++) 
    {
        if (!IsClientInGame(i)) continue;
        if (IsFakeClient(i)) continue;
        if (GetClientTeam(i) != 1) continue;
        if (IsClientSourceTV(i)) continue;
        
        GetClientAuthId(i, AuthId_Steam2, spectatorSteamIds[spectatorCount], STEAMID_LENGTH);
        spectatorCount++;
    }	
    
    // set timestamp
    lastTimestamp = GetTime();
}

/*
* client authorisation - check and create timer if neccessary
* #######################
*/
public void OnClientAuthorized(int client, const char[] auth) {
    // get timestamp
    int currentTimestamp = GetTime();
    
    // check timestamp
    if ((currentTimestamp - lastTimestamp) > ACTIVE_SECONDS) return;
    
    // check fake client
    if (strcmp(auth, "BOT") == 0) return;
    
    // find steamid
    int index = Function_GetIndex(auth);
    if (index == -1) return;
    
    // create move timer
    spectatorTimer[index] = CreateTimer(1.0, Timer_MoveToSpec, client, TIMER_REPEAT);
}

/*
* move to spec timer - checks for ingame and move the client
* #######################
*/
public Action Timer_MoveToSpec(Handle timer, int client) {
    // check ingame - if not => repeat
    if (!IsClientInGame(client)) return Plugin_Continue;
    
    // get steamid
    char auth[STEAMID_LENGTH];
    GetClientAuthId(client, AuthId_Steam2, auth, STEAMID_LENGTH);
    
    // find index
    int index = Function_GetIndex(auth);
    
    // check index (this should not happen^^)
    if (index == -1) return Plugin_Stop;
    
    // reset timer handle
    spectatorTimer[index] = INVALID_HANDLE;
    
    // check team - if already spec => stop
    int team = GetClientTeam(client);
    if (team == 1)
    {
        CreateTimer(2.0, ReSpec, client);
        return Plugin_Stop;
    }
    
    // get client name
    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));
    
    // change team and stop
    ChangeClientTeam(client, 1);
    CreateTimer(2.0, ReSpec, client);
    //PrintToChatAll("[SM] Found %s in %s team. Moved him back to spec team.", name, (team == 2) ? "survivor" : "infected");
    
    return Plugin_Stop;
}

public Action ReSpec(Handle timer, int client)
{
    if(GetClientTeam(client) == 1) FakeClientCommand(client, "say /spectate");
}

/*
* client disconnect - stop timer
* #######################
*/
public void OnClientDisconnect(int client) {
    // get steamid
    char clientSteamId[STEAMID_LENGTH];
    GetClientAuthId(client, AuthId_Steam2, clientSteamId, STEAMID_LENGTH);
    
    // find index
    int index = Function_GetIndex(clientSteamId);
    
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
int Function_GetIndex(const char[] clientSteamId) {
    // loop through steamids
    for (int i = 0; i < spectatorCount; i++) {
        if (StrEqual(spectatorSteamIds[i], clientSteamId)) return i;	
    }
    
    return -1;
}

int GetRealClientCount() 
{
    int clients = 0;
    for (int i = 1; i <= MaxClients; i++) 
    {
        if(IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i) && GetClientTeam(i) != 1) clients++;
    }
    return clients;
}