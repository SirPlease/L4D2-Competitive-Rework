#define PLUGIN_VERSION		"1.3"

#include <sourcemod>
#include <sdktools>

#define L4D_VOTE_TEAM_ALL			-1
#define L4D2_VOTE_TEAM_ALL			255

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Vote Poll Fix",
	author = "raziEiL [disawar1]",
	description = "Changes number of players eligible to vote",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (late)
		VPF_PrepareToFindVoteEnt();

	return APLRes_Success;
}

static g_iVoteEntity = INVALID_ENT_REFERENCE, bool:g_bVotePoolFixTriggered, g_iVoteTeamAll;

public OnPluginStart()
{
	CreateConVar("l4d_votepoll_fix_version", PLUGIN_VERSION, "Vote Poll Fix plugin version.", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);

	decl String:sGameFolder[32];
	GetGameFolderName(sGameFolder, 32);

	if (StrEqual(sGameFolder, "left4dead")){

		g_iVoteTeamAll = L4D_VOTE_TEAM_ALL
		HookEvent("vote_started", VPF_ev_VoteStarted, EventHookMode_Pre);
	}
	else {

		g_iVoteTeamAll = L4D2_VOTE_TEAM_ALL
		HookUserMessage(GetUserMessageId("VoteStart"), VPF_mh_OnVoteStart);
	}

	HookEvent("round_start", VPF_ev_RoundStart, EventHookMode_PostNoCopy);

	AddCommandListener(VPF_cmdh_Vote, "vote");
}

public Action:VPF_cmdh_Vote(client, const String:command[], argc)
{
	if (g_bVotePoolFixTriggered && GetClientTeam(client) == 1)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action:VPF_ev_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	VPF_PrepareToFindVoteEnt();
}

public Action:VPF_ev_VoteStarted(Handle:event, const String:name[], bool:dontBroadcast)
{
	VPF_PrepareToFix(GetEventInt(event, "team"), GetEventInt(event, "initiator"));
}

public Action:VPF_mh_OnVoteStart(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new team = BfReadByte(bf);
	new client = BfReadByte(bf);

	VPF_PrepareToFix(team, client);
}

VPF_PrepareToFix(team, client)
{
	decl iPolls;
	if (IsValidInitiator(client) && IsValidVoteEnt() && IsAnyOneSpectator() && ((team == g_iVoteTeamAll && (iPolls = GetTotalPlayers())) || (iPolls = GetTeammateCount(team)))){

		g_bVotePoolFixTriggered = true;
		SetEntProp(g_iVoteEntity, Prop_Send, "m_potentialVotes", iPolls);
	}
	else
		g_bVotePoolFixTriggered = false;
}

VPF_PrepareToFindVoteEnt()
{
	if (!IsValidVoteEnt())
		CreateTimer(0.5, VPF_t_FindVoteContollerEnt, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:VPF_t_FindVoteContollerEnt(Handle:timer)
{
	g_iVoteEntity = EntIndexToEntRef(FindEntityByClassname(-1, "vote_controller"));
}

GetTotalPlayers()
{
	new players;

	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetClientTeam(i) > 1 && !IsFakeClient(i))
			players++;

	return players;
}

GetTeammateCount(team)
{
	if (team != 2 && team != 3)
		return 0;

	new teammates;

	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i))
			teammates++;

	return teammates;
}

bool:IsValidInitiator(index)
{
	return index > 0 && index <= MaxClients && IsClientInGame(index) && GetClientTeam(index) != 1;
}

bool:IsValidVoteEnt()
{
	return EntRefToEntIndex(g_iVoteEntity) != INVALID_ENT_REFERENCE;
}

bool:IsAnyOneSpectator()
{
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetClientTeam(i) == 1 && !IsFakeClient(i))
			return true;

	return false;
}
