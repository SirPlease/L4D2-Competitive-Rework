/**
 * vim: set ts=4 :
 * =============================================================================
 * Sniff L4D; L4D2; TF2; and CS:GO vote events, user messages, and commands
 *
 * NativeVotes (C) 2011-2014 Ross Bemrose (Powerlord). All rights reserved.
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

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define LOGFILE "vote_diagnostics.txt"

#pragma newdecls required

EngineVersion g_EngineVersion = Engine_Unknown;

int g_VoteController = -1;

#define MAX_ARG_SIZE 65

#define DELAY 6.0

public Plugin myinfo = 
{
	name = "L4D,L4D2,TF2,CS:GO Vote Sniffer",
	author = "Powerlord",
	description = "Sniff voting commands, events, and usermessages",
	version = "1.2.5",
	url = "http://www.sourcemod.net/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!Game_IsGameSupported())
	{
		strcopy(error, err_max, "Unsupported game");
		return APLRes_Failure;
	}

	if (!late)
	{
		switch (g_EngineVersion)
		{
			case Engine_Left4Dead, Engine_Left4Dead2:
			{
				CreateTimer(30.0, L4DL4D2_LogControllerValues, _, TIMER_FLAG_NO_MAPCHANGE);
			}
			
			case Engine_CSGO, Engine_TF2, Engine_SDK2013, Engine_Insurgency:
			{
				CreateTimer(30.0, TF2CSGO_LogControllerValues, _, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return APLRes_Success;
}

bool CheckVoteController()
{
	int entity = -1;
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

bool Game_IsGameSupported()
{
	g_EngineVersion = GetEngineVersion();
	
	switch (g_EngineVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2, Engine_CSGO, Engine_TF2, Engine_SDK2013, Engine_Insurgency:
		{
			return true;
		}
	}
	
	return false;
}

public void OnPluginStart()
{
	switch (g_EngineVersion)
	{
		case Engine_Left4Dead:
		{
			HookEventEx("vote_changed", L4DL4D2_EventVoteChanged);
			HookEventEx("vote_ended", L4D_EventVoteEnded);
			HookEventEx("vote_started", L4D_EventVoteStarted);
			HookEventEx("vote_passed", L4D_EventVotePassed);
			HookEventEx("vote_failed", L4D_EventVoteFailed);
			HookEventEx("vote_cast_yes", L4D_EventVoteYes);
			HookEventEx("vote_cast_no", L4D_EventVoteNo);
			
			HookUserMessage(GetUserMessageId("VoteRegistered"), L4DL4D2_MessageVoteRegistered);
			HookUserMessage(GetUserMessageId("CallVoteFailed"), L4DL4D2_MessageCallVoteFailed);
		}
		
		case Engine_Left4Dead2:
		{
			HookEventEx("vote_changed", L4DL4D2_EventVoteChanged);
			
			HookUserMessage(GetUserMessageId("VoteRegistered"), L4DL4D2_MessageVoteRegistered);
			HookUserMessage(GetUserMessageId("VoteStart"), L4D2_MessageVoteStart);
			HookUserMessage(GetUserMessageId("VotePass"), L4D2_MessageVotePass);
			HookUserMessage(GetUserMessageId("VoteFail"), L4D2_MessageVoteFail);
			HookUserMessage(GetUserMessageId("CallVoteFailed"), L4DL4D2_MessageCallVoteFailed);
		}
		
		case Engine_CSGO, Engine_TF2, Engine_SDK2013, Engine_Insurgency:
		{
			HookEventEx("vote_cast", TF2CSGO_EventVoteCast);
			HookEventEx("vote_options", TF2CSGO_EventVoteOptions);
			
			if (GetUserMessageType() == UM_Protobuf)
			{
				HookUserMessage(GetUserMessageId("VoteSetup"), CSGO_MessageVoteSetup);
				HookUserMessage(GetUserMessageId("VoteStart"), CSGO_MessageVoteStart);
				HookUserMessage(GetUserMessageId("VotePass"), CSGO_MessageVotePass);
				HookUserMessage(GetUserMessageId("VoteFailed"), CSGO_MessageVoteFail);
				HookUserMessage(GetUserMessageId("CallVoteFailed"), CSGO_MessageCallVoteFailed);
			}
			else
			{
				HookUserMessage(GetUserMessageId("VoteSetup"), TF2_MessageVoteSetup);
				HookUserMessage(GetUserMessageId("VoteStart"), TF2_MessageVoteStart);
				HookUserMessage(GetUserMessageId("VotePass"), TF2_MessageVotePass);
				HookUserMessage(GetUserMessageId("VoteFailed"), TF2_MessageVoteFail);
				HookUserMessage(GetUserMessageId("CallVoteFailed"), TF2_MessageCallVoteFailed);
			}
		}
	}
	
	AddCommandListener(CommandVote, "vote");
	AddCommandListener(CommandCallVote, "callvote");
	
	char gameName[64];
	GetGameFolderName(gameName, sizeof(gameName));
	
	LogToFile(LOGFILE, "Game: %s", gameName);
}

/*
"vote_changed"
{
		"yesVotes"              "byte"
		"noVotes"               "byte"
		"potentialVotes"        "byte"
}
*/
public void L4DL4D2_EventVoteChanged(Event event, const char[] name, bool dontBroadcast)
{
	int yesVotes = event.GetInt("yesVotes");
	int noVotes = event.GetInt("noVotes");
	int potentialVotes = event.GetInt("potentialVotes");
	LogMessage("Vote Changed event: yesVotes: %d, noVotes: %d, potentialVotes: %d",
		yesVotes, noVotes, potentialVotes);
	
}

