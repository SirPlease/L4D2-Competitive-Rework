#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <l4d2lib>
#define REQUIRE_PLUGIN
#include <colors>

#define DEBUG_SM	0

public Plugin myinfo =
{
	name = "L4D2 Scoremod",
	author = "CanadaRox, ProdigySim",
	description = "L4D2 Custom Scoring System (Health Bonus)",
	version = "1.1.2",
	url = "https://bitbucket.org/CanadaRox/random-sourcemod-stuff"
};

new bool:l4d2lib_available = false;

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

// Score Difference
new iDifference;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("HealthBonus", _Native_HealthBonus);
	
	RegPluginLibrary("l4d2_scoremod");
	return APLRes_Success;
}

public int _Native_HealthBonus(Handle plugin, int numParams)
{
	return SM_CalculateSurvivalBonus();
}

public OnPluginStart()
{
	SM_hEnable = CreateConVar("SM_enable", "1", "L4D2 Custom Scoring - Enable/Disable", FCVAR_NONE);
	HookConVarChange(SM_hEnable, SM_ConVarChanged_Enable);
	
	SM_hHBRatio = CreateConVar("SM_healthbonusratio", "2.0", "L4D2 Custom Scoring - Healthbonus Multiplier", FCVAR_NONE, true, 0.25, true, 5.0);
	HookConVarChange(SM_hHBRatio, SM_CVChanged_HealthBonusRatio);
	
	SM_hSurvivalBonusRatio = CreateConVar("SM_survivalbonusratio", "0.0", "Ratio to be used for a static survival bonus against Map distance. 25% == 100 points maximum health bonus on a 400 distance map", FCVAR_NONE);
	HookConVarChange(SM_hSurvivalBonusRatio, SM_CVChanged_SurvivalBonusRatio);
	
	SM_hTempMulti0 = CreateConVar("SM_tempmulti_incap_0", "0.30625", "L4D2 Custom Scoring - How important temp health is on survivors who have had no incaps", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(SM_hTempMulti0, SM_ConVarChanged_TempMulti0);
	
	SM_hTempMulti1 = CreateConVar("SM_tempmulti_incap_1", "0.17500", "L4D2 Custom Scoring - How important temp health is on survivors who have had one incap", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(SM_hTempMulti1, SM_ConVarChanged_TempMulti1);
	
	SM_hTempMulti2 = CreateConVar("SM_tempmulti_incap_2", "0.10000", "L4D2 Custom Scoring - How important temp health is on survivors who have had two incaps (black and white)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(SM_hTempMulti2, SM_ConVarChanged_TempMulti2);
	
	SM_fTempMulti[0] = GetConVarFloat(SM_hTempMulti0);
	SM_fTempMulti[1] = GetConVarFloat(SM_hTempMulti1);
	SM_fTempMulti[2] = GetConVarFloat(SM_hTempMulti2);

	decl String:buf[32];
	FloatToString(GetConVarFloat(FindConVar("first_aid_heal_percent")), buf, sizeof(buf));
	SM_hHealPercent = CreateConVar("SM_first_aid_heal_percent", buf, "L4D2 Custom Scoring: What percent of health is healed by medkits?");
	IntToString(GetConVarInt(FindConVar("pain_pills_health_value")), buf, sizeof(buf));
	SM_hPillPercent = CreateConVar("SM_pain_pills_health_value", buf, "L4D2 Custom Scoring: How much health is added by pills?");
	IntToString(GetConVarInt(FindConVar("adrenaline_health_buffer")), buf, sizeof(buf));
	SM_hAdrenPercent = CreateConVar("SM_adrenaline_health_buffer", buf, "L4D2 Custom Scoring: How much health is added by adrenaline?");

	SM_hMapMulti = CreateConVar("SM_mapmulti", "1", "L4D2 Custom Scoring - Increases Healthbonus Max to Distance Max", FCVAR_NONE);
	
	SM_hCustomMaxDistance = CreateConVar("SM_custommaxdistance", "0", "L4D2 Custom Scoring - Custom max distance from config", FCVAR_NONE);
	
	SM_hSurvivalBonus = FindConVar("vs_survival_bonus");
	SM_hTieBreaker = FindConVar("vs_tiebreak_bonus");
	
	HookConVarChange(SM_hHealPercent, SM_ConVarChanged_Health);
	HookConVarChange(SM_hPillPercent, SM_ConVarChanged_Health);
	HookConVarChange(SM_hAdrenPercent, SM_ConVarChanged_Health);
	
	SM_iDefaultSurvivalBonus = GetConVarInt(SM_hSurvivalBonus);
	SM_iDefaultTieBreaker = GetConVarInt(SM_hTieBreaker);
	SM_fHealPercent = GetConVarFloat(SM_hHealPercent);
	SM_iPillPercent = GetConVarInt(SM_hPillPercent);
	SM_iAdrenPercent = GetConVarInt(SM_hAdrenPercent);
	
	RegConsoleCmd("sm_health", SM_Cmd_Health);
	
	l4d2lib_available = LibraryExists("l4d2lib");
	
}
 
public OnLibraryRemoved(const String:name[])
{
	if (strcmp(name, "l4d2lib") == 0)
	{
		l4d2lib_available = false;
	}
}
 
public OnLibraryAdded(const String:name[])
{
	if (strcmp(name, "l4d2lib") == 0)
	{
		l4d2lib_available = true;
	}
}

public OnPluginEnd()
{
	PluginDisable();
}

public OnMapStart()
{
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
		return;
	}

	PluginEnable();
	SM_bModuleIsEnabled = true;
}

public SM_ConVarChanged_TempMulti0(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SM_fTempMulti[0] = StringToFloat(newValue);
}

public SM_ConVarChanged_TempMulti1(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SM_fTempMulti[1] = StringToFloat(newValue);
}

public SM_ConVarChanged_TempMulti2(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SM_fTempMulti[2] = StringToFloat(newValue);
}

public SM_CVChanged_HealthBonusRatio(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SM_fHBRatio = StringToFloat(newValue);
}

public SM_CVChanged_SurvivalBonusRatio(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SM_fSurvivalBonusRatio = StringToFloat(newValue);
}

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

PluginDisable()
{
	SetConVarInt(SM_hSurvivalBonus, SM_iDefaultSurvivalBonus);
	SetConVarInt(SM_hTieBreaker, SM_iDefaultTieBreaker);
	SM_bHooked = false;
}

public Action:SM_DoorClose_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!SM_bModuleIsEnabled) return;
	if (GetEventBool(event, "checkpoint"))
	{
		SetConVarInt(SM_hSurvivalBonus, SM_CalculateSurvivalBonus());
	}
}

