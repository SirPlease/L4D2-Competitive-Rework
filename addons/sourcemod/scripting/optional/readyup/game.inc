#if defined _readyup_game_included
 #endinput
#endif
#define _readyup_game_included

Action Timer_RestartCountdowns(Handle timer, bool startOn)
{
	RestartCountdowns(startOn);
	return Plugin_Stop;
}

void RestartCountdowns(bool startOn)
{
	if (!inReadyUp && !startOn) {
		return;
	}
	
	if (L4D2_IsScavengeMode())
	{
		RestartScvngSetupCountdown(startOn);
		ResetAccumulatedTime();
	}
	else
	{
		RestartVersusStartCountdown(startOn);
	}
	
	RestartMobCountdown(startOn);
}

void ResetAccumulatedTime()
{
	static ConVar scavenge_round_initial_time = null;
	if (scavenge_round_initial_time == null)
		if ((scavenge_round_initial_time = FindConVar("scavenge_round_initial_time")) == null)
			return;
	
	L4D_NotifyNetworkStateChanged();
	GameRules_SetPropFloat("m_flAccumulatedTime", scavenge_round_initial_time.FloatValue);
}

void RestartVersusStartCountdown(bool startOn)
{
	static ConVar s_cv = null;
	if (s_cv == null)
		if ((s_cv = FindConVar("versus_force_start_time")) == null)
			return;
	
	L4D2_CTimerStart(L4D2CT_VersusStartTimer, startOn ? s_cv.FloatValue : 99999.9);
}

// TODO: Implement script override
static float GetRandomMobSpawnInterval()
{
	static ConVar s_cvMinInterval, s_cvMaxInterval;
	
	static ConVar z_difficulty;
	static char s_sDifficulty[10] = "normal";
	
	if (L4D2_HasConfigurableDifficultySetting())
	{
		if (z_difficulty == null)
			z_difficulty = FindConVar("z_difficulty");
		
		char buffer[10];
		z_difficulty.GetString(buffer, sizeof(buffer));
		String_ToLower(buffer, sizeof(buffer));
		
		if (strcmp(buffer, "impossible") == 0)
			strcopy(buffer, sizeof(buffer), "expert");
		
		if (strcmp(buffer, s_sDifficulty) != 0)
		{
			strcopy(s_sDifficulty, sizeof(s_sDifficulty), buffer);
			
			s_cvMinInterval = null;
			s_cvMaxInterval = null;
		}
	}
	
	if (s_cvMinInterval == null)
	{
		char buffer[64];
		FormatEx(buffer, sizeof(buffer), "z_mob_spawn_min_interval_%s", s_sDifficulty);
		s_cvMinInterval = FindConVar(buffer);
		FormatEx(buffer, sizeof(buffer), "z_mob_spawn_max_interval_%s", s_sDifficulty);
		s_cvMaxInterval = FindConVar(buffer);
	}
	
	if (s_cvMinInterval == null || s_cvMaxInterval == null)
	{
		ThrowError("Missing convars for mob spawn interval!");
	}
	
	SetRandomSeed(GetTime());
	return GetRandomFloat(s_cvMinInterval.FloatValue, s_cvMaxInterval.FloatValue);
}

void RestartMobCountdown(bool startOn)
{
	float fDuration = startOn ? GetRandomMobSpawnInterval() : 99999.9;
	L4D2_CTimerStart(L4D2CT_MobSpawnTimer, fDuration);
}

void RestartScvngSetupCountdown(bool startOn)
{
	static ConVar s_cv = null;
	if (s_cv == null)
		if ((s_cv = FindConVar("scavenge_round_setup_time")) == null)
			return;
	
	CountdownTimer timer = L4D2Direct_GetScavengeRoundSetupTimer();
	if (timer == CTimer_Null)
		return;
	
	CTimer_Start(timer, startOn ? s_cv.FloatValue : 99999.9);
	ToggleCountdownPanel(startOn);
}

void ToggleCountdownPanel(bool onoff, int client = 0)
{
	if (client > 0 && IsClientInGame(client)) ShowVGUIPanel(client, "ready_countdown", _, onoff);
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				ShowVGUIPanel(i, "ready_countdown", _, onoff);
			}
		}
	}
}

void ClearSurvivorProgress()
{
	for (int i = 0; i < 4; i++)
	{
		GameRules_SetProp("m_iVersusDistancePerSurvivor", 0, _,
				i + 4 * GameRules_GetProp("m_bAreTeamsFlipped"));
	}
}

void ResetSurvivorState()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != L4D2Team_Survivor)
			continue;
			
		SetEntProp(i, Prop_Data, "m_idrowndmg", 0.0);
		SetEntProp(i, Prop_Data, "m_idrownrestored", 0.0);
	}
}

void SetAllowSpawns(bool allow)
{
	director_no_specials.BoolValue = allow;
}

// l4d2util_stocks
stock void String_ToLower(char[] str, const int MaxSize)
{
	int iSize = strlen(str); //Сounts string length to zero terminator

	for (int i = 0; i < iSize && i < MaxSize; i++) { //more security, so that the cycle is not endless
		if (IsCharUpper(str[i])) {
			str[i] = CharToLower(str[i]);
		}
	}

	str[iSize] = '\0';
}
