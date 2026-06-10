#if defined _l4d_stats_score_included
	#endinput
#endif
#define _l4d_stats_score_included

stock bool:Stats_IsAnneStatsMode()
{
	decl String:plugin_name[MAX_LINE_WIDTH];
	if (cvar_mode == null && FindConVar("l4d_ready_cfg_name"))
	{
		cvar_mode = FindConVar("l4d_ready_cfg_name");
	}

	if (cvar_mode == null)
		return false;

	GetConVarString(cvar_mode, plugin_name, sizeof(plugin_name));
	return StrContains(plugin_name, "AnneHappy", false) != -1
		|| StrContains(plugin_name, "WitchParty", false) != -1
		|| StrContains(plugin_name, "AllCharger", false) != -1
		|| StrContains(plugin_name, "Alone", false) != -1
		|| StrContains(plugin_name, "1vHunters", false) != -1;
}

// Anne 系可以运行在 versus 底座上，但积分和记录仍归入战役桶。
stock Stats_GetCurrentStatsGamemodeID()
{
	if (Stats_IsAnneStatsMode() &&
			(CurrentGamemodeID == GAMEMODE_VERSUS || CurrentGamemodeID == GAMEMODE_REALISMVERSUS))
	{
		return GAMEMODE_COOP;
	}

	return CurrentGamemodeID;
}

stock Stats_GetPointsColumnForModeAndTeam(Mode, ClientTeam, String:UpdatePoints[], MaxLength)
{
	switch (Mode)
	{
		case GAMEMODE_VERSUS:
		{
			if (ClientTeam == TEAM_INFECTED)
				Format(UpdatePoints, MaxLength, "points_infected");
			else
				Format(UpdatePoints, MaxLength, "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, MaxLength, "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, MaxLength, "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			if (ClientTeam == TEAM_INFECTED)
				Format(UpdatePoints, MaxLength, "points_scavenge_infected");
			else
				Format(UpdatePoints, MaxLength, "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			if (ClientTeam == TEAM_INFECTED)
				Format(UpdatePoints, MaxLength, "points_realism_infected");
			else
				Format(UpdatePoints, MaxLength, "points_realism_survivors");
		}
		case GAMEMODE_OTHERMUTATIONS:
		{
			Format(UpdatePoints, MaxLength, "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, MaxLength, "points");
		}
	}
}

// 根据当前统计模式和玩家队伍选择 players 表里的积分列。
// 新增奖励时优先走这个函数，避免每个事件都复制一份 switch。
stock Stats_GetPointsColumnForTeam(ClientTeam, String:UpdatePoints[], MaxLength)
{
	Stats_GetPointsColumnForModeAndTeam(Stats_GetCurrentStatsGamemodeID(), ClientTeam, UpdatePoints, MaxLength);
}

stock Stats_GetMapPointsFieldForTeam(ClientTeam, String:Field[], MaxLength)
{
	new Mode = Stats_GetCurrentStatsGamemodeID();
	if (ClientTeam == TEAM_INFECTED &&
			(Mode == GAMEMODE_VERSUS || Mode == GAMEMODE_SCAVENGE || Mode == GAMEMODE_REALISMVERSUS))
	{
		Format(Field, MaxLength, "points_infected");
		return;
	}

	Format(Field, MaxLength, "points");
}

stock Stats_GetPlaytimeColumnForMode(Mode, String:Playtime[], MaxLength)
{
	switch (Mode)
	{
		case GAMEMODE_VERSUS:
		{
			Format(Playtime, MaxLength, "playtime_versus");
		}
		case GAMEMODE_REALISM:
		{
			Format(Playtime, MaxLength, "playtime_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(Playtime, MaxLength, "playtime_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(Playtime, MaxLength, "playtime_scavenge");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(Playtime, MaxLength, "playtime_realismversus");
		}
		case GAMEMODE_OTHERMUTATIONS:
		{
			Format(Playtime, MaxLength, "playtime_mutations");
		}
		default:
		{
			Format(Playtime, MaxLength, "playtime");
		}
	}
}

// 给单个玩家发放积分，并同步当前地图积分统计。
// ExtraSet 用于追加 ", award_x = award_x + 1" 这类同表字段更新。
stock bool:Stats_AwardClientScore(Client, Score, const String:ExtraSet[] = "", bool:UpdateMapPoints = true)
{
	if (db == INVALID_HANDLE || StatsDisabled() || !Stats_IsValidHumanClient(Client) || Score == 0)
		return false;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	decl String:UpdatePoints[32];
	Stats_GetPointsColumnForTeam(GetClientTeam(Client), UpdatePoints, sizeof(UpdatePoints));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i%s WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, ExtraSet, ClientID);
	SendSQLUpdate(query);

	if (UpdateMapPoints && Score > 0)
		UpdateMapStat("points", Score);

	AddScore(Client, Score);
	return true;
}
