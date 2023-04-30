#include <sourcemod>
#include <sdktools>
#include <l4d2_mission_manager>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "L4D2 Mission Manager",
	author = "Rikka0w0",
	description = "Mission manager for L4D2, provide information about map orders for other plugins",
	version = "v1.0.0",
	url = "http://forums.alliedmods.net/showthread.php?t=308725"
}

public void OnPluginStart(){
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false)) {
		SetFailState("Use this in Left 4 Dead or Left 4 Dead 2 only.");
	}

	InitSDKCalls();
	CacheMissions();
	LMM_InitLists();
	ParseMissions();
	ParseLocalization(LMM_GAMEMODE_COOP);
	ParseLocalization(LMM_GAMEMODE_VERSUS);
	ParseLocalization(LMM_GAMEMODE_SCAVENGE);
	ParseLocalization(LMM_GAMEMODE_SURVIVAL);
	
	FireEvent_OnLMMUpdateList();
		
	RegConsoleCmd("sm_lmm_list", Command_List, "Usage: sm_lmm_list [<coop|versus|scavenge|survival|invalid>]");
}

public void OnPluginEnd() {
	LMM_FreeLists();
	LMM_FreeLocalizedLists();
}

public Action Command_List(int iClient, int args) {
	if (args < 1) {
		for (int i=0; i<4; i++) {
			LMM_GAMEMODE gamemode = view_as<LMM_GAMEMODE>(i);
			DumpMissionInfo(iClient, gamemode);
		}
	} else {
		char gamemodeName[LEN_GAMEMODE_NAME];
		GetCmdArg(1, gamemodeName, sizeof(gamemodeName));
		
		if (StrEqual("invalid", gamemodeName, false)) {
			int missionCount = LMM_GetNumberOfInvalidMissions();
			ReplyToCommand(iClient, "Invalid missions (count:%d):", missionCount);
			for (int iMission=0; iMission<missionCount; iMission++) {
				char missionName[LEN_MISSION_NAME];
				LMM_GetInvalidMissionName(iMission, missionName, sizeof(missionName));
				ReplyToCommand(iClient, ", %s", missionName);
			}
		} else {
			LMM_GAMEMODE gamemode = LMM_StringToGamemode(gamemodeName);
			DumpMissionInfo(iClient, gamemode);
		}
	}
	return Plugin_Handled;
}

void DumpMissionInfo(int client, LMM_GAMEMODE gamemode) {
	char gamemodeName[LEN_GAMEMODE_NAME];
	LMM_GamemodeToString(gamemode, gamemodeName, sizeof(gamemodeName));

	int missionCount = LMM_GetNumberOfMissions(gamemode);
	char missionName[LEN_MISSION_NAME];
	char mapName[LEN_MAP_FILENAME];
	char localizedName[LEN_LOCALIZED_NAME];
	
	ReplyToCommand(client, "Gamemode = %s (%d missions)", gamemodeName, missionCount);

	for (int iMission=0; iMission<missionCount; iMission++) {
		LMM_GetMissionName(gamemode, iMission, missionName, sizeof(missionName));
		int mapCount = LMM_GetNumberOfMaps(gamemode, iMission);
		if (LMM_GetMissionLocalizedName(gamemode, iMission, localizedName, sizeof(localizedName), LANG_SERVER) > 0) {
			ReplyToCommand(client, "%d. %s <%s> %d maps", iMission+1, missionName, localizedName, mapCount);
		} else {
			ReplyToCommand(client, "%d. !! <%s> (%d maps)", iMission+1, missionName, mapCount);
		}
		
		for (int iMap=0; iMap<mapCount; iMap++) {
			LMM_GetMapName(gamemode, iMission, iMap, mapName, sizeof(mapName));
			if (LMM_GetMapLocalizedName(gamemode, iMission, iMap, localizedName, sizeof(localizedName), LANG_SERVER) > 0) {
				ReplyToCommand(client, "> %d. %s <%s>", iMap+1, localizedName, mapName);
			} else {
				ReplyToCommand(client, "> %d. !! <%s>", iMap+1, mapName);
			}
		}
	}
	ReplyToCommand(client, "-------------------");
}

/*=======================================
#########       SDKCalls        #########
=======================================*/
Handle hGameConf = INVALID_HANDLE;
Handle hSDKC_IsMissionFinalMap = INVALID_HANDLE;
void InitSDKCalls() {
  hGameConf = LoadGameConfigFile("l4d2_mission_manager");

  // Preparing SDK Call for IsMissionFinalMap
  StartPrepSDKCall(SDKCall_GameRules);
  PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTerrorGameRules::IsMissionFinalMap");
  PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
  hSDKC_IsMissionFinalMap = EndPrepSDKCall();
  if(hSDKC_IsMissionFinalMap == INVALID_HANDLE)
    PrintToServer("Failed to find CTerrorGameRules::IsMissionFinalMap signature.");
}

public int Native_IsOnFinalMap(Handle plugin, int numParams){
  return hSDKC_IsMissionFinalMap == INVALID_HANDLE ? -1 : SDKCall(hSDKC_IsMissionFinalMap);
}

