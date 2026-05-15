#if defined _l4d_stats_output_rank_timing_included
	#endinput
#endif
#define _l4d_stats_output_rank_timing_included

// 聊天输出、地图计时、队伍洗牌辅助、MOTD 和 Anne 模式辅助。

// Print a chat message to a specific team instead of all players

public StatsPrintToChatTeam(Team, const String:Message[], any:...)
{
	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 3);

	new AnnounceToTeam = GetConVarInt(cvar_AnnounceToTeam);

	if (Team > 0 && AnnounceToTeam)
	{
		new maxplayers = MaxClients;
		new ClientTeam;

		for (new i = 1; i <= maxplayers; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			{
				ClientTeam = GetClientTeam(i);
				if (ClientTeam == Team || (ClientTeam == TEAM_SPECTATORS && AnnounceToTeam == 2))
				{
					StatsPrintToChatPreFormatted(i, FormattedMessage);
				}
			}
		}
	}
	else
		StatsPrintToChatAllPreFormatted(FormattedMessage);
}

// Debugging...
/*
public PrintToConsoleAll(const String:Message[], any:...)
{
	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 2);

	PrintToConsole(0, FormattedMessage);

	new maxplayers = MaxClients;

	for (new i = 1; i <= maxplayers; i++)
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			PrintToConsole(i, FormattedMessage);
}*/

// Disable map timings when opposing team has human players. The time is too much depending on opposing team that is is comparable.

MapTimingEnabled()
{
	return MapTimingBlocked || CurrentGamemodeID == GAMEMODE_COOP || CurrentGamemodeID == GAMEMODE_SURVIVAL || CurrentGamemodeID == GAMEMODE_REALISM || CurrentGamemodeID == GAMEMODE_OTHERMUTATIONS;
}

MapTimingRuns_EnsureTable()
{
	decl String:query[2048];
	Format(query, sizeof(query),
		"CREATE TABLE IF NOT EXISTS `%stimedmap_runs` ("
		... "`run_id` varchar(64) NOT NULL,"
		... "`map` varchar(255) CHARACTER SET utf8mb4 NOT NULL,"
		... "`gamemode` int(1) unsigned NOT NULL,"
		... "`difficulty` int(1) unsigned NOT NULL,"
		... "`steamid` varchar(255) CHARACTER SET utf8mb4 NOT NULL,"
		... "`time` double NOT NULL,"
		... "`players` int(2) NOT NULL,"
		... "`mutation` varchar(64) CHARACTER SET utf8mb4 NOT NULL DEFAULT '',"
		... "`mode` int(1) unsigned NOT NULL DEFAULT '0',"
		... "`sinum` int(1) unsigned NOT NULL DEFAULT '0',"
		... "`sitime` int(1) unsigned NOT NULL DEFAULT '0',"
		... "`usebuy` int(1) unsigned NOT NULL DEFAULT '0',"
		... "`auto` int(1) unsigned NOT NULL DEFAULT '0',"
		... "`anneversion` varchar(64) CHARACTER SET utf8mb4 NOT NULL DEFAULT 'None',"
		... "`created` datetime NOT NULL,"
		... "`modified` datetime NOT NULL,"
		... "PRIMARY KEY (`run_id`,`steamid`),"
		... "KEY `idx_timedmap_runs_filter_time` (`map`,`mode`,`difficulty`,`sinum`,`sitime`,`usebuy`,`anneversion`,`time`),"
		... "KEY `idx_timedmap_runs_steamid` (`steamid`,`modified`)"
		... ") ENGINE=InnoDB DEFAULT CHARSET=utf8",
		DbPrefix);
	DoFastQuery(0, query);
}

MapTimingRuns_RecordParticipant(const String:RunID[], const String:MapName[], GamemodeID, const String:ClientID[], Float:TotalTime, PlayerCounter, GameDifficulty, const String:Mutation[], Mode)
{
	decl String:query[2048];
	Format(query, sizeof(query),
		"INSERT IGNORE INTO `%stimedmap_runs` "
		... "(`run_id`,`map`,`gamemode`,`difficulty`,`steamid`,`time`,`players`,`mutation`,`mode`,`sinum`,`sitime`,`usebuy`,`auto`,`anneversion`,`created`,`modified`) "
		... "VALUES ('%s','%s',%i,%i,'%s',%f,%i,'%s',%i,%i,%i,%i,%i,'%s',NOW(),NOW())",
		DbPrefix, RunID, MapName, GamemodeID, GameDifficulty, ClientID, TotalTime, PlayerCounter, Mutation, Mode,
		GetAnneInfectedNumber(), GetAnneSISpawnTime(), g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_USEBUY), IsAutoSpawnTime(), GetAnneVersion());
	SendSQLUpdate(query);
}

