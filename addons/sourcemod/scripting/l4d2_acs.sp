//////////////////////////////////////////
// Automatic Campaign Switcher for L4D2 //
// Version 2.0.0                        //
// Compiled Oct 7, 2018                 //
// Programmed by Rikka                  //
//////////////////////////////////////////

/*==================================================================================================

	*** REQUIRES l4d2_mission_manager ***

	This plugin was written in response to the server kicking everyone if the vote is not passed
	at the end of the campaign. It will automatically switch to the appropriate map at all the
	points a vote would be automatically called, by the game, to go to the lobby or play again.
	ACS also includes a voting system in which people can vote for their favorite campaign/map
	on a finale or scavenge map.  The winning campaign/map will become the next map the server
	loads.

	Supported Game Modes in Left 4 Dead 2
		Coop
		Versus
		Scavenge
		Survival

	Untested Game Modes in Left 4 Dead 2
		Realism
		Team Versus
		Team Scavenge
		Mutation 1-20
		Community 1-5

	Change Log
		----- Rikka's upgraded version -----
		v2.3.0 (Oct 24, 2020)	- Add randomizer and other customizations to the next map voting menu

		v2.2.0 (Oct 1, 2020)	- Use a new SDKCall method for checking if the current map is finale or not

		v2.1.1 (Dec 15, 2019)	- Allow server admins to set custom finales in coop mode

		v2.1.0 (Oct 19, 2019)	- Applied Lux's patch, map switching is now more safe and memory leakage is eliminated

		v2.0.0 (Oct 7, 2018)	- Applied Lux's patch, players should see the next map voting menu anyway

		v1.9.9 (Sep 5, 2018)	- Transformed to new SourcePawn syntax
								- Fixed incorrect reading of CVars
								- Removed hardcoded map lists
								- Added "sm_chmap" and "sm_chmap2" commands
								- Colorized chat messages
		
		----- Chris Pringle's original version -----
		v1.2.2 (May 21, 2011)	- Added message for new vote winner when a player disconnects
								- Fixed the sound to play to all the players in the game
								- Added a max amount of coop finale map failures cvar
								- Changed the wait time for voting ad from round_start to the 
								  player_left_start_area event 
								- Added the voting sound when the vote menu pops up
		
		v1.2.1 (May 18, 2011)	- Fixed mutation 15 (Versus Survival)
		
		v1.2.0 (May 16, 2011)	- Changed some of the text to be more clear
								- Added timed notifications for the next map
								- Added a cvar for how to advertise the next map
								- Added a cvar for the next map advertisement interval
								- Added a sound to help notify players of a new vote winner
								- Added a cvar to enable/disable sound notification
								- Added a custom wait time for coop game modes
								
		v1.1.0 (May 12, 2011)	- Added a voting system
								- Added error checks if map is not found when switching
								- Added a cvar for enabling/disabling voting system
								- Added a cvar for how to advertise the voting system
								- Added a cvar for time to wait for voting advertisement
								- Added all current Mutation and Community game modes
								
		v1.0.0 (May 5, 2011)	- Initial Release

===================================================================================================*/

#include <sourcemod>
#include <sdktools>
#include <l4d2_mission_manager>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION	"v2.3.0"

//Define the wait time after round before changing to the next map in each game mode
#define WAIT_TIME_BEFORE_SWITCH_COOP			5.0
#define WAIT_TIME_BEFORE_SWITCH_VERSUS			5.0
#define WAIT_TIME_BEFORE_SWITCH_SCAVENGE		9.0
#define WAIT_TIME_BEFORE_SWITCH_SURVIVAL		5.0

//Define Game Modes
#define GAMEMODE_UNKNOWN	LMM_GAMEMODE_UNKNOWN
#define GAMEMODE_COOP 		LMM_GAMEMODE_COOP
#define GAMEMODE_VERSUS 	LMM_GAMEMODE_VERSUS
#define GAMEMODE_SCAVENGE 	LMM_GAMEMODE_SCAVENGE
#define GAMEMODE_SURVIVAL 	LMM_GAMEMODE_SURVIVAL

#define DISPLAY_MODE_DISABLED		0
#define DISPLAY_MODE_HINT		1
#define DISPLAY_MODE_CHAT		2
#define DISPLAY_MODE_MENU		3

#define SOUND_NEW_VOTE_START	"ui/Beep_SynthTone01.wav"
#define SOUND_NEW_VOTE_WINNER	"ui/alert_clink.wav"


//Global Variables
LMM_GAMEMODE g_iGameMode;			//Integer to store the gamemode
int g_iRoundEndCounter;				//Round end event counter for versus
int g_iCoopFinaleFailureCount;		//Number of times the Survivors have lost the current finale
bool g_bFinaleWon;				//Indicates whether a finale has be beaten or not

int l4d2_AllowedDie;
int hCVar_VotingAdDelayfrequency;

//Voting Variables					
bool g_bClientShownVoteAd[MAXPLAYERS + 1];				//If the client has seen the ad already
bool g_bClientVoted[MAXPLAYERS + 1];					//If the client has voted on a map
// For Coop/Versus: missionIndex of the winning campaign
// For Scavenge/Survival: uniqueID of the winning map
int g_iClientVote[MAXPLAYERS + 1];						//The value of the clients vote
// Only updated by findVoteWinner()
int g_iWinningMapIndices[MAXPLAYERS + 1];				//Winning map/campaigns' indices
int g_iWinningMapIndices_Len;
int g_iWinningMapVotes;									//Winning map/campaign's number of votes, 0 = no one voted yet

//Console Variables (CVars)
ConVar g_hCVar_VotingEnabled;			//Tells if the voting system is on
ConVar g_hCVar_VoteWinnerSoundEnabled;	//Sound plays when vote winner changes
ConVar g_hCVar_VotingAdMode;			//The way to advertise the voting system
ConVar g_hCVar_VotingAdDelayTime;		//Time to wait before showing advertising
ConVar g_hCVar_VotingAdDelayfrequency;		//
ConVar g_hCVar_NextMapMenuOptions;		// Controls what maps will be shown in the next maps menu
ConVar g_hCVar_NextMapMenuExcludes;		// Excludes certain maps from the next maps menu
ConVar g_hCVar_NextMapMenuOrder;		// Controls the order of maps shown in the next maps menu
ConVar g_hCVar_NextMapAdMode;			//The way to advertise the next map 
ConVar g_hCVar_NextMapAdInterval;		//Interval for ACS next map advertisement
ConVar g_hCVar_MaxFinaleFailures;		//Amount of times Survivors can fail before ACS switches in coop
ConVar g_hCVar_ChMapBroadcastInterval;	//The interval for advertising "!chmap"
ConVar g_hCVar_ChMapPolicy;				//The behavior of "!chmap" 
ConVar g_hCVar_PreventEmptyServer;		//If enabled, the server automatically switch to the first available official map when no one is playing a 3-rd map

Handle g_hTimer_DisplayVoteAdToAll;
Handle g_hTimer_ChMapBroadcast;
Handle g_hTimer_CheckEmpty;


/*========================================================
#########       Mission Change SDKCall Method     #######
========================================================*/
bool g_bMapChanger = false;
native void L4D2_ChangeLevel(const char[] sMap);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("L4D2_ChangeLevel");
	return APLRes_Success;
}

public void OnLibraryAdded(const char[] sName)
{
	if(StrEqual(sName, "l4d2_changelevel")) {
		g_bMapChanger = true;
	}
}

public void OnLibraryRemoved(const char[] sName)
{
	if(StrEqual(sName, "l4d2_changelevel")) {
		g_bMapChanger = false;
	}
}

/*=========================================================
#########       Mission Cycle Data Storage        #########
=========================================================*/
#define LEN_CFG_LINE 256
#define LEN_CFG_SEGMENT 128
#define CHAR_CYCLE_SEPARATOR "// 3-rd maps(Do not delete/modify this line!)"

ArrayList g_hInt_MapIndexes[COUNT_LMM_GAMEMODE];
int g_int_CyclingCount[COUNT_LMM_GAMEMODE];
ArrayList g_hStr_MyCoopFinales;

void ACS_InitLists() {
	for (int gamemode=0; gamemode<COUNT_LMM_GAMEMODE; gamemode++) {
		g_hInt_MapIndexes[gamemode] = new ArrayList(1);
		g_int_CyclingCount[gamemode] = 0;
	}

	g_hStr_MyCoopFinales = new ArrayList(LEN_MAP_FILENAME);
}

void ACS_FreeLists() {
	for (int gamemode=0; gamemode<COUNT_LMM_GAMEMODE; gamemode++) {
		delete g_hInt_MapIndexes[gamemode];
	}

	delete g_hStr_MyCoopFinales;
}

ArrayList ACS_GetMissionIndexList(LMM_GAMEMODE gamemode) {
	return g_hInt_MapIndexes[view_as<int>(gamemode)];
}

void ACS_SetCyclingCount(LMM_GAMEMODE gamemode, int count) {
	g_int_CyclingCount[view_as<int>(gamemode)] = count;
}

// Used by the ACS
int ACS_GetCycledMissionCount(LMM_GAMEMODE gamemode) {
	return g_int_CyclingCount[view_as<int>(gamemode)];
}

int ACS_GetMissionCount(LMM_GAMEMODE gamemode){
	return ACS_GetMissionIndexList(gamemode).Length;
}

int ACS_GetMissionIndex(LMM_GAMEMODE gamemode, int cycleIndex) {
	ArrayList missionIndexList = ACS_GetMissionIndexList(gamemode);
	if (missionIndexList == null) {
		return -1;
	}

	return missionIndexList.Get(cycleIndex);
}

int ACS_GetCycleIndex(LMM_GAMEMODE gamemode, int missionIndex) {
	ArrayList missionIndexList = ACS_GetMissionIndexList(gamemode);
	if (missionIndexList == null) {
		return -1;
	}

	return missionIndexList.FindValue(missionIndex);
}

int ACS_GetFirstMapName(LMM_GAMEMODE gamemode, int cycleIndex, char[] mapname, int length){
	return LMM_GetMapName(gamemode, ACS_GetMissionIndex(gamemode, cycleIndex), 0, mapname, length);
}

int ACS_GetLastMapName(LMM_GAMEMODE gamemode, int cycleIndex, char[] mapname, int length){
	int iMission = ACS_GetMissionIndex(gamemode, cycleIndex);
	int mapCount = LMM_GetNumberOfMaps(gamemode, iMission);
	return LMM_GetMapName(gamemode, iMission, mapCount-1, mapname, length);
}

int ACS_GetCycleIndexFromMapName(LMM_GAMEMODE gamemode, const char[] mapname) {
  int missionIndex = -1;
  int mapIndex = LMM_FindMapIndexByName(gamemode, missionIndex, mapname);
  if (mapIndex == -1)
    return -1;

  return ACS_GetCycleIndex(gamemode, missionIndex);
}

bool ACS_GetLocalizedMissionName(LMM_GAMEMODE gamemode, int cycleIndex, int client, char[] localizedName, int length) {
	ArrayList missionIndexList = ACS_GetMissionIndexList(gamemode);
	if (missionIndexList == null)
		return false;
	
	int missionIndex = missionIndexList.Get(cycleIndex);
	return LMM_GetMissionLocalizedName(gamemode, missionIndex, localizedName, length, client) > 0;
}

