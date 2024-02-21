/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod NativeVotes Rock The Vote Plugin
 * Creates a map vote when the required number of players have requested one.
 * Updated with NativeVotes support
 *
 * NativeVotes (C)2011-2016 Ross Bemrose (Powerlord). All rights reserved.
 * SourceMod (C)2004-2014 AlliedModders LLC.  All rights reserved.
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
#include <mapchooser>

#undef REQUIRE_PLUGIN
#include <nativevotes>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define VERSION "1.8.0 beta 4"

public Plugin myinfo =
{
	name = "NativeVotes Map Nominations",
	author = "AlliedModders LLC and Powerlord",
	description = "Provides Map Nominations",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=208010"
};

ConVar g_Cvar_ExcludeOld;
ConVar g_Cvar_ExcludeCurrent;

Menu g_MapMenu = null;
ArrayList g_MapList = null;
int g_mapFileSerial = -1;

#define MAPSTATUS_ENABLED (1<<0)
#define MAPSTATUS_DISABLED (1<<1)
#define MAPSTATUS_EXCLUDE_CURRENT (1<<2)
#define MAPSTATUS_EXCLUDE_PREVIOUS (1<<3)
#define MAPSTATUS_EXCLUDE_NOMINATED (1<<4)

StringMap g_mapTrie = null;

// NativeVotes
bool g_NativeVotes;
bool g_RegisteredMenusChangeLevel = false;
bool g_RegisteredMenusNextLevel = false;

#define LIBRARY "nativevotes"

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("nominations.phrases");
	
	int arraySize = ByteCountToCells(PLATFORM_MAX_PATH);
	g_MapList = new ArrayList(arraySize);
	
	CreateConVar("nativevotes_nominations_version", VERSION, "NativeVotes Nominations version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	g_Cvar_ExcludeOld = CreateConVar("sm_nominate_excludeold", "1", "Specifies if the current map should be excluded from the Nominations list", 0, true, 0.00, true, 1.0);
	g_Cvar_ExcludeCurrent = CreateConVar("sm_nominate_excludecurrent", "1", "Specifies if the MapChooser excluded maps should also be excluded from Nominations", 0, true, 0.00, true, 1.0);
	
	RegConsoleCmd("sm_nominate", Command_Nominate);
	
	RegAdminCmd("sm_nominate_addmap", Command_Addmap, ADMFLAG_CHANGEMAP, "sm_nominate_addmap <mapname> - Forces a map to be on the next mapvote.");
	
	g_mapTrie = new StringMap();
}

public void OnPluginEnd()
{
	RemoveVoteHandler();
}

public void OnAllPluginsLoaded()
{
	if (FindPluginByFile("nominations.smx") != null)
	{
		LogMessage("Unloading mapchooser to prevent conflicts...");
		ServerCommand("sm plugins unload nominations");
		
		char oldPath[PLATFORM_MAX_PATH];
		char newPath[PLATFORM_MAX_PATH];
		
		BuildPath(Path_SM, oldPath, sizeof(oldPath), "plugins/nominations.smx");
		BuildPath(Path_SM, newPath, sizeof(newPath), "plugins/disabled/nominations.smx");
		if (RenameFile(newPath, oldPath))
		{
			LogMessage("Moving nominations to disabled.");
		}
	}
	
	g_NativeVotes = LibraryExists(LIBRARY) && 
		GetFeatureStatus(FeatureType_Native, "NativeVotes_AreVoteCommandsSupported") == FeatureStatus_Available && 
		NativeVotes_AreVoteCommandsSupported();
		
	if (g_NativeVotes)
		RegisterVoteHandler();
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, LIBRARY, false) && 
		GetFeatureStatus(FeatureType_Native, "NativeVotes_AreVoteCommandsSupported") == FeatureStatus_Available && 
		NativeVotes_AreVoteCommandsSupported())
	{
		g_NativeVotes = true;
		RegisterVoteHandler();
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, LIBRARY, false))
	{
		g_NativeVotes = false;
		RemoveVoteHandler();
	}
}

public void OnConfigsExecuted()
{
	if (ReadMapList(g_MapList,
					g_mapFileSerial,
					"nominations",
					MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER)
		== null)
	{
		if (g_mapFileSerial == -1)
		{
			SetFailState("Unable to create a valid map list.");
		}
	}
	
	delete g_MapMenu;
}

