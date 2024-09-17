/*
*	Left 4 DHooks Direct - Stock Functions
*	Copyright (C) 2024 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#if defined _l4d_silver_included
 #endinput
#endif
#define _l4d_silver_included

#pragma newdecls required

#include <sdktools>
#include <sdkhooks>

#tryinclude <left4dhooks>
#tryinclude <left4dhooks_anim>
#tryinclude <left4dhooks_stocks>
#tryinclude <left4dhooks_lux_library>





// ====================================================================================================
// ENUMS
// ====================================================================================================
enum
{
	L4D_TEAM_UNASSIGNED			= 0,
	L4D_TEAM_SPECTATOR			= 1,
	L4D_TEAM_SURVIVOR			= 2,
	L4D_TEAM_INFECTED			= 3,
	L4D_TEAM_FOUR				= 4
}

enum
{
	L4D_WEAPON_SLOT_PRIMARY		= 0,
	L4D_WEAPON_SLOT_SECONDARY	= 1,
	L4D_WEAPON_SLOT_GRENADE		= 2,
	L4D_WEAPON_SLOT_MEDKIT		= 3,	// L4D2: Also upgrade ammo packs and defibrillator
	L4D_WEAPON_SLOT_PILLS		= 4,	// L4D2: Also Adrenaline
	L4D_WEAPON_SLOT_CARRIED		= 5		// Physics props such as GasCan etc.
}

enum
{
	L4D1_ZOMBIE_CLASS_SMOKER	= 1,
	L4D1_ZOMBIE_CLASS_BOOMER	= 2,
	L4D1_ZOMBIE_CLASS_HUNTER	= 3,
	L4D1_ZOMBIE_CLASS_WITCH		= 4,
	L4D1_ZOMBIE_CLASS_TANK		= 5
}

enum
{
	L4D2_ZOMBIE_CLASS_SMOKER	= 1,
	L4D2_ZOMBIE_CLASS_BOOMER	= 2,
	L4D2_ZOMBIE_CLASS_HUNTER	= 3,
	L4D2_ZOMBIE_CLASS_SPITTER	= 4,
	L4D2_ZOMBIE_CLASS_JOCKEY	= 5,
	L4D2_ZOMBIE_CLASS_CHARGER	= 6,
	L4D2_ZOMBIE_CLASS_WITCH		= 7,
	L4D2_ZOMBIE_CLASS_TANK		= 8
}

enum
{
	SERVER_OS_WINDOWS			= 0,
	SERVER_OS_LINUX				= 1,
}

// Thanks to "Dragokas":
enum // m_eDoorState
{
	DOOR_STATE_CLOSED,
	DOOR_STATE_OPENING_IN_PROGRESS,
	DOOR_STATE_OPENED,
	DOOR_STATE_CLOSING_IN_PROGRESS
}

// Thanks to "Dragokas":
enum // m_spawnflags
{
	DOOR_FLAG_STARTS_OPEN		= 1,
	DOOR_FLAG_STARTS_LOCKED		= 2048,
	DOOR_FLAG_SILENT			= 4096,
	DOOR_FLAG_USE_CLOSES		= 8192,
	DOOR_FLAG_SILENT_NPC		= 16384,
	DOOR_FLAG_IGNORE_USE		= 32768,
	DOOR_FLAG_UNBREAKABLE		= 524288
}





// ====================================================================================================
// STOCKS
// ====================================================================================================

// ==================================================
// ENGINE STOCKS
// ==================================================
static EngineVersion g_iEngine;

/**
 * @brief Returns if the server is running on the Left 4 Dead series engine
 *
 * @return					Returns true if the server is running on the Left 4 Dead series
 */
stock bool L4D_IsEngineLeft4Dead()
{
	if( g_iEngine == Engine_Unknown )
	{
		g_iEngine = GetEngineVersion();
	}

	return (g_iEngine == Engine_Left4Dead || g_iEngine == Engine_Left4Dead2);
}

/**
 * @brief Returns if the server is running on Left 4 Dead 1
 *
 * @return					Returns true if server is running on Left 4 Dead 1
 */
stock bool L4D_IsEngineLeft4Dead1()
{
	if( g_iEngine == Engine_Unknown )
	{
		g_iEngine = GetEngineVersion();
	}

	return g_iEngine == Engine_Left4Dead;
}

/**
 * @brief Returns if the server is running on Left 4 Dead 2
 *
 * @return					Returns true if server is running on Left 4 Dead 2
 */
