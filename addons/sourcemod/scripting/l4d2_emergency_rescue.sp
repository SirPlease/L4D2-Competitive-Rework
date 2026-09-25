/**
 * l4d2_emergency_rescue
 *
 * Referee / admin accident-recovery tool for competitive Left 4 Dead 2.
 *
 * Why this exists
 * ---------------
 * A Survivor can lose a round to something that is not a normal Special Infected play:
 * getting wedged in map geometry, being pinned by a door or a lift, or eating a bugged
 * damage spike that instantly incaps or kills them. None of that can be undone through
 * in-game mechanics, and today the only answers are restarting the round or negotiating
 * something on the fly - which is exactly what causes disputes.
 *
 * What this plugin gives the referee
 * ----------------------------------
 *   1. Teleport a Survivor, with the destination safety-checked first
 *      - to the position the referee is aiming at
 *      - to a per-map preset coordinate
 *      - next to a chosen teammate
 *   2. Restore Survivor state
 *      - real health and temporary health
 *      - incap count, with the matching third-strike flag
 *      - roll a Survivor back to the state they had just before their last incap
 *
 * Design notes
 * ------------
 *   - The plugin never touches a Survivor unless a referee asks it to. Everything else it
 *     does is read-only event observation, so it is inert during normal play.
 *   - Every teleport and every state change is written to the normal SourceMod admin log
 *     (LogAction) and to addons/sourcemod/logs/l4d2_emergency_rescue.log, recording the
 *     acting admin, the target, the old value and the new value.
 *   - The safety check rejects a destination whose player hull does not fit (wall), that
 *     has no ground underneath (void), that is covered by living Special Infected, or that
 *     is not on the teammate's level when teleporting next to someone.
 *   - A Survivor who is currently pinned by a Special Infected is refused rather than moved.
 *     A pin is normal play rather than a bug accident, and teleporting out of one would both
 *     change the match and drag the pin along.
 *   - Nothing here writes a Survivor who is already down. Setting real health while a
 *     Survivor is incapacitated or hanging writes the game's pre-incap health, which is what
 *     they are rebuilt from on the rescue, and says so, rather than writing the bleed-out
 *     pool behind the referee's back.
 *   - Reviving a Survivor who is already dead is deliberately out of scope: that is the
 *     death and defibrillator path rather than an incap-count accident, and this repository
 *     already ships a plugin for it. Asking to restore a dead Survivor says so explicitly.
 *
 * Commands
 * --------
 * All commands are registered with ADMFLAG_BAN, the same flag the other referee-facing
 * commands in this repository use (pause, team swap, caster management). Per-command flags
 * can be changed in addons/sourcemod/configs/admin_overrides.cfg, for example:
 *
 *   "sm_rescue"        "b"      // ADMFLAG_GENERIC
 *   "sm_rescue_here"   "b"
 *
 *   sm_rescue                                  open the rescue menu
 *   sm_rescue_here    <target>                 teleport to the referee's crosshair
 *   sm_rescue_to      <target> <teammate>      teleport next to a teammate
 *   sm_rescue_pos     <target> <preset>        teleport to a saved preset point
 *   sm_rescue_save    <preset>                 save the crosshair position as a preset
 *   sm_rescue_health  <target> <amount> [temp] set real (temp=0) or temporary health
 *   sm_rescue_incap   <target> <count>         set the incap count
 *   sm_rescue_restore <target>                 roll back to the pre-accident state
 *   sm_rescue_status  [target]                 print current and recorded state
 *
 * Targets accept the usual SourceMod patterns: part of a name, #userid, @survivors, ...
 *
 * Setting real health also clears the temporary health buffer, so "set health to 100"
 * always means 100 total. Use temp=1 to change the temporary buffer on its own.
 *
 * Preset coordinates
 * ------------------
 * Stored per map in addons/sourcemod/configs/l4d2_emergency_rescue.cfg:
 *
 *   "EmergencyRescue"
 *   {
 *       "c1m1_hotel"
 *       {
 *           "1"   "1234.500 567.000 64.000"
 *       }
 *   }
 *
 * Dependencies: SourceMod 1.11+, Left4DHooks (shipped with this repository).
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <left4dhooks>

// ---------------------------------------------------------------------------
// Plugin metadata
// ---------------------------------------------------------------------------

#define PLUGIN_NAME         "L4D2 Emergency Rescue"
#define PLUGIN_AUTHOR       "apples1949"
#define PLUGIN_DESCRIPTION  "Referee accident recovery: safe teleport, health and incap count restore"
#define PLUGIN_VERSION      "1.0.0"
#define PLUGIN_URL          "https://github.com/SirPlease/L4D2-Competitive-Rework/issues/1012"

// ---------------------------------------------------------------------------
// Files and ConVars
// ---------------------------------------------------------------------------

#define TRANSLATIONS_FILE   "l4d2_emergency_rescue"
#define PRESET_PATH         "configs/l4d2_emergency_rescue.cfg"
#define PRESET_ROOT         "EmergencyRescue"
#define LOG_PATH            "logs/l4d2_emergency_rescue.log"

#define CVAR_ENABLE         "l4d2_emergency_rescue_enable"
#define CVAR_SAFE_CHECK     "l4d2_emergency_rescue_safe_check"
#define CVAR_SI_RADIUS      "l4d2_emergency_rescue_si_radius"
#define CVAR_MAX_DROP       "l4d2_emergency_rescue_max_drop"
#define CVAR_SNAPSHOT       "l4d2_emergency_rescue_snapshot"
#define CVAR_ANNOUNCE       "l4d2_emergency_rescue_announce"

#define RESCUE_ADMFLAGS     ADMFLAG_BAN

// ---------------------------------------------------------------------------
// Tuning constants
// ---------------------------------------------------------------------------

#define TEAM_SURVIVOR                     2
#define TEAM_INFECTED                     3

#define RESCUE_MIN_HEALTH                 1
#define RESCUE_DEFAULT_MAX_HEALTH         100

// Standing Survivor hull, the same one the game uses for movement collision.
#define HULL_MINS_X                     -16.0
#define HULL_MINS_Y                     -16.0
#define HULL_MINS_Z                       0.0
#define HULL_MAXS_X                      16.0
#define HULL_MAXS_Y                      16.0
#define HULL_MAXS_Z                      72.0

// The hull trace for a candidate spot starts this far above it, so a spot sitting exactly
// on the floor does not begin the trace inside solid.
#define GROUND_HULL_LIFT                  8.0

// How the ring search places a Survivor next to their teammate.
#define TEAMMATE_RING_RADIUS_MIN         40.0
#define TEAMMATE_RING_RADIUS_STEP        30.0
#define TEAMMATE_RING_RADIUS_MAX        160.0
#define TEAMMATE_RING_ANGLES                8

// A candidate spot counts as taken when another living Survivor is closer than this.
#define SPOT_OCCUPIED_DISTANCE           48.0

// How far a spot next to a teammate may sit above or below them. Without this the ring
// search happily resolves a point over a ledge or a lift shaft onto the floor far below,
// which is the second accident this plugin exists to prevent.
#define TEAMMATE_MAX_HEIGHT_DELTA        48.0

#define PRESET_NAME_LEN                    64
#define PRESET_SLOTS                        8

#define RESCUE_MESSAGE_LEN                256
#define RESCUE_REASON_LEN                 128

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------

ConVar g_cvEnable;
ConVar g_cvSafeCheck;
ConVar g_cvSiRadius;
ConVar g_cvMaxDrop;
ConVar g_cvSnapshot;
ConVar g_cvAnnounce;

ConVar g_cvGameMaxIncap;

TopMenu g_hAdminMenu;

// Presets for the current map: name -> "x y z", plus the display order.
StringMap g_smPresets;
ArrayList g_aPresetOrder;
char g_sPresetMap[PLATFORM_MAX_PATH];

// Menu navigation state.
int g_iMenuTarget[MAXPLAYERS + 1];   // userid of the Survivor the admin is working on
int g_iMenuPage[MAXPLAYERS + 1];     // page to return to in the target list

// The last state a Survivor was observed in while standing up. Cheap, read-only event
// tracking that makes "restore the pre-accident value" mean the value from before the
// damaging hit instead of whatever the bugged hit left behind.
bool  g_bStandingValid[MAXPLAYERS + 1];
int   g_iStandingHealth[MAXPLAYERS + 1];
float g_fStandingTempHealth[MAXPLAYERS + 1];
int   g_iStandingReviveCount[MAXPLAYERS + 1];

// The state captured when a Survivor actually went down, which is what a referee rolls
// back to.
bool  g_bSnapshotValid[MAXPLAYERS + 1];
int   g_iSnapshotHealth[MAXPLAYERS + 1];
float g_fSnapshotTempHealth[MAXPLAYERS + 1];
int   g_iSnapshotReviveCount[MAXPLAYERS + 1];

bool g_bLateLoaded;

static const float g_fHullMins[3] = { HULL_MINS_X, HULL_MINS_Y, HULL_MINS_Z };
static const float g_fHullMaxs[3] = { HULL_MAXS_X, HULL_MAXS_Y, HULL_MAXS_Z };

// Why a destination was rejected.
enum RescueBlock
{
	RescueBlock_None = 0,
	RescueBlock_Wall,
	RescueBlock_Void,
	RescueBlock_Infected,
	RescueBlock_Level,
	RescueBlock_Occupied
}

// ===========================================================================
// Lifecycle
// ===========================================================================

public Plugin myinfo =
{
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version     = PLUGIN_VERSION,
	url         = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoaded = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations(TRANSLATIONS_FILE);

	g_smPresets = new StringMap();
	g_aPresetOrder = new ArrayList(ByteCountToCells(PRESET_NAME_LEN));

	CreateConVar("l4d2_emergency_rescue_version", PLUGIN_VERSION, "L4D2 Emergency Rescue plugin version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_cvEnable = CreateConVar(CVAR_ENABLE, "1",
		"1 = enable the Emergency Rescue commands, 0 = disable them (the plugin then does nothing at all).",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvSafeCheck = CreateConVar(CVAR_SAFE_CHECK, "1",
		"1 = verify a teleport destination before using it (hull fits, ground below, no Special Infected), 0 = teleport blindly.",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvSiRadius = CreateConVar(CVAR_SI_RADIUS, "250.0",
		"How close living Special Infected may be to a teleport destination before it is rejected. 0 = do not check for Infected.",
		FCVAR_NOTIFY, true, 0.0, true, 2000.0);
	g_cvMaxDrop = CreateConVar(CVAR_MAX_DROP, "200.0",
		"How far below a candidate spot the plugin looks for ground. A spot with no ground inside this distance counts as void.",
		FCVAR_NOTIFY, true, 16.0, true, 2048.0);
	g_cvSnapshot = CreateConVar(CVAR_SNAPSHOT, "1",
		"1 = record each Survivor's state before they go down, so sm_rescue_restore can roll the accident back, 0 = do not record.",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvAnnounce = CreateConVar(CVAR_ANNOUNCE, "1",
		"1 = tell both teams when a referee teleports a Survivor or restores their state, 0 = only tell the referee.",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d2_emergency_rescue");

	g_cvGameMaxIncap = FindConVar("survivor_max_incapacitated_count");

	RegAdminCmd("sm_rescue", Command_Rescue, RESCUE_ADMFLAGS, "Open the emergency rescue menu.");
	RegAdminCmd("sm_rescue_here", Command_RescueHere, RESCUE_ADMFLAGS, "sm_rescue_here <target> - Teleport a Survivor to the position you are aiming at.");
	RegAdminCmd("sm_rescue_to", Command_RescueTo, RESCUE_ADMFLAGS, "sm_rescue_to <target> <teammate> - Teleport a Survivor next to a teammate.");
	RegAdminCmd("sm_rescue_pos", Command_RescuePos, RESCUE_ADMFLAGS, "sm_rescue_pos <target> <preset> - Teleport a Survivor to a saved preset point.");
	RegAdminCmd("sm_rescue_save", Command_RescueSave, RESCUE_ADMFLAGS, "sm_rescue_save <preset> - Save the position you are aiming at as a preset for this map.");
	RegAdminCmd("sm_rescue_health", Command_RescueHealth, RESCUE_ADMFLAGS, "sm_rescue_health <target> <amount> [temp] - Set a Survivor's real (temp=0) or temporary health.");
	RegAdminCmd("sm_rescue_incap", Command_RescueIncap, RESCUE_ADMFLAGS, "sm_rescue_incap <target> <count> - Set a Survivor's incap count.");
	RegAdminCmd("sm_rescue_restore", Command_RescueRestore, RESCUE_ADMFLAGS, "sm_rescue_restore <target> - Roll a Survivor back to the state they had before their last incap.");
	RegAdminCmd("sm_rescue_status", Command_RescueStatus, RESCUE_ADMFLAGS, "sm_rescue_status [target] - Print a Survivor's current and recorded state.");

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("player_incapacitated_start", Event_PlayerIncapacitatedStart);
	HookEvent("round_start", Event_RoundStart);

	// Late load: the map is already running, so seed what the events would have recorded.
	if (g_bLateLoaded)
	{
		LoadPresets();

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
				RecordStandingState(i);
		}
	}

	TopMenu topmenu;
	if (LibraryExists("adminmenu") && (topmenu = GetAdminTopMenu()) != null)
		OnAdminMenuReady(topmenu);
}

public void OnMapStart()
{
	LoadPresets();

	for (int i = 1; i <= MaxClients; i++)
		ClearClientRecords(i);
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
		g_hAdminMenu = null;
}

public void OnClientDisconnect(int client)
{
	ClearClientRecords(client);
	g_iMenuTarget[client] = 0;
	g_iMenuPage[client] = 0;
}

// ===========================================================================
// Admin menu integration
// ===========================================================================

public void OnAdminMenuReady(Handle topmenu)
{
	TopMenu menu = TopMenu.FromHandle(topmenu);

	// The callback fires again if the admin menu plugin reloads.
	if (menu == g_hAdminMenu)
		return;

	g_hAdminMenu = menu;

	// Items must live inside a category, so there is nowhere to put this one when the
	// Server Commands category is missing. The sm_rescue command still works.
	TopMenuObject category = FindTopMenuCategory(menu, ADMINMENU_SERVERCOMMANDS);
	if (category == INVALID_TOPMENUOBJECT)
		return;

	AddToTopMenu(menu, "emergency_rescue", TopMenuObject_Item, AdminMenu_Handler,
		category, "sm_rescue", RESCUE_ADMFLAGS);
}

public void AdminMenu_Handler(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
			FormatEx(buffer, maxlength, "%T", "Rescue Menu Title", client);

		case TopMenuAction_SelectOption:
			ShowTargetMenu(client);
	}
}

// ===========================================================================
// Commands
// ===========================================================================

public Action Command_Rescue(int client, int args)
{
	if (!IsRescueEnabled(client))
		return Plugin_Handled;

	if (!IsValidClient(client))
	{
		RescueReply(client, "%t", "Rescue Menu Needs Player");
		return Plugin_Handled;
	}

	ShowTargetMenu(client);
	return Plugin_Handled;
}

public Action Command_RescueHere(int client, int args)
{
	if (!IsRescueEnabled(client))
		return Plugin_Handled;

	if (args < 1)
	{
		RescueReply(client, "%t", "Rescue Usage Here");
		return Plugin_Handled;
	}

	char pattern[MAX_TARGET_LENGTH];
	GetCmdArg(1, pattern, sizeof pattern);

	int target = ResolveTarget(client, pattern);
	if (target == -1)
		return Plugin_Handled;

	RescueTeleportToAim(client, target);
	return Plugin_Handled;
}

public Action Command_RescueTo(int client, int args)
{
	if (!IsRescueEnabled(client))
		return Plugin_Handled;

	if (args < 2)
	{
		RescueReply(client, "%t", "Rescue Usage To");
		return Plugin_Handled;
	}

	char pattern[MAX_TARGET_LENGTH];
	char matePattern[MAX_TARGET_LENGTH];
	GetCmdArg(1, pattern, sizeof pattern);
	GetCmdArg(2, matePattern, sizeof matePattern);

	int target = ResolveTarget(client, pattern);
	if (target == -1)
		return Plugin_Handled;

	int teammate = ResolveTarget(client, matePattern);
	if (teammate == -1)
		return Plugin_Handled;

	if (teammate == target)
	{
		RescueReply(client, "%t", "Rescue Teammate Is Target", target);
		return Plugin_Handled;
	}

	RescueTeleportNextToTeammate(client, target, teammate);
	return Plugin_Handled;
}

public Action Command_RescuePos(int client, int args)
{
	if (!IsRescueEnabled(client))
		return Plugin_Handled;

	if (args < 2)
	{
		RescueReply(client, "%t", "Rescue Usage Pos");
		return Plugin_Handled;
	}

	char pattern[MAX_TARGET_LENGTH];
	char preset[PRESET_NAME_LEN];
	GetCmdArg(1, pattern, sizeof pattern);
	GetCmdArg(2, preset, sizeof preset);

	int target = ResolveTarget(client, pattern);
	if (target == -1)
		return Plugin_Handled;

	RescueTeleportToPreset(client, target, preset);
	return Plugin_Handled;
}

public Action Command_RescueSave(int client, int args)
{
	if (!IsRescueEnabled(client))
		return Plugin_Handled;

	if (!IsValidClient(client))
	{
		RescueReply(client, "%t", "Rescue Aim Needs Player");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		RescueReply(client, "%t", "Rescue Usage Save");
		return Plugin_Handled;
	}

	char preset[PRESET_NAME_LEN];
	GetCmdArg(1, preset, sizeof preset);

	RescueSavePreset(client, preset);
	return Plugin_Handled;
}

public Action Command_RescueHealth(int client, int args)
{
	if (!IsRescueEnabled(client))
		return Plugin_Handled;

	if (args < 2)
	{
		RescueReply(client, "%t", "Rescue Usage Health");
		return Plugin_Handled;
	}

	char pattern[MAX_TARGET_LENGTH];
	char amountArg[16];
	char tempArg[16];
	GetCmdArg(1, pattern, sizeof pattern);
	GetCmdArg(2, amountArg, sizeof amountArg);
	GetCmdArg(3, tempArg, sizeof tempArg);

	int target = ResolveTarget(client, pattern);
	if (target == -1)
		return Plugin_Handled;

	RescueApplyHealth(client, target, StringToInt(amountArg), StringToInt(tempArg) != 0);
	return Plugin_Handled;
}

public Action Command_RescueIncap(int client, int args)
{
	if (!IsRescueEnabled(client))
		return Plugin_Handled;

	if (args < 2)
	{
		RescueReply(client, "%t", "Rescue Usage Incap");
		return Plugin_Handled;
	}

	char pattern[MAX_TARGET_LENGTH];
	char countArg[16];
	GetCmdArg(1, pattern, sizeof pattern);
	GetCmdArg(2, countArg, sizeof countArg);

	int target = ResolveTarget(client, pattern);
	if (target == -1)
		return Plugin_Handled;

	RescueApplyIncapCount(client, target, StringToInt(countArg));
	return Plugin_Handled;
}

public Action Command_RescueRestore(int client, int args)
{
	if (!IsRescueEnabled(client))
		return Plugin_Handled;

	if (!IsValidClient(client))
	{
		RescueReply(client, "%t", "Rescue Menu Needs Player");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		RescueReply(client, "%t", "Rescue Usage Restore");
		return Plugin_Handled;
	}

	char pattern[MAX_TARGET_LENGTH];
	GetCmdArg(1, pattern, sizeof pattern);

	// A dead Survivor has to resolve here so the reply can explain why they cannot be
	// restored, rather than being filtered out by the resolver.
	int target = ResolveTarget(client, pattern, false);
	if (target == -1)
		return Plugin_Handled;

	RescueRestoreSnapshot(client, target);
	return Plugin_Handled;
}

public Action Command_RescueStatus(int client, int args)
{
	if (!IsRescueEnabled(client))
		return Plugin_Handled;

	if (args < 1)
	{
		if (!IsValidClient(client))
		{
			RescueReply(client, "%t", "Rescue Usage Status");
			return Plugin_Handled;
		}

		ShowTargetMenu(client);
		return Plugin_Handled;
	}

	char pattern[MAX_TARGET_LENGTH];
	GetCmdArg(1, pattern, sizeof pattern);

	int target = ResolveTarget(client, pattern);
	if (target == -1)
		return Plugin_Handled;

	RescuePrintStatus(client, target);
	return Plugin_Handled;
}

// ===========================================================================
// Menus
//
// Menu display text is localised while the menu is built. The target is already known at
// that point, so there is no need for MenuAction_DisplayItem.
// ===========================================================================

void ShowTargetMenu(int admin, int page = 0)
{
	// Counted before the menu is created, so an empty menu is never built.
	int candidates = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidSurvivor(i) && IsPlayerAlive(i))
			candidates++;
	}

	if (candidates == 0)
	{
		RescueReply(admin, "%t", "Rescue No Survivor");
		return;
	}

	Menu menu = new Menu(TargetMenu_Handler);
	menu.SetTitle("%T", "Rescue Menu Title", admin);

	char info[16];
	char display[RESCUE_MESSAGE_LEN];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidSurvivor(i) || !IsPlayerAlive(i))
			continue;

		IntToString(GetClientUserId(i), info, sizeof info);
		FormatEx(display, sizeof display, "%T", "Rescue Target Item", admin,
			i, GetClientHealth(i), GetClientReviveCount(i));
		menu.AddItem(info, display);
	}

	menu.ExitButton = true;
	menu.DisplayAt(admin, page, MENU_TIME_FOREVER);
}

public int TargetMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int admin = param1;

			char info[16];
			menu.GetItem(param2, info, sizeof info);

			int target = GetClientOfUserId(StringToInt(info));
			if (!IsValidSurvivor(target) || !IsPlayerAlive(target))
			{
				RescueReply(admin, "%t", "Rescue Target Invalid");
				ShowTargetMenu(admin);
				return 0;
			}

			g_iMenuTarget[admin] = GetClientUserId(target);
			g_iMenuPage[admin] = menu.Selection;

			ShowActionMenu(admin);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void ShowActionMenu(int admin)
{
	int target = GetClientOfUserId(g_iMenuTarget[admin]);
	if (!IsValidSurvivor(target) || !IsPlayerAlive(target))
	{
		ShowTargetMenu(admin, g_iMenuPage[admin]);
		return;
	}

	char display[64];

	Menu menu = new Menu(ActionMenu_Handler);
	menu.SetTitle("%T", "Rescue Action Title", admin, target);

	FormatEx(display, sizeof display, "%T", "Rescue Action Aim", admin);
	menu.AddItem("aim", display);

	FormatEx(display, sizeof display, "%T", "Rescue Action Teammate", admin);
	menu.AddItem("mate", display);

	FormatEx(display, sizeof display, "%T", "Rescue Action Preset", admin);
	menu.AddItem("preset", display);

	FormatEx(display, sizeof display, "%T", "Rescue Action Health", admin);
	menu.AddItem("health", display);

	FormatEx(display, sizeof display, "%T", "Rescue Action Incap", admin);
	menu.AddItem("incap", display);

	FormatEx(display, sizeof display, "%T", "Rescue Action Restore", admin);
	menu.AddItem("restore", display);

	FormatEx(display, sizeof display, "%T", "Rescue Action Status", admin);
	menu.AddItem("status", display);

	FormatEx(display, sizeof display, "%T", "Rescue Action Save", admin);
	menu.AddItem("save", display);

	menu.ExitBackButton = true;
	menu.Display(admin, MENU_TIME_FOREVER);
}

public int ActionMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int admin = param1;

			char info[16];
			menu.GetItem(param2, info, sizeof info);

			int target = GetClientOfUserId(g_iMenuTarget[admin]);
			if (!IsValidSurvivor(target) || !IsPlayerAlive(target))
			{
				RescueReply(admin, "%t", "Rescue Target Invalid");
				ShowTargetMenu(admin, g_iMenuPage[admin]);
				return 0;
			}

			if (StrEqual(info, "aim"))
			{
				RescueTeleportToAim(admin, target);
				ShowActionMenu(admin);
			}
			else if (StrEqual(info, "mate"))
			{
				ShowTeammateMenu(admin);
			}
			else if (StrEqual(info, "preset"))
			{
				ShowPresetMenu(admin);
			}
			else if (StrEqual(info, "health"))
			{
				ShowHealthMenu(admin);
			}
			else if (StrEqual(info, "incap"))
			{
				ShowIncapMenu(admin);
			}
			else if (StrEqual(info, "restore"))
			{
				RescueRestoreSnapshot(admin, target);
				ShowActionMenu(admin);
			}
			else if (StrEqual(info, "status"))
			{
				RescuePrintStatus(admin, target);
				ShowActionMenu(admin);
			}
			else if (StrEqual(info, "save"))
			{
				ShowPresetSlotMenu(admin);
			}
		}

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				ShowTargetMenu(param1, g_iMenuPage[param1]);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void ShowTeammateMenu(int admin)
{
	int target = GetClientOfUserId(g_iMenuTarget[admin]);

	// Counted before the menu is created, so an empty menu is never built and never has to
	// be destroyed again.
	int candidates = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidSurvivor(i) && IsPlayerAlive(i) && i != target)
			candidates++;
	}

	if (candidates == 0)
	{
		RescueReply(admin, "%t", "Rescue No Teammate");
		ShowActionMenu(admin);
		return;
	}

	Menu menu = new Menu(TeammateMenu_Handler);
	menu.SetTitle("%T", "Rescue Select Teammate", admin);

	char info[16];
	char display[MAX_NAME_LENGTH + 8];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidSurvivor(i) || !IsPlayerAlive(i) || i == target)
			continue;

		IntToString(GetClientUserId(i), info, sizeof info);
		FormatEx(display, sizeof display, "%N", i);
		menu.AddItem(info, display);
	}

	menu.ExitBackButton = true;
	menu.Display(admin, MENU_TIME_FOREVER);
}

public int TeammateMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int admin = param1;

			char info[16];
			menu.GetItem(param2, info, sizeof info);

			int teammate = GetClientOfUserId(StringToInt(info));
			int target = GetClientOfUserId(g_iMenuTarget[admin]);

			if (!IsValidSurvivor(teammate) || !IsPlayerAlive(teammate))
			{
				RescueReply(admin, "%t", "Rescue Target Invalid");
				ShowTeammateMenu(admin);
				return 0;
			}

			if (!IsValidSurvivor(target) || !IsPlayerAlive(target))
			{
				RescueReply(admin, "%t", "Rescue Target Invalid");
				ShowTargetMenu(admin, g_iMenuPage[admin]);
				return 0;
			}

			RescueTeleportNextToTeammate(admin, target, teammate);
			ShowActionMenu(admin);
		}

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				ShowActionMenu(param1);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void ShowPresetMenu(int admin)
{
	if (g_aPresetOrder.Length == 0)
	{
		RescueReply(admin, "%t", "Rescue Preset Empty");
		ShowActionMenu(admin);
		return;
	}

	Menu menu = new Menu(PresetMenu_Handler);
	menu.SetTitle("%T", "Rescue Select Preset", admin);

	char name[PRESET_NAME_LEN];
	for (int i = 0; i < g_aPresetOrder.Length; i++)
	{
		g_aPresetOrder.GetString(i, name, sizeof name);
		menu.AddItem(name, name);
	}

	menu.ExitBackButton = true;
	menu.Display(admin, MENU_TIME_FOREVER);
}

public int PresetMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int admin = param1;

			char name[PRESET_NAME_LEN];
			menu.GetItem(param2, name, sizeof name);

			int target = GetClientOfUserId(g_iMenuTarget[admin]);
			if (!IsValidSurvivor(target) || !IsPlayerAlive(target))
			{
				RescueReply(admin, "%t", "Rescue Target Invalid");
				ShowTargetMenu(admin, g_iMenuPage[admin]);
				return 0;
			}

			RescueTeleportToPreset(admin, target, name);
			ShowActionMenu(admin);
		}

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				ShowActionMenu(param1);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void ShowPresetSlotMenu(int admin)
{
	Menu menu = new Menu(PresetSlotMenu_Handler);
	menu.SetTitle("%T", "Rescue Select Preset Slot", admin);

	char info[8];
	char display[PRESET_NAME_LEN];

	for (int i = 1; i <= PRESET_SLOTS; i++)
	{
		IntToString(i, info, sizeof info);
		FormatEx(display, sizeof display, "%T", "Rescue Preset Slot", admin, i);
		menu.AddItem(info, display);
	}

	menu.ExitBackButton = true;
	menu.Display(admin, MENU_TIME_FOREVER);
}

public int PresetSlotMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int admin = param1;

			char slot[8];
			menu.GetItem(param2, slot, sizeof slot);

			RescueSavePreset(admin, slot);
			ShowActionMenu(admin);
		}

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				ShowActionMenu(param1);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void ShowHealthMenu(int admin)
{
	Menu menu = new Menu(HealthMenu_Handler);
	menu.SetTitle("%T", "Rescue Select Health", admin);

	menu.AddItem("real:100", "100");
	menu.AddItem("real:80", "80");
	menu.AddItem("real:60", "60");
	menu.AddItem("real:40", "40");
	menu.AddItem("real:20", "20");
	menu.AddItem("real:1", "1");
	menu.AddItem("temp:50", "50 (temp)");
	menu.AddItem("temp:25", "25 (temp)");

	menu.ExitBackButton = true;
	menu.Display(admin, MENU_TIME_FOREVER);
}

public int HealthMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int admin = param1;

			char info[16];
			menu.GetItem(param2, info, sizeof info);

			char parts[2][16];
			ExplodeString(info, ":", parts, sizeof parts, sizeof parts[]);

			int target = GetClientOfUserId(g_iMenuTarget[admin]);
			if (!IsValidSurvivor(target) || !IsPlayerAlive(target))
			{
				RescueReply(admin, "%t", "Rescue Target Invalid");
				ShowTargetMenu(admin, g_iMenuPage[admin]);
				return 0;
			}

			RescueApplyHealth(admin, target, StringToInt(parts[1]), StrEqual(parts[0], "temp"));
			ShowActionMenu(admin);
		}

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				ShowActionMenu(param1);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void ShowIncapMenu(int admin)
{
	int maxIncap = GetGameMaxIncapCount();
	int highest = maxIncap > 0 ? maxIncap : 3;

	Menu menu = new Menu(IncapMenu_Handler);
	menu.SetTitle("%T", "Rescue Select Incap", admin);

	char info[8];
	char mark[32];
	char display[RESCUE_MESSAGE_LEN];

	// The entry at the game limit is marked, because that is the one that turns the
	// Survivor black and white.
	for (int i = 0; i <= highest; i++)
	{
		mark[0] = '\0';
		if (maxIncap > 0 && i >= maxIncap)
			FormatEx(mark, sizeof mark, "%T", "Rescue Incap Third Strike Mark", admin);

		IntToString(i, info, sizeof info);
		FormatEx(display, sizeof display, "%T", "Rescue Incap Item", admin, i, mark);
		menu.AddItem(info, display);
	}

	menu.ExitBackButton = true;
	menu.Display(admin, MENU_TIME_FOREVER);
}

public int IncapMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int admin = param1;

			char info[8];
			menu.GetItem(param2, info, sizeof info);

			int target = GetClientOfUserId(g_iMenuTarget[admin]);
			if (!IsValidSurvivor(target) || !IsPlayerAlive(target))
			{
				RescueReply(admin, "%t", "Rescue Target Invalid");
				ShowTargetMenu(admin, g_iMenuPage[admin]);
				return 0;
			}

			RescueApplyIncapCount(admin, target, StringToInt(info));
			ShowActionMenu(admin);
		}

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				ShowActionMenu(param1);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

// ===========================================================================
// Target helpers
// ===========================================================================

/**
 * Resolves a command target pattern to one Survivor.
 *
 * @param requireAlive  True for everything that needs a Survivor on their feet. The restore
 *                      command passes false so a dead Survivor can be resolved and then
 *                      answered with a message that actually explains the situation,
 *                      instead of the generic "target must be alive" from the resolver.
 *
 * @return Client index, or -1 when the target could not be resolved.
 */
