#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools_sound>
#include <dhooks>
#include <colors>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>
#undef REQUIRE_PLUGIN
#include <l4d_tank_control_eq>
//#define REQUIRE_PLUGIN

#define LEFT4FRAMEWORK_GAMEDATA "left4dhooks.l4d2"
#define SECTION_NAME "ZombieManager::SpawnTank"

#define PLUGIN_VERSION "1.3b"
#define DANG "ui/pickup_secret01.wav"

Handle g_hDetour;

public Plugin myinfo = 
{
	name = "L4D2 Tank Announcer",
	author = "Visor, Forgetest, xoxo",
	description = "Announce in chat and via a sound when a Tank has spawned",
	version = PLUGIN_VERSION,
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	Handle hGameData = LoadGameConfigFile(LEFT4FRAMEWORK_GAMEDATA);
	if (hGameData == null) {
		SetFailState("Missing gamedata \"%s\".", LEFT4FRAMEWORK_GAMEDATA);
	}
	
	g_hDetour = DHookCreateFromConf(hGameData, SECTION_NAME);
	if (g_hDetour == null) {
		SetFailState("Failed to create detour '" ... SECTION_NAME ..."' from gamedata.");
	}
	
	if (!DHookEnableDetour(g_hDetour, true, OnSpawnTank)) {
		SetFailState("Failed to enable detour '" ... SECTION_NAME ... "'.");
	}

	delete hGameData;
}

public void OnPluginEnd()
{
	if (!DHookDisableDetour(g_hDetour, true, OnSpawnTank))
		SetFailState("Failed to disable detour \"SpawnTank\".");
}

public void OnMapStart()
{
	PrecacheSound(DANG);
}

public MRESReturn OnSpawnTank(Handle hReturn, Handle hParams)
{
	bool ret = DHookGetReturn(hReturn) != 0; // left4dhooks sets it 0 to disable tank spawns
	
	if (ret == true) {
		RequestFrame(OnNextFrame, 0);	// seems it occurs often that prints with wrong teamcolors
									// make a slight delay here to try fixing this
	}
	return MRES_Ignored;
}

public void OnNextFrame(any data)
{
	char nameBuf[MAX_NAME_LENGTH];
	if (IsTankSelection()) {
		int tankClient = FindAliveTankClient();
	
		if (tankClient > 0 && !IsFakeClient(tankClient)) {
			FormatEx(nameBuf, sizeof(nameBuf), "%N", tankClient);
		} else {
			tankClient = GetTankSelection();
			if (tankClient > 0 && IsClientInGame(tankClient)) {
				FormatEx(nameBuf, sizeof(nameBuf), "%N", tankClient);
			} else {
				FormatEx(nameBuf, sizeof(nameBuf), "AI");
			}
		}
	} else {
		int tankClient = FindAliveTankClient();
		
		if (tankClient > 0 && !IsFakeClient(tankClient)) {
			FormatEx(nameBuf, sizeof(nameBuf), "%N", tankClient);
		} else {
			FormatEx(nameBuf, sizeof(nameBuf), "AI");
		}
	}
	
	CPrintToChatAll("{red}[{default}!{red}] {olive}Tank{default}({red}Control: %s{default}) has spawned!", nameBuf);
	EmitSoundToAll(DANG);
}

/*
 * @return			true if GetTankSelection exist false otherwise.
 */
bool IsTankSelection()
{
	return (GetFeatureStatus(FeatureType_Native, "GetTankSelection") != FeatureStatus_Unknown);
}
