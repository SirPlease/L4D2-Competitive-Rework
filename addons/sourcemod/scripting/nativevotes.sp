/**
 * vim: set ts=4 :
 * =============================================================================
 * NativeVotes
 * NativeVotes is a voting API plugin for L4D, L4D2, TF2, and CS:GO.
 * Based on the SourceMod voting API
 * 
 * NativeVotes (C) 2011-2015 Ross Bemrose (Powerlord). All rights reserved.
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
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#include "include/nativevotes.inc"
#include "include/implodeexplode.inc"

EngineVersion g_EngineVersion = Engine_Unknown;

#include "nativevotes/data-keyvalues.sp"

#define VERSION 							"1.1.1fix"

#define LOGTAG "NV"

#define MAX_VOTE_DETAILS_LENGTH				64	// From SourceSDK2013's shareddefs.h
#define TRANSLATION_LENGTH					192

#define VOTE_DELAY_TIME 					3.0

// SourceMod uses these internally, so... we do too.
#define VOTE_NOT_VOTING 					-2
#define VOTE_PENDING 						-1

#define MAX_VOTE_ISSUES						20
#define VOTE_STRING_SIZE					32

//----------------------------------------------------------------------------
// These values are swapped from their NativeVotes equivalent
#define L4D2_VOTE_YES_INDEX					1
#define L4D2_VOTE_NO_INDEX					0

#define L4DL4D2_COUNT						2
#define TF2CSGO_COUNT						5

#define MAX_CALLVOTE_SIZE					128

//#define LOG

//----------------------------------------------------------------------------
// Global Variables
int g_NextVote = 0;

//----------------------------------------------------------------------------
// CVars
ConVar g_Cvar_VoteHintbox;
ConVar g_Cvar_VoteChat;
ConVar g_Cvar_VoteConsole;
ConVar g_Cvar_VoteClientConsole;
ConVar g_Cvar_VoteDelay;

//----------------------------------------------------------------------------
// Used to track current vote data
//new Handle:g_hVoteTimer;
Handle g_hDisplayTimer;

int g_Clients;
int g_TotalClients;
int g_Items;
ArrayList g_hVotes;
NativeVote g_hCurVote;
int g_curDisplayClient = 0;
char g_newMenuTitle[TRANSLATION_LENGTH];
int g_curItemClient = 0;
char g_newMenuItem[TRANSLATION_LENGTH];

bool g_bStarted;
bool g_bCancelled;
int g_NumVotes;
int g_VoteTime;
int g_VoteFlags;
float g_fStartTime;
int g_TimeLeft;
int g_ClientVotes[MAXPLAYERS+1];
bool g_bRevoting[MAXPLAYERS+1];
char g_LeaderList[1024];

ConVar sv_vote_holder_may_vote_no;

// Map list stuffs

#define STRINGTABLE_NAME					"ServerMapCycle"
#define STRINGTABLE_ITEM					"ServerMapCycle"
//#define MAP_STRING_CACHE_SIZE				PLATFORM_MAX_PATH * 256

// Forward
Handle g_OverrideMaps;
StringMap g_MapOverrides;
bool g_OverridesSet;
bool g_OverrideNextCallVote[MAXPLAYERS + 1];

enum struct CallVoteForwards
{
	Handle CallVote_Forward;
	Handle CallVote_Vis;
}

enum struct CallVoteListData
{
	NativeVotesOverride CallVoteList_VoteType;
	bool CallVoteList_VoteEnabled;
}

CallVoteForwards g_CallVotes[NativeVotesOverride_Count];

#include "nativevotes/game.sp"

public Plugin myinfo = 
{
	name = "NativeVotes",
	author = "Powerlord",
	description = "Voting API to use the game's native vote panels. Compatible with L4D, L4D2, TF2, and CS:GO.",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=208008"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char engineName[64];
	if (!Game_IsGameSupported(engineName, sizeof(engineName)))
	{
		Format(error, err_max, "Unsupported game: %s", engineName);
		//strcopy(error, err_max, "Unsupported game");
		return APLRes_Failure;
	}
	
	CreateNative("NativeVotes_IsVoteTypeSupported", Native_IsVoteTypeSupported);
	CreateNative("NativeVotes_Create", Native_Create);
	CreateNative("NativeVotes_Close", Native_Close);
	CreateNative("NativeVotes_Display", Native_Display);
	CreateNative("NativeVotes_AddItem", Native_AddItem);
	CreateNative("NativeVotes_InsertItem", Native_InsertItem);
	CreateNative("NativeVotes_RemoveItem", Native_RemoveItem);
	CreateNative("NativeVotes_RemoveAllItems", Native_RemoveAllItems);
	CreateNative("NativeVotes_GetItem", Native_GetItem);
	CreateNative("NativeVotes_GetItemCount", Native_GetItemCount);
	CreateNative("NativeVotes_SetDetails", Native_SetDetails);
	CreateNative("NativeVotes_GetDetails", Native_GetDetails);
	CreateNative("NativeVotes_SetTitle", Native_SetTitle);
	CreateNative("NativeVotes_GetTitle", Native_GetTitle);
	CreateNative("NativeVotes_SetTarget", Native_SetTarget);
	CreateNative("NativeVotes_GetTarget", Native_GetTarget);
	CreateNative("NativeVotes_GetTargetSteam", Native_GetTargetSteam);
	CreateNative("NativeVotes_IsVoteInProgress", Native_IsVoteInProgress);
	CreateNative("NativeVotes_GetMaxItems", Native_GetMaxItems);
	CreateNative("NativeVotes_SetOptionFlags", Native_SetOptionFlags);
	CreateNative("NativeVotes_GetOptionFlags", Native_GetOptionFlags);
	CreateNative("NativeVotes_SetNoVoteButton", Native_SetNoVoteButton);
	CreateNative("NativeVotes_Cancel", Native_Cancel);
	CreateNative("NativeVotes_SetResultCallback", Native_SetResultCallback);
	CreateNative("NativeVotes_CheckVoteDelay", Native_CheckVoteDelay);
	CreateNative("NativeVotes_IsClientInVotePool", Native_IsClientInVotePool);
	CreateNative("NativeVotes_RedrawClientVote", Native_RedrawClientVote);
	CreateNative("NativeVotes_GetType", Native_GetType);
	CreateNative("NativeVotes_SetTeam", Native_SetTeam);
	CreateNative("NativeVotes_GetTeam", Native_GetTeam);
	CreateNative("NativeVotes_SetInitiator", Native_SetInitiator);
	CreateNative("NativeVotes_GetInitiator", Native_GetInitiator);
	CreateNative("NativeVotes_DisplayPass", Native_DisplayPass);
	CreateNative("NativeVotes_DisplayPassCustomToOne", Native_DisplayPassCustomToOne);
	CreateNative("NativeVotes_DisplayPassEx", Native_DisplayPassEx);
	//CreateNative("NativeVotes_DisplayRawPass", Native_DisplayRawPass);
	CreateNative("NativeVotes_DisplayRawPassToOne", Native_DisplayRawPassToOne);
	CreateNative("NativeVotes_DisplayRawPassCustomToOne", Native_DisplayRawPassCustomToOne);
	CreateNative("NativeVotes_DisplayFail", Native_DisplayFail);
	CreateNative("NativeVotes_DisplayRawFail", Native_DisplayRawFail);
	//CreateNative("NativeVotes_DisplayRawFailToOne", Native_DisplayRawFailToOne);
	CreateNative("NativeVotes_AreVoteCommandsSupported", Native_AreVoteCommandsSupported);
	CreateNative("NativeVotes_RegisterVoteCommand", Native_RegisterVoteCommand);
	CreateNative("NativeVotes_UnregisterVoteCommand", Native_UnregisterVoteCommand);
	CreateNative("NativeVotes_DisplayCallVoteFail", Native_DisplayCallVoteFail);
	CreateNative("NativeVotes_RedrawVoteTitle", Native_RedrawVoteTitle);
	CreateNative("NativeVotes_RedrawVoteItem", Native_RedrawVoteItem);
	
	// Transitional syntax support
	CreateNative("NativeVote.NativeVote", Native_Create);
	CreateNative("NativeVote.Close", Native_Close);
	CreateNative("NativeVote.AddItem", Native_AddItem);
	CreateNative("NativeVote.InsertItem", Native_InsertItem);
	CreateNative("NativeVote.RemoveItem", Native_RemoveItem);
	CreateNative("NativeVote.RemoveAllItems", Native_RemoveAllItems);
	CreateNative("NativeVote.GetItem", Native_GetItem);
	CreateNative("NativeVote.SetDetails", Native_SetDetails);
	CreateNative("NativeVote.GetDetails", Native_GetDetails);
	CreateNative("NativeVote.SetTitle", Native_SetTitle);
	CreateNative("NativeVote.GetTitle", Native_GetTitle);
	CreateNative("NativeVote.SetTarget", Native_SetTarget);
	CreateNative("NativeVote.GetTarget", Native_GetTarget);
	CreateNative("NativeVote.GetTargetSteam", Native_GetTargetSteam);
	CreateNative("NativeVote.DisplayVote", Native_Display);
	CreateNative("NativeVote.DisplayPass", Native_DisplayPass);
	CreateNative("NativeVote.DisplayPassCustomToOne", Native_DisplayPassCustomToOne);
	CreateNative("NativeVote.DisplayPassEx", Native_DisplayPassEx);
	CreateNative("NativeVote.DisplayFail", Native_DisplayFail);
	CreateNative("NativeVote.OptionFlags.set", Native_SetOptionFlags);
	CreateNative("NativeVote.OptionFlags.get", Native_GetOptionFlags);
	CreateNative("NativeVote.NoVoteButton.set", Native_SetNoVoteButton);
	CreateNative("NativeVote.VoteResultCallback.set", Native_SetResultCallback);
	CreateNative("NativeVote.ItemCount.get", Native_GetItemCount);
	CreateNative("NativeVote.VoteType.get", Native_GetType);
	CreateNative("NativeVote.Team.set", Native_SetTeam);
	CreateNative("NativeVote.Team.get", Native_GetTeam);
	CreateNative("NativeVote.Initiator.set", Native_SetInitiator);
	CreateNative("NativeVote.Initiator.get", Native_GetInitiator);
	
	RegPluginLibrary("nativevotes");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("core.phrases");
	LoadTranslations("nativevotes.phrases.txt");
	
	CreateConVar("nativevotes_version", VERSION, "NativeVotes API version", FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_Cvar_VoteHintbox = CreateConVar("nativevotes_progress_hintbox", "0", "Show current vote progress in a hint box", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_VoteChat = CreateConVar("nativevotes_progress_chat", "0", "Show current vote progress as chat messages", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_VoteConsole = CreateConVar("nativevotes_progress_console", "0", "Show current vote progress as console messages", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_VoteClientConsole = CreateConVar("nativevotes_progress_client_console", "0", "Show current vote progress as console messages to clients", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_VoteDelay = CreateConVar("nativevotes_vote_delay", "30", "Sets the recommended time in between public votes", FCVAR_NONE, true, 0.0);
	
	Game_InitializeCvars();
	
	HookConVarChange(g_Cvar_VoteDelay, OnVoteDelayChange);

	AddCommandListener(Command_Vote, "vote"); // All games, command listeners aren't case sensitive
	
	sv_vote_holder_may_vote_no = FindConVar("sv_vote_holder_may_vote_no");
	
	// The new version of the CallVote system is TF2 only
	if (Game_AreVoteCommandsSupported())
	{
		AddCommandListener(Command_CallVote, "callvote");
		
		// None is type 0, which has no overrides
		// As of 2015-09-28, there are 10 votes for a total of 20 private forwards created here.
		for (int i = 1; i < sizeof(g_CallVotes); i++)
		{
			g_CallVotes[i].CallVote_Forward = CreateForward(ET_Hook, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_Cell);
			g_CallVotes[i].CallVote_Vis = CreateForward(ET_Hook, Param_Cell, Param_Cell);
		}
		
		g_OverrideMaps = CreateGlobalForward("NativeVotes_OverrideMaps", ET_Hook, Param_Cell);
	}
	
	g_hVotes = new ArrayList(1, Game_GetMaxItems());
	
	AutoExecConfig(true, "nativevotes");
}

public void OnMapStart()
{
	// Map list stuffs
	if (g_MapOverrides != null)
		delete g_MapOverrides;
		
	g_OverridesSet = false;
}

public Action Timer_RetryCallVote(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	
	if (client == 0)
	{
		return Plugin_Stop;
	}
	
	FakeClientCommand(client, "callvote");
	return Plugin_Stop;
}

public void ProcessMapList()
{
	int stringTableIndex = FindStringTable(STRINGTABLE_NAME);
	int stringIndex = FindStringIndex(stringTableIndex, STRINGTABLE_ITEM);

	StringMap overrideList = new StringMap();
	
	// Maplist resets every map
	int length = GetStringTableDataLength(stringTableIndex, stringIndex);
	char[] mapData = new char[length];
	GetStringTableData(stringTableIndex, stringIndex, mapData, length);

	// We'll get an extra blank entry if we don't do this
	TrimString(mapData);
	
	ExplodeStringToStringMap(mapData, "\n", overrideList, PLATFORM_MAX_PATH, ImplodePart_Key);

	Action mapResult = Plugin_Continue;
	Call_StartForward(g_OverrideMaps);
	Call_PushCell(overrideList);
	Call_Finish(mapResult);

	if (mapResult == Plugin_Changed && overrideList.Size > 0)
	{
#if defined LOG
		LogMessage("Overriding map list with %d maps", overrideList.Size);
#endif 
		
		g_MapOverrides = overrideList;
		
		int maxLength = GetStringMapImplodeSize(overrideList, 1, ImplodePart_Key);
		
		char[] newMapData = new char[maxLength];
		int newLength = ImplodeStringMapToString(overrideList, "\n", newMapData, maxLength, ImplodePart_Key);
		if (newLength < maxLength && newMapData[newLength] != '\n')
		{
			// do this to avoid a StrCat
			newLength += strcopy(newMapData[newLength], maxLength, "\n") + 1;
		}
		
		SetStringTableData(stringTableIndex, stringIndex, newMapData, newLength);
	}
	else
	{
		delete overrideList;
	}
}

public void OnClientDisconnect_Post(int client)
{
	if (!Internal_IsVoteInProgress() || !Internal_IsClientInVotePool(client))
	{
		return;
	}

	/* Wipe out their vote if they had one.  We have to make sure the
	 * newly connected client is not allowed to vote.
	 */
	int item = g_ClientVotes[client];
	if (item >= VOTE_PENDING)
	{
		if (item > VOTE_PENDING)
		{
			g_hVotes.Set(item, g_hVotes.Get(item) - 1);
		}
		
		g_ClientVotes[client] = VOTE_NOT_VOTING;
	}
	
	CancelClientVote(g_hCurVote, client, MenuCancel_Disconnected);
}

