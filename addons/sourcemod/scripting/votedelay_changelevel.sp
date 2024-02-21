/**
 * vim: set ts=4 :
 * =============================================================================
 * Vote Delay: Changelevel
 * Delay ChangeLevel and NextLevel votes until X rounds have passed
 *
 * Vote Delay: Changelevel (C)2014 Powerlord (Ross Bemrose).  All rights reserved.
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

#define VERSION "1.0.1"

#define VOTE_STRING_SIZE					32

new Handle:g_Cvar_Enabled;
new Handle:g_Cvar_FullRounds;
new Handle:g_Cvar_Rounds;

new g_VoteController = -1;
new g_bUserBuf = false;

// Stolen from NativeVotes
enum NativeVotesCallFailType
{
	NativeVotesCallFail_Generic = 0,			/**< Generic fail. */
	NativeVotesCallFail_Loading = 1,			/**< L4D/L4D2: Players are still loading. */
	NativeVotesCallFail_Recent = 2,				/**< TF2/CS:GO: You can't call another vote yet: Argument is seconds until you can call another vote. */
	NativeVotesCallFail_Disabled = 5,			/**< TF2/CS:GO: Server has disabled that issue. */
	NativeVotesCallFail_MapNotFound = 6,		/**< TF2/CS:GO: Server does not have that map. */
	NativeVotesCallFail_SpecifyMap = 7,			/**< TF2/CS:GO: You must specify a map. */
	NativeVotesCallFail_Failed = 8,				/**< TF2/CS:GO: This vote failed recently: Argument is seconds until this vote can be called again. */
	NativeVotesCallFail_WrongTeam = 9,			/**< TF2/CS:GO: Team can't call this vote. */
	NativeVotesCallFail_Waiting = 10,			/**< TF2/CS:GO: Vote can't be called during Waiting For Players. */
	NativeVotesCallFail_PlayerNotFound = 11,	/**< TF2/CS:GO: Player to kick can't be found. Buggy in TF2. */
	NativeVotesCallFail_Unknown = 11,
	NativeVotesCallFail_CantKickAdmin = 12,		/**< TF2/CS:GO: Can't kick server admin. */
	NativeVotesCallFail_ScramblePending = 13,	/**< TF2/CS:GO: Team Scramble is pending. */
	NativeVotesCallFail_Spectators = 14,		/**< TF2/CS:GO: Spectators aren't allowed to call votes. */
	NativeVotesCallFail_LevelSet = 15,			/**< TF2: Next level already set. */
	NativeVotesCallFail_Warmup = 15,			/**< CSGO: Vote can't be called during Warmup */
	NativeVotesCallFail_MapNotValid = 16,		/**< TF2: Map is not in MapCycle. */
	NativeVotesCallFail_KickTime = 17,			/**< TF2: Cannot kick at this time: Argument is seconds until you can call another kick vote. */
	NativeVotesCallFail_KickDuringRound = 18,	/**< TF2: Cannot kick during a round. */
};

public Plugin:myinfo = {
	name			= "Vote Delay: Changelevel",
	author			= "Powerlord",
	description		= "Delay vote change until after X rounds have gone by",
	version			= VERSION,
	url				= ""
};

new roundCount = 1;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new EngineVersion:engine = GetEngineVersion();
	
	if (engine != Engine_TF2 && engine != Engine_CSGO)
	{
		strcopy(error, err_max, "Only works on TF2 and CS:GO");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("votedelay_changelevel_version", VERSION, "Vote Delay: Changelevel version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	g_Cvar_Enabled = CreateConVar("votedelay_changelevel_enable", "1", "Enable Vote Delay: Changelevel?", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_Cvar_FullRounds = CreateConVar("votedelay_changelevel_fullrounds", "1", "Full rounds only? Only applies to TF2.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_Rounds = CreateConVar("votedelay_changelevel_rounds", "4", "During what round should votes become available?", FCVAR_NONE, true, 0.0, true, 10.0);
	
	g_bUserBuf = (GetUserMessageType() == UM_Protobuf);
	
	AddCommandListener(Cmd_CallVote, "callvote");
	HookEvent("round_end", Event_RoundEnd);
	HookEventEx("teamplay_round_win", Event_RoundWin);

	AutoExecConfig(true, "votedelay_changelevel");
}

public OnMapStart()
{
	roundCount = 1;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GameRules_GetProp("m_bWarmupPeriod"))
	{
		roundCount++;
	}
}

public Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_Cvar_FullRounds) && !GetEventInt(event, "full_round"))
	{
		return;
	}
	
	roundCount++;
}

public Action:Cmd_CallVote(client, const String:command[], argc)
{
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	if (!GetConVarBool(g_Cvar_Enabled) || argc == 0 || IsNativeVoteInProgress())
	{
		return Plugin_Continue;
	}
	
	decl String:voteCommand[VOTE_STRING_SIZE];
	GetCmdArg(1, voteCommand, VOTE_STRING_SIZE);
	
	if (!StrEqual(voteCommand, "ChangeLevel", false) && !StrEqual(voteCommand, "NextLevel", false))
	{
		return Plugin_Continue;
	}
	
	new voteRound = GetConVarInt(g_Cvar_Rounds);
	
	if (roundCount >= voteRound)
	{
		return Plugin_Continue;
	}
	
	new ReplySource:source = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	// For lack of a better reason
	TF2CSGO_CallVoteFail(client, NativeVotesCallFail_Disabled);
	ReplyToCommand(client, "%s vote is disabled until after round %d, current round is %d", voteCommand, voteRound, roundCount);
	
	SetCmdReplySource(source);
	
	return Plugin_Stop;
}

bool:IsNativeVoteInProgress()
{
	if (CheckVoteController())
	{
		new activeIndex = GetEntProp(g_VoteController, Prop_Send, "m_iActiveIssueIndex");
		if (activeIndex > -1)
		{
			return true;
		}
	}
	
	return false;
}

bool:CheckVoteController()
{
	new entity = -1;
	if (g_VoteController != -1)
	{
		entity = EntRefToEntIndex(g_VoteController);
	}
	
	if (entity == -1)
	{
		entity = FindEntityByClassname(-1, "vote_controller");
		if (entity == -1)
		{
			LogError("Could not find Vote Controller.");
			return false;
		}
		
		g_VoteController = EntIndexToEntRef(entity);
	}
	return true;
}

TF2CSGO_CallVoteFail(client, NativeVotesCallFailType:reason, time=0)
{
	new Handle:callVoteFail = StartMessageOne("CallVoteFailed", client, USERMSG_RELIABLE);

	if(g_bUserBuf)
	{
		PbSetInt(callVoteFail, "reason", _:reason);
		PbSetInt(callVoteFail, "time", time);
	}
	else
	{
		BfWriteByte(callVoteFail, _:reason);
		BfWriteShort(callVoteFail, time);
	}
	EndMessage();
}

