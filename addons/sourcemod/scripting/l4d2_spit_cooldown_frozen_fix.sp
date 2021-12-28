#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.2"

public Plugin myinfo = 
{
	name = "[L4D2] Spit Cooldown Frozen Fix",
	author = "Forgetest",
	description = "Simple fix for spit cooldown being \"frozen\".",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

ConVar z_spit_interval;
ArrayList g_hWaitList;

public void OnPluginStart()
{
	z_spit_interval = FindConVar("z_spit_interval");
	
	g_hWaitList = new ArrayList(2);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("ability_use", Event_AbilityUse);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_hWaitList.Clear();
}

void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
	char sAbility[16];
	event.GetString("ability", sAbility, sizeof(sAbility));
	if (strcmp(sAbility[8], "spit") == 0)
	{
		// duration of spit animation seems to vary from [1.160003, 1.190002] on 100t sv
		g_hWaitList.Set(g_hWaitList.Push(event.GetInt("userid")), GetGameTime() + 1.2, 1);
	}
}

public void OnGameFrame()
{
	while (g_hWaitList.Length && GetGameTime() >= g_hWaitList.Get(0, 1))
	{
		CheckSpitAbility(g_hWaitList.Get(0, 0));
		g_hWaitList.Erase(0);
	}
}

void CheckSpitAbility(int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || GetEntProp(client, Prop_Send, "m_zombieClass") != 4 || !IsPlayerAlive(client))
	{
		return;
	}
	
	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (ability == -1)
	{
		return;
	}
	
	// potential freezing detected
	if (GetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", 0) == 3600.0)
	{
		float interval = z_spit_interval.FloatValue;
		SetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", interval, 0);
		SetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", GetGameTime() + interval, 1);
		SetEntProp(ability, Prop_Send, "m_bHasBeenActivated", false);
	}
}
