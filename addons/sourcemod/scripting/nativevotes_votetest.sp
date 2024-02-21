/**
 * vim: set ts=4 :
 * =============================================================================
 * NativeVotes Vote Tester
 * Copyright (C) 2011-2013 Ross Bemrose (Powerlord).  All rights reserved.
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

#pragma newdecls required
#include "include/nativevotes"

#define VERSION "1.1"

public Plugin myinfo = 
{
	name = "NativeVotes Vote Tester",
	author = "Powerlord",
	description = "Various NativeVotes vote type tests",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=208008"
}

public void OnPluginStart()
{
	CreateConVar("nativevotestest_version", VERSION, "NativeVotes Vote Tester version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	RegAdminCmd("voteyesno", Cmd_TestYesNo, ADMFLAG_VOTE, "Test Yes/No votes");
	RegAdminCmd("votemult", Cmd_TestMult, ADMFLAG_VOTE, "Test Multiple Choice votes");
	RegAdminCmd("voteyesnocustom", Cmd_TestYesNoCustom, ADMFLAG_VOTE, "Test Multiple Choice vote with Custom Display text");
	RegAdminCmd("votemultcustom", Cmd_TestMultCustom, ADMFLAG_VOTE, "Test Multiple Choice vote with Custom Display text");
	RegAdminCmd("votenovote", Cmd_TestNoVote, ADMFLAG_VOTE, "Test Multiple Choice vote with \"No Vote\" option");
	RegAdminCmd("votenovotecustom", Cmd_TestNoVoteCustom, ADMFLAG_VOTE, "Test Multiple Choice vote with \"No Vote\" option and Custom Display text");
}

public Action Cmd_TestYesNo(int client, int args)
{
	if (!NativeVotes_IsVoteTypeSupported(NativeVotesType_Custom_YesNo))
	{
		ReplyToCommand(client, "Game does not support Custom Yes/No votes.");
		return Plugin_Handled;
	}
	
	if (!NativeVotes_IsNewVoteAllowed())
	{
		int seconds = NativeVotes_CheckVoteDelay();
		ReplyToCommand(client, "Vote is not allowed for %d more seconds", seconds);
		return Plugin_Handled;
	}
	
	NativeVote vote = new NativeVote(YesNoHandler, NativeVotesType_Custom_YesNo);
	
	vote.Initiator = client;
	vote.SetDetails("Test Yes/No Vote");
	vote.DisplayVoteToAll(30);
	
	return Plugin_Handled;
}

public int YesNoHandler(NativeVote vote, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			vote.Close();
		}
		
		case MenuAction_VoteCancel:
		{
			if (param1 == VoteCancel_NoVotes)
			{
				vote.DisplayFail(NativeVotesFail_NotEnoughVotes);
			}
			else
			{
				vote.DisplayFail(NativeVotesFail_Generic);
			}
		}
		
		case MenuAction_VoteEnd:
		{
			if (param1 == NATIVEVOTES_VOTE_NO)
			{
				vote.DisplayFail(NativeVotesFail_Loses);
			}
			else
			{
				vote.DisplayPass("Test Yes/No Vote Passed!");
				// Do something because it passed
			}
		}
	}
	return 0;
}

public Action Cmd_TestMult(int client, int args)
{
	if (!NativeVotes_IsVoteTypeSupported(NativeVotesType_Custom_Mult))
	{
		ReplyToCommand(client, "Game does not support Custom Multiple Choice votes.");
		return Plugin_Handled;
	}

	if (!NativeVotes_IsNewVoteAllowed())
	{
		int seconds = NativeVotes_CheckVoteDelay();
		ReplyToCommand(client, "Vote is not allowed for %d more seconds", seconds);
		return Plugin_Handled;
	}
	
	NativeVote vote = new NativeVote(MultHandler, NativeVotesType_Custom_Mult);
	
	vote.Initiator = client;
	vote.SetDetails("Test Mult Vote");
	vote.AddItem("choice1", "Choice 1");
	vote.AddItem("choice2", "Choice 2");
	vote.AddItem("choice3", "Choice 3");
	vote.AddItem("choice4", "Choice 4");
	vote.AddItem("choice5", "Choice 5");
	// 5 is currently the maximum number of choices in any game
	vote.DisplayVoteToAll(30);
	
	return Plugin_Handled;
}

public int MultHandler(NativeVote vote, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			vote.Close();
		}
		
		case MenuAction_VoteCancel:
		{
			if (param1 == VoteCancel_NoVotes)
			{
				vote.DisplayFail(NativeVotesFail_NotEnoughVotes);
			}
			else
			{
				vote.DisplayFail(NativeVotesFail_Generic);
			}
		}
		
		case MenuAction_VoteEnd:
		{
			char info[64];
			char display[64];
			vote.GetItem(param1, info, sizeof(info), display, sizeof(display));
			
			vote.DisplayPass(display);
			
			// Do something with info
		}
	}
	return 0;
}

public Action Cmd_TestYesNoCustom(int client, int args)
{
	if (!NativeVotes_IsVoteTypeSupported(NativeVotesType_Custom_YesNo))
	{
		ReplyToCommand(client, "Game does not support Custom Yes/No votes.");
		return Plugin_Handled;
	}

	if (!NativeVotes_IsNewVoteAllowed())
	{
		int seconds = NativeVotes_CheckVoteDelay();
		ReplyToCommand(client, "Vote is not allowed for %d more seconds", seconds);
		return Plugin_Handled;
	}
	
	NativeVote vote = new NativeVote(YesNoCustomHandler, NativeVotesType_Custom_YesNo, NATIVEVOTES_ACTIONS_DEFAULT|MenuAction_Display);
	
	vote.Initiator = client;
	vote.SetDetails("Test Yes/No Vote");
	vote.DisplayVoteToAll(30);
	
	return Plugin_Handled;
}

public int YesNoCustomHandler(NativeVote vote, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			vote.Close();
		}
		
		case MenuAction_Display:
		{
			char display[64];
			Format(display, sizeof(display), "%N Test Yes/No Vote", param1);
			PrintToChat(param1, "New Menu Title: %s", display);
			NativeVotes_RedrawVoteTitle(display);
			return view_as<int>(Plugin_Changed);
		}
		
		case MenuAction_VoteCancel:
		{
			if (param1 == VoteCancel_NoVotes)
			{
				vote.DisplayFail(NativeVotesFail_NotEnoughVotes);
			}
			else
			{
				vote.DisplayFail(NativeVotesFail_Generic);
			}
		}
		
		case MenuAction_VoteEnd:
		{
			if (param1 == NATIVEVOTES_VOTE_NO)
			{
				vote.DisplayFail(NativeVotesFail_Loses);
			}
			else
			{
				vote.DisplayPass("Test Custom Yes/No Vote Passed!");
				// Do something because it passed
			}
		}
	}
	
	return 0;
}

public Action Cmd_TestMultCustom(int client, int args)
{
	if (!NativeVotes_IsVoteTypeSupported(NativeVotesType_Custom_Mult))
	{
		ReplyToCommand(client, "Game does not support Custom Multiple Choice votes.");
		return Plugin_Handled;
	}

	if (!NativeVotes_IsNewVoteAllowed())
	{
		int seconds = NativeVotes_CheckVoteDelay();
		ReplyToCommand(client, "Vote is not allowed for %d more seconds", seconds);
		return Plugin_Handled;
	}
	
	NativeVote vote = new NativeVote(MultCustomHandler, NativeVotesType_Custom_Mult, NATIVEVOTES_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem);
	
	vote.Initiator = client;
	vote.SetDetails("Test Mult Vote");
	vote.AddItem("choice1", "Choice 1");
	vote.AddItem("choice2", "Choice 2");
	vote.AddItem("choice3", "Choice 3");
	vote.AddItem("choice4", "Choice 4");
	vote.AddItem("choice5", "Choice 5");
	// 5 is currently the maximum number of choices in any game
	vote.DisplayVoteToAll(30);
	
	return Plugin_Handled;
}

public int MultCustomHandler(NativeVote vote, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			vote.Close();
		}
		
		case MenuAction_Display:
		{
			char display[64];
			Format(display, sizeof(display), "%N Test Mult Vote", param1);
			PrintToChat(param1, "New Menu Title: %s", display);
			NativeVotes_RedrawVoteTitle(display);
			return view_as<int>(Plugin_Changed);
		}
		
		case MenuAction_VoteCancel:
		{
			if (param1 == VoteCancel_NoVotes)
			{
				vote.DisplayFail(NativeVotesFail_NotEnoughVotes);
			}
			else
			{
				vote.DisplayFail(NativeVotesFail_Generic);
			}
		}
		
		case MenuAction_VoteEnd:
		{
			char info[64];
			char display[64];
			vote.GetItem(param1, info, sizeof(info), display, sizeof(display));
			
			// Do something with info
			//NativeVotes_DisplayPassCustom(vote, "%t Mult passed", "Translation Phrase");
			vote.DisplayPassCustom("%s passed", display);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[64];
			char display[64];
			
			char buffer[64];
			
			vote.GetItem(param2, info, sizeof(info), display, sizeof(display));
			
			// This is generally how you'd do translations, but normally with %T and a format phrase
			bool bReplace = false;
			if (StrEqual(info, "choice1"))
			{
				Format(buffer, sizeof(buffer), "%N %s", param1, display);
				bReplace = true;
			}
			else if (StrEqual(info, "choice2"))
			{
				Format(buffer, sizeof(buffer), "%N %s", param1, display);
				bReplace = true;
			}
			else if (StrEqual(info, "choice3"))
			{
				Format(buffer, sizeof(buffer), "%N %s", param1, display);
				bReplace = true;
			}
			else if (StrEqual(info, "choice4"))
			{
				Format(buffer, sizeof(buffer), "%N %s", param1, display);
				bReplace = true;
			}
			else if (StrEqual(info, "choice5"))
			{
				Format(buffer, sizeof(buffer), "%N %s", param1, display);
				bReplace = true;
			}
			
			PrintToChat(param1, "New Menu Item %d: %s", param2, buffer);
			
			if (bReplace)
			{
				NativeVotes_RedrawVoteItem(buffer);
				return view_as<int>(Plugin_Changed);
			}
		}
	}
	
	return 0;
}

public Action Cmd_TestNoVote(int client, int args)
{
	if (!NativeVotes_IsVoteTypeSupported(NativeVotesType_Custom_Mult))
	{
		ReplyToCommand(client, "Game does not support Custom Multiple Choice votes.");
		return Plugin_Handled;
	}

	if (!NativeVotes_IsNewVoteAllowed())
	{
		int seconds = NativeVotes_CheckVoteDelay();
		ReplyToCommand(client, "Vote is not allowed for %d more seconds", seconds);
		return Plugin_Handled;
	}
	
	NativeVote vote = new NativeVote(MultHandler, NativeVotesType_Custom_Mult);
	
	vote.NoVoteButton = true;
	vote.Initiator = client;
	vote.SetDetails("Test Mult Vote with NoVote");
	vote.AddItem("choice1", "Choice 1");
	vote.AddItem("choice2", "Choice 2");
	vote.AddItem("choice3", "Choice 3");
	vote.AddItem("choice4", "Choice 4");
	vote.AddItem("choice5", "Choice 5");
	// 5 is currently the maximum number of choices in any game, but No Vote should make the max 4...
	vote.DisplayVoteToAll(30);
	
	return Plugin_Handled;
}

public Action Cmd_TestNoVoteCustom(int client, int args)
{
	if (!NativeVotes_IsVoteTypeSupported(NativeVotesType_Custom_Mult))
	{
		ReplyToCommand(client, "Game does not support Custom Multiple Choice votes.");
		return Plugin_Handled;
	}

	if (!NativeVotes_IsNewVoteAllowed())
	{
		int seconds = NativeVotes_CheckVoteDelay();
		ReplyToCommand(client, "Vote is not allowed for %d more seconds", seconds);
		return Plugin_Handled;
	}
	
	NativeVote vote = new NativeVote(MultCustomHandler, NativeVotesType_Custom_Mult, NATIVEVOTES_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem);

	vote.NoVoteButton = true;
	vote.Initiator = client;
	vote.SetDetails("Test Mult Vote");
	vote.AddItem("choice1", "Choice 1");
	vote.AddItem("choice2", "Choice 2");
	vote.AddItem("choice3", "Choice 3");
	vote.AddItem("choice4", "Choice 4");
	vote.AddItem("choice5", "Choice 5");
	// 5 is currently the maximum number of choices in any game, but No Vote should make the max 4...
	vote.DisplayVoteToAll(30);
	
	return Plugin_Handled;
}

