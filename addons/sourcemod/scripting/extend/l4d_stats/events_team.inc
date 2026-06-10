#if defined _l4d_stats_events_team_included
	#endinput
#endif
#define _l4d_stats_events_team_included

// 团队事件和 L4D2 事件：过关、团灭、控人、成就、Witch 等。

// Campaign win code.

public Action:event_CampaignWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver || StatsDisabled())
		return;

	CampaignOver = true;

	StopMapTiming();
	new Float:TotalTime = GetEngineTime() - MapTimingStartTime;
	if(TotalTime < 30.0)
	{
		StatsPrintToChatAll("记录时间小于30s，数据应该不对，没有分数奖励!(PS: 30s能完成的图算啥图)");
		return;
	}

	if (CurrentGamemodeID == GAMEMODE_SCAVENGE ||
			CurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_VictorySurvivors), 4, 12, TEAM_SURVIVORS);
	new Mode = GetConVarInt(cvar_AnnounceMode);
	new SurvivorCount = GetEventInt(event, "survivorcount");
	new ClientTeam, bool:NegativeScore = GetConVarBool(cvar_EnableNegativeScore);
	if(SurvivorCount>4)
		SurvivorCount=4;
	Score *= SurvivorCount;

	decl String:query[1024];
	decl String:iID[MAX_LINE_WIDTH];
	decl String:UpdatePoints[32], String:UpdatePointsPenalty[32];

	switch (Stats_GetCurrentStatsGamemodeID())
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

	if((AnneMultiPlayerMode() || SinglePlayerMode())){
		if((g_brpgAvailable && !L4D_RPG_GetGlobalValue(INDEX_VALID)) || !IsThisRoundValid())
		{
			Score = RoundToFloor(view_as<float>(Score) * 0.4);
		}
		else
		{
			int inf= GetAnneInfectedNumber();
			if(inf <= 4)
			{
				if(AnneMultiPlayerMode())
					Score = RoundToFloor(Score * (1 - (4 - inf) * 0.2));
			}
			else if(inf > 4 && inf <= 6)
				Score = RoundToFloor(Score + Score * (inf - 4) * 0.1);
			else if(inf > 6 && inf <= 8)
				Score = RoundToFloor(Score + Score * (inf - 4) * 0.2);
			else if(inf>8)
				Score = RoundToFloor(Score + Score * (inf-4)*0.3);
		}	
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
		//娱乐模式完成关卡统一只给100分
		if(Score > 400)
			Score = 400;
		//return Plugin_Continue;
	}

	if(!CheckIsOfficalMap())return;

	new maxplayers = MaxClients;
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, iID, sizeof(iID));
				new ClientScore = NewPlayerBonus_ApplyScoreMultiplier(i, Score);

				Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_campaigns = award_campaigns + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, ClientScore, iID);
				SendSQLUpdate(query);

				if (ClientScore > 0)
				{
					UpdateMapStat("points", ClientScore);
					ScoreLog_SetContext("campaign_win", "base=l4d_stats_campaign*survivor_count,difficulty,anne,player_count,hardcore,fun,newbie_multiplier");
					AddScore(i, ClientScore);
				}
			}
			else if (ClientTeam == TEAM_INFECTED && NegativeScore)
			{
				GetClientRankAuthString(i, iID, sizeof(iID));

				Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i WHERE steamid = '%s'", DbPrefix, UpdatePointsPenalty, UpdatePointsPenalty, Score, iID);
				SendSQLUpdate(query);

				if (Score > 0)
				{
					ScoreLog_SetContext("campaign_infected_penalty", "base=campaign_win_score,negative_score");
					AddScore(i, Score * (-1));
				}
			}
		}
	}

	if (Mode && Score > 0)
	{
		StatsPrintToChatTeam(TEAM_SURVIVORS, "{lightgreen}所有幸存者因 {olive}%i 幸存者{green}完成了救援关 {default}获得了 {green}%i {default}分!", SurvivorCount, Score);
		NewPlayerBonus_AnnounceMultiplier("救援关", Score);

		if (NegativeScore)
			StatsPrintToChatTeam(TEAM_INFECTED, "{lightgreen}所有感染者因 {green}没能阻拦幸存者完成救援关{default}! {lightgreen}失去了 {green}%i {default}分", Score);
	}
}

// Safe House reached code. Points are given to all players.
// Also, Witch Not Disturbed code, points also given to all players.

public Action:event_MapTransitionPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	MapChangingForConnectAnnounce = true;

	if (StatsDisabled())
		return;
	g_broundend = true;
}

public Action:event_MapTransition(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;
	CheckSurvivorsWin();
}

// Begin panic event.

public Action:event_PanicEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	if (CampaignOver || PanicEvent)
		return;

	PanicEvent = true;

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL)
	{
		SurvivalStart();
		return;
	}

	CreateTimer(75.0, timer_PanicEventEnd);
}

// Panic Event with no Incaps code. Points given to all players.

public Action:timer_PanicEventEnd(Handle:timer, Handle:hndl)
{
	if (StatsDisabled())
		return;

	if (CampaignOver || CurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (PanicEvent && !PanicEventIncap)
	{
		new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Panic), 2, 4, TEAM_SURVIVORS);

		if (Score > 0)
		{
			decl String:query[1024];
			decl String:iID[MAX_LINE_WIDTH];
			decl String:UpdatePoints[32];

			switch (Stats_GetCurrentStatsGamemodeID())
			{
				case GAMEMODE_VERSUS:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
				}
				case GAMEMODE_REALISM:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
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

			new maxplayers = MaxClients;
			for (new i = 1; i <= maxplayers; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
				{
					GetClientRankAuthString(i, iID, sizeof(iID));
					Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i WHERE steamid = '%s' ", DbPrefix, UpdatePoints, UpdatePoints, Score, iID);
					SendSQLUpdate(query);
					UpdateMapStat("points", Score);
					AddScore(i, Score);
				}
			}

			if (Mode)
				StatsPrintToChatTeam(TEAM_SURVIVORS, "{lightgreen}所有幸存者因 {olive}尸潮事件过后没有倒地或者死亡 {default}获得了 {green}%i {default}分!", Score);
		}
	}

	PanicEvent = false;
	PanicEventIncap = false;
}

// Begin Boomer blind.

public Action:event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (StatsGetClientTeam(Attacker) != TEAM_INFECTED)
		return;

	PlayerVomited = true;

//	new bool:Infected = GetEventBool(event, "infected");
//
//	if (!Infected)
//		return;

	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsClientBot(Attacker))
		return;

	PlayerBlinded[Victim][0] = 1;
	PlayerBlinded[Victim][1] = Attacker;

	BoomerHitCounter[Attacker]++;

	if (TimerBoomerPerfectCheck[Attacker] != INVALID_HANDLE)
	{
		CloseHandle(TimerBoomerPerfectCheck[Attacker]);
		TimerBoomerPerfectCheck[Attacker] = INVALID_HANDLE;
	}

	TimerBoomerPerfectCheck[Attacker] = CreateTimer(6.0, timer_BoomerBlindnessCheck, Attacker);
}

// Boomer Mob Survival with no Incaps code. Points are given to all players.

