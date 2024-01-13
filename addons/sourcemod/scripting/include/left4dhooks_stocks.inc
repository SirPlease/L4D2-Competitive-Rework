/**
 * =============================================================================
 * Left 4 Dead Stocks Library (C)2011-2012 Buster "Mr. Zero" Nielsen
 * Syntax Update and merge into "Left 4 DHooks Direct" (C) 2024 "SilverShot"
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License, version 3.0, as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2,"
 * the "Source Engine," the "SourcePawn JIT," and any Game MODs that run on
 * software by the Valve Corporation.  You must obey the GNU General Public
 * License in all respects for all other code used.  Additionally,
 * AlliedModders LLC grants this exception to all derivative works.
 * AlliedModders LLC defines further exceptions, found in LICENSE.txt
 * (as of this writing, version JULY-31-2007), or
 * <http://www.sourcemod.net/license.php>.
 */

#if defined _l4d_stocks_included
 #endinput
#endif
#define _l4d_stocks_included

#pragma newdecls required

#tryinclude <left4dhooks_anim>
#tryinclude <left4dhooks_silver>
#tryinclude <left4dhooks_lux_library>





// ====================================================================================================
// VARIOUS STOCKS: "l4d_stocks.inc" by "Mr. Zero"
// ====================================================================================================

#include <sdktools>

/* Spawn state bit flags */
#define L4D_SPAWNFLAG_CANSPAWN			(0 << 0)
#define L4D_SPAWNFLAG_DISABLED			(1 << 0)
#define L4D_SPAWNFLAG_WAITFORSURVIVORS	(1 << 1)
#define L4D_SPAWNFLAG_WAITFORFINALE		(1 << 2)
#define L4D_SPAWNFLAG_WAITFORTANKTODIE	(1 << 3)
#define L4D_SPAWNFLAG_SURVIVORESCAPED	(1 << 4)
#define L4D_SPAWNFLAG_DIRECTORTIMEOUT	(1 << 5)
#define L4D_SPAWNFLAG_WAITFORNEXTWAVE	(1 << 6)
#define L4D_SPAWNFLAG_CANBESEEN			(1 << 7)
#define L4D_SPAWNFLAG_TOOCLOSE			(1 << 8)
#define L4D_SPAWNFLAG_RESTRICTEDAREA	(1 << 9)
#define L4D_SPAWNFLAG_BLOCKED			(1 << 10)

/* Weapon upgrade bit flags */
#define L4D2_WEPUPGFLAG_NONE			(0 << 0)
#define L4D2_WEPUPGFLAG_INCENDIARY		(1 << 0)
#define L4D2_WEPUPGFLAG_EXPLOSIVE		(1 << 1)
#define L4D2_WEPUPGFLAG_LASER			(1 << 2)

/* Instructor Hint bit flags */
#define L4D2_IHFLAG_NONE				(0 << 0)
#define L4D2_IHFLAG_PULSE_SLOW			(1 << 0)
#define L4D2_IHFLAG_PULSE_FAST			(1 << 1)
#define L4D2_IHFLAG_PULSE_URGENT		(1 << 2)
#define L4D2_IHFLAG_ALPHA_SLOW			(1 << 3)
#define L4D2_IHFLAG_ALPHA_FAST			(1 << 4)
#define L4D2_IHFLAG_ALPHA_URGENT		(1 << 5)
#define L4D2_IHFLAG_SHAKE_NARROW		(1 << 6)
#define L4D2_IHFLAG_SHAKE_WIDE			(1 << 7)
#define L4D2_IHFLAG_STATIC				(1 << 8)

/* Survivor intensity -- Equal or less */
#define L4D_SURVIVORINTENSITY_MILD		0.25
#define L4D_SURVIVORINTENSITY_MODERATE	0.50
#define L4D_SURVIVORINTENSITY_HIGH		0.75
#define L4D_SURVIVORINTENSITY_EXTREME	1.00

enum L4DTeam
{
	L4DTeam_Unassigned				= 0,
	L4DTeam_Spectator				= 1,
	L4DTeam_Survivor				= 2,
	L4DTeam_Infected				= 3
}

enum L4DWeaponSlot
{
	L4DWeaponSlot_Primary			= 0,
	L4DWeaponSlot_Secondary			= 1,
	L4DWeaponSlot_Grenade			= 2,
	L4DWeaponSlot_FirstAid			= 3,
	L4DWeaponSlot_Pills				= 4
}

enum L4D2GlowType
{
	L4D2Glow_None					= 0,
	L4D2Glow_OnUse					= 1,
	L4D2Glow_OnLookAt				= 2,
	L4D2Glow_Constant				= 3
}

enum L4D1ZombieClassType
{
	L4D1ZombieClass_Smoker			= 1,
	L4D1ZombieClass_Boomer			= 2,
	L4D1ZombieClass_Hunter			= 3,
	L4D1ZombieClass_Witch			= 4,
	L4D1ZombieClass_Tank			= 5,
	L4D1ZombieClass_NotInfected		= 6
}

enum L4D2ZombieClassType
{
	L4D2ZombieClass_Smoker			= 1,
	L4D2ZombieClass_Boomer			= 2,
	L4D2ZombieClass_Hunter			= 3,
	L4D2ZombieClass_Spitter			= 4,
	L4D2ZombieClass_Jockey			= 5,
	L4D2ZombieClass_Charger			= 6,
	L4D2ZombieClass_Witch			= 7,
	L4D2ZombieClass_Tank			= 8,
	L4D2ZombieClass_NotInfected		= 9
}

enum L4D2UseAction
{
	L4D2UseAction_None				= 0,	// No use action active
	L4D2UseAction_Healing			= 1,	// Includes healing yourself or a teammate.
	L4D2UseAction_AmmoPack			= 2,	// When deploying the ammo pack that was never added into the game
	L4D2UseAction_Defibing			= 4,	// When defib'ing a dead body.
	L4D2UseAction_GettingDefibed	= 5,	// When comming back to life from a dead body.
	L4D2UseAction_DeployIncendiary	= 6,	// When deploying Incendiary ammo
	L4D2UseAction_DeployExplosive	= 7,	// When deploying Explosive ammo
	L4D2UseAction_PouringGas		= 8,	// Pouring gas into a generator
	L4D2UseAction_Cola				= 9,	// For Dead Center map 2 cola event, when handing over the cola to whitalker.
	L4D2UseAction_Button			= 10,	// Such as buttons, timed buttons, generators, etc.
	L4D2UseAction_UsePointScript	= 11	// When using a "point_script_use_target" entity
	/* List is not fully done, these are just the ones I have found so far */
}

enum L4DResourceType
{
	L4DResource_Ping,
	L4DResource_Score,
	L4DResource_TankTickets,
	L4DResource_Deaths,
	L4DResource_MaxHealth,
	L4DResource_WantsToPlay,
	L4DResource_TankTickets2
}