/*====================================================
#########       Mission Cycle Parsing        #########
====================================================*/
// Get the path of the mission cycle file, max length of char[] path = PLATFORM_MAX_PATH
// Return the actual length of the path, -1 if failed
int GetMissionCycleFilePath(LMM_GAMEMODE gamemode, char[] path) {
	switch (gamemode) {
		case LMM_GAMEMODE_COOP: {
			return BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "configs/missioncycle.coop.txt");
		}
		case LMM_GAMEMODE_VERSUS: {
			return BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "configs/missioncycle.versus.txt");
		}
		case LMM_GAMEMODE_SCAVENGE: {
			return BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "configs/missioncycle.scavenge.txt");
		}
		case LMM_GAMEMODE_SURVIVAL: {
			return BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "configs/missioncycle.survival.txt");
		}
		default: {
			return -1;
		}
	}
}

bool HasMissionCycleFile(LMM_GAMEMODE gamemode) {
	char path[PLATFORM_MAX_PATH];
	if (GetMissionCycleFilePath(gamemode, path) == -1)
		return false;

	return FileExists(path);
}

File OpenMissionCycleFile(LMM_GAMEMODE gamemode, const char[] mode) {
	char path[PLATFORM_MAX_PATH];
	if (GetMissionCycleFilePath(gamemode, path) == -1)
		return null;
	
	return OpenFile(path, mode);
}

void PopulateDefaultMissionCycle(LMM_GAMEMODE gamemode, File missionCycleFile) {
	switch (gamemode) {
		case LMM_GAMEMODE_COOP, LMM_GAMEMODE_VERSUS: {
			missionCycleFile.WriteLine("L4D2C1");
			missionCycleFile.WriteLine("L4D2C2");
			missionCycleFile.WriteLine("L4D2C3");
			missionCycleFile.WriteLine("L4D2C4");
			missionCycleFile.WriteLine("L4D2C5");
			missionCycleFile.WriteLine("L4D2C6");
			missionCycleFile.WriteLine("L4D2C7");
			missionCycleFile.WriteLine("L4D2C8");
			missionCycleFile.WriteLine("L4D2C9");
			missionCycleFile.WriteLine("L4D2C10");
			missionCycleFile.WriteLine("L4D2C11");
			missionCycleFile.WriteLine("L4D2C12");
			missionCycleFile.WriteLine("L4D2C13");
			missionCycleFile.WriteLine("L4D2C14");
		}
		case LMM_GAMEMODE_SCAVENGE: {
			missionCycleFile.WriteLine("L4D2C1");
			missionCycleFile.WriteLine("L4D2C2");
			missionCycleFile.WriteLine("L4D2C3");
			missionCycleFile.WriteLine("L4D2C4");
			missionCycleFile.WriteLine("L4D2C5");
			missionCycleFile.WriteLine("L4D2C6");
			missionCycleFile.WriteLine("L4D2C7");
			missionCycleFile.WriteLine("L4D2C8");
			missionCycleFile.WriteLine("L4D2C10");
			missionCycleFile.WriteLine("L4D2C11");
			missionCycleFile.WriteLine("L4D2C12");
			missionCycleFile.WriteLine("L4D2C14");
		}
		case LMM_GAMEMODE_SURVIVAL: {
			missionCycleFile.WriteLine("L4D2C1");
			missionCycleFile.WriteLine("L4D2C2");
			missionCycleFile.WriteLine("L4D2C3");
			missionCycleFile.WriteLine("L4D2C4");
			missionCycleFile.WriteLine("L4D2C5");
			missionCycleFile.WriteLine("L4D2C6");
			missionCycleFile.WriteLine("L4D2C7");
			missionCycleFile.WriteLine("L4D2C8");
			missionCycleFile.WriteLine("L4D2C14");
		}
	}
}

void LoadMissionList(LMM_GAMEMODE gamemode) {
	ArrayList missionIndexList = ACS_GetMissionIndexList(gamemode);

	char buffer[LEN_CFG_LINE];
	char buffer_split[3][LEN_CFG_SEGMENT];
	File missionCycleFile;
	char missionName[LEN_MISSION_NAME];
	char gamemodeName[LEN_GAMEMODE_NAME];
	LMM_GamemodeToString(gamemode, gamemodeName, sizeof(gamemodeName));
	
	// Create default mission cycle file if not existed yet
	if (!HasMissionCycleFile(gamemode)){
		missionCycleFile = OpenMissionCycleFile(gamemode, "w+");
		missionCycleFile.WriteLine("// Do not delete this line! format: <Mission Name(see txt files in missions.cache folder)>");
		PopulateDefaultMissionCycle(gamemode, missionCycleFile);
		missionCycleFile.WriteLine(CHAR_CYCLE_SEPARATOR);
		delete missionCycleFile;
	}
	
	missionCycleFile = OpenMissionCycleFile(gamemode, "r");
	missionCycleFile.ReadLine(buffer, sizeof(buffer));
	while(!missionCycleFile.EndOfFile() && missionCycleFile.ReadLine(buffer, sizeof(buffer))) {
		ReplaceString(buffer, sizeof(buffer), "\n", "");
		TrimString(buffer);
		if (StrContains(buffer, "//") == 0) {
			if (StrContains(buffer, CHAR_CYCLE_SEPARATOR) == 0) {
				ACS_SetCyclingCount(gamemode, missionIndexList.Length);
			}

			// Ignore comments
		} else {
			int numOfStrings = ExplodeString(buffer, ",", buffer_split, LEN_CFG_LINE, LEN_CFG_SEGMENT);
			TrimString(buffer_split[0]);	// Mission name
			if (numOfStrings > 1) {
				// For future use
			}
			
			int iMission = LMM_FindMissionIndexByName(gamemode, buffer_split[0]);
			if (iMission >= 0) {	// The mission is valid
				missionIndexList.Push(iMission);
			} 
			/*else 
			{
				LogError("Mission \"%s\" (Gamemode: %s) is not in the mission cache or no longer exists!\n", buffer_split[0], gamemodeName);
			}
			*/
		}
	}
	delete missionCycleFile;
	
	// Missions in missionIndexList are in the cyclic order and all valid
	// But l4d2_mission_manager may have some new missions
	// Then append new missions to the end of mission cycle and store the new mission cycle!
	missionCycleFile = OpenMissionCycleFile(gamemode, "a");
	for (int iMission=0; iMission<LMM_GetNumberOfMissions(gamemode); iMission++) {
		if (missionIndexList.FindValue(iMission) < 0) {
			// Found a new mission
			LMM_GetMissionName(gamemode, iMission, missionName, sizeof(missionName));
			LogMessage("Found new %s mission \"%s\" !", gamemodeName, missionName);
			missionCycleFile.WriteLine(missionName);
		}
	}
	
	delete missionCycleFile;
	// Mission list is complete and finalized
}

void DumpMissionInfo(int client, LMM_GAMEMODE gamemode) {
	char gamemodeName[LEN_GAMEMODE_NAME];
	LMM_GamemodeToString(gamemode, gamemodeName, sizeof(gamemodeName));

	ArrayList missionIndexList = ACS_GetMissionIndexList(gamemode);
	int missionCount = ACS_GetMissionCount(gamemode);
	
	char missionName[LEN_MISSION_NAME];
	char firstMap[LEN_MAP_FILENAME];
	char lastMap[LEN_MAP_FILENAME];
	char localizedName[LEN_MISSION_NAME];

	ReplyToCommand(client, "Gamemode = %s (%d missions, %d in cycle)", gamemodeName, missionCount, ACS_GetCycledMissionCount(gamemode));

	for (int cycleIndex=0; cycleIndex<missionCount; cycleIndex++) {
		int iMission = missionIndexList.Get(cycleIndex);
		int mapCount = LMM_GetNumberOfMaps(gamemode, iMission);
		LMM_GetMissionName(gamemode, iMission, missionName, sizeof(missionName));
		ACS_GetFirstMapName(gamemode, cycleIndex, firstMap, sizeof(firstMap));
		ACS_GetLastMapName(gamemode, cycleIndex, lastMap, sizeof(lastMap));
		if (ACS_GetLocalizedMissionName(gamemode, cycleIndex, client, localizedName, sizeof(localizedName))) {
			ReplyToCommand(client, "%d.%s (%s) = %s -> %s (%d maps)", cycleIndex+1 , localizedName, missionName, firstMap, lastMap, mapCount);
		} else {
			ReplyToCommand(client, "%d.%s <Missing localization> = %s -> %s (%d maps)", cycleIndex+1, missionName, firstMap, lastMap, mapCount);
		}
	}
	ReplyToCommand(client, "-------------------");
}

/*====================================================
#########   Custom Coop Finale List Parsing  #########
====================================================*/
bool LoadCustomCoopFinaleList() {
	char path[PLATFORM_MAX_PATH];
	int path_len = BuildPath(Path_SM, path, sizeof(path), "configs/finale.coop.txt");
	if (path_len == -1)
		return false;

	File finaleListFile;

	if (!FileExists(path)){
		finaleListFile = OpenFile(path, "w+");
		if (finaleListFile == null)
			return false;
		finaleListFile.WriteLine("// The following maps will be treated as finale maps in Coop mode. Example: c1m1_hotel. Do not delete this line!");
		delete finaleListFile;
		return true;
	}

	finaleListFile = OpenFile(path, "r");
	if (finaleListFile == null)
		return false;

	// Start parsing the file
	char buffer[128];
	finaleListFile.ReadLine(buffer, sizeof(buffer));
	while(!finaleListFile.EndOfFile() && finaleListFile.ReadLine(buffer, sizeof(buffer))) {
		ReplaceString(buffer, sizeof(buffer), "\n", "");
		TrimString(buffer);

		int missionIndex;
		int iMap = LMM_FindMapIndexByName(LMM_GAMEMODE_COOP, missionIndex, buffer);
		if (iMap > -1) {
			g_hStr_MyCoopFinales.PushString(buffer);
		} 
		/*else 
		{
			LogError("Map \"%s\" (From finale.coop.txt) is invalid!\n", buffer);
		}
		*/
	}
	delete finaleListFile;

	return true;
}

void DumpCustomCoopFinaleList(int client) {
	char buffer[LEN_MAP_FILENAME];
	int len = GetArraySize(g_hStr_MyCoopFinales);

	ReplyToCommand(client, "%d valid custom coop finales from finale.coop.txt:", len);

	for (int i=0; i<len; i++) {
		g_hStr_MyCoopFinales.GetString(i, buffer, sizeof(buffer));
		ReplyToCommand(client, "%d. %s", i+1, buffer);
	}
}

