/*
*	Gear Transfer
*	Copyright (C) 2024 Silvers
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



#define PLUGIN_VERSION		"2.36"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Gear Transfer
*	Author	:	SilverShot
*	Descrp	:	Survivor bots can automatically pickup and give items. Players can switch, grab or give items.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=137616
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

2.36 (15-Dec-2024)
	- Now fires the "spawner_give_item" event where required. Thanks to "little_froy" for updating.

2.35 (05-Nov-2024)
	- Fixed invalid client error, likely due to 3rd party plugin. Thanks to "voledar" for reporting.

2.34 (17-Jun-2024)
	- Fixed compile errors on SM 1.12. Thanks to "TheStarRocker" for reporting.

2.33 (28-Jan-2024)
	- Fixed memory leak caused by clearing StringMap/ArrayList data instead of deleting.

2.32 (20-Dec-2023)
	- Added cvar "l4d_gear_transfer_start" to block auto grab/give for a specified time on round start. Requested by "Iciaria".

2.31 (27-Jul-2023)
	- Fixed compile error on SourceMod version 1.12. Thanks to "ur5efj" for reporting.

2.30 (25-May-2023)
	- Fixed items not always equipping and possibly the rare bug of them being stuck under players feet. Thanks to "little_froy" for reporting.

2.29 (20-Jan-2023)
	- Reverted change that broke equipping items on some servers. Thanks to "MilanesaTM" for reporting.

2.28b (07-Jan-2023)
	- Fixed incorrect Simplified Chinese translations. Thanks to "apples1949" and "a2121858" for reporting.

2.28 (25-Dec-2022)
	- Added Simplified Chinese translations. Thanks to "NoroHime" and "a2121858" for providing.
	- Added cvar "l4d_gear_transfer_notifies" to determine the types of transfers that will be notified in chat. Requested by "Yabi".
	- Changed cvar "l4d_gear_transfer_notify" added an option to only print to participants of transfers and an option to ignore pills/adrenaline transfers. Requested by "Yabi".

2.27 (25-Aug-2022)
	- Fixed property not found errors. Thanks to "haiping567" and "Dominatez" for reporting.

2.26 (19-Aug-2022)
	- Fixed plugin not loading without "Heartbeat" plugin due to the last update. Thanks to "alasfourom" for reporting.

2.25 (19-Aug-2022)
	- Added cvar "l4d_gear_transfer_dying" to only give healing items when someone is black and white.
	- This option is compatible with the "Heartbeat (Revive Fix - Post Revive Options)" plugin.

2.24 (10-Aug-2022)
	- Bots no longer give health items when using it themselves. Requested by "TBK Duy".

2.23 (15-Jun-2022)
	- Changed cvar "l4d_gear_transfer_notify" to allow notifications when pills or adrenaline are transferred using the games system. Requested by "Shadowart".

2.22 (08-Jun-2022)
	- Added cvar "l4d_gear_transfer_idle" to control if items can be transferred with players who are idle. Requested by "Gold Fish".
	- Fixed not being able to give items to bots on some servers. Thanks to "Zheldorg" for reporting and "KoMiKoZa" for a server to test on.

2.21 (01-Mar-2022)
	- Fixed event errors from the last update in L4D1. Thanks to "Krufftys Killers" for reporting.

2.20 (01-Mar-2022)
	- Plugin now fires the "give_weapon" and "weapon_given" events. Requested by "NoroHime".

2.19 (19-Oct-2021)
	- Fixed "Invalid edict" error when creating items to give. Thanks to "TBK Duy" for reporting.

2.18 (18-Sep-2021)
	- Fixed round end breaking the plugin due to the last update. Thanks to "TBK Duy" for reporting.

2.17 (18-Sep-2021)
	- Now only blocks reload if transferring with the reload key until released or maximum of 0.4 seconds. Thanks to "Ja-Forces" for reporting.
	- Added forwards "GearTransfer_OnWeaponGive", "GearTransfer_OnWeaponGrab"and "GearTransfer_OnWeaponSwap" to notify plugins when something happens.
	- Compatibility with "Survivor Shove" plugin version 1.11 or newer.

2.16 (06-Sep-2021)
	- Fixed the last update creating a ghost weapon attached between players legs. Thanks to "ddd123" for reporting.

2.15 (02-Sep-2021)
	- Fixed the weapon slots equip icon not displaying like older versions. Thanks to "TBK Duy" for reporting.

2.14 (25-Jul-2021)
	- New translation files added (please update them all). Thanks to "imyz" for re-working the translations.
	- Compatibility support for the "Survivor Shove" plugin (version 1.10 or newer).

2.13 (26-Feb-2021)
	- Blocked reloading weapons when transferring with the Reload key. Thanks to "bazrael" for reporting.

2.12 (30-Sep-2020)
	- Fixed compile errors on SM 1.11.

2.11 (26-Jun-2020)
	- Fixed right click passing conflict with "Prototype Grenades" plugin. Thanks to "fbef0102" for fixing.

2.10 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.

2.9 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

2.8 (28-Feb-2020)
	- Fixed duplicating weapons bug (bots picking invisible _spawn items). Thanks to "ridiculousties" for reporting.
	- Fixed clients swapping to pistols. Thanks to "TiTz" for reporting.
	- Switching grenades now keeps the grenade equipped.

2.7 (11-Feb-2020)
	- Fixed switching first aid with bots instead of healing them.
	- Fixed bots auto giving straight away after you gave them adrenaline/pills.
	- Fixed players instantly grabbing from bots after they gave adrenaline/pills.

2.6 (06-Jan-2020)
	- Fixed not being able to grab adrenaline/pills from shoving. Thanks to "KillerBudgie" for reporting.

2.5 (05-Jan-2020)
	- Added additional checks to prevent OnWeaponEquip errors. Thanks to "Mr. Man" for reporting.

2.4 (09-Nov-2019)
	- Fixed Molotov idle sound not stopping on transfer. Thanks to "ceasedU" for reporting.
	- Fixed not picking up items in Survival/after round restart due to last version fixes.

2.3 (09-Nov-2019)
	- Fixed "Invalid memory access". Thanks to "Lux" for reporting.
	- Fixed bots not always picking up items.

2.2 (04-Nov-2019)
	- Additional optimization for L4D1.

2.1 (01-Nov-2019)
	- Fixed error from missing event "weapon_drop" in L4D1. Thanks to "Dragokas" for reporting.

2.0 (01-Nov-2019)
	- Plugin overhauled and optimized. Several times faster than the previous version.
	- Profiler used to determine the best procedures for least CPU cycles.
	- Auto give/grab features and item exchange with reload/shove key is much more optimized.
	- Cvars have been changed, added, removed and renamed. Please delete or backup and update your old cvars config.

	- Thanks to "Lux" for testing and lots of advice and ideas on optimizing.
	- Thanks to "Dragokas" and "disawar1" for testing.

1.6.5 (21-Oct-2019)
	- Fixed invalid entity errors from "Prototype Grenades" support changes. Thanks to "Dragokas" for reporting.

1.6.4 (18-Oct-2019)
	- Blocks transferring items when pressing Shoot + Shove, to support "Prototype Grenades" plugin.

1.6.3 (10-Oct-2019)
	- Added support for "Prototype Grenades" plugin.

1.6.2 (19-Aug-2019)
	- Prevents auto grab and auto give during intro cut scenes.

1.6.1.1 (09-May-2019) (Dragokas)
	- Added detection of sex additionally by character (for custom models).

1.6.1 (14-Aug-2018)
	- Removed LogError "Tracer Bug".

1.6.0 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed cvar "l4d_gear_transfer_modes_tog" now supports L4D1.

1.5.12 (17-Jul-2017)
	- Fixed invalid entity error - Thanks to "Newbie_Sexy" for reporting and "Visual77" for some code.

1.5.11 (25-Jun-2017)
	- Fixed client not connected errors - Thanks to "Lux" for reporting.
	- Fixed depreciated FCVAR_PLUGIN flag.

1.5.10 (10-May-2012)
	- Added Traditional Chinese translations - Thanks to "bazrael".
	- Added cvar "l4d_gear_transfer_vocalize" to control transfer vocalizes - Thanks to "bazrael" for the request.

1.5.9 (31-Mar-2012)
	- Fixed the last update breaking auto give and auto grab.

1.5.8 (30-Mar-2012)
	- Added Russian translations - Thanks to "disawar1".
	- Added cvar "l4d_gear_transfer_modes_on" to control which game modes the plugin works in.
	- Added cvar "l4d_gear_transfer_modes_tog" same as above, but only works for L4D2.

1.5.7 (18-Oct-2011)
	- Fires the item_pickup and player_use events when bots auto grab. Required for Footlocker Spawner 1.2+.

1.5.6 (20-Apr-2011)
	- Added cvar 'l4d_gear_transfer_modes_off' to turn off the plugin on certain game modes.
	- Fixed deleting grenade spawns which give infinite items.

1.5.5 (30-Jan-2011)
	- Changed the bot allow cvars (as requested by "LTR.2") so you can specify which items bots auto give/grab.

1.5.4 (06-Jan-2011)
	- Another attempt to fix 'm_humanSpectatorUserID' errors.
	- Added chat notifications block from round start the same as vocalize block.

1.5.3 (04-Jan-2011)
	- Changed the previous check to make sure the netclass is 'SurvivorBot', should stop all related errors.

1.5.2 (02-Jan-2011)
	- Added check for 'bebop_bot_fakeclient' which caused errors.
	- Removed the -attack2 after shoves thanks to Valve patching some client commands.

1.5.1 (09-Dec-2010)
	- Added IsVisibleTo for player to player transfers (stops transfers through walls!).
	- Fixed auto give transferring directly after a player to player transfer.

1.5.0 (03-Dec-2010)
	- Optimized a lot code.
	- Fixed allow cvars not restricting their correct items.
	- Added cvar 'l4d_gear_transfer_modes' to disable auto give/grab in listed game modes.
	- Added cvar 'l4d_gear_transfer_timer_item' to specify how often the auto grab item list updates.
	- Added delay to auto give when switching items with bots.
	- Added vocalize block for 60 seconds from round start.
	- Added check for translation file.
	- Added finale_vehicle_leaving event to disable auto give/grab.
	- Added notifications for auto give/grab when 'l4d_gear_transfer_notify' is enabled.
	- Removed hint text when l4d_gear_transfer_notify set to 2. Now only shows chat notifications.

1.4.11 (27-Oct-2010)
	- Added ("-attack2") to stop shoving after successful transfer.
	- Added FCVAR_DONTRECORD flag to the version cvar.

1.4.10 (21-Oct-2010)
	- Fixed 'switch' translation being given the wrong weapon name.
	- Changed weapon name text color to yellow.

1.4.9 (19-Oct-2010)
	- Fixed player_shoved transfers not working because of a missing exclamation mark!

1.4.8 (16-Oct-2010)
	- Fixed Infected receiving items.

1.4.7 (16-Oct-2010)
	- Optimized auto give a little.

1.4.6 (16-Oct-2010)
	- Re-added FileExists check for scenes, now using Valve's Filesystem!
	- Small changes.

1.4.5 (14-Oct-2010)
	- Re-added player_shoved event to transfer items.
	- Removed FileExists check from scenes, now vocalizes L4D1 characters!

1.4.4 (12-Oct-2010)
	- Fixed creating dupe grenades when throwing.

1.4.3 (12-Oct-2010)
	- Fixed AutoTimer rubbish!
	- Stopped auto give/grab when survivor is incapped/reviving.

1.4.2 (10-Oct-2010)
	- Small fixes.

1.4.1 (07-Oct-2010)
	- Added displaying transfers in chat messages with translations.
	- Changed some vocalize parts for The Sacrifice update.

1.4.0.1 (03-Oct-2010)
	- Fixed disabling shove transfers with first aid.

1.4.0 (03-Oct-2010)
	- Officially supports the first Left4Dead!
	- Added check so bots will not auto grab "projectile" grenades.
	- Added check so bots will not auto grab items who have owners.
	- Added cvars to allow/disallow bots to auto give/grab certain items.
	- Changed cvars to comply with releasing guidelines.
	- Idle players no longer treated as bots.

1.3.0 (01-Oct-2010)
	- Small changes to auto grab.

1.2.9 (29-Sep-2010)
	- Disabled transfers with incapacitated players.
	- Fixed disabling auto give/grab in versus.
	- Changed the fix for auto grab creating two grenades again.
	- Removed player_shoved event, reload+shove transfer from OnPlayerRunCmd.

1.2.8 (27-Sep-2010)
	- Changed the fix for auto grab creating two grenades.

1.2.7 (27-Sep-2010)
	- Fixed auto grab creating two grenades!
	- Delaying all bots for 3 seconds after they receive an item.

1.2.6 (26-Sep-2010)
	- Optimized code.
	- TraceFilter added on survivors so they don't block transfers.

1.2.5 (22-Sep-2010)
	- Delayed bots auto give for 3 seconds after they are given an item.

1.2.4 (21-Sep-2010)
	- Fixed auto give when sb_all_bot_team.

1.2.3 (21-Sep-2010)
	- Added weapon_given hook to stop pills/adrenaline being given back!

1.2.2 (21-Sep-2010)
	- Minor changes.

1.2.1 (21-Sep-2010)
	- Added adrenaline and pain pills to transfers. You can only use the reload key to switch.
	- Added cvars to allow/disallow the above transfers.
	- Added vocalize on first aid kit transfers.

1.2.0 (19-Sep-2010)
	- Renamed more appropriately to "Gear Transfer".
	- Added defibrillators, first aid kits, explosive and incendiary rounds to transfers.
	- Added cvars to allow/disallow the transfer of certain items.
	- Changed the transfer being triggered by the Use key to the Reload key.
	- Disabled auto give/grab in versus games (as they should be full with players!).

1.1.2 (15-Sep-2010)
	- Removed HookSingleEntityOutput, which was causing crashes.

1.1.1 (11-Sep-2010)
	- Some fixes.

1.1.0 (09-Sep-2010)
	- Added "AtomicStryker"'s Vocalize with scenes.

1.03.0 (08-Sep-2010)
	- Removed Vocalize stuff.

1.02.0 (08-Sep-2010)
	- Changed things "AtomicStryker" suggested.

1.0.1 (08-Sep-2010)
	- Fixed UnhookEvent error.
	- Added check in case of over 64 grenades.

1.0.0 (07-Sep-2010)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "DJ_WEST" for "[L4D/L4D2] Grenade Transfer"
	https://forums.alliedmods.net/showthread.php?t=122293

*	Thanks to "AtomicStryker" for "[L4D & L4D2] Boomer Splash Damage"
	https://forums.alliedmods.net/showthread.php?t=98794

*	Thanks to "Crimson_Fox" for "[L4D2] Weapon Unlock"
	https://forums.alliedmods.net/showthread.php?t=114296

*	Thanks to "AtomicStryker" for "L4D2 Vocalize ANYTHING"
	https://forums.alliedmods.net/showthread.php?t=122270

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>
#include <sdktools>
#include <sdkhooks>

// Benchmarking: 0=Off. 1=Debug spew. 2=Include Auto Give/Grab timer benchmarking.
// Auto Give/Grab functions can exit leaving profiler enabled. I don't care to waste time fixing this.
// This should only be used for testing and not on a live server as the profiler and spew will cause excess lag.
#define BENCHMARK				0
#if BENCHMARK
	#include <profiler>
	Handle g_Profiler;

	#if BENCHMARK == 2
		static float g_fBenchGiveMin;
		static float g_fBenchGiveAvg;
		static float g_fBenchGiveMax;
		static int g_iBenchGiveTicks;
		static float g_fBenchGrabMin;
		static float g_fBenchGrabAvg;
		static float g_fBenchGrabMax;
		static int g_iBenchGrabTicks;
		static bool g_bProfiling;
	#endif
#endif



#define CVAR_FLAGS				FCVAR_NOTIFY
#define MAX_TYPES				9

#define SOUND_BIGREWARD			"UI/BigReward.wav"			// Give
#define SOUND_LITTLEREWARD		"UI/LittleReward.wav"		// Receive
#define SOUND_MOLOTOV_IDLE		")weapons/molotov/fire_idle_loop_1.wav" // ")" intentional.


// Cvar handles
ConVar g_hCvarAllow, g_hCvarDying, g_hCvarDistGive, g_hCvarDistGrab, g_hCvarGive, g_hCvarGrab, g_hCvarIdle, g_hCvarMethod, g_hCvarModesBot, g_hCvarModesOn, g_hCvarModesOff, g_hCvarModesTog, g_hCvarNotify, g_hCvarNotifies, g_hCvarSounds, g_hCvarStart, g_hCvarTimeout, g_hCvarTimerGive, g_hCvarTimerGrab, g_hCvarTraces, g_hCvarTypes, g_hCvarVocalize;
ConVar g_hCvarMPGameMode, g_hCvarMaxIncap;

// Cvar variables
int g_iCvarMaxIncap, g_iCvarDying, g_iCvarGive, g_iCvarGrab, g_iCvarMethod, g_iCvarNotify, g_iCvarNotifies, g_iCvarTypes, g_iCvarTraces, g_iCvarVocalize;
bool g_bCvarSounds, g_bCvarIdle;
float g_fDistGive, g_fDistGrab, g_fCvarStart, g_fTimerGive, g_fTimerGrab, g_fCvarTimeout, g_fBlockVocalize, g_fStartTime;

// Variables
bool g_bCvarAllow, g_bMapStarted, g_bModeOffAuto, g_bRoundOver, g_bRoundIntro, g_bTranslation, g_bTranslationNew, g_bLeft4Dead2;

GlobalForward g_hForwardGive, g_hForwardGrab, g_hForwardSwap;

// Timer handles
Handle g_hTimerGrab, g_hTimerGive;

// From "Heartbeat" plugin
bool g_bPluginHeartbeat;
native int Heartbeat_GetRevives(int client);

// Arrays for entities
float g_fNextTransfer[MAXPLAYERS+1];	// Next time allowed to transfer
float g_fReloadTime[MAXPLAYERS+1];		// When holding the reload key
float g_fEquipTime[MAXPLAYERS+1];		// Equipped time, to prevent drop event firing on some servers
int g_iClientItem[MAXPLAYERS+1][3];		// Store item entity index for each slot
int g_iClientType[MAXPLAYERS+1][3];		// Store item type
ArrayList g_ListMeds; // List of item entities from OnEntityCreated
ArrayList g_ListNade;
ArrayList g_ListPack;
ArrayList g_TypeMeds; // Item type index after string checking
ArrayList g_TypeNade;
ArrayList g_TypePack;

// Enums for code legibility
enum
{
	SLOT_NADE		= 2,
	SLOT_PACK		= 3,
	SLOT_MEDS		= 4
}

enum
{
	EMPTY_NADE		= (1<<0),
	EMPTY_PACK		= (1<<1),
	EMPTY_MEDS		= (1<<2)
}

enum
{
	METHOD_NONE		= 0,
	METHOD_GIVE		= (1<<0),
	METHOD_GRAB		= (1<<1),
	METHOD_SWAP		= (1<<2)
}

enum
{
	NOTIFY_GIVE		= (1<<0),
	NOTIFY_GRAB		= (1<<1),
	NOTIFY_SWITCH	= (1<<2)
}

enum
{
	NOTIFY_ALL		= (1<<0),	// PrintToChatAll
	NOTIFY_EVENT	= (1<<1),	// Print games transfer event
	NOTIFY_CLIENT	= (1<<2),	// Print client only
	NOTIFY_IGNORE	= (1<<3)	// Ignore printing pills/adrenaline and use game prompt only
}

enum
{
	TYPE_ADREN,
	TYPE_PILLS,
	TYPE_MOLO,
	TYPE_PIPE,
	TYPE_VOMIT,
	TYPE_FIRST,
	TYPE_EXPLO,
	TYPE_INCEN,
	TYPE_DEFIB
}



// ORDER GRAB/GIVE:
// Items are picked up in order defined by "g_sPickups" array. Only re-arrange items within their slot positions.
// Eg adrenaline and pills are one slot, grenades another and packs another.
// The slot order must remain as: MEDS, NADE, PACK. This order cannot be changed.
// Given the choice of 3 items from 3 different slots, bots will choose meds, then grenades, then packs.

// To change the order of grabbing / giving items you must:
// 1. Re-arrange aboves "TYPE_*" enum to match "g_sPickups" array below.
// 2. Change the "TOP_INDEX_*" to the last entry for each slot.
// Eg: TYPE_VOMIT is the last entry for grenades, TYPE_DEFIB the last entry for packs.
// If you move TYPE_DEFIB up, the last entry would be TYPE_INCEN or whichever your custom order specifies.
#define	TOP_INDEX_MEDS		TYPE_PILLS
#define	TOP_INDEX_NADE		TYPE_VOMIT
#define	TOP_INDEX_PACK		TYPE_DEFIB

// Items to transfer:
static const char g_sPickups[9][] =
{
	"weapon_adrenaline",
	"weapon_pain_pills",
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar",
	"weapon_first_aid_kit",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary",
	"weapon_defibrillator"
};

int g_Lengths[9];

// Vocalize for Left 4 Dead 2
static const char g_Coach[8][] =
{
	"takepipebomb01", "takepipebomb02", "takepipebomb03", "takemolotov01", "takemolotov02", "takefirstaid01", "takefirstaid02", "takefirstaid03"
};
static const char g_Ellis[15][] =
{
	"takepipebomb01", "takepipebomb02", "takepipebomb03", "takemolotov01", "takemolotov02", "takemolotov03", "takemolotov04", "takemolotov05",
	"takemolotov06", "takemolotov07", "takemolotov08", "takefirstaid01", "takefirstaid02", "takefirstaid03", "takefirstaid04"
};
static const char g_Nick[9][] =
{
	"takepipebomb01", "takepipebomb02", "takemolotov01", "takemolotov02", "takefirstaid01", "takefirstaid02", "takefirstaid03", "takefirstaid04",
	"takefirstaid05"
};
static const char g_Rochelle[9][] =
{
	"takepipebomb01", "takepipebomb02", "takemolotov01", "takemolotov02", "takemolotov03", "takemolotov04", "takefirstaid01", "takefirstaid02",
	"takefirstaid03"
};

// Vocalize for Left 4 Dead
static const char g_Bill[10][] =
{
	"TakePipeBomb01", "TakePipeBomb02", "TakePipeBomb03", "TakePipeBomb04", "TakeMolotov01", "TakeMolotov02", "TakeMolotov03", "TakeFirstAid01",
	"TakeFirstAid02", "TakeFirstAid03"
};
static const char g_Francis[12][] =
{
	"TakePipeBomb01", "TakePipeBomb02", "TakePipeBomb03", "TakePipeBomb04", "TakePipeBomb05", "TakeMolotov01", "TakeMolotov02", "TakeMolotov03",
	"TakeFirstAid01", "TakeFirstAid02", "TakeFirstAid03", "TakeFirstAid04"
};
static const char g_Louis[10][] =
{
	"TakePipeBomb01", "TakePipeBomb02", "TakePipeBomb03", "takepipebomb05", "TakeMolotov01", "TakeMolotov02", "TakeMolotov03", "TakeFirstAid01",
	"TakeFirstAid02", "TakeFirstAid03"
};
static const char g_Zoey[10][] =
{
	"TakePipeBomb02", "takepipebomb04", "TakeMolotov02", "takemolotov04", "takemolotov05", "takemolotov07", "TakeFirstAid01", "TakeFirstAid02",
	"TakeFirstAid03", "takefirstaid05"
};



// ====================================================================================================
//					FORWARDS
// ====================================================================================================
/**
 * @brief Called whenever a player or bot gives an item to someone
 *
 * @param client		The client giving the item
 * @param target		The client receiving an item
 * @param item			Entity index of the object given
 *
 * @noreturn
 */
