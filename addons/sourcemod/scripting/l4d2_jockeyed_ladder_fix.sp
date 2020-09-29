#pragma semicolon 1

#include <sourcemod>
// #include <sdktools>
#include <collisionhook>

public Plugin:myinfo =
{
	name = "L4D2 Jockeyed Survivor Ladder Fix",
	author = "Visor",
	description = "Fixes jockeyed Survivors slowly sliding down the ladders",
	version = "1.1",
	url = "https://github.com/Attano/L4D2-Competitive-Framework"
};

public Action:CH_PassFilter(entity1, entity2, &bool:result)
{
	if ((IsJockeyedSurvivor(entity1) || IsJockeyedSurvivor(entity2))
		&& (IsLadder(entity1) || IsLadder(entity2)))
	{
		result = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool:IsLadder(entity)
{
	if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
	{
		decl String:strClassName[64];
		GetEdictClassname(entity, strClassName, sizeof(strClassName));
		return (StrContains(strClassName, "ladder") > 0);
	}
	return false;
}

bool:IsJockeyedSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsJockeyed(client));
}

bool:IsJockey(client)
{
	return (client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client) 
		&& GetClientTeam(client) == 3 
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == 5);
}

bool:IsJockeyed(survivor)
{
	return IsJockey(GetEntDataEnt2(survivor, 16128));
}