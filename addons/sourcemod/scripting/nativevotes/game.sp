/**
 * vim: set ts=4 :
 * =============================================================================
 * NativeVotes
 * NativeVotes is a voting API plugin for L4D, L4D2, TF2, and CS:GO.
 * Based on the SourceMod voting API
 * 
 * NativeVotes (C) 2011-2014 Ross Bemrose (Powerlord). All rights reserved.
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */
#if defined _nativevotes_game_included
 #endinput
#endif

#define _nativevotes_game_included

#include <sourcemod>

#define L4DL4D2_COUNT						2
#define TF2CSGO_COUNT						5

#define INVALID_ISSUE						-1

//----------------------------------------------------------------------------
// Translation strings

//----------------------------------------------------------------------------
// L4D/L4D2

#define L4DL4D2_VOTE_YES_STRING				"Yes"
#define L4DL4D2_VOTE_NO_STRING				"No"

#define L4D_VOTE_KICK_START					"#L4D_vote_kick_player"
#define L4D_VOTE_KICK_PASSED				"#L4D_vote_passed_kick_player"

// User vote to restart map.
#define L4D_VOTE_RESTART_START				"#L4D_vote_restart_game"
#define L4D_VOTE_RESTART_PASSED				"#L4D_vote_passed_restart_game"

// User vote to change maps.
#define L4D_VOTE_CHANGECAMPAIGN_START		"#L4D_vote_mission_change"
#define L4D_VOTE_CHANGECAMPAIGN_PASSED		"#L4D_vote_passed_mission_change"
#define L4D_VOTE_CHANGELEVEL_START			"#L4D_vote_chapter_change"
#define L4D_VOTE_CHANGELEVEL_PASSED			"#L4D_vote_passed_chapter_change"

// User vote to return to lobby.
#define L4D_VOTE_RETURNTOLOBBY_START			"#L4D_vote_return_to_lobby"
#define L4D_VOTE_RETURNTOLOBBY_PASSED		"#L4D_vote_passed_return_to_lobby"

// User vote to change difficulty.
#define L4D_VOTE_CHANGEDIFFICULTY_START		"#L4D_vote_change_difficulty"
#define L4D_VOTE_CHANGEDIFFICULTY_PASSED		"#L4D_vote_passed_change_difficulty"

// While not a vote string, it works just as well.
#define L4D_VOTE_CUSTOM					"#L4D_TargetID_Player"

//----------------------------------------------------------------------------
// L4D2

// User vote to change alltalk.
#define L4D2_VOTE_ALLTALK_START				"#L4D_vote_alltalk_change"
#define L4D2_VOTE_ALLTALK_PASSED			"#L4D_vote_passed_alltalk_change"
#define L4D2_VOTE_ALLTALK_ENABLE			"#L4D_vote_alltalk_enable"
#define L4D2_VOTE_ALLTALK_DISABLE			"#L4D_vote_alltalk_disable"

//----------------------------------------------------------------------------
// TF2/CSGO
#define TF2CSGO_VOTE_PREFIX					"option"

#define TF2CSGO_VOTE_STRING_KICK			"Kick"
#define TF2CSGO_VOTE_STRING_RESTART			"RestartGame"
#define TF2CSGO_VOTE_STRING_CHANGELEVEL		"ChangeLevel"
#define TF2CSGO_VOTE_STRING_NEXTLEVEL		"NextLevel"
#define TF2CSGO_VOTE_STRING_SCRAMBLE			"ScrambleTeams"

//----------------------------------------------------------------------------
// TF2

#define TF2_VOTE_STRING_CHANGEMISSION		"ChangeMission"

// This one doesn't actually exist in the normal vote menu, but it has a translation string for it.
// Thus, this is the name we will use for it internally
#define TF2_VOTE_STRING_ETERNAWEEN			"Eternaween"

// These are toggles, but the on and off versions are identical
#define TF2_VOTE_STRING_AUTOBALANCE			"TeamAutoBalance" 
#define TF2_VOTE_STRING_CLASSLIMIT			"ClassLimits"

// New as of 2015-09-24
#define TF2_VOTE_STRING_EXTEND				"ExtendLevel"

// Menu items for votes
#define TF2_VOTE_MENU_RESTART				"#Vote_RestartGame"
#define TF2_VOTE_MENU_KICK					"#Vote_Kick"
#define TF2_VOTE_MENU_CHANGELEVEL			"#Vote_ChangeLevel"
#define TF2_VOTE_MENU_NEXTLEVEL				"#Vote_NextLevel"
#define TF2_VOTE_MENU_SCRAMBLE				"#Vote_ScrambleTeams"
#define TF2_VOTE_MENU_CHANGEMISSION			"#Vote_ChangeMission"
#define TF2_VOTE_MENU_ETERNAWEEN			"#Vote_Eternaween"
#define TF2_VOTE_MENU_AUTOBALANCE_ON			"#Vote_TeamAutoBalance_Enable"
#define TF2_VOTE_MENU_AUTOBALANCE_OFF		"#Vote_TeamAutoBalance_Disable"
#define TF2_VOTE_MENU_CLASSLIMIT_ON			"#Vote_ClassLimit_Enable"
#define TF2_VOTE_MENU_CLASSLIMIT_OFF			"#Vote_ClassLimit_Disable"
#define TF2_VOTE_MENU_EXTEND				"#Vote_ExtendLevel"

// User vote to kick user.
#define TF2_VOTE_KICK_IDLE_START			"#TF_vote_kick_player_idle"
#define TF2_VOTE_KICK_SCAMMING_START			"#TF_vote_kick_player_scamming"
#define TF2_VOTE_KICK_CHEATING_START			"#TF_vote_kick_player_cheating"
#define TF2_VOTE_KICK_START					"#TF_vote_kick_player_other"
#define TF2_VOTE_KICK_PASSED				"#TF_vote_passed_kick_player"

// User vote to restart map.
#define TF2_VOTE_RESTART_START				"#TF_vote_restart_game"
#define TF2_VOTE_RESTART_PASSED				"#TF_vote_passed_restart_game"

// User vote to change maps.
#define TF2_VOTE_CHANGELEVEL_START			"#TF_vote_changelevel"
#define TF2_VOTE_CHANGELEVEL_PASSED			"#TF_vote_passed_changelevel"

// User vote to change next level.
#define TF2_VOTE_NEXTLEVEL_SINGLE_START		"#TF_vote_nextlevel"
#define TF2_VOTE_NEXTLEVEL_MULTIPLE_START	"#TF_vote_nextlevel_choices" // Started by server
#define TF2_VOTE_NEXTLEVEL_EXTEND_PASSED		"#TF_vote_passed_nextlevel_extend" // Also used for extend vote
#define TF2_VOTE_NEXTLEVEL_PASSED			"#TF_vote_passed_nextlevel"

// User vote to scramble teams.  Can be immediate or end of round.
#define TF2_VOTE_SCRAMBLE_IMMEDIATE_START	"#TF_vote_scramble_teams"
#define TF2_VOTE_SCRAMBLE_ROUNDEND_START		"#TF_vote_should_scramble_round"
#define TF2_VOTE_SCRAMBLE_PASSED			"#TF_vote_passed_scramble_teams"

// User vote to change MvM mission
#define TF2_VOTE_CHANGEMISSION_START			"#TF_vote_changechallenge"
#define TF2_VOTE_CHANGEMISSION_PASSED		"#TF_vote_passed_changechallenge"

// User vote for eternaween
#define TF2_VOTE_ETERNAWEEN_START			"#TF_vote_eternaween"
#define TF2_VOTE_ETERNAWEEN_PASSED			"#TF_vote_passed_eternaween"

// User vote to start round
#define TF2_VOTE_ROUND_START				"#TF_vote_td_start_round"
#define TF2_VOTE_ROUND_PASSED				"#TF_vote_passed_td_start_round"

// User vote to enable autobalance
#define TF2_VOTE_AUTOBALANCE_ENABLE_START	"#TF_vote_autobalance_enable"
#define TF2_VOTE_AUTOBALANCE_ENABLE_PASSED	"#TF_vote_passed_autobalance_enable"

// User vote to disable autobalance
#define TF2_VOTE_AUTOBALANCE_DISABLE_START	"#TF_vote_autobalance_disable"
#define TF2_VOTE_AUTOBALANCE_DISABLE_PASSED	"#TF_vote_passed_autobalance_disable"

// User vote to enable classlimits
#define TF2_VOTE_CLASSLIMITS_ENABLE_START	"#TF_vote_classlimits_enable"
#define TF2_VOTE_CLASSLIMITS_ENABLE_PASSED	"#TF_vote_passed_classlimits_enable"

// User vote to disable classlimits
#define TF2_VOTE_CLASSLIMITS_DISABLE_START	"#TF_vote_classlimits_disable"
#define TF2_VOTE_CLASSLIMITS_DISABLE_PASSED	"#TF_vote_passed_classlimits_disable"

// Use vote to extend map.
#define TF2_VOTE_EXTEND_START				"#TF_vote_extendlevel"

// While not a vote string, it works just as well.
#define TF2_VOTE_CUSTOM					"#TF_playerid_noteam"

// TF2 (and SDK2013?) VoteFail / CallVoteFail reasons
enum
{
	VOTE_FAILED_GENERIC,
	VOTE_FAILED_TRANSITIONING_PLAYERS,
	VOTE_FAILED_RATE_EXCEEDED,
	VOTE_FAILED_YES_MUST_EXCEED_NO,
	VOTE_FAILED_QUORUM_FAILURE,
	VOTE_FAILED_ISSUE_DISABLED,
	VOTE_FAILED_MAP_NOT_FOUND,
	VOTE_FAILED_MAP_NAME_REQUIRED,
	VOTE_FAILED_FAILED_RECENTLY,
	VOTE_FAILED_TEAM_CANT_CALL,
	VOTE_FAILED_WAITINGFORPLAYERS,
	VOTE_FAILED_PLAYERNOTFOUND,
	VOTE_FAILED_CANNOT_KICK_ADMIN,
	VOTE_FAILED_SCRAMBLE_IN_PROGRESS,
	VOTE_FAILED_SPECTATOR,
	VOTE_FAILED_NEXTLEVEL_SET,
	VOTE_FAILED_MAP_NOT_VALID,
	VOTE_FAILED_CANNOT_KICK_FOR_TIME,
	VOTE_FAILED_CANNOT_KICK_DURING_ROUND,
	VOTE_FAILED_MODIFICATION_ALREADY_ACTIVE,
}

//----------------------------------------------------------------------------
// CSGO
// User vote to kick user.
#define CSGO_VOTE_KICK_IDLE_START			"#SFUI_vote_kick_player_idle"
#define CSGO_VOTE_KICK_SCAMMING_START		"#SFUI_vote_kick_player_scamming"
#define CSGO_VOTE_KICK_CHEATING_START		"#SFUI_vote_kick_player_cheating"
#define CSGO_VOTE_KICK_START				"#SFUI_vote_kick_player_other"
#define CSGO_VOTE_KICK_OTHERTEAM			"#SFUI_otherteam_vote_kick_player"
#define CSGO_VOTE_KICK_PASSED				"#SFUI_vote_passed_kick_player"

// User vote to restart map.
#define CSGO_VOTE_RESTART_START				"#SFUI_vote_restart_game"
#define CSGO_VOTE_RESTART_PASSED			"#SFUI_vote_passed_restart_game"

// User vote to change maps.
#define CSGO_VOTE_CHANGELEVEL_START			"#SFUI_vote_changelevel"
#define CSGO_VOTE_CHANGELEVEL_PASSED			"#SFUI_vote_passed_changelevel"

// User vote to change next level.
#define CSGO_VOTE_NEXTLEVEL_SINGLE_START		"#SFUI_vote_nextlevel"
#define CSGO_VOTE_NEXTLEVEL_MULTIPLE_START	"#SFUI_vote_nextlevel_choices" // Started by server
#define CSGO_VOTE_NEXTLEVEL_EXTEND_PASSED	"#SFUI_vote_passed_nextlevel_extend"
#define CSGO_VOTE_NEXTLEVEL_PASSED			"#SFUI_vote_passed_nextlevel"

// User vote to scramble teams.
#define CSGO_VOTE_SCRAMBLE_START			"#SFUI_vote_scramble_teams"
#define CSGO_VOTE_SCRAMBLE_PASSED 			"#SFUI_vote_passed_scramble_teams"

// User vote to swap teams.
#define CSGO_VOTE_SWAPTEAMS_START			"#SFUI_vote_swap_teams"
#define CSGO_VOTE_SWAPTEAMS_PASSED 			"#SFUI_vote_passed_swap_teams"

// User vote to surrender
#define CSGO_VOTE_SURRENDER_START			"#SFUI_vote_surrender"
#define CSGO_VOTE_SURRENDER_OTHERTEAM		"#SFUI_otherteam_vote_continue_or_surrender"
#define CSGO_VOTE_SURRENDER_PASSED			"#SFUI_vote_passed_surrender"

// User vote to rematch
#define CSGO_VOTE_REMATCH_START				"#SFUI_vote_rematch"
#define CSGO_VOTE_REMATCH_PASSED			"#SFUI_vote_passed_rematch"

// User vote to continue match with bots
#define CSGO_VOTE_CONTINUE_START			"#SFUI_vote_continue"
#define CSGO_VOTE_CONTINUE_OTHERTEAM		"#SFUI_otherteam_vote_continue_or_surrender"
#define CSGO_VOTE_CONTINUE_PASSED			"#SFUI_vote_passed_continue"

// User vote to pause game
#define CSGO_VOTE_PAUSE_START				"#SFUI_Vote_pause_match"
#define CSGO_VOTE_PAUSE_PASSED				"#SFUI_vote_passed_pause_match"

// User vote to unpause game
#define CSGO_VOTE_UNPAUSE_START				"#SFUI_Vote_unpause_match"
#define CSGO_VOTE_UNPAUSE_PASSED			"#SFUI_vote_passed_unpause_match"

// User vote to load backups
#define CSGO_VOTE_LOADBACKUP_START			"#SFUI_Vote_loadbackup"
#define CSGO_VOTE_LOADBACKUP_PASSED			"#SFUI_vote_passed_loadbackup"

// User vote to start match
#define CSGO_VOTE_READY_START				"#SFUI_Vote_ready_for_match"
#define CSGO_VOTE_READY_PASSED				"#SFUI_vote_passed_ready_for_match"

