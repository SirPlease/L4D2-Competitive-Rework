#if defined _l4d_stats_rules_included
	#endinput
#endif
#define _l4d_stats_rules_included

// 计分规则、模式判断、生还者/感染者结算和状态重置辅助。

/*
-----------------------------------------------------------------------------
Private functions
-----------------------------------------------------------------------------
*/

HunterSmokerSave(Savior, Victim, BasePoints, AdvMult, ExpertMult, String:SaveFrom[], String:SQLField[])
{
	int human = CheckSurvivorsHumans();
	if (StatsDisabled() || human < 3)
		return;

	if (!Stats_IsSurvivorHuman(Savior) || !Stats_IsSurvivorHuman(Victim) || Savior == Victim)
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);

	decl String:SaviorName[MAX_LINE_WIDTH];
	GetClientName(Savior, SaviorName, sizeof(SaviorName));
	decl String:SaviorID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Savior, SaviorID, sizeof(SaviorID));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));
	decl String:VictimID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Victim, VictimID, sizeof(VictimID));

	if (StrEqual(SaviorID, VictimID))
		return;

	new Score = ModifyScoreDifficulty(BasePoints, AdvMult, ExpertMult, TEAM_SURVIVORS);
	Score = NewPlayerBonus_ApplyScoreMultiplier(Savior, Score);
	decl String:UpdatePoints[32];

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
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, %s = %s + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, SQLField, SQLField, SaviorID);
	SendSQLUpdate(query);

	if (Score <= 0)
		return;

	if (Mode)
		StatsPrintToChat(Savior, "你因把 \x05%s\x01 从 \x04%s\x01 里救了出来获得 \x04%i \x01分!", VictimName, SaveFrom, Score);

	UpdateMapStat("points", Score);
	decl String:ScoreFormula[MAX_MESSAGE_WIDTH];
	Format(ScoreFormula, sizeof(ScoreFormula), "base=%i,difficulty=%i/%i,save_from=%s,newbie_multiplier", BasePoints, AdvMult, ExpertMult, SaveFrom);
	ScoreLog_SetContext("save_teammate", ScoreFormula);
	AddScore(Savior, Score);
}

bool:IsClientBot(client)
{
	if (client == 0 || !IsClientConnected(client) || IsFakeClient(client))
	{
		return true;
	}

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	if (StrEqual(SteamID, "BOT", false))
	{
		return true;
	}

	return false;
}

ModifyScoreRealism(BaseScore, ClientTeam, bool:ToCeil=true)
{
	
	if (EngineVersion1 != Engine_Left4Dead)
	{
		decl Handle:Multiplier;
		CurrentGamemodeID=GetCurrentGamemodeID();
		if (CurrentGamemodeID == GAMEMODE_REALISM)
			Multiplier = cvar_RealismMultiplier;
		else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		{
			if (ClientTeam == TEAM_SURVIVORS)
				Multiplier = cvar_RealismVersusSurMultiplier;
			else if(ClientTeam == TEAM_INFECTED)
				Multiplier = cvar_RealismVersusInfMultiplier;
			else
				return BaseScore;
		}
		else
			return BaseScore;

		if (ToCeil)
			BaseScore = RoundToCeil(GetConVarFloat(Multiplier) * BaseScore);
		else
			BaseScore = RoundToFloor(GetConVarFloat(Multiplier) * BaseScore);
	}

	return BaseScore;
}

ModifyScoreDifficultyFloatNR(BaseScore, Float:AdvMult, Float:ExpMult, ClientTeam, bool:ToCeil=true)
{
	return ModifyScoreDifficultyFloat(BaseScore, AdvMult, ExpMult, ClientTeam, ToCeil, false);
}

ModifyScoreDifficultyFloat(BaseScore, Float:AdvMult, Float:ExpMult, ClientTeam, bool:ToCeil=true, bool:Reduction = true)
{
	if (BaseScore <= 0)
	{
		return 0;
	}

	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	new Float:ModifiedScore;

	if (StrEqual(Difficulty, "Hard", false)) ModifiedScore = BaseScore * AdvMult;
	else if (StrEqual(Difficulty, "Impossible", false)) ModifiedScore = BaseScore * ExpMult;
	else return ModifyScoreRealism(BaseScore, ClientTeam);

	new Score = 0;
	if (ToCeil)
	{
		Score = RoundToCeil(ModifiedScore);
	}
	else
	{
		Score = RoundToFloor(ModifiedScore);
	}

	if (ClientTeam == TEAM_SURVIVORS && Reduction)
	{
		Score = GetMedkitPointReductionScore(Score);
	}

	return ModifyScoreRealism(Score, ClientTeam, ToCeil);
}

// Score modifier without point reduction. Usable for minus points.

ModifyScoreDifficultyNR(BaseScore, AdvMult, ExpMult, ClientTeam)
{
	return ModifyScoreDifficulty(BaseScore, AdvMult, ExpMult, ClientTeam, false);
}

ModifyScoreDifficulty(BaseScore, AdvMult, ExpMult, ClientTeam, bool:Reduction = true)
{
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "hard", false)) BaseScore = BaseScore * AdvMult;
	if (StrEqual(Difficulty, "impossible", false)) BaseScore = BaseScore * ExpMult;

	if (ClientTeam == TEAM_SURVIVORS && Reduction)
	{
		BaseScore = GetMedkitPointReductionScore(BaseScore);
	}

	return ModifyScoreRealism(BaseScore, ClientTeam);
}

IsDifficultyEasy()
{
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "easy", false))
	{
		return true;
	}

	return false;
}

InvalidGameMode()
{
	// Currently will always return False in Survival and Versus gamemodes.
	// This will be removed in a future version when stats for those versions work.

	if (CurrentGamemodeID == GAMEMODE_COOP && GetConVarBool(cvar_EnableCoop))
	{
		return false;
	}
	else if (CurrentGamemodeID == GAMEMODE_SURVIVAL && GetConVarBool(cvar_EnableSv))
	{
		return false;
	}
	else if (CurrentGamemodeID == GAMEMODE_VERSUS && GetConVarBool(cvar_EnableVersus))
	{
		return false;
	}
	else if (CurrentGamemodeID == GAMEMODE_SCAVENGE && GetConVarBool(cvar_EnableScavenge))
	{
		return false;
	}
	else if (CurrentGamemodeID == GAMEMODE_REALISM && GetConVarBool(cvar_EnableRealism))
	{
		return false;
	}
	else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS && GetConVarBool(cvar_EnableRealismVersus))
	{
		return false;
	}
	else if (CurrentGamemodeID == GAMEMODE_OTHERMUTATIONS && GetConVarBool(cvar_EnableMutations))
	{
		return false;
	}

	return true;
}

stock int CheckSurvivorsHumans()
{
	new humans = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == 2)
		{
			humans++;
		}
	}
	return humans;
}

