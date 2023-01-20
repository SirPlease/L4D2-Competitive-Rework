#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <sdkhooks> //OnEntityCreated
#include <l4d2util_constants>

#define DEBUG						0

#define GAMEDATA_FILE				"l4d2_pistol_delay"
#define RATE_OF_FIRE_OFFSET_NAME	"CTerrorGun::GetRateOfFire"
#define IS_FULLY_AUTO_OFFSET_NAME	"CTerrorGun::IsFullyAutomatic" // funny

#define MIN_RATE_OF_FIRE			0.001
#define MAX_RATE_OF_FIRE			5.0

#define DEF_RITE_OF_FIRE_SINGLE		0.175
#define DEF_RITE_OF_FIRE_DUALIES	0.075	// Look at function 'CPistol::GetRateOfFire'
#define DEF_RITE_OF_FIRE_INCAP		0.3		// Equals cvar 'survivor_incapacitated_cycle_time'

bool
	g_bLateLoad = false;

float
	g_fPistolDelaySingle = DEF_RITE_OF_FIRE_SINGLE,
	//g_fPistolDelayIncap = DEF_RITE_OF_FIRE_INCAP,
	g_fPistolDelayDualies = DEF_RITE_OF_FIRE_DUALIES; // def value

DynamicHook
	g_hRateOfFire = null;

ConVar
	//g_hPistolDelayIncapped = null,
	g_hPistolDelayDualies = null,
	g_hPistolDelaySingle = null;

#if DEBUG
float
	g_fOldFireRate[MAXPLAYERS + 1][MAX_EDICTS];

DynamicHook
	g_hIsFullyAutomatic = null;

ConVar
	g_hAutomaticPistol = null;
#endif

public Plugin myinfo =
{
	name = "L4D2 pistol delay",
	author = "A1m`",
	version = "1.3",
	description = "Allows you to adjust the rate of fire of pistols (with a high tickrate, the rate of fire of dual pistols is very high).",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoad = bLate;

	return APLRes_Success;
}

public void OnPluginStart()
{
	InitGameData();

	// Value 'DEF_RITE_OF_FIRE_DUALIES' probably too low for a high tickrate
	g_hPistolDelayDualies = CreateConVar( \
		"l4d_pistol_delay_dualies", \
		"0.1", "Minimum time (in seconds) between dual pistol shots", \
		FCVAR_NOTIFY, \
		true, MIN_RATE_OF_FIRE, true, MAX_RATE_OF_FIRE \
	);

	char sDefValue[64];
	FloatToString(DEF_RITE_OF_FIRE_SINGLE, sDefValue, sizeof(sDefValue));

	g_hPistolDelaySingle = CreateConVar( \
		"l4d_pistol_delay_single", \
		sDefValue, \
		"Minimum time (in seconds) between single pistol shots", \
		FCVAR_NOTIFY,
		true, MIN_RATE_OF_FIRE, true, MAX_RATE_OF_FIRE \
	);

#if DEBUG
	// I think it's a good thing to check the delay
	// Causes visual bugs in the client
	g_hAutomaticPistol = CreateConVar( \
		"l4d_automatic_pistol", \
		"0", \
		"Can the pistol fire non-stop while you hold down the IN_ATTACK key", \
		FCVAR_NOTIFY,
		true, 0.0, true, 1.0 \
	);

	HookEvent("weapon_fire", Event_WeaponFire);
#endif

	//ConVar hCvarSurvivrIncapCycleTime = FindConVar("survivor_incapacitated_cycle_time");
	//hCvarSurvivrIncapCycleTime.GetDefault(sDefValue, sizeof(sDefValue));

	// I do not think that it is necessary depends on the cvar 'survivor_incapacitated_cycle_time'
	/*g_hPistolDelayIncapped = CreateConVar( \
		"l4d_pistol_delay_incapped", \
		sDefValue, \
		"Minimum time (in seconds) between pistol shots while incapped" \
		, FCVAR_NOTIFY, \
		true, MIN_RATE_OF_FIRE, true, MAX_RATE_OF_FIRE \
	);*/

	g_fPistolDelaySingle = ClampFloat(g_hPistolDelaySingle.FloatValue, MIN_RATE_OF_FIRE, MAX_RATE_OF_FIRE);
	g_fPistolDelayDualies = ClampFloat(g_hPistolDelayDualies.FloatValue, MIN_RATE_OF_FIRE, MAX_RATE_OF_FIRE);
	//g_fPistolDelayIncap = ClampFloat(g_hPistolDelayIncapped.FloatValue, MIN_RATE_OF_FIRE, MAX_RATE_OF_FIRE);

	g_hPistolDelayDualies.AddChangeHook(Cvars_Changed);
	g_hPistolDelaySingle.AddChangeHook(Cvars_Changed);
	//g_hPistolDelayIncapped.AddChangeHook(Cvars_Changed);

	LateLoad();
}

