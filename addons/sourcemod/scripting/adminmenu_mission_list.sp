#include <sourcemod>
#include <adminmenu>
#include <l4d2_source_keyvalues>
#include <left4dhooks>
#include <localizer>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.5.1"

#define TRANSLATION_MISSIONS	"missions.phrases.txt"
#define TRANSLATION_CHAPTERS	"chapters.phrases.txt"

// --- 全局变量 ---
TopMenu g_TopMenu_AdminMenu;
Address g_pDirector;
Address g_pMatchExtL4D;
Handle g_hSDK_GetAllMissions;
StringMap g_smExclude;
ConVar g_cvMPGameMode;
char g_sCurrentGameMode[32];
bool g_bMapChanger_L4D2Changelevel;
bool g_bMapChanger_MapChanger;
bool g_bLastMenuIsOfficial[MAXPLAYERS + 1];
bool g_bLocalizerReady;

Localizer g_loc;

// --- 插件信息 ---
public Plugin myinfo = {
    name = "L4D2 Admin Mission Menu",
    author = "HoongDou ",
    description = "Adds a 'Switch Map/Mission' item to the admin menu for direct map changes.",
    version = PLUGIN_VERSION,
    url = "https://github.com/HoongDou/L4D2-HoongDou-Project"
};

// --- Natives & 库 ---
native void L4D2_ChangeLevel(const char[] sMap);
native bool MC_SetNextMap(const char[] map);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    MarkNativeAsOptional("L4D2_ChangeLevel");
    MarkNativeAsOptional("MC_SetNextMap");
    RegPluginLibrary("l4d2_mm_adminmenu");
    return APLRes_Success;
}

public void OnLibraryAdded(const char[] name) {
    if (StrEqual(name, "l4d2_changelevel")) {
        g_bMapChanger_L4D2Changelevel = true;
    } else if (StrEqual(name, "map_changer")) {
        g_bMapChanger_MapChanger = true;
    } else if (StrEqual(name, "adminmenu") && g_TopMenu_AdminMenu == null) {
        TopMenu topmenu = GetAdminTopMenu();
        if (topmenu != null) {
            OnAdminMenuReady(topmenu);
        }
    }
}

public void OnLibraryRemoved(const char[] name) {
    if (StrEqual(name, "adminmenu")) {
        g_TopMenu_AdminMenu = null;
    } else if (StrEqual(name, "l4d2_changelevel")) {
        g_bMapChanger_L4D2Changelevel = false;
    } else if (StrEqual(name, "map_changer")) {
        g_bMapChanger_MapChanger = false;
    }
}

// --- 插件核心功能 ---

public void OnPluginStart() {
    LoadTranslations("common.phrases");
    LoadTranslations("l4d2_mm_adminmenu.phrases");

    if (!Init_GameData()) {
        SetFailState("Failed to initialize game data");
        return;
    }

    Init_ExcludeList();
    Init_ConVars();
    Init_Commands();
    
    TopMenu topmenu;
    if (LibraryExists("adminmenu") && (topmenu = GetAdminTopMenu()) != null) {
        OnAdminMenuReady(topmenu);
    }

    // 初始化 Localizer
    if (LibraryExists("localizer")) {
        Init_Localizer();
    } else {
        LogMessage("Localizer not found, using fallback translation method");
        // 延迟生成翻译文件
        CreateTimer(3.0, Timer_GenerateTranslations);
    }
}

void Init_ExcludeList() {
    g_smExclude = new StringMap();
    g_smExclude.SetValue("credits", 1);
    g_smExclude.SetValue("holdoutchallenge", 1);
    g_smExclude.SetValue("holdouttraining", 1);
    g_smExclude.SetValue("parishdash", 1);
    g_smExclude.SetValue("shootzones", 1);
}

void Init_ConVars() {
    g_cvMPGameMode = FindConVar("mp_gamemode");
    if (g_cvMPGameMode != null) {
        g_cvMPGameMode.AddChangeHook(OnGameModeChanged);
        UpdateCurrentGameMode();
    }
}

void Init_Commands() {
    RegAdminCmd("sm_vpk_reload", Cmd_ReloadMissions, ADMFLAG_RCON, "Reloads VPKs and mission list.");
    RegAdminCmd("sm_adminmap_gentrans", Cmd_GenerateTranslations, ADMFLAG_RCON, "Force regenerates map translation files.");
}

// 直接调用初始化
void Init_Localizer() {
    g_loc = new Localizer();
    if (g_loc == null) {
        LogError("Failed to create Localizer instance");
        return;
    }
    
    // 直接标记为准备好并生成翻译文件
    g_bLocalizerReady = true;
    CreateTimer(1.0, Timer_GenerateTranslations);
}

public void OnMapStart() {
    UpdateCurrentGameMode();
}

