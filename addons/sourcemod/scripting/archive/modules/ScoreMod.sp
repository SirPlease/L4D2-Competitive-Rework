#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define DEBUG_SM	0

new SM_iDefaultSurvivalBonus;
new SM_iDefaultTieBreaker;
new SM_iPillPercent;
new SM_iAdrenPercent;

new Float:SM_fHealPercent;
new Float:SM_fMapMulti;
new Float:SM_fHBRatio;
new Float:SM_fSurvivalBonusRatio;
new Float:SM_fTempMulti[3];

new bool:SM_bModuleIsEnabled;
new bool:SM_bHooked = false;

// Saves first round score
new bool:SM_bIsFirstRoundOver = false;
new bool:SM_bIsSecondRoundStarted = false;
new bool:SM_bIsSecondRoundOver = false;
new SM_iFirstScore;

// Cvars
new Handle:SM_hEnable;
new Handle:SM_hHBRatio;
new Handle:SM_hSurvivalBonusRatio;
new Handle:SM_hMapMulti;
new Handle:SM_hCustomMaxDistance;

// Default Cvar Values
new Handle:SM_hSurvivalBonus;
new Handle:SM_hTieBreaker;
new Handle:SM_hHealPercent;
new Handle:SM_hPillPercent;
new Handle:SM_hAdrenPercent;
new Handle:SM_hTempMulti0;
new Handle:SM_hTempMulti1;
new Handle:SM_hTempMulti2;

public SM_OnModuleStart()
{
	SM_hEnable = CreateConVarEx("SM_enable", "1", "L4D2 Custom Scoring - Enable/Disable", CVAR_FLAGS);
	HookConVarChange(SM_hEnable, SM_ConVarChanged_Enable);
	
	SM_hHBRatio = CreateConVarEx("SM_healthbonusratio", "2.0", "L4D2 Custom Scoring - Healthbonus Multiplier", CVAR_FLAGS, true, 0.25, true, 5.0);
	HookConVarChange(SM_hHBRatio, SM_CVChanged_HealthBonusRatio);
	
	SM_hSurvivalBonusRatio = CreateConVarEx("SM_survivalbonusratio", "0.0", "Ratio to be used for a static survival bonus against Map distance. 25% == 100 points maximum health bonus on a 400 distance map", CVAR_FLAGS);
	HookConVarChange(SM_hSurvivalBonusRatio, SM_CVChanged_SurvivalBonusRatio);
	
	SM_hTempMulti0 = CreateConVarEx("SM_tempmulti_incap_0", "0.30625", "L4D2 Custom Scoring - How important temp health is on survivors who have had no incaps", CVAR_FLAGS, true, 0.0, true, 1.0);
	HookConVarChange(SM_hTempMulti0, SM_ConVarChanged_TempMulti0);
	
	SM_hTempMulti1 = CreateConVarEx("SM_tempmulti_incap_1", "0.17500", "L4D2 Custom Scoring - How important temp health is on survivors who have had one incap", CVAR_FLAGS, true, 0.0, true, 1.0);
	HookConVarChange(SM_hTempMulti1, SM_ConVarChanged_TempMulti1);
	
	SM_hTempMulti2 = CreateConVarEx("SM_tempmulti_incap_2", "0.10000", "L4D2 Custom Scoring - How important temp health is on survivors who have had two incaps (black and white)", CVAR_FLAGS, true, 0.0, true, 1.0);
	HookConVarChange(SM_hTempMulti2, SM_ConVarChanged_TempMulti2);
	
	SM_fTempMulti[0] = GetConVarFloat(SM_hTempMulti0);
	SM_fTempMulti[1] = GetConVarFloat(SM_hTempMulti1);
	SM_fTempMulti[2] = GetConVarFloat(SM_hTempMulti2);

	SM_hMapMulti = CreateConVarEx("SM_mapmulti", "1", "L4D2 Custom Scoring - Increases Healthbonus Max to Distance Max", CVAR_FLAGS);
	
	SM_hCustomMaxDistance = CreateConVarEx("SM_custommaxdistance", "0", "L4D2 Custom Scoring - Custom max distance from config", CVAR_FLAGS);
	
	SM_hSurvivalBonus = FindConVar("vs_survival_bonus");
	SM_hTieBreaker = FindConVar("vs_tiebreak_bonus");
	
	SM_hHealPercent = FindConVar("first_aid_heal_percent");
	SM_hPillPercent = FindConVar("pain_pills_health_value");
	SM_hAdrenPercent = FindConVar("adrenaline_health_buffer");
	HookConVarChange(SM_hHealPercent, SM_ConVarChanged_Health);
	HookConVarChange(SM_hPillPercent, SM_ConVarChanged_Health);
	HookConVarChange(SM_hAdrenPercent, SM_ConVarChanged_Health);
	
	SM_iDefaultSurvivalBonus = GetConVarInt(SM_hSurvivalBonus);
	SM_iDefaultTieBreaker = GetConVarInt(SM_hTieBreaker);
	SM_fHealPercent = GetConVarFloat(SM_hHealPercent);
	SM_iPillPercent = GetConVarInt(SM_hPillPercent);
	SM_iAdrenPercent = GetConVarInt(SM_hAdrenPercent);
	
	RegConsoleCmd("sm_health", SM_Cmd_Health);
}

