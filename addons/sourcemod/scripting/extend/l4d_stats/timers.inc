#if defined _l4d_stats_timers_included
	#endinput
#endif
#define _l4d_stats_timers_included

// 状态结束、友伤统计、洗牌投票和周期更新定时器。

// End blinded state.

public Action:timer_EndBoomerBlinded(Handle:timer, any:data)
{
	PlayerBlinded[data][0] = 0;
	PlayerBlinded[data][1] = 0;
}

// End blinded state.

public Action:timer_EndSmokerParalyzed(Handle:timer, any:data)
{
	PlayerParalyzed[data][0] = 0;
	PlayerParalyzed[data][1] = 0;
}

// End lunging state.

public Action:timer_EndHunterLunged(Handle:timer, any:data)
{
	PlayerLunged[data][0] = 0;
	PlayerLunged[data][1] = 0;
}

// End plummel state.

public Action:timer_EndChargerPlummel(Handle:timer, any:data)
{
	ChargerPlummelVictim[PlayerPlummeled[data][1]] = 0;
	PlayerPlummeled[data][0] = 0;
	PlayerPlummeled[data][1] = 0;
}

// End charge impact counter state.

public Action:timer_EndCharge(Handle:timer, any:data)
{
	ChargerImpactCounterTimer[data] = INVALID_HANDLE;
	new Counter = ChargerImpactCounter[data];
	ChargerImpactCounter[data] = 0;

	new Score = 0;
	new String:ScoreSet[256] = "";

	if (Counter >= GetConVarInt(cvar_ChargerRamHits))
	{
		Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_ChargerRamSuccess), 0.9, 0.8, TEAM_INFECTED);

		if (CurrentGamemodeID == GAMEMODE_VERSUS)
		{
			Format(ScoreSet, sizeof(ScoreSet), "points_infected = points_infected + %i", Score);
		}
		else if (CurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		{
			Format(ScoreSet, sizeof(ScoreSet), "points_realism_infected = points_realism_infected + %i", Score);
		}
		else if (CurrentGamemodeID == GAMEMODE_SCAVENGE)
		{
			Format(ScoreSet, sizeof(ScoreSet), "points_scavenge_infected = points_scavenge_infected + %i", Score);
		}
		else
		{
			Format(ScoreSet, sizeof(ScoreSet), "points_mutations = points_mutations + %i", Score);
		}

		StrCat(ScoreSet, sizeof(ScoreSet), ", award_scatteringram = award_scatteringram + 1, ");

		if (EnableSounds_Charger_Ram && GetConVarBool(cvar_SoundsEnabled))
			EmitSoundToAll(SOUND_CHARGER_RAM);
	}
	//UPDATE players SET points_infected = points_infected + 40, award_scatteringram = acharger_impacts = charger_impacts + 4 WHERE steamid = 'STEAM_1:1:12345678'

	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(data, AttackerID, sizeof(AttackerID));

	decl String:query[512];
	Format(query, sizeof(query), "UPDATE %splayers SET %scharger_impacts = charger_impacts + %i WHERE steamid = '%s'", DbPrefix, ScoreSet, Counter, AttackerID);
	SendSQLUpdate(query);

	if (Score > 0)
		UpdateMapStat("points_infected", Score);

	if (Counter > 0)
		UpdateMapStat("charger_impacts", Counter);

	new Mode = 0;
	if (Score > 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if ((Mode == 1 || Mode == 2) && IsClientConnected(data) && IsClientInGame(data))
		StatsPrintToChat(data, "你用牛撞了\x03%i \x01幸存者获得了 \x04%i \x01分!", Counter, Score);
	else if (Mode == 3)
	{
		decl String:AttackerName[MAX_LINE_WIDTH];
		GetClientName(data, AttackerName, sizeof(AttackerName));
		StatsPrintToChatAll("\x05%s \x01用牛撞了\x03%i \x01幸存者获得了 \x04%i \x01分s!", AttackerName, Counter, Score);
	}
}

