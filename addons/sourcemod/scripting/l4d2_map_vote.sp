#pragma semicolon 1 
#pragma newdecls required

#define PLUGIN_NAME             "L4D2 Map vote"
#define PLUGIN_AUTHOR           "fdxx, sorallll"
#define PLUGIN_DESCRIPTION      "Map vote with mission-only for players; chapters for admins"
#define PLUGIN_VERSION          "0.9.2-custom" // MOD: bumped
#define PLUGIN_URL              ""

#define TRANSLATION_MISSIONS    "missions.phrases.txt"
#define TRANSLATION_CHAPTERS    "chapters.phrases.txt"

#define SOUND_MENU              "ui/pickup_secret01.wav"

#define NOTIFY_CHAT             (1<<0)
#define NOTIFY_HINT             (1<<1)
#define NOTIFY_MENU             (1<<2)

#define BENCHMARK               0
#if BENCHMARK
    #include <profiler>
    Profiler g_profiler;
#endif

#include <sourcemod>
#include <sdktools>
#include <l4d2_nativevote>          // https://github.com/fdxx/l4d2_nativevote
#include <l4d2_source_keyvalues>    // https://github.com/fdxx/l4d2_source_keyvalues
#include <colors>
#include <localizer>
#include <left4dhooks>

Localizer
    loc;

Address
    g_pDirector,
    g_pMatchExtL4D;

Handle
    g_hSDK_GetAllMissions,
    g_hSDK_OnChangeMissionVote;

StringMap
    g_smExclude,
    g_smFirstMap;

ConVar
    g_cvMPGameMode,
    g_cvNotifyMapNext,
    g_cvAutoReloadMode,          // 0=关闭；1=仅管理员触发；2=所有人触发
    g_cvAutoReloadCooldown,
    g_cvVersusFromCoop;

char
    g_sMode[128];

bool
    g_bOnce,
    g_bMapChanger,
    g_bMissionKVInjected;

Address
    g_pLastMissionRoot;

int
    g_iNotifyMapNext,
    g_iType[MAXPLAYERS + 1],
    g_iPos[MAXPLAYERS + 1][2];

static char
    g_sLangCode[][] = {
        "en",
        "chi"
    };
float g_fNextReloadAt = 0.0;     // 下一次允许自动刷新的时间戳（GetGameTime）