/*===========================================
#########       Menu Systems        #########
===========================================*/
#define MMC_ITEM_LEN_INFO 16
#define MMC_ITEM_LEN_NAME 16
#define MMC_ITEM_IDONTCARE_TEXT "I dont care"
#define MMC_ITEM_ALLMAPS_TEXT "All maps"
#define MMC_ITEM_MISSION_TEXT "Mission"
#define MMC_ITEM_MAP_TEXT "Map"
bool ShowMissionChooser(int iClient, bool isMap, bool isVote, int prevLevelMenuPage=0) {
	if(iClient < 1 || IsClientInGame(iClient) == false || IsFakeClient(iClient) == true)
		return false;

	//Create the menu
	Menu chooser = CreateMenu(MissionChooserMenuHandler, MenuAction_Select | MenuAction_DisplayItem | MenuAction_End);

  // Setup the title and "I dont care" option
	if (isMap) {
		chooser.SetTitle("%T", "Choose a Map", iClient);
		if (isVote) {
			chooser.AddItem(MMC_ITEM_IDONTCARE_TEXT, "N/A");
		}
		chooser.AddItem(MMC_ITEM_ALLMAPS_TEXT, "N/A");
	} else {
		chooser.SetTitle("%T", "Choose a Mission", iClient);
		if (isVote) {
			chooser.AddItem(MMC_ITEM_IDONTCARE_TEXT, "N/A");
		}
	}

	// Determine the map list shown in the menu
	char curMapName[LEN_MAP_FILENAME];
	GetCurrentMap(curMapName,sizeof(curMapName));			//Get the current map from the game
	int curCycleIndex = ACS_GetCycleIndexFromMapName(g_iGameMode, curMapName);  // -1 if not found
	int cycledCount = ACS_GetCycledMissionCount(g_iGameMode);
	int cycleIndices_maxlen = ACS_GetMissionCount(g_iGameMode);
	int[] cycleIndices = new int[cycleIndices_maxlen];
	int cycleIndices_len = 0;
	// Go through each mission, add valid options to int[] cycleIndices
	for(int cycleIndex = 0; cycleIndex < cycleIndices_maxlen; cycleIndex++) {
		if (isVote) {
			// Exclude the current map (g_hCVar_NextMapMenuExcludes)
			if (g_hCVar_NextMapMenuExcludes.IntValue == 1 && curCycleIndex == cycleIndex) continue;
			// Exclude addon maps (g_hCVar_NextMapMenuOptions)
			if (g_hCVar_NextMapMenuOptions.IntValue == 1 && !(cycleIndex < cycledCount)) continue;	
			// Exclude maps with different types (g_hCVar_NextMapMenuOptions)
			if (g_hCVar_NextMapMenuOptions.IntValue == 2 && (cycleIndex < cycledCount) != (curCycleIndex < cycledCount)) continue;
		}
		cycleIndices[cycleIndices_len] = cycleIndex;
		cycleIndices_len++;
	}

	// Randomize (g_hCVar_NextMapMenuOrder)
	if (isVote && g_hCVar_NextMapMenuOrder.IntValue == 1) {
		for (int i = 0; i<cycleIndices_len; i++) {
			int iSwap = i + GetRandomInt(0, cycleIndices_len-i-1);
			int temp = cycleIndices[i];
			cycleIndices[i] = cycleIndices[iSwap];
			cycleIndices[iSwap] = temp;
		}
	}

	char menuName[20];
	for (int i = 0; i<cycleIndices_len; i++) {
		IntToString(cycleIndices[i], menuName, sizeof(menuName));
		chooser.AddItem(MMC_ITEM_MISSION_TEXT, menuName);
	}

	//Add an exit button
	chooser.ExitButton = true;

	//And finally, show the menu to the client
	chooser.DisplayAt(iClient, prevLevelMenuPage, MENU_TIME_FOREVER);

	return true;	
}

public int MissionChooserMenuHandler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_End) {
		delete menu;
		return 0;
	}
	
	char menuInfo[MMC_ITEM_LEN_INFO];
	char menuName[MMC_ITEM_LEN_NAME];
	char localizedName[LEN_LOCALIZED_NAME];
	
	// Change the map to the selected item.
	if(action == MenuAction_Select)	{
		if (item < 0) { // Not a valid map option
			return 0;
		}

		// Find out the current menu mode
		menu.GetItem(0, menuInfo, sizeof(menuInfo));
		if (StrEqual(menuInfo, MMC_ITEM_IDONTCARE_TEXT, false)) {
			// Voting mode
			if (item == 0) {
				// "I dont care" is selected
				VoteMenuHandler(client, true, -1, -1);
				//PrintToServer("\"I dont care\" is selected");
				return 0;
			} else {
				// Other vote mode menu items
				menu.GetItem(1, menuInfo, sizeof(menuInfo));
				if (StrEqual(menuInfo, MMC_ITEM_ALLMAPS_TEXT, false)) {
					// Voting for a map
					if (item == 1) {
						// "All map" is selected, prepare map list for all missions
						ShowMapChooser(client, true, -1, menu.Selection);
					} else {
						// A mission is selected, prepare a map list for the selected mission
						menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
						int cycleIndex = StringToInt(menuName);
						ShowMapChooser(client, true, cycleIndex, menu.Selection);
					}
				} else {
					// Voting for a mission
					menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
					int cycleIndex = StringToInt(menuName);
					int missionIndex = ACS_GetMissionIndex(g_iGameMode, cycleIndex);
					VoteMenuHandler(client, false, missionIndex, -1);
					
					//ACS_GetLocalizedMissionName(g_iGameMode, cycleIndex, client, localizedName, sizeof(localizedName));
					//PrintToServer("ACS: a mission \"%s\" is chosen", localizedName);					
				}
			}
		} else {
			// Chmap mode
			if (StrEqual(menuInfo, MMC_ITEM_ALLMAPS_TEXT, false)) {
				if (item == 0) {
					// "All map" is selected, prepare map list for all missions
					ShowMapChooser(client, false, -1, menu.Selection);
				} else {
					// A mission is selected, prepare a map list for the selected mission
					menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
					int cycleIndex = StringToInt(menuName);
					ShowMapChooser(client, false, cycleIndex, menu.Selection);
				}
				// Browse map list
			} else {
				if (IsVoteInProgress()) {
					ReplyToCommand(client, "\x04[提示]\x05%t", "Vote in Progress");
					return 0;
				}
			
				// A mission is chosen
				menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
				int cycleIndex = StringToInt(menuName);
				ShowChmapVoteToAll(ACS_GetMissionIndex(g_iGameMode, cycleIndex), -1);
			}
		}
		
	} else if (action == MenuAction_DisplayItem) {
		menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
		if (StrEqual(menuInfo, MMC_ITEM_MISSION_TEXT, false)) {
			int cycleIndex = StringToInt(menuName);
			// Localize mission name
			ACS_GetLocalizedMissionName(g_iGameMode, cycleIndex, client, localizedName, sizeof(localizedName));		
		} else {
			// Localize other menu items
			Format(localizedName, sizeof(localizedName), "%T", menuInfo, client);
		}
		RedrawMenuItem(localizedName);
	}
	
	return 0;
}

bool ShowMapChooser(int iClient, bool isVote, int cycleIndex, int prevLevelMenuPage) {
	if(iClient < 1 || IsClientInGame(iClient) == false || IsFakeClient(iClient) == true)
		return false;
	
	char menuInfo[MMC_ITEM_LEN_INFO];
	// Use menu info to store value of isVote and prevLevelMenuPage
	Format(menuInfo, sizeof(menuInfo), "%d,%d", (isVote ? 1 : 0), prevLevelMenuPage);
	
	//Create the menu
	Menu chooser = CreateMenu(MapChooserMenuHandler, MenuAction_Select | MenuAction_DisplayItem | MenuAction_End | MenuAction_Cancel);
	chooser.SetTitle("%T", "Choose a Map", iClient);
	
	char menuName[MMC_ITEM_LEN_NAME];
	if (cycleIndex < 0) {
		// Show all maps at once
		for (cycleIndex = 0; cycleIndex<ACS_GetMissionCount(g_iGameMode); cycleIndex++) {
			int missionIndex = ACS_GetMissionIndex(g_iGameMode, cycleIndex);
			for (int mapIndex=0; mapIndex<LMM_GetNumberOfMaps(g_iGameMode, missionIndex); mapIndex++) {
				Format(menuName, sizeof(menuName), "%d,%d", missionIndex, mapIndex);
				chooser.AddItem(menuInfo, menuName);
			}			
		}
	} else {
		int missionIndex = ACS_GetMissionIndex(g_iGameMode, cycleIndex);
		for (int mapIndex=0; mapIndex<LMM_GetNumberOfMaps(g_iGameMode, missionIndex); mapIndex++) {
			Format(menuName, sizeof(menuName), "%d,%d", missionIndex, mapIndex);
			chooser.AddItem(menuInfo, menuName);
		}
	}
	
	//Add an exitBack button
	chooser.ExitBackButton = true;
	
	//And finally, show the menu to the client
	chooser.Display(iClient, MENU_TIME_FOREVER);
	
	//Play a sound to indicate that the user can vote on a map
	EmitSoundToClient(iClient, SOUND_NEW_VOTE_START);
	
	return true;	
}

public int MapChooserMenuHandler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_End) {
		delete menu;
		return 0;
	}
	
	char menuInfo[MMC_ITEM_LEN_INFO];
	char menuName[MMC_ITEM_LEN_NAME];
	char localizedName[LEN_LOCALIZED_NAME];

	char buffer_split[3][MMC_ITEM_LEN_NAME];
	
	if (action == MenuAction_Cancel) {
		if (item == MenuCancel_ExitBack) {
			// Open main menu
			menu.GetItem(0, menuInfo, sizeof(menuInfo));
			ExplodeString(menuInfo, ",", buffer_split, 3, MMC_ITEM_LEN_NAME);
			bool isVote = StringToInt(buffer_split[0]) == 1;
			int prevLevelMenuPage = StringToInt(buffer_split[1]);
			ShowMissionChooser(client, true, isVote, prevLevelMenuPage);
		}
	} else if (action == MenuAction_DisplayItem) {
		menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
		ExplodeString(menuName, ",", buffer_split, 3, MMC_ITEM_LEN_NAME);
		int missionIndex = StringToInt(buffer_split[0]);
		int mapIndex = StringToInt(buffer_split[1]);
		LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), client);
		RedrawMenuItem(localizedName);
	} else if (action == MenuAction_Select)	{
		if (item < 0) { // Not a valid map option
			return 0;
		}
		
		if (IsVoteInProgress()) {
			ReplyToCommand(client, "\x04[提示]\x05%t", "Vote in Progress");
			return 0;
		}
		
		menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
		ExplodeString(menuName, ",", buffer_split, 3, MMC_ITEM_LEN_NAME);
		int missionIndex = StringToInt(buffer_split[0]);
		int mapIndex = StringToInt(buffer_split[1]);	

		if (StrEqual(menuInfo, "1", false)) {
			// Vote mode
			VoteMenuHandler(client, false, missionIndex, mapIndex);
		} else {
			// Chmap mode
			ShowChmapVoteToAll(missionIndex, mapIndex);
		}
	}
	return 0;
}

void ShowChmapVoteToAll(int missionIndex, int mapIndex) {
	Menu menuVote = CreateMenu(ChampVoteHandler, 
						MenuAction_Display|MenuAction_DisplayItem|MenuAction_VoteCancel|MenuAction_VoteEnd|MenuAction_End);
	
	menuVote.SetTitle("To be translated");
	char menuInfo[MMC_ITEM_LEN_INFO];
	IntToString(missionIndex, menuInfo, sizeof(menuInfo));
	menuVote.AddItem(menuInfo, "Yes");
	IntToString(mapIndex, menuInfo, sizeof(menuInfo));	
	menuVote.AddItem(menuInfo, "No");
	menuVote.ExitButton = false;
	menuVote.DisplayVoteToAll(20);
}

