#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <l4dstats>

#define PLUGIN_VERSION "1.0"

Database g_hDatabase = null;
Database g_hBlacklistDatabase = null;
Handle g_hPollTimer = null;
Handle g_hReconnectTimer = null;
Handle g_hKeepAliveTimer = null;
Handle g_hBlacklistReconnectTimer = null;
Handle g_hBlacklistRefreshTimer = null;
Handle g_hBlacklistKeepAliveTimer = null;

bool g_bConnecting;
bool g_bBlacklistConnecting;
bool g_bReady;
bool g_bPollInFlight;
bool g_bBlacklistRefreshInFlight;
bool g_bl4dstatsAvailable;
bool g_bClientSeeGlobal[MAXPLAYERS + 1];
bool g_bClientSeeLFG[MAXPLAYERS + 1];
StringMap g_mClientBlockedSteam64[MAXPLAYERS + 1];
int g_iLastMessageId;
int g_iLastCleanupTime;

ConVar g_cvEnabled;
ConVar g_cvDatabaseConfig;
ConVar g_cvPollInterval;
ConVar g_cvPollBatch;
ConVar g_cvCleanupInterval;
ConVar g_cvRetentionDays;
ConVar g_cvMessagePrefix;
ConVar g_cvBlacklistFilter;
ConVar g_cvBlacklistDatabaseConfig;
ConVar g_cvBlacklistTable;
ConVar g_cvBlacklistRefreshInterval;
ConVar g_cvLimitDefault;
ConVar g_cvLimit1M;
ConVar g_cvLimit5M;
ConVar g_cvLimit10M;
ConVar g_cvLimit20M;
ConVar g_cvLimitKickAdmin;
ConVar g_cvShowGlobal;
ConVar g_cvShowLFG;

ConVar g_cvLFGLimitDefault;
ConVar g_cvLFGLimit1M;
ConVar g_cvLFGLimit5M;
ConVar g_cvLFGLimit10M;
ConVar g_cvLFGLimit20M;
ConVar g_cvLFGLimitKickAdmin;

#define GLOBAL_CHAT_RECONNECT_DELAY 10.0
#define GLOBAL_CHAT_KEEPALIVE_INTERVAL 45.0

public Plugin myinfo =
{
	name = "Anne Global Chat",
	author = "OpenAI",
	description = "Cross-server chat through a shared MySQL table",
	version = PLUGIN_VERSION,
	url = "https://github.com/fantasylidong/CompetitiveWithAnne"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("global_chat");
	CreateNative("GlobalChat_Broadcast", Native_GlobalChatBroadcast);
	return APLRes_Success;
}

public int Native_GlobalChatBroadcast(Handle plugin, int numParams)
{
	if (numParams < 1)
		return ThrowNativeError(SP_ERROR_NATIVE, "GlobalChat_Broadcast requires message");

	char message[256];
	GetNativeString(1, message, sizeof(message));
	TrimString(message);

	if (message[0] == '\0')
		return false;

	if (!g_cvEnabled.BoolValue || !g_bReady || g_hDatabase == null)
		return false;

	InsertGlobalMessage("@SERVER", "@BROADCAST", message);
	return true;
}