// End carried state.

public Action:timer_EndChargerCarry(Handle:timer, any:data)
{
	ChargerCarryVictim[PlayerCarried[data][1]] = 0;
	PlayerCarried[data][0] = 0;
	PlayerCarried[data][1] = 0;
}

// End jockey ride state.

public Action:timer_EndJockeyRide(Handle:timer, any:data)
{
	JockeyVictim[PlayerCarried[data][1]] = 0;
	PlayerJockied[data][0] = 0;
	PlayerJockied[data][1] = 0;
}

// End friendly fire damage counter.

public Action:timer_FriendlyFireDamageEnd(Handle:timer, any:dp)
{
	ResetPack(dp);

	new HumanDamage = ReadPackCell(dp);
	new BotDamage = ReadPackCell(dp);
	new Attacker = ReadPackCell(dp);

	// This may fail! What happens when a player skips and another joins with the same Client ID (is this even possible in such short time?)
	FriendlyFireTimer[Attacker][0] = INVALID_HANDLE;

	decl String:AttackerID[MAX_LINE_WIDTH];
	ReadPackString(dp, AttackerID, sizeof(AttackerID));
	decl String:AttackerName[MAX_LINE_WIDTH];
	ReadPackString(dp, AttackerName, sizeof(AttackerName));

	// The damage is read and turned into lost points...
	ResetPack(dp);
	WritePackCell(dp, 0); // Human damage
	WritePackCell(dp, 0); // Bot damage

	if (HumanDamage <= 0 && BotDamage <= 0)
		return;

	new Score = 0;
		
	if (GetConVarBool(cvar_EnableNegativeScore))
	{
		if (HumanDamage > 0)
			Score += ModifyScoreDifficultyNR(RoundToNearest(GetConVarFloat(cvar_FriendlyFireMultiplier) * HumanDamage), 2, 4, TEAM_SURVIVORS);

		if (BotDamage > 0)
			{
				new Float:BotScoreMultiplier = GetConVarFloat(cvar_BotScoreMultiplier);

				if (BotScoreMultiplier > 0.0)
					Score += ModifyScoreDifficultyNR(RoundToNearest(GetConVarFloat(cvar_FriendlyFireMultiplier) * BotDamage), 2, 4, TEAM_SURVIVORS);
			}
		}
        char UpdatePoints[32];
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

        new Mode = 0;
        if (Score > 0)
        	Mode = GetConVarInt(cvar_AnnounceMode);
        
        if ((Mode == 1 || Mode == 2) && IsClientConnected(Attacker) && IsClientInGame(Attacker))
        	StatsPrintToChat(Attacker, "你因为造成了\x05(%i 血)的友伤\x01  \x03失去了 \x04%i \x01分!", HumanDamage + BotDamage, Score);
        else if (Mode == 3)
        	StatsPrintToChatAll("\x05%s \x01因为造成了\x05(%i 血)的友伤\x01  \x03失去了 \x04%i \x01分!", AttackerName,HumanDamage + BotDamage, Score );

}

// Start team shuffle.

public Action:timer_ShuffleTeams(Handle:timer, any:data)
{
	if (CheckHumans())
		return;

	decl String:query[1024];
	Format(query, sizeof(query), "SELECT steamid FROM %splayers WHERE ", DbPrefix);

	new maxplayers = MaxClients;
	decl String:SteamID[MAX_LINE_WIDTH], String:where[512];
	new counter = 0, team;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientBot(i) || !IsClientConnected(i) || !IsClientInGame(i))
			continue;

		team = GetClientTeam(i);

		if (team != TEAM_SURVIVORS && team != TEAM_INFECTED)
			continue;

		if (counter++ > 0)
			StrCat(query, sizeof(query), "OR ");

		GetClientRankAuthString(i, SteamID, sizeof(SteamID));
		Format(where, sizeof(where), "steamid = '%s' ", SteamID);
		StrCat(query, sizeof(query), where);
	}

	if (counter <= 1)
	{
		StatsPrintToChatAllPreFormatted2(true, "Team shuffle by player PPM failed because there was \x03not enough players\x01!");
		return;
	}

	Format(where, sizeof(where), "ORDER BY (%s) / (%s) DESC", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME);
	StrCat(query, sizeof(query), where);

	SQL_TQuery(db, ExecuteTeamShuffle, query);
}