// User vote to delay match start
#define CSGO_VOTE_NOTREADY_START			"#SFUI_Vote_not_ready_for_match"
#define CSGO_VOTE_NOTREADY_PASSED			"#SFUI_vote_passed_not_ready_for_match"

// User vote to start round
#define CSGO_VOTE_ROUND_START				"#SFUI_vote_td_start_round"
#define CSGO_VOTE_ROUND_PASSED				"#SFUI_vote_passed_td_start_round"

#define CSGO_VOTE_UNIMPLEMENTED_OTHERTEAM	"#SFUI_otherteam_vote_unimplemented"

// While not a vote string, it works just as well.
#define CSGO_VOTE_CUSTOM					"#SFUI_Scoreboard_NormalPlayer"

// CSGO VoteFail / CallVoteFail reasons
enum
{
	CSGO_VOTE_FAILED_GENERIC,
	CSGO_VOTE_FAILED_TRANSITIONING_PLAYERS,
	CSGO_VOTE_FAILED_RATE_EXCEEDED,
	CSGO_VOTE_FAILED_YES_MUST_EXCEED_NO,
	CSGO_VOTE_FAILED_QUORUM_FAILURE,
	CSGO_VOTE_FAILED_ISSUE_DISABLED,
	CSGO_VOTE_FAILED_MAP_NOT_FOUND,
	CSGO_VOTE_FAILED_MAP_NAME_REQUIRED,
	CSGO_VOTE_FAILED_FAILED_RECENTLY,
	CSGO_VOTE_FAILED_FAILED_RECENTLY_KICK,
	CSGO_VOTE_FAILED_FAILED_RECENTLY_MAP,
	CSGO_VOTE_FAILED_FAILED_RECENTLY_SWAP,
	CSGO_VOTE_FAILED_FAILED_RECENTLY_SCRAMBLE,
	CSGO_VOTE_FAILED_FAILED_RECENTLY_RESTART,
	CSGO_VOTE_FAILED_TEAM_CANT_CALL,
	CSGO_VOTE_FAILED_WARMUP,
	CSGO_VOTE_FAILED_PLAYERNOTFOUND,
	CSGO_VOTE_FAILED_CANNOT_KICK_ADMIN,
	CSGO_VOTE_FAILED_SCRAMBLE_IN_PROGRESS,
	CSGO_VOTE_FAILED_SWAP_IN_PROGRESS,
	CSGO_VOTE_FAILED_SPECTATOR,
	CSGO_VOTE_FAILED_NEXTLEVEL_SET,
	CSGO_VOTE_FAILED_UNKNOWN1,
	CSGO_VOTE_FAILED_SURRENDER_ABANDON,
	CSGO_VOTE_FAILED_UNKNOWN2,
	CSGO_VOTE_FAILED_PAUSED,
	CSGO_VOTE_FAILED_NOT_PAUSED,
	CSGO_VOTE_FAILED_NOT_WARMUP,
	CSGO_VOTE_FAILED_MIN_PLAYERS,
	CSGO_VOTE_FAILED_ROUND_ENDED,
}


//----------------------------------------------------------------------------
// Generic functions
// 

// This is deprecated in NativeVotes 1.1
enum
{
	ValveVote_Kick = 0,
	ValveVote_Restart = 1,
	ValveVote_ChangeLevel = 2,
	ValveVote_NextLevel = 3,
	ValveVote_Scramble = 4,
	ValveVote_SwapTeams = 5,
}

static int g_VoteController = -1;
static bool g_bUserBuf = false;

static ConVar g_Cvar_Votes_Enabled;
static ConVar g_Cvar_VoteKick_Enabled;
static ConVar g_Cvar_MvM_VoteKick_Enabled;
static ConVar g_Cvar_VoteNextLevel_Enabled;
static ConVar g_Cvar_VoteChangeLevel_Enabled;
static ConVar g_Cvar_MvM_VoteChangeLevel_Enabled;
static ConVar g_Cvar_VoteRestart_Enabled;
static ConVar g_Cvar_MvM_VoteRestart_Enabled;
static ConVar g_Cvar_VoteScramble_Enabled;
static ConVar g_Cvar_MvM_VoteChallenge_Enabled;
static ConVar g_Cvar_VoteAutoBalance_Enabled;
static ConVar g_Cvar_VoteClassLimits_Enabled;
static ConVar g_Cvar_MvM_VoteClassLimits_Enabled;
static ConVar g_Cvar_VoteExtend_Enabled;

static ConVar g_Cvar_ClassLimit;
static ConVar g_Cvar_AutoBalance;

static ConVar g_Cvar_HideDisabledIssues;

/**
 * TODO(UPDATE): For now we only support one vote from NativeVotes at a time.
 * 
 * Ideally we peek and poke at the game's `s_nVoteIdx` and increment it accordingly, but we also
 * have to store an internal list of active votes.
 */
static int s_nNativeVoteIdx = 0;

bool Game_IsGameSupported(char[] engineName="", int maxlength=0)
{
	g_EngineVersion = GetEngineVersion();
	g_bUserBuf = GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf;
	
	//LogMessage("Detected Engine version: %d", g_EngineVersion);
	if (maxlength > 0)
	{
		GetEngineVersionName(g_EngineVersion, engineName, maxlength);
	}
	
	switch (g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2, Engine_CSGO, Engine_TF2:
		{
			return true;
		}
	}
	
	return false;
}

void Game_InitializeCvars()
{
	switch (g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2, Engine_CSGO:
		{
			g_Cvar_Votes_Enabled = FindConVar("sv_allow_votes");
		}
		
		case Engine_TF2:
		{
			g_Cvar_Votes_Enabled = FindConVar("sv_allow_votes");
			g_Cvar_VoteKick_Enabled = FindConVar("sv_vote_issue_kick_allowed");
			g_Cvar_MvM_VoteKick_Enabled = FindConVar("sv_vote_issue_kick_allowed_mvm");
			g_Cvar_VoteNextLevel_Enabled = FindConVar("sv_vote_issue_nextlevel_allowed");
			g_Cvar_VoteChangeLevel_Enabled = FindConVar("sv_vote_issue_changelevel_allowed");
			g_Cvar_MvM_VoteChangeLevel_Enabled = FindConVar("sv_vote_issue_changelevel_allowed_mvm");
			g_Cvar_VoteRestart_Enabled = FindConVar("sv_vote_issue_restart_game_allowed");
			g_Cvar_MvM_VoteRestart_Enabled = FindConVar("sv_vote_issue_restart_game_allowed_mvm");
			g_Cvar_VoteScramble_Enabled = FindConVar("sv_vote_issue_scramble_teams_allowed");
			g_Cvar_MvM_VoteChallenge_Enabled = FindConVar("sv_vote_issue_mvm_challenge_allowed");
			g_Cvar_VoteAutoBalance_Enabled = FindConVar("sv_vote_issue_autobalance_allowed");
			g_Cvar_VoteClassLimits_Enabled = FindConVar("sv_vote_issue_classlimits_allowed");
			g_Cvar_MvM_VoteClassLimits_Enabled = FindConVar("sv_vote_issue_classlimits_allowed_mvm");
			g_Cvar_VoteExtend_Enabled = FindConVar("sv_vote_issue_extendlevel_allowed");
			
			g_Cvar_ClassLimit = FindConVar("tf_classlimit");
			g_Cvar_AutoBalance = FindConVar("mp_autoteambalance");
			
			g_Cvar_HideDisabledIssues = FindConVar("sv_vote_ui_hide_disabled_issues");
		}
	}
}

NativeVotesKickType Game_GetKickType(const char[] param1, int &target)
{
	NativeVotesKickType kickType;
	
	switch(g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2, Engine_CSGO:
		{
			target = StringToInt(param1);
			kickType = NativeVotesKickType_Generic;
		}
		
		case Engine_TF2:
		{
			char params[2][20];
			ExplodeString(param1, " ", params, sizeof(params), sizeof(params[]));
			
			target = StringToInt(params[0]);
			
			if (StrEqual(params[1], "cheating", false))
			{
				kickType = NativeVotesKickType_Cheating;
			}
			else if (StrEqual(params[1], "idle", false))
			{
				kickType = NativeVotesKickType_Idle;
			}
			else if (StrEqual(params[1], "scamming", false))
			{
				kickType = NativeVotesKickType_Scamming;
			}
			else
			{
				kickType = NativeVotesKickType_Generic;					
			}
		}
	}
	return kickType;
}

bool CheckVoteController()
{
	int entity = INVALID_ENT_REFERENCE;
	if (g_VoteController != -1)
	{
		entity = EntRefToEntIndex(g_VoteController);
	}
	
	if (entity == INVALID_ENT_REFERENCE)
	{
		entity = FindEntityByClassname(-1, "vote_controller");
		if (entity == -1)
		{
			//LogError("Could not find Vote Controller.");
			return false;
		}
		
		g_VoteController = EntIndexToEntRef(entity);
	}
	return true;
}

// All logic for choosing a game-specific function should happen here.
// There should be one per function in the game shared and specific sections
int Game_ParseVote(const char[] option)
{
	int item = NATIVEVOTES_VOTE_INVALID;
	
#if defined LOG
	LogMessage("Parsing vote option %s", option);
#endif
	
	switch(g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2:
		{
			item = L4DL4D2_ParseVote(option);
		}
		
		case Engine_CSGO:
		{
			item = CSGO_ParseVote(option);
		}
		case Engine_TF2:
		{
			item = TF2_ParseVote(option);
		}
	}
	
	return item;

}

int Game_GetMaxItems()
{
	switch (g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2:
		{
			return L4DL4D2_COUNT;
		}
		
		case Engine_CSGO, Engine_TF2:
		{
			return TF2CSGO_COUNT;
		}
	}
	
	return 0; // Here to prevent warnings
}

bool Game_CheckVoteType(NativeVotesType type)
{
	bool returnVal = false;
	
	switch(g_EngineVersion)
	{
		case Engine_Left4Dead:
		{
			returnVal = L4D_CheckVoteType(type);
		}
		
		case Engine_Left4Dead2:
		{
			returnVal = L4D2_CheckVoteType(type);
		}
		
		case Engine_CSGO:
		{
			returnVal = CSGO_CheckVoteType(type);
		}

		case Engine_TF2:
		{
			returnVal = TF2_CheckVoteType(type);
		}
	}
	
	return returnVal;
}

bool Game_CheckVotePassType(NativeVotesPassType type)
{
	bool returnVal = false;
	
	switch(g_EngineVersion)
	{
		case Engine_Left4Dead:
		{
			returnVal = L4D_CheckVotePassType(type);
		}
		
		case Engine_Left4Dead2:
		{
			returnVal = L4D2_CheckVotePassType(type);
		}
		
		case Engine_CSGO:
		{
			returnVal = CSGO_CheckVotePassType(type);
		}
		
		case Engine_TF2:
		{
			returnVal = TF2_CheckVotePassType(type);
		}
	}
	
	return returnVal;
}

bool Game_DisplayVoteToOne(NativeVote vote, int client)
{
	if (g_bCancelled)
	{
		return false;
	}
	
	int clients[1];
	clients[0] = client;
	
	return Game_DisplayVote(vote, clients, 1);
}

bool Game_DisplayVote(NativeVote vote, int[] clients, int num_clients)
{
	if (g_bCancelled)
	{
		return false;
	}
	
	switch(g_EngineVersion)
	{
		case Engine_Left4Dead:
		{
			L4D_DisplayVote(vote, num_clients);
		}
		
		case Engine_Left4Dead2:
		{
			L4D2_DisplayVote(vote, clients, num_clients);
		}
		
		case Engine_CSGO, Engine_TF2:
		{
			TF2CSGO_DisplayVote(vote, clients, num_clients);
		}
	}

	
#if defined LOG
	char details[MAX_VOTE_DETAILS_LENGTH];
	char translation[TRANSLATION_LENGTH];
	
	NativeVotesType voteType = Data_GetType(vote);
	Data_GetDetails(vote, details, sizeof(details));
	Game_VoteTypeToTranslation(voteType, translation, sizeof(translation));
	
	LogMessage("Displaying vote: type: %d, translation: \"%s\", details: \"%s\"", voteType, translation, details);
#endif
	
	return true;
}

void Game_DisplayVoteFail(NativeVote vote, NativeVotesFailType reason)
{
	int team = Data_GetTeam(vote);
	
	int total = 0;
	int[] players = new int[MaxClients];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		players[total++] = i;
	}
	
	Game_DisplayRawVoteFail(players, total, reason, team);
}

void Game_DisplayRawVoteFail(int[] clients, int numClients, NativeVotesFailType reason, int team)
{
	switch(g_EngineVersion)
	{
		case Engine_Left4Dead:
		{
			L4D_VoteFail(team);
		}
		
		case Engine_Left4Dead2:
		{
			L4D2_VoteFail(clients, numClients, team);
		}
		
		case Engine_CSGO:
		{
			int reasonType = VoteFailTypeToInt(reason);
			CSGO_VoteFail(clients, numClients, reasonType, team);
		}
		
		case Engine_TF2:
		{
			int reasonType = VoteFailTypeToInt(reason);
			TF2_VoteFail(clients, numClients, reasonType, team);
		}
	}
	
#if defined LOG
	LogMessage("Vote Failed to %d client(s): \"%d\"", numClients, reason);
#endif
}

void Game_DisplayVotePass(NativeVote vote, const char[] details="", int client=0)
{
	NativeVotesPassType passType = VoteTypeToVotePass(Data_GetType(vote));
	
	Game_DisplayVotePassEx(vote, passType, details, client);
}

void Game_DisplayVotePassEx(NativeVote vote, NativeVotesPassType passType, const char[] details="", int client=0)
{
	int team = Data_GetTeam(vote);

	Game_DisplayRawVotePass(passType, team, client, details);
}

