/*
//-------------------------------------------------------------------------------------------------------------------
// Version 1: Prevents Survivors from picking up Players in the following situations:
//-------------------------------------------------------------------------------------------------------------------
// - Incapped Player is taking Spit Damage.
// - Players doing the pick-up gets hit by the Tank (Punch or Rock)
//
//-------------------------------------------------------------------------------------------------------------------
// Version 1.1: Prevents Survivors from switching from their current item to another without client requesting so:
//-------------------------------------------------------------------------------------------------------------------
// - Player no longer switches to pills when a teammate passes them pills through "M2".
// - Player picks up a Secondary Weapon while not on their Secondary Weapon. (Dual Pistol will force a switch though)
// - Added CVars for Pick-ups/Switching Item
//
//-------------------------------------------------------------------------------------------------------------------
// Version 1.2: Added Client-side Flags so that players can choose whether or not to make use of the Server's flags.
//-------------------------------------------------------------------------------------------------------------------
// - Welp, there's only one change.. so yeah. Enjoy!
//
//-------------------------------------------------------------------------------------------------------------------
// Version 2.0: Added way to detect Dual Pistol pick-up and block so.
//-------------------------------------------------------------------------------------------------------------------
// - Via hacky memory patch. 
//
//-------------------------------------------------------------------------------------------------------------------
// TODO:
//-------------------------------------------------------------------------------------------------------------------
// - Be a nice guy and less lazy, allow the plugin to work flawlessly with other's peoples needs.. It doesn't require much attention.
// - Find cleaner methods to detect and handle functions.
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
//#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util> //#include <weapons>
#include <colors>
#include <dhooks>
#include <sourcescramble>

#define FLAGS_SWITCH_MELEE                1
#define FLAGS_SWITCH_PILLS                2

#define FLAGS_INCAP_SPIT                  1
#define FLAGS_INCAP_TANKPUNCH             2
#define FLAGS_INCAP_TANKROCK              4

#define TEAM_SURVIVOR                     2
#define TEAM_INFECTED                     3

#define GAMEDATA_FILE "l4d2_pickup"
#define KEY_CTERRORGUN_USE "CTerrorGun_Use"
#define KEY_CTERRORGUN_USE_WINDOWS "CTerrorGun_Use_Windows"
#define KEY_CWEAPONSPAWN_USE "CWeaponSpawn::Use"
#define PATCH_STOPHOLSTER "EquipSecondWeapon_StopHolster"
#define PATCH_SETACTIVEWEAPON "EquipSecondWeapon_SetActiveWeapon"
#define PATCH_DEPLOY "EquipSecondWeapon_Deploy"

bool
	bLateLoad,
	bTanked[MAXPLAYERS + 1],
	bCantSwitchHealth[MAXPLAYERS + 1],
	bCantSwitchSecondary[MAXPLAYERS + 1],
	bPreventValveSwitch[MAXPLAYERS +1];
	
Handle
	hSecondary[MAXPLAYERS + 1],
	hHealth[MAXPLAYERS + 1],
	hTanked[MAXPLAYERS + 1],
	hValveSwitch[MAXPLAYERS + 1];

ConVar
	hSwitchFlags,
	hIncapPickupFlags;

int
	iSwitchFlags[MAXPLAYERS + 1],
	SwitchFlags,
	IncapFlags;

bool
	g_bLeft4Dead2,
	g_bLinux;

MemoryPatch
	g_hPatch_StopHolster,
	g_hPatch_SetActiveWeapon,
	g_hPatch_Deploy;

public Plugin myinfo = 
{
	name = "L4D2 Pick-up Changes",
	author = "Sir, Forgetest", //Update syntax A1m`
	description = "Alters a few things regarding picking up/giving items and incapped Players.",
	version = "2.0a",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead:
		{
			g_bLeft4Dead2 = false;
		}
		case Engine_Left4Dead2:
		{
			g_bLeft4Dead2 = true;
		}
		default:
		{
			strcopy(error, err_max, "Plugin supports only Left 4 Dead & 2");
			return APLRes_SilentFailure;
		}
	}
	bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadSDK();
	
	hSwitchFlags = CreateConVar("pickup_switch_flags", "3", "Flags for Switching from current item (1:Melee Weapons, 2: Passed Pills)", _, true, 0.0, true, 3.0);
	hIncapPickupFlags = CreateConVar("pickup_incap_flags", "7", "Flags for Stopping Pick-up progress on Incapped Survivors (1:Spit Damage, 2:TankPunch, 4:TankRock", _, true, 0.0, true, 7.0);
	
	SwitchFlags = hSwitchFlags.IntValue;
	IncapFlags = hIncapPickupFlags.IntValue;
	
	HookConVarChange(hSwitchFlags, CVarChanged);
	HookConVarChange(hIncapPickupFlags, CVarChanged);

	RegConsoleCmd("sm_secondary", ChangeSecondaryFlags);

	if (bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			HookValidClient(i, true);
		}
	}
}

void LoadSDK()
{
	Handle conf = LoadGameConfigFile(GAMEDATA_FILE);
	if (conf == null)
		SetFailState("Missing gamedata \"" ... GAMEDATA_FILE ..."\"");
	
	int offset = GameConfGetOffset(conf, "OS");
	if (offset == -1)
		SetFailState("Failed to find offset \"OS\"");
	
	g_bLinux = (offset == 1);
	
	SetupDetours(conf);
	
	g_hPatch_StopHolster = MemoryPatch.CreateFromConf(conf, PATCH_STOPHOLSTER);
	if (!g_hPatch_StopHolster || !g_hPatch_StopHolster.Validate())
		SetFailState("Failed to validate memory patch \"" ... PATCH_STOPHOLSTER ... "\"");
	
	g_hPatch_SetActiveWeapon = MemoryPatch.CreateFromConf(conf, PATCH_SETACTIVEWEAPON);
	if (!g_hPatch_SetActiveWeapon || !g_hPatch_SetActiveWeapon.Validate())
		SetFailState("Failed to validate memory patch \"" ... PATCH_SETACTIVEWEAPON ... "\"");
	
	g_hPatch_Deploy = MemoryPatch.CreateFromConf(conf, PATCH_DEPLOY);
	if (!g_hPatch_Deploy || !g_hPatch_Deploy.Validate())
		SetFailState("Failed to validate memory patch \"" ... PATCH_DEPLOY ... "\"");
	
	delete conf;
}

void SetupDetours(Handle conf)
{
	Handle hDetour = DHookCreateFromConf(
							conf,
							(g_bLeft4Dead2 || g_bLinux ? KEY_CTERRORGUN_USE : KEY_CTERRORGUN_USE_WINDOWS)
					);
	
	if (!hDetour)
		SetFailState("Failed to create setup detour for \"%s\"", (g_bLeft4Dead2 || g_bLinux ? KEY_CTERRORGUN_USE : KEY_CTERRORGUN_USE_WINDOWS));
	
	if (!DHookEnableDetour(hDetour, false, CTerrorGun_OnUse)
		|| !DHookEnableDetour(hDetour, true, CTerrorGun_OnUsePost)
	) {
		SetFailState("Failed to enable detour \"%s\"", (g_bLeft4Dead2 || g_bLinux ? KEY_CTERRORGUN_USE : KEY_CTERRORGUN_USE_WINDOWS));
	}
	
	hDetour = DHookCreateFromConf(conf, KEY_CWEAPONSPAWN_USE);
	
	if (!hDetour)
		SetFailState("Failed to create setup detour for \"" ... KEY_CWEAPONSPAWN_USE ... "\"");
	
	if (!DHookEnableDetour(hDetour, false, CWeaponSpawn_OnUse)
		|| !DHookEnableDetour(hDetour, true, CWeaponSpawn_OnUsePost)
	) {
		SetFailState("Failed to enable detour \"" ... KEY_CWEAPONSPAWN_USE ... "\"");
	}
}

void ApplyPatch(bool patch)
{
	static bool patched = false;
	if (patch && !patched)
	{
		if (!g_hPatch_StopHolster.Enable())
			SetFailState("Failed to enable memory patch \"" ... PATCH_STOPHOLSTER ... "\"");
		
		if (!g_hPatch_SetActiveWeapon.Enable())
			SetFailState("Failed to enable memory patch \"" ... PATCH_SETACTIVEWEAPON ... "\"");
		
		if (!g_hPatch_Deploy.Enable())
			SetFailState("Failed to enable memory patch \"" ... PATCH_DEPLOY ... "\"");
		
		patched = true;
	}
	else if (!patch && patched)
	{
		g_hPatch_StopHolster.Disable();
		g_hPatch_SetActiveWeapon.Disable();
		g_hPatch_Deploy.Disable();
		
		patched = false;
	}
}

/* ---------------------------------
//                                 |
//       Standard Client Stuff     |
//                                 |
// -------------------------------*/
public void OnClientPutInServer(int client)
{
	HookValidClient(client, true);
	if (iSwitchFlags[client] < 2) {
		iSwitchFlags[client] = SwitchFlags;
	}
}