stock const char L4D1ZombieClassname[6][] =
{
	"smoker",
	"boomer",
	"hunter",
	"witch",
	"tank",
	"error_bad_L4D1ZombieClassType"
};

stock const char L4D2ZombieClassname[9][] =
{
	"smoker",
	"boomer",
	"hunter",
	"spitter",
	"jockey",
	"charger",
	"witch",
	"tank",
	"error_bad_L4D2ZombieClassType"
};

static const char L4DResourceName[L4DResourceType][] =
{
	"m_iPing",
	"m_iScore",
	"m_iTankTickets",
	"m_iDeaths",
	"m_maxHealth",
	"m_wantsToPlay",
	"m_tankTickets"
};

/**
 * Returns the clients team using L4DTeam.
 *
 * @param client		Player's index.
 * @return				Current L4DTeam of player.
 * @error				Invalid client index.
 */
stock L4DTeam L4D_GetClientTeam(int client)
{
	int team = GetClientTeam(client);
	return view_as<L4DTeam>(team);
}

/**
 * Returns zombie player L4D1 zombie class.
 *
 * @param client		Player's index.
 * @return				Current L4D1ZombieClassType of player.
 * @error				Invalid client index.
 */
// L4D1 only.
stock L4D1ZombieClassType L4D1_GetPlayerZombieClass(int client)
{
	return view_as<L4D1ZombieClassType>(GetEntProp(client, Prop_Send, "m_zombieClass"));
}

/**
 * Set zombie player L4D1 zombie class.
 *
 * @param client		Player's index.
 * @param class			L4D1ZombieClassType class symbol.
 * @noreturn
 * @error				Invalid client index.
 */
// L4D1 only.
stock void L4D1_SetPlayerZombieClass(int client, L4D1ZombieClassType class)
{
	SetEntProp(client, Prop_Send, "m_zombieClass", class);
}

/**
 * Returns zombie player L4D2 zombie class.
 *
 * @param client		Player's index.
 * @return				Current L4D2ZombieClassType of player.
 * @error				Invalid client index.
 */
// L4D2 only.
stock any L4D2_GetPlayerZombieClass(int client)
{
	return view_as<L4D2ZombieClassType>(GetEntProp(client, Prop_Send, "m_zombieClass"));
}

/**
 * Set zombie player L4D2 zombie class.
 *
 * @param client		Player's index.
 * @param class			L4D2ZombieClassType class symbol.
 * @noreturn
 * @error				Invalid client index.
 */
// L4D2 only.
stock void L4D2_SetPlayerZombieClass(int client, L4D2ZombieClassType class)
{
	SetEntProp(client, Prop_Send, "m_zombieClass", class);
}

/**
 * Returns ghost state of zombie player.
 *
 * @param client		Player index.
 * @return				True if player is ghost, false otherwise.
 * @error				Invalid client index.
 */
stock bool L4D_IsPlayerGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost", 1));
}

/**
 * Sets ghost state of zombie player.
 *
 * @param client		Player index.
 * @param isGhost		Sets ghost status.
 * @noreturn
 * @error				Invalid client index.
 */
stock void L4D_SetPlayerGhostState(int client, bool isGhost)
{
	SetEntProp(client, Prop_Send, "m_isGhost", isGhost, 1);
}

/**
 * Returns ghost spawn state of zombie player.
 *
 * @param client		Player index.
 * @return				Player's spawn state bits.
 * @error				Invalid client index.
 */
stock int L4D_GetPlayerGhostSpawnState(int client)
{
	return GetEntProp(client, Prop_Send, "m_ghostSpawnState");
}

/**
 * Set zombie player's ghost spawn state bits.
 *
 * Note: The game updates spawn state bits every frame.
 *
 * @param client		Player index.
 * @param bits			Ghost spawn state bits.
 * @noreturn
 * @error				Invalid client index.
 */
stock void L4D_SetPlayerGhostSpawnState(int client, int bits)
{
	SetEntProp(client, Prop_Send, "m_ghostSpawnState", bits);
}

/**
 * Returns whether zombie player is culling.
 *
 * @param client		Player index.
 * @return				True if player is culling, false otherwise.
 */
stock bool L4D_IsPlayerCulling(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isCulling", 1));
}

/**
 * Set culling state of zombie player.
 *
 * @param client		Player index.
 * @param isCulling		Whether player is culling.
 * @noreturn
 * @error				Invalid client index.
 */
stock void L4D_SetPlayerCullingState(int client, bool isCulling)
{
	SetEntProp(client, Prop_Send, "m_isCulling", isCulling, 1);
}

/**
 * Returns whether player is incapacitated.
 *
 * Note: A tank player will return true when in dying animation.
 *
 * @param client		Player index.
 * @return				True if incapacitated, false otherwise.
 * @error				Invalid client index.
 */
stock bool L4D_IsPlayerIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1));
}

/**
 * Set player's incapacitated state.
 *
 * @param client			Player index.
 * @param isIncapacitated	Whether the player is incapacitated.
 * @noreturn
 * @error					Invalid client index.
 */
stock void L4D_SetPlayerIncapacitatedState(int client, bool isIncapacitated)
{
	SetEntProp(client, Prop_Send, "m_isIncapacitated", isIncapacitated, 1);
}

/**
 * Returns survivor player shove penalty.
 *
 * @param client		Player index.
 * @return				Current shove penalty of player.
 */
stock int L4D_GetPlayerShovePenalty(int client)
{
	return GetEntProp(client, Prop_Send, "m_iShovePenalty");
}

/**
 * Set survivor player shove penalty.
 *
 * @param client		Player index.
 * @param shovePenalty	Shove penalty.
 * @noreturn
 * @error				Invalid client index.
 */
stock void L4D_SetPlayerShovePenalty(int client, int shovePenalty)
{
	SetEntProp(client, Prop_Send, "m_iShovePenalty", shovePenalty);
}

/**
 * Returns tank player's frustration.
 *
 * @param client		Player index.
 * @return				How frustrated tank player is.
 * @error				Invalid client index.
 */
stock int L4D_GetTankFrustration(int client)
{
	return GetEntProp(client, Prop_Send, "m_frustration");
}

/**
 * Set tank player's frustration.
 *
 * @param client		Player index.
 * @param frustration	How frustrated tank player is.
 * @noreturn
 * @error				Invalid client index.
 */
stock void L4D_SetTankFrustration(int client, int frustration)
{
	SetEntProp(client, Prop_Send, "m_frustration", frustration);
}

/**
 * Returns whether survivor player is idle.
 *
 * @param				Player index.
 * @return				True if idle, false otherwise.
 */
stock bool L4D_IsPlayerIdle(int client)
{
	return L4D_GetBotOfIdlePlayer(client) > -1;
}

/**
 * Returns survivor bot of idle survivor player.
 *
 * @param client		Player index.
 * @return				Player index of the bot, -1 if not found.
 */
