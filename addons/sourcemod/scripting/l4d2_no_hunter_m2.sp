#pragma semicolon 1

#include <sourcemod>
#include <left4downtown> // min v0.5.7

#define DEBUG   0

public Plugin:myinfo = 
{
	name = "L4D2 No Hunter Deadstops",
	author = "Visor",
	description = "Self-descriptive",
	version = "3.3.1",
	url = "https://github.com/Attano/Equilibrium"
};

public Action:L4D_OnShovedBySurvivor(shover, shovee, const Float:vector[3])
{
	if (!IsSurvivor(shover) || !IsHunter(shovee) || HasTarget(shovee))
		return Plugin_Continue;

	return Plugin_Handled;
}

public Action:L4D2_OnEntityShoved(shover, shovee_ent, weapon, Float:vector[3], bool:bIsHunterDeadstop)
{
	if (!IsSurvivor(shover) || !IsHunter(shovee_ent) || HasTarget(shovee_ent))
		return Plugin_Continue;

	return Plugin_Handled;
}

stock bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

stock bool:IsInfected(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}

stock bool:IsHunter(client)  
{
	if (!IsInfected(client))
		return false;
		
	if (!IsPlayerAlive(client))
		return false;

	if (GetEntProp(client, Prop_Send, "m_zombieClass") != 3)
		return false;

	return true;
}

bool:HasTarget(hunter)
{
	new target = GetEntDataEnt2(hunter, 16004);
	return (IsSurvivor(target) && IsPlayerAlive(target));
}