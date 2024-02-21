/**
 * vim: set ts=4 :
 * =============================================================================
 * NativeVotes
 * Copyright (C) 2011-2015 Ross Bemrose (Powerlord).  All rights reserved.
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
 
#include <menus>
#include <sourcemod>

// NativeVotes 1.1 series

#if defined _nativevotes_included
 #endinput
#endif
#define _nativevotes_included

#define CLIENT_DISCONNECTED			-1

#define NATIVEVOTES_EXTEND 			"Extend current Map" /** Defined in TF2, but doesn't appear to be localized */

#define NATIVEVOTES_ALL_TEAMS		-1 // Formerly defined by TF2, may be the same in L4D/L4D2/CSGO
#define NATIVEVOTES_TF2_ALL_TEAMS	0 // Defined by TF2, may be the same in L4D/L4D2
#define NATIVEVOTES_TEAM_UNASSIGNED 0 // For completeness, do not otherwise use
#define NATIVEVOTES_TEAM_SPECTATOR	1 // Spectators
#define NATIVEVOTES_TEAM_1			2 // RED/Survivors/Terrorists
#define NATIVEVOTES_TEAM_2			3 // BLU/Infected/Counter-Terrorists

#define NATIVEVOTES_SERVER_INDEX 	99 // Defined by TF2, may be the same in L4D/L4D2

// These may seem backwards, but this is the order that the votes appear in the vote screen
#define NATIVEVOTES_VOTE_INVALID	-1		/**< Vote was invalid, currently only valid internally */
#define NATIVEVOTES_VOTE_YES		0		/**< Vote was yes */
#define NATIVEVOTES_VOTE_NO			1		/**< Vote was no */

/*
The following MenuActions are supported.  Arguments are also listed, as they differ slightly from the default
MenuAction_Start		A menu has been started (nothing passed). Only exists for compat reasons.
MenuAction_Display		A menu is about to be displayed (param1=client). If you choose to change the vote text,
 						To change the text, use NativeVotes_RedrawVoteTitle()
						If you do so, return 1 or _:Plugin_Changed  Otherwise, return _:Plugin_Continue or 0.
MenuAction_Select		An item was selected (param1=client, param2=item). For subplugin support; normal plugins
						should use NativeVotes_SetResultCallback or catch the MenuAction_VoteEnd action.
MenuAction_End			A vote has fully ended and the vote object is ready to be cleaned up
						param1 is MenuEnd reason, either MenuEnd_VotingCancelled or MenuEnd_VotingDone
MenuAction_VoteEnd		A vote sequence has succeeded (param1=chosen item)
						This is not called if NativeVotes_SetResultCallback has been used on the vote.
						You should call NativeVotes_DisplayPass or NativeVotes_DisplayPassEx after this
MenuAction_VoteStart	A vote sequence has started (nothing passed).  Use this instead of MenuAction_Start
MenuAction_VoteCancel	A vote sequence has been cancelled (param1=reason)
MenuAction_DisplayItem	Item text is being drawn to the display (param1=client, param2=item)
						To change the text, use NativeVotes_RedrawVoteItem().
						If you do so, return 1 or _:Plugin_Changed.  Otherwise, return _:Plugin_Continue or 0.
*/

#define NATIVEVOTES_ACTIONS_DEFAULT		MenuAction_VoteStart|MenuAction_VoteCancel|MenuAction_VoteEnd|MenuAction_End

/**
 * Vote types. These are mapped to translation strings and pass strings by VoteStart and VotePass handlers
 */
enum NativeVotesType
{
	NativeVotesType_None = 0,		/**< Special placeholder for callvote with no arguments for NativeVotes_OnCallVote */
	NativeVotesType_Custom_YesNo,	/**< Yes/No, details are vote text. */
	NativeVotesType_Custom_Mult,	/**< TF2/CS:GO: Multiple-choice, details are vote text. */
	NativeVotesType_ChgCampaign,	/**< L4D/L4D2: Yes/No, details are campaign name */
	NativeVotesType_ChgDifficulty,	/**< L4D/L4D2: Yes/No, details are difficulty number in L4D/L4D2 */
	NativeVotesType_ReturnToLobby,	/**< L4D/L4D2: Yes/No, details are ignored */
	NativeVotesType_AlltalkOn,		/**< L4D2: Yes/No, details are ignored (handled internally by extension) */
	NativeVotesType_AlltalkOff,		/**< L4D2: Yes/No, details are ignored (handled internally by extension) */
	NativeVotesType_Restart,		/**< Yes/No, details are ignored */
	NativeVotesType_Kick,			/**< Yes/No, target is player userid, details are auto-set by target */
	NativeVotesType_KickIdle,		/**< TF2/CS:GO: Yes/No, target is player userid, details are auto-set by target */
	NativeVotesType_KickScamming,	/**< TF2/CS:GO: Yes/No, target is player userid, details are auto-set by target */
	NativeVotesType_KickCheating,	/**< TF2/CS:GO: Yes/No, target is player userid, details are auto-set by target */
	NativeVotesType_ChgLevel,		/**< Yes/No, details are level number in L4D/L4D2 or map name in TF2 */
	NativeVotesType_NextLevel,		/**< TF2/CS:GO: Yes/No, details are map name */
	NativeVotesType_NextLevelMult,	/**< TF2/CS:GO: Multiple-choice, details are ignored */
	NativeVotesType_ScrambleNow,	/**< TF2/CS:GO: Yes/No, details are ignored */
	NativeVotesType_ScrambleEnd,	/**< TF2: Yes/No, details are ignored */
	NativeVotesType_ChgMission,		/**< TF2: Yes/No, details are popfile */
	NativeVotesType_SwapTeams,		/**< CS:GO: Yes/No, details are ignored */
	NativeVotesType_Surrender,		/**< CS:GO: Yes/No, details are ignored */
	NativeVotesType_Rematch,		/**< CS:GO: Yes/No, details are ignored */
	NativeVotesType_Continue,		/**< CS:GO: Yes/No, details are ignored */
	NativeVotesType_StartRound,		/**< TF2: Yes/No, details are ignored */
	NativeVotesType_Eternaween,		/**< TF2: Yes/No, details are ignored */
	NativeVotesType_AutoBalanceOn,	/**< TF2: Yes/No, details are ignored */
	NativeVotesType_AutoBalanceOff,	/**< TF2: Yes/No, details are ignored */
	NativeVotesType_ClassLimitsOn,	/**< TF2: Yes/No, details are ignored */
	NativeVotesType_ClassLimitsOff,	/**< TF2: Yes/No, details are ignored */
	NativeVotesType_Extend,			/**< TF2: Yes/No, details are ignored */
};

enum NativeVotesPassType
{
	NativeVotesPass_None = 0,			/**< Special placeholder for error value */
	NativeVotesPass_Custom,				/**< Details are custom pass message */
	NativeVotesPass_ChgCampaign,		/**< L4D/L4D2: Details are campaign name */
	NativeVotesPass_ChgDifficulty,		/**< L4D/L4D2/TF2: Details are difficulty number in L4D/L4D2 and mission name in TF2 */
	NativeVotesPass_ReturnToLobby,		/**< L4D/L4D2: Details are ignored */
	NativeVotesPass_AlltalkOn,			/**< L4D2: Details are ignored */
	NativeVotesPass_AlltalkOff,			/**< L4D2: Details are ignored */
	NativeVotesPass_Restart,			/**< Details are ignored */
	NativeVotesPass_Kick,				/**< Details are player name */
	NativeVotesPass_ChgLevel,			/**< Details are level number in L4D/L4D2 or map name in TF2/CS:GO */
	NativeVotesPass_NextLevel,			/**< TF2/CS:GO: Details are map name */
	NativeVotesPass_Extend,				/**< TF2/CS:GO: Details are ignored */
	NativeVotesPass_Scramble,			/**< TF2/CS:GO: Details are ignored */
	NativeVotesPass_ChgMission,			/**< TF2: Details are popfile */
	NativeVotesPass_SwapTeams,			/**< CS:GO: Details are ignored */
	NativeVotesPass_Surrender,			/**< CS:GO: Details are ignored */
	NativeVotesPass_Rematch,			/**< CS:GO: Details are ignored */
	NativeVotesPass_Continue,			/**< CS:GO: Details are ignored */
	NativeVotesPass_StartRound,			/**< TF2: Details are ignored */
	NativeVotesPass_Eternaween,			/**< TF2: Details are ignored */
	NativeVotesPass_AutoBalanceOn,		/**< TF2: Yes/No, details are ignored */
	NativeVotesPass_AutoBalanceOff,		/**< TF2: Yes/No, details are ignored */
	NativeVotesPass_ClassLimitsOn,		/**< TF2: Yes/No, details are ignored */
	NativeVotesPass_ClassLimitsOff,		/**< TF2: Yes/No, details are ignored */
};

