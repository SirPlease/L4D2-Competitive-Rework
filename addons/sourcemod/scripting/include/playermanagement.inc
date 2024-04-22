/*
	SourcePawn is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2008 ITB CompuPhase.
	Source is Copyright (C) Valve Corporation.
	All trademarks are property of their respective owners.

	This program is free software: you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#if defined  _playermanagement_included_
 #endinput
#endif
#define _playermanagement_included_


/**
 * Changes the team of a client.
 *
 * @param client The client index.
 * @param team The team index to change to.
 * @param force (Optional) Forces the team change even if the client is not allowed to switch teams.
 * @return True if the team change was successful, false otherwise.
 */
native bool ChangeClientTeamEx(int client, int team, bool force = false)

public SharedPlugin __pl_playermanagement =
{
	name = "playermanagement",
	file = "playermanagement.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_playermanagement_SetNTVOptional()
{
	MarkNativeAsOptional("ChangeClientTeamEx");
}
#endif