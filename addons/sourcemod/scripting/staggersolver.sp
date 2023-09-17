#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "Super Stagger Solver",
	author = "CanadaRox, A1m (fix), Sir (rework), Forgetest, Harry",
	description = "Blocks all button presses and restarts animations during stumbles",
	version = "2.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

#define TEAM_INFECTED 3
#define Z_TANK 8

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
/*
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
*/
public void L4D2_OnStagger_Post(int client, int source)
{
	if( client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		if (L4D_IsPlayerStaggering(client))
		{
			if (!FixSpitter(client))
			{
				if (IsTank(client))
				{
					int anim = GetEntProp(client, Prop_Send, "m_nSequence");
					switch(anim)
					{
						case 52, 53, 54, 55, 56, 57, 58, 59, 60: // victory (coop only)
						{
							SetEntPropFloat(client, Prop_Send, "m_flCycle", 1.0);
						}
						/* comment out reason: controlled by another plugin: rock_stumble_block 
						case 48, 49, 50, 51: // Throw Rock
						{
							SetEntPropFloat(client, Prop_Send, "m_flCycle", 1.0);
						}*/
						case 28, 29, 30, 31: //stumble
						{
							SetEntPropFloat(client, Prop_Send, "m_fServerAnimStartTime", GetGameTime());
							SetEntPropFloat(client, Prop_Send, "m_flCycle", 0.0);
						}
					}

					return;
				}

				SetEntPropFloat(client, Prop_Send, "m_fServerAnimStartTime", GetGameTime());
				SetEntPropFloat(client, Prop_Send, "m_flCycle", 0.0);
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

bool IsTank(int iClient)
{
	return (GetClientTeam(iClient) == TEAM_INFECTED && GetEntProp(iClient, Prop_Send, "m_zombieClass") == Z_TANK);
}