#if defined _l4d_stats_persistence_included
	#endinput
#endif
#define _l4d_stats_persistence_included

// 数据库连接、玩家/地图持久化、基础查询和相关计分定时器。

static Handle g_hDBReconnectTimer = INVALID_HANDLE;

// Make connection to database.

bool:ConnectDB()
{
	if (db != INVALID_HANDLE)
		return true;

	if (SQL_CheckConfig(DB_CONF_NAME))
	{
		new String:Error[256];
		db = SQL_Connect(DB_CONF_NAME, true, Error, sizeof(Error));

		if (db == INVALID_HANDLE)
		{
			LogError("Failed to connect to database: %s", Error);
			return false;
		}
		else if (!SQL_FastQuery(db, "SET NAMES 'utf8mb4'"))
		{
			if (SQL_GetError(db, Error, sizeof(Error)))
			{
				if (IsDBConnectionLostError(Error))
					LogMessage("[l4d_stats] 设置数据库字符集时连接丢失，等待自动重连。");
				else
					LogError("Failed to update encoding to utf8mb4: %s", Error);
				ScheduleDBReconnect(Error);
			}
			else
				LogError("Failed to update encoding to utf8mb4: unknown");
			if (db != INVALID_HANDLE)
			{
				CloseHandle(db);
				db = INVALID_HANDLE;
			}
			return false;
		}

		if (!CheckDatabaseValidity(DbPrefix))
		{
			if (IsDBReconnectPending())
				return false;

			LogError("Database is missing required table or tables.");
			if (db != INVALID_HANDLE)
			{
				CloseHandle(db);
				db = INVALID_HANDLE;
			}
			return false;
		}

		ScoreLog_EnsureTable();
		if (db == INVALID_HANDLE)
			return false;

		QuarterRank_EnsureTable();
		if (db == INVALID_HANDLE)
			return false;

		ModeStats_EnsureTable();
		if (db == INVALID_HANDLE)
			return false;

		MapTimingRuns_EnsureTable();
		if (db == INVALID_HANDLE)
			return false;
	}
	else
	{
		LogError("Databases.cfg missing '%s' entry!", DB_CONF_NAME);
		return false;
	}

	return true;
}

bool:IsDBReconnectPending()
{
	return (g_hDBReconnectTimer != INVALID_HANDLE);
}

// 检测是否为连接丢失错误
bool:IsDBConnectionLostError(const String:error[])
{
	return (StrContains(error, "Lost connection", false) != -1
		|| StrContains(error, "server has gone away", false) != -1);
}

// 标记连接丢失并安排重连
void ScheduleDBReconnect(const char[] error)
{
	if (!IsDBConnectionLostError(error))
		return;

	LogMessage("[l4d_stats] 检测到数据库连接丢失，10 秒后自动重连...");
	g_bScoreLogTableReady = false;
	g_bQuarterRankTableReady = false;
	g_bQuarterRankDbChecked = false;
	g_bModeStatsTableReady = false;

	if (db != INVALID_HANDLE)
	{
		CloseHandle(db);
		db = INVALID_HANDLE;
	}

	if (g_hDBReconnectTimer == INVALID_HANDLE)
		g_hDBReconnectTimer = CreateTimer(10.0, Timer_L4DStatsDBReconnect);
}

public Action:Timer_L4DStatsDBReconnect(Handle:timer, any:data)
{
	g_hDBReconnectTimer = INVALID_HANDLE;

	if (ConnectDB())
	{
		LogMessage("[l4d_stats] 数据库重连成功。");
		ReadDb();
		GetTop100PlayerScore();
		QuarterRank_QueryTop100Scores();
		CreateTimer(1.0, InitPlayers);
	}
	else
	{
		LogError("[l4d_stats] 数据库重连失败，10 秒后再次重试。");
		if (g_hDBReconnectTimer == INVALID_HANDLE)
			g_hDBReconnectTimer = CreateTimer(10.0, Timer_L4DStatsDBReconnect);
	}

	return Plugin_Stop;
}

bool:CheckDatabaseValidity(const String:Prefix[])
{
	if (!DoFastQuery(0, "SELECT * FROM %splayers WHERE 1 = 2", Prefix) ||
			!DoFastQuery(0, "SELECT * FROM %smaps WHERE 1 = 2", Prefix) ||
			!DoFastQuery(0, "SELECT * FROM %stimedmaps WHERE 1 = 2", Prefix) ||
			!DoFastQuery(0, "SELECT * FROM %ssettings WHERE 1 = 2", Prefix))
	{
		return false;
	}

	return true;
}

