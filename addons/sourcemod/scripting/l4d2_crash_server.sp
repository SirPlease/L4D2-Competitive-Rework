#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <regex>

bool g_bEnabled = false;
int g_iNumberOfGamesUntilCrash = 3;

ConVar
	g_hCvarEnabled = null,
	g_hCvarNumberOfGamesUntilCrash = null;

int numberOfGamesPlayed = 0;
int previousScore = 0;

public Plugin myinfo =
{
	name = "L4D2 - Crash server",
	author = "Altair Sossai",
	description = "Force server crash after N games",
	version = "1.0",
	url	= "https://github.com/altair-sossai/l4d2-zone-server"
};

public void OnPluginStart()
{
	g_hCvarEnabled = CreateConVar("l4d2_crash_server_enabled", "0", "Enabled crash server");
	g_hCvarNumberOfGamesUntilCrash = CreateConVar("l4d2_crash_server_number_of_games", "3", "Number of games until crash");
	
	CvarsToType();
	
	g_hCvarEnabled.AddChangeHook(Cvars_Changed);
	g_hCvarNumberOfGamesUntilCrash.AddChangeHook(Cvars_Changed);

	HookEvent("round_start", RoundStart_Event);

	RegAdminCmd("sm_forcecrash", ForceCrash_Cmd, ADMFLAG_BAN);
}

public void Cvars_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	CvarsToType();
}

void CvarsToType()
{
	g_bEnabled = g_hCvarEnabled.BoolValue;
	g_iNumberOfGamesUntilCrash = g_hCvarNumberOfGamesUntilCrash.IntValue;
}

public Action ForceCrash_Cmd(int client, int args)
{
	AlertAndCrash();

	return Plugin_Continue;
}

public void RoundStart_Event(Handle event, const char[] name, bool dontBroadcast)
{
	if (!g_bEnabled)
		return;

	CreateTimer(30.0, RoundStart_Timer);
}

public Action RoundStart_Timer(Handle timer)
{
	if (previousScore == 0)
		return Plugin_Continue;

	int currentScore = GetCurrentScore();
	if (currentScore != 0)
		return Plugin_Continue;

	numberOfGamesPlayed++;
	previousScore = 0;

	if (numberOfGamesPlayed >= g_iNumberOfGamesUntilCrash)
		AlertAndCrash();

	return Plugin_Continue;
}

public void L4D2_OnEndVersusModeRound_Post()
{
	previousScore = GetCurrentScore();
}

int GetCurrentScore()
{
	return L4D2Direct_GetVSCampaignScore(0) + L4D2Direct_GetVSCampaignScore(1);
}

void AlertAndCrash()
{
	char status[1024];
	ServerCommandEx(status, sizeof(status), "status");

	char ip[40];
	Regex regex = new Regex("public (\\d+\\.\\d+\\.\\d+\\.\\d+:\\d+)");
	regex.Match(status);
	regex.GetSubString(1, ip, sizeof(ip));
	
	PrintToChatAll("\x01The server will be restarted in \x0315\x01 seconds, use the \x04IP\x01 below to reconnect");

	for (int i = 0; i < 3; i++)
		PrintToChatAll("\x04connect %s", ip);

	CreateTimer(15.0, AlertAndCrash_Timer);
}

Action AlertAndCrash_Timer(Handle timer)
{
	KickAll();
	Crash();

	return Plugin_Continue;
}

void KickAll()
{
	for( int i = 1; i <= MaxClients; i++ )
		if(IsClientInGame(i))
			KickClient(i, "The server has been restarted, see the IP in your game console");
}

void Crash()
{
	UnloadAccelerator();
	CreateTimer(0.1, Crash_Timer);
}

void UnloadAccelerator()
{
	char responseBuffer[4096];
	
	ServerCommandEx(responseBuffer, sizeof(responseBuffer), "%s", "sm exts list");
	
	Regex regex = new Regex("\\[([0-9]+)\\] Accelerator");
	
	if (regex.Match(responseBuffer) > 0 && regex.CaptureCount() == 2)
	{
		char sAcceleratorExtNum[4];
		
		regex.GetSubString(1, sAcceleratorExtNum, sizeof(sAcceleratorExtNum));
		
		ServerCommand("sm exts unload %s 0", sAcceleratorExtNum);
		ServerExecute();
	}
	
	delete regex;
}

Action Crash_Timer(Handle timer)
{
	SetCommandFlags("crash", GetCommandFlags("crash") &~ FCVAR_CHEAT);
	ServerCommand("crash");

	return Plugin_Continue;
}