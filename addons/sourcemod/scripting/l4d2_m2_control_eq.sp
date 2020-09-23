#pragma semicolon 1

#define L4D2UTIL_STOCKS_ONLY

#include <sourcemod>
#include <l4d2util>
#include <left4dhooks>

// The z_gun_swing_vs_amt_penalty cvar is the amount of cooldown time you get
// when you are on your maximum m2 penalty. However, whilst testing I found that
// a magic number of ~0.7s was always added to this.
#define COOLDOWN_EXTRA_TIME 0.7

// Sometimes the ability timer doesn't get reset if the timer interval is the
// stagger time. Use an epsilon to set it slightly before the stagger is over.
#define STAGGER_TIME_EPS 0.1

new Handle:hMaxShovePenaltyCvar;
new Handle:hShovePenaltyAmtCvar;
new Handle:hPounceCrouchDelayCvar;
new Handle:hMaxStaggerDurationCvar;
new Handle:hLeapIntervalCvar;
new Handle:hPenaltyIncreaseHunterCvar;
new Handle:hPenaltyIncreaseJockeyCvar;
new Handle:hPenaltyIncreaseSmokerCvar;

new bool:g_NoHunterM2 = false;

public Plugin:myinfo =
{
	name        = "L4D2 M2 Control",
	author      = "Jahze, Visor",
	version     = "1.5",
	description = "Blocks instant repounces and gives m2 penalty after a shove/deadstop",
	url 		= "https://github.com/Attano/Equilibrium"
}

public OnPluginStart()
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

public OnAllPluginsLoaded()
{
	g_NoHunterM2 = (FindPluginByFile("optional/l4d2_no_hunter_deadstops.smx") != INVALID_HANDLE);
}

public Action:OutSkilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new shovee = GetClientOfUserId(GetEventInt(event, "userid"));
	new shover = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!IsSurvivor(shover) || !IsInfected(shovee))
	{
		return;
	}

	new penaltyIncrease;
	new L4D2_Infected:zClass = GetInfectedClass(shovee);
	if (zClass == L4D2Infected_Hunter)
	{
		penaltyIncrease = GetConVarInt(hPenaltyIncreaseHunterCvar);
	}
	else if (zClass == L4D2Infected_Jockey)
	{
		penaltyIncrease = GetConVarInt(hPenaltyIncreaseJockeyCvar);
	}
	else if (zClass == L4D2Infected_Smoker)
	{
		penaltyIncrease = GetConVarInt(hPenaltyIncreaseSmokerCvar);
	}
	else
	{
		return;
	}
	
	new maxPenalty = GetConVarInt(hMaxShovePenaltyCvar);
	new penalty = L4D2Direct_GetShovePenalty(shover);

	penalty += penaltyIncrease;
	if (penalty > maxPenalty)
	{
		penalty = maxPenalty;
	}

	L4D2Direct_SetShovePenalty(shover, penalty);
	L4D2Direct_SetNextShoveTime(shover, CalcNextShoveTime(penalty, maxPenalty));

	if (zClass == L4D2Infected_Smoker || (zClass == L4D2Infected_Hunter && g_NoHunterM2))
	{
		return;
	}
	
	new Float:staggerTime = GetConVarFloat(hMaxStaggerDurationCvar);
	CreateTimer(staggerTime - STAGGER_TIME_EPS, ResetAbilityTimer, shovee);
}

public Action:ResetAbilityTimer(Handle:event, any:shovee)
{
	new Float:time = GetGameTime();
	new L4D2_Infected:zClass = GetInfectedClass(shovee);
	new Float:recharge;

	if (zClass == L4D2Infected_Hunter)
	{
		recharge = GetConVarFloat(hPounceCrouchDelayCvar);
	}
	else
	{
		recharge = GetConVarFloat(hLeapIntervalCvar);
	}

	new Float:timestamp;
	new Float:duration;
	if (!GetInfectedAbilityTimer(shovee, timestamp, duration))
	{
		return;
	}

	duration = time + recharge + STAGGER_TIME_EPS;
	if (duration > timestamp)
	{
		SetInfectedAbilityTimer(shovee, duration, recharge);
	}
}

static Float:CalcNextShoveTime(penalty, max)
{
	new Float:time = GetGameTime();
	new Float:maxPenalty = float(max);
	new Float:currentPenalty = float(penalty);
	new Float:ratio = currentPenalty/maxPenalty;
	new Float:maxTime = GetConVarFloat(hShovePenaltyAmtCvar);

	return time + ratio*maxTime + COOLDOWN_EXTRA_TIME;
}