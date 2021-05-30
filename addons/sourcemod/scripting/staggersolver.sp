#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define GAMEDATA_FILE "staggersolver"
#define SIGNATURE_NAME "IsStaggering"

public Plugin myinfo =
{
	name = "Super Stagger Solver",
	author = "CanadaRox, A1m (fix)",
	description = "Blocks all button presses during stumbles",
	version = "1.1",
};

Handle g_hIsStaggering;

public void OnPluginStart()
{
	Handle g_hGameConf = LoadGameConfigFile(GAMEDATA_FILE);
	if (g_hGameConf == INVALID_HANDLE) {
		SetFailState("[Stagger Solver] Could not load game config file '%s'.", GAMEDATA_FILE);
	}
	
	StartPrepSDKCall(SDKCall_Player);

	if (!PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, SIGNATURE_NAME)) {
		SetFailState("[Stagger Solver] Could not find signature '%s' in gamedata.", SIGNATURE_NAME);
	}
	
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hIsStaggering = EndPrepSDKCall();
	
	if (g_hIsStaggering == INVALID_HANDLE) {
		SetFailState("[Stagger Solver] Failed to load signature '%s'", SIGNATURE_NAME);
	}
	
	delete g_hGameConf;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && SDKCall(g_hIsStaggering, client)) {
		/*
			* if you shoved the infected player with the butt while moving on the ladder, 
			* he will not be able to move until he is killed
		*/
		if (GetEntityMoveType(client) != MOVETYPE_LADDER) {
			buttons = 0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
