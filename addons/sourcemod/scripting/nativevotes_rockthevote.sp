/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod NativeVotes Rock The Vote Plugin
 * Creates a map vote when the required number of players have requested one.
 * Updated with NativeVotes support
 *
 * NativeVotes (C)2011-2016 Ross Bemrose (Powerlord). All rights reserved.
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
#include <mapchooser>
#include <nextmap>

#undef REQUIRE_PLUGIN
#include <nativevotes>
#define REQUIRE_PLUGIN

// Despite being labeled as TF2-only, this plugin does work on other games.
// It's just identical to rockthevote.smx there
#undef REQUIRE_EXTENSIONS
#include <tf2>
#define REQUIRE_EXTENSIONS

#pragma semicolon 1
#pragma newdecls required

#define VERSION "1.8.0 beta 1"

public Plugin myinfo =
{
	name = "NativeVotes Rock The Vote",
	author = "AlliedModders LLC and Powerlord",
	description = "Provides RTV Map Voting",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=208010"
};

ConVar g_Cvar_Needed;
ConVar g_Cvar_MinPlayers;
ConVar g_Cvar_InitialDelay;
ConVar g_Cvar_Interval;
ConVar g_Cvar_ChangeTime;
ConVar g_Cvar_RTVPostVoteAction;

bool g_CanRTV = false;		// True if RTV loaded maps and is active.
bool g_RTVAllowed = false;	// True if RTV is available to players. Used to delay rtv votes.
int g_Voters = 0;				// Total voters connected. Doesn't include fake clients.
int g_Votes = 0;				// Total number of "say rtv" votes
int g_VotesNeeded = 0;			// Necessary votes before map vote begins. (voters * percent_needed)
bool g_Voted[MAXPLAYERS+1] = {false, ...};

bool g_InChange = false;

// NativeVotes
bool g_NativeVotes;
bool g_RegisteredMenusChangeLevel = false;
int g_RTVTime = 0;
bool g_Warmup = false;

#define LIBRARY "nativevotes"


public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("rockthevote.phrases");
	
	g_Cvar_Needed = CreateConVar("sm_rtv_needed", "0.60", "Percentage of players needed to rockthevote (Def 60%)", 0, true, 0.05, true, 1.0);
	g_Cvar_MinPlayers = CreateConVar("sm_rtv_minplayers", "0", "Number of players required before RTV will be enabled.", 0, true, 0.0, true, float(MAXPLAYERS));
	g_Cvar_InitialDelay = CreateConVar("sm_rtv_initialdelay", "30.0", "Time (in seconds) before first RTV can be held", 0, true, 0.00);
	g_Cvar_Interval = CreateConVar("sm_rtv_interval", "240.0", "Time (in seconds) after a failed RTV before another can be held", 0, true, 0.00);
	g_Cvar_ChangeTime = CreateConVar("sm_rtv_changetime", "0", "When to change the map after a succesful RTV: 0 - Instant, 1 - RoundEnd, 2 - MapEnd", _, true, 0.0, true, 2.0);
	g_Cvar_RTVPostVoteAction = CreateConVar("sm_rtv_postvoteaction", "0", "What to do with RTV's after a mapvote has completed. 0 - Allow, success = instant change, 1 - Deny", _, true, 0.0, true, 1.0);
	
	RegConsoleCmd("sm_rtv", Command_RTV);
	
	AutoExecConfig(true, "rtv");
}

public void OnPluginEnd()
{
	RemoveVoteHandler();
}

public void OnAllPluginsLoaded()
{
	if (FindPluginByFile("rockthevote.smx") != null)
	{
		LogMessage("Unloading rockthevote to prevent conflicts...");
		ServerCommand("sm plugins unload rockthevote");
		
		char oldPath[PLATFORM_MAX_PATH];
		char newPath[PLATFORM_MAX_PATH];
		
		BuildPath(Path_SM, oldPath, sizeof(oldPath), "plugins/rockthevote.smx");
		BuildPath(Path_SM, newPath, sizeof(newPath), "plugins/disabled/rockthevote.smx");
		if (RenameFile(newPath, oldPath))
		{
			LogMessage("Moving rockthevote to disabled.");
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

public void TF2_OnWaitingForPlayersStart()
{
	g_Warmup = true;
}

public void TF2_OnWaitingForPlayersEnd()
{
	g_Warmup = false;
}

public void OnMapStart()
{
	g_Voters = 0;
	g_Votes = 0;
	g_VotesNeeded = 0;
	g_InChange = false;
	
	/* Handle late load */
	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			OnClientConnected(i);	
		}	
	}
}

public void OnMapEnd()
{
	g_Warmup = false;
	g_CanRTV = false;	
	g_RTVAllowed = false;
}

public void OnConfigsExecuted()
{	
	g_CanRTV = true;
	g_RTVAllowed = false;
	g_RTVTime = GetTime() + g_Cvar_Interval.IntValue;
	CreateTimer(g_Cvar_InitialDelay.FloatValue, Timer_DelayRTV, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientConnected(int client)
{
	if(IsFakeClient(client))
		return;
	
	g_Voted[client] = false;

	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_Cvar_Needed.FloatValue);
	
	return;
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client))
		return;
	
	if(g_Voted[client])
	{
		g_Votes--;
	}
	
	g_Voters--;
	
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_Cvar_Needed.FloatValue);
	
	if (!g_CanRTV)
	{
		return;	
	}
	
	if (g_Votes && 
		g_Voters && 
		g_Votes >= g_VotesNeeded && 
		g_RTVAllowed ) 
	{
		if (g_Cvar_RTVPostVoteAction.IntValue == 1 && HasEndOfMapVoteFinished())
		{
			return;
		}
		
		StartRTV();
	}	
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if (!g_CanRTV || !client)
	{
		return;
	}
	
	if (strcmp(sArgs, "rtv", false) == 0 || strcmp(sArgs, "rockthevote", false) == 0)
	{
		ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
		
		AttemptRTV(client);
		
		SetCmdReplySource(old);
	}
}

