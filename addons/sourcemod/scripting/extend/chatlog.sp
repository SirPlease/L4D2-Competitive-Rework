#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

bool g_bFullyConnected;
bool g_bConnecting;
Handle g_hReconnectTimer = null;
Handle g_hKeepAliveTimer = null;
Handle g_hCleanupTimer = null;

Database g_hDatabase = null;

#define CHATLOG_DB_CONFIG "chatlog"
#define CHATLOG_RECONNECT_DELAY 10.0
#define CHATLOG_KEEPALIVE_INTERVAL 45.0
#define CHATLOG_CLEANUP_INTERVAL 21600.0

ConVar chatlog_clearTable;
ConVar chatlog_clearTableDuration;

public Plugin myinfo = {
	name		= "Chat Log",
	author		= "venus, 东",
	description	= "Save all user messages in database, add server name and port",
	version		= "1.2",
	url			= "https://github.com/ivenuss"
};

public void OnPluginStart()
{
	chatlog_clearTable = CreateConVar("sm_chatlog_cleartable_enabled", "1", "Enable/Disable clearing table (1/0)", 0, true, 0.0, true, 1.0);
	chatlog_clearTableDuration = CreateConVar("sm_chatlog_cleartable_duration", "12 MONTH", "How often will table restart\n(TIME FUNCTIONS: https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html)");

	AutoExecConfig(true, "chatlog");
}

public void OnMapEnd()
{
	// 连接和 KeepAlive 都保持跨地图运行，不停不断。
}

public void OnConfigsExecuted()
{
	SQL_ConnectChatLog();
}

void SQL_ConnectChatLog()
{
	if (g_hDatabase != null || g_bConnecting)
		return;

	if (!SQL_CheckConfig(CHATLOG_DB_CONFIG))
	{
		LogError("[chatlog] databases.cfg 缺少 '%s' 配置。", CHATLOG_DB_CONFIG);
		SQL_ScheduleReconnect();
		return;
	}

	g_bConnecting = true;
	char error[256];
	g_hDatabase = SQL_Connect(CHATLOG_DB_CONFIG, false, error, sizeof(error));
	g_bConnecting = false;

	if (g_hDatabase == null)
	{
		LogError("[chatlog] 数据库连接失败: %s", error);
		SQL_ScheduleReconnect();
		return;
	}

	if (!SQL_SetCharset(g_hDatabase, "utf8mb4"))
		LogError("[chatlog] 设置数据库字符集 utf8mb4 失败。");

	SQL_FastQuery(g_hDatabase, "SET NAMES 'utf8mb4'");
	SQL_CreateChatLogTable();
}

void SQL_CreateChatLogTable()
{
	g_hDatabase.Query(SQL_CreateCallback, "\
		CREATE TABLE IF NOT EXISTS `chat_log` ( \
		`id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT, \
		`date` DATETIME NULL DEFAULT NULL, \
		`map` VARCHAR(128) NOT NULL COLLATE 'utf8mb4_general_ci', \
		`steamid` VARCHAR(21) NOT NULL COLLATE 'utf8mb4_general_ci', \
		`name` VARCHAR(128) NOT NULL COLLATE 'utf8mb4_general_ci', \
		`message_style` TINYINT(2) NULL DEFAULT 0, \
		`message` VARCHAR(126) NOT NULL COLLATE 'utf8mb4_general_ci', \
		`server` varchar(126) DEFAULT NULL COLLATE 'utf8mb4_general_ci', \
		`port` int(11) DEFAULT NULL , \
		PRIMARY KEY (`id`) USING BTREE, \
		KEY `idx_chat_log_date` (`date`) \
	) \
	DEFAULT CHARSET='utf8mb4' \
	ENGINE=InnoDB \
	;");
}

bool SQL_IsConnectionLostError(const char[] error)
{
	return StrContains(error, "Lost connection", false) != -1
		|| StrContains(error, "server has gone away", false) != -1;
}

void SQL_ScheduleReconnect()
{
	g_bFullyConnected = false;
	g_bConnecting = false;
	SQL_StopKeepAliveTimer();
	SQL_StopCleanupTimer();

	if (g_hDatabase != null)
	{
		delete g_hDatabase;
		g_hDatabase = null;
	}

	if (g_hReconnectTimer == null)
		g_hReconnectTimer = CreateTimer(CHATLOG_RECONNECT_DELAY, Timer_ReconnectDatabase);
}

void SQL_StartKeepAliveTimer()
{
	if (g_hKeepAliveTimer != null)
		return;

	g_hKeepAliveTimer = CreateTimer(CHATLOG_KEEPALIVE_INTERVAL, Timer_KeepAlive, _, TIMER_REPEAT);
}

