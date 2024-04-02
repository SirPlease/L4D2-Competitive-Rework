#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define USE_GIVEPLAYERITEM 0 // Works correctly only in the latest version of sourcemod 1.11 (GivePlayerItem sourcemod native)

enum
{
	ePILL_INDEX = 0,
	eADREN_INDEX,

	eITEM_SIZE
}

int
	g_iBotUsedCount[MAXPLAYERS + 1][eITEM_SIZE];

public Plugin myinfo =
{
	name = "Simplified Bot Pop Stop",
	author = "Stabby & CanadaRox",
	description = "Removes pills from bots if they try to use them and restores them when a human takes over.",
	version = "1.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("bot_player_replace", Event_PlayerJoined);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void Event_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	for (int j = 1; j <= MaxClients; j++) {
		for (int i = 0; i < eITEM_SIZE; i++) {
			g_iBotUsedCount[j][i] = 0;
		}
	}
}

// Take pills from the bot before they get used
public void Event_WeaponFire(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	if (!IsFakeClient(iClient)) {
		return;
	}

	int iWeaponId = hEvent.GetInt("weaponid");
	int iWeaponArrayIndex = -1;

	switch (iWeaponId) {
		case WEPID_PAIN_PILLS: {
			iWeaponArrayIndex = ePILL_INDEX;
		}
		case WEPID_ADRENALINE: {
			iWeaponArrayIndex = eADREN_INDEX;
		}
		default: {
			return;
		}
	}

	g_iBotUsedCount[iClient][iWeaponArrayIndex]++;

	int iEntity = GetPlayerWeaponSlot(iClient, L4D2WeaponSlot_LightHealthItem);
	RemovePlayerItem(iClient, iEntity);

#if SOURCEMOD_V_MINOR > 8
	RemoveEntity(iEntity);
#else
	AcceptEntityInput(iEntity, "Kill");
#endif
}

// Give the human player the pills back when they join
public void Event_PlayerJoined(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iLeavingBot = GetClientOfUserId(hEvent.GetInt("bot"));
	if (g_iBotUsedCount[iLeavingBot][ePILL_INDEX] < 1 && g_iBotUsedCount[iLeavingBot][eADREN_INDEX] < 1) {
		return;
	}

	int iPlayer = GetClientOfUserId(hEvent.GetInt("player"));
	RestoreItems(iPlayer, iLeavingBot);
}

void RestoreItems(int iClient, int iLeavingBot)
{
	int iCurrentWeapon = GetPlayerWeaponSlot(iClient, L4D2WeaponSlot_LightHealthItem);

	for (int j = 0; j < eITEM_SIZE; j++) {
		if (g_iBotUsedCount[iLeavingBot][j] < 1) {
			continue;
		}

		for (int i = 1; i <= g_iBotUsedCount[iLeavingBot][j]; i++) {
			#if (SOURCEMOD_V_MINOR == 11) || USE_GIVEPLAYERITEM
				if (iCurrentWeapon == -1) {
					int iEntity = GivePlayerItem(iClient, (j == ePILL_INDEX) ? "weapon_pain_pills" : "weapon_adrenaline");
					iCurrentWeapon = iEntity;
					continue;
				}

				CreateEntityAtLocation(iClient, (j == ePILL_INDEX) ? "weapon_pain_pills" : "weapon_adrenaline");
			#else
				int iEntity = CreateEntityAtLocation(iClient, (j == ePILL_INDEX) ? "weapon_pain_pills" : "weapon_adrenaline");

				if (iEntity != -1 && iCurrentWeapon == -1) {
					EquipPlayerWeapon(iClient, iEntity);
					iCurrentWeapon = iEntity;
				}
			#endif
		}

		g_iBotUsedCount[iLeavingBot][j] = 0;
	}
}

int CreateEntityAtLocation(int iClient, const char[] sEntityName)
{
	int iEntity = CreateEntityByName(sEntityName);
	if (iEntity == -1) {
		return -1;
	}
	
	float fClientOrigin[3];
	GetClientAbsOrigin(iClient, fClientOrigin);
	fClientOrigin[2] += 10.0;
	TeleportEntity(iEntity, fClientOrigin, NULL_VECTOR, NULL_VECTOR);

	DispatchSpawn(iEntity);

	return iEntity;
}
