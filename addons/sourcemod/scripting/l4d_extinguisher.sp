/*
*	Extinguisher and Flamethrower
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



#define PLUGIN_VERSION		"1.23"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Extinguisher and Flamethrower
*	Author	:	SilverShot
*	Descrp	:	Usable Extinguishers.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=160232
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.23 (25-May-2023)
	- Made the last change compatible with L4D1. Thanks to "Ja-Forces" for reporting.

1.22 (31-Mar-2023)
	- Changed the method for detecting nearby fires to be accurate and not within a certain range. Fixes fires not extinguishing when they spread out.
	- Changed cvar "l4d_extinguisher_incap" adding option "2" supporting the "Incapped Weapons" plugin.
	- Fixed not being able to use the extinguisher when someone is healing you.
	- Fixed the weapon showing after crawling while incapped and holding an Extinguisher.
	- Thanks to "swiftswing1" for the bug reports and testing.

1.21 (20-Jun-2022)
	- Extinguisher is now blocked when "using" something, e.g. buttons.

1.20 (15-Jun-2022)
	- Made refueling with gascans compatible with the "Scavenge Pouring - Unleaded Gas Only" plugin.

1.19 (01-Mar-2022)
	- Changed where sounds are played so they're clearer and louder. Thanks to "swiftswing1" for reporting.
	- Fixed Spanish translation. File "translations/es/extinguisher.phrases.txt" has been updated. Thanks to "swiftswing1" for reporting.

1.18 (19-Oct-2021)
	- Fixed the extinguisher equipping over the Chainsaw. Thanks to "swiftswing1" for reporting.
	- Fixed zooming sniper scopes when using the zoom button with an extinguisher equipped. Thanks to "swiftswing1" for reporting.
	- Zooming still occurs for a split second. Would probably require detouring "CTerrorGun::CanZoom" or something similar to totally block.
	- Changed some code which only works in SM 1.10 or newer.

1.17 (11-Jul-2021)
	- L4D2: Fixed not attaching the Extinguisher correctly to "Coach" and some L4D1 characters in L4D2. Probably broken in game recent updates.

1.16 (01-Jul-2021)
	- Added a warning message to suggest installing the "Scavenge Score Fix - Gascan Pouring", "Attachments API" and "Use Priority Patch" plugins if missing.
	- Increased the range of which you can extinguish fires from. Thanks to "mikaelangelis" for reporting and testing.

1.15 (15-Feb-2021)
	- Fixed "Cannot create new entity when no map is running" error. Thanks to "Dragokas" for reporting.
	- Fixed "Property "m_flFrozen" not found" error. Thanks to "Mi.Cura" for reporting and "Marttt" for fixing.

1.14 (30-Sep-2020)
	- Fixed compile errors on SM 1.11.

1.13 (15-Jul-2020)
	- Fixed players getting stuck when an extinguisher breaks during pick up. Thanks to "xZk" for reporting.
	- Fixed L4D1 throwing errors from blocking glow cvars. Thanks to no one for reporting.
	- Made compatible with the "Weapon Charms" plugin version 1.7+ only.

1.12 (15-May-2020)
	- Fixed the Blast Pushback type not flinging players when they are too close.
	- Fixed the Extinguisher not displaying after reviving someone.
	- Replaced "point_hurt" entity with "SDKHooks_TakeDamage" function.

1.11 (10-May-2020)
	- Added better error log message when gamedata file is missing.
	- Blocked glow convars being generated for L4D1 which does not support glows.
	- Fixed Blast Pushback type making players stumble instead of throwing them due to 1.9.2 changes.
	- Various changes to tidy up code.
	- Various optimizations and fixes.

1.10 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.
	- Removed "colors.inc" dependency.
	- Updated these translation file encodings to UTF-8 (to display all characters correctly): Danish (da), German (de).

1.9.3 (04-Mar-2020)
	- Minor changes to source, has no affect.

1.9.2 (10-Oct-2019)
	- Fixed entity leak - not deleting an entity after use.
	- Blast Pushback now pushes Common and Witches away.

1.9.1 (28-Jun-2019)
	- Changed PrecacheParticle method.

1.9 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed cvar "l4d_extinguisher_modes_tog" now supports L4D1.

1.8.4 (12-Jun-2015)
	- Fixed the plugin not compiling on SourceMod 1.7.x.

1.8.3 (18-Aug-2013)
	- Fixed the Extinguisher being active when using a mounted gun. - Thanks to "Herbie" for reporting.

1.8.2 (21-Jul-2013)
	- Removed Sort_Random work-around. This was fixed in SourceMod 1.4.7, all should update or spawning issues will occur.

1.8.1 (07-Oct-2012)
	- Fixed the Extinguisher blocking players +USE by adding a single line of code - Thanks to "Machine".

1.8 (10-Jul-2012)
	- Fixed hurting players behind you.

1.7 (25-May-2012)
	- Added cvar "l4d_extinguisher_vomit" to remove the boomer vomit effect from players on the first spray.
	- Fixed the Extinguisher type not causing damage when combo cvar was set to 0.
	- Fixed Louis and Zoey effects spraying in the wrong direction in L4D2.

1.6 (21-May-2012)
	- Added German translations - Thanks to "Dont Fear The Reaper".

1.6 (10-May-2012)
	- Added cvar "l4d_extinguisher_time" to control how long players have to shoot when standing in fire before removing it.
	- Fixed the fires not being removed properly.
	- Fixed the extinguisher not appearing after throwing held objects.
	- Fixed refuel hints displaying in L4D1, refilling with gascans cannot work in L4D1.
	- Small changes.

1.5 (30-Mar-2012)
	- Added cvar "l4d_extinguisher_modes_off" to control which game modes the plugin works in.
	- Added cvar "l4d_extinguisher_modes_tog" same as above, but only works for L4D2.
	- Changed cvar "l4d_extinguisher_hint" added options 3 and 4.
	- Fixed errors the last update caused when Exintguishers were broken by things such as molotovs.
	- Fixed hookevent errors in L4D1, refilling with gascans cannot work in L4D1.
	- Fixed not being able to use pistols when incapped and being revived.
	- Fixed the extinguisher not showing in first person view when equipped after being snared or incapped.
	- Fixed a bug where deleting Extinguishers would also delete "type" entries.
	- Made it easier to extinguish fires by increasing the range which is detected.
	- Optimized the plugin by only creating PreThink hooks when Extinguishers/Gascans are equipped.
	- Optimized the plugin by not detecting the creation of prop_physics models.
	- Stopped setting freezerspray glow on common infected which already have a glow enabled.

1.4 (01-Dec-2011)
	- Fixed players getting stuck when an Extinguisher is broken and they are picking it up.

1.3 (01-Dec-2011)
	- Added Extinguishers to these maps: Crash Course, Death Toll, Dead Air, Blood Harvest, Cold Stream.
	- Added Russian translations - Thanks to "disawar1".
	- Added cvar l4d_extinguisher_incap so the Extinguisher can be used when incapacitated.
	- Added a new translation to notify players they can use the Extinguisher while incapped, if enabled.
	- Added a new translation when the Extinguisher is empty notifying players they can refuel with gas cans.
	- Fixed being able to use the Extinguisher while ridden by a jockey.
	- Fixed l4d_extinguisher_max cvar, limiting how many extinguishers can be used simultaneously.
	- Fixed the Extinguisher attachment position on Zoey.
	- Hides the Extinguisher from a players personal view when not equipped.
	- Made the translation files a requirement for the plugin to work error free.
	- Removed slot cvar. Picking up Extinguishers with pistols uses that slot. Other items default to the primary slot.

1.2 (01-Jul-2011)
	- Added refueling of dropped extinguishers.
	- Added new translations for the above.

1.1 (28-Jun-2011)
	- Fixed the type cvar not setting correctly when combo cvar was enabled.
	- Removed bad spawns from the data config.

1.0 (26-Jun-2011)
	- Initial release.

======================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "DJ_WEST" For Chainsaw Refueling code showing usage of point_prop_use_target.
	https://forums.alliedmods.net/showthread.php?t=121983

======================================================================================*/

#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <readyup>

#define CVAR_FLAGS				FCVAR_NOTIFY
#define GAMEDATA				"l4d_extinguisher"
#define CONFIG_SPAWNS			"data/l4d_extinguisher.cfg"
#define MAX_ALLOWED				32

#define ATTACHMENT_BONE			"weapon_bone"
#define ATTACHMENT_EYES			"eyes"
#define ATTACHMENT_PRIMARY		"primary"
#define ATTACHMENT_ARM			"armR_T"

#define MODEL_EXTINGUISHER		"models/props/cs_office/Fire_Extinguisher.mdl"
#define MODEL_BOUNDING			"models/props/cs_militia/silo_01.mdl"
#define PARTICLE_RAND			"molotov_explosion_child_burst"
#define PARTICLE_FIRE1			"fire_jet_01_flame"
#define PARTICLE_FIRE2			"fire_small_02"
#define PARTICLE_SPRAY			"extinguisher_spray"
#define PARTICLE_BLAST1			"impact_steam_short"
#define PARTICLE_BLAST2			"charger_wall_impact_b"
#define SOUND_FIRE_L4D1			"ambient/Spacial_Loops/CarFire_Loop.wav"
#define SOUND_FIRE_L4D2			"ambient/fire/interior_fire02_stereo.wav"
#define SOUND_SPRAY				"ambient/gas/cannister_loop.wav"
#define SOUND_BLAST				"weapons/molotov/fire_ignite_4.wav"


ConVar g_hCvarAllow, g_hCvarBreak, g_hCvarCheck, g_hCvarCombo, g_hCvarDamage, g_hCvarFlame, g_hCvarFreq, g_hCvarFriend, g_hCvarFuel, g_hCvarGlowB, g_hCvarGlowE, g_hCvarGlowF, g_hCvarGlowRan, g_hCvarGlowS, g_hCvarGrab, g_hCvarHint, g_hCvarIncap, g_hCvarMax, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarPush, g_hCvarPushFuel, g_hCvarPushTime, g_hCvarRandom, g_hCvarRange, g_hCvarRemove, g_hCvarSpray, g_hCvarTime, g_hCvarTimeOut, g_hCvarTimed, g_hCvarType, g_hCvarView, g_hCvarVomit, g_hCvarWeapon;
int g_iCvarBreak, g_iCvarCheck, g_iCvarCombo, g_iCvarDamage, g_iCvarFlame, g_iCvarFriend, g_iCvarFuel, g_iCvarGlowB, g_iCvarGlowE, g_iCvarGlowF, g_iCvarGlowRan, g_iCvarGlowS, g_iCvarGrab, g_iCvarHint, g_iCvarIncap, g_iCvarMax, g_iCvarPush, g_iCvarPushFuel, g_iCvarRandom, g_iCvarRemove, g_iCvarSpray, g_iCvarTime, g_iCvarType, g_iCvarView, g_iCvarVomit;
bool g_bCvarAllow, g_bMapStarted, g_bCvarCrawl;
char g_sCvarWeapon[32];
float g_fCvarFreq, g_fCvarPushTime, g_fCvarRange, g_fCvarTimed, g_fCvarTimeout;

ConVar g_hCvarMPGameMode, g_hCvarCrawl;
Handle g_hSdkVomit, g_hTimerTrace;
bool g_bGlow, g_bLeft4Dead2;
int g_iLoadStatus, g_iOffsetGlow, g_iPlayerSpawn, g_iRoundStart, g_iSpawnCount;
int g_iWallExt[MAX_ALLOWED][3];		// Wall extinguishers: [0] = prop_physics, [1] = func_button, [2] = Type.
int g_iDropped[MAX_ALLOWED][4];		// Dropped extinguishers: [0] = prop_physics, [1] = func_button, [2] = Fuel, [3] = Type.
int g_iSpawned[MAX_ALLOWED][4];		// Spawned extinguishers: [0] = prop_physics, [1] = func_button, [2] = Fuel, [3] = Type.
int g_iInferno[MAX_ALLOWED][2];		// Del molotov/fireworks: [0] = inferno / fire_cracker_blast / insect_swarm, [1] = Count
int g_iPlayerData[MAXPLAYERS+1][6];	// [0] = prop_dynamic, [1] = info_particle, [2] = Light, [3] = Fuel, [4] = Type, [5] Blocked use.
int g_iRefuel[MAXPLAYERS+1][3];		// [0] = Gascan Index, [1] = point_prop_use_target, [2] = g_iDropped extinguisher index.
int g_iGunSlot[MAXPLAYERS+1];		// [0] = Primary Slot, [1] = Melee, [2] = Melee slot when incapped (returns to 0 after).
int g_iHooked[MAXPLAYERS+1];		// SDKHooks PreThink 0=Off/1=On.
int g_iZoomed[MAXPLAYERS+1];		// Bool to set when zoomed and frame requested to unzoom
int g_iButtons[MAXPLAYERS+1];		// Last buttons held
float g_fTimeout[MAXPLAYERS+1];		// Timeouts


enum
{
	ENUM_WALLEXT	= (1 << 0),
	ENUM_DROPPED	= (1 << 1),
	ENUM_SPAWNED	= (1 << 2),
	ENUM_BLOCKED	= (1 << 3),
	ENUM_INCAPPED	= (1 << 4),
	ENUM_LEDGEBLOCK	= (1 << 5),
	ENUM_INREVIVE	= (1 << 6)
}
enum
{
	ENUM_EXTINGUISHER	= (1 << 0),
	ENUM_FLAMETHROWER	= (1 << 1),
	ENUM_FREEZERSPRAY	= (1 << 2),
	ENUM_BLASTPUSHBACK	= (1 << 3)
}
enum
{
	TYPE_EXTINGUISHER = 1,
	TYPE_FLAMETHROWER,
	TYPE_FREEZERSPRAY,
	TYPE_BLASTPUSHBACK
}
enum
{
	INDEX_PROP,
	INDEX_PART,
	INDEX_LIGHT,
	INDEX_FUEL,
	INDEX_TYPE,
	INDEX_BLOCK
}
enum
{
	SLOT_PRIMARY,
	SLOT_SECONDARY,
	SLOT_TEMP_PRI,
	SLOT_TEMP_SEC,
	SLOT_CURRENT_PRI,
	SLOT_CURRENT_SEC
}

// "Weapon Charms" plugin compatibility
bool g_bCharmsPlugin;
native void Charms_Create(int client, int index = 0);
native void Charms_Delete(int client);
native int Charms_GetIndex(int client);



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Extinguisher and Flamethrower",
	author = "SilverShot",
	description = "Usable Extinguishers.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=160232"
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

	MarkNativeAsOptional("Charms_Create");
	MarkNativeAsOptional("Charms_Delete");
	MarkNativeAsOptional("Charms_GetIndex");

	return APLRes_Success;
}

public void OnLibraryAdded(const char[] name)
{
	if( strcmp(name, "charms_silvers") == 0 )
		g_bCharmsPlugin = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if( strcmp(name, "charms_silvers") == 0 )
		g_bCharmsPlugin = false;
}
public void OnRoundLiveCountdownPre(){
	for(int i = 1; i <= MaxClients; i++){
		if (IsClientInGame(i)){
			DropExtinguisher(i);
		}
	}
}

public void OnRoundIsLive(){
	OnRoundLiveCountdownPre();
}


public void OnAllPluginsLoaded()
{
	// Attachments API
	if( FindConVar("attachments_api_version") == null && ((g_bLeft4Dead2 && FindConVar("l4d2_swap_characters_version") != null) || FindConVar("l4d_csm_version") != null) )
	{
		LogMessage("\n==========\nWarning: You should install \"[ANY] Attachments API\" to fix model attachments when changing character models: https://forums.alliedmods.net/showthread.php?t=325651\n==========\n");
	}

	// Scavenge Score Fix
	if( g_bLeft4Dead2 && FindConVar("l4d2_scavenge_score_fix") == null )
	{
		LogMessage("\n==========\nWarning: You should install \"[L4D2] Scavenge Score Fix - Gascan Pouring\" to prevent affecting the score when filling gas in Scavenge style events: https://forums.alliedmods.net/showthread.php?t=187686\n==========\n");
	}

	// Use Priority Patch
	if( FindConVar("l4d_use_priority_version") == null )
	{
		LogMessage("\n==========\nWarning: You should install \"[L4D & L4D2] Use Priority Patch\" to fix attached models blocking +USE action: https://forums.alliedmods.net/showthread.php?t=327511\n==========\n");
	}
}

