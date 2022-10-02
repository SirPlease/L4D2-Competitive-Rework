// Changelog:
//
// 2.0 (robex):
//     - Code rework, cleaned up old sourcemod functions
//     - Allow limiting individual melees, to limit them with l4d_wlimits_add
//       use names in MeleeWeaponNames array (l4d2util_constants.inc)
//

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util> //#include <weapons>
#include <colors>

#define MAX_WEAPON_NAME_LENGTH	32
#define GAMEDATA_FILE			"l4d_wlimits"
#define GAMEDATA_USE_AMMO		"CWeaponAmmoSpawn_Use"

#define MAX_PLAYER_WEAPON_SLOTS 5

#define TEAM_SURVIVOR 2

enum struct LimitArrayEntry
{
	int LAE_iLimit;
	int LAE_iGiveAmmo;
	int LAE_WeaponArray[WEPID_SIZE / 32 + 1];
	int LAE_MeleeArray[WEPID_MELEES_SIZE / 32 + 1];
}

Handle
	hSDKGiveDefaultAmmo;

ArrayList
	hLimitArray;

bool
	bIsLocked,
	bIsIncappedWithMelee[MAXPLAYERS + 1],
	bIsPressingButtonUse[MAXPLAYERS + 1],
	bIsHoldingButtonUse[MAXPLAYERS + 1];

StringMap hMeleeWeaponNamesTrie = null;

public Plugin myinfo =
{
	name = "L4D Weapon Limits",
	author = "CanadaRox, Stabby, Forgetest, A1m`, robex",
	description = "Restrict weapons individually or together",
	version = "2.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	L4D2Weapons_Init();

	hLimitArray = new ArrayList(sizeof(LimitArrayEntry));

	/* Preparing SDK Call */
	Handle conf = LoadGameConfigFile(GAMEDATA_FILE);

	if (conf == null) {
		SetFailState("Gamedata missing: %s", GAMEDATA_FILE);
	}
	
	StartPrepSDKCall(SDKCall_Entity);

	if (!PrepSDKCall_SetFromConf(conf, SDKConf_Signature, GAMEDATA_USE_AMMO)) {
		SetFailState("Gamedata missing signature: %s", GAMEDATA_USE_AMMO);
	}
	
	// Client that used the ammo spawn
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	hSDKGiveDefaultAmmo = EndPrepSDKCall();
	
	if (hSDKGiveDefaultAmmo == null) {
		SetFailState("Failed to finish SDKCall setup: %s", GAMEDATA_USE_AMMO);
	}

	hMeleeWeaponNamesTrie = new StringMap();

	for (int i = 0; i < WEPID_MELEES_SIZE; i++) {
		hMeleeWeaponNamesTrie.SetValue(MeleeWeaponNames[i], i);
	}


	RegServerCmd("l4d_wlimits_add", AddLimit_Cmd, "Add a weapon limit");
	RegServerCmd("l4d_wlimits_lock", LockLimits_Cmd, "Locks the limits to improve search speeds");
	RegServerCmd("l4d_wlimits_clear", ClearLimits_Cmd, "Clears all weapon limits (limits must be locked to be cleared)");

	HookEvent("round_start", ClearUp, EventHookMode_PostNoCopy);
	HookEvent("player_incapacitated_start", OnIncap);
	HookEvent("revive_success", OnRevive);
	HookEvent("player_death", OnDeath);
	HookEvent("player_bot_replace", OnBotReplacedPlayer);
	HookEvent("bot_player_replace", OnPlayerReplacedBot);
	
	delete conf;
}

public void OnMapStart()
{
	PrecacheSound("player/suit_denydevice.wav");
}

public void ClearUp(Event hEvent, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MAXPLAYERS; i++) {
		bIsIncappedWithMelee[i] = false;
		bIsPressingButtonUse[i] = false;
		bIsHoldingButtonUse[i] = false;
	}
}

public void OnClientPutInServer(int client)
{
	bIsPressingButtonUse[client] = false;
	bIsHoldingButtonUse[client] = false;
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}

public void OnClientDisconnect(int client)
{
	bIsPressingButtonUse[client] = false;
	bIsHoldingButtonUse[client] = false;
	SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}