forward void GearTransfer_OnWeaponGive(int client, int target, int item);

/**
 * @brief Called whenever a player or bot grabs an item
 *
 * @param client		The client grabbing the item
 * @param target		The bot who gave the item, or 0 for when bots auto grab items
 * @param item			Entity index of the object grabbed
 *
 * @noreturn
 */
forward void GearTransfer_OnWeaponGrab(int client, int target, int item);

/**
 * @brief Called whenever a player swaps items with a bot
 *
 * @param client		The client swapping the item
 * @param target		The bot whose item was swapped
 * @param itemGiven		Entity index of the object given to the bot
 * @param itemTaken		Entity index of the object given to the player
 *
 * @noreturn
 */
forward void GearTransfer_OnWeaponSwap(int client, int target, int itemGiven, int itemTaken);



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Gear Transfer",
	author = "SilverShot",
	description = "Survivor bots can automatically pickup and give items. Players can switch, grab or give items.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=137616"
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

	RegPluginLibrary("l4d_gear_transfer");

	MarkNativeAsOptional("Heartbeat_GetRevives");

	g_hForwardGive = new GlobalForward("GearTransfer_OnWeaponGive",						ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardGrab = new GlobalForward("GearTransfer_OnWeaponGrab",						ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardSwap = new GlobalForward("GearTransfer_OnWeaponSwap",						ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell);

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
	// Translations
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "translations/gear_transfer.new.phrases.txt");
	if( FileExists(sPath) )
	{
		LoadTranslations("gear_transfer.new.phrases");
		g_bTranslationNew = true;
		g_bTranslation = true;
	}
	else
	{
		BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "translations/gear_transfer.phrases.txt");
		if( FileExists(sPath) )
		{
			LoadTranslations("gear_transfer.phrases");
			g_bTranslation = true;
		} else {
			g_bTranslation = false;
		}
	}

	// Cvars
	g_hCvarAllow =			CreateConVar(	"l4d_gear_transfer_allow",			"1",			"0=Plugin Off, 1=Plugin On.", CVAR_FLAGS);
	g_hCvarModesBot =		CreateConVar(	"l4d_gear_transfer_modes_bot",		"",				"Disallow bots from auto give/grab in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesOn =		CreateConVar(	"l4d_gear_transfer_modes_on",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_gear_transfer_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_gear_transfer_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarDistGive =		CreateConVar(	"l4d_gear_transfer_dist_give",		"150.0",		"How close you have to be to transfer an item. Also affects bots auto give range.", CVAR_FLAGS);
	g_hCvarDistGrab =		CreateConVar(	"l4d_gear_transfer_dist_grab",		"150.0",		"How close the bots need to be for them to pick up an item.", CVAR_FLAGS);
	g_hCvarDying =			CreateConVar(	"l4d_gear_transfer_dying",			"0",			"Bots only auto give when their receiver is black and white. 0=Ignored. 1=First Aid. 2=Pills or Adrenaline (game logic will give anyway, unless using Bot Healing plugin). 3=Both.", CVAR_FLAGS);
	g_hCvarIdle =			CreateConVar(	"l4d_gear_transfer_idle",			"0",			"0=No, 1=Yes. Can items be transferred with idle players, players will be able to grab and switch items with idle players.", CVAR_FLAGS);
	g_hCvarMethod =			CreateConVar(	"l4d_gear_transfer_method",			"3",			"0=Off. 1=Shove only, 2=Reload key only, 3=Shove and Reload key to transfer items.", CVAR_FLAGS);
	g_hCvarNotifies =		CreateConVar(	"l4d_gear_transfer_notifies",		"7",			"Notify on these types of transfers: 1=Give, 2=Grab, 4=Switch, 7=All. Add numbers together.", CVAR_FLAGS);
	g_hCvarNotify =			CreateConVar(	"l4d_gear_transfer_notify",			"1",			"0=Off, 1=Display transfers to everyone, 2=Also display when transferring pills/adrenaline via the games own system, 4=Display between recipients only. 8=Ignore printing pills/adrenaline and use game prompt only. Add numbers together.", CVAR_FLAGS);
	g_hCvarSounds =			CreateConVar(	"l4d_gear_transfer_sounds",			"1",			"0=Off, 1=Play a sound to the person giving/receiving an item.", CVAR_FLAGS);
	g_hCvarStart =			CreateConVar(	"l4d_gear_transfer_start",			"0.0",			"Block auto give and auto grab from round start for this many seconds.", CVAR_FLAGS);
	g_hCvarTimerGive =		CreateConVar(	"l4d_gear_transfer_timer_give",		"1.0",			"0.0=Off. How often to check survivor bot positions to real clients for auto give.", CVAR_FLAGS, true, 0.0, true, 10.0);
	g_hCvarTimerGrab =		CreateConVar(	"l4d_gear_transfer_timer_grab",		"0.5",			"0.0=Off. How often to check survivor bot positions to item positions for auto grab.", CVAR_FLAGS, true, 0.0, true, 10.0);
	g_hCvarTimeout =		CreateConVar(	"l4d_gear_transfer_timeout",		"5.0",			"Timeout to stop bots returning an item after switching with a player. Timeout to prevent bots auto grabbing a recently dropped item.", CVAR_FLAGS, true, 1.0);
	g_hCvarTraces =			CreateConVar(	"l4d_gear_transfer_traces",			"15",			"Maximum number of ray traces per frame for auto give/grab. This could be increased with minimal impact.", CVAR_FLAGS, true, 1.0, true, 120.0);
	g_hCvarGive =			CreateConVar(	"l4d_gear_transfer_types_give",		"123456789",	"Which type can bots auto give. 0=Off. 1=Adrenaline, 2=Pain Pills, 3=Molotov, 4=Pipe Bomb, 5=Vomit Jar, 6=First Aid, 7=Explosive Rounds, 8=Incendiary Rounds, 9=Defibrillator. Any string combination.", CVAR_FLAGS);
	g_hCvarGrab =			CreateConVar(	"l4d_gear_transfer_types_grab",		"123456789",	"Which type can bots auto grab. 0=Off. 1=Adrenaline, 2=Pain Pills, 3=Molotov, 4=Pipe Bomb, 5=Vomit Jar, 6=First Aid, 7=Explosive Rounds, 8=Incendiary Rounds, 9=Defibrillator. Any string combination.", CVAR_FLAGS);
	g_hCvarTypes =			CreateConVar(	"l4d_gear_transfer_types_real",		"123456789",	"The types real players can transfer. 0=Off. 1=Adrenaline, 2=Pain Pills, 3=Molotov, 4=Pipe Bomb, 5=Vomit Jar, 6=First Aid, 7=Explosive Rounds, 8=Incendiary Rounds, 9=Defibrillator. Any string combination.", CVAR_FLAGS);
	g_hCvarVocalize =		CreateConVar(	"l4d_gear_transfer_vocalize",		"1",			"0=Off. 1=Players vocalize when transferring items. Blocked for the first 60 seconds of a new round.", CVAR_FLAGS);
	CreateConVar(							"l4d_gear_transfer_version",		PLUGIN_VERSION, "Gear Transfer plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_gear_transfer");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOn.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesBot.AddChangeHook(ConVarChanged_AutoMode);

	if( !g_bLeft4Dead2 )
	{
		g_hCvarMaxIncap = FindConVar("survivor_max_incapacitated_count");
		g_hCvarMaxIncap.AddChangeHook(ConVarChanged_Cvars);
	}

	g_hCvarGive.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarGrab.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTypes.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDying.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDistGive.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDistGrab.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarIdle.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMethod.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarNotify.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarNotifies.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSounds.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarStart.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimeout.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimerGive.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimerGrab.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTraces.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarVocalize.AddChangeHook(ConVarChanged_Cvars);

	// Arrays
	g_ListMeds = new ArrayList();
	g_ListNade = new ArrayList();
	g_ListPack = new ArrayList();
	g_TypeMeds = new ArrayList();
	g_TypeNade = new ArrayList();
	g_TypePack = new ArrayList();

	// Start plugin
	for( int i = 0; i < sizeof(g_sPickups); i++ )
		g_Lengths[i] = strlen(g_sPickups[i]);

	IsAllowed();

	#if BENCHMARK
	g_Profiler = CreateProfiler();
	#endif
}

