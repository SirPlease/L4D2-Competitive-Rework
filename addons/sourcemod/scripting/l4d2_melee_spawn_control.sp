/*====================================================
1.4
	- Restore the mission's original "meleeweapons" on map end and plugin unload.
	- No longer needs the "KeyValues::FindKey" gamedata.
	- Code cleanup.

1.3
	- Fixed the meleeweapons list if some 3rd party map mission do not declare the "meleeweapons".
	- Save the initial meleeweapons list. After changing the new mission, the "meleeweapons" will be restored and redeclared.

1.2
	- Fixed didn't take effect in time if added Cvars to server.cfg. Thanks to "Target_7" for reporting.

1.1
	- Fixed broken windows signatures.
	- Not forces map to reload any more.
	- Thanks to "Silvers" for reporting and help.

1.0
	- Initial release
======================================================*/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define GAMEDATA "l4d2_melee_spawn_control"
#define MELEE_LIST_LENGTH 255
#define MELEE_MAX_ENTRIES 32
#define MELEE_NAME_LENGTH 40

// Used when a mission doesn't declare "meleeweapons".
#define DEFAULT_MELEE_LIST "fireaxe;frying_pan;machete;baseball_bat;crowbar;cricket_bat;tonfa;katana;electric_guitar;knife;riotshield;golfclub;shovel;pitchfork"

Handle
	g_hSDKKvGetString,
	g_hSDKKvSetString;

ConVar
	g_hCvarGameMode,
	g_hCvarMeleeSpawn,
	g_hCvarAddMelee;

StringMap g_smInitialMelee; // Mission's original melee list

Address g_pMissionInfo; // Mission info whose "meleeweapons" we may have changed, restored to g_sMissionMelee.
char g_sMissionMelee[MELEE_LIST_LENGTH];

public Plugin myinfo =
{
	name = "l4d2 melee spawn control",
	author = "IA/NanaNana",
	description = "Unlock melee weapons",
	version = "1.4",
	url = "http://forums.alliedmods.net/showthread.php?t=327605"
};

public void OnPluginStart()
{
	GameData hGameData = new GameData(GAMEDATA);
	if (hGameData == null) {
		SetFailState("Could not find gamedata \"" ... GAMEDATA ... ".txt\"");
	}

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "KeyValues::GetString");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
	g_hSDKKvGetString = EndPrepSDKCall();
	if (g_hSDKKvGetString == null) {
		SetFailState("KeyValues::GetString sig invalid.");
	}

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "KeyValues::SetString");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hSDKKvSetString = EndPrepSDKCall();
	if (g_hSDKKvSetString == null) {
		SetFailState("KeyValues::SetString sig invalid.");
	}

	DynamicDetour hDetour = DynamicDetour.FromConf(hGameData, "OnGetMissionInfo");
	if (hDetour == null || !hDetour.Enable(Hook_Post, Detour_OnGetMissionInfo)) {
		SetFailState("Failed to detour \"CTerrorGameRules::GetMissionInfo\".");
	}

	delete hGameData;

	g_smInitialMelee = new StringMap();

	g_hCvarGameMode = FindConVar("mp_gamemode");
	g_hCvarMeleeSpawn = CreateConVar("l4d2_melee_spawn", "", "Melee weapon list for unlock, use ',' to separate between names, e.g: pitchfork,shovel. Empty for no change");
	g_hCvarAddMelee = CreateConVar("l4d2_add_melee", "", "Add melee weapons to map basis melee spawn or l4d2_melee_spawn, use ',' to separate between names. Empty for don't add");
}

public void OnMapEnd()
{
	RestoreMissionInfo();
}

public void OnPluginEnd()
{
	RestoreMissionInfo();
}

void RestoreMissionInfo()
{
	if (g_pMissionInfo == Address_Null) {
		return;
	}

	SDKCall(g_hSDKKvSetString, g_pMissionInfo, "meleeweapons", g_sMissionMelee);
	g_pMissionInfo = Address_Null;
}

