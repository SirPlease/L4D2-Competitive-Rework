#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

#define NOAVOID_ADDTIME 2.0

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D/L4D2]noteam_nudging",
	author = "Lux",
	description = "Prevents small push effect between survior players, bots still get pushed.",
	version = PLUGIN_VERSION,
	url = "-"
};


public void OnPluginStart()
{
	CreateConVar("noteam_nudging_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CreateTimer(1.0, UpdateAvoid, _, TIMER_REPEAT);
}

public Action UpdateAvoid(Handle timer)
{
	float flTime = GetGameTime();
	float flPropTime;
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i) || IsFakeClient(i))
			continue;
		
		flPropTime = GetEntPropFloat(i, Prop_Send, "m_noAvoidanceTimer", 1);
		if(flPropTime > flTime + NOAVOID_ADDTIME)
			continue;
		
		SetEntPropFloat(i, Prop_Send, "m_noAvoidanceTimer", flTime + NOAVOID_ADDTIME, 1);
	}
}