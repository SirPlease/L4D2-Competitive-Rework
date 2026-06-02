/*
*	No Reload Animation Fix - Picking Up Same Weapon
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

#define PLUGIN_VERSION 		"1.8"



/**
 * No conflict with the following plugins:
 * Reserve (Ammo) Control: https://forums.alliedmods.net/showthread.php?t=334274
 * Weapons Skins RNG: https://forums.alliedmods.net/showthread.php?t=327609
 * Reload Fix - Max Clip Size: https://forums.alliedmods.net/showthread.php?t=327105
 * l4d2_weapon_csgo_reload: https://github.com/fbef0102/L4D2-Plugins/tree/master/l4d2_weapon_csgo_reload
*/



/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] No Reload Animation Fix
*	Author	:	SilverShot & HarryPotter
*	Descrp	:	Prevent filling the clip and skipping the reload animation when taking the same weapon.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=333100
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.8 (03-Apr-2024)
	- Fixed wrong weapons ammo when switch weapons. Thanks to "HarryPotter" for the update.

1.7 (12-Mar-2024)
	- Save all clients weapons ammo, useful if weapon ammo exceeded the official ammo cvar. Thanks to "HarryPotter" for the update.

1.6 (25-May-2023)
	- Added cvar "l4d2_reload_fix_give" to optionally prevent "give" command with same type of weapon setting to the previous weapons ammo.

1.5 (20-Aug-2022)
	- Records all weapons clip and ammo. Thanks to "HarryPotter" for writing.

1.4 (29-Mar-2022)
	- Fixed not always detecting the correct current weapon. Thanks to "Forgetest" for fixing.

1.3 (02-Nov-2021)
	- Fixed treating different weapon skins as the same weapon. Thanks to "tRololo312312" for reporting.

1.2 (06-Jul-2021)
	- Fixed throwing errors about invalid entity. Thanks to "HarryPotter" for reporting.

1.1 (27-Jun-2021)
	- Fixed throwing errors about invalid entity. Thanks to "HarryPotter" for reporting.

1.0 (19-Jun-2021)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS		FCVAR_NOTIFY
#define MAX_SKIN 		5

enum WeaponID
{
	ID_NONE,
	//ID_PISTOL,
	//ID_DUAL_PISTOL,
	ID_SMG,
	ID_PUMPSHOTGUN,
	ID_RIFLE,
	ID_AUTOSHOTGUN,
	ID_HUNTING_RIFLE,
	ID_SMG_SILENCED,
	ID_SMG_MP5,
	ID_CHROMESHOTGUN,
	//ID_MAGNUM,
	ID_AK47,
	ID_RIFLE_DESERT,
	ID_SNIPER_MILITARY,
	ID_GRENADE,
	ID_SG552,
	ID_M60,
	ID_AWP,
	ID_SCOUT,
	ID_SPASSHOTGUN,
	ID_WEAPON_MAX
}

int g_iClip[MAXPLAYERS + 1][view_as<int>(ID_WEAPON_MAX)][MAX_SKIN];
int g_iAmmo[MAXPLAYERS + 1][view_as<int>(ID_WEAPON_MAX)][MAX_SKIN];
bool g_bIgnored[MAXPLAYERS + 1];
StringMap g_hWeaponName;
int g_iOffsetAmmo;
int g_iPrimaryAmmoType;
bool g_bLateLoad;
ConVar g_hCvarGive;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] No Reload Animation Fix",
	author = "SilverShot, HarryPotter",
	description = "Prevent filling the clip and skipping the reload animation when taking the same weapon.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=333100"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;

	RegPluginLibrary("l4d2_reload_fix");

	return APLRes_Success;
}

public void OnPluginStart()
{
	// Lateload
	if( g_bLateLoad )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			ClearClientAmmo(i);
			if( IsClientInGame(i) )
			{
				SDKHook(i, SDKHook_WeaponCanUsePost, WeaponCanUse);
			}
		}
	}

	// Offsets to setting reserve ammo
	g_iOffsetAmmo = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	g_iPrimaryAmmoType = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");

	g_hCvarGive = CreateConVar("l4d2_reload_fix_give", "1", "When using the give command and replacing the same weapon type, transfer ammo to the new weapon. 0=No. 1=Yes.", CVAR_FLAGS);
	CreateConVar("l4d2_reload_fix_version", PLUGIN_VERSION, "No Reload Animation Fix plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarGive.AddChangeHook(ConVarChanged_Cvars);

	SetWeaponClassName();

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("weapon_drop", Event_Weapon_Drop);
}