public void OnPluginStart()
{
	// SDK Calls
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnITExpired") == false )
		SetFailState("Failed to find signature: CTerrorPlayer::OnITExpired");

	delete hGameData;
	g_hSdkVomit = EndPrepSDKCall();

	if( g_hSdkVomit == null )
		SetFailState("Failed to create SDKCall: CTerrorPlayer::OnITExpired");


	// Translations
	BuildPath(Path_SM, sPath, sizeof(sPath), "translations/extinguisher.phrases.txt");
	if( !FileExists(sPath) )
		SetFailState("Required translation file is missing: 'translations/extinguisher.phrases.txt'");

	LoadTranslations("extinguisher.phrases");
	LoadTranslations("common.phrases");

	// Cvars
	g_hCvarAllow = CreateConVar(		"l4d_extinguisher_allow",		"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarBreak = CreateConVar(		"l4d_extinguisher_break",		"2",			"0=No break, 1=Valve default breaks when damaged, 2=Breaks and cannot be used, 3=Same as 2 but special infected can't break.", CVAR_FLAGS);
	g_hCvarCheck = CreateConVar(		"l4d_extinguisher_check",		"0",			"Players must have the l4d_extinguisher_weapon to equip and use Extinguishers.", CVAR_FLAGS);
	g_hCvarCombo = CreateConVar(		"l4d_extinguisher_combo",		"255 255 255",	"0=Off. Otherwise all Extinguisher functions in one. Sets the Extinguisher glow color. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS);
	g_hCvarDamage = CreateConVar(		"l4d_extinguisher_damage",		"1",			"How much damage the Extinguisher does per touch when fired. Triggered according to frequency cvar.", CVAR_FLAGS);
	g_hCvarFlame = CreateConVar(		"l4d_extinguisher_flame",		"2",			"Flamethrower particles and glow. 0=Flame type A, 1=Flame type B, 2=Type A + Light, 3=Type B + Light.", CVAR_FLAGS);
	g_hCvarFreq = CreateConVar(			"l4d_extinguisher_frequency",	"0.1",			"How often the damage trace fires, igniting entities etc.", CVAR_FLAGS);
	g_hCvarFriend = CreateConVar(		"l4d_extinguisher_friendly",	"1",			"0=Off, 1=Friendly fire, allow survivors to hurt each other, 2=Only hurt survivors from the Blast type.", CVAR_FLAGS);
	g_hCvarFuel = CreateConVar(			"l4d_extinguisher_fuel",		"1000",			"0=Infinite, How much fuel each Extinguisher has. Consumption is based on how often the PreThink fires.", CVAR_FLAGS);
	if( g_bLeft4Dead2 )
	{
	g_hCvarGlowRan = CreateConVar(		"l4d_extinguisher_glow",		"150",			"0=Glow Off. Any other value sets the range at which extinguishers glow.", CVAR_FLAGS);
	g_hCvarGlowB = CreateConVar(		"l4d_extinguisher_glow_blast",	"255 255 0",	"0=Valve default. Any other value sets glow color for blast pushback.", CVAR_FLAGS);
	g_hCvarGlowE = CreateConVar(		"l4d_extinguisher_glow_extin",	"0 255 0",		"0=Valve default. Any other value sets glow color for extinguishers.", CVAR_FLAGS);
	g_hCvarGlowF = CreateConVar(		"l4d_extinguisher_glow_flame",	"255 0 0",		"0=Valve default. Any other value sets glow color for flamethrowers.", CVAR_FLAGS);
	g_hCvarGlowS = CreateConVar(		"l4d_extinguisher_glow_spray",	"0 150 255",	"0=Valve default. Any other value sets glow color for freezer sprays.", CVAR_FLAGS);
	}
	g_hCvarGrab = CreateConVar(			"l4d_extinguisher_grab",		"32",			"0=Off, How many pre-existing extinguishers on maps can this plugin cater for.", CVAR_FLAGS);
	g_hCvarHint = CreateConVar(			"l4d_extinguisher_hint",		"1",			"0=Off, 1=Display hints from translation file, 2=Not when Broken, 3=Not when Refueled, 4=Not when Broken or Refueled.", CVAR_FLAGS);
	g_hCvarIncap = CreateConVar(		"l4d_extinguisher_incap",		"1",			"0=Off, 1=Allow the Extinguisher to be used when incapacitated (temporarily switches Extinguisher to pistol slot). 2=Stay on the slot being used for Extinguishers (support for Incapped Weapons plugin).", CVAR_FLAGS);
	g_hCvarMax = CreateConVar(			"l4d_extinguisher_max",			"0",			"Maximum number of players allowed to have the Extinguisher at once.", CVAR_FLAGS);
	g_hCvarModes =	CreateConVar(		"l4d_extinguisher_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(		"l4d_extinguisher_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(		"l4d_extinguisher_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarPush =	CreateConVar(		"l4d_extinguisher_push",		"400",			"When hit by the blast type, push players/infected by this much force.", CVAR_FLAGS );
	g_hCvarPushFuel = CreateConVar(		"l4d_extinguisher_push_fuel",	"25",			"0=Infinite, How much fuel to take away when using the blast pushback type.", CVAR_FLAGS);
	g_hCvarPushTime = CreateConVar(		"l4d_extinguisher_push_time",	"0.5",			"How long after using the blast pushback type before it can be used again.", CVAR_FLAGS);
	g_hCvarRandom = CreateConVar(		"l4d_extinguisher_random",		"1",			"0=Off, -1=All, any other value sets how many randomly auto spawn from the config.", CVAR_FLAGS);
	g_hCvarRange = CreateConVar(		"l4d_extinguisher_range",		"150",			"How far the Extinguisher can affect entities.", CVAR_FLAGS);
	g_hCvarRemove = CreateConVar(		"l4d_extinguisher_remove",		"0",			"0=Off, 1=Remove extinguishers after being broken, 2=Remove when out of fuel, 3=Remove when broken or out of fuel.", CVAR_FLAGS);
	g_hCvarSpray = CreateConVar(		"l4d_extinguisher_spray",		"7",			"What can be extinguished with the Extinguisher type? 1=Molotovs/Barrels, 2=Firework Explosions, 4=Spitter Acid, 7=All.", CVAR_FLAGS);
	g_hCvarTime = CreateConVar(			"l4d_extinguisher_time",		"8",			"How long players have to shoot the Extinguisher type when standing in a fire before it can be removed.", CVAR_FLAGS);
	g_hCvarTimed = CreateConVar(		"l4d_extinguisher_timed",		"1.0",			"How long does it take to pick up extinguishers.", CVAR_FLAGS);
	g_hCvarTimeOut = CreateConVar(		"l4d_extinguisher_timeout",		"0.2",			"How long after using the Extinguisher till you can use it again.", CVAR_FLAGS);
	g_hCvarType = CreateConVar(			"l4d_extinguisher_type",		"15",			"Which types are allowed: 1=Extinguisher, 2=Flamethrower, 4=Freezer spray, 8=Blast, 15=All.", CVAR_FLAGS);
	g_hCvarView = CreateConVar(			"l4d_extinguisher_view",		"1",			"When clients hold the Extinguisher: 0=Show it, 1=Show it and hide their weapon, 2=Show their weapon and hide Extinguisher, 3=Same as 2 but others can see the Extinguisher.", CVAR_FLAGS);
	g_hCvarVomit = CreateConVar(		"l4d_extinguisher_vomit",		"5",			"Remove the boomer vomit effect from players on the first spray. 0=Off, 1=Extinguisher, 2=Flamethrower, 4=Blast type, 7=All.", CVAR_FLAGS);
	g_hCvarWeapon = CreateConVar(		"l4d_extinguisher_weapon",		"",				"\"\"=All (must set l4d_extinguisher_check to 0). Weapon entity name to replace and use for the Extinguisher.", CVAR_FLAGS);
	CreateConVar(						"l4d_extinguisher_version",		PLUGIN_VERSION,	"Extinguisher plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	//AutoExecConfig(true,				"l4d_extinguisher");

	g_hCvarCrawl = FindConVar("survivor_allow_crawling");
	g_hCvarCrawl.AddChangeHook(ConVarChanged_Cvars);

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarBreak.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarCheck.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarCombo.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDamage.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFlame.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFreq.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFriend.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFuel.AddChangeHook(ConVarChanged_Cvars);
	if( g_bLeft4Dead2 )
	{
	g_hCvarGlowRan.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarGlowB.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarGlowE.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarGlowF.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarGlowS.AddChangeHook(ConVarChanged_Cvars);
	}
	g_hCvarGrab.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHint.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarIncap.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMax.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPush.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPushFuel.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPushTime.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRandom.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRange.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRemove.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpray.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTime.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimed.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimeOut.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarType.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarView.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarVomit.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWeapon.AddChangeHook(ConVarChanged_Cvars);
	RegConsoleCmd(	"sm_dropext",	CmdDrop,						"Drops an equipped extinguisher. Admins usage: sm_dropext <#userid|name>. No arguments = self.");
	RegConsoleCmd(	"sm_giveext",	CmdGive,						"Gives extinguisher. Usage: sm_giveext <1|2|3|4> (give to self, where 1=Extinguisher, 2=Flamethrower, 3=Freezerspray, 4=Blast Pushback) or <#userid|name> <type: 1|2|3|4>");
	RegAdminCmd(	"sm_spawnext",	CmdSpawn,		ADMFLAG_ROOT,	"Spawns an extinguisher at your crosshair location. Usage: sm_spawnext <1|2|3|4> (1=Extinguisher, 2=Flamethrower, 3=Freezerspray, 4=Blast Pushback)");
	RegAdminCmd(	"sm_extwep",	CmdExtWep,		ADMFLAG_ROOT,	"Gives the l4d_extinguisher_weapon to the target player(s). Usage: sm_extwep <#userid|name>. No arguments = self.");
	RegAdminCmd(	"sm_extsave",	CmdExtSave,		ADMFLAG_ROOT,	"Spawns a extinguisher at your crosshair and saves to config. Usage: sm_extsave <1|2|4|8> 1=Extinguisher, 2=Flamethrower, 4=Freezerspray, 8=Blast Pushback, 15=Any.");
	RegAdminCmd(	"sm_extang",	CmdExtAng,		ADMFLAG_ROOT,	"Set angle of extinguisher behind crosshair. Only works on sm_extsave extinguishers.");
	RegAdminCmd(	"sm_extpos",	CmdExtPos,		ADMFLAG_ROOT,	"Set position of extinguisher behind crosshair. Only works on sm_extsave extinguishers.");
	RegAdminCmd(	"sm_extset",	CmdExtSet,		ADMFLAG_ROOT,	"Save to the config the ang/pos of extinguisher behind crosshair if spawned with sm_extsave.");
	RegAdminCmd(	"sm_extdel",	CmdExtDelete,	ADMFLAG_ROOT,	"Removes the extinguisher your crosshair is pointing at.");
	RegAdminCmd(	"sm_extclear",	CmdExtClear,	ADMFLAG_ROOT,	"Removes all extinguishers from the current map (except those equipped by players).");
	RegAdminCmd(	"sm_extwipe",	CmdExtWipe,		ADMFLAG_ROOT,	"Removes all extinguishers from the current map and deletes them from the config.");
	RegAdminCmd(	"sm_extlist",	CmdExtList,		ADMFLAG_ROOT,	"Display a list extinguisher positions and the number of extinguishers.");

	AddCommandListener(CommandListenerGive, "give");

	if( g_bLeft4Dead2 )
	{
		RegAdminCmd("sm_extglow",	CmdExtGlow,		ADMFLAG_ROOT,	"Toggle to enable glow on all extinguishers to see where they are placed.");
		g_iOffsetGlow = FindSendPropInfo("prop_physics", "m_nGlowRange");
	}
}

public void OnPluginEnd()
{
	ResetPlugin();
}

void ResetPlugin()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	g_iLoadStatus = 0;

	KillEnts();

	for( int i = 1; i <= MaxClients; i++ )
	{
		g_fTimeout[i] = 0.0;
		g_iHooked[i] = 0;
		g_iZoomed[i] = 0;
		g_iButtons[i] = 0;

		int entity = g_iRefuel[i][1];
		if( IsValidEntRef(entity) )
			RemoveEntity(entity);

		if( IsClientInGame(i) )
		{
			KillAttachments(i, true);

			if( g_iHooked[i] )
			{
				g_iHooked[i] = 0;
				SDKUnhook(i, SDKHook_PreThink, OnPreThink);
			}
		}
	}
}

public void OnMapStart()
{
	g_bMapStarted = true;

	PrecacheModel(MODEL_EXTINGUISHER, true);
	PrecacheModel(MODEL_BOUNDING, true);

	PrecacheParticle(PARTICLE_RAND);
	PrecacheParticle(PARTICLE_FIRE1);
	PrecacheParticle(PARTICLE_FIRE2);
	PrecacheParticle(PARTICLE_SPRAY);
	PrecacheParticle(PARTICLE_BLAST1);
	if( g_bLeft4Dead2 )
		PrecacheParticle(PARTICLE_BLAST2);

	PrecacheSound(SOUND_SPRAY, true);
	PrecacheSound(SOUND_BLAST, true);
	if( g_bLeft4Dead2 )
		PrecacheSound(SOUND_FIRE_L4D2, true);
	else
		PrecacheSound(SOUND_FIRE_L4D1, true);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
}

Action CommandListenerGive(int client, const char[] command, int args)
{
	if( args > 0 )
	{
		char buffer[8];
		GetCmdArg(1, buffer, sizeof(buffer));

		if( strcmp(buffer, "health", false) == 0 )
		{
			g_iPlayerData[client][INDEX_BLOCK] &= ~ENUM_LEDGEBLOCK;
			g_iPlayerData[client][INDEX_BLOCK] &= ~ENUM_INREVIVE;
			g_iPlayerData[client][INDEX_BLOCK] &= ~ENUM_INCAPPED;

			if( g_iCvarIncap )
			{
				if( g_iCvarIncap != 2 )
				{
					if( g_iGunSlot[client] == SLOT_PRIMARY || g_iGunSlot[client] == SLOT_CURRENT_PRI )
						g_iGunSlot[client] = SLOT_TEMP_PRI;
					else if( g_iGunSlot[client] == SLOT_TEMP_SEC || g_iGunSlot[client] == SLOT_CURRENT_SEC )
						g_iGunSlot[client] = SLOT_SECONDARY;
				}

				// MoveExtinguisher(client, true);
			// }
			// else
			// {
				// MoveExtinguisher(client, false);
			}

			// CreateTimer(0.1, TimerReviveSuccess, GetClientUserId(client));
		}
	}

	return Plugin_Continue;
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

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarCrawl = g_hCvarCrawl.BoolValue;
	g_iCvarBreak = g_hCvarBreak.IntValue;
	g_iCvarCheck = g_hCvarCheck.IntValue;
	g_iCvarCombo = GetColor(g_hCvarCombo);
	g_iCvarDamage = g_hCvarDamage.IntValue;
	g_iCvarFlame = g_hCvarFlame.IntValue;
	g_fCvarFreq = g_hCvarFreq.FloatValue;
	g_iCvarFriend = g_hCvarFriend.BoolValue;
	g_iCvarFuel = g_hCvarFuel.IntValue;
	if( g_bLeft4Dead2 )
	{
	g_iCvarGlowRan = g_hCvarGlowRan.IntValue;
	g_iCvarGlowB = GetColor(g_hCvarGlowB);
	g_iCvarGlowE = GetColor(g_hCvarGlowE);
	g_iCvarGlowF = GetColor(g_hCvarGlowF);
	g_iCvarGlowS = GetColor(g_hCvarGlowS);
	}
	g_iCvarGrab = g_hCvarGrab.IntValue;
	g_iCvarHint = g_hCvarHint.IntValue;
	g_iCvarIncap = g_hCvarIncap.IntValue;
	g_iCvarMax = g_hCvarMax.IntValue;
	g_iCvarPush = g_hCvarPush.IntValue;
	g_iCvarPushFuel = g_hCvarPushFuel.IntValue;
	g_fCvarPushTime = g_hCvarPushTime.FloatValue;
	g_iCvarRandom = g_hCvarRandom.IntValue;
	g_fCvarRange = g_hCvarRange.FloatValue;
	g_iCvarRemove = g_hCvarRemove.IntValue;
	g_iCvarSpray = g_hCvarSpray.IntValue;
	g_iCvarTime = g_hCvarTime.IntValue;
	g_fCvarTimed = g_hCvarTimed.FloatValue;
	g_fCvarTimeout = g_hCvarTimeOut.FloatValue;
	g_iCvarType = g_hCvarType.IntValue;
	g_iCvarView = g_hCvarView.IntValue;
	g_iCvarVomit = g_hCvarVomit.IntValue;
	g_hCvarWeapon.GetString(g_sCvarWeapon, sizeof(g_sCvarWeapon));
}

int GetColor(ConVar hCvar)
{
	char sTemp[12];
	hCvar.GetString(sTemp, sizeof(sTemp));

	if( sTemp[0] == 0 )
		return 0;

	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, sizeof(sColors), sizeof(sColors[]));

	if( color != 3 )
		return 0;

	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);

	return color;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		LateLoad();
		HookEvents();
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		ResetPlugin();
		UnhookEvents();
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

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
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

void LateLoad()
{
	LoadExtinguishers();

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			int weapon = GetEntProp(i, Prop_Send, "m_holdingObject");
			if( weapon != -1 )
			{
				char sTemp[32];
				GetEdictClassname(weapon, sTemp, sizeof(sTemp));

				if( strcmp(sTemp, "gascan") == 0 )
				{
					g_iRefuel[i][0] = EntIndexToEntRef(weapon);
					SDKHook(i, SDKHook_PreThink, OnPreThink);
				}
			}
		}
	}
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void HookEvents()
{
	HookEvent("round_end",					Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("round_start",				Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("player_death",				Event_Remove);
	HookEvent("player_disconnect",			Event_Remove);
	HookEvent("player_team",				Event_Team);
	HookEvent("player_bot_replace",			Event_Swap_Bot);
	HookEvent("bot_player_replace",			Event_Swap_User);
	HookEvent("player_spawn",				Event_PlayerSpawn);
	HookEvent("revive_success",				Event_ReviveSuccess);
	HookEvent("revive_begin",				Event_ReviveStart);
	HookEvent("revive_end",					Event_ReviveEnd);
	HookEvent("player_incapacitated",		Event_BlockIncap);
	HookEvent("player_ledge_grab",			Event_BlockLedge);
	HookEvent("lunge_pounce",				Event_BlockStart);
	HookEvent("pounce_end",					Event_BlockEnd);
	HookEvent("tongue_grab",				Event_BlockStart);
	HookEvent("tongue_release",				Event_BlockEnd);

	if( g_bLeft4Dead2 )
	{
		HookEvent("charger_pummel_start",		Event_BlockStart);
		HookEvent("charger_carry_start",		Event_BlockStart);
		HookEvent("charger_carry_end",			Event_BlockEnd);
		HookEvent("charger_pummel_end",			Event_BlockEnd);
		HookEvent("jockey_ride",				Event_BlockStart);
		HookEvent("jockey_ride_end",			Event_BlockEnd);
		HookEvent("gascan_pour_completed",		Event_GascanPoured);
		HookEvent("item_pickup",				Event_GascanPickup);
		HookEvent("weapon_drop",				Event_GascanDropped);
	}
}

void UnhookEvents()
{
	UnhookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
	UnhookEvent("round_start",				Event_RoundStart,	EventHookMode_PostNoCopy);
	UnhookEvent("player_death",				Event_Remove);
	UnhookEvent("player_disconnect",		Event_Remove);
	UnhookEvent("player_team",				Event_Team);
	UnhookEvent("player_bot_replace",		Event_Swap_Bot);
	UnhookEvent("bot_player_replace",		Event_Swap_User);
	UnhookEvent("player_spawn",				Event_PlayerSpawn);
	UnhookEvent("revive_success",			Event_ReviveSuccess);
	UnhookEvent("revive_begin",				Event_ReviveStart);
	UnhookEvent("revive_end",				Event_ReviveEnd);
	UnhookEvent("player_incapacitated",		Event_BlockIncap);
	UnhookEvent("player_ledge_grab",		Event_BlockLedge);
	UnhookEvent("lunge_pounce",				Event_BlockStart);
	UnhookEvent("tongue_grab",				Event_BlockStart);
	UnhookEvent("pounce_end",				Event_BlockEnd);
	UnhookEvent("tongue_release",			Event_BlockEnd);

	if( g_bLeft4Dead2 )
	{
		UnhookEvent("charger_pummel_start",		Event_BlockStart);
		UnhookEvent("charger_carry_start",		Event_BlockStart);
		UnhookEvent("charger_carry_end",		Event_BlockEnd);
		UnhookEvent("charger_pummel_end",		Event_BlockEnd);
		UnhookEvent("jockey_ride",				Event_BlockStart);
		UnhookEvent("jockey_ride_end",			Event_BlockEnd);
		UnhookEvent("gascan_pour_completed",	Event_GascanPoured);
		UnhookEvent("item_pickup",				Event_GascanPickup);
		UnhookEvent("weapon_drop",				Event_GascanDropped);
	}
}

void Event_Remove(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("userid");
	if( client )
	{
		client = GetClientOfUserId(client);
		if( client && IsClientInGame(client) )
		{
			int team = GetClientTeam(client);
			if( team == 2 )
				DropExtinguisher(client);
		}
	}
}

void Event_Team(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("userid");
	if( client )
	{
		client = GetClientOfUserId(client);
		if( client )
		{
			int team = GetClientTeam(client);
			if( team != 2 )
				DropExtinguisher(client);
		}
	}
}

void Event_Swap_Bot(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));

	g_iPlayerData[bot][INDEX_FUEL] = g_iPlayerData[client][INDEX_FUEL];
	g_iPlayerData[bot][INDEX_TYPE] = g_iPlayerData[client][INDEX_TYPE];

	if( IsValidEntRef(g_iPlayerData[client][INDEX_PROP]) )
	{
		KillAttachments(client, true);
		GiveExtinguisher(bot);
	}
}

void Event_Swap_User(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));

	g_iPlayerData[client][INDEX_FUEL] = g_iPlayerData[bot][INDEX_FUEL];
	g_iPlayerData[client][INDEX_TYPE] = g_iPlayerData[bot][INDEX_TYPE];

	if( IsValidEntRef(g_iPlayerData[bot][INDEX_PROP]) )
	{
		KillAttachments(bot, true);
		GiveExtinguisher(client);

		if( GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) )
		{
			SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
		}
	}
}