/*
VoteRegistered Structure
	- Byte      Choice voted for, 0 = No, 1 = Yes

*/  
public Action L4DL4D2_MessageVoteRegistered(UserMsg msg_id, BfRead message, const int[] players, int playersNum, bool reliable, bool init)
{
	int choice = BfReadByte(message);
	
	LogToFile(LOGFILE, "VoteRegistered Usermessage: choice: %d", choice);
	return Plugin_Continue;
}

/*
CallVoteFailed
    - Byte		Failure reason code (1-2, 5-15)
    - Short		Time until new vote allowed for code 2

message CCSUsrMsg_CallVoteFailed
{
	optional int32 reason = 1;
	optional int32 time = 2;
}
*/
public Action L4DL4D2_MessageCallVoteFailed(UserMsg msg_id, BfRead message, const int[] players, int playersNum, bool reliable, bool init)
{
	int reason;
	int time;
	
	reason = BfReadByte(message);
	
	LogToFile(LOGFILE, "CallVoteFailed Usermessage: reason: %d", reason, time);
	return Plugin_Continue;
}

/*
 "vote_started"
{
		"issue"                 "string"
		"param1"                "string"
		"team"                  "byte"
		"initiator"             "long" // entity id of the player who initiated the vote
}
*/
public void L4D_EventVoteStarted(Event event, const char[] name, bool dontBroadcast)
{
	char issue[MAX_ARG_SIZE];
	char param1[MAX_ARG_SIZE];
	event.GetString("issue", issue, sizeof(issue));
	event.GetString("param1", param1, sizeof(param1));
	int team = event.GetInt("team");
	int initiator = event.GetInt("initiator");
	LogToFile(LOGFILE, "Vote Start Event: issue: \"%s\", param1: \"%s\", team: %d, initiator: %d", issue, param1, team, initiator);
	
	if (CheckVoteController())
	{
		LogToFile(LOGFILE, "Active Index for issue %s: %d", issue, GetEntProp(g_VoteController, Prop_Send, "m_activeIssueIndex"));
	}
}

/*
"vote_ended"
{
}
*/
public void L4D_EventVoteEnded(Event event, const char[] name, bool dontBroadcast)
{
	LogToFile(LOGFILE, "Vote Ended Event");
	
	CreateTimer(DELAY, L4DL4D2_LogControllerValues, _, TIMER_FLAG_NO_MAPCHANGE);
}

/*
"vote_passed"
{
		"details"               "string"
		"param1"                "string"
		"team"                  "byte"
}
*/
public void L4D_EventVotePassed(Event event, const char[] name, bool dontBroadcast)
{
	char details[MAX_ARG_SIZE];
	char param1[MAX_ARG_SIZE];
	event.GetString("details", details, sizeof(details));
	event.GetString("param1", param1, sizeof(param1));
	int team = event.GetInt("team");
	LogToFile(LOGFILE, "Vote Passed event: details: %s, param1: %s, team: %d", details, param1, team);
}

/*
"vote_failed"
{
		"team"                  "byte"
}
*/
public void L4D_EventVoteFailed(Event event, const char[] name, bool dontBroadcast)
{
	int team = event.GetInt("team");
	LogToFile(LOGFILE, "Vote Failed event: team: %d", team);
}