stock Stats_GetMinPlayingHumans()
{
	new MinHumans = GetConVarInt(cvar_HumansNeeded);

	if (!SinglePlayerMode() && MinHumans < 2)
		MinHumans = 2;

	return MinHumans;
}

bool:CheckHumans()
{
	new MinHumans = Stats_GetMinPlayingHumans();
	new Humans = Stats_CountPlayingHumans();

	if (Humans < MinHumans)
	{
		return true;
	}
	else
	{
		return false;
	}
}

ResetInfVars()
{
	new i;

	// 让上一回合/上一张图遗留的保护队友延迟结算全部失效，避免过关后旧计时器继续刷分。
	ProtectedFriendlyRoundToken++;
	if (ProtectedFriendlyRoundToken > 1000000000)
	{
		ProtectedFriendlyRoundToken = 1;
	}

	// Reset all Infected variables
	for (i = 0; i < MAXPLAYERS + 1; i++)
	{
		BoomerHitCounter[i] = 0;
		BoomerVomitUpdated[i] = false;
		InfectedDamageCounter[i] = 0;
		SmokerDamageCounter[i] = 0;
		SpitterDamageCounter[i] = 0;
		JockeyDamageCounter[i] = 0;
		ChargerDamageCounter[i] = 0;
		ChargerImpactCounter[i] = 0;
		TankPointsCounter[i] = 0;
		TankDamageCounter[i] = 0;
		ClientInfectedType[i] = 0;
		TankSurvivorKillCounter[i] = 0;
		TankDamageTotalCounter[i] = 0;
		ChargerCarryVictim[i] = 0;
		ChargerPlummelVictim[i] = 0;
		JockeyVictim[i] = 0;
		JockeyRideStartTime[i] = 0;

		PlayerBlinded[i][0] = 0;
		PlayerBlinded[i][1] = 0;
		PlayerParalyzed[i][0] = 0;
		PlayerParalyzed[i][1] = 0;
		PlayerLunged[i][0] = 0;
		PlayerLunged[i][1] = 0;
		PlayerPlummeled[i][0] = 0;
		PlayerPlummeled[i][1] = 0;
		PlayerCarried[i][0] = 0;
		PlayerCarried[i][1] = 0;
		PlayerJockied[i][0] = 0;
		PlayerJockied[i][1] = 0;

		TimerBoomerPerfectCheck[i] = INVALID_HANDLE;
		TimerInfectedDamageCheck[i] = INVALID_HANDLE;

		if (TimerProtectedFriendly[i] != INVALID_HANDLE)
		{
			CloseHandle(TimerProtectedFriendly[i]);
		}

		TimerProtectedFriendly[i] = INVALID_HANDLE;
		ProtectedFriendlyCounter[i] = 0;

		if (ChargerImpactCounterTimer[i] != INVALID_HANDLE)
		{
			CloseHandle(ChargerImpactCounterTimer[i]);
		}

		ChargerImpactCounterTimer[i] = INVALID_HANDLE;
	}
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client){
	Stats_RecordStartGrantedSupportItems();
	Stats_ScheduleInitialSupportItemScans(12.0);

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2)
			ClientEnabled[i] = true;
	}
	NewPlayerBonus_AnnounceRoundStart();
	//开局提示该难度完成最快速度
	if(!IsNormalMode())GetThisModeBestTime();
	return Plugin_Continue;
}

ResetVars()
{
	ClearTrie(FriendlyFireDamageTrie);
	ClearTrie(PlayerRankVoteTrie);

	PlayerVomited = false;
	PlayerVomitedIncap = false;
	PanicEvent = false;
	PanicEventIncap = false;
	CampaignOver = false;
	Isstart = false;
	SupportStartGrantRecorded = false;
	SupportStartGrantUntil = 0.0;
	WitchExists = false;
	WitchDisturb = false;
	MedkitsUsedCounter = 0;

	// Reset kill/point score timer amount
	CreateTimer(1.0, InitPlayers);
	InitialSupportScanUntil = 0.0;
	Stats_ScheduleInitialSupportItemScans(10.0);

	TankCount = 0;

	new i, j, maxplayers = MaxClients;
	for (i = 1; i <= maxplayers; i++)
	{
		AnnounceCounter[i] = 0;
		CurrentPoints[i] = 0;
		ClientRankMute[i] = false;
		ClientEnabled[i] = false;
		HealingFirstAid[i] = 0;
		SupportMedicineAwardCount[i] = 0;
		SupportMedkitAwardCount[i] = 0;
		SupportReviveAwardCount[i] = 0;
		SupportDefibAwardCount[i] = 0;
	}

	for (i = 0; i < MAXPLAYERS + 1; i++)
	{
		if (TimerRankChangeCheck[i] != INVALID_HANDLE)
			CloseHandle(TimerRankChangeCheck[i]);

		TimerRankChangeCheck[i] = INVALID_HANDLE;
		QuarterRankChangeLastRank[i] = 0;
		QuarterRankChangeFirstCheck[i] = true;
		SupportReloadTime[i] = 0.0;
		SupportReloadType[i] = 0;
		SupportGiveCommandUntil[i] = 0.0;
		SupportReloadOrigin[i][0] = 0.0;
		SupportReloadOrigin[i][1] = 0.0;
		SupportReloadOrigin[i][2] = 0.0;

		for (j = 0; j < MAXPLAYERS + 1; j++)
		{
			FriendlyFireCooldown[i][j] = false;
			FriendlyFireTimer[i][j] = INVALID_HANDLE;
		}

		if (MeleeKillTimer[i] != INVALID_HANDLE)
			CloseHandle(MeleeKillTimer[i]);
		MeleeKillTimer[i] = INVALID_HANDLE;
		MeleeKillCounter[i] = 0;

		PostAdminCheckRetryCounter[i] = 0;
	}

	for (i = 0; i < sizeof(Pills); i++)
	{
		Pills[i] = 0;
		Adrenaline[i] = 0;
		PillsFirstHolder[i] = 0;
		AdrenalineFirstHolder[i] = 0;
		FirstAidFirstHolder[i] = 0;
		SupportItemWorldSpawned[i] = false;
	}

	Stats_RecordWorldSupportItems();
	ResetInfVars();
}

public ResetRankChangeCheck()
{
	new maxplayers = MaxClients;

	for (new i = 1; i <= maxplayers; i++)
		StartRankChangeCheck(i);
}

public StartRankChangeCheck(Client)
{
	if (TimerRankChangeCheck[Client] != INVALID_HANDLE)
		CloseHandle(TimerRankChangeCheck[Client]);

	TimerRankChangeCheck[Client] = INVALID_HANDLE;

	if (Client == 0 || IsClientBot(Client))
		return;

	RankChangeFirstCheck[Client] = true;
	QuarterRankChangeFirstCheck[Client] = true;
	DoShowRankChange(Client);
	TimerRankChangeCheck[Client] = CreateTimer(GetConVarFloat(cvar_AnnounceRankChangeIVal), timer_ShowRankChange, Client, TIMER_REPEAT);
}

