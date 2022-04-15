#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>

#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define ENTITY_MAX_NAME_LENGTH 64
#define DEBUG 0

ConVar g_hReplaceMagnum = null;
ConVar g_hReplaceMagnumNumPistols = null;
int g_hasDeagle[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Magnum incap remover",
	author = "robex",
	description = "Replace magnum with regular pistols when incapped.",
	version = "0.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	g_hReplaceMagnum = CreateConVar("l4d2_replace_magnum_incap", "1.0", "Replace magnum with pistol when incapacitated.");
	g_hReplaceMagnumNumPistols = CreateConVar("l4d2_replace_magnum_num_pistols", "1.0", "Replace magnum with single (1) or double (2) pistols.");

	HookEvent("player_incapacitated", PlayerIncap_Event);
	HookEvent("revive_success", ReviveSuccess_Event);
}

public Action PlayerIncap_Event(Handle event, const char[] name, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	char sWeaponName[ENTITY_MAX_NAME_LENGTH];

	int secWeaponIndex = GetPlayerWeaponSlot(client, L4D2WeaponSlot_Secondary);
	GetEdictClassname(secWeaponIndex, sWeaponName, sizeof(sWeaponName));

#if DEBUG
	CPrintToChatAll("client %d -> weapon %s", client, sWeaponName);
#endif

	int secWeapId = WeaponNameToId(sWeaponName);
	if (secWeapId == WEPID_PISTOL_MAGNUM) {
		RemovePlayerItem(client, secWeaponIndex);
		GivePlayerItem(client, "weapon_pistol");
		if (GetConVarInt(g_hReplaceMagnumNumPistols) > 1) {
			GivePlayerItem(client, "weapon_pistol");
		}
		g_hasDeagle[client] = 1;
	} else {
		g_hasDeagle[client] = 0;
	}

	return Plugin_Continue;
}

public Action ReviveSuccess_Event(Handle event, const char[] name, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "subject"));

#if DEBUG
	CPrintToChatAll("client %d revived, g_hasDeagle %d", client, g_hasDeagle[client]);
#endif

	if (g_hasDeagle[client]) {
		int secWeaponIndex = GetPlayerWeaponSlot(client, L4D2WeaponSlot_Secondary);

		RemovePlayerItem(client, secWeaponIndex);
		GivePlayerItem(client, "weapon_pistol_magnum");
	}

	return Plugin_Continue;
}