stock bool L4D_IsEngineLeft4Dead2()
{
	if( g_iEngine == Engine_Unknown )
	{
		g_iEngine = GetEngineVersion();
	}

	return g_iEngine == Engine_Left4Dead2;
}



// ==================================================
// DOOR STOCKS
// ==================================================

/**
 * @brief Returns the specified door state. Uses the "DOOR_STATE_*" enum
 *
 * @param entity			The "prop_door*" entity to check
 *
 * @return the "DOOR_STATE_*" value
 */
stock int L4D_GetDoorState(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_eDoorState");
}

/**
 * @brief Returns the specified door flags. Uses the "DOOR_FLAG_*" enum
 *
 * @param entity			The "prop_door*" entity to check
 *
 * @return the "DOOR_FLAG_*" value
 */
stock int L4D_GetDoorFlag(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_spawnflags");
}



// ==================================================
// ENTITY STOCKS
// ==================================================

/**
 * @brief Returns a players current weapon, or -1 if none.
 *
 * @param client			Client ID of the player to check
 *
 * @return weapon entity index or -1 if none
 */
stock int L4D_GetPlayerCurrentWeapon(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

/**
 * @brief Returns the Custom Ability entity of a Special Infected
 * @remarks Returns the entity of "ability_vomit" (Boomer), "ability_lunge" (Hunter), "ability_tongue" (Smoker), "ability_charge" (Charger), "ability_ride" (Jockey), "ability_spit" (Spitter), "ability_throw" (Tank)
 *
 * @param client			Client ID of the player to check
 *
 * @return entity index or -1 if none
 */
stock int L4D_GetPlayerCustomAbility(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_customAbility");
}

/**
 * @brief Returns the players Use Action Target
 *
 * @param client			Client ID of the player to check
 *
 * @return entity index or -1 if none
 */
stock int L4D_GetPlayerUseTarget(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_useActionTarget");
}

/**
 * @brief Returns the parent of an entity
 *
 * @param client			Entity index to check
 *
 * @return entity index or -1 if none
 */
stock int L4D_EntityParent(int entity)
{
	return GetEntPropEnt(entity, Prop_Data, "m_pParent");
}

/**
 * @brief Checks if a player is using any mounted weapon (minigun or 50cal)
 *
 * @param client			Client to check
 *
 * @return true if using a mounted weapon, false otherwise
 */
stock bool IsUsingMinigun(int client)
{
	return ((GetEntProp(client, Prop_Send, "m_usingMountedWeapon") > 0) || (GetEntProp(client, Prop_Send, L4D_IsEngineLeft4Dead2() ? "m_usingMountedGun" : "m_usingMinigun") > 0));
}

/**
 * @brief Stops a client using a mounted weapon
 *
 * @param client			Entity index to check
 *
 * @return entity index or -1 if none
 */
stock void StopUsingMinigun(int client)
{
	if( IsUsingMinigun(client) )
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hUseEntity");
		if( entity > 0 && entity < 2048 )
		{
			SetEntPropEnt(entity, Prop_Send, "m_owner", -1);
		}

		SetEntProp(client, Prop_Send, L4D_IsEngineLeft4Dead2() ? "m_usingMountedGun" : "m_usingMinigun", 0);
		SetEntProp(client, Prop_Send, "m_usingMountedWeapon", 0);
		SetEntPropEnt(client, Prop_Send, "m_hUseEntity", -1);
	}
}

/**
 * @brief Returns if a player is on fire
 *
 * @param client			Client index to check
 *
 * @return true on fire, false otherwise
 */
stock bool L4D_IsPlayerOnFire(int client)
{
	if( GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONFIRE ) return true;
	else return false;
}

/**
 * @brief Returns if a player is burning
 *
 * @param client			Client index to check
 *
 * @return true on burning, false otherwise
 */
stock bool L4D_IsPlayerBurning(int client)
{
	float fBurning = GetEntPropFloat(client, Prop_Send, "m_burnPercent");
	return (fBurning > 0.0) ? true : false;
}

/**
 * @brief Returns true if a physics object or alarmed car can be moved by the tank
 *
 * @param entity			Entity index to check
 *
 * @return true if it can be moved, false otherwise
 */