public Action:SM_PlayerDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!SM_bModuleIsEnabled) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	// Can't just check for fakeclient
	if(client && GetClientTeam(client) == 2)
	{
		SetConVarInt(SM_hSurvivalBonus, SM_CalculateSurvivalBonus());
	}
	
}

public Action:SM_RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!SM_bModuleIsEnabled) return;
	if(!SM_bIsFirstRoundOver) 
	{
		// First round just ended, save the current score.
		SM_bIsFirstRoundOver = true;
		decl iAliveCount;
		SM_iFirstScore = RoundToFloor(SM_CalculateAvgHealth(iAliveCount) * SM_fMapMulti * SM_fHBRatio + 400 * SM_fMapMulti * SM_fSurvivalBonusRatio);
		
		// If the score is nonzero, trust the SurvivalBonus var.
		SM_iFirstScore = (SM_iFirstScore ? GetConVarInt(SM_hSurvivalBonus) *iAliveCount : 0);
		CPrintToChatAll("{blue}[{default}!{blue}] {default}Round {blue}1 {default}Bonus: {olive}%d", SM_iFirstScore);
		if (GetConVarBool(SM_hCustomMaxDistance) && GetCustomMapMaxScore() > -1) CPrintToChatAll("{blue}[{default}!{blue}] {default}Custom Max Distance: {olive}%d", GetCustomMapMaxScore());
	}
	else if (SM_bIsSecondRoundStarted && !SM_bIsSecondRoundOver)
	{
		SM_bIsSecondRoundOver = true;
		// Second round has ended, print scores
		
		decl iAliveCount;
		new iScore = RoundToFloor(SM_CalculateAvgHealth(iAliveCount) * SM_fMapMulti * SM_fHBRatio + 400 * SM_fMapMulti * SM_fSurvivalBonusRatio);
		// If the score is nonzero, trust the SurvivalBonus var.
		iScore = iScore ? GetConVarInt(SM_hSurvivalBonus) * iAliveCount : 0; 
		CPrintToChatAll("{blue}[{default}!{blue}] {default}Round {blue}1 {default}Bonus: {olive}%d", SM_iFirstScore);
		CPrintToChatAll("{blue}[{default}!{blue}] {default}Round {blue}2 {default}Bonus: {olive}%d", iScore);
		iDifference = SM_iFirstScore - iScore;
		if (iScore > SM_iFirstScore) iDifference = (~iDifference) + 1;
		CPrintToChatAll("{red}[{default}!{red}] {default}Difference: {olive}%d", iDifference);
		if (GetConVarBool(SM_hCustomMaxDistance) && GetCustomMapMaxScore() > -1) CPrintToChatAll("{blue}[{default}!{blue}] {default}Custom Max Distance: {olive}%d", GetCustomMapMaxScore());
	}
}
public Action:SM_RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!SM_bModuleIsEnabled) return;
	if(SM_bIsFirstRoundOver) 
	{
		// Mark the beginning of the second round.
		SM_bIsSecondRoundStarted = true;
	}
}

