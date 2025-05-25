#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>

#define TEAM_SURVIVORS 2

ConVar g_hVsBossBuffer;

public Plugin myinfo =
{
	name = "L4D2 Survivor Progress",
	author = "CanadaRox, Visor",
	description = "Print survivor progress in flow percents ",
	version = "2.0.5",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	LoadTranslation("current.phrases");
	g_hVsBossBuffer = FindConVar("versus_boss_buffer");

	RegConsoleCmd("sm_cur", CurrentCmd);
	RegConsoleCmd("sm_current", CurrentCmd);
}

Action CurrentCmd(int client, int args)
{
	int boss_proximity = RoundToNearest(GetBossProximity() * 100.0);
	CPrintToChat(client, "%t %t", "Tag", "Current", boss_proximity);
	return Plugin_Handled;
}

/**
 * Calculates the proximity of the boss to the survivors.
 *
 * @return The proximity value, ranging from 0.0 to 1.0.
 */
float GetBossProximity()
{
	float proximity = GetMaxSurvivorCompletion() + g_hVsBossBuffer.FloatValue / L4D2Direct_GetMapMaxFlowDistance();

	return (proximity > 1.0) ? 1.0 : proximity;
}

/**
 * Calculates the maximum completion flow for survivors in the game.
 *
 * @return The maximum completion flow for survivors.
 */
float GetMaxSurvivorCompletion()
{
	float flow = 0.0, tmp_flow = 0.0;
	Address pNavArea;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS && IsPlayerAlive(i)) {
			pNavArea = L4D_GetLastKnownArea(i);
			if (pNavArea != Address_Null) {
				tmp_flow = L4D2Direct_GetTerrorNavAreaFlow(pNavArea);
				flow = (flow > tmp_flow) ? flow : tmp_flow;
			}
		}
	}

	return (flow / L4D2Direct_GetMapMaxFlowDistance());
}

/**
 * Check if the translation file exists
 *
 * @param translation	Translation name.
 * @noreturn
 */
stock void LoadTranslation(const char[] translation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}