StatsDisabled(bool:MapCheck = false)
{
	if (!GetConVarBool(cvar_Enable))
		return true;

	if (InvalidGameMode())
		return true;

	if (!MapCheck && IsDifficultyEasy())
		return true;

	if (!MapCheck && CheckHumans())
		return true;

	if (!MapCheck && GetConVarBool(cvar_Cheats))
		return true;

	if (db == INVALID_HANDLE)
		return true;

	return false;
}

// Check that player the score is in the map score limits and return the value that is addable.

public AddScore(Client, Score)
{
	// ToDo: use cvar_MaxPoints to check if the score is within the map limits
	CurrentPoints[Client] += Score;
	ScoreLog_Record(Client, Score);
	QuarterRank_RecordScore(Client, Score);
	ModeStats_RecordScore(Client, Score);

	//if (GetConVarBool(cvar_AnnounceRankChange))
	//{
	//}

	return Score;
}

public UpdateSmokerDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	decl String:iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_smoker_damage = infected_smoker_damage + %i WHERE steamid = '%s'", DbPrefix, Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_smoker_damage", Damage);
}

public UpdateSpitterDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	decl String:iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_spitter_damage = infected_spitter_damage + %i WHERE steamid = '%s'", DbPrefix, Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_spitter_damage", Damage);
}

public UpdateJockeyDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	decl String:iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_jockey_damage = infected_jockey_damage + %i WHERE steamid = '%s'", DbPrefix, Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_jockey_damage", Damage);
}

UpdateJockeyRideLength(Client, Float:RideLength=-1.0)
{
	if (Client <= 0 || RideLength == 0 || IsClientBot(Client) || (RideLength < 0 && JockeyRideStartTime[Client] <= 0))
		return;

	if (RideLength < 0)
		RideLength = float(GetTime() - JockeyRideStartTime[Client]);

	decl String:iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_jockey_ridetime = infected_jockey_ridetime + %f WHERE steamid = '%s'", DbPrefix, RideLength, iID);
	SendSQLUpdate(query);

	UpdateMapStatFloat("infected_jockey_ridetime", RideLength);
}

public UpdateChargerDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	decl String:iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_charger_damage = infected_charger_damage + %i WHERE steamid = '%s'", DbPrefix, Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_charger_damage", Damage);
}

public CheckSurvivorsWin()
{
	//StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03有调用CheckSurvivorsWin方法!");
	if (CampaignOver)
		return;
	if (!Isstart)
		return;

	CampaignOver = true;
	if (g_brpgAvailable && !L4D_RPG_GetGlobalValue(INDEX_VALID))
	{
		StopMapTiming();
		return;
	}
	if (!IsNormalMode() && !IsThisRoundValid())
	{
		StopMapTiming();
		return;
	}

	//StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03CampaignOver值没问题!");
	StopMapTiming();
	CurrentGamemodeID = GetCurrentGamemodeID();
	// Return if gamemode is Scavenge or Survival
	if (CurrentGamemodeID == GAMEMODE_SCAVENGE ||
			CurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;
	//StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03Gameid没问题");
	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Witch), 5, 10, TEAM_SURVIVORS);
	new Mode = GetConVarInt(cvar_AnnounceMode);
	decl String:iID[MAX_LINE_WIDTH];
	decl String:query[1024];
	new maxplayers = MaxClients;
	decl String:UpdatePoints[32], String:UpdatePointsPenalty[32];
	new ClientTeam, bool:NegativeScore = GetConVarBool(cvar_EnableNegativeScore);

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			Format(UpdatePointsPenalty, sizeof(UpdatePointsPenalty), "points_infected");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
			Format(UpdatePointsPenalty, sizeof(UpdatePointsPenalty), "points_realism_infected");
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
	//StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03Witch分数为%d",Score);
	if (Score > 0 && WitchExists && !WitchDisturb)
	{
		for (new i = 1; i <= maxplayers; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, iID, sizeof(iID));
				Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, iID);
				SendSQLUpdate(query);
				UpdateMapStat("points", Score);
				ScoreLog_SetContext("witch_undisturbed", "base=l4d_stats_witch,difficulty");
				AddScore(i, Score);
			}
		}

		if (Mode)
			StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03所有幸存者因 \x05没有惊扰Witch \x01获得\x04%i \x01额外过关分!", Score);
	}
	//StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03过关分数为%d",Score);
	Score = 0;
	new Deaths = 0;
	new BaseScore = ModifyScoreDifficulty(GetConVarInt(cvar_SafeHouse), 2, 2, TEAM_SURVIVORS);

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i)  && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			if (IsPlayerAlive(i))
				Score = Score + BaseScore;
			else
				Deaths++;
		}
	}
	if(Score>400)
		Score=400;
	
	if (SinglePlayerMode())
	{
		int addScore = 0;
		if( GetAnneInfectedNumber() > 3 && ((g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_VALID)) && IsThisRoundValid())){
			addScore = (GetAnneInfectedNumber() - 3) * 100;
		}
		char buffer[256];
		Format(buffer, sizeof(buffer), "\x03单人模式 \x01没有\x04特感击杀奖励，所以过关奖励分数\x053倍");
		if(addScore > 0){
			Format(buffer, sizeof(buffer), "%s, 获得难度分数补贴 %d 分", buffer, addScore);
		}
		StatsPrintToChatTeam(TEAM_SURVIVORS, buffer);
		Score *=3;
	}

	if((AnneMultiPlayerMode() || SinglePlayerMode()) && ((g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_VALID)) && IsThisRoundValid())){
		int inf = GetAnneInfectedNumber();
		if(inf>4)
			Score=RoundToFloor(Score+Score*(inf-4)*0.2);
		else if(inf>6)
			Score=RoundToFloor(Score+Score*(inf-4)*0.3);
		else if(inf>8)
			Score=RoundToFloor(Score+Score*(inf-4)*0.4);
	}

	if(IsAboveFourPeople())
	{
		Score = RoundToFloor(Score * (4.0 / getSurvivorNum()));
	}

	if(IsGaoJiRenJiEnabled())
	{
		Score = RoundToFloor(Score * 0.5);
	}

	// HardCore 奖励增加50%
	if(IsAnne() == 2)
	{
		Score = RoundToFloor(1.5 * Score);
	}

	if(IsFunGame() > 1)
	{
		if(Score > 200){
			Score = 200;
		}
		//return Plugin_Continue;
	}

	new String:All4Safe[64] = "";
	if (Deaths == 0)
		Format(All4Safe, sizeof(All4Safe), ", award_allinsafehouse = award_allinsafehouse + 1");

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				InterstitialPlayerUpdate(i);
				new ClientScore = NewPlayerBonus_ApplyScoreMultiplier(i, Score);

				GetClientRankAuthString(i, iID, sizeof(iID));
				Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i%s WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, ClientScore, All4Safe, iID);
				SendSQLUpdate(query);
				UpdateMapStat("points", ClientScore);
				ScoreLog_SetContext("safehouse", "base=l4d_stats_safehouse*alive_survivors,difficulty,anne,player_count,hardcore,fun,newbie_multiplier");
				AddScore(i, ClientScore);
			}
			else if (ClientTeam == TEAM_INFECTED && NegativeScore)
			{
				DoInfectedFinalChecks(i);

				GetClientRankAuthString(i, iID, sizeof(iID));
				Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, iID);
				SendSQLUpdate(query);
				ScoreLog_SetContext("safehouse_infected_penalty", "base=safehouse_score,negative_score");
				AddScore(i, Score * (-1));
			}
			if (TimerRankChangeCheck[i] != INVALID_HANDLE)
				TriggerTimer(TimerRankChangeCheck[i], true);
		}
	}

	if (Mode && Score > 0)
	{
		StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03所有幸存者因 \x05%i 死亡到达安全门 \x01获得 \x04%i \x01分!", Deaths, Score);
		NewPlayerBonus_AnnounceMultiplier("安全屋", Score);

		if (NegativeScore)
			StatsPrintToChatTeam(TEAM_INFECTED, "\x03所有感染者因 \x05让幸存者进了安全门 \x01失去了 \x04%i \x01分!", Score);
	}

	NoBuyBonus_TryAwardSurvivors();

	PlayerVomited = false;
	PanicEvent = false;
}