stock int L4D_GetBotOfIdlePlayer(int client)
{
	int idleClient;
	int offset;
	char netclass[64];

	for (int bot = 1; bot <= MaxClients; bot++)
	{
		if (!IsClientInGame(bot) ||
			!IsFakeClient(bot) ||
			view_as<L4DTeam>(GetClientTeam(bot)) != L4DTeam_Survivor ||
			!IsPlayerAlive(bot) ||
			GetClientHealth(bot) < 1)
		{
			continue;
		}

		GetEntityNetClass(bot, netclass, sizeof(netclass));
		offset = FindSendPropInfo(netclass, "m_humanSpectatorUserID");

		if (offset < 1)
		{
			continue;
		}

		idleClient = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));

		if (idleClient == client)
		{
			return bot;
		}
	}

	return -1;
}

/**
 * Returns idle survivor player of survivor bot.
 *
 * @param bot			Player index of bot.
 * @return				Player index of idle client, -1 if not found.
 * @error				Invalid client index.
 */
stock int L4D_GetIdlePlayerOfBot(int bot)
{
	char netclass[64];
	GetEntityNetClass(bot, netclass, sizeof(netclass));
	int offset = FindSendPropInfo(netclass, "m_humanSpectatorUserID");

	if (offset < 1)
	{
		return -1;
	}

	return GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));
}

/**
 * Returns resource entity.
 *
 * @return				Entity index of resource entity, -1 if not found.
 */
stock int L4D_GetResourceEntity()
{
	return FindEntityByClassname(-1, "terror_player_manager");
}

/**
 * Retrieves client data from the resource entity.
 *
 * @param client		Player's index.
 * @param type			ResourceType constant
 * @return				Value or -1 on failure.
 * @error				Invalid client index, client not in game or failed to find resource entity.
 */
stock int L4D_GetPlayerResourceData(int client, L4DResourceType type)
{
	if (!IsClientConnected(client))
	{
		return -1;
	}

	int offset = FindSendPropInfo("CTerrorPlayerResource", L4DResourceName[type]);

	if (offset < 1)
	{
		return -1;
	}

	int entity = L4D_GetResourceEntity();

	if (entity == -1)
	{
		return -1;
	}

	return GetEntData(entity, offset + (client * 4));
}

/**
 * Sets client data in the resource entity.
 *
 * Note: The game overwrites these values every frame, so changing them will have very little effect.
 *
 * @param client		Player's index.
 * @param type			ResourceType constant
 * @param value			Value to set.
 * @return				Value or -1 on failure.
 * @error				Invalid client index, client not in game or failed to find resource entity.
 */
stock bool L4D_SetPlayerResourceData(int client, L4DResourceType type, any value)
{
	if (!IsClientConnected(client))
	{
		return false;
	}

	int offset = FindSendPropInfo("CTerrorPlayerResource", L4DResourceName[type]);

	if (offset < 1)
	{
		return false;
	}

	int entity = L4D_GetResourceEntity();

	if (entity == -1)
	{
		return false;
	}

	SetEntData(entity, offset + (client * 4), value);

	return true;
}

/**
 * Removes the weapon from a client's weapon slot
 *
 * @param client		Player's index.
 * @param slot			Slot index.
 * @noreturn
 * @error				Invalid client or lack of mod support.
 */
stock void L4D_RemoveWeaponSlot(int client, L4DWeaponSlot slot)
{
	int weaponIndex;
	while ((weaponIndex = GetPlayerWeaponSlot(client, view_as<int>(slot))) != -1)
	{
		RemovePlayerItem(client, weaponIndex);
		RemoveEdict(weaponIndex);
	}
}

/**
 * Removes all weapons from a client
 *
 * @param client		Player's index.
 * @noreturn
 * @error				Invalid client or lack of mod support.
 */
stock void L4D_RemoveAllWeapons(int client)
{
	for (int i = 0; i <= 4; i++)
	{
		L4D_RemoveWeaponSlot(client, view_as<L4DWeaponSlot>(i));
	}
}

/**
 * Returns whether the finale is active.
 *
 * Note: Finales can also be on other maps than just the finale map. A perfect
 * example of this is the Swamp Fever map 1 crescendo event. This event is
 * defined as a finale by Valve for some reason.
 *
 * @return				True if finale is active, false otherwise.
 */
stock bool L4D_IsFinaleActive()
{
	int entity = L4D_GetResourceEntity();

	if (entity == -1)
	{
		return false;
	}

	return view_as<bool>(GetEntProp(entity, Prop_Send, "m_isFinale", 1));
}

/**
 * Returns whether any survivor have left the safe area.
 *
 * @return				True if any survivor have left safe area, false otherwise.
 */
stock bool L4D_HasAnySurvivorLeftSafeAreaStock()
{
	int entity = L4D_GetResourceEntity();

	if (entity == -1)
	{
		return false;
	}

	return view_as<bool>(GetEntProp(entity, Prop_Send, "m_hasAnySurvivorLeftSafeArea", 1));
}

/**
 * Returns pending tank player.
 *
 * @return				Player index of pending tank player, -1 if not found.
 */
stock int L4D_GetPendingTankPlayer()
{
	int entity = L4D_GetResourceEntity();

	if (entity == -1)
	{
		return -1;
	}

	return GetEntProp(entity, Prop_Send, "m_pendingTankPlayerIndex");
}

/**
 * Set entity glow. This is consider safer and more robust over setting each glow property on their own because glow offset will be check first.
 *
 * @param entity		Entity index.
 * @parma type			Glow type.
 * @param range			Glow max range, 0 for unlimited.
 * @param minRange		Glow min range.
 * @param colorOverride	Glow color, RGB.
 * @param flashing		Whether the glow will be flashing.
 * @return				True if glow was set, false if entity does not support glow.
 */
// L4D2 only.
stock bool L4D2_SetEntityGlow(int entity, L4D2GlowType type, int range, int minRange, int colorOverride[3], bool flashing)
{
	if (!IsValidEntity(entity))
	{
		return false;
	}

	char netclass[64];
	GetEntityNetClass(entity, netclass, sizeof(netclass));

	int offset = FindSendPropInfo(netclass, "m_iGlowType");

	if (offset < 1)
	{
		return false;
	}

	L4D2_SetEntityGlow_Type(entity, type);
	L4D2_SetEntityGlow_Range(entity, range);
	L4D2_SetEntityGlow_MinRange(entity, minRange);
	L4D2_SetEntityGlow_Color(entity, colorOverride);
	L4D2_SetEntityGlow_Flashing(entity, flashing);
	return true;
}

