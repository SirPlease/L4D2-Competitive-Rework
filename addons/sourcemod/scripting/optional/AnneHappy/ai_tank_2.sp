#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <colors>
#include <left4dhooks>
#include <treeutil>
#undef REQUIRE_PLUGIN
#include <infected_control>

#define CVAR_FLAG FCVAR_NOTIFY
#define NAV_MESH_HEIGHT 20.0								// 有效 Nav 位置高度
#define WALL_DETECT_DIST 64.0								// 前方墙体检测距离
#define FALL_DETECT_HEIGHT 120.0							// 向下坠落高度
#define ROCK_THROW_HEIGHT 110.0								// 坦克石头出手高度
#define ROCK_AIM_TIME 0.8									// 坦克扔石头瞄准的时间
#define FUNCTION_FINDPOS_TRY 5								// 函数找位一次最大找位次数
#define LAG_DETECT_TIME 2.0									// 坦克位置检测间隔
#define LAG_DETECT_RAIDUS 100								// 坦克位置检测范围
#define LAG_DETECT_OFFSET 30.0								// 坦克位置检测偏移角度
#define TREE_DETECT_TIME 1.5								// 绕树检测间隔
#define VISION_UNLOCK_TIME 2.0								// 视角解锁间隔
#define SPEED_MAX 450.0										// 速度修正最大速度长度
#define SPEED_MIN 200.0										// 速度修正最大速度长度
#define RAY_ANGLE view_as<float>({90.0, 0.0, 0.0})
#define DEBUG_ALL 0
#if (DEBUG_ALL)
int g_sprite;
#include <vector_show>
#endif

public Plugin myinfo = 
{
	name 			= "Ai_Tank_Enhance2.0",
	author 			= "夜羽真白，东",
	description 	= "Tank 增强插件 2.0 版本",
	version 		= "2.0.1.0",
	url 			= "https://github.com/fantasylidong/CompetitiveWithAnne"
}

enum struct struct_TankConsume
{
	// Bools
	bool bCanInitPos;				// 生成之后是否允许找位
	bool bCanConsume;				// 是否允许消耗
	bool bIsReachingFunctionPos;	// 是否正在前往函数找位的位置
	bool bIsReachingRayPos;			// 是否正在前往射线找位的位置
	bool bInConsumePlace;			// 是否在消耗位上
	bool bHasRecordProgress;		// 是否记录生还者当前路程
	bool bHasCreatePosTimer;		// 是否创建位置检测时钟
	bool bCanLockVision;
	// Ints
	int iTreeTarget;				// 绕树目标
	int iConsumeSurPercent;			// 坦克开始消耗时生还者在地图上的进度
	int iConsumeNum;				// 坦克消耗次数
	int iIncappedCount;				// 坦克拍倒的人数
	// Float
	float fTankStopDistance;
	float fNowPos[3];				// 坦克当前位置
	float fFunctionConsumePos[3];	// 函数找位找到的消耗位
	float fRayConsumePos[3];		// 射线找位找到的消耗位
	float fTreeTime;				// 绕树检测时长
	float fTreeTargetPos[3];		// 绕树生还当前位置
	float fFailedJumpedTime;		// 团灭嘲讽跳起来的时间戳
	float fRockThrowTime;			// 扔石头的时间戳
	float fLockVisonTime;			// 视角解锁时间戳
	// 结构体变量初始化
	void struct_Init()
	{
		this.bCanInitPos = this.bCanConsume = this.bIsReachingFunctionPos = this.bIsReachingRayPos = this.bInConsumePlace = this.bHasRecordProgress = false;
		this.iTreeTarget = this.iConsumeSurPercent = this.iConsumeNum = this.iIncappedCount = 0;
		this.fTreeTime = this.fFailedJumpedTime = this.fRockThrowTime = this.fLockVisonTime = 0.0;
		this.bHasCreatePosTimer = false;
		this.fTankStopDistance = 0.0;
	}
	void setTankStopDistance(float distance){
		this.fTankStopDistance =distance;
	}
}
static struct_TankConsume eTankStructure[MAXPLAYERS + 1];
stock void ConsumePosInit(int client, bool function_pos = true, bool ray_pos = true)
{
	if (function_pos && ray_pos)
	{
		eTankStructure[client].fFunctionConsumePos[0] = eTankStructure[client].fFunctionConsumePos[1] = eTankStructure[client].fFunctionConsumePos[2] = 0.0;
		eTankStructure[client].fRayConsumePos[0] = eTankStructure[client].fRayConsumePos[1] = eTankStructure[client].fRayConsumePos[2] = 0.0;
	}
	else if (function_pos && !ray_pos)
	{
		eTankStructure[client].fFunctionConsumePos[0] = eTankStructure[client].fFunctionConsumePos[1] = eTankStructure[client].fFunctionConsumePos[2] = 0.0;
	}
	else if (!function_pos && ray_pos)
	{
		eTankStructure[client].fRayConsumePos[0] = eTankStructure[client].fRayConsumePos[1] = eTankStructure[client].fRayConsumePos[2] = 0.0;
	}
}

// ConVars
ConVar g_hAllowBhop, g_hBhopSpeed, g_hAirAngleRestrict,	g_hTankStopDistance,														// 控制坦克连跳，防止跳过头
g_hAllowThrow, g_hAllowThrowRange,																				// 控制坦克是否可以扔石头
g_hAllowConsume, g_hConsumeInfSub, g_hConsumeHealth, g_hRayRaidus, g_hConsumeDist, g_hFindNewPosDist, g_hSneakTank,
g_hConsumePosRaidus, g_hForceAttackDist, g_hForceAttackProgress, g_hVomitAttackNum, g_hConsumeIncap,
g_hConsumeRockInterval,																							// 控制坦克消耗
g_hAllowTreeDetect, g_hAntiTreeMethod, g_hTargetChoose,															// 控制坦克目标选择
g_hAttackRange, g_hSiLimit, g_hVsBossFlowBuffer, g_hVomitInterval, g_hFadeTime, g_hRockInterval,
g_hRockMinInterval;																								// 坦克攻击距离，特感数量
// Ints
int throw_min_range = 0, throw_max_range = 0, sicount = 0,														// 最小与最大允许投掷距离，特感数量
highest_health_target = -1, lowest_health_target = -1;
// Handle
Handle hPosCheckTimer[MAXPLAYERS + 1] = { null };
// List
ArrayList ladderList = null;
//bool
bool g_bSISystem = false;