public void OnPluginStart()
{
	g_cvEnabled = CreateConVar("sm_qf_enabled", "1", "是否启用全服聊天。", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvDatabaseConfig = CreateConVar("sm_qf_database", "globalchat", "databases.cfg 里的数据库配置名称。");
	g_cvPollInterval = CreateConVar("sm_qf_poll_interval", "2.0", "全服聊天轮询间隔，单位秒。", FCVAR_NONE, true, 2.0, true, 30.0);
	g_cvPollBatch = CreateConVar("sm_qf_poll_batch", "30", "每次最多拉取多少条全服聊天消息。", FCVAR_NONE, true, 1.0, true, 200.0);
	g_cvCleanupInterval = CreateConVar("sm_qf_cleanup_interval", "21600", "清理旧全服聊天记录的间隔，单位秒。", FCVAR_NONE, true, 300.0);
	g_cvRetentionDays = CreateConVar("sm_qf_retention_days", "7", "全服聊天记录保留天数。0 表示不清理。", FCVAR_NONE, true, 0.0);
	g_cvMessagePrefix = CreateConVar("sm_qf_prefix", "[全服]", "全服聊天前缀。");
	g_cvBlacklistFilter = CreateConVar("sm_qf_blacklist_filter", "1", "是否按 l4d2_blacklist 屏蔽全服聊天显示。", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvBlacklistDatabaseConfig = CreateConVar("sm_qf_blacklist_database", "l4dstats", "l4d2_blacklist 使用的 databases.cfg 配置名称。");
	g_cvBlacklistTable = CreateConVar("sm_qf_blacklist_table", "player_blocks", "l4d2_blacklist 使用的数据库表名。");
	g_cvBlacklistRefreshInterval = CreateConVar("sm_qf_blacklist_refresh_interval", "60.0", "刷新当前在线玩家 blacklist 缓存的间隔，单位秒。", FCVAR_NONE, true, 10.0, true, 600.0);
	g_cvLimitDefault = CreateConVar("sm_qf_limit_default", "3", "普通玩家每日全服聊天次数。", FCVAR_NONE, true, 0.0);
	g_cvLimit1M = CreateConVar("sm_qf_limit_1m", "5", "100w 积分以上玩家每日全服聊天次数。", FCVAR_NONE, true, 0.0);
	g_cvLimit5M = CreateConVar("sm_qf_limit_5m", "10", "500w 积分以上玩家每日全服聊天次数。", FCVAR_NONE, true, 0.0);
	g_cvLimit10M = CreateConVar("sm_qf_limit_10m", "20", "1000w 积分以上玩家每日全服聊天次数。", FCVAR_NONE, true, 0.0);
	g_cvLimit20M = CreateConVar("sm_qf_limit_20m", "30", "2000w 积分以上玩家每日全服聊天次数。", FCVAR_NONE, true, 0.0);
	g_cvLimitKickAdmin = CreateConVar("sm_qf_limit_kick_admin", "50", "有 kick 权限但没有 z 权限的管理员每日全服聊天次数。", FCVAR_NONE, true, 0.0);
	g_cvShowGlobal = CreateConVar("sm_qf_show_global", "1", "本服玩家是否能看到普通全服聊天和上线提示。", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvShowLFG = CreateConVar("sm_zd_show_global", "1", "本服旁观玩家是否能看到找队友全服提示。", FCVAR_NONE, true, 0.0, true, 1.0);

	g_cvLFGLimitDefault = CreateConVar("sm_zd_limit_default", "3", "普通玩家每日找队友次数。", FCVAR_NONE, true, 0.0);
	g_cvLFGLimit1M = CreateConVar("sm_zd_limit_1m", "5", "100w 积分以上玩家每日找队友次数。", FCVAR_NONE, true, 0.0);
	g_cvLFGLimit5M = CreateConVar("sm_zd_limit_5m", "10", "500w 积分以上玩家每日找队友次数。", FCVAR_NONE, true, 0.0);
	g_cvLFGLimit10M = CreateConVar("sm_zd_limit_10m", "20", "1000w 积分以上玩家每日找队友次数。", FCVAR_NONE, true, 0.0);
	g_cvLFGLimit20M = CreateConVar("sm_zd_limit_20m", "30", "2000w 积分以上玩家每日找队友次数。", FCVAR_NONE, true, 0.0);
	g_cvLFGLimitKickAdmin = CreateConVar("sm_zd_limit_kick_admin", "50", "有 kick 权限但没有 z 权限的管理员每日找队友次数。", FCVAR_NONE, true, 0.0);

	RegConsoleCmd("sm_qf", Command_GlobalChat, "发送全服聊天: !qf <内容>");
	RegConsoleCmd("sm_quanfu", Command_GlobalChat, "发送全服聊天: !quanfu <内容>");
	
	RegConsoleCmd("sm_zd", Command_LFG, "发送找队友信息: !zd <内容>");
	RegConsoleCmd("sm_zudui", Command_LFG, "发送找队友信息: !zudui <内容>");
	RegConsoleCmd("sm_zdy", Command_LFG, "发送找队友信息: !zdy <内容>");
	RegConsoleCmd("sm_qfmenu", Command_GlobalChatMenu, "打开全服聊天接收设置菜单");
	RegConsoleCmd("sm_qfadmin", Command_GlobalChatMenu, "打开全服聊天接收设置菜单");
	RegConsoleCmd("sm_zdmenu", Command_GlobalChatMenu, "打开找队友提示接收设置菜单");

	for (int i = 1; i <= MaxClients; i++)
	{
		g_bClientSeeGlobal[i] = true;
		g_bClientSeeLFG[i] = true;
	}

	AutoExecConfig(true, "global_chat");
}

public void OnClientPutInServer(int client)
{
	g_bClientSeeGlobal[client] = true;
	g_bClientSeeLFG[client] = true;
	ClearClientBlacklistCache(client);
}

public void OnClientDisconnect(int client)
{
	g_bClientSeeGlobal[client] = true;
	g_bClientSeeLFG[client] = true;
	ClearClientBlacklistCache(client);
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
	if (g_hDatabase != null)
	{
		g_bReady = true;
		StartPollTimer();
	}
	else
	{
		ConnectDatabase();
	}

	if (g_hBlacklistDatabase != null)
	{
		StartBlacklistRefreshTimer();
		RefreshBlacklistCache();
	}
	else
	{
		ConnectBlacklistDatabase();
	}
}

public void OnPluginEnd()
{
	StopPollTimer();
	StopReconnectTimer();
	StopKeepAliveTimer();
	StopBlacklistReconnectTimer();
	StopBlacklistRefreshTimer();
	StopBlacklistKeepAliveTimer();

	if (g_hDatabase != null)
	{
		delete g_hDatabase;
		g_hDatabase = null;
	}

	if (g_hBlacklistDatabase != null)
	{
		delete g_hBlacklistDatabase;
		g_hBlacklistDatabase = null;
	}

	for (int i = 1; i <= MaxClients; i++)
		ClearClientBlacklistCache(i);
}

public void OnMapEnd()
{
	// 换图时主动清理定时器和连接状态，
	// 确保 SQL 回调不会操作已失效的句柄。
	StopPollTimer();
	StopReconnectTimer();
	StopKeepAliveTimer();
	StopBlacklistRefreshTimer();
	StopBlacklistReconnectTimer();
	StopBlacklistKeepAliveTimer();
	g_bReady = false;
	g_bPollInFlight = false;
	g_bBlacklistRefreshInFlight = false;
	g_bConnecting = false;
	g_bBlacklistConnecting = false;

	if (g_hDatabase != null)
	{
		delete g_hDatabase;
		g_hDatabase = null;
	}

	if (g_hBlacklistDatabase != null)
	{
		delete g_hBlacklistDatabase;
		g_hBlacklistDatabase = null;
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
	
	NormalizeSteamId(steamId);

	char steamId64[32];
	if (!GetClientAuthId(client, AuthId_SteamID64, steamId64, sizeof(steamId64), true))
	{
		ReplyToCommand(client, "[全服] 无法获取你的 SteamID64，请稍后再试。");
		return Plugin_Handled;
	}

	char clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));

	if (HasUnlimitedGlobalChat(client))
	{
		InsertGlobalMessage(steamId64, clientName, message);
		return Plugin_Handled;
	}

	ReserveDailyUsage(client, steamId, steamId64, clientName, message, GetDailyLimit(client));
	return Plugin_Handled;
}

public Action Command_LFG(int client, int args)
{
	if (!g_cvEnabled.BoolValue)
	{
		ReplyToCommand(client, "[全服] 全服聊天当前未启用。");
		return Plugin_Handled;
	}

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
	{
		ReplyToCommand(client, "[全服] 只有游戏内玩家可以使用找队友功能。");
		return Plugin_Handled;
	}

	if (!g_bReady || g_hDatabase == null)
	{
		ReplyToCommand(client, "[全服] 数据库尚未连接，请稍后再试。");
		return Plugin_Handled;
	}

	char message[128];
	if (args > 0)
	{
		GetCmdArgString(message, sizeof(message));
		StripQuotes(message);
		TrimString(message);
	}

	char steamId[32];
	if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
	{
		ReplyToCommand(client, "[全服] 无法获取你的 SteamID，请稍后再试。");
		return Plugin_Handled;
	}
	
	NormalizeSteamId(steamId);

	char steamId64[32];
	if (!GetClientAuthId(client, AuthId_SteamID64, steamId64, sizeof(steamId64), true))
	{
		ReplyToCommand(client, "[全服] 无法获取你的 SteamID64，请稍后再试。");
		return Plugin_Handled;
	}

	char clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));

	char formattedMsg[256];
	FormatEx(formattedMsg, sizeof(formattedMsg), "%s_||_%s", clientName, message);

	if (HasUnlimitedGlobalChat(client))
	{
		InsertGlobalMessage(steamId64, "@LFG", formattedMsg);
		ReplyToCommand(client, "[全服] 找队友信息已发送给所有旁观玩家。");
		return Plugin_Handled;
	}

	ReserveDailyLFGUsage(client, steamId, steamId64, "@LFG", formattedMsg, GetLFGDailyLimit(client));
	return Plugin_Handled;
}