public StartMapTiming()
{
	if (!MapTimingEnabled() || MapTimingStartTime != 0.0 || StatsDisabled())
	{
		return;
	}

	MapTimingStartTime = GetEngineTime();

	new ClientTeam, maxplayers = MaxClients;
	decl String:ClientID[MAX_LINE_WIDTH];

	ClearTrie(MapTimingSurvivors);
	ClearTrie(MapTimingInfected);

	new bool:SoundsEnabled = EnableSounds_Maptime_Start && GetConVarBool(cvar_SoundsEnabled);

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, ClientID, sizeof(ClientID));
				SetTrieValue(MapTimingSurvivors, ClientID, 1, true);

				if (SoundsEnabled)
					EmitSoundToClient(i, StatsSound_MapTime_Start);
			}
			else if (ClientTeam == TEAM_INFECTED)
			{
				GetClientRankAuthString(i, ClientID, sizeof(ClientID));
				SetTrieValue(MapTimingInfected, ClientID, 1, true);
			}
		}
	}
}

GetCurrentDifficulty()
{
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "normal", false)) return 1;
	else if (StrEqual(Difficulty, "hard", false)) return 2;
	else if (StrEqual(Difficulty, "impossible", false)) return 3;
	else return 0;
}

public bool StopMapTiming()
{
	if (!MapTimingEnabled() || MapTimingStartTime <= 0.0 || StatsDisabled())
	{
		return false;
	}
	if(g_brpgAvailable && !L4D_RPG_GetGlobalValue(INDEX_VALID))
	{
		if (GetConVarInt(cvar_AnnounceMode))
		{
			StatsPrintToChatAll("此次结果因修改难度或开启高级人机或使用管理员功能导致 \x04无效 \x01，不记录这张地图游戏时间!");
		}
		MapTimingStartTime = -1.0;
		MapTimingBlocked = true;
		return false;
	}
	if(!IsNormalMode() && !IsThisRoundValid())
	{
		if (GetConVarInt(cvar_AnnounceMode))
		{
			StatsPrintToChatAll("此次结果因关闭tank连跳导致 \x04无效 \x01，不记录这张地图游戏时间!");
		}
		MapTimingStartTime = -1.0;
		MapTimingBlocked = true;
		return false;
	}
	int mode = 0;
	if(IsWitchParty())
	{
		mode = 2;
	}else if(IsAllCharger())
	{
		mode = 3;
	}else if(IsAlone())
	{
		mode = 4;
	}else if(Is1vht())
	{
		mode = 5;
	}else if(IsAnne() == 1)
	{
		mode = 1;
	}else if(IsAnne() == 2)
	{
		mode = 6;
	}
	ConVar multiplayer = FindConVar("l4d_multislots_survivors_manager_enable");
	if(mode > 0 && (multiplayer == null || multiplayer.IntValue == 1 || GetConVarInt(cvar_SurvivorLimit) > 4))
	{
		StatsPrintToChatAll("启用了多人运动模式，不记录这张地图游戏时间!");
		MapTimingStartTime = -1.0;
		MapTimingBlocked = true;
		return false;
	}

	new Float:TotalTime = GetEngineTime() - MapTimingStartTime;
	if(TotalTime < 30.0)
	{
		StatsPrintToChatAll("记录时间小于30s，数据应该不对，没有分数奖励!(PS: 30s能完成的图算啥图)");
		return false;
	}

	MapTimingStartTime = -1.0;
	MapTimingBlocked = true;

	new Handle:dp = INVALID_HANDLE;
	new ClientTeam, enabled, maxplayers = MaxClients;
	decl String:ClientID[MAX_LINE_WIDTH], String:MapName[MAX_LINE_WIDTH], String:query[512];

	GetCurrentMap(MapName, sizeof(MapName));

	new i, PlayerCounter = 0, InfectedCounter = (CurrentGamemodeID == GAMEMODE_VERSUS || CurrentGamemodeID == GAMEMODE_SCAVENGE ? 0 : 1);

	// 结算时以实际过关队伍为准，补登记中途加入/重连后加入的真人幸存者。
	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			GetClientRankAuthString(i, ClientID, sizeof(ClientID));
			if (!GetTrieValue(MapTimingSurvivors, ClientID, enabled))
			{
				SetTrieValue(MapTimingSurvivors, ClientID, 1, true);
			}
		}
	}

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);
			GetClientRankAuthString(i, ClientID, sizeof(ClientID));

			if (ClientTeam == TEAM_SURVIVORS && GetTrieValue(MapTimingSurvivors, ClientID, enabled))
			{
				if (enabled)
					PlayerCounter++;
			}
			else if (IsNormalMode() && ClientTeam == TEAM_INFECTED)
			{
				InfectedCounter++;
				if (GetTrieValue(MapTimingInfected, ClientID, enabled))
				{
					if (enabled)
						PlayerCounter++;
				}
			}
		}
	}

	// Game ended because all of the infected team left the server... don't record the time!
	//if (InfectedCounter <= 0)
		//return;

	new GameDifficulty = GetCurrentDifficulty();
	if(mode > 0)
	{
		GetThisModeBestTime(g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_USEBUY));	
		PlayerCounter = GetConVarInt(cvar_SurvivorLimit);
	}

	decl String:RunID[64];
	Format(RunID, sizeof(RunID), "%i_%i_%i", GetTime(), RoundToFloor(TotalTime * 1000.0), GetRandomInt(1000, 9999));

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, ClientID, sizeof(ClientID));

				if (GetTrieValue(MapTimingSurvivors, ClientID, enabled))
				{
					if (enabled)
						{
							dp = CreateDataPack();
							MapTimingRuns_RecordParticipant(RunID, MapName, CurrentGamemodeID, ClientID, TotalTime, PlayerCounter, GameDifficulty, CurrentMutation, mode);

							WritePackString(dp, MapName);
							WritePackCell(dp, CurrentGamemodeID);
							WritePackString(dp, ClientID);
							WritePackFloat(dp, TotalTime);
							WritePackCell(dp, i);
							WritePackCell(dp, PlayerCounter);
						WritePackCell(dp, GameDifficulty);
						WritePackString(dp, CurrentMutation);

						if(mode > 0)
						{
							Format(query, sizeof(query), "SELECT time FROM %stimedmaps WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s' AND sinum = %i AND sitime = %i AND anneversion = '%s' AND mode = %i AND usebuy = %i AND auto = %i AND players = %i", DbPrefix, MapName, CurrentGamemodeID, GameDifficulty, CurrentMutation, ClientID, GetAnneInfectedNumber(), GetAnneSISpawnTime(), GetAnneVersion(), mode, g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_USEBUY), IsAutoSpawnTime(), PlayerCounter);
						}
						else
						{
							Format(query, sizeof(query), "SELECT time FROM %stimedmaps WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s' AND mode = %i", DbPrefix, MapName, CurrentGamemodeID, GameDifficulty, CurrentMutation, ClientID, mode);
						}
						SQL_TQuery(db, UpdateMapTimingStat, query, dp);
					}
				}
 			}
		}
	}

	ClearTrie(MapTimingSurvivors);
	return true;
}