void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("userid");
	if( client )
	{
		client = GetClientOfUserId(client);
		if( client )
		{
			g_iPlayerData[client][INDEX_BLOCK] &= ~ENUM_LEDGEBLOCK;
			g_iPlayerData[client][INDEX_BLOCK] &= ~ENUM_INREVIVE;
			g_iPlayerData[client][INDEX_BLOCK] &= ~ENUM_INCAPPED;

			int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if( iWeapon > 0 )
			{
				if( iWeapon == GetPlayerWeaponSlot(client, g_iGunSlot[client]) )
					MoveExtinguisher(client, true);
				else
					MoveExtinguisher(client, false);
			}
		}
	}

	int userid = event.GetInt("subject");
	client = GetClientOfUserId(userid);
	if( client )
	{
		g_iPlayerData[client][INDEX_BLOCK] = 0;
		SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);

		if( g_iGunSlot[client] == SLOT_TEMP_PRI || g_iGunSlot[client] == SLOT_CURRENT_PRI ) // Incapped extinguisher usage enabled, switch from melee slot to primary, as they had.
			g_iGunSlot[client] = SLOT_PRIMARY;
		else if( g_iGunSlot[client] == SLOT_TEMP_SEC || g_iGunSlot[client] == SLOT_CURRENT_SEC )
			g_iGunSlot[client] = SLOT_SECONDARY;

		MoveExtinguisher(client, false);
		CreateTimer(0.1, TimerReviveSuccess, userid);
	}
}

Action TimerReviveSuccess(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
	{
		int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		int iValidWeapon = HasWeapon(client, iWeapon);
		if( iValidWeapon )
		{
			MoveExtinguisher(client, true);

			g_fTimeout[client] = GetGameTime() + 0.5;
		}
		else
		{
			MoveExtinguisher(client, false);
		}
	}

	return Plugin_Continue;
}

void Event_ReviveStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("userid");
	if( client )
	{
		client = GetClientOfUserId(client);
		if( client )
		{
			g_iPlayerData[client][INDEX_BLOCK] |= ENUM_INREVIVE;
			MoveExtinguisher(client, false);
		}
	}

	client = event.GetInt("subject");
	if( client )
	{
		client = GetClientOfUserId(client);
		if( client )
		{
			g_iPlayerData[client][INDEX_BLOCK] |= ENUM_INREVIVE;
			MoveExtinguisher(client, false);

			if( g_iCvarIncap )
			{
				if( g_iCvarIncap != 2 )
				{
					if( g_iGunSlot[client] == SLOT_TEMP_PRI || g_iGunSlot[client] == SLOT_CURRENT_PRI )
						g_iGunSlot[client] = SLOT_PRIMARY;
					else if( g_iGunSlot[client] == SLOT_SECONDARY || g_iGunSlot[client] == SLOT_CURRENT_SEC )
						g_iGunSlot[client] = SLOT_TEMP_SEC;
				}

				int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if( iWeapon > 0 )
					SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() - 0.2);
			}
		}
	}
}

void Event_ReviveEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("userid");
	if( client )
	{
		client = GetClientOfUserId(client);
		if( client )
		{
			g_iPlayerData[client][INDEX_BLOCK] &= ~ENUM_LEDGEBLOCK;
			g_iPlayerData[client][INDEX_BLOCK] &= ~ENUM_INREVIVE;

			int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if( iWeapon > 0 )
			{
				if( iWeapon == GetPlayerWeaponSlot(client, g_iGunSlot[client]) )
					MoveExtinguisher(client, true);
				else
					MoveExtinguisher(client, false);
			}
		}
	}

	client = event.GetInt("subject");
	if( client )
	{
		client = GetClientOfUserId(client);
		if( client )
		{
			g_iPlayerData[client][INDEX_BLOCK] &= ~ENUM_LEDGEBLOCK;
			g_iPlayerData[client][INDEX_BLOCK] &= ~ENUM_INREVIVE;

			if( g_iCvarIncap )
			{
				if( g_iCvarIncap != 2 )
				{
					if( g_iGunSlot[client] == SLOT_PRIMARY || g_iGunSlot[client] == SLOT_CURRENT_PRI )
						g_iGunSlot[client] = SLOT_TEMP_PRI;
					else if( g_iGunSlot[client] == SLOT_TEMP_SEC || g_iGunSlot[client] == SLOT_CURRENT_SEC )
						g_iGunSlot[client] = SLOT_SECONDARY;
				}

				MoveExtinguisher(client, true);
			}
			else
			{
				MoveExtinguisher(client, false);
			}
		}
	}
}

void Event_BlockIncap(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if( client )
	{
		if( !g_iCvarIncap )
		{
			g_iPlayerData[client][INDEX_BLOCK] |= ENUM_INCAPPED;

			MoveExtinguisher(client, false);
			int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			int iValidWeapon = HasWeapon(client, iWeapon);
			if( iValidWeapon )
				SetEntPropFloat(iValidWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.2);
		}
		else
		{
			SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
			RequestFrame(OnFrameIncap, userid);

			if( g_iCvarIncap != 2 )
			{
				if( g_iGunSlot[client] == SLOT_PRIMARY || g_iGunSlot[client] == SLOT_CURRENT_PRI ) // 0 = Primary slot, temporarily move to pistol slot.
					g_iGunSlot[client] = SLOT_TEMP_PRI;
			}

			if( g_iCvarHint && IsValidEntRef(g_iPlayerData[client][INDEX_PROP]) )
			{
				int iType = g_iPlayerData[client][INDEX_TYPE];
				if( IsClientInGame(client) )
				{
					if( g_iCvarCombo || iType == TYPE_EXTINGUISHER )
						CPrintToChat(client, "%t%t", "Ext_ChatTagExtinguisher", "Ext_Incapped");
					else if( iType == TYPE_FLAMETHROWER )
						CPrintToChat(client, "%t%t", "Ext_ChatTagFlamethrower", "Ext_Incapped");
					else if( iType == TYPE_FREEZERSPRAY )
						CPrintToChat(client, "%t%t", "Ext_ChatTagFreezerspray", "Ext_Incapped");
					else
						CPrintToChat(client, "%t%t", "Ext_ChatTagBlastpushback", "Ext_Incapped");
				}
			}
		}
	}
}

void OnFrameIncap(int client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) )
	{
		OnWeaponSwitch(client, 0);
		OnWeaponIncap(client);
	}
}

void Event_BlockLedge(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client )
	{
		if( g_iCvarIncap != 2 )
		{
			if( g_iGunSlot[client] == SLOT_TEMP_PRI || g_iGunSlot[client] == SLOT_CURRENT_PRI ) // Was in temporarily pistol slot, move to primary slot.
				g_iGunSlot[client] = SLOT_PRIMARY;
			else if( g_iGunSlot[client] == SLOT_TEMP_SEC || g_iGunSlot[client] == SLOT_CURRENT_SEC )
				g_iGunSlot[client] = SLOT_SECONDARY;
		}

		g_iPlayerData[client][INDEX_BLOCK] |= ENUM_LEDGEBLOCK;
		MoveExtinguisher(client, false);
	}
}

void Event_BlockStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if( client )
	{
		g_iPlayerData[client][INDEX_BLOCK] |= ENUM_BLOCKED;
		MoveExtinguisher(client, false);
	}
}

void Event_BlockEnd(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("victim");
	int client = GetClientOfUserId(userid);
	if( client )
	{
		g_iPlayerData[client][INDEX_BLOCK] &= ~ENUM_BLOCKED;

		CreateTimer(0.1, TimerReviveSuccess, userid);
	}
}

void Event_GascanPoured(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	int entity = g_iRefuel[client][1];
	g_iRefuel[client][1] = 0;

	if( IsValidEntRef(entity) )
		RemoveEntity(entity);

	int index = g_iRefuel[client][2] -1;
	if( index != -1 && IsValidEntRef(g_iDropped[index][0]) )
	{
		g_iDropped[index][2] = g_iCvarFuel;

		if( g_iCvarHint == 1 || g_iCvarHint == 2 )
		{
			int iType = g_iDropped[index][3];
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) )
				{
					if( g_iCvarCombo || iType == TYPE_EXTINGUISHER )
						CPrintToChat(i, "%T%T", "Ext_ChatTagExtinguisher", i, "Ext_Refueled", i);
					else if( iType == TYPE_FLAMETHROWER )
						CPrintToChat(i, "%T%T", "Ext_ChatTagFlamethrower", i, "Ext_Refueled", i);
					else if( iType == TYPE_FREEZERSPRAY )
						CPrintToChat(i, "%T%T", "Ext_ChatTagFreezerspray", i, "Ext_Refueled", i);
					else
						CPrintToChat(i, "%T%T", "Ext_ChatTagBlastpushback", i, "Ext_Refueled", i);
				}
			}
		}
	}
}

void Event_GascanPickup(Event event, const char[] name, bool dontBroadcast)
{
	char sTemp[8];
	event.GetString("item", sTemp, sizeof(sTemp));
	if( strcmp(sTemp, "gascan") == 0 )
	{
		int userid = event.GetInt("userid");
		int client = GetClientOfUserId(userid);

		if( g_iHooked[client] == 0 )
		{
			g_iHooked[client] = 1;
			SDKHook(client, SDKHook_PreThink, OnPreThink);
		}

		int entity = g_iRefuel[client][1];

		if( IsValidEntRef(entity) )
			RemoveEntity(entity);

		entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( entity != 0 && entity != -1 )
			g_iRefuel[client][0] = EntIndexToEntRef(entity);
		else
			g_iRefuel[client][0] = 0;

		MoveExtinguisher(client, false);
	}
}

void Event_GascanDropped(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	if( client )
	{
		char sTemp[8];
		event.GetString("item", sTemp, sizeof(sTemp));
		if( strcmp(sTemp, "gascan") == 0 )
		{
			int entity = g_iRefuel[client][1];
			g_iRefuel[client][1] = 0;

			if( IsValidEntRef(entity) )
				RemoveEntity(entity);

			g_iRefuel[client][0] = 0;

			g_fTimeout[client] = GetGameTime() + 0.5;
		}

		CreateTimer(0.0, TimerReviveSuccess, userid);
	}
}



// ====================================================================================================
//					START EVENTS - LOAD EXTINGUISHERS
// ====================================================================================================
void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bGlow = false;

	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("userid");
	if( client )
	{
		client = GetClientOfUserId(client);
		if( client )
		{
			g_iZoomed[client] = 0;
			g_iPlayerData[client][INDEX_BLOCK] = 0;
			SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);

			if( g_iCvarIncap != 2 )
			{
				if( g_iGunSlot[client] == SLOT_TEMP_PRI || g_iGunSlot[client] == SLOT_CURRENT_PRI ) // Incapped extinguisher usage enabled, switch from melee slot to primary, as they had.
					g_iGunSlot[client] = SLOT_PRIMARY;
				else if( g_iGunSlot[client] == SLOT_TEMP_SEC || g_iGunSlot[client] == SLOT_CURRENT_SEC )
					g_iGunSlot[client] = SLOT_SECONDARY;
			}
			else
			{
				int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if( GetPlayerWeaponSlot(client, 0) == weapon )
					g_iGunSlot[client] = SLOT_CURRENT_PRI;
				else
					g_iGunSlot[client] = SLOT_CURRENT_SEC;
			}
		}
	}

	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

Action TimerStart(Handle timer)
{
	ResetPlugin();
	LoadExtinguishers();

	return Plugin_Continue;
}

