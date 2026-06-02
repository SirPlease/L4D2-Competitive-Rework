
#include <sourcemod>
#include <builtinvotes>
//get here: https://forums.alliedmods.net/showthread.php?t=162164

#undef REQUIRE_PLUGIN
#include <confogl>
#include <colors>
#define REQUIRE_PLUGIN
//get proper version here: https://bitbucket.org/vintik/confogl-old

#define L4D_TEAM_SPECTATE	1
#define MATCHMODES_PATH		"configs/matchmodes.txt"

new Handle:g_hVote;
new Handle:g_hModesKV;
new Handle:g_hCvarPlayerLimit;
new Handle:g_hMaxPlayers;
new Handle:g_hSvMaxPlayers;
new String:g_sCfg[32];
new bool:g_bIsConfoglAvailable;
new bool:OnSet

public Plugin:myinfo = 
{
	name = "Match Vote",
	author = "vintik, Sir",
	description = "!match !rmatch - Change Hostname and Slots while you're at it!",
	version = "1.1.3",
	url = "https://bitbucket.org/vintik/various-plugins"
}

public OnPluginStart()
{
	decl String:sBuffer[128];
	GetGameFolderName(sBuffer, sizeof(sBuffer));
	if (!StrEqual(sBuffer, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 dead 2 only!");
	}
	g_hModesKV = CreateKeyValues("MatchModes");
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), MATCHMODES_PATH);
	if (!FileToKeyValues(g_hModesKV, sBuffer))
	{
		SetFailState("Couldn't load matchmodes.txt!");
	}
	
	g_hSvMaxPlayers = FindConVar("sv_maxplayers");
	g_hMaxPlayers = CreateConVar("mv_maxplayers", "8", "How many slots would you like the Server to be at Config Load/Unload?");
	RegConsoleCmd("sm_match", MatchRequest);
	RegConsoleCmd("sm_rmatch", MatchReset);
	
	g_hCvarPlayerLimit = CreateConVar("sm_match_player_limit", "1", "Minimum # of players in game to start the vote");
	g_bIsConfoglAvailable = LibraryExists("confogl");
}

public OnConfigsExecuted()
{
	if (!OnSet)
	{
		SetConVarInt(g_hSvMaxPlayers, GetConVarInt(g_hMaxPlayers));
		OnSet = true;
	}
}

public OnPluginEnd()
{
	SetConVarInt(g_hSvMaxPlayers, GetConVarInt(g_hMaxPlayers));
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "confogl")) g_bIsConfoglAvailable = false;
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "confogl")) g_bIsConfoglAvailable = true;
}

public Action:MatchRequest(client, args)
{
	if ((!client) || (!g_bIsConfoglAvailable)) return Plugin_Handled;
	if (args > 0)
	{
		//config specified
		new String:sCfg[64], String:sName[64];
		GetCmdArg(1, sCfg, sizeof(sCfg));
		if (FindConfigName(sCfg, sName, sizeof(sName)))
		{
			if (StartMatchVote(client, sName))
			{
				strcopy(g_sCfg, sizeof(g_sCfg), sCfg);
				//caller is voting for
				FakeClientCommand(client, "Vote Yes");
			}
			return Plugin_Handled;
		}
	}
	//show main menu
	MatchModeMenu(client);
	return Plugin_Handled;
}

bool:FindConfigName(const String:cfg[], String:name[], maxlength)
{
	KvRewind(g_hModesKV);
	if (KvGotoFirstSubKey(g_hModesKV))
	{
		do
		{
			if (KvJumpToKey(g_hModesKV, cfg))
			{
				KvGetString(g_hModesKV, "name", name, maxlength);
				return true;
			}
		} while (KvGotoNextKey(g_hModesKV, false));
	}
	return false;
}

MatchModeMenu(client)
{
	new Handle:hMenu = CreateMenu(MatchModeMenuHandler);
	SetMenuTitle(hMenu, "选择比赛模式:");
	new String:sBuffer[64];
	KvRewind(g_hModesKV);
	if (KvGotoFirstSubKey(g_hModesKV))
	{
		do
		{
			KvGetSectionName(g_hModesKV, sBuffer, sizeof(sBuffer));
			AddMenuItem(hMenu, sBuffer, sBuffer);
		} while (KvGotoNextKey(g_hModesKV, false));
	}
	DisplayMenu(hMenu, client, 20);
}

public MatchModeMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:sInfo[64], String:sBuffer[64];
		GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
		KvRewind(g_hModesKV);
		if (KvJumpToKey(g_hModesKV, sInfo) && KvGotoFirstSubKey(g_hModesKV))
		{
			new Handle:hMenu = CreateMenu(ConfigsMenuHandler);
			Format(sBuffer, sizeof(sBuffer), "选择 %s 配置:", sInfo);
			SetMenuTitle(hMenu, sBuffer);
			do
			{
				KvGetSectionName(g_hModesKV, sInfo, sizeof(sInfo));
				KvGetString(g_hModesKV, "name", sBuffer, sizeof(sBuffer));
				AddMenuItem(hMenu, sInfo, sBuffer);
			} while (KvGotoNextKey(g_hModesKV));
			DisplayMenu(hMenu, param1, 20);
		}
		else
		{
			CPrintToChat(param1, "{blue}[{default}Match{blue}] {default}没有找到这个模式的参数.");
			MatchModeMenu(param1);
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public ConfigsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:sInfo[64], String:sBuffer[64];
		GetMenuItem(menu, param2, sInfo, sizeof(sInfo), _, sBuffer, sizeof(sBuffer));
		if (StartMatchVote(param1, sBuffer))
		{
			strcopy(g_sCfg, sizeof(g_sCfg), sInfo);
			//caller is voting for
			FakeClientCommand(param1, "Vote Yes");
		}
		else
		{
			MatchModeMenu(param1);
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	if (action == MenuAction_Cancel)
	{
		MatchModeMenu(param1);
	}
}

bool:StartMatchVote(client, const String:cfgname[])
{
	if (GetClientTeam(client) == L4D_TEAM_SPECTATE)
	{
		CPrintToChat(client, "{blue}[{default}Match{blue}] {default}旁观者不允许发起比赛模式更改投票.");
		return false;
	}
	/*
	if (LGO_IsMatchModeLoaded())
	{
		CPrintToChat(client, "{blue}[{default}Match{blue}] {default}比赛模式已经加载!");
		return false;
	}
	*/
	if (!IsBuiltinVoteInProgress())
	{
		new iNumPlayers;
		decl iPlayers[MaxClients];
		//list of non-spectators players
		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == L4D_TEAM_SPECTATE))
			{
				continue;
			}
			iPlayers[iNumPlayers++] = i;
		}
		if (iNumPlayers < GetConVarInt(g_hCvarPlayerLimit))
		{
			CPrintToChat(client, "{blue}[{default}Match{blue}] {default}比赛投票暂不能使用，因为玩家不够.");
			return false;
		}
		new String:sBuffer[64];
		g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
		Format(sBuffer, sizeof(sBuffer), "加载 confogl '%s' 配置?", cfgname);
		SetBuiltinVoteArgument(g_hVote, sBuffer);
		SetBuiltinVoteInitiator(g_hVote, client);
		SetBuiltinVoteResultCallback(g_hVote, MatchVoteResultHandler);
		DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);
		return true;
	}
	CPrintToChat(client, "{blue}[{default}Match{blue}] {default}比赛投票目前暂不能使用.");
	return false;
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

public void MatchVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (new i=0; i<num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{
				DisplayBuiltinVotePass(vote, "加载比赛模式");
				ServerCommand("sm_forcematch %s", g_sCfg);
				return;
			}
		}
	}
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

public Action:MatchReset(client, args)
{
	if ((!client) || (!g_bIsConfoglAvailable)) return Plugin_Handled;
	//voting for resetmatch
	StartResetMatchVote(client);
	return Plugin_Handled;
}

StartResetMatchVote(client)
{
	if (GetClientTeam(client) == L4D_TEAM_SPECTATE)
	{
		CPrintToChat(client, "{blue}[{default}Match{blue}] {default}旁观者不允许重置比赛模式.");
		return;
	}
	/*
	if (!LGO_IsMatchModeLoaded())
	{
		CPrintToChat(client, "{blue}[{default}Match{blue}] {default}没有比赛模式加载.");
		return;
	}
	*/
	if (IsNewBuiltinVoteAllowed())
	{
		new iNumPlayers;
		decl iPlayers[MaxClients];
		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == L4D_TEAM_SPECTATE))
			{
				continue;
			}
			iPlayers[iNumPlayers++] = i;
		}
		if (ConnectingPlayers() > 0)
		{
			CPrintToChat(client, "{blue}[{default}Match{blue}] {default}重置比赛投票暂不能使用，有人正在加入游戏");
			return;
		}
		g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
		SetBuiltinVoteArgument(g_hVote, "关闭confogl?");
		SetBuiltinVoteInitiator(g_hVote, client);
		SetBuiltinVoteResultCallback(g_hVote, ResetMatchVoteResultHandler);
		DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);
		FakeClientCommand(client, "Vote Yes");
		return;
	}
	CPrintToChat(client, "{blue}[{default}Match{blue}] {default}重置比赛投票暂不能使用.");
}

public void ResetMatchVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (new i=0; i<num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{
				DisplayBuiltinVotePass(vote, "Confogl 正在卸载模式...");
				ServerCommand("sm_resetmatch");
				return;
			}
		}
	}
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

ConnectingPlayers()
{
	new Clients = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) && IsClientConnected(i))
			
		Clients++;
	}
	return Clients;
}