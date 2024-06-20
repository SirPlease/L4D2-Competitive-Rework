#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <builtinvotes>
#undef REQUIRE_PLUGIN
#include <confogl>
#include <colors>

#define TEAM_SPECTATE	1
#define MATCHMODES_PATH "configs/matchmodes.txt"

Handle
	g_hVote = null;

KeyValues
	g_hModesKV = null;

ConVar
	g_hEnabled		   = null,
	g_hCvarPlayerLimit = null,
	g_hMaxPlayers	   = null,
	g_hSvMaxPlayers	   = null;

char
	g_sCfg[32];

bool
	g_bIsConfoglAvailable = false,
	g_bOnSet			  = false,
	g_bCedaGame			  = false,
	g_bShutdown			  = false;

public Plugin myinfo =
{
	name		= "Match Vote",
	author		= "vintik, Sir, StarterX4",
	description = "!match !rmatch !chmatch - Change Hostname and Slots while you're at it!",
	version		= "1.4",
	url			= "https://github.com/L4D-Community/L4D2-Competitive-Framework"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	EngineVersion iEngine = GetEngineVersion();
	if (iEngine != Engine_Left4Dead2)
	{
		strcopy(sError, iErrMax, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	char sBuffer[PLATFORM_MAX_PATH];
	g_hModesKV = new KeyValues("MatchModes");
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), MATCHMODES_PATH);

	if (!g_hModesKV.ImportFromFile(sBuffer))
		SetFailState("Couldn't load matchmodes.txt!");

	LoadTranslation("match_vote.phrases");

	g_hEnabled		   = CreateConVar("sm_match_vote_enabled", "1", "Plugin enabled", _, true, 0.0, true, 1.0);
	g_hMaxPlayers	   = CreateConVar("mv_maxplayers", "30", "How many slots would you like the Server to be at Config Load/Unload?", _, true, 1.0, true, 32.0);
	g_hCvarPlayerLimit = CreateConVar("sm_match_player_limit", "1", "Minimum # of players in game to start the vote", _, true, 1.0, true, 32.0);

	RegConsoleCmd("sm_match", MatchRequest);
	RegConsoleCmd("sm_chmatch", ChangeMatchRequest);
	RegConsoleCmd("sm_rmatch", MatchReset);

	AddCommandListener(Listener_Quit, "quit");
	AddCommandListener(Listener_Quit, "_restart");
	AddCommandListener(Listener_Quit, "crash");

	g_hSvMaxPlayers		  = FindConVar("sv_maxplayers");
	g_bIsConfoglAvailable = LibraryExists("confogl");
}

public void OnConfigsExecuted()
{
	if (!g_bOnSet)
	{
		g_hSvMaxPlayers.SetInt(g_hMaxPlayers.IntValue);
		g_bOnSet = true;
	}
}

Action Listener_Quit(int iClient, const char[] sCommand, int iArgc)
{
	g_bShutdown = true;
	return Plugin_Continue;
}

public void OnPluginEnd()
{
	if (g_bShutdown)
		return;

	g_hSvMaxPlayers.SetInt(g_hMaxPlayers.IntValue);
}

public void OnLibraryRemoved(const char[] sPluginName)
{
	if (strcmp(sPluginName, "confogl") == 0)
		g_bIsConfoglAvailable = false;
}

public void OnLibraryAdded(const char[] sPluginName)
{
	if (strcmp(sPluginName, "confogl") == 0)
		g_bIsConfoglAvailable = true;
}

public void OnCedapugStarted()
{
	g_bCedaGame = true;
}

public void OnCedapugEnded()
{
	g_bCedaGame = false;
}

Action MatchRequest(int iClient, int iArgs)
{
	if (!g_hEnabled.BoolValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "Disabled");
		return Plugin_Handled;
	}

	if (!iClient)
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "NoConsole");
		return Plugin_Handled;
	}

	if (!g_bIsConfoglAvailable)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "ConfoglNotAvailable");
		return Plugin_Handled;
	}

	if (LGO_IsMatchModeLoaded())
	{
		ChangeMatchRequest(iClient, iArgs);
		// CPrintToChat(iClient, "%t %t", "Tag", "MatchLoaded");
		return Plugin_Handled;
	}

	if (iArgs > 0)
	{
		// config specified
		char sCfg[64], sName[64];
		GetCmdArg(1, sCfg, sizeof(sCfg));

		if (FindConfigName(sCfg, sName, sizeof(sName)))
		{
			if (StartMatchVote(iClient, sName))
			{
				strcopy(g_sCfg, sizeof(g_sCfg), sCfg);

				// caller is voting for
				FakeClientCommand(iClient, "Vote Yes");
			}

			return Plugin_Handled;
		}
	}

	// show main menu
	MatchModeMenu(iClient);
	return Plugin_Handled;
}

