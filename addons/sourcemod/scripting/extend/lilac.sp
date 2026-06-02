/*
	Little Anti-Cheat
	Copyright (C) 2018-2021 J_Tanzanite

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#include <sourcemod>
#include <sdktools_engine>
#include <sdktools_entoutput>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <materialadmin>
#tryinclude <sourcebanspp>
#tryinclude <updater>
#include <tf2>
#include <tf2_stocks>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

// Include warnings:
#if !defined _updater_included
	#warning "updater.inc" include file not found, auto update functionality will not work!
#endif
#if !defined _sourcebanspp_included
	#warning "sourcebanspp.inc" include file not found, banning though SourceBans++ will not work!
#endif
#if !defined _materialadmin_included
	#warning "materialadmin.inc" include file not found, banning through Material-Admin will not work!
	#warning Включаемый файл "materialadmin.inc" не найден, бан через Material-Admin не будет работать!
#endif

#pragma semicolon 1
#pragma newdecls required

#include "lilac/lilac_globals.sp" // Must be at top, contains defines.

#include "lilac/lilac_aimbot.sp"
#include "lilac/lilac_aimlock.sp"
#include "lilac/lilac_angles.sp"
#include "lilac/lilac_anti_duck_delay.sp"
#include "lilac/lilac_backtrack.sp"
#include "lilac/lilac_bhop.sp"
#include "lilac/lilac_config.sp"
#include "lilac/lilac_convar.sp"
#include "lilac/lilac_database.sp"
#include "lilac/lilac_lerp.sp"
#include "lilac/lilac_macro.sp"
#include "lilac/lilac_noisemaker.sp"
#include "lilac/lilac_ping.sp"
#include "lilac/lilac_stock.sp"
#include "lilac/lilac_string.sp" // String takes care of chat and names.


public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};


public void OnPluginStart()
{
	char gamefolder[32];

	LoadTranslations("lilac.phrases.txt");

	GetGameFolderName(gamefolder, sizeof(gamefolder));
	if (StrEqual(gamefolder, "tf", false)) {
		ggame = GAME_TF2;

		HookEvent("post_inventory_application", event_inventoryupdate, EventHookMode_Post);
		HookEvent("player_teleported", event_teleported, EventHookMode_Post);
	}
	else if (StrEqual(gamefolder, "cstrike", false)) {
		ggame = GAME_CSS;
	}
	else if (StrEqual(gamefolder, "csgo", false)) {
		ggame = GAME_CSGO;

		if ((cvar_bhop = FindConVar("sv_autobunnyhopping")) != null) {
			force_disable_bhop = GetConVarInt(cvar_bhop);
			HookConVarChange(cvar_bhop, cvar_change);
		}
		else {
			// We weren't able to get the cvar,
			//     disable bhop checks just in case.
			force_disable_bhop = 1;

			PrintToServer("[Lilac] Unable to to find convar \"sv_autobunnyhopping\", bhop checks have been forcefully disabled.");
		}
	}
	else if (StrEqual(gamefolder, "left4dead2", false)) {
		ggame = GAME_L4D2;

		// Pitch AA isn't really used much in L4D2 afaik, plus,
		// 	like larrybrains reported, causes false positives for
		// 	the infected team memeber smoker.
		// Thanks to Larrybrains for reporting this!
		max_angles = view_as<float>({0.0, 0.0, 50.01});
	}
	else if (StrEqual(gamefolder, "left4dead", false)) {
		ggame = GAME_L4D;

		// Same as L4D2, the smoker handles pitch differently it seems.
		// Thanks to finishlast for reporting this!
		max_angles = view_as<float>({0.0, 0.0, 50.01});
	}
	else if (StrEqual(gamefolder, "dod", false)) {
		ggame = GAME_DODS;
	}
	else {
		ggame = GAME_UNKNOWN;
		PrintToServer("[Lilac] This game currently isn't supported, Little Anti-Cheat will still run, but expect some bugs and false positives/bans!");
	}

	if (ggame == GAME_TF2)
		HookEvent("player_death", event_player_death_tf2, EventHookMode_Pre);
	else
		HookEvent("player_death", event_player_death, EventHookMode_Pre);

	HookEvent("player_spawn", event_teleported, EventHookMode_Post);
	HookEvent("player_changename", event_namechange, EventHookMode_Post);

	HookEntityOutput("trigger_teleport", "OnEndTouch", map_teleport);

	// Default ban lengths are -1. (Global ConVar).
	for (int i = 0; i < CHEAT_MAX; i++)
		ban_length_overwrite[i] = -1;

	// Bans for Bhop last 1 month by default.
	ban_length_overwrite[CHEAT_BHOP] = 24 * 30 * 60;

	// Bans for Macros are 15 minutes by default.
	ban_length_overwrite[CHEAT_MACRO] = 15;

	// If sv_maxupdaterate is changed mid-game and then this plugin
	// 	is loaded, then it could lead to false positives.
	// Reset all stats on all players already in-game, but ignore lerp.
	// Also check players already in-game for noisemaker.
	for (int i = 1; i <= MaxClients; i++) {
		lilac_reset_client(i);
		lilac_lerp_ignore_nolerp_client(i);
		check_inventory_for_noisemaker(i);
	}

	forwardhandle = CreateGlobalForward("lilac_cheater_detected",
		ET_Ignore, Param_Cell, Param_Cell);
	forwardhandleban = CreateGlobalForward("lilac_cheater_banned",
		ET_Ignore, Param_Cell, Param_Cell);
	forwardhandleallow = CreateGlobalForward("lilac_allow_cheat_detection",
		ET_Event, Param_Cell, Param_Cell);

	CreateTimer(QUERY_TIMER, timer_query, _, TIMER_REPEAT);
	CreateTimer(5.0, timer_check_ping, _, TIMER_REPEAT);
	CreateTimer(5.0, timer_check_lerp, _, TIMER_REPEAT);
	CreateTimer(0.5, timer_check_aimlock, _, TIMER_REPEAT);
	CreateTimer(60.0 * 5.0, timer_decrement_macro, _, TIMER_REPEAT);

	tick_rate = RoundToNearest(1.0 / GetTickInterval());

	// Ignore low tickrates.
	macro_max = (tick_rate >= 60 && tick_rate <= MACRO_LOG_LENGTH) ? 20 : 0;

	if (tick_rate > 50) {
		bhop_settings_min[BHOP_INDEX_MIN] = 5;
		bhop_settings_min[BHOP_INDEX_MAX] = 10;
		bhop_settings_min[BHOP_INDEX_TOTAL] = 2;
	}
	else {
		bhop_settings_min[BHOP_INDEX_MIN] = 10;
		bhop_settings_min[BHOP_INDEX_MAX] = 20;
		bhop_settings_min[BHOP_INDEX_TOTAL] = 4;
	}
	bhop_settings_min[BHOP_INDEX_JUMP] = -1;

	// This sets up convars and such.
	lilac_config_setup();

	if (icvar[CVAR_LOG])
		lilac_log_first_time_setup();
}

public void OnAllPluginsLoaded()
{
	sourcebanspp_exist = LibraryExists("sourcebans++");
	materialadmin_exist = LibraryExists("materialadmin");

	if (LibraryExists("updater"))
		lilac_update_url();

	// Startup message.
	PrintToServer("[Little Anti-Cheat %s] Successfully loaded!", PLUGIN_VERSION);
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int err_max)
{
	// Been told this isn't needed, but just in case.
	MarkNativeAsOptional("SBPP_BanPlayer");
	MarkNativeAsOptional("MABanPlayer");
	MarkNativeAsOptional("Updater_AddPlugin");
	MarkNativeAsOptional("Updater_RemovePlugin");
	MarkNativeAsOptional("IRC_MsgFlaggedChannels");

	// Build the log path for the file in case the user has overridden sm_basepath. 
	BuildPath(Path_SM, log_file, sizeof(log_file), "logs/lilac.log");
	return APLRes_Success;
}

public void OnLibraryAdded(const char []name)
{
	if (StrEqual(name, "sourcebans++"))
		sourcebanspp_exist = true;
	else if (StrEqual(name, "materialadmin"))
		materialadmin_exist = true;
	else if (StrEqual(name, "updater"))
		lilac_update_url();
}

public void OnLibraryRemoved(const char []name)
{
	if (StrEqual(name, "sourcebans++"))
		sourcebanspp_exist = false;
	else if (StrEqual(name, "materialadmin"))
		materialadmin_exist = false;
}

void lilac_update_url()
{
#if defined _updater_included
	if (icvar[CVAR_AUTO_UPDATE]) {
		if (!NATIVE_EXISTS("Updater_AddPlugin")) {
			PrintToServer("Error: Native Updater_AddPlugin() not found! Check if updater plugin is installed.");
			return;
		}

		Updater_AddPlugin(UPDATE_URL);
	}
	else {
		if (!NATIVE_EXISTS("Updater_RemovePlugin")) {
			PrintToServer("Error: Native Updater_RemovePlugin() not found! Check if updater plugin is installed.");
			return;
		}

		Updater_RemovePlugin();
	}
#else
	PrintToServer("Error: Auto updater wasn't included when compiled, auto updating won't work!");
#endif
}

public void OnClientPutInServer(int client)
{
	lilac_reset_client(client);
	lilac_string_check_name(client);

	CreateTimer(30.0, timer_welcome, GetClientUserId(client));
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (condition == TFCond_Taunting)
		playerinfo_time_teleported[client] = GetGameTime();
	else if (condition == TFCond_HalloweenKart)
		playerinfo_time_bumpercart[client] = GetGameTime();
}

public Action event_teleported(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid", -1));

	if (is_player_valid(client))
		playerinfo_time_teleported[client] = GetGameTime();
	return Plugin_Continue;
}

public void map_teleport(const char[] output, int caller, int activator, float delay)
{
	if (!is_player_valid(activator) || IsFakeClient(activator))
		return;

	playerinfo_time_teleported[activator] = GetGameTime();
}

public Action timer_welcome(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	// Todo: Considering there are log-only options now...
	// Perhaps I should check if ANYTHING can ban at all.
	if (is_player_valid(client) && icvar[CVAR_WELCOME]
		&& icvar[CVAR_ENABLE] && icvar[CVAR_BAN])
		PrintToChat(client, "[Lilac] %T", "welcome_msg", client, PLUGIN_VERSION);
	return Plugin_Stop;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3],
				float angles[3], int& weapon, int& subtype, int& cmdnum,
				int& tickcount, int& seed, int mouse[2])
{
	static int lbuttons[MAXPLAYERS + 1];

	if (!is_player_valid(client) || IsFakeClient(client))
		return Plugin_Continue;

	// Increment the index.
	if (++playerinfo_index[client] >= CMD_LENGTH)
		playerinfo_index[client] = 0;

	// Store when the tick was processed.
	playerinfo_time_usercmd[client][playerinfo_index[client]] = GetGameTime();

	// Store information.
	lilac_backtrack_store_tickcount(client, tickcount);
	set_player_log_angles(client, angles, playerinfo_index[client]);
	playerinfo_buttons[client][playerinfo_index[client]] = buttons;
	playerinfo_actions[client][playerinfo_index[client]] = 0;

	if ((buttons & IN_ATTACK) && bullettime_can_shoot(client))
		playerinfo_actions[client][playerinfo_index[client]] |= ACTION_SHOT;

	if (icvar[CVAR_ENABLE]) {
		// Detect Anti-Duck-Delay.
		if (ggame == GAME_CSGO && icvar[CVAR_ANTI_DUCK_DELAY])
			lilac_anti_duck_delay_check(client, buttons);

		// Detect Angle-Cheats.
		if (icvar[CVAR_ANGLES])
			lilac_angles_check(client, angles);

		// Detect Macros.
		if (macro_max && icvar[CVAR_MACRO])
			lilac_macro_check(client, buttons, lbuttons[client]);

		// Detect bhop.
		if (!force_disable_bhop && icvar[CVAR_BHOP])
			lilac_bhop_check(client, buttons, lbuttons[client]);

		// Patch Angle-Cheats.
		if (icvar[CVAR_PATCH_ANGLES])
			lilac_angles_patch(angles);

		// Patch Backtracking.
		if (icvar[CVAR_BACKTRACK_PATCH])
			tickcount = lilac_backtrack_patch(client, tickcount);
	}

	lbuttons[client] = buttons;

	return Plugin_Continue;
}