public SM_OnModuleEnd()
{
	PluginDisable(false);
}

public SM_OnMapStart()
{
	if (!IsPluginEnabled()) return;
	
	if (!GetConVarBool(SM_hMapMulti)) SM_fMapMulti = 1.00;
	else SM_fMapMulti = float(GetMapMaxScore()) / 400.0;
	
	SM_bModuleIsEnabled = GetConVarBool(SM_hEnable);
	
	if (SM_bModuleIsEnabled && !SM_bHooked) PluginEnable();
	if (SM_bModuleIsEnabled) SetConVarInt(SM_hTieBreaker, 0);
	if (SM_bModuleIsEnabled && GetConVarBool(SM_hCustomMaxDistance) && GetCustomMapMaxScore() > -1) 
	{
		SetMapMaxScore(GetCustomMapMaxScore());
		// to allow a distance score of 0 and a health bonus
		if (GetCustomMapMaxScore() > 0) SM_fMapMulti = float(GetCustomMapMaxScore()) / 400.0;
	}
	
	SM_bIsFirstRoundOver = false;
	SM_bIsSecondRoundStarted = false;
	SM_bIsSecondRoundOver = false;
	SM_iFirstScore = 0;
	
	SM_fTempMulti[0] = GetConVarFloat(SM_hTempMulti0);
	SM_fTempMulti[1] = GetConVarFloat(SM_hTempMulti1);
	SM_fTempMulti[2] = GetConVarFloat(SM_hTempMulti2);
}

public SM_ConVarChanged_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0)
	{
		PluginDisable();
		SM_bModuleIsEnabled = false;
	}
	else
	{
		PluginEnable();
		SM_bModuleIsEnabled = true;
	}
}

public SM_ConVarChanged_TempMulti0(Handle:convar, const String:oldValue[], const String:newValue[]) SM_fTempMulti[0] = StringToFloat(newValue);
public SM_ConVarChanged_TempMulti1(Handle:convar, const String:oldValue[], const String:newValue[]) SM_fTempMulti[1] = StringToFloat(newValue);
public SM_ConVarChanged_TempMulti2(Handle:convar, const String:oldValue[], const String:newValue[]) SM_fTempMulti[2] = StringToFloat(newValue);

public SM_CVChanged_HealthBonusRatio(Handle:convar, const String:oldValue[], const String:newValue[]) SM_fHBRatio = StringToFloat(newValue);
public SM_CVChanged_SurvivalBonusRatio(Handle:convar, const String:oldValue[], const String:newValue[]) SM_fSurvivalBonusRatio = StringToFloat(newValue);

public SM_ConVarChanged_Health(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SM_fHealPercent = GetConVarFloat(SM_hHealPercent);
	SM_iPillPercent = GetConVarInt(SM_hPillPercent);
	SM_iAdrenPercent = GetConVarInt(SM_hAdrenPercent);
}