public Plugin myinfo = {
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

native bool MC_SetNextMap(const char[] map);
public void OnLibraryAdded(const char[] name) {
    if (strcmp(name, "map_changer") == 0)
        g_bMapChanger = true;
}

public void OnLibraryRemoved(const char[] name) {
    if (strcmp(name, "map_changer") == 0)
        g_bMapChanger = false;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    RegPluginLibrary("l4d2_map_vote");
    MarkNativeAsOptional("MC_SetNextMap");
    return APLRes_Success;
}

public void OnPluginStart() {
	LoadTranslations("l4d2_map_vote.phrases");
    Init();
    g_smFirstMap = new StringMap();

    CreateConVar("l4d2_map_vote_version", PLUGIN_VERSION, "L4D2 Map vote plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    g_cvNotifyMapNext =  CreateConVar("notify_map_next", "1", "终局开始后提示投票下一张地图的方式. \n0=不提示, 1=聊天栏, 2=屏幕中央, 4=弹出菜单.", FCVAR_NOTIFY);
    g_cvAutoReloadMode = CreateConVar(
    "l4d2_mapvote_autoreload", "2",
    "输入 !mapvote 时是否自动刷新 VPK 与战役列表：0=关；1=仅管理员触发；2=所有人触发。",
    FCVAR_NOTIFY);

    g_cvAutoReloadCooldown = CreateConVar(
        "l4d2_mapvote_reload_cd", "10.0",
        "自动刷新冷却（秒），避免被频繁触发导致卡顿。",
        FCVAR_NOTIFY);
	g_cvVersusFromCoop = CreateConVar(
		"l4d2_mapvote_versus_from_coop", "1",
		"给缺少 versus 的战役临时注入 modes/versus：0=关，1=仅 Anne 派生 cfg，2=所有 cfg。",
		FCVAR_NOTIFY);
    g_cvNotifyMapNext.AddChangeHook(CvarChanged);
    g_cvVersusFromCoop.AddChangeHook(CvarChanged_MissionKV);

    loc = new Localizer();
    loc.Delegate_InitCompleted(OnPhrasesReady);

    //AutoExecConfig(true);

    g_cvMPGameMode = FindConVar("mp_gamemode");
    g_cvMPGameMode.AddChangeHook(CvarChanged_Mode);

    RegConsoleCmd("sm_v3",        cmdMapVote);
    RegConsoleCmd("sm_maps",      cmdMapVote);
    RegConsoleCmd("sm_chmap",     cmdMapVote);
    RegConsoleCmd("sm_mapvote",   cmdMapVote);
    RegConsoleCmd("sm_votemap",   cmdMapVote);

	//RegConsoleCmd("sm_mapvote",		cmdMapNext);
    RegConsoleCmd("sm_mapnext",   cmdMapNext);
    RegConsoleCmd("sm_votenext",  cmdMapNext);

    RegAdminCmd("sm_reload_vpk",      cmdReload,      ADMFLAG_ROOT);
    RegAdminCmd("sm_update_vpk",      cmdReload,      ADMFLAG_ROOT);
    //RegAdminCmd("sm_missions_reload", cmdReload,      ADMFLAG_ROOT);
    RegAdminCmd("sm_missions_export", cmdRxport,      ADMFLAG_ROOT);

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

    HookEntityOutput("trigger_finale", "FinaleStart", OnFinaleStart);
}

enum struct esPhrase {
    char key[64];
    char val[64];
    int official;
}

public void OnPhrasesReady() {
    #if BENCHMARK
    g_profiler = new Profiler();
    g_profiler.Start();
    #endif

    InjectMissionKV();

    esPhrase esp;
    ArrayList al_missions = new ArrayList(sizeof esPhrase);
    ArrayList al_chapters = new ArrayList(sizeof esPhrase);

    int value;
    char phrase[64];
    char translation[64];
    SourceKeyValues kvModes;
    SourceKeyValues kvChapters;
    SourceKeyValues kvMissions = SDKCall(g_hSDK_GetAllMissions, g_pMatchExtL4D);
    for (kvMissions = kvMissions.GetFirstTrueSubKey(); !kvMissions.IsNull(); kvMissions = kvMissions.GetNextTrueSubKey()) {
        kvMissions.GetName(phrase, sizeof phrase);
        if (g_smExclude.ContainsKey(phrase))
            continue;

        kvModes = kvMissions.FindKey("modes");
        if (kvModes.IsNull())
            continue;

        value = kvMissions.GetInt("builtin");
        if (al_missions.FindString(phrase) == -1) {
            kvMissions.GetString("DisplayTitle", translation, sizeof translation, "N/A");
            strcopy(esp.key, sizeof esp.key, phrase);
            strcopy(esp.val, sizeof esp.val, !strcmp(translation, "N/A") ? phrase : translation);
            esp.official = value;
            al_missions.PushArray(esp);
        }

        for (kvModes = kvModes.GetFirstTrueSubKey(); !kvModes.IsNull(); kvModes = kvModes.GetNextTrueSubKey()) {
            for (kvChapters = kvModes.GetFirstTrueSubKey(); !kvChapters.IsNull(); kvChapters = kvChapters.GetNextTrueSubKey()) {
                GetKVStringEither(kvChapters, "map", "Map", phrase, sizeof phrase);
                if (!phrase[0] || FindCharInString(phrase, '/') != -1)
                    continue;

                if (al_chapters.FindString(phrase) == -1) {
                    kvChapters.GetString("DisplayName", translation, sizeof translation, "N/A");
                    strcopy(esp.key, sizeof esp.key, phrase);
                    strcopy(esp.val, sizeof esp.val, !strcmp(translation, "N/A") ? phrase : translation);
                    esp.official = value;
                    al_chapters.PushArray(esp);
                }
            }
        }
    }

    int x;
    File file;
    KeyValues kv;
    char buffer[64];
    char FilePath[PLATFORM_MAX_PATH];

    int missions_len = al_missions.Length;
    int chapters_len = al_chapters.Length;
    for (int i; i < sizeof g_sLangCode; i++) {
        kv = new KeyValues("Phrases");
        BuildPhrasePath(FilePath, sizeof FilePath, TRANSLATION_MISSIONS, g_sLangCode[i]);
        if (!FileExists(FilePath)) {
            file = OpenFile(FilePath, "w");
            if (!file) {
                LogError("Cannot open file: \"%s\"", FilePath);
                continue;
            }

            if (!file.WriteLine("")) {
                LogError("Cannot write file line: \"%s\"", FilePath);
                delete file;
                continue;
            }

            delete file;

            for (x = 0; x < missions_len; x++) {
                al_missions.GetArray(x, esp);
                if (kv.JumpToKey(esp.key, true)) {
                    if (!esp.official)
                        kv.SetString(g_sLangCode[i], esp.val);
                    else {
                        loc.PhraseTranslateToLang(esp.val, buffer, sizeof buffer, _, _, g_sLangCode[i], esp.val);
                        kv.SetString(g_sLangCode[i], buffer);
                    }
                    kv.Rewind();
                    kv.ExportToFile(FilePath);
                }
            }
        }
        else if(kv.ImportFromFile(FilePath)) {
            for (x = 0; x < missions_len; x++) {
                al_missions.GetArray(x, esp);
                if (kv.JumpToKey(esp.key, true)) {
                    if (!kv.JumpToKey(g_sLangCode[i])) {
                        if (!esp.official)
                            kv.SetString(g_sLangCode[i], esp.val);
                        else {
                            loc.PhraseTranslateToLang(esp.val, buffer, sizeof buffer, _, _, g_sLangCode[i], esp.val);
                            kv.SetString(g_sLangCode[i], buffer);
                        }
                        kv.SetString(g_sLangCode[i], esp.val);
                        kv.Rewind();
                        kv.ExportToFile(FilePath);
                    }
                    kv.Rewind();
                }
            }
        }

        delete kv;

        kv = new KeyValues("Phrases");
        BuildPhrasePath(FilePath, sizeof FilePath, TRANSLATION_CHAPTERS, g_sLangCode[i]);
        if (!FileExists(FilePath)) {
            file = OpenFile(FilePath, "w");
            if (!file) {
                LogError("Cannot open file: \"%s\"", FilePath);
                continue;
            }

            if (!file.WriteLine("")) {
                LogError("Cannot write file line: \"%s\"", FilePath);
                delete file;
                continue;
            }

            delete file;

            for (x = 0; x < chapters_len; x++) {
                al_chapters.GetArray(x, esp);
                if (kv.JumpToKey(esp.key, true)) {
                    if (!esp.official)
                        kv.SetString(g_sLangCode[i], esp.val);
                    else {
                        loc.PhraseTranslateToLang(esp.val, buffer, sizeof buffer, _, _, g_sLangCode[i], esp.val);
                        kv.SetString(g_sLangCode[i], buffer);
                    }
                    kv.Rewind();
                    kv.ExportToFile(FilePath);
                }
            }
        }
        else if(kv.ImportFromFile(FilePath)) {
            for (x = 0; x < chapters_len; x++) {
                al_chapters.GetArray(x, esp);
                if (kv.JumpToKey(esp.key, true)) {
                    if (!kv.JumpToKey(g_sLangCode[i])) {
                        if (!esp.official)
                            kv.SetString(g_sLangCode[i], esp.val);
                        else {
                            loc.PhraseTranslateToLang(esp.val, buffer, sizeof buffer, _, _, g_sLangCode[i], esp.val);
                            kv.SetString(g_sLangCode[i], buffer);
                        }
                        kv.Rewind();
                        kv.ExportToFile(FilePath);
                    }
                }
                kv.Rewind();
            }
        }

        delete kv;
    }

    loc.Close();
    delete al_missions;
    delete al_chapters;

    value = 0;
    BuildPhrasePath(FilePath, sizeof FilePath, TRANSLATION_MISSIONS, "en");
    if (FileExists(FilePath)) {
        value = 1;
        LoadTranslations("missions.phrases");
    }

    BuildPhrasePath(FilePath, sizeof FilePath, TRANSLATION_CHAPTERS, "en");
    if (FileExists(FilePath)) {
        value = 1;
        LoadTranslations("chapters.phrases");
    }

    if (value) {
        InsertServerCommand("sm_reload_translations");
        ServerExecute();
    }

    #if BENCHMARK
    g_profiler.Stop();
    LogError("Export Phrases Time: %f", g_profiler.Time);
    #endif
}

void BuildPhrasePath(char[] buffer, int maxlength, const char[] fliename, const char[] lang_code) {
    strcopy(buffer, maxlength, "translations/");

    int len;
    if (strcmp(lang_code, "en")) {
        len = strlen(buffer);
        FormatEx(buffer[len], maxlength - len, "%s/", lang_code);
    }

    len = strlen(buffer);
    FormatEx(buffer[len], maxlength - len, "%s", fliename);
    BuildPath(Path_SM, buffer, maxlength, "%s", buffer);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    g_bOnce = false;
}

void OnFinaleStart(const char[] output, int caller, int activator, float delay) {
    if (!g_bOnce && L4D_IsMissionFinalMap()) {
        g_bOnce = true;

        if (g_iNotifyMapNext & NOTIFY_CHAT)
            CPrintToChatAll("%t", "L4D2MapVote_MapnextChatPrompt");

        if (g_iNotifyMapNext & NOTIFY_HINT)
            PrintHintTextToAll("聊天栏输入 !mapnext 投票下一张地图");

        if (g_iNotifyMapNext & NOTIFY_MENU) {
            int team;
            for (int i = 1; i <= MaxClients; i++) {
                // MOD: 修正括号优先级
                if (IsClientInGame(i) && !IsFakeClient(i) && ((team = GetClientTeam(i)) == 2 || team == 3))
                    cmdMapNext(i, 0);
            }
            EmitSoundToAll(SOUND_MENU, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
        }
    }
}

void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    GetCvars();
}

void CvarChanged_Mode(ConVar convar, const char[] oldValue, const char[] newValue) {
    GetCvars_Mode();
    MarkMissionKVDirty();
    SetFirstMapString();
}

void CvarChanged_MissionKV(ConVar convar, const char[] oldValue, const char[] newValue) {
    MarkMissionKVDirty();
}

public void OnConfigsExecuted() {
    GetCvars();
    GetCvars_Mode();
    InjectMissionKV();
    SetFirstMapString();
}

void GetCvars() {
    g_iNotifyMapNext = g_cvNotifyMapNext.IntValue;
}

void GetCvars_Mode() {
    g_cvMPGameMode.GetString(g_sMode, sizeof g_sMode);
}

void SetFirstMapString() {
    InjectMissionKV();

    g_smFirstMap.Clear();
    char mission[64], map[64];
    SourceKeyValues kvMissions = SDKCall(g_hSDK_GetAllMissions, g_pMatchExtL4D);
    for (SourceKeyValues kvSub = kvMissions.GetFirstTrueSubKey(); !kvSub.IsNull(); kvSub = kvSub.GetNextTrueSubKey()) {
        SourceKeyValues kvMode = FindVisibleMissionMode(kvSub, g_sMode);
        if (kvMode.IsNull())
            continue;

        SourceKeyValues kvFirstMap = kvMode.FindKey("1");
        if (kvFirstMap.IsNull())
            continue;

        kvSub.GetName(mission, sizeof mission);
        GetKVStringEither(kvFirstMap, "map", "Map", map, sizeof map);
        if (!map[0])
            continue;

        g_smFirstMap.SetString(map, mission);
    }
}

void MarkMissionKVDirty() {
    g_bMissionKVInjected = false;
    g_pLastMissionRoot = Address_Null;
}

SourceKeyValues GetMissionManagerRoot() {
    if (g_pMatchExtL4D == Address_Null)
        return view_as<SourceKeyValues>(Address_Null);

    Address root = view_as<Address>(LoadFromAddress(g_pMatchExtL4D + view_as<Address>(4), NumberType_Int32));
    return view_as<SourceKeyValues>(root);
}

void InjectMissionKV(bool force = false) {
    if (!ShouldUseVersusMissionInjection())
        return;

    SourceKeyValues kvRoot = GetMissionManagerRoot();
    if (kvRoot.IsNull())
        return;

    Address root = view_as<Address>(kvRoot);
    if (!force && g_bMissionKVInjected && g_pLastMissionRoot == root)
        return;

    g_pLastMissionRoot = root;

    SourceKeyValues kvMissions = kvRoot.FindKey("Missions");
    if (kvMissions.IsNull()) {
        kvMissions = SDKCall(g_hSDK_GetAllMissions, g_pMatchExtL4D);
        if (kvMissions.IsNull())
            return;
    }

    int injected;
    int indexed;
    char mission[64];
    for (SourceKeyValues kvMission = kvMissions.GetFirstTrueSubKey(); !kvMission.IsNull(); kvMission = kvMission.GetNextTrueSubKey()) {
        kvMission.GetName(mission, sizeof mission);
        if (g_smExclude.ContainsKey(mission))
            continue;

        SourceKeyValues kvVersus = kvMission.FindKey("modes/versus");
        if (kvVersus.IsNull()) {
            SourceKeyValues kvSource = FindMissionModeSource(kvMission);
            if (kvSource.IsNull())
                continue;

            kvVersus = kvMission.FindKey("modes/versus", true);
            if (kvVersus.IsNull())
                continue;

            if (CopyMissionModeChapters(kvSource, kvVersus, mission)) {
                kvVersus.SetInt("AnneHappyInjected", 1);
                injected++;
            }
            else {
                continue;
            }
        }

        if (RegisterMissionModePointer(kvRoot, "versus", mission, kvMission))
            indexed++;
    }

    g_bMissionKVInjected = true;

    if (injected || indexed)
        LogMessage("Injected mission KV for versus: modes=%d, indexes=%d", injected, indexed);
}

bool ShouldUseVersusMissionInjection() {
    if (g_cvVersusFromCoop == null)
        return false;

    int mode = g_cvVersusFromCoop.IntValue;
    if (mode <= 0)
        return false;

    if (mode >= 2)
        return true;

    ConVar cfgName = FindConVar("l4d_ready_cfg_name");
    if (cfgName == null)
        return false;

	char cfg[128];
	cfgName.GetString(cfg, sizeof cfg);
	return StrContains(cfg, "AnneHappy", false) != -1
		|| StrContains(cfg, "WitchParty", false) != -1
		|| StrContains(cfg, "AllCharger", false) != -1
		|| StrContains(cfg, "Alone", false) != -1
		|| StrContains(cfg, "1vHunters", false) != -1;
}

SourceKeyValues FindVisibleMissionMode(SourceKeyValues kvMission, const char[] mode) {
    char key[64];
    FormatEx(key, sizeof key, "modes/%s", mode);
    SourceKeyValues kvMode = kvMission.FindKey(key);
    if (kvMode.IsNull())
        return kvMode;

    if (StrEqual(mode, "versus", false) && kvMode.GetInt("AnneHappyInjected", 0) && !ShouldUseVersusMissionInjection())
        return view_as<SourceKeyValues>(Address_Null);

    return kvMode;
}

SourceKeyValues FindMissionModeSource(SourceKeyValues kvMission) {
    static char modes[][] = {
        "coop",
        "realism"
    };

    for (int i; i < sizeof modes; i++) {
        char key[32];
        FormatEx(key, sizeof key, "modes/%s", modes[i]);
        SourceKeyValues kvMode = kvMission.FindKey(key);
        if (!kvMode.IsNull())
            return kvMode;
    }

    return view_as<SourceKeyValues>(Address_Null);
}

bool CopyMissionModeChapters(SourceKeyValues kvSource, SourceKeyValues kvDest, const char[] mission) {
    int chapters = GetMissionChapterCount(kvSource);
    if (chapters <= 0)
        return false;

    int copied;
    char key[16];
    for (int i = 1; i <= chapters; i++) {
        IntToString(i, key, sizeof key);
        SourceKeyValues kvSourceChapter = kvSource.FindKey(key);
        if (kvSourceChapter.IsNull())
            continue;

        SourceKeyValues kvDestChapter = kvDest.FindKey(key, true);
        if (kvDestChapter.IsNull())
            continue;

        CopyMissionChapterValues(kvSourceChapter, kvDestChapter, mission, i);
        copied++;
    }

    if (!copied)
        return false;

    kvDest.SetInt("chapters", chapters);
    return true;
}

int GetMissionChapterCount(SourceKeyValues kvMode) {
    int chapters = kvMode.GetInt("chapters", 0);
    if (chapters > 0)
        return chapters;

    char name[16], map[64];
    for (SourceKeyValues kvChapter = kvMode.GetFirstTrueSubKey(); !kvChapter.IsNull(); kvChapter = kvChapter.GetNextTrueSubKey()) {
        kvChapter.GetName(name, sizeof name);
        GetKVStringEither(kvChapter, "map", "Map", map, sizeof map);
        if (map[0]) {
            int chapter = StringToInt(name);
            if (chapter > chapters)
                chapters = chapter;
        }
    }

    return chapters;
}

void CopyMissionChapterValues(SourceKeyValues kvSource, SourceKeyValues kvDest, const char[] mission, int chapter) {
    char key[64];
    char value[256];
    for (SourceKeyValues kvValue = kvSource.GetFirstValue(); !kvValue.IsNull(); kvValue = kvValue.GetNextValue()) {
        kvValue.GetName(key, sizeof key);
        switch (kvValue.GetDataType(NULL_STRING)) {
            case TYPE_STRING: {
                kvValue.GetString(NULL_STRING, value, sizeof value, "");
                kvDest.SetString(key, value);
            }
            case TYPE_INT: {
                kvDest.SetInt(key, kvValue.GetInt(NULL_STRING, 0));
            }
            case TYPE_FLOAT: {
                kvDest.SetFloat(key, kvValue.GetFloat(NULL_STRING, 0.0));
            }
        }
    }

    if (GetKVStringEither(kvSource, "map", "Map", value, sizeof value)) {
        kvDest.SetString("map", value);
        kvDest.SetString("Map", value);
    }

    if (GetKVStringEither(kvDest, "DisplayName", "displayname", value, sizeof value)) {
        kvDest.SetString("DisplayName", value);
    }
    else {
        FormatEx(value, sizeof value, "%s-%d", mission, chapter);
        kvDest.SetString("DisplayName", value);
    }

    if (GetKVStringEither(kvDest, "image", "Image", value, sizeof value))
        kvDest.SetString("image", value);
    else
        kvDest.SetString("image", "maps/unknown");

    kvDest.SetInt("chapter", chapter);
}

bool GetKVStringEither(SourceKeyValues kv, const char[] first, const char[] second, char[] value, int maxlength) {
    kv.GetString(first, value, maxlength, "");
    if (!value[0])
        kv.GetString(second, value, maxlength, "");

    return value[0] != '\0';
}

bool RegisterMissionModePointer(SourceKeyValues kvRoot, const char[] mode, const char[] mission, SourceKeyValues kvMission) {
    char path[128];
    FormatEx(path, sizeof path, "GameModes/%s/missions/%s", mode, mission);

    Address missionPtr = view_as<Address>(kvMission);
    if (kvRoot.GetPtr(path, Address_Null) == missionPtr)
        return false;

    kvRoot.SetPtr(path, missionPtr);
    return true;
}

// 统一的刷新逻辑：刷新 VPK 路径 + mission_reload + 重新生成短语和首章映射
void DoReloadVPKAndMissions()
{
    ServerCommand("update_addon_paths; mission_reload");
    ServerExecute();
    MarkMissionKVDirty();
    InjectMissionKV(true);

    // 你的原逻辑：重导翻译短语、重建首章映射
    OnPhrasesReady();
    SetFirstMapString();

    // 反馈给所有真人玩家
    CPrintToChatAll("%t", "L4D2MapVote_VPKCampaignListsRefreshed");
}

bool MaybeAutoReloadOnMapvote(int client)
{
    int mode = g_cvAutoReloadMode.IntValue;       // 0/1/2
    if (mode == 0) return false;

    bool isAdmin = CheckCommandAccess(client, "sm_reload_vpk", ADMFLAG_ROOT, true);
    if (mode == 1 && !isAdmin) {
        // 仅管理员模式下，非管理员触发不会刷新
        return false;
    }

    float now = GetGameTime();
    float cd  = g_cvAutoReloadCooldown.FloatValue;

    if (now < g_fNextReloadAt) {
        // 冷却中只对发起者提示一下（避免刷屏）
        float left = g_fNextReloadAt - now;
        if (left < 0.1) left = 0.1;
        CPrintToChat(client, "%t", "L4D2MapVote_VPKRefreshCooldownRemaining", left);
        return false;
    }

    // 真正执行刷新
    DoReloadVPKAndMissions();
    g_fNextReloadAt = now + cd;
    return true;
}

Action cmdReload(int client, int args) {
    DoReloadVPKAndMissions();
    ReplyToCommand(client, "已刷新 VPK 与战役列表。");
    return Plugin_Handled;
}

Action cmdRxport(int client, int args) {
    if (args != 1) {
        ReplyToCommand(client, "sm_missions_export <file>");
        return Plugin_Handled;
    }

    InjectMissionKV();

    char file[PLATFORM_MAX_PATH];
    GetCmdArg(1, file, sizeof file);
    SourceKeyValues kv = SDKCall(g_hSDK_GetAllMissions, g_pMatchExtL4D);
    if (kv.SaveToFile(file))
        ReplyToCommand(client, "Save to file succeeded: %s", file);

    return Plugin_Handled;
}

// ==============================
// !mapnext （终局下一战役投票）
// ==============================

Action cmdMapNext(int client, int args) {
    if (!client || !IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Handled;

    if (!g_bMapChanger) {
        CPrintToChat(client, "%t", "L4D2MapVote_PrePluginNotInstalled");
        return Plugin_Handled;
    }

    if (!L4D_IsMissionFinalMap()) {
        CPrintToChat(client, "%t", "L4D2MapVote_CurrentMapNotFinalMap");
        return Plugin_Handled;
    }

    if (GetClientTeam(client) == 1) {
        CPrintToChat(client, "%t", "L4D2MapVote_SpectatorsCannotVote");
        return Plugin_Handled;
    }

    Menu menu = new Menu(MapNext_MenuHandler);
    menu.SetTitle("选择下一张地图:");
    menu.AddItem("", "官方地图");
    menu.AddItem("", "三方地图");
    menu.Display(client, 30);
    return Plugin_Handled;
}

int MapNext_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
    switch (action) {
        case MenuAction_Select: {
            g_iPos[client][0] = 0;
            g_iPos[client][1] = 0;
            g_iType[client] = param2;

            ShowNextMap(client);
        }
    
        case MenuAction_End:
            delete menu;
    }

    return 0;
}

void ShowNextMap(int client) {
    InjectMissionKV();

    char title[64];
    char buffer[64];
    Menu menu = new Menu(ShowNextMap_MenuHandler);
    menu.SetTitle("选择地图:");

    SourceKeyValues kvMissions = SDKCall(g_hSDK_GetAllMissions, g_pMatchExtL4D);
    for (SourceKeyValues kvSub = kvMissions.GetFirstTrueSubKey(); !kvSub.IsNull(); kvSub = kvSub.GetNextTrueSubKey()) {
        kvSub.GetName(title, sizeof title);
        if (g_smExclude.ContainsKey(title))
            continue;

        if (FindVisibleMissionMode(kvSub, g_sMode).IsNull())
            continue;

        int val;
        val = kvSub.GetInt("builtin");
        if (val && g_iType[client] == 0) {
            fmt_Translate(title, buffer, sizeof buffer, client, title);
            menu.AddItem(title, buffer);
        }
        else if (!val && g_iType[client] == 1) {
            fmt_Translate(title, buffer, sizeof buffer, client, title);
            menu.AddItem(title, buffer);
        }
    }

    menu.ExitBackButton = true;
    menu.DisplayAt(client, g_iPos[client][g_iType[client]], 30);
}

int ShowNextMap_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
    switch (action) {
        case MenuAction_Select: {
            g_iPos[client][g_iType[client]] = menu.Selection;

            char item[64];
            menu.GetItem(param2, item, sizeof item);
            VoteNextMap(client, item);
        }

        case MenuAction_Cancel: {
            if (param2 == MenuCancel_ExitBack)
                cmdMapNext(client, 0);
        }

        case MenuAction_End:
            delete menu;
    }

    return 0;
}

void VoteNextMap(int client, const char[] item) {
    if (!L4D2NativeVote_IsAllowNewVote()) {
        CPrintToChat(client, "%t", "L4D2MapVote_VotingInProgressCannotStartNewVote");
        return;
    }

    InjectMissionKV();

    SourceKeyValues kvMissions = SDKCall(g_hSDK_GetAllMissions, g_pMatchExtL4D);
    SourceKeyValues kvMission = kvMissions.FindKey(item);
    SourceKeyValues kvChapters = kvMission.IsNull() ? view_as<SourceKeyValues>(Address_Null) : FindVisibleMissionMode(kvMission, g_sMode);
    if (kvChapters.IsNull()) {
        CPrintToChat(client, "%t", "L4D2MapVote_NoValidChapterMapExists");
        return;
    }

    bool find;
    char info[2][64];
    SourceKeyValues kvMap;
    for (kvMap = kvChapters.GetFirstTrueSubKey(); !kvMap.IsNull(); kvMap = kvMap.GetNextTrueSubKey()) {
        GetKVStringEither(kvMap, "map", "Map", info[1], sizeof info[]);
        if (IsMapValidEx(info[1])) {
            find = true;
            break;
        }
    }

    if (!find) {
        CPrintToChat(client, "%t", "L4D2MapVote_NoValidChapterMapExists");
        return;
    }

    strcopy(info[0], sizeof info[], item);
    char buffer[128];
    ImplodeStrings(info, sizeof info, "//", buffer, sizeof buffer);

    L4D2NativeVote vote = L4D2NativeVote(NextMap_Handler);
    vote.Initiator = client;
    vote.SetInfo(buffer);

    int team;
    int clients[1];
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || IsFakeClient(i) || (team = GetClientTeam(i)) < 2 || team > 3)
            continue;

        fmt_Translate(item, buffer, sizeof buffer, i, item);
        vote.SetTitle("设置下一张地图为: %s", buffer);

        clients[0] = i;
        vote.DisplayVote(clients, 1, 20);
    }
}