/* ========== Register Native APIs ========== */
Handle g_hForward_OnLMMUpdateList;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("LMM_GetCurrentGameMode", Native_GetCurrentGameMode);
	CreateNative("LMM_StringToGamemode", Native_StringToGamemode);
	CreateNative("LMM_GamemodeToString", Native_GamemodeToString);

	CreateNative("LMM_GetNumberOfMissions", Native_GetNumberOfMissions);
	CreateNative("LMM_FindMissionIndexByName", Native_FindMissionIndexByName);
	CreateNative("LMM_GetMissionName", Native_GetMissionName);
	CreateNative("LMM_GetMissionLocalizedName", Native_GetMissionLocalizedName);
   
	CreateNative("LMM_GetNumberOfMaps", Native_GetNumberOfMaps);
	CreateNative("LMM_FindMapIndexByName", Native_FindMapIndexByName);
	CreateNative("LMM_GetMapName", Native_GetMapName);
	CreateNative("LMM_GetMapLocalizedName", Native_GetMapLocalizedName);
	CreateNative("LMM_GetMapUniqueID", Native_GetMapUniqueID);
	CreateNative("LMM_DecodeMapUniqueID", Native_DecodeMapUniqueID);	
	CreateNative("LMM_GetMapUniqueIDCount", Native_GetMapUniqueIDCount);
   
	CreateNative("LMM_GetNumberOfInvalidMissions", Native_GetNumberOfInvalidMissions);
	CreateNative("LMM_GetInvalidMissionName", Native_GetInvalidMissionName);

	CreateNative("LMM_IsOnFinalMap", Native_IsOnFinalMap);

	g_hForward_OnLMMUpdateList = CreateGlobalForward("OnLMMUpdateList", ET_Ignore);
	RegPluginLibrary("l4d2_mission_manager");

	return APLRes_Success;
}

void FireEvent_OnLMMUpdateList() {
	Call_StartForward(g_hForward_OnLMMUpdateList);
	Call_Finish();
}

public int Native_GetCurrentGameMode(Handle plugin, int numParams) {
	LMM_GAMEMODE gamemode;
	//Get the gamemode string from the game
	char strGameMode[20];
	FindConVar("mp_gamemode").GetString(strGameMode, sizeof(strGameMode));
	
	//Set the global gamemode int for this plugin
	if(StrEqual(strGameMode, "coop", false))
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "realism", false))
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode,"versus", false))
		gamemode = LMM_GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "teamversus", false))
		gamemode = LMM_GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "scavenge", false))
		gamemode = LMM_GAMEMODE_SCAVENGE;
	else if(StrEqual(strGameMode, "teamscavenge", false))
		gamemode = LMM_GAMEMODE_SCAVENGE;
	else if(StrEqual(strGameMode, "survival", false))
		gamemode = LMM_GAMEMODE_SURVIVAL;
	else if(StrEqual(strGameMode, "mutation1", false))		//Last Man On Earth
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation2", false))		//Headshot!
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation3", false))		//Bleed Out
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation4", false))		//Hard Eight
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation5", false))		//Four Swordsmen
		gamemode = LMM_GAMEMODE_COOP;
	//else if(StrEqual(strGameMode, "mutation6", false))	//Nothing here
	//	gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation7", false))		//Chainsaw Massacre
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation8", false))		//Ironman
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation9", false))		//Last Gnome On Earth
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation10", false))	//Room For One
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation11", false))	//Healthpackalypse!
		gamemode = LMM_GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "mutation12", false))	//Realism Versus
		gamemode = LMM_GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "mutation13", false))	//Follow the Liter
		gamemode = LMM_GAMEMODE_SCAVENGE;
	else if(StrEqual(strGameMode, "mutation14", false))	//Gib Fest
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation15", false))	//Versus Survival
		gamemode = LMM_GAMEMODE_SURVIVAL;
	else if(StrEqual(strGameMode, "mutation16", false))	//Hunting Party
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation17", false))	//Lone Gunman
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation18", false))	//Bleed Out Versus
		gamemode = LMM_GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "mutation19", false))	//Taaannnkk!
		gamemode = LMM_GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "mutation20", false))	//Healing Gnome
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "community1", false))	//Special Delivery
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "community2", false))	//Flu Season
		gamemode = LMM_GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "community3", false))	//Riding My Survivor
		gamemode = LMM_GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "community4", false))	//Nightmare
		gamemode = LMM_GAMEMODE_SURVIVAL;
	else if(StrEqual(strGameMode, "community5", false))	//Death's Door
		gamemode = LMM_GAMEMODE_COOP;
	else
		gamemode = LMM_GAMEMODE_UNKNOWN;
		
	return view_as<int>(gamemode);
}

public int Native_StringToGamemode(Handle plugin, int numParams) {
	if (numParams < 1)
		return -1;
	
	// Get parameters
	int length;
	GetNativeStringLength(1, length);
	char[] gamemodeName = new char[length+1];
	GetNativeString(1, gamemodeName, length+1);
	
	if(StrEqual("coop", gamemodeName, false)) {
		return view_as<int>(LMM_GAMEMODE_COOP);
	} else if (StrEqual("versus", gamemodeName, false)) {
		return view_as<int>(LMM_GAMEMODE_VERSUS);
	} else if(StrEqual("scavenge", gamemodeName, false)) {
		return view_as<int>(LMM_GAMEMODE_SCAVENGE);
	} else if (StrEqual("survival", gamemodeName, false)) {
		return view_as<int>(LMM_GAMEMODE_SURVIVAL);
	}
	
	return view_as<int>(LMM_GAMEMODE_UNKNOWN);
}

