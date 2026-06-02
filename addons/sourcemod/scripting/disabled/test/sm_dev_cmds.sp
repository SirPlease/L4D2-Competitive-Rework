/*
*	Dev Cmds
*	Copyright (C) 2026 Silvers
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



#define PLUGIN_VERSION 		"1.54"

/*=======================================================================================
	Plugin Info:

*	Name	:	[ANY] Dev Cmds
*	Author	:	SilverShot
*	Descrp	:	Provides a heap of commands for admins/developers to use.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=187566
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.54 (14-Mar-2026)
	- Added command "sm_setdmg" to apply specific damage to an entity.

1.53 (17-Feb-2026)
	- L4D/2: Added command "sm_temp" to set temporary health on a player.
	- Fixed throwing errors for games which have no "m_iHammerID". Thanks to "caxanga334" for reporting.

1.52 (22-Sep-2024)
	- Changed commands "sm_setang", "sm_setpos", "sm_tele" and "sm_tel" to allow placing "?" in any given XYZ vector to ignore and use the current targets value. Requested by "Tonblader".

1.51 (17-Jun-2024)
	- Fixed command "sm_weapons" showing your own held weapon, instead of the targets.

1.50 (05-Mar-2024)
	- Added a few more "m_h*" variables to read the entity index instead of reference number. Probably only for L4D/2 series.

1.49 (22-Nov-2023)
	- Added command "sm_delents" to delete entities of a certain classnames. Allows using * wildcard to match various entities for example "weapon_*" can be used.
	- Changed command "sm_near" to also show the targetname.

1.48 (19-Feb-2023)
	- Added command "sm_hexcols" to print a list of hex colors to chat. Requested by "Marttt".

1.47 (10-Jan-2023)
	- Added command "sm_gamerules" to read/write to the gamerules proxy.
	- Added support for reading/writing to GameRules. Thanks to "Marttt" for the initial code. Requested by "caxanga334".
	- Plugin now requires SourceMod 1.11 or newer. Using some natives that only appear in SM 1.11.

1.46 (28-Oct-2022)
	- Added command "sm_vertex" to display the vecMins and vecMaxs of an entity.
	- Fixed command "sm_listens" to displaying full details.
	- L4D1/2: Fixed "sm_zspawnv" not pre-caching Special Infected models, also validates model paths and attempts to cache unknown ones. Thanks to "Tonblader" for reporting.

1.45 (10-Aug-2022)
	- Changed command "sm_del" to no longer delete clients.

1.44 (17-Jul-2022)
	- Fixed compile warnings on SM 1.11 when using SMLib.

1.43 (16-Jul-2022)
	- Changed "sm_prop*" commands to allow editing members elements for example "m_iAmmo.005" to modify element array 005. Requested by "Sreaper".
	- Added list of known entity property keys to better get or set their values.

1.42 (01-Aug-2022)
	- Fixed command "sm_clients" throwing an error if a client was not in game.

1.41 (24-Jun-2022)
	- Fixed command "sm_playtime" not showing playtime when the server is empty.

1.40 (24-Jun-2022)
	- Fixed command "sm_playtime" sometimes breaking and not showing any playtime.

1.39 (20-Jun-2022)
	- Added command "sm_playtime" to show how long players have been playing.
	- Changed command "sm_clients" formatting to be clearer.

1.38 (09-Jun-2022)
	- Added command "sm_changes" to show how many map changes have occurred.

1.37 (03-Jun-2022)
	- Fixed command "sm_uptime" not displaying the correct time.

1.36 (03-Jun-2022)
	- Changed the method for the command "sm_uptime" to show since the plugin was loaded since GetGameTime() resets to 0.0 on map change.

1.35 (01-Jun-2022)
	- Added command "sm_aimpos" to get the vector position where the crosshair is aiming.
	- Added command "sm_uptime" to display how long the server has been up. Thanks to "Impact123" for the code: https://forums.alliedmods.net/showthread.php?t=182012

1.34 (10-May-2022)
	- Reverted command "sm_prop*" to before last update, removing the "m_h" check in the keynames, due to breaking non-entity fields.

1.33 (25-Apr-2022)
	- Changed commands "sm_prop*" to get or set entity indexes which contain "m_h" in the keyname. Requested by "Sreaper".
	- Changed command "sm_users" to count the last UserID better.

1.32 (10-Apr-2022)
	- Changed command "sm_ent" to allow aiming at clients. Requested by "Sreaper".
	- Changed command "sm_weapons" to include the currently held object/item/weapon.

1.31 (14-Dec-2021)
	- Added command "sm_users" to report total bots and clients that connected and the last UserID index.
	- Changed command "sm_listens" to output more information about sounds. Thanks to "Marttt" for writing.

1.30 (23-Nov-2021)
	- Blocked various in-game commands from being used on the server.
	- Changed various commands to use "ReplyToCommand". Requested by "Dragokas".

1.29 (10-Nov-2021)
	- Added command "sm_viewmodel" to return a clients viewmodel entity index.
	- Changed command "sm_attachments" to display attachments on entities. Requested by "Marttt".
	- Fixed command "sm_dele" crashing the server when no entity was provided. Thanks to "Marttt" for reporting.

1.28 (06-Nov-2021)
	- Fixed possible invalid entity when using "sm_propent". Thanks to "Shku" for reporting.

1.27 (04-Nov-2021)
	- Added command "sm_rngc" to randomly execute specified commands if the chance is met, client command. Requested by "Tonblader".
	- Added command "sm_rngf" to randomly execute specified commands if the chance is met, fake client command. Requested by "Tonblader".
	- Added command "sm_rngs" to randomly execute specified commands if the chance is met, server command. Requested by "Tonblader".
	- Added command "sm_wearables" for TF2 to list a players cosmetic items. Requested by "Shku".
	- Changed "sm_propent" to accept target filters. Thanks to "Maliwolf" for coding.

1.26 (27-Oct-2021)
	- Added command "sm_tele" to teleport clients to aim position or specific vector. Requested by "Dragokas".
	- Added command "sm_collision" to toggle collision on a specified entity. Requested by "canadianjeff". Thanks to "Dragokas" for the stock.
	- Added commands "sm_solid" and "sm_solidf" to return the solid type and solid flags from a value.
	- L4D1 & L4D2: Changed command "sm_nospawn" to block common spawning. Thanks to "Dragokas" for reporting.

1.25 (13-Sep-2021)
	- Added command "sm_getspeed" to return a players current speed value.
	- Added command "sm_listens" to toggle printing all sounds being played.
	- Added command "sm_delweps" to delete weapons from yourself or the targeted clients.
	- Added command "sm_bringents" to teleport specified entities by classname to around the player.
	- L4D2: Added command "sm_sc" to change the gamemode to Scavenge.

1.24 (06-Sep-2021)
	- Added command "sm_attachments" to display all attachments on a specific client.
	- Added command "sm_emit" to play a sound from your client.

1.23 (11-Aug-2021)
	- Added commands "sm_bit" and "sm_val" to get and return values from: "1<<20" to "1048576" and "1048577" to "(1<<0); (1<<20)" for example.
	- Added command "sm_dmg" to return SDKHooks damage flags from a value. For example "sm_dmg 9" returns "DMG_CRUSH (1<<0); DMG_BURN (1<<3)".
	- Added command "sm_adm" to toggle between ROOT and BAN admin flags (or specified target flags). Requires ROOT to work. e.g: "sm_adm BAN KICK".
	- Changed command "sm_anim" to watch sequence numbers on every frame and display only when they change, until toggled off.

1.22 (29-Jul-2021)
	- L4D1 & L4D2: Changed command "sm_zspawnv" to accept a skin parameter for the models.

1.21 (25-Jul-2021)
	- L4D1 & L4D2: Changed command "sm_zspawnv" to accept the modelname. This does not precache the model and a server crash possible for non-cached models. Requested by "Tonblader".
	- Usage: "sm_zspawnv boomer posX posY posZ modelname" or "sm_zspawnv boomer posX posY posZ andX angY andZ modelname". Modelname is optional.

1.20 (22-Jul-2021)
	- L4D1 & L4D2: Fixed command "sm_zspawnv" not spawning in the correct direction. Thanks to "Tonblader" for reporting.

1.19 (05-Jul-2021)
	- L4D1 & L4D2: Added command "sm_bots" to spawn a Survivor bot.

1.18 (04-Jul-2021)
	- Removed requirement of being alive for some commands: "sm_ccmd", "sm_fcmd", "sm_nv", "sm_ledge". Thanks to "noto3" for reporting.

1.17 (01-Jul-2021)
	- L4D1 and L4D2: Added command "sm_zspawnv" to spawn infected and special infected specifying pos and ang. Requested by "Tonblader" and "nataa123".

1.16 (16-Jun-2021)
	- Changed commands "sm_setang", "sm_setpos", "sm_tel" and "sm_viewr" and set speed to 0 on teleport. Requested by "Tonblader".

1.15 (15-Feb-2021)
	- Changed "sm_count" to accept a classname to search for. Requested by "canadianjeff".

1.14 (30-Sep-2020)
	- Fixed compile errors on SM 1.11.

1.13 (20-Sep-2020)
	- Added command "sm_setpos" to set target(s) origin position. Requested by "Tonblader".
	- Fixed command "sm_cheats" not working in all games.
	- Increased model string length for "sm_ent" and "sm_ente" commands.

1.12 (07-Jun-2020)
	- Added command "sm_setang" to set target(s) view angles. Requested by "Tonblader".

1.11 (10-May-2020)
	- Various changes to tidy up code.

1.10 (25-Mar-2020)
	- Changed "sm_range" to add an optional arg for specifying an entity.
	- Fixed command "sm_cheats" not toggling "sv_cheats".
	- Some text changes from previously added commands.

1.9 (19-Mar-2020)
	Update with changes provided by "Dragokas":
	- Added command "sm_ice" to freeze any client/entity from moving.
	- Changed command "sm_anim" to allow getting the sequence for a specified entity.
	- Fixed command "sm_stopang" from not repeating.
	- Fixed commands "sm_halt", "sm_hold" and "sv_cheats" from not accurately detecting the cvar setting being changed.

1.8 (02-Mar-2020)
	Update by "Dragokas":
	- Appended "sm_find" <classname> <maxdist> (2nd argument filters entities located in specified radius).
	- Added command "sm_damage" <client> - to track damage info dealt to this client or by this client. Use -1 or empty to track everybody.
	- (L4D & L4D2) Added command "sm_nospawn" to prevent all types of infected from spawning.
	- (L4D & L4D2) Added command "sm_slayall" to slay all common and special infected and witches.

	Update by "Silvers":
	- Added command "sm_scmd" to execute a server command.
	- Changed command "sm_count" to work better and sort the classnames list.

1.7 (02-Nov-2019)
	- Fixed copy paste error preventing the plugin from compiling. Thanks to "eyal282" for reporting.

1.6 (01-Nov-2019)
	- Changed "sm_input", "sm_inputent" and "sm_inputme" to accept activator and caller params.
	- Fixed commands "sm_ledge", "sm_spit" and "sm_nv" failing with ProcessTargetString. Thanks to "Marttt".

1.5 (30-Oct-2019)
	- Added command "sm_clients" to list client indexes/userids and some other data.
	- Added command "sm_weapons" to list your own weapons or that of the target you're aiming at or specified index by command arg.
	- Added command "sm_range" to find how far away an object is.
	- Added command "sm_near" to list nearby object classnames.
	- Added various vector commands  provided by "Dragokas": "sm_dist", "sm_distdir", "sm_distfloor", "sm_distroof", "sm_size", "sm_sizee".
	- Changed "sm_ent" and "sm_ente" to add more info. Provided by "Marttt".
	- Changed "sm_box" laser outlines to use smlib draw box with correct angles matrix rotation. Provided by "disawar1".
	- The "sm_box" changes work when the smlib include is present, or defaults to old version, no edits required.
	- Various fixes and changes.

1.4.1 (28-Jun-2019)
	- Changed PrecacheParticle method.

1.4 (01-Jun-2019)
	- Added "sm_anim" to show your players animation sequence number (for 6 * 0.5 seconds).
	- Changed "sm_tel" to also accept angles when teleporting.
	- Changed "sm_ente" to work from the server console.

1.3 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.2 (09-Aug-2013)
	- Reverted the change to "sm_alloff".
	- Changed "sm_fcmd" to allow command arguments, Usage: sm_fcmd <#userid|name> <command> [args].

1.1 (22-Jun-2012)
	- Added "sm_findname" to list entities by matching a partial targetname.
	- Changed "sm_modlist" to save the file as "models_mapname.txt".
	- Changed "sm_input", "sm_inputent" and "sm_inputme" to accept parameters.
	- Changed "sm_alloff" to not toggle the director or sb_hold_position.
	- Fixed "sm_find" throwing errors for non-networked entities.

1.0 (15-Jun-2012)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "Don't Fear The Reaper" - For the sm_slaycommon and sm_slaywitches code.

======================================================================================*/

#tryinclude <smlib> // SMLIB - for sm_box. Before newdecls incase using old syntax style.

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define	MAX_OUTPUTS		32
#define RED		 		{255, 0, 0, 255}
#define GREEN			{0, 255, 0, 255}
#define BLUE			{0, 0, 255, 255}

#if !defined _smlib_included
// Taken from smlib
enum
{
	FSOLID_CUSTOMRAYTEST		= 0x0001,	// Ignore solid type + always call into the entity for ray tests
	FSOLID_CUSTOMBOXTEST		= 0x0002,	// Ignore solid type + always call into the entity for swept box tests
	FSOLID_NOT_SOLID			= 0x0004,	// Are we currently not solid?
	FSOLID_TRIGGER				= 0x0008,	// This is something may be collideable but fires touch functions
											// even when it's not collideable (when the FSOLID_NOT_SOLID flag is set)
	FSOLID_NOT_STANDABLE		= 0x0010,	// You can't stand on this
	FSOLID_VOLUME_CONTENTS		= 0x0020,	// Contains volumetric contents (like water)
	FSOLID_FORCE_WORLD_ALIGNED	= 0x0040,	// Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
	FSOLID_USE_TRIGGER_BOUNDS	= 0x0080,	// Uses a special trigger bounds separate from the normal OBB
	FSOLID_ROOT_PARENT_ALIGNED	= 0x0100,	// Collisions are defined in root parent's local coordinate space
	FSOLID_TRIGGER_TOUCH_DEBRIS	= 0x0200,	// This trigger will touch debris objects

	FSOLID_MAX_BITS	= 10
};

enum
{
	SOLID_NONE			= 0,	// no solid model
	SOLID_BSP			= 1,	// a BSP tree
	SOLID_BBOX			= 2,	// an AABB
	SOLID_OBB			= 3,	// an OBB (not implemented yet)
	SOLID_OBB_YAW		= 4,	// an OBB, constrained so that it can only yaw
	SOLID_CUSTOM		= 5,	// Always call into the entity for tests
	SOLID_VPHYSICS		= 6,	// solid vphysics object, get vcollide from the model and collide with that
	SOLID_LAST,
};
#endif



float g_vSavedPos[3];
bool g_bFirst = true;
int g_sprite;

bool g_bLateLoad, g_bDirector = true, g_bAll, g_bNB, g_bNospawn, g_bDamage;
int g_iGAMETYPE, g_iEntsSpit[MAXPLAYERS], g_iLedge[MAXPLAYERS], g_iDamageRequestor, g_iTotalBots, g_iTotalPlays, g_iLastUserID, g_iGameTime, g_iPlayers, g_iPlayTime, g_iPlayedTime, g_iMapChanges;
float g_vAng[MAXPLAYERS+1][3], g_vPos[MAXPLAYERS+1][3];

ConVar sb_hold_position, sb_stop, sv_cheats, mp_gamemode, z_background_limit, z_boomer_limit, z_charger_limit, z_common_limit, z_hunter_limit, z_jockey_limit, z_minion_limit, z_smoker_limit, z_spitter_limit, director_no_bosses, director_no_mobs, director_no_specials;
int g_iHaloIndex, g_iLaserIndex, g_iOutputs[MAX_OUTPUTS][2];
char g_sOutputs[MAX_OUTPUTS][64];
StringMap g_hEntityKeys;

EngineVersion g_iEngine;
char g_sGameRulesNet[32], g_sGameRulesClass[32];

// Precache models for spawning (L4D1/2)
static const char g_sModels1[][] =
{
	"models/infected/witch.mdl",
	"models/infected/hulk.mdl",
	"models/infected/smoker.mdl",
	"models/infected/boomer.mdl",
	"models/infected/hunter.mdl"
};

static const char g_sModels2[][] =
{
	"models/infected/witch_bride.mdl",
	"models/infected/spitter.mdl",
	"models/infected/jockey.mdl",
	"models/infected/charger.mdl"
};
enum
{
	GAME_ANY = 1,
	GAME_L4D,
	GAME_L4D2,
	GAME_CSS,
	GAME_TF2
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[ANY] Dev Cmds",
	author = "SilverShot",
	description = "Provides a heap of commands for admins/developers to use.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=187566"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	switch( test )
	{
		case Engine_CSS:			g_iGAMETYPE = GAME_CSS;
		case Engine_CSGO:			g_iGAMETYPE = GAME_CSS;
		case Engine_Left4Dead:		g_iGAMETYPE = GAME_L4D;
		case Engine_Left4Dead2:		g_iGAMETYPE = GAME_L4D2;
		case Engine_TF2:			g_iGAMETYPE = GAME_TF2;
		default:					g_iGAMETYPE = GAME_ANY;
	}

	g_bLateLoad = late;
	g_iEngine = test;

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_dev_cmds",		PLUGIN_VERSION,	"Dev Cmds plugin version.",	FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Commands
	RegAdminCmd("sm_refresh",		CmdRefresh,		ADMFLAG_ROOT, "Refresh plugins (same as 'sm plugins refresh').");
	RegAdminCmd("sm_renew",			CmdRenew,		ADMFLAG_ROOT, "Unload and Refresh plugins (same as 'sm plugins unload_all; sm plugins refresh').");
	RegAdminCmd("sm_unload",		CmdUnload,		ADMFLAG_ROOT, "Unload all plugins (same as 'sm plugins unload_all').");

	RegAdminCmd("sm_round",			CmdRound,		ADMFLAG_ROOT, "Executes 'mp_restartgame 1' to restart round.");
	RegAdminCmd("sm_cheats",		CmdCheats,		ADMFLAG_ROOT, "Toggles sv_cheats.");
	RegAdminCmd("sm_logit",			CmdLogIt,		ADMFLAG_ROOT, "<text>. Logs specified text to 'sourcemod/logs/sm_logit.txt'.");
	RegAdminCmd("sm_gametime",		CmdGameTime,	ADMFLAG_ROOT, "Displays the GetGameTime() float.");
	RegAdminCmd("sm_uptime",		CmdUpTime,		ADMFLAG_ROOT, "Displays how long the server has been up. Maybe inaccurate if server hibernation is active.");
	RegAdminCmd("sm_playtime",		CmdPlayTime,	ADMFLAG_ROOT, "Displays how long players have been playing on the server.");
	RegAdminCmd("sm_changes",		CmdChanges,		ADMFLAG_ROOT, "Displays how many map changes have occurred.");
	RegAdminCmd("sm_createent",		CmdCreateEnt,	ADMFLAG_ROOT, "<classname>. Creates and removes the entity classname, reports success.");

	RegAdminCmd("sm_cv",			CmdCV,			ADMFLAG_ROOT, "<cvar> [value]. Get/Set cvar value without the notify flag.");
	RegAdminCmd("cv",				CmdCV,			ADMFLAG_ROOT, "<cvar> [value]. Get/Set cvar value without the notify flag.");
	RegAdminCmd("sm_e",				CmdECheat,		ADMFLAG_ROOT, "<command> [args]. Executes a cheat command.");
	RegAdminCmd("e",				CmdECheat,		ADMFLAG_ROOT, "<command> [args]. Executes a cheat command.");
	RegAdminCmd("sm_ccmd",			CmdCCmd,		ADMFLAG_ROOT, "<#userid|name> <command> [args]. Executes a client command on the target you specify.");
	RegAdminCmd("sm_fcmd",			CmdFCmd,		ADMFLAG_ROOT, "<#userid|name> <command> [args]. Executes a fake client command on the target you specify.");
	RegAdminCmd("sm_scmd",			CmdSCmd,		ADMFLAG_ROOT, "Executes a server command.");
	RegAdminCmd("sm_rngc",			CmdRngC,		ADMFLAG_ROOT, "<0-100> <command string> chance out of 100 to execute the command string, client command.");
	RegAdminCmd("sm_rngf",			CmdRngF,		ADMFLAG_ROOT, "<0-100> <command string> chance out of 100 to execute the command string, fake client command.");
	RegAdminCmd("sm_rngs",			CmdRngS,		ADMFLAG_ROOT, "<0-100> <command string> chance out of 100 to execute the command string, server command.");

	RegAdminCmd("sm_views",			CmdViewS,		ADMFLAG_ROOT, "Saves your current position and eye angles.");
	RegAdminCmd("sm_viewr",			CmdViewR,		ADMFLAG_ROOT, "Teleports you to the saved position and eye angles.");
	RegAdminCmd("sm_pos",			CmdPosition,	ADMFLAG_ROOT, "Displays your position vector.");
	RegAdminCmd("sm_aimpos",		CmdAimPos,		ADMFLAG_ROOT, "Displays the position vector where your crosshair is aiming.");
	RegAdminCmd("sm_setang",		CmdSetAng,		ADMFLAG_ROOT, "<#userid|name> <vector ang>. Teleport someone to the x y z angles vector specified. Place ? to ignore an XYZ vector and use the targets current value.");
	RegAdminCmd("sm_setpos",		CmdSetPos,		ADMFLAG_ROOT, "<#userid|name> <vector pos>. Teleport someone to the x y z origin vector specified. Place ? to ignore an XYZ vector and use the targets current value.");
	RegAdminCmd("sm_bringents",		CmdBring,		ADMFLAG_ROOT, "<classname> [distance: (default 50)]. Teleport specified entities by classname to around the player. e.g. sm_bringents weapon_rifle.");
	RegAdminCmd("sm_tele",			CmdTele,		ADMFLAG_ROOT, "<#userid|name> [x y z vector pos]. Teleport specified targets to aim location or to the x y z origin vector specified. Place ? to ignore an XYZ vector and use the targets current value.");
	RegAdminCmd("sm_tel",			CmdTeleport,	ADMFLAG_ROOT, "<vector pos> [vector ang]. Teleport yourself to the x y z vector specified. Place ? to ignore an XYZ vector and use the targets current value.");
	RegAdminCmd("sm_range",			CmdRange,		ADMFLAG_ROOT, "[entity] Shows how far away an object is that you're aiming at, or optional arg to specify an entity index.");
	RegAdminCmd("sm_near",			CmdNear,		ADMFLAG_ROOT, "Lists all nearby entities within the specified range. Usage sm_near: [range].");
	RegAdminCmd("sm_dist",			CmdDist,		ADMFLAG_ROOT, "Enter twice to measure distance between the origins you stand on.");
	RegAdminCmd("sm_distdir",		CmdDistDir,		ADMFLAG_ROOT, "Get distance between you and end point of direction you are looking at (considering collision).");
	RegAdminCmd("sm_distfloor",		CmdDistFloor,	ADMFLAG_ROOT, "Get distance between you and floor below you (considering collision).");
	RegAdminCmd("sm_distroof",		CmdDistRoof,	ADMFLAG_ROOT, "Get distance between you and roof above your head (considering collision).");
	RegAdminCmd("sm_size",			CmdSizeMe,		ADMFLAG_ROOT, "Get sizes (Width, Length, Height) of your player.");
	RegAdminCmd("sm_sizee",			CmdSizeTarget,	ADMFLAG_ROOT, "Get sizes (Width, Length, Height) of the entity you are looking at.");