/**
 * Reasons a vote was canceled.  Not used for L4D/L4D2, as they don't care
 */
enum NativeVotesFailType
{
	NativeVotesFail_Generic = 0,			/**< Vote was generically cancelled. */
	NativeVotesFail_Loses = 3,			/**< No votes outnumbered Yes votes */
	NativeVotesFail_NotEnoughVotes = 4,	/**< Vote did not receive enough votes. */
};

/**
 * Reasons a callvote command failed.
 * 
 * This will mainly be used by VoteCommand overrides, although it is available to all games
 * as a convenience.
 * 
 * Note:
 * 0-1 match for all games.
 * 2-14 match for TF2 and CS:GO
 * 15 is different for TF2 and CS:GO as they were added after the vote system was copied.
 * 16+ are exclusive to TF2.
 * 
 * UPDATE: Starting in 2015, this list is no longer a direct one-to-one with the values the game uses.
 * This is because CS:GO changed a bunch of their values.
 * Plugins that use NativeVotesCallFail_Warmup WILL need to be recompiled as it has been assigned a new number
 */
enum NativeVotesCallFailType
{
	NativeVotesCallFail_Generic = 0,			/**< Generic fail. */
	NativeVotesCallFail_Loading = 1,			/**< L4D/L4D2: Players are still loading. */
	NativeVotesCallFail_Recent = 2,				/**< TF2/CSGO: You can't call another vote yet: Argument is seconds until you can call another vote. */
	NativeVotesCallFail_Disabled = 5,			/**< TF2/CSGO: Server has disabled that issue. */
	NativeVotesCallFail_MapNotFound = 6,		/**< TF2/CSGO: Server does not have that map. */
	NativeVotesCallFail_SpecifyMap = 7,			/**< TF2/CSGO: You must specify a map. */
	NativeVotesCallFail_Failed = 8,				/**< TF2/CSGO: This vote failed recently. Argument is seconds until this vote can be called again. */
	NativeVotesCallFail_WrongTeam = 9,			/**< TF2/CSGO: Team can't call this vote. */
	NativeVotesCallFail_Waiting = 10,			/**< TF2/CSGO: Vote can't be called during Waiting For Players/Warmup. */
	NativeVotesCallFail_Warmup = 10,			/**< CSGO: Vote can't be called during Warmup. Same as Waiting For Players for compat reasons */
	NativeVotesCallFail_PlayerNotFound = 11,	/**< TF2/CSGO: Player to kick can't be found. Buggy in TF2. */
	NativeVotesCallFail_Unknown = 11,
	NativeVotesCallFail_CantKickAdmin = 12,		/**< TF2/CSGO: Can't kick server admin. */
	NativeVotesCallFail_ScramblePending = 13,	/**< TF2/CSGO: Team Scramble is pending. */
	NativeVotesCallFail_Spectators = 14,		/**< TF2/CSGO: Spectators aren't allowed to call votes. */
	NativeVotesCallFail_LevelSet = 15,			/**< TF2: Next level already set. */
	NativeVotesCallFail_MapNotValid = 16,		/**< TF2: Map is not in MapCycle. */
	NativeVotesCallFail_KickTime = 17,			/**< TF2: Cannot kick at this time: Argument is seconds until you can call another kick vote. */
	NativeVotesCallFail_KickDuringRound = 18,	/**< TF2: Cannot kick during a round. */
	NativeVotesCallFail_AlreadyActive = 19,		/**< TF2: Cannot call vote because modification (Eternaween) is already active (may not work) */
	NativeVotesCallFail_KickFailed = 20,		/**< CSGO: Kick vote failed recently. Argument is seconds until this vote can be called again. */
	NativeVotesCallFail_MapFailed = 21,			/**< CSGO: Map vote failed recently. Argument is seconds until this vote can be called again. */
	NativeVotesCallFail_SwapFailed = 22,		/**< CSGO: Swap Teams vote failed recently. Argument is seconds until this vote can be called again. */
	NativeVotesCallFail_ScrambleFailed = 23,	/**< CSGO: Scramble vote failed recently. Argument is seconds until this vote can be called again. */
	NativeVotesCallFail_RestartFailed = 24,		/**< CSGO: Restart vote failed recently. Argument is seconds until this vote can be called again. */
	NativeVotesCallFail_SwapPending = 25,		/**< CSGO: Team Swap is pending. */
	NativeVotesCallFail_Unknown2 = 26,			/**< CSGO: Unknown */
	NativeVotesCallFail_CantSurrender = 27,		/**< CSGO: Can't surrender until a teammate abandons the match. */
	NativeVotesCallFail_Unknown3 = 28,			/**< CSGO: Unknown */
	NativeVotesCallFail_MatchPaused = 29,		/**< CSGO: Match is already paused. */
	NativeVotesCallFail_NotPaused = 30,			/**< CSGO: Match is not paused. */
	NativeVotesCallFail_NotWarmup = 31,			/**< CSGO: Match is not in warmup. */
	NativeVotesCallFail_MinPlayers = 32,		/**< CSGO: Vote requires 10 players. */
	NativeVotesCallFail_RoundEnded = 33,		/**< CSGO: Vote can't succeed after round has ended. */
};

enum NativeVotesKickType
{
	NativeVotesKickType_None = 0,			/**< Not a kick vote */
	NativeVotesKickType_Generic,			/**< Generic kick vote type.  The only type available on L4D/L4D2 */
	NativeVotesKickType_Idle,				/**< TF2/CS:GO: Client chose Idle from the list */
	NativeVotesKickType_Scamming,			/**< TF2/CS:GO: Client chose Scamming from the list */
	NativeVotesKickType_Cheating,			/**< TF2/CS:GO: Client chose Cheating from the list */	
}

/**
 * Types of votes that can be overridden in the client vote menu
 * 
 * Note that menus use the same command for enable and disable votes,
 * so their overrides reflect this
 * 
 * Only TF2 supports this feature
 */
enum NativeVotesOverride
{
	NativeVotesOverride_None,
	NativeVotesOverride_Restart,
	NativeVotesOverride_Kick,
	NativeVotesOverride_ChgLevel,
	NativeVotesOverride_NextLevel,
	NativeVotesOverride_Scramble,
	NativeVotesOverride_ChgMission,
	NativeVotesOverride_Eternaween,
	NativeVotesOverride_AutoBalance,
	NativeVotesOverride_ClassLimits,
	NativeVotesOverride_Extend,
	NativeVotesOverride_Count,
}