public void OnMapStart()
{
	g_bMapStarted = true;
	g_bRoundIntro = false;

	PrecacheSound(SOUND_LITTLEREWARD);
	PrecacheSound(SOUND_BIGREWARD);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
	ResetItemArray();
}

void ResetPlugin()
{
	g_fBlockVocalize = 0.0;
	g_fStartTime = 0.0;

	for( int i = 1; i <= MaxClients; i++ )
	{
		g_fNextTransfer[i] = 0.0;
		g_fReloadTime[i] = 0.0;
		g_fEquipTime[i] = 0.0;

		for( int x = 0; x < 3; x++ )
		{
			g_iClientItem[i][x] = 0;
			g_iClientType[i][x] = 0;
		}

		if( !g_bLeft4Dead2 )
			SDKUnhook(i, SDKHook_WeaponEquip, OnWeaponDrop);
		SDKUnhook(i, SDKHook_WeaponEquip, OnWeaponEquip);
	}
}

void ResetItemArray()
{
	// .Clear() is creating a memory leak
	// g_ListMeds.Clear();
	// g_ListNade.Clear();
	// g_ListPack.Clear();
	// g_TypeMeds.Clear();
	// g_TypeNade.Clear();
	// g_TypePack.Clear();
	delete g_ListMeds;
	delete g_ListNade;
	delete g_ListPack;
	delete g_TypeMeds;
	delete g_TypeNade;
	delete g_TypePack;
	g_ListMeds = new ArrayList();
	g_ListNade = new ArrayList();
	g_ListPack = new ArrayList();
	g_TypeMeds = new ArrayList();
	g_TypeNade = new ArrayList();
	g_TypePack = new ArrayList();
}

public void OnClientPutInServer(int client)
{
	if( g_bCvarAllow )
	{
		if( !g_bLeft4Dead2 )
			SDKHook(client, SDKHook_WeaponEquip, OnWeaponDrop);
		SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	}
}