public Action:timer_ProtectedFriendly(Handle:timer, any:data)
{
	new Handle:Pack = data;
	ResetPack(Pack);
	new TimerUserID = ReadPackCell(Pack);
	new TimerRoundToken = ReadPackCell(Pack);
	new client = GetClientOfUserId(TimerUserID);

	if (client <= 0 || client > MaxClients)
	{
		return Plugin_Stop;
	}

	if (TimerProtectedFriendly[client] != timer)
	{
		return Plugin_Stop;
	}

	TimerProtectedFriendly[client] = INVALID_HANDLE;

	if (TimerRoundToken != ProtectedFriendlyRoundToken || StatsDisabled() || CampaignOver || !Stats_IsRpgRoundValid() || !Stats_IsSurvivorHuman(client))
	{
		ProtectedFriendlyCounter[client] = 0;
		return Plugin_Stop;
	}

	new ProtectedFriendlies = ProtectedFriendlyCounter[client];
	ProtectedFriendlyCounter[client] = 0;

	if (ProtectedFriendlies <= 0)
	{
		return Plugin_Stop;
	}

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Protect), 2, 3, TEAM_SURVIVORS);
	Score = NewPlayerBonus_ApplyScoreMultiplier(client, Score);
	ScoreLog_SetContext("protect_teammate", "base=l4d_stats_protect,difficulty,newbie_multiplier");
	AddScore(client, Score);

	UpdateMapStat("points", Score);

	decl String:UpdatePoints[32];
	decl String:UserID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, UserID, sizeof(UserID));
	decl String:UserName[MAX_LINE_WIDTH];
	GetClientName(client, UserName, sizeof(UserName));

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		}
		case GAMEMODE_OTHERMUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_protect = award_protect + %i WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, ProtectedFriendlies, UserID);
	SendSQLUpdate(query);
	QuarterRank_RecordField(client, "award_protect", ProtectedFriendlies);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(client, "你\x05 保护队友 \x01获得了 \x04%i \x01分！!", Score);
		else if (Mode == 3)
			StatsPrintToChatAll("\x05%s\x05 保护队友 \x01获得了 \x04%i \x01分！\x01!", UserName, Score);
	}
}
// Team infected damage score

public Action:timer_InfectedDamageCheck(Handle:timer, any:data)
{
	TimerInfectedDamageCheck[data] = INVALID_HANDLE;

	if (data == 0 || IsClientBot(data))
		return;

	new InfectedDamage = GetConVarInt(cvar_InfectedDamage);

	new Score = 0;
	new DamageCounter = 0;

	if (InfectedDamage > 1)
	{
		if (InfectedDamageCounter[data] < InfectedDamage)
			return;

		new TotalDamage = InfectedDamageCounter[data];

		while (TotalDamage >= InfectedDamage)
		{
			DamageCounter += InfectedDamage;
			TotalDamage -= InfectedDamage;
			Score++;
		}
	}
	else
	{
		DamageCounter = InfectedDamageCounter[data];
		Score = InfectedDamageCounter[data];
	}

	Score = ModifyScoreDifficultyFloat(Score, 0.75, 0.5, TEAM_INFECTED);

	if (Score > 0)
	{
		InfectedDamageCounter[data] -= DamageCounter;

		new Mode = GetConVarInt(cvar_AnnounceMode);

		decl String:query[1024];
		decl String:iID[MAX_LINE_WIDTH];

		GetClientRankAuthString(data, iID, sizeof(iID));

		if (CurrentGamemodeID == GAMEMODE_VERSUS)
		{
			Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i WHERE steamid = '%s'", DbPrefix, Score, iID);
		}
		else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		{
			Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i WHERE steamid = '%s'", DbPrefix, Score, iID);
		}
		else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
		{
			Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i WHERE steamid = '%s'", DbPrefix, Score, iID);
		}
		else
		{
			Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i WHERE steamid = '%s'", DbPrefix, Score, iID);
		}

		SendSQLUpdate(query);

		UpdateMapStat("points_infected", Score);

		if (Mode == 1 || Mode == 2)
		{
			if (InfectedDamage > 1)
				StatsPrintToChat(data, "你因给生还者造成了 \x04%i \x01分的伤害获得了 \x04%i \x01分！", DamageCounter, Score);
		}
		else if (Mode == 3)
		{
			decl String:Name[MAX_LINE_WIDTH];
			GetClientName(data, Name, sizeof(Name));
			if (InfectedDamage > 1)
				StatsPrintToChatAll("\x05%s 因给生还者造成了 \x04%i \x01分的伤害获得了 \x04%i \x01分!", Name, DamageCounter, Score);
		}
	}
}

// Get Boomer points

GetBoomerPoints(VictimCount)
{
	if (VictimCount <= 0)
		return 0;

	return GetConVarInt(cvar_BoomerSuccess) * VictimCount;
}

// Calculate Boomer vomit hits and check Boomer Perfect Blindness award