public void OnPluginStart()
{
	// 连跳相关
	g_hAllowBhop = CreateConVar("ai_Tank_Bhop", "1", "是否开启坦克连跳", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hBhopSpeed = CreateConVar("ai_TankBhopSpeed", "60", "坦克连跳速度", CVAR_FLAG, true, 0.0);
	g_hTankStopDistance = CreateConVar("ai_Tank_StopDistance", "135", "Tank在距离目标多远位置停下连跳", FCVAR_NOTIFY, true, 0.0);
	// 消耗相关
	g_hAllowConsume = CreateConVar("ai_TankConsume", "0", "是否开启坦克消耗", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hSneakTank = CreateConVar("ai_TankSneakTime", "0", "tank会消耗到下一波生成时间小于ai_TankSneakTime,0为关闭，消耗开启的时候不启用", CVAR_FLAG, true, 0.0, true, 28.0);
	g_hConsumeInfSub = CreateConVar("ai_TankConsumeInfSub", "1", "当前特感少于等于特感上限减去这个值的时，坦克可以消耗", CVAR_FLAG, true, 0.0);
	g_hRayRaidus = CreateConVar("ai_TankConsumeRayRaidus", "1500", "射线找消耗位的范围，从坦克当前位置开始计算", CVAR_FLAG, true, 0.0);
	g_hConsumeDist = CreateConVar("ai_TankConsumeDistance", "1200", "射线找到的消耗位需要离生还者这么远", CVAR_FLAG, true, 0.0);
	g_hFindNewPosDist = CreateConVar("ai_TankFindNewConsumePosDistance", "750", "最近的生还者离坦克这么远坦克会重新找消耗位", CVAR_FLAG, true, 0.0);
	g_hForceAttackDist = CreateConVar("ai_TankForceAttackDist", "350", "生还者距离坦克这么近坦克会强制攻击", CVAR_FLAG, true, 0.0);
	g_hForceAttackProgress = CreateConVar("ai_TankForceAttackProgress", "10", "开始消耗时记录生还者路程，当超过路程加这个值时不允许消耗", CVAR_FLAG, true, 0.0);
	g_hConsumePosRaidus = CreateConVar("ai_TankConsumePosRaidus", "100", "坦克走出了消耗位中心坐标以这个值为半径画圆的范围，会强制重新进入", CVAR_FLAG, true, 0.0);
	g_hConsumeHealth = CreateConVar("ai_TankConsumeHealth", "2000", "坦克血量少于这个值时强制压制", CVAR_FLAG, true, 0.0);
	g_hVomitAttackNum = CreateConVar("ai_TankVomitAttackNum", "1", "有这个值的生还者在坦克消耗时被喷，坦克会强制压制", CVAR_FLAG, true, 0.0);
	g_hConsumeIncap = CreateConVar("ai_TankConsumeIncapNum", "1", "坦克强制压制时，如果令这个数量的生还者倒地，如果可以消耗则继续消耗", CVAR_FLAG, true, 0.0);
	g_hAirAngleRestrict = CreateConVar("ai_TankAirAngleRestrict", "57", "坦克当前速度与到目标的向量大于这个角度将会停止连跳", CVAR_FLAG, true, 0.0, true, 90.0);
	g_hConsumeRockInterval = CreateConVar("ai_TankConsumeRockInterval", "4", "坦克在消耗位上时多少秒扔一次石头", CVAR_FLAG, true, 0.0);
	// 目标选择
	g_hTargetChoose = CreateConVar("ai_TankTarget", "0", "坦克目标选择：0=自然目标选择，1=最近，2=血量最低，3=血量最高", CVAR_FLAG, true, 0.0, true, 3.0);
	g_hAllowTreeDetect = CreateConVar("ai_TankTreeDetect", "1", "是否开启防止绕树功能", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAntiTreeMethod = CreateConVar("ai_TankAntiTreeMethod", "1", "防止绕树的方法：1=选择新的目标，2=传送到绕树生还位置", CVAR_FLAG, true, 1.0, true, 2.0);
	// 扔石头相关
	g_hAllowThrow = CreateConVar("ai_TankThow", "1", "是否允许坦克丢石头", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAllowThrowRange = CreateConVar("ai_TankThrowRange", "250,500", "允许坦克丢石头的范围，中间用逗号隔开，不能有空格", CVAR_FLAG);
	g_hAllowThrowRange.AddChangeHook(ConVarChanged_Cvars);
	Get_ThrowRange();
	// 坦克拳头攻击范围
	g_hAttackRange = FindConVar("tank_attack_range");
	g_hSiLimit = FindConVar("l4d_infected_limit");
	g_hVsBossFlowBuffer = FindConVar("versus_boss_buffer");
	g_hVomitInterval = FindConVar("z_vomit_fade_start");
	g_hFadeTime = FindConVar("z_vomit_fade_duration");
	g_hRockInterval = FindConVar("z_tank_throw_interval");
	g_hRockMinInterval = FindConVar("tank_throw_min_interval");
	// HookEvents
	HookEvent("tank_spawn", evt_TankSpawn);
	HookEvent("player_incapacitated", evt_PlayerIncapped);
	HookEvent("finale_win", evt_ResetLadder);
	HookEvent("map_transition", evt_ResetLadder);
	HookEvent("round_start", evt_RoundStart, EventHookMode_PostNoCopy);
	// Building List
	ladderList = new ArrayList(3);
	#if(DEBUG_ALL)
		RegAdminCmd("sm_checkladder", CalculateLadderNum, ADMFLAG_ROOT, "测试当前地图有多少个梯子");
	#endif
}

public void OnAllPluginsLoaded(){
	g_bSISystem = LibraryExists("infected_control");
}
public void OnLibraryAdded(const char[] name)
{
    if ( StrEqual(name, "infected_control") ) { g_bSISystem = true; }
}
public void OnLibraryRemoved(const char[] name)
{
    if ( StrEqual(name, "infected_control") ) { g_bSISystem = false; }
}

#if(DEBUG_ALL)
public Action CalculateLadderNum(int client, int args){
	int ent = -1, laddercount = 0;
	while((ent = FindEntityByClassname(ent, "func_simpleladder")) != -1) {
		if(IsValidEntity(ent)) {
			laddercount++;
		}
	}
	PrintToChatAll("本地图共有：%d 个梯子 %d个初始化检测梯子", laddercount, ladderList.Length);
	return Plugin_Handled;
}
#endif

public void OnPluginEnd()
{
	delete ladderList;
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Get_ThrowRange();
}

stock void CheckAllLadder()
{
	ladderList.Clear();
	char className[64] = {'\0'};
	float ladderVec[3] = {0.0}, ladderAgl[3] = {0.0}, ladderActPos[3] = {0.0}, mins[3] = {0.0}, maxs[3] = {0.0};
	for (int i = MaxClients + 1; i < GetEntityCount(); i++)
	{
		if (IsValidEntity(i) && IsValidEdict(i))
		{
			GetEntityClassname(i, className, sizeof(className));
			if (className[0] == 'f' && (strcmp(className, "func_simpleladder") == 0 || strcmp(className, "func_ladder") == 0))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", ladderVec);
				GetEntPropVector(i, Prop_Send, "m_vecMins", mins);
				GetEntPropVector(i, Prop_Send, "m_vecMaxs", maxs);
				GetEntPropVector(i, Prop_Send, "m_angRotation", ladderAgl);
				Math_RotateVector(mins, ladderAgl, mins);
				Math_RotateVector(maxs, ladderAgl, maxs);
				ladderActPos[0] = ladderVec[0] + (mins[0] + maxs[0]) * 0.5;
				ladderActPos[1] = ladderVec[1] + (mins[1] + maxs[1]) * 0.5;
				ladderActPos[2] = ladderVec[2] + (mins[2] + maxs[2]) * 0.5;
				#if (DEBUG_ALL)
				{
					PrintToConsoleAll("[Ai-Tank]：梯子：%d 坐标：[%.2f, %.2f, %.2f]", i, ladderActPos[0], ladderActPos[1], ladderActPos[2]);
				}
				#endif
				ladderList.PushArray(ladderActPos);
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsAiTank(client))
	{
		if (L4D_IsPlayerStaggering(client) || buttons & IN_BACK)
			return Plugin_Continue;
		bool bHasSight = false, bIsSurvivorFailed = true;
		int vomit_survivor = 0, target = GetClientAimTarget(client, true), flags = GetEntityFlags(client), nearest_target = GetClosetMobileSurvivor(client), nearest_targetdist = GetClosetSurvivorDistance(client), current_seq = GetEntProp(client, Prop_Send, "m_nSequence");	sicount = GetSiCount_ExcludeTank(bIsSurvivorFailed, vomit_survivor);
		float selfpos[3] = {0.0}, eyeangles[3] = {0.0}, velbuffer[3] = {0.0}, vecspeed[3] = {0.0}, curspeed = 0.0;
		GetClientAbsOrigin(client, selfpos);
		GetClientEyeAngles(client, eyeangles);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecspeed);
		curspeed = SquareRoot(Pow(vecspeed[0], 2.0) + Pow(vecspeed[1], 2.0));
		bHasSight = view_as<bool>(GetEntProp(client, Prop_Send, "m_hasVisibleThreats"));
		// 连跳与扔石头相关，判断目标是否有效，目标有效，执行连跳与空中防止跳过头操作，同时判断距离，是否允许扔石头
		if (IsValidSurvivor(target))
		{
			float targetpos[3] = {0.0};
			int targetdist = GetClosetSurvivorDistance(client, target);
			GetClientAbsOrigin(target, targetpos);
			velbuffer = CalculateVel(selfpos, targetpos, g_hBhopSpeed.FloatValue);
			// 扔石头相关
			if (g_hAllowThrow.BoolValue && throw_min_range >= 0 && throw_max_range >= 0)
			{
				if (targetdist > throw_max_range || targetdist < throw_min_range && (g_hRockInterval.IntValue < 999 || g_hRockMinInterval.IntValue < 999))
				{
					g_hRockInterval.SetInt(999);
					g_hRockMinInterval.SetInt(999);
					buttons &= ~ IN_ATTACK2;
				}
				else if (g_hRockInterval.IntValue != 5 || g_hRockMinInterval.IntValue != 8)
				{
					
					g_hRockInterval.RestoreDefault();
					g_hRockMinInterval.RestoreDefault();
				}
			}
			// 连跳距离及防止跳过头控制，要改连跳距离改这里，默认坦克拳头长度 * 0.8 - 1500 距离允许连跳
			if (!eTankStructure[client].bCanConsume && eTankStructure[client].fTankStopDistance <= targetdist <= 2000 && curspeed > 190.0)
			{
				if (g_hAllowBhop.BoolValue && (flags & FL_ONGROUND))
				{
					buttons |= IN_JUMP;
					buttons |= IN_DUCK;
					if (Tank_DoBhop(client, buttons, velbuffer))
					{
						return Plugin_Changed;
					}
				}
				else if (!(flags & FL_ONGROUND))
				{
					// 在空中禁止跳跃和蹲
					buttons &= ~IN_JUMP;
					buttons &= ~IN_DUCK;
					float velangles[3] = {0.0}, new_velvec[3] = {0.0}, self_target_vec[3] = {0.0};
					/* float speed_length = 0.0;
					speed_length = GetVectorLength(vecspeed, false); */
					GetVectorAngles(vecspeed, velangles);
					velangles[0] = velangles[2] = 0.0;
					GetAngleVectors(velangles, new_velvec, NULL_VECTOR, NULL_VECTOR);
					NormalizeVector(new_velvec, new_velvec);
					// 获取自身与生还之间的向量，x，y 方向不置 0，z 方向置 0
					if(selfpos[2] < targetpos[2])
						selfpos[2] = targetpos[2] = 0.0;
					MakeVectorFromPoints(selfpos, targetpos, self_target_vec);
					NormalizeVector(self_target_vec, self_target_vec);
					float angeldifference = RadToDeg(ArcCosine(GetVectorDotProduct(new_velvec, self_target_vec)));
					if ( angeldifference > g_hAirAngleRestrict.FloatValue && angeldifference < 120.0)
					{
						MakeVectorFromPoints(selfpos, targetpos, new_velvec);
						GetVectorAngles(new_velvec, velangles);
						NormalizeVector(new_velvec, new_velvec);
						// 按照原来速度向量长度 + 缩放长度缩放修正后的速度向量，觉得太阴间了可以修改
						if(curspeed > SPEED_MAX)
							ScaleVector(new_velvec, SPEED_MAX);
						else
							ScaleVector(new_velvec, curspeed);
						TeleportEntity(client, NULL_VECTOR, velangles, new_velvec);
					}
				}
			}
			/*
			// 如果玩家在坦克拳头距离范围内，强制拍拳
			if (bHasSight && targetdist <= g_hAttackRange.IntValue * 0.95 && !IsClientIncapped(target))
			{
				buttons |= IN_ATTACK;
				return Plugin_Changed;
			}
			*/
			// 绕树检测，目标距离小于 170 且不可直视，第一次与下一次不可直视的时间大于 TREE_DETECT_TIME，记录位置，如果生还保持有效且未出绕树时记录的坐标 170 范围的圆域则继续切换目标
			if (g_hAllowTreeDetect.BoolValue && targetdist < 170 && !Player_IsVisible_To(client, target))
			{
				if (eTankStructure[client].fTreeTime == 0.0)
				{
					eTankStructure[client].fTreeTime = GetGameTime();
				}
				else if (GetGameTime() - eTankStructure[client].fTreeTime > TREE_DETECT_TIME)
				{
					switch (g_hAntiTreeMethod.IntValue)
					{
						case 1:
						{
							CopyVectors(targetpos, eTankStructure[client].fTreeTargetPos);
							eTankStructure[client].iTreeTarget = target;
							eTankStructure[client].fTreeTime = 0.0;
						}
						case 2:
						{
							TeleportEntity(client, targetpos, NULL_VECTOR, NULL_VECTOR);
							eTankStructure[client].iTreeTarget = 0;
							//PrintToChat(client, "{O}[Ai-Tank]：{G}喜欢绕树是吧");
						}
					}
				}
			}
			else if (IsValidSurvivor(eTankStructure[client].iTreeTarget) && !Is_InConsumeRaidus(targetpos, eTankStructure[client].fTreeTargetPos, 170))
			{
				eTankStructure[client].iTreeTarget = 0;
			}
		}
		// 前往消耗位的途中，允许连跳，无需判断是否有目标
		if (eTankStructure[client].bCanConsume && eTankStructure[client].bIsReachingFunctionPos || eTankStructure[client].bIsReachingRayPos)
		{
			if ((eTankStructure[client].fFunctionConsumePos[0] != 0.0 && !Is_InConsumeRaidus(selfpos, eTankStructure[client].fFunctionConsumePos, g_hConsumePosRaidus.IntValue * 2)) || (eTankStructure[client].fRayConsumePos[0] != 0.0 && !Is_InConsumeRaidus(selfpos, eTankStructure[client].fRayConsumePos, g_hConsumePosRaidus.IntValue * 2)))
			{
				GetAngleVectors(eyeangles, velbuffer, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(velbuffer, velbuffer);
				ScaleVector(velbuffer, g_hBhopSpeed.FloatValue);
				if (g_hAllowBhop.BoolValue && (flags & FL_ONGROUND) && curspeed > 190.0)
				{
					buttons |= IN_JUMP;
					buttons |= IN_DUCK;
					if (Tank_DoBhop(client, buttons, velbuffer))
					{
						return Plugin_Changed;
					}
				}
			}
		}
		// 消耗相关，判断是否允许消耗
		if (g_hAllowConsume.BoolValue || (g_hSneakTank.FloatValue > 0.0 && eTankStructure[client].bCanConsume))
		{
			if (IsValidSurvivor(nearest_target))
			{
				eTankStructure[client].bCanConsume = Check_TankCanConsume(client, sicount, nearest_target, vomit_survivor);
				// 允许消耗，进行消耗找位
				if (eTankStructure[client].bCanConsume)
				{
					Find_And_Goto_ConsumePos(client, nearest_target);
					RayPos_Visible_Check(client);
					ConsumePos_NearestTargetDist_Check(client, nearest_targetdist, bHasSight);
					In_ConsumePos_ThrowRock(client, selfpos, current_seq, buttons);
					Survivor_Progress_Check(client);
				}
			}
		}
		else
		{
			// Cvar 变动，不允许消耗时，重置 Tank 行为
			if (eTankStructure[client].bCanConsume)
			{
				g_hRockInterval.RestoreDefault();
				g_hRockMinInterval.RestoreDefault();
				CreateTimer(0.5, Timer_TankAction_Reset, client);
				eTankStructure[client].bCanConsume = eTankStructure[client].bIsReachingFunctionPos = eTankStructure[client].bIsReachingRayPos = eTankStructure[client].bInConsumePlace = false;
			}
		}
		// 扔石头时，记录扔石头的时间戳
		if (current_seq == 49 || current_seq == 50 || current_seq == 51)
		{
			eTankStructure[client].fRockThrowTime = GetGameTime();
		}
		// 视角锁定，不允许消耗时并当前时间戳减去扔石头时的时间戳大于 ROCK_AIM_TIME 锁定视角
		if (bHasSight && !eTankStructure[client].bCanConsume && GetGameTime() - eTankStructure[client].fRockThrowTime > ROCK_AIM_TIME  && eTankStructure[client].bCanLockVision)
		{
			#if (DEBUG_ALL)
				//PrintToConsoleAll("锁定视角中");
			#endif
			float self_eye_pos[3] = {0.0}, targetpos[3] = {0.0}, look_at[3] = {0.0};
			if (IsValidSurvivor(nearest_target))
			{
				GetClientEyePosition(client, self_eye_pos);
				GetClientAbsOrigin(nearest_target, targetpos);
				targetpos[2] += 45.0;
				MakeVectorFromPoints(self_eye_pos, targetpos, look_at);
				GetVectorAngles(look_at, look_at);
				TeleportEntity(client, NULL_VECTOR, look_at, NULL_VECTOR);
			}
		}
		// 爬梯子时，禁止连跳
		if (GetEntityMoveType(client) & MOVETYPE_LADDER)
		{
			buttons &= ~IN_JUMP;
			buttons &= ~IN_DUCK;
			switch (GetEntProp(client, Prop_Send, "m_nSequence"))
			{
				case 15,16,17:
				{
					buttons &= ~IN_ATTACK;
				}
			}
			return Plugin_Changed;
		}
		// 着火时，自动灭火
		if (GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONFIRE)
		{
			ExtinguishEntity(client);
		}
		// 生还者团灭了，跳起来嘲讽，按键时间不要过快，0.3 秒为最小间隔，如果在帧操作中一直按键则会导致按键不会执行
		if (bIsSurvivorFailed)
		{
			if (eTankStructure[client].fFailedJumpedTime == 0.0)
			{
				eTankStructure[client].fFailedJumpedTime = GetGameTime();
			}
			else if (GetGameTime() - eTankStructure[client].fFailedJumpedTime > 0.3)
			{
				eTankStructure[client].fFailedJumpedTime = GetGameTime();
				buttons |= IN_JUMP;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

// 坦克跳砖
public Action L4D_OnCThrowActivate(int ability)
{
	SetConVarString(FindConVar("z_tank_throw_force"), "1000");
	int client = GetEntPropEnt(ability, Prop_Data, "m_hOwnerEntity");
	if (IsAiTank(client))
	{
		RequestFrame(NextFrame_JumpRock, client);
	}
	return Plugin_Continue;
}
void NextFrame_JumpRock(int client)
{
	if (IsAiTank(client))
	{
		int flags = GetEntityFlags(client), target = GetClosetMobileSurvivor(client);
		if ((flags & FL_ONGROUND)&& IsValidSurvivor(target))
		{
			if (!eTankStructure[client].bCanConsume)
			{
				float eyeangles[3] = {0.0}, lookat[3] = {0.0};
				GetClientEyeAngles(client, eyeangles);
				GetAngleVectors(eyeangles, lookat, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(lookat, lookat);
				ScaleVector(lookat, 260.0);
				lookat[2] = 260.0;
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, lookat);
			}
			else
			{
				float upspeed[3] = {0.0, 0.0, 260.0};
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, upspeed);
			}
		}
	}
}

// 目标选择
public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{
	if (IsAiTank(specialInfected) && IsValidSurvivor(curTarget) && g_hTargetChoose.IntValue)
	{
		if (IsClientPinned(curTarget) || IsClientIncapped(curTarget) || IsValidSurvivor(eTankStructure[specialInfected].iTreeTarget))
		{
			int newtarget = GetClosetMobileSurvivor(specialInfected, curTarget);
			if (IsValidSurvivor(newtarget))
			{
				curTarget = newtarget;
				return Plugin_Changed;
			}
		}
		else
		{
			switch (g_hTargetChoose.IntValue)
			{
				case 1:
				{
					int newtarget = GetClosetMobileSurvivor(specialInfected);
					if (IsValidSurvivor(newtarget))
					{
						curTarget = newtarget;
						return Plugin_Changed;
					}
				}
				case 2:
				{
					if (IsValidSurvivor(highest_health_target))
					{
						curTarget = highest_health_target;
						return Plugin_Changed;
					}
				}
				case 3:
				{
					if (IsValidSurvivor(lowest_health_target))
					{
						curTarget = lowest_health_target;
						return Plugin_Changed;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

// 坦克刷新
public void evt_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsAiTank(client))
	{
		// 坦克刷新后，先清空其他类型的数据，过 1 秒，再清空由于运行 OnPlayerRunCmd 中找到的消耗位，让坦克继续找位，目标有效，则停止时钟，坦克刚刚创建出来后 1s 可能还会无目标，使用循环时钟
		eTankStructure[client].struct_Init();
		eTankStructure[client].setTankStopDistance(GetConVarFloat(g_hTankStopDistance));
		CreateTimer(1.0, Timer_SpawnCheckConsume, client, TIMER_REPEAT);
		CreateTimer(1.0, Timer_SneakCheck, client, TIMER_REPEAT);
		CreateTimer(2.0, checkLadderAroundHandler, client, TIMER_REPEAT);
		// 创建坦克位置检测时钟，如果坦克在有目标前就卡住，则不会检测，所以在刷出来的时候就需要创建
		if (!eTankStructure[client].bHasCreatePosTimer)
		{
			hPosCheckTimer[client] = CreateTimer(LAG_DETECT_TIME, Timer_CheckLag, client, TIMER_REPEAT);
			eTankStructure[client].bHasCreatePosTimer = true;
		}
	}
}

public Action Timer_SneakCheck(Handle timer, int client)
{
	if (IsAiTank(client) && g_hSneakTank.FloatValue > 0.0 && !g_hAllowConsume.BoolValue && g_bSISystem)
	{
		#if (DEBUG_ALL)
			PrintToConsoleAll("[Ai-Tank]：SneakTank开启，Tank将在特感刷新前%f秒消耗， 当前特感生成时间为%f秒后", g_hSneakTank.FloatValue, GetNextSpawnTime());
		#endif
		float time = FindConVar("versus_special_respawn_interval").FloatValue / 2.0;
		if(GetNextSpawnTime() < (time > g_hSneakTank.FloatValue ? g_hSneakTank.FloatValue: time))
		{
			eTankStructure[client].bCanConsume = false;
			throw_min_range = 250;
			throw_max_range = 500;
			#if (DEBUG_ALL)
				PrintToConsoleAll("[Ai-Tank]：SneakTank关闭，已到tank压制时间，关闭消耗，最小扔石头距离改为250，最大改为500");
			#endif
			return Plugin_Stop;
		}
		else if(eTankStructure[client].bCanConsume != true || throw_min_range != 400 || throw_max_range != 2000)
		{
			eTankStructure[client].bCanConsume = true;
			throw_min_range = 400;
			throw_max_range = 2000;
			#if (DEBUG_ALL)
				PrintToConsoleAll("[Ai-Tank]：SneakTank开启，未到tank压制时间，开启消耗，最小扔石头距离改为400，最大改为2000");
			#endif
			return Plugin_Continue;
		}
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public Action Timer_SpawnCheckConsume(Handle timer, int client)
{
	if (IsAiTank(client))
	{
		int target = GetClientAimTarget(client, true);
		if (IsValidSurvivor(target))
		{
			ConsumePosInit(client);
			eTankStructure[client].bCanInitPos = true;
			eTankStructure[client].bIsReachingFunctionPos = eTankStructure[client].bIsReachingRayPos = false;
			#if (DEBUG_ALL)
				PrintToConsoleAll("[Ai-Tank]：刷新坦克，客户端索引：%d，当前坦克目标：%d（%N），第一次创建时钟查看是否可以消耗", client, target, target);
			#endif
			return Plugin_Stop;
		}
	}
	return Plugin_Stop;
}

// 玩家倒地
public void evt_PlayerIncapped(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (IsAiTank(attacker) && IsValidSurvivor(client))
	{
		eTankStructure[attacker].iIncappedCount += 1;
	}
	else if (IsAiTank(client) )
	{
		eTankStructure[client].struct_Init();
		ConsumePosInit(client);
	}
}

// 过关重置梯子信息
public void evt_ResetLadder(Event event, const char[] name, bool dontBroadcast)
{
	ladderList.Clear();
}

public void evt_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(3.0, initLadder, _, TIMER_FLAG_NO_MAPCHANGE);
}

// 开局重置梯子状态
public Action initLadder(Handle timer)
{
	if(ladderList.Length <= 1){
		CheckAllLadder();
	}
	return Plugin_Continue;
}

stock bool IsOnLadder(int entity)
{
	return GetEntityMoveType(entity) == MOVETYPE_LADDER;
}

// 是否 ai 坦克
bool IsAiTank(int client)
{
	return view_as<bool>(GetInfectedClass(client) == view_as<int>(ZC_TANK) && IsFakeClient(client));
}

// 计算坦克加速后的速度向量
float[] CalculateVel(float selfpos[3], float targetpos[3], float force)
{
	float vecbuffer[3] = {0.0};
	SubtractVectors(targetpos, selfpos, vecbuffer);
	NormalizeVector(vecbuffer, vecbuffer);
	ScaleVector(vecbuffer, force);
	return vecbuffer;
}

// 坦克连跳
bool Tank_DoBhop(int client, int &buttons, float vec[3])
{
	bool bJumped = false;
	if (buttons & IN_FORWARD || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT)
	{
		if (ClientPush(client, vec))
		{
			bJumped = true;
		}
	}
	return bJumped;
}

// 以缩放后的向量加速到玩家的当前速度中
bool ClientPush(int client, float vec[3])
{
	float curvel[3] = {0.0};
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", curvel);
	AddVectors(curvel, vec, curvel);
	if (Dont_HitWall_Or_Fall(client, curvel))
	{
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, curvel);
		return true;
	}
	return false;
}

// 坦克当前位置卡住检测，LAG_DETECT_TIME 时间检测一次位置
public Action Timer_CheckLag(Handle timer, int client)
{
	if (IsAiTank(client))
	{
		float selfpos[3] = {0.0};
		GetClientAbsOrigin(client, selfpos);
		if (!Is_InConsumeRaidus(selfpos, eTankStructure[client].fNowPos, LAG_DETECT_RAIDUS))
		{
			CopyVectors(selfpos, eTankStructure[client].fNowPos);
			#if (DEBUG_ALL)
				PrintToConsoleAll("[Ai-Tank]：当前位置：%.2f %.2f，记录位置：%.2f %.2f，没有卡住，复制向量", selfpos[0], selfpos[1], eTankStructure[client].fNowPos[0], eTankStructure[client].fNowPos[1]);
			#endif
		}
		else if (GetEntProp(client, Prop_Send, "m_zombieState") == 0 && eTankStructure[client].bCanConsume && !Is_InConsumeRaidus(selfpos, eTankStructure[client].fNowPos, LAG_DETECT_RAIDUS))
		{
			// 若在消耗的途中卡住，则重新找消耗位置
			eTankStructure[client].bInConsumePlace = eTankStructure[client].bIsReachingFunctionPos = eTankStructure[client].bIsReachingRayPos = false;
			ConsumePosInit(client);
			#if (DEBUG_ALL)
				PrintToConsoleAll("[Ai-Tank]：当前坦克在前往消耗位置的过程中卡住，重置消耗位");
			#endif
		}
		else if (GetEntProp(client, Prop_Send, "m_zombieState") == 0)
		{
			// 若在攻击的途中卡住，则命令强制攻击最近的生还者
			int newtarget = GetClosetMobileSurvivor(client);
			if (IsValidSurvivor(newtarget))
			{
				Logic_RunScript(COMMANDABOT_ATTACK, GetClientUserId(client), GetClientUserId(newtarget));
				#if (DEBUG_ALL)
					PrintToConsoleAll("[Ai-Tank]：当前坦克在攻击目标的过程中卡住，选择新的攻击目标：%N，强制攻击", newtarget);
				#endif
			}
		}
		else
		{
			/* float eyeangles[3] = {0.0}, look_at[3] = {0.0};
			GetClientEyeAngles(client, eyeangles);
			GetAngleVectors(eyeangles, look_at, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(look_at, look_at);
			ScaleVector(look_at, 251.0);
			look_at[1] = GetRandomFloat(look_at[1], look_at[1] + 360.0);
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, look_at); */
			// 获取 Tank 眼睛角度，x，z 置 0，y 每 2s 偏移 30 度，获取方向向量进行推动
			float eyeAngles[3] = {0.0}, resultVec[3] = {0.0};
			GetClientEyeAngles(client, eyeAngles);
			resultVec[1] = eyeAngles[1] + LAG_DETECT_OFFSET;
			GetAngleVectors(resultVec, resultVec, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(resultVec, resultVec);
			ScaleVector(resultVec, 251.0);
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, resultVec);
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

// 检测坦克下一帧的位置是否会撞墙或向下受到伤害或会掉落
bool Dont_HitWall_Or_Fall(int client, float vel[3])
{
	bool hullrayhit = false;
	int down_hullray_hitent = -1;
	char down_hullray_hitent_classname[16] = {'\0'};
	float selfpos[3] = {0.0}, resultpos[3] = {0.0}, mins[3] = {0.0}, maxs[3] = {0.0}, hullray_endpos[3] = {0.0}, down_hullray_startpos[3] = {0.0}, down_hullray_endpos[3] = {0.0}, down_hullray_hitpos[3] = {0.0};
	GetClientAbsOrigin(client, selfpos);
	AddVectors(selfpos, vel, resultpos);
	GetClientMins(client, mins);
	GetClientMaxs(client, maxs);
	selfpos[2] += NAV_MESH_HEIGHT;
	resultpos[2] += NAV_MESH_HEIGHT;
	// 由自身位置 +NAV_MESH_HEIGHT 高度 向前射出大小为 mins，maxs 的固体，检测前方 g_hAttackRange 距离是否能撞到，撞到则不允许连跳
	Handle hTrace = TR_TraceHullFilterEx(selfpos, resultpos, mins, maxs, MASK_NPCSOLID_BRUSHONLY, TR_EntityFilter);
	if (TR_DidHit(hTrace))
	{
		hullrayhit = true;
		TR_GetEndPosition(hullray_endpos, hTrace);
		if (GetVectorDistance(selfpos, hullray_endpos) < g_hAttackRange.FloatValue * 0.6 && eTankStructure[client].bCanConsume)
		{
			delete hTrace;
			return false;
		}
		else if(!eTankStructure[client].bCanConsume)
		{
			delete hTrace;
			return true;
		}
	}
	delete hTrace;
	resultpos[2] -= NAV_MESH_HEIGHT;
	// 没有撞到，则说明前方 g_hAttackRange 距离内没有障碍物，接着进行下一帧理论位置向下的检测，检测是否有会对自身造成伤害的位置
	if (!hullrayhit)
	{
		down_hullray_startpos = resultpos;
	}
	CopyVectors(down_hullray_startpos, down_hullray_endpos);
	down_hullray_endpos[2] -= 100000.0;
	Handle hDownTrace = TR_TraceHullFilterEx(down_hullray_startpos, down_hullray_endpos, mins, maxs, MASK_NPCSOLID_BRUSHONLY, TR_EntityFilter);
	if (TR_DidHit(hDownTrace))
	{
		TR_GetEndPosition(down_hullray_hitpos, hDownTrace);
		int target;
		float targetPos[3];
		target = GetClientAimTarget(client);
		if(target >= 0)
			GetClientAbsOrigin(target, targetPos);
		// 如果向下的射线撞到的位置减去起始位置的高度大于 FALL_DETECT_HEIGHT 则说明会掉下去，但是如果目标在下方，依旧可以进行下一步检测,否则停止连跳
		if (down_hullray_startpos[2] - down_hullray_hitpos[2] > FALL_DETECT_HEIGHT && (target < 0 || (target >= 0 && down_hullray_hitpos[2] < targetPos[2])))
		{
			delete hDownTrace;
			return false;
		}
		down_hullray_hitent = TR_GetEntityIndex(hDownTrace);
		GetEdictClassname(down_hullray_hitent, down_hullray_hitent_classname, sizeof(down_hullray_hitent_classname));
		if (strcmp(down_hullray_hitent_classname, "trigger_hurt") == 0)
		{
			delete hDownTrace;
			return false;
		}
		delete hDownTrace;
		return true;
	}
	delete hDownTrace;
	return false;
}

bool TR_EntityFilter(int entity, int mask)
{
	if (entity <= MaxClients)
	{
		return false;
	}
	else if (entity > MaxClients)
	{
		char classname[16] = {'\0'};
		GetEdictClassname(entity, classname, sizeof(classname));
		if (strcmp(classname, "infected") == 0 || strcmp(classname, "witch") == 0 || strcmp(classname, "prop_physics") == 0 || strcmp(classname, "tank_rock") == 0)
		{
			return false;
		}
	}
	return true;
}

// 返回当前在场特感数量，不包括坦克
int GetSiCount_ExcludeTank(bool &survivor_failed, int &vomitsurvivor)
{
	int count = 0, highest_health = 0, lowest_health = 65535;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && IsClientInGame(client))
		{
			if (GetClientTeam(client) == view_as<int>(TEAM_INFECTED) && GetEntProp(client, Prop_Send, "m_zombieClass") != view_as<int>(ZC_TANK))
			{
				count += 1;
			}
			else if (GetClientTeam(client) == view_as<int>(TEAM_SURVIVOR) && IsPlayerAlive(client) && !IsClientPinned(client) && !IsClientIncapped(client))
			{
				survivor_failed = false;
				// 计算正在胆汁状态中的生还者数量
				if (GetGameTime() < (GetEntPropFloat(client, Prop_Send, "m_vomitStart") + g_hVomitInterval.IntValue + g_hFadeTime.IntValue))
				{
					vomitsurvivor += 1;
				}
				// 根据目标选择找到血量最高或者最低的生还者
				switch (g_hTargetChoose.IntValue)
				{
					case 2:
					{
						int low_health = GetClientHealth(client);
						if (low_health < lowest_health)
						{
							lowest_health = low_health;
							lowest_health_target = client;
						}
					}
					case 3:
					{
						int high_health = GetClientHealth(client);
						if (high_health > highest_health)
						{
							highest_health = high_health;
							highest_health_target = client;
						}
					}
				}
			}
		}
	}
	return count;
}

// 获取允许扔石头的范围
void Get_ThrowRange()
{
	char throw_range[16] = {'\0'}, temp[2][6];
	g_hAllowThrowRange.GetString(throw_range, sizeof(throw_range));
	ExplodeString(throw_range, ",", temp, 2, 6);
	throw_min_range = StringToInt(temp[0]);
	throw_max_range = StringToInt(temp[1]);
}

// 判断当前坦克是否可以消耗
bool Check_TankCanConsume(int client, int m_sicount, int target, int vomitsurvivor)
{
	bool bCanConsume = false;
	if (IsAiTank(client) && IsValidSurvivor(target))
	{
		float selfpos[3] = {0.0}, targetpos[3] = {0.0};
		GetClientAbsOrigin(client, selfpos);
		GetClientAbsOrigin(target, targetpos);
		// 在场特感小于特感刷新数量减去 g_hConsumeInfSub 值且自身位置大于等于生还地图进度，允许消耗，最后是或关系（倒地人数大于等于限制或距离大于限制则可以继续消耗找位）
		// 由于 OnPlayerRunCmd 下面已经判断坦克路程是否在生还前面，否则不允许压制，此处无需判断
		if (IsPlayerAlive(client) && GetClientHealth(client) > g_hConsumeHealth.IntValue && (m_sicount <= g_hSiLimit.IntValue - g_hConsumeInfSub.IntValue) && vomitsurvivor < g_hVomitAttackNum.IntValue && (eTankStructure[client].iIncappedCount >= g_hConsumeIncap.IntValue || GetVectorDistance(selfpos, targetpos) > g_hForceAttackDist.FloatValue))
		{
			bCanConsume = true;
			// 记录生还者当前地图完成度
			if (!eTankStructure[client].bHasRecordProgress)
			{
				Record_Survivor_Progress(client);
				eTankStructure[client].bHasRecordProgress = true;
			}
		}
		// 当前上面任意条件不满足时，不允许消耗
		else if (IsPlayerAlive(client) && !IsClientIncapped(client) && eTankStructure[client].bCanConsume)
		{
			CreateTimer(1.0, Timer_TankAction_Reset, client);
			#if (DEBUG_ALL)
				PrintToConsoleAll("[Ai-Tank]：【当前坦克血量：%d 或 距离：%.2f 或 被喷：%d 或 当前特感：%d】 -> 不满足要求，强制压制", GetClientHealth(client), GetVectorDistance(selfpos, targetpos), vomitsurvivor, m_sicount);
			#endif
		}
	}
	return bCanConsume;
}

// 令当前坦克进行消耗找位，函数与射线找位同时进行，如果函数找到位置而射线没找到位置则先前往函数找位位置，直到射线找到位置前往射线找位位置
// OnPlayerRunCmd 中已经判断过可以消耗才执行这个函数，故这里不需要再次判断是否可以消耗
void Find_And_Goto_ConsumePos(int client, int target)
{
	// 如果当前坦克的函数找位位置为 0.0，即没有函数找位的位置，进行函数找位，否则，控制其进入函数找位的位置
	if (eTankStructure[client].fFunctionConsumePos[0] == 0.0 && eTankStructure[client].bCanInitPos && !eTankStructure[client].bIsReachingFunctionPos && !eTankStructure[client].bInConsumePlace)
	{
		Function_FindConsumePos(client, target);
	}
	if (eTankStructure[client].fFunctionConsumePos[0] != 0.0 && !eTankStructure[client].bInConsumePlace && !eTankStructure[client].bIsReachingFunctionPos)
	{
		CreateTimer(1.0, Timer_CommandToFunctionPos, client, TIMER_REPEAT);
		eTankStructure[client].bIsReachingFunctionPos = true;
		#if (DEBUG_ALL)
			PrintToConsoleAll("[Ai-Tank]：函数找到的消耗位：%.2f %.2f %.2f", eTankStructure[client].fFunctionConsumePos[0], eTankStructure[client].fFunctionConsumePos[1], eTankStructure[client].fFunctionConsumePos[2]);
		#endif
	}
	// 如果当前坦克的射线找位位置为 0.0，进行射线找位，否则，尽管坦克正在前往函数找位的位置，也令其进入射线找位的位置
	if (eTankStructure[client].fRayConsumePos[0] == 0.0 && eTankStructure[client].bCanInitPos && !eTankStructure[client].bIsReachingRayPos && !eTankStructure[client].bInConsumePlace)
	{
		Ray_FindConsumePos(client, target);
	}
	if (eTankStructure[client].fRayConsumePos[0] != 0.0 && !eTankStructure[client].bInConsumePlace && !eTankStructure[client].bIsReachingRayPos)
	{
		CreateTimer(1.0, Timer_CommandToRayPos, client, TIMER_REPEAT);
		eTankStructure[client].bIsReachingRayPos = true;
		#if (DEBUG_ALL)
			PrintToConsoleAll("[Ai-Tank]：射线找到的消耗位：%.2f %.2f %.2f", eTankStructure[client].fRayConsumePos[0], eTankStructure[client].fRayConsumePos[1], eTankStructure[client].fRayConsumePos[2]);
		#endif
	}
}

// 记录生还者当前地图完成度
void Record_Survivor_Progress(int client)
{
	if (IsAiTank(client))
	{
		int target = L4D_GetHighestFlowSurvivor();
		if (IsValidSurvivor(target))
		{
			float targetpos[3] = {0.0};
			GetClientAbsOrigin(target, targetpos);
			Address pNavArea = L4D2Direct_GetTerrorNavArea(targetpos);
			if (pNavArea == Address_Null)
			{
				pNavArea = view_as<Address>(L4D_GetNearestNavArea(targetpos, 300.0));
			}
			eTankStructure[client].iConsumeSurPercent = Calculate_Flow(pNavArea);
			#if (DEBUG_ALL)
				PrintToConsoleAll("[Ai-Tank]：当前坦克可以消耗，当前生还者进度：%d", eTankStructure[client].iConsumeSurPercent);
			#endif
		}
	}
}

// 检查生还者进度是否超过限制
void Survivor_Progress_Check(int client)
{
	int target = L4D_GetHighestFlowSurvivor(), now_flow = 0;
	if (IsAiTank(client) && IsValidSurvivor(target))
	{
		float targetpos[3] = {0.0};
		GetClientAbsOrigin(target, targetpos);
		Address pNavArea = L4D2Direct_GetTerrorNavArea(targetpos);
		if (pNavArea == Address_Null)
		{
			pNavArea = view_as<Address>(L4D_GetNearestNavArea(targetpos, 300.0));
		}
		now_flow = Calculate_Flow(pNavArea);
		if (eTankStructure[client].bCanConsume && now_flow > (eTankStructure[client].iConsumeSurPercent + g_hForceAttackProgress.IntValue))
		{
			CreateTimer(1.0, Timer_TankAction_Reset, client);
			eTankStructure[client].bCanConsume = false;
			#if (DEBUG_ALL)
				PrintToConsoleAll("[Ai-Tank]：当前生还者进度：%d，大于限制进度：%d，控制坦克强制压制", now_flow, eTankStructure[client].iConsumeSurPercent + g_hForceAttackProgress.IntValue);
			#endif
		}
	}
}

// 让坦克去函数找到的消耗位
public Action Timer_CommandToFunctionPos(Handle timer, int client)
{
	if (IsAiTank(client))
	{
		float selfpos[3] = {0.0};
		GetClientAbsOrigin(client, selfpos);
		if (eTankStructure[client].fFunctionConsumePos[0] != 0.0 && eTankStructure[client].fRayConsumePos[0] == 0.0 && !Is_InConsumeRaidus(selfpos, eTankStructure[client].fFunctionConsumePos, g_hConsumePosRaidus.IntValue * 3))
		{
			#if (DEBUG_ALL)
				PrintToConsoleAll("[Ai-Tank]：控制当前坦克去往函数的消耗位");
			#endif
			Logic_RunScript(COMMANDABOT_MOVE, eTankStructure[client].fFunctionConsumePos[0], eTankStructure[client].fFunctionConsumePos[1], eTankStructure[client].fFunctionConsumePos[2], GetClientUserId(client));
			return Plugin_Continue;
		}
		else
		{
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

// 让坦克去射线找到的消耗位
public Action Timer_CommandToRayPos(Handle timer, int client)
{
	if (IsAiTank(client))
	{
		float selfpos[3] = {0.0};
		GetClientAbsOrigin(client, selfpos);
		if (eTankStructure[client].fRayConsumePos[0] != 0.0 && !Is_InConsumeRaidus(selfpos, eTankStructure[client].fRayConsumePos, g_hConsumePosRaidus.IntValue * 3))
		{
			#if (DEBUG_ALL)
				PrintToConsoleAll("[Ai-Tank]：控制当前坦克去往射线的消耗位");
			#endif
			ConsumePosInit(client, true, false);
			Logic_RunScript(COMMANDABOT_MOVE, eTankStructure[client].fRayConsumePos[0], eTankStructure[client].fRayConsumePos[1], eTankStructure[client].fRayConsumePos[2], GetClientUserId(client));
			return Plugin_Continue;
		}
		else
		{
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}
// 重置坦克行为
public Action Timer_TankAction_Reset(Handle timer, int client)
{
	if (IsAiTank(client))
	{
		Logic_RunScript(COMMANDABOT_RESET, GetClientUserId(client));
		ConsumePosInit(client);
		eTankStructure[client].struct_Init();
		eTankStructure[client].bCanInitPos = true;
		g_hRockInterval.RestoreDefault();
		g_hRockMinInterval.RestoreDefault();
		#if (DEBUG_ALL)
			PrintToConsoleAll("[Ai-Tank]：函数内重置当前坦克行为");
		#endif
	}
	return Plugin_Continue;
}

// 判断最近生还者与正在消耗的坦克之间的距离，如果小于 g_hFindNewPosDist 值且可见，找新的消耗位
void ConsumePos_NearestTargetDist_Check(int client, int targetdist, bool has_sight)
{
	if (eTankStructure[client].bInConsumePlace && targetdist <= g_hFindNewPosDist.IntValue && has_sight)
	{
		ConsumePosInit(client);
		eTankStructure[client].bIsReachingFunctionPos = eTankStructure[client].bIsReachingRayPos = eTankStructure[client].bInConsumePlace = false;
		#if (DEBUG_ALL)
			PrintToConsoleAll("[Ai-Tank]：当前消耗位可视玩家，且距离小于：%d，重新找位", g_hFindNewPosDist.IntValue);
		#endif
	}
}

// 判断射线找到的消耗位是否可以看见玩家，如果不能看到玩家，令其找新的函数与射线消耗位
void RayPos_Visible_Check(int client)
{
	if (eTankStructure[client].bInConsumePlace && (eTankStructure[client].fFunctionConsumePos[0] != 0.0 || eTankStructure[client].fRayConsumePos[0] != 0.0) && !Pos_IsVisibleTo_Player(client, eTankStructure[client].fRayConsumePos))
	{
		ConsumePosInit(client);
		eTankStructure[client].bIsReachingFunctionPos = eTankStructure[client].bIsReachingRayPos = eTankStructure[client].bInConsumePlace = false;
		#if (DEBUG_ALL)
			PrintToConsoleAll("[Ai-Tank]：当前消耗位不可直视任何玩家，选择新的消耗位");
		#endif
	}
}

// 当前坦克走到消耗位范围中时，令其扔石头
Action In_ConsumePos_ThrowRock(int client, float selfpos[3], int sequence, int &buttons)
{
	if (Is_InConsumeRaidus(selfpos, eTankStructure[client].fFunctionConsumePos, g_hConsumePosRaidus.IntValue) || Is_InConsumeRaidus(selfpos, eTankStructure[client].fRayConsumePos, g_hConsumePosRaidus.IntValue))
	{
		eTankStructure[client].bInConsumePlace = true;
		eTankStructure[client].bIsReachingFunctionPos = eTankStructure[client].bIsReachingRayPos = false;
		g_hRockInterval.SetInt(g_hConsumeRockInterval.IntValue);
		g_hRockMinInterval.SetInt(g_hConsumeRockInterval.IntValue);
		// 获取当前动画序列，如果当前动画序列等于任意一个投掷动画，则存入时间戳
		if (sequence == 49 || sequence == 50 || sequence == 51)
		{
			eTankStructure[client].fRockThrowTime = GetGameTime();
		}
		else if (GetGameTime() - eTankStructure[client].fRockThrowTime > ROCK_AIM_TIME)
		{
			buttons |= IN_ATTACK2;
			return Plugin_Changed;
		}
	}
	else
	{
		if (eTankStructure[client].fFunctionConsumePos[0] != 0.0 && eTankStructure[client].fRayConsumePos[0] == 0.0 && !eTankStructure[client].bIsReachingFunctionPos)
		{
			eTankStructure[client].bIsReachingFunctionPos = true;
			CreateTimer(1.0, Timer_CommandToFunctionPos, client, TIMER_REPEAT);
			#if (DEBUG_ALL)
				PrintToConsoleAll("[Ai-Tank]：当前坦克走出函数消耗位，重新进入");
			#endif
		}
		if (eTankStructure[client].fRayConsumePos[0] != 0.0 && !eTankStructure[client].bIsReachingRayPos)
		{
			eTankStructure[client].bIsReachingRayPos = true;
			CreateTimer(1.0, Timer_CommandToRayPos, client, TIMER_REPEAT);
			#if (DEBUG_ALL)
				PrintToConsoleAll("[Ai-Tank]：当前坦克走出射线消耗位，重新进入");
			#endif
		}
	}
	return Plugin_Continue;
}

// 使用函数找消耗位
void Function_FindConsumePos(int client, int target)
{
	L4D_GetRandomPZSpawnPosition(target, view_as<int>(ZC_TANK), 8, eTankStructure[client].fFunctionConsumePos);
}

// 使用射线找消耗位
void Ray_FindConsumePos(int client, int target)
{
	if (IsAiTank(client) && IsValidSurvivor(target))
	{
		float selfpos[3] = {0.0}, targetpos[3] = {0.0}, grid_min[2] = {0.0}, grid_max[2] = {0.0}, down_ray_pos[3] = {0.0}, down_ray_endpos[3] = {0.0};
		GetClientAbsOrigin(client, selfpos);
		GetClientAbsOrigin(target, targetpos);
		grid_min[0] = targetpos[0];	grid_max[0] = targetpos[0];
		grid_min[1] = targetpos[1];	grid_max[1] = targetpos[1];
		grid_min[0] -= g_hRayRaidus.FloatValue;
		grid_min[1] -= g_hRayRaidus.FloatValue;
		grid_max[0] += g_hRayRaidus.FloatValue;
		grid_max[1] += g_hRayRaidus.FloatValue;
		down_ray_pos[0] = GetRandomFloat(grid_min[0], grid_max[0]);
		down_ray_pos[1] = GetRandomFloat(grid_min[1], grid_max[1]);
		down_ray_pos[2] = GetRandomFloat(targetpos[2], targetpos[2] + 500.0);
		TR_TraceRay(down_ray_pos, RAY_ANGLE, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite);
		if (TR_DidHit())
		{
			TR_GetEndPosition(down_ray_endpos);
			down_ray_endpos[2] += ROCK_THROW_HEIGHT;
			#if (DEBUG_ALL)
				ShowLaser(4, down_ray_pos, down_ray_endpos);
			#endif
			if (Pos_IsVisibleTo_Player(client, down_ray_endpos) && IsOnValidMesh(down_ray_endpos) && !IsPos_StuckTank(down_ray_endpos, client) && Is_Pos_Ahead(down_ray_endpos) && GetVectorDistance(down_ray_endpos, targetpos) >= g_hConsumeDist.FloatValue)
			{
				CopyVectors(down_ray_endpos, eTankStructure[client].fRayConsumePos);
			}
		}
	}
}

// 判断给定位置是否在有效 NAV MESH 上
bool IsOnValidMesh(float refpos[3])
{
	Address pNav = L4D2Direct_GetTerrorNavArea(refpos);
	return pNav != Address_Null;
}

// 判断位置是否会将坦克卡住
bool IsPos_StuckTank(float refpos[3], int client)
{
	bool stuck = false;
	float client_mins[3] = {0.0}, client_maxs[3] = {0.0}, up_hull_endpos[3] = {0.0};
	GetClientMins(client, client_mins);
	GetClientMaxs(client, client_maxs);
	CopyVectors(refpos, up_hull_endpos);
	up_hull_endpos[2] += 72.0;
	TR_TraceHullFilter(refpos, up_hull_endpos, client_mins, client_maxs, MASK_NPCSOLID_BRUSHONLY, TR_EntityFilter);
	stuck = TR_DidHit();
	return stuck;
}

// 判断坦克当前位置是否在消耗范围内
bool Is_InConsumeRaidus(float selfpos[3], float refpos[3], int raidus)
{
	return view_as<bool>(Is_InRoundArea(selfpos[0], selfpos[1], refpos[0], refpos[1], raidus));
}

// 判断给定位置是否处于圆周内
bool Is_InRoundArea(float selfx, float selfy, float xpos, float ypos, int raidus)
{
	return view_as<bool>((Pow(FloatAbs(xpos - selfx), 2.0) + Pow(FloatAbs(ypos - selfy), 2.0)) < Pow(float(raidus), 2.0));
}

// 禁止低抛，低抛动画序列为 50，任意选择一个其他投掷序列 49，51，改变当前序列
public Action L4D2_OnSelectTankAttack(int client, int &sequence)
{
	if (IsFakeClient(client) && sequence == 50)
	{
		sequence = GetRandomInt(0, 1) ? 49 : 51;
		return Plugin_Handled;
	}
	return Plugin_Changed;
}

// 判断一个坐标是否在当前最高路程的生还者前面
bool Is_Pos_Ahead(float refpos[3])
{
	int pos_flow = 0, target_flow = 0;
	Address pNowNav = L4D2Direct_GetTerrorNavArea(refpos);
	if (pNowNav == Address_Null)
	{
		pNowNav = view_as<Address>(L4D_GetNearestNavArea(refpos, 300.0));
	}
	pos_flow = Calculate_Flow(pNowNav);
	int target = L4D_GetHighestFlowSurvivor();
	if (IsValidSurvivor(target))
	{
		float targetpos[3] = {0.0};
		GetClientAbsOrigin(target, targetpos);
		Address pTargetNav = L4D2Direct_GetTerrorNavArea(targetpos);
		if (pTargetNav == Address_Null)
		{
			pTargetNav = view_as<Address>(L4D_GetNearestNavArea(refpos, 300.0));
		}
		target_flow = Calculate_Flow(pTargetNav);
	}
	return view_as<bool>(pos_flow >= target_flow);
}
int Calculate_Flow(Address pNavArea)
{
	float now_nav_flow = L4D2Direct_GetTerrorNavAreaFlow(pNavArea) / L4D2Direct_GetMapMaxFlowDistance();
	float now_nav_promixity = now_nav_flow + g_hVsBossFlowBuffer.FloatValue / L4D2Direct_GetMapMaxFlowDistance();
	if (now_nav_promixity > 1.0)
	{
		now_nav_promixity = 1.0;
	}
	return RoundToNearest(now_nav_promixity * 100.0);
}

// 检测坦克周围是否有梯子
// @ Proposal by Morzlee
public Action checkLadderAroundHandler(Handle timer, int client)
{
	if (!IsAiTank(client)) { return Plugin_Stop; }
	float tankPos[3] = {0.0}, curLadderPos[3] = {0.0};
	GetClientAbsOrigin(client, tankPos);
	#if (DEBUG_ALL)
	{
		PrintToConsoleAll("梯子检测");
	}
	#endif
	for (int i = 0; i < ladderList.Length; i++)
	{
		ladderList.GetArray(i, curLadderPos);
		tankPos[2] = curLadderPos[2] = 0.0;
		if (GetVectorDistance(tankPos, curLadderPos) <= 150.0)
		{
			#if (DEBUG_ALL)
			{
				PrintToConsoleAll("[Ai-Tank]：Tank 坐标：[%.2f, %.2f, %.2f]，梯子：%d 坐标：[%.2f, %.2f, %.2f]，距离：%.2f", tankPos[0], tankPos[1], tankPos[2],
				 (i + 1), curLadderPos[0], curLadderPos[1], curLadderPos[2], GetVectorDistance(tankPos, curLadderPos));
			}
			#endif
			eTankStructure[client].bCanLockVision = false;
			eTankStructure[client].fLockVisonTime = GetGameTime();
			return Plugin_Continue;
		}
	}
	if (GetGameTime() - eTankStructure[client].fLockVisonTime > VISION_UNLOCK_TIME) { eTankStructure[client].bCanLockVision = true; }
	return Plugin_Continue;
}

// from smlib https://github.com/bcserv/smlib

/**
 * Rotates a vector around its zero-point.
 * Note: As example you can rotate mins and maxs of an entity and then add its origin to mins and maxs to get its bounding box in relation to the world and its rotation.
 * When used with players use the following angle input:
 *   angles[0] = 0.0;
 *   angles[1] = 0.0;
 *   angles[2] = playerEyeAngles[1];
 *
 * @param vec 			Vector to rotate.
 * @param angles 		How to rotate the vector.
 * @param result		Output vector.
 * @noreturn
 */
stock void Math_RotateVector(const float vec[3], const float angles[3], float result[3])
{
    // First the angle/radiant calculations
    float rad[3];
    // I don't really know why, but the alpha, beta, gamma order of the angles are messed up...
    // 2 = xAxis
    // 0 = yAxis
    // 1 = zAxis
    rad[0] = DegToRad(angles[2]);
    rad[1] = DegToRad(angles[0]);
    rad[2] = DegToRad(angles[1]);

    // Pre-calc function calls
    float cosAlpha = Cosine(rad[0]);
    float sinAlpha = Sine(rad[0]);
    float cosBeta = Cosine(rad[1]);
    float sinBeta = Sine(rad[1]);
    float cosGamma = Cosine(rad[2]);
    float sinGamma = Sine(rad[2]);

    // 3D rotation matrix for more information: http://en.wikipedia.org/wiki/Rotation_matrix#In_three_dimensions
    float x = vec[0];
    float y = vec[1];
    float z = vec[2];
    float newX;
    float newY;
    float newZ;
    newY = cosAlpha*y - sinAlpha*z;
    newZ = cosAlpha*z + sinAlpha*y;
    y = newY;
    z = newZ;

    newX = cosBeta*x + sinBeta*z;
    newZ = cosBeta*z - sinBeta*x;
    x = newX;
    z = newZ;

    newX = cosGamma*x - sinGamma*y;
    newY = cosGamma*y + sinGamma*x;
    x = newX;
    y = newY;

    // Store everything...
    result[0] = x;
    result[1] = y;
    result[2] = z;
}