PluginEnable()
{
	HookEvent("door_close", SM_DoorClose_Event);
	HookEvent("player_death", SM_PlayerDeath_Event);
	HookEvent("round_end", SM_RoundEnd_Event);
	HookEvent("round_start", SM_RoundStart_Event);
	HookEvent("finale_vehicle_leaving", SM_FinaleVehicleLeaving_Event, EventHookMode_PostNoCopy);
	RegConsoleCmd("say", SM_Command_Say);
	RegConsoleCmd("say_team", SM_Command_Say);
	SM_fHBRatio = GetConVarFloat(SM_hHBRatio);
	SM_fSurvivalBonusRatio = GetConVarFloat(SM_hSurvivalBonusRatio);
	SM_iDefaultSurvivalBonus = GetConVarInt(SM_hSurvivalBonus);
	SM_iDefaultTieBreaker = GetConVarInt(SM_hTieBreaker);
	SetConVarInt(SM_hTieBreaker, 0);
	SM_fHealPercent = GetConVarFloat(SM_hHealPercent);
	SM_iPillPercent = GetConVarInt(SM_hPillPercent);
	SM_iAdrenPercent = GetConVarInt(SM_hAdrenPercent);
	SM_bHooked = true;
}

PluginDisable(bool:unhook=true)
{
	if(unhook)
	{
		UnhookEvent("door_close", SM_DoorClose_Event);
		UnhookEvent("player_death", SM_PlayerDeath_Event);
		UnhookEvent("round_end", SM_RoundEnd_Event, EventHookMode_PostNoCopy);
		UnhookEvent("round_start", SM_RoundStart_Event, EventHookMode_PostNoCopy);
		UnhookEvent("finale_vehicle_leaving", SM_FinaleVehicleLeaving_Event, EventHookMode_PostNoCopy);
	}
	SetConVarInt(SM_hSurvivalBonus, SM_iDefaultSurvivalBonus);
	SetConVarInt(SM_hTieBreaker, SM_iDefaultTieBreaker);
	SM_bHooked = false;
}

public Action:SM_DoorClose_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!SM_bModuleIsEnabled || !IsPluginEnabled()) return;
	if (GetEventBool(event, "checkpoint"))
	{
		SetConVarInt(SM_hSurvivalBonus, SM_CalculateSurvivalBonus());
	}
}

public Action:SM_PlayerDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!SM_bModuleIsEnabled || !IsPluginEnabled()) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	// Can't just check for fakeclient
	if(client && GetClientTeam(client) == 2)
	{
		SetConVarInt(SM_hSurvivalBonus, SM_CalculateSurvivalBonus());
	}
	
}

public Action:SM_RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!SM_bModuleIsEnabled || !IsPluginEnabled()) return;
	if(!SM_bIsFirstRoundOver) 
	{
		// First round just ended, save the current score.
		SM_bIsFirstRoundOver = true;
		decl iAliveCount;
		SM_iFirstScore = RoundToFloor(SM_CalculateAvgHealth(iAliveCount) * SM_fMapMulti * SM_fHBRatio + 400 * SM_fMapMulti * SM_fSurvivalBonusRatio * iAliveCount / 4.0);
		
		// If the score is nonzero, trust the SurvivalBonus var.
		SM_iFirstScore = (SM_iFirstScore ? GetConVarInt(SM_hSurvivalBonus) *iAliveCount : 0);
		PrintToChatAll("\x01[\x05Confogl\x01] Round 1 Bonus: \x04%d", SM_iFirstScore);
		if (GetConVarBool(SM_hCustomMaxDistance) && GetCustomMapMaxScore() > -1) PrintToChatAll("\x01[\x05Confogl\x01] Custom Max Distance: \x04%d", GetCustomMapMaxScore());
	}
	else if (SM_bIsSecondRoundStarted && !SM_bIsSecondRoundOver)
	{
		SM_bIsSecondRoundOver = true;
		// Second round has ended, print scores
		
		decl iAliveCount;
		new iScore = RoundToFloor(SM_CalculateAvgHealth(iAliveCount) * SM_fMapMulti * SM_fHBRatio + 400 * SM_fMapMulti * SM_fSurvivalBonusRatio * iAliveCount / 4.0);
		// If the score is nonzero, trust the SurvivalBonus var.
		iScore = iScore ? GetConVarInt(SM_hSurvivalBonus) * iAliveCount : 0; 
		PrintToChatAll("\x01[\x05Confogl\x01] Round 1 Bonus: \x04%d", SM_iFirstScore);
		PrintToChatAll("\x01[\x05Confogl\x01] Round 2 Bonus: \x04%d", iScore);
		if (GetConVarBool(SM_hCustomMaxDistance) && GetCustomMapMaxScore() > -1) PrintToChatAll("\x01[\x05Confogl\x01] Custom Max Distance: \x04%d", GetCustomMapMaxScore());
	}
}
public Action:SM_RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!SM_bModuleIsEnabled || !IsPluginEnabled()) return;
	if(SM_bIsFirstRoundOver) 
	{
		// Mark the beginning of the second round.
		SM_bIsSecondRoundStarted = true;
	}
}

