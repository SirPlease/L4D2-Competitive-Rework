#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <builtinvotes>

DataPack
	g_hCallBackPack = null;

Handle
	g_hVoteHandler = null;

ConVar
	g_hCvarBlockBVote = null,
	g_hCvarDisplayBVoteResult = null;

enum
{
	eBlockNone = 0,
	eBlockOnCreation,
	eBlockAtStart
};

enum
{
	eVoteFail = 0,
	eVotePass
};

stock const char g_sBuiltinVoteCreateError[][] =
{
	"eBuiltinVoteErrorNone",
	"eBlockedWithForward",
	"eInvalidParamBuiltinVoteType"
};

public Plugin myinfo =
{
	name = "[L4D2] BuiltinVotes test",
	author = "A1m`",
	description = "Plugin to test the extension 'builtinvotes'",
	version = "2.5",
	url = "https://github.com/L4D-Community/builtinvotes"
};

public void OnPluginStart()
{
	g_hCvarBlockBVote = CreateConVar("sm_block_builtinvotes", \
		"0", \
		"Block all votes from extension 'builtinvotes' (used for debugging). 1 - block voting on creation, 2 - block voting at start.", \
		_, true, 0.0, true, 2.0 \
	);

	g_hCvarDisplayBVoteResult = CreateConVar("sm_display_builtinvotes_result", \
		"1", \
		"Display the result of voting at the end of voting. 0 - not display, 1 - display.", \
		_, true, 0.0, true, 1.0 \
	);

	RegAdminCmd("sm_bv_test", Cmd_BuiltinVotesTest, ADMFLAG_GENERIC);
	RegAdminCmd("sm_bv_close_data", Cmd_BuiltinVotesCloseData, ADMFLAG_GENERIC);
	RegAdminCmd("sm_getvotecontroller", Cmd_GetGameVoteController, ADMFLAG_GENERIC);
}

Action Cmd_GetGameVoteController(int iClient, int iArgs)
{
	int iEntIndex = Game_GetVoteController();
	
	char sEntityName[64];
	FormatEx(sEntityName, sizeof(sEntityName), "Unknown entity");

	if (iEntIndex > MaxClients && IsValidEntity(iEntIndex)) {
		GetEntityClassname(iEntIndex, sEntityName, sizeof(sEntityName));
	}

	PrintToChat(iClient, "Entity name: %s, entity index: %d!", sEntityName, iEntIndex);

	return Plugin_Handled;
}

public Action OnBuiltinVoteCreate(Handle hPlugin, const char[] sPluginName)
{
	PrintToChatAll("[OnBuiltinVoteCreate] hPlugin: %x, sPluginName: %s", hPlugin, sPluginName);

	if (hPlugin != null) {
		char sPlName[32], sPlAuthor[32], sPlDescription[64], sPlVersion[16], sPlUrl[256];
		
		GetPluginInfo(hPlugin, PlInfo_Name, sPlName, sizeof(sPlName));
		GetPluginInfo(hPlugin, PlInfo_Author, sPlAuthor, sizeof(sPlAuthor));
		GetPluginInfo(hPlugin, PlInfo_Description, sPlDescription, sizeof(sPlDescription));
		GetPluginInfo(hPlugin, PlInfo_Version, sPlVersion, sizeof(sPlVersion));
		GetPluginInfo(hPlugin, PlInfo_URL, sPlUrl, sizeof(sPlUrl));

		PrintToChatAll("[OnBuiltinVoteCreate] Plugin name: %s ", sPlName);
		PrintToChatAll("[OnBuiltinVoteCreate] Plugin author: %s ", sPlAuthor);
		PrintToChatAll("[OnBuiltinVoteCreate] Plugin description: %s ", sPlDescription);
		PrintToChatAll("[OnBuiltinVoteCreate] Plugin version: %s ", sPlVersion);
		PrintToChatAll("[OnBuiltinVoteCreate] Plugin url: %s ", sPlUrl);
		PrintToChatAll("[OnBuiltinVoteCreate] Plugin status: %d", GetPluginStatus(hPlugin));
	}

	return (g_hCvarBlockBVote.IntValue == eBlockOnCreation) ? Plugin_Handled : Plugin_Continue;
}

public Action OnBuiltinVoteStart(Handle hVote, Handle hPlugin, const char[] sPluginName)
{
	int iInitiator = GetBuiltinVoteInitiator(hVote);

	char sInitiatorName[32] = "Unknown";
	
	// Server (0) and clients (1-32)
	if (iInitiator >= 0 && iInitiator <= MaxClients && IsClientInGame(iInitiator)) {
		GetClientName(iInitiator, sInitiatorName, sizeof(sInitiatorName));
	}

	PrintToChatAll("[OnBuiltinVoteStart] Initiator: %s (%d), hPlugin: %x, sPluginName: %s", sInitiatorName, iInitiator, hPlugin, sPluginName);

	if (hPlugin != null) {
		char sPlName[32], sPlAuthor[32], sPlDescription[64], sPlVersion[16], sPlUrl[256];
		
		GetPluginInfo(hPlugin, PlInfo_Name, sPlName, sizeof(sPlName));
		GetPluginInfo(hPlugin, PlInfo_Author, sPlAuthor, sizeof(sPlAuthor));
		GetPluginInfo(hPlugin, PlInfo_Description, sPlDescription, sizeof(sPlDescription));
		GetPluginInfo(hPlugin, PlInfo_Version, sPlVersion, sizeof(sPlVersion));
		GetPluginInfo(hPlugin, PlInfo_URL, sPlUrl, sizeof(sPlUrl));

		PrintToChatAll("[OnBuiltinVoteStart] Plugin name: %s ", sPlName);
		PrintToChatAll("[OnBuiltinVoteStart] Plugin author: %s ", sPlAuthor);
		PrintToChatAll("[OnBuiltinVoteStart] Plugin description: %s ", sPlDescription);
		PrintToChatAll("[OnBuiltinVoteStart] Plugin version: %s ", sPlVersion);
		PrintToChatAll("[OnBuiltinVoteStart] Plugin url: %s ", sPlUrl);
		PrintToChatAll("[OnBuiltinVoteStart] Plugin status: %d", GetPluginStatus(hPlugin));
	}

	return (g_hCvarBlockBVote.IntValue == eBlockAtStart) ? Plugin_Handled : Plugin_Continue;
}

