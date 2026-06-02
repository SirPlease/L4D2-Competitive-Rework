#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define TEAM_SURVIVOR           2
#define TEAM_INFECTED           3

#define ZC_SMOKER               1
#define ZC_BOOMER               2
#define ZC_HUNTER               3
#define ZC_SPITTER              4
#define ZC_JOCKEY               5
#define ZC_CHARGER              6

#define POUNCE_TIMER            0.1


// CVars
bool bLateLoad                                               = false;
ConVar  hCvarPounceInterrupt                                 = null;

int iHunterSkeetDamage[MAXPLAYERS+1];                                               // how much damage done in a single hunter leap so far
bool bIsPouncing[MAXPLAYERS+1];                                                      // whether hunter player is currently pouncing/lunging

public Plugin myinfo =
{
    name = "Bot SI skeet/level damage fix",
    author = "Tabun & HarryPotter",
    description = "Makes AI SI take (and do) damage like human SI.",
    version = "1.3",
    url = "nope"
}

public APLRes AskPluginLoad2( Handle plugin, bool late, char[] error, int errMax)
{
    bLateLoad = late;
    return APLRes_Success;
}


public void OnPluginStart()
{
    // cvars
    hCvarPounceInterrupt = FindConVar("z_pounce_damage_interrupt");
    
    // events
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("player_shoved", Event_PlayerShoved, EventHookMode_Post);
    HookEvent("ability_use", Event_AbilityUse, EventHookMode_Post);
    
    // hook when loading late
    if (bLateLoad) {
        for (int i = 1; i < MaxClients + 1; i++) {
            if (IsClientAndInGame(i)) {
                OnClientPutInServer(i);
            }
        }
    }
}


public void OnClientPutInServer(int client)
{
    // hook bots spawning
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    bIsPouncing[client] = false; 
    iHunterSkeetDamage[client] = 0;
}

public void OnClientDisconnect(int client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}



public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!IsClientAndInGame(victim) || !IsClientAndInGame(attacker) || damage == 0.0) { return Plugin_Continue; }
    
    // AI taking damage
    if (GetClientTeam(victim) == TEAM_INFECTED && IsFakeClient(victim))
    {
        // check if AI is hit while in lunge/charge
        
        int zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
        int abilityEnt = 0;
        
        switch (zombieClass) {
            
            case ZC_HUNTER: {
                // skeeting mechanic is completely disabled for AI,
                // so we have to replicate it.
                
                iHunterSkeetDamage[victim] += RoundToFloor(damage);
                
                // have we skeeted it?
                if (bIsPouncing[victim] && iHunterSkeetDamage[victim] >= GetConVarInt(hCvarPounceInterrupt))
                {
                    bIsPouncing[victim] = false; 
                    iHunterSkeetDamage[victim] = 0;
                    
                    // this should be a skeet
                    damage = float(GetClientHealth(victim));
                    return Plugin_Changed;
                }
            }
            
            case ZC_CHARGER: {
                // all damage gets divided by 3 while AI is charging,
                // so all we have to do is multiply by 3.
                
                abilityEnt = GetEntPropEnt(victim, Prop_Send, "m_customAbility");
                bool isCharging = false;
                if (abilityEnt > 0) {
                    isCharging = (GetEntProp(abilityEnt, Prop_Send, "m_isCharging") > 0) ? true : false;
                }
                
                if (isCharging)
                {
                    damage = (damage * 3) + 1;
                    return Plugin_Changed;
                }
            }
            
        }
    }
    return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
    // clear SI tracking stats
    for (int i=1; i <= MaxClients; i++)
    {
        iHunterSkeetDamage[i] = 0;
        bIsPouncing[i] = false;
    }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
    int victim = GetClientOfUserId(event.GetInt("userId"));
    
    if (!IsClientAndInGame(victim)) { return; }
    
    bIsPouncing[victim] = false;
}

public void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast) 
{
    int victim = GetClientOfUserId(event.GetInt("userId"));
    
    if (!IsClientAndInGame(victim)) { return; }
    
    bIsPouncing[victim] = false;
}


// hunters pouncing / tracking
public void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast) 
{
    // track hunters pouncing
    int client = GetClientOfUserId(event.GetInt("userid"));
    char abilityName[64];
    
    if (!IsClientAndInGame(client) || GetClientTeam(client) != TEAM_INFECTED) { return; }
    
    GetEventString(event, "ability", abilityName, sizeof(abilityName));
    
    if (!bIsPouncing[client] && strcmp(abilityName, "ability_lunge", false) == 0)
    {
        // Hunter pounce
        bIsPouncing[client] = true;
        iHunterSkeetDamage[client] = 0;                                     // use this to track skeet-damage
        
        CreateTimer(POUNCE_TIMER, Timer_GroundTouch, client, TIMER_REPEAT); // check every TIMER whether the pounce has ended
                                                                            // If the hunter lands on another player's head, they're technically grounded.
                                                                            // Instead of using isGrounded, this uses the bIsPouncing[] array with less precise timer
    }
}

public Action Timer_GroundTouch(Handle timer, any client)
{
    if (IsClientAndInGame(client) && ((IsGrounded(client)) || !IsPlayerAlive(client)|| !IsFakeClient(client) || IsOnLadder(client)) )
    {
        // Reached the ground or died in mid-air
        bIsPouncing[client] = false;
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

public bool IsGrounded(int client)
{
    return (GetEntProp(client,Prop_Data,"m_fFlags") & FL_ONGROUND) > 0;
}

bool IsClientAndInGame(int index)
{
    if (index > 0 && index <= MaxClients)
    {
        return IsClientInGame(index);
    }
    return false;
}


bool IsOnLadder(int entity)
{
    return GetEntityMoveType(entity) == MOVETYPE_LADDER;
}
