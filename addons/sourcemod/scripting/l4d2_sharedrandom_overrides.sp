/**
 * Plugin: Shared Random Pattern
 * Original author: A1m`
 * 
 * Description:
 *   Implements a configurable, non-random shotgun pellet pattern:
 *     - Custom rings
 *     - Radius factors
 *     - Hybrid spread (Maybe in the future)
 *   Replaces the old ASM patch method with a detour hook.
 *   Fixed the spread direction calculation: it now uses the full 0 – < 180 degree range, unlike the old ASM patch.
 *   The old ASM patch used a spread direction from -22° to ~154°, if the center pellet was activated, or from 0° to ~134° if not.
 *   Disable spread offset, up-down or left-right relative to the shot. This is not needed in static spread. The old assembler patch did not fix this. 
 *     Otherwise the shot will not be accurate. (Thanks Alan for the report).
 *
 * Credits:
 *   Jahze                         - Wrote the first ASM patch for static spread and wrote a plugin to customize this pattern `l4d2_static_shotgun_spread`,
 *                                   along with several related helper plugins for spread manipulation and testing.
 *   ProdigySim                    — Proposed replacing ASM patch with function hook `SharedRandomFloat` and offered the initial version of the plugin.
 *   ProdigySim, Visor, A1m`, Rena - Old plugin maintainers — maintained l4d2_static_shotgun_spread and old ASM patch.
 *   Alan                          - Provides feedback, tests the initial version of the plugin proposed by ProdigySim, and checks its functionality.
 * 
 * Notes:
 *   This plugin supports the old logic entirely and is aimed at further changing the spread pattern.
 *   The old method with ASM patch was difficult to understand, support, and was limited.
 * 
 * Research & Implementation:
 *   Test code has been written in C++; see the plugin below.
 *   A detailed analysis of the ASM patch from the file `code_patcher.txt` (gamedata file) was performed.
 *   Reverse engineering and analysis of the game code, function `CTerrorPlayer::FireBullets`and accompanying code
 *   Investigating the behavior of the `l4d2_static_shotgun_spread` plugin.
 *
 * Bugs & Todo:
 *   Fix: Large values of the 'sgspread_prediction_seed' cvar do not match the specified ones because the cvar value is stored as a float and breaks when retrieved due to rounding.
 *   Add: Gaussian distribution of the pattern.
 *   Improve: Remove the dynamic patch of the central pellet for an individual pattern for each shotgun.
 *   Fix: The saved seed is sometimes equal to INT_MAX (overflow?).
 *   Add: l4d1 support?
 *
 * The game stack trace look like this:
 *
 *   CTerrorGun::FireBullet
 *           │
 *           ▼
 *   SharedRandomFloat
 *           │
 *           ▼
 *   FireTerrorBullets
 *           │
 *           ▼
 *   CTerrorPlayer::FireBullet
 *           │
 *           ▼
 *   SharedRandomFloat
**/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <left4dhooks> //#include <left4downtown>
#include <sourcescramble>

#define DEBUG						0

#define GAMEDATA_FILE				"l4d2_sharedrandom_overrides"
#define DHOOK_SHAREDRANDFLOAT_NAME	"DH::SharedRandomFloat"
#define CTERRORGUN_FIREBULLET		"DH::CTerrorGun::FireBullet"
#define CENTER_PELLET_PATCH			"spread_center_pellet_patch"
#define SHAREDRANDFLOAT_NAME		"SharedRandomFloat"
#define CBASEENTITY_PREDICTIONSEED	"CBaseEntity::m_nPredictionRandomSeed"

// How many bits to use to encode an edict.
#define MAX_EDICT_BITS				11 // # of bits needed to represent max edicts
// Max # of edicts in a level
#define MAX_EDICTS					(1 << MAX_EDICT_BITS)

#define INT_MAX						0x7fffffff

enum /*eSpreadTypes*/
{
	eSGSDisable = 0,
	eSGSStaticRings,
	eSGSDynamicRings,
	eSGSVanillaConsistent,

	eSGSpread_Size
};

enum /*eSurvivorUpgradeType*/
{
	UPGRADE_INCENDIARY_AMMO = 0,
	UPGRADE_EXPLOSIVE_AMMO,
	UPGRADE_LASER_SIGHT
};

enum /*eFireBulletsInfo*/
{
	eiCurrentFireId = 0,
	eiTotalPellets,
	eiWeaponRef,
	eiWeaponOwnerRef,
	eiFrameCallNum,
	eiPredictionRandomSeedOld,

	eTotalSize
};

#if DEBUG
enum /*eDebugType*/
{
	eDataTypeNone = -1,
	efScatterOffset = 0,
	efAngleDeg,
	efHorizontalSpread,
	efVerticalSpread,

	eDebugDataSize
};

float
	g_fDebugDataStorage[eDebugDataSize] = {0.0, ...};

bool
	g_bDebugSetData[eDebugDataSize] = {false, ...};
#endif

int
	g_iCurrentFireID = 0,
	g_iSavedPredictionRandomSeed = -1,
	g_iFireBulletInfo[eTotalSize] = {0, ...};

Address
	g_iPredictionRandomSeedAddr = Address_Null;

MemoryPatch
	g_hCenterPelletPatch = null;

DynamicDetour
	g_hDetourTerrorGunFireBullet = null,
	g_hDetourSharedRandomFloat = null;

bool
	g_bCenterPelletPatchEnabled = false,
	g_bDetourHooksEnabled = false;

ConVar
	g_hCvarPatternType = null,
	g_hCvarRing1Pellets = null,
	g_hCvarRing1Factor = null,
	g_hCvarCenterPellet = null,
	g_hCvarRing1MaxOffsetPercent = null,
	g_hCvarRing2MaxOffsetPercent = null,
	g_hCvarAllPelletsSpreadOffset = null,
	g_hCvarPredictionSeed = null,
	g_hCvarPerfFireBulletSingle = null;