void InitGameData()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA_FILE);

	if (!hGamedata) {
		SetFailState("Gamedata '"... GAMEDATA_FILE ...".txt' missing or corrupt.");
	}

	int iGetRateOfFireOffset = GameConfGetOffset(hGamedata, RATE_OF_FIRE_OFFSET_NAME);
	if (iGetRateOfFireOffset == -1) {
		SetFailState("Failed to get offset '"... RATE_OF_FIRE_OFFSET_NAME ..."'.");
	}

#if DEBUG
	int iFullyAutomaticOffset = GameConfGetOffset(hGamedata, IS_FULLY_AUTO_OFFSET_NAME);
	if (iFullyAutomaticOffset == -1) {
		SetFailState("Failed to get offset '"... IS_FULLY_AUTO_OFFSET_NAME ..."'.");
	}

	g_hIsFullyAutomatic = new DynamicHook(iFullyAutomaticOffset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity);
#endif

	g_hRateOfFire = new DynamicHook(iGetRateOfFireOffset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity);

	delete hGamedata;
}

void LateLoad()
{
	if (!g_bLateLoad) {
		return;
	}

	int iEntity = INVALID_ENT_REFERENCE;

	while ((iEntity = FindEntityByClassname(iEntity, "weapon_pistol")) != INVALID_ENT_REFERENCE) {
		if (!IsValidEntity(iEntity)) {
			continue;
		}

		g_hRateOfFire.HookEntity(Hook_Pre, iEntity, CPistol_OnGetRiteOfFire);

		#if DEBUG
			g_hIsFullyAutomatic.HookEntity(Hook_Pre, iEntity, CPistol_OnFullyAutomatic);
		#endif
	}
}

void Cvars_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_fPistolDelaySingle = ClampFloat(g_hPistolDelaySingle.FloatValue, MIN_RATE_OF_FIRE, MAX_RATE_OF_FIRE);
	g_fPistolDelayDualies = ClampFloat(g_hPistolDelayDualies.FloatValue, MIN_RATE_OF_FIRE, MAX_RATE_OF_FIRE);
	//g_fPistolDelayIncap = ClampFloat(g_hPistolDelayIncapped.FloatValue, MIN_RATE_OF_FIRE, MAX_RATE_OF_FIRE);
}

public void OnEntityCreated(int iEntity, const char[] sEntityName)
{
	if (sEntityName[0] != 'w' || strcmp("weapon_pistol", sEntityName) != 0) {
		return;
	}

	g_hRateOfFire.HookEntity(Hook_Pre, iEntity, CPistol_OnGetRiteOfFire);

#if DEBUG
	PrintToChatAll("[OnEntityCreated] iEntity: %s (%d)", sEntityName, iEntity);

	g_hIsFullyAutomatic.HookEntity(Hook_Pre, iEntity, CPistol_OnFullyAutomatic);
#endif
}

MRESReturn CPistol_OnGetRiteOfFire(int iWeapon, DHookReturn hReturn)
{
	int iOwner = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwner");

	if (iOwner != -1 && IsIncapacitated(iOwner)) {
		//hReturn.Value = g_fPistolDelayIncap;
		//return MRES_Supercede;

		return MRES_Ignored;
	}

	if (GetEntProp(iWeapon, Prop_Send, "m_isDualWielding", 1) < 1) {
		hReturn.Value = (GetEntProp(iWeapon, Prop_Send, "m_iClip1") <= 0) ? 1.5 * g_fPistolDelaySingle : g_fPistolDelaySingle;

		return MRES_Supercede;
	}

	hReturn.Value = (GetEntProp(iWeapon, Prop_Send, "m_iClip1") <= 0) ? 0.2 : g_fPistolDelayDualies;

	return MRES_Supercede;
}

#if DEBUG
/*
	"weapon_fire"
	{
		"local"		"1"		// don't network this, its way too spammy
		"userid"	"short"
		"weapon"	"string"	// used weapon name
		"weaponid"	"short"		// used weapon ID
		"count"		"short"		// number of bullets
	}
*/

void Event_WeaponFire(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (hEvent.GetInt("weaponid") != WEPID_PISTOL) {
		return;
	}

	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iClient < 1 || GetClientTeam(iClient) != L4D2Team_Survivor) {
		return;
	}

	int iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (iActiveWeapon == -1) {
		return;
	}

	float fNow = GetGameTime();
	float fOldValue = g_fOldFireRate[iClient][iActiveWeapon];

	char sEntityName[ENTITY_MAX_NAME_LENGTH];
	GetEdictClassname(iActiveWeapon, sEntityName, sizeof(sEntityName));

	PrintToChat(iClient, "Weapon: %s (%d), old fire time: %f, current fire time: %f, Diff: %f", \
						sEntityName, iActiveWeapon, fOldValue, fNow, fNow - fOldValue);

	g_fOldFireRate[iClient][iActiveWeapon] = fNow;
}

