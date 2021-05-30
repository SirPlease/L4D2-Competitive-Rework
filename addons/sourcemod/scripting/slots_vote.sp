#pragma semicolon 1

#include <sourcemod>
#include <builtinvotes>
#include <colors>

new Handle:g_hVote;
new String:g_sSlots[32];
new Handle:hMaxSlots;
new MaxSlots;

public Plugin:myinfo =
{
	name = "Slots?! Voter",
	description = "Slots Voter",
	author = "Sir",
	version = "",
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_slots", SlotsRequest);
	hMaxSlots = CreateConVar("slots_max_slots", "30", "Maximum amount of slots you wish players to be able to vote for? (DON'T GO HIGHER THAN 30)");
	MaxSlots = GetConVarInt(hMaxSlots);
	HookConVarChange(hMaxSlots, CVarChanged);
}

public Action:SlotsRequest(client, args)
{
	if (!client)
	{
		return Plugin_Handled;
	}
	if (args == 1)
	{
		new String:sSlots[64];
		GetCmdArg(1, sSlots, sizeof(sSlots));
		new Int = StringToInt(sSlots);
		if (Int > MaxSlots)
		{
			CPrintToChat(client, "{blue}[{default}Slots{blue}] {default}You can't limit slots above {olive}%i {default}on this Server", MaxSlots);
		}
		else
		{
			if (GetUserAdmin(client) != INVALID_ADMIN_ID)
			{
				CPrintToChatAll("{blue}[{default}Slots{blue}] {olive}Admin {default}has limited Slots to {blue}%i", Int);
				SetConVarInt(FindConVar("sv_maxplayers"), Int);
			}
			else if (Int < GetConVarInt(FindConVar("survivor_limit")) + GetConVarInt(FindConVar("z_max_player_zombies")))
			{
				CPrintToChat(client, "{blue}[{default}Slots{blue}] {default}You can't limit Slots lower than required Players.");
			}
			else if (StartSlotVote(client, sSlots))
			{
				strcopy(g_sSlots, sizeof(g_sSlots), sSlots);
				FakeClientCommand(client, "Vote Yes");
			}
		}
	}
	else
	{
		CPrintToChat(client, "{blue}[{default}Slots{blue}] {default}Usage: {olive}!slots {default}<{olive}number{default}> {blue}| {default}Example: {olive}!slots 8");
	}
	return Plugin_Handled;
}

bool:StartSlotVote(client, String:Slots[])
{
	if (GetClientTeam(client) == 1)
	{
		PrintToChat(client, "Voting isn't allowed for spectators.");
		return false;
	}

	if (IsNewBuiltinVoteAllowed())
	{
		new iNumPlayers;
		decl iPlayers[MaxClients];
		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == 1))
			{
				continue;
			}
			iPlayers[iNumPlayers++] = i;
		}
		
		new String:sBuffer[64];
		g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
		Format(sBuffer, sizeof(sBuffer), "Limit Slots to '%s'?", Slots);
		SetBuiltinVoteArgument(g_hVote, sBuffer);
		SetBuiltinVoteInitiator(g_hVote, client);
		SetBuiltinVoteResultCallback(g_hVote, SlotVoteResultHandler);
		DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);
		return true;
	}

	PrintToChat(client, "Vote cannot be started now.");
	return false;
}

public void SlotVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (new i=0; i<num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{
				new Slots = StringToInt(g_sSlots, 10);
				DisplayBuiltinVotePass(vote, "Limiting Slots...");
				SetConVarInt(FindConVar("sv_maxplayers"), Slots);
				return;
			}
		}
	}
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

public VoteActionHandler(Handle:vote, BuiltinVoteAction:action, param1, param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			g_hVote = INVALID_HANDLE;
			CloseHandle(vote);
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, BuiltinVoteFailReason:param1);
		}
	}
}

public CVarChanged(Handle:cvar, String:oldValue[], String:newValue[])
{
	MaxSlots = GetConVarInt(hMaxSlots);
}