int ResolveTarget(int admin, const char[] pattern, bool requireAlive = true)
{
	int targets[MAXPLAYERS];
	char targetName[MAX_TARGET_LENGTH];
	bool multiLingual;

	int flags = COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_MULTI;
	if (requireAlive)
		flags |= COMMAND_FILTER_ALIVE;

	int count = ProcessTargetString(pattern, admin, targets, sizeof targets,
		flags, targetName, sizeof targetName, multiLingual);

	if (count <= 0)
	{
		// ReplyToTargetError falls back to the server console when admin is 0.
		ReplyToTargetError(admin, count);
		return -1;
	}

	int target = targets[0];
	if (!IsValidSurvivor(target))
	{
		RescueReply(admin, "%t", "Rescue Target Invalid");
		return -1;
	}

	return target;
}

bool IsRescueEnabled(int admin)
{
	if (g_cvEnable.BoolValue)
		return true;

	RescueReply(admin, "%t", "Rescue Disabled");
	return false;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool IsValidSurvivor(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == TEAM_SURVIVOR;
}

// ===========================================================================
// Teleport
// ===========================================================================

void RescueTeleportToAim(int admin, int target)
{
	if (!IsValidClient(admin))
	{
		RescueReply(admin, "%t", "Rescue Aim Needs Player");
		return;
	}

	float aim[3];
	if (!GetAimOrigin(admin, aim))
	{
		RescueReply(admin, "%t", "Rescue Aim Failed");
		return;
	}

	float destination[3];
	int infected = 0;
	RescueBlock block = ApplySafetyCheck(aim, destination, infected);
	if (block != RescueBlock_None)
	{
		ReportBlocked(admin, block, infected);
		return;
	}

	// The destination label is built twice: once in the referee's language for the private
	// reply, and once in the server language for the broadcast, so the announcement cannot
	// end up mixing two languages when the referee and the server differ.
	char label[RESCUE_REASON_LEN];
	char announceLabel[RESCUE_REASON_LEN];
	FormatEx(label, sizeof label, "%T", "Rescue Destination Aim", admin);
	FormatEx(announceLabel, sizeof announceLabel, "%T", "Rescue Destination Aim", LANG_SERVER);

	PerformRescueTeleport(admin, target, destination, label, announceLabel);
}

void RescueTeleportNextToTeammate(int admin, int target, int teammate)
{
	if (!IsValidSurvivor(teammate) || !IsPlayerAlive(teammate))
	{
		RescueReply(admin, "%t", "Rescue Teammate Invalid");
		return;
	}

	float base[3];
	GetClientAbsOrigin(teammate, base);

	// Prefer the closest free spot, then widen the ring. A Survivor is never dropped on top
	// of the teammate, because the engine would push them apart and could shove the
	// teammate off a ledge.
	float candidate[3];
	float destination[3];
	bool found = false;
	RescueBlock lastBlock = RescueBlock_None;
	int lastInfected = 0;
	int infected;

	for (float radius = TEAMMATE_RING_RADIUS_MIN; radius <= TEAMMATE_RING_RADIUS_MAX && !found; radius += TEAMMATE_RING_RADIUS_STEP)
	{
		for (int step = 0; step < TEAMMATE_RING_ANGLES; step++)
		{
			float angle = DegToRad(float(step) * (360.0 / float(TEAMMATE_RING_ANGLES)));

			candidate[0] = base[0] + Cosine(angle) * radius;
			candidate[1] = base[1] + Sine(angle) * radius;
			candidate[2] = base[2];

			RescueBlock block = ApplySafetyCheck(candidate, destination, infected);

			if (block == RescueBlock_None)
			{
				// A ring point that resolves onto a floor far above or below the teammate is
				// a ledge, a balcony or a lift shaft, not "next to the teammate".
				if (destination[2] < base[2] - TEAMMATE_MAX_HEIGHT_DELTA
					|| destination[2] > base[2] + TEAMMATE_MAX_HEIGHT_DELTA)
				{
					RememberBlock(lastBlock, lastInfected, RescueBlock_Level, 0);
					continue;
				}

				if (IsSpotOccupied(destination, target, teammate))
				{
					RememberBlock(lastBlock, lastInfected, RescueBlock_Occupied, 0);
					continue;
				}

				found = true;
				break;
			}

			RememberBlock(lastBlock, lastInfected, block, infected);
		}
	}

	if (!found)
	{
		ReportBlocked(admin, lastBlock, lastInfected);
		return;
	}

	char label[RESCUE_REASON_LEN];
	char announceLabel[RESCUE_REASON_LEN];
	FormatEx(label, sizeof label, "%T", "Rescue Destination Teammate", admin, teammate);
	FormatEx(announceLabel, sizeof announceLabel, "%T", "Rescue Destination Teammate", LANG_SERVER, teammate);

	PerformRescueTeleport(admin, target, destination, label, announceLabel);
}

void RescueTeleportToPreset(int admin, int target, const char[] name)
{
	if (g_aPresetOrder.Length == 0)
	{
		RescueReply(admin, "%t", "Rescue Preset Empty");
		return;
	}

	float preset[3];
	if (!GetPreset(name, preset))
	{
		RescueReply(admin, "%t", "Rescue Preset Missing", name);
		return;
	}

	float destination[3];
	int infected = 0;
	RescueBlock block = ApplySafetyCheck(preset, destination, infected);
	if (block != RescueBlock_None)
	{
		ReportBlocked(admin, block, infected);
		return;
	}

	char label[RESCUE_REASON_LEN];
	char announceLabel[RESCUE_REASON_LEN];
	FormatEx(label, sizeof label, "%T", "Rescue Destination Preset", admin, name);
	FormatEx(announceLabel, sizeof announceLabel, "%T", "Rescue Destination Preset", LANG_SERVER, name);

	PerformRescueTeleport(admin, target, destination, label, announceLabel);
}

/**
 * Runs the destination safety check unless the referee turned it off. With the check
 * disabled the raw position is used, which is what the referee explicitly asked for.
 */
RescueBlock ApplySafetyCheck(const float pos[3], float destination[3], int &infected)
{
	infected = 0;

	if (!g_cvSafeCheck.BoolValue)
	{
		destination = pos;
		return RescueBlock_None;
	}

	return ValidateStandPosition(pos, destination, infected);
}

void PerformRescueTeleport(int admin, int target, const float destination[3], const char[] label, const char[] announceLabel)
{
	if (!IsValidSurvivor(target) || !IsPlayerAlive(target))
	{
		RescueReply(admin, "%t", "Rescue Target Invalid");
		return;
	}

	// A pinned Survivor is normal play rather than a bug accident, and a teleport would drag
	// the pin along and put them down at the destination still disabled. Refusing is better
	// than silently rewriting the match.
	if (L4D2_GetInfectedAttacker(target) > 0)
	{
		RescueReply(admin, "%t", "Rescue Target Pinned", target);
		return;
	}

	PrepareSurvivorForTeleport(target);

	float zero[3];
	TeleportEntity(target, destination, NULL_VECTOR, zero);

	// NULL_VECTOR means "leave the velocity alone", so the explicit zero vector above is
	// what stops the Survivor. Repeating it as a netprop write means someone who was
	// falling or flying cannot carry that momentum into the new position.
	SetEntPropVector(target, Prop_Data, "m_vecVelocity", zero);

	char message[RESCUE_MESSAGE_LEN * 2];
	FormatEx(message, sizeof message, "%L teleported %L to %s (%.1f %.1f %.1f)",
		admin, target, label, destination[0], destination[1], destination[2]);
	RescueLogLine(admin, target, message);

	RescueReply(admin, "%t", "Rescue Teleport Success", target, label);
	AnnounceRescue("%t", "Rescue Announce Teleport", target, announceLabel);
}

/**
 * Removes the states that would otherwise survive a teleport and drag the Survivor back.
 *
 * MOVETYPE_WALK and the frozen flag are cleared because the whole point of the command is
 * that the Survivor ends up standing and movable at the new position; a Survivor who is
 * frozen, or in a non-walking move type, would simply arrive stuck in a different place.
 *
 * Nothing else is touched. In particular a Survivor who is currently pinned is not cleaned
 * up: a pin is normal play rather than a bug accident, breaking it would be a change to the
 * match that the referee did not ask for, and the pin would travel with them anyway. That
 * case is refused before this is reached.
 */
void PrepareSurvivorForTeleport(int target)
{
	SetEntityMoveType(target, MOVETYPE_WALK);

	int flags = GetEntProp(target, Prop_Send, "m_fFlags");
	if (flags & FL_FROZEN)
		SetEntProp(target, Prop_Send, "m_fFlags", flags & ~FL_FROZEN);
}

/**
 * Finds the world position the admin is aiming at, rejecting a ray that never hit anything
 * or that ended outside the playable world.
 */
bool GetAimOrigin(int admin, float origin[3])
{
	float eyePosition[3];
	float eyeAngles[3];
	GetClientEyePosition(admin, eyePosition);
	GetClientEyeAngles(admin, eyeAngles);

	Handle trace = TR_TraceRayFilterEx(eyePosition, eyeAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter_WorldOnly);

	bool found = false;
	if (TR_DidHit(trace) && TR_GetFraction(trace) < 1.0)
	{
		TR_GetEndPosition(origin, trace);
		found = !TR_PointOutsideWorld(origin);
	}

	delete trace;
	return found;
}

/**
 * Checks a candidate position and normalises it onto the ground.
 *
 * @return RescueBlock_None when the position is usable.
 */
RescueBlock ValidateStandPosition(const float pos[3], float destination[3], int &infected, bool checkInfected = true)
{
	infected = 0;

	// Aiming into a wall or a prop is rejected outright, instead of quietly dropping the
	// Survivor on top of whatever was aimed at.
	if (IsHullBlocked(pos))
		return RescueBlock_Wall;

	float start[3];
	float end[3];
	start = pos;
	start[2] += GROUND_HULL_LIFT;
	end = start;
	end[2] -= g_cvMaxDrop.FloatValue;

	Handle trace = TR_TraceHullFilterEx(start, end, g_fHullMins, g_fHullMaxs,
		MASK_PLAYERSOLID, TraceFilter_WorldOnly);

	// Starting inside geometry means the spot is buried in a wall, a prop or a ceiling.
	if (TR_StartSolid(trace) || TR_AllSolid(trace))
	{
		delete trace;
		return RescueBlock_Wall;
	}

	// Nothing underneath inside the search depth: a pit, a hole, or off the map.
	if (!TR_DidHit(trace) || TR_GetFraction(trace) >= 1.0)
	{
		delete trace;
		return RescueBlock_Void;
	}

	TR_GetEndPosition(destination, trace);
	delete trace;

	// The hull has to fit where it actually comes to rest, not where it was aimed.
	if (IsHullBlocked(destination))
		return RescueBlock_Wall;

	if (checkInfected && g_cvSiRadius.FloatValue > 0.0)
	{
		infected = CountNearbySpecialInfected(destination, g_cvSiRadius.FloatValue);
		if (infected > 0)
			return RescueBlock_Infected;
	}

	return RescueBlock_None;
}

/**
 * True when the Survivor hull overlaps solid geometry at the given position.
 *
 * The hull is swept one unit down onto the position rather than traced with a zero length
 * start and end, so the engine always performs a real containment test. Coming to rest on
 * the floor is the normal case and does not count as blocked; only starting inside
 * geometry does.
 */
bool IsHullBlocked(const float pos[3])
{
	float start[3];
	float end[3];
	start = pos;
	start[2] += 1.0;
	end = pos;

	Handle trace = TR_TraceHullFilterEx(start, end, g_fHullMins, g_fHullMaxs,
		MASK_PLAYERSOLID, TraceFilter_WorldOnly);

	bool blocked = TR_StartSolid(trace) || TR_AllSolid(trace);

	delete trace;
	return blocked;
}

/**
 * Counts living Special Infected close enough to the destination to make the arrival a
 * second accident. Ghost Infected are ignored: they are not a threat where they hover.
 */
int CountNearbySpecialInfected(const float pos[3], float radius)
{
	float squaredRadius = radius * radius;
	float origin[3];
	int count = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || GetClientTeam(i) != TEAM_INFECTED)
			continue;

		if (!IsPlayerAlive(i) || L4D_IsPlayerGhost(i))
			continue;

		GetClientAbsOrigin(i, origin);
		if (GetVectorDistance(pos, origin, true) <= squaredRadius)
			count++;
	}

	return count;
}

