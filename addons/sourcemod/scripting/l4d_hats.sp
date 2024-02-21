/*
*	Hats
*	Copyright (C) 2021 Silvers
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



#define PLUGIN_VERSION 		"1.42"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Hats
*	Author	:	SilverShot
*	Descrp	:	Attaches specified models to players above their head.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=153781
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.42 (16-Dec-2021)
	- Fixed simple mistake from last update causing wrong menu listing when not using a "hatnames" translation. Thanks to "Mi.Cura" for reporting.

1.41 (14-Dec-2021)
	- Fixed spawning and respawning with a hat when it was turned off. Thanks to "kot4404" for reporting.

	- Changed the "hatnames.phrases.txt" translation file format for better modifications when adding or removing hats from the data config.
	- Now supports adding hats and breaking the plugin when missing from the "hatnames.phrases.txt" translations file.
	- New "hatnames" translations no longer uses indexes and only model names.
	- Still supports the old version but suggest upgrading to the new.
	- Included the script for converting the translation file based on the config. Search for "TRANSLATE CODE" in the source.

1.40 (11-Dec-2021)
	- Fixed not saving hat angles and origins correctly when "l4d_hats_wall" was set to "0". Thanks to "NoroHime" for reporting.
	- Now saves when a hat was removed, if saving is enabled. Requested by "kot4404".

1.39 (09-Dec-2021)
	- Changed command "sm_hat" to accept "rand" or "random" as a parameter option to give a random hat.
	- Updated the "chi" and "zho" translation "hatnames.phrases.txt" files to be correct. Thanks to "NoroHime".

1.38 (03-Dec-2021)
	- Added "Off" option to the menu. Requested by "kot4404".
	- Fixed command "sm_hatadd" from not adding new entries. Thanks to "swiftswing1" for reporting.
	- Changes to fix warnings when compiling on SourceMod 1.11.

1.37 (09-Sep-2021)
	- Plugin now deletes the client cookie and hat if they no longer have access to use hats. Requested by "Darkwob".

1.36 (20-Jul-2021)
	- Removed cvar "l4d_hats_view" - recommended to use "ThirdPersonShoulder_Detect" plugin to turn on/off the hat view when in 3rd/1st person view.

1.35 (10-Jul-2021)
	- Fixed giving random hats to players when the "l4d_hats_random" cvar was set to "0". Thanks to "XYZC" for reporting.

1.34 (05-Jul-2021)
	- Fixed giving random hats on round_start when "l4d_hats_save" cvar was set to "1".

1.33 (04-Jul-2021)
	- Fixed "sm_hatrand" and "sm_hatrandom" from not giving random hats. Not sure when this broke.

1.32 (01-Jul-2021)
	- Added a warning message to suggest installing the "Attachments API" and "Use Priority Patch" plugins if missing.

1.31 (03-May-2021)
	- Added Simplified Chinese (zho) and Traditional Chinese (chi) translations. Thanks to "pan0s" for providing.
	- Fixed not giving random hats to clients who have no saved hats. Thanks to "pan0s" for reporting.

1.30 (28-Apr-2021)
	- Fixed client not in-game errors. Thanks to "HarryPotter" for reporting.

1.29 (10-Apr-2021)
	- Added cvar "l4d_hats_bots" to allow or disallow bots from spawning with hats.
	- Added cvar "l4d_hats_make" to allow players with specific flags only to auto spawn with hats.

1.28 (20-Mar-2021)
	- Added cvar "l4d_hats_wall" to prevent hats glowing through walls. Thanks to "Marttt" for the method and "Dragokas" for requesting.
	- Fixed personal hats not showing when changing hat in external view.

1.27 (01-Mar-2021)
	- Fixed invalid client errors due to the last update. Thanks to "ur5efj" for reporting.

1.26 (01-Mar-2021)
	- Now blocks showing hats when spectating someone in first person view. Thanks to "Alex101192" for reporting.

1.25 (23-Feb-2021)
	- Fixed hats not hiding after being revived. Thanks to "Alex101192" for reporting.

1.24 (01-Oct-2020)
	- Changed "l4d_hats_precache" cvar default value to blank.
	- Changed the way "l4d_hats_detect" works. Now also detects if reviving someone (events were unreliable and causing bugs).
	- Fixed 1st and 3rd person view of hats wrongfully toggling under certain conditions. Thanks to "Alex101192" for reporting.
	- Fixed some spelling mistakes in the "data/l4d_hats.cfg" hat names.

1.23 (16-Jun-2020)
	- Added Russian and Ukrainian translations - Thanks to "Dragokas" for providing.
	- Fixed changing hats when "l4d_hats_save" and "l4d_hats_random" were set. Random is superseded by saved if present.
	- Fixed command "sm_hatclient" throwing an error when only a client was specified.
	- Fixed hat view "ThirdPersonShoulder_Detect" and "Survivor Thirdperson" plugins clashing.

1.22 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Fixed not always loading client cookies before creating hats. Thanks to "Alex101192" for reporting.
	- Fixed potentially not translating some strings.
	- Fixed some functions not working for more than 100 hats.
	- Fixed hats affecting Survivor Thirdperson view under certain conditions.
	- Various changes to tidy up code.
	- Various optimizations and fixes.

1.21 (30-Apr-2020)
	- Added cvar "l4d_hats_detect" to enable clients to see their own hat when 3rd person view is detected.
	- Optionally uses "ThirdPersonShoulder_Detect" plugin by "Lux" and "MasterMind420", if available.

	- Added bunch of maps to the default value of "l4d_hats_precache". Thanks to "Alex101192" for providing.
	- Increased "l4d_hats_precache" cvar length, max usable length 490 (due to game limitations).

1.20 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.
	- Removed "colors.inc" dependency.
	- Updated these translation file encodings to UTF-8 (to display all characters correctly): German (de).

1.19 (19-Dec-2019)
	- Added command "sm_hatclient" to set a clients hat, requested by "foxhound27".

1.18 (23-Oct-2019)
	- Added commands "sm_hatshowon" and "sm_hatshowoff" to turn on/off personal hat visibility.
	- Fixed cvar "l4d_hats_precache" from modifying the allow cvar. Now correctly disables on blocked maps.

1.17 (10-Sep-2019)
	- Added cvar "l4d_hats_precache" to prevent pre-caching models on specified maps.

1.17b (19-Aug-2019)
	- Fixed ghosts from having hats.

1.16 (02-Aug-2019)
	- Fixed "m_TimeForceExternalView not found" error for L4D1 - Thanks to "Ja-Forces" for reporting.

1.15 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed cvar "l4d_hats_modes_tog" now supports L4D1.

1.14 (25-Jun-2017)
	- Added "Reset" option to the ang/pos/size menus, requested by "ZBzibing".
	- Fixed depreciated FCVAR_PLUGIN and GetClientAuthString.
	- Increased MAX_HATS value and added many extra L4D2 hats thanks to "Munch".

1.13 (29-Mar-2015)
	- Fixed the plugin not working in L4D1 due to a SetEntPropFloat property not found error.

1.12 (07-Oct-2012)
	- Fixed hats blocking players +USE by adding a single line of code - Thanks to "Machine".

1.11 (02-Jul-2012)
	- Fixed cvar "l4d_hats_random" from not working properly - Thanks to "Don't Fear The Reaper" for reporting.

1.10 (20-Jun-2012)
	- Added German translations - Thanks to "Don't Fear The Reaper".
	- Small fixes.

1.9.0 (22-May-2012)
	- Fixed multiple hat changes only showing the first hat to players.
	- Changing hats will no longer return the player to firstperson if thirdperson was already on.

1.8.0 (21-May-2012)
	- Fixed command "sm_hatc" making the client thirdpeson and not the target.

1.7.0 (20-May-2012)
	- Added cvar "l4d_hats_change" to put the player into thirdperson view when they select a hat, requested by "disawar1".

1.6.1 (15-May-2012)
	- Fixed a bug when printing to chat after changing someones hat.
	- Fixed cvar "l4d_hats_menu" not allowing access if it was empty.

1.6.0 (15-May-2012)
	- Fixed the allow cvars not affecting everything.

1.5.0 (10-May-2012)
	- Added translations, required for the commands and menu title.
	- Added optional translations for the hat names as requested by disawar1.
	- Added cvar "l4d_hats_allow" to turn on/off the plugin.
	- Added cvar "l4d_hats_modes" to control which game modes the plugin works in.
	- Added cvar "l4d_hats_modes_off" same as above.
	- Added cvar "l4d_hats_modes_tog" same as above, but only works for L4D2.
	- Added cvar "l4d_hats_save" to save a players hat for next time they spawn or connect.
	- Added command "sm_hatsize" to change the scale/size of hats as suggested by worminater.
	- Fixed "l4d_hats_menu" flags not setting correctly.
	- Optimized the plugin by hooking cvar changes.
	- Selecting a hat from the menu no longer returns to the first page.

1.4.3 (07-May-2011)
	- Added "name" key to the config for reading hat names.

1.4.2 (16-Apr-2011)
	- Changed the way models are checked to exist and precached.

1.4.1 (16-Apr-2011)
	- Added new hat models to the config. Deleted and repositioned models blocking the "use" function.
	- Changed the hat entity from prop_dynamic to prop_dynamic_override (allows physics models to be attached).
	- Fixed command "sm_hatadd" causing crashes due to models not being pre-cached, cannot cache during a round, causes crash.
	- Fixed pre-caching models which are missing (logs an error telling you an incorrect model is specified).

1.4.0 (11-Apr-2011)
	- Added cvar "l4d_hats_opaque" to set hat transparency.
	- Changed cvar "l4d_hats_random" to create a random hat when survivors spawn. 0=Never. 1=On round start. 2=Only first spawn (keeps the same hat next round).
	- Fixed hats changing when returning from idle.
	- Replaced underscores (_) with spaces in the menu.

1.3.4 (09-Apr-2011)
	- Fixed hooking L4D2 events in L4D1.

1.3.3 (07-Apr-2011)
	- Fixed command "sm_hatc" not displaying for admins when they are dead/infected team.
	- Minor bug fixes.

1.3.2 (06-Apr-2011)
	- Fixed command "sm_hatc" displaying invalid player.

1.3.1 (05-Apr-2011)
	- Fixed the fix of command "sm_hat" flags not applying.

1.3.0 (05-Apr-2011)
	- Fixed command "sm_hat" flags not applying.

1.2.0 (03-Apr-2011)
	- Added command "sm_hatoffc" for admins to disable hats on specific clients.
	- Added cvar "l4d_hats_third" to control the previous update's addition.

1.1.1a (03-Apr-2011)
	- Added events to show / hide the hat when in third / first person view.

1.1.1 (02-Apr-2011)
	- Added cvar "l4d_hats_view" to toggle if a players hat is visible by default when they join.
	- Resets variables for clients when they connect.

1.1.0 (01-Apr-2011)
	- Added command "sm_hatoff" - Toggle to turn on or off the ability of wearing hats.
	- Added command "sm_hatadd" - To add models into the config.
	- Added command "sm_hatdel" - To remove a model from the config.
	- Added command "sm_hatlist" - To display a list of all models (for use with sm_hatdel).

1.0.0 (29-Mar-2011)
	- Initial release.

======================================================================================*/