void Game_DisplayRawVotePass(NativeVotesPassType passType, int team, int client=0, const char[] details="")
{
	char translation[TRANSLATION_LENGTH];

	switch (g_EngineVersion)
	{
		case Engine_Left4Dead:
		{
			if (!client)
			{
				L4DL4D2_VotePassToTranslation(passType, translation, sizeof(translation));
				
				L4D_VotePass(translation, details, team);
			}
		}
		
		case Engine_Left4Dead2:
		{
			L4DL4D2_VotePassToTranslation(passType, translation, sizeof(translation));
			
			switch (passType)
			{
				case NativeVotesPass_AlltalkOn:
				{
					L4D2_VotePass(translation, L4D2_VOTE_ALLTALK_ENABLE, team, client);
				}
				
				case NativeVotesPass_AlltalkOff:
				{
					L4D2_VotePass(translation, L4D2_VOTE_ALLTALK_DISABLE, team, client);
				}
				
				default:
				{
					L4D2_VotePass(translation, details, team, client);
				}
			}
		}
		
		case Engine_CSGO:
		{
			CSGO_VotePassToTranslation(passType, translation, sizeof(translation));
			CSGO_VotePass(translation, details, team, client);
		}
		
		case Engine_TF2:
		{
			TF2_VotePassToTranslation(passType, translation, sizeof(translation));
			TF2_VotePass(translation, details, team, client);
		}
	}
	
#if defined LOG
	if (client != 0)
		LogMessage("Vote Passed: \"%s\", \"%s\"", translation, details);
#endif
}

void Game_DisplayVotePassCustom(NativeVote vote, const char[] translation, int client)
{
	int team = Data_GetTeam(vote);
	Game_DisplayRawVotePassCustom(translation, team, client);
}

void Game_DisplayRawVotePassCustom(const char[] translation, int team, int client)
{
	switch (g_EngineVersion)
	{
		case Engine_Left4Dead:
		{
			ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes_DisplayPassCustom is not supported on L4D");
		}
		
		case Engine_Left4Dead2:
		{
			L4D2_VotePass(L4D_VOTE_CUSTOM, translation, team, client);
		}
		
		case Engine_CSGO:
		{
			CSGO_VotePass(CSGO_VOTE_CUSTOM, translation, team, client);
		}
		
		case Engine_TF2:
		{
			TF2_VotePass(TF2_VOTE_CUSTOM, translation, team, client);
		}
	}
	
#if defined LOG
	if (client != 0)
		LogMessage("Vote Passed Custom: \"%s\"", translation);
#endif
}

void Game_DisplayCallVoteFail(int client, NativeVotesCallFailType reason, int time)
{
	
	int reasonType = VoteCallFailTypeToInt(reason);
	
	switch (g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2:
		{
			L4DL4D2_CallVoteFail(client, reasonType);
		}
		
		case Engine_CSGO:
		{
			CSGO_CallVoteFail(client, reasonType, time);
		}
		
		case Engine_TF2:
		{
			TF2_CallVoteFail(client, reasonType, time);
		}
	}
	
#if defined LOG
	LogMessage("Call vote failed: client: %N, reason: %d, time: %d", client, reason, time);
#endif
}

void Game_ClientSelectedItem(NativeVote vote, int client, int item)
{
#if defined LOG
	LogMessage("Client %N selected item %d", client, item);
#endif
	switch(g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2:
		{
			L4DL4D2_ClientSelectedItem(client, item);
		}
		
		case Engine_CSGO:
		{
			CSGO_ClientSelectedItem(vote, client, item);
		}
		case Engine_TF2:
		{
			TF2_ClientSelectedItem(vote, client, item);
		}
/*
		case Engine_Left4Dead:
		{
			L4D_ClientSelectedItem(vote, client, item);
		}
		
		case Engine_Left4Dead2:
		{
			L4D2_ClientSelectedItem(client, item);
		}
*/
	}
}

void Game_UpdateVoteCounts(ArrayList hVoteCounts, int totalClients)
{
	switch(g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2:
		{
			L4DL4D2_UpdateVoteCounts(hVoteCounts, totalClients);
		}
		
		case Engine_CSGO, Engine_TF2:
		{
			TF2CSGO_UpdateVoteCounts(hVoteCounts);
		}
	}
}

void Game_DisplayVoteSetup(int client, ArrayList hVoteTypes)
{
	switch (g_EngineVersion)
	{
		case Engine_Left4Dead:
		{
			//L4D_DisplayVoteSetup(client, voteTypes);
		}
		
		case Engine_Left4Dead2:
		{
			//L4D2_DisplayVoteSetup(client, voteTypes);
		}
		
		case Engine_TF2:
		{
			TF2_DisplayVoteSetup(client, hVoteTypes);
		}
		
		case Engine_CSGO:
		{
			//CSGO_DisplayVoteSetup(client, hVoteTypes);
		}
		
	}
}

// stock because at the moment it's only used in logging code which isn't always compiled.
stock void Game_VoteTypeToTranslation(NativeVotesType voteType, char[] translation, int maxlength)
{
	switch(g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2:
		{
			L4DL4D2_VoteTypeToTranslation(voteType, translation, maxlength);
		}
		
		case Engine_CSGO:
		{
			CSGO_VoteTypeToTranslation(voteType, translation, maxlength);
		}
		
		case Engine_TF2:
		{
			TF2_VoteTypeToTranslation(voteType, translation, maxlength);
		}
	}
}

stock void Game_UpdateClientCount(int num_clients)
{
	switch(g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2:
		{
			L4DL4D2_UpdateClientCount(num_clients);
		}
		
		case Engine_CSGO, Engine_TF2:
		{
			TF2CSGO_UpdateClientCount(num_clients);
		}
	}
}

public Action Game_ResetVote(Handle timer)
{
	switch(g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2:
		{
			L4DL4D2_ResetVote();
		}
		
		case Engine_CSGO, Engine_TF2:
		{
			TF2CSGO_ResetVote();
		}
	}
	return Plugin_Continue;
}

void Game_VoteYes(int client)
{
	switch (g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2:
		{
			FakeClientCommand(client, "Vote Yes");
		}
		
		case Engine_CSGO, Engine_TF2:
		{
			FakeClientCommand(client, "vote option1");
		}
	}
}

void Game_VoteNo(int client)
{
	switch (g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2:
		{
			FakeClientCommand(client, "Vote No");
		}
		
		case Engine_CSGO, Engine_TF2:
		{
			FakeClientCommand(client, "vote option2");
		}
	}
}

bool Game_IsVoteInProgress()
{
	switch (g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2:
		{
			return L4DL4D2_IsVoteInProgress();
		}
		
		case Engine_CSGO, Engine_TF2:
		{
			return TF2CSGO_IsVoteInProgress();
		}
	}
	
	return false;
}

bool Game_AreVoteCommandsSupported()
{
	switch (g_EngineVersion)
	{
		case Engine_TF2:
		{
			return true;
		}
	}
	
	return false;
}

stock bool Game_VoteTypeToVoteString(NativeVotesType voteType, char[] voteString, int maxlength)
{
	switch (g_EngineVersion)
	{
		case Engine_TF2:
		{
			return TF2_VoteTypeToVoteString(voteType, voteString, maxlength);
		}
	}
	
	return false;
}

stock NativeVotesType Game_VoteStringToVoteType(char[] voteString)
{
	switch (g_EngineVersion)
	{
		case Engine_TF2:
		{
			return TF2_VoteStringToVoteType(voteString);
		}
	}
	
	return NativeVotesType_None;
}

stock NativeVotesOverride Game_VoteTypeToVoteOverride(NativeVotesType voteType)
{
	switch (g_EngineVersion)
	{
		case Engine_TF2:
		{
			return TF2_VoteTypeToVoteOverride(voteType);
		}
	}
	
	return NativeVotesOverride_None;
}

stock NativeVotesType Game_VoteOverrideToVoteType(NativeVotesOverride overrideType)
{
	switch (g_EngineVersion)
	{
		case Engine_TF2:
		{
			return TF2_VoteOverrideToVoteType(overrideType);
		}
	}
	
	return NativeVotesType_None;
}

stock NativeVotesOverride Game_VoteStringToVoteOverride(const char[] voteString)
{
	switch (g_EngineVersion)
	{
		case Engine_TF2:
		{
			return TF2_VoteStringToVoteOverride(voteString);
		}
	}
	
	return NativeVotesOverride_None;
}

stock bool Game_OverrideTypeToVoteString(NativeVotesOverride overrideType, char[] voteString, int maxlength)
{
	switch (g_EngineVersion)
	{
		case Engine_TF2:
		{
			return TF2_OverrideTypeToVoteString(overrideType, voteString, maxlength);
		}
	}
	
	return false;
}

stock bool Game_OverrideTypeToTranslationString(NativeVotesOverride overrideType, char[] translationString, int maxlength)
{
	switch (g_EngineVersion)
	{
		case Engine_TF2:
		{
			return TF2_OverrideTypeToTranslationString(overrideType, translationString, maxlength);
		}
	}
	
	return false;
}

void Game_AddDefaultVotes(ArrayList hVoteTypes)
{
	switch (g_EngineVersion)
	{
		case Engine_TF2:
		{
			TF2_AddDefaultVotes(hVoteTypes, Game_AreDisabledIssuesHidden());
		}
	}
}

bool Game_AreDisabledIssuesHidden()
{
	switch (g_EngineVersion)
	{
		case Engine_TF2:
		{
			return g_Cvar_HideDisabledIssues.BoolValue;
		}
	}
	
	return true;
}

// All games shared functions

//----------------------------------------------------------------------------
// Data functions

static NativeVotesPassType VoteTypeToVotePass(NativeVotesType voteType)
{
	NativeVotesPassType passType = NativeVotesPass_None;
	
	switch(voteType)
	{
		case NativeVotesType_Custom_YesNo, NativeVotesType_Custom_Mult:
		{
			passType = NativeVotesPass_Custom;
		}
		
		case NativeVotesType_ChgCampaign:
		{
			passType = NativeVotesPass_ChgCampaign;
		}
		
		case NativeVotesType_ChgDifficulty:
		{
			passType = NativeVotesPass_ChgDifficulty;
		}
		
		case NativeVotesType_ReturnToLobby:
		{
			passType = NativeVotesPass_ReturnToLobby;
		}
		
		case NativeVotesType_AlltalkOn:
		{
			passType = NativeVotesPass_AlltalkOn;
		}
		
		case NativeVotesType_AlltalkOff:
		{
			passType = NativeVotesPass_AlltalkOff;
		}
		
		case NativeVotesType_Restart:
		{
			passType = NativeVotesPass_Restart;
		}
		
		case NativeVotesType_Kick, NativeVotesType_KickIdle, NativeVotesType_KickScamming, NativeVotesType_KickCheating:
		{
			passType = NativeVotesPass_Kick;
		}
		
		case NativeVotesType_ChgLevel:
		{
			passType = NativeVotesPass_ChgLevel;
		}
		
		case NativeVotesType_NextLevel, NativeVotesType_NextLevelMult:
		{
			passType = NativeVotesPass_NextLevel;
		}
		
		case NativeVotesType_ScrambleNow, NativeVotesType_ScrambleEnd:
		{
			passType = NativeVotesPass_Scramble;
		}
		
		case NativeVotesType_ChgMission:
		{
			passType = NativeVotesPass_ChgMission;
		}
		
		case NativeVotesType_SwapTeams:
		{
			passType = NativeVotesPass_SwapTeams;
		}
		
		case NativeVotesType_Surrender:
		{
			passType = NativeVotesPass_Surrender;
		}
		
		case NativeVotesType_Rematch:
		{
			passType = NativeVotesPass_Rematch;
		}
		
		case NativeVotesType_Continue:
		{
			passType = NativeVotesPass_Continue;
		}
		
		case NativeVotesType_StartRound:
		{
			passType = NativeVotesPass_StartRound;
		}
		
		case NativeVotesType_Eternaween:
		{
			passType = NativeVotesPass_Eternaween;
		}
		
		case NativeVotesType_AutoBalanceOn:
		{
			passType = NativeVotesPass_AutoBalanceOn;
		}
		
		case NativeVotesType_AutoBalanceOff:
		{
			passType = NativeVotesPass_AutoBalanceOff;
		}
		
		case NativeVotesType_ClassLimitsOn:
		{
			passType = NativeVotesPass_ClassLimitsOn;
		}
		
		case NativeVotesType_ClassLimitsOff:
		{
			passType = NativeVotesPass_ClassLimitsOff;
		}
		
		case NativeVotesType_Extend:
		{
			passType = NativeVotesPass_Extend;
		}
		
		default:
		{
			passType = NativeVotesPass_Custom;
		}
	}
	
	return passType;
}

// In case we find more types later
static int VoteFailTypeToInt(NativeVotesFailType failType)
{
	return view_as<int>(failType);
}

