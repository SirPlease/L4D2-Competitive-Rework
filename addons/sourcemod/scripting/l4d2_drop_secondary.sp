#include <colors>
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

char sSecondary[MAXPLAYERS + 1][64];
char sMeleeScript[MAXPLAYERS + 1][64];

/*****************************************************************************************
*
*                          TODO:
*                  
******************************************************************************************
*
* - Use tries instead, fool.
* - Add a command for adding custom melees into the above mentioned tries.
*
*****************************************************************************************/

#define SECONDARY_PISTOL         "weapon_pistol"
#define SECONDARY_PISTOL_MAGNUM  "weapon_pistol_magnum"
#define SECONDARY_MELEE          "weapon_melee"

#define MELEE_NONE            "none"

ConVar l4d2_drop_secondary_debug;
bool bDebug;

public Plugin myinfo = 
{
	name = "L4D2 Drop Secondary",
	author = "Sir, ProjectSky (Initial Plugin by Jahze & Visor)",
	version = "1.1",
	description = "Testing Purposes"
}

public void OnPluginStart() 
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_use", Event_OnPlayerUse, EventHookMode_Post);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);

	HookEvent("player_bot_replace", Event_OnPlayerReplacedByBot);
	HookEvent("bot_player_replace", Event_OnBotReplacedByPlayer);

	l4d2_drop_secondary_debug = CreateConVar("l4d2_drop_secondary_debug", "0", "Enable Debugging? (Print out to all chat)", FCVAR_NONE, true, 0.0, true, 1.0);
	bDebug = l4d2_drop_secondary_debug.BoolValue;
	l4d2_drop_secondary_debug.AddChangeHook(DebugChanged);
}

/*****************************************************************************************
*
*           THESE ARE ONLY USED TO RESET A PLAYER'S STORED SECONDARY WEAPON/MELEE SCRIPT
*                  
*****************************************************************************************/
public void OnClientDisconnect(int client)
{
	sSecondary[client] = SECONDARY_PISTOL;
	sMeleeScript[client] = MELEE_NONE;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		sSecondary[i] = SECONDARY_PISTOL;
		sMeleeScript[i] = MELEE_NONE;
	}
}

/*****************************************************************************************
*
*                  THESE ARE USED TO MAKE SURE THE CORRECT PLAYER KEEPS 
*                          THEIR SECONDARY AND MELEE SCRIPT
*                  
*****************************************************************************************/
public void Event_OnPlayerReplacedByBot(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"))
	int player = GetClientOfUserId(event.GetInt("player"))

	sSecondary[bot] = sSecondary[player];
	sMeleeScript[bot] = sMeleeScript[player];
	sSecondary[player] = SECONDARY_PISTOL;
	sMeleeScript[player] = MELEE_NONE;

	if (bDebug) CPrintToChatAll("{green}[{olive}OnPlayerReplacedByBot{green}] {default}- {blue}BOT {default}replaced {blue}%N {default}({green}Secondary: {olive}%s{default})", player, sSecondary[bot]);
}

public void Event_OnBotReplacedByPlayer(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"))
	int player = GetClientOfUserId(event.GetInt("player"))

	sSecondary[player] = sSecondary[bot];
	sMeleeScript[player] = sMeleeScript[bot];
	sSecondary[bot] = SECONDARY_PISTOL;
	sMeleeScript[bot] = MELEE_NONE;

	if (bDebug) CPrintToChatAll("{green}[{olive}OnBotReplacedByPlayer{green}] {default}- {blue}%N {default}replaced {blue}BOT {default}({green}Secondary: {olive}%s{default})", player, sSecondary[player]);
}