void LoadExtinguishers()
{
	if( !g_bMapStarted ) return;
	if( g_iLoadStatus == 1 ) return;
	g_iLoadStatus = 1;
	g_iSpawnCount = 0;

	if( g_iCvarGrab )
	{
		int entity = -1;
		while( g_iSpawnCount < g_iCvarGrab && (entity = FindEntityByClassname(entity, "prop_physics")) != INVALID_ENT_REFERENCE )
			CreateButton(entity, ENUM_WALLEXT);
	}

	if( !g_iCvarRandom )
		return;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	KeyValues hFile = new KeyValues("extinguishers");
	if( !hFile.ImportFromFile(sPath) )
	{
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		delete hFile;
		return;
	}

	// Retrieve how many extinguishers to display
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return;
	}

	// Spawn only a select few extinguishers?
	int iType, index, i, iRandom = g_iCvarRandom;
	int iIndexes[MAX_ALLOWED+1];
	if( iCount > MAX_ALLOWED )
		iCount = MAX_ALLOWED;

	// Spawn all saved extinguishers or create random
	if( iRandom > iCount)
		iRandom = iCount;
	if( iRandom != -1 )
	{
		for( i = 1; i <= iCount; i++ )
			iIndexes[i-1] = i;

		SortIntegers(iIndexes, iCount, Sort_Random);
		iCount = iRandom;
	}

	// Get the extinguisher origins and spawn
	char sTemp[10];
	float vPos[3], vAng[3];
	for( i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		Format(sTemp, sizeof(sTemp), "angle_%d", index);
		hFile.GetVector(sTemp, vAng);
		Format(sTemp, sizeof(sTemp), "origin_%d", index);
		hFile.GetVector(sTemp, vPos);
		Format(sTemp, sizeof(sTemp), "types_%d", index);
		iType = hFile.GetNum(sTemp, g_iCvarType);

		if( vPos[0] == 0.0 && vPos[0] == 0.0 && vPos[0] == 0.0 ) // Should never happen.
			LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Count=%d.", i, index, iCount);
		else
			CreateExtinguisher(vPos, vAng, GetRandomType(iType), ENUM_SPAWNED);
	}

	delete hFile;
}

int CreateExtinguisher(float vPos[3], float vAng[3], int iType, int iEnum)
{
	int entity;

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		if( (iEnum == ENUM_SPAWNED && !IsValidEntRef(g_iSpawned[i][0])) || (iEnum == ENUM_DROPPED && !IsValidEntRef(g_iDropped[i][0])) )
		{
			entity = CreateEntityByName("prop_physics");
			DispatchKeyValue(entity, "model", MODEL_EXTINGUISHER);
			TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
			DispatchSpawn(entity);
			SetEntityMoveType(entity, MOVETYPE_NONE);
			SetEntProp(entity, Prop_Data, "m_CollisionGroup", 1);
			SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);

			if( iEnum == ENUM_SPAWNED )
			{
				g_iSpawned[i][0] = EntIndexToEntRef(entity);
				g_iSpawned[i][2] = g_iCvarFuel;
				CreateButton(entity, ENUM_SPAWNED, iType);
			} else {
				g_iDropped[i][0] = EntIndexToEntRef(entity);
				g_iDropped[i][2] = g_iCvarFuel;
				CreateButton(entity, ENUM_DROPPED, iType);
			}

			break;
		}
	}
	return entity;
}



// ====================================================================================================
//					COMMANDS - sm_dropext, sm_giveext, sm_spawnext, sm_extwep
// ====================================================================================================
Action CmdDrop(int client, int args)
{
	if( g_bCvarAllow )
	{
		if( args == 0 )
		{
			DropExtinguisher(client);
		}
		else
		{
			if( CheckCommandAccess(client, "", ADMFLAG_ROOT, true) )
			{
				char target_name[MAX_TARGET_LENGTH], arg1[32];
				int target_list[MAXPLAYERS], target_count;
				bool tn_is_ml;

				GetCmdArg(1, arg1, sizeof(arg1));

				if( (target_count = ProcessTargetString(
						arg1,
						client,
						target_list,
						MAXPLAYERS,
						COMMAND_FILTER_ALIVE,
						target_name,
						sizeof(target_name),
						tn_is_ml)) <= 0 )
				{
					ReplyToTargetError(client, target_count);
					return Plugin_Handled;
				}

				for( int i = 0; i < target_count; i++ )
					DropExtinguisher(target_list[i]);
			}
		}
	}
	return Plugin_Handled;
}

Action CmdGive(int client, int args)
{
	if (!IsInReady()){
		AdminId id = GetUserAdmin(client);
		if (!GetAdminFlag(id, Admin_Generic)) {
			PrintToChat(client, "游戏已经开始了!");
			return Plugin_Handled;
		}
	}
	if( g_bCvarAllow )
	{
		if( args == 0 )
		{
			g_iPlayerData[client][INDEX_FUEL] = g_iCvarFuel;
			g_iPlayerData[client][INDEX_TYPE] = GetRandomType(g_iCvarType);
			GiveExtinguisher(client);
		}
		else
		{
			char arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));

			if( args == 1 && strlen(arg1) == 1 )
			{
				g_iPlayerData[client][INDEX_FUEL] = g_iCvarFuel;
				g_iPlayerData[client][INDEX_TYPE] = StringToInt(arg1);
				GiveExtinguisher(client);
				return Plugin_Handled;
			}

			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			char target_name[MAX_TARGET_LENGTH];

			if( (target_count = ProcessTargetString(
				arg1,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0 )
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}

			int target;
			for( int i = 0; i < target_count; i++ )
			{
				target = target_list[i];
				if( GetClientTeam(target) == 2 )
				{
					g_iPlayerData[target][INDEX_FUEL] = g_iCvarFuel;
					if( args == 1 )
						g_iPlayerData[target][INDEX_TYPE] = GetRandomType(g_iCvarType);
					else
					{
						GetCmdArg(2, arg1, sizeof(arg1));
						g_iPlayerData[target][INDEX_TYPE] = StringToInt(arg1);
					}
					GiveExtinguisher(target);
				}
			}
		}
	}
	return Plugin_Handled;
}

Action CmdSpawn(int client, int args)
{
	if( g_bCvarAllow )
	{
		if( args == 0 )
		{
			float vPos[3], vAng[3];
			SetTeleportEndPoint(client, vPos, vAng);
			int entity = CreateExtinguisher(vPos, vAng, 0, ENUM_DROPPED);
			SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
		}
		else
		{
			char arg1[4];
			float vPos[3], vAng[3];
			GetCmdArg(1, arg1, sizeof(arg1));

			SetTeleportEndPoint(client, vPos, vAng);
			int entity = CreateExtinguisher(vPos, vAng, StringToInt(arg1), ENUM_DROPPED);
			SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
		}
	}
	return Plugin_Handled;
}

Action CmdExtWep(int client, int args)
{
	if( g_bCvarAllow )
	{
		if( g_sCvarWeapon[0] == 0 )
		{
			ReplyToCommand(client, "[Extinguisher] Cannot give weapon, l4d_extinguisher_weapon string is empty!");
			return Plugin_Handled;
		}

		if( args == 0 && client && IsClientInGame(client) && IsPlayerAlive(client) )
			GiveWeapon(client);
		else
		{
			char arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));

			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			char target_name[MAX_TARGET_LENGTH];

			if( (target_count = ProcessTargetString(
				arg1,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0 )
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}

			int target;
			for( int i = 0; i < target_count; i++ )
			{
				target = target_list[i];
				GiveWeapon(target);
			}
		}
	}
	return Plugin_Handled;
}

void GiveWeapon(int client)
{
	if( GetClientTeam(client == 2 ) )
	{
		int bits = GetUserFlagBits(client);
		int flags = GetCommandFlags("give");
		SetUserFlagBits(client, ADMFLAG_ROOT);
		SetCommandFlags("give", flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give %s", g_sCvarWeapon);
		SetUserFlagBits(client, bits);
		SetCommandFlags("give", flags);
	}
}



// ====================================================================================================
//					COMMANDS - SAVE, DELETE, CLEAR, WIPE, ANG, POS, LIST, GLOW
// ====================================================================================================
//					sm_extsave
// ====================================================================================================
Action CmdExtSave(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Extinguisher] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = new KeyValues("extinguishers");
	if( !hFile.ImportFromFile(sPath) )
	{
		CPrintToChat(client, "%tError: Cannot read the extinguisher config, assuming empty file. (\x05%s\x01).", "Ext_ChatTagExtinguisher", sPath);
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !hFile.JumpToKey(sMap, true) )
	{
		CPrintToChat(client, "%tError: Failed to add map to extinguisher spawn config.", "Ext_ChatTagExtinguisher");
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many extinguishers are saved
	int iCount = hFile.GetNum("num", 0);
	if( iCount >= MAX_ALLOWED )
	{
		CPrintToChat(client, "%tError: Cannot add anymore extinguishers. Used: (\x05%d/%d\x01).", "Ext_ChatTagExtinguisher", iCount, MAX_ALLOWED);
		delete hFile;
		return Plugin_Handled;
	}

	// Set player position as extinguisher spawn location
	float vPos[3], vAng[3];
	if( !SetTeleportEndPoint(client, vPos, vAng) )
	{
		CPrintToChat(client, "%tCannot place extinguisher, please try again.", "Ext_ChatTagExtinguisher");
		delete hFile;
		return Plugin_Handled;
	}

	// Save count
	iCount++;
	hFile.SetNum("num", iCount);

	// Save angle / origin
	char sTemp[10];
	Format(sTemp, sizeof(sTemp), "angle_%d", iCount);
	hFile.SetVector(sTemp, vAng);
	Format(sTemp, sizeof(sTemp), "origin_%d", iCount);
	hFile.SetVector(sTemp, vPos);

	if( args == 1 )
	{
		char sBuff[4];
		GetCmdArg(1, sBuff, sizeof(sBuff));
		int iType = StringToInt(sBuff);
		Format(sTemp, sizeof(sTemp), "types_%d", iCount);
		hFile.SetNum(sTemp, iType);
		CreateExtinguisher(vPos, vAng, GetRandomType(iType), ENUM_SPAWNED);
	}
	else
		CreateExtinguisher(vPos, vAng, 0, ENUM_SPAWNED);

	// Save cfg
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	// Create extinguisher
	CPrintToChat(client, "%t(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", "Ext_ChatTagExtinguisher", iCount, MAX_ALLOWED, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_extdel
// ====================================================================================================
Action CmdExtDelete(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Extinguisher] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	float vPos[3], vEntPos[3];
	bool bDelete;
	int aim = GetClientAimTarget(client, false);

	if( aim != -1 )
	{
		aim = EntIndexToEntRef(aim);
		for( int i = 0; i < MAX_ALLOWED; i++ )
		{
			if( aim == g_iSpawned[i][0] || aim == g_iSpawned[i][1] )
			{
				GetEntPropVector(g_iSpawned[i][0], Prop_Send, "m_vecOrigin", vEntPos);
				RemoveEntity(g_iSpawned[i][0]);
				RemoveEntity(g_iSpawned[i][1]);
				g_iSpawned[i][0] = 0;
				g_iSpawned[i][1] = 0;
				bDelete = true;
				break;
			}
			else if( aim == g_iDropped[i][0] || aim == g_iDropped[i][1] )
			{
				GetEntPropVector(g_iDropped[i][0], Prop_Send, "m_vecOrigin", vEntPos);
				RemoveEntity(g_iDropped[i][0]);
				RemoveEntity(g_iDropped[i][1]);
				g_iDropped[i][0] = 0;
				g_iDropped[i][1] = 0;
				CPrintToChat(client, "%tDropped Extinguisher removed.", "Ext_ChatTagExtinguisher");
				return Plugin_Handled;
			}
			if( bDelete ) break;
		}
	}

	if( !bDelete )
	{
		CPrintToChat(client, "%tError: Cannot find the extinguisher you tried to delete.", "Ext_ChatTagExtinguisher");
		return Plugin_Handled;
	}

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%tWarning: Cannot find the extinguisher config (\x05%s\x01).", "Ext_ChatTagExtinguisher", CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	KeyValues hFile = new KeyValues("extinguishers");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%tWarning: Cannot load the extinguisher config (\x05%s\x01).", "Ext_ChatTagExtinguisher", sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%tWarning: Current map not in the extinguisher config.", "Ext_ChatTagExtinguisher");
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many extinguishers
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return Plugin_Handled;
	}

	bool bMove;
	int iNum1;
	char sTemp[10];
	float vAng[3];

	// Move the other entries down
	for( int i = 1; i <= iCount; i++ )
	{
		Format(sTemp, sizeof(sTemp), "origin_%d", i);
		hFile.GetVector(sTemp, vPos);

		if( !bMove )
		{
			if( GetVectorDistance(vPos, vEntPos) <= 1.0 )
			{
				hFile.DeleteKey(sTemp);
				Format(sTemp, sizeof(sTemp), "angle_%d", i);
				hFile.DeleteKey(sTemp);
				Format(sTemp, sizeof(sTemp), "types_%d", i);
				hFile.DeleteKey(sTemp);
				bMove = true;
			}
			else if( i == iCount ) // No extinguishers... exit
			{
				PrintToChat(client, "%tWarning: Cannot find the extinguisher inside the config.", "Ext_ChatTagExtinguisher");
				delete hFile;
				return Plugin_Handled;
			}
		}
		else
		{
			// Retrieve data and delete
			hFile.DeleteKey(sTemp);
			Format(sTemp, sizeof(sTemp), "angle_%d", i);
			hFile.GetVector(sTemp, vAng);
			hFile.DeleteKey(sTemp);
			Format(sTemp, sizeof(sTemp), "types_%d", i);

			iNum1 = hFile.GetNum(sTemp, -1);
			if( iNum1 != -1 )
				hFile.DeleteKey(sTemp);

			// Save data to previous id
			Format(sTemp, sizeof(sTemp), "angle_%d", i-1);
			hFile.SetVector(sTemp, vAng);
			Format(sTemp, sizeof(sTemp), "origin_%d", i-1);
			hFile.SetVector(sTemp, vPos);
			if( iNum1 != -1 )
			{
				Format(sTemp, sizeof(sTemp), "types_%d", i-1);
				hFile.SetNum(sTemp, iNum1);
			}
		}
	}

	iCount--;
	hFile.SetNum("num", iCount);

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	CPrintToChat(client, "%t(\x05%d/%d\x01) - Extinguisher removed from config.", "Ext_ChatTagExtinguisher", iCount, MAX_ALLOWED);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_extclear
// ====================================================================================================
Action CmdExtClear(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	KillEnts();
	CPrintToChat(client, "%tAll extinguishers removed from the map.", "Ext_ChatTagExtinguisher");
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_extwipe
// ====================================================================================================
Action CmdExtWipe(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Extinguisher] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		CPrintToChat(client, "%tError: Cannot find the extinguisher config (\x05%s\x01).", "Ext_ChatTagExtinguisher", sPath);
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = new KeyValues("extinguishers");
	if( !hFile.ImportFromFile(sPath) )
	{
		CPrintToChat(client, "%tError: Cannot load the extinguisher config (\x05%s\x01).", "Ext_ChatTagExtinguisher", sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap, false) )
	{
		CPrintToChat(client, "%tError: Current map not in the extinguisher config.", "Ext_ChatTagExtinguisher");
		delete hFile;
		return Plugin_Handled;
	}

	hFile.DeleteThis();

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	KillEnts();
	CPrintToChat(client, "%t(0/%d) - All extinguishers removed from config, add new extinguishers with \x05sm_extsave\x01.", "Ext_ChatTagExtinguisher", MAX_ALLOWED);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_extang
// ====================================================================================================
Action CmdExtAng(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	ShowAngMenu(client);
	return Plugin_Handled;
}

void ShowAngMenu(int client)
{
	Menu menu = new Menu(AngMenuHandler);

	menu.AddItem("", "X + 5.0");
	menu.AddItem("", "Y + 5.0");
	menu.AddItem("", "Z + 5.0");
	menu.AddItem("", "");
	menu.AddItem("", "X - 5.0");
	menu.AddItem("", "Y - 5.0");
	menu.AddItem("", "Z - 5.0");

	menu.SetTitle("Set Angle");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int AngMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
		delete menu;
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowAngMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		ShowAngMenu(client);

		int aim = GetClientAimTarget(client, false);
		if( aim != -1 )
		{
			float vAng[3];
			int entity;

			for( int i = 0; i < MAX_ALLOWED; i++ )
			{
				entity = g_iSpawned[i][0];

				if( entity && EntRefToEntIndex(entity) == aim )
				{
					GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

					switch( index )
					{
						case 0: vAng[0] += 5.0;
						case 1: vAng[1] += 5.0;
						case 2: vAng[2] += 5.0;
						case 4: vAng[0] -= 5.0;
						case 5: vAng[1] -= 5.0;
						case 6: vAng[2] -= 5.0;
					}

					TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);
					CPrintToChat(client, "%tNew angles: %f %f %f", "Ext_ChatTagExtinguisher", vAng[0], vAng[1], vAng[2]);
					break;
				}
			}
		}
	}

	return 0;
}

// ====================================================================================================
//					sm_extpos
// ====================================================================================================
Action CmdExtPos(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	ShowPosMenu(client);
	return Plugin_Handled;
}

void ShowPosMenu(int client)
{
	Menu menu = new Menu(PosMenuHandler);

	menu.AddItem("", "X + 0.5");
	menu.AddItem("", "Y + 0.5");
	menu.AddItem("", "Z + 0.5");
	menu.AddItem("", "");
	menu.AddItem("", "X - 0.5");
	menu.AddItem("", "Y - 0.5");
	menu.AddItem("", "Z - 0.5");

	menu.SetTitle("Set Position");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int PosMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
		delete menu;
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowPosMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		ShowPosMenu(client);

		int aim = GetClientAimTarget(client, false);
		if( aim != -1 )
		{
			float vPos[3];
			int entity;

			for( int i = 0; i < MAX_ALLOWED; i++ )
			{
				entity = g_iSpawned[i][0];

				if( entity && EntRefToEntIndex(entity) == aim )
				{
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

					switch( index )
					{
						case 0: vPos[0] += 0.5;
						case 1: vPos[1] += 0.5;
						case 2: vPos[2] += 0.5;
						case 4: vPos[0] -= 0.5;
						case 5: vPos[1] -= 0.5;
						case 6: vPos[2] -= 0.5;
					}

					TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
					CPrintToChat(client, "%tNew origin: %f %f %f", "Ext_ChatTagExtinguisher", vPos[0], vPos[1], vPos[2]);
					break;
				}
			}
		}
	}

	return 0;
}

