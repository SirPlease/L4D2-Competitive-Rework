/*
*	No Reload Animation Fix - Picking Up Same Weapon
*	Copyright (C) 2021 Silvers
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



#define PLUGIN_VERSION 		"1.2"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] No Reload Animation Fix - Picking Up Same Weapon
*	Author	:	SilverShot
*	Descrp	:	Prevent filling the clip and skipping the reload animation when taking the same weapon.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=333100
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

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
#include <sdkhooks>

StringMap g_hWeaponOffsets;
int g_iClipAmmo[MAXPLAYERS+1];
int g_iOffsetAmmo;
bool g_bLateLoad;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] No Reload Animation Fix - Picking Up Same Weapon",
	author = "SilverShot",
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

	return APLRes_Success;
}

public void OnPluginStart()
{
	// Lateload
	if( g_bLateLoad )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKHook(i, SDKHook_WeaponCanUsePost, WeaponCanUse);
			}
		}
	}

	// Offsets to setting reserve ammo
	g_iOffsetAmmo = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

	g_hWeaponOffsets = new StringMap();
	g_hWeaponOffsets.SetValue("weapon_rifle", 12);
	g_hWeaponOffsets.SetValue("weapon_smg", 20);
	g_hWeaponOffsets.SetValue("weapon_pumpshotgun", 28);
	g_hWeaponOffsets.SetValue("weapon_shotgun_chrome", 28);
	g_hWeaponOffsets.SetValue("weapon_autoshotgun", 32);
	g_hWeaponOffsets.SetValue("weapon_hunting_rifle", 36);

	// if( g_bLeft4Dead2 )
	// {
	g_hWeaponOffsets.SetValue("weapon_rifle_sg552", 12);
	g_hWeaponOffsets.SetValue("weapon_rifle_desert", 12);
	g_hWeaponOffsets.SetValue("weapon_rifle_ak47", 12);
	g_hWeaponOffsets.SetValue("weapon_smg_silenced", 20);
	g_hWeaponOffsets.SetValue("weapon_smg_mp5", 20);
	g_hWeaponOffsets.SetValue("weapon_shotgun_spas", 32);
	g_hWeaponOffsets.SetValue("weapon_sniper_scout", 40);
	g_hWeaponOffsets.SetValue("weapon_sniper_military", 40);
	g_hWeaponOffsets.SetValue("weapon_sniper_awp", 40);
	g_hWeaponOffsets.SetValue("weapon_grenade_launcher", 68);
	// }

	CreateConVar("l4d2_reload_fix_version", PLUGIN_VERSION, "No Reload Animation Fix plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUsePost, WeaponCanUse);
}

public void WeaponCanUse(int client, int weapon)
{
	g_iClipAmmo[client] = -1;

	if( weapon == -1 ) return;

	// Validate team
	if( GetClientTeam(client) == 2 )
	{
		// Validate weapon
		int current = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( current == -1 ) return;

		static char class1[32], class2[32];
		GetEdictClassname(current, class1, sizeof(class1));
		GetEdictClassname(weapon, class2, sizeof(class2));

		// Match same weapon
		if( strcmp(class1, class2) == 0 )
		{
			// Store clip size
			g_iClipAmmo[client] = GetEntProp(current, Prop_Send, "m_iClip1");

			// Modify on next frame so we get new weapons reserve ammo
			DataPack dPack = new DataPack();
			dPack.WriteCell(GetClientUserId(client));
			dPack.WriteCell(EntIndexToEntRef(weapon));
			RequestFrame(OnFrame, dPack);
		}
	}
}

public void OnFrame(DataPack dPack)
{
	dPack.Reset();

	int client = dPack.ReadCell();
	client = GetClientOfUserId(client);
	if( !client || !IsClientInGame(client) || g_iClipAmmo[client] == -1 )
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

	delete dPack;

	// Validate weapon
	if( weapon == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") )
	{
		int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");

		// Restore clip size to previous
		SetEntProp(weapon, Prop_Send, "m_iClip1", g_iClipAmmo[client]);

		// Add new ammo received to reserve ammo
		int ammo = GetOrSetPlayerAmmo(client, weapon);
		GetOrSetPlayerAmmo(client, weapon, ammo + clip - g_iClipAmmo[client]);
	}
}

// Reserve ammo
int GetOrSetPlayerAmmo(int client, int iWeapon, int iAmmo = -1)
{
	static char sWeapon[32];
	GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));

	int offset;
	g_hWeaponOffsets.GetValue(sWeapon, offset);

	if( offset )
	{
		if( iAmmo != -1 ) SetEntData(client, g_iOffsetAmmo + offset, iAmmo);
		else return GetEntData(client, g_iOffsetAmmo + offset);
	}

	return 0;
}