GetThisModeBestTime(int UseBuy=0)
{

	decl String:MapName[MAX_LINE_WIDTH], String:query[512];

	GetCurrentMap(MapName, sizeof(MapName));

	new GameDifficulty = GetCurrentDifficulty();
	int mode = 1;
	if(IsWitchParty())
	{
		mode = 2;
	}else if(IsAllCharger())
	{
		mode = 3;
	}else if(IsAlone())
	{
		mode = 4;
	}else if(Is1vht())
	{
		mode = 5;
	}else if(IsAnne() == 1)
	{
		mode = 1;
	}else if(IsAnne() == 2)
	{
		mode = 6;
	}
	Format(query, sizeof(query), "SELECT time FROM %stimedmaps WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s'  AND sinum = %i AND sitime = %i AND anneversion = '%s' AND mode = %i AND usebuy = %i AND auto = %i AND players = %i ORDER BY time LIMIT 1",\
	 		DbPrefix, MapName, CurrentGamemodeID, GameDifficulty, CurrentMutation, GetAnneInfectedNumber(), GetAnneSISpawnTime(),\
			GetAnneVersion(), mode, UseBuy, IsAutoSpawnTime(), GetConVarInt(cvar_SurvivorLimit));
	LogMessage("GetFastTimequery: %s", query);
	SQL_TQuery(db, GetFastTime, query);
}

