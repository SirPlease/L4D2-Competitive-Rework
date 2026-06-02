#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>

#define PLUGIN_VERSION "2.2"

public Plugin myinfo =
{
	name = "Death Cam Skip Fix",
	author = "Jacob, Sir, Forgetest",
	description = "Blocks players skipping their death time by going spec",
	version = PLUGIN_VERSION,
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

float g_flSavedTime[MAXPLAYERS + 1] = {0.0, ...};
bool g_bSkipPrint[MAXPLAYERS + 1];
ConVar g_cvExploitAnnounce;

public void OnPluginStart()
{
	LoadPluginTranslations("nodeathcamskip.phrases");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	
	g_cvExploitAnnounce = CreateConVar("deathcam_skip_announce", "1", "Print a message when someone exploits.", FCVAR_SPONLY, true, 0.0, true, 1.0);
}

public void OnClientPutInServer(int client)
{
	g_flSavedTime[client] = 0.0;
	g_bSkipPrint[client] = false;
}

void Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		g_flSavedTime[i] = 0.0;
		g_bSkipPrint[i] = false;
	}
}

void Event_PlayerDeath(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidInfected(client))
		return;
	
	SetExploiter(client);
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int team = event.GetInt("team");
	int oldteam = event.GetInt("oldteam");
	if (team == oldteam)
		return;
	
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client))
		return;
	
	if (oldteam == 3)
	{
		if (IsPlayerAlive(client) && !GetEntProp(client, Prop_Send, "m_isGhost"))
		{
			SetExploiter(client);
		}
	}
	else if (team == 3)
	{
		RequestFrame(OnNextFrame_PlayerTeam, userid);
	}
}

void OnNextFrame_PlayerTeam(int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidInfected(client))
		return;
	
	if (g_flSavedTime[client] == 0.0)
		return;
	
	if (GetGameTime() - g_flSavedTime[client] >= 6.0)
		return;
	
	L4D_State_Transition(client, STATE_DEATH_ANIM);
	SetEntPropFloat(client, Prop_Send, "m_flDeathTime", g_flSavedTime[client]);
	
	WarnExploiting(client);
}

void WarnExploiting(int client)
{
	if (!g_cvExploitAnnounce.BoolValue)
		return;
	
	if (g_bSkipPrint[client])
		return;
	
	CPrintToChatAll("%t", "WarnExploiting", client);
	g_bSkipPrint[client] = true;
}

void SetExploiter(int client)
{
	g_flSavedTime[client] = GetGameTime();
	g_bSkipPrint[client] = false;
}

void LoadPluginTranslations(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "translations/%s.txt", translation);
	if (!FileExists(sPath))
	{
		SetFailState("Missing translations \"%s\"", translation);
	}
	LoadTranslations(translation);
}

stock bool IsValidInfected(int client)
{ 
	if (client <= 0 || client > MaxClients)
		return false; 

	return IsClientInGame(client) && GetClientTeam(client) == 3 && !IsFakeClient(client); 
}