bool IsSpotOccupied(const float pos[3], int ignoreA, int ignoreB)
{
	float squaredDistance = SPOT_OCCUPIED_DISTANCE * SPOT_OCCUPIED_DISTANCE;
	float origin[3];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == ignoreA || i == ignoreB)
			continue;

		if (!IsValidSurvivor(i) || !IsPlayerAlive(i))
			continue;

		GetClientAbsOrigin(i, origin);
		if (GetVectorDistance(pos, origin, true) <= squaredDistance)
			return true;
	}

	return false;
}

/**
 * Trace filter that keeps the world and props but drops every player, so a teammate
 * standing on a spot does not read as a solid wall.
 */
public bool TraceFilter_WorldOnly(int entity, int contentsMask)
{
	return entity < 1 || entity > MaxClients;
}

void ReportBlocked(int admin, RescueBlock block, int infected)
{
	char reason[RESCUE_REASON_LEN];
	FormatBlockReason(reason, sizeof reason, admin, block, infected);

	RescueReply(admin, "%t", "Rescue Unsafe Destination", reason);
}

/**
 * Keeps the most useful rejection reason for the operator message while the ring search
 * tries candidate after candidate. Special Infected beat everything because they are the
 * most actionable, then real geometry problems, then "the nearby spots are taken".
 */
