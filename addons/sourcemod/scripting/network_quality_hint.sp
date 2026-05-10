#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.0.1"
#define CHAT_TAG "\x04[网络]\x01"

ConVar
	g_hEnable,
	g_hCheckInterval,
	g_hPingLimit,
	g_hLossLimit,
	g_hChokeLimit,
	g_hBadSamples,
	g_hWarnCooldown,
	g_hIpPageUrl,
	g_hIntroDelay;

Handle g_hTimer;

bool g_bEnable;
float g_fCheckInterval;
int g_iPingLimit;
float g_fLossLimit;
float g_fChokeLimit;
int g_iBadSamples;
float g_fWarnCooldown;
float g_fIntroDelay;
char g_sIpPageUrl[192];

int g_iBadCount[MAXPLAYERS + 1];
float g_fLastWarnAt[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Network Quality Hint",
	author = "Anne",
	description = "Checks ping/loss/choke and reminds players to reconnect from the server IP page.",
	version = PLUGIN_VERSION,
	url = "https://github.com/fantasylidong/CompetitiveWithAnne"
};

public void OnPluginStart()
{
	CreateConVar("nqh_version", PLUGIN_VERSION, "Network Quality Hint version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_hEnable = CreateConVar("nqh_enable", "1", "Enable network quality checks.", _, true, 0.0, true, 1.0);
	g_hCheckInterval = CreateConVar("nqh_check_interval", "20.0", "Seconds between network quality checks.", _, true, 5.0, true, 300.0);
	g_hPingLimit = CreateConVar("nqh_ping_limit", "120", "Warn when ping is higher than this value in ms. -1 disables ping checks.", _, true, -1.0);
	g_hLossLimit = CreateConVar("nqh_loss_limit", "2.0", "Warn when packet loss is higher than this percent. -1 disables loss checks.", _, true, -1.0);
	g_hChokeLimit = CreateConVar("nqh_choke_limit", "5.0", "Warn when choke is higher than this percent. -1 disables choke checks.", _, true, -1.0);
	g_hBadSamples = CreateConVar("nqh_bad_samples", "3", "Consecutive bad samples required before warning.", _, true, 1.0, true, 20.0);
	g_hWarnCooldown = CreateConVar("nqh_warn_cooldown", "180.0", "Seconds before warning the same player again.", _, true, 30.0, true, 1800.0);
	g_hIpPageUrl = CreateConVar("nqh_ip_page_url", "https://anne.trygek.com/ip.php", "Web page that lists server IPs and copyable connect commands.");
	g_hIntroDelay = CreateConVar("nqh_intro_delay", "25.0", "Seconds after join before printing a one-time status hint. 0 disables it.", _, true, 0.0, true, 300.0);

	RegConsoleCmd("sm_net", Command_NetStatus, "Show your network status.");
	RegConsoleCmd("sm_ping", Command_NetStatus, "Show your network status.");
	RegConsoleCmd("sm_loss", Command_NetStatus, "Show your network status.");

	HookConVarChange(g_hEnable, OnCvarChanged);
	HookConVarChange(g_hCheckInterval, OnCvarChanged);
	HookConVarChange(g_hPingLimit, OnCvarChanged);
	HookConVarChange(g_hLossLimit, OnCvarChanged);
	HookConVarChange(g_hChokeLimit, OnCvarChanged);
	HookConVarChange(g_hBadSamples, OnCvarChanged);
	HookConVarChange(g_hWarnCooldown, OnCvarChanged);
	HookConVarChange(g_hIpPageUrl, OnCvarChanged);
	HookConVarChange(g_hIntroDelay, OnCvarChanged);

	ReadCvars();
	RestartTimer();
	AutoExecConfig(true, "network_quality_hint");
}

public void OnMapStart()
{
	RestartTimer();
}

public void OnMapEnd()
{
	StopTimer();
}

public void OnClientPutInServer(int client)
{
	g_iBadCount[client] = 0;
	g_fLastWarnAt[client] = 0.0;

	if (g_bEnable && g_fIntroDelay > 0.0 && !IsFakeClient(client)) {
		CreateTimer(g_fIntroDelay, Timer_IntroHint, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnClientDisconnect(int client)
{
	g_iBadCount[client] = 0;
	g_fLastWarnAt[client] = 0.0;
}

void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	float oldInterval = g_fCheckInterval;

	ReadCvars();

	if (convar == g_hEnable || convar == g_hCheckInterval || oldInterval != g_fCheckInterval) {
		RestartTimer();
	}
}

void ReadCvars()
{
	g_bEnable = g_hEnable.BoolValue;
	g_fCheckInterval = g_hCheckInterval.FloatValue;
	g_iPingLimit = g_hPingLimit.IntValue;
	g_fLossLimit = g_hLossLimit.FloatValue;
	g_fChokeLimit = g_hChokeLimit.FloatValue;
	g_iBadSamples = g_hBadSamples.IntValue;
	g_fWarnCooldown = g_hWarnCooldown.FloatValue;
	g_fIntroDelay = g_hIntroDelay.FloatValue;

	g_hIpPageUrl.GetString(g_sIpPageUrl, sizeof(g_sIpPageUrl));
}

void RestartTimer()
{
	StopTimer();

	if (g_bEnable) {
		g_hTimer = CreateTimer(g_fCheckInterval, Timer_CheckClients, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

void StopTimer()
{
	if (g_hTimer != null) {
		KillTimer(g_hTimer);
		g_hTimer = null;
	}
}

Action Timer_IntroHint(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if (IsHumanInGame(client)) {
		PrintClientStatus(client, false);
	}

	return Plugin_Stop;
}

Action Timer_CheckClients(Handle timer)
{
	if (!g_bEnable) {
		return Plugin_Continue;
	}

	for (int client = 1; client <= MaxClients; client++) {
		if (!IsHumanInGame(client)) {
			continue;
		}

		CheckClient(client);
	}

	return Plugin_Continue;
}

void CheckClient(int client)
{
	int ping = GetClientPingMs(client);
	float loss = GetClientLossPct(client);
	float choke = GetClientChokePct(client);

	bool badPing = g_iPingLimit >= 0 && ping > g_iPingLimit;
	bool badLoss = g_fLossLimit >= 0.0 && loss > g_fLossLimit;
	bool badChoke = g_fChokeLimit >= 0.0 && choke > g_fChokeLimit;

	if (!badPing && !badLoss && !badChoke) {
		g_iBadCount[client] = 0;
		return;
	}

	g_iBadCount[client]++;

	if (g_iBadCount[client] < g_iBadSamples) {
		return;
	}

	float now = GetEngineTime();
	if (now - g_fLastWarnAt[client] < g_fWarnCooldown) {
		return;
	}

	g_fLastWarnAt[client] = now;
	PrintNetworkWarning(client, ping, loss, choke, badPing, badLoss, badChoke);
}

Action Command_NetStatus(int client, int args)
{
	if (client <= 0) {
		ReplyToCommand(client, "[Network] This command is only available in game.");
		return Plugin_Handled;
	}

	if (!IsClientInGame(client)) {
		return Plugin_Handled;
	}

	PrintClientStatus(client, true);
	return Plugin_Handled;
}

void PrintClientStatus(int client, bool includeRouteHint)
{
	int ping = GetClientPingMs(client);
	float loss = GetClientLossPct(client);
	float choke = GetClientChokePct(client);

	PrintToChat(client, "%s 当前网络：ping \x05%dms\x01，loss \x05%.2f%%\x01，choke \x05%.2f%%\x01。", CHAT_TAG, ping, loss, choke);

	if (includeRouteHint) {
		char pageUrl[512];
		BuildServerPageUrl(pageUrl, sizeof(pageUrl));
		PrintToChat(client, "%s 如果延迟或丢包异常，请打开 IP 页面复制当前服务器地址后重新连接：\x04%s\x01", CHAT_TAG, pageUrl);
	}
}

void PrintNetworkWarning(int client, int ping, float loss, float choke, bool badPing, bool badLoss, bool badChoke)
{
	char reason[128];
	char pageUrl[512];
	BuildReason(reason, sizeof(reason), badPing, badLoss, badChoke);
	BuildServerPageUrl(pageUrl, sizeof(pageUrl));

	PrintToChat(client, "%s 检测到你的网络状态异常：\x05%s\x01。当前 ping \x05%dms\x01，loss \x05%.2f%%\x01，choke \x05%.2f%%\x01。", CHAT_TAG, reason, ping, loss, choke);
	PrintToChat(client, "%s 请打开 IP 页面，复制当前服务器对应的 connect 命令，粘贴到控制台重新连接：\x04%s\x01", CHAT_TAG, pageUrl);
	PrintToChat(client, "%s 三线服务器请优先使用网页展示的分流入口，避免从收藏或历史记录走错线路。", CHAT_TAG);
}

void BuildServerPageUrl(char[] buffer, int maxlen)
{
	char hostname[192];
	char encoded[384];

	ConVar cvarHostname = FindConVar("hostname");
	if (cvarHostname == null) {
		strcopy(buffer, maxlen, g_sIpPageUrl);
		return;
	}

	cvarHostname.GetString(hostname, sizeof(hostname));
	UrlEncode(hostname, encoded, sizeof(encoded));

	if (StrContains(g_sIpPageUrl, "?", false) == -1) {
		Format(buffer, maxlen, "%s?server=%s", g_sIpPageUrl, encoded);
	} else {
		Format(buffer, maxlen, "%s&server=%s", g_sIpPageUrl, encoded);
	}
}

void BuildReason(char[] buffer, int maxlen, bool badPing, bool badLoss, bool badChoke)
{
	buffer[0] = '\0';

	if (badPing) {
		StrCat(buffer, maxlen, "ping过高");
	}

	if (badLoss) {
		if (buffer[0] != '\0') {
			StrCat(buffer, maxlen, " / ");
		}
		StrCat(buffer, maxlen, "丢包过高");
	}

	if (badChoke) {
		if (buffer[0] != '\0') {
			StrCat(buffer, maxlen, " / ");
		}
		StrCat(buffer, maxlen, "choke过高");
	}
}

int GetClientPingMs(int client)
{
	return RoundToNearest(GetClientAvgLatency(client, NetFlow_Outgoing) * 1000.0);
}

float GetClientLossPct(int client)
{
	return GetNetworkPct(GetClientAvgLoss(client, NetFlow_Outgoing));
}

float GetClientChokePct(int client)
{
	return GetNetworkPct(GetClientAvgChoke(client, NetFlow_Outgoing));
}

float GetNetworkPct(float value)
{
	if (value < 0.0) {
		return 0.0;
	}

	return value * 100.0;
}

bool IsHumanInGame(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}

void UrlEncode(const char[] input, char[] output, int maxlen)
{
	int pos = 0;

	for (int i = 0; input[i] != '\0' && pos < maxlen - 1; i++) {
		int c = input[i] & 0xff;

		if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.' || c == '~') {
			output[pos++] = input[i];
		} else if (c == ' ') {
			if (pos < maxlen - 1) {
				output[pos++] = '+';
			}
		} else if (pos < maxlen - 3) {
			Format(output[pos], maxlen - pos, "%%%02X", c);
			pos += 3;
		}
	}

	output[pos] = '\0';
}
