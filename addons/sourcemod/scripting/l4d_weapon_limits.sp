#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <weapons>
#include <colors>

#pragma semicolon 1
#pragma newdecls required

#define MAX_WEAPON_NAME_LENGTH 32
#define GAMEDATA_FILE          "l4d_wlimits"
#define GAMEDATA_USE_AMMO      "CWeaponAmmoSpawn_Use"

public Plugin myinfo =
{
	name = "L4D Weapon Limits",
	author = "CanadaRox, Stabby, Forgetest",
	description = "Restrict weapons individually or together",
	version = "1.3.5",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

#define TEAM_SURVIVOR 2

enum struct LimitArrayEntry
{
	int LAE_iLimit;
	int LAE_iGiveAmmo;
	int LAE_WeaponArray[view_as<int>(WeaponId)/32+1];
}

Handle hSDKGiveDefaultAmmo;
ArrayList hLimitArray;
bool bIsLocked;
bool bIsIncappedWithMelee[MAXPLAYERS + 1];

public void OnPluginStart()
{
	hLimitArray = new ArrayList(sizeof LimitArrayEntry);
	L4D2Weapons_Init();

	/* Preparing SDK Call */
	/* {{{ */
	GameData conf = LoadGameConfigFile(GAMEDATA_FILE);

	if (conf == null)
		SetFailState("Gamedata missing: %s", GAMEDATA_FILE);

	StartPrepSDKCall(SDKCall_Entity);

	if (!PrepSDKCall_SetFromConf(conf, SDKConf_Signature, GAMEDATA_USE_AMMO))
		SetFailState("Gamedata missing signature: %s", GAMEDATA_USE_AMMO);

	// Client that used the ammo spawn
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	hSDKGiveDefaultAmmo = EndPrepSDKCall();
	
	if (hSDKGiveDefaultAmmo == null)
		SetFailState("Failed to finish SDKCall setup: %s", GAMEDATA_USE_AMMO);
	/* }}} */

	RegServerCmd("l4d_wlimits_add", AddLimit_Cmd, "Add a weapon limit");
	RegServerCmd("l4d_wlimits_lock", LockLimits_Cmd, "Locks the limits to improve search speeds");
	RegServerCmd("l4d_wlimits_clear", ClearLimits_Cmd, "Clears all weapon limits (limits must be locked to be cleared)");

	HookEvent("round_start", ClearUp);
	HookEvent("player_incapacitated_start", OnIncap);
	HookEvent("revive_success", OnRevive);
	HookEvent("player_death", OnDeath);
	HookEvent("player_bot_replace", OnBotReplacedPlayer);
	HookEvent("bot_player_replace", OnPlayerReplacedBot);
}

public void OnMapStart()
{
	PrecacheSound("player/suit_denydevice.wav");
}

public void ClearUp(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		bIsIncappedWithMelee[i] = false;
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}

public Action AddLimit_Cmd(int args)
{
	if (bIsLocked)
	{
		PrintToServer("Limits have been locked");
		return Plugin_Handled;
	}
	else if (args < 3)
	{
		PrintToServer("Usage: l4d_wlimits_add <limit> <ammo> <weapon1> <weapon2> ... <weaponN>\nAmmo: -1: Given for primary weapon spawns only, 0: no ammo given ever, else: ammo always given");
		return Plugin_Handled;
	}

	char sTempBuff[MAX_WEAPON_NAME_LENGTH];
	GetCmdArg(1, sTempBuff, sizeof(sTempBuff));

	LimitArrayEntry newEntry;
	int wepid;
	newEntry.LAE_iLimit = StringToInt(sTempBuff);

	GetCmdArg(2, sTempBuff, sizeof(sTempBuff));
	newEntry.LAE_iGiveAmmo = StringToInt(sTempBuff);

	for (int i = 3; i <= args; ++i)
	{
		GetCmdArg(i, sTempBuff, sizeof(sTempBuff));
		wepid = view_as<int>(WeaponNameToId(sTempBuff));
		newEntry.LAE_WeaponArray[wepid/32] |= (1 << (wepid % 32));
	}
	hLimitArray.PushArray(newEntry);
	return Plugin_Handled;
}

public Action LockLimits_Cmd(int args)
{
	if (bIsLocked)
	{
		PrintToServer("Weapon limits already locked");
	}
	else
	{
		bIsLocked = true;
	}
}

public Action ClearLimits_Cmd(int args)
{
	if (bIsLocked)
	{
		bIsLocked = false;
		PrintToChatAll("[L4D Weapon Limits] Weapon limits cleared!");
		ClearLimits();
	}
}

void ClearLimits()
{
	if (hLimitArray != null)
		ClearArray(hLimitArray);
}

public Action WeaponCanUse(int client, int weapon)
{
	// TODO: There seems to be an issue that this hook will be constantly called
	//       when client with no weapon on equivalent slot just eyes or walks on it.
	//       If the weapon meets limit, client will have the warning spamming unexpectedly.
	
	if (GetClientTeam(client) != TEAM_SURVIVOR || !bIsLocked) return Plugin_Continue;
	
	int wepid = view_as<int>(IdentifyWeapon(weapon));
	int wep_slot = GetSlotFromWeaponId(view_as<WeaponId>(wepid));
	int player_weapon = GetPlayerWeaponSlot(client, wep_slot);
	int player_wepid = view_as<int>(IdentifyWeapon(player_weapon));

	LimitArrayEntry arrayEntry;
	
	int size = hLimitArray.Length;
	for (int i = 0; i < size; ++i)
	{
		hLimitArray.GetArray(i, arrayEntry);
		if (arrayEntry.LAE_WeaponArray[wepid/32] & (1 << (wepid % 32)) && GetWeaponCount(arrayEntry.LAE_WeaponArray) >= arrayEntry.LAE_iLimit)
		{
			if (!player_wepid || wepid == player_wepid || !(arrayEntry.LAE_WeaponArray[player_wepid/32] & (1 << (player_wepid % 32))))
			{
				// Swap melee, np
				if (player_wepid == view_as<int>(WEPID_MELEE) && wepid == view_as<int>(WEPID_MELEE))
					return Plugin_Continue;
				
				if ((wep_slot == 0 && arrayEntry.LAE_iGiveAmmo == -1) || arrayEntry.LAE_iGiveAmmo != 0)
					GiveDefaultAmmo(client);
					
				CPrintToChat(client, "{blue}[{default}Weapon Limits{blue}]{default} This weapon group has reached its max of {green}%d", arrayEntry.LAE_iLimit);
				EmitSoundToClient(client, "player/suit_denydevice.wav");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public void OnIncap(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && GetClientTeam(client) == TEAM_SURVIVOR && IdentifyWeapon(GetPlayerWeaponSlot(client, 1)) == WEPID_MELEE)
	{
		bIsIncappedWithMelee[client] = true;
	}
}

public void OnRevive(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (client > 0 && bIsIncappedWithMelee[client])
	{
		bIsIncappedWithMelee[client] = false;
	}
}

public void OnDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && GetClientTeam(client) == TEAM_SURVIVOR && bIsIncappedWithMelee[client])
	{
		bIsIncappedWithMelee[client] = false;
	}
}

public void OnBotReplacedPlayer(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));
	if (!bot && GetClientTeam(bot) != TEAM_SURVIVOR)
		return;
	
	int player = GetClientOfUserId(event.GetInt("player"));
	bIsIncappedWithMelee[bot] = bIsIncappedWithMelee[player];
	bIsIncappedWithMelee[player] = false;
}

