#pragma semicolon 1
#include <sourcemod>
#include <custom_fakelag>
#include <colors>
#include <builtinvotes>
#include <readyup>


public Plugin myinfo =
{
	name = "Set Fakelags",
	author = "sheo",
	description = "!fakelag_votestart and !fakelag commands to set fake player latency",
	version = "1.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};


Handle g_hVote;
int iYesVotes = 0;
int iNoVotes = 0;

bool bIsFirstReadyUp;


public OnPluginStart() {
	RegConsoleCmd("sm_fakelag", Cmd_SetFakelag);
	RegConsoleCmd("sm_fakelags", Cmd_SetFakelag);
	RegConsoleCmd("sm_fakelatency", Cmd_SetFakelag);
	RegConsoleCmd("sm_fakeping", Cmd_SetFakelag);

	RegConsoleCmd("sm_listlags", Cmd_ListFakelag);
	RegConsoleCmd("sm_listlag", Cmd_ListFakelag);
	RegConsoleCmd("sm_listping", Cmd_ListFakelag);
	RegConsoleCmd("sm_listpings", Cmd_ListFakelag);
	RegConsoleCmd("sm_listfakelags", Cmd_ListFakelag);
	RegConsoleCmd("sm_listfakepings", Cmd_ListFakelag);

	RegConsoleCmd("sm_fakelag_votestart", Cmd_VoteFakelag);
	RegConsoleCmd("sm_fakelags_votestart", Cmd_VoteFakelag);
	RegConsoleCmd("sm_fakelag_vote", Cmd_VoteFakelag);
	RegConsoleCmd("sm_fakelags_vote", Cmd_VoteFakelag);

	RegAdminCmd("sm_forcefakelags", Cmd_ForceFL, ADMFLAG_ROOT);
	RegAdminCmd("sm_forcedisablefakelags", Cmd_ForceDisableFL, ADMFLAG_ROOT);
}

Action Cmd_ForceFL(int client, int args) {
	EquatePings();
	return Plugin_Handled;
}

Action Cmd_ForceDisableFL(int client, int args) {
	RemoveAllFakelags();
	return Plugin_Handled;
}

Action Cmd_VoteFakelag(int client, int args) {
	if (client > 0 && IsClientInGame(client) && GetClientTeam(client) > 1 && !IsBuiltinVoteInProgress()) {
		int iNumPlayers;
		int iPlayers[MAXPLAYERS + 1];
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1) {
				iPlayers[iNumPlayers++] = i;
			}
		}
		g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
		iYesVotes = 0;
		iNoVotes = 0;
		SetBuiltinVoteArgument(g_hVote, "Equalize pings?");
		CPrintToChatAll("{olive}%N {default}suggested to equalize pings", client);
		SetBuiltinVoteInitiator(g_hVote, client);
		SetBuiltinVoteResultCallback(g_hVote, PingsVoteResultHandler);
		DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 15);
		FakeClientCommand(client, "Vote Yes");
	}
	return Plugin_Handled;
}

public VoteActionHandler(Handle vote, BuiltinVoteAction action, param1, param2) {
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
		case BuiltinVoteAction_Select:
		{
			if (param2 == 1) {
				iYesVotes++;
				//PrintToChatAll("%N : F1", param1);
			} else if (param2 == 0) {
				iNoVotes++;
				//PrintToChatAll("%N : F2", param1);
			}
		}
	}
}

public void PingsVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info) {
	if (iYesVotes > iNoVotes) {
		DisplayBuiltinVotePass(vote, "Pings are equalized");
		CPrintToChatAll("[{green}!{default}] Pings are equalized");
		CPrintToChatAll("[{green}!{default}] If they become incorrect midgame, start {green}!fakelag_votestart{default} again");
		CPrintToChatAll("[{green}!{default}] Type {green}/fakelag 0{default} to disable (only for you, not a vote)");
		EquatePings();
	} else {
		DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
	}
}

Action Cmd_SetFakelag(int client, int args) {
	if (client > 0 && IsClientInGame(client)) {
		if (!bIsFirstReadyUp) {
			CPrintToChat(client, "[{green}!{default}] Fake latency setting is only allowed during first readyup of the map");
			CPrintToChat(client, "[{green}!{default}] Use {green}!fakelag_votestart{default} to equalize pings midgame");
			return Plugin_Handled;
		}
		float fFakeLatency;
		if (args > 0) {
			char sArg1[10];
			GetCmdArg(1, sArg1, sizeof(sArg1));
			fFakeLatency = StringToFloat(sArg1);
			if (fFakeLatency > 350.0) {
				fFakeLatency = 350.0;
			} else if (fFakeLatency < 0.0) {
				fFakeLatency = 0.0;
			}
		} else {
			fFakeLatency = 0.0;
		}
		if (CFakeLag_GetPlayerLatency(client) != fFakeLatency) {
			CFakeLag_SetPlayerLatency(client, fFakeLatency);
			CPrintToChatAll("[{green}!{default}] {blue}%N {default}set his fake latency to {green}%.01f{default}ms", client, fFakeLatency);
		}
	}
	return Plugin_Handled;
}

