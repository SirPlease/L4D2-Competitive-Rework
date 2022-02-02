#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <builtinvotes>
#include <colors>
#undef REQUIRE_PLUGIN
#include <caster_system>

#define PLUGIN_VERSION "9.3.11a"

public Plugin myinfo =
{
	name = "L4D2 Ready-Up with convenience fixes",
	author = "CanadaRox, Target",
	description = "New and improved ready-up plugin with optimal for convenience.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

// ========================
//  Defines
// ========================
#define NULL_VELOCITY view_as<float>({0.0, 0.0, 0.0})

#define L4D2Team_None		0
#define L4D2Team_Spectator	1
#define L4D2Team_Survivor	2
#define L4D2Team_Infected	3

#define MAX_FOOTERS 10
#define MAX_FOOTER_LEN 65
#define MAX_SOUNDS 5

#define SECRET_SOUND "/level/gnomeftw.wav"
#define DEFAULT_COUNTDOWN_SOUND "weapons/hegrenade/beep.wav"
#define DEFAULT_LIVE_SOUND "ui/survival_medal.wav"
#define DEFAULT_AUTOSTART_SOUND "ui/buttonrollover.wav"

#define TRANSLATION_READYUP "readyup.phrases"

#define READY_MODE_MANUAL 1
#define READY_MODE_AUTOSTART 2

#define AFK_DURATION 15.0

#define DEBUG 0

enum
{
	WL_NotInWater = 0,
	WL_Feet,
	WL_Waist,
	WL_Eyes
};

// ========================
//  Plugin Variables
// ========================
// Game Cvars
ConVar
	director_no_specials,
	god,
	sb_stop,
	survivor_limit,
	z_max_player_zombies,
	sv_infinite_primary_ammo;

// Plugin Cvars
ConVar
	l4d_ready_enabled,
	l4d_ready_disable_spawns, l4d_ready_survivor_freeze,
	l4d_ready_cfg_name, l4d_ready_server_cvar, 
	l4d_ready_max_players,
	l4d_ready_delay, l4d_ready_force_extra, l4d_ready_autostart_delay, l4d_ready_autostart_wait,
	l4d_ready_enable_sound, l4d_ready_chuckle, l4d_ready_countdown_sound, l4d_ready_live_sound, l4d_ready_autostart_sound,
	l4d_ready_secret,
	l4d_ready_unbalanced_start,
	l4d_ready_unbalanced_min;

// Server Name
ConVar ServerNamer;

// Ready Panel
bool
	hiddenPanel[MAXPLAYERS+1];
char
	sCmd[32],
	readyFooter[MAX_FOOTERS][MAX_FOOTER_LEN];
int
	iCmd,
	footerCounter;
float
	fStartTimestamp;
	
// Standard Ready Up
bool
	inLiveCountdown,
	inReadyUp,
	isForceStart,
	readySurvFreeze,
	isPlayerReady[MAXPLAYERS+1];
Handle
	readyCountdownTimer;
char
	countdownSound[PLATFORM_MAX_PATH],
	liveSound[PLATFORM_MAX_PATH];
int
	readyDelay;

// Auto Start
bool
	isAutoStartMode,
	inAutoStart;
Handle
	autoStartTimer;
char
	autoStartSound[PLATFORM_MAX_PATH];
int
	autoStartDelay,
	expireTime;

// Forwards
Handle
	preInitiateForward,
	initiateForward,
	preCountdownForward,
	countdownForward,
	preLiveForward,
	liveForward;

//AFK?!
float g_fButtonTime[MAXPLAYERS+1];

// Spectate Fix
Handle g_hChangeTeamTimer[MAXPLAYERS+1];

// :D
Handle blockSecretSpam[MAXPLAYERS+1];

// Caster System
bool casterSystemAvailable;

// Delayed initiation
bool g_bTransitioning = false;

// Reason enum for Countdown cancelling
enum disruptType
{
	readyStatus,
	teamShuffle,
	playerDisconn,
	forceStartAbort
};

static const char chuckleSound[MAX_SOUNDS][] =
{
	"/npc/moustachio/strengthattract01.wav",
	"/npc/moustachio/strengthattract02.wav",
	"/npc/moustachio/strengthattract05.wav",
	"/npc/moustachio/strengthattract06.wav",
	"/npc/moustachio/strengthattract09.wav"
};


// ========================
//  Plugin Setup
// ========================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("AddStringToReadyFooter",	Native_AddStringToReadyFooter);
	CreateNative("EditFooterStringAtIndex", Native_EditFooterStringAtIndex);
	CreateNative("FindIndexOfFooterString", Native_FindIndexOfFooterString);
	CreateNative("GetFooterStringAtIndex",	Native_GetFooterStringAtIndex);
	CreateNative("IsInReady",				Native_IsInReady);
	CreateNative("ToggleReadyPanel",		Native_ToggleReadyPanel);
	
	preInitiateForward = CreateGlobalForward("OnReadyUpInitiatePre", ET_Ignore);
	initiateForward = CreateGlobalForward("OnReadyUpInitiate", ET_Ignore);
	preCountdownForward = CreateGlobalForward("OnRoundLiveCountdownPre", ET_Ignore);
	countdownForward = CreateGlobalForward("OnRoundLiveCountdown", ET_Ignore);
	preLiveForward = CreateGlobalForward("OnRoundIsLivePre", ET_Ignore);
	liveForward = CreateGlobalForward("OnRoundIsLive", ET_Ignore);
	RegPluginLibrary("readyup");
	return APLRes_Success;
}

