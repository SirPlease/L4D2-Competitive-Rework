#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <l4dstats>

#define PLUGIN_VERSION "1.0"

Database g_hDatabase = null;
Handle g_hPollTimer = null;
Handle g_hReconnectTimer = null;

bool g_bConnecting;
bool g_bReady;
bool g_bPollInFlight;
bool g_bl4dstatsAvailable;
int g_iLastMessageId;
int g_iLastCleanupTime;

ConVar g_cvEnabled;
ConVar g_cvDatabaseConfig;
ConVar g_cvPollInterval;
ConVar g_cvPollBatch;
ConVar g_cvCleanupInterval;
ConVar g_cvRetentionDays;
ConVar g_cvMessagePrefix;
ConVar g_cvLimitDefault;
ConVar g_cvLimit1M;
ConVar g_cvLimit5M;
ConVar g_cvLimit10M;
ConVar g_cvLimit20M;

public Plugin myinfo =
{
	name = "Anne Global Chat",
	author = "OpenAI",
	description = "Cross-server chat through a shared MySQL table",
	version = PLUGIN_VERSION,
	url = "https://github.com/fantasylidong/CompetitiveWithAnne"
};

public void OnPluginStart()
{
	g_cvEnabled = CreateConVar("sm_qf_enabled", "1", "是否启用全服聊天。", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvDatabaseConfig = CreateConVar("sm_qf_database", "globalchat", "databases.cfg 里的数据库配置名称。");
	g_cvPollInterval = CreateConVar("sm_qf_poll_interval", "1.0", "全服聊天轮询间隔，单位秒。", FCVAR_NONE, true, 0.5, true, 30.0);
	g_cvPollBatch = CreateConVar("sm_qf_poll_batch", "30", "每次最多拉取多少条全服聊天消息。", FCVAR_NONE, true, 1.0, true, 200.0);
	g_cvCleanupInterval = CreateConVar("sm_qf_cleanup_interval", "21600", "清理旧全服聊天记录的间隔，单位秒。", FCVAR_NONE, true, 300.0);
	g_cvRetentionDays = CreateConVar("sm_qf_retention_days", "7", "全服聊天记录保留天数。0 表示不清理。", FCVAR_NONE, true, 0.0);
	g_cvMessagePrefix = CreateConVar("sm_qf_prefix", "[全服]", "全服聊天前缀。");
	g_cvLimitDefault = CreateConVar("sm_qf_limit_default", "3", "普通玩家每日全服聊天次数。", FCVAR_NONE, true, 0.0);
	g_cvLimit1M = CreateConVar("sm_qf_limit_1m", "5", "100w 积分以上玩家每日全服聊天次数。", FCVAR_NONE, true, 0.0);
	g_cvLimit5M = CreateConVar("sm_qf_limit_5m", "10", "500w 积分以上玩家每日全服聊天次数。", FCVAR_NONE, true, 0.0);
	g_cvLimit10M = CreateConVar("sm_qf_limit_10m", "20", "1000w 积分以上玩家每日全服聊天次数。", FCVAR_NONE, true, 0.0);
	g_cvLimit20M = CreateConVar("sm_qf_limit_20m", "30", "2000w 积分以上玩家每日全服聊天次数。", FCVAR_NONE, true, 0.0);

	RegConsoleCmd("sm_qf", Command_GlobalChat, "发送全服聊天: !qf <内容>");
	RegConsoleCmd("sm_quanfu", Command_GlobalChat, "发送全服聊天: !quanfu <内容>");

	AutoExecConfig(true, "global_chat");
}

public void OnAllPluginsLoaded()
{
	g_bl4dstatsAvailable = LibraryExists("l4d_stats");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "l4d_stats"))
		g_bl4dstatsAvailable = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "l4d_stats"))
		g_bl4dstatsAvailable = false;
}

public void OnConfigsExecuted()
{
	ConnectDatabase();
}

public void OnPluginEnd()
{
	StopPollTimer();
	StopReconnectTimer();

	if (g_hDatabase != null)
	{
		delete g_hDatabase;
		g_hDatabase = null;
	}
}

