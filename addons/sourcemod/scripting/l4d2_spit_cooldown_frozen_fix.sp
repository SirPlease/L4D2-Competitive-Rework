#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.1a"

public Plugin myinfo = 
{
	name = "[L4D2] Spit Cooldown Frozen Fix",
	author = "Forgetest",
	description = "Simple fix for spit cooldown being \"frozen\".",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

ConVar z_spit_interval;

public void OnPluginStart()
{
	z_spit_interval = FindConVar("z_spit_interval");
	
	HookEvent("ability_use", Event_AbilityUse);
}

void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
	char sAbility[16];
	event.GetString("ability", sAbility, sizeof(sAbility));
	if (strcmp(sAbility[8], "spit") == 0)
	{
		// duration of spit animation seems to vary from [1.160003, 1.190002] on 100t sv
		CreateTimer(1.2, Timer_CheckAbilityTimer, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_CheckAbilityTimer(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || GetEntProp(client, Prop_Send, "m_zombieClass") != 4 || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	
	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (ability == -1)
	{
		return Plugin_Stop;
	}
	
	// potential freezing detected
	if (GetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", 0) == 3600.0)
	{
		float interval = z_spit_interval.FloatValue;
		SetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", interval, 0);
		SetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", GetGameTime() + interval, 1);
		SetEntProp(ability, Prop_Send, "m_bHasBeenActivated", false);
	}
	
	return Plugin_Stop;
}
