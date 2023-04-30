#include <sourcemod>
#include <l4d2_mission_manager>
#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

#define MMAM_MC_INFO_LEN 20
#define MMAM_MC_INFO_ALL "All maps"
#define MMAM_MC_INFO_MISSION "Mission"
#define MMAM_MC_NAME_LEN 20
#define MMAM_MC_TITLE "Switch Map/Mission"

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


// Keep track of the top menu
TopMenu g_TopMenu_AdminMenu = null;
Menu g_Menu_MissionChooser;

LMM_GAMEMODE g_iGameMode;

public Plugin myinfo = {
	name = "L4D2 MissionManager AdminMenu",
	author = "Rikka0w0",
	description = "Map/Campaign menu for server admins, see Admin Menu -> Server Commands",
	version = "v1.0.0",
	url = "http://forums.alliedmods.net/showthread.php?t=308708"
}

public void OnPluginStart(){
	LoadTranslations("l4d2_mm_adminmenu");

	/* See if the menu plugin is already ready */
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null)) {
		/* If so, manually fire the callback */
		OnAdminMenuReady(topmenu);
	}
}

public void OnLibraryAdded(const char[] sName)
{
	if(StrEqual(sName, "l4d2_changelevel")) {
		g_bMapChanger = true;
	}
}

public void OnLibraryRemoved(const char[] name) {
	if (StrEqual(name, "adminmenu", false)) {
		g_TopMenu_AdminMenu = null;
	}
	else if(StrEqual(name, "l4d2_changelevel")) {
		g_bMapChanger = true;
	}
}


public void OnMapStart() {	
	//Set the game mode
	g_iGameMode = LMM_GetCurrentGameMode();
}
/* ========== Admin Menu ========== */
public void OnAdminMenuReady(Handle hTopMenu) {
	TopMenu topmenu = TopMenu.FromHandle(hTopMenu);
	
	/* Block us from being called twice */
	if (topmenu == g_TopMenu_AdminMenu) {
		return;
	}
	g_TopMenu_AdminMenu = topmenu;
	
	// Add menu entries
	TopMenuObject adminmenu_servercommands = FindTopMenuCategory(topmenu, ADMINMENU_SERVERCOMMANDS);
	if (adminmenu_servercommands == INVALID_TOPMENUOBJECT )
		PrintToChatAll("Admin Menu -> Server Commands is not ready!");
	
	AddToTopMenu(topmenu, "switch_mapmission", TopMenuObject_Item, ItemHandler, adminmenu_servercommands);
}

public void ItemHandler(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int clientID, char[] buffer, int maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "%T", MMAM_MC_TITLE, clientID);
	} else if (action == TopMenuAction_SelectOption) {
		// The admin menu item was selected, display the mission list
		
		//Create the menu
		if (g_Menu_MissionChooser == null) {
			g_Menu_MissionChooser = CreateMenu(MissionChooserMenuHandler, MenuAction_Select | MenuAction_Cancel | MenuAction_DisplayItem | MenuAction_Display);
			g_Menu_MissionChooser.SetTitle("%T", MMAM_MC_TITLE, LANG_SERVER);
			g_Menu_MissionChooser.AddItem(MMAM_MC_INFO_ALL, "all maps");
			
			char menuName[MMAM_MC_NAME_LEN];
			for(int missionIndex = 0; missionIndex < LMM_GetNumberOfMissions(g_iGameMode); missionIndex++) {
				if (LMM_GetNumberOfMaps(g_iGameMode, missionIndex)) {
					IntToString(missionIndex, menuName, sizeof(menuName));
					g_Menu_MissionChooser.AddItem(MMAM_MC_INFO_MISSION, menuName);
				}
			}
		
			//Add an exit button
			g_Menu_MissionChooser.ExitButton = true;
			g_Menu_MissionChooser.ExitBackButton = true;
			
		}

	
		//And finally, show the menu to the client
		g_Menu_MissionChooser.Display(clientID, MENU_TIME_FOREVER);
	}
}