public void OnNominationRemoved(const char[] map, int owner)
{
	int status;
	
	char resolvedMap[PLATFORM_MAX_PATH];
	FindMap(map, resolvedMap, sizeof(resolvedMap));
	
	/* Is the map in our list? */
	if (!g_mapTrie.GetValue(resolvedMap, status))
	{
		return;	
	}
	
	/* Was the map disabled due to being nominated */
	if ((status & MAPSTATUS_EXCLUDE_NOMINATED) != MAPSTATUS_EXCLUDE_NOMINATED)
	{
		return;
	}
	
	g_mapTrie.SetValue(resolvedMap, MAPSTATUS_ENABLED);
}

public Action Command_Addmap(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_nominate_addmap <mapname>");
		return Plugin_Handled;
	}
	
	char mapname[PLATFORM_MAX_PATH];
	char resolvedMap[PLATFORM_MAX_PATH];
	GetCmdArg(1, mapname, sizeof(mapname));

	if (FindMap(mapname, resolvedMap, sizeof(resolvedMap)) == FindMap_NotFound)
	{
		// We couldn't resolve the map entry to a filename, so...
		ReplyToCommand(client, "%t", "Map was not found", mapname);
		return Plugin_Handled;		
	}
	
	char displayName[PLATFORM_MAX_PATH];
	GetMapDisplayName(resolvedMap, displayName, sizeof(displayName));
	
	int status;
	if (!g_mapTrie.GetValue(resolvedMap, status))
	{
		ReplyToCommand(client, "%t", "Map was not found", displayName);
		return Plugin_Handled;		
	}
	
	NominateResult result = NominateMap(resolvedMap, true, 0);
	
	if (result > Nominate_Replaced)
	{
		/* We assume already in vote is the casue because the maplist does a Map Validity check and we forced, so it can't be full */
		ReplyToCommand(client, "%t", "Map Already In Vote", displayName);
		
		return Plugin_Handled;	
	}
	
	
	g_mapTrie.SetValue(resolvedMap, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);

	
	ReplyToCommand(client, "%t", "Map Inserted", displayName);
	LogAction(client, -1, "\"%L\" inserted map \"%s\".", client, mapname);

	return Plugin_Handled;		
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if (!client)
	{
		return;
	}
	
	if (strcmp(sArgs, "nominate", false) == 0)
	{
		ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
		
		AttemptNominate(client);
		
		SetCmdReplySource(old);
	}
}

public Action Command_Nominate(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}
	
	if (args == 0)
	{
		AttemptNominate(client);
		return Plugin_Handled;
	}
	
	char mapname[PLATFORM_MAX_PATH];
	GetCmdArg(1, mapname, sizeof(mapname));
	
	return Internal_CommandNominate(client, mapname, false);
}

Action Internal_CommandNominate(int client, const char[] mapname, bool isVoteMenu)
{
	char resolvedMap[PLATFORM_MAX_PATH];
	
	if (FindMap(mapname, resolvedMap, sizeof(resolvedMap)) == FindMap_NotFound)
	{
		// We couldn't resolve the map entry to a filename, so...
		ReplyToCommand(client, "%t", "Map was not found", mapname);
		
		if (isVoteMenu && g_NativeVotes)
		{
			NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_MapNotFound);
		}
		return Plugin_Handled;		
	}
	
	char displayName[PLATFORM_MAX_PATH];
	GetMapDisplayName(resolvedMap, displayName, sizeof(displayName));
	
	int status;
	if (!g_mapTrie.GetValue(resolvedMap, status))
	{
		ReplyToCommand(client, "%t", "Map was not found", displayName);
		if (isVoteMenu && g_NativeVotes)
		{
			NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_MapNotValid);
		}
		return Plugin_Handled;		
	}
	
	if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
	{
		if ((status & MAPSTATUS_EXCLUDE_CURRENT) == MAPSTATUS_EXCLUDE_CURRENT)
		{
			if (isVoteMenu && g_NativeVotes)
			{
				NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_MapNotValid);
			}
			ReplyToCommand(client, "[SM] %t", "Can't Nominate Current Map");
		}
		
		if ((status & MAPSTATUS_EXCLUDE_PREVIOUS) == MAPSTATUS_EXCLUDE_PREVIOUS)
		{
			if (isVoteMenu && g_NativeVotes)
			{
				NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_MapNotValid);
			}
			ReplyToCommand(client, "[SM] %t", "Map in Exclude List");
		}
		
		if ((status & MAPSTATUS_EXCLUDE_NOMINATED) == MAPSTATUS_EXCLUDE_NOMINATED)
		{
			if (isVoteMenu && g_NativeVotes)
			{
				NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_MapNotValid);
			}
			ReplyToCommand(client, "[SM] %t", "Map Already Nominated");
		}
		
		return Plugin_Handled;
	}
	
	NominateResult result = NominateMap(resolvedMap, false, client);
	
	if (result > Nominate_Replaced)
	{
		if (result == Nominate_AlreadyInVote)
		{
			if (isVoteMenu && g_NativeVotes)
			{
				NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_MapNotValid);
			}
			ReplyToCommand(client, "%t", "Map Already In Vote", displayName);
		}
		else
		{
			if (isVoteMenu && g_NativeVotes)
			{
				NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_MapNotValid);
			}
			ReplyToCommand(client, "[SM] %t", "Map Already Nominated");
		}
		
		return Plugin_Handled;	
	}
	
	/* Map was nominated! - Disable the menu item and update the trie */
	
	g_mapTrie.SetValue(resolvedMap, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);
	
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	PrintToChatAll("[SM] %t", "Map Nominated", name, displayName);
	
	return Plugin_Handled;
}