public Action:event_PlayerBlindEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;
	
	if(IsFunGame())
	{
		//娱乐模式团灭不掉分也不奖励分
		return ;
	}
	new Player = GetClientOfUserId(GetEventInt(event, "userid"));

	if (StatsGetClientTeam(Player) != TEAM_SURVIVORS)
		return;

	if (Player > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndBoomerBlinded, Player);

	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (PlayerVomited && !PlayerVomitedIncap)
	{
		new Score = ModifyScoreDifficulty(GetConVarInt(cvar_BoomerMob), 2, 5, TEAM_SURVIVORS);

		if (Score > 0)
		{
			decl String:query[1024];
			decl String:iID[MAX_LINE_WIDTH];
			decl String:UpdatePoints[32];

			switch (Stats_GetCurrentStatsGamemodeID())
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

			new maxplayers = MaxClients;
			for (new i = 1; i <= maxplayers; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == 2)
				{
					GetClientRankAuthString(i, iID, sizeof(iID));
					Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i WHERE steamid = '%s' ", DbPrefix, UpdatePoints, UpdatePoints, Score, iID);
					SendSQLUpdate(query);
					UpdateMapStat("points", Score);
					AddScore(i, Score);
				}
			}
			if (Mode)
				StatsPrintToChatTeam(TEAM_SURVIVORS, "{lightgreen}所有幸存者因 {olive}boomer爆炸后无人死亡 {default}获得了 {green}%i {default}分!", Score);
		}
	}

	PlayerVomited = false;
	PlayerVomitedIncap = false;
}

// Friendly Incapicitate code. Also handles if players should be awarded
// points for surviving a Panic Event or Boomer Mob without incaps.

PlayerIncap(Attacker, Victim)
{
	// Stats enabled and CampaignOver is checked by the caller

	if (PanicEvent)
		PanicEventIncap = true;

	if (PlayerVomited)
		PlayerVomitedIncap = true;

	if (Victim <= 0)
		return;

	if (!Attacker || IsClientBot(Attacker))
	{
		// Attacker is normal indected but the Victim was infected by blinding and/or paralysation.
		if (Attacker == 0
				&& Victim > 0
				&& (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1]
					|| PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1]
					|| PlayerLunged[Victim][0] && PlayerLunged[Victim][1]
					|| PlayerCarried[Victim][0] && PlayerCarried[Victim][1]
					|| PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1]
					|| PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
				&& IsGamemodeVersus())
			PlayerIncapExternal(Victim);

		if (CurrentGamemodeID == GAMEMODE_SURVIVAL && Victim > 0)
			CheckSurvivorsAllDown();

		return;
	}

	new AttackerTeam = GetClientTeam(Attacker);
	new VictimTeam = GetClientTeam(Victim);
	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (VictimTeam == TEAM_SURVIVORS)
		CheckSurvivorsAllDown();

	// Attacker is a Survivor
	if (AttackerTeam == TEAM_SURVIVORS && VictimTeam == TEAM_SURVIVORS)
	{
		decl String:AttackerID[MAX_LINE_WIDTH];
		GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));
		decl String:AttackerName[MAX_LINE_WIDTH];
		GetClientName(Attacker, AttackerName, sizeof(AttackerName));

		decl String:VictimName[MAX_LINE_WIDTH];
		GetClientName(Victim, VictimName, sizeof(VictimName));

		new Score = 0;
		if (GetConVarBool(cvar_EnableNegativeScore))
		{
			if (!IsClientBot(Victim))
				Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FIncap), 2, 4, TEAM_SURVIVORS);
			else
			{
				new Float:BotScoreMultiplier = GetConVarFloat(cvar_BotScoreMultiplier);

				if (BotScoreMultiplier > 0.0)
					Score = RoundToNearest(ModifyScoreDifficultyNR(GetConVarInt(cvar_FIncap), 2, 4, TEAM_SURVIVORS) * BotScoreMultiplier);
			}
		}
		else
			Mode = 0;

		decl String:UpdatePoints[32];

		switch (Stats_GetCurrentStatsGamemodeID())
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

			decl String:query[512];
			Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i, award_fincap = award_fincap + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, AttackerID);
			SendSQLUpdate(query);
			QuarterRank_RecordField(Attacker, "award_fincap", 1);
			QuarterRank_RecordScore(Attacker, Score * (-1));

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Attacker, "你 {lightgreen}失去了 {green}%i {default}分 by {lightgreen}黑倒了 {olive}%s{default}!", Score, VictimName);
		else if (Mode == 3)
			StatsPrintToChatAll("{olive}%s {default} {lightgreen}失去了{green}%i {default}分 by {lightgreen}黒倒了 {olive}%s{default}!", AttackerName, Score, VictimName);
	}

	// Attacker is an Infected
	else if (AttackerTeam == TEAM_INFECTED && VictimTeam == TEAM_SURVIVORS)
	{
		SurvivorIncappedByInfected(Attacker, Victim, Mode);
	}
}

// Friendly Incapacitate event.

public Action:event_PlayerIncap(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if(L4D_HasAnySurvivorLeftSafeArea())PlayerIncap(Attacker, Victim);
}

// Save friendly from being dragged by Smoker.

public Action:event_TongueSave(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new Savior = GetClientOfUserId(GetEventInt(event, "userid"));

	HunterSmokerSave(Savior, Victim, GetConVarInt(cvar_SmokerDrag), 2, 3, "Smoker", "award_smoker");
}

// Save friendly from being choked by Smoker.

public Action:event_ChokeSave(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new Savior = GetClientOfUserId(GetEventInt(event, "userid"));

	HunterSmokerSave(Savior, Victim, GetConVarInt(cvar_ChokePounce), 2, 3, "Smoker", "award_smoker");
}

// Save friendly from being pounced by Hunter.

public Action:event_PounceSave(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Savior = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "Victim"));

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndHunterLunged, Victim);

	HunterSmokerSave(Savior, Victim, GetConVarInt(cvar_ChokePounce), 2, 3, "Hunter", "award_hunter");
}

// Player is hanging from a ledge.

public Action:event_PlayerFallDamage(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver || !IsGamemodeVersus())
		return;

	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new Attacker = GetClientOfUserId(GetEventInt(event, "causer"));
	new Damage = RoundToNearest(GetEventFloat(event, "damage"));

	if (Attacker == 0 && PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
		Attacker = PlayerJockied[Victim][1];

	if (Attacker == 0 || IsClientBot(Attacker) || GetClientTeam(Attacker) != TEAM_INFECTED || GetClientTeam(Victim) != TEAM_SURVIVORS || Damage <= 0)
		return;

	new VictimHealth = GetClientHealth(Victim);
	new VictimIsIncap = GetEntProp(Victim, Prop_Send, "m_isIncapacitated");

	// If the victim health is zero or below zero or is incapacitated don't count the damage from the fall
	if (VictimHealth <= 0 || VictimIsIncap != 0)
		return;

	// Damage should never exceed the amount of healt the fallen survivor had before falling down.
	if (VictimHealth < Damage)
		Damage = VictimHealth;

	if (Damage <= 0)
		return;

	SurvivorHurt(Attacker, Victim, Damage);
}

// Player melee killed an infected

public Action:event_MeleeKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	//new EntityID = GetEventInt(event, "entityid");
	//new bool:Ambushed = GetEventBool(event, "ambush");

	if (Attacker == 0 || IsClientBot(Attacker) || GetClientTeam(Attacker) != TEAM_SURVIVORS || !IsClientConnected(Attacker) || !IsClientInGame(Attacker))
		return;

	IncrementMeleeKills(Attacker);
}

// Player is hanging from a ledge.

