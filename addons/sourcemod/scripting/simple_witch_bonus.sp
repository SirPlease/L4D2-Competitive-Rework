#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d2_penalty_bonus>

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_SURVIVOR(%1)         (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_SURVIVOR(%1)   (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_SURVIVOR_ALIVE(%1)   (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1)   (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))


new     bool:           g_bLateLoad                                         = false;
new     Handle:         g_hCvarBonus                                        = INVALID_HANDLE;
new     Handle:         g_hCvarPrint                                        = INVALID_HANDLE;
new     Handle:         g_hCvarBonusAlways                                  = INVALID_HANDLE;
new     Handle:         g_hTrieEntityCreated                                = INVALID_HANDLE;
new     Handle:         g_hWitchTrie                                        = INVALID_HANDLE;

// trie values: OnEntityCreated classname
enum strOEC
{
    OEC_WITCH
};


public Plugin:myinfo = 
{
    name = "Simple Witch Kill Bonus",
    author = "Tabun",
    description = "Gives bonus for witches getting killed without doing damage to survivors (uses pbonus).",
    version = "0.9.3",
    url = "none"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    g_bLateLoad = late;    
    return APLRes_Success;
}

public OnPluginStart()
{
    HookEvent("witch_spawn", Event_WitchSpawned, EventHookMode_Post);
    HookEvent("witch_killed", Event_WitchKilled, EventHookMode_Post);

    g_hCvarBonus = CreateConVar("sm_simple_witch_bonus", "25", "Bonus points to award for clean witch kills.", FCVAR_NONE, true, 0.0);
    g_hCvarPrint = CreateConVar("sm_witch_bonus_print", "1", "Should we print when we award points for killing the witch?", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvarBonusAlways = CreateConVar("sm_witch_bonus_always", "0", "Should you receive points when something other than survivors kills witch?", FCVAR_NONE, true, 0.0, true, 1.0);

    g_hWitchTrie = CreateTrie();
    g_hTrieEntityCreated = CreateTrie();
    SetTrieValue(g_hTrieEntityCreated, "witch", OEC_WITCH);

    if (g_bLateLoad) {
        for (new client = 1; client <= MaxClients; client++) {
            if (IS_VALID_INGAME(client)) {
                SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageByWitch);
            }
        }
    }
}

// player damage tracking
public OnClientPostAdminCheck(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageByWitch);
}
public OnClientDisconnect(client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamageByWitch);
}

// entity destruction
public OnEntityDestroyed(entity)
{
    decl String:witch_key[10];
    FormatEx(witch_key, sizeof(witch_key), "%x", entity);
    
    RemoveFromTrie(g_hWitchTrie, witch_key);
}

// witch tracking
public Action: Event_WitchSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
    new witch = GetEventInt(event, "witchid");    
    decl String:witch_key[10];
    FormatEx(witch_key, sizeof(witch_key), "%x", witch);
    SetTrieValue(g_hWitchTrie, witch_key, 0);
}

// kill tracking
public Action: Event_WitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
    new witch = GetEventInt(event, "witchid");
    new attacker = GetClientOfUserId( GetEventInt(event, "userid") );

    // only award bonus if survivors deal the last blow
    if ( !IS_VALID_SURVIVOR(attacker) &&  GetConVarBool(g_hCvarBonusAlways) == false ) {
        return Plugin_Continue;
    }
    
    // only award bonus if witch didn't get a scratch off
    decl String:witch_key[10];
    FormatEx(witch_key, sizeof(witch_key), "%x", witch);

    new witch_check;
    if (!GetTrieValue(g_hWitchTrie, witch_key, witch_check) || !witch_check) {
        GiveWitchBonus();
    }

    return Plugin_Continue;
}

// track witch doing damage to survivors
public Action: OnTakeDamageByWitch(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if (IS_VALID_SURVIVOR(victim) && damage > 0.0) {
        if (IsWitch(attacker)) {
            decl String:witch_key[10];
            FormatEx(witch_key, sizeof(witch_key), "%x", attacker);
            SetTrieValue(g_hWitchTrie, witch_key, 1);
        }
    }
}

// apply bonus, through PenaltyBonus
stock GiveWitchBonus()
{
    new iBonus = GetConVarInt(g_hCvarBonus);
    if(GetConVarBool(g_hCvarPrint) == true)
	{
        PrintToChatAll("\x01Killing the witch has awarded: \x05%d \x01points!", iBonus);
    }
    PBONUS_AddRoundBonus(iBonus, true);
}

stock bool: IsWitch(entity)
{
    if (!IsValidEntity(entity)) {
        return false;
    }
    
    decl String: classname[24];
    new strOEC: classnameOEC;
    GetEdictClassname(entity, classname, sizeof(classname));

    return !(!GetTrieValue(g_hTrieEntityCreated, classname, classnameOEC) || classnameOEC != OEC_WITCH);
}