public int MissionChooserMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Cancel) {	// param1 - clientID, param2 - reason
		if (param2 == MenuCancel_ExitBack) {
			// Back option is select
			// Display the previous admin menu
			DisplayTopMenu(g_TopMenu_AdminMenu, param1, TopMenuPosition_LastCategory);
		}
		return 0;
	}
	
	char menuInfo[MMAM_MC_INFO_LEN];	
	char menuName[MMAM_MC_NAME_LEN];
	char localizedName[LEN_LOCALIZED_NAME];
	
	if(action == MenuAction_Select)	{ // param1 - clientID, param2 - itemID
		menu.GetItem(param2, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
	
		// Change the map to the selected item.
		IntToString(menu.Selection, menuInfo, sizeof(menuInfo));	// Use menu info to store the curreng page
	
		//Create the menu
		Menu chooser = CreateMenu(MapChooserMenuHandler, MenuAction_Select | MenuAction_DisplayItem | MenuAction_End | MenuAction_Cancel);
		chooser.SetTitle("%T", "Choose a Map", param1);
		
		if (param2 == 0) {
			// Show all maps at once
			for(int missionIndex = 0; missionIndex < LMM_GetNumberOfMissions(g_iGameMode); missionIndex++) {
				for (int mapIndex=0; mapIndex<LMM_GetNumberOfMaps(g_iGameMode, missionIndex); mapIndex++) {
					Format(menuName, sizeof(menuName), "%d,%d", missionIndex, mapIndex);
					chooser.AddItem(menuInfo, menuName);
				}
			}
		} else {
			int missionIndex = StringToInt(menuName);
			for (int mapIndex=0; mapIndex<LMM_GetNumberOfMaps(g_iGameMode, missionIndex); mapIndex++) {
				Format(menuName, sizeof(menuName), "%d,%d", missionIndex, mapIndex);
				chooser.AddItem(menuInfo, menuName);
			}
		}
		
		chooser.ExitButton = true;
		chooser.ExitBackButton = true;
		chooser.Display(param1, MENU_TIME_FOREVER);
	} else if (action == MenuAction_DisplayItem) { // param1 - clientID, param2 - itemID
		menu.GetItem(param2, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
		if (StrEqual(menuInfo, MMAM_MC_INFO_MISSION, false)) {
			int missionIndex = StringToInt(menuName);
			// Localize mission name
			LMM_GetMissionLocalizedName(g_iGameMode, missionIndex, localizedName, sizeof(localizedName), param1);		
		} else {
			// Localize other menu items
			Format(localizedName, sizeof(localizedName), "%T", menuInfo, param1);
		}
		RedrawMenuItem(localizedName);
	} else if (action == MenuAction_Display) { // param - clientID, param2 - panel
		Format(localizedName, sizeof(localizedName), "%T", MMAM_MC_TITLE, param1);
		Panel panel = view_as<Panel>(param2);
		panel.SetTitle(localizedName);
	}
	
	return 0;
}

public int MapChooserMenuHandler(Menu menu, MenuAction action, int param1, int item) {
	if (action == MenuAction_End) {
		delete menu;
		return 0;
	}
	
	char menuInfo[MMAM_MC_INFO_LEN];	
	char menuName[MMAM_MC_NAME_LEN];
	char localizedName[LEN_LOCALIZED_NAME];
	char localizedName2[LEN_LOCALIZED_NAME];
	char colorizedName[LEN_LOCALIZED_NAME*2+LEN_MAP_FILENAME];
	char mapName[LEN_MAP_FILENAME];

	char buffer_split[3][MMAM_MC_NAME_LEN];
	
	if (action == MenuAction_Cancel) {
		if (item == MenuCancel_ExitBack) {	// param1 - clientID, param2 - reason
			menu.GetItem(0, menuInfo, sizeof(menuInfo));
			int last_page = StringToInt(menuInfo);
			g_Menu_MissionChooser.DisplayAt(param1, last_page, MENU_TIME_FOREVER);
		}
	} else if (action == MenuAction_DisplayItem) {
		menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
		ExplodeString(menuName, ",", buffer_split, 3, MMAM_MC_NAME_LEN);
		int missionIndex = StringToInt(buffer_split[0]);
		int mapIndex = StringToInt(buffer_split[1]);
		LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName, sizeof(localizedName), param1);
		RedrawMenuItem(localizedName);
	} else if (action == MenuAction_Select)	{
		if (item < 0) { // Not a valid map option
			return 0;
		}
			
		menu.GetItem(item, menuInfo, sizeof(menuInfo), _, menuName, sizeof(menuName));
		ExplodeString(menuName, ",", buffer_split, 3, MMAM_MC_NAME_LEN);
		int missionIndex = StringToInt(buffer_split[0]);
		int mapIndex = StringToInt(buffer_split[1]);	

		LMM_GetMissionLocalizedName(g_iGameMode, missionIndex, localizedName, sizeof(localizedName), param1);
		LMM_GetMapName(g_iGameMode, missionIndex, mapIndex, mapName, sizeof(mapName));
		if (LMM_GetMapLocalizedName(g_iGameMode, missionIndex, mapIndex, localizedName2, sizeof(localizedName2), param1) == 1) {
			Format(colorizedName, sizeof(colorizedName), "\x04%s\x01.\x04%s (%s)\x01", localizedName, localizedName2, mapName);
		} else {
			Format(colorizedName, sizeof(colorizedName), "\x04%s\x01.\x04%s\x01", localizedName, mapName);
		}
		
		PrintToChatAll("\x03[SM]\x01 %t", "Admin is forcing a map change", colorizedName);
		
		DataPack dp;
		CreateDataTimer(3.0, Timer_ChangeMap, dp);
		dp.WriteString(mapName);
	}
	return 0;
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
		ForceChangeLevel(mapName, "Admin forced a map change");
	}
	return Plugin_Stop;
}