public GetFastTime(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	new Mode = GetConVarInt(cvar_AnnounceMode);
	if (SQL_GetRowCount(hndl) > 0)
	{
		SQL_FetchRow(hndl);
		FastestTime = SQL_FetchFloat(hndl, 0);
		char TimeLabel[32];
		SetTimeLabel(FastestTime, TimeLabel, sizeof(TimeLabel));
		if (Mode)
		{
			StatsPrintToChatAll("当前模式该难度\x04 [%s使用B数] \x01最快通关速度为\x04 %s \x01." , (g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_USEBUY))?"":"不", TimeLabel);
		}
	}
	else{
		if (Mode)
		{
			StatsPrintToChatAll("你来到无人的荒野，当前模式该难度没有最快纪录，快来挑战一下吧");
		}
	}
}


public UpdateMapTimingStat(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	int mode = 0;
	if(IsWitchParty())
	{
		mode = 2;
	}else if(IsAllCharger())
	{
		mode = 3;
	}else if(IsAlone())
	{
		mode = 4;
	}else if(Is1vht())
	{
		mode = 5;
	}else if(IsAnne() == 1)
	{
		mode = 1;
	}else if(IsAnne() == 2)
	{
		mode = 6;
	}
	ResetPack(dp);

	decl String:MapName[MAX_LINE_WIDTH], String:ClientID[MAX_LINE_WIDTH], String:query[512], String:TimeLabel[32], String:Mutation[MAX_LINE_WIDTH];
	new GamemodeID, Float:TotalTime, Float:OldTime, Client, PlayerCounter, GameDifficulty;
	ReadPackString(dp, MapName, sizeof(MapName));
	GamemodeID = ReadPackCell(dp);
	ReadPackString(dp, ClientID, sizeof(ClientID));
	TotalTime = ReadPackFloat(dp);
	Client = ReadPackCell(dp);
	PlayerCounter = ReadPackCell(dp);
	GameDifficulty = ReadPackCell(dp);
	ReadPackString(dp, Mutation, sizeof(Mutation));

	CloseHandle(dp);

	// Return if client is not a human player
	if (IsClientBot(Client) || !IsClientInGame(Client))
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (SQL_GetRowCount(hndl) > 0)
	{
		SQL_FetchRow(hndl);
		OldTime = SQL_FetchFloat(hndl, 0);
		if(TotalTime < 30.0)
		{
			StatsPrintToChat(Client, "记录时间小于30s，数据应该不对，此次记录不进行记录!");
			return;
		}

		if ((CurrentGamemodeID != GAMEMODE_SURVIVAL && OldTime <= TotalTime) || (CurrentGamemodeID == GAMEMODE_SURVIVAL && OldTime >= TotalTime))
		{
			if (Mode)
			{
				SetTimeLabel(OldTime, TimeLabel, sizeof(TimeLabel));
				if(mode > 0)
				{
					StatsPrintToChat(Client, "下次继续努力哦，这张图 \x04Anne%s \x01版本该难度的最快完成时间 \x04%s \x01 并没有提升!", GetAnneVersion(), TimeLabel);
				}
				else
				{
					StatsPrintToChat(Client, "下次继续努力哦，这张图最快完成时间 \x04%s \x01 并没有提升!", TimeLabel);
				}
			}
			if(mode > 0)
			{
				Format(query, sizeof(query), "UPDATE %stimedmaps SET plays = plays + 1, modified = NOW() WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s' AND sinum = %i AND sitime = %i AND anneversion = '%s' AND mode = %i AND usebuy = %i AND auto = %i", DbPrefix, MapName, GamemodeID, GameDifficulty, Mutation, ClientID, GetAnneInfectedNumber(), GetAnneSISpawnTime(), GetAnneVersion(), mode, g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_USEBUY), IsAutoSpawnTime());
			}
			else
			{
				Format(query, sizeof(query), "UPDATE %stimedmaps SET plays = plays + 1, modified = NOW() WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s' AND mode = %i", DbPrefix, MapName, GamemodeID, GameDifficulty, Mutation, ClientID, mode);
			}
		}
		else
		{
			if (Mode)
			{
				SetTimeLabel(TotalTime, TimeLabel, sizeof(TimeLabel));
				StatsPrintToChat(Client, "牛逼，你刷新了%s这张图 \x04Anne%s \x01版本该难度的最快完成时间，目前是 \x04%s\x01!", FastestTime < TotalTime?"目前":"你", GetAnneVersion(), TimeLabel);

			}

			if(mode > 0)
			{
				Format(query, sizeof(query), "UPDATE %stimedmaps SET plays = plays + 1, time = %f, players = %i, modified = NOW() WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s' AND sinum = %i AND sitime = %i AND anneversion = '%s' AND mode = %i AND usebuy = %i AND auto = %i", DbPrefix, TotalTime, PlayerCounter, MapName, GamemodeID, GameDifficulty, Mutation, ClientID, GetAnneInfectedNumber(), GetAnneSISpawnTime(), GetAnneVersion(), mode, g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_USEBUY), IsAutoSpawnTime());
			}
			else
			{
				Format(query, sizeof(query), "UPDATE %stimedmaps SET plays = plays + 1, time = %f, players = %i, modified = NOW() WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s' AND mode = %i", DbPrefix, TotalTime, PlayerCounter, MapName, GamemodeID, GameDifficulty, Mutation, ClientID, mode);
			}
			
			if (EnableSounds_Maptime_Improve && GetConVarBool(cvar_SoundsEnabled))
				EmitSoundToClient(Client, StatsSound_MapTime_Improve);
		}
	}
	else
	{
		if (Mode)
		{
			SetTimeLabel(TotalTime, TimeLabel, sizeof(TimeLabel));
			StatsPrintToChat(Client, "你花费了 \x04%s \x01来完成这张地图!", TimeLabel);
		}

		if(mode > 0)
		{
			Format(query, sizeof(query), "INSERT INTO %stimedmaps (map, gamemode, difficulty, mutation, steamid, plays, time, players, sinum, sitime, anneversion, mode, usebuy, auto, modified, created) VALUES ('%s', %i, %i, '%s', '%s', 1, %f, %i, %i, %i, '%s', %i, %i, %i, NOW(), NOW())", DbPrefix, MapName, GamemodeID, GameDifficulty, Mutation, ClientID, TotalTime, PlayerCounter, GetAnneInfectedNumber(), GetAnneSISpawnTime(), GetAnneVersion(), mode, g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_USEBUY), IsAutoSpawnTime());
		}
		else
		{
			Format(query, sizeof(query), "INSERT INTO %stimedmaps (map, gamemode, difficulty, mutation, steamid, plays, time, players, mode, modified, created) VALUES ('%s', %i, %i, '%s', '%s', 1, %f, %i, %i, NOW(), NOW())", DbPrefix, MapName, GamemodeID, GameDifficulty, Mutation, ClientID, TotalTime, PlayerCounter, mode);
		}
	}

	FastestTime = -1.0;

	SendSQLUpdate(query);
}