public Plugin myinfo =
{
	name        = "[L4D] Shared Random Pattern",
	author      = "A1m`",
	description = "Replaces random spread for shotgun pellets with configurable pattern (no ASM patch)",
	version     = "0.2.8",
	url         = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();

	g_hCvarPatternType = CreateConVar(
		"sgspread_pattern_type",
		"1",
		"Specifies the pattern type: \
		0 - disable(vanilla), \
		1 - static shotgun spread pattern, \
		2 - two-circle random deviation pattern (first circle: (Max spread / sgspread_ring1_factor) minus 'sgspread_ring1_offset', second circle: Max spread minus 'sgspread_ring2_offset'), \
		3 - repeatable vanilla spread.",
		_, true, float(eSGSDisable), true, float(eSGSpread_Size)
	);

	// sgspread_ring1_bullets old cvar name
	g_hCvarRing1Pellets = CreateConVar(
		"sgspread_ring1_pellets",
		"3",
		"Number of pellets in the first ring, the remaining pellets will go to the second ring.",
		_, true, 0.0
	);

	g_hCvarRing1Factor = CreateConVar(
		"sgspread_ring1_factor",
		"2",
		"Determines how far pellets in the first ring are from the center (Max spread / factor).",
		_, true, 1.0
	);

	g_hCvarCenterPellet = CreateConVar(
		"sgspread_center_pellet",
		"1",
		"Center pellet: 0 - off, 1 - on (default game behavior).",
		_, true, 0.0, true, 1.0
	);

	g_hCvarRing1MaxOffsetPercent = CreateConVar(
		"sgspread_ring1_offset",
		"60.0",
		"Maximum random deviation for the first circle (in percent of its radius). Used in pattern type 2 ('eSGSDynamicRings').",
		_, true, 1.0, true, 100.0
	);

	g_hCvarRing2MaxOffsetPercent = CreateConVar(
		"sgspread_ring2_offset",
		"30.0",
		"Maximum random deviation for the second circle (in percent of its radius). Used in pattern type 2 ('eSGSDynamicRings').",
		_, true, 1.0, true, 100.0
	);

	g_hCvarAllPelletsSpreadOffset = CreateConVar(
		"sgspread_all_pellets_offset",
		"0",
		"Enable or disable spread offset (vertical/horizontal) relative to the shot. \
		If enabled, the entire pellet spread shifts slightly, reducing accuracy. \
		Typically not required for static spread.",
		_, true, 0.0, true, 1.0
	);

	// ConVar is stored as a float internally? So when setting a large number (1234567890),
	// it's rounded to the nearest representable float.
	g_hCvarPredictionSeed = CreateConVar(
		"sgspread_prediction_seed",
		"-1",
		"Set a fixed seed for predictable pellet spread. If set to -1, the plugin will remember any random value for shots. Used in pattern type 4 ('eSGSVanillaConsistent').",
		_, false, 0.0, true, float(INT_MAX)
	);

#if DEBUG
	RegConsoleCmd("sm_center_pellet_val", Cmd_CheckCenterPelletVal);
	RegConsoleCmd("sm_get_random_seed", Cmd_GetPredictionRandomSeed);
#endif

	RegAdminCmd("sm_reset_seed", Cmd_ResetSavedPredictionSeed, ADMFLAG_RCON);

	InitPlugin();
}

void InitPlugin()
{
	g_hCvarPerfFireBulletSingle = FindConVar("perf_fire_bullet_single");

	TogglePatch(!g_hCvarCenterPellet.BoolValue);
	ToggleDetourHooks(g_hCvarPatternType.IntValue > eSGSDisable);

	g_hCvarPatternType.AddChangeHook(Hook_OnPatternChanged);
	g_hCvarCenterPellet.AddChangeHook(Hook_OnCenterPelletChanged);
}

void InitGameData()
{
	GameData hGamedata = new GameData(GAMEDATA_FILE);
	if (hGamedata == null) {
		SetFailState("Missing gamedata '%s'", GAMEDATA_FILE);
	}

	g_hDetourSharedRandomFloat = DynamicDetour.FromConf(hGamedata, DHOOK_SHAREDRANDFLOAT_NAME);
	if (g_hDetourSharedRandomFloat == null) {
		SetFailState("Missing detour setup '%s'", DHOOK_SHAREDRANDFLOAT_NAME);
	}

	g_hDetourTerrorGunFireBullet = DynamicDetour.FromConf(hGamedata, CTERRORGUN_FIREBULLET);
	if (g_hDetourTerrorGunFireBullet == null) {
		SetFailState("Missing detour setup '%s'", CTERRORGUN_FIREBULLET);
	}

	g_hCenterPelletPatch = MemoryPatch.CreateFromConf(hGamedata, CENTER_PELLET_PATCH);
	if (g_hCenterPelletPatch == null || !g_hCenterPelletPatch.Validate()) {
		SetFailState("Failed to validate MemoryPatch '%s'", CENTER_PELLET_PATCH);
	}

	g_iPredictionRandomSeedAddr = GameConfGetAddress(hGamedata, CBASEENTITY_PREDICTIONSEED);
	if (g_iPredictionRandomSeedAddr == Address_Null) {
		SetFailState("Unable to get '%s' address", CBASEENTITY_PREDICTIONSEED);
	}

	delete hGamedata;
}

void Hook_OnPatternChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ToggleDetourHooks(hConVar.IntValue > eSGSDisable);
}

void Hook_OnCenterPelletChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	TogglePatch(!hConVar.BoolValue);
}

void TogglePatch(bool bPatchEnable, bool bDeleteHandles = false)
{
	if (g_hCenterPelletPatch == null) {
		SetFailState("Patch handle '%s' is null", CENTER_PELLET_PATCH);
		return;
	}

	if (bPatchEnable && !g_bCenterPelletPatchEnabled) {
		if (!g_hCenterPelletPatch.Enable()) {
			SetFailState("Failed to enable MemoryPatch '%s'", CENTER_PELLET_PATCH);
		}

		g_bCenterPelletPatchEnabled = true;
		return;
	}

	if (!bPatchEnable && g_bCenterPelletPatchEnabled) {
		g_hCenterPelletPatch.Disable(); // void

		g_bCenterPelletPatchEnabled = false;
	}

	if (!bPatchEnable && bDeleteHandles) {
		delete g_hCenterPelletPatch;
		g_hCenterPelletPatch = null;
	}
}

