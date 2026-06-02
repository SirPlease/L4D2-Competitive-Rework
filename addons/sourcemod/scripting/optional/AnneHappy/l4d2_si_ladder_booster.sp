#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.3.3"
#define TEAM_INFECTED 3
#define NORMAL_SPEED 1.0

ConVar g_cvAiLadderBoost;
ConVar g_cvPzLadderBoost;
ConVar g_cvBoostMultiplier;

bool g_bAiLadderBoost;
bool g_bPzLadderBoost;
float g_fBoostMultiplier;

public Plugin myinfo =
{
	name = "L4D2 SI LADDER BOOSTER",
	author = "AiMee",
	description = "",
	version = PLUGIN_VERSION,
	url = "233"
};

public void OnPluginStart()
{
	g_cvAiLadderBoost = CreateConVar("l4d2_ai_ladder_boost", "1", "", FCVAR_SPONLY, true, 0.0, true, 1.0);
	g_cvPzLadderBoost = CreateConVar("l4d2_pz_ladder_boost", "0", "", FCVAR_SPONLY, true, 0.0, true, 1.0);
	g_cvBoostMultiplier = CreateConVar("l4d2_boost_multiplier", "3.2", "", FCVAR_SPONLY, true, 0.0, true, 10.0);

	g_cvAiLadderBoost.AddChangeHook(OnConVarChanged);
	g_cvPzLadderBoost.AddChangeHook(OnConVarChanged);
	g_cvBoostMultiplier.AddChangeHook(OnConVarChanged);

	GetCvars();
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bAiLadderBoost = g_cvAiLadderBoost.BoolValue;
	g_bPzLadderBoost = g_cvPzLadderBoost.BoolValue;
	g_fBoostMultiplier = g_cvBoostMultiplier.FloatValue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	if (GetEntityMoveType(client) != MOVETYPE_LADDER)
	{
		if (GetClientSpeed(client) == g_fBoostMultiplier)
		{
			SetClientSpeed(client, NORMAL_SPEED);
		}
		return Plugin_Continue;
	}

	if (g_bAiLadderBoost && IsFakeClient(client))
	{
		SetClientSpeed(client, g_fBoostMultiplier);
		return Plugin_Continue;
	}

	if (g_bPzLadderBoost && !IsFakeClient(client) && !IsInfectedGhost(client))
	{
		SetClientSpeed(client, g_fBoostMultiplier);
		return Plugin_Continue;
	}

	return Plugin_Continue;
}

bool IsInfectedGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}

void SetClientSpeed(int client, float value)
{
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", value);
}

float GetClientSpeed(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
}
