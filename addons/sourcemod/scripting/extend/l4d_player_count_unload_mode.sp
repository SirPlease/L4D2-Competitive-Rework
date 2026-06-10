/**
 * End-user License Agreements
 * Half-Year warranty since deal, fix any bug for free
 * 
 * If Distribute, copy or share this code without permission, will void the warranty and we will not support anymore 
 * 
 * You can install on server and use the function of this plugin to receive sponsorships
 * 
 * You are free to modify source code for your convenience, but this will void the warranty. 
 * In case of bugs or malfunctions resulting from such modifications, we will not be responsible.
 * 
 * Once you receive this sp file, you are deemed to have agreed, understood and applied to the content above.
 * 
 * -----------------------------------------------------------------------------
 * 終端使用者授權合約
 * 以交易日期計算只有半年保固期，半年內插件有問題或者出現bug或者有優化可以免費更新修復到好
 * 
 * 未經同意，隨意散播發布、複製、分享這個插件與這個插件的代碼，將失去保固期並不再提供支援
 * 
 * 你可以使用、安裝到伺服器上、用此插件的功能營利或獲得贊助
 * 
 * 你可以修改源碼，以利於自己能方便使用，但這將導致保固期失效；出現Bug或不能正常使用的情況，後果自行承擔
 * 
 * 一旦拿到此插件源碼即視為您對該內容已認同、了解及適用
 * 
 * -----------------------------------------------------------------------------
 * 终端使用者授权合约
 * 以交易日期计算只有半年保固期，半年内插件有问题或者出现bug或者有优化可以免费更新修复到好
 * 
 * 未经同意，随意散播发布、复制、分享这个插件与这个插件的代码，将失去保固期并不再提供支援
 * 
 * 你可以使用、安装到伺服器上、用此插件的功能营利或获得赞助
 * 
 * 你可以修改源码，以利于自己能方便使用，但这将导致保固期失效；出现Bug或不能正常使用的情况，后果自行承担
 * 
 * 一旦拿到此插件源码即视为您对该内容已认同、了解及适用
 */