public SetTimeLabel(Float:TheSeconds, String:TimeLabel[], maxsize)
{
	new FlooredSeconds = RoundToFloor(TheSeconds);
	new FlooredSecondsMod = FlooredSeconds % 60;
	new Float:Seconds = TheSeconds - float(FlooredSeconds) + float(FlooredSecondsMod);
	new Minutes = (TheSeconds < 60.0 ? 0 : RoundToNearest(float(FlooredSeconds - FlooredSecondsMod) / 60));
	new MinutesMod = Minutes % 60;
	new Hours = (Minutes < 60 ? 0 : RoundToNearest(float(Minutes - MinutesMod) / 60));
	Minutes = MinutesMod;

	if (Hours > 0)
		Format(TimeLabel, maxsize, "%i小时 %i分钟 %.1f秒", Hours, Minutes, Seconds);
	else if (Minutes > 0)
		Format(TimeLabel, maxsize, "%i 分钟 %.1f 秒", Minutes, Seconds);
	else
		Format(TimeLabel, maxsize, "%.1f 秒", Seconds);
}

public DisplayRankVote(client)
{
	DisplayYesNoPanel(client, RANKVOTE_QUESTION, RankVotePanelHandler, RoundToNearest(GetConVarFloat(cvar_RankVoteTime)));
}

