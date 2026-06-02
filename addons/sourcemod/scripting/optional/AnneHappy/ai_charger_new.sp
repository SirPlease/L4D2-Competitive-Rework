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
	name 			= "Ai-Charger增强",
	author 			= "Breezy，High Cookie，Standalone，Newteee，cravenge，Harry，Sorallll，PaimonQwQ，夜羽真白，东",
	description 	= "觉得Ai-Charger不够强？ Try this！",
	version 		= "2022/5/2",
	url 			= "https://steamcommunity.com/id/saku_ra/"
}

// ConVars
ConVar g_hChargerBhop, g_hChargerBhopSpeed, g_hChargerTarget, g_hStartChargeDistance, g_hChargerAimOffset, g_hHealthStartCharge, g_hChargerAirAngles,g_hChargerCoolTime;
// Ints
int g_iChargerTarget, g_iStartChargeDistance, g_iChargerAimOffset, g_iHealthStartCharge, g_iValidSurvivor = 0,g_iChargerCoolTime;
// Bools
bool g_bChargerBhop, g_bShouldCharge[MAXPLAYERS + 1],alreadycharged[MAXPLAYERS + 1];
// Floats
float g_fChargerBhopSpeed, g_fChargerAirAngles;

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define ZC_CHARGER 6
#define FL_JUMPING 65922

