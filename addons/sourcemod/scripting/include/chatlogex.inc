/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod (C)2004-2011 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This file is part of the SourceMod/SourcePawn SDK.
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
 
#if defined _chatlogex_included
 #endinput
#endif
#define _chatlogex_included

enum ChatType
{
    // 玩家击杀信息
    CHATTYPE_KILL = -2,
    // 进入/离开消息通知类 地图修改/名称修改类
    CHATTYPE_EVENT = -1,
    // 存活客户端
    CHATTYPE_ALIVEALL = 0,
    CHATTYPE_ALIVETEAM = 2,
    // 死亡的客户端 (旁观者为死亡状态)
    CHATTYPE_DEATHALL = 1,
    CHATTYPE_DEATHTEAM = 3 
};

enum ChatTeam
{
    CHATTEAM_ANNOUNCE = -1,
    CHATTEAM_SPEC = 1,
    CHATTEAM_SURVIVOR = 2,
    CHATTEAM_INFECTED = 3
};

/**
 * 向Chatlog database中添加一条消息
 * 
 * @param clientname 该消息的发送者
 * @param clientAuthID 发送者的steamid
 * @param text 发送的文本
 * @param team 发送者所属队伍
 * @param type 发送的消息类型 
 * 
 * @return 0
 * 
 */
native int AddToChatLog(char[] clientname, char[] clientAuthID, char[] text, 
                            int team, int type);

/**
 * 向Chatlog database中添加一条注释型消息
 * 
 * @param text 消息文本
 * 
 * @return 0
 */
native int AddToChatLog2(char[] text);

public SharedPlugin __pl_chatlogex =
{
    name = "chatlogex",
    file = "chatlogex.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_chatlogex_SetNTVOptional()
{
    MarkNativeAsOptional("AddToChatLog");
    MarkNativeAsOptional("AddToChatLog2");
}
#endif