/**
 * 当 Localizer 准备好后，开始生成地图翻译文件
 */
public void OnPhrasesReady() {
    LogMessage("Localizer is ready. Generating map and mission translation files...");
    g_bLocalizerReady = true;
    GenerateTranslationFiles();
}

public Action Timer_GenerateTranslations(Handle timer) {
    GenerateTranslationFiles();
    return Plugin_Continue;
}

public void OnAdminMenuReady(Handle hTopMenu) {
    TopMenu topmenu = view_as<TopMenu>(hTopMenu);
    
    if (topmenu == null) {
        PrintToServer("[Admin Mission Menu] Error: TopMenu is null in OnAdminMenuReady.");
        return;
    }

    if (topmenu == g_TopMenu_AdminMenu) {
        return;
    }
    
    g_TopMenu_AdminMenu = topmenu;
    TopMenuObject server_commands = FindTopMenuCategory(topmenu, ADMINMENU_SERVERCOMMANDS);
    if (server_commands != INVALID_TOPMENUOBJECT) {
        AddToTopMenu(topmenu, "l4d2_switch_map", TopMenuObject_Item, AdminMenu_MainHandler, server_commands, "l4d2_switch_map_access", ADMFLAG_CHANGEMAP);
        PrintToServer("[Admin Mission Menu] Menu item added successfully.");
    } else {
        PrintToServer("[Admin Mission Menu] Warning: Could not find server commands category.");
    }
}

public void AdminMenu_MainHandler(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int maxlength) {
    if (action == TopMenuAction_DisplayOption) {
        Format(buffer, maxlength, "%T", "Switch Map/Mission", client);
    } else if (action == TopMenuAction_SelectOption) {
        Display_MapTypeMenu(client);
    }
}

/**
 * 菜单1: 选择地图类型 (官方/三方)
 */