public Action:event_PlayerLedge(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || !IsGamemodeVersus())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "causer"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Attacker == 0 && PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
		Attacker = PlayerJockied[Victim][1];

	if (Attacker == 0 || IsClientBot(Attacker) || GetClientTeam(Attacker) != TEAM_INFECTED)
		return;

	new Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_PlayerLedgeSuccess), 0.9, 0.8, TEAM_INFECTED);

	if (Score > 0)
	{
		decl String:VictimName[MAX_LINE_WIDTH];
		GetClientName(Victim, VictimName, sizeof(VictimName));

		new Mode = GetConVarInt(cvar_AnnounceMode);

		decl String:ClientID[MAX_LINE_WIDTH];
		GetClientRankAuthString(Attacker, ClientID, sizeof(ClientID));

		decl String:query[1024];
		decl String:UpdatePoints[32];
		Stats_GetPointsColumnForTeam(TEAM_INFECTED, UpdatePoints, sizeof(UpdatePoints));
		Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_ledgegrab = award_ledgegrab + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, ClientID);

		SendSQLUpdate(query);

		decl String:MapPoints[32];
		Stats_GetMapPointsFieldForTeam(TEAM_INFECTED, MapPoints, sizeof(MapPoints));
		UpdateMapStat(MapPoints, Score);

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Attacker, "你造成玩家 {olive}%s{default} 挂边获得 {green}%i {default}分!", VictimName, Score);
		else if (Mode == 3)
		{
			decl String:AttackerName[MAX_LINE_WIDTH];
			GetClientName(Attacker, AttackerName, sizeof(AttackerName));
			StatsPrintToChatAll("{olive}%s {default}造成玩家 {olive}%s{default} 挂边获得 {green}%i {default}分!", AttackerName, VictimName, Score);
		}
	}
}

// Player spawned in game.

public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Player == 0)
		return;

	InitializeClientInf(Player);
	Stats_RecordHeldSupportItems(Player);

	ClientInfectedType[Player] = 0;
	BoomerHitCounter[Player] = 0;
	BoomerVomitUpdated[Player] = false;
	SmokerDamageCounter[Player] = 0;
	SpitterDamageCounter[Player] = 0;
	JockeyDamageCounter[Player] = 0;
	ChargerDamageCounter[Player] = 0;
	ChargerImpactCounter[Player] = 0;
	TankPointsCounter[Player] = 0;
	TankDamageCounter[Player] = 0;
	TankDamageTotalCounter[Player] = 0;
	TankSurvivorKillCounter[Player] = 0;
	ChargerCarryVictim[Player] = 0;
	ChargerPlummelVictim[Player] = 0;
	JockeyVictim[Player] = 0;
	JockeyRideStartTime[Player] = 0;

	PlayerBlinded[Player][0] = 0;
	PlayerBlinded[Player][1] = 0;
	PlayerParalyzed[Player][0] = 0;
	PlayerParalyzed[Player][1] = 0;
	PlayerLunged[Player][0] = 0;
	PlayerLunged[Player][1] = 0;
	PlayerPlummeled[Player][0] = 0;
	PlayerPlummeled[Player][1] = 0;
	PlayerCarried[Player][0] = 0;
	PlayerCarried[Player][1] = 0;
	PlayerJockied[Player][0] = 0;
	PlayerJockied[Player][1] = 0;

	if (!IsClientBot(Player))
		SetClientInfectedType(Player);

	if (ChargerImpactCounterTimer[Player] != INVALID_HANDLE)
		CloseHandle(ChargerImpactCounterTimer[Player]);

	ChargerImpactCounterTimer[Player] = INVALID_HANDLE;
}

// Player hurt. Used for calculating damage points for the Infected players and also
// the friendly fire damage when Friendly Fire Mode is set to Damage Based.

public Action:event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	// Self inflicted damage does not count
	if (Attacker == Victim)
		return;

	if (Attacker == 0 || IsClientBot(Attacker))
	{
		// Attacker is normal indected but the Victim was infected by blinding and/or paralysation.
		if (Attacker == 0
				&& Victim > 0
				&& (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1]
					|| PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1]
					|| PlayerLunged[Victim][0] && PlayerLunged[Victim][1]
					|| PlayerCarried[Victim][0] && PlayerCarried[Victim][1]
					|| PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1]
					|| PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
				&& IsGamemodeVersus())
			SurvivorHurtExternal(event, Victim);

		return;
	}

	new Damage = GetEventInt(event, "dmg_health");
	new AttackerTeam = GetClientTeam(Attacker);
	new AttackerInfType = -1;

	new VictimTeam = GetClientTeam(Victim);
	if (AttackerTeam == VictimTeam && AttackerTeam == TEAM_INFECTED)
		return;

	if (Attacker > 0&&L4D_HasAnySurvivorLeftSafeArea())
	{
		if (AttackerTeam == TEAM_INFECTED)
			AttackerInfType = ClientInfectedType[Attacker];
		else if (AttackerTeam == TEAM_SURVIVORS && GetConVarInt(cvar_FriendlyFireMode) == 2)
		{
			if (VictimTeam == TEAM_SURVIVORS)
			{
				if (FriendlyFireTimer[Attacker][0] != INVALID_HANDLE)
				{
					CloseHandle(FriendlyFireTimer[Attacker][0]);
					FriendlyFireTimer[Attacker][0] = INVALID_HANDLE;
				}

				decl String:AttackerID[MAX_LINE_WIDTH];
				GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));
				decl String:AttackerName[MAX_LINE_WIDTH];
				GetClientName(Attacker, AttackerName, sizeof(AttackerName));

				// Using datapack to deliver the needed info so that the attacker can't escape the penalty by disconnecting

				new Handle:dp = INVALID_HANDLE;
				new OldHumanDamage = 0;
				new OldBotDamage = 0;

				if (!GetTrieValue(FriendlyFireDamageTrie, AttackerID, dp))
				{
					dp = CreateDataPack();
					SetTrieValue(FriendlyFireDamageTrie, AttackerID, dp);
				}
				else
				{
					// Read old damage value
					ResetPack(dp);
					OldHumanDamage = ReadPackCell(dp);
					OldBotDamage = ReadPackCell(dp);
				}

				if (IsClientBot(Victim))
					OldBotDamage += Damage;
				else
					OldHumanDamage += Damage;

				ResetPack(dp, true);

				WritePackCell(dp, OldHumanDamage);
				WritePackCell(dp, OldBotDamage);
				WritePackCell(dp, Attacker);
				WritePackString(dp, AttackerID);
				WritePackString(dp, AttackerName);

				// This may fail! What happens when a player skips and another joins with the same Client ID (is this even possible in such short time?)
				FriendlyFireTimer[Attacker][0] = CreateTimer(5.0, timer_FriendlyFireDamageEnd, dp);

				return;
			}
		}
	}
	if (AttackerInfType < 0)
		return;

//	decl String:AttackerID[MAX_LINE_WIDTH];
//	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));

//	new Mode;
//	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
//	decl String:VictimName[MAX_LINE_WIDTH];
//	new VictimTeam = 0;
//	new Score = 0;

//	if (Victim > 0)
//	{
//		GetClientName(Victim, VictimName, sizeof(VictimName));
//		VictimTeam = GetClientTeam(Victim);
//	}
//	else
//		Format(VictimName, sizeof(VictimName), "UNKNOWN");

