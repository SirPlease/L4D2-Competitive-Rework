/**
 * SetScores Left 4 Dead 2 plugin version 1.2. Allows players/admins to set the score for a match via the 
 * !setscores command in chat. Through the cvar setscore_allow_player_vote (default 1, enabled) server 
 * administrators may disable the vote functionality. The cvar setscore_force_admin_vote will force admins
 * to start a vote to change the score (default 0, vote not required). Additionally, the number of players 
 * required to initiate the vote may be configured by setscore_player_limit (default 2).
 *
 * Original Author: vintik
 * 
 * Contributors: purpletreefactory and Grego, added vote functionality and all chat messages
 *
 * Special Thanks: ProdigySim and Visor, code improvements and suggestions
 *
 * Testers: LuckyLock, DuckDuckGo, XBye, Statik
 */
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <builtinvotes>

#define PLUGIN_VERSION "1.4"

#define GAMEDATA_FILE "left4dhooks.l4d2"

public Plugin myinfo =
{
	name = "SetScores",
	author = "vintik, Forgetest, A1m`",
	description = "Changes team scores.",
	version = PLUGIN_VERSION,
	url = "https://bitbucket.org/vintik/various-plugins"
}

#define L4D_TEAM_SPECTATE 1

ConVar 
	minimumPlayersForVote, 
	allowPlayersToVote, 
	forceAdminsToVote;
	
Handle 
	voteHandler,
	hSetCampaignScores;
	
int 
	survivorScore, 
	infectedScore;
	
bool 
	inFirstReadyUpOfRound;

//Beginning of our plugin, verifies the game is l4d2 and sets up our convars/command
public void OnPluginStart()
{
	CheckGame();
	LoadSDK();
	
	minimumPlayersForVote = CreateConVar("setscore_player_limit", "2", "Minimum # of players in game to start the vote");
	allowPlayersToVote = CreateConVar("setscore_allow_player_vote", "1", "Whether player initiated votes are allowed, 1 to allow (default), 0 to disallow.");
	forceAdminsToVote = CreateConVar("setscore_force_admin_vote", "0", "Whether admin score changes require a vote, 1 vote required, 0 vote not required (default).");
	
	RegConsoleCmd("sm_setscores", Command_SetScores, "sm_setscores <survivor score> <infected score>");
}

void CheckGame()
{
	if (GetEngineVersion() != Engine_Left4Dead2) {
		SetFailState("Plugin 'SetScores' supports Left 4 Dead 2 only!");
	}
}

void LoadSDK()
{
	GameData conf = LoadGameConfigFile(GAMEDATA_FILE);
	if (conf == INVALID_HANDLE)
	{
		SetFailState("Could not load gamedata/%s.txt", GAMEDATA_FILE);
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if (!PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "SetCampaignScores")) {
		SetFailState("Function 'SetCampaignScores' not found.");
	}
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hSetCampaignScores = EndPrepSDKCall();
	if (hSetCampaignScores == INVALID_HANDLE) {
		SetFailState("Function 'SetCampaignScores' found, but something went wrong.");
	}
	
	delete conf;
}

//Starting point for the setscores command
public Action Command_SetScores(int client, int args)
{
	//Only allow during the first ready up of the round
	if (!inFirstReadyUpOfRound) {
		ReplyToCommand(client, "Scores can only be changed during readyup before the round starts.");
		return Plugin_Handled;
	}
	
	if (args < 2) {
		ReplyToCommand(client, "Usage: sm_setscores <survivor score> <infected score>");
		return Plugin_Handled;
	}
	
	char buffer[32];
	//Retrieve and store the survivor score
	GetCmdArg(1, buffer, sizeof(buffer));
	int tempSurvivorScore = StringToInt(buffer);
	//Retrieve and store the infected score
	GetCmdArg(2, buffer, sizeof(buffer));
	int tempInfectedScore = StringToInt(buffer);
	
	bool IsAdmin = false;
	
	//Determine whether the user is admin and what action to take
	if (GetUserAdmin(client) != INVALID_ADMIN_ID) {
		//If we are forcing admins to start votes, start a vote
		if (!forceAdminsToVote.BoolValue) {
			SetScores(tempSurvivorScore, tempInfectedScore, client);
			return Plugin_Handled;
		}
		
		IsAdmin = true; //else, ignore setscore_allow_player_vote convar for admins
	}
	
	if (IsAdmin || allowPlayersToVote.BoolValue) {
		//If players are allowed to vote, start a vote
		StartScoreVote(tempSurvivorScore, tempInfectedScore, client, IsAdmin);
	}
	
	return Plugin_Handled;
}