void RememberBlock(RescueBlock &current, int &currentInfected, RescueBlock candidate, int infected)
{
	if (candidate == RescueBlock_Occupied && current != RescueBlock_None)
		return;

	if (current == RescueBlock_None
		|| candidate == RescueBlock_Infected
		|| current == RescueBlock_Occupied
		|| current == RescueBlock_Level)
	{
		current = candidate;
		currentInfected = infected;
	}
}

void FormatBlockReason(char[] buffer, int maxlen, int admin, RescueBlock block, int infected)
{
	switch (block)
	{
		case RescueBlock_Wall:
			FormatEx(buffer, maxlen, "%T", "Rescue Unsafe Reason Wall", admin);

		case RescueBlock_Void:
			FormatEx(buffer, maxlen, "%T", "Rescue Unsafe Reason Void", admin);

		case RescueBlock_Infected:
			FormatEx(buffer, maxlen, "%T", "Rescue Unsafe Reason Infected", admin, infected);

		case RescueBlock_Level:
			FormatEx(buffer, maxlen, "%T", "Rescue Unsafe Reason Level", admin);

		case RescueBlock_Occupied:
			FormatEx(buffer, maxlen, "%T", "Rescue Unsafe Reason Occupied", admin);

		default:
			FormatEx(buffer, maxlen, "%T", "Rescue Unsafe Reason Unknown", admin);
	}
}

