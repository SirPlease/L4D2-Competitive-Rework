#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>
#include <left4dhooks>

#define GAMEDATA "boomer_horde_equalizer"
#define KEY_WANDERERSCONDITION "WanderersCondition"

ConVar
	g_hPatchEnable = null,
	g_hzMobSpawnMaxSize = null;

MemoryPatch
	g_hPatch_WanderersCondition = null;

public Plugin myinfo = 
{
	name = "Boomer Horde Equalizer",
	author = "Visor, Jacob, A1m`",
	version = "1.5",
	description = "Fixes boomer hordes being different sizes based on wandering commons.",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();

	g_hPatchEnable = CreateConVar("boomer_horde_equalizer", "1", "Fix boomer hordes being different sizes based on wandering commons. (1 - enable, 0 - disable)", _, true, 0.0, true, 1.0);

	CheckPatch(g_hPatchEnable.BoolValue);
	
	g_hPatchEnable.AddChangeHook(Cvars_Changed);
	
	g_hzMobSpawnMaxSize = FindConVar("z_mob_spawn_max_size");
}

void InitGameData()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);

	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}
	
	g_hPatch_WanderersCondition = MemoryPatch.CreateFromConf(hGamedata, KEY_WANDERERSCONDITION);
	if (g_hPatch_WanderersCondition == null || !g_hPatch_WanderersCondition.Validate()) {
		SetFailState("Failed to validate MemoryPatch \"" ... KEY_WANDERERSCONDITION ... "\"");
	}
	
	delete hGamedata;
}

public Action L4D_OnSpawnITMob(int &iAmount)
{
	iAmount = g_hzMobSpawnMaxSize.IntValue;
	return Plugin_Changed;
}

public void Cvars_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	CheckPatch(hConVar.BoolValue);
}

public void OnPluginEnd()
{
	CheckPatch(false);
}

void CheckPatch(bool bIsPatch)
{
	static bool bIsPatched = false;
	if (bIsPatch) {
		if (bIsPatched) {
			PrintToServer("[" ... GAMEDATA ... "] Plugin already enabled");
			return;
		}
		if (!g_hPatch_WanderersCondition.Enable()) {
			SetFailState("[" ... GAMEDATA ... "] Failed to enable patch '" ... KEY_WANDERERSCONDITION ... "'.");
		}
		PrintToServer("[" ... GAMEDATA ... "] Successfully patched '" ... KEY_WANDERERSCONDITION ... "'."); //GAMEDATA == plugin name
		bIsPatched = true;
	} else {
		if (!bIsPatched) {
			PrintToServer("[" ... GAMEDATA ... "] Plugin already disabled");
			return;
		}
		g_hPatch_WanderersCondition.Disable();
		bIsPatched = false;
	}
}