	RegAdminCmd("sm_del",			CmdDel,			ADMFLAG_ROOT, "Deletes the entity your crosshair is over.");
	RegAdminCmd("sm_dele",			CmdDelE,		ADMFLAG_ROOT, "<entity>. Deletes the entity you specify.");
	RegAdminCmd("sm_delents",		CmdDelEnts,		ADMFLAG_ROOT, "<classname> Delete all the entities of a specific classname.");
	RegAdminCmd("sm_ent",			CmdEnt,			ADMFLAG_ROOT, "Displays info about the entity your crosshair is over.");
	RegAdminCmd("sm_ente",			CmdEntE,		ADMFLAG_ROOT, "<entity>. Displays info about the entity you specify.");
	RegAdminCmd("sm_vertex",		CmdVertex,		ADMFLAG_ROOT, "[entity]. Displays vMaxs and vMins bounding box about the specified entity or aimed at entity.");
	RegAdminCmd("sm_box",			CmdBox,			ADMFLAG_ROOT, "[entity]. Displays a beam box around the specified entity or aimed at entity for 10 seconds.");
	RegAdminCmd("sm_find",			CmdFind,		ADMFLAG_ROOT, "<classname> List entity indexes from the given classname.");
	RegAdminCmd("sm_findname",		CmdFindName,	ADMFLAG_ROOT, "<targetname> List entity indexes from a partial targetname.");
	RegAdminCmd("sm_count",			CmdCount,		ADMFLAG_ROOT, "Displays a list of all spawned entity classnames and count. Optional sm_count <classname>");
	RegAdminCmd("sm_modlist",		CmdModList,		ADMFLAG_ROOT, "Saves a list of all the models used on the current map to 'sourcemod/logs/models_<MAPNAME>.txt'.");
	RegAdminCmd("sm_collision",		CmdColli,		ADMFLAG_ROOT, "[entity] Toggles collision on the aimed entity or specified entity index.");
	RegAdminCmd("sm_movetype",		CmdMoveType,	ADMFLAG_ROOT, "[entity] Set the MoveType of an entity.");
	RegAdminCmd("sm_anim",			CmdAnim,		ADMFLAG_ROOT, "[sequence]. Show aimed entities animation sequence number until toggled again or your own if not aimed at entity. Optionally, it can set sequence. Checks every frame and reports changes.");
	RegAdminCmd("sm_weapons",		CmdWeapons,		ADMFLAG_ROOT, "[client index]. Lists players weapons and indexes. Either yourself, or aim target or optional index via cmd args.");
	if( g_iGAMETYPE == GAME_TF2 )
		RegAdminCmd("sm_wearables",	CmdWearables,	ADMFLAG_ROOT, "[client index]. Lists players cosmetics indexes and definitions. Either yourself with no args, or aim target or optional index via cmd args.");
	RegAdminCmd("sm_attachments",	CmdAttachments,	ADMFLAG_ROOT, "[#userid|name] or [entity index] Displays a list of attachments on the specified clients. No args = self.");
	RegAdminCmd("sm_viewmodel",		CmdViewmodel,	ADMFLAG_ROOT, "[#userid|name] returns a clients viewmodel entity index, or no args = self.");
	RegAdminCmd("sm_delweps",		CmdDelWeps,		ADMFLAG_ROOT, "[#userid|name] delete weapons from targeted clients, or no args = self.");
	RegAdminCmd("sm_getspeed",		CmdSpeed,		ADMFLAG_ROOT, "<#userid|name> Get the speed of the specified clients.");
	RegAdminCmd("sm_clients",		CmdClients,		ADMFLAG_ROOT, "Lists client indexes/userids and some other data.");
	RegAdminCmd("sm_users",			CmdUsers,		ADMFLAG_ROOT, "Prints the total amount of bots and clients who had connected and the last UserID to have connected.");
	RegAdminCmd("sm_ice",			CmdFreeze,		ADMFLAG_ROOT, "[entity]. Freeze / unfreeze aim target or specified entity.");
	RegAdminCmd("sm_damage",		CmdDamage,		ADMFLAG_ROOT, "<client index>. Track damage info deal to this client or by this client. -1 or empty to track everybody.");
	RegAdminCmd("sm_solid",			CmdSolid,		ADMFLAG_ROOT, "<flags>. Returns the SolidType_t flags from a flag value.");
	RegAdminCmd("sm_solidf",		CmdSolidF,		ADMFLAG_ROOT, "<flags>. Returns the SolidFlags_t flags from a flag value.");
	RegAdminCmd("sm_dmg",			CmdDmg,			ADMFLAG_ROOT, "<flags>. Returns the SDKHooks DamageType from a flag value.");
	RegAdminCmd("sm_setdmg",		CmdSetDmg,		ADMFLAG_ROOT, "<target index> <damage amount> [damage type enum] [inflictor index]. Deal damage to an entity.");
	RegAdminCmd("sm_val",			CmdVal,			ADMFLAG_ROOT, "<bit value>. e.g: sm_val 1<<20. Returns: 1048576");
	RegAdminCmd("sm_bit",			CmdBit,			ADMFLAG_ROOT, "<bit value>. e.g: sm_bit 1048577. Returns: (1<<0); (1<<20)");
	RegAdminCmd("sm_adm",			CmdAdm,			0, "Toggles between ROOT and BAN admin flags, for testing stuff without ROOT access. Or specified flags e.g. Usage: sm_adm BAN KICK");
	RegAdminCmd("sm_hexcols",		CmdHexCol,		ADMFLAG_ROOT, "Print a list of hex colors to chat.");

	RegAdminCmd("sm_gamerules",		CmdGameRules,	ADMFLAG_ROOT, "<prop> [value] Affects the gamerules proxy. Can read or write to table members, prop.member: e.g. m_iChapterDamage.001");
	RegAdminCmd("sm_prop",			CmdProp,		ADMFLAG_ROOT, "<prop> [value] Affects the entity you aim at. Can read or write to table members, prop.member: e.g. m_iChapterDamage.001");
	RegAdminCmd("sm_propent",		CmdPropEnt,		ADMFLAG_ROOT, "<entity> or <#userid|name> <prop> [val] Affects the specified entity. Can read or write to table members, prop.member: e.g. m_iChapterDamage.001");
	RegAdminCmd("sm_propself",		CmdPropMe,		ADMFLAG_ROOT, "<prop> [value] Affects yourself. Can read or write to table members, prop.member: e.g. m_iChapterDamage.001");
	RegAdminCmd("sm_propi",			CmdPropMe,		ADMFLAG_ROOT, "<prop> [value] Affects yourself. Can read or write to table members, prop.member: e.g. m_iChapterDamage.001");

	RegAdminCmd("sm_input",			CmdInput,		ADMFLAG_ROOT, "<input> [param] [activator] [caller] Makes the entity you're aiming at accept an Input. Optionally give a param, e.g. sm_input color '255 0 0'.");
	RegAdminCmd("sm_inputent",		CmdInputEnt,	ADMFLAG_ROOT, "<entity|targetname> <input> [param] [activator] [caller] Makes the specified entity accept an Input. Optionally give a param, e.g. sm_inputent 5 color '255 0 0'.");
	RegAdminCmd("sm_inputme",		CmdInputMe,		ADMFLAG_ROOT, "<input> [param] [activator] [caller] Makes you accept an entity Input. Optionally give a param, e.g. sm_inputme color '255 0 0'.");
	RegAdminCmd("sm_output",		CmdOutput,		ADMFLAG_ROOT, "<output> Watches the specified output on the entity aimed at.");
	RegAdminCmd("sm_outputent",		CmdOutputEnt,	ADMFLAG_ROOT, "<entity> <output> Watches the specified entity and specified output.");
	RegAdminCmd("sm_outputme",		CmdOutputMe,	ADMFLAG_ROOT, "<output> Watches the specified output on yourself.");
	RegAdminCmd("sm_outputstop",	CmdOutputStop,	ADMFLAG_ROOT, "Stops watching all entity outputs.");
	RegAdminCmd("sm_emit",			CmdEmit,		ADMFLAG_ROOT, "<sound path and filename> Plays a sound from your client. For testing sounds.");
	RegAdminCmd("sm_listens",		CmdListen,		ADMFLAG_ROOT, "Toggle to start/stop listening to sounds being played. Displays messages in chat to everyone.");
	RegAdminCmd("sm_watchents",		CmdWatchEnts,	ADMFLAG_ROOT, "Toggle to watch which entities are being spawned.");
	RegAdminCmd("sm_newbot",		CmdBot,			ADMFLAG_ROOT, "Create new bot client.");

	RegAdminCmd("sm_part",			CmdPart,		ADMFLAG_ROOT, "<name> Displays a particle you specify. Automatically removed after 5 seconds.");
	RegAdminCmd("sm_parti",			CmdPart2,		ADMFLAG_ROOT, "<name> Displays a particle where you are pointing. Automatically removed after 5 seconds.");

	if( g_iGAMETYPE == GAME_L4D || g_iGAMETYPE == GAME_L4D2 )
	{
		RegAdminCmd("sm_lobby",			CmdLobby,		0,	"Starts a vote return to lobby.");
		RegAdminCmd("sm_ledge",			CmdLedge,		ADMFLAG_ROOT, "Enables/Disables ledge hanging.");
		RegAdminCmd("sm_spit",			CmdSpit,		ADMFLAG_ROOT, "[#userid|name] Toggles spitter goo dribble on self (with no args) or specified targets.");
		RegAdminCmd("sm_temp",			CmdTemp,		ADMFLAG_ROOT, "<#userid|name> <amount> Set temporary health on a client.");

		RegAdminCmd("sm_alloff",		CmdAll,			ADMFLAG_ROOT, "Toggles - AI director on/off, z_common_limit, sb_hold.");
		RegAdminCmd("sm_director",		CmdDirector,	ADMFLAG_ROOT, "Toggles - AI director on/off.");
		RegAdminCmd("sm_hold",			CmdHold,		ADMFLAG_ROOT, "Toggles sb_hold - Stop the survivor bots moving but allows them to shoot.");
		RegAdminCmd("sm_halt",			CmdHalt,		ADMFLAG_ROOT, "Toggles sb_stop - Stops the survivor bots from moving and shooting.");
		RegAdminCmd("sm_nb",			CmdNB,			ADMFLAG_ROOT, "Toggles nb_stop - Stops all survivors/specifial infected from moving.");

		RegAdminCmd("sm_nospawn",		CmdNoSpawn,		ADMFLAG_ROOT, "Prevents all types of infected from spawning");
		RegAdminCmd("sm_zspawnv",		CmdZSpawnV,		ADMFLAG_ROOT, "Spawn infected and special infected specifying pos and ang. Usage sm_zspawnv <boomer|hunter|smoker|spitter|jockey|charger|tank|witch|infected> <pos X> <pos Y> <pos Z>  ( [modelname] [skin] || [ang X] [ang Y] [ang Z] [modelname] [skin] ).");
		RegAdminCmd("sm_bots",			CmdBotsL4D,		ADMFLAG_ROOT, "Creates a new Survivor bot.");

		RegAdminCmd("sm_slayall",		CmdSlayAll,		ADMFLAG_ROOT, "Slays all common and special infected and witches");
		RegAdminCmd("sm_slaycommon",	CmdSlayCommon,	ADMFLAG_ROOT, "Slays all common infected.");
		RegAdminCmd("sm_slaywitches",	CmdSlayWitches,	ADMFLAG_ROOT, "Slays all witches.");
		RegAdminCmd("sm_stopang",		CmdStopAngle,	ADMFLAG_ROOT, "Freeze current angle of all survivor bot players.");

		RegAdminCmd("sm_c",				CmdCoop,		ADMFLAG_ROOT, "Sets the game mode to Coop.");
		RegAdminCmd("sm_r",				CmdRealism,		ADMFLAG_ROOT, "Sets the game mode to Realism.");
		RegAdminCmd("sm_s",				CmdSurvival,	ADMFLAG_ROOT, "Sets the game mode to Survival.");
		RegAdminCmd("sm_v",				CmdVersus,		ADMFLAG_ROOT, "Sets the game mode to Versus.");
		if( g_iGAMETYPE == GAME_L4D2 )
		RegAdminCmd("sm_sc",			CmdScavenge,	ADMFLAG_ROOT, "Sets the game mode to Scavenge.");

		sb_hold_position = FindConVar("sb_hold_position");
		sb_stop = FindConVar("sb_stop");
		mp_gamemode = FindConVar("mp_gamemode");
		z_background_limit = FindConVar("z_background_limit");
		z_common_limit = FindConVar("z_common_limit");
		z_minion_limit = FindConVar("z_minion_limit");
		director_no_bosses = FindConVar("director_no_bosses");
		director_no_specials = FindConVar("director_no_specials");
		director_no_mobs = FindConVar("director_no_mobs");
	}

	sv_cheats = FindConVar("sv_cheats");

	if( g_iGAMETYPE == GAME_L4D2 )
	{
		z_boomer_limit = FindConVar("z_boomer_limit");
		z_charger_limit = FindConVar("z_charger_limit");
		z_hunter_limit = FindConVar("z_hunter_limit");
		z_jockey_limit = FindConVar("z_jockey_limit");
		z_smoker_limit = FindConVar("z_smoker_limit");
		z_spitter_limit = FindConVar("z_spitter_limit");
	}

	if( g_iGAMETYPE == GAME_CSS || g_iGAMETYPE == GAME_L4D || g_iGAMETYPE == GAME_L4D2 )
	{
		RegAdminCmd("sm_nv",		CmdNV,			ADMFLAG_ROOT, "Toggles nightvision.");
	}

	if( g_iGAMETYPE == GAME_CSS )
	{
		RegAdminCmd("sm_bots",		CmdBots,		ADMFLAG_ROOT, "Opens a menu to spawn bots.");
		RegAdminCmd("sm_money",		CmdMoney,		ADMFLAG_ROOT, "Opens a menu of players, sets 16000 money.");
	}

	// Translations
	LoadTranslations("common.phrases");

	// Events
	HookEventEx("round_end", Event_RoundEnd, EventHookMode_PostNoCopy); // Only hooks if exists

	// Other
	g_iGameTime = GetTime();

	if( g_bLateLoad )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && !IsFakeClient(i) )
			{
				g_iPlayTime = GetTime();
				g_iPlayers++;
			}
		}
	}

	// Property Field stuff
	g_hEntityKeys = new StringMap();
	g_hEntityKeys.SetValue("moveparent", true);
	g_hEntityKeys.SetValue("m_hActiveWeapon", true);
	g_hEntityKeys.SetValue("m_hAttachedToEntity", true);
	g_hEntityKeys.SetValue("m_hAttachEntity", true);
	g_hEntityKeys.SetValue("m_hBuildableButtonUseEnt", true);
	g_hEntityKeys.SetValue("m_hColorCorrectionCtrl", true);
	g_hEntityKeys.SetValue("m_hConstraintEntity", true);
	g_hEntityKeys.SetValue("m_hControlPointEnts", true);
	g_hEntityKeys.SetValue("m_hEffectEntity", true);
	g_hEntityKeys.SetValue("m_hElevator", true);
	g_hEntityKeys.SetValue("m_hEntAttached", true);
	g_hEntityKeys.SetValue("m_hGasNozzle", true);
	g_hEntityKeys.SetValue("m_hGroundEntity", true);
	g_hEntityKeys.SetValue("m_hLastWeapon", true);
	g_hEntityKeys.SetValue("m_hMoveParent", true);
	g_hEntityKeys.SetValue("m_hMyWeapons", true);
	g_hEntityKeys.SetValue("m_hObserverTarget", true);
	g_hEntityKeys.SetValue("m_holdingObject", true);
	g_hEntityKeys.SetValue("m_hOwner", true);
	g_hEntityKeys.SetValue("m_hOwnerEntity", true);
	g_hEntityKeys.SetValue("m_hPlayer", true);
	g_hEntityKeys.SetValue("m_hPlayerOwner", true);
	g_hEntityKeys.SetValue("m_hPostProcessCtrl", true);
	g_hEntityKeys.SetValue("m_hProps", true);
	g_hEntityKeys.SetValue("m_hRagdoll", true);
	g_hEntityKeys.SetValue("m_hScriptUseTarget", true);
	g_hEntityKeys.SetValue("m_hStartPoint", true);
	g_hEntityKeys.SetValue("m_hTargetEntity", true);
	g_hEntityKeys.SetValue("m_hThrower", true);
	g_hEntityKeys.SetValue("m_hTonemapController", true);
	g_hEntityKeys.SetValue("m_hUseEntity", true);
	g_hEntityKeys.SetValue("m_hVehicle", true);
	g_hEntityKeys.SetValue("m_hViewEntity", true);
	g_hEntityKeys.SetValue("m_hViewModel", true);
	g_hEntityKeys.SetValue("m_hViewPosition", true);
	g_hEntityKeys.SetValue("m_hWeapon", true);
	g_hEntityKeys.SetValue("m_hZoomOwner", true);
	g_hEntityKeys.SetValue("m_useActionTarget", true);
	g_hEntityKeys.SetValue("m_useActionOwner", true);
	g_hEntityKeys.SetValue("m_reviveTarget", true);
	g_hEntityKeys.SetValue("m_reviveOwner", true);
	g_hEntityKeys.SetValue("m_healTarget", true);
	g_hEntityKeys.SetValue("m_survivor", true);

	// GameRules net class name
	switch( g_iEngine )
	{
		case Engine_AlienSwarm:			g_sGameRulesNet = "CAlienSwarmProxy";
		case Engine_BlackMesa:			g_sGameRulesNet = "CBM_MP_GameRulesProxy";
		case Engine_BloodyGoodTime:		g_sGameRulesNet = "CPMGameRulesProxy";
		case Engine_Contagion:			g_sGameRulesNet = "CTerrorGameRulesProxy";
		case Engine_CSGO:				g_sGameRulesNet = "CCSGameRulesProxy";
		case Engine_CSS:				g_sGameRulesNet = "CCSGameRulesProxy";
		case Engine_DarkMessiah:		g_sGameRulesNet = "CHL2MPGameRulesProxy";
		case Engine_DODS:				g_sGameRulesNet = "CDODGameRulesProxy";
		case Engine_EYE:				g_sGameRulesNet = "CHL2MPGameRulesProxy";
		case Engine_HL2DM:				g_sGameRulesNet = "CHL2MPGameRulesProxy";
		case Engine_Insurgency:			g_sGameRulesNet = "CINSRulesProxy";
		case Engine_Left4Dead:			g_sGameRulesNet = "CTerrorGameRulesProxy";
		case Engine_Left4Dead2:			g_sGameRulesNet = "CTerrorGameRulesProxy";
		case Engine_NuclearDawn:		g_sGameRulesNet = "CNuclearDawnRulesProxy";
		case Engine_TF2:				g_sGameRulesNet = "CTFGameRulesProxy";
	}

	switch( g_iEngine )
	{
		case Engine_AlienSwarm:			g_sGameRulesClass = "asw_gamerules";
		case Engine_BlackMesa:			g_sGameRulesClass = "blackmesa_mp_gamerules";
		case Engine_BloodyGoodTime:		g_sGameRulesClass = "pm_gamerules";
		case Engine_Contagion:			g_sGameRulesClass = "contagion_gamerules";
		case Engine_CSGO:				g_sGameRulesClass = "cs_gamerules";
		case Engine_CSS:				g_sGameRulesClass = "cs_gamerules";
		case Engine_DarkMessiah:		g_sGameRulesClass = "hl2mp_gamerules";
		case Engine_DODS:				g_sGameRulesClass = "dod_gamerules";
		case Engine_EYE:				g_sGameRulesClass = "hl2mp_gamerules";
		case Engine_HL2DM:				g_sGameRulesClass = "hl2mp_gamerules";
		case Engine_Insurgency:			g_sGameRulesClass = "ins_gamerules";
		case Engine_Left4Dead:			g_sGameRulesClass = "terror_gamerules";
		case Engine_Left4Dead2:			g_sGameRulesClass = "terror_gamerules";
		case Engine_NuclearDawn:		g_sGameRulesClass = "nd_gamerules";
		case Engine_TF2:				g_sGameRulesClass = "tf_gamerules";
	}
}

public void OnPluginEnd()
{
	if( g_iGAMETYPE == GAME_L4D2 )
	{
		for( int i = 0; i <= MaxClients; i++ )
		{
			if( IsValidEntRef(g_iEntsSpit[i]) )
			{
				AcceptEntityInput(g_iEntsSpit[i], "ClearParent");
				RemoveEntity(g_iEntsSpit[i]);
			}
		}
	}
}

public void OnMapStart()
{
	if( g_iGAMETYPE == GAME_L4D || g_iGAMETYPE == GAME_L4D2 )
	{
		g_bDirector = true;
		g_bAll = false;

		for( int i = 0; i < sizeof(g_sModels1); i++ )
			PrecacheModel(g_sModels1[i]);

		if( g_iGAMETYPE == GAME_L4D2 )
		{
			PrecacheParticle("spitter_slime_trail");

			for( int i = 0; i < sizeof(g_sModels2); i++ )
				PrecacheModel(g_sModels2[i]);
		}
	}

	g_iLaserIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloIndex = PrecacheModel("materials/sprites/halo01.vmt");

	g_iMapChanges++;
}

Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bFirst = true;

	return Plugin_Continue;
}