public int Native_GamemodeToString(Handle plugin, int numParams) {
	if (numParams < 1)
		return -1;
	
	// Get parameters
	LMM_GAMEMODE gamemode = view_as<LMM_GAMEMODE>(GetNativeCell(1));
	int length = GetNativeCell(3);
	char gamemodeName[LEN_GAMEMODE_NAME];

	switch (gamemode) {
		case LMM_GAMEMODE_COOP: {
			strcopy(gamemodeName, sizeof(gamemodeName), "coop");
		}
		case LMM_GAMEMODE_VERSUS: {
			strcopy(gamemodeName, sizeof(gamemodeName), "versus");
		}
		case LMM_GAMEMODE_SCAVENGE: {
			strcopy(gamemodeName, sizeof(gamemodeName), "scavenge");
		}
		case LMM_GAMEMODE_SURVIVAL: {
			strcopy(gamemodeName, sizeof(gamemodeName), "survival");
		}
		default: {
			strcopy(gamemodeName, sizeof(gamemodeName), "unknown");
		}
	}
	
	if (SetNativeString(2, gamemodeName, length, false) != SP_ERROR_NONE)
		return -1;
		
	return 0;
}

/* ========== Mission Parser Outputs ========== */
ArrayList g_hStr_InvalidMissionNames;

ArrayList g_hStr_MissionNames[COUNT_LMM_GAMEMODE];	// g_hStr_CoopMissionNames.Length = Number of Coop Missions
ArrayList g_hInt_Entries[COUNT_LMM_GAMEMODE];		// g_hInt_CoopEntries.Length = Number of Coop Missions + 1
ArrayList g_hStr_Maps[COUNT_LMM_GAMEMODE];			// The value of nth element in g_hInt_CoopEntries is the offset of nth mission's first map 

void LMM_InitLists() {
	g_hStr_InvalidMissionNames = new ArrayList(LEN_MISSION_NAME);

	for (int i=0; i<COUNT_LMM_GAMEMODE; i++) {
		g_hStr_MissionNames[i] = new ArrayList(LEN_MISSION_NAME);
		g_hInt_Entries[i] = new ArrayList(1);
		g_hInt_Entries[i].Push(0);
		g_hStr_Maps[i] = new ArrayList(LEN_MAP_FILENAME);
	}
}

void LMM_FreeLists() {
	delete g_hStr_InvalidMissionNames;

	for (int i=0; i<COUNT_LMM_GAMEMODE; i++) {
		delete g_hStr_MissionNames[i];
		delete g_hInt_Entries[i];
		delete g_hStr_Maps[i];
	}
}

ArrayList LMM_GetMissionNameList(LMM_GAMEMODE gamemode) {
	return g_hStr_MissionNames[view_as<int>(gamemode)];
}

ArrayList LMM_GetEntryList(LMM_GAMEMODE gamemode) {
	return g_hInt_Entries[view_as<int>(gamemode)];
}

ArrayList LMM_GetMapList(LMM_GAMEMODE gamemode) {
	return g_hStr_Maps[view_as<int>(gamemode)];
}

public int Native_GetNumberOfMissions(Handle plugin, int numParams) {
	if (numParams < 1)
		return -1;
	
	int gamemode = GetNativeCell(1);
	if (gamemode < 0 || gamemode >= COUNT_LMM_GAMEMODE)
		return -1;
	
	return g_hStr_MissionNames[gamemode].Length;	
}

public int Native_FindMissionIndexByName(Handle plugin, int numParams) {
	if (numParams < 2)
		return -1;
	
	// Get parameters
	LMM_GAMEMODE gamemode = view_as<LMM_GAMEMODE>(GetNativeCell(1));
	int length;
	GetNativeStringLength(2, length);
	char[] missionName = new char[length+1];
	GetNativeString(2, missionName, length+1);
	
	ArrayList missionNameList = LMM_GetMissionNameList(gamemode);
	if (missionNameList == null)
		return -1;
	
	return missionNameList.FindString(missionName);
}

public int Native_GetMissionName(Handle plugin, int numParams) {
	if (numParams < 4)
		return -1;
	
	// Get parameters
	LMM_GAMEMODE gamemode = view_as<LMM_GAMEMODE>(GetNativeCell(1));
	int missionIndex = GetNativeCell(2);
	int length = GetNativeCell(4);
	
	ArrayList missionNameList = LMM_GetMissionNameList(gamemode);
	if (missionNameList == null)
		return -1;
	
	
	char missionName[LEN_MISSION_NAME];
	missionNameList.GetString(missionIndex, missionName, sizeof(missionName));
	
	if (SetNativeString(3, missionName, length, false) != SP_ERROR_NONE)
		return -1;
		
	return 0;
}

public int Native_GetMissionLocalizedName(Handle plugin, int numParams) {
	if (numParams < 4)
		return -1;
	
	// Get parameters
	LMM_GAMEMODE gamemode = view_as<LMM_GAMEMODE>(GetNativeCell(1));
	int missionIndex = GetNativeCell(2);
	int length = GetNativeCell(4);
	int client = GetNativeCell(5);
	
	ArrayList missionNameList = LMM_GetMissionNameList(gamemode);
	if (missionNameList == null)
		return -1;
	
	
	char missionName[LEN_MISSION_NAME];
	missionNameList.GetString(missionIndex, missionName, sizeof(missionName));
	
	ArrayList missionLocalizedList = LMM_GetMissionLocalizedList(gamemode);
	if (missionLocalizedList.Get(missionIndex) > 0) {
		char localizedName[LEN_LOCALIZED_NAME];
		Format(localizedName, sizeof(localizedName), "%T", missionName, client);
		if (SetNativeString(3, localizedName, length, false) != SP_ERROR_NONE)
			return -1;
		return 1;
	} else {
		if (SetNativeString(3, missionName, length, false) != SP_ERROR_NONE)
			return -1;
		return 0;
	}
}

