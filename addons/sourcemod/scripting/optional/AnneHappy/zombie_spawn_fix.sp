#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sourcescramble>

#define GAMEDATA "zombie_spawn_fix"

static const char g_sPatchNames[][] =
{
	"ZombieManager::CanZombieSpawnHere::IsInTransitionCondition",
	"CTerrorPlayer::OnPreThinkGhostState::IsInTransitionCondition",
	"CTerrorPlayer::OnPreThinkGhostState::SpawnDisabledCondition",
	"ZombieManager::AccumulateSpawnAreaCollection::EnforceFinaleNavSpawnRulesCondition"
};

// some code from [L4D2] Air Ability Patch (https://forums.alliedmods.net/showthread.php?p=2660278)
public Plugin myinfo =
{
	name = "[L4D2]Zombie Spawn Fix",
	author = "sorallll & Psyk0tik (Crasher_3637)",
	description = "Fixed Special Inected and Player Zombie spawning failures in some cases",
	version = "1.0.9",
	url = "https://forums.alliedmods.net/showthread.php?t=333351"
};

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "gamedata/%s.txt", GAMEDATA);
	if (!FileExists(sPath))
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if (!hGameData)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	MemoryPatch patch;
	for (int i; i < sizeof g_sPatchNames; i++) {
		patch = MemoryPatch.CreateFromConf(hGameData, g_sPatchNames[i]);
		if (!patch.Validate())
			LogError("Failed to verify patch: \"%s\"", g_sPatchNames[i]);
		else if (patch.Enable())
			PrintToServer("Enabled patch: \"%s\"", g_sPatchNames[i]);
	}

	delete hGameData;
}