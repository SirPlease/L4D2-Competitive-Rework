/**
 * vim: set ts=4 :
 * =============================================================================
 * BuiltinVotes (C)2011 Ross Bemrose (Powerlord).  All rights reserved.
 * =============================================================================
 *
 * This file is part of the BuiltinVotes addon.
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

#if defined _builtinvotes_included_stocks
	#endinput
#endif
#define _builtinvotes_included_stocks

// Does not support direct inclusion
#if !defined _builtinvotes_included
	#endinput
#endif

/* Source: https://github.com/L4D-Community/builtinvotes/blob/master/extra/include/builtinvotes_stocks.inc */

enum eVoteType
{
	eVoteNone = -1,
	eBuiltinVote = 0,
	eGameVote = 1
};

/**
 * Sends a vote menu to all clients.  See DisplayBuiltinVote() for more information.
 *
 * @param vote				Vote Handle.
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if this menu already has a vote session
 *							in progress.
 * @error					Invalid Handle.
 */
stock bool DisplayBuiltinVoteToAll(Handle vote, int time)
{
	int iNumPlayers;
	int[] iPlayers = new int[MaxClients];

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || IsFakeClient(i)) {
			continue;
		}

		iPlayers[iNumPlayers++] = i;
	}

	return DisplayBuiltinVote(vote, iPlayers, iNumPlayers, time);
}

/**
 * Quick stock to determine whether voting is allowed.  This doesn't let you
 * fine-tune a reason for not voting, so it's not recommended for lazily
 * telling clients that voting isn't allowed.
 * Checks if a game or builtinvote vote is in progress
 *
 * @return				True if voting is allowed, false if voting is in progress
 *						or the cooldown is active.
 */
stock bool IsNewBuiltinVoteAllowed()
{
	return (!(IsBuiltinVoteInProgress() || CheckBuiltinVoteDelay() != 0));
}

/**
 * Returns the type of vote currently in progress
 *
 * @return eVoteType        eVoteNone (-1) - if the vote is not in progress now,
 *							eBuiltinVote (0) - if 'builtinvote' voting is in progress,
 *							eGameVote (1) - if in-game voting is in progress.
 */
stock eVoteType GetVoteType_InProgress()
{
	if (BuiltinVote_IsVoteInProgress()) {
		return eBuiltinVote;
	}

	if (Game_IsVoteInProgress()) {
		return eGameVote;
	}

	return eVoteNone;
}

/**
 * Retrieves voting information from BuiltinVoteAction_VoteEnd.
 *
 * @param param2		Second parameter of BuiltinVoteAction_VoteEnd.
 * @param winningVotes	Number of votes received by the winning option.
 * @param totalVotes	Number of total votes received.
 * @noreturn
 */
stock void GetBuiltinVoteInfo(int param2, int &winningVotes, int &totalVotes)
{
	winningVotes = param2 & 0xFFFF;
	totalVotes = param2 >> 16;
}

/**
 * Sends a vote menu to a single team.  See DisplayBuiltinVote() for more information.
 *
 * @param vote				Vote Handle.
 * @param team				Team to send vote to. 1 = spectators, 2 = RED/Survivors, 3 = BLU/Infected
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if this menu already has a vote session
 *							in progress.
 * @error					Invalid Handle.
 */
stock bool DisplayBuiltinVoteToTeam(Handle vote, int team, int time)
{
	SetBuiltinVoteTeam(vote, team);

	int iNumPlayers;
	int[] iPlayers = new int[MaxClients];

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) != team)) {
			continue;
		}

		iPlayers[iNumPlayers++] = i;
	}

	return DisplayBuiltinVote(vote, iPlayers, iNumPlayers, time);
}

/**
 * Sends a vote menu to all clients except one.  See DisplayBuiltinVote() for more information.
 * Useful for kick/ban votes
 *
 * @param vote				Vote Handle.
 * @param client			Client index not to send vote to
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if this menu already has a vote session
 *							in progress or if the client isn't in the game.
 * @error					Invalid Handle.
 */
stock bool DisplayBuiltinVoteToAllButOne(Handle vote, int client, int time)
{
	if (!IsClientInGame(client)) {
		return false;
	}

	int iNumPlayers;
	int[] iPlayers = new int[MaxClients];

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || IsFakeClient(i) || (i == client)) {
			continue;
		}

		iPlayers[iNumPlayers++] = i;
	}

	return DisplayBuiltinVote(vote, iPlayers, iNumPlayers, time);
}

/**
 * Sends a vote menu to a single team except one player.  See DisplayBuiltinVote() for more information.
 *
 * @param vote				Vote Handle.
 * @param client			Client index not to send vote to.  Team is derived from this client.
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if this menu already has a vote session
 *							in progress or the client isn't in the game.
 * @error					Invalid Handle.
 */
stock bool DisplayBuiltinVoteToTeamButOne(Handle vote, int client, int time)
{
	if (!IsClientInGame(client)) {
		return false;
	}

	int team = GetClientTeam(client);

#if 0
	if (team < 2) {
		return false;
	}
#endif

	SetBuiltinVoteTeam(vote, team);

	int iNumPlayers;
	int[] iPlayers = new int[MaxClients];

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || IsFakeClient(i) || (i == client) || (GetClientTeam(i) != team)) {
			continue;
		}

		iPlayers[iNumPlayers++] = i;
	}

	return DisplayBuiltinVote(vote, iPlayers, iNumPlayers, time);
}

/**
 * Sends a vote menu to all clients who are not spectators or waiting to choose a team.  See DisplayBuiltinVote() for more information.
 *
 * @param vote				Vote Handle.
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if this menu already has a vote session
 *							in progress.
 * @error					Invalid Handle.
 */
stock bool DisplayBuiltinVoteToAllNonSpectators(Handle vote, int time)
{
	int iNumPlayers;
	int[] iPlayers = new int[MaxClients];

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) < 2)) {
			continue;
		}

		iPlayers[iNumPlayers++] = i;
	}

	return DisplayBuiltinVote(vote, iPlayers, iNumPlayers, time);
}