public void OnPluginStart()
{
	// CreateConVar
	g_hChargerCoolTime= CreateConVar("ai_ChargerCoolTime", "12", "Charger多少秒之后才能再次冲锋", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hChargerBhop = CreateConVar("ai_ChargerBhop", "1", "是否开启Charger连跳", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hChargerBhopSpeed = CreateConVar("ai_ChargerBhopSpeed", "90.0", "Charger连跳的速度", FCVAR_NOTIFY, true, 0.0);
	g_hChargerTarget = CreateConVar("ai_ChargerTarget", "3", "Charger目标选择：1=自然目标选择，2=优先撞人多处，3=优先取最近目标", FCVAR_NOTIFY, true, 1.0, true, 2.0);
	g_hStartChargeDistance = CreateConVar("ai_ChargerStartChargeDistance", "300", "Charger只能在与目标小于这一距离时冲锋", FCVAR_NOTIFY, true, 0.0);
	g_hChargerAimOffset = CreateConVar("ai_ChargerAimOffset", "30", "目标的瞄准角度与Charger处于这一角度内，Charger将不会冲锋", FCVAR_NOTIFY, true, 0.0);
	g_hHealthStartCharge = CreateConVar("ai_ChargerStartChargeHealth", "350", "Charger的生命值低于这一个值才会冲锋", FCVAR_NOTIFY, true, 0.0);
	g_hChargerAirAngles = CreateConVar("ai_ChargerAirAngles", "60.0", "Charger在空中的速度向量与到生还者的方向向量夹角大于这个值停止连跳", FCVAR_NOTIFY, true, 0.0);
	// HookEvents
	HookEvent("player_spawn", evt_PlayerSpawn);
	HookEvent("charger_charge_start", evt_ChargerChargeStart);
	// AddChangeHook
	g_hChargerCoolTime.AddChangeHook(ConVarChanged_Cvars);
	g_hChargerBhop.AddChangeHook(ConVarChanged_Cvars);
	g_hChargerBhopSpeed.AddChangeHook(ConVarChanged_Cvars);
	g_hChargerTarget.AddChangeHook(ConVarChanged_Cvars);
	g_hStartChargeDistance.AddChangeHook(ConVarChanged_Cvars);
	g_hChargerAimOffset.AddChangeHook(ConVarChanged_Cvars);
	g_hHealthStartCharge.AddChangeHook(ConVarChanged_Cvars);
	g_hChargerAirAngles.AddChangeHook(ConVarChanged_Cvars);
	// GetCvars
	GetCvars();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iChargerCoolTime=g_hChargerCoolTime.IntValue;
	g_bChargerBhop = g_hChargerBhop.BoolValue;
	g_fChargerBhopSpeed = g_hChargerBhopSpeed.FloatValue;
	g_iChargerTarget = g_hChargerTarget.IntValue;
	g_iStartChargeDistance = g_hStartChargeDistance.IntValue;
	g_iChargerAimOffset = g_hChargerAimOffset.IntValue;
	g_iHealthStartCharge = g_hHealthStartCharge.IntValue;
	g_fChargerAirAngles = g_hChargerAirAngles.FloatValue;
}

public Action OnPlayerRunCmd(int charger, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsAiCharger(charger))
	{
		float fChargerPos[3];
		GetClientAbsOrigin(charger, fChargerPos);
		// 获取状态
		int iFlags = GetEntityFlags(charger), iTarget = GetClientAimTarget(charger, true);
		float fSpeed[3] = {0.0}, fCurrentSpeed = 0.0, fDistance = NearestSurvivorDistance(charger);
		GetEntPropVector(charger, Prop_Data, "m_vecVelocity", fSpeed);
		fCurrentSpeed = SquareRoot(Pow(fSpeed[0], 2.0) + Pow(fSpeed[1], 2.0));
		bool bHasSight = view_as<bool>(GetEntProp(charger, Prop_Send, "m_hasVisibleThreats"));
		if (buttons & IN_ATTACK)
		{
			vel[0] = vel[1] = vel[2] = 0.0;
		}
		// 可以冲锋且可视的条件下距离小于 150，目标没有正在看着自身，则需要血量小于限制并且按下右键的情况下才可冲锋，如果目标正在看着自身，则只需要判断距离
		if (ChargerCanCharge(charger) && bHasSight && (!IsTargetWatchingAttacker(charger, g_iChargerAimOffset) && g_bShouldCharge[charger] && fDistance < 150.0) || 
			(IsTargetWatchingAttacker(charger, g_iChargerAimOffset) && fDistance < 150.0))
		{
			vel[0] = vel[1] = 0.0;
			buttons |= IN_ATTACK;
			buttons |= IN_ATTACK2;
			return Plugin_Changed;
		}
		if (bHasSight && IsSurvivor(iTarget) && float(g_iStartChargeDistance) < fDistance < 1000.0 && fCurrentSpeed > 175.0)
		{
			// 连跳操作
			float fBuffer[3] = {0.0}, fTargetPos[3] = {0.0};
			GetClientAbsOrigin(iTarget, fTargetPos);
			fBuffer = UpdatePosition(charger, iTarget, g_fChargerBhopSpeed);
			if (g_bChargerBhop)
			{
				if (iFlags & FL_ONGROUND)
				{
					buttons |= IN_JUMP;
					buttons |= IN_DUCK;
					if ((buttons & IN_FORWARD) || (buttons & IN_BACK) || (buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT))
					{
						ClientPush(charger, fBuffer);
					}
				}
				else if (iFlags == FL_JUMPING)
				{
					float fAngles[3] = {0.0};
					if (fDistance < 250.0)
					{
						float fAnglesPost[3];
						GetVectorAngles(fSpeed, fAngles);
						fAnglesPost = fAngles;
						fAngles[0] = fAngles[2] = 0.0;
						GetAngleVectors(fAngles, fAngles, NULL_VECTOR, NULL_VECTOR);
						NormalizeVector(fAngles, fAngles);
						// 保存当前位置
						static float fDirection[2][3];
						fDirection[0] = fChargerPos;
						fDirection[1] = fTargetPos;
						fChargerPos[2] = fTargetPos[2] = 0.0;
						MakeVectorFromPoints(fChargerPos, fTargetPos, fChargerPos);
						NormalizeVector(fChargerPos, fChargerPos);
						// 计算距离
						if (RadToDeg(ArcCosine(GetVectorDotProduct(fAngles, fChargerPos))) >= g_fChargerAirAngles)
						{
							// 重新设置速度方向
							float fNewVelocity[3];
							MakeVectorFromPoints(fDirection[0], fDirection[1], fNewVelocity);
							NormalizeVector(fNewVelocity, fNewVelocity);
							ScaleVector(fNewVelocity, fCurrentSpeed);
							TeleportEntity(charger, NULL_VECTOR, fAnglesPost, fNewVelocity);
						}
					}
				}
			}
		}
		if (IsSurvivor(iTarget))
		{
			float targetpos[3] = {0.0};
			GetClientAbsOrigin(iTarget, targetpos);
			int iSurvivorDistance = GetSurvivorDistance(fChargerPos, iTarget);
			int iChargerHealth = GetClientHealth(charger);
			if (iChargerHealth > g_iHealthStartCharge || iSurvivorDistance > g_iStartChargeDistance || FloatAbs(fChargerPos[2] - targetpos[2]) > 72.0)
			{
				if (!g_bShouldCharge[charger] && ChargerCanCharge(charger))
				{
					BlockCharge(charger);
					buttons |= IN_ATTACK2;
					return Plugin_Changed;
				}
			}
			else
			{
				buttons |= IN_ATTACK2;
				if(!alreadycharged[charger])
				g_bShouldCharge[charger] = true;
			}
			return Plugin_Continue;
		}
		if (GetEntityMoveType(charger) & MOVETYPE_LADDER)
		{
			//buttons &= ~IN_JUMP;
			buttons &= ~IN_DUCK;
		}
	}
	return Plugin_Continue;
}

public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{
	if (IsAiCharger(specialInfected))
	{
		float fSelfPos[3], self_eye_pos[3] = {0.0};
		GetClientAbsOrigin(specialInfected, fSelfPos);
		GetClientEyePosition(specialInfected, self_eye_pos);
		int iTeamMeleeCount = TeamMeleeCheck();
		switch (g_iChargerTarget)
		{
			case 2:
			{
				int crowded = GetCrowdPlace();
				if (crowded != -1 && IsSurvivor(crowded))
				{
					curTarget = crowded;
					return Plugin_Changed;
				}
			}
			case 3:
			{
				// 所有人都拿着近战，随机选取最近目标
				if (iTeamMeleeCount == g_iValidSurvivor)
				{
					int newtarget = GetClosestSurvivor(fSelfPos);
					if (IsSurvivor(newtarget))
					{
						curTarget = newtarget;
						return Plugin_Changed;
					}
				}
				else
				{
					// 当前目标拿着近战且不是整个团队都拿着近战，当前 Charger 看不见其他玩家且距离没有小于 600，不改变目标
					if (NearestSurvivorDistance(specialInfected) > 0.50 * float(g_iStartChargeDistance))
					{
						if (ClientMeleeCheck(curTarget))
						{
							int newtarget = GetClosestSurvivor(fSelfPos, curTarget);
							for (int i = 1; i <= MaxClients; i++)
							{
								if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == view_as<int>(TEAM_SURVIVOR) && i != curTarget)
								{
									float eye_pos[3] = {0.0};
									GetClientEyePosition(i, eye_pos);
									Handle hTrace = TR_TraceRayFilterEx(self_eye_pos, eye_pos, MASK_VISIBLE, RayType_EndPoint, TR_RayFilter, specialInfected);
									if (!TR_DidHit(hTrace) && GetVectorDistance(self_eye_pos, eye_pos) < 600.0 && IsSurvivor(newtarget))
									{
										curTarget = newtarget;
										return Plugin_Changed;
									}
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
bool TR_RayFilter(int entity, int mask, int self)
{
	return entity != self;
}

bool ClientMeleeCheck(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR)
	{
		int iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(iActiveWeapon) && IsValidEdict(iActiveWeapon))
		{
			char sWeaponName[64];
			GetEdictClassname(iActiveWeapon, sWeaponName, sizeof(sWeaponName));
			if (strcmp(sWeaponName[7], "melee") == 0 || strcmp(sWeaponName, "weapon_chainsaw") == 0)
			{
				return true;
			}
		}
	}
	return false;
}

int TeamMeleeCheck()
{
	int iTeamMeleeCount = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client) && !IsIncapped(client) && !IsPinned(client))
		{
			g_iValidSurvivor += 1;
			int iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (IsValidEntity(iActiveWeapon) && IsValidEdict(iActiveWeapon))
			{
				char sWeaponName[32] = '\0';
				GetEdictClassname(iActiveWeapon, sWeaponName, sizeof(sWeaponName));
				if (strcmp(sWeaponName[7], "melee") == 0 || strcmp(sWeaponName, "weapon_chainsaw") == 0)
				{
					iTeamMeleeCount += 1;
				}
			}
		}
	}
	return iTeamMeleeCount;
}

// From：http://github.com/PaimonQwQ/L4D2-Plugins/smartspitter.sp
int GetCrowdPlace()
{
	int iCount = GetSurvivorCount();
	if (iCount > 0)
	{
		int index = 0, iTarget = 0;
		int[] iSurvivors = new int[iCount];
		float fDistance[MAXPLAYERS + 1] = -1.0;
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client) && GetClientTeam(client) == TEAM_SURVIVOR)
			{
				iSurvivors[index++] = client;
			}
		}
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR)
			{
				fDistance[client] = 0.0;
				float fClientPos[3] = 0.0;
				GetClientAbsOrigin(client, fClientPos);
				for (int i = 0; i < iCount; i++)
				{
					float fPos[3] = 0.0;
					GetClientAbsOrigin(iSurvivors[i], fPos);
					fDistance[client] += GetVectorDistance(fClientPos, fPos, true);
				}
			}
		}
		for (int i = 0; i < iCount; i++)
		{
			if (fDistance[iSurvivors[iTarget]] > fDistance[iSurvivors[i]])
			{
				if (fDistance[iSurvivors[i]] != -1.0)
				{
					iTarget = i;
				}
			}
		}
		return iSurvivors[iTarget];
	}
	else
	{
		return -1;
	}
}

bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	else
	{
		return false;
	}
}

int GetSurvivorCount()
{
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
			iCount++;
		}
	}
	return iCount;
}

// ***** 事件 *****
public void evt_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsAiCharger(client))
	{
		alreadycharged[client]=false;
		g_bShouldCharge[client] = false;
	}
}

public void evt_ChargerChargeStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsAiCharger(client))
	{
		g_bShouldCharge[client]=false;
		alreadycharged[client]=true;
		CreateTimer(g_iChargerCoolTime, ChargerEnable, client, TIMER_FLAG_NO_MAPCHANGE);
		int iTarget = GetClientAimTarget(client, true);
		if (!IsSurvivor(iTarget) || IsIncapped(iTarget) || IsPinned(iTarget) || IsTargetWatchingAttacker(client, g_iChargerAimOffset))
		{
			int iNewTarget, iTargets[MAXPLAYERS + 1];
			float fNewDistance;
			static float vPos[3];
			static int iNumClients, i;
			iNumClients = 0;
			GetClientEyePosition(client, vPos);
			iNumClients = GetClientsInRange(vPos, RangeType_Visibility, iTargets, MAXPLAYERS);
			if (iNumClients != 0)
			{
				static ArrayList aTargets;
				aTargets = new ArrayList(2);
				static float vTarget[3], dist;
				static int index, victim;
				for (i = 0; i < iNumClients; i++)
				{
					victim = iTargets[i];
					if (victim && victim != iTarget && GetClientTeam(victim) == TEAM_SURVIVOR && IsPlayerAlive(victim) && !IsIncapped(victim) && !IsPinned(victim))
					{
						GetClientAbsOrigin(victim, vTarget);
						dist = GetVectorDistance(vPos, vTarget);
						index = aTargets.Push(dist);
						aTargets.Set(index, victim, 1);
					}
				}
				if (aTargets.Length != 0)
				{
					SortADTArray(aTargets, Sort_Ascending, Sort_Float);
					fNewDistance = aTargets.Get(0, 0);
					iNewTarget = aTargets.Get(0, 1);
				}
				delete aTargets;
			}
			if (iNewTarget && fNewDistance <= g_iStartChargeDistance)
			{
				iTarget = iNewTarget;
			}
			ChargerPridiction(client, iTarget);
		}
	}
}
public Action ChargerEnable(Handle timer,int client) {
	alreadycharged[client]=false;
	g_bShouldCharge[client]=true;
}
void ChargerPridiction(int charger, int survivor)
{
	if (IsAiCharger(charger) && IsSurvivor(survivor))
	{
		float fSelfPos[3], fTargetPos[3], fAttackDirection[3], fAttackAngle[3];
		GetClientAbsOrigin(charger, fSelfPos);
		GetClientAbsOrigin(survivor, fTargetPos);
		MakeVectorFromPoints(fSelfPos, fTargetPos, fAttackDirection);
		GetVectorAngles(fAttackDirection, fAttackAngle);
		TeleportEntity(charger, NULL_VECTOR, fAttackAngle, NULL_VECTOR);
	}
}

