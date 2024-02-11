#if defined __scoremod_included
	#endinput
#endif
#define __scoremod_included

#define DEBUG_SM			false
#define SM_MODULE_NAME		"ScoreMod"

static int
	SM_iDefaultSurvivalBonus = 0,
	SM_iDefaultTieBreaker = 0,
	SM_iPillPercent = 0,
	SM_iAdrenPercent = 0,
	SM_iFirstScore = 0;

static float
	SM_fHealPercent = 0.0,
	SM_fMapMulti = 0.0,
	SM_fHBRatio = 0.0,
	SM_fSurvivalBonusRatio = 0.0,
	SM_fTempMulti[3] = {0.0, ...};

static bool
	SM_bDebugEnabled = DEBUG_SM,
	SM_bEventsHooked = false,
	SM_bModuleIsEnabled = false,
	SM_bHooked = false,
	SM_bIsFirstRoundOver = false,
	SM_bIsSecondRoundStarted = false,
	SM_bIsSecondRoundOver = false;

// Cvars
static ConVar
	SM_hEnable = null,
	SM_hHBRatio = null,
	SM_hSurvivalBonusRatio = null,
	SM_hMapMulti = null,
	SM_hCustomMaxDistance = null;

// Default Cvar Values
static ConVar
	SM_hSurvivalBonus = null,
	SM_hTieBreaker = null,
	SM_hHealPercent = null,
	SM_hPillPercent = null,
	SM_hAdrenPercent = null,
	SM_hTempMulti0 = null,
	SM_hTempMulti1 = null,
	SM_hTempMulti2 = null;

void SM_APL()
{
	CreateNative("LGO_IsScoremodEnabled", Native_IsScoremodEnabled);
	CreateNative("LGO_GetScoremodBonus", Native_GetScoremodBonus);
}

void SM_OnModuleStart()
{
	SM_hEnable = CreateConVarEx("SM_enable", "1", "L4D2 Custom Scoring - Enable/Disable", _, true, 0.0, true, 1.0);
	SM_hHBRatio = CreateConVarEx("SM_healthbonusratio", "2.0", "L4D2 Custom Scoring - Healthbonus Multiplier", _, true, 0.25, true, 5.0);
	SM_hSurvivalBonusRatio = CreateConVarEx("SM_survivalbonusratio", "0.0", "Ratio to be used for a static survival bonus against Map distance. 25% == 100 points maximum health bonus on a 400 distance map", _);
	SM_hTempMulti0 = CreateConVarEx("SM_tempmulti_incap_0", "0.30625", "L4D2 Custom Scoring - How important temp health is on survivors who have had no incaps", _, true, 0.0, true, 1.0);
	SM_hTempMulti1 = CreateConVarEx("SM_tempmulti_incap_1", "0.17500", "L4D2 Custom Scoring - How important temp health is on survivors who have had one incap", _, true, 0.0, true, 1.0);
	SM_hTempMulti2 = CreateConVarEx("SM_tempmulti_incap_2", "0.10000", "L4D2 Custom Scoring - How important temp health is on survivors who have had two incaps (black and white)", _, true, 0.0, true, 1.0);
	SM_hMapMulti = CreateConVarEx("SM_mapmulti", "1", "L4D2 Custom Scoring - Increases Healthbonus Max to Distance Max", _, true, 0.0, true, 1.0);
	SM_hCustomMaxDistance = CreateConVarEx("SM_custommaxdistance", "0", "L4D2 Custom Scoring - Custom max distance from config", _, true, 0.0, true, 1.0);

	SM_fTempMulti[0] = SM_hTempMulti0.FloatValue;
	SM_fTempMulti[1] = SM_hTempMulti1.FloatValue;
	SM_fTempMulti[2] = SM_hTempMulti2.FloatValue;

	SM_hEnable.AddChangeHook(SM_ConVarChanged_Enable);
	SM_hHBRatio.AddChangeHook(SM_CVChanged_HealthBonusRatio);
	SM_hSurvivalBonusRatio.AddChangeHook(SM_CVChanged_SurvivalBonusRatio);
	SM_hTempMulti0.AddChangeHook(SM_ConVarChanged_TempMulti0);
	SM_hTempMulti1.AddChangeHook(SM_ConVarChanged_TempMulti1);
	SM_hTempMulti2.AddChangeHook(SM_ConVarChanged_TempMulti2);

	SM_hSurvivalBonus = FindConVar("vs_survival_bonus");
	SM_hTieBreaker = FindConVar("vs_tiebreak_bonus");
	SM_hHealPercent = FindConVar("first_aid_heal_percent");
	SM_hPillPercent = FindConVar("pain_pills_health_value");
	SM_hAdrenPercent = FindConVar("adrenaline_health_buffer");

	SM_fHealPercent = SM_hHealPercent.FloatValue;
	SM_iPillPercent = SM_hPillPercent.IntValue;
	SM_iAdrenPercent = SM_hAdrenPercent.IntValue;
	SM_iDefaultSurvivalBonus = SM_hSurvivalBonus.IntValue;
	SM_iDefaultTieBreaker = SM_hTieBreaker.IntValue;

	SM_hHealPercent.AddChangeHook(SM_ConVarChanged_Health);
	SM_hPillPercent.AddChangeHook(SM_ConVarChanged_Health);
	SM_hAdrenPercent.AddChangeHook(SM_ConVarChanged_Health);

	RegConsoleCmd("sm_health", SM_Cmd_Health);
	RegConsoleCmd("sm_bonus", SM_Cmd_Health);
}

