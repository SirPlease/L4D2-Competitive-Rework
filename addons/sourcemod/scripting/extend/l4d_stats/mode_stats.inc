#if defined _l4d_stats_mode_stats_included
	#endinput
#endif
#define _l4d_stats_mode_stats_included

// Per-mode efficiency stats. This is the canonical source for mode-scoped PPM/KPM.

new bool:g_bModeStatsTableReady = true;

stock ModeStats_GetAnneMode()
{
	if (IsAnne() == 1)
		return 1;
	if (IsWitchParty())
		return 2;
	if (IsAllCharger())
		return 3;
	if (IsAlone())
		return 4;
	if (Is1vht())
		return 5;
	if (IsAnneShotgunMode())
		return 7;
	if (IsAnne() == 2)
		return 6;

	return 0;
}

stock bool:ModeStats_IsRankedMode()
{
	// These modes intentionally inflate or suppress normal scoring, so keep them out of legacy main playtime.
	// They are still tracked separately in player_mode_stats through ModeStats_ShouldTrackClient().
	if (IsWitchParty() || IsAllCharger() || IsAlone() || Is1vht())
		return false;

	return true;
}

stock bool:ModeStats_ShouldTrackClient(Client)
{
	if (db == INVALID_HANDLE || !g_bModeStatsTableReady)
		return false;

	if (Client <= 0 || Client > MaxClients)
		return false;

	if (!IsClientConnected(Client) || !IsClientInGame(Client) || IsClientBot(Client))
		return false;

	new team = GetClientTeam(Client);
	if (team != TEAM_SURVIVORS && team != TEAM_INFECTED)
		return false;

	if (StatsDisabled())
		return false;

	return true;
}

stock ModeStats_RecordPlaytime(Client, Minutes)
{
	if (Minutes <= 0 || !Stats_ShouldCountClientPlaytime(Client) || !ModeStats_ShouldTrackClient(Client))
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	decl String:query[512];
	Format(query, sizeof(query),
		"INSERT INTO `%splayer_mode_stats` (steamid, mode_id, anne_mode, playtime, updated) VALUES ('%s', %i, %i, %i, UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE playtime = playtime + %i, updated = UNIX_TIMESTAMP()",
		DbPrefix,
		ClientID,
		Stats_GetCurrentStatsGamemodeID(),
		ModeStats_GetAnneMode(),
		Minutes,
		Minutes);
	SendSQLUpdate(query);
}

stock ModeStats_RecordScore(Client, Score)
{
	if (Score == 0 || !ModeStats_ShouldTrackClient(Client))
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	decl String:query[512];
	Format(query, sizeof(query),
		"INSERT INTO `%splayer_mode_stats` (steamid, mode_id, anne_mode, points, updated) VALUES ('%s', %i, %i, %i, UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE points = points + %i, updated = UNIX_TIMESTAMP()",
		DbPrefix,
		ClientID,
		Stats_GetCurrentStatsGamemodeID(),
		ModeStats_GetAnneMode(),
		Score,
		Score);
	SendSQLUpdate(query);
}

stock ModeStats_RecordKills(Client, Kills, Headshots = 0)
{
	if (Kills <= 0 || !ModeStats_ShouldTrackClient(Client))
		return;

	if (Headshots < 0)
		Headshots = 0;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	decl String:query[512];
	Format(query, sizeof(query),
		"INSERT INTO `%splayer_mode_stats` (steamid, mode_id, anne_mode, kills, headshots, updated) VALUES ('%s', %i, %i, %i, %i, UNIX_TIMESTAMP()) ON DUPLICATE KEY UPDATE kills = kills + %i, headshots = headshots + %i, updated = UNIX_TIMESTAMP()",
		DbPrefix,
		ClientID,
		Stats_GetCurrentStatsGamemodeID(),
		ModeStats_GetAnneMode(),
		Kills,
		Headshots,
		Kills,
		Headshots);
	SendSQLUpdate(query);
}