/**
 * Set entity glow type.
 *
 * @param entity		Entity index.
 * @parma type			Glow type.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_SetEntityGlow_Type(int entity, L4D2GlowType type)
{
	SetEntProp(entity, Prop_Send, "m_iGlowType", type);
}

/**
 * Set entity glow range.
 *
 * @param entity		Entity index.
 * @parma range			Glow range.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_SetEntityGlow_Range(int entity, int range)
{
	SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
}

/**
 * Set entity glow min range.
 *
 * @param entity		Entity index.
 * @parma minRange		Glow min range.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_SetEntityGlow_MinRange(int entity, int minRange)
{
	SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", minRange);
}

/**
 * Set entity glow color.
 *
 * @param entity		Entity index.
 * @parma colorOverride	Glow color, RGB.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_SetEntityGlow_Color(int entity, int colorOverride[3])
{
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", colorOverride[0] + (colorOverride[1] * 256) + (colorOverride[2] * 65536));
}

/**
 * Set entity glow flashing state.
 *
 * @param entity		Entity index.
 * @parma flashing		Whether glow will be flashing.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_SetEntityGlow_Flashing(int entity, bool flashing)
{
	SetEntProp(entity, Prop_Send, "m_bFlashing", flashing);
}

/**
 * Returns entity glow type.
 *
 * @param entity		Entity index.
 * @return				L4D2 glow type.
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock L4D2GlowType L4D2_GetEntityGlow_Type(int entity)
{
	return view_as<L4D2GlowType>(GetEntProp(entity, Prop_Send, "m_iGlowType"));
}

/**
 * Returns entity glow range.
 *
 * @param entity		Entity index.
 * @return				Glow range.
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock int L4D2_GetEntityGlow_Range(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_nGlowRange");
}

/**
 * Returns entity glow min range.
 *
 * @param entity		Entity index.
 * @return				Glow min range.
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock int L4D2_GetEntityGlow_MinRange(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_nGlowRangeMin");
}

/**
 * Returns entity glow flashing state.
 *
 * @param entity		Entity index.
 * @return				Glow flashing state.
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock bool L4D2_GetEntityGlow_Flashing(int entity)
{
	return view_as<bool>(GetEntProp(entity, Prop_Send, "m_bFlashing"));
}

/**
 * Removes entity glow.
 *
 * @param entity		Entity index.
 * @return				True if glow was removed, false if entity does not
 *						support glow.
 */
// L4D2 only.
stock bool L4D2_RemoveEntityGlow(int entity)
{
	return view_as<bool>(L4D2_SetEntityGlow(entity, L4D2Glow_None, 0, 0, { 0, 0, 0 }, false));
}

/**
 * Removes entity glow override color.
 *
 * Note: This only removes the override color and reset it to the default glow
 * color.
 *
 * @param entity		Entity index.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_RemoveEntityGlow_Color(int entity)
{
	L4D2_SetEntityGlow_Color(entity, { 0, 0, 0 });
}

/**
 * Whether survivor glow for player is enabled.
 *
 * @param client		Client index.
 * @return				True if survivor glow is enabled, false otherwise.
 * @error				Invalid client index.
 */
// L4D2 only.
stock bool L4D2_IsPlayerSurvivorGlowEnable(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_bSurvivorGlowEnabled"));
}

/**
 * Set survivor glow state for player.
 *
 * @param client		Client index.
 * @param enabled		Whether survivor glow is enabled.
 * @noreturn
 * @error				Invalid client index.
 */
// L4D2 only.
stock void L4D2_SetPlayerSurvivorGlowState(int client, bool enabled)
{
	SetEntProp(client, Prop_Send, "m_bSurvivorGlowEnabled", enabled);
}

/**
 * Return player current revive count.
 *
 * @param client		Client index.
 * @return				Survivor's current revive count.
 * @error				Invalid client index.
 */
stock int L4D_GetPlayerReviveCount(int client)
{
	return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}

/**
 * Set player revive count.
 *
 * @param client		Client index.
 * @param count			Revive count.
 * @noreturn
 * @error				Invalid client index.
 */
stock void L4D_SetPlayerReviveCount(int client, int count)
{
	SetEntProp(client, Prop_Send, "m_currentReviveCount", count);
}

/**
 * Return player intensity.
 *
 * Note: Its percentage. 0.0 - Player is calm, 1.0 - Player is stressed.
 *
 * @param client		Client index.
 * @return				Intensity.
 * @error				Invalid client index.
 */
stock float L4D_GetPlayerIntensity(int client)
{
	/* This format is used to keep consistency with the Director which also
	 * uses 0.0 for calm and 1.0 for stressed */
	return float(GetEntProp(client, Prop_Send, "m_clientIntensity")) / 100.0;
}

/**
 * Returns average survivor intensity.
 *
 * Note: Its percentage. 0.0 - All survivors is calm, 1.0 - All survivors is stressed.
 *
 * @return				Average intensity level for survivors.
 */
stock float L4D_GetAvgSurvivorIntensity()
{
	int intensityTotal = 0;
	int intensityMaxTotal = 0;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) ||
			view_as<L4DTeam>(GetClientTeam(client)) != L4DTeam_Survivor ||
			!IsPlayerAlive(client) ||
			GetClientHealth(client) < 1)
		{
			continue;
		}

		intensityMaxTotal += 100;
		intensityTotal += GetEntProp(client, Prop_Send, "m_clientIntensity");
	}

	/* This format is used to keep consistency with the Director which also uses 0.0 for calm and 1.0 for stressed */
	return float(intensityTotal) / float(intensityMaxTotal);
}

/**
 * Set player intensity.
 *
 * Note: Its percentage. 0.0 - Player is calm, 1.0 - Player is stressed.
 *
 * @param client		Client index.
 * @param intensity		Intensity.
 * @noreturn
 * @error				Invalid client index.
 */
stock void L4D_SetPlayerIntensity(int client, float intensity)
{
	SetEntProp(client, Prop_Send, "m_clientIntensity", RoundToNearest(intensity * 100.0));
}

/**
 * Returns whether player is calm.
 *
 * Note: Player is calm means that the player have not taken damage or
 * fired their weapon for a while. Survivor bots always return false.
 *
 * @param client		Client index.
 * @return				True if player is calm, false otherwise.
 * @error				Invalid client index.
 */
stock bool L4D_IsPlayerCalm(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isCalm"));
}

/**
 * Set player is calm state.
 *
 * Note: Player is calm means that the player have not taken damage or fired their weapon for a while.
 *
 * @param client		Client index.
 * @param isCalm		Whether player is calm.
 * @noreturn
 * @error				Invalid client index.
 */
stock void L4D_SetPlayerCalmState(int client, bool isCalm)
{
	SetEntProp(client, Prop_Send, "m_isCalm", isCalm);
}

/**
 * Returns whether player has visible threats.
 *
 * Note: This function should work for all players. Survivors looking upon
 * specials, witch or tank will be marked as has visible threats. However
 * looking at commons will not be seen as has visible threats. The common has
 * to be awaken from its slumber before beings seen as a threat.
 *
 * @parma client		Client index.
 * @return				True if player has visible threats, false otherwise.
 * @error				Invalid client index.
 */
stock bool L4D_HasVisibleThreats(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_hasVisibleThreats"));
}

/**
 * Returns whether player is on third strike.
 *
 * @param client		Client index.
 * @return				True if on third strike, false otherwise.
 * @error				Invalid client index.
 */
