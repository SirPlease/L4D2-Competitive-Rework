#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <collisionhook>

#define TEAM_SURVIVOR 2

bool
	isPulled[MAXPLAYERS + 1] = {false, ...},
	bRockFix,
	bPullThrough,
	bRockThroughIncap;

//Cvars
ConVar
	hRockFix,
	hPullThrough,
	hRockThroughIncap;

//Strings to dump stuff in
char
	sEntityCName[20],
	sEntityCNameTwo[20];

public Plugin myinfo =
{
	name = "L4D2 Collision Adjustments",
	author = "Sir",
	version = "1.3",
	description = "Allows messing with pesky Collisions in Left 4 Dead 2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	// Smokers
	HookEvent("tongue_grab", Event_SurvivorPulled);
	HookEvent("tongue_release", Event_PullEnd);

	//Cvars
	hRockFix = CreateConVar("collision_tankrock_common", "1", "Will Rocks go through Common Infected (and also kill them) instead of possibly getting stuck on them?");
	hPullThrough = CreateConVar("collision_smoker_common", "0", "Will Pulled Survivors go through Common Infected?");
	hRockThroughIncap = CreateConVar("collision_tankrock_incap", "0", "Will Rocks go through Incapacitated Survivors? (Won't go through new incaps caused by the Rock)");
	
	CvarsInType();

	//Cvar Changes
	hRockFix.AddChangeHook(cvarChanged);
	hPullThrough.AddChangeHook(cvarChanged);
	hRockThroughIncap.AddChangeHook(cvarChanged);
	
	HookEvent("round_start", Event_Reset, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_Reset, EventHookMode_PostNoCopy);
}

public void cvarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
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
	if (!IsValidEdict(ent1) || !IsValidEdict(ent2)) {
		return Plugin_Continue;
	}

	GetEdictClassname(ent1, sEntityCName, sizeof(sEntityCName));
	GetEdictClassname(ent2, sEntityCNameTwo, sizeof(sEntityCNameTwo));

	if (strcmp(sEntityCName, "infected") == 0) {
		if (bRockFix && strcmp(sEntityCNameTwo, "tank_rock") == 0) {
			result = false;
			return Plugin_Handled;
		}

		if (bPullThrough && IsSurvivor(ent2) && isPulled[ent2]) {
			result = false;
			return Plugin_Handled;
		}
	} else if (strcmp(sEntityCNameTwo, "infected") == 0) {
		if (bRockFix && strcmp(sEntityCName, "tank_rock") == 0) {
			result = false;
			return Plugin_Handled;
		}

		if (bPullThrough && IsSurvivor(ent1) && isPulled[ent1]) {
			result = false;
			return Plugin_Handled;
		}
	} else if (strcmp(sEntityCName, "tank_rock") == 0) {
		if (bRockThroughIncap && IsSurvivorAndIncapacitated(ent2)) {
			result = false;
			return Plugin_Handled;
		}
	} else if (strcmp(sEntityCNameTwo, "tank_rock") == 0) {
		if (bRockThroughIncap && IsSurvivorAndIncapacitated(ent1)) {
			result = false;
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void Event_Reset(Event hEvent, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i <= MAXPLAYERS; i++) {
		isPulled[i] = false;
	}
}

public void Event_SurvivorPulled(Event hEvent, const char[] name, bool dontBroadcast)
{
	isPulled[GetClientOfUserId(hEvent.GetInt("victim"))] = true;
}

public void Event_PullEnd(Event hEvent, const char[] name, bool dontBroadcast)
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