#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x05[HATS]\x03 "
#define CONFIG_SPAWNS		"data/l4d_hats.cfg"
#define	MAX_HATS			128


ConVar g_hCvarAllow, g_hCvarBots, g_hCvarChange, g_hCvarDetect, g_hCvarMake, g_hCvarMenu, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarOpaq, g_hCvarPrecache, g_hCvarRand, g_hCvarSave, g_hCvarThird, g_hCvarWall;
ConVar g_hCvarMPGameMode;
Handle g_hCookie;
Menu g_hMenu, g_hMenus[MAXPLAYERS+1];
bool g_bCvarAllow, g_bMapStarted, g_bCvarBots, g_bCvarWall, g_bLeft4Dead2, g_bTranslation, g_bViewHooked, g_bValidMap;
int g_iCount, g_iCvarMake, g_iCvarFlags, g_iCvarOpaq, g_iCvarRand, g_iCvarSave, g_iCvarThird;
float g_fCvarChange, g_fCvarDetect;

float g_fSize[MAX_HATS], g_vAng[MAX_HATS][3], g_vPos[MAX_HATS][3];
char g_sModels[MAX_HATS][64], g_sNames[MAX_HATS][64];
char g_sSteamID[MAXPLAYERS+1][32];		// Stores client user id to determine if the blocked player is the same
int g_iHatIndex[MAXPLAYERS+1];			// Player hat entity reference
int g_iHatWalls[MAXPLAYERS+1];			// Hidden hat entity reference
int g_iSelected[MAXPLAYERS+1];			// The selected hat index (0 to MAX_HATS)
int g_iTarget[MAXPLAYERS+1];			// For admins to change clients hats
int g_iType[MAXPLAYERS+1];				// Stores selected hat to give players
bool g_bHatView[MAXPLAYERS+1];			// Player view of hat on/off (personal setting)
bool g_bHatOff[MAXPLAYERS+1];			// Lets players turn their hats on/off
bool g_bMenuType[MAXPLAYERS+1];			// Admin var for menu
bool g_bBlocked[MAXPLAYERS+1];			// Determines if the player is blocked from hats
bool g_bExternalCvar[MAXPLAYERS+1];		// If thirdperson view was detected (thirdperson_shoulder cvar)
bool g_bExternalProp[MAXPLAYERS+1];		// If thirdperson view was detected (netprop or revive actions)
bool g_bExternalState[MAXPLAYERS+1];	// If thirdperson view was detected
bool g_bCookieAuth[MAXPLAYERS+1];		// When cookies cached and client is authorized
Handle g_hTimerView[MAXPLAYERS+1];		// Thirdperson view when selecting hat
Handle g_hTimerDetect;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Hats",
	author = "SilverShot",
	description = "Attaches specified models to players above their head.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=153781"
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
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	// Attachments API
	if( FindConVar("attachments_api_version") == null && (FindConVar("l4d2_swap_characters_version") != null || FindConVar("l4d_csm_version") != null) )
	{
		LogMessage("\n==========\nWarning: You should install \"[ANY] Attachments API\" to fix model attachments when changing character models: https://forums.alliedmods.net/showthread.php?t=325651\n==========\n");
	}

	// Use Priority Patch
	if( FindConVar("l4d_use_priority_version") == null )
	{
		LogMessage("\n==========\nWarning: You should install \"[L4D & L4D2] Use Priority Patch\" to fix attached models blocking +USE action: https://forums.alliedmods.net/showthread.php?t=327511\n==========\n");
	}
}

