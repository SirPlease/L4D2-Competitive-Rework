#if defined _l4d_stats_output_rank_timing_included
	#endinput
#endif
#define _l4d_stats_output_rank_timing_included

// 聊天输出、地图计时、队伍洗牌辅助、MOTD 和 Anne 模式辅助。

// Print a chat message to a specific team instead of all players

public StatsPrintToChatTeam(Team, const String:Message[], any:...)
{
	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 3);

	new AnnounceToTeam = GetConVarInt(cvar_AnnounceToTeam);

	if (Team > 0 && AnnounceToTeam)
	{
		new maxplayers = MaxClients;
		new ClientTeam;

		for (new i = 1; i <= maxplayers; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			{
				ClientTeam = GetClientTeam(i);
				if (ClientTeam == Team || (ClientTeam == TEAM_SPECTATORS && AnnounceToTeam == 2))
				{
					StatsPrintToChatPreFormatted(i, FormattedMessage);
				}
			}
		}
	}
	else
		StatsPrintToChatAllPreFormatted(FormattedMessage);
}

// Debugging...
/*
public PrintToConsoleAll(const String:Message[], any:...)
{
	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 2);

	PrintToConsole(0, FormattedMessage);

	new maxplayers = MaxClients;

	for (new i = 1; i <= maxplayers; i++)
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			PrintToConsole(i, FormattedMessage);
}*/

// Disable map timings when opposing team has human players. The time is too much depending on opposing team that is is comparable.

MapTimingEnabled()
{
	new StatsGamemodeID = Stats_GetCurrentStatsGamemodeID();
	return MapTimingBlocked || StatsGamemodeID == GAMEMODE_COOP || StatsGamemodeID == GAMEMODE_SURVIVAL || StatsGamemodeID == GAMEMODE_REALISM || StatsGamemodeID == GAMEMODE_OTHERMUTATIONS;
}

MapTimingRuns_RecordParticipant(const String:RunID[], const String:MapName[], GamemodeID, const String:ClientID[], Float:TotalTime, PlayerCounter, GameDifficulty, const String:Mutation[], Mode)
{
	decl String:query[2048];
	Format(query, sizeof(query),
		"INSERT IGNORE INTO `%stimedmap_runs` "
		... "(`run_id`,`map`,`gamemode`,`difficulty`,`steamid`,`time`,`players`,`mutation`,`mode`,`sinum`,`sitime`,`usebuy`,`auto`,`anneversion`,`created`,`modified`) "
		... "VALUES ('%s','%s',%i,%i,'%s',%f,%i,'%s',%i,%i,%i,%i,%i,'%s',NOW(),NOW())",
		DbPrefix, RunID, MapName, GamemodeID, GameDifficulty, ClientID, TotalTime, PlayerCounter, Mutation, Mode,
		GetAnneInfectedNumber(), GetAnneSISpawnTime(), g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_USEBUY), IsAutoSpawnTime(), GetAnneVersion());
	SendSQLUpdate(query);
}

public StartMapTiming()
{
	if (!MapTimingEnabled() || MapTimingStartTime != 0.0 || StatsDisabled())
	{
		return;
	}

	MapTimingStartTime = GetEngineTime();
	g_bMapTimingGlobalBroadcastSent = false;

	new ClientTeam, maxplayers = MaxClients;
	decl String:ClientID[MAX_LINE_WIDTH];

	ClearTrie(MapTimingSurvivors);
	ClearTrie(MapTimingInfected);

	new bool:SoundsEnabled = EnableSounds_Maptime_Start && GetConVarBool(cvar_SoundsEnabled);

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, ClientID, sizeof(ClientID));
				SetTrieValue(MapTimingSurvivors, ClientID, 1, true);

				if (SoundsEnabled)
					EmitSoundToClient(i, StatsSound_MapTime_Start);
			}
			else if (ClientTeam == TEAM_INFECTED)
			{
				GetClientRankAuthString(i, ClientID, sizeof(ClientID));
				SetTrieValue(MapTimingInfected, ClientID, 1, true);
			}
		}
	}
}

GetCurrentDifficulty()
{
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "normal", false)) return 1;
	else if (StrEqual(Difficulty, "hard", false)) return 2;
	else if (StrEqual(Difficulty, "impossible", false)) return 3;
	else return 0;
}

GetMapTimingDifficulty()
{
	if (AnneMultiPlayerMode() || IsAnneShotgunMode())
	{
		ConVar enabled = FindConVar("ah_ai_dynamic_enable");
		ConVar currentLevel = FindConVar("ah_ai_dynamic_current_level");
		if (currentLevel != null && (enabled == null || enabled.BoolValue))
		{
			new level = currentLevel.IntValue;
			if (level >= 1 && level <= 5)
				return level;
		}

		ConVar fixedLevel = FindConVar("ah_ai_dynamic_fixed_level");
		if (fixedLevel != null && (enabled == null || enabled.BoolValue))
		{
			new level = fixedLevel.IntValue;
			if (level >= 1 && level <= 5)
				return level;
		}
	}

	return GetCurrentDifficulty();
}

