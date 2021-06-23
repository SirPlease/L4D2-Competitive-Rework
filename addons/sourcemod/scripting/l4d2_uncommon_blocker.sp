#pragma semicolon 1
#pragma newdecls required;

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define DEBUG                   false

#define UNC_CEDA                1
#define UNC_CLOWN               2
#define UNC_MUDMEN              4
#define UNC_RIOT                8
#define UNC_ROADCREW            16

ConVar hPluginEnabled; // convar: enable block
ConVar hBlockFlags; // convar: what to block

/*
    -----------------------------------------------------------------------------------------------------------------------------------------------------

    Changelog
    ---------
		0.1c
            - new syntax, little fixes
        0.1b
            - spawns common after killing uncommon entity
            
        0.1a
            - first version (not really optimized)

    -----------------------------------------------------------------------------------------------------------------------------------------------------
 */
public Plugin myinfo = 
{
	name = "Uncommon Infected Blocker",
	author = "Tabun", //sytax update A1m`
	description = "Blocks uncommon infected from ruining your day.",
	version = "0.1c",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

/* -------------------------------
 *      Init
 * ------------------------------- */
public void OnPluginStart()
{
	hPluginEnabled = CreateConVar("sm_uncinfblock_enabled", "1", "Enable the fix for the jockey-damage glitch.", _, true, 0.0, true, 1.0);
	hBlockFlags = CreateConVar("sm_uncinfblock_types",   "31", "Which uncommon infected to block (1:ceda, 2:clowns, 4:mudmen, 8:riot cops, 16:roadcrew).", _, true, 0.0);
}

/* -------------------------------
 *      General hooks / events
 * ------------------------------- */
public void OnEntityCreated(int entity, const char[] classname)
{
	if (strcmp(classname, "infected", false) == 0 && hPluginEnabled.BoolValue) {
		if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity)) {
			SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
		}
	}
}

public void OnEntitySpawned(int entity)
{
	if (isUncommon(entity)) {
		float location[3];
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
bool isUncommon(int entity)
{
	if (entity <= 0 || entity > 2048 || !IsValidEdict(entity)) {
		return false;
	}
	
	char model[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	int bBlockFlags = hBlockFlags.IntValue;

	if (StrContains(model, "_ceda") != -1 && (UNC_CEDA & bBlockFlags)) { 
		return true;
	}
	
	if (StrContains(model, "_clown") != -1 && (UNC_CLOWN & bBlockFlags)) { 
		return true;
	}
	
	if (StrContains(model, "_mud") != -1 && (UNC_MUDMEN & bBlockFlags)) {
		return true;
	}
	
	if (StrContains(model, "_riot") != -1 && (UNC_RIOT & bBlockFlags)) {
		return true;
	}
	
	if (StrContains(model, "_roadcrew") != -1 && (UNC_ROADCREW & bBlockFlags)) {
		return true;
	}
	
	return false;
}

public void SpawnCommon(float location[3])
{
	int zombie = CreateEntityByName("infected");

	//SetEntityModel(zombie, "model string here");  // just leaving this default for now..
	
	/*
	 * Original game code:
	 * #define TIME_TO_TICKS( dt )		( (int)( 0.5f + (float)(dt) / TICK_INTERVAL ) ) 
	 * SetNextThink( TIME_TO_TICKS(gpGlobals->curtime ) );
	 * Right?
	*/
	int iTickTime = RoundToNearest(GetGameTime() / GetTickInterval()) + 5; //think in next tick?  // copied from uncommon spawner plugin, prolly helps avoid the zombie get 'stuck' ?      
	
	SetEntProp(zombie, Prop_Data, "m_nNextThinkTick", iTickTime);

	DispatchSpawn(zombie);
	ActivateEntity(zombie);

	TeleportEntity(zombie, location, NULL_VECTOR, NULL_VECTOR);

	#if DEBUG
	PrintToChatAll("Spawned common (loc: %.0f %.0f %.0f)", location[0], location[1], location[2]);
	#endif
}