public void OnPluginStart()
{
	// Load config
	KeyValues hFile = OpenConfig();
	char sTemp[64];
	for( int i = 0; i < MAX_HATS; i++ )
	{
		IntToString(i+1, sTemp, sizeof(sTemp));
		if( hFile.JumpToKey(sTemp) )
		{
			hFile.GetString("mod", sTemp, sizeof(sTemp));

			TrimString(sTemp);
			if( sTemp[0] == 0 )
				break;

			if( FileExists(sTemp, true) )
			{
				hFile.GetVector("ang", g_vAng[i]);
				hFile.GetVector("loc", g_vPos[i]);
				g_fSize[i] = hFile.GetFloat("size", 1.0);
				g_iCount++;

				strcopy(g_sModels[i], sizeof(g_sModels[]), sTemp);

				hFile.GetString("name", g_sNames[i], sizeof(g_sNames[]));

				if( strlen(g_sNames[i]) == 0 )
					GetHatName(g_sNames[i], i);
			}
			else
				LogError("Cannot find the model '%s'", sTemp);

			hFile.Rewind();
		}
	}
	delete hFile;

	if( g_iCount == 0 )
		SetFailState("No models wtf?!");



	// Transactions
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "translations/hatnames.phrases.txt");
	g_bTranslation = FileExists(sPath);

	if( g_bTranslation )
		LoadTranslations("hatnames.phrases");
	LoadTranslations("hats.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");



	// Hats menu
	if( g_bTranslation == false )
	{
		g_hMenu = new Menu(HatMenuHandler);
		g_hMenu.AddItem("Off", "Off");

		for( int i = 0; i < g_iCount; i++ )
			g_hMenu.AddItem(g_sModels[i], g_sNames[i]);
		g_hMenu.SetTitle("%t", "Hat_Menu_Title");
		g_hMenu.ExitButton = true;
	}



	// Cvars
	g_hCvarAllow = CreateConVar(		"l4d_hats_allow",		"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarBots = CreateConVar(			"l4d_hats_bots",		"1",			"0=Disallow bots from spawning with Hats. 1=Allow bots to spawn with hats.", CVAR_FLAGS, true, 0.0, true, 1.0 );
	g_hCvarChange = CreateConVar(		"l4d_hats_change",		"1.3",			"0=Off. Other value puts the player into thirdperson for this many seconds when selecting a hat.", CVAR_FLAGS );
	g_hCvarDetect = CreateConVar(		"l4d_hats_detect",		"0.3",			"0.0=Off. How often to detect thirdperson view. Also uses ThirdPersonShoulder_Detect plugin if available.", CVAR_FLAGS );
	g_hCvarMake = CreateConVar(			"l4d_hats_make",		"",				"Specify admin flags or blank to allow all players to spawn with a hat, requires the l4d_hats_random cvar to spawn.", CVAR_FLAGS );
	g_hCvarMenu = CreateConVar(			"l4d_hats_menu",		"",				"Specify admin flags or blank to allow all players access to the hats menu.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(		"l4d_hats_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(		"l4d_hats_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(		"l4d_hats_modes_tog",	"",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarOpaq = CreateConVar(			"l4d_hats_opaque",		"255", 			"How transparent or solid should the hats appear. 0=Translucent, 255=Opaque.", CVAR_FLAGS, true, 0.0, true, 255.0 );
	g_hCvarPrecache = CreateConVar(		"l4d_hats_precache",	"",				"Prevent pre-caching models on these maps, separate by commas (no spaces). Enabling plugin on these maps will crash the server.", CVAR_FLAGS );
	g_hCvarRand = CreateConVar(			"l4d_hats_random",		"1", 			"Attach a random hat when survivors spawn. 0=Never. 1=On round start. 2=Only first spawn (keeps the same hat next round).", CVAR_FLAGS, true, 0.0, true, 3.0 );
	g_hCvarSave = CreateConVar(			"l4d_hats_save",		"1", 			"0=Off, 1=Save the players selected hats and attach when they spawn or rejoin the server. Overrides the random setting.", CVAR_FLAGS, true, 0.0, true, 1.0 );
	g_hCvarThird = CreateConVar(		"l4d_hats_third",		"1", 			"0=Off, 1=When a player is in third person view, display their hat. Hide when in first person view.", CVAR_FLAGS, true, 0.0, true, 1.0 );
	g_hCvarWall = CreateConVar(			"l4d_hats_wall",		"1",			"0=Show hats glowing through walls, 1=Hide hats glowing when behind walls (creates 1 extra entity per hat).", CVAR_FLAGS, true, 0.0, true, 1.0 );
	CreateConVar(						"l4d_hats_version",		PLUGIN_VERSION,	"Hats plugin version.",	FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_hats");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarBots.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarChange.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDetect.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMake.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMenu.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRand.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSave.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWall.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarOpaq.AddChangeHook(CvarChangeOpac);
	g_hCvarThird.AddChangeHook(CvarChangeThird);



	// Commands
	RegConsoleCmd("sm_hat",			CmdHat,								"Displays a menu of hats allowing players to change what they are wearing. Optional args: [0 - 128 or hat name or \"random\"]");
	RegConsoleCmd("sm_hatoff",		CmdHatOff,							"Toggle to turn on or off the ability of wearing hats.");
	RegConsoleCmd("sm_hatshow",		CmdHatShow,							"Toggle to see or hide your own hat.");
	RegConsoleCmd("sm_hatview",		CmdHatShow,							"Toggle to see or hide your own hat.");
	RegConsoleCmd("sm_hatshowon",	CmdHatShowOn,						"See your own hat.");
	RegConsoleCmd("sm_hatshowoff",	CmdHatShowOff,						"Hide your own hat.");
	RegAdminCmd("sm_hatclient",		CmdHatClient,		ADMFLAG_ROOT,	"Set a clients hat. Usage: sm_hatclient <#userid|name> [hat name or hat index: 0-128 (MAX_HATS)].");
	RegAdminCmd("sm_hatoffc",		CmdHatOffTarget,	ADMFLAG_ROOT,	"Toggle the ability of wearing hats on specific players.");
	RegAdminCmd("sm_hatc",			CmdHatTarget,		ADMFLAG_ROOT,	"Displays a menu listing players, select one to change their hat.");
	RegAdminCmd("sm_hatrandom",		CmdHatRand,			ADMFLAG_ROOT,	"Randomizes all players hats.");
	RegAdminCmd("sm_hatrand",		CmdHatRand,			ADMFLAG_ROOT,	"Randomizes all players hats.");
	RegAdminCmd("sm_hatadd",		CmdHatAdd,			ADMFLAG_ROOT,	"Adds specified model to the config (must be the full model path).");
	RegAdminCmd("sm_hatdel",		CmdHatDel,			ADMFLAG_ROOT,	"Removes a model from the config (either by index or partial name matching).");
	RegAdminCmd("sm_hatlist",		CmdHatList,			ADMFLAG_ROOT,	"Displays a list of all the hat models (for use with sm_hatdel).");
	RegAdminCmd("sm_hatsave",		CmdHatSave,			ADMFLAG_ROOT,	"Saves the hat position and angels to the hat config.");
	RegAdminCmd("sm_hatload",		CmdHatLoad,			ADMFLAG_ROOT,	"Changes all players hats to the one you have.");
	RegAdminCmd("sm_hatang",		CmdAng,				ADMFLAG_ROOT,	"Shows a menu allowing you to adjust the hat angles (affects all hats/players).");
	RegAdminCmd("sm_hatpos",		CmdPos,				ADMFLAG_ROOT,	"Shows a menu allowing you to adjust the hat position (affects all hats/players).");
	RegAdminCmd("sm_hatsize",		CmdHatSize,			ADMFLAG_ROOT,	"Shows a menu allowing you to adjust the hat size (affects all hats/players).");

	g_hCookie = RegClientCookie("l4d_hats", "Hat Type", CookieAccess_Protected);
}

public void OnPluginEnd()
{
	for( int i = 1; i <= MaxClients; i++ )
		RemoveHat(i);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	char sTemp[32];
	g_hCvarMake.GetString(sTemp, sizeof(sTemp));
	g_iCvarMake = ReadFlagString(sTemp);
	g_hCvarMenu.GetString(sTemp, sizeof(sTemp));
	g_iCvarFlags = ReadFlagString(sTemp);
	g_bCvarBots = g_hCvarBots.BoolValue;
	g_fCvarChange = g_hCvarChange.FloatValue;
	g_fCvarDetect = g_hCvarDetect.FloatValue;
	g_iCvarOpaq = g_hCvarOpaq.IntValue;
	g_iCvarRand = g_hCvarRand.IntValue;
	g_iCvarSave = g_hCvarSave.IntValue;
	g_iCvarThird = g_hCvarThird.IntValue;
	g_bCvarWall = g_hCvarWall.BoolValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true && g_bValidMap == true )
	{
		g_bCvarAllow = true;

		if( g_iCvarThird )
			HookViewEvents();
		HookEvents();
		SpectatorHatHooks();

		for( int i = 1; i <= MaxClients; i++ )
		{
			g_bHatView[i] = false;
			g_iSelected[i] = GetRandomInt(0, g_iCount -1);
		}

		if( g_iCvarRand || g_iCvarSave )
		{
			int clientID;

			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) && GetClientTeam(i) == 2 )
				{
					clientID = GetClientUserId(i);

					if( g_iCvarSave && !IsFakeClient(i) )
					{
						OnClientCookiesCached(i);
						CreateTimer(0.3, TimerDelayCreate, clientID);
					}
					else if( g_iCvarRand )
					{
						CreateTimer(0.3, TimerDelayCreate, clientID);
					}
				}
			}
		}

		// if( g_bLeft4Dead2 && g_fCvarDetect )
		if( g_fCvarDetect )
		{
			delete g_hTimerDetect;
			g_hTimerDetect = CreateTimer(g_fCvarDetect, TimerDetect, _, TIMER_REPEAT);
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false || g_bValidMap == false) )
	{
		g_bCvarAllow = false;

		UnhookViewEvents();
		UnhookEvents();

		for( int i = 1; i <= MaxClients; i++ )
		{
			RemoveHat(i);

			if( IsValidEntRef(g_iHatIndex[i]) )
			{
				for( int x = 1; x <= MaxClients; x++ )
				{
					if( IsClientInGame(x) )
					{
						SDKUnhook(g_iHatIndex[i], SDKHook_SetTransmit, Hook_SetSpecTransmit);
					}
				}
			}
		}
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

public void OnGamemode(const char[] output, int caller, int activator, float delay)
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
//					OTHER BITS
// ====================================================================================================
public void OnMapStart()
{
	g_bMapStarted = true;
	g_bValidMap = true;

	char sCvar[512];
	g_hCvarPrecache.GetString(sCvar, sizeof(sCvar));

	if( sCvar[0] != '\0' )
	{
		char sMap[64];
		GetCurrentMap(sMap, sizeof(sMap));

		Format(sMap, sizeof(sMap), ",%s,", sMap);
		Format(sCvar, sizeof(sCvar), ",%s,", sCvar);

		if( StrContains(sCvar, sMap, false) != -1 )
			g_bValidMap = false;
	}

	if( g_bValidMap )
		for( int i = 0; i < g_iCount; i++ )
			PrecacheModel(g_sModels[i]);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void OnClientAuthorized(int client, const char[] sSteamID)
{
	if( g_bBlocked[client] )
	{
		if( IsFakeClient(client) )
		{
			g_bBlocked[client] = false;
		}
		else if( strcmp(sSteamID, g_sSteamID[client]) )
		{
			strcopy(g_sSteamID[client], sizeof(g_sSteamID[]), sSteamID);
			g_bBlocked[client] = false;
		}
	}

	g_bMenuType[client] = false;

	CookieAuthTest(client);
}

public void OnClientCookiesCached(int client)
{
	if( g_bCvarAllow && g_iCvarSave && !IsFakeClient(client) )
	{
		// Get client cookies, set type if available or default.
		char sCookie[4];
		GetClientCookie(client, g_hCookie, sCookie, sizeof(sCookie));

		if( sCookie[0] == 0 )
		{
			g_iType[client] = 0;
		}
		else
		{
			int type = StringToInt(sCookie);
			g_iType[client] = type;
		}

		CookieAuthTest(client);
	}
}

void CookieAuthTest(int client)
{
	// Check if clients allowed to use hats otherwise delete cookie/hat
	if( g_iCvarMake && g_bCookieAuth[client] && !IsFakeClient(client) )
	{
		int flags = GetUserFlagBits(client);

		if( !(flags & ADMFLAG_ROOT) && !(flags & g_iCvarMake) )
		{
			g_iType[client] = 0;
			RemoveHat(client);
			SetClientCookie(client, g_hCookie, "0");
		}
	} else {
		g_bCookieAuth[client] = true;
	}
}

public void OnClientDisconnect(int client)
{
	g_bCookieAuth[client] = false;
	delete g_hTimerView[client];
}

KeyValues OpenConfig()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		SetFailState("Cannot find the file: \"%s\"", CONFIG_SPAWNS);

	KeyValues hFile = new KeyValues("models");
	if( !hFile.ImportFromFile(sPath) )
	{
		delete hFile;
		SetFailState("Cannot load the file: \"%s\"", CONFIG_SPAWNS);
	}
	return hFile;
}

void SaveConfig(KeyValues hFile)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	hFile.Rewind();
	hFile.ExportToFile(sPath);
}

