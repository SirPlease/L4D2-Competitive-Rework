#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <collisionhook>

#define TEAM_SURVIVOR 2
#define MAX_EDICTS 2048

enum
{
	ENTITY_OTHER,
	ENTITY_COMMON,
	ENTITY_ROCK
};

bool
	isPulled[MAXPLAYERS + 1] = {false, ...},
	bRockFix,
	bPullThrough,
	bRockThroughIncap;

ConVar
	hRockFix,
	hPullThrough,
	hRockThroughIncap;

int iEntityType[MAX_EDICTS + 1];

public Plugin myinfo =
{
	name = "L4D2 Collision Adjustments",
	author = "Sir",
	version = "1.4",
	description = "Allows messing with pesky Collisions in Left 4 Dead 2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	// Smokers
	HookEvent("tongue_grab", Event_SurvivorPulled);
	HookEvent("tongue_release", Event_PullEnd);

	// Cvars
	hRockFix = CreateConVar("collision_tankrock_common", "1", "Will Rocks go through Common Infected (and also kill them) instead of possibly getting stuck on them?");
	hPullThrough = CreateConVar("collision_smoker_common", "0", "Will Pulled Survivors go through Common Infected?");
	hRockThroughIncap = CreateConVar("collision_tankrock_incap", "0", "Will Rocks go through Incapacitated Survivors? (Won't go through new incaps caused by the Rock)");

	CvarsInType();

	// Cvar Changes
	hRockFix.AddChangeHook(cvarChanged);
	hPullThrough.AddChangeHook(cvarChanged);
	hRockThroughIncap.AddChangeHook(cvarChanged);

	HookEvent("round_start", Event_Reset, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_Reset, EventHookMode_PostNoCopy);

	// Late load
	char sClassname[64];
	int iMaxEntities = GetMaxEntities();
	for (int i = MaxClients + 1; i < iMaxEntities; i++) {
		if (IsValidEdict(i) && GetEdictClassname(i, sClassname, sizeof(sClassname))) {
			OnEntityCreated(i, sClassname);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity <= MaxClients || entity > MAX_EDICTS) {
		return;
	}

	if (strcmp(classname, "infected") == 0) {
		iEntityType[entity] = ENTITY_COMMON;
	} else if (strcmp(classname, "tank_rock") == 0) {
		iEntityType[entity] = ENTITY_ROCK;
	} else {
		iEntityType[entity] = ENTITY_OTHER;
	}
}

public void OnClientDisconnect(int client)
{
	isPulled[client] = false;
}

void cvarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CvarsInType();
}

void CvarsInType()
{
	bRockFix = hRockFix.BoolValue;
	bPullThrough = hPullThrough.BoolValue;
	bRockThroughIncap = hRockThroughIncap.BoolValue;
}

public Action CH_PassFilter(int ent1, int ent2, bool &result)
{
	int iType1 = (ent1 > MaxClients && ent1 <= MAX_EDICTS) ? iEntityType[ent1] : ENTITY_OTHER;
	int iType2 = (ent2 > MaxClients && ent2 <= MAX_EDICTS) ? iEntityType[ent2] : ENTITY_OTHER;

	if (iType1 == ENTITY_OTHER && iType2 == ENTITY_OTHER) {
		return Plugin_Continue;
	}

	if (iType1 == ENTITY_COMMON) {
		if (bRockFix && iType2 == ENTITY_ROCK) {
			result = false;
			return Plugin_Handled;
		}

		if (bPullThrough && IsPulledSurvivor(ent2)) {
			result = false;
			return Plugin_Handled;
		}
	} else if (iType2 == ENTITY_COMMON) {
		if (bRockFix && iType1 == ENTITY_ROCK) {
			result = false;
			return Plugin_Handled;
		}

		if (bPullThrough && IsPulledSurvivor(ent1)) {
			result = false;
			return Plugin_Handled;
		}
	} else if (iType1 == ENTITY_ROCK) {
		if (bRockThroughIncap && IsSurvivorAndIncapacitated(ent2)) {
			result = false;
			return Plugin_Handled;
		}
	} else if (iType2 == ENTITY_ROCK) {
		if (bRockThroughIncap && IsSurvivorAndIncapacitated(ent1)) {
			result = false;
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

void Event_Reset(Event hEvent, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i <= MAXPLAYERS; i++) {
		isPulled[i] = false;
	}
}

void Event_SurvivorPulled(Event hEvent, const char[] name, bool dontBroadcast)
{
	isPulled[GetClientOfUserId(hEvent.GetInt("victim"))] = true;
}

void Event_PullEnd(Event hEvent, const char[] name, bool dontBroadcast)
{
	isPulled[GetClientOfUserId(hEvent.GetInt("victim"))] = false;
}

// ----------------------------
bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

bool IsSurvivor(int client)
{
	return (IsValidClient(client) && GetClientTeam(client) == TEAM_SURVIVOR);
}

bool IsPulledSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && isPulled[client] && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR);
}

bool IsSurvivorAndIncapacitated(int client)
{
	if (IsSurvivor(client)) {
		if (GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0) {
			return true;
		}

		if (!IsPlayerAlive(client)) {
			return true;
		}
	}

	return false;
}
