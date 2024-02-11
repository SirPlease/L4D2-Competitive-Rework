#if defined __weapon_information_included
	#endinput
#endif
#define __weapon_information_included

#define DEBUG_WI							0

#if (DEBUG_ALL)
	#define DEBUG_WI						1
#endif

#define WI_MODULE_NAME						"WepInfo"

#define MODEL_PREFIX						"models/w_models/weapons/w_"
#define MODEL_SURFIX						".mdl"
#define SPAWN_PREFIX						"weapon_"
#define SPAWN_SURFIX						"_spawn"

//====================================================
// Weapon Index & ID
//====================================================
#define WEAPON_REMOVE_INDEX					-1
#define WEAPON_NULL_INDEX					0

#define WEAPON_SMG_ID						2
#define WEAPON_SMG_INDEX					1
#define WEAPON_PUMPSHOTGUN_ID				3
#define WEAPON_PUMPSHOTGUN_INDEX			2

#define WEAPON_AUTOSHOTGUN_ID				4
#define WEAPON_AUTOSHOTGUN_INDEX			3
#define WEAPON_RIFLE_ID						5
#define WEAPON_RIFLE_INDEX					4

#define WEAPON_HUNTING_RIFLE_ID				6
#define WEAPON_HUNTING_RIFLE_INDEX			5
#define WEAPON_SMG_SILENCED_ID				7
#define WEAPON_SMG_SILENCED_INDEX			6

#define WEAPON_SHOTGUN_CHROME_ID			8
#define WEAPON_SHOTGUN_CHROME_INDEX			7
#define WEAPON_RIFLE_DESERT_ID				9
#define WEAPON_RIFLE_DESERT_INDEX			8

#define WEAPON_SNIPER_MILITARY_ID			10
#define WEAPON_SNIPER_MILITARY_INDEX		9
#define WEAPON_SHOTGUN_SPAS_ID				11
#define WEAPON_SHOTGUN_SPAS_INDEX			10

#define WEAPON_GRENADE_LAUNCHER_ID			21
#define WEAPON_GRENADE_LAUNCHER_INDEX		11
#define WEAPON_RIFLE_AK47_ID				26
#define WEAPON_RIFLE_AK47_INDEX				12

#define WEAPON_RIFLE_M60_ID					37
#define WEAPON_RIFLE_M60_INDEX				13

#define WEAPON_SMG_MP5_ID					33
#define WEAPON_SMG_MP5_INDEX				14
#define WEAPON_RIFLE_SG552_ID				34
#define WEAPON_RIFLE_SG552_INDEX			15

#define WEAPON_SNIPER_AWP_ID				35
#define WEAPON_SNIPER_AWP_INDEX				16
#define WEAPON_SNIPER_SCOUT_ID				36
#define WEAPON_SNIPER_SCOUT_INDEX			17

#define WEAPON_CHAINSAW_INDEX				18

#define WEAPON_PIPE_BOMB_INDEX				19
#define WEAPON_MOLOTOV_INDEX				20
#define WEAPON_VOMITJAR_INDEX				21

#define WEAPON_FIRST_AID_KIT_INDEX			22
#define WEAPON_DEFIBRILLATOR_INDEX			23
#define WEAPON_UPG_EXPLOSIVE_INDEX			24
#define WEAPON_UPG_INCENDIARY_INDEX			25

#define WEAPON_PAIN_PILLS_INDEX				26
#define WEAPON_ADRENALINE_INDEX				27

//====================================================
#define NUM_OF_WEAPONS						28

#define FIRST_WEAPON						1
#define LAST_WEAPON							18
#define FIRST_EXTRA							19
#define LAST_EXTRA							27

#define WEAPON_NUMBER_OF_START_KITS			4

enum /*WEAPONATTRIBUTES*/
{
	WeaponID,
	Tier1EquivalentIndex,
	ReplacementIndex,

	WeaponAttributes_Size
};

