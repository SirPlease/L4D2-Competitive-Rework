#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

enum AimType
{
	AimEye,
	AimBody,
	AimChest
};

public Plugin myinfo = 
{
	name 			= "Ai_Jockey增强",
	author 			= "Breezy，High Cookie，Standalone，Newteee，cravenge，Harry，Sorallll，PaimonQwQ，夜羽真白, 东",
	description 	= "觉得Ai猴子太弱了？ Try this！",
	version 		= "2022/11/1",
	url 			= "https://github.com/fantasylidong/CompetitiveWithAnne"
}

// ConVars
ConVar g_hBhopSpeed, g_hStartHopDistance, g_hJockeyStumbleRadius, g_hJockeyLeapRange, g_hJockeyLeapAgain, g_hJockeyAirAngles, g_hJockeyLeapTime;
// Ints
int g_iState[MAXPLAYERS + 1][8];
// Float
float g_fStartHopDistance, g_fJockeyBhopSpeed, g_fJockeyStumbleRadius, g_fJockeyLeapRange, g_fJockeyLeapAgain, g_fJockeyAirAngles, g_fJockeyLeapTime;
// Bools
bool g_bHasBeenShoved[MAXPLAYERS + 1], g_bCanLeap[MAXPLAYERS + 1];


#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define ZC_JOCKEY 5
#define FL_JUMPING 65922
// JOCKEY
#define JOCKEYMINSPEED 130.0
#define SPEED_FIXED_LENGTH 400.0

public void OnPluginStart()
{
	g_hBhopSpeed = CreateConVar("ai_JockeyBhopSpeed", "80.0", "Jockey连跳的速度", FCVAR_NOTIFY, true, 0.0);
	g_hStartHopDistance = CreateConVar("ai_JockeyStartHopDistance", "800.0", "Jockey距离生还者多少距离开始主动连跳", FCVAR_NOTIFY, true, 0.0);
	g_hJockeyStumbleRadius = CreateConVar("ai_JockeyStumbleRadius", "50.0", "Jockey骑到人后会对多少范围内的生还者产生硬直效果", FCVAR_NOTIFY, true, 0.0);
	g_hJockeyAirAngles = CreateConVar("ai_JockeyAirAngles", "60.0", "Jockey的速度方向与到目标的向量方向的距离大于这个角度，改变方向", FCVAR_NOTIFY, true, 0.0, true, 180.0);
	g_hJockeyLeapRange =		FindConVar("z_jockey_leap_range");
	g_hJockeyLeapAgain =		FindConVar("z_jockey_leap_again_timer");
	g_hJockeyLeapTime =		FindConVar("z_jockey_leap_time");
	// HookEvent
	HookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("player_spawn", evt_PlayerSpawn, EventHookMode_Pre);
	HookEvent("player_shoved", evt_PlayerShoved, EventHookMode_Pre);
	HookEvent("jockey_ride", evt_JockeyRide, EventHookMode_Pre);
	// AddChangeHook
	g_hBhopSpeed.AddChangeHook(ConVarChanged_Cvars);
	g_hStartHopDistance.AddChangeHook(ConVarChanged_Cvars);
	g_hJockeyStumbleRadius.AddChangeHook(ConVarChanged_Cvars);
	g_hJockeyAirAngles.AddChangeHook(ConVarChanged_Cvars);
	// GetCvars
	GetCvars();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bCanLeap[i] = false;
	}	
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_fJockeyBhopSpeed = g_hBhopSpeed.FloatValue;
	g_fStartHopDistance = g_hStartHopDistance.FloatValue;
	g_fJockeyStumbleRadius = g_hJockeyStumbleRadius.FloatValue;
	g_fJockeyLeapRange = g_hJockeyLeapRange.FloatValue;
	g_fJockeyLeapAgain = g_hJockeyLeapAgain.FloatValue;
	g_fJockeyAirAngles = g_hJockeyAirAngles.FloatValue;
	g_fJockeyLeapTime = g_hJockeyLeapTime.FloatValue;
}