// ===========================================================================
// State restore
// ===========================================================================

void RescueApplyHealth(int admin, int target, int amount, bool asTemporary)
{
	if (!IsValidSurvivor(target) || !IsPlayerAlive(target))
	{
		RescueReply(admin, "%t", "Rescue Target Invalid");
		return;
	}

	if (amount < RESCUE_MIN_HEALTH)
	{
		RescueReply(admin, "%t", "Rescue Health Too Low", amount, RESCUE_MIN_HEALTH);
		amount = RESCUE_MIN_HEALTH;
	}

	if (asTemporary)
	{
		float oldTemp = GetClientTempHealth(target);

		int tempCeiling = GetClientMaxHealth(target);
		if (amount > tempCeiling)
		{
			RescueReply(admin, "%t", "Rescue Health Clamped", target, amount, tempCeiling);
			amount = tempCeiling;
		}

		SetClientTempHealth(target, float(amount));

		char message[RESCUE_MESSAGE_LEN * 2];
		FormatEx(message, sizeof message, "%L set temporary health of %L: %.0f -> %d",
			admin, target, oldTemp, amount);
		RescueLogLine(admin, target, message);

		RescueReply(admin, "%t", "Rescue Temp Health Success", target, float(amount), oldTemp);
		AnnounceRescue("%t", "Rescue Announce Health", target, amount);
		return;
	}

	int maxHealth = GetClientMaxHealth(target);
	if (amount > maxHealth)
	{
		RescueReply(admin, "%t", "Rescue Health Clamped", target, amount, maxHealth);
		amount = maxHealth;
	}

	int oldHealth = GetClientHealth(target);
	float oldTemp = GetClientTempHealth(target);

	// While a Survivor is down, m_iHealth is the bleed-out pool, not the health they stand
	// up with: writing it here would only make them die sooner, and the game replaces it
	// from its own pre-incap state on the pickup anyway. So the requested value is stored
	// where a downed Survivor is actually rebuilt from, and the referee is told that it
	// takes effect on the rescue.
	if (L4D_IsPlayerIncapacitated(target) || L4D_IsPlayerHangingFromLedge(target))
	{
		// The old pre-incap value is logged rather than the bleed-out pool, because the pool
		// is not comparable with the value being written and would read as nonsense in a
		// dispute review.
		int previousPreIncap = L4D2Direct_GetPreIncapHealth(target);

		L4D2Direct_SetPreIncapHealth(target, amount);
		L4D2Direct_SetPreIncapHealthBuffer(target, 0);

		char downMessage[RESCUE_MESSAGE_LEN * 2];
		FormatEx(downMessage, sizeof downMessage,
			"%L set the pre-incap health of %L (down, bleed-out pool %d): %d -> %d",
			admin, target, oldHealth, previousPreIncap, amount);
		RescueLogLine(admin, target, downMessage);

		RescueReply(admin, "%t", "Rescue Health WhileDown", target, amount, previousPreIncap);
		AnnounceRescue("%t", "Rescue Announce Health Down", target, amount);
		return;
	}

	SetEntityHealth(target, amount);

	// Clear the decaying buffer so the Survivor's health really is the requested number
	// instead of that number plus whatever overheal was still ticking down.
	SetClientTempHealth(target, 0.0);

	char message[RESCUE_MESSAGE_LEN * 2];
	FormatEx(message, sizeof message, "%L set health of %L: %d -> %d (temporary health %.0f -> 0)",
		admin, target, oldHealth, amount, oldTemp);
	RescueLogLine(admin, target, message);

	RescueReply(admin, "%t", "Rescue Health Success", target, amount, oldHealth);
	AnnounceRescue("%t", "Rescue Announce Health", target, amount);
}

