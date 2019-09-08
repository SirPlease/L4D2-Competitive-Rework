#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define GAMEDATA_FILE           "staggersolver"

#define TEAM_SURVIVOR           2
#define TEAM_INFECTED           3

#define ZC_SMOKER               1
#define ZC_BOOMER               2
#define ZC_HUNTER               3
#define ZC_SPITTER              4
#define ZC_JOCKEY               5
#define ZC_CHARGER              6

// Bit flags to enable individual features of the plugin
#define SKEET_POUNCING_AI       (0x01)
#define DEBUFF_CHARGING_AI      (0x02)
#define BLOCK_STUMBLE_SCRATCH   (0x04)
#define ALL_FEATURES            (SKEET_POUNCING_AI | DEBUFF_CHARGING_AI | BLOCK_STUMBLE_SCRATCH)

// Globals
new     Handle:         hGameConf;
new     Handle:         hIsStaggering;
new     bool:           bLateLoad                                               = false;

// CVars
new                     fEnabled                                                = ALL_FEATURES;         // Enables individual features of the plugin
new                     iPounceInterrupt                                        = 150;                  // Caches pounce interrupt cvar's value
new                     iHunterSkeetDamage[MAXPLAYERS+1]                        = { 0, ... };           // How much damage done in a single hunter leap so far


/*
    
    Changelog
    ---------
        
        1.0.9
            - used CanadaRox's SDK method for detecting staggers (since it's less likely to have false positives).

        1.0.8
            - fixed bug where clients with maxclient index would be ignored

        1.0.7
            - reset original way of dealing extra skeet damage to reward killer.

        1.0.6
            - (dcx2) Removed ground-tracking timer for hunter skeet, switched to m_isAttemptingToPounce
            - (dcx2) Removed handles from global variables, since they are unused after OnPluginStart
            - (dcx2) Switched hunter skeeting to SetEntityHealth() for increased compatibility with damage tracking plugins (ie l4d2_assist)

        1.0.5 
            - (dcx2) Added enable cvar
            - (dcx2) cached pounce interrupt cvar
            - (dcx2) fixed charger debuff calculation
            
        1.0.4 
            - Used dcx2's much better IN_ATTACK2 method of blocking stumble-scratching.
            
        1.0.3
            - Added stumble-negation inflictor check so only SI scratches are affected.
        
        1.0.2
            - Fixed incorrect bracketing that caused error spam. (Re-fixed because drunk)
        
        1.0.0
            - Blocked AI scratches-while-stumbling from doing any damage.
            - Replaced clunky charger tracking with simple netprop check.
        
        0.0.5 and older
            - Small fix for chargers getting 1 damage for 0-damage events.
            - simulates human-charger damage behavior while charging for AI chargers.
            - simulates human-hunter skeet behavior for AI hunters.

    -----------------------------------------------------------------------------------------------------------------------------------------------------
 */

public Plugin:myinfo =
{
    name = "Bot SI skeet/level damage fix",
    author = "Tabun, dcx2",
    description = "Makes AI SI take (and do) damage like human SI.",
    version = "1.0.9",
    url = "https://github.com/Tabbernaut/L4D2-Plugins/tree/master/ai_damagefix"
}

public APLRes:AskPluginLoad2( Handle:plugin, bool:late, String:error[], errMax)
{
    bLateLoad = late;
    return APLRes_Success;
}


public OnPluginStart()
{
    // find/create cvars, hook changes, cache current values
    new Handle:hCvarEnabled = CreateConVar("sm_aidmgfix_enable", "7", "Bit flag: Enables plugin features (add together): 1=Skeet pouncing AI, 2=Debuff charging AI, 4=Block stumble scratches, 7=all, 0=off", FCVAR_PLUGIN|FCVAR_NOTIFY);
    new Handle:hCvarPounceInterrupt = FindConVar("z_pounce_damage_interrupt");

    HookConVarChange(hCvarEnabled, OnAIDamageFixEnableChanged);
    HookConVarChange(hCvarPounceInterrupt, OnPounceInterruptChanged);

    fEnabled = GetConVarInt(hCvarEnabled);
    iPounceInterrupt = GetConVarInt(hCvarPounceInterrupt);

    // events
    HookEvent("ability_use", Event_AbilityUse, EventHookMode_Post);
    
    // hook when loading late
    if (bLateLoad) {
        for (new i = 1; i < MaxClients + 1; i++) {
            if (IsClientAndInGame(i)) {
                OnClientPostAdminCheck(i);
            }
        }
    }
    
    // sdkhook
    hGameConf = LoadGameConfigFile(GAMEDATA_FILE);
    if (hGameConf == INVALID_HANDLE)
    SetFailState("[aidmgfix] Could not load game config file (staggersolver.txt).");

    StartPrepSDKCall(SDKCall_Player);

    if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "IsStaggering"))
    SetFailState("[aidmgfix] Could not find signature IsStaggering.");
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    hIsStaggering = EndPrepSDKCall();
    if (hIsStaggering == INVALID_HANDLE)
    SetFailState("[aidmgfix] Failed to load signature IsStaggering");

    CloseHandle(hGameConf);
}


public OnAIDamageFixEnableChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    fEnabled = StringToInt(newVal);
}

public OnPounceInterruptChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    iPounceInterrupt = StringToInt(newVal);
}


public OnClientPostAdminCheck(client)
{
    // hook bots spawning
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    iHunterSkeetDamage[client] = 0;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    // Must be enabled, victim and attacker must be ingame, damage must be greater than 0, victim must be AI infected
    if (fEnabled && IsClientAndInGame(victim) && IsClientAndInGame(attacker) && damage > 0.0 && GetClientTeam(victim) == TEAM_INFECTED && IsFakeClient(victim))
    {
        new zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

        // Is this AI hunter attempting to pounce?
        if (zombieClass == ZC_HUNTER && (fEnabled & SKEET_POUNCING_AI) && GetEntProp(victim, Prop_Send, "m_isAttemptingToPounce"))
        {
            iHunterSkeetDamage[victim] += RoundToFloor(damage);
            
            // have we skeeted it?
            if (iHunterSkeetDamage[victim] >= iPounceInterrupt)
            {
                // Skeet the hunter
                iHunterSkeetDamage[victim] = 0;
                damage = float(GetClientHealth(victim));
                return Plugin_Changed;
            }
        }
        else if (zombieClass == ZC_CHARGER && (fEnabled & DEBUFF_CHARGING_AI))
        {
            // Is this AI charger charging?
            new abilityEnt = GetEntPropEnt(victim, Prop_Send, "m_customAbility");
            if (IsValidEntity(abilityEnt) && GetEntProp(abilityEnt, Prop_Send, "m_isCharging") > 0)
            {
                // Game does Floor(Floor(damage) / 3 - 1) to charging AI chargers, so multiply Floor(damage)+1 by 3
                damage = (damage - FloatFraction(damage) + 1.0) * 3.0;
                return Plugin_Changed;
            }
        }
    }
    
    return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons)
{
    // If the AI Infected is staggering, block melee so they can't scratch
    if ((fEnabled & BLOCK_STUMBLE_SCRATCH) && IsClientAndInGame(client) && GetClientTeam(client) == TEAM_INFECTED && IsFakeClient(client) && SDKCall(hIsStaggering, client))
    {
        buttons &= ~IN_ATTACK2;
    }
    
    return Plugin_Continue;
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
        // Clear skeet tracking damage each time the hunter starts a pounce
        iHunterSkeetDamage[client] = 0;
    }
}

bool:IsClientAndInGame(index)
{
    return (index > 0 && index <= MaxClients && IsClientInGame(index));
}
