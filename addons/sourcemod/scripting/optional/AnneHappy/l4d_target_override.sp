/*
*	Target Override
*	Copyright (C) 2022 Silvers
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



#define PLUGIN_VERSION 		"2.24"
#define DEBUG_BENCHMARK		0			// 0=Off. 1=Benchmark only (for command). 2=Benchmark (displays on server). 3=PrintToServer various data.

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Target Override
*	Author	:	SilverShot
*	Descrp	:	Overrides Special Infected targeting of Survivors.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=322311
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

2.24 (24-Nov-2022)
	- Fixed plugin not accounting for idle or disconnected players being replaced by bots. Thanks to "HarryPotter" for help.

2.23 (28-Oct-2022)
	- Fixed Special Infected not being able to target other SI. Tank vs SI is still not capable. Thanks to "Tonblader" for reporting.
	- Fixed the "voms" and "voms2" options not working correctly.
	- Plugin now prevents the Tank attempting to attack vomited Special Infected, since the Tank will just stand there.

2.22 (20-Oct-2022)
	- Fixed various issues with the "pinned" option breaking targeting. Thanks to "morzlee" for reporting and lots of help testing.

2.21 (08-Oct-2022)
	- Added option "15" to target the Survivor furthest behind in flow distance. Requested by "gabuch2"
	- Added option "16" to target a Survivor with their flashlight on. Requested by "gabuch2"
	- Added option "17" to target a Survivor who is running (not crouched or walking). Requested by "gabuch2"

	- Added new include file for 3rd party plugins to use the forward and natives.
	- Added natives "L4D_TargetOverride_GetOption" and "L4D_TargetOverride_SetOption" for 3rd party plugins to get or set some option values. Requested by "morzlee".
	- Added native "L4D_TargetOverride_GetValue" for 3rd party plugins to get or set client values. Requested by "morzlee".
	- Added forward "L4D_OnTargetOverride" for 3rd party plugins to trigger every frame or whenever someone is being targeted. Requested by "morzlee".
	- Added cvar "l4d_target_override_forward" to enable or disabled the forward. Disabled by default to save CPU cycles.

	- Changed "targeted" option to use the set value as a maximum number of Special Infected allowed to target someone. Requested by "morzlee".
	- Fixed option "14" not working in L4D1. Thanks to "axelnieves2012" for fixing.
	- Increased string buffer and maximum orders in case all options are used in a single "order" data key value string.

2.20 (03-Oct-2022)
	- Added option "14" to target someone healing whose health is below "survivor_limp_health" cvar value. Added by "axelnieves2012".
	- Fixed order "12" and "13" being switched. Thanks to "axelnieves2012" for reporting.

2.19 (22-Sep-2022)
	- Added option "13" to "order" to target the Survivor furthest ahead in flow distance. Requested by "axelnieves2012".
	- Added option "targeted" to the data config to prevent targeting someone that's already targeted by another Special Infected. Requested by "axelnieves2012".

2.18 (10-Aug-2022)
	- Added cvar "l4d_target_override_team" to specify which Survivor teams can be targeted.
	- Added option "dist" to the data config to set how close the Special Infected must be to a target to prevent changing target.
	- Added option "time" to the data config to set the duration of targeting the last attacker before being allowed to change target.
	- Fixed the wait time and last attacker interfering with selecting a new target. Thanks to "moschinovac" for reporting.

2.17 (30-Jul-2022)
	- Added option "12" to "order" to target the Survivor furthest ahead in flow distance. Requested by "yzybb".

2.16 (09-Sep-2021)
	- Fixed not reading the entire data configs "order" value when the string was longer than 15 characters.

2.15a (09-Jul-2021)
	- L4D2: Fixed GameData file from the "2.2.2.0" game update.

2.15 (06-Jul-2021)
	- Limited the patch from last update to L4D2 only.

2.14 (03-Jul-2021)
	- L4D2: Fixed plugin not ignoring players using a minigun. Thanks to "ProjectSky" for reporting.
	- L4D2: GameData .txt file updated.

2.13 (04-Jun-2021)
	- Fixed the plugin not working without the optional "Left 4 DHooks Direct" plugin being installed. Thanks to "spaghettipastaman" for reporting.

2.12 (20-Apr-2021)
	- Changed cvar "l4d_target_override_type" adding type "3" to order range by nav flow distance.
	- This requires the "Left4DHooks" plugin and used only when the plugin is detected. Maybe unreliable due to unreachable flow areas.

	- Fixed "Highest Health" and "Highest Health" orders not validating the clients correctly, Thanks to "larrybrains" for reporting.
	- Fixed "Highest Health" and "Highest Health" config orders description being flipped.

2.11 (12-Apr-2021)
	- Added priority order option "11" to target players using a Mini Gun.

2.10 (15-Feb-2021)
	- Added option "safe" to control if Survivors can be attacked when in a saferoom. Requested by "axelnieves2012".

2.9 (18-Sep-2020)
	- Added option "range" to set how near a Survivor must be to target. Defaults to 0.0 for no range check.
	- Added option "voms2" to control if Survivors can be attacked when incapacitated and vomited.
	- Data config "data/l4d_target_override.cfg" updated to reflect changes.
	- Thanks to "XDglory" for requesting and testing.

2.8 (17-May-2020)
	- Fixed "normal" order test affecting ledge hanging players. Thanks to "tRololo312312" for reporting.
	- Optimized the order test loop by exiting when order is 0, unavailable.

2.7 (15-May-2020)
	- Fixed not resetting variables on clients spawning causing issues e.g. thinking someone's ledge hanging.
	- Thanks to "tRololo312312" for reporting.

2.6 (10-May-2020)
	- Added option "8" to "order" to choose targeting the survivor with highest health.
	- Added option "9" to "order" to choose targeting the survivor with lowest health.
	- Added option "10" to "order" to choose targeting a survivor being Pummelled by the Charger (L4D2 only).
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Fixed "incap" option not working correctly. Thanks to "login101" for reporting.
	- Fixed not resetting the last attacker on special infected spawning.
	- Gamedata changed to wildcard first few bytes due to Left4DHooks using as a detour.

2.5 (07-Apr-2020)
	- Added cvar "l4d_target_override_type" to select which method to search for survivors.
	- Fixed "Invalid index 0" when no valid targets are available. Thanks to "tRololo312312".

2.4 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

2.3 (26-Mar-2020)
	- Added option "last" to the config to enable targeting the last attacker using order value 7.
	- Added option "7" to "order" to choose targeting the last attacker.
	- This option won't change target if one is already very close (250 units).
	- Thanks to "xZk" for requesting.

2.2 (24-Mar-2020)
	- Fixed memory leak. Thanks to "sorallll" for reporting. Thanks to "Lux" for adding the fix.

2.1 (23-Mar-2020)
	- Fixed only using the first 5 priority order values and never checking the 6th when the first 5 fail.

2.0 (23-Mar-2020)
	- Initial Release.

	- Combined L4D1 and L4D2 versions into 1 plugin.
	- Major changes to how the plugin works.
	- Now has a data config to choose preferences for each Special Infected.

	- Renamed plugin (delete the old .smx - added check to prevent duplicate plugins).
	- Removed cvar "l4d2_target_patch_special", now part part of data config settings.
	- Removed cvar "l4d2_target_patch_targets", now part part of data config settings.
	- Removed cvar "l4d2_target_patch_wait", now part part of data config settings.
	- Removed cvar "l4d2_target_patch_incap", now part part of data config settings.
	- Removed cvar "l4d_target_patch_incap", now part part of data config settings.

1.5 (17-Jan-2020)
	- Added cvar "l4d2_target_patch_incap" to control the following:
	1. Only target vomited and incapacitated players. - Requested by "ReCreator".
	2. Only target incapacitated when everyone is incapacitated. - Requested by "Mr. Man".

1.4 (14-Jan-2020)
	- Fixed not actually using the GetClientsInRange array. Thanks to "Peace-Maker" for reporting.

1.3 (14-Jan-2020)
	- Added cvar "l4d2_target_patch_wait" to delay between switching targets unless current target is invalid.
	- Now using "GetClientsInRange" to select potentially visible clients. Thanks to "Peace-Maker" for recommending.

1.2 (13-Jan-2020)
	- Added cvar "l4d2_target_patch_targets" to control which Special Infected cannot target incapped survivors.
	- If used, this will change those specific Special Infected to target the nearest non-incapped survivor.

1.1 (13-Jan-2020)
	- Fixed mistake causing error with "m_isHangingFromLedge".

1.0 (13-Jan-2020)
	- Initial release.

=========================
*	L4D1 - Target Patch:
=========================

1.2 (16-Jan-2020)
	- Added cvar "l4d_target_patch_incap" to control the following:
	1. Only target vomited and incapacitated players. - Requested by "ReCreator".
	2. Only target incapacitated when everyone is incapacitated. - Requested by "Mr. Man".

1.1 (14-Jan-2020)
	- Fixed invalid entity. Thanks to "Venom1777" for reporting.

1.0 (13-Jan-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>
#include <l4d_target_override>

// Left4DHooks natives - optional - (added here to avoid requiring Left4DHooks include)
native float L4D2Direct_GetFlowDistance(int client);
native Address L4D2Direct_GetTerrorNavArea(const float pos[3], float beneathLimit = 120.0);
native float L4D2Direct_GetTerrorNavAreaFlow(Address pTerrorNavArea);
native int L4D_GetHighestFlowSurvivor();



#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
#include <profiler>
Handle g_Prof;
float g_fBenchMin;
float g_fBenchMax;
float g_fBenchAvg;
float g_iBenchTicks;
#endif


#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"l4d_target_override"
#define CONFIG_DATA			"data/l4d_target_override.cfg"

ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarForward, g_hCvarSpecials, g_hCvarTeam, g_hCvarType, g_hDecayDecay, g_hCvarLimp;
bool g_bCvarAllow, g_bMapStarted, g_bLateLoad, g_bLeft4Dead2, g_bLeft4DHooks, g_bCvarForward;
int g_iCvarSpecials, g_iCvarTeam, g_iCvarType, g_iClassTank;
float g_fDecayDecay, g_fCvarLimp;
Handle g_hDetour, g_hForward;

ArrayList g_BytesSaved;
Address g_iFixOffset;
int g_iFixCount, g_iFixMatch;



#define MAX_BUFFER		48		// Maximum buffer size when exploding the "order" string "0,0,0"
#define MAX_ORDERS		17		// Maximum number of "order"'s
int g_iOrderTank[MAX_ORDERS];
int g_iOrderSmoker[MAX_ORDERS];
int g_iOrderBoomer[MAX_ORDERS];
int g_iOrderHunter[MAX_ORDERS];
int g_iOrderSpitter[MAX_ORDERS];
int g_iOrderJockeys[MAX_ORDERS];
int g_iOrderCharger[MAX_ORDERS];

#define MAX_SPECIAL		7
int g_iOptionLast[MAX_SPECIAL];
int g_iOptionPinned[MAX_SPECIAL];
int g_iOptionIncap[MAX_SPECIAL];
int g_iOptionVoms[MAX_SPECIAL];
int g_iOptionVoms2[MAX_SPECIAL];
int g_iOptionSafe[MAX_SPECIAL];
int g_iOptionTarg[MAX_SPECIAL];
float g_fOptionRange[MAX_SPECIAL];
float g_fOptionDist[MAX_SPECIAL];
float g_fOptionLast[MAX_SPECIAL];
float g_fOptionWait[MAX_SPECIAL];

#define MAX_PLAY		MAXPLAYERS+1
float g_fLastSwitch[MAX_PLAY];
float g_fLastAttack[MAX_PLAY];
int g_iLastAttacker[MAX_PLAY];
int g_iLastOrders[MAX_PLAY];
int g_iLastVictim[MAX_PLAY];
bool g_bIncapped[MAX_PLAY];
bool g_bLedgeGrab[MAX_PLAY];
bool g_bPinBoomer[MAX_PLAY];
bool g_bPinSmoker[MAX_PLAY];
bool g_bPinHunter[MAX_PLAY];
bool g_bPinJockey[MAX_PLAY];
bool g_bPinCharger[MAX_PLAY];
bool g_bPumCharger[MAX_PLAY];
bool g_bCheckpoint[MAX_PLAY];

enum
{
	INDEX_TARG_DIST,
	INDEX_TARG_VIC,
	INDEX_TARG_TEAM
}

enum
{
	INDEX_TANK		= 0,
	INDEX_SMOKER	= 1,
	INDEX_BOOMER	= 2,
	INDEX_HUNTER	= 3,
	INDEX_SPITTER	= 4,
	INDEX_JOCKEY	= 5,
	INDEX_CHARGER	= 6
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Target Override",
	author = "SilverShot",
	description = "Overrides Special Infected targeting of Survivors.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=322311"
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

	MarkNativeAsOptional("L4D2Direct_GetFlowDistance");
	MarkNativeAsOptional("L4D2Direct_GetTerrorNavArea");
	MarkNativeAsOptional("L4D2Direct_GetTerrorNavAreaFlow");
	MarkNativeAsOptional("L4D_GetHighestFlowSurvivor");

	CreateNative("L4D_TargetOverride_GetValue", Native_GetValue);
	CreateNative("L4D_TargetOverride_GetOption", Native_GetOption);
	CreateNative("L4D_TargetOverride_SetOption", Native_SetOption);

	g_hForward = CreateGlobalForward("L4D_OnTargetOverride", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);

	RegPluginLibrary("l4d_target_override");

	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnLibraryAdded(const char[] sName)
{
	if( strcmp(sName, "left4dhooks") == 0 )
		g_bLeft4DHooks = true;
}

public void OnLibraryRemoved(const char[] sName)
{
	if( strcmp(sName, "left4dhooks") == 0 )
		g_bLeft4DHooks = false;
}

public void OnAllPluginsLoaded()
{
	// =========================
	// PREVENT OLD PLUGIN
	// =========================
	if( FindConVar(g_bLeft4Dead2 ? "l4d2_target_patch_version" : "l4d_target_patch_version") != null )
		SetFailState("Error: Old plugin \"%s\" detected. This plugin supersedes the old version, delete it and restart server.", g_bLeft4Dead2 ? "l4d2_target_patch" : "l4d_target_patch");
}

public void OnPluginStart()
{
	g_iClassTank = g_bLeft4Dead2 ? 8 : 5;

	// =========================
	// GAMEDATA
	// =========================
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	// Detour
	g_hDetour = DHookCreateFromConf(hGameData, "BossZombiePlayerBot::ChooseVictim");

	if( !g_hDetour ) SetFailState("Failed to find \"BossZombiePlayerBot::ChooseVictim\" signature.");



	// =========================
	// PATCH - Remove ignoring players using mini gun
	// =========================
	if( g_bLeft4Dead2 )
	{
		g_iFixOffset = GameConfGetAddress(hGameData, "TankAttack::Update");
		if( !g_iFixOffset ) SetFailState("Failed to find \"TankAttack::Update\" signature.");

		int offs = GameConfGetOffset(hGameData, "TankAttack__Update_Offset");
		if( offs == -1 ) SetFailState("Failed to load \"TankAttack__Update_Offset\" offset.");

		g_iFixOffset += view_as<Address>(offs);

		g_iFixCount = GameConfGetOffset(hGameData, "TankAttack__Update_Count");
		if( g_iFixCount == -1 ) SetFailState("Failed to load \"TankAttack__Update_Count\" offset.");

		g_iFixMatch = GameConfGetOffset(hGameData, "TankAttack__Update_Match");
		if( g_iFixMatch == -1 ) SetFailState("Failed to load \"TankAttack__Update_Match\" offset.");

		g_BytesSaved = new ArrayList();

		for( int i = 0; i < g_iFixCount; i++ )
		{
			g_BytesSaved.Push(LoadFromAddress(g_iFixOffset + view_as<Address>(i), NumberType_Int8));
		}

		if( g_BytesSaved.Get(0) != g_iFixMatch ) SetFailState("Failed to load, byte mis-match @ %d (0x%02X != 0x%02X)", offs, g_BytesSaved.Get(0), g_iFixMatch);
	}

	delete hGameData;



	// =========================
	// CVARS
	// =========================
	g_hCvarAllow =			CreateConVar(	"l4d_target_override_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_target_override_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_target_override_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_target_override_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarForward =		CreateConVar(	"l4d_target_override_forward",			"0",				"0=Off. 1=On. Forward used for 3rd party plugins when someone is being targeted, triggers every frame or so.", CVAR_FLAGS );
	if( g_bLeft4Dead2 )
		g_hCvarSpecials =	CreateConVar(	"l4d_target_override_specials",			"127",				"Override these Specials target function: 1=Smoker, 2=Boomer, 4=Hunter, 8=Spitter, 16=Jockey, 32=Charger, 64=Tank. 127=All. Add numbers together.", CVAR_FLAGS );
	else
		g_hCvarSpecials =	CreateConVar(	"l4d_target_override_specials",			"15",				"Override these Specials target function: 1=Smoker, 2=Boomer, 4=Hunter, 8=Tank. 15=All. Add numbers together.", CVAR_FLAGS );
	g_hCvarTeam =			CreateConVar(	"l4d_target_override_team",				"2",				"Which Survivor teams should be targeted. 2=Default Survivors. 4=Holdout and Passing bots. 6=Both.", CVAR_FLAGS );
	g_hCvarType =			CreateConVar(	"l4d_target_override_type",				"1",				"How should the plugin search through Survivors. 1=Nearest visible (defaults to games method on fail). 2=All Survivors from the nearest. 3=Nearest by flow distance (requires Left4DHooks plugin, defaults to type 2).", CVAR_FLAGS );
	CreateConVar(							"l4d_target_override_version",			PLUGIN_VERSION,		"Target Override plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_target_override");

	g_hCvarLimp = FindConVar("survivor_limp_health");
	g_hDecayDecay = FindConVar("pain_pills_decay_rate");
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarForward.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpecials.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTeam.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarType.AddChangeHook(ConVarChanged_Cvars);
	g_hDecayDecay.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLimp.AddChangeHook(ConVarChanged_Cvars);



	// =========================
	// COMMANDS
	// =========================
	RegAdminCmd("sm_to_reload",		CmdReload,	ADMFLAG_ROOT, "Reloads the data config.");

	#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
	RegAdminCmd("sm_to_stats",		CmdStats,	ADMFLAG_ROOT, "Displays benchmarking stats (min/avg/max).");
	#endif



	// =========================
	// LATELOAD
	// =========================
	if( g_bLateLoad )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && IsPlayerAlive(i) )
			{
				g_bIncapped[i]			= GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) == 1;
				g_bLedgeGrab[i]			= GetEntProp(i, Prop_Send, "m_isHangingFromLedge", 1) == 1;
				g_bPinSmoker[i]			= GetEntPropEnt(i, Prop_Send, "m_tongueOwner") > 0;
				g_bPinHunter[i]			= GetEntPropEnt(i, Prop_Send, "m_pounceAttacker") > 0;
				if( g_bLeft4Dead2 )
				{
					g_bPinJockey[i]		= GetEntPropEnt(i, Prop_Send, "m_jockeyAttacker") > 0;
					g_bPinCharger[i]	= GetEntPropEnt(i, Prop_Send, "m_pummelAttacker") > 0;
					g_bPumCharger[i] = g_bPinCharger[i];
				}
				// g_bPinBoomer[i]		= Unvomit/Left4DHooks method could solve this, but only required for lateload - cba.
			}
		}
	}

	#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
	g_Prof = CreateProfiler();
	#endif
}

public void OnPluginEnd()
{
	DetourAddress(false);
	PatchAddress(false);
}



// ====================================================================================================
//					LOAD DATA CONFIG
// ====================================================================================================
#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
Action CmdStats(int client, int args)
{
	ReplyToCommand(client, "Target Override: Stats: Min %f. Avg %f. Max %f", g_fBenchMin, g_fBenchAvg / g_iBenchTicks, g_fBenchMax);
	return Plugin_Handled;
}
#endif

Action CmdReload(int client, int args)
{
	OnMapStart();
	ReplyToCommand(client, "Target Override: Data config reloaded.");
	return Plugin_Handled;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void OnMapStart()
{
	g_bMapStarted = true;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_DATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	// Load config
	KeyValues hFile = new KeyValues("target_patch");
	if( !hFile.ImportFromFile(sPath) )
	{
		SetFailState("Error loading file: \"%s\". Try replacing the file with the original.", sPath);
	}

	ExplodeToArray("tank",			hFile,	INDEX_TANK,		g_iOrderTank);
	ExplodeToArray("smoker",		hFile,	INDEX_SMOKER,	g_iOrderSmoker);
	ExplodeToArray("boomer",		hFile,	INDEX_BOOMER,	g_iOrderBoomer);
	ExplodeToArray("hunter",		hFile,	INDEX_HUNTER,	g_iOrderHunter);
	if( g_bLeft4Dead2 )
	{
		ExplodeToArray("spitter",	hFile,	INDEX_SPITTER,	g_iOrderSpitter);
		ExplodeToArray("jockey",	hFile,	INDEX_JOCKEY,	g_iOrderJockeys);
		ExplodeToArray("charger",	hFile,	INDEX_CHARGER,	g_iOrderCharger);
	}

	delete hFile;
}

void ExplodeToArray(char[] key, KeyValues hFile, int index, int arr[MAX_ORDERS])
{
	if( hFile.JumpToKey(key) )
	{
		char buffer[MAX_BUFFER];
		char buffers[MAX_ORDERS][3];

		hFile.GetString("order", buffer, sizeof(buffer), "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0");
		ExplodeString(buffer, ",", buffers, MAX_ORDERS, sizeof(buffers[]));

		for( int i = 0; i < MAX_ORDERS; i++ )
		{
			arr[i] = StringToInt(buffers[i]);
		}

		g_iOptionPinned[index] = hFile.GetNum("pinned");
		g_iOptionIncap[index] = hFile.GetNum("incap");
		g_iOptionVoms[index] = hFile.GetNum("voms");
		g_iOptionVoms2[index] = hFile.GetNum("voms2");
		g_fOptionRange[index] = hFile.GetFloat("range");
		g_fOptionDist[index] = hFile.GetFloat("dist");
		g_fOptionWait[index] = hFile.GetFloat("wait");
		g_iOptionLast[index] = hFile.GetNum("last");
		g_fOptionLast[index] = hFile.GetFloat("time");
		g_iOptionSafe[index] = hFile.GetNum("safe");
		g_iOptionTarg[index] = hFile.GetNum("targeted");
		hFile.Rewind();
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

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_fDecayDecay =		g_hDecayDecay.FloatValue;
	g_fCvarLimp =		g_hCvarLimp.FloatValue;
	g_bCvarForward =	g_hCvarForward.BoolValue;
	g_iCvarSpecials =	g_hCvarSpecials.IntValue;
	g_iCvarTeam =		g_hCvarTeam.IntValue;
	g_iCvarType =		g_hCvarType.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		HookPlayerHurt(true);

		HookEvent("player_spawn",						Event_PlayerSpawn);
		HookEvent("player_death",						Event_PlayerDeath);
		HookEvent("round_start",						Event_RoundStart);
		HookEvent("revive_success",						Event_ReviveSuccess);	// Revived
		HookEvent("player_incapacitated",				Event_Incapacitated);
		HookEvent("player_ledge_grab",					Event_LedgeGrab);		// Ledge
		HookEvent("player_now_it",						Event_BoomerStart);		// Boomer
		HookEvent("player_no_longer_it",				Event_BoomerEnd);
		HookEvent("lunge_pounce",						Event_HunterStart);		// Hunter
		HookEvent("pounce_end",							Event_HunterEnd);
		HookEvent("tongue_grab",						Event_SmokerStart);		// Smoker
		HookEvent("tongue_release",						Event_SmokerEnd);
		HookEvent("player_left_checkpoint",				Event_LeftCheckpoint);
		HookEvent("player_entered_checkpoint",			Event_EnteredCheckpoint);
		HookEvent("player_bot_replace",					Event_PlayerReplace);
		HookEvent("bot_player_replace",					Event_BotReplace);

		if( g_bLeft4Dead2 )
		{
			HookEvent("jockey_ride",					Event_JockeyStart);		// Jockey
			HookEvent("jockey_ride_end",				Event_JockeyEnd);
			HookEvent("charger_pummel_start",			Event_ChargerPummel);	// Charger
			HookEvent("charger_carry_start",			Event_ChargerStart);
			HookEvent("charger_carry_end",				Event_ChargerEnd);
			HookEvent("charger_pummel_end",				Event_ChargerEnd);
			HookEvent("player_entered_start_area",		Event_EnteredCheckpoint);
		}

		DetourAddress(true);
		PatchAddress(true);
		g_bCvarAllow = true;
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		HookPlayerHurt(false);

		UnhookEvent("player_spawn",						Event_PlayerSpawn);
		UnhookEvent("player_death",						Event_PlayerDeath);
		UnhookEvent("round_start",						Event_RoundStart);
		UnhookEvent("revive_success",					Event_ReviveSuccess);	// Revived
		UnhookEvent("player_incapacitated",				Event_Incapacitated);
		UnhookEvent("player_ledge_grab",				Event_LedgeGrab);		// Ledge
		UnhookEvent("player_now_it",					Event_BoomerStart);		// Boomer
		UnhookEvent("player_no_longer_it",				Event_BoomerEnd);
		UnhookEvent("lunge_pounce",						Event_HunterStart);		// Hunter
		UnhookEvent("pounce_end",						Event_HunterEnd);
		UnhookEvent("tongue_grab",						Event_SmokerStart);		// Smoker
		UnhookEvent("tongue_release",					Event_SmokerEnd);
		UnhookEvent("player_left_checkpoint",			Event_LeftCheckpoint);
		UnhookEvent("player_entered_checkpoint",		Event_EnteredCheckpoint);
		UnhookEvent("player_bot_replace",				Event_PlayerReplace);
		UnhookEvent("bot_player_replace",				Event_BotReplace);

		if( g_bLeft4Dead2 )
		{
			UnhookEvent("jockey_ride",					Event_JockeyStart);		// Jockey
			UnhookEvent("jockey_ride_end",				Event_JockeyEnd);
			UnhookEvent("charger_pummel_start",			Event_ChargerPummel);	// Charger
			UnhookEvent("charger_carry_start",			Event_ChargerStart);
			UnhookEvent("charger_carry_end",			Event_ChargerEnd);
			UnhookEvent("charger_pummel_end",			Event_ChargerEnd);
			UnhookEvent("player_entered_start_area",	Event_EnteredCheckpoint);
		}

		DetourAddress(false);
		PatchAddress(false);
		g_bCvarAllow = false;
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



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void OnClientDisconnect(int client)
{
	// Remove disconnected client from being targeted
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( g_iLastVictim[i] == client )
		{
			g_iLastVictim[i] = 0;
		}
	}
}

void Event_EnteredCheckpoint(Event event, const char[] name, bool dontBroadcast)
{
	g_bCheckpoint[GetClientOfUserId(event.GetInt("userid"))] = true;
}

void Event_LeftCheckpoint(Event event, const char[] name, bool dontBroadcast)
{
	g_bCheckpoint[GetClientOfUserId(event.GetInt("userid"))] = false;
}

void Event_PlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));
	int player = GetClientOfUserId(GetEventInt(event, "player"));

	g_bCheckpoint[bot]	= g_bCheckpoint[player];
	g_bIncapped[bot] 	= g_bIncapped[player];
	g_bLedgeGrab[bot]	= g_bLedgeGrab[player];
	g_bPinSmoker[bot]	= g_bPinSmoker[player];
	g_bPinHunter[bot]	= g_bPinHunter[player];
	if( g_bLeft4Dead2 )
	{
		g_bPinJockey[bot]	= g_bPinJockey[player];
		g_bPinCharger[bot]	= g_bPinCharger[player];
		g_bPumCharger[bot]	= g_bPumCharger[player];
	}
}

void Event_BotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));
	int player = GetClientOfUserId(GetEventInt(event, "player"));

	g_bCheckpoint[player]	= g_bCheckpoint[bot];
	g_bIncapped[player] 	= g_bIncapped[bot];
	g_bLedgeGrab[player]	= g_bLedgeGrab[bot];
	g_bPinSmoker[player]	= g_bPinSmoker[bot];
	g_bPinHunter[player]	= g_bPinHunter[bot];
	if( g_bLeft4Dead2 )
	{
		g_bPinJockey[player]	= g_bPinJockey[bot];
		g_bPinCharger[player]	= g_bPinCharger[bot];
		g_bPumCharger[player]	= g_bPumCharger[bot];
	}
}

void HookPlayerHurt(bool doHook)
{
	// Hook player_hurt for order type 7 - target last attacker.
	bool hook;
	for( int i = 0; i < MAX_SPECIAL; i++ )
	{
		if( g_iOptionLast[i] )
		{
			hook = true;
			break;
		}
	}

	static bool bHookedHurt;

	if( doHook && hook && !bHookedHurt )
	{
		bHookedHurt = true;
		HookEvent("player_hurt",		Event_PlayerHurt);
	}
	else if( (!doHook || !hook) && bHookedHurt )
	{
		bHookedHurt = false;
		UnhookEvent("player_hurt",		Event_PlayerHurt);
	}
}

void ResetVars(int client)
{
	g_iLastAttacker[client] = 0;
	g_iLastOrders[client] = 0;
	g_iLastVictim[client] = 0;
	g_fLastSwitch[client] = 0.0;
	g_fLastAttack[client] = 0.0;
	g_bIncapped[client] = false;
	g_bLedgeGrab[client] = false;
	g_bPinBoomer[client] = false;
	g_bPinSmoker[client] = false;
	g_bPinHunter[client] = false;
	g_bPinJockey[client] = false;
	g_bPinCharger[client] = false;
	g_bPumCharger[client] = false;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 0; i <= MaxClients; i++ )
	{
		ResetVars(i);

		if( i && IsClientInGame(i) && ValidateTeam(i) == 2 )
			g_bCheckpoint[i] = true;
		else
			g_bCheckpoint[i] = false;
	}
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	ResetVars(client);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	g_iLastVictim[client] = 0;

	if( client )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( g_iLastVictim[i] == client )
			{
				g_iLastVictim[i] = 0;
			}
		}
	}
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = event.GetInt("attacker");
	if( attacker )
	{
		int type = event.GetInt("type");

		if( type & (DMG_BULLET|DMG_SLASH|DMG_CLUB) )
		{
			g_iLastAttacker[client] = attacker;
			g_fLastAttack[client] = GetGameTime();
		}
	}
}

void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	g_bIncapped[client] = false;
	g_bLedgeGrab[client] = false;
}

void Event_Incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bIncapped[client] = true;
}

void Event_LedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bLedgeGrab[client] = true;
}

void Event_SmokerStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinSmoker[client] = true;
}

void Event_SmokerEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinSmoker[client] = false;
}

void Event_BoomerStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bPinBoomer[client] = true;
}

void Event_BoomerEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bPinBoomer[client] = false;
}

void Event_HunterStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinHunter[client] = true;
}

void Event_HunterEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinHunter[client] = false;
}

void Event_JockeyStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinJockey[client] = true;
}

void Event_JockeyEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinJockey[client] = false;
}

void Event_ChargerPummel(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPumCharger[client] = true;
	g_bPinCharger[client] = true;
}

void Event_ChargerStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinCharger[client] = true;
}

void Event_ChargerEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinCharger[client] = false;
	g_bPumCharger[client] = false;
}



// ====================================================================================================
//					PATCH + DETOUR
// ====================================================================================================
void PatchAddress(bool patch)
{
	if( !g_bLeft4Dead2 ) return;

	static bool patched;

	if( !patched && patch )
	{
		patched = true;

		for( int i = 0; i < g_iFixCount; i++ )
		{
			StoreToAddress(g_iFixOffset + view_as<Address>(i), 0x90, NumberType_Int8);
		}
	}
	else if( patched && !patch )
	{
		patched = false;

		for( int i = 0; i < g_iFixCount; i++ )
		{
			StoreToAddress(g_iFixOffset + view_as<Address>(i), g_BytesSaved.Get(i), NumberType_Int8);
		}
	}
}

void DetourAddress(bool patch)
{
	static bool patched;

	if( !patched && patch )
	{
		if( !DHookEnableDetour(g_hDetour, false, ChooseVictim) )
			SetFailState("Failed to detour \"BossZombiePlayerBot::ChooseVictim\".");

		patched = true;
	}
	else if( patched && !patch )
	{
		if( !DHookDisableDetour(g_hDetour, false, ChooseVictim) )
			SetFailState("Failed to disable detour \"BossZombiePlayerBot::ChooseVictim\".");

		patched = false;
	}
}

MRESReturn ChooseVictim(int attacker, Handle hReturn)
{
	#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
	StartProfiling(g_Prof);
	#endif

	#if DEBUG_BENCHMARK == 3
	PrintToServer("");
	PrintToServer("");
	PrintToServer("CHOOSER {%d - \"%N\"}", attacker, attacker);
	#endif



	// =========================
	// VALIDATE SPECIAL ALLOWED CHANGE TARGET
	// =========================
	// 1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger, 5 (L4D1) / 8 (L4D2)=Tank
	int class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
	if( class == g_iClassTank ) class -= 1;
	if( g_iCvarSpecials & (1 << class - 1) == 0 )
	{
		#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
		StopProfiling(g_Prof);
		float speed = GetProfilerTime(g_Prof);
		if( speed < g_fBenchMin ) g_fBenchMin = speed;
		if( speed > g_fBenchMax ) g_fBenchMax = speed;
		g_fBenchAvg += speed;
		g_iBenchTicks++;
		#endif

		#if DEBUG_BENCHMARK == 2
		PrintToServer("ChooseVictim End 1 in %f (Min %f. Avg %f. Max %f)", speed, g_fBenchMin, g_fBenchAvg / g_iBenchTicks, g_fBenchMax);
		#endif

		return MRES_Ignored;
	}

	// Change tank class for use as index
	if( class == g_iClassTank - 1 )
	{
		class = 0;
	}



	// =========================
	// VALIDATE OLD TARGET, WAIT
	// =========================
	int newVictim;
	int lastVictim = g_iLastVictim[attacker];
	if( lastVictim )
	{
		// Player disconnected or player dead, otherwise validate last selected order still applies
		if( IsClientInGame(lastVictim) && IsPlayerAlive(lastVictim) )
		{
			#if DEBUG_BENCHMARK == 3
			PrintToServer("=== Test Last: Order: %d. newVictim {%d - \"%N\"}", g_iLastOrders[attacker], lastVictim, lastVictim);
			#endif

			newVictim = OrderTest(attacker, lastVictim, ValidateTeam(lastVictim), class, g_iLastOrders[attacker]);

			#if DEBUG_BENCHMARK == 3
			PrintToServer("=== Test Last: newVictim {%d - \"%N\"}", lastVictim, lastVictim);
			#endif
		}

		// Not reached delay time
		if( newVictim && GetGameTime() <= g_fLastSwitch[attacker] )
		{
			#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
			StopProfiling(g_Prof);
			float speed = GetProfilerTime(g_Prof);
			if( speed < g_fBenchMin ) g_fBenchMin = speed;
			if( speed > g_fBenchMax ) g_fBenchMax = speed;
			g_fBenchAvg += speed;
			g_iBenchTicks++;
			#endif

			#if DEBUG_BENCHMARK == 2
			PrintToServer("ChooseVictim End 2 in %f (Min %f. Avg %f. Max %f)", speed, g_fBenchMin, g_fBenchAvg / g_iBenchTicks, g_fBenchMax);
			#endif

			#if DEBUG_BENCHMARK == 3
			PrintToServer("=== Test Last: wait delay (%0.2f).", GetGameTime() - g_fLastSwitch[attacker]);
			#endif

			// CONTINUE OVERRIDE LAST
			Action aResult = SendForward(attacker, newVictim, g_iLastOrders[attacker]);
			if( aResult == Plugin_Handled ) return MRES_Ignored;

			DHookSetReturn(hReturn, newVictim);
			return MRES_Supercede;
		}
		else
		{
			if( newVictim && g_fOptionDist[class] )
			{
				static float vPos[3], vVec[3];
				GetClientAbsOrigin(newVictim, vPos);
				GetClientAbsOrigin(attacker, vVec);
				float dist = GetVectorDistance(vPos, vVec);

				if( dist < g_fOptionDist[class] )
				{
					#if DEBUG_BENCHMARK == 3
					PrintToServer("=== Test Dist: within %0.2f / %0.2f range to keep target.", dist, g_fOptionDist[class]);
					#endif

					g_fLastSwitch[attacker] = GetGameTime() + g_fOptionWait[class];

					// CONTINUE OVERRIDE LAST
					Action aResult = SendForward(attacker, newVictim, g_iLastOrders[attacker]);
					if( aResult == Plugin_Handled ) return MRES_Ignored;

					DHookSetReturn(hReturn, newVictim);
					return MRES_Supercede;
				}
			}

			#if DEBUG_BENCHMARK == 3
			PrintToServer("=== Test Last: wait reset.");
			#endif

			newVictim = 0;
			g_iLastOrders[attacker] = 0;
			g_iLastVictim[attacker] = 0;
			g_fLastSwitch[attacker] = 0.0;
		}
	}



	// =========================
	// FIND NEAREST SURVIVORS
	// =========================
	// Visible near
	float vPos[3];
	int targets[MAX_PLAY];
	int numClients;


	// Search method
	switch( g_iCvarType )
	{
		case 1:
		{
			GetClientEyePosition(attacker, vPos);
			numClients = GetClientsInRange(vPos, RangeType_Visibility, targets, MAX_PLAY);
		}
		case 2, 3:
		{
			GetClientAbsOrigin(attacker, vPos);
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( attacker != i && IsClientInGame(i) && IsPlayerAlive(i) )
				{
					targets[numClients++] = i;
				}
			}
		}
	}

	if( numClients == 0 )
	{
		#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
		StopProfiling(g_Prof);
		float speed = GetProfilerTime(g_Prof);
		if( speed < g_fBenchMin ) g_fBenchMin = speed;
		if( speed > g_fBenchMax ) g_fBenchMax = speed;
		g_fBenchAvg += speed;
		g_iBenchTicks++;
		#endif

		#if DEBUG_BENCHMARK == 2
		PrintToServer("ChooseVictim End 3 in %f (Min %f. Avg %f. Max %f)", speed, g_fBenchMin, g_fBenchAvg / g_iBenchTicks, g_fBenchMax);
		#endif

		return MRES_Ignored;
	}



	// =========================
	// GET DISTANCE
	// =========================
	ArrayList aTargets = new ArrayList(3);
	float vTarg[3];
	float dist;
	float flow;
	int team;
	int index;
	int total;
	int victim;

	// Check range by nav flow
	int type = g_iCvarType;
	if( type == 3 && g_bLeft4DHooks )
	{
		// Attempt to get flow distance from position and nav address
		flow = L4D2Direct_GetFlowDistance(attacker);
		if( flow == 0.0 || flow == -9999.0 ) // Invalid flows
		{
			// Failing that try backup method
			Address addy = L4D2Direct_GetTerrorNavArea(vPos);
			if( addy )
			{
				flow = L4D2Direct_GetTerrorNavAreaFlow(addy);

				if( flow == 0.0 || flow == -9999.0 ) // Invalid flows
				{
					type = 2;
				}
			} else {
				type = 2;
			}
		}
	} else {
		type = 2;
	}

	for( int i = 0; i < numClients; i++ )
	{
		victim = targets[i];

		if( victim && IsPlayerAlive(victim) )
		{
			team = ValidateTeam(victim);
			// Option "voms2" then allow attacking vomited survivors ELSE not vomited
			// Option "voms" then allow choosing team 3 when vomited
			if( (team == 2 && (g_iOptionVoms2[class] == 1 || g_bPinBoomer[victim] == false) ) ||
				(team == 3 && g_iOptionVoms[class] == 1 && g_bPinBoomer[victim] == true) )
			{
				// Saferoom test
				if( !g_iOptionSafe[class] || !g_bCheckpoint[victim] )
				{
					// Already targeted test
					if( g_iOptionTarg[class] )
					{
						total = 0;

						for( int x = 1; x <= MaxClients; x++ )
						{
							if( x != attacker && g_iLastVictim[x] == victim )
							{
								if( IsClientInGame(x) )
								{
									total++;
									if( total >= g_iOptionTarg[class] )
									{
										#if DEBUG_BENCHMARK == 3
										if( IsClientInGame(x) )
										{
											PrintToServer("{\"%N\"} is ignoring {\"%N\"} already targeted by {\"%N\"}", attacker, victim, x);
										}
										#endif

										victim = 0;
										break;
									}
								}
								else
								{
									g_iLastVictim[x] = 0;
								}
							}
						}

						if( victim == 0 ) continue;
					}

					if( type == 3 )
					{
						// Attempt to get flow distance from position and nav address
						dist = L4D2Direct_GetFlowDistance(victim);
						if( dist == 0.0 || dist == -9999.0 ) // Invalid flows
						{
							// Failing that try backup method
							GetClientAbsOrigin(victim, vTarg);
							Address addy = L4D2Direct_GetTerrorNavArea(vTarg);
							if( addy )
							{
								dist = L4D2Direct_GetTerrorNavAreaFlow(addy);

								if( dist == 0.0 || dist == -9999.0 ) // Invalid flows
								{
									dist = 999999.0;
								}
							} else {
								dist = 999999.0;
							}
						}

						if( dist != 999999.0 ) // Invalid flows
						{
							dist -= flow;
							if( dist < 0.0 ) dist *= -1.0;
						}
					}
					else
					{
						GetClientAbsOrigin(victim, vTarg);
						dist = GetVectorDistance(vPos, vTarg);
					}

					if( dist != 999999.0 && (g_fOptionRange[class] == 0.0 || dist < g_fOptionRange[class]) )
					{
						index = aTargets.Push(dist);
						aTargets.Set(index, victim, INDEX_TARG_VIC);
						aTargets.Set(index, team, INDEX_TARG_TEAM);
					}
				}
			}
		}
	}

	// Sort by nearest
	int len = aTargets.Length;
	if( len == 0 )
	{
		delete aTargets;

		#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
		StopProfiling(g_Prof);
		float speed = GetProfilerTime(g_Prof);
		if( speed < g_fBenchMin ) g_fBenchMin = speed;
		if( speed > g_fBenchMax ) g_fBenchMax = speed;
		g_fBenchAvg += speed;
		g_iBenchTicks++;
		#endif

		#if DEBUG_BENCHMARK == 2
		PrintToServer("ChooseVictim End 4 in %f (Min %f. Avg %f. Max %f)", speed, g_fBenchMin, g_fBenchAvg / g_iBenchTicks, g_fBenchMax);
		#endif

		return MRES_Ignored;
	}

	SortADTArray(aTargets, Sort_Ascending, Sort_Float);



	// =========================
	// OPTION "incap" CHECK and OPTION: "pinned"
	// =========================
	bool allPinned;
	bool allIncap;

	if( g_iOptionIncap[class] == 3 )
		allIncap = true;

	if( g_iOptionPinned[class] )
		allPinned = true;

	if( allIncap || allPinned )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && ValidateTeam(i) == 2 && IsPlayerAlive(i) )
			{
				// =========================
				// ALL INCAPPED CHECK
				// OPTION: "incap" "3"
				// =========================
				// 3=Only attack incapacitated when everyone is incapacitated.
				if( allIncap && g_bIncapped[i] == false )
				{
					allIncap = false;
				}



				// =========================
				// ALL PINNED CHECK
				// OPTION: "pinned"
				// =========================
				// Validate pinned and allowed
				// 1=Smoker. 2=Hunter. 4=Jockey. 8=Charger.
				if( allPinned )
				{
					if( g_iOptionPinned[class] & 1 && g_bPinSmoker[i] ) continue;
					if( g_iOptionPinned[class] & 2 && g_bPinHunter[i] ) continue;
					if( g_bLeft4Dead2 )
					{
						if( g_iOptionPinned[class] & 4 && g_bPinJockey[i] ) continue;
						if( g_iOptionPinned[class] & 8 && g_bPinCharger[i] ) continue;
					}

					allPinned = false;
				}
			}
		}
	}



	// =========================
	// ORDER VALIDATION
	// =========================
	// Loop through all orders progressing to the next on fail, and each time loop through all survivors from nearest to test the order preference
	int order;
	int orders;

	for( ; orders < MAX_ORDERS; orders++ )
	{
		// Found someone last order loop, exit loop
		#if DEBUG_BENCHMARK == 3
		PrintToServer("=== ORDER LOOP %d. newVictim {%d - \"%N\"}", orders + 1, newVictim, newVictim);
		#endif

		if( newVictim ) break;



		// =========================
		// OPTION: "order"
		// =========================
		switch( class )
		{
			case INDEX_TANK:		order = g_iOrderTank[orders];
			case INDEX_SMOKER:		order = g_iOrderSmoker[orders];
			case INDEX_BOOMER:		order = g_iOrderBoomer[orders];
			case INDEX_HUNTER:		order = g_iOrderHunter[orders];
			case INDEX_SPITTER:		order = g_iOrderSpitter[orders];
			case INDEX_JOCKEY:		order = g_iOrderJockeys[orders];
			case INDEX_CHARGER:		order = g_iOrderCharger[orders];
		}



		// No order
		if( order == 0 ) continue;



		// Last Attacker enabled?
		if( order == 7 && g_iOptionLast[class] == 0 ) continue;



		// =========================
		// LOOP SURVIVORS
		// =========================
		for( int i = 0; i < len; i++ )
		{
			victim = aTargets.Get(i, INDEX_TARG_VIC);



			// All incapped, target nearest
			if( allIncap )
			{
				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break allIncap");
				#endif

				newVictim = victim;
				break;
			}



			team = aTargets.Get(i, INDEX_TARG_TEAM);
			// dist = aTargets.Get(i, INDEX_TARG_DIST);



			// =========================
			// OPTION: "incap"
			// =========================
			// 0=Ignore incapacitated players.
			// 1=Allow attacking incapacitated players.
			// 2=Only attack incapacitated players when they are vomited.
			// 3=Only attack incapacitated when everyone is incapacitated.
			// 3 is already checked above.
			if( team == 2 && g_bIncapped[victim] == true )
			{
				switch( g_iOptionIncap[class] )
				{
					case 0: continue;
					case 2: if( g_bPinBoomer[victim] == false ) continue;
				}
			}



			// =========================
			// OPTION: "pinned"
			// =========================
			if( g_iOptionPinned[class] )
			{
				if( g_iOptionPinned[class] & 1 && g_bPinSmoker[victim] )
				{
					if( GetEntPropEnt(victim, Prop_Send, "m_tongueOwner") == -1 )
					{
						allPinned = false;
						g_bPinSmoker[victim] = false;
					}
					else
					{
						#if DEBUG_BENCHMARK == 3
						PrintToServer("Ignoring pinned {%d - \"%N\"} by Smoker", victim, victim);
						#endif

						continue;
					}
				}

				if( g_iOptionPinned[class] & 2 && g_bPinHunter[victim] )
				{
					if( GetEntPropEnt(victim, Prop_Send, "m_pounceAttacker") == -1 )
					{
						allPinned = false;
						g_bPinHunter[victim] = false;
					}
					else
					{
						#if DEBUG_BENCHMARK == 3
						PrintToServer("Ignoring pinned {%d - \"%N\"} by Hunter", victim, victim);
						#endif

						continue;
					}
				}

				if( g_bLeft4Dead2 )
				{
					if( g_iOptionPinned[class] & 4 && g_bPinJockey[victim] )
					{
						if( GetEntPropEnt(victim, Prop_Send, "m_jockeyAttacker") == -1 )
						{
							allPinned = false;
							g_bPinJockey[victim] = false;
						}
						else
						{
							#if DEBUG_BENCHMARK == 3
							PrintToServer("Ignoring pinned {%d - \"%N\"} by Jockey", victim, victim);
							#endif

							continue;
						}
					}

					if( g_iOptionPinned[class] & 8 && g_bPinCharger[victim] )
					{
						if( GetEntPropEnt(victim, Prop_Send, "m_carryAttacker") == -1  || GetEntPropEnt(victim, Prop_Send, "m_pummelAttacker") == -1 )
						{
							allPinned = false;
							g_bPinCharger[victim] = false;
						}
						else
						{
							#if DEBUG_BENCHMARK == 3
							PrintToServer("Ignoring pinned {%d - \"%N\"} by Charger", victim, victim);
							#endif

							continue;
						}
					}
				}
			}



			// =========================
			// OPTION: "order"
			// =========================
			newVictim = OrderTest(attacker, victim, team, class, order);

			#if DEBUG_BENCHMARK == 3
			PrintToServer("Order %d newVictim {%d - \"%N\"}", order, newVictim, newVictim);
			#endif

			if( newVictim || order == 0 ) break;
		}

		if( newVictim || order == 0 ) break;
	}



	// All pinned and not allowed to target, target self to avoid attacking pinned.
	if( allPinned )
	{
		if( g_iOptionPinned[class] )
		{
			// Verify actually pinned, seems an issue with events not resetting, maybe caused by a plugin?
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) && ValidateTeam(i) == 2 && IsPlayerAlive(i) )
				{
					if( g_iOptionPinned[class] & 1 && g_bPinSmoker[i] )
					{
						if( GetEntPropEnt(i, Prop_Send, "m_tongueOwner") == -1 )
						{
							allPinned = false;
							g_bPinSmoker[i] = false;
							break;
						}

						continue;
					}

					if( g_iOptionPinned[class] & 2 && g_bPinHunter[i] )
					{
						if( GetEntPropEnt(i, Prop_Send, "m_pounceAttacker") == -1 )
						{
							allPinned = false;
							g_bPinHunter[i] = false;
							break;
						}

						continue;
					}

					if( g_bLeft4Dead2 )
					{
						if( g_iOptionPinned[class] & 4 && g_bPinJockey[i] )
						{
							if( GetEntPropEnt(i, Prop_Send, "m_jockeyAttacker") == -1 )
							{
								allPinned = false;
								g_bPinJockey[i] = false;
								break;
							}

							continue;
						}

						if( g_iOptionPinned[class] & 8 && g_bPinCharger[i] )
						{
							if( GetEntPropEnt(i, Prop_Send, "m_carryAttacker") == -1  || GetEntPropEnt(i, Prop_Send, "m_pummelAttacker") == -1 )
							{
								allPinned = false;
								g_bPinCharger[i] = false;
								break;
							}

							continue;
						}
					}
				}
			}
		}

		if( allPinned )
		{
			#if DEBUG_BENCHMARK == 3
			PrintToServer("All pinned, selecting self: {%d - \"%N\"}", attacker, attacker);
			#endif

			newVictim = attacker;
		}
	}



	// =========================
	// NEW TARGET
	// =========================
	if( newVictim != g_iLastVictim[attacker] )
	{
		#if DEBUG_BENCHMARK == 3
		PrintToServer("New order victim selected: {%d - \"%N\"} (order %d/%d)", newVictim, newVictim, order, orders);
		#endif

		g_iLastOrders[attacker] = order;
		g_iLastVictim[attacker] = newVictim;
		g_fLastSwitch[attacker] = GetGameTime() + g_fOptionWait[class];
	}



	// =========================
	// OVERRIDE VICTIM
	// =========================
	if( newVictim )
	{
		Action aResult = SendForward(attacker, newVictim, g_iLastOrders[attacker]);
		if( aResult == Plugin_Handled ) return MRES_Ignored;

		DHookSetReturn(hReturn, newVictim);

		#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
		StopProfiling(g_Prof);
		float speed = GetProfilerTime(g_Prof);
		if( speed < g_fBenchMin ) g_fBenchMin = speed;
		if( speed > g_fBenchMax ) g_fBenchMax = speed;
		g_fBenchAvg += speed;
		g_iBenchTicks++;
		#endif

		#if DEBUG_BENCHMARK == 2
		PrintToServer("ChooseVictim End 5 in %f (Min %f. Avg %f. Max %f)", speed, g_fBenchMin, g_fBenchAvg / g_iBenchTicks, g_fBenchMax);
		#endif

		delete aTargets;
		return MRES_Supercede;
	}

	#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
	StopProfiling(g_Prof);
	float speed = GetProfilerTime(g_Prof);
	if( speed < g_fBenchMin ) g_fBenchMin = speed;
	if( speed > g_fBenchMax ) g_fBenchMax = speed;
	g_fBenchAvg += speed;
	g_iBenchTicks++;
	#endif

	#if DEBUG_BENCHMARK == 2
	PrintToServer("ChooseVictim End 6 in %f (Min %f. Avg %f. Max %f)", speed, g_fBenchMin, g_fBenchAvg / g_iBenchTicks, g_fBenchMax);
	#endif

	delete aTargets;
	return MRES_Ignored;
}

int OrderTest(int attacker, int victim, int team, int class, int order)
{
	#if DEBUG_BENCHMARK == 3
	PrintToServer("Begin OrderTest for {%d - \"%N\"}. Test {%d - \"%N\"} with order: %d", attacker, attacker, victim, victim, order);
	#endif

	int newVictim;

	switch( order )
	{
		// 1=Normal Survivor
		case 1:
		{
			if( team == 2 &&
				g_bLedgeGrab[victim] == false &&
				g_bIncapped[victim] == false &&
				g_bPinBoomer[victim] == false &&
				g_bPinSmoker[victim] == false &&
				g_bPinHunter[victim] == false &&
				g_bPinJockey[victim] == false &&
				g_bPinCharger[victim] == false
			)
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 1");
				#endif
			}
		}

		// 2=Vomited Survivor
		case 2:
		{
			if( team == 2 && g_bPinBoomer[victim] == true )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 2");
				#endif
			}
		}

		// 3=Incapped
		case 3:
		{
			if( team == 2 && g_bIncapped[victim] == true && g_bLedgeGrab[victim] == false )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 3");
				#endif
			}
		}

		// 4=Pinned
		case 4:
		{
			if( team == 2 &&
				g_bPinSmoker[victim] == true ||
				g_bPinHunter[victim] == true ||
				g_bPinJockey[victim] == true ||
				g_bPinCharger[victim] == true
			)
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 4");
				#endif
			}
		}

		// 5=Ledge
		case 5:
		{
			if( team == 2 && g_bLedgeGrab[victim] )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 5");
				#endif
			}
		}

		// 6=Infected Vomited
		case 6:
		{
			if( team == 3 && victim != attacker && g_bPinBoomer[victim] && class != INDEX_TANK ) // Prevent Tank attacking vomited Special Infected, since the Tank won't punch them.
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 6");
				#endif
			}
		}

		// 7=Last Attacker
		case 7:
		{
			if( g_iLastAttacker[attacker] && g_fLastAttack[attacker] + g_fOptionLast[class] > GetGameTime() )
			{
				victim = GetClientOfUserId(g_iLastAttacker[attacker]);
				if( victim && IsPlayerAlive(victim) && ValidateTeam(victim) == 2 )
				{
					newVictim = victim;

					#if DEBUG_BENCHMARK == 3
					PrintToServer("Break order 7");
					#endif
				}
				else
				{
					g_iLastAttacker[attacker] = 0;
				}
			}
		}

		// 8=Lowest Health Survivor
		case 8:
		{
			if( team == 2 )
			{
				int target;
				int health;
				int total = 10000;

				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientInGame(i) && ValidateTeam(i) == 2 && IsPlayerAlive(i) )
					{
						health = RoundFloat(GetClientHealth(i) + GetTempHealth(i));
						if( health < total )
						{
							target = i;
							total = health;
						}
					}
				}

				if( target == victim )
				{
					newVictim = target;

					#if DEBUG_BENCHMARK == 3
					PrintToServer("Break order 8");
					#endif
				}
			}
		}

		// 9=Highest Health Survivor
		case 9:
		{
			if( team == 2 )
			{
				int target;
				int health;
				int total;

				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientInGame(i) && ValidateTeam(i) == 2 && IsPlayerAlive(i) )
					{
						health = RoundFloat(GetClientHealth(i) + GetTempHealth(i));
						if( health > total )
						{
							target = i;
							total = health;
						}
					}
				}

				if( target == victim )
				{
					newVictim = target;

					#if DEBUG_BENCHMARK == 3
					PrintToServer("Break order 9");
					#endif
				}
			}
		}

		// 10=Pummelled Survivor
		case 10:
		{
			if( team == 2 && g_bPumCharger[victim] )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 10");
				#endif
			}
		}

		// 11=Mounted Mini Gun
		case 11:
		{
			if( team == 2 && GetEntProp(victim, Prop_Send, "m_usingMountedWeapon") > 0 )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 11");
				#endif
			}
		}

		// 12=Reviving someone
		case 12:
		{
			if( team == 2 && GetEntPropEnt(victim, Prop_Send, "m_reviveTarget") > 0 )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 12");
				#endif
			}
		}

		// 13=Furthest Ahead
		case 13:
		{
			if( g_bLeft4DHooks && team == 2 && L4D_GetHighestFlowSurvivor() == victim )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 13");
				#endif
			}
		}

		// 14=Healing critical
		case 14:
		{
			if( (g_bLeft4Dead2 && team == 2 && GetEntPropEnt(victim, Prop_Send, "m_useActionTarget") == victim && GetEntProp(victim, Prop_Send, "m_iCurrentUseAction") == 1) || (!g_bLeft4Dead2 && team == 2 && GetEntPropEnt(victim, Prop_Send, "m_healTarget") == victim) )
			{
				int health = RoundFloat(GetClientHealth(victim) + GetTempHealth(victim));
				if( health < g_fCvarLimp )
				{
					newVictim = victim;

					#if DEBUG_BENCHMARK == 3
					PrintToServer("Break order 14");
					#endif
				}
			}
		}

		// 15=Furthest Ahead
		case 15:
		{
			if( g_bLeft4DHooks && team == 2 )
			{
				float flow;
				float last = 99999.9;
				int target;

				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientInGame(i) && ValidateTeam(i) == 2 && IsPlayerAlive(i) )
					{
						flow = L4D2Direct_GetFlowDistance(i);
						if( flow < last )
						{
							last = flow;
							target = i;
						}
					}
				}

				if( target == victim )
				{
					newVictim = victim;

					#if DEBUG_BENCHMARK == 3
					PrintToServer("Break order 15");
					#endif
				}
			}
		}

		// 16=Flashlight on
		case 16:
		{
			if( team == 2 && GetEntProp(victim, Prop_Send, "m_fEffects") & 4 )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 16");
				#endif
			}
		}

		// 17=Running
		case 17:
		{
			if( team == 2 )
			{
				int buttons = GetClientButtons(victim);
				if( !(buttons & IN_SPEED) && !(buttons & IN_DUCK) && (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT) )
				{
					newVictim = victim;

					#if DEBUG_BENCHMARK == 3
					PrintToServer("Break order 17");
					#endif
				}
			}
		}
	}

	// Ignore players using a minigun if not checking for that
	if( newVictim && order != 11 && GetEntProp(newVictim, Prop_Send, "m_usingMountedWeapon") > 0 )
	{
		newVictim = 0;
	}

	return newVictim;
}



// ====================================================================================================
//					NATIVES AND FORWARDS
// ====================================================================================================
any Native_GetValue(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int option = GetNativeCell(2);

	switch( view_as<VALUE_OPTION_INDEX>(option) )
	{
		case VALUE_INDEX_VICTIM:		return g_iLastVictim[client];
		case VALUE_INDEX_SWITCH:		return g_fLastSwitch[client];
		case VALUE_INDEX_ATTACK:		return g_fLastAttack[client];
		case VALUE_INDEX_ATTACKER:		return g_iLastAttacker[client];
		case VALUE_INDEX_ORDER:			return g_iLastOrders[client];
		case VALUE_INDEX_TOTAL:
		{
			int total;

			for( int i = 1; i <= MaxClients; i++ )
			{
				if( g_iLastVictim[i] == client )
				{
					total++;
				}
			}

			return total;
		}
	}

	return -1;
}

any Native_GetOption(Handle plugin, int numParams)
{
	int index = GetNativeCell(1);
	int option = GetNativeCell(2);

	switch( view_as<TARGET_OPTION_INDEX>(option) )
	{
		case INDEX_PINNED:		return g_iOptionPinned[index];
		case INDEX_INCAP:		return g_iOptionIncap[index];
		case INDEX_VOMS:		return g_iOptionVoms[index];
		case INDEX_VOMS2:		return g_iOptionVoms2[index];
		case INDEX_RANGE:		return g_fOptionRange[index];
		case INDEX_DIST:		return g_fOptionDist[index];
		case INDEX_WAIT:		return g_fOptionWait[index];
		case INDEX_LAST:		return g_iOptionLast[index];
		case INDEX_TIME:		return g_fOptionLast[index];
		case INDEX_SAFE:		return g_iOptionSafe[index];
		case INDEX_TARGETED:	return g_iOptionTarg[index];
	}

	return -1;
}

int Native_SetOption(Handle plugin, int numParams)
{
	int index = GetNativeCell(1);
	int option = GetNativeCell(2);
	any value = GetNativeCell(3);

	switch( view_as<TARGET_OPTION_INDEX>(option) )
	{
		case INDEX_PINNED:		g_iOptionPinned[index] = value;
		case INDEX_INCAP:		g_iOptionIncap[index] = value;
		case INDEX_VOMS:		g_iOptionVoms[index] = value;
		case INDEX_VOMS2:		g_iOptionVoms2[index] = value;
		case INDEX_RANGE:		g_fOptionRange[index] = value;
		case INDEX_DIST:		g_fOptionDist[index] = value;
		case INDEX_WAIT:		g_fOptionWait[index] = value;
		case INDEX_LAST:		g_iOptionLast[index] = value;
		case INDEX_TIME:		g_fOptionLast[index] = value;
		case INDEX_SAFE:		g_iOptionSafe[index] = value;
		case INDEX_TARGETED:	g_iOptionTarg[index] = value;
	}

	return 0;
}

Action SendForward(int attacker, int &victim, int order)
{
	if( g_bCvarForward )
	{
		int victim2 = victim;

		// Forward
		Action aResult;
		Call_StartForward(g_hForward);
		Call_PushCell(attacker);
		Call_PushCellRef(victim2);
		Call_PushCell(order);
		Call_Finish(aResult);

		if( aResult == Plugin_Changed ) victim = victim2;

		return aResult;
	}

	return Plugin_Continue;
}



// ====================================================================================================
//					STOCKS
// ====================================================================================================
float GetTempHealth(int client)
{
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_fDecayDecay;
	return fHealth < 0.0 ? 0.0 : fHealth;
}

int ValidateTeam(int client)
{
	int team = GetClientTeam(client);
	switch( team )
	{
		case 2:		if( 2 & g_iCvarTeam) return 2;
		case 4:		if( 4 & g_iCvarTeam) return 2;
		case 3:		return 3;
	}

	return 0;
}