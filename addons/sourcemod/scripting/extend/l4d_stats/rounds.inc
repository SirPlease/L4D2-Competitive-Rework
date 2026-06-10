#if defined _l4d_stats_rounds_included
	#endinput
#endif
#define _l4d_stats_rounds_included

// 游戏模式标签、回合开始/结束和清道夫回合入口。

public SetCurrentGamemodeName()
{
	switch (Stats_GetCurrentStatsGamemodeID())
	{
		case GAMEMODE_COOP:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "战役");
		}
		case GAMEMODE_VERSUS:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "对抗");
		}
		case GAMEMODE_REALISM:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "写实");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "生存");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "清道夫");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "写实对抗");
		}
		case GAMEMODE_OTHERMUTATIONS:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "突变模式");
		}
		default:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "未知模式");
		}
	}

	if (CurrentGamemodeID == GAMEMODE_OTHERMUTATIONS)
	{
		GetConVarString(cvar_Gamemode, CurrentMutation, sizeof(CurrentMutation));
	}
	else
	{
		CurrentMutation[0] = 0;
	}
}

public Action Event_RoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(!g_broundend && (AnneMultiPlayerMode() || SinglePlayerMode())){
		g_broundend = true;
	}else{
		return Plugin_Handled;
	}
	if(!L4D_HasAnySurvivorLeftSafeArea())
		return Plugin_Continue;
	if(!Isstart)
		return Plugin_Continue;
	UpdateMapStat("restarts", 1);
	int Score=200;
	if (!GetConVarBool(cvar_EnableNegativeScore))
		return Plugin_Continue;
	if (AnneMultiPlayerMode() || (FindConVar("survivor_limit").IntValue > 2)){
		Score = 200;
	}
	else{
		Score = 0;
	}
	
	if(IsAnne() == 2)
	{
		Score = RoundToFloor(view_as<float>(Score) * 0.4);
	}

	if(IsFunGame())
	{
		//娱乐模式团灭不掉分
		return Plugin_Continue;
	}
	
	for(int i = 1; i <= MaxClients; i++){
		if(IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == 2 || ClientEnabled[i]) && !IsFakeClient(i) && Score > 0){
			StatsPrintToChat(i, "{lightgreen}所有参与玩家 {default}都 {lightgreen}掉了 {green}%i {default}分 by {lightgreen}大家又坐牢了!", Score);
			decl String:UpdatePoints[32];
			decl String:UserID[MAX_LINE_WIDTH];
			GetClientRankAuthString(i, UserID, sizeof(UserID));

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
			Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i WHERE steamid = '%s'", DbPrefix, UpdatePoints, UpdatePoints, Score * -1, UserID);
			SendSQLUpdate(query);
		}
	}
	Isstart=false;	
	return Plugin_Continue;
}

// Scavenge round start event (occurs when door opens or players leave the start area)

public Action:event_ScavengeRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	event_RoundStart(event, name, dontBroadcast);

	g_bStatsPlaytimeStarted = true;
	StartMapTiming();
}

// Called after the connection to the database is established

public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetVars();
	CheckCurrentMapDB();
	MapTimingStartTime = 0.0;
	MapTimingBlocked = false;
	g_bStatsPlaytimeStarted = false;
	g_broundend = false;
	NewPlayerBonus_ResetRound();
	ResetRankChangeCheck();
}