public Action:timer_BoomerBlindnessCheck(Handle:timer, any:data)
{
	TimerBoomerPerfectCheck[data] = INVALID_HANDLE;

	if (data > 0 && !IsClientBot(data) && IsClientInGame(data) && GetClientTeam(data) == TEAM_INFECTED && BoomerHitCounter[data] > 0)
	{
		new HitCounter = BoomerHitCounter[data];
		BoomerHitCounter[data] = 0;
		new OriginalHitCounter = HitCounter;
		new BoomerPerfectHits = GetConVarInt(cvar_BoomerPerfectHits);
		new BoomerPerfectSuccess = GetConVarInt(cvar_BoomerPerfectSuccess);
		new Score = 0;
		new AwardCounter = 0;

		//PrintToConsole(0, "timer_BoomerBlindnessCheck -> HitCounter = %i / BoomerPerfectHits = %i", HitCounter, BoomerPerfectHits);

		while (HitCounter >= BoomerPerfectHits)
		{
			HitCounter -= BoomerPerfectHits;
			Score += BoomerPerfectSuccess;
			AwardCounter++;
			//PrintToConsole(0, "timer_BoomerBlindnessCheck -> Score = %i", Score);
		}

		Score += GetBoomerPoints(HitCounter);
		//PrintToConsole(0, "timer_BoomerBlindnessCheck -> Total Score = %i", Score);
		Score = ModifyScoreDifficultyFloat(Score, 0.75, 0.5, TEAM_INFECTED);

		decl String:query[1024];
		decl String:iID[MAX_LINE_WIDTH];
		GetClientRankAuthString(data, iID, sizeof(iID));

		if (CurrentGamemodeID == GAMEMODE_VERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_perfect_blindness = award_perfect_blindness + %i, infected_boomer_blinded = infected_boomer_blinded + %i, infected_boomer_vomits = infected_boomer_vomits + %i WHERE steamid = '%s'", DbPrefix, Score, AwardCounter, OriginalHitCounter, (BoomerVomitUpdated[data] ? 0 : 1), iID);
		else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_perfect_blindness = award_perfect_blindness + %i, infected_boomer_blinded = infected_boomer_blinded + %i, infected_boomer_vomits = infected_boomer_vomits + %i WHERE steamid = '%s'", DbPrefix, Score, AwardCounter, OriginalHitCounter, (BoomerVomitUpdated[data] ? 0 : 1), iID);
		else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
			Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_perfect_blindness = award_perfect_blindness + %i, infected_boomer_blinded = infected_boomer_blinded + %i, infected_boomer_vomits = infected_boomer_vomits + %i WHERE steamid = '%s'", DbPrefix, Score, AwardCounter, OriginalHitCounter, (BoomerVomitUpdated[data] ? 0 : 1), iID);
		else
			Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_perfect_blindness = award_perfect_blindness + %i, infected_boomer_blinded = infected_boomer_blinded + %i, infected_boomer_vomits = infected_boomer_vomits + %i WHERE steamid = '%s'", DbPrefix, Score, AwardCounter, OriginalHitCounter, (BoomerVomitUpdated[data] ? 0 : 1), iID);

		SendSQLUpdate(query);

		if (!BoomerVomitUpdated[data])
			UpdateMapStat("infected_boomer_vomits", 1);
		UpdateMapStat("infected_boomer_blinded", HitCounter);

		BoomerVomitUpdated[data] = false;

		if (Score > 0)
		{
			UpdateMapStat("points_infected", Score);

			new Mode = GetConVarInt(cvar_AnnounceMode);

			if (Mode == 1 || Mode == 2)
			{
				if (AwardCounter > 0)
					StatsPrintToChat(data, "你完美的糊生还者的眼，获得 \x04%i \x01 分!", Score);
				else
					StatsPrintToChat(data, "你获得了 \x04%i \x01分!", Score);
			}
			else if (Mode == 3)
			{
				decl String:Name[MAX_LINE_WIDTH];
				GetClientName(data, Name, sizeof(Name));
				if (AwardCounter > 0)
					StatsPrintToChatAll("\x05%s \x01完美的糊生还者的眼，获得 \x04%i \x01 分!", Name, Score);
				else
					StatsPrintToChatAll("\x05%s \x01获得了 \x04%i \x01分!", Name, Score);
			}
		}

		if (AwardCounter > 0 && EnableSounds_Boomer_Vomit && GetConVarBool(cvar_SoundsEnabled))
			EmitSoundToAll(StatsSound_Boomer_Vomit);
	}
}


// Perform player init.

public Action:InitPlayers(Handle:timer)
{
	if (db == INVALID_HANDLE)
		return;

	decl String:query[64];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", DbPrefix);
	SQL_TQuery(db, GetRankTotal, query);

	new maxplayers = MaxClients;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			CheckPlayerDB(i);

			QueryClientPoints(i);
			QuarterRank_QueryClient(i);

			TimerPoints[i] = 0;
			TimerKills[i] = 0;
		}
	}
}

QueryClientPoints(Client, SQLTCallback:callback=INVALID_FUNCTION)
{
	decl String:SteamID[MAX_LINE_WIDTH];

	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));
	QueryClientPointsSteamID(Client, SteamID, callback);
}