static int VoteCallFailTypeToInt(NativeVotesCallFailType failType)
{
	switch (g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2:
		{
			switch (failType)
			{
				case NativeVotesCallFail_Generic:
				{
					return VOTE_FAILED_GENERIC;
				}
				
				case NativeVotesCallFail_Loading:
				{
					return VOTE_FAILED_TRANSITIONING_PLAYERS;
				}
				
				case NativeVotesCallFail_Recent:
				{
					return VOTE_FAILED_FAILED_RECENTLY;
				}
			}
		}
		
		case Engine_TF2:
		{
			switch (failType)
			{
				case NativeVotesCallFail_Generic:
				{
					return VOTE_FAILED_GENERIC;
				}
				
				case NativeVotesCallFail_Loading:
				{
					return VOTE_FAILED_TRANSITIONING_PLAYERS;
				}
				
				case NativeVotesCallFail_Recent:
				{
					return VOTE_FAILED_FAILED_RECENTLY;
				}
				
				case NativeVotesCallFail_Disabled:
				{
					return VOTE_FAILED_ISSUE_DISABLED;
				}
				
				case NativeVotesCallFail_MapNotFound:
				{
					return VOTE_FAILED_MAP_NOT_FOUND;
				}
				
				case NativeVotesCallFail_SpecifyMap:
				{
					return VOTE_FAILED_MAP_NAME_REQUIRED;
				}
				
				case NativeVotesCallFail_Failed:
				{
					return VOTE_FAILED_FAILED_RECENTLY;
				}
				
				case NativeVotesCallFail_WrongTeam:
				{
					return VOTE_FAILED_TEAM_CANT_CALL;
				}
				
				case NativeVotesCallFail_Waiting:
				{
					return VOTE_FAILED_WAITINGFORPLAYERS;
				}
				
				case NativeVotesCallFail_PlayerNotFound:
				{
					return VOTE_FAILED_PLAYERNOTFOUND;
				}
				
				case NativeVotesCallFail_CantKickAdmin:
				{
					return VOTE_FAILED_CANNOT_KICK_ADMIN;
				}
				
				case NativeVotesCallFail_ScramblePending:
				{
					return VOTE_FAILED_SCRAMBLE_IN_PROGRESS;
				}
				
				case NativeVotesCallFail_Spectators:
				{
					return VOTE_FAILED_SPECTATOR;
				}
				
				case NativeVotesCallFail_LevelSet:
				{
					return VOTE_FAILED_NEXTLEVEL_SET;
				}
				
				case NativeVotesCallFail_MapNotValid:
				{
					return VOTE_FAILED_MAP_NOT_VALID;
				}
				
				case NativeVotesCallFail_KickTime:
				{
					return VOTE_FAILED_CANNOT_KICK_FOR_TIME;
				}
				
				case NativeVotesCallFail_KickDuringRound:
				{
					return VOTE_FAILED_CANNOT_KICK_DURING_ROUND;
				}
				
				case NativeVotesCallFail_AlreadyActive:
				{
					return VOTE_FAILED_MODIFICATION_ALREADY_ACTIVE;
				}
			}
		}
		
		case Engine_CSGO:
		{
			switch (failType)
			{
				case NativeVotesCallFail_Generic:
				{
					return CSGO_VOTE_FAILED_GENERIC;
				}
				
				case NativeVotesCallFail_Loading:
				{
					return CSGO_VOTE_FAILED_TRANSITIONING_PLAYERS;
				}
				
				case NativeVotesCallFail_Recent:
				{
					return CSGO_VOTE_FAILED_RATE_EXCEEDED;
				}
				
				case NativeVotesCallFail_Disabled:
				{
					return CSGO_VOTE_FAILED_ISSUE_DISABLED;
				}
				
				case NativeVotesCallFail_MapNotFound:
				{
					return CSGO_VOTE_FAILED_MAP_NOT_FOUND;
				}
				
				case NativeVotesCallFail_SpecifyMap:
				{
					return CSGO_VOTE_FAILED_MAP_NAME_REQUIRED;
				}
				
				case NativeVotesCallFail_Failed:
				{
					return CSGO_VOTE_FAILED_FAILED_RECENTLY;
				}
				
				case NativeVotesCallFail_WrongTeam:
				{
					return CSGO_VOTE_FAILED_TEAM_CANT_CALL;
				}
				
				case NativeVotesCallFail_Warmup:
				{
					return CSGO_VOTE_FAILED_WARMUP;
				}
				
				case NativeVotesCallFail_PlayerNotFound:
				{
					return CSGO_VOTE_FAILED_PLAYERNOTFOUND;
				}
				
				case NativeVotesCallFail_CantKickAdmin:
				{
					return CSGO_VOTE_FAILED_CANNOT_KICK_ADMIN;
				}
				
				case NativeVotesCallFail_ScramblePending:
				{
					return CSGO_VOTE_FAILED_SCRAMBLE_IN_PROGRESS;
				}
				
				case NativeVotesCallFail_Spectators:
				{
					return CSGO_VOTE_FAILED_SPECTATOR;
				}
				
				case NativeVotesCallFail_LevelSet:
				{
					return CSGO_VOTE_FAILED_NEXTLEVEL_SET;
				}
				
				case NativeVotesCallFail_KickFailed:
				{
					return CSGO_VOTE_FAILED_FAILED_RECENTLY_KICK;
				}
				
				case NativeVotesCallFail_MapFailed:
				{
					return CSGO_VOTE_FAILED_FAILED_RECENTLY_MAP;
				}
				
				case NativeVotesCallFail_SwapFailed:
				{
					return CSGO_VOTE_FAILED_FAILED_RECENTLY_SWAP;
				}
				
				case NativeVotesCallFail_ScrambleFailed:
				{
					return CSGO_VOTE_FAILED_FAILED_RECENTLY_SCRAMBLE;
				}
				
				case NativeVotesCallFail_RestartFailed:
				{
					return CSGO_VOTE_FAILED_FAILED_RECENTLY_RESTART;
				}
				
				case NativeVotesCallFail_SwapPending:
				{
					return CSGO_VOTE_FAILED_SWAP_IN_PROGRESS;
				}
				
				case NativeVotesCallFail_Unknown2:
				{
					return CSGO_VOTE_FAILED_UNKNOWN1;
				}
				
				case NativeVotesCallFail_CantSurrender:
				{
					return CSGO_VOTE_FAILED_SURRENDER_ABANDON;
				}
				
				case NativeVotesCallFail_Unknown3:
				{
					return CSGO_VOTE_FAILED_UNKNOWN2;
				}
				
				case NativeVotesCallFail_MatchPaused:
				{
					return CSGO_VOTE_FAILED_PAUSED;
				}
				
				case NativeVotesCallFail_NotPaused:
				{
					return CSGO_VOTE_FAILED_NOT_PAUSED;
				}
				
				case NativeVotesCallFail_NotWarmup:
				{
					return CSGO_VOTE_FAILED_NOT_WARMUP;
				}
				
				case NativeVotesCallFail_MinPlayers:
				{
					return CSGO_VOTE_FAILED_MIN_PLAYERS;
				}
				
				case NativeVotesCallFail_RoundEnded:
				{
					return CSGO_VOTE_FAILED_ROUND_ENDED;
				}
			}				
		}
	}
	
	return VOTE_FAILED_GENERIC;
}

static void GetEngineVersionName(EngineVersion version, char[] printName, int maxlength)
{
	switch (version)
	{
		case Engine_Unknown:
		{
			strcopy(printName, maxlength, "Unknown");
		}
		
		case Engine_Original:				
		{
			strcopy(printName, maxlength, "Original");
		}
		
		case Engine_SourceSDK2006:
		{
			strcopy(printName, maxlength, "Source SDK 2006");
		}
		
		case Engine_SourceSDK2007:
		{
			strcopy(printName, maxlength, "Source SDK 2007");
		}
		
		case Engine_Left4Dead:
		{
			strcopy(printName, maxlength, "Left 4 Dead ");
		}
		
		case Engine_DarkMessiah:
		{
			strcopy(printName, maxlength, "Dark Messiah");
		}
		
		case Engine_Left4Dead2:
		{
			strcopy(printName, maxlength, "Left 4 Dead 2");
		}
		
		case Engine_AlienSwarm:
		{
			strcopy(printName, maxlength, "Alien Swarm");
		}
		
		case Engine_BloodyGoodTime:
		{
			strcopy(printName, maxlength, "Bloody Good Time");
		}
		
		case Engine_EYE:
		{
			strcopy(printName, maxlength, "E.Y.E. Divine Cybermancy");
		}
		
		case Engine_Portal2:
		{
			strcopy(printName, maxlength, "Portal 2");
		}
		
		case Engine_CSGO:
		{
			strcopy(printName, maxlength, "Counter-Strike: Global Offensive");
		}
		
		case Engine_CSS:
		{
			strcopy(printName, maxlength, "Counter-Strike: Source");
		}
		
		case Engine_DOTA:
		{
			strcopy(printName, maxlength, "DOTA 2");
		}
		
		case Engine_HL2DM:
		{
			strcopy(printName, maxlength, "Half-Life 2: Deathmatch");
		}
		
		case Engine_DODS:
		{
			strcopy(printName, maxlength, "Day of Defeat: Source");
		}
		
		case Engine_TF2:
		{
			strcopy(printName, maxlength, "Team Fortress 2");
		}
		
		case Engine_NuclearDawn:
		{
			strcopy(printName, maxlength, "Nuclear Dawn");
		}
		
		default:
		{
			strcopy(printName, maxlength, "Not listed");
		}
	}
}



//----------------------------------------------------------------------------
// L4D/L4D2 shared functions

// NATIVEVOTES_VOTE_INVALID means parse failed
static int L4DL4D2_ParseVote(const char[] option)
{
	if (StrEqual(option, "Yes", false))
	{
		return NATIVEVOTES_VOTE_YES;
	}
	else if (StrEqual(option, "No", false))
	{
		return NATIVEVOTES_VOTE_NO;
	}
	
	return NATIVEVOTES_VOTE_INVALID;
}

static void L4DL4D2_ClientSelectedItem(int client, int item)
{
	int choice;
	
	if (item == NATIVEVOTES_VOTE_NO)
	{
		choice = 0;
	}
	else if (item == NATIVEVOTES_VOTE_YES)
	{
		choice = 1;
	}
	
	BfWrite voteCast = UserMessageToBfWrite(StartMessageOne("VoteRegistered", client, USERMSG_RELIABLE));
	voteCast.WriteByte(choice);
	EndMessage();
}

static void L4DL4D2_UpdateVoteCounts(ArrayList votes, int totalClients)
{
	int yesVotes = votes.Get(NATIVEVOTES_VOTE_YES);
	int noVotes = votes.Get(NATIVEVOTES_VOTE_NO);
	Event changeEvent = CreateEvent("vote_changed");
	changeEvent.SetInt("yesVotes", yesVotes);
	changeEvent.SetInt("noVotes", noVotes);
	changeEvent.SetInt("potentialVotes", totalClients);
	changeEvent.Fire();
	
	if (CheckVoteController())
	{
		SetEntProp(g_VoteController, Prop_Send, "m_votesYes", yesVotes);
		SetEntProp(g_VoteController, Prop_Send, "m_votesNo", noVotes);
	}
}

static stock void L4DL4D2_UpdateClientCount(int num_clients)
{
	if (CheckVoteController())
	{
		SetEntProp(g_VoteController, Prop_Send, "m_potentialVotes", num_clients);
	}
}

static void L4DL4D2_CallVoteFail(int client, int reason)
{
	BfWrite callVoteFail = UserMessageToBfWrite(StartMessageOne("CallVoteFailed", client, USERMSG_RELIABLE));

	callVoteFail.WriteByte(reason);
	
	EndMessage();
}

static void L4DL4D2_VoteTypeToTranslation(NativeVotesType voteType, char[] translation, int maxlength)
{
	switch(voteType)
	{
		case NativeVotesType_ChgCampaign:
		{
			strcopy(translation, maxlength, L4D_VOTE_CHANGECAMPAIGN_START);
		}
		
		case NativeVotesType_ChgDifficulty:
		{
			strcopy(translation, maxlength, L4D_VOTE_CHANGEDIFFICULTY_START);
		}
		
		case NativeVotesType_ReturnToLobby:
		{
			strcopy(translation, maxlength, L4D_VOTE_RETURNTOLOBBY_START);
		}
		
		case NativeVotesType_AlltalkOn, NativeVotesType_AlltalkOff:
		{
			strcopy(translation, maxlength, L4D2_VOTE_ALLTALK_START);
		}
		
		case NativeVotesType_Restart:
		{
			strcopy(translation, maxlength, L4D_VOTE_RESTART_START);
		}
		
		case NativeVotesType_Kick:
		{
			strcopy(translation, maxlength, L4D_VOTE_KICK_START);
		}
		
		case NativeVotesType_ChgLevel:
		{
			strcopy(translation, maxlength, L4D_VOTE_CHANGELEVEL_START);
		}
		
		default:
		{
			strcopy(translation, maxlength, L4D_VOTE_CUSTOM);
		}
	}
}

static void L4DL4D2_VotePassToTranslation(NativeVotesPassType passType, char[] translation, int maxlength)
{
	switch(passType)
	{
		case NativeVotesPass_Custom:
		{
			strcopy(translation, maxlength, L4D_VOTE_CUSTOM);
		}
		
		case NativeVotesPass_ChgCampaign:
		{
			strcopy(translation, maxlength, L4D_VOTE_CHANGECAMPAIGN_PASSED);
		}
		
		case NativeVotesPass_ChgDifficulty:
		{
			strcopy(translation, maxlength, L4D_VOTE_CHANGEDIFFICULTY_PASSED);
		}
		
		case NativeVotesPass_ReturnToLobby:
		{
			strcopy(translation, maxlength, L4D_VOTE_RETURNTOLOBBY_PASSED);
		}
		
		case NativeVotesPass_AlltalkOn, NativeVotesPass_AlltalkOff:
		{
			strcopy(translation, maxlength, L4D2_VOTE_ALLTALK_PASSED);
		}
		
		case NativeVotesPass_Restart:
		{
			strcopy(translation, maxlength, L4D_VOTE_RESTART_PASSED);
		}
		
		case NativeVotesPass_Kick:
		{
			strcopy(translation, maxlength, L4D_VOTE_KICK_PASSED);
		}
		
		case NativeVotesPass_ChgLevel:
		{
			strcopy(translation, maxlength, L4D_VOTE_CHANGELEVEL_PASSED);
		}
		
		default:
		{
			strcopy(translation, maxlength, L4D_VOTE_CUSTOM);
		}
	}
}

static void L4DL4D2_ResetVote()
{
	if (CheckVoteController())
	{
		SetEntProp(g_VoteController, Prop_Send, "m_activeIssueIndex", INVALID_ISSUE);
		SetEntProp(g_VoteController, Prop_Send, "m_votesYes", 0);
		SetEntProp(g_VoteController, Prop_Send, "m_votesNo", 0);
		SetEntProp(g_VoteController, Prop_Send, "m_potentialVotes", 0);
		SetEntProp(g_VoteController, Prop_Send, "m_onlyTeamToVote", NATIVEVOTES_ALL_TEAMS);
	}
}

static bool L4DL4D2_IsVoteInProgress()
{
	if (CheckVoteController())
	{	
		return (GetEntProp(g_VoteController, Prop_Send, "m_activeIssueIndex") > INVALID_ISSUE);
	}
	return false;
}

//----------------------------------------------------------------------------
// L4D functions

/*
static L4D_ClientSelectedItem(Handle:vote, client, item)
{
	if (item > NATIVEVOTES_VOTE_INVALID && item <= Game_GetMaxItems())
	{
		new Handle:castEvent;
		
		switch (item)
		{
			case NATIVEVOTES_VOTE_YES:
			{
				castEvent = CreateEvent("vote_cast_no");
			}
			
			case NATIVEVOTES_VOTE_NO:
			{
				castEvent = CreateEvent("vote_cast_yes");
			}
			
			default:
			{
				return;
			}
		}
		
		if (castEvent != INVALID_HANDLE)
		{
			SetEventInt(castEvent, "team", Data_GetTeam(vote));
			SetEventInt(castEvent, "entityid", client);
			FireEvent(castEvent);
		}
		
	}
}
*/