/*
"vote_cast_yes"
{
		"team"                  "byte"
		"entityid"              "long"  // entity id of the voter
}
*/
public void L4D_EventVoteYes(Event event, const char[] name, bool dontBroadcast)
{
	int team = event.GetInt("team");
	int client = event.GetInt("entityid");
	LogToFile(LOGFILE, "Vote Cast Yes event: team: %d, client: %N", team, client);
}

/*
"vote_cast_no"
{
		"team"                  "byte"
		"entityid"              "long"  // entity id of the voter
}
*/
public void L4D_EventVoteNo(Event event, const char[] name, bool dontBroadcast)
{
	int team = event.GetInt("team");
	int client = event.GetInt("entityid");
	LogToFile(LOGFILE, "Vote Cast No event: team: %d, client: %N", team, client);
}

/*
VoteStart Structure
	- Byte      Team index or -1 for all
	- Byte      Initiator client index (or 99 for Server?)
	- String    Vote issue phrase
	- String    Vote issue phrase argument
	- String    Initiator name

*/
public Action L4D2_MessageVoteStart(UserMsg msg_id, BfRead message, const int[] players, int playersNum, bool reliable, bool init)
{
	char issue[MAX_ARG_SIZE];
	char param1[MAX_ARG_SIZE];
	char initiatorName[MAX_NAME_LENGTH];

	int team = message.ReadByte();
	int initiator = message.ReadByte();
	
	message.ReadString(issue, MAX_ARG_SIZE);
	message.ReadString(param1, MAX_ARG_SIZE);
	message.ReadString(initiatorName, MAX_NAME_LENGTH);

	LogToFile(LOGFILE, "VoteStart Usermessage: team: %d, initiator: %d, issue: %s, param1: %s, player count: %d, initiatorName: %s", team, initiator, issue, param1, playersNum, initiatorName);
	if (CheckVoteController())
	{
		LogToFile(LOGFILE, "Active Index for issue %s: %d", issue, GetEntProp(g_VoteController, Prop_Send, "m_activeIssueIndex"));
	}

	return Plugin_Continue;
}