static const int Weapon_Attributes[NUM_OF_WEAPONS][WeaponAttributes_Size] = {

	//====================================================
	// Weapons
	//====================================================

	// NULL
	{
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX
	},

	// SMG
	{
		WEAPON_SMG_ID,
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX
	},

	// Pumpshotgun
	{
		WEAPON_PUMPSHOTGUN_ID,
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX
	},

	// Autoshotgun
	{
		WEAPON_AUTOSHOTGUN_ID,
		WEAPON_PUMPSHOTGUN_INDEX,
		WEAPON_NULL_INDEX
	},

	// Rifle
	{
		WEAPON_RIFLE_ID,
		WEAPON_SMG_INDEX,
		WEAPON_NULL_INDEX
	},

	// Hunting rifle
	{
		WEAPON_HUNTING_RIFLE_ID,
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX
	},

	// SMG silenced
	{
		WEAPON_SMG_SILENCED_ID,
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX
	},

	// Chrome shotgun
	{
		WEAPON_SHOTGUN_CHROME_ID,
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX
	},

	// Desert rifle
	{
		WEAPON_RIFLE_DESERT_ID,
		WEAPON_SMG_INDEX,
		WEAPON_NULL_INDEX
	},

	// Military sniper
	{
		WEAPON_SNIPER_MILITARY_ID,
		WEAPON_HUNTING_RIFLE_INDEX,
		WEAPON_NULL_INDEX
	},

	// Spas shotgun
	{
		WEAPON_SHOTGUN_SPAS_ID,
		WEAPON_SHOTGUN_CHROME_INDEX,
		WEAPON_NULL_INDEX
	},

	// Grenade launcher
	{
		WEAPON_GRENADE_LAUNCHER_ID,
		WEAPON_NULL_INDEX,
		WEAPON_REMOVE_INDEX
	},

	// AK47
	{
		WEAPON_RIFLE_AK47_ID,
		WEAPON_SMG_SILENCED_INDEX,
		WEAPON_NULL_INDEX
	},

	// M60
	{
		WEAPON_RIFLE_M60_ID,
		WEAPON_NULL_INDEX,
		WEAPON_REMOVE_INDEX,
	},

	// MP5
	{
		WEAPON_SMG_MP5_ID,
		WEAPON_NULL_INDEX,
		WEAPON_SMG_INDEX
	},

	// SG552
	{
		WEAPON_RIFLE_SG552_ID,
		WEAPON_SMG_MP5_INDEX,
		WEAPON_RIFLE_INDEX
	},

	// AWP
	{
		WEAPON_SNIPER_AWP_ID,
		WEAPON_SNIPER_SCOUT_INDEX,
		WEAPON_SNIPER_MILITARY_INDEX
	},

	// Scout
	{
		WEAPON_SNIPER_SCOUT_ID,
		WEAPON_NULL_INDEX,
		WEAPON_HUNTING_RIFLE_INDEX
	},

	//====================================================
	// Melee Weapons
	//====================================================

	// Chainsaw
	{
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX,
		WEAPON_REMOVE_INDEX
	},

	//====================================================
	// Extra Items
	//====================================================

	// Pipe Bomb
	{
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX
	},

	// Molotov
	{
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX
	},

	// Vomitjar
	{
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX
	},

	// First Aid Kit
	{
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX,
		WEAPON_REMOVE_INDEX
	},

	// Defibrillator
	{
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX,
		WEAPON_REMOVE_INDEX
	},

	// Explosive Upgrade Pack
	{
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX,
		WEAPON_REMOVE_INDEX
	},

	// Incendiary Upgrade Pack
	{
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX,
		WEAPON_REMOVE_INDEX
	},

	// Pain pills
	{
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX
	},

	// Adrenaline
	{
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX,
		WEAPON_NULL_INDEX
	}
};

static const char Weapon_Models[NUM_OF_WEAPONS][] = {

	//====================================================
	// Weapons
	//====================================================

	// NULL
	"",

	// SMG
	"smg_uzi",

	// Shotgun
	"shotgun",

	// Autoshotgun
	"autoshot_m4super",

	// Rifle
	"rifle_m16a2",

	// Hunting rifle
	"sniper_mini14",

	// SMG silenced
	"smg_a",

	// Chrome shotgun
	"pumpshotgun_a",

	// Desert rifle
	"rifle_b",

	// Military rifle
	"sniper_military",

	// Spas shotgun
	"shotgun_spas",

	// Grenade launcher
	"",

	// AK47
	"rifle_ak47",

	// M60
	"m60",

	// MP5
	"smg_mp5",

	// SG552
	"",

	// AWP
	"",

	// Scout
	"sniper_scout",

	//====================================================
	// Melee Weapons
	//====================================================

	// Chainsaw
	"",

	//====================================================
	// Extra Items
	//====================================================

	// Pipe Bomb
	"",

	// Molotov
	"",

	// Vomitjar
	"",

	// First Aid Kit
	"",

	// Defibrillator
	"",

	// Explosive Upgrade Pack
	"",

	// Incendiary Upgrade Pack
	"",

	// Pain pills
	"",

	// Adrenaline
	""
};

static const char Weapon_Spawns[NUM_OF_WEAPONS][] = {

	//====================================================
	// Weapons
	//====================================================

	// NULL
	"",

	// SMG
	"",

	// Shotgun
	"",

	// Autoshotgun
	"autoshotgun",

	// Rifle
	"rifle",

	// Hunting rifle
	"",

	// SMG silenced
	"",

	// Chrome shotgun
	"",

	// Desert rifle
	"rifle_desert",

	// Military rifle
	"sniper_military",

	// Spas shotgun
	"shotgun_spas",

	// Grenade launcher
	"grenade_launcher",

	// AK47
	"rifle_ak47",

	// M60
	"rifle_m60",

	// MP5
	"",

	// SG552
	"",

	// AWP
	"",

	// Scout
	"",

	//====================================================
	// Melee Weapons
	//====================================================

	// Chainsaw
	"chainsaw",

	//====================================================
	// Extra Items
	//====================================================

	// Pipe Bomb
	"pipe_bomb",

	// Molotov
	"molotov",

	// Vomitjar
	"vomitjar",

	// First Aid Kit
	"first_aid_kit",

	// Defibrillator
	"defibrillator",

	// Explosive Upgrade Pack
	"upgradepack_explosive",

	// Incendiary Upgrade Pack
	"upgradepack_incendiary",

	// Pain pills
	"pain_pills",

	// Adrenaline
	"adrenaline"
};

//====================================================
// Kit Protection
//====================================================
static int
	Weapon_iKitEntity[WEAPON_NUMBER_OF_START_KITS] = {0, ...},
	Weapon_iKitCount = 0;

//====================================================
// Map Info
//====================================================
static float
	Weapon_fMapOrigin_Start[3],
	Weapon_fMapOrigin_End[3],
	Weapon_fMapDist_Start,
	Weapon_fMapDist_StartExtra,
	Weapon_fMapDist_End;

static bool
	Weapon_bUpdateMapInfo = true;
//====================================================