GetMapTimingDifficultyName(Difficulty, String:Name[], MaxLength)
{
	switch (Difficulty)
	{
		case 1:
			strcopy(Name, MaxLength, "简单");
		case 2:
			strcopy(Name, MaxLength, "普通");
		case 3:
			strcopy(Name, MaxLength, "困难");
		case 4:
			strcopy(Name, MaxLength, "专家");
		case 5:
			strcopy(Name, MaxLength, "极限");
		default:
			strcopy(Name, MaxLength, "未知");
	}
}

GetMapTimingMode()
{
	if (IsWitchParty())
		return 2;
	else if (IsAllCharger())
		return 3;
	else if (IsAlone())
		return 4;
	else if (Is1vht())
		return 5;
	else if (IsAnneShotgunMode())
		return 7;
	else if (IsAnne() == 2)
		return 6;
	else if (IsAnne() == 1)
		return 1;

	return 0;
}

bool:IsAnneTimingBroadcastMode(Mode)
{
	return Mode == 1 || Mode == 6 || Mode == 7;
}

GetMapTimingModeName(Mode, String:Name[], MaxLength)
{
	switch (Mode)
	{
		case 1:
			strcopy(Name, MaxLength, "普通药役");
		case 6:
			strcopy(Name, MaxLength, "硬核药役");
		case 7:
			strcopy(Name, MaxLength, "喷子药役");
		default:
			strcopy(Name, MaxLength, "药役");
	}
}

BuildMapTimingRunPlayerNames(String:Names[], MaxLength)
{
	Names[0] = '\0';

	new shown = 0;
	new total = 0;
	new enabled;
	decl String:ClientID[MAX_LINE_WIDTH], String:ClientName[MAX_NAME_LENGTH], String:Buffer[MAX_MESSAGE_WIDTH];

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i) || IsClientBot(i) || GetClientTeam(i) != TEAM_SURVIVORS)
			continue;

		GetClientRankAuthString(i, ClientID, sizeof(ClientID));
		if (!GetTrieValue(MapTimingSurvivors, ClientID, enabled) || !enabled)
			continue;

		total++;
		if (shown >= 3)
			continue;

		GetClientName(i, ClientName, sizeof(ClientName));
		if (Names[0] == '\0')
			strcopy(Names, MaxLength, ClientName);
		else
		{
			Format(Buffer, sizeof(Buffer), "%s、%s", Names, ClientName);
			strcopy(Names, MaxLength, Buffer);
		}
		shown++;
	}

	if (total > shown)
	{
		Format(Buffer, sizeof(Buffer), "%s 等%d人", Names, total);
		strcopy(Names, MaxLength, Buffer);
	}
	else if (Names[0] == '\0')
	{
		strcopy(Names, MaxLength, "本次队伍");
	}
}