static void L4D_DisplayVote(NativeVote vote, int num_clients)
{
	char translation[TRANSLATION_LENGTH];

	NativeVotesType voteType = Data_GetType(vote);
	
	L4DL4D2_VoteTypeToTranslation(voteType, translation, sizeof(translation));

	char details[MAX_VOTE_DETAILS_LENGTH];
	Data_GetDetails(vote, details, MAX_VOTE_DETAILS_LENGTH);
	
	int team = Data_GetTeam(vote);
	
	if (CheckVoteController())
	{
		// TODO: Need to look these values up
		SetEntProp(g_VoteController, Prop_Send, "m_activeIssueIndex", 0); // For now, set to 0 to block in-game votes
		SetEntProp(g_VoteController, Prop_Send, "m_onlyTeamToVote", team);
		SetEntProp(g_VoteController, Prop_Send, "m_votesYes", 0);
		SetEntProp(g_VoteController, Prop_Send, "m_votesNo", 0);
		SetEntProp(g_VoteController, Prop_Send, "m_potentialVotes", num_clients);
	}

	Event voteStart = CreateEvent("vote_started");
	voteStart.SetInt("team", team);
	voteStart.SetInt("initiator", Data_GetInitiator(vote));
	voteStart.SetString("issue", translation);
	voteStart.SetString("param1", details);
	voteStart.Fire();
	
}

static void L4D_VoteEnded()
{
	Event endEvent = CreateEvent("vote_ended");
	endEvent.Fire();
}

static void L4D_VotePass(const char[] translation, const char[] details, int team)
{
	L4D_VoteEnded();
	
	Event passEvent = CreateEvent("vote_passed");
	passEvent.SetString("details", translation);
	passEvent.SetString("param1", details);
	passEvent.SetInt("team", team);
	passEvent.Fire();
}

static void L4D_VoteFail(int team)
{
	L4D_VoteEnded();

	Event failEvent = CreateEvent("vote_failed");
	failEvent.SetInt("team", team);
	failEvent.Fire();
}

static bool L4D_CheckVoteType(NativeVotesType voteType)
{
	switch(voteType)
	{
		case NativeVotesType_Custom_YesNo, NativeVotesType_ChgCampaign, NativeVotesType_ChgDifficulty,
		NativeVotesType_ReturnToLobby, NativeVotesType_Restart, NativeVotesType_Kick,
		NativeVotesType_ChgLevel:
		{
			return true;
		}
	}
	
	return false;
}

static bool L4D_CheckVotePassType(NativeVotesPassType passType)
{
	switch(passType)
	{
		case NativeVotesPass_Custom, NativeVotesPass_ChgCampaign, NativeVotesPass_ChgDifficulty,
		NativeVotesPass_ReturnToLobby, NativeVotesPass_Restart, NativeVotesPass_Kick,
		NativeVotesPass_ChgLevel:
		{
			return true;
		}
	}
	
	return false;
}

//----------------------------------------------------------------------------
// L4D2 functions

static void L4D2_DisplayVote(NativeVote vote, int[] clients, int num_clients)
{
	char translation[TRANSLATION_LENGTH];

	NativeVotesType voteType = Data_GetType(vote);
	
	L4DL4D2_VoteTypeToTranslation(voteType, translation, sizeof(translation));

	char details[MAX_VOTE_DETAILS_LENGTH];
	
	int team = Data_GetTeam(vote);
	bool bCustom = false;
	
	switch (voteType)
	{
		case NativeVotesType_AlltalkOn:
		{
			strcopy(details, MAX_VOTE_DETAILS_LENGTH, L4D2_VOTE_ALLTALK_ENABLE);
		}
		
		case NativeVotesType_AlltalkOff:
		{
			strcopy(details, MAX_VOTE_DETAILS_LENGTH, L4D2_VOTE_ALLTALK_DISABLE);
		}
		
		case NativeVotesType_Custom_YesNo, NativeVotesType_Custom_Mult:
		{
			Data_GetTitle(vote, details, MAX_VOTE_DETAILS_LENGTH);
			bCustom = true;
		}
		
		default:
		{
			Data_GetDetails(vote, details, MAX_VOTE_DETAILS_LENGTH);
		}
	}
	
	int initiator = Data_GetInitiator(vote);
	char initiatorName[MAX_NAME_LENGTH];

	if (initiator != NATIVEVOTES_SERVER_INDEX && initiator > 0 && initiator <= MaxClients && IsClientInGame(initiator))
	{
		GetClientName(initiator, initiatorName, MAX_NAME_LENGTH);
	}

	for (int i = 0; i < num_clients; ++i)
	{
		g_newMenuTitle[0] = '\0';
		
		MenuAction actions = Data_GetActions(vote);
		
		Action changeTitle = Plugin_Continue;
		if (bCustom && actions & MenuAction_Display)
		{
			g_curDisplayClient = clients[i];
			changeTitle = view_as<Action>(DoAction(vote, MenuAction_Display, clients[i], 0));
		}
		
		g_curDisplayClient = 0;
	
		BfWrite voteStart = UserMessageToBfWrite(StartMessageOne("VoteStart", clients[i], USERMSG_RELIABLE));
		voteStart.WriteByte(team);
		voteStart.WriteByte(initiator);
		voteStart.WriteString(translation);
		if (changeTitle == Plugin_Changed)
		{
			voteStart.WriteString(g_newMenuTitle);
		}
		else
		{
			voteStart.WriteString(details);
		}
		voteStart.WriteString(initiatorName);
		EndMessage();
	}
	
	if (CheckVoteController())
	{
		SetEntProp(g_VoteController, Prop_Send, "m_onlyTeamToVote", team);
		SetEntProp(g_VoteController, Prop_Send, "m_votesYes", 0);
		SetEntProp(g_VoteController, Prop_Send, "m_votesNo", 0);
		SetEntProp(g_VoteController, Prop_Send, "m_potentialVotes", num_clients);
		SetEntProp(g_VoteController, Prop_Send, "m_activeIssueIndex", 0); // Set to 0 to block ingame votes
	}
}

static void L4D2_VotePass(const char[] translation, const char[] details, int team, int client=0)
{
	BfWrite votePass;
	if (!client)
	{
		votePass = UserMessageToBfWrite(StartMessageAll("VotePass", USERMSG_RELIABLE));
	}
	else
	{
		votePass = UserMessageToBfWrite(StartMessageOne("VotePass", client, USERMSG_RELIABLE));
	}
	
	votePass.WriteByte(team);
	votePass.WriteString(translation);
	votePass.WriteString(details);
	EndMessage();
}

static void L4D2_VoteFail(int[] clients, int numClients, int team)
{
	BfWrite voteFailed = UserMessageToBfWrite(StartMessage("VoteFail", clients, numClients, USERMSG_RELIABLE));
	
	voteFailed.WriteByte(team);
	EndMessage();
}

static bool L4D2_CheckVoteType(NativeVotesType voteType)
{
	switch(voteType)
	{
		case NativeVotesType_Custom_YesNo, NativeVotesType_ChgCampaign, NativeVotesType_ChgDifficulty,
		NativeVotesType_ReturnToLobby, NativeVotesType_AlltalkOn, NativeVotesType_AlltalkOff,
		NativeVotesType_Restart, NativeVotesType_Kick, NativeVotesType_ChgLevel:
		{
			return true;
		}
	}
	
	return false;
}

static bool L4D2_CheckVotePassType(NativeVotesPassType passType)
{
	switch(passType)
	{
		case NativeVotesPass_Custom, NativeVotesPass_ChgCampaign, NativeVotesPass_ChgDifficulty,
		NativeVotesPass_ReturnToLobby, NativeVotesPass_AlltalkOn, NativeVotesPass_AlltalkOff,
		NativeVotesPass_Restart, NativeVotesPass_Kick, NativeVotesPass_ChgLevel:
		{
			return true;
		}
	}
	
	return false;
}

//----------------------------------------------------------------------------
// TF2/CSGO shared functions

// TF2 and CSGO functions are still together in case Valve moves TF2 to protobufs.

// NATIVEVOTES_VOTE_INVALID means parse failed
static int CSGO_ParseVote(const char[] option)
{
	// option1 <-- 7 characters exactly
	if (strlen(option) != 7)
	{
		return NATIVEVOTES_VOTE_INVALID;
	}

	return StringToInt(option[6]) - 1;
}

// NATIVEVOTES_VOTE_INVALID means parse failed
static int TF2_ParseVote(const char[] option)
{
	// the update on 2022-06-22 changed the params passed to the `vote` command
	// previously it was a single string "optionN", where N was the option to be selected
	// now it's two arguments "X optionN", where X is the vote index being acted on
	
	if (strlen(option) == 0 || GetCmdArgs() != 2)
	{
		return NATIVEVOTES_VOTE_INVALID;
	}
	
	// int voteidx = GetCmdArgInt(1);
	
	char voteOption[16];
	GetCmdArg(2, voteOption, sizeof(voteOption));
	
	// option1 <-- 7 characters exactly
	// voteOption's last character should be numeric
	if (strlen(voteOption) != 7 || !IsCharNumeric(voteOption[6]))
	{
		return NATIVEVOTES_VOTE_INVALID;
	}
	
	return StringToInt(voteOption[6]) - 1;
}

static void CSGO_ClientSelectedItem(NativeVote vote, int client, int item)
{
	Event castEvent = CreateEvent("vote_cast");
	
	castEvent.SetInt("team", Data_GetTeam(vote));
	castEvent.SetInt("entityid", client);
	castEvent.SetInt("vote_option", item);
	castEvent.Fire();
}

static void TF2_ClientSelectedItem(NativeVote vote, int client, int item)
{
	Event castEvent = CreateEvent("vote_cast");
	
	castEvent.SetInt("team", Data_GetTeam(vote));
	castEvent.SetInt("voteidx", s_nNativeVoteIdx); // TODO(UPDATE): this was added in 2022-06-22 - figure out what the client voted for
	castEvent.SetInt("entityid", client);
	castEvent.SetInt("vote_option", item);
	castEvent.Fire();
}

static void TF2CSGO_UpdateVoteCounts(ArrayList votes)
{
	if (CheckVoteController())
	{
		int size = votes.Length;
		for (int i = 0; i < size; i++)
		{
			SetEntProp(g_VoteController, Prop_Send, "m_nVoteOptionCount", votes.Get(i), 4, i);
		}
	}
}

static stock void TF2CSGO_UpdateClientCount(int num_clients)
{
	if (CheckVoteController())
	{
		SetEntProp(g_VoteController, Prop_Send, "m_nPotentialVotes", num_clients);
	}
}

static void TF2CSGO_DisplayVote(NativeVote vote, int[] clients, int num_clients)
{
	NativeVotesType voteType = Data_GetType(vote);
	
	// Added for novote support
	bool bNoVoteButton = (Data_GetFlags(vote) & MENUFLAG_BUTTON_NOVOTE) == MENUFLAG_BUTTON_NOVOTE;
	
	if (bNoVoteButton)
	{
		int max = Game_GetMaxItems();
		if (Data_GetItemCount(vote) == max)
		{
			// item must be removed before No Vote is added to prevent it from being blocked
			Data_RemoveItem(vote, max-1);
		}
		
		char display[TRANSLATION_LENGTH];
		Format(display, sizeof(display), "%T", "No Vote", LANG_SERVER);
		
		Data_InsertItem(vote, 0, "No Vote", display);
	}

	char translation[TRANSLATION_LENGTH];
	char otherTeamString[TRANSLATION_LENGTH];
	bool bYesNo = true;
	bool bCustom = false;
	
	char details[MAX_VOTE_DETAILS_LENGTH];
	
	// voteIndex is used by the CVoteController, which we're not using.
	// -1 means no vote in progress, so any other value should work.
	//int voteIndex = TF2CSGO_GetVoteType(voteType);
	int voteIndex = 0;
	
	switch (voteType)
	{
		case NativeVotesType_Custom_YesNo, NativeVotesType_Custom_Mult:
		{
			Data_GetTitle(vote, details, MAX_VOTE_DETAILS_LENGTH);
			bCustom = true;
		}
		
		default:
		{
			Data_GetDetails(vote, details, MAX_VOTE_DETAILS_LENGTH);
		}
	}
	
	switch(g_EngineVersion)
	{
		case Engine_CSGO:
		{
			bYesNo = CSGO_VoteTypeToTranslation(voteType, translation, sizeof(translation));
			CSGO_VoteTypeToVoteOtherTeamString(voteType, otherTeamString, sizeof(otherTeamString));
		}
		
		case Engine_TF2:
		{
			bYesNo = TF2_VoteTypeToTranslation(voteType, translation, sizeof(translation));
		}
	}
	
	int team = Data_GetTeam(vote);
	
	// Moved to mimic SourceSDK2013's server/vote_controller.cpp
	if (CheckVoteController())
	{
		SetEntProp(g_VoteController, Prop_Send, "m_bIsYesNoVote", bYesNo);
		
		// CSGO gets very cranky if you try setting this
		if (g_EngineVersion == Engine_TF2)
			SetEntProp(g_VoteController, Prop_Send, "m_iActiveIssueIndex", voteIndex);
			
		SetEntProp(g_VoteController, Prop_Send, "m_iOnlyTeamToVote", team);
		for (int i = 0; i < 5; i++)
		{
			SetEntProp(g_VoteController, Prop_Send, "m_nVoteOptionCount", 0, _, i);
		}
		
		// TODO(UPDATE): M-M-M-MULTIVOTE
		// we need unique vote indices; HUD elements for previous votes aren't cleaned up (?)
		// the game implements this as `this->m_nVoteIdx = s_nVoteIdx++`
		s_nNativeVoteIdx = GetEntProp(g_VoteController, Prop_Send, "m_nVoteIdx");
#if defined LOG
		PrintToServer("Starting vote index: %d (controller: %d)", s_nNativeVoteIdx, GetEntProp(g_VoteController, Prop_Send, "m_nVoteIdx"));
#endif
		SetEntProp(g_VoteController, Prop_Send, "m_nVoteIdx", s_nNativeVoteIdx + 1); // TODO(UPDATE)
	}
	
	// According to Source SDK 2013, vote_options is only sent for a multiple choice vote.
	// As of 2015-09-28, vote_options is sent for all votes in TF2 despite Yes/No being
	// translated in the UI itself.
	// As of 2016-07-10, we send this only when we're doing Yes/No votes as we handle
	// multiple choice votes separately later.
	if (bYesNo)
	{
		int itemCount = Data_GetItemCount(vote);
		
		Event optionsEvent = CreateEvent("vote_options");
		
		for (int i = 0; i < itemCount; i++)
		{
			char option[8];
			Format(option, sizeof(option), "%s%d", TF2CSGO_VOTE_PREFIX, i+1);
			
			char display[TRANSLATION_LENGTH];
			Data_GetItemDisplay(vote, i, display, sizeof(display));
			optionsEvent.SetString(option, display);
		}
		optionsEvent.SetInt("count", itemCount);
		optionsEvent.SetInt("voteidx", s_nNativeVoteIdx); // TODO(UPDATE)
		optionsEvent.Fire();
	}
	
	// Moved to mimic SourceSDK2013's server/vote_controller.cpp
	// For whatever reason, while the other props are set first, this one's set after the vote_options event
	if (CheckVoteController())
	{
		SetEntProp(g_VoteController, Prop_Send, "m_nPotentialVotes", num_clients);
	}

	// required to allow the initiator to vote on their own issue
	// ValveSoftware/Source-1-Games#3934
	if (sv_vote_holder_may_vote_no && vote.Initiator <= MaxClients)
	{
		sv_vote_holder_may_vote_no.ReplicateToClient(vote.Initiator, "1");
	}

	MenuAction actions = Data_GetActions(vote);

	for (int i = 0; i < num_clients; ++i)
	{
		g_newMenuTitle[0] = '\0';
		
		Action changeTitle = Plugin_Continue;
		if (bCustom && actions & MenuAction_Display)
		{
			g_curDisplayClient = clients[i];
			changeTitle = DoAction(vote, MenuAction_Display, clients[i], 0);
		}
		
		g_curDisplayClient = 0;
		
		if (!bYesNo)
		{
			TF2CSGO_SendOptionsToClient(vote, clients[i]);
		}
		
		Handle voteStart = StartMessageOne("VoteStart", clients[i], USERMSG_RELIABLE);
		
		if(g_bUserBuf)
		{
			Protobuf protoStart = UserMessageToProtobuf(voteStart);
			protoStart.SetInt("team", team);
			protoStart.SetInt("ent_idx", Data_GetInitiator(vote));
			protoStart.SetString("disp_str", translation);
			if (bCustom && changeTitle == Plugin_Changed)
			{
				protoStart.SetString("details_str", g_newMenuTitle);
			}
			else
			{
				protoStart.SetString("details_str", details);
			}
			protoStart.SetBool("is_yes_no_vote", bYesNo);
			protoStart.SetString("other_team_str", otherTeamString);
			protoStart.SetInt("vote_type", voteIndex);
		}
		else
		{
			BfWrite bfStart = UserMessageToBfWrite(voteStart);
			bfStart.WriteByte(team);
			bfStart.WriteNum(s_nNativeVoteIdx);
			bfStart.WriteByte(Data_GetInitiator(vote));
			bfStart.WriteString(translation);
			if (bCustom && changeTitle == Plugin_Changed)
			{
				bfStart.WriteString(g_newMenuTitle);
			}
			else
			{
				bfStart.WriteString(details);
			}
			bfStart.WriteBool(bYesNo);
		}
		
		EndMessage();
	}
	
	g_curDisplayClient = 0;
	
}