public int ChampVoteHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Display) {
		// Localize title
		char localizedName[LEN_LOCALIZED_NAME];
		char menuInfo[MMC_ITEM_LEN_INFO];
		menu.GetItem(0, menuInfo, sizeof(menuInfo));
		int missionIndex = StringToInt(menuInfo);
		menu.GetItem(1, menuInfo, sizeof(menuInfo));
		int mapIndex = StringToInt(menuInfo);

		if (mapIndex < 0) {
			LMM_GetMissionLocalizedName(g_iGameMode, missionIndex, localizedName, sizeof(localizedName), param1);
		} else {
			LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), param1);
		}
		
	 	char buffer[255];
		Format(buffer, sizeof(buffer), "%T", "Change Map To", param1, localizedName);
		Panel panel = view_as<Panel>(param2);
		panel.SetTitle(buffer);
	} else if (action == MenuAction_DisplayItem) {
		char menuName[MMC_ITEM_LEN_NAME];
		char buffer[MMC_ITEM_LEN_NAME];
		menu.GetItem(param2, "", 0, _, menuName, sizeof(menuName));
		Format(buffer, sizeof(buffer), "%T", menuName, param1);	// param1 = clientIndex
	 	RedrawMenuItem(buffer);
	} else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes) {
		PrintToChatAll("\x04[提示]\x05%t", "No Votes Cast");
	} else if (action == MenuAction_VoteEnd) {
		// param1: The winning item, param2: vote result
		int votes, totalVotes;	// totalVotes != numOfPlayers
		GetMenuVoteInfo(param2, votes, totalVotes);
		
		int playerCount = 0;
		for(int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			if(IsClientInGame(iPlayer) && !IsFakeClient(iPlayer))
				playerCount++;
		
		int abstention = playerCount - totalVotes;
		int yesVotes, noVotes;
		if (param1 == 1) {	// "No" is winning
			yesVotes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
			noVotes = votes;
		} else {	// "Yes" is winning
			yesVotes = votes;
			noVotes = totalVotes - votes;
		}

		float percent, limit;
		if (g_hCVar_ChMapPolicy.IntValue == 1) {
			// Treat abstention as NO
			percent = float(yesVotes) / float(playerCount);
		} else if (g_hCVar_ChMapPolicy.IntValue == 2) {
			// Treat abstention as YES, highly not recommended
			percent = float(yesVotes + abstention) / float(playerCount);
		} else {
			// Disabled
			return 0;
		}
		
		ConVar limitConVar = FindConVar("sm_vote_map");
		if (limitConVar == null) {
			limit = 0.6;
		} else {
			limit = limitConVar.FloatValue;
		}

		// A multi-argument vote is "always successful", but have to check if its a Yes/No vote.
		if (percent < limit) {
			LogAction(-1, -1, "Vote failed.");
			PrintToChatAll("\x04[提示]\x05%t\x04[\x03%d\x04,\x03%d\x04,\x03%d\x04]", "Vote Failed", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), playerCount, yesVotes, noVotes, abstention);
		} else {
			PrintToChatAll("\x04[提示]\x05%t\x0[\x03%d\x04,\x03%d\x04,\x03%d\x04]", "Vote Successful", RoundToNearest(100.0*percent), playerCount, yesVotes, noVotes, abstention);
			
			char menuInfo[MMC_ITEM_LEN_INFO];
			menu.GetItem(0, menuInfo, sizeof(menuInfo));
			int missionIndex = StringToInt(menuInfo);
			menu.GetItem(1, menuInfo, sizeof(menuInfo));
			int mapIndex = StringToInt(menuInfo);

			char colorizedName[LEN_MISSION_NAME];
			char localizedName[LEN_MISSION_NAME];
			char mapName[LEN_MAP_FILENAME];
			if (mapIndex < 0) {
				// Vote for mission, switch to its first map
				LMM_GetMapName(g_iGameMode, missionIndex, 0, mapName, sizeof(mapName));
				for (int client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client)) {
						LMM_GetMissionLocalizedName(g_iGameMode, missionIndex, localizedName, sizeof(localizedName), client);
						Format(colorizedName, sizeof(colorizedName), "\x03%s\x05", localizedName);
						PrintToChat(client,"\x04[提示]%t", "Mission is now winning the vote", colorizedName);
					}
				}			
			} else {
				// Vote for a map, switch to that map
				LMM_GetMapName(g_iGameMode, missionIndex, mapIndex, mapName, sizeof(mapName));
				for (int client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client)) {
						LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), client);
						Format(colorizedName, sizeof(colorizedName), "\x03%s\x05", localizedName);
						PrintToChat(client,"\x04[提示]%t", "Map is now winning the vote", colorizedName);
					}
				}
			}
			
			Format(colorizedName, sizeof(colorizedName), "\x03%s\x05", mapName);
			PrintToChatAll("\x04[提示]%t", "Changing map", colorizedName);
			CreateChangeMapTimer(mapName);
		}
	} else if (action == MenuAction_End) {
		delete menu;
	}
	
	return 0;
}

void CreateChangeMapTimer(const char[] mapName) {
	float delay = 5.0;
	switch (g_iGameMode) {
		case LMM_GAMEMODE_COOP: {delay=WAIT_TIME_BEFORE_SWITCH_COOP;}
		case LMM_GAMEMODE_VERSUS: {delay=WAIT_TIME_BEFORE_SWITCH_VERSUS;}
		case LMM_GAMEMODE_SCAVENGE: {delay=WAIT_TIME_BEFORE_SWITCH_SCAVENGE;}
		case LMM_GAMEMODE_SURVIVAL: {delay=WAIT_TIME_BEFORE_SWITCH_SURVIVAL;}
	}
	
	DataPack dp;
	CreateDataTimer(delay, Timer_ChangeMap, dp);
	dp.WriteString(mapName);
}

public Action Timer_ChangeMap(Handle timer, DataPack dp) {
	char mapName[LEN_MAP_FILENAME];
	
	dp.Reset();
	dp.ReadString(mapName, sizeof(mapName));
	
	if(g_bMapChanger)
	{
		L4D2_ChangeLevel(mapName);
	}
	else
	{
		ShutDownScriptedMode();
		ForceChangeLevel(mapName, "sm_votemap Result");
	}
	return Plugin_Stop;
}

public void OnAllPluginsLoaded() 
{
	if (!LibraryExists("l4d2_mission_manager")) {
		SetFailState("l4d2_mission_manager was not found.");
	}
	
	ACS_InitLists();
	LoadMissionList(LMM_GAMEMODE_COOP);
	LoadMissionList(LMM_GAMEMODE_VERSUS);
	LoadMissionList(LMM_GAMEMODE_SCAVENGE);
	LoadMissionList(LMM_GAMEMODE_SURVIVAL);
	
	DumpMissionInfo(0, LMM_GAMEMODE_COOP);
	DumpMissionInfo(0, LMM_GAMEMODE_VERSUS);
	DumpMissionInfo(0, LMM_GAMEMODE_SCAVENGE);
	DumpMissionInfo(0, LMM_GAMEMODE_SURVIVAL);

	LoadCustomCoopFinaleList();
	DumpCustomCoopFinaleList(0);

	g_bMapChanger = LibraryExists("l4d2_changelevel");
}

public void OnPluginEnd() {
	ACS_FreeLists();
}

/*======================================================================================
#####################             P L U G I N   I N F O             ####################
======================================================================================*/

public Plugin myinfo = {
	name = "Automatic Campaign Switcher (ACS)",
	author = "Rikka0w0, Chris Pringle",
	description = "Automatically switches to the next campaign when the previous campaign is over",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=308708"
}

/*======================================================================================
#################             O N   P L U G I N   S T A R T            #################
======================================================================================*/
public void OnPluginStart() {
	LoadTranslations("acs.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("basevotes.phrases");
	
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false)) {
		SetFailState("Use this in Left 4 Dead or Left 4 Dead 2 only.");
	}
	
	//Create custom console variables
	CreateConVar("l4d2_acs_version", PLUGIN_VERSION, "(ACS)自动换图插件的版本.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCVar_VotingEnabled = CreateConVar("l4d2_acs_voting_system_enabled", "1", "启用玩家投票换图插件? 0=禁用, 1=启用.", FCVAR_NOTIFY);
	g_hCVar_VoteWinnerSoundEnabled = CreateConVar("l4d2_acs_voting_sound_enabled", "1", "打开投票换图菜单时播放声音? 0=禁用, 1=启用.", FCVAR_NOTIFY);
	g_hCVar_VotingAdMode = CreateConVar("l4d2_acs_voting_ad_mode", "2", "救援关幸存者离开开始区域后更换下一张地图的方式,只显示一次(选项1和2是提示玩家输入指令打开投票菜单). 0=禁用, 1=屏幕中下, 2=聊天窗, 3=自动打开投票菜单.", FCVAR_NOTIFY);
	g_hCVar_VotingAdDelayTime = CreateConVar("l4d2_acs_voting_ad_delay_time", "30.0", "救援关幸存者离开开始区域后提示预选下一关地图的投票指令.", FCVAR_NOTIFY);
	g_hCVar_VotingAdDelayfrequency = CreateConVar("l4d2_acs_voting_ad_delay_frequency", "10", "救援关预选下一关地图的投票指令显示多少次.", FCVAR_NOTIFY);
	g_hCVar_NextMapMenuOptions = CreateConVar("l4d2_acs_next_map_menu_options", "2", "救援关投票换图列表里地图的显示类型. 0=官方和附加地图, 1=仅限官方图, 2=当前地图的类型.", FCVAR_NOTIFY);
	g_hCVar_NextMapMenuExcludes = CreateConVar("l4d2_acs_next_map_menu_excludes", "1", "救援关投票换图列表里排除当前地图? 0=不排除, 1=排除当前地图.", FCVAR_NOTIFY);
	g_hCVar_NextMapMenuOrder= CreateConVar("l4d2_acs_next_map_menu_order", "0", "救援关投票菜单中地图的显示顺序. 0=官方图,然后是附加地图, 1=随机.", FCVAR_NOTIFY);
	g_hCVar_NextMapAdMode = CreateConVar("l4d2_acs_next_map_ad_mode", "2", "救援关公告下一张地图信息的显示方式. 0=禁用, 1=屏幕中下, 2=聊天窗.", FCVAR_NOTIFY);
	g_hCVar_NextMapAdInterval = CreateConVar("l4d2_acs_next_map_ad_interval", "60.0", "救援关循环公告下一张地图信息的时间(秒).", FCVAR_NOTIFY);
	g_hCVar_MaxFinaleFailures = CreateConVar("l4d2_acs_max_coop_finale_failures", "1", "战役模式救援关幸存者任务失败多少次后自动换图? 0=禁用.", FCVAR_NOTIFY);
	g_hCVar_ChMapPolicy =  CreateConVar("l4d2_acs_chmap_policy", "2", " 启用 !chmap 和 !chmap2 投票换图指令?\n 0=禁用(同时禁用公告投票换图指令).\n 1=启用(不投票视为不同意). \n 2=启用(不投票视为同意)", FCVAR_NOTIFY);	
	g_hCVar_ChMapBroadcastInterval =  CreateConVar("l4d2_acs_chmap_broadcast_interval", "90.0", "设置循环公告投票指令 \"!chmap\" 的时间(秒). 0=禁用.", FCVAR_NOTIFY);	
	g_hCVar_PreventEmptyServer =  CreateConVar("l4d2_acs_prevent_empty_server", "1", "当服务器是附加战役且没有玩家在服务器时自动切换到第一个可用的官方图. 0=禁用, 1=启用.", FCVAR_NOTIFY);	
	
	//Hook console variable changes
	HookConVarChange(g_hCVar_VotingEnabled, CVarChange_Voting);
	HookConVarChange(g_hCVar_VoteWinnerSoundEnabled, CVarChange_NewVoteWinnerSound);
	HookConVarChange(g_hCVar_VotingAdMode, CVarChange_VotingAdMode);
	HookConVarChange(g_hCVar_VotingAdDelayTime, CVarChange_VotingAdDelayTime);
	HookConVarChange(g_hCVar_NextMapAdMode, CVarChange_NewMapAdMode);
	HookConVarChange(g_hCVar_NextMapAdInterval, CVarChange_NewMapAdInterval);
	HookConVarChange(g_hCVar_MaxFinaleFailures, CVarChange_MaxFinaleFailures);
	HookConVarChange(g_hCVar_ChMapBroadcastInterval, CVarChange_ChMapBroadcastInterval);
	HookConVarChange(g_hCVar_PreventEmptyServer, CVarChange_PreventEmptyServer);
	
	AutoExecConfig(true, "l4d2_acs");
	
	//Hook the game events
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_win", Event_FinaleWin);
	HookEvent("scavenge_match_finished", Event_ScavengeMapFinished);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	//Register custom console commands
	RegConsoleCmd("mapvote", MapVote);
	RegConsoleCmd("mapvotes", DisplayCurrentVotes);
	RegConsoleCmd("sm_chmap", Command_ChangeMapVote);
	RegConsoleCmd("sm_chmap2", Command_ChangeMapVote2);
	//RegConsoleCmd("sm_acs_maps", Command_MapList);
}

