#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <builtinvotes>
#include <colors>
#undef REQUIRE_PLUGIN
#include <caster_system>

#define PLUGIN_VERSION "10.1"

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

#define L4D2Team_None       0
#define L4D2Team_Spectator  1
#define L4D2Team_Survivor   2
#define L4D2Team_Infected   3

#define DEBUG 0

enum
{
	ReadyMode_PlayerReady = 1,
	ReadyMode_AutoStart,
	ReadyMode_TeamReady
}

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
// Forwards
GlobalForward
	g_hPreInitiateForward,
	g_hInitiateForward,
	g_hPreCountdownForward,
	g_hCountdownForward,
	g_hPreLiveForward,
	g_hLiveForward,
	g_hCountdownCancelledForward,
	g_hPlayerReadyForward,
	g_hPlayerUnreadyForward;

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
	// basic
	l4d_ready_enabled, l4d_ready_cfg_name, l4d_ready_server_cvar, l4d_ready_max_players,
	// game
	l4d_ready_disable_spawns, l4d_ready_survivor_freeze,
	// sound
	l4d_ready_enable_sound, l4d_ready_notify_sound, l4d_ready_countdown_sound, l4d_ready_live_sound, l4d_ready_autostart_sound, l4d_ready_chuckle, l4d_ready_secret,
	// action
	l4d_ready_delay, l4d_ready_force_extra, l4d_ready_autostart_delay, l4d_ready_autostart_wait, l4d_ready_autostart_min, l4d_ready_unbalanced_start, l4d_ready_unbalanced_min;

// Server Name
ConVar
	g_cvServerNamer;

// Ready Panel
Footer
	nativeFooter;
float
	fStartTimestamp;
	
// Standard Ready Up
int
	readyUpMode;
bool
	inLiveCountdown,
	inReadyUp,
	isForceStart,
	readySurvFreeze;

// Spectate Fix
Handle g_hChangeTeamTimer[MAXPLAYERS+1];

// Caster System
bool casterSystemAvailable;

// Reason enum for Countdown cancelling
enum disruptType
{
	readyStatus,
	teamShuffle,
	playerDisconn,
	adminAbort,
	
	disruptType_SIZE
};

// FIXME: Global const array requires static keyword, then how could I share it between modules?
//static const char g_sDisruptReason[disruptType_SIZE][] = 
char g_sDisruptReason[disruptType_SIZE][] = 
{
	"Player marked unready",
	"Player switched team",
	"Player disconnected",
	"Admin aborted"
};

// Sub modules is included here
#include "readyup/action.inc"
#include "readyup/command.inc"
#include "readyup/footer.inc"
#include "readyup/game.inc"
#include "readyup/native.inc"
#include "readyup/panel.inc"
#include "readyup/player.inc"
#include "readyup/setup.inc"
#include "readyup/sound.inc"
#include "readyup/util.inc"

// ========================
//  Plugin Setup
// ========================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	SetupNatives();
	SetupForwards();
	RegPluginLibrary("readyup");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation();
	
	SetupConVars();
	SetupCommands();
	
	nativeFooter = new Footer();
	
	readySurvFreeze = l4d_ready_survivor_freeze.BoolValue;
	l4d_ready_survivor_freeze.AddChangeHook(CvarChg_SurvFreeze);
	
	l4d_ready_server_cvar.AddChangeHook(CvarChg_ServerCvar);

	HookEvent("round_start",			RoundStart_Event, EventHookMode_Pre);
	HookEvent("player_team",			PlayerTeam_Event, EventHookMode_Post);
	HookEvent("gameinstructor_draw",	GameInstructorDraw_Event, EventHookMode_PostNoCopy);
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

void FillServerNamer()
{
	char buffer[64];
	l4d_ready_server_cvar.GetString(buffer, sizeof buffer);
	if ((g_cvServerNamer = FindConVar(buffer)) == null)
		g_cvServerNamer = FindConVar("hostname");
}

void FindCasterSystem()
{
	casterSystemAvailable = LibraryExists("caster_system");
}

// ========================
//  ConVar Change
// ========================

void CvarChg_SurvFreeze(ConVar convar, const char[] oldValue, const char[] newValue)
{
	readySurvFreeze = convar.BoolValue;
	
	if (inReadyUp)
	{
		ReturnTeamToSaferoom(L4D2Team_Survivor);
		SetTeamFrozen(L4D2Team_Survivor, readySurvFreeze);
	}
}

void CvarChg_ServerCvar(ConVar convar, const char[] oldValue, const char[] newValue)
{
	FillServerNamer();
}

// ========================
//  Events
// ========================

void EntO_OnGameplayStart(const char[] output, int caller, int activator, float delay)
{
	InitiateReadyUp();
}

void RoundStart_Event(Event event, const char[] name, bool dontBroadcast)
{
	InitiateReadyUp(false);
}

void GameInstructorDraw_Event(Event event, const char[] name, bool dontBroadcast)
{
	// Workaround for restarting countdown after scavenge intro
	CreateTimer(0.1, Timer_RestartCountdowns, false, TIMER_FLAG_NO_MAPCHANGE);
}

void PlayerTeam_Event(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if (!client || IsFakeClient(client))
		return;
	
	SetButtonTime(client);
	
	if (!inReadyUp) return;
	
	SetPlayerReady(client, false);
	
	if (isForceStart)
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
	PrecacheSounds();
	
	for (int client = 1; client <= MAXPLAYERS; client++)
	{
		g_hChangeTeamTimer[client] = null;
	}
	
	HookEntityOutput("info_director", "OnGameplayStart", EntO_OnGameplayStart);
}

/* This ensures all cvars are reset if the map is changed during ready-up */
public void OnMapEnd()
{
	if (inReadyUp)
	{
		InitiateAutoStart(false);
		InitiateLive(false);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (inReadyUp && L4D2_IsScavengeMode() && !IsFakeClient(client))
	{
		ToggleCountdownPanel(false, client);
	}
}

public void OnClientDisconnect(int client)
{
	SetPlayerHiddenPanel(client, false);
	SetPlayerReady(client, false);
	g_hChangeTeamTimer[client] = null;
}

/* No need to do any other checks since it seems like this is required no matter what since the intros unfreezes players after the animation completes */
public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
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
				SetButtonTime(client);
			}
			else if (buttons || impulse) SetButtonTime(client);
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
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if (inReadyUp)
	{
		RestartCountdowns(false);
		ReturnPlayerToSaferoom(client, false);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// ========================
//  Command Listener
// ========================

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	SetButtonTime(client);
	return Plugin_Continue;
}

Action Vote_Callback(int client, const char[] command, int argc)
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