public Action OnPlayerRunCmd(int jockey, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsAiJockey(jockey))
	{
		if(GetEntPropEnt(jockey, Prop_Send, "m_jockeyVictim") > 0)
			return Plugin_Continue;
		if (L4D_IsPlayerStaggering(jockey))
			return Plugin_Continue;
		int iFlags = GetEntityFlags(jockey);
		float fSpeed[3] = {0.0}, fCurrentSpeed, fJockeyPos[3] = {0.0};
		GetEntPropVector(jockey, Prop_Data, "m_vecVelocity", fSpeed);
		fCurrentSpeed = SquareRoot(Pow(fSpeed[0], 2.0) + Pow(fSpeed[1], 2.0));
		GetClientAbsOrigin(jockey, fJockeyPos);
		// 获取jockey状态
		int iTarget = NearestSurvivor(jockey);
		bool bHasSight = view_as<bool>(GetEntProp(jockey, Prop_Send, "m_hasVisibleThreats"));
		if (IsSurvivor(iTarget) && IsPlayerAlive(iTarget) && bHasSight && !g_bHasBeenShoved[jockey])
		{
			// 其他操作
			float fBuffer[3] = {0.0}, fTargetPos[3] = {0.0}, fDistance = NearestSurvivorDistance(jockey);
			GetClientAbsOrigin(iTarget, fTargetPos);
			if (fCurrentSpeed > JOCKEYMINSPEED && fDistance < g_fStartHopDistance)
			{
				float self_eye_pos[3] = {0.0}, targetpos[3] = {0.0}, look_at[3] = {0.0};
				GetClientEyePosition(jockey, self_eye_pos);
				GetClientAbsOrigin(iTarget, targetpos);
				targetpos[2] += 45.0;
				MakeVectorFromPoints(self_eye_pos, targetpos, look_at);
				GetVectorAngles(look_at, look_at);
				TeleportEntity(jockey, NULL_VECTOR, look_at, NULL_VECTOR);
				fBuffer = UpdatePosition(jockey, iTarget, g_fJockeyBhopSpeed);
				//PrintToConsoleAll("flag：%d", iFlags);
				if (iFlags & FL_ONGROUND)
				{
					static float vAng[3];
					//PrintToConsoleAll("前提条件满足， 在地上，速度：%f 最近生还者距离： %f ", fCurrentSpeed, fDistance);
					if (fDistance < g_fJockeyLeapRange)
					{
						// 在地上的情况，如果猴子能骑人,则把它改为跳跃状态，增加跳跃高度,否则为普通跳跃
						if (GetState(jockey, 0) == IN_JUMP && g_bCanLeap[jockey] && fDistance < g_fJockeyLeapRange)
						{
							
							bool bIsWatchingJockey = IsTargetWatchingAttacker(jockey, 20);
							if (bIsWatchingJockey)
							{
								vAng = angles;
								vAng[0] = Math_GetRandomFloat(-35.0, -10.0);
								TeleportEntity(jockey, NULL_VECTOR, vAng, NULL_VECTOR);
							}
							buttons |= IN_ATTACK;
							SetState(jockey, 0, IN_ATTACK);
						}
						//normaljump
						else
						{
							//PrintToConsoleAll("普通跳跃");
							vAng = angles;
							vAng[0] = Math_GetRandomFloat(-10.0, 0.0);
							TeleportEntity(jockey, NULL_VECTOR, vAng, NULL_VECTOR);
							buttons |= IN_JUMP;
							switch (GetRandomInt(0, 2))
							{
								case 0:
								{
									buttons |= IN_DUCK;
								}
								case 1:
								{
									buttons |= IN_ATTACK2;
								}
							}
							if(g_bCanLeap[jockey])
								SetState(jockey, 0, IN_JUMP);
						}
					}
					else if(buttons & IN_FORWARD || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT)
					{
						//PrintToConsoleAll("连跳");
						buttons |= IN_JUMP;
						buttons |= IN_DUCK;
						ClientPush(jockey, fBuffer);
					}
				}			
				// 空中转向
				else
				{
					//太近不允许强制换方向
					if(fDistance > 150.0){
						//PrintToConsoleAll("检测猴子在空中");
						float fAngles[3], new_velvec[3] = {0.0}, self_target_vec[3] = {0.0};
						GetVectorAngles(fSpeed, fAngles);
						fAngles[0] = fAngles[2] = 0.0;
						GetAngleVectors(fAngles, new_velvec, NULL_VECTOR, NULL_VECTOR);
						NormalizeVector(new_velvec, new_velvec);
						// 保存当前位置
						// 生还比特感高，关闭z方向
						if(fTargetPos[2] > fTargetPos[2])
							fJockeyPos[2] = fTargetPos[2] = 0.0;
						MakeVectorFromPoints(fJockeyPos, fTargetPos, self_target_vec);
						NormalizeVector(self_target_vec, self_target_vec);
						float fAngleDifference = RadToDeg(ArcCosine(GetVectorDotProduct(new_velvec, self_target_vec)));
						//PrintToConsoleAll("速度夹角：%f", fAngleDifference);
						// 计算距离
						if (fAngleDifference > g_fJockeyAirAngles && fAngleDifference < 120.0)
						{
							//重新设置方向
							MakeVectorFromPoints(fJockeyPos, fTargetPos, new_velvec);
							GetVectorAngles(new_velvec, fAngles);
							NormalizeVector(new_velvec, new_velvec);
							// 按照原来速度向量长度 + 缩放长度缩放修正后的速度向量，觉得太阴间了可以修改
							ScaleVector(new_velvec, fCurrentSpeed * 0.9);
							//PrintToConsoleAll("方向夹角为： %f,强制转向后的速度: %f", fAngleDifference, GetVectorLength(new_velvec));
							TeleportEntity(jockey, NULL_VECTOR, fAngles, new_velvec);
						}
					}
					// 不在地上，禁止按下跳跃键和攻击键
					buttons &= ~IN_JUMP;
					buttons &= ~IN_ATTACK;
				}
			}
		}
		if (GetEntityMoveType(jockey) & MOVETYPE_LADDER)
		{
			buttons &= ~IN_JUMP;
			buttons &= ~IN_DUCK;
		}
	}
	return Plugin_Continue;
}



