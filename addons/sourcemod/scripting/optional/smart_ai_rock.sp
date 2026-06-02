#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_VERSION "2.0"

public Plugin myinfo = 
{
	name = "[L4D & 2] Smart AI Rock",
	author = "Forgetest, CanadaRox (Original author)",
	description = "Prevent underhand rocks and fix sticking aim after throws for AI Tanks.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

methodmap PlayerBody
{
	property CountdownTimer m_lookAtExpireTimer {
		public get() {
			return view_as<CountdownTimer>(
				view_as<Address>(this) + view_as<Address>(100)
			);
		}
	}
}

public void L4D_TankRock_OnRelease_Post(int tank, int rock, const float vecPos[3], const float vecAng[3], const float vecVel[3], const float vecRot[3])
{
	if (!IsFakeClient(tank))
		return;
	
	int ability = GetEntPropEnt(tank, Prop_Send, "m_customAbility");
	if (ability == -1)
		return;
	
	CountdownTimer throwTimer = CThrow__GetThrowTimer(ability);
	float flThrowEndTime = CTimer_GetTimestamp(throwTimer);
	
	CreateTimer(flThrowEndTime - GetGameTime() + 0.01, Timer_ExpireLookAt, GetClientUserId(tank), TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_ExpireLookAt(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client)) // gone
		return Plugin_Stop;
	
	if (GetClientTeam(client) != 3) // taken over
		return Plugin_Stop;
	
	if (L4D_IsPlayerIncapacitated(client) || !IsPlayerAlive(client)) // dead
		return Plugin_Stop;
	
	PlayerBody pBody = Tank__GetBodyInterface(client);
	CTimer_SetTimestamp(pBody.m_lookAtExpireTimer, GetGameTime());
	
	return Plugin_Stop;
}

PlayerBody Tank__GetBodyInterface(int tank)
{
	static int s_iOffs_m_playerBody = -1;
	if (s_iOffs_m_playerBody == -1)
		s_iOffs_m_playerBody = FindSendPropInfo("SurvivorBot"/* lol */, "m_humanSpectatorEntIndex") + 12 - 4 * view_as<int>(L4D_IsEngineLeft4Dead2());
	
	return view_as<PlayerBody>(
		LoadFromAddress(GetEntityAddress(tank) + view_as<Address>(s_iOffs_m_playerBody), NumberType_Int32)
	);
}

CountdownTimer CThrow__GetThrowTimer(int ability)
{
	static int s_iOffs_m_throwTimer = -1;
	if (s_iOffs_m_throwTimer == -1)
		s_iOffs_m_throwTimer = FindSendPropInfo("CThrow", "m_hasBeenUsed") + 4;
	
	return view_as<CountdownTimer>(
		GetEntityAddress(ability) + view_as<Address>(s_iOffs_m_throwTimer)
	);
}

/**
 * Smart AI Rock
 *  by CanadaRox
 */
/*public Action L4D2_OnSelectTankAttack(int client, int &sequence)
{
	if (L4D_IsEngineLeft4Dead2() && IsFakeClient(client) && sequence == 50)
	{
		sequence = GetRandomInt(0, 1) ? 49 : 51;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}*/
