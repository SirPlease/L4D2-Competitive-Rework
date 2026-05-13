#if defined _l4d_stats_lifecycle_included
	#endinput
#endif
#define _l4d_stats_lifecycle_included

// 地图、玩家连接/断开和 ConVar 变化生命周期。

// Reset all boolean variables when a map changes.

public OnMapStart()
{
	GetConVarString(cvar_Gamemode, CurrentGamemode, sizeof(CurrentGamemode));
	CurrentGamemodeID = GetCurrentGamemodeID();
	SetCurrentGamemodeName();
	QuarterRank_EnsureCurrentQuarter();
	ResetVars();
}

// Init player on connect, and update total rank and client rank.

public OnClientPostAdminCheck(client)
{
	if (db == INVALID_HANDLE)
	{
		return;
	}

	InitializeClientInf(client);
	PostAdminCheckRetryCounter[client] = 0;

	if (IsClientBot(client))
	{
		return;
	}

	CreateTimer(1.0, ClientPostAdminCheck, client);
}

public Action:ClientPostAdminCheck(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		if (PostAdminCheckRetryCounter[client]++ < 10)
		{
			CreateTimer(3.0, ClientPostAdminCheck, client);
		}

		return;
	}

	StartRankChangeCheck(client);

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	CheckPlayerDB(client);
	QuarterRank_QueryClient(client);

	TimerPoints[client] = 0;
	TimerKills[client] = 0;
	TimerHeadshots[client] = 0;

	CreateTimer(10.0, RankConnect, client);
	CreateTimer(15.0, AnnounceConnect, client);

	AnnouncePlayerConnect(client);
}

public OnPluginEnd()
{
	if (db == INVALID_HANDLE)
		return;

	new maxplayers = MaxClients;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			switch (GetClientTeam(i))
			{
				case TEAM_SURVIVORS:
					InterstitialPlayerUpdate(i);
				case TEAM_INFECTED:
					DoInfectedFinalChecks(i);
			}
		}
	}

	CloseHandle(db);
	db = INVALID_HANDLE;

	CommandsRegistered = false;

	//if (ClearPlayerMenu != INVALID_HANDLE)
	//{
	//	CloseHandle(ClearPlayerMenu);
	//	ClearPlayerMenu = INVALID_HANDLE;
	//}
	delete MapTimingSurvivors; 
 	delete MapTimingInfected; 
 	delete FriendlyFireDamageTrie; 
 	delete PlayerRankVoteTrie; 
}

// Show rank on connect.

public Action:RankConnect(Handle:timer, any:value)
{
	if (GetConVarBool(cvar_RankOnJoin) && !InvalidGameMode())
	{
		cmd_ShowRank(value, 0);
	}
}

// Announce on player connect!

public Action:AnnounceConnect(Handle:timer, any:client)
{
	if (!GetConVarBool(cvar_AnnounceMode))
	{
		return;
	}

	if (!IsClientConnected(client) || !IsClientInGame(client))
	{
		if (AnnounceCounter[client] > 10)
		{
			AnnounceCounter[client] = 0;
		}
		else
		{
			AnnounceCounter[client]++;
			CreateTimer(5.0, AnnounceConnect, client);
		}

		return;
	}

	AnnounceCounter[client]++;
	Call_StartForward(AnnounceGameTime);//转发触发
	Call_PushCell(client);//按顺序将参数push进forward传参列表里
	Call_Finish();//转发结束

	ShowMOTD(client);
	StatsPrintToChat2(client, true, "输入 \x05rankmenu \x01来操作 \x04%s\x01!", PLUGIN_NAME);
}

// Update the player's interstitial stats, since they may have
// gotten points between the last update and when they disconnect.

public OnClientDisconnect(client)
{
	InitializeClientInf(client);
	PlayerRankVote[client] = RANKVOTE_NOVOTE;
	ClientRankMute[client] = false;
	QuarterRankChangeLastRank[client] = 0;
	QuarterRankChangeFirstCheck[client] = true;

	if (TimerRankChangeCheck[client] != INVALID_HANDLE)
		CloseHandle(TimerRankChangeCheck[client]);

	TimerRankChangeCheck[client] = INVALID_HANDLE;

	if (IsClientBot(client))
		return;

	if (MapTimingStartTime >= 0.0)
	{
		decl String:ClientID[MAX_LINE_WIDTH];
		GetClientRankAuthString(client, ClientID, sizeof(ClientID));

		RemoveFromTrie(MapTimingSurvivors, ClientID);
		RemoveFromTrie(MapTimingInfected, ClientID);
	}

	if (IsClientInGame(client))
	{
		switch (GetClientTeam(client))
		{
			case TEAM_SURVIVORS:
				InterstitialPlayerUpdate(client);
			case TEAM_INFECTED:
				DoInfectedFinalChecks(client);
		}
	}

	new maxplayers = MaxClients;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (i != client && IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			return;
	}

	// If we get this far, ALL HUMAN PLAYERS LEFT THE SERVER
	CampaignOver = true;

	if (RankVoteTimer != INVALID_HANDLE)
	{
		CloseHandle(RankVoteTimer);
		RankVoteTimer = INVALID_HANDLE;
	}
}

public action_LanChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarInt(cvar_Lan))
		LogMessage("ATTENTION! %s in LAN environment is based on IP address rather than Steam ID. The statistics are not reliable when they are base on IP!", PLUGIN_NAME);
}

// Update the Database prefix when the Cvar is changed.

public action_DbPrefixChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_DbPrefix)
	{
		if (StrEqual(DbPrefix, newValue))
			return;

		if (db != INVALID_HANDLE && !CheckDatabaseValidity(DbPrefix))
		{
			strcopy(DbPrefix, sizeof(DbPrefix), oldValue);
			SetConVarString(cvar_DbPrefix, DbPrefix);
		}
		else
			strcopy(DbPrefix, sizeof(DbPrefix), newValue);
	}
}

// Update the Update Timer when the Cvar is changed.

public action_TimerChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_UpdateRate)
	{
		CloseHandle(UpdateTimer);

		new NewTime = StringToInt(newValue);
		UpdateTimer = CreateTimer(float(NewTime), timer_ShowTimerScore, INVALID_HANDLE, TIMER_REPEAT);
	}
}

// Update the CurrentGamemode when the Cvar is changed.

public action_DifficultyChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_Difficulty)
	{
		MapTimingStartTime = -1.0;
		MapTimingBlocked = true;
	}
}

// Update the CurrentGamemode when the Cvar is changed.

public action_GamemodeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_Gamemode)
	{
		GetConVarString(cvar_Gamemode, CurrentGamemode, sizeof(CurrentGamemode));
		CurrentGamemodeID = GetCurrentGamemodeID();
		SetCurrentGamemodeName();
	}
}