void ToggleDetourHooks(bool bDetourEnable, bool bDeleteHandles = false)
{
	if (g_hDetourSharedRandomFloat == null) {
		SetFailState("Detour handle '%s' is null", DHOOK_SHAREDRANDFLOAT_NAME);
		return;
	}

	if (bDetourEnable && !g_bDetourHooksEnabled) {
		if (!g_hDetourTerrorGunFireBullet.Enable(Hook_Pre, Handler_CTerrorGun__FireBullet_Pre)) {
			SetFailState("Failed to enable detour '%s'", CTERRORGUN_FIREBULLET);
		}

		if (!g_hDetourTerrorGunFireBullet.Enable(Hook_Post, Handler_CTerrorGun__FireBullet_Post)) {
			SetFailState("Failed to enable detour '%s'", CTERRORGUN_FIREBULLET);
		}

		if (!g_hDetourSharedRandomFloat.Enable(Hook_Pre, Handler_SharedRandomFloat_Pre)) {
			SetFailState("Failed to enable detour '%s'", DHOOK_SHAREDRANDFLOAT_NAME);
		}

		#if DEBUG
			if (!g_hDetourSharedRandomFloat.Enable(Hook_Post, Handler_SharedRandomFloat_Post)) {
				SetFailState("Failed to enable detour '%s'", DHOOK_SHAREDRANDFLOAT_NAME);
			}
		#endif

		ClearFireBulletsInfo();
		g_bDetourHooksEnabled = true;
		return;
	}

	if (!bDetourEnable && g_bDetourHooksEnabled) {
		if (!g_hDetourTerrorGunFireBullet.Disable(Hook_Pre, Handler_CTerrorGun__FireBullet_Pre)) {
			SetFailState("Failed to enable detour '%s'", CTERRORGUN_FIREBULLET);
		}

		if (!g_hDetourTerrorGunFireBullet.Disable(Hook_Post, Handler_CTerrorGun__FireBullet_Post)) {
			SetFailState("Failed to enable detour '%s'", CTERRORGUN_FIREBULLET);
		}

		if (!g_hDetourSharedRandomFloat.Disable(Hook_Pre, Handler_SharedRandomFloat_Pre)) {
			SetFailState("Failed to disable detour '%s'", DHOOK_SHAREDRANDFLOAT_NAME);
		}

		#if DEBUG
			if (!g_hDetourSharedRandomFloat.Disable(Hook_Post, Handler_SharedRandomFloat_Post)) {
				SetFailState("Failed to disable detour '%s'", DHOOK_SHAREDRANDFLOAT_NAME);
			}
		#endif

		ClearFireBulletsInfo();
		g_bDetourHooksEnabled = false;
	}

	if (!bDetourEnable && bDeleteHandles) {
		delete g_hDetourSharedRandomFloat;
		g_hDetourSharedRandomFloat = null;
	}
}

public void OnPluginEnd()
{
	g_hCvarPatternType.RemoveChangeHook(Hook_OnPatternChanged);
	g_hCvarCenterPellet.RemoveChangeHook(Hook_OnCenterPelletChanged);

	ToggleDetourHooks(false, true);
	TogglePatch(false, true);
}

// Pre-hook
// void CTerrorGun::FireBullet( void )
// We save additional information that is not in `SharedRandomFloat` function
MRESReturn Handler_CTerrorGun__FireBullet_Pre(int iThisWeapon)
{
	ClearFireBulletsInfo();

	char sWeaponName[32];
	GetEdictClassname(iThisWeapon, sWeaponName, sizeof(sWeaponName));

	g_iFireBulletInfo[eiTotalPellets] = GetTotalPellets(iThisWeapon, sWeaponName);
	g_iFireBulletInfo[eiWeaponRef] = EntIndexToEntRef(iThisWeapon);

	int iOwner = GetEntPropEnt(iThisWeapon, Prop_Send, "m_hOwner"); // CTerrorWeapon::GetPlayerOwner()
	if (iOwner > 0 && iOwner <= MaxClients) { // Replacement for CBasePlayer::IsPlayer check
		g_iFireBulletInfo[eiWeaponOwnerRef] = EntIndexToEntRef(iOwner);
	}

	IncrementFireId();
	g_iFireBulletInfo[eiCurrentFireId] = g_iCurrentFireID;
	g_iFireBulletInfo[eiFrameCallNum] = GetGameTickCount();

	TryOverrideRandomSeed();

#if DEBUG
	// CTerrorWeaponInfo::m_fPelletScatterYaw, offset 3120
	g_fDebugDataStorage[efHorizontalSpread] = L4D2_GetFloatWeaponAttribute(sWeaponName, L4D2FWA_PelletScatterYaw);
	g_bDebugSetData[efHorizontalSpread] = true;

	// CTerrorWeaponInfo::m_fPelletScatterPitch, offset 3116
	g_fDebugDataStorage[efVerticalSpread] = L4D2_GetFloatWeaponAttribute(sWeaponName, L4D2FWA_PelletScatterPitch);
	g_bDebugSetData[efVerticalSpread] = true;

	PrintToChatAll("[CTerrorGun::FireBullet (Pre)] Weapon ref: %d", EntIndexToEntRef(iThisWeapon));
	ParseAdditionInfo();
#endif

	return MRES_Ignored;
}

// Post-hook
// void CTerrorGun::FireBullet( void )
// Clearing additional information
MRESReturn Handler_CTerrorGun__FireBullet_Post(int iThisWeapon)
{
	if (g_iFireBulletInfo[eiPredictionRandomSeedOld] != -1) {
		StoreToAddress(g_iPredictionRandomSeedAddr, g_iFireBulletInfo[eiPredictionRandomSeedOld], NumberType_Int32, false);
	}

	ClearFireBulletsInfo();

#if DEBUG
	PrintToChatAll("[CTerrorGun::FireBullet (Post)] Weapon ref: %d, frame: %d", EntIndexToEntRef(iThisWeapon), GetGameTickCount());
#endif

	return MRES_Ignored;
}