// ====================================================================================================
//					sm_extset
// ====================================================================================================
Action CmdExtSet(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Extinguisher] Commands can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		char sPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
		if( !FileExists(sPath) )
		{
			CPrintToChat(client, "%tError: Cannot find the extinguisher config (\x05%s\x01).", "Ext_ChatTagExtinguisher", sPath);
			return Plugin_Handled;
		}

		KeyValues hFile = new KeyValues("extinguishers");
		if( !hFile.ImportFromFile(sPath) )
		{
			CPrintToChat(client, "%tError: Cannot read the extinguisher config (\x05%s\x01).", "Ext_ChatTagExtinguisher", sPath);
			delete hFile;
			return Plugin_Handled;
		}

		// Check for current map in the config
		char sTemp[64];
		GetCurrentMap(sTemp, sizeof(sTemp));
		if( !hFile.JumpToKey(sTemp, true) )
		{
			CPrintToChat(client, "%tError: Cannot find the current map in the config.", "Ext_ChatTagExtinguisher");
			delete hFile;
			return Plugin_Handled;
		}

		float vPos[3], vAng[3];
		int entity;

		for( int i = 0; i < MAX_ALLOWED; i++ )
		{
			entity = g_iSpawned[i][0];

			if( entity && EntRefToEntIndex(entity) == aim )
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
				GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

				Format(sTemp, sizeof(sTemp), "angle_%d", i+1);
				hFile.SetVector(sTemp, vAng);
				Format(sTemp, sizeof(sTemp), "origin_%d", i+1);
				hFile.SetVector(sTemp, vPos);

				if( args == 1 )
				{
					char sArg1[4];
					GetCmdArg(1, sArg1, sizeof(sArg1));
					Format(sTemp, sizeof(sTemp), "types_%d", i+1);
					hFile.SetNum(sTemp, StringToInt(sArg1));
				}

				hFile.Rewind();
				hFile.ExportToFile(sPath);
				delete hFile;

				if( args == 1 )
					CPrintToChat(client, "%tSaved angles, origin and type to the config.", "Ext_ChatTagExtinguisher");
				else
					CPrintToChat(client, "%tSaved angles and origin to the config.", "Ext_ChatTagExtinguisher");
				return Plugin_Handled;
			}
		}

		delete hFile;
	}
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_extlist, sm_extglow
// ====================================================================================================
Action CmdExtList(int client, int args)
{
	float vPos[3];
	int i, u, entity, count;

	for( u = 0; u < 3; u++ )
	{
		if( u == 0 )
		{
			if( client == 0 )
				ReplyToCommand(client, "[Extinguisher] Part of the Map:");
			else
				CPrintToChat(client, "%tPart of the Map:", "Ext_ChatTagExtinguisher");
		}
		else if( u == 1 )
		{
			if( client == 0 )
				ReplyToCommand(client, "[Extinguisher] Dropped by Players:");
			else
				CPrintToChat(client, "%tDropped by Players:", "Ext_ChatTagExtinguisher");
		}
		else if( u == 2 )
		{
			if( client == 0 )
				ReplyToCommand(client, "[Extinguisher] Spawned by Plugin:");
			else
				CPrintToChat(client, "%tSpawned by Plugin:", "Ext_ChatTagExtinguisher");
		}
		for( i = 0; i < MAX_ALLOWED; i++ )
		{
			if( u == 0 )
				entity = g_iWallExt[i][0];
			else if( u == 1 )
				entity = g_iDropped[i][0];
			else if( u == 2 )
				entity = g_iSpawned[i][0];

			if( IsValidEntRef(entity) )
			{
				count++;
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
				if( client == 0 )
					ReplyToCommand(client, "[Extinguisher] %d) %f %f %f", i+1, vPos[0], vPos[1], vPos[2]);
				else
					CPrintToChat(client, "%t%d) %f %f %f", "Ext_ChatTagExtinguisher", i+1, vPos[0], vPos[1], vPos[2]);
			}
		}

		if( client == 0 )
			ReplyToCommand(client, "[Extinguisher] --------------------");
		else
			CPrintToChat(client, "%t--------------------", "Ext_ChatTagExtinguisher");
	}

	if( client == 0 )
		ReplyToCommand(client, "[Extinguisher] Total: %d.", count);
	else
		CPrintToChat(client, "%tTotal: %d/%d.", "Ext_ChatTagExtinguisher", count, MAX_ALLOWED);
	
	return Plugin_Handled;
}

Action CmdExtGlow(int client, int args)
{
	int i, u, entity;
	g_bGlow = !g_bGlow;

	for( u = 0; u < 3; u++ )
	{
		for( i = 0; i < MAX_ALLOWED; i++ )
		{
			if( u == 0 )
				entity = g_iWallExt[i][0];
			else if( u == 1 )
				entity = g_iDropped[i][0];
			else if( u == 2 )
				entity = g_iSpawned[i][0];

			if( IsValidEntRef(entity) )
			{
				SetEntProp(entity, Prop_Send, "m_nGlowRange", g_bGlow ? 0 : g_iCvarGlowRan);
				ChangeEdictState(entity, g_iOffsetGlow);
				if( g_bGlow )
					AcceptEntityInput(entity, "StartGlowing");
				else if( !g_bGlow && !g_iCvarGlowRan )
					AcceptEntityInput(entity, "StopGlowing");
			}
		}
	}

	CPrintToChat(client, "%tGlow has been turned %s", "Ext_ChatTagExtinguisher", g_bGlow ? "on" : "off");
	return Plugin_Handled;
}



// ====================================================================================================
//					TIMEOUT / TRACE / HURT / PUSH - PRETHINK
// ====================================================================================================
Action TimerTrace(Handle timer)
{
	bool destroy = true;
	static bool bSwitch;
	bSwitch = !bSwitch;

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsValidEntRef(g_iPlayerData[i][INDEX_PART]) )
		{
			TraceAttack(i, bSwitch, 0, false);
			destroy = false;
		}
	}

	if( destroy )
	{
		g_hTimerTrace = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void TraceAttack(int client, bool bHullTrace, int iPushEntity, bool bFirstTrace)
{
	float vPos[3], vAng[3], vEnd[3];

	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	MoveForward(vPos, vAng, vPos, 50.0);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, FilterExcludeSelf, client);
	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vEnd, trace);
	}
	else
	{
		delete trace;
		return;
	}

	if( bHullTrace )
	{
		delete trace;
		float vMins[3], vMaxs[3];
		vMins = view_as<float>({ -15.0, -15.0, -15.0 });
		vMaxs = view_as<float>({ 15.0, 15.0, 15.0 });
		trace = TR_TraceHullFilterEx(vPos, vEnd, vMins, vMaxs, MASK_SHOT, FilterExcludeSelf, client);

		if( !TR_DidHit(trace) )
		{
			delete trace;
			return;
		}
	}

	TR_GetEndPosition(vEnd, trace);
	if( GetVectorDistance(vPos, vEnd) > g_fCvarRange )
	{
		delete trace;
		return;
	}

	int type = g_iPlayerData[client][INDEX_TYPE];
	int entity = TR_GetEntityIndex(trace);
	delete trace;

	if( entity > 0 && entity <= MaxClients )
	{
		if( bFirstTrace && g_iCvarVomit )
		{
			int vomit;
			if( type == 3 ) vomit = 1;
			else vomit = type;

			if( (g_iCvarVomit == 7 || g_iCvarVomit & vomit) )
			{
				SDKCall(g_hSdkVomit, entity);
			}
		}

		if( g_iCvarFriend == 0 )
		{
			if( GetClientTeam(entity) == 2 )
				return;
		}
		else if( g_iCvarFriend == 2 && type != TYPE_BLASTPUSHBACK )
			return;

		if( type == TYPE_EXTINGUISHER || type == TYPE_FREEZERSPRAY )
			ExtinguishEntity(entity);

		HurtEntity(entity, client);

		if( iPushEntity && type == TYPE_BLASTPUSHBACK )
			PushEntity(client, vPos, vEnd);
	}
	else
	{
		static char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));

		if( type == TYPE_FLAMETHROWER && strcmp(classname, "prop_physics") == 0 )
		{
			SetEntPropEnt(entity, Prop_Data, "m_hLastAttacker", client);
			AcceptEntityInput(entity, "Ignite", client, client);
		}
		else if( type == TYPE_FLAMETHROWER && strcmp(classname, "weapon_gascan") == 0 )
		{
			SetVariantString("OnIgnite !self:Break:!activator:2:1");
			AcceptEntityInput(entity, "AddOutput", client, client);
			AcceptEntityInput(entity, "Ignite", client, client);
		}
		else
		{
			int dmgtype;
			if( strcmp(classname, "infected") == 0 )		dmgtype = 1;
			else if( strcmp(classname, "witch") == 0 )		dmgtype = 2;

			HurtEntity(entity, client, dmgtype);

			if( iPushEntity && type == TYPE_BLASTPUSHBACK )
				PushEntity(client, vPos, vEnd);

			if( g_bLeft4Dead2 &&
				( (g_iCvarCombo && type == TYPE_FREEZERSPRAY && g_iCvarType & ENUM_FREEZERSPRAY) || (!g_iCvarCombo && type == TYPE_FREEZERSPRAY) ) &&
				GetEntProp(entity, Prop_Data, "m_iHealth") > 0 && GetEntProp(entity, Prop_Send, "m_glowColorOverride") == 0 )
			{
				if( HasEntProp(entity, Prop_Data, "m_flFrozen") )
				{
					SetEntPropFloat(entity, Prop_Data, "m_flFrozen", 0.3);
				}
				SetEntProp(entity, Prop_Send, "m_nGlowRange", 350);
				SetEntProp(entity, Prop_Send, "m_iGlowType", 2);
				SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowS);
				AcceptEntityInput(entity, "StartGlowing");

				SetVariantString("OnKilled !self:StopGlowing::0:1");
				AcceptEntityInput(entity, "AddOutput");
			}
		}
	}
}

void HurtEntity(int target, int client, int dmgtype = 0)
{
	if( g_iPlayerData[client][INDEX_TYPE] == TYPE_FLAMETHROWER )
	{
		SDKHooks_TakeDamage(target, client, client, float(g_iCvarDamage), DMG_BURN);
	}
	else if( target > MaxClients && g_iPlayerData[client][INDEX_TYPE] == TYPE_BLASTPUSHBACK )
	{
		if( dmgtype == 1 )
			SDKHooks_TakeDamage(target, client, client, float(g_iCvarDamage), g_bLeft4Dead2 ? DMG_AIRBOAT : DMG_BUCKSHOT); // Common L4D2 / L4D1
		else
			SDKHooks_TakeDamage(target, client, client, float(g_iCvarDamage), DMG_BLAST); // Witch
	}
	else
	{
		SDKHooks_TakeDamage(target, client, client, float(g_iCvarDamage), DMG_GENERIC);
	}
}

void PushEntity(int client, float vAng[3], float vPos[3])
{
	int entity = CreateEntityByName("trigger_multiple");
	DispatchKeyValue(entity, "spawnflags", "1");
	DispatchSpawn(entity);
	SetEntityModel(entity, MODEL_BOUNDING);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

	float vMins[3]; vMins = view_as<float>({ -50.0, -50.0, -50.0 });
	float vMaxs[3]; vMaxs = view_as<float>({ 50.0, 50.0, 50.0 });
	SetEntPropVector(entity, Prop_Send, "m_vecMins", vMins);
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vMaxs);
	SetEntProp(entity, Prop_Send, "m_nSolidType", 2);

	SetEntProp(entity, Prop_Data, "m_iHammerID", client);
	HookSingleEntityOutput(entity, "OnStartTouch", OnTouching);

	SetVariantString("OnUser1 !self:Kill::0.01:1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
}

void OnTouching(const char[] output, int caller, int activator, float delay)
{
	int client = GetEntProp(caller, Prop_Data, "m_iHammerID");
	if( activator == client )
		return;

	float vAng[3];
	GetEntPropVector(client, Prop_Data, "m_angRotation", vAng);

	GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAng, vAng);
	ScaleVector(vAng, float(g_iCvarPush));
	vAng[2] = 300.0 + (g_iCvarPush / 10);

	TeleportEntity(activator, NULL_VECTOR, NULL_VECTOR, vAng);
}



