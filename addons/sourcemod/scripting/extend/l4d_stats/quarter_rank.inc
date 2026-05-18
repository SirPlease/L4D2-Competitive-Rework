#if defined _l4d_stats_quarter_rank_included
	#endinput
#endif
#define _l4d_stats_quarter_rank_included

// 季度榜模块。
// 每次 AddScore 同步写入当前季度积分；季度切换时自动把当前榜清零。

new Handle:cvar_QuarterRankEnable = INVALID_HANDLE;
new bool:g_bQuarterRankTableReady = false;
new bool:g_bQuarterRankDbChecked = false;
new g_iQuarterRankKey = 0;
new QuarterRankTotal = 0;
new ClientQuarterPoints[MAXPLAYERS + 1];
new ClientQuarterPlayTime[MAXPLAYERS + 1];
new ClientQuarterRank[MAXPLAYERS + 1];
new CheckQuarterPlayerPoint[100];

stock QuarterRank_CreateCvars()
{
	cvar_QuarterRankEnable = CreateConVar("l4d_stats_quarter_rank_enable", "1", "是否启用季度积分榜。0=关闭, 1=开启", 0, true, 0.0, true, 1.0);
}

stock QuarterRank_GetCurrentKey()
{
	decl String:YearText[8];
	decl String:MonthText[4];
	FormatTime(YearText, sizeof(YearText), "%Y", GetTime());
	FormatTime(MonthText, sizeof(MonthText), "%m", GetTime());

	new Year = StringToInt(YearText);
	new Month = StringToInt(MonthText);
	new Quarter = ((Month - 1) / 3) + 1;

	return Year * 10 + Quarter;
}

stock QuarterRank_GetCurrentQuarter()
{
	return QuarterRank_GetCurrentKey();
}

stock QuarterRank_FormatCurrentQuarter(String:buffer[], maxlength)
{
	new QuarterKey = QuarterRank_GetCurrentQuarter();
	new Year = QuarterKey / 10;
	new Quarter = QuarterKey % 10;
	Format(buffer, maxlength, "%i年第%i季度", Year, Quarter);
}

stock QuarterRank_EnsureTable()
{
	if (db == INVALID_HANDLE)
		return;

	decl String:query[4096];
	new len = 0;
	len += Format(query[len], sizeof(query) - len, "CREATE TABLE IF NOT EXISTS `%sscore_quarter` (", DbPrefix);
	len += Format(query[len], sizeof(query) - len, "`steamid` varchar(64) CHARACTER SET utf8mb4 NOT NULL,");
	len += Format(query[len], sizeof(query) - len, "`quarter_key` int(8) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`points` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`playtime` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`points_coop` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`points_survivors` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`points_infected` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`points_survival` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`points_realism` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`points_scavenge_survivors` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`points_scavenge_infected` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`points_realism_survivors` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`points_realism_infected` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`points_mutations` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`kills` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`headshots` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`melee_kills` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`kill_infected` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`kill_hunter` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`kill_smoker` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`kill_boomer` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`kill_spitter` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`kill_jockey` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`kill_charger` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`award_medkit` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`award_pills` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`award_adrenaline` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`award_revive` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`award_defib` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`award_rescue` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`award_protect` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`award_friendlyfire` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`award_teamkill` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`award_fincap` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`award_left4dead` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`award_letinsafehouse` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`award_witchdisturb` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "`updated` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query) - len, "PRIMARY KEY (`steamid`),");
	len += Format(query[len], sizeof(query) - len, "KEY `quarter_points` (`quarter_key`,`points`),");
	len += Format(query[len], sizeof(query) - len, "KEY `points` (`points`)");
	len += Format(query[len], sizeof(query) - len, ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

	g_bQuarterRankTableReady = DoFastQuery(0, query);
	if (!g_bQuarterRankTableReady && db != INVALID_HANDLE)
	{
		// CREATE TABLE 可能因共享连接的串台错误而失败，用 SELECT 回查验证表是否实际存在
		if (DoFastQuery(0, "SELECT 1 FROM `%sscore_quarter` LIMIT 0", DbPrefix))
		{
			g_bQuarterRankTableReady = true;
			LogMessage("[l4d_stats] score_quarter 表已存在，忽略 CREATE TABLE 错误。");
		}
		else
		{
			LogError("Failed to create quarter rank table `%sscore_quarter`.", DbPrefix);
			return;
		}
	}
	else if (!g_bQuarterRankTableReady)
	{
		return;
	}

	QuarterRank_EnsureCurrentQuarter();
}

