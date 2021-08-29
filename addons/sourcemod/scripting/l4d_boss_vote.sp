#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <builtinvotes>
#include <colors>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util_rounds>
#undef REQUIRE_PLUGIN
#include <readyup>
#include <l4d2_boss_percents>
#include <witch_and_tankifier>

#define PLUGIN_VERSION "3.2.5"

public Plugin myinfo =
{
	name = "[L4D2] Vote Boss",
	author = "Spoon, Forgetest",
	version = PLUGIN_VERSION,
	description = "Votin for boss change.",
	url = "https://github.com/spoon-l4d2"
};

GlobalForward
	g_forwardUpdateBosses;

ConVar
	g_hCvarBossVoting;
	
bool
	bv_bTank,
	bv_bWitch;

int
	bv_iTank,
	bv_iWitch;

public void OnPluginStart()
{
	g_forwardUpdateBosses = new GlobalForward("OnUpdateBosses", ET_Ignore, Param_Cell, Param_Cell);
	
	g_hCvarBossVoting = CreateConVar("l4d_boss_vote", "1", "Enable boss voting", FCVAR_NOTIFY, true, 0.0, true, 1.0); // Sets if boss voting is enabled or disabled
	
	RegConsoleCmd("sm_voteboss", VoteBossCmd); // Allows players to vote for custom boss spawns
	RegConsoleCmd("sm_bossvote", VoteBossCmd); // Allows players to vote for custom boss spawns
	
	RegAdminCmd("sm_ftank", ForceTankCommand, ADMFLAG_BAN);
	RegAdminCmd("sm_fwitch", ForceWitchCommand, ADMFLAG_BAN);
}

bool RunVoteChecks(int client)
{
	if (IsDarkCarniRemix())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Boss voting is not available on this map.");
		return false;
	}
	if (!IsInReady())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Boss voting is only available during ready up.");
		return false;
	}
	if (InSecondHalfOfRound())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Boss voting is only available during the first round of a map.");
		return false;
	}
	if (GetClientTeam(client) == 1)
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Boss voting is not available for spectators.");
		return false;
	}
	if (!IsNewBuiltinVoteAllowed())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Boss Vote cannot be called right now...");
		return false;
	}
	return true;
}