methodmap NativeVote < KeyValues
{
	// Creates a new, empty vote.
	//
	// @param handler			Function which will receive vote actions.
	// @param voteType		Vote type, cannot be changed after set
	// @param actions			Optionally set which actions to receive.  VoteStart,
	//						VoteCancel, VoteEnd, and End will always be received
	//						regardless of whether they are set or not.  They are
	//						also the only default actions.
	public native NativeVote(NativeVotes_Handler handler, NativeVotesType voteType,
	                           MenuAction actions=NATIVEVOTES_ACTIONS_DEFAULT);
	
	// Frees all handles related to a vote.
	//
	// THIS MUST BE CALLED TO AVOID HANDLE LEAKS
	public native void Close();
	
	// Appends a new item to the end of a vote.  Only valid for Multiple Choice votes
	//
	// @param info				Item information string.
	// @return					True on success, false on failure.
	// @error					Item limit reached or if the vote is not multiple choice.
	public native bool AddItem(const char[] info, const char[] display);
	
	// Inserts an item into the menu before a certain position; the new item will
	// be at the given position and all next items pushed forward.
	//
	// @param position			Position, starting from 0.
	// @param info				Item information string.
	// @return					True on success, false on failure.
	// @error					Invalid vote position or if the vote is not multiple choice.
	public native bool InsertItem(int position, const char[] info, const char[] display);
	
	// Removes an item from the menu.
	//
	// @param position			Position, starting from 0.
	// @return					True on success, false on failure.
	// @error					Invalid vote position or if the vote is not multiple choice.
	public native bool RemoveItem(int position);
	
	// Removes all items from a vote.
	//
	// @error					If the vote is not multiple choice.
	public native void RemoveAllItems();
	
	// Retrieves information about a vote item.
	//
	// @param position			Position, starting from 0.
	// @param infoBuf				Info buffer.
	// @param infoBufLen			Maximum length of the info buffer.
	// @param dispBuf				Display buffer.
	// @param displayBufLen		Maximum length of the display buffer.
	// @return					True on success, false if position is invalid.
	public native bool GetItem(int position, char[] infoBuf, int infoBufLen,
							char[] dispBuf="", int dispBufLen=0);
	
	// Sets the vote's details for votes that support details
	// If this is a custom vote, use SetTitle to set the vote's title.
	//
	// @param fmt 				Message string format
	// @param ...					Message string arguments.
	public native void SetDetails(const char[] fmt, any ...);
	
	// Returns the text of a vote's details if set.
	//
	// @param buffer				Buffer to store details.
	// @param maxlength			Maximum length of the buffer.
	public native void GetDetails(char[] buffer, int maxlength);
	
	// Sets a custom vote's default title/instruction message.
	//
	// @param fmt 				Message string format
	// @param ...					Message string arguments.
	public native void SetTitle(const char[] fmt, any ...);
	
	// Return the text of a custom vote's title.
	// If not set, returns Details instead.
	//     This behavior is for compatibility with NativeVotes 0.8.0 and below.
	//
	// @param buffer				Buffer to store title.
	// @param maxlength			Maximum length of the buffer.
	public native void GetTitle(char[] buffer, int maxlength);
	
	// Sets the target userid for vote
	// This should be used instead of SetArgument for votes that target players
	// 
	// Also sets target SteamID
	// 
	// @param userid				Client index of target player or 0 to clear target
	// @param setDetails			If true, also sets vote details to client's name
	public native void SetTarget(int client, bool setDetails=true);

	// Returns the vote's target client index, 0 for client disconnected, or -1 for no target.
	//
	// @return					Client index of target player, 0 for client disconnected, or -1 for no target.
	public native int GetTarget();
	
	// Get the SteamID2 of a vote's target
	// Useful if the target has disconnected from the server during a vote.
	// This was added in specifically for Kick/Ban votes
	//
	// @param buffer				Buffer to store steamId.  Should be 19 characters or more.
	// @param maxlength			Maximum length of the buffer.
	public native void GetTargetSteam(char[] buffer, int maxlength);

	// Broadcasts a vote to a list of clients.  The most selected item will be 
	// returned through MenuAction_VoteEnd.  On a tie, a random item will be returned 
	// from a list of the tied items.
	//
	// Note that MenuAction_VoteStart, MenuAction_VoteCancel, MenuAction_VoteEnd, and MenuAction_End are all
	// default callbacks and do not need to be enabled.
	//
	// @param clients				Array of clients to broadcast to.
	// @param numClients			Number of clients in the array.
	// @param time				Maximum time to leave vote on the screen.
	// @param flags				Optional voting flags (i.e. VOTEFLAG_NO_REVOTES)
	// @return					True on success, false if a this vote already has a
	// 							vote session in progress.
	// @error					A vote is already in progress.
	public native bool DisplayVote(int[] clients, int numClients, int time, int flags=0);
	
	// Sends a vote menu to all clients.  See NativeVotes_Display() for more information.
	//
	// @param time				Maximum time to leave vote on the screen.
	// @param flags				Optional voting flags (i.e. VOTEFLAG_NO_REVOTES)
	// @return					True on success, false if this menu already has a
	// 							vote session in progress.
	// @error					A vote is already in progress.
	public bool DisplayVoteToAll(int time, int flags=0)
	{
		int total = 0;
		int[] players = new int[MaxClients];
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;
			players[total++] = i;
		}
		return this.DisplayVote(players, total, time, flags);
	}
	
	// Display default vote passed screen for this vote type
	//
	// You MUST call one of the DisplayPass* or DisplayFail functions
	// to hide the vote screen for users who didn't vote, and to clear out their selection
	// for the next vote.
	//
	// The format string/any args are a Valve format string or the item that won the vote.
	//
	// @param fmt 				Message string format
	// @param ...					Message string arguments.
	public native void DisplayPass(const char[] fmt="", any ...);
	
	// Display vote passed screen with custom text to a single client
	//
	// You MUST call one of the DisplayPass* or DisplayFail functions
	// to hide the vote screen for users who didn't vote, and to clear out their selection
	// for the next vote.
	//
	// You should favor DisplayPassCustom over this function as you must send a
	// DisplayPass to all clients
	// 
	// The format string/any args are the item that won the vote.
	//
	// @param client				Client to display pass screen to.
	// @param fmt					A format string.
	// @param ...					Variable number of format parameters
	public native void DisplayPassCustomToOne(int client, const char[] fmt, any ...);
	
	// Display vote passed screen with custom text to all clients
	//
	// You MUST call one of the DisplayPass* or DisplayFail functions
	// to hide the vote screen for users who didn't vote, and to clear out their selection
	// for the next vote.
	// 
	// The format string/any args are the item that won the vote.
	//
	// @param fmt					A format string.
	// @param ...					Variable number of format parameters
	public void DisplayPassCustom(const char[] fmt, any ...)
	{
		char buffer[192];
		
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;
				
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), fmt, 3);
			this.DisplayPassCustomToOne(i, "%s", buffer);
		}
	}
	
	// Display vote passed screen with a custom type.
	//
	// A sample usage of this would be if Extend won an RTV vote: vote.DisplayPassEx(NativeVotesPass_Extend, map);
	//
	// You MUST call one of the DisplayPass* or DisplayFail functions
	// to hide the vote screen for users who didn't vote, and to clear out their selection
	// for the next vote.
	// 
	// The format string/any args are the item that won the vote.
	//
	// @param passType				The pass screen to display
	// @param fmt					A format string.
	// @param ...					Variable number of format parameters
	public native void DisplayPassEx(NativeVotesPassType passType, const char[] fmt="", any ...);
	
	// Display vote failure screen to all users in a vote.
	//
	// You MUST call one of the DisplayPass* or DisplayFail functions
	// to hide the vote screen for users who didn't vote, and to clear out their selection
	// for the next vote.
	// 
	// @param reason			Vote failure reason from NativeVotesFailType enum
	public native void DisplayFail(NativeVotesFailType reason=NativeVotesFail_Generic);

	// Get or set a vote's option flags.
	//
	// If a certain bit is not supported, it will be stripped before being set.
	//
	// NOTE: Only MENUFLAG_BUTTON_NOVOTE is supported by NativeVotes
	property int OptionFlags {
		public native get();
		public native set(int value);
	}
	
	// Sets whether or not the vote has a "no vote" button in slot 1 for
	// multiple choice votes.
	// By default, votes do not have a no vote button.
	property bool NoVoteButton {
		public native set(bool value);
	}
	
	// Sets an advanced vote handling callback.  If this callback is set,
	// MenuAction_VoteEnd will not be called.
	property NativeVotes_VoteHandler VoteResultCallback {
		public native set(NativeVotes_VoteHandler handler);
	}
	
	// Returns the number of items in a vote.
	property int ItemCount {
		public native get();
	}

	// Retrieve the vote type
	property NativeVotesType VoteType {
		public native get();
	}
	
	// Get or set the team this vote is for
	// NATIVEVOTES_ALL_TEAMS is used for all teams.
	property int Team {
		public native get();
		public native set(int team);
	}

	// Get or set the client index of the player who initiated the vote.
	// Use NATIVEVOTES_SERVER_INDEX if initiated by the server itself.
	//
	// Defaults to NATIVEVOTES_SERVER_INDEX if not explicitly set.
	property int Initiator {
		public native get();
		public native set(int initiator);
	}
}

