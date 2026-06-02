#pragma semicolon 1
#pragma newdecls required

#define VERSION	"0.2"

#include <sourcemod>
#include <sourcescramble> // https://github.com/nosoop/SMExt-SourceScramble

public Plugin myinfo =
{
	name = "L4D2 Lag Compensation Null CUserCmd fix",
	author = "fdxx",
	description = "Prevent crash: CLagCompensationManager::StartLagCompensation with NULL CUserCmd!!!",
	version = VERSION,
}

public void OnPluginStart()
{
	Init();
	CreateConVar("l4d2_null_cusercmd_fix_version", VERSION, "Version", FCVAR_NONE | FCVAR_DONTRECORD);
}

void Init()
{
	GameData hGameData = new GameData("l4d2_null_cusercmd_fix");
	if (hGameData == null)
		SetFailState("Failed to load \"l4d2_null_cusercmd_fix.txt\" gamedata.");

	MemoryPatch mPatch = MemoryPatch.CreateFromConf(hGameData, "CLagCompensationManager::StartLagCompensation");
	if (!mPatch.Validate())
		SetFailState("Verify patch failed.");
	if (!mPatch.Enable())
		SetFailState("Enable patch failed.");
}