public Action VoteBossCmd(int client, int args)
{
	if (!GetConVarBool(g_hCvarBossVoting)) return;
	if (!RunVoteChecks(client)) return;
	if (args != 2)
	{
		CReplyToCommand(client, "{blue}<{green}BossVote{blue}>{default} Usage: !voteboss {olive}<{default}tank{olive}> <{default}witch{olive}>{default}.");
		CReplyToCommand(client, "{blue}<{green}BossVote{blue}>{default} Use {default}\"{blue}0{default}\" for {olive}No Spawn{default}, \"{blue}-1{default}\" for {olive}Ignorance.");
		return;
	}
	
	// Get all non-spectating players
	int iNumPlayers;
	int[] iPlayers = new int[MaxClients];
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == 1))
		{
			continue;
		}
		iPlayers[iNumPlayers++] = i;
	}
	
	// Get Requested Boss Percents
	char bv_sTank[8];
	char bv_sWitch[8];
	GetCmdArg(1, bv_sTank, 8);
	GetCmdArg(2, bv_sWitch, 8);
	
	bv_iTank = -1;
	bv_iWitch = -1;
	
	// Make sure the args are actual numbers
	if (!IsInteger(bv_sTank) || !IsInteger(bv_sWitch))
	{
		CReplyToCommand(client, "{blue}<{green}BossVote{blue}>{default} Percentages are {olive}invalid{default}.");
		return;
	}
	
	// Check to make sure static bosses don't get changed
	if (!IsStaticTankMap())
	{
		bv_bTank = (bv_iTank = StringToInt(bv_sTank)) > 0;
	}
	else
	{
		bv_bTank = false;
		CReplyToCommand(client, "{blue}<{green}BossVote{blue}>{default} Tank spawn is static and can not be changed on this map.");
	}
	
	if (!IsStaticWitchMap())
	{
		bv_bWitch = (bv_iWitch = StringToInt(bv_sWitch)) > 0;
	}
	else
	{
		bv_bWitch = false;
		CReplyToCommand(client, "{blue}<{green}BossVote{blue}>{default} Witch spawn is static and can not be changed on this map.");
	}
	
	// Check if percent is within limits
	if (bv_bTank && !IsTankPercentValid(bv_iTank))
	{
		CReplyToCommand(client, "{blue}<{green}BossVote{blue}>{default} Tank percentage is {blue}banned{default}.");
		return;
	}
	
	if (bv_bWitch && !IsWitchPercentValid(bv_iWitch))
	{
		CReplyToCommand(client, "{blue}<{green}BossVote{blue}>{default} Witch percentage is {blue}banned{default}.");
		return;
	}
	
	char bv_voteTitle[64];
	
	// Set vote title
	if (bv_bTank && bv_bWitch)	// Both Tank and Witch can be changed 
	{
		Format(bv_voteTitle, 64, "Set Tank to: %s and Witch to: %s?", bv_sTank, bv_sWitch);
	}
	else if (bv_bTank)	// Only Tank can be changed
	{
		if (bv_iWitch == 0)
		{
			Format(bv_voteTitle, 64, "Set Tank to: %s and Witch to: Disabled?", bv_sTank);
		}
		else
		{
			Format(bv_voteTitle, 64, "Set Tank to: %s?", bv_sTank);
		}
	}
	else if (bv_bWitch) // Only Witch can be changed
	{
		if (bv_iTank == 0)
		{
			Format(bv_voteTitle, 64, "Set Tank to: Disabled and Witch to: %s?", bv_sWitch);
		}
		else
		{
			Format(bv_voteTitle, 64, "Set Witch to: %s?", bv_sWitch);
		}
	}
	else // Neither can be changed... ok...
	{
		if (bv_iTank == 0 && bv_iWitch == 0)
		{
			Format(bv_voteTitle, 64, "Set Bosses to: Disabled?");
		}
		else if (bv_iTank == 0)
		{
			Format(bv_voteTitle, 64, "Set Tank to: Disabled?");
		}
		else if (bv_iWitch == 0)
		{
			Format(bv_voteTitle, 64, "Set Witch to: Disabled?");
		}
		else // Probably not.
		{
			return;
		}
	}
	
	// Start the vote!
	Handle bv_hVote = CreateBuiltinVote(BossVoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
	SetBuiltinVoteArgument(bv_hVote, bv_voteTitle);
	SetBuiltinVoteInitiator(bv_hVote, client);
	SetBuiltinVoteResultCallback(bv_hVote, BossVoteResultHandler);
	DisplayBuiltinVote(bv_hVote, iPlayers, iNumPlayers, 20);
	FakeClientCommand(client, "Vote Yes");
}

public void BossVoteActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			CloseHandle(vote);
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
		}
	}
}

public void BossVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i=0; i<num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2))
			{
			
				// One last ready-up check.
				if (!IsInReady())  {
					DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
					CPrintToChatAll("{blue}<{green}BossVote{blue}>{default} Spawns can only be set during ready up.");
					return;
				}
				
				if (bv_bTank && bv_bWitch)	// Both Tank and Witch can be changed 
				{
					DisplayBuiltinVotePass(vote, "Setting Boss Spawns...");
				}
				else if (bv_bTank)	// Only Tank can be changed -- Witch must be static
				{
					DisplayBuiltinVotePass(vote, "Setting Tank Spawn...");
				}
				else if (bv_bWitch) // Only Witch can be changed -- Tank must be static
				{
					DisplayBuiltinVotePass(vote, "Setting Witch Spawn...");
				}
				else // Neither can be changed... ok...
				{
					DisplayBuiltinVotePass(vote, "Setting Boss Disabled...");
				}
				
				SetTankPercent(bv_iTank);
				SetWitchPercent(bv_iWitch);
				
				if (bv_iTank == 0)
				{
					SetTankDisabled(true);
				}
				
				if (bv_iWitch == 0)
				{
					SetWitchDisabled(true);
				}
				
				// Update our shiz yo
				UpdateBossPercents();
				
				// Forward da message man :)
				Call_StartForward(g_forwardUpdateBosses);
				Call_PushCell(bv_iTank);
				Call_PushCell(bv_iWitch);
				Call_Finish();
				
				return;
			}
		}
	}
	
	// Vote Failed
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
	return;
}