static bool
	Weapon_bConvar[NUM_OF_WEAPONS] = {false, ...},
	Weapon_bReplaceTier2 = true,
	Weapon_bReplaceTier2_Finale = true,
	Weapon_bReplaceTier2_All = true,
	Weapon_bLimitTier2 = true,
	Weapon_bLimitTier2_Safehouse = true,
	Weapon_bReplaceStartKits = true,
	Weapon_bReplaceFinaleKits = true,
	Weapon_bRemoveLaserSight = true,
	Weapon_bRemoveExtraItems = true;

static ConVar
	Weapon_hConvar[NUM_OF_WEAPONS] = {null, ...},
	Weapon_hReplaceTier2 = null,
	Weapon_hReplaceTier2_Finale = null,
	Weapon_hReplaceTier2_All = null,
	Weapon_hLimitTier2 = null,
	Weapon_hLimitTier2_Safehouse = null,
	Weapon_hReplaceStartKits = null,
	Weapon_hReplaceFinaleKits = null,
	Weapon_hRemoveLaserSight = null,
	Weapon_hRemoveExtraItems = null;

//====================================================
// Module setup
//====================================================
void WI_OnModuleStart()
{
	WI_Convar_Setup();

	HookEvent("round_start", WI_RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", WI_RoundEnd_Event, EventHookMode_PostNoCopy);
	HookEvent("spawner_give_item", WI_SpawnerGiveItem_Event);
}

void WI_OnMapEnd()
{
	Weapon_bUpdateMapInfo = true;
}

//====================================================
// Functions
//====================================================
static void WI_Convar_Setup()
{
	Weapon_hConvar[WEAPON_SMG_MP5_INDEX] = CreateConVarEx("replace_cssweapons", "1", "Replace CSS weapons with normal L4D2 weapons", _, true, 0.0, true, 1.0);

	Weapon_hConvar[WEAPON_RIFLE_SG552_INDEX] = Weapon_hConvar[WEAPON_SMG_MP5_INDEX];
	Weapon_hConvar[WEAPON_SNIPER_AWP_INDEX] = Weapon_hConvar[WEAPON_SMG_MP5_INDEX];
	Weapon_hConvar[WEAPON_SNIPER_SCOUT_INDEX] = Weapon_hConvar[WEAPON_SMG_MP5_INDEX];

	Weapon_hConvar[WEAPON_GRENADE_LAUNCHER_INDEX] = CreateConVarEx("remove_grenade", "1", "Remove all grenade launchers", _, true, 0.0, true, 1.0);
	Weapon_hConvar[WEAPON_CHAINSAW_INDEX] = CreateConVarEx("remove_chainsaw", "1", "Remove all chainsaws", _, true, 0.0, true, 1.0);
	Weapon_hConvar[WEAPON_RIFLE_M60_INDEX] = CreateConVarEx("remove_m60", "1", "Remove all M60 rifles", _, true, 0.0, true, 1.0);

	Weapon_hConvar[WEAPON_FIRST_AID_KIT_INDEX] = CreateConVarEx("remove_statickits", "1", "Remove all static medkits (medkits such as the gun shop, these are compiled into the map)", _, true, 0.0, true, 1.0);
	Weapon_hConvar[WEAPON_DEFIBRILLATOR_INDEX] = CreateConVarEx("remove_defib", "1", "Remove all defibrillators", _, true, 0.0, true, 1.0);
	Weapon_hConvar[WEAPON_UPG_EXPLOSIVE_INDEX] = CreateConVarEx("remove_upg_explosive", "1", "Remove all explosive upgrade packs", _, true, 0.0, true, 1.0);
	Weapon_hConvar[WEAPON_UPG_INCENDIARY_INDEX] = CreateConVarEx("remove_upg_incendiary", "1", "Remove all incendiary upgrade packs", _, true, 0.0, true, 1.0);

	for (int index = FIRST_WEAPON; index < NUM_OF_WEAPONS; index++) {
		if (Weapon_hConvar[index] == null) {
			continue;
		}

		Weapon_bConvar[index] = Weapon_hConvar[index].BoolValue;
		Weapon_hConvar[index].AddChangeHook(WI_ConvarChange);
	}

	Weapon_hReplaceTier2 = CreateConVarEx("replace_tier2", "1", "Replace tier 2 weapons in start and end safe room with their tier 1 equivalent", _, true, 0.0, true, 1.0);
	Weapon_hReplaceTier2_Finale = CreateConVarEx("replace_tier2_finale", "1", "Replace tier 2 weapons in start safe room with their tier 1 equivalent, on finale", _, true, 0.0, true, 1.0);
	Weapon_hReplaceTier2_All = CreateConVarEx("replace_tier2_all", "1", "Replace ALL tier 2 weapons with their tier 1 equivalent EVERYWHERE", _, true, 0.0, true, 1.0);
	Weapon_hLimitTier2 = CreateConVarEx("limit_tier2", "1", "Limit tier 2 weapons outside safe rooms. Replaces a tier 2 stack with tier 1 upon first weapon pickup", _, true, 0.0, true, 1.0);
	Weapon_hLimitTier2_Safehouse = CreateConVarEx("limit_tier2_saferoom", "1", "Limit tier 2 weapons inside safe rooms. Replaces a tier 2 stack with tier 1 upon first weapon pickup", _, true, 0.0, true, 1.0);
	Weapon_hReplaceStartKits = CreateConVarEx("replace_startkits", "1", "Replaces start medkits with pills", _, true, 0.0, true, 1.0);
	Weapon_hReplaceFinaleKits = CreateConVarEx("replace_finalekits", "1", "Replaces finale medkits with pills", _, true, 0.0, true, 1.0);
	Weapon_hRemoveLaserSight = CreateConVarEx("remove_lasersight", "1", "Remove all laser sight upgrades", _, true, 0.0, true, 1.0);
	Weapon_hRemoveExtraItems = CreateConVarEx("remove_saferoomitems", "1", "Remove all extra items inside saferooms (items for slot 3, 4 and 5, minus medkits)", _, true, 0.0, true, 1.0);

	ConVarsInType();

	Weapon_hReplaceTier2.AddChangeHook(WI_ConvarChange);
	Weapon_hReplaceTier2_Finale.AddChangeHook(WI_ConvarChange);
	Weapon_hReplaceTier2_All.AddChangeHook(WI_ConvarChange);
	Weapon_hLimitTier2.AddChangeHook(WI_ConvarChange);
	Weapon_hLimitTier2_Safehouse.AddChangeHook(WI_ConvarChange);
	Weapon_hReplaceStartKits.AddChangeHook(WI_ConvarChange);
	Weapon_hReplaceFinaleKits.AddChangeHook(WI_ConvarChange);
	Weapon_hRemoveLaserSight.AddChangeHook(WI_ConvarChange);
	Weapon_hRemoveExtraItems.AddChangeHook(WI_ConvarChange);
}

static void ConVarsInType()
{
	Weapon_bReplaceTier2 = Weapon_hReplaceTier2.BoolValue;
	Weapon_bReplaceTier2_Finale = Weapon_hReplaceTier2_Finale.BoolValue;
	Weapon_bReplaceTier2_All = Weapon_hReplaceTier2_All.BoolValue;
	Weapon_bLimitTier2 = Weapon_hLimitTier2.BoolValue;
	Weapon_bLimitTier2_Safehouse = Weapon_hLimitTier2_Safehouse.BoolValue;
	Weapon_bReplaceStartKits = Weapon_hReplaceStartKits.BoolValue;
	Weapon_bReplaceFinaleKits = Weapon_hReplaceFinaleKits.BoolValue;
	Weapon_bRemoveLaserSight = Weapon_hRemoveLaserSight.BoolValue;
	Weapon_bRemoveExtraItems = Weapon_hRemoveExtraItems.BoolValue;
}

static void WI_ConvarChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	for (int index = FIRST_WEAPON; index < NUM_OF_WEAPONS; index++) {
		if (Weapon_hConvar[index] == null) {
			continue;
		}

		Weapon_bConvar[index] = Weapon_hConvar[index].BoolValue;
	}

	ConVarsInType();
}