stock bool L4D_IsTankProp(int entity)
{
	static char classname[16];

	GetEdictClassname(entity, classname, sizeof(classname));

	if( strcmp(classname, "prop_physics") == 0 )
	{
		if( GetEntProp(entity, Prop_Send, "m_hasTankGlow") )
		{
			return true;
		}
	}
	else if( strcmp(classname, "prop_car_alarm") == 0 )
	{
		return true;
	}

	return false;
}



// ==================================================
// COMMON INFECTED STOCKS
// ==================================================

/**
 * @brief Creates a panic event mob horde
 * @remarks Subject to horde cooldown timer
 * @remarks Can probably reset the timer with either "L4D_ResetMobTimer();" native or using "L4D2CT_MobSpawnTimer" with the timer natives.
 *
 * @noreturn
 */
stock void L4D_ForcePanicEvent()
{
	static EngineVersion engine;

	if( engine == Engine_Unknown )
	{
		engine = GetEngineVersion();
	}

	if( engine == Engine_Left4Dead2 )
	{
		static int director = INVALID_ENT_REFERENCE;

		if( director == INVALID_ENT_REFERENCE || EntRefToEntIndex(director) == INVALID_ENT_REFERENCE )
		{
			director = FindEntityByClassname(-1, "info_director");
			if( director != INVALID_ENT_REFERENCE )
			{
				director = EntIndexToEntRef(director);
			}
		}

		if( director != INVALID_ENT_REFERENCE )
		{
			AcceptEntityInput(director, "ForcePanicEvent");
			return;
		}
	}

	int flags = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flags & ~FCVAR_CHEAT);
	ServerCommand("director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flags);
}

/**
 * @brief Returns the current number of common infected
 *
 * @return entity index or -1 if none
 */