public void OnPluginStart()
{
	l4d_ready_enabled			= CreateConVar("l4d_ready_enabled", "1", "Enable this plugin. (Values: 0 = Disabled, 1 = Manual ready, 2 = Auto start)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	l4d_ready_cfg_name			= CreateConVar("l4d_ready_cfg_name", "", "Configname to display on the ready-up panel", FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);
	l4d_ready_server_cvar		= CreateConVar("l4d_ready_server_cvar", "sn_main_name", "ConVar to retrieve the server name for displaying on the ready-up panel", FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);
	l4d_ready_disable_spawns	= CreateConVar("l4d_ready_disable_spawns", "0", "Prevent SI from having spawns during ready-up", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	l4d_ready_survivor_freeze	= CreateConVar("l4d_ready_survivor_freeze", "1", "Freeze the survivors during ready-up.  When unfrozen they are unable to leave the saferoom but can move freely inside", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	l4d_ready_max_players		= CreateConVar("l4d_ready_max_players", "12", "Maximum number of players to show on the ready-up panel.", FCVAR_NOTIFY, true, 0.0, true, MAXPLAYERS+1.0);
	l4d_ready_delay				= CreateConVar("l4d_ready_delay", "3", "Number of seconds to count down before the round goes live.", FCVAR_NOTIFY, true, 0.0);
	l4d_ready_force_extra		= CreateConVar("l4d_ready_force_extra", "2", "Number of seconds added to the duration of live count down.", FCVAR_NOTIFY, true, 0.0);
	l4d_ready_autostart_delay	= CreateConVar("l4d_ready_autostart_delay", "5", "Number of seconds to count down before auto-start kicks in.", FCVAR_NOTIFY, true, 0.0);
	l4d_ready_autostart_wait	= CreateConVar("l4d_ready_autostart_wait", "20", "Number of seconds to wait for connecting players before auto-start is forced.", FCVAR_NOTIFY, true, 0.0);
	l4d_ready_enable_sound		= CreateConVar("l4d_ready_enable_sound", "1", "Enable sound during autostart & countdown & on live", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	l4d_ready_countdown_sound	= CreateConVar("l4d_ready_countdown_sound", DEFAULT_COUNTDOWN_SOUND, "The sound that plays when a round goes on countdown");	
	l4d_ready_live_sound		= CreateConVar("l4d_ready_live_sound", DEFAULT_LIVE_SOUND, "The sound that plays when a round goes live");
	l4d_ready_autostart_sound	= CreateConVar("l4d_ready_autostart_sound", DEFAULT_AUTOSTART_SOUND, "The sound that plays when auto-start goes on countdown");
	l4d_ready_chuckle			= CreateConVar("l4d_ready_chuckle", "0", "Enable random moustachio chuckle during countdown");
	l4d_ready_secret			= CreateConVar("l4d_ready_secret", "1", "Play something good", _, true, 0.0, true, 1.0);
	l4d_ready_unbalanced_start	= CreateConVar("l4d_ready_unbalanced_start", "0", "Allow game to go live when teams are not full.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	l4d_ready_unbalanced_min	= CreateConVar("l4d_ready_unbalanced_min", "2", "Minimum of players in each team to allow a unbalanced start.", FCVAR_NOTIFY, true, 0.0);
	
	director_no_specials = FindConVar("director_no_specials");
	god = FindConVar("god");
	sb_stop = FindConVar("sb_stop");
	survivor_limit = FindConVar("survivor_limit");
	z_max_player_zombies = FindConVar("z_max_player_zombies");
	sv_infinite_primary_ammo = FindConVar("sv_infinite_primary_ammo");

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
	
#if DEBUG
	RegAdminCmd("sm_initready", InitReady_Cmd, ADMFLAG_ROOT);
	RegAdminCmd("sm_initlive", InitLive_Cmd, ADMFLAG_ROOT);
#endif

	LoadTranslation();

	HookEvent("round_start", RoundStart_Event, EventHookMode_Pre);
	HookEvent("player_team", PlayerTeam_Event, EventHookMode_Post);
	HookEvent("gameinstructor_draw", GameInstructorDraw_Event, EventHookMode_PostNoCopy);

	readySurvFreeze = l4d_ready_survivor_freeze.BoolValue;
	l4d_ready_survivor_freeze.AddChangeHook(SurvFreezeChanged);
	
	l4d_ready_server_cvar.AddChangeHook(ServerCvarChanged);
}

public void OnPluginEnd()
{
	InitiateLive(false);
}

public void OnAllPluginsLoaded()
{
	FillServerNamer();
	FindCasterSystem();
}

public void OnLibraryRemoved(const char[] name)
{
	FindCasterSystem();
}

void LoadTranslation()
{
	char sPath[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, sPath, sizeof sPath, "translations/" ... TRANSLATION_READYUP ... ".txt");
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file \"" ... TRANSLATION_READYUP ... ".txt\"");
	}
	LoadTranslations(TRANSLATION_READYUP);
}

void FillServerNamer()
{
	char buffer[64];
	l4d_ready_server_cvar.GetString(buffer, sizeof buffer);
	if ((ServerNamer = FindConVar(buffer)) == null)
		ServerNamer = FindConVar("hostname");
}

void FindCasterSystem()
{
	casterSystemAvailable = LibraryExists("caster_system");
}



// ========================
//  ConVar Change
// ========================

public void SurvFreezeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	readySurvFreeze = convar.BoolValue;
	
	if (inReadyUp)
	{
		ReturnTeamToSaferoom(L4D2Team_Survivor);
		SetTeamFrozen(L4D2Team_Survivor, readySurvFreeze);
	}
}

public void ServerCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	FillServerNamer();
}



// ========================
//  Events
// ========================

public void OnConfigsExecuted()
{
	if (g_bTransitioning) InitiateReadyUp();
}

public void RoundStart_Event(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bTransitioning) InitiateReadyUp();
}

public void GameInstructorDraw_Event(Event event, const char[] name, bool dontBroadcast)
{
	// First map intro ended, absolutely after all players' being loaded in game
	g_bTransitioning = false;
	
	// Workaround for restarting countdown after scavenge intro
	CreateTimer(0.1, Timer_RestartCountdowns, false, TIMER_FLAG_NO_MAPCHANGE);
}

