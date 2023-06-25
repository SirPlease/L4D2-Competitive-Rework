#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <regex>

public Plugin myinfo =
{
	name = "L4D auto restart",
	author = "Harry Potter",
	description = "make server restart (Force crash) when the last player disconnects from the server",
	version = "2.6",
	url	= "https://steamcommunity.com/profiles/76561198026784913"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test == Engine_Left4Dead )
	{
		
	}
	else if( test == Engine_Left4Dead2 )
	{
		
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

#define CVAR_FLAGS			FCVAR_NOTIFY

ConVar g_hConVarHibernate;
Handle COLD_DOWN_Timer;

bool g_bNoOneInServer;

public void OnPluginStart()
{
	g_hConVarHibernate = FindConVar("sv_hibernate_when_empty");
	g_hConVarHibernate.AddChangeHook(ConVarChanged_Hibernate);

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);	
}

public void OnPluginEnd()
{
	delete COLD_DOWN_Timer;
}

void ConVarChanged_Hibernate(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	g_hConVarHibernate.SetBool(false);
}

public void OnMapStart()
{	
	if(g_bNoOneInServer)
	{
		g_bNoOneInServer = false;
		if(CheckPlayerInGame(0) == false) //沒有玩家在伺服器中
		{
			g_bNoOneInServer = true;

			delete COLD_DOWN_Timer;
			COLD_DOWN_Timer = CreateTimer(20.0, COLD_DOWN);
		}
	}
}

public void OnMapEnd()
{
	delete COLD_DOWN_Timer;
}

public void OnConfigsExecuted()
{
	g_hConVarHibernate.SetBool(false);
	if(g_bNoOneInServer)
	{
		g_bNoOneInServer = false;
		if(CheckPlayerInGame(0) == false) //沒有玩家在伺服器中
		{
			g_bNoOneInServer = true;

			delete COLD_DOWN_Timer;
			COLD_DOWN_Timer = CreateTimer(20.0, COLD_DOWN);
		}
	}
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || IsFakeClient(client) || (IsClientConnected(client) && !IsClientInGame(client))) return; //連線中尚未進來的玩家離線
	if(client && !CheckPlayerInGame(client)) //檢查是否還有玩家以外的人還在伺服器
	{
		g_bNoOneInServer = true;

		delete COLD_DOWN_Timer;
		COLD_DOWN_Timer = CreateTimer(15.0, COLD_DOWN);
	}
}

Action COLD_DOWN(Handle timer, any client)
{
	if(CheckPlayerInGame(0)) //有玩家在伺服器中
	{
		g_bNoOneInServer = false;
		COLD_DOWN_Timer = null;
		return Plugin_Continue;
	}
	
	if(CheckPlayerConnectingSV()) //沒有玩家在伺服器但是有玩家正在連線
	{
		COLD_DOWN_Timer = CreateTimer(20.0, COLD_DOWN); //重新計時
		return Plugin_Continue;
	}
	
	LogMessage("Last one player left the server, Restart server now");
	PrintToServer("Last one player left the server, Restart server now");

	UnloadAccelerator();

	CreateTimer(0.1, Timer_RestartServer);

	COLD_DOWN_Timer = null;
	return Plugin_Continue;
}

Action Timer_RestartServer(Handle timer)
{
	SetCommandFlags("crash", GetCommandFlags("crash") &~ FCVAR_CHEAT);
	ServerCommand("crash");

	//SetCommandFlags("sv_crash", GetCommandFlags("sv_crash") &~ FCVAR_CHEAT);
	//ServerCommand("sv_crash");//crash server, make linux auto restart server

	return Plugin_Continue;
}

void UnloadAccelerator()
{
	/*if( g_iCvarUnloadExtNum )
	{
		ServerCommand("sm exts unload %i 0", g_iCvarUnloadExtNum);
	}*/

	char responseBuffer[4096];
	
	// fetch a list of sourcemod extensions
	ServerCommandEx(responseBuffer, sizeof(responseBuffer), "%s", "sm exts list");
	
	// matching ext name only should sufiice
	Regex regex = new Regex("\\[([0-9]+)\\] Accelerator");
	
	// actually matched?
	// CapcureCount == 2? (see @note of "Regex.GetSubString" in regex.inc)
	if (regex.Match(responseBuffer) > 0 && regex.CaptureCount() == 2)
	{
		char sAcceleratorExtNum[4];
		
		// 0 is the full string "[?] Accelerator"
		// 1 is the matched extension number
		regex.GetSubString(1, sAcceleratorExtNum, sizeof(sAcceleratorExtNum));
		
		// unload it
		ServerCommand("sm exts unload %s 0", sAcceleratorExtNum);
		ServerExecute();
	}
	
	delete regex;
}

bool CheckPlayerInGame(int client)
{
	for (int i = 1; i < MaxClients+1; i++)
		if(IsClientInGame(i) && !IsFakeClient(i) && i!=client)
			return true;

	return false;
}

bool CheckPlayerConnectingSV()
{
	for (int i = 1; i < MaxClients+1; i++)
		if(IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i))
			return true;

	return false;
}