#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

#define GAMEDATA "l4d2_notankautoaim"

ConVar
	hPatchEnable = null;

MemoryPatch
	hPatch_ClawTargetScan = null;

public Plugin myinfo =
{
	name = "L4D2 Tank Claw Fix",
	author = "Jahze(patch data), Visor(SM), A1m`",
	description = "Removes the Tank claw's undocumented auto-aiming ability",
	version = "0.5",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework/"
}

public void OnPluginStart()
{
	InitGameData();

	hPatchEnable = CreateConVar("l4d2_notankautoaim", "1", "Remove the Tank claw's undocumented auto-aiming ability (1 - enable, 0 - disable)", _, true, 0.0, true, 1.0);
	
	CheckPatch(hPatchEnable.BoolValue);
	
	hPatchEnable.AddChangeHook(Cvars_Changed);
}

void InitGameData()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	
	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt", GAMEDATA);
	}
	
	hPatch_ClawTargetScan = MemoryPatch.CreateFromConf(hGamedata, "ClawTargetScan");
	if (hPatch_ClawTargetScan == null || !hPatch_ClawTargetScan.Validate()) {
		SetFailState("Failed to validate MemoryPatch 'ClawTargetScan'.");
	}
	
	delete hGamedata;
}

public void Cvars_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CheckPatch(convar.BoolValue);
}

public void OnPluginEnd()
{
	CheckPatch(false);
}

void CheckPatch(bool IsPatch)
{
	static bool IsPatched = false;
	if (IsPatch) {
		if (IsPatched) {
			PrintToServer("[" ... GAMEDATA ... "] Plugin already enabled");
			return;
		}
		if (!hPatch_ClawTargetScan.Enable()) {
			SetFailState("[" ... GAMEDATA ... "] Failed to enable patch 'ClawTargetScan'");
		}
		PrintToServer("[" ... GAMEDATA ... "] Successfully patched 'ClawTargetScan'."); //GAMEDATA == plugin name
		IsPatched = true;
	} else {
		if (!IsPatched) {
			PrintToServer("[" ... GAMEDATA ... "] Plugin already disabled");
			return;
		}
		hPatch_ClawTargetScan.Disable();
		IsPatched = false;
	}
}