public int Native_GetNumberOfMaps(Handle plugin, int numParams) {
	if (numParams < 2)
		return -1;
	
	// Get parameters
	LMM_GAMEMODE gamemode = view_as<LMM_GAMEMODE>(GetNativeCell(1));
	int missionIndex = GetNativeCell(2);
	
	ArrayList entryList = LMM_GetEntryList(gamemode);
	if (entryList == null)
		return -1;
		
	if (missionIndex > entryList.Length - 1)
		return -1;
		
	int startMapIndex = entryList.Get(missionIndex);
	int endMapIndex = entryList.Get(missionIndex + 1);
		
	return endMapIndex - startMapIndex;
}

public int Native_FindMapIndexByName(Handle plugin, int numParams) {
	if (numParams < 3)
		return -1;
	
	// Get parameters
	LMM_GAMEMODE gamemode = view_as<LMM_GAMEMODE>(GetNativeCell(1));
	int length;
	GetNativeStringLength(3, length);
	char[] mapName = new char[length+1];
	GetNativeString(3, mapName, length+1);
	
	// Ignore case, all to lower case
	String_ToLower(mapName, mapName, length+1);
	
	ArrayList mapList = LMM_GetMapList(gamemode);
	if (mapList == null)
		return -1;
	
	ArrayList entryList = LMM_GetEntryList(gamemode);
	
	int mapPos = mapList.FindString(mapName);
	if (mapPos < 0)
		return -1;
	
	int startMapIndex = 0;
	for (int nextMissionIndex=1; nextMissionIndex<mapList.Length+1; nextMissionIndex++){
		int nextStartMapIndex = entryList.Get(nextMissionIndex);
		
		if (startMapIndex <= mapPos && mapPos < nextStartMapIndex) {
			SetNativeCellRef(2, nextMissionIndex-1);
			return mapPos - startMapIndex;
		}
		
		startMapIndex = nextStartMapIndex;
	}
	
	return -1;
}

public int Native_GetMapName(Handle plugin, int numParams) {
	if (numParams < 5)
		return -1;
	
	// Get parameters
	LMM_GAMEMODE gamemode = view_as<LMM_GAMEMODE>(GetNativeCell(1));
	int missionIndex = GetNativeCell(2);
	int mapIndex = GetNativeCell(3);
	int length = GetNativeCell(5);
	
	ArrayList entryList = LMM_GetEntryList(gamemode);
	if (entryList == null)
		return -1;
		
	if (missionIndex > entryList.Length - 1)
		return -1;
		
	int mapIndexOffset = entryList.Get(missionIndex);
	ArrayList mapList = LMM_GetMapList(gamemode);
	
	char mapName[LEN_MAP_FILENAME];
	mapList.GetString(mapIndexOffset+mapIndex, mapName, sizeof(mapName));
	
	if (SetNativeString(4, mapName, length, false) != SP_ERROR_NONE)
		return -1;
		
	return 0;
}

public int Native_GetMapLocalizedName(Handle plugin, int numParams) {
	if (numParams < 4)
		return -1;
	
	// Get parameters
	LMM_GAMEMODE gamemode = view_as<LMM_GAMEMODE>(GetNativeCell(1));
	int missionIndex = GetNativeCell(2);
	int mapIndex = GetNativeCell(3);
	int length = GetNativeCell(5);
	int client = GetNativeCell(6);
	
	ArrayList entryList = LMM_GetEntryList(gamemode);
	if (entryList == null)
		return -1;
	
	
	ArrayList mapList = LMM_GetMapList(gamemode);
	char mapFileName[LEN_MAP_FILENAME];
	int offset = entryList.Get(missionIndex);
	mapList.GetString(offset + mapIndex, mapFileName, sizeof(mapFileName));
	
	ArrayList mapLocalizedList = LMM_GetMapLocalizedList(gamemode);
	if (mapLocalizedList.Get(offset + mapIndex) > 0) {
		char localizedName[LEN_LOCALIZED_NAME];
		Format(localizedName, sizeof(localizedName), "%T", mapFileName, client);
		if (SetNativeString(4, localizedName, length, false) != SP_ERROR_NONE)
			return -1;
		return 1;
	} else {
		if (SetNativeString(4, mapFileName, length, false) != SP_ERROR_NONE)
			return -1;
		return 0;
	}
}

public int Native_GetMapUniqueID(Handle plugin, int numParams) {
	if (numParams < 3)
		return -1;
	
	// Get parameters
	LMM_GAMEMODE gamemode = view_as<LMM_GAMEMODE>(GetNativeCell(1));
	int missionIndex = GetNativeCell(2);
	int mapIndex = GetNativeCell(3);
	
	if (missionIndex < 0)
		return -1;
	
	ArrayList entryList = LMM_GetEntryList(gamemode);
	if (entryList == null)
		return -1;
		
	if (missionIndex > entryList.Length - 2)
		return -1;
		
	int offset = entryList.Get(missionIndex);
	return offset + mapIndex;
}