/**
 * Is a specific vote type supported by this game?
 * 
 * @param voteType			Vote type
 */
native bool NativeVotes_IsVoteTypeSupported(NativeVotesType voteType);

/**
 * Creates a new, empty vote.
 * 
 * @param handler			Function which will receive vote actions.
 * @param voteType		Vote type, cannot be changed after set
 * @param actions			Optionally set which actions to receive.  VoteStart,
 * 						VoteCancel, VoteEnd, and End will always be received
 * 						regardless of whether they are set or not.  They are
 * 						also the only default actions.
 * @return				A new vote Handle on INVALID_HANDLE if a vote type is unsupported by this game.
 */
native NativeVote NativeVotes_Create(NativeVotes_Handler handler, NativeVotesType voteType,
                                    MenuAction actions=NATIVEVOTES_ACTIONS_DEFAULT);

/**
 * Frees all handles related to a vote.
 * 
 * THIS MUST BE CALLED TO AVOID HANDLE LEAKS
 * 
 * @param vote				Vote handle
 */
native void NativeVotes_Close(Handle vote);

/**
 * Appends a new item to the end of a vote.  Only valid for Multiple Choice votes
 *
 * @param vote				NativeVotes Handle.
 * @param info				Item information string.
 * @return					True on success, false on failure.
 * @error					Invalid Handle, item limit reached, or if the vote is not multiple choice.
 */
native bool NativeVotes_AddItem(Handle vote, const char[] info, const char[] display);

/**
 * Inserts an item into the menu before a certain position; the new item will
 * be at the given position and all next items pushed forward.
 *
 * @param vote				Vote Handle.
 * @param position			Position, starting from 0.
 * @param info				Item information string.
 * @return					True on success, false on failure.
 * @error					Invalid Handle or vote position, or if the vote is not multiple choice.
 */
native bool NativeVotes_InsertItem(Handle vote, int position, const char[] info, const char[] display);

/**
 * Removes an item from the menu.
 *
 * @param vote				Vote Handle.
 * @param position			Position, starting from 0.
 * @return					True on success, false on failure.
 * @error					Invalid Handle or vote position,  or if the vote is not multiple choice.
 */
native bool NativeVotes_RemoveItem(Handle vote, int position);

/**
 * Removes all items from a vote.
 *
 * @param vote				Vote Handle.
 * @error					Invalid Handle or vote position, or if the vote is not multiple choice.
 */
native void NativeVotes_RemoveAllItems(Handle vote);

/**
 * Retrieves information about a vote item.
 *
 * @param vote				Vote Handle.
 * @param position			Position, starting from 0.
 * @param infoBuf				Info buffer.
 * @param infoBufLen			Maximum length of the info buffer.
 * @param dispBuf				Display buffer.
 * @param displayBufLen		Maximum length of the display buffer.
 * @return					True on success, false if position is invalid.
 * @error					Invalid Handle
 */
native bool NativeVotes_GetItem(Handle vote, 
						int position,
						char[] infoBuf, 
						int infoBufLen,
						char[] dispBuf="",
						int dispBufLen=0);
						
/**
 * Returns the number of items in a vote.
 *
 * @param vote				Vote Handle.
 * @return					Number of items in the vote.
 * @error					Invalid Handle.
 */
native int NativeVotes_GetItemCount(Handle vote);

/**
 * Sets the vote's details for votes that support details
 * If this is a custom vote, use NativeVotes_SetTitle to set the vote's title.
 *
 * @param vote				Vote Handle.
 * @param fmt 				Message string format
 * @param ...				Message string arguments.
 * @error					Invalid Handle.
 */
native void NativeVotes_SetDetails(Handle vote, const char[] fmt, any ...);

/**
 * Returns the text of a vote's details if set.
 *
 * @param vote				Vote Handle.
 * @param buffer			Buffer to store details.
 * @param maxlength			Maximum length of the buffer.
 * @error					Invalid Handle.
 */
native void NativeVotes_GetDetails(Handle vote, char[] buffer, int maxlength);

/**
 * Sets a custom vote's default title/instruction message.
 *
 * @param vote				Vote Handle.
 * @param fmt 				Message string format
 * @param ...				Message string arguments.
 * @error					Invalid Handle.
 */
native void NativeVotes_SetTitle(Handle vote, const char[] fmt, any ...);

/**
 * Return the text of a custom vote's title.
 * If not set, returns Details instead.
 *     This behavior is for compatibility with NativeVotes 0.8.0 and below.
 *
 * @param vote				Vote Handle.
 * @param buffer			Buffer to store title.
 * @param maxlength			Maximum length of the buffer.
 * @error					Invalid Handle.
 */
native void NativeVotes_GetTitle(Handle vote, char[] buffer, int maxlength);

/**
 * Sets the target userid for vote
 * This should be used instead of SetArgument for votes that target players
 * 
 * Also sets target SteamID
 * 
 * @param vote				Vote Handle.
 * @param userid			Client index of target player or 0 to clear target
 * @param setDetails		If true, also sets vote details to client's name
 * @error					Invalid Handle.
 */
native void NativeVotes_SetTarget(Handle vote, int client, bool setDetails=true);

/**
 * Returns the vote's target client index, 0 for client disconnected, or -1 for no target.
 *
 * @param vote				Vote Handle.
 * @return					Client index of target player, 0 for client disconnected, or -1 for no target.
 * @error					Invalid Handle.
 */
native int NativeVotes_GetTarget(Handle vote);

/**
 * Get the SteamID2 of a vote's target
 * Useful if the target has disconnected from the server during a vote.
 * This was added in specifically for Kick/Ban votes
 *
 * @param vote				Vote Handle.
 * @param buffer			Buffer to store steamId.  Should be 19 characters or more..
 * @param maxlength			Maximum length of the buffer.
 * @error					Invalid Handle.
 */
native void NativeVotes_GetTargetSteam(Handle vote, char[] buffer, int maxlength);

/**
 * Returns whether a vote is in progress.
 *
 * @return					True if a NativeVotes vote is in progress, false otherwise.
 */
native bool NativeVotes_IsVoteInProgress();

/**
 * Returns a style's maximum items
 * 
 * @return Maximum items
 */
native int NativeVotes_GetMaxItems();

/**
 * Sets a vote's option flags.
 *
 * If a certain bit is not supported, it will be stripped before being set.
 * 
 * NOTE: Only MENUFLAG_BUTTON_NOVOTE is supported by NativeVotes
 *
 * @param vote				Vote Handle.
 * @param flags				A new bitstring of MENUFLAG bits.
 * @error					Invalid Handle.
 */
native void NativeVotes_SetOptionFlags(Handle vote, int flags);

/**
 * Retrieves a vote's option flags.
 *
 * NOTE: Only MENUFLAG_BUTTON_NOVOTE is supported by NativeVotes
 *
 * @param vote				Vote Handle.
 * @return					A bitstring of MENUFLAG bits.
 * @error					Invalid Handle.
 */
native int NativeVotes_GetOptionFlags(Handle vote);