void CancelClientVote(NativeVote vote, int client, int reason)
{
	OnCancel(vote, client, reason);
	OnClientEnd();
}

public Action Command_CallVote(int client, const char[] command, int argc)
{
	if (g_OverrideNextCallVote[client])
	{
		g_OverrideNextCallVote[client] = false;
		return Plugin_Continue;
	}
	
	if (Internal_IsVoteInProgress() || Game_IsVoteInProgress())
	{
		return Plugin_Handled;
	}
	
	Action result = Plugin_Continue;
	
	switch (argc)
	{
		// No args means that we need to return a CallVoteSetup usermessage
		case 0:
		{
			if (!g_OverridesSet	&& Game_AreVoteCommandsSupported())
			{
				g_OverridesSet = true;
				ProcessMapList();

#if defined LOG
				LogMessage("Delaying to allow stringtable time to network");
#endif
				// Force it to reissue the callvote command so that the map list gets networked
				CreateTimer(0.1, Timer_RetryCallVote, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
				return Plugin_Handled;
			}

			ArrayList hVoteTypes = new ArrayList(sizeof(CallVoteListData)); // Stores arrays of CallVoteListData
			
			Game_AddDefaultVotes(hVoteTypes);

			// Add our overridden votes to the system
			bool overridesPresent = false;
			for (int i = 1; i < sizeof(g_CallVotes); i++)
			{
				if (GetForwardFunctionCount(g_CallVotes[i].CallVote_Forward) > 0)
				{
#if defined LOG
					LogMessage("Found overrides for vote type: %d", i);
#endif
					overridesPresent = true;
					CallVoteListData voteType;

					int pos = FindVoteInArray(hVoteTypes, view_as<NativeVotesOverride>(i));
					if (pos > -1)
					{
						hVoteTypes.GetArray(pos, voteType, sizeof(CallVoteListData));
						voteType.CallVoteList_VoteEnabled = true;
#if defined LOG
						LogMessage("Forcing vote type to visible: %d", i);
#endif
						hVoteTypes.SetArray(pos, voteType);
					}
					else
					{
#if defined LOG
						LogMessage("Creating override for vote type: %d", i);
#endif
						voteType.CallVoteList_VoteType = view_as<NativeVotesOverride>(i);
						voteType.CallVoteList_VoteEnabled = true;
						hVoteTypes.PushArray(voteType);
					}
				}
			}
			
			if (overridesPresent)
			{
				PerformVisChecks(client, hVoteTypes);
#if defined LOG
				LogMessage("Overriding VoteSetup message");
#endif
				Game_DisplayVoteSetup(client, hVoteTypes);
				delete hVoteTypes;
				return Plugin_Handled;
			}
			else
			{
				delete hVoteTypes;
				return Plugin_Continue;
			}
		}
		
		default:
		{
			char voteCommand[VOTE_STRING_SIZE];
			GetCmdArg(1, voteCommand, VOTE_STRING_SIZE);

#if defined LOG
			LogMessage("User is attempting to call %s", voteCommand);
#endif
			
			NativeVotesOverride overrideType = Game_VoteStringToVoteOverride(voteCommand);
			
			char argument[PLATFORM_MAX_PATH];
			
			if (GetForwardFunctionCount(g_CallVotes[overrideType].CallVote_Forward) == 0)
			{
				
				if (g_MapOverrides != null && 
					(overrideType == NativeVotesOverride_ChgLevel ||
					overrideType == NativeVotesOverride_NextLevel))
				{
					char map[PLATFORM_MAX_PATH];
					
					GetCmdArg(2, map, sizeof(map));
					g_MapOverrides.GetString(map, argument, sizeof(argument));

					g_OverrideNextCallVote[client] = true;
					FakeClientCommandEx(client, "callvote %s %s", voteCommand, argument);
					return Plugin_Handled;
				}
				
#if defined LOG
				LogMessage("We don't have a handler for %s, passing back to server", voteCommand);
#endif
				return Plugin_Continue;
			}
			
			// Vis checks are done here just in case something went wrong and the vote option was shown to a person it shouldn't be.
#if defined LOG
			LogMessage("Calling visForward for %s", voteCommand);
#endif
			Call_StartForward(g_CallVotes[overrideType].CallVote_Vis);
			Call_PushCell(client);
			Call_PushCell(overrideType);
			Call_Finish(result);
			if (result >= Plugin_Handled)
			{
				return result;
			}
					
			NativeVotesType voteType = Game_VoteStringToVoteType(voteCommand);
			
			int target = 0;
			
			NativeVotesKickType kickType = NativeVotesKickType_None;
			
			switch (voteType)
			{
				case NativeVotesType_Kick:
				{
					char param1[20];
					GetCmdArg(2, param1, sizeof(param1));
					
					kickType = Game_GetKickType(param1, target);
					
					int targetClient = GetClientOfUserId(target);
					
					if (targetClient < 1 || targetClient > MaxClients || !IsClientInGame(targetClient))
					{
						return Plugin_Continue;
					}
	
					GetClientName(targetClient, argument, sizeof(argument));
				}
				
				case NativeVotesType_ChgLevel, NativeVotesType_NextLevel:
				{
					if (g_MapOverrides == null)
					{
						GetCmdArg(2, argument, sizeof(argument));
					}
					else
					{
						char map[PLATFORM_MAX_PATH];
					
						GetCmdArg(2, map, sizeof(map));
						g_MapOverrides.GetString(map, argument, sizeof(argument));
					}
				}
				
				default:
				{
					GetCmdArg(2, argument, sizeof(argument));
				}
			}

#if defined LOG
			LogMessage("Calling callVoteForward for %s", voteCommand);
#endif
			
			Call_StartForward(g_CallVotes[overrideType].CallVote_Forward);
			Call_PushCell(client);
			Call_PushCell(overrideType);
			Call_PushString(argument);
			Call_PushCell(kickType);
			Call_PushCell(target);
			Call_Finish(result);
		}
	}
	
	// Default to continue if we're not processing things
	return result;

}

stock int FindVoteInArray(ArrayList myArray, NativeVotesOverride value)
{
	int size = myArray.Length;
	for (int i = 0; i < size; i++)
	{
		CallVoteListData voteData;
		myArray.GetArray(i, voteData, sizeof(CallVoteListData));
		
		if (voteData.CallVoteList_VoteType == value)
		{
			return i;
		}
	}
	
	return -1;
}

stock bool IsVoteEnabled(ArrayList myArray, NativeVotesOverride value)
{
	int pos = FindVoteInArray(myArray, value);
	if (pos > -1)
	{
		CallVoteListData voteType;
		myArray.GetArray(pos, voteType, sizeof(CallVoteListData));
		if (voteType.CallVoteList_VoteEnabled)
			return true;
	}
	return false;
}

public void OnVoteDelayChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	/* See if the new vote delay isn't something we need to account for */
	if (convar.IntValue < 1)
	{
		g_NextVote = 0;
		return;
	}
	
	/* If there was never a last vote, ignore this change */
	if (g_NextVote <= 0)
	{
		return;
	}
	
	/* Subtract the original value, then add the new one. */
	g_NextVote -= StringToInt(oldValue);
	g_NextVote += StringToInt(newValue);
}