void NextMap_Handler(L4D2NativeVote vote, VoteAction action, int param1, int param2) {
    switch (action) {
        case VoteAction_Start: {
            char buffer[128];
            char info[2][64];
            vote.GetInfo(buffer, sizeof buffer);
            ExplodeString(buffer, "//", info, sizeof info, sizeof info[]);

            for (int i = 1; i <= MaxClients; i++) {
                if (IsClientInGame(i) && !IsFakeClient(i)) {
                    fmt_Translate(info[0], info[0], sizeof info[], i, info[0]);
                    CPrintToChat(i, "%t", "L4D2MapVote_InitiatesVoteSetsNextMap", param1, info[0]);
                }
            }
        }

        case VoteAction_PlayerVoted:
            CPrintToChatAll("%t", "L4D2MapVote_Voted", param1);

        case VoteAction_End: {
            if (vote.YesCount > vote.PlayerCount / 2) {
                vote.SetPass("设置中...");

                char buffer[128];
                char info[2][64];
                vote.GetInfo(buffer, sizeof buffer);
                ExplodeString(buffer, "//", info, sizeof info, sizeof info[]);

                if (!g_bMapChanger || !MC_SetNextMap(info[1]))
                    CPrintToChatAll("%t", "L4D2MapVote_SetupFailed");
                else {
                    for (int i = 1; i <= MaxClients; i++) {
                        if (IsClientInGame(i) && !IsFakeClient(i)) {
                            fmt_Translate(info[0], info[0], sizeof info[], i, info[0]);
                            CPrintToChat(i, "%t", "L4D2MapVote_NextMapSet", info[0]);
                        }
                    }
                }
            }
            else
                vote.SetFail();
        }
    }
}