/**
 * Sets whether or not the vote has a "no vote" button in slot 1 for
 * multiple choice votes.
 * By default, votes do not have a no vote button.
 * 
 * @param vote		NativeVotes Handle
 * @param button		True to enable the button, false to remove it.
 * @return			True if allowed; false on failure.
 * @error			Invalid Handle.
 */
native bool NativeVotes_SetNoVoteButton(Handle vote, bool button);

/**
 * Cancels the vote in progress.
 *
 * @error					If no vote is in progress.
 */
native void NativeVotes_Cancel();

/**
 * Called when a vote action is completed.
 * 
 * This is a clone of the SM 1.6 MenuHandler for future compatibility.
 *
 * @param vote			The vote being acted upon.
 * @param action			The action of the vote.
 * @param param1			First action parameter (usually the client).
 * @param param2			Second action parameter (usually the item).
 */
typedef NativeVotes_Handler = function int (NativeVote vote, MenuAction action, int param1, int param2);

/**
 * Callback for when a vote has ended and results are available.
 * 
 * Due to SourceMod Forward limitations in plugins, multi-dimension arrays can't be passed
 * to forwards.  This means we have to split the client_info and item_info arrays into
 * their components.
 * 
 * @param vote			The vote being voted on.
 * @param num_votes		Number of votes tallied in total.
 * @param num_clients		Number of clients who could vote.
 * @param client_indexes	Array of client indexes. Parallel with client_votes.
 * @param client_votes		Array of client votes. Parallel with client_indexes.
 * @param num_items		Number of unique items that were selected.
 * @param item_indexes		Array of vote item indexes. Parallel with item_votes..
 * @param item_votes		Array of vote vote counts. Parallel with item_indexes.
 */
typedef NativeVotes_VoteHandler = function void (NativeVote vote,
							int num_votes, 
							int num_clients,
							const int[] client_indexes,
							const int[] client_votes,
							int num_items,
							const int[] item_indexes,
							const int[] item_votes);
/**
 * Function to convert client/vote arrays into their two-dimensional versions,
 * which can then be passed to a standard vote handler.
 * 
 * client_info and item_info are the resulting arrays.
 * 
 * Note: When declaring client_info and item_info, you'll probably want to declare them like this:
 * new client_info[num_clients][2];
 * new item_info[num_items][2];
 * 
 * NOTE: This should only be used to execute shared logic or logic that knows that the resulting
 * vote data is from NativeVotes.
 *
 * @param num_clients		Number of clients who could vote.
 * @param client_indexes	Array of client indexes. Parallel with client_votes.
 * @param client_votes		Array of client votes. Parallel with client_indexes.
 * @param num_items			Number of unique items that were selected.
 * @param item_indexes		Array of vote item indexes. Parallel with item_votes..
 * @param item_votes		Array of vote vote counts. Parallel with item_indexes.
 * @param client_info		Array of clients.  Use VOTEINFO_CLIENT_ defines.
 * @param item_info			Array of items, sorted by count.  Use VOTEINFO_ITEM
 *							defines.
 */
stock void NativeVotes_FixResults(int num_clients,
							const int[] client_indexes,
							const int[] client_votes,
							int num_items,
							const int[] item_indexes,
							const int[] item_votes,
							int[][] client_info, 
							int[][] item_info)
{
	for (int i = 0; i < num_clients; ++i)
	{
		client_info[i][VOTEINFO_CLIENT_INDEX] = client_indexes[i];
		client_info[i][VOTEINFO_CLIENT_ITEM] = client_votes[i];
	}
	
	for (int i = 0; i < num_items; ++i)
	{
		item_info[i][VOTEINFO_ITEM_INDEX] = item_indexes[i];
		item_info[i][VOTEINFO_ITEM_VOTES] = item_votes[i];
	}
}

/**
 * Sets an advanced vote handling callback.  If this callback is set,
 * MenuAction_VoteEnd will not be called.
 *
 * @param vote				NativeVotes Handle.
 * @param callback			Callback function.
 * @error					Invalid Handle or callback.
 */
native void NativeVotes_SetResultCallback(Handle vote, NativeVotes_VoteHandler callback);

/**
 * Returns the number of seconds you should "wait" before displaying
 * a public vote.  This number is the time remaining until
 * (last_vote + sm_vote_delay).
 *
 * @return					Number of seconds to wait, or 0 for none.
 */
native int NativeVotes_CheckVoteDelay();

/**
 * Returns whether a client is in the pool of clients allowed 
 * to participate in the current vote.  This is determined by 
 * the client list passed to NativeVotes_Display().
 *
 * @param client			Client index.
 * @return					True if client is allowed to vote, false otherwise.
 * @error					If no vote is in progress or client index is invalid.
 */
native bool NativeVotes_IsClientInVotePool(int client);

/**
 * Redraws the current vote to a client in the voting pool.
 *
 * @param client			Client index.
 * @param revotes			True to allow revotes, false otherwise.
 * @return					True on success, false if the client is in the vote pool 
 *							but cannot vote again.
 * @error					No vote in progress, client is not in the voting pool, 
 *							or client index is invalid.
 */
native bool NativeVotes_RedrawClientVote(int client, bool revotes=true);

/**
 * Retrieve the vote type
 * 
 * @param vote				NativeVotes Handle.
 * @return					The built in vote type
 * @error					Invalid Handle
 */
native NativeVotesType NativeVotes_GetType(Handle vote);

/**
 * Set the team this vote is for, or NATIVEVOTES_ALL_TEAMS for all teams.
 * 
 * Defaults to NATIVEVOTES_ALL_TEAMS if not explicitly set.
 * 
 * @param vote				NativeVotes Handle.
 * @param team				Team number this vote is for
 * @error					Invalid Handle
 */
native void NativeVotes_SetTeam(Handle vote, int team);

/**
 * Retrieve the team this vote is for
 * 
 * @param vote				NativeVotes Handle.
 * @return					Team index or NATIVEVOTES_ALL_TEAMS for all teams.
 * @error					Invalid Handle
 */
native int NativeVotes_GetTeam(Handle vote);

/**
 * Set the client index of the player who initiated the vote.
 * Use NATIVEVOTES_SERVER_INDEX if initiated by the server itself.
 * 
 * Defaults to NATIVEVOTES_SERVER_INDEX if not explicitly set.
 * 
 * @param vote				NativeVotes Handle.
 * @param client			Client who initiated the vote or NATIVEVOTES_SERVER_INDEX
 * @error					Invalid Handle
 */
native void NativeVotes_SetInitiator(Handle vote, int client);

/**
 * Retrieve the client index of the player who initiated the vote or NATIVEVOTES_SERVER_INDEX if 
 * initiated by the server itself.
 * 
 * @param					Vote handle
 * @return					Client index or NATIVEVOTES_SERVER_INDEX
 * @error					Invalid Handle
 */
native int NativeVotes_GetInitiator(Handle vote);

/**
 * Broadcasts a vote to a list of clients.  The most selected item will be 
 * returned through MenuAction_VoteEnd.  On a tie, a random item will be returned 
 * from a list of the tied items.
 *
 * Note that MenuAction_VoteStart, MenuAction_VoteCancel, MenuAction_VoteEnd, and MenuAction_End are all
 * default callbacks and do not need to be enabled.
 *
 * @param vote				Vote Handle.
 * @param clients			Array of clients to broadcast to.
 * @param numClients		Number of clients in the array.
 * @param time				Maximum time to leave menu on the screen.
 * @param flags				Optional voting flags (i.e. VOTEFLAG_NO_REVOTES)
 * @return					True on success, false if a vote is already in progress.
 * @error					Invalid Handle, or a vote is already in progress.
 */
native bool NativeVotes_Display(Handle vote, int[] clients, int numClients, int time, int flags=0);

/**
 * Sends a vote menu to all clients.  See NativeVotes_Display() for more information.
 *
 * @param vote				Vote Handle.
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if this menu already has a vote session
 *							in progress.
 * @error					Invalid Handle, or a vote is already in progress.
 */