void OnWeaponEquip(int client, int weapon)
{
	if( weapon > MaxClients && IsValidEntity(weapon) )
	{
		static char classname[32];
		GetEntityClassname(weapon, classname, sizeof(classname));

		int type = GetItemType(classname);
		if( type == -1 )
		{
			return;
		}

		int slot = GetItemSlot(type) - 2;
		g_iClientItem[client][slot] = EntIndexToEntRef(weapon);
		g_iClientType[client][slot] = type + 1;
		g_fEquipTime[client] = GetGameTime();
	}
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_AutoMode(Handle convar, const char[] oldValue, const char[] newValue)
{
	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	g_hCvarModesBot.GetString(sGameModes, sizeof(sGameModes));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);
	Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
	g_bModeOffAuto = (StrContains(sGameModes, sGameMode) != -1);
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	if( !g_bLeft4Dead2 )
		g_iCvarMaxIncap = g_hCvarMaxIncap.IntValue;

	g_iCvarGive = GetEnum(g_hCvarGive);
	g_iCvarGrab = GetEnum(g_hCvarGrab);
	g_iCvarTypes = GetEnum(g_hCvarTypes);
	g_iCvarDying = g_hCvarDying.IntValue;
	g_fDistGive = g_hCvarDistGive.FloatValue;
	g_fDistGrab = g_hCvarDistGrab.FloatValue;
	g_bCvarIdle = g_hCvarIdle.BoolValue;
	g_iCvarMethod = g_hCvarMethod.IntValue;
	g_iCvarNotify = g_hCvarNotify.IntValue;
	g_iCvarNotifies = g_hCvarNotifies.IntValue;
	g_bCvarSounds = g_hCvarSounds.BoolValue;
	g_fCvarStart = g_hCvarStart.FloatValue;
	g_fCvarTimeout = g_hCvarTimeout.FloatValue;
	g_fTimerGive = g_hCvarTimerGive.FloatValue;
	g_fTimerGrab = g_hCvarTimerGrab.FloatValue;
	g_iCvarTraces = g_hCvarTraces.IntValue;
	g_iCvarVocalize = g_hCvarVocalize.IntValue;

	#if BENCHMARK
	PrintToServer("############### TempTimerToggle CVARS");
	#endif
	TempTimerToggle();
}

int GetEnum(ConVar cvar)
{
	int val;
	static char num[2], temp[10];
	cvar.GetString(temp, sizeof(temp));

	for( int i = 0; i < strlen(temp); i++ )
	{
		num[0] = temp[i];
		if( StringToInt(num) != 0 )
			val += (1<<StringToInt(num)-1);
	}

	return val;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		#if BENCHMARK
		PrintToServer("############### TempTimerToggle IsAllowed");
		#endif
		TempTimerToggle();

		int weapon;
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				// Hook WeaponEquip
				if( !g_bLeft4Dead2 )
					SDKHook(i, SDKHook_WeaponEquip, OnWeaponDrop);
				SDKHook(i, SDKHook_WeaponEquip, OnWeaponEquip);

				for( int slot = SLOT_NADE; slot <= SLOT_MEDS; slot++ )
				{
					weapon = GetPlayerWeaponSlot(i, slot);
					if( weapon != -1 )
					{
						OnWeaponEquip(i, weapon);
					}
				}
			}
		}

		// Loop through all items, add to array
		int index;
		int entity;
		char classname[32];
		for( int i = 0; i < MAX_TYPES * 2; i++ )
		{
			if( !g_bLeft4Dead2 && (i == TYPE_ADREN || i == TYPE_VOMIT || (i > TOP_INDEX_NADE && i != TYPE_FIRST)) ) continue;

			if( i >= MAX_TYPES ) index = i - MAX_TYPES; else index = i;
			strcopy(classname, sizeof(classname), g_sPickups[index]);
			if( i >= MAX_TYPES ) StrCat(classname, sizeof(classname), "_spawn");

			entity = -1;
			while( (entity = FindEntityByClassname(entity, classname)) != INVALID_ENT_REFERENCE )
			{
				switch( GetItemSlot(index) )
				{
					case SLOT_MEDS:
					{
						g_ListMeds.Push(EntIndexToEntRef(entity));
						g_TypeMeds.Push(i);
					}
					case SLOT_NADE:
					{
						g_ListNade.Push(EntIndexToEntRef(entity));
						g_TypeNade.Push(i);
					}
					case SLOT_PACK:
					{
						g_ListPack.Push(EntIndexToEntRef(entity));
						g_TypePack.Push(i);
					}
				}
			}
		}

		HookEvent("gameinstructor_nodraw",		Event_InstructorOff,	EventHookMode_PostNoCopy);
		HookEvent("gameinstructor_draw",		Event_InstructorOn,		EventHookMode_PostNoCopy);
		HookEvent("round_start",				Event_RoundStart,		EventHookMode_PostNoCopy);
		HookEvent("round_end",					Event_RoundEnd,			EventHookMode_PostNoCopy);
		HookEvent("finale_vehicle_leaving",		Event_RoundEnd,			EventHookMode_PostNoCopy);
		HookEvent("spawner_give_item",			Event_SpawnerGiveItem);
		HookEvent("weapon_fire",				Event_WeaponFire);
		HookEvent("weapon_given",				Event_WeaponGiven);
		HookEvent("player_shoved",				Event_PlayerShoved);
		if( g_bLeft4Dead2 )
			HookEvent("weapon_drop",			Event_WeaponDrop);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		#if BENCHMARK
		PrintToServer("############### TempTimerToggle IsAllowed off");
		#endif
		TempTimerToggle();
		ResetPlugin();
		ResetItemArray();

		UnhookEvent("gameinstructor_nodraw",	Event_InstructorOff,	EventHookMode_PostNoCopy);
		UnhookEvent("gameinstructor_draw",		Event_InstructorOn,		EventHookMode_PostNoCopy);
		UnhookEvent("round_start",				Event_RoundStart,		EventHookMode_PostNoCopy);
		UnhookEvent("round_end",				Event_RoundEnd,			EventHookMode_PostNoCopy);
		UnhookEvent("finale_vehicle_leaving",	Event_RoundEnd,			EventHookMode_PostNoCopy);
		UnhookEvent("spawner_give_item",		Event_SpawnerGiveItem);
		UnhookEvent("weapon_fire",				Event_WeaponFire);
		UnhookEvent("weapon_given",				Event_WeaponGiven);
		UnhookEvent("player_shoved",			Event_PlayerShoved);
		if( g_bLeft4Dead2 )
			UnhookEvent("weapon_drop",			Event_WeaponDrop);
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModesOn.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENT - START / END
// ====================================================================================================
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	#if BENCHMARK == 2
	g_iBenchGiveTicks = 0;
	g_fBenchGiveMin = 0.0;
	g_fBenchGiveAvg = 0.0;
	g_fBenchGiveMax = 0.0;
	g_iBenchGrabTicks = 0;
	g_fBenchGrabMin = 0.0;
	g_fBenchGrabAvg = 0.0;
	g_fBenchGrabMax = 0.0;
	PrintToServer("############### TempTimerToggle Event_RoundStart");
	#endif

	g_bRoundOver = false;
	g_fStartTime = GetGameTime();

	// Vocalize block
	if( g_iCvarVocalize && (g_iCvarGive || g_iCvarGrab) )
		g_fBlockVocalize = GetGameTime() + 60.0;

	TempTimerToggle();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	#if BENCHMARK
	PrintToServer("############### TempTimerToggle Event_RoundEnd");
	#endif

	g_bRoundOver = true;

	ResetItemArray();
	TempTimerToggle();

	for( int i = 1; i <= MaxClients; i++ )
	{
		g_fNextTransfer[i] = 0.0;
		g_fEquipTime[i] = 0.0;
	}
}



// ====================================================================================================
//					EVENT - INSTRUCTOR
// ====================================================================================================
// Block auto grab during intro cut scenes.
void Event_InstructorOff(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundIntro = true;
}

void Event_InstructorOn(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(15.0, TimerIntro, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action TimerIntro(Handle timer)
{
	g_bRoundIntro = false;
	return Plugin_Continue;
}



// ======================================================================================
//					EVENT - SPAWNER GIVE ITEM
// ======================================================================================
// Delete the last item picked up from a weapon_spawn to stop bots auto grabbing nothing!
void Event_SpawnerGiveItem(Event event, const char[] name, bool dontBroadcast)
{
	if( !g_iCvarGrab )					// Bug only with auto grab
		return;

	int ent = event.GetInt("spawner");
	if( ent <= MaxClients || ent > 2048 || !IsValidEdict(ent) ) return;

	int flag = GetEntProp(ent, Prop_Data, "m_spawnflags");
	if( flag & (1<<3) ) return;	// Infinite ammo
	int value = GetEntProp(ent, Prop_Data, "m_itemCount");
	if( value > 1 )	return;		// We only need to delete if theres 1 item at the spawn

	static char classname[32];
	GetEdictClassname(ent, classname, sizeof(classname));	// Item name

	for( int i = 2; i < 5; i++ )
	{
		if( strncmp(classname[7], g_sPickups[i][7], 7) == 0 )				// Item must be a grenade
			RemoveEntity(ent);
	}
}



// ====================================================================================================
//					EVENT - WEAPON FIRE
// ====================================================================================================
// This event stops duplicate grenades being created when someone throws and tries to transfer
void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( GetClientTeam(client) != 2 )
		return;

	static char classname[10];
	event.GetString("weapon", classname, sizeof(classname));

	if( strcmp(classname, "pipe_bomb") == 0 || strcmp(classname, "molotov") == 0 || (g_bLeft4Dead2 && strcmp(classname, "vomitjar") == 0) )
	{
		SetNextTransfer(client, 2.0);
	}
}



// ======================================================================================
//					EVENT - PILLS / ADREN GIVEN
// ======================================================================================
// This event stops pills/adrenaline being auto given by bots after you have given to them, and stops you taking it back straight away
void Event_WeaponGiven(Event event, const char[] name, bool dontBroadcast)
{
	int giver = GetClientOfUserId(event.GetInt("giver"));
	if( !giver ) return;

	if( !IsFakeClient(giver) )
		SetNextTransfer(giver, 2.0);

	int weapon = event.GetInt("weapon");
	if( weapon == 15 || weapon == 23 )
	{
		int client = GetClientOfUserId(event.GetInt("userid"));

		if( g_iCvarNotify & NOTIFY_EVENT && g_iCvarNotifies & NOTIFY_GIVE && g_fNextTransfer[client] < GetGameTime() )
		{
			int type;

			if( weapon == 23 )
				type = 0;
			else
				type = 1;

			if( g_bTranslationNew )
			{
				MPrintToChatAll(giver, "Gave", g_sPickups[type], client);
			}
			else
			{
				GearTransferPrintToChatAll(client, "{olive}%N {default}%t {green}%t {default}%t {olive}%N", giver, "Gave", g_sPickups[type], "To", client);
			}
		}

		if( g_iCvarGive && IsFakeClient(client) )
		{
			SetNextTransfer(client, 3.0);
		}
	}
}



// ====================================================================================================
//					EVENT - WEAPON DROP
// ====================================================================================================
// Better to use "weapon_drop" event in L4D2 because of "SDKHooks_DropWeapon" error. Search this plugin for "SDKHooks_DropWeapon" for more info.
// L4D1 is missing the event so we'll have to use "SDKHook_WeaponDrop".
void Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client )
	{
		int item = event.GetInt("propid");
		item = EntIndexToEntRef(item);
		OnDrop(client, item);
	}
}

void OnWeaponDrop(int client, int item)
{
	item = EntIndexToEntRef(item);
	OnDrop(client, item);
}

void OnDrop(int client, int item)
{
	for( int i = 0; i < 3; i++ )
	{
		if( item == g_iClientItem[client][i] )
		{
			if( g_fEquipTime[client] == GetGameTime() ) return; // Bug: for some reason on some servers the OnWeaponDrop fires after OnWeaponEquip for the same item that was just equipped

			g_iClientItem[client][i] = 0;
			g_iClientType[client][i] = 0;
			SetEntPropFloat(item, Prop_Data, "m_flCreateTime", GetGameTime() + g_fCvarTimeout);
			return;
		}
	}
}



// ====================================================================================================
//					EVENT - PLAYER SHOVED
// ====================================================================================================
void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCvarMethod == 2 ) // Reload key only
		return;

	int target = GetClientOfUserId(event.GetInt("userid"));
	if( GetClientTeam(target) != 2 || !IsPlayerAlive(target) )
		return;

	// Validate client
	int client = GetClientOfUserId(event.GetInt("attacker"));
	if( IsFakeClient(client) )
		return;

	// They just transferred, return
	if( GetGameTime() < g_fNextTransfer[client] )
		return;

	// Don't allow transfers while incapped/reviving
	if( IsReviving(client) || IsIncapped(client) )
		return;

	TransferItem(client, target, true);
}