public Action:SM_FinaleVehicleLeaving_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!SM_bModuleIsEnabled || !IsPluginEnabled()) return;
	
	SetConVarInt(SM_hSurvivalBonus, SM_CalculateSurvivalBonus());
}

SM_IsPlayerIncap(client) return GetEntProp(client, Prop_Send, "m_isIncapacitated");

public Action:SM_Cmd_Health(client, args)
{
	if (!SM_bModuleIsEnabled || !IsPluginEnabled()) return;
	
	decl iAliveCount;
	new Float:fAvgHealth = SM_CalculateAvgHealth(iAliveCount);
	
	if (SM_bIsSecondRoundStarted) PrintToChat(client, "\x01[\x05Confogl\x01] Round 1 Bonus: \x04%d", SM_iFirstScore);
	
	if (client)	PrintToChat(client, "\x01[\x05Confogl\x01] Average Health: \x04%.02f", fAvgHealth);
	else PrintToServer("[Confogl] Average Health: %.02f", fAvgHealth);
	
	new iScore = RoundToFloor(fAvgHealth * SM_fMapMulti * SM_fHBRatio) * iAliveCount ;
	
	if(DEBUG_SM || IsDebugEnabled())
		LogMessage("[ScoreMod] CalcScore: %d MapMulti: %.02f Multiplier %.02f", iScore, SM_fMapMulti, SM_fHBRatio);
		
	if (client)
	{
		PrintToChat(client, "\x01[\x05Confogl\x01] Health Bonus: \x04%d", iScore );
		if (SM_fSurvivalBonusRatio != 0.0) PrintToChat(client, "\x01[\x05Confogl\x01] Static Survival Bonus Per Survivor: \x04%d", RoundToFloor(400 * SM_fMapMulti * SM_fSurvivalBonusRatio));
		if (GetConVarBool(SM_hCustomMaxDistance) && GetCustomMapMaxScore() > -1) PrintToChat(client, "\x01[\x05Confogl\x01] Custom Max Distance: \x04%d", GetCustomMapMaxScore());
	}
	else
	{
		PrintToServer("[Confogl] Health Bonus: %d", iScore );
		if (SM_fSurvivalBonusRatio != 0.0) PrintToServer("[Confogl] Static Survival Bonus Per Survivor: %d", RoundToFloor(400 * SM_fMapMulti * SM_fSurvivalBonusRatio));
		if (GetConVarBool(SM_hCustomMaxDistance) && GetCustomMapMaxScore() > -1) PrintToServer("[Confogl] Custom Max Distance: %d", GetCustomMapMaxScore());
	}

	
}

stock SM_CalculateSurvivalBonus()
{
	return RoundToFloor(SM_CalculateAvgHealth() * SM_fMapMulti * SM_fHBRatio + 400 * SM_fMapMulti * SM_fSurvivalBonusRatio);
}

