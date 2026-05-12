#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

bool g_bFullyConnected;

Database g_hDatabase = null;

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

public void OnConfigsExecuted()
{
	if (!g_hDatabase)
	{
		Database.Connect(SQL_Connection, "chatlog");
	}
}

public void SQL_Connection(Database database, const char[] error, int data)
{
	if (database == null)
		SetFailState(error);
	else
	{
		g_hDatabase = database;

		g_hDatabase.SetCharset("utf8mb4");

		g_hDatabase.Query(SQL_CreateCallback, "\
		CREATE TABLE IF NOT EXISTs`chat_log` ( \
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
}

public void SQL_CreateCallback(Database datavas, DBResultSet results, const char[] error, int data)
{
	if (results == null)
		SetFailState(error);
		
	g_bFullyConnected = true;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] szArgs)
{
	if (g_bFullyConnected && !IsFakeClient(client))
	{
		if (strlen(szArgs) > 0 && szArgs[0]!='!' && szArgs[0]!='/')
		{
			int iMsgStyle, iServerPort;
			int iTimeTmp = GetTime();
			char szQuery[512], szTime[512], szMap[128], szSteamID[21], szTimeFunction[64], szServerName[64];

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
				return;
			}
			iServerPort = GetConVarInt( FindConVar( "hostport" ) );
			GetConVarString(FindConVar("hostname"), szServerName, sizeof(szServerName));

			g_hDatabase.Format(szQuery, sizeof(szQuery), "INSERT INTO chat_log (date, map, steamid, name, message_style, message, server, port) VALUES ('%s', '%s', '%s', '%N', '%d', '%s', '%s', '%d')", szTime, szMap, szSteamID, client, iMsgStyle, szArgs, szServerName, iServerPort);
			g_hDatabase.Query(SQL_Error, szQuery);

			GetConVarString(chatlog_clearTableDuration, szTimeFunction, sizeof(szTimeFunction));

			if (GetConVarBool(chatlog_clearTable))
			{
				g_hDatabase.Format(szQuery, sizeof(szQuery), "DELETE FROM chat_log WHERE date < DATE_SUB(NOW(), INTERVAL %s)", szTimeFunction);
				g_hDatabase.Query(SQL_Error, szQuery);
			}
		}
	}
}

public void SQL_Error(Database datavas, DBResultSet results, const char[] error, int data)
{
	if (results == null)
	{
		SetFailState(error);
	}
}