stock int L4D_GetCommonsCount()
{
	int entity = -1;
	int count;
	while( (entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE )
	{
		count++;
	}

	return count;
}

/**
 * @brief Spawns a Common Infected at the given position
 *
 * @param vPos			Origin vector to spawn at
 * @param vAng			Angles vector to spawn at (optional)
 *
 * @return entity index or -1 on failure
 */
stock int L4D_SpawnCommonInfected(float vPos[3], float vAng[3] = { 0.0, 0.0, 0.0 })
{
	int entity = CreateEntityByName("infected");
	if( entity != -1 )
	{
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		DispatchSpawn(entity);
	}

	return entity;
}



// ==================================================
// INFECTED: GET VICTIM
// ==================================================

/**
 * @brief Returns the Survivor victim when pinned by a Hunter
 *
 * @param client			Client ID of the Special Infected player to check
 *
 * @return Victim client index, or 0 if none
 */
stock int L4D_GetVictimHunter(int client)
{
	int attacker;

	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_pounceVictim")) > 0 )
		return attacker;

	return 0;
}

/**
 * @brief Returns the Survivor victim when pinned by a Smoker
 *
 * @param client			Client ID of the Special Infected player to check
 *
 * @return Victim client index, or 0 if none
 */
stock int L4D_GetVictimSmoker(int client)
{
	int attacker;

	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_tongueVictim")) > 0 )
		return attacker;

	return 0;
}

/**
 * @brief Returns the Survivor victim when pinned by a Charger
 *
 * @param client			Client ID of the Special Infected player to check
 *
 * @return Victim client index, or 0 if none
 */
// L4D2 only.
stock int L4D_GetVictimCharger(int client)
{
	int attacker;

	if( L4D_IsEngineLeft4Dead2() )
	{
		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_pummelVictim")) > 0 )
			return attacker;
	}

	return 0;
}

/**
 * @brief Returns the Survivor victim when carried by a Charger
 *
 * @param client			Client ID of the Special Infected player to check
 *
 * @return Victim client index, or 0 if none
 */
// L4D2 only.
stock int L4D_GetVictimCarry(int client)
{
	int attacker;

	if( L4D_IsEngineLeft4Dead2() )
	{
		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_carryVictim")) > 0 )
			return attacker;
	}

	return 0;
}

/**
 * @brief Returns the Survivor victim when pinned by a Jockey
 *
 * @param client			Client ID of the Special Infected player to check
 *
 * @return Victim client index, or 0 if none
 */
// L4D2 only.
stock int L4D_GetVictimJockey(int client)
{
	int attacker;

	if( L4D_IsEngineLeft4Dead2() )
	{
		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim")) > 0 )
			return attacker;
	}

	return 0;
}



// ==================================================
// SURVIVOR: GET ATTACKER
// ==================================================

/**
 * @brief Returns a Survivors attacker when pinned by a Hunter
 *
 * @param client			Client ID of the Survivor player to check
 *
 * @return Attacker client index, or 0 if none
 */
stock int L4D_GetAttackerHunter(int client)
{
	int attacker;

	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker")) > 0 )
		return attacker;

	return 0;
}

/**
 * @brief Returns a Survivors attacker when pinned by a Smoker
 *
 * @param client			Client ID of the Survivor player to check
 *
 * @return Attacker client index, or 0 if none
 */
stock int L4D_GetAttackerSmoker(int client)
{
	int attacker;

	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner")) > 0 )
		return attacker;

	return 0;
}

/**
 * @brief Returns a Survivors attacker when pummelled by a Charger
 *
 * @param client			Client ID of the Survivor player to check
 *
 * @return Attacker client index, or 0 if none
 */
// L4D2 only.
stock int L4D_GetAttackerCharger(int client)
{
	int attacker;

	if( L4D_IsEngineLeft4Dead2() )
	{
		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker")) > 0 )
			return attacker;
	}

	return 0;
}

/**
 * @brief Returns a Survivors attacker when carried by a Charger
 *
 * @param client			Client ID of the Survivor player to check
 *
 * @return Attacker client index, or 0 if none
 */
// L4D2 only.
stock int L4D_GetAttackerCarry(int client)
{
	int attacker;

	if( L4D_IsEngineLeft4Dead2() )
	{
		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker")) > 0 )
			return attacker;
	}

	return 0;
}

/**
 * @brief Returns a Survivors attacker when pinned by a Jockey
 *
 * @param client			Client ID of the Survivor player to check
 *
 * @return Attacker client index, or 0 if none
 */
// L4D2 only.
stock int L4D_GetAttackerJockey(int client)
{
	int attacker;

	if( L4D_IsEngineLeft4Dead2() )
	{
		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker")) > 0 )
			return attacker;
	}

	return 0;
}



// ==================================================
// PINNED CHECKS
// ==================================================

/**
 * @brief Returns the attacker when a Survivor is pinned by a Special Infected
 *
 * @param client			Client ID of the player to check
 *
 * @return Attacker client index, or 0 if none
 */
stock int L4D_GetPinnedInfected(int client)
{
	int attacker;

	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker")) > 0 )
		return attacker;

	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner")) > 0 )
		return attacker;

	if( L4D_IsEngineLeft4Dead2() )
	{
		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker")) > 0 )
			return attacker;

		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker")) > 0 )
			return attacker;

		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker")) > 0 )
			return attacker;
	}

	return 0;
}

/**
 * @brief Returns the victim when a Survivor is pinned by a Special Infected
 *
 * @param client			Client ID of the player to check
 *
 * @return Attacker client index, or 0 if none
 */
stock int L4D_GetPinnedSurvivor(int client)
{
	int class = GetEntProp(client, Prop_Send, "m_zombieClass");
	int victim;

	if( L4D_IsEngineLeft4Dead2() )
	{
		switch( class )
		{
			case 1:		victim = GetEntPropEnt(client, Prop_Send, "m_tongueVictim");
			case 3:		victim = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
			case 5:		victim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
			case 6:
			{
				victim = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
				if( victim < 1 ) victim = GetEntPropEnt(client, Prop_Send, "m_carryVictim");
			}
		}
	}
	else
	{
		switch( class )
		{
			case 1:		victim = GetEntPropEnt(client, Prop_Send, "m_tongueVictim");
			case 3:		victim = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
		}
	}

	if( victim > 0 )
		return victim;

	return 0;
}

/**
 * @brief Returns true when someone is being carried/pummelled by more than 1 Charger
 *
 * @param client			Client ID of the player to check
 *
 * @return Returns true when someone is being carried/pummelled by more than 1 Charger
 */
// L4D2 only.
stock bool L4D2_IsMultiCharged(int victim)
{
	if( !L4D_IsEngineLeft4Dead2() )
		ThrowError("Stock only supports L4D2.");

	int count;

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( !IsClientInGame(i) )
			continue;

		else if( GetClientTeam(i) != 3 )
			continue;

		else if( L4D2_GetPlayerZombieClass(i) != L4D2ZombieClass_Charger )
			continue;

		if( L4D_GetVictimCarry(i) == victim || L4D_GetVictimCharger(i) == victim )
		count++;
	}

	return count >= 2;
}

/**
 * @brief Returns if a Survivor is pinned by a Special Infected
 *
 * @param client			Client ID of the player to check
 *
 * @return Returns true if pinned, false otherwise
 */