// ==============================
// !mapvote （本次修改重点）
// 玩家：只能选战役（mission），投票通过后切该战役（第一章）。
// 管理员：可以继续选具体章节，投票通过后立刻切该章节。
// ==============================

Action cmdMapVote(int client, int args) {
    if (!client || !IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Handled;

    if (GetClientTeam(client) == 1) {
        CPrintToChat(client, "%t", "L4D2MapVote_SpectatorsCannotVote");
        return Plugin_Handled;
    }
    // 在弹出菜单之前，按配置尝试自动刷新 VPK/战役列表
    MaybeAutoReloadOnMapvote(client);
    Menu menu = new Menu(MapVote_MenuHandler);
    menu.SetTitle("选择地图类型:");
    menu.AddItem("", "官方地图");
    menu.AddItem("", "三方地图");
    menu.Display(client, 30);
    return Plugin_Handled;
}

int MapVote_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
    switch (action) {
        case MenuAction_Select: {
            g_iPos[client][0] = 0;
            g_iPos[client][1] = 0;
            g_iType[client] = param2;

            ShowVoteMap(client);
        }
    
        case MenuAction_End:
            delete menu;
    }

    return 0;
}

void ShowVoteMap(int client) {
    InjectMissionKV();

    char title[64];
    char buffer[64];
    Menu menu = new Menu(ShowVoteMap_MenuHandler);
    // MOD: 标题更贴近“战役选择”
    menu.SetTitle("选择战役:");

    SourceKeyValues kvMissions = SDKCall(g_hSDK_GetAllMissions, g_pMatchExtL4D);
    for (SourceKeyValues kvSub = kvMissions.GetFirstTrueSubKey(); !kvSub.IsNull(); kvSub = kvSub.GetNextTrueSubKey()) {
        kvSub.GetName(title, sizeof title);
        if (g_smExclude.ContainsKey(title))
            continue;

        if (FindVisibleMissionMode(kvSub, g_sMode).IsNull())
            continue;
        
        int val;
        val = kvSub.GetInt("builtin");
        if (val && g_iType[client] == 0) {
            fmt_Translate(title, buffer, sizeof buffer, client, title);
            // key=mission name，val=显示文字
            menu.AddItem(title, buffer);
        }
        else if (!val && g_iType[client] == 1) {
            fmt_Translate(title, buffer, sizeof buffer, client, title);
            menu.AddItem(title, buffer);
        }
    }

    menu.ExitBackButton = true;
    menu.DisplayAt(client, g_iPos[client][g_iType[client]], 30);
}

