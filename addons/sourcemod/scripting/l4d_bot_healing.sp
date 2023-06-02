/*
*	Bot Healing Values
*	Copyright (C) 2023 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION 		"2.2"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Bot Healing Values
*	Author	:	SilverShot
*	Descrp	:	Set the health value bots require before using First Aid, Pain Pills or Adrenaline.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=338889
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

2.2 (25-May-2023)
	- Fixed invalid client errors. Thanks to "Mystik Spiral" for reporting and "BHaType" for information.
	- Client could be 0 but hooking would still be valid, so removing team check works fine and is valid.

2.1 (20-Aug-2022)
	- Fixed the plugin not working on L4D2 Linux. GameData file has been updated.
	- Optimized the "Actions" part of the plugin.

2.0 (19-Aug-2022)
	- Changed the patching method to prevent crashes.
	- Now requires "SourceScramble" extension or "Actions" extension.
	- GameData is not required when only use the "Actions" extension.

	- Optionally uses the "Actions" extension to prevent healing until black and white.
	- Plugin is compatible with the "Heartbeat (Revive Fix - Post Revive Options)" plugin.

	- Thanks to "Forgetest" for helping and testing.
	- Thanks to "HarryPotter" and "Toranks" for testing.

1.1 (02-Aug-2022)
	- Fix for server crashing.

1.0 (01-Aug-2022)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#undef REQUIRE_EXTENSIONS
#include <sourcescramble>
#include <actions>
#define REQUIRE_EXTENSIONS



#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"l4d_bot_healing"


bool g_bLeft4Dead2;
ConVar g_hCvarPainPillsDecay, g_hCvarMaxIncap, g_hCvarFirst, g_hCvarPills, g_hCvarDieFirst, g_hCvarDiePills;
float g_fCvarPainPillsDecay, g_fCvarFirst, g_fCvarPills;
bool g_bCvarDieFirst, g_bCvarDiePills;
int g_iCvarMaxIncap;

MemoryPatch g_hPatchFirst1;
MemoryPatch g_hPatchFirst2;
MemoryPatch g_hPatchPills1;
MemoryPatch g_hPatchPills2;

// From "Heartbeat" plugin
bool g_bExtensionActions;
bool g_bExtensionScramble;
bool g_bPluginHeartbeat;
native int Heartbeat_GetRevives(int client);



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Bot Healing Values",
	author = "SilverShot",
	description = "Set the health value bots require before using First Aid, Pain Pills or Adrenaline.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=338889"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	MarkNativeAsOptional("Heartbeat_GetRevives");

	return APLRes_Success;
}

public void OnLibraryAdded(const char[] name)
{
	if( strcmp(name, "l4d_heartbeat") == 0 )
	{
		g_bPluginHeartbeat = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if( strcmp(name, "l4d_heartbeat") == 0 )
	{
		g_bPluginHeartbeat = false;
	}
}

public void OnPluginStart()
{
	// ====================
	// Validate extensions
	// ====================
	g_bExtensionActions = LibraryExists("actionslib");
	g_bExtensionScramble = GetFeatureStatus(FeatureType_Native, "MemoryPatch.CreateFromConf") == FeatureStatus_Available;

	if( !g_bExtensionActions && !g_bExtensionScramble )
	{
		SetFailState("\n==========\nMissing required extensions: \"Actions\" or \"SourceScramble\".\nRead installation instructions again.\n==========");
	}



	// ====================
	// Load GameData
	// ====================
	if( g_bExtensionScramble )
	{
		char sPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
		if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

		GameData hGameData = new GameData(GAMEDATA);
		if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);



		// ====================
		// Enable patches
		// ====================
		g_hPatchFirst1 = MemoryPatch.CreateFromConf(hGameData, "BotHealing_FirstAid_A");
		if( !g_hPatchFirst1.Validate() ) SetFailState("Failed to validate \"BotHealing_FirstAid_A\" target.");
		if( !g_hPatchFirst1.Enable() ) SetFailState("Failed to patch \"BotHealing_FirstAid_A\" target.");

		g_hPatchFirst2 = MemoryPatch.CreateFromConf(hGameData, "BotHealing_FirstAid_B");
		if( !g_hPatchFirst2.Validate() ) SetFailState("Failed to validate \"BotHealing_FirstAid_B\" target.");
		if( !g_hPatchFirst2.Enable() ) SetFailState("Failed to patch \"BotHealing_FirstAid_B\" target.");

		g_hPatchPills1 = MemoryPatch.CreateFromConf(hGameData, "BotHealing_Pills_A");
		if( !g_hPatchPills1.Validate() ) SetFailState("Failed to validate \"BotHealing_Pills_A\" target.");
		if( !g_hPatchPills1.Enable() ) SetFailState("Failed to patch \"BotHealing_Pills_A\" target.");

		g_hPatchPills2 = MemoryPatch.CreateFromConf(hGameData, "BotHealing_Pills_B");
		if( !g_hPatchPills2.Validate() ) SetFailState("Failed to validate \"BotHealing_Pills_B\" target.");
		if( !g_hPatchPills2.Enable() ) SetFailState("Failed to patch \"BotHealing_Pills_B\" target.");



		// ====================
		// Patch memory
		// ====================
		// First Aid
		StoreToAddress(g_hPatchFirst1.Address + view_as<Address>(2), GetAddressOfCell(g_fCvarFirst), NumberType_Int32);
		StoreToAddress(g_hPatchFirst2.Address + view_as<Address>(2), GetAddressOfCell(g_fCvarFirst), NumberType_Int32);

		// Pills
		StoreToAddress(g_hPatchPills1.Address + view_as<Address>(2), GetAddressOfCell(g_fCvarPills), NumberType_Int32);
		StoreToAddress(g_hPatchPills2.Address + view_as<Address>(2), GetAddressOfCell(g_fCvarPills), NumberType_Int32);
	}



	// ====================
	// ConVars
	// ====================
	if( !g_bLeft4Dead2 )
	{
		g_hCvarMaxIncap = FindConVar("survivor_max_incapacitated_count");
		g_hCvarMaxIncap.AddChangeHook(ConVarChanged_Cvars);
	}

	g_hCvarDieFirst = CreateConVar("l4d_bot_healing_die_first", "0", "0=游戏默认 1=只允许自己或目标是黑白状态时打包(需要'Actions'扩展)", CVAR_FLAGS);
	g_hCvarDiePills = CreateConVar("l4d_bot_healing_die_pills", "0", "0=游戏默认 1=只允许自己或目标是黑白状态时打包或给药(需要'Actions'扩展)", CVAR_FLAGS);
	g_hCvarFirst = CreateConVar("l4d_bot_healing_first", g_bLeft4Dead2 ? "15.0" : "15.0", "当bot血量低于此值时，允许其打包", CVAR_FLAGS);
	g_hCvarPills = CreateConVar("l4d_bot_healing_pills", g_bLeft4Dead2 ? "39.0" : "39.0", "当bot血量低于此值时，允许其吃药", CVAR_FLAGS);
	CreateConVar("l4d_bot_healing_version", PLUGIN_VERSION, "Bot Healing Values plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d_bot_healing");

	g_hCvarPainPillsDecay = FindConVar("pain_pills_decay_rate");
	g_hCvarPainPillsDecay.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFirst.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPills.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDieFirst.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDiePills.AddChangeHook(ConVarChanged_Cvars);
}

public void OnPluginEnd()
{
	if( g_bExtensionScramble )
	{
		g_hPatchFirst1.Disable();
		g_hPatchFirst2.Disable();
		g_hPatchPills1.Disable();
		g_hPatchPills2.Disable();
	}
}

public void OnConfigsExecuted()
{
	GetCvars();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	if( !g_bLeft4Dead2 )
		g_iCvarMaxIncap = g_hCvarMaxIncap.IntValue;

	g_bCvarDieFirst = g_hCvarDieFirst.BoolValue;
	g_bCvarDiePills = g_hCvarDiePills.BoolValue;

	g_fCvarFirst = g_hCvarFirst.FloatValue;
	g_fCvarPills = g_hCvarPills.FloatValue;

	g_fCvarPainPillsDecay = g_hCvarPainPillsDecay.FloatValue;
}



// ====================================================================================================
//					ACTIONS EXTENSION
// ====================================================================================================
public void OnActionCreated(BehaviorAction action, int actor, const char[] name)
{
    // Validate allowed
	if( !g_bCvarDieFirst && !g_bCvarDiePills )
		return;

	if( strncmp(name, "Survivor", 8) == 0 )
	{
		/* Hooking self healing action (when bot wants to heal self) */
		if( g_bCvarDieFirst && strcmp(name[8], "HealSelf") == 0 )
			action.OnStart = OnSelfActionFirst;

		/* Hooking friend healing action (when bot wants to heal someone) */
		else if( g_bCvarDieFirst && strcmp(name[8], "HealFriend") == 0 )
			action.OnStartPost = OnFriendActionFirst;

		/* Hooking take pills action (when bot wants to take pills) */
		else if( g_bCvarDiePills && strcmp(name[8], "TakePills") == 0 )
			action.OnStart = OnSelfActionPills;

		/* Hooking give pills action (when bot wants to give pills) */
		else if( g_bCvarDiePills && strcmp(name[8], "GivePillsToFriend") == 0 )
			action.OnStartPost = OnFriendActionPills;
	}
}

