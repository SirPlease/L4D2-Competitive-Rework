#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>
#include <left4dhooks>

// The z_gun_swing_vs_amt_penalty cvar is the amount of cooldown time you get
// when you are on your maximum m2 penalty. However, whilst testing I found that
// a magic number of ~0.7s was always added to this.
//
// @Forgetest: nah just "z_gun_swing_interval"
//#define COOLDOWN_EXTRA_TIME 0.7

// Sometimes the ability timer doesn't get reset if the timer interval is the
// stagger time. Use an epsilon to set it slightly before the stagger is over.
//#define STAGGER_TIME_EPS 0.1

ConVar 
	hMinShovePenaltyCvar,
	hMaxShovePenaltyCvar,
	hShoveIntervalCvar,
	hShovePenaltyAmtCvar,
	hPounceCrouchDelayCvar,
	hLeapIntervalCvar,
	hPenaltyIncreaseHunterCvar,
	hPenaltyIncreaseJockeyCvar,
	hPenaltyIncreaseSmokerCvar;

public Plugin myinfo =
{
	name		= "L4D2 M2 Control",
	author		= "Jahze, Visor, A1m`, Forgetest",
	version		= "1.8",
	description	= "Blocks instant repounces and gives m2 penalty after a shove/deadstop",
	url 		= "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	HookEvent("player_shoved", OutSkilled);
	
	L4D_OnGameModeChange(L4D_GetGameModeType());
	
	hShoveIntervalCvar = FindConVar("z_gun_swing_interval");
	hShovePenaltyAmtCvar = FindConVar("z_gun_swing_vs_amt_penalty");
	hPounceCrouchDelayCvar = FindConVar("z_pounce_crouch_delay");
	hLeapIntervalCvar = FindConVar("z_leap_interval");

	hPenaltyIncreaseHunterCvar = CreateConVar("l4d2_m2_hunter_penalty", "0", "How much penalty gets added when you shove a Hunter");
	hPenaltyIncreaseJockeyCvar = CreateConVar("l4d2_m2_jockey_penalty", "0", "How much penalty gets added when you shove a Jockey");
	hPenaltyIncreaseSmokerCvar = CreateConVar("l4d2_m2_smoker_penalty", "0", "How much penalty gets added when you shove a Smoker");
}

public void L4D_OnGameModeChange(int gamemode)
{
	switch (gamemode)
	{
		case GAMEMODE_COOP, GAMEMODE_SURVIVAL:
		{
			hMinShovePenaltyCvar = FindConVar("z_gun_swing_coop_min_penalty");
			hMaxShovePenaltyCvar = FindConVar("z_gun_swing_coop_max_penalty");
		}
		case GAMEMODE_SCAVENGE, GAMEMODE_VERSUS:
		{
			hMinShovePenaltyCvar = FindConVar("z_gun_swing_vs_min_penalty");
			hMaxShovePenaltyCvar = FindConVar("z_gun_swing_vs_max_penalty");
		}
	}
}

public void OutSkilled(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int shover = GetClientOfUserId(hEvent.GetInt("attacker"));
	if (!IsSurvivor(shover)) {
		return;
	}
	
	int shover_weapon = GetEntPropEnt(shover, Prop_Send, "m_hActiveWeapon");
	if (shover_weapon == -1) {
		return;
	}
	
	int shovee_userid = hEvent.GetInt("userid");
	int shovee = GetClientOfUserId(shovee_userid);
	if (!IsInfected(shovee)) {
		return;
	}
	
	int penaltyIncrease, zClass = GetInfectedClass(shovee);
	switch (zClass) {
		case L4D2Infected_Hunter: {
			penaltyIncrease = hPenaltyIncreaseHunterCvar.IntValue;
		}
		case L4D2Infected_Jockey: {
			penaltyIncrease = hPenaltyIncreaseJockeyCvar.IntValue;
		}
		case L4D2Infected_Smoker: {
			penaltyIncrease = hPenaltyIncreaseSmokerCvar.IntValue;
		}
		default: {
			return;
		}
	}

	int minPenalty = hMinShovePenaltyCvar.IntValue;
	int maxPenalty = hMaxShovePenaltyCvar.IntValue;
	int penalty = L4D2Direct_GetShovePenalty(shover);

	penalty += penaltyIncrease;
	if (penalty > maxPenalty) {
		penalty = maxPenalty;
	}

	float fAttackStartTime = GetEntPropFloat(shover_weapon, Prop_Send, "m_attackTimer", 1) - GetEntPropFloat(shover_weapon, Prop_Send, "m_attackTimer", 0);
	float eps = GetGameTime() - fAttackStartTime;
	
	L4D2Direct_SetShovePenalty(shover, penalty);
	L4D2Direct_SetNextShoveTime(shover, CalcNextShoveTime(penalty, minPenalty, maxPenalty) - eps);
	
	if (zClass != L4D2Infected_Smoker) {
		CreateTimer(0.1, ResetAbilityTimer, shovee_userid, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
}

public Action ResetAbilityTimer(Handle hTimer, any shovee_userid)
{
	int shovee = GetClientOfUserId(shovee_userid);
	if (shovee > 0 && GetInfectedAbilityEntity(shovee) != -1) {
		float timestamp = GetEntPropFloat(shovee, Prop_Send, "m_staggerTimer", 1);
		if (timestamp == -1.0) {
			return Plugin_Continue;
		}
		
		float recharge = (GetInfectedClass(shovee) == L4D2Infected_Hunter) ? hPounceCrouchDelayCvar.FloatValue : hLeapIntervalCvar.FloatValue;
		
		float new_timestamp = timestamp + recharge;
		if (new_timestamp > timestamp) {
			SetInfectedAbilityTimer(shovee, new_timestamp, recharge);
		}
	}

	return Plugin_Stop;
}

float CalcNextShoveTime(int currentPenalty, int minPenalty, int maxPenalty)
{
	float ratio = 0.0;
	if (currentPenalty >= minPenalty)
	{
		ratio = L4D2Util_ClampFloat(float(currentPenalty - minPenalty) / float(maxPenalty - minPenalty), 0.0, 1.0);
	}
	float fDuration = ratio * hShovePenaltyAmtCvar.FloatValue;
	float fReturn = GetGameTime() + fDuration + hShoveIntervalCvar.FloatValue;

	return fReturn;
}