stock bool L4D_IsPlayerPinned(int client)
{
	return L4D_GetPinnedInfected(client) != 0;
}

/**
 * @brief Returns if a Survivor is being attacked in the Smokers arms
 *
 * @param client			Client ID of the player to check
 *
 * @return Returns true if player has reached the Smoker, false otherwise
 */
stock bool L4D_HasReachedSmoker(int client)
{
	// m_isHangingFromTongue sometimes returns 1 when still being dragged, using this instead
	return GetEntProp(client, Prop_Send, "m_reachedTongueOwner", 1) == 1;
}



// ==================================================
// CHARGER STOCKS - Written by "Forgetest"
// ==================================================
#define QueuedPummel_Victim		0
#define QueuedPummel_StartTime	4
#define QueuedPummel_Attacker	8

/**
 * @brief Internally used to get offset to the start of queued pummel field.
 *
 * @return					Offset into CTerrorPlayer to the start of queued pummel props
 */
static stock int L4D2_OffsQueuedPummelInfo()
{
	static int m_hQueuedPummelVictim = -1;
	if( m_hQueuedPummelVictim == -1 )
		m_hQueuedPummelVictim = FindSendPropInfo("CTerrorPlayer", "m_pummelAttacker") + 4;

	return m_hQueuedPummelVictim;
}

/**
 * @brief Returns the timestamp when the queued pummel begins.
 *
 * @param client			Client ID of the charger to check
 *
 * @return timestamp or -1.0 if no queued pummel
 */
stock float L4D2_GetQueuedPummelStartTime(int charger)
{
	return GetEntDataFloat(charger, L4D2_OffsQueuedPummelInfo() + QueuedPummel_StartTime);
}

/**
 * @brief Sets the timestamp when the queued pummel begins.
 *
 * @param client			Client ID of the charger to check
 * @param timestamp			Timestamp to set
 *
 * @noreturn
 */
stock void L4D2_SetQueuedPummelStartTime(int charger, float timestamp)
{
	SetEntDataFloat(charger, L4D2_OffsQueuedPummelInfo() + QueuedPummel_StartTime, timestamp);
}

/**
 * @brief Returns if a Charger is in a queued pummel.
 *
 * @param charger			Client ID of the charger to check
 *
 * @return true if in queued pummel, false otherwise
 */
stock bool L4D2_IsInQueuedPummel(int charger)
{
	float flTimestamp = L4D2_GetQueuedPummelStartTime(charger);

	return flTimestamp != -1.0 && flTimestamp > GetGameTime();
}

/**
 * @brief Returns the victim of a Charger in a queued pummel.
 *
 * @param client			Client ID of the player to check
 *
 * @return client index or -1 if none
 */
stock int L4D2_GetQueuedPummelVictim(int client)
{
	return GetEntDataEnt2(client, L4D2_OffsQueuedPummelInfo() + QueuedPummel_Victim);
}

/**
 * @brief Sets the victim of a Charger in a queued pummel.
 *
 * @param client			Client ID of the player to set
 * @param target			Client ID of the target to set
 *
 * @noreturn
 */
stock void L4D2_SetQueuedPummelVictim(int client, int target)
{
	SetEntDataEnt2(client, L4D2_OffsQueuedPummelInfo() + QueuedPummel_Victim, target);
}

/**
 * @brief Returns the attacker of a Survivor in a queued pummel.
 *
 * @param client			Client ID of the player to check
 *
 * @return client index or -1 if none
 */
stock int L4D2_GetQueuedPummelAttacker(int client)
{
	return GetEntDataEnt2(client, L4D2_OffsQueuedPummelInfo() + QueuedPummel_Attacker);
}

/**
 * @brief Sets the attacker of a Survivor in a queued pummel.
 *
 * @param client			Client ID of the player to set
 * @param target			Client ID of the target to set
 *
 * @noreturn
 */
stock void L4D2_SetQueuedPummelAttacker(int client, int target)
{
	SetEntDataEnt2(client, L4D2_OffsQueuedPummelInfo() + QueuedPummel_Attacker, target);
}



// ==================================================
// LEDGE HANG STOCKS
// ==================================================

/**
 * @brief Returns if a Survivor is hanging from a ledge
 *
 * @param client			Client ID of the player to check
 *
 * @return Returns true if hanging, false otherwise
 */
stock bool L4D_IsPlayerHangingFromLedge(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1) == 1;
}