stock int GetAnneInfectedNumber(){
	return GetConVarInt(FindConVar("l4d_infected_limit"));
}

stock int GetAnneSISpawnTime()
{
	return GetConVarInt(FindConVar("versus_special_respawn_interval"));
}

stock char[] GetAnneVersion()
{
	char version[255];
	GetConVarString(FindConVar("AnnePluginVersion"), version, sizeof(version));
	return version;
}

IsSingleTeamGamemode()
{
	if (CurrentGamemodeID == GAMEMODE_SCAVENGE ||
			CurrentGamemodeID == GAMEMODE_VERSUS ||
			CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		return false;

	return true;
}

CheckSurvivorsAllDown()
{
	if (CampaignOver ||
				CurrentGamemodeID == GAMEMODE_COOP ||
				CurrentGamemodeID == GAMEMODE_REALISM)
		return;

	new maxplayers = MaxClients;
	new ClientTeam;
	new bool:ClientIsAlive, bool:ClientIsBot, bool:ClientIsIncap;
	new KilledSurvivor[MaxClients];
	new AliveInfected[MaxClients];
	new Infected[MaxClients];
	new InfectedCounter = 0, AliveInfectedCounter = 0;
	new i;

	// Add to killing score on all incapacitated surviviors
	new IncapCounter = 0;

	for (i = 1; i <= maxplayers; i++)
	{
		if (!IsClientInGame(i))
			continue;

		ClientIsBot = IsClientBot(i);
		ClientIsIncap = IsClientIncapacitated(i);
		ClientIsAlive = IsClientAlive(i);

		if (ClientIsBot || IsClientInGame(i))
			ClientTeam = GetClientTeam(i);
		else 
			continue;

		// Client is not dead and not incapped -> game continues!
		if (ClientTeam == TEAM_SURVIVORS && ClientIsAlive && !ClientIsIncap)
			return;

		if (ClientTeam == TEAM_INFECTED && !ClientIsBot)
		{
			if (ClientIsAlive)
				AliveInfected[AliveInfectedCounter++] = i;

			Infected[InfectedCounter++] = i;
		}
		else if (ClientTeam == TEAM_SURVIVORS && ClientIsAlive)
			KilledSurvivor[IncapCounter++] = i;
	}

	// If we ever get this far it means the surviviors are all down or dead!

	CampaignOver = true;

	// Stop the timer and return if gamemode is Survival
	if (CurrentGamemodeID == GAMEMODE_SURVIVAL)
	{
		SurvivalStarted = false;
		StopMapTiming();
		return;
	}

	// If we ever get this far it means the current gamemode is NOT Survival

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == TEAM_SURVIVORS)
				InterstitialPlayerUpdate(i);

			if (TimerRankChangeCheck[i] != INVALID_HANDLE)
				TriggerTimer(TimerRankChangeCheck[i], true);
		}
	}

	decl String:query[1024];
	decl String:ClientID[MAX_LINE_WIDTH];
	new Mode = GetConVarInt(cvar_AnnounceMode);

	for (i = 0; i < AliveInfectedCounter; i++)
		DoInfectedFinalChecks(AliveInfected[i]);

	new Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_VictoryInfected), 0.75, 0.5, TEAM_INFECTED) * IncapCounter;

	if (Score > 0)
		for (i = 0; i < InfectedCounter; i++)
		{
			GetClientRankAuthString(Infected[i], ClientID, sizeof(ClientID));

			if (CurrentGamemodeID == GAMEMODE_VERSUS)
				Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_infected_win = award_infected_win + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);
			else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
				Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_infected_win = award_infected_win + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);
			else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
				Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_scavenge_infected_win = award_scavenge_infected_win + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);
			else
				Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_scavenge_infected_win = award_scavenge_infected_win + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);

			SendSQLUpdate(query);
		}

	UpdateMapStat("infected_win", 1);
	if (IncapCounter > 0)
		UpdateMapStat("survivor_kills", IncapCounter);
	if (Score > 0)
		UpdateMapStat("points_infected", Score);

	if (Score > 0 && Mode)
		StatsPrintToChatTeam(TEAM_INFECTED, "\x03所有感染者 \x05因杀死了所有幸存者 \x01获得 \x04%i \x01分!", Score);

	if (!GetConVarBool(cvar_EnableNegativeScore))
		return;
	if(IsFunGame())
	{
		return ;
	}
	if (CurrentGamemodeID == GAMEMODE_VERSUS)
	{
		Score = ModifyScoreDifficultyFloatNR(GetConVarInt(cvar_Restart), 0.75, 0.5, TEAM_SURVIVORS);
	}
	else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
	{
		Score = ModifyScoreDifficultyFloatNR(GetConVarInt(cvar_Restart), 0.6, 0.3, TEAM_SURVIVORS);
	}
	else
	{
		Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Restart), 2, 3, TEAM_SURVIVORS);
		Score = 400 - Score;
	}

	for (i = 0; i < IncapCounter; i++)
	{
		GetClientRankAuthString(KilledSurvivor[i], ClientID, sizeof(ClientID));

		if (CurrentGamemodeID == GAMEMODE_VERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_survivors = points_survivors - %i WHERE steamid = '%s'", DbPrefix, Score, ClientID);
		else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_realism_survivors = points_realism_survivors - %i WHERE steamid = '%s'", DbPrefix, Score, ClientID);
		else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
			Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_survivors = points_scavenge_survivors - %i WHERE steamid = '%s'", DbPrefix, Score, ClientID);
		else
			Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations - %i WHERE steamid = '%s'", DbPrefix, Score, ClientID);

		SendSQLUpdate(query);
	}

	if (Mode && Score > 0)
		StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03所有幸存者 \x01 \x03失去了 \x04%i \x01分 by \x03全部坐牢\x01!", Score);
}

