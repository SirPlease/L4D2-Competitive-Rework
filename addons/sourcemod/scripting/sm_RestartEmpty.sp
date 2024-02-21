#define PLUGIN_VERSION "2.6"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <regex>

#define CVAR_FLAGS			FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[ANY] Restart Empty Server (or Map)", 
	author = "Alex Dragokas", 
	description = "Restart server (or change the map) when all players leave the game",
	version = PLUGIN_VERSION, 
	url = "https://github.com/dragokas/"
};

ConVar g_ConVarEnable;
ConVar g_ConVarMethod;
ConVar g_ConVarDelay;
ConVar g_ConVarHibernate;
ConVar g_ConVarUnloadExtNum;
ConVar g_ConVarMinPeriodHours;
ConVar g_ConVarLimitRebootHourStart;
ConVar g_ConVarLimitRebootHourEnd;
ConVar g_ConVarForceRebootHourStart;
ConVar g_ConVarForceRebootHourEnd;
ConVar g_ConVarDeltaUTC;
ConVar g_ConVarStartRandomMap;

bool g_bCvarEnabled;
bool g_bStartRandomMap;
bool g_bServerStarted;
int g_iCvarMethod;
int g_iCvarUnloadExtNum;
int g_iCvarMinPeriodHours;
int g_iCVarLimitRebootHourStart;
int g_iCVarLimitRebootHourEnd;
int g_iCVarForceRebootHourStart;
int g_iCVarForceRebootHourEnd;
int g_iHybernateInitial;
float g_fCvarDeltaUTC;
float g_fCvarDelay;
int g_iPluginRunDate;
char g_sMapListPath[PLATFORM_MAX_PATH];
char g_sLogPath[PLATFORM_MAX_PATH];
Handle hPluginMe;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	hPluginMe = myself;
	g_iPluginRunDate = GetTime();
	if( late )
	{
		g_bServerStarted = true;
	}
	return APLRes_Success;
}

int GetPluginWorkDurationHours()
{
	return (GetTime() - g_iPluginRunDate) / 3600;
}