// ====================================================================================================
//					ON PLAYER RUN CMD
// ====================================================================================================
// ====================================================================================================
//					TRANSFER ITEM
// ====================================================================================================
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	// Blocked
	if( !g_bCvarAllow || g_bRoundOver || !g_iCvarTypes || !g_fDistGive || !g_iCvarMethod )
		return Plugin_Continue;

	// 1 = Shove key only
	if( buttons & IN_RELOAD )
	{
		if( g_iCvarMethod == 1 )
			return Plugin_Continue;
	} else {
		g_fReloadTime[client] = 0.0;
	}

	// Check keys
	bool b_FromShove;
	if( buttons & IN_ATTACK2 && !(buttons & IN_ATTACK) )
	{
		// 2 = Reload key only
		if( g_iCvarMethod == 2 )
			return Plugin_Continue;

		b_FromShove = true;
	}

	// Transfer attempt
	if( buttons & IN_RELOAD || (buttons & IN_ATTACK2 && !(buttons & IN_ATTACK)) )
	{
		// They just transferred, block reload
		if( !b_FromShove && buttons & IN_RELOAD && g_fReloadTime[client] > GetGameTime() )
		{
			buttons &= ~IN_RELOAD;
			return Plugin_Changed;
		} else {
		// They just transferred, return
			if( GetGameTime() < g_fNextTransfer[client] + 0.3 )
			{
				return Plugin_Continue;
			}
		}

		// Validate client
		if( !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2 )
			return Plugin_Continue;

		// Don't allow transfers while incapped/reviving
		if( IsReviving(client) || IsIncapped(client) )
			return Plugin_Continue;

		// Get aim target
		int target = GetClientAimTarget(client, true);

		// They must be aiming at an alive survivor
		if( target == -1 || target > MaxClients || GetClientTeam(target) != 2 || !IsPlayerAlive(target) )
			return Plugin_Continue;

		TransferItem(client, target, b_FromShove);
	}

	return Plugin_Continue;
}



// ====================================================================================================
//					TRANSFER ITEM
// ====================================================================================================
void TransferItem(int client, int target, bool b_FromShove)
{
	// Don't allow transfers while incapped/reviving
	if( IsReviving(target) || IsIncapped(target) )
		return;

	// Start by allowing all types, validate to figure out which we're doing
	int transferType = METHOD_GIVE | METHOD_SWAP;

	// Validate item for give
	int slot = -1;
	int type = -1;
	int item = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if( item != -1 )
	{
		item = EntIndexToEntRef(item);

		// Get type (faster than doing string checks, they're already done in OnWeaponEquip)
		for( int i = 0; i < 3; i++ )
		{
			if( item == g_iClientItem[client][i] )
			{
				type = g_iClientType[client][i] - 1;
				slot = i;
				break;
			}
		}
	}

	// Validate type
	if( type == -1 || AllowedToTransfer(type) == false )
	{
		// Cannot give or swap
		transferType &= ~METHOD_GIVE;
		transferType &= ~METHOD_SWAP;
	} else {
		// Validate target can swap or has empty slot for give
		slot = GetItemSlot(type);

		if( GetPlayerWeaponSlot(target, slot) == -1 )
		{
			transferType &= ~METHOD_SWAP; // Cannot swap
		} else {
			transferType &= ~METHOD_GIVE; // Cannot give
		}
	}

	// Test for grab
	bool fakeTarget = IsFakeClient(target) && HasSpectator(target) == false;
	if( transferType == METHOD_NONE && fakeTarget == true )
	{
		for( int i = 0; i < 3; i++ )
		{
			type = g_iClientType[target][i] - 1;

			if( type != -1 && AllowedToTransfer(type) )
			{
				// Target has valid entity, client has empty slot.
				// GetPlayerWeaponSlot because some !drop plugins can bug and remove 2 items: 1 correct and 1 newly created entity - it's identical twin probably at 0,0,0 whilst retaining "m_hOwnerEntity"
				// SDKHooks_DropWeapon() fails to fire the SDKHook_WeaponDrop() forward so we cannot rely on this to know when a weapon is removed..
				// Hence why they're always stored in g_iClientItem and checked to be valid. But invalid when removed and the owner doesn't change.
				if( IsValidEntRef(g_iClientItem[target][i]) == true && GetPlayerWeaponSlot(client, i + 2) == -1 )
				{
					item = EntRefToEntIndex(g_iClientItem[target][i]);
					if( GetEntPropEnt(item, Prop_Send, "m_hOwnerEntity") == target ) // FIXME: Validate owner, lack of tracking items after dropping.
					{
						transferType = METHOD_GRAB;
						slot = i + 2;
						break;
					}
				}
			}
		}
	}

	// Nothing valid, return.
	if( transferType == METHOD_NONE || (transferType != METHOD_GIVE && fakeTarget == false) )
		return;

	// Don't give pills/adrenaline from shoves, the game already does this.
	// Don't allow medkits to be transferred from shoves, so they can heal others!
	if( b_FromShove &&
		((transferType == METHOD_GIVE && type <= TOP_INDEX_MEDS) ||
		(transferType == METHOD_GIVE || transferType == METHOD_SWAP) && type == TYPE_FIRST)
	)
	{
		SetNextTransfer(client, 0.5); // Timeout to prevent grabbing straight after the game gives.
		return;
	}

	// Verify distance
	static float vPos[3], vEnd[3], dist;
	GetClientEyePosition(client, vPos);
	GetClientEyePosition(target, vEnd);
	dist = GetVectorDistance(vPos, vEnd);

	// They are within range
	if( dist <= g_fDistGive )
	{
		GiveItem(client, target, item, slot - 2, type, transferType);

		// Block reload key
		if( !b_FromShove )
		{
			g_fReloadTime[client] = GetGameTime() + 0.4;
		}
	}
}



// ====================================================================================================
//					GIVE AN ITEM
// ====================================================================================================
void SetNextTransfer(int client, float next)
{
	float time = GetGameTime() + next;
	if( time > g_fNextTransfer[client] )
		g_fNextTransfer[client] = time;
}

void GiveItem(int client, int target, int item, int slot, int type, int transferType)
{
	// Don't allow transfer after giving
	SetNextTransfer(client, 1.5);

	// Don't let bots give back for a while
	if( g_iCvarGive && transferType != METHOD_GRAB && IsFakeClient(target) )
	{
		SetNextTransfer(target, g_fCvarTimeout);
	} else {
		SetNextTransfer(target, 1.2);
	}

	// Sounds
	if( g_bCvarSounds )
	{
		switch( transferType )
		{
			case METHOD_GIVE: { PlaySound(target, SOUND_LITTLEREWARD); PlaySound(client, SOUND_BIGREWARD); }
			case METHOD_GRAB, METHOD_SWAP: PlaySound(client, SOUND_LITTLEREWARD);
		}
	}

	// Vocalize
	if( g_iCvarVocalize )
	{
		if( transferType == METHOD_GRAB )
			Vocalize(client, type);
		else if( transferType == METHOD_GIVE )
			Vocalize(target, type);
		else
		{
			type = g_iClientType[client][slot] - 1;
			Vocalize(target, type);

			type = g_iClientType[target][slot] - 1;
			Vocalize(client, type);
		}
	}

	// Notification
	if( g_iCvarNotify && g_bTranslation && GetGameTime() > g_fBlockVocalize )
	{
		if( transferType == METHOD_GIVE && g_iCvarNotifies & NOTIFY_GIVE )
		{
			if( !(g_iCvarNotify & NOTIFY_IGNORE) || (type != TYPE_PILLS && type != TYPE_ADREN) )
			{
				if( g_bTranslationNew )
					MPrintToChatAll(client, "Gave", g_sPickups[type], target);
				else
					GearTransferPrintToChatAll(target, "{olive}%N {default}%t {green}%t {default}%t {olive}%N", client, "Gave", g_sPickups[type], "To", target);
			}
		}
		else if( transferType == METHOD_GRAB && g_iCvarNotifies & NOTIFY_GRAB )
		{
			if( !(g_iCvarNotify & NOTIFY_IGNORE) || (type != TYPE_PILLS && type != TYPE_ADREN) )
			{
				if( g_bTranslationNew )
					MPrintToChatAll(client, "Grabbed", g_sPickups[type], target);
				else
					GearTransferPrintToChatAll(target, "{olive}%N {default}%t {green}%t {default}%t {olive}%N", client, "Grabbed", g_sPickups[type], "From", target);
			}
		}
		else if( transferType == METHOD_SWAP && g_iCvarNotifies & NOTIFY_SWITCH )
		{
			type = g_iClientType[client][slot] - 1;

			if( !(g_iCvarNotify & NOTIFY_IGNORE) || (type != TYPE_PILLS && type != TYPE_ADREN) )
			{
				if( g_bTranslationNew )
					MPrintToChatAll(client, "Switched", g_sPickups[type], target);
				else
					GearTransferPrintToChatAll(target, "{olive}%N {default}%t {green}%t {default}%t {olive}%N", client, "Switched", g_sPickups[type], "With", target);
			}

			type = g_iClientType[target][slot] - 1;

			if( !(g_iCvarNotify & NOTIFY_IGNORE) || (type != TYPE_PILLS && type != TYPE_ADREN) )
			{
				if( g_bTranslationNew )
					MPrintToChatAll(target, "Gave", g_sPickups[type], client);
				else
					GearTransferPrintToChatAll(client, "{olive}%N {default}%t {green}%t {default}%t {olive}%N", target, "Gave", g_sPickups[type], "To", client);
			}
		}
	}

	// TRANSFER
	if( transferType == METHOD_SWAP )
	{
		int ent_c = g_iClientItem[client][slot];
		int ent_t = g_iClientItem[target][slot];
		int type_c = g_iClientType[client][slot];
		int type_t = g_iClientType[target][slot];

		if( g_iClientType[client][slot] - 1 == TYPE_MOLO )	StopSound(ent_t, SNDCHAN_STATIC, SOUND_MOLOTOV_IDLE);
		if( g_iClientType[target][slot] - 1 == TYPE_MOLO )	StopSound(ent_c, SNDCHAN_STATIC, SOUND_MOLOTOV_IDLE);

		RemovePlayerItem(target, ent_t);
		RemovePlayerItem(client, ent_c);

		if( IsFakeClient(client) )
		{
			EquipPlayerWeapon(client, ent_t);
			ent_t = EntRefToEntIndex(ent_t);
		} else {
			// RemoveEntity(ent_t); // Causing bugs with ghost weapon (valid entity) attached to bots feet
			RemoveEdict(ent_t);
			ent_t = CreateAndEquip(client, type_t - 1);
		}

		if( IsFakeClient(target) )
		{
			EquipPlayerWeapon(target, ent_c);
			ent_c = EntRefToEntIndex(ent_c);
		} else {
			// RemoveEntity(ent_c); // Causing bugs with ghost weapon (valid entity) attached to bots feet
			RemoveEdict(ent_c);
			ent_c = CreateAndEquip(target, type_c - 1);
		}

		if( type >= TYPE_MOLO && type <= TYPE_VOMIT )
		{
			// Switch to previous weapon to stop the bug where Molotovs appear with Pipe particles and vice versa.
			ClientCommand(client, "lastinv");
			CreateTimer(0.1, TimerSwapBack, GetClientUserId(client));
		}

		// Events
		FireEventsGeneral(client, target, ent_c, type);
		FireEventsGeneral(target, client, ent_t, type);

		// Forward
		Call_StartForward(g_hForwardSwap);
		Call_PushCell(client);
		Call_PushCell(target);
		Call_PushCell(ent_c);
		Call_PushCell(ent_t);
		Call_Finish();
	}
	else if( transferType == METHOD_GIVE )
	{
		g_iClientItem[client][slot] = 0;

		if( type == TYPE_MOLO )	StopSound(item, SNDCHAN_STATIC, SOUND_MOLOTOV_IDLE);

		RemovePlayerItem(client, item);

		if( IsFakeClient(target) )
		{
			EquipPlayerWeapon(target, item);
			item = EntRefToEntIndex(item);
		} else {
			// RemoveEntity(item); // Causing bugs with ghost weapon (valid entity) attached to bots feet
			RemoveEdict(item);
			item = CreateAndEquip(target, type);
		}

		// Events
		FireEventsGeneral(client, target, item, type);

		// Forward
		Call_StartForward(g_hForwardGive);
		Call_PushCell(client);
		Call_PushCell(target);
		Call_PushCell(item);
		Call_Finish();
	}
	else if( transferType == METHOD_GRAB )
	{
		g_iClientItem[target][slot] = 0;

		if( type == TYPE_MOLO )	StopSound(item, SNDCHAN_STATIC, SOUND_MOLOTOV_IDLE);

		RemovePlayerItem(target, item);

		if( IsFakeClient(client) )
		{
			EquipPlayerWeapon(client, item);
		} else {
			// RemoveEntity(item); // Causing bugs with ghost weapon (valid entity) attached to bots feet
			RemoveEdict(item);
			item = CreateAndEquip(client, type);
		}

		// Events
		FireEventsGeneral(target, client, item, type);

		// Forward
		Call_StartForward(g_hForwardGrab);
		Call_PushCell(client);
		Call_PushCell(target);
		Call_PushCell(item);
		Call_Finish();
	}
}

