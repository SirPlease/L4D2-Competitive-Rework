#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>

#define DEBUG_DOWNLINE 0
#define DEBUG_EYELINE 0
// Defines
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define OBSTACLE_HEIGHT 18.0
#define PLAYER_HEIGHT 72.0
#define TANK_UNSTUCK_TRIES 100
// CommandAbot
#define PLUGIN_SCRIPTLOGIC "plugin_scripting_logic_entity"
#define COMMANDABOT_MOVE "CommandABot({cmd = 1, pos = Vector(%f, %f, %f), bot = GetPlayerFromUserID(%i)})"
#define COMMANDABOT_ATTACK "CommandABot({cmd = 0, bot = GetPlayerFromUserID(%i), target = GetPlayerFromUserID(%i)})"
#define COMMANDABOT_RESET "CommandABot({cmd = 3, bot = GetPlayerFromUserID(%i)})"
// RockThrowSequence
#define SEQUENCE_ONEHAND 49
#define SEQUENCE_UNDERHAND 50
#define SEQUENCE_TWOHAND 51
// ZC_CLASS
#define ZC_SMOKER 1
#define ZC_BOOMER 2
#define ZC_HUNTER 3
#define ZC_SPITTER 4
#define ZC_JOCKEY 5
#define ZC_CHARGER 6
#define ZC_TANK 8
// Flags
#define FL_JUMPING 65922

// Enums
enum AimType
{
	AimEye,
	AimBody,
	AimChest
};

public Plugin myinfo =
{
	name 			= "Ai_Tank_Enhance",
	author 			= "Breezy，High Cookie，Standalone，Newteee，cravenge，Harry，Sorallll，PaimonQwQ，夜羽真白,东",
	description 	= "觉得Ai克太弱了？ Try this！",
	version 		= "2022-5-02",
	url 			= "https://steamcommunity.com/id/saku_ra/"
}

// ConVars
ConVar g_hTankBhop, g_hTankThrow, g_hTankThrowDist,g_hTankBlockThrowDist, g_hTankTarget, g_hTankBhopSpeed, g_hTreeDetect, g_hTreeNewTarget, g_hTankAirAngles, g_hTankAttackRange
, g_hTankConsumeHeight, g_hTankConsumLimit, g_hTankConsumeRaidus, g_hTankAttackVomitedNum, g_hVomitCanInstantAttack, g_hVomitAttackInterval, g_hTeleportForwardPercent
, g_hVsBossFlowBuffer, g_hTankConsumeLimitNum, g_hTankThrowForce, g_hTankConsume, g_hTankConsumeType, g_hTankRetreatAirAngles, g_hTankConsumeAction, g_hTankConsumeDamagePercent
, g_hTankForceAttackDistance, g_hTankConsumeHealthLimit, g_hTankAttackIncapped, g_hTankConsumeValidRaidus, g_hTankConsumeDistance, g_hSiLimit, g_hTankStopDistance;
// Ints
int g_iTankTarget, g_iTankThrowDist, g_iTankBlockThrowDist, g_iTreeDetect, g_iTreePlayer[MAXPLAYERS + 1] = -1, g_iTreeNewTarget, g_iTankConsumeLimit
, g_iTankConsumeRaidus, g_iTankAttackVomitedNum, g_iVomitedPlayer = 0, g_iTeleportForwardPercent, g_iTankConsumeSurvivorProgress[MAXPLAYERS + 1] = 0
, g_iTankConsumeNum, g_iTankConsumeLimitNum[MAXPLAYERS + 1] = 0, g_iTankConsumeType, g_iTankConsumeAction, g_iTankConsumeDamagePercent, g_iTankForceAttackDistance, g_iTankConsumeHealthLimit, g_iTankAttackIncapped
, g_iTankConsumeValidRaidus, g_iTankConsumeDistance, g_iTankIncappedCount[MAXPLAYERS + 1][1], g_iTankConsumeValidPos[MAXPLAYERS + 1][1], g_iTankSecondAttackDistance[MAXPLAYERS + 1][1]
, g_iDistanceCount[MAXPLAYERS + 1][1], g_iTankUnstuckTimes[MAXPLAYERS + 1][2], g_iSiLimit = 0, g_iTankStopDistance;