void AttemptNominate(int client)
{
	if (g_MapMenu == null)
	{
		BuildMapMenu();
	}
	g_MapMenu.SetTitle("%T", "Nominate Title", client);
	g_MapMenu.Display(client, MENU_TIME_FOREVER);
	
	return;
}

void BuildMapMenu()
{
	g_mapTrie.Clear();
	
	g_MapMenu = new Menu(Handler_MapSelectMenu, MENU_ACTIONS_DEFAULT|MenuAction_DrawItem|MenuAction_DisplayItem);

	char map[PLATFORM_MAX_PATH];
	
	ArrayList excludeMaps;
	char currentMap[PLATFORM_MAX_PATH];
	
	if (g_Cvar_ExcludeOld.BoolValue)
	{	
		excludeMaps = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
		GetExcludeMapList(excludeMaps);
	}
	
	if (g_Cvar_ExcludeCurrent.BoolValue)
	{
		GetCurrentMap(currentMap, sizeof(currentMap));
	}
	
	for (int i = 0; i < g_MapList.Length; i++)
	{
		int status = MAPSTATUS_ENABLED;
		
		g_MapList.GetString(i, map, sizeof(map));
		
		FindMap(map, map, sizeof(map));
		
		char displayName[PLATFORM_MAX_PATH];
		GetMapDisplayName(map, displayName, sizeof(displayName));

		if (g_Cvar_ExcludeCurrent.BoolValue)
		{
			if (StrEqual(map, currentMap))
			{
				status = MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_CURRENT;
			}
		}
		
		/* Dont bother with this check if the current map check passed */
		if (g_Cvar_ExcludeOld.BoolValue && status == MAPSTATUS_ENABLED)
		{
			if (excludeMaps.FindString(map) != -1)
			{
				status = MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_PREVIOUS;
			}
		}
		
		g_MapMenu.AddItem(map, displayName);
		g_mapTrie.SetValue(map, status);
	}

	g_MapMenu.ExitButton = true;

	delete excludeMaps;
}

