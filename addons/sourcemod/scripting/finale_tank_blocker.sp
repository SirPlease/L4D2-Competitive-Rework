#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define FINALE_STAGE_TANK 8

StringMap
	g_hFinaleExceptionMaps = null;

int
	g_iTankCount[2] = {0, 0};

public Plugin myinfo =
{
	name = "Finale Even-Numbered Tank Blocker",
	author = "Stabby, Visor",
	description = "Blocks even-numbered non-flow finale tanks.",
	version = "2.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	RegServerCmd("finale_tank_default", SetFinaleExceptionMap);

	g_hFinaleExceptionMaps = new StringMap();
}

public void OnMapEnd()
{
	g_iTankCount[0] = 0;
	g_iTankCount[1] = 0;
}

public Action SetFinaleExceptionMap(int iArgs)
{
	if (iArgs != 1) {
		PrintToServer("Usage: finale_tank_default <mapname>");
		LogError("Usage: finale_tank_default <mapname>");
		return Plugin_Handled;
	}
	
	char sMapName[64];
	GetCmdArg(1, sMapName, sizeof(sMapName));
	g_hFinaleExceptionMaps.SetValue(sMapName, true);

	return Plugin_Handled;
}

public Action L4D2_OnChangeFinaleStage(int &iFinaleType, const char[] sArg)
{
	char sMapName[64];
	GetCurrentMap(sMapName, sizeof(sMapName));

	int iValue = 0;
	if (g_hFinaleExceptionMaps.GetValue(sMapName, iValue)) {
		return Plugin_Continue;
	}

	if (iFinaleType == FINALE_STAGE_TANK) {
		if (++g_iTankCount[GameRules_GetProp("m_bInSecondHalfOfRound")] % 2 == 0) {
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}