public Action Command_ChangeMapVote(int iClient, int args) {
	if (g_hCVar_ChMapPolicy.IntValue < 1) {
		//PrintToChat(iClient, "\x04[提示]\x05投票换图指令\x03!chmap\x05没有启用.");
		PrintToChat(iClient, "\x04[提示]\x05%t", "Change chmap advertise", "\x03!chmap\x05");
		return Plugin_Handled;	// Disabled
	}
	
	ShowMissionChooser(iClient, (g_iGameMode == GAMEMODE_SCAVENGE || g_iGameMode == GAMEMODE_SURVIVAL), false);
	
	//Play a sound to indicate that the user can vote on a map
	EmitSoundToClient(iClient, SOUND_NEW_VOTE_START);
	return Plugin_Handled;
}

public Action Command_ChangeMapVote2(int iClient, int args) {
	if (g_hCVar_ChMapPolicy.IntValue < 1) {
		//PrintToChat(iClient, "\x04[提示]\x05投票换图指令\x03!chmap2\x05没有启用.");
		PrintToChat(iClient, "\x04[提示]\x05%t", "Change chmap advertise", "\x03!chmap2\x05");
		return Plugin_Handled;	// Disabled
	}
	
	ShowMissionChooser(iClient, true, false);

	//Play a sound to indicate that the user can vote on a map
	EmitSoundToClient(iClient, SOUND_NEW_VOTE_START);	
	return Plugin_Handled;
}

public void OnConfigsExecuted() {
	MakeChMapBroadcastTimer();

	//Display advertising for the next campaign or map
	if(g_hCVar_NextMapAdMode.IntValue != DISPLAY_MODE_DISABLED)
		CreateTimer(g_hCVar_NextMapAdInterval.FloatValue, Timer_AdvertiseNextMap, _, TIMER_FLAG_NO_MAPCHANGE);
	
	if(g_hCVar_VotingEnabled.BoolValue)
	{
		delete g_hTimer_DisplayVoteAdToAll;
		g_hTimer_DisplayVoteAdToAll = CreateTimer(g_hCVar_VotingAdDelayTime.FloatValue, Timer_DisplayVoteAdToAll, _, TIMER_REPEAT);
	}
}

void MakeChMapBroadcastTimer() {
	if(g_hCVar_ChMapPolicy.FloatValue != 0 && g_hCVar_ChMapBroadcastInterval.FloatValue > 0)
	{
		delete g_hTimer_ChMapBroadcast;
		g_hTimer_ChMapBroadcast = CreateTimer(g_hCVar_ChMapBroadcastInterval.FloatValue, Timer_WelcomeMessage, INVALID_HANDLE, TIMER_REPEAT);
	}
}

public Action Timer_WelcomeMessage(Handle timer, any param) {
	PrintToChatAll("\x04[提示]\x05%t", "Change map advertise", "\x03!chmap\x05");
	return Plugin_Continue;
}

/*======================================================================================
##########           C V A R   C A L L B A C K   F U N C T I O N S           ###########
======================================================================================*/
public void CVarChange_PreventEmptyServer(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;

	CheckEmptyServer();
}

public void CVarChange_ChMapBroadcastInterval(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;

	MakeChMapBroadcastTimer();
}

//Callback function for the cvar for voting system
public void CVarChange_Voting(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;
	
	//If the value was changed, then set it and display a message to the server and players
	if (StringToInt(strNewValue) == 1) {
		PrintToServer("[提示]已启用投票系统.");
		PrintToChatAll("[提示]已启用投票系统.");
	} else {
		PrintToServer("[提示]已启用投票系统.");
		PrintToChatAll("[提示]已启用投票系统.");
	}
}

//Callback function for enabling or disabling the new vote winner sound
public void CVarChange_NewVoteWinnerSound(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;
	
	//If the value was changed, then set it and display a message to the server and players
	if (StringToInt(strNewValue) == 1) {
		PrintToServer("[提示]已启用打开投票菜单时播放声音.");
		PrintToChatAll("[提示]已启用打开投票菜单时播放声音.");
	} else {
		PrintToServer("[提示]已禁用打开投票菜单时播放声音.");
		PrintToChatAll("[提示]已禁用打开投票菜单时播放声音.");
	}
}

//Callback function for how the voting system is advertised to the players at the beginning of the round
public void CVarChange_VotingAdMode(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;
	
	//If the value was changed, then set it and display a message to the server and players
	switch(StringToInt(strNewValue)) {
		case 0:	{
			PrintToServer("[ACS] ConVar changed: Voting display mode: DISABLED");
			PrintToChatAll("[提示] ConVar changed: Voting display mode: DISABLED");
		}
		case 1:	{
			PrintToServer("[ACS] ConVar changed: Voting display mode: HINT TEXT");
			PrintToChatAll("[提示] ConVar changed: Voting display mode: HINT TEXT");
		}
		case 2:	{
			PrintToServer("[ACS] ConVar changed: Voting display mode: CHAT TEXT");
			PrintToChatAll("[提示] ConVar changed: Voting display mode: CHAT TEXT");
		}
		case 3:	{
			PrintToServer("[ACS] ConVar changed: Voting display mode: OPEN VOTE MENU");
			PrintToChatAll("[提示] ConVar changed: Voting display mode: OPEN VOTE MENU");
		}
	}
}

//Callback function for the cvar for voting display delay time
public void CVarChange_VotingAdDelayTime(Handle hCVar, const char[] strOldValue, const char[] strNewValue)
{
	l4d2_CVarChange();
	
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;
	
	//Get the new value
	float fDelayTime = StringToFloat(strNewValue);
	
	//If the value was changed, then set it and display a message to the server and players
	if (fDelayTime > 0.1)
	{
		PrintToServer("[ACS] ConVar changed: Voting advertisement delay time changed to %f", fDelayTime);
		PrintToChatAll("[提示] ConVar changed: Voting advertisement delay time changed to %f", fDelayTime);
	}
	else
	{
		PrintToServer("[ACS] ConVar changed: Voting advertisement delay time changed to 0.1");
		PrintToChatAll("[提示] ConVar changed: Voting advertisement delay time changed to 0.1");
	}
}

void l4d2_CVarChange()
{
	hCVar_VotingAdDelayfrequency = g_hCVar_VotingAdDelayfrequency.IntValue;
}

//Callback function for how ACS and the next map is advertised to the players during a finale
public void CVarChange_NewMapAdMode(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;
		
	//If the value was changed, then set it and display a message to the server and players
	switch(StringToInt(strNewValue)) {
		case 0:	{
			PrintToServer("[ACS] ConVar changed: Next map advertisement display mode: DISABLED");
			PrintToChatAll("[提示] ConVar changed: Next map advertisement display mode: DISABLED");
		}
		case 1:	{
			PrintToServer("[ACS] ConVar changed: Next map advertisement display mode: HINT TEXT");
			PrintToChatAll("[提示] ConVar changed: Next map advertisement display mode: HINT TEXT");
		}
		case 2:	{
			PrintToServer("[ACS] ConVar changed: Next map advertisement display mode: CHAT TEXT");
			PrintToChatAll("[提示] ConVar changed: Next map advertisement display mode: CHAT TEXT");
		}
	}
}

//Callback function for the interval that controls the timer that advertises ACS and the next map
public void CVarChange_NewMapAdInterval(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;
	
	//Get the new value
	float fDelayTime = StringToFloat(strNewValue);
	
	//If the value was changed, then set it and display a message to the server and players
	if (fDelayTime > 60.0) {
		PrintToServer("[ACS] ConVar changed: Next map advertisement interval changed to %f", fDelayTime);
		PrintToChatAll("[提示] ConVar changed: Next map advertisement interval changed to %f", fDelayTime);
	} else {
		PrintToServer("[ACS] ConVar changed: Next map advertisement interval changed to 60.0");
		PrintToChatAll("[提示] ConVar changed: Next map advertisement interval changed to 60.0");
	}
}

//Callback function for the amount of times the survivors can fail a coop finale map before ACS switches
public void CVarChange_MaxFinaleFailures(Handle hCVar, const char[] strOldValue, const char[] strNewValue) {
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false))
		return;
	
	//Get the new value
	int iMaxFailures = StringToInt(strNewValue);
	
	//If the value was changed, then set it and display a message to the server and players
	if (iMaxFailures > 0) {
		PrintToServer("[ACS] ConVar changed: Max Coop finale failures changed to %f", iMaxFailures);
		PrintToChatAll("[提示] ConVar changed: Max Coop finale failures changed to %f", iMaxFailures);
	} else {
		PrintToServer("[ACS] ConVar changed: Max Coop finale failures changed to 0");
		PrintToChatAll("[提示] ConVar changed: Max Coop finale failures changed to 0");
	}
}
/*======================================================================================
#################                     E V E N T S                      #################
======================================================================================*/

public void OnMapStart() {	
	//Set the game mode
	g_iGameMode = LMM_GetCurrentGameMode();
	
	//Precache sounds
	PrecacheSound(SOUND_NEW_VOTE_START);
	PrecacheSound(SOUND_NEW_VOTE_WINNER);
	
	l4d2_AllowedDie = 0;
	g_iRoundEndCounter = 0;			//Reset the round end counter on every map start
	g_iCoopFinaleFailureCount = 0;	//Reset the amount of Survivor failures
	g_bFinaleWon = false;			//Reset the finale won variable
	ResetAllVotes();				//Reset every player's vote
	l4d2_CVarChange();
	delete g_hTimer_DisplayVoteAdToAll;
}

public void OnMapEnd() {
	KillEmptyCheckTimer();
}