public Action Command_RTV(int client, int args)
{
	if (!g_CanRTV || !client)
	{
		return Plugin_Handled;
	}
	
	AttemptRTV(client);
	
	return Plugin_Handled;
}

void AttemptRTV(int client, bool isVoteMenu=false)
{
	if (!g_RTVAllowed  || (g_Cvar_RTVPostVoteAction.IntValue == 1 && HasEndOfMapVoteFinished()))
	{
		ReplyToCommand(client, "[SM] %t", "RTV Not Allowed");
		if (isVoteMenu && g_NativeVotes)
		{
			if (g_Warmup)
			{
				NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_Waiting);
			}
			else
			{
				int timeleft = g_RTVTime - GetTime();
				if (timeleft > 0)
				{
					NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_Failed, timeleft);
				}
				else
				{
					NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_Generic);
				}
			}
		}
		return;
	}
		
	if (!CanMapChooserStartVote())
	{
		ReplyToCommand(client, "[SM] %t", "RTV Started");
		return;
	}
	
	if (GetClientCount(true) < g_Cvar_MinPlayers.IntValue)
	{
		ReplyToCommand(client, "[SM] %t", "Minimal Players Not Met");
		if (isVoteMenu && g_NativeVotes)
		{
			NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_Loading);
		}
		return;			
	}
	
	if (g_Voted[client])
	{
		ReplyToCommand(client, "[SM] %t", "Already Voted", g_Votes, g_VotesNeeded);
		if (isVoteMenu && g_NativeVotes)
		{
			NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_AlreadyActive);
		}
		return;
	}	
	
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	g_Votes++;
	g_Voted[client] = true;
	
	PrintToChatAll("[SM] %t", "RTV Requested", name, g_Votes, g_VotesNeeded);
	
	if (g_Votes >= g_VotesNeeded)
	{
		StartRTV();
	}	
}

public Action Timer_DelayRTV(Handle timer)
{
	g_RTVAllowed = true;
	return Plugin_Continue;
}

void StartRTV()
{
	if (g_InChange)
	{
		return;	
	}
	
	if (EndOfMapVoteEnabled() && HasEndOfMapVoteFinished())
	{
		/* Change right now then */
		char map[PLATFORM_MAX_PATH];
		if (GetNextMap(map, sizeof(map)))
		{
			GetMapDisplayName(map, map, sizeof(map));
			
			PrintToChatAll("[SM] %t", "Changing Maps", map);
			CreateTimer(5.0, Timer_ChangeMap, _, TIMER_FLAG_NO_MAPCHANGE);
			g_InChange = true;
			
			ResetRTV();
			
			g_RTVAllowed = false;
		}
		return;	
	}
	
	if (CanMapChooserStartVote())
	{
		MapChange when = view_as<MapChange>(g_Cvar_ChangeTime.IntValue);
		InitiateMapChooserVote(when);
		
		ResetRTV();
		
		g_RTVAllowed = false;
		g_RTVTime = GetTime() + g_Cvar_Interval.IntValue;

		CreateTimer(g_Cvar_Interval.FloatValue, Timer_DelayRTV, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

void ResetRTV()
{
	g_Votes = 0;
			
	for (int i=1; i<=MAXPLAYERS; i++)
	{
		g_Voted[i] = false;
	}
}

public Action Timer_ChangeMap(Handle hTimer)
{
	g_InChange = false;
	
	LogMessage("RTV changing map manually");
	
	char map[PLATFORM_MAX_PATH];
	if (GetNextMap(map, sizeof(map)))
	{	
		ForceChangeLevel(map, "RTV after mapvote");
	}
	
	return Plugin_Stop;
}

void RegisterVoteHandler()
{
	if (!g_NativeVotes)
		return;
		
	if (!g_RegisteredMenusChangeLevel)
	{
		NativeVotes_RegisterVoteCommand(NativeVotesOverride_ChgLevel, Menu_RTV);
		g_RegisteredMenusChangeLevel = true;
	}
}

void RemoveVoteHandler()
{
	if (g_RegisteredMenusChangeLevel)
	{
		if (g_NativeVotes)
			NativeVotes_UnregisterVoteCommand(NativeVotesOverride_ChgLevel, Menu_RTV);
			
		g_RegisteredMenusChangeLevel = false;
	}
		
}

public Action Menu_RTV(int client, NativeVotesOverride overrideType, const char[] voteArgument)
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
	
	AttemptRTV(client, true);
	
	SetCmdReplySource(old);
	
	return Plugin_Handled;
}