public Action evt_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	int iShovedPlayer = GetClientOfUserId(event.GetInt("userid"));
	if (IsAiJockey(iShovedPlayer))
	{
		g_bHasBeenShoved[iShovedPlayer] = true;
		CreateTimer(g_fJockeyLeapTime, Timer_LeapTimeCoolDown, iShovedPlayer, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}



public Action evt_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iSpawnPlayer = GetClientOfUserId(event.GetInt("userid"));
	if (IsAiJockey(iSpawnPlayer))
	{
		g_bHasBeenShoved[iSpawnPlayer] = false;
		g_bCanLeap[iSpawnPlayer] = true;
		SetState(iSpawnPlayer, 0, IN_JUMP);
	}
	return Plugin_Handled;
}

public Action Timer_LeapCoolDown(Handle timer, int jockey)
{
	g_bCanLeap[jockey] = true;
	return Plugin_Continue;
}

public Action Timer_LeapTimeCoolDown(Handle timer, int jockey)
{
	g_bHasBeenShoved[jockey] = false;
	return Plugin_Continue;
}

public void evt_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	if (g_fJockeyStumbleRadius <= 0.0 || !L4D2_IsGenericCooperativeMode())
		return;

	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!attacker || !IsClientInGame(attacker))
		return;

	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!victim || !IsClientInGame(victim))
		return;
	g_bCanLeap[attacker] = false;
	CreateTimer(g_fJockeyLeapAgain, Timer_LeapCoolDown, attacker, TIMER_FLAG_NO_MAPCHANGE);
	StumbleByStanders(victim, attacker);
}

void StumbleByStanders(int pinnedSurvivor, int pinner) 
{
	static float pinnedSurvivorPos[3], pos[3], dir[3];
	GetClientAbsOrigin(pinnedSurvivor, pinnedSurvivorPos);
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			if(i != pinnedSurvivor && i != pinner && !IsPinned(i)) 
			{
				GetClientAbsOrigin(i, pos);
				SubtractVectors(pos, pinnedSurvivorPos, dir);
				if(GetVectorLength(dir) <= g_fJockeyStumbleRadius) 
				{
					NormalizeVector(dir, dir); 
					L4D_StaggerPlayer(i, pinnedSurvivor, dir);
				}
			}
		} 
	}
}




// ***** 方法 *****
bool IsAiJockey(int client)
{
	if (client && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && IsFakeClient(client) && GetClientTeam(client) == TEAM_INFECTED && GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_JOCKEY && GetEntProp(client, Prop_Send, "m_isGhost") != 1)
	{
		return true;
	}
	else
	{
		return false;
	}
}

bool IsPinned(int client)
{
	bool bIsPinned = false;
	if (IsSurvivor(client))
	{
		if( GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 ) bIsPinned = true;
		if( GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 ) bIsPinned = true;
		if( GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 ) bIsPinned = true;
		if( GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 ) bIsPinned = true;
		if( GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 ) bIsPinned = true;
	}		
	return bIsPinned;
}