public void OnMapEnd()
{
	if (g_hCurVote != null)
	{
		// Cancel the ongoing vote, but don't close the handle, as the other plugins may still re-use it
		CancelVoting();
		//OnVoteCancel(g_hCurVote, VoteCancel_Generic);
		g_hCurVote = null;
	}
	
	if (g_hDisplayTimer != null)
	{
		delete g_hDisplayTimer;
	}

//	g_hVoteTimer = INVALID_HANDLE;
}

public Action Command_Vote(int client, const char[] command, int argc)
{
#if defined LOG
	char voteString[128];
	GetCmdArgString(voteString, sizeof(voteString));
	LogMessage("Client %N ran a vote command: %s", client, voteString);
#endif
	
	// If we're not running a vote, return the vote control back to the server
	if (!Internal_IsVoteInProgress() || g_ClientVotes[client] != VOTE_PENDING)
	{
		return Plugin_Continue;
	}
	
	char option[64];
	GetCmdArgString(option, sizeof(option));
	
	int item = Game_ParseVote(option);
	
	// Make sure we don't go out of bounds on the vote
	if (item == NATIVEVOTES_VOTE_INVALID || item > g_Items)
	{
		return Plugin_Handled;
	}

	bool cancel;
	
	if (Data_GetFlags(g_hCurVote) & MENUFLAG_BUTTON_NOVOTE && item == 0)
	{
		cancel = true;
	}

	if (cancel)
	{
		OnCancel(g_hCurVote, client, MenuCancel_Exit);
	}
	else
	{
		OnVoteSelect(g_hCurVote, client, item);
	}

	OnClientEnd();
	
	return Plugin_Handled;
}

void OnVoteSelect(NativeVote vote, int client, int item)
{
	if (Internal_IsVoteInProgress() && g_ClientVotes[client] == VOTE_PENDING)
	{
		/* Check by our item count, NOT the vote array size */
		if (item < g_Items)
		{
			Game_ClientSelectedItem(vote, client, item);
			
			g_ClientVotes[client] = item;
			g_hVotes.Set(item, g_hVotes.Get(item) + 1);
			g_NumVotes++;
			
			Game_UpdateVoteCounts(g_hVotes, g_TotalClients);
			
			if (g_Cvar_VoteChat.BoolValue || g_Cvar_VoteConsole.BoolValue || g_Cvar_VoteClientConsole.BoolValue)
			{
				char choice[128];
				char name[MAX_NAME_LENGTH+1];
				Data_GetItemDisplay(vote, item, choice, sizeof(choice));
				
				GetClientName(client, name, MAX_NAME_LENGTH);
				
				if (g_Cvar_VoteConsole.BoolValue)
				{
					PrintToServer("[%s] %T", LOGTAG, "Voted For", LANG_SERVER, name, choice);
				}
				
				if (g_Cvar_VoteChat.BoolValue || g_Cvar_VoteClientConsole.BoolValue)
				{
					char phrase[30];
					
					if (g_bRevoting[client])
					{
						strcopy(phrase, sizeof(phrase), "Changed Vote");
					}
					else
					{
						strcopy(phrase, sizeof(phrase), "Voted For");
					}
					
					if (g_Cvar_VoteChat.BoolValue)
					{
						PrintToChatAll("[%s] %t", LOGTAG, phrase, name, choice);
					}
					
					if (g_Cvar_VoteClientConsole.BoolValue)
					{
						for (int i = 1; i <= MaxClients; i++)
						{
							if (IsClientInGame(i) && !IsFakeClient(i))
							{
								PrintToConsole(i, "[%s] %t", LOGTAG, phrase, name, choice);
							}
						}
					}
				}
			}
			
			BuildVoteLeaders();
			DrawHintProgress();
			
			OnSelect(g_hCurVote, client, item);
		}
	}
}

//MenuAction_Select
void OnSelect(NativeVote vote, int client, int item)
{
	MenuAction actions = Data_GetActions(vote);
	if (actions & MenuAction_Select)
	{
		DoAction(vote, MenuAction_Select, client, item);
	}
}

//MenuAction_End
void OnEnd(NativeVote vote, int item)
{
	// Always called
	DoAction(vote, MenuAction_End, item, 0);
}