// Pre-hook
// float SharedRandomFloat( const char *sharedname, float flMinVal, float flMaxVal, int additionalSeed /*=0*/ )
// Our code only works if CTerrorWeaponInfo::m_fPelletScatterYaw offset 3120 (flHorizontalSpread) is greater than zero,
// and the code only works for the 2nd pellet if the central pellet is not activated with the patch,
// because the function is called only in this case,
// with parameters "CTerrorPlayer::FireBullet Spread" or "CTerrorPlayer::FireBullet SpreadDir".
MRESReturn Handler_SharedRandomFloat_Pre(DHookReturn hReturn, DHookParam hParams)
{
	// Check if additional information is received, our code works,
	// otherwise our spread pattern will be incorrect.
	if (!ShouldOverrideSharedRandom()) {
		return MRES_Ignored;
	}

	char sSharedName[128];
	hParams.GetString(1, sSharedName, sizeof(sSharedName));

	float flMin = hParams.Get(2);
	float flMax = hParams.Get(3);
	int iAdditionSeed = hParams.Get(4);

	float flOverrideValue = 0.0;
	MRESReturn iReturnOverride = OverrideSharedRandom(sSharedName, flMin, flMax, iAdditionSeed, g_iFireBulletInfo[eiTotalPellets], flOverrideValue);

	if (iReturnOverride != MRES_Ignored) {
		#if DEBUG
			PrintToChatAll("[OverrideSharedRandom] Name: %s, max: %.6f, seed: %d, total pellets: %d, override value: %.6f",
						sSharedName, flMax, iAdditionSeed, g_iFireBulletInfo[eiTotalPellets], flOverrideValue);
		#endif

		if (iReturnOverride == MRES_ChangedHandled) {
			//hParams.SetString(1, sSharedName);
			hParams.Set(2, flMin);
			hParams.Set(3, flMax);
			//hParams.Set(4, iAdditionSeed);
		} else {
			DHookSetReturn(hReturn, flOverrideValue);
		}

		return iReturnOverride;
	}

	return MRES_Ignored;
}

// Post-hook for logging, can be disabled in release
// float SharedRandomFloat( const char *sharedname, float flMinVal, float flMaxVal, int additionalSeed /*=0*/ )
#if DEBUG
MRESReturn Handler_SharedRandomFloat_Post(DHookReturn hReturn, DHookParam hParams)
{
	char sSharedName[128];
	hParams.GetString(1, sSharedName, sizeof(sSharedName));

	float flMin = hParams.Get(2);
	float flMax = hParams.Get(3);
	int iAdditionSeed = hParams.Get(4);

	float flReturned = hReturn.Value;

	CalculatePoints(sSharedName, flReturned, iAdditionSeed);
	int iPredictionRandomSeedNow = LoadFromAddress(g_iPredictionRandomSeedAddr, NumberType_Int32);
	PrintToChatAll("[SharedRandomFloat (Post)] Name: %s, Min: %.6f, Max: %.6f, Additional Seed: %d, Seed: %d, Return: %.6f",
						sSharedName, flMin, flMax, iAdditionSeed, iPredictionRandomSeedNow, flReturned);
	return MRES_Ignored;
}
#endif

