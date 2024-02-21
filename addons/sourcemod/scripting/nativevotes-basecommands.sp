/**
 * vim: set ts=4 :
 * =============================================================================
 * NativeVotes Basecommands Plugin
 * Provides cancelvote and revote functionality for NativeVotes
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
 
#include <sourcemod>
#include <nativevotes>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define VERSION "1.1"
#pragma newdecls required
#pragma semicolon 1

TopMenu hTopMenu;

public Plugin myinfo = 
{
	name = "NativeVotes Basic Commands",
	author = "Powerlord and AlliedModders LLC",
	description = "Revote and Cancel support for NativeVotes",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=208008"
}

public void OnPluginStart()
{
	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	
	AddCommandListener(Command_CancelVote, "sm_cancelvote");
	AddCommandListener(Command_ReVote, "sm_revote");
}

bool PerformCancelVote(int client)
{
	if (!NativeVotes_IsVoteInProgress())
	{
		return false;
	}

	ShowActivity2(client, "[NV] ", "%t", "Cancelled Vote");
	
	NativeVotes_Cancel();
	return true;
}

public Action Command_CancelVote(int client, const char[] command, int argc)
{
	if (!CheckCommandAccess(client, "sm_cancelvote", ADMFLAG_VOTE))
	{
		if (IsVoteInProgress())
		{
			// Let basecommands handle it
			return Plugin_Continue;
		}
		
		ReplyToCommand(client, "%t", "No Access");
		return Plugin_Stop;
	}
	
	if (PerformCancelVote(client))
	{
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Continue;
	}
}

public void AdminMenu_CancelVote(Handle topmenu, 
							  TopMenuAction action,
							  TopMenuObject object_id,
							  int param,
							  char[] buffer,
							  int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Cancel vote", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		PerformCancelVote(param);
		RedisplayAdminMenu(topmenu, param);	
	}
	else if (action == TopMenuAction_DrawOption)
	{
		buffer[0] = NativeVotes_IsVoteInProgress() ? ITEMDRAW_DEFAULT : ITEMDRAW_IGNORE;
	}
}

public Action Command_ReVote(int client, const char[] command, int argc)
{
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	if (!NativeVotes_IsVoteInProgress())
	{
		return Plugin_Continue;
	}
	
	if (!NativeVotes_IsClientInVotePool(client))
	{
		if (IsVoteInProgress())
		{
			// Let basecommands handle it
			return Plugin_Continue;
		}
		
		ReplyToCommand(client, "[NV] %t", "Cannot participate in vote");
		return Plugin_Stop;
	}
	
	if (NativeVotes_RedrawClientVote(client))
	{
		return Plugin_Stop;
	}
	else if (!IsVoteInProgress())
	{
		ReplyToCommand(client, "[NV] %t", "Cannot change vote");
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);
	
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	TopMenuObject voting_commands = hTopMenu.FindCategory(ADMINMENU_VOTINGCOMMANDS);

	if (voting_commands != INVALID_TOPMENUOBJECT)
	{
		hTopMenu.AddItem("sm_cancelvote", AdminMenu_CancelVote, voting_commands, "sm_cancelvote", ADMFLAG_VOTE);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, "adminmenu") == 0)
	{
		hTopMenu = null;
	}
}
