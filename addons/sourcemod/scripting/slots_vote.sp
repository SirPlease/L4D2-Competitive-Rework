#pragma semicolon 1
#pragma newdecls required

#include <builtinvotes>
#include <colors>
#include <sourcemod>

#define L4D2Team_Spectator 1

Handle g_hVote;
char   g_sSlots[32];
ConVar hMaxSlots;
int    MaxSlots;

public Plugin myinfo =
{
	name        = "Slots?! Voter",
	description = "Slots Voter",
	author      = "Sir",
	version     = "",
	url         = "https://github.com/SirPlease/L4D2-Competitive-Rework/"
};

public void OnPluginStart()
{
	LoadTranslations("slots_vote.phrases");
	RegConsoleCmd("sm_slots", SlotsRequest);
	hMaxSlots = CreateConVar("slots_max_slots", "30", "Maximum amount of slots you wish players to be able to vote for? (DON'T GO HIGHER THAN 30)");
	MaxSlots  = hMaxSlots.IntValue;
	HookConVarChange(hMaxSlots, CVarChanged);
}

public Action SlotsRequest(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%T", "NotConsoleVote", LANG_SERVER);
		return Plugin_Handled;
	}

	if (args == 1)
	{
		char sSlots[64];
		GetCmdArg(1, sSlots, sizeof(sSlots));
		int Int = StringToInt(sSlots);
		if (Int > MaxSlots)
		{
			CPrintToChat(client, "%t %t", "Tag", "LimitSlotsAbove", MaxSlots);
		}
		else
		{
			if (CheckCommandAccess(client, "sm_kick", ADMFLAG_KICK))
			{
				char sName[MAX_NAME_LENGTH];
				GetClientName(client, sName, sizeof(sName));
				CPrintToChatAll("%t %t", "Tag", "LimitedSlotsTo", sName, Int);
				SetConVarInt(FindConVar("sv_maxplayers"), Int);
			}
			else if (Int < GetConVarInt(FindConVar("survivor_limit")) + GetConVarInt(FindConVar("z_max_player_zombies")))
			{
				CPrintToChat(client, "%t %t", "Tag", "RequiredPlayers");
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
		CPrintToChat(client, "%t %t", "Tag", "SlotsUsage");
	}
	return Plugin_Handled;
}

bool StartSlotVote(int client, char[] Slots)
{
	if (GetClientTeam(client) <= L4D2Team_Spectator)
	{
		CPrintToChat(client, "%t %t", "Tag", "Spectators");
		return false;
	}

	if (!IsBuiltinVoteInProgress())
	{
		int iNumPlayers = 0;
		int[] iPlayers  = new int[MaxClients];

		// list of non-spectators players
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) <= L4D2Team_Spectator)
			{
				continue;
			}

			iPlayers[iNumPlayers++] = i;
		}

		char sBuffer[64];
		Format(sBuffer, sizeof(sBuffer), "%T", "LimitSlots", LANG_SERVER, Slots);

		g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
		SetBuiltinVoteArgument(g_hVote, sBuffer);
		SetBuiltinVoteInitiator(g_hVote, client);
		SetBuiltinVoteResultCallback(g_hVote, SlotVoteResultHandler);
		DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);
		return true;
	}

	CPrintToChat(client, "%t %t", "Tag", "CannotBeStarted");
	return false;
}

public void VoteActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			delete vote;
			g_hVote = null;
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
		}
	}
}

public void SlotVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i = 0; i < num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{

				int Slots = StringToInt(g_sSlots, 10);
				char Buffer[32];
				Format(Buffer, sizeof(Buffer), "%T", "LimitingSlots", LANG_SERVER);
				DisplayBuiltinVotePass(vote, Buffer);
				SetConVarInt(FindConVar("sv_maxplayers"), Slots);
				return;
			}
		}
	}
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

public void CVarChanged(Handle cvar, char[] oldValue, char[] newValue)
{
	MaxSlots = GetConVarInt(hMaxSlots);
}