#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

ConVar
	g_hCvarEnabled = null,
	g_hCvarSkipStaticMaps = null;

public Plugin myinfo =
{
	name = "Versus Boss Spawn Persuasion",
	author = "ProdigySim",
	description = "Makes Versus Boss Spawns obey cvars",
	version = "1.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	g_hCvarEnabled = CreateConVar("l4d_obey_boss_spawn_cvars", "1", "Enable forcing boss spawns to obey boss spawn cvars", _, true, 0.0, true, 1.0);
	g_hCvarSkipStaticMaps = CreateConVar("l4d_obey_boss_spawn_except_static", "1", "Don't override boss spawning rules on Static Tank Spawn maps (c7m1, c13m2)", _, true, 0.0, true, 1.0);
}

public Action L4D_OnGetScriptValueInt(const char[] sKey, int &retVal)
{
	if (g_hCvarEnabled.BoolValue) {
		if (strcmp(sKey, "DisallowThreatType") == 0) {
			// Stop allowing threat types!
			retVal = 0;
			return Plugin_Handled;
		}

		if (strcmp(sKey, "ProhibitBosses") == 0) {
			retVal = 0;
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action L4D_OnGetMissionVSBossSpawning(float &spawn_pos_min, float &spawn_pos_max, float &tank_chance, float &witch_chance)
{
	if (g_hCvarEnabled.BoolValue) {
		if (g_hCvarSkipStaticMaps.BoolValue) {
			char sMapName[32];
			GetCurrentMap(sMapName, sizeof(sMapName));

			if (strcmp(sMapName, "c7m1_docks") == 0 || strcmp(sMapName, "c13m2_southpinestream") == 0) {
				return Plugin_Continue;
			}
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}
