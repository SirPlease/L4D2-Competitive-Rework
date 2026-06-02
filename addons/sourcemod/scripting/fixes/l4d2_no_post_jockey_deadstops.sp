#pragma semicolon 1

#include <sourcemod>
#include <left4dhooks>

public Plugin:myinfo = 
{
	name = "L4D2 No Post-Jockeyed Shoves",
	author = "Sir",
	description = "L4D2 has a nasty bug which Survivors would exploit and this fixes that. (Holding out a melee and spamming shove, even if the jockey was behind you, would self-clear yourself after the Jockey actually landed.",
	version = "1.0",
	url = "nah"
};

public Action L4D_OnShovedBySurvivor(int client, int victim, const float vecDir[3])
{
	if (!IsSurvivor(client) || !IsJockey(victim))
		return Plugin_Continue;
	
	if (IsJockeyed(client)) return Plugin_Handled;
	return Plugin_Continue;
}

public Action L4D2_OnEntityShoved(int client, int entity, int weapon, float vecDir[3], bool bIsHighPounce)
{
	if (!IsSurvivor(client) || !IsJockey(entity))
		return Plugin_Continue;
	
	if (IsJockeyed(client)) return Plugin_Handled;
	return Plugin_Continue;
}

bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

bool IsInfected(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}

bool IsJockey(int client)  
{
	if (!IsInfected(client))
		return false;
		
	if (!IsPlayerAlive(client))
		return false;

	if (GetEntProp(client, Prop_Send, "m_zombieClass") != 5)
		return false;

	return true;
}

bool IsJockeyed(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0;
}