// Initialize RANKVOTE
public InitializeRankVote(client)
{
	if (StatsDisabled())
	{
		if (client == 0)
		{
			PrintToConsole(0, "[RANK] Cannot initiate vote when the plugin is disabled!");
		}
		else
		{
			StatsPrintToChatPreFormatted2(client, true, "Cannot initiate vote when the plugin is disabled!");
		}

		return;
	}

	// No TEAM gamemodes are allowed
	if (!IsTeamGamemode())
	{
		if (client == 0)
		{
			PrintToConsole(0, "[RANK] The Rank Vote is not enabled in this gamemode!");
		}
		else
		{
			if (EngineVersion1 == Engine_Left4Dead)
			{
				StatsPrintToChatPreFormatted2(client, true, "The \x04Rank Vote \x01is enabled in \x03Versus \x01gamemode!");
			}
			else
			{
				StatsPrintToChatPreFormatted2(client, true, "The \x04Rank Vote \x01is enabled in \x03Versus\x01, \x03Realism Versus \x01and \x03Scavenge \x01gamemodes!");
			}
		}

		return;
	}

	if (RankVoteTimer != INVALID_HANDLE)
	{
		if (client > 0)
		{
			DisplayRankVote(client);
		}
		else
		{
			PrintToConsole(client, "[RANK] The Rank Vote is already initiated!");
		}

		return;
	}

	new bool:IsAdmin = (client > 0 ? ((GetUserFlagBits(client) & ADMFLAG_GENERIC) == ADMFLAG_GENERIC) : true);

	new team;
	decl String:ClientID[MAX_LINE_WIDTH];

	if (!IsAdmin && client > 0 && GetTrieValue(PlayerRankVoteTrie, ClientID, team))
	{
		StatsPrintToChatPreFormatted2(client, true, "You can initiate a \x04Rank Vote \x01only once per map!");
		return;
	}

	if (!IsAdmin && client > 0)
	{
		GetClientRankAuthString(client, ClientID, sizeof(ClientID));
		SetTrieValue(PlayerRankVoteTrie, ClientID, 1, true);
	}

	RankVoteTimer = CreateTimer(GetConVarFloat(cvar_RankVoteTime), timer_RankVote);

	new i;

	for (i = 0; i <= MAXPLAYERS; i++)
	{
		PlayerRankVote[i] = RANKVOTE_NOVOTE;
	}

	new maxplayers = MaxClients;

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			team = GetClientTeam(i);

			if (team == TEAM_SURVIVORS || team == TEAM_INFECTED)
			{
				DisplayRankVote(i);
			}
		}
	}

	if (client > 0)
	{
		decl String:UserName[MAX_LINE_WIDTH];
		GetClientName(client, UserName, sizeof(UserName));

		StatsPrintToChatAll2(true, "The \x04Rank Vote \x01was initiated by \x05%s\x01!", UserName);
	}
	else
	{
		StatsPrintToChatAllPreFormatted2(true, "The \x04Rank Vote \x01was initiated from Server Console!");
	}
}

/*
	From plugin:
		name = "L4D2 Score/Team Manager",
		author = "Downtown1 & AtomicStryker",
		description = "Manage teams and scores in L4D2",
		version = 1.1.2,
		url = "http://forums.alliedmods.net/showthread.php?p=1029519"
*/

stock bool:ChangeRankPlayerTeam(client, team)
{
	if(GetClientTeam(client) == team) return true;

	if(team != TEAM_SURVIVORS)
	{
		//we can always swap to infected or spectator, it has no actual limit
		ChangeClientTeam(client, team);
		return true;
	}

	if(GetRankTeamHumanCount(team) == GetRankTeamMaxHumans(team))
		return false;

	new bot;
	//for survivors its more tricky
	for (bot = 1; bot < MaxClients + 1 && (!IsClientConnected(bot) || !IsFakeClient(bot) || (GetClientTeam(bot) != TEAM_SURVIVORS)); bot++) {}

	if (bot == MaxClients + 1)
	{
		new String:command[] = "sb_add";
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);

		ServerCommand("sb_add");

		SetCommandFlags(command, flags);

		return false;
	}

	//have to do this to give control of a survivor bot
	SDKCall(L4DStatsSHS, bot, client);
	SDKCall(L4DStatsTOB, client, true);

	return true;
}