stock bool NativeVotes_DisplayToAll(Handle vote, int time)
{
	int total = 0;
	int[] players = new int[MaxClients];
	
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		players[total++] = i;
	}
	
	return NativeVotes_Display(vote, players, total, time);
}

/**
 * Sends a vote menu to a single team.  See NativeVotes_Display() for more information.
 *
 * @param vote				Vote Handle.
 * @param team				Team to send vote to. 1 = spectators, 2 = RED/Survivors/Terrorists, 3 = BLU/Infected/Counter-Terrorists
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if this menu already has a vote session
 *							in progress.
 * @error					Invalid Handle, or a vote is already in progress.
 */
#pragma deprecated This functionality should be done in client plugins instead
stock bool NativeVotes_DisplayToTeam(Handle vote, int team, int time)
{
	NativeVotes_SetTeam(vote, team);

	int total;
	int[] players = new int[MaxClients];
	
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) != team))
			continue;
		players[total++] = i;
	}
	
	return NativeVotes_Display(vote, players, total, time);
}

/**
 * Sends a vote menu to all clients who are not spectators or waiting to choose a team.  See NativeVotes_Display() for more information.
 *
 * @param vote				Vote Handle.
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if this menu already has a vote session
 *							in progress.
 * @error					Invalid Handle, or a vote is already in progress.
 */
#pragma deprecated This functionality should be done in client plugins instead
stock bool NativeVotes_DisplayToAllNonSpectators(Handle vote, int time)
{
	int total;
	int[] players = new int[MaxClients];
	
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) < 2))
			continue;
		players[total++] = i;
	}
	
	return NativeVotes_Display(vote, players, total, time);
}

/**
 * Display default vote passed screen for this vote type
 *
 * You MUST call one of the NativeVotes_DisplayPass* or NativeVotes_DisplayFail functions
 * to hide the vote screen for users who didn't vote, and to clear out their selection
 * for the next vote.
 * 
 * The format string/any args are a Valve format string or the item that won the vote.
 *
 * @param vote				Vote handle
 * @param fmt 				Message string format
 * @param ...				Message string arguments.
 */
native void NativeVotes_DisplayPass(Handle vote, const char[] fmt="", any ...);

/**
 * Display vote passed screen with custom text to a single user
 *
 * You MUST call one of the NativeVotes_DisplayPass* or NativeVotes_DisplayFail functions
 * to hide the vote screen for users who didn't vote, and to clear out their selection
 * for the next vote.
 * 
 * You should favor DisplayPassCustom over this function as you must send a
 * NativeVotes_DisplayPass to all clients
 * 
 * The format string/any args are a Valve format string or the item that won the vote.
 *
 * @param vote				Vote handle
 * @param client			Client to display pass screen to.
 * @param fmt 				Message string format
 * @param ...				Message string arguments.
 */
native void NativeVotes_DisplayPassCustomToOne(Handle vote, int client, const char[] fmt, any ...);

/**
 * Display vote passed screen with custom text
 *
 * You MUST call one of the NativeVotes_DisplayPass* or NativeVotes_DisplayFail functions
 * to hide the vote screen for users who didn't vote, and to clear out their selection
 * for the next vote.
 * 
 * The format string/any args are a Valve format string or the item that won the vote.
 * 
 * @param vote				Vote handle
 * @param fmt 				Message string format
 * @param ...				Message string arguments.
 */
stock void NativeVotes_DisplayPassCustom(Handle vote, const char[] fmt, any ...)
{
	char buffer[192];
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), fmt, 3);
			NativeVotes_DisplayPassCustomToOne(vote, i, "%s", buffer);
		}
	}
}

/**
 * Display vote passed screen with a custom type.
 *
 * A sample usage of this would be if Extend won an RTV vote: NativeVotes_DisplayPassEx(vote, NativeVotesPass_Extend, map);
 *
 * You MUST call one of the NativeVotes_DisplayPass* or NativeVotes_DisplayFail functions
 * to hide the vote screen for users who didn't vote, and to clear out their selection
 * for the next vote.
 * 
 * The format string/any args are a Valve format string or the item that won the vote.
 * 
 * @param vote				Vote handle
 * @param passType			The pass screen to display
 * @param fmt 				Message string format
 * @param ...				Message string arguments.
 */
native void NativeVotes_DisplayPassEx(Handle vote, NativeVotesPassType passType, const char[] fmt="", any ...);

/**
 * Display vote passed screen to a single client when a vote isn't running
 *
 * Check NativeVotes_IsVoteInProgress() first as this function won't work while a vote is running.
 *
 * Don't confuse this function with NativeVotes_DisplayPassEx, as that function properly adjusts the state on the vote
 *   Handle, while this function doesn't.
 * 
 * @param client			client to display to
 * @param passType			The pass screen to display
 * @param team				Which team to show this to? Likely you want one of 
 * 							NATIVEVOTES_ALL_TEAMS, NATIVEVOTES_TEAM_1, or NATIVEVOTES_TEAM_2
 * @param fmt 				Message string format
 * @param ...				Message string arguments.
 */
native void NativeVotes_DisplayRawPassToOne(int client, NativeVotesPassType passType, int team=NATIVEVOTES_ALL_TEAMS, const char[] fmt="", any ...);

/**
 * Display vote passed screen when a vote isn't running
 *
 * Check NativeVotes_IsVoteInProgress() first as this function won't work while a vote is running.
 *
 * Don't confuse this function with NativeVotes_DisplayPassEx, as that function properly adjusts the state on the vote
 *   Handle, while this function doesn't.
 * 
 * The format string/any args are a Valve format string or the item that won the vote.
 * 
 * @param passType			The pass screen to display
 * @param team				Which team to show this to? Likely you want one of 
 * 							NATIVEVOTES_ALL_TEAMS, NATIVEVOTES_TEAM_1, or NATIVEVOTES_TEAM_2
 * @param fmt 				Message string format
 * @param ...				Message string arguments.
 */
stock void NativeVotes_DisplayRawPassToAll(NativeVotesPassType passType, int team=NATIVEVOTES_ALL_TEAMS, const char[] fmt="", any ...)
{
	char buffer[192];
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), fmt, 4);
			NativeVotes_DisplayRawPassToOne(i, passType, team, "%s", buffer);
		}
	}	
}

/**
 * Display vote passed screen when a vote isn't running
 *
 * Check NativeVotes_IsVoteInProgress() first as this function won't work while a vote is running.
 *
 * Don't confuse this function with NativeVotes_DisplayPassEx, as that function properly adjusts the state on the vote
 *   Handle, while this function doesn't.
 * 
 * The format string/any args are a Valve format string or the item that won the vote.
 * 
 * @param clients			List of clients to display to
 * @param numClients		Number of clients to send this to.
 * @param passType			The pass screen to display
 * @param details			Normally the item that won the vote. Also used for custom vote winners
 * @param team				Which team to show this to? Likely you want one of 
 * 							NATIVEVOTES_ALL_TEAMS, NATIVEVOTES_TEAM_1, or NATIVEVOTES_TEAM_2
 */
stock void NativeVotes_DisplayRawPass(int[] clients, int numClients, NativeVotesPassType passType, int team=NATIVEVOTES_ALL_TEAMS, const char[] fmt="", any ...)
{
	char buffer[192];
	
	for (int i = 0; i <= numClients; ++i)
	{
		if (IsClientInGame(clients[i]) && !IsFakeClient(clients[i]))
		{
			SetGlobalTransTarget(clients[i]);
			VFormat(buffer, sizeof(buffer), fmt, 4);
			NativeVotes_DisplayRawPassToOne(clients[i], passType, team, "%s", buffer);
		}
	}	
}