public bool StopMapTiming()
{
	if (!MapTimingEnabled() || MapTimingStartTime <= 0.0 || StatsDisabled())
	{
		return false;
	}
	if(g_brpgAvailable && !L4D_RPG_GetGlobalValue(INDEX_VALID))
	{
		if (GetConVarInt(cvar_AnnounceMode))
		{
			StatsPrintToChatAll("此次结果因修改难度或开启高级人机或使用管理员功能导致 {green}无效 {default}，不记录这张地图游戏时间!");
		}
		MapTimingStartTime = -1.0;
		MapTimingBlocked = true;
		return false;
	}
	if(!IsNormalMode() && !IsThisRoundValid())
	{
		if (GetConVarInt(cvar_AnnounceMode))
		{
			StatsPrintToChatAll("此次结果因关闭tank连跳导致 {green}无效 {default}，不记录这张地图游戏时间!");
		}
		MapTimingStartTime = -1.0;
		MapTimingBlocked = true;
		return false;
	}
	int mode = GetMapTimingMode();
	ConVar multiplayer = FindConVar("l4d_multislots_survivors_manager_enable");
	if(mode > 0 && (multiplayer == null || multiplayer.IntValue == 1 || GetConVarInt(cvar_SurvivorLimit) > 4))
	{
		StatsPrintToChatAll("启用了多人运动模式，不记录这张地图游戏时间!");
		MapTimingStartTime = -1.0;
		MapTimingBlocked = true;
		return false;
	}

	new Float:TotalTime = GetEngineTime() - MapTimingStartTime;
	if(TotalTime < 30.0)
	{
		StatsPrintToChatAll("记录时间小于30s，数据应该不对，没有分数奖励!(PS: 30s能完成的图算啥图)");
		return false;
	}

	MapTimingStartTime = -1.0;
	MapTimingBlocked = true;

	new Handle:dp = INVALID_HANDLE;
	new ClientTeam, enabled, maxplayers = MaxClients;
	decl String:ClientID[MAX_LINE_WIDTH], String:MapName[MAX_LINE_WIDTH], String:query[512];

	GetCurrentMap(MapName, sizeof(MapName));

	new i, PlayerCounter = 0, InfectedCounter = (CurrentGamemodeID == GAMEMODE_VERSUS || CurrentGamemodeID == GAMEMODE_SCAVENGE ? 0 : 1);

	// 结算时以实际过关队伍为准，补登记中途加入/重连后加入的真人幸存者。
	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			GetClientRankAuthString(i, ClientID, sizeof(ClientID));
			if (!GetTrieValue(MapTimingSurvivors, ClientID, enabled))
			{
				SetTrieValue(MapTimingSurvivors, ClientID, 1, true);
			}
		}
	}

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);
			GetClientRankAuthString(i, ClientID, sizeof(ClientID));

			if (ClientTeam == TEAM_SURVIVORS && GetTrieValue(MapTimingSurvivors, ClientID, enabled))
			{
				if (enabled)
					PlayerCounter++;
			}
			else if (IsNormalMode() && ClientTeam == TEAM_INFECTED)
			{
				InfectedCounter++;
				if (GetTrieValue(MapTimingInfected, ClientID, enabled))
				{
					if (enabled)
						PlayerCounter++;
				}
			}
		}
	}

	// Game ended because all of the infected team left the server... don't record the time!
	//if (InfectedCounter <= 0)
		//return;

	new GameDifficulty = GetMapTimingDifficulty();
	new StatsGamemodeID = Stats_GetCurrentStatsGamemodeID();
	if(mode > 0)
	{
		GetThisModeBestTime(g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_USEBUY));	
		PlayerCounter = GetConVarInt(cvar_SurvivorLimit);
	}

	decl String:RunID[64];
	Format(RunID, sizeof(RunID), "%i_%i_%i", GetTime(), RoundToFloor(TotalTime * 1000.0), GetRandomInt(1000, 9999));

	decl String:RunPlayers[MAX_MESSAGE_WIDTH];
	BuildMapTimingRunPlayerNames(RunPlayers, sizeof(RunPlayers));
	MaybeAnnounceAnneNoBuyFastest(MapName, TotalTime, PlayerCounter, GameDifficulty, mode, RunPlayers);

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, ClientID, sizeof(ClientID));

				if (GetTrieValue(MapTimingSurvivors, ClientID, enabled))
				{
					if (enabled)
						{
							dp = CreateDataPack();
							MapTimingRuns_RecordParticipant(RunID, MapName, StatsGamemodeID, ClientID, TotalTime, PlayerCounter, GameDifficulty, CurrentMutation, mode);

							WritePackString(dp, MapName);
							WritePackCell(dp, StatsGamemodeID);
							WritePackString(dp, ClientID);
							WritePackFloat(dp, TotalTime);
							WritePackCell(dp, i);
							WritePackCell(dp, PlayerCounter);
						WritePackCell(dp, GameDifficulty);
						WritePackString(dp, CurrentMutation);

						if(mode > 0)
						{
							Format(query, sizeof(query), "SELECT time FROM %stimedmaps WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s' AND sinum = %i AND sitime = %i AND anneversion = '%s' AND mode = %i AND usebuy = %i AND auto = %i AND players = %i", DbPrefix, MapName, StatsGamemodeID, GameDifficulty, CurrentMutation, ClientID, GetAnneInfectedNumber(), GetAnneSISpawnTime(), GetAnneVersion(), mode, g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_USEBUY), IsAutoSpawnTime(), PlayerCounter);
						}
						else
						{
							Format(query, sizeof(query), "SELECT time FROM %stimedmaps WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s' AND mode = %i", DbPrefix, MapName, StatsGamemodeID, GameDifficulty, CurrentMutation, ClientID, mode);
						}
						SQL_TQuery(db, UpdateMapTimingStat, query, dp);
					}
				}
 			}
		}
	}

	ClearTrie(MapTimingSurvivors);
	return true;
}

GetThisModeBestTime(int UseBuy=0)
{

	decl String:MapName[MAX_LINE_WIDTH], String:query[512];

	GetCurrentMap(MapName, sizeof(MapName));

	new GameDifficulty = GetMapTimingDifficulty();
	new StatsGamemodeID = Stats_GetCurrentStatsGamemodeID();
	int mode = GetMapTimingMode();
	if (mode <= 0)
		mode = 1;
	Format(query, sizeof(query), "SELECT time FROM %stimedmaps WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s'  AND sinum = %i AND sitime = %i AND anneversion = '%s' AND mode = %i AND usebuy = %i AND auto = %i AND players = %i ORDER BY time LIMIT 1", \
			DbPrefix, MapName, StatsGamemodeID, GameDifficulty, CurrentMutation, GetAnneInfectedNumber(), GetAnneSISpawnTime(), \
			GetAnneVersion(), mode, UseBuy, IsAutoSpawnTime(), GetConVarInt(cvar_SurvivorLimit));
	LogMessage("GetFastTimequery: %s", query);
	SQL_TQuery(db, GetFastTime, query);
}