public void OnConfigsExecuted()
{
	GetCvars();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	static bool hooked;
	bool setting = g_hCvarGive.BoolValue;

	if( hooked && setting )
	{
		RemoveCommandListener(CommandListener, "give");
		hooked = false;
	}
	else if( !hooked && !setting )
	{
		AddCommandListener(CommandListener, "give");
		hooked = true;
	}
}

Action CommandListener(int client, const char[] command, int args)
{
	g_bIgnored[client] = true;
	RequestFrame(OnFrameIgnore, client); // Don't need userid for this

	return Plugin_Continue;
}

void OnFrameIgnore(int client)
{
	g_bIgnored[client] = false;
}

public void OnClientPutInServer(int client)
{
	ClearClientAmmo(client);
	g_bIgnored[client] = false;
	SDKHook(client, SDKHook_WeaponCanUsePost, WeaponCanUse);
}

// Fix picking up weapons filling the clip
void WeaponCanUse(int client, int weapon)
{
	if( weapon == -1 ) return;
	if( g_bIgnored[client] ) return;

	//PrintToChatAll("%N WeaponCanUse", client);

	// Validate team
	if( GetClientTeam(client) == 2 )
	{
		// Validate weapon
		int current = GetPlayerWeaponSlot(client, 0);
		if( current != -1 )
		{
			static char sCurrent_ClassName[32];
			GetEntityClassname(current, sCurrent_ClassName, sizeof(sCurrent_ClassName));
			WeaponID current_weaponid = ID_NONE;
			if( !g_hWeaponName.GetValue(sCurrent_ClassName, current_weaponid) ) return;

			int current_skin = GetEntProp(current, Prop_Send, "m_nSkin");

			// Store clip size
			g_iClip[client][current_weaponid][current_skin] = GetEntProp(current, Prop_Send, "m_iClip1");
			g_iAmmo[client][current_weaponid][current_skin] = GetOrSetPlayerAmmo(client, current);

			//PrintToChatAll("%N WeaponCanUse Old Weapon %s (skin:%d), clip: %d, ammo: %d", client, sCurrent_ClassName, current_skin, g_iClip[client][current_weaponid][current_skin], g_iAmmo[client][current_weaponid][current_skin]);
		}

		static char sWeapon_ClassName[32];
		GetEntityClassname(weapon, sWeapon_ClassName, sizeof(sWeapon_ClassName));
		WeaponID weapon_weaponid = ID_NONE;
		if( !g_hWeaponName.GetValue(sWeapon_ClassName, weapon_weaponid) ) return;

		// Modify on next frame so we get new weapons reserve ammo
		DataPack dPack = new DataPack();
		dPack.WriteCell(GetClientUserId(client));
		dPack.WriteCell(EntIndexToEntRef(weapon));
		dPack.WriteCell(weapon_weaponid);
		RequestFrame(OnFrame, dPack);
	}
}