bool:IsClientIncapacitated(client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0 ||
				 GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0;
}

bool:IsClientAlive(client)
{
	if (!IsClientConnected(client))
		return false;

	if (IsFakeClient(client))
		return GetClientHealth(client) > 0 && GetEntProp(client, Prop_Send, "m_lifeState") == 0;
	else if (!IsClientInGame(client))
			return false;

	return IsPlayerAlive(client);
}

bool:IsGamemode(const String:Gamemode[])
{
	if (StrContains(CurrentGamemode, Gamemode, false) != -1)
	{
		return true;
	}

	return false;
}

GetGamemodeID(const String:Gamemode[])
{
	if (StrEqual(Gamemode, "coop", false))
	{
		return GAMEMODE_COOP;
	}
	else if (StrEqual(Gamemode, "survival", false))
	{
		return GAMEMODE_SURVIVAL;
	}
	else if (StrEqual(Gamemode, "versus", false))
	{
		return GAMEMODE_VERSUS;
	}
	else if (StrEqual(Gamemode, "teamversus", false) && GetConVarInt(cvar_EnableTeamVersus))
	{
		return GAMEMODE_VERSUS;
	}
	else if (StrEqual(Gamemode, "scavenge", false))
	{
		return GAMEMODE_SCAVENGE;
	}
	else if (StrEqual(Gamemode, "teamscavenge", false) && GetConVarInt(cvar_EnableTeamScavenge))
	{
		return GAMEMODE_SCAVENGE;
	}
	else if (StrEqual(Gamemode, "realism", false))
	{
		return GAMEMODE_REALISM;
	}
	else if (StrEqual(Gamemode, "mutation4", false) && IsMutationCoop())
	{
		return GAMEMODE_COOP;
	}
	else if (StrEqual(Gamemode, "mutation12", false))
	{
		return GAMEMODE_REALISMVERSUS;
	}
	else if (StrEqual(Gamemode, "teamrealismversus", false) && GetConVarInt(cvar_EnableTeamRealismVersus))
	{
		return GAMEMODE_REALISMVERSUS;
	}
	else if (StrContains(Gamemode, "mutation", false) == 0 ||
					 StrContains(Gamemode, "community", false) == 0)
	{
		return GAMEMODE_OTHERMUTATIONS;
	}

	return GAMEMODE_UNKNOWN;
}

GetCurrentGamemodeID()
{
	new String:CurrentMode[16];
	GetConVarString(cvar_Gamemode, CurrentMode, sizeof(CurrentMode));

	return GetGamemodeID(CurrentMode);
}

IsGamemodeVersus()
{
	return IsGamemode("versus") || (IsGamemode("teamversus") && GetConVarBool(cvar_EnableTeamVersus));
}
/*
IsGamemodeRealism()
{
	return IsGamemode("realism");
}

IsGamemodeRealismVersus()
{
	return IsGamemode("mutation12");
}

IsGamemodeScavenge()
{
	return IsGamemode("scavege") || (IsGamemode("teamscavege") && GetConVarBool(cvar_EnableTeamScavenge));
}

IsGamemodeCoop()
{
	return IsGamemode("coop");
}
*/
GetSurvivorKillScore()
{
	return ModifyScoreDifficultyFloat(GetConVarInt(cvar_SurvivorDeath), 0.75, 0.5, TEAM_INFECTED);
}

DoInfectedFinalChecks(Client, ClientInfType = -1)
{
	if (Client == 0)
		return;

	if (ClientInfType < 0)
		ClientInfType = ClientInfectedType[Client];

	if (ClientInfType == INF_ID_SMOKER)
	{
		new Damage = SmokerDamageCounter[Client];
		SmokerDamageCounter[Client] = 0;
		UpdateSmokerDamage(Client, Damage);
	}
	else if (EngineVersion1 != Engine_Left4Dead && ClientInfType == INF_ID_SPITTER_L4D2)
	{
		new Damage = SpitterDamageCounter[Client];
		SpitterDamageCounter[Client] = 0;
		UpdateSpitterDamage(Client, Damage);
	}
	else if (EngineVersion1 != Engine_Left4Dead && ClientInfType == INF_ID_JOCKEY_L4D2)
	{
		new Damage = JockeyDamageCounter[Client];
		JockeyDamageCounter[Client] = 0;
		UpdateJockeyDamage(Client, Damage);
		UpdateJockeyRideLength(Client);
	}
	else if (EngineVersion1 != Engine_Left4Dead && ClientInfType == INF_ID_CHARGER_L4D2)
	{
		new Damage = ChargerDamageCounter[Client];
		ChargerDamageCounter[Client] = 0;
		UpdateChargerDamage(Client, Damage);
	}
}

GetInfType(Client)
{
	// Client > 0 && ClientTeam == TEAM_INFECTED checks are done by the caller

	new InfType = GetEntProp(Client, Prop_Send, "m_zombieClass");

	// Make the conversion so that everything gets stored in the correct fields
	if (EngineVersion1 == Engine_Left4Dead)
	{
		if (InfType == INF_ID_WITCH_L4D1)
			return INF_ID_WITCH_L4D2;

		if (InfType == INF_ID_TANK_L4D1)
			return INF_ID_TANK_L4D2;
	}

	return InfType;
}

SetClientInfectedType(Client)
{
	// Bot check is done by the caller

	if (Client <= 0)
		return;

	new ClientTeam = GetClientTeam(Client);

	if (ClientTeam == TEAM_INFECTED)
	{
		ClientInfectedType[Client] = GetInfType(Client);

		if (ClientInfectedType[Client] != INF_ID_SMOKER
				&& ClientInfectedType[Client] != INF_ID_BOOMER
				&& ClientInfectedType[Client] != INF_ID_HUNTER
				&& ClientInfectedType[Client] != INF_ID_SPITTER_L4D2
				&& ClientInfectedType[Client] != INF_ID_JOCKEY_L4D2
				&& ClientInfectedType[Client] != INF_ID_CHARGER_L4D2
				&& ClientInfectedType[Client] != INF_ID_TANK_L4D2)
			return;

		decl String:ClientID[MAX_LINE_WIDTH];
		GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

		decl String:query[1024];
		Format(query, sizeof(query), "UPDATE %splayers SET infected_spawn_%i = infected_spawn_%i + 1 WHERE steamid = '%s'", DbPrefix, ClientInfectedType[Client], ClientInfectedType[Client], ClientID);
		SendSQLUpdate(query);

		new String:Spawn[32];
		Format(Spawn, sizeof(Spawn), "infected_spawn_%i", ClientInfectedType[Client]);
		UpdateMapStat(Spawn, 1);
	}
	else
		ClientInfectedType[Client] = 0;
}

TankDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0)
		return 0;

	// Update only the Tank inflicted damage related statistics
	UpdateTankDamage(Client, Damage);

	// If value is negative then client has already received the Bulldozer Award
	if (TankDamageTotalCounter[Client] >= 0)
	{
		TankDamageTotalCounter[Client] += Damage;
		new TankDamageTotal = GetConVarInt(cvar_TankDamageTotal);

		if (TankDamageTotalCounter[Client] >= TankDamageTotal)
		{
			TankDamageTotalCounter[Client] = -1; // Just one award per Tank
			new Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_TankDamageTotalSuccess), 0.75, 0.5, TEAM_INFECTED);

			if (Score > 0)
			{
				decl String:ClientID[MAX_LINE_WIDTH];
				GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

				decl String:query[1024];

				if (CurrentGamemodeID == GAMEMODE_VERSUS)
					Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_bulldozer = award_bulldozer + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);
				else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
					Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_bulldozer = award_bulldozer + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);
				else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
					Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_bulldozer = award_bulldozer + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);
				else
					Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_bulldozer = award_bulldozer + 1 WHERE steamid = '%s'", DbPrefix, Score, ClientID);

				SendSQLUpdate(query);

				UpdateMapStat("points_infected", Score);

				new Mode = GetConVarInt(cvar_AnnounceMode);

				if (Mode == 1 || Mode == 2)
					StatsPrintToChat(Client, "你给幸存者造成了价值 \x04%i\x01 分的伤害获得 \x04%i \x01分!", TankDamageTotal, Score);
				else if (Mode == 3)
				{
					decl String:Name[MAX_LINE_WIDTH];
					GetClientName(Client, Name, sizeof(Name));
					StatsPrintToChatAll("\x05%s \x01给幸存者造成了价值 \x04%i\x01 分的伤害获得 \x04%i \x01分!", Name, TankDamageTotal, Score);
				}

				if (EnableSounds_Tank_Bulldozer && GetConVarBool(cvar_SoundsEnabled))
					EmitSoundToAll(StatsSound_Tank_Bulldozer);
			}
		}
	}

	new DamageLimit = GetConVarInt(cvar_TankDamageCap);

	if (TankDamageCounter[Client] >= DamageLimit)
		return 0;

	TankDamageCounter[Client] += Damage;

	if (TankDamageCounter[Client] > DamageLimit)
		Damage -= TankDamageCounter[Client] - DamageLimit;

	return Damage;
}

UpdateFriendlyFire(Attacker, Victim)
{
	decl String:AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));
	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	new Score = 0;
	if (GetConVarBool(cvar_EnableNegativeScore))
	{
		if (!IsClientBot(Victim))
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FFire), 2, 4, TEAM_SURVIVORS);
		else
		{
			new Float:BotScoreMultiplier = GetConVarFloat(cvar_BotScoreMultiplier);

			if (BotScoreMultiplier > 0.0)
				Score = RoundToNearest(ModifyScoreDifficultyNR(GetConVarInt(cvar_FFire), 2, 4, TEAM_SURVIVORS) * BotScoreMultiplier);
		}
	}

	decl String:UpdatePoints[32];

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
	if(IsNormalMode()){
		Score = RoundToFloor(Score / 5.0);
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i, award_friendlyfire = award_friendlyfire + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, AttackerID);
	SendSQLUpdate(query);
	QuarterRank_RecordField(Attacker, "award_friendlyfire", 1);
	QuarterRank_RecordScore(Attacker, Score * (-1));

	new Mode = 0;
	if (Score > 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode == 1 || Mode == 2)
		StatsPrintToChat(Attacker, "你已经 \x03失去了 \x04%i \x01分 by \x03黑枪了 \x05%s\x01!", Score, VictimName);
	else if (Mode == 3)
		StatsPrintToChatAll("\x05%s \x01已经 \x03失去了 \x04%i \x01分 by \x03黑枪了 \x05%s\x01!", AttackerName, Score, VictimName);
}

UpdateHunterDamage(Client, Damage)
{
	if (Damage <= 0)
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_hunter_pounce_dmg = infected_hunter_pounce_dmg + %i, infected_hunter_pounce_counter = infected_hunter_pounce_counter + 1 WHERE steamid = '%s'", DbPrefix, Damage, ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_hunter_pounce_counter", 1);
	UpdateMapStat("infected_hunter_pounce_damage", Damage);
}

UpdateTankDamage(Client, Damage)
{
	if (Damage <= 0)
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_tank_damage = infected_tank_damage + %i WHERE steamid = '%s'", DbPrefix, Damage, ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_tank_damage", Damage);
}
/*
UpdatePlayerScore(Client, Score)
{
	if (Score == 0)
		return;

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			UpdatePlayerScoreVersus(Client, GetClientTeam(Client), Score);
		}
		case GAMEMODE_REALISM:
		{
			UpdatePlayerScoreRealismVersus(Client, GetClientTeam(Client), Score);
		}
		case GAMEMODE_SURVIVAL:
		{
			UpdatePlayerScore2(Client, Score, "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			UpdatePlayerScoreScavenge(Client, GetClientTeam(Client), Score);
		}
		case GAMEMODE_OTHERMUTATIONS:
		{
			UpdatePlayerScore2(Client, Score, "points_mutations");
		}
		default:
		{
			UpdatePlayerScore2(Client, Score, "points");
		}
	}
}

UpdatePlayerScoreVersus(Client, ClientTeam, Score)
{
	if (Score == 0)
		return;

	if (ClientTeam == TEAM_SURVIVORS)
		UpdatePlayerScore2(Client, Score, "points_survivors");
	else if (ClientTeam == TEAM_INFECTED)
		UpdatePlayerScore2(Client, Score, "points_infected");
}

UpdatePlayerScoreRealismVersus(Client, ClientTeam, Score)
{
	if (Score == 0)
		return;

	if (ClientTeam == TEAM_SURVIVORS)
		UpdatePlayerScore2(Client, Score, "points_realism_survivors");
	else if (ClientTeam == TEAM_INFECTED)
		UpdatePlayerScore2(Client, Score, "points_realism_infected");
}

UpdatePlayerScoreScavenge(Client, ClientTeam, Score)
{
	if (Score == 0)
		return;

	if (ClientTeam == TEAM_SURVIVORS)
		UpdatePlayerScore2(Client, Score, "points_scavenge_survivors");
	else if (ClientTeam == TEAM_INFECTED)
		UpdatePlayerScore2(Client, Score, "points_scavenge_infected");
}
*/
UpdatePlayerScore2(Client, Score, const String:Points[])
{
	if (Score == 0)
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i WHERE steamid = '%s'", DbPrefix, Points, Points, Score, ClientID);
	SendSQLUpdate(query);

	if (Score > 0)
		UpdateMapStat("points", Score);

	AddScore(Client, Score);
}

UpdateTankSniper(Client)
{
	if (Client <= 0)
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	UpdateTankSniperSteamID(ClientID);
}

UpdateTankSniperSteamID(const String:ClientID[])
{
	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_tanksniper = infected_tanksniper + 1 WHERE steamid = '%s'", DbPrefix, ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_tanksniper", 1);
}