/**
 * @brief Returns if a Survivor can ledge hang
 *
 * @param client			Client ID of the player to check
 *
 * @return Returns true if can hang, false otherwise
 */
stock bool L4D_CanPlayerLedgeHang(int client)
{
	// Get address
	static int addy = -1;
	if( addy == -1 )
	{
		/*
			See the function "CTerrorPlayer::InputDisableLedgeHang"
			On Windows: this[16417] = 0;
			m_bWasPresentAtSurvivalStart offset == 16388
			16388 + 29 = 16417
			Offset unlikely to change unless netprops are added/removed/changed - which is very unlikely
		*/
		addy = FindSendPropInfo("CTerrorPlayer", "m_bWasPresentAtSurvivalStart") + 29;
	}

	return GetEntData(client, addy, 1) == 1;
}

/**
 * @brief Allow a Survivor to ledge hang
 *
 * @param client			Client ID of the player to affect
 *
 * @noreturn
 */
stock void L4D_LedgeHangEnable(int client)
{
	AcceptEntityInput(client, "EnableLedgeHang");
}

/**
 * @brief Disallow a Survivor to ledge hang
 *
 * @param client			Client ID of the player to affect
 *
 * @noreturn
 */
stock void L4D_LedgeHangDisable(int client)
{
	AcceptEntityInput(client, "DisableLedgeHang");
}

/**
 * @brief Checks if a Survivor is currently staggering
 *
 * @param client			Client ID of the player to affect
 *
 * @return Returns true if player is staggering, false otherwise
 */
// Updated more accurate version thanks to "HarryPotter" for providing.
stock bool L4D_IsPlayerStaggering(int client)
{
	static int Activity = -1;

	if( L4D_IsEngineLeft4Dead2() )
	{
		Activity = PlayerAnimState.FromPlayer(client).GetMainActivity();

		switch( Activity )
		{
			case L4D2_ACT_TERROR_SHOVED_FORWARD_MELEE, // 633, 634, 635, 636: stumble
				L4D2_ACT_TERROR_SHOVED_BACKWARD_MELEE,
				L4D2_ACT_TERROR_SHOVED_LEFTWARD_MELEE,
				L4D2_ACT_TERROR_SHOVED_RIGHTWARD_MELEE:
					return true;
		}
	}
	else
	{
		Activity = L4D1_GetMainActivity(client);

		switch( Activity )
		{
			case L4D1_ACT_TERROR_SHOVED_FORWARD, // 1145, 1146, 1147, 1148: stumble
				L4D1_ACT_TERROR_SHOVED_BACKWARD,
				L4D1_ACT_TERROR_SHOVED_LEFTWARD,
				L4D1_ACT_TERROR_SHOVED_RIGHTWARD:
					return true;
		}
	}

	static int m_iQueuedStaggerType = -1;
	if( m_iQueuedStaggerType == -1 )
		m_iQueuedStaggerType = FindSendPropInfo("CTerrorPlayer", "m_staggerDist") + 4;

	if( GetEntData(client, m_iQueuedStaggerType, 4) == -1 )
	{
		if( GetGameTime() >= GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) )
		{
			return false;
		}

		static float vStgDist[3], vOrigin[3];
		GetEntPropVector(client, Prop_Send, "m_staggerStart", vStgDist);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", vOrigin);

		static float fStgDist2;
		fStgDist2 = GetEntPropFloat(client, Prop_Send, "m_staggerDist");

		return GetVectorDistance(vStgDist, vOrigin) <= fStgDist2;
	}

	return true;
}

stock int L4D1_GetMainActivity(int client)
{
	static int s_iOffs_m_eCurrentMainSequenceActivity = -1;
	if( s_iOffs_m_eCurrentMainSequenceActivity == -1 )
		s_iOffs_m_eCurrentMainSequenceActivity = FindSendPropInfo("CTerrorPlayer", "m_iProgressBarDuration") + 476;

	return LoadFromAddress(GetEntityAddress(client) + view_as<Address>(s_iOffs_m_eCurrentMainSequenceActivity), NumberType_Int32);
}