//================================================
// GetWeaponIndex( iEntity, const String:sEntityClassName[128] )
//================================================
// Searches the weapon index for the given entity
//  class
static int WI_GetWeaponIndex(int iEntity, const char[] sEntityClassName)
{
	//------------------------------------------------
	// Check for weapon in class name
	//------------------------------------------------
	// If the class name doesn't contain weapon at all
	//  we don't need to loop thourgh with this entity
	// Return false

	if (StrContains(sEntityClassName, "weapon") == -1) {
		return WEAPON_NULL_INDEX;
	}

#if (DEBUG_WI)
	LogMessage("[%s] GetWeaponIndex( iEntity %i sEntityClassName \"%s\" )", WI_MODULE_NAME, iEntity, sEntityClassName);
	LogMessage("[%s] {", WI_MODULE_NAME);
#endif

	//------------------------------------------------
	// Check class name
	//------------------------------------------------
	// If the class name is weapon_spawn we got a
	//  dynamic spawn and as such read the weapon id
	//  for detimernation of the weapon index

	int WeaponIndex;
	bool bFoundIndex = false;

	if (strcmp(sEntityClassName, "weapon_spawn") == 0) {
		int WepID = GetEntProp(iEntity, Prop_Send, "m_weaponID");

		#if (DEBUG_WI)
			LogMessage("[%s]     Dynamic weapon spawn, weaponID %i", WI_MODULE_NAME, WepID);
		#endif

		for (WeaponIndex = FIRST_WEAPON; WeaponIndex < NUM_OF_WEAPONS; WeaponIndex++) {
			if (Weapon_Attributes[WeaponIndex][WeaponID] != WepID) {
				continue;
			}

			#if (DEBUG_WI)
				LogMessage("[%s]     Weapon WeaponIndex %i", WI_MODULE_NAME, WeaponIndex);
			#endif

			bFoundIndex = true;
			break;
		}
	}
	//------------------------------------------------
	// Check static spawns
	//------------------------------------------------
	// Otherwise loop through the weapon index for
	//  static classes
	// If we got a match we know the index
	else {
		char sBuffer[MAX_ENTITY_NAME_LENGTH];
		for (WeaponIndex = FIRST_WEAPON; WeaponIndex < NUM_OF_WEAPONS; WeaponIndex++) {
			if (strlen(Weapon_Spawns[WeaponIndex]) < 1) {
				continue;
			}

			Format(sBuffer, sizeof(sBuffer), "%s%s%s", SPAWN_PREFIX, Weapon_Spawns[WeaponIndex], SPAWN_SURFIX);

			if (strcmp(sEntityClassName, sBuffer) != 0) {
				continue;
			}

			#if (DEBUG_WI)
				LogMessage("[%s]     Static spawn, weapon WeaponIndex %i", WI_MODULE_NAME, WeaponIndex);
			#endif

			bFoundIndex = true;
			break;
		}
	}

	//------------------------------------------------
	// Check index
	//------------------------------------------------
	// If we didn't find the index, return false

	if (!bFoundIndex) {
		#if (DEBUG_WI)
			LogMessage("[%s]     Not found in weapon index", WI_MODULE_NAME);
			LogMessage("[%s] }", WI_MODULE_NAME);
		#endif

		return WEAPON_NULL_INDEX;
	}

#if (DEBUG_WI)
	LogMessage("[%s] }", WI_MODULE_NAME);
#endif

	return WeaponIndex;
}

