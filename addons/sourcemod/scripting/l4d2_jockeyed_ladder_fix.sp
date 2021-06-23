#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <collisionhook>

#define Z_JOCKEY 5
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

public Plugin myinfo =
{
	name = "L4D2 Jockeyed Survivor Ladder Fix",
	author = "Visor, A1m`",
	description = "Fixes jockeyed Survivors slowly sliding down the ladders",
	version = "1.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public Action CH_PassFilter(int entity1, int entity2, bool &result)
{
	if ((IsJockeyedSurvivor(entity1) || IsJockeyedSurvivor(entity2))
		&& (IsLadder(entity1) || IsLadder(entity2))) {
		result = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool IsLadder(int entity)
{
	if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity)) {
		char strClassName[64];
		GetEdictClassname(entity, strClassName, sizeof(strClassName));
		return (StrContains(strClassName, "ladder") > 0);
	}
	return false;
}

bool IsJockeyedSurvivor(int client)
{
	return (client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client) 
		&& GetClientTeam(client) == TEAM_SURVIVOR 
		&& IsJockeyed(client));
}

bool IsJockey(int client)
{
	return (client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client) 
		&& GetClientTeam(client) == TEAM_INFECTED 
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == Z_JOCKEY);
}

bool IsJockeyed(int survivor)
{
	return IsJockey(GetEntPropEnt(survivor, Prop_Send, "m_jockeyAttacker"));
}