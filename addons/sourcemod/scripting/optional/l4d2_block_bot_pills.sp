#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <actions>
#include <colors>

bool g_bExtensionActions;

ConVar g_cvDebugModeEnabled;

public Plugin myinfo =
{
	name = "[L4D2] Block Bot Pills",
	author = "B[R]UTUS",
	description = "Prohibits the use of pills to bots",
	version = "1.0.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	LoadTranslations("l4d2_block_bot_pills.phrases");
	// ====================
	// Validate extensions
	// ====================
	g_bExtensionActions = LibraryExists("actionslib");

	if (!g_bExtensionActions)
		SetFailState("\n==========\nMissing required extensions: \"Actions\".\nRead installation instructions again.\n==========");

	g_cvDebugModeEnabled = CreateConVar("l4d2_bbp_debug_enabled", "0", "Is debug mode enabled?");

	HookEvent("player_bot_replace", playerBotReplace_Event);
}

void playerBotReplace_Event(Event hEvent, char[] sEventName, bool dontBroadcast)
{
	int bot = GetClientOfUserId(hEvent.GetInt("bot"));

	if (bot < 1 || bot > MaxClients)
		return;

	char sWeapon[64];
	GetClientWeapon(bot, sWeapon, sizeof(sWeapon));

	if (strcmp(sWeapon[7], "pain_pills") == 0)
	{
		AcceptEntityInput(GetPlayerWeaponSlot(bot, 4), "Kill");

		int newPills = CreateEntityByName("weapon_pain_pills");
		DispatchSpawn(newPills);
		EquipPlayerWeapon(bot, newPills);

		if (g_cvDebugModeEnabled.BoolValue)
			CPrintToChatAll("%t", "L4D2BlockBotPills_BotBlockPillsPreventedAccidental", bot);
	}
}

// ====================================================================================================
//					ACTIONS EXTENSION
// ====================================================================================================
public void OnActionCreated(BehaviorAction action, int actor, const char[] name)
{
	/* Hooking take pills action (when bot wants to take pills) */
	if (strcmp(name, "SurvivorTakePills") == 0)
		action.OnStart = OnSelfActionPills;
}

public Action OnSelfActionPills(BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result)
{
	if (g_cvDebugModeEnabled.BoolValue)
		CPrintToChatAll("%t", "L4D2BlockBotPills_BotBlockPillsBotWants", actor);

	result.type = DONE;
	return Plugin_Changed;
}