public Action:SM_FinaleVehicleLeaving_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!SM_bModuleIsEnabled) return;
	
	SetConVarInt(SM_hSurvivalBonus, SM_CalculateSurvivalBonus());
}

bool:SM_IsPlayerIncap(client) 
{
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0);
}

public Action:SM_Cmd_Health(client, args)
{
	if (!SM_bModuleIsEnabled) return;
	
	decl iAliveCount;
	new Float:fAvgHealth = SM_CalculateAvgHealth(iAliveCount);	
	
	new iScore = RoundToFloor(fAvgHealth * SM_fMapMulti * SM_fHBRatio) * iAliveCount ;
	
	if (SM_bIsSecondRoundStarted)
    {
		iDifference = SM_iFirstScore - iScore;
		if (iScore > SM_iFirstScore) iDifference = (~iDifference) + 1;
		CPrintToChat(client, "{blue}[{default}!{blue}] {default}Round {blue}1 {default}Bonus: {olive}%d {default}({green}Difference: {olive}%d{default})", SM_iFirstScore, iDifference);
	}
	
	#if DEBUG_SM
		LogMessage("[ScoreMod] CalcScore: %d MapMulti: %.02f Multiplier %.02f", iScore, SM_fMapMulti, SM_fHBRatio);
	#endif
	
	if (client)
	{
		CPrintToChat(client, "{blue}[{default}!{blue}] {default}Health Bonus: {olive}%d", iScore );
	}
	else
	{
		PrintToServer("[ScoreMod] Health Bonus: %d", iScore );
	}

	if (GetConVarBool(SM_hCustomMaxDistance) && GetCustomMapMaxScore() > -1) {
		if (client) {
			CPrintToChat(client, "{blue}[{default}!{blue}] {default}Custom Max Distance: {olive}%d", GetCustomMapMaxScore());
		}
		else {
			PrintToServer("[ScoreMod] Custom Max Distance: %d", GetCustomMapMaxScore());
		}
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
	new bool:IsFinale = L4D_IsMissionFinalMap();
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
	if (!SM_bModuleIsEnabled) return Plugin_Continue;
	
	decl String:sMessage[MAX_NAME_LENGTH];
	GetCmdArg(1, sMessage, sizeof(sMessage));
	
	if (StrEqual(sMessage, "!health")) return Plugin_Handled;
	
	return Plugin_Continue;
}

stock bool:IsSurvivor(client)
{
	return IsClientInGame(client) && GetClientTeam(client) == 2;
}

stock GetSurvivorPermanentHealth(client)
{
    return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock GetSurvivorTempHealth(client)
{
	new temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
	return (temphp > 0 ? temphp : 0);
}

stock GetSurvivorIncapCount(client)
{
    return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}

stock GetCustomMapMaxScore()
{
	return l4d2lib_available ? L4D2_GetMapValueInt("max_distance", -1) : -1;
}

stock GetMapMaxScore()
{
	return L4D_GetVersusMaxCompletionScore();
}

stock SetMapMaxScore(score)
{
	L4D_SetVersusMaxCompletionScore(score);
}