QueryClientPointsSteamID(Client, const String:SteamID[], SQLTCallback:callback=INVALID_FUNCTION)
{
	if (callback == INVALID_FUNCTION)
		callback = GetClientPoints;

	decl String:query[512];

	Format(query, sizeof(query), "SELECT %s FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPOINTS, DbPrefix, SteamID);

	SQL_TQuery(db, callback, query, Client);
}

QueryClientPointsDP(Handle:dp, SQLTCallback:callback)
{
	decl String:query[1024], String:SteamID[MAX_LINE_WIDTH];

	ResetPack(dp);

	ReadPackCell(dp);
	ReadPackString(dp, SteamID, sizeof(SteamID));

	Format(query, sizeof(query), "SELECT %s FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPOINTS, DbPrefix, SteamID);

	SQL_TQuery(db, callback, query, dp);
}

QueryClientRank(Client, SQLTCallback:callback=INVALID_FUNCTION)
{
	if (callback == INVALID_FUNCTION)
		callback = GetClientRank;

	decl String:query[256];

	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE %s >= %i", DbPrefix, DB_PLAYERS_TOTALPOINTS, ClientPoints[Client]);

	SQL_TQuery(db, callback, query, Client);
}

QueryClientRankDP(Handle:dp, SQLTCallback:callback)
{
	decl String:query[256];

	ResetPack(dp);

	new Client = ReadPackCell(dp);

	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE %s >= %i", DbPrefix, DB_PLAYERS_TOTALPOINTS, ClientPoints[Client]);

	SQL_TQuery(db, callback, query, dp);
}

QueryClientGameModeRankDP(Handle:dp, SQLTCallback:callback)
{
	if (!InvalidGameMode())
	{
		decl String:query[1024];

		ResetPack(dp);

		new Client = ReadPackCell(dp);

		switch (CurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_versus > 0 AND points_survivors + points_infected >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_VERSUS]);
			}
			case GAMEMODE_REALISM:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realism > 0 AND points_realism >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_REALISM]);
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_survival > 0 AND points_survival >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_SURVIVAL]);
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_scavenge > 0 AND points_scavenge_survivors + points_scavenge_infected >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_SCAVENGE]);
			}
			case GAMEMODE_REALISMVERSUS:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realismversus > 0 AND points_realism_survivors + points_realism_infected >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_REALISMVERSUS]);
			}
			case GAMEMODE_OTHERMUTATIONS:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_mutations > 0 AND points_mutations >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_OTHERMUTATIONS]);
			}
			default:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime > 0 AND points >= %i", DbPrefix, ClientGameModePoints[Client][GAMEMODE_COOP]);
			}
		}

		SQL_TQuery(db, callback, query, dp);
	}
}
/*
QueryClientGameModePoints(Client, SQLTCallback:callback=INVALID_FUNCTION)
{
	decl String:SteamID[MAX_LINE_WIDTH];

	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));
	QueryClientGameModePointsStmID(Client, SteamID, callback);
}

QueryClientGameModePointsStmID(Client, const String:SteamID[], SQLTCallback:callback=INVALID_FUNCTION)
{
	if (cbGetRankTotal == INVALID_HANDLE)
		callback = GetClientGameModePoints;

	decl String:query[1024];

	Format(query, sizeof(query), "SELECT points, points_survivors + points_infected, points_realism, points_survival, points_scavenge_survivors + points_scavenge_infected + points_realism_survivors + points_realism_infected, points_mutations FROM %splayers WHERE steamid = '%s'", DbPrefix, SteamID);

	SQL_TQuery(db, callback, query, Client);
}
*/
QueryClientGameModePointsDP(Handle:dp, SQLTCallback:callback)
{
	decl String:query[1024], String:SteamID[MAX_LINE_WIDTH];

	ResetPack(dp);

	ReadPackCell(dp);
	ReadPackString(dp, SteamID, sizeof(SteamID));

	Format(query, sizeof(query), "SELECT points, points_survivors + points_infected, points_realism, points_survival, points_scavenge_survivors + points_scavenge_infected, points_realism_survivors + points_realism_infected, points_mutations FROM %splayers WHERE steamid = '%s'", DbPrefix, SteamID);

	SQL_TQuery(db, callback, query, dp);
}
/*
QueryRanks()
{
	QueryRank_1();
	QueryRank_2();
}
*/
QueryRank_1(Handle:dp=INVALID_HANDLE, SQLTCallback:callback=INVALID_FUNCTION)
{
	if (callback == INVALID_FUNCTION)
		callback = GetRankTotal;

	decl String:query[1024];

	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", DbPrefix);

	SQL_TQuery(db, callback, query, dp);
}

QueryRank_2(Handle:dp=INVALID_HANDLE, SQLTCallback:callback=INVALID_FUNCTION)
{
	if (callback == INVALID_FUNCTION)
		callback = GetGameModeRankTotal;

	decl String:query[1024];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_versus > 0", DbPrefix);
		}
		case GAMEMODE_REALISM:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realism > 0", DbPrefix);
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_survival > 0", DbPrefix);
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_scavenge > 0", DbPrefix);
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realismversus > 0", DbPrefix);
		}
		case GAMEMODE_OTHERMUTATIONS:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_mutations > 0", DbPrefix);
		}
		default:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime > 0", DbPrefix);
		}
	}

	SQL_TQuery(db, callback, query, dp);
}

QueryClientStats(Client, CallingMethod=CM_UNKNOWN)
{
	decl String:SteamID[MAX_LINE_WIDTH];

	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));
	QueryClientStatsSteamID(Client, SteamID, CallingMethod);
}

