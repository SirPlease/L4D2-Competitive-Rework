#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define GAMEDATA_FILE "staggersolver"

public Plugin:myinfo =
{
	name = "Super Stagger Solver",
	author = "CanadaRox",
	description = "Blocks all button presses during stumbles",
	version = "(^.^)",
};

new Handle:g_hGameConf;
new Handle:g_hIsStaggering;

public OnPluginStart()
{
	g_hGameConf = LoadGameConfigFile(GAMEDATA_FILE);
	if (g_hGameConf == INVALID_HANDLE)
		SetFailState("[Stagger Solver] Could not load game config file.");

	StartPrepSDKCall(SDKCall_Player);

	if (!PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "IsStaggering"))
		SetFailState("[Stagger Solver] Could not find signature IsStaggering.");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hIsStaggering = EndPrepSDKCall();
	if (g_hIsStaggering == INVALID_HANDLE)
		SetFailState("[Stagger Solver] Failed to load signature IsStaggering");

	CloseHandle(g_hGameConf);
}

public Action:OnPlayerRunCmd(client, &buttons)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && SDKCall(g_hIsStaggering, client))
	{
		buttons = 0;
	}
	return Plugin_Continue;
}