//================================================
// IsStatic( iEntity, iWeaponIndex )
//================================================
// Checks if the given entity with matching weapon
//  index is a static spawn

static bool WI_IsStatic(int iEntity, int iWeaponIndex)
{
	if (strlen(Weapon_Spawns[iWeaponIndex]) < 1) {
		return false;
	}

	char sEntityClassName[MAX_ENTITY_NAME_LENGTH], sBuffer[MAX_ENTITY_NAME_LENGTH];

	GetEdictClassname(iEntity, sEntityClassName, sizeof(sEntityClassName));
	Format(sBuffer, sizeof(sBuffer), "%s%s%s", SPAWN_PREFIX, Weapon_Spawns[iWeaponIndex], SPAWN_SURFIX);

	if (strcmp(sEntityClassName, sBuffer) != 0) {
		return false;
	}

	// This is to prevent crashing
	// Some static spawns doesn't have a model as we just wish to remove them
	if (strlen(Weapon_Models[iWeaponIndex]) < 1) {
		return false;
	}

	return true;
}

//================================================
// ReplaceWeapon( iEntity, iWeaponIndex, bool:bSpawnerEvent )
//================================================
// Takes care of handling weapon entities,
//  killing, replacing, and updateing.

static void WI_ReplaceWeapon(int iEntity, int iWeaponIndex, bool bSpawnerEvent = false)
{
	#if (DEBUG_WI)
		LogMessage("[%s]     ReplaceWeapon( iEntity %i, iWeaponIndex %i, bSpawnerEvent %b )", WI_MODULE_NAME, iEntity, iWeaponIndex, bSpawnerEvent);
		LogMessage("[%s]     {", WI_MODULE_NAME);
	#endif

	//------------------------------------------------
	// Removal of weapons
	//------------------------------------------------
	// Checks if the replacement index is equal to -1
	//  (WEAPON_REMOVE_INDEX)
	// If so, check the cvar boolean and kill the
	//  weapon

	if (!bSpawnerEvent
		&& Weapon_Attributes[iWeaponIndex][ReplacementIndex] == WEAPON_REMOVE_INDEX
		&& Weapon_bConvar[iWeaponIndex]
	) {
		KillEntity(iEntity);

		#if (DEBUG_WI)
			LogMessage("[%s]         Killing weapon as requested...", WI_MODULE_NAME);
			LogMessage("[%s]     }", WI_MODULE_NAME);
		#endif

		return;
	}

	//------------------------------------------------
	// Replacement of static weapons
	//------------------------------------------------
	// Replaces all weapon_*weaponname*_spawn with
	//  weapon_spawn and the old weapon ID

	char sModelBuffer[PLATFORM_MAX_PATH];
	float fOrigin[3], fRotation[3];

	if (!bSpawnerEvent
		&& WI_IsStatic(iEntity, iWeaponIndex)
		&& (Weapon_Attributes[iWeaponIndex][WeaponID] != WEAPON_NULL_INDEX)
	) {
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fOrigin);
		GetEntPropVector(iEntity, Prop_Send, "m_angRotation", fRotation);
		KillEntity(iEntity);

		iEntity = CreateEntityByName("weapon_spawn");
		SetEntProp(iEntity, Prop_Send, "m_weaponID", Weapon_Attributes[iWeaponIndex][WeaponID]);

		Format(sModelBuffer, sizeof(sModelBuffer), "%s%s%s", MODEL_PREFIX, Weapon_Models[iWeaponIndex], MODEL_SURFIX);
		SetEntityModel(iEntity, sModelBuffer);

		TeleportEntity(iEntity, fOrigin, fRotation, NULL_VECTOR);
		DispatchKeyValue(iEntity, "count", "5");
		DispatchSpawn(iEntity);
		SetEntityMoveType(iEntity, MOVETYPE_NONE);

		#if (DEBUG_WI)
			LogMessage("[%s]         Replacing static spawn with weapon_spawn, new iEntity %i, weaponID %i, model \"%s\"", \
							WI_MODULE_NAME, iEntity, Weapon_Attributes[iWeaponIndex][WeaponID], sModelBuffer);
		#endif
	}

	//------------------------------------------------
	// Replace Weapons
	//------------------------------------------------
	// Replace weapons that needs to be done so
	// This is to replace CSS weapons, but can be
	//  adjusted to fit with any weapon

	if ((!bSpawnerEvent
		&& Weapon_Attributes[iWeaponIndex][ReplacementIndex] != WEAPON_NULL_INDEX
		|| Weapon_Attributes[iWeaponIndex][ReplacementIndex] != WEAPON_REMOVE_INDEX)
		&& Weapon_bConvar[iWeaponIndex]
	) {
		iWeaponIndex = Weapon_Attributes[iWeaponIndex][ReplacementIndex];
		SetEntProp(iEntity, Prop_Send, "m_weaponID", Weapon_Attributes[iWeaponIndex][WeaponID]);
		Format(sModelBuffer, sizeof(sModelBuffer), "%s%s%s", MODEL_PREFIX, Weapon_Models[iWeaponIndex], MODEL_SURFIX);
		SetEntityModel(iEntity, sModelBuffer);

		#if (DEBUG_WI)
			LogMessage("[%s]          Following replacement index, new weaponID %i, new model \"%s\"", WI_MODULE_NAME, iWeaponIndex, sModelBuffer);
		#endif
	}

	//------------------------------------------------
	// Check for tier 1 equivalent
	//------------------------------------------------
	// Check the current weapon index for a tier 1
	//  equivalent

	if (Weapon_Attributes[iWeaponIndex][Tier1EquivalentIndex] == WEAPON_NULL_INDEX) {
		#if (DEBUG_WI)
			LogMessage("[%s]         No tier 1 equivalent, no need to proceed", WI_MODULE_NAME);
			LogMessage("[%s]     }", WI_MODULE_NAME);
		#endif

		return;
	}

	//------------------------------------------------
	// Check location
	//------------------------------------------------
	// Check the location of the weapon, to see if its
	//  within a saferoom

	bool bIsInSaferoom = false;
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fOrigin);

	// Within start safe room
	if (!Weapon_bReplaceTier2_All && IsVersus()) {
		if (GetVectorDistance(Weapon_fMapOrigin_Start, fOrigin) > Weapon_fMapDist_StartExtra
			&& GetVectorDistance(Weapon_fMapOrigin_End, fOrigin) > Weapon_fMapDist_End
		) {
			#if (DEBUG_WI)
				LogMessage("[%s]         Weapon is outside of a saferoom", WI_MODULE_NAME);
			#endif

			if (!bSpawnerEvent) {
				#if (DEBUG_WI)
					LogMessage("[%s]     }", WI_MODULE_NAME);
				#endif
				return;
			}
		} else {
			#if (DEBUG_WI)
				LogMessage("[%s]         Weapon is inside a saferoom", WI_MODULE_NAME);
			#endif
			bIsInSaferoom = true;
		}
	}

	//------------------------------------------------
	// Check tier 2 replacement booleans
	//------------------------------------------------
	// Check and see if the plugin is set to replace
	//  tier 2 weapons
	// One for non-finale maps and one for finales

	if (!Weapon_bReplaceTier2_All) {
		if (!bSpawnerEvent) {
			if ((!Weapon_bReplaceTier2 && !L4D_IsMissionFinalMap()) || (!Weapon_bReplaceTier2_Finale && L4D_IsMissionFinalMap())) {
				#if (DEBUG_WI)
					LogMessage("[%s]         We do not want to replace weapons, IsMapFinale %b", WI_MODULE_NAME, L4D_IsMissionFinalMap());
					LogMessage("[%s]     }", WI_MODULE_NAME);
				#endif

				return;
			}
		} else {
			if ((!Weapon_bLimitTier2 && !bIsInSaferoom) || (!Weapon_bLimitTier2_Safehouse && bIsInSaferoom)) {
				#if (DEBUG_WI)
					LogMessage("[%s]         We do not want to replace weapons, bLimitTier2 %b, bLimitTier2_Saferoom %b, bIsInSaferoom %b", \
									WI_MODULE_NAME, Weapon_bLimitTier2, Weapon_bLimitTier2_Safehouse, bIsInSaferoom);
					LogMessage("[%s]     }", WI_MODULE_NAME);
				#endif

				return;
			}
		}
	}