// End of RANKVOTE.

public Action:timer_RankVote(Handle:timer, any:data)
{
	RankVoteTimer = INVALID_HANDLE;

	if (!CheckHumans())
	{
		new humans = 0, votes = 0, yesvotes = 0, novotes = 0, WinningVoteCount = 0;

		CheckRankVotes(humans, votes, yesvotes, novotes, WinningVoteCount);

		StatsPrintToChatAll2(true, "Vote to shuffle teams by player PPM \x03%s \x01with \x04%i (yes) against %i (no)\x01.", (yesvotes > novotes ? "PASSED" : "DID NOT PASS"), yesvotes, novotes);

		if (yesvotes > novotes)
		{
			CreateTimer(3.0, timer_ShuffleTeams);
		}
	}
}

// End friendly fire cooldown.

public Action:timer_FriendlyFireCooldownEnd(Handle:timer, any:data)
{
	FriendlyFireCooldown[FriendlyFirePrm[data][0]][FriendlyFirePrm[data][1]] = false;
	FriendlyFireTimer[FriendlyFirePrm[data][0]][FriendlyFirePrm[data][1]] = INVALID_HANDLE;
}

// End friendly fire cooldown.

public Action:timer_MeleeKill(Handle:timer, any:data)
{
	MeleeKillTimer[data] = INVALID_HANDLE;
	new Counter = MeleeKillCounter[data];
	MeleeKillCounter[data] = 0;

	if (Counter <= 0 || IsClientBot(data) || !IsClientConnected(data) || !IsClientInGame(data) || GetClientTeam(data) != TEAM_SURVIVORS)
		return;

	decl String:query[512], String:clientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(data, clientID, sizeof(clientID));
	Format(query, sizeof(query), "UPDATE %splayers SET melee_kills = melee_kills + %i WHERE steamid = '%s'", DbPrefix, Counter, clientID);
	SendSQLUpdate(query);
}

// Perform minutely updates of player database.
// Reports Disabled message if in Versus, Easy mode, not enough Human players, and if cheats are active.

public Action:timer_UpdatePlayers(Handle:timer, Handle:hndl)
{
	if (CheckHumans())
	{
		if (GetConVarBool(cvar_DisabledMessages))
		{
			StatsPrintToChatAllPreFormatted("求生之路排名系统现在处于 \x04关闭\x01 状态, 没有足够玩家!");
		}

		return;
	}

	if (StatsDisabled())
		return;
	UpdateMapStat("playtime", 1);
	QuarterRank_QueryTop100Scores();

	new maxplayers = MaxClients;
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			CheckPlayerDB(i);
	}
}

// Display rank change.

public Action:timer_ShowRankChange(Handle:timer, any:client)
{
	DoShowRankChange(client);
}

public DoShowRankChange(Client)
{
	if (StatsDisabled())
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	QueryClientPointsSteamID(Client, ClientID, GetClientPointsRankChange);

	if (QuarterRank_Enabled())
	{
		QuarterRank_QueryClientPointsSteamID(Client, ClientID, GetClientQuarterPointsRankChange);
	}
}

// Display player rank.

public Action:timer_ShowPlayerJoined(Handle:timer, any:client)
{
	DoShowPlayerJoined(client);
}

