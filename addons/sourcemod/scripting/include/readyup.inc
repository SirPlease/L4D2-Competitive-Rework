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
#if defined  _readyup_included_
 #endinput
#endif
#define _readyup_included_

/**
 * Called when the live countdown ends and the round goes live
 */
forward void OnRoundIsLive();

/**
 * Returns the index of a item in the footer array.
 * Does not have to be exact. The footer only needs to contain the input, does not need to match.
 *
 * @param index    	Index of string
 * @param buffer	Where to store result
 * @param maxlength	Max length of buffer
 * @return          String at specified index
 */
native int GetFooterStringAtIndex(int index, char[] buffer, int maxlength);

/**
 * Returns the index of a item in the footer array.
 * Does not have to be exact. The footer only needs to contain the input, does not need to match.
 *
 * @param string    String to search for
 * @return          Int index of string
 */
native int FindIndexOfFooterString(const char[] string);

/**
 * Edits a footer string on the ready-up panel at the specified index.
 *
 * @param index  	Index of string to edit
 * @param string    String to add to the footer
 * @return          True if the string was added, false otherwise
 */
native bool EditFooterStringAtIndex(int index, const char[] string);

/**
 * Adds the string to the bottom of the ready-up panel.
 * String must be <=65 characters including the null byte.
 * String will be entirely added or not added, no truncation.
 *
 * @param footer    String to add to the footer
 * @return          Int Index of string in footer.
 */
native int AddStringToReadyFooter(const char[] footer);

/**
 * Whether or not the game is currently waiting for players to ready up.
 *
 * @return          True if the game is currently in the ready-up phase.
 */
native bool IsInReady();

/**
 * If this in-game and fully connected client is a caster or not
 *
 * @return          True if this is a registered caster
 */
native bool IsClientCaster(int client);

/**
 * If this Steam ID is a registered caster or not
 *
 * @param           String containing the user's auth id
 * @return          True if this is a registered caster
 */
native bool IsIDCaster(const char[] AuthID);

public SharedPlugin __pl_readyup =
{
	name = "readyup",
	file = "readyup.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_readyup_SetNTVOptional()
{
	MarkNativeAsOptional("GetFooterStringAtIndex");
	MarkNativeAsOptional("FindIndexOfFooterString");
	MarkNativeAsOptional("EditFooterStringAtIndex");
	MarkNativeAsOptional("AddStringToReadyFooter");
	MarkNativeAsOptional("IsInReady");
	MarkNativeAsOptional("IsClientCaster");
	MarkNativeAsOptional("IsIDCaster");
}
#endif

// vim: ft=sourcepawn et sw=8