public int Native_DecodeMapUniqueID(Handle plugin, int numParams) {
	if (numParams < 3)
		return -1;
	
	// Get parameters
	LMM_GAMEMODE gamemode = view_as<LMM_GAMEMODE>(GetNativeCell(1));
	int mapPos = GetNativeCell(3);
		
	ArrayList mapList = LMM_GetMapList(gamemode);
	if (mapList == null)
		return -1;
	
	ArrayList entryList = LMM_GetEntryList(gamemode);
	
	int startMapIndex = 0;
	for (int nextMissionIndex=1; nextMissionIndex<mapList.Length+1; nextMissionIndex++){
		int nextStartMapIndex = entryList.Get(nextMissionIndex);
		
		if (startMapIndex <= mapPos && mapPos < nextStartMapIndex) {
			SetNativeCellRef(2, nextMissionIndex-1);
			return mapPos - startMapIndex;
		}
		
		startMapIndex = nextStartMapIndex;
	}
	
	return -1;
}

public int Native_GetMapUniqueIDCount(Handle plugin, int numParams) {
	if (numParams < 1)
		return -1;
	
	// Get parameters
	LMM_GAMEMODE gamemode = view_as<LMM_GAMEMODE>(GetNativeCell(1));
	
	ArrayList mapList = LMM_GetMapList(gamemode);
	if (mapList == null)
		return -1;
		
	return mapList.Length;
}

public int Native_GetNumberOfInvalidMissions(Handle plugin, int numParams) {
	return g_hStr_InvalidMissionNames.Length;
}

public int Native_GetInvalidMissionName(Handle plugin, int numParams) {
	if (numParams < 2)
		return -1;
	
	int missionIndex = GetNativeCell(1);
	int length = GetNativeCell(3);
	
	char missionName[LEN_MISSION_NAME];
	g_hStr_InvalidMissionNames.GetString(missionIndex, missionName, sizeof(missionName));
	
	if (SetNativeString(2, missionName, length, false) != SP_ERROR_NONE)
		return -1;
		
	return 0;
}

/* ========== Mission Parser ========== */
// MissionParser state variables
int g_MissionParser_UnknownCurLayer;
int g_MissionParser_UnknownPreState;
int g_MissionParser_State;
#define MPS_UNKNOWN -1
#define MPS_ROOT 0
#define MPS_MISSION 1
#define MPS_MODES 2
#define MPS_GAMEMODE 3
#define MPS_MAP 4

LMM_GAMEMODE g_MissionParser_CurGameMode;
char g_MissionParser_MissionName[LEN_MISSION_NAME];
int g_MissionParser_CurMapID;
ArrayList g_hIntMap_Index;
ArrayList g_hStrMap_FileName;

public SMCResult MissionParser_NewSection(SMCParser smc, const char[] name, bool opt_quotes) {
	switch (g_MissionParser_State) {
		case MPS_ROOT: {
			if(strcmp("mission", name, false)==0) {
				g_MissionParser_State = MPS_MISSION;
			} else {
				g_MissionParser_UnknownPreState = g_MissionParser_State;
				g_MissionParser_UnknownCurLayer = 1;
				g_MissionParser_State = MPS_UNKNOWN;
				// PrintToServer("MissionParser_NewSection found an unknown structure: %s",name);
			}
		}
		case MPS_MISSION: {
			if(StrEqual("modes", name, false)) {
				g_MissionParser_State = MPS_MODES;
				// PrintToServer("Entering modes section");
			} else {
				g_MissionParser_UnknownPreState = g_MissionParser_State;
				g_MissionParser_UnknownCurLayer = 1;
				g_MissionParser_State = MPS_UNKNOWN;
				// PrintToServer("MissionParser_NewSection found an unknown structure: %s",name);
			}
		}
		case MPS_MODES: {
			g_MissionParser_CurGameMode = LMM_StringToGamemode(name);
			if (g_MissionParser_CurGameMode == LMM_GAMEMODE_UNKNOWN) {
				g_MissionParser_UnknownPreState = g_MissionParser_State;
				g_MissionParser_UnknownCurLayer = 1;
				g_MissionParser_State = MPS_UNKNOWN;
				// PrintToServer("MissionParser_NewSection found an unknown structure: %s",name);
			} else {
				g_hIntMap_Index.Clear();
				g_hStrMap_FileName.Clear();
				g_MissionParser_State = MPS_GAMEMODE;
			}
			
			// PrintToServer("Enter gamemode: %d (%s)", g_MissionParser_CurGameMode, name);
		}
		case MPS_GAMEMODE: {
			int mapID = StringToInt(name);
			if (mapID > 0) {	// Valid map section
				g_MissionParser_State = MPS_MAP;
				g_MissionParser_CurMapID = mapID;
			} else {
				// Skip invalid sections
				g_MissionParser_UnknownPreState = g_MissionParser_State;
				g_MissionParser_UnknownCurLayer = 1;
				g_MissionParser_State = MPS_UNKNOWN;
				//PrintToServer("MissionParser_NewSection found an unknown structure: %s",name);
			}
		}
		case MPS_MAP: {
			// Do not traverse further
			g_MissionParser_UnknownPreState = g_MissionParser_State;
			g_MissionParser_UnknownCurLayer = 1;
			g_MissionParser_State = MPS_UNKNOWN;
			//PrintToServer("MissionParser_NewSection found an unknown structure: %s",name);
		}
		
		case MPS_UNKNOWN: { // Traverse through unknown structures
			g_MissionParser_UnknownCurLayer++;
		}
	}
	
	return SMCParse_Continue;
}