public void PlayerTeam_Event(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if (!client || IsFakeClient(client))
		return;
	
	isPlayerReady[client] = false;
	SetEngineTime(client);
	
	if (!inReadyUp) return;
	
	if (isAutoStartMode || isForceStart)
		return;
	
	int team = event.GetInt("team");
	int oldteam = event.GetInt("oldteam");
	
	if (team == L4D2Team_None && oldteam != L4D2Team_Spectator) // Player disconnecting
	{
		CancelFullReady(client, playerDisconn);
	}
	
	else if (!g_hChangeTeamTimer[client]) // Player in-game swapping team
	{
		DataPack dp;
		g_hChangeTeamTimer[client] = CreateDataTimer(0.1, Timer_PlayerTeam, dp);
		dp.WriteCell(client);
		dp.WriteCell(userid);
		dp.WriteCell(oldteam);
	}
}

public Action Timer_PlayerTeam(Handle timer, DataPack dp)
{
	dp.Reset();
	
	int client = dp.ReadCell();
	int userid = dp.ReadCell();
	int oldteam = dp.ReadCell();
	
	if (client == GetClientOfUserId(userid))
	{
		if (inLiveCountdown)
		{
			int team = GetClientTeam(client);
			if (team != oldteam)
			{
				if (oldteam != L4D2Team_None || team != L4D2Team_Spectator)
				{
					CancelFullReady(client, teamShuffle);
				}
			}
		}
	}
	
	g_hChangeTeamTimer[client] = null;

	return Plugin_Stop;
}

// ========================
//  Forwards
// ========================

public void OnMapStart()
{
	/* OnMapEnd needs this to work */
	char szPath[PLATFORM_MAX_PATH];
	
	l4d_ready_countdown_sound.GetString(countdownSound, sizeof(countdownSound));
	l4d_ready_live_sound.GetString(liveSound, sizeof(liveSound));
	l4d_ready_autostart_sound.GetString(autoStartSound, sizeof(autoStartSound));
	
	Format(szPath, sizeof(szPath), "sound/%s", countdownSound);
	if (!FileExists(szPath, true)) {
		strcopy(countdownSound, sizeof(countdownSound), DEFAULT_COUNTDOWN_SOUND);
	}
	
	Format(szPath, sizeof(szPath), "sound/%s", liveSound);
	if (!FileExists(szPath, true)) {
		strcopy(liveSound, sizeof(liveSound), DEFAULT_LIVE_SOUND);
	}
	
	Format(szPath, sizeof(szPath), "sound/%s", autoStartSound);
	if (!FileExists(szPath, true)) {
		strcopy(autoStartSound, sizeof(autoStartSound), DEFAULT_AUTOSTART_SOUND);
	}
	
	PrecacheSound(SECRET_SOUND);
	PrecacheSound(countdownSound);
	PrecacheSound(liveSound);
	PrecacheSound(autoStartSound);
	for (int i = 0; i < MAX_SOUNDS; i++)
	{
		PrecacheSound(chuckleSound[i]);
	}
	for (int client = 1; client <= MAXPLAYERS; client++)
	{
		blockSecretSpam[client] = null;
		g_hChangeTeamTimer[client] = null;
	}
	readyCountdownTimer = null;
}

/* This ensures all cvars are reset if the map is changed during ready-up */
public void OnMapEnd()
{
	if (inReadyUp)
	{
		if (inAutoStart) InitiateAutoStart(false);
		InitiateLive(false);
	}
	g_bTransitioning = true;
}

public void OnClientPostAdminCheck(int client)
{
	if (inReadyUp && IsScavenge() && !IsFakeClient(client))
	{
		ToggleCountdownPanel(false, client);
	}
}

public void OnClientDisconnect(int client)
{
	hiddenPanel[client] = false;
	isPlayerReady[client] = false;
	g_fButtonTime[client] = 0.0;
	g_hChangeTeamTimer[client] = null;
}