/*
	From plugin:
		name = "L4D2 Score/Team Manager",
		author = "Downtown1 & AtomicStryker",
		description = "Manage teams and scores in L4D2",
		version = 1.1.2,
		url = "http://forums.alliedmods.net/showthread.php?p=1029519"
*/

stock bool:IsRankClientInGameHuman(client)
{
	if (client > 0) return IsClientInGame(client) && !IsFakeClient(client);
	else return false;
}

/*
	From plugin:
		name = "L4D2 Score/Team Manager",
		author = "Downtown1 & AtomicStryker",
		description = "Manage teams and scores in L4D2",
		version = 1.1.2,
		url = "http://forums.alliedmods.net/showthread.php?p=1029519"
*/

stock GetRankTeamHumanCount(team)
{
	new humans = 0;
	
	for(new i = 1; i < MaxClients + 1; i++)
	{
		if(IsRankClientInGameHuman(i) && GetClientTeam(i) == team)
		{
			humans++;
		}
	}
	
	return humans;
}

stock GetRankTeamMaxHumans(team)
{
	switch (team)
	{
		case TEAM_SURVIVORS:
			return GetConVarInt(cvar_SurvivorLimit);
		case TEAM_INFECTED:
			return GetConVarInt(cvar_InfectedLimit);
		case TEAM_SPECTATORS:
			return MaxClients;
	}
	
	return -1;
}

GetClientRankAuthString(client, String:auth[], maxlength)
{
	if (GetConVarInt(cvar_Lan))
	{
		GetClientAuthId(client,AuthId_Engine, auth, maxlength);

		if (!StrEqual(auth, "BOT", false))
		{
			GetClientIP(client, auth, maxlength);
		}
	}
	else
	{
		GetClientAuthId(client, AuthId_Engine,auth, maxlength);

		if (StrEqual(auth, "STEAM_ID_LAN", false))
		{
			GetClientIP(client, auth, maxlength);
		}
	}
}

public StatsPrintToChatAll(const String:Message[], any:...)
{
	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 2);

	StatsPrintToChatAllPreFormatted(FormattedMessage);
}

public StatsPrintToChatAll2(bool:Forced, const String:Message[], any:...)
{
	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 2);

	StatsPrintToChatAllPreFormatted2(Forced, FormattedMessage);
}

public StatsPrintToChatAllPreFormatted(const String:Message[])
{
	new maxplayers = MaxClients;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			StatsPrintToChatPreFormatted(i, Message);
		}
	}
}

public StatsPrintToChatAllPreFormatted2(bool:Forced, const String:Message[])
{
	new maxplayers = MaxClients;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			StatsPrintToChatPreFormatted2(i, Forced, Message);
		}
	}
}

public StatsPrintToChat(Client, const String:Message[], any:...)
{
	// CHECK IF CLIENT HAS MUTED THE PLUGIN
	if (ClientRankMute[Client])
	{
		return;
	}

	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 3);

	StatsPrintToChatPreFormatted(Client, FormattedMessage);
}

public StatsPrintToChat2(Client, bool:Forced, const String:Message[], any:...)
{
	// CHECK IF CLIENT HAS MUTED THE PLUGIN
	if (!Forced && ClientRankMute[Client])
	{
		return;
	}

	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 4);

	StatsPrintToChatPreFormatted2(Client, Forced, FormattedMessage);
}

public StatsPrintToChatPreFormatted(Client, const String:Message[])
{
	StatsPrintToChatPreFormatted2(Client, false, Message);
}

public StatsPrintToChatPreFormatted2(Client, bool:Forced, const String:Message[])
{
	// CHECK IF CLIENT HAS MUTED THE PLUGIN
	if (!Forced && ClientRankMute[Client])
	{
		return;
	}

	PrintToChat(Client, "\x04[\x03RANK\x04] \x01%s", Message);
}

stock StatsGetClientTeam(client)
{
	if (client <= 0 || !IsClientConnected(client))
	{
		return TEAM_UNDEFINED;
	}

	if (IsFakeClient(client) || IsClientInGame(client))
	{
		return GetClientTeam(client);
	}

	return TEAM_UNDEFINED;
}