public SMCResult MissionParser_KeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes) {
	switch (g_MissionParser_State) {
		case MPS_MISSION: {
			if (strcmp("Name", key, false)==0) {
				strcopy(g_MissionParser_MissionName, LEN_MISSION_NAME, value);
			}
		}
		case MPS_MAP: {
			if (StrEqual("Map", key, false)) {
				g_hIntMap_Index.Push(g_MissionParser_CurMapID);
				char mapFileName[LEN_MAP_FILENAME];
				String_ToLower(value, mapFileName, sizeof(mapFileName));
				g_hStrMap_FileName.PushString(mapFileName);
				// PrintToServer("Map %d: %s", g_MissionParser_CurMapID, value);
			}
		}
	}
	
	return SMCParse_Continue;
}

public SMCResult MissionParser_EndSection(SMCParser smc) {
	switch (g_MissionParser_State) {
		case MPS_MISSION: {
			g_MissionParser_State = MPS_ROOT;
		}
		
		case MPS_MODES: {
			// PrintToServer("Leaving modes section");
			g_MissionParser_State = MPS_MISSION;
		}
		
		case MPS_GAMEMODE: {
			// PrintToServer("Leaving gamemode: %d", g_MissionParser_CurGameMode);
			g_MissionParser_State = MPS_MODES;
			
			int numOfValidMaps = 0;
			char mapFile[LEN_MAP_FILENAME];
			// Make sure that all map indexes are consecutive and start from 1
			// And validate maps
			for (int iMap=1; iMap<=g_hIntMap_Index.Length; iMap++) {
				int index = g_hIntMap_Index.FindValue(iMap);
				if (index < 0) {
					char gamemodeName[LEN_GAMEMODE_NAME];
					LMM_GamemodeToString(g_MissionParser_CurGameMode, gamemodeName, sizeof(gamemodeName));
					if (g_hStr_InvalidMissionNames.FindString(g_MissionParser_MissionName) < 0) {
						g_hStr_InvalidMissionNames.PushString(g_MissionParser_MissionName);
					}
					//LogError("Mission %s contains invalid \"%s\" section", g_MissionParser_MissionName, gamemodeName);
					return SMCParse_HaltFail;
				}
				
				g_hStrMap_FileName.GetString(index, mapFile, sizeof(mapFile));
				if (!IsMapValid(mapFile)) {
					char gamemodeName[LEN_GAMEMODE_NAME];
					LMM_GamemodeToString(g_MissionParser_CurGameMode, gamemodeName, sizeof(gamemodeName));
					if (g_hStr_InvalidMissionNames.FindString(g_MissionParser_MissionName) < 0) {
						g_hStr_InvalidMissionNames.PushString(g_MissionParser_MissionName);
					}
					//LogError("Mission %s contains invalid map: \"%s\", gamemode: \"%s\"", g_MissionParser_MissionName, mapFile, gamemodeName);
					return SMCParse_HaltFail;
				}
				numOfValidMaps++;
			}
			
			if (numOfValidMaps < 1) {
				char gamemodeName[LEN_GAMEMODE_NAME];
				LMM_GamemodeToString(g_MissionParser_CurGameMode, gamemodeName, sizeof(gamemodeName));
				//LogError("Mission %s does not contain any valid map in gamemode: \"%s\"", g_MissionParser_MissionName, gamemodeName);
				return SMCParse_Continue;
			}
			
			// Add them to corresponding map lists
			ArrayList mapList = LMM_GetMapList(g_MissionParser_CurGameMode);
			
			for (int iMap=1; iMap<=g_hIntMap_Index.Length; iMap++) {
				int index = g_hIntMap_Index.FindValue(iMap);
				
				g_hStrMap_FileName.GetString(index, mapFile, sizeof(mapFile));
				mapList.PushString(mapFile);
			}
			
			// Add a new entry
			ArrayList entryList = LMM_GetEntryList(g_MissionParser_CurGameMode);
			int lastOffset = entryList.Get(entryList.Length-1);
			entryList.Push(lastOffset+g_hIntMap_Index.Length);
			
			// Add to mission name list
			ArrayList missionName = LMM_GetMissionNameList(g_MissionParser_CurGameMode);
			missionName.PushString(g_MissionParser_MissionName);
		}
		
		case MPS_MAP: {
			g_MissionParser_State = MPS_GAMEMODE;
		}
		
		case MPS_UNKNOWN: { // Traverse through unknown structures
			g_MissionParser_UnknownCurLayer--;
			if (g_MissionParser_UnknownCurLayer == 0) {
				g_MissionParser_State = g_MissionParser_UnknownPreState;
			}
		}
	}
	
	return SMCParse_Continue;
}

void CopyFile(const char[] src, const char[] target) {
	File fileSrc;
	fileSrc = OpenFile(src, "rb", true, NULL_STRING);
	if (fileSrc != null) {
		File fileTarget;
		fileTarget = OpenFile(target, "wb", true, NULL_STRING);
		if (fileTarget != null) {
			int buffer[256]; // 256Bytes each time
			int numOfElementRead;
			while (!fileSrc.EndOfFile()){
				numOfElementRead = fileSrc.Read(buffer, 256, 1);
				fileTarget.Write(buffer, numOfElementRead, 1);
			}
			FlushFile(fileTarget);
			fileTarget.Close();
		}
		fileSrc.Close();
	}
}