stock void OnVoteEnd(NativeVote vote, int item)
{
	// Always called
	DoAction(vote, MenuAction_VoteEnd, item, 0);
}

void OnVoteStart(NativeVote vote)
{
	// Fire both Start and VoteStart in the other plugin.
	
	MenuAction actions = Data_GetActions(vote);
	if (actions & MenuAction_Start)
	{
		DoAction(vote, MenuAction_Start, 0, 0);
	}
	
	// Always called
	DoAction(vote, MenuAction_VoteStart, 0, 0);
}

void OnVoteCancel(NativeVote vote, int reason)
{
	// Always called
	DoAction(vote, MenuAction_VoteCancel, reason, 0);
}

void OnCancel(NativeVote vote, int client, int reason)
{
	DoAction(vote, MenuAction_Cancel, client, reason);
}

void OnClientEnd()
{
	DecrementPlayerCount();
}

Action DoAction(NativeVote vote, MenuAction action, int param1, int param2, Action def_res = Plugin_Continue)
{
	Action res = def_res;

	Handle handler = CloneHandle(Data_GetHandler(vote));
#if defined LOG
	LogMessage("Calling Menu forward for vote: %d, handler: %d, action: %d, param1: %d, param2: %d", vote, handler, action, param1, param2);
#endif
	Call_StartForward(handler);
	Call_PushCell(vote);
	Call_PushCell(action);
	Call_PushCell(param1);
	Call_PushCell(param2);
	Call_Finish(res);
	delete handler;
	return res;
}

void OnVoteResults(NativeVote vote, const int[][] votes, int num_votes, int item_count, const int[][] client_list, int num_clients)
{
	Handle resultsHandler = Data_GetResultCallback(vote);
	
	if (resultsHandler == null || !GetForwardFunctionCount(resultsHandler))
	{
		/* Call MenuAction_VoteEnd instead.  See if there are any extra winners. */
		int num_items = 1;
		for (int i = 1; i < num_votes; i++)
		{
			if (votes[i][VOTEINFO_ITEM_VOTES] != votes[0][VOTEINFO_ITEM_VOTES])
			{
				break;
			}
			num_items++;
		}
		
		/* See if we need to pick a random winner. */
		int winning_item;
		if (num_items > 1)
		{
			/* Yes, we do */
			winning_item = GetRandomInt(0, num_items - 1);
			winning_item = votes[winning_item][VOTEINFO_ITEM_INDEX];
		}
		else 
		{
			/* No, take the first */
			winning_item = votes[0][VOTEINFO_ITEM_INDEX];
		}
		
		int winning_votes = votes[0][VOTEINFO_ITEM_VOTES];
		
		DoAction(vote, MenuAction_VoteEnd, winning_item, (num_votes << 16) | (winning_votes & 0xFFFF));
	}
	else
	{
		// This code is quite different than its C++ version, as we're reversing the logic previously done
		
		int[] client_indexes = new int[num_clients];
		int[] client_items = new int[num_clients];
		int[] vote_items = new int[item_count];
		int[] vote_votes = new int[item_count];
		
		/* First array */
		for (int i = 0; i < item_count; i++)
		{
			vote_items[i] = votes[i][VOTEINFO_ITEM_INDEX];
			vote_votes[i] = votes[i][VOTEINFO_ITEM_VOTES];
		}
		
		/* Second array */
		for (int i = 0; i < num_clients; i++)
		{
			client_indexes[i] = client_list[i][VOTEINFO_CLIENT_INDEX];
			client_items[i] = client_list[i][VOTEINFO_CLIENT_ITEM];
		}

#if defined LOG
		LogMessage("Calling results forward for vote: %d, num_votes: %d, num_clients: %d, item_count: %d", vote, num_votes, num_clients, item_count);
#endif
		
		Call_StartForward(resultsHandler);
		Call_PushCell(vote);
		Call_PushCell(num_votes);
		Call_PushCell(num_clients);
		Call_PushArray(client_indexes, num_clients);
		Call_PushArray(client_items, num_clients);
		Call_PushCell(item_count);
		Call_PushArray(vote_items, item_count);
		Call_PushArray(vote_votes, item_count);
		Call_Finish();
	}
}

/*
VoteEnd(Handle:vote)
{
	if (g_NumVotes == 0)
	{
		// Fire VoteCancel in the other plugin
		OnVoteCancel(vote, VoteCancel_NoVotes);
	}
	else
	{
		new num_items;
		new num_votes;
		
		new slots = Game_GetMaxItems();
		new votes[slots][2];
		
		Internal_GetResults(votes, slots);
		
		if (!SendResultCallback(vote, num_votes, num_items, votes))
		{
			new Handle:handler = Data_GetHandler(g_hCurVote);
			
			Call_StartForward(handler);
			Call_PushCell(g_CurVote);
			Call_PushCell(MenuAction_VoteEnd);
			Call_PushCell(votes[0][VOTEINFO_ITEM_INDEX]);
			Call_PushCell(0);
			Call_Finish();
		}
	}
	
}

bool:SendResultCallback(Handle:vote, num_votes, num_items, const votes[][])
{
	new Handle:voteResults = Data_GetResultCallback(g_CurVote);
	if (GetForwardFunctionCount(voteResults) == 0)
	{
		return false;
	}
	
	// This block is present because we can't pass 2D arrays to other plugins' functions
	new item_indexes[];
	new item_votes[];
	
	for (int i = 0, i < num_items; i++)
	{
		item_indexes[i] = votes[i][VOTEINFO_ITEM_INDEX];
		item_votes[i] = votes[i][VOTEINFO_ITEM_VOTES];
	}
	
	// Client block
	new client_indexes[MaxClients];
	new client_votes[MaxClients];
	
	new num_clients;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_ClientVotes[i] > VOTE_PENDING)
		{
			client_indexes[num_clients] = i;
			client_votes[num_clients] = g_ClientVotes[i];
			num_clients++;
		}
	}
	
	Call_StartForward(voteResults);
	Call_PushCell(_:vote);
	Call_PushCell(num_votes);
	Call_PushCell(num_clients);
	Call_PushArray(client_indexes, num_clients);
	Call_PushArray(client_votes, num_clients);
	Call_PushCell(num_items);
	Call_PushArray(item_indexes, num_items);
	Call_PushArray(item_votes, num_items);
	Call_Finish();
	
	return true;
}
*/

void DrawHintProgress()
{
	if (!g_Cvar_VoteHintbox.BoolValue)
	{
		return;
	}
	
	float timeRemaining = (g_fStartTime + g_VoteTime) - GetGameTime();
	
	if (timeRemaining < 0.0)
	{
		timeRemaining = 0.0;
	}
	
	int iTimeRemaining = RoundFloat(timeRemaining);

	PrintHintTextToAll("%t%s", "Vote Count", g_NumVotes, g_TotalClients, iTimeRemaining, g_LeaderList);
}

void BuildVoteLeaders()
{
	if (g_NumVotes == 0 || !g_Cvar_VoteHintbox.BoolValue)
	{
		return;
	}
	
	// Since we can't have structs, we get "struct" with this instead
	
	int slots = Game_GetMaxItems();
	int[][] votes = new int[slots][2];
	
	int num_items = Internal_GetResults(votes);
	
	/* Take the top 3 (if applicable) and draw them */
	g_LeaderList[0] = '\0';
	
	for (int i = 0; i < num_items && i < 3; i++)
	{
		int cur_item = votes[i][VOTEINFO_ITEM_INDEX];
		char choice[256];
		Data_GetItemDisplay(g_hCurVote, cur_item, choice, sizeof(choice));
		Format(g_LeaderList, sizeof(g_LeaderList), "%s\n%i. %s: (%i)", g_LeaderList, i+1, choice, votes[i][VOTEINFO_ITEM_VOTES]);
	}
	
}

public int SortVoteItems(int[] a, int[] b, const int[][] array, Handle hndl)
{
	if (b[VOTEINFO_ITEM_VOTES] == a[VOTEINFO_ITEM_VOTES])
	{
		return 0;
	}
	else if (b[VOTEINFO_ITEM_VOTES] > a[VOTEINFO_ITEM_VOTES])
	{
		return 1;
	}
	else
	{
		return -1;
	}
}

void DecrementPlayerCount()
{
	g_Clients--;
	
	// The vote is running and we have no clients left, so end the vote.
	if (g_bStarted && g_Clients == 0)
	{
		EndVoting();
	}
	
}


