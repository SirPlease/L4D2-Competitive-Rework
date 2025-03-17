/* -----------------------------------------------------------------------------------------------------------------------------------------------------
 * 	Changelog:
 * 	---------
 *		2.3: (17.01.2025) (Forgetest)
 *			Fix:
 *			- Fixed "small-sized" mobs involving uncommon zombies.
 *
 *		2.2: (24.10.2021) (A1m`)
 *			1. Fixed: in some cases we received the coordinates of the infected 0.0.0, now the plugin always gets the correct coordinates.
 *
 * 		2.0: (14.08.2021) (A1m`)
 * 			1. Completely rewrite the method of identifying uncommon infected.
 * 			2. Added some uncommon infected (fallen survivor and Jimmy Gibbs).
 * 			3. Optimization and code improvement.
 * 			4. Plugin tested for all uncommon infected.
 * 			5. A bug is noticed in the plugin, sometimes we get zero coordinates on the SDKHook_SpawnPost, what should we do about it?
 *
 * 		0.1d: (06.07.2021) (A1m`)
 * 			1. fixes description of cvar 'sm_uncinfblock_enabled' after 12+- years of using the plugin :D.
 *
 * 		0.1c: (23.06.2021) (A1m`)
 * 			1. new syntax, little fixes.
 *
 * 		0.1b:
 * 			1. spawns infected after killing uncommon entity.
 *
 * 		0.1a
 * 			1. first version (not really optimized).
 *
 * -----------------------------------------------------------------------------------------------------------------------------------------------------
 * Plugin test results (these are all uncommon infected):
 *
 * L4D2Gender_Ceda = 11
 * Plugin flag: (11 - 11 = 0) (1 << 0) = 1
 * Uncommon infected spawned! Model: models/infected/common_male_ceda_l4d1.mdl, gender: 11, plugin flag: 1.
 * Uncommon infected spawned! Model: models/infected/common_male_ceda.mdl, gender: 11, plugin flag: 1.
 *
 * L4D2Gender_Crawler = 12
 * Plugin flag: (12 - 11 = 1) (1 << 1) = 2
 * Uncommon infected spawned! Model: models/infected/common_male_mud_L4D1.mdl, gender: 12, plugin flag: 2.
 * Uncommon infected spawned! Model: models/infected/common_male_mud.mdl, gender: 12, plugin flag: 2.
 *
 * L4D2Gender_Undistractable = 13
 * Plugin flag: (13 - 11 = 2) (1 << 2) = 4
 * Uncommon infected spawned! Model: models/infected/common_male_roadcrew_l4d1.mdl, gender: 13, plugin flag: 4.
 * Uncommon infected spawned! Model: models/infected/common_male_roadcrew.mdl, gender: 13, plugin flag: 4.
 * Uncommon infected spawned! Model: models/infected/common_male_baggagehandler_02.mdl, gender: 13, plugin flag: 4.
 * Note: common_male_roadcrew_rain.mdl is this model used in the game?
 *
 * L4D2Gender_Fallen = 14
 * Plugin flag: (14 - 11 = 3) (1 << 3) = 8
 * Uncommon infected spawned! Model: models/infected/common_male_fallen_survivor_l4d1.mdl, gender: 14, plugin flag: 8.
 * Uncommon infected spawned! Model: models/infected/common_male_fallen_survivor.mdl, gender: 14, plugin flag: 8.
 * Uncommon infected spawned! Model: models/infected/common_male_parachutist.mdl, gender: 14, plugin flag: 8.
 * Note: no, it's not the one that hangs on the tree on the map 'c3m2_swamp'.

 * L4D2Gender_Riot_Control = 15
 * Plugin flag: (15 - 11 = 4) (1 << 4) = 16
 * Uncommon infected spawned! Model: models/infected/common_male_riot.mdl, gender: 15, plugin flag: 16.
 * Note: there is a version for l4d1, but it is not used (common_male_riot_l4d1.mdl).

 * L4D2Gender_Clown = 16
 * Plugin flag: (16 - 11 = 5) (1 << 5) = 32
 * Uncommon infected spawned! Model: models/infected/common_male_clown.mdl, gender: 16, plugin flag: 32.

 * L4D2Gender_Jimmy = 17
 * Plugin flag: (17 - 11 = 6) (1 << 6) = 64
 * Uncommon infected spawned! Model: models/infected/common_male_jimmy.mdl, gender: 17, plugin flag: 64.
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define DEBUG 0
#define UNCOMMON_INFECTED_AMOUNT 7

stock const char sUncommon[][] =
{
	"ceda",
	"crawler",
	"undistractable",
	"fallen",
	"riot_control",
	"clown",
	"jimmy"
};

ConVar
	g_hPluginEnabled = null,
	g_hBlockUncInfFlags = null;

public Plugin myinfo =
{
	name = "Uncommon Infected Blocker",
	author = "Tabun, A1m`",
	description = "Blocks uncommon infected from ruining your day.",
	version = "2.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	g_hPluginEnabled = CreateConVar("sm_uncinfblock_enabled", "1", "Enable uncommon blocker plugin?", _, true, 0.0, true, 1.0 );

	// 1 + 2 + 4 + 8 + 16 + 32 + 64 = 127 - Block all
	// 55 - All except fallen survivor and Jimmy Gibbs
	g_hBlockUncInfFlags = CreateConVar( \
		"sm_uncinfblock_flags", \
		"55", \
		"Which uncommon infected to block (1:ceda, 2:crawler(mudmen), 4:undistractable(roadcrew), 8:fallen, 16:riotcop, 32:clown, 64:jimmy). 127 - All.", \
		_, true, 1.0, true, 127.0 \
	);

	RegAdminCmd("sm_uncinfblock_check", Cmd_UncInfBlock_Check, ADMFLAG_GENERIC);
}

Action Cmd_UncInfBlock_Check(int iClient, int iArgs)
{
	for (int i = 0; i < UNCOMMON_INFECTED_AMOUNT; i++) {
		ReplyToCommand(iClient, "Uncommon class '%s' %s. Uncommon infected Flag: %d.", sUncommon[i], (IsUncommonInfectedBlocked(i)) ? "blocked" : "unblocked", (1 << i));
	}

	return Plugin_Handled;
}

public void OnEntityCreated(int iEntity, const char[] sClassName)
{
	if (sClassName[0] != 'i' || !g_hPluginEnabled.BoolValue) {
		return;
	}

	if (strncmp(sClassName, "infected", 8, false) == 0) {
		SDKHook(iEntity, SDKHook_SpawnPost, Hook_OnEntitySpawned);
	}
}

void Hook_OnEntitySpawned(int iEntity)
{
	RequestFrame(OnNextFrame, EntIndexToEntRef(iEntity));
}

void OnNextFrame(int iEntity)
{
	if (EntRefToEntIndex(iEntity) == INVALID_ENT_REFERENCE || !IsValidEdict(iEntity)) {
		return;
	}

	int iUncommonInfected = GetGender(iEntity) - L4D2Gender_Ceda;
	bool bIsUncommonInfected = (iUncommonInfected >= 0 && iUncommonInfected < UNCOMMON_INFECTED_AMOUNT);

	if (!bIsUncommonInfected) {
		return;
	}

#if DEBUG
	char sModel[PLATFORM_MAX_PATH];
	GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	PrintToChatAll("Uncommon infected spawned! Entity: %d, model: %s, gender: %d, plugin flag: %d, blocked: %s.", \
						EntRefToEntIndex(iEntity), sModel, GetGender(iEntity), (1 << iUncommonInfected), (IsUncommonInfectedBlocked(iUncommonInfected)) ? "true" : "false");
#endif

	if (!IsUncommonInfectedBlocked(iUncommonInfected)) {
		return;
	}
	
	float fLocation[3];
	GetEntPropVector(iEntity, Prop_Data, "m_vecAbsOrigin", fLocation);			// get location
																				// @Forgetest: "m_vecOrigin" is not world origin

	bool mobRush = GetEntProp(iEntity, Prop_Send, "m_mobRush") == 1;

#if DEBUG
	PrintToChatAll("2 Blocked uncommon infected! Entity: %d, location: %.0f %.0f %.0f, mobRush: %s.", EntRefToEntIndex(iEntity), fLocation[0], fLocation[1], fLocation[2], mobRush ? "true" : "false");
#endif

	// kill the uncommon infected
#if SOURCEMOD_V_MINOR > 8
	RemoveEntity(iEntity);
#else
	AcceptEntityInput(iEntity, "Kill");
#endif

	SpawnNewInfected(fLocation, mobRush);											// spawn infected in location instead
}

void SpawnNewInfected(const float fLocation[3], bool mobRush)
{
	int iInfected = CreateEntityByName("infected");
	if (iInfected < 1) {
		return;
	}

	/*
	 * Original game code:
	 * #define TICK_INTERVAL			(gpGlobals->interval_per_tick)
	 * #define TIME_TO_TICKS( dt )		( (int)( 0.5f + (float)(dt) / TICK_INTERVAL ) )
	 * SetNextThink( TIME_TO_TICKS(gpGlobals->curtime ) );
	*/
	int iTickTime = RoundToNearest(GetGameTime() / GetTickInterval()) + 5; // copied from uncommon spawner plugin, prolly helps avoid the zombie get 'stuck' ?

	SetEntProp(iInfected, Prop_Data, "m_nNextThinkTick", iTickTime);
	DispatchSpawn(iInfected);
	ActivateEntity(iInfected);

	TeleportEntity(iInfected, fLocation, NULL_VECTOR, NULL_VECTOR);

	if (mobRush)
		SetEntProp(iInfected, Prop_Send, "m_mobRush", mobRush);

#if DEBUG
	PrintToChatAll("Spawned new infected! Entity: %d, location: %.0f %.0f %.0f, mobRush: %s.", iInfected, fLocation[0], fLocation[1], fLocation[2], mobRush ? "true" : "false");
#endif
}

bool IsUncommonInfectedBlocked(const int iUncommonInfected)
{
	return (((1 << iUncommonInfected) & g_hBlockUncInfFlags.IntValue) != 0);
}