static void TF2CSGO_SendOptionsToClient(NativeVote vote, int client)
{
	Event optionsEvent = CreateEvent("vote_options");
	
	MenuAction actions = Data_GetActions(vote);
	bool bNoVoteButton = (Data_GetFlags(vote) & MENUFLAG_BUTTON_NOVOTE) == MENUFLAG_BUTTON_NOVOTE;

	int start = 0;
	
	if (bNoVoteButton)
	{
		start = 1;
		char option[8];
		Format(option, sizeof(option), "%s1", TF2CSGO_VOTE_PREFIX);
		
		char display[TRANSLATION_LENGTH];
		Format(display, sizeof(display), "%T", "No Vote", client);
		optionsEvent.SetString(option, display);
	}
	
	int itemCount = Data_GetItemCount(vote);
	
	for (int i = start; i < itemCount; i++)
	{
		Action changeItem = Plugin_Continue;
		
		if (actions & MenuAction_DisplayItem)
		{
			g_curItemClient = client;
			g_newMenuItem[0] = '\0';
			
			changeItem = DoAction(vote, MenuAction_DisplayItem, client, i);
			g_curItemClient = 0;
		}
		
		char option[8];
		Format(option, sizeof(option), "%s%d", TF2CSGO_VOTE_PREFIX, i+1);
		char display[TRANSLATION_LENGTH];

		if (changeItem == Plugin_Changed)
		{
			strcopy(display, TRANSLATION_LENGTH, g_newMenuItem);
		}
		else
		{
			Data_GetItemDisplay(vote, i, display, sizeof(display));
		}
		optionsEvent.SetString(option, display);
	}
	optionsEvent.SetInt("count", itemCount);
	optionsEvent.SetInt("voteidx", s_nNativeVoteIdx); // TODO(UPDATE)
	optionsEvent.FireToClient(client);
	// FireToClient does not close the handle, so we call Cancel() to do that for us.
	optionsEvent.Cancel();
}

static void CSGO_VotePass(const char[] translation, const char[] details, int team, int client=0)
{
	Protobuf votePass = null;
	
	if (!client)
	{
		votePass = UserMessageToProtobuf(StartMessageAll("VotePass", USERMSG_RELIABLE));
	}
	else
	{
		votePass = UserMessageToProtobuf(StartMessageOne("VotePass", client, USERMSG_RELIABLE));
	}

	votePass.SetInt("team", team);
	votePass.SetString("disp_str", translation);
	votePass.SetString("details_str", details);
	votePass.SetInt("vote_type", 0); // Unknown, need to check values

	EndMessage();
}

static void TF2_VotePass(const char[] translation, const char[] details, int team, int client=0)
{
	BfWrite votePass = null;
	
	if (!client)
	{
		votePass = UserMessageToBfWrite(StartMessageAll("VotePass", USERMSG_RELIABLE));
	}
	else
	{
		votePass = UserMessageToBfWrite(StartMessageOne("VotePass", client, USERMSG_RELIABLE));
	}

	votePass.WriteByte(team);
	votePass.WriteNum(s_nNativeVoteIdx);
	votePass.WriteString(translation);
	votePass.WriteString(details);

	EndMessage();
}

static void CSGO_VoteFail(int[] clients, int numClients, int reason, int team)
{
	Protobuf voteFailed = UserMessageToProtobuf(StartMessage("VoteFailed", clients, numClients, USERMSG_RELIABLE));
	
	voteFailed.SetInt("team", team);
	voteFailed.SetInt("reason", reason);

	EndMessage();
}

static void TF2_VoteFail(int[] clients, int numClients, int reason, int team)
{
	BfWrite voteFailed = UserMessageToBfWrite(StartMessage("VoteFailed", clients, numClients, USERMSG_RELIABLE));
	
	voteFailed.WriteByte(team);
	voteFailed.WriteNum(s_nNativeVoteIdx); // TODO(UPDATE)
	voteFailed.WriteByte(reason);

	EndMessage();
}

static void CSGO_CallVoteFail(int client, int reason, int time)
{
	Protobuf callVoteFail = UserMessageToProtobuf(StartMessageOne("CallVoteFailed", client, USERMSG_RELIABLE));

	callVoteFail.SetInt("reason", reason);
	callVoteFail.SetInt("time", time);

	EndMessage();
}

static void TF2_CallVoteFail(int client, int reason, int time)
{
	BfWrite callVoteFail = UserMessageToBfWrite(StartMessageOne("CallVoteFailed", client, USERMSG_RELIABLE));

	callVoteFail.WriteByte(reason);
	callVoteFail.WriteShort(time);

	EndMessage();
}

stock static void CSGO_DisplayVoteSetup(int client, ArrayList hVoteTypes)
{
	int count = hVoteTypes.Length;
	
	Protobuf voteSetup = UserMessageToProtobuf(StartMessageOne("VoteSetup", client, USERMSG_RELIABLE));
	
	for (int i = 0; i < count; ++i)
	{
		char voteIssue[128];
		
		CallVoteListData voteData;
		hVoteTypes.GetArray(i, voteData.CallVoteList_VoteType);
		
		Game_OverrideTypeToVoteString(voteData.CallVoteList_VoteType, voteIssue, sizeof(voteIssue));
		
		
		voteSetup.AddString("potential_issues", voteIssue);
	}
	
	EndMessage();
}

static void TF2_DisplayVoteSetup(int client, ArrayList hVoteTypes)
{
	int count = hVoteTypes.Length;
	
	BfWrite voteSetup = UserMessageToBfWrite(StartMessageOne("VoteSetup", client, USERMSG_RELIABLE));
	
	voteSetup.WriteByte(count);
	
	for (int i = 0; i < count; ++i)
	{
		char voteIssue[128];
		
		CallVoteListData voteData;
		hVoteTypes.GetArray(i, voteData, sizeof(CallVoteListData));
		
		Game_OverrideTypeToVoteString(voteData.CallVoteList_VoteType, voteIssue, sizeof(voteIssue));
		
		char translation[128];
		Game_OverrideTypeToTranslationString(voteData.CallVoteList_VoteType, translation, sizeof(translation));
		
		voteSetup.WriteString(voteIssue);
		voteSetup.WriteString(translation);
		voteSetup.WriteByte(voteData.CallVoteList_VoteEnabled);
	}
	
	EndMessage();
}

static void TF2CSGO_ResetVote()
{
	if (CheckVoteController())
	{	
		if (g_EngineVersion == Engine_TF2)
		{
			SetEntProp(g_VoteController, Prop_Send, "m_iActiveIssueIndex", INVALID_ISSUE);
			SetEntProp(g_VoteController, Prop_Send, "m_nVoteIdx", -1); // TODO(UPDATE)
		}
		
		for (int i = 0; i < 5; i++)
		{
			SetEntProp(g_VoteController, Prop_Send, "m_nVoteOptionCount", 0, _, i);
		}
		SetEntProp(g_VoteController, Prop_Send, "m_nPotentialVotes", 0);
		if (g_EngineVersion == Engine_TF2)
		{
			SetEntProp(g_VoteController, Prop_Send, "m_iOnlyTeamToVote", NATIVEVOTES_TF2_ALL_TEAMS);
		}
		else
		{
			SetEntProp(g_VoteController, Prop_Send, "m_iOnlyTeamToVote", NATIVEVOTES_ALL_TEAMS);
		}
		SetEntProp(g_VoteController, Prop_Send, "m_bIsYesNoVote", true);
	}
}

static bool TF2CSGO_IsVoteInProgress()
{
	if (CheckVoteController())
	{	
		return (GetEntProp(g_VoteController, Prop_Send, "m_iActiveIssueIndex") != INVALID_ISSUE);
	}
	return false;
}


//----------------------------------------------------------------------------
// TF2 functions

static bool TF2_CheckVoteType(NativeVotesType voteType)
{
	switch(voteType)
	{
		case NativeVotesType_Custom_YesNo, NativeVotesType_Restart,
		NativeVotesType_Kick, NativeVotesType_KickIdle, NativeVotesType_KickScamming, NativeVotesType_KickCheating,
		NativeVotesType_ChgLevel, NativeVotesType_NextLevel, NativeVotesType_ScrambleNow, NativeVotesType_ScrambleEnd,
		NativeVotesType_ChgMission, NativeVotesType_StartRound, NativeVotesType_Eternaween,
		NativeVotesType_AutoBalanceOn, NativeVotesType_AutoBalanceOff,
		NativeVotesType_ClassLimitsOn, NativeVotesType_ClassLimitsOff, NativeVotesType_Extend:
		{
			return true;
		}
		
		case NativeVotesType_Custom_Mult, NativeVotesType_NextLevelMult:
		{
			return true;
		}
	}
	
	return false;
}

static bool TF2_CheckVotePassType(NativeVotesPassType passType)
{
	switch(passType)
	{
		case NativeVotesPass_Custom, NativeVotesPass_Restart, NativeVotesPass_ChgLevel,
		NativeVotesPass_Kick, NativeVotesPass_NextLevel, NativeVotesPass_Extend,
		NativeVotesPass_Scramble, NativeVotesPass_ChgMission, NativeVotesPass_StartRound, NativeVotesPass_Eternaween,
		NativeVotesPass_AutoBalanceOn, NativeVotesPass_AutoBalanceOff,
		NativeVotesPass_ClassLimitsOn, NativeVotesPass_ClassLimitsOff:
		{
			return true;
		}
	}
	
	return false;
}

static bool TF2_VoteTypeToTranslation(NativeVotesType voteType, char[] translation, int maxlength)
{
	bool bYesNo = true;
	switch(voteType)
	{
		case NativeVotesType_Custom_Mult:
		{
			strcopy(translation, maxlength, TF2_VOTE_CUSTOM);
			bYesNo = false;
		}
		
		case NativeVotesType_Restart:
		{
			strcopy(translation, maxlength, TF2_VOTE_RESTART_START);
		}
		
		case NativeVotesType_Kick:
		{
			strcopy(translation, maxlength, TF2_VOTE_KICK_START);
		}
		
		case NativeVotesType_KickIdle:
		{
			strcopy(translation, maxlength, TF2_VOTE_KICK_IDLE_START);
		}
		
		case NativeVotesType_KickScamming:
		{
			strcopy(translation, maxlength, TF2_VOTE_KICK_SCAMMING_START);
		}
		
		case NativeVotesType_KickCheating:
		{
			strcopy(translation, maxlength, TF2_VOTE_KICK_CHEATING_START);
		}
		
		case NativeVotesType_ChgLevel:
		{
			strcopy(translation, maxlength, TF2_VOTE_CHANGELEVEL_START);
		}
		
		case NativeVotesType_NextLevel:
		{
			strcopy(translation, maxlength, TF2_VOTE_NEXTLEVEL_SINGLE_START);
		}
		
		case NativeVotesType_NextLevelMult:
		{
			
			strcopy(translation, maxlength, TF2_VOTE_NEXTLEVEL_MULTIPLE_START);
			bYesNo = false;
		}
		
		case NativeVotesType_ScrambleNow:
		{
			strcopy(translation, maxlength, TF2_VOTE_SCRAMBLE_IMMEDIATE_START);
		}
		
		case NativeVotesType_ScrambleEnd:
		{
			strcopy(translation, maxlength, TF2_VOTE_SCRAMBLE_ROUNDEND_START);
		}
		
		case NativeVotesType_ChgMission:
		{
			strcopy(translation, maxlength, TF2_VOTE_CHANGEMISSION_START);
		}
		
		case NativeVotesType_StartRound:
		{
			strcopy(translation, maxlength, TF2_VOTE_ROUND_START);
		}
		
		case NativeVotesType_Eternaween:
		{
			strcopy(translation, maxlength, TF2_VOTE_ETERNAWEEN_START);
		}
		
		case NativeVotesType_AutoBalanceOn:
		{
			strcopy(translation, maxlength, TF2_VOTE_AUTOBALANCE_ENABLE_START);
		}
		
		case NativeVotesType_AutoBalanceOff:
		{
			strcopy(translation, maxlength, TF2_VOTE_AUTOBALANCE_DISABLE_START);
		}
		
		case NativeVotesType_ClassLimitsOn:
		{
			strcopy(translation, maxlength, TF2_VOTE_CLASSLIMITS_ENABLE_START);
		}
		
		case NativeVotesType_ClassLimitsOff:
		{
			strcopy(translation, maxlength, TF2_VOTE_CLASSLIMITS_DISABLE_START);
		}
		
		case NativeVotesType_Extend:
		{
			strcopy(translation, maxlength, TF2_VOTE_EXTEND_START);
		}
		
		default:
		{
			strcopy(translation, maxlength, TF2_VOTE_CUSTOM);
		}
	}
	
	return bYesNo;
}