stock QuarterRank_EnsurePlaytimeColumn()
{
	if (db == INVALID_HANDLE)
		return;

	decl String:query[1024];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '%sscore_quarter' AND COLUMN_NAME = 'playtime'", DbPrefix);
	SQL_TQuery(db, QuarterRank_CheckPlaytimeColumn, query);
}

public QuarterRank_CheckPlaytimeColumn(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QuarterRank_CheckPlaytimeColumn Query failed: %s", error);
		return;
	}

	if (!SQL_HasResultSet(hndl))
	{
		LogMessage("QuarterRank_CheckPlaytimeColumn returned no result set; waiting for the next database check.");
		return;
	}

	if (!SQL_FetchRow(hndl) || SQL_FetchInt(hndl, 0) <= 0)
		DoFastQuery(0, "ALTER TABLE `%sscore_quarter` ADD COLUMN `playtime` int(11) NOT NULL DEFAULT '0' AFTER `points`", DbPrefix);
}

stock QuarterRank_ResetLocalCache()
{
	QuarterRankTotal = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		ClientQuarterPoints[i] = 0;
		ClientQuarterPlayTime[i] = 0;
		ClientQuarterRank[i] = 0;
	}

	for (new i = 0; i < 100; i++)
	{
		CheckQuarterPlayerPoint[i] = 0;
	}
}

stock QuarterRank_EnsureCurrentQuarter()
{
	new CurrentKey = QuarterRank_GetCurrentKey();
	if (g_iQuarterRankKey == CurrentKey && (!g_bQuarterRankTableReady || g_bQuarterRankDbChecked))
		return;

	if (g_iQuarterRankKey != CurrentKey)
	{
		g_iQuarterRankKey = CurrentKey;
		g_bQuarterRankDbChecked = false;
		QuarterRank_ResetLocalCache();
	}

	if (db == INVALID_HANDLE || !g_bQuarterRankTableReady)
		return;

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE `%sscore_quarter` SET quarter_key = %i, points = 0, playtime = 0, updated = UNIX_TIMESTAMP() WHERE quarter_key <> %i", DbPrefix, g_iQuarterRankKey, g_iQuarterRankKey);
	SendSQLUpdate(query);
	g_bQuarterRankDbChecked = true;
}

stock bool:QuarterRank_Enabled()
{
	if (cvar_QuarterRankEnable == INVALID_HANDLE || !GetConVarBool(cvar_QuarterRankEnable))
		return false;

	if (db == INVALID_HANDLE || !g_bQuarterRankTableReady)
		return false;

	return true;
}

stock QuarterRank_GetModePointsColumn(Client, String:buffer[], maxlength)
{
	Stats_GetPointsColumnForTeam(GetClientTeam(Client), buffer, maxlength);
	if (StrEqual(buffer, "points"))
		Format(buffer, maxlength, "points_coop");
}

