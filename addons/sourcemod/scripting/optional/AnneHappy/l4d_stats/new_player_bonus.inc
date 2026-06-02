#if defined _l4d_stats_new_player_bonus_included
	#endinput
#endif
#define _l4d_stats_new_player_bonus_included

new Handle:cvar_NewPlayerBonusEnable = INVALID_HANDLE;
new Handle:cvar_NewPlayerBonusPlaytime = INVALID_HANDLE;
new Handle:cvar_NewPlayerBonusMaxPoints = INVALID_HANDLE;
new Handle:cvar_NewPlayerBonusFirstMultiplier = INVALID_HANDLE;
new Handle:cvar_NewPlayerBonusExtraMultiplier = INVALID_HANDLE;
new Handle:cvar_NewPlayerBonusMaxMultiplier = INVALID_HANDLE;
new bool:g_bNewPlayerBonusRoundAnnounced = false;

// 带新人奖励配置：
// - 同时以累计游玩时间和总分判断新人。
// - 新人本身不吃带新倍率，非新人幸存者才会吃倍率。
// - 默认 1 名新人 x1.1，之后每多 1 名新人 +0.2，即 2 名 x1.3、3 名 x1.5。
stock NewPlayerBonus_CreateCvars()
{
	cvar_NewPlayerBonusEnable = CreateConVar("l4d_stats_newbie_bonus_enable", "1", "是否启用带新人分数倍率。0=关闭, 1=开启", 0, true, 0.0, true, 1.0);
	cvar_NewPlayerBonusPlaytime = CreateConVar("l4d_stats_newbie_bonus_playtime", "4320", "累计游玩时间低于该分钟数时才可能视为新人。", 0, true, 0.0);
	cvar_NewPlayerBonusMaxPoints = CreateConVar("l4d_stats_newbie_bonus_maxpoints", "200000", "总分低于该值时才可能视为新人。", 0, true, 0.0);
	cvar_NewPlayerBonusFirstMultiplier = CreateConVar("l4d_stats_newbie_bonus_first_multiplier", "1.1", "带 1 名新人时的分数倍率。", 0, true, 1.0);
	cvar_NewPlayerBonusExtraMultiplier = CreateConVar("l4d_stats_newbie_bonus_extra_multiplier", "0.2", "第 2 名新人开始，每多 1 名新人额外增加的倍率。", 0, true, 0.0);
	cvar_NewPlayerBonusMaxMultiplier = CreateConVar("l4d_stats_newbie_bonus_max_multiplier", "0.0", "带新人分数倍率上限。0=不限制", 0, true, 0.0);
}

stock NewPlayerBonus_ResetRound()
{
	g_bNewPlayerBonusRoundAnnounced = false;
}

stock bool:NewPlayerBonus_IsNewPlayer(client)
{
	if (!Stats_IsSurvivorHuman(client))
		return false;

	// ClientPlayTime / ClientPoints 在玩家授权后从 DB 异步读取；新入库或尚未有记录时为 0，按新人处理。
	return ClientPlayTime[client] < GetConVarInt(cvar_NewPlayerBonusPlaytime) &&
		ClientPoints[client] < GetConVarInt(cvar_NewPlayerBonusMaxPoints);
}

stock NewPlayerBonus_CountNewSurvivors()
{
	new Count = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (NewPlayerBonus_IsNewPlayer(i))
			Count++;
	}

	return Count;
}

stock Float:NewPlayerBonus_GetMultiplier()
{
	if (!GetConVarBool(cvar_NewPlayerBonusEnable))
		return 1.0;

	new NewPlayerCount = NewPlayerBonus_CountNewSurvivors();
	if (NewPlayerCount <= 0)
		return 1.0;

	new Float:Multiplier = GetConVarFloat(cvar_NewPlayerBonusFirstMultiplier);
	if (NewPlayerCount > 1)
		Multiplier += float(NewPlayerCount - 1) * GetConVarFloat(cvar_NewPlayerBonusExtraMultiplier);

	new Float:MaxMultiplier = GetConVarFloat(cvar_NewPlayerBonusMaxMultiplier);
	if (MaxMultiplier > 0.0 && Multiplier > MaxMultiplier)
		Multiplier = MaxMultiplier;

	if (Multiplier < 1.0)
		Multiplier = 1.0;

	return Multiplier;
}

stock bool:NewPlayerBonus_ShouldApplyToClient(client)
{
	if (!GetConVarBool(cvar_NewPlayerBonusEnable))
		return false;

	if (!Stats_IsSurvivorHuman(client) || NewPlayerBonus_IsNewPlayer(client))
		return false;

	return NewPlayerBonus_CountNewSurvivors() > 0;
}

stock NewPlayerBonus_ApplyScoreMultiplier(client, Score)
{
	if (Score <= 0 || !NewPlayerBonus_ShouldApplyToClient(client))
		return Score;

	new Float:Multiplier = NewPlayerBonus_GetMultiplier();
	if (Multiplier <= 1.0)
		return Score;

	return RoundToCeil(float(Score) * Multiplier);
}

stock NewPlayerBonus_AnnounceMultiplier(const String:Reason[], BaseScore)
{
	if (BaseScore <= 0 || !GetConVarBool(cvar_NewPlayerBonusEnable))
		return;

	new NewPlayerCount = NewPlayerBonus_CountNewSurvivors();
	new Float:Multiplier = NewPlayerBonus_GetMultiplier();
	if (NewPlayerCount <= 0 || Multiplier <= 1.0)
		return;

	StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03带新玩家%s倍率: \x05%i \x01名新人, 非新人幸存者获得 \x04%.1fx \x01分数倍率!", Reason, NewPlayerCount, Multiplier);
}

stock NewPlayerBonus_AnnounceRoundStart()
{
	if (g_bNewPlayerBonusRoundAnnounced || !GetConVarBool(cvar_NewPlayerBonusEnable) || !GetConVarInt(cvar_AnnounceMode))
		return;

	new NewPlayerCount = NewPlayerBonus_CountNewSurvivors();
	new Float:Multiplier = NewPlayerBonus_GetMultiplier();
	if (NewPlayerCount <= 0 || Multiplier <= 1.0)
		return;

	g_bNewPlayerBonusRoundAnnounced = true;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!NewPlayerBonus_IsNewPlayer(i))
			continue;

		StatsPrintToChat(i, "\x03你当前被判定为新人，本局非新人幸存者会获得 \x04%.1fx \x01带新分数倍率。", Multiplier);
	}

	StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03本局检测到 \x05%i \x01名新人，带新系数为 \x04%.1fx\x01；新人本身不吃倍率，非新人幸存者获得加成。", NewPlayerCount, Multiplier);
}