void EndVoting()
{
	int voteDelay = g_Cvar_VoteDelay.IntValue;
	if (voteDelay < 1)
	{
		g_NextVote = 0;
	}
	else
	{
		g_NextVote = GetTime() + voteDelay;
	}
	
	if (g_hDisplayTimer != null)
	{
		delete g_hDisplayTimer;
	}
	
	if (g_bCancelled)
	{
		/* If we were cancelled, don't bother tabulating anything.
		 * Reset just in case someone tries to redraw, which means
		 * we need to save our states.
		 */
		NativeVote vote = g_hCurVote;
		Internal_Reset(true);
		OnVoteCancel(vote, VoteCancel_Generic);
		OnEnd(vote, MenuEnd_VotingCancelled);
		return;
	}
	
	int slots = Game_GetMaxItems();
	int[][] votes = new int[slots][2];
	int num_votes;
	int num_items = Internal_GetResults(votes, num_votes);
	
	if (!num_votes)
	{
		NativeVote vote = g_hCurVote;
		Internal_Reset();
		OnVoteCancel(vote, VoteCancel_NoVotes);
		OnEnd(vote, MenuEnd_VotingCancelled);
		return;
	}
	
	int[][] client_list = new int[MaxClients][2];
	int num_clients = Internal_GetClients(client_list);
	
	/* Save states, then clear what we've saved.
	 * This makes us re-entrant, which is always the safe way to go.
	 */
	NativeVote vote = g_hCurVote;
	Internal_Reset();
	
#if defined LOG
	LogMessage("Voting done");
#endif
	
	/* Send vote info */
	OnVoteResults(vote, votes, num_votes, num_items, client_list, num_clients);
	OnEnd(vote, MenuEnd_VotingDone);
}

bool StartVote(NativeVote vote, int num_clients, int[] clients, int max_time, int flags)
{
	if (!InitializeVoting(vote, max_time, flags))
	{
		return false;
	}
	
	/* Due to hibernating servers, we no longer use GameTime, but instead standard timestamps.
	 */

	int voteDelay = g_Cvar_VoteDelay.IntValue;
	if (voteDelay < 1)
	{
		g_NextVote = 0;
	}
	else
	{
		/* This little trick break for infinite votes!
		 * However, we just ignore that since those 1) shouldn't exist and
		 * 2) people must be checking IsVoteInProgress() beforehand anyway.
		 */
		g_NextVote = GetTime() + voteDelay + max_time;
	}
	
	g_fStartTime = GetGameTime();
	g_VoteTime = max_time;
	g_TimeLeft = max_time;
	
	int clientCount = 0;
	
	for (int i = 0; i < num_clients; ++i)
	{
		if (clients[i] < 1 || clients[i] > MaxClients)
		{
			continue;
		}
		
		g_ClientVotes[clients[i]] = VOTE_PENDING;
		clientCount++;
	}
	
	g_Clients = clientCount;
	
	Game_UpdateVoteCounts(g_hVotes, clientCount);
	
	DoClientVote(vote, clients, num_clients);	
	
	StartVoting();
	
	DrawHintProgress();
	
	return true;
}

bool DoClientVote(NativeVote vote, int[] clients, int num_clients)
{
	int totalPlayers = 0;
	int[] realClients = new int[MaxClients+1];
	
	for (int i = 0; i < num_clients; ++i)
	{
		if (clients[i] < 1 || clients[i] > MaxClients || !IsClientInGame(clients[i]) || IsFakeClient(clients[i]))
		{
			continue;
		}
		
		realClients[totalPlayers++] = clients[i];
	}
	
	if (totalPlayers > 0)
	{
		Game_DisplayVote(vote, realClients, totalPlayers);
		return true;
	}
	else
	{
		return false;
	}
}

bool InitializeVoting(NativeVote vote, int time, int flags)
{
	if (Internal_IsVoteInProgress())
	{
		return false;
	}
	
	Internal_Reset();
	
	/* Mark all clients as not voting */
	for (int i = 1; i <= MaxClients; ++i)
	{
		g_ClientVotes[i] = VOTE_NOT_VOTING;
		g_bRevoting[i] = false;
	}
	
	g_Items = Data_GetItemCount(vote);
	
	// Clear all items
	for (int i = 0; i < g_hVotes.Length; ++i)
	{
		g_hVotes.Set(i, 0);
	}
	
	g_hCurVote = vote;
	g_VoteTime = time;
	g_VoteFlags = flags;
	
	return true;
}

void StartVoting()
{
	if (g_hCurVote == null)
	{
		return;
	}
	
	g_bStarted = true;
	
	OnVoteStart(g_hCurVote);
	
	g_hDisplayTimer = CreateTimer(1.0, DisplayTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	g_TotalClients = g_Clients;

	/* By now we know how many clients were set.
	 * If there are none, we should end IMMEDIATELY.
	 */
	if (g_Clients == 0)
	{
		EndVoting();
		return;
	}
	
	// Kick targets automatically vote no if they're in the pool
	NativeVotesType voteType = Data_GetType(g_hCurVote);
	
	switch (voteType)
	{
		case NativeVotesType_Kick, NativeVotesType_KickCheating, NativeVotesType_KickIdle, NativeVotesType_KickScamming:
		{
			int target = Data_GetTarget(g_hCurVote);
			
			if (target > 0 && target <= MaxClients && IsClientConnected(target) && Internal_IsClientInVotePool(target))
			{
				Game_VoteNo(target);
			}
		}
	}
	
	// Initiators always vote yes when they're in the pool.
	if (voteType != NativeVotesType_Custom_Mult && voteType != NativeVotesType_NextLevelMult)
	{
		int initiator = Data_GetInitiator(g_hCurVote);
		
		if (initiator > 0 && initiator <= MaxClients && IsClientConnected(initiator) && Internal_IsClientInVotePool(initiator))
		{
			Game_VoteYes(initiator);
		}
	}
}

public Action DisplayTimer(Handle timer)
{
	DrawHintProgress();
	if (--g_TimeLeft == 0)
	{
		if (g_hDisplayTimer != null)
		{
			g_hDisplayTimer = null;
			EndVoting();
		}
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

int Internal_GetResults(int[][] votes, int &num_votes=0)
{
	if (!Internal_IsVoteInProgress())
	{
		return 0;
	}
	
	// Since we can't have structs, we get "struct" with this instead
	int num_items;
	
	num_votes = 0;
	
	for (int i = 0; i < g_Items; i++)
	{
		int voteCount = g_hVotes.Get(i);
		if (voteCount > 0)
		{
			votes[num_items][VOTEINFO_ITEM_INDEX] = i;
			votes[num_items][VOTEINFO_ITEM_VOTES] = voteCount;
			num_votes += voteCount;
			num_items++;
		}
	}
	
	/* Sort the item list descending like we promised */
	SortCustom2D(votes, num_items, SortVoteItems);

	return num_items;
}

int Internal_GetClients(int[][] client_vote)
{
	if (!Internal_IsVoteInProgress())
	{
		return 0;
	}
	
	/* Build the client list */
	int num_clients;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_ClientVotes[i] >= VOTE_PENDING)
		{
			client_vote[num_clients][VOTEINFO_CLIENT_INDEX] = i;
			client_vote[num_clients][VOTEINFO_CLIENT_ITEM] = g_ClientVotes[i];
			num_clients++;
		}
	}
	
	return num_clients;
}

bool Internal_IsCancelling()
{
	return g_bCancelled;
}

stock NativeVote Internal_GetCurrentVote()
{
	return g_hCurVote;
}

void Internal_Reset(bool cancel=false)
{
	g_Clients = 0;
	g_Items = 0;
	g_bStarted = false;
	g_hCurVote = null;
	g_NumVotes = 0;
	g_bCancelled = false;
	g_LeaderList[0] = '\0';
	g_TotalClients = 0;
	
	if (g_hDisplayTimer != null)
	{
		delete g_hDisplayTimer;
	}
	
	if (!cancel)
	{
		CreateTimer(5.0, Game_ResetVote, TIMER_FLAG_NO_MAPCHANGE);
	}
}

bool Internal_IsVoteInProgress()
{
	return (g_hCurVote != INVALID_HANDLE);
}

bool Internal_IsClientInVotePool(int client)
{
	if (client < 1
		|| client > MaxClients
		|| g_hCurVote == null)
	{
		return false;
	}

	return (g_ClientVotes[client] > VOTE_NOT_VOTING);
}

bool Internal_RedrawToClient(int client, bool revotes)
{
	if (!Internal_IsVoteInProgress() || !Internal_IsClientInVotePool(client))
	{
		return false;
	}
	
	if (g_ClientVotes[client] >= 0)
	{
		if ((g_VoteFlags & VOTEFLAG_NO_REVOTES) || !revotes || g_VoteTime <= VOTE_DELAY_TIME)
		{
			return false;
		}
		
		g_Clients++;
		SetArrayCell(g_hVotes, g_ClientVotes[client], GetArrayCell(g_hVotes, g_ClientVotes[client]) - 1);
		g_ClientVotes[client] = VOTE_PENDING;
		g_bRevoting[client] = true;
		g_NumVotes--;
		Game_UpdateVoteCounts(g_hVotes, g_TotalClients);
	}
	
	// Display the vote fail screen for a few seconds
	//Game_DisplayVoteFail(g_hCurVote, NativeVotesFail_Generic, client);
	
	// No, display a vote pass screen because that's nicer and we can customize it.
	// Note: This isn't inside the earlier if because some players have had issues where the display
	//   doesn't always appear the first time.
	char revotePhrase[128];
	Format(revotePhrase, sizeof(revotePhrase), "%T", "NativeVotes Revote", client);
	Game_DisplayVotePassCustom(g_hCurVote, revotePhrase, client);
	
	DataPack data;
	
	CreateDataTimer(VOTE_DELAY_TIME, RedrawTimer, data, TIMER_FLAG_NO_MAPCHANGE);
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(view_as<int>(g_hCurVote));
	
	return true;
}

public Action RedrawTimer(Handle timer, DataPack data)
{
	if (g_hCurVote == null)
	{
		return Plugin_Stop;
	}
	
	ResetPack(data);
	int client = GetClientOfUserId(data.ReadCell());
	if (client == 0)
	{
		return Plugin_Stop;
	}
	
	NativeVote vote = view_as<NativeVote>(data.ReadCell());
	
	if (Internal_IsVoteInProgress() && !Internal_IsCancelling() && vote == g_hCurVote)
	{
		Game_DisplayVoteToOne(vote, client);
	}
	
	return Plugin_Stop;
}

void CancelVoting()
{
	if (g_bCancelled || g_hCurVote == INVALID_HANDLE)
	{
		return;
	}
	
	g_bCancelled = true;
	
	EndVoting();
}

void PerformVisChecks(int client, ArrayList hVoteTypes)
{
	// Iterate backwards so we can safely remove items
	for (int i = hVoteTypes.Length - 1; i >= 0; i--)
	{
		CallVoteListData voteData;
		hVoteTypes.GetArray(i, voteData, sizeof(CallVoteListData));
		
		Action hide = Plugin_Continue;
		
#if defined LOG
		LogMessage("Checking visibility forward for %d: %d", voteData.CallVoteList_VoteType., g_CallVotes[voteData.CallVoteList_VoteType].CallVote_Vis);
#endif
		Call_StartForward(g_CallVotes[voteData.CallVoteList_VoteType].CallVote_Vis);
		Call_PushCell(client);
		Call_PushCell(voteData.CallVoteList_VoteType);
		Call_Finish(hide);
		if (hide >= Plugin_Handled)
		{
#if defined LOG
			LogMessage("Hiding vote type %d", voteData.CallVoteList_VoteType);
#endif
			if (Game_AreDisabledIssuesHidden())
			{
				// Since we hide disabled issues, remove it from the arraylist
				RemoveFromArray(hVoteTypes, i);
			}
			else
			{
				// Arrays are pass by ref, so this should update the one inside the ArrayList
				voteData.CallVoteList_VoteEnabled = false;
			}
		}
	}
}

//----------------------------------------------------------------------------
// Natives

// native bool:NativeVotes_IsVoteTypeSupported(NativeVotesType:voteType);
public int Native_IsVoteTypeSupported(Handle plugin, int numParams)
{
	NativeVotesType type = GetNativeCell(1);
	
	return Game_CheckVoteType(type);
}

// native Handle:NativeVotes_Create(MenuHandler:handler, NativeVotesType:voteType,
//	MenuAction:actions=NATIVEVOTES_ACTIONS_DEFAULT);
public int Native_Create(Handle plugin, int numParams)
{
	Function handler = GetNativeFunction(1);
	NativeVotesType voteType = GetNativeCell(2);
	MenuAction actions = GetNativeCell(3);
	
	if (handler == INVALID_FUNCTION)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Menuhandler is invalid");
	}
	
	NativeVote vote;
	if (Game_CheckVoteType(voteType))
	{
		vote = Data_CreateVote(voteType, actions);
	}
	else
	{
		return view_as<int>(INVALID_HANDLE);
	}
	
	if (voteType != NativeVotesType_NextLevelMult && voteType != NativeVotesType_Custom_Mult)
	{
		Data_AddItem(vote, "yes", "Yes");
		Data_AddItem(vote, "no", "No");
	}
	
	Handle menuForward = Data_GetHandler(vote);
	
	AddToForward(menuForward, plugin, handler);
	
	return view_as<int>(vote);
}