void GetHatName(char sTemp[64], int index)
{
	strcopy(sTemp, sizeof(sTemp), g_sModels[index]);
	ReplaceString(sTemp, sizeof(sTemp), "_", " ");
	int pos = FindCharInString(sTemp, '/', true) + 1;
	int len = strlen(sTemp) - pos - 3;
	strcopy(sTemp, len, sTemp[pos]);
}

bool IsValidClient(int client)
{
	if( client && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
		return true;
	return false;
}



// ====================================================================================================
//					CVAR CHANGES
// ====================================================================================================
public void CvarChangeOpac(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iCvarOpaq = g_hCvarOpaq.IntValue;

	if( g_bCvarAllow )
	{
		int entity;
		for( int i = 1; i <= MaxClients; i++ )
		{
			entity = g_iHatIndex[i];
			if( IsValidClient(i) && IsValidEntRef(entity) )
			{
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, g_iCvarOpaq);
			}
		}
	}
}

public void CvarChangeThird(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iCvarThird = g_hCvarThird.IntValue;

	if( g_bCvarAllow )
	{
		if( g_iCvarThird )
			HookViewEvents();
		else
			UnhookViewEvents();
	}
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void HookEvents()
{
	HookEvent("round_start",		Event_Start);
	HookEvent("round_end",			Event_RoundEnd);
	HookEvent("player_death",		Event_PlayerDeath);
	HookEvent("player_spawn",		Event_PlayerSpawn);
	HookEvent("player_team",		Event_PlayerTeam);
}

void UnhookEvents()
{
	UnhookEvent("round_start",		Event_Start);
	UnhookEvent("round_end",		Event_RoundEnd);
	UnhookEvent("player_death",		Event_PlayerDeath);
	UnhookEvent("player_spawn",		Event_PlayerSpawn);
	UnhookEvent("player_team",		Event_PlayerTeam);
}

void HookViewEvents()
{
	if( g_bViewHooked == false )
	{
		g_bViewHooked = true;

		HookEvent("revive_success",			Event_First2);
		HookEvent("player_ledge_grab",		Event_Third1);
		HookEvent("lunge_pounce",			Event_Third2);
		HookEvent("pounce_end",				Event_First1);
		HookEvent("tongue_grab",			Event_Third2);
		HookEvent("tongue_release",			Event_First1);

		if( g_bLeft4Dead2 )
		{
			HookEvent("charger_pummel_start",		Event_Third2);
			HookEvent("charger_carry_start",		Event_Third2);
			HookEvent("charger_carry_end",			Event_First1);
			HookEvent("charger_pummel_end",			Event_First1);
		}
	}
}

void UnhookViewEvents()
{
	if( g_bViewHooked == false )
	{
		g_bViewHooked = true;

		UnhookEvent("revive_success",		Event_First2);
		UnhookEvent("player_ledge_grab",	Event_Third1);
		UnhookEvent("lunge_pounce",			Event_Third2);
		UnhookEvent("pounce_end",			Event_First1);
		UnhookEvent("tongue_grab",			Event_Third2);
		UnhookEvent("tongue_release",		Event_First1);

		if( g_bLeft4Dead2 )
		{
			UnhookEvent("charger_pummel_start",		Event_Third2);
			UnhookEvent("charger_carry_start",		Event_Third2);
			UnhookEvent("charger_carry_end",		Event_First1);
			UnhookEvent("charger_pummel_end",		Event_First1);
		}
	}
}

public void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCvarRand == 1 )
		CreateTimer(0.5, TimerRand, _, TIMER_FLAG_NO_MAPCHANGE);

	// if( g_bLeft4Dead2 && g_fCvarDetect )
	if( g_fCvarDetect )
	{
		delete g_hTimerDetect;
		g_hTimerDetect = CreateTimer(g_fCvarDetect, TimerDetect, _, TIMER_REPEAT);
	}
}

public Action TimerRand(Handle timer)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsValidClient(i) && g_iType[i] != -1 )
		{
			CreateHat(i, g_iType[i] ? g_iType[i] - 1 : -1);
		}
	}

	return Plugin_Continue;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++ )
		RemoveHat(i);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( !client || GetClientTeam(client) != 2 )
		return;

	RemoveHat(client);
	SpectatorHatHooks();
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCvarRand == 2 || g_iCvarSave )
	{
		int clientID = event.GetInt("userid");
		int client = GetClientOfUserId(clientID);

		if( client )
		{
			RemoveHat(client);
			CreateTimer(0.5, TimerDelayCreate, clientID);
		}
	}

	SpectatorHatHooks();
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int clientID = event.GetInt("userid");
	int client = GetClientOfUserId(clientID);

	RemoveHat(client);
	SpectatorHatHooks();

	if( g_iCvarRand )
		CreateTimer(0.1, TimerDelayCreate, clientID);
}

public Action TimerDelayCreate(Handle timer, any client)
{
	client = GetClientOfUserId(client);

	if( IsValidClient(client) && !g_bBlocked[client] )
	{
		bool fake = IsFakeClient(client);
		if( !g_bCvarBots && fake )
		{
			return Plugin_Continue;
		}

		if( !fake && g_iCvarMake != 0 )
		{
			int flags = GetUserFlagBits(client);

			if( !(flags & ADMFLAG_ROOT) && !(flags & g_iCvarMake) )
			{
				return Plugin_Continue;
			}
		}

		if( g_iCvarRand == 2 )
			CreateHat(client, -2);
		else if( g_iCvarSave && !IsFakeClient(client) )
			CreateHat(client, -3);
		else if( g_iCvarRand )
			CreateHat(client, -1);
	}

	return Plugin_Continue;
}

public void Event_First1(Event event, const char[] name, bool dontBroadcast)
{
	EventView(GetClientOfUserId(event.GetInt("victim")), false);
}

public void Event_First2(Event event, const char[] name, bool dontBroadcast)
{
	EventView(GetClientOfUserId(event.GetInt("subject")), false);
}

public void Event_Third1(Event event, const char[] name, bool dontBroadcast)
{
	EventView(GetClientOfUserId(event.GetInt("userid")), true);
}

public void Event_Third2(Event event, const char[] name, bool dontBroadcast)
{
	EventView(GetClientOfUserId(event.GetInt("victim")), true);
}

void EventView(int client, bool bIsThirdPerson)
{
	if( IsValidClient(client) )
	{
		SetHatView(client, bIsThirdPerson);
	}
}

