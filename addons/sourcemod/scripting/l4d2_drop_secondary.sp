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
#define MELEE_FIREAXE         "fireaxe"
#define MELEE_FRYING_PAN      "frying_pan"
#define MELEE_MACHETE         "machete"
#define MELEE_BASEBALL_BAT    "baseball_bat"
#define MELEE_CROWBAR         "crowbar"
#define MELEE_CRICKET_BAT     "cricket_bat"
#define MELEE_TONFA           "tonfa"
#define MELEE_KATANA          "katana"
#define MELEE_ELECTRIC_GUITAR "electric_guitar"
#define MELEE_GOLFCLUB        "golfclub"
#define MELEE_SHIELD          "riotshield"
#define MELEE_KNIFE           "hunting_knife"
#define MELEE_PITCHFORK       "pitchfork"
#define MELEE_SHOVEL          "shovel"

#define MODEL_V_FIREAXE "models/weapons/melee/v_fireaxe.mdl"
#define MODEL_V_FRYING_PAN "models/weapons/melee/v_frying_pan.mdl"
#define MODEL_V_MACHETE "models/weapons/melee/v_machete.mdl"
#define MODEL_V_BASEBALL_BAT "models/weapons/melee/v_bat.mdl"
#define MODEL_V_CROWBAR "models/weapons/melee/v_crowbar.mdl"
#define MODEL_V_CRICKET_BAT "models/weapons/melee/v_cricket_bat.mdl"
#define MODEL_V_TONFA "models/weapons/melee/v_tonfa.mdl"
#define MODEL_V_KATANA "models/weapons/melee/v_katana.mdl"
#define MODEL_V_ELECTRIC_GUITAR "models/weapons/melee/v_electric_guitar.mdl"
#define MODEL_V_GOLFCLUB "models/weapons/melee/v_golfclub.mdl"
#define MODEL_V_SHIELD "models/weapons/melee/v_riotshield.mdl"
#define MODEL_V_KNIFE "models/v_models/v_knife_t.mdl"
#define MODEL_V_PITCHFORK "models/weapons/melee/v_pitchfork.mdl"
#define MODEL_V_SHOVEL "models/weapons/melee/v_shovel.mdl"

ConVar l4d2_drop_secondary_debug;
bool bDebug;

public Plugin myinfo = 
{
	name = "L4D2 Drop Secondary",
	author = "Sir (Initial Plugin by Jahze & Visor)",
	version = "1.0",
	description = "Testing Purposes"
}

public void OnPluginStart() 
{
	HookEvent("round_start", Event_RoundStart);
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

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
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
public Action Event_OnPlayerReplacedByBot(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"))
	int player = GetClientOfUserId(event.GetInt("player"))

	sSecondary[bot] = sSecondary[player];
	sMeleeScript[bot] = sMeleeScript[player];
	sSecondary[player] = SECONDARY_PISTOL;
	sMeleeScript[player] = MELEE_NONE;

	if (bDebug) CPrintToChatAll("{green}[{olive}OnPlayerReplacedByBot{green}] {default}- {blue}BOT {default}replaced {blue}%N {default}({green}Secondary: {olive}%s{default})", player, sSecondary[bot]);
}

public Action Event_OnBotReplacedByPlayer(Event event, const char[] name, bool dontBroadcast)
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
public Action Event_OnPlayerUse(Event event, const char[] name, bool dontBroadcast) 
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
	char buffSecondary[64];
	GetEntPropString(iWeaponIndex, Prop_Data, "m_ModelName", buffSecondary, sizeof(buffSecondary));

	if (StrEqual(buffSecondary, MODEL_V_FIREAXE))
	{
		sMeleeScript[client] = MELEE_FIREAXE;
	}
	else if (StrEqual(buffSecondary, MODEL_V_FRYING_PAN))
	{
		sMeleeScript[client] = MELEE_FRYING_PAN;
	}
	else if (StrEqual(buffSecondary, MODEL_V_MACHETE))
	{
		sMeleeScript[client] = MELEE_MACHETE;
	}
	else if (StrEqual(buffSecondary, MODEL_V_BASEBALL_BAT))
	{
		sMeleeScript[client] = MELEE_BASEBALL_BAT;
	}
	else if (StrEqual(buffSecondary, MODEL_V_CROWBAR))
	{
		sMeleeScript[client] = MELEE_CROWBAR;
	}
	else if (StrEqual(buffSecondary, MODEL_V_CRICKET_BAT))
	{
		sMeleeScript[client] = MELEE_CRICKET_BAT;
	}
	else if (StrEqual(buffSecondary, MODEL_V_TONFA))
	{
		sMeleeScript[client]  = MELEE_TONFA;
	}
	else if (StrEqual(buffSecondary, MODEL_V_KATANA))
	{
		sMeleeScript[client] = MELEE_KATANA;
	}
	else if (StrEqual(buffSecondary, MODEL_V_ELECTRIC_GUITAR))
	{
		sMeleeScript[client] = MELEE_ELECTRIC_GUITAR;
	}
	else if (StrEqual(buffSecondary, MODEL_V_GOLFCLUB))
	{
		sMeleeScript[client] = MELEE_GOLFCLUB;
	}
	else if (StrEqual(buffSecondary, MODEL_V_SHIELD))
	{
		sMeleeScript[client] = MELEE_SHIELD;
	}
	else if (StrEqual(buffSecondary, MODEL_V_KNIFE))
	{
		sMeleeScript[client] = MELEE_KNIFE;
	}
	else if (StrEqual(buffSecondary, MODEL_V_PITCHFORK))
	{
		sMeleeScript[client] = MELEE_PITCHFORK;
	}
	else if (StrEqual(buffSecondary, MODEL_V_SHOVEL))
	{
		sMeleeScript[client] = MELEE_SHOVEL;
	}
	else sMeleeScript[client] = MELEE_NONE;

	if (bDebug) CPrintToChatAll("{green}[{olive}DetermineMeleeScript{green}] {default}- {blue}%N {default}has {olive}%s {default}- MS: {olive}%s", client, buffSecondary, sMeleeScript[client]);
}

public void DebugChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bDebug = l4d2_drop_secondary_debug.BoolValue;
	CPrintToChatAll("{blue}[{default}L4D2 Drop Secondary{blue}]{default}: {green}Debugging {olive}%s", bDebug ? "Enabled" : "Disabled");
}