#if (DEBUG_WI)
	else {
		LogMessage("[%s]         bReplaceTier2_All %b", WI_MODULE_NAME, Weapon_bReplaceTier2_All);
	}
#endif

	//------------------------------------------------
	// Replace tier 2 weapon
	//------------------------------------------------
	// And lastly after all these steps, this is where
	//  the magic happens
	// Replace the weapon with its tier 1 equivalent
	//  and update the model

	iWeaponIndex = Weapon_Attributes[iWeaponIndex][Tier1EquivalentIndex];
	SetEntProp(iEntity, Prop_Send, "m_weaponID", Weapon_Attributes[iWeaponIndex][WeaponID]);
	Format(sModelBuffer, sizeof(sModelBuffer), "%s%s%s", MODEL_PREFIX, Weapon_Models[iWeaponIndex], MODEL_SURFIX);
	SetEntityModel(iEntity, sModelBuffer);

#if (DEBUG_WI)
	LogMessage("[%s]         Replacing Tier 2, new WeaponID %i, model \"%s\"", WI_MODULE_NAME, Weapon_Attributes[iWeaponIndex][WeaponID], sModelBuffer);
	LogMessage("[%s]     }", WI_MODULE_NAME);
#endif
}

//================================================
// ReplaceExtra( iEntity, iWeaponIndex )
//================================================
// Takes care of handling extra entities,
//  killing, replacing, and updateing.

