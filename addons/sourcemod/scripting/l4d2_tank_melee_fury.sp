#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo =
{
	name = "L4D2 Tank Melee Fury",
	author = "Visor",
	description = "Aggressive melee Survivors are almost certain to get punished for excessively pushing the Tank",
	version = "1.0",
	url = "https://github.com/Attano/L4D2-Competitive-Framework"
};

public OnPluginStart()
{
    HookEvent("player_hurt", OnPlayerHurt);
}

// public OnConfigsExecuted()
// {
    // SetConVarFloat(FindConVar("tank_swing_miss_interval"), 0.5);
// }

// public OnPluginEnd()
// {
    // ResetConVar(FindConVar("tank_swing_miss_interval"));
// }

public Action:OnPlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new tank = GetClientOfUserId(GetEventInt(event, "userid"));
	new survivor = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!IsSurvivor(survivor) || !IsTank(tank))
	{
		return;
	}

	decl String:weaponName[64];
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));
	if (!IsMelee(weaponName))
	{
		return;
	}
	
	new tankClaw = GetActiveWeapon(tank);
	new Float:swingTime = GetConVarFloat(FindConVar("tank_swing_interval")) + GetConVarFloat(FindConVar("tank_windup_time"));
	SetEntPropFloat(tankClaw, Prop_Send, "m_flNextPrimaryAttack", GetEntPropFloat(tankClaw, Prop_Send, "m_flNextPrimaryAttack") - swingTime);
	SetEntPropFloat(tankClaw, Prop_Send, "m_flNextSecondaryAttack", GetEntPropFloat(tankClaw, Prop_Send, "m_flNextSecondaryAttack") - swingTime);
}

GetActiveWeapon(client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

bool:IsMelee(const String:weaponName[])
{
	return (StrEqual(weaponName, "weapon_melee", false) || StrEqual(weaponName, "melee", false));
}

bool:IsSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

bool:IsTank(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(client));
}