MRESReturn OverrideSharedRandom(const char[] sSharedName, float &flMin, float &flMax, int iAdditionSeed, int iTotalPellets, float& flOverrideValue)
{
	if (strcmp(sSharedName, "CTerrorGun::FireBullet HorizSpread") == 0
		|| strcmp(sSharedName, "CTerrorGun::FireBullet VertSpread") == 0
	) {
		// Shotguns Only: Disable spread offset (vertical/horizontal) relative to the shot.
		// This is not needed in static spread.
		// The old assembler patch did not fix this.
		if (!g_hCvarAllPelletsSpreadOffset.BoolValue && iTotalPellets > 1 && flMax > 0.0) {
			flOverrideValue = 0.0;
			return MRES_Override;
		}

		return MRES_Ignored;
	}

	// Call original function with a constant seed.
	if (g_hCvarPatternType.IntValue == eSGSVanillaConsistent) {
		return MRES_Ignored;
	}

	int iPelletsInRing1 = g_hCvarRing1Pellets.IntValue + (g_hCvarCenterPellet.BoolValue ? 1 : 0);

	if (strcmp(sSharedName, "CTerrorPlayer::FireBullet Spread") == 0) {
		if (g_hCvarPatternType.IntValue == eSGSStaticRings) {
			if (iAdditionSeed > iPelletsInRing1) {
				// Ring 2 (full spread)
				// flHorizontalSpread == flMax, look at the comments below the plugin to see where this came from.
				flOverrideValue = flMax;
				return MRES_Override;
			}

			// Ring 1 (reduced spread)
			// flHorizontalSpread == flMax
			flOverrideValue = (flMax / g_hCvarRing1Factor.FloatValue);
			return MRES_Override;
		}

		// eSGSDynamicRings
		if (iAdditionSeed > iPelletsInRing1) {
			// Ring 2 - random radius from flMax, minus configurable offset (g_hCvarRing2MaxOffsetPercent).
			float fOffsetPercent = flMax * (g_hCvarRing2MaxOffsetPercent.FloatValue / 100.0);

			flMin = flMax - fOffsetPercent;
			flMax = flMax;

			return MRES_ChangedHandled; // The function will return a random value itself
		}

		// Ring 1 - random radius from (flMax / ring factor) minus configurable offset (g_hCvarRing1MaxOffsetPercent).
		float fRingFactor = flMax / g_hCvarRing1Factor.FloatValue;
		float fOffsetPercent = fRingFactor * (g_hCvarRing1MaxOffsetPercent.FloatValue / 100.0);

		flMin = fRingFactor - fOffsetPercent;
		flMax = fRingFactor;

		return MRES_ChangedHandled; // The function will return a random value itself.
	}

	if (strcmp(sSharedName, "CTerrorPlayer::FireBullet SpreadDir") == 0) {
		if (iAdditionSeed > iPelletsInRing1) {
			// Ring 2
			//
			// In fact, `iRemainingShots` doesn't exist, it's all optimization on Linux, it doesn't exist on Windows,
			// it all comes down to using iTotalPellets.
			//
			// We don't have access to this thing `iRemainingShots` (linux only?).
			// We now count the number of pellets in the second ring differently
			//
			// Old formula from `l4d2_static_shotgun_spread` (linux only?):
			//    int iPelletsInRing1 = g_hCvarRing1Pellets.IntValue + (1 - !g_hCvarCenterPellet.BoolValue);
			//    int iPelletsCount2 = g_hCvarRing1Pellets.IntValue + (2 - !g_hCvarCenterPellet.BoolValue); 
			//    flOverrideValue = (180.0f / float(iRemainingShots + iAdditionSeed - iPelletsInRing1) * float(iAdditionSeed - iPelletsCount2));
			//
			// New formula, now we use total pellets var.
			// FirstSeed = 1 if center pellet enabled; FirstSeed = 2 if not (to shift the indexing).
			//
			// Center pellet disabled
			//    int iPelletsInRing = iTotalPellets - g_hCvarRing1Pellets.IntValue;
			//    int iIndexInRing = iAdditionSeed - g_hCvarRing1Pellets.IntValue + 1;
			//    flOverrideValue = (180.0f / float(iPelletsInRing) * float(iIndexInRing));
			//
			// Center pellet enabled
			//    int iPelletsInRing = iTotalPellets - g_hCvarRing1Pellets.IntValue + 1; // + 1 for center pellet
			//    int iIndexInRing = iAdditionSeed - g_hCvarRing1Pellets.IntValue + 2;
			//    flOverrideValue = (180.0f / float(iPelletsInRing) * float(iIndexInRing));

			int iPelletsInRing2 = iTotalPellets - iPelletsInRing1;
			int iFirstSeed = (g_hCvarCenterPellet.BoolValue) ? 2 : 1; // We add the pellet offset due to the seed
			int iIndexInRing = iAdditionSeed - (g_hCvarRing1Pellets.IntValue + iFirstSeed);
			float fAngleStep = 180.0 / float(iPelletsInRing2);

			flOverrideValue = (fAngleStep * float(iIndexInRing));
			return MRES_Override;
		}

		// Ring 1:
		//
		// Old formula from `l4d2_static_shotgun_spread` for linux (degree patch), for windows (360 / pellets):
		//   float flDegree = 360.0f / (2.0f * float(g_hCvarRing1Pellets.IntValue));
		//   flOverrideValue = (flDegree * float(iAdditionSeed - 2));
		// 
		// New formula, we use an angle from 0 to < 180 degrees, the old ASM patch created a negative angle.
		// FirstSeed = 1 if center pellet enabled; FirstSeed = 2 if not (to shift the indexing).
		//
		// Center pellet disabled
		//    flOverrideValue = (180.0f / float(g_hCvarRing1Pellets.IntValue) * float(iAdditionSeed - 2));
		//
		// Center pellet enabled
		//    flOverrideValue = (180.0f / float(g_hCvarRing1Pellets.IntValue) * float(iAdditionSeed - 1));

		int iFirstSeed = (g_hCvarCenterPellet.BoolValue) ? 2 : 1;
		int iIndexInRing = iAdditionSeed - iFirstSeed;
		float fAngleStep = 180.0 / float(g_hCvarRing1Pellets.IntValue);

		flOverrideValue = (fAngleStep * float(iIndexInRing));
		return MRES_Override;
	}

	return MRES_Ignored;
}

bool ShouldOverrideSharedRandom()
{
	if (g_iFireBulletInfo[eiWeaponRef] == INVALID_ENT_REFERENCE) {
		return false;
	}

	int iWeapon = EntRefToEntIndex(g_iFireBulletInfo[eiWeaponRef]);
	if (iWeapon == INVALID_ENT_REFERENCE) {
		return false;
	}

	// Check if additional data was saved in another call, i.e. the data is outdated
	// I don't think it's necessary, but the checks are too simple and don't affect performance,
	// so I'll leave it, because if we get the wrong data, our spread pattern will be wrong.
	// The asm patch took the data directly, but we can't do that inside function `SharedRandomFloat`
	if (g_iFireBulletInfo[eiFrameCallNum] != GetGameTickCount() || g_iFireBulletInfo[eiCurrentFireId] != g_iCurrentFireID) {
		return false;
	}

	return true;
}

void IncrementFireId()
{
	// int overflow check
	if (g_iCurrentFireID > 1000000) {
		g_iCurrentFireID = 0;
	}

	g_iCurrentFireID++;
}

int GetTotalPellets(int iWeapon, const char[] sWeaponName)
{
	// From game function `CTerrorPlayer::FireBullet`
	int iWeaponInfoPellets = L4D2_GetIntWeaponAttribute(sWeaponName, L4D2IWA_Bullets);

	int iTotalPellets = iWeaponInfoPellets;
	int iBulletsPerFire = g_hCvarPerfFireBulletSingle.IntValue;
	if (iBulletsPerFire == 1) {
		iTotalPellets = 1;
	} else if (iBulletsPerFire > 1) {
		iTotalPellets = iWeaponInfoPellets * iBulletsPerFire;
	}

	// In the game, this is not a simple variable, it is a CBitVec<3> m_upgradeBitVec
	if (HasEntProp(iWeapon, Prop_Send, "m_upgradeBitVec")) {
		if (GetEntProp(iWeapon, Prop_Send, "m_upgradeBitVec") & (1 << UPGRADE_EXPLOSIVE_AMMO)) {
			iTotalPellets = 1;
		}
	}

	return iTotalPellets;
}

