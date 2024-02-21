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
#if defined _mp_transiation_included
 #endinput
#endif
#define _mp_transiation_included

/**
 * 设置自动切换的地图，map1 -> map2
 * @param map1      要进行切换的图
 * @param map2      切换到的图
 */
native int AddMapTransition(char[] map1, char[] map2);

/**
 * 删除所有进行自动切换的图 
 */
native int ResetAllMapTransition();

/**
 * 在自动切换列表中删除某张图
 * @param map       要删除的图（要切换的图，不是切换到的图）
 * @return          0执行成功，1失败
 */
native int RemoveMapTransition(char[] map);

public SharedPlugin __pl_mp_transiation =
{
	name = "mp_transiation",
	file = "mp_transiation.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_mp_transiation_SetNTVOptional()
{
	MarkNativeAsOptional("AddMapTransition");
	MarkNativeAsOptional("ResetAllMapTransition");
	MarkNativeAsOptional("RemoveMapTransition");
}
#endif