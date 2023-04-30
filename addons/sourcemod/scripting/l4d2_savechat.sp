/*
 ----------------------------------------------------------------
 Plugin      : SaveChat 
 Author      : citkabuto
 Game        : Any Source game
 Description : Will record all player messages to a file
 ================================================================
 Date       Version  Description
 ================================================================
 23/Feb/10  1.2.1    - Fixed bug with player team id
 15/Feb/10  1.2.0    - Now records team name when using cvar
                            sm_record_detail 
 01/Feb/10  1.1.1    - Fixed bug to prevent errors when using 
                       HLSW (client index 0 is invalid)
 31/Jan/10  1.1.0    - Fixed date format on filename
                       Added ability to record player info
                       when connecting using cvar:
                            sm_record_detail (0=none,1=all:def:1)
 28/Jan/10  1.0.0    - Initial Version 
 ----------------------------------------------------------------
*/

#pragma semicolon 1
//強制1.7以後的新語法
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <geoip.inc>
#include <string.inc>

#define PLUGIN_VERSION "SaveChat_1.2.1"

static char chatFile[128];
Handle fileHandle = null;
ConVar sc_record_detail = null;

public Plugin myinfo = 
{
	name = "SaveChat",
	author = "citkabuto",
	description = "Records player chat messages to a file",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=117116"
}

public void OnPluginStart()
{
	char date[21];
	char logFile[100];

	/* Register CVars */
	CreateConVar("sm_savechat_version", PLUGIN_VERSION, "记录STEAM32位ID插件的版本.", FCVAR_DONTRECORD|FCVAR_REPLICATED);

	sc_record_detail = CreateConVar("sc_record_detail", "1", "记录玩家的STEAM32位ID和IP地址?  0=禁用, 1=启用.", FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d2_savechat");
	
	/* Say commands */
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);

	/* Format date for log filename */
	FormatTime(date, sizeof(date), "%y%m%d", -1);

	/* Create name of logfile to use */
	Format(logFile, sizeof(logFile), "/logs/chat%s.log", date);
	BuildPath(Path_SM, chatFile, PLATFORM_MAX_PATH, logFile);
}

/*
 * Capture player chat and record to file
 */
public Action Command_Say(int client, int args)
{
	LogChat(client, args, false);
	return Plugin_Continue;
}

/*
 * Capture player team chat and record to file
 */
public Action Command_SayTeam(int client, int args)
{
	LogChat(client, args, true);
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	/* Only record player detail if CVAR set */
	if(GetConVarInt(sc_record_detail) != 1)
		return;

	if(IsFakeClient(client)) 
		return;

	char msg[2048];
	char time[21];
	char country[3];
	char steamID[128];
	char playerIP[50];
	
	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));

	/* Get 2 digit country code for current player */
	if(GetClientIP(client, playerIP, sizeof(playerIP), true) == false)
	{
		country   = "  ";
	}
	else
	{
		if(GeoipCode2(playerIP, country) == false)
		{
			country = "  ";
		}
	}

	FormatTime(time, sizeof(time), "%H:%M:%S", -1);
	Format(msg, sizeof(msg), "[%s] [%s] %-35N 已加入: (%s | %s)", time, country, client, steamID, playerIP);

	SaveMessage(msg);
}

/*
 * Extract all relevant information and format 
 */
public void LogChat(int client, int args, bool teamchat)
{
	char msg[2048];
	char time[21];
	char text[1024];
	char country[3];
	char playerIP[50];
	char teamName[20];

	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);

	if(client == 0)
	{
		/* Don't try and obtain client country/team if this is a console message */
		Format(country, sizeof(country), "  ");
		Format(teamName, sizeof(teamName), "");
	}
	else
	{
		/* Get 2 digit country code for current player */
		if(GetClientIP(client, playerIP, sizeof(playerIP), true) == false)
		{
			country   = "  ";
		}
		else
		{
			if(GeoipCode2(playerIP, country) == false)
			{
				country = "  ";
			}
		}
		GetTeamName(GetClientTeam(client), teamName, sizeof(teamName));
	}
	FormatTime(time, sizeof(time), "%H:%M:%S", -1);

	if(GetConVarInt(sc_record_detail) == 1)
	{
		Format(msg, sizeof(msg), "[%s] [%s] [%-11s] %-35N :%s %s", time, country, teamName, client, teamchat == true ? " (TEAM)" : "", text);
	}
	else
	{
		Format(msg, sizeof(msg), "[%s] [%s] %-35N :%s %s", time, country, client, teamchat == true ? " (TEAM)" : "", text);
	}

	SaveMessage(msg);
}

/*
 * Log a map transition
 */
public void OnMapStart()
{
	char map[128];
	char msg[1024];
	char date[32];
	char time[32];
	char logFile[128];

	GetCurrentMap(map, sizeof(map));

	/* The date may have rolled over, so update the logfile name here */
	FormatTime(date, sizeof(date), "%y%m%d", -1);
	Format(logFile, sizeof(logFile), "/logs/chat%s.log", date);
	BuildPath(Path_SM, chatFile, PLATFORM_MAX_PATH, logFile);

	FormatTime(time, sizeof(time), "%Y-%m-%d %H:%M:%S", -1);
	Format(msg, sizeof(msg), "[%s] --- 新的地图开始: %s ---", time, map);

	SaveMessage("--=================================================================--");
	SaveMessage(msg);
	SaveMessage("--=================================================================--");
}

/*
 * Log the message to file
 */
public void SaveMessage(const char[] message)
{
	fileHandle = OpenFile(chatFile, "a");  /* Append */
	WriteFileLine(fileHandle, message);
	CloseHandle(fileHandle);
}

