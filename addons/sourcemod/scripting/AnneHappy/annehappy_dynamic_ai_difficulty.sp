#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <l4dstats>

#define PLUGIN_VERSION "2026.05.17.4"
#define TEAM_SURVIVOR 2
#define DEFAULT_CONFIG_PATH "configs/AnneHappy/dynamic_ai_difficulty.cfg"
#define DEFAULT_THRESHOLD_DB_CONFIG "l4dstats"
#define DEFAULT_THRESHOLD_TABLE "ai_dynamic_ppm_thresholds"

ConVar g_cvEnable;
ConVar g_cvCheckInterval;
ConVar g_cvLevel2PPM;
ConVar g_cvLevel3PPM;
ConVar g_cvLevel4PPM;
ConVar g_cvLevel5PPM;
ConVar g_cvFixedLevel;
ConVar g_cvConfigPath;
ConVar g_cvUseQuarterStats;
ConVar g_cvQuarterMinMinutes;
ConVar g_cvThresholdMode;
ConVar g_cvThresholdDbConfig;
ConVar g_cvThresholdTable;
ConVar g_cvThresholdMaxAge;
ConVar g_cvAnnounce;
ConVar g_cvDebug;
ConVar g_cvCurrentLevel;
ConVar g_cvCurrentMode;
ConVar g_cvCurrentPPM;
ConVar g_cvCurrentLocked;

Database g_hThresholdDb = null;
Handle g_hTimer = null;
float g_fNextCheckAt = 0.0;
float g_fDbLevel2PPM = 0.0;
float g_fDbLevel3PPM = 0.0;
float g_fDbLevel4PPM = 0.0;
float g_fDbLevel5PPM = 0.0;
float g_fCurrentPPM = 0.0;
int g_iCurrentLevel = 0;
int g_iCurrentMode = 0;
int g_iDbThresholdSampleCount = 0;
int g_iDbThresholdUpdatedAt = 0;
int g_iNextThresholdRefreshAt = 0;
bool g_bDifficultyLocked = false;
bool g_bPendingAutoApply = false;
bool g_bSurvivorsLeftStartArea = false;
bool g_bThresholdDbConnecting = false;
bool g_bThresholdSchemaReady = false;
bool g_bThresholdQueryInFlight = false;
bool g_bDbThresholdReady = false;
char g_sDbThresholdSource[32];

public Plugin myinfo =
{
    name = "AnneHappy Dynamic AI Difficulty",
    author = "morzlee + ChatGPT",
    description = "根据生还者积分/游玩时间(PPM)动态调整 AnneHappy 特感难度",
    version = PLUGIN_VERSION,
    url = "https://github.com/fantasylidong/CompetitiveWithAnne"
};

