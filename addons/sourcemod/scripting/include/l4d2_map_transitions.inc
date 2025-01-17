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
#if defined  _l4d2_map_transitions_included_
 #endinput
#endif
#define _l4d2_map_transitions_included_

/**
 * @brief Get the next map name for map transition
 *
 * @param buffer	String to write map name, empty if no map transition set
 * @param maxlength	Max length of buffer
 * 
 * @noreturn
 */
native void l4d2_map_transitions_GetNextMap(char[] buffer, int maxlength);

/**
 * @brief Called when the plugin is about to force change next map
 *
 * @param sNextMapName	the next map name for map transition
 *
 * @return			Plugin_Handled to block map changing, Plugin_Continue otherwise
 */
forward Action l4d2_map_transitions_OnChangeNextMap_Pre(const char[] sNextMapName);

/**
 * @brief Called when the plugin is about to force change next map
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 * 
 * @param sNextMapName	the next map name for map transition
 *
 * @noreturn
 */
forward void l4d2_map_transitions_OnChangeNextMap_Post(const char[] sNextMapName);


public SharedPlugin __pl_l4d2_map_transitions =
{
	name = "l4d2_map_transitions",
	file = "l4d2_map_transitions.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_map_transitions_SetNTVOptional()
{
	MarkNativeAsOptional("l4d2_map_transitions_GetNextMap");
}
#endif