int ShowVoteMap_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
    switch (action) {
        case MenuAction_Select: {
            g_iPos[client][g_iType[client]] = menu.Selection;

            char mission[64];
            menu.GetItem(param2, mission, sizeof mission);

            if (IsAdminCanPickChapter(client)) {
                // 管理员：可以选择具体章节
                ShowChaptersMenu(client, mission);
            } else {
                // 普通玩家：直接按“战役”发起投票（切到该战役第一章）
                VoteChangeMission(client, mission); // MOD: 新增
            }
        }

        case MenuAction_Cancel: {
            if (param2 == MenuCancel_ExitBack)
                cmdMapVote(client, 0);
        }

        case MenuAction_End:
            delete menu;
    }

    return 0;
}

// MOD: 新增 — 检查是否允许选择章节（管理员）
bool IsAdminCanPickChapter(int client) {
    // 你也可以换成 ADMFLAG_GENERIC 或自定义指令名
    return CheckCommandAccess(client, "sm_mapvote_chapter", ADMFLAG_CHANGEMAP, true);
}

// MOD: 新增 — 战役级投票（不选章节）
void VoteChangeMission(int client, const char[] mission) {
    if (!L4D2NativeVote_IsAllowNewVote()) {
        CPrintToChat(client, "%t", "L4D2MapVote_VotingInProgressCannotStartNewVote");
        return;
    }

    InjectMissionKV();

    // mission 即 kvMissions 的 key
    L4D2NativeVote vote = L4D2NativeVote(ChangeMission_Handler);
    vote.Initiator = client;
    vote.SetInfo(mission);

    int team;
    int clients[1];

    char display[64];
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || IsFakeClient(i) || (team = GetClientTeam(i)) < 2 || team > 3)
            continue;

        fmt_Translate(mission, display, sizeof display, i, mission);
        vote.SetTitle("更换战役: %s", display);

        clients[0] = i;
        vote.DisplayVote(clients, 1, 20);
    }
}