public OnClientAuthorized(Client, const String:SteamID[]){
	if (!Client)
		return;
	if (StrEqual(SteamID, "BOT", false)) {
		return;
	}
	decl String:query[1024];
	Format(query, sizeof(query), "SELECT %s, %s FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPLAYTIME, DB_PLAYERS_TOTALPOINTS, DbPrefix, SteamID);
	SQL_TQuery(db, GetBasicInf, query, Client);
}
// Send the RANK panel to the client's display.
public GetBasicInf(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetBasicInf Query failed: %s", error);
		ScheduleDBReconnect(error);
		return;
	}

	new Playtime;
	new String:Name[32];

	if (SQL_FetchRow(hndl))
	{
		Playtime = SQL_FetchInt(hndl, 0);
		ClientPlayTime[client] = Playtime;
		ClientPoints[client] = SQL_FetchInt(hndl, 1);
		Call_StartForward(SuccessGetPlayerTime);//转发触发
		Call_PushCell(client);//按顺序将参数push进forward传参列表里
		Call_Finish();//转发结束
	}
	else
	{
		GetClientName(client, Name, sizeof(Name));
		Playtime = 0;
	}
}
public DoShowPlayerJoined(client)
{
	if (StatsDisabled())
	{
		return;
	}

	decl String:clientId[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, clientId, sizeof(clientId));

	QueryClientStatsSteamID(client, clientId, CM_PLAYERJOINED);
}

// Display common Infected scores to each player.

public Action:timer_ShowTimerScore(Handle:timer, Handle:hndl)
{
	if (StatsDisabled())
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);
	decl String:Name[MAX_LINE_WIDTH];

	new maxplayers = MaxClients;
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			// if (CurrentPoints[i] > GetConVarInt(cvar_MaxPoints))
			//     continue;

			TimerPoints[i] = GetMedkitPointReductionScore(TimerPoints[i]);
			TimerPoints[i] = NewPlayerBonus_ApplyScoreMultiplier(i, TimerPoints[i]);

			if (TimerPoints[i] > 0 && TimerKills[i] > 0)
			{
				if (Mode == 1 || Mode == 2)
				{
					StatsPrintToChat(i, "你击杀了 \x05%i \x01 个感染者获得\x04%i \x01分!", TimerKills[i], TimerPoints[i]);
				}
				else if (Mode == 3)
				{
					GetClientName(i, Name, sizeof(Name));
					StatsPrintToChatAll("\x05%s \x01击杀了 \x05%i \x01 个感染者获得\x04%i \x01分!", Name, TimerKills[i], TimerPoints[i]);
				}
			}

			InterstitialPlayerUpdateEx(i, false);
		}

		TimerPoints[i] = 0;
		TimerKills[i] = 0;
		TimerHeadshots[i] = 0;
	}

}

// Update a player's stats, used for interstitial updating.

public InterstitialPlayerUpdate(client)
{
	InterstitialPlayerUpdateEx(client, true);
}

InterstitialPlayerUpdateEx(client, bool:ApplyNewPlayerMultiplier)
{
	new AwardPoints = TimerPoints[client];
	if (ApplyNewPlayerMultiplier)
		AwardPoints = NewPlayerBonus_ApplyScoreMultiplier(client, AwardPoints);

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, ClientID, sizeof(ClientID));

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

	new len = 0;
	decl String:query[1024];
	len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET %s = %s + %i, ", DbPrefix, UpdatePoints, UpdatePoints, AwardPoints);
	len += Format(query[len], sizeof(query)-len, "kills = kills + %i, kill_infected = kill_infected + %i, ", TimerKills[client], TimerKills[client]);
	len += Format(query[len], sizeof(query)-len, "headshots = headshots + %i ", TimerHeadshots[client]);
	len += Format(query[len], sizeof(query)-len, "WHERE steamid = '%s'", ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("kills", TimerKills[client]);
	UpdateMapStat("points", AwardPoints);

	ScoreLog_SetContext("common_infected_timer", "timer_points=sum_common_infected_kills,difficulty,newbie_multiplier");
	AddScore(client, AwardPoints);
}