void Display_MapTypeMenu(int client) {
    if (!IsClientValid(client)) {
        return;
    }
    
    Menu menu = new Menu(MenuHandler_MapType);
    menu.SetTitle("%T", "Switch Map/Mission", client);

    char buffer[64];
    Format(buffer, sizeof(buffer), "%T", "Official Maps", client);
    menu.AddItem("official", buffer);
    Format(buffer, sizeof(buffer), "%T", "Addon Maps", client);
    menu.AddItem("addon", buffer);

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_MapType(Menu menu, MenuAction action, int client, int choice) {
    if (action == MenuAction_Select) {
        char info[16];
        menu.GetItem(choice, info, sizeof(info));

        bool isOfficial = StrEqual(info, "official");
        Display_MissionListMenu(client, isOfficial);
    } else if (action == MenuAction_Cancel) {
        if (choice == MenuCancel_ExitBack && g_TopMenu_AdminMenu != null) {
            DisplayTopMenu(g_TopMenu_AdminMenu, client, TopMenuPosition_LastCategory);
        }
    } else if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

/**
 * 菜单2: 显示战役列表 (根据官方/三方筛选)
 */
void Display_MissionListMenu(int client, bool official) {
    if (!IsClientValid(client)) {
        return;
    }
    
    Menu menu = new Menu(MenuHandler_MissionList);
    menu.SetTitle("%T", official ? "Official Missions" : "Addon Missions", client);
    g_bLastMenuIsOfficial[client] = official;

    SourceKeyValues kvMissions = SDKCall(g_hSDK_GetAllMissions, g_pMatchExtL4D);
    if (kvMissions.IsNull()) {
        PrintToChat(client, "[SM] Failed to get mission list.");
        delete menu;
        return;
    }

    int itemCount = 0;
    char missionName[64], displayTitle[128];
    
    for (SourceKeyValues kvSub = kvMissions.GetFirstTrueSubKey(); !kvSub.IsNull(); kvSub = kvSub.GetNextTrueSubKey()) {
        kvSub.GetName(missionName, sizeof(missionName));
        if (g_smExclude.ContainsKey(missionName)) {
            continue;
        }

        char modePath[128];
        Format(modePath, sizeof(modePath), "modes/%s", g_sCurrentGameMode);
        if (kvSub.FindKey(modePath).IsNull()) {
            continue;
        }

        bool isBuiltIn = kvSub.GetInt("builtin") == 1;
        if (isBuiltIn == official) {
            // 尝试从翻译文件获取，如果失败则使用原名
            if (!TranslatePhrase(client, missionName, displayTitle, sizeof(displayTitle))) {
                strcopy(displayTitle, sizeof(displayTitle), missionName);
            }
            menu.AddItem(missionName, displayTitle);
            itemCount++;
        }
    }

    if (itemCount == 0) {
        PrintToChat(client, "[SM] No maps found for current game mode.");
        delete menu;
        return;
    }

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_MissionList(Menu menu, MenuAction action, int client, int choice) {
    if (action == MenuAction_Select) {
        char missionName[64];
        menu.GetItem(choice, missionName, sizeof(missionName));
        Display_ChapterListMenu(client, missionName);
    } else if (action == MenuAction_Cancel) {
        if (choice == MenuCancel_ExitBack) {
            Display_MapTypeMenu(client);
        }
    } else if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

/**
 * 菜单3: 显示章节列表
 */
void Display_ChapterListMenu(int client, const char[] missionName) {
    if (!IsClientValid(client)) {
        return;
    }
    
    Menu menu = new Menu(MenuHandler_ChapterList);
    char title[128];
    if (!TranslatePhrase(client, missionName, title, sizeof(title))) {
        strcopy(title, sizeof(title), missionName);
    }
    menu.SetTitle(title);

    SourceKeyValues kvMissions = SDKCall(g_hSDK_GetAllMissions, g_pMatchExtL4D);
    if (kvMissions.IsNull()) {
        delete menu;
        return;
    }

    char chapterPath[192];
    Format(chapterPath, sizeof(chapterPath), "%s/modes/%s", missionName, g_sCurrentGameMode);
    SourceKeyValues kvChapters = kvMissions.FindKey(chapterPath);
    if (kvChapters.IsNull()) {
        delete menu;
        return;
    }

    int itemCount = 0;
    char mapName[64], displayMapName[128];
    
    for (SourceKeyValues kvMap = kvChapters.GetFirstTrueSubKey(); !kvMap.IsNull(); kvMap = kvMap.GetNextTrueSubKey()) {
        kvMap.GetString("Map", mapName, sizeof(mapName));
        if (IsMapValid(mapName)) {
            if (!TranslatePhrase(client, mapName, displayMapName, sizeof(displayMapName))) {
                strcopy(displayMapName, sizeof(displayMapName), mapName);
            }
            menu.AddItem(mapName, displayMapName);
            itemCount++;
        }
    }

    if (itemCount == 0) {
        PrintToChat(client, "[SM] No valid maps found for this mission.");
        delete menu;
        return;
    }

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_ChapterList(Menu menu, MenuAction action, int client, int choice) {
    if (action == MenuAction_Select) {
        char mapName[64];
        menu.GetItem(choice, mapName, sizeof(mapName));
        TriggerMapChange(mapName);
    } else if (action == MenuAction_Cancel) {
        if (choice == MenuCancel_ExitBack) {
            Display_MissionListMenu(client, g_bLastMenuIsOfficial[client]);
        }
    } else if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

// --- 辅助函数 ---

bool IsClientValid(int client) {
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && !IsFakeClient(client));
}

bool TranslatePhrase(int client, const char[] phrase, char[] buffer, int maxlen) {
    // 尝试使用SourceMod翻译系统
    char temp[256];
    Format(temp, sizeof(temp), "%T", phrase, client);
    
    // 如果翻译失败，temp会等于格式字符串，这时返回false
    if (StrContains(temp, "%T") != -1) {
        return false;
    }
    
    strcopy(buffer, maxlen, temp);
    return true;
}

void TriggerMapChange(const char[] map) {
    char mapDisplayName[128];
    if (!TranslatePhrase(0, map, mapDisplayName, sizeof(mapDisplayName))) {
        strcopy(mapDisplayName, sizeof(mapDisplayName), map);
    }
    
    PrintToChatAll("\x04[SM]\x01 Admin is forcing a map change to \x03%s\x01.", mapDisplayName);
    
    DataPack dp = new DataPack();
    dp.WriteString(map);
    CreateTimer(2.0, Timer_ChangeMap, dp, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ChangeMap(Handle timer, DataPack dp) {
    dp.Reset();
    char mapName[64];
    dp.ReadString(mapName, sizeof(mapName));
    delete dp;

    if (g_bMapChanger_L4D2Changelevel && GetFeatureStatus(FeatureType_Native, "L4D2_ChangeLevel") == FeatureStatus_Available) {
        L4D2_ChangeLevel(mapName);
    } else if (g_bMapChanger_MapChanger && GetFeatureStatus(FeatureType_Native, "MC_SetNextMap") == FeatureStatus_Available) {
        MC_SetNextMap(mapName);
        ServerCommand("changelevel %s", mapName);
    } else {
        ServerCommand("changelevel %s", mapName);
    }
    return Plugin_Stop;
}

Action Cmd_ReloadMissions(int client, int args) {
    PrintToChatAll("\x04[SM]\x01 Admin is reloading VPKs and mission list...");
    ServerCommand("update_addon_paths; mission_reload");
    ServerExecute();
    ReplyToCommand(client, "VPKs and missions reloaded.");
    CreateTimer(1.0, Timer_GenerateTranslations);
    return Plugin_Handled;
}

Action Cmd_GenerateTranslations(int client, int args) {
    ReplyToCommand(client, "Forcing regeneration of map translation files...");
    GenerateTranslationFiles();
    return Plugin_Handled;
}

void OnGameModeChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    UpdateCurrentGameMode();
}

void UpdateCurrentGameMode() {
    if (g_cvMPGameMode != null) {
        g_cvMPGameMode.GetString(g_sCurrentGameMode, sizeof(g_sCurrentGameMode));
    }
}

/**
 * 生成翻译文件
 */
void GenerateTranslationFiles() {
    char pathMissions[PLATFORM_MAX_PATH];
    char pathChapters[PLATFORM_MAX_PATH];
    
    BuildPath(Path_SM, pathMissions, sizeof(pathMissions), "translations/%s", TRANSLATION_MISSIONS);
    BuildPath(Path_SM, pathChapters, sizeof(pathChapters), "translations/%s", TRANSLATION_CHAPTERS);

    KeyValues kvMissions = new KeyValues("Phrases");
    KeyValues kvChapters = new KeyValues("Phrases");
    
    // 如果文件存在，先导入现有数据
    if (FileExists(pathMissions)) {
        kvMissions.ImportFromFile(pathMissions);
    }
    
    if (FileExists(pathChapters)) {
        kvChapters.ImportFromFile(pathChapters);
    }

    SourceKeyValues kvAllMissions = SDKCall(g_hSDK_GetAllMissions, g_pMatchExtL4D);
    if (kvMissions == null) {
        LogError("Could not get mission list from game.");
        delete kvMissions;
        delete kvChapters;
        return;
    }

    char missionKey[64], chapterKey[64];
    char missionTitle[128], chapterTitle[128];
    
    // 遍历所有战役
    for (SourceKeyValues kvSub = kvAllMissions.GetFirstTrueSubKey(); !kvSub.IsNull(); kvSub = kvSub.GetNextTrueSubKey()) {
        kvSub.GetName(missionKey, sizeof(missionKey));
        if (g_smExclude.ContainsKey(missionKey)) {
            continue;
        }

        kvSub.GetString("DisplayTitle", missionTitle, sizeof(missionTitle), missionKey);
        
        // 添加战役翻译
        AddTranslationEntry(kvMissions, missionKey, missionTitle);

        // 遍历章节
        SourceKeyValues kvModes = kvSub.FindKey("modes");
        if (kvModes.IsNull()) {
            continue;
        }

        for (SourceKeyValues kvMode = kvModes.GetFirstTrueSubKey(); !kvMode.IsNull(); kvMode = kvMode.GetNextTrueSubKey()) {
            for (SourceKeyValues kvChapter = kvMode.GetFirstTrueSubKey(); !kvChapter.IsNull(); kvChapter = kvChapter.GetNextTrueSubKey()) {
                kvChapter.GetString("Map", chapterKey, sizeof(chapterKey));
                if (StrEqual(chapterKey, "")) {
                    continue;
                }

                kvChapter.GetString("DisplayName", chapterTitle, sizeof(chapterTitle), chapterKey);
                
                // 添加章节翻译
                AddTranslationEntry(kvChapters, chapterKey, chapterTitle);
            }
        }
    }

    // 导出文件
    kvMissions.ExportToFile(pathMissions);
    kvChapters.ExportToFile(pathChapters);
    
    delete kvMissions;
    delete kvChapters;

    LogMessage("Translation files updated successfully.");
    
    // 重新加载翻译
    LoadTranslations(TRANSLATION_MISSIONS);
    LoadTranslations(TRANSLATION_CHAPTERS);
}


void AddTranslationEntry(KeyValues kv, const char[] key, const char[] displayName) {
    kv.JumpToKey(key, true);
    
    // 简化翻译逻辑，直接使用显示名称
    kv.SetString("en", displayName);
    kv.SetString("chi", displayName);
    
    kv.GoBack();
}

bool Init_GameData() {
    GameData hGameData = new GameData("l4d2_map_vote");
    if (hGameData == null) {
        LogError("Failed to load 'l4d2_map_vote.txt' gamedata file.");
        return false;
    }

    g_pDirector = hGameData.GetAddress("CDirector");
    if (g_pDirector == Address_Null) {
        LogError("Failed to find address: 'CDirector'");
        delete hGameData;
        return false;
    }

    g_pMatchExtL4D = hGameData.GetAddress("g_pMatchExtL4D");
    if (g_pMatchExtL4D == Address_Null) {
        LogError("Failed to find address: 'g_pMatchExtL4D'");
        delete hGameData;
        return false;
    }

    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetVirtual(0);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    g_hSDK_GetAllMissions = EndPrepSDKCall();
    if (g_hSDK_GetAllMissions == null) {
        LogError("Failed to create SDKCall: 'MatchExtL4D::GetAllMissions'");
        delete hGameData;
        return false;
    }

    delete hGameData;
    return true;
}