stock bool L4D_IsPlayerOnThirdStrike(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike"));
}

/**
 * Set player third strike state.
 *
 * @param client		Client index.
 * @param onThirdStrike Whether survivor is on third strike.
 * @noreturn
 * @error				Invalid client index.
 */
stock void L4D_SetPlayerThirdStrikeState(int client, bool onThirdStrike)
{
	SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", onThirdStrike);
}

/**
 * Returns whether player is going to die.
 *
 * Note: This is not the same as is player on third strike. While on third
 * strike defines whether player should die next time they get incapacitated,
 * this defines whether the survivor should limp when they hit 1hp and make
 * the character vocalize their "I dont think I'm gonna make it" lines.
 *
 * @param client		Client index.
 * @return				True if player is going to die, false otherwise.
 * @error				Invalid client index.
 */
stock bool L4D_IsPlayerGoingToDie(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGoingToDie"));
}

/**
 * Set player is going to die state.
 *
 * @param client		Client index.
 * @param isGoingToDie	Whether player is going to die.
 * @noreturn
 * @error				Invalid client index.
 */
stock void L4D_SetPlayerIsGoingToDie(int client, bool isGoingToDie)
{
	SetEntProp(client, Prop_Send, "m_isGoingToDie", isGoingToDie);
}

/**
 * Returns whether weapon is upgrade compatible.
 *
 * @param weapon		Weapon entity index.
 * @return				True if compatible with upgrades, false otherwise.
 * @error				Invalid entity index.
 */
stock bool L4D2_IsWeaponUpgradeCompatible(int weapon)
{
	if( HasEntProp(weapon, Prop_Send, "m_upgradeBitVec") )
		return true;

	return false;
}

/**
 * Returns upgraded ammo count for weapon.
 *
 * @param weapon		Weapon entity index.
 * @return				Upgraded ammo count.
 * @error				Invalid entity index.
 */
// L4D2 only.
stock int L4D2_GetWeaponUpgradeAmmoCount(int weapon)
{
	if( HasEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded") )
		return GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");

	return 0;
}

/**
 * Set upgraded ammo count in weapon.
 *
 * @param weapon		Weapon entity index.
 * @param count			Upgraded ammo count.
 * @noreturn
 * @error				Invalid entity index.
 */
// L4D2 only.
stock void L4D2_SetWeaponUpgradeAmmoCount(int weapon, int count)
{
	if( HasEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded") )
		SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", count);
}

/**
 * Returns weapon upgrades of weapon.
 *
 * @param weapon		Weapon entity index.
 * @return				Weapon upgrade bits.
 * @error				Invalid entity index.
 */
// L4D2 only.
stock int L4D2_GetWeaponUpgrades(int weapon)
{
	if( HasEntProp(weapon, Prop_Send, "m_upgradeBitVec") )
		return GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");

	return 0;
}

/**
 * Set weapon upgrades for weapon.
 *
 * @param weapon		Weapon entity index.
 * @param upgrades		Weapon upgrade bits.
 * @noreturn
 * @error				Invalid entity index.
 */
// L4D2 only.
stock void L4D2_SetWeaponUpgrades(int weapon, int upgrades)
{
	if( HasEntProp(weapon, Prop_Send, "m_upgradeBitVec") )
	{
		SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", upgrades);
	}
}

/**
 * Returns infected attacker of survivor victim.
 *
 * Note: Infected attacker means the infected player that is currently
 * pinning down the survivor. Such as hunter, smoker, charger and jockey.
 *
 * @param client		Survivor client index.
 * @return				Infected attacker index, -1 if not found.
 * @error				Invalid client index.
 */
// L4D2 only.
stock int L4D2_GetInfectedAttacker(int client)
{
	int attacker;

	/* Charger */
	attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	if (attacker > 0)
	{
		return attacker;
	}

	attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
	if (attacker > 0)
	{
		return attacker;
	}

	/* Hunter */
	attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	if (attacker > 0)
	{
		return attacker;
	}

	/* Smoker */
	attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (attacker > 0)
	{
		return attacker;
	}

	/* Jockey */
	attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if (attacker > 0)
	{
		return attacker;
	}

	return -1;
}

/**
 * Returns survivor victim of infected attacker.
 *
 * Note: Survivor victim means the survivor player that is currently pinned
 * down by an attacker. Such as hunter, smoker, charger and jockey.
 *
 * @param client		Infected client index.
 * @return				Survivor victim index, -1 if not found.
 * @error				Invalid client index.
 */
// L4D2 only.
stock int L4D2_GetSurvivorVictim(int client)
{
	int victim;

	/* Charger */
	victim = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
	if (victim > 0)
	{
		return victim;
	}

	victim = GetEntPropEnt(client, Prop_Send, "m_carryVictim");
	if (victim > 0)
	{
		return victim;
	}

	/* Hunter */
	victim = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
	if (victim > 0)
	{
		return victim;
	}

	/* Smoker */
	victim = GetEntPropEnt(client, Prop_Send, "m_tongueVictim");
	if (victim > 0)
	{
		return victim;
	}

	/* Jockey */
	victim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
	if (victim > 0)
	{
		return victim;
	}

	return -1;
}

/**
 * Returns whether survivor client was present at survival start.
 *
 * @param client		Client index.
 * @return				True if survivor was present at survival start, false otherwise.
 * @error				Invalid client index.
 */
// L4D2 only.
stock bool L4D2_WasPresentAtSurvivalStart(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_bWasPresentAtSurvivalStart"));
}

/**
 * Sets whether player was present at survival start.
 *
 * @param client		Client index.
 * @param wasPresent	Whether survivor was present at survival start.
 * @noreturn
 * @error				Invalid client index.
 */
// L4D2 only.
stock void L4D2_SetPresentAtSurvivalStart(int client, bool wasPresent)
{
	SetEntProp(client, Prop_Send, "m_bWasPresentAtSurvivalStart", wasPresent);
}

/**
 * Returns whether player is using a mounted weapon.
 *
 * @param client		Client index.
 * @return				True if using a mounted weapon, false otherwise.
 * @error				Invalid client index.
 */
stock bool L4D_IsPlayerUsingMountedWeapon(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_usingMountedWeapon"));
}

/**
 * Returns player temporarily health.
 *
 * Note: This will not work with mutations or campaigns that alters the decay
 * rate through vscript'ing. If you want to be sure that it works no matter
 * the mutation, you will have to detour the OnGetScriptValueFloat function.
 * Doing so you are able to capture the altered decay rate and calculate the
 * temp health the same way as this function does.
 *
 * @param client		Client index.
 * @return				Player's temporarily health, -1 if unable to get.
 * @error				Invalid client index or unable to find pain_pills_decay_rate cvar.
 */
stock int L4D_GetPlayerTempHealth(int client)
{
	static ConVar painPillsDecayCvar;
	if (painPillsDecayCvar == null)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == null)
		{
			return -1;
		}
	}

	int tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * painPillsDecayCvar.FloatValue)) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}