//Event fired when the Round Ends
public Action Event_RoundEnd(Handle hEvent, const char[] strName, bool bDontBroadcast) {
	// PrintToChatAll("\x03[ACS]\x04 Event_RoundEnd");
	//Check to see if on a finale map, if so change to the next campaign after two rounds
	if(g_iGameMode == GAMEMODE_VERSUS && OnFinaleOrScavengeMap() == true) {
		g_iRoundEndCounter++;
		
		if(g_iRoundEndCounter >= 4)	//This event must be fired on the fourth time Round End occurs.
			CheckMapForChange();	//This is because it fires twice during each round end for
									//some strange reason, and versus has two rounds in it.
	}
	//If in Coop and on a finale, check to see if the surviors have lost the max amount of times
	else if(g_iGameMode == GAMEMODE_COOP && OnFinaleOrScavengeMap() == true &&
			g_hCVar_MaxFinaleFailures.IntValue > 0 && g_bFinaleWon == false &&
			++g_iCoopFinaleFailureCount >= g_hCVar_MaxFinaleFailures.IntValue)
	{
		CheckMapForChange();
	}
	
	return Plugin_Continue;
}

//Event fired when a finale is won
public Action Event_FinaleWin(Handle hEvent, const char[] strName, bool bDontBroadcast) {
	// PrintToChatAll("\x03[ACS]\x04 Event_FinaleWin");
	g_bFinaleWon = true;	//This is used so that the finale does not switch twice if this event
							//happens to land on a max failure count as well as this
	
	//Change to the next campaign
	if(g_iGameMode == GAMEMODE_COOP)
		CheckMapForChange();
	
	return Plugin_Continue;
}

//Event fired when a map is finished for scavenge
public Action Event_ScavengeMapFinished(Handle hEvent, const char[] strName, bool bDontBroadcast) {
	//Change to the next Scavenge map
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		ChangeScavengeMap();
	
	return Plugin_Continue;
}

//Event fired when a player disconnects from the server
public Action Event_PlayerDisconnect(Handle hEvent, const char[] strName, bool bDontBroadcast) {
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient < 1)
		return Plugin_Continue;
		
	//Reset the client's votes
	g_bClientVoted[iClient] = false;
	g_iClientVote[iClient] = -1;
	
	//Check to see if there is a new vote winner
	SetTheCurrentVoteWinner();
	
	CheckEmptyServer();
	
	return Plugin_Continue;
}


/*======================================================================================
#################             A C S   C H A N G E   M A P              #################
======================================================================================*/
void CheckEmptyServer() {
	if (IsEmptyServer()) {
		if (g_hTimer_CheckEmpty == null) {
			g_hTimer_CheckEmpty = CreateTimer(5.0, Timer_CheckEmptyServer, INVALID_HANDLE, TIMER_REPEAT);
		}
	}
}

bool IsEmptyServer() {
	if (!g_hCVar_PreventEmptyServer.BoolValue)
		return false;	// Feature disabled
		
	for (int client = 1; client <= MaxClients; client++) {
		if (!IsClientInGame(client))
			continue;	// Not a valid client id

		if (!IsFakeClient(client))
			return false;	// Someone is in the server
	}

	char mapName[LEN_MAP_FILENAME];
	GetCurrentMap(mapName,sizeof(mapName));					//Get the current map from the game
	
	int missionIndex;
	LMM_FindMapIndexByName(g_iGameMode, missionIndex, mapName);
	
	for (int cycleIndex=0; cycleIndex<ACS_GetCycledMissionCount(g_iGameMode); cycleIndex++) {
		if (ACS_GetMissionIndex(g_iGameMode, cycleIndex) == missionIndex)
			return false;	// Current map/mission is in cycle
	}
	
	// Current map/mission is not in cycle
	return true;
}

void KillEmptyCheckTimer() {
	if (g_hTimer_CheckEmpty != null) {
		KillTimer(g_hTimer_CheckEmpty);
		g_hTimer_CheckEmpty = null;
	}
}

public Action Timer_CheckEmptyServer(Handle timer, any param) {
	static int counter = 0;
	if (IsEmptyServer()){
		counter++;
		if (counter > 10) {	// Idle for 50s
			counter = 0;
			KillEmptyCheckTimer();
			
			char mapName[LEN_MAP_FILENAME];
			ACS_GetFirstMapName(g_iGameMode, 0, mapName, sizeof(mapName));
			LogMessage("Empty server is running 3-rd map, switching to the first official map!");
			
			if(g_bMapChanger)
			{
				L4D2_ChangeLevel(mapName);
			}
			else
			{
				//ShutDownScriptedMode(); i guess we would need the signiture here :P
				ForceChangeLevel(mapName, "Empty server with 3-rd map");			
			}
		}
	} else {
		// Some one joined
		KillEmptyCheckTimer();
	}
	return Plugin_Continue;
}

//Check to see if the current map is a finale, and if so, switch to the next campaign
void CheckMapForChange() {
	char strCurrentMap[LEN_MAP_FILENAME];
	GetCurrentMap(strCurrentMap,sizeof(strCurrentMap));					//Get the current map from the game

	char colorizedname[LEN_LOCALIZED_NAME];
	char mapName[LEN_MAP_FILENAME];
	char localizedName[LEN_LOCALIZED_NAME];
	for(int cycleIndex = 0; cycleIndex < ACS_GetMissionCount(g_iGameMode); cycleIndex++)	{
		ACS_GetLastMapName(g_iGameMode, cycleIndex, mapName, sizeof(mapName));
		if(StrEqual(strCurrentMap, mapName, false)) {
			for (int client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client)) {
					ACS_GetLocalizedMissionName(g_iGameMode, cycleIndex, client, localizedName, sizeof(localizedName));
					Format(colorizedname, sizeof(colorizedname), "\x03%s\x05", localizedName);
					PrintToChat(client, "\x04[提示]%t", "Campaign finished", colorizedname);
				}
			}
			
			//Check to see if someone voted for a campaign, if so, then change to the winning campaign
			if(g_hCVar_VotingEnabled.BoolValue && hasVoted()) {
				int winningMapIndex = GetRandomInt(0, g_iWinningMapIndices_Len-1);
				winningMapIndex = g_iWinningMapIndices[winningMapIndex];
				LMM_GetMapName(g_iGameMode, winningMapIndex, 0, mapName, sizeof(mapName));
				if(IsMapValid(mapName)) {
					for (int client = 1; client <= MaxClients; client++) {
						if (IsClientInGame(client)) {
							LMM_GetMissionLocalizedName(g_iGameMode, winningMapIndex, localizedName, sizeof(localizedName), client);
							Format(colorizedname, sizeof(colorizedname), "\x03%s\x05", localizedName);
							PrintToChat(client, "\x04[提示]%t", "Switching to the vote winner", colorizedname);
						}
					}
					
					CreateChangeMapTimer(mapName);
					
					return;
				}
				//else
					//LogError("Error: %s is an invalid map name, attempting normal map rotation.", mapName);
			}
			
			//If no map was chosen in the vote, then go with the automatic map rotation
			
			if(cycleIndex >= ACS_GetCycledMissionCount(g_iGameMode) - 1)	//Check to see if it reaches/exceed the end of official map list
				cycleIndex = 0;					//If so, start the array over by setting to -1 + 1 = 0
			else
				cycleIndex++;
				
			ACS_GetFirstMapName(g_iGameMode, cycleIndex, mapName, sizeof(mapName));
			if(IsMapValid(mapName)) {
				for (int client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client)) {
						ACS_GetLocalizedMissionName(g_iGameMode, cycleIndex, client, localizedName, sizeof(localizedName));
						Format(colorizedname, sizeof(colorizedname), "\x03%s\x05", localizedName);
						PrintToChat(client, "\x04[提示]%t", "Switching campaign to", colorizedname);
					}
				}
				
				CreateChangeMapTimer(mapName);
			}
			//else
				//LogError("Error: %s is an invalid map name, unable to switch map.", mapName);
			
			return;
		}
	}
}

//Change to the next scavenge map
void ChangeScavengeMap() {
	char mapName[LEN_MAP_FILENAME];
	char colorizedname[LEN_LOCALIZED_NAME];
	char localizedName[LEN_LOCALIZED_NAME];
	int cycleCount = ACS_GetMissionCount(g_iGameMode);

	//Check to see if someone voted for a map, if so, then change to the winning map
	if(g_hCVar_VotingEnabled.BoolValue && hasVoted()) {
		int winningMapIndex = GetRandomInt(0, g_iWinningMapIndices_Len-1);
		winningMapIndex = g_iWinningMapIndices[winningMapIndex];
		int missionIndex;
		int mapIndex = LMM_DecodeMapUniqueID(g_iGameMode, missionIndex, winningMapIndex);
		LMM_GetMapName(g_iGameMode, missionIndex, mapIndex, mapName, sizeof(mapName));
		if(IsMapValid(mapName)) {
			for (int client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client)) {
					LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), client);
					Format(colorizedname, sizeof(colorizedname), "\x03%s\x05", localizedName);
					PrintToChat(client, "\x04[提示]%t", "Switching to the vote winner", colorizedname);
				}
			}
			
			CreateChangeMapTimer(mapName);
			
			return;
		}
		//else
			//LogError("Error: %s is an invalid map name, attempting normal map rotation.", mapName);
	}
	
	//If no map was chosen in the vote, then go with the automatic map rotation
	
	char strCurrentMap[LEN_MAP_FILENAME];
	GetCurrentMap(strCurrentMap, sizeof(strCurrentMap));	//Get the current map from the game
	
	//Go through all maps and to find which map index it is on, and then switch to the next map
	for(int cycleIndex = 0; cycleIndex < cycleCount; cycleIndex++)	{
		int missionIndex = ACS_GetMissionIndex(g_iGameMode, cycleIndex);
		int mapCount = LMM_GetNumberOfMaps(g_iGameMode, missionIndex);
		for (int mapIndex = 0; mapIndex<mapCount; mapIndex++) {
			LMM_GetMapName(g_iGameMode, missionIndex, mapIndex, mapName, sizeof(mapName));

			if(StrEqual(strCurrentMap, mapName, false)) {
				// Check to see if its the end of the array
				// If so, start the array over
				if (mapIndex == mapCount - 1) {	// Last map of a mission
					mapIndex = 0;	// Switch to the first map of the next mission
							
					if (cycleIndex == ACS_GetCycledMissionCount(g_iGameMode) - 1) {	// End of mission cycle
						cycleIndex = 0;
					} else {
						cycleIndex++;
					}
					// Find out the new cycleIndex
					missionIndex = ACS_GetMissionIndex(g_iGameMode, cycleIndex);
				} else {
					mapIndex++;		// Move to next map
				}
				
				LMM_GetMapName(g_iGameMode, missionIndex, mapIndex, mapName, sizeof(mapName));
				//Make sure the map is valid before changing and displaying the message
				if(IsMapValid(mapName)) {
					for (int client = 1; client <= MaxClients; client++) {
						if (IsClientInGame(client)) {
							LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), client);
							Format(colorizedname, sizeof(colorizedname), "\x03%s\x05", localizedName);
							PrintToChat(client, "\x04[提示]%t", "Switching map to", colorizedname);
						}
					}	

					CreateChangeMapTimer(mapName);
				}
				//else
					//LogError("Error: %s is an invalid map name, unable to switch map.", mapName);
				
				return;
			}
		}
	}
}

/*======================================================================================
#################            A C S   A D V E R T I S I N G             #################
======================================================================================*/