void SM_OnModuleEnd()
{
	PluginDisable(false);
}

void SM_OnMapStart()
{
	if (!IsPluginEnabled()) {
		return;
	}

	SM_fMapMulti = (!SM_hMapMulti.BoolValue) ? 1.00 : float(L4D_GetVersusMaxCompletionScore()) / 400.0;

	SM_bModuleIsEnabled = SM_hEnable.BoolValue;

	if (SM_bModuleIsEnabled && !SM_bHooked) {
		PluginEnable();
	}

	if (SM_bModuleIsEnabled) {
		SM_hTieBreaker.SetInt(0);
	}

	if (SM_bModuleIsEnabled && SM_hCustomMaxDistance.BoolValue && GetCustomMapMaxScore() > -1) {
		L4D_SetVersusMaxCompletionScore(GetCustomMapMaxScore());
		// to allow a distance score of 0 and a health bonus
		if (GetCustomMapMaxScore() > 0) {
			SM_fMapMulti = float(GetCustomMapMaxScore()) / 400.0;
		}
	}

	SM_bIsFirstRoundOver = false;
	SM_bIsSecondRoundStarted = false;
	SM_bIsSecondRoundOver = false;
	SM_iFirstScore = 0;

	SM_fTempMulti[0] = SM_hTempMulti0.FloatValue;
	SM_fTempMulti[1] = SM_hTempMulti1.FloatValue;
	SM_fTempMulti[2] = SM_hTempMulti2.FloatValue;
}

static void SM_ConVarChanged_Enable(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if (StringToInt(sNewValue) == 0) {
		PluginDisable();
		SM_bModuleIsEnabled = false;
	} else {
		PluginEnable();
		SM_bModuleIsEnabled = true;
	}
}

static void SM_ConVarChanged_TempMulti0(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	SM_fTempMulti[0] = StringToFloat(sNewValue);
}

static void SM_ConVarChanged_TempMulti1(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	SM_fTempMulti[1] = StringToFloat(sNewValue);
}

static void SM_ConVarChanged_TempMulti2(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	SM_fTempMulti[2] = StringToFloat(sNewValue);
}

static void SM_CVChanged_HealthBonusRatio(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	SM_fHBRatio = StringToFloat(sNewValue);
}

static void SM_CVChanged_SurvivalBonusRatio(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	SM_fSurvivalBonusRatio = StringToFloat(sNewValue);
}

static void SM_ConVarChanged_Health(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	SM_fHealPercent = SM_hHealPercent.FloatValue;
	SM_iPillPercent = SM_hPillPercent.IntValue;
	SM_iAdrenPercent = SM_hAdrenPercent.IntValue;
}

static void PluginEnable()
{
	ToggleHook(true);

	SM_fHBRatio = SM_hHBRatio.FloatValue;
	SM_fSurvivalBonusRatio = SM_hSurvivalBonusRatio.FloatValue;
	SM_iDefaultSurvivalBonus = SM_hSurvivalBonus.IntValue;
	SM_iDefaultTieBreaker = SM_hTieBreaker.IntValue;

	SM_hTieBreaker.SetInt(0);

	SM_fHealPercent = SM_hHealPercent.FloatValue;
	SM_iPillPercent = SM_hPillPercent.IntValue;
	SM_iAdrenPercent = SM_hAdrenPercent.IntValue;

	SM_bHooked = true;
}