// Show hat when thirdperson view
public Action TimerDetect(Handle timer)
{
	if( g_bCvarAllow == false )
	{
		g_hTimerDetect = null;
		return Plugin_Stop;
	}

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( g_bExternalCvar[i] == false && g_iHatIndex[i] && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
		{
			if( (g_bLeft4Dead2 && GetEntPropFloat(i, Prop_Send, "m_TimeForceExternalView") > GetGameTime()) || GetEntPropEnt(i, Prop_Send, "m_reviveTarget") != -1 )
			{
				if( g_bExternalProp[i] == false )
				{
					g_bExternalProp[i] = true;
					SetHatView(i, true);
				}
			}
			else
			{
				if( g_bExternalProp[i] == true )
				{
					g_bExternalProp[i] = false;
					SetHatView(i, false);
				}
			}
		}
	}

	return Plugin_Continue;
}

public void TP_OnThirdPersonChanged(int client, bool bIsThirdPerson)
{
	if( g_fCvarDetect )
	{
		if( bIsThirdPerson == true && g_bExternalCvar[client] == false )
		{
			g_bExternalCvar[client] = true;
			SetHatView(client, true);
		}
		else if( bIsThirdPerson == false && g_bExternalCvar[client] == true )
		{
			g_bExternalCvar[client] = false;
			SetHatView(client, false);
		}
	}
}

void SetHatView(int client, bool bIsThirdPerson)
{
	if( bIsThirdPerson && !g_bExternalState[client] )
	{
		g_bExternalState[client] = true;

		int entity = g_iHatIndex[client];
		if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
			SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	}
	else if( !bIsThirdPerson && g_bExternalState[client] )
	{
		g_bExternalState[client] = false;

		if( !g_bHatView[client] )
		{
			int entity = g_iHatIndex[client];
			if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
				SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
		}
	}
}



// ====================================================================================================
//					BLOCK HATS - WHEN SPECTATING IN 1ST PERSON VIEW
// ====================================================================================================
// Loop through hats, find valid ones, loop through for each client and add transmit hook for spectators
// Could be better instead of unhooking and hooking everyone each time, but quick and dirty addition...
void SpectatorHatHooks()
{
	for( int index = 1; index <= MaxClients; index++ )
	{
		if( IsValidEntRef(g_iHatIndex[index]) )
		{
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) )
				{
					SDKUnhook(g_iHatIndex[index], SDKHook_SetTransmit, Hook_SetSpecTransmit);

					if( !IsPlayerAlive(i) )
					{
						// Must hook 1 frame later because SDKUnhook first and then SDKHook doesn't work, it won't be hooked for some reason.
						DataPack dPack = new DataPack();
						dPack.WriteCell(GetClientUserId(i));
						dPack.WriteCell(index);
						RequestFrame(OnFrameHooks, dPack);
					}
				}
			}
		}
	}
}

public void OnFrameHooks(DataPack dPack)
{
	dPack.Reset();

	int client = dPack.ReadCell();
	client = GetClientOfUserId(client);

	if( client && IsClientInGame(client) && !IsPlayerAlive(client) )
	{
		int index = dPack.ReadCell();
		SDKHook(EntRefToEntIndex(g_iHatIndex[index]), SDKHook_SetTransmit, Hook_SetSpecTransmit);
	}

	delete dPack;
}