public void OnPluginStart()
{
	CreateConVar("sm_restart_empty_version", PLUGIN_VERSION, "Plugin Version", CVAR_FLAGS | FCVAR_DONTRECORD);
	
	( g_ConVarEnable 				= CreateConVar("sm_restart_empty_enable", 					"1", 	"Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS)).AddChangeHook(OnCvarChanged);
	( g_ConVarMethod 				= CreateConVar("sm_restart_empty_method", 					"2", 	"When server is empty, what to do? 1 - _restart, 2 - crash (use if method # 1 is not work), 3 - just change map", CVAR_FLAGS)).AddChangeHook(OnCvarChanged);
	( g_ConVarDelay 				= CreateConVar("sm_restart_empty_delay", 					"1.0", 	"Grace period (in sec.) waiting for new player to join until actually decide to restart the server", CVAR_FLAGS)).AddChangeHook(OnCvarChanged);
	( g_ConVarUnloadExtNum 			= CreateConVar("sm_restart_empty_unload_ext_num", 			"0", 	"If you have Accelerator extension, you need specify here order number of this extension in the list: sm exts list", CVAR_FLAGS)).AddChangeHook(OnCvarChanged);
	( g_ConVarMinPeriodHours		= CreateConVar("sm_restart_empty_min_period", 				"0", 	"Minimum period (in hours) this plugin should wait before the next restarting is allowed (0 - disable, 24 - allow once per day)", CVAR_FLAGS)).AddChangeHook(OnCvarChanged);
	( g_ConVarLimitRebootHourStart 	= CreateConVar("sm_restart_empty_limit_hour_start", 		"0", 	"Allow rebooting to be started from this hour only (paired with \"*_end\" ConVar)", CVAR_FLAGS)).AddChangeHook(OnCvarChanged);
	( g_ConVarLimitRebootHourEnd 	= CreateConVar("sm_restart_empty_limit_hour_end", 			"24", 	"Allow rebooting until this hour only (paired with \"*_start\" ConVar)", CVAR_FLAGS)).AddChangeHook(OnCvarChanged);
	( g_ConVarForceRebootHourStart 	= CreateConVar("sm_restart_empty_force_hour_start", 		"-1", 	"Start hour for force rebooting (if last reboot happened > 24 hours ago) and somebody leaves during this hour (paired with \"*_end\" ConVar) (-1 to disable)", CVAR_FLAGS)).AddChangeHook(OnCvarChanged);
	( g_ConVarForceRebootHourEnd 	= CreateConVar("sm_restart_empty_force_hour_end", 			"-1", 	"End hour for force rebooting (if last reboot happened > 24 hours ago) and somebody leaves during this hour (paired with \"*_start\" ConVar) (-1 to disable)", CVAR_FLAGS)).AddChangeHook(OnCvarChanged);
	( g_ConVarDeltaUTC 				= CreateConVar("sm_restart_empty_utc_delta", 				"0.0", 	"If your server has incorrect time, you can set UTC correction hours here (they will be appended to a server time)", CVAR_FLAGS)).AddChangeHook(OnCvarChanged);
	( g_ConVarStartRandomMap 		= CreateConVar("sm_restart_empty_server_start_changemap", 	"0", 	"When server restarted, change map to the random one from the file: data/restart_empty_maps.txt (1 - Yes / 0 - No)", CVAR_FLAGS)).AddChangeHook(OnCvarChanged);
	
	AutoExecConfig(true, "sm_restart_empty");
	
	g_ConVarHibernate = FindConVar("sv_hibernate_when_empty");
	
	BuildPath(Path_SM, g_sMapListPath, 	sizeof(g_sMapListPath), "data/restart_empty_maps.txt");
	BuildPath(Path_SM, g_sLogPath, 		sizeof(g_sLogPath), 	"logs/restart.log");
	
	RemoveCrashLog(); // if "CRASH" folder exists, removes last crash that happen due to server restart
	
	RegAdminCmd("sm_restarter_ctime", 		CmdTime, 		ADMFLAG_ROOT, "Check the server time taking into account UTC delta ConVar");
	RegAdminCmd("sm_restarter_accelerator", CmdAccelerator, ADMFLAG_ROOT, "Show auto-detected order number of Accelerator extension");
	
	GetCvars();
}

Action CmdTime(int client, int args)
{
	char s[16];
	int iUnix = GetTime() + RoundToCeil(g_fCvarDeltaUTC * 3600.0);
	FormatTime(s, sizeof(s), "%H:%M", iUnix);
	ReplyToCommand(client, s);
	return Plugin_Handled;
}

Action CmdAccelerator(int client, int args)
{
	int iAccelExtNum;
	if( (iAccelExtNum = GetAcceleratorExtNumberFromCmd()) != 0 )
	{
		ReplyToCommand(client, "Found Accelerator ext. under number: %i", iAccelExtNum);
	}
	else {
		ReplyToCommand(client, "Coudn't found Accelerator extension!\nUse ConVar sm_restart_empty_unload_ext_num instead.");
	}
	return Plugin_Handled;
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarEnabled = g_ConVarEnable.BoolValue;
	g_iCvarMethod = g_ConVarMethod.IntValue;
	g_fCvarDelay = g_ConVarDelay.FloatValue;
	g_iCvarUnloadExtNum = g_ConVarUnloadExtNum.IntValue;
	g_iCvarMinPeriodHours = g_ConVarMinPeriodHours.IntValue;
	g_iCVarLimitRebootHourStart = g_ConVarLimitRebootHourStart.IntValue;
	g_iCVarLimitRebootHourEnd = g_ConVarLimitRebootHourEnd.IntValue;
	g_iCVarForceRebootHourStart = g_ConVarForceRebootHourStart.IntValue;
	g_iCVarForceRebootHourEnd = g_ConVarForceRebootHourEnd.IntValue;
	g_fCvarDeltaUTC = g_ConVarDeltaUTC.FloatValue;
	g_bStartRandomMap = g_ConVarStartRandomMap.BoolValue;
	
	InitHook();
}

void InitHook()
{
	static bool bHooked;
	
	if( g_bCvarEnabled )
	{
		if( !bHooked )
		{
			HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);	
			bHooked = true;
		}
	} else {
		if( bHooked )
		{
			UnhookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);	
			bHooked = false;
		}
	}
}

public void OnConfigsExecuted()
{
	if( g_bStartRandomMap && !g_bServerStarted)
	{
		g_bServerStarted = true;
		ChangeMap("Server is restarted");
	}
	if( g_ConVarHibernate != null )
	{
		g_iHybernateInitial = g_ConVarHibernate.IntValue;
		g_ConVarHibernate.SetInt(0);
	}
}

Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if( client == 0 || !IsFakeClient(client) )
	{
		if( !RealPlayerExist(client) )
		{
			if( IsRebootTimeAllowed() )
			{
				if( g_ConVarHibernate != null )
				{
					g_ConVarHibernate.SetInt(0);
				}
				CreateTimer(g_fCvarDelay, Timer_CheckPlayers);
				return Plugin_Continue;
			}
		}
		if( g_iCVarForceRebootHourStart != -1 )
		{
			if( IsForceRebootRequired() )
			{
				StartRebootSequence();
			}
		}
	}
	return Plugin_Continue;
}