QueryClientStatsSteamID(Client, const String:SteamID[], CallingMethod=CM_UNKNOWN)
{
	new Handle:dp = CreateDataPack();

	WritePackCell(dp, Client);
	WritePackString(dp, SteamID);
	WritePackCell(dp, CallingMethod);

	QueryClientStatsDP(dp);
}

QueryClientStatsDP(Handle:dp)
{
	QueryClientGameModePointsDP(dp, QueryClientStatsDP_1);
}

public QueryClientStatsDP_1(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_1 Query failed: %s", error);
		ScheduleDBReconnect(error);
		return;
	}

	ResetPack(dp);
	GetClientGameModePoints(owner, hndl, error, ReadPackCell(dp));

	QueryClientPointsDP(dp, QueryClientStatsDP_2);
}

public QueryClientStatsDP_2(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_2 Query failed: %s", error);
		ScheduleDBReconnect(error);
		return;
	}

	ResetPack(dp);
	GetClientPoints(owner, hndl, error, ReadPackCell(dp));

	QueryClientGameModeRankDP(dp, QueryClientStatsDP_3);
}

public QueryClientStatsDP_3(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_3 Query failed: %s", error);
		ScheduleDBReconnect(error);
		return;
	}

	ResetPack(dp);
	GetClientGameModeRank(owner, hndl, error, ReadPackCell(dp));

	QueryClientRankDP(dp, QueryClientStatsDP_4);
}

public QueryClientStatsDP_4(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_4 Query failed: %s", error);
		ScheduleDBReconnect(error);
		return;
	}

	ResetPack(dp);
	GetClientRank(owner, hndl, error, ReadPackCell(dp));

	QueryRank_1(dp, QueryClientStatsDP_5);
}

public QueryClientStatsDP_5(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_5 Query failed: %s", error);
		ScheduleDBReconnect(error);
		return;
	}

	ResetPack(dp);
	GetRankTotal(owner, hndl, error, ReadPackCell(dp));

	QueryRank_2(dp, QueryClientStatsDP_6);
}

public QueryClientStatsDP_6(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		if (dp != INVALID_HANDLE)
			CloseHandle(dp);

		LogError("QueryClientStatsDP_6 Query failed: %s", error);
		ScheduleDBReconnect(error);
		return;
	}

	ResetPack(dp);
	GetGameModeRankTotal(owner, hndl, error, ReadPackCell(dp));

	QuarterRank_QueryClientPointsDP(dp, QueryClientStatsDP_7);
}

public QueryClientStatsDP_7(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		if (dp != INVALID_HANDLE)
			CloseHandle(dp);

		LogError("QueryClientStatsDP_7 Query failed: %s", error);
		ScheduleDBReconnect(error);
		return;
	}

	ResetPack(dp);
	QuarterRank_GetClientPoints(owner, hndl, error, ReadPackCell(dp));

	QuarterRank_QueryClientRankDP(dp, QueryClientStatsDP_8);
}

public QueryClientStatsDP_8(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		if (dp != INVALID_HANDLE)
			CloseHandle(dp);

		LogError("QueryClientStatsDP_8 Query failed: %s", error);
		ScheduleDBReconnect(error);
		return;
	}

	ResetPack(dp);
	QuarterRank_GetClientRank(owner, hndl, error, ReadPackCell(dp));

	QuarterRank_QueryTotalDP(dp, QueryClientStatsDP_9);
}

public QueryClientStatsDP_9(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		if (dp != INVALID_HANDLE)
			CloseHandle(dp);

		LogError("QueryClientStatsDP_9 Query failed: %s", error);
		ScheduleDBReconnect(error);
		return;
	}

	decl String:SteamID[MAX_LINE_WIDTH];

	ResetPack(dp);

	new Client = ReadPackCell(dp);
	ReadPackString(dp, SteamID, sizeof(SteamID));
	new CallingMethod = ReadPackCell(dp);

	QuarterRank_GetTotal(owner, hndl, error, Client);

	// Callback
	if (CallingMethod == CM_RANK)
	{
		QueryClientStatsDP_Rank(Client, SteamID);
	}
	else if (CallingMethod == CM_TOP10)
	{
		QueryClientStatsDP_Top10(Client, SteamID);
	}
	else if (CallingMethod == CM_NEXTRANK)
	{
		QueryClientStatsDP_NextRank(Client, SteamID);
	}
	else if (CallingMethod == CM_NEXTRANKFULL)
	{
		QueryClientStatsDP_NextRankFull(Client, SteamID);
	}
	else if (CallingMethod == CM_PLAYERJOINED)
	{
		QueryClientStatsDP_PlayerJoined(Client, SteamID);
	}

	// Clean your mess up
	CloseHandle(dp);
	dp = INVALID_HANDLE;
}