/* OLD VERSION (Before being updated by "HarryPotter")
stock bool L4D_IsPlayerStaggering(int client)
{
	static int m_iQueuedStaggerType = -1;
	if( m_iQueuedStaggerType == -1 )
	m_iQueuedStaggerType = FindSendPropInfo("CTerrorPlayer", "m_staggerDist") + 4;

	if( GetEntData(client, m_iQueuedStaggerType, 4) == -1 )
	{
		if( GetGameTime() >= GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) )
		{
			return false;
		}

		static float vStgDist[3], vOrigin[3];
		GetEntPropVector(client, Prop_Send, "m_staggerStart", vStgDist);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", vOrigin);

		static float fStgDist2;
		fStgDist2 = GetEntPropFloat(client, Prop_Send, "m_staggerDist");

		return GetVectorDistance(vStgDist, vOrigin) <= fStgDist2;
	}

	return true;
}
*/



// ==================================================
// INCAP and REVIVE STOCKS
// ==================================================
/**
 * @brief Set a Survivors incapacitated netprop
 * @remarks When setting to false can make a Survivor have 300 health (the incapped health value)
 *
 * @param client			Client ID of the player to affect
 * @param incap				True to incap, false to remove incap (not the proper way of reviving from incap, probably bypasses revive event)
 *
 * @noreturn
 */
stock void L4D_SetPlayerIncapped(int client, bool incap)
{
	SetEntProp(client, Prop_Send, "m_isIncapacitated", incap ? 1 : 0);
}

/**
 * @brief Incap a Survivor by giving them 100.0 damage
 *
 * @param client			Client ID of the player to affect
 * @param attacker			Optionally set the attacker to credit them for the incap
 *
 * @noreturn
 */
stock void L4D_SetPlayerIncappedDamage(int client, int attacker = 0)
{
	SDKHooks_TakeDamage(client, attacker, attacker, 100.0);
}

/**
 * @brief Returns a Survivors revive target
 *
 * @param client			Client ID of the player to check
 *
 * @return Target client index, or 0 if none
 */
stock int L4D_GetPlayerReviveTarget(int client)
{
	int target = GetEntPropEnt(client, Prop_Send, "m_reviveTarget");
	if( target > 0 )
		return target;

	return 0;
}

/**
 * @brief Returns an incapacitated Survivor's reviver
 *
 * @param client			Client ID of the player to check
 *
 * @return Reviver client index, or 0 if none
 */
stock int L4D_GetPlayerReviveOwner(int client)
{
	int target = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
	if( target > 0 )
		return target;

	return 0;
}

/**
 * @brief Stops a Survivor reviving someone
 * @remarks Prevents accidental freezing of player who tried to revive you
 * @remarks Thanks to "Dragokas" for the stock
 *
 * @param client			Client ID of the player to affect
 *
 * @noreturn
 */
stock void L4D_StopReviveAction(int client)
{
	int owner_save = -1;
	int target_save = -1;
	int owner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner"); // when you reviving somebody, this is -1. When somebody revive you, this is somebody's id
	int target = GetEntPropEnt(client, Prop_Send, "m_reviveTarget"); // when you reviving somebody, this is somebody's id. When somebody revive you, this is -1

	SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	SetEntPropEnt(client, Prop_Send, "m_reviveTarget", -1);

	if( owner != -1 ) // we must reset flag for both - for you, and who you revive
	{
		SetEntPropEnt(owner, Prop_Send, "m_reviveOwner", -1);
		SetEntPropEnt(owner, Prop_Send, "m_reviveTarget", -1);
		owner_save = owner;
	}

	if( target != -1 )
	{
		SetEntPropEnt(target, Prop_Send, "m_reviveOwner", -1);
		SetEntPropEnt(target, Prop_Send, "m_reviveTarget", -1);
		target_save = target;
	}

	if( L4D_IsEngineLeft4Dead2() )
	{
		owner = GetEntPropEnt(client, Prop_Send, "m_useActionOwner");		// used when healing e.t.c.
		target = GetEntPropEnt(client, Prop_Send, "m_useActionTarget");
		SetEntPropEnt(client, Prop_Send, "m_useActionOwner", -1);
		SetEntPropEnt(client, Prop_Send, "m_useActionTarget", -1);

		if( owner != -1 )
		{
			SetEntPropEnt(owner, Prop_Send, "m_useActionOwner", -1);
			SetEntPropEnt(owner, Prop_Send, "m_useActionTarget", -1);
			owner_save = owner;
		}

		if( target > 0 && target <= MaxClients )
		{
			SetEntPropEnt(target, Prop_Send, "m_useActionOwner", -1);
			SetEntPropEnt(target, Prop_Send, "m_useActionTarget", -1);
			target_save = target;
		}

		SetEntProp(client, Prop_Send, "m_iCurrentUseAction", 0);
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);

		if( owner_save != -1 )
		{
			SetEntProp(owner_save, Prop_Send, "m_iCurrentUseAction", 0);
			SetEntPropFloat(owner_save, Prop_Send, "m_flProgressBarDuration", 0.0);
		}

		if( target_save != -1 )
		{
			SetEntProp(target_save, Prop_Send, "m_iCurrentUseAction", 0);
			SetEntPropFloat(target_save, Prop_Send, "m_flProgressBarDuration", 0.0);
		}
	}
	else
	{
		owner = GetEntPropEnt(client, Prop_Send, "m_healOwner");		// used when healing
		target = GetEntPropEnt(client, Prop_Send, "m_healTarget");
		SetEntPropEnt(client, Prop_Send, "m_healOwner", -1);
		SetEntPropEnt(client, Prop_Send, "m_healTarget", -1);

		if( owner != -1 )
		{
			SetEntPropEnt(owner, Prop_Send, "m_healOwner", -1);
			SetEntPropEnt(owner, Prop_Send, "m_healTarget", -1);
			owner_save = owner;
		}

		if( target != -1 )
		{
			SetEntPropEnt(target, Prop_Send, "m_healOwner", -1);
			SetEntPropEnt(target, Prop_Send, "m_healTarget", -1);
			target_save = target;
		}

		SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);

		if( owner_save != -1 )
		{
			SetEntProp(owner_save, Prop_Send, "m_iProgressBarDuration", 0);
		}

		if( target_save != -1 )
		{
			SetEntProp(target_save, Prop_Send, "m_iProgressBarDuration", 0);
		}
	}
}