void RescueApplyIncapCount(int admin, int target, int count)
{
	if (!IsValidSurvivor(target) || !IsPlayerAlive(target))
	{
		RescueReply(admin, "%t", "Rescue Target Invalid");
		return;
	}

	if (count < 0)
	{
		RescueReply(admin, "%t", "Rescue Incap Clamped", count, 0);
		count = 0;
	}

	int maxIncap = GetGameMaxIncapCount();
	if (maxIncap > 0 && count > maxIncap)
	{
		RescueReply(admin, "%t", "Rescue Incap Clamped", count, maxIncap);
		count = maxIncap;
	}

	int oldCount = GetClientReviveCount(target);
	SetClientReviveCount(target, count, maxIncap);

	char message[RESCUE_MESSAGE_LEN * 2];
	FormatEx(message, sizeof message, "%L set incap count of %L: %d -> %d",
		admin, target, oldCount, count);
	RescueLogLine(admin, target, message);

	RescueReply(admin, "%t", "Rescue Incap Success", target, count, oldCount);
	AnnounceRescue("%t", "Rescue Announce Incap", target, count);
}

void RescueRestoreSnapshot(int admin, int target)
{
	if (!IsValidSurvivor(target))
	{
		RescueReply(admin, "%t", "Rescue Target Invalid");
		return;
	}

	// Bringing a dead Survivor back needs the death and defibrillator path, which this
	// plugin deliberately does not touch - a dead Survivor is not an incap-count accident,
	// and this repository already ships a defib plugin for it. Say so plainly instead of
	// failing with a generic target error.
	if (!IsPlayerAlive(target))
	{
		RescueReply(admin, "%t", "Rescue Target Dead", target);
		return;
	}

	if (!g_bSnapshotValid[target])
	{
		RescueReply(admin, "%t", "Rescue Snapshot Missing", target);
		return;
	}

	int health = g_iSnapshotHealth[target];
	float tempHealth = g_fSnapshotTempHealth[target];
	int reviveCount = g_iSnapshotReviveCount[target];

	int maxHealth = GetClientMaxHealth(target);
	if (health > maxHealth)
		health = maxHealth;
	if (health < RESCUE_MIN_HEALTH)
		health = RESCUE_MIN_HEALTH;

	int oldHealth = GetClientHealth(target);
	float oldTemp = GetClientTempHealth(target);
	int oldCount = GetClientReviveCount(target);

	bool wasDown = L4D_IsPlayerHangingFromLedge(target) || L4D_IsPlayerIncapacitated(target);

	char detail[64];
	detail[0] = '\0';
	if (wasDown)
		FormatEx(detail, sizeof detail, " (revived from incapacitated or ledge hang)");

	if (wasDown)
	{
		// Stand them back up first: a Survivor who is still on the ground cannot be given a
		// standing health value the game keeps, and the accident is only undone once they
		// are actually playing again.
		L4D_ReviveSurvivor(target);

		// Standing a Survivor up runs the game's own revive path, which assigns health as
		// part of the transition. Re-applying the recorded values one tick later makes sure
		// the referee's numbers are the ones that stick.
		DataPack pack;
		CreateDataTimer(0.2, Timer_ApplyRestore, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(GetClientUserId(target));
		pack.WriteCell(health);
		pack.WriteFloat(tempHealth);
		pack.WriteCell(reviveCount);
	}
	else
	{
		SetEntityHealth(target, health);
		SetClientTempHealth(target, tempHealth);
		SetClientReviveCount(target, reviveCount, GetGameMaxIncapCount());
	}

	char message[RESCUE_MESSAGE_LEN * 3];
	FormatEx(message, sizeof message,
		"%L restored %L to the pre-accident state%s: health %d -> %d, temporary health %.0f -> %.0f, incap count %d -> %d",
		admin, target, detail, oldHealth, health, oldTemp, tempHealth, oldCount, reviveCount);
	RescueLogLine(admin, target, message);

	RescueReply(admin, "%t", "Rescue Restore Success", target, health, reviveCount);
	AnnounceRescue("%t", "Rescue Announce Restore", target);
}

/**
 * Second half of a revive-and-restore. The DataPack is owned by the timer
 * (CreateDataTimer adds TIMER_DATA_HNDL_CLOSE), so it must not be deleted here.
 */
public Action Timer_ApplyRestore(Handle timer, DataPack pack)
{
	pack.Reset();

	int client = GetClientOfUserId(pack.ReadCell());
	int health = pack.ReadCell();
	float tempHealth = pack.ReadFloat();
	int reviveCount = pack.ReadCell();

	if (!IsValidSurvivor(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	SetEntityHealth(client, health);
	SetClientTempHealth(client, tempHealth);
	SetClientReviveCount(client, reviveCount, GetGameMaxIncapCount());

	return Plugin_Stop;
}

void RescuePrintStatus(int admin, int target)
{
	if (!IsValidSurvivor(target))
	{
		RescueReply(admin, "%t", "Rescue Target Invalid");
		return;
	}

	char state[64];
	if (!IsPlayerAlive(target))
		FormatEx(state, sizeof state, "%T", "Rescue State Dead", admin);
	else if (L4D_IsPlayerHangingFromLedge(target))
		FormatEx(state, sizeof state, "%T", "Rescue State Hanging", admin);
	else if (L4D_IsPlayerIncapacitated(target))
		FormatEx(state, sizeof state, "%T", "Rescue State Incapped", admin);
	else
		FormatEx(state, sizeof state, "%T", "Rescue State Normal", admin);

	char line[RESCUE_MESSAGE_LEN];
	int maxIncap = GetGameMaxIncapCount();

	if (maxIncap > 0)
	{
		FormatEx(line, sizeof line, "%T", "Rescue Status Line Max", admin,
			target, GetClientHealth(target), GetClientTempHealth(target),
			GetClientReviveCount(target), maxIncap, state);
	}
	else
	{
		FormatEx(line, sizeof line, "%T", "Rescue Status Line", admin,
			target, GetClientHealth(target), GetClientTempHealth(target),
			GetClientReviveCount(target), state);
	}

	RescueReplyText(admin, line);

	if (g_bSnapshotValid[target])
	{
		FormatEx(line, sizeof line, "%T", "Rescue Status Snapshot", admin,
			g_iSnapshotHealth[target], g_fSnapshotTempHealth[target], g_iSnapshotReviveCount[target]);
		RescueReplyText(admin, line);
	}
	else
	{
		RescueReply(admin, "%t", "Rescue Status No Snapshot", target);
	}
}

// ---------------------------------------------------------------------------
// State accessors. Health, temporary health and incap count are all plain netprops, so the
// plugin does not need a native to read or write them.
// ---------------------------------------------------------------------------

int GetClientReviveCount(int client)
{
	return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}

/**
 * Writes the incap count and keeps the third-strike flag in step with it. When the game
 * limit is unknown the flag is left alone rather than being guessed at.
 *
 * The black-and-white outline glow is deliberately not touched: m_iGlowType and friends are
 * a shared visual channel that other plugins in this repository use for their own markers,
 * so clearing them here could wipe someone else's effect. Clearing m_bIsOnThirdStrike is
 * the flag the game reads.
 */
void SetClientReviveCount(int client, int count, int maxIncap)
{
	SetEntProp(client, Prop_Send, "m_currentReviveCount", count);

	if (maxIncap <= 0)
		return;

	SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", count >= maxIncap ? 1 : 0);
}

float GetClientTempHealth(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
}

void SetClientTempHealth(int client, float value)
{
	if (value < 0.0)
		value = 0.0;

	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", value);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

int GetClientMaxHealth(int client)
{
	int maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
	return maxHealth > 0 ? maxHealth : RESCUE_DEFAULT_MAX_HEALTH;
}

int GetGameMaxIncapCount()
{
	if (g_cvGameMaxIncap == null)
	{
		g_cvGameMaxIncap = FindConVar("survivor_max_incapacitated_count");
		if (g_cvGameMaxIncap == null)
			return 0;
	}

	int maxIncap = g_cvGameMaxIncap.IntValue;
	return maxIncap > 0 ? maxIncap : 0;
}

// ===========================================================================
// Accident recording
// ===========================================================================

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	RecordStandingState(GetClientOfUserId(event.GetInt("userid")));
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	// Recorded after the hit, so the value kept is the health the Survivor was still
	// standing at. A hit that incaps or kills them leaves the previous value in place,
	// which is exactly the pre-accident value a referee wants to restore.
	RecordStandingState(GetClientOfUserId(event.GetInt("userid")));
}

void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	RecordStandingState(GetClientOfUserId(event.GetInt("subject")));
}

void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	RecordStandingState(GetClientOfUserId(event.GetInt("subject")));
}

void Event_PlayerIncapacitatedStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvSnapshot.BoolValue)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(client))
		return;

	if (g_bStandingValid[client])
	{
		g_iSnapshotHealth[client] = g_iStandingHealth[client];
		g_fSnapshotTempHealth[client] = g_fStandingTempHealth[client];
		g_iSnapshotReviveCount[client] = g_iStandingReviveCount[client];
	}
	else
	{
		// No standing sample yet (the first incap after a late load, for example), so fall
		// back to the Survivor's maximum health rather than to whatever the damaging hit
		// left behind.
		g_iSnapshotHealth[client] = GetClientMaxHealth(client);
		g_fSnapshotTempHealth[client] = 0.0;
		g_iSnapshotReviveCount[client] = GetClientReviveCount(client);
	}

	g_bSnapshotValid[client] = true;

	char message[RESCUE_MESSAGE_LEN];
	FormatEx(message, sizeof message, "recorded pre-incap state of %L: health %d, temporary health %.0f, incap count %d",
		client, g_iSnapshotHealth[client], g_fSnapshotTempHealth[client], g_iSnapshotReviveCount[client]);
	RescueLogLine(-1, client, message, false);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// A recording only describes the life the Survivor is on, so it does not survive a
	// round boundary.
	for (int i = 1; i <= MaxClients; i++)
		ClearClientRecords(i);
}

