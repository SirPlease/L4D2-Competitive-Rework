#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>

#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define MAX_SURVIVORS 4
#define ENTITY_MAX_NAME_LENGTH 64
#define DEBUG 0


ConVar g_hReplaceMagnum = null;
int g_hasDeagle[MAX_SURVIVORS];

public Plugin myinfo =
{
	name = "Magnum incap remover",
	author = "robex",
	description = "Replace magnum with regular pistols when incapped.",
	version = "0.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	g_hReplaceMagnum = CreateConVar("l4d2_replace_magnum_incap", "1.0", "Replace magnum with single (1) or double (2) pistols when incapacitated. 0 to disable.");

	HookEvent("player_incapacitated", PlayerIncap_Event);
	HookEvent("revive_success", ReviveSuccess_Event);
}

public Action PlayerIncap_Event(Handle event, const char[] name, bool bDontBroadcast)
{
	if (GetConVarInt(g_hReplaceMagnum) < 1) {
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// This also fires on Tank Death, so check for client team to prevent issues down the line.
	if (GetClientTeam(client) != 2) { return Plugin_Continue; }

	int playerIndex = GetPlayerCharacter(client);
	char sWeaponName[ENTITY_MAX_NAME_LENGTH];
	int secWeaponIndex = GetPlayerWeaponSlot(client, L4D2WeaponSlot_Secondary);
	GetEdictClassname(secWeaponIndex, sWeaponName, sizeof(sWeaponName));


#if DEBUG
	PrintToChatAll("client %d, player index %d", client, playerIndex);
	CPrintToChatAll("client %d -> weapon %s", client, sWeaponName);
#endif

	int secWeapId = WeaponNameToId(sWeaponName);
	if (secWeapId == WEPID_PISTOL_MAGNUM) {
		RemovePlayerItem(client, secWeaponIndex);
		RemoveEntity(secWeaponIndex);

		GivePlayerItem(client, "weapon_pistol");
		if (GetConVarInt(g_hReplaceMagnum) > 1) {
			GivePlayerItem(client, "weapon_pistol");
		}
		g_hasDeagle[playerIndex] = 1;
	} else {
		g_hasDeagle[playerIndex] = 0;
	}

	return Plugin_Continue;
}

public Action ReviveSuccess_Event(Handle event, const char[] name, bool bDontBroadcast)
{
	if (GetConVarInt(g_hReplaceMagnum) < 1) {
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(GetEventInt(event, "subject"));
	int playerIndex = GetPlayerCharacter(client);

#if DEBUG
	CPrintToChatAll("client %d revived, player index %d, g_hasDeagle %d", client, playerIndex, g_hasDeagle[client]);
#endif

	if (g_hasDeagle[playerIndex]) {
		int secWeaponIndex = GetPlayerWeaponSlot(client, L4D2WeaponSlot_Secondary);

		RemovePlayerItem(client, secWeaponIndex);
		RemoveEntity(secWeaponIndex);

		GivePlayerItem(client, "weapon_pistol_magnum");
	}

	return Plugin_Continue;
}

int GetPlayerCharacter(int client)
{
	int tmpChr = GetEntProp(client, Prop_Send, "m_survivorCharacter");

	// use models when incorrect character returned
	if (tmpChr < 0 || tmpChr >= MAX_SURVIVORS) {
		char model[256];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));

		if (StrContains(model, "gambler") != -1) {
			tmpChr = 0;
		} else if (StrContains(model, "coach") != -1) {
			tmpChr = 2;
		} else if (StrContains(model, "mechanic") != -1) {
			tmpChr = 3;
		} else if (StrContains(model, "producer") != -1) {
			tmpChr = 1;
		} else if (StrContains(model, "namvet") != -1) {
			tmpChr = 0;
		} else if (StrContains(model, "teengirl") != -1) {
			tmpChr = 1;
		} else if (StrContains(model, "biker") != -1) {
			tmpChr = 3;
		} else if (StrContains(model, "manager") != -1) {
			tmpChr = 2;
		} else {
			tmpChr = 0;
		}
	}

	return tmpChr;
}
