#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "Super Stagger Solver",
	author = "CanadaRox, A1m (fix), Sir (rework), Forgetest",
	description = "Blocks all button presses and restarts animations during stumbles",
	version = "2.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void L4D_OnShovedBySurvivor_Post(int client, int victim, const float vecDir[3])
{
	if (L4D_IsPlayerStaggering(victim))
	{
		if (!FixSpitter(victim))
		{
			SetEntPropFloat(victim, Prop_Send, "m_fServerAnimStartTime", GetGameTime());
			SetEntPropFloat(victim, Prop_Send, "m_flCycle", 0.0);
		}
	}
}

public void L4D2_OnEntityShoved_Post(int client, int entity, int weapon, const float vecDir[3], bool bIsHighPounce)
{
	if( entity > 0 && entity <= MaxClients && IsClientInGame(entity) && GetClientTeam(entity) == 3)
	{
		if (L4D_IsPlayerStaggering(entity))
		{
			if (!FixSpitter(entity))
			{
				SetEntPropFloat(entity, Prop_Send, "m_fServerAnimStartTime", GetGameTime());
				SetEntPropFloat(entity, Prop_Send, "m_flCycle", 0.0);
			}
		}
	}
}

bool FixSpitter(int client)
{
	if (GetClientTeam(client) != 3)
		return false;
	
	if (GetEntProp(client, Prop_Send, "m_zombieClass") != 4)
		return false;
	
	if (GetEntProp(client, Prop_Send, "m_nSequence") != 21)
		return false;
	
	SetEntPropFloat(client, Prop_Send, "m_flCycle", 1.0);
	return true;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (IsClientInGame(client) 
	&& IsPlayerAlive(client)
	&& L4D_IsPlayerStaggering(client))
	{
		/*
			* If you shove an SI that's on the ladder, the player won't be able to move at all until killed.
			* This is why we only apply this method when the SI is not on a ladder.
		*/
		if (GetEntityMoveType(client) != MOVETYPE_LADDER) {
			buttons = 0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}