stock QuarterRank_RecordScore(Client, Score)
{
	if (Score == 0)
		return;

	QuarterRank_EnsureCurrentQuarter();

	if (!QuarterRank_Enabled() || !Stats_IsValidHumanClient(Client))
		return;

	ClientQuarterPoints[Client] += Score;
	if (ClientQuarterPoints[Client] < 0)
		ClientQuarterPoints[Client] = 0;

	decl String:SteamID[MAX_LINE_WIDTH];
	decl String:EscSteamID[MAX_LINE_WIDTH * 2 + 1];
	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));
	SQL_EscapeString(db, SteamID, EscSteamID, sizeof(EscSteamID));

	new InsertScore = Score;
	if (InsertScore < 0)
		InsertScore = 0;

	decl String:ModePointsColumn[32];
	QuarterRank_GetModePointsColumn(Client, ModePointsColumn, sizeof(ModePointsColumn));

	decl String:query[1024];
	Format(query, sizeof(query), "INSERT INTO `%sscore_quarter` (steamid, quarter_key, points, `%s`, updated) VALUES ('%s', %i, %i, %i, UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE points = IF(quarter_key = VALUES(quarter_key), GREATEST(points + %i, 0), VALUES(points)), `%s` = IF(quarter_key = VALUES(quarter_key), GREATEST(`%s` + %i, 0), VALUES(`%s`)), quarter_key = VALUES(quarter_key), updated = VALUES(updated)",
		DbPrefix, ModePointsColumn, EscSteamID, g_iQuarterRankKey, InsertScore, InsertScore, Score, ModePointsColumn, ModePointsColumn, Score, ModePointsColumn);
	SendSQLUpdate(query);
}

stock QuarterRank_RecordField(Client, const String:Field[], Amount)
{
	if (Amount <= 0)
		return;

	QuarterRank_EnsureCurrentQuarter();

	if (!QuarterRank_Enabled() || StatsDisabled() || !Stats_IsValidHumanClient(Client))
		return;

	decl String:SteamID[MAX_LINE_WIDTH];
	decl String:EscSteamID[MAX_LINE_WIDTH * 2 + 1];
	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));
	SQL_EscapeString(db, SteamID, EscSteamID, sizeof(EscSteamID));

	decl String:query[1024];
	Format(query, sizeof(query), "INSERT INTO `%sscore_quarter` (steamid, quarter_key, `%s`, updated) VALUES ('%s', %i, %i, UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE `%s` = IF(quarter_key = VALUES(quarter_key), `%s` + VALUES(`%s`), VALUES(`%s`)), quarter_key = VALUES(quarter_key), updated = VALUES(updated)",
		DbPrefix, Field, EscSteamID, g_iQuarterRankKey, Amount, Field, Field, Field, Field);
	SendSQLUpdate(query);
}

stock QuarterRank_RecordInfectedKill(Client, const String:InfectedType[], Kills, Headshots = 0)
{
	if (Kills <= 0)
		return;

	QuarterRank_EnsureCurrentQuarter();

	if (!QuarterRank_Enabled() || StatsDisabled() || !Stats_IsValidHumanClient(Client))
		return;

	if (Headshots < 0)
		Headshots = 0;

	decl String:SteamID[MAX_LINE_WIDTH];
	decl String:EscSteamID[MAX_LINE_WIDTH * 2 + 1];
	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));
	SQL_EscapeString(db, SteamID, EscSteamID, sizeof(EscSteamID));

	decl String:KillColumn[32];
	Format(KillColumn, sizeof(KillColumn), "kill_%s", InfectedType);

	decl String:query[1024];
	Format(query, sizeof(query), "INSERT INTO `%sscore_quarter` (steamid, quarter_key, kills, headshots, `%s`, updated) VALUES ('%s', %i, %i, %i, %i, UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE kills = IF(quarter_key = VALUES(quarter_key), kills + VALUES(kills), VALUES(kills)), headshots = IF(quarter_key = VALUES(quarter_key), headshots + VALUES(headshots), VALUES(headshots)), `%s` = IF(quarter_key = VALUES(quarter_key), `%s` + VALUES(`%s`), VALUES(`%s`)), quarter_key = VALUES(quarter_key), updated = VALUES(updated)",
		DbPrefix, KillColumn, EscSteamID, g_iQuarterRankKey, Kills, Headshots, Kills, KillColumn, KillColumn, KillColumn, KillColumn);
	SendSQLUpdate(query);
}