static void WI_ReplaceExtra(int iEntity, int iWeaponIndex)
{
#if (DEBUG_WI)
	LogMessage("[%s]     ReplaceExtra( iEntity %i, iWeaponIndex %i )", WI_MODULE_NAME, iEntity, iWeaponIndex);
	LogMessage("[%s]     {", WI_MODULE_NAME);
#endif

	//------------------------------------------------
	// Removal of extras
	//------------------------------------------------
	// Checks if the replacement index is equal to -1
	//  (WEAPON_REMOVE_INDEX)
	// If so, check the cvar boolean and kill the
	//  weapon, minus medkits as these needs special
	//  care

	if (Weapon_Attributes[iWeaponIndex][ReplacementIndex] == WEAPON_REMOVE_INDEX
		&& Weapon_bConvar[iWeaponIndex]
		&& iWeaponIndex != WEAPON_FIRST_AID_KIT_INDEX
	) {
		KillEntity(iEntity);

		#if (DEBUG_WI)
			LogMessage("[%s]         Killing weapon as requested...", WI_MODULE_NAME);
			LogMessage("[%s]     }", WI_MODULE_NAME);
		#endif

		return;
	}

	//------------------------------------------------
	// Check entity
	//------------------------------------------------
	// Stop removing extra items that are protected
	// (medkits converted to pain pills)
	for (int Index = 0; Index < WEAPON_NUMBER_OF_START_KITS; Index++) {
		if (Weapon_iKitEntity[Index] == iEntity) {
			#if (DEBUG_WI)
				LogMessage("[%s]         Start kit found, save entity", WI_MODULE_NAME);
				LogMessage("[%s]     }", WI_MODULE_NAME);
			#endif

			return;
		}
	}

	//------------------------------------------------
	// Check location
	//------------------------------------------------
	// If the item is within the end safe room and its
	//  not finale
	// OR
	// If the items is within start safe room, and it
	//  is not a first aid kit
	// Remove the item
	float fOrigin[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fOrigin);

	bool bIsInStartSaferoom = false, bIsInStartSaferoomExtra = false;
	bool bIsInEndSaferoom = false, bIsInFinaleArea = false;

	float fStartDistance = GetVectorDistance(Weapon_fMapOrigin_Start, fOrigin);

	if (fStartDistance <= Weapon_fMapDist_Start) {
		bIsInStartSaferoom = true;
		bIsInStartSaferoomExtra = true;
	} else if (fStartDistance <= Weapon_fMapDist_StartExtra) {
		bIsInStartSaferoomExtra = true;
	} else if (GetVectorDistance(Weapon_fMapOrigin_End, fOrigin) <= Weapon_fMapDist_End) {
		if (L4D_IsMissionFinalMap()) {
			bIsInFinaleArea = true;
		} else {
			bIsInEndSaferoom = true;
		}
	}

	if (Weapon_bRemoveExtraItems &&
		(bIsInEndSaferoom || (bIsInStartSaferoomExtra && iWeaponIndex != WEAPON_FIRST_AID_KIT_INDEX))
	) {
		KillEntity(iEntity);

		#if (DEBUG_WI)
			LogMessage("[%s]         Extra item is within a safe room, killing...", WI_MODULE_NAME);
			LogMessage("[%s]     }", WI_MODULE_NAME);
		#endif

		return;
	}

	//------------------------------------------------
	// Check for medkit
	//------------------------------------------------
	// No need to go on if it is not a medkit

	if (iWeaponIndex != WEAPON_FIRST_AID_KIT_INDEX) {
		#if (DEBUG_WI)
			LogMessage("[%s]         Not a medkit and not inside any saferoom, no need to go on", WI_MODULE_NAME);
			LogMessage("[%s]     }", WI_MODULE_NAME);
		#endif

		return;
	}

	//------------------------------------------------
	// Check location of medkit
	//------------------------------------------------
	// If its outside the start safe room we assume
	// it is a static medkit and it needs removal

	if (Weapon_bConvar[iWeaponIndex] && !bIsInStartSaferoom && !bIsInFinaleArea) {
		KillEntity(iEntity);

		#if (DEBUG_WI)
			LogMessage("[%s]         Static medkit outside saferoom and finale, killing...", WI_MODULE_NAME);
			LogMessage("[%s]     }", WI_MODULE_NAME);
		#endif

		return;
	}

	if (Weapon_iKitCount >= WEAPON_NUMBER_OF_START_KITS && bIsInStartSaferoom) {
		KillEntity(iEntity);

		#if (DEBUG_WI)
			LogMessage("[%s]         More than 4 saferoom medkits found, killing entity...", WI_MODULE_NAME);
			LogMessage("[%s]     }", WI_MODULE_NAME);
		#endif

		return;
	}

	float fRotation[3];
	char sSpawnBuffer[MAX_ENTITY_NAME_LENGTH];

	if (bIsInStartSaferoom && Weapon_bReplaceStartKits) {
		GetEntPropVector(iEntity, Prop_Send, "m_angRotation", fRotation);

		KillEntity(iEntity);

		Format(sSpawnBuffer, sizeof(sSpawnBuffer), "%s%s%s", SPAWN_PREFIX, Weapon_Spawns[WEAPON_PAIN_PILLS_INDEX], SPAWN_SURFIX);

		iEntity = CreateEntityByName(sSpawnBuffer);
		TeleportEntity(iEntity, fOrigin, fRotation, NULL_VECTOR);
		DispatchSpawn(iEntity);
		SetEntityMoveType(iEntity, MOVETYPE_NONE);

		#if (DEBUG_WI)
			LogMessage("[%s]         Replacing start medkit with pills", WI_MODULE_NAME);
		#endif
	} else if (bIsInFinaleArea && Weapon_bReplaceFinaleKits) {
		GetEntPropVector(iEntity, Prop_Send, "m_angRotation", fRotation);

		KillEntity(iEntity);

		Format(sSpawnBuffer, sizeof(sSpawnBuffer), "%s%s%s", SPAWN_PREFIX, Weapon_Spawns[WEAPON_PAIN_PILLS_INDEX], SPAWN_SURFIX);

		iEntity = CreateEntityByName(sSpawnBuffer);
		TeleportEntity(iEntity, fOrigin, fRotation, NULL_VECTOR);
		DispatchSpawn(iEntity);
		SetEntityMoveType(iEntity, MOVETYPE_NONE);

		#if (DEBUG_WI)
			LogMessage("[%s]         Replacing finale medkit with pills", WI_MODULE_NAME);
		#endif
	}

	if (bIsInStartSaferoom) {
		Weapon_iKitEntity[Weapon_iKitCount++] = iEntity;

		#if (DEBUG_WI)
			LogMessage("[%s]         Start medkit added to array", WI_MODULE_NAME);
			LogMessage("[%s]     }", WI_MODULE_NAME);
		#endif
	}
}