/**
 * 好服务器始终保留给多人模式；高峰期时普通服务器也不开放单人模式。
 * 管理员在场时不强制卸载模式。
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>      // https://github.com/fbef0102/L4D1_2-Plugins/releases

#define PLUGIN_VERSION			"1.1.0-2026/06/10"
#define PLUGIN_NAME			    "l4d_player_count_unload_mode"
#define DEBUG 0

public Plugin myinfo =
{
	name = "[L4D2 - ZM環境] 人數不夠卸載模式",
	author = "HarryPotter",
	description = "This is custom plugin",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/profiles/76561198026784913/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion test = GetEngineVersion();

    if( test != Engine_Left4Dead2 )
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3
#define PEAK_STATE_TABLE    "l4d_peak_state"

enum ERestrictionReason
{
    RestrictionReason_None = 0,
    RestrictionReason_GoodServerReserved,
    RestrictionReason_PeakNormalSingle,
    RestrictionReason_TimeRestricted
}

ConVar survivor_limit, z_max_player_zombies;
int g_iCvarSurvivorLimit, g_iCvarInfectedMax;

ConVar g_hCvarEnable, g_hCvarTime, g_hCvarCount, g_hCvarFlag, g_hCvarDelay;
ConVar g_hCvarPeakMode, g_hCvarPeakRatio, g_hCvarPeakHoldTime, g_hCvarDBConfig, g_hCvarServerId, g_hCvarServerIp, g_hCvarServerPort, g_hCvarStatusTable, g_hCvarStatusInterval, g_hCvarStatusMaxAge;
// 服务器本地相对 UTC 的偏移（分钟）。优先用 %z，失败时回退到可配置的 ConVar。
ConVar g_hTzServerOffset; // 可选：回退用（例如老 Windows 不支持 %z）
bool g_bCvarEnable;
int g_iCvarCount, g_iCvarPeakMode, g_iCvarPeakHoldTime, g_iCvarServerPort, g_iCvarStatusMaxAge;
float g_fCvarDelay, g_fCvarPeakRatio, g_fCvarStatusInterval;
char g_sCvarime[128], g_sCvarFlag[AdminFlags_TOTAL], g_sCvarDBConfig[64], g_sCvarServerId[128], g_sCvarServerIp[64], g_sCvarStatusTable[64];

enum struct ETimeData
{
    char m_sTime[12];
    int m_iCvarStartHour;
    int m_iCvarStartMin;
    int m_iCvarEndHour;
    int m_iCvarEndMin;
}

ArrayList g_aTimeList;

int 
    g_iRoundStart, 
    g_iPlayerSpawn,
    g_iRoundCounter;

bool 
    g_bPluginStart;

Handle
    g_hDetectTimer,
    g_hStatusTimer;

Database g_hDB;
bool g_bDBReady, g_bPeakQueryPending, g_bLastPeakActive, g_bLastGoodServer, g_bIsMySQL;
bool g_bAutoServerId;
int g_iLastActiveServers, g_iLastTotalServers;
int g_iLastStatusWriteTime, g_iLastStatusPlayerCount = -1;
int g_iPeakHoldUntil;

public void OnPluginStart()
{
	LoadTranslations("l4d_player_count_unload_mode.phrases");
    survivor_limit = FindConVar("survivor_limit");
    z_max_player_zombies = FindConVar("z_max_player_zombies");

    g_hCvarEnable 		= CreateConVar( PLUGIN_NAME ... "_enable",        "1",              "0=Plugin off, 1=Plugin on.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvarTime 		= CreateConVar(	PLUGIN_NAME ... "_time", 		  "18:00~22:59",    "檢測的時間段, 寫法xx:xx~xx:xx (二十四小時制), 寫多時間段請用逗號區隔", CVAR_FLAGS);
    g_hCvarCount        = CreateConVar(	PLUGIN_NAME ... "_count", 		  "3",              "檢測 survivor_limit + infected 空位 <= 此數值之時，強制執行sm_resetmatch, 卸載模式", CVAR_FLAGS, true, 1.0, true, 32.0);
    g_hCvarFlag         = CreateConVar(	PLUGIN_NAME ... "_flag", 		  "b",              "有這權限的管理員在場就不會被強制卸載模式", CVAR_FLAGS);
    g_hCvarDelay        = CreateConVar(	PLUGIN_NAME ... "_delay", 		  "60.0",           "地圖載入此秒數後才會檢測時間與人數", CVAR_FLAGS, true, 0.0);
    g_hCvarPeakMode     = CreateConVar( PLUGIN_NAME ... "_peak_mode",     "1",              "高峰期判定方式: 0=按_time時間段, 1=共享数据库统计所有服务器有玩家比例", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvarPeakRatio    = CreateConVar( PLUGIN_NAME ... "_peak_ratio",    "0.70",           "peak_mode=1 时，有玩家服务器数/有效服务器数 >= 此比例即视为高峰期", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvarPeakHoldTime = CreateConVar( PLUGIN_NAME ... "_peak_hold_time", "3600",          "peak_mode=1 时，一旦进入高峰期后至少持续限制多少秒；0=不保持", CVAR_FLAGS, true, 0.0);
    g_hCvarDBConfig     = CreateConVar( PLUGIN_NAME ... "_db_config",     "l4dstats",        "peak_mode=1 使用的 databases.cfg 区块名", CVAR_FLAGS);
    g_hCvarServerId     = CreateConVar( PLUGIN_NAME ... "_server_id",     "",               "本服务器唯一ID；留空时优先从hostname提取前缀#编号，如Anne云服#21，失败则使用hostname:hostport", CVAR_FLAGS);
    g_hCvarServerIp     = CreateConVar( PLUGIN_NAME ... "_server_ip",     "",               "写入网页状态表的服务器公网IP/域名；可填host或host:port；留空时自动读取net_public_adr/ip/hostip", CVAR_FLAGS);
    g_hCvarServerPort   = CreateConVar( PLUGIN_NAME ... "_server_port",   "0",              "写入网页状态表的服务器外网端口；0=自动读取hostport/port；server_ip填host:port时优先使用其中端口", CVAR_FLAGS, true, 0.0, true, 65535.0);
    g_hCvarStatusTable  = CreateConVar( PLUGIN_NAME ... "_status_table",  "l4d_server_status", "peak_mode=1 使用的服务器状态表名", CVAR_FLAGS);
    g_hCvarStatusInterval = CreateConVar(PLUGIN_NAME ... "_status_interval", "180.0",       "peak_mode=1 本服人数写入数据库的心跳间隔秒数；人数变化时会尽快写入", CVAR_FLAGS, true, 5.0);
    g_hCvarStatusMaxAge = CreateConVar( PLUGIN_NAME ... "_status_max_age", "540",           "peak_mode=1 查询全服状态时，只统计多少秒内更新过的服务器，建议为status_interval的3倍", CVAR_FLAGS, true, 10.0);
    CreateConVar(                       PLUGIN_NAME ... "_version",       PLUGIN_VERSION, PLUGIN_NAME ... " Plugin Version", CVAR_FLAGS_PLUGIN_VERSION);
    g_hTzServerOffset = CreateConVar(PLUGIN_NAME ... "_server_utc_offset", "480",
        "Fallback: server's UTC offset in minutes (only used if %z unsupported).");
    //AutoExecConfig(true,                PLUGIN_NAME);

    GetCvars();
    GetTimeCvars();
    survivor_limit.AddChangeHook(ConVarChanged_Cvars);
    z_max_player_zombies.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarTime.AddChangeHook(ConVarChanged_TimeCvars);
    g_hCvarCount.AddChangeHook(ConVarChanged_TimeCvars);
    g_hCvarFlag.AddChangeHook(ConVarChanged_TimeCvars);
    g_hCvarDelay.AddChangeHook(ConVarChanged_TimeCvars);
    g_hCvarPeakMode.AddChangeHook(ConVarChanged_PeakCvars);
    g_hCvarPeakRatio.AddChangeHook(ConVarChanged_PeakCvars);
    g_hCvarPeakHoldTime.AddChangeHook(ConVarChanged_PeakCvars);
    g_hCvarDBConfig.AddChangeHook(ConVarChanged_PeakCvars);
    g_hCvarServerId.AddChangeHook(ConVarChanged_PeakCvars);
    g_hCvarServerIp.AddChangeHook(ConVarChanged_PeakCvars);
    g_hCvarServerPort.AddChangeHook(ConVarChanged_PeakCvars);
    g_hCvarStatusTable.AddChangeHook(ConVarChanged_PeakCvars);
    g_hCvarStatusInterval.AddChangeHook(ConVarChanged_PeakCvars);
    g_hCvarStatusMaxAge.AddChangeHook(ConVarChanged_PeakCvars);

    HookEvent("round_start",            Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_spawn",           Event_PlayerSpawn);
    HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy); //trigger twice in versus/survival/scavenge mode, one when all survivors wipe out or make it to saferom, one when first round ends (second round_start begins).
    HookEvent("map_transition", 		Event_RoundEnd,		EventHookMode_PostNoCopy); //1. all survivors make it to saferoom in and server is about to change next level in coop mode (does not trigger round_end), 2. all survivors make it to saferoom in versus
    HookEvent("mission_lost", 			Event_RoundEnd,		EventHookMode_PostNoCopy); //all survivors wipe out in coop mode (also triggers round_end)
    HookEvent("finale_vehicle_leaving", Event_RoundEnd,		EventHookMode_PostNoCopy); //final map final rescue vehicle leaving  (does not trigger round_end)

    HookEvent("player_team",            Event_PlayerTeam);

    RegAdminCmd("sm_peakstatus", Cmd_PeakStatus, ADMFLAG_GENERIC, "查看当前全服高峰期判定状态");

    SetupPeakDatabase();
    RestartStatusTimer();
}

// Cvars-------------------------------

void ConVarChanged_Cvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void ConVarChanged_TimeCvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
    GetCvars();
    GetTimeCvars();
}

void ConVarChanged_PeakCvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
    GetCvars();
    SetupPeakDatabase();
    RestartStatusTimer();
}

void GetCvars()
{
    g_iCvarSurvivorLimit = survivor_limit.IntValue;
    g_iCvarInfectedMax = z_max_player_zombies.IntValue;

    g_bCvarEnable = g_hCvarEnable.BoolValue;
    g_hCvarTime.GetString(g_sCvarime, sizeof(g_sCvarime));
    g_iCvarCount = g_hCvarCount.IntValue;
    g_hCvarFlag.GetString(g_sCvarFlag, sizeof(g_sCvarFlag));
    g_fCvarDelay = g_hCvarDelay.FloatValue;
    g_iCvarPeakMode = g_hCvarPeakMode.IntValue;
    g_fCvarPeakRatio = g_hCvarPeakRatio.FloatValue;
    g_iCvarPeakHoldTime = g_hCvarPeakHoldTime.IntValue;
    g_hCvarDBConfig.GetString(g_sCvarDBConfig, sizeof(g_sCvarDBConfig));
    g_hCvarServerId.GetString(g_sCvarServerId, sizeof(g_sCvarServerId));
    g_hCvarServerIp.GetString(g_sCvarServerIp, sizeof(g_sCvarServerIp));
    g_iCvarServerPort = g_hCvarServerPort.IntValue;
    g_hCvarStatusTable.GetString(g_sCvarStatusTable, sizeof(g_sCvarStatusTable));
    g_fCvarStatusInterval = g_hCvarStatusInterval.FloatValue;
    g_iCvarStatusMaxAge = g_hCvarStatusMaxAge.IntValue;

    TrimString(g_sCvarServerId);
    TrimString(g_sCvarServerIp);
    if (g_iCvarServerPort < 0 || g_iCvarServerPort > 65535)
        g_iCvarServerPort = 0;
    TrimString(g_sCvarStatusTable);
    if (g_sCvarStatusTable[0] == '\0' || !IsSafeSQLIdentifier(g_sCvarStatusTable))
    {
        strcopy(g_sCvarStatusTable, sizeof(g_sCvarStatusTable), "l4d_server_status");
    }

    if (g_sCvarServerId[0] == '\0')
    {
        g_bAutoServerId = true;
        BuildDefaultServerId(g_sCvarServerId, sizeof(g_sCvarServerId));
    }
    else
    {
        char sIndexedServerId[128];
        if (TryBuildIndexedHostnameId(g_sCvarServerId, sIndexedServerId, sizeof(sIndexedServerId)))
            strcopy(g_sCvarServerId, sizeof(g_sCvarServerId), sIndexedServerId);

        g_bAutoServerId = false;
    }
}

void GetTimeCvars()
{
    delete g_aTimeList;
    g_aTimeList = new ArrayList(sizeof(ETimeData));

    char sCvarimeCopy[128], sTime[12];
    FormatEx(sCvarimeCopy, sizeof(sCvarimeCopy), "%s", g_sCvarime);
    int index = SplitString(sCvarimeCopy, ",", sTime, sizeof(sTime));
    if(index >= 0)
    {
        do
        {
            //LogError("Time: %s, index: %d", sTime, index);
            ETimeData eTimeData;
            ConvertStringTimeToInt(sTime, eTimeData);
            g_aTimeList.PushArray(eTimeData);

            FormatEx(sCvarimeCopy, sizeof(sCvarimeCopy), "%s", sCvarimeCopy[index]);
            index = SplitString(sCvarimeCopy, ",", sTime, sizeof(sTime));
        }
        while(index != -1);
    }

    //LogError("last Time: %s", sCvarimeCopy);
    ETimeData eTimeData;
    ConvertStringTimeToInt(sCvarimeCopy, eTimeData);
    g_aTimeList.PushArray(eTimeData);
}

// Sourcemod API Forward-------------------------------

public void OnMapStart()
{
    g_iRoundCounter = 1;
}

public void OnMapEnd()
{
    ClearDefault();
    ResetTimer();

    g_bPluginStart = false;
}

public void OnPluginEnd()
{
    delete g_hStatusTimer;
    delete g_hDB;
}

// Event-------------------------------

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
    if( g_iRoundCounter != 1) return;
    g_iRoundCounter++;

    if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
        CreateTimer(0.5, Timer_PluginStart, _, TIMER_FLAG_NO_MAPCHANGE);
    g_iRoundStart = 1;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{ 
    if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
        CreateTimer(0.5, Timer_PluginStart, _, TIMER_FLAG_NO_MAPCHANGE);
    g_iPlayerSpawn = 1;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
    ClearDefault();
    ResetTimer();          // ← 必须停掉
    g_bPluginStart = false; // ← 暂停检测，等下个回合再启动
}


void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
    if (g_iCvarPeakMode == 1)
        CreateTimer(1.0, Timer_UpdateServerStatus, _, TIMER_FLAG_NO_MAPCHANGE);

    if(!g_bCvarEnable || !g_bPluginStart || g_hDetectTimer != null) return;

    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);
    if (client && IsClientInGame(client) && !IsFakeClient(client))
    {
        delete g_hDetectTimer; 
        g_hDetectTimer = CreateTimer(1.0, Timer_DetectPlayerCount);
    }
}

Action Cmd_PeakStatus(int client, int args)
{
    if (g_iCvarPeakMode == 0)
    {
        if (IsInConfiguredTime())
            ReplyToCommand(client, "[Peak] 当前使用时间段判定模式。现在在限制时间段内。");
        else
            ReplyToCommand(client, "[Peak] 当前使用时间段判定模式。现在不在限制时间段内。");
        return Plugin_Handled;
    }

    if (!g_bDBReady || g_hDB == null)
    {
        ReplyToCommand(client, "[Peak] 数据库尚未连接完成，暂时无法查询全服高峰期状态。");
        return Plugin_Handled;
    }

    int userid = (client > 0) ? GetClientUserId(client) : -1;
    QueryPeakState(userid);
    ReplyToCommand(client, "[Peak] 正在查询全服高峰期状态...");

    return Plugin_Handled;
}

// Timer & Frame-------------------------------

Action Timer_PluginStart(Handle timer)
{
    ClearDefault();

    delete g_hDetectTimer; 
    g_hDetectTimer = CreateTimer(g_fCvarDelay, Timer_DetectPlayerCount);

    g_bPluginStart = true;

    return Plugin_Continue;
}

Action Timer_DetectPlayerCount(Handle timer)
{
    g_hDetectTimer = null;

    if (!g_bCvarEnable)
        return Plugin_Continue;

    if (!ShouldCheckCurrentMode())
        return Plugin_Continue;

    if (g_iCvarPeakMode == 1)
    {
        QueryPeakState(0);
        return Plugin_Continue;
    }

    if (IsInConfiguredTime())
        ApplyRestriction(RestrictionReason_TimeRestricted);

    return Plugin_Continue;
}

bool IsInConfiguredTime()
{
    bool bIsInCvarTime = false;
    ETimeData eTimeData;

    // —— 关键：先把当前时间戳换算到上海时区，再格式化出小时/分钟 ——
    char sSystemTimeHour[4], sSystemTimeMin[4];
    int iSystemTimeHour, iSystemTimeMin;

    int stampCN = ToShanghaiStamp(GetTime());
    FormatTime(sSystemTimeHour, sizeof(sSystemTimeHour), "%H", stampCN);
    FormatTime(sSystemTimeMin,  sizeof(sSystemTimeMin),  "%M", stampCN);

    iSystemTimeHour = StringToInt(sSystemTimeHour);
    iSystemTimeMin  = StringToInt(sSystemTimeMin);

    for (int i = 0; i < g_aTimeList.Length; i++)
    {
        g_aTimeList.GetArray(i, eTimeData);
        if (IsBetweenTime(iSystemTimeHour, iSystemTimeMin, eTimeData))
        {
            bIsInCvarTime = true;
            break;
        }
    }

    return bIsInCvarTime;
}

void ApplyRestriction(ERestrictionReason reason)
{
    if (IsAnyAdminOnline())
        return;

    ServerCommand("sm_resetmatch");
    int iModeSlots = GetModePlayerSlots();
    int iMultiMin = g_iCvarCount + 1;

    switch (reason)
    {
        case RestrictionReason_GoodServerReserved:
        {
            CPrintToChatAll("%t", "L4DPlayerCountUnloadMode_GoodServerReserved", iMultiMin, iModeSlots);
        }
        case RestrictionReason_PeakNormalSingle:
        {
            int iRemain = GetPeakHoldRemaining();
            CPrintToChatAll("%t", "L4DPlayerCountUnloadMode_PeakNormalSingle", g_iLastActiveServers, g_iLastTotalServers, g_fCvarPeakRatio * 100.0, RoundToCeil(float(iRemain) / 60.0), iModeSlots);
        }
        default:
        {
            CPrintToChatAll("%t", "L4DPlayerCountUnloadMode_TimeRestricted", iMultiMin, iModeSlots);
        }
    }
}

void SetupPeakDatabase()
{
    if (g_iCvarPeakMode != 1)
        return;

    g_bDBReady = false;
    g_bPeakQueryPending = false;
    g_bLastGoodServer = false;
    g_iLastActiveServers = 0;
    g_iLastTotalServers = 0;
    g_iLastStatusWriteTime = 0;
    g_iLastStatusPlayerCount = -1;
    g_iPeakHoldUntil = 0;

    delete g_hDB;
    SQL_TConnect(SQLCB_OnConnect, g_sCvarDBConfig, 0);
}

public void SQLCB_OnConnect(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null)
    {
        LogError("[%s] DB connect failed: %s", PLUGIN_NAME, error);
        return;
    }

    g_hDB = view_as<Database>(hndl);

    char sDriver[32];
    if (!SQL_GetDriverIdent(owner, sDriver, sizeof(sDriver)))
    {
        LogError("[%s] Failed to get DB driver ident", PLUGIN_NAME);
        return;
    }
    g_bIsMySQL = StrEqual(sDriver, "mysql", false);

    if (g_bIsMySQL)
    {
        if (!SQL_SetCharset(g_hDB, "utf8mb4"))
        {
            LogError("[%s] SQL_SetCharset utf8mb4 failed", PLUGIN_NAME);
        }
    }

    CreateStatusTable();
}

void CreateStatusTable()
{
    char sQuery[1024];
    if (g_bIsMySQL)
    {
        FormatEx(sQuery, sizeof(sQuery),
            "CREATE TABLE IF NOT EXISTS `%s` ( \
                `address_key` VARCHAR(160) NOT NULL, \
                `server_id` VARCHAR(128) NOT NULL, \
                `hostname` VARCHAR(128) NOT NULL DEFAULT '', \
                `ip` VARCHAR(64) NOT NULL DEFAULT '', \
                `port` INT NOT NULL DEFAULT 0, \
                `players` INT NOT NULL DEFAULT 0, \
                `updated_at` INT NOT NULL DEFAULT 0, \
                `enabled` TINYINT NOT NULL DEFAULT 1, \
                `is_good_server` TINYINT NOT NULL DEFAULT 0, \
                PRIMARY KEY (`address_key`), \
                KEY `server_id` (`server_id`), \
                KEY `updated_at` (`updated_at`) \
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4",
            g_sCvarStatusTable);
    }
    else
    {
        FormatEx(sQuery, sizeof(sQuery),
            "CREATE TABLE IF NOT EXISTS `%s` ( \
                `address_key` TEXT NOT NULL PRIMARY KEY, \
                `server_id` TEXT NOT NULL DEFAULT '', \
                `hostname` TEXT NOT NULL DEFAULT '', \
                `ip` TEXT NOT NULL DEFAULT '', \
                `port` INTEGER NOT NULL DEFAULT 0, \
                `players` INTEGER NOT NULL DEFAULT 0, \
                `updated_at` INTEGER NOT NULL DEFAULT 0, \
                `enabled` INTEGER NOT NULL DEFAULT 1, \
                `is_good_server` INTEGER NOT NULL DEFAULT 0 \
            )",
            g_sCvarStatusTable);
    }

    SQL_TQuery(g_hDB, SQLCB_CreateStatusTable, sQuery);
}

public void SQLCB_CreateStatusTable(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null && error[0] != '\0')
    {
        LogError("[%s] Create status table failed: %s", PLUGIN_NAME, error);
        return;
    }

    EnsureStatusAddressKeyColumn();
}

bool IsIgnorableSchemaError(const char[] error)
{
    return error[0] == '\0'
        || StrContains(error, "Duplicate column", false) != -1
        || StrContains(error, "duplicate column", false) != -1
        || StrContains(error, "Duplicate key name", false) != -1
        || StrContains(error, "duplicate key name", false) != -1
        || StrContains(error, "Multiple primary key", false) != -1
        || StrContains(error, "multiple primary key", false) != -1;
}

void EnsureStatusAddressKeyColumn()
{
    char sQuery[512];
    if (g_bIsMySQL)
    {
        FormatEx(sQuery, sizeof(sQuery),
            "ALTER TABLE `%s` ADD COLUMN `address_key` VARCHAR(160) NOT NULL DEFAULT '' FIRST",
            g_sCvarStatusTable);
    }
    else
    {
        FormatEx(sQuery, sizeof(sQuery),
            "ALTER TABLE `%s` ADD COLUMN `address_key` TEXT NOT NULL DEFAULT ''",
            g_sCvarStatusTable);
    }

    SQL_TQuery(g_hDB, SQLCB_EnsureStatusAddressKeyColumn, sQuery);
}

public void SQLCB_EnsureStatusAddressKeyColumn(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null && !IsIgnorableSchemaError(error))
    {
        LogError("[%s] Add status address_key column failed: %s", PLUGIN_NAME, error);
    }

    EnsureStatusIpColumn();
}

void EnsureStatusIpColumn()
{
    char sQuery[512];
    if (g_bIsMySQL)
    {
        FormatEx(sQuery, sizeof(sQuery),
            "ALTER TABLE `%s` ADD COLUMN `ip` VARCHAR(64) NOT NULL DEFAULT '' AFTER `hostname`",
            g_sCvarStatusTable);
    }
    else
    {
        FormatEx(sQuery, sizeof(sQuery),
            "ALTER TABLE `%s` ADD COLUMN `ip` TEXT NOT NULL DEFAULT ''",
            g_sCvarStatusTable);
    }

    SQL_TQuery(g_hDB, SQLCB_EnsureStatusIpColumn, sQuery);
}

public void SQLCB_EnsureStatusIpColumn(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null && !IsIgnorableSchemaError(error))
    {
        LogError("[%s] Add status ip column failed: %s", PLUGIN_NAME, error);
    }

    EnsureStatusPortColumn();
}

void EnsureStatusPortColumn()
{
    char sQuery[512];
    if (g_bIsMySQL)
    {
        FormatEx(sQuery, sizeof(sQuery),
            "ALTER TABLE `%s` ADD COLUMN `port` INT NOT NULL DEFAULT 0 AFTER `ip`",
            g_sCvarStatusTable);
    }
    else
    {
        FormatEx(sQuery, sizeof(sQuery),
            "ALTER TABLE `%s` ADD COLUMN `port` INTEGER NOT NULL DEFAULT 0",
            g_sCvarStatusTable);
    }

    SQL_TQuery(g_hDB, SQLCB_EnsureStatusPortColumn, sQuery);
}

public void SQLCB_EnsureStatusPortColumn(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null && !IsIgnorableSchemaError(error))
    {
        LogError("[%s] Add status port column failed: %s", PLUGIN_NAME, error);
    }

    EnsureStatusGoodServerColumn();
}

void EnsureStatusGoodServerColumn()
{
    char sQuery[512];
    if (g_bIsMySQL)
    {
        FormatEx(sQuery, sizeof(sQuery),
            "ALTER TABLE `%s` ADD COLUMN `is_good_server` TINYINT NOT NULL DEFAULT 0 AFTER `enabled`",
            g_sCvarStatusTable);
    }
    else
    {
        FormatEx(sQuery, sizeof(sQuery),
            "ALTER TABLE `%s` ADD COLUMN `is_good_server` INTEGER NOT NULL DEFAULT 0",
            g_sCvarStatusTable);
    }

    SQL_TQuery(g_hDB, SQLCB_EnsureStatusGoodServerColumn, sQuery);
}

public void SQLCB_EnsureStatusGoodServerColumn(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null && !IsIgnorableSchemaError(error))
    {
        LogError("[%s] Add status good-server column failed: %s", PLUGIN_NAME, error);
    }

    MigrateStatusAddressKeys();
}

void MigrateStatusAddressKeys()
{
    char sQuery[512];
    FormatEx(sQuery, sizeof(sQuery),
        "UPDATE `%s` SET `address_key` = `server_id` WHERE `address_key` = '' OR `address_key` IS NULL",
        g_sCvarStatusTable);
    SQL_TQuery(g_hDB, SQLCB_MigrateStatusAddressKeys, sQuery);
}

public void SQLCB_MigrateStatusAddressKeys(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null && error[0] != '\0')
    {
        LogError("[%s] Migrate status address_key failed: %s", PLUGIN_NAME, error);
    }

    MigrateStatusPrimaryKey();
}

void MigrateStatusPrimaryKey()
{
    if (!g_bIsMySQL)
    {
        CreatePeakStateTable();
        return;
    }

    char sQuery[512];
    FormatEx(sQuery, sizeof(sQuery),
        "ALTER TABLE `%s` DROP PRIMARY KEY, ADD PRIMARY KEY (`address_key`)",
        g_sCvarStatusTable);
    SQL_TQuery(g_hDB, SQLCB_MigrateStatusPrimaryKey, sQuery);
}

public void SQLCB_MigrateStatusPrimaryKey(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null && error[0] != '\0'
        && StrContains(error, "Multiple primary key", false) == -1
        && StrContains(error, "multiple primary key", false) == -1)
    {
        LogError("[%s] Migrate status primary key failed: %s", PLUGIN_NAME, error);
    }

    EnsureStatusServerIdIndex();
}

void EnsureStatusServerIdIndex()
{
    if (!g_bIsMySQL)
    {
        CreatePeakStateTable();
        return;
    }

    char sQuery[512];
    FormatEx(sQuery, sizeof(sQuery),
        "ALTER TABLE `%s` ADD INDEX `server_id` (`server_id`)",
        g_sCvarStatusTable);
    SQL_TQuery(g_hDB, SQLCB_EnsureStatusServerIdIndex, sQuery);
}

public void SQLCB_EnsureStatusServerIdIndex(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null && !IsIgnorableSchemaError(error))
    {
        LogError("[%s] Add status server_id index failed: %s", PLUGIN_NAME, error);
    }

    CreatePeakStateTable();
}

void CreatePeakStateTable()
{
    char sQuery[512];
    if (g_bIsMySQL)
    {
        FormatEx(sQuery, sizeof(sQuery),
            "CREATE TABLE IF NOT EXISTS `%s` ( \
                `state_key` VARCHAR(64) NOT NULL, \
                `hold_until` INT NOT NULL DEFAULT 0, \
                `updated_at` INT NOT NULL DEFAULT 0, \
                PRIMARY KEY (`state_key`) \
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4",
            PEAK_STATE_TABLE);
    }
    else
    {
        FormatEx(sQuery, sizeof(sQuery),
            "CREATE TABLE IF NOT EXISTS `%s` ( \
                `state_key` TEXT NOT NULL PRIMARY KEY, \
                `hold_until` INTEGER NOT NULL DEFAULT 0, \
                `updated_at` INTEGER NOT NULL DEFAULT 0 \
            )",
            PEAK_STATE_TABLE);
    }

    SQL_TQuery(g_hDB, SQLCB_CreatePeakStateTable, sQuery);
}

public void SQLCB_CreatePeakStateTable(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null && error[0] != '\0')
    {
        LogError("[%s] Create peak state table failed: %s", PLUGIN_NAME, error);
        return;
    }

    CleanupLegacyStatusRows();

    g_bDBReady = true;
    UpdateServerStatus(true);
}

void CleanupLegacyStatusRows()
{
    if (!g_bIsMySQL)
        return;

    char sQuery[256];
    FormatEx(sQuery, sizeof(sQuery),
        "DELETE FROM `%s` WHERE (`address_key` = '' OR `address_key` IS NULL) AND `server_id` COLLATE utf8mb4_bin NOT REGEXP '^Anne云服#[0-9]+$'",
        g_sCvarStatusTable);
    SQL_TQuery(g_hDB, SQLCB_Generic, sQuery);
}

void RestartStatusTimer()
{
    delete g_hStatusTimer;

    if (g_iCvarPeakMode != 1)
        return;

    g_hStatusTimer = CreateTimer(g_fCvarStatusInterval, Timer_UpdateServerStatus, _, TIMER_REPEAT);
}

Action Timer_UpdateServerStatus(Handle timer)
{
    UpdateServerStatus();
    return Plugin_Continue;
}

void UpdateServerStatus(bool bForce = false)
{
    if (g_iCvarPeakMode != 1 || !g_bDBReady || g_hDB == null)
        return;

    int iNow = GetTime();
    int iPlayers = GetHumanPlayerCount();
    int iMinChangedInterval = 5;
    int iHeartbeatInterval = RoundToFloor(g_fCvarStatusInterval);

    if (!bForce)
    {
        if (iPlayers == g_iLastStatusPlayerCount && iNow - g_iLastStatusWriteTime < iHeartbeatInterval)
            return;

        if (iPlayers != g_iLastStatusPlayerCount && iNow - g_iLastStatusWriteTime < iMinChangedInterval)
            return;
    }

    char sServerId[256], sHostname[256], sServerIp[64], sAddressKey[192];
    char sEscServerId[512], sEscHostname[512], sEscServerIp[128], sEscAddressKey[384];
    ConVar hHostname = FindConVar("hostname");
    if (hHostname != null)
        hHostname.GetString(sHostname, sizeof(sHostname));
    else
        strcopy(sHostname, sizeof(sHostname), "server");

    if (!BuildCurrentServerId(sHostname, sServerId, sizeof(sServerId)))
        return;

    int iPort;
    if (!BuildCurrentServerAddress(sServerIp, sizeof(sServerIp), iPort, sAddressKey, sizeof(sAddressKey)))
        return;

    SQL_EscapeString(g_hDB, sServerId, sEscServerId, sizeof(sEscServerId));
    SQL_EscapeString(g_hDB, sHostname, sEscHostname, sizeof(sEscHostname));
    SQL_EscapeString(g_hDB, sServerIp, sEscServerIp, sizeof(sEscServerIp));
    SQL_EscapeString(g_hDB, sAddressKey, sEscAddressKey, sizeof(sEscAddressKey));

    char sQuery[1536];
    if (g_bIsMySQL)
    {
        FormatEx(sQuery, sizeof(sQuery),
            "INSERT INTO `%s` (`address_key`, `server_id`, `hostname`, `ip`, `port`, `players`, `updated_at`, `enabled`) VALUES ('%s', '%s', '%s', '%s', %d, %d, UNIX_TIMESTAMP(), 1) \
             ON DUPLICATE KEY UPDATE `server_id` = VALUES(`server_id`), `hostname` = VALUES(`hostname`), `ip` = VALUES(`ip`), `port` = VALUES(`port`), `players` = VALUES(`players`), `updated_at` = VALUES(`updated_at`), `enabled` = VALUES(`enabled`)",
            g_sCvarStatusTable, sEscAddressKey, sEscServerId, sEscHostname, sEscServerIp, iPort, iPlayers);
        SQL_TQuery(g_hDB, SQLCB_Generic, sQuery);

        FormatEx(sQuery, sizeof(sQuery),
            "DELETE FROM `%s` WHERE `server_id` = '%s' AND `address_key` <> '%s' AND (`ip` = '' OR `port` = 0 OR `address_key` = `server_id`)",
            g_sCvarStatusTable, sEscServerId, sEscAddressKey);
        SQL_TQuery(g_hDB, SQLCB_Generic, sQuery);
    }
    else
    {
        FormatEx(sQuery, sizeof(sQuery),
            "INSERT OR IGNORE INTO `%s` (`address_key`, `server_id`, `hostname`, `ip`, `port`, `players`, `updated_at`, `enabled`) VALUES ('%s', '%s', '%s', '%s', %d, %d, strftime('%%s','now'), 1)",
            g_sCvarStatusTable, sEscAddressKey, sEscServerId, sEscHostname, sEscServerIp, iPort, iPlayers);
        SQL_TQuery(g_hDB, SQLCB_Generic, sQuery);

        FormatEx(sQuery, sizeof(sQuery),
            "UPDATE `%s` SET `server_id` = '%s', `hostname` = '%s', `ip` = '%s', `port` = %d, `players` = %d, `updated_at` = strftime('%%s','now'), `enabled` = 1 WHERE `address_key` = '%s'",
            g_sCvarStatusTable, sEscServerId, sEscHostname, sEscServerIp, iPort, iPlayers, sEscAddressKey);
        SQL_TQuery(g_hDB, SQLCB_Generic, sQuery);

        FormatEx(sQuery, sizeof(sQuery),
            "DELETE FROM `%s` WHERE `server_id` = '%s' AND `address_key` <> '%s' AND (`ip` = '' OR `port` = 0 OR `address_key` = `server_id`)",
            g_sCvarStatusTable, sEscServerId, sEscAddressKey);
        SQL_TQuery(g_hDB, SQLCB_Generic, sQuery);
    }

    g_iLastStatusWriteTime = iNow;
    g_iLastStatusPlayerCount = iPlayers;
}

void QueryPeakState(int iReplyUserid)
{
    if (g_iCvarPeakMode != 1)
        return;

    if (!g_bDBReady || g_hDB == null)
    {
        if (iReplyUserid != 0)
            ReplyPeakStatus(iReplyUserid, false, false);
        else
        {
            ERestrictionReason reason = GetRestrictionReason(g_bLastPeakActive, g_bLastGoodServer);
            if (reason != RestrictionReason_None)
                ApplyRestriction(reason);
        }
        return;
    }

    if (g_bPeakQueryPending && iReplyUserid == 0)
        return;

    UpdateServerStatus();
    if (iReplyUserid == 0)
        g_bPeakQueryPending = true;

    char sHostname[256], sServerId[256], sEscServerId[512];
    ConVar hHostname = FindConVar("hostname");
    if (hHostname != null)
        hHostname.GetString(sHostname, sizeof(sHostname));
    else
        strcopy(sHostname, sizeof(sHostname), "server");

    if (BuildCurrentServerId(sHostname, sServerId, sizeof(sServerId)))
        SQL_EscapeString(g_hDB, sServerId, sEscServerId, sizeof(sEscServerId));
    else
        sEscServerId[0] = '\0';

    char sQuery[1024];
    if (g_bIsMySQL)
    {
        FormatEx(sQuery, sizeof(sQuery),
            "SELECT SUM(CASE WHEN `players` > 0 THEN 1 ELSE 0 END), COUNT(*), COALESCE((SELECT `hold_until` FROM `%s` WHERE `state_key` = 'global' LIMIT 1), 0), COALESCE((SELECT MAX(`is_good_server`) FROM `%s` WHERE `server_id` = '%s'), 0) FROM `%s` WHERE `enabled` = 1 AND `updated_at` >= UNIX_TIMESTAMP() - %d",
            PEAK_STATE_TABLE, g_sCvarStatusTable, sEscServerId, g_sCvarStatusTable, g_iCvarStatusMaxAge);
    }
    else
    {
        FormatEx(sQuery, sizeof(sQuery),
            "SELECT SUM(CASE WHEN `players` > 0 THEN 1 ELSE 0 END), COUNT(*), COALESCE((SELECT `hold_until` FROM `%s` WHERE `state_key` = 'global' LIMIT 1), 0), COALESCE((SELECT MAX(`is_good_server`) FROM `%s` WHERE `server_id` = '%s'), 0) FROM `%s` WHERE `enabled` = 1 AND `updated_at` >= strftime('%%s','now') - %d",
            PEAK_STATE_TABLE, g_sCvarStatusTable, sEscServerId, g_sCvarStatusTable, g_iCvarStatusMaxAge);
    }

    SQL_TQuery(g_hDB, SQLCB_QueryPeakState, sQuery, iReplyUserid);
}

public void SQLCB_QueryPeakState(Handle owner, Handle hndl, const char[] error, any data)
{
    int iReplyUserid = data;
    if (iReplyUserid == 0)
        g_bPeakQueryPending = false;

    if (hndl == null)
    {
        LogError("[%s] Query peak state failed: %s", PLUGIN_NAME, error);
        if (iReplyUserid != 0)
            ReplyPeakStatus(iReplyUserid, false, false);
        return;
    }

    if (!SQL_FetchRow(hndl))
    {
        if (iReplyUserid != 0)
            ReplyPeakStatus(iReplyUserid, false, false);
        return;
    }

    int iActiveServers = SQL_FetchInt(hndl, 0);
    int iTotalServers = SQL_FetchInt(hndl, 1);
    int iGlobalHoldUntil = SQL_FetchInt(hndl, 2);
    bool bGoodServer = (SQL_FetchInt(hndl, 3) != 0);
    bool bRawPeak = false;

    g_iLastActiveServers = iActiveServers;
    g_iLastTotalServers = iTotalServers;
    g_bLastGoodServer = bGoodServer;

    if (iTotalServers > 0)
    {
        float fRatio = float(iActiveServers) / float(iTotalServers);
        bRawPeak = (fRatio >= g_fCvarPeakRatio);
    }

    int iNow = GetTime();
    if (bRawPeak)
    {
        g_iPeakHoldUntil = iNow + g_iCvarPeakHoldTime;
        SavePeakHoldUntil(g_iPeakHoldUntil);
    }
    else
    {
        g_iPeakHoldUntil = iGlobalHoldUntil;
    }

    bool bIsPeak = bRawPeak || (g_iPeakHoldUntil > iNow);

    g_bLastPeakActive = bIsPeak;

    if (iReplyUserid != 0)
        ReplyPeakStatus(iReplyUserid, true, bRawPeak);

    ERestrictionReason reason = GetRestrictionReason(bIsPeak, g_bLastGoodServer);
    if (!g_bCvarEnable || reason == RestrictionReason_None)
        return;

    ApplyRestriction(reason);
}

public void SQLCB_Generic(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null && error[0] != '\0')
    {
        LogError("[%s] SQL error: %s", PLUGIN_NAME, error);
    }
}

void SavePeakHoldUntil(int iHoldUntil)
{
    if (!g_bDBReady || g_hDB == null)
        return;

    char sQuery[512];
    if (g_bIsMySQL)
    {
        FormatEx(sQuery, sizeof(sQuery),
            "REPLACE INTO `%s` (`state_key`, `hold_until`, `updated_at`) VALUES ('global', %d, UNIX_TIMESTAMP())",
            PEAK_STATE_TABLE, iHoldUntil);
    }
    else
    {
        FormatEx(sQuery, sizeof(sQuery),
            "REPLACE INTO `%s` (`state_key`, `hold_until`, `updated_at`) VALUES ('global', %d, strftime('%%s','now'))",
            PEAK_STATE_TABLE, iHoldUntil);
    }

    SQL_TQuery(g_hDB, SQLCB_Generic, sQuery);
}

int GetPeakHoldRemaining()
{
    int iRemain = g_iPeakHoldUntil - GetTime();
    return (iRemain > 0) ? iRemain : 0;
}

void ReplyPeakStatus(int iReplyUserid, bool bQueryOk, bool bRawPeak)
{
    int client = 0;
    if (iReplyUserid > 0)
    {
        client = GetClientOfUserId(iReplyUserid);
        if (client == 0)
            return;
    }

    if (!bQueryOk)
    {
        ReplyToCommand(client, "[Peak] 查询失败或数据库未就绪，请查看 SourceMod error 日志。");
        return;
    }

    float fRatio = 0.0;
    if (g_iLastTotalServers > 0)
        fRatio = float(g_iLastActiveServers) / float(g_iLastTotalServers);

    int iRemain = GetPeakHoldRemaining();
    if (g_bLastPeakActive)
    {
        ReplyToCommand(client, "[Peak] 当前处于高峰期。全服有玩家服务器: %d/%d (%.1f%%)，阈值: %.0f%%，本轮锁定剩余: %d 分钟，实时占比%s达到阈值。本服好服务器: %s。规则：好服务器始终保留给%d人及以上模式；高峰期非好服务器也不开放单人模式；管理员在场免疫。",
            g_iLastActiveServers, g_iLastTotalServers, fRatio * 100.0, g_fCvarPeakRatio * 100.0, RoundToCeil(float(iRemain) / 60.0), bRawPeak ? "已" : "未", g_bLastGoodServer ? "是" : "否", g_iCvarCount + 1);
    }
    else
    {
        ReplyToCommand(client, "[Peak] 当前未进入高峰期。全服有玩家服务器: %d/%d (%.1f%%)，阈值: %.0f%%。本服好服务器: %s。规则：好服务器始终保留给%d人及以上模式；高峰期非好服务器也不开放单人模式；管理员在场免疫。",
            g_iLastActiveServers, g_iLastTotalServers, fRatio * 100.0, g_fCvarPeakRatio * 100.0, g_bLastGoodServer ? "是" : "否", g_iCvarCount + 1);
    }
}


bool IsAnyAdminOnline()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i)) continue;
        if (HasAccess(i, g_sCvarFlag)) return true;
    }
    return false;
}
// Function-------------------------------

void ConvertStringTimeToInt(char[] sTime, ETimeData eTimeData)
{
	static char sTwoTime[2][6], sStartTime[2][3], sEndTime[2][3];
	if(ExplodeString(sTime, "~", sTwoTime, 2, sizeof(sTwoTime[])) != 2)
	{
		LogError("Convar \"_time\" %s error", sTime);
		return;
	}

	if(ExplodeString(sTwoTime[0], ":", sStartTime, 2, sizeof(sStartTime[])) != 2)
	{
		LogError("Convar \"_time\" %s error", sTime);
		return;
	}

	eTimeData.m_iCvarStartHour = StringToInt(sStartTime[0]);
	eTimeData.m_iCvarStartMin = StringToInt(sStartTime[1]);

	if(ExplodeString(sTwoTime[1], ":", sEndTime, 2, sizeof(sEndTime[])) != 2)
	{
		LogError("Convar \"_time\" %s error", sTime);
		return;
	}

	eTimeData.m_iCvarEndHour = StringToInt(sEndTime[0]);
	eTimeData.m_iCvarEndMin = StringToInt(sEndTime[1]);
}

bool IsBetweenTime(int sysH, int sysM, ETimeData d)
{
    int sys  = sysH*60 + sysM;
    int beg  = d.m_iCvarStartHour*60 + d.m_iCvarStartMin;
    int end  = d.m_iCvarEndHour*60   + d.m_iCvarEndMin;

    if (beg == end) return true;                 // 覆盖整天
    if (beg < end)  return (sys >= beg && sys <= end);
    // 跨零点
    return (sys >= beg || sys <= end);
}

// Others-------------------------------

bool IsAnne()
{
    char plugin_name[256];
    ConVar cvar_mode = FindConVar("l4d_ready_cfg_name");
    if(cvar_mode == null) return false;
    cvar_mode.GetString(plugin_name, sizeof(plugin_name));

    if(StrContains(plugin_name, "AnneHappy", false) != -1 
        || StrContains(plugin_name, "AllCharger", false) != -1 
        || StrContains(plugin_name, "1vHunters", false) != -1 
        || StrContains(plugin_name, "WitchParty", false) != -1
        || StrContains(plugin_name, "Alone", false) != -1)
    {
        return true;
    }

    return false;
}

int GetInfectedSlots()
{
    if(IsAnne())
    {
        return 0;
    }
    else
    {
        return g_iCvarInfectedMax;
    }
}

int GetModePlayerSlots()
{
    return g_iCvarSurvivorLimit + GetInfectedSlots();
}

bool IsCurrentSinglePlayerMode()
{
    return g_iCvarSurvivorLimit <= 1 && GetInfectedSlots() == 0;
}

bool IsBelowMultiplayerMode()
{
    return GetModePlayerSlots() <= g_iCvarCount;
}

bool ShouldCheckCurrentMode()
{
    if (g_iCvarPeakMode == 1)
        return IsBelowMultiplayerMode() || IsCurrentSinglePlayerMode();

    return IsBelowMultiplayerMode();
}

ERestrictionReason GetRestrictionReason(bool bIsPeak, bool bGoodServer)
{
    if (bGoodServer && IsBelowMultiplayerMode())
        return RestrictionReason_GoodServerReserved;

    if (bIsPeak && !bGoodServer && IsCurrentSinglePlayerMode())
        return RestrictionReason_PeakNormalSingle;

    return RestrictionReason_None;
}

int GetHumanPlayerCount()
{
    int iCount = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
            iCount++;
    }

    return iCount;
}

void BuildDefaultServerId(char[] buffer, int maxlen)
{
    char sHostname[96];
    ConVar hHostname = FindConVar("hostname");
    if (hHostname != null)
        hHostname.GetString(sHostname, sizeof(sHostname));
    else
        strcopy(sHostname, sizeof(sHostname), "server");

    BuildServerIdFromHostname(sHostname, buffer, maxlen);
}

void BuildServerIdFromHostname(const char[] hostname, char[] buffer, int maxlen)
{
    if (TryBuildIndexedHostnameId(hostname, buffer, maxlen))
        return;

    ConVar hHostPort = FindConVar("hostport");
    int iPort = (hHostPort != null) ? hHostPort.IntValue : 0;

    FormatEx(buffer, maxlen, "%s:%d", hostname, iPort);
}

bool BuildCurrentServerAddress(char[] ipBuffer, int ipMaxLen, int &port, char[] addressKey, int addressKeyMaxLen)
{
    if (g_sCvarServerIp[0] != '\0')
    {
        strcopy(ipBuffer, ipMaxLen, g_sCvarServerIp);
        int configuredPort = 0;
        ExtractAddressPort(ipBuffer, configuredPort);
        port = configuredPort;
    }
    else if (!GetCurrentServerPublicIp(ipBuffer, ipMaxLen))
    {
        return false;
    }
    else
    {
        port = 0;
    }

    if (g_iCvarServerPort > 0)
        port = g_iCvarServerPort;

    if (port <= 0)
        port = GetCurrentServerPort();

    TrimString(ipBuffer);
    if (ipBuffer[0] == '\0' || port <= 0)
        return false;

    FormatEx(addressKey, addressKeyMaxLen, "%s:%d", ipBuffer, port);
    TrimString(addressKey);
    return addressKey[0] != '\0';
}

void ExtractAddressPort(char[] address, int &port)
{
    TrimString(address);
    int iLen = strlen(address);
    if (iLen <= 0)
        return;

    int iColon = -1;
    for (int i = iLen - 1; i >= 0; i--)
    {
        if (address[i] == ':')
        {
            iColon = i;
            break;
        }
    }

    if (iColon <= 0 || iColon >= iLen - 1)
        return;

    char sPort[12];
    int iOut = 0;
    for (int i = iColon + 1; i < iLen && iOut < sizeof(sPort) - 1; i++)
    {
        if (address[i] < '0' || address[i] > '9')
            return;
        sPort[iOut++] = address[i];
    }
    sPort[iOut] = '\0';

    int iParsedPort = StringToInt(sPort);
    if (iParsedPort <= 0 || iParsedPort > 65535)
        return;

    address[iColon] = '\0';
    TrimString(address);
    if (address[0] == '\0')
        return;

    port = iParsedPort;
}

int GetCurrentServerPort()
{
    ConVar hHostPort = FindConVar("hostport");
    if (hHostPort != null && hHostPort.IntValue > 0)
        return hHostPort.IntValue;

    ConVar hPort = FindConVar("port");
    if (hPort != null && hPort.IntValue > 0)
        return hPort.IntValue;

    return 0;
}

bool GetCurrentServerPublicIp(char[] buffer, int maxlen)
{
    ConVar hPublicAdr = FindConVar("net_public_adr");
    if (hPublicAdr != null)
    {
        hPublicAdr.GetString(buffer, maxlen);
        TrimString(buffer);
        if (buffer[0] != '\0')
            return true;
    }

    ConVar hIp = FindConVar("ip");
    if (hIp != null)
    {
        hIp.GetString(buffer, maxlen);
        TrimString(buffer);
        if (buffer[0] != '\0' && !StrEqual(buffer, "0.0.0.0") && !StrEqual(buffer, "localhost", false))
            return true;
    }

    ConVar hHostIp = FindConVar("hostip");
    if (hHostIp != null)
    {
        int iHostIp = hHostIp.IntValue;
        if (iHostIp > 0)
        {
            FormatEx(buffer, maxlen, "%d.%d.%d.%d",
                (iHostIp >> 24) & 0xFF,
                (iHostIp >> 16) & 0xFF,
                (iHostIp >> 8) & 0xFF,
                iHostIp & 0xFF);
            return true;
        }
    }

    buffer[0] = '\0';
    return false;
}

bool BuildCurrentServerId(const char[] hostname, char[] buffer, int maxlen)
{
    if (g_bAutoServerId)
        return TryBuildIndexedHostnameId(hostname, buffer, maxlen);

    strcopy(buffer, maxlen, g_sCvarServerId);
    return buffer[0] != '\0';
}

bool TryBuildIndexedHostnameId(const char[] hostname, char[] buffer, int maxlen)
{
    int iLen = strlen(hostname);
    int iHash = -1;

    for (int i = 0; i < iLen; i++)
    {
        if (hostname[i] == '#')
        {
            iHash = i;
            break;
        }
    }

    if (iHash < 0)
        return false;

    int iDigitStart = iHash + 1;
    while (iDigitStart < iLen && (hostname[iDigitStart] == ' ' || hostname[iDigitStart] == '\t'))
        iDigitStart++;

    int iDigitEnd = iDigitStart;
    while (iDigitEnd < iLen && hostname[iDigitEnd] >= '0' && hostname[iDigitEnd] <= '9')
        iDigitEnd++;

    if (iDigitEnd == iDigitStart)
        return false;

    char sDigits[16];
    int iOut = 0;
    for (int i = iDigitStart; i < iDigitEnd && iOut < sizeof(sDigits) - 1; i++)
        sDigits[iOut++] = hostname[i];
    sDigits[iOut] = '\0';

    FormatEx(buffer, maxlen, "Anne云服#%s", sDigits);
    TrimString(buffer);

    return buffer[0] != '\0';
}

bool IsSafeSQLIdentifier(const char[] value)
{
    int iLen = strlen(value);
    if (iLen <= 0)
        return false;

    for (int i = 0; i < iLen; i++)
    {
        int c = value[i];
        bool bOk = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_';
        if (!bOk)
            return false;
    }

    return true;
}

void ClearDefault()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

void ResetTimer()
{
    delete g_hDetectTimer;
}

bool HasAccess(int client, char[] sAcclvl)
{
	// no permissions set
	if (strlen(sAcclvl) == 0)
		return true;

	else if (StrEqual(sAcclvl, "-1"))
		return false;

	// check permissions
	int flag = GetUserFlagBits(client);
	if ( flag & ReadFlagString(sAcclvl) || flag & ADMFLAG_ROOT )
	{
		return true;
	}

	return false;
}


// 读取“此时间戳下，服务器本地相对 UTC 的偏移（分钟）”
int GetLocalUtcOffsetMinutes(int stamp)
{
    char z[8];
    FormatTime(z, sizeof z, "%z", stamp); // 形如 +0800 / -0700

    // 若运行库不支持 %z（个别平台会返回空或'???'等），走回退
    if (z[0] == '\0' || z[0] == '?')
        return g_hTzServerOffset.IntValue;

    // 解析 +HHMM / -HHMM
    int hhmm = StringToInt(z); // "+0800"→800, "-0700"→-700
    int sign = (z[0] == '-') ? -1 : 1;
    int absval = (hhmm < 0) ? -hhmm : hhmm;
    int minutes = (absval / 100) * 60 + (absval % 100);
    return sign * minutes;
}

// 把 UTC 时间戳转换为“上海时区意义下”的时间戳，再交给 FormatTime 使用
int ToShanghaiStamp(int stampUtc /* = GetTime() */)
{
    if (stampUtc <= 0) stampUtc = GetTime();
    const int kShanghaiOffsetMin = 8 * 60;  // Asia/Shanghai 固定 UTC+8，无夏令时
    int localOffset = GetLocalUtcOffsetMinutes(stampUtc);
    return stampUtc + (kShanghaiOffsetMin - localOffset) * 60;
}