Action Cmd_BuiltinVotesCloseData(int iClient, int iArgs)
{
	if (g_hCallBackPack == null) {
		PrintToChat(iClient, "User data was not passed to the callback!");
		return Plugin_Handled;
	}

	delete g_hCallBackPack;
	g_hCallBackPack = null;

	PrintToChat(iClient, "User data was successfully deleted!");

	return Plugin_Handled;
}

Action Cmd_BuiltinVotesTest(int iClient, int iArgs)
{
	StartBuiltinVote(iClient, (iArgs == 1));

	return Plugin_Handled;
}

void StartBuiltinVote(const int iInitiator, bool bPassData = false)
{
	if (!IsNewBuiltinVoteAllowed()) {
		PrintToChat(iInitiator, "Builtinvote cannot be started now.");
		return;
	}

	int iNumPlayers;
	int[] iPlayers = new int[MaxClients];
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || IsFakeClient(i)) {
			continue;
		}

		iPlayers[iNumPlayers++] = i;
	}

	eBuiltinVoteCreateError iError;
	g_hVoteHandler = CreateBuiltinVoteEx(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End, iError);
	if (g_hVoteHandler == null) {
		PrintToChatAll("Failed to create vote. Reason %s (%d)!", g_sBuiltinVoteCreateError[iError], iError);
		return;
	}

	char sBuffer[64];
	Format(sBuffer, sizeof(sBuffer), "Builtinvote test!");
	SetBuiltinVoteArgument(g_hVoteHandler, sBuffer);
	SetBuiltinVoteInitiator(g_hVoteHandler, iInitiator);

	if (bPassData) {
		g_hCallBackPack = new DataPack();

		g_hCallBackPack.WriteString("UserData 1");
		g_hCallBackPack.WriteString("UserData 2");
		g_hCallBackPack.WriteCell(1);
		g_hCallBackPack.WriteCell(2);

		SetBuiltinVoteResultCallback(g_hVoteHandler, VoteResultHandlerUserData, g_hCallBackPack, BV_DATA_HNDL_CLOSE);
	} else {
		SetBuiltinVoteResultCallback(g_hVoteHandler, VoteResultHandler);
	}

	DisplayBuiltinVote(g_hVoteHandler, iPlayers, iNumPlayers, 20);
	//FakeClientCommand(iInitiator, "Vote Yes");
}

void VoteActionHandler(Handle hVote, BuiltinVoteAction iAction, int iParam1, int iParam2)
{
	switch (iAction) {
		case BuiltinVoteAction_End: {
			g_hVoteHandler = null;
			g_hCallBackPack = null;
			delete hVote;
		}
		case BuiltinVoteAction_Cancel: {
			DisplayBVoteResult(hVote, eVoteFail);
		}
	}
}

void VoteResultHandlerUserData(Handle hVote, int iNumVotes, int iNumClients, \
									const int[][] iClientInfo, int iNumItems, const int[][] iItemInfo, DataPack hPack)
{
	for (int i = 0; i < iNumItems; i++) {
		if (iItemInfo[i][BUILTINVOTEINFO_ITEM_INDEX] != BUILTINVOTES_VOTE_YES) {
			continue;
		}

		if (iItemInfo[i][BUILTINVOTEINFO_ITEM_VOTES] > (iNumClients / 2)) {
			hPack.Reset();

			char sBuffer1[32], sBuffer2[32];
			hPack.ReadString(sBuffer1, sizeof(sBuffer1));
			hPack.ReadString(sBuffer2, sizeof(sBuffer2));

			int iBuff1 = hPack.ReadCell();
			int iBuff2 = hPack.ReadCell();
			PrintToChatAll("String1: %s, String2: %s, int1: %d, int2: %d", sBuffer1, sBuffer2, iBuff1, iBuff2);

			DisplayBVoteResult(hVote, eVotePass, "Builtinvote test end...");

			return;
		}
	}

	DisplayBVoteResult(hVote, eVoteFail);
}

void VoteResultHandler(Handle hVote, int iNumVotes, int iNumClients, \
									const int[][] iClientInfo, int iNumItems, const int[][] iItemInfo)
{
	for (int i = 0; i < iNumItems; i++) {
		if (iItemInfo[i][BUILTINVOTEINFO_ITEM_INDEX] != BUILTINVOTES_VOTE_YES) {
			continue;
		}

		if (iItemInfo[i][BUILTINVOTEINFO_ITEM_VOTES] > (iNumClients / 2)) {
			DisplayBVoteResult(hVote, eVotePass, "Builtinvote test end...");

			return;
		}
	}

	DisplayBVoteResult(hVote, eVoteFail);
}

void DisplayBVoteResult(Handle hVote, int iResultType, char[] sPassArg = "")
{
	if (!g_hCvarDisplayBVoteResult.BoolValue) {
		return;
	}

	if (iResultType == eVotePass) {
		DisplayBuiltinVotePass(hVote, sPassArg);

		return;
	}

	DisplayBuiltinVoteFail(hVote, BuiltinVoteFail_Loses);
}