int CreateAndEquip(int client, int type)
{
	static char classname[32];

	switch( type )
	{
		case TYPE_ADREN:		classname = "weapon_adrenaline";
		case TYPE_PILLS:		classname = "weapon_pain_pills";
		case TYPE_MOLO:			classname = "weapon_molotov";
		case TYPE_PIPE:			classname = "weapon_pipe_bomb";
		case TYPE_VOMIT:		classname = "weapon_vomitjar";
		case TYPE_FIRST:		classname = "weapon_first_aid_kit";
		case TYPE_EXPLO:		classname = "weapon_upgradepack_explosive";
		case TYPE_INCEN:		classname = "weapon_upgradepack_incendiary";
		case TYPE_DEFIB:		classname = "weapon_defibrillator";
		default:				{LogError("Type wrong: %d", type); return 0;} // This should never happen, but just in case...
	}

	int entity = GivePlayerItem(client, classname);
	if( entity != INVALID_ENT_REFERENCE )
	{
		RemovePlayerItem(client, entity);
		EquipPlayerWeapon(client, entity);
		return entity;
	}

	return 0;
}

Action TimerSwapBack(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if( client ) ClientCommand(client, "slot3");
	return Plugin_Continue;
}



// ====================================================================================================
//					AUTO GRAB - GET ITEM SPAWNS
// ====================================================================================================
public void OnEntityCreated(int entity, const char[] classname)
{
	#if BENCHMARK
	StartProfiling(g_Profiler);
	g_bProfiling = true;
	#endif

	if( g_bCvarAllow && g_iCvarGrab && classname[0] == 'w' ) // Match "w" from "weapon_"
	{
		int len = strlen(classname);
		if( len > 13 && classname[6] == '_' ) // Min length "weapon_molotov". Match "_" from "weapon_"
		{
			for( int i = 0; i < MAX_TYPES; i++ )
			{
				if( len >= g_Lengths[i] && strncmp(classname[7], g_sPickups[i][7], g_Lengths[i] > 20 ? 13 : g_Lengths[i] - 7) == 0 ) // Match after "weapon_" for string len or 13 chars: (eg "upgradepack_i").
				{
					if( len > g_Lengths[i] ) // Is "_spawn" type
						len = i + MAX_TYPES;
					else
						len = i;

					SetEntPropFloat(entity, Prop_Data, "m_flCreateTime", GetGameTime() + g_fCvarTimeout);

					switch( GetItemSlot(i) )
					{
						case SLOT_MEDS:
						{
							g_ListMeds.Push(EntIndexToEntRef(entity));
							g_TypeMeds.Push(len);
						}
						case SLOT_NADE:
						{
							g_ListNade.Push(EntIndexToEntRef(entity));
							g_TypeNade.Push(len);
						}
						case SLOT_PACK:
						{
							g_ListPack.Push(EntIndexToEntRef(entity));
							g_TypePack.Push(len);
						}
					}

					#if BENCHMARK
					StopProfiling(g_Profiler);
					g_bProfiling = false;
					float speed = GetProfilerTime(g_Profiler);
					PrintToServer("GEAR:OnEntityCreated: %f. %d - (%s)", speed, entity, classname);
					#endif

					return;
				}
			}
		}
	}

	#if BENCHMARK
	StopProfiling(g_Profiler);
	g_bProfiling = false;
	#endif
}



// ====================================================================================================
//					AUTO GIVE / GRAB TIMERS
// ====================================================================================================
void TempTimerToggle()
{
	delete g_hTimerGive;
	delete g_hTimerGrab;

	if( !g_bCvarAllow || g_bRoundOver || g_bModeOffAuto ) return;

	if( g_iCvarGive && g_fTimerGive )		g_hTimerGive = CreateTimer(g_fTimerGive, TimerAutoGive, _, TIMER_REPEAT);
	if( g_iCvarGrab && g_fTimerGrab )		g_hTimerGrab = CreateTimer(g_fTimerGrab, TimerAutoGrab, _, TIMER_REPEAT);
}

