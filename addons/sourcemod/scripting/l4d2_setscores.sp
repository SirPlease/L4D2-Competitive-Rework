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

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <builtinvotes>
#include <colors>

#define L4D_TEAM_SPECTATE    1

new Handle:minimumPlayersForVote = INVALID_HANDLE;
new Handle:allowPlayersToVote = INVALID_HANDLE;
new Handle:forceAdminsToVote = INVALID_HANDLE;
new Handle:voteHandler = INVALID_HANDLE;
new survivorScore = 0;
new infectedScore = 0;
new initiatingClient = 0;
new bool:adminInitiated = false;
new bool:inFirstReadyUpOfRound = false;

// Used to set the scores
new Handle:gConf = INVALID_HANDLE;
new Handle:fSetCampaignScores = INVALID_HANDLE;

public Plugin:myinfo = {
  name = "SetScores",
  author = "vintik",
  description = "Changes team scores.",
  version = "1.2",
  url = "https://bitbucket.org/vintik/various-plugins"
}

//Beginning of our plugin, verifies the game is l4d2 and sets up our convars/command
public OnPluginStart() {
  decl String:sGame[256];
  GetGameFolderName(sGame, sizeof(sGame));

  if (!StrEqual(sGame, "left4dead2", false)) {
    SetFailState("Plugin 'SetScores' supports Left 4 Dead 2 only!");
  }
  
  gConf = LoadGameConfigFile("left4dhooks.l4d2");
  if(gConf == INVALID_HANDLE)
  {
    LogError("Could not load gamedata/left4dhooks.l4d2.txt");
  }

  StartPrepSDKCall(SDKCall_GameRules);
  if(PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetCampaignScores")) {
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    fSetCampaignScores = EndPrepSDKCall();
    if(fSetCampaignScores == INVALID_HANDLE) {
      LogError("Function 'SetCampaignScores' found, but something went wrong.");
    }
  } else {
    LogError("Function 'SetCampaignScores' not found.");
  }
  
  minimumPlayersForVote = CreateConVar("setscore_player_limit", "2", "Minimum # of players in game to start the vote");
  allowPlayersToVote = CreateConVar("setscore_allow_player_vote", "1", "Whether player initiated votes are allowed, 1 to allow (default), 0 to disallow.");
  forceAdminsToVote = CreateConVar("setscore_force_admin_vote", "0", "Whether admin score changes require a vote, 1 vote required, 0 vote not required (default).");
  RegConsoleCmd("sm_setscores", Command_SetScores, "sm_setscores <survivor score> <infected score>");
}

//Starting point for the setscores command
public Action:Command_SetScores(client, args) {
  //Only allow during the first ready up of the round
  if (!inFirstReadyUpOfRound) {
    ReplyToCommand(client, "Scores can only be changed during readyup before the round starts.");
    return Plugin_Handled;
  }

  if (args < 2) {
    ReplyToCommand(client, "Usage: sm_setscores <survivor score> <infected score>");
    return Plugin_Handled;
  }

  //Store the client that requested a score change
  initiatingClient = client;

  new String:buffer[32];
  //Retrieve and store the survivor score
  GetCmdArg(1, buffer, sizeof(buffer));
  survivorScore = StringToInt(buffer);
  //Retrieve and store the infected score
  GetCmdArg(2, buffer, sizeof(buffer));
  infectedScore = StringToInt(buffer);

  new AdminId:id = GetUserAdmin(client);
  
  //Determine whether the user is admin and what action to take
  if(id != INVALID_ADMIN_ID) {
    adminInitiated = true;
    //If we are forcing admins to start votes, start a vote
    if (GetConVarInt(forceAdminsToVote) == 1) {
      StartScoreVote();
	} else {
      SetScores();
	}
  } else if (GetConVarInt(allowPlayersToVote) == 1) { 
    //If players are allowed to vote, start a vote
    adminInitiated = false;
    StartScoreVote();
  }

  return Plugin_Handled;
}

