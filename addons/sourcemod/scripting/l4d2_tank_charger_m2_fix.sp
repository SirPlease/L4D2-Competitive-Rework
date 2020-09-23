#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

public Plugin:myinfo =
{
	name = "L4D2 Tank & Charger M2 Fix",
	description = "Stops Shoves slowing the Tank and Charger Down",
	author = "Sir, Visor",
	version = "1.0",
	url = "https://github.com/Attano/Equilibrium"
};

public Action:L4D_OnShovedBySurvivor(shover, shovee, const Float:vector[3])
{
	if (!IsSurvivor(shover) || !IsInfected(shovee))
	{
		return Plugin_Continue;
	}
	if (IsTankOrCharger(shovee))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:L4D2_OnEntityShoved(shover, shovee_ent, weapon, Float:vector[3], bool:bIsHunterDeadstop)
{
	if (!IsSurvivor(shover) || !IsInfected(shovee_ent))
	{
		return Plugin_Continue;
	}
	if (IsTankOrCharger(shovee_ent))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool:IsTankOrCharger(client)
{
	if (!IsPlayerAlive(client))
	{
		return false;
	}
	
	new zombieclass = GetEntProp(client, Prop_Send, "m_zombieClass");
	return (zombieclass == 6 || zombieclass == 8);
}

bool:IsSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

bool:IsInfected(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3);
}