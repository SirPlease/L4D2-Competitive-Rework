#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <geoip>

#define PLUGIN_VERSION "1.3"

StringMap
	g_aCommands;

ConVar
	g_hHostport;

char
	g_sChatFilePath[PLATFORM_MAX_PATH];

static const char
	g_sCommands[][] =
	{
		"say",
		"say_team",
		"callvote",
		"unpause",
		"setpause",
		"choose_opendoor",
		"choose_closedoor",
		"go_away_from_keyboard"
	};

public Plugin myinfo = 
{
	name = "SaveChat",
	author = "citkabuto, sorallll",
	description = "Records player chat messages to a file",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=117116"
}

public void OnPluginStart()
{
	vInitCommands();

	char sDate[21];
	FormatTime(sDate, sizeof sDate, "%d%m%y", -1);
	BuildPath(Path_SM, g_sChatFilePath, sizeof g_sChatFilePath, "/logs/chat%s-%i.log", sDate, (g_hHostport = FindConVar("hostport")).IntValue);

	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);

	AddCommandListener(CommandListener, "");
}

void vInitCommands()
{
	g_aCommands = new StringMap();
	for(int i; i < sizeof g_sCommands; i++)
		g_aCommands.SetValue(g_sCommands[i], i);
}

Action CommandListener(int client, char[] command, int argc)
{
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;
/*
	if (strncmp(command, "sm", 2) != 0) {
		static int value;
		StringToLowerCase(command);
		if (!g_aCommands.GetValue(command, value))
		{
			return Plugin_Continue;
		}
			
	}
*/	
	static char sTime[16];
	static char sTeamName[12];
	static char sMessage[255];

	FormatTime(sTime, sizeof sTime, "%H:%M:%S", -1);
	GetTeamName(GetClientTeam(client), sTeamName, sizeof sTeamName);
	GetCmdArgString(sMessage, sizeof sMessage);
	StripQuotes(sMessage);

	Format(sMessage, sizeof sMessage, "[%s] [%s] %N: %s %s", sTime, sTeamName, client, command, sMessage);
	vSaveMessage(sMessage);
	return Plugin_Continue;
}

public void OnMapEnd()
{
	char sTime[32];
	char sMessage[255];

	FormatTime(sTime, sizeof sTime, "%d/%m/%Y %H:%M:%S", -1);

	GetCurrentMap(sMessage, sizeof sMessage);
	Format(sMessage, sizeof sMessage, "[%s] --- 地图结束: %s ---", sTime, sMessage);

	vSaveMessage("--=================================================================--");
	vSaveMessage(sMessage);
	vSaveMessage("--=================================================================--");
}

public void OnMapStart()
{
	char sTime[32];
	char sMessage[255];

	FormatTime(sMessage, sizeof sMessage, "%d%m%y", -1);
	BuildPath(Path_SM, g_sChatFilePath, sizeof g_sChatFilePath, "/logs/chat%s-%i.log", sMessage, g_hHostport.IntValue);

	FormatTime(sTime, sizeof sTime, "%d/%m/%Y %H:%M:%S", -1);

	GetCurrentMap(sMessage, sizeof sMessage);
	Format(sMessage, sizeof sMessage, "[%s] --- 地图开始: %s ---", sTime, sMessage);

	vSaveMessage("--=================================================================--");
	vSaveMessage(sMessage);
	vSaveMessage("--=================================================================--");
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client))
		return;

	char sTime[16];
	char sCountry[3];
	char sPlayerIP[32];
	char sMessage[255];

	if (!GetClientIP(client, sPlayerIP, sizeof sPlayerIP, true)) 
		strcopy(sCountry, sizeof sCountry, "  ");
	else {
		if (!GeoipCode2(sPlayerIP, sCountry)) 
			strcopy(sCountry, sizeof sCountry, "  ");
	}

	FormatTime(sTime, sizeof sTime, "%H:%M:%S", -1);
	FormatEx(sMessage, sizeof sMessage, "[%s] [%s] %L 加入游戏 (%s)", sTime, sCountry, client, sPlayerIP);
	vSaveMessage(sMessage);
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	char sTime[32];
	char sMessage[255];

	FormatTime(sTime, sizeof sTime, "%d/%m/%Y %H:%M:%S", -1);

	GetCurrentMap(sMessage, sizeof sMessage);
	Format(sMessage, sizeof sMessage, "[%s] --- 回合结束: %s ---", sTime, sMessage);

	vSaveMessage("--=================================================================--");
	vSaveMessage(sMessage);
	vSaveMessage("--=================================================================--");
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	char sTime[32];
	char sMessage[255];

	FormatTime(sTime, sizeof sTime, "%d/%m/%Y %H:%M:%S", -1);

	GetCurrentMap(sMessage, sizeof sMessage);
	Format(sMessage, sizeof sMessage, "[%s] --- 回合开始: %s ---", sTime, sMessage);

	vSaveMessage("--=================================================================--");
	vSaveMessage(sMessage);
	vSaveMessage("--=================================================================--");
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || IsFakeClient(client))
		return;

	char sTime[16];
	char sMessage[255];

	FormatTime(sTime, sizeof sTime, "%H:%M:%S", -1);
	event.GetString("reason", sMessage, sizeof sMessage);
	Format(sMessage, sizeof sMessage, "[%s] %L 离开游戏 (reason: %s)", sTime, client, sMessage);
	vSaveMessage(sMessage);
}

void vSaveMessage(const char[] sMessage)
{
	File file = OpenFile(g_sChatFilePath, "a");
	file.WriteLine("%s", sMessage);
	file.Flush();
	delete file;
}