// native Handle:NativeVotes_Close(Handle:vote);
public int Native_Close(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	
	if (vote == null)
	{
		return 0;
	}
	
	if (g_hCurVote == vote)
	{
		CancelVoting();
		g_hCurVote = null;

/*		
		if (g_hVoteTimer != INVALID_HANDLE)
		{
			KillTimer(g_hVoteTimer);
			g_hVoteTimer = INVALID_HANDLE;
		}
*/
	}
	
	// This bit is necessary because the Forward system appears to not remove these when the forward Handle is closed
	// This was necessary in SM 1.5.x, but has a REALLY high probability of crashing in SM 1.6, plus is no longer needed
	//new Handle:menuForward = Data_GetHandler(vote);
	//RemoveAllFromForward(menuForward, plugin);
	
	//new Handle:voteResults = Data_GetResultCallback(vote);
	//RemoveAllFromForward(voteResults, plugin);
	
	// Do the datatype-specific close operations
	Data_CloseVote(vote);
	return 0;
}

// native bool:NativeVotes_Display(Handle:vote, clients[], numClients, time, flags=0);
public int Native_Display(Handle plugin, int numParams)
{
	if (Internal_IsVoteInProgress())
	{
		ThrowNativeError(SP_ERROR_NATIVE, "A vote is already in progress");
	}
	
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return false;
	}
	
	int count = GetNativeCell(3);
	int[] clients = new int[count];
	GetNativeArray(2, clients, count);
	
	// Note: Only one flag exists: VOTEFLAG_NO_REVOTES
	int flags = 0;
	
	if (numParams >= 5)
	{
		flags = GetNativeCell(5);
	}
	
	if (!StartVote(vote, count, clients, GetNativeCell(4), flags))
	{
		return 0;
	}
	
	return 1;
	
}

// native bool:NativeVotes_AddItem(Handle:vote, const String:info[], const String:display[]);
public int Native_AddItem(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return false;
	}

	NativeVotesType voteType = Data_GetType(vote);
	
	if (voteType != NativeVotesType_NextLevelMult && voteType != NativeVotesType_Custom_Mult)
	{
		return false;
	}

	char info[256];
	char display[256];
	GetNativeString(2, info, sizeof(info));
	GetNativeString(3, display, sizeof(display));
	
	return Data_AddItem(vote, info, display);
}

// native bool:NativeVotes_InsertItem(Handle:vote, position, const String:info[], const String:display[]);
public int Native_InsertItem(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return false;
	}

	NativeVotesType voteType = Data_GetType(vote);
	
	if (voteType != NativeVotesType_NextLevelMult && voteType != NativeVotesType_Custom_Mult)
	{
		return false;
	}

	int position = GetNativeCell(2);
	
	if (position < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Vote index can't be negative: %d", position);
		return false;
	}
	
	char info[256];
	char display[256];
	GetNativeString(3, info, sizeof(info));
	GetNativeString(4, display, sizeof(display));
	
	return Data_InsertItem(vote, position, info, display);
	
}

// native bool:NativeVotes_RemoveItem(Handle:vote, position);
public int Native_RemoveItem(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return false;
	}
	
	NativeVotesType voteType = Data_GetType(vote);
	
	if (voteType != NativeVotesType_NextLevelMult && voteType != NativeVotesType_Custom_Mult)
	{
		return false;
	}

	int position = GetNativeCell(2);
	
	return Data_RemoveItem(vote, position);
}

// native NativeVotes_RemoveAllItems(Handle:vote);
public int Native_RemoveAllItems(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	Data_RemoveAllItems(vote);
	return 0;
}

// native bool:NativeVotes_GetItem(Handle:vote, 
//						position, 
//						String:infoBuf[], 
//						infoBufLen,
//						String:dispBuf[]="",
//						dispBufLen=0);
public int Native_GetItem(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	int position = GetNativeCell(2);
	
	int infoLength = GetNativeCell(4);
	char[] info = new char[infoLength];
	Data_GetItemInfo(vote, position, info, infoLength);
	SetNativeString(3, info, infoLength);
	
	if (numParams >= 6)
	{
		int displayLength = GetNativeCell(6);
		if (displayLength > 0)
		{
			char[] display = new char[displayLength];
			Data_GetItemDisplay(vote, position, display, displayLength);
			SetNativeString(5, display, displayLength);
		}
	}
	return 0;
}

// native NativeVotes_GetItemCount(Handle:vote);
public int Native_GetItemCount(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	return Data_GetItemCount(vote);
}

// native NativeVotes_GetDetails(Handle:vote, String:buffer[], maxlength);
public int Native_GetDetails(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	int len = GetNativeCell(3);

	char[] details = new char[len];
	
	Data_GetDetails(vote, details, len);
	
	SetNativeString(2, details, len);
	return 0;
}