void TryOverrideRandomSeed()
{
	if (g_hCvarPatternType.IntValue != eSGSVanillaConsistent) {
		return;
	}

	int iPredictionRandomSeedNow = LoadFromAddress(g_iPredictionRandomSeedAddr, NumberType_Int32) & INT_MAX;

	if (g_hCvarPredictionSeed.IntValue != -1) {
		g_iSavedPredictionRandomSeed = -1;

		g_iFireBulletInfo[eiPredictionRandomSeedOld] = iPredictionRandomSeedNow;
		StoreToAddress(g_iPredictionRandomSeedAddr, g_hCvarPredictionSeed.IntValue & INT_MAX, NumberType_Int32, false);
		return;
	}

	if (g_iSavedPredictionRandomSeed == -1) {
		g_iSavedPredictionRandomSeed = iPredictionRandomSeedNow;
	} else {
		g_iFireBulletInfo[eiPredictionRandomSeedOld] = iPredictionRandomSeedNow;
		StoreToAddress(g_iPredictionRandomSeedAddr, g_iSavedPredictionRandomSeed & INT_MAX, NumberType_Int32, false);
	}
}

void ClearFireBulletsInfo()
{
	for (int i = 0; i < eTotalSize; i++) {
		g_iFireBulletInfo[i] = 0;
	}

	g_iFireBulletInfo[eiPredictionRandomSeedOld] = -1;
	g_iFireBulletInfo[eiWeaponRef] = INVALID_ENT_REFERENCE;
	g_iFireBulletInfo[eiWeaponOwnerRef] = INVALID_ENT_REFERENCE;

#if DEBUG
	ClearDebugData();
#endif
}

Action Cmd_ResetSavedPredictionSeed(int iClient, int iArgs)
{
	g_iSavedPredictionRandomSeed = -1;
	ReplyToCommand(iClient, "[SM] Reset saved prediction seed.");

	return Plugin_Handled;
}

stock int GenerateTimeSeed()
{
	float fEngineTime = GetEngineTime() * 1000.0;
	int iSeed = RoundToNearest(fEngineTime);
	return iSeed & INT_MAX;
}

#if DEBUG
void CalculatePoints(const char[] sSharedName, float fSetData, int iAdditionSeed)
{
	// From game function `CTerrorPlayer::FireBullet`
	//
	// This function is used to debug.
	// It collects the values ​​generated by the SharedRandomFloat function and outputs the results to the chat when both required values ​​are obtained:
	// ** efScatterOffset — random deviation of pellets from the center (scatter).
	// ** efAngleDeg — the direction of this deviation in degrees.

	if (strcmp(sSharedName, "CTerrorPlayer::FireBullet Spread") == 0) {
		g_bDebugSetData[efScatterOffset] = true;
		g_fDebugDataStorage[efScatterOffset] = fSetData;
	} else if (strcmp(sSharedName, "CTerrorPlayer::FireBullet SpreadDir") == 0) {
		g_bDebugSetData[efAngleDeg] = true;
		g_fDebugDataStorage[efAngleDeg] = fSetData;
	}

	if (!g_bDebugSetData[efScatterOffset] || !g_bDebugSetData[efAngleDeg]) {
		return;
	}

	if (!g_bDebugSetData[efHorizontalSpread] || !g_bDebugSetData[efVerticalSpread]) {
		return;
	}

	float fVerticalSpreadScale = 1.0;
	if (g_fDebugDataStorage[efHorizontalSpread] != 0.0 && g_fDebugDataStorage[efVerticalSpread] != 0.0) {
		fVerticalSpreadScale = g_fDebugDataStorage[efVerticalSpread] / g_fDebugDataStorage[efHorizontalSpread];
	}

	// Game code, variables have been changed to make the code easier to understand.
	//
	// g_fDebugDataStorage[efHorizontalSpread] = CTerrorWeaponInfo::m_fPelletScatterYaw, offset 3120
	// g_fDebugDataStorage[efVerticalSpread] = CTerrorWeaponInfo::m_fPelletScatterPitch, offset 3116
	//
	//g_fDebugDataStorage[efScatterOffset] = SharedRandomFloat("CTerrorPlayer::FireBullet Spread", -g_fDebugDataStorage[efHorizontalSpread], g_fDebugDataStorage[efHorizontalSpread], iAdditionSeed);
	//g_fDebugDataStorage[efAngleDeg] = SharedRandomFloat("CTerrorPlayer::FireBullet SpreadDir", 0.0, 180.0, iAdditionSeed);

	float fAngleRad = (g_fDebugDataStorage[efAngleDeg] * 2.0) * (FLOAT_PI / 180.0); // Scale to 2.0f and convert to radians
	float fOffsetX = (fVerticalSpreadScale * g_fDebugDataStorage[efScatterOffset]) * Sine(fAngleRad);
	float fOffsetY = g_fDebugDataStorage[efScatterOffset] * Cosine(fAngleRad);

	PrintToChatAll("%d) x: %f, y: %f", iAdditionSeed, fOffsetX, fOffsetY);

	g_bDebugSetData[efScatterOffset] = false;
	g_fDebugDataStorage[efScatterOffset] = 0.0;

	g_bDebugSetData[efAngleDeg] = false;
	g_fDebugDataStorage[efAngleDeg] = 0.0;
}

void ClearDebugData()
{
	for (int i = 0; i < eDebugDataSize; i++) {
		g_bDebugSetData[i] = false;
		g_fDebugDataStorage[i] = 0.0;
	}
}

void ParseAdditionInfo()
{
	char sWeaponName[64];
	int iWeaponIndex = GetEntityIndexAndName(g_iFireBulletInfo[eiWeaponRef], sWeaponName, sizeof(sWeaponName));

	char sOwnerName[64];
	int iOwnerIndex = GetEntityIndexAndName(g_iFireBulletInfo[eiWeaponOwnerRef], sOwnerName, sizeof(sOwnerName));

	PrintToChatAll("[Weapon Info] Ref: %d, index: %d, name %s", g_iFireBulletInfo[eiWeaponRef], iWeaponIndex, sWeaponName);
	PrintToChatAll("[Owner Info] Ref: %d, index: %d, name: %s", g_iFireBulletInfo[eiWeaponOwnerRef], iOwnerIndex, sOwnerName);
	PrintToChatAll("[Another Info] Total pellets: %d, frame: %d", g_iFireBulletInfo[eiTotalPellets], g_iFireBulletInfo[eiFrameCallNum]);
}