MaybeAnnounceAnneNoBuyFastest(const String:MapName[], Float:TotalTime, PlayerCounter, GameDifficulty, Mode, const String:RunPlayers[])
{
	if (g_bMapTimingGlobalBroadcastSent || db == INVALID_HANDLE)
		return;

	if (!IsAnneTimingBroadcastMode(Mode) || GetAnneSISpawnTime() != 16)
		return;

	if (g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_USEBUY))
		return;

	new StatsGamemodeID = Stats_GetCurrentStatsGamemodeID();
	decl String:query[512];
	Format(query, sizeof(query), "SELECT time FROM %stimedmaps WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND sinum = %i AND sitime = 16 AND anneversion = '%s' AND mode = %i AND usebuy = 0 AND auto = %i AND players = %i ORDER BY time LIMIT 1",
		DbPrefix, MapName, StatsGamemodeID, GameDifficulty, CurrentMutation, GetAnneInfectedNumber(), GetAnneVersion(), Mode, IsAutoSpawnTime(), PlayerCounter);

	new Handle:dp = CreateDataPack();
	WritePackString(dp, MapName);
	WritePackFloat(dp, TotalTime);
	WritePackCell(dp, GameDifficulty);
	WritePackCell(dp, GetAnneInfectedNumber());
	WritePackCell(dp, Mode);
	WritePackString(dp, RunPlayers);
	WritePackString(dp, GetAnneVersion());

	SQL_TQuery(db, SQL_OnCheckAnneNoBuyFastest, query, dp);
}

public SQL_OnCheckAnneNoBuyFastest(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	ResetPack(dp);
	decl String:MapName[MAX_LINE_WIDTH], String:AnneVersion[64], String:RunPlayers[MAX_MESSAGE_WIDTH];
	new Float:TotalTime, GameDifficulty, InfectedNumber, Mode;
	ReadPackString(dp, MapName, sizeof(MapName));
	TotalTime = ReadPackFloat(dp);
	GameDifficulty = ReadPackCell(dp);
	InfectedNumber = ReadPackCell(dp);
	Mode = ReadPackCell(dp);
	ReadPackString(dp, RunPlayers, sizeof(RunPlayers));
	ReadPackString(dp, AnneVersion, sizeof(AnneVersion));
	CloseHandle(dp);

	if (hndl == INVALID_HANDLE)
	{
		LogError("[l4d_stats] Anne fastest broadcast query failed: %s", error);
		return;
	}

	new bool:IsFastest = false;
	new Float:OldTime = -1.0;
	if (SQL_GetRowCount(hndl) > 0)
	{
		SQL_FetchRow(hndl);
		OldTime = SQL_FetchFloat(hndl, 0);
		IsFastest = TotalTime < OldTime;
	}
	else
	{
		IsFastest = true;
	}

	if (!IsFastest || g_bMapTimingGlobalBroadcastSent)
		return;

	g_bMapTimingGlobalBroadcastSent = true;

	decl String:TimeLabel[32], String:DifficultyName[16], String:ModeName[32], String:Message[256];
	SetTimeLabel(TotalTime, TimeLabel, sizeof(TimeLabel));
	GetMapTimingDifficultyName(GameDifficulty, DifficultyName, sizeof(DifficultyName));
	GetMapTimingModeName(Mode, ModeName, sizeof(ModeName));
	Format(Message, sizeof(Message), "{olive}[%s地图记录刷新通告]{default}: {olive}%s{default} 在 {lightgreen}[%s]{default} 刷新 {green}%d特16秒无商店%s难度记录{default}，新纪录为 {green}%s{default}。",
		ModeName, RunPlayers, MapName, InfectedNumber, DifficultyName, TimeLabel);

	if (GetFeatureStatus(FeatureType_Native, "GlobalChat_Broadcast") == FeatureStatus_Available && GlobalChat_Broadcast(Message))
		return;

	StatsPrintToChatAll("%s", Message);
}

public GetFastTime(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	new Mode = GetConVarInt(cvar_AnnounceMode);
	if (SQL_GetRowCount(hndl) > 0)
	{
		SQL_FetchRow(hndl);
		FastestTime = SQL_FetchFloat(hndl, 0);
		char TimeLabel[32];
		SetTimeLabel(FastestTime, TimeLabel, sizeof(TimeLabel));
		if (Mode)
		{
			StatsPrintToChatAll("当前模式该难度{green} [%s使用B数] {default}最快通关速度为{green} %s {default}." , (g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_USEBUY))?"":"不", TimeLabel);
		}
	}
	else{
		if (Mode)
		{
			StatsPrintToChatAll("你来到无人的荒野，当前模式该难度没有最快纪录，快来挑战一下吧");
		}
	}
}