public Action Command_GlobalChat(int client, int args)
{
	if (!g_cvEnabled.BoolValue)
	{
		ReplyToCommand(client, "[全服] 全服聊天当前未启用。");
		return Plugin_Handled;
	}

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
	{
		ReplyToCommand(client, "[全服] 只有游戏内玩家可以发送全服聊天。");
		return Plugin_Handled;
	}

	if (!g_bReady || g_hDatabase == null)
	{
		ReplyToCommand(client, "[全服] 数据库尚未连接，请稍后再试。");
		return Plugin_Handled;
	}

	char message[256];
	GetCmdArgString(message, sizeof(message));
	StripQuotes(message);
	TrimString(message);

	if (message[0] == '\0')
	{
		ReplyToCommand(client, "[全服] 用法: !qf <内容>");
		return Plugin_Handled;
	}

	char steamId[32];
	if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
	{
		ReplyToCommand(client, "[全服] 无法获取你的 SteamID，请稍后再试。");
		return Plugin_Handled;
	}

	char clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));

	if (HasUnlimitedGlobalChat(client))
	{
		InsertGlobalMessage(steamId, clientName, message);
		return Plugin_Handled;
	}

	ReserveDailyUsage(client, steamId, clientName, message, GetDailyLimit(client));
	return Plugin_Handled;
}

void ConnectDatabase()
{
	if (g_hDatabase != null || g_bConnecting)
		return;

	char configName[64];
	g_cvDatabaseConfig.GetString(configName, sizeof(configName));

	g_bConnecting = true;
	Database.Connect(SQL_OnConnect, configName);
}

void ScheduleReconnect()
{
	g_bReady = false;
	g_bConnecting = false;
	g_bPollInFlight = false;
	StopPollTimer();

	if (g_hDatabase != null)
	{
		delete g_hDatabase;
		g_hDatabase = null;
	}

	if (g_hReconnectTimer == null)
		g_hReconnectTimer = CreateTimer(10.0, Timer_ReconnectDatabase, _, TIMER_FLAG_NO_MAPCHANGE);
}

void StartPollTimer()
{
	StopPollTimer();
	g_hPollTimer = CreateTimer(g_cvPollInterval.FloatValue, Timer_PollMessages, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void StopPollTimer()
{
	if (g_hPollTimer != null)
	{
		delete g_hPollTimer;
		g_hPollTimer = null;
	}
}

void StopReconnectTimer()
{
	if (g_hReconnectTimer != null)
	{
		delete g_hReconnectTimer;
		g_hReconnectTimer = null;
	}
}

public Action Timer_ReconnectDatabase(Handle timer, any data)
{
	g_hReconnectTimer = null;
	ConnectDatabase();
	return Plugin_Stop;
}

public Action Timer_PollMessages(Handle timer, any data)
{
	if (!g_cvEnabled.BoolValue || !g_bReady || g_hDatabase == null)
		return Plugin_Continue;

	if (g_bPollInFlight)
		return Plugin_Continue;

	RunCleanupIfNeeded();

	char query[256];
	g_hDatabase.Format(query, sizeof(query), "SELECT id, server, port, name, message FROM anne_global_chat WHERE id > %d ORDER BY id ASC LIMIT %d", g_iLastMessageId, g_cvPollBatch.IntValue);
	g_bPollInFlight = true;
	g_hDatabase.Query(SQL_OnPollMessages, query);

	return Plugin_Continue;
}

public void SQL_OnConnect(Database database, const char[] error, any data)
{
	g_bConnecting = false;

	if (database == null)
	{
		LogError("[global_chat] 数据库连接失败: %s", error);
		ScheduleReconnect();
		return;
	}

	g_hDatabase = database;
	g_hDatabase.SetCharset("utf8mb4");
	g_hDatabase.Query(SQL_OnCreateTable, "\
		CREATE TABLE IF NOT EXISTS `anne_global_chat` ( \
			`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, \
			`created_at` DATETIME NOT NULL, \
			`server` VARCHAR(126) NOT NULL COLLATE 'utf8mb4_general_ci', \
			`port` INT NOT NULL DEFAULT 0, \
			`steamid` VARCHAR(32) NOT NULL COLLATE 'utf8mb4_general_ci', \
			`name` VARCHAR(128) NOT NULL COLLATE 'utf8mb4_general_ci', \
			`message` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_general_ci', \
			PRIMARY KEY (`id`) USING BTREE, \
			KEY `idx_anne_global_chat_created_at` (`created_at`) \
		) DEFAULT CHARSET='utf8mb4' ENGINE=InnoDB;");
}

public void SQL_OnCreateTable(Database database, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[global_chat] 初始化消息表失败: %s", error);
		ScheduleReconnect();
		return;
	}

	g_hDatabase.Query(SQL_OnCreateUsageTable, "\
		CREATE TABLE IF NOT EXISTS `anne_global_chat_usage` ( \
			`steamid` VARCHAR(32) NOT NULL COLLATE 'utf8mb4_general_ci', \
			`usage_date` DATE NOT NULL, \
			`used_count` INT UNSIGNED NOT NULL DEFAULT 0, \
			`last_used_at` DATETIME NOT NULL, \
			PRIMARY KEY (`steamid`, `usage_date`) USING BTREE, \
			KEY `idx_anne_global_chat_usage_date` (`usage_date`) \
		) DEFAULT CHARSET='utf8mb4' ENGINE=InnoDB;");
}

void RunCleanupIfNeeded()
{
	int retentionDays = g_cvRetentionDays.IntValue;
	if (retentionDays <= 0)
		return;

	int now = GetTime();
	if (now - g_iLastCleanupTime < g_cvCleanupInterval.IntValue)
		return;

	g_iLastCleanupTime = now;

	char query[256];
	g_hDatabase.Format(query, sizeof(query), "DELETE FROM anne_global_chat WHERE created_at < DATE_SUB(NOW(), INTERVAL %d DAY)", retentionDays);
	g_hDatabase.Query(SQL_OnCleanup, query);

	g_hDatabase.Format(query, sizeof(query), "DELETE FROM anne_global_chat_usage WHERE usage_date < DATE_SUB(CURDATE(), INTERVAL %d DAY)", retentionDays);
	g_hDatabase.Query(SQL_OnCleanup, query);
}

public void SQL_OnCleanup(Database database, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[global_chat] 清理旧消息失败: %s", error);
		ScheduleReconnect();
	}
}