stock QuarterRank_RecordPlaytime(Client, Minutes)
{
	if (Minutes <= 0)
		return;

	QuarterRank_EnsureCurrentQuarter();

	if (!QuarterRank_Enabled() || StatsDisabled() || !Stats_IsValidHumanClient(Client))
		return;

	new team = GetClientTeam(Client);
	if (team != TEAM_SURVIVORS && team != TEAM_INFECTED)
		return;

	ClientQuarterPlayTime[Client] += Minutes;

	decl String:SteamID[MAX_LINE_WIDTH];
	decl String:EscSteamID[MAX_LINE_WIDTH * 2 + 1];
	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));
	SQL_EscapeString(db, SteamID, EscSteamID, sizeof(EscSteamID));

	decl String:query[512];
	Format(query, sizeof(query), "INSERT INTO `%sscore_quarter` (steamid, quarter_key, playtime, updated) VALUES ('%s', %i, %i, UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE playtime = IF(quarter_key = VALUES(quarter_key), playtime + VALUES(playtime), VALUES(playtime)), quarter_key = VALUES(quarter_key), updated = VALUES(updated)",
		DbPrefix, EscSteamID, g_iQuarterRankKey, Minutes);
	SendSQLUpdate(query);
}

stock QuarterRank_QueryClient(Client)
{
	if (!QuarterRank_Enabled() || !Stats_IsValidHumanClient(Client))
		return;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));
	QuarterRank_QueryClientPointsSteamID(Client, SteamID);
}

stock QuarterRank_QueryClientPointsSteamID(Client, const String:SteamID[], SQLTCallback:callback=INVALID_FUNCTION)
{
	if (callback == INVALID_FUNCTION)
		callback = QuarterRank_GetClientPoints;

	QuarterRank_EnsureCurrentQuarter();

	decl String:EscSteamID[MAX_LINE_WIDTH * 2 + 1];
	SQL_EscapeString(db, SteamID, EscSteamID, sizeof(EscSteamID));

	decl String:query[512];
	Format(query, sizeof(query), "SELECT points, playtime FROM `%sscore_quarter` WHERE steamid = '%s' AND quarter_key = %i", DbPrefix, EscSteamID, g_iQuarterRankKey);
	SQL_TQuery(db, callback, query, Client);
}

stock QuarterRank_QueryClientPointsDP(Handle:dp, SQLTCallback:callback)
{
	QuarterRank_EnsureCurrentQuarter();
	if (!QuarterRank_Enabled())
	{
		SQL_TQuery(db, callback, "SELECT 0, 0", dp);
		return;
	}

	decl String:SteamID[MAX_LINE_WIDTH];
	ResetPack(dp);
	ReadPackCell(dp);
	ReadPackString(dp, SteamID, sizeof(SteamID));

	decl String:EscSteamID[MAX_LINE_WIDTH * 2 + 1];
	SQL_EscapeString(db, SteamID, EscSteamID, sizeof(EscSteamID));

	decl String:query[512];
	Format(query, sizeof(query), "SELECT points, playtime FROM `%sscore_quarter` WHERE steamid = '%s' AND quarter_key = %i", DbPrefix, EscSteamID, g_iQuarterRankKey);
	SQL_TQuery(db, callback, query, dp);
}

public QuarterRank_GetClientPoints(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("QuarterRank_GetClientPoints Query failed: %s", error);
		return;
	}

	ClientQuarterPoints[client] = 0;
	ClientQuarterPlayTime[client] = 0;
	if (SQL_FetchRow(hndl))
	{
		ClientQuarterPoints[client] = SQL_FetchInt(hndl, 0);
		ClientQuarterPlayTime[client] = SQL_FetchInt(hndl, 1);
	}
}

