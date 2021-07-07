#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>
#include <left4dhooks>

// The z_gun_swing_vs_amt_penalty cvar is the amount of cooldown time you get
// when you are on your maximum m2 penalty. However, whilst testing I found that
// a magic number of ~0.7s was always added to this.
#define COOLDOWN_EXTRA_TIME 0.7

// Sometimes the ability timer doesn't get reset if the timer interval is the
// stagger time. Use an epsilon to set it slightly before the stagger is over.
#define STAGGER_TIME_EPS 0.1

ConVar 
	hMaxShovePenaltyCvar,
	hShovePenaltyAmtCvar,
	hPounceCrouchDelayCvar,
	hMaxStaggerDurationCvar,
	hLeapIntervalCvar,
	hPenaltyIncreaseHunterCvar,
	hPenaltyIncreaseJockeyCvar,
	hPenaltyIncreaseSmokerCvar;

bool
	g_NoHunterM2 = false;

public Plugin myinfo =
{
	name		= "L4D2 M2 Control",
	author		= "Jahze, Visor", //update syntax, minor fixes A1m`
	version		= "1.7",
	description	= "Blocks instant repounces and gives m2 penalty after a shove/deadstop",
	url 		= "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	HookEvent("player_shoved", OutSkilled);
	
	hMaxShovePenaltyCvar = FindConVar("z_gun_swing_vs_max_penalty");
	hShovePenaltyAmtCvar = FindConVar("z_gun_swing_vs_amt_penalty");
	hPounceCrouchDelayCvar = FindConVar("z_pounce_crouch_delay");
	hMaxStaggerDurationCvar = FindConVar("z_max_stagger_duration");
	hLeapIntervalCvar = FindConVar("z_leap_interval");

	hPenaltyIncreaseHunterCvar = CreateConVar("l4d2_m2_hunter_penalty", "0", "How much penalty gets added when you shove a Hunter");
	hPenaltyIncreaseJockeyCvar = CreateConVar("l4d2_m2_jockey_penalty", "0", "How much penalty gets added when you shove a Jockey");
	hPenaltyIncreaseSmokerCvar = CreateConVar("l4d2_m2_smoker_penalty", "0", "How much penalty gets added when you shove a Smoker");
}

public void OnAllPluginsLoaded()
{
	g_NoHunterM2 = (FindPluginByFile("optional/l4d2_no_hunter_deadstops.smx") != null);
}

public void OutSkilled(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int shover = GetClientOfUserId(hEvent.GetInt("attacker"));
	if (!IsSurvivor(shover)) {
		return;
	}
	
	int shovee_userid = hEvent.GetInt("userid");
	int shovee = GetClientOfUserId(shovee_userid);
	if (!IsInfected(shovee)) {
		return;
	}
	
	int penaltyIncrease;
	L4D2_Infected zClass = GetInfectedClass(shovee);
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

	int maxPenalty = hMaxShovePenaltyCvar.IntValue;
	int penalty = L4D2Direct_GetShovePenalty(shover);

	penalty += penaltyIncrease;
	if (penalty > maxPenalty) {
		penalty = maxPenalty;
	}

	L4D2Direct_SetShovePenalty(shover, penalty);
	L4D2Direct_SetNextShoveTime(shover, CalcNextShoveTime(penalty, maxPenalty));

	if (zClass == L4D2Infected_Smoker 
	|| (zClass == L4D2Infected_Hunter && g_NoHunterM2)) {
		return;
	}
	
	float staggerTime = hMaxStaggerDurationCvar.FloatValue - STAGGER_TIME_EPS;
	CreateTimer(staggerTime, ResetAbilityTimer, shovee_userid, TIMER_FLAG_NO_MAPCHANGE);
}

public Action ResetAbilityTimer(Handle hTimer, any shovee_userid)
{
	int shovee = GetClientOfUserId(shovee_userid);
	if (shovee > 0) {
		float recharge = (GetInfectedClass(shovee) == L4D2Infected_Hunter) ? hPounceCrouchDelayCvar.FloatValue : hLeapIntervalCvar.FloatValue;
		
		float timestamp, duration;
		if (!GetInfectedAbilityTimer(shovee, timestamp, duration)) {
			return;
		}

		duration = GetGameTime() + recharge + STAGGER_TIME_EPS;
		if (duration > timestamp) {
			SetInfectedAbilityTimer(shovee, duration, recharge);
		}
	}
}

float CalcNextShoveTime(int currentPenalty, int maxPenalty)
{
	float ratio = float(currentPenalty) / float(maxPenalty);
	float fDuration = ratio * hShovePenaltyAmtCvar.FloatValue;
	float fReturn = GetGameTime() + fDuration + COOLDOWN_EXTRA_TIME;

	return fReturn;
}