public Action AddLimit_Cmd(int args)
{
	if (bIsLocked) {
		PrintToServer("Limits have been locked !");
		return Plugin_Handled;
	} else if (args < 3) {
		PrintToServer("Usage: l4d_wlimits_add <limit> <ammo> <weapon1> <weapon2> ... <weaponN>\nAmmo: -1: Given for primary weapon spawns only, 0: no ammo given ever, else: ammo always given !");
		return Plugin_Handled;
	}

	char sTempBuff[MAX_WEAPON_NAME_LENGTH];
	GetCmdArg(1, sTempBuff, sizeof(sTempBuff));
	
	int wepid;
	int meleeid;

	LimitArrayEntry newEntry;

	newEntry.LAE_iLimit = StringToInt(sTempBuff);
	GetCmdArg(2, sTempBuff, sizeof(sTempBuff));
	newEntry.LAE_iGiveAmmo = StringToInt(sTempBuff);

	for (int i = 3; i <= args; ++i) {
		GetCmdArg(i, sTempBuff, sizeof(sTempBuff));
		wepid = WeaponNameToId(sTempBuff);
		newEntry.LAE_WeaponArray[wepid / 32] |= (1 << (wepid % 32));

		// assume it might be a melee
		if (wepid == WEPID_NONE) {
			if (hMeleeWeaponNamesTrie.GetValue(sTempBuff, meleeid)) {
				newEntry.LAE_MeleeArray[meleeid / 32] |= (1 << (meleeid % 32));
			}
		}
	}
	
	hLimitArray.PushArray(newEntry, sizeof(LimitArrayEntry));
	return Plugin_Handled;
}

public Action LockLimits_Cmd(int args)
{
	if (bIsLocked) {
		PrintToServer("Weapon limits already locked !");
	} else {
		bIsLocked = true;
		PrintToServer("Weapon limits locked !");
	}

	return Plugin_Handled;
}

public Action ClearLimits_Cmd(int args)
{
	if (bIsLocked) {
		bIsLocked = false;
		PrintToChatAll("[L4D Weapon Limits] Weapon limits cleared!");
		ClearLimits();
	}

	return Plugin_Handled;
}

void ClearLimits()
{
	if (hLimitArray != null) {
		ClearArray(hLimitArray);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client)) {
		bIsHoldingButtonUse[client] = bIsPressingButtonUse[client];
		bIsPressingButtonUse[client] = !!(buttons & IN_USE);
	} else {
		bIsHoldingButtonUse[client] = false;
		bIsPressingButtonUse[client] = false;
	}
	
	return Plugin_Continue;
}

int isWeaponLimited(const int[] mask, int wepid)
{
	return mask[wepid / 32] & (1 << (wepid % 32));
}

void denyWeapon(int wep_slot, LimitArrayEntry arrayEntry, int client)
{
	if ((wep_slot == 0 && arrayEntry.LAE_iGiveAmmo == -1) || arrayEntry.LAE_iGiveAmmo != 0) {
		GiveDefaultAmmo(client);
	}

	// Notify the client only when they are attempting to pick this up
	// in which way spamming gets avoided due to auto-pick-up checking left since Counter:Strike.
	if (bIsPressingButtonUse[client] && !bIsHoldingButtonUse[client])
	{
		bIsHoldingButtonUse[client] = true;
		CPrintToChat(client, "{blue}[{default}Weapon Limits{blue}]{default} This weapon group has reached its max of {green}%d", arrayEntry.LAE_iLimit);
		EmitSoundToClient(client, "player/suit_denydevice.wav");
	}
}

