#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define Z_HUNTER 3
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

bool bIsPouncing[MAXPLAYERS + 1]; // whether hunter player is currently pouncing/lunging

float 
	bIsPouncingStartTime[MAXPLAYERS + 1],  // Pouncing stop time 
	bIsPouncingStopTime[MAXPLAYERS + 1];  // Pouncing stop time 

ConVar
	cvarHunterGroundM2Godframes;

public Plugin myinfo = 
{
	name = "[L4D2] No Hunter Deadstops",
	author = "Spoon, Luckylock, A1m`",
	description = "Prevents deadstops but allows m2s on standing hunters",
	version = "1.0.3",
	url = "https://github.com/luckyserv"
};

public void OnPluginStart()
{
	HookEvent("round_start", view_as<EventHook>(Event_RoundStart), EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("ability_use", Event_AbilityUse, EventHookMode_Post);

	cvarHunterGroundM2Godframes = CreateConVar("hunter_ground_m2_godframes", "0.75", "m2 godframes after a hunter lands on the ground", _, true, 0.0, true, 1.0);
}

public Action L4D_OnShovedBySurvivor(int shover, int shovee, const float vecDir[3])
{
	return Shove_Handler(shover, shovee);
}

public Action L4D2_OnEntityShoved(int shover, int shovee, int weapon, float vecDir[3], bool bIsHighPounce)
{
	return Shove_Handler(shover, shovee);
}

Action Shove_Handler(int shover, int shovee)
{
	// Check to make sure the shover is a survivor and the client being shoved is a hunter
	if (!IsSurvivor(shover) || !IsHunter(shovee)) {
		return Plugin_Continue;
	}

	// If the hunter is lunging (pouncing) block m2s
	if (bIsPouncing[shovee]) {
		return Plugin_Handled;
	}
	
	// If the hunter is on a survivor, allow m2s
	if (HasTarget(shovee)) {
		return Plugin_Continue;
	}

	//// If the hunter is crouching and on the ground, block m2s
	//if ((GetEntityFlags(shovee) & FL_DUCKING) && (GetEntityFlags(shovee) & FL_ONGROUND))
	//{
	//	return Plugin_Handled;
	//}
	
	return Plugin_Continue;
} 

// check if client is on survivor team
bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR);
}

// check if client is on infected team
bool IsInfected(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED);
}

// check if client is a hunter
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

// check if the hunter is on a survivor 
bool HasTarget(int hunter)
{
	int target = GetEntPropEnt(hunter, Prop_Send, "m_pounceVictim");

	return (IsSurvivor(target) && IsPlayerAlive(target));
}

public void Event_RoundStart()
{
	// clear SI tracking stats
	for (int i = 1; i <= MaxClients; i++)
	{
		bIsPouncing[i] = false;
	}
}

public void Event_PlayerDeath(Event hEvent, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(hEvent.GetInt("userid"));

	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim)) { 
		return;
	}

	bIsPouncing[victim] = false;
}

// hunters pouncing / tracking
public void Event_AbilityUse(Event hEvent, const char[] name, bool dontBroadcast)
{
	// track hunters pouncing
	char abilityName[64];
	hEvent.GetString("ability", abilityName, sizeof(abilityName));
	
	if (strcmp(abilityName, "ability_lunge", false) == 0) {
		int client = GetClientOfUserId(hEvent.GetInt("userid"));
		
		if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED) { 
			// Hunter pounce
			bIsPouncingStopTime[client] = 0.0;
			bIsPouncingStartTime[client] = GetGameTime();
			bIsPouncing[client] = true;
		}
	}
}

public void OnGameFrame()
{
	float fNow = GetGameTime();
	for (int client = 1; client <= MaxClients; client++) {
		bIsPouncing[client] = bIsPouncing[client] && IsClientInGame(client) && IsPlayerAlive(client);

		if (bIsPouncing[client]) {
			if (fNow - bIsPouncingStartTime[client] > 0.04) {

				if (bIsPouncingStopTime[client] == 0.0) {
					if (GetEntityFlags(client) & FL_ONGROUND) {
						// PrintToChatAll("Hunter grounded (buffer = %.0f ms)", cvarHunterGroundM2Godframes.FloatValue * 1000);
						bIsPouncingStopTime[client] = fNow;    
					}
				} else if (fNow - bIsPouncingStopTime[client] > cvarHunterGroundM2Godframes.FloatValue) {
					// PrintToChatAll("Not pouncing anymore.");
					bIsPouncing[client] = false;
				}
			}
		}
	} 
}