QueryClientStatsDP_Rank(Client, const String:SteamID[])
{
	decl String:query[1024];
	Format(query, sizeof(query), "SELECT name, %s, %s, kills, versus_kills_survivors + scavenge_kills_survivors + realism_kills_survivors + mutations_kills_survivors, headshots FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPLAYTIME, DB_PLAYERS_TOTALPOINTS, DbPrefix, SteamID);
	SQL_TQuery(db, DisplayRank, query, Client);
}

QueryClientStatsDP_Top10(Client, const String:SteamID[])
{
	decl String:query[1024];
	Format(query, sizeof(query), "SELECT name, %s, %s, kills, versus_kills_survivors + scavenge_kills_survivors + realism_kills_survivors + mutations_kills_survivors, headshots FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPLAYTIME, DB_PLAYERS_TOTALPOINTS, DbPrefix, SteamID);
	SQL_TQuery(db, DisplayRank, query, Client);
}

QueryClientStatsDP_NextRank(Client, const String:SteamID[])
{
	decl String:query[1024];
	Format(query, sizeof(query), "SELECT (%s + 1) - %i FROM %splayers WHERE (%s) >= %i AND steamid <> '%s' ORDER BY (%s) ASC LIMIT 1", DB_PLAYERS_TOTALPOINTS, ClientPoints[Client], DbPrefix, DB_PLAYERS_TOTALPOINTS, ClientPoints[Client], SteamID, DB_PLAYERS_TOTALPOINTS);
	SQL_TQuery(db, DisplayClientNextRank, query, Client);

	if (TimerRankChangeCheck[Client] != INVALID_HANDLE)
		TriggerTimer(TimerRankChangeCheck[Client], true);
}

QueryClientStatsDP_NextRankFull(Client, const String:SteamID[])
{
	decl String:query[2048];
	Format(query, sizeof(query), "SELECT (%s + 1) - %i FROM %splayers WHERE (%s) >= %i AND steamid <> '%s' ORDER BY (%s) ASC LIMIT 1", DB_PLAYERS_TOTALPOINTS, ClientPoints[Client], DbPrefix, DB_PLAYERS_TOTALPOINTS, ClientPoints[Client], SteamID, DB_PLAYERS_TOTALPOINTS);
	SQL_TQuery(db, GetClientNextRank, query, Client);

	decl String:query1[1024], String:query2[256], String:query3[1024];
	Format(query1, sizeof(query1), "SELECT name, (%s) AS totalpoints FROM %splayers WHERE (%s) >= %i AND steamid <> '%s' ORDER BY totalpoints ASC LIMIT 3", DB_PLAYERS_TOTALPOINTS, DbPrefix, DB_PLAYERS_TOTALPOINTS, ClientPoints[Client], SteamID);
	Format(query2, sizeof(query2), "SELECT name, %i AS totalpoints FROM %splayers WHERE steamid = '%s'", ClientPoints[Client], DbPrefix, SteamID);
	Format(query3, sizeof(query3), "SELECT name, (%s) as totalpoints FROM %splayers WHERE (%s) < %i ORDER BY totalpoints DESC LIMIT 3", DB_PLAYERS_TOTALPOINTS, DbPrefix, DB_PLAYERS_TOTALPOINTS, ClientPoints[Client]);
	Format(query, sizeof(query), "(%s) UNION (%s) UNION (%s) ORDER BY totalpoints DESC", query1, query2, query3);
	SQL_TQuery(db, DisplayNextRankFull, query, Client);

	if (TimerRankChangeCheck[Client] != INVALID_HANDLE)
		TriggerTimer(TimerRankChangeCheck[Client], true);
}

// Check if a map is already in the DB.

CheckCurrentMapDB()
{
	if (StatsDisabled(true))
		return;

	decl String:MapName[MAX_LINE_WIDTH];
	GetCurrentMap(MapName, sizeof(MapName));

	decl String:query[512];
	Format(query, sizeof(query), "SELECT name FROM %smaps WHERE name = LOWER('%s') AND gamemode = %i AND mutation = '%s'", DbPrefix, MapName, GetCurrentGamemodeID(), CurrentMutation);

	SQL_TQuery(db, InsertMapDB, query);
}

// Insert a map into the database if they do not already exist.

public InsertMapDB(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (db == INVALID_HANDLE)
		return;

	if (StatsDisabled(true))
		return;

	if (!SQL_GetRowCount(hndl))
	{
		decl String:MapName[MAX_LINE_WIDTH];
		GetCurrentMap(MapName, sizeof(MapName));

		decl String:query[512];
		Format(query, sizeof(query), "INSERT IGNORE INTO %smaps SET name = LOWER('%s'), custom = 1, gamemode = %i", DbPrefix, MapName, GetCurrentGamemodeID());

		SQL_TQuery(db, SQLErrorCheckCallback, query);
	}
}

// Check if a player is already in the DB, and update their timestamp and playtime.

CheckPlayerDB(client)
{
	if (StatsDisabled())
		return;

	if (IsClientBot(client))
		return;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	decl String:query[512];
	Format(query, sizeof(query), "SELECT steamid FROM %splayers WHERE steamid = '%s'", DbPrefix, SteamID);
	SQL_TQuery(db, InsertPlayerDB, query, client);

	ReadClientRankMuteSteamID(client, SteamID);
}

ReadClientRankMute(Client)
{
	// Check stats disabled and is client bot before calling this method!

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));

	ReadClientRankMuteSteamID(Client, SteamID);
}

