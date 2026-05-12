#if defined _l4d_stats_no_buy_bonus_included
	#endinput
#endif
#define _l4d_stats_no_buy_bonus_included

new Handle:cvar_NoBuyBonusEnable = INVALID_HANDLE;
new Handle:cvar_NoBuyBonusScore5 = INVALID_HANDLE;
new Handle:cvar_NoBuyBonusScore6 = INVALID_HANDLE;
new Handle:cvar_NoBuyBonusScore7 = INVALID_HANDLE;
new Handle:cvar_NoBuyBonusScore8 = INVALID_HANDLE;
new Handle:cvar_NoBuyBonusScore9 = INVALID_HANDLE;
new Handle:cvar_NoBuyBonusScore10Plus = INVALID_HANDLE;
new Handle:cvar_NoBuyBonusHardcoreMultiplier = INVALID_HANDLE;

// 原 rpg.sp 的“不使用 B 数过关奖励”迁移到积分插件。
// 这里只读 RPG 暴露的 INDEX_USEBUY/INDEX_VALID，不再让 RPG 直接写 stats 数据库。
stock NoBuyBonus_CreateCvars()
{
	cvar_NoBuyBonusEnable = CreateConVar("l4d_stats_nobuy_bonus_enable", "1", "是否启用不使用B数过关额外积分。0=关闭, 1=开启", 0, true, 0.0, true, 1.0);
	cvar_NoBuyBonusScore5 = CreateConVar("l4d_stats_nobuy_bonus_5si", "200", "不使用B数过关时，5特模式额外积分。", 0, true, 0.0);
	cvar_NoBuyBonusScore6 = CreateConVar("l4d_stats_nobuy_bonus_6si", "500", "不使用B数过关时，6特模式额外积分。", 0, true, 0.0);
	cvar_NoBuyBonusScore7 = CreateConVar("l4d_stats_nobuy_bonus_7si", "800", "不使用B数过关时，7特模式额外积分。", 0, true, 0.0);
	cvar_NoBuyBonusScore8 = CreateConVar("l4d_stats_nobuy_bonus_8si", "1100", "不使用B数过关时，8特模式额外积分。", 0, true, 0.0);
	cvar_NoBuyBonusScore9 = CreateConVar("l4d_stats_nobuy_bonus_9si", "1500", "不使用B数过关时，9特模式额外积分。", 0, true, 0.0);
	cvar_NoBuyBonusScore10Plus = CreateConVar("l4d_stats_nobuy_bonus_10si", "2000", "不使用B数过关时，10特及以上模式额外积分。", 0, true, 0.0);
	cvar_NoBuyBonusHardcoreMultiplier = CreateConVar("l4d_stats_nobuy_bonus_hardcore_multiplier", "1.3", "HardCore 模式的不使用B数额外积分倍率。", 0, true, 0.0);
}

stock NoBuyBonus_GetBaseScore()
{
	new InfectedNumber = GetAnneInfectedNumber();

	if (InfectedNumber == 5)
		return GetConVarInt(cvar_NoBuyBonusScore5);
	if (InfectedNumber == 6)
		return GetConVarInt(cvar_NoBuyBonusScore6);
	if (InfectedNumber == 7)
		return GetConVarInt(cvar_NoBuyBonusScore7);
	if (InfectedNumber == 8)
		return GetConVarInt(cvar_NoBuyBonusScore8);
	if (InfectedNumber == 9)
		return GetConVarInt(cvar_NoBuyBonusScore9);
	if (InfectedNumber > 9)
		return GetConVarInt(cvar_NoBuyBonusScore10Plus);

	return 0;
}

stock NoBuyBonus_GetFinalScore()
{
	new Score = NoBuyBonus_GetBaseScore();
	if (Score <= 0)
		return 0;

	if (IsAnne() == 2)
		Score = RoundToFloor(float(Score) * GetConVarFloat(cvar_NoBuyBonusHardcoreMultiplier));

	if (IsAboveFourPeople())
		Score = RoundToFloor(float(Score) * (4.0 / getSurvivorNum()));

	return Score;
}

stock NoBuyBonus_TryAwardSurvivors()
{
	if (!GetConVarBool(cvar_NoBuyBonusEnable))
		return;

	if (!g_brpgAvailable || !IsAnne())
		return;

	if (L4D_RPG_GetGlobalValue(INDEX_USEBUY))
		return;

	if (!L4D_RPG_GetGlobalValue(INDEX_VALID))
		return;

	if (IsGaoJiRenJiEnabled())
	{
		StatsPrintToChatAll("\x01[\x04RANK\x01]\x04由于开启了高级人机，不能获得额外过关积分");
		return;
	}

	if (!IsThisRoundValid())
	{
		StatsPrintToChatAll("\x01[\x04RANK\x01]\x04由于关闭了tank连跳，不能获得额外过关积分");
		return;
	}

	new Score = NoBuyBonus_GetFinalScore();
	if (Score <= 0)
		return;

	new Awarded = 0;
	decl String:ScoreFormula[MAX_MESSAGE_WIDTH];
	Format(ScoreFormula, sizeof(ScoreFormula), "infected_limit=%i,hardcore_multiplier=%.2f,above_four_adjustment,no_buy=1", GetAnneInfectedNumber(), GetConVarFloat(cvar_NoBuyBonusHardcoreMultiplier));
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!Stats_IsSurvivorHuman(i))
			continue;

		ScoreLog_SetContext("nobuy_bonus", ScoreFormula);
		if (Stats_AwardClientScore(i, Score))
			Awarded++;
	}
	ScoreLog_ClearContext();

	if (Awarded > 0)
		StatsPrintToChatAll("\x01[\x04RANK\x01]\x04幸存者强势通过当前关卡，没花费任何B数，获得额外%d过关积分", Score);
}