bool g_bWatchEnts;
bool g_bWatchSpawn;
int g_iSpawned;
public void OnEntityCreated(int entity, const char[] classname)
{
	if( g_bWatchEnts )
	{
		PrintToServer("%d %s", entity, classname);
		PrintToChatAll("%d %s", entity, classname);
	}

	if( g_bNospawn )
	{
		if( strcmp(classname, "infected") == 0 )
		{
			SDKHook(entity, SDKHook_SpawnPost, OnSpawnCommon);
		}
	}

	if( g_bWatchSpawn )
	{
		if(
			strcmp(classname, "boomer") == 0 ||
			strcmp(classname, "hunter") == 0 ||
			strcmp(classname, "smoker") == 0 ||
			strcmp(classname, "spitter") == 0 ||
			strcmp(classname, "jockey") == 0 ||
			strcmp(classname, "charger") == 0 ||
			strcmp(classname, "tank") == 0 ||
			strcmp(classname, "witch") == 0 ||
			strcmp(classname, "infected") == 0
		)
		{
			g_iSpawned = entity;
		}
	}
}

void OnSpawnCommon(int entity)
{
	RemoveEntity(entity);
}



// ====================================================================================================
//					COMMANDS - PLUGINS - sm_refresh, sm_reload, sm_unload
// ====================================================================================================
Action CmdRefresh(int client, int args)
{
	ServerCommand("sm plugins refresh");
	if( client ) PrintToChat(client, "\x04[Plugins Refreshed]");
	else ReplyToCommand(client, "[Plugins Refreshed]");
	return Plugin_Handled;
}

Action CmdRenew(int client, int args)
{
	ServerCommand("sm plugins unload_all; sm plugins refresh");
	if( client ) PrintToChat(client, "\x04[Plugins Reloaded]");
	else ReplyToCommand(client, "[Plugins Reloaded]");
	return Plugin_Handled;
}

Action CmdUnload(int client, int args)
{
	ServerCommand("sm plugins unload_all");
	if( client ) PrintToChat(client, "\x04[Plugins Unloaded]");
	else ReplyToCommand(client, "[Plugins Unloaded]");
	return Plugin_Handled;
}



// ====================================================================================================
//					COMMANDS - ALL GAMES - sm_round, sm_cheats, sm_logit, sm_createent
// ====================================================================================================
Action CmdRound(int client, int args)
{
	if( g_iGAMETYPE == GAME_CSS )
		ServerCommand("mp_restartgame 1");
	else
		ServerCommand("sm_cvar mp_restartgame 1");
	if( client ) PrintToChat(client, "\x04[Restarting game]");
	else ReplyToCommand(client, "\x04[Restarting game]");
	return Plugin_Handled;
}

Action CmdCheats(int client, int args)
{
	if( sv_cheats != null )
	{
		if( sv_cheats.IntValue == 1 )
		{
			ServerCommand("sv_cheats 0");
			if( client ) PrintToChat(client, "\x04[sv_cheats]\x01 disabled!");
			else ReplyToCommand(client, "[sv_cheats] disabled!");
		}
		else
		{
			ServerCommand("sv_cheats 1");
			if( client ) PrintToChat(client, "\x04[sv_cheats]\x01 enabled!");
			else ReplyToCommand(client, "[sv_cheats] enabled!");
		}
	}
	return Plugin_Handled;
}

Action CmdLogIt(int client, int args)
{
	if( args == 0 )
	{
		ReplyToCommand(client, "Usage: sm_logit <text>");
		return Plugin_Handled;
	}

	char sTemp[256];
	GetCmdArgString(sTemp, sizeof(sTemp));
	LogCustom("%N: %s", client, sTemp);
	return Plugin_Handled;
}

Action CmdGameTime(int client, int args)
{
	ReplyToCommand(client, "[GameTime] %f", GetGameTime());
	return Plugin_Handled;
}

Action CmdUpTime(int client, int args)
{
	// From nextmap plugin
	int time = GetTime() - g_iGameTime;
	int days = time / 86400;
	int hours = (time / 3600) % 24;
	int minutes = (time / 60) % 60;
	int seconds = time % 60;

	if( client > 0 && client <= MaxClients && IsClientInGame(client) )
	{
		PrintToChat(client, "\x03Uptime: %d days %d hours %d minutes %d seconds", days, hours, minutes, seconds);
	}
	else if( client == 0 )
	{
		PrintToServer("Uptime: %d days %d hours %d minutes %d seconds", days, hours, minutes, seconds);
	}

	return Plugin_Handled;
}

Action CmdPlayTime(int client, int args)
{
	// From nextmap plugin
	int time = g_iPlayers ? g_iPlayedTime + GetTime() - g_iPlayTime : g_iPlayedTime;
	int days = time / 86400;
	int hours = (time / 3600) % 24;
	int minutes = (time / 60) % 60;
	int seconds = time % 60;

	if( client > 0 && client <= MaxClients && IsClientInGame(client) )
	{
		PrintToChat(client, "\x03Playtime: %d days %d hours %d minutes %d seconds", days, hours, minutes, seconds);
	}
	else if( client == 0 )
	{
		PrintToServer("Playtime: %d days %d hours %d minutes %d seconds", days, hours, minutes, seconds);
	}

	return Plugin_Handled;
}

Action CmdChanges(int client, int args)
{
	if( client > 0 && client <= MaxClients && IsClientInGame(client) )
	{
		PrintToChat(client, "\x01Map Changes: \x03%d", g_iMapChanges);
	}
	else if( client == 0 )
	{
		PrintToServer("Map Changes: %d", g_iMapChanges);
	}

	return Plugin_Handled;
}

Action CmdCreateEnt(int client, int args)
{
	if( args != 1 )
	{
		ReplyToCommand(client, "Usage: sm_createent <text>");
		return Plugin_Handled;
	}

	char sBuff[32];
	GetCmdArg(1, sBuff, sizeof(sBuff));

	int entity = CreateEntityByName(sBuff);
	if( entity != -1 )
	{
		ReplyToCommand(client, "Created entity: %s", sBuff);
		RemoveEntity(entity);
	}
	else
	{
		ReplyToCommand(client, "Failed entity: %s", sBuff);
	}
	return Plugin_Handled;
}




// ====================================================================================================
//					COMMANDS - ALL GAMES - sm_e, sm_cv, sm_fcmd
// ====================================================================================================
Action CmdCV(int client, int args)
{
	if( args == 0 )
	{
		ReplyToCommand(client, "[SM] Usage: sm_cv <cvar> [value]");
		return Plugin_Handled;
	}

	char sCvar[64], sTemp[256];
	GetCmdArg(1, sCvar, sizeof(sCvar));

	ConVar hCvar = FindConVar(sCvar);
	if( hCvar == null )
	{
		ReplyToCommand(client, "[SM] %t", "Unable to find cvar", sCvar);
		return Plugin_Handled;
	}

	if( args == 1 )
	{
		hCvar.GetString(sTemp, sizeof(sTemp));
		ReplyToCommand(client, "[SM] %t", "Value of cvar", sCvar, sTemp);
		return Plugin_Handled;
	}

	int flags = hCvar.Flags;
	hCvar.Flags = flags & ~FCVAR_NOTIFY;
	GetCmdArg(2, sTemp, sizeof(sTemp));
	hCvar.SetString(sTemp);
	hCvar.Flags = flags;

	ReplyToCommand(client, "[SM] %t", "Cvar changed", sCvar, sTemp);

	return Plugin_Handled;
}

Action CmdECheat(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args == 0 )
	{
		ReplyToCommand(client, "Usage: sm_e <command> [args]");
		return Plugin_Handled;
	}

	char sArg1[64], sArg2[64];
	GetCmdArg(1, sArg1, sizeof(sArg1));

	if( args != 1 )
	{
		GetCmdArgString(sArg2, sizeof(sArg2));
		strcopy(sArg2, sizeof(sArg2), sArg2[FindCharInString(sArg2, ' ')]);
	}

	int bits = GetUserFlagBits(client);
	int flags = GetCommandFlags(sArg1);

	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(sArg1, flags & ~FCVAR_CHEAT);

	if( args != 1 )
		FakeClientCommand(client, "%s %s", sArg1, sArg2);
	else
		FakeClientCommand(client, sArg1);

	SetUserFlagBits(client, bits);
	SetCommandFlags(sArg1, flags);
	return Plugin_Handled;
}

Action CmdCCmd(int client, int args)
{
	if( args < 2 )
	{
		ReplyToCommand(client, "Usage: sm_ccmd <#userid|name> <command> [args]");
	}

	char arg1[32], arg2[32], arg3[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if( args == 3 ) GetCmdArg(3, arg3, sizeof(arg3));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if( (target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		0,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	int target;
	for( int i = 0; i < target_count; i++ )
	{
		target = target_list[i];

		if( args == 3 )
			ClientCommand(target, "%s %s", arg2, arg3);
		else
			ClientCommand(target, arg2);
		ReplyToCommand(client, "[ClientCmd] Performed on %N", target);
	}

	return Plugin_Handled;
}

Action CmdFCmd(int client, int args)
{
	if( args < 2 )
	{
		ReplyToCommand(client, "Usage: sm_fcmd <#userid|name> <command> [args]");
	}

	char arg1[32]; char arg2[32]; char arg3[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if( args == 3 ) GetCmdArg(3, arg3, sizeof(arg3));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if( (target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		0,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	int target;
	for( int i = 0; i < target_count; i++ )
	{
		target = target_list[i];

		if( args == 3 )
			FakeClientCommand(target, "%s %s", arg2, arg3);
		else
			FakeClientCommand(target, arg2);

		if( client ) PrintToChat(client, "[FakeCmd] Performed on %N", target);
		else ReplyToCommand(client, "[FakeCmd] Performed on %N", target);
	}

	return Plugin_Handled;
}

Action CmdSCmd(int client, int args)
{
	char sTemp[512];
	GetCmdArgString(sTemp, sizeof(sTemp));
	ServerCommand(sTemp);
	return Plugin_Handled;
}

Action CmdRngC(int client, int args)
{
	RandomCommand(client, args, 1);
	return Plugin_Handled;
}

Action CmdRngF(int client, int args)
{
	RandomCommand(client, args, 2);
	return Plugin_Handled;
}

Action CmdRngS(int client, int args)
{
	RandomCommand(client, args, 3);
	return Plugin_Handled;
}

void RandomCommand(int client, int args, int type)
{
	if( args < 2 )
	{
		ReplyToCommand(client, "[SM[ Usage: sm_rngc/sm_rngf/sm_rngs <0-100> <command string> chance out of 100 to execute the command string.");
		return;
	}

	char sTemp[256];
	GetCmdArg(1, sTemp, sizeof(sTemp));

	if( GetRandomInt(0, 100) <= StringToInt(sTemp) )
	{
		// Copy command string after first arg
		GetCmdArgString(sTemp, sizeof(sTemp));
		int pos = FindCharInString(sTemp, ' ');
		Format(sTemp, sizeof(sTemp), sTemp[pos]);

		switch( type )
		{
			case 1: ClientCommand(client, sTemp);
			case 2: FakeClientCommand(client, sTemp);
			case 3: ServerCommand(sTemp);
		}
	}

	return;
}



// ====================================================================================================
//					COMMANDS - POS - sm_views, sm_viewr, sm_pos, sm_tel
// ====================================================================================================
Action CmdViewS(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	GetClientAbsOrigin(client, g_vPos[client]);
	GetClientEyeAngles(client, g_vAng[client]);
	ReplyToCommand(client, "Position saved.");
	return Plugin_Handled;
}

Action CmdViewR(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( g_vAng[client][0] == 0.0 && g_vAng[client][1] == 0.0 && g_vAng[client][2] == 0.0 )
	{
		PrintToChat(client, "[ViewR] No saved position.");
		return Plugin_Handled;
	}
	TeleportEntity(client, g_vPos[client], g_vAng[client], view_as<float>({ 0.0, 0.0, 0.0}));
	return Plugin_Handled;
}

Action CmdPosition(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	float vPos[3], vAng[3];
	GetClientAbsOrigin(client, vPos);
	GetClientEyeAngles(client, vAng);
	PrintToChat(client, "%f %f %f     %f %f %f", vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	return Plugin_Handled;
}

Action CmdAimPos(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	float vPos[3];
	if( GetDirectionEndPoint(client, vPos) )
	{
		ReplyToCommand(client, "End position: %f %f %f", vPos[0], vPos[1], vPos[2]);
	} else {
		ReplyToCommand(client, "Cannot find end position.");
	}

	return Plugin_Handled;
}

Action CmdSetAng(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args != 4 )
	{
		ReplyToCommand(client, "[SM] Usage: <#userid|name> <vector angles (X Y Z)>.");
	}

	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if( (target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	int target;
	float vAng[3];
	bool x, y, z;

	GetCmdArg(2, arg1, sizeof(arg1));
	if( strcmp(arg1, "?") == 0 ) x = true;
	else vAng[0] = StringToFloat(arg1);

	GetCmdArg(3, arg1, sizeof(arg1));
	if( strcmp(arg1, "?") == 0 ) y = true;
	else vAng[1] = StringToFloat(arg1);

	GetCmdArg(4, arg1, sizeof(arg1));
	if( strcmp(arg1, "?") == 0 ) z = true;
	else vAng[2] = StringToFloat(arg1);

	for( int i = 0; i < target_count; i++ )
	{
		target = target_list[i];

		if( x || y || z )
		{
			float vVec[3];
			GetEntPropVector(target, Prop_Data, "m_angRotation", vVec);
			if( x ) vAng[0] = vVec[0];
			if( y ) vAng[1] = vVec[1];
			if( z ) vAng[2] = vVec[2];
		}

		TeleportEntity(target, NULL_VECTOR, vAng, view_as<float>({ 0.0, 0.0, 0.0}));
	}

	return Plugin_Handled;
}

Action CmdSetPos(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args != 4 )
	{
		ReplyToCommand(client, "[SM] Usage: <#userid|name> <vector origin (X Y Z)>.");
	}

	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if( (target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	int target;
	float vPos[3];
	bool x, y, z;

	GetCmdArg(2, arg1, sizeof(arg1));
	if( strcmp(arg1, "?") == 0 ) x = true;
	else vPos[0] = StringToFloat(arg1);

	GetCmdArg(3, arg1, sizeof(arg1));
	if( strcmp(arg1, "?") == 0 ) y = true;
	else vPos[1] = StringToFloat(arg1);

	GetCmdArg(4, arg1, sizeof(arg1));
	if( strcmp(arg1, "?") == 0 ) z = true;
	else vPos[2] = StringToFloat(arg1);

	for( int i = 0; i < target_count; i++ )
	{
		target = target_list[i];

		if( x || y || z )
		{
			float vVec[3];
			GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vVec);
			if( x ) vPos[0] = vVec[0];
			if( y ) vPos[1] = vVec[1];
			if( z ) vPos[2] = vVec[2];
		}

		TeleportEntity(target, vPos, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0}));
	}

	return Plugin_Handled;
}

Action CmdBring(int client, int args)
{
	#define DISTANCE		50.0 // How far from the player to teleport entities

	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
	}

	if( args != 1 && args != 2 )
	{
		ReplyToCommand(client, "Usage: sm_bringents <classname> [distance: (default 50)]");
		return Plugin_Handled;
	}

	char classname[64];

	float distance = DISTANCE;
	if( args == 2 )
	{
		GetCmdArg(2, classname, sizeof(classname));
		distance = StringToFloat(classname);
	}

	GetCmdArg(1, classname, sizeof(classname));

	ArrayList alEnts = new ArrayList();
	int count;
	int entity = -1;
	while( (entity = FindEntityByClassname(entity, classname)) != INVALID_ENT_REFERENCE )
	{
		alEnts.Push(entity);
		count++;
	}

	if( count == 0 )
	{
		ReplyToCommand(client, "[SM] 0 entities matching \"%s\" classname.", classname);
		return Plugin_Handled;
	}

	float vAngle;
	float vVec[3];
	float vPos[3];
	float vAng[3];
	GetClientAbsOrigin(client, vPos);

	// Loop through 12 positions around the player to find a good flare position
	for( int i = 1; i <= count; i++ )
	{
		entity = alEnts.Get(i - 1);

		vVec = vPos;
		vAngle = i * 360.0 / count; // Divide circle into parts

		// Draw in a circle around player
		vVec[0] += distance * (Cosine(vAngle));
		vVec[1] += distance * (Sine(vAngle));
		vVec[2] += 10.0;

		MakeVectorFromPoints(vPos, vVec, vAng);
		GetVectorAngles(vAng, vAng);
		vAng[0] = 0.0;
		vAng[1] -= 90.0;
		vAng[2] = 0.0;

		TeleportEntity(entity, vVec, vAng, NULL_VECTOR);
	}

	return Plugin_Handled;
}

Action CmdTeleport(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	float vPos[3];
	char arg[16];
	if( args == 6 )
	{
		bool x, y, z;

		GetCmdArg(1, arg, sizeof(arg));
		if( strcmp(arg, "?") == 0 ) x = true;
		else vPos[0] = StringToFloat(arg);

		GetCmdArg(2, arg, sizeof(arg));
		if( strcmp(arg, "?") == 0 ) y = true;
		else vPos[1] = StringToFloat(arg);

		GetCmdArg(3, arg, sizeof(arg));
		if( strcmp(arg, "?") == 0 ) z = true;
		else vPos[2] = StringToFloat(arg);

		if( x || y || z )
		{
			float vVec[3];
			GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vVec);
			if( x ) vPos[0] = vVec[0];
			if( y ) vPos[1] = vVec[1];
			if( z ) vPos[2] = vVec[2];
			x = false;
			y = false;
			z = false;
		}

		float vAng[3];

		GetCmdArg(4, arg, sizeof(arg));
		if( strcmp(arg, "?") == 0 ) x = true;
		else vAng[0] = StringToFloat(arg);

		GetCmdArg(5, arg, sizeof(arg));
		if( strcmp(arg, "?") == 0 ) y = true;
		else vAng[1] = StringToFloat(arg);

		GetCmdArg(6, arg, sizeof(arg));
		if( strcmp(arg, "?") == 0 ) z = true;
		else vAng[2] = StringToFloat(arg);

		if( x || y || z )
		{
			float vVec[3];
			GetEntPropVector(client, Prop_Data, "m_angRotation", vVec);
			if( x ) vAng[0] = vVec[0];
			if( y ) vAng[1] = vVec[1];
			if( z ) vAng[2] = vVec[2];
		}

		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
		return Plugin_Handled;
	}
	else if( args == 3 )
	{
		bool x, y, z;

		GetCmdArg(1, arg, sizeof(arg));
		if( strcmp(arg, "?") == 0 ) x = true;
		else vPos[0] = StringToFloat(arg);

		GetCmdArg(2, arg, sizeof(arg));
		if( strcmp(arg, "?") == 0 ) y = true;
		else vPos[1] = StringToFloat(arg);

		GetCmdArg(3, arg, sizeof(arg));
		if( strcmp(arg, "?") == 0 ) z = true;
		else vPos[2] = StringToFloat(arg);

		if( x || y || z )
		{
			float vVec[3];
			GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vVec);
			if( x ) vPos[0] = vVec[0];
			if( y ) vPos[1] = vVec[1];
			if( z ) vPos[2] = vVec[2];
		}
	}
	else if( args == 1 )
	{
		GetCmdArg(1, arg, sizeof(arg));
		int entity = StringToInt(arg);
		if( IsValidEntity(entity) )
		{
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
			vPos[2] += 20.0;
			TeleportEntity(client, vPos, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0}));
		}
	}
	else
	{
		SetTeleportEndPoint(client, vPos);
	}
	TeleportEntity(client, vPos, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0}));
	return Plugin_Handled;
}

Action CmdTele(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args != 1 && args != 4 )
	{
		ReplyToCommand(client, "Usage: sm_tele <#userid|name> [vector pos]. Teleport targets to your aim position or to the x y z vector specified");
		return Plugin_Handled;
	}

	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if( (target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	float vPos[3];
	bool x, y, z;

	if( args == 4 )
	{
		GetCmdArg(2, arg1, sizeof(arg1));
		if( strcmp(arg1, "?") == 0 ) x = true;
		else vPos[0] = StringToFloat(arg1);

		GetCmdArg(3, arg1, sizeof(arg1));
		if( strcmp(arg1, "?") == 0 ) y = true;
		else vPos[1] = StringToFloat(arg1);

		GetCmdArg(4, arg1, sizeof(arg1));
		if( strcmp(arg1, "?") == 0 ) z = true;
		else vPos[2] = StringToFloat(arg1);
	} else {
		SetTeleportEndPoint(client, vPos);
	}

	int target;
	for( int i = 0; i < target_count; i++ )
	{
		target = target_list[i];

		if( x || y || z )
		{
			float vVec[3];
			GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vVec);
			if( x ) vPos[0] = vVec[0];
			if( y ) vPos[1] = vVec[1];
			if( z ) vPos[2] = vVec[2];
		}

		TeleportEntity(target, vPos, NULL_VECTOR, NULL_VECTOR);
	}


	return Plugin_Handled;
}

Action CmdRange(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int entity;
	if( args )
	{
		char arg1[6];
		GetCmdArg(1, arg1, sizeof(arg1));
		entity = StringToInt(arg1);
		if( IsValidEntity(entity) == false )
		{
			ReplyToCommand(client, "[SM] Invalid entity specified.");
			return Plugin_Handled;
		}
	} else {
		entity = GetClientAimTarget(client, false);
	}

	if( entity != -1 )
	{
		float vPos[3], vLoc[3], fLen;

		GetClientAbsOrigin(client, vPos);
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vLoc);
		fLen = GetVectorDistance(vPos, vLoc);

		PrintToChat(client, "Range: %f from %d", fLen, entity);
	}
	return Plugin_Handled;
}