Action Cmd_ListFakelag(int client, int args) {
	if (client > 0 && IsClientInGame(client)) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
				PrintToChat(client, "%N : %.01fms", i, CFakeLag_GetPlayerLatency(i));
			}
		}
	}
	return Plugin_Handled;
}

EquatePings() {

	//get players and their pings
	int iClients[4][2]; //0 if no client
	float fPings[4][2]; //0.0 if no client
	int fTClientSurv;
	int fTClientInf;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			if (GetClientTeam(i) == 2) {
				if (fTClientSurv >= 4) {
					return;
				}
				iClients[fTClientSurv][0] = i;
				fPings[fTClientSurv][0] = GetPing(i);
				fTClientSurv++;
			} else if (GetClientTeam(i) == 3) {
				if (fTClientInf >= 4) {
					return;
				}
				iClients[fTClientInf][1] = i;
				fPings[fTClientInf][1] = GetPing(i);
				fTClientInf++;
			}
		}
	}


	//sort players by their pings
	int iTempVal;
	float fTempVal;
	for (int iT = 0; iT <= 1; iT++) {
		bool bSorted = false;
		while (!bSorted) {
			bool bSortHit = false;
			for (int iP = 2; iP >= 0; iP--) {
				if (iClients[iP + 1][iT] > 0 && (fPings[iP][iT] < fPings[iP + 1][iT] || iClients[iP][iT] == 0)) {
					iTempVal = iClients[iP + 1][iT];
					iClients[iP + 1][iT] = iClients[iP][iT];
					iClients[iP][iT] = iTempVal;

					fTempVal = fPings[iP + 1][iT];
					fPings[iP + 1][iT] = fPings[iP][iT];
					fPings[iP][iT] = fTempVal;
					//PrintToServer("Sort op (team %d): %.01f, %.01f, %.01f, %.01f", iT, fPings[0][iT], fPings[1][iT], fPings[2][iT], fPings[3][iT]);
					if (!bSortHit) {
						bSortHit = true;
					}
				}
			}
			if (!bSortHit) {
				bSorted = true;
			}
		}
	}


	//equalize ping between two players from different teams
	for (int iP = 0; iP < 4; iP++) {
		if (iClients[iP][0] > 0 && iClients[iP][1] > 0) {
			if (fPings[iP][0] > fPings[iP][1]) {
				CFakeLag_SetPlayerLatency(iClients[iP][1], fPings[iP][0] - fPings[iP][1]);
				//PrintToChatAll("Eq pings of %N and %N (diff %.01f)", iClients[iP][0], iClients[iP][1], fPings[iP][0] - fPings[iP][1]);
			} else if (fPings[iP][1] > fPings[iP][0]) {
				CFakeLag_SetPlayerLatency(iClients[iP][0], fPings[iP][1] - fPings[iP][0]);
				//PrintToChatAll("Eq pings of %N and %N (diff %.01f)", iClients[iP][0], iClients[iP][1], fPings[iP][1] - fPings[iP][0]);
			} else {
				CFakeLag_SetPlayerLatency(iClients[iP][0], 0.0);
				CFakeLag_SetPlayerLatency(iClients[iP][1], 0.0);
			}
		} else if (iClients[iP][0] > 0 && iClients[iP][1] == 0) {
			CFakeLag_SetPlayerLatency(iClients[iP][0], 0.0);
		} else if (iClients[iP][0] == 0 && iClients[iP][1] > 0) {
			CFakeLag_SetPlayerLatency(iClients[iP][1], 0.0);
		}
	}
}

RemoveAllFakelags() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 0) {
			CFakeLag_SetPlayerLatency(i, 0.0);
		}
	}
}

float GetPing(client) {
	return ((GetClientAvgLatency(client, NetFlow_Outgoing) * 1000.0) - CFakeLag_GetPlayerLatency(client));
}

public void OnMapStart() {
	bIsFirstReadyUp = true;
}

public void OnRoundIsLive() {
	bIsFirstReadyUp = false;
}