public UpdateMapTimingStat(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	int mode = GetMapTimingMode();
	ResetPack(dp);

	decl String:MapName[MAX_LINE_WIDTH], String:ClientID[MAX_LINE_WIDTH], String:query[512], String:TimeLabel[32], String:Mutation[MAX_LINE_WIDTH];
	new GamemodeID, Float:TotalTime, Float:OldTime, Client, PlayerCounter, GameDifficulty;
	ReadPackString(dp, MapName, sizeof(MapName));
	GamemodeID = ReadPackCell(dp);
	ReadPackString(dp, ClientID, sizeof(ClientID));
	TotalTime = ReadPackFloat(dp);
	Client = ReadPackCell(dp);
	PlayerCounter = ReadPackCell(dp);
	GameDifficulty = ReadPackCell(dp);
	ReadPackString(dp, Mutation, sizeof(Mutation));

	CloseHandle(dp);

	// Return if client is not a human player
	if (IsClientBot(Client) || !IsClientInGame(Client))
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (SQL_GetRowCount(hndl) > 0)
	{
		SQL_FetchRow(hndl);
		OldTime = SQL_FetchFloat(hndl, 0);
		if(TotalTime < 30.0)
		{
			StatsPrintToChat(Client, "记录时间小于30s，数据应该不对，此次记录不进行记录!");
			return;
		}

		if ((CurrentGamemodeID != GAMEMODE_SURVIVAL && OldTime <= TotalTime) || (CurrentGamemodeID == GAMEMODE_SURVIVAL && OldTime >= TotalTime))
		{
			if (Mode)
			{
				SetTimeLabel(OldTime, TimeLabel, sizeof(TimeLabel));
				if(mode > 0)
				{
					StatsPrintToChat(Client, "下次继续努力哦，这张图 {green}Anne%s {default}版本该难度的最快完成时间 {green}%s {default} 并没有提升!", GetAnneVersion(), TimeLabel);
				}
				else
				{
					StatsPrintToChat(Client, "下次继续努力哦，这张图最快完成时间 {green}%s {default} 并没有提升!", TimeLabel);
				}
			}
			if(mode > 0)
			{
				Format(query, sizeof(query), "UPDATE %stimedmaps SET plays = plays + 1, modified = NOW() WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s' AND sinum = %i AND sitime = %i AND anneversion = '%s' AND mode = %i AND usebuy = %i AND auto = %i", DbPrefix, MapName, GamemodeID, GameDifficulty, Mutation, ClientID, GetAnneInfectedNumber(), GetAnneSISpawnTime(), GetAnneVersion(), mode, g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_USEBUY), IsAutoSpawnTime());
			}
			else
			{
				Format(query, sizeof(query), "UPDATE %stimedmaps SET plays = plays + 1, modified = NOW() WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s' AND mode = %i", DbPrefix, MapName, GamemodeID, GameDifficulty, Mutation, ClientID, mode);
			}
		}
		else
		{
			if (Mode)
			{
				SetTimeLabel(TotalTime, TimeLabel, sizeof(TimeLabel));
				StatsPrintToChat(Client, "牛逼，你刷新了%s这张图 {green}Anne%s {default}版本该难度的最快完成时间，目前是 {green}%s{default}!", FastestTime < TotalTime?"目前":"你", GetAnneVersion(), TimeLabel);

			}

			if(mode > 0)
			{
				Format(query, sizeof(query), "UPDATE %stimedmaps SET plays = plays + 1, time = %f, players = %i, modified = NOW() WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s' AND sinum = %i AND sitime = %i AND anneversion = '%s' AND mode = %i AND usebuy = %i AND auto = %i", DbPrefix, TotalTime, PlayerCounter, MapName, GamemodeID, GameDifficulty, Mutation, ClientID, GetAnneInfectedNumber(), GetAnneSISpawnTime(), GetAnneVersion(), mode, g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_USEBUY), IsAutoSpawnTime());
			}
			else
			{
				Format(query, sizeof(query), "UPDATE %stimedmaps SET plays = plays + 1, time = %f, players = %i, modified = NOW() WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s' AND mode = %i", DbPrefix, TotalTime, PlayerCounter, MapName, GamemodeID, GameDifficulty, Mutation, ClientID, mode);
			}
			
			if (EnableSounds_Maptime_Improve && GetConVarBool(cvar_SoundsEnabled))
				EmitSoundToClient(Client, StatsSound_MapTime_Improve);
		}
	}
	else
	{
		if (Mode)
		{
			SetTimeLabel(TotalTime, TimeLabel, sizeof(TimeLabel));
			StatsPrintToChat(Client, "你花费了 {green}%s {default}来完成这张地图!", TimeLabel);
		}

		if(mode > 0)
		{
			Format(query, sizeof(query), "INSERT INTO %stimedmaps (map, gamemode, difficulty, mutation, steamid, plays, time, players, sinum, sitime, anneversion, mode, usebuy, auto, modified, created) VALUES ('%s', %i, %i, '%s', '%s', 1, %f, %i, %i, %i, '%s', %i, %i, %i, NOW(), NOW())", DbPrefix, MapName, GamemodeID, GameDifficulty, Mutation, ClientID, TotalTime, PlayerCounter, GetAnneInfectedNumber(), GetAnneSISpawnTime(), GetAnneVersion(), mode, g_brpgAvailable && L4D_RPG_GetGlobalValue(INDEX_USEBUY), IsAutoSpawnTime());
		}
		else
		{
			Format(query, sizeof(query), "INSERT INTO %stimedmaps (map, gamemode, difficulty, mutation, steamid, plays, time, players, mode, modified, created) VALUES ('%s', %i, %i, '%s', '%s', 1, %f, %i, %i, NOW(), NOW())", DbPrefix, MapName, GamemodeID, GameDifficulty, Mutation, ClientID, TotalTime, PlayerCounter, mode);
		}
	}

	FastestTime = -1.0;

	SendSQLUpdate(query);
}