public void OnClientDisconnect_Post(int client)
{
	KillActiveTimers(client);
	HookValidClient(client, false);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (bTanked[client]) {
		buttons &= ~IN_USE;
		if (hTanked[client] == null) {
			hTanked[client] = CreateTimer(0.2, DelayUse, client);
		}
	}
	return Plugin_Continue;
}

public Action ChangeSecondaryFlags(int client, int args)
{
	if (IsValidClient(client)) {
		if (iSwitchFlags[client] != 3) {
			iSwitchFlags[client] = 3;
			CPrintToChat(client, "{blue}[{default}ItemSwitch{blue}] {default}Switch to Melee on pick-up: {blue}OFF");
		} else {
			iSwitchFlags[client] = 2;
			CPrintToChat(client, "{blue}[{default}ItemSwitch{blue}] {default}Switch to Melee on pick-up: {blue}ON");
		}
	}
	return Plugin_Handled;
}


/* ---------------------------------
//                                 |
//       Yucky Timer Method~       |
//                                 |
// -------------------------------*/
public Action DelayUse(Handle hTimer, any client)
{
	bTanked[client] = false;
	hTanked[client] = null;
}

public Action DelaySwitchHealth(Handle hTimer, any client)
{
	bCantSwitchHealth[client] = false;
	hHealth[client] = null;
}

