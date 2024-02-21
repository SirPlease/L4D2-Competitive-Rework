/**
 * vim: set ts=4 :
 * =============================================================================
 * NativeVotes
 * NativeVotes is a voting API plugin for L4D, L4D2, TF2, and CS:GO.
 * Based on the SourceMod voting API
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

#if defined _nativevotes_data_included
 #endinput
#endif

#define _nativevotes_data_included

#include <sourcemod>

#define INFO_LENGTH 128
#define INFO "item_info"
#define DISPLAY "item_display"

bool Data_GetItemInfo(KeyValues vote, int item, char[] choice, int choiceSize)
{
	if (item >= Data_GetItemCount(vote))
	{
		return false;
	}
	
	ArrayList array = view_as<ArrayList>(vote.GetNum(INFO, view_as<int>(INVALID_HANDLE)));

	// Shouldn't happen, but just in case...
	if (array == null)
	{
		return false;
	}
	
	array.GetString(item, choice, choiceSize);
	return true;
}

bool Data_GetItemDisplay(KeyValues vote, int item, char[] choice, int choiceSize)
{
	if (item >= Data_GetItemCount(vote))
	{
		return false;
	}
	
	ArrayList array = view_as<ArrayList>(vote.GetNum(DISPLAY, view_as<int>(INVALID_HANDLE)));

	// Shouldn't happen, but just in case...
	if (array == null)
	{
		return false;
	}
	
	array.GetString(item, choice, choiceSize);
	return true;
}

int Data_GetItemCount(KeyValues vote)
{
	ArrayList array = view_as<ArrayList>(vote.GetNum(INFO, view_as<int>(INVALID_HANDLE)));
	if (array == null)
	{
		return 0;
	}
	
	return array.Length;
}

int Data_GetTeam(KeyValues vote)
{
	return vote.GetNum("team", NATIVEVOTES_ALL_TEAMS);
}

void Data_SetTeam(KeyValues vote, int team)
{
	vote.SetNum("team", team);
}

int Data_GetInitiator(KeyValues vote)
{
	return vote.GetNum("initiator", NATIVEVOTES_SERVER_INDEX);
}

void Data_SetInitiator(KeyValues vote, int initiator)
{
	vote.SetNum("initiator", initiator);
}

void Data_GetDetails(KeyValues vote, char[] details, int maxlength)
{
	vote.GetString("details", details, maxlength);
}

void Data_SetDetails(KeyValues vote, const char[] details)
{
	vote.SetString("details", details);
}

void Data_GetTitle(KeyValues vote, char[] title, int maxlength)
{
	// Shim for older code that sets custom vote titles in details
	vote.GetString("custom_title", title, maxlength);
	if (strlen(title) == 0)
	{
		vote.GetString("details", title, maxlength);
	}
}

void Data_SetTitle(KeyValues vote, const char[] title)
{
	vote.SetString("custom_title", title);
}

int Data_GetTarget(KeyValues vote)
{
	return vote.GetNum("target");
}

void Data_SetTarget(KeyValues vote, int target)
{
	vote.SetNum("target", target);
}

void Data_GetTargetSteam(KeyValues vote, char[] steamId, int maxlength)
{
	vote.GetString("target_steam", steamId, maxlength);
}

void Data_SetTargetSteam(KeyValues vote, const char[] steamId)
{
	vote.SetString("target_steam", steamId);	
}

NativeVotesType Data_GetType(KeyValues vote)
{
	return view_as<NativeVotesType>(vote.GetNum("vote_type", view_as<int>(NativeVotesType_Custom_YesNo)));
}

Handle Data_GetHandler(KeyValues vote)
{
	if (vote == null)
		return null;
	
	return view_as<Handle>(vote.GetNum("handler_callback"));
}

Handle Data_GetResultCallback(KeyValues vote)
{
	if (vote == null)
		return null;
	
	return view_as<Handle>(vote.GetNum("result_callback"));
}

int Data_GetFlags(KeyValues vote)
{
	return vote.GetNum("flags");
}

void Data_SetFlags(KeyValues vote, int flags)
{
	if (flags & MENUFLAG_BUTTON_NOVOTE)
	{
		NativeVotesType voteType = Data_GetType(vote);
		
		// Strip novote if this is a YesNo vote
		if (Game_IsVoteTypeYesNo(voteType))
		{
			flags &= ~MENUFLAG_BUTTON_NOVOTE;
		}
	}
	
	vote.SetNum("flags", flags);
}

NativeVote Data_CreateVote(NativeVotesType voteType, MenuAction actions)
{
	Handle handler = CreateForward(ET_Single, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	Handle voteResults = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Cell, Param_Array, Param_Array);
	
	KeyValues vote = CreateKeyValues("NativeVote");

	vote.SetNum("handler_callback", view_as<int>(handler));
	vote.SetNum("vote_type", view_as<int>(voteType));
	vote.SetString("details", "");
	vote.SetNum("target", -1);
	vote.SetString("target_steam", "");
	vote.SetNum("actions", view_as<int>(actions));
	vote.SetNum("result_callback", view_as<int>(voteResults));
	vote.SetNum("initiator", NATIVEVOTES_SERVER_INDEX);
	if (g_EngineVersion == Engine_TF2)
	{
		vote.SetNum("team", NATIVEVOTES_TF2_ALL_TEAMS);
	}
	else
	{
		vote.SetNum("team", NATIVEVOTES_ALL_TEAMS);
	}
	vote.SetNum("flags", 0);
	vote.SetString("custom_title", "");
	
	vote.SetNum(INFO, view_as<int>(new ArrayList(ByteCountToCells(INFO_LENGTH))));
	vote.SetNum(DISPLAY, view_as<int>(new ArrayList(ByteCountToCells(INFO_LENGTH))));
	
	return view_as<NativeVote>(vote);
}

MenuAction Data_GetActions(KeyValues vote)
{
	return view_as<MenuAction>(vote.GetNum("actions"));
}

bool Data_AddItem(KeyValues vote, const char[] info, const char[] display)
{
	ArrayList infoArray = view_as<ArrayList>(vote.GetNum(INFO, view_as<int>(INVALID_HANDLE)));
	ArrayList displayArray = view_as<ArrayList>(vote.GetNum(DISPLAY, view_as<int>(INVALID_HANDLE)));
	
	if (infoArray == null || displayArray == null ||
		infoArray.Length >= Game_GetMaxItems() ||
		displayArray.Length >= Game_GetMaxItems())
	{
		return false;
	}
	
	infoArray.PushString(info);
	displayArray.PushString(display);
	
	return true;
}

bool Data_InsertItem(KeyValues vote, int position, const char[] info, const char[] display)
{
	ArrayList infoArray = view_as<ArrayList>(vote.GetNum(INFO, view_as<int>(INVALID_HANDLE)));
	ArrayList displayArray = view_as<ArrayList>(vote.GetNum(DISPLAY, view_as<int>(INVALID_HANDLE)));
	
	if (infoArray == null || displayArray == null ||
		infoArray.Length >= Game_GetMaxItems() ||
		displayArray.Length >= Game_GetMaxItems() ||
		position >= infoArray.Length)
	{
		return false;
	}
	
	infoArray.ShiftUp(position);
	displayArray.ShiftUp(position);

	infoArray.SetString(position, info);
	displayArray.SetString(position, display);
	
	return true;
}

bool Data_RemoveItem(KeyValues vote, int position)
{
	ArrayList infoArray = view_as<ArrayList>(vote.GetNum(INFO, view_as<int>(INVALID_HANDLE)));
	ArrayList displayArray = view_as<ArrayList>(vote.GetNum(DISPLAY, view_as<int>(INVALID_HANDLE)));
	
	if (infoArray == null || displayArray == null ||
		position >= infoArray.Length || position < 0)
	{
		return false;
	}
	
	infoArray.Erase(position);
	displayArray.Erase(position);

	return true;
}

void Data_RemoveAllItems(KeyValues vote)
{
	ArrayList infoArray = view_as<ArrayList>(vote.GetNum(INFO, view_as<int>(INVALID_HANDLE)));
	ArrayList displayArray = view_as<ArrayList>(vote.GetNum(DISPLAY, view_as<int>(INVALID_HANDLE)));
	
	infoArray.Clear();
	displayArray.Clear();
}

void Data_CloseVote(KeyValues vote)
{
	if (vote == null)
	{
		return;
	}
	
	Handle handler = Data_GetHandler(vote);
	if (handler != null)
	{
		delete handler;
	}
	
	Handle voteResults = Data_GetResultCallback(vote);
	if (voteResults != null)
	{
		delete voteResults;
	}
	
	ArrayList infoArray = view_as<ArrayList>(vote.GetNum(INFO, view_as<int>(INVALID_HANDLE)));
	if (infoArray != null)
	{
		delete infoArray;
	}
	
	ArrayList displayArray = view_as<ArrayList>(vote.GetNum(DISPLAY, view_as<int>(INVALID_HANDLE)));
	if (displayArray != null)
	{
		delete displayArray;
	}
	
	delete vote;
}
