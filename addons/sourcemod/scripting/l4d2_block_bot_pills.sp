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
	version = "1.0",
	url = "https://steamcommunity.com/id/8ru7u5/"
}

public void OnPluginStart()
{
	// ====================
	// Validate extensions
	// ====================
	g_bExtensionActions = LibraryExists("actionslib");

	if (!g_bExtensionActions)
		SetFailState("\n==========\nMissing required extensions: \"Actions\".\nRead installation instructions again.\n==========");

	g_cvDebugModeEnabled = CreateConVar("l4d2_bbp_debug_enabled", "0", "Is debug mode enabled?");
}

// ====================================================================================================
//					ACTIONS EXTENSION
// ====================================================================================================
public void OnActionCreated(BehaviorAction action, int actor, const char[] name)
{
    /* Hooking take pills action (when bot wants to take pills) */
	if (strcmp(name[8], "TakePills") == 0)
		action.OnStart = OnSelfActionPills;
}

public Action OnSelfActionPills(BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result)
{
    if (g_cvDebugModeEnabled.BoolValue)
        CPrintToChatAll("{green}[{default}Bot Block Pills{green}]{default}: Bot {blue}%N{default} wants to use pain pills. Blocking this action...", actor);

    result.type = DONE;
    return Plugin_Changed;
}