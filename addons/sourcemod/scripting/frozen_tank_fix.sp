#include <sourcemod>
#include <sdktools>

#define PL_VERSION "2.0"

public Plugin:myinfo =
{
	name = "Fix frozen tanks",
	version = PL_VERSION,
	author = "sheo",
}

public OnPluginStart()
{
	HookEvent("player_incapacitated", Event_PlayerIncap);
	CreateConVar("l4d2_fix_frozen_tank_version", PL_VERSION, "Frozen tank fix version", FCVAR_NOTIFY);
}

public Event_PlayerIncap(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && IsPlayerTank(client))
	{
		CreateTimer(1.0, KillTank_tCallback);
	}
}

public Action:KillTank_tCallback(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsPlayerTank(i) && IsIncapitated(i))
		{
			ForcePlayerSuicide(i);
		}
	}
}

bool:IsIncapitated(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool:IsPlayerTank(client)
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