// Survivor died.

SurvivorDied(Attacker, Victim, AttackerInfType = -1, Mode = -1)
{
	if (!Attacker || !Victim || StatsGetClientTeam(Attacker) != TEAM_INFECTED || StatsGetClientTeam(Victim) != TEAM_SURVIVORS)
		return;

	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	SurvivorDiedNamed(Attacker, Victim, VictimName, AttackerID, AttackerInfType, Mode);
}

// An Infected player killed a Survivor.

SurvivorDiedNamed(Attacker, Victim, const String:VictimName[], const String:AttackerID[], AttackerInfType = -1, Mode = -1)
{
	if (!Attacker || !Victim || StatsGetClientTeam(Attacker) != TEAM_INFECTED || StatsGetClientTeam(Victim) != TEAM_SURVIVORS)
		return;

//LogError("SurvivorDiedNamed - VictimName = %s", VictimName);

	if (AttackerInfType < 0)
	{
		if (ClientInfectedType[Attacker] == 0)
			SetClientInfectedType(Attacker);

		AttackerInfType = ClientInfectedType[Attacker];
	}

	if (EngineVersion1 == Engine_Left4Dead)
	{
		if (AttackerInfType != INF_ID_SMOKER
				&& AttackerInfType != INF_ID_BOOMER
				&& AttackerInfType != INF_ID_HUNTER
				&& AttackerInfType != INF_ID_TANK_L4D2) // SetClientInfectedType sets tank id to L4D2
			return;
	}
	else
	{
		if (AttackerInfType != INF_ID_SMOKER
				&& AttackerInfType != INF_ID_BOOMER
				&& AttackerInfType != INF_ID_HUNTER
				&& AttackerInfType != INF_ID_SPITTER_L4D2
				&& AttackerInfType != INF_ID_JOCKEY_L4D2
				&& AttackerInfType != INF_ID_CHARGER_L4D2
				&& AttackerInfType != INF_ID_TANK_L4D2)
			return;
	}

	new Score = GetSurvivorKillScore();

	new len = 0;
	decl String:query[1024];

	if (CurrentGamemodeID == GAMEMODE_VERSUS)
		len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET points_infected = points_infected + %i, versus_kills_survivors = versus_kills_survivors + 1 ", DbPrefix, Score);
	else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, realism_kills_survivors = realism_kills_survivors + 1 ", DbPrefix, Score);
	else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
		len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, scavenge_kills_survivors = scavenge_kills_survivors + 1 ", DbPrefix, Score);
	else
		len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET points_mutations = points_mutations + %i, mutations_kills_survivors = mutations_kills_survivors + 1 ", DbPrefix, Score);
	len += Format(query[len], sizeof(query)-len, "WHERE steamid = '%s'", AttackerID);
	SendSQLUpdate(query);
	ModeStats_RecordKills(Attacker, 1);

	if (Mode < 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode)
	{
		if (Mode > 2)
		{
			decl String:AttackerName[MAX_LINE_WIDTH];
			GetClientName(Attacker, AttackerName, sizeof(AttackerName));
			StatsPrintToChatAll("\x05%s 杀了 \x05%s \x01获得了 \x04%i \x01分!", AttackerName, VictimName, Score);
		}
		else
			StatsPrintToChat(Attacker, "你杀了 \x05%s \x01获得了 \x04%i \x01分!", VictimName, Score);
	}

	UpdateMapStat("survivor_kills", 1);
	UpdateMapStat("points_infected", Score);
	AddScore(Attacker, Score);
}

// Survivor got hurt.

SurvivorHurt(Attacker, Victim, Damage, AttackerInfType = -1, Handle:event = INVALID_HANDLE)
{
	if (!Attacker || !Victim || Damage <= 0 || Attacker == Victim)
		return;

	if (AttackerInfType < 0)
	{
		new AttackerTeam = GetClientTeam(Attacker);

		if (Attacker > 0 && AttackerTeam == TEAM_INFECTED)
			AttackerInfType = GetInfType(Attacker);
	}

	if (AttackerInfType != INF_ID_SMOKER
			&& AttackerInfType != INF_ID_BOOMER
			&& AttackerInfType != INF_ID_HUNTER
			&& AttackerInfType != INF_ID_SPITTER_L4D2
			&& AttackerInfType != INF_ID_JOCKEY_L4D2
			&& AttackerInfType != INF_ID_CHARGER_L4D2
			&& AttackerInfType != INF_ID_TANK_L4D2)
		return;

	if (TimerInfectedDamageCheck[Attacker] != INVALID_HANDLE)
	{
		CloseHandle(TimerInfectedDamageCheck[Attacker]);
		TimerInfectedDamageCheck[Attacker] = INVALID_HANDLE;
	}

	new VictimHealth = GetClientHealth(Victim);

	if (VictimHealth < 0)
		Damage += VictimHealth;

	if (Damage <= 0)
		return;

	if (AttackerInfType == INF_ID_TANK_L4D2 && event != INVALID_HANDLE)
	{
		InfectedDamageCounter[Attacker] += TankDamage(Attacker, Damage);

		decl String:Weapon[16];
		GetEventString(event, "weapon", Weapon, sizeof(Weapon));

		new RockHit = GetConVarInt(cvar_TankThrowRockSuccess);

		if (RockHit > 0 && strcmp(Weapon, "tank_rock", false) == 0)
		{
			if (CurrentGamemodeID == GAMEMODE_VERSUS)
				UpdatePlayerScore2(Attacker, RockHit, "points_infected");
			else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
				UpdatePlayerScore2(Attacker, RockHit, "points_realism_infected");
			else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
				UpdatePlayerScore2(Attacker, RockHit, "points_scavenge_infected");
			else
				UpdatePlayerScore2(Attacker, RockHit, "points_mutations");
			UpdateTankSniper(Attacker);

			decl String:VictimName[MAX_LINE_WIDTH];

			if (Victim > 0)
				GetClientName(Victim, VictimName, sizeof(VictimName));
			else
				Format(VictimName, sizeof(VictimName), "UNKNOWN");

			new Mode = GetConVarInt(cvar_AnnounceMode);

			if (Mode == 1 || Mode == 2)
				StatsPrintToChat(Attacker, "你因为丢石头到 \x05%s\x01头上获得 \x04%i \x01分!", VictimName, RockHit);
			else if (Mode == 3)
			{
				decl String:AttackerName[MAX_LINE_WIDTH];
				GetClientName(Attacker, AttackerName, sizeof(AttackerName));
				StatsPrintToChatAll("\x05%s \x01丢石头到\x05%s\x01头上获得 \x04%i \x01分!", AttackerName, VictimName, RockHit);
			}
		}
	}
	else
		InfectedDamageCounter[Attacker] += Damage;

	if (AttackerInfType == INF_ID_SMOKER)
		SmokerDamageCounter[Attacker] += Damage;
	else if (AttackerInfType == INF_ID_SPITTER_L4D2)
		SpitterDamageCounter[Attacker] += Damage;
	else if (AttackerInfType == INF_ID_JOCKEY_L4D2)
		JockeyDamageCounter[Attacker] += Damage;
	else if (AttackerInfType == INF_ID_CHARGER_L4D2)
		ChargerDamageCounter[Attacker] += Damage;

	TimerInfectedDamageCheck[Attacker] = CreateTimer(5.0, timer_InfectedDamageCheck, Attacker);
}