bool FindConfigName(const char[] sConfig, char[] sName, const int iMaxLength)
{
	g_hModesKV.Rewind();

	if (g_hModesKV.GotoFirstSubKey())
	{
		do
		{
			if (g_hModesKV.JumpToKey(sConfig))
			{
				g_hModesKV.GetString("name", sName, iMaxLength);
				return true;
			}
		}
		while (g_hModesKV.GotoNextKey(false));
	}

	return false;
}

void MatchModeMenu(int iClient)
{
	char sTitle[64];
	Format(sTitle, sizeof(sTitle), "%t", "Title_Match");

	Menu hMenu = new Menu(MatchModeMenuHandler);
	hMenu.SetTitle(sTitle);

	char sBuffer[64];
	g_hModesKV.Rewind();

	if (g_hModesKV.GotoFirstSubKey())
	{
		do
		{
			g_hModesKV.GetSectionName(sBuffer, sizeof(sBuffer));
			hMenu.AddItem(sBuffer, sBuffer);
		}
		while (g_hModesKV.GotoNextKey(false));
	}

	hMenu.Display(iClient, 20);
}

int MatchModeMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		char sInfo[64], sBuffer[64];
		menu.GetItem(param2, sInfo, sizeof(sInfo));

		g_hModesKV.Rewind();

		if (g_hModesKV.JumpToKey(sInfo) && g_hModesKV.GotoFirstSubKey())
		{
			char sTitle[64];
			Format(sTitle, sizeof(sTitle), "%t", "Title_Config", sInfo);

			Menu hMenu = new Menu(ConfigsMenuHandler);
			hMenu.SetTitle(sTitle);

			do
			{
				g_hModesKV.GetSectionName(sInfo, sizeof(sInfo));
				g_hModesKV.GetString("name", sBuffer, sizeof(sBuffer));

				hMenu.AddItem(sInfo, sBuffer);
			}
			while (g_hModesKV.GotoNextKey());

			hMenu.Display(param1, 20);
		}
		else
		{
			CPrintToChat(param1, "%t %t", "Tag", "ConfigNotFound");
			MatchModeMenu(param1);
		}
	}

	return 0;
}

int ConfigsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
		delete menu;
	else if (action == MenuAction_Cancel)
		MatchModeMenu(param1);
	else if (action == MenuAction_Select)
	{
		char sInfo[64], sBuffer[64];
		menu.GetItem(param2, sInfo, sizeof(sInfo), _, sBuffer, sizeof(sBuffer));

		if (StartMatchVote(param1, sBuffer))
		{
			strcopy(g_sCfg, sizeof(g_sCfg), sInfo);
			// caller is voting for
			FakeClientCommand(param1, "Vote Yes");
		}
		else
			MatchModeMenu(param1);
	}

	return 0;
}

bool StartMatchVote(int iClient, const char[] sCfgName)
{
	if (GetClientTeam(iClient) <= TEAM_SPECTATE)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NoSpec");
		return false;
	}

	if (IsBuiltinVoteInProgress())
	{
		CPrintToChat(iClient, "%t %t", "Tag", "VoteInProgress", CheckBuiltinVoteDelay());
		return false;
	}

	int[] iPlayers = new int[MaxClients];
	int iNumPlayers = 0;
	int iConnectedCount = ProcessPlayers(iPlayers, iNumPlayers);

	if (iConnectedCount > 0)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "PlayersConnecting");
		return false;
	}

	if (iNumPlayers < g_hCvarPlayerLimit.IntValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NotEnoughPlayers", iNumPlayers, g_hCvarPlayerLimit.IntValue);
		return false;
	}

	char sTitle[64];
	Format(sTitle, sizeof(sTitle), "%T", "Title_LoadConfig", LANG_SERVER, sCfgName);

	g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
	SetBuiltinVoteArgument(g_hVote, sTitle);
	SetBuiltinVoteInitiator(g_hVote, iClient);
	SetBuiltinVoteResultCallback(g_hVote, MatchVoteResultHandler);
	DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);
	return true;
}

void VoteActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
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

void MatchVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i = 0; i < num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{
				char sVotepass[64];
				Format(sVotepass, sizeof(sVotepass), "%T", "VotePass_Loading", LANG_SERVER);

				DisplayBuiltinVotePass(vote, sVotepass);
				ServerCommand("sm_forcematch %s", g_sCfg);
				return;
			}
		}
	}

	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

Action MatchReset(int iClient, int iArgs)
{
	if (!g_hEnabled.BoolValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "Disabled");
		return Plugin_Handled;
	}

	if (!iClient)
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "NoConsole");
		return Plugin_Handled;
	}

	if (!g_bIsConfoglAvailable)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "ConfoglNotAvailable");
		return Plugin_Handled;
	}

	if (g_bCedaGame)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "CedaGame");
		return Plugin_Handled;
	}

	if (!LGO_IsMatchModeLoaded())
	{
		CPrintToChat(iClient, "%t %t", "Tag", "MatchNotLoaded");
		return Plugin_Handled;
	}

	// voting for resetmatch
	StartResetMatchVote(iClient);
	return Plugin_Handled;
}

bool StartResetMatchVote(int iClient)
{
	if (GetClientTeam(iClient) <= TEAM_SPECTATE)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NoSpec");
		return false;
	}

	if (IsBuiltinVoteInProgress())
	{
		CPrintToChat(iClient, "%t %t", "Tag", "VoteInProgress", CheckBuiltinVoteDelay());
		return false;
	}

	int[] iPlayers = new int[MaxClients];
	int iNumPlayers = 0;
	int iConnectedCount = ProcessPlayers(iPlayers, iNumPlayers);

	if (iConnectedCount > 0)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "PlayersConnecting");
		return false;
	}

	char sTitle[64];
	Format(sTitle, sizeof(sTitle), "%T", "Title_OffConfogl", LANG_SERVER);

	g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
	SetBuiltinVoteArgument(g_hVote, sTitle);
	SetBuiltinVoteInitiator(g_hVote, iClient);
	SetBuiltinVoteResultCallback(g_hVote, ResetMatchVoteResultHandler);
	DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);

	FakeClientCommand(iClient, "Vote Yes");
	return true;
}

void ResetMatchVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i = 0; i < num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{
				char sVotepass[24];
				Format(sVotepass, sizeof(sVotepass), "%T", "VotePass_Unloading", LANG_SERVER);

				DisplayBuiltinVotePass(vote, sVotepass);
				ServerCommand("sm_resetmatch");
				return;
			}
		}
	}

	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

Action ChangeMatchRequest(int iClient, int iArgs)
{
	if (!g_hEnabled.BoolValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "Disabled");
		return Plugin_Handled;
	}

	if (!iClient)
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "NoConsole");
		return Plugin_Handled;
	}

	if (!g_bIsConfoglAvailable)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "ConfoglNotAvailable");
		return Plugin_Handled;
	}

	if (g_bCedaGame)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "CedaGame");
		return Plugin_Handled;
	}

	if (!LGO_IsMatchModeLoaded())
	{
		MatchRequest(iClient, iArgs);
		// CPrintToChat(iClient, "%t %t", "Tag", "MatchNotLoaded");
		return Plugin_Handled;
	}

	if (iArgs > 0)
	{
		// config specified
		char sCfg[64], sName[64];
		GetCmdArg(1, sCfg, sizeof(sCfg));
		if (FindConfigName(sCfg, sName, sizeof(sName)))
		{
			if (StartChMatchVote(iClient, sName))
			{
				strcopy(g_sCfg, sizeof(g_sCfg), sCfg);

				// caller is voting for
				FakeClientCommand(iClient, "Vote Yes");
			}
			return Plugin_Handled;
		}
	}

	// show main menu
	ChMatchModeMenu(iClient);
	return Plugin_Handled;
}

