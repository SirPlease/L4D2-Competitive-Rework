#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 
#include <sdkhooks>

#define DEBUG                   false

#define UNC_CEDA                1
#define UNC_CLOWN               2
#define UNC_MUDMEN              4
#define UNC_RIOT                8
#define UNC_ROADCREW            16

new Handle: hPluginEnabled;                                     // convar: enable block
new Handle: hBlockFlags =       INVALID_HANDLE;                 // convar: what to block


/*
    -----------------------------------------------------------------------------------------------------------------------------------------------------

    Changelog
    ---------
        0.1b
            - spawns common after killing uncommon entity
            
        0.1a
            - first version (not really optimized)

    -----------------------------------------------------------------------------------------------------------------------------------------------------
 */


public Plugin:myinfo = 
{
    name = "Uncommon Infected Blocker",
    author = "Tabun",
    description = "Blocks uncommon infected from ruining your day.",
    version = "0.1b",
    url = "nope"
}

/* -------------------------------
 *      Init
 * ------------------------------- */

public OnPluginStart()
{
    // cvars
    hPluginEnabled = CreateConVar("sm_uncinfblock_enabled", "1", "Enable the fix for the jockey-damage glitch.", FCVAR_NONE, true, 0.0, true, 1.0);
    hBlockFlags =    CreateConVar("sm_uncinfblock_types",   "31", "Which uncommon infected to block (1:ceda, 2:clowns, 4:mudmen, 8:riot cops, 16:roadcrew).", FCVAR_NONE, true, 0.0);
}

/* -------------------------------
 *      General hooks / events
 * ------------------------------- */

public OnEntityCreated(entity, const String:classname[])
{
    if (!GetConVarBool(hPluginEnabled)) { return; }
    
    if(entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
    {
        if (StrEqual(classname, "infected", false))
        {
            SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
        }
    }
}


public OnEntitySpawned(entity)
{
    if (isUncommon(entity))
    {

        
        new Float: location[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", location);           // get location
        
        AcceptEntityInput(entity, "Kill");                                      // kill the uncommon
        
	#if DEBUG
	PrintToChatAll("Blocked uncommon (loc: %.0f %.0f %.0f)", location[0], location[1], location[2]);
	#endif
        
        SpawnCommon(location);                                                  // spawn common in location instead
    }
}

    
/* --------------------------------------
 *     Shared function(s)
 * -------------------------------------- */

stock bool:isUncommon(entity)
{
    if (entity <= 0 || entity > 2048 || !IsValidEdict(entity)) return false;
    decl String:model[128];
    
    GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
    new bBlockFlags = GetConVarInt(hBlockFlags);
    
    if (StrContains(model, "_ceda") != -1       && (UNC_CEDA & bBlockFlags))     { return true; }
    if (StrContains(model, "_clown") != -1      && (UNC_CLOWN & bBlockFlags))    { return true; }
    if (StrContains(model, "_mud") != -1        && (UNC_MUDMEN & bBlockFlags))   { return true; }
    if (StrContains(model, "_riot") != -1       && (UNC_RIOT & bBlockFlags))     { return true; }
    if (StrContains(model, "_roadcrew") != -1   && (UNC_ROADCREW & bBlockFlags)) { return true; }
    return false;
}

public SpawnCommon(Float:location[3])
{
    new zombie = CreateEntityByName("infected");
    
    //SetEntityModel(zombie, "model string here");  // just leaving this default for now..
    
    new ticktime = RoundToNearest( FloatDiv( GetGameTime() , GetTickInterval() ) ) + 5;         // copied from uncommon spawner plugin, prolly helps avoid the zombie get 'stuck' ?
    SetEntProp(zombie, Prop_Data, "m_nNextThinkTick", ticktime);

    DispatchSpawn(zombie);
    ActivateEntity(zombie);
    
    TeleportEntity(zombie, location, NULL_VECTOR, NULL_VECTOR);
    
    #if DEBUG
    PrintToChatAll("Spawned common (loc: %.0f %.0f %.0f)", location[0], location[1], location[2]);
    #endif
}