// Bools
bool g_bTankBhop, g_bTankThrow, g_bCanTankConsume[MAXPLAYERS + 1] = false, g_bInConsumePlace[MAXPLAYERS + 1] = false, g_bReturnConsumePlace[MAXPLAYERS + 1] = false, g_bCanTankAttack[MAXPLAYERS + 1] = true
, g_bVomitCanInstantAttack, g_bVomitCanConsume[MAXPLAYERS + 1] = false, g_bTankConsume, g_bIsFirstConsumeCheck[MAXPLAYERS + 1] = true, g_bDistanceHandle[MAXPLAYERS + 1] = false
, g_bTankActionReset[MAXPLAYERS + 1] = false;
// Floats
float g_fTankBhopSpeed, g_fTankAirAngles, g_fTankAttackRange, g_fTreePlayerOriginPos[3], g_fTankConsumeHeight, g_fConsumePosition[MAXPLAYERS + 1][3]
, g_fTeleportPosition[MAXPLAYERS + 1][3], g_fVomitAttackInterval, g_fRunTopSpeed[MAXPLAYERS + 1], g_fTankRetreatAirAngles;
// Handles
Handle g_hDistanceTimer[MAXPLAYERS + 1] = INVALID_HANDLE;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion Engine = GetEngineVersion();
	if (Engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "当前插件仅适用于 Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	CreateNative("IsTankInConsume", Native_IsTankInConsume);
	CreateNative("IsTankInConsumePlace", Native_IsTankInConsumePlace);
	RegPluginLibrary("tankconsume");
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hTankBhopSpeed = CreateConVar("ai_Tank_BhopSpeed", "60.0", "Tank连跳的速度", FCVAR_NOTIFY, true, 0.0);
	g_hTankStopDistance = CreateConVar("ai_Tank_StopDistance", "130", "Tank在距离目标多远位置停下来", FCVAR_NOTIFY, true, 0.0);
	g_hTankBhop = CreateConVar("ai_Tank_Bhop", "1", "是否开启Tank连跳功能：0=关闭，1=开启", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hTankThrow = CreateConVar("ai_Tank_Throw", "1", "是否允许Tank投掷石块：0=关闭，1=开启", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hTankThrowDist = CreateConVar("ai_TankThrowDistance", "450", "Tank距离目标多近允许投掷石块", FCVAR_NOTIFY, true, 0.0);
	g_hTankBlockThrowDist = CreateConVar("ai_TankBlockThrowDistance", "200", "Tank距离目标多近时阻止投掷石块", FCVAR_NOTIFY, true, 0.0);
	g_hTankTarget = CreateConVar("ai_TankTarget", "1", "Tank目标选择：1=最近，2=血量最少，3=血量最多", FCVAR_NOTIFY, true, 1.0, true, 3.0);
	g_hTreeDetect = CreateConVar("ai_TankTreeDetect", "1", "生还者与Tank进行秦王绕柱时进行的操作：0=关闭此项，1=切换目标，2=将Tank传送至绕树的生还者后", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	g_hTreeNewTarget = CreateConVar("ai_TankTreeNewTargetDistance", "300", "Tank记录绕树生还者并选择新目标后，距离新目标多近重置绕树目标记录", FCVAR_NOTIFY, true, 0.0);
	g_hTankAirAngles = CreateConVar("ai_TankAirAngles", "60.0", "Tank在空中的速度向量与到生还者的方向向量夹角大于这个值停止连跳", FCVAR_NOTIFY, true, 0.0, true, 90.0);
	g_hTankConsume = CreateConVar("ai_TankConsume", "0", "是否开启Tank消耗功能", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hTankConsumeHeight = CreateConVar("ai_TankConsumeHeight", "100", "Tank进行消耗时将会优先选择高于这个高度的位置，如无则随机选位", FCVAR_NOTIFY, true, 0.0);
	g_hTankConsumLimit = CreateConVar("ai_TankConsumeLimit", "0", "感染者团队少于等于当前刷特数量 - 这个值的特感时", FCVAR_NOTIFY, true, 0.0);
	g_hTankConsumeRaidus = CreateConVar("ai_TankConsumeRaidus", "80.0", "Tank消耗位置的范围，从中心坐标以这个半径画圆", FCVAR_NOTIFY, true, 0.0);
	g_hTankAttackVomitedNum = CreateConVar("ai_TankAttackVomitedNum", "1", "如果有这个数量的生还者被Boomer喷吐到，正在进行消耗的Tank将会攻击", FCVAR_NOTIFY, true, 0.0);
	g_hVomitCanInstantAttack = CreateConVar("ai_TankVomitCanInstantAttack", "1", "是否开启固定数量生还者被喷吐后Tank立刻攻击", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hVomitAttackInterval = CreateConVar("ai_TankVomitAttackInterval", "20.0", "从开始被喷且Tank允许攻击时开始，这个时间内Tank允许攻击", FCVAR_NOTIFY, true, 0.0);
	g_hTeleportForwardPercent = CreateConVar("ai_TankTeleportForwardPercent", "10", "Tank开始消耗时，记录此时生还者行进距离x，生还者前压超过x + 这个值时，Tank会传送至生还者处进行压制", FCVAR_NOTIFY, true, 0.0);
	g_hTankConsumeLimitNum = CreateConVar("ai_TankConsumeLimitNum", "5", "Tank最多进行消耗的次数（找到一次消耗位并抵达消耗位算 1 次消耗）", FCVAR_NOTIFY, true, 0.0);
	g_hTankConsumeType = CreateConVar("ai_TankConsumeType", "6", "Tank进行消耗将会按照哪种特感类型找位：1=Smoker，2=Boomer，3=Hunter，4=Spitter，5=Jockey，6=Charger，8=Tank", FCVAR_NOTIFY, true, 1.0, true, 8.0);
	g_hTankRetreatAirAngles = CreateConVar("ai_TankRetreatAirAngles", "75.0", "Tank在回避的连跳过程中视角与速度超过这个值将会停止连跳", FCVAR_NOTIFY, true, 0.0);
	g_hTankConsumeAction = CreateConVar("ai_TankConsumeAction", "2", "Tank在消耗范围内将会：1=冰冻，2=可活动但不允许超出消耗范围", FCVAR_NOTIFY, true, 1.0, true, 2.0);
	g_hTankConsumeDamagePercent = CreateConVar("ai_TankConsumeDamagePercent", "50", "Tank在消耗过程中只会受到这个百分比的伤害", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	// 2022-4-7新增
	g_hTankForceAttackDistance = CreateConVar("ai_TankForceAttackDistance", "300", "Tank在离最近生还这个距离时即使可以消耗也不会当着生还的面回避生还（强制压制）", FCVAR_NOTIFY, true, 0.0);
	g_hTankAttackIncapped = CreateConVar("ai_TankIncappedCount", "1", "强制压制时，需要拍倒这个数量的生还者才允许继续检测是否可以消耗", FCVAR_NOTIFY, true, 0.0);
	g_hTankConsumeHealthLimit = CreateConVar("ai_TankConsumeHealthLimit", "1200", "Tank在少于这么多血量时不会消耗", FCVAR_NOTIFY, true, 0.0);
	g_hTankConsumeValidRaidus = CreateConVar("ai_TankConsumeValidRaidus", "1800", "Tank在当前消耗位上，如果当前消耗位不能直视生还，则以这个半径重新找位", FCVAR_NOTIFY, true, 0.0);
	g_hTankConsumeDistance = CreateConVar("ai_TankConsumeDistance", "1200", "Tank消耗找位的位置必须离生还者大于这个距离", FCVAR_NOTIFY, true, 0.0);
	// 其他 Cvar
	g_hTankAttackRange = FindConVar("tank_attack_range");
	g_hVsBossFlowBuffer = FindConVar("versus_boss_buffer");
	g_hTankThrowForce = FindConVar("z_tank_throw_force");
	g_hSiLimit = FindConVar("l4d_infected_limit");
	// HookEvents
	HookEvent("player_spawn", evt_PlayerSpawn);
	HookEvent("player_death", evt_PlayerDeath);
	HookEvent("player_now_it", evt_PlayerNowIt);
	HookEvent("player_incapacitated", evt_PlayerIncapped);
	// AddChangeHook
	g_hTankStopDistance.AddChangeHook(ConVarChanged_Cvars);
	g_hSiLimit.AddChangeHook(ConVarChanged_Cvars);
	g_hTankBhop.AddChangeHook(ConVarChanged_Cvars);
	g_hTankThrow.AddChangeHook(ConVarChanged_Cvars);
	g_hTankThrowDist.AddChangeHook(ConVarChanged_Cvars);
	g_hTankBlockThrowDist.AddChangeHook(ConVarChanged_Cvars);
	g_hTankTarget.AddChangeHook(ConVarChanged_Cvars);
	g_hTreeDetect.AddChangeHook(ConVarChanged_Cvars);
	g_hTreeNewTarget.AddChangeHook(ConVarChanged_Cvars);
	g_hTankBhopSpeed.AddChangeHook(ConVarChanged_Cvars);
	g_hTankAirAngles.AddChangeHook(ConVarChanged_Cvars);
	g_hTankAttackRange.AddChangeHook(ConVarChanged_Cvars);
	g_hTankConsumeHeight.AddChangeHook(ConVarChanged_Cvars);
	g_hTankConsumLimit.AddChangeHook(ConVarChanged_Cvars);
	g_hTankConsumeRaidus.AddChangeHook(ConVarChanged_Cvars);
	g_hTankAttackVomitedNum.AddChangeHook(ConVarChanged_Cvars);
	g_hVomitCanInstantAttack.AddChangeHook(ConVarChanged_Cvars);
	g_hVomitAttackInterval.AddChangeHook(ConVarChanged_Cvars);
	g_hTeleportForwardPercent.AddChangeHook(ConVarChanged_Cvars);
	g_hTankConsumeLimitNum.AddChangeHook(ConVarChanged_Cvars);
	g_hVsBossFlowBuffer.AddChangeHook(ConVarChanged_Cvars);
	g_hTankThrowForce.AddChangeHook(ConVarChanged_Cvars);
	g_hTankConsume.AddChangeHook(ConVarChanged_Cvars);
	g_hTankConsumeType.AddChangeHook(ConVarChanged_Cvars);
	g_hTankRetreatAirAngles.AddChangeHook(ConVarChanged_Cvars);
	g_hTankConsumeAction.AddChangeHook(ConVarChanged_Cvars);
	g_hTankConsumeDamagePercent.AddChangeHook(ConVarChanged_Cvars);
	g_hTankForceAttackDistance.AddChangeHook(ConVarChanged_Cvars);
	g_hTankConsumeHealthLimit.AddChangeHook(ConVarChanged_Cvars);
	g_hTankAttackIncapped.AddChangeHook(ConVarChanged_Cvars);
	g_hTankConsumeValidRaidus.AddChangeHook(ConVarChanged_Cvars);
	g_hTankConsumeDistance.AddChangeHook(ConVarChanged_Cvars);
	// GetConVar
	GetCvars();
	// 数组初始化
	for (int i = 0; i < MAXPLAYERS + 1; i++)
	{
		for (int j = 0; j < 3; j++)
		{
			g_fConsumePosition[i][j] = 0.0;
			g_fTeleportPosition[i][j] = 0.0;
		}
	}
	// Debug
	RegAdminCmd("sm_con", Cmd_Consume, ADMFLAG_BAN);
}

// **************
//		指令
// **************
public Action Cmd_Consume(int client, int args)
{
	if (client && client <= MaxClients && IsClientInGame(client))
	{
		int iTank;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsAiTank(i))
			{
				iTank = i;
			}
		}
		float tankpos[3] = {0.0};
		GetClientAbsOrigin(iTank, tankpos);
		DoConsume(iTank, tankpos);
	}
}

// 向量绘制
#include "vector/vector_show.sp"

// ******************
//		Natives
// ******************
public int Native_IsTankInConsume(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return g_bCanTankConsume[client];
}

public int Native_IsTankInConsumePlace(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return g_bInConsumePlace[client];
}

// *********************
//		获取Cvar值
// *********************
void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bTankBhop = g_hTankBhop.BoolValue;
	g_iTankStopDistance = g_hTankStopDistance.IntValue;
	g_bTankThrow = g_hTankThrow.BoolValue;
	g_iTankTarget = g_hTankTarget.IntValue;
	g_iTankThrowDist = g_hTankThrowDist.IntValue;
	g_iTankBlockThrowDist = g_hTankBlockThrowDist.IntValue;
	g_iTreeDetect = g_hTreeDetect.IntValue;
	g_iTreeNewTarget = g_hTreeNewTarget.IntValue;
	g_fTankBhopSpeed = g_hTankBhopSpeed.FloatValue;
	g_fTankAirAngles = g_hTankAirAngles.FloatValue;
	g_fTankAttackRange = g_hTankAttackRange.FloatValue;
	g_fTankConsumeHeight = g_hTankConsumeHeight.FloatValue;
	g_iTankConsumeLimit = g_hTankConsumLimit.IntValue;
	g_iTankConsumeRaidus = g_hTankConsumeRaidus.IntValue;
	g_iTankAttackVomitedNum = g_hTankAttackVomitedNum.IntValue;
	g_bVomitCanInstantAttack = g_hVomitCanInstantAttack.BoolValue;
	g_fVomitAttackInterval = g_hVomitAttackInterval.FloatValue;
	g_iTeleportForwardPercent = g_hTeleportForwardPercent.IntValue;
	g_iTankConsumeNum = g_hTankConsumeLimitNum.IntValue;
	g_bTankConsume = g_hTankConsume.BoolValue;
	g_iTankConsumeType = g_hTankConsumeType.IntValue;
	g_fTankRetreatAirAngles = g_hTankRetreatAirAngles.FloatValue;
	g_iTankConsumeAction = g_hTankConsumeAction.IntValue;
	g_iTankConsumeDamagePercent = g_hTankConsumeDamagePercent.IntValue;
	g_iTankForceAttackDistance = g_hTankForceAttackDistance.IntValue;
	g_iTankConsumeHealthLimit = g_hTankConsumeHealthLimit.IntValue;
	g_iTankAttackIncapped = g_hTankAttackIncapped.IntValue;
	g_iTankConsumeValidRaidus = g_hTankConsumeValidRaidus.IntValue;
	g_iTankConsumeDistance = g_hTankConsumeDistance.IntValue;
	g_iSiLimit = g_hSiLimit.IntValue;
}

// **************
//		主要
// **************
// 坦克扔石头力度大小，跳砖设置，在消耗位上时，不允许跳砖
public Action L4D_OnCThrowActivate(int ability)
{
	SetConVarString(FindConVar("z_tank_throw_force"), "1000");
	int tankclient = GetEntPropEnt(ability, Prop_Data, "m_hOwnerEntity");
	if (IsAiTank(tankclient) && GetEntProp(tankclient, Prop_Send, "m_zombieClass") == ZC_TANK && !g_bCanTankConsume[tankclient] && g_bCanTankAttack[tankclient])
	{
		RequestFrame(NextFrame_JumpRock, tankclient);
	}
	return Plugin_Continue;
}

void NextFrame_JumpRock(int tankclient)
{
	if (IsAiTank(tankclient))
	{
		float tankpos[3] = {0.0};
		GetClientAbsOrigin(tankclient, tankpos);
		int target = GetClosestSurvivor(tankpos);
		if (IsSurvivor(target))
		{
			int flags = GetEntityFlags(tankclient);
			if (flags & FL_ONGROUND)
			{
				float eyeangles[3] = 0.0, lookat[3] = 0.0;
				GetClientEyeAngles(tankclient, eyeangles);
				GetAngleVectors(eyeangles, lookat, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(lookat, lookat);
				ScaleVector(lookat, 300.0);
				lookat[2] = 300.0;
				TeleportEntity(tankclient, NULL_VECTOR, NULL_VECTOR, lookat);
			}
		}
	}
}

public Action OnPlayerRunCmd(int tank, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsAiTank(tank))
	{
		float fTankPos[3] = {0.0}, fSpeed[3] = {0.0}, fCurrentSpeed = 0.0, fAngles[3] = {0.0};
		GetClientAbsOrigin(tank, fTankPos);
		int iSurvivorDistance, iTarget, iFlags, iNearestTarget, iInfectedCount = GetInfectedCount(), survivorcount = GetSurvivorCount();
		iSurvivorDistance = GetSurvivorDistance(fTankPos);	iTarget = GetClientAimTarget(tank, true);	iNearestTarget = GetClosestSurvivor(fTankPos);
		// 获取坦克状态，速度
		iFlags = GetEntityFlags(tank);
		GetEntPropVector(tank, Prop_Data, "m_vecVelocity", fSpeed);
		fCurrentSpeed = SquareRoot(Pow(fSpeed[0], 2.0) + Pow(fSpeed[1], 2.0));
		bool bHasSight = view_as<bool>(GetEntProp(tank, Prop_Send, "m_hasVisibleThreats"));
		// 是否允许投掷石块？
		if (g_bTankThrow)
		{
			if (iSurvivorDistance > g_iTankThrowDist || iSurvivorDistance < g_iTankBlockThrowDist)
			{
				buttons &= ~IN_ATTACK2;
			}
		}
		else
		{
			buttons &= ~IN_ATTACK2;
		}
		if (IsSurvivor(iTarget))
		{
			if (bHasSight && !g_bCanTankConsume[tank] && g_bCanTankAttack[tank] && iSurvivorDistance < g_iTankBlockThrowDist && IsSurvivor(iNearestTarget))
			{
				float TargetAngles[3] = {0.0};
				ComputeAimAngles(tank, iNearestTarget, TargetAngles, AimChest);
				TargetAngles[2] = 0.0;
				TeleportEntity(tank, NULL_VECTOR, TargetAngles, NULL_VECTOR);
			}
			// 连跳操作
			if (g_bTankBhop)
			{
				// 计算坦克与目标之间的距离
				float fBuffer[3] = {0.0}, fTargetPos[3] = {0.0};
				GetClientAbsOrigin(iTarget, fTargetPos);
				fBuffer = UpdatePosition(tank, iTarget, g_fTankBhopSpeed);
				if (g_iTankStopDistance < iSurvivorDistance < 2000 && fCurrentSpeed > 190.0)
				{
					if (iFlags & FL_ONGROUND)
					{
						buttons |= IN_JUMP;
						buttons |= IN_DUCK;
						if (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT)
						{
							ClientPush(tank, fBuffer);
						}
					}
					else if (iFlags == FL_JUMPING)
					{
						if (!g_bCanTankConsume[tank] && g_bCanTankAttack[tank] && iSurvivorDistance * 0.90 > g_fTankAttackRange)
						{
							float fAnglesPost[3];
							GetVectorAngles(fSpeed, fAngles);
							fAnglesPost = fAngles;
							fAngles[0] = fAngles[2] = 0.0;
							GetAngleVectors(fAngles, fAngles, NULL_VECTOR, NULL_VECTOR);
							NormalizeVector(fAngles, fAngles);
							// 保存当前位置
							static float fDirection[2][3];
							fDirection[0] = fTankPos;
							fDirection[1] = fTargetPos;
							fTankPos[2] = fTargetPos[2] = 0.0;
							MakeVectorFromPoints(fTankPos, fTargetPos, fTankPos);
							NormalizeVector(fTankPos, fTankPos);
							// 计算距离
							if (RadToDeg(ArcCosine(GetVectorDotProduct(fAngles, fTankPos))) < g_fTankAirAngles)
							{
								return Plugin_Continue;
							}
							// 重新设置速度方向
							float fNewVelocity[3];
							MakeVectorFromPoints(fDirection[0], fDirection[1], fNewVelocity);
							NormalizeVector(fNewVelocity, fNewVelocity);
							ScaleVector(fNewVelocity, fCurrentSpeed);
							TeleportEntity(tank, NULL_VECTOR, fAnglesPost, fNewVelocity);
						}
					}
				}
			}
		}
		else
		{
			if (g_bCanTankConsume[tank] && !g_bCanTankAttack[tank] && !g_bInConsumePlace[tank] && bHasLeftRoundPoint(g_fConsumePosition[tank], fTankPos, g_iTankConsumeRaidus * 3))
			{
				// 逃跑时，前往消耗位的途中连跳，在消耗位时不允许连跳，减少从消耗位里跳出来的概率
				float fTankEyeAngles[3], fForwardVec[3];
				GetClientEyeAngles(tank, fTankEyeAngles);
				GetAngleVectors(fTankEyeAngles, fForwardVec, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(fForwardVec, fForwardVec);
				ScaleVector(fForwardVec, g_fTankBhopSpeed);
				if (g_bCanTankConsume[tank] && !g_bInConsumePlace[tank])
				{
					if (g_bTankBhop)
					{
						if (iFlags & FL_ONGROUND && fCurrentSpeed > 190.0)
						{
							buttons |= IN_JUMP;
							buttons |= IN_DUCK;
							if (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT)
							{
								ClientPush(tank, fForwardVec);
							}

						}
						else if (iFlags == FL_JUMPING)
						{
							float fRetreatAnglePost[3];
							GetVectorAngles(fSpeed, fAngles);
							fRetreatAnglePost = fAngles;
							fAngles[0] = fAngles[2] = 0.0;
							GetAngleVectors(fAngles, fAngles, NULL_VECTOR, NULL_VECTOR);
							NormalizeVector(fAngles, fAngles);
							static float fEyeAngles[3];
							GetClientEyeAngles(tank, fEyeAngles);
							fEyeAngles[0] = fEyeAngles[2] = 0.0;
							GetAngleVectors(fEyeAngles, fEyeAngles, NULL_VECTOR, NULL_VECTOR);
							NormalizeVector(fEyeAngles, fEyeAngles);
							if (RadToDeg(ArcCosine(GetVectorDotProduct(fAngles, fEyeAngles))) < g_fTankRetreatAirAngles)
							{
								return Plugin_Continue;
							}
							TeleportEntity(tank, NULL_VECTOR, fRetreatAnglePost, fSpeed);
						}
					}
				}
			}
		}
		// 消耗操作
		if (g_bTankConsume)
		{
			if (!g_bIsFirstConsumeCheck[tank])
			{
				CheckCanTankConsume(tank, iSurvivorDistance, iInfectedCount);
			}
			// 射线找消耗位条件：
			// 1.当前坦克允许消耗，且没有找到有效消耗位，不在消耗位上时
			// 2.当前坦克进入到消耗位中，且消耗位不可直视所有生还
			// 3.允许消耗在消耗位上时，可直视生还，距离超过 g_iTankForceAttackDistance + 500 且路程在生还前方
			if ((g_bCanTankConsume[tank] && !g_bCanTankAttack[tank] && !g_bInConsumePlace[tank] && g_fConsumePosition[tank][0] == 0.0) 
			|| (g_bInConsumePlace[tank] && g_iTankConsumeValidPos[tank][0] == survivorcount) 
			|| (g_bInConsumePlace[tank] && bHasSight && iSurvivorDistance < g_iTankForceAttackDistance + 500 && IsPosAhead(fTankPos)))
			{
				float nearestpos[3] = {0.0}, rayangles[3] = {0.0}, mins[2] = {0.0}, maxs[2] = {0.0}, rayz = 0.0, raypos[3] = {0.0};
				rayangles[0] = 90.0;
				if (IsSurvivor(iNearestTarget))
				{
					GetClientAbsOrigin(iNearestTarget, nearestpos);
					mins[0] = nearestpos[0];	mins[1] = nearestpos[1];
					maxs[0] = nearestpos[0];	maxs[1] = nearestpos[1];
					mins[0] -= float(g_iTankConsumeValidRaidus);
					mins[1] -= float(g_iTankConsumeValidRaidus);
					maxs[0] += float(g_iTankConsumeValidRaidus);
					maxs[1] += float(g_iTankConsumeValidRaidus);
					raypos[0] = GetRandomFloat(mins[0], maxs[0]);
					raypos[1] = GetRandomFloat(mins[1], maxs[1]);
					rayz = g_fConsumePosition[tank][2] + 500.0;
					raypos[2] = GetRandomFloat(g_fConsumePosition[tank][2], rayz);
					TR_TraceRay(raypos, rayangles, MASK_NPCSOLID_BRUSHONLY, RayType_Infinite);
					if (TR_DidHit())
					{
						float endpos[3] = {0.0}, survivoreyepos[3] = {0.0};
						TR_GetEndPosition(endpos);
						endpos[2] += 110.0;
						#if (DEBUG_DOWNLINE)
							ShowLaser(4, raypos, endpos);
						#endif
						for (int survivor = 1; survivor <= MaxClients; survivor++)
						{
							if (IsClientConnected(survivor) && IsClientInGame(survivor) && GetClientTeam(survivor) == TEAM_SURVIVOR)
							{
								GetClientEyePosition(survivor, survivoreyepos);
								Handle hSecondTrace = TR_TraceRayFilterEx(endpos, survivoreyepos, MASK_ALL, RayType_EndPoint, Trace_FilterNoPlayers, tank);
								#if (DEBUG_EYELINE)
									ShowLaser(2, endpos, survivoreyepos);
								#endif
								if (!TR_DidHit(hSecondTrace))
								{
									if (GetVectorDistance(endpos, survivoreyepos) >= float(g_iTankConsumeDistance) 
									&& L4D2_VScriptWrapper_NavAreaBuildPath(fTankPos, endpos, g_iTankConsumeValidRaidus + 1000.0, false, false, TEAM_INFECTED, false) && !IsPlayerStuck(endpos, tank) 
									&& IsPosAhead(endpos) && endpos[2] - fTankPos[2] >= g_fTankConsumeHeight)
									{
										PrintToConsoleAll("[Ai-Tank]：当前消耗位置无法直视生还，新位置：%.2f，%.2f，%.2f，距离：%.2f，是否在生还路程前？%b"
										, endpos[0], endpos[1], endpos[2] - 110.0, GetVectorDistance(endpos, survivoreyepos), IsPosAhead(endpos));
										g_fConsumePosition[tank][0] = endpos[0];
										g_fConsumePosition[tank][1] = endpos[1];
										g_fConsumePosition[tank][2] = endpos[2];
										if (g_bCanTankConsume[tank] && !g_bCanTankAttack[tank])
										{
											Logic_RunScript(COMMANDABOT_MOVE, g_fConsumePosition[tank][0], g_fConsumePosition[tank][1], g_fConsumePosition[tank][2], GetClientUserId(tank));
											g_iTankConsumeValidPos[tank][0] = 0;
											g_bInConsumePlace[tank] = false;
											delete hSecondTrace;
											break;
										}
									}
								}
								delete hSecondTrace;
							}
							else
							{
								continue;
							}
						}
					}
				}
			}
			// 消耗位置判断，有消耗位置时，执行以下内容，否则不执行，只用判断 x 即可，x 为零，其他必为零
			if (g_fConsumePosition[tank][0] != 0.0)
			{
				float survivorpos[3] = {0.0};
				if (!g_bInConsumePlace[tank])
				{
					// 为假，则坦克进入了范围内
					if (!bHasLeftRoundPoint(g_fConsumePosition[tank], fTankPos, g_iTankConsumeRaidus))
					{
						buttons &= ~IN_JUMP;
						buttons &= ~IN_DUCK;
						buttons |= IN_ATTACK2;
						PrintToConsoleAll("[Ai-Tank]：当前克进入到了消耗范围中，半径：%d", g_iTankConsumeRaidus);
						// 重设当前坦克锤倒人数与状态
						g_iTankIncappedCount[tank][0] = 0;
						g_bInConsumePlace[tank] = true;
						g_bReturnConsumePlace[tank] = false;
						g_bDistanceHandle[tank] = false;
						// 循环判断是否可视生还，如果所有生还均不可直视，则更换消耗位
						if (g_hDistanceTimer[tank] != INVALID_HANDLE)
						{
							delete g_hDistanceTimer[tank];
							g_hDistanceTimer[tank] = INVALID_HANDLE;
						}
						for (int survivor = 1; survivor <= MaxClients; survivor++)
						{
							if (IsClientConnected(survivor) && IsClientInGame(survivor) && GetClientTeam(survivor) == TEAM_SURVIVOR && IsPlayerAlive(survivor))
							{
								float rockpos[3] = {0.0};
								rockpos[0] = g_fConsumePosition[tank][0]; rockpos[1] = g_fConsumePosition[tank][1]; rockpos[2] = g_fConsumePosition[tank][2] + 110.0;
								GetClientEyePosition(survivor, survivorpos);
								Handle hTrace = TR_TraceRayFilterEx(rockpos, survivorpos, MASK_SHOT, RayType_EndPoint, Trace_FilterNoPlayers, tank);
								if (TR_DidHit(hTrace))
								{
									g_iTankConsumeValidPos[tank][0] += 1;
									if (g_iTankConsumeValidPos[tank][0] > survivorcount)
									{
										g_iTankConsumeValidPos[tank][0] = survivorcount;
									}
								}
								delete hTrace;
							}
							else
							{
								continue;
							}
						}
						PrintToConsoleAll("[Ai-Tank]：当前视线不可直接可视生还人数：%d", g_iTankConsumeValidPos[tank][0]);
						switch (g_iTankConsumeAction)
						{
							case 1:
							{
								SetEntityMoveType(tank, MOVETYPE_NONE);
							}
							case 2:
							{
								buttons |= IN_ATTACK2;
							}
						}
					}
					// 为真，坦克还没有进到消耗范围内，检测是否卡住
					else
					{
						if (IsPlayerStuck(fTankPos, tank) && iTarget == -1 && iFlags != FL_JUMPING || GetEntityMoveType(tank) != MOVETYPE_LADDER && !IsTankAttacking(tank) && fCurrentSpeed < 50.0)
						{
							bool bHasFind = false;
							float newpos[3] = {0.0};
							g_iTankUnstuckTimes[tank][0] += 1;
							if (g_iTankUnstuckTimes[tank][0] > TANK_UNSTUCK_TRIES)
							{
								Address pNowNav = L4D2Direct_GetTerrorNavArea(fTankPos);
								if (pNowNav == Address_Null)
								{
									bHasFind = L4D_GetRandomPZSpawnPosition(tank, g_iTankConsumeType, 50, newpos);
									if (bHasFind)
									{
										TeleportEntity(tank, newpos, NULL_VECTOR, NULL_VECTOR);
									}
									return Plugin_Stop;
								}
								buttons |= IN_ATTACK;
								buttons |= IN_FORWARD;
								TeleportSmooth(tank);
								bHasFind = L4D_GetRandomPZSpawnPosition(tank, g_iTankConsumeType, 50, newpos);
								if (bHasFind)
								{
									PrintToConsoleAll("[Ai-Tank]：当前克卡住，重新执行找位，位置：%.2f，%.2f，%.2f", newpos[0], newpos[1], newpos[2]);
									Logic_RunScript(COMMANDABOT_MOVE, newpos[0], newpos[1], newpos[2], GetClientUserId(tank));
									TankActionReset(tank);
								}
								g_iTankUnstuckTimes[tank][0] = 0;
								return Plugin_Stop;
							}
						}
						else if (g_iTankUnstuckTimes[tank][0] == g_iTankUnstuckTimes[tank][0])
						{
							g_iTankUnstuckTimes[tank][1] += 1;
							if (g_iTankUnstuckTimes[tank][1] >= 50)
							{
								g_iTankUnstuckTimes[tank][0] = 0;
								g_iTankUnstuckTimes[tank][1] = 0;
							}
						}
					}
				}
				else
				{
					if (bHasLeftRoundPoint(g_fConsumePosition[tank], fTankPos, g_iTankConsumeRaidus))
					{
						g_bInConsumePlace[tank] = false;
						// 出了消耗范围，重新进入
						if (g_bCanTankConsume[tank] && !g_bCanTankAttack[tank])
						{
							if (!g_bReturnConsumePlace[tank])
							{
								buttons &= ~IN_JUMP;
								buttons &= ~IN_DUCK;
								Logic_RunScript(COMMANDABOT_MOVE, g_fConsumePosition[tank][0], g_fConsumePosition[tank][1], g_fConsumePosition[tank][2], GetClientUserId(tank));
								g_bReturnConsumePlace[tank] = true;
							}
						}
					}
				}
			}
			// 消耗时生还者前压判断
			if (g_bCanTankConsume[tank] && !g_bCanTankAttack[tank])
			{
				// 当前路程大于等于开始消耗的路程加给定路程，生还者前压，找位传送
				int iNowSurvivorPercent = RoundToNearest(GetBossProximity() * 100.0);
				if (iNowSurvivorPercent >= g_iTankConsumeSurvivorProgress[tank] + g_iTeleportForwardPercent && !IsPosAhead(fTankPos))
				{
					bool bHasFind = L4D_GetRandomPZSpawnPosition(iNearestTarget, ZC_TANK, 50, g_fTeleportPosition[tank]);
					if (bHasFind && g_fTeleportPosition[tank][0] != 0.0)
					{
						//PrintToConsoleAll("[Ai-Tank]：当前克路程小于生还者当前路程：%d 且在后面，传送", iNowSurvivorPercent);
						TeleportEntity(tank, g_fTeleportPosition[tank], NULL_VECTOR, NULL_VECTOR);
						g_bCanTankConsume[tank] = false;
						g_bCanTankAttack[tank] = true;
					}
				}
			}
		}
		// 着火时，自动灭火
		if (GetEntProp(tank, Prop_Data, "m_fFlags") & FL_ONFIRE)
		{
			ExtinguishEntity(tank);
		}
		// 梯子上，阻止跳跃和蹲下
		if (GetEntityMoveType(tank) & MOVETYPE_LADDER)
		{
			buttons &= ~IN_JUMP;
			buttons &= ~IN_DUCK;
		}
	}
	return Plugin_Continue;
}

// 重置坦克行动状态
void TankActionReset(int client)
{
	if (IsAiTank(client))
	{
		PrintToConsoleAll("[Ai-Tank]：重置当前克行为");
		SetConVarInt(FindConVar("z_tank_throw_interval"), 8);
		SetConVarInt(FindConVar("tank_throw_min_interval"), 8);
		if (g_bCanTankConsume[client] && !g_bCanTankAttack[client])
		{
			if (g_iTankConsumeAction == 1)
			{
				SetEntityMoveType(client, MOVETYPE_WALK);
			}
			g_bCanTankAttack[client] = true;
			g_bCanTankConsume[client] = false;
			g_bInConsumePlace[client] = false;
			g_bReturnConsumePlace[client] = false;
			g_fConsumePosition[client][0] = g_fConsumePosition[client][1] = g_fConsumePosition[client][2] = 0.0;
			Logic_RunScript(COMMANDABOT_RESET, GetClientUserId(client));
		}
	}
}

void CheckCanTankConsume(int tank, int survivordist, int iInfectedCount)
{
	float fTankPos[3] = {0.0};	GetClientAbsOrigin(tank, fTankPos);
	if (iInfectedCount <= g_iSiLimit - g_iTankConsumeLimit)
	{
		// 一定数量生还者被喷后，重新设置状态
		if (g_iVomitedPlayer >= g_iTankAttackVomitedNum && g_bVomitCanInstantAttack)
		{
			g_bCanTankConsume[tank] = false;
			g_bCanTankAttack[tank] = true;
			if (g_bTankActionReset[tank])
			{
				TankActionReset(tank);
				g_bTankActionReset[tank] = false;
			}
			if (!g_bVomitCanConsume[tank])
			{
				CreateTimer(g_fVomitAttackInterval, Timer_VomitAttackAgain, TIMER_FLAG_NO_MAPCHANGE);
				g_bVomitCanConsume[tank] = true;
			}
		}
		// 没有一定数量生还被喷，检测是否可以消耗
		else
		{
			bool bHasSight = view_as<bool>(GetEntProp(tank, Prop_Send, "m_hasVisibleThreats"));
			if (!bHasSight && !g_bCanTankConsume[tank] && g_bCanTankAttack[tank] && survivordist > g_iTankSecondAttackDistance[tank][0] && g_iTankConsumeLimitNum[tank] <= g_iTankConsumeNum && GetClientHealth(tank) > g_iTankConsumeHealthLimit)
			{
				//PrintToConsoleAll("[Ai-Tank]：正常消耗找位且不可直视生还，行 718，当前最近生还距离：%d，克强制压制距离：%d", survivordist, g_iTankSecondAttackDistance[tank][0]);
				DoConsume(tank, fTankPos);
				g_bVomitCanConsume[tank] = false;
			}
			// 最近生还者距离克小于限制距离
			if (survivordist <= g_iTankSecondAttackDistance[tank][0])
			{
				//PrintToConsoleAll("[Ai-Tank]：当前最近生还者离克最近距离：%d，限制距离：%d", survivordist, g_iTankSecondAttackDistance[tank][0]);
				// 如果克拍倒了大于限制人数的人，消耗次数小于限制，血量高于限制，则消耗，创建时钟检测最近生还与克的距离
				if (g_iTankIncappedCount[tank][0] >= g_iTankAttackIncapped && g_iTankConsumeLimitNum[tank] <= g_iTankConsumeNum && GetClientHealth(tank) > g_iTankConsumeHealthLimit)
				{
					if (!g_bCanTankConsume[tank] && g_bCanTankAttack[tank] && !g_bInConsumePlace[tank])
					{
						if (!g_bDistanceHandle[tank])
						{
							//PrintToConsoleAll("[Ai-Tank]：当前克拍倒：%d 人，大于限制：%d 人，创建时钟追踪是否有生还继续压制", g_iTankIncappedCount[tank][0], g_iTankIncappedCount);
							g_hDistanceTimer[tank] = CreateTimer(1.0, Timer_DistanceTrack, tank, TIMER_REPEAT);
							g_bDistanceHandle[tank] = true;
						}
						//PrintToConsoleAll("开始消耗");
						DoConsume(tank,fTankPos);
					}
					// 当前克可以消耗，但距离计数超过了 5 次，说明生还已经跟在克后面 5s，继续压制
					else if (g_bCanTankConsume[tank] && !g_bCanTankAttack[tank] && g_iDistanceCount[tank][0] >= 5)
					{
						//PrintToConsoleAll("[Ai-Tank]：当前有生还继续压制在克后多于：%d 次，强制压制", g_iDistanceCount[tank][0]);
						if (g_bTankActionReset[tank])
						{
							TankActionReset(tank);
							g_bTankActionReset[tank] = false;
							g_iTankIncappedCount[tank][0] = 0;
							g_iDistanceCount[tank][0] = 0;
							g_iTankSecondAttackDistance[tank][0] = g_iTankForceAttackDistance;
							if (g_hDistanceTimer[tank] != INVALID_HANDLE)
							{
								delete g_hDistanceTimer[tank];
								g_hDistanceTimer[tank] = INVALID_HANDLE;
							}
						}
					}
				}
				// 没有拍倒大于限制的人数，直接压制
				else
				{
					//PrintToConsoleAll("不符合消耗条件，当前拍倒人数：%d，限制：%d，血量：%d", g_iTankIncappedCount[tank][0], g_iTankIncappedCount, GetClientHealth(tank));
					if (g_bTankActionReset[tank])
					{
						//PrintToConsoleAll("[Ai-Tank]：当前克拍倒的人数：%d，小于限制人数：%d，强制压制", g_iTankIncappedCount[tank][0], g_iTankIncappedCount);
						TankActionReset(tank);
						g_bTankActionReset[tank] = false;
					}
				}
			}
			// 克消耗次数多于限制或血量少于限制血量，重置
			if (g_iTankConsumeLimitNum[tank] > g_iTankConsumeNum || GetClientHealth(tank) <= g_iTankConsumeHealthLimit)
			{
				if (g_bTankActionReset[tank])
				{
					//PrintToConsoleAll("[Ai-Tank]：当前克血量：%d，小于消耗血量：%d，强制压制", GetClientHealth(tank), g_iTankConsumeHealthLimit);
					TankActionReset(tank);
					g_bTankActionReset[tank] = false;
				}
			}
		}
	}
	else
	{
		if (g_bTankActionReset[tank])
		{
			//PrintToConsoleAll("[Ai-Tank]：当前特感数量：%d，多于消耗限制数量：%d，强制压制", iInfectedCount, g_iSiLimit - g_iTankConsumeLimit);
			TankActionReset(tank);
			g_bTankActionReset[tank] = false;
		}
	}
}

public Action Timer_DistanceTrack(Handle timer, int client)
{
	if (IsAiTank(client))
	{
		float tankpos[3] = {0.0};
		GetClientAbsOrigin(client, tankpos);
		int distance = GetSurvivorDistance(tankpos);
		if (distance < g_iTankSecondAttackDistance[client][0])
		{
			g_iDistanceCount[client][0] += 1;
		}
	}
}

void DoConsume(int client, float tankpos[3])
{
	if (IsAiTank(client))
	{
		int target = GetClosestSurvivor(tankpos);
		if (IsSurvivor(target))
		{
			int survivorpercent = RoundToNearest(GetBossProximity() * 100.0);
			g_iTankConsumeSurvivorProgress[client] = survivorpercent;
			// 设置状态
			g_iTankConsumeLimitNum[client] += 1;
			g_bCanTankConsume[client] = true;
			g_bCanTankAttack[client] = false;
			g_bTankActionReset[client] = true;
			SetConVarInt(FindConVar("z_tank_throw_interval"), 4);
			SetConVarInt(FindConVar("tank_throw_min_interval"), 4);
		}
	}
}

public Action Timer_VomitAttackAgain(Handle timer)
{
	g_iVomitedPlayer = 0;
}

// 选择目标时
public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{
	if (IsAiTank(specialInfected))
	{
		int newtarget = -1;
		int iButtons = GetClientButtons(specialInfected);
		// 有目标的情况
		if (IsSurvivor(curTarget))
		{
			float fTankPos[3];
			GetClientAbsOrigin(specialInfected, fTankPos);
			// 如果目标正在被控或倒地，则选择新目标
			if (IsPinned(curTarget) || IsIncapped(curTarget))
			{
				newtarget = TargetChoose(g_iTankTarget, specialInfected, curTarget);
				if (IsSurvivor(newtarget))
				{
					curTarget = newtarget;
					return Plugin_Changed;
				}
				else
				{
					return Plugin_Continue;
				}
			}
			if (GetSurvivorDistance(fTankPos, curTarget) < 170)
			{
				switch (g_iTreeDetect)
				{
					case 1:
					{
						bool bCanSee = IsVisible(specialInfected, curTarget);
						if (!bCanSee)
						{
							g_iTreePlayer[specialInfected] = curTarget;
							// 开始记录绕树生还原始位置并选择新目标
							GetClientAbsOrigin(curTarget, g_fTreePlayerOriginPos);
							newtarget = TargetChoose(g_iTankTarget, specialInfected, g_iTreePlayer[specialInfected]);
						}
						if (IsSurvivor(newtarget))
						{
							curTarget = newtarget;
							return Plugin_Changed;
						}
						else
						{
							return Plugin_Continue;
						}
					}
					// 搞传送
					case 2:
					{
						float fNewTargetPos[3], fNewTargetAngles[3];
						GetClientAbsOrigin(curTarget, fNewTargetPos);	GetClientEyeAngles(curTarget, fNewTargetAngles);
						TeleportEntity(specialInfected, fNewTargetPos, fNewTargetAngles, NULL_VECTOR);
						CPrintToChat(curTarget, "{R}<Tank>：{G}喜欢绕树是吧？");
						return Plugin_Continue;
					}
				}
			}
			else
			{
				// 绕树生还突然跑出来接近坦克，如果有绕树情况，则选择treeTarget，不执行此段，坦克选择新目标后，绕树生还突然追坦克，清空绕树保存目标重新选择
				if (IsSurvivor(g_iTreePlayer[specialInfected]))
				{
					float fTreePlayerNewPos[3];
					GetClientAbsOrigin(g_iTreePlayer[specialInfected], fTreePlayerNewPos);
					// PrintToChatAll("%d，半径%d", RoundToNearest((g_fTreePlayerOriginPos[0] - fTreePlayerNewPos[0]) * (g_fTreePlayerOriginPos[0] - fTreePlayerNewPos[0]) + (g_fTreePlayerOriginPos[1] - fTreePlayerNewPos[1]) * (g_fTreePlayerOriginPos[1] - fTreePlayerNewPos[1])), 225 * 225);
					if (!bHasLeftRoundPoint(g_fTreePlayerOriginPos, fTreePlayerNewPos, 225))
					{
						// 还在绕树啊？
						newtarget = TargetChoose(g_iTankTarget, specialInfected, g_iTreePlayer[specialInfected]);
						if (IsSurvivor(newtarget))
						{
							curTarget = newtarget;
							return Plugin_Changed;
						}
						else
						{
							return Plugin_Continue;
						}
					}
					else
					{
						if (GetSurvivorDistance(fTankPos, g_iTreePlayer[specialInfected]) < g_iTreeNewTarget)
						{
							SetEntProp(specialInfected, Prop_Data, "m_nButtons", iButtons |= IN_BACK);
							SetEntProp(specialInfected, Prop_Data, "m_nButtons", iButtons |= IN_FORWARD);
							SetEntProp(specialInfected, Prop_Data, "m_nButtons", iButtons |= IN_JUMP);
							// 检测绕树目标与坦克之间的距离，终于出来了
							g_iTreePlayer[specialInfected] = -1;
							for (int i = 0; i < 3; i++)
							{
								g_fTreePlayerOriginPos[i] = 0.0;
							}
							newtarget = TargetChoose(g_iTankTarget, specialInfected);
							if (IsSurvivor(newtarget))
							{
								curTarget = newtarget;
								return Plugin_Changed;
							}
							else
							{
								return Plugin_Continue;
							}
						}
					}
				}
				// 绕树保存目标为-1时的情况，没有人绕树，选择新目标，Tank刷新初始目标
				else
				{
					curTarget = TargetChoose(g_iTankTarget, specialInfected);
				}
			}
			// 坦克距离新目标小于g_iTreeNewTarget的距离时，重置绕树目标
			if (curTarget != g_iTreePlayer[specialInfected] && GetSurvivorDistance(fTankPos, curTarget) < g_iTreeNewTarget)
			{
				g_iTreePlayer[specialInfected] = -1;
			}
		}
		else{
			newtarget = TargetChoose(g_iTankTarget, specialInfected, curTarget);
		}
	}
	return Plugin_Continue;
}

// From：Sorallll（Ai_Tank.smx）：https://github.com/umlka/l4d2/blob/main/AI_HardSI/ai_tank.sp
public Action L4D_OnGetRunTopSpeed(int target, float &retVal)
{
	g_fRunTopSpeed[target] = retVal;
	return Plugin_Continue;
}

public Action L4D_TankRock_OnRelease(int tank, int rock, float vecPos[3], float vecAng[3], float vecVel[3], float vecRot[3])
{
	int iTarget = GetClientAimTarget(tank, true);
	if (iTarget > 0)
	{
		float fTargetPos[3], fRockPos[3], fVectors[3];
		GetClientAbsOrigin(iTarget, fTargetPos);
		GetClientAbsOrigin(tank, fRockPos);
		float fDelta = GetVectorDistance(fRockPos, fTargetPos) / GetConVarFloat(g_hTankThrowForce) * PLAYER_HEIGHT;
		fTargetPos[2] += fDelta;
		while(fDelta < PLAYER_HEIGHT)
		{
			if (!WillHitWall(tank, rock, -1, fTargetPos))
			{
				break;
			}
			fDelta += 10.0;
			fTargetPos[2] += 10.0;
		}
		fDelta = fTargetPos[2] - fRockPos[2];
		if (fDelta > PLAYER_HEIGHT)
		{
			fTargetPos[2] += fDelta / PLAYER_HEIGHT * 10.0;
		}
		GetClientEyePosition(tank, fRockPos);
		MakeVectorFromPoints(fRockPos, fTargetPos, fVectors);
		GetVectorAngles(fVectors, fTargetPos);
		TeleportEntity(rock, NULL_VECTOR, fTargetPos, NULL_VECTOR);
		static float vLength;
		vLength = GetVectorLength(fVectors);
		vLength = vLength > GetConVarFloat(g_hTankThrowForce) ? vLength : GetConVarFloat(g_hTankThrowForce);
		NormalizeVector(fVectors, fVectors);
		ScaleVector(fVectors, vLength + g_fRunTopSpeed[iTarget]);
		TeleportEntity(rock, fVectors, NULL_VECTOR, NULL_VECTOR);
	}
}

bool WillHitWall(int iTank, int iEntity, int iTarget = -1, const float vEndPos[3] = NULL_VECTOR)
{
	static float fSource[3], fTargetPos[3];
	GetClientEyePosition(iTank, fSource);
	// 无目标的情况，目标位置等于中止位置
	if (iTarget == -1)
	{
		fTargetPos = vEndPos;
	}
	else
	{
		GetClientEyePosition(iTarget, fTargetPos);
	}
	static float vMins[3], vMaxs[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecMins", vMins);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vMaxs);
	static bool bHit;
	static Handle hTrace;
	// 从坦克视角位置到目标视角位置发射射线，撞到实体返回真
	hTrace = TR_TraceHullFilterEx(fSource, fTargetPos, vMins, vMaxs, MASK_SOLID, Trace_EntityFilter);
	bHit = TR_DidHit(hTrace);
	delete hTrace;
	return bHit;
}


// **************
//		事件
// *************
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (IsAiTank(victim))
	{
		if (g_bCanTankConsume[victim])
		{
			if (GetRandomInt(1, 100) <= g_iTankConsumeDamagePercent)
			{
				return Plugin_Continue;
			}
			else
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public void evt_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsAiTank(client))
	{
		TankInitialization(client);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		if (g_bTankConsume)
		{
			CreateTimer(1.5, Timer_CheckCanConsume, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		if (g_hDistanceTimer[client] != INVALID_HANDLE)
		{
			delete g_hDistanceTimer[client];
			g_hDistanceTimer[client] = INVALID_HANDLE;
		}
	}
}

public Action Timer_CheckCanConsume(Handle timer, int client)
{
	if (IsAiTank(client) && g_bIsFirstConsumeCheck[client])
	{
		float tankpos[3] = {0.0};	GetClientAbsOrigin(client, tankpos);
		int dist = GetSurvivorDistance(tankpos);
		int iInfectedCount = GetInfectedCount();
		CheckCanTankConsume(client, dist, iInfectedCount);
		g_bIsFirstConsumeCheck[client] = false;
	}
}

public void evt_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsAiTank(client))
	{
		TankInitialization(client);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void evt_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
	int iTank = FindTank();
	if (IsAiTank(iTank))
	{
		// 坦克可以进行消耗或正在消耗，触发玩家被喷事件，计算被喷玩家数量
		if (g_bCanTankConsume[iTank] && !g_bCanTankAttack[iTank])
		{
			g_iVomitedPlayer += 1;
		}
	}
}

public void evt_PlayerIncapped(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (IsSurvivor(victim) && IsAiTank(attacker))
	{
		g_iTankIncappedCount[attacker][0] += 1;
		//PrintToConsoleAll("[Ai-Tank]：倒地：%N，攻击者：%N，目前：%d", victim, attacker, g_iTankIncappedCount[attacker][0]);
		g_iTankSecondAttackDistance[attacker][0] /= 2;
		if (g_iTankSecondAttackDistance[attacker][0] < 150)
		{
			g_iTankSecondAttackDistance[attacker][0] = 150;
		}
	}
}

// 坦克初始化
void TankInitialization(int client)
{
	g_iTreePlayer[client] = -1;
	g_bCanTankConsume[client] = false;
	g_bInConsumePlace[client] = false;
	g_bCanTankAttack[client] = true;
	g_bReturnConsumePlace[client] = false;
	g_bVomitCanConsume[client] = false;
	g_fConsumePosition[client][0] = g_fConsumePosition[client][1] = g_fConsumePosition[client][2] = 0.0;
	g_fTeleportPosition[client][0] = g_fTeleportPosition[client][1] = g_fTeleportPosition[client][2] = 0.0;
	g_iTankConsumeSurvivorProgress[client] = 0;
	g_iTankConsumeLimitNum[client] = 0;
	g_bIsFirstConsumeCheck[client] = true;
	g_iTankIncappedCount[client][0] = 0;
	g_iTankConsumeValidPos[client][0] = 0;
	g_iTankSecondAttackDistance[client][0] = g_iTankForceAttackDistance;
	g_bDistanceHandle[client] = false;
	g_iDistanceCount[client][0] = 0;
	g_bTankActionReset[client] = false;
	g_iTankUnstuckTimes[client][0] = 0;
	g_iTankUnstuckTimes[client][1] = 0;
}

// **************
//		方法
// *************
bool IsAiTank(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && IsFakeClient(client) && GetClientTeam(client) == TEAM_INFECTED && GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK && GetEntProp(client, Prop_Send, "m_isGhost") != 1)
	{
		return true;
	}
	else
	{
		return false;
	}
}

// 是否离开树检测，坦克转换目标，记录绕树生还原始位置向量，以原始向量为起点画圆，将绕树生还后续位置与原始向量作的圆对比，到圆心的距离，是否大于给定半径（树宽）
//  if (!((x - x1)*(x - x1) + (y - y1)*(y - y1) > r*r)) return true; else return false;
bool bHasLeftRoundPoint(float originPos[3], float nowPos[3], int radius)
{
	if (RoundToNearest((originPos[0] - nowPos[0]) * (originPos[0] - nowPos[0]) + (originPos[1] - nowPos[1]) * (originPos[1] - nowPos[1])) > radius * radius)
	{
		return true;
	}
	else
	{
		return false;
	}
}

// 计算加速后的向量
float UpdatePosition(int tank, int target, float fForce)
{
	float fBuffer[3] = {0.0}, fTankPos[3] = {0.0}, fTargetPos[3] = {0.0};
	GetClientAbsOrigin(tank, fTankPos);
	GetClientAbsOrigin(target, fTargetPos);
	SubtractVectors(fTargetPos, fTankPos, fBuffer);
	fBuffer[2] = 0.0;
	NormalizeVector(fBuffer, fBuffer);
	ScaleVector(fBuffer, fForce);
	return fBuffer;
}

// 连跳操作
void ClientPush(int client, float fForwardVec[3])
{
	float fCurVelVec[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fCurVelVec);
	AddVectors(fCurVelVec, fForwardVec, fCurVelVec);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fCurVelVec);
}


bool Trace_EntityFilter(int entity, int contentsMask)
{
	if (entity <= MaxClients)
	{
		return false;
	}
	else
	{
		static char sClassname[9];
		GetEntityClassname(entity, sClassname, sizeof(sClassname));
		if (sClassname[0] == 'i' || sClassname[0] == 'w')
		{
			if (strcmp(sClassname, "infected") == 0 || strcmp(sClassname, "witch") == 0)
			{
				return false;
			}
		}
	}
	return true;
}

// 坦克目标选择
int TargetChoose(int iMethod, int iTank, int iSpecificClient = -1)
{
	int iTarget = -1;
	switch (iMethod)
	{
		// 第一种情况，选择最近生还者
		case 1:
		{
			float tankpos[3] = {0.0};
			GetClientAbsOrigin(iTank, tankpos);
			int nearesttarget = GetClosestSurvivor(tankpos);
			if (IsSurvivor(nearesttarget) && IsPlayerAlive(nearesttarget) && nearesttarget != iSpecificClient && !IsIncapped(nearesttarget))
			{
				iTarget = nearesttarget;
			}
		}
		// 第二种情况，选择血量最少的生还者
		case 2:
		{
			int minHealth = 100;
			float selfpos[3], targetpos[3];
			GetClientAbsOrigin(iTank, selfpos);
			for (int client = 1; client <= MaxClients; ++client)
			{
				if (IsSurvivor(client) && IsPlayerAlive(client) && client != iSpecificClient && !IsIncapped(client))
				{
					GetClientAbsOrigin(client, targetpos);
					int iHealth = GetEntProp(client, Prop_Data, "m_iHealth");
					if (iHealth < minHealth)
					{
						minHealth = iHealth;
						iTarget = client;
					}
				}
			}
		}
		// 第三种情况，选择血量最多的生还者
		case 3:
		{
			int maxHealth = 0;
			float selfpos[3], targetpos[3];
			GetClientAbsOrigin(iTank, selfpos);
			for (int client = 1; client <= MaxClients; ++client)
			{
				if (IsSurvivor(client) && IsPlayerAlive(client) && client != iSpecificClient && !IsIncapped(client))
				{
					GetClientAbsOrigin(client, targetpos);
					int iHealth = GetEntProp(client, Prop_Data, "m_iHealth");
					if (iHealth > maxHealth)
					{
						maxHealth = iHealth;
						iTarget = client;
					}
				}
			}
		}
	}
	return iTarget;
}

// 是否是生还？
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

// 目标是否在倒地状态？
bool IsIncapped(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

// 是否两者可见？
bool IsVisible(int client, int target)
{
	bool bCanSee = false;
	float selfpos[3], angles[3];
	GetClientEyePosition(client, selfpos);
	ComputeAimAngles(client, target, angles);
	Handle hTrace = TR_TraceRayFilterEx(selfpos, angles, MASK_SOLID, RayType_Infinite, Trace_FilterNoPlayers, client);
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

// 计算角度
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

// 获取生还距离
int GetSurvivorDistance(float refpos[3], int SpecificSur = -1)
{
	int TargetSur;
	float TargetSurPos[3];
	if (IsSurvivor(SpecificSur))
	{
		TargetSur = SpecificSur;
	}
	else
	{
		TargetSur = GetClosestSurvivor(refpos);
	}
	GetEntPropVector(TargetSur, Prop_Send, "m_vecOrigin", TargetSurPos);
	return RoundToNearest(GetVectorDistance(refpos, TargetSurPos));
}

// 有目的性选择最近生还
int GetClosestSurvivor(float refpos[3], int excludeSur = -1)
{
	float surPos[3];	int closetSur = GetRandomSurvivor();
	if (closetSur == 0)
	{
		return 0;
	}
	GetClientAbsOrigin(closetSur, surPos);
	int iClosetAbsDisplacement = RoundToNearest(GetVectorDistance(refpos, surPos));
	for (int client = 1; client < MaxClients; client++)
	{
		if (IsSurvivor(client) && IsPlayerAlive(client) && client != excludeSur && !IsIncapped(client))
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
	return closetSur;
}

bool TankIsPinned(int client)
{
	bool bIsPinned = false;
	if (IsSurvivor(client))
	{
		if(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0) bIsPinned = true;
		if(GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0) bIsPinned = true;
		if(GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0) bIsPinned = true;
		if(GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0) bIsPinned = true;
	}		
	return bIsPinned;
}

bool IsPinned(int client)
{
	bool bIsPinned = false;
	if (IsSurvivor(client))
	{
		if(GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0) bIsPinned = true;
		if(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0) bIsPinned = true;
		if(GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0) bIsPinned = true;
		if(GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0) bIsPinned = true;
		if(GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0) bIsPinned = true;
	}		
	return bIsPinned;
}

int GetSurvivorCount()
{
	int iSurvivorCount = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (client && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR)
		{
			iSurvivorCount += 1;
		}
	}
	return iSurvivorCount;
}

int GetInfectedCount()
{
	int iInfectedCount = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (client && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_INFECTED && GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_TANK)
		{
			iInfectedCount += 1;
		}
	}
	return iInfectedCount;
}

// From：Shadowysn，https://forums.alliedmods.net/showthread.php?t=261566&page=8
void Logic_RunScript(const char[] sCode, any ...) 
{
	int iScriptLogic = FindEntityByTargetname(-1, PLUGIN_SCRIPTLOGIC);
	if (!iScriptLogic || !IsValidEntity(iScriptLogic))
	{
		iScriptLogic = CreateEntityByName("logic_script");
		DispatchKeyValue(iScriptLogic, "targetname", PLUGIN_SCRIPTLOGIC);
		DispatchSpawn(iScriptLogic);
	}
	char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

int FindEntityByTargetname(int index, const char[] findname)
{
	for (int i = index; i < GetMaxEntities(); i++)
	{
		if (IsValidEntity(i))
		{
			char name[128];
			GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
			if (StrEqual(name, findname, false))
			{
				return i;
			}
		}
	}
	return -1;
}

// 禁止低抛
public Action L4D2_OnSelectTankAttack(int client, int &sequence)
{
	if (sequence == SEQUENCE_UNDERHAND)
	{
		sequence = GetRandomInt(0, 1) ? SEQUENCE_ONEHAND : SEQUENCE_TWOHAND;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// 检测特感团队是否有坦克
int FindTank()
{
	int iTank = -1;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsAiTank(client))
		{
			iTank = client;
		}
	}
	return iTank;
}

// 计算生还者在地图上的路程
float GetBossProximity()
{
	float proximity = GetMaxSurvivorCompletion() + g_hVsBossFlowBuffer.FloatValue / L4D2Direct_GetMapMaxFlowDistance();
	return (proximity > 1.0) ? 1.0 : proximity;
}

float GetMaxSurvivorCompletion()
{
	float flow = 0.0, tmp_flow = 0.0, origin[3];
	Address pNavArea;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
			GetClientAbsOrigin(i, origin);
			pNavArea = L4D2Direct_GetTerrorNavArea(origin);
			if (pNavArea != Address_Null)
			{
				tmp_flow = L4D2Direct_GetTerrorNavAreaFlow(pNavArea);
				flow = (flow > tmp_flow) ? flow : tmp_flow;
			}
		}
	}
	return (flow / L4D2Direct_GetMapMaxFlowDistance());
}

stock bool IsOnValidMesh(float fReferencePos[3])
{
	Address pNavArea = L4D2Direct_GetTerrorNavArea(fReferencePos);
	if (pNavArea != Address_Null)
	{
		return true;
	}
	else
	{
		return false;
	}
}

bool IsPlayerStuck(float fSpawnPos[3], int client)
{
	bool IsStuck = true;
	float fMins[3] = {0.0}, fMaxs[3] = {0.0}, fNewPos[3] = {0.0};
	fNewPos = fSpawnPos;
	fNewPos[2] += 35.0;
	fMins[0] = fMins[1] = -16.0;
	fMins[2] = 0.0;
	fMaxs[0] = fMaxs[1] = 16.0;
	fMaxs[2] = 72.0;
	TR_TraceHullFilter(fSpawnPos, fNewPos, fMins, fMaxs, MASK_NPCSOLID_BRUSHONLY, Trace_FilterNoPlayers, client);
	IsStuck = TR_DidHit();
	return IsStuck;
}

public bool Trace_FilterNoPlayers(int entity, int mask, any data)
{
    if(entity == data || (entity >= 1 && entity <= MaxClients))
    {
        return false;
    }
    return true;
}

stock float CopyVectors(float origin[3], float result[3])
{
	result[0] = origin[0];
	result[1] = origin[1];
	result[2] = origin[2];
}

bool TeleportSmooth(int client)
{
	return TeleportPlayerSmooth(client, 150.0, 251.0);
}

bool TeleportPlayerSmooth(int client, float distance, float power = 251.0)
{
	static float angles[3] = {0.0},	dir[3] = {0.0},	current[3] = {0.0},	result[3] = {0.0}, selfpos[3] = {0.0}, vectarget[3] = {0.0};
	GetClientAbsOrigin(client, selfpos);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", current);
	int target = GetClosestSurvivor(selfpos);
	if (IsSurvivor(target))
	{
		GetClientAbsOrigin(target, vectarget);
		float newvec[3] = {0.0};
		SubtractVectors(selfpos, vectarget, angles);
		NormalizeVector(newvec, newvec);
		GetVectorAngles(newvec, angles);
		TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
	}
	GetClientEyeAngles(client, angles);
	GetAngleVectors(angles, dir, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(dir, distance);
	result[0] = current[0] + dir[0];
	result[1] = current[1] + dir[1];
	result[2] = power;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, result);
	return true;
}

bool IsTankAttacking(int client)
{
	return GetEntProp(client, Prop_Send, "m_fireLayerSequence") > 0;
}

bool IsPosAhead(float vecpos[3])
{
	float tmpflow = 0.0;
	Address pnownav = L4D2Direct_GetTerrorNavArea(vecpos);
	if (pnownav == Address_Null)
	{
		pnownav = view_as<Address>(L4D_GetNearestNavArea(vecpos));
	}
	tmpflow = L4D2Direct_GetTerrorNavAreaFlow(pnownav);
	tmpflow = tmpflow / L4D2Direct_GetMapMaxFlowDistance();
	float tankproximity = tmpflow + g_hVsBossFlowBuffer.FloatValue / L4D2Direct_GetMapMaxFlowDistance();
	tankproximity > 1.0 ? 1.0 : tankproximity;
	int newtankproximity = RoundToNearest(tankproximity * 100.0);
	if (newtankproximity > RoundToNearest(GetBossProximity() * 100.0))
	{
		return true;
	}
	else
	{
		return false;
	}
}