// ====================================================================================================
//					PRETHINK - EXTINGUISHER SHOOT, BLOCK SHOOTING
// ====================================================================================================
void OnPreThink(int client)
{
	static int s_iEquipped[MAXPLAYERS];


	// --------------------------------------------------
	// Is the player holding a gascan, are they trying to refuel a dropped extinguisher?
	// --------------------------------------------------
	if( g_bLeft4Dead2 && IsValidEntRef(g_iRefuel[client][0]) )
	{
		int buttons = GetClientButtons(client);
		if( buttons & IN_ATTACK )
		{
			if( !IsValidEntRef(g_iRefuel[client][1]) )
			{
				int aim = GetClientAimTarget(client, false);
				if( aim != -1 )
				{
					int ref = EntIndexToEntRef(aim);

					for( int i = 0; i < MAX_ALLOWED; i++ )
					{
						if( g_iDropped[i][0] == ref && g_iDropped[i][2] != -12345 ) // Pointing at extinguisher and not broken.
						{
							buttons &= ~IN_ATTACK;
							SetEntProp(client, Prop_Data, "m_nButtons", buttons);

							int entity = CreateEntityByName("point_prop_use_target");
							DispatchKeyValue(entity, "nozzle", "gas_nozzle");
							DispatchSpawn(entity);

							SetEntProp(entity, Prop_Data, "m_iHammerID", client); // Fix for "[L4D2] Scavenge Pouring - Unleaded Gas Only" plugin

							float vPos[3];
							GetEntPropVector(ref, Prop_Data, "m_vecOrigin", vPos);
							TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

							float vMins[3]; vMins = view_as<float>({ -15.0, -15.0, -25.0 });
							float vMaxs[3]; vMaxs = view_as<float>({ 15.0, 15.0, 25.0 });
							SetEntPropVector(entity, Prop_Send, "m_vecMins", vMins);
							SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vMaxs);

							g_iRefuel[client][1] = EntIndexToEntRef(entity);
							g_iRefuel[client][2] = i+1;

							break;
						}
					}
				}
			}
		}
		else
		{
			int can = g_iRefuel[client][1];
			if( IsValidEntRef(can) )
				RemoveEntity(can);
			g_iRefuel[client][1] = 0;
			g_iRefuel[client][2] = 0;
		}

		return;
	}



	// --------------------------------------------------
	// Does the player have a valid extinguisher attached?
	// --------------------------------------------------
	if( IsValidEntRef(g_iPlayerData[client][INDEX_PROP]) )
	{
		// --------------------------------------------------
		// Incap not allowed
		// --------------------------------------------------
		if( !g_iCvarIncap && GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 1 )
		{
			return;
		}

		int iValidWeapon;
		int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		int mounted = GetEntProp(client, Prop_Send, "m_usingMountedWeapon");
		if( mounted != 0 )
			iValidWeapon = -2;
		else
			iValidWeapon = HasWeapon(client, iWeapon, true);


		// --------------------------------------------------
		// Not holding the valid weapon to use for extinguishers
		// --------------------------------------------------
		if( iValidWeapon != iWeapon )
		{
			// --------------------------------------------------
			// Ext in hand? Then kill effects and move ext to their back.
			// --------------------------------------------------
			if( s_iEquipped[client] )
			{
				s_iEquipped[client] = 0;
				KillAttachments(client, false);
				MoveExtinguisher(client, false);
			}


			// --------------------------------------------------
			// Check enabled? Then drop the weapon.
			// --------------------------------------------------
			if( g_iCvarCheck && (iValidWeapon == 0 || iValidWeapon == 1) )
			{
				DropExtinguisher(client);

				if( g_iCvarHint )
				{
					char sTemp[256], sWeapon[64];
					Format(sTemp, sizeof(sTemp), "%T%T", "Ext_ChatTagExtinguisher", client, "Ext_Blocked", client);
					Format(sWeapon, sizeof(sWeapon), "%T", "Ext_WeaponName", LANG_SERVER);
					ReplaceStringEx(sTemp, sizeof(sTemp), "<WEAPON>", sWeapon);
					CPrintToChat(client, sTemp);
				}
			}


			// --------------------------------------------------
			// If they are holding a melee weapon, move the extinguisher to the primary slot
			// --------------------------------------------------
			if( iValidWeapon == 1 && (g_iGunSlot[client] == SLOT_SECONDARY || g_iGunSlot[client] == SLOT_CURRENT_SEC) )
				g_iGunSlot[client] = SLOT_PRIMARY;
			return;
		}


		// --------------------------------------------------
		// Not holding the ext? Then move to hand
		// --------------------------------------------------
		if( !s_iEquipped[client] )
		{
			MoveExtinguisher(client, true);
			s_iEquipped[client] = 1;

			// Timeout before use
			g_fTimeout[client] = GetGameTime() + 0.4;
		}


		// --------------------------------------------------
		// They are holding the valid weapon and extinguisher
		// --------------------------------------------------

		// Forces player to raise weapon
		SetEntProp(client, Prop_Send, "m_isCalm", 0);


		// --------------------------------------------------
		// CHECK CLIENT BUTTONS, SET PRIMARY WEAPON ATTACK TO NOT SHOOT
		// --------------------------------------------------
		int buttons = GetClientButtons(client);
		SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 10.0);


		// --------------------------------------------------
		// ---------- INCAPPED CRAWLING
		// --------------------------------------------------
		if( g_bCvarCrawl )
		{
			if( !(buttons & IN_FORWARD) && g_iButtons[client] & IN_FORWARD )
			{
				OnWeaponSwitch(client, 0);
			}

			g_iButtons[client] = buttons;
		}


		// --------------------------------------------------
		// ---------- RELOAD : DROP WEAPON
		// --------------------------------------------------
		if( buttons & IN_RELOAD )
		{
			DropExtinguisher(client);
		}


		// --------------------------------------------------
		// ---------- ATTACK : SHOOT!
		// --------------------------------------------------
		else if( (buttons & IN_ATTACK || buttons & IN_ZOOM) && g_iPlayerData[client][INDEX_BLOCK] == 0 && GetGameTime() > g_fTimeout[client] && (g_bLeft4Dead2 ? GetEntPropEnt(client, Prop_Send, "m_useActionOwner") != client : GetEntPropEnt(client, Prop_Send, "m_hUseEntity") <= 0) )
		{
			if( buttons & IN_ZOOM )
			{
				if( !g_iZoomed[client] )
				{
					g_iZoomed[client] = 1;
					RequestFrame(OnFrameZoom, GetClientUserId(client));
				}
			}

			int type;

			if( g_iCvarCombo ) // Combo? Make primary attack a flamethrower, secondary attack the spray and zoom the blast
			{
				if( g_iCvarType & ENUM_FLAMETHROWER && buttons & IN_ATTACK )
				{
					type = TYPE_FLAMETHROWER;
				}
				else if( g_iCvarType & ENUM_BLASTPUSHBACK && buttons & IN_SPEED && buttons & IN_ZOOM )
				{
					type = TYPE_BLASTPUSHBACK;
				}
				else if( (g_iCvarType & ENUM_FREEZERSPRAY || g_iCvarType & ENUM_EXTINGUISHER ) )
				{
					type = TYPE_FREEZERSPRAY;
				}

				g_iPlayerData[client][INDEX_TYPE] = type;
			}
			else
			{
				type = g_iPlayerData[client][INDEX_TYPE];
			}

			int fuel = g_iPlayerData[client][INDEX_FUEL];


			// --------------------------------------------------
			// Fuel is empty... kill particles and show hint. Set timeout so this doesn't trigger again.
			// --------------------------------------------------
			if( g_iCvarFuel && fuel <= 0 )
			{
				g_fTimeout[client] = GetGameTime() + 10.0;

				if( g_iCvarRemove > 1 )
					KillAttachments(client, true);
				else
					KillAttachments(client, false);

				if( g_iCvarHint )
				{
					if( g_iCvarCombo || type == TYPE_EXTINGUISHER )
						PrintHintText(client, "%t", "Ext_EmptyExtinguisher");
					else if( type == TYPE_FLAMETHROWER )
						PrintHintText(client, "%t", "Ext_EmptyFlamethrower");
					else if( type == TYPE_FREEZERSPRAY )
						PrintHintText(client, "%t", "Ext_EmptyFreezerspray");
					else
						PrintHintText(client, "%t", "Ext_EmptyBlastpushback");

					if( g_bLeft4Dead2 == true )
					{
						if( g_iCvarCombo || type == TYPE_EXTINGUISHER )
							CPrintToChat(client, "%t%t", "Ext_ChatTagExtinguisher", "Ext_Refuel");
						else if( type == TYPE_FLAMETHROWER )
							CPrintToChat(client, "%t%t", "Ext_ChatTagFlamethrower", "Ext_Refuel");
						else if( type == TYPE_FREEZERSPRAY )
							CPrintToChat(client, "%t%t", "Ext_ChatTagFreezerspray", "Ext_Refuel");
						else
							CPrintToChat(client, "%t%t", "Ext_ChatTagBlastpushback", "Ext_Refuel");
					}
				}
			}


			// --------------------------------------------------
			// Still has fuel, create particles, update hint
			// --------------------------------------------------
			else
			{
				int iUpdateFuel;

				// Not shooting? No particles
				if( !IsValidEntRef(g_iPlayerData[client][INDEX_PART]) )
				{
					if( type == TYPE_BLASTPUSHBACK )
					{
						g_fTimeout[client] = GetGameTime() + g_fCvarPushTime;

						TraceAttack(client, true, g_iCvarPush, true);

						// FUEL
						if( g_iCvarPushFuel )
						{
							g_iPlayerData[client][INDEX_FUEL] -= g_iCvarPushFuel;
							iUpdateFuel = 1;
						}
					}
					else
					{
						TraceAttack(client, true, 0, true);

						if( g_hTimerTrace == null )
							g_hTimerTrace = CreateTimer(g_fCvarFreq, TimerTrace, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}

					CreateEffects(client);
				}
				else
				{
					// Player is using freezer type, check for inferno to remove
					if( type == TYPE_EXTINGUISHER || (g_iCvarCombo && type == TYPE_FREEZERSPRAY) )
					{
						bool stop;
						int count, entity, x, y, z;
						float vPos[3], vEnd[3], vVec[3];

						for( int index = 0; index < MAX_ALLOWED; index++ )
						{
							entity = g_iInferno[index][0];
							if( IsValidEntRef(entity) )
							{
								GetClientAbsOrigin(client, vPos);
								GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vEnd);

								if( g_bLeft4Dead2 )
								{
									if( GetVectorDistance(vPos, vEnd) <= 300.0 )
									{
										count = GetEntProp(entity, Prop_Send, "m_fireCount") - 1;

										for( int i = count; i > 0; )
										{
											i--;
											x = GetEntProp(entity, Prop_Send, "m_fireXDelta", 4, i);
											y = GetEntProp(entity, Prop_Send, "m_fireYDelta", 4, i);
											z = GetEntProp(entity, Prop_Send, "m_fireZDelta", 4, i);

											vVec = vEnd;
											vVec[0] += x;
											vVec[1] += y;
											vVec[2] += z;

											if( GetVectorDistance(vPos, vVec) <= 50.0 )
											{
												if( g_iInferno[index][1]++ >= g_iCvarTime )
												{
													stop = true;
													RemoveEntity(entity);
													break;
												}
											}
										}
									}
								}
								else
								{
									if( GetVectorDistance(vPos, vEnd) <= 250.0 )
									{
										if( g_iInferno[index][1]++ >= g_iCvarTime )
										{
											stop = true;
											RemoveEntity(entity);
											break;
										}
									}
								}
							}

							if( stop ) break;
						}
					}
				}


				// FUEL
				if( g_iCvarFuel )
				{
					if( type != TYPE_BLASTPUSHBACK )
						g_iPlayerData[client][INDEX_FUEL]--;
					else
					{
						if( iUpdateFuel == 0 )
							return;
						else
							iUpdateFuel = 0;
					}
				}


				// FUEL HINT
				if( g_iCvarFuel && g_iCvarHint )
				{
					int percent = fuel * 10 / g_iCvarFuel;
					if( percent != (fuel -= type == TYPE_BLASTPUSHBACK ? g_iCvarPushFuel : 1) * 10 / g_iCvarFuel )
					{
						char sTemp[12];
						for( int i = 0; i < 10; i++ )
						{
							if( i < percent )
								StrCat(sTemp, sizeof(sTemp), "|");
							else
								StrCat(sTemp, sizeof(sTemp), " ");
						}

						if( g_iCvarCombo || type == TYPE_EXTINGUISHER )
							PrintHintText(client, "%t [%s]", "Ext_FuelExtinguisher", sTemp);
						else if( type == TYPE_FLAMETHROWER )
							PrintHintText(client, "%t [%s]", "Ext_FuelFlamethrower", sTemp);
						else if( type == TYPE_FREEZERSPRAY )
							PrintHintText(client, "%t [%s]", "Ext_FuelFreezerspray", sTemp);
						else
							PrintHintText(client, "%t [%s]", "Ext_FuelBlastpushback", sTemp);
					}
				}
			}
		}


		// --------------------------------------------------
		// NOT SHOOTING EXT, DELETE THE PARTICLES IF THEY ARE VALID
		// --------------------------------------------------
		else if( IsValidEntRef(g_iPlayerData[client][INDEX_PART]) )
		{
			// No longer firing weapon, kill particles etc.
			KillAttachments(client, false);

			// Timeout, stop shooting
			if( g_iPlayerData[client][INDEX_TYPE] == TYPE_BLASTPUSHBACK )
			{
				g_fTimeout[client] = GetGameTime() + g_fCvarPushTime;
			}
			else
			{
				g_fTimeout[client] = GetGameTime() + g_fCvarTimeout;
			}
		}
	}
	else
	{
		if( g_bLeft4Dead2 && IsValidEntRef(g_iRefuel[client][0]) == false )
		{
			g_iHooked[client] = 0;
			SDKUnhook(client, SDKHook_PreThink, OnPreThink);
		}
	}
}



// ====================================================================================================
//					EFFECTS - SPRAY or (FIRE and LIGHT) and DAMAGE.
// ====================================================================================================
void CreateEffects(int client)
{
	float vPos[3], vAng[3];

	int iType = g_iPlayerData[client][INDEX_TYPE];
	int particle = CreateEntityByName("info_particle_system");
	if( iType == TYPE_FLAMETHROWER )
		if( g_iCvarFlame == 0 || g_iCvarFlame == 2 )
			DispatchKeyValue(particle, "effect_name", PARTICLE_FIRE1);
		else
			DispatchKeyValue(particle, "effect_name", PARTICLE_FIRE2);
	else if( iType == TYPE_BLASTPUSHBACK )
		DispatchKeyValue(particle, "effect_name", PARTICLE_BLAST1);
	else
		DispatchKeyValue(particle, "effect_name", PARTICLE_SPRAY);

	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "Start");
	g_iPlayerData[client][INDEX_PART] = EntIndexToEntRef(particle);

	SetVariantString("!activator");
	AcceptEntityInput(particle, "SetParent", client);

	int bone = GetSurvivorType(client);

	if( bone == 0 )
	{
		SetVariantString(ATTACHMENT_BONE);

		if( iType == TYPE_BLASTPUSHBACK )
		{
			vPos[1] = 5.0;
			vPos[2] = 20.0;
		}
		else if( iType == TYPE_FLAMETHROWER )
		{
			vPos[1] = 7.0;
			vPos[2] = 25.0;

			if( g_iCvarFlame == 0 || g_iCvarFlame == 2 )
			{
				vAng[0] = -90.0;
				vAng[1] = -90.0;
				vAng[2] = -90.0;
			}
		}
		else
		{
			vAng[0] = -90.0;
			vPos[0] = -1.0;
			vPos[1] = 7.0;
			vPos[2] = 18.0;
		}
	}
	else
	{
		SetVariantString(ATTACHMENT_ARM);

		if( iType == TYPE_BLASTPUSHBACK )
		{
			vAng[0] = 90.0;
			vAng[1] = 90.0;
			vPos[0] = -5.0;
			vPos[1] = 45.0;
		}
		else if( iType == TYPE_FLAMETHROWER )
		{
			vAng[1] = 90.0;
			vPos[0] = -5.0;
			vPos[1] = 45.0;
		}
		else
		{
			vAng[1] = 90.0;
			vPos[0] = -3.0;
			vPos[2] = -3.0;
			vPos[1] = 35.0;
		}
	}

	AcceptEntityInput(particle, "SetParentAttachment");
	TeleportEntity(particle, vPos, vAng, NULL_VECTOR);


	// ====================================================================================================
	// SOUND
	// ====================================================================================================
	if( iType == TYPE_FLAMETHROWER )
	{
		EmitSoundToAll(g_bLeft4Dead2 ? SOUND_FIRE_L4D2 : SOUND_FIRE_L4D1, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
	else if( iType == TYPE_BLASTPUSHBACK )
	{
		EmitSoundToAll(SOUND_BLAST, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
	else
	{
		EmitSoundToAll(SOUND_SPRAY, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}


	// ====================================================================================================
	// BLAST
	// ====================================================================================================
	int entity;
	if( g_bLeft4Dead2 && iType == TYPE_BLASTPUSHBACK )
	{
		entity = CreateEntityByName("info_particle_system");
		DispatchKeyValue(entity, "effect_name", PARTICLE_BLAST2);

		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "Start");

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);

		if( bone == 0 ) SetVariantString(ATTACHMENT_BONE);
		else SetVariantString(ATTACHMENT_ARM);
		AcceptEntityInput(entity, "SetParentAttachment");

		vPos[2] = 100.0;
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::1.0:-1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}


	// ====================================================================================================
	// LIGHT_DYNAMIC
	// ====================================================================================================
	if( iType == TYPE_FLAMETHROWER )
	{
		if( (g_iCvarFlame == 2 || g_iCvarFlame == 3) )
		{
			entity = CreateEntityByName("light_dynamic");
			DispatchKeyValue(entity, "_light", "255 30 0 255");
			DispatchKeyValue(entity, "brightness", "1");
			DispatchKeyValueFloat(entity, "spotlight_radius", 32.0);
			DispatchKeyValueFloat(entity, "distance", 25.0);
			DispatchKeyValue(entity, "style", "6");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "TurnOn");
			g_iPlayerData[client][INDEX_LIGHT] = EntIndexToEntRef(entity);

			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", client);

			if( bone == 0 ) SetVariantString(ATTACHMENT_BONE);
			else SetVariantString(ATTACHMENT_ARM);
			AcceptEntityInput(entity, "SetParentAttachment");

			if( g_iCvarFlame == 3 )
			{
				SetVariantString("OnUser1 !self:Distance:50:0.1:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser1 !self:Distance:80:0.2:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser1 !self:Distance:125:0.3:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser1 !self:Distance:180:0.4:-1");
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser1");
			}
			else
			{
				SetVariantString("OnUser1 !self:Distance:100:0.1:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser1 !self:Distance:180:0.2:-1");
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser1");
			}

			TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

void OnWeaponSwitch(int client, int weapon)
{
	weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	if( weapon != -1 )
	{
		if( IsValidEntRef(g_iPlayerData[client][INDEX_PROP]) )
		{
			if( GetPlayerWeaponSlot(client, 0) == weapon )
			{
				switch( g_iGunSlot[client] )
				{
					case SLOT_PRIMARY, SLOT_TEMP_SEC, SLOT_CURRENT_PRI:
					{
						SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
					}
					default:
					{
						SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
					}
				}
			}
			else if( GetPlayerWeaponSlot(client, 1) == weapon )
			{
				switch( g_iGunSlot[client] )
				{
					case SLOT_SECONDARY, SLOT_TEMP_PRI, SLOT_CURRENT_SEC:
					{
						SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
					}
					default:
					{
						SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
					}
				}
			}
			else
			{
				SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
			}
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		}
	}
}

void OnWeaponIncap(int client)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	if( weapon != -1 )
	{
		if( IsValidEntRef(g_iPlayerData[client][INDEX_PROP]) )
		{
			if( GetPlayerWeaponSlot(client, 0) == weapon )
			{
				switch( g_iGunSlot[client] )
				{
					case SLOT_PRIMARY, SLOT_TEMP_SEC, SLOT_CURRENT_PRI:
					{
						MoveExtinguisher(client, true);
					}
					default:
					{
						MoveExtinguisher(client, false);
					}
				}
			}
			else if( GetPlayerWeaponSlot(client, 1) == weapon )
			{
				switch( g_iGunSlot[client] )
				{
					case SLOT_SECONDARY, SLOT_TEMP_PRI, SLOT_CURRENT_SEC:
					{
						MoveExtinguisher(client, true);
					}
					default:
					{
						MoveExtinguisher(client, false);
					}
				}
			}
			else
			{
				MoveExtinguisher(client, false);
			}
		}
		else
		{
			MoveExtinguisher(client, false);
		}
	}
}



// ====================================================================================================
//					CREATE BUTTON ON ALL EXTINGUISHERS
// ====================================================================================================
public void OnEntityCreated(int entity, const char[] classname)
{
	if( g_bCvarAllow && g_iLoadStatus && g_iCvarType & ENUM_EXTINGUISHER )
	{
		if( (g_iCvarSpray & (1<<0) && strcmp(classname, "inferno") == 0) || g_bLeft4Dead2 &&
			((g_iCvarSpray & (1<<1) && (strcmp(classname, "fire_cracker_blast") == 0)) ||
			(g_iCvarSpray & (1<<2) && strcmp(classname, "insect_swarm") == 0)) )
		{
			SDKHook(entity, SDKHook_Spawn, OnSpawnInferno);
		}
	}
}

void OnSpawnInferno(int entity)
{
	if( !(g_iCvarType & ENUM_EXTINGUISHER) )
		return;

	int index = -1;
	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		if( !IsValidEntRef(g_iInferno[i][0]) )
		{
			index = i;
			break;
		}
	}

	if( index != -1 )
	{
		g_iInferno[index][0] = EntIndexToEntRef(entity);
		g_iInferno[index][1] = 0;
	}
}



// ====================================================================================================
//					CREATE BUTTON
// ====================================================================================================
bool CreateButton(int entity, int arraytype, int iType = 0)
{
	int index;
	if( iType == 0 ||
		iType == 1 && !(g_iCvarType & ENUM_EXTINGUISHER) ||
		iType == 2 && !(g_iCvarType & ENUM_FLAMETHROWER) ||
		iType == 3 && !(g_iCvarType & ENUM_FREEZERSPRAY) ||
		iType == 4 && !(g_iCvarType & ENUM_BLASTPUSHBACK) )
		iType = GetRandomType(g_iCvarType);

	if( arraytype == ENUM_WALLEXT )
	{
		char sModelName[48];
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));

		if( strcmp(sModelName, MODEL_EXTINGUISHER, false) != 0 )
			return false;

		for( int i = 0; i < MAX_ALLOWED; i++ )
		{
			if( !IsValidEntRef(g_iWallExt[i][1]) )	// Button
			{
				g_iSpawnCount++;
				index = i;
				break;
			}
			else if( i == MAX_ALLOWED -1 )
			{
				ThrowError("No free index to store wall button");
			}
		}
		g_iWallExt[index][0] = EntIndexToEntRef(entity);
	}
	else if( arraytype == ENUM_DROPPED )
	{
		for( int i = 0; i < MAX_ALLOWED; i++ )
		{
			if( !IsValidEntRef(g_iDropped[i][1]) )
			{
				index = i;
				break;
			}
			else if( i == MAX_ALLOWED -1 )
				ThrowError("No free index to store drop button");
		}
		g_iDropped[index][0] = EntIndexToEntRef(entity);
	}
	else
	{
		for( int i = 0; i < MAX_ALLOWED; i++ )
		{
			if( !IsValidEntRef(g_iSpawned[i][1]) )
			{
				index = i;
				break;
			}
			else if( i == MAX_ALLOWED -1 )
				ThrowError("No free index to store drop button");
		}
		g_iSpawned[index][0] = EntIndexToEntRef(entity);
	}


	char sTemp[16];
	int button;
	if( g_fCvarTimed == 0.0 )
		button = CreateEntityByName("func_button");
	else
		button = CreateEntityByName("func_button_timed");

	if( arraytype == ENUM_WALLEXT )
		g_iWallExt[index][1] = EntIndexToEntRef(button);
	else if( arraytype == ENUM_DROPPED )
		g_iDropped[index][1] = EntIndexToEntRef(button);
	else
		g_iSpawned[index][1] = EntIndexToEntRef(button);

	Format(sTemp, sizeof(sTemp), "ft%d", EntIndexToEntRef(button));
	DispatchKeyValue(entity, "targetname", sTemp);
	DispatchKeyValue(button, "glow", sTemp);
	DispatchKeyValue(button, "rendermode", "3");

	if( g_bLeft4Dead2 && g_iCvarGlowRan )
	{
		SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarGlowRan);
		SetEntProp(entity, Prop_Send, "m_iGlowType", 3);

		if( g_iCvarCombo )
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarCombo);
		else if( iType == TYPE_EXTINGUISHER )
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowE);
		else if( iType == TYPE_FLAMETHROWER )
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowF);
		else if( iType == TYPE_FREEZERSPRAY )
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowS);
		else
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowB);

		ChangeEdictState(entity, g_iOffsetGlow);
		AcceptEntityInput(entity, "StartGlowing");
	}

	if( arraytype == ENUM_WALLEXT )
		g_iWallExt[index][2] = iType;
	else if( arraytype == ENUM_DROPPED )
		g_iDropped[index][3] = iType;
	else
		g_iSpawned[index][3] = iType;

	if( g_fCvarTimed == 0.0 )
	{
		DispatchKeyValue(button, "spawnflags", "1025");
		DispatchKeyValue(button, "wait", "1");
	}
	else
	{
		DispatchKeyValue(button, "spawnflags", "0");
		DispatchKeyValue(button, "auto_disable", "1");
		FloatToString(g_fCvarTimed, sTemp, sizeof(sTemp));
		DispatchKeyValue(button, "use_time", sTemp);
	}
	DispatchSpawn(button);
	AcceptEntityInput(button, "Enable");
	ActivateEntity(button);

	SetVariantString("!activator");
	AcceptEntityInput(button, "SetParent", entity);
	TeleportEntity(button, view_as<float>({0.0, 0.0, 5.0}), NULL_VECTOR, NULL_VECTOR);

	SetEntProp(button, Prop_Send, "m_nSolidType", 0, 1);
	SetEntProp(button, Prop_Send, "m_usSolidFlags", 4, 2);

	float vMins[3]; vMins = view_as<float>({-5.0, -5.0, -5.0});
	float vMaxs[3]; vMaxs = view_as<float>({5.0, 5.0, 5.0});
	SetEntPropVector(button, Prop_Send, "m_vecMins", vMins);
	SetEntPropVector(button, Prop_Send, "m_vecMaxs", vMaxs);

	if( g_bLeft4Dead2 )
	{
		SetEntProp(button, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(button, Prop_Send, "m_CollisionGroup", 1);
	}

	if( g_iCvarBreak == 0 )
		SetEntProp(entity, Prop_Data, "m_iMinHealthDmg", 99999);
	else if( g_iCvarBreak > 1 )
		HookSingleEntityOutput(entity, "OnHealthChanged", OnHealthChanged);

	if( g_fCvarTimed == 0 )
		HookSingleEntityOutput(button, "OnPressed", OnPressed);
	else
	{
		SetVariantString("OnTimeUp !self:Enable::1:-1");
		AcceptEntityInput(button, "AddOutput");
		HookSingleEntityOutput(button, "OnTimeUp", OnPressed);
	}

	return true;
}