public Action Command_GlobalChatMenu(int client, int args)
{
	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	ShowGlobalChatMenu(client);
	return Plugin_Handled;
}

bool CanToggleLFGPreference(int client)
{
	return CheckCommandAccess(client, "sm_kick", ADMFLAG_KICK, true);
}

void ShowGlobalChatMenu(int client)
{
	Menu menu = new Menu(MenuHandler_GlobalChatMenu);
	menu.SetTitle("全服聊天接收设置\n普通全服: %s\n找队友提示: %s", g_bClientSeeGlobal[client] ? "接收" : "屏蔽", g_bClientSeeLFG[client] ? "接收" : "屏蔽");
	menu.AddItem("toggle_global", g_bClientSeeGlobal[client] ? "屏蔽普通全服聊天" : "接收普通全服聊天");

	if (CanToggleLFGPreference(client))
		menu.AddItem("toggle_lfg", g_bClientSeeLFG[client] ? "屏蔽找队友提示" : "接收找队友提示");
	else
		menu.AddItem("lfg_locked", "找队友提示: 仅管理员可屏蔽", ITEMDRAW_DISABLED);

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_GlobalChatMenu(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
		return 0;
	}

	if (action != MenuAction_Select)
		return 0;

	if (client <= 0 || !IsClientInGame(client))
		return 0;

	char info[32];
	menu.GetItem(item, info, sizeof(info));

	if (StrEqual(info, "toggle_global"))
	{
		g_bClientSeeGlobal[client] = !g_bClientSeeGlobal[client];
		PrintToChat(client, "\x04[全服]\x01 你已%s普通全服聊天。", g_bClientSeeGlobal[client] ? "接收" : "屏蔽");
		ShowGlobalChatMenu(client);
	}
	else if (StrEqual(info, "toggle_lfg") && CanToggleLFGPreference(client))
	{
		g_bClientSeeLFG[client] = !g_bClientSeeLFG[client];
		PrintToChat(client, "\x04[全服]\x01 你已%s找队友提示。", g_bClientSeeLFG[client] ? "接收" : "屏蔽");
		ShowGlobalChatMenu(client);
	}

	return 0;
}