//	if (VictimTeam == TEAM_INFECTED)
//	{
//		decl String:query[1024];
//
//		Score = GetConVarInt(cvar_FFire);
//		Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected - %i WHERE steamid = '%s'", DbPrefix, Score, AttackerID);
//		SendSQLUpdate(query);
//
//		UpdateMapStat("points_infected", Score * -1);
//		Mode = GetConVarInt(cvar_AnnounceMode);
//
//		if (Mode == 1 || Mode == 2)
//			StatsPrintToChat(Attacker, "You have {lightgreen}LOST {green}%i {default}points for {lightgreen}Friendly Firing {olive}%s{default}!", Score, VictimName);
//		else if (Mode == 3)
//		{
//			decl String:AttackerName[MAX_LINE_WIDTH];
//			GetClientName(Attacker, AttackerName, sizeof(AttackerName));
//			StatsPrintToChatAll("{olive}%s {default}has {lightgreen}LOST {green}%i {default}points for {lightgreen}Friendly Firing {olive}%s{default}!", AttackerName, Score, VictimName);
//		}
//
//		return;
//	}

	SurvivorHurt(Attacker, Victim, Damage, AttackerInfType, event);
}

// Smoker events.

public Action:event_SmokerGrap(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || !IsGamemodeVersus() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerParalyzed[Victim][0] = 1;
	PlayerParalyzed[Victim][1] = Attacker;
}

// Jockey events.

public Action:event_JockeyStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerJockied[Victim][0] = 1;
	PlayerJockied[Victim][1] = Attacker;

	JockeyVictim[Attacker] = Victim;
	JockeyRideStartTime[Attacker] = 0;

	if (Attacker == 0 || IsClientBot(Attacker) || !IsClientConnected(Attacker) || !IsClientInGame(Attacker))
		return;

	JockeyRideStartTime[Attacker] = GetTime();

	decl String:query[1024];
	decl String:iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, iID, sizeof(iID));
	Format(query, sizeof(query), "UPDATE %splayers SET jockey_rides = jockey_rides + 1 WHERE steamid = '%s'", DbPrefix, iID);
	SendSQLUpdate(query);
	UpdateMapStat("jockey_rides", 1);
}

public Action:event_JockeyRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Jockey = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new Rescuer = GetClientOfUserId(GetEventInt(event, "rescuer"));
	new Float:RideLength = GetEventFloat(event, "ride_length");

	if (Rescuer > 0 && !IsClientBot(Rescuer) && IsClientInGame(Rescuer))
	{
		decl String:query[1024], String:JockeyName[MAX_LINE_WIDTH], String:VictimName[MAX_LINE_WIDTH], String:RescuerName[MAX_LINE_WIDTH], String:RescuerID[MAX_LINE_WIDTH], String:UpdatePoints[32];
		new Score = ModifyScoreDifficulty(GetConVarInt(cvar_JockeyRide), 2, 3, TEAM_SURVIVORS);
		Score = NewPlayerBonus_ApplyScoreMultiplier(Rescuer, Score);

		GetClientRankAuthString(Rescuer, RescuerID, sizeof(RescuerID));

		switch (Stats_GetCurrentStatsGamemodeID())
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

		Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_jockey = award_jockey + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, RescuerID);
		SendSQLUpdate(query);

		if (Score > 0)
		{
			UpdateMapStat("points", Score);
			ScoreLog_SetContext("save_jockey_ride", "base=l4d_stats_jockeyride,difficulty,newbie_multiplier");
			AddScore(Rescuer, Score);
		}

		GetClientName(Jockey, JockeyName, sizeof(JockeyName));
		GetClientName(Victim, VictimName, sizeof(VictimName));

		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (Score > 0)
		{
			if (Mode == 1 || Mode == 2)
				StatsPrintToChat(Rescuer, "你将 {olive}%s {default}从 {green}%s{default} 手里救下获得{green}%i {default}分!", VictimName, JockeyName, Score);
			else if (Mode == 3)
			{
				GetClientName(Rescuer, RescuerName, sizeof(RescuerName));
				StatsPrintToChatAll("{olive}%s {default}将 {olive}%s {default}从 {green}%s{default} 手里救下获得{green}%i {default}分!", RescuerName, VictimName, JockeyName, Score);
			}
		}
	}

	JockeyVictim[Jockey] = 0;

	if (Jockey == 0 || IsClientBot(Jockey) || !IsClientInGame(Jockey))
	{
		PlayerJockied[Victim][0] = 0;
		PlayerJockied[Victim][1] = 0;
		JockeyRideStartTime[Victim] = 0;
		return;
	}

	UpdateJockeyRideLength(Jockey, RideLength);

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndJockeyRide, Victim);
}

public Action:event_JockeyKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
		return;

	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndJockeyRide, Victim);
}

// Charger events.

public Action:event_ChargerKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	int human = CheckSurvivorsHumans();
	if (StatsDisabled() || CampaignOver || human < 3)
		return Plugin_Continue;

	new Killer = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (Killer == 0 || IsClientBot(Killer) || !IsClientInGame(Killer))
		return Plugin_Continue;

	new Charger = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:query[1024], String:KillerName[MAX_LINE_WIDTH], String:KillerID[MAX_LINE_WIDTH], String:UpdatePoints[32];
	new Score = 0;
	new bool:IsMatador = GetEventBool(event, "melee") && GetEventBool(event, "charging");

	GetClientRankAuthString(Killer, KillerID, sizeof(KillerID));

	switch (Stats_GetCurrentStatsGamemodeID())
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

	if (ChargerCarryVictim[Charger])
	{
		Score += ModifyScoreDifficulty(GetConVarInt(cvar_ChargerCarry), 2, 3, TEAM_SURVIVORS);
	}
	else if (ChargerPlummelVictim[Charger])
	{
		Score += ModifyScoreDifficulty(GetConVarInt(cvar_ChargerPlummel), 2, 3, TEAM_SURVIVORS);
	}

	if (IsMatador)
	{
		// Give a Matador award
		Score += ModifyScoreDifficulty(GetConVarInt(cvar_Matador), 2, 3, TEAM_SURVIVORS);
	}

	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_charger = award_charger + 1%s WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, (IsMatador ? ", award_matador = award_matador + 1" : ""), KillerID);
	SendSQLUpdate(query);

	if (Score <= 0)
		return Plugin_Continue;

	UpdateMapStat("points", Score);
	AddScore(Killer, Score);

	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode)
	{
		GetClientName(Killer, KillerName, sizeof(KillerName));

		if (IsMatador)
		{
			if(IsFunGame() == 2)
				return Plugin_Continue;
			if (Mode == 1 || Mode == 2)
				StatsPrintToChat(Killer, "你 {green}秒了个牛{default} 获得 {green}%i {default}分!", Score);
			else if (Mode == 3)
				StatsPrintToChatAll("{olive}%s {default} {green}秒了个牛{default} 获得 {green}%i {default}分!", KillerName, Score);
		}
		else
		{
			decl String:VictimName[MAX_LINE_WIDTH], String:ChargerName[MAX_LINE_WIDTH];

			GetClientName(Charger, ChargerName, sizeof(ChargerName));

			if (ChargerCarryVictim[Charger] > 0 && (IsClientBot(ChargerCarryVictim[Charger]) || (IsClientConnected(ChargerCarryVictim[Charger]) && IsClientInGame(ChargerCarryVictim[Charger]))))
			{
				GetClientName(ChargerCarryVictim[Charger], VictimName, sizeof(VictimName));
				Format(VictimName, sizeof(VictimName), "{olive}%s{default}", VictimName);
			}
			else
				Format(VictimName, sizeof(VictimName), "a survivor");
			if(StrEqual(KillerName, VictimName))
				return Plugin_Continue;

			if (Mode == 1 || Mode == 2)
				StatsPrintToChat(Killer, "你将 {olive}%s{default} 从 {green}%s{default} 手里救下获得 {green}%i {default}分!", VictimName, ChargerName, Score);
			else if (Mode == 3)
				StatsPrintToChatAll("{olive}%s {default}将 {olive}%s{default} 从 {green}%s{default} 手里救下获得 {green}%i {default}分!", KillerName, VictimName, ChargerName, Score);
		}
	}
}