stock SM_CalculateScore()
{
	decl iAliveCount;
	new Float:fScore = SM_CalculateAvgHealth(iAliveCount);
	return RoundToFloor(fScore * SM_fMapMulti * SM_fHBRatio + 400 * SM_fMapMulti * SM_fSurvivalBonusRatio) * iAliveCount;
}

stock Float:SM_CalculateAvgHealth(&iAliveCount=0)
{
	new iTotalHealth;
	new iTotalTempHealth[3];
	
	new Float:fTotalAdjustedTempHealth;
	new bool:IsFinale = IsMapFinale();
	// Temporary Storage Variables for inventory
	new iTemp;
	new iCurrHealth;
	new iCurrTemp;
	new iIncapCount;
	decl String:strTemp[50];
	
	new iSurvCount;
	iAliveCount =0;
		
	for (new index = 1; index <= MaxClients; index++)
	{
		if (IsSurvivor(index))
		{
			iSurvCount++;
			if (IsPlayerAlive(index))
			{
			
				if (!SM_IsPlayerIncap(index))
				{
					// Get Main health stats
					iCurrHealth = GetSurvivorPermanentHealth(index);
					
					iCurrTemp = GetSurvivorTempHealth(index);
					
					iIncapCount = GetSurvivorIncapCount(index);
					
					// Adjust for kits
					iTemp = GetPlayerWeaponSlot(index, 3);
					if (iTemp > -1)
					{
						GetEdictClassname(iTemp, strTemp, sizeof(strTemp));
						if (StrEqual(strTemp, "weapon_first_aid_kit"))
						{
							iCurrHealth = RoundToFloor(iCurrHealth + ((100 - iCurrHealth) * SM_fHealPercent));
							iCurrTemp = 0;
							iIncapCount = 0;
						}
					}
					// Adjust for pills/adrenaline
					iTemp = GetPlayerWeaponSlot(index, 4);
					if (iTemp > -1)
					{
						GetEdictClassname(iTemp, strTemp, sizeof(strTemp));
						if (StrEqual(strTemp, "weapon_pain_pills")) iCurrTemp += SM_iPillPercent;
						else if (StrEqual(strTemp, "weapon_adrenaline")) iCurrTemp += SM_iAdrenPercent;
					}
					// Enforce max 100 total health points 
					if ((iCurrTemp + iCurrHealth) > 100) iCurrTemp = 100 - iCurrHealth;
					iAliveCount++;
					
					iTotalHealth += iCurrHealth;
					if (iIncapCount < 0 ) { iIncapCount = 0; } else if (iIncapCount > 2 ) { iIncapCount = 2; }
					iTotalTempHealth[iIncapCount] += iCurrTemp;
				}
				else if (!IsFinale) iAliveCount++;
			}
		}
	}
	
	for (new i; i < 3; i++) fTotalAdjustedTempHealth += iTotalTempHealth[i] * SM_fTempMulti[i];
	
	// Total Score = Average Health points * numAlive
	
	// Average Health points = Total Health Points / Survivor Count
	// Total Health Points = Total Permanent Health + Total Adjusted Temp Health
	
	// return Average Health Points
	new Float:fAvgHealth  = (iTotalHealth + fTotalAdjustedTempHealth) / iSurvCount; 
	
	#if DEBUG_SM
		LogMessage("[ScoreMod] TotalPerm: %d TotalAdjustedTemp: %.02f SurvCount: %d AliveCount: %d AvgHealth: %.02f", 
			iTotalHealth, fTotalAdjustedTempHealth, iSurvCount, iAliveCount, fAvgHealth);
	#endif
			
	return fAvgHealth;
}

public Action:SM_Command_Say(client, args)
{
	if (!SM_bModuleIsEnabled || !IsPluginEnabled()) return Plugin_Continue;
	
	decl String:sMessage[MAX_NAME_LENGTH];
	GetCmdArg(1, sMessage, sizeof(sMessage));
	
	if (StrEqual(sMessage, "!health")) return Plugin_Handled;
	
	return Plugin_Continue;
}
