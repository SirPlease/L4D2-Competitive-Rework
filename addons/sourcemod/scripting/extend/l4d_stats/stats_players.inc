#if defined _l4d_stats_players_included
	#endinput
#endif
#define _l4d_stats_players_included

stock bool:Stats_IsValidClient(client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	if (!IsClientConnected(client) || !IsClientInGame(client))
		return false;

	return true;
}

stock Stats_ClientFromEntityOrUserId(value)
{
	if (Stats_IsValidClient(value))
		return value;

	return GetClientOfUserId(value);
}

stock bool:Stats_IsRpgRoundValid()
{
	return !g_brpgAvailable || L4D_RPG_GetGlobalValue(INDEX_VALID);
}

// 统一的人类玩家校验入口。
// 旧代码里同类判断分散在事件中，新模块尽量先复用这里，减少以后扩展奖励时漏判 bot/未进服玩家。
stock bool:Stats_IsValidHumanClient(client)
{
	if (!Stats_IsValidClient(client))
		return false;

	if (IsClientBot(client))
		return false;

	return true;
}

// 有效且正在幸存者队伍的人类玩家。
stock bool:Stats_IsSurvivorHuman(client)
{
	return Stats_IsValidHumanClient(client) && GetClientTeam(client) == TEAM_SURVIVORS;
}

// 有效且正在感染者队伍的人类玩家。
stock bool:Stats_IsInfectedHuman(client)
{
	return Stats_IsValidHumanClient(client) && GetClientTeam(client) == TEAM_INFECTED;
}

// 正在参与本局的人类玩家；旁观者不计入计分人数门槛。
stock bool:Stats_IsPlayingHuman(client)
{
	if (!Stats_IsValidHumanClient(client))
		return false;

	new team = GetClientTeam(client);
	return team == TEAM_SURVIVORS || team == TEAM_INFECTED;
}

stock Stats_CountPlayingHumans()
{
	new humans = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Stats_IsPlayingHuman(i))
			humans++;
	}

	return humans;
}

stock bool:Stats_HasPlaytimeStarted()
{
	if (CurrentGamemodeID == GAMEMODE_SURVIVAL)
		return SurvivalStarted;

	if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
		return g_bStatsPlaytimeStarted;

	return g_bStatsPlaytimeStarted || L4D_HasAnySurvivorLeftSafeArea();
}

stock bool:Stats_ShouldCountClientPlaytime(Client)
{
	if (!Stats_HasPlaytimeStarted() || !Stats_IsValidHumanClient(Client))
		return false;

	new team = GetClientTeam(Client);
	return team == TEAM_SURVIVORS || team == TEAM_INFECTED;
}