public Action DelaySwitchSecondary(Handle hTimer, any client)
{
	bCantSwitchSecondary[client] = false;
	hSecondary[client] = null;
}

public Action DelayValveSwitch(Handle hTimer, any client)
{
	bPreventValveSwitch[client] = false;
	hValveSwitch[client] = null;
}


/* ---------------------------------
//                                 |
//         SDK Hooks, Fun!         |
//                                 |
// -------------------------------*/
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidEdict(inflictor) || !IsPlayerSurvivor(victim)) {
		return Plugin_Continue;
	}
	
	// Spitter damaging player that's being picked up.
	// Read the damage input differently, forcing the pick-up to end with every damage tick. (NOTE: Bots still bypass this)
	if ((IncapFlags & FLAGS_INCAP_SPIT) && IsPlayerIncapacitated(victim))
	{
		char classname[64];
		GetEdictClassname(inflictor, classname, sizeof(classname));
		if (StrEqual(classname, "insect_swarm"))
		{
			damagetype = DMG_GENERIC;
			return Plugin_Changed;
		}
	}

	// Tank Rock or Punch.
	if (IsPlayerTank(attacker))
	{
		if (IsTankRock(inflictor)) {
			if (IncapFlags & FLAGS_INCAP_TANKROCK) {
				bTanked[victim] = true;
			}
		} else if (IncapFlags & FLAGS_INCAP_TANKPUNCH) {
			bTanked[victim] = true;
		}
	}
	
	return Plugin_Continue;
}