bool IsForceRebootRequired()
{
	if( g_iCVarForceRebootHourStart == -1 || g_iCVarForceRebootHourEnd == -1 )
	{
		return false;
	}
	if( GetPluginWorkDurationHours() < 24 )
	{
		return false;
	}
	int iUnix = GetTime() + RoundToCeil(g_fCvarDeltaUTC * 3600.0);
	int Hour;
	SplitSeconds(iUnix, _, Hour);
	
	if( g_iCVarForceRebootHourStart >= g_iCVarForceRebootHourEnd ) // 0 ... 23
	{
		if( Hour >= g_iCVarForceRebootHourStart && Hour <= g_iCVarForceRebootHourEnd )
		{
			return true;
		}
	}
	else // like 22 ... 3
	{
		if( Hour >= g_iCVarForceRebootHourStart || Hour <= g_iCVarForceRebootHourEnd )
		{
			return true;
		}
	}
	return false;
}

bool IsRebootTimeAllowed()
{
	if( GetPluginWorkDurationHours() < g_iCvarMinPeriodHours )
	{
		return false;
	}
	int iUnix = GetTime() + RoundToCeil(g_fCvarDeltaUTC * 3600.0);
	int Hour;
	SplitSeconds(iUnix, _, Hour);
	
	if( g_iCVarLimitRebootHourStart >= g_iCVarLimitRebootHourEnd ) // 0 ... 23
	{
		if( Hour >= g_iCVarLimitRebootHourStart && Hour <= g_iCVarLimitRebootHourEnd )
		{
			return true;
		}
	}
	else // like 22 ... 3
	{
		if( Hour >= g_iCVarLimitRebootHourStart || Hour <= g_iCVarLimitRebootHourEnd )
		{
			return true;
		}
	}
	return false;
}

Action Timer_CheckPlayers(Handle timer, int UserId)
{
	if( !RealPlayerExist() )
	{
		StartRebootSequence();
	}
	return Plugin_Continue;
}

void StartRebootSequence()
{
	if( g_iCvarMethod != 3 )
	{
		UnloadAccelerator();
		UnloadPluginsExcludeMe();
		KickAll();
	}
	CreateTimer(0.1, Timer_RestartServer);
}

Action Timer_RestartServer(Handle timer)
{
	RestartServer();
	return Plugin_Continue;
}

void RestartServer()
{
	if (RealPlayerExist()) return;
	switch( g_iCvarMethod )
	{
		case 1: {
			LogToFileEx(g_sLogPath, "Sending '_restart'... Reason: %s", RealPlayerExist() ? "Scheduled time" : "Empty Server");
			ServerCommand("_restart");
		}
		case 2: {
			LogToFileEx(g_sLogPath, "Sending 'crash'... Reason: %s", RealPlayerExist() ? "Scheduled time" : "Empty Server");
			SetCommandFlags("crash", GetCommandFlags("crash") &~ FCVAR_CHEAT);
			ServerCommand("crash");
		}
		case 3: {
			ChangeMap("Empty server");
			if( g_ConVarHibernate != null )
			{
				CreateTimer(15.0, Timer_DoHybernate);
			}
		}
	}
}

void ChangeMap(char[] reason)
{
	char sMap[64];
	SetRandomSeed(GetTime());
	
	ArrayList al = new ArrayList(ByteCountToCells(sizeof(sMap)));
	
	if( FileExists(g_sMapListPath) )
	{
		File file = OpenFile(g_sMapListPath, "r", false);
		if( file )
		{
			while( !file.EndOfFile() )
			{
				file.ReadLine(sMap, sizeof(sMap));
				TrimString(sMap); // against weird read line bug in sm

				if( sMap[0] != 0 && sMap[0] != '\\' && sMap[0] != '<' )
				{
					if( IsMapValidEx(sMap) )
					{
						al.PushString(sMap);
					}
				}
			}
			file.Close();
		}
	}
	if( al.Length > 0 )
	{
		int idx = GetRandomInt(0, al.Length - 1);
		al.GetString(idx, sMap, sizeof(sMap));
	}
	else {
		GetCurrentMap(sMap, sizeof(sMap));
		LogError("Warning: no valid maps found in: %s", g_sMapListPath);
	}
	delete al;
	LogToFileEx(g_sLogPath, "Changing map to: %s... Reason: %s", sMap, reason);
	if( CommandExists("sm_map") )
	{
		ServerCommand("sm_map %s", sMap);
	}
	else {
		ForceChangeLevel(sMap, reason);
	}
}