public Action:event_ChargerCarryStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerCarried[Victim][0] = 1;
	PlayerCarried[Victim][1] = Attacker;

	ChargerCarryVictim[Attacker] = Victim;

	if (IsClientBot(Attacker) || !IsClientConnected(Attacker) || !IsClientInGame(Attacker))
		return;

	IncrementImpactCounter(Attacker);
}

public Action:event_ChargerCarryRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	//new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	//if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
	//{
	//	ChargerCarryVictim[Attacker] = 0;
	//	PlayerCarried[Victim][0] = 0;
	//	PlayerCarried[Victim][1] = 0;
	//	return;
	//}

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndChargerCarry, Victim);
}

public Action:event_ChargerImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Attacker == 0 || IsClientBot(Attacker) || !IsClientConnected(Attacker) || !IsClientInGame(Attacker))
		return;

	//new Victim = GetClientOfUserId(GetEventInt(event, "victim"));
	IncrementImpactCounter(Attacker);
}

IncrementImpactCounter(client)
{
	if (ChargerImpactCounterTimer[client] != INVALID_HANDLE)
		CloseHandle(ChargerImpactCounterTimer[client]);

	ChargerImpactCounterTimer[client] = CreateTimer(3.0, timer_EndCharge, client);

	ChargerImpactCounter[client]++;
}

public Action:event_ChargerPummelStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	// There is no delay on charger carry once the plummel starts
	ChargerCarryVictim[Attacker] = 0;

	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerPlummeled[Victim][0] = 1;
	PlayerPlummeled[Victim][1] = Attacker;

	ChargerPlummelVictim[Attacker] = Victim;

	//if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
	//	return;
}

public Action:event_ChargerPummelRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
	{
		PlayerPlummeled[Victim][0] = 0;
		PlayerPlummeled[Victim][1] = 0;
		ChargerPlummelVictim[Attacker] = 0;
		return;
	}

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndChargerPlummel, Victim);
}

// Hunter events.

public Action:event_HunterRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "victim"));

	if (Player > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndHunterLunged, Player);
}

// Smoker events.

public Action:event_SmokerRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "victim"));

	if (Player > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndSmokerParalyzed, Player);
}

// L4D2 ammo upgrade deployed event.

public Action:event_UpgradePackAdded(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !SurvivalStarted)
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Player == 0 || IsClientBot(Player))
		return;

	new Score = GetConVarInt(cvar_AmmoUpgradeAdded);

	if (Score > 0)
		Score = ModifyScoreDifficulty(Score, 2, 3, TEAM_SURVIVORS);

	decl String:PlayerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Player, PlayerID, sizeof(PlayerID));

	decl String:UpdatePoints[32];

	switch (Stats_GetCurrentStatsGamemodeID())
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
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_upgrades_added = award_upgrades_added + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, PlayerID);

	SendSQLUpdate(query);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (!Mode)
			return;

		new EntityID = GetEventInt(event, "upgradeid");
		decl String:ModelName[128];
		GetEntPropString(EntityID, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));

		if (StrContains(ModelName, "incendiary_ammo", false) >= 0)
			strcopy(ModelName, sizeof(ModelName), "Incendiary Ammo");
		else if (StrContains(ModelName, "exploding_ammo", false) >= 0)
			strcopy(ModelName, sizeof(ModelName), "Exploding Ammo");
		else
			strcopy(ModelName, sizeof(ModelName), "UNKNOWN");

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Player, "你部署一个 {olive}%s{default}获得 {green}%i {default}分!", ModelName, Score);
		else if (Mode == 3)
		{
			decl String:PlayerName[MAX_LINE_WIDTH];
			GetClientName(Player, PlayerName, sizeof(PlayerName));
			StatsPrintToChatAll("{olive}%s {default}部署一个 {olive}%s{default}获得 {green}%i {default}分!", PlayerName, ModelName, Score);
		}
	}
}

// L4D2 gascan pour completed event.

public Action:event_GascanPoured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Player == 0 || IsClientBot(Player))
		return;

	new Score = GetConVarInt(cvar_GascanPoured);

	if (Score > 0)
		Score = ModifyScoreDifficulty(Score, 2, 3, TEAM_SURVIVORS);

	decl String:PlayerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Player, PlayerID, sizeof(PlayerID));

	decl String:UpdatePoints[32];

	switch (Stats_GetCurrentStatsGamemodeID())
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
	if(IsFunGame() > 1)
	{
		Score = 0;
		//return Plugin_Continue;
	}
	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_gascans_poured = award_gascans_poured + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, PlayerID);

	SendSQLUpdate(query);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Player, "你成功 {green}灌了桶油{default} 获得了 {green}%i {default}分!", Score);
		else if (Mode == 3)
		{
			decl String:PlayerName[MAX_LINE_WIDTH];
			GetClientName(Player, PlayerName, sizeof(PlayerName));
			StatsPrintToChatAll("{olive}%s {default}成功 {green}灌了桶油{default} 获得了 {green}%i {default}分!", PlayerName, Score);
		}
	}
}

// Achievement earned.

/*
56 - Helping Hand
57 - Field Medic
58 - Pharm-Assist
59 - My Bodyguard
60 - Dead Stop
61 - Crownd
62 - Untouchables
63 -
64 - Drag and Drop
65 - Blind Luck
66 - Akimbo Assassin
67 -
68 - Hero Closet
69 - Hunter Punter
70 - Tongue Twister
71 - No Smoking Section
72 -
73 - 101 Cremations
74 - Do Not Disturb
75 - Man Vs Tank
76 - TankBusters
77 - Safety First
78 - No-one Left Behind
79 -
80 -
81 - Unbreakable
82 - Witch Hunter
83 - Red Mist
84 - Pyrotechnician
85 - Zombie Genocidest
86 - Dead Giveaway
87 - Stand Tall
88 -
89 -
90 - Zombicidal Maniac
91 - What are you trying to Prove?
92 -
93 - Nothing Special
94 - Burn the Witch
95 - Towering Inferno
96 - Spinal Tap
97 - Stomach Upset
98 - Brain Salad
99 - Jump Shot
100 - Mercy Killer
101 - Back 2 Help
102 - Toll Collector
103 - Dead Baron
104 - Grim Reaper
105 - Ground Cover
106 - Clean Kill
107 - Big Drag
108 - Chain Smoker
109 - Barf Bagged
110 - Double Jump
111 - All 4 Dead
112 - Dead Wreckening
113 - Lamb 2 Slaughter
114 - Outbreak
*/

public Action:event_Achievement(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
	{
		return;
	}

	new Player = GetClientOfUserId(GetEventInt(event, "player"));
	new Achievement = GetEventInt(event, "achievement");

	if (IsClientBot(Player))
	{
		return;
	}

	if (DEBUG)
	{
		LogMessage("Achievement earned: %i", Achievement);
	}
}

// Saferoom door opens.

public Action:event_DoorOpen(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(MapTimingBlocked || MapTimingStartTime != 0.0 || !GetEventBool(event, "checkpoint") || !GetEventBool(event, "closed") || CurrentGamemodeID == GAMEMODE_SURVIVAL || StatsDisabled())
	{
		MapTimingBlocked = true;
		return Plugin_Continue;
	}

	StartMapTiming();
	Isstart = true;
	NewPlayerBonus_AnnounceRoundStart();

	return Plugin_Continue;
}