bool CanReceiveGlobalMessage(int client, const char[] senderSteam64)
{
	return g_cvShowGlobal.BoolValue
		&& client > 0
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& !IsFakeClient(client)
		&& g_bClientSeeGlobal[client]
		&& !IsSenderBlockedByClient(client, senderSteam64);
}

bool CanReceiveLFGMessage(int client, const char[] senderSteam64)
{
	return g_cvShowLFG.BoolValue
		&& client > 0
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& !IsFakeClient(client)
		&& g_bClientSeeLFG[client]
		&& !IsSenderBlockedByClient(client, senderSteam64);
}

bool IsSenderBlockedByClient(int client, const char[] senderSteam64)
{
	if (!g_cvBlacklistFilter.BoolValue || senderSteam64[0] == '\0' || !IsSteam64(senderSteam64))
		return false;

	if (g_mClientBlockedSteam64[client] == null)
		return false;

	int value;
	return g_mClientBlockedSteam64[client].GetValue(senderSteam64, value);
}

bool IsSteam64(const char[] value)
{
	int len = strlen(value);
	if (len < 15)
		return false;

	for (int i = 0; i < len; i++)
	{
		if (value[i] < '0' || value[i] > '9')
			return false;
	}

	return true;
}

void ClearClientBlacklistCache(int client)
{
	if (client < 1 || client > MaxClients)
		return;

	if (g_mClientBlockedSteam64[client] != null)
	{
		delete g_mClientBlockedSteam64[client];
		g_mClientBlockedSteam64[client] = null;
	}
}

void AddClientBlockedSteam64(int client, const char[] blockedSteam64)
{
	if (client < 1 || client > MaxClients || blockedSteam64[0] == '\0')
		return;

	if (g_mClientBlockedSteam64[client] == null)
		g_mClientBlockedSteam64[client] = new StringMap();

	g_mClientBlockedSteam64[client].SetValue(blockedSteam64, 1);
}

int FindClientBySteam64(const char[] steam64)
{
	char current[32];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		if (!GetClientAuthId(i, AuthId_SteamID64, current, sizeof(current), true))
			continue;

		if (StrEqual(current, steam64))
			return i;
	}

	return 0;
}

void GetSafeBlacklistTable(char[] table, int maxlen)
{
	char raw[64];
	g_cvBlacklistTable.GetString(raw, sizeof(raw));

	int out;
	for (int i = 0; raw[i] != '\0' && out < maxlen - 1; i++)
	{
		if ((raw[i] >= 'a' && raw[i] <= 'z')
			|| (raw[i] >= 'A' && raw[i] <= 'Z')
			|| (raw[i] >= '0' && raw[i] <= '9')
			|| raw[i] == '_')
		{
			table[out++] = raw[i];
		}
	}

	table[out] = '\0';
	if (table[0] == '\0')
		strcopy(table, maxlen, "player_blocks");
}