public int Handler_MapSelectMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char map[PLATFORM_MAX_PATH], name[MAX_NAME_LENGTH], displayName[PLATFORM_MAX_PATH];
			menu.GetItem(param2, map, sizeof(map), _, displayName, sizeof(displayName));
			
			GetClientName(param1, name, sizeof(name));
	
			NominateResult result = NominateMap(map, false, param1);
			
			/* Don't need to check for InvalidMap because the menu did that already */
			if (result == Nominate_AlreadyInVote)
			{
				PrintToChat(param1, "[SM] %t", "Map Already Nominated");
				return 0;
			}
			else if (result == Nominate_VoteFull)
			{
				PrintToChat(param1, "[SM] %t", "Max Nominations");
				return 0;
			}
			
			g_mapTrie.SetValue(map, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);

			if (result == Nominate_Replaced)
			{
				PrintToChatAll("[SM] %t", "Map Nomination Changed", name, displayName);
				return 0;	
			}
			
			PrintToChatAll("[SM] %t", "Map Nominated", name, displayName);
		}
		
		case MenuAction_DrawItem:
		{
			char map[PLATFORM_MAX_PATH];
			menu.GetItem(param2, map, sizeof(map));
			
			int status;
			
			if (!g_mapTrie.GetValue(map, status))
			{
				LogError("Menu selection of item not in trie. Major logic problem somewhere.");
				return ITEMDRAW_DEFAULT;
			}
			
			if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
			{
				return ITEMDRAW_DISABLED;	
			}
			
			return ITEMDRAW_DEFAULT;
						
		}
		
		case MenuAction_DisplayItem:
		{
			char map[PLATFORM_MAX_PATH], displayName[PLATFORM_MAX_PATH];
			menu.GetItem(param2, map, sizeof(map), _, displayName, sizeof(displayName));
			
			int status;
			
			if (!g_mapTrie.GetValue(map, status))
			{
				LogError("Menu selection of item not in trie. Major logic problem somewhere.");
				return 0;
			}
			
			char display[PLATFORM_MAX_PATH + 64];
			
			if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
			{
				if ((status & MAPSTATUS_EXCLUDE_CURRENT) == MAPSTATUS_EXCLUDE_CURRENT)
				{
					Format(display, sizeof(display), "%s (%T)", displayName, "Current Map", param1);
					return RedrawMenuItem(display);
				}
				
				if ((status & MAPSTATUS_EXCLUDE_PREVIOUS) == MAPSTATUS_EXCLUDE_PREVIOUS)
				{
					Format(display, sizeof(display), "%s (%T)", displayName, "Recently Played", param1);
					return RedrawMenuItem(display);
				}
				
				if ((status & MAPSTATUS_EXCLUDE_NOMINATED) == MAPSTATUS_EXCLUDE_NOMINATED)
				{
					Format(display, sizeof(display), "%s (%T)", displayName, "Nominated", param1);
					return RedrawMenuItem(display);
				}
			}
			
			return 0;
		}
	}
	
	return 0;
}

void RegisterVoteHandler()
{
	if (!g_NativeVotes)
		return;
		
	if (!g_RegisteredMenusNextLevel)
	{
		NativeVotes_RegisterVoteCommand(NativeVotesOverride_NextLevel, Menu_Nominate);
		g_RegisteredMenusNextLevel = true;
	}
	
	if (!g_RegisteredMenusChangeLevel)
	{
		NativeVotes_RegisterVoteCommand(NativeVotesOverride_ChgLevel, Menu_Nominate);
		g_RegisteredMenusChangeLevel = true;
	}
}

void RemoveVoteHandler()
{
	if (g_RegisteredMenusNextLevel)
	{
		if (g_NativeVotes)
			NativeVotes_UnregisterVoteCommand(NativeVotesOverride_NextLevel, Menu_Nominate);
			
		g_RegisteredMenusNextLevel = false;
	}
	
	if (g_RegisteredMenusChangeLevel)
	{
		if (g_NativeVotes)
			NativeVotes_UnregisterVoteCommand(NativeVotesOverride_ChgLevel, Menu_Nominate);
			
		g_RegisteredMenusChangeLevel = false;
	}
		
}

public Action Menu_Nominate(int client, NativeVotesOverride overrideType, const char[] voteArgument)
{
	if (!client || NativeVotes_IsVoteInProgress())
	{
		return Plugin_Handled;
	}
	
	if (strlen(voteArgument) == 0)
	{
		NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_SpecifyMap);
		return Plugin_Handled;
	}
	
	ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	Action myReturn = Internal_CommandNominate(client, voteArgument, true);
	
	SetCmdReplySource(old);
	
	return myReturn;
}

public Action NativeVotes_OverrideMaps(StringMap mapList)
{
	if (g_MapMenu == null)
	{
		BuildMapMenu();
	}
	
	if (g_mapTrie.Size == 0)
	{
		LogMessage("No maps loaded.");
		return Plugin_Continue;
	}
	
	// We don't care about the current list, replace it with our own
	mapList.Clear();
	
	StringMapSnapshot snapshot = g_mapTrie.Snapshot();
	int length = snapshot.Length;
	
	for (int i = 0; i < length; i++)
	{
		int size = snapshot.KeyBufferSize(i);
		char[] map = new char[size];
		snapshot.GetKey(i, map, size);
		
		int flags;
		
		if (!g_mapTrie.GetValue(map, flags) || flags & MAPSTATUS_DISABLED == MAPSTATUS_DISABLED)
		{
			continue;
		}
		
		char displayName[PLATFORM_MAX_PATH];
		GetMapDisplayName(map, displayName, sizeof(displayName));
		
		// Display name first
		mapList.SetString(displayName, map);
	}
	
	delete snapshot;
	
	if (mapList.Size > 0)
	{
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