/**
 * Display vote passed screen with custom text to a single client when a vote isn't running
 *
 * Don't confuse this function with NativeVotes_DisplayPassCustomToOne, as that function properly adjusts the state on the vote
 *   Handle, while this function doesn't.
 * 
 * @param client			client to display to
 * @param team				Which team to show this to? Likely you want one of 
 * 							NATIVEVOTES_ALL_TEAMS, NATIVEVOTES_TEAM_1, or NATIVEVOTES_TEAM_2
 * @param fmt 				Message string format
 * @param ...				Message string arguments.
 */
native void NativeVotes_DisplayRawPassCustomToOne(int client, int team, const char[] fmt, any ...);

/**
 * Display vote passed screen with custom text to all clients when a vote isn't running
 *
 * Don't confuse this function with NativeVotes_DisplayPassCustom, as that function properly adjusts the state on the vote
 *   Handle, while this function doesn't.
 * 
 * @param team				Which team to show this to? Likely you want one of 
 * 							NATIVEVOTES_ALL_TEAMS, NATIVEVOTES_TEAM_1, or NATIVEVOTES_TEAM_2
 * @param fmt 				Message string format
 * @param ...				Message string arguments.
 */
stock void NativeVotes_DisplayRawPassCustomToAll(int team, const char[] fmt, any ...)
{
	char buffer[192];
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		SetGlobalTransTarget(i);
		VFormat(buffer, sizeof(buffer), fmt, 3);
		NativeVotes_DisplayRawPassCustomToOne(i, team, "%s", buffer);
	}
}

/**
 * Display vote passed screen with custom text when a vote isn't running
 *
 * Don't confuse this function with NativeVotes_DisplayPassCustom, as that function properly adjusts the state on the vote
 *   Handle, while this function doesn't.
 * 
 * @param team				Which team to show this to? Likely you want one of 
 * 							NATIVEVOTES_ALL_TEAMS, NATIVEVOTES_TEAM_1, or NATIVEVOTES_TEAM_2
 * @param fmt 				Message string format
 * @param ...				Message string arguments.
 */
stock void NativeVotes_DisplayRawPassCustom(int[] clients, int numClients, int team, const char[] fmt, any ...)
{
	char buffer[192];
	
	for (int i = 0; i <= numClients; ++i)
	{
		if (!IsClientInGame(clients[i]) || IsFakeClient(clients[i]))
			continue;
		SetGlobalTransTarget(clients[i]);
		VFormat(buffer, sizeof(buffer), fmt, 5);
		NativeVotes_DisplayRawPassCustomToOne(clients[i], team, "%s", buffer);
	}
}

/**
 * Display vote failure screen to all users in a vote.
 *
 * You MUST call one of the NativeVotes_DisplayPass* or NativeVotes_DisplayFail functions
 * to hide the vote screen for users who didn't vote, and to clear out their selection
 * for the next vote.
 * 
 * @param vote				Vote handle
 * @param reason			Vote failure reason from NativeVotesFailType enum
 */
native void NativeVotes_DisplayFail(Handle vote, NativeVotesFailType reason=NativeVotesFail_Generic);

/**
 * Display vote failure screen.
 *
 * This version is used to display the vote failure screen when a vote isn't actually running.
 *
 * Don't confuse this function with NativeVotes_DisplayFail, as that function properly adjusts the state on the vote
 *   Handle, while this function doesn't.
 * 
 * @param reason			Vote failure reason from NativeVotesFailType enum
 * @param team				Which team to show this to? Likely you want one of 
 * 							NATIVEVOTES_ALL_TEAMS, NATIVEVOTES_TEAM_1, or NATIVEVOTES_TEAM_2
 */
native void NativeVotes_DisplayRawFail(int[] clients, int numClients, NativeVotesFailType reason=NativeVotesFail_Generic, int team=NATIVEVOTES_ALL_TEAMS);

/**
 * Display vote failure screen to all clients.
 *
 * This version is used to display the vote failure screen when a vote isn't actually running.
 * 
 * @param reason				Vote failure reason from NativeVotesFailType enum
 * @param team				Which team to show this to? Likely you want one of 
 * 							NATIVEVOTES_ALL_TEAMS, NATIVEVOTES_TEAM_1, or NATIVEVOTES_TEAM_2
 */
stock void NativeVotes_DisplayRawFailToAll(NativeVotesFailType reason=NativeVotesFail_Generic, int team=NATIVEVOTES_ALL_TEAMS)
{
	int total = 0;
	int[] players = new int[MaxClients];
	
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		players[total++] = i;
	}
	
	NativeVotes_DisplayRawFail(players, total, reason, team);
	return;
}

/**
 * Display vote failure screen to one client.
 *
 * This version is used to display the vote failure screen when a vote isn't actually running.
 * 
 * @param client				client to display to
 * @param reason				Vote failure reason from NativeVotesFailType enum
 * @param team				Which team to show this to? Likely you want one of 
 * 							NATIVEVOTES_ALL_TEAMS, NATIVEVOTES_TEAM_1, or NATIVEVOTES_TEAM_2
 */
stock void NativeVotes_DisplayRawFailToOne(int client, NativeVotesFailType reason=NativeVotesFail_Generic, int team=NATIVEVOTES_ALL_TEAMS)
{
	int players[1];
	
	players[0] = client;
	

	NativeVotes_DisplayRawFail(players, 1, reason, team);
	return;
}

/**
 * Quick stock to determine whether voting is allowed.  This doesn't let you 
 * fine-tune a reason for not voting, so it's not recommended for lazily 
 * telling clients that voting isn't allowed.
 * 
 * @return				True if voting is allowed, false if voting is in progress
 *						or the cooldown is active.
 */
stock bool NativeVotes_IsNewVoteAllowed()
{
	if (NativeVotes_IsVoteInProgress() || NativeVotes_CheckVoteDelay() != 0)
	{
		return false;
	}
	
	return true;
}
/**
 * Forward for "callvote" handling
 * 
 * If a vote is already running, callvote will silently fail and this function will never be called.
 * This is standard in-game behavior to prevent callvote from interfering with running votes.
 * 
 * You should respond to this by starting a vote, calling NativeVotes_DisplayCallVoteFail, or printing a message in chat
 * (for votes that require more than one person to use it).
 * 
 * The callvote panel always vanishes when a user chooses an option, so NativeVotes_DisplayCallVoteFail isn't mandatory.
 */
typeset NativeVotes_CallVoteHandler
{
	/**
	 * For kick votes
	 * 
	 * @param client		Client running callvote.
	 * @param voteCommand	The vote command used.
	 * @param voteArgument	Vote argument or blank if the vote type has no argument.
	 * @param kickType		For kick votes, the kick type. For all other types, NativeVotesType_None.
	 * @param target		For kick votes, the target userid.
	 * @return				Plugin_Continue to allow the server itself (or another plugin) to process the callvote
	 * 						Plugin_Handled if you processed this vote type
	 * 						Plugin_Stop to block the vote type (not recommended)
	 */	
	function Action (int client, NativeVotesOverride overrideType, const char[] voteArgument, NativeVotesKickType kickType, int target);
	
	/**
	 * For votes whose args you want to see
	 * 
	 * @param client		Client running callvote.
	 * @param voteCommand	The vote command used.
	 * @param voteArgument	Vote argument or blank if the vote type has no argument.
	 * @return				Plugin_Continue to allow the server itself (or another plugin) to process the callvote
	 * 						Plugin_Handled if you processed this vote type
	 * 						Plugin_Stop to block the vote type (not recommended)
	 */	
	function Action (int client, NativeVotesOverride overrideType, const char[] voteArgument);
	
	/**
	 * For votes whose args you DON'T want to see
	 * 
	 * @param client		Client running callvote.
	 * @param voteCommand	The vote command used.
	 * @return				Plugin_Continue to allow the server itself (or another plugin) to process the callvote
	 * 						Plugin_Handled if you processed this vote type
	 * 						Plugin_Stop to block the vote type (not recommended)
	 */	
	function Action (int client, NativeVotesOverride overrideType);
}