ReadClientRankMuteSteamID(Client, const String:SteamID[])
{
	// Check stats disabled and is client bot before calling this method!

	decl String:query[512];
	Format(query, sizeof(query), "SELECT mute FROM %ssettings WHERE steamid = '%s'", DbPrefix, SteamID);
	SQL_TQuery(db, GetClientRankMute, query, Client);
}

// Insert a player into the database if they do not already exist.

public InsertPlayerDB(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (db == INVALID_HANDLE || IsClientBot(client))
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("InsertPlayerDB failed! Reason: %s", error);
		return;
	}

	if (StatsDisabled())
	{
		return;
	}

	if (!SQL_GetRowCount(hndl))
	{
		new String:SteamID[MAX_LINE_WIDTH];
		GetClientRankAuthString(client, SteamID, sizeof(SteamID));

		new String:query[512];
		Format(query, sizeof(query), "INSERT IGNORE INTO %splayers SET steamid = '%s'", DbPrefix, SteamID);
		SQL_TQuery(db, SQLErrorCheckCallback, query);
	}

	UpdatePlayer(client);
}

// Insert a player into the settings database if they do not already exist.

public SetClientRankMute(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (db == INVALID_HANDLE || IsClientBot(client))
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("SetClientRankMute failed! Reason: %s", error);
		return;
	}

	if (StatsDisabled())
		return;

	if (SQL_GetAffectedRows(owner) == 0)
	{
		// Something went wrong!
		ClientRankMute[client] = false;
		return;
	}

	ReadClientRankMute(client);
}

// Insert a player into the settings database if they do not already exist.

public GetClientRankMute(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (db == INVALID_HANDLE || IsClientBot(client))
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientRankMute failed! Reason: %s", error);
		return;
	}

	if (StatsDisabled())
	{
		return;
	}

	if (!SQL_GetRowCount(hndl))
	{
		new String:SteamID[MAX_LINE_WIDTH];
		GetClientRankAuthString(client, SteamID, sizeof(SteamID));

		new String:query[512];
		Format(query, sizeof(query), "INSERT IGNORE INTO %ssettings SET steamid = '%s'", DbPrefix, SteamID);
		SQL_TQuery(db, SetClientRankMute, query, client);
	}
	else
	{
		while (SQL_FetchRow(hndl))
		{
			ClientRankMute[client] = (SQL_FetchInt(hndl, 0) != 0);
		}
	}
}

// Run a SQL query, used for UPDATE's only.

SendSQLUpdate(const String:query[], SQLTCallback:callback=INVALID_FUNCTION)
{
	if (db == INVALID_HANDLE)
	{
		return;
	}

	if (callback == INVALID_FUNCTION)
	{
		callback = SQLErrorCheckCallback;
	}

	if (DEBUG)
	{
		if (QueryCounter >= 256)
		{
			QueryCounter = 0;
		}

		new queryid = QueryCounter++;

		Format(QueryBuffer[queryid], MAX_QUERY_COUNTER, query);

		SQL_TQuery(db, callback, query, queryid);
	}
	else
	{
		SQL_TQuery(db, callback, query);
	}
}

// Report error on sql query;

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:queryid)
{
	if (db == INVALID_HANDLE)
	{
		return;
	}

		if(!StrEqual("", error))
		{
			if (IsDBConnectionLostError(error))
			{
				if (DEBUG)
					LogMessage("SQL connection lost: %s (Query: \"%s\")", error, QueryBuffer[queryid]);
				else
					LogMessage("SQL connection lost: %s", error);

				ScheduleDBReconnect(error);
				return;
			}

			if (DEBUG)
			{
				LogError("SQL Error: %s (Query: \"%s\")", error, QueryBuffer[queryid]);
		}
		else
		{
			LogError("SQL Error: %s", error);
		}

		ScheduleDBReconnect(error);
	}
}

stock bool IsPlayer(int client)
{
	int team = GetClientTeam(client);
	return (team == 2 || team == 3);
}

// Perform player update of name, playtime, and timestamp.

public UpdatePlayer(client)
{
	if (!IsClientConnected(client) && !IsClientInGame(client))
	{
		return;
	}


	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	decl String:Name[MAX_LINE_WIDTH];
	GetClientName(client, Name, sizeof(Name));

	ReplaceString(Name, sizeof(Name), "<?php", "");
	ReplaceString(Name, sizeof(Name), "<?PHP", "");
	ReplaceString(Name, sizeof(Name), "?>", "");
	ReplaceString(Name, sizeof(Name), "\\", "");
	ReplaceString(Name, sizeof(Name), "\"", "");
	ReplaceString(Name, sizeof(Name), "'", "");
	ReplaceString(Name, sizeof(Name), ";", "");
	ReplaceString(Name, sizeof(Name), "�", "");
	ReplaceString(Name, sizeof(Name), "`", "");

	UpdatePlayerFull(client, SteamID, Name);
}