public Action Timer_AdvertiseNextMap(Handle timer, any param) {
	//If next map advertising is enabled, display the text and start the timer again
	if(g_hCVar_NextMapAdMode.IntValue != DISPLAY_MODE_DISABLED)	{
		if (OnFinaleOrScavengeMap())
			DisplayNextMapToAll();
		CreateTimer(g_hCVar_NextMapAdInterval.FloatValue, Timer_AdvertiseNextMap, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

// Assume g_iWinningMapIndices_Len >= 1
// maxlen = (LEN_MISSION_NAME + 4) * g_iWinningMapIndices_Len
void GetWinnerListForDisplay_Scavenge(int client, char[] strbuf, int maxlen) {
	char localizedName[LEN_MISSION_NAME];
	char colorizedName[LEN_MISSION_NAME + 4];

	int missionIndex;
	int mapIndex = LMM_DecodeMapUniqueID(g_iGameMode, missionIndex, g_iWinningMapIndices[0]);

	LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), client);
	Format(strbuf, maxlen, "\x04%s\x05", localizedName);

	for (int i = 1; i<g_iWinningMapIndices_Len; i++) {
		mapIndex = LMM_DecodeMapUniqueID(g_iGameMode, missionIndex, g_iWinningMapIndices[0]);
		LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), client);
		Format(colorizedName, sizeof(colorizedName), ", \x04%s\x05", localizedName);
		StrCat(strbuf, maxlen, colorizedName);
	}
}

void GetWinnerListForDisplay(int client, char[] strbuf, int maxlen) {
	char localizedName[LEN_MISSION_NAME];
	char colorizedName[LEN_MISSION_NAME + 4];

	LMM_GetMissionLocalizedName(g_iGameMode, g_iWinningMapIndices[0], localizedName, sizeof(localizedName), client);
	Format(strbuf, maxlen, "\x04%s\x05", localizedName);

	for (int i = 1; i<g_iWinningMapIndices_Len; i++) {
		LMM_GetMissionLocalizedName(g_iGameMode, g_iWinningMapIndices[i], localizedName, sizeof(localizedName), client);
		Format(colorizedName, sizeof(colorizedName), ", \x04%s\x05", localizedName);
		StrCat(strbuf, maxlen, colorizedName);
	}
}

bool NextMapFromRotation_Scavenge(int& missionIndex_ret, int& mapIndex_ret) {
	char mapName[LEN_MAP_FILENAME];
	char strCurrentMap[LEN_MAP_FILENAME];
	GetCurrentMap(strCurrentMap, sizeof(strCurrentMap));	//Get the filename of the current map from the game
	int cycleCount = ACS_GetMissionCount(g_iGameMode);

	//Go through all maps and to find which map index it is on, and then switch to the next map
	for (int cycleIndex = 0; cycleIndex < cycleCount; cycleIndex++) {
		int missionIndex = ACS_GetMissionIndex(g_iGameMode, cycleIndex);
		int mapCount = LMM_GetNumberOfMaps(g_iGameMode, missionIndex);
		for (int mapIndex = 0; mapIndex<mapCount; mapIndex++) {
			LMM_GetMapName(g_iGameMode, missionIndex, mapIndex, mapName, sizeof(mapName));

			if (StrEqual(strCurrentMap, mapName, false)) {
				if (mapIndex >= mapCount - 1) {	// Last map of a mission
					mapIndex = 0;	// Switch to the first map of the next mission

					if (cycleIndex >= ACS_GetCycledMissionCount(g_iGameMode) - 1) {	// End of mission cycle
						cycleIndex = 0;
					}
					else {
						cycleIndex++;
					}
					// Find out the new cycleIndex
					missionIndex = ACS_GetMissionIndex(g_iGameMode, cycleIndex);
				}
				else {
					mapIndex++;		// Move to next map
				}

				missionIndex_ret = missionIndex;
				mapIndex_ret = mapIndex;
				return true;
			}
		}
	}

	//LogError("ACS was unable to locate the current map (%s) in the map cycle!", strCurrentMap);
	return false;
}

bool NextMapFromRotation(int& cycleIndex_ret) {
	char mapName[LEN_MAP_FILENAME];
	char strCurrentMap[LEN_MAP_FILENAME];
	GetCurrentMap(strCurrentMap, sizeof(strCurrentMap));	//Get the filename of the current map from the game
	int cycleCount = ACS_GetMissionCount(g_iGameMode);

	// Not voted yet, display the next map in rotation
	//Go through all maps and to find which map index it is on, and then switch to the next map
	for (int cycleIndex = 0; cycleIndex < cycleCount; cycleIndex++) {
		ACS_GetLastMapName(g_iGameMode, cycleIndex, mapName, sizeof(mapName));
		if (StrEqual(strCurrentMap, mapName, false)) {
			if (cycleIndex >= ACS_GetCycledMissionCount(g_iGameMode) - 1) {	//Check to see if its the end of the array
				cycleIndex_ret = 0;					//If so, start the array over by setting to -1 + 1 = 0
			} else {
				cycleIndex_ret = cycleIndex + 1;
			}
			return true;
		}
	}

	// If in Coop mode, also check the custom finale list
	if (g_iGameMode == LMM_GAMEMODE_COOP) {
		for (int i=0; i<GetArraySize(g_hStr_MyCoopFinales); i++) {
			g_hStr_MyCoopFinales.GetString(i, mapName, sizeof(mapName));
			if(StrEqual(strCurrentMap, mapName, false)) {
				int iMission;
				LMM_FindMapIndexByName(g_iGameMode, iMission, mapName);
				// Locate the current mission in the mission cycle list
				for (int cycleIndex = 0; cycleIndex < cycleCount; cycleIndex++) {
					if (ACS_GetMissionIndex(g_iGameMode, cycleIndex) == iMission) {
						if (cycleIndex >= ACS_GetCycledMissionCount(g_iGameMode) - 1) {	//Check to see if its the end of the array
							cycleIndex_ret = 0;					//If so, start the array over by setting to -1 + 1 = 0
						} else {
							cycleIndex_ret = cycleIndex + 1;
						}
						return true;
					}
				}
			}
		}
	}

	//LogError("ACS was unable to locate the current map (%s) in the map cycle!", strCurrentMap);
	return false;
}

void DisplayNextMapTo_Scavenge(int client, bool replyCMD) {
	int strbuf_len = (LEN_MISSION_NAME + 4) * g_iWinningMapIndices_Len;
	char[] strbuf = new char[strbuf_len];

	if(g_iWinningMapVotes > 0) {
		GetWinnerListForDisplay_Scavenge(client, strbuf, strbuf_len);

		if (replyCMD) {
			ReplyToCommand(client, "\x04[提示]\x05%t", g_iWinningMapIndices_Len == 1 ? "The next map is currently" : "The next map will be one of", strbuf);
		} else if(g_hCVar_NextMapAdMode.IntValue == DISPLAY_MODE_HINT) {
			PrintHintText(client, "%t", g_iWinningMapIndices_Len == 1 ? "The next map is currently" : "The next map will be one of", strbuf);
		} else if(g_hCVar_NextMapAdMode.IntValue == DISPLAY_MODE_CHAT)	{
			PrintToChat(client, "\x04[提示]\x05%t", g_iWinningMapIndices_Len == 1 ? "The next map is currently" : "The next map will be one of", strbuf);
		}
	} else {
		int missionIndex, mapIndex;
		if (!NextMapFromRotation_Scavenge(missionIndex, mapIndex))
			return;

		char localizedName[LEN_MISSION_NAME];
		char colorizedName[LEN_MISSION_NAME + 4];
		// Display the result to everyone
		LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), client);

		//Display the next map in the rotation in the appropriate way
		if (replyCMD) {
			Format(colorizedName, sizeof(colorizedName), "\x03%s\x05", localizedName);
			ReplyToCommand(client, "\x04[提示]\x05%t", "The next map is currently", colorizedName);
		} else if (g_hCVar_NextMapAdMode.IntValue == DISPLAY_MODE_HINT) {
			PrintHintText(client, "%t", "The next map is currently", localizedName);
		} else if (g_hCVar_NextMapAdMode.IntValue == DISPLAY_MODE_CHAT) {
			Format(colorizedName, sizeof(colorizedName), "\x03%s\x05", localizedName);
			PrintToChat(client, "\x04[提示]\x05%t", "The next map is currently", colorizedName);
		}
	}
}

void DisplayNextMapTo(int client, bool replyCMD) {
	int strbuf_len = (LEN_MISSION_NAME + 4) * g_iWinningMapIndices_Len;
	char[] strbuf = new char[strbuf_len];

	//If there is a winner to the vote display the winner if not display the next map in rotation
	if (g_iWinningMapVotes > 0) {
		GetWinnerListForDisplay(client, strbuf, strbuf_len);
		
		if (replyCMD) {
			ReplyToCommand(client, "\x04[提示]\x05%t", g_iWinningMapIndices_Len == 1 ? "The next campaign is currently" : "The next campaign will be one of", strbuf);
		} else if(g_hCVar_NextMapAdMode.IntValue == DISPLAY_MODE_HINT) {
			PrintHintText(client, "%t", g_iWinningMapIndices_Len == 1 ? "The next campaign is currently" : "The next campaign will be one of", strbuf);
		} else if(g_hCVar_NextMapAdMode.IntValue == DISPLAY_MODE_CHAT)	{
			PrintToChat(client, "\x04[提示]\x05%t", g_iWinningMapIndices_Len == 1 ? "The next campaign is currently" : "The next campaign will be one of", strbuf);
		}
	} else {
		int cycleIndex = 0;
		if (!NextMapFromRotation(cycleIndex))
			return;

		char localizedName[LEN_MISSION_NAME];
		char colorizedName[LEN_MISSION_NAME + 4];

		//Display the next map in the rotation in the appropriate way
		ACS_GetLocalizedMissionName(g_iGameMode, cycleIndex, client, localizedName, sizeof(localizedName));

		if (replyCMD) {
			Format(colorizedName, sizeof(colorizedName), "\x03%s\x05", localizedName);
			ReplyToCommand(client, "\x04[提示]%t", "The next campaign is currently", colorizedName);
		} else if (g_hCVar_NextMapAdMode.IntValue == DISPLAY_MODE_HINT) {
			PrintHintText(client, "%t", "The next campaign is currently", localizedName);
		} else if (g_hCVar_NextMapAdMode.IntValue == DISPLAY_MODE_CHAT) {
			Format(colorizedName, sizeof(colorizedName), "\x04%s\x05", localizedName);
			PrintToChat(client, "\x04[提示]%t", "The next campaign is currently", colorizedName);
		}
	}
}

// Display nothing if not on the last map
void DisplayNextMapToAll() {
	for (int client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client)) {
			if(g_iGameMode == GAMEMODE_SCAVENGE) {
				DisplayNextMapTo_Scavenge(client, false);
			} else {
				DisplayNextMapTo(client, false);
			}
		}
	}
}
/*======================================================================================
#################              V O T I N G   S Y S T E M               #################
======================================================================================*/

/*======================================================================================
################             P L A Y E R   C O M M A N D S              ################
======================================================================================*/

//Command that a player can use to vote/revote for a map/campaign
public Action MapVote(int iClient, int args) {
	if(!g_hCVar_VotingEnabled.BoolValue) {
		ReplyToCommand(iClient, "\x04[提示]\x05%t", "Voting is disable");
		return Plugin_Handled;
	}
	
	if(!OnFinaleOrScavengeMap()) {
		PrintToChat(iClient, "\x04[提示]\x05%t", "Voting is not available");
		return Plugin_Handled;
	}
	
	//Open the vote menu for the client if they arent using the server console
	if(iClient < 1)
		PrintToServer("You cannot vote for a map from the server console, use the in-game chat");
	else
		VoteMenuDraw(iClient);

	return Plugin_Handled;
}