MRESReturn CPistol_OnFullyAutomatic(int iWeapon, DHookReturn hReturn)
{
	hReturn.Value = g_hAutomaticPistol.BoolValue;

	return MRES_Supercede;
}
#endif

bool IsIncapacitated(int iClient)
{
	if (GetEntProp(iClient, Prop_Send, "m_lifeState") == LIFE_ALIVE) {
		return (GetEntProp(iClient, Prop_Send, "m_isIncapacitated", 1) > 0);
	}

	return false;
}

float ClampFloat(float inc, float low, float high)
{
	return (inc > high) ? high : ((inc < low) ? low : inc);
}

/* @A1m`:
 * Of course, the high tick rate has an effect on the rate of fire for all weapons, 
 * because the ItemPostFrame function is called more often, but this is not a bug.
 *
 * This becomes very noticeable when the rate of fire is too low, for example, dual pistols have a rate of fire of 0.075.
 * This code, or any other code that changes the delay of the shot,
 * may cause visual problems in the client,
 * because this code also exists in the client in the same form.
 * The best solution is to add a cvar with the FCVAR_REPLICATED flag in functions 'C_Pistol::GetRateOfFire' and 'CPistol::GetRateOfFire'.
 * This will allow us to change the value on the client and server at the same time, of course only for game developers ;D.
 *
 * sm_weapon_attributes weapon_pistol
 * Weapon stats for weapon_pistol:
 * 		Damage: 36.
 * 		Bullets: 1.
 * 		Clip Size: 15.
 * 		Max player speed: 250.00.
 * 		Spread per shot: 1.00.
 * 		Max spread: 30.00.
 * 		Spread decay: 5.00.
 * 		Min ducking spread: 0.50.
 * 		Min standing spread: 1.50.
 * 		Min in air spread: 3.00.
 * 		Max movement spread: 3.00.
 * 		Penetration num layers: 0.00.
 * 		Penetration power: 30.00.
 * 		Penetration max dist: 0.00.
 * 		Char penetration max dist: 0.00.
 * 		Range: 2500.00.
 * 		Range modifier: 0.75.
 * 		Cycle time: 0.17.
 * 		Pellet scatter pitch: 0.00.
 * 		Pellet scatter yaw: 0.00.

float CPistol::GetRateOfFire( )
{
	if ( !IsDualWielding() )
	{
		return BaseClass::GetRateOfFire(); //CTerrorGun::GetRateOfFire
	}

	CTerrorPlayer *pOwner = GetPlayerOwner();

	if ( pOwner && pOwner->IsIncapacitated() )
	{
		return BaseClass::GetRateOfFire(); //CTerrorGun::GetRateOfFire
	}

	return ( m_iClip1 <= 0 ) ? 0.2 : 0.075;
}

float CTerrorGun::GetRateOfFire()
{
	CTerrorPlayer *pOwner = GetPlayerOwner();

	if ( pOwner && pOwner->IsIncapacitated() )
	{
		return survivor_incapacitated_cycle_time.GetFloat();
	}

	if ( m_iClip1 <= 0 )
	{
		return 1.5 * GetCSWpnData().GetCycleTime(); //m_fCycleTime
	}

	return GetCSWpnData().GetCycleTime(); //m_fCycleTime
}

CTerrorPlayer *CTerrorWeapon::GetPlayerOwner()
{
	return ToTerrorPlayer( GetOwner() );
}

inline CTerrorPlayer *ToTerrorPlayer( CBaseEntity *pEntity )
{
	if ( !pEntity || !pEntity->IsPlayer() )
	{
		return NULL;
	}

#if _DEBUG
	Assert( static_cast< CTerrorPlayer* >( pEntity ) == dynamic_cast< CTerrorPlayer* >( pEntity ) );
#endif

	return static_cast<CTerrorPlayer *>( pEntity );
}

CBaseCombatCharacter *CBaseCombatWeapon::GetOwner() const
{
	return ToBaseCombatCharacter( m_hOwner.Get() );
}

inline CBaseCombatCharacter *ToBaseCombatCharacter( CBaseEntity *pEntity )
{
	if ( !pEntity )
	{
		return NULL;
	}

	return pEntity->MyCombatCharacterPointer();
}

bool CTerrorGun::IsDualWielding()
{
	return m_isDualWielding;
}

bool CTerrorPlayer::IsIncapacitated()
{
	if ( IsAlive() )
	{
		return m_isIncapacitated;
	}

	return false;
}

inline bool CBaseEntity::IsAlive( void )const
{
	return m_lifeState == LIFE_ALIVE;  //LIFE_ALIVE = 0
}
*/
