#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

#define DEBUG 0

#define MAX_ENTITY_NAME_SIZE 64

#define TEAM_INFECTED 3

bool
	g_bLateLoad = false;

public Plugin myinfo =
{
	name = "L4D2 Explosion Damage Prevention",
	author = "Sir, A1m`",
	version = "1.1",
	description = "No more explosion damage to the infected from entity",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;

	return APLRes_Success;
}

public void OnPluginStart()
{
	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!(damagetype & DMG_BLAST)) {
		return Plugin_Continue;
	}
	
	// If the victim an infected taken explosive damage from the entity
	// env_explosion, trigger_hurt, point_hurt etc...
	if (attacker > MaxClients && IsValidEntity(attacker) && IsInfected(victim)) {
		#if DEBUG
			char sEntityName[MAX_ENTITY_NAME_SIZE];
			GetEntityClassname(attacker, sEntityName, sizeof(sEntityName));
			PrintToChatAll("hOnTakeDamage victim: %d, attacker: %d (%s), inflictor: %d, damage: %f, damagetype: %d", \
								victim, attacker, sEntityName, inflictor, damage, damagetype);
		#endif
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

bool IsInfected(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED);
}
