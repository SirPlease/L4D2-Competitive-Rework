#if defined _lmm_included_
 #endinput
#endif
#define _lmm_included_

#define LEN_MISSION_NAME 64		// e.g. L4D2C1
#define LEN_MAP_FILENAME 64		// e.g. c1m1_hotel
#define LEN_GAMEMODE_NAME 32	// e.g. coop, versus, scavenge, survival
#define LEN_LOCALIZED_NAME 64

#define COUNT_LMM_GAMEMODE 4

enum LMM_GAMEMODE
{
	LMM_GAMEMODE_UNKNOWN = -1,
	LMM_GAMEMODE_COOP = 0,
	LMM_GAMEMODE_VERSUS = 1,
	LMM_GAMEMODE_SCAVENGE = 2,
	LMM_GAMEMODE_SURVIVAL = 3
};

native LMM_GAMEMODE LMM_GetCurrentGameMode();
native LMM_GAMEMODE LMM_StringToGamemode(const char[] name);
native int LMM_GamemodeToString(LMM_GAMEMODE gamemode, char[] name, int length);

native int LMM_GetNumberOfMissions(LMM_GAMEMODE gamemode);
native int LMM_FindMissionIndexByName(LMM_GAMEMODE gamemode, const char[] missionName);
native int LMM_GetMissionName(LMM_GAMEMODE gamemode, int missionIndex, char[] missionName, int length);
/**
	Attempt to localize the mission name, return 1 for success, 0 for no localization and -1 for error.
**/
native int LMM_GetMissionLocalizedName(LMM_GAMEMODE gamemode, int missionIndex, char[] missionName, int length, int client);

native int LMM_GetNumberOfMaps(LMM_GAMEMODE gamemode, int missionIndex);
native int LMM_FindMapIndexByName(LMM_GAMEMODE gamemode, int& missionIndex, const char[] mapName);
native int LMM_GetMapName(LMM_GAMEMODE gamemode, int missionIndex, int mapIndex, char[] mapName, int length);
/** 
	Attempt to localize the map name, return 1 for success, 0 for no localization and -1 for error. 
	mapName will be converted to lower case internally. Entries in maps.phrases.txt can only have lower case English letters and numbers
**/
native int LMM_GetMapLocalizedName(LMM_GAMEMODE gamemode, int missionIndex, int mapIndex, char[] mapName, int length, int client);
/**
	Get the unique ID of the map, which contains the information of both missionIndex and mapIndex
**/
native int LMM_GetMapUniqueID(LMM_GAMEMODE gamemode, int missionIndex, int mapIndex);
/**
	Decode the unique ID of the map, and return both missionIndex and mapIndex
**/
native int LMM_DecodeMapUniqueID(LMM_GAMEMODE gamemode, int& missionIndex, int mapUID);
/**
	Get the number of map unique id, also the number of maps for the given gamemode
**/
native int LMM_GetMapUniqueIDCount(LMM_GAMEMODE gamemode);

native int LMM_GetNumberOfInvalidMissions();
native int LMM_GetInvalidMissionName(int missionIndex, char[] mapName, int length);

/**
  Powered by SDKCall("CTerrorGameRules::IsMissionFinalMap").
  Return 1 if the current map is the final of the campaign, return 0 if not.
  Return -1 if SDKCall failed.
**/
native int LMM_IsOnFinalMap();

/**
	This forward is called during the OnPluginStart() phase.
	Do NOT use any LMM APIs in OnPluginStart, due to the chance that your plugin is loaded prior to LMM.
	LMM APIs become available in OnAllPluginsLoaded().
**/
forward void OnLMMUpdateList();

/**
	This can only work while a client is ingame.
	To call while no clients are not in game requires a signiture @CDirector
	
	Call this before you force change level to close HSCRIPT.
	Any other way of level changing is fine e.g. level transition L4D "callvote missionchange" ect.
**/
stock void ShutDownScriptedMode()
{
	int iClient = 0;
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(!IsClientInGame(i))
			continue;
		
		iClient = i;
		break;
	}
	
	if(iClient < 1)
		return;
	
	int iCmdFlags = GetCommandFlags("scripted_mode_shutdown");
	PrintToServer("[MissionManager] EndingScripted Mode.");
	SetCommandFlags("scripted_mode_shutdown", iCmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(iClient, "scripted_mode_shutdown");
	SetCommandFlags("scripted_mode_shutdown", iCmdFlags);
}