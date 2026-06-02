#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define TEAM_INFECTED 3
#define Z_TANK 8

public Plugin myinfo =
{
	name = "Fix frozen tanks",
	version = "2.2",
	author = "sheo",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	HookEvent("player_incapacitated", Event_PlayerIncap);
}

void Event_PlayerIncap(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iClient > 0 && IsPlayerTank(iClient)) {
		CreateTimer(1.0, Timer_KillTankDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_KillTankDelay(Handle hTimer)
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsPlayerTank(i) && IsIncapitated(i)) {
			ForcePlayerSuicide(i);
		}
	}

	return Plugin_Stop;
}

bool IsPlayerTank(int iClient)
{
	return (IsClientInGame(iClient)
		&& GetClientTeam(iClient) == TEAM_INFECTED
		&& GetEntProp(iClient, Prop_Send, "m_zombieClass") == Z_TANK);
}

bool IsIncapitated(int iClient)
{
	return (GetEntProp(iClient, Prop_Send, "m_isIncapacitated", 1) > 0);
}
