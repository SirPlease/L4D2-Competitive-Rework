#if defined _l4d_stats_players_included
	#endinput
#endif
#define _l4d_stats_players_included

// 统一的人类玩家校验入口。
// 旧代码里同类判断分散在事件中，新模块尽量先复用这里，减少以后扩展奖励时漏判 bot/未进服玩家。
stock bool:Stats_IsValidHumanClient(client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	if (!IsClientConnected(client) || !IsClientInGame(client))
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
