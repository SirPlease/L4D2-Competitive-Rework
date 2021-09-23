#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN

#define HEALTH_FIRST_AID_KIT    1
#define HEALTH_DEFIBRILLATOR    2
#define HEALTH_PAIN_PILLS       4
#define HEALTH_ADRENALINE       8

#define THROWABLE_PIPE_BOMB     16
#define THROWABLE_MOLOTOV       32
#define THROWABLE_VOMITJAR      64

#define TEAM_SURV 2
#define TEAM_INF  3


public Plugin myinfo =
{
	name = "Starting Items",
	author = "CircleSquared, Jacob, robex",
	description = "Gives health items and throwables to survivors at the start of each round",
	version = "2.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

Handle hCvarItemType;
bool g_bReadyUpAvailable = false;

public void OnPluginStart()
{
	hCvarItemType = CreateConVar("starting_item_flags", "0", "Item flags to give on leaving the saferoom (1: Kit, 2: Defib, 4: Pills, 8: Adren, 16: Pipebomb, 32: Molotov, 64: Bile)", FCVAR_NONE);
	HookEvent("player_left_start_area", PlayerLeftStartArea);
}

public void OnAllPluginsLoaded()
{
	g_bReadyUpAvailable = LibraryExists("readyup");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "readyup")) {
		g_bReadyUpAvailable = false;
	}
}
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "readyup")) {
		g_bReadyUpAvailable = true;
	}
}

public void OnRoundIsLive()
{
	DetermineItems();
}

public Action PlayerLeftStartArea(Handle event, const char[] name, bool dontBroadcast)
{
	if (!g_bReadyUpAvailable) {
		DetermineItems();
	}
	return Plugin_Continue;
}	

public void DetermineItems()
{
	char strItemName[32];
	int iItemFlags = GetConVarInt(hCvarItemType);

	if (iItemFlags) {
		if (iItemFlags & HEALTH_FIRST_AID_KIT) {
			strItemName = "weapon_first_aid_kit";
			giveStartingItem(strItemName);
		} else if (iItemFlags & HEALTH_DEFIBRILLATOR) {
			strItemName = "weapon_defibrillator";
			giveStartingItem(strItemName);
		}

		if (iItemFlags & HEALTH_PAIN_PILLS) {
			strItemName = "weapon_pain_pills";
			giveStartingItem(strItemName);
		} else if (iItemFlags & HEALTH_ADRENALINE) {
			strItemName = "weapon_adrenaline";
			giveStartingItem(strItemName);
		}

		if (iItemFlags & THROWABLE_PIPE_BOMB) {
			strItemName = "weapon_pipe_bomb";
			giveStartingItem(strItemName);
		} else if (iItemFlags & THROWABLE_MOLOTOV) {
			strItemName = "weapon_molotov";
			giveStartingItem(strItemName);
		} else if (iItemFlags & THROWABLE_VOMITJAR) {
			strItemName = "weapon_vomitjar";
			giveStartingItem(strItemName);
		}
	}
}

void giveStartingItem(const char[] strItemName)
{
	int startingItem;
	float clientOrigin[3];

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURV) {
			startingItem = CreateEntityByName(strItemName);
			GetClientAbsOrigin(i, clientOrigin);
			TeleportEntity(startingItem, clientOrigin, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(startingItem);
			EquipPlayerWeapon(i, startingItem);
		}
	}
}