//Command that a player can use to see the total votes for all maps/campaigns
public Action DisplayCurrentVotes(int iClient, int args) {
	char localizedName[LEN_MISSION_NAME];

	if(!g_hCVar_VotingEnabled.BoolValue) {
		ReplyToCommand(iClient, "\x04[提示]\x05%t", "Voting is disable");
		return Plugin_Handled;
	}
	
	if(!OnFinaleOrScavengeMap()) {
		PrintToChat(iClient, "\x04[提示]\x05%t", "Voting is not available");
		return Plugin_Handled;
	}
			
	//Display to the client the current winning map
	if(hasVoted()) {
		//Show message to all the players of the new vote winner
		if(g_iGameMode == GAMEMODE_SCAVENGE) {
			DisplayNextMapTo_Scavenge(iClient, true);
		} else {
			DisplayNextMapTo(iClient, true);
		}
	} else {
		ReplyToCommand(iClient, "\x04[提示]\x05%t", "No one has voted yet");	
	}


	int iNumberOfOptions;

	//Get the total number of options for the current game mode
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		iNumberOfOptions = LMM_GetMapUniqueIDCount(g_iGameMode);
	else
		iNumberOfOptions = LMM_GetNumberOfMissions(g_iGameMode);
		
	//Loop through all maps and display the ones that have votes
	int[] iMapVotes = new int[iNumberOfOptions];
	
	for(int iOption = 0; iOption < iNumberOfOptions; iOption++)	{
		iMapVotes[iOption] = 0;
		
		//Tally votes for the current map
		for(int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			if(g_iClientVote[iPlayer] == iOption)
				iMapVotes[iOption]++;
		
		//Display this particular map and its amount of votes it has to the client
		if(iMapVotes[iOption] > 0)	{
			if(g_iGameMode == GAMEMODE_SCAVENGE) {
				int missionIndex;
				int mapIndex = LMM_DecodeMapUniqueID(g_iGameMode, missionIndex, iOption);
				LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), iClient);
				ReplyToCommand(iClient, "\x04          %s: \x05%d %t", localizedName, iMapVotes[iOption], "Votes");
			} else {
				LMM_GetMissionLocalizedName(g_iGameMode, iOption, localizedName, sizeof(localizedName), iClient);
				ReplyToCommand(iClient, "\x04          %s: \x05%d %t", localizedName, iMapVotes[iOption], "Votes");
			}
				
		}
	}
	return Plugin_Handled;
}

/*======================================================================================
###############                   V O T E   M E N U                       ##############
======================================================================================*/

//Timer to show the menu to the players if they have not voted yet
public Action Timer_DisplayVoteAdToAll(Handle hTimer, any iData)
{
	if(!g_hCVar_VotingEnabled.BoolValue || !OnFinaleOrScavengeMap())
	{
		g_hTimer_DisplayVoteAdToAll = null;
		return Plugin_Stop;
	}

	// Check if anyone left the saferoom
	int entityRes = FindEntityByClassname(-1, "terror_player_manager");	// Resource Entity
	bool survivorLeftSaferoom = false;
	if (entityRes != -1) {
		survivorLeftSaferoom = view_as<bool> (GetEntProp(entityRes, Prop_Send, "m_hasAnySurvivorLeftSafeArea", 1));
	}

	// If nobody left, keep waiting...
	if (!survivorLeftSaferoom)
		return Plugin_Continue;
		
	l4d2_AllowedDie += 1;
	
	if(l4d2_AllowedDie > hCVar_VotingAdDelayfrequency)
	{
		g_hTimer_DisplayVoteAdToAll = null;
		return Plugin_Stop;
	}
	
	for(int iClient = 1;iClient <= MaxClients; iClient++)
	{
		if(!g_bClientShownVoteAd[iClient] && !g_bClientVoted[iClient] && IsClientInGame(iClient) && !IsFakeClient(iClient))
		{
			switch(g_hCVar_VotingAdMode.IntValue)
			{
				case DISPLAY_MODE_MENU: VoteMenuDraw(iClient);
				case DISPLAY_MODE_HINT: PrintHintText(iClient, "%t", "Map vote advertise", "!mapvote", "!mapvotes");
				case DISPLAY_MODE_CHAT: PrintToChat(iClient, "\x04[提示]\x05%t", "Map vote advertise", "\x03!mapvote\x05", "\x03!mapvotes\x05");
			}
			if(l4d2_AllowedDie > hCVar_VotingAdDelayfrequency)
				g_bClientShownVoteAd[iClient] = true;
		}
	}
	return Plugin_Continue;
}

//Draw the menu for voting
public void VoteMenuDraw(int iClient) {
	if(iClient < 1 || IsClientInGame(iClient) == false || IsFakeClient(iClient) == true)
		return;
	
	//Populate the menu with the maps in rotation for the corresponding game mode
	if(g_iGameMode == GAMEMODE_SCAVENGE) {
		ShowMissionChooser(iClient, true, true);	// Choose maps
	} else {
		ShowMissionChooser(iClient, false, true);	// Choose missions
	}
	
	//Play a sound to indicate that the user can vote on a map
	EmitSoundToClient(iClient, SOUND_NEW_VOTE_START);
}

//Handle the menu selection the client chose for voting
public void VoteMenuHandler(int iClient, bool dontCare, int missionIndex, int mapIndex) {
	g_bClientVoted[iClient] = true;
	
	//Set the players current vote
	if(dontCare) {
		g_iClientVote[iClient] = -1;
	} else {
		if(g_iGameMode == GAMEMODE_SCAVENGE || g_iGameMode == GAMEMODE_SURVIVAL) {
			g_iClientVote[iClient] = LMM_GetMapUniqueID(g_iGameMode, missionIndex, mapIndex);
		} else {
			g_iClientVote[iClient] = missionIndex;
		}
	}
			
	//Check to see if theres a new winner to the vote
	SetTheCurrentVoteWinner();
		
	//Display the appropriate message to the voter
	char localizedName[LEN_MISSION_NAME];
	if(dontCare) {
		PrintHintText(iClient, "%t", "You did not vote", "!mapvote");
	} else if(g_iGameMode == GAMEMODE_SCAVENGE) {
		LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), iClient);
		PrintHintText(iClient, "%t", "You voted for", localizedName, "!mapvote", "!mapvotes");
	} else {
		LMM_GetMissionLocalizedName(g_iGameMode, missionIndex, localizedName, sizeof(localizedName), iClient);
		PrintHintText(iClient, "%t", "You voted for", localizedName, "!mapvote", "!mapvotes");
	}
}

/*======================================================================================
#########       M I S C E L L A N E O U S   V O T E   F U N C T I O N S        #########
======================================================================================*/
int GetNumOfMenuOption() {
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		return LMM_GetMapUniqueIDCount(g_iGameMode);
	else
		return LMM_GetNumberOfMissions(g_iGameMode);
}

bool hasVoted() {
	return g_iWinningMapVotes > 0;
}

// Find the campaigns with the highest number of votes
// g_iWinningMapIndices will contain an array of campaign indices
// The length is indicated by g_iWinningMapIndices_Len,
// -1 means no one has voted yet
void findVoteWinner() {
	int iNumberOfOptions = GetNumOfMenuOption();
	int[] iMapVotes = new int[iNumberOfOptions];

	g_iWinningMapVotes = 0;

	//Loop through all options and get the highest voted option
	for(int iOption = 0; iOption < iNumberOfOptions; iOption++) {
		iMapVotes[iOption] = 0;

		//Tally votes for the current option
		for(int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			if(g_iClientVote[iPlayer] == iOption)
				iMapVotes[iOption]++;
		
		//Check if the current option has more votes than the currently highest voted option
		if(iMapVotes[iOption] > g_iWinningMapVotes) {
			g_iWinningMapVotes = iMapVotes[iOption];
		}
	}
	
	// Clear previous results
	g_iWinningMapIndices_Len = 0;
	for (int i=0; i< sizeof(g_iWinningMapIndices); i++) {
		g_iWinningMapIndices[i] = 0;
	}
	
	if (g_iWinningMapVotes == 0)
		return;	// No one voted yet

	for(int iOption = 0; iOption < iNumberOfOptions; iOption++) {
		if (iMapVotes[iOption] == g_iWinningMapVotes) {
			g_iWinningMapIndices[g_iWinningMapIndices_Len] = iOption;
			g_iWinningMapIndices_Len++;
		}
	}
}


//Resets all the votes for every player
void ResetAllVotes() {
	for(int iClient = 1; iClient <= MaxClients; iClient++) {
		g_bClientVoted[iClient] = false;
		g_iClientVote[iClient] = -1;
		
		//Reset so that the player can see the advertisement
		g_bClientShownVoteAd[iClient] = false;
	}

	//Reset the winning map to NULL
	g_iWinningMapVotes = 0;
	g_iWinningMapIndices_Len = 0;
	for (int i = 0; i< sizeof(g_iWinningMapIndices); i++) {
		g_iWinningMapIndices[i] = 0;
	}
}

//Tally up all the votes and set the current winner
void SetTheCurrentVoteWinner() {
	//Store the current winnder to see if there is a change
	int oldWinners[MAXPLAYERS + 1];
	int oldWinners_Len = g_iWinningMapIndices_Len;
	for (int i = 0; i < oldWinners_Len; i++) {
		oldWinners[i] = g_iWinningMapIndices[i];
	}

	//Loop through all options and get the highest voted option
	findVoteWinner();

	bool winnerChanged = false;
	if (g_iWinningMapIndices_Len == oldWinners_Len) {
		for (int i = 0; i < g_iWinningMapIndices_Len; i++) {
			if (g_iWinningMapIndices[i] != oldWinners[i]) {
				winnerChanged = true;
			}
		}
	} else {
		winnerChanged = true;
	}

	if (winnerChanged)
		DisplayNextMapToAll();
}

//Check if the current map is the last in the campaign if not in the Scavenge game mode
bool OnFinaleOrScavengeMap() {
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		return true;
	
	if(g_iGameMode == GAMEMODE_SURVIVAL)
		return false;

	// Coop or Versus
	char strCurrentMap[LEN_MAP_FILENAME];
	GetCurrentMap(strCurrentMap, sizeof(strCurrentMap));	//Get the current map from the game
	// Check if the current map is in the custom finale list
	char lastMap[LEN_MAP_FILENAME];
	if (g_iGameMode == LMM_GAMEMODE_COOP) {
		for (int i=0; i<GetArraySize(g_hStr_MyCoopFinales); i++) {
			g_hStr_MyCoopFinales.GetString(i, lastMap, sizeof(lastMap));
			if(StrEqual(strCurrentMap, lastMap, false))
				return true;
		}
	}

	// Attempt to use SDKCall first
	int sdkcall_ret = LMM_IsOnFinalMap();
	if (sdkcall_ret > -1) {
		// SDKCall succeed
		return sdkcall_ret == 1;
	}

	// SDKCall failed due to possible signature change, fallback to our classic method
	//Run through all the maps, if the current map is a finale map, return true
	for(int cycleIndex = 0; cycleIndex < ACS_GetMissionCount(g_iGameMode); cycleIndex++) {
		ACS_GetLastMapName(g_iGameMode, cycleIndex, lastMap, sizeof(lastMap));
		if(StrEqual(strCurrentMap, lastMap, false))
			return true;
	}

	return false;
}