void ChMatchModeMenu(int iClient)
{
	char sTitle[64];
	Format(sTitle, sizeof(sTitle), "%t", "Title_Match");

	Menu hMenu = new Menu(ChMatchModeMenuHandler);
	hMenu.SetTitle(sTitle);

	char sBuffer[64];
	g_hModesKV.Rewind();

	if (g_hModesKV.GotoFirstSubKey())
	{
		do
		{
			g_hModesKV.GetSectionName(sBuffer, sizeof(sBuffer));
			hMenu.AddItem(sBuffer, sBuffer);
		}
		while (g_hModesKV.GotoNextKey(false));
	}

	hMenu.Display(iClient, 20);
}

int ChMatchModeMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		char sInfo[64], sBuffer[64];
		menu.GetItem(param2, sInfo, sizeof(sInfo));

		g_hModesKV.Rewind();

		if (g_hModesKV.JumpToKey(sInfo) && g_hModesKV.GotoFirstSubKey())
		{
			char sTitle[64];
			Format(sTitle, sizeof(sTitle), "%t", "Title_Config", sInfo);

			Menu hMenu = new Menu(ChConfigsMenuHandler);
			hMenu.SetTitle(sTitle);

			do
			{
				g_hModesKV.GetSectionName(sInfo, sizeof(sInfo));
				g_hModesKV.GetString("name", sBuffer, sizeof(sBuffer));

				hMenu.AddItem(sInfo, sBuffer);
			}
			while (g_hModesKV.GotoNextKey());

			hMenu.Display(param1, 20);
		}
		else
		{
			CPrintToChat(param1, "%t %t", "Tag", "ConfigNotFound");
			ChMatchModeMenu(param1);
		}
	}

	return 0;
}

int ChConfigsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		ChMatchModeMenu(param1);
	}
	else if (action == MenuAction_Select)
	{
		char sInfo[64], sBuffer[64];
		menu.GetItem(param2, sInfo, sizeof(sInfo), _, sBuffer, sizeof(sBuffer));

		if (StartChMatchVote(param1, sBuffer))
		{
			strcopy(g_sCfg, sizeof(g_sCfg), sInfo);
			// caller is voting for
			FakeClientCommand(param1, "Vote Yes");
		}
		else
			ChMatchModeMenu(param1);
	}

	return 0;
}

bool StartChMatchVote(int iClient, const char[] sCfgName)
{
	if (GetClientTeam(iClient) <= TEAM_SPECTATE)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NoSpec");
		return false;
	}

	if (IsBuiltinVoteInProgress())
	{
		CPrintToChat(iClient, "%t %t", "Tag", "VoteInProgress", CheckBuiltinVoteDelay());
		return false;
	}

	int[] iPlayers = new int[MaxClients];
	int iNumPlayers = 0;
	int iConnectedCount = ProcessPlayers(iPlayers, iNumPlayers);

	if (iNumPlayers < g_hCvarPlayerLimit.IntValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NotEnoughPlayers");
		return false;
	}

	if (iConnectedCount > 0)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "PlayersConnecting");
		return false;
	}

	char sTitle[64];
	Format(sTitle, sizeof(sTitle), "%T", "Title_ChangeConfogl", LANG_SERVER, sCfgName);

	g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
	SetBuiltinVoteArgument(g_hVote, sTitle);
	SetBuiltinVoteInitiator(g_hVote, iClient);
	SetBuiltinVoteResultCallback(g_hVote, ChMatchVoteResultHandler);
	DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);

	return true;
}

void ChMatchVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i = 0; i < num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{
				char sVotepass[24];
				Format(sVotepass, sizeof(sVotepass), "%T", "VotePass_Changed", LANG_SERVER);

				DisplayBuiltinVotePass(vote, sVotepass);
				ServerCommand("sm_forcechangematch %s", g_sCfg);
				return;
			}
		}
	}

	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

/**
 * Check if the translation file exists
 *
 * @param translation	Translation name.
 * @noreturn
 */
stock void LoadTranslation(const char[] translation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}


/**
 * Processes the players in the game and populates the given array with their indices.
 *
 * @param iPlayers The array to store the indices of the players.
 * @param iNumPlayers A reference to the variable that will hold the number of players.
 * @return The number of connected clients in the game.
 */
int ProcessPlayers(int[] iPlayers, int &iNumPlayers)
{
	int iConnectedCount = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			if (IsClientConnected(i))
				iConnectedCount++;
		}
		else
		{
			if (!IsFakeClient(i) && GetClientTeam(i) > TEAM_SPECTATE)
				iPlayers[iNumPlayers++] = i;
		}
	}

	return iConnectedCount;
}