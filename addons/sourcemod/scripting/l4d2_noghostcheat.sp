#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo =
{
	name = "L4D2 Ghost-Cheat Preventer",
	author = "Sir",
	description = "Don't broadcast Infected entities to Survivors while in ghost mode, disabling them from hooking onto the entities with 3rd party programs.",
	version = "1.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

// Game events that give away where a ghost is (checkpoint nav areas, entities it can see).
static const char g_sGhostEvents[][] =
{
	"player_left_checkpoint",
	"weapon_spawn_visible",
	"entity_visible"
};

public void OnPluginStart()
{
	for (int i = 0; i < sizeof(g_sGhostEvents); i++) {
		HookEvent(g_sGhostEvents[i], Event_GhostPosition, EventHookMode_Pre);
	}

	for (int client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client)) {
			OnClientPutInServer(client);
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strncmp(classname, "weapon_", 7) == 0 && StrContains(classname, "_claw") != -1) {
		SDKHook(entity, SDKHook_SetTransmit, Hook_ClawSetTransmit);
	}
}

Action Hook_SetTransmit(int client, int entity)
{
	/*
		By default Valve still transmits the entities to Survivors, even when not in sight or in ghost mode.
		Detecting if a player is actually in someone's sight is likely impossible to implement without issues, but blocking ghosts from being transmitted has no downsides.
		This code will prevent 3rd party programs from hooking onto unspawned Infected.
	*/
	if (IsGhostHiddenFrom(client, entity)) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

Action Hook_ClawSetTransmit(int claw, int entity)
{
	/*
		A ghost's claw is transmitted which follows the ghost around,
		so it would still tell Survivors whether (and which) ghost is near them.
	*/
	if (IsGhostHiddenFrom(GetEntPropEnt(claw, Prop_Send, "m_hOwnerEntity"), entity)) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

Action Event_GhostPosition(Event event, const char[] name, bool dontBroadcast)
{
	/*
		Cheats can hook and read any game event that is broadcast to players, so these would tell everyone where a ghost is.
		In the 3 events that we hooked we only care about networked events where the Ghost Infected is the client, which will
		expose the ghost's position to Survivors.
	*/
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (dontBroadcast || !IsValidClient(client) || GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_isGhost") != 1) {
		return Plugin_Continue;
	}

	event.BroadcastDisabled = true;

	/*
		We'll still broadcast the event to the ghost itself to prevent any possible issues with their client
		I'm not sure if this is necessary, but it won't hurt.
	*/
	if (!IsFakeClient(client)) {
		event.FireToClient(client);
	}

	return Plugin_Continue;
}

// Is 'ghost' an Infected in ghost mode and the 'viewer' a Survivor?
bool IsGhostHiddenFrom(int ghost, int viewer)
{
	return IsValidClient(ghost) && IsValidClient(viewer)
		&& GetClientTeam(ghost) == 3
		&& GetClientTeam(viewer) == 2
		&& GetEntProp(ghost, Prop_Send, "m_isGhost") == 1;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}
