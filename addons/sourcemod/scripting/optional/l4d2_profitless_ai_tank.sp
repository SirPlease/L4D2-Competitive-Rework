#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

int lastHumanTankId;

public Plugin myinfo =
{
	name = "L4D2 Profitless AI Tank",
	author = "Visor, Forgetest",
	description = "Passing control to AI Tank will no longer be rewarded with an instant respawn",
	version = "0.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	HookEvent("tank_frustrated", OnTankFrustrated, EventHookMode_Post);
}

public void OnMapStart()
{
	lastHumanTankId = 0;
}

void OnTankFrustrated(Event event, const char[] name, bool dontBroadcast)
{
	lastHumanTankId = event.GetInt("userid");
	RequestFrame(OnNextFrame_Reset);
}

void OnNextFrame_Reset()
{
	lastHumanTankId = 0;
}

public Action L4D_OnEnterGhostStatePre(int client)
{
	if (lastHumanTankId && GetClientUserId(client) == lastHumanTankId)
	{
		lastHumanTankId = 0;
		L4D_State_Transition(client, STATE_DEATH_ANIM);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}