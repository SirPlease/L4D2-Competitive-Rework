#if defined _readyup_setup_included
 #endinput
#endif
#define _readyup_setup_included

#include "sound.inc" // Default sound samples

#define TRANSLATION_READYUP "readyup.phrases"

void LoadTranslation()
{
	char sPath[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "translations/" ... TRANSLATION_READYUP ... ".txt");
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file \"" ... TRANSLATION_READYUP ... ".txt\"");
	}
	LoadTranslations(TRANSLATION_READYUP);
}

void SetupNatives()
{
	CreateNative("AddStringToReadyFooter",	Native_AddStringToReadyFooter);
	CreateNative("EditFooterStringAtIndex", Native_EditFooterStringAtIndex);
	CreateNative("FindIndexOfFooterString", Native_FindIndexOfFooterString);
	CreateNative("GetFooterStringAtIndex",	Native_GetFooterStringAtIndex);
	CreateNative("IsInReady",				Native_IsInReady);
	CreateNative("ToggleReadyPanel",		Native_ToggleReadyPanel);
}

void SetupForwards()
{
	g_hPreInitiateForward = new GlobalForward("OnReadyUpInitiatePre", ET_Ignore);
	g_hInitiateForward = new GlobalForward("OnReadyUpInitiate", ET_Ignore);
	g_hPreCountdownForward = new GlobalForward("OnRoundLiveCountdownPre", ET_Ignore);
	g_hCountdownForward = new GlobalForward("OnRoundLiveCountdown", ET_Ignore);
	g_hPreLiveForward = new GlobalForward("OnRoundIsLivePre", ET_Ignore);
	g_hLiveForward = new GlobalForward("OnRoundIsLive", ET_Ignore);
	g_hCountdownCancelledForward = new GlobalForward("OnReadyCountdownCancelled", ET_Ignore, Param_Cell, Param_String);
	g_hPlayerReadyForward = new GlobalForward("OnPlayerReady", ET_Ignore, Param_Cell);
	g_hPlayerUnreadyForward = new GlobalForward("OnPlayerUnready", ET_Ignore, Param_Cell);
}

void SetupConVars()
{
	// basic
	l4d_ready_enabled			= CreateConVar("l4d_ready_enabled", "1", "Enable this plugin. (Values: 0 = Disabled, 1 = Manual ready, 2 = Auto start, 3 = Team ready)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	l4d_ready_cfg_name			= CreateConVar("l4d_ready_cfg_name", "", "Configname to display on the ready-up panel", FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);
	l4d_ready_server_cvar		= CreateConVar("l4d_ready_server_cvar", "sn_main_name", "ConVar to retrieve the server name for displaying on the ready-up panel", FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);
	l4d_ready_max_players		= CreateConVar("l4d_ready_max_players", "12", "Maximum number of players to show on the ready-up panel.", FCVAR_NOTIFY, true, 0.0, true, MAXPLAYERS+1.0);
	
	// game
	l4d_ready_disable_spawns	= CreateConVar("l4d_ready_disable_spawns", "0", "Prevent SI from having spawns during ready-up", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	l4d_ready_survivor_freeze	= CreateConVar("l4d_ready_survivor_freeze", "1", "Freeze the survivors during ready-up.  When unfrozen they are unable to leave the saferoom but can move freely inside", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	// sound
	l4d_ready_enable_sound		= CreateConVar("l4d_ready_enable_sound", "1", "Enable sounds played to clients", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	l4d_ready_notify_sound		= CreateConVar("l4d_ready_notify_sound", DEFAULT_NOTIFY_SOUND, "The sound that plays when a round goes on countdown");	
	l4d_ready_countdown_sound	= CreateConVar("l4d_ready_countdown_sound", DEFAULT_COUNTDOWN_SOUND, "The sound that plays when a round goes on countdown");	
	l4d_ready_live_sound		= CreateConVar("l4d_ready_live_sound", DEFAULT_LIVE_SOUND, "The sound that plays when a round goes live");
	l4d_ready_autostart_sound	= CreateConVar("l4d_ready_autostart_sound", DEFAULT_AUTOSTART_SOUND, "The sound that plays when auto-start goes on countdown");
	l4d_ready_chuckle			= CreateConVar("l4d_ready_chuckle", "0", "Enable random moustachio chuckle during countdown");
	l4d_ready_secret			= CreateConVar("l4d_ready_secret", "1", "Play something good", _, true, 0.0, true, 1.0);
	
	// action
	l4d_ready_delay				= CreateConVar("l4d_ready_delay", "3", "Number of seconds to count down before the round goes live.", FCVAR_NOTIFY, true, 0.0);
	l4d_ready_force_extra		= CreateConVar("l4d_ready_force_extra", "2", "Number of seconds added to the duration of live count down.", FCVAR_NOTIFY, true, 0.0);
	l4d_ready_autostart_delay	= CreateConVar("l4d_ready_autostart_delay", "5", "Number of seconds to count down before auto-start kicks in.", FCVAR_NOTIFY, true, 0.0);
	l4d_ready_autostart_wait	= CreateConVar("l4d_ready_autostart_wait", "20", "Number of seconds to wait for connecting players before auto-start is forced.", FCVAR_NOTIFY, true, 0.0);
	l4d_ready_autostart_min		= CreateConVar("l4d_ready_autostart_min", "0.25", "Percent of max players (Versus = 8) in game to allow auto-start to proceed.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	l4d_ready_unbalanced_start	= CreateConVar("l4d_ready_unbalanced_start", "0", "Allow game to go live when teams are not full.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	l4d_ready_unbalanced_min	= CreateConVar("l4d_ready_unbalanced_min", "2", "Minimum of players in each team to allow a unbalanced start.", FCVAR_NOTIFY, true, 0.0);
	
	// game convars
	director_no_specials = FindConVar("director_no_specials");
	god = FindConVar("god");
	sb_stop = FindConVar("sb_stop");
	survivor_limit = FindConVar("survivor_limit");
	z_max_player_zombies = FindConVar("z_max_player_zombies");
	sv_infinite_primary_ammo = FindConVar("sv_infinite_primary_ammo");
}

void SetupCommands()
{
	// Ready Commands
	RegConsoleCmd("sm_ready",			Ready_Cmd, "Mark yourself as ready for the round to go live");
	RegConsoleCmd("sm_r",				Ready_Cmd, "Mark yourself as ready for the round to go live");
	RegConsoleCmd("sm_toggleready",		ToggleReady_Cmd, "Toggle your ready status");
	RegConsoleCmd("sm_unready",			Unready_Cmd, "Mark yourself as not ready if you have set yourself as ready");
	RegConsoleCmd("sm_nr",				Unready_Cmd, "Mark yourself as not ready if you have set yourself as ready");
	
	// Admin Commands
	RegAdminCmd("sm_forcestart",		ForceStart_Cmd, ADMFLAG_BAN, "Forces the round to start regardless of player ready status.");
	RegAdminCmd("sm_fs",				ForceStart_Cmd, ADMFLAG_BAN, "Forces the round to start regardless of player ready status.");

	// Player Commands
	RegConsoleCmd("sm_hide",			Hide_Cmd, "Hides the ready-up panel so other menus can be seen");
	RegConsoleCmd("sm_show",			Show_Cmd, "Shows a hidden ready-up panel");
	RegConsoleCmd("sm_return",			Return_Cmd, "Return to a valid saferoom spawn if you get stuck during an unfrozen ready-up period");
}