/**
 * Forward for "callvote" visibility check.
 * This forward is called once for each registered vote command
 * 
 * Note: If other plugins have the same vote name registered, they may block it.
 * 
 * @param client		Client running callvote.
 * @param voteCommand	The vote command used.
 * @return				Plugin_Continue will show the vote.
 *						Plugin_Handled or Plugin_Stop will hide the vote from this user.
 *
 * The highest return value will be the one that takes effect.
 */
typedef NativeVotes_CallVoteVisCheck = function Action (int client, NativeVotesOverride overrideType);

/**
 * Are vote commands supported by this game?
 * 
 * @return			true if they are supported, false if not.
 *                     As of this writing, only TF2 will return true
 */
native bool NativeVotes_AreVoteCommandsSupported();

/**
 * Register a vote command for the callvote command.
 * 
 * This function is only relevant to TF2.
 * 
 * @param overrideType		Type of vote to hook in the menu.
 * @param callHandler		Handler to register
 * @param visHandler		Optional Handler to determine if this vote is visible to a player
 */
native void NativeVotes_RegisterVoteCommand(NativeVotesOverride overrideType, NativeVotes_CallVoteHandler callHandler, NativeVotes_CallVoteVisCheck visHandler=INVALID_FUNCTION);

/**
 * Unregister a vote command for the callvote command 
 * 
 * This function is only relevant to TF2.
 * 
 * @param overrideType		Type of vote to hook in the menu.
 * @param callHandler		Handler to register
 * @param visHandler		Optional Handler to determine if this vote is visible to a player
 */
native void NativeVotes_UnregisterVoteCommand(NativeVotesOverride overrideType, NativeVotes_CallVoteHandler callHandler, NativeVotes_CallVoteVisCheck visHandler=INVALID_FUNCTION);

/**
 * Send a call vote fail screen to a user
 * Used to respond to a callvote with invalid arguments or for other reasons
 * (such as trying to target an admin for a kick/ban vote)
 * 
 * @param client		The client to display the fail screen to
 * @param reason		A vote call fail reason
 * @param time			For NativeVotesCallFail_Recent, the number of seconds until client can call any votes.
 *						For NativeVotesCallFail_Failed, the number of seconds until the vote can be called again
 *						For NativeVotesCallFail_PlayerNotFound, may be the player userid
 */
native void NativeVotes_DisplayCallVoteFail(int client, NativeVotesCallFailType reason, int time=0);

/**
 * Register an alternative map list to use instead of the core map list.
 * This only works on games that support vote commands (i.e. TF2)
 *
 * This callback will be called the first time a user opens the vote menu
 * 
 * It is recommended that a nominations plugin be in charge of this.
 *
 * The StringMap should use display name as the key and the mapcycle-style name as the value
 * Note: These can be things that aren't maps for votes like UMC's group vote
 *
 * @param client		The client viewing the map list
 * @param mapList 		StringMap of maps.
 *						By default, this will contain the default mapcycle from the mapcyclefile.
 * @return				Plugin_Changed if you added/changed the list, Plugin_Continue otherwise.
 */
forward Action NativeVotes_OverrideMaps(StringMap mapList);

/**
 * Redraws the vote title from inside a MenuAction_Display callback
 * Not supported on L4D
 * 
 * @param text			Vote title to draw
 * @error 				If called from outside MenuAction_Display
 * @return				Plugin_Changed if the change is allowed, Plugin_Continue if it isn't.
 */
native Action NativeVotes_RedrawVoteTitle(const char[] text);

/**
 * Redraws the vote text from inside a MenuAction_DisplayItem callback.
 * Only supported on multiple-choice votes
 * 
 * @param text			Vote text to draw.
 * @error 				If called from outside MenuAction_DisplayItem
 * @return				Plugin_Changed if the change is allowed, Plugin_Continue if it isn't.
 */
native Action NativeVotes_RedrawVoteItem(const char[] text);

/**
 * Retrieves voting information from MenuAction_VoteEnd.
 *
 * @param param2		Second parameter of MenuAction_VoteEnd.
 * @param winningVotes	Number of votes received by the winning option.
 * @param totalVotes	Number of total votes received.
 */
stock void NativeVotes_GetInfo(int param2, int &winningVotes, int &totalVotes)
{
	winningVotes = param2 & 0xFFFF;
	totalVotes = param2 >> 16;
}

/**
 * Do not edit below this line!
 */
public SharedPlugin __pl_nativevotes = 
{
	name = "nativevotes",
	file = "nativevotes.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_nativevotes_SetNTVOptional()
{
	MarkNativeAsOptional("NativeVotes_IsVoteTypeSupported");
	MarkNativeAsOptional("NativeVotes_Create");
	MarkNativeAsOptional("NativeVotes_Close");
	MarkNativeAsOptional("NativeVotes_AddItem");
	MarkNativeAsOptional("NativeVotes_InsertItem");
	MarkNativeAsOptional("NativeVotes_RemoveItem");
	MarkNativeAsOptional("NativeVotes_RemoveAllItems");
	MarkNativeAsOptional("NativeVotes_GetItem");
	MarkNativeAsOptional("NativeVotes_GetItemCount");
	MarkNativeAsOptional("NativeVotes_SetDetails");
	MarkNativeAsOptional("NativeVotes_GetDetails");
	MarkNativeAsOptional("NativeVotes_SetTitle");
	MarkNativeAsOptional("NativeVotes_GetTitle");
	MarkNativeAsOptional("NativeVotes_SetTarget");
	MarkNativeAsOptional("NativeVotes_GetTarget");
	MarkNativeAsOptional("NativeVotes_GetTargetSteam");
	MarkNativeAsOptional("NativeVotes_IsVoteInProgress");
	MarkNativeAsOptional("NativeVotes_GetMaxItems");
	MarkNativeAsOptional("NativeVotes_SetOptionFlags");
	MarkNativeAsOptional("NativeVotes_GetOptionFlags");
	MarkNativeAsOptional("NativeVotes_SetNoVoteButton");
	MarkNativeAsOptional("NativeVotes_Cancel");
	MarkNativeAsOptional("NativeVotes_SetResultCallback");
	MarkNativeAsOptional("NativeVotes_CheckVoteDelay");
	MarkNativeAsOptional("NativeVotes_IsClientInVotePool");
	MarkNativeAsOptional("NativeVotes_RedrawClientVote");
	MarkNativeAsOptional("NativeVotes_GetType");
	MarkNativeAsOptional("NativeVotes_SetTeam");
	MarkNativeAsOptional("NativeVotes_GetTeam");
	MarkNativeAsOptional("NativeVotes_SetInitiator");
	MarkNativeAsOptional("NativeVotes_GetInitiator");
	MarkNativeAsOptional("NativeVotes_Display");
	MarkNativeAsOptional("NativeVotes_DisplayPass");
	MarkNativeAsOptional("NativeVotes_DisplayPassCustomToOne");
	MarkNativeAsOptional("NativeVotes_DisplayPassEx");
	MarkNativeAsOptional("NativeVotes_DisplayRawPassToOne");
	MarkNativeAsOptional("NativeVotes_DisplayRawPassCustomToOne");
	MarkNativeAsOptional("NativeVotes_DisplayFail");
	MarkNativeAsOptional("NativeVotes_DisplayRawFail");
	MarkNativeAsOptional("NativeVotes_DisplayRawFailToOne");
	MarkNativeAsOptional("NativeVotes_AreVoteCommandsSupported");
	MarkNativeAsOptional("NativeVotes_RegisterVoteCommand");
	MarkNativeAsOptional("NativeVotes_UnregisterVoteCommand");
	MarkNativeAsOptional("NativeVotes_IsVoteCommandRegistered");
	MarkNativeAsOptional("NativeVotes_DisplayCallVoteFail");
	MarkNativeAsOptional("NativeVotes_RedrawVoteTitle");
	MarkNativeAsOptional("NativeVotes_RedrawVoteItem");
}
#endif