static void TF2_VotePassToTranslation(NativeVotesPassType passType, char[] translation, int maxlength)
{
	switch(passType)
	{
		case NativeVotesPass_Restart:
		{
			strcopy(translation, maxlength, TF2_VOTE_RESTART_PASSED);
		}
		
		case NativeVotesPass_Kick:
		{
			strcopy(translation, maxlength, TF2_VOTE_KICK_PASSED);
		}
		
		case NativeVotesPass_ChgLevel:
		{
			strcopy(translation, maxlength, TF2_VOTE_CHANGELEVEL_PASSED);
		}
		
		case NativeVotesPass_NextLevel:
		{
			strcopy(translation, maxlength, TF2_VOTE_NEXTLEVEL_PASSED);
		}
		
		case NativeVotesPass_Extend:
		{
			strcopy(translation, maxlength, TF2_VOTE_NEXTLEVEL_EXTEND_PASSED);
		}
		
		case NativeVotesPass_Scramble:
		{
			strcopy(translation, maxlength, TF2_VOTE_SCRAMBLE_PASSED);
		}

		case NativeVotesPass_ChgMission:
		{
			strcopy(translation, maxlength, TF2_VOTE_CHANGEMISSION_PASSED);
		}
		
		case NativeVotesPass_StartRound:
		{
			strcopy(translation, maxlength, TF2_VOTE_ROUND_PASSED);
		}
		
		case NativeVotesPass_Eternaween:
		{
			strcopy(translation, maxlength, TF2_VOTE_ETERNAWEEN_PASSED);
		}
		
		case NativeVotesPass_AutoBalanceOn:
		{
			strcopy(translation, maxlength, TF2_VOTE_AUTOBALANCE_ENABLE_PASSED);
		}
		
		case NativeVotesPass_AutoBalanceOff:
		{
			strcopy(translation, maxlength, TF2_VOTE_AUTOBALANCE_DISABLE_PASSED);
		}
		
		case NativeVotesPass_ClassLimitsOn:
		{
			strcopy(translation, maxlength, TF2_VOTE_CLASSLIMITS_ENABLE_PASSED);
		}
		
		case NativeVotesPass_ClassLimitsOff:
		{
			strcopy(translation, maxlength, TF2_VOTE_CLASSLIMITS_DISABLE_PASSED);
		}
		
		default:
		{
			strcopy(translation, maxlength, TF2_VOTE_CUSTOM);
		}
	}
}

static void TF2_AddDefaultVotes(ArrayList hVoteTypes, bool bHideDisabledVotes)
{
	int globalEnable = g_Cvar_Votes_Enabled.BoolValue;
	if (!globalEnable && bHideDisabledVotes)
	{
		return;
	}

	if (GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		// Default MvM vote types
		
		// Kick
		VoteTypeSet(hVoteTypes, bHideDisabledVotes, NativeVotesOverride_Kick, globalEnable && g_Cvar_MvM_VoteKick_Enabled.BoolValue);
		
		// Restart
		VoteTypeSet(hVoteTypes, bHideDisabledVotes, NativeVotesOverride_Restart, globalEnable && g_Cvar_MvM_VoteRestart_Enabled.BoolValue);
		
		// ChgLevel
		VoteTypeSet(hVoteTypes, bHideDisabledVotes, NativeVotesOverride_ChgLevel, globalEnable && g_Cvar_MvM_VoteChangeLevel_Enabled.BoolValue);
		
		// ChgMission
		VoteTypeSet(hVoteTypes, bHideDisabledVotes, NativeVotesOverride_ChgMission, globalEnable && g_Cvar_MvM_VoteChallenge_Enabled.BoolValue);
		
		// ClassLimits
		VoteTypeSet(hVoteTypes, bHideDisabledVotes, NativeVotesOverride_ClassLimits, globalEnable && g_Cvar_MvM_VoteClassLimits_Enabled.BoolValue);
	}
	else
	{
		// Default vote types

		// Kick
		VoteTypeSet(hVoteTypes, bHideDisabledVotes, NativeVotesOverride_Kick, globalEnable && g_Cvar_VoteKick_Enabled.BoolValue);
		
		// Restart
		VoteTypeSet(hVoteTypes, bHideDisabledVotes, NativeVotesOverride_Restart, globalEnable && g_Cvar_VoteRestart_Enabled.BoolValue);
		
		// ChgLevel
		VoteTypeSet(hVoteTypes, bHideDisabledVotes, NativeVotesOverride_ChgLevel, globalEnable && g_Cvar_VoteChangeLevel_Enabled.BoolValue);
		
		// NextLevel
		VoteTypeSet(hVoteTypes, bHideDisabledVotes, NativeVotesOverride_NextLevel, globalEnable && g_Cvar_VoteNextLevel_Enabled.BoolValue);
		
		// Scramble
		VoteTypeSet(hVoteTypes, bHideDisabledVotes, NativeVotesOverride_Scramble, globalEnable && g_Cvar_VoteScramble_Enabled.BoolValue);
		
		// ClassLimits
		VoteTypeSet(hVoteTypes, bHideDisabledVotes, NativeVotesOverride_ClassLimits, globalEnable && g_Cvar_VoteClassLimits_Enabled.BoolValue);
		
		// AutoBalance
		VoteTypeSet(hVoteTypes, bHideDisabledVotes, NativeVotesOverride_AutoBalance, globalEnable && g_Cvar_VoteAutoBalance_Enabled.BoolValue);
		
		// Extend
		VoteTypeSet(hVoteTypes, bHideDisabledVotes, NativeVotesOverride_Extend, globalEnable && g_Cvar_VoteExtend_Enabled.BoolValue);
	}
	
}

static void VoteTypeSet(ArrayList hVoteTypes, bool bHideDisabledVotes, NativeVotesOverride voteType, bool bEnabled)
{
	CallVoteListData voteList;
	
	if (bEnabled || !bHideDisabledVotes)
	{
		voteList.CallVoteList_VoteType = voteType;
		voteList.CallVoteList_VoteEnabled = bEnabled;
		
		hVoteTypes.PushArray(voteList);
	}
}

//----------------------------------------------------------------------------
// CSGO functions

static bool CSGO_CheckVoteType(NativeVotesType voteType)
{
	switch(voteType)
	{
		case NativeVotesType_Custom_YesNo, NativeVotesType_Restart,
		NativeVotesType_Kick, NativeVotesType_KickIdle, NativeVotesType_KickScamming, NativeVotesType_KickCheating,
		NativeVotesType_ChgLevel, NativeVotesType_NextLevel, NativeVotesType_ScrambleNow, NativeVotesType_SwapTeams,
		NativeVotesType_Surrender, NativeVotesType_Rematch, NativeVotesType_Continue:
		{
			return true;
		}
		
		case NativeVotesType_Custom_Mult, NativeVotesType_NextLevelMult:
		{
			// Until/unless Valve fixes their menu code, this is false.
			return false;
		}
		
	}
	
	return false;
}

static bool CSGO_CheckVotePassType(NativeVotesPassType passType)
{
	switch(passType)
	{
		case NativeVotesPass_Custom, NativeVotesPass_Restart, NativeVotesPass_Kick,
		NativeVotesPass_ChgLevel, NativeVotesPass_NextLevel, NativeVotesPass_Extend,
		NativeVotesPass_Scramble, NativeVotesPass_SwapTeams, NativeVotesPass_Surrender,
		NativeVotesPass_Rematch, NativeVotesPass_Continue:
		{
			return true;
		}
	}
	
	return false;
}

static bool CSGO_VoteTypeToTranslation(NativeVotesType voteType, char[] translation, int maxlength)
{
	bool bYesNo = true;
	switch(voteType)
	{
		case NativeVotesType_Custom_Mult:
		{
			strcopy(translation, maxlength, CSGO_VOTE_CUSTOM);
			bYesNo = false;
		}
		
		case NativeVotesType_Restart:
		{
			strcopy(translation, maxlength, CSGO_VOTE_RESTART_START);
		}
		
		case NativeVotesType_Kick:
		{
			strcopy(translation, maxlength, CSGO_VOTE_KICK_START);
		}
		
		case NativeVotesType_KickIdle:
		{
			strcopy(translation, maxlength, CSGO_VOTE_KICK_IDLE_START);
		}
		
		case NativeVotesType_KickScamming:
		{
			strcopy(translation, maxlength, CSGO_VOTE_KICK_SCAMMING_START);
		}
		
		case NativeVotesType_KickCheating:
		{
			strcopy(translation, maxlength, CSGO_VOTE_KICK_CHEATING_START);
		}
		
		case NativeVotesType_ChgLevel:
		{
			strcopy(translation, maxlength, CSGO_VOTE_CHANGELEVEL_START);
		}
		
		case NativeVotesType_NextLevel:
		{
			strcopy(translation, maxlength, CSGO_VOTE_NEXTLEVEL_SINGLE_START);
		}
		
		case NativeVotesType_NextLevelMult:
		{
			
			strcopy(translation, maxlength, CSGO_VOTE_NEXTLEVEL_MULTIPLE_START);
			bYesNo = false;
		}
		
		case NativeVotesType_ScrambleNow:
		{
			strcopy(translation, maxlength, CSGO_VOTE_SCRAMBLE_START);
		}
		
		case NativeVotesType_SwapTeams:
		{
			strcopy(translation, maxlength, CSGO_VOTE_SWAPTEAMS_START);
		}
		
		case NativeVotesType_Surrender:
		{
			strcopy(translation, maxlength, CSGO_VOTE_SURRENDER_START);
		}
		
		case NativeVotesType_Rematch:
		{
			strcopy(translation, maxlength, CSGO_VOTE_REMATCH_START);
		}
		
		case NativeVotesType_Continue:
		{
			strcopy(translation, maxlength, CSGO_VOTE_CONTINUE_START);
		}
		
		default:
		{
			strcopy(translation, maxlength, CSGO_VOTE_CUSTOM);
		}
	}
	
	return bYesNo;
}

static void CSGO_VotePassToTranslation(NativeVotesPassType passType, char[] translation, int maxlength)
{
	switch(passType)
	{
		case NativeVotesPass_Restart:
		{
			strcopy(translation, maxlength, CSGO_VOTE_RESTART_PASSED);
		}
		
		case NativeVotesPass_Kick:
		{
			strcopy(translation, maxlength, CSGO_VOTE_KICK_PASSED);
		}
		
		case NativeVotesPass_ChgLevel:
		{
			strcopy(translation, maxlength, CSGO_VOTE_CHANGELEVEL_PASSED);
		}
		
		case NativeVotesPass_NextLevel:
		{
			strcopy(translation, maxlength, CSGO_VOTE_NEXTLEVEL_PASSED);
		}
		
		case NativeVotesPass_Extend:
		{
			strcopy(translation, maxlength, CSGO_VOTE_NEXTLEVEL_EXTEND_PASSED);
		}
		
		case NativeVotesPass_Scramble:
		{
			strcopy(translation, maxlength, CSGO_VOTE_SCRAMBLE_PASSED);
		}
		
		case NativeVotesPass_SwapTeams:
		{
			strcopy(translation, maxlength, CSGO_VOTE_SWAPTEAMS_PASSED);
		}
		
		case NativeVotesPass_Surrender:
		{
			strcopy(translation, maxlength, CSGO_VOTE_SURRENDER_PASSED);
		}
		
		case NativeVotesPass_Rematch:
		{
			strcopy(translation, maxlength, CSGO_VOTE_REMATCH_PASSED);
		}
		
		case NativeVotesPass_Continue:
		{
			strcopy(translation, maxlength, CSGO_VOTE_CONTINUE_PASSED);
		}
		
		default:
		{
			strcopy(translation, maxlength, CSGO_VOTE_CUSTOM);
		}
	}
}

static void CSGO_VoteTypeToVoteOtherTeamString(NativeVotesType voteType, char[] otherTeamString, int maxlength)
{
	switch(voteType)
	{
		case NativeVotesType_Kick:
		{
			strcopy(otherTeamString, maxlength, CSGO_VOTE_KICK_OTHERTEAM);
		}
		
		case NativeVotesType_Surrender:
		{
			strcopy(otherTeamString, maxlength, CSGO_VOTE_SURRENDER_OTHERTEAM);
		}
		
		case NativeVotesType_Continue:
		{
			strcopy(otherTeamString, maxlength, CSGO_VOTE_CONTINUE_OTHERTEAM);
		}
		
		default:
		{
			strcopy(otherTeamString, maxlength, CSGO_VOTE_UNIMPLEMENTED_OTHERTEAM);
		}
	}

}

static stock int TF2CSGO_GetVoteType(NativeVotesType voteType)
{
	int valveVoteType = ValveVote_Restart;
	
	switch (voteType)
	{
		case NativeVotesType_Custom_YesNo, NativeVotesType_Restart:
		{
			valveVoteType = ValveVote_Restart;
		}
		
		case NativeVotesType_Custom_Mult, NativeVotesType_NextLevel, NativeVotesType_NextLevelMult:
		{
			valveVoteType = ValveVote_NextLevel;
		}
		
		case NativeVotesType_Kick, NativeVotesType_KickIdle, NativeVotesType_KickScamming, NativeVotesType_KickCheating:
		{
			valveVoteType = ValveVote_Kick;
		}
		
		case NativeVotesType_ChgLevel:
		{
			valveVoteType = ValveVote_ChangeLevel;
		}
		
		case NativeVotesType_ScrambleNow, NativeVotesType_ScrambleEnd:
		{
			valveVoteType = ValveVote_Scramble;
		}
		
		case NativeVotesType_SwapTeams:
		{
			valveVoteType = ValveVote_SwapTeams;
		}
	}
	
	return valveVoteType;
}