// MOD: 新增 — 战役级投票处理
void ChangeMission_Handler(L4D2NativeVote vote, VoteAction action, int param1, int param2) {
    switch (action) {
        case VoteAction_Start: {
            char mission[64];
            vote.GetInfo(mission, sizeof mission);

            char disp[64];
            for (int i = 1; i <= MaxClients; i++) {
                if (IsClientInGame(i) && !IsFakeClient(i)) {
                    fmt_Translate(mission, disp, sizeof disp, i, mission);
                    CPrintToChat(i, "%t", "L4D2MapVote_InitiatesVoteReplacementCampaign", param1, disp);
                }
            }
        }

        case VoteAction_PlayerVoted:
            CPrintToChatAll("%t", "L4D2MapVote_Voted", param1);

        case VoteAction_End: {
            if (vote.YesCount > vote.PlayerCount / 2) {
                vote.SetPass("加载中...");

                char mission[64];
                vote.GetInfo(mission, sizeof mission);

                InjectMissionKV();

                // 直接按战役切换（CDirector::OnChangeMissionVote 会按当前 mp_gamemode 进入该战役的第一章）
                SDKCall(g_hSDK_OnChangeMissionVote, g_pDirector, mission);
            }
            else
                vote.SetFail();
        }
    }
}

// ==============================
// 管理员“选章节并立刻切换”的老逻辑（保留）
// ==============================

