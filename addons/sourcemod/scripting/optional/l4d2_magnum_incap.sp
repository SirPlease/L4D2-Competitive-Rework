#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools_functions>

#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define DEBUG 0

int g_iOffs_m_hSecondaryWeaponRestore;
ConVar g_hReplaceMagnum = null;

public Plugin myinfo =
{
	name = "Magnum incap remover",
	author = "robex, Sir, Forgetest",
	description = "Replace magnum with regular pistols when incapped.",
	version = "0.5.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	g_iOffs_m_hSecondaryWeaponRestore = FindSendPropInfo("CTerrorPlayer", "m_iVersusTeam") - 20;

	g_hReplaceMagnum = CreateConVar("l4d2_replace_magnum_incap", "1.0", "Replace magnum with single (1) or double (2) pistols when incapacitated. 0 to disable.");

	HookEvent("player_incapacitated", PlayerIncap_Event);
}

void PlayerIncap_Event(Event hEvent, char[] name, bool dontBroadcast) 
{
	if (GetConVarInt(g_hReplaceMagnum) < 1) { return; }

	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	// This also fires on Tank Death, so check for client team to prevent issues down the line.
	if (GetClientTeam(client) != 2) { return; }

	int secWeaponIndex = GetPlayerWeaponSlot(client, L4D2WeaponSlot_Secondary);
	if (secWeaponIndex == -1)
		return;

	char sWeaponName[ENTITY_MAX_NAME_LENGTH];
	GetEdictClassname(secWeaponIndex, sWeaponName, sizeof(sWeaponName));

#if DEBUG
	PrintToChatAll("client %d -> weapon %s", client, sWeaponName);
#endif

	if (!strcmp(sWeaponName, "weapon_pistol_magnum") && GetPlayerSecondaryWeaponRestore(client) == -1) {
		RemovePlayerItem(client, secWeaponIndex);
		SetPlayerSecondaryWeaponRestore(client, secWeaponIndex);

		GivePlayerItem(client, "weapon_pistol");
		if (GetConVarInt(g_hReplaceMagnum) > 1) {
			GivePlayerItem(client, "weapon_pistol");
		}
	}
}

int GetPlayerSecondaryWeaponRestore(int client)
{
	return GetEntDataEnt2(client, g_iOffs_m_hSecondaryWeaponRestore);
}

void SetPlayerSecondaryWeaponRestore(int client, int weapon)
{
	SetEntDataEnt2(client, g_iOffs_m_hSecondaryWeaponRestore, weapon);
}