public Action WeaponCanUse(int client, int weapon)
{
	if (GetClientTeam(client) != TEAM_SURVIVOR || !bIsLocked) {
		return Plugin_Continue;
	}
	
	int wepid = IdentifyWeapon(weapon);
	int is_melee = (wepid == WEPID_MELEE);
	int meleeid = 0;
	if (is_melee) {
		meleeid = IdentifyMeleeWeapon(weapon);
	}
	int wep_slot = GetSlotFromWeaponId(wepid);

	int player_weapon = GetPlayerWeaponSlot(client, wep_slot);
	int player_wepid = IdentifyWeapon(player_weapon);
	/*int player_meleeid = 0;
	if (player_wepid == WEPID_MELEE) {
		player_meleeid = IdentifyMeleeWeapon(player_weapon);
	}*/

	LimitArrayEntry arrayEntry;

	int iSize = hLimitArray.Length;
	for (int i = 0; i < iSize; i++) {
		hLimitArray.GetArray(i, arrayEntry, sizeof(LimitArrayEntry));
		if (is_melee) {
			int specificMeleeCount = GetMeleeCount(arrayEntry.LAE_MeleeArray);
			int allMeleeCount = GetWeaponCount(arrayEntry.LAE_WeaponArray);

			int isSpecificMeleeLimited = isWeaponLimited(arrayEntry.LAE_MeleeArray, meleeid);
			int isAllMeleeLimited = isWeaponLimited(arrayEntry.LAE_WeaponArray, wepid);

			if (isSpecificMeleeLimited && specificMeleeCount >= arrayEntry.LAE_iLimit) {
				denyWeapon(wep_slot, arrayEntry, client);
				return Plugin_Handled;
			}

			if (isAllMeleeLimited && allMeleeCount >= arrayEntry.LAE_iLimit) {
				// dont deny swapping melees when theres only a limit on global melees
				if (player_wepid != WEPID_MELEE) {
					denyWeapon(wep_slot, arrayEntry, client);
					return Plugin_Handled;
				}
			}
		} else {
			// is weapon about to be picked up limited and over the limit?
			if (isWeaponLimited(arrayEntry.LAE_WeaponArray, wepid) && GetWeaponCount(arrayEntry.LAE_WeaponArray) >= arrayEntry.LAE_iLimit) {
				// is currently held weapon limited?
				if (!player_wepid || wepid == player_wepid || !isWeaponLimited(arrayEntry.LAE_WeaponArray, player_wepid)) {
					denyWeapon(wep_slot, arrayEntry, client);
					return Plugin_Handled;
				}
			}
		}
	}

	return Plugin_Continue;
}

public void OnIncap(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && GetClientTeam(client) == TEAM_SURVIVOR && IdentifyWeapon(GetPlayerWeaponSlot(client, 1)) == WEPID_MELEE) {
		bIsIncappedWithMelee[client] = true;
	}
}

public void OnRevive(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (client > 0 && bIsIncappedWithMelee[client]) {
		bIsIncappedWithMelee[client] = false;
	}
}

public void OnDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && GetClientTeam(client) == TEAM_SURVIVOR && bIsIncappedWithMelee[client]) {
		bIsIncappedWithMelee[client] = false;
	}
}

public void OnBotReplacedPlayer(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));
	if (bot > 0 && GetClientTeam(bot) == TEAM_SURVIVOR) {
		int player = GetClientOfUserId(event.GetInt("player"));
		bIsIncappedWithMelee[bot] = bIsIncappedWithMelee[player];
		bIsIncappedWithMelee[player] = false;
	}
}

public void OnPlayerReplacedBot(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));
	if (player > 0 && GetClientTeam(player) == TEAM_SURVIVOR) {
		int bot = GetClientOfUserId(event.GetInt("bot"));
		bIsIncappedWithMelee[player] = bIsIncappedWithMelee[bot];
		bIsIncappedWithMelee[bot] = false;
	}
}

stock int GetWeaponCount(const int[] mask)
{
	bool queryMelee = view_as<bool>(mask[WEPID_MELEE / 32] & (1 << (WEPID_MELEE % 32)));

	int count, wepid;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i)) {
			for (int j = 0; j < MAX_PLAYER_WEAPON_SLOTS; ++j) {
				wepid = IdentifyWeapon(GetPlayerWeaponSlot(i, j));
				if (isWeaponLimited(mask, wepid) || (j == 1 && queryMelee && bIsIncappedWithMelee[i])) {
					count++;
				}
			}
		}
	}

	return count;
}

stock int GetMeleeCount(const int[] mask)
{
	int count, meleeid;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i)) {
			meleeid = IdentifyMeleeWeapon(GetPlayerWeaponSlot(i, L4D2WeaponSlot_Secondary));
			if (meleeid == WEPID_MELEE_NONE)
				continue;

			if (isWeaponLimited(mask, meleeid) || bIsIncappedWithMelee[i]) {
				count++;
			}
		}
	}

	return count;
}

stock void GiveDefaultAmmo(int client)
{
	SDKCall(hSDKGiveDefaultAmmo, 0, client);
}