public SetTimeLabel(Float:TheSeconds, String:TimeLabel[], maxsize)
{
	new FlooredSeconds = RoundToFloor(TheSeconds);
	new FlooredSecondsMod = FlooredSeconds % 60;
	new Float:Seconds = TheSeconds - float(FlooredSeconds) + float(FlooredSecondsMod);
	new Minutes = (TheSeconds < 60.0 ? 0 : RoundToNearest(float(FlooredSeconds - FlooredSecondsMod) / 60));
	new MinutesMod = Minutes % 60;
	new Hours = (Minutes < 60 ? 0 : RoundToNearest(float(Minutes - MinutesMod) / 60));
	Minutes = MinutesMod;

	if (Hours > 0)
		Format(TimeLabel, maxsize, "%i小时 %i分钟 %.1f秒", Hours, Minutes, Seconds);
	else if (Minutes > 0)
		Format(TimeLabel, maxsize, "%i 分钟 %.1f 秒", Minutes, Seconds);
	else
		Format(TimeLabel, maxsize, "%.1f 秒", Seconds);
}

public DisplayRankVote(client)
{
	DisplayYesNoPanel(client, RANKVOTE_QUESTION, RankVotePanelHandler, RoundToNearest(GetConVarFloat(cvar_RankVoteTime)));
}

// Initialize RANKVOTE
public InitializeRankVote(client)
{
	if (StatsDisabled())
	{
		if (client == 0)
		{
			PrintToConsole(0, "[RANK] Cannot initiate vote when the plugin is disabled!");
		}
		else
		{
			StatsPrintToChatPreFormatted2(client, true, "Cannot initiate vote when the plugin is disabled!");
		}

		return;
	}

	// No TEAM gamemodes are allowed
	if (!IsTeamGamemode())
	{
		if (client == 0)
		{
			PrintToConsole(0, "[RANK] The Rank Vote is not enabled in this gamemode!");
		}
		else
		{
			if (EngineVersion1 == Engine_Left4Dead)
			{
				StatsPrintToChatPreFormatted2(client, true, "The {green}Rank Vote {default}is enabled in {lightgreen}Versus {default}gamemode!");
			}
			else
			{
				StatsPrintToChatPreFormatted2(client, true, "The {green}Rank Vote {default}is enabled in {lightgreen}Versus{default}, {lightgreen}Realism Versus {default}and {lightgreen}Scavenge {default}gamemodes!");
			}
		}

		return;
	}

	if (RankVoteTimer != INVALID_HANDLE)
	{
		if (client > 0)
		{
			DisplayRankVote(client);
		}
		else
		{
			PrintToConsole(client, "[RANK] The Rank Vote is already initiated!");
		}

		return;
	}

	new bool:IsAdmin = (client > 0 ? ((GetUserFlagBits(client) & ADMFLAG_GENERIC) == ADMFLAG_GENERIC) : true);

	new team;
	decl String:ClientID[MAX_LINE_WIDTH];

	if (!IsAdmin && client > 0 && GetTrieValue(PlayerRankVoteTrie, ClientID, team))
	{
		StatsPrintToChatPreFormatted2(client, true, "You can initiate a {green}Rank Vote {default}only once per map!");
		return;
	}

	if (!IsAdmin && client > 0)
	{
		GetClientRankAuthString(client, ClientID, sizeof(ClientID));
		SetTrieValue(PlayerRankVoteTrie, ClientID, 1, true);
	}

	RankVoteTimer = CreateTimer(GetConVarFloat(cvar_RankVoteTime), timer_RankVote);

	new i;

	for (i = 0; i <= MAXPLAYERS; i++)
	{
		PlayerRankVote[i] = RANKVOTE_NOVOTE;
	}

	new maxplayers = MaxClients;

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			team = GetClientTeam(i);

			if (team == TEAM_SURVIVORS || team == TEAM_INFECTED)
			{
				DisplayRankVote(i);
			}
		}
	}

	if (client > 0)
	{
		decl String:UserName[MAX_LINE_WIDTH];
		GetClientName(client, UserName, sizeof(UserName));

		StatsPrintToChatAll2(true, "The {green}Rank Vote {default}was initiated by {olive}%s{default}!", UserName);
	}
	else
	{
		StatsPrintToChatAllPreFormatted2(true, "The {green}Rank Vote {default}was initiated from Server Console!");
	}
}

