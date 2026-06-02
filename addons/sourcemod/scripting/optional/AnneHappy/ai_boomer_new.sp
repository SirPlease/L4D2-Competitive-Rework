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
	name 			= "Ai-Boomer增强",
	author 			= "夜羽真白，东",
	description 	= "觉得Ai-Boomer不够强， Try this！",
	version 		= "1.0.1.0",
	url 			= "https://steamcommunity.com/id/saku_ra/"
}

// ConVars
ConVar g_hBoomerBhop, g_hBoomerBhopSpeed, g_hVomitRange, g_hBoomerAirAngles;
// Floats
float g_fBoomerBhopSpeed, g_fVomitRange, g_fBoomerAirAngles;
// Bools
bool g_bBoomerBhop, bCanVomit[MAXPLAYERS + 1];
// Handles
Handle g_hVomitSurvivor;

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define ZC_BOOMER 2
#define FL_JUMPING 65922

public void OnPluginStart()
{
	// CreateConVar
	g_hBoomerBhop = CreateConVar("ai_BoomerBhop", "1", "是否开启Boomer连跳", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hBoomerBhopSpeed = CreateConVar("ai_BoomerBhopSpeed", "150.0", "Boomer连跳的速度", FCVAR_NOTIFY, true, 0.0);
	g_hBoomerAirAngles = CreateConVar("ai_BoomerAirAngles", "60.0", "Boomer在空中的速度向量与到生还者的方向向量夹角大于这个值停止连跳", FCVAR_NOTIFY, true, 0.0);
	g_hVomitRange = FindConVar("z_vomit_range");
	// HookEvents
	HookEvent("player_spawn", evt_PlayerSpawn);
	HookEvent("player_shoved", evt_PlayerShoved);
	HookEvent("ability_use", evt_AbilityUse);
	// AddChangeHook
	g_hBoomerBhop.AddChangeHook(ConVarChanged_Cvars);
	g_hBoomerBhopSpeed.AddChangeHook(ConVarChanged_Cvars);
	g_hBoomerAirAngles.AddChangeHook(ConVarChanged_Cvars);
	g_hVomitRange.AddChangeHook(ConVarChanged_Cvars);
	// GetCvars
	GetCvars();
	// Signatures
	Handle g_hGameConf = LoadGameConfigFile("left4dhooks.l4d2");
	if (g_hGameConf == INVALID_HANDLE)
	{
		SetFailState("无法找到 left4dhooks.l4d2 文件在 config 文件夹中");
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer::OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hVomitSurvivor = EndPrepSDKCall();
	if (g_hVomitRange == INVALID_HANDLE)
	{
		SetFailState("无法找到签名 CTerrorPlayer::OnVomitedUpon 可能已损坏或已更新");
	}
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bBoomerBhop = g_hBoomerBhop.BoolValue;
	g_fBoomerBhopSpeed = g_hBoomerBhopSpeed.FloatValue;
	g_fVomitRange = g_hVomitRange.FloatValue;
	g_fBoomerAirAngles = g_hBoomerAirAngles.FloatValue;
}

public Action OnPlayerRunCmd(int boomer, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if (IsAiBoomer(boomer))
	{
		if (L4D_IsPlayerStaggering(boomer))
			return Plugin_Continue;
		float fSpeed[3] = {0.0}, fCurrentSpeed = 0.0, fDistance = 0.0, fBoomerPos[3] = {0.0};
		GetEntPropVector(boomer, Prop_Data, "m_vecVelocity", fSpeed);
		fCurrentSpeed = SquareRoot(Pow(fSpeed[0], 2.0) + Pow(fSpeed[1], 2.0));
		fDistance = NearestSurvivorDistance(boomer);
		// 获取状态，目标
		int iFlags = GetEntityFlags(boomer), iTarget = GetClientAimTarget(boomer, true);
		bool bHasSight = view_as<bool>(GetEntProp(boomer, Prop_Send, "m_hasVisibleThreats"));
		GetClientAbsOrigin(boomer, fBoomerPos);
		// 靠近生还者，立即喷吐，不需要在地上，空中也能吐
		if(bHasSight && fDistance <= g_fVomitRange - 150.0 && bCanVomit[boomer])
		{
			buttons |= IN_FORWARD;
			buttons |= IN_ATTACK;
		}	
		else if (bHasSight && 0.1 * g_fVomitRange < fDistance < 10000.0 && fCurrentSpeed > 160.0)
		{
			if (IsSurvivor(iTarget))
			{
				// 连跳操作
				float fBuffer[3] = {0.0}, fTargetPos[3] = {0.0};
				GetClientAbsOrigin(iTarget, fTargetPos);
				fBuffer = UpdatePosition(boomer, iTarget, g_fBoomerBhopSpeed);
				if (g_bBoomerBhop)
				{
					if (iFlags & FL_ONGROUND)
					{
						buttons |= IN_JUMP;
						buttons |= IN_DUCK;
						if (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT)
						{
							ClientPush(boomer, fBuffer);
						}
					}
					else if (iFlags == FL_JUMPING)
					{
						float iTargetDistance = GetVectorDistance(fTargetPos, fBoomerPos);
						if (iTargetDistance < 100.0)
						{
							float fAnglesPost[3], fAngles[3];
							GetVectorAngles(fSpeed, fAngles);
							fAnglesPost = fAngles;
							fAngles[0] = fAngles[2] = 0.0;
							GetAngleVectors(fAngles, fAngles, NULL_VECTOR, NULL_VECTOR);
							NormalizeVector(fAngles, fAngles);
							// 保存当前位置
							static float fDirection[2][3];
							fDirection[0] = fBoomerPos;
							fDirection[1] = fTargetPos;
							fBoomerPos[2] = fTargetPos[2] = 0.0;
							MakeVectorFromPoints(fBoomerPos, fTargetPos, fBoomerPos);
							NormalizeVector(fBoomerPos, fBoomerPos);
							// 计算距离
							if (RadToDeg(ArcCosine(GetVectorDotProduct(fAngles, fBoomerPos))) < g_fBoomerAirAngles)
							{
								return Plugin_Continue;
							}
							// 重新设置速度方向
							float fNewVelocity[3];
							MakeVectorFromPoints(fDirection[0], fDirection[1], fNewVelocity);
							NormalizeVector(fNewVelocity, fNewVelocity);
							ScaleVector(fNewVelocity,fCurrentSpeed);
							TeleportEntity(boomer, NULL_VECTOR, fAnglesPost, fNewVelocity);
						}
					}
				}
			}
		}
		if (GetEntityMoveType(boomer) & MOVETYPE_LADDER)
		{
			buttons &= ~IN_JUMP;
			buttons &= ~IN_DUCK;
		}

		// SDKCall，强行被喷
		if (buttons & IN_ATTACK && bCanVomit[boomer])
		{
			bCanVomit[boomer] = false;
			float fVomitInterval = GetConVarFloat(FindConVar("z_vomit_interval"));
			float fSelfPos[3], fTargetPos[3];
			GetClientAbsOrigin(boomer, fSelfPos);
			for (int client = 1; client <= MaxClients; ++client)
			{
				if (IsSurvivor(client) && IsPlayerAlive(client) && IsVisible(boomer, client))
				{
					float fTargetDistance;
					GetClientAbsOrigin(client, fTargetPos);
					fTargetDistance = GetVectorDistance(fSelfPos, fTargetPos);
					if (fTargetDistance <= 100)
					{
						VomitPlayer(client, boomer);
					}
				}
			}
			CreateTimer(fVomitInterval, Timer_VomitCoolDown, boomer, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

void ComputeAimAngles(int client, int target, float angles[3], AimType type = AimEye)
{
	if(client<0||client>MaxClients||target<0||target>MaxClients)
		return;
	float selfpos[3], targetpos[3], lookat[3];
	GetClientEyePosition(client, selfpos);
	switch (type)
	{
		case AimEye:
		{
			GetClientEyePosition(target, targetpos);
		}
		case AimBody:
		{
			GetClientAbsOrigin(target, targetpos);
		}
		case AimChest:
		{
			GetClientAbsOrigin(target, targetpos);
			targetpos[2] += 45.0;
		}
	}
	MakeVectorFromPoints(selfpos, targetpos, lookat);
	GetVectorAngles(lookat, angles);
}
bool traceFilter(int entity, int mask, int self)
{
	return entity != self;
}
bool IsVisible(int client, int target)
{
	bool bCanSee = false;
	float selfpos[3], angles[3];
	GetClientEyePosition(client, selfpos);
	ComputeAimAngles(client, target, angles);
	Handle hTrace = TR_TraceRayFilterEx(selfpos, angles, MASK_SOLID, RayType_Infinite, traceFilter, client);
	if (TR_DidHit(hTrace))
	{
		int hit = TR_GetEntityIndex(hTrace);
		if (hit == target)
		{
			bCanSee = true;
		}
	}
	delete hTrace;
	return bCanSee;
}


void VomitPlayer(int target, int boomer)
{
	if (IsSurvivor(target) && IsPlayerAlive(target))
	{
		SDKCall(g_hVomitSurvivor, target, boomer, true);
	}
}

// ***** 事件 *****
public Action evt_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsAiBoomer(client))
	{
		bCanVomit[client] = true;
	}
	return Plugin_Continue;
}

public void evt_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	int iShovedPlayer = GetClientOfUserId(event.GetInt("userid"));
	if (IsAiBoomer(iShovedPlayer))
	{
		bCanVomit[iShovedPlayer] = false;
		CreateTimer(1.5, Timer_VomitCoolDown, iShovedPlayer, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_VomitCoolDown(Handle timer, int client)
{
	bCanVomit[client] = true;
	return Plugin_Continue;
}

public Action evt_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsAiBoomer(client))
	{
		Boomer_OnVomit(client);
	}
	return Plugin_Changed;
}



void Boomer_OnVomit(int client)
{
	//hook改变方向
	SDKHook(client, SDKHook_PreThink, SpreadBoomer);
	//以防2.5s后boomer没死没有unhook
	CreateTimer(2.5, Unhook ,client);
}

public Action Unhook(Handle Timer, int client)
{
	if( IsClientConnected( client ) != true || IsClientInGame(client) != true || IsPlayerAlive(client) != true || GetClientTeam( client ) != 3 )
	{
		SDKUnhook(client, SDKHook_PreThink, SpreadBoomer);	
	}
	return Plugin_Continue;
}
//改变方向
public Action SpreadBoomer(int client)
{
	if( IsClientConnected( client ) != true || IsClientInGame(client) != true || IsPlayerAlive(client) != true || GetClientTeam( client ) != 3 )
	{
		SDKUnhook(client, SDKHook_PreThink, SpreadBoomer);	
		return Plugin_Continue;
	}
	static float fNearestAngles[3];
	if (MakeNearestAngles(client, fNearestAngles))
	{
		fNearestAngles[1]+= GetRandomFloat(-90.0, 90.0);
		fNearestAngles[0]-= 20;
		TeleportEntity(client, NULL_VECTOR, fNearestAngles, NULL_VECTOR);
	}
	return Plugin_Changed;
}

/*
void Boomer_OnVomit(int client)
{
	//hook改变方向
	//SDKHook(client, SDKHook_PreThink, SpreadBoomer);
	//以防3s后boomer没死没有unhook
	static float fNearestAngles[3];
	if (MakeNearestAngles(client, fNearestAngles))
	{
		TeleportEntity(client, NULL_VECTOR, fNearestAngles, NULL_VECTOR);
	}
	DataPack dp = new DataPack();
	dp.WriteCell(client);
	dp.WriteFloat(2.0);
	CreateTimer(0.25, SpreadBoomer, dp);
}
//改变方向
public Action SpreadBoomer(Handle timer,DataPack dp)
{
	dp.Reset();
	int client = dp.ReadCell();
	float time = dp.ReadFloat();
	if( IsClientConnected( client ) != true || IsClientInGame(client) != true || IsPlayerAlive(client) != true || GetClientTeam( client ) != 3 )
	{
		return;
	}
	static float fNearestAngles[3];
	if (MakeNearestAngles(client, fNearestAngles))
	{
		fNearestAngles[1]+= GetRandomFloat(-90.0, 90.0);
		fNearestAngles[0]+= 10;
		TeleportEntity(client, NULL_VECTOR, fNearestAngles, NULL_VECTOR);
	}
	if(time - 0.25 >= 0)
	{
		dp.Reset(true);
		dp.WriteCell(client);
		dp.WriteFloat(time - 0.25);
		CreateTimer(0.25, SpreadBoomer, dp);
	}
		
}
*/

bool MakeNearestAngles(int client, float NearestAngles[3])
{
	static int iAimTarget;
	static float vTarget[3], vOrigin[3];
	iAimTarget = GetClientAimTarget(client, true);
	if (iAimTarget > 0)
	{
		if (IsSurvivor(iAimTarget))
		{
			static int i, iNum, iTargets[MAXPLAYERS + 1];
			GetClientEyePosition(client, vOrigin);
			iNum = GetClientsInRange(vOrigin, RangeType_Visibility, iTargets, MAXPLAYERS);
			if (iNum == 0)
			{
				return false;
			}
			static int iTarget;
			static ArrayList aTargets;
			aTargets = new ArrayList(2);
			for (i = 0; i < iNum; i++)
			{
				iTarget = iTargets[i];
				if (iTarget && iTarget != iAimTarget && GetClientTeam(iTarget) == TEAM_SURVIVOR && IsPlayerAlive(iTarget))
				{
					GetClientAbsOrigin(iTarget, vTarget);
					aTargets.Set(aTargets.Push(GetVectorDistance(vOrigin, vTarget)), iTarget, 1);
				}
			}
			if (aTargets.Length != 0)
			{
				SortADTArray(aTargets, Sort_Ascending, Sort_Float);
				iAimTarget = aTargets.Get(0, 1);
			}
			delete aTargets;
		}
		else
		{
			return false;
		}
		GetClientAbsOrigin(client, vOrigin);
		GetClientAbsOrigin(iAimTarget, vTarget);
		MakeVectorFromPoints(vOrigin, vTarget, vOrigin);
		GetVectorAngles(vOrigin, NearestAngles);
		return true;
	}
	else
	{
		return false;
	}
}

// ***** 方法 *****
bool IsAiBoomer(int client)
{
	if (client && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && IsFakeClient(client) && GetClientTeam(client) == TEAM_INFECTED && GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_BOOMER && GetEntProp(client, Prop_Send, "m_isGhost") != 1)
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
	static float vPos[3], vTarget[3], fDistance[MAXPLAYERS + 1];
	iCount = 0;
	GetClientAbsOrigin(client, vPos);
	for (i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) && !IsIncapped(i))
		{
			GetClientAbsOrigin(i, vTarget);
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

float[] UpdatePosition(int boomer, int target, float fForce)
{
	float fBuffer[3], fBoomerPos[3], fTargetPos[3];
	GetClientAbsOrigin(boomer, fBoomerPos);	GetClientAbsOrigin(target, fTargetPos);
	SubtractVectors(fTargetPos, fBoomerPos, fBuffer);
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

