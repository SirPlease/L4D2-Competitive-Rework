#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <collisionhook>

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define MAX_EDICTS 2048

bool g_bInfectedLadder[MAX_EDICTS + 1];

public Plugin myinfo =
{
	name = "[L4D/2] Fix Infected Ladder Collision",
	author = "Sir",
	description = "Remove survivor collision with infected ladders.",
	version = "1.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "func_simpleladder")) != -1) {
		Hook_LadderSpawnPost(entity);
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	// Have to wait until after it spawns, team keyvalue isn't assigned yet.
	if (entity > 0 && entity <= MAX_EDICTS && strcmp(classname, "func_simpleladder") == 0) {
		SDKHook(entity, SDKHook_SpawnPost, Hook_LadderSpawnPost);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity > 0 && entity <= MAX_EDICTS) {
		g_bInfectedLadder[entity] = false;
	}
}

void Hook_LadderSpawnPost(int entity)
{
	if (GetEntProp(entity, Prop_Send, "m_iTeamNum") == TEAM_INFECTED) {
		g_bInfectedLadder[entity] = true;
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

// We don't send infected ladder data to survivors, this bit handles the clientside prediction so that they don't get visual bugs (jitter/rubberbanding)
Action Hook_SetTransmit(int entity, int client)
{
	if (GetClientTeam(client) == TEAM_SURVIVOR) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

// We don't let survivors collide with infected ladders, this bit handles the server side collision (actual collision)
public Action CH_PassFilter(int ent1, int ent2, bool &result)
{
	int client, ladder;

	if (ent1 > 0 && ent1 <= MaxClients) {
		client = ent1;
		ladder = ent2;
	}
	else if (ent2 > 0 && ent2 <= MaxClients) {
		client = ent2;
		ladder = ent1;
	}
	else {
		return Plugin_Continue;
	}

	if (ladder <= MaxClients || ladder > MAX_EDICTS || !g_bInfectedLadder[ladder]) {
		return Plugin_Continue;
	}

	if (GetEntProp(client, Prop_Send, "m_iTeamNum") != TEAM_SURVIVOR) {
		return Plugin_Continue;
	}

	result = false;
	return Plugin_Handled;
}