public Action WeaponCanSwitchTo(int client, int weapon)
{
	if (!IsValidEntity(weapon)) {
		return Plugin_Continue;
	}

	char sWeapon[64];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon)); 
	WeaponId wep = WeaponNameToId(sWeapon);

	// Health Items.
	if ((iSwitchFlags[client] & FLAGS_SWITCH_PILLS) && (wep == WEPID_PAIN_PILLS || wep == WEPID_ADRENALINE) && bCantSwitchHealth[client]) {
		return Plugin_Stop;
	}
	
	//Weapons.
	if ((iSwitchFlags[client] & FLAGS_SWITCH_MELEE) && (wep == WEPID_MELEE || wep == WEPID_PISTOL_MAGNUM || wep == WEPID_PISTOL) && bCantSwitchSecondary[client]) {
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action WeaponEquip(int client, int weapon)
{
	if (!IsValidEntity(weapon)) {
		return Plugin_Continue;
	}
	
	// Weapon Currently Using
	char weapon_name[64];
	GetClientWeapon(client, weapon_name, sizeof(weapon_name));
	WeaponId wepname = WeaponNameToId(weapon_name);

	// New Weapon
	char sWeapon[64]; 
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon)); 
	WeaponId wep = WeaponNameToId(sWeapon);

	// Health Items.
	if (wep == WEPID_PAIN_PILLS || wep == WEPID_ADRENALINE) {
		bCantSwitchHealth[client] = true;
		hHealth[client] = CreateTimer(0.1, DelaySwitchHealth, client);
	}
	// Also Check if Survivor is incapped to make sure no issues occur (Melee players get given a pistol for example)
	else if (!IsPlayerIncapacitated(client) && !bPreventValveSwitch[client]) {
		// New Weapon is a Secondary?
		if (wep == WEPID_MELEE || wep == WEPID_PISTOL_MAGNUM || wep == WEPID_PISTOL)
		{
			// Is Currently used Weapon a Secondary?
			if (wepname == WEPID_MELEE || wepname == WEPID_PISTOL || wepname == WEPID_PISTOL_MAGNUM) {
				return Plugin_Continue;
			}
			
			bCantSwitchSecondary[client] = true;
			hSecondary[client] = CreateTimer(0.1, DelaySwitchSecondary, client);
		}
	}
	return Plugin_Continue;
}

public Action WeaponDrop(int client, int weapon)
{
	if (!IsValidEntity(weapon)) {
		return Plugin_Continue;
	}
	// Weapon Currently Using
	char weapon_name[64];
	GetClientWeapon(client, weapon_name, sizeof(weapon_name));
	WeaponId wepname = WeaponNameToId(weapon_name);

	// Secondary Weapon
	//int Secondary = GetPlayerWeaponSlot(client, 1);

	// Weapon Dropping
	char sWeapon[64]; 
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon)); 
	WeaponId wep = WeaponNameToId(sWeapon);

	// Check if Player is Alive/Incapped and just dropped his secondary for a different one
	if (!IsPlayerIncapacitated(client) && IsPlayerAlive(client))  {
		// Annoying workaround to fix Dual Pistols.
		/*if (wep == WEPID_PISTOL && GetEntProp(Secondary, Prop_Send, "m_isDualWielding") && wepname != WEPID_MELEE && wepname != WEPID_PISTOL && wepname != WEPID_PISTOL_MAGNUM) {
			SetEntProp(Secondary, Prop_Send, "m_isDualWielding", 0);
			SDKHooks_DropWeapon(client, Secondary);
			SetEntProp(Secondary, Prop_Send, "m_isDualWielding", 1);
		} else */if ((wep == WEPID_MELEE || wep == WEPID_PISTOL || wep == WEPID_PISTOL_MAGNUM) && (wepname == WEPID_MELEE || wepname == WEPID_PISTOL || wepname == WEPID_PISTOL_MAGNUM)) {
			bPreventValveSwitch[client] = true;
			hValveSwitch[client] = CreateTimer(0.1, DelayValveSwitch, client);
		}
	}
	return Plugin_Continue;
}


/* ---------------------------------
//                                 |
//       Dualies Workaround        |
//                                 |
// -------------------------------*/
stock bool IsSwitchingToDualCase(int client, int weapon)
{
	if (!IsValidEdict(weapon))
		return false;
	
	static char clsname[64];
	if (!GetEdictClassname(weapon, clsname, sizeof clsname))
		return false;
	
	if (clsname[0] != 'w')
		return false;
	
	if (g_bLeft4Dead2 && strcmp(clsname[7], "spawn") == 0)
	{
		if (GetEntProp(weapon, Prop_Send, "m_weaponID") != 1) // WEPID_PISTOL
			return false;
	}
	else if (strncmp(clsname[7], "pistol", 6) != 0)
	{
		return false;
	}
	
	int secondary = GetPlayerWeaponSlot(client, 1);
	if (secondary == -1)
		return false;
	
	if (!GetEdictClassname(secondary, clsname, sizeof clsname))
		return false;
	
	return strcmp(clsname, "weapon_pistol") == 0 && !GetEntProp(secondary, Prop_Send, "m_hasDualWeapons");
}