public void SQL_OnCreateUsageTable(Database database, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[global_chat] 初始化使用次数表失败: %s", error);
		ScheduleReconnect();
		return;
	}

	g_hDatabase.Query(SQL_OnLoadLastId, "SELECT COALESCE(MAX(id), 0) FROM anne_global_chat");
}

public void SQL_OnLoadLastId(Database database, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[global_chat] 读取最新消息 ID 失败: %s", error);
		ScheduleReconnect();
		return;
	}

	if (results.FetchRow())
		g_iLastMessageId = results.FetchInt(0);

	g_bReady = true;
	StartPollTimer();
}

bool HasUnlimitedGlobalChat(int client)
{
	return CheckCommandAccess(client, "sm_kick", ADMFLAG_KICK, true);
}

int GetDailyLimit(int client)
{
	int score = 0;
	if (g_bl4dstatsAvailable && GetFeatureStatus(FeatureType_Native, "l4dstats_GetClientScore") == FeatureStatus_Available)
		score = l4dstats_GetClientScore(client);

	if (score >= 20000000)
		return g_cvLimit20M.IntValue;

	if (score >= 10000000)
		return g_cvLimit10M.IntValue;

	if (score >= 5000000)
		return g_cvLimit5M.IntValue;

	if (score >= 1000000)
		return g_cvLimit1M.IntValue;

	return g_cvLimitDefault.IntValue;
}

void ReserveDailyUsage(int client, const char[] steamId, const char[] clientName, const char[] message, int limit)
{
	if (limit <= 0)
	{
		ReplyToCommand(client, "[全服] 你当前没有全服聊天次数。");
		return;
	}

	char safeSteamId[64];
	g_hDatabase.Escape(steamId, safeSteamId, sizeof(safeSteamId));

	char usageDate[16];
	FormatTime(usageDate, sizeof(usageDate), "%Y-%m-%d", GetTime());

	char query[768];
	g_hDatabase.Format(query, sizeof(query), "\
		INSERT INTO anne_global_chat_usage (steamid, usage_date, used_count, last_used_at) \
		VALUES ('%s', '%s', 1, NOW()) \
		ON DUPLICATE KEY UPDATE \
			last_used_at = IF(used_count < %d, NOW(), last_used_at), \
			used_count = IF(used_count < %d, used_count + 1, used_count)",
		safeSteamId, usageDate, limit, limit);

	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(limit);
	pack.WriteString(steamId);
	pack.WriteString(clientName);
	pack.WriteString(message);

	g_hDatabase.Query(SQL_OnReserveDailyUsage, query, pack);
}