/**
 * Samples the state of a Survivor who is alive and on their feet. Read-only: this never
 * writes to the game, it only remembers values for a later restore.
 */
void RecordStandingState(int client)
{
	if (!g_cvSnapshot.BoolValue)
		return;

	if (!IsValidSurvivor(client) || !IsPlayerAlive(client))
		return;

	if (L4D_IsPlayerIncapacitated(client) || L4D_IsPlayerHangingFromLedge(client))
		return;

	int health = GetClientHealth(client);
	if (health <= 0)
		return;

	g_bStandingValid[client] = true;
	g_iStandingHealth[client] = health;
	g_fStandingTempHealth[client] = GetClientTempHealth(client);
	g_iStandingReviveCount[client] = GetClientReviveCount(client);
}

void ClearClientRecords(int client)
{
	if (client < 1 || client > MaxClients)
		return;

	g_bStandingValid[client] = false;
	g_iStandingHealth[client] = 0;
	g_fStandingTempHealth[client] = 0.0;
	g_iStandingReviveCount[client] = 0;

	g_bSnapshotValid[client] = false;
	g_iSnapshotHealth[client] = 0;
	g_fSnapshotTempHealth[client] = 0.0;
	g_iSnapshotReviveCount[client] = 0;
}

// ===========================================================================
// Presets
// ===========================================================================

