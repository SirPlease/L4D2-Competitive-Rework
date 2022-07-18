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
		scavenge_round_initial_time = FindConVar("scavenge_round_initial_time");
	
	L4D_NotifyNetworkStateChanged();
	GameRules_SetPropFloat("m_flAccumulatedTime", scavenge_round_initial_time.FloatValue);
}

void RestartVersusStartCountdown(bool startOn)
{
	static float fDuration = 0.0;
	
	if (startOn)
	{
		if (fDuration != 0.0) L4D2_CTimerStart(L4D2CT_VersusStartTimer, fDuration);
	}
	else
	{
		float temp = L4D2_CTimerGetCountdownDuration(L4D2CT_VersusStartTimer);
		if (temp != 0.0 && temp >= 3600.0)
		{
			fDuration = temp;
			L4D2_CTimerStart(L4D2CT_VersusStartTimer, 3600.0);
		}
	}
}

void RestartMobCountdown(bool startOn)
{
	static float fDuration = 0.0;
	
	if (startOn)
	{
		if (fDuration != 0.0) L4D2_CTimerStart(L4D2CT_MobSpawnTimer, fDuration);
	}
	else
	{
		float temp = L4D2_CTimerGetCountdownDuration(L4D2CT_MobSpawnTimer);
		if (temp != 0.0 && temp >= 3600.0)
		{
			fDuration = temp;
			L4D2_CTimerStart(L4D2CT_MobSpawnTimer, 3600.0);
		}
	}
}

void RestartScvngSetupCountdown(bool startOn)
{
	static float fDuration = 0.0;
	
	if (startOn)
	{
		if (fDuration != 0.0) CTimer_Start(L4D2Direct_GetScavengeRoundSetupTimer(), fDuration);
	}
	else
	{
		float temp = CTimer_GetCountdownDuration(L4D2Direct_GetScavengeRoundSetupTimer());
		if (temp != 0.0 && temp >= 99999.0)
		{
			fDuration = temp;
			CTimer_Start(L4D2Direct_GetScavengeRoundSetupTimer(), 99999.0);
		}
	}
	
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