// native NativeVotes_SetDetails(Handle:vote, String:fmt[], any:...);
public int Native_SetDetails(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	char details[MAX_VOTE_DETAILS_LENGTH];

	//SetGlobalTransTarget(LANG_SERVER);
	FormatNativeString(0, 2, 3, sizeof(details), _, details);
	
	Data_SetDetails(vote, details);
	return 0;
}

// native NativeVotes_GetDetails(Handle:vote, String:buffer[], maxlength);
public int Native_GetTitle(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	int len = GetNativeCell(3);

	char[] title = new char[len];
	
	Data_GetTitle(vote, title, len);
	
	SetNativeString(2, title, len);
	return 0;
}

// native NativeVotes_SetTitle(Handle:vote, String:fmt[], any:...);
public int Native_SetTitle(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	char details[MAX_VOTE_DETAILS_LENGTH];
	
	//SetGlobalTransTarget(LANG_SERVER);
	FormatNativeString(0, 2, 3, sizeof(details), _, details);
	
	Data_SetTitle(vote, details);
	return 0;
}

// native bool:NativeVotes_IsVoteInProgress();
public int Native_IsVoteInProgress(Handle plugin, int numParams)
{
	return Internal_IsVoteInProgress() || Game_IsVoteInProgress();
}

// native NativeVotes_GetMaxItems();
public int Native_GetMaxItems(Handle plugin, int numParams)
{
	return Game_GetMaxItems();
}

// native NativeVotes_GetOptionFlags(Handle:vote);
public int Native_GetOptionFlags(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	return Data_GetFlags(vote);
}

// native NativeVotes_SetOptionFlags(Handle:vote, flags);
public int Native_SetOptionFlags(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	int flags = GetNativeCell(2);
	
	// This is an ORed group of flags to strip the ones we don't support
	flags &= (MENUFLAG_BUTTON_NOVOTE);
	
	Data_SetFlags(vote, flags);
	return 0;
}

// native bool NativeVotes_SetNoVoteButton(Handle vote, bool button);
public int Native_SetNoVoteButton(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
	}

	int flags = Data_GetFlags(vote);
	
	if (GetNativeCell(2))
	{
		flags |= MENUFLAG_BUTTON_NOVOTE;
	}
	else
	{
		flags &= ~MENUFLAG_BUTTON_NOVOTE;
	}
	
	Data_SetFlags(vote, flags);
	
	int newflags = Data_GetFlags(vote);
	
	return (flags == newflags);
}

// native NativeVotes_Cancel();
public int Native_Cancel(Handle plugin, int numParams)
{
	if (!Internal_IsVoteInProgress())
	{
		ThrowNativeError(SP_ERROR_NATIVE, "No vote is in progress");
		return 0;
	}
	
	CancelVoting();
	return 0;
}

// native NativeVotes_SetResultCallback(Handle:vote, NativeVotes_VoteHandler:callback);
public int Native_SetResultCallback(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	Function handler = GetNativeFunction(2);
	
	if (handler == INVALID_FUNCTION)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes_VoteHandler is invalid");
		return 0;
	}
	
	Handle voteResults = Data_GetResultCallback(vote);
	
	RemoveAllFromForward(voteResults, plugin);
	if (!AddToForward(voteResults, plugin, handler))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes_VoteHandler cannot be added to forward");
	}
	return 0;
}

// native NativeVotes_CheckVoteDelay();
public int Native_CheckVoteDelay(Handle plugin, int numParams)
{
	int curTime = GetTime();
	if (g_NextVote <= curTime)
	{
		return 0;
	}
	
	return (g_NextVote - curTime);
}

// native bool:NativeVotes_IsClientInVotePool(client);
public int Native_IsClientInVotePool(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (client <= 0 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
		return false;
	}
	
	if (!Internal_IsVoteInProgress())
	{
		ThrowNativeError(SP_ERROR_NATIVE, "No vote is in progress");
		return false;
	}
	
	return Internal_IsClientInVotePool(client);
}

// native bool:NativeVotes_RedrawClientVote(client, bool:revotes=true);
public int Native_RedrawClientVote(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients || !IsClientConnected(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
		return false;
	}
	
	if (!Internal_IsVoteInProgress())
	{
		// When revoting in TF2, NativeVotes_IsVoteInProgress always gets skipped because of Game_IsVoteInProgress() 
		// 	TF2s vote controller will stay alive a few seconds after the vote is complete
		// 	If one tries to revote right as a vote completes, it will throw an error
		LogError("No vote is in progress");
		return false;
	}
	
	if (!Internal_IsClientInVotePool(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client is not in the voting pool");
		return false;
	}
	
	bool revote = true;
	if (numParams >= 2 && !GetNativeCell(2))
	{
		revote = false;
	}
	
	return Internal_RedrawToClient(client, revote);
}

// native NativeVotesType:NativeVotes_GetType(Handle:vote);
public int Native_GetType(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	return view_as<int>(Data_GetType(vote));
}

// native NativeVotes_GetTeam(Handle:vote);
public int Native_GetTeam(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return NATIVEVOTES_ALL_TEAMS;
	}
	
	return Data_GetTeam(vote);
	
}

// native NativeVotes_SetTeam(Handle:vote, team);
public int Native_SetTeam(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	int team = GetNativeCell(2);
	
	// Teams are numbered starting with 0
	// Currently 4 is the maximum (Unassigned, Spectator, Team 1, Team 2)
	if (team >= GetTeamCount())
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Team %d is invalid", team);
		return 0;
	}
	
	if (g_EngineVersion == Engine_TF2 && team == NATIVEVOTES_ALL_TEAMS)
	{
		team = NATIVEVOTES_TF2_ALL_TEAMS;
	}
	
	Data_SetTeam(vote, team);
	return 0;
}

// native NativeVotes_GetInitiator(Handle:vote);
public int Native_GetInitiator(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return NATIVEVOTES_SERVER_INDEX;
	}
	
	return Data_GetInitiator(vote);
}

// native NativeVotes_SetInitiator(Handle:vote, client);
public int Native_SetInitiator(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	int initiator = GetNativeCell(2);
	Data_SetInitiator(vote, initiator);
	return 0;
}

// native NativeVotes_DisplayPass(Handle:vote, const String:details[]="");
public int Native_DisplayPass(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}

	if (numParams >= 2)
	{
		char winner[TRANSLATION_LENGTH];
		FormatNativeString(0, 2, 3, sizeof(winner), _, winner);
		
		Game_DisplayVotePass(vote, winner);
	}
	else
	{
		Game_DisplayVotePass(vote);		
	}
	return 0;
}

// native NativeVotes_DisplayPassCustomToOne(Handle:vote, client, const String:format[], any:...);
public int Native_DisplayPassCustomToOne(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}

	int client = GetNativeCell(2);
	
	char translation[TRANSLATION_LENGTH];
	
	SetGlobalTransTarget(client);
	FormatNativeString(0, 3, 4, TRANSLATION_LENGTH, _, translation);

	Game_DisplayVotePassCustom(vote, translation, client);
	return 0;
}

// native NativeVotes_DisplayPassEx(Handle:vote, NativeVotesPassType:passType, const String:details[]="");
public int Native_DisplayPassEx(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	NativeVotesPassType passType = view_as<NativeVotesPassType>(GetNativeCell(2));
	
	if (!Game_CheckVotePassType(passType))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid vote pass type: %d", passType);
	}
	
	if (numParams >= 3)
	{
		char winner[TRANSLATION_LENGTH];
		//SetGlobalTransTarget(LANG_SERVER);
		FormatNativeString(0, 3, 4, sizeof(winner), _, winner);
		
		Game_DisplayVotePassEx(vote, passType, winner);
	}
	else
	{
		Game_DisplayVotePassEx(vote, passType);
	}
	return 0;
}

// native NativeVotes_DisplayRawPass(NativeVotesPassType:passType, const String:details[]="", team=NATIVEVOTES_ALL_TEAMS);
/*
public Native_DisplayRawPass(Handle:plugin, numParams)
{
	new NativeVotesPassType:passType = NativeVotesPassType:GetNativeCell(1);
	
	if (!Game_CheckVotePassType(passType))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid vote pass type: %d", passType);
	}

	new len;
	GetNativeStringLength(2, len);
	new String:winner[len+1];
	GetNativeString(2, winner, len+1);
	new team = GetNativeCell(3);

	if (g_EngineVersion == Engine_TF2 && team == NATIVEVOTES_ALL_TEAMS)
	{
		team = NATIVEVOTES_TF2_ALL_TEAMS;
	}
	
	Game_DisplayRawVotePass(passType, winner, team);
}
*/

