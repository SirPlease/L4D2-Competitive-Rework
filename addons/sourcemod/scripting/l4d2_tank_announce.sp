#include <sourcemod>
#include <sdktools_sound>
#include <dhooks>
#include <colors>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.3"

public Plugin myinfo = 
{
	name = "L4D2 Tank Announcer",
	author = "Visor, Forgetest",
	description = "Announce in chat and via a sound when a Tank has spawned",
	version = PLUGIN_VERSION,
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

#define DANG "ui/pickup_secret01.wav"

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
	CPrintToChatAll("{red}[{default}!{red}] {olive}Tank {default}has spawned!");
	EmitSoundToAll(DANG);
}