/**
 * Set players temporarily health.
 *
 * @param client		Client index.
 * @param tempHealth	Temporarily health.
 * @noreturn
 * @error				Invalid client index.
 */
stock void L4D_SetPlayerTempHealth(int client, int tempHealth)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(tempHealth));
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

/**
 * Set players temporarily health. Allows for setting above 200 HP.
 *
 * @param client		Client index.
 * @param tempHealth	Temporarily health.
 * @noreturn
 * @error				Invalid client index.
 */
stock void L4D_SetPlayerTempHealthFloat(int client, float tempHealth)
{
	static ConVar painPillsDecayCvar;
	if (painPillsDecayCvar == null)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == null)
		{
			return;
		}
	}

	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", tempHealth);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime() + ((tempHealth - 200) / painPillsDecayCvar.FloatValue + 1 / painPillsDecayCvar.FloatValue));
}

/**
 * Returns player use action.
 *
 * @param client		Client index.
 * @return				Use action.
 * @error				Invalid client index.
 */
// L4D2 only.
stock L4D2UseAction L4D2_GetPlayerUseAction(int client)
{
	return view_as<L4D2UseAction>(GetEntProp(client, Prop_Send, "m_iCurrentUseAction"));
}

/**
 * Returns player use action target.
 *
 * @param client		Client index.
 * @return				Entity index.
 * @error				Invalid client index.
 */
// L4D2 only.
stock int L4D2_GetPlayerUseActionTarget(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_useActionTarget");
}

/**
 * Returns player use action owner.
 *
 * @param client		Client index.
 * @return				Entity index.
 * @error				Invalid client index.
 */
// L4D2 only.
stock int L4D2_GetPlayerUseActionOwner(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_useActionOwner");
}

/**
 * Creates an instructor hint.
 *
 * Note: Both infected and survivor players will see hint. No more than one at
 * a time can be shown. The "newest" hint will override the old no matter the
 * timeout and range. This instructor hint will not be shown if the given
 * player is dead.
 *
 * @param name			Instructor hint name.
 * @param target		Entity index of target.
 * @param caption		Caption of hint.
 * @param color			Color of the caption. RGB format.
 * @param iconOnScreen	Icon when hint is on screen.
 * @param iconOffScreen	Icon when hint is off screen.
 * @param binding		Key binding to show.
 * @param iconOffset	Height offset for icon from target entity's origin.
 * @param range			Display range of hint. 0 for unlimited range.
 * @param timeout		Timeout out for hint. 0 will persist until stopped with L4D2_EndInstructorHint.
 * @param allowNoDrawTarget	Whether hint will work with targets that have nodraw set.
 * @param noOffScreen	Whether when hint is off screen it will show an arrow pointing to target.
 * @param forceCaption	Whether the hint and icon will show even when occluded a wall.
 * @param flags			Instructor hint bit flags. See L4D2_IHFLAG_* defines.
 * @return				True if send, false otherwise.
 */
// L4D2 only.
stock bool L4D2_CreateInstructorHint(const char[] name,
									int target = 0,
									const char[] caption,
									int color[3] = {255, 255, 255},
									const char[] iconOnScreen = "icon_tip",
									const char[] iconOffScreen = "icon_tip",
									const char[] binding = "",
									float iconOffset = 0.0,
									float range = 0.0,
									int timeout = 0,
									bool allowNoDrawTarget = true,
									bool noOffScreen = false,
									bool forceCaption = false,
									int flags = L4D2_IHFLAG_STATIC)
{
	Event event = CreateEvent("instructor_server_hint_create", true);
	if (event == null)
	{
		return false;
	}

	char finalizedColor[16];
	Format(finalizedColor, 16, "%d,%d,%d", color[0], color[1], color[2]);

	event.SetString("hint_name", name);
	event.SetInt("hint_target", target);
	event.SetString("hint_caption", caption);
	event.SetString("hint_color", finalizedColor);
	event.SetString("hint_icon_onscreen", iconOnScreen);
	event.SetString("hint_icon_offscreen", iconOffScreen);
	event.SetString("hint_binding", binding);
	event.SetFloat("hint_icon_offset", iconOffset);
	event.SetFloat("hint_range", range);
	event.SetInt("hint_timeout", timeout);
	event.SetBool("hint_allow_nodraw_target", allowNoDrawTarget);
	event.SetBool("hint_nooffscreen", noOffScreen);
	event.SetBool("hint_forcecaption", forceCaption);
	event.SetInt("hint_flags", flags);
	event.Fire();
	return true;
}

/**
 * Stops all instructor hints with name.
 *
 * @param name			Name of instructor hint to stop.
 * @return				True if send, false otherwise.
 */
// L4D2 only.
stock bool L4D2_StopInstructorHint(const char[] name)
{
	Event event = CreateEvent("instructor_server_hint_stop", true);
	if (event == null)
	{
		return false;
	}

	event.SetString("hint_name", name);
	event.Fire();
	return true;
}

/**
 * Returns whether shotgun needs to be pumped.
 *
 * @parma weapon		Weapon entity index.
 * @return				True if shotgun needs to be pumped, false otherwise.
 */
// L4D1 only.
stock int L4D1_GetShotgunNeedPump(int weapon)
{
	return HasEntProp(weapon, Prop_Send, "m_needPump") && GetEntProp(weapon, Prop_Send, "m_needPump");
}

/**
 * Sets whether shotgun needs to be pumped.
 *
 * @parma weapon		Weapon entity index.
 * @parma needPump		Whether shotgun needs to be pumped.
 * @noreturn
 */
// L4D1 only.
stock void L4D1_SetShotgunNeedPump(int weapon, bool needPump)
{
	if( HasEntProp(weapon, Prop_Send, "m_needPump") )
	{
		SetEntProp(weapon, Prop_Send, "m_needPump", view_as<int>(needPump));
	}
}

/**
 * Sets custom ability cooldown of client.
 *
 * Note: Used for the Infected class abilities.
 *
 * @param client		Client index.
 * @param time			How long before client can use their custom ability.
 * @return				True if set, false if no ability found.
 */
// L4D2 only.
stock bool L4D2_SetCustomAbilityCooldown(int client, float time)
{
	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (ability > 0 && IsValidEdict(ability))
	{
		SetEntPropFloat(ability, Prop_Send, "m_duration", time);
		SetEntPropFloat(ability, Prop_Send, "m_timestamp", GetGameTime() + time);
		return true;
	}
	return false;
}





// ====================================================================================================
// WEAPON STOCKS: "l4d_weapon_stocks.inc" by "Mr. Zero"
// ====================================================================================================

/* Credits to ProdigySim for the weapon details, models and original script */

#if defined _l4d_weapon_stocks_included
 #endinput
#endif
#define _l4d_weapon_stocks_included

#include <adt_trie>
#include <sourcemod>
#include <sdktools>