// ***** 方法 *****
bool IsAiCharger(int client)
{
	if (client && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && IsFakeClient(client) && GetClientTeam(client) == TEAM_INFECTED && GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_CHARGER && GetEntProp(client, Prop_Send, "m_isGhost") != 1)
	{
		return true;
	}
	else
	{
		return false;
	}
}

float NearestSurvivorDistance(int client)
{
	static int i, iCount;
	static float vPos[3], vTargetPos[3], fDistance[MAXPLAYERS + 1] = {0.0};
	iCount = 0;
	GetClientAbsOrigin(client, vPos);
	for (i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) && !IsIncapped(i) && !IsPinned(i))
		{
			GetClientAbsOrigin(i, vTargetPos);
			fDistance[iCount++] = GetVectorDistance(vPos, vTargetPos);
		}
	}
	if (iCount == 0)
	{
		return -1.0;
	}
	SortFloats(fDistance, iCount, Sort_Ascending);
	return fDistance[0];
}

bool ChargerCanCharge(int client)
{
	if (GetEntPropEnt(client, Prop_Send, "m_pummelVictim") > 0 || GetEntPropEnt(client, Prop_Send, "m_carryVictim") > 0)
	{
		return false;
	}
	int iAbility = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (iAbility != -1 && GetEntProp(iAbility, Prop_Send, "m_isCharging") != 1 && GetEntPropFloat(iAbility, Prop_Send, "m_timestamp") < GetGameTime())
	{
		return true;
	}
	return false;
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

float UpdatePosition(int charger, int target, float fForce)
{
	float fBuffer[3], fChargerPos[3], fTargetPos[3];
	GetClientAbsOrigin(charger, fChargerPos);	GetClientAbsOrigin(target, fTargetPos);
	SubtractVectors(fTargetPos, fChargerPos, fBuffer);
	NormalizeVector(fBuffer, fBuffer);
	ScaleVector(fBuffer, fForce);
	return fBuffer;
}

void ClientPush(int client, float fForwardVec[3])
{
	float fCurVelVec[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fCurVelVec);
	for (int i = 0; i < 3; i++)
	{
		fCurVelVec[i] += fForwardVec[i];
	}
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fCurVelVec);
}