/**
 * @brief Returns if a Survivor is incapacitated
 *
 * @param client			Client ID of the player to check
 *
 * @return Returns true if incapacitated, false otherwise
 */
#pragma deprecated Use L4D_IsPlayerIncapacitated instead
stock bool L4D_IsPlayerIncapped(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) != 0;
}





// ==================================================
// GET CLIENT STOCKS
// ==================================================

/**
 * @brief Returns a random client in-game
 *
 * @return Client index or 0 if none
 */
stock int GetAnyRandomClient()
{
	int client;
	ArrayList aClients = new ArrayList();

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			aClients.Push(i);
		}
	}

	if( aClients.Length > 0 )
	{
		SetRandomSeed(GetGameTickCount());
		client = aClients.Get(GetRandomInt(0, aClients.Length - 1));
	}

	delete aClients;

	return client;
}

/**
 * @brief Returns a random Survivor
 *
 * @param alive			-1 = Any. 0 = Only dead players. 1 = Only alive players
 * @param bots			-1 = Any. 0 - Only real players. 1 = Only fake players
 *
 * @return Client index or 0 if none
 */
stock int GetRandomSurvivor(int alive = -1, int bots = -1)
{
	return GetRandomClient(2, alive, bots);
}

/**
 * @brief Returns a random Special Infected
 *
 * @param alive			-1 = Any. 0 = Only dead players. 1 = Only alive players
 * @param bots			-1 = Any. 0 - Only real players. 1 = Only fake players
 *
 * @return Client index or 0 if none
 */
stock int GetRandomInfected(int alive = -1, int bots = -1)
{
	return GetRandomClient(3, alive, bots);
}

/**
 * @brief Returns a random client in game
 *
 * @param team			-1 = Any. 1=Spectators, 2=Survivors, 3=Special Infected, 5=Survivors and Special Infected (team > 1)
 * @param alive			-1 = Any. 0 = Only dead players. 1 = Only alive players
 * @param bots			-1 = Any. 0 - Only real players. 1 = Only fake players
 *
 * @return Client index or 0 if none
 */
stock int GetRandomClient(int team = -1, int alive = -1, int bots = -1)
{
	ArrayList aClients = new ArrayList();

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && (team == -1 || (team == 5 && GetClientTeam(i) > 1) || GetClientTeam(i) == team) && (alive == -1 || IsPlayerAlive(i) == view_as<bool>(alive)) && (bots == -1 || IsFakeClient(i) == view_as<bool>(bots)) )
		{
			aClients.Push(i);
		}
	}

	int client;

	if( aClients.Length > 0 )
	{
		SetRandomSeed(GetGameTickCount());
		client = aClients.Get(GetRandomInt(0, aClients.Length - 1));
	}

	delete aClients;

	return client;
}