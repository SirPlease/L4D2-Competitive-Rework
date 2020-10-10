#include <sourcemod>
#include <left4dhooks>

#define TEAM_SURVIVOR           2
#define TEAM_INFECTED           3

#define HUNTER_GROUND_M2_GODFRAMES GetConVarFloat(cvarHunterGroundM2Godframes)

new     bool:           bIsPouncing[MAXPLAYERS+1];                                                      // whether hunter player is currently pouncing/lunging
new     Float:          bIsPouncingStartTime[MAXPLAYERS+1];  // Pouncing stop time 
new     Float:          bIsPouncingStopTime[MAXPLAYERS+1];  // Pouncing stop time 

new ConVar:cvarHunterGroundM2Godframes;

public Plugin:myinfo = 
{
	name = "[L4D2] No Hunter Deadstops",
	author = "Spoon & Luckylock",
	description = "Prevents deadstops but allows m2s on standing hunters",
	version = "1.0.1",
	url = "https://github.com/luckyserv"
};

public OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("ability_use", Event_AbilityUse, EventHookMode_Post);

    cvarHunterGroundM2Godframes = CreateConVar("hunter_ground_m2_godframes", "0.75", "m2 godframes after a hunter lands on the ground", FCVAR_NONE, true, 0.0, true, 1.0);
}

public Action:L4D_OnShovedBySurvivor(shover, shovee, const Float:vector[3])
{
    return Shove_Handler(shover, shovee);
}

public Action:L4D2_OnEntityShoved(shover, shovee, weapon, Float:vector[3], bool:bIsHunterDeadstop)
{
    return Shove_Handler(shover, shovee);
}

public Action Shove_Handler(shover, shovee) {

	// Check to make sure the shover is a survivor and the client being shoved is a hunter
	if (!IsSurvivor(shover) || !IsHunter(shovee)) {
		return Plugin_Continue;
    }

	// If the hunter is lunging (pouncing) block m2s
	if (bIsPouncing[shovee])
	{
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
stock bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

// check if client is on infected team
stock bool:IsInfected(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}

// check if client is a hunter
stock bool:IsHunter(client)  
{
	if (!IsInfected(client))
		return false;
		
	if (!IsPlayerAlive(client))
		return false;

	if (GetEntProp(client, Prop_Send, "m_zombieClass") != 3)
		return false;

	return true;
}

// check if the hunter is on a survivor 
bool:HasTarget(hunter)
{
	new target = GetEntDataEnt2(hunter, 16004);
	return (IsSurvivor(target) && IsPlayerAlive(target));
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    // clear SI tracking stats
    for (new i=1; i <= MaxClients; i++)
    {
        bIsPouncing[i] = false;
    }
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new victim = GetClientOfUserId(GetEventInt(event, "userId"));

    if (!IsClientAndInGame(victim)) { return; }

    bIsPouncing[victim] = false;
}

// hunters pouncing / tracking
public Event_AbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
    // track hunters pouncing
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new String:abilityName[64];

    if (!IsClientAndInGame(client) || GetClientTeam(client) != TEAM_INFECTED) { return; }

    GetEventString(event, "ability", abilityName, sizeof(abilityName));

    if (strcmp(abilityName, "ability_lunge", false) == 0)
    {
        // Hunter pounce
        bIsPouncingStopTime[client] = 0.0;
        bIsPouncingStartTime[client] = GetGameTime();
        bIsPouncing[client] = true;
    }
}

public void OnGameFrame() {
    for (new client = 1; client < MAXPLAYERS+1; ++client) {

        bIsPouncing[client] = bIsPouncing[client] && IsClientAndInGame(client) && IsPlayerAlive(client);

        if (bIsPouncing[client]) {

            if (GetGameTime() - bIsPouncingStartTime[client] > 0.04) {

                if (bIsPouncingStopTime[client] == 0.0) {
                    if (IsGrounded(client)) {
                        // PrintToChatAll("Hunter grounded (buffer = %.0f ms)", HUNTER_GROUND_M2_GODFRAMES * 1000);
                        bIsPouncingStopTime[client] = GetGameTime();    
                    }

                } else if (GetGameTime() - bIsPouncingStopTime[client] > HUNTER_GROUND_M2_GODFRAMES) {
                    // PrintToChatAll("Not pouncing anymore.");
                    bIsPouncing[client] = false;    
                }
            }
        }
    } 
}

public bool:IsGrounded(client)
{
    return (GetEntProp(client,Prop_Data,"m_fFlags") & FL_ONGROUND) > 0;
}

bool:IsClientAndInGame(index)
{
    if (index > 0 && index <= MaxClients)
    {
        return IsClientInGame(index);
    }
    return false;
}