/*****************************************************************************************
*
*                   THIS FIRES AND STORES A PLAYER'S SECONDARY
*                  
*****************************************************************************************/
public void Event_OnPlayerUse(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int targetid = event.GetInt("targetid");

	if (IsValidSurvivor(client) && IsValidEntity(targetid)) 
	{
		char sClassname[32];
		GetEntityClassname(targetid, sClassname, sizeof(sClassname))

		if (StrContains(sClassname, "pistol") != -1 ||
		StrContains(sClassname, "melee") != -1)
		{
			// We do an actual check of what the client has here because we deal with limitations in certain configs.
			// The limitation would cause the secondary to be set on the client while the client didn't even equip it.
			int iWeaponIndex = GetPlayerWeaponSlot(client, 1);

			if (IsValidEntity(iWeaponIndex))
			{
				char sWeaponName[32];
				GetEntityClassname(iWeaponIndex, sWeaponName, sizeof(sWeaponName));

				if (StrEqual(sWeaponName, "weapon_pistol")) sSecondary[client] = SECONDARY_PISTOL;
				else if (StrEqual(sWeaponName, "weapon_pistol_magnum")) sSecondary[client] = SECONDARY_PISTOL_MAGNUM;
				else if (StrEqual(sWeaponName, "weapon_melee")) DetermineMeleeScript(client, iWeaponIndex);

				if (bDebug) CPrintToChatAll("{green}[{olive}OnPlayerUse{green}] {default}- {blue}%N{default}'s picked up a secondary: ({green}Secondary: {olive}%s{default})", client, sSecondary[client]);
			}
		}
	}
}

/*****************************************************************************************
*
*           THIS IS USED TO STORE A PLAYER'S SECONDARY WEAPON ON INCAP, 
*                     IN CASE HE/SHE DIES WHILE INCAPACITATED
*                  
*****************************************************************************************/
public Action Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidSurvivor(victim))
	{
		if (bDebug) CPrintToChatAll("{green}[{olive}OnPlayerDeath{green}] {default}- {blue}%N {default}({green}Secondary: {olive}%s{default})", victim, sSecondary[victim]);
		SpawnSecondary(victim);
	}

	return Plugin_Continue;
}

bool IsValidSurvivor(int client) 
{ 
	if (client <= 0 
	|| client > MaxClients
	|| !IsClientInGame(client)) return false;
	return GetClientTeam(client) == 2; 
}

void SpawnSecondary(int client)
{
	int weapon;
	
	if (StrEqual(sSecondary[client], SECONDARY_PISTOL)) weapon = CreateEntityByName("weapon_pistol");
	else if (StrEqual(sSecondary[client], SECONDARY_PISTOL_MAGNUM)) weapon = CreateEntityByName("weapon_pistol_magnum");
	else 
	{
		if (StrEqual(sMeleeScript[client], MELEE_NONE))
		{
			CPrintToChat(client, "{blue}[{default}L4D2 Drop Secondary{blue}]{default}: {green}ERROR {default}- Something went wrong determining the melee script for your secondary weapon, report this issue to the {olive}Plugin Author{default}.");
			return;
		}

		weapon = CreateEntityByName("weapon_melee");
		if (weapon == -1) return;

		DispatchKeyValue(weapon, "melee_script_name", sMeleeScript[client]);
	}

	if (weapon != -1) 
	{
		DispatchSpawn(weapon);
		float vOrigin[3];
		GetClientEyePosition(client, vOrigin);
		TeleportEntity(weapon, vOrigin, NULL_VECTOR, NULL_VECTOR);
	}
}

void DetermineMeleeScript(int client, int iWeaponIndex)
{
	sSecondary[client] = SECONDARY_MELEE;
	char buffScriptName[64];
	GetEntPropString(iWeaponIndex, Prop_Data, "m_strMapSetScriptName", buffScriptName, sizeof(buffScriptName));

	sMeleeScript[client] = buffScriptName;

	if (bDebug) CPrintToChatAll("{green}[{olive}DetermineMeleeScript{green}] {default}- {blue}%N {default}has {olive}%s {default}- MS: {olive}%s", client, buffScriptName, sMeleeScript[client]);
}

public void DebugChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bDebug = l4d2_drop_secondary_debug.BoolValue;
	CPrintToChatAll("{blue}[{default}L4D2 Drop Secondary{blue}]{default}: {green}Debugging {olive}%s", bDebug ? "Enabled" : "Disabled");
}