//Starts a vote to change scores
StartScoreVote() {
  //Disallow spectator voting
  if (GetClientTeam(initiatingClient) == L4D_TEAM_SPECTATE) {
    PrintToChat(initiatingClient, "Score voting isn't allowed for spectators.");
    return;
  }

  if (IsNewBuiltinVoteAllowed()) {
	//Determine the number of voting players (non-spectator) and store their client ids
    new iNumPlayers;
    decl iPlayers[MaxClients];
    for (new i=1; i<=MaxClients; i++) {
      if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == L4D_TEAM_SPECTATE)) {
        continue;
      }
      iPlayers[iNumPlayers++] = i;
    }

	//If there aren't enough players for the vote indicate so to the user
    if (iNumPlayers < GetConVarInt(minimumPlayersForVote)) {
      PrintToChat(initiatingClient, "Score vote cannot be started. Not enough players.");
      return;
    }

	//Create the vote
    voteHandler = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
	
	//Set the text for the vote, initiating client and handler
    new String:sBuffer[64];
    Format(sBuffer, sizeof(sBuffer), "Change scores to %d - %d?", survivorScore, infectedScore);
    SetBuiltinVoteArgument(voteHandler, sBuffer);
    SetBuiltinVoteInitiator(voteHandler, initiatingClient);
    SetBuiltinVoteResultCallback(voteHandler, ScoreVoteResultHandler);

	//Display the vote and make the initiator automatically vote yes
    DisplayBuiltinVote(voteHandler, iPlayers, iNumPlayers, 20);
    FakeClientCommand(initiatingClient, "Vote Yes");
    return;
  }

  PrintToChat(initiatingClient, "Score vote cannot be started now.");
}

//Actually sets the scores of the teams and print the results to all chat
SetScores() {
  //Determine which teams are which
  new SurvivorTeamIndex = GameRules_GetProp("m_bAreTeamsFlipped") ? 1 : 0;
  new InfectedTeamIndex = GameRules_GetProp("m_bAreTeamsFlipped") ? 0 : 1;
  
  //Set the scores
  SDKCall(fSetCampaignScores, survivorScore, infectedScore); //visible scores
  L4D2Direct_SetVSCampaignScore(SurvivorTeamIndex, survivorScore); //real scores
  L4D2Direct_SetVSCampaignScore(InfectedTeamIndex, infectedScore);
 
  if(!adminInitiated) {
    CPrintToChatAll("Scores set to {olive}%d {default} ({green}Sur{default}) - {olive}%d {default} ({green}Inf{default}) by vote.", survivorScore, infectedScore);
  } else {
    new String:client_name[32];
    GetClientName(initiatingClient, client_name, sizeof(client_name));
    CPrintToChatAll("Scores set to {olive}%d {default} ({green}Sur{default}) - {olive}%d {default} ({green}Inf{default}) by {lightgreen}%s{default}.", survivorScore, infectedScore, client_name);
  }
}

//Handler for the vote
public VoteActionHandler(Handle:vote, BuiltinVoteAction:action, param1, param2) {
  switch (action) {
   	case BuiltinVoteAction_End: {
      voteHandler = INVALID_HANDLE;
      CloseHandle(vote);
    }
    case BuiltinVoteAction_Cancel: {
      DisplayBuiltinVoteFail(vote, BuiltinVoteFailReason:param1);
    }
  }
}

//Handles a score vote's results, if a majority voted for the score change then set the scores
public ScoreVoteResultHandler(Handle:vote, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2]) {
  for (new i=0; i<num_items; i++) {
    if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES) {
      if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2)) {
        DisplayBuiltinVotePass(vote, "Changing scores...");
        SetScores();
        return;
   	  }
    }
  }
  DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

// Disables score changes once round goes live
public OnRoundIsLive() {
  inFirstReadyUpOfRound = false;
}

// Enables scores changes when map is loaded
public OnMapStart() {
  inFirstReadyUpOfRound = true;
}