Action TimerAutoGive(Handle timer)
{
	if( !g_bCvarAllow || g_bRoundOver || g_bModeOffAuto )
	{
		g_hTimerGive = null;
		return Plugin_Stop;
	}

	if( g_bRoundIntro ) return Plugin_Continue;
	if( g_fCvarStart && g_fStartTime + g_fCvarStart > GetGameTime() ) return Plugin_Continue;

	#if BENCHMARK
	StartProfiling(g_Profiler);
	g_bProfiling = true;
	#endif



	// Static to save CPU cycles on each call from allocating and initializing memory, pretty pointless on ints but whatever.
	static float vBot[3];
	static int slot;
	static int type;
	static int entity;
	static int weapon;
	static int target;
	static int player;

	// Used to resume iteration after exiting from reaching trace ray count limit.
	static int lastBot = 1;
	static int frameTraces;
	frameTraces = 0;

	// Cache valid targets in loop
	static float targetPos[MAXPLAYERS+1][3];
	int targetValid[MAXPLAYERS+1];

	#if BENCHMARK
	if( lastBot != 1 )
	PrintToServer("GIVE: RESUMING LAST BOT %d", lastBot);
	#endif



	// Loop through bots
	for( int bot = lastBot; bot <= MaxClients; bot++ )
	{
		lastBot = bot + 1;

		// Transferred recently
		if( GetGameTime() < g_fNextTransfer[bot] )
			continue;

		// Make sure bot is team survivor and alive
		// Don't allow transfers while incapped/reviving
		if( IsClientInGame(bot) && GetClientTeam(bot) == 2 && IsPlayerAlive(bot) && IsFakeClient(bot) && !IsReviving(bot) && !IsIncapped(bot) )
		{
			// Spectator check moved to here, to re-use the netclass below
			static char netclass[12];
			GetEntityNetClass(bot, netclass, sizeof(netclass));

			if( !g_bCvarIdle )
			{
				if( strcmp(netclass, "SurvivorBot") == 0 && GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID") != 0 )
					continue;
			}

			// Loop through weapon slots
			for( slot = 0; slot < 3; slot++ )
			{
				// Validate type allowed by bots
				type = g_iClientType[bot][slot];
				if( BotAllowedTransfer(type, true) )
				{
					weapon = 0;

					// Bot has item in slot, and owner is bot. FIXME: Entity not handled after equip, could be invalid.
					entity = g_iClientItem[bot][slot];

					if( IsValidEntRef(entity) == true && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == bot )
					{
						// Prevent auto give when bot using healing
						if( slot > 0 && FindSendPropInfo(netclass, "m_iCurrentUseAction") != -1 && GetEntProp(bot, Prop_Send, "m_iCurrentUseAction") == 1 )
						{
							continue;
						}

						// Validate range
						GetClientEyePosition(bot, vBot);

						// Loop through real clients, check range
						for( player = 1; player <= MaxClients; player++ )
						{
							// Transferred recently
							if( GetGameTime() < g_fNextTransfer[player] )
								continue;

							if( targetValid[player] == 0 )
							{
								targetValid[player] = 1;
								if( IsClientInGame(player) && GetClientTeam(player) == 2 && IsPlayerAlive(player) && IsFakeClient(player) == false && !IsReviving(player) && !IsIncapped(player) )
								{
									targetValid[player] = 2;
									GetClientEyePosition(player, targetPos[player]);
								}
							}

							if( targetValid[player] == 2 )
							{
								if( GetPlayerWeaponSlot(player, slot + 2) == -1 )
								{
									g_iClientItem[player][slot] = 0;

									// Range check
									if( GetVectorDistance(vBot, targetPos[player]) <= g_fDistGive )
									{
										// Validate receiver is black and white for first aid/pills/adrenaline
										if( g_iCvarDying )
										{
											switch( type - 1 )
											{
												case TYPE_FIRST:
												{
													if( g_iCvarDying != 2 )
													{
														// Check B&W
														if( g_bLeft4Dead2 ? GetEntProp(player, Prop_Send, "m_bIsOnThirdStrike") == 0 : (g_bPluginHeartbeat ? Heartbeat_GetRevives(player) : GetEntProp(player, Prop_Send, "m_currentReviveCount")) < g_iCvarMaxIncap )
														{
															continue;
														}
													}
												}
												case TYPE_ADREN, TYPE_PILLS:
												{
													if( g_iCvarDying != 1 )
													{
														// Check B&W
														if( g_bLeft4Dead2 ? GetEntProp(player, Prop_Send, "m_bIsOnThirdStrike") == 0 : (g_bPluginHeartbeat ? Heartbeat_GetRevives(player) : GetEntProp(player, Prop_Send, "m_currentReviveCount")) < g_iCvarMaxIncap )
														{
															continue;
														}
													}
												}
											}
										}

										// Is visible to target
										frameTraces++;

										if( IsVisibleTo(vBot, targetPos[player]) )
										{
											#if BENCHMARK
											PrintToServer("GIVE: VISIBLE. BOT %d. SLOT %d. TRACES (%d/%d)", bot, slot, frameTraces, g_iCvarTraces);
											#endif
											// Limit number of traces per frame
											weapon = entity;
											target = player;
											targetValid[player] = 1; // Stop other bots targeting
											break;
										}

										// Limit number of traces per frame
										if( frameTraces >= g_iCvarTraces )
										{
											#if BENCHMARK == 2
											StopProfiling(g_Profiler);
											g_bProfiling = false;
											float speed = GetProfilerTime(g_Profiler);
											if( speed < g_fBenchGiveMin ) g_fBenchGiveMin = speed;
											if( speed > g_fBenchGiveMax ) g_fBenchGiveMax = speed;
											g_fBenchGiveAvg += speed;
											g_iBenchGiveTicks++;
											PrintToServer("SPEED::AutoGive_F %f. Min %f. Avg %f. Max %f. Traces %d", speed, g_fBenchGiveMin, g_fBenchGiveAvg / g_iBenchGiveTicks, g_fBenchGiveMax, frameTraces);
											#endif

											#if BENCHMARK
											PrintToServer("GIVE: FRAME TRACE LIMIT REACHED!!! lastBot %d / (%d/%d)", lastBot, frameTraces, g_iCvarTraces);
											#endif

											return Plugin_Continue;
										}
									}
								}
							}
						}
					}



					// Valid item to give.
					if( weapon )
					{
						GiveItem(bot, target, weapon, slot, type - 1, METHOD_GIVE);

						#if BENCHMARK == 2

						if( g_bProfiling )
						{
							StopProfiling(g_Profiler);
							g_bProfiling = false;
						}

						float speed = GetProfilerTime(g_Profiler);
						if( speed < g_fBenchGiveMin ) g_fBenchGiveMin = speed;
						if( speed > g_fBenchGiveMax ) g_fBenchGiveMax = speed;
						g_fBenchGiveAvg += speed;
						g_iBenchGiveTicks++;
						PrintToServer("SPEED::AutoGive_T %f. Min %f. Avg %f. Max %f. Traces %d", speed, g_fBenchGiveMin, g_fBenchGiveAvg / g_iBenchGiveTicks, g_fBenchGiveMax, frameTraces);
						#endif

						#if BENCHMARK
						PrintToServer("AUTO GIVE - equip %d (%s) from %d (%N) to %d (%N)", EntRefToEntIndex(weapon), g_sPickups[type - 1], bot, bot, target, target);
						#endif

						return Plugin_Continue; // Prevent multiple gives in the same frame and wait until next timer firing?
					}
				}
			}
		}

		// Reset entire loop to start again
		if( lastBot - 1 == MaxClients )
		{
			lastBot = 1;
		}
	}


	#if BENCHMARK == 2
	StopProfiling(g_Profiler);
	g_bProfiling = false;
	float speed = GetProfilerTime(g_Profiler);
	if( speed < g_fBenchGiveMin ) g_fBenchGiveMin = speed;
	if( speed > g_fBenchGiveMax ) g_fBenchGiveMax = speed;
	g_fBenchGiveAvg += speed;
	g_iBenchGiveTicks++;

	PrintToServer("SPEED::AutoGive %f. Min %f. Avg %f. Max %f. Traces %d", speed, g_fBenchGiveMin, g_fBenchGiveAvg / g_iBenchGiveTicks, g_fBenchGiveMax, frameTraces);
	#endif

	return Plugin_Continue;
}

Action TimerAutoGrab(Handle timer)
{
	if( !g_bCvarAllow || g_bRoundOver || g_bModeOffAuto )
	{
		g_hTimerGrab = null;
		return Plugin_Stop;
	}

	if( g_bRoundIntro ) return Plugin_Continue;

	#if BENCHMARK
	StartProfiling(g_Profiler);
	g_bProfiling = true;
	#endif
	#if BENCHMARK == 2
	#endif



	// Static to save CPU cycles on each call from allocating and initializing memory
	static ArrayList aList;
	static ArrayList aType;
	static float vBot[3];
	static float vPos[3];
	static int slot;
	static int type;
	static int index;
	static int entity;
	static int weapon;
	static bool spawner;
	float times = GetGameTime();

	// Used to resume iteration after exiting from reaching trace ray count limit.
	static int lastBot = 1;
	static int lastIndex;
	static int maxIndex;
	static int frameTraces;
	frameTraces = 0;

	#if BENCHMARK
	if( lastIndex != 0 )
	PrintToServer("GRAB RESUMING LAST INDEX %d. bot=%d", lastIndex, lastBot);
	#endif



	// Loop through bots
	for( int bot = lastBot; bot <= MaxClients; bot++ )
	{
		lastBot = bot;

		// Make sure bot is team survivor and alive
		// Don't allow transfers while incapped/reviving
		if( IsClientInGame(bot) && GetClientTeam(bot) == 2 && IsPlayerAlive(bot) && IsFakeClient(bot) && !IsReviving(bot) && !IsIncapped(bot) )
		{
			// Transferred recently
			if( times < g_fNextTransfer[bot] )
				continue;

			// Loop through weapon slots
			for( slot = 0; slot < 3; slot++ )
			{
				// Bot missing item in slot, or owner is not bot. FIXME: Entity not handled after equip, could be invalid.
				entity = g_iClientItem[bot][slot];
				if( IsValidEntRef(entity) == false || GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != bot )
				{
					weapon = 0;

					// Get entity array lists
					switch( slot + 2 )
					{
						case SLOT_NADE: { aList = g_ListNade; aType = g_TypeNade; }
						case SLOT_PACK: { aList = g_ListPack; aType = g_TypePack; }
						case SLOT_MEDS: { aList = g_ListMeds; aType = g_TypeMeds; }
					}

					// Loop through array list
					maxIndex = aList.Length;
					for( index = lastIndex; index < maxIndex; index++ )
					{
						// Validate type allowed by bots
						lastIndex = index;
						type = aType.Get(index);

						if( type > MAX_TYPES )
						{
							spawner = true;
							type -= MAX_TYPES;
						} else {
							spawner = false;
						}

						if( BotAllowedTransfer(type + 1, false) )
						{
							// Validate entity
							entity = aList.Get(index);

							if( IsValidEntRef(entity) == false )
							{
								// Remove invalid entities from array
								aType.Erase(index);
								aList.Erase(index);
								maxIndex--;
								index--;
							} else {
								// Item does not have owner and was not recently dropped
								if( GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == -1 && GetEntPropFloat(entity, Prop_Data, "m_flCreateTime") < times )
								{
									// Validate range
									GetClientEyePosition(bot, vBot);
									GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
									if( GetVectorDistance(vBot, vPos) <= g_fDistGrab )
									{
										// Is visible to item
										frameTraces++;
										if( IsVisibleTo(vBot, vPos) )
										{
											#if BENCHMARK
											PrintToServer("GRAB: VISIBLE. BOT %d (%N). SLOT %d. TRACES (%d/%d)", bot, bot, slot, frameTraces, g_iCvarTraces);
											#endif

											// Limit number of traces per frame
											weapon = entity;
											break;
										}

										// Limit number of traces per frame
										if( frameTraces >= g_iCvarTraces )
										{
											#if BENCHMARK
											PrintToServer("GRAB - FRAME TRACE LIMIT REACHED!!! lastIndex %d / (%d/%d)", lastIndex, frameTraces, g_iCvarTraces);
											#endif

											#if BENCHMARK == 2
											StopProfiling(g_Profiler);
											g_bProfiling = false;
											float speed = GetProfilerTime(g_Profiler);
											if( speed < g_fBenchGrabMin ) g_fBenchGrabMin = speed;
											if( speed > g_fBenchGrabMax ) g_fBenchGrabMax = speed;
											g_fBenchGrabAvg += speed;
											g_iBenchGrabTicks++;
											PrintToServer("SPEED::AutoGrab_F %f. Min %f. Avg %f. Max %f. Traces %d", speed, g_fBenchGrabMin, g_fBenchGrabAvg / g_iBenchGrabTicks, g_fBenchGrabMax, frameTraces);
											#endif
											return Plugin_Continue;
										}
									}
								}
							}
						}

						// Reset last index
						if( index == maxIndex - 1 ) lastIndex = 0;
						if( weapon ) break;
					}



					// Valid item to grab.
					if( weapon )
					{
						if( spawner )
						{
							// =========================
							// PROTOTYPE GRENADES - incase _spawn grenades ever have set types. Does anyone need this feature to set grenade types on spawned grenades before pickup?
							// TODO: Prototype Grenades needs to validate index is within type range otherwise a maps hammer ID will throw errors.
							// hammer = GetEntProp(weapon, Prop_Data, "m_iHammerID");
							// =========================

							int flag = GetEntProp(weapon, Prop_Data, "m_spawnflags");
							if( flag & (1<<3) )
							{
								// Unlimited items, do nothing.
							}
							else
							{
								int iCount = GetEntProp(weapon, Prop_Data, "m_itemCount");
								if( iCount > 1 )
									SetEntProp(weapon, Prop_Data, "m_itemCount", iCount -1);
								else
									RemoveEntity(weapon);
							}

							int item = CreateEntityByName(g_sPickups[type]);
							if( item == -1 )
							{
								LogError("Failed to create entity '%s' for %N", g_sPickups[type], bot);
							}
							else
							{
								if( !DispatchSpawn(item) )
								{
									LogError("Failed to dispatch '%s' for %N", g_sPickups[type], bot);
								}
								else
								{
									// =========================
									// if( hammer ) SetEntProp(item, Prop_Data, "m_iHammerID", hammer);
									// =========================

									#if BENCHMARK
									PrintToServer("AUTO GRAB - spawner %d (%s) to %d (%N)", EntRefToEntIndex(weapon), g_sPickups[type], bot, bot);
									#endif
									EquipPlayerWeapon(bot, item);

									Call_StartForward(g_hForwardGrab);
									Call_PushCell(bot);
									Call_PushCell(0);
									Call_PushCell(item);
									Call_Finish();
								}
							}
						}
						else
						{
							#if BENCHMARK
							PrintToServer("AUTO GRAB - equip %d (%s) to %d (%N)", EntRefToEntIndex(weapon), g_sPickups[type], bot, bot);
							#endif
							EquipPlayerWeapon(bot, weapon);

							Call_StartForward(g_hForwardGrab);
							Call_PushCell(bot);
							Call_PushCell(0);
							Call_PushCell(EntRefToEntIndex(weapon));
							Call_Finish();
						}

						SetNextTransfer(bot, 2.0);

						FireEventsFootlocker(bot, EntRefToEntIndex(weapon), type, spawner);

						Vocalize(bot, type);

						if( g_iCvarNotify & NOTIFY_ALL && g_bTranslation && times > g_fBlockVocalize && g_iCvarNotifies & NOTIFY_GRAB )
						{
							if( g_bTranslationNew )
								MPrintToChatAll(bot, "BotGrabbed", g_sPickups[type], 0);
							else
								GearTransferPrintToChatAll(0, "{olive}%N {default}%t {green}%t", bot, "Grabbed", g_sPickups[type]);
						}

						// break;
						return Plugin_Continue; // Prevent multiple gives in the same frame and wait until next timer firing?
					}
				}
			}
		}

		// Reset entire loop to start again
		if( lastBot == MaxClients )
		{
			lastBot = 1;
			lastIndex = 0;
		}
	}

	#if BENCHMARK == 2
	StopProfiling(g_Profiler);
	g_bProfiling = false;
	float speed = GetProfilerTime(g_Profiler);
	if( speed < g_fBenchGrabMin ) g_fBenchGrabMin = speed;
	if( speed > g_fBenchGrabMax ) g_fBenchGrabMax = speed;
	g_fBenchGrabAvg += speed;
	g_iBenchGrabTicks++;

	PrintToServer("SPEED::AutoGrab %f. Min %f. Avg %f. Max %f. Traces %d", speed, g_fBenchGrabMin, g_fBenchGrabAvg / g_iBenchGrabTicks, g_fBenchGrabMax, frameTraces);
	#endif
	return Plugin_Continue;
}



// ====================================================================================================
//					VARIOUS HELPERS
// ====================================================================================================
void FireEventsFootlocker(int client, int target, int type, bool spawner)
{
	Event hEvent = CreateEvent("item_pickup", true);
	if( hEvent != null )
	{
		hEvent.SetInt("userid", GetClientUserId(client));
		hEvent.SetString("item", g_sPickups[type]);
		hEvent.Fire();
	}

	if(spawner)
	{
		hEvent = CreateEvent("spawner_give_item", true);
		if( hEvent != null )
		{
			hEvent.SetInt("userid", GetClientUserId(client));
			hEvent.SetString("item", g_sPickups[type]);
			hEvent.SetInt("spawner", target);
			hEvent.Fire();
		}
	}

	hEvent = CreateEvent("player_use", true);
	if( hEvent != null )
	{
		hEvent.SetInt("userid", GetClientUserId(client));
		hEvent.SetInt("targetid", target);
		hEvent.Fire();
	}
}

void FireEventsGeneral(int client, int target, int weapon, int type)
{
	int weaponid;

	if( g_bLeft4Dead2 )
	{
		switch( type )
		{
			case TYPE_ADREN:	weaponid = 23;		// weapon_adrenaline
			case TYPE_PILLS:	weaponid = 15;		// weapon_pain_pills
			case TYPE_MOLO:		weaponid = 13;		// weapon_molotov
			case TYPE_PIPE:		weaponid = 14;		// weapon_pipe_bomb
			case TYPE_VOMIT:	weaponid = 25;		// weapon_vomitjar
			case TYPE_FIRST:	weaponid = 12;		// weapon_first_aid_kit
			case TYPE_EXPLO:	weaponid = 31;		// weapon_upgradepack_explosive
			case TYPE_INCEN:	weaponid = 30;		// weapon_upgradepack_incendiary
			case TYPE_DEFIB:	weaponid = 24;		// weapon_defibrillator
		}
	} else {
		switch( type )
		{
			case TYPE_FIRST:	weaponid = 8;		// weapon_first_aid_kit
			case TYPE_MOLO:		weaponid = 9;		// weapon_molotov
			case TYPE_PIPE:		weaponid = 10;		// weapon_pipe_bomb
			case TYPE_PILLS:	weaponid = 12;		// weapon_pain_pills
		}
	}

	Event hEvent = CreateEvent("weapon_given");
	if( hEvent )
	{
		hEvent.SetInt("userid", GetClientUserId(target));
		hEvent.SetInt("giver", GetClientUserId(client));
		hEvent.SetInt("weapon", weaponid);
		hEvent.SetInt("weaponentid", weapon);
		hEvent.Fire();
	}

	hEvent = CreateEvent("give_weapon");
	if( hEvent )
	{
		hEvent.SetInt("userid", GetClientUserId(client));
		hEvent.SetInt("recipient", GetClientUserId(target));
		hEvent.SetInt("weapon", weaponid);
		hEvent.Fire();
	}
}

bool HasSpectator(int client)
{
	if( g_bCvarIdle ) return false; // Allow transfer with idle players

	static char classname[12];
	GetEntityNetClass(client, classname, sizeof(classname));

	if( strcmp(classname, "SurvivorBot") == 0 && GetEntProp(client, Prop_Send, "m_humanSpectatorUserID") == 0 )
		return false;
	return true;
}

bool IsReviving(int client)
{
	if( GetEntPropEnt(client, Prop_Send, "m_reviveOwner") > 0 )
		return true;
	return false;
}

bool IsIncapped(int client)
{
	if( GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0 )
		return true;
	return false;
}

int GetItemType(const char[] classname)
{
	for( int i = 0; i < MAX_TYPES; i++ )
	{
		if( strncmp(classname[7], g_sPickups[i][7], 13) == 0 )
			return i;
	}
	return -1;
}

int GetItemSlot(int type)
{
	if( type <= TOP_INDEX_MEDS )	return SLOT_MEDS;
	if( type <= TOP_INDEX_NADE )	return SLOT_NADE;
	if( type <= TOP_INDEX_PACK )	return SLOT_PACK;
	return 0;
}

bool AllowedToTransfer(int type)
{
	if( g_iCvarTypes & (1<<type) )
		return true;
	return false;
}

bool BotAllowedTransfer(int type, bool give)
{
	if( type == -1 )							return false;
	if( give && g_iCvarGive & (1<<type-1) )		return true;
	if( !give && g_iCvarGrab & (1<<type-1) )	return true;
	return false;
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}



// ====================================================================================================
//					VOCALIZE
// ====================================================================================================
void Vocalize(int client, int type)
{
	if( g_iCvarVocalize == 0 || GetGameTime() < g_fBlockVocalize )
		return;

	// Don't need to vocalize these
	if( type != TYPE_PIPE && type != TYPE_MOLO && type != TYPE_FIRST ) return;



	// Declare variables
	int surv, min, max;
	static char model[40];

	// Get survivor model
	GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));

	switch( model[29] )
	{
		case 'c': { model = "coach";		surv = 1; }
		case 'b': { model = "gambler";		surv = 2; }
		case 'h': { model = "mechanic";		surv = 3; }
		case 'd': { model = "producer";		surv = 4; }
		case 'v': { model = "NamVet";		surv = 5; }
		case 'e': { model = "Biker";		surv = 6; }
		case 'a': { model = "Manager";		surv = 7; }
		case 'n': { model = "TeenGirl";		surv = 8; }
		default:
		{
			int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");

			if( g_bLeft4Dead2 )
			{
				switch( character )
				{
					case 0:	{ model = "gambler";		surv = 2; } // Nick
					case 1:	{ model = "producer";		surv = 4; } // Rochelle
					case 2:	{ model = "coach";			surv = 1; } // Coach
					case 3:	{ model = "mechanic";		surv = 3; } // Ellis
					case 4:	{ model = "NamVet";			surv = 5; } // Bill
					case 5:	{ model = "TeenGirl";		surv = 8; } // Zoey
					case 6:	{ model = "Biker";			surv = 6; } // Francis
					case 7:	{ model = "Manager";		surv = 7; } // Louis
				}
			} else {
				switch( character )
				{
					case 0:	 { model = "TeenGirl";		surv = 8; } // Zoey
					case 1:	 { model = "NamVet";		surv = 5; } // Bill
					case 2:	 { model = "Biker";			surv = 6; } // Francis
					case 3:	 { model = "Manager";		surv = 7; } // Louis
				}
			}
		}
	}

	// Failed for some reason? Should never happen.
	if( surv == 0 )
		return;

	// Pipe Bomb
	if( type == TYPE_PIPE )
	{
		switch( surv )
		{
			case 1: max = 2;	// Coach
			case 2: max = 1;	// Nick
			case 3: max = 2;	// Ellis
			case 4: max = 1;	// Rochelle
			case 5: max = 3;	// Bill
			case 6: max = 4;	// Francis
			case 7: max = 3;	// Louis
			case 8: max = 1;	// Zoey
		}
	}

	// Molotov
	else if( type == TYPE_MOLO )
	{
		switch( surv )
		{
			case 1: {min = 3; max = 4;}
			case 2: {min = 2; max = 3;}
			case 3: {min = 3; max = 10;}
			case 4: {min = 2; max = 5;}
			case 5: {min = 5; max = 6;}
			case 6: {min = 5; max = 7;}
			case 7: {min = 4; max = 6;}
			case 8: {min = 2; max = 5;}
		}
	}

	// First aid
	else if( type == TYPE_FIRST )
	{
		switch( surv )
		{
			case 1: {min = 5; max = 7;}
			case 2: {min = 4; max = 8;}
			case 3: {min = 11; max = 14;}
			case 4: {min = 6; max = 8;}
			case 5: {min = 7; max = 9;}
			case 6: {min = 8; max = 11;}
			case 7: {min = 7; max = 8;}
			case 8: {min = 6; max = 9;}
		}
	}

	// Random number
	int random = GetRandomInt(min, max);

	// Select random vocalize
	static char sTemp[40];
	switch( surv )
	{
		case 1: Format(sTemp, sizeof(sTemp), g_Coach[random]);
		case 2: Format(sTemp, sizeof(sTemp), g_Nick[random]);
		case 3: Format(sTemp, sizeof(sTemp), g_Ellis[random]);
		case 4: Format(sTemp, sizeof(sTemp), g_Rochelle[random]);
		case 5: Format(sTemp, sizeof(sTemp), g_Bill[random]);
		case 6: Format(sTemp, sizeof(sTemp), g_Francis[random]);
		case 7: Format(sTemp, sizeof(sTemp), g_Louis[random]);
		case 8: Format(sTemp, sizeof(sTemp), g_Zoey[random]);
	}

	// Create scene location and call
	Format(sTemp, sizeof(sTemp), "scenes/%s/%s.vcd", model, sTemp);
	VocalizeScene(client, sTemp);
}