public Action:event_StartAreaPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(CurrentGamemodeID != GAMEMODE_SURVIVAL && !StatsDisabled())
		Stats_OpenStartGrantedSupportItemWindow();

	return Plugin_Continue;
}

public Action:event_StartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(CurrentGamemodeID != GAMEMODE_SURVIVAL && !StatsDisabled())
		g_bStatsPlaytimeStarted = true;

	if(CurrentGamemodeID != GAMEMODE_SURVIVAL && !StatsDisabled())
	{
		Stats_RecordStartGrantedSupportItems();
		NewPlayerBonus_AnnounceRoundStart();
	}

	if(MapTimingBlocked || MapTimingStartTime != 0.0 || CurrentGamemodeID == GAMEMODE_SURVIVAL || StatsDisabled())
	{
		MapTimingBlocked = true;
		return Plugin_Continue;
	}
	StartMapTiming();
	Isstart = true;
	NewPlayerBonus_AnnounceRoundStart();

	return Plugin_Continue;
}

public Action:event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(MapTimingBlocked || MapTimingStartTime != 0.0 || GetEventBool(event, "isbot"))
	{
		return Plugin_Continue;
	}

	new Player = GetClientOfUserId(GetEventInt(event, "userid"));
	//new NewTeam = GetEventInt(event, "team");
	//new OldTeam = GetEventInt(event, "oldteam");

	if (Player <= 0)
	{
		return Plugin_Continue;
	}

	decl String:PlayerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Player, PlayerID, sizeof(PlayerID));

	RemoveFromTrie(MapTimingSurvivors, PlayerID);
	RemoveFromTrie(MapTimingInfected, PlayerID);

	return Plugin_Continue;
}

// AbilityUse.

public Action:event_AbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientAbsOrigin(Player, HunterPosition[Player]);

	if (!IsClientBot(Player) && GetClientInfectedType(Player) == INF_ID_BOOMER)
	{
		decl String:query[1024];
		decl String:iID[MAX_LINE_WIDTH];
		GetClientRankAuthString(Player, iID, sizeof(iID));
		Format(query, sizeof(query), "UPDATE %splayers SET infected_boomer_vomits = infected_boomer_vomits + 1 WHERE steamid = '%s'", DbPrefix, iID);
		SendSQLUpdate(query);
		UpdateMapStat("infected_boomer_vomits", 1);
		BoomerVomitUpdated[Player] = true;
	}
}

// Player got pounced.

public Action:event_PlayerPounced(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerLunged[Victim][0] = 1;
	PlayerLunged[Victim][1] = Attacker;

	if (IsClientBot(Attacker))
		return;

	new Float:PouncePosition[3];

	GetClientAbsOrigin(Attacker, PouncePosition);
	new PounceDistance = RoundToNearest(GetVectorDistance(HunterPosition[Attacker], PouncePosition));

	if (PounceDistance < MinPounceDistance)
		return;

	new Dmg = RoundToNearest((((PounceDistance - float(MinPounceDistance)) / float(MaxPounceDistance - MinPounceDistance)) * float(MaxPounceDamage)) + 1);
	new DmgCap = GetConVarInt(cvar_HunterDamageCap);

	if (Dmg > DmgCap)
		Dmg = DmgCap;

	new PerfectDmgLimit = GetConVarInt(cvar_HunterPerfectPounceDamage);
	new NiceDmgLimit = GetConVarInt(cvar_HunterNicePounceDamage);

	UpdateHunterDamage(Attacker, Dmg);

	if (Dmg < NiceDmgLimit && Dmg < PerfectDmgLimit)
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);

	decl String:AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));
	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));
	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	new Score = 0;
	decl String:Label[32];
	decl String:query[1024];

	if (Dmg >= PerfectDmgLimit)
	{
		Score = GetConVarInt(cvar_HunterPerfectPounceSuccess);
		decl String:UpdatePoints[32];
		Stats_GetPointsColumnForTeam(TEAM_INFECTED, UpdatePoints, sizeof(UpdatePoints));
		Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_pounce_perfect = award_pounce_perfect + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, AttackerID);
		Format(Label, sizeof(Label), "Death From Above");

		if (EnableSounds_Hunter_Perfect && GetConVarBool(cvar_SoundsEnabled))
			EmitSoundToAll(StatsSound_Hunter_Perfect);
	}
	else
	{
		Score = GetConVarInt(cvar_HunterNicePounceSuccess);
		decl String:UpdatePoints[32];
		Stats_GetPointsColumnForTeam(TEAM_INFECTED, UpdatePoints, sizeof(UpdatePoints));
		Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_pounce_nice = award_pounce_nice + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, AttackerID);
		Format(Label, sizeof(Label), "Pain From Above");
	}

	SendSQLUpdate(query);
	decl String:MapPoints[32];
	Stats_GetMapPointsFieldForTeam(TEAM_INFECTED, MapPoints, sizeof(MapPoints));
	UpdateMapStat(MapPoints, Score);

	if (Mode == 1 || Mode == 2)
		StatsPrintToChat(Attacker, "你在{olive}%s{default}身上完成了一个 {olive}%s {default}扑倒，获得 {green}%i {default}分!", VictimName, Label, Score);
	else if (Mode == 3)
		StatsPrintToChatAll("{olive}%s 在{olive}%s{default}身上完成了一个 {olive}%s {default}扑倒，获得 {green}%i {default}分!", AttackerName, VictimName, Label, Score);
}

// Revive friendly code.

public Action:event_RevivePlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !SurvivalStarted)
		return;

	if (!Stats_IsRpgRoundValid())
		return;

	if (GetEventBool(event, "ledge_hang"))
		return;

	new Savior = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "subject"));
	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (Savior == Victim)
		return;

	if (!Stats_TryConsumeSupportRoundAward(Savior, Victim, SupportReviveAwardCount))
		return;

	decl String:SaviorName[MAX_LINE_WIDTH];
	GetClientName(Savior, SaviorName, sizeof(SaviorName));
	decl String:SaviorID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Savior, SaviorID, sizeof(SaviorID));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));
	decl String:VictimID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Victim, VictimID, sizeof(VictimID));

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Revive), 2, 3, TEAM_SURVIVORS);
	Score = NewPlayerBonus_ApplyScoreMultiplier(Savior, Score);

	decl String:UpdatePoints[32];

	switch (Stats_GetCurrentStatsGamemodeID())
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
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_revive = award_revive + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, SaviorID);
	SendSQLUpdate(query);
	QuarterRank_RecordField(Savior, "award_revive", 1);

	UpdateMapStat("points", Score);
	decl String:ScoreFormula[MAX_MESSAGE_WIDTH];
	Format(ScoreFormula, sizeof(ScoreFormula), "base=l4d_stats_revive,difficulty,target=%s,newbie_multiplier", VictimID);
	ScoreLog_SetContext("revive_teammate", ScoreFormula);
	AddScore(Savior, Score);

	if (Score > 0)
	{
		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Savior, "你因拉起 {olive}%s{default} 获得 {green}%i {default}分!", VictimName, Score);
		else if (Mode == 3)
			StatsPrintToChatAll("{olive}%s {default}因拉起 {olive}%s{default} 获得 {green}%i {default}分!", SaviorName, VictimName, Score);
	}
}

