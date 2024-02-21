#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"
#define g_Cvar_Rank RANK
#define g_Cvar_PlayersServed SERVED

Handle g_Cvar_Rank
Handle g_Cvar_PlayersServed
 
public Plugin:myinfo =
{
	name = "L4D Server World Wide Rank",
	author = ".Rain",
	description = "Changes server rank and number of players served.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/KadabraZz/"
};

public void OnPluginStart()
{
    g_Cvar_Rank           = CreateConVar("l4d_serverranking", "1", "This will change the world ranking of the server", FCVAR_NOTIFY);
    g_Cvar_PlayersServed  = CreateConVar("l4d_playersserved", "4000", "This will change the number of players served from the server", FCVAR_NOTIFY);	
}

public OnClientConnected()
{
	ServerRanking();
}

public OnClientDisconnect()
{
	ServerRanking();
}

ServerRanking()
{
	GameRules_SetProp("m_iServerRank", any:(GetConVarInt(RANK)), 4, 0, false);
	GameRules_SetProp("m_iServerPlayerCount", any:(GetConVarInt(SERVED)), 4, 0, false);
}