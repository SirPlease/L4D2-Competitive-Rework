#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "2.0"

public Plugin myinfo =
{
	name = "Fix frozen tanks",
	version = PL_VERSION,
	author = "sheo",
}

public void OnPluginStart()
{
	CreateConVar("l4d2_fix_frozen_tank_version", PL_VERSION, "Frozen tank fix version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);
	HookEvent("player_incapacitated", Event_PlayerIncap, EventHookMode_Post);
}

public void Event_PlayerIncap(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && IsPlayerTank(client))
	{
		CreateTimer(1.0, KillTank_tCallback, client);
	}
}

Action KillTank_tCallback(Handle timer, int client)
{
	if (IsPlayerTank(client) && IsIncapitated(client))
	{
		ForcePlayerSuicide(client);
	}

	return Plugin_Handled;
}

bool IsIncapitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

bool IsPlayerTank(int client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		if (GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
		{
			return true;
		}
	}
	return false;
}