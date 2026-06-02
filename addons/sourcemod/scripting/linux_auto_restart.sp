#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define VERSION "0.4"

ConVar
	sv_hibernate_when_empty,
	sb_all_bot_game,
	g_cvDelayTime;

float
	g_fDelayTime;

public Plugin myinfo =
{
	name = "L4D2 Auto restart",
	author = "Dragokas, Harry Potter, fdxx",
	description = "Auto restart server when the last player disconnects from the server. Only support Linux system",
	version = VERSION,
}

public void OnPluginStart()
{
	sv_hibernate_when_empty = FindConVar("sv_hibernate_when_empty");
	sb_all_bot_game = FindConVar("sb_all_bot_game");

	CreateConVar("l4d2_auto_restart_version", VERSION, "插件版本", FCVAR_NONE | FCVAR_DONTRECORD);
	g_cvDelayTime = CreateConVar("l4d2_auto_restart_delay", "30.0", "Restart grace period (in sec.)", FCVAR_NOTIFY);
	g_fDelayTime = g_cvDelayTime.FloatValue;
	g_cvDelayTime.AddChangeHook(OnConVarChanged);

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	RegAdminCmd("sm_restart", Cmd_RestartServer, ADMFLAG_ROOT);

	//AutoExecConfig(true, "l4d2_auto_restart");
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_fDelayTime = g_cvDelayTime.FloatValue;
}

Action Cmd_RestartServer(int client, int args)
{
	if(client == 0)return Plugin_Handled;
	LogToFilePlus("%N手动重启服务器...", client);
	RestartServer();
	return Plugin_Handled;
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0 || !IsFakeClient(client))
	{
		char sNetworkid[4];
		event.GetString("networkid", sNetworkid, sizeof(sNetworkid));
		if (!strcmp(sNetworkid, "BOT", false)) 
			return;
			
		if (!HaveRealPlayer(client))
		{
			sv_hibernate_when_empty.IntValue = 0;
			sb_all_bot_game.IntValue = 1;
			CreateTimer(g_fDelayTime, RestServer_Timer);
			LogToFilePlus("服务器已没有真实玩家, %.1f 秒后重启服务器", g_fDelayTime);
		}
	}
}

Action RestServer_Timer(Handle timer)
{
	if (!HaveRealPlayer())
	{
		LogToFilePlus("自动重启服务器...");
		RestartServer();
	}
	else LogToFilePlus("服务器重启失败, 还有真实玩家");
	return Plugin_Continue;
}

void RestartServer()
{
	UnloadAccelerator();
	SetCommandFlags("crash", GetCommandFlags("crash") &~ FCVAR_CHEAT);
	ServerCommand("crash");
}

bool HaveRealPlayer(int iExclude = 0)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != iExclude && IsClientConnected(i) && !IsFakeClient(i))
		{
			return true;
		}
	}
	return false;
}

void UnloadAccelerator()
{
	int Id = GetAcceleratorId();
	if (Id != -1)
	{
		ServerCommand("sm exts unload %i 0", Id);
		ServerExecute();
	}
}

//by sorallll
int GetAcceleratorId()
{
	char sBuffer[512];
	ServerCommandEx(sBuffer, sizeof(sBuffer), "sm exts list");
	int index = SplitString(sBuffer, "] Accelerator (", sBuffer, sizeof(sBuffer));
	if(index == -1)
		return -1;

	for(int i = strlen(sBuffer); i >= 0; i--)
	{
		if(sBuffer[i] == '[')
			return StringToInt(sBuffer[i + 1]);
	}

	return -1;
}

void LogToFilePlus(const char[] sMsg, any ...)
{
	static char sDate[32], sLogPath[PLATFORM_MAX_PATH];
	static char sBuffer[256];

	FormatTime(sDate, sizeof(sDate), "%Y%m%d");
	BuildPath(Path_SM, sLogPath, sizeof(sLogPath), "logs/%s_logging.log", sDate);
	VFormat(sBuffer, sizeof(sBuffer), sMsg, 2);

	LogToFileEx(sLogPath, "%s", sBuffer);
}