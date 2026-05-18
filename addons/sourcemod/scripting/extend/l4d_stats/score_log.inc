#if defined _l4d_stats_score_log_included
	#endinput
#endif
#define _l4d_stats_score_log_included

// 积分流水记录模块。
// 设计目标：每次 AddScore 都写一条独立流水，后续可以按玩家、地图、原因还原分数来源。

new Handle:cvar_ScoreLogEnable = INVALID_HANDLE;
new bool:g_bScoreLogTableReady = false;
new String:g_sScoreLogReason[MAX_LINE_WIDTH] = "";
new String:g_sScoreLogFormula[MAX_MESSAGE_WIDTH] = "";
new g_iScoreLogContextUses = 0;

stock ScoreLog_CreateCvars()
{
	cvar_ScoreLogEnable = CreateConVar("l4d_stats_scorelog_enable", "1", "是否记录每次积分加减流水。0=关闭, 1=开启", 0, true, 0.0, true, 1.0);
}

stock ScoreLog_EnsureTable()
{
	if (db == INVALID_HANDLE)
		return;

	decl String:query[2048];
	new len = 0;
	len += Format(query[len], sizeof(query) - len, "CREATE TABLE IF NOT EXISTS `%sscore_log` (", DbPrefix);
	len += Format(query[len], sizeof(query) - len, "`id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,");
	len += Format(query[len], sizeof(query) - len, "`created` int(11) NOT NULL,");
	len += Format(query[len], sizeof(query) - len, "`steamid` varchar(64) CHARACTER SET utf8mb4 NOT NULL,");
	len += Format(query[len], sizeof(query) - len, "`name` varchar(128) CHARACTER SET utf8mb4 NOT NULL,");
	len += Format(query[len], sizeof(query) - len, "`map` varchar(128) CHARACTER SET utf8mb4 NOT NULL,");
	len += Format(query[len], sizeof(query) - len, "`gamemode` int(2) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`difficulty` varchar(32) CHARACTER SET utf8mb4 NOT NULL DEFAULT '',");
	len += Format(query[len], sizeof(query) - len, "`team` int(2) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`score` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`score_after` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`reason` varchar(64) CHARACTER SET utf8mb4 NOT NULL DEFAULT 'unknown',");
	len += Format(query[len], sizeof(query) - len, "`formula` varchar(255) CHARACTER SET utf8mb4 NOT NULL DEFAULT '',");
	len += Format(query[len], sizeof(query) - len, "`round_valid` tinyint(1) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`usebuy` tinyint(1) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`newbie_count` int(4) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`newbie_multiplier` double NOT NULL DEFAULT '1',");
	len += Format(query[len], sizeof(query) - len, "PRIMARY KEY (`id`),");
	len += Format(query[len], sizeof(query) - len, "KEY `steamid_created` (`steamid`,`created`),");
	len += Format(query[len], sizeof(query) - len, "KEY `reason_created` (`reason`,`created`),");
	len += Format(query[len], sizeof(query) - len, "KEY `map_created` (`map`,`created`),");
	len += Format(query[len], sizeof(query) - len, "KEY `score_created` (`score`,`created`)");
	len += Format(query[len], sizeof(query) - len, ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

	g_bScoreLogTableReady = DoFastQuery(0, query);
	if (!g_bScoreLogTableReady)
	{
		if (IsDBReconnectPending() || db == INVALID_HANDLE)
			LogMessage("Score log table `%sscore_log` is not ready; waiting for database reconnect.", DbPrefix);
		else
			LogError("Failed to create score log table `%sscore_log`.", DbPrefix);
	}
}

stock ScoreLog_SetContext(const String:Reason[], const String:Formula[], Uses = 1)
{
	strcopy(g_sScoreLogReason, sizeof(g_sScoreLogReason), Reason);
	strcopy(g_sScoreLogFormula, sizeof(g_sScoreLogFormula), Formula);
	g_iScoreLogContextUses = Uses;

	if (g_iScoreLogContextUses <= 0)
		g_iScoreLogContextUses = 1;
}

stock ScoreLog_ClearContext()
{
	g_sScoreLogReason[0] = '\0';
	g_sScoreLogFormula[0] = '\0';
	g_iScoreLogContextUses = 0;
}

stock ScoreLog_ConsumeContext(String:Reason[], ReasonLength, String:Formula[], FormulaLength)
{
	if (g_sScoreLogReason[0] == '\0')
		strcopy(Reason, ReasonLength, "unknown");
	else
		strcopy(Reason, ReasonLength, g_sScoreLogReason);

	strcopy(Formula, FormulaLength, g_sScoreLogFormula);

	if (g_iScoreLogContextUses > 0)
	{
		g_iScoreLogContextUses--;
		if (g_iScoreLogContextUses <= 0)
			ScoreLog_ClearContext();
	}
}

stock ScoreLog_Record(Client, Score)
{
	decl String:Reason[MAX_LINE_WIDTH];
	decl String:Formula[MAX_MESSAGE_WIDTH];
	ScoreLog_ConsumeContext(Reason, sizeof(Reason), Formula, sizeof(Formula));

	if (Score == 0 || cvar_ScoreLogEnable == INVALID_HANDLE || !GetConVarBool(cvar_ScoreLogEnable))
		return;

	if (db == INVALID_HANDLE || !g_bScoreLogTableReady || !Stats_IsValidHumanClient(Client))
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	decl String:ClientName[128];
	GetClientName(Client, ClientName, sizeof(ClientName));

	decl String:MapName[128];
	GetCurrentMap(MapName, sizeof(MapName));

	decl String:Difficulty[32];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	decl String:EscClientID[MAX_LINE_WIDTH * 2 + 1];
	decl String:EscClientName[257];
	decl String:EscMapName[257];
	decl String:EscDifficulty[65];
	decl String:EscReason[MAX_LINE_WIDTH * 2 + 1];
	decl String:EscFormula[MAX_MESSAGE_WIDTH * 2 + 1];
	SQL_EscapeString(db, ClientID, EscClientID, sizeof(EscClientID));
	SQL_EscapeString(db, ClientName, EscClientName, sizeof(EscClientName));
	SQL_EscapeString(db, MapName, EscMapName, sizeof(EscMapName));
	SQL_EscapeString(db, Difficulty, EscDifficulty, sizeof(EscDifficulty));
	SQL_EscapeString(db, Reason, EscReason, sizeof(EscReason));
	SQL_EscapeString(db, Formula, EscFormula, sizeof(EscFormula));

	new RoundValid = 1;
	new UseBuy = 0;
	if (g_brpgAvailable)
	{
		RoundValid = L4D_RPG_GetGlobalValue(INDEX_VALID) ? 1 : 0;
		UseBuy = L4D_RPG_GetGlobalValue(INDEX_USEBUY) ? 1 : 0;
	}

	new NewbieCount = NewPlayerBonus_CountNewSurvivors();
	new Float:NewbieMultiplier = NewPlayerBonus_GetMultiplier();

	decl String:query[2048];
	Format(query, sizeof(query),
		"INSERT INTO `%sscore_log` (created, steamid, name, map, gamemode, difficulty, team, score, score_after, reason, formula, round_valid, usebuy, newbie_count, newbie_multiplier) VALUES (UNIX_TIMESTAMP(), '%s', '%s', '%s', %i, '%s', %i, %i, %i, '%s', '%s', %i, %i, %i, %.3f)",
		DbPrefix,
		EscClientID,
		EscClientName,
		EscMapName,
		CurrentGamemodeID,
		EscDifficulty,
		GetClientTeam(Client),
		Score,
		CurrentPoints[Client],
		EscReason,
		EscFormula,
		RoundValid,
		UseBuy,
		NewbieCount,
		NewbieMultiplier);
	SendSQLUpdate(query);
}