bool:UpdateServerSettings(Client, const String:Key[], const String:Value[], const String:Desc[])
{
	new Handle:statement = INVALID_HANDLE;
	decl String:error[1024], String:query[2048];

	// Add a row if it does not previously exist
	if (!DoFastQuery(Client, "INSERT IGNORE INTO %sserver_settings SET sname = '%s', svalue = ''", DbPrefix, Key))
	{
		PrintToConsole(Client, "[RANK] %s: Setting a new MOTD value failure!", Desc);
		return false;
	}

	Format(query, sizeof(query), "UPDATE %sserver_settings SET svalue = ? WHERE sname = '%s'", DbPrefix, Key);

	statement = SQL_PrepareQuery(db, query, error, sizeof(error));

	if (statement == INVALID_HANDLE)
	{
		PrintToConsole(Client, "[RANK] %s: Update failed! (Reason: Cannot create SQL statement)");
		return false;
	}

	new bool:retval = true;
	SQL_BindParamString(statement, 0, Value, false);

	if (!SQL_Execute(statement))
	{
		if (SQL_GetError(db, error, sizeof(error)))
		{
			PrintToConsole(Client, "[RANK] %s: Update failed! (Error = \"%s\")", Desc, error);
			LogError("%s: Update failed! (Error = \"%s\")", Desc, error);
		}
		else
		{
			PrintToConsole(Client, "[RANK] %s: Update failed!", Desc);
			LogError("%s: Update failed!", Desc);
		}
		
		retval = false;
	}
	else
	{
		PrintToConsole(Client, "[RANK] %s: Update successful!", Desc);

		if (StrEqual(Key, "motdmessage", false))
		{
			strcopy(MessageOfTheDay, sizeof(MessageOfTheDay), Value);
			ShowMOTDAll();
		}
	}

	CloseHandle(statement);
	
	return retval;
}

ShowMOTDAll()
{
	new maxplayers = MaxClients;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ShowMOTD(i);
		}
	}
}

ShowMOTD(client, bool:forced=false)
{
	if (!forced && !GetConVarBool(cvar_AnnounceMotd))
	{
		return;
	}

	StatsPrintToChat2(client, forced, "\x05%s: \x01%s", MOTD_TITLE, MessageOfTheDay);
}

AnnouncePlayerConnect(client)
{
	if (!GetConVarBool(cvar_AnnouncePlayerJoined))
	{
		return;
	}

	DoShowPlayerJoined(client);
}

ReadDb()
{
	ReadDbMotd();
}

ReadDbMotd()
{
	decl String:query[512];
	Format(query, sizeof(query), "SELECT svalue FROM %sserver_settings WHERE sname = 'motdmessage' LIMIT 1", DbPrefix);
	SQL_TQuery(db, ReadDbMotdCallback, query);
}

public ReadDbMotdCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("ReadDbMotdCallback Query failed: %s", error);
		return;
	}

	if (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, MessageOfTheDay, sizeof(MessageOfTheDay));
	}
}

stock bool IsGaoJiRenJiEnabled()
{
	ConVar gjrj = FindConVar("sb_fix_enabled");
	if(gjrj == null)
	{
		return false;
	}
	else if(gjrj.BoolValue)
	{
		return true;
	}
	return false;
}

stock bool IsNormalMode()
{
	ConVar cvar = FindConVar("l4d_infected_limit");
	if(cvar == null) return true;
	return false;
}

stock int IsAutoSpawnTime()
{
	ConVar cvar = FindConVar("inf_EnableAutoSpawnTime");
	if(cvar_mode == null) return false;
	return cvar.IntValue;
}

stock bool IsThisRoundValid()
{
	ConVar tank_bhop = FindConVar("ai_Tank_Bhop");
	if(AnneMultiPlayerMode())
	{
		return tank_bhop.BoolValue;
	}
	return true;
}

stock bool CheckIsOfficalMap(){
	char mapname[256];
	GetCurrentMap(mapname,sizeof(mapname));
	if(( (mapname[0]=='c') && (mapname[2]=='m') &&(mapname[4]=='_'))||((mapname[0]=='c')&&(mapname[3]=='m')&&(mapname[5]=='_')))
		return true;
	return false;
}
