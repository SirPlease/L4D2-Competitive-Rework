#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <dhooks>

#define PLUGIN_NAME				"Punch Angle"
#define PLUGIN_AUTHOR			"sorallll"
#define PLUGIN_DESCRIPTION		""
#define PLUGIN_VERSION			"1.0.0"
#define PLUGIN_URL				""

#define GAMEDATA				"punch_angle"

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart() {
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof buffer, "gamedata/%s.txt", GAMEDATA);
	if (!FileExists(buffer))
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", buffer);

	GameData hGameData = new GameData(GAMEDATA);
	if (!hGameData)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	DynamicDetour dDetour = DynamicDetour.FromConf(hGameData, "DD::CBasePlayer::SetPunchAngle");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: \"DD::CBasePlayer::SetPunchAngle\"");

	if (!dDetour.Enable(Hook_Pre, DD_CBasePlayer_SetPunchAngle_Pre))
		SetFailState("Failed to detour pre: \"DD::CBasePlayer::SetPunchAngle\"");

	delete hGameData;
}

MRESReturn DD_CBasePlayer_SetPunchAngle_Pre(int pThis, DHookReturn hReturn, DHookParam hParams) {
	/*if (pThis < 1 || pThis > MaxClients || !IsClientInGame(pThis))
		return MRES_Ignored;*/

	if (GetClientTeam(pThis) != 2 || !IsPlayerAlive(pThis))
		return MRES_Ignored;

	hReturn.Value = 0;
	return MRES_Supercede;
}