Action CmdNear(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
	}

	char sTemp[64];
	char sName[64];
	float range = 150.0;

	if( args == 1 )
	{
		GetCmdArg(1, sTemp, sizeof(sTemp));
		range = StringToFloat(sTemp);
	}

	float vPos[3];
	float vEnt[3];
	GetClientAbsOrigin(client, vPos);

	for( int i = 0; i < 4096; i++ )
	{
		if( IsValidEntity(i) && IsValidEdict(i) )
		{
			GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vEnt);
			if( GetVectorDistance(vPos, vEnt) <= range )
			{
				GetEdictClassname(i, sTemp, sizeof(sTemp));
				GetEntPropString(i, Prop_Data, "m_iName", sName, sizeof(sName));
				ReplyToCommand(client, "%d. %f - %s (%s)", i, GetVectorDistance(vPos, vEnt), sTemp, sName);
			}
		}
	}

	return Plugin_Handled;
}

Action CmdDist(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
	}

	if( g_bFirst )
	{
		GetClientAbsOrigin(client, g_vSavedPos);
		PrintToChat(client, "Start point is saved (pos: %f %f %f)", g_vSavedPos[0], g_vSavedPos[1], g_vSavedPos[2]);
		g_bFirst = false;
	}
	else
	{
		float vPos[3];
		GetClientAbsOrigin(client, vPos);
		PrintToChat(client, "End point at pos: %f %f %f\nDistance: %f", vPos[0], vPos[1], vPos[2], GetVectorDistance(vPos, g_vSavedPos, false));
		g_bFirst = true;
	}
	return Plugin_Handled;
}

Action CmdDistDir(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
	}

	float vOrigin[3], vEnd[3], vEndNonCol[3];
	float dist;

	GetClientAbsOrigin(client, vOrigin);

	if( GetDirectionEndPoint(client, vEnd) )
	{
		dist = GetVectorDistance(vOrigin, vEnd);
		PrintToChat(client, "Directional end point: %f %f %f. Distance: %f", vEnd[0], vEnd[1], vEnd[2], dist);

		if( GetNonCollideEndPoint(client, vEnd, vEndNonCol) )
		{
			dist = GetVectorDistance(vOrigin, vEndNonCol);
			PrintToChat(client, "Non-collide end point: %f %f %f. Distance: %f", vEndNonCol[0], vEndNonCol[1], vEndNonCol[2], dist);
		}
		else
		{
			PrintToChat(client, "Non-collide end point doesn't found.");
		}
	}
	else
	{
		PrintToChat(client, "Directional end point doesn't found.");
	}

	return Plugin_Handled;
}

bool GetNonCollideEndPoint(int client, float vEnd[3], float vEndNonCol[3])
{
	float vMin[3], vMax[3], vStart[3];
	GetClientAbsOrigin(client, vStart);
	GetClientMins(client, vMin);
	GetClientMaxs(client, vMax);

	vStart[2] += 20.0; // if nearby area is irregular

	Handle hTrace = TR_TraceHullFilterEx(vStart, vEnd, vMin, vMax, MASK_PLAYERSOLID, TraceRayNoPlayers, client);
	if( hTrace != null )
	{
		if( TR_DidHit(hTrace) )
		{
			TR_GetEndPosition(vEndNonCol, hTrace);
			delete hTrace;
			LaserP(vStart, vEndNonCol, GREEN, 5.0);
			return true;
		}
		delete hTrace;
	}

	return false;
}

// Unused
stock float GetDistanceToVec(int client, float vEnd[3])
{
	float vEndNonCol[3], fDistance;
	fDistance = 0.0;

	if( GetNonCollideEndPoint(client, vEnd, vEndNonCol) )
	{
		float vOrigin[3];
		GetClientAbsOrigin(client, vOrigin);
		fDistance = GetVectorDistance(vOrigin, vEndNonCol);
	}

	return fDistance;
}

bool GetDirectionEndPoint(int client, float vEndPos[3])
{
	float vDir[3], vPos[3];
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vDir);

	Handle hTrace = TR_TraceRayFilterEx(vPos, vDir, MASK_PLAYERSOLID, RayType_Infinite, TraceRayNoPlayers, client);
	if( hTrace != null )
	{
		if( TR_DidHit(hTrace) )
		{
			TR_GetEndPosition(vEndPos, hTrace);
			delete hTrace;
			LaserP(vPos, vEndPos, RED);
			return true;
		}
		delete hTrace;
	}
	return false;
}

Action CmdDistFloor(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
	}

	float dist = GetDistanceToFloor(client);
	PrintToChat(client, "dist to floor: %f", dist);
	return Plugin_Handled;
}

float GetDistanceToFloor(int client, float maxheight = 3000.0)
{
	float vStart[3], fDistance = 0.0;

	if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == 0)
		return 0.0;

	GetClientAbsOrigin(client, vStart);

	vStart[2] += 10.0;

	float vMin[3], vMax[3], vOrigin[3], vEnd[3];
	vEnd[0] = vStart[0];
	vEnd[1] = vStart[1];
	vEnd[2] = vStart[2] - maxheight;
	GetClientMins(client, vMin);
	GetClientMaxs(client, vMax);
	GetClientAbsOrigin(client, vOrigin);

	Handle hTrace = TR_TraceHullFilterEx(vOrigin, vEnd, vMin, vMax, MASK_PLAYERSOLID, TraceRayNoPlayers, client);
	if( hTrace != null )
	{
		if( TR_DidHit(hTrace) )
		{
			float fEndPos[3];
			TR_GetEndPosition(fEndPos, hTrace);
			vStart[2] -= 10.0;
			fDistance = GetVectorDistance(vStart, fEndPos);
		}
		else
		{
			fDistance = maxheight;
		}
		delete hTrace;
	}

	return fDistance;
}

Action CmdDistRoof(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
	}

	float dist = GetDistanceToRoof(client);
	PrintToChat(client, "dist to roof: %f", dist);
	return Plugin_Handled;
}

float GetDistanceToRoof(int client, float maxheight = 3000.0)
{
	float vMin[3], vMax[3], vOrigin[3], vEnd[3], vStart[3], fDistance = 0.0;
	GetClientAbsOrigin(client, vStart);
	vStart[2] += 10.0;
	vEnd[0] = vStart[0];
	vEnd[1] = vStart[1];
	vEnd[2] = vStart[2] + maxheight;
	GetClientMins(client, vMin);
	GetClientMaxs(client, vMax);
	GetClientAbsOrigin(client, vOrigin);
	Handle hTrace = TR_TraceHullFilterEx(vOrigin, vEnd, vMin, vMax, MASK_PLAYERSOLID, TraceRayNoPlayers, client);
	if( hTrace != null )
	{
		if( TR_DidHit(hTrace) )
		{
			float fEndPos[3];
			TR_GetEndPosition(fEndPos, hTrace);
			vStart[2] -= 10.0;
			fDistance = GetVectorDistance(vStart, fEndPos);
		}
		else
		{
			fDistance = maxheight;
		}
		delete hTrace;
	}
	return fDistance;
}

bool TraceRayNoPlayers(int entity, int mask, int data)
{
	if( entity == data || (entity >= 1 && entity <= MaxClients) )
	{
		return false;
	}
	return true;
}

// Unused
/*
bool TraceRay_DontHitSelf(int iEntity, int iMask, int data)
{
	return (iEntity != data);
}
*/

void LaserP(float start[3], float end[3], int color[4], float width = 3.0)
{
	TE_SetupBeamPoints(start, end, g_sprite, 0, 0, 0, 10.0, width, width, 7, 0.0, color, 5);
	TE_SendToAll();
}

void ShowSize(int client, int target)
{
	if( target > 0 )
	{
		char sClass[64];
		GetEntityClassname(target, sClass, sizeof(sClass));

		if( HasEntProp(target, Prop_Data, "m_vecMins") )
		{
			float vStart[3], vEnd[3];

			GetEntPropVector(target, Prop_Data, "m_vecMins", vStart);
			GetEntPropVector(target, Prop_Data, "m_vecMaxs", vEnd);

			PrintToChat(client, "Class: %s. Width: %.2f, Length: %.2f, Heigth: %.2f", sClass, FloatAbs(vStart[0] - vEnd[0]), FloatAbs(vStart[1] - vEnd[1]), FloatAbs(vStart[2] - vEnd[2]));
		}
		else
		{
			PrintToChat(client, "Class: %s. ERROR when extracting size!", sClass);
		}
	}
}

Action CmdSizeMe(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
	}

	ShowSize(client, client);
	return Plugin_Handled;
}

Action CmdSizeTarget(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
	}

	int target = GetClientAimTarget(client, false);
	ShowSize(client, target);
	return Plugin_Handled;
}



// ====================================================================================================
//					COMMANDS - ENTITIES - sm_del, sm_ent, sm_box, sm_find, sm_count, sm_modlist
// ====================================================================================================
Action CmdDel(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int entity = GetClientAimTarget(client, false);
	if( entity > MaxClients )
		RemoveEntity(entity);

	return Plugin_Handled;
}

Action CmdDelE(int client, int args)
{
	if( args == 1 )
	{
		char sTemp[32];
		int entity;

		GetCmdArg(1, sTemp, sizeof(sTemp));
		entity = StringToInt(sTemp);

		if( entity == 0 || entity <= MaxClients || (entity < -1 && EntRefToEntIndex(entity) == INVALID_ENT_REFERENCE) || (entity >= MaxClients && IsValidEntity(entity) == false) )
		{
			ReplyToCommand(client, "[SM] Invalid Entity %d", entity);
			return Plugin_Handled;
		}

		RemoveEntity(entity);
	}

	return Plugin_Handled;
}

Action CmdDelEnts(int client, int args)
{
	char sTemp[32];

	if( args == 1 )
	{
		GetCmdArg(1, sTemp, sizeof(sTemp));
		int entity = -1;
		while( (entity = FindEntityByClassname(entity, sTemp)) != INVALID_ENT_REFERENCE )
		{
			RemoveEntity(entity);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_delents <classname>");
	}

	return Plugin_Handled;
}

Action CmdEnt(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int entity = GetClientAimTarget(client, false);
	if( entity > 0 )
	{
		char sName[64], sClass[64];
		GetEdictClassname(entity, sClass, sizeof(sClass));
		GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));

		char sModel[128];
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

		int iHammerID = -1;
		if( HasEntProp(entity, Prop_Data, "m_iHammerID") )
			iHammerID = GetEntProp(entity, Prop_Data, "m_iHammerID");

		float vPos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);

		float vAng[3];
		GetEntPropVector(entity, Prop_Data, "m_angRotation", vAng);

		PrintToChat(client, "\x05%d \x01Class: \x05%s \x01Targetname: \x05%s \x01Model: \x05%s \x01HammerID: \x05%d \x01Position: \x05%.2f %.2f %.2f \x01Angles: \x05%.2f %.2f %.2f", entity, sClass, sName, sModel, iHammerID, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	}

	return Plugin_Handled;
}

Action CmdEntE(int client, int args)
{
	char sTemp[32];
	int entity;

	if( args == 1 )
	{
		GetCmdArg(1, sTemp, sizeof(sTemp));
		entity = StringToInt(sTemp);

		if( (entity < -1 && EntRefToEntIndex(entity) == INVALID_ENT_REFERENCE) || (entity >= MaxClients && IsValidEntity(entity) == false) )
		{
			ReplyToCommand(client, "[SM] Invalid Entity %d", entity);
			return Plugin_Handled;
		}
	}

	if( client && args == 0 )
	{
		entity = GetClientAimTarget(client, false);
		if( entity == -1 )
			return Plugin_Handled;
	}

	if( IsValidEntity(entity) )
	{
		char sName[64], sClass[64];
		GetEntPropString(entity, Prop_Data, "m_iClassname", sClass, sizeof(sClass));
		GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));

		char sModel[128];
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

		int iHammerID = -1;
		if( HasEntProp(entity, Prop_Data, "m_iHammerID") )
			iHammerID = GetEntProp(entity, Prop_Data, "m_iHammerID");

		float vPos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);

		float vAng[3];
		GetEntPropVector(entity, Prop_Data, "m_angRotation", vAng);

		if( client )
			PrintToChat(client, "\x05%d \x01Class: \x05%s \x01Targetname: \x05%s \x01Model: \x05%s \x01HammerID: \x05%d \x01Position: \x05%.2f %.2f %.2f \x01Angles: \x05%.2f %.2f %.2f", entity, sClass, sName, sModel, iHammerID, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
		else
			ReplyToCommand(client, "\x05%d \x01Class: \x05%s \x01Targetname: \x05%s \x01Model: \x05%s \x01HammerID: \x05%d \x01Position: \x05%.2f %.2f %.2f \x01Angles: \x05%.2f %.2f %.2f", entity, sClass, sName, sModel, iHammerID, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	} else {
		ReplyToCommand(client, "[SM] Invalid Entity %d", entity);
	}

	return Plugin_Handled;
}

Action CmdVertex(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sTemp[32];
	int entity;

	if( args == 1 )
	{
		GetCmdArg(1, sTemp, sizeof(sTemp));
		entity = StringToInt(sTemp);

		if( entity == 0 || (entity < -1 && EntRefToEntIndex(entity) == INVALID_ENT_REFERENCE) || (entity >= 0 && IsValidEntity(entity) == false) )
			return Plugin_Handled;
	}
	else
	{
		entity = GetClientAimTarget(client, false);
		if( entity == -1 )
			return Plugin_Handled;
	}

	float vMins[3]; float vMaxs[3];
	char sClass[64];

	GetEntPropString(entity, Prop_Data, "m_iClassname", sClass, sizeof(sClass));
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vMaxs);
	GetEntPropVector(entity, Prop_Send, "m_vecMins", vMins);

	if( client )
		PrintToChat(client, "\x05%d \x01Class: \x05%s \x01vecMins: \x05%.2f %.2f %.2f \x01vecMaxs: \x05%.2f %.2f %.2f", entity, sClass, vMins[0], vMins[1], vMins[2], vMaxs[0], vMaxs[1], vMaxs[2]);
	else
		ReplyToCommand(client, "%d Class: %s vecMins: %.2f %.2f %.2f vecMaxs: %.2f %.2f %.2f", entity, sClass, vMins[0], vMins[1], vMins[2], vMaxs[0], vMaxs[1], vMaxs[2]);

	return Plugin_Handled;
}

Action CmdBox(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sTemp[32];
	int entity;

	if( args == 1 )
	{
		GetCmdArg(1, sTemp, sizeof(sTemp));
		entity = StringToInt(sTemp);

		if( entity == 0 || (entity < -1 && EntRefToEntIndex(entity) == INVALID_ENT_REFERENCE) || (entity >= 0 && IsValidEntity(entity) == false) )
			return Plugin_Handled;
	}
	else
	{
		entity = GetClientAimTarget(client, false);
		if( entity == -1 )
			return Plugin_Handled;
	}

	float vPos[3]; float vMins[3]; float vMaxs[3];

	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vMaxs);
	GetEntPropVector(entity, Prop_Send, "m_vecMins", vMins);

	if( HasEntProp(entity, Prop_Send, "moveparent") && GetEntPropEnt(entity, Prop_Send, "moveparent") > 0 )
	{
		float vAdd[3];
		GetEntPropVector(GetEntPropEnt(entity, Prop_Send, "moveparent"), Prop_Send, "m_vecOrigin", vAdd);
		vPos[0] += vAdd[0];
		vPos[1] += vAdd[1];
		vPos[2] += vAdd[2];
	}

#if defined _smlib_included
	DrawDebugBox(entity, client, 10.0);
#else
	if( vMins[0] == vMaxs[0] && vMins[1] == vMaxs[1] && vMins[2] == vMaxs[2] )
	{
		vMins = view_as<float>({ -15.0, -15.0, -15.0 });
		vMaxs = view_as<float>({ 15.0, 15.0, 15.0 });
	}
	else
	{
		AddVectors(vPos, vMaxs, vMaxs);
		AddVectors(vPos, vMins, vMins);
	}

	float vPos1[3], vPos2[3], vPos3[3], vPos4[3], vPos5[3], vPos6[3];
	vPos1 = vMaxs;
	vPos1[0] = vMins[0];
	vPos2 = vMaxs;
	vPos2[1] = vMins[1];
	vPos3 = vMaxs;
	vPos3[2] = vMins[2];
	vPos4 = vMins;
	vPos4[0] = vMaxs[0];
	vPos5 = vMins;
	vPos5[1] = vMaxs[1];
	vPos6 = vMins;
	vPos6[2] = vMaxs[2];

	TE_SendBeam(vMaxs, vPos1);
	TE_SendBeam(vMaxs, vPos2);
	TE_SendBeam(vMaxs, vPos3);
	TE_SendBeam(vPos6, vPos1);
	TE_SendBeam(vPos6, vPos2);
	TE_SendBeam(vPos6, vMins);
	TE_SendBeam(vPos4, vMins);
	TE_SendBeam(vPos5, vMins);
	TE_SendBeam(vPos5, vPos1);
	TE_SendBeam(vPos5, vPos3);
	TE_SendBeam(vPos4, vPos3);
	TE_SendBeam(vPos4, vPos2);
#endif

	ReplyToCommand(client, "[Box] Displaying beams for 10 seconds on %d", entity);
	return Plugin_Handled;
}

#if defined _smlib_included
void DrawDebugBox(int entity, int client = 0, float time = 1.0, int color[4] = {0, 255, 0, 255})
{
	float vOrigin[3], vAng[3], vMins[3], vMaxs[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);
	GetEntPropVector(entity, Prop_Send, "m_vecMins", vMins);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vMaxs);

	if( GetVectorLength(vMins, true) == 0.0 && GetVectorLength(vMaxs, true) == 0.0)
	{
		Array_Fill(vMins, sizeof(vMins), -8.0);
		Array_Fill(vMaxs, sizeof(vMaxs), 8.0);
	}

	if( client )
	{
		Effect_DrawBeamBoxRotatableToClient(client, vOrigin, vMins, vMaxs, vAng, g_iLaserIndex, 0, 0, 0, time+0.1, 0.1, 0.1, 0, 0.0, color, 0);
		AddVectorInt(vMaxs, 20);
		Effect_DrawAxisOfRotationToClient(client, vOrigin, vAng, vMaxs, g_iLaserIndex, 0, 0, 0, time+0.1, 1.0, 1.0, 0, 0.0, 0);
	}
	else
	{
		Effect_DrawBeamBoxRotatableToAll(vOrigin, vMins, vMaxs, vAng, g_iLaserIndex, 0, 0, 0, time+0.1, 0.1, 0.1, 0, 0.0, color, 0);
		AddVectorInt(vMaxs, 20);
		Effect_DrawAxisOfRotationToAll(vOrigin, vAng, vMaxs, g_iLaserIndex, 0, 0, 0, time+0.1, 1.0, 1.0, 0, 0.0, 0);
	}
}

void AddVectorInt(float vVal[3], int val)
{
	vVal[0] += val;
	vVal[1] += val;
	vVal[2] += val;
}
#endif

stock void TE_SendBeam(const float vMins[3], const float vMaxs[3])
{
	TE_SetupBeamPoints(vMins, vMaxs, g_iLaserIndex, g_iHaloIndex, 0, 0, 5.0, 1.0, 1.0, 1, 0.0, { 255, 0, 0, 255 }, 0);
	TE_SendToAll();
}

Action CmdFind(int client, int args)
{
	if( args == 0 )
	{
		ReplyToCommand(client, "[Input] Usage: sm_find <classname>");
		return Plugin_Handled;
	}

	char class[64], sName[64], sTemp[16];
	float vPos[3], vMe[3], maxdist, dist;
	int offset, count, parent, entity = -1;
	GetCmdArg(1, class, sizeof(class));

	if( args > 1 && client )
	{
		GetCmdArg(2, sTemp, sizeof(sTemp));
		maxdist = StringToFloat(sTemp);
	}

	if( client )
	{
		GetClientAbsOrigin(client, vMe);
	}

	while( (entity = FindEntityByClassname(entity, class)) != INVALID_ENT_REFERENCE )
	{
		GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));

		offset = FindDataMapInfo(entity, "m_vecOrigin");

		if( offset != -1 )
		{
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);

			if( HasEntProp(entity, Prop_Send, "moveparent") )
			{
				parent = GetEntPropEnt(entity, Prop_Send, "moveparent");
				if( parent > 0 && IsValidEntity(parent) && HasEntProp(parent, Prop_Data, "m_vecOrigin") )
				{
					float vAdd[3];
					GetEntPropVector(parent, Prop_Data, "m_vecOrigin", vAdd);
					vPos[0] += vAdd[0];
					vPos[1] += vAdd[1];
					vPos[2] += vAdd[2];
				}
			}

			dist = GetVectorDistance(vPos, vMe);

			if( maxdist == 0.0 || dist <= maxdist )
			{
				if( client ) PrintToChat(client, "%d [%s] (dist: %f) - %f %f %f", entity, sName, dist, vPos[0], vPos[1], vPos[2]);
				else ReplyToCommand(client, "%d [%s] - %f %f %f", entity, sName, vPos[0], vPos[1], vPos[2]);
			}
		}
		else
		{
			if( maxdist == 0.0 )
			{
				if( client ) PrintToChat(client, "%d (%d) [%s]", entity, EntRefToEntIndex(entity), sName);
				else ReplyToCommand(client, "%d (%d) [%s]", entity, EntRefToEntIndex(entity), sName);
			}
		}
		count++;
	}
	return Plugin_Handled;
}

Action CmdFindName(int client, int args)
{
	if( args == 0 )
	{
		ReplyToCommand(client, "[Input] Usage: sm_findname <classname>");
		return Plugin_Handled;
	}

	char sFind[64], sTemp[64], sName[64];
	GetCmdArg(1, sFind, sizeof(sFind));

	for( int i = 0; i < 4096; i++ )
	{
		if( IsValidEntity(i) )
		{
			if( i <= 2048 || EntIndexToEntRef(i) != -1 )
			{
				GetEntPropString(i, Prop_Data, "m_iName", sName, sizeof(sName));
				if( StrContains(sName, sFind, false) != -1 )
				{
					GetEntityClassname(i, sTemp, sizeof(sTemp));

					if( client ) PrintToChat(client, "%d [%s] %s", i, sTemp, sName);
					else ReplyToCommand(client, "%d [%s] %s", i, sTemp, sName);
				}
			}
		}
	}
	return Plugin_Handled;
}