public void OnPluginStart()
{
    g_cvEnable = CreateConVar("ah_ai_dynamic_enable", "1", "是否启用 AnneHappy 动态难度", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvCheckInterval = CreateConVar("ah_ai_dynamic_check_interval", "5.0", "回合定档前，每隔多少秒从 l4d_stats 重试检查一次平均 PPM", FCVAR_NOTIFY, true, 1.0, true, 60.0);
    g_cvLevel2PPM = CreateConVar("ah_ai_dynamic_ppm_normal", "30.89", "进入普通难度的 l4d_stats 平均 PPM 阈值", FCVAR_NOTIFY, true, 0.0);
    g_cvLevel3PPM = CreateConVar("ah_ai_dynamic_ppm_hard", "43.23", "进入困难难度的 l4d_stats 平均 PPM 阈值", FCVAR_NOTIFY, true, 0.0);
    g_cvLevel4PPM = CreateConVar("ah_ai_dynamic_ppm_expert", "63.70", "进入专家难度的 l4d_stats 平均 PPM 阈值", FCVAR_NOTIFY, true, 0.0);
    g_cvLevel5PPM = CreateConVar("ah_ai_dynamic_ppm_extreme", "77.57", "进入极限难度的 l4d_stats 平均 PPM 阈值", FCVAR_NOTIFY, true, 0.0);
    g_cvFixedLevel = CreateConVar("ah_ai_dynamic_fixed_level", "0", "固定动态难度：0=自动，1=简单，2=普通，3=困难，4=专家，5=极限", FCVAR_NOTIFY, true, 0.0, true, 5.0);
    g_cvConfigPath = CreateConVar("ah_ai_dynamic_config", DEFAULT_CONFIG_PATH, "难度配置文件路径，相对 addons/sourcemod", FCVAR_NOTIFY);
    g_cvUseQuarterStats = CreateConVar("ah_ai_dynamic_use_quarter_stats", "0", "是否优先使用季度积分/季度时间计算玩家 PPM；当前季度数据失真时应关闭", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvQuarterMinMinutes = CreateConVar("ah_ai_dynamic_quarter_min_minutes", "300", "玩家本季度样本低于该分钟数时回退使用总积分 PPM", FCVAR_NOTIFY, true, 0.0);
    g_cvThresholdMode = CreateConVar("ah_ai_dynamic_threshold_mode", "1", "PPM 阈值来源：0=使用本 cfg 固定阈值，1=从数据库读取每日分位阈值", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvThresholdDbConfig = CreateConVar("ah_ai_dynamic_threshold_db_config", DEFAULT_THRESHOLD_DB_CONFIG, "每日 PPM 阈值数据库配置名，对应 databases.cfg", FCVAR_NOTIFY);
    g_cvThresholdTable = CreateConVar("ah_ai_dynamic_threshold_table", DEFAULT_THRESHOLD_TABLE, "每日 PPM 阈值表名，只允许字母数字下划线", FCVAR_NOTIFY);
    g_cvThresholdMaxAge = CreateConVar("ah_ai_dynamic_threshold_max_age", "172800", "数据库阈值最大有效秒数；0=不检查过期，默认2天", FCVAR_NOTIFY, true, 0.0);
    g_cvAnnounce = CreateConVar("ah_ai_dynamic_announce", "1", "调档时是否在聊天框提示", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvDebug = CreateConVar("ah_ai_dynamic_debug", "0", "是否输出动态难度调试日志", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvCurrentLevel = CreateConVar("ah_ai_dynamic_current_level", "0", "当前回合动态难度：0=未定档，1=简单，2=普通，3=困难，4=专家，5=极限", FCVAR_DONTRECORD, true, 0.0, true, 5.0);
    g_cvCurrentMode = CreateConVar("ah_ai_dynamic_current_mode", "0", "当前回合动态难度来源：0=自动，1=固定", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
    g_cvCurrentPPM = CreateConVar("ah_ai_dynamic_current_ppm", "0.0", "当前回合自动定档使用的平均 PPM；固定模式为 0", FCVAR_DONTRECORD, true, 0.0);
    g_cvCurrentLocked = CreateConVar("ah_ai_dynamic_current_locked", "0", "当前回合动态难度是否已经锁定", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
    CreateConVar("ah_ai_dynamic_version", PLUGIN_VERSION, "AnneHappy Dynamic AI Difficulty version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_PostNoCopy);

    RegConsoleCmd("sm_aippm", Cmd_ShowPPM, "显示当前 AnneHappy 动态难度和 PPM");
    RegAdminCmd("sm_aidiff", Cmd_SetDifficulty, ADMFLAG_CONFIG, "sm_aidiff <0-5> 设置动态难度；0=自动，1-5=固定难度");
    RegAdminCmd("sm_aidiff_reload", Cmd_ReloadDifficulty, ADMFLAG_CONFIG, "重新读取难度配置并应用当前难度");

    AutoExecConfig(true, "annehappy_dynamic_ai_difficulty");
    StartDifficultyTimer();
}

public void OnConfigsExecuted()
{
    StartDifficultyTimer();
    RequestThresholdRefresh(true);
    PrepareRoundDifficulty(true);
}

public void OnMapEnd()
{
    StopDifficultyTimer();
}

void StartDifficultyTimer()
{
    if (g_hTimer != null)
        return;

    g_hTimer = CreateTimer(5.0, Timer_CheckDifficulty, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void StopDifficultyTimer()
{
    if (g_hTimer == null)
        return;

    KillTimer(g_hTimer);
    g_hTimer = null;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_fNextCheckAt = 0.0;
    g_fCurrentPPM = 0.0;
    g_iCurrentLevel = 0;
    g_iCurrentMode = 0;
    g_bDifficultyLocked = false;
    g_bPendingAutoApply = true;
    g_bSurvivorsLeftStartArea = false;
    PublishCurrentDifficulty();

    RequestThresholdRefresh(false);
    PrepareRoundDifficulty(true);
}

public void Event_PlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
    g_bSurvivorsLeftStartArea = true;

    if (!g_cvEnable.BoolValue || g_bDifficultyLocked)
        return;

    if (g_iCurrentLevel <= 0)
        ApplyDifficulty(1, true);

    g_bDifficultyLocked = true;
    g_bPendingAutoApply = false;
    PublishCurrentDifficulty();

    if (g_cvAnnounce.BoolValue)
    {
        char levelName[16];
        GetLevelName(g_iCurrentLevel, levelName, sizeof(levelName));
        PrintToChatAll("\x04[AnneHappyAI]\x01 本回合动态难度已锁定为 \x03%s\x01。", levelName);
    }
}

public Action Timer_CheckDifficulty(Handle timer)
{
    if (!g_cvEnable.BoolValue || g_bDifficultyLocked || !g_bPendingAutoApply)
        return Plugin_Continue;

    float now = GetGameTime();
    if (g_fNextCheckAt > now)
        return Plugin_Continue;

    g_fNextCheckAt = now + g_cvCheckInterval.FloatValue;

    if (ApplyFixedDifficultyIfNeeded(false))
        return Plugin_Continue;

    TryApplyAutoDifficulty(false);
    return Plugin_Continue;
}

void PrepareRoundDifficulty(bool silent)
{
    if (!g_cvEnable.BoolValue || g_bDifficultyLocked)
        return;

    if (ApplyFixedDifficultyIfNeeded(silent))
        return;

    if (g_iCurrentLevel <= 0)
    {
        ApplyDifficulty(1, true);
        g_iCurrentMode = 0;
        g_fCurrentPPM = 0.0;
        PublishCurrentDifficulty();
    }

    g_bPendingAutoApply = true;
    TryApplyAutoDifficulty(silent);
}

bool ApplyFixedDifficultyIfNeeded(bool silent)
{
    int fixedLevel = g_cvFixedLevel.IntValue;
    if (fixedLevel <= 0)
        return false;

    ApplyDifficulty(ClampLevel(fixedLevel), true);
    g_bDifficultyLocked = true;
    g_bPendingAutoApply = false;
    g_iCurrentMode = 1;
    g_fCurrentPPM = 0.0;
    PublishCurrentDifficulty();

    if (!silent && g_cvAnnounce.BoolValue)
    {
        char levelName[16];
        GetLevelName(g_iCurrentLevel, levelName, sizeof(levelName));
        PrintToChatAll("\x04[AnneHappyAI]\x01 固定动态难度：\x03%s\x01。", levelName);
    }

    return true;
}

bool TryApplyAutoDifficulty(bool silent)
{
    if (ShouldWaitForThresholdRefresh())
    {
        g_bPendingAutoApply = true;
        return false;
    }

    if (!StatsNativeReady())
    {
        g_bPendingAutoApply = true;
        return false;
    }

    int players;
    int totalScore;
    int totalMinutes;
    int quarterPlayers;
    int fallbackPlayers;
    float ppm;
    if (!GetSurvivorStatsPPM(ppm, players, totalScore, totalMinutes, quarterPlayers, fallbackPlayers))
    {
        g_bPendingAutoApply = true;
        return false;
    }

    int level = GetLevelForPPM(ppm);
    ApplyDifficulty(level, silent, ppm, totalScore, totalMinutes, players, quarterPlayers, fallbackPlayers);

    g_bDifficultyLocked = true;
    g_bPendingAutoApply = false;
    g_iCurrentMode = 0;
    g_fCurrentPPM = ppm;
    PublishCurrentDifficulty();

    if (g_cvDebug.BoolValue)
        LogMessage("[AnneHappyAI] stats_players=%d quarter_players=%d fallback_players=%d score=%d minutes=%d ppm=%.2f level=%d", players, quarterPlayers, fallbackPlayers, totalScore, totalMinutes, ppm, g_iCurrentLevel);

    return true;
}

public Action Cmd_ShowPPM(int client, int args)
{
    if (!StatsNativeReady())
    {
        ReplyToCommand(client, "[AnneHappyAI] l4d_stats native 不可用，暂时无法计算 PPM。");
        return Plugin_Handled;
    }

    int players;
    int totalScore;
    int totalMinutes;
    int quarterPlayers;
    int fallbackPlayers;
    float ppm;
    if (!GetSurvivorStatsPPM(ppm, players, totalScore, totalMinutes, quarterPlayers, fallbackPlayers))
    {
        ReplyToCommand(client, "[AnneHappyAI] 当前没有可用的真人生还者 l4d_stats 数据。");
        return Plugin_Handled;
    }

    char levelName[16];
    char thresholdSource[48];
    float ppmNormal;
    float ppmHard;
    float ppmExpert;
    float ppmExtreme;
    GetLevelName(g_iCurrentLevel, levelName, sizeof(levelName));
    GetThresholdSourceName(thresholdSource, sizeof(thresholdSource));
    GetActiveThresholds(ppmNormal, ppmHard, ppmExpert, ppmExtreme);
    ReplyToCommand(client, "[AnneHappyAI] 难度=%d(%s) PPM=%.2f 积分=%d 时间=%d分钟 人数=%d 季度样本=%d 总榜回退=%d 阈值=%s %.2f/%.2f/%.2f/%.2f 锁定=%s 固定=%d",
        g_iCurrentLevel, levelName, ppm, totalScore, totalMinutes, players, quarterPlayers, fallbackPlayers,
        thresholdSource, ppmNormal, ppmHard, ppmExpert, ppmExtreme,
        g_bDifficultyLocked ? "是" : "否", g_cvFixedLevel.IntValue);
    return Plugin_Handled;
}

public Action Cmd_SetDifficulty(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "用法: sm_aidiff <0-5>，0=自动，1=简单，2=普通，3=困难，4=专家，5=极限");
        return Plugin_Handled;
    }

    char arg[8];
    GetCmdArg(1, arg, sizeof(arg));
    int level = StringToInt(arg);
    if (level <= 0)
    {
        g_cvFixedLevel.SetInt(0, true, false);
        if (g_bSurvivorsLeftStartArea)
        {
            ReplyToCommand(client, "[AnneHappyAI] 已切换为自动难度，将从下一回合开始生效；当前回合难度不变。");
            return Plugin_Handled;
        }

        g_iCurrentMode = 0;
        g_fCurrentPPM = 0.0;
        g_bDifficultyLocked = false;
        g_bPendingAutoApply = true;

        if (!TryApplyAutoDifficulty(false))
            PublishCurrentDifficulty();

        ReplyToCommand(client, "[AnneHappyAI] 已切换为自动难度。");
        return Plugin_Handled;
    }

    level = ClampLevel(level);
    g_cvFixedLevel.SetInt(level, true, false);
    if (g_bSurvivorsLeftStartArea)
    {
        char levelName[16];
        GetLevelName(level, levelName, sizeof(levelName));
        ReplyToCommand(client, "[AnneHappyAI] 已固定难度为 %d(%s)，将从下一回合开始生效；当前回合难度不变。", level, levelName);
        return Plugin_Handled;
    }

    ApplyDifficulty(level, true);
    g_bDifficultyLocked = true;
    g_bPendingAutoApply = false;
    g_iCurrentMode = 1;
    g_fCurrentPPM = 0.0;
    PublishCurrentDifficulty();

    char levelName[16];
    GetLevelName(level, levelName, sizeof(levelName));
    ReplyToCommand(client, "[AnneHappyAI] 已固定难度为 %d(%s)", level, levelName);
    return Plugin_Handled;
}

public Action Cmd_ReloadDifficulty(int client, int args)
{
    RequestThresholdRefresh(true);

    if (g_iCurrentLevel <= 0)
    {
        ReplyToCommand(client, "[AnneHappyAI] 当前还没有定档，无法重载应用。");
        return Plugin_Handled;
    }

    int applied = ApplyProfileCvars(g_iCurrentLevel);
    ReplyToCommand(client, "[AnneHappyAI] 已重新读取配置并应用当前难度 %d，应用 %d 个 cvar。", g_iCurrentLevel, applied);
    return Plugin_Handled;
}

void PublishCurrentDifficulty()
{
    g_cvCurrentLevel.SetInt(g_iCurrentLevel, false, false);
    g_cvCurrentMode.SetInt(g_iCurrentMode, false, false);
    g_cvCurrentPPM.SetFloat(g_fCurrentPPM, false, false);
    g_cvCurrentLocked.SetInt(g_bDifficultyLocked ? 1 : 0, false, false);
}

bool StatsNativeReady()
{
    return GetFeatureStatus(FeatureType_Native, "l4dstats_GetClientScore") == FeatureStatus_Available
        && GetFeatureStatus(FeatureType_Native, "l4dstats_GetClientPlayTime") == FeatureStatus_Available;
}

bool QuarterStatsReady()
{
    return GetFeatureStatus(FeatureType_Native, "l4dstats_GetClientQuarterScore") == FeatureStatus_Available
        && GetFeatureStatus(FeatureType_Native, "l4dstats_GetClientQuarterPlayTime") == FeatureStatus_Available;
}

bool GetSurvivorStatsPPM(float &ppm, int &players, int &totalScore, int &totalMinutes, int &quarterPlayers, int &fallbackPlayers)
{
    ppm = 0.0;
    players = 0;
    totalScore = 0;
    totalMinutes = 0;
    quarterPlayers = 0;
    fallbackPlayers = 0;

    bool quarterReady = g_cvUseQuarterStats.BoolValue && QuarterStatsReady();
    int minQuarterMinutes = g_cvQuarterMinMinutes.IntValue;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != TEAM_SURVIVOR)
            continue;

        int selectedScore;
        int selectedMinutes;
        bool selectedQuarter = false;
        if (quarterReady)
        {
            int quarterMinutes = l4dstats_GetClientQuarterPlayTime(client);
            if (quarterMinutes >= minQuarterMinutes)
            {
                selectedScore = l4dstats_GetClientQuarterScore(client);
                selectedMinutes = quarterMinutes;
                selectedQuarter = true;
            }
            else
            {
                selectedScore = l4dstats_GetClientScore(client);
                selectedMinutes = l4dstats_GetClientPlayTime(client);
            }
        }
        else
        {
            selectedScore = l4dstats_GetClientScore(client);
            selectedMinutes = l4dstats_GetClientPlayTime(client);
        }

        if (selectedMinutes <= 0)
            continue;

        if (selectedScore < 0)
            selectedScore = 0;

        players++;
        if (selectedQuarter)
            quarterPlayers++;
        else
            fallbackPlayers++;

        totalScore += selectedScore;
        totalMinutes += selectedMinutes;
    }

    if (players <= 0 || totalMinutes <= 0)
        return false;

    ppm = float(totalScore) / float(totalMinutes);
    return true;
}

int GetLevelForPPM(float ppm)
{
    int level = 1;
    float ppmNormal;
    float ppmHard;
    float ppmExpert;
    float ppmExtreme;
    GetActiveThresholds(ppmNormal, ppmHard, ppmExpert, ppmExtreme);

    if (ppm >= ppmExtreme)
        level = 5;
    else if (ppm >= ppmExpert)
        level = 4;
    else if (ppm >= ppmHard)
        level = 3;
    else if (ppm >= ppmNormal)
        level = 2;

    return level;
}

void GetActiveThresholds(float &ppmNormal, float &ppmHard, float &ppmExpert, float &ppmExtreme)
{
    if (UseDbThresholds())
    {
        ppmNormal = g_fDbLevel2PPM;
        ppmHard = g_fDbLevel3PPM;
        ppmExpert = g_fDbLevel4PPM;
        ppmExtreme = g_fDbLevel5PPM;
        return;
    }

    ppmNormal = g_cvLevel2PPM.FloatValue;
    ppmHard = g_cvLevel3PPM.FloatValue;
    ppmExpert = g_cvLevel4PPM.FloatValue;
    ppmExtreme = g_cvLevel5PPM.FloatValue;
}

bool UseDbThresholds()
{
    if (!g_cvThresholdMode.BoolValue || !g_bDbThresholdReady)
        return false;

    int maxAge = g_cvThresholdMaxAge.IntValue;
    if (maxAge > 0 && g_iDbThresholdUpdatedAt > 0 && GetTime() - g_iDbThresholdUpdatedAt > maxAge)
        return false;

    return true;
}

bool ShouldWaitForThresholdRefresh()
{
    if (!g_cvThresholdMode.BoolValue || UseDbThresholds())
        return false;

    return g_bThresholdDbConnecting || g_bThresholdQueryInFlight;
}

void GetThresholdSourceName(char[] buffer, int maxlen)
{
    if (!UseDbThresholds())
    {
        strcopy(buffer, maxlen, "cfg");
        return;
    }

    FormatEx(buffer, maxlen, "db:%s/%d", g_sDbThresholdSource, g_iDbThresholdSampleCount);
}

void RequestThresholdRefresh(bool force)
{
    if (!g_cvThresholdMode.BoolValue)
        return;

    if (g_bThresholdQueryInFlight)
        return;

    int now = GetTime();
    if (!force && g_iNextThresholdRefreshAt > now)
        return;

    g_iNextThresholdRefreshAt = now + 300;

    if (g_hThresholdDb == null)
    {
        ConnectThresholdDb();
        return;
    }

    if (!g_bThresholdSchemaReady)
    {
        CreateThresholdTable();
        return;
    }

    QueryThresholdRow();
}

void ConnectThresholdDb()
{
    if (g_hThresholdDb != null || g_bThresholdDbConnecting)
        return;

    char configName[64];
    g_cvThresholdDbConfig.GetString(configName, sizeof(configName));
    TrimString(configName);
    if (configName[0] == '\0')
        strcopy(configName, sizeof(configName), DEFAULT_THRESHOLD_DB_CONFIG);

    if (!SQL_CheckConfig(configName))
    {
        LogError("[AnneHappyAI] threshold database config not found: %s", configName);
        return;
    }

    g_bThresholdDbConnecting = true;
    Database.Connect(SQL_OnThresholdDbConnected, configName);
}

public void SQL_OnThresholdDbConnected(Database db, const char[] error, any data)
{
    g_bThresholdDbConnecting = false;

    if (db == null)
    {
        LogError("[AnneHappyAI] failed to connect threshold database: %s", error);
        return;
    }

    g_hThresholdDb = db;
    if (!SQL_SetCharset(g_hThresholdDb, "utf8mb4") && g_cvDebug.BoolValue)
        LogMessage("[AnneHappyAI] failed to set threshold database charset utf8mb4");

    CreateThresholdTable();
}

bool GetThresholdTableName(char[] table, int maxlen)
{
    g_cvThresholdTable.GetString(table, maxlen);
    TrimString(table);
    if (table[0] == '\0')
        strcopy(table, maxlen, DEFAULT_THRESHOLD_TABLE);

    for (int i = 0; table[i] != '\0'; i++)
    {
        int c = table[i];
        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_')
            continue;

        LogError("[AnneHappyAI] invalid threshold table name: %s", table);
        return false;
    }

    return true;
}

void CreateThresholdTable()
{
    if (g_hThresholdDb == null || g_bThresholdQueryInFlight)
        return;

    char table[64];
    if (!GetThresholdTableName(table, sizeof(table)))
        return;

    char query[1024];
    FormatEx(query, sizeof(query),
        "CREATE TABLE IF NOT EXISTS `%s` ("
        ... "`id` tinyint unsigned NOT NULL DEFAULT 1,"
        ... "`source` varchar(32) NOT NULL DEFAULT 'daily',"
        ... "`sample_count` int NOT NULL DEFAULT 0,"
        ... "`ppm_p60` float NOT NULL DEFAULT 30.89,"
        ... "`ppm_p75` float NOT NULL DEFAULT 43.23,"
        ... "`ppm_p90` float NOT NULL DEFAULT 63.70,"
        ... "`ppm_p95` float NOT NULL DEFAULT 77.57,"
        ... "`updated_at` int NOT NULL DEFAULT 0,"
        ... "PRIMARY KEY (`id`)"
        ... ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4",
        table);

    g_bThresholdQueryInFlight = true;
    g_hThresholdDb.Query(SQL_OnThresholdTableCreated, query);
}

public void SQL_OnThresholdTableCreated(Database db, DBResultSet results, const char[] error, any data)
{
    g_bThresholdQueryInFlight = false;

    if (error[0] != '\0')
    {
        LogError("[AnneHappyAI] failed to create threshold table: %s", error);
        return;
    }

    CheckThresholdP95Column();
}

void CheckThresholdP95Column()
{
    if (g_hThresholdDb == null || g_bThresholdQueryInFlight)
        return;

    char table[64];
    if (!GetThresholdTableName(table, sizeof(table)))
        return;

    char query[512];
    FormatEx(query, sizeof(query),
        "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '%s' AND COLUMN_NAME = 'ppm_p95'",
        table);

    g_bThresholdQueryInFlight = true;
    g_hThresholdDb.Query(SQL_OnThresholdP95ColumnChecked, query);
}

public void SQL_OnThresholdP95ColumnChecked(Database db, DBResultSet results, const char[] error, any data)
{
    g_bThresholdQueryInFlight = false;

    if (error[0] != '\0')
    {
        LogError("[AnneHappyAI] failed to check threshold ppm_p95 column: %s", error);
        g_bThresholdSchemaReady = true;
        QueryThresholdRow();
        return;
    }

    if (results != null && SQL_FetchRow(results) && SQL_FetchInt(results, 0) > 0)
    {
        g_bThresholdSchemaReady = true;
        QueryThresholdRow();
        return;
    }

    AddThresholdP95Column();
}

void AddThresholdP95Column()
{
    if (g_hThresholdDb == null || g_bThresholdQueryInFlight)
        return;

    char table[64];
    if (!GetThresholdTableName(table, sizeof(table)))
        return;

    char query[256];
    FormatEx(query, sizeof(query), "ALTER TABLE `%s` ADD COLUMN `ppm_p95` float NOT NULL DEFAULT 77.57 AFTER `ppm_p90`", table);

    g_bThresholdQueryInFlight = true;
    g_hThresholdDb.Query(SQL_OnThresholdP95ColumnAdded, query);
}

public void SQL_OnThresholdP95ColumnAdded(Database db, DBResultSet results, const char[] error, any data)
{
    g_bThresholdQueryInFlight = false;

    if (error[0] != '\0')
    {
        LogError("[AnneHappyAI] failed to add threshold ppm_p95 column: %s", error);
        return;
    }

    g_bThresholdSchemaReady = true;
    QueryThresholdRow();
}

void QueryThresholdRow()
{
    if (g_hThresholdDb == null || g_bThresholdQueryInFlight)
        return;

    char table[64];
    if (!GetThresholdTableName(table, sizeof(table)))
        return;

    char query[512];
    FormatEx(query, sizeof(query), "SELECT ppm_p60, ppm_p75, ppm_p90, ppm_p95, sample_count, updated_at, source FROM `%s` WHERE id = 1 LIMIT 1", table);

    g_bThresholdQueryInFlight = true;
    g_hThresholdDb.Query(SQL_OnThresholdRowLoaded, query);
}

public void SQL_OnThresholdRowLoaded(Database db, DBResultSet results, const char[] error, any data)
{
    g_bThresholdQueryInFlight = false;

    if (error[0] != '\0')
    {
        LogError("[AnneHappyAI] failed to load threshold row: %s", error);
        return;
    }

    if (results == null || !SQL_FetchRow(results))
    {
        if (g_cvDebug.BoolValue)
            LogMessage("[AnneHappyAI] threshold row not found, using cfg thresholds");
        return;
    }

    float ppmNormal = SQL_FetchFloat(results, 0);
    float ppmHard = SQL_FetchFloat(results, 1);
    float ppmExpert = SQL_FetchFloat(results, 2);
    float ppmExtreme = SQL_FetchFloat(results, 3);
    int sampleCount = SQL_FetchInt(results, 4);
    int updatedAt = SQL_FetchInt(results, 5);
    char source[32];
    SQL_FetchString(results, 6, source, sizeof(source));
    if (source[0] == '\0')
        strcopy(source, sizeof(source), "daily");

    if (sampleCount <= 0 || updatedAt <= 0 || ppmNormal <= 0.0 || ppmHard < ppmNormal || ppmExpert < ppmHard || ppmExtreme < ppmExpert)
    {
        LogError("[AnneHappyAI] invalid threshold row: sample=%d updated=%d p60=%.2f p75=%.2f p90=%.2f p95=%.2f",
            sampleCount, updatedAt, ppmNormal, ppmHard, ppmExpert, ppmExtreme);
        return;
    }

    g_fDbLevel2PPM = ppmNormal;
    g_fDbLevel3PPM = ppmHard;
    g_fDbLevel4PPM = ppmExpert;
    g_fDbLevel5PPM = ppmExtreme;
    g_iDbThresholdSampleCount = sampleCount;
    g_iDbThresholdUpdatedAt = updatedAt;
    strcopy(g_sDbThresholdSource, sizeof(g_sDbThresholdSource), source);
    g_bDbThresholdReady = true;

    if (g_cvDebug.BoolValue)
    {
        LogMessage("[AnneHappyAI] loaded db thresholds source=%s sample=%d updated=%d p60=%.2f p75=%.2f p90=%.2f p95=%.2f",
            g_sDbThresholdSource, g_iDbThresholdSampleCount, g_iDbThresholdUpdatedAt,
            g_fDbLevel2PPM, g_fDbLevel3PPM, g_fDbLevel4PPM, g_fDbLevel5PPM);
    }
}

void GetLevelName(int level, char[] buffer, int maxlen)
{
    if (level <= 0)
    {
        strcopy(buffer, maxlen, "未定档");
        return;
    }

    switch (ClampLevel(level))
    {
        case 1:
        {
            strcopy(buffer, maxlen, "简单");
        }
        case 2:
        {
            strcopy(buffer, maxlen, "普通");
        }
        case 3:
        {
            strcopy(buffer, maxlen, "困难");
        }
        case 4:
        {
            strcopy(buffer, maxlen, "专家");
        }
        default:
        {
            strcopy(buffer, maxlen, "极限");
        }
    }
}

void ApplyDifficulty(int level, bool force, float ppm = 0.0, int score = 0, int minutes = 0, int players = 0, int quarterPlayers = 0, int fallbackPlayers = 0)
{
    level = ClampLevel(level);
    if (!force && level == g_iCurrentLevel)
        return;

    g_iCurrentLevel = level;

    ApplyProfileCvars(level);

    if (g_cvAnnounce.BoolValue && !force)
    {
        char levelName[16];
        GetLevelName(level, levelName, sizeof(levelName));
        PrintToChatAll("\x04[AnneHappyAI]\x01 l4d_stats PPM %.2f，%d人积分 %d / %d分钟（季度%d人/总榜回退%d人），动态难度调整为 \x03%s\x01。", ppm, players, score, minutes, quarterPlayers, fallbackPlayers, levelName);
    }
}

int ClampLevel(int level)
{
    if (level < 1)
        return 1;
    if (level > 5)
        return 5;
    return level;
}

void BuildDifficultyConfigPath(char[] path, int maxlen)
{
    char relativePath[PLATFORM_MAX_PATH];
    g_cvConfigPath.GetString(relativePath, sizeof(relativePath));
    TrimString(relativePath);

    if (relativePath[0] == '\0')
        strcopy(relativePath, sizeof(relativePath), DEFAULT_CONFIG_PATH);

    BuildPath(Path_SM, path, maxlen, "%s", relativePath);
}

bool ApplyConfigCvar(const char[] name, const char[] value)
{
    ConVar cvar = FindConVar(name);
    if (cvar == null)
    {
        if (g_cvDebug.BoolValue)
            LogMessage("[AnneHappyAI] config cvar not found: %s", name);

        return false;
    }

    cvar.SetString(value, true, false);
    return true;
}

int ApplyProfileCvars(int level)
{
    char path[PLATFORM_MAX_PATH];
    BuildDifficultyConfigPath(path, sizeof(path));

    KeyValues kv = new KeyValues("AnneHappyDynamicAIDifficulty");
    if (!kv.ImportFromFile(path))
    {
        LogError("[AnneHappyAI] Failed to read difficulty config: %s", path);
        delete kv;
        return 0;
    }

    char levelKey[16];
    FormatEx(levelKey, sizeof(levelKey), "level%d", ClampLevel(level));
    if (!kv.JumpToKey(levelKey))
    {
        LogError("[AnneHappyAI] Missing section \"%s\" in difficulty config: %s", levelKey, path);
        delete kv;
        return 0;
    }

    int applied = 0;
    if (kv.GotoFirstSubKey(false))
    {
        do
        {
            char cvarName[64];
            char value[128];
            kv.GetSectionName(cvarName, sizeof(cvarName));
            kv.GetString(NULL_STRING, value, sizeof(value), "");

            if (cvarName[0] == '\0' || value[0] == '\0')
                continue;

            if (ApplyConfigCvar(cvarName, value))
                applied++;
        }
        while (kv.GotoNextKey(false));
    }

    delete kv;

    if (applied <= 0)
        LogError("[AnneHappyAI] No cvars applied from section \"%s\" in config: %s", levelKey, path);

    return applied;
}