/*
L4D1:

56 - Helping Hand
57 - Field Medic
58 - Pharm-Assist
59 - My Bodyguard
60 - Dead Stop
61 - Crownd
62 - Untouchables
63 -
64 - Drag and Drop
65 - Blind Luck
66 - Akimbo Assassin
67 -
68 - Hero Closet
69 - Hunter Punter
70 - Tongue Twister
71 - No Smoking Section
72 -
73 - 101 Cremations
74 - Do Not Disturb
75 - Man Vs Tank
76 - TankBusters
77 - Safety First
78 - No-one Left Behind
79 -
80 -
81 - Unbreakable
82 - Witch Hunter
83 - Red Mist
84 - Pyrotechnician
85 - Zombie Genocidest
86 - Dead Giveaway
87 - Stand Tall
88 -
89 -
90 - Zombicidal Maniac
91 - What are you trying to Prove?
92 -
93 - Nothing Special
94 - Burn the Witch
95 - Towering Inferno
96 - Spinal Tap
97 - Stomach Upset
98 - Brain Salad
99 - Jump Shot
100 - Mercy Killer
101 - Back 2 Help
102 - Toll Collector
103 - Dead Baron
104 - Grim Reaper
105 - Ground Cover
106 - Clean Kill
107 - Big Drag
108 - Chain Smoker
109 - Barf Bagged
110 - Double Jump
111 - All 4 Dead
112 - Dead Wreckening
113 - Lamb 2 Slaughter
114 - Outbreak
*/


/*
L4D2:
0 - End of Campaign (Not 100% Sure)
7 - End of Level (Not 100% Sure)
8 - End of Level (Not 100% Sure)
17 - Kill Tank
22 - Random Director Mob
23 - End of Level (Not 100% Sure)
40 - End of Campaign (Not 100% Sure)
67 - Protect Friendly
68 - Give Pain Pills
69 - Give Adrenaline
70 - Give Heatlh (Heal using Med Pack)
71 - End of Level (Not 100% Sure)
72 - End of Campaign (Not 100% Sure)
75 - Save Friendly from Ledge Grasp
76 - Save Friendly from Special Infected
80 - Hero Closet Rescue Survivor
81 - Kill Tank with no deaths
84 - Team Kill
85 - Incap Friendly
86 - Left Friendly for Dead
87 - Friendly Fire
89 - Incap Friendly
95 - Let infected in safe room
99 - Round Restart (All Dead)
*/

// Miscellaneous events and awards. See specific award for info.

public Action:event_Award_L4D2(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
	{
		return;
	}

	new PlayerID = GetEventInt(event, "userid");

	if (!PlayerID)
	{
		return;
	}

	new User = GetClientOfUserId(PlayerID);

	if (IsClientBot(User))
	{
		return;
	}

	new SubjectID = GetEventInt(event, "subjectentid");
	new Mode = GetConVarInt(cvar_AnnounceMode);
	decl String:UserName[MAX_LINE_WIDTH];
	GetClientName(User, UserName, sizeof(UserName));

	new Recipient;
	decl String:RecipientName[MAX_LINE_WIDTH];

	new Score = 0;
	new String:AwardSQL[128];
	new AwardID = GetEventInt(event, "award");

	//StatsPrintToChat(User, "[TEST] Your actions gave you award (ID = %i)", AwardID);

	if (AwardID == 67) // Protect friendly
	{
		Recipient = Stats_ClientFromEntityOrUserId(SubjectID);

		if (!Stats_IsSurvivorHuman(User) || !Stats_IsSurvivorHuman(Recipient) || User == Recipient)
		{
			return;
		}

		if (!Stats_IsRpgRoundValid())
		{
			return;
		}

		ProtectedFriendlyCounter[User]++;

		if (TimerProtectedFriendly[User] != INVALID_HANDLE)
		{
			CloseHandle(TimerProtectedFriendly[User]);
			TimerProtectedFriendly[User] = INVALID_HANDLE;
		}

		new Handle:Pack = CreateDataPack();
		WritePackCell(Pack, GetClientUserId(User));
		WritePackCell(Pack, ProtectedFriendlyRoundToken);
		TimerProtectedFriendly[User] = CreateTimer(3.0, timer_ProtectedFriendly, Pack, TIMER_DATA_HNDL_CLOSE);

		return;
	}

	if (AwardID == 68) // Pills given
	{
		if (!SubjectID)
		{
			return;
		}

		if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !GetConVarBool(cvar_EnableSvMedicPoints))
		{
			return;
		}

		if (!Stats_IsRpgRoundValid())
		{
			return;
		}

		Recipient = Stats_ClientFromEntityOrUserId(SubjectID);

		GivePills(User, Recipient);

		return;
	}

	if (AwardID == 69) // Adrenaline given
	{
		if (!SubjectID)
		{
			return;
		}

		if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !GetConVarBool(cvar_EnableSvMedicPoints))
		{
			return;
		}

		if (!Stats_IsRpgRoundValid())
		{
			return;
		}

		Recipient = Stats_ClientFromEntityOrUserId(SubjectID);

		GiveAdrenaline(User, Recipient);

		return;
	}

	if (AwardID == 85) // Incap friendly
	{
		if (!SubjectID)
		{
			return;
		}

		Recipient = Stats_ClientFromEntityOrUserId(SubjectID);

		PlayerIncap(User, Recipient);

		return;
	}

	if (AwardID == 80) // Respawn friendly
	{
		if (!SubjectID)
		{
			return;
		}

		if (!Stats_IsRpgRoundValid())
		{
			return;
		}

		Recipient = Stats_ClientFromEntityOrUserId(SubjectID);

		if (!Stats_IsSurvivorHuman(User) || !Stats_IsSurvivorHuman(Recipient) || User == Recipient)
		{
			return;
		}

		Score = ModifyScoreDifficulty(GetConVarInt(cvar_Rescue), 2, 3, TEAM_SURVIVORS);
		Score = NewPlayerBonus_ApplyScoreMultiplier(User, Score);
		GetClientName(Recipient, RecipientName, sizeof(RecipientName));
		Format(AwardSQL, sizeof(AwardSQL), ", award_rescue = award_rescue + 1");
		UpdateMapStat("points", Score);

		if (Score > 0)
		{
			if (Mode == 1 || Mode == 2)
			{
				StatsPrintToChat(User, "你解救  {olive}%s{default}获得 {green}%i {default}分!", RecipientName, Score);
			}
			else if (Mode == 3)
			{
				StatsPrintToChatAll("{olive}%s 解救  {olive}%s{default}获得 {green}%i {default}分!", UserName, RecipientName, Score);
			}
		}
	}
	else if (AwardID == 81) // Kill Tank with no deaths
	{
		Score = ModifyScoreDifficulty(0, 1, 1, TEAM_SURVIVORS);
		Format(AwardSQL, sizeof(AwardSQL), ", award_tankkillnodeaths = award_tankkillnodeaths + 1");
	}