public Action Hook_SetSpecTransmit(int entity, int client)
{
	if( !IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_iObserverMode") == 4 )
	{
		int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		if( target > 0 && target <= MaxClients  && g_iHatIndex[target] == EntIndexToEntRef(entity) )
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
//					sm_hat
// ====================================================================================================
public Action CmdHat(int client, int args)
{
	if( !g_bCvarAllow || !IsValidClient(client) )
	{
		CPrintToChat(client, "%s%T", CHAT_TAG, "No Access", client);
		return Plugin_Handled;
	}

	if( g_iCvarFlags != 0 )
	{
		int flags = GetUserFlagBits(client);

		if( !(flags & ADMFLAG_ROOT) && !(flags & g_iCvarFlags) )
		{
			CPrintToChat(client, "%s%T", CHAT_TAG, "No Access", client);
			return Plugin_Handled;
		}
	}

	if( args == 1 )
	{
		char sTemp[64];
		GetCmdArg(1, sTemp, sizeof(sTemp));

		if( strlen(sTemp) < 4 )
		{
			int index = StringToInt(sTemp);
			if( index < 0 || index >= (g_iCount + 1) )
			{
				CPrintToChat(client, "%s%T", CHAT_TAG, "Hat_No_Index", client, index, g_iCount);
			}
			else
			{
				RemoveHat(client);

				if( index == 0 )
				{
					if( g_iCvarSave && !IsFakeClient(client) )
					{
						SetClientCookie(client, g_hCookie, "-1");
						g_iType[client] = -1;
					}

					CPrintToChat(client, "%s%T", CHAT_TAG, "Off", client);
				}
				else if( CreateHat(client, index - 1) )
				{
					ExternalView(client);
				}
			}
		}
		else if( strncmp(sTemp, "rand", 4, false) == 0 )
		{
			RemoveHat(client);

			if( CreateHat(client, GetRandomInt(1, g_iCount) - 1) )
			{
				ExternalView(client);
				return Plugin_Handled;
			}
		}
		else
		{
			ReplaceString(sTemp, sizeof(sTemp), " ", "_");

			for( int i = 0; i < g_iCount; i++ )
			{
				if( StrContains(g_sModels[i], sTemp) != -1 || StrContains(g_sNames[i], sTemp) != -1 )
				{
					RemoveHat(client);

					if( CreateHat(client, i) )
					{
						ExternalView(client);
					}
					return Plugin_Handled;
				}
			}

			CPrintToChat(client, "%s%T", CHAT_TAG, "Hat_Not_Found", client, sTemp);
		}
	}
	else
	{
		ShowMenu(client);
	}

	return Plugin_Handled;
}

public int HatMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End && g_bTranslation == true && client != 0 )
	{
		delete menu;
	}
	else if( action == MenuAction_Select )
	{
		int target = g_iTarget[client];
		if( target )
		{
			target = GetClientOfUserId(target);
			if( IsValidClient(target) )
			{
				char name[MAX_NAME_LENGTH];
				GetClientName(target, name, sizeof(name));

				CPrintToChat(client, "%s%T", CHAT_TAG, "Hat_Changed", client, name);
				RemoveHat(target);

				if( index != 0 && CreateHat(target, index - 1) )
				{
					ExternalView(target);
				}

				ShowMenu(client);
			}
			else
			{
				CPrintToChat(client, "%s%T", CHAT_TAG, "Hat_Invalid", client);

				ShowMenu(client);
			}

			return 0;
		}
		else
		{
			RemoveHat(client);

			if( index == 0 )
			{
				if( g_iCvarSave && !IsFakeClient(client) )
				{
					SetClientCookie(client, g_hCookie, "-1");
					g_iType[client] = -1;
				}

				CPrintToChat(client, "%s%T", CHAT_TAG, "Off", client);
			}
			else if( CreateHat(client, index - 1) )
			{
				ExternalView(client);
			}
		}

		int menupos = menu.Selection;
		menu.DisplayAt(client, menupos, MENU_TIME_FOREVER);
	}

	return 0;
}

void ShowMenu(int client)
{
	if( g_bTranslation == false )
	{
		g_hMenu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		static char sMsg[128];
		Menu hTemp = new Menu(HatMenuHandler);
		hTemp.SetTitle("%T", "Hat_Menu_Title", client);
		FormatEx(sMsg, sizeof(sMsg), "%T", "Off", client);
		hTemp.AddItem("Off", sMsg);

		for( int i = 0; i < g_iCount; i++ )
		{
			FormatEx(sMsg, sizeof(sMsg), "%s", g_sModels[i]);
			int lang = GetClientLanguage(client);

			if( IsTranslatedForLanguage(sMsg, lang) == true )
			{
				Format(sMsg, sizeof(sMsg), "%T", sMsg, client);
				hTemp.AddItem(g_sModels[i], sMsg);
			} else {
				FormatEx(sMsg, sizeof(sMsg), "Hat %d", i + 1);
				if( IsTranslatedForLanguage(sMsg, lang) == true )
				{
					Format(sMsg, sizeof(sMsg), "%T", sMsg, client);
					hTemp.AddItem(g_sModels[i], sMsg);
				} else {
					hTemp.AddItem(g_sModels[i], g_sNames[i]);
				}
			}
		}

		hTemp.ExitButton = true;
		hTemp.Display(client, MENU_TIME_FOREVER);

		g_hMenus[client] = hTemp;
	}
}

// ====================================================================================================
//					sm_hatoff
// ====================================================================================================
public Action CmdHatOff(int client, int args)
{
	if( !g_bCvarAllow || g_bBlocked[client] )
	{
		CPrintToChat(client, "%s%T", CHAT_TAG, "No Access", client);
		return Plugin_Handled;
	}

	g_bHatOff[client] = !g_bHatOff[client];

	if( g_bHatOff[client] )
		RemoveHat(client);

	char sTemp[64];
	FormatEx(sTemp, sizeof(sTemp), "%T", g_bHatOff[client] ? "Hat_Off" : "Hat_On", client);
	CPrintToChat(client, "%s%T", CHAT_TAG, "Hat_Ability", client, sTemp);

	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatshow
// ====================================================================================================
public Action CmdHatShowOn(int client, int args)
{
	g_bHatView[client] = false;
	CmdHatShow(client, args);
	return Plugin_Handled;
}

public Action CmdHatShowOff(int client, int args)
{
	g_bHatView[client] = true;
	CmdHatShow(client, args);
	return Plugin_Handled;
}

public Action CmdHatShow(int client, int args)
{
	if( !g_bCvarAllow || g_bBlocked[client] )
	{
		CPrintToChat(client, "%s%T", CHAT_TAG, "No Access", client);
		return Plugin_Handled;
	}

	int entity = g_iHatIndex[client];
	if( entity == 0 || (entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE )
	{
		CPrintToChat(client, "%s%T", CHAT_TAG, "Hat_Missing", client);
		return Plugin_Handled;
	}

	g_bHatView[client] = !g_bHatView[client];
	if( !g_bHatView[client] )
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	else
		SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit);

	char sTemp[64];
	FormatEx(sTemp, sizeof(sTemp), "%T", g_bHatView[client] ? "Hat_On" : "Hat_Off", client);
	CPrintToChat(client, "%s%T", CHAT_TAG, "Hat_View", client, sTemp);
	return Plugin_Handled;
}



// ====================================================================================================
//					ADMIN COMMANDS
// ====================================================================================================
//					sm_hatrand / sm_ratrandom
// ====================================================================================================
public Action CmdHatRand(int client, int args)
{
	if( g_bCvarAllow )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			RemoveHat(i);
		}

		int last = g_iCvarRand;
		g_iCvarRand = 1;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsValidClient(i) )
			{
				CreateHat(i, -1);
			}
		}

		g_iCvarRand = last;
	}
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatclient
// ====================================================================================================
public Action CmdHatClient(int client, int args)
{
	if( args == 0 )
	{
		ReplyToCommand(client, "Usage: sm_hatclient <#userid|name> [hat name or hat index: 0-128 (MAX_HATS)].");
		return Plugin_Handled;
	}

	char sArg[32], target_name[MAX_TARGET_LENGTH];
	GetCmdArg(1, sArg, sizeof(sArg));

	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if( (target_count = ProcessTargetString(
		sArg,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE, /* Only allow alive players */
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0 )
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	int index = -1;
	if( args == 2 )
	{
		GetCmdArg(2, sArg, sizeof(sArg));

		if( strlen(sArg) > 3 )
		{
			for( int i = 0; i < g_iCount; i++ )
			{
				if( strcmp(g_sNames[i], sArg, false) == 0 )
				{
					index = i;
					break;
				}
			}
		} else {
			index = StringToInt(sArg);
		}
	}
	else
	{
		index = GetRandomInt(0, g_iCount - 1);
	}

	for( int i = 0; i < target_count; i++ )
	{
		if( GetClientTeam(target_list[i]) == 2 )
		{
			RemoveHat(target_list[i]);
			CreateHat(target_list[i], index);
			ReplyToCommand(client, "[Hat] Set '%N' to '%s'", target_list[i], g_sNames[index]);
		}
	}

	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatc / sm_hatoffc
// ====================================================================================================
public Action CmdHatTarget(int client, int args)
{
	if( g_bCvarAllow )
		ShowPlayerList(client);
	return Plugin_Handled;
}

public Action CmdHatOffTarget(int client, int args)
{
	if( g_bCvarAllow )
	{
		g_bMenuType[client] = true;
		ShowPlayerList(client);
	}
	return Plugin_Handled;
}

void ShowPlayerList(int client)
{
	if( client && IsClientInGame(client) )
	{
		char sTempA[4], sTempB[MAX_NAME_LENGTH];
		Menu menu = new Menu(PlayerListMenu);

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsValidClient(i) )
			{
				IntToString(GetClientUserId(i), sTempA, sizeof(sTempA));
				GetClientName(i, sTempB, sizeof(sTempB));
				menu.AddItem(sTempA, sTempB);
			}
		}

		if( g_bMenuType[client] )
			menu.SetTitle("Select player to disable hats:");
		else
			menu.SetTitle("Select player to change hats:");
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int PlayerListMenu(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
	{
		delete menu;
	}
	else if( action == MenuAction_Select )
	{
		char sTemp[8];
		menu.GetItem(index, sTemp, sizeof(sTemp));
		int target = StringToInt(sTemp);
		target = GetClientOfUserId(target);

		if( g_bMenuType[client] )
		{
			g_bMenuType[client] = false;
			g_bBlocked[target] = !g_bBlocked[target];

			if( g_bBlocked[target] == false )
			{
				if( IsValidClient(target) )
				{
					RemoveHat(target);
					CreateHat(target);

					char name[MAX_NAME_LENGTH];
					GetClientName(target, name, sizeof(name));
					CPrintToChat(client, "%s%T", CHAT_TAG, "Hat_Unblocked", client, name);
				}
			}
			else
			{
				char name[MAX_NAME_LENGTH];
				GetClientName(target, name, sizeof(name));
				GetClientAuthId(target, AuthId_Steam2, g_sSteamID[target], sizeof(g_sSteamID[]));
				CPrintToChat(client, "%s%T", CHAT_TAG, "Hat_Blocked", client, name);
				RemoveHat(target);
			}
		}
		else
		{
			if( IsValidClient(target) )
			{
				g_iTarget[client] = GetClientUserId(target);

				ShowMenu(client);
			}
		}
	}

	return 0;
}

// ====================================================================================================
//					sm_hatadd
// ====================================================================================================
public Action CmdHatAdd(int client, int args)
{
	if( !g_bCvarAllow )
		return Plugin_Handled;

	if( args == 1 )
	{
		if( g_iCount < MAX_HATS )
		{
			char sTemp[64], sKey[4];
			GetCmdArg(1, sTemp, sizeof(sTemp));

			if( FileExists(sTemp, true) )
			{
				strcopy(g_sModels[g_iCount], sizeof(g_sModels[]), sTemp);
				g_vAng[g_iCount] = view_as<float>({ 0.0, 0.0, 0.0 });
				g_vPos[g_iCount] = view_as<float>({ 0.0, 0.0, 0.0 });
				g_fSize[g_iCount] = 1.0;

				KeyValues hFile = OpenConfig();
				IntToString(g_iCount+1, sKey, sizeof(sKey));
				hFile.JumpToKey(sKey, true);
				hFile.SetString("mod", sTemp);
				SaveConfig(hFile);
				delete hFile;
				g_iCount++;
				ReplyToCommand(client, "%sAdded hat '\05%s\x03' %d/%d", CHAT_TAG, sTemp, g_iCount, MAX_HATS);

				if( g_bTranslation )
				{
					ReplyToCommand(client, "%sYou must add the translation for this hat or the plugin will break.", CHAT_TAG);
				}
			}
			else
				ReplyToCommand(client, "%sCould not find the model '\05%s'. Not adding to config.", CHAT_TAG, sTemp);
		}
		else
		{
			ReplyToCommand(client, "%sReached maximum number of hats (%d)", CHAT_TAG, MAX_HATS);
		}
	}
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatdel
// ====================================================================================================
public Action CmdHatDel(int client, int args)
{
	if( !g_bCvarAllow )
		return Plugin_Handled;

	if( args == 1 )
	{
		char sTemp[64];
		int index;
		bool bDeleted;

		GetCmdArg(1, sTemp, sizeof(sTemp));
		if( strlen(sTemp) < 4 )
		{
			index = StringToInt(sTemp);
			if( index < 1 || index >= (g_iCount + 1) )
			{
				ReplyToCommand(client, "%sCannot find the hat index %d, values between 1 and %d", CHAT_TAG, index, g_iCount);
				return Plugin_Handled;
			}
			index--;
			strcopy(sTemp, sizeof(sTemp), g_sModels[index]);
		}
		else
		{
			index = 0;
		}

		char sModel[64], sKey[4];
		KeyValues hFile = OpenConfig();

		for( int i = index; i < MAX_HATS; i++ )
		{
			IntToString(i+1, sKey, sizeof(sKey));
			if( hFile.JumpToKey(sKey) )
			{
				if( bDeleted )
				{
					IntToString(i, sKey, sizeof(sKey));
					hFile.SetSectionName(sKey);

					strcopy(g_sModels[i-1], sizeof(g_sModels[]), g_sModels[i]);
					strcopy(g_sNames[i-1], sizeof(g_sNames[]), g_sNames[i]);
					g_vAng[i-1] = g_vAng[i];
					g_vPos[i-1] = g_vPos[i];
					g_fSize[i-1] = g_fSize[i];
				}
				else
				{
					hFile.GetString("mod", sModel, sizeof(sModel));
					if( StrContains(sModel, sTemp) != -1 )
					{
						ReplyToCommand(client, "%sYou have deleted the hat '\x05%s\x03'", CHAT_TAG, sModel);
						hFile.DeleteKey(sTemp);

						g_iCount--;
						bDeleted = true;

						if( g_bTranslation == false )
						{
							g_hMenu.RemoveItem(i);
						}
						else
						{
							for( int x = 1; x <= MAXPLAYERS; x++ )
							{
								if( g_hMenus[x] != null )
								{
									g_hMenus[x].RemoveItem(i);
								}
							}
						}
					}
				}
			}

			hFile.Rewind();
			if( i == MAX_HATS - 1 )
			{
				if( bDeleted )
					SaveConfig(hFile);
				else
					ReplyToCommand(client, "%sCould not delete hat, did not find model '\x05%s\x03'", CHAT_TAG, sTemp);
			}
		}
		delete hFile;
	}
	else
	{
		int index = g_iSelected[client];

		TranslateHatName(client, index);
	}
	return Plugin_Handled;
}

void TranslateHatName(int client, int index)
{
	if( g_bTranslation == false )
	{
		CPrintToChat(client, "%s%T", CHAT_TAG, "Hat_Wearing", client, g_sNames[index]);
	}
	else
	{
		static char sMsg[128];
		FormatEx(sMsg, sizeof(sMsg), "%s", g_sModels[index]);
		int lang = GetClientLanguage(client);

		if( IsTranslatedForLanguage(sMsg, lang) == true )
		{
			Format(sMsg, sizeof(sMsg), "%T", sMsg, client);
			CPrintToChat(client, "%s%T", CHAT_TAG, "Hat_Wearing", client, sMsg);
		} else {
			FormatEx(sMsg, sizeof(sMsg), "Hat %d", index + 1);
			if( IsTranslatedForLanguage(sMsg, lang) == true )
			{
				Format(sMsg, sizeof(sMsg), "%T", sMsg, client);
				CPrintToChat(client, "%s%T", CHAT_TAG, "Hat_Wearing", client, sMsg);
			} else {
				CPrintToChat(client, "%s%T", CHAT_TAG, "Hat_Wearing", client, g_sNames[index]);
			}
		}
	}
}

// ====================================================================================================
//					sm_hatlist
// ====================================================================================================
public Action CmdHatList(int client, int args)
{
	for( int i = 0; i < g_iCount; i++ )
		ReplyToCommand(client, "%d) %s", i+1, g_sModels[i]);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatload
// ====================================================================================================
public Action CmdHatLoad(int client, int args)
{
	if( g_bCvarAllow && IsValidClient(client) )
	{
		int selected = g_iSelected[client];
		PrintToChat(client, "%sLoaded hat '\x05%s\x03' on all players.", CHAT_TAG, g_sModels[selected]);

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsValidClient(i) )
			{
				RemoveHat(i);
				CreateHat(i, selected);
			}
		}
	}
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatsave
// ====================================================================================================
public Action CmdHatSave(int client, int args)
{
	if( g_bCvarAllow && IsValidClient(client) )
	{
		int entity = g_bCvarWall ? g_iHatWalls[client] : g_iHatIndex[client];
		if( IsValidEntRef(entity) )
		{
			KeyValues hFile = OpenConfig();
			int index = g_iSelected[client];

			char sTemp[4];
			IntToString(index+1, sTemp, sizeof(sTemp));
			if( hFile.JumpToKey(sTemp) )
			{
				float vAng[3], vPos[3];
				float fSize;

				GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
				hFile.SetVector("ang", vAng);
				hFile.SetVector("loc", vPos);
				g_vAng[index] = vAng;
				g_vPos[index] = vPos;

				if( g_bLeft4Dead2 )
				{
					entity = g_iHatIndex[client];
					if( IsValidEntRef(entity) )
					{
						fSize = GetEntPropFloat(entity, Prop_Send, "m_flModelScale");
						if( fSize == 1.0 )
						{
							if( hFile.GetFloat("size", 999.9) != 999.9 )
								hFile.DeleteKey("size");
						}
						else
							hFile.SetFloat("size", fSize);

						g_fSize[index] = fSize;
					}
				}

				SaveConfig(hFile);
				PrintToChat(client, "%sSaved '\x05%s\x03' hat origin and angles.", CHAT_TAG, g_sModels[index]);
			}
			else
			{
				PrintToChat(client, "%s\x04Warning: \x03Could not save '\x05%s\x03' hat origin and angles.", CHAT_TAG, g_sModels[index]);
			}
			delete hFile;
		}
	}

	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatang
// ====================================================================================================
public Action CmdAng(int client, int args)
{
	if( g_bCvarAllow )
		ShowAngMenu(client);
	return Plugin_Handled;
}

void ShowAngMenu(int client)
{
	if( !IsValidClient(client) )
	{
		CPrintToChat(client, "%s%T", CHAT_TAG, "No Access", client);
		return;
	}

	Menu menu = new Menu(AngMenuHandler);

	menu.AddItem("", "X + 10.0");
	menu.AddItem("", "Y + 10.0");
	menu.AddItem("", "Z + 10.0");
	menu.AddItem("", "Reset");
	menu.AddItem("", "X - 10.0");
	menu.AddItem("", "Y - 10.0");
	menu.AddItem("", "Z - 10.0");

	menu.SetTitle("Set hat angles.");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int AngMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
		delete menu;
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowAngMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		if( IsValidClient(client) )
		{
			ShowAngMenu(client);

			float vAng[3];
			int entity;
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsValidClient(i) )
				{
					entity = g_bCvarWall ? g_iHatWalls[i] : g_iHatIndex[i];
					if( IsValidEntRef(entity) )
					{
						GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

						switch( index )
						{
							case 0: vAng[0] += 10.0;
							case 1: vAng[1] += 10.0;
							case 2: vAng[2] += 10.0;
							case 3: vAng = view_as<float>({0.0,0.0,0.0});
							case 4: vAng[0] -= 10.0;
							case 5: vAng[1] -= 10.0;
							case 6: vAng[2] -= 10.0;
						}

						TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);
					}
				}
			}

			CPrintToChat(client, "%sNew hat angles: %f %f %f", CHAT_TAG, vAng[0], vAng[1], vAng[2]);
		}
	}

	return 0;
}

// ====================================================================================================
//					sm_hatpos
// ====================================================================================================
public Action CmdPos(int client, int args)
{
	if( g_bCvarAllow )
		ShowPosMenu(client);
	return Plugin_Handled;
}

void ShowPosMenu(int client)
{
	if( !IsValidClient(client) )
	{
		CPrintToChat(client, "%s%T", CHAT_TAG, "No Access", client);
		return;
	}

	Menu menu = new Menu(PosMenuHandler);

	menu.AddItem("", "X + 0.5");
	menu.AddItem("", "Y + 0.5");
	menu.AddItem("", "Z + 0.5");
	menu.AddItem("", "Reset");
	menu.AddItem("", "X - 0.5");
	menu.AddItem("", "Y - 0.5");
	menu.AddItem("", "Z - 0.5");

	menu.SetTitle("Set hat position.");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int PosMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
		delete menu;
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowPosMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		if( IsValidClient(client) )
		{
			ShowPosMenu(client);

			float vPos[3];
			int entity;
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsValidClient(i) )
				{
					entity = g_bCvarWall ? g_iHatWalls[i] : g_iHatIndex[i];
					if( IsValidEntRef(entity) )
					{
						GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

						switch( index )
						{
							case 0: vPos[0] += 0.5;
							case 1: vPos[1] += 0.5;
							case 2: vPos[2] += 0.5;
							case 3: vPos = view_as<float>({0.0,0.0,0.0});
							case 4: vPos[0] -= 0.5;
							case 5: vPos[1] -= 0.5;
							case 6: vPos[2] -= 0.5;
						}

						TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}

			CPrintToChat(client, "%sNew hat origin: %f %f %f", CHAT_TAG, vPos[0], vPos[1], vPos[2]);
		}
	}

	return 0;
}