public MRESReturn CTerrorGun_OnUse(int pThis, Handle hParams)
{
	int client = DHookGetParam(hParams, (g_bLeft4Dead2 || g_bLinux ? 1 : 2));
	
	if ((iSwitchFlags[client] & FLAGS_SWITCH_MELEE) && IsSwitchingToDualCase(client, pThis))
	{
		ApplyPatch(true);
	}
	
	return MRES_Ignored;
}

public MRESReturn CWeaponSpawn_OnUse(int pThis, Handle hParams)
{
	int client = DHookGetParam(hParams, 1);

	if ((iSwitchFlags[client] & FLAGS_SWITCH_MELEE) && IsSwitchingToDualCase(client, pThis))
	{
		ApplyPatch(true);
	}
	
	return MRES_Ignored;
}

public MRESReturn CTerrorGun_OnUsePost(Handle hParams)
{
	ApplyPatch(false);
}

public MRESReturn CWeaponSpawn_OnUsePost(Handle hParams)
{
	ApplyPatch(false);
}


/* ---------------------------------
//                                 |
//        Stocks, Functions        |
//                                 |
// -------------------------------*/
bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
} 

bool IsPlayerSurvivor(int client)
{
	return (IsValidClient(client) && GetClientTeam(client) == 2);
}

bool IsPlayerIncapacitated(int client)
{
	bool bIsIncapped = false;
	if (IsPlayerSurvivor(client)) {
		if (GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0) {
			bIsIncapped = true;
		}

		if (!IsPlayerAlive(client)) {
			bIsIncapped = true;
		}
	}
	return bIsIncapped;
}

bool IsPlayerTank(int client)
{
	return (IsValidClient(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

bool IsTankRock(int entity)
{
	if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity)) {
		char classname[64];
		GetEdictClassname(entity, classname, sizeof(classname));
		return (strcmp(classname, "tank_rock") == 0);
	}

	return false;
}

void KillActiveTimers(int client)
{
	if (hTanked[client] != null) {
		KillTimer(hTanked[client]);
		hTanked[client] = null;
	}
	
	if (hHealth[client] != null) {
		KillTimer(hHealth[client]);
		hHealth[client] = null;
	}
	
	if (hSecondary[client] != null) {
		KillTimer(hSecondary[client]);
		hSecondary[client] = null;
	}
	
	if (hValveSwitch[client] != null) {
		KillTimer(hValveSwitch[client]);
		hValveSwitch[client] = null;
	}
	
	hTanked[client] = null;
	hHealth[client] = null;
	hSecondary[client] = null;
	hValveSwitch[client] = null;
	bCantSwitchHealth[client] = false;
	bCantSwitchSecondary[client] = false;
	bPreventValveSwitch[client] = false;
	bTanked[client] = false;
	iSwitchFlags[client] = -1;
}

void HookValidClient(int client, bool Hook)
{
	if (IsValidClient(client)) {
		if (Hook) {
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(client, SDKHook_WeaponCanSwitchTo, WeaponCanSwitchTo);
			SDKHook(client, SDKHook_WeaponEquip, WeaponEquip);
			SDKHook(client, SDKHook_WeaponDrop, WeaponDrop);
		} else {
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(client, SDKHook_WeaponCanSwitchTo, WeaponCanSwitchTo);
			SDKUnhook(client, SDKHook_WeaponEquip, WeaponEquip);
			SDKUnhook(client, SDKHook_WeaponDrop, WeaponDrop);
		}
	}
}

/* ---------------------------------
//                                 |
//          Cvar Changes!          |
//                                 |
// -------------------------------*/
public void CVarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	IncapFlags = hIncapPickupFlags.IntValue;
	SwitchFlags = hSwitchFlags.IntValue;
}