void OnFrame(DataPack dPack)
{
	dPack.Reset();

	int client = dPack.ReadCell();
	client = GetClientOfUserId(client);
	if( !client || !IsClientInGame(client))
	{
		delete dPack;
		return;
	}

	int weapon = dPack.ReadCell();
	weapon = EntRefToEntIndex(weapon);
	if( weapon == INVALID_ENT_REFERENCE )
	{
		delete dPack;
		return;
	}

	WeaponID weapon_weaponid = dPack.ReadCell();
	int weapon_skin = GetEntProp(weapon, Prop_Send, "m_nSkin"); // skin available on this frame

	// static char sWeapon_ClassName[32];
	// GetEntityClassname(weapon, sWeapon_ClassName, sizeof(sWeapon_ClassName));
	// PrintToChatAll("%N WeaponCanUse New Weapon %s (skin:%d)", client, sWeapon_ClassName, weapon_skin);

	if( g_iClip[client][weapon_weaponid][weapon_skin] == -1 || g_iAmmo[client][weapon_weaponid][weapon_skin] == -1)
	{
		delete dPack;
		return;
	}

	delete dPack;

	// Validate weapon
	if( weapon == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") )
	{
		int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");

		// Restore clip size to previous
		SetEntProp(weapon, Prop_Send, "m_iClip1", g_iClip[client][weapon_weaponid][weapon_skin]);

		// Add new ammo received to reserve ammo
		int cur_ammo = GetOrSetPlayerAmmo(client, weapon) + clip - g_iClip[client][weapon_weaponid][weapon_skin];
		int old_ammo = g_iAmmo[client][weapon_weaponid][weapon_skin];
		if( old_ammo <= cur_ammo )
		{
			GetOrSetPlayerAmmo(client, weapon, GetMin(cur_ammo, 999));
		}
		else
		{
			GetOrSetPlayerAmmo(client, weapon, old_ammo);
		}
	}
}

int GetMin(int a, int b)
{
	return a < b ? a : b;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, Timer_Event_PlayerSpawn, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_Event_PlayerSpawn(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if( !client || !IsClientInGame(client) || !IsPlayerAlive(client) ) return Plugin_Continue;

	ClearClientAmmo(client);

	return Plugin_Continue;
}

void Event_PlayerDeath( Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( !client || !IsClientInGame(client) ) return;

	ClearClientAmmo(client);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		ClearClientAmmo(client);
	}
}

// Save ammo when dropped
void Event_Weapon_Drop(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( !client || !IsClientInGame(client) ) return;

	int weapon = event.GetInt("propid");
	if( weapon <= MaxClients || !IsValidEntity(weapon) ) return;

	static char sWeapon_ClassName[32];
	GetEntityClassname(weapon, sWeapon_ClassName, sizeof(sWeapon_ClassName));
	WeaponID weapon_weaponid = ID_NONE;
	if( !g_hWeaponName.GetValue(sWeapon_ClassName, weapon_weaponid) ) return;

	int weapon_skin = GetEntProp(weapon, Prop_Send, "m_nSkin");

	g_iClip[client][weapon_weaponid][weapon_skin] = GetEntProp(weapon, Prop_Send, "m_iClip1");
	g_iAmmo[client][weapon_weaponid][weapon_skin] = GetOrSetPlayerAmmo(client, weapon);


	// PrintToChatAll("%N Drop weapon %s (skin:%d), clip: %d", client, sWeapon_ClassName, weapon_skin, GetEntProp(weapon, Prop_Send, "m_iClip1"));
}

// Reserve ammo
int GetOrSetPlayerAmmo(int client, int iWeapon, int iAmmo = -1)
{
	int offset = GetEntData(iWeapon, g_iPrimaryAmmoType) * 4; // Thanks to "Root" or whoever for this method of not hard-coding offsets: https://github.com/zadroot/AmmoManager/blob/master/scripting/ammo_manager.sp

	if( offset )
	{
		if( iAmmo != -1 ) SetEntData(client, g_iOffsetAmmo + offset, iAmmo);
		else
		{
			int ammo = GetEntData(client, g_iOffsetAmmo + offset);
			return ammo >= 999 ? 999 : ammo;
		}
	}

	return 0;
}

// Weapon ID's
void SetWeaponClassName()
{
	g_hWeaponName = new StringMap();
	g_hWeaponName.SetValue("", ID_NONE);
	//g_hWeaponName.SetValue("weapon_pistol", ID_PISTOL);
	//g_hWeaponName.SetValue("weapon_pistol", ID_DUAL_PISTOL);
	g_hWeaponName.SetValue("weapon_smg", ID_SMG);
	g_hWeaponName.SetValue("weapon_pumpshotgun", ID_PUMPSHOTGUN);
	g_hWeaponName.SetValue("weapon_rifle", ID_RIFLE);
	g_hWeaponName.SetValue("weapon_autoshotgun", ID_AUTOSHOTGUN);
	g_hWeaponName.SetValue("weapon_hunting_rifle", ID_HUNTING_RIFLE);
	g_hWeaponName.SetValue("weapon_smg_silenced", ID_SMG_SILENCED);
	g_hWeaponName.SetValue("weapon_smg_mp5", ID_SMG_MP5);
	g_hWeaponName.SetValue("weapon_shotgun_chrome", ID_CHROMESHOTGUN);
	//g_hWeaponName.SetValue("weapon_pistol_magnum", ID_MAGNUM);
	g_hWeaponName.SetValue("weapon_rifle_ak47", ID_AK47);
	g_hWeaponName.SetValue("weapon_rifle_desert", ID_RIFLE_DESERT);
	g_hWeaponName.SetValue("weapon_sniper_military", ID_SNIPER_MILITARY);
	g_hWeaponName.SetValue("weapon_grenade_launcher", ID_GRENADE);
	g_hWeaponName.SetValue("weapon_rifle_sg552", ID_SG552);
	g_hWeaponName.SetValue("weapon_rifle_m60", ID_M60);
	g_hWeaponName.SetValue("weapon_sniper_awp", ID_AWP);
	g_hWeaponName.SetValue("weapon_sniper_scout", ID_SCOUT);
	g_hWeaponName.SetValue("weapon_shotgun_spas", ID_SPASSHOTGUN);
}

// Reset array
void ClearClientAmmo(int client)
{
	for( WeaponID weapon = ID_NONE; weapon < ID_WEAPON_MAX ; ++weapon )
	{
		for( int skin = 0; skin < MAX_SKIN; skin++ )
		{
			g_iClip[client][weapon][skin] = -1;
			g_iAmmo[client][weapon][skin] = -1;
		}
	}
}