// Perform player update of name, playtime, and timestamp.

public UpdatePlayerFull(Client, const String:SteamID[], const String:Name[])
{
	// Client can be ZERO! Look at UpdatePlayerCallback.

	decl String:Playtime[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(Playtime, sizeof(Playtime), "playtime_versus");
		}
		case GAMEMODE_REALISM:
		{
			Format(Playtime, sizeof(Playtime), "playtime_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(Playtime, sizeof(Playtime), "playtime_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(Playtime, sizeof(Playtime), "playtime_scavenge");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(Playtime, sizeof(Playtime), "playtime_realismversus");
		}
		case GAMEMODE_OTHERMUTATIONS:
		{
			Format(Playtime, sizeof(Playtime), "playtime_mutations");
		}
		default:
		{
			Format(Playtime, sizeof(Playtime), "playtime");
		}
	}

	decl String:IP[16];
	GetClientIP(Client, IP, sizeof(IP));

	decl String:query[512];	
	//方便网页显示具体游玩模式
	int mode = 0;
	if(IsAnne() == 1)
	{
		mode = 1;
	}else if(IsWitchParty())
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
	}else if(IsAnneShotgunMode())
	{
		mode = 7;
	}else if(IsAnne() == 2)
	{
		mode = 6;
	}
	//旁观者更新时间戳，但是不增加游戏时间，这样来方便统计在线人数
	if(!IsPlayer(Client) || !ModeStats_IsRankedMode())
		Format(query, sizeof(query), "UPDATE %splayers SET lastontime = UNIX_TIMESTAMP(), lastannemode = %i, lastgamemode = %i, name = '%s', ip = '%s' WHERE steamid = '%s'", DbPrefix, mode, CurrentGamemodeID, Name, IP, SteamID);
	else
		Format(query, sizeof(query), "UPDATE %splayers SET lastontime = UNIX_TIMESTAMP(), %s = %s + 1, lastannemode = %i, lastgamemode = %i, name = '%s', ip = '%s' WHERE steamid = '%s'", DbPrefix, Playtime, Playtime, mode, CurrentGamemodeID, Name, IP, SteamID);
	
	SQL_TQuery(db, UpdatePlayerCallback, query, Client);
	ModeStats_RecordPlaytime(Client, 1);
	QuarterRank_RecordPlaytime(Client, 1);
}

// Report error on sql query;

public UpdatePlayerCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (db == INVALID_HANDLE)
	{
		return;
	}

	if (!StrEqual("", error))
	{
		if (client > 0)
		{
			decl String:SteamID[MAX_LINE_WIDTH];
			GetClientRankAuthString(client, SteamID, sizeof(SteamID));

			UpdatePlayerFull(0, SteamID, "INVALID_CHARACTERS");

			return;
		}

		LogError("SQL Error: %s", error);
	}
}

// Perform a map stat update.
public UpdateMapStat(const String:Field[], Score)
{
	if (Score <= 0)
	{
		return;
	}

	decl String:MapName[64];
	GetCurrentMap(MapName, sizeof(MapName));

	decl String:DiffSQL[MAX_LINE_WIDTH];
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "normal", false)) Format(DiffSQL, sizeof(DiffSQL), "nor");
	else if (StrEqual(Difficulty, "hard", false)) Format(DiffSQL, sizeof(DiffSQL), "adv");
	else if (StrEqual(Difficulty, "impossible", false)) Format(DiffSQL, sizeof(DiffSQL), "exp");
	else return;

	decl String:FieldSQL[MAX_LINE_WIDTH];
	Format(FieldSQL, sizeof(FieldSQL), "%s_%s", Field, DiffSQL);

	decl String:query[512];
	Format(query, sizeof(query), "UPDATE %smaps SET %s = %s + %i WHERE name = LOWER('%s') and gamemode = %i", DbPrefix, FieldSQL, FieldSQL, Score, MapName, GetCurrentGamemodeID());
	SendSQLUpdate(query);
}

// Perform a map stat update.
public UpdateMapStatFloat(const String:Field[], Float:Value)
{
	if (Value <= 0)
	{
		return;
	}

	decl String:MapName[64];
	GetCurrentMap(MapName, sizeof(MapName));

	decl String:DiffSQL[MAX_LINE_WIDTH];
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "normal", false)) Format(DiffSQL, sizeof(DiffSQL), "nor");
	else if (StrEqual(Difficulty, "hard", false)) Format(DiffSQL, sizeof(DiffSQL), "adv");
	else if (StrEqual(Difficulty, "impossible", false)) Format(DiffSQL, sizeof(DiffSQL), "exp");
	else return;

	decl String:FieldSQL[MAX_LINE_WIDTH];
	Format(FieldSQL, sizeof(FieldSQL), "%s_%s", Field, DiffSQL);

	decl String:query[512];
	Format(query, sizeof(query), "UPDATE %smaps SET %s = %s + %f WHERE name = LOWER('%s') and gamemode = %i", DbPrefix, FieldSQL, FieldSQL, Value, MapName, GetCurrentGamemodeID());
	SendSQLUpdate(query);
}