// ====================================================================================================
//					BUTTON PRESS - GIVE
// ====================================================================================================
void OnPressed(const char[] output, int caller, int activator, float delay)
{
	if( !g_bCvarAllow )
		return;

	if( IsValidEntRef(g_iPlayerData[activator][INDEX_PROP]) )
	{
		if( g_iCvarHint )
		{
			if( g_sCvarWeapon[0] == 0 )
				CPrintToChat(activator, "%t%t", "Ext_ChatTagExtinguisher", "Ext_EquipHasCombo");
			else
			{
				char sTemp[256], sWeapon[64];
				Format(sTemp, sizeof(sTemp), "%T%T", "Ext_ChatTagExtinguisher", activator, "Ext_EquipHasCheck", activator);
				Format(sWeapon, sizeof(sWeapon), "%T", "Ext_WeaponName", LANG_SERVER);
				ReplaceStringEx(sTemp, sizeof(sTemp), "<WEAPON>", sWeapon);
				CPrintToChat(activator, sTemp);
			}
		}
		return;
	}

	if( g_iCvarMax && ExtinguisherCount(activator) == false )
		return;

	int iWeapon = GetEntPropEnt(activator, Prop_Send, "m_hActiveWeapon");
	int iValidWeapon = HasWeapon(activator, iWeapon);

	if( g_iCvarCheck && iValidWeapon == 0 )
	{
		if( g_iCvarHint )
		{
			char sTemp[256], sWeapon[64];
			Format(sTemp, sizeof(sTemp), "%T%T", "Ext_ChatTagExtinguisher", activator, "Ext_Blocked", activator);
			Format(sWeapon, sizeof(sWeapon), "%T", "Ext_WeaponName", LANG_SERVER);
			ReplaceStringEx(sTemp, sizeof(sTemp), "<WEAPON>", sWeapon);
			CPrintToChat(activator, sTemp);
		}
		return;
	}

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		if( g_iDropped[i][1] && EntRefToEntIndex(g_iDropped[i][1]) == caller ) // Dropped Button
		{
			g_iPlayerData[activator][INDEX_FUEL] = g_iDropped[i][2];
			g_iPlayerData[activator][INDEX_TYPE] = g_iDropped[i][3];
			g_iDropped[i][1] = 0;
			g_iDropped[i][2] = 0;
			if( IsValidEntRef(g_iDropped[i][0]) )
			{
				RemoveEntity(g_iDropped[i][0]);
				g_iDropped[i][0] = 0;
				break;
			}
		}
		else if( g_iSpawned[i][1] && EntRefToEntIndex(g_iSpawned[i][1]) == caller ) // Spawned Button
		{
			g_iPlayerData[activator][INDEX_FUEL] = g_iCvarFuel;
			g_iPlayerData[activator][INDEX_TYPE] = g_iSpawned[i][3];
			if( IsValidEntRef(g_iSpawned[i][0]) )
			{
				RemoveEntity(g_iSpawned[i][0]);
				g_iSpawned[i][0] = 0;
				g_iSpawned[i][1] = 0;
				break;
			}
		}
		else if( g_iWallExt[i][1] && EntRefToEntIndex(g_iWallExt[i][1]) == caller ) // Wall Button
		{
			g_iPlayerData[activator][INDEX_FUEL] = g_iCvarFuel;
			g_iPlayerData[activator][INDEX_TYPE] = g_iWallExt[i][2];
			if( IsValidEntRef(g_iWallExt[i][0]) )
			{
				RemoveEntity(g_iWallExt[i][0]);
				g_iWallExt[i][0] = 0;
				g_iWallExt[i][1] = 0;
				break;
			}
		}
		else if( i == MAX_ALLOWED -1 )
		{
			g_iPlayerData[activator][INDEX_FUEL] = g_iCvarFuel;
			g_iPlayerData[activator][INDEX_TYPE] = GetRandomType(g_iCvarType);
			LogError("Cannot find button index..."); // Should never happen
		}
	}

	RemoveEntity(caller); // Delete button
	GiveExtinguisher(activator);
}



// ====================================================================================================
//					ON HEALTH CHANGED
// ====================================================================================================
void OnHealthChanged(const char[] output, int caller, int activator, float delay)
{
	if( g_iCvarBreak == 3 && activator > 0 && activator <= MaxClients && GetClientTeam(activator) == 3 )
		return;

	UnhookSingleEntityOutput(caller, "OnHealthChanged", OnHealthChanged);

	int iArray, iType, iButton;

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		if( g_iWallExt[i][0] && EntRefToEntIndex(g_iWallExt[i][0]) == caller )
		{
			iButton = g_iWallExt[i][1];
			if( IsValidEntRef(iButton) )
			{
				if( g_iCvarRemove == 1 || g_iCvarRemove == 3 )
				{
					RemoveEntity(iButton);
					g_iWallExt[i][0] = 0;
					g_iWallExt[i][1] = 0;
				}
				else
				{
					AcceptEntityInput(iButton, "Disable");
				}

				iType = g_iWallExt[i][2];
				iArray = 1;
				break;
			}
		}

		if( g_iDropped[i][0] && EntRefToEntIndex(g_iDropped[i][0]) == caller )
		{
			iButton = g_iDropped[i][1];
			if( IsValidEntRef(iButton) )
			{
				if( g_iCvarRemove == 1 || g_iCvarRemove == 3 )
				{
					RemoveEntity(iButton);
					g_iDropped[i][0] = 0;
					g_iDropped[i][1] = 0;
				}
				else
				{
					AcceptEntityInput(iButton, "Lock");
					AcceptEntityInput(iButton, "Disable");
				}

				g_iDropped[i][2] = -12345;
				iType = g_iDropped[i][3];
				iArray = 2;
				break;
			}
		}

		if( g_iSpawned[i][0] && EntRefToEntIndex(g_iSpawned[i][0]) == caller )
		{
			iButton = g_iSpawned[i][1];
			if( IsValidEntRef(iButton) )
			{
				if( g_iCvarRemove == 1 || g_iCvarRemove == 3 )
				{
					RemoveEntity(iButton);
					g_iSpawned[i][0] = 0;
					g_iSpawned[i][1] = 0;
				}
				else
				{
					AcceptEntityInput(iButton, "Disable");
				}

				iType = g_iSpawned[i][3];
				iArray = 3;
				break;
			}
		}
	}

	if( iArray == 0 )
	{
		LogError("Cannot find broken extinguisher..."); // Should never happen
		return;
	}

	int client = GetEntPropEnt(iButton, Prop_Data, "m_hActivator");
	if( client != -1 )
	{
		if( client > 0 && client <= MaxClients && IsClientInGame(client) )
		{
			SetEntPropEnt(client, Prop_Send, "m_useActionOwner", -1);
			SetEntPropEnt(client, Prop_Send, "m_useActionTarget", -1);
			SetEntProp(client, Prop_Send, "m_iCurrentUseAction", 0);
		}
	}

	if( iType == TYPE_FLAMETHROWER || GetRandomInt(0, 2) == 1 )
	{
		int entity = CreateEntityByName("info_particle_system");
		DispatchKeyValue(entity, "effect_name", PARTICLE_RAND);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "Start");

		float vPos[3], vAng[3];
		GetEntPropVector(caller, Prop_Data, "m_vecOrigin", vPos);
		GetEntPropVector(caller, Prop_Data, "m_angRotation", vAng);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", caller);

		SetVariantString("OnUser1 !self:ClearParent::4:1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser1 !self:Kill::4.1:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}

	if( iArray != 1 ) // Wall ext
	{
		int entity = CreateEntityByName("info_particle_system");
		DispatchKeyValue(entity, "effect_name", PARTICLE_SPRAY);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "Start");

		float vPos[3], vAng[3];
		GetEntPropVector(caller, Prop_Data, "m_vecOrigin", vPos);
		GetEntPropVector(caller, Prop_Data, "m_angRotation", vAng);
		float vFwd[3], vRight[3], vUp[3];
		GetAngleVectors(vAng, vFwd, vRight, vUp);
		ScaleVector(vFwd, 2.0);
		ScaleVector(vUp, 22.0);
		vPos[0] += vFwd[0] + vRight[0] + vUp[0];
		vPos[1] += vFwd[1] + vRight[1] + vUp[1];
		vPos[2] += vFwd[2] + vRight[2] + vUp[2];
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", caller);

		SetVariantString("OnUser1 !self:ClearParent::5:1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser1 !self:Kill::5.1:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");

		EmitSoundToAll(SOUND_SPRAY, caller, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 5.0);
		CreateTimer(5.0, TimerStopSound, EntIndexToEntRef(caller));
	}

	AcceptEntityInput(caller, "StopGlowing");

	if( g_iCvarRemove == 1 || g_iCvarRemove == 3 )
	{
		SetVariantString("OnUser1 !self:Kill::6:1");
		AcceptEntityInput(caller, "AddOutput");
		AcceptEntityInput(caller, "FireUser1");
	}

	if( (g_iCvarHint == 1 || g_iCvarHint == 3 ) && activator > 0 && activator <= MaxClients )
	{
		char sTemp[256], sName[MAX_NAME_LENGTH];
		GetClientName(activator, sName, MAX_NAME_LENGTH);

		for( int x = 1; x <= MaxClients; x++ )
		{
			if( IsClientInGame(x) )
			{
				if( g_iCvarCombo || iType == TYPE_EXTINGUISHER )
					Format(sTemp, sizeof(sTemp), "%T%T", "Ext_ChatTagExtinguisher", x, "Ext_Broken", x);
				else if( iType == TYPE_FLAMETHROWER )
					Format(sTemp, sizeof(sTemp), "%T%T", "Ext_ChatTagFlamethrower", x, "Ext_Broken", x);
				else if( iType == TYPE_FREEZERSPRAY )
					Format(sTemp, sizeof(sTemp), "%T%T", "Ext_ChatTagFreezerspray", x, "Ext_Broken", x);
				else
					Format(sTemp, sizeof(sTemp), "%T%T", "Ext_ChatTagBlastpushback", x, "Ext_Broken", x);

				ReplaceStringEx(sTemp, sizeof(sTemp), "<NAME>", sName);

				CPrintToChat(x, sTemp);
			}
		}
	}
}

Action TimerStopSound(Handle timer, int entity)
{
	if( IsValidEntRef(entity) )
		StopSound(entity, SNDCHAN_AUTO, SOUND_SPRAY);

	return Plugin_Continue;
}