public Action OnSelfActionFirst(BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result)
{
	bool allow = g_bLeft4Dead2 ? GetEntProp(actor, Prop_Send, "m_bIsOnThirdStrike") == 1 : (g_bPluginHeartbeat ? Heartbeat_GetRevives(actor) : GetEntProp(actor, Prop_Send, "m_currentReviveCount")) >= g_iCvarMaxIncap;

	if( !g_bExtensionScramble && allow && GetClientHealth(actor) + L4D_GetPlayerTempHealth(actor) > g_fCvarFirst )
		allow = false;

	result.type = allow ? CONTINUE : DONE;
	return Plugin_Changed;
}

public Action OnSelfActionPills(BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result)
{
	bool allow = g_bLeft4Dead2 ? GetEntProp(actor, Prop_Send, "m_bIsOnThirdStrike") == 1 : (g_bPluginHeartbeat ? Heartbeat_GetRevives(actor) : GetEntProp(actor, Prop_Send, "m_currentReviveCount")) >= g_iCvarMaxIncap;

	if( !g_bExtensionScramble && allow && GetClientHealth(actor) + L4D_GetPlayerTempHealth(actor) > g_fCvarPills )
		allow = false;

	result.type = allow ? CONTINUE : DONE;
	return Plugin_Changed;
}

