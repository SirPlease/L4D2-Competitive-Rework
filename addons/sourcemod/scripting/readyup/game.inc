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

void RestartMobCountdown(bool startOn)
{
	static float fDuration = -1.0;
	
	if (startOn)
	{
		if (fDuration != -1.0) L4D2_CTimerStart(L4D2CT_MobSpawnTimer, fDuration);
	}
	else
	{
		float fTemp = L4D2_CTimerGetCountdownDuration(L4D2CT_MobSpawnTimer);
		if (fTemp != -1.0 && fTemp < 99999.9)
		{
			fDuration = fTemp;
			L4D2_CTimerStart(L4D2CT_MobSpawnTimer, 99999.9);
		}
	}
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

void SetAllowSpawns(bool allow)
{
	director_no_specials.BoolValue = allow;
}