MRESReturn Detour_OnGetMissionInfo(DHookReturn hReturn)
{
	// The list is read while the map loads, later calls are left alone.
	if (GetGameTime() > 5.0) {
		return MRES_Ignored;
	}

	Address pMissionInfo = hReturn.Value;
	if (pMissionInfo == Address_Null) {
		return MRES_Ignored;
	}

	// Identify the mission by the first map of the current mode, KeyValues resolves the "/" path itself.
	char sMode[64], sPath[96], sMissionKey[64], sInitial[MELEE_LIST_LENGTH];
	g_hCvarGameMode.GetString(sMode, sizeof(sMode));
	FormatEx(sPath, sizeof(sPath), "modes/%s/1/Map", sMode);
	SDKCall(g_hSDKKvGetString, pMissionInfo, sMissionKey, sizeof(sMissionKey), sPath, "N/A");

	if (!g_smInitialMelee.GetString(sMissionKey, sInitial, sizeof(sInitial))) {
		SDKCall(g_hSDKKvGetString, pMissionInfo, sInitial, sizeof(sInitial), "meleeweapons", "");

		if (sInitial[0] == '\0') {
			strcopy(sInitial, sizeof(sInitial), DEFAULT_MELEE_LIST);
			SDKCall(g_hSDKKvSetString, pMissionInfo, "meleeweapons", sInitial);
		}

		if (strcmp(sMissionKey, "N/A") != 0) {
			g_smInitialMelee.SetString(sMissionKey, sInitial, false);
		}
	}

	if (g_pMissionInfo != pMissionInfo) {
		RestoreMissionInfo();
	}

	g_pMissionInfo = pMissionInfo;
	strcopy(g_sMissionMelee, sizeof(g_sMissionMelee), sInitial);

	char sSpawn[MELEE_LIST_LENGTH], sAdd[MELEE_LIST_LENGTH];
	g_hCvarMeleeSpawn.GetString(sSpawn, sizeof(sSpawn));
	g_hCvarAddMelee.GetString(sAdd, sizeof(sAdd));
	ReplaceString(sSpawn, sizeof(sSpawn), " ", "");
	ReplaceString(sAdd, sizeof(sAdd), " ", "");

	// Nothing configured, make sure the mission has its own list.
	if (sSpawn[0] == '\0' && sAdd[0] == '\0') {
		char sCurrent[MELEE_LIST_LENGTH];
		SDKCall(g_hSDKKvGetString, pMissionInfo, sCurrent, sizeof(sCurrent), "meleeweapons", "");

		if (strcmp(sCurrent, sInitial) != 0) {
			SDKCall(g_hSDKKvSetString, pMissionInfo, "meleeweapons", sInitial);
		}

		return MRES_Ignored;
	}

	ReplaceString(sInitial, sizeof(sInitial), ";", ",");
	if (sSpawn[0] == '\0') {
		strcopy(sSpawn, sizeof(sSpawn), sInitial);
	}

	char sBase[MELEE_MAX_ENTRIES][MELEE_NAME_LENGTH], sExtra[MELEE_MAX_ENTRIES][MELEE_NAME_LENGTH];
	int iBaseCount = ExplodeString(sSpawn, ",", sBase, sizeof(sBase), sizeof(sBase[]));
	int iExtraCount = ExplodeString(sAdd, ",", sExtra, sizeof(sExtra), sizeof(sExtra[]));

	// Append the added weapons that aren't in the list yet.
	for (int i = 0; i < iExtraCount; i++) {
		if (sExtra[i][0] == '\0' || IsInList(sExtra[i], sBase, iBaseCount)) {
			continue;
		}

		Format(sSpawn, sizeof(sSpawn), "%s,%s", sSpawn, sExtra[i]);
	}

	// Same as the mission's own list, nothing to change.
	if (strcmp(sSpawn, sInitial) == 0) {
		return MRES_Ignored;
	}

	ReplaceString(sSpawn, sizeof(sSpawn), ",", ";");
	SDKCall(g_hSDKKvSetString, pMissionInfo, "meleeweapons", sSpawn);

	return MRES_Ignored;
}

bool IsInList(const char[] sName, const char[][] sList, int iCount)
{
	for (int i = 0; i < iCount; i++) {
		if (strcmp(sName, sList[i], false) == 0) {
			return true;
		}
	}

	return false;
}
