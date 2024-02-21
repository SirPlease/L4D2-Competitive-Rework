/**
 * vim: set ts=4 :
 * =============================================================================
 * CSGO VoteStart Multiple Test
 * Test CS:GO Start Vote Panel
 * 
 * CSGO VoteStart Multiple Test(C) 2014 Ross Bemrose (Powerlord). All rights reserved.
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

#define VERSION "1.1"

new bool:g_bVoteActive = false;

public Plugin:myinfo = 
{
	name = "CSGO VoteStart Multiple Test",
	author = "Powerlord",
	description = "Test CS:GO VoteStart Panels",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=208008"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		strcopy(error, err_max, "Only runs on CS:GO");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("core.phrases");
	
	RegAdminCmd("votemulti", Cmd_VoteMulti, ADMFLAG_VOTE, "Multiple Choice Vote");
	RegAdminCmd("voteyesno", Cmd_VoteYesNo, ADMFLAG_VOTE, "YesNo Choice Vote");
	RegAdminCmd("voteclear", Cmd_VoteFail, ADMFLAG_VOTE, "Multiple Choice Vote");
	
	AddCommandListener(Listener_Vote, "vote");
}

public Action:Cmd_VoteMulti(client, args)
{
	new entity = FindEntityByClassname(-1, "vote_controller");
	if (entity > -1)
	{
		SetEntProp(entity, Prop_Send, "m_bIsYesNoVote", false);
		//SetEntProp(entity, Prop_Send, "m_iActiveIssueIndex", 3);
		SetEntProp(entity, Prop_Send, "m_iOnlyTeamToVote", -1);
		for (new i = 0; i < 5; i++)
		{
			SetEntProp(entity, Prop_Send, "m_nVoteOptionCount", 0, _, i);
		}
	}
	
	new Handle:optionsEvent = CreateEvent("vote_options");
	
	SetEventString(optionsEvent, "option1", "de_dust");
	SetEventString(optionsEvent, "option2", "de_dust2");
	SetEventString(optionsEvent, "option3", "cs_italy");
	SetEventString(optionsEvent, "option4", "de_sugarcane");
	SetEventString(optionsEvent, "option5", "ar_shoots");
	SetEventInt(optionsEvent, "count", 5);
	FireEvent(optionsEvent);
	
	if (entity > -1)
	{
		SetEntProp(entity, Prop_Send, "m_nPotentialVotes", GetClientCount(true));
	}

	LogMessage("Finished setting vote_controller properties.");

	g_bVoteActive = true;
	
	CreateTimer(0.2, Timer_StartMultiVote, GetClientUserId(client));
	return Plugin_Handled;
}

public Action:Timer_StartMultiVote(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client <= 0 && client > MaxClients)
	{
		return Plugin_Continue;
	}
	
	new Handle:voteStart = StartMessageAll("VoteStart", USERMSG_RELIABLE);
	PbSetInt(voteStart, "team", -1);
	PbSetInt(voteStart, "ent_idx", 99);
	PbSetString(voteStart, "disp_str", "#SFUI_vote_nextlevel_choices");
	PbSetString(voteStart, "details_str", "");
	PbSetBool(voteStart, "is_yes_no_vote", false);
	PbSetString(voteStart, "other_team_str", "#SFUI_otherteam_vote_unimplemented");
	PbSetInt(voteStart, "vote_type", 1);
	EndMessage();	
	
	return Plugin_Stop;
}


public Action:Cmd_VoteYesNo(client, args)
{
	new entity = FindEntityByClassname(-1, "vote_controller");
	if (entity > -1)
	{
		SetEntProp(entity, Prop_Send, "m_bIsYesNoVote", true);
		//SetEntProp(entity, Prop_Send, "m_iActiveIssueIndex", 2);
		SetEntProp(entity, Prop_Send, "m_iOnlyTeamToVote", -1);
		for (new i = 0; i < 5; i++)
		{
			SetEntProp(entity, Prop_Send, "m_nVoteOptionCount", 0, _, i);
		}
	}
	
	new Handle:optionsEvent = CreateEvent("vote_options");
	SetEventString(optionsEvent, "option1", "Yes");
	SetEventString(optionsEvent, "option2", "No");
	SetEventString(optionsEvent, "option3", "");
	SetEventString(optionsEvent, "option4", "");
	SetEventString(optionsEvent, "option5", "");
	SetEventInt(optionsEvent, "count", 2);
	FireEvent(optionsEvent);
	
	if (entity > -1)
	{
		SetEntProp(entity, Prop_Send, "m_nPotentialVotes", GetClientCount(true));
	}

	g_bVoteActive = true;
	
	LogMessage("Finished setting vote_controller properties.");

	CreateTimer(0.2, Timer_StartYesNoVote, GetClientUserId(client));
	return Plugin_Handled;
}

public Action:Timer_StartYesNoVote(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client <= 0 && client > MaxClients)
	{
		return Plugin_Continue;
	}
	
	new Handle:voteStart = StartMessageAll("VoteStart", USERMSG_RELIABLE);
	PbSetInt(voteStart, "team", -1);
	PbSetInt(voteStart, "ent_idx", client);
	PbSetString(voteStart, "disp_str", "#SFUI_vote_changelevel");
	PbSetString(voteStart, "details_str", "de_dust2");
	PbSetBool(voteStart, "is_yes_no_vote", true);
	PbSetString(voteStart, "other_team_str", "#SFUI_otherteam_vote_unimplemented");
	PbSetInt(voteStart, "vote_type", 1);
	EndMessage();	
	
	return Plugin_Stop;
}

public Action:Cmd_VoteFail(client, args)
{
	if (g_bVoteActive)
		VoteFail();

	return Plugin_Handled;
}

public Action:Listener_Vote(client, const String:command[], argc)
{
	if (!g_bVoteActive)
	{
		return Plugin_Continue;
	}
	
	new ReplySource:oldSource = SetCmdReplySource(SM_REPLY_TO_CHAT);
	ReplyToCommand(client, "Caught vote.");
	
	VoteFail();
	
	SetCmdReplySource(oldSource);
	return Plugin_Handled;
}

VoteFail()
{
	g_bVoteActive = false;
	new Handle:voteFailed = StartMessageAll("VoteFailed", USERMSG_RELIABLE);
	
	PbSetInt(voteFailed, "team", -1);
	PbSetInt(voteFailed, "reason", 0);
	EndMessage();
	
	CreateTimer(5.0, Timer_ResetData);
}

public Action:Timer_ResetData(Handle:timer)
{
	new entity = FindEntityByClassname(-1, "vote_controller");
	if (entity > -1)
	{
		//SetEntProp(entity, Prop_Send, "m_iActiveIssueIndex", -1);
		for (new i = 0; i < 5; i++)
		{
			SetEntProp(entity, Prop_Send, "m_nVoteOptionCount", 0, _, i);
		}
		SetEntProp(entity, Prop_Send, "m_nPotentialVotes", 0);
		SetEntProp(entity, Prop_Send, "m_iOnlyTeamToVote", -1);
		SetEntProp(entity, Prop_Send, "m_bIsYesNoVote", true);
	}	
}