// Moved to event_PlayerDeath
//	else if (AwardID == 84 && !CampaignOver) // Team kill
//	{
//		if (!SubjectID)
//			return;
//
//		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));
//
//		Format(AwardSQL, sizeof(AwardSQL), ", award_teamkill = award_teamkill + 1");
//		Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FKill), 2, 4, TEAM_SURVIVORS);
//		Score = Score * -1;
//
//		if (Mode == 1 || Mode == 2)
//			StatsPrintToChat(User, "You have {lightgreen}LOST {green}%i {default}points for {lightgreen}Team Killing!", Score);
//		else if (Mode == 3)
//			StatsPrintToChatAll("{olive}%s {default}has {lightgreen}LOST {green}%i {default}points for {lightgreen}Team Killing!", UserName, Score);
//	}
	else if (AwardID == 86) // Left friendly for dead
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_left4dead = award_left4dead + 1");
		Score = ModifyScoreDifficulty(0, 1, 1, TEAM_SURVIVORS);
	}
	else if (AwardID == 95) // Let infected in safe room
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_letinsafehouse = award_letinsafehouse + 1");

		Score = 0;
		if (GetConVarBool(cvar_EnableNegativeScore))
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_InSafeRoom), 2, 4, TEAM_SURVIVORS);
		else
			Mode = 0;

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(User, "你 {lightgreen}失去了 {green}%i {default}分 by 让{lightgreen}感染者进入安全门!", Score);
		else if (Mode == 3)
			StatsPrintToChatAll("{olive}%s {default}has {lightgreen}失去了 {green}%i {default}分 by 让{lightgreen}感染者进入安全门!", UserName, Score);

		Score = Score * -1;
	}
	else if (AwardID == 99) // Round restart
	{
		UpdateMapStat("restarts", 1);
		if(!Isstart)
			return;
		Score=200;
		if (!GetConVarBool(cvar_EnableNegativeScore))
			return;
		if (AnneMultiPlayerMode() || (FindConVar("survivor_limit").IntValue > 2)){
			Score = 200;
		}
		else {
			Score= 0;
		}
		if(IsFunGame())
		{
			Score = 0;
			//return Plugin_Continue;
		}
		if(IsAnne() == 2)
		{
			Score = RoundToFloor(view_as<float>(Score) * 0.4);			
		}
		if (Mode && Score > 0)
			StatsPrintToChat(User, "{lightgreen}所有幸存者 {default}都 {lightgreen}掉了 {green}%i {default}分 by {lightgreen}大家又坐牢了!", Score);
		Mode=0;
		Score = Score * -1;
		Isstart=false;
	}
	else
	{
//StatsPrintToChat(User, "[DEBUG] event_Award => %i", AwardID);
		return;
	}

	decl String:UpdatePoints[32];
	decl String:UserID[MAX_LINE_WIDTH];
	GetClientRankAuthString(User, UserID, sizeof(UserID));

	switch (Stats_GetCurrentStatsGamemodeID())
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
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i%s WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, AwardSQL, UserID);
	SendSQLUpdate(query);
	if (AwardID == 80)
		QuarterRank_RecordField(User, "award_rescue", 1);
	else if (AwardID == 86)
		QuarterRank_RecordField(User, "award_left4dead", 1);
	else if (AwardID == 95)
		QuarterRank_RecordField(User, "award_letinsafehouse", 1);

	if (Score != 0)
	{
		decl String:ScoreFormula[MAX_MESSAGE_WIDTH];
		if (AwardID == 80)
		{
			Format(ScoreFormula, sizeof(ScoreFormula), "base=l4d_stats_rescue,difficulty,subject=%i,newbie_multiplier", SubjectID);
			ScoreLog_SetContext("rescue_closet", ScoreFormula);
		}
		else if (AwardID == 95)
		{
			ScoreLog_SetContext("infected_in_saferoom_penalty", "base=l4d_stats_insaferoom,difficulty,negative_score");
		}
		else if (AwardID == 99)
		{
			ScoreLog_SetContext("round_restart_penalty", "base=l4d_stats_restart_or_anne_restart,difficulty,negative_score");
		}
		else
		{
			Format(ScoreFormula, sizeof(ScoreFormula), "award_id=%i", AwardID);
			ScoreLog_SetContext("achievement_score", ScoreFormula);
		}
		AddScore(User, Score);
	}
}

// Scavenge halftime code.

public Action:event_ScavengeHalftime(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	CampaignOver = true;

	new maxplayers = MaxClients;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			switch (GetClientTeam(i))
			{
				case TEAM_SURVIVORS:
					InterstitialPlayerUpdate(i);
				case TEAM_INFECTED:
					DoInfectedFinalChecks(i);
			}
		}
	}
}

// Survival started code.

public Action:event_SurvivalStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	SurvivalStart();
}

public SurvivalStart()
{
	UpdateMapStat("restarts", 1);
	SurvivalStarted = true;
	g_bStatsPlaytimeStarted = true;
	MapTimingStartTime = 0.0;
	MapTimingBlocked = false;
	StartMapTiming();
}

// Car alarm triggered code.
// ====================================================================================================
// Hook Events (L4D2)
// ====================================================================================================

public Action:event_CarAlarm(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CurrentGamemodeID == GAMEMODE_SURVIVAL || !GetConVarBool(cvar_EnableNegativeScore))
		return;

	new Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_CarAlarm), 2, 3, TEAM_SURVIVORS);
	UpdateMapStat("caralarm", 1);

	if (Score <= 0)
		return;

	decl String:UpdatePoints[32];
	decl String:query[1024];

	switch (Stats_GetCurrentStatsGamemodeID())
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
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Mode = GetConVarInt(cvar_AnnounceMode);
	Score*=2;
	decl String:iID[MAX_LINE_WIDTH];

	if (IsClientConnected(attacker) && IsClientInGame(attacker) && !IsClientBot(attacker) && GetClientTeam(attacker) == TEAM_SURVIVORS)
	{
		GetClientRankAuthString(attacker, iID, sizeof(iID));
		Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, iID);
		SendSQLUpdate(query);

		if (Mode)
			StatsPrintToChatAll("{green}%N {lightgreen}失去了 {green}%i {default}分 by {lightgreen}又特么打警报车是吧.jpg{default}!", attacker, Score);
	}
}

// Reset Witch existence in the world when a new one is created.

public Action:event_WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	WitchExists = true;
}

// Witch was crowned!

public Action:event_WitchCrowned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;

	if (!Stats_IsRpgRoundValid())
		return;

	new Killer = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:Crowned = GetEventBool(event, "oneshot");

	if (Crowned && Killer > 0 && !IsClientBot(Killer) && IsClientConnected(Killer) && IsClientInGame(Killer))
	{
		decl String:SteamID[MAX_LINE_WIDTH];
		GetClientRankAuthString(Killer, SteamID, sizeof(SteamID));

		new Score = ModifyScoreDifficulty(GetConVarInt(cvar_WitchCrowned), 2, 3, TEAM_SURVIVORS);
		decl String:UpdatePoints[32];

		switch (Stats_GetCurrentStatsGamemodeID())
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
		if(IsWitchParty())
		{
			Score = RoundToCeil(Score / 2.0);
		}
		if(IsFunGame())
		{
			Score = 0;
			//return Plugin_Continue;
		}

		decl String:query[1024];
		Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_witchcrowned = award_witchcrowned + 1 WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score, SteamID);
		SendSQLUpdate(query);

		if (Score > 0 && GetConVarInt(cvar_AnnounceMode))
		{
			decl String:Name[MAX_LINE_WIDTH];
			GetClientName(Killer, Name, sizeof(Name));

			StatsPrintToChatTeam(TEAM_SURVIVORS, "{olive}%s {green}对Witch洒洒水 {default}获得{green}%i {default}分!", Name, Score);
		}
	}
}

// Witch was disturbed!

public Action:event_WitchDisturb(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	if (WitchExists)
	{
		WitchDisturb = true;

		if (!GetEventInt(event, "userid"))
			return;

		new User = GetClientOfUserId(GetEventInt(event, "userid"));

		if (IsClientBot(User))
			return;

		decl String:UserID[MAX_LINE_WIDTH];
		GetClientRankAuthString(User, UserID, sizeof(UserID));

			decl String:query[1024];
			Format(query, sizeof(query), "UPDATE %splayers SET award_witchdisturb = award_witchdisturb + 1 WHERE steamid = '%s'", DbPrefix, UserID);
			SendSQLUpdate(query);
			QuarterRank_RecordField(User, "award_witchdisturb", 1);
		}
	}