void ConnectBlacklistDatabase()
{
	if (!g_cvBlacklistFilter.BoolValue || g_hBlacklistDatabase != null || g_bBlacklistConnecting)
		return;

	char configName[64];
	g_cvBlacklistDatabaseConfig.GetString(configName, sizeof(configName));

	g_bBlacklistConnecting = true;
	Database.Connect(SQL_OnBlacklistConnect, configName);
}

public void SQL_OnBlacklistConnect(Database database, const char[] error, any data)
{
	g_bBlacklistConnecting = false;

	if (database == null)
	{
		LogError("[global_chat] blacklist 数据库连接失败: %s", error);
		ScheduleBlacklistReconnect();
		return;
	}

	g_hBlacklistDatabase = database;
	g_hBlacklistDatabase.SetCharset("utf8mb4");
	StartBlacklistKeepAliveTimer();
	StartBlacklistRefreshTimer();
	RefreshBlacklistCache();
}

void ScheduleBlacklistReconnect()
{
	g_bBlacklistConnecting = false;
	g_bBlacklistRefreshInFlight = false;
	StopBlacklistRefreshTimer();
	StopBlacklistKeepAliveTimer();

	if (g_hBlacklistDatabase != null)
	{
		delete g_hBlacklistDatabase;
		g_hBlacklistDatabase = null;
	}

	StopBlacklistReconnectTimer();
	g_hBlacklistReconnectTimer = CreateTimer(GLOBAL_CHAT_RECONNECT_DELAY, Timer_ReconnectBlacklistDatabase);
}

void StartBlacklistRefreshTimer()
{
	StopBlacklistRefreshTimer();
	g_hBlacklistRefreshTimer = CreateTimer(g_cvBlacklistRefreshInterval.FloatValue, Timer_RefreshBlacklistCache, _, TIMER_REPEAT);
}

void StopBlacklistRefreshTimer()
{
	Handle timer = g_hBlacklistRefreshTimer;
	g_hBlacklistRefreshTimer = null;

	if (timer != null)
		delete timer;
}

void StopBlacklistReconnectTimer()
{
	Handle timer = g_hBlacklistReconnectTimer;
	g_hBlacklistReconnectTimer = null;

	if (timer != null)
		delete timer;
}

void StartBlacklistKeepAliveTimer()
{
	if (g_hBlacklistKeepAliveTimer != null)
		return;

	g_hBlacklistKeepAliveTimer = CreateTimer(GLOBAL_CHAT_KEEPALIVE_INTERVAL, Timer_BlacklistKeepAlive, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void StopBlacklistKeepAliveTimer()
{
	Handle timer = g_hBlacklistKeepAliveTimer;
	g_hBlacklistKeepAliveTimer = null;

	if (timer != null)
		delete timer;
}

public Action Timer_ReconnectBlacklistDatabase(Handle timer, any data)
{
	g_hBlacklistReconnectTimer = null;
	ConnectBlacklistDatabase();
	return Plugin_Stop;
}

public Action Timer_RefreshBlacklistCache(Handle timer, any data)
{
	RefreshBlacklistCache();
	return Plugin_Continue;
}

public Action Timer_BlacklistKeepAlive(Handle timer, any data)
{
	if (!g_cvBlacklistFilter.BoolValue || g_hBlacklistDatabase == null)
		return Plugin_Continue;

	g_hBlacklistDatabase.Query(SQL_OnBlacklistKeepAlive, "SELECT 1");
	return Plugin_Continue;
}

public void SQL_OnBlacklistKeepAlive(Database database, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[global_chat] blacklist 数据库保活失败: %s", error);
		ScheduleBlacklistReconnect();
	}
}

void RefreshBlacklistCache()
{
	if (!g_cvBlacklistFilter.BoolValue || g_hBlacklistDatabase == null || g_bBlacklistRefreshInFlight)
		return;

	char inClause[1024];
	char steam64[32];
	char escaped[64];
	int count;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		if (!GetClientAuthId(i, AuthId_SteamID64, steam64, sizeof(steam64), true))
			continue;

		g_hBlacklistDatabase.Escape(steam64, escaped, sizeof(escaped));

		if (count == 0)
			FormatEx(inClause, sizeof(inClause), "'%s'", escaped);
		else
			Format(inClause, sizeof(inClause), "%s,'%s'", inClause, escaped);

		count++;
	}

	if (count == 0)
	{
		for (int i = 1; i <= MaxClients; i++)
			ClearClientBlacklistCache(i);
		return;
	}

	char table[64];
	GetSafeBlacklistTable(table, sizeof(table));

	char query[1280];
	FormatEx(query, sizeof(query), "SELECT blocker, blocked FROM `%s` WHERE blocker IN (%s)", table, inClause);

	g_bBlacklistRefreshInFlight = true;
	g_hBlacklistDatabase.Query(SQL_OnRefreshBlacklistCache, query);
}