void LoadPresets()
{
	g_smPresets.Clear();
	g_aPresetOrder.Clear();

	GetCurrentMapName(g_sPresetMap, sizeof g_sPresetMap);

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof path, PRESET_PATH);

	KeyValues kv = new KeyValues(PRESET_ROOT);
	if (!kv.ImportFromFile(path))
	{
		delete kv;
		return;
	}

	if (kv.JumpToKey(g_sPresetMap) && kv.GotoFirstSubKey(false))
	{
		char name[PRESET_NAME_LEN];
		char value[64];

		do
		{
			kv.GetSectionName(name, sizeof name);
			kv.GetString(NULL_STRING, value, sizeof value);

			if (name[0] != '\0' && value[0] != '\0')
			{
				g_smPresets.SetString(name, value);
				g_aPresetOrder.PushString(name);
			}
		}
		while (kv.GotoNextKey(false));
	}

	delete kv;
}

bool GetPreset(const char[] name, float pos[3])
{
	char value[64];
	if (!g_smPresets.GetString(name, value, sizeof value))
		return false;

	char parts[3][32];
	if (ExplodeString(value, " ", parts, sizeof parts, sizeof parts[]) != 3)
		return false;

	pos[0] = StringToFloat(parts[0]);
	pos[1] = StringToFloat(parts[1]);
	pos[2] = StringToFloat(parts[2]);

	return true;
}

void RescueSavePreset(int admin, const char[] name)
{
	if (!IsValidClient(admin))
	{
		RescueReply(admin, "%t", "Rescue Aim Needs Player");
		return;
	}

	if (name[0] == '\0')
	{
		RescueReply(admin, "%t", "Rescue Usage Save");
		return;
	}

	// The name becomes a KeyValues section name, and saving rewrites the whole file, so a
	// quote, a backslash or a brace would corrupt the presets of every map on the server.
	if (!IsValidPresetName(name))
	{
		RescueReply(admin, "%t", "Rescue Preset Name Invalid", name);
		return;
	}

	float aim[3];
	if (!GetAimOrigin(admin, aim))
	{
		RescueReply(admin, "%t", "Rescue Aim Failed");
		return;
	}

	// Snap the saved point onto the ground, so a preset taken while looking slightly above
	// the floor still lands correctly later. Special Infected are not considered here: the
	// point may well be useful again once they have moved on.
	float destination[3];
	int infected = 0;

	if (g_cvSafeCheck.BoolValue)
	{
		RescueBlock block = ValidateStandPosition(aim, destination, infected, false);
		if (block != RescueBlock_None)
		{
			ReportBlocked(admin, block, infected);
			return;
		}
	}
	else
	{
		destination = aim;
	}

	if (!SavePreset(name, destination))
	{
		RescueReply(admin, "%t", "Rescue Preset Save Failed");
		RescueLogLine(admin, -1, "failed to write the preset file");
		return;
	}

	char message[RESCUE_MESSAGE_LEN * 2];
	FormatEx(message, sizeof message, "%L saved preset \"%s\" on %s at (%.1f %.1f %.1f)",
		admin, name, g_sPresetMap, destination[0], destination[1], destination[2]);
	RescueLogLine(admin, -1, message);

	RescueReply(admin, "%t", "Rescue Preset Saved", name,
		destination[0], destination[1], destination[2]);
}

bool SavePreset(const char[] name, const float pos[3])
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof path, PRESET_PATH);

	// Re-read first so presets saved for other maps are preserved. An absent file is the
	// normal first run; a file that exists but cannot be parsed is not, and exporting on top
	// of it would silently drop every other map's presets.
	KeyValues kv = new KeyValues(PRESET_ROOT);
	if (!kv.ImportFromFile(path) && FileExists(path))
	{
		delete kv;
		return false;
	}

	kv.JumpToKey(g_sPresetMap, true);

	char value[64];
	FormatEx(value, sizeof value, "%.3f %.3f %.3f", pos[0], pos[1], pos[2]);
	kv.SetString(name, value);

	kv.Rewind();
	bool written = kv.ExportToFile(path);
	delete kv;

	if (written)
	{
		g_smPresets.SetString(name, value);

		if (g_aPresetOrder.FindString(name) == -1)
			g_aPresetOrder.PushString(name);
	}

	return written;
}

/**
 * A preset name is written straight into the config as a KeyValues section name, and
 * KeyValues has no escaping for those, so anything that would break the file structure is
 * rejected. Bytes above 127 are allowed, which keeps non-Latin names usable.
 */
bool IsValidPresetName(const char[] name)
{
	int length = strlen(name);
	if (length < 1 || length > PRESET_NAME_LEN - 1)
		return false;

	for (int i = 0; i < length; i++)
	{
		if (name[i] < 32 || name[i] == '"' || name[i] == '\\' || name[i] == '{' || name[i] == '}')
			return false;
	}

	return true;
}

/**
 * Map names for Workshop maps can carry a "workshop/<id>/" prefix. The preset file is keyed
 * by the plain map name, so the same map always resolves to the same section.
 */
void GetCurrentMapName(char[] buffer, int maxlen)
{
	char map[PLATFORM_MAX_PATH];
	GetCurrentMap(map, sizeof map);

	int offset = 0;
	for (int i = strlen(map) - 1; i >= 0; i--)
	{
		if (map[i] == '/' || map[i] == '\\')
		{
			offset = i + 1;
			break;
		}
	}

	strcopy(buffer, maxlen, map[offset]);
}

// ===========================================================================
// Feedback and logging
// ===========================================================================

/**
 * Sends a localised line to the referee who ran the command.
 */
void RescueReply(int admin, const char[] phrase, any ...)
{
	int languageTarget = IsValidClient(admin) ? admin : LANG_SERVER;

	char message[RESCUE_MESSAGE_LEN];
	SetGlobalTransTarget(languageTarget);
	VFormat(message, sizeof message, phrase, 3);

	char prefix[32];
	FormatEx(prefix, sizeof prefix, "%T", "Rescue Prefix", languageTarget);

	if (IsValidClient(admin))
		PrintToChat(admin, "\x04[%s]\x01 %s", prefix, message);
	else
		PrintToServer("[%s] %s", prefix, message);
}

/**
 * Sends an already formatted line to the referee.
 */
void RescueReplyText(int admin, const char[] text)
{
	char prefix[32];
	FormatEx(prefix, sizeof prefix, "%T", "Rescue Prefix", IsValidClient(admin) ? admin : LANG_SERVER);

	if (IsValidClient(admin))
		PrintToChat(admin, "\x04[%s]\x01 %s", prefix, text);
	else
		PrintToServer("[%s] %s", prefix, text);
}

/**
 * Tells both teams what happened. A rescue always changes the match, so saying so out loud
 * is what keeps it from becoming the next dispute. Uses the server language, because one
 * format call cannot be re-translated per client.
 */
void AnnounceRescue(const char[] phrase, any ...)
{
	if (!g_cvAnnounce.BoolValue)
		return;

	char message[RESCUE_MESSAGE_LEN];
	SetGlobalTransTarget(LANG_SERVER);
	VFormat(message, sizeof message, phrase, 2);

	char prefix[32];
	FormatEx(prefix, sizeof prefix, "%T", "Rescue Prefix", LANG_SERVER);

	PrintToChatAll("\x04[%s]\x01 %s", prefix, message);
}

/**
 * Writes one line to the plugin's own review log, and optionally to the standard SourceMod
 * admin log. The message must already name the admin, the target and the old and new values.
 *
 * The dedicated file exists because a disputed round is reviewed by reading one short file
 * rather than by searching the whole admin log. The path is spelled out instead of using
 * LogToFile(), whose naming rules are not obvious.
 *
 * @param admin         Client who performed the action, or -1 when no admin caused it. Passed
 *                      on to LogAction so the standard log records the actor itself rather
 *                      than relying on the name inside the message.
 * @param target        Client the action applied to, or -1.
 * @param message       What happened.
 * @param alsoAdminLog  False for observations that no admin caused, such as recording a
 *                      Survivor's state when they go down. Those belong in the review log
 *                      but would only add noise to the admin action log.
 */
void RescueLogLine(int admin, int target, const char[] message, bool alsoAdminLog = true)
{
	char stamped[RESCUE_MESSAGE_LEN * 3];
	FormatEx(stamped, sizeof stamped, "[%s] %s", g_sPresetMap, message);

	if (alsoAdminLog)
		LogAction(admin, target, "[EmergencyRescue] %s", stamped);

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof path, LOG_PATH);

	File file = OpenFile(path, "a");
	if (file == null)
		return;

	char timeStamp[32];
	FormatTime(timeStamp, sizeof timeStamp, "%Y-%m-%d %H:%M:%S");
	file.WriteLine("%s: %s", timeStamp, stamped);
	delete file;
}
