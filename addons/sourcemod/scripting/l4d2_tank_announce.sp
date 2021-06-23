#include <sourcemod>
#include <sdktools_sound>
#include <dhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <l4d_tank_control_eq>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.3a"

public Plugin myinfo = 
{
	name = "L4D2 Tank Announcer",
	author = "Visor, Forgetest, xoxo",
	description = "Announce in chat and via a sound when a Tank has spawned",
	version = PLUGIN_VERSION,
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

#define DANG "ui/pickup_secret01.wav"
#define TEAM_NONE 0
#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

enum L4D2SI
{
	ZC_None,
	ZC_Smoker,
	ZC_Boomer,
	ZC_Hunter,
	ZC_Spitter,
	ZC_Jockey,
	ZC_Charger,
	ZC_Witch,
	ZC_Tank
};

Handle g_hDetour;

public void OnPluginStart()
{
	GameData hData = new GameData("left4dhooks.l4d2");
	if (hData == null)
		SetFailState("Missing gamedata \"left4dhooks.l4d2\".");
	
	g_hDetour = DHookCreateFromConf(hData, "SpawnTank");
	if (g_hDetour == null)
		SetFailState("Failed to create detour \"SpawnTank\" from gamedata.");
	
	if (!DHookEnableDetour(g_hDetour, true, OnSpawnTank))
		SetFailState("Failed to enable detour \"SpawnTank\".");
		
	delete hData;
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
	
	if (ret == true)
		RequestFrame(OnNextFrame);	// seems it occurs often that prints with wrong teamcolors
									// make a slight delay here to try fixing this
	return MRES_Ignored;
}

public void OnNextFrame()
{
	char nameBuf[MAX_NAME_LENGTH];
	if (IsTankSelection())
	{
		int tankClient = FindTank();
	
		if (tankClient > 0 && !IsFakeClient(tankClient))
			FormatEx(nameBuf, sizeof(nameBuf), "%N", tankClient);
		else {
			tankClient = GetTankSelection();
			if (tankClient > 0 && IsClientInGame(tankClient))
				FormatEx(nameBuf, sizeof(nameBuf), "%N", tankClient);
			else
				FormatEx(nameBuf, sizeof(nameBuf), "AI");
		}
	} else {
		int tankClient = FindTank();
		
		if (tankClient > 0 && !IsFakeClient(tankClient))
			FormatEx(nameBuf, sizeof(nameBuf), "%N", tankClient);
		else {
			FormatEx(nameBuf, sizeof(nameBuf), "AI");
		}
	}
	
	CPrintToChatAll("{red}[{default}!{red}] {olive}Tank{default}({red}Control: %s{default}) has spawned!", nameBuf);
	EmitSoundToAll(DANG);
}

// ========================
//  Stocks
// ========================

bool IsInfected(int client)
{
	return IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED;
}


L4D2SI GetInfectedClass(int client)
{
	return view_as<L4D2SI>(GetEntProp(client, Prop_Send, "m_zombieClass"));
}


/*
 * @return			TankClient id if can't found return -1.
 */
int FindTank()
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsInfected(i) && GetInfectedClass(i) == ZC_Tank && IsPlayerAlive(i))
			return i;
	}

	return -1;
}


/*
 * @return			true if GetTankSelection exist false otherwise.
 */
bool IsTankSelection()
{
	return (GetFeatureStatus(FeatureType_Native, "GetTankSelection") != FeatureStatus_Unknown);
}