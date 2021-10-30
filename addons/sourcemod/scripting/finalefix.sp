#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define TEAM_SURVIVOR 2

public Plugin myinfo =
{
	name = "L4D2 Finale Incap Distance Fixifier",
	author = "CanadaRox",
	description = "Kills survivors before the score is calculated so you don't get full distance if you are incapped as the rescue vehicle leaves.",
	version = "1.0.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	HookEvent("finale_vehicle_leaving", FinaleEnd_Event, EventHookMode_PostNoCopy);
}

public void FinaleEnd_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerIncap(i)) {
			ForcePlayerSuicide(i);
		}
	}
}

bool IsPlayerIncap(int iClient)
{
	return view_as<bool>(GetEntProp(iClient, Prop_Send, "m_isIncapacitated", 1));
}
