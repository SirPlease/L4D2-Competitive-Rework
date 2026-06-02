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
	version		= "1.16",
	description	= "Blocks instant repounces and gives m2 penalty after a shove/deadstop",
	url 		= "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	HookEvent("player_shoved", Event_PlayerShoved);
	
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

void Event_PlayerShoved(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int shover = GetClientOfUserId(hEvent.GetInt("attacker"));
	if (!IsSurvivor(shover)) {
		return;
	}
	
	if (GetEntProp(shover, Prop_Send, "m_bAdrenalineActive")) {
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
	
	int penaltyIncrease;
	switch (GetInfectedClass(shovee)) {
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
	int penalty = GetEntProp(shover, Prop_Send, "m_iShovePenalty");

	penalty += penaltyIncrease;
	if (penalty > maxPenalty) {
		penalty = maxPenalty;
	}

	float fAttackStartTime = GetEntPropFloat(shover_weapon, Prop_Send, "m_attackTimer", 1) - GetEntPropFloat(shover_weapon, Prop_Send, "m_attackTimer", 0);
	float eps = GetGameTime() - fAttackStartTime;
	
	SetEntProp(shover, Prop_Send, "m_iShovePenalty", penalty);
	SetEntPropFloat(shover, Prop_Send, "m_flNextShoveTime", CalcNextShoveTime(penalty, minPenalty, maxPenalty) - eps);
}

float g_flStaggerEndTime;
public Action L4D_OnCancelStagger(int client)
{
	g_flStaggerEndTime = GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1);
	if (g_flStaggerEndTime <= 0.0 || g_flStaggerEndTime <= GetGameTime())
		g_flStaggerEndTime = -1.0;
	
	return Plugin_Continue;
}

public void L4D_OnCancelStagger_Post(int client)
{
	if (IsInfected(client) && IsPlayerAlive(client) && !L4D_IsPlayerGhost(client))
	{
		float recharge = -1.0;
		bool bAttacking = false;
		switch (GetInfectedClass(client))
		{
			case L4D2Infected_Hunter: {
				recharge = hPounceCrouchDelayCvar.FloatValue;
				bAttacking = GetEntPropEnt(client, Prop_Send, "m_pounceVictim") != -1;
			}
			case L4D2Infected_Jockey: {
				recharge = hLeapIntervalCvar.FloatValue;
				bAttacking = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim") != -1;

				if (g_flStaggerEndTime != -1.0)
					recharge += g_flStaggerEndTime - GetGameTime();
			}
			default: {
				return;
			}
		}
		
		if (recharge != -1.0 && !bAttacking)
		{
			int ability = GetInfectedAbilityEntity(client);
			if (ability != -1) {
				float fNext = GetGameTime() + recharge;
				float timestamp = GetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", 1);
				if (fNext > timestamp) {
					SetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", recharge, 0);
					SetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", fNext, 1);
				}
			}
		}
	}
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