static void ToggleHook(bool bIsHook)
{
	if (bIsHook) {
		if (!SM_bEventsHooked) {
			HookEvent("door_close", SM_DoorClose_Event);
			HookEvent("player_death", SM_PlayerDeath_Event);
			HookEvent("round_end", SM_RoundEnd_Event, EventHookMode_PostNoCopy);
			HookEvent("round_start", SM_RoundStart_Event, EventHookMode_PostNoCopy);
			HookEvent("finale_vehicle_leaving", SM_FinaleVehicleLeaving_Event, EventHookMode_PostNoCopy);

			/*AddCommandListener(SM_Command_Say, "say");
			AddCommandListener(SM_Command_Say, "say_team");*/

			SM_bEventsHooked = true;
		}
	} else {
		if (SM_bEventsHooked) {
			UnhookEvent("door_close", SM_DoorClose_Event);
			UnhookEvent("player_death", SM_PlayerDeath_Event);
			UnhookEvent("round_end", SM_RoundEnd_Event, EventHookMode_PostNoCopy);
			UnhookEvent("round_start", SM_RoundStart_Event, EventHookMode_PostNoCopy);
			UnhookEvent("finale_vehicle_leaving", SM_FinaleVehicleLeaving_Event, EventHookMode_PostNoCopy);

			/*RemoveCommandListener(SM_Command_Say, "say");
			RemoveCommandListener(SM_Command_Say, "say_team");*/

			SM_bEventsHooked = false;
		}
	}
}

static void PluginDisable(bool unhook = true)
{
	if (unhook) {
		ToggleHook(false);
	}

	SM_hSurvivalBonus.SetInt(SM_iDefaultSurvivalBonus);
	SM_hTieBreaker.SetInt(SM_iDefaultTieBreaker);

	SM_bHooked = false;
}

static void SM_DoorClose_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!SM_bModuleIsEnabled || !IsPluginEnabled() || !hEvent.GetBool("checkpoint")) {
		return;
	}

	SM_hSurvivalBonus.SetInt(SM_CalculateSurvivalBonus());
}

static void SM_PlayerDeath_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!SM_bModuleIsEnabled || !IsPluginEnabled()) {
		return;
	}

	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	// Can't just check for fakeclient
	if (client > 0 && GetClientTeam(client) == L4D2Team_Survivor) {
		SM_hSurvivalBonus.SetInt(SM_CalculateSurvivalBonus());
	}
}

static void SM_RoundEnd_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!SM_bModuleIsEnabled || !IsPluginEnabled()) {
		return;
	}

	if (!SM_bIsFirstRoundOver) {
		// First round just ended, save the current score.
		SM_bIsFirstRoundOver = true;
		int iAliveCount;
		SM_iFirstScore = RoundToFloor(SM_CalculateAvgHealth(iAliveCount) * SM_fMapMulti * SM_fHBRatio + 400 * SM_fMapMulti * SM_fSurvivalBonusRatio * iAliveCount / 4.0);

		// If the score is nonzero, trust the SurvivalBonus var.
		SM_iFirstScore = (SM_iFirstScore) ? (SM_hSurvivalBonus.IntValue * iAliveCount) : 0;

		//PrintToChatAll("\x01[\x05Confogl\x01] Round 1 Bonus: \x04%d", SM_iFirstScore);
		CPrintToChatAll("{blue}[{default}Confogl{blue}]{default} Round 1 Bonus: {olive}%d", SM_iFirstScore);

		if (SM_hCustomMaxDistance.BoolValue && GetCustomMapMaxScore() > -1) {
			//PrintToChatAll("\x01[\x05Confogl\x01] Custom Max Distance: \x04%d", GetCustomMapMaxScore());
			CPrintToChatAll("{blue}[{default}Confogl{blue}]{default} Custom Max Distance: {olive}%d", GetCustomMapMaxScore());
		}
	} else if (SM_bIsSecondRoundStarted && !SM_bIsSecondRoundOver) {
		SM_bIsSecondRoundOver = true;
		// Second round has ended, print scores

		int iAliveCount;
		int iScore = RoundToFloor(SM_CalculateAvgHealth(iAliveCount) * SM_fMapMulti * SM_fHBRatio + 400 * SM_fMapMulti * SM_fSurvivalBonusRatio * iAliveCount / 4.0);
		// If the score is nonzero, trust the SurvivalBonus var.
		iScore = (iScore) ? (SM_hSurvivalBonus.IntValue * iAliveCount) : 0;

		//PrintToChatAll("\x01[\x05Confogl\x01] Round 1 Bonus: \x04%d", SM_iFirstScore);
		//PrintToChatAll("\x01[\x05Confogl\x01] Round 2 Bonus: \x04%d", iScore);
		CPrintToChatAll("{blue}[{default}Confogl{blue}]{default} Round 1 Bonus: {olive}%d", SM_iFirstScore);
		CPrintToChatAll("{blue}[{default}Confogl{blue}]{default} Round 2 Bonus: {olive}%d", iScore);

		if (SM_hCustomMaxDistance.BoolValue && GetCustomMapMaxScore() > -1) {
			//PrintToChatAll("\x01[\x05Confogl\x01] Custom Max Distance: \x04%d", GetCustomMapMaxScore());
			CPrintToChatAll("{blue}[{default}Confogl{blue}]{default} Custom Max Distance: {olive}%d", GetCustomMapMaxScore());
		}
	}
}