/*
	From plugin:
		name = "L4D2 Score/Team Manager",
		author = "Downtown1 & AtomicStryker",
		description = "Manage teams and scores in L4D2",
		version = 1.1.2,
		url = "http://forums.alliedmods.net/showthread.php?p=1029519"
*/

stock bool:ChangeRankPlayerTeam(client, team)
{
	if(GetClientTeam(client) == team) return true;

	if(team != TEAM_SURVIVORS)
	{
		//we can always swap to infected or spectator, it has no actual limit
		ChangeClientTeam(client, team);
		return true;
	}

	if(GetRankTeamHumanCount(team) == GetRankTeamMaxHumans(team))
		return false;

	new bot;
	//for survivors its more tricky
	for (bot = 1; bot < MaxClients + 1 && (!IsClientConnected(bot) || !IsFakeClient(bot) || (GetClientTeam(bot) != TEAM_SURVIVORS)); bot++) {}

	if (bot == MaxClients + 1)
	{
		new String:command[] = "sb_add";
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);

		ServerCommand("sb_add");

		SetCommandFlags(command, flags);

		return false;
	}

	//have to do this to give control of a survivor bot
	SDKCall(L4DStatsSHS, bot, client);
	SDKCall(L4DStatsTOB, client, true);

	return true;
}

/*
	From plugin:
		name = "L4D2 Score/Team Manager",
		author = "Downtown1 & AtomicStryker",
		description = "Manage teams and scores in L4D2",
		version = 1.1.2,
		url = "http://forums.alliedmods.net/showthread.php?p=1029519"
*/

stock bool:IsRankClientInGameHuman(client)
{
	if (client > 0) return IsClientInGame(client) && !IsFakeClient(client);
	else return false;
}

/*
	From plugin:
		name = "L4D2 Score/Team Manager",
		author = "Downtown1 & AtomicStryker",
		description = "Manage teams and scores in L4D2",
		version = 1.1.2,
		url = "http://forums.alliedmods.net/showthread.php?p=1029519"
*/

stock GetRankTeamHumanCount(team)
{
	new humans = 0;
	
	for(new i = 1; i < MaxClients + 1; i++)
	{
		if(IsRankClientInGameHuman(i) && GetClientTeam(i) == team)
		{
			humans++;
		}
	}
	
	return humans;
}

stock GetRankTeamMaxHumans(team)
{
	switch (team)
	{
		case TEAM_SURVIVORS:
			return GetConVarInt(cvar_SurvivorLimit);
		case TEAM_INFECTED:
			return GetConVarInt(cvar_InfectedLimit);
		case TEAM_SPECTATORS:
			return MaxClients;
	}
	
	return -1;
}

GetClientRankAuthString(client, String:auth[], maxlength)
{
	if (GetConVarInt(cvar_Lan))
	{
		GetClientAuthId(client,AuthId_Engine, auth, maxlength);

		if (!StrEqual(auth, "BOT", false))
		{
			GetClientIP(client, auth, maxlength);
		}
	}
	else
	{
		GetClientAuthId(client, AuthId_Engine,auth, maxlength);

		if (StrEqual(auth, "STEAM_ID_LAN", false))
		{
			GetClientIP(client, auth, maxlength);
		}
	}
}

public StatsPrintToChatAll(const String:Message[], any:...)
{
	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 2);

	StatsPrintToChatAllPreFormatted(FormattedMessage);
}

public StatsPrintToChatAll2(bool:Forced, const String:Message[], any:...)
{
	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 2);

	StatsPrintToChatAllPreFormatted2(Forced, FormattedMessage);
}

public StatsPrintToChatAllPreFormatted(const String:Message[])
{
	new maxplayers = MaxClients;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			StatsPrintToChatPreFormatted(i, Message);
		}
	}
}

public StatsPrintToChatAllPreFormatted2(bool:Forced, const String:Message[])
{
	new maxplayers = MaxClients;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			StatsPrintToChatPreFormatted2(i, Forced, Message);
		}
	}
}

public StatsPrintToChat(Client, const String:Message[], any:...)
{
	// CHECK IF CLIENT HAS MUTED THE PLUGIN
	if (ClientRankMute[Client])
	{
		return;
	}

	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 3);

	StatsPrintToChatPreFormatted(Client, FormattedMessage);
}

public StatsPrintToChat2(Client, bool:Forced, const String:Message[], any:...)
{
	// CHECK IF CLIENT HAS MUTED THE PLUGIN
	if (!Forced && ClientRankMute[Client])
	{
		return;
	}

	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 4);

	StatsPrintToChatPreFormatted2(Client, Forced, FormattedMessage);
}

public StatsPrintToChatPreFormatted(Client, const String:Message[])
{
	StatsPrintToChatPreFormatted2(Client, false, Message);
}