public Action OnFriendActionFirst(BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result)
{
	int target = action.Get(0x34) & 0xFFF;
	bool allow = g_bLeft4Dead2 ? GetEntProp(target, Prop_Send, "m_bIsOnThirdStrike") == 1 : (g_bPluginHeartbeat ? Heartbeat_GetRevives(target) : GetEntProp(target, Prop_Send, "m_currentReviveCount")) >= g_iCvarMaxIncap;

	if( !g_bExtensionScramble && allow && GetClientHealth(target) + L4D_GetPlayerTempHealth(target) > g_fCvarFirst )
		allow = false;

	result.type = allow ? CONTINUE : DONE;
	return Plugin_Changed;
}

public Action OnFriendActionPills(BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result)
{
	int target = action.Get(0x34) & 0xFFF;
	bool allow = g_bLeft4Dead2 ? GetEntProp(target, Prop_Send, "m_bIsOnThirdStrike") == 1 : (g_bPluginHeartbeat ? Heartbeat_GetRevives(target) : GetEntProp(target, Prop_Send, "m_currentReviveCount")) >= g_iCvarMaxIncap;

	if( !g_bExtensionScramble && allow && GetClientHealth(target) + L4D_GetPlayerTempHealth(target) > g_fCvarPills )
		allow = false;

	result.type = allow ? CONTINUE : DONE;
	return Plugin_Changed;
}



// ====================================================================================================
//					STOCK
// ====================================================================================================
stock int L4D_GetPlayerTempHealth(int client)
{
	int tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_fCvarPainPillsDecay)) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}