enum L4D2WeaponId
{
	L4D2WeaponId_None,				// 0
	L4D2WeaponId_Pistol,			// 1
	L4D2WeaponId_Smg,				// 2
	L4D2WeaponId_Pumpshotgun,		// 3
	L4D2WeaponId_Autoshotgun,		// 4
	L4D2WeaponId_Rifle,				// 5
	L4D2WeaponId_HuntingRifle,		// 6
	L4D2WeaponId_SmgSilenced,		// 7
	L4D2WeaponId_ShotgunChrome,		// 8
	L4D2WeaponId_RifleDesert,		// 9
	L4D2WeaponId_SniperMilitary,	// 10
	L4D2WeaponId_ShotgunSpas,		// 11
	L4D2WeaponId_FirstAidKit,		// 12
	L4D2WeaponId_Molotov,			// 13
	L4D2WeaponId_PipeBomb,			// 14
	L4D2WeaponId_PainPills,			// 15
	L4D2WeaponId_Gascan,			// 16
	L4D2WeaponId_PropaneTank,		// 17
	L4D2WeaponId_OxygenTank,		// 18
	L4D2WeaponId_Melee,				// 19
	L4D2WeaponId_Chainsaw,			// 20
	L4D2WeaponId_GrenadeLauncher,	// 21
	L4D2WeaponId_AmmoPack,			// 22
	L4D2WeaponId_Adrenaline,		// 23
	L4D2WeaponId_Defibrillator,		// 24
	L4D2WeaponId_Vomitjar,			// 25
	L4D2WeaponId_RifleAK47,			// 26
	L4D2WeaponId_GnomeChompski,		// 27
	L4D2WeaponId_ColaBottles,		// 28
	L4D2WeaponId_FireworksBox,		// 29
	L4D2WeaponId_IncendiaryAmmo,	// 30
	L4D2WeaponId_FragAmmo,			// 31
	L4D2WeaponId_PistolMagnum,		// 32
	L4D2WeaponId_SmgMP5,			// 33
	L4D2WeaponId_RifleSG552,		// 34
	L4D2WeaponId_SniperAWP,			// 35
	L4D2WeaponId_SniperScout,		// 36
	L4D2WeaponId_RifleM60,			// 37
	L4D2WeaponId_TankClaw,			// 38
	L4D2WeaponId_HunterClaw,		// 39
	L4D2WeaponId_ChargerClaw,		// 40
	L4D2WeaponId_BoomerClaw,		// 41
	L4D2WeaponId_SmokerClaw,		// 42
	L4D2WeaponId_SpitterClaw,		// 43
	L4D2WeaponId_JockeyClaw,		// 44
	L4D2WeaponId_Machinegun,		// 45
	L4D2WeaponId_FatalVomit,		// 46
	L4D2WeaponId_ExplodingSplat,	// 47
	L4D2WeaponId_LungePounce,		// 48
	L4D2WeaponId_Lounge,			// 49
	L4D2WeaponId_FullPull,			// 50
	L4D2WeaponId_Choke,				// 51
	L4D2WeaponId_ThrowingRock,		// 52
	L4D2WeaponId_TurboPhysics,		// 53
	L4D2WeaponId_Ammo,				// 54
	L4D2WeaponId_UpgradeItem,		// 55
	L4D2WeaponId_MAX
};

static const char L4D2WeaponName[L4D2WeaponId][] =
{
	"weapon_none",					// 0
	"weapon_pistol",				// 1
	"weapon_smg",					// 2
	"weapon_pumpshotgun",			// 3
	"weapon_autoshotgun",			// 4
	"weapon_rifle",					// 5
	"weapon_hunting_rifle",			// 6
	"weapon_smg_silenced",			// 7
	"weapon_shotgun_chrome",		// 8
	"weapon_rifle_desert",			// 9
	"weapon_sniper_military",		// 10
	"weapon_shotgun_spas",			// 11
	"weapon_first_aid_kit",			// 12
	"weapon_molotov",				// 13
	"weapon_pipe_bomb",				// 14
	"weapon_pain_pills",			// 15
	"weapon_gascan",				// 16
	"weapon_propanetank",			// 17
	"weapon_oxygentank",			// 18
	"weapon_melee",					// 19
	"weapon_chainsaw",				// 20
	"weapon_grenade_launcher",		// 21
	"weapon_ammo_pack",				// 22
	"weapon_adrenaline",			// 23
	"weapon_defibrillator",			// 24
	"weapon_vomitjar",				// 25
	"weapon_rifle_ak47",			// 26
	"weapon_gnome",					// 27
	"weapon_cola_bottles",			// 28
	"weapon_fireworkcrate",			// 29
	"weapon_upgradepack_incendiary",	// 30
	"weapon_upgradepack_explosive",		// 31
	"weapon_pistol_magnum",			// 32
	"weapon_smg_mp5",				// 33
	"weapon_rifle_sg552",			// 34
	"weapon_sniper_awp",			// 35
	"weapon_sniper_scout",			// 36
	"weapon_rifle_m60",				// 37
	"weapon_tank_claw",				// 38
	"weapon_hunter_claw",			// 39
	"weapon_charger_claw",			// 40
	"weapon_boomer_claw",			// 41
	"weapon_smoker_claw",			// 42
	"weapon_spitter_claw",			// 43
	"weapon_jockey_claw",			// 44
	"weapon_machinegun",			// 45
	"vomit",						// 46
	"splat",						// 47
	"pounce",						// 48
	"lounge",						// 49
	"pull",							// 50
	"choke",						// 51
	"rock",							// 52
	"physics",						// 53
	"weapon_ammo",					// 54
	"upgrade_item",					// 55
	""
};