// ====================================================================================================
//					sm_hatsize
// ====================================================================================================
public Action CmdHatSize(int client, int args)
{
	if( g_bCvarAllow )
		ShowSizeMenu(client);
	return Plugin_Handled;
}

void ShowSizeMenu(int client)
{
	if( !IsValidClient(client) )
	{
		CPrintToChat(client, "%s%T", CHAT_TAG, "No Access", client);
		return;
	}

	if( !g_bLeft4Dead2 )
	{
		CPrintToChat(client, "%sCannot set hat size in L4D1.", CHAT_TAG);
		return;
	}

	Menu menu = new Menu(SizeMenuHandler);

	menu.AddItem("", "+ 0.1");
	menu.AddItem("", "- 0.1");
	menu.AddItem("", "+ 0.5");
	menu.AddItem("", "- 0.5");
	menu.AddItem("", "+ 1.0");
	menu.AddItem("", "- 1.0");
	menu.AddItem("", "Reset");

	menu.SetTitle("Set hat size.");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SizeMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
		delete menu;
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowSizeMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		if( IsValidClient(client) )
		{
			ShowSizeMenu(client);

			float fSize;
			int entity;
			for( int i = 1; i <= MaxClients; i++ )
			{
				entity = g_iHatIndex[i];
				if( IsValidEntRef(entity) )
				{
					fSize = GetEntPropFloat(entity, Prop_Send, "m_flModelScale");

					switch( index )
					{
						case 0: fSize += 0.1;
						case 1: fSize -= 0.1;
						case 2: fSize += 0.5;
						case 3: fSize -= 0.5;
						case 4: fSize += 1.0;
						case 5: fSize -= 1.0;
						case 6: fSize = 1.0;
					}

					SetEntPropFloat(entity, Prop_Send, "m_flModelScale", fSize);
				}
			}

			CPrintToChat(client, "%sNew hat scale: %f", CHAT_TAG, fSize);
		}
	}

	return 0;
}



