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
#if defined l4d2_saferoom_detect_inc_
	#endinput
#endif
#define l4d2_saferoom_detect_inc_

/*
  Check if entity is in a saferoom
  returns bool (errors/incorrect data returns false)
*/
native bool SAFEDETECT_IsEntityInStartSaferoom(int entity);
native bool SAFEDETECT_IsEntityInEndSaferoom(int entity);

/*
  Check if player (client) is in a saferoom
  returns bool (errors/incorrect data returns false)
*/
native bool SAFEDETECT_IsPlayerInStartSaferoom(int client);
native bool SAFEDETECT_IsPlayerInEndSaferoom(int client);

public SharedPlugin __pl_l4d2_saferoom_detect =
{
	name = "l4d2_saferoom_detect",
	file = "l4d2_saferoom_detect.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_saferoom_detect_SetNTVOptional()
{
	MarkNativeAsOptional("SAFEDETECT_IsEntityInStartSaferoom");
	MarkNativeAsOptional("SAFEDETECT_IsEntityInEndSaferoom");
	MarkNativeAsOptional("SAFEDETECT_IsPlayerInStartSaferoom");
	MarkNativeAsOptional("SAFEDETECT_IsPlayerInEndSaferoom");
}
#endif