Action CmdCount(int client, int args)
{
	int count;
	int tt;
	char classname[64];
	char matching[64];
	StringMap hMap = new StringMap();

	if( args )
	{
		GetCmdArg(1, matching, sizeof(matching));
	}

	// Get counts
	for( int i = 0; i < 4096; i++ )
	{
		if( IsValidEntity(i) && IsValidEdict(i) )
		{
			tt++;
			GetEdictClassname(i, classname, sizeof(classname));

			if( !args || strcmp(matching, classname) == 0 )
			{
				if( hMap.GetValue(classname, count) == false )
					hMap.SetValue(classname, 1);
				else
					hMap.SetValue(classname, count + 1);
			}
		}
	}

	// Sort
	ArrayList hSortStr = new ArrayList(ByteCountToCells(64));
	StringMapSnapshot hSnap = hMap.Snapshot();
	int len = hSnap.Length;

	for( int i = 0; i < len; i++ )
	{
		hSnap.GetKey(i, classname, sizeof(classname));
		hMap.GetValue(classname, count);

		Format(classname, sizeof(classname), "%s>%d", classname, count);
		hSortStr.PushString(classname);
	}

	SortADTArray(hSortStr, Sort_Ascending, Sort_String);

	// Display
	for( int i = 0; i < len; i++ )
	{
		hSortStr.GetString(i, classname, sizeof(classname));
		count = StrContains(classname, ">");
		classname[count] = 0;
		count = StringToInt(classname[count+1]);
		ReplyToCommand(client, "%5d %s", count, classname);
	}

	ReplyToCommand(client, "Total: %d classnames from %d entities.", len, tt);

	// Clean up
	delete hMap;
	delete hSnap;
	delete hSortStr;
	return Plugin_Handled;
}

Action CmdModList(int client, int args)
{
	int offset, count;
	char sTemp[64];
	char sClas[64];

	for( int i = 1; i < 4096; i++ )
	{
		if( IsValidEntity(i) && IsValidEdict(i) )
		{
			GetEdictClassname(i, sClas, sizeof(sClas));
			offset = FindDataMapInfo(i, "m_ModelName");
			if( offset != -1 )
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));
				if( sTemp[0] )
				{
					LogModels("%s - %s", sTemp, sClas);
					count++;
				}
			}
		}
	}

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	ReplyToCommand(client, "[Models] Saved %d to \"/sourcemod/logs/models_%s.txt\"", count, sMap);
	return Plugin_Handled;
}

Action CmdColli(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int entity;

	if( args == 0 )
	{
		entity = GetClientAimTarget(client, false);
		if( entity == -1 )
		{
			ReplyToCommand(client, "[SM] sm_collision: Invalid aim target.");
			return Plugin_Handled;
		}
	} else {
		char sArg[8];
		GetCmdArg(1 ,sArg, sizeof(sArg));

		entity = StringToInt(sArg);
		if( entity <= 0 || entity > 2048 || !IsValidEntity(entity) )
		{
			ReplyToCommand(client, "[SM] sm_collision: Invalid entity specified.");
			return Plugin_Handled;
		}
	}

	if( GetEntProp(entity, Prop_Send, "m_nSolidType", 1) == view_as<int>(SOLID_NONE) )
	{
		ReplyToCommand(client, "[SM] sm_collision: Set target %d solid.", entity);
		SetEntitySolid(entity, true);
	}
	else
	{
		ReplyToCommand(client, "[SM] sm_collision: Set target %d non-solid.", entity);
		SetEntitySolid(entity, false);
	}

	return Plugin_Handled;
}

Action CmdMoveType(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args == 0 )
	{
		ReplyToCommand(client, "[SM] Usage: sm_movetype <type> [entity]");
		return Plugin_Handled;
	}

	char sArg[8];
	int entity;

	if( args == 1 )
	{
		entity = GetClientAimTarget(client, false);
		if( entity == -1 )
		{
			entity = client;
		}
	}
	else if( args == 2 )
	{
		GetCmdArg(2 ,sArg, sizeof(sArg));

		entity = StringToInt(sArg);
		if( entity <= 0 || entity > 2048 || !IsValidEntity(entity) )
		{
			ReplyToCommand(client, "[SM] sm_collision: Invalid entity specified.");
			return Plugin_Handled;
		}
	}

	GetCmdArg(1 ,sArg, sizeof(sArg));
	int type = StringToInt(sArg);

	SetEntityMoveType(entity, view_as<MoveType>(type));

	if( entity > 0 && entity <= MaxClients )
		ReplyToCommand(client, "[SM] Set MoveType %d on %N.", type, entity);
	else
		ReplyToCommand(client, "[SM] Set MoveType %d on %d.", type, entity);

	return Plugin_Handled;
}

bool g_bAnimWatch;
int g_iAnimIndex;
int g_iAnimTarget;
int g_iAnimLast;
Action CmdAnim(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int target = GetClientAimTarget(client, false);

	if( target < 0 )
	{
		target = client;
	}

	if( g_bAnimWatch )
	{
		g_bAnimWatch = false;
		PrintToChat(client, "Stopped watching entity: %d", g_iAnimIndex);
		return Plugin_Handled;
	}

	if( !HasEntProp(target, Prop_Send, "m_nSequence") )
	{
		PrintToChat(client, "%d entity doesn't have m_nSequence property!", target);
		return Plugin_Handled;
	}

	if( args > 0 )
	{
		char sTemp[16];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		int iSeq = StringToInt(sTemp);
		SetEntProp(target, Prop_Send, "m_nSequence", iSeq);
		return Plugin_Handled;
	}

	g_bAnimWatch = true;
	g_iAnimLast = 0;
	g_iAnimIndex = target;
	g_iAnimTarget = EntIndexToEntRef(target);
	RequestFrame(OnAnimFrame, GetClientUserId(client));

	return Plugin_Handled;
}

void OnAnimFrame(int userid)
{
	// Validate owner
	int client = GetClientOfUserId(userid);
	if( !client || !IsClientInGame(client) )
	{
		g_bAnimWatch = false;
		g_iAnimLast = 0;
		g_iAnimTarget = 0;
		return;
	}

	int target = EntRefToEntIndex(g_iAnimTarget);
	if( target != INVALID_ENT_REFERENCE && g_bAnimWatch )
	{
		int seq = GetEntProp(target, Prop_Send, "m_nSequence");
		if( g_iAnimLast != seq )
		{
			g_iAnimLast = seq;
			PrintToChat(client, "[SM] Ent: %d Anim: %d", target, seq);
		}

		RequestFrame(OnAnimFrame, userid);
		return;
	}

	g_bAnimWatch = false;
	g_iAnimLast = 0;
	g_iAnimTarget = 0;
	PrintToChat(client, "[SM] sm_anim finished.");
}

Action CmdWeapons(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char classname[64];
	int weapon;
	int target = GetClientAimTarget(client);
	if( target < 0 )
	{
		if( args == 1 )
		{
			GetCmdArg(1, classname, sizeof(classname));
			target = StringToInt(classname);
			if( target < 0 || target > MaxClients || !IsClientInGame(target) )
				target = client;
		}
		else target = client;
	}

	ReplyToCommand(client, "Showing weapons for: %N", target);

	weapon = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
	if( weapon != -1 )
	{
		GetEdictClassname(weapon, classname, sizeof(classname));
		ReplyToCommand(client, "Held = %d. %s", weapon, classname);
	}

	for( int i = 0; i <= 5; i++ )
	{
		weapon = GetPlayerWeaponSlot(target, i);
		if( weapon != -1 )
		{
			GetEdictClassname(weapon, classname, sizeof(classname));
			ReplyToCommand(client, "Slot %d = %d. %s", i, weapon, classname);
		}
	}

	return Plugin_Handled;
}

Action CmdWearables(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char classname[64];
	int weapon = -1;
	int target = GetClientAimTarget(client);
	if( target < 0 )
	{
		if( args == 1 )
		{
			GetCmdArg(1, classname, sizeof(classname));
			target = StringToInt(classname);
			if( target < 0 || target > MaxClients || !IsClientInGame(target) )
				target = client;
		}
		else target = client;
	}

	ReplyToCommand(client, "Showing cosmetics for: %N", target);

	while( (weapon = FindEntityByClassname(weapon, "tf_wearable")) != INVALID_ENT_REFERENCE )
	{
		if( GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity") == target )
		{
			ReplyToCommand(client, "Cosmetic: %d. Definition: %d", weapon, GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
		}
	}

	return Plugin_Handled;
}

Action CmdAttachments(int client, int args)
{
	if( args == 0 )
	{
		if( !client )
		{
			ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		}
		else
		{
			GetAttachments(client, client);
		}
	}
	else
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;

		if( (target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			int entity = StringToInt(arg1);
			if( entity > 0 && IsValidEntity(entity) )
			{
				GetAttachments(client, entity);
			}

			// ReplyToTargetError(client, target_count);
			// return Plugin_Handled;
		}

		int target;
		for( int i = 0; i < target_count; i++ )
		{
			target = target_list[i];

			GetAttachments(client, target);
		}
	}
	return Plugin_Handled;
}

void GetAttachments(int client, int target)
{
	char classname[64];

	for( int i = 1; i <= 2048; i++ )
	{
		if( IsValidEntity(i) && HasEntProp(i, Prop_Send, "moveparent") && GetEntPropEnt(i, Prop_Send, "moveparent") == target )
		{
			GetEdictClassname(i, classname, sizeof(classname));
			if( target <= MaxClients )
			{
				ReplyToCommand(client, "Attachment %N: %d %s", target, i, classname);
			} else {
				ReplyToCommand(client, "Attachment %d: %d %s", target, i, classname);
			}
		}
	}
}

Action CmdViewmodel(int client, int args)
{
	if( args == 0 )
	{
		if( !client )
		{
			ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		}
		else
		{
			GetViewmodel(client, client);
		}
	}
	else
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;

		if( (target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		int target;
		for( int i = 0; i < target_count; i++ )
		{
			target = target_list[i];

			GetViewmodel(client, target);
		}
	}
	return Plugin_Handled;
}

void GetViewmodel(int client, int target)
{
	ReplyToCommand(client, "Viewmodel (%d) %N = %d", target, target, GetEntPropEnt(target, Prop_Data, "m_hViewModel"));
}

Action CmdDelWeps(int client, int args)
{
	if( args == 0 )
	{
		DeleteWeapons(client, client);
	}
	else
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;

		if( (target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		int target;
		for( int i = 0; i < target_count; i++ )
		{
			target = target_list[i];

			DeleteWeapons(client, target);
		}
	}
	return Plugin_Handled;
}

void DeleteWeapons(int client, int target)
{
	int weapon;
	for( int i = 0; i < 5; i++ )
	{
		weapon = GetPlayerWeaponSlot(target, i);
		if( weapon != -1 )
		{
			RemovePlayerItem(client, weapon);
			RemoveEntity(weapon);
		}
	}
}

Action CmdSpeed(int client, int args)
{
	if( args == 0 )
	{
		GetSpeed(client);
	}
	else
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;

		if( (target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		int target;
		for( int i = 0; i < target_count; i++ )
		{
			target = target_list[i];

			GetSpeed(target);
		}
	}
	return Plugin_Handled;
}

void GetSpeed(int client)
{
	float vVec[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVec);
	float speed = GetVectorLength(vVec);
	ReplyToCommand(client, "Speed %N: %f", client, speed);
}

Action CmdClients(int client, int args)
{
	ReplyToCommand(client, "Index: UserID: Team: %20s Name:", "SteamID:");
	char steamID[64];

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientConnected(i) )
		{
			if( IsFakeClient(i) )
				steamID = "<BOT>";
			else
				GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID));

			ReplyToCommand(client, "%4d %6d %4d     %20s %N", i, GetClientUserId(i), IsClientInGame(i) ? GetClientTeam(i) : 0, steamID, i);
		}
	}
	return Plugin_Handled;
}

Action CmdUsers(int client, int args)
{
	ReplyToCommand(client, "[SM] Total Bots: %d. Total Clients: %d. Last UserID: %d", g_iTotalBots, g_iTotalPlays, g_iLastUserID);
	return Plugin_Handled;
}

Action CmdFreeze(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sEnt[16];
	int target;

	if( args > 0 )
	{
		GetCmdArg(1, sEnt, sizeof(sEnt));
		target = StringToInt(sEnt);
		if( !IsValidEntity(target) )
		{
			PrintToChat(client, "Entity %d is invalid.", target);
			return Plugin_Handled;
		}
	} else {
		target = GetClientAimTarget(client, false);
		if( target == -1)
		{
			PrintToChat(client, "Not aiming at a valid Entity.");
			return Plugin_Handled;
		}
	}

	if( !HasEntProp(target, Prop_Send, "movetype") )
	{
		PrintToChat(client, "Entity %d cannot be frozen.", target);
	} else {
		int mt = GetEntProp(target, Prop_Send, "movetype");

		if( mt == view_as<int>(MOVETYPE_NONE) )
		{
			SetEntProp(target, Prop_Send, "movetype", MOVETYPE_WALK);
			PrintToChat(client, "Entity %d is un-frozen.", target);
		} else {
			SetEntProp(target, Prop_Send, "movetype", MOVETYPE_NONE);
			PrintToChat(client, "Entity %d is frozen.", target);
		}
	}
	return Plugin_Handled;
}

Action CmdDamage(int client, int args)
{
	if( g_bDamage )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}

		if( client ) PrintToChat(client, "\x04[Damage Info]\x01 disabled!");
		else ReplyToCommand(client, "[Damage Info] disabled!");
	}
	else
	{
		if( args > 0 )
		{
			char sTemp[16];
			GetCmdArg(1, sTemp, sizeof(sTemp));
			g_iDamageRequestor = StringToInt(sTemp);
		}
		else
		{
			g_iDamageRequestor = -1;
		}

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}

		if( client ) PrintToChat(client, "\x04[Damage Info]\x01 enabled!");
		else ReplyToCommand(client, "[Damage Info] enabled!");
	}

	g_bDamage = !g_bDamage;
	return Plugin_Handled;
}

Action CmdSolid(int client, int args)
{
	if( args != 1 )
	{
		ReplyToCommand(client, "Usage: sm_solid <SolidType_t value>");
		return Plugin_Handled;
	}

	char sTemp[256];
	GetCmdArg(1, sTemp, sizeof(sTemp));
	int flags = StringToInt(sTemp);

	sTemp[0] = 0;
	switch( flags )
	{
		case view_as<int>(SOLID_NONE):							sTemp = "SOLID_NONE = 0";
		case view_as<int>(SOLID_BSP):							sTemp = "SOLID_BSP = 1";
		case view_as<int>(SOLID_BBOX):							sTemp = "SOLID_BBOX = 2";
		case view_as<int>(SOLID_OBB):							sTemp = "SOLID_OBB = 3";
		case view_as<int>(SOLID_OBB_YAW):						sTemp = "SOLID_OBB_YAW = 4";
		case view_as<int>(SOLID_CUSTOM):							sTemp = "SOLID_CUSTOM = 5";
		case view_as<int>(SOLID_VPHYSICS):						sTemp = "SOLID_VPHYSICS = 6";
	}

	ReplyToCommand(client, "SolidType_t %d = %s", flags, sTemp);
	return Plugin_Handled;
}

Action CmdSolidF(int client, int args)
{
	if( args != 1 )
	{
		ReplyToCommand(client, "Usage: sm_solidf <SolidFlags_t value>");
		return Plugin_Handled;
	}

	char sTemp[256];
	GetCmdArg(1, sTemp, sizeof(sTemp));
	int flags = StringToInt(sTemp);

	sTemp[0] = 0;
	if( flags & view_as<int>(FSOLID_CUSTOMRAYTEST) )				StrCat(sTemp, sizeof(sTemp), "FSOLID_CUSTOMRAYTEST = 0x0001; ");
	if( flags & view_as<int>(FSOLID_CUSTOMBOXTEST) )				StrCat(sTemp, sizeof(sTemp), "FSOLID_CUSTOMBOXTEST = 0x0002; ");
	if( flags & view_as<int>(FSOLID_NOT_SOLID) )					StrCat(sTemp, sizeof(sTemp), "FSOLID_NOT_SOLID = 0x0004; ");
	if( flags & view_as<int>(FSOLID_TRIGGER) )					StrCat(sTemp, sizeof(sTemp), "FSOLID_TRIGGER = 0x0008; ");
	if( flags & view_as<int>(FSOLID_NOT_STANDABLE) )				StrCat(sTemp, sizeof(sTemp), "FSOLID_NOT_STANDABLE = 0x0010; ");
	if( flags & view_as<int>(FSOLID_VOLUME_CONTENTS) )			StrCat(sTemp, sizeof(sTemp), "FSOLID_VOLUME_CONTENTS = 0x0020; ");
	if( flags & view_as<int>(FSOLID_FORCE_WORLD_ALIGNED) )		StrCat(sTemp, sizeof(sTemp), "FSOLID_FORCE_WORLD_ALIGNED = 0x0040; ");
	if( flags & view_as<int>(FSOLID_USE_TRIGGER_BOUNDS) )		StrCat(sTemp, sizeof(sTemp), "FSOLID_USE_TRIGGER_BOUNDS = 0x0080; ");
	if( flags & view_as<int>(FSOLID_ROOT_PARENT_ALIGNED) )		StrCat(sTemp, sizeof(sTemp), "FSOLID_ROOT_PARENT_ALIGNED = 0x0100; ");
	if( flags & view_as<int>(FSOLID_TRIGGER_TOUCH_DEBRIS) )		StrCat(sTemp, sizeof(sTemp), "FSOLID_TRIGGER_TOUCH_DEBRIS = 0x0200; ");

	if( sTemp[0] ) sTemp[strlen(sTemp) - 2] = 0; // Clear last "; "

	ReplyToCommand(client, "SolidFlags_t %d = %s", flags, sTemp);
	return Plugin_Handled;
}

Action CmdDmg(int client, int args)
{
	if( args != 1 )
	{
		ReplyToCommand(client, "Usage: sm_dmg <damage flags value>");
		return Plugin_Handled;
	}

	char sTemp[256];
	GetCmdArg(1, sTemp, sizeof(sTemp));
	int flags = StringToInt(sTemp);

	sTemp[0] = 0;
	if( flags & DMG_GENERIC )					StrCat(sTemp, sizeof(sTemp), "DMG_GENERIC 0; ");
	if( flags & DMG_CRUSH )						StrCat(sTemp, sizeof(sTemp), "DMG_CRUSH (1<<0); ");
	if( flags & DMG_BULLET )					StrCat(sTemp, sizeof(sTemp), "DMG_BULLET (1<<1); ");
	if( flags & DMG_SLASH )						StrCat(sTemp, sizeof(sTemp), "DMG_SLASH (1<<2); ");
	if( flags & DMG_BURN )						StrCat(sTemp, sizeof(sTemp), "DMG_BURN (1<<3); ");
	if( flags & DMG_VEHICLE )					StrCat(sTemp, sizeof(sTemp), "DMG_VEHICLE (1<<4); ");
	if( flags & DMG_FALL )						StrCat(sTemp, sizeof(sTemp), "DMG_FALL (1<<5); ");
	if( flags & DMG_BLAST )						StrCat(sTemp, sizeof(sTemp), "DMG_BLAST (1<<6); ");
	if( flags & DMG_CLUB )						StrCat(sTemp, sizeof(sTemp), "DMG_CLUB (1<<7); ");
	if( flags & DMG_SHOCK )						StrCat(sTemp, sizeof(sTemp), "DMG_SHOCK (1<<8); ");
	if( flags & DMG_SONIC )						StrCat(sTemp, sizeof(sTemp), "DMG_SONIC (1<<9); ");
	if( flags & DMG_ENERGYBEAM )				StrCat(sTemp, sizeof(sTemp), "DMG_ENERGYBEAM (1<<10); ");
	if( flags & DMG_PREVENT_PHYSICS_FORCE )		StrCat(sTemp, sizeof(sTemp), "DMG_PREVENT_PHYSICS_FORCE (1<<11); ");
	if( flags & DMG_NEVERGIB )					StrCat(sTemp, sizeof(sTemp), "DMG_NEVERGIB (1<<12); ");
	if( flags & DMG_ALWAYSGIB )					StrCat(sTemp, sizeof(sTemp), "DMG_ALWAYSGIB (1<<13); ");
	if( flags & DMG_DROWN )						StrCat(sTemp, sizeof(sTemp), "DMG_DROWN (1<<14); ");
	if( flags & DMG_PARALYZE )					StrCat(sTemp, sizeof(sTemp), "DMG_PARALYZE (1<<15); ");
	if( flags & DMG_NERVEGAS )					StrCat(sTemp, sizeof(sTemp), "DMG_NERVEGAS (1<<16); ");
	if( flags & DMG_POISON )					StrCat(sTemp, sizeof(sTemp), "DMG_POISON (1<<17); ");
	if( flags & DMG_RADIATION )					StrCat(sTemp, sizeof(sTemp), "DMG_RADIATION (1<<18); ");
	if( flags & DMG_DROWNRECOVER )				StrCat(sTemp, sizeof(sTemp), "DMG_DROWNRECOVER (1<<19); ");
	if( flags & DMG_ACID )						StrCat(sTemp, sizeof(sTemp), "DMG_ACID (1<<20); ");
	if( flags & DMG_SLOWBURN )					StrCat(sTemp, sizeof(sTemp), "DMG_SLOWBURN (1<<21); ");
	if( flags & DMG_REMOVENORAGDOLL )			StrCat(sTemp, sizeof(sTemp), "DMG_REMOVENORAGDOLL (1<<22); ");
	if( flags & DMG_PHYSGUN )					StrCat(sTemp, sizeof(sTemp), "DMG_PHYSGUN (1<<23); ");
	if( flags & DMG_PLASMA )					StrCat(sTemp, sizeof(sTemp), "DMG_PLASMA (1<<24); ");
	if( flags & DMG_AIRBOAT )					StrCat(sTemp, sizeof(sTemp), "DMG_AIRBOAT (1<<25); ");
	if( flags & DMG_DISSOLVE )					StrCat(sTemp, sizeof(sTemp), "DMG_DISSOLVE (1<<26); ");
	if( flags & DMG_BLAST_SURFACE )				StrCat(sTemp, sizeof(sTemp), "DMG_BLAST_SURFACE (1<<27); ");
	if( flags & DMG_DIRECT )					StrCat(sTemp, sizeof(sTemp), "DMG_DIRECT (1<<28); ");
	if( flags & DMG_BUCKSHOT )					StrCat(sTemp, sizeof(sTemp), "DMG_BUCKSHOT (1<<29); ");

	if( sTemp[0] ) sTemp[strlen(sTemp) - 2] = 0; // Clear last "; "

	ReplyToCommand(client, "Dmg Flags %d = %s", flags, sTemp);
	return Plugin_Handled;
}