void ShowChaptersMenu(int client, const char[] item) {
    InjectMissionKV();

    char buffer[128];
    char info[2][64];
    SourceKeyValues kvMissions = SDKCall(g_hSDK_GetAllMissions, g_pMatchExtL4D);
    SourceKeyValues kvMission = kvMissions.FindKey(item);
    SourceKeyValues kvChapters = kvMission.IsNull() ? view_as<SourceKeyValues>(Address_Null) : FindVisibleMissionMode(kvMission, g_sMode);
    if (kvChapters.IsNull()) {
        CPrintToChat(client, "%t", "L4D2MapVote_NoValidChapterMapExists");
        return;
    }

    Menu menu = new Menu(Chapters_MenuHandler);
    menu.SetTitle("选择章节:");

    bool valid_map;
    strcopy(info[0], sizeof info[], item);
    for (SourceKeyValues kvSub = kvChapters.GetFirstTrueSubKey(); !kvSub.IsNull(); kvSub = kvSub.GetNextTrueSubKey()) {
        GetKVStringEither(kvSub, "map", "Map", info[1], sizeof info[]);
        if (!IsMapValidEx(info[1]))
            continue;

        valid_map = true;
        ImplodeStrings(info, sizeof info, "//", buffer, sizeof buffer);
        fmt_Translate(info[1], info[1], sizeof info[], client, info[1]);
        menu.AddItem(buffer, info[1]);
    }

    if (!valid_map)
        CPrintToChat(client, "%t", "L4D2MapVote_NoValidChapterMapExists");

    menu.ExitBackButton = true;
    menu.Display(client, 30);
}