public void SQL_OnReserveDailyUsage(Database database, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();
	int userid = pack.ReadCell();
	int limit = pack.ReadCell();

	char steamId[32];
	char clientName[MAX_NAME_LENGTH];
	char message[256];
	pack.ReadString(steamId, sizeof(steamId));
	pack.ReadString(clientName, sizeof(clientName));
	pack.ReadString(message, sizeof(message));
	delete pack;

	if (results == null)
	{
		int client = GetClientOfUserId(userid);
		if (client > 0)
			ReplyToCommand(client, "[全服] 检查今日次数失败，请稍后再试。");

		LogError("[global_chat] 更新每日使用次数失败: %s", error);
		ScheduleReconnect();
		return;
	}

	if (results.AffectedRows <= 0)
	{
		int client = GetClientOfUserId(userid);
		if (client > 0)
			ReplyToCommand(client, "[全服] 今日全服聊天次数已用完（每日 %d 次）。", limit);

		return;
	}

	InsertGlobalMessage(steamId, clientName, message);
}

void InsertGlobalMessage(const char[] steamId, const char[] clientName, const char[] message)
{
	char hostname[128];
	char safeHostname[256];
	char safeSteamId[64];
	char safeName[256];
	char safeMessage[512];

	GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
	g_hDatabase.Escape(hostname, safeHostname, sizeof(safeHostname));
	g_hDatabase.Escape(steamId, safeSteamId, sizeof(safeSteamId));
	g_hDatabase.Escape(message, safeMessage, sizeof(safeMessage));
	g_hDatabase.Escape(clientName, safeName, sizeof(safeName));

	int port = FindConVar("hostport").IntValue;

	char query[1024];
	FormatEx(query, sizeof(query), "INSERT INTO anne_global_chat (created_at, server, port, steamid, name, message) VALUES (NOW(), '%s', %d, '%s', '%s', '%s')", safeHostname, port, safeSteamId, safeName, safeMessage);
	g_hDatabase.Query(SQL_OnInsertMessage, query);
}

public void SQL_OnInsertMessage(Database database, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[global_chat] 写入全服消息失败: %s", error);
		ScheduleReconnect();
	}
}

/**
 * 从完整 hostname 中提取 "Anne云服#N" 前缀。
 * 若未找到该模式，则原样返回 server。
 */
void GetShortServerName(const char[] server, char[] shortName, int maxLen)
{
	// 查找 "Anne云服#" 在字符串中的位置（UTF-8：Anne=4字节，云=3，服=3，#=1，共11字节）
	static const char pattern[] = "Anne\xe4\xba\x91\xe6\x9c\x8d#"; // "Anne云服#"
	int pos = StrContains(server, pattern, false);
	if (pos < 0)
	{
		// 未找到，原样使用
		strcopy(shortName, maxLen, server);
		return;
	}

	int prefixLen = strlen(pattern); // 模式本身的长度
	int start = pos + prefixLen;     // '#' 之后第一个字符的下标

	// 向后读取连续数字
	int end = start;
	while (server[end] >= '0' && server[end] <= '9')
		end++;

	// 截取 pos .. end-1
	int copyLen = end - pos;
	if (copyLen <= 0 || copyLen >= maxLen)
	{
		strcopy(shortName, maxLen, server);
		return;
	}

	strcopy(shortName, copyLen + 1, server[pos]);
}

public void SQL_OnPollMessages(Database database, DBResultSet results, const char[] error, any data)
{
	g_bPollInFlight = false;

	if (results == null)
	{
		LogError("[global_chat] 拉取全服消息失败: %s", error);
		ScheduleReconnect();
		return;
	}

	char prefix[64];
	char server[128];
	char shortServer[64];
	char name[128];
	char message[256];

	g_cvMessagePrefix.GetString(prefix, sizeof(prefix));

	while (results.FetchRow())
	{
		int id = results.FetchInt(0);
		results.FetchString(1, server, sizeof(server));
		results.FetchString(3, name, sizeof(name));
		results.FetchString(4, message, sizeof(message));

		if (id > g_iLastMessageId)
			g_iLastMessageId = id;

		GetShortServerName(server, shortServer, sizeof(shortServer));
		PrintToChatAll("\x04%s \x03[%s] \x05%s\x01: %s", prefix, shortServer, name, message);
	}
}