Action CmdSetDmg(int client, int args)
{
	if( args < 2 )
	{
		ReplyToCommand(client, "Usage: sm_setdmg <target index> <damage amount> [damage type enum] [inflictor index]");
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArg(1, sArg, sizeof(sArg));
	int target = StringToInt(sArg);

	GetCmdArg(2, sArg, sizeof(sArg));
	float damage = StringToFloat(sArg);

	int type = DMG_GENERIC;
	if( args >= 3 )
	{
		GetCmdArg(3, sArg, sizeof(sArg));
		type = StringToInt(sArg);
	}

	int inflictor;
	if( args == 4 )
	{
		GetCmdArg(4, sArg, sizeof(sArg));
		inflictor = StringToInt(sArg);
	}

	SDKHooks_TakeDamage(target, inflictor, inflictor, damage, type);

	return Plugin_Handled;
}

Action CmdVal(int client, int args)
{
	if( args != 1 )
	{
		ReplyToCommand(client, "Usage: sm_val <bit value>. e.g: sm_val 1<<20");
		return Plugin_Handled;
	}

	char sArg[16];
	char sTemp[16];
	GetCmdArg(1, sArg, sizeof(sArg));

	int pos = SplitString(sArg, "<<", sTemp, sizeof(sTemp));
	if( pos == -1 )
	{
		ReplyToCommand(client, "Usage: sm_val <bit value>. e.g: sm_val 1<<20");
		return Plugin_Handled;
	}

	int a = StringToInt(sTemp);
	int b = StringToInt(sArg[pos]);

	ReplyToCommand(client, "[SM] Bit Value: (%d << %d) = %d", a, b, a << b);

	return Plugin_Handled;
}

Action CmdBit(int client, int args)
{
	if( args != 1 )
	{
		ReplyToCommand(client, "Usage: sm_bit <bit value>. e.g: sm_bit 1048576");
		return Plugin_Handled;
	}

	char sArg[16];
	char sTemp[256];
	GetCmdArg(1, sArg, sizeof(sArg));
	int bits = StringToInt(sArg);

	for( int i = 0; i < 32; i++ )
	{
		if( bits & (1<<i) )
		{
			Format(sTemp, sizeof(sTemp), "%s; (1<<%d)", sTemp, i);
		}
	}

	strcopy(sTemp, sizeof(sTemp), sTemp[2]); // Clear starting "; "

	ReplyToCommand(client, "[SM] Bit Value: %d = %s", bits, sTemp);

	return Plugin_Handled;
}

int g_iAdmin[MAXPLAYERS+1];
Action CmdAdm(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( GetUserFlagBits(client) == ADMFLAG_ROOT )
	{
		PrintToChat(client, "[SM] sm_adm: Current: %d. ROOT: %d. BAN: %d", GetUserFlagBits(client), ADMFLAG_ROOT, ADMFLAG_BAN);

		g_iAdmin[client] = GetClientUserId(client);

		if( args )
		{
			int flags, index;
			char sTemp[256], sRet[256];

			while( index < args )
			{
				index++;
				GetCmdArg(index, sTemp, sizeof(sTemp));

				if( strcmp(sTemp, "RESERVATION") == 0 )		{ flags |= (1<<0);		StrCat(sRet, sizeof(sRet), "RESERVATION|"); }
				if( strcmp(sTemp, "GENERIC") == 0 )			{ flags |= (1<<1);		StrCat(sRet, sizeof(sRet), "GENERIC|"); }
				if( strcmp(sTemp, "KICK") == 0 )			{ flags |= (1<<2);		StrCat(sRet, sizeof(sRet), "KICK|"); }
				if( strcmp(sTemp, "BAN") == 0 )				{ flags |= (1<<3);		StrCat(sRet, sizeof(sRet), "BAN|"); }
				if( strcmp(sTemp, "UNBAN") == 0 )			{ flags |= (1<<4);		StrCat(sRet, sizeof(sRet), "UNBAN|"); }
				if( strcmp(sTemp, "SLAY") == 0 )			{ flags |= (1<<5);		StrCat(sRet, sizeof(sRet), "SLAY|"); }
				if( strcmp(sTemp, "CHANGEMAP") == 0 )		{ flags |= (1<<6);		StrCat(sRet, sizeof(sRet), "CHANGEMAP|"); }
				if( strcmp(sTemp, "CONVARS") == 0 )			{ flags |= (1<<7);		StrCat(sRet, sizeof(sRet), "CONVARS|"); }
				if( strcmp(sTemp, "CONFIG") == 0 )			{ flags |= (1<<8);		StrCat(sRet, sizeof(sRet), "CONFIG|"); }
				if( strcmp(sTemp, "CHAT") == 0 )			{ flags |= (1<<9);		StrCat(sRet, sizeof(sRet), "CHAT|"); }
				if( strcmp(sTemp, "VOTE") == 0 )			{ flags |= (1<<10);		StrCat(sRet, sizeof(sRet), "VOTE|"); }
				if( strcmp(sTemp, "PASSWORD") == 0 )		{ flags |= (1<<11);		StrCat(sRet, sizeof(sRet), "PASSWORD|"); }
				if( strcmp(sTemp, "RCON") == 0 )			{ flags |= (1<<12);		StrCat(sRet, sizeof(sRet), "RCON|"); }
				if( strcmp(sTemp, "CHEATS") == 0 )			{ flags |= (1<<13);		StrCat(sRet, sizeof(sRet), "CHEATS|"); }
				if( strcmp(sTemp, "ROOT") == 0 )			{ flags |= (1<<14);		StrCat(sRet, sizeof(sRet), "ROOT|"); }
				if( strcmp(sTemp, "CUSTOM1") == 0 )			{ flags |= (1<<15);		StrCat(sRet, sizeof(sRet), "CUSTOM1|"); }
				if( strcmp(sTemp, "CUSTOM2") == 0 )			{ flags |= (1<<16);		StrCat(sRet, sizeof(sRet), "CUSTOM2|"); }
				if( strcmp(sTemp, "CUSTOM3") == 0 )			{ flags |= (1<<17);		StrCat(sRet, sizeof(sRet), "CUSTOM3|"); }
				if( strcmp(sTemp, "CUSTOM4") == 0 )			{ flags |= (1<<18);		StrCat(sRet, sizeof(sRet), "CUSTOM4|"); }
				if( strcmp(sTemp, "CUSTOM5") == 0 )			{ flags |= (1<<19);		StrCat(sRet, sizeof(sRet), "CUSTOM5|"); }
				if( strcmp(sTemp, "CUSTOM6") == 0 )			{ flags |= (1<<20);		StrCat(sRet, sizeof(sRet), "CUSTOM6|"); }
			}

			if( sRet[0] ) sRet[strlen(sRet) - 1] = 0; // Clear last "|"
			PrintToChat(client, "[SM] sm_adm: Set admin flag: %s (%d)", sRet, flags);

			SetUserFlagBits(client, flags);
		} else {
			SetUserFlagBits(client, ADMFLAG_BAN);
			PrintToChat(client, "[SM] sm_adm: Set admin flag: BAN");
		}
	}
	else
	{
		if( g_iAdmin[client] && GetClientOfUserId(g_iAdmin[client]) == client )
		{
			PrintToChat(client, "[SM] sm_adm: Current: %d. ROOT: %d. BAN: %d", GetUserFlagBits(client), ADMFLAG_ROOT, ADMFLAG_BAN);

			g_iAdmin[client] = 0;
			SetUserFlagBits(client, ADMFLAG_ROOT);
			PrintToChat(client, "[SM] sm_adm: Restored flag: ROOT");
		}
	}

	return Plugin_Handled;
}

Action CmdHexCol(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	PrintToChat(client, "\x01 \x01\\01");
	PrintToChat(client, "\x01 \x02\\02");
	PrintToChat(client, "\x01 \x03\\03");
	PrintToChat(client, "\x01 \x04\\04");
	PrintToChat(client, "\x01 \x05\\05");
	PrintToChat(client, "\x01 \x06\\06");
	PrintToChat(client, "\x01 \x07\\07");
	PrintToChat(client, "\x01 \x08\\08");
	PrintToChat(client, "\x01 \x09\\09");
	PrintToChat(client, "\x01 \x10\\10");
	PrintToChat(client, "\x01 \x11\\11");
	PrintToChat(client, "\x01 \x12\\12");
	PrintToChat(client, "\x01 \x13\\13");
	PrintToChat(client, "\x01 \x14\\14");
	PrintToChat(client, "\x01 \x15\\15");
	PrintToChat(client, "\x01 \x16\\16");
	PrintToChat(client, "\x01 \x17\\17");
	PrintToChat(client, "\x01 \x18\\18");
	PrintToChat(client, "\x01 \x19\\19");
	PrintToChat(client, "\x01 \x20\\20");
	PrintToChat(client, "\x01 \x21\\21");
	PrintToChat(client, "\x01 \x22\\22");
	PrintToChat(client, "\x01 \x23\\23");
	PrintToChat(client, "\x01 \x24\\24");
	PrintToChat(client, "\x01 \x25\\25");
	PrintToChat(client, "\x01 \x26\\26");
	PrintToChat(client, "\x01 \x27\\27");
	PrintToChat(client, "\x01 \x28\\28");
	PrintToChat(client, "\x01 \x29\\29");
	PrintToChat(client, "\x01 \x30\\30");
	PrintToChat(client, "\x01 \x31\\31");

	// Why doesn't this work:
	/*
	for( int i = 1; i <= 31; i++ )
	{
		PrintToChat(client, " \x01\x%02X\\x%02X", i, i);
	}
	// */

	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	if( IsFakeClient(client) )
	{
		g_iTotalBots++;
	}

	int user = GetClientUserId(client);
	if( user > g_iLastUserID ) g_iLastUserID = user;

	g_iAdmin[client] = 0;

	if( g_bDamage )
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void OnClientConnected(int client)
{
	if( !IsFakeClient(client) )
	{
		g_iTotalPlays++;
		g_iPlayers++;

		if( g_iPlayers == 1 )
		{
			g_iPlayTime = GetTime();
		}
	}
}

public void OnClientDisconnect(int client)
{
	if( g_bDamage )
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}

	// Play time
	if( !IsFakeClient(client) )
	{
		g_iPlayers--;

		if( g_iPlayers == 0 )
		{
			g_iPlayedTime += GetTime() - g_iPlayTime;
		}
	}

}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if( g_iDamageRequestor != -1 )
	{
		if( victim != g_iDamageRequestor && attacker != g_iDamageRequestor )
		{
			return Plugin_Continue;
		}
	}

	char sClassAttacker[64];
	char sClassInflictor[64];
	GetEdictClassname(attacker, sClassAttacker, sizeof(sClassAttacker));
	GetEdictClassname(inflictor, sClassInflictor, sizeof(sClassInflictor));

	char msg[256];
	Format(msg, sizeof(msg), "\x03Damage taken: \x01victim:\x05%d \x01| attacker:\x05%d (%s) \x01| inflictor:\x05%d (%s) \x01|\
	dmg:\x05%0.2f \x01| dmg type:\x05%d \x01| weapon ent:\x05%d \x01| force:\x05%0.2f \x01| dmg pos:\x05%0.2f",
	victim, attacker, sClassAttacker, inflictor, sClassInflictor, damage, damagetype, weapon, damageForce, damagePosition);

	PrintToChatAll(msg);
	// PrintToConsoleAll(msg);

	return Plugin_Continue;
}



// ====================================================================================================
//					COMMANDS - ENTITY PROPERTIES - sm_gamerules, sm_prop, sm_propent, sm_propi
// ====================================================================================================
Action CmdGameRules(int client, int args)
{
	if( g_sGameRulesClass[0] )
	{
		static int entity;

		if( !IsValidEntRef(entity) )
		{
			entity = FindEntityByClassname(-1, g_sGameRulesClass);

			if( entity != INVALID_ENT_REFERENCE )
				entity = EntIndexToEntRef(entity);
		}

		if( entity != INVALID_ENT_REFERENCE )
		{
			char sProp[64], sValue[64];
			GetCmdArg(1, sProp, sizeof(sProp));
			if( args == 2 )
				GetCmdArg(2, sValue, sizeof(sValue));

			PropertyValue(client, EntRefToEntIndex(entity), args, sProp, sValue);
		}
		else
		{
			ReplyToCommand(client, "[SM] Error: Cannot find the GameRules \"%s\" entity.", g_sGameRulesClass);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Error: Missing GameRules classname.");
	}
	
	return Plugin_Handled;
}

Action CmdProp(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
	}
	else if( args < 1 || args > 2 )
	{
		ReplyToCommand(client, "[SM] Usage: sm_prop <property name> [value].");
	}
	else if( IsClientInGame(client) )
	{
		int entity = GetClientAimTarget(client, false);
		if( entity == -1 )
			return Plugin_Handled;

		char sProp[64], sValue[64];
		GetCmdArg(1, sProp, sizeof(sProp));
		if( args == 2 )
			GetCmdArg(2, sValue, sizeof(sValue));

		PropertyValue(client, entity, args, sProp, sValue);
	}

	return Plugin_Handled;
}

Action CmdPropEnt(int client, int args)
{
	if( args < 2 || args > 3 )
	{
		ReplyToCommand(client, "[SM] Usage: sm_propent <entity index> <property name> [value].");
	}
	else
	{
		char sTemp[64], sProp[64], sValue[64];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		GetCmdArg(2, sProp, sizeof(sProp));
		if( args == 3 )
			GetCmdArg(3, sValue, sizeof(sValue));

		char sTrgName[MAX_TARGET_LENGTH];
		int	 aTrgList[MAXPLAYERS], iTrgCount;
		bool bNameMultiLang;

		if( (iTrgCount = ProcessTargetString(sTemp, client, aTrgList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, sTrgName, sizeof(sTrgName), bNameMultiLang)) <= 0 )
		{
			int entity = StringToInt(sTemp);
			if( IsValidEntity(entity) )
			{
				PropertyValue(client, entity, args-1, sProp, sValue);
			}
			return Plugin_Handled;
		}

		for( int i = 0; i < iTrgCount; i++)
		{
			if( IsValidEntity(aTrgList[i]) )
			{
				PropertyValue(client, aTrgList[i], args-1, sProp, sValue);
			}
		}
	}

	return Plugin_Handled;
}

Action CmdPropMe(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
	}
	else if( args < 1 || args > 2 )
	{
		PrintToChat(client, "[SM] Usage: sm_propi <property name> [value].");
	}
	else
	{
		char sProp[64], sValue[64];
		GetCmdArg(1, sProp, sizeof(sProp));
		if( args == 2 )
			GetCmdArg(2, sValue, sizeof(sValue));

		PropertyValue(client, client, args, sProp, sValue);
	}

	return Plugin_Handled;
}