// Taken from:
// [Tech Demo] L4D2 Vocalize ANYTHING
// https://forums.alliedmods.net/showthread.php?t=122270
// author = "AtomicStryker"
// ====================================================================================================
//					VOCALIZE SCENE
// ====================================================================================================
void VocalizeScene(int client, const char[] scenefile)
{
	int entity = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(entity, "SceneFile", scenefile);
	DispatchSpawn(entity);
	SetEntPropEnt(entity, Prop_Data, "m_hOwner", client);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start", client, client);
}

void PlaySound(int client, const char sound[32])
{
	EmitSoundToClient(client, sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}



// ====================================================================================================
//					PRINT TO CHAT
// ====================================================================================================
// Taken from:
// https://docs.sourcemod.net/api/index.php?fastload=show&id=151&
void GearTransferPrintToChatAll(int client, const char[] format, any ...)
{
	static char buffer[192];

	if( g_iCvarNotify & NOTIFY_CLIENT )
	{
		if( IsClientInGame(client) && !IsFakeClient(client) )
		{
			SetGlobalTransTarget(client);
			VFormat(buffer, sizeof(buffer), format, 3);
			CPrintToChat(client, "%s", buffer);
		}
	}
	else
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && !IsFakeClient(i) )
			{
				SetGlobalTransTarget(i);
				VFormat(buffer, sizeof(buffer), format, 3);
				CPrintToChat(i, "%s", buffer);
			}
		}
	}
}

void MPrintToChatAll(int client, const char[] phrase, const char[] item, int target)
{
	static char clientName[192];
	static char targetName[192];
	static char pickupItem[192];

	int max = g_iCvarNotify & NOTIFY_CLIENT ? 2 : MaxClients;
	int user;

	for( int i = 1; i <= max; i++ )
	{
		if( max == 2 )
		{
			if( i == 2 )
				user = target;
			else
				user = client;
		}
		else
		{
			user = i;
		}

		if( IsClientInGame(user) && !IsFakeClient(user) )
		{
			SetGlobalTransTarget(user);
			pickupItem = Translate(user, "{green}%t{default}", item);
			clientName = Translate(user, "{olive}%N{default}", client);

			if( target == 0 )	// Announcing Bot auto-grabs an item
			{
				CPrintToChat(user, "%t", phrase, clientName, pickupItem);
			}
			else
			{
				targetName = Translate(user, "{olive}%N{default}", target);
				CPrintToChat(user, "%t", phrase, clientName, pickupItem, targetName);
			}
		}
	}
}



// ====================================================================================================
//					TRANSLATE
// ====================================================================================================
char[] Translate(int client, const char[] format, any ...)
{
	char buffer[192];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	return buffer;
}



/// ====================================================================================================
//					TRACE RAY
// ====================================================================================================
// Taken from:
// plugin = "L4D_Splash_Damage"
// author = "AtomicStryker"
bool IsVisibleTo(float position[3], float targetposition[3])
{
	static float vAngles[3], vLookAt[3];

	MakeVectorFromPoints(position, targetposition, vLookAt); // compute vector from start to target
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace

	// execute Trace
	static Handle trace;
	trace = TR_TraceRayFilterEx(position, vAngles, MASK_ALL, RayType_Infinite, _TraceFilter);

	static bool isVisible;
	isVisible = false;

	if( TR_DidHit(trace) )
	{
		static float vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint

		if( (GetVectorDistance(position, vStart, false) + 25.0 ) >= GetVectorDistance(position, targetposition))
		{
			isVisible = true; // if trace ray length plus tolerance equal or bigger absolute distance, you hit the target
		}
	}

	delete trace;
	return isVisible;
}

bool _TraceFilter(int entity, int contentsMask)
{
	if( entity <= MaxClients || !IsValidEntity(entity) )
		return false;
	return true;
}