void SQL_StopKeepAliveTimer()
{
	if (g_hKeepAliveTimer == null)
		return;

	KillTimer(g_hKeepAliveTimer);
	g_hKeepAliveTimer = null;
}

void SQL_StartCleanupTimer()
{
	SQL_StopCleanupTimer();
	g_hCleanupTimer = CreateTimer(CHATLOG_CLEANUP_INTERVAL, Timer_CleanupChatLog, _, TIMER_REPEAT);
}

void SQL_StopCleanupTimer()
{
	if (g_hCleanupTimer == null)
		return;

	KillTimer(g_hCleanupTimer);
	g_hCleanupTimer = null;
}

public Action Timer_ReconnectDatabase(Handle timer, any data)
{
	g_hReconnectTimer = null;
	SQL_ConnectChatLog();
	return Plugin_Stop;
}

public Action Timer_KeepAlive(Handle timer, any data)
{
	if (!g_bFullyConnected || g_hDatabase == null)
		return Plugin_Continue;

	g_hDatabase.Query(SQL_KeepAliveCallback, "SELECT 1");
	return Plugin_Continue;
}

public void SQL_KeepAliveCallback(Database datavas, DBResultSet results, const char[] error, int data)
{
	if (results == null)
	{
		LogError("[chatlog] 数据库保活失败: %s", error);
		SQL_ScheduleReconnect();
	}
}

public Action Timer_CleanupChatLog(Handle timer, any data)
{
	SQL_RunCleanup();
	return Plugin_Continue;
}

void SQL_RunCleanup()
{
	if (!g_bFullyConnected || g_hDatabase == null || !GetConVarBool(chatlog_clearTable))
		return;

	char szTimeFunction[64];
	char szQuery[256];
	GetConVarString(chatlog_clearTableDuration, szTimeFunction, sizeof(szTimeFunction));
	TrimString(szTimeFunction);
	if (szTimeFunction[0] == '\0')
		return;

	g_hDatabase.Format(szQuery, sizeof(szQuery), "DELETE FROM chat_log WHERE date < DATE_SUB(NOW(), INTERVAL %s)", szTimeFunction);
	g_hDatabase.Query(SQL_Error, szQuery);
}

public void SQL_CreateCallback(Database datavas, DBResultSet results, const char[] error, int data)
{
	if (results == null)
	{
		LogError("[chatlog] 初始化数据表失败: %s", error);
		if (SQL_IsConnectionLostError(error))
			SQL_ScheduleReconnect();
		return;
	}

	g_bFullyConnected = true;
	SQL_StartKeepAliveTimer();
	SQL_StartCleanupTimer();
	SQL_RunCleanup();
}

public void OnPluginEnd()
{
	if (g_hReconnectTimer != null)
	{
		KillTimer(g_hReconnectTimer);
		g_hReconnectTimer = null;
	}

	SQL_StopKeepAliveTimer();
	SQL_StopCleanupTimer();

	if (g_hDatabase != null)
	{
		delete g_hDatabase;
		g_hDatabase = null;
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] szArgs)
{
	if (g_bFullyConnected && !IsFakeClient(client))
	{
		if (strlen(szArgs) > 0 && szArgs[0]!='!' && szArgs[0]!='/')
		{
			int iMsgStyle, iServerPort;
			int iTimeTmp = GetTime();
			char szQuery[512], szTime[512], szMap[128], szSteamID[21], szServerName[64];

			if (StrContains(command, "_", false) != -1)
			{
				iMsgStyle = 1; //Team chat
			}

			else
			{
				iMsgStyle = 0; //General chat
			}

			FormatTime(szTime, sizeof(szTime), "%Y-%m-%d %T", iTimeTmp);
			GetCurrentMap(szMap, sizeof(szMap));
			

			if(!GetClientAuthId(client, AuthId_Steam2, szSteamID, sizeof(szSteamID)))
			{
				LogError("Player %N's steamid couldn't be fetched", client);
				return Plugin_Continue;
			}
			iServerPort = GetConVarInt( FindConVar( "hostport" ) );
			GetConVarString(FindConVar("hostname"), szServerName, sizeof(szServerName));

			g_hDatabase.Format(szQuery, sizeof(szQuery), "INSERT INTO chat_log (date, map, steamid, name, message_style, message, server, port) VALUES ('%s', '%s', '%s', '%N', '%d', '%s', '%s', '%d')", szTime, szMap, szSteamID, client, iMsgStyle, szArgs, szServerName, iServerPort);
			g_hDatabase.Query(SQL_Error, szQuery);
		}
	}

	return Plugin_Continue;
}

public void SQL_Error(Database datavas, DBResultSet results, const char[] error, int data)
{
	if (results == null)
	{
		LogError("[chatlog] SQL 查询失败: %s", error);
		if (SQL_IsConnectionLostError(error))
			SQL_ScheduleReconnect();
	}
}