void KickAll()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			KickClient(i, "Server Restarts");
		}
	}
}

void UnloadPluginsExcludeMe()
{
	char name[64];
	Handle hPlugin;
	Handle hIter = GetPluginIterator();
	
	if( hIter )
	{
		while( MorePlugins(hIter) )
		{
			hPlugin = ReadPlugin(hIter);
			
			if( hPlugin != hPluginMe && hPlugin != INVALID_HANDLE )
			{
				GetPluginFilename(hPlugin, name, sizeof(name));
				ServerCommand("sm plugins unload \"%s\"", name);
				ServerExecute();
			}
		}
		CloseHandle(hIter);
	}
}

int GetAcceleratorExtNumberFromCmd() // thanks to @Forgetest
{
	int iExtNum = 0;
	char responseBuffer[4096];
	// fetch a list of sourcemod extensions
	ServerCommandEx(responseBuffer, sizeof(responseBuffer), "sm exts list");
	// matching ext name only should suffice
	Regex regex = new Regex("\\[([0-9]+)\\] Accelerator");
	// actually matched?
	if( regex.Match(responseBuffer) > 0 && regex.CaptureCount() == 2 )
	{
		char sAcceleratorExtNum[4] = "0";
		// 0 is the full string "[?] Accelerator"
		// 1 is the matched extension number
		if( regex.GetSubString(1, sAcceleratorExtNum, sizeof(sAcceleratorExtNum)) )
		{
			if( sAcceleratorExtNum[0] != 0 && IsCharNumeric(sAcceleratorExtNum[0]) )
			{
				iExtNum = StringToInt(sAcceleratorExtNum, 10);
			}
		}
	}
	delete regex;
	return iExtNum;
}

void UnloadAccelerator()
{
	int iAccelExtNum;
	if( (iAccelExtNum = GetAcceleratorExtNumberFromCmd()) != 0 )
	{
		ServerCommand("sm exts unload %i 0", iAccelExtNum);
		ServerExecute();
	}
	else if( g_iCvarUnloadExtNum )
	{
		ServerCommand("sm exts unload %i 0", g_iCvarUnloadExtNum);
		ServerExecute();
	}
}

Action Timer_DoHybernate(Handle timer)
{
	if ( !RealPlayerExist() )
	{
		g_ConVarHibernate.SetInt(g_iHybernateInitial);
	}
	return Plugin_Continue;
}

bool RealPlayerExist(int iExclude = 0)
{
	for( int client = 1; client <= MaxClients; client++ )
	{
		if( client != iExclude && IsClientConnected(client) )
		{
			if( !IsFakeClient(client) )
			{
				return true;
			}
		}
	}
	return false;
}

void RemoveCrashLog()
{
	if( !FileExists(g_sLogPath) )
	{
		return;
	}

	char sFile[PLATFORM_MAX_PATH];
	int ft, ftReport = GetFileTime(g_sLogPath, FileTime_LastChange);
	
	if( DirExists("CRASH") )
	{
		DirectoryListing hDir = OpenDirectory("CRASH");
		if( hDir != null )
		{
			while( hDir.GetNext(sFile, sizeof(sFile)) )
			{
				TrimString(sFile);
				if( StrContains(sFile, "crash-") != -1 )
				{
					Format(sFile, sizeof(sFile), "CRASH/%s", sFile);
					ft = GetFileTime(sFile, FileTime_Created);
					
					if( 0 <= ft - ftReport < 10 ) // fresh crash?
					{
						DeleteFile(sFile);
					}
				}
			}
			delete hDir;
		}
	}
}

void SplitSeconds(int iUnix, int &D = 0, int &H = 0, int &M = 0, int &S = 0)
{
	D = iUnix / 86400;
	iUnix -= D * 86400;
	H = iUnix / 3600;
	iUnix -= H * 3600;
	M = iUnix / 60;
	S = iUnix - M * 60;
}

bool IsMapValidEx(char[] map)
{
	static char path[PLATFORM_MAX_PATH];
	return FindMap(map, path, sizeof(path)) == FindMap_Found;
}