public void SQL_OnRefreshBlacklistCache(Database database, DBResultSet results, const char[] error, any data)
{
	g_bBlacklistRefreshInFlight = false;

	if (results == null)
	{
		LogError("[global_chat] 刷新 blacklist 缓存失败: %s", error);
		ScheduleBlacklistReconnect();
		return;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			ClearClientBlacklistCache(i);
	}

	char blocker[32];
	char blocked[32];
	while (results.FetchRow())
	{
		results.FetchString(0, blocker, sizeof(blocker));
		results.FetchString(1, blocked, sizeof(blocked));

		int client = FindClientBySteam64(blocker);
		if (client > 0)
			AddClientBlockedSteam64(client, blocked);
	}
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
	StopKeepAliveTimer();

	if (g_hDatabase != null)
	{
		delete g_hDatabase;
		g_hDatabase = null;
	}

	StopReconnectTimer();
	g_hReconnectTimer = CreateTimer(GLOBAL_CHAT_RECONNECT_DELAY, Timer_ReconnectDatabase);
}

void StartPollTimer()
{
	StopPollTimer();
	g_hPollTimer = CreateTimer(g_cvPollInterval.FloatValue, Timer_PollMessages, _, TIMER_REPEAT);
}

void StopPollTimer()
{
	Handle timer = g_hPollTimer;
	g_hPollTimer = null;

	if (timer != null)
		delete timer;
}

void StopReconnectTimer()
{
	Handle timer = g_hReconnectTimer;
	g_hReconnectTimer = null;

	if (timer != null)
		delete timer;
}

void StartKeepAliveTimer()
{
	if (g_hKeepAliveTimer != null)
		return;

	g_hKeepAliveTimer = CreateTimer(GLOBAL_CHAT_KEEPALIVE_INTERVAL, Timer_KeepAlive, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void StopKeepAliveTimer()
{
	Handle timer = g_hKeepAliveTimer;
	g_hKeepAliveTimer = null;

	if (timer != null)
		delete timer;
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
	g_hDatabase.Format(query, sizeof(query), "SELECT id, steamid, server, port, name, message FROM anne_global_chat WHERE id > %d ORDER BY id ASC LIMIT %d", g_iLastMessageId, g_cvPollBatch.IntValue);
	g_bPollInFlight = true;
	g_hDatabase.Query(SQL_OnPollMessages, query);

	return Plugin_Continue;
}

public Action Timer_KeepAlive(Handle timer, any data)
{
	if (!g_bReady || g_hDatabase == null)
		return Plugin_Continue;

	g_hDatabase.Query(SQL_OnKeepAlive, "SELECT 1");
	return Plugin_Continue;
}

public void SQL_OnKeepAlive(Database database, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[global_chat] 数据库保活失败: %s", error);
		ScheduleReconnect();
	}
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

	g_hDatabase.Query(SQL_OnCreateTitlesTable, "\
		CREATE TABLE IF NOT EXISTS `anne_global_chat_titles` ( \
			`steamid` VARCHAR(32) NOT NULL COLLATE 'utf8mb4_general_ci', \
			`title` VARCHAR(64) NOT NULL COLLATE 'utf8mb4_general_ci', \
			PRIMARY KEY (`steamid`) USING BTREE \
		) DEFAULT CHARSET='utf8mb4' ENGINE=InnoDB;");
}

public void SQL_OnCreateTitlesTable(Database database, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[global_chat] 初始化头衔表失败: %s", error);
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

public void SQL_OnCreateUsageTable(Database database, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[global_chat] 初始化使用次数表失败: %s", error);
		ScheduleReconnect();
		return;
	}

	g_hDatabase.Query(SQL_OnCreateLFGUsageTable, "\
		CREATE TABLE IF NOT EXISTS `anne_lfg_chat_usage` ( \
			`steamid` VARCHAR(32) NOT NULL COLLATE 'utf8mb4_general_ci', \
			`usage_date` DATE NOT NULL, \
			`used_count` INT UNSIGNED NOT NULL DEFAULT 0, \
			`last_used_at` DATETIME NOT NULL, \
			PRIMARY KEY (`steamid`, `usage_date`) USING BTREE, \
			KEY `idx_anne_lfg_chat_usage_date` (`usage_date`) \
		) DEFAULT CHARSET='utf8mb4' ENGINE=InnoDB;");
}

public void SQL_OnCreateLFGUsageTable(Database database, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[global_chat] 初始化找队友使用次数表失败: %s", error);
		ScheduleReconnect();
		return;
	}

	g_hDatabase.Query(SQL_OnLoadLastId, "SELECT COALESCE(MAX(id), 0) FROM anne_global_chat");
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

	g_hDatabase.Format(query, sizeof(query), "DELETE FROM anne_lfg_chat_usage WHERE usage_date < DATE_SUB(CURDATE(), INTERVAL %d DAY)", retentionDays);
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
	StartKeepAliveTimer();
	StartPollTimer();
}