//================================================
// PrecacheModels
//================================================
// Loops through all the models and precache the
//  ones we need
static void WI_PrecacheModels()
{
	char ModelBuffer[PLATFORM_MAX_PATH];
	for (int index = FIRST_WEAPON; index <= LAST_WEAPON; index++) {
		if (strlen(Weapon_Models[index]) == 0) {
			continue;
		}

		Format(ModelBuffer, sizeof(ModelBuffer), "%s%s%s", MODEL_PREFIX, Weapon_Models[index], MODEL_SURFIX);

		if (IsModelPrecached(ModelBuffer)) {
			continue;
		}

		PrecacheModel(ModelBuffer);

		#if (DEBUG_WI)
			LogMessage("[%s] Model precached: %s", WI_MODULE_NAME, ModelBuffer);
		#endif
	}
}

//================================================
// GetMapInfo
//================================================
// Updates the global map variables if needed
static void WI_GetMapInfo()
{
	if (!Weapon_bUpdateMapInfo/* || !FindMapId() */) {
		return;
	}

	Weapon_fMapOrigin_Start[0] = GetMapStartOriginX();
	Weapon_fMapOrigin_Start[1] = GetMapStartOriginY();
	Weapon_fMapOrigin_Start[2] = GetMapStartOriginZ();
	Weapon_fMapOrigin_End[0] = GetMapEndOriginX();
	Weapon_fMapOrigin_End[1] = GetMapEndOriginY();
	Weapon_fMapOrigin_End[2] = GetMapEndOriginZ();
	Weapon_fMapDist_Start = GetMapStartDist();
	Weapon_fMapDist_StartExtra = GetMapStartExtraDist();
	Weapon_fMapDist_End = GetMapEndDist();

	Weapon_bUpdateMapInfo = false;
}

static void WI_RoundStart_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	CreateTimer(0.3, WI_RoundStartLoop, _, TIMER_FLAG_NO_MAPCHANGE);
}

static void WI_RoundEnd_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Weapon_bUpdateMapInfo = true;
}

static Action WI_RoundStartLoop(Handle hTimer)
{
	if (!IsPluginEnabled()) {
		return Plugin_Stop;
	}

	WI_GetMapInfo();

	if (Weapon_bUpdateMapInfo) {
		return Plugin_Stop;
	}

	WI_PrecacheModels();

#if (DEBUG_WI)
	LogMessage("[%s] Round Start Loop( )", WI_MODULE_NAME);
	LogMessage("[%s] {", WI_MODULE_NAME);
#endif

	for (int KitIndex = 0; KitIndex < WEAPON_NUMBER_OF_START_KITS; KitIndex++) {
		Weapon_iKitEntity[KitIndex] = 0;
	}

	Weapon_iKitCount = 0;

	char entclass[MAX_ENTITY_NAME_LENGTH];
	int iEntity, iWeaponIndex, entcount = GetEntityCount();

	for (iEntity = (MaxClients + 1); iEntity <= entcount; iEntity++) {
		if (!IsValidEdict(iEntity)) {
			continue;
		}

		GetEdictClassname(iEntity, entclass, sizeof(entclass));

		iWeaponIndex = WI_GetWeaponIndex(iEntity, entclass);
		if (iWeaponIndex != WEAPON_NULL_INDEX) {
			if (iWeaponIndex <= LAST_WEAPON) {
				WI_ReplaceWeapon(iEntity, iWeaponIndex);
			} else {
				WI_ReplaceExtra(iEntity, iWeaponIndex);
			}
		}

		if (Weapon_bRemoveLaserSight && StrContains(entclass, "upgrade_laser_sight") != -1) {
			KillEntity(iEntity);

			#if (DEBUG_WI)
				LogMessage("[%s] Killing laser sight...", WI_MODULE_NAME);
			#endif

			continue;
		}
	}

#if (DEBUG_WI)
	LogMessage("[%s]     Round Start Loop End", WI_MODULE_NAME);
	LogMessage("[%s] }", WI_MODULE_NAME);
#endif

	return Plugin_Stop;
}

static void WI_SpawnerGiveItem_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!IsPluginEnabled()) {
		return;
	}

	int iEntity = hEvent.GetInt("spawner");

	char sEntityClassName[MAX_ENTITY_NAME_LENGTH];
	GetEdictClassname(iEntity, sEntityClassName, sizeof(sEntityClassName));

	int iWeaponIndex = WI_GetWeaponIndex(iEntity, sEntityClassName);
	if (iWeaponIndex == WEAPON_NULL_INDEX) {
		return;
	}

	WI_ReplaceWeapon(iEntity, iWeaponIndex, true);
}