static void SM_RoundStart_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!SM_bModuleIsEnabled || !IsPluginEnabled() || !SM_bIsFirstRoundOver) {
		return;
	}

	// Mark the beginning of the second round.
	SM_bIsSecondRoundStarted = true;
}

static void SM_FinaleVehicleLeaving_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!SM_bModuleIsEnabled || !IsPluginEnabled()) {
		return;
	}

	SM_hSurvivalBonus.SetInt(SM_CalculateSurvivalBonus());
}

static Action SM_Cmd_Health(int client, int args)
{
	if (!SM_bModuleIsEnabled || !IsPluginEnabled()) {
		return Plugin_Handled;
	}

	int iAliveCount;
	float fAvgHealth = SM_CalculateAvgHealth(iAliveCount);

	if (SM_bIsSecondRoundStarted) {
		//PrintToChat(client, "\x01[\x05Confogl\x01] Round 1 Bonus: \x04%d", SM_iFirstScore);
		CPrintToChat(client, "{blue}[{default}Confogl{blue}]{default} Round 1 Bonus: {olive}%d", SM_iFirstScore);
	}

	if (client) {
		//PrintToChat(client, "\x01[\x05Confogl\x01] Average Health: \x04%.02f", fAvgHealth);
		CPrintToChat(client, "{blue}[{default}Confogl{blue}]{default} Average Health: {olive}%.02f", fAvgHealth);
	} else {
		PrintToServer("[Confogl] Average Health: %.02f", fAvgHealth);
	}

	int iScore = RoundToFloor(fAvgHealth * SM_fMapMulti * SM_fHBRatio) * iAliveCount;

	if (SM_bDebugEnabled || IsDebugEnabled()) {
		LogMessage("[%s] CalcScore: %d MapMulti: %.02f Multiplier %.02f", SM_MODULE_NAME, iScore, SM_fMapMulti, SM_fHBRatio);
	}

	if (client) {
		//PrintToChat(client, "\x01[\x05Confogl\x01] Health Bonus: \x04%d", iScore);
		CPrintToChat(client, "{blue}[{default}Confogl{blue}]{default} Health Bonus: {olive}%d", iScore);

		if (SM_fSurvivalBonusRatio != 0.0) {
			//PrintToChat(client, "\x01[\x05Confogl\x01] Static Survival Bonus Per Survivor: \x04%d", RoundToFloor(400 * SM_fMapMulti * SM_fSurvivalBonusRatio));
			CPrintToChat(client, "{blue}[{default}Confogl{blue}]{default} Static Survival Bonus Per Survivor: {olive}%d", RoundToFloor(400 * SM_fMapMulti * SM_fSurvivalBonusRatio));
		}

		if (SM_hCustomMaxDistance.BoolValue && GetCustomMapMaxScore() > -1) {
			//PrintToChat(client, "\x01[\x05Confogl\x01] Custom Max Distance: \x04%d", GetCustomMapMaxScore());
			CPrintToChat(client, "{blue}[{default}Confogl{blue}]{default} Custom Max Distance: {olive}%d", GetCustomMapMaxScore());
		}
	} else {
		PrintToServer("[Confogl] Health Bonus: %d", iScore);

		if (SM_fSurvivalBonusRatio != 0.0) {
			PrintToServer("[Confogl] Static Survival Bonus Per Survivor: %d", RoundToFloor(400 * SM_fMapMulti * SM_fSurvivalBonusRatio));
		}

		if (SM_hCustomMaxDistance.BoolValue && GetCustomMapMaxScore() > -1) {
			PrintToServer("[Confogl] Custom Max Distance: %d", GetCustomMapMaxScore());
		}
	}

	return Plugin_Handled;
}