stock QuarterRank_QueryClientRank(Client, SQLTCallback:callback=INVALID_FUNCTION)
{
	if (callback == INVALID_FUNCTION)
		callback = QuarterRank_GetClientRank;

	QuarterRank_EnsureCurrentQuarter();

	decl String:query[512];
	if (ClientQuarterPoints[Client] <= 0)
		Format(query, sizeof(query), "SELECT 0");
	else
		Format(query, sizeof(query), "SELECT COUNT(*) FROM `%sscore_quarter` WHERE quarter_key = %i AND points >= %i AND points > 0", DbPrefix, g_iQuarterRankKey, ClientQuarterPoints[Client]);

	SQL_TQuery(db, callback, query, Client);
}

stock QuarterRank_QueryClientRankDP(Handle:dp, SQLTCallback:callback)
{
	QuarterRank_EnsureCurrentQuarter();
	if (!QuarterRank_Enabled())
	{
		SQL_TQuery(db, callback, "SELECT 0", dp);
		return;
	}

	ResetPack(dp);
	new Client = ReadPackCell(dp);

	decl String:query[512];
	if (ClientQuarterPoints[Client] <= 0)
		Format(query, sizeof(query), "SELECT 0");
	else
		Format(query, sizeof(query), "SELECT COUNT(*) FROM `%sscore_quarter` WHERE quarter_key = %i AND points >= %i AND points > 0", DbPrefix, g_iQuarterRankKey, ClientQuarterPoints[Client]);

	SQL_TQuery(db, callback, query, dp);
}

public QuarterRank_GetClientRank(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("QuarterRank_GetClientRank Query failed: %s", error);
		return;
	}

	ClientQuarterRank[client] = 0;
	if (SQL_FetchRow(hndl))
		ClientQuarterRank[client] = SQL_FetchInt(hndl, 0);
}

stock QuarterRank_QueryTotal(SQLTCallback:callback=INVALID_FUNCTION, any:data=0)
{
	if (callback == INVALID_FUNCTION)
		callback = QuarterRank_GetTotal;

	QuarterRank_EnsureCurrentQuarter();

	decl String:query[256];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM `%sscore_quarter` WHERE quarter_key = %i AND points > 0", DbPrefix, g_iQuarterRankKey);
	SQL_TQuery(db, callback, query, data);
}

stock QuarterRank_QueryTotalDP(Handle:dp, SQLTCallback:callback)
{
	QuarterRank_EnsureCurrentQuarter();
	if (!QuarterRank_Enabled())
	{
		SQL_TQuery(db, callback, "SELECT 0", dp);
		return;
	}

	decl String:query[256];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM `%sscore_quarter` WHERE quarter_key = %i AND points > 0", DbPrefix, g_iQuarterRankKey);
	SQL_TQuery(db, callback, query, dp);
}

public QuarterRank_GetTotal(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QuarterRank_GetTotal Query failed: %s", error);
		return;
	}

	QuarterRankTotal = 0;
	if (SQL_FetchRow(hndl))
		QuarterRankTotal = SQL_FetchInt(hndl, 0);
}

stock QuarterRank_QueryTop100Scores()
{
	if (!QuarterRank_Enabled())
		return;

	QuarterRank_EnsureCurrentQuarter();

	decl String:query[256];
	Format(query, sizeof(query), "SELECT points FROM `%sscore_quarter` WHERE quarter_key = %i AND points > 0 ORDER BY points DESC LIMIT 100", DbPrefix, g_iQuarterRankKey);
	SQL_TQuery(db, QuarterRank_GetTop100Scores, query, 0);
}

public QuarterRank_GetTop100Scores(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QuarterRank_GetTop100Scores failed! Reason: %s", error);
		return;
	}

	new i = 0;
	while (i < 100)
	{
		CheckQuarterPlayerPoint[i++] = 0;
	}

	i = 0;
	while (SQL_FetchRow(hndl) && i < 100)
	{
		CheckQuarterPlayerPoint[i++] = SQL_FetchInt(hndl, 0);
	}
}