int GetSurvivorDistance(const float refpos[3], int SpecificSur = -1)
{
	int TargetSur;
	float TargetSurPos[3], RefSurPos[3];
	RefSurPos[0] = refpos[0];	RefSurPos[1] = refpos[1];	RefSurPos[2] = refpos[2];
	if (SpecificSur > 0 && IsSurvivor(SpecificSur))
	{
		TargetSur = SpecificSur;
	}
	else
	{
		int target = GetClosestSurvivor(RefSurPos);
		if (IsSurvivor(target))
		{
			TargetSur = target;
		}
	}
	GetEntPropVector(TargetSur, Prop_Send, "m_vecOrigin", TargetSurPos);
	return RoundToNearest(GetVectorDistance(RefSurPos, TargetSurPos));
}

int GetRandomMobileSurvivor()
{
	int survivors[16] = {0}, index = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client) && !IsIncapped(client) && !IsPinned(client))
		{
			survivors[index] = client;
			index += 1;
		}
	}
	if (index > 0)
	{
		return survivors[GetRandomInt(0, index - 1)];
	}
	return 0;
}

int GetClosestSurvivor(float refpos[3], int excludeSur = -1)
{
	float surPos[3] = {0.0};
	int closetSur = GetRandomMobileSurvivor();
	if (IsSurvivor(closetSur))
	{
		GetClientAbsOrigin(closetSur, surPos);
		int iClosetAbsDisplacement = RoundToNearest(GetVectorDistance(refpos, surPos));
		for (int client = 1; client < MaxClients; client++)
		{
			if (IsSurvivor(client) && IsPlayerAlive(client) && client != excludeSur && !IsIncapped(client) && !IsPinned(client))
			{
				GetClientAbsOrigin(client, surPos);
				int iAbsDisplacement = RoundToNearest(GetVectorDistance(refpos, surPos));
				if (iClosetAbsDisplacement < 0)
				{
					iClosetAbsDisplacement = iAbsDisplacement;
					closetSur = client;
				}
				else if (iAbsDisplacement < iClosetAbsDisplacement)
				{
					iClosetAbsDisplacement = iAbsDisplacement;
					closetSur = client;
				}
			}
		}
	}
	return closetSur;
}

void BlockCharge(int charger)
{
	int iChargeEntity = GetEntPropEnt(charger, Prop_Send, "m_customAbility");
	if (iChargeEntity > 0)
	{
		SetEntPropFloat(iChargeEntity, Prop_Send, "m_timestamp", GetGameTime() + 0.1);
	}
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