void PropertyValue(int client, int entity, int args, char sProp[64], const char sValue[64])
{
	char sClass[64], sValueTemp[64], sMember[8], sTemp[3][16];
	float vVec[3];
	PropFieldType proptype;
	GetEntityNetClass(entity, sClass, sizeof(sClass));

	// Match gamerules net class
	bool gamerules;
	if( g_sGameRulesNet[0] && strcmp(sClass, g_sGameRulesNet) == 0 )
		gamerules = true;

	// Member offset
	int member;
	int pos;
	if( (pos = FindCharInString(sProp, '.', true)) != -1 )
	{
		int len = strlen(sProp);
		for( int i = pos + 1; i < len; i++ )
		{
			if( IsCharNumeric(sProp[i]) == false )
			{
				pos = 0;
				break;
			}
		}

		if( pos )
		{
			member = StringToInt(sProp[pos + 1]);
			sProp[pos] = '\x0';
			Format(sMember, sizeof(sMember), ".%03d", member);
		}
	}

	// READ
	if( args == 1 )
	{
		// PROP SEND
		int offset = FindSendPropInfo(sClass, sProp, proptype);
		if( offset > 0 )
		{
			if( member && GetEntPropArraySize(entity, Prop_Send, sProp) <= member )
			{
				ReplyToCommand(client, "Member size %00d is too large for this entity Prop_Send. Maximum %d member elements (starting from index 0).", member, GetEntPropArraySize(entity, Prop_Send, sProp));
				sMember[0] = 0;
				member = 0;
			}

			if( g_hEntityKeys.ContainsKey(sProp) )
			{
				proptype = PropField_Entity;
			}

			if( proptype == PropField_Integer )
			{
				if( client )
					PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 integer \"%s\" \"%s%s\" is \x05%d", entity, sClass, sProp, sMember, GetEntProp(entity, Prop_Send, sProp, _, member));
				else
					ReplyToCommand(client, "%d) Prop_Send integer \"%s\" \"%s%s\" is %d", entity, sClass, sProp, sMember, GetEntProp(entity, Prop_Send, sProp, _, member));
			}
			else if( proptype == PropField_Entity )
			{
				if( client )
					PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 entity \"%s\" \"%s%s\" is \x05%d", entity, sClass, sProp, sMember, GetEntPropEnt(entity, Prop_Send, sProp, member));
				else
					ReplyToCommand(client, "%d) Prop_Send entity \"%s\" \"%s%s\" is %d", entity, sClass, sProp, sMember, GetEntPropEnt(entity, Prop_Send, sProp, member));
			}
			else if( proptype == PropField_Float )
			{
				if( client )
					PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 float \"%s\" \"%s%s\" is \x05%f", entity, sClass, sProp, sMember, GetEntPropFloat(entity, Prop_Send, sProp, member));
				else
					ReplyToCommand(client, "%d) Prop_Send float \"%s\" \"%s%s\" is %f", entity, sClass, sProp, sMember, GetEntPropFloat(entity, Prop_Send, sProp, member));
			}
			else if( proptype == PropField_String || proptype == PropField_String_T )
			{
				GetEntPropString(entity, Prop_Send, sProp, sValueTemp, sizeof(sValueTemp), member);

				if( client )
					PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 string \"%s\" \"%s%s\" is \x05%s", entity, sClass, sProp, sMember, sValueTemp);
				else
					ReplyToCommand(client, "%d) Prop_Send string \"%s\" \"%s%s\" is %s", entity, sClass, sProp, sMember, sValueTemp);
			}
			else if( proptype == PropField_Vector )
			{
				GetEntPropVector(entity, Prop_Send, sProp, vVec, member);

				if( client )
					PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 vector \"%s\" \"%s%s\" is \x05%f %f %f", entity, sClass, sProp, sMember, vVec[0], vVec[1], vVec[2]);
				else
					ReplyToCommand(client, "%d) Prop_Send vector \"%s\" \"%s%s\" is %f %f %f", entity, sClass, sProp, sMember, vVec[0], vVec[1], vVec[2]);
			}
			else
			{
				if( proptype == PropField_Unsupported )
				{
					if( client )
						PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 \"%s\" \"%s\" Error: PropField_Unsupported.", entity, sClass, sProp);
					else
						ReplyToCommand(client, "%d) Prop_Send \"%s\" \"%s\" Error: PropField_Unsupported.", entity, sClass, sProp);
				}
				else
				{
					if( client )
						PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 \"%s\" \"%s\" Unknown Error.", entity, sClass, sProp);
					else
						ReplyToCommand(client, "%d) Prop_Send \"%s\" \"%s\" Unknown Error.", entity, sClass, sProp);
				}
			}
		}


		// PROP DATA
		offset = FindDataMapInfo(entity, sProp, proptype);
		if( offset != -1 )
		{
			if( member && GetEntPropArraySize(entity, Prop_Data, sProp) <= member )
			{
				ReplyToCommand(client, "Member size %00d is too large for this entity Prop_Data. Maximum %d member elements (starting from index 0).", member, GetEntPropArraySize(entity, Prop_Data, sProp));
				member = 0;
			}

			if( g_hEntityKeys.ContainsKey(sProp) )
			{
				proptype = PropField_Entity;
			}

			if( proptype == PropField_Integer )
			{
				if( client )
					PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 integer \"%s\" \"%s%s\" is \x05%d", entity, sClass, sProp, sMember, GetEntProp(entity, Prop_Data, sProp, _, member));
				else
					ReplyToCommand(client, "%d) Prop_Data integer \"%s\" \"%s%s\" is %d", entity, sClass, sProp, sMember, GetEntProp(entity, Prop_Data, sProp, _, member));
			}
			else if( proptype == PropField_Entity )
			{
				if( client )
					PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 entity \"%s\" \"%s%s\" is \x05%d", entity, sClass, sProp, sMember, GetEntPropEnt(entity, Prop_Data, sProp, member));
				else
					ReplyToCommand(client, "%d) Prop_Data entity \"%s\" \"%s%s\" is %d", entity, sClass, sProp, sMember, GetEntPropEnt(entity, Prop_Data, sProp, member));
			}
			else if( proptype == PropField_Float )
			{
				if( client )
					PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 float \"%s\" \"%s%s\" is \x05%f", entity, sClass, sProp, sMember, GetEntPropFloat(entity, Prop_Data, sProp, member));
				else
					ReplyToCommand(client, "%d) Prop_Data float \"%s\" \"%s%s\" is %f", entity, sClass, sProp, sMember, GetEntPropFloat(entity, Prop_Data, sProp, member));
			}
			else if( proptype == PropField_String || proptype == PropField_String_T )
			{
				GetEntPropString(entity, Prop_Data, sProp, sValueTemp, sizeof(sValueTemp), member);

				if( client )
					PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 string \"%s\" \"%s%s\" is \x05%s", entity, sClass, sProp, sMember, sValueTemp);
				else
					ReplyToCommand(client, "%d) Prop_Data string \"%s\" \"%s%s\" is %s", entity, sClass, sProp, sMember, sValueTemp);
			}
			else if( proptype == PropField_Vector )
			{
				GetEntPropVector(entity, Prop_Data, sProp, vVec, member);

				if( client )
					PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 vector \"%s\" \"%s%s\" is \x05%f %f %f", entity, sClass, sProp, sMember, vVec[0], vVec[1], vVec[2]);
				else
					ReplyToCommand(client, "%d) Prop_Data vector \"%s\" \"%s%s\" is %f %f %f", entity, sClass, sProp, sMember, vVec[0], vVec[1], vVec[2]);
			}
			else
			{
				if( proptype == PropField_Unsupported )
				{
					if( client )
						PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 \"%s\" \"%s\" Error: PropField_Unsupported.", entity, sClass, sProp);
					else
						ReplyToCommand(client, "%d) Prop_Data \"%s\" \"%s\" Error: PropField_Unsupported.", entity, sClass, sProp);
				}
				else
				{
					if( client )
						PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 \"%s\" \"%s\" Unknown Error.", entity, sClass, sProp);
					else
						ReplyToCommand(client, "%d) Prop_Data \"%s\" \"%s\" Unknown Error.", entity, sClass, sProp);
				}
			}
		}
	}


	// WRITE
	else
	{
		// PROP SEND
		int offset = FindSendPropInfo(sClass, sProp, proptype);
		if( offset > 0 )
		{
			if( member && GetEntPropArraySize(entity, Prop_Send, sProp) <= member )
			{
				ReplyToCommand(client, "Member size %00d is too large for this entity Prop_Data. Maximum %d member elements (starting from index 0).", member, GetEntPropArraySize(entity, Prop_Send, sProp));
				member = 0;
			}

			if( g_hEntityKeys.ContainsKey(sProp) )
			{
				proptype = PropField_Entity;
			}

			if( proptype == PropField_Integer )
			{
				int value = StringToInt(sValue);

				if( gamerules )
					GameRules_SetProp(sProp, value, _, member);
				else
					SetEntProp(entity, Prop_Send, sProp, value, _, member);

				if( client )
					PrintToChat(client, "\x05%d\x01) Set \x03Prop_Send\x01 integer \"%s\" \"%s%s\" to \x05%d", entity, sClass, sProp, sMember, value);
				else
					ReplyToCommand(client, "%d) Set Prop_Send integer \"%s\" \"%s%s\" to %d", entity, sClass, sProp, sMember, value);
			}
			else if( proptype == PropField_Entity )
			{
				int value = StringToInt(sValue);

				if( gamerules )
					GameRules_SetPropEnt(sProp, value, member);
				else
					SetEntPropEnt(entity, Prop_Send, sProp, value, member);

				if( client )
					PrintToChat(client, "\x05%d\x01) Set \x03Prop_Send\x01 entity \"%s\" \"%s%s\" to \x05%d", entity, sClass, sProp, sMember, value);
				else
					ReplyToCommand(client, "%d) Set Prop_Send entity \"%s\" \"%s%s\" to %d", entity, sClass, sProp, sMember, value);
			}
			else if( proptype == PropField_Float )
			{
				float value = StringToFloat(sValue);

				if( gamerules )
					GameRules_SetPropFloat(sProp, value, member);
				else
					SetEntPropFloat(entity, Prop_Send, sProp, value, member);

				if( client )
					PrintToChat(client, "\x05%d\x01) Set \x03Prop_Send\x01 float \"%s\" \"%s%s\" to \x05%f", entity, sClass, sProp, sMember, value);
				else
					ReplyToCommand(client, "%d) Set Prop_Send float \"%s\" \"%s%s\" to %f", entity, sClass, sProp, sMember, value);
			}
			else if( proptype == PropField_String || proptype == PropField_String_T )
			{
				if( gamerules )
					GameRules_SetPropString(sProp, sValue, _, member);
				else
					SetEntPropString(entity, Prop_Send, sProp, sValue, member);

				if( client )
					PrintToChat(client, "\x05%d\x01) Set \x03Prop_Send\x01 string \"%s\" \"%s%s\" to \x05%s", entity, sClass, sProp, sMember, sValue);
				else
					ReplyToCommand(client, "%d) Set Prop_Send string \"%s\" \"%s%s\" to %s", entity, sClass, sProp, sMember, sValue);
			}
			else if( proptype == PropField_Vector )
			{
				ExplodeString(sValue, " ", sTemp, sizeof(sTemp), sizeof(sTemp[]));
				vVec[0] = StringToFloat(sTemp[0]);
				vVec[1] = StringToFloat(sTemp[1]);
				vVec[2] = StringToFloat(sTemp[2]);

				if( gamerules )
					GameRules_SetPropVector(sProp, vVec, member);
				else
					SetEntPropVector(entity, Prop_Send, sProp, vVec, member);

				if( client )
					PrintToChat(client, "\x05%d\x01) Set \x03Prop_Send\x01 vector \"%s\" \"%s%s\" to \x05%f %f %f", entity, sClass, sProp, sMember, vVec[0], vVec[1], vVec[2]);
				else
					ReplyToCommand(client, "%d) Set Prop_Send vector \"%s\" \"%s%s\" to %f %f %f", entity, sClass, sProp, sMember, vVec[0], vVec[1], vVec[2]);
			}
			else
			{
				if( proptype == PropField_Unsupported )
				{
					if( client )
						PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 \"%s\" \"%s\" Error: PropField_Unsupported.", entity, sClass, sProp);
					else
						ReplyToCommand(client, "%d) Prop_Send \"%s\" \"%s\" Error: PropField_Unsupported.", entity, sClass, sProp);
				}
				else
				{
					if( client )
						PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 \"%s\" \"%s\" Unknown Error.", entity, sClass, sProp);
					else
						ReplyToCommand(client, "%d) Prop_Send \"%s\" \"%s\" Unknown Error.", entity, sClass, sProp);
				}
			}
		}


		// PROP DATA
		offset = FindDataMapInfo(entity, sProp, proptype);
		if( offset != -1 )
		{
			if( member && GetEntPropArraySize(entity, Prop_Data, sProp) <= member )
			{
				ReplyToCommand(client, "Member size %00d is too large for this entity Prop_Data. Maximum %d member elements (starting from index 0).", member, GetEntPropArraySize(entity, Prop_Data, sProp));
				member = 0;
			}

			if( g_hEntityKeys.ContainsKey(sProp) )
			{
				proptype = PropField_Entity;
			}

			if( proptype == PropField_Integer )
			{
				int value = StringToInt(sValue);
				SetEntProp(entity, Prop_Data, sProp, value, _, member);

				if( client )
					PrintToChat(client, "\x05%d\x01) Set \x05Prop_Data\x01 integer \"%s\" \"%s%s\" to \x05%d", entity, sClass, sProp, sMember, value);
				else
					ReplyToCommand(client, "%d) Set Prop_Data integer \"%s\" \"%s%s\" to %d", entity, sClass, sProp, sMember, value);
			}
			else if( proptype == PropField_Entity )
			{
				int value = StringToInt(sValue);
				SetEntPropEnt(entity, Prop_Data, sProp, value, member);

				if( client )
					PrintToChat(client, "\x05%d\x01) Set \x05Prop_Data\x01 entity \"%s\" \"%s%s\" to \x05%d", entity, sClass, sProp, sMember, value);
				else
					ReplyToCommand(client, "%d) Set Prop_Data entity \"%s\" \"%s%s\" to %d", entity, sClass, sProp, sMember, value);
			}
			else if( proptype == PropField_Float )
			{
				float value = StringToFloat(sValue);
				SetEntPropFloat(entity, Prop_Data, sProp, value, member);

				if( client )
					PrintToChat(client, "\x05%d\x01) Set \x05Prop_Data\x01 float \"%s\" \"%s%s\" to \x05%f", entity, sClass, sProp, sMember, value);
				else
					ReplyToCommand(client, "%d) Set Prop_Data float \"%s\" \"%s%s\" to %f", entity, sClass, sProp, sMember, value);
			}
			else if( proptype == PropField_String || proptype == PropField_String_T )
			{
				SetEntPropString(entity, Prop_Data, sProp, sValue, member);

				if( client )
					PrintToChat(client, "\x05%d\x01) Set \x05Prop_Data\x01 string \"%s\" \"%s%s\" to \x05%s", entity, sClass, sProp, sMember, sValue);
				else
					ReplyToCommand(client, "%d) Set Prop_Data string \"%s\" \"%s%s\" to %s", entity, sClass, sProp, sMember, sValue);
			}
			else if( proptype == PropField_Vector )
			{
				ExplodeString(sValue, " ", sTemp, sizeof(sTemp), sizeof(sTemp[]));
				vVec[0] = StringToFloat(sTemp[0]);
				vVec[1] = StringToFloat(sTemp[1]);
				vVec[2] = StringToFloat(sTemp[2]);

				SetEntPropVector(entity, Prop_Data, sProp, vVec, member);

				if( client )
					PrintToChat(client, "\x05%d\x01) Set \x05Prop_Data\x01 vector \"%s\" \"%s%s\" to \x05%f %f %f", entity, sClass, sProp, sMember, vVec[0], vVec[1], vVec[2]);
				else
					ReplyToCommand(client, "%d) Set Prop_Data vector \"%s\" \"%s%s\" to %f %f %f", entity, sClass, sProp, sMember, vVec[0], vVec[1], vVec[2]);
			}
			else
			{
				if( proptype == PropField_Unsupported )
				{
					if( client )
						PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 \"%s\" \"%s\" Error: PropField_Unsupported.", entity, sClass, sProp);
					else
						ReplyToCommand(client, "%d) Prop_Data \"%s\" \"%s\" Error: PropField_Unsupported.", entity, sClass, sProp);
				}
				else
				{
					if( client )
						PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 \"%s\" \"%s\" Unknown Error.", entity, sClass, sProp);
					else
						ReplyToCommand(client, "%d) Prop_Data \"%s\" \"%s\" Unknown Error.", entity, sClass, sProp);
				}
			}
		}
	}
}



// ====================================================================================================
//					COMMANDS - sm_input, sm_inputent
// ====================================================================================================
Action CmdInput(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args == 0 )
	{
		ReplyToCommand(client, "[Input] Usage: sm_input <input> [params] [activator] [caller]");
		return Plugin_Handled;
	}

	int entity = GetClientAimTarget(client, false);
	if( entity != -1 )
	{
		char sCommand[64];
		char sArg[64];
		GetCmdArg(1, sCommand, sizeof(sCommand));

		if( args >= 2 )
		{
			GetCmdArg(2, sArg, sizeof(sArg));
			SetVariantString(sArg);
		}

		int a = -1, c = -1;
		if( args >= 3 )
		{
			GetCmdArg(3, sArg, sizeof(sArg));
			a = StringToInt(sArg);
		}

		if( args >= 4 )
		{
			GetCmdArg(4, sArg, sizeof(sArg));
			c = StringToInt(sArg);
		}

		if( AcceptEntityInput(entity, sCommand, a, c) )
			ReplyToCommand(client, "[Input] Success!");
		else
			ReplyToCommand(client, "[Input] Failed!");
	}

	return Plugin_Handled;
}

Action CmdInputEnt(int client, int args)
{
	if( args < 2 )
	{
		ReplyToCommand(client, "[InputEnt] Usage: sm_inputent <entity index|target name> <input> [params] [activator] [caller]");
		return Plugin_Handled;
	}

	char sCommand[64];
	GetCmdArg(1, sCommand, sizeof(sCommand));

	int entity;
	if( StringToIntEx(sCommand, entity) == 0 )
	{
		entity = FindByTargetName(sCommand);
		if( entity == -1 )
		{
			ReplyToCommand(client, "[InputEnt] Cannot find the specified targetname.");
			return Plugin_Handled;
		}
	}

	if( IsValidEntity(entity) )
	{
		GetCmdArg(2, sCommand, sizeof(sCommand));
		char sArg[64];

		if( args >= 3 )
		{
			GetCmdArg(3, sArg, sizeof(sArg));
			SetVariantString(sArg);
		}

		int a = -1, c = -1;
		if( args >= 4 )
		{
			GetCmdArg(4, sArg, sizeof(sArg));
			a = StringToInt(sArg);
		}

		if( args >= 5 )
		{
			GetCmdArg(5, sArg, sizeof(sArg));
			c = StringToInt(sArg);
		}

		if( AcceptEntityInput(entity, sCommand, a, c) )
			ReplyToCommand(client, "[InputEnt] Success!");
		else
			ReplyToCommand(client, "[InputEnt] Failed!");
	}

	return Plugin_Handled;
}

int FindByTargetName(const char[] sTarget)
{
	char sName[64];
	for( int i = MaxClients + 1; i < 4096; i++ )
	{
		if( IsValidEntity(i) )
		{
			GetEntPropString(i, Prop_Data, "m_iName", sName, sizeof(sName));
			if( strcmp(sTarget, sName) == 0 ) return i;
		}
	}
	return -1;
}

Action CmdInputMe(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args == 0 )
	{
		ReplyToCommand(client, "[InputMe] Usage: sm_inputme <input> [params] [activator] [caller]");
		return Plugin_Handled;
	}

	char sCommand[64];
	char sArg[64];
	GetCmdArg(1, sCommand, sizeof(sCommand));

	if( args >= 2 )
	{
		GetCmdArg(2, sArg, sizeof(sArg));
		SetVariantString(sArg);
	}

	int a = -1, c = -1;
	if( args >= 3 )
	{
		GetCmdArg(3, sArg, sizeof(sArg));
		a = StringToInt(sArg);
	}

	if( args >= 4 )
	{
		GetCmdArg(4, sArg, sizeof(sArg));
		c = StringToInt(sArg);
	}

	if( AcceptEntityInput(client, sCommand, a, c) )
		ReplyToCommand(client, "[InputMe] Success!");
	else
		ReplyToCommand(client, "[InputMe] Failed!");

	return Plugin_Handled;
}



// ====================================================================================================
//					COMMANDS - sm_output, sm_outputent
// ====================================================================================================
Action CmdOutput(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args != 1 )
	{
		ReplyToCommand(client, "[Output] Usage: sm_output <input>");
		return Plugin_Handled;
	}

	int entity = GetClientAimTarget(client, false);
	if( entity != -1 )
	{
		char sTemp[64];
		GetCmdArg(1, sTemp, sizeof(sTemp));

		HookSingleEntityOutput(entity, sTemp, OutputCallback);
		ReplyToCommand(client, "[Output] Successfully hooked '%s'!", sTemp);

		for( int i = 0; i < MAX_OUTPUTS; i++ )
		{
			if( IsValidEntRef(g_iOutputs[i][0]) == false )
			{
				g_iOutputs[i][0] = EntIndexToEntRef(entity);
				g_iOutputs[i][1] = client;
				strcopy(g_sOutputs[i], sizeof(g_sOutputs[]), sTemp);
				break;
			}
		}
	}

	return Plugin_Handled;
}

Action CmdOutputEnt(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args != 2 )
	{
		ReplyToCommand(client, "[OutputEnt] Usage: sm_output <entity index> <input>");
		return Plugin_Handled;
	}

	char sTemp[64];
	GetCmdArg(1, sTemp, sizeof(sTemp));
	int entity = StringToInt(sTemp);

	if( IsValidEntity(entity) )
	{
		GetCmdArg(2, sTemp, sizeof(sTemp));

		HookSingleEntityOutput(entity, sTemp, OutputCallback);
		ReplyToCommand(client, "[OutputEnt] Successfully hooked '%s'!", sTemp);

		for( int i = 0; i < MAX_OUTPUTS; i++ )
		{
			if( IsValidEntRef(g_iOutputs[i][0]) == false )
			{
				g_iOutputs[i][0] = EntIndexToEntRef(entity);
				g_iOutputs[i][1] = client;
				strcopy(g_sOutputs[i], sizeof(g_sOutputs[]), sTemp);
				break;
			}
		}
	}

	return Plugin_Handled;
}

Action CmdOutputMe(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args != 1 )
	{
		ReplyToCommand(client, "[OutputMe] Usage: sm_outputme <input>");
		return Plugin_Handled;
	}

	char sTemp[64];
	GetCmdArg(1, sTemp, sizeof(sTemp));

	HookSingleEntityOutput(client, sTemp, OutputCallback);
	ReplyToCommand(client, "[OutputMe] Successfully hooked '%s'!", sTemp);

	for( int i = 0; i < MAX_OUTPUTS; i++ )
	{
		if( IsValidEntRef(g_iOutputs[i][0]) == false )
		{
			g_iOutputs[i][0] = client;
			g_iOutputs[i][1] = client;
			strcopy(g_sOutputs[i], sizeof(g_sOutputs[]), sTemp);
			break;
		}
	}
	return Plugin_Handled;
}

void OutputCallback(const char[] output, int caller, int activator, float delay)
{
	PrintToChatAll("\x01[Output] \x05%s \x01Caller= \x05%d \x01Activator= \x05%d", output, caller, activator);
}

Action CmdOutputStop(int client, int args)
{
	for( int i = 0; i < MAX_OUTPUTS; i++ )
	{
		if( (g_iOutputs[i][0] && g_iOutputs[i][0] <= MaxClients) || IsValidEntRef(g_iOutputs[i][0]) == true )
		{
			UnhookSingleEntityOutput(g_iOutputs[i][0], g_sOutputs[i], OutputCallback);
			g_iOutputs[i][0] = 0;
			g_iOutputs[i][1] = 0;
			g_sOutputs[i][0] = 0;
		}
	}
	return Plugin_Handled;
}

Action CmdEmit(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args == 0 )
	{
		ReplyToCommand(client, "Usage: sm_emit <sound path and filename>.");
		return Plugin_Handled;
	}

	char sBuff[PLATFORM_MAX_PATH];
	GetCmdArg(1, sBuff, sizeof(sBuff));

	EmitSoundToAll(sBuff, client);
	return Plugin_Handled;
}

Action CmdListen(int client, int args)
{
	static bool bListen;

	if( bListen )
	{
		RemoveAmbientSoundHook(SoundHookA);
		RemoveNormalSoundHook(SoundHookN);
	}
	else
	{
		AddAmbientSoundHook(SoundHookA);
		AddNormalSoundHook(SoundHookN);
	}

	bListen = !bListen;

	return Plugin_Handled;
}

Action SoundHookA(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
	PrintToChatAll("\x05A_Sample: \x01%s", sample);
	PrintToChatAll("\x01A_Sent: \x01%d \x05vol: \x01%.2f \x05lvl: \x01%d \x05pch: \x01%d \x05flg: \x01%d", entity, volume, level, pitch, flags);

	return Plugin_Continue;
}

Action SoundHookN(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	static char strchannel[19];
	if( channel == -1 ) strchannel = "REPLACE";
	if( channel == 0 ) strchannel = "AUTO";
	if( channel == 1 ) strchannel = "WEAPON";
	if( channel == 2 ) strchannel = "VOICE";
	if( channel == 3 ) strchannel = "ITEM";
	if( channel == 4 ) strchannel = "BODY";
	if( channel == 5 ) strchannel = "STREAM";
	if( channel == 6 ) strchannel = "STATIC";
	if( channel == 7 ) strchannel = "VOICE_BASE";
	if( channel == 135 ) strchannel = "USER_BASE";

	PrintToChatAll("\x05N_Sample: \x01%s", sample);
	PrintToChatAll("\x01N_Sent: \x01%d \x05num: \x01%d \x05cnl: \x01%d %s \x05vol: \x01%.2f \x05lvl: \x01%d \x05pch: \x01%d \x05flg: \x01%d", entity, numClients, channel, strchannel, volume, level, pitch, flags);

	return Plugin_Continue;
}

Action CmdWatchEnts(int client, int args)
{
	g_bWatchEnts = !g_bWatchEnts;
	ReplyToCommand(client, "Watch Entities: %s", g_bWatchEnts ? "On" : "Off");
	return Plugin_Handled;
}

Action CmdBot(int client, int args)
{
	int bot = CreateFakeClient("Bot");
	if( bot && IsClientInGame(bot) )
	{
		if( client )
		{
			float origin[3];
			GetClientAbsOrigin(client, origin);
			TeleportEntity(bot, origin, NULL_VECTOR, NULL_VECTOR);
			ChangeClientTeam(bot, 2);
		}
		ReplyToCommand(client, "Created Bot index: %d", bot);
	} else {
		ReplyToCommand(client, "Failed to create bot");
	}

	return Plugin_Handled;
}