/*
VotePass Structure
	- Byte      Team index or -1 for all
	- String    Vote issue pass phrase
	- String    Vote issue pass phrase argument

*/
public Action L4D2_MessageVotePass(UserMsg msg_id, BfRead message, const int[] players, int playersNum, bool reliable, bool init)
{
	char issue[MAX_ARG_SIZE];
	char param1[MAX_ARG_SIZE];
	int team = message.ReadByte();
	
	message.ReadString(issue, MAX_ARG_SIZE);
	message.ReadString(param1, MAX_ARG_SIZE);
	
	LogToFile(LOGFILE, "VotePass Usermessage: team: %d, issue: %s, param1: %s", team, issue, param1);

	CreateTimer(DELAY, L4DL4D2_LogControllerValues, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

/*
VoteFail Structure
	- Byte      Team index or -1 for all

*/  
public Action L4D2_MessageVoteFail(UserMsg msg_id, BfRead message, const int[] players, int playersNum, bool reliable, bool init)
{
	int team = message.ReadByte();
	
	LogToFile(LOGFILE, "VoteFail Usermessage: team: %d", team);

	CreateTimer(DELAY, L4DL4D2_LogControllerValues, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

/*
"vote_cast"
{
		"vote_option"   "byte"  // which option the player voted on
		"team"                  "short"
		"entityid"              "long"  // entity id of the voter
}
*/
public void TF2CSGO_EventVoteCast(Event event, const char[] name, bool dontBroadcast)
{
	int vote_option = event.GetInt("vote_option");
	int team = event.GetInt("team");
	int entityid = event.GetInt("entityid");
	LogToFile(LOGFILE, "Vote Cast event: vote_option: %d, team: %d, client: %N", vote_option, team, entityid);
}

/*
"vote_options"
{
		"count"                 "byte"  // Number of options - up to MAX_VOTE_OPTIONS
		"option1"               "string"
		"option2"               "string"
		"option3"               "string"
		"option4"               "string"
		"option5"               "string"
}
*/
public void TF2CSGO_EventVoteOptions(Event event, const char[] name, bool dontBroadcast)
{
	char option1[MAX_ARG_SIZE];
	char option2[MAX_ARG_SIZE];
	char option3[MAX_ARG_SIZE];
	char option4[MAX_ARG_SIZE];
	char option5[MAX_ARG_SIZE];
	
	int count = event.GetInt("count");
	event.GetString("option1", option1, sizeof(option1));
	event.GetString("option2", option2, sizeof(option2));
	event.GetString("option3", option3, sizeof(option3));
	event.GetString("option4", option4, sizeof(option4));
	event.GetString("option5", option5, sizeof(option5));
	LogToFile(LOGFILE, "Vote Options event: count: %d, option1: %s, option2: %s, option3: %s, option4: %s, option5: %s", 
		count, option1, option2, option3, option4, option5);
}

/* 
message CCSUsrMsg_VoteSetup
{
	repeated string potential_issues = 1;
}	 
*/
public Action CSGO_MessageVoteSetup(UserMsg msg_id, Protobuf message, const int[] players, int playersNum, bool reliable, bool init)
{
	char options[2049];
	int count = message.GetRepeatedFieldCount("potential_issues");
	for(int i = 0; i < count; i++)
	{
		char option[MAX_ARG_SIZE];
		message.ReadString("potential_issues", option, MAX_ARG_SIZE, i);
		StrCat(options, sizeof(options), option);
		StrCat(options, sizeof(options), " ");
	}

	LogToFile(LOGFILE, "VoteSetup Usermessage: count: %d, options: %s", count, options);
	
	return Plugin_Continue;
}

/*
VoteSetup
	- Byte		Option count
	* issue		multiple issues matching the number in the first byte

issue
	- String		Vote name
	- String		Vote translation string
	- Byte		Whether a vote is enabled or not.
*/
public Action TF2_MessageVoteSetup(UserMsg msg_id, BfRead message, const int[] players, int playersNum, bool reliable, bool init)
{
	char options[2049];
	int count = message.ReadByte();
	for (int i = 0; i < count; i++)
	{
		char option[MAX_ARG_SIZE*2+1];
		char potential_issue[MAX_ARG_SIZE];
		char translation[MAX_ARG_SIZE];
		message.ReadString(potential_issue, MAX_ARG_SIZE);
		message.ReadString(translation, MAX_ARG_SIZE);
		
		int enabled = message.ReadByte();
		Format(option, sizeof(option), "(%s, %s, %d) ", potential_issue, translation, enabled);
		
		StrCat(options, sizeof(options), option);
	}

	LogToFile(LOGFILE, "VoteSetup Usermessage: count: %d, options: %s", count, options);
	
	return Plugin_Continue;
}

/*
message CCSUsrMsg_VoteStart
{
	optional int32 team = 1;
	optional int32 ent_idx = 2;
	optional int32 vote_type = 3;
	optional string disp_str = 4;
	optional string details_str = 5;
	optional string other_team_str = 6;
	optional bool is_yes_no_vote = 7;

}
*/
public Action CSGO_MessageVoteStart(UserMsg msg_id, Protobuf message, const int[] players, int playersNum, bool reliable, bool init)
{
	char issue[MAX_ARG_SIZE];
	char otherTeamIssue[MAX_ARG_SIZE];
	char param1[MAX_ARG_SIZE];
	int team;
	int initiator;
	bool yesNo;
	int voteType;
	
	team = message.ReadInt("team");
	initiator = message.ReadInt("ent_idx");
	message.ReadString("disp_str", issue, MAX_ARG_SIZE);
	message.ReadString("details_str", param1, MAX_ARG_SIZE);
	yesNo = message.ReadBool("is_yes_no_vote");
	message.ReadString("other_team_str", otherTeamIssue, MAX_ARG_SIZE);
	voteType = message.ReadInt("vote_type");

	LogToFile(LOGFILE, "VoteStart Usermessage: team: %d, initiator: %d, issue: %s, otherTeamIssue: %s, param1: %s, yesNo: %d, player count: %d, voteType: %d", team, initiator, issue, otherTeamIssue, param1, yesNo, playersNum, voteType);
	
	CreateTimer(0.0, TF2CSGO_LogControllerValues, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

/*
VoteStart Structure
	- Byte      Team index or -1 for all
	- Byte      Initiator client index or 99 for Server
	- String    Vote issue phrase
	- String    Vote issue phrase argument
	- Bool      false for Yes/No, true for Multiple choice
*/
public Action TF2_MessageVoteStart(UserMsg msg_id, BfRead message, const int[] players, int playersNum, bool reliable, bool init)
{
	char issue[MAX_ARG_SIZE];
	char param1[MAX_ARG_SIZE];
	int team;
	int initiator;
	bool yesNo;
	
	team = message.ReadByte();
	initiator = message.ReadByte();
	message.ReadString(issue, MAX_ARG_SIZE);
	message.ReadString(param1, MAX_ARG_SIZE);
	yesNo = message.ReadBool();

	LogToFile(LOGFILE, "VoteStart Usermessage: team: %d, initiator: %d, issue: %s, param1: %s, yesNo: %d, player count: %d", team, initiator, issue, param1, yesNo, playersNum);
	
	CreateTimer(0.0, TF2CSGO_LogControllerValues, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

/*
message CCSUsrMsg_VotePass
{
	optional int32 team = 1;
	optional int32 vote_type = 2;
	optional string disp_str= 3;
	optional string details_str = 4;
}
*/
public Action CSGO_MessageVotePass(UserMsg msg_id, Protobuf message, const int[] players, int playersNum, bool reliable, bool init)
{
	char issue[MAX_ARG_SIZE];
	char param1[MAX_ARG_SIZE];
	int team;
	int voteType;

	team = message.ReadInt("team");
	message.ReadString("disp_str", issue, MAX_ARG_SIZE);
	message.ReadString("details_str", param1, MAX_ARG_SIZE);
	voteType = message.ReadInt("vote_type");
	
	LogToFile(LOGFILE, "VotePass Usermessage: team: %d, issue: %s, param1: %s, voteType: %d", team, issue, param1, voteType);
	
	CreateTimer(DELAY, TF2CSGO_LogControllerValues, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

/*
VotePass Structure
	- Byte      Team index or -1 for all
	- String    Vote issue pass phrase
	- String    Vote issue pass phrase argument
*/
public Action TF2_MessageVotePass(UserMsg msg_id, BfRead message, const int[] players, int playersNum, bool reliable, bool init)
{
	char issue[MAX_ARG_SIZE];
	char param1[MAX_ARG_SIZE];
	int team;

	team = message.ReadByte();
	message.ReadString(issue, MAX_ARG_SIZE);
	message.ReadString(param1, MAX_ARG_SIZE);
	
	LogToFile(LOGFILE, "VotePass Usermessage: team: %d, issue: %s, param1: %s", team, issue, param1);
	
	CreateTimer(DELAY, TF2CSGO_LogControllerValues, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

/*
message CCSUsrMsg_VoteFailed
{
	optional int32 team = 1;
	optional int32 reason = 2;	
}
*/  
public Action CSGO_MessageVoteFail(UserMsg msg_id, Protobuf message, const int[] players, int playersNum, bool reliable, bool init)
{
	int team = message.ReadInt("team");
	int reason = message.ReadInt("reason");
	
	LogToFile(LOGFILE, "VoteFail Usermessage: team: %d, reason: %d", team, reason);
	
	CreateTimer(DELAY, TF2CSGO_LogControllerValues, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

/*
VoteFailed Structure
	- Byte      Team index or -1 for all
	- Byte      Failure reason code (0, 3-4)
*/
public Action TF2_MessageVoteFail(UserMsg msg_id, BfRead message, const int[] players, int playersNum, bool reliable, bool init)
{
	int team = message.ReadByte();
	int reason = message.ReadByte();
	
	LogToFile(LOGFILE, "VoteFail Usermessage: team: %d, reason: %d", team, reason);
	
	CreateTimer(DELAY, TF2CSGO_LogControllerValues, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action TF2CSGO_LogControllerValues(Handle timer)
{
	if (!CheckVoteController())
	{
		return Plugin_Continue;
	}
	
	int team = GetEntProp(g_VoteController, Prop_Send, "m_iOnlyTeamToVote");
	int activeIssue = GetEntProp(g_VoteController, Prop_Send, "m_iActiveIssueIndex");
	int potentialVotes = GetEntProp(g_VoteController, Prop_Send, "m_nPotentialVotes");
	bool isYesNo = view_as<bool>(GetEntProp(g_VoteController, Prop_Send, "m_bIsYesNoVote"));
	int voteCounts[5];
	for (int i = 0; i < 5; ++i)
	{
		voteCounts[i] = GetEntProp(g_VoteController, Prop_Send, "m_nVoteOptionCount", _, i);
	}
	
	LogToFile(LOGFILE, "Vote Controller, issue: %d, team: %d, potentialVotes: %d, yesNo: %d, count1: %d, count2: %d, count3: %d, count4: %d, count5: %d",
	activeIssue, team, potentialVotes, isYesNo, voteCounts[0], voteCounts[1], voteCounts[2], voteCounts[3], voteCounts[4]);
	return Plugin_Continue;
}

public Action L4DL4D2_LogControllerValues(Handle timer)
{
	if (!CheckVoteController())
	{
		return Plugin_Continue;
	}
	
	int team = GetEntProp(g_VoteController, Prop_Send, "m_onlyTeamToVote");
	int activeIssue = GetEntProp(g_VoteController, Prop_Send, "m_activeIssueIndex");
	int potentialVotes = GetEntProp(g_VoteController, Prop_Send, "potentialVotes");
	int voteCounts[2];
	voteCounts[0] = GetEntProp(g_VoteController, Prop_Send, "m_votesYes");
	voteCounts[1] = GetEntProp(g_VoteController, Prop_Send, "m_votesNo");
	
	LogToFile(LOGFILE, "Vote Controller, issue: %d, team: %d, potentialVotes: %d, countYes: %d, countNo: %d",
	activeIssue, team, potentialVotes, voteCounts[0], voteCounts[1]);
	return Plugin_Continue;
}

/*
message CCSUsrMsg_CallVoteFailed
{
	optional int32 reason = 1;
	optional int32 time = 2;
}
*/
public Action CSGO_MessageCallVoteFailed(UserMsg msg_id, Protobuf message, const int[] players, int playersNum, bool reliable, bool init)
{
	int reason = message.ReadInt("reason");
	int time = message.ReadInt("time");
	
	LogToFile(LOGFILE, "CallVoteFailed Usermessage: reason: %d, time: %d", reason, time);
	return Plugin_Continue;
}

/*
CallVoteFailed
    - Byte		Failure reason code (1-2, 5-15)
    - Short		Time until new vote allowed for code 2
*/
public Action TF2_MessageCallVoteFailed(UserMsg msg_id, BfRead message, const int[] players, int playersNum, bool reliable, bool init)
{
	int reason = message.ReadByte();
	int time = message.ReadShort();
	
	LogToFile(LOGFILE, "CallVoteFailed Usermessage: reason: %d, time: %d", reason, time);
	return Plugin_Continue;
}

/*
	This is likely a client-side event as it never produced any values.
	
	"endmatch_mapvote_selecting_map"
	{
		"count"			"byte"	// Number of "ties"
		"slot1"			"byte"
		"slot2"			"byte"
		"slot3"			"byte"
		"slot4"			"byte"
		"slot5"			"byte"
		"slot6"			"byte"
		"slot7"			"byte"
		"slot8"			"byte"
		"slot9"			"byte"
		"slot10"		"byte"
	}
*/
/*
public void CSGO_EventMapVote(Event event, const char[] name, bool dontBroadcast)
{
	int count = event.GetInt("count");
	int slot1 = event.GetInt("slot1");
	int slot2 = event.GetInt("slot2");
	int slot3 = event.GetInt("slot3");
	int slot4 = event.GetInt("slot4");
	int slot5 = event.GetInt("slot5");
	int slot6 = event.GetInt("slot6");
	int slot7 = event.GetInt("slot7");
	int slot8 = event.GetInt("slot8");
	int slot9 = event.GetInt("slot9");
	int slot10 = event.GetInt("slot10");
	
	LogToFile(LOGFILE, "Endmatch_Mapvote_SelectingMap event: count: %d, slot1: %d, slot2: %d, slot3: %d, slot4: %d, slot5: %d, slot6: %d, slot7: %d, slot8: %d, slot9: %d, slot10: %d ",
	count, slot1, slot2, slot3, slot4, slot5, slot6, slot7, slot8, slot9, slot10);
}
*/

/*
Vote command
    - String		option1 through option5 (for TF2/CS:GO); Yes or No (for L4D/L4D2)
 */
public Action CommandVote(int client, const char[] command, int argc)
{
	char vote[MAX_ARG_SIZE];
	GetCmdArg(1, vote, sizeof(vote));
	
	LogToFile(LOGFILE, "%N used vote command: %s %s", client, command, vote);
	return Plugin_Continue;
}

/*
callvote command
	- String		Vote type (Valid types are sent in the VoteSetup message)
	- String		target (or type - target for Kick)
*/
public Action CommandCallVote(int client, const char[] command, int argc)
{
	char args[255];
	GetCmdArgString(args, sizeof(args));
	
	LogToFile(LOGFILE, "callvote command: client: %N, command: %s", client, args);
	return Plugin_Continue;
}
