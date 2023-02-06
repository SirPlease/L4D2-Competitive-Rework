#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

float fSavedTime[MAXPLAYERS + 1] = {0.0, ...};

public Plugin myinfo = {
	name = "Death Cam Skip Fix",
	author = "Jacob, Sir, Forgetest",
	description = "Blocks players skipping their death time by going spec",
	version = "2.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
}

public void OnClientPutInServer(int client)
{
	fSavedTime[client] = 0.0;
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
			fSavedTime[client] = GetGameTime();
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
	
	if (fSavedTime[client] == 0.0)
		return;
	
	if (GetGameTime() - fSavedTime[client] >= 6.0)
		return;
	
	L4D_State_Transition(client, STATE_DEATH_ANIM);
	SetEntPropFloat(client, Prop_Send, "m_flDeathTime", fSavedTime[client]);
}

void Event_PlayerDeath(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (IsValidInfected(client))
	{
		fSavedTime[client] = GetGameTime();
	}
}

stock bool IsValidInfected(int client)
{ 
	if (client <= 0 || client > MaxClients)
		return false; 

	return IsClientInGame(client) && GetClientTeam(client) == 3 && !IsFakeClient(client); 
}