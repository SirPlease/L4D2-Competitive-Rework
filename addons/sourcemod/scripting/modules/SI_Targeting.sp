#include "includes/hardcoop_util.sp"

new Handle:arraySurvivors; // dynamic array holding only the survivor entity IDs
new targetSurvivor[MAXPLAYERS+1]; // survivor target of each special infected

public SI_TargetingModule_Start() 
{
	// Initialise dynamic arrays
	arraySurvivors = CreateArray();
	// Assigning targets to spawned infected
	HookEvent("player_spawn", OnPlayerSpawnPre, EventHookMode_Pre);
	HookEvent("player_incapacitated", OnPlayerImmobilised, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerImmobilised, EventHookMode_Pre);
}

/***********************************************************************************************************************************************************************************

																		UPDATING VALID SURVIVOR TARGETS

***********************************************************************************************************************************************************************************/

// Re-assign targets to all special infected cappers
RefreshTargets() {
	// Refresh survivor array
	ClearArray(arraySurvivors);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i)) {
			PushArrayCell(arraySurvivors, i);
		}
	}
	 
	// Assign targets
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsBotCapper(i) && IsPlayerAlive(i)) {
			targetSurvivor[i] = GetTargetSurvivor();
		}
	}
}

/* @return: The entity index to a permanent health carrying survivor that is not being pinned.
 *			In the absence of permanent health a random survivor (whom possibly may be pinned) is assigned as the target.
 *	
*/
GetTargetSurvivor() {
	new target = -1;
	new arraySize = GetArraySize(arraySurvivors);
	if (arraySize > 0) {
		new lastIndex = arraySize - 1;
		// Check if there are survivors holding permanent health
		new bool:bDoesPermHealthRemain = false;
		for (new i = 0; i < arraySize; i++) {
			new survivor = GetArrayCell(arraySurvivors, i);
			if (GetEntProp(survivor, Prop_Send, "m_currentReviveCount") < 1  && IsMobile(survivor)) {
				bDoesPermHealthRemain = true;
			}
		}
		
		// Pick a random target, only choose mobile perm health survivor 
		if( bDoesPermHealthRemain ) {
			new randomIndex;
			new randomSurvivor;
			do {
				randomIndex = GetRandomInt(0, lastIndex);		
				randomSurvivor = GetArrayCell(arraySurvivors, randomIndex);		 
			} while (GetEntProp(randomSurvivor, Prop_Send, "m_currentReviveCount") > 0);
			target = randomSurvivor;
		}		
	}	
	
	return target;
}

/***********************************************************************************************************************************************************************************

																	EXECUTING AI TARGET PREFERENCING

***********************************************************************************************************************************************************************************/

// Assign target to any cappers(smoker, hunter, jockey charger) that spawn
public Action:OnPlayerSpawnPre(Handle:event, String:name[], bool:dontBroadcast) {
	new playerID = GetEventInt(event, "userid");
	new player = GetClientOfUserId(playerID);
	if (IsBotCapper(player)) {
		// Assign a survivor for the infected to target
		targetSurvivor[player] = GetTargetSurvivor();
		#if DEBUG
			decl String:infectedName[32];
			decl String:targetName[32];
			GetClientName(player, infectedName, sizeof(infectedName));
			GetClientName(targetSurvivor[player], targetName, sizeof(targetName));
			LogMessage("%s spawned and was assigned target: %s", infectedName, targetName);
		#endif
	} 
}

// Influence AI targeting - AI will still prefer close range survivors if assigned targets are significantly farther
// N.B. requires disabling of SMAC_Commands to prevent kicks for command spamming
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
	if (IsBotCapper(client)) {
	   new token = GetRandomInt(0, 100);
	   if( token < 50 ) {
	       AttackTarget(client);
	   }		
	}	
}

AttackTarget(client) {
	new botID = GetClientUserId(client);
	// Prefer health bonus survivors
	new target = targetSurvivor[client];
	if (IsValidClient(target) && IsSurvivor(target)) {
		// if not already pinned
		if (IsMobile(target)) {
			new targetID = GetClientUserId(target);		
			// Check bot is still alive, and not a dummy client 
			new String:clientName[MAX_NAME_LENGTH];
			if (IsBotInfected(client) && GetClientName(client, clientName, sizeof(clientName)) ) {
				if (StrContains(clientName, "dummy", false) == -1) { // naming convention used in 'special_infected_wave_spawner.smx'
					ScriptCommand("CommandABot({cmd=%i,bot=GetPlayerFromUserID(%i),target=GetPlayerFromUserID(%i)})", CMD_ATTACK, botID, targetID); // attack
				}
			}				
		}			
	}
}

/***********************************************************************************************************************************************************************************

																				UTILITY

***********************************************************************************************************************************************************************************/

ScriptCommand(const String:arguments[], any:...) {
	new String:vscript[PLATFORM_MAX_PATH];
	VFormat(vscript, sizeof(vscript), arguments, 2);
	CheatCommand("script", vscript);
}

// @return: true if client is a survivor that is not dead/incapacitated nor pinned by an SI
bool:IsMobile(client) {
	new bool:bIsMobile = true;
	if (IsSurvivor(client)) {
		if (IsPinned(client) || IsIncap(client)) {
			bIsMobile = false;
		}
	} 
	return bIsMobile;
}

// @return: true if player is a dead/incapacitated survivor
bool:IsIncap(client) {
	new bool:bIsIncapped = false;
	if ( IsSurvivor(client) ) {
		if (GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0) bIsIncapped = true;
		if (!IsPlayerAlive(client)) bIsIncapped = true;
	}
	return bIsIncapped;
}

bool:IsBotCapper(client) {
	if (IsBotInfected(client)) {
		new zombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
		if ( L4D2_Infected:zombieClass != L4D2Infected_Boomer && L4D2_Infected:zombieClass != L4D2Infected_Spitter && L4D2_Infected:zombieClass != L4D2Infected_Tank ) {
			return true;
		}
	}
	return false;
}