// ====================================================================================================
//					MOVE EXTINGUISHER - PARENT TO HAND / BACK
// ====================================================================================================
void OnMoveCharm(int client)
{
	client = GetClientOfUserId(client);
	if( client ) Charms_Delete(client);

	// Because charms resets
	if( g_iCvarView == 1 )
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
}

void MoveExtinguisher(int client, bool bWeaponSlot = false)
{
	int entity = g_iPlayerData[client][INDEX_PROP];

	if( IsValidEntRef(entity) )
	{
		float vPos[3], vAng[3];

		AcceptEntityInput(entity, "ClearParent");
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);

		entity = EntRefToEntIndex(entity);

		if( bWeaponSlot )
		{
			if( g_bCharmsPlugin )
			{
				Charms_Delete(client);
				RequestFrame(OnMoveCharm, GetClientUserId(client));
			}

			if( g_iCvarView == 1 )
				SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);

			int bone = GetSurvivorType(client);
			if( bone == 0 )
			{
				SetVariantString(ATTACHMENT_BONE);
				vAng[2] = 180.0;
				vPos[0] = -5.0;
				vPos[1] = 2.0;
				vPos[2] = 23.0;
			}
			else
			{
				SetVariantString(ATTACHMENT_ARM);
				vAng[2] = 90.0;
				vPos[0] = -5.0;
				vPos[1] = 40.0;
			}
			AcceptEntityInput(entity, "SetParentAttachment");

			if( g_iCvarView != 2 )
				SDKUnhook(entity, SDKHook_SetTransmit, OnTransmit);
		}
		else
		{
			if( g_bCharmsPlugin )
			{
				Charms_Create(client);
			}

			if( g_iCvarView == 1 )
			{
				if( !g_bCharmsPlugin || Charms_GetIndex(client) == 0 )
					SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
			}

			vAng[0] = 260.0;
			vAng[2] = 10.0;
			vPos[0] = 15.0;
			vPos[1] = 2.0;
			vPos[2] = 5.0;
			SetVariantString(ATTACHMENT_PRIMARY);
			AcceptEntityInput(entity, "SetParentAttachment");

			if( g_iCvarView != 2 )
				SDKHook(entity, SDKHook_SetTransmit, OnTransmit);
		}

		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	}
}



// ====================================================================================================
//					DROP EXTINGUISHER
// ====================================================================================================
void DropExtinguisher(int client)
{
	if( IsValidEntRef(g_iPlayerData[client][INDEX_PROP]) )
	{
		int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		int iValidWeapon = HasWeapon(client, iWeapon);
		if( iValidWeapon )
			SetEntPropFloat(iValidWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.2);

		if( g_bCharmsPlugin )
		{
			Charms_Create(client);
		}

		if( g_iCvarView == 1 )
		{
			if( !g_bCharmsPlugin || Charms_GetIndex(client) == 0 )
				SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		}

		//int index;
		for( int i = 0; i < MAX_ALLOWED; i++ )
		{
			if( !IsValidEntRef(g_iDropped[i][0]) )
			{
				//index = i;
				break;
			}
			else if( i == MAX_ALLOWED -1 )
			{
				KillAttachments(client, true);
				ThrowError("No free index for extinguisher model.");
			}
		}

		//int entity = CreateEntityByName("prop_physics");
		//DispatchKeyValue(entity, "disableshadows", "1");
		//DispatchKeyValue(entity, "model", MODEL_EXTINGUISHER);
		//DispatchSpawn(entity);

		//float vPos[3], vAng[3];
		//GetClientAbsOrigin(client, vPos);
		//GetClientAbsAngles(client, vAng);
		//MoveForward(vPos, vAng, vPos, 32.0);
		//vPos[2] += 2.0;
		//TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

		//SetEntProp(entity, Prop_Data, "m_CollisionGroup", 1);
		//SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);

		//g_iDropped[index][0] = EntIndexToEntRef(entity);
		//g_iDropped[index][2] = g_iPlayerData[client][INDEX_FUEL];
		//g_iDropped[index][3] = g_iPlayerData[client][INDEX_TYPE];
		g_iPlayerData[client][INDEX_FUEL] = 0;

		//CreateButton(entity, ENUM_DROPPED, g_iDropped[index][3]);
		KillAttachments(client, true);
	}
}



// ====================================================================================================
//					GIVE EXTINGUISHER
// ====================================================================================================
void GiveExtinguisher(int client)
{
	if( g_iCvarMax && ExtinguisherCount(client) == false )
		return;

	int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	int slot = GetPlayerWeaponSlot(client, 1);
	if( iWeapon == slot )
		g_iGunSlot[client] = g_iCvarIncap == 2 ? SLOT_CURRENT_SEC : SLOT_SECONDARY;
	else
		g_iGunSlot[client] = g_iCvarIncap == 2 ? SLOT_CURRENT_PRI : SLOT_PRIMARY;

	int iValidWeapon = HasWeapon(client, iWeapon);

	if( g_iCvarCheck && iValidWeapon == 0 )
	{
		if( g_iCvarHint )
		{
			char sTemp[256], sWeapon[64];
			Format(sTemp, sizeof(sTemp), "%T%T", "Ext_ChatTagExtinguisher", client, "Ext_Blocked", client);
			Format(sWeapon, sizeof(sWeapon), "%T", "Ext_WeaponName", LANG_SERVER);
			ReplaceStringEx(sTemp, sizeof(sTemp), "<WEAPON>", sWeapon);
			CPrintToChat(client, sTemp);
		}
		return;
	}

	KillAttachments(client, true);

	if( g_iHooked[client] == 0 )
	{
		g_iHooked[client] = 1;
		SDKHook(client, SDKHook_PreThink, OnPreThink);
	}

	int entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "disableshadows", "1");
	DispatchKeyValue(entity, "model", MODEL_EXTINGUISHER);
	DispatchSpawn(entity);
	SetEntProp(entity, Prop_Data, "m_iEFlags", 0);

	g_iPlayerData[client][INDEX_PROP] = EntIndexToEntRef(entity);
	if( g_iCvarView == 2 )
		SDKHook(entity, SDKHook_SetTransmit, OnTransmit);

	// Check if the equipped weapon activates the extinguisher, if so, MoveExt to their hand, else move to their back.
	if( iWeapon != -1 && iWeapon == iValidWeapon )
	{
		SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 10.0);
		MoveExtinguisher(client, true);

		g_fTimeout[client] = GetGameTime() + g_fCvarTimeout;
	}
	else
		MoveExtinguisher(client, false);

	if( g_iCvarHint )
	{
		char sTemp[256];
		int type = g_iPlayerData[client][INDEX_TYPE];

		// Display message about using the item
		if( g_iCvarCombo )
			Format(sTemp, sizeof(sTemp), "%T%T", "Ext_ChatTagExtinguisher", client, "Ext_EquipCombo", client);
		else
		{
			if( type == TYPE_EXTINGUISHER )
				Format(sTemp, sizeof(sTemp), "%T%T", "Ext_ChatTagExtinguisher", client, "Ext_EquipUseExtinguisher", client);
			else if( type == TYPE_FLAMETHROWER )
				Format(sTemp, sizeof(sTemp), "%T%T", "Ext_ChatTagFlamethrower", client, "Ext_EquipUseFlamethrower", client);
			else if( type == TYPE_FREEZERSPRAY )
				Format(sTemp, sizeof(sTemp), "%T%T", "Ext_ChatTagFreezerspray", client, "Ext_EquipUseFreezerspray", client);
			else
				Format(sTemp, sizeof(sTemp), "%T%T", "Ext_ChatTagBlastpushback", client, "Ext_EquipUseBlastpushback", client);
		}

		CPrintToChat(client, sTemp);

		// Display message if fuel empty
		if( g_iCvarFuel && g_iPlayerData[client][INDEX_FUEL] == 0 )
		{
			if( g_iCvarRemove > 1 )
				KillAttachments(client, true);

			if( g_iCvarCombo || type == TYPE_EXTINGUISHER )
				PrintHintText(client, "%t", "Ext_EmptyExtinguisher");
			else if( type == TYPE_FLAMETHROWER )
				PrintHintText(client, "%t", "Ext_EmptyFlamethrower");
			else if( type == TYPE_FREEZERSPRAY )
				PrintHintText(client, "%t", "Ext_EmptyFreezerspray");
			else
				PrintHintText(client, "%t", "Ext_EmptyBlastpushback");
		}
	}
}


bool ExtinguisherCount(int client)
{
	int count;
	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		if( IsValidEntRef(g_iPlayerData[i][INDEX_PROP]) )
			count++;

		if( count > g_iCvarMax )
		{
			if( g_iCvarHint )
				CPrintToChat(client, "%t%t", "Ext_ChatTagExtinguisher", "Ext_EquipFull");
			return false;
		}
	}

	return true;
}



// ====================================================================================================
//					SET TRANSMIT
// ====================================================================================================
Action OnTransmit(int entity, int client)
{
	if( EntIndexToEntRef(entity) == g_iPlayerData[client][INDEX_PROP] )
		return Plugin_Handled;
	return Plugin_Continue;
}



// ====================================================================================================
//					KILL ATTACHMENTS / ENTS
// ====================================================================================================
void KillAttachments(int client, bool all)
{
	if( all )
	{
		if( g_bCharmsPlugin )
		{
			Charms_Delete(client);
		}

		if( g_iCvarView == 1 )
		{
			if( !g_bCharmsPlugin || Charms_GetIndex(client) == 0 )
				SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		}

		int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		int iValidWeapon = HasWeapon(client, iWeapon);
		if( iValidWeapon )
			SetEntPropFloat(iValidWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.2);

		if( g_iHooked[client] )
		{
			g_iHooked[client] = 0;
			SDKUnhook(client, SDKHook_PreThink, OnPreThink);
		}
	}

	StopSound(client, SNDCHAN_AUTO, SOUND_SPRAY);
	StopSound(client, SNDCHAN_AUTO, g_bLeft4Dead2 ? SOUND_FIRE_L4D2 : SOUND_FIRE_L4D1);

	int entity = g_iPlayerData[client][INDEX_PROP];
	if( all && IsValidEntRef(entity ) )
	{
		if( g_iCvarView == 2 )
			SDKUnhook(entity, SDKHook_SetTransmit, OnTransmit);
		AcceptEntityInput(entity, "ClearParent");
		RemoveEntity(entity);
		g_iPlayerData[client][INDEX_PROP] = 0;
	}

	entity = g_iPlayerData[client][INDEX_PART];
	if( IsValidEntRef(entity) )
	{
		AcceptEntityInput(entity, "ClearParent");
		RemoveEntity(entity);
		g_iPlayerData[client][INDEX_PART] = 0;
	}

	entity = g_iPlayerData[client][INDEX_LIGHT];
	if( IsValidEntRef(entity) )
	{
		AcceptEntityInput(entity, "ClearParent");
		RemoveEntity(entity);
		g_iPlayerData[client][INDEX_LIGHT] = 0;
	}
}

void KillEnts()
{
	int entity;

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		entity = g_iWallExt[i][0];
		if( IsValidEntRef(entity) )
		{
			StopSound(entity, SNDCHAN_AUTO, SOUND_SPRAY);
			AcceptEntityInput(entity, "StopGlowing");
			g_iWallExt[i][0] = 0;
		}

		entity = g_iWallExt[i][1];
		if( IsValidEntRef(entity) )
		{
			RemoveEntity(entity);
			g_iWallExt[i][1] = 0;
		}

		entity = g_iDropped[i][0];
		if( IsValidEntRef(entity) )
		{
			StopSound(entity, SNDCHAN_AUTO, SOUND_SPRAY);
			RemoveEntity(entity);
			g_iDropped[i][0] = 0;
		}

		entity = g_iDropped[i][1];
		if( IsValidEntRef(entity) )
		{
			RemoveEntity(entity);
			g_iDropped[i][1] = 0;
		}

		entity = g_iSpawned[i][0];
		if( IsValidEntRef(entity) )
		{
			StopSound(entity, SNDCHAN_AUTO, SOUND_SPRAY);
			RemoveEntity(entity);
			g_iSpawned[i][0] = 0;
		}

		entity = g_iSpawned[i][1];
		if( IsValidEntRef(entity) )
		{
			RemoveEntity(entity);
			g_iSpawned[i][1] = 0;
		}
	}
}



// ====================================================================================================
//					STUFF
// ====================================================================================================
// Returns if the player has a valid weapon or not. Valid entity ID on success, 0 on failure, 1 on melee weapons.
int HasWeapon(int client, int weapon, bool test = false)
{
	if( weapon == -1 || g_iGunSlot[client] == SLOT_TEMP_SEC )
		return 0;

	if( g_iCvarCheck == 0 && g_sCvarWeapon[0] == 0 )
	{
		if( g_iGunSlot[client] != SLOT_PRIMARY && g_iGunSlot[client] != SLOT_CURRENT_PRI )
		{
			if( GetPlayerWeaponSlot(client, 1) == weapon )
			{
				if( g_bLeft4Dead2 )
				{
					char sTemp[16];
					GetEdictClassname(weapon, sTemp, sizeof(sTemp));
					if( strcmp(sTemp[7], "melee") == 0 || strcmp(sTemp[7], "chainsaw") == 0 )
					{
						if( test )
							return 1;
					}
					else
						return weapon;
				}
				else
					return weapon;
			}
		}
		else
		{
			if( GetPlayerWeaponSlot(client, 0) == weapon )
				return weapon;
		}
		return 0;
	}

	char sWeapon[32];
	int entity;

	for( int i = 0; i < 2; i++ )
	{
		entity = GetPlayerWeaponSlot(client, i);
		if( entity != -1 )
		{
			GetEdictClassname(entity, sWeapon, sizeof(sWeapon));
			if( strcmp(sWeapon, g_sCvarWeapon) == 0 )
				return entity;
		}
	}

	return 0;
}

int GetSurvivorType(int client)
{
	if( !g_bLeft4Dead2 )
		return 1; // All models should use the "louis" position, since L4D1 models have no weapon_bone attachment.

	char sModel[32];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	switch( sModel[29] )
	{
		case 'n':		return 1;		// n = Teenangst
		case 'e':		return 1;		// e = Francis
		case 'a':		return 1;		// a = Louis
		case 'c':		return 1;		// c = Coach
		default:		return 0;
	}
}

int GetRandomType(int iType)
{
	if( g_iCvarCombo ) return 1;

	int iCount, iArray[4];
	if( iType & ENUM_EXTINGUISHER )		iArray[iCount++] = 1;
	if( iType & ENUM_FLAMETHROWER )		iArray[iCount++] = 2;
	if( iType & ENUM_FREEZERSPRAY )		iArray[iCount++] = 3;
	if( iType & ENUM_BLASTPUSHBACK )	iArray[iCount++] = 4;
	return iArray[GetRandomInt(0, iCount -1)];
}

void OnFrameZoom(int client)
{
	client = GetClientOfUserId(client);
	if( client )
	{
		g_iZoomed[client] = 0;
		UnzoomWeapon(client);
	}
}

void UnzoomWeapon(int client)
{
	SetEntPropEnt(client, Prop_Send, "m_hZoomOwner", -1);
	SetEntPropFloat(client, Prop_Send, "m_flFOVTime", 0.0);
	SetEntPropFloat(client, Prop_Send, "m_flFOVRate", 0.0);
	SetEntProp(client, Prop_Send, "m_iFOV", 0);
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

void CPrintToChat(int client, char[] message, any ...)
{
	static char buffer[256];
	VFormat(buffer, sizeof(buffer), message, 3);

	ReplaceString(buffer, sizeof(buffer), "{default}",		"\x01");
	ReplaceString(buffer, sizeof(buffer), "{white}",		"\x01");
	ReplaceString(buffer, sizeof(buffer), "{cyan}",			"\x03");
	ReplaceString(buffer, sizeof(buffer), "{lightgreen}",	"\x03");
	ReplaceString(buffer, sizeof(buffer), "{orange}",		"\x04");
	ReplaceString(buffer, sizeof(buffer), "{green}",		"\x04"); // Actually orange in L4D2, but replicating colors.inc behaviour
	ReplaceString(buffer, sizeof(buffer), "{olive}",		"\x05");

	PrintToChat(client, buffer);
}



// ====================================================================================================
//					POSITION STUFF
// ====================================================================================================
void MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}

bool SetTeleportEndPoint(int client, float vPos[3], float vAng[3])
{
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, FilterExcludeSelf, client);

	if( TR_DidHit(trace) )
	{
		float vNorm[3];
		TR_GetEndPosition(vPos, trace);
		TR_GetPlaneNormal(trace, vNorm);
		GetVectorAngles(vNorm, vAng);
		if( vNorm[2] == 1.0 )
		{
			vAng[0] = 0.0;
			vAng[1] += 180.0;
		}
		else
		{
			vPos[2] += 1.0;
		}
	}
	else
	{
		delete trace;
		return false;
	}

	delete trace;
	return true;
}

bool FilterExcludeSelf(int entity, int contentsMask, int client)
{
	if( entity == client )
		return false;
	return true;
}