/* No need to do any other checks since it seems like this is required no matter what since the intros unfreezes players after the animation completes */
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (inReadyUp && IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			static int iLastMouse[MAXPLAYERS+1][2];
			
			// Mouse Movement Check
			if (mouse[0] != iLastMouse[client][0] || mouse[1] != iLastMouse[client][1])
			{
				iLastMouse[client][0] = mouse[0];
				iLastMouse[client][1] = mouse[1];
				SetEngineTime(client);
			}
			else if (buttons || impulse) SetEngineTime(client);
		}
		
		if (GetClientTeam(client) == L4D2Team_Survivor)
		{
			if (readySurvFreeze || inLiveCountdown)
			{
				MoveType iMoveType = GetEntityMoveType(client);
				if (iMoveType != MOVETYPE_NONE && iMoveType != MOVETYPE_NOCLIP)
				{
					SetClientFrozen(client, true);
				}
			}
			else
			{
				if (GetEntProp(client, Prop_Send, "m_nWaterLevel") == WL_Eyes)
				{
					ReturnPlayerToSaferoom(client, false);
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if (inReadyUp)
	{
		// Mob timer is set after survivor leaving saferoom
		CreateTimer(0.3, Timer_RestartMob, _, TIMER_FLAG_NO_MAPCHANGE);
		ReturnPlayerToSaferoom(client, false);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Timer_RestartMob(Handle timer)
{
	if (inReadyUp) RestartMobCountdown(false);

	return Plugin_Stop;
}



// ========================
//  Command Listener
// ========================

public Action Say_Callback(int client, const char[] command, int argc)
{
	SetEngineTime(client);

	return Plugin_Continue;
}

public Action Vote_Callback(int client, const char[] command, int argc)
{
	// Fast ready / unready through default keybinds for voting
	if (!client) return Plugin_Continue;
	if (BuiltinVote_IsVoteInProgress() && IsClientInBuiltinVotePool(client)) return Plugin_Continue;
	
	if (Game_IsVoteInProgress())
	{
		int voteteam = Game_GetVoteTeam();
		if (voteteam == -1 || voteteam == GetClientTeam(client))
		{
			return Plugin_Continue;
		}
	}
	
	char sArg[8];
	GetCmdArg(1, sArg, sizeof(sArg));
	if (strcmp(sArg, "Yes", false) == 0)
		Ready_Cmd(client, 0);
	else if (strcmp(sArg, "No", false) == 0)
		Unready_Cmd(client, 0);

	return Plugin_Continue;
}



// ========================
//  Ready Commands
// ========================

public Action Ready_Cmd(int client, int args)
{
	if (inReadyUp && IsPlayer(client))
	{
		isPlayerReady[client] = true;
		if (l4d_ready_secret.BoolValue)
			DoSecrets(client);
		if (!inAutoStart && CheckFullReady())
			InitiateLiveCountdown();
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Unready_Cmd(int client, int args)
{
	if (inReadyUp && !isAutoStartMode)
	{
		AdminId id = GetUserAdmin(client);
		bool hasflag = (id != INVALID_ADMIN_ID && GetAdminFlag(id, Admin_Ban)); // Check for specific admin flag
		
		if (isForceStart)
		{
			if (!hasflag) return Plugin_Handled;
			CancelFullReady(client, forceStartAbort);
			isForceStart = false;
		}
		else
		{
			if (IsPlayer(client))
			{
				SetEngineTime(client);
				isPlayerReady[client] = false;
			}
			else if (!hasflag)
			{
				return Plugin_Handled;
			}
			CancelFullReady(client, readyStatus);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action ToggleReady_Cmd(int client, int args)
{
	if (inReadyUp)
	{
		return isPlayerReady[client] ? Unready_Cmd(client, 0) : Ready_Cmd(client, 0);
	}
	return Plugin_Continue;
}



// ========================
//  Admin Commands
// ========================

public Action ForceStart_Cmd(int client, int args)
{
	if (inReadyUp && !isAutoStartMode)
	{		
		// Check if admin always allowed to do so
		AdminId id = GetUserAdmin(client);
		if (id != INVALID_ADMIN_ID && GetAdminFlag(id, Admin_Ban)) // Check for specific admin flag
		{
			isForceStart = true;
			InitiateLiveCountdown();
			CPrintToChatAll("%t", "ForceStartAdmin", client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}



// ========================
//  Player Commands
// ========================

public Action Hide_Cmd(int client, int args)
{
	if (inReadyUp)
	{
		hiddenPanel[client] = true;
		CPrintToChat(client, "%t", "PanelHide");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Show_Cmd(int client, int args)
{
	if (inReadyUp)
	{
		hiddenPanel[client] = false;
		CPrintToChat(client, "%t", "PanelShow");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}



public Action Return_Cmd(int client, int args)
{
	if (inReadyUp
			&& client > 0
			&& GetClientTeam(client) == L4D2Team_Survivor)
	{
		ReturnPlayerToSaferoom(client, false);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}



#if DEBUG
public Action InitReady_Cmd(int client, int args)
{
	InitiateReadyUp();
	return Plugin_Handled;
}

public Action InitLive_Cmd(int client, int args)
{
	InitiateLive();
	return Plugin_Handled;
}
#endif



// ========================
//  Readyup Stuff
// ========================

void ToggleCommandListeners(bool hook)
{
	static bool hooked = false;
	if (hooked && !hook)
	{
		RemoveCommandListener(Say_Callback, "say");
		RemoveCommandListener(Say_Callback, "say_team");
		RemoveCommandListener(Vote_Callback, "Vote");
		hooked = false;
	}
	else if (!hooked && hook)
	{
		AddCommandListener(Say_Callback, "say");
		AddCommandListener(Say_Callback, "say_team");
		AddCommandListener(Vote_Callback, "Vote");
		hooked = true;
	}
}

public int DummyHandler(Handle menu, MenuAction action, int param1, int param2) { return 1; }

public Action MenuRefresh_Timer(Handle timer)
{
	if (inReadyUp)
	{
		UpdatePanel();
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public Action MenuCmd_Timer(Handle timer)
{
	if (inReadyUp)
	{
		iCmd > 9 ? (iCmd = 1) : (iCmd += 1);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

void PrintCmd()
{
	switch (iCmd)
	{
		case 1: FormatEx(sCmd, sizeof(sCmd), "->1. !ready|!r / !unready|!nr");
		case 2: FormatEx(sCmd, sizeof(sCmd), "->2. !slots #");
		case 3: FormatEx(sCmd, sizeof(sCmd), "->3. !voteboss <tank> <witch>");
		case 4: FormatEx(sCmd, sizeof(sCmd), "->4. !match / !rmatch");
		case 5: FormatEx(sCmd, sizeof(sCmd), "->5. !show / !hide");
		case 6: FormatEx(sCmd, sizeof(sCmd), "->6. !setscores <survs> <inf>");
		case 7: FormatEx(sCmd, sizeof(sCmd), "->7. !lerps");
		case 8: FormatEx(sCmd, sizeof(sCmd), "->8. !secondary");
		case 9: FormatEx(sCmd, sizeof(sCmd), "->9. !forcestart / !fs");
	}
}

void UpdatePanel()
{
	char survivorBuffer[800] = "";
	char infectedBuffer[800] = "";
	char casterBuffer[600] = "";
	char specBuffer[400] = "";
	int playerCount = 0;
	int casterCount = 0;
	int specCount = 0;

	Panel menuPanel = new Panel();

	char ServerBuffer[128];
	char ServerName[32];
	char cfgName[32];
	PrintCmd();

	int iPassTime = RoundToFloor(GetGameTime() - fStartTimestamp);

	ServerNamer.GetString(ServerName, sizeof(ServerName));
	
	l4d_ready_cfg_name.GetString(cfgName, sizeof(cfgName));
	Format(ServerBuffer, sizeof(ServerBuffer), "▸ Server: %s \n▸ Slots: %d/%d\n▸ Config: %s", ServerName, GetSeriousClientCount(), FindConVar("sv_maxplayers").IntValue, cfgName);
	menuPanel.DrawText(ServerBuffer);
	
	FormatTime(ServerBuffer, sizeof(ServerBuffer), "▸ %m/%d/%Y - %I:%M%p");
	Format(ServerBuffer, sizeof(ServerBuffer), "%s (%02d:%02d)", ServerBuffer, iPassTime / 60, iPassTime % 60);
	menuPanel.DrawText(ServerBuffer);
	
	menuPanel.DrawText(" ");
	menuPanel.DrawText("▸ Commands:");
	menuPanel.DrawText(sCmd);
	menuPanel.DrawText(" ");
	
	char nameBuf[64];
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			++playerCount;
			GetClientFixedName(client, nameBuf, sizeof(nameBuf));
			
			if (IsPlayer(client))
			{
				if (isPlayerReady[client])
				{
					if (!inLiveCountdown && !isAutoStartMode) PrintHintText(client, "%t", "HintReady");
					Format(nameBuf, sizeof(nameBuf), isAutoStartMode ? "%s\n" : "☑ %s\n", nameBuf);
					GetClientTeam(client) == L4D2Team_Survivor ? StrCat(survivorBuffer, sizeof(survivorBuffer), nameBuf) : StrCat(infectedBuffer, sizeof(infectedBuffer), nameBuf);
				}
				else 
				{
					if (!inLiveCountdown && !isAutoStartMode) PrintHintText(client, "%t", "HintUnready");
					Format(nameBuf, sizeof(nameBuf), isAutoStartMode ? "%s\n" : "☐ %s%s\n", nameBuf, ( IsPlayerAfk(client) ? " [AFK]" : "" ));
					GetClientTeam(client) == L4D2Team_Survivor ? StrCat(survivorBuffer, sizeof(survivorBuffer), nameBuf) : StrCat(infectedBuffer, sizeof(infectedBuffer), nameBuf);
				}
			}
			else
			{
				++specCount;
				if (casterSystemAvailable && IsClientCaster(client))
				{
					++casterCount;
					Format(nameBuf, sizeof(nameBuf), "%s\n", nameBuf);
					StrCat(casterBuffer, sizeof(casterBuffer), nameBuf);
				}
				else
				{
					if (playerCount <= l4d_ready_max_players.IntValue)
					{
						Format(nameBuf, sizeof(nameBuf), "%s\n", nameBuf);
						StrCat(specBuffer, sizeof(specBuffer), nameBuf);
					}
				}
			}
		}
	}
	
	int textCount = 0;
	int bufLen = strlen(survivorBuffer);
	if (bufLen != 0)
	{
		survivorBuffer[bufLen] = '\0';
		ReplaceString(survivorBuffer, sizeof(survivorBuffer), "#", "_");
		Format(nameBuf, sizeof(nameBuf), "->%d. Survivors", ++textCount);
		menuPanel.DrawText(nameBuf);
		menuPanel.DrawText(survivorBuffer);
	}

	bufLen = strlen(infectedBuffer);
	if (bufLen != 0)
	{
		infectedBuffer[bufLen] = '\0';
		ReplaceString(infectedBuffer, sizeof(infectedBuffer), "#", "_");
		Format(nameBuf, sizeof(nameBuf), "->%d. Infected", ++textCount);
		menuPanel.DrawText(nameBuf);
		menuPanel.DrawText(infectedBuffer);
	}
	
	if (specCount && textCount) menuPanel.DrawText(" ");

	if (casterSystemAvailable)
	{
		bufLen = strlen(casterBuffer);
		if (bufLen != 0)
		{
			casterBuffer[bufLen] = '\0';
			Format(nameBuf, sizeof(nameBuf), "->%d. Caster%s", ++textCount, casterCount > 1 ? "s" : "");
			menuPanel.DrawText(nameBuf);
			ReplaceString(casterBuffer, sizeof(casterBuffer), "#", "_", true);
			menuPanel.DrawText(casterBuffer);
		}
	}
	
	bufLen = strlen(specBuffer);
	if (bufLen != 0)
	{
		specBuffer[bufLen] = '\0';
		Format(nameBuf, sizeof(nameBuf), "->%d. Spectator%s", ++textCount, specCount > 1 ? "s" : "");
		menuPanel.DrawText(nameBuf);
		ReplaceString(specBuffer, sizeof(specBuffer), "#", "_");
		if (playerCount > l4d_ready_max_players.IntValue && specCount - casterCount > 1)
			FormatEx(specBuffer, sizeof(specBuffer), "**Many** (%d)", specCount - casterCount);
		menuPanel.DrawText(specBuffer);
	}

	bufLen = strlen(readyFooter[0]);
	if (bufLen != 0)
	{
		menuPanel.DrawText(" ");
		for (int i = 0; i < footerCounter; i++)
		{
			menuPanel.DrawText(readyFooter[i]);
		}
	}

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && !hiddenPanel[client]) 
		{
			if (BuiltinVote_IsVoteInProgress() && IsClientInBuiltinVotePool(client))
			{
				continue;
			}
			
			if (Game_IsVoteInProgress())
			{
				int voteteam = Game_GetVoteTeam();
				if (voteteam == -1 || voteteam == GetClientTeam(client))
				{
					continue;
				}
			}
			
			switch (GetClientMenu(client))
			{
				case MenuSource_External, MenuSource_Normal: continue;
			}
			
			menuPanel.Send(client, DummyHandler, 1);
		}
	}
	
	delete menuPanel;
}

void InitiateReadyUp()
{
	if (!l4d_ready_enabled.BoolValue) return;
	
	Call_StartForward(preInitiateForward);
	Call_Finish();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		isPlayerReady[i] = false;
	}

	UpdatePanel();
	CreateTimer(1.0, MenuRefresh_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(4.0, MenuCmd_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	inReadyUp = true;
	inLiveCountdown = false;
	isForceStart = false;
	readyCountdownTimer = null;
	
	fStartTimestamp = GetGameTime();
	
	isAutoStartMode = (l4d_ready_enabled.IntValue == READY_MODE_AUTOSTART);

	if (l4d_ready_disable_spawns.BoolValue)
	{
		director_no_specials.SetBool(true);
	}

	sv_infinite_primary_ammo.Flags &= ~FCVAR_NOTIFY;
	sv_infinite_primary_ammo.SetBool(true);
	sv_infinite_primary_ammo.Flags |= FCVAR_NOTIFY;
	god.Flags &= ~FCVAR_NOTIFY;
	god.SetBool(true);
	god.Flags |= FCVAR_NOTIFY;
	sb_stop.SetBool(true);

	for (int i = 0; i < MAX_FOOTERS; i++)
	{
		readyFooter[i][0] = '\0';
	}
	footerCounter = 0;
	
	CreateTimer(0.3, Timer_RestartCountdowns, false, TIMER_FLAG_NO_MAPCHANGE);
		
	ToggleCommandListeners(true);
	
	if (isAutoStartMode)
	{
		expireTime = l4d_ready_autostart_wait.IntValue;
		CreateTimer(1.0, Timer_AutoStartHelper, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
	
	Call_StartForward(initiateForward);
	Call_Finish();
}

void InitiateLive(bool real = true)
{
	if (real)
	{
		Call_StartForward(preLiveForward);
		Call_Finish();
	}
	
	inReadyUp = false;
	inLiveCountdown = false;
	isForceStart = false;

	SetTeamFrozen(L4D2Team_Survivor, false);

	sv_infinite_primary_ammo.Flags &= ~FCVAR_NOTIFY;
	sv_infinite_primary_ammo.SetBool(false);
	sv_infinite_primary_ammo.Flags |= FCVAR_NOTIFY;
	director_no_specials.SetBool(false);
	god.Flags &= ~FCVAR_NOTIFY;
	god.SetBool(false);
	god.Flags |= FCVAR_NOTIFY;
	sb_stop.SetBool(false);
	
	ToggleCommandListeners(false);

	if (real)
	{
		CreateTimer(0.1, Timer_RestartCountdowns, true, TIMER_FLAG_NO_MAPCHANGE);
		ClearSurvivorProgress();
		
		Call_StartForward(liveForward);
		Call_Finish();
	}
	else
	{
		readyCountdownTimer = null;
	}
}

public Action Timer_AutoStartHelper(Handle timer)
{
	if (g_bTransitioning || GetSeriousClientCount(true) == 0)
	{
		// no player in game
		expireTime = l4d_ready_autostart_wait.IntValue;
		return Plugin_Continue;
	}
	
	if (IsAnyPlayerLoading())
	{
		if (expireTime > 0)
		{
			expireTime--;
			PrintHintTextToAll("%t", "AutoStartWaiting");
			return Plugin_Continue;
		}
	}
	
	CreateTimer(8.0, Timer_InitiateAutoStart, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

public Action Timer_InitiateAutoStart(Handle timer)
{
	InitiateAutoStart();

	return Plugin_Stop;
}

void InitiateAutoStart(bool real = true)
{
	if (!real)
	{
		inAutoStart = false;
		autoStartTimer = null;
		return;
	}
	
	if (autoStartTimer == null)
	{
		PrintHintTextToAll("%t", "InitiateAutoStart");
		inAutoStart = true;
		autoStartDelay = l4d_ready_autostart_delay.IntValue;
		autoStartTimer = CreateTimer(1.0, AutoStartDelay_Timer, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
}

public Action AutoStartDelay_Timer(Handle timer)
{
	if (autoStartDelay == 0)
	{
		InitiateLiveCountdown();
		autoStartTimer = null;
		inAutoStart = false;
		return Plugin_Stop;
	}
	else
	{
		PrintHintTextToAll("%t", "AutoStartCountdown", autoStartDelay);
		if (l4d_ready_enable_sound.BoolValue)
		{
			EmitSoundToAll(autoStartSound, _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
		}
		autoStartDelay--;
	}
	return Plugin_Continue;
}

void InitiateLiveCountdown()
{
	if (readyCountdownTimer == null)
	{
		Call_StartForward(preCountdownForward);
		Call_Finish();
		
		ReturnTeamToSaferoom(L4D2Team_Survivor);
		PrintHintTextToAll("%t", "LiveCountdownBegin");
		inLiveCountdown = true;
		readyDelay = l4d_ready_delay.IntValue;
		if (isForceStart) readyDelay += l4d_ready_force_extra.IntValue;
		readyCountdownTimer = CreateTimer(1.0, ReadyCountdownDelay_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
		Call_StartForward(countdownForward);
		Call_Finish();
	}
}

public Action ReadyCountdownDelay_Timer(Handle timer)
{
	if (readyDelay == 0)
	{
		PrintHintTextToAll("%t", "RoundIsLive");
		InitiateLive();
		readyCountdownTimer = null;
		if (l4d_ready_enable_sound.BoolValue)
		{
			if (l4d_ready_chuckle.BoolValue)
			{
				EmitSoundToAll(chuckleSound[GetRandomInt(0,MAX_SOUNDS-1)]);
			}
			else { EmitSoundToAll(liveSound, _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5); }
		}
		return Plugin_Stop;
	}
	else
	{
		PrintHintTextToAll("%t", "LiveCountdown", readyDelay);
		if (l4d_ready_enable_sound.BoolValue)
		{
			EmitSoundToAll(countdownSound, _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
		}
		readyDelay--;
	}
	return Plugin_Continue;
}

bool CheckFullReady()
{
	int survReadyCount = 0, infReadyCount = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && isPlayerReady[client])
		{
			switch (GetClientTeam(client))
			{
				case L4D2Team_Survivor: survReadyCount++;
				case L4D2Team_Infected: infReadyCount++;
			}
		}
	}
	
	int survLimit = survivor_limit.IntValue;
	int zombLimit = z_max_player_zombies.IntValue;
	
	if (l4d_ready_unbalanced_start.BoolValue)
	{
		int iBaseline = l4d_ready_unbalanced_min.IntValue;
		
		if (iBaseline > survLimit) iBaseline = survLimit;
		if (iBaseline > zombLimit) iBaseline = zombLimit;
		
		return (iBaseline <= GetTeamHumanCount(L4D2Team_Survivor) <= survReadyCount)
			&& (iBaseline <= GetTeamHumanCount(L4D2Team_Infected) <= infReadyCount);
	}
	else
	{
		return (survReadyCount + infReadyCount) >= survLimit + zombLimit;
	}
}

void CancelFullReady(int client, disruptType type)
{
	if (readyCountdownTimer != null)
	{
		SetTeamFrozen(L4D2Team_Survivor, GetConVarBool(l4d_ready_survivor_freeze));
		if (type == teamShuffle) SetClientFrozen(client, false);
		inLiveCountdown = false;
		KillTimer(readyCountdownTimer);
		readyCountdownTimer = null;
		PrintHintTextToAll("%t", "LiveCountdownCancelled");
		
		switch (type)
		{
			case readyStatus: CPrintToChatAllEx(client, "%t", "DisruptReadyStatus", client);
			case teamShuffle: CPrintToChatAllEx(client, "%t", "DisruptTeamShuffle", client);
			case playerDisconn: CPrintToChatAllEx(client, "%t", "DisruptPlayerDisc", client);
			case forceStartAbort: CPrintToChatAll("%t", "DisruptForceStartAbort", client);
		}
	}
}

public Action Timer_RestartCountdowns(Handle timer, bool startOn)
{
	if (!inReadyUp && !startOn) {
		return Plugin_Stop;
	}
	
	if (IsScavenge())
	{
		RestartScvngSetupCountdown(startOn);
	}
	else
	{
		RestartVersusStartCountdown(startOn);
	}
	
	RestartMobCountdown(startOn);

	return Plugin_Stop;
}

void RestartVersusStartCountdown(bool startOn)
{
	static float fDuration = 0.0;
	
	if (startOn)
	{
		if (fDuration != 0.0) L4D2_CTimerStart(L4D2CT_VersusStartTimer, fDuration);
	}
	else
	{
		float temp = L4D2_CTimerGetCountdownDuration(L4D2CT_VersusStartTimer);
		if (temp != 0.0 && temp != 3600.0)
		{
			fDuration = temp;
			L4D2_CTimerStart(L4D2CT_VersusStartTimer, 3600.0);
		}
	}
}

void RestartMobCountdown(bool startOn)
{
	static float fDuration = 0.0;
	
	if (startOn)
	{
		if (fDuration != 0.0) L4D2_CTimerStart(L4D2CT_MobSpawnTimer, fDuration);
	}
	else
	{
		float temp = L4D2_CTimerGetCountdownDuration(L4D2CT_MobSpawnTimer);
		if (temp != 0.0 && temp != 3600.0)
		{
			fDuration = temp;
			L4D2_CTimerStart(L4D2CT_MobSpawnTimer, 3600.0);
		}
	}
}

void RestartScvngSetupCountdown(bool startOn)
{
	static float fDuration = 0.0;
	
	if (startOn)
	{
		if (fDuration != 0.0) CTimer_Start(L4D2Direct_GetScavengeRoundSetupTimer(), fDuration);
	}
	else
	{
		float temp = CTimer_GetCountdownDuration(L4D2Direct_GetScavengeRoundSetupTimer());
		if (temp != 0.0 && temp != 99999.0)
		{
			fDuration = temp;
			CTimer_Start(L4D2Direct_GetScavengeRoundSetupTimer(), 99999.0);
		}
	}
	
	ToggleCountdownPanel(startOn);
}

void ToggleCountdownPanel(bool onoff, int client = 0)
{
	if (client > 0 && IsClientInGame(client)) ShowVGUIPanel(client, "ready_countdown", _, onoff);
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				ShowVGUIPanel(i, "ready_countdown", _, onoff);
			}
		}
	}
}


// ========================
// :D
// ========================

void DoSecrets(int client)
{
	if (GetClientTeam(client) == L4D2Team_Survivor && !blockSecretSpam[client])
	{
		int particle = CreateEntityByName("info_particle_system");
		if (particle == -1) return;
		
		float pos[3];
		GetClientAbsOrigin(client, pos);
		
		pos[2] += 80;
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(particle, "effect_name", "achieved");
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		CreateTimer(5.0, killParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
		
		EmitSoundToAll(SECRET_SOUND, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
		CreateTimer(2.5, killSound);
		
		blockSecretSpam[client] = CreateTimer(5.0, SecretSpamDelay, client);
	}
	PrintCenterTextAll("\x42\x4f\x4e\x45\x53\x41\x57\x20\x49\x53\x20\x52\x45\x41\x44\x59\x21");
}

public Action SecretSpamDelay(Handle timer, int client)
{
	blockSecretSpam[client] = null;
	return Plugin_Stop;
}

public Action killParticle(Handle timer, int entRef)
{
	int entity = EntRefToEntIndex(entRef);
	if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
	return Plugin_Stop;
}

public Action killSound(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
			StopSound(i, SNDCHAN_AUTO, SECRET_SOUND);
	
	return Plugin_Stop;
}



// ========================
//  Natives
// ========================

public int Native_AddStringToReadyFooter(Handle plugin, int numParams)
{
	if (inReadyUp)
	{
		char footer[MAX_FOOTER_LEN];
		GetNativeString(1, footer, sizeof(footer));
		if (footerCounter < MAX_FOOTERS)
		{
			int len = strlen(footer);
			if (0 < len < MAX_FOOTER_LEN && !IsEmptyString(footer, len))
			{
				strcopy(readyFooter[footerCounter], MAX_FOOTER_LEN, footer);
				footerCounter++;
				return footerCounter-1;
			}
		}
	}
	return -1;
}

public int Native_EditFooterStringAtIndex(Handle plugin, int numParams)
{
	if (inReadyUp)
	{
		char newString[MAX_FOOTER_LEN];
		GetNativeString(2, newString, sizeof(newString));
		int index = GetNativeCell(1);
		
		if (footerCounter < MAX_FOOTERS)
		{
			if (strlen(newString) < MAX_FOOTER_LEN)
			{
				readyFooter[index] = newString;
				return true;
			}
		}
	}
	return false;
}

public int Native_FindIndexOfFooterString(Handle plugin, int numParams)
{
	if (inReadyUp)
	{
		char stringToSearchFor[MAX_FOOTER_LEN];
		GetNativeString(1, stringToSearchFor, sizeof(stringToSearchFor));
		
		for (int i = 0; i < footerCounter; i++){
			if (strlen(readyFooter[i]) == 0) continue;
			
			if (StrContains(readyFooter[i], stringToSearchFor, false) > -1){
				return i;
			}
		}
	}
	return -1;
}

public int Native_GetFooterStringAtIndex(Handle plugin, int numParams)
{
	if (inReadyUp)
	{
		int index = GetNativeCell(1), maxlen = GetNativeCell(3);
		char buffer[MAX_FOOTER_LEN];
		
		if (index < MAX_FOOTERS) {
			strcopy(buffer, sizeof(buffer), readyFooter[index]);
		}
		
		SetNativeString(2, buffer, maxlen, true);
		return true;
	}

	return false;
}

public int Native_IsInReady(Handle plugin, int numParams)
{
	return inReadyUp;
}

public int Native_ToggleReadyPanel(Handle plugin, int numParams)
{
	if (inReadyUp)
	{
		// TODO: Inform the client(s) that panel is supressed?
		bool hide = !GetNativeCell(1);
		
		int client = GetNativeCell(2);
		if (client && IsClientInGame(client))
		{
			bool temp = !hiddenPanel[client];
			hiddenPanel[client] = hide;
			return temp;
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					hiddenPanel[i] = hide;
				}
			}
			return true;
		}
	}
	return false;
}


// ========================
//  Helpers
// ========================

void ClearSurvivorProgress()
{
	for (int i = 0; i < 4; i++)
	{
		GameRules_SetProp("m_iVersusDistancePerSurvivor", 0, _,
				i + 4 * GameRules_GetProp("m_bAreTeamsFlipped"));
	}
}

void SetEngineTime(int client)
{
	g_fButtonTime[client] = GetEngineTime();
}

stock void GetClientFixedName(int client, char[] name, int length)
{
	GetClientName(client, name, length);

	if (name[0] == '[')
	{
		char temp[MAX_NAME_LENGTH];
		strcopy(temp, sizeof(temp), name);
		temp[sizeof(temp)-2] = 0;
		strcopy(name[1], length-1, temp);
		name[0] = ' ';
	}
}

stock bool IsScavenge()
{
	return L4D2_IsScavengeMode();
}

stock bool IsEmptyString(const char[] str, int length)
{
	for (int i = 0; i < length; ++i)
	{
		if (!IsCharSpace(str[i]))
		{
			switch (str[i])
			{
				case '\r', '\n': continue;
				
				default: return false;
			}
		}
	}
	return true;
}

stock bool IsAnyPlayerLoading()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && (!IsClientInGame(i) || GetClientTeam(i) == L4D2Team_None))
		{
			return true;
		}
	}
	return false;
}

stock int GetSeriousClientCount(bool inGame = false)
{
	int clients = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (inGame)
		{
			if (IsClientInGame(i) && !IsFakeClient(i)) clients++;
		}
		else
		{
			if (IsClientConnected(i) && !IsFakeClient(i)) clients++;
		}
	}
	
	return clients;
}

stock void ReturnPlayerToSaferoom(int client, bool flagsSet = true)
{
	int warp_flags;
	if (!flagsSet)
	{
		warp_flags = GetCommandFlags("warp_to_start_area");
		SetCommandFlags("warp_to_start_area", warp_flags & ~FCVAR_CHEAT);
	}

	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
	{
		L4D_ReviveSurvivor(client);
	}

	FakeClientCommand(client, "warp_to_start_area");

	if (!flagsSet)
	{
		SetCommandFlags("warp_to_start_area", warp_flags);
	}
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VELOCITY);
}

stock void ReturnTeamToSaferoom(int team)
{
	int warp_flags = GetCommandFlags("warp_to_start_area");
	SetCommandFlags("warp_to_start_area", warp_flags & ~FCVAR_CHEAT);

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team)
		{
			ReturnPlayerToSaferoom(client, true);
		}
	}

	SetCommandFlags("warp_to_start_area", warp_flags);
}

stock void SetTeamFrozen(int team, bool freezeStatus)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team)
		{
			SetClientFrozen(client, freezeStatus);
		}
	}
}

stock void SetClientFrozen(int client, bool freeze)
{
	SetEntityMoveType(client, freeze ? MOVETYPE_NONE : (GetClientTeam(client) == L4D2Team_Spectator ? MOVETYPE_NOCLIP : MOVETYPE_WALK));
}

stock bool IsPlayerAfk(int client)
{
	return GetEngineTime() - g_fButtonTime[client] > AFK_DURATION;
}

stock bool IsPlayer(int client)
{
	int team = GetClientTeam(client);
	return (team == L4D2Team_Survivor || team == L4D2Team_Infected);
}

stock int GetTeamHumanCount(int team)
{
	int humans = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == team)
		{
			humans++;
		}
	}
	
	return humans;
}