static float SM_CalculateAvgHealth(int &iAliveCount = 0)
{
	// Temporary Storage Variables for inventory
	char strTemp[MAX_ENTITY_NAME_LENGTH];

	int iTotalHealth, iTotalTempHealth[3], iTemp;
	int iCurrHealth, iCurrTemp, iIncapCount, iSurvCount;

	float fTotalAdjustedTempHealth;

	bool IsFinale = L4D_IsMissionFinalMap();

	iAliveCount = 0;

	for (int index = 1; index <= MaxClients; index++) {
		if (IsSurvivor(index)) {
			iSurvCount++;
			if (IsPlayerAlive(index)) {
				if (GetEntProp(index, Prop_Send, "m_isIncapacitated", 1) < 1) {

					// Get Main health stats
					iCurrHealth = GetSurvivorPermanentHealth(index);
					iCurrTemp = GetSurvivorTempHealth(index);
					iIncapCount = GetSurvivorIncapCount(index);

					// Adjust for kits
					iTemp = GetPlayerWeaponSlot(index, L4D2WeaponSlot_HeavyHealthItem);
					if (iTemp > -1) {
						GetEdictClassname(iTemp, strTemp, sizeof(strTemp));

						if (strcmp(strTemp, "weapon_first_aid_kit") == 0) {
							iCurrHealth = RoundToFloor(iCurrHealth + ((100 - iCurrHealth) * SM_fHealPercent));
							iCurrTemp = 0;
							iIncapCount = 0;
						}
					}

					// Adjust for pills/adrenaline
					iTemp = GetPlayerWeaponSlot(index, L4D2WeaponSlot_LightHealthItem);
					if (iTemp > -1) {
						GetEdictClassname(iTemp, strTemp, sizeof(strTemp));

						if (strcmp(strTemp, "weapon_pain_pills") == 0) {
							iCurrTemp += SM_iPillPercent;
						} else if (strcmp(strTemp, "weapon_adrenaline") == 0) {
							iCurrTemp += SM_iAdrenPercent;
						}
					}

					// Enforce max 100 total health points
					if ((iCurrTemp + iCurrHealth) > 100) {
						iCurrTemp = 100 - iCurrHealth;
					}

					iAliveCount++;
					iTotalHealth += iCurrHealth;

					if (iIncapCount < 0) {
						iIncapCount = 0;
					} else if (iIncapCount > 2) {
						iIncapCount = 2;
					}

					iTotalTempHealth[iIncapCount] += iCurrTemp;
				} else if (!IsFinale) {
					iAliveCount++;
				}
			}
		}
	}

	for (int i = 0; i < 3; i++) {
		fTotalAdjustedTempHealth += iTotalTempHealth[i] * SM_fTempMulti[i];
	}

	// Total Score = Average Health points * numAlive

	// Average Health points = Total Health Points / Survivor Count
	// Total Health Points = Total Permanent Health + Total Adjusted Temp Health

	// return Average Health Points
	float fAvgHealth = (iTotalHealth + fTotalAdjustedTempHealth) / iSurvCount;
	
	if (SM_bDebugEnabled || IsDebugEnabled()) {
		LogMessage("[%s] TotalPerm: %d TotalAdjustedTemp: %.02f SurvCount: %d AliveCount: %d AvgHealth: %.02f", \
						SM_MODULE_NAME, iTotalHealth, fTotalAdjustedTempHealth, iSurvCount, iAliveCount, fAvgHealth);
	}

	return fAvgHealth;
}

/*static Action SM_Command_Say(int iClient, const char[] sCommand, int iArgc)
{
	if (iClient == 0 || !SM_bModuleIsEnabled || !IsPluginEnabled()) {
		return Plugin_Continue;
	}

	char sMessage[MAX_NAME_LENGTH];
	GetCmdArg(1, sMessage, sizeof(sMessage));

	if (strcmp(sMessage, "!health") == 0) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}*/

static int SM_CalculateSurvivalBonus()
{
	return RoundToFloor(SM_CalculateAvgHealth() * SM_fMapMulti * SM_fHBRatio + 400 * SM_fMapMulti * SM_fSurvivalBonusRatio);
}

static int SM_CalculateScore()
{
	int iAliveCount = 0;
	float fScore = SM_CalculateAvgHealth(iAliveCount);

	return RoundToFloor(fScore * SM_fMapMulti * SM_fHBRatio + 400 * SM_fMapMulti * SM_fSurvivalBonusRatio) * iAliveCount;
}

static int Native_IsScoremodEnabled(Handle plugin, int numParams)
{
	return (SM_bModuleIsEnabled && IsPluginEnabled());
}

static int Native_GetScoremodBonus(Handle plugin, int numParams)
{
	if (!SM_bModuleIsEnabled || !IsPluginEnabled()) {
		return -1;
	}

	return SM_CalculateScore();
}