// ====================================================================================================
//					COMMANDS - CREATE - sm_part, sm_parti
// ====================================================================================================
Action CmdPart(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sBuff[64];
	GetCmdArg(1, sBuff, sizeof(sBuff));

	char sAttachment[12];
	int entity;
	FormatEx(sAttachment, sizeof(sAttachment), "forward");
	entity = DisplayParticle(sBuff, view_as<float>({ 0.0, 0.0, 0.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment);

	SetVariantString("OnUser1 !self:Kill::5.0:1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");

	return Plugin_Handled;
}

Action CmdPart2(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sBuff[64];
	float vPos[3];
	GetCmdArg(1, sBuff, sizeof(sBuff));

	SetTeleportEndPoint(client, vPos);
	int entity = DisplayParticle(sBuff, vPos, NULL_VECTOR);

	SetVariantString("OnUser1 !self:Kill::5.0:1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");

	return Plugin_Handled;
}



// ====================================================================================================
//					COMMANDS - L4D2 - sm_lobby, sm_ledge, sm_spit, sm_alloff, sm_director, sm_hold, sm_halt, sm_c, sm_r, sm_s, sm_v
// ====================================================================================================
Action CmdLobby(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	FakeClientCommand(client, "callvote ReturnToLobby");
	return Plugin_Handled;
}

Action CmdLedge(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args == 0 )
	{
		g_iLedge[client] = !g_iLedge[client];

		if( g_iLedge[client] )
			AcceptEntityInput(client, "DisableLedgeHang");
		else
			AcceptEntityInput(client, "EnableLedgeHang");

		PrintToChat(client, "[LedgeGrab] %s", g_iLedge[client] ? "Disabled" : "Enabled");
	}
	else
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;

		if( (target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		int target;
		for( int i = 0; i < target_count; i++ )
		{
			target = target_list[i];

			g_iLedge[target] = !g_iLedge[target];

			if( g_iLedge[target] )
				AcceptEntityInput(target, "DisableLedgeHang");
			else
				AcceptEntityInput(target, "EnableLedgeHang");

			PrintToChat(client, "[LedgeGrab] %s for %N", g_iLedge[target] ? "Disabled" : "Enabled", target);
		}
	}

	return Plugin_Handled;
}

Action CmdSpit(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args == 0 )
	{
		int entity = g_iEntsSpit[client];
		if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		{
			RemoveEntity(entity);
		}
		else
		{
			char sAttachment[12];
			FormatEx(sAttachment, sizeof(sAttachment), "forward");
			g_iEntsSpit[client] = DisplayParticle("spitter_slime_trail", view_as<float>({ 0.0, 0.0, 0.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment);
			g_iEntsSpit[client] = EntIndexToEntRef(g_iEntsSpit[client]);
		}
	}
	else
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;

		if( (target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		char sAttachment[12];
		int entity; int target;
		for( int i = 0; i < target_count; i++ )
		{
			target = target_list[i];

			entity = g_iEntsSpit[target];
			if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
			{
				RemoveEntity(entity);
			}
			else
			{
				FormatEx(sAttachment, sizeof(sAttachment), "forward");
				g_iEntsSpit[target] = DisplayParticle("spitter_slime_trail", view_as<float>({ 0.0, 0.0, 0.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), target, sAttachment);
				g_iEntsSpit[target] = EntIndexToEntRef(g_iEntsSpit[target]);

				PrintToChat(client, "[Spit] %s for %N", g_iLedge[target] ? "Removed" : "Added", target);
			}
		}
	}

	return Plugin_Handled;
}

Action CmdTemp(int client, int args)
{
	if( args != 2 )
	{
		ReplyToCommand(client, "Usage: sm_temp <#userid|name> <amount>");
		return Plugin_Handled;
	}

	char sTemp[32];
	GetCmdArg(1, sTemp, sizeof(sTemp));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if( (target_count = ProcessTargetString(
		sTemp,
		client,
		target_list,
		MAXPLAYERS,
		0,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, sTemp, sizeof(sTemp));
	float health = StringToFloat(sTemp);

	int target;
	for( int i = 0; i < target_count; i++ )
	{
		target = target_list[i];

		SetEntPropFloat(target, Prop_Send, "m_healthBuffer", health);
		SetEntPropFloat(target, Prop_Send, "m_healthBufferTime", GetGameTime());
	}

	return Plugin_Handled;
}

Action CmdAll(int client, int args)
{
	if( g_bAll )
	{
		g_bAll = false;
		g_bDirector = true;

		ExecuteCheatCommand("director_start");
		ExecuteCheatCommand("sb_hold_position", "0");
		z_background_limit.RestoreDefault();
		z_common_limit.RestoreDefault();
		z_minion_limit.RestoreDefault();

		if( g_iGAMETYPE == GAME_L4D2 )
		{
			z_boomer_limit.RestoreDefault();
			z_charger_limit.RestoreDefault();
			z_hunter_limit.RestoreDefault();
			z_jockey_limit.RestoreDefault();
			z_smoker_limit.RestoreDefault();
			z_spitter_limit.RestoreDefault();
		}
		if( client ) PrintToChat(client, "\x04[All]\x01 Enabled!");
		else ReplyToCommand(client, "[All] Enabled!");
	}
	else
	{
		g_bAll = true;
		g_bDirector = false;

		ExecuteCheatCommand("director_stop");
		ExecuteCheatCommand("sb_hold_position", "1");
		z_background_limit.IntValue = 0;
		z_common_limit.IntValue = 0;
		z_minion_limit.IntValue = 0;
		if( g_iGAMETYPE == GAME_L4D2 )
		{
			z_boomer_limit.IntValue = 0;
			z_charger_limit.IntValue = 0;
			z_hunter_limit.IntValue = 0;
			z_jockey_limit.IntValue = 0;
			z_smoker_limit.IntValue = 0;
			z_spitter_limit.IntValue = 0;
		}
		if( client ) PrintToChat(client, "\x04[All]\x01 Disabled!");
		else ReplyToCommand(client, "[All] Disabled!");
	}

	return Plugin_Handled;
}

Action CmdDirector(int client, int args)
{
	if( g_bDirector )
	{
		ExecuteCheatCommand("director_stop");
		if( client ) PrintToChat(client, "\x04[AI Director]\x01 disabled!");
		else ReplyToCommand(client, "[AI Director] disabled!");
	}
	else
	{
		ExecuteCheatCommand("director_start");
		if( client ) PrintToChat(client, "\x04[AI Director]\x01 enabled!");
		else ReplyToCommand(client, "[AI Director] enabled!");
	}
	g_bDirector = !g_bDirector;
	return Plugin_Handled;
}

Action CmdHold(int client, int args)
{
	if( sb_hold_position.IntValue == 1 )
	{
		ExecuteCheatCommand("sb_hold_position", "0");
		if( client ) PrintToChat(client, "\x04[sb_hold_position]\x01 0");
		else ReplyToCommand(client, "[sb_hold_position] 0");
	}
	else
	{
		ExecuteCheatCommand("sb_hold_position", "1");
		if( client ) PrintToChat(client, "\x04[sb_hold_position]\x01 1");
		else ReplyToCommand(client, "[sb_hold_position] 1");
	}
	return Plugin_Handled;
}

Action CmdHalt(int client, int args)
{
	if( sb_stop.IntValue == 1 )
	{
		ExecuteCheatCommand("sb_stop", "0");
		if( client ) PrintToChat(client, "\x04[sb_stop]\x01 0");
		else ReplyToCommand(client, "[sb_stop] 0");
	}
	else
	{
		ExecuteCheatCommand("sb_stop", "1");
		if( client ) PrintToChat(client, "\x04[sb_stop]\x01 1");
		else ReplyToCommand(client, "[sb_stop] 1");
	}
	return Plugin_Handled;
}

Action CmdNB(int client, int args)
{
	if( g_bNB )
	{
		ExecuteCheatCommand("nb_stop", "0");
		if( client ) PrintToChat(client, "\x04[nb_stop]\x01 0");
		else ReplyToCommand(client, "[nb_stop] 0");
	}
	else
	{
		ExecuteCheatCommand("nb_stop", "1");
		if( client ) PrintToChat(client, "\x04[nb_stop]\x01 1");
		else ReplyToCommand(client, "[nb_stop] 1");
	}
	g_bNB = !g_bNB;
	return Plugin_Handled;
}

Action CmdNoSpawn(int client, int args)
{
	if( g_bNospawn )
	{
		if( client ) PrintToChat(client, "\x04[nospawn]\x01 disabled!");
		else ReplyToCommand(client, "[nospawn] disabled!");
		DisableSpawn(false);
		sv_cheats.RemoveChangeHook(ConVarChanged_Cheats);
	}
	else
	{
		DisableSpawn(true);
		sv_cheats.AddChangeHook(ConVarChanged_Cheats);
		if( client ) PrintToChat(client, "\x04[nospawn]\x01 enabled!");
		else ReplyToCommand(client, "[nospawn] enabled!");
	}
	g_bNospawn = !g_bNospawn;
	return Plugin_Handled;
}

void DisableSpawn(bool bDisable)
{
	if( bDisable )
	{
		director_no_bosses.SetInt(1);
		director_no_specials.SetInt(1);
		director_no_mobs.SetInt(1);
	}
	else
	{
		director_no_bosses.SetInt(0);
		director_no_specials.SetInt(0);
		director_no_mobs.SetInt(0);
	}
}

void ConVarChanged_Cheats(ConVar convar, const char[] oldValue, const char[] newValue)
{
	 // 1 -> 0
	if( strcmp(oldValue, "1") == 0 && strcmp(newValue, "0") == 0 )
	{
		if( g_bNospawn )
		{
			//RequestFrame(OnNextFrameFixCvars); // not enough
			CreateTimer(0.1, Timer_FixCvars);
		}
	}
}

Action Timer_FixCvars(Handle timer)
{
	if( g_bNospawn )
	{
		DisableSpawn(true);
	}

	return Plugin_Continue;
}

Action CmdZSpawnV(int client, int args)
{
	if( args < 4 || args > 9 )
	{
		ReplyToCommand(client, "[SM] Usage: sm_zspawnv <boomer|hunter|smoker|spitter|jockey|charger|tank|witch|infected> <pos X> <pos Y> <pos Z> ( [modelname] [skin] || [ang X] [ang Y] [ang Z] [modelname] [skin])");
		return Plugin_Handled;
	}

	// Type
	char type[10];
	GetCmdArg(1, type, sizeof(type));

	if( strcmp(type, "boomer") && strcmp(type, "hunter") && strcmp(type, "smoker") && strcmp(type, "spitter") && strcmp(type, "jockey") && strcmp(type, "charger") && strcmp(type, "tank") && strcmp(type, "witch") && strcmp(type, "infected") )
	{
		ReplyToCommand(client, "[SM] Usage: sm_zspawnv <boomer|hunter|smoker|spitter|jockey|charger|tank|witch|infected> <pos X> <pos Y> <pos Z>  ( [modelname] [skin] || [ang X] [ang Y] [ang Z] [modelname] [skin])");
		return Plugin_Handled;
	}

	// Spawn
	int bits = GetUserFlagBits(client);
	int flags = GetCommandFlags("z_spawn");
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);

	g_iSpawned = 0;
	g_bWatchSpawn = true;
	FakeClientCommand(client, "z_spawn %s", type);
	g_bWatchSpawn = false;

	if( g_iSpawned == 0 )
	{
		ReplyToCommand(client, "[SM] Failed to spawn %s", type);
		return Plugin_Handled;
	} else {
		ReplyToCommand(client, "[SM] Spawned %d %s", g_iSpawned, type);
	}

	SetUserFlagBits(client, bits);
	SetCommandFlags("z_spawn", flags);

	// Pos
	char temp[16];
	float vPos[3], vAng[3];

	GetCmdArg(2, temp, sizeof(temp));
	vPos[0] = StringToFloat(temp);
	GetCmdArg(3, temp, sizeof(temp));
	vPos[1] = StringToFloat(temp);
	GetCmdArg(4, temp, sizeof(temp));
	vPos[2] = StringToFloat(temp);

	// Ang
	if( args >= 7 )
	{
		GetCmdArg(5, temp, sizeof(temp));
		vAng[0] = StringToFloat(temp);
		GetCmdArg(6, temp, sizeof(temp));
		vAng[1] = StringToFloat(temp);
		GetCmdArg(7, temp, sizeof(temp));
		vAng[2] = StringToFloat(temp);

		TeleportEntity(g_iSpawned, vPos, vAng, NULL_VECTOR);
	} else {
		TeleportEntity(g_iSpawned, vPos, NULL_VECTOR, NULL_VECTOR);
	}

	if( args == 5 || args == 8 )
	{
		char modelname[256];
		GetCmdArg(args == 5 ? 5 : 8, modelname, sizeof(modelname));

		if( FileExists(modelname, true) )
		{
			if( !IsModelPrecached(modelname) )
			{
				PrecacheModel(modelname);
			}

			SetEntityModel(g_iSpawned, modelname);
		}

	}
	else if( args == 6 || args == 9 )
	{
		char modelname[256];
		GetCmdArg(args == 6 ? 5 : 8, modelname, sizeof(modelname));

		if( FileExists(modelname, true) )
		{
			if( !IsModelPrecached(modelname) )
			{
				PrecacheModel(modelname);
			}

			SetEntityModel(g_iSpawned, modelname);
		}

		GetCmdArg(args == 6 ? 6 : 9, modelname, sizeof(modelname));
		SetEntProp(g_iSpawned, Prop_Send, "m_nSkin", StringToInt(modelname));
	}

	return Plugin_Handled;
}

Action CmdBotsL4D(int client, int args)
{
	int bot = CreateFakeClient("DevBot");
	DispatchKeyValue(bot, "classname", "SurvivorBot");
	DispatchSpawn(bot);
	ChangeClientTeam(bot, 2);
	KickClient(bot);

	return Plugin_Handled;
}

Action CmdSlayAll(int client, int args)
{
	CmdSlayCommon(client, 0);
	CmdSlayWitches(client, 0);
	SlaySpecial(client);
	return Plugin_Handled;
}

// Code thanks to: "Don't Fear The Reaper"
Action CmdSlayCommon(int client, int args)
{
	int count, i_EdictIndex = -1;
	while( (i_EdictIndex = FindEntityByClassname(i_EdictIndex, "infected")) != INVALID_ENT_REFERENCE )
	{
		RemoveEntity(i_EdictIndex);
		count++;
	}

	ReplyToCommand(client, "[SM] Slayed %d common infected.", count);
	return Plugin_Handled;
}

// Code thanks to: "Don't Fear The Reaper"
Action CmdSlayWitches(int client, int args)
{
	int count, i_EdictIndex = -1;
	while( (i_EdictIndex = FindEntityByClassname(i_EdictIndex, "witch")) != INVALID_ENT_REFERENCE )
	{
		RemoveEntity(i_EdictIndex);
		count++;
	}

	if( count == 1 )
		ReplyToCommand(client, "[SM] Slayed 1 witch.");
	else
		ReplyToCommand(client, "[SM] Slayed %d witches", count);
	return Plugin_Handled;
}

void SlaySpecial(int client)
{
	int count;
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3 )
		{
			RemoveEntity(i);
			count++;
		}
	}

	ReplyToCommand(client, "[SM] Slayed %d special infected.", count);
}

Action CmdStopAngle(int client, int args)
{
	float ang[3];
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 )
		{
			GetClientAbsAngles(client, ang);
			DataPack dp = new DataPack();
			dp.WriteFloat(ang[0]);
			dp.WriteFloat(ang[1]);
			dp.WriteFloat(ang[2]);
			dp.WriteCell(GetClientUserId(i));
			CreateTimer(0.1, Time_StopAngle, dp, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_HNDL_CLOSE);
		}
	}
	return Plugin_Handled;
}

Action Time_StopAngle(Handle timer, DataPack dp)
{
	dp.Reset();
	float ang[3];
	ang[0] = dp.ReadFloat();
	ang[1] = dp.ReadFloat();
	ang[2] = dp.ReadFloat();
	int client = GetClientOfUserId(dp.ReadCell());

	if( client && IsClientInGame(client) )
	{
		TeleportEntity(client, NULL_VECTOR, ang, NULL_VECTOR);
	}

	return Plugin_Continue;
}

Action CmdCoop(int client, int args)
{
	mp_gamemode.SetString("coop");

	if( client ) PrintToChat(client, "\x04[GameMode]\x01 Gamemode set to coop!");
	else ReplyToCommand(client, "[GameMode] Gamemode set to coop!");
	return Plugin_Handled;
}

Action CmdRealism(int client, int args)
{
	mp_gamemode.SetString("realism");

	if( client ) PrintToChat(client, "\x04[GameMode]\x01 Gamemode set to realism!");
	else ReplyToCommand(client, "[GameMode] Gamemode set to realism!");
	return Plugin_Handled;
}

Action CmdSurvival(int client, int args)
{
	mp_gamemode.SetString("survival");

	if( client ) PrintToChat(client, "\x04[GameMode]\x01 Gamemode set to survival!");
	else ReplyToCommand(client, "[GameMode] Gamemode set to survival!");
	return Plugin_Handled;
}

Action CmdVersus(int client, int args)
{
	if( g_iGAMETYPE == GAME_L4D2 )
		ExecuteCheatCommand("sb_all_bot_game", "1");
	else
		ExecuteCheatCommand("sb_all_bot_team", "1");
	mp_gamemode.SetString("versus");

	if( client ) PrintToChat(client, "\x04[GameMode]\x01 Gamemode set to versus!");
	else ReplyToCommand(client, "[GameMode] Gamemode set to versus!");
	return Plugin_Handled;
}

Action CmdScavenge(int client, int args)
{
	ExecuteCheatCommand("sb_all_bot_game", "1");
	mp_gamemode.SetString("scavenge");

	if( client ) PrintToChat(client, "\x04[GameMode]\x01 Gamemode set to scavenge!");
	else ReplyToCommand(client, "[GameMode] Gamemode set to scavenge!");
	return Plugin_Handled;
}



// ====================================================================================================
//					COMMANDS - L4D2 & CSS - sm_nv
// ====================================================================================================
Action CmdNV(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args == 0 )
	{
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", !GetEntProp(client, Prop_Send, "m_bNightVisionOn"));
	}
	else
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;

		if( (target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		int target, nv;
		for( int i = 0; i < target_count; i++ )
		{
			target = target_list[i];
			nv = !GetEntProp(target, Prop_Send, "m_bNightVisionOn");
			SetEntProp(target, Prop_Send, "m_bNightVisionOn", nv);
			ReplyToCommand(client, "Turned %s Nightvision for %N", nv ? "On" : "Off", target);
		}
	}
	return Plugin_Handled;
}



// ====================================================================================================
//					COMMANDS - CSS - sm_bots, sm_money
// ====================================================================================================
Action CmdBots(int client, int args)
{
	ShowBotMenu(client);
	return Plugin_Handled;
}

void ShowBotMenu(int client)
{
	if( IsClientInGame(client) )
	{
		Menu menu = new Menu(BotMenuHandler);
		menu.AddItem("1", "10 CT");
		menu.AddItem("2", "10 T");
		menu.AddItem("3", "Add CT");
		menu.AddItem("4", "Add T");
		menu.AddItem("5", "Kick CT");
		menu.AddItem("6", "Kick T");
		menu.AddItem("7", "Kick all");
		menu.SetTitle("Bots Control:");
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

int BotMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
		delete menu;
	else if( action == MenuAction_Select )
	{
		switch( index )
		{
			case 0:			ServerCommand("bot_kick; bot_join_team ct; bot_quota 10"); // bot_prefix CT;
			case 1:			ServerCommand("bot_kick; bot_join_team t; bot_quota 10"); // bot_prefix T;
			case 2:			ServerCommand("bot_add ct");
			case 3:			ServerCommand("bot_add t");
			case 4:			ServerCommand("bot_kick ct");
			case 5:			ServerCommand("bot_kick t");
			case 6:			ServerCommand("bot_kick");
		}

		ShowBotMenu(client);
	}
	else if( action == MenuAction_Cancel && index == MenuCancel_ExitBack )
		ShowBotMenu(client);

	return 0;
}

Action CmdMoney(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	ShowPlayerList(client);
	return Plugin_Handled;
}

void ShowPlayerList(int client)
{
	if( client && IsClientInGame(client) )
	{
		char sTempA[8], sTempB[MAX_NAME_LENGTH];
		Menu menu = new Menu(PlayerListMenur);

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsValidClient(i) )
			{
				IntToString(GetClientUserId(i), sTempA, sizeof(sTempA));
				GetClientName(i, sTempB, sizeof(sTempB));
				menu.AddItem(sTempA, sTempB);
			}
		}

		menu.SetTitle("Give money to:");
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

int PlayerListMenur(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
		delete menu;
	else if( action == MenuAction_Select )
	{
		char sTemp[32];
		menu.GetItem(index, sTemp, sizeof(sTemp));
		int target = StringToInt(sTemp);
		target = GetClientOfUserId(target);

		if( IsValidClient(target) )
		{
			SetEntProp(target, Prop_Send, "m_iAccount", 16000);
		}

		ShowPlayerList(client);
	}
	else if( action == MenuAction_Cancel && index == MenuCancel_ExitBack )
		ShowPlayerList(client);

	return 0;
}



// ====================================================================================================
//					STUFF
// ====================================================================================================
void ExecuteCheatCommand(const char[] command, const char[] value = "")
{
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT); // Remove cheat flag
	ServerCommand("%s %s", command, value);
	ServerExecute();
	SetCommandFlags(command, flags);
}

void SetEntitySolid(int entity, bool doSolid)
{
	int m_nSolidType	= GetEntProp(entity, Prop_Data, "m_nSolidType", 1);
	int m_usSolidFlags	= GetEntProp(entity, Prop_Data, "m_usSolidFlags", 2);

	if( doSolid )
	{
		if( m_nSolidType == 0 )
			SetEntProp(entity, Prop_Send, "m_nSolidType", view_as<int>(SOLID_VPHYSICS), 1);

		if( m_usSolidFlags & view_as<int>(FSOLID_NOT_SOLID) )
			SetEntProp(entity, Prop_Send, "m_usSolidFlags", m_usSolidFlags &~ view_as<int>(FSOLID_NOT_SOLID), 2);
	}
	else
	{
		if( m_nSolidType != 0 )
			SetEntProp(entity, Prop_Send, "m_nSolidType", view_as<int>(SOLID_NONE),	1);

		if( m_usSolidFlags & view_as<int>(FSOLID_NOT_SOLID) == 0 )
			SetEntProp(entity, Prop_Send, "m_usSolidFlags", m_usSolidFlags | view_as<int>(FSOLID_NOT_SOLID), 2);
	}
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

int DisplayParticle(char[] sParticle, float vPos[3], float fAng[3], int client = 0, const char[] sAttachment = "")
{
	int entity = CreateEntityByName("info_particle_system");

	if( entity != -1 && IsValidEdict(entity) )
	{
		DispatchKeyValue(entity, "effect_name", sParticle);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");

		if( client )
		{
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", client);

			if( strlen(sAttachment) != 0 )
			{
				SetVariantString(sAttachment);
				AcceptEntityInput(entity, "SetParentAttachment");
			}
		}

		TeleportEntity(entity, vPos, fAng, NULL_VECTOR);

		return entity;
	}

	return 0;
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

bool IsValidClient(int client)
{
	if( !client || !IsClientInGame(client) || !IsPlayerAlive(client) )
		return false;
	return true;
}

bool SetTeleportEndPoint(int client, float vPos[3])
{
	float vBuffer[3], vAng[3];
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	Handle hTrace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter);

	if( TR_DidHit(hTrace) )
	{
		TR_GetEndPosition(vPos, hTrace);
		GetAngleVectors(vAng, vBuffer, NULL_VECTOR, NULL_VECTOR);
		vPos[0] += vBuffer[0] * -10;
		vPos[1] += vBuffer[1] * -10;
		vPos[2] += vBuffer[2] * -10;
	}
	else
	{
		delete hTrace;
		return false;
	}
	delete hTrace;
	return true;
}

bool TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}

void LogModels(const char[] format, any ...)
{
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	char sFile[PLATFORM_MAX_PATH];
	GetCurrentMap(sMap, sizeof(sMap));
	BuildPath(Path_SM, sFile, sizeof(sFile), "logs/models_%s.txt", sMap);
	File file = OpenFile(sFile, "a+");
	file.WriteLine(buffer);
	FlushFile(file);
	delete file;
}

void LogCustom(const char[] format, any ...)
{
	static char sFile[PLATFORM_MAX_PATH], sTime[256], buffer[512];

	BuildPath(Path_SM, sFile, sizeof(sFile), "logs/sm_logit.txt");
	FormatTime(sTime, sizeof(sTime), "%d-%b-%Y %H:%M:%S");
	VFormat(buffer, sizeof(buffer), format, 2);

	File file = OpenFile(sFile, "a+");
	file.WriteLine("%s  %s", sTime, buffer);
	FlushFile(file);
	delete file;
}