int GetEntityIndexAndName(int iRef, char[] sEntityName, int iMaxLength)
{
	FormatEx(sEntityName, iMaxLength, "Unknown");

	if (iRef == INVALID_ENT_REFERENCE) {
		return INVALID_ENT_REFERENCE;
	}

	int iIndex = EntRefToEntIndex(iRef);
	if (iIndex == INVALID_ENT_REFERENCE) {
		return INVALID_ENT_REFERENCE;
	}

	if (iIndex < 0 || iIndex > MAX_EDICTS) {
		return INVALID_ENT_REFERENCE;
	}

	if (iIndex >= 1 && iIndex <= MaxClients) {
		GetClientName(iIndex, sEntityName, iMaxLength);
	} else {
		GetEdictClassname(iIndex, sEntityName, iMaxLength);
	}

	return iIndex;
}

Action Cmd_CheckCenterPelletVal(int iClient, int iArgs)
{
	Address hPatchAggr = g_hCenterPelletPatch.Address;

	int iValue = LoadFromAddress(hPatchAggr + view_as<Address>(1), NumberType_Int8);
	ReplyToCommand(iClient, "[Debug] Center pellet: %s, patch value: %d.", (iValue == 0) ? "disable" : "enable", iValue);

	return Plugin_Handled;
}

Action Cmd_GetPredictionRandomSeed(int iClient, int iArgs)
{
	int iValue = LoadFromAddress(g_iPredictionRandomSeedAddr, NumberType_Int32);
	ReplyToCommand(iClient, "[Debug] %s: %d.", CBASEENTITY_PREDICTIONSEED, iValue);

	return Plugin_Handled;
}
#endif

#if 0
// C++ test code written by A1m`
//
// Can be run in any C++ compiler,
// you need to compare the points with the assembler patch and the function hook,
// changing the value of the `bUseOurAsmPatch` variable.
//
// Some settings have been changed.
// Command `sm_weapon_attributes shotgun_chrome` from `l4d2_weapon_attributes` plugin
/*
	Weapon stats for weapon_shotgun_chrome:
	Damage: 17.
	Pellets: 16.
	Clip Size: 8.
	Max player speed: 220.00.
	Spread per shot: 1.00.
	Max spread: 5.00.
	Spread decay: 5.00.
	Min ducking spread: 0.00.
	Min standing spread: 0.80.
	Min in air spread: 2.50.
	Max movement spread: 1.50.
	Penetration num layers: 0.00.
	Penetration power: 30.00.
	Penetration max dist: 500.00.
	Char penetration max dist: 300.00.
	Range: 3000.00.
	Range modifier: 0.69.
	Cycle time: 0.50.
	Pellet scatter pitch: 3.25.
	Pellet scatter yaw: 3.25.
*/
#include <iostream>
#include <cmath>
#include <iomanip> // setprecision, fixed
#include <cstring>

using namespace std;
float SharedRandomFloat(const char* sSharedName, float flMin, float flMax, int iAdditionSeed);

// Zonemod settings for chorme shotgun
int iTotalPellets = 16; // CTerrorWeaponInfo::m_iBullets, offset 2520 (Maybe m_iPellets?)
int iNumPelletsRing1 = 8; // Cvar `sgspread_ring1_pellets` from `l4d2_static_shotgun_spread` plugin
float flRing1Factor = 3.0f; // Cvar `sgspread_ring1_factor` from `l4d2_static_shotgun_spread` plugin
bool bCenterPellet = false; // Cvar `sgspread_center_pellet` from `l4d2_static_shotgun_spread` plugin
bool bUseOurAsmPatch = false; // Use asm or hook SharedRandomFloat with our code

float flHorizontalSpread = 3.25f; // default value, CTerrorWeaponInfo::m_fPelletScatterYaw, offset 3120
float flVerticalSpread = 3.25f; // default value, CTerrorWeaponInfo::m_fPelletScatterPitch, offset 3116

int main()
{
	// iAdditionSeed - `CTerrorPlayer::FireBullets` function arg
	//
	// We ignore start vector (vector[3] = {0.0f, 0.0f, 0.0f}),
	// it is also one of the arguments of the function
	//
	// We ignore the initial vector of the shot, 
	// we set it to zero, so it does not participate in our calculations, 
	// it is also one of the arguments of the function
	//
	// In fact, `iRemainingShots` doesn't exist, it's all optimization on Linux, it doesn't exist on Windows, 
	// it all comes down to using iTotalPellets.
	//
	// Init vars
	int iAdditionSeed = 0;
	float flAngleDeg = 0.0f;
	float flNewSpread = 0.0f;
	int iRemainingShots = iTotalPellets - 1;

	float flVerticalSpreadScale = 1.0f;
	if (flHorizontalSpread != 0.0f && flVerticalSpread != 0.0f) {
		// 3.25 / 3.25 = 1.0f for chrome anyway, omg
		flVerticalSpreadScale = flVerticalSpread / flHorizontalSpread;
	}

	if (iTotalPellets > 0) {
		for (int i = (bCenterPellet) ? 1 : 0; ; i = 0) { // `l4d2_static_shotgun_spread` center pellet (center pellet patch) in start loop
			++iAdditionSeed;

			if (flHorizontalSpread != 0.0f && i == 0) {
				if (bUseOurAsmPatch) {
					// Start our asm patch
					int iPelletsCountRing1 = iNumPelletsRing1 + (1 - !bCenterPellet); // `l4d2_static_shotgun_spread` formula
					
					if (iAdditionSeed > iPelletsCountRing1) { // `l4d2_static_shotgun_spread` pellet 0 offset (pellet0 patch)
						// Ring 2
						flNewSpread = flHorizontalSpread;
						
						// `l4d2_static_shotgun_spread` pellet 1 and pellet 2 offsets (pellet1, pellet2 patch) ↓
						int iPelletsCountRing12 = iNumPelletsRing1 + (2 - !bCenterPellet); // `l4d2_static_shotgun_spread` formula
						flAngleDeg = 180.0f / float(iRemainingShots + iAdditionSeed - iPelletsCountRing1) * float(iAdditionSeed - iPelletsCountRing12);
					} else {
						// Ring 1 
						float flDegree = 360.0f / (2.0f * float(iNumPelletsRing1)); // formula from `l4d2_static_shotgun_spread` for linux (degree patch), for windows (360 / pellets)
						
						flNewSpread = flHorizontalSpread / flRing1Factor; // `l4d2_static_shotgun_spread` factor (factor patch), for linux store int type, windows float type
						flAngleDeg = flDegree * float(iAdditionSeed - 2);
					}
					// End our asm patch
				} else {
					// Use hook SharedRandomFloat with our code
					// The goal is to get the same values as in the assembler patch
					flNewSpread = SharedRandomFloat("CTerrorPlayer::FireBullet Spread", -flHorizontalSpread, flHorizontalSpread, iAdditionSeed);
					flAngleDeg = SharedRandomFloat("CTerrorPlayer::FireBullet SpreadDir", 0.0f, 180.0f, iAdditionSeed);
				}

				float flAngleRad = (flAngleDeg * 2.0f) * (M_PI / 180.0f); // scale to 2.0f and convert to radians
				float flOffsetX = (flVerticalSpreadScale * flNewSpread) * sin(flAngleRad);
				float flOffsetY = flNewSpread * cos(flAngleRad);

				//cout << "flNewSpread: " << fixed << setprecision(6) << flNewSpread 
				//	<< ", flAngleDeg: " << fixed << setprecision(6) << flAngleDeg 
				//	<< ", flAngleRad: " << fixed << setprecision(6) << flAngleRad 
				//	<< endl;

				// You can draw the obtained result somewhere on the website, 
				// or, for example, ask to draw chatgpt
				cout << "x: " << fixed << setprecision(6) << flOffsetX 
					<< ", y: " << fixed << setprecision(6) << flOffsetY 
					<< endl;
			}
			
			if (iAdditionSeed == 1 && i == 1) {
				// Center pellet code
				float flOffsetX = 0.0f;
				float flOffsetY = 0.0f;
				cout << "x: " << fixed << setprecision(6) << flOffsetX
					<< ", y: " << fixed << setprecision(6) << flOffsetY
					<< endl;
			}
			
			if (iRemainingShots <= 0) {
				cout << "Total shots: "<< iAdditionSeed;
				break;
			}

			--iRemainingShots;
		}
	}

	return 0;
}

