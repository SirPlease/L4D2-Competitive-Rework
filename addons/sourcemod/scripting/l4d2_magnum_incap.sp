#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define ENTITY_MAX_NAME_LENGTH 64
#define DEBUG 0

ConVar g_hReplaceMagnum = null;
bool g_bHasDeagle[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Magnum incap remover",
	author = "robex, Sir",
	description = "Replace magnum with regular pistols when incapped.",
	version = "0.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	g_hReplaceMagnum = CreateConVar("l4d2_replace_magnum_incap", "1.0", "Replace magnum with single (1) or double (2) pistols when incapacitated. 0 to disable.");

	HookEvent("player_incapacitated", PlayerIncap_Event);
	HookEvent("revive_success", ReviveSuccess_Event);
	HookEvent("round_start", RoundStart_Event);
	HookEvent("bot_player_replace", Replaced_Event);
	HookEvent("player_bot_replace", Replaced_Event);
}

void RoundStart_Event(Event hEvent, char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		g_bHasDeagle[i] = false;
	}
}

void Replaced_Event(Event hEvent, char[] name, bool dontBroadcast) 
{
	bool bBotReplaced = (!strncmp(name, "b", 1));
	int replaced = bBotReplaced ? GetClientOfUserId(hEvent.GetInt("bot")) : GetClientOfUserId(hEvent.GetInt("player"));
	int replacer = bBotReplaced ? GetClientOfUserId(hEvent.GetInt("player")) : GetClientOfUserId(hEvent.GetInt("bot"));

	g_bHasDeagle[replacer] = g_bHasDeagle[replaced];
}

void PlayerIncap_Event(Event hEvent, char[] name, bool dontBroadcast) 
{
	if (GetConVarInt(g_hReplaceMagnum) < 1) { return; }

	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	// This also fires on Tank Death, so check for client team to prevent issues down the line.
	if (GetClientTeam(client) != 2) { return; }

	char sWeaponName[ENTITY_MAX_NAME_LENGTH];
	int secWeaponIndex = GetPlayerWeaponSlot(client, L4D2WeaponSlot_Secondary);
	GetEdictClassname(secWeaponIndex, sWeaponName, sizeof(sWeaponName));

#if DEBUG
	PrintToChatAll("client %d -> weapon %s", client, sWeaponName);
#endif

	int secWeapId = WeaponNameToId(sWeaponName);
	if (secWeapId == WEPID_PISTOL_MAGNUM) {
		RemovePlayerItem(client, secWeaponIndex);
		RemoveEntity(secWeaponIndex);

		GivePlayerItem(client, "weapon_pistol");
		if (GetConVarInt(g_hReplaceMagnum) > 1) {
			GivePlayerItem(client, "weapon_pistol");
		}
		g_bHasDeagle[client] = true;
	} else {
		g_bHasDeagle[client] = false;
	}
}

void ReviveSuccess_Event(Event hEvent, char[] name, bool dontBroadcast) 
{
	if (GetConVarInt(g_hReplaceMagnum) < 1) { return; }

	int client = GetClientOfUserId(hEvent.GetInt("subject"));

#if DEBUG
	PrintToChatAll("client %d revived, g_bHasDeagle: %s", client, g_bHasDeagle[client] ? "True" : "False");
#endif

	if (g_bHasDeagle[client]) {
		int secWeaponIndex = GetPlayerWeaponSlot(client, L4D2WeaponSlot_Secondary);

		RemovePlayerItem(client, secWeaponIndex);
		RemoveEntity(secWeaponIndex);

		GivePlayerItem(client, "weapon_pistol_magnum");
		g_bHasDeagle[client] = false; // Gets set on incap anywoo.
	}
}