static const char L4D2WeaponWorldModel[L4D2WeaponId][] =
{
	"",
	"/w_models/weapons/w_pistol_b.mdl",
	"/w_models/weapons/w_smg_uzi.mdl",
	"/w_models/weapons/w_shotgun.mdl",
	"/w_models/weapons/w_autoshot_m4super.mdl",
	"/w_models/weapons/w_rifle_m16a2.mdl",
	"/w_models/weapons/w_sniper_mini14.mdl",
	"/w_models/weapons/w_smg_a.mdl",
	"/w_models/weapons/w_pumpshotgun_a.mdl",
	"/w_models/weapons/w_desert_rifle.mdl",			// "/w_models/weapons/w_rifle_b.mdl"
	"/w_models/weapons/w_sniper_military.mdl",
	"/w_models/weapons/w_shotgun_spas.mdl",
	"/w_models/weapons/w_eq_medkit.mdl",
	"/w_models/weapons/w_eq_molotov.mdl",
	"/w_models/weapons/w_eq_pipebomb.mdl",
	"/w_models/weapons/w_eq_painpills.mdl",
	"/props_junk/gascan001a.mdl",
	"/props_junk/propanecanister001.mdl",
	"/props_equipment/oxygentank01.mdl",
	"",		// "/weapons/w_knife_t.mdl",
			// "/weapons/melee/w_bat.mdl",
			// "/weapons/melee/w_chainsaw.mdl
			// "/weapons/melee/w_cricket_bat.mdl",
			// "/weapons/melee/w_crowbar.mdl",
			// "/weapons/melee/w_didgeridoo.mdl",
			// "/weapons/melee/w_electric_guitar.mdl",
			// "/weapons/melee/w_fireaxe.mdl",
			// "/weapons/melee/w_frying_pan.mdl",
			// "/weapons/melee/w_golfclub.mdl",
			// "/weapons/melee/w_katana.mdl",
			// "/weapons/melee/w_machete.mdl",
			// "/weapons/melee/w_riotshield.mdl",
			// "/weapons/melee/w_tonfa.mdl"
	"/weapons/melee/w_chainsaw.mdl",
	"/w_models/weapons/w_grenade_launcher.mdl",
	"",
	"/w_models/weapons/w_eq_adrenaline.mdl",
	"/w_models/weapons/w_eq_defibrillator.mdl",
	"/w_models/weapons/w_eq_bile_flask.mdl",
	"/w_models/weapons/w_rifle_ak47.mdl",
	"/props_junk/gnome.mdl",
	"/w_models/weapons/w_cola.mdl",
	"/props_junk/explosive_box001.mdl",
	"/w_models/weapons/w_eq_incendiary_ammopack.mdl",
	"/w_models/weapons/w_eq_explosive_ammopack.mdl",
	"/w_models/weapons/w_desert_eagle.mdl",
	"/w_models/weapons/w_smg_mp5.mdl",
	"/w_models/weapons/w_rifle_sg552.mdl",
	"/w_models/weapons/w_sniper_awp.mdl",
	"/w_models/weapons/w_sniper_scout.mdl",
	"/w_models/weapons/w_m60.mdl",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	""
};

StringMap g_hWeaponNameTrie;

/**
 * Returns whether weapon id is valid.
 *
 * @param weaponId		Weapon id to check for validity.
 * @return				True if weapon id is valid, false otherwise.
 */
// L4D2 only.
stock bool L4D2_IsValidWeaponId(L4D2WeaponId weaponId)
{
	return weaponId >= L4D2WeaponId_None && weaponId < L4D2WeaponId_MAX;
}

/**
 * Returns whether weapon name is a valid weapon.
 *
 * @param weaponName	Weapon name to check for validity.
 * @return				True if weapon name is valid, false otherwise.
 */
// L4D2 only.
stock bool L4D2_IsValidWeaponName(const char[] weaponName)
{
	return L4D2_GetWeaponIdByWeaponName(weaponName) != L4D2WeaponId_None;
}

/**
 * Checks to see if a given weapon id has a known WeaponModel in this file's model array.
 *
 * Note: The melee weapon have multiple valid models. This function will
 * return false for melee weapon.
 *
 * @param weaponId		Weapon id to check for a known weapon model for.
 * @return				True if a valid weapon model exists for weapon id, false otherwise.
 */
// L4D2 only.
stock bool L4D2_HasValidWeaponWorldModel(L4D2WeaponId weaponId)
{
	return L4D2WeaponWorldModel[weaponId][0] != '\0';
}

/**
 * Returns weapon world model by weapon id.
 *
 * @note Does not work with melee weapons.
 *
 * @param weaponId		Weapon id.
 * @param dest			Destination string buffer to copy to.
 * @param destlen		Destination buffer length (includes null terminator).
 * @return				Number of cells written.
 */
// L4D2 only.
stock int L4D2_GetWeaponModelByWeaponId(L4D2WeaponId weaponId, char[] dest, int destlen)
{
	if (!L4D2_IsValidWeaponId(weaponId))
	{
		return 0;
	}

	return strcopy(dest, destlen, L4D2WeaponWorldModel[weaponId]);
}

/**
 * Returns weapon id by weapon world model.
 *
 * @note Does not work with melee weapons.
 *
 * @param model			Weapon world model.
 * @return				Weapon Id.
 */
// L4D2 only.
stock L4D2WeaponId L4D2_GetWeaponIdByWeaponModel(const char[] model)
{
	for (int i = 0; i < sizeof(L4D2WeaponWorldModel); i++)
	{
		if (strcmp(model, L4D2WeaponWorldModel[i], false) == 0)
		{
			return view_as<L4D2WeaponId>(i);
		}
	}

	return L4D2WeaponId_None;
}

/**
 * Returns weapon id by weapon name.
 *
 * @param weaponName	Weapon name to get id from.
 * @return				The corresponding weapon id if found, else L4D2WeaponId_None.
 */
// L4D2 only.
stock L4D2WeaponId L4D2_GetWeaponIdByWeaponName(const char[] weaponName)
{
	L4D2_InitWeaponNameTrie();
	L4D2WeaponId weaponId;
	return g_hWeaponNameTrie.GetValue(weaponName, weaponId) ? weaponId : L4D2WeaponId_None;
}

/**
 * Returns weapon name by weapon id.
 *
 * @param weaponName	Weapon id to get name from.
 * @param dest			Destination string buffer to copy to.
 * @param destlen		Destination buffer length (includes null terminator).
 * @return				Number of cells written.
 */
// L4D2 only.
stock int L4D2_GetWeaponNameByWeaponId(L4D2WeaponId weaponId, char[] dest, int destlen)
{
	if (!L4D2_IsValidWeaponId(weaponId))
	{
		return 0;
	}

	return strcopy(dest, destlen, L4D2WeaponName[weaponId]);
}

/**
 * Returns weapon id of entity.
 *
 * @param weapon		Entity index of weapon.
 * @return				Weapon id if found, L4D2WeaponId_None otherwise.
 * @error				Invalid entity index.
 */
// L4D2 only.
stock L4D2WeaponId L4D2_GetWeaponId(int weapon)
{
	char classname[64];
	if (!GetEdictClassname(weapon, classname, sizeof(classname)))
	{
		return L4D2WeaponId_None;
	}

	if (strcmp(classname, "weapon_spawn") == 0)
	{
		return view_as<L4D2WeaponId>(GetEntProp(weapon, Prop_Send, "m_weaponID"));
	}

	int len = strlen(classname);
	if (len - 6 > 0 && strcmp(classname[len - 6], "_spawn") == 0)
	{
		classname[len - 6] = '\0';
	}

	return L4D2_GetWeaponIdByWeaponName(classname);
}

/**
 * Initialize the L4D2 weapon names trie. Not necessary to be executed, done by the functions that require the trie.
 *
 * @noreturn
 */
// L4D2 only.
stock void L4D2_InitWeaponNameTrie()
{
	if (g_hWeaponNameTrie != null)
	{
		return;
	}

	g_hWeaponNameTrie = new StringMap();
	for (int i = 0; i < view_as<int>(L4D2WeaponId_MAX); i++)
	{
		g_hWeaponNameTrie.SetValue(L4D2WeaponName[i], i);
	}
}