// Survivor was hurt by normal infected while being blinded and/or paralyzed.

SurvivorHurtExternal(Handle:event, Victim)
{
	if (event == INVALID_HANDLE || !Victim)
		return;

	new Damage = GetEventInt(event, "dmg_health");

	new VictimHealth = GetClientHealth(Victim);

	if (VictimHealth < 0)
		Damage += VictimHealth;

	if (Damage <= 0)
		return;

	new Attacker;

	if (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1])
	{
		Attacker = PlayerBlinded[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}

	if (PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1])
	{
		Attacker = PlayerParalyzed[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (PlayerLunged[Victim][0] && PlayerLunged[Victim][1])
	{
		Attacker = PlayerLunged[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1])
	{
		Attacker = PlayerPlummeled[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (PlayerCarried[Victim][0] && PlayerCarried[Victim][1])
	{
		Attacker = PlayerCarried[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
	{
		Attacker = PlayerJockied[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
}

PlayerDeathExternal(Victim)
{
	if (!Victim || StatsGetClientTeam(Victim) != TEAM_SURVIVORS)
		return;

	CheckSurvivorsAllDown();

	new Attacker = 0;

	if (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1])
	{
		Attacker = PlayerBlinded[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_BOOMER);
	}

	if (PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1])
	{
		Attacker = PlayerParalyzed[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_SMOKER);
	}
	else if (PlayerLunged[Victim][0] && PlayerLunged[Victim][1])
	{
		Attacker = PlayerLunged[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
	else if (PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
	{
		Attacker = PlayerJockied[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
	else if (PlayerCarried[Victim][0] && PlayerCarried[Victim][1])
	{
		Attacker = PlayerCarried[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
	else if (PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1])
	{
		Attacker = PlayerPlummeled[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
}

PlayerIncapExternal(Victim)
{
	if (!Victim || StatsGetClientTeam(Victim) != TEAM_SURVIVORS)
		return;

	CheckSurvivorsAllDown();

	new Attacker = 0;

	if (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1])
	{
		Attacker = PlayerBlinded[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}

	if (PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1])
	{
		Attacker = PlayerParalyzed[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (PlayerLunged[Victim][0] && PlayerLunged[Victim][1])
	{
		Attacker = PlayerLunged[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1])
	{
		Attacker = PlayerPlummeled[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (PlayerCarried[Victim][0] && PlayerCarried[Victim][1])
	{
		Attacker = PlayerCarried[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
	{
		Attacker = PlayerJockied[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
}

SurvivorIncappedByInfected(Attacker, Victim, Mode = -1)
{
	if (Attacker > 0 && !IsClientConnected(Attacker) || Attacker > 0 && IsClientBot(Attacker))
		return;

	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));
	decl String:AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	new Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_SurvivorIncap), 0.75, 0.5, TEAM_INFECTED);

	if (Score <= 0)
		return;

	decl String:query[512];

	if (CurrentGamemodeID == GAMEMODE_VERSUS)
		Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
	else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
	else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
		Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
	else
		Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
	SendSQLUpdate(query);

	UpdateMapStat("points_infected", Score);

	if (Mode < 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode == 1 || Mode == 2)
		StatsPrintToChat(Attacker, "你制伏 \x05%s \x01获得 \x04%i \x01分!", VictimName, Score);
	else if (Mode == 3)
		StatsPrintToChatAll("\x05%s 制伏 \x05%s \x01获得 \x04%i \x01分!", AttackerName, VictimName, Score);
}

Float:GetMedkitPointReductionFactor()
{
	if (MedkitsUsedCounter <= 0)
		return 1.0;

	new Float:Penalty = GetConVarFloat(cvar_MedkitUsedPointPenalty);

	// If Penalty is set to ZERO: There is no reduction.
	if (Penalty <= 0.0)
		return 1.0;

	new PenaltyFree = -1;

	if (CurrentGamemodeID == GAMEMODE_REALISM || CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		PenaltyFree = GetConVarInt(cvar_MedkitUsedRealismFree);

	if (PenaltyFree < 0)
		PenaltyFree = GetConVarInt(cvar_MedkitUsedFree);

	if (PenaltyFree >= MedkitsUsedCounter)
		return 1.0;

	Penalty *= MedkitsUsedCounter - PenaltyFree;

	new Float:PenaltyMax = GetConVarFloat(cvar_MedkitUsedPointPenaltyMax);

	if (Penalty > PenaltyMax)
		return 1.0 - PenaltyMax;

	return 1.0 - Penalty;
}

// Calculate the score with the medkit point reduction

GetMedkitPointReductionScore(Score, bool:ToCeil = false)
{
	new Float:ReductionFactor = GetMedkitPointReductionFactor();

	if (ReductionFactor == 1.0)
		return Score;

	if (ToCeil)
		return RoundToCeil(Score * ReductionFactor);
	else
		return RoundToFloor(Score * ReductionFactor);
}

AnnounceMedkitPenalty(Mode = -1)
{
	new Float:ReductionFactor = GetMedkitPointReductionFactor();

	if (ReductionFactor == 1.0)
		return;

	if (Mode < 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode)
		StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03所有幸存者 \x01现在只能获得正常分数的百分之 \x04%i \x01，因为用了他们的第 \x05%i 个医疗包%s\x01!", RoundToNearest(ReductionFactor * 100), MedkitsUsedCounter,  (EngineVersion1 == Engine_Left4Dead ? "" : "或电击器"));
}

GetClientInfectedType(Client)
{
	if (Client > 0 && GetClientTeam(Client) == TEAM_INFECTED)
		return GetInfType(Client);

	return 0;
}

InitializeClientInf(Client)
{
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		if (PlayerParalyzed[i][1] == Client)
		{
			PlayerParalyzed[i][0] = 0;
			PlayerParalyzed[i][1] = 0;
		}
		if (PlayerLunged[i][1] == Client)
		{
			PlayerLunged[i][0] = 0;
			PlayerLunged[i][1] = 0;
		}
		if (PlayerCarried[i][1] == Client)
		{
			PlayerCarried[i][0] = 0;
			PlayerCarried[i][1] = 0;
		}
		if (PlayerPlummeled[i][1] == Client)
		{
			PlayerPlummeled[i][0] = 0;
			PlayerPlummeled[i][1] = 0;
		}
		if (PlayerJockied[i][1] == Client)
		{
			PlayerJockied[i][0] = 0;
			PlayerJockied[i][1] = 0;
		}
	}
}