void CacheMissions() {
	DirectoryListing dirList;
	dirList = OpenDirectory("missions", true, NULL_STRING);

	if (dirList == null) {
        //LogError("[SM] Plugin is not running! Could not locate mission folder");
        SetFailState("Could not locate mission folder");
	} else {	
		if (!DirExists("missions.cache")) {
			CreateDirectory("missions.cache", 511);
		}
		
		char missionFileName[PLATFORM_MAX_PATH];
		FileType fileType;
		while(dirList.GetNext(missionFileName, PLATFORM_MAX_PATH, fileType)) {
			if (fileType == FileType_File &&
			strcmp("credits.txt", missionFileName, false) != 0
			) {
				char missionSrc[PLATFORM_MAX_PATH];
				char missionCache[PLATFORM_MAX_PATH];
				missionSrc = "missions/";

				Format(missionSrc, PLATFORM_MAX_PATH, "missions/%s", missionFileName);
				Format(missionCache, PLATFORM_MAX_PATH, "missions.cache/%s", missionFileName);
				// PrintToServer("Cached mission file %s", missionFileName);
				
				if (!FileExists(missionCache, true, NULL_STRING)) {
					CopyFile(missionSrc, missionCache);
				}
			}
			
		}
		
		delete dirList;
	}
}

void ParseMissions() {
	DirectoryListing dirList;
	dirList = OpenDirectory("missions.cache", true, NULL_STRING);
	
	if (dirList == null) {
		//LogError("The \"missions.cache\" folder was not found!");
	} else {
		// Create the parser
		SMCParser parser = SMC_CreateParser();
		parser.OnEnterSection = MissionParser_NewSection;
		parser.OnLeaveSection = MissionParser_EndSection;
		parser.OnKeyValue = MissionParser_KeyValue;
		
		g_hIntMap_Index = new ArrayList(1);
		g_hStrMap_FileName = new ArrayList(LEN_MAP_FILENAME);
	
		char missionCache[PLATFORM_MAX_PATH];
		char missionFileName[PLATFORM_MAX_PATH];
		FileType fileType;
		while(dirList.GetNext(missionFileName, PLATFORM_MAX_PATH, fileType)) {
			if (fileType == FileType_File) {
				Format(missionCache, PLATFORM_MAX_PATH, "missions.cache/%s", missionFileName);
				
				// Process the mission file				
				g_MissionParser_State = MPS_ROOT;
				SMCError err = parser.ParseFile(missionCache);
				if (err != SMCError_Okay) {
					g_hStr_InvalidMissionNames.PushString(missionCache);
					//LogError("An error occured while parsing %s, code:%d", missionCache, err);
				}
			}
		}
		
		delete g_hIntMap_Index;
		delete g_hStrMap_FileName;
		delete dirList;	
	}
}

/* ========== Localization File Parser ========== */
ArrayList g_hBool_MissionNameLocalized[COUNT_LMM_GAMEMODE];
ArrayList g_hBool_MapNameLocalized[COUNT_LMM_GAMEMODE];

void LMM_NewLocalizedList(LMM_GAMEMODE gamemode) {
	ArrayList missionLocalizedList = new ArrayList(1, LMM_GetNumberOfMissions(gamemode));
	ArrayList mapLocalizedList = new ArrayList(1, LMM_GetMapList(gamemode).Length);
	
	g_hBool_MissionNameLocalized[view_as<int>(gamemode)] = missionLocalizedList;
	g_hBool_MapNameLocalized[view_as<int>(gamemode)] = mapLocalizedList;
	
	for (int i=0; i<missionLocalizedList.Length; i++) {
		missionLocalizedList.Set(i, 0, 0);
	}
	
	for (int i=0; i<mapLocalizedList.Length; i++) {
		mapLocalizedList.Set(i, 0, 0);
	}
}

void LMM_FreeLocalizedLists() {
	for (int gamemode=0; gamemode<COUNT_LMM_GAMEMODE; gamemode++) {
		delete g_hBool_MissionNameLocalized[gamemode];
		delete g_hBool_MapNameLocalized[gamemode];
	}
}

ArrayList LMM_GetMissionLocalizedList(LMM_GAMEMODE gamemode) {
	return g_hBool_MissionNameLocalized[view_as<int>(gamemode)];
}