int Chapters_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char item[128];
            menu.GetItem(param2, item, sizeof item);
            VoteChangeMap(client, item);
        }

        case MenuAction_Cancel: {
            if (param2 == MenuCancel_ExitBack)
                ShowVoteMap(client);
        }
    
        case MenuAction_End:
            delete menu;
    }

    return 0;
}

void VoteChangeMap(int client, const char[] item) {
    if (!L4D2NativeVote_IsAllowNewVote()) {
        CPrintToChat(client, "%t", "L4D2MapVote_VotingInProgressCannotStartNewVote");
        return;
    }

    L4D2NativeVote vote = L4D2NativeVote(ChangeMap_Handler);
    vote.Initiator = client;
    vote.SetInfo(item);

    char info[2][64];
    ExplodeString(item, "//", info, sizeof info, sizeof info[]);

    int team;
    int clients[1];
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || IsFakeClient(i) || (team = GetClientTeam(i)) < 2 || team > 3)
            continue;

        fmt_Translate(info[0], info[0], sizeof info[], i, info[0]);
        fmt_Translate(info[1], info[1], sizeof info[], i, info[1]);
        vote.SetTitle("更换地图: %s (%s)", info[0], info[1]);

        clients[0] = i;
        vote.DisplayVote(clients, 1, 20);
    }
}

void ChangeMap_Handler(L4D2NativeVote vote, VoteAction action, int param1, int param2) {
    switch (action) {
        case VoteAction_Start: {
            char buffer[128];
            char info[2][64];
            vote.GetInfo(buffer, sizeof buffer);
            ExplodeString(buffer, "//", info, sizeof info, sizeof info[]);

            for (int i = 1; i <= MaxClients; i++) {
                if (IsClientInGame(i) && !IsFakeClient(i)) {
                    fmt_Translate(info[0], info[0], sizeof info[], i, info[0]);
                    fmt_Translate(info[1], info[1], sizeof info[], i, info[1]);
                    CPrintToChat(i, "%t", "L4D2MapVote_InitiatesVoteChangeMap", param1, info[0], info[1]);
                }
            }
        }

        case VoteAction_PlayerVoted:
            CPrintToChatAll("%t", "L4D2MapVote_Voted", param1);

        case VoteAction_End: {
            if (vote.YesCount > vote.PlayerCount / 2) {
                vote.SetPass("加载中...");

                char buffer[128];
                char info[2][64];
                vote.GetInfo(buffer, sizeof buffer);
                ExplodeString(buffer, "//", info, sizeof info, sizeof info[]);

                if (!g_smFirstMap.GetString(info[1], buffer, sizeof buffer))
                    ServerCommand("changelevel %s", info[1]);
                else
                    SDKCall(g_hSDK_OnChangeMissionVote, g_pDirector, buffer);
            }
            else
                vote.SetFail();
        }
    }
}

public void OnMapStart() {
    PrecacheSound(SOUND_MENU);
}

void Init() {
    GameData hGameData = new GameData("l4d2_map_vote");
    if (!hGameData)
        SetFailState("Failed to load \"l4d2_map_vote.txt\" file");
    
    g_pDirector = hGameData.GetAddress("CDirector");
    if (!g_pDirector)
        SetFailState("Failed to find address: \"CDirector\"");

    g_pMatchExtL4D = hGameData.GetAddress("g_pMatchExtL4D");
    if (!g_pMatchExtL4D)
        SetFailState("Failed to find address: \"g_pMatchExtL4D\"");

    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetVirtual(0);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    if (!(g_hSDK_GetAllMissions = EndPrepSDKCall()))
        SetFailState("Failed to create SDKCall: \"MatchExtL4D::GetAllMissions\"");
    
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::OnChangeMissionVote");
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    if (!(g_hSDK_OnChangeMissionVote = EndPrepSDKCall()))
        SetFailState("Failed to create SDKCall: \"CDirector::OnChangeMissionVote\"");

    delete hGameData;

    g_smExclude = new StringMap();
    g_smExclude.SetValue("credits", 1);
    g_smExclude.SetValue("HoldoutChallenge", 1);
    g_smExclude.SetValue("HoldoutTraining", 1);
    g_smExclude.SetValue("parishdash", 1);
    g_smExclude.SetValue("shootzones", 1);
}

bool IsMapValidEx(const char[] map) {
    if (!map[0])
        return false;

    char foundmap[1];
    return FindMap(map, foundmap, sizeof foundmap) == FindMap_Found;
}

void fmt_Translate(const char[] phrase, char[] buffer, int maxlength, int client, const char[] defvalue="") {
    if (!TranslationPhraseExists(phrase))
        strcopy(buffer, maxlength, defvalue);
    else
        Format(buffer, maxlength, "%T", phrase, client);
}