public StatsPrintToChatPreFormatted2(Client, bool:Forced, const String:Message[])
{
	// CHECK IF CLIENT HAS MUTED THE PLUGIN
	if (!Forced && ClientRankMute[Client])
	{
		return;
	}

	CPrintToChat(Client, "%t", "L4DStats_RankMessage", Message);
}

stock StatsGetClientTeam(client)
{
	if (client <= 0 || !IsClientConnected(client))
	{
		return TEAM_UNDEFINED;
	}

	if (IsFakeClient(client) || IsClientInGame(client))
	{
		return GetClientTeam(client);
	}

	return TEAM_UNDEFINED;
}

bool:UpdateServerSettings(Client, const String:Key[], const String:Value[], const String:Desc[])
{
	new Handle:statement = INVALID_HANDLE;
	decl String:error[1024], String:query[2048];

	// Add a row if it does not previously exist
	if (!DoFastQuery(Client, "INSERT IGNORE INTO %sserver_settings SET sname = '%s', svalue = ''", DbPrefix, Key))
	{
		PrintToConsole(Client, "[RANK] %s: Setting a new MOTD value failure!", Desc);
		return false;
	}

	Format(query, sizeof(query), "UPDATE %sserver_settings SET svalue = ? WHERE sname = '%s'", DbPrefix, Key);

	statement = SQL_PrepareQuery(db, query, error, sizeof(error));

	if (statement == INVALID_HANDLE)
	{
		PrintToConsole(Client, "[RANK] %s: Update failed! (Reason: Cannot create SQL statement)");
		return false;
	}

	new bool:retval = true;
	SQL_BindParamString(statement, 0, Value, false);

	if (!SQL_Execute(statement))
	{
		if (SQL_GetError(db, error, sizeof(error)))
		{
			PrintToConsole(Client, "[RANK] %s: Update failed! (Error = \"%s\")", Desc, error);
			LogError("%s: Update failed! (Error = \"%s\")", Desc, error);
		}
		else
		{
			PrintToConsole(Client, "[RANK] %s: Update failed!", Desc);
			LogError("%s: Update failed!", Desc);
		}
		
		retval = false;
	}
	else
	{
		PrintToConsole(Client, "[RANK] %s: Update successful!", Desc);

		if (StrEqual(Key, "motdmessage", false))
		{
			strcopy(MessageOfTheDay, sizeof(MessageOfTheDay), Value);
			ShowMOTDAll();
		}
	}

	CloseHandle(statement);
	
	return retval;
}

ShowMOTDAll()
{
	new maxplayers = MaxClients;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ShowMOTD(i);
		}
	}
}

ShowMOTD(client, bool:forced=false)
{
	if (!forced && !GetConVarBool(cvar_AnnounceMotd))
	{
		return;
	}

	StatsPrintToChat2(client, forced, "{olive}%s: {default}%s", MOTD_TITLE, MessageOfTheDay);
}

AnnouncePlayerConnect(client)
{
	if (!GetConVarBool(cvar_AnnouncePlayerJoined))
	{
		return;
	}

	DoShowPlayerJoined(client);
}

ReadDb()
{
	ReadDbMotd();
}

ReadDbMotd()
{
	if (db == INVALID_HANDLE)
		return;

	decl String:query[512];
	Format(query, sizeof(query), "SELECT svalue FROM %sserver_settings WHERE sname = 'motdmessage' LIMIT 1", DbPrefix);
	SQL_TQuery(db, ReadDbMotdCallback, query);
}

public ReadDbMotdCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("ReadDbMotdCallback Query failed: %s", error);
		return;
	}

	if (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, MessageOfTheDay, sizeof(MessageOfTheDay));
	}
}

stock bool IsGaoJiRenJiEnabled()
{
	ConVar gjrj = FindConVar("sb_fix_enabled");
	if(gjrj == null)
	{
		return false;
	}
	else if(gjrj.BoolValue)
	{
		return true;
	}
	return false;
}

stock bool IsNormalMode()
{
	ConVar cvar = FindConVar("l4d_infected_limit");
	if(cvar == null) return true;
	return false;
}

stock int IsAutoSpawnTime()
{
	ConVar cvar = FindConVar("inf_EnableAutoSpawnTime");
	if(cvar_mode == null) return false;
	return cvar.IntValue;
}

stock bool IsThisRoundValid()
{
	ConVar tank_bhop = FindConVar("ai_Tank_Bhop");
	if(AnneMultiPlayerMode())
	{
		return tank_bhop.BoolValue;
	}
	return true;
}

stock bool CheckIsOfficalMap(){
	char mapname[256];
	GetCurrentMap(mapname,sizeof(mapname));
	if(( (mapname[0]=='c') && (mapname[2]=='m') &&(mapname[4]=='_'))||((mapname[0]=='c')&&(mapname[3]=='m')&&(mapname[5]=='_')))
		return true;
	return false;
}