int  NearestSurvivor(int client) {
	static int i;
	static float vPos[3];
	static float vTar[3];
	static float dist;
	static float minDist;

	minDist = -1.0;
	int minClient = client;
	GetClientAbsOrigin(client, vPos);
	for (i = 1; i <= MaxClients; i++) {
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !L4D_IsPlayerIncapacitated(i)) {
			GetClientAbsOrigin(i, vTar);
			dist = GetVectorDistance(vPos, vTar);
			if (minDist == -1.0 || dist < minDist){
				minDist = dist;
				minClient = i;
			}
				
		}
	}

	return minClient;
}

bool IsSurvivor(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR)
	{
		return true;
	}
	else
	{
		return false;
	}
}

bool IsIncapped(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

//最近生还者水平距离
float NearestSurvivorDistance(int client)
{
	static int i, iCount;
	static float vPos[3], vTarget[3], fDistance[MAXPLAYERS + 1];
	iCount = 0;
	GetClientAbsOrigin(client, vPos);
	vPos[2] = 0.0;
	for (i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) && !IsIncapped(i))
		{
			GetClientAbsOrigin(i, vTarget);
			vTarget[2] = 0.0;
			fDistance[iCount++] = GetVectorDistance(vPos, vTarget);
		}
	}
	if (iCount == 0)
	{
		return -1.0;
	}
	SortFloats(fDistance, iCount, Sort_Ascending);
	return fDistance[0];
}

bool IsTargetWatchingAttacker(int attacker, int offset)
{
	bool bIsWatching = true;
	if (GetClientTeam(attacker) == TEAM_INFECTED && IsPlayerAlive(attacker))
	{
		int iTarget = GetClientAimTarget(attacker);
		if (IsSurvivor(iTarget))
		{
			int iOffset = RoundToNearest(GetPlayerAimOffset(iTarget, attacker));
			if (iOffset <= offset)
			{
				bIsWatching = true;
			}
			else
			{
				bIsWatching = false;
			}
		}
	}
	return bIsWatching;
}

float GetPlayerAimOffset(int attacker, int target)
{
	if (IsClientConnected(attacker) && IsClientInGame(attacker) && IsPlayerAlive(attacker) && IsClientConnected(target) && IsClientInGame(target) && IsPlayerAlive(target))
	{
		float fAttackerPos[3], fTargetPos[3], fAimVector[3], fDirectVector[3], fResultAngle;
		GetClientEyeAngles(attacker, fAimVector);
		fAimVector[0] = fAimVector[2] = 0.0;
		GetAngleVectors(fAimVector, fAimVector, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(fAimVector, fAimVector);
		// 获取目标位置
		GetClientAbsOrigin(target, fTargetPos);
		GetClientAbsOrigin(attacker, fAttackerPos);
		fAttackerPos[2] = fTargetPos[2] = 0.0;
		MakeVectorFromPoints(fAttackerPos, fTargetPos, fDirectVector);
		NormalizeVector(fDirectVector, fDirectVector);
		// 计算角度
		fResultAngle = RadToDeg(ArcCosine(GetVectorDotProduct(fAimVector, fDirectVector)));
		return fResultAngle;
	}
	return -1.0;
}

void SetState(int client, int no, int value)
{
	g_iState[client][no] = value;
}

int GetState(int client, int no)
{
	return g_iState[client][no];
}

float[] UpdatePosition(int jockey, int target, float fForce)
{
	float fBuffer[3] = {0.0}, fTankPos[3] = {0.0}, fTargetPos[3] = {0.0};
	GetClientAbsOrigin(jockey, fTankPos);
	GetClientAbsOrigin(target, fTargetPos);
	SubtractVectors(fTargetPos, fTankPos, fBuffer);
	NormalizeVector(fBuffer, fBuffer);
	ScaleVector(fBuffer, fForce);
	fBuffer[2] = 0.0;
	return fBuffer;
}

void ClientPush(int client, float fForwardVec[3])
{
	float fCurVelVec[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fCurVelVec);
	AddVectors(fCurVelVec, fForwardVec, fCurVelVec);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fCurVelVec);
}

/**
 * Returns a random, uniform Float number in the specified (inclusive) range.
 * This is safe to use multiple times in a function.
 * The seed is set automatically for each plugin.
 *
 * @param min			Min value used as lower border
 * @param max			Max value used as upper border
 * @return				Random Float number between min and max
 */
float Math_GetRandomFloat(float min, float max)
{
	return (GetURandomFloat() * (max  - min)) + min;
}