bool HasUnlimitedGlobalChat(int client)
{
	return CheckCommandAccess(client, "sm_qf_unlimited", ADMFLAG_ROOT, true);
}

bool HasKickAdminGlobalChatLimit(int client)
{
	return CheckCommandAccess(client, "sm_kick", ADMFLAG_KICK, true);
}

int GetDailyLimit(int client)
{
	if (HasKickAdminGlobalChatLimit(client))
		return g_cvLimitKickAdmin.IntValue;

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

int GetLFGDailyLimit(int client)
{
	if (HasKickAdminGlobalChatLimit(client))
		return g_cvLFGLimitKickAdmin.IntValue;

	int score = 0;
	if (g_bl4dstatsAvailable && GetFeatureStatus(FeatureType_Native, "l4dstats_GetClientScore") == FeatureStatus_Available)
		score = l4dstats_GetClientScore(client);

	if (score >= 20000000)
		return g_cvLFGLimit20M.IntValue;

	if (score >= 10000000)
		return g_cvLFGLimit10M.IntValue;

	if (score >= 5000000)
		return g_cvLFGLimit5M.IntValue;

	if (score >= 1000000)
		return g_cvLFGLimit1M.IntValue;

	return g_cvLFGLimitDefault.IntValue;
}

void ReserveDailyUsage(int client, const char[] usageSteamId, const char[] messageSteamId, const char[] clientName, const char[] message, int limit)
{
	if (limit <= 0)
	{
		ReplyToCommand(client, "[全服] 你当前没有全服聊天次数。");
		return;
	}

	char safeSteamId[64];
	g_hDatabase.Escape(usageSteamId, safeSteamId, sizeof(safeSteamId));

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
	pack.WriteString(messageSteamId);
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

void ReserveDailyLFGUsage(int client, const char[] usageSteamId, const char[] messageSteamId, const char[] clientName, const char[] message, int limit)
{
	if (limit <= 0)
	{
		ReplyToCommand(client, "[全服] 你当前没有找队友次数。");
		return;
	}

	char safeSteamId[64];
	g_hDatabase.Escape(usageSteamId, safeSteamId, sizeof(safeSteamId));

	char usageDate[16];
	FormatTime(usageDate, sizeof(usageDate), "%Y-%m-%d", GetTime());

	char query[768];
	g_hDatabase.Format(query, sizeof(query), "\
		INSERT INTO anne_lfg_chat_usage (steamid, usage_date, used_count, last_used_at) \
		VALUES ('%s', '%s', 1, NOW()) \
		ON DUPLICATE KEY UPDATE \
			last_used_at = IF(used_count < %d, NOW(), last_used_at), \
			used_count = IF(used_count < %d, used_count + 1, used_count)",
		safeSteamId, usageDate, limit, limit);

	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(limit);
	pack.WriteString(messageSteamId);
	pack.WriteString(clientName);
	pack.WriteString(message);

	g_hDatabase.Query(SQL_OnReserveDailyLFGUsage, query, pack);
}

public void SQL_OnReserveDailyLFGUsage(Database database, DBResultSet results, const char[] error, DataPack pack)
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
			ReplyToCommand(client, "[全服] 检查今日找队友次数失败，请稍后再试。");

		LogError("[global_chat] 更新每日找队友次数失败: %s", error);
		ScheduleReconnect();
		return;
	}

	if (results.AffectedRows <= 0)
	{
		int client = GetClientOfUserId(userid);
		if (client > 0)
			ReplyToCommand(client, "[全服] 今日找队友次数已用完（每日 %d 次）。", limit);

		return;
	}

	InsertGlobalMessage(steamId, clientName, message);

	int client = GetClientOfUserId(userid);
	if (client > 0)
		ReplyToCommand(client, "[全服] 找队友信息已发送给所有旁观玩家。");
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
	char senderSteam64[32];
	char server[128];
	char shortServer[64];
	char name[128];
	char message[256];

	g_cvMessagePrefix.GetString(prefix, sizeof(prefix));

	while (results.FetchRow())
	{
		int id = results.FetchInt(0);
		results.FetchString(1, senderSteam64, sizeof(senderSteam64));
		results.FetchString(2, server, sizeof(server));
		results.FetchString(4, name, sizeof(name));
		results.FetchString(5, message, sizeof(message));

		if (id > g_iLastMessageId)
			g_iLastMessageId = id;

		if (StrEqual(name, "@LOGIN"))
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (CanReceiveGlobalMessage(i, senderSteam64))
					PrintToChat(i, "\x04%s %s", prefix, message);
			}
		}
		else if (StrEqual(name, "@LFG"))
		{
			char parts[2][128];
			int count = ExplodeString(message, "_||_", parts, sizeof(parts), sizeof(parts[]));
			if (count < 1) continue;

			for (int i = 1; i <= MaxClients; i++)
			{
				if (CanReceiveLFGMessage(i, senderSteam64) && GetClientTeam(i) == 1)
				{
					if (count < 2 || parts[1][0] == '\0')
					{
						PrintCenterText(i, "%s 玩家在 %s 召唤队友", parts[0], server);
						PrintToChat(i, "\x04%s \x05%s \x01玩家在 \x03%s \x01召唤队友", prefix, parts[0], server);
					}
					else
					{
						PrintCenterText(i, "%s 玩家在 %s 召唤队友", parts[0], server);
						PrintToChat(i, "\x04%s \x05%s \x01玩家在 \x03%s \x01召唤队友\n\x01留言: \x05%s", prefix, parts[0], server, parts[1]);
					}
				}
			}
		}
		else if (StrEqual(name, "@BROADCAST"))
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (CanReceiveGlobalMessage(i, senderSteam64))
					PrintToChat(i, "\x01%s", message);
			}
		}
		else
		{
			GetShortServerName(server, shortServer, sizeof(shortServer));
			for (int i = 1; i <= MaxClients; i++)
			{
				if (CanReceiveGlobalMessage(i, senderSteam64))
					PrintToChat(i, "\x04%s \x03[%s] \x05%s\x01: %s", prefix, shortServer, name, message);
			}
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (!g_cvEnabled.BoolValue || !g_bReady || g_hDatabase == null)
		return;

	if (IsFakeClient(client))
		return;

	char steamId[32];
	if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
		return;
	
	NormalizeSteamId(steamId);

	char steamId64[32];
	if (!GetClientAuthId(client, AuthId_SteamID64, steamId64, sizeof(steamId64), true))
		return;

	RefreshBlacklistCache();

	char query[256];
	char safeSteamId[64];
	g_hDatabase.Escape(steamId, safeSteamId, sizeof(safeSteamId));
	
	g_hDatabase.Format(query, sizeof(query), "SELECT title FROM anne_global_chat_titles WHERE steamid = '%s'", safeSteamId);
	
	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteString(steamId64);
	
	g_hDatabase.Query(SQL_OnCheckLoginTitle, query, pack);
}