bool IsInteger(const char[] buffer)
{
	// negative check
	if ( !IsCharNumeric(buffer[0]) && buffer[0] != '-' )
		return false;
	
	int len = strlen(buffer);
	for (int i = 1; i < len; i++)
	{
		if ( !IsCharNumeric(buffer[i]) )
			return false;
	}

	return true;
}

/* ========================================================
// ==================== Admin Commands ====================
// ========================================================
 *
 * Where the admin commands for setting boss spawns will go
 *
 * vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
*/

public Action ForceTankCommand(int client, int args)
{
	if (!GetConVarBool(g_hCvarBossVoting)) return;
	if (IsDarkCarniRemix())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Command not available on this map.");
		return;
	}
	
	if (IsStaticTankMap())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Tank spawn is static and can not be changed on this map.");
		return;
	}
	
	if (!IsInReady())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Command can only be used during ready up.");
		return;
	}
	
	// Get Requested Tank Percent
	char bv_sTank[32];
	GetCmdArg(1, bv_sTank, 32);
	
	// Make sure the cmd argument is a number
	if (!IsInteger(bv_sTank))
		return;
	
	// Convert it to in int boy
	int p_iRequestedPercent = StringToInt(bv_sTank);
	
	if (p_iRequestedPercent < 0)
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Percentage is {blue}invalid{default}.");
		return;
	}
	
	// Check if percent is within limits
	if (!IsTankPercentValid(p_iRequestedPercent))
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Percentage is {blue}banned{default}.");
		return;
	}
	
	// Set the boss
	SetTankPercent(p_iRequestedPercent);
	
	// Let everybody know
	char clientName[32];
	GetClientName(client, clientName, sizeof(clientName));
	CPrintToChatAll("{blue}<{green}BossVote{blue}>{default} Tank spawn set to {olive}%i%%{default} by Admin {blue}%s{default}.", p_iRequestedPercent, clientName);
	
	// Update our shiz yo
	UpdateBossPercents();
	
	// Forward da message man :)
	Call_StartForward(g_forwardUpdateBosses);
	Call_PushCell(p_iRequestedPercent);
	Call_PushCell(-1);
	Call_Finish();
}

public Action ForceWitchCommand(int client, int args)
{
	if (!GetConVarBool(g_hCvarBossVoting)) return;
	if (IsDarkCarniRemix())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Command not available on this map.");
		return;
	}
	
	if (IsStaticWitchMap())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Witch spawn is static and can not be changed on this map.");
		return;
	}
	
	if (!IsInReady())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Command can only be used during ready up.");
		return;
	}
	
	// Get Requested Witch Percent
	char bv_sWitch[32];
	GetCmdArg(1, bv_sWitch, 32);
	
	// Make sure the cmd argument is a number
	if (!IsInteger(bv_sWitch))
		return;
	
	// Convert it to in int boy
	int p_iRequestedPercent = StringToInt(bv_sWitch);
	
	if (p_iRequestedPercent < 0)
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Percentage is {blue}invalid{default}.");
		return;
	}
	
	// Check if percent is within limits
	if (!IsWitchPercentValid(p_iRequestedPercent))
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Percentage is {olive}banned{default}.");
		return;
	}
	
	// Set the boss
	SetWitchPercent(p_iRequestedPercent);
	
	// Let everybody know
	char clientName[32];
	GetClientName(client, clientName, sizeof(clientName));
	CPrintToChatAll("{blue}<{green}BossVote{blue}>{default} Witch spawn set to {olive}%i%%{default} by Admin {blue}%s{default}.", p_iRequestedPercent, clientName);
	
	// Update our shiz yo
	UpdateBossPercents();
	
	// Forward da message man :)
	Call_StartForward(g_forwardUpdateBosses);
	Call_PushCell(-1);
	Call_PushCell(p_iRequestedPercent);
	Call_Finish();
}