float SharedRandomFloat(const char* sSharedName, float flMin, float flMax, int iAdditionSeed)
{
	int iPelletsInRing1 = iNumPelletsRing1 + (bCenterPellet ? 1 : 0);

	if (strcmp(sSharedName, "CTerrorPlayer::FireBullet Spread") == 0) {
		if (iAdditionSeed > iPelletsInRing1) {
			// Ring 2 (full spread)
			// flHorizontalSpread == flMax
			return flMax;
		}

		// Ring 1 (reduced spread)
		// flHorizontalSpread == flMax
		return (flMax / flRing1Factor);
	}

	if (strcmp(sSharedName, "CTerrorPlayer::FireBullet SpreadDir") == 0) {
		if (iAdditionSeed > iPelletsInRing1) {
			// Ring 2
			//
			// In fact, `iRemainingShots` doesn't exist, it's all optimization on Linux, it doesn't exist on Windows,
			// it all comes down to using iTotalPellets.
			//
			// We don't have access to this thing `iRemainingShots` (linux only?).
			// We now count the number of pellets in the second ring differently
			//
			// Old formula from `l4d2_static_shotgun_spread` (linux only?):
			//    int iPelletsInRing1 = iNumPelletsRing1 + (1 - !bCenterPellet);
			//    int iPelletsCountRing12 = iNumPelletsRing1 + (2 - !bCenterPellet); 
			//    return (180.0f / float(iRemainingShots + iAdditionSeed - iPelletsInRing1) * float(iAdditionSeed - iPelletsCountRing12));
			//
			// New formula, now we use total pellets var.
			// FirstSeed = 1 if center pellet enabled; FirstSeed = 2 if not (to shift the indexing).
			//
			// Center pellet disabled
			//    int iPelletsInRing = iTotalPellets - iNumPelletsRing1;
			//    int iIndexInRing = iAdditionSeed - iNumPelletsRing1 + 1;
			//    return (180.0f / float(iPelletsInRing) * float(iIndexInRing));
			//
			// Center pellet enabled
			//    int iPelletsInRing = iTotalPellets - iNumPelletsRing1 + 1; // + 1 for center pellet
			//    int iIndexInRing = iAdditionSeed - iNumPelletsRing1 + 2;
			//    return (180.0f / float(iPelletsInRing) * float(iIndexInRing));

			int iPelletsInRing2 = iTotalPellets - iPelletsInRing1;
			int iFirstSeed = (bCenterPellet) ? 2 : 1; // We add the pellet offset due to the seed
			int iIndexInRing = iAdditionSeed - (iNumPelletsRing1 + iFirstSeed);
			float fAngleStep = 180.0f / float(iPelletsInRing2);

			return (fAngleStep * float(iIndexInRing));
		}

		// Ring 1:
		//
		// Old formula from `l4d2_static_shotgun_spread` for linux (degree patch), for windows (360 / pellets):
		//   float flDegree = 360.0f / (2.0f * float(iNumPelletsRing1));
		//   return (flDegree * float(iAdditionSeed - 2));
		// 
		// New formula, we use an angle from 0 to < 180 degrees, the old ASM patch created a negative angle.
		// FirstSeed = 1 if center pellet enabled; FirstSeed = 2 if not (to shift the indexing).
		//
		// Center pellet disabled
		//    return (180.0f / float(iNumPelletsRing1) * float(iAdditionSeed - 2));
		//
		// Center pellet enabled
		//    return (180.0f / float(iNumPelletsRing1) * float(iAdditionSeed - 1));
		
		int iFirstSeed = (bCenterPellet) ? 2 : 1;
		int iIndexInRing = iAdditionSeed - iFirstSeed;
		float fAngleStep = 180.0f / float(iNumPelletsRing1);

		return (fAngleStep * float(iIndexInRing));
	}

	return 0.0f; // The game returns a random value, but we return 0.0f
}
#endif