// The stocks below are used by the vote override system
// Not all are used by the plugin
static stock bool TF2_VoteTypeToVoteString(NativeVotesType voteType, char[] voteString, int maxlength)
{
	bool valid = false;
	switch(voteType)
	{
		case NativeVotesType_Kick, NativeVotesType_KickCheating, NativeVotesType_KickIdle, NativeVotesType_KickScamming:
		{
			strcopy(voteString, maxlength, TF2CSGO_VOTE_STRING_KICK);
			valid = true;
		}
		
		case NativeVotesType_ChgLevel:
		{
			strcopy(voteString, maxlength, TF2CSGO_VOTE_STRING_CHANGELEVEL);
			valid = true;
		}
		
		case NativeVotesType_NextLevel:
		{
			strcopy(voteString, maxlength, TF2CSGO_VOTE_STRING_NEXTLEVEL);
			valid = true;
		}
		
		case NativeVotesType_Restart:
		{
			strcopy(voteString, maxlength, TF2CSGO_VOTE_STRING_RESTART);
			valid = true;
		}
		
		case NativeVotesType_ScrambleEnd, NativeVotesType_ScrambleNow:
		{
			strcopy(voteString, maxlength, TF2CSGO_VOTE_STRING_SCRAMBLE);
			valid = true;
		}
		
		case NativeVotesType_Eternaween:
		{
			strcopy(voteString, maxlength, TF2_VOTE_STRING_ETERNAWEEN);
			valid = true;
		}
		
		case NativeVotesType_AutoBalanceOn:
		{
			strcopy(voteString, maxlength, TF2_VOTE_STRING_AUTOBALANCE);
			valid = true;
		}
		
		case NativeVotesType_AutoBalanceOff:
		{
			strcopy(voteString, maxlength, TF2_VOTE_STRING_AUTOBALANCE);
			valid = true;
		}
		
		case NativeVotesType_ClassLimitsOn:
		{
			strcopy(voteString, maxlength, TF2_VOTE_STRING_CLASSLIMIT);
			valid = true;
		}
		
		case NativeVotesType_ClassLimitsOff:
		{
			strcopy(voteString, maxlength, TF2_VOTE_STRING_CLASSLIMIT);
			valid = true;
		}
		
		case NativeVotesType_Extend:
		{
			strcopy(voteString, maxlength, TF2_VOTE_STRING_EXTEND);
		}
	}
	
	return valid;
}

static stock NativeVotesType TF2_VoteStringToVoteType(const char[] voteString)
{
	NativeVotesType voteType = NativeVotesType_None;
	
	if (StrEqual(voteString, TF2CSGO_VOTE_STRING_KICK, false))
	{
		voteType = NativeVotesType_Kick;
	}
	else if (StrEqual(voteString, TF2CSGO_VOTE_STRING_CHANGELEVEL, false))
	{
		voteType = NativeVotesType_ChgLevel;
	}
	else if (StrEqual(voteString, TF2CSGO_VOTE_STRING_NEXTLEVEL, false))
	{
		voteType = NativeVotesType_NextLevel;
	}
	else if (StrEqual(voteString, TF2CSGO_VOTE_STRING_RESTART, false))
	{
		voteType = NativeVotesType_Restart;
	}
	else if (StrEqual(voteString, TF2CSGO_VOTE_STRING_SCRAMBLE, false))
	{
		voteType = NativeVotesType_ScrambleNow;
	}
	else if (StrEqual(voteString, TF2_VOTE_STRING_ETERNAWEEN, false))
	{
		voteType = NativeVotesType_Eternaween;
	}
	else if (StrEqual(voteString, TF2_VOTE_STRING_AUTOBALANCE, false))
	{
		if (g_Cvar_AutoBalance.BoolValue)
		{
			voteType = NativeVotesType_AutoBalanceOff;
		}
		else
		{
			voteType = NativeVotesType_AutoBalanceOn;
		}
	}
	else if (StrEqual(voteString, TF2_VOTE_STRING_CLASSLIMIT, false))
	{
		if (g_Cvar_ClassLimit.IntValue)
		{
			voteType = NativeVotesType_ClassLimitsOff;
		}
		else
		{
			voteType = NativeVotesType_ClassLimitsOn;
		}
	}
	else if (StrEqual(voteString, TF2_VOTE_STRING_EXTEND, false))
	{
		voteType = NativeVotesType_Extend;
	}	
	else if (StrEqual(voteString, TF2_VOTE_STRING_CHANGEMISSION, false))
	{
		voteType = NativeVotesType_ChgMission;
	}
	else if (StrEqual(voteString, TF2_VOTE_STRING_CHANGEMISSION, false))
	{
		voteType = NativeVotesType_ChgMission;
	}
	
	return voteType;
}

static stock NativeVotesOverride TF2_VoteTypeToVoteOverride(NativeVotesType voteType)
{
	NativeVotesOverride overrideType = NativeVotesOverride_None;
	
	switch (voteType)
	{
		case NativeVotesType_Kick, NativeVotesType_KickCheating, NativeVotesType_KickIdle, NativeVotesType_KickScamming:
		{
			overrideType = NativeVotesOverride_Kick;
		}
		
		case NativeVotesType_ChgLevel:
		{
			overrideType = NativeVotesOverride_ChgLevel;
		}
		
		case NativeVotesType_NextLevel:
		{
			overrideType = NativeVotesOverride_NextLevel;
		}
		
		case NativeVotesType_Restart:
		{
			overrideType = NativeVotesOverride_Restart;
		}
		
		case NativeVotesType_ScrambleEnd, NativeVotesType_ScrambleNow:
		{
			overrideType = NativeVotesOverride_Scramble;
		}
		
		case NativeVotesType_Eternaween:
		{
			overrideType = NativeVotesOverride_Eternaween;
		}
		
		case NativeVotesType_AutoBalanceOn, NativeVotesType_AutoBalanceOff:
		{
			overrideType = NativeVotesOverride_AutoBalance;
		}
		
		case NativeVotesType_ClassLimitsOn, NativeVotesType_ClassLimitsOff:
		{
			overrideType = NativeVotesOverride_ClassLimits;
		}
		
		case NativeVotesType_Extend:
		{
			overrideType = NativeVotesOverride_Extend;
		}
	}
	
	return overrideType;
}

static stock NativeVotesType TF2_VoteOverrideToVoteType(NativeVotesOverride overrideType)
{
	NativeVotesType voteType = NativeVotesType_None;
	
	switch (overrideType)
	{
		case NativeVotesOverride_Restart:
		{
			voteType = NativeVotesType_Restart;
		}
		
		case NativeVotesOverride_Kick:
		{
			voteType = NativeVotesType_Kick;
		}
		
		case NativeVotesOverride_ChgLevel:
		{
			voteType = NativeVotesType_ChgLevel;
		}
		
		case NativeVotesOverride_NextLevel:
		{
			voteType = NativeVotesType_NextLevel;
		}
		
		case NativeVotesOverride_Scramble:
		{
			voteType = NativeVotesType_ScrambleNow;
		}
		
		case NativeVotesOverride_ChgMission:
		{
			voteType = NativeVotesType_ChgMission;
		}
		
		case NativeVotesOverride_Eternaween:
		{
			voteType = NativeVotesType_Eternaween;
		}
		
		case NativeVotesOverride_AutoBalance:
		{
			voteType = NativeVotesType_AutoBalanceOn;
		}
		
		case NativeVotesOverride_ClassLimits:
		{
			voteType = NativeVotesType_ClassLimitsOn;
		}
		
		case NativeVotesOverride_Extend:
		{
			voteType = NativeVotesType_Extend;
		}		
	}
	
	return voteType;
}

static stock NativeVotesOverride TF2_VoteStringToVoteOverride(const char[] voteString)
{
	NativeVotesOverride overrideType = NativeVotesOverride_None;
	
	if (StrEqual(voteString, TF2CSGO_VOTE_STRING_KICK, false))
	{
		overrideType = NativeVotesOverride_Kick;
	}
	else if (StrEqual(voteString, TF2CSGO_VOTE_STRING_CHANGELEVEL, false))
	{
		overrideType = NativeVotesOverride_ChgLevel;
	}
	else if (StrEqual(voteString, TF2CSGO_VOTE_STRING_NEXTLEVEL, false))
	{
		overrideType = NativeVotesOverride_NextLevel;
	}
	else if (StrEqual(voteString, TF2CSGO_VOTE_STRING_RESTART, false))
	{
		overrideType = NativeVotesOverride_Restart;
	}
	else if (StrEqual(voteString, TF2CSGO_VOTE_STRING_SCRAMBLE, false))
	{
		overrideType = NativeVotesOverride_Scramble;
	}
	else if (StrEqual(voteString, TF2_VOTE_STRING_ETERNAWEEN, false))
	{
		overrideType = NativeVotesOverride_Eternaween;
	}
	else if (StrEqual(voteString, TF2_VOTE_STRING_AUTOBALANCE, false))
	{
		overrideType = NativeVotesOverride_AutoBalance;
	}
	else if (StrEqual(voteString, TF2_VOTE_STRING_CLASSLIMIT, false))
	{
		overrideType = NativeVotesOverride_ClassLimits;
	}
	else if (StrEqual(voteString, TF2_VOTE_STRING_EXTEND, false))
	{
		overrideType = NativeVotesOverride_Extend;
	}	
	else if (StrEqual(voteString, TF2_VOTE_STRING_CHANGEMISSION, false))
	{
		overrideType = NativeVotesOverride_ChgMission;
	}
	
#if defined LOG
	LogMessage("Resolved \"%s\" to %d", voteString, overrideType);
#endif

	return overrideType;
}

static stock bool TF2_OverrideTypeToVoteString(NativeVotesOverride overrideType, char[] voteString, int maxlength)
{
	bool valid = false;
	switch(overrideType)
	{
		case NativeVotesOverride_Kick:
		{
			strcopy(voteString, maxlength, TF2CSGO_VOTE_STRING_KICK);
			valid = true;
		}
		
		case NativeVotesOverride_ChgLevel:
		{
			strcopy(voteString, maxlength, TF2CSGO_VOTE_STRING_CHANGELEVEL);
			valid = true;
		}
		
		case NativeVotesOverride_NextLevel:
		{
			strcopy(voteString, maxlength, TF2CSGO_VOTE_STRING_NEXTLEVEL);
			valid = true;
		}
		
		case NativeVotesOverride_Restart:
		{
			strcopy(voteString, maxlength, TF2CSGO_VOTE_STRING_RESTART);
			valid = true;
		}
		
		case NativeVotesOverride_Scramble:
		{
			strcopy(voteString, maxlength, TF2CSGO_VOTE_STRING_SCRAMBLE);
			valid = true;
		}
		
		case NativeVotesOverride_Eternaween:
		{
			strcopy(voteString, maxlength, TF2_VOTE_STRING_ETERNAWEEN);
			valid = true;
		}
		
		case NativeVotesOverride_AutoBalance:
		{
			strcopy(voteString, maxlength, TF2_VOTE_STRING_AUTOBALANCE);
			valid = true;
		}
		
		case NativeVotesOverride_ClassLimits:
		{
			strcopy(voteString, maxlength, TF2_VOTE_STRING_CLASSLIMIT);
			valid = true;
		}
		
		case NativeVotesOverride_Extend:
		{
			strcopy(voteString, maxlength, TF2_VOTE_STRING_EXTEND);
		}		
		
		case NativeVotesOverride_ChgMission:
		{
			strcopy(voteString, maxlength, TF2_VOTE_STRING_CHANGEMISSION);
		}
	}
	
	return valid;
}

static stock bool TF2_OverrideTypeToTranslationString(NativeVotesOverride overrideType, char[] translationString, int maxlength)
{
	bool valid = false;
	switch(overrideType)
	{
		case NativeVotesOverride_Kick:
		{
			strcopy(translationString, maxlength, TF2_VOTE_MENU_KICK);
			valid = true;
		}
		
		case NativeVotesOverride_ChgLevel:
		{
			strcopy(translationString, maxlength, TF2_VOTE_MENU_CHANGELEVEL);
			valid = true;
		}
		
		case NativeVotesOverride_NextLevel:
		{
			strcopy(translationString, maxlength, TF2_VOTE_MENU_NEXTLEVEL);
			valid = true;
		}
		
		case NativeVotesOverride_Restart:
		{
			strcopy(translationString, maxlength, TF2_VOTE_MENU_RESTART);
			valid = true;
		}
		
		case NativeVotesOverride_Scramble:
		{
			strcopy(translationString, maxlength, TF2_VOTE_MENU_SCRAMBLE);
			valid = true;
		}
		
		case NativeVotesOverride_Eternaween:
		{
			strcopy(translationString, maxlength, TF2_VOTE_MENU_ETERNAWEEN);
			valid = true;
		}
		
		case NativeVotesOverride_AutoBalance:
		{
			if (GetConVarBool(g_Cvar_AutoBalance))
			{
				strcopy(translationString, maxlength, TF2_VOTE_MENU_AUTOBALANCE_OFF);
			}
			else
			{
				strcopy(translationString, maxlength, TF2_VOTE_MENU_AUTOBALANCE_ON);
			}
			valid = true;
		}
		
		case NativeVotesOverride_ClassLimits:
		{
			if (GetConVarInt(g_Cvar_ClassLimit))
			{
				strcopy(translationString, maxlength, TF2_VOTE_MENU_CLASSLIMIT_OFF);
			}
			else
			{
				strcopy(translationString, maxlength, TF2_VOTE_MENU_CLASSLIMIT_ON);
			}
			valid = true;
		}
		
		case NativeVotesOverride_Extend:
		{
			strcopy(translationString, maxlength, TF2_VOTE_MENU_EXTEND);
		}
	}
	
	return valid;
}

stock bool Game_IsVoteTypeCustom(NativeVotesType voteType)
{
	switch(voteType)
	{
		case NativeVotesType_Custom_YesNo, NativeVotesType_Custom_Mult:
		{
			return true;
		}
	}
	
	return false;
}

stock bool Game_IsVoteTypeYesNo(NativeVotesType voteType)
{
	switch(voteType)
	{
		case NativeVotesType_Custom_Mult, NativeVotesType_NextLevelMult:
		{
			return false;
		}
	}
	
	return true;
}