public void SQL_OnCheckLoginTitle(Database database, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();
	int userid = pack.ReadCell();
	char steamId64[32];
	pack.ReadString(steamId64, sizeof(steamId64));
	delete pack;

	if (results == null)
	{
		LogError("[global_chat] 检查玩家头衔失败: %s", error);
		return;
	}

	if (results.FetchRow())
	{
		int client = GetClientOfUserId(userid);
		if (client > 0 && IsClientInGame(client))
		{
			char title[64];
			results.FetchString(0, title, sizeof(title));

			char clientName[MAX_NAME_LENGTH];
			GetClientName(client, clientName, sizeof(clientName));

			char hostname[128];
			char shortServer[64];
			GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
			GetShortServerName(hostname, shortServer, sizeof(shortServer));

			char formattedMsg[256];
			FormatEx(formattedMsg, sizeof(formattedMsg), "\x01%s \x05%s \x01在 \x03%s \x01上线了！", title, clientName, shortServer);

			InsertGlobalMessage(steamId64, "@LOGIN", formattedMsg);
		}
	}
}

void NormalizeSteamId(char[] steamId)
{
	// 规范化 SteamID，强制将前缀统一替换为 STEAM_0:1:
	if (StrContains(steamId, "STEAM_") == 0)
	{
		steamId[6] = '0';
		steamId[8] = '1';
	}
}