public void OnPlayerReplacedBot(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));
	if (!player && GetClientTeam(player) != TEAM_SURVIVOR)
		return;
	
	int bot = GetClientOfUserId(event.GetInt("bot"));
	bIsIncappedWithMelee[player] = bIsIncappedWithMelee[bot];
	bIsIncappedWithMelee[bot] = false;
}

stock int GetWeaponCount(const int[] mask)
{
	bool queryMelee = !!(mask[view_as<int>(WEPID_MELEE) / 32] & (1 << (view_as<int>(WEPID_MELEE) % 32)));
	
	int count;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i))
		{
			for (int j = 0; j < 5; ++j)
			{
				int wepid = view_as<int>(IdentifyWeapon(GetPlayerWeaponSlot(i, j)));
				if (mask[wepid/32] & (1 << (wepid % 32)) || (j == 1 && queryMelee && bIsIncappedWithMelee[i]))
				{
					++count;
				}
			}
		}
	}
	return count;
}

stock void GiveDefaultAmmo(int client)
{
	// NOTE:
	// Previously the plugin seems to cache an index of one ammo pile in current map, and is supposed to use it here.
	// For some reason, the caching never runs, and the code is completely wrong either.
	// Therefore, it has been consistently using an SDKCall like below ('0' should be the index of ammo pile).
	// However, since it actually has worked without error and crash for a long time, I would decide to leave it still.
	// If your server suffers from this, please try making use of the functions commented below.
	
	SDKCall(hSDKGiveDefaultAmmo, 0, client);
}

/*stock int FindAmmoSpawn()
{
	int entity = FindEntityByClassname(MaxClients+1, "weapon_ammo_spawn");
	if (entity != -1)
	{
		return entity;
	}
	//We have to make an ammo pile!
	return MakeAmmoPile();
}

stock int MakeAmmoPile()
{
	int ammo = CreateEntityByName("weapon_ammo_spawn");
	DispatchSpawn(ammo);
	LogMessage("No ammo pile found, creating one: %d", iAmmoPile);
	return ammo;
}*/
