#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <collisionhook>

#define Z_JOCKEY 5
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define MAX_EDICTS 2048

bool g_bIsLadder[MAX_EDICTS + 1];

public Plugin myinfo =
{
	name = "L4D2 Jockeyed Survivor Ladder Fix",
	author = "Visor, A1m`",
	description = "Fixes jockeyed Survivors slowly sliding down the ladders",
	version = "1.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	// Late load
	char strClassName[64];
	int iMaxEntities = GetMaxEntities();
	for (int i = MaxClients + 1; i < iMaxEntities; i++) {
		if (IsValidEdict(i) && GetEdictClassname(i, strClassName, sizeof(strClassName))) {
			OnEntityCreated(i, strClassName);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity > MaxClients && entity <= MAX_EDICTS) {
		g_bIsLadder[entity] = (StrContains(classname, "ladder") > 0);
	}
}

public Action CH_PassFilter(int entity1, int entity2, bool &result)
{
	int client;

	if (entity1 > MaxClients && entity1 <= MAX_EDICTS && g_bIsLadder[entity1]) {
		client = entity2;
	} else if (entity2 > MaxClients && entity2 <= MAX_EDICTS && g_bIsLadder[entity2]) {
		client = entity1;
	} else {
		return Plugin_Continue;
	}

	if (!IsJockeyedSurvivor(client)) {
		return Plugin_Continue;
	}

	result = false;
	return Plugin_Handled;
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