// native NativeVotes_DisplayRawPassToOne(client, NativeVotesPassType:passType, const String:details[]="", team=NATIVEVOTES_ALL_TEAMS);
public int Native_DisplayRawPassToOne(Handle plugin, int numParams)
{
	int  client = GetNativeCell(1);
	NativeVotesPassType passType = view_as<NativeVotesPassType>(GetNativeCell(2));
	
	if (!Game_CheckVotePassType(passType))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid vote pass type: %d", passType);
	}

	int team = GetNativeCell(3);
	
	if (g_EngineVersion == Engine_TF2 && team == NATIVEVOTES_ALL_TEAMS)
	{
		team = NATIVEVOTES_TF2_ALL_TEAMS;
	}
	
	if (numParams >= 4)
	{
		char winner[TRANSLATION_LENGTH];
		SetGlobalTransTarget(client);
		FormatNativeString(0, 4, 5, sizeof(winner), _, winner);
	
		Game_DisplayRawVotePass(passType, team, client, winner);
	}
	else
	{
		Game_DisplayRawVotePass(passType, team, client);
	}
	return 0;
}

// native NativeVotes_DisplayRawPassCustomToOne(client, team, const String:format[], any:...);
public int Native_DisplayRawPassCustomToOne(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int team = GetNativeCell(2);
	
	char translation[TRANSLATION_LENGTH];
	
	SetGlobalTransTarget(client);
	FormatNativeString(0, 3, 4, TRANSLATION_LENGTH, _, translation);

	Game_DisplayRawVotePassCustom(translation, team, client);
	return 0;
}

// native NativeVotes_DisplayFail(Handle:vote, NativeVotesFailType:reason=NativeVotesFail_Generic);
public int Native_DisplayFail(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	NativeVotesFailType reason = view_as<NativeVotesFailType>(GetNativeCell(2));

	Game_DisplayVoteFail(vote, reason);
	return 0;
}

// native NativeVotes_DisplayRawFail(NativeVotesFailType:reason=NativeVotesFail_Generic, team=NATIVEVOTES_ALL_TEAMS);
public int Native_DisplayRawFail(Handle plugin, int numParams)
{
	int size = GetNativeCell(2);
	int[] clients = new int[size];
	GetNativeArray(1, clients, size);
	
	NativeVotesFailType reason = view_as<NativeVotesFailType>(GetNativeCell(3));
	
	int team = GetNativeCell(4);

	if (g_EngineVersion == Engine_TF2 && team == NATIVEVOTES_ALL_TEAMS)
	{
		team = NATIVEVOTES_TF2_ALL_TEAMS;
	}
	
	Game_DisplayRawVoteFail(clients, size, reason, team);
	return 0;
}

// native NativeVotes_DisplayRawFailToOne(client, NativeVotesFailType:reason=NativeVotesFail_Generic, team=NATIVEVOTES_ALL_TEAMS);
/*
public Native_DisplayRawFailToOne(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	new NativeVotesFailType:reason = NativeVotesFailType:GetNativeCell(2);
	
	new team = GetNativeCell(3);
	
	if (g_EngineVersion == Engine_TF2 && team == NATIVEVOTES_ALL_TEAMS)
	{
		team = NATIVEVOTES_TF2_ALL_TEAMS;
	}
	
	Game_DisplayRawVoteFail(reason, team, client);
}
*/
// native NativeVotes_GetTarget(Handle:vote);
public int Native_GetTarget(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	int target = Data_GetTarget(vote);
	
	if (target == 0)
	{
		// No target was set, return -1
		return -1;
	}
		
	return GetClientOfUserId(target);
}

// native NativeVotes_GetTargetSteam(Handle:vote, String:buffer[], maxlength);
public int Native_GetTargetSteam(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	int size = GetNativeCell(3);
	char[] steamId = new char[size];
	GetNativeString(2, steamId, size);
	
	Data_GetTargetSteam(vote, steamId, size);
	return 0;
}

// native NativeVotes_SetTarget(Handle:vote, client, bool:setDetails=true);
public int Native_SetTarget(Handle plugin, int numParams)
{
	NativeVote vote = GetNativeCell(1);
	if (vote == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	int client = GetNativeCell(2);
	
	if (client < 1 || client > MaxClients || !IsClientConnected(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
		return 0;
	}
	
	int userid;
	char steamId[20];
	
	if (client <= 0)
	{
		userid = 0;
		steamId = "";
	}
	else
	{
		userid = GetClientUserId(client);
		if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
		{
			steamId = "";
		}
	}

	Data_SetTarget(vote, userid);
	Data_SetTargetSteam(vote, steamId);

	bool changeDetails = GetNativeCell(3);
	if (changeDetails)
	{
		char name[MAX_NAME_LENGTH+1];
		if (client > 0)
		{
			GetClientName(client, name, MAX_NAME_LENGTH);
			Data_SetDetails(vote, name);
		}
		else
		{
			Data_SetDetails(vote, "");
		}
	}
	return 0;
}

// native bool:NativeVotes_AreVoteCommandsSupported();
public int Native_AreVoteCommandsSupported(Handle plugin, int numParams)
{
	return Game_AreVoteCommandsSupported();
}

// native NativeVotes_RegisterVoteCommand(NativeVotesOverride:overrideType, NativeVotes_CallVoteHandler:callHandler, NativeVotes_CallVoteVisCheck:visHandler=INVALID_FUNCTION);
public int Native_RegisterVoteCommand(Handle plugin, int numParams)
{
	NativeVotesOverride overrideType = GetNativeCell(1);
	Function callVoteHandler = GetNativeFunction(2);
	Function visHandler = GetNativeFunction(3);

	// This tosses an error so use the simplified version
	//	if (view_as<int>(overrideType) > sizeof(g_CallVotes))
	if (overrideType > NativeVotesOverride_Count)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Override Type %d is not supported by this version of NativeVotes", overrideType);
		return 0;
	}
	
	if (callVoteHandler == INVALID_FUNCTION)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "CallVoteHandler function was invalid");
		return 0;
	}
	
	AddToForward(g_CallVotes[overrideType].CallVote_Forward, plugin, callVoteHandler);
	
	if (visHandler != INVALID_FUNCTION)
	{
		AddToForward(g_CallVotes[overrideType].CallVote_Vis, plugin, visHandler);
	}
	return 0;
}

// native NativeVotes_UnregisterVoteCommand(NativeVotesOverride:overrideType, NativeVotes_CallVoteHandler:callHandler, NativeVotes_CallVoteVisCheck:visHandler=INVALID_FUNCTION);
public int Native_UnregisterVoteCommand(Handle plugin, int numParams)
{
	NativeVotesOverride overrideType = GetNativeCell(1);
	Function callVoteHandler = GetNativeFunction(2);
	Function visHandler = GetNativeFunction(3);

	if (overrideType > NativeVotesOverride_Count)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Override Type %d is not supported by this version of NativeVotes", overrideType);
		return 0;
	}
	
	if (callVoteHandler == INVALID_FUNCTION)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "CallVoteHandler function was invalid");
		return 0;
	}
	
	RemoveFromForward(g_CallVotes[overrideType].CallVote_Forward, plugin, callVoteHandler);

	if (visHandler != INVALID_FUNCTION)
	{
		RemoveFromForward(g_CallVotes[overrideType].CallVote_Vis, plugin, visHandler);
	}
	return 0;
}

// native NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFailType:reason, time=0);
public int Native_DisplayCallVoteFail(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients || !IsClientConnected(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
		return 0;
	}
	
	NativeVotesCallFailType reason = GetNativeCell(2);
	
	int time = GetNativeCell(3);
	
	Game_DisplayCallVoteFail(client, reason, time);
	return 0;
}

// native Action:NativeVotes_RedrawVoteTitle(const String:text[]);
public int Native_RedrawVoteTitle(Handle plugin, int numParams)
{
	if (!g_curDisplayClient)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "You can only call this once from a MenuAction_Display callback");
	}
	
	NativeVotesType voteType = Data_GetType(g_hCurVote);
	
	if (voteType != NativeVotesType_Custom_Mult && voteType != NativeVotesType_Custom_YesNo)
	{
		return view_as<int>(Plugin_Continue);
	}
	
	GetNativeString(1, g_newMenuTitle, TRANSLATION_LENGTH);
	return view_as<int>(Plugin_Changed);
}

// native Action:NativeVotes_RedrawVoteItem(const String:text[]);
public int Native_RedrawVoteItem(Handle plugin, int numParams)
{
	if (!g_curItemClient)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "You can only call this once from a MenuAction_DisplayItem callback");
	}
	
	if (Game_GetMaxItems() == L4DL4D2_COUNT)
	{
		return view_as<int>(Plugin_Continue);
	}
	
	GetNativeString(1, g_newMenuItem, TRANSLATION_LENGTH);
	return view_as<int>(Plugin_Changed);
}