ArrayList LMM_GetMapLocalizedList(LMM_GAMEMODE gamemode) {
	return g_hBool_MapNameLocalized[view_as<int>(gamemode)];
}
/*================================================================
#########       Mission Name Localization Parsing        #########
=================================================================*/
bool g_MissionNameLocalization_ParsingMissionLocalization;
LMM_GAMEMODE g_MissionNameLocalization_Gamemode;
int g_MissionNameLocalization_State;
int g_MissionNameLocalization_UnknownCurLayer;
int g_MissionNameLocalization_UnknownPreState;
#define MNLS_UNKNOWN -1
#define MNLS_ROOT 0
#define MNLS_PHRASES 1
public SMCResult LocalizationParser_NewSection(SMCParser smc, const char[] name, bool opt_quotes) {
	switch (g_MissionNameLocalization_State) {
		case MNLS_ROOT: {
			if(strcmp("Phrases", name, false)==0) {
				g_MissionNameLocalization_State = MNLS_PHRASES;
			} else {
				g_MissionNameLocalization_UnknownPreState = g_MissionNameLocalization_State;
				g_MissionNameLocalization_UnknownCurLayer = 1;
				g_MissionNameLocalization_State = MNLS_UNKNOWN;
			}
		}
		case MNLS_PHRASES: {
			if (g_MissionNameLocalization_ParsingMissionLocalization) {
				int missionIndex = LMM_FindMissionIndexByName(g_MissionNameLocalization_Gamemode, name);
				if (missionIndex > -1) {
					
					ArrayList missionLocalizationList = LMM_GetMissionLocalizedList(g_MissionNameLocalization_Gamemode);
					missionLocalizationList.Set(missionIndex, 1, 0);
				}
			} else {
				// We are parsing map name localization
				int missionIndex;
				int mapIndex = LMM_FindMapIndexByName(g_MissionNameLocalization_Gamemode, missionIndex, name);
				if (mapIndex > -1 && missionIndex > -1) {
					ArrayList entryList = LMM_GetEntryList(g_MissionNameLocalization_Gamemode);
					ArrayList mapLocalizationList = LMM_GetMapLocalizedList(g_MissionNameLocalization_Gamemode);
					int offset = entryList.Get(missionIndex);
					mapLocalizationList.Set(offset + mapIndex, 1, 0);
				}
			}
			
			
			// Do not traverse further
			g_MissionNameLocalization_UnknownPreState = g_MissionNameLocalization_State;
			g_MissionNameLocalization_UnknownCurLayer = 1;
			g_MissionNameLocalization_State = MNLS_UNKNOWN;
		}
		
		case MNLS_UNKNOWN: { // Traverse through unknown structures
			g_MissionNameLocalization_UnknownCurLayer++;
		}
	}
	
	return SMCParse_Continue;
}

public SMCResult LocalizationParser_KeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes) {
	return SMCParse_Continue;
}

public SMCResult LocalizationParser_EndSection(SMCParser parser) {
	switch (g_MissionNameLocalization_State) {
		case MNLS_PHRASES: {
			return SMCParse_Halt;
		}
		
		case MNLS_UNKNOWN: { // Traverse through unknown structures
			g_MissionNameLocalization_UnknownCurLayer--;
			if (g_MissionNameLocalization_UnknownCurLayer == 0) {
				g_MissionNameLocalization_State = g_MissionNameLocalization_UnknownPreState;
			}
		}
	}
	
	return SMCParse_Continue;
}

void ParseLocalization(LMM_GAMEMODE gamemode) {
	// Check existance of default(English) localization
	char missonsPhrasesEnglish[PLATFORM_MAX_PATH];
	char mapsPhrasesEnglish[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, missonsPhrasesEnglish, sizeof(missonsPhrasesEnglish), "translations/missions.phrases.txt");
	BuildPath(Path_SM, mapsPhrasesEnglish, sizeof(mapsPhrasesEnglish), "translations/maps.phrases.txt");
	
	if (!FileExists(missonsPhrasesEnglish)) {
		//LogError("Mission name localization file %s does not exist!", missonsPhrasesEnglish);
		// TO-DO:
	}
	
	if (!FileExists(mapsPhrasesEnglish)) {
		//LogError("Map name localization file %s does not exist!", mapsPhrasesEnglish);
		// TO-DO:
	}
	
	LoadTranslations("missions.phrases");
	LoadTranslations("maps.phrases");
	
	// Init array
	LMM_NewLocalizedList(gamemode);
	
	SMCParser parser = SMC_CreateParser();
	parser.OnEnterSection = LocalizationParser_NewSection;
	parser.OnKeyValue = LocalizationParser_KeyValue;
	parser.OnLeaveSection = LocalizationParser_EndSection;
 
	g_MissionNameLocalization_Gamemode = gamemode;
	g_MissionNameLocalization_ParsingMissionLocalization = true;
	g_MissionNameLocalization_State = MNLS_ROOT;
	
	SMCError err = parser.ParseFile(missonsPhrasesEnglish);
	if (err != SMCError_Okay) {
		//LogError("An error occured while parsing missions.phrases.txt(English), code:%d", err);
	}
	
	g_MissionNameLocalization_ParsingMissionLocalization = false;
	g_MissionNameLocalization_State = MNLS_ROOT;
	
	err = parser.ParseFile(mapsPhrasesEnglish);
	if (err != SMCError_Okay) {
		//LogError("An error occured while parsing maps.phrases.txt(English), code:%d", err);
	}
}

/* ========== Utils ========== */
int String_ToLower(const char[] input, char[] output, int size) {
	size--;
	int x = 0;
	while (input[x] != '\0' && x < size) {
		output[x] = CharToLower(input[x]);
		x++;
	}
	output[x] = '\0';
	
	return x+1;
}

/* int FindStringInArrayEx(Handle array, const char[] item, bool caseSensitive = false, int lastFound = 0) {
	int maxLength = strlen(item)+1;
	char[] buffer = new char[maxLength];
	int arrayLength = GetArraySize(array);
	for (int curIndex=lastFound; curIndex<arrayLength; curIndex++) {
		GetArrayString(array, curIndex, buffer, maxLength);
		
		if (StrEqual(buffer, item, caseSensitive)) {
			return curIndex;
		}
	}
	
	return -1;
} */