// ====================================================================================================
//					HAT STUFF
// ===================================================================================================
void RemoveHat(int client)
{
	// Hat entity
	int entity = g_iHatIndex[client];
	g_iHatIndex[client] = 0;

	if( IsValidEntRef(entity) )
		RemoveEntity(entity);

	// Hidden entity
	entity = g_iHatWalls[client];
	g_iHatWalls[client] = 0;

	if( IsValidEntRef(entity) )
		RemoveEntity(entity);
}

bool CreateHat(int client, int index = -1)
{
	if( g_bBlocked[client] || g_bHatOff[client] || IsValidEntRef(g_iHatIndex[client]) == true || IsValidClient(client) == false )
		return false;

	if( index == -1 ) // Random hat
	{
		if( g_iCvarRand == 0 ) return false;
		if( g_iType[client] == -1 ) return false;

		if( g_iCvarFlags != 0 )
		{
			if( IsFakeClient(client) )
				return false;

			int flags = GetUserFlagBits(client);
			if( !(flags & ADMFLAG_ROOT) && !(flags & g_iCvarFlags) )
				return false;
		}

		index = GetRandomInt(0, g_iCount -1);
		g_iType[client] = index + 1;
	}
	else if( index == -2 ) // Previous random hat
	{
		if( g_iCvarRand != 2 ) return false;

		index = g_iType[client];
		if( index == -1 ) return false;

		if( index == 0 )
		{
			index = GetRandomInt(1, g_iCount);
		}

		index--;
	}
	else if( index == -3 ) // Saved hats
	{
		index = g_iType[client];
		if( index == -1 ) return false;

		if( index == 0 )
		{
			if( IsFakeClient(client) == true )
				return false;
			else
			{
				if(  g_iCvarRand == 0 ) return false;

				index = GetRandomInt(1, g_iCount);
			}
		}

		index--;
	}
	else // Specified hat
	{
		g_iType[client] = index + 1;
	}

	if( g_iCvarSave && !IsFakeClient(client) )
	{
		char sNum[4];
		IntToString(index + 1, sNum, sizeof(sNum));
		SetClientCookie(client, g_hCookie, sNum);
	}

	// Fix showing glow through walls, break glow inheritance by attaching hats to info_target.
	// Method by "Marttt": https://forums.alliedmods.net/showpost.php?p=2737781&postcount=21
	int target;

	if( g_bCvarWall )
	{
		target = CreateEntityByName("info_target");
		DispatchSpawn(target);
	}

	int entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		SetEntityModel(entity, g_sModels[index]);
		DispatchSpawn(entity);
		if( g_bLeft4Dead2 )
		{
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", g_fSize[index]);
		}

		if( g_bCvarWall )
		{
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", target);
			TeleportEntity(target, g_vPos[index], NULL_VECTOR, NULL_VECTOR);

			SetVariantString("!activator");
			AcceptEntityInput(target, "SetParent", client);
			SetVariantString("eyes");
			AcceptEntityInput(target, "SetParentAttachment");
			TeleportEntity(target, g_vPos[index], NULL_VECTOR, NULL_VECTOR);

			g_iHatWalls[client] = EntIndexToEntRef(target);
		} else {
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", client);
			SetVariantString("eyes");
			AcceptEntityInput(entity, "SetParentAttachment");
			TeleportEntity(entity, g_vPos[index], NULL_VECTOR, NULL_VECTOR);
		}

		// Lux
		AcceptEntityInput(entity, "DisableCollision");
		SetEntProp(entity, Prop_Send, "m_noGhostCollision", 1, 1);
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0x0004);
		SetEntPropVector(entity, Prop_Send, "m_vecMins", view_as<float>({0.0, 0.0, 0.0}));
		SetEntPropVector(entity, Prop_Send, "m_vecMaxs", view_as<float>({0.0, 0.0, 0.0}));
		// Lux

		TeleportEntity(g_bCvarWall ? target : entity, g_vPos[index], g_vAng[index], NULL_VECTOR);
		SetEntProp(entity, Prop_Data, "m_iEFlags", 0);

		if( g_iCvarOpaq )
		{
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 255, 255, 255, g_iCvarOpaq);
		}

		g_iSelected[client] = index;
		g_iHatIndex[client] = EntIndexToEntRef(entity);

		if( !g_bHatView[client] )
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);

		TranslateHatName(client, index);

		SpectatorHatHooks();
		return true;
	}

	return false;
}

void ExternalView(int client)
{
	if( g_fCvarChange && g_bLeft4Dead2 )
	{
		g_bExternalState[client] = false;

		EventView(client, true);

		// Survivor Thirdperson plugin sets 99999.3.
		if( GetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView") == 99999.3 )
			return;

		delete g_hTimerView[client];
		g_hTimerView[client] = CreateTimer(g_fCvarChange + (g_fCvarChange >= 2.0 ? 0.4 : 0.2), TimerEventView, GetClientUserId(client));

		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", GetGameTime() + g_fCvarChange);
	}
}

public Action TimerEventView(Handle timer, any client)
{
	client = GetClientOfUserId(client);
	if( client )
	{
		EventView(client, false);
		g_hTimerView[client] = null;
	}

	return Plugin_Continue;
}

public Action Hook_SetTransmit(int entity, int client)
{
	if( EntIndexToEntRef(entity) == g_iHatIndex[client] )
		return Plugin_Handled;
	return Plugin_Continue;
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}



// ====================================================================================================
//					COLORS.INC REPLACEMENT
// ====================================================================================================
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
//					TRANSLATE CODE
// ====================================================================================================
// If using this code, you must replace the "\" character with "/" in the new "*phrases.txt.new" file.
stock void TranslateHatnames()
{
	int maxIndex = 95; // Searches from "1" to maxIndex (including max) in the "hatnames" file. Matches to the data config.

	char sLang[4] = "zho/"; // Language folder to translate. Blank for "en"
	char sText[256];
	char sModel[PLATFORM_MAX_PATH];
	char sTran[PLATFORM_MAX_PATH];
	char sData[PLATFORM_MAX_PATH];
	char sSave[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, sSave, sizeof sSave, "translations/%shatnames.phrases.txt.new", sLang);
	BuildPath(Path_SM, sTran, sizeof sTran, "translations/%shatnames.phrases.txt", sLang);
	BuildPath(Path_SM, sData, sizeof sData, "data/l4d_hats.cfg");

	KeyValues hTran = new KeyValues("Phrases");
	KeyValues hData = new KeyValues("Models");
	KeyValues hSave = new KeyValues("Phrases");

	hTran.ImportFromFile(sTran);
	hData.ImportFromFile(sData);

	char sIndex[16];

	for( int i = 1; i <= maxIndex; i++ )
	{
		IntToString(i, sIndex, sizeof sIndex);
		hData.JumpToKey(sIndex);
		hData.GetString("mod", sModel, sizeof(sModel));
		ReplaceString(sModel, sizeof sModel, "/", "\\");

		Format(sIndex, sizeof sIndex, "Hat %d", i);
		hTran.JumpToKey(sIndex);
		hTran.GetString(sLang, sText, sizeof(sText));

		PrintToServer("%02d (%s) [%s] == [%s]", i, sIndex, sModel, sText);

		hSave.JumpToKey(sModel, true);
		hSave.SetString(sLang, sText);

		hTran.Rewind();
		hData.Rewind();
		hSave.Rewind();
	}

	hSave.ExportToFile(sSave);

	delete hTran;
	delete hData;
	delete hSave;
}