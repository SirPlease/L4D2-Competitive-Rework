#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sourcescramble>

#define GAMEDATA "aggresive_specials_patch"

public Plugin myinfo = 
{
	name = "Aggresive Specials Patch",
	author = "sorallll",
	description = "在非脚本模式下实现cm_AggressiveSpecials = 1的效果",
	version = "1.1.1",
	url = ""
};

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "gamedata/%s.txt", GAMEDATA);
	if(!FileExists(sPath))
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(!hGameData)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	MemoryPatch patch = MemoryPatch.CreateFromConf(hGameData, "CDirector::SpecialsShouldAdvanceOnSurvivors::HasPlayerControlledZombiesCondition");
	if(!patch.Validate())
		SetFailState("Failed to verify patch: CDirector::SpecialsShouldAdvanceOnSurvivors::HasPlayerControlledZombiesCondition");
	else if(patch.Enable())
		PrintToServer("Enabled patch: CDirector::SpecialsShouldAdvanceOnSurvivors::HasPlayerControlledZombiesCondition");

	delete hGameData;
}