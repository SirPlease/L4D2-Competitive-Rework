#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define Z_HUNTER 3
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

static const int deadstopSequences[] = {64, 67, 11, 8};

public Plugin myinfo = 
{
	name = "L4D2 No Hunter Deadstops",
	author = "Visor, A1m",
	description = "Self-descriptive",
	version = "3.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public Action L4D_OnShovedBySurvivor(int shover, int shovee, const float vector[3])
{
	return Shove_Handler(shover, shovee);
}

public Action L4D2_OnEntityShoved(int shover, int shovee_ent, int weapon, float vector[3], bool bIsHunterDeadstop)
{
	return Shove_Handler(shover, shovee_ent);
}

Action Shove_Handler(int shover, int shovee)
{
	if (!IsSurvivor(shover) || !IsHunter(shovee)) {
		return Plugin_Continue;
	}
	
	if (HasTarget(shovee)) {
		return Plugin_Continue;
	}
	
	if (IsPlayingDeadstopAnimation(shovee)) {
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
} 

bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR);
}

bool IsInfected(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED);
}

bool IsHunter(int client)
{
	if (!IsInfected(client)) {
		return false;
	}
	
	if (!IsPlayerAlive(client)) {
		return false;
	}
	
	if (GetEntProp(client, Prop_Send, "m_zombieClass") != Z_HUNTER) {
		return false;
	}
	
	return true;
}

bool IsPlayingDeadstopAnimation(int hunter)
{
	int sequence = GetEntProp(hunter, Prop_Send, "m_nSequence");
	for (int i = 0; i < sizeof(deadstopSequences); i++) {
		if (deadstopSequences[i] == sequence) {
			return true;
		}
	}
	return false;
}

bool HasTarget(int hunter)
{
	int target = GetEntPropEnt(hunter, Prop_Send, "m_pounceVictim");

	return (IsSurvivor(target) && IsPlayerAlive(target));
}