//Starts a vote to change scores
void StartScoreVote(const int survScore, const int infectScore, const int initiator, bool IsAdmin)
{
	//Disallow spectator voting
	if (!IsAdmin && GetClientTeam(initiator) == L4D_TEAM_SPECTATE) {
		PrintToChat(initiator, "Score voting isn't allowed for spectators.");
		return;
	}

	if (IsNewBuiltinVoteAllowed()) {
		//Determine the number of voting players (non-spectator) and store their client ids
		int iNumPlayers;
		int[] iPlayers = new int[MaxClients];
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == L4D_TEAM_SPECTATE))
				continue;
				
			iPlayers[iNumPlayers++] = i;
		}

		//If there aren't enough players for the vote indicate so to the user
		if (iNumPlayers < minimumPlayersForVote.IntValue) {
			PrintToChat(initiator, "Score vote cannot be started. Not enough players.");
			return;
		}
		
		//The best place for this
		survivorScore = survScore; 
		infectedScore = infectScore;
		
		//Create the vote
		voteHandler = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
		
		//Set the text for the vote, initiating client and handler
		char sBuffer[64];
		Format(sBuffer, sizeof(sBuffer), "Change scores to %d - %d?", survivorScore, infectedScore);
		SetBuiltinVoteArgument(voteHandler, sBuffer);
		SetBuiltinVoteInitiator(voteHandler, initiator);
		SetBuiltinVoteResultCallback(voteHandler, ScoreVoteResultHandler);
		
		//Display the vote and make the initiator automatically vote yes
		DisplayBuiltinVote(voteHandler, iPlayers, iNumPlayers, 20);
		FakeClientCommand(initiator, "Vote Yes");
		return;
	}

	PrintToChat(initiator, "Score vote cannot be started now.");
}

//Actually sets the scores of the teams and print the results to all chat
void SetScores(const int survScore, const int infectScore, const int iAdminIndex)
{
	//Determine which teams are which
	bool bFlipped = L4D2_AreTeamsFlipped();
	int SurvivorTeamIndex = bFlipped ? 1 : 0;
	int InfectedTeamIndex = bFlipped ? 0 : 1;
	
	//Set the scores
	SDKCall(hSetCampaignScores,
				(bFlipped) ? infectScore : survScore,
				(bFlipped) ? survScore : infectScore); //visible scores
	L4D2Direct_SetVSCampaignScore(SurvivorTeamIndex, survScore); //real scores
	L4D2Direct_SetVSCampaignScore(InfectedTeamIndex, infectScore);
	
	if (iAdminIndex != -1) { //This works well for an index '0' as well, if the initiator is CONSOLE
		char client_name[32];
		GetClientName(iAdminIndex, client_name, sizeof(client_name));
		PrintToChatAll("\x01Scores set to \x05%d \x01 (\x04Sur\x01) - \x05%d \x01 (\x04Inf\x01) by \x03%s\x01.", survScore, infectScore, client_name);
	} else {
		PrintToChatAll("\x01Scores set to \x05%d \x01 (\x04Sur\x01) - \x05%d \x01 (\x04Inf\x01) by vote.", survScore, infectScore);
	}
}

//Handler for the vote
public int VoteActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2) {
	switch (action) {
		case BuiltinVoteAction_End: {
			voteHandler = null;
			delete vote;
		}
		case BuiltinVoteAction_Cancel: {
			DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Generic);
		}
	}
}

//Handles a score vote's results, if a majority voted for the score change then set the scores
public void ScoreVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i = 0; i < num_items; i++) {
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES) {
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2)) {
				DisplayBuiltinVotePass(vote, "Changing scores...");
				SetScores(survivorScore, infectedScore, -1);
				return;
			}
		}
	}
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

// Disables score changes once round goes live
public void OnRoundIsLive()
{
	inFirstReadyUpOfRound = false;
}

// Enables scores changes when map is loaded
public void OnMapStart()
{
	inFirstReadyUpOfRound = true;
}
