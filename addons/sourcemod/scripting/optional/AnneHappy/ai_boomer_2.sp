#pragma semicolon 1 
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <treeutil>

#define CVAR_FLAG FCVAR_NOTIFY
#define EYE_ANGLE_UP_HEIGHT 15.0
#define NAV_MESH_HEIGHT 20.0
#define FALL_DETECT_HEIGHT 120.0
#define COMMAND_INTERVAL 1.0
#define PLAYER_HEIGHT 72.0
#define TURN_ANGLE_DIVIDE 3.0
#define DEBUG_ALL 0

enum AimType
{
	AimEye,
	AimBody,
	AimChest
};

public Plugin myinfo = 
{
	name 			= "Ai Boomer 2.0",
	author 			= "夜羽真白",
	description 	= "Ai Boomer 增强 2.0 版本 (integrated tweaks by ChatGPT)",
	version 		= "2023/1/17+rev2025-09-05",
	url 			= "https://steamcommunity.com/id/saku_ra/"
}

ConVar
	g_hAllowBhop,
	g_hBhopSpeed,
	g_hUpVision,
	g_hTurnVision,
	g_hForceBile,
	g_hBileFindRange,
	g_hVomitRange,
	g_hVomitDuration,
	g_hVomitInterval,
	g_hTurnInterval,
	g_hAllowInDegreeForceBile,
	g_hAllowAutoFrame;

// Bools
bool
	can_bile[MAXPLAYERS + 1] = { true },
	in_bile_interval[MAXPLAYERS + 1] = { false },
	isInBileState[MAXPLAYERS + 1] = { false };

// Ints，bile_frame 0 位：当前目标索引，1 位：循环次数
int
	bile_frame[MAXPLAYERS + 1][2],
	/* 第二次强制喷吐检测，0位：当前检测帧数，1位：目标检测帧数 */
	secondCheckFrame[MAXPLAYERS + 1];

// Lists
ArrayList
	targetList[MAXPLAYERS + 1] = { null };

public void OnPluginStart()
{
	// CreateConVars
	g_hAllowBhop = CreateConVar("ai_BoomerBhop", "1", "是否开启 Boomer 连跳", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hBhopSpeed = CreateConVar("ai_BoomerBhopSpeed", "150.0", "Boomer 连跳速度", CVAR_FLAG, true, 0.0);
	g_hUpVision = CreateConVar("ai_BoomerUpVision", "1", "Boomer 喷吐时是否上抬视角", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hTurnVision = CreateConVar("ai_BoomerTurnVision", "1", "Boomer 喷吐时是否旋转视角", CVAR_FLAG, true, 0.0, true, 1.0);

	// 注意：保持默认 0（关闭），以符合“不要打开强制胆汁”的要求
	g_hForceBile = CreateConVar("ai_BoomerForceBile", "0", "是否开启生还者到 Boomer 喷吐范围内强制被喷", CVAR_FLAG, true, 0.0, true, 1.0);

	g_hBileFindRange = CreateConVar("ai_BoomerBileFindRange", "300", "在这个距离内有被控或倒地的生还 Boomer 会优先攻击，0 = 禁用", CVAR_FLAG, true, 0.0);
	g_hTurnInterval = CreateConVar("ai_BoomerTurnInterval", "15", "Boomer 喷吐旋转视角时每隔多少帧转移一个目标", CVAR_FLAG, true, 0.0);
	// 在角度内是否允许强制喷吐
	g_hAllowInDegreeForceBile = CreateConVar("ai_BoomerDegreeForceBile", "10", "是否允许目标和 Boomer 视角处在这个角度内且能看到目标头部强制喷吐，0 = 禁用", CVAR_FLAG, true, 0.0);
	g_hAllowAutoFrame = CreateConVar("ai_BoomerAutoFrame", "1", "是否允许 Boomer 根据目标的角度自动计算视野在下一个目标的帧数", CVAR_FLAG, true, 0.0, true, 1.0);

	/* 其他 Cvar */
	g_hVomitRange = FindConVar("z_vomit_range");
	g_hVomitDuration = FindConVar("z_vomit_duration");
	g_hVomitInterval = FindConVar("z_vomit_interval");

	// HookEvents
	HookEvent("player_spawn", evt_PlayerSpawn);
	HookEvent("player_shoved", evt_PlayerShoved);
	HookEvent("player_now_it", evt_PlayerNowIt);
	HookEvent("round_start", evt_RoundStart);

	// SetConVars
	SetConVarFloat(FindConVar("boomer_exposed_time_tolerance"), 10000.0);
	SetConVarFloat(FindConVar("boomer_vomit_delay"), 0.1);
}

public void OnPluginEnd()
{
	FindConVar("boomer_exposed_time_tolerance").RestoreDefault();
	FindConVar("boomer_vomit_delay").RestoreDefault();
	for (int i = 0; i < MAXPLAYERS + 1; i++)
	{
		delete targetList[i];
		targetList[i] = null;
	}
}

/* 回合开始，每个玩家的二次检测帧数为 0 */
public void evt_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < MAXPLAYERS + 1; i++) { secondCheckFrame[i] = 0; }
}

public void evt_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsBoomer(client)) { return; }
	in_bile_interval[client] = true;
	CreateTimer(1.5, Timer_ResetAbility, client);
}

public void evt_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsBoomer(client)) { return; }
	can_bile[client] = true;
	in_bile_interval[client] = false;
	bile_frame[client][0] = bile_frame[client][1] = 0;
	// Build ArrayList
	if (targetList[client] != null) { targetList[client].Clear(); }
	else { targetList[client] = new ArrayList(2); }
}

/* 玩家被喷，不重复给他上喷吐效果，当玩家胆汁效果过后，将被喷状态设置为 false，后续可以继续上喷吐效果 */
public void evt_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker")), victim = GetClientOfUserId(event.GetInt("userid"));
	if (!IsBoomer(attacker) || !IsPlayerAlive(attacker) || !IsValidSurvivor(victim) || !IsPlayerAlive(victim)) { return; }
	isInBileState[victim] = true;
	CreateTimer(FindConVar("sb_vomit_blind_time").FloatValue, resetBileStateHandler, victim);
}

public Action resetBileStateHandler(Handle timer, int client)
{
	isInBileState[client] = false;
	secondCheckFrame[client] = 0;
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if (!IsBoomer(client)) { return Plugin_Continue; }

	float self_pos[3], self_eye_pos[3], targetPos[3], target_eye_pos[3], vec_speed[3], aim_angles[3], vel_buffer[3], targetDist, cur_speed;
	int flags, target, ability, isAbilityUsing, i;
	bool has_sight;

	flags = GetEntityFlags(client);
	target = GetClosetSurvivor(client);
	ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (!IsValidEntity(ability)) { return Plugin_Continue; }

	has_sight = view_as<bool>(GetEntProp(client, Prop_Send, "m_hasVisibleThreats"));
	isAbilityUsing = GetEntProp(ability, Prop_Send, "m_isSpraying");

	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec_speed);
	cur_speed = SquareRoot(Pow(vec_speed[0], 2.0) + Pow(vec_speed[1], 2.0));

	GetClientAbsOrigin(client, self_pos);
	GetClientEyePosition(client, self_eye_pos);

	if (IsValidSurvivor(target)) {
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPos);
		GetClientEyePosition(target, target_eye_pos);
		targetDist = GetVectorDistance(self_pos, targetPos);
	}

	// === 初次对准 + 贴脸仰角兜底（修正 C） =========================================
	if (has_sight && IsValidSurvivor(target) && !in_bile_interval[client] && targetList[client].Length < 1)
	{
		if (targetDist <= g_hVomitRange.FloatValue)
		{
			ComputeAimAngles(client, target, aim_angles, AimEye);

			// [CHANGE] 使用眼睛高度差与“贴脸仰角兜底”，避免“看脚下”
			if (g_hUpVision.BoolValue)
			{
				float eyeDelta = self_eye_pos[2] - target_eye_pos[2]; // 自己眼睛 - 目标眼睛
				float factor = (eyeDelta > 0.0) ? 1.5 : 0.8;
				aim_angles[0] -= targetDist / (PLAYER_HEIGHT * factor);

				// 不要明显低头；贴脸时至少给一点仰角
				if (aim_angles[0] > 4.0) aim_angles[0] = 4.0;
				if (targetDist <= 85.0 && aim_angles[0] > -5.0)
					aim_angles[0] = -5.0;
			}
			TeleportEntity(client, NULL_VECTOR, aim_angles, NULL_VECTOR);

			/* 判断第一个目标是否需要强行被喷，boomer 能力使用后过一个目标帧数延时再做一次检测 */
			if (g_hAllowInDegreeForceBile.BoolValue && isInAimOffset(client, target, g_hAllowInDegreeForceBile.FloatValue) && !isInBileState[target] && isAbilityUsing)
			{
				if (secondCheckFrame[target] < g_hTurnInterval.IntValue && !isInBileState[target]) { secondCheckFrame[target]++; }
				else if (!isInBileState[target] && secondCheck(client, target))
				{
					#if DEBUG_ALL
						PrintToConsoleAll("[Ai-Boomer]：%N 第一个目标是：%N 二次检测通过，强制被喷", client, target);
					#endif
					L4D_CTerrorPlayer_OnVomitedUpon(target, client);
					isInBileState[target] = true;
					secondCheckFrame[target] = 0;
				}
			}
		}
	}

	// === 旋转多目标（修正 B：重算距离 + 眼睛高度差 + 贴脸仰角兜底） =================
	if (targetList[client].Length >= 1 && !in_bile_interval[client] && g_hTurnVision.BoolValue)
	{
		/* 当前喷吐目标索引小于胖子目标数 */
		if (bile_frame[client][0] < targetList[client].Length)
		{
			/* 获得下一个要转向的目标 */
			int turnTarget = targetList[client].Get(bile_frame[client][0], 1);
			float turnAngle = targetList[client].Get(bile_frame[client][0], 0);

			if (!IsValidSurvivor(turnTarget) || !IsPlayerAlive(turnTarget))
			{
				bile_frame[client][0] += 1;
				bile_frame[client][1] = 0;
				return Plugin_Continue;
			}

			float turnTargetPos[3], turnTargetEye[3];
			GetClientAbsOrigin(turnTarget, turnTargetPos);
			GetClientEyePosition(turnTarget, turnTargetEye);
			float turnDist = GetVectorDistance(self_pos, turnTargetPos);

			/* 视野转向 & 上抬 */
			ComputeAimAngles(client, turnTarget, aim_angles, AimEye);
			if (g_hUpVision.BoolValue)
			{
				// [CHANGE] 使用眼睛高度差 + 贴脸仰角兜底
				float eyeDelta2 = self_eye_pos[2] - turnTargetEye[2];
				float factor2 = (eyeDelta2 > 0.0) ? 1.5 : 0.8;
				aim_angles[0] -= turnDist / (PLAYER_HEIGHT * factor2);

				if (aim_angles[0] > 4.0) aim_angles[0] = 4.0;
				if (turnDist <= 85.0 && aim_angles[0] > -5.0)
					aim_angles[0] = -5.0;
			}
			TeleportEntity(client, NULL_VECTOR, aim_angles, NULL_VECTOR);

			/* 强制喷吐检测，帧数确认 */
			int targetFrame = g_hAllowAutoFrame.BoolValue ? RoundToNearest(turnAngle / TURN_ANGLE_DIVIDE) : g_hTurnInterval.IntValue;
			#if DEBUG_ALL
				PrintToConsoleAll("[Ai-Boomer]：下一个目标是：%N，角度：%.2f°，检测帧数：%d", turnTarget, turnAngle, targetFrame);
			#endif

			/* 当前 targetFrame = 0，代表目标就在面前，无需再次检测，直接强制被喷即可 */
			if (g_hAllowInDegreeForceBile.BoolValue && g_hAllowAutoFrame.BoolValue && targetFrame == 0)
			{
				L4D_CTerrorPlayer_OnVomitedUpon(turnTarget, client);
				isInBileState[turnTarget] = true;
				secondCheckFrame[turnTarget] = 0;
				bile_frame[client][0] += 1;
				return Plugin_Continue;
			}

			if (bile_frame[client][1] < targetFrame)
			{
				/* 动态目标帧数，强制喷吐 */
				if (g_hAllowInDegreeForceBile.BoolValue)
				{
					if (secondCheckFrame[turnTarget] < targetFrame && !isInBileState[turnTarget])
					{
						#if DEBUG_ALL
							PrintToConsoleAll("[Ai-Boomer]：目标：%N 二次检测帧：%d，被喷：%b，是否通过：%b",
								turnTarget, secondCheckFrame[turnTarget], isInBileState[turnTarget], secondCheck(client, turnTarget));
						#endif
						secondCheckFrame[turnTarget]++;
					}
					else if (!isInBileState[turnTarget] && secondCheck(client, turnTarget))
					{
						#if DEBUG_ALL
							PrintToConsoleAll("[Ai-Boomer]：%N 当前目标：%N，二次检测通过，强制被喷", client, turnTarget);
						#endif
						L4D_CTerrorPlayer_OnVomitedUpon(turnTarget, client);
						isInBileState[turnTarget] = true;
						secondCheckFrame[turnTarget] = 0;
						bile_frame[client][1] = targetFrame;
					}
					else if (isInBileState[turnTarget])
					{
						#if DEBUG_ALL
							PrintToConsoleAll("[Ai-Boomer]：目标：%N 已在喷吐状态，切下一个", turnTarget);
						#endif
						bile_frame[client][1] = secondCheckFrame[turnTarget] = 0;
						bile_frame[client][0] += 1;
						return Plugin_Continue;
					}
				}
				bile_frame[client][1] += 1;
			}
			/* 喷完了，清理胖子目标集合 */
			else if (bile_frame[client][0] >= targetList[client].Length)
			{
				targetList[client].Clear();
				bile_frame[client][0] = bile_frame[client][1] = 0;
			}
			/* 没喷完，但是一个目标帧数满了，目标索引 + 1，继续喷下一个目标 */
			else
			{
				bile_frame[client][0] += 1;
				bile_frame[client][1] = 0;
			}
		}
	}

	// === 近距离主动喷吐（原逻辑保留） ============================================
	if ((flags & FL_ONGROUND) && IsValidSurvivor(target) && has_sight && targetDist <= RoundToNearest(0.8 * g_hVomitRange.FloatValue) && !in_bile_interval[client] && can_bile[client])
	{
		buttons |= IN_FORWARD;
		buttons |= IN_ATTACK;
		if (can_bile[client]) { CreateTimer(g_hVomitDuration.FloatValue, Timer_ResetBile, client); }
		can_bile[client] = false;
	}

	// === 倒地/被控近战：有条件触发；若本帧喷吐则清掉右键（修正 A） ================
	if (IsValidSurvivor(target) && (IsClientIncapped(target) || IsClientPinned(target)) && targetDist <= 80.0)
	{
		if (FloatAbs(self_pos[2] - targetPos[2]) <= PLAYER_HEIGHT)
		{
			float tgtEye[3];
			GetClientEyePosition(target, tgtEye);
			if (L4D2_IsVisibleToPlayer(client, TEAM_SURVIVOR, TEAM_INFECTED, 0, tgtEye))
			{
				// 只有喷吐不可用（在CD/被推）或当前没视线时，才允许右键
				if (!can_bile[client] || in_bile_interval[client] || !has_sight)
				{
					buttons |= IN_ATTACK2;
				}
			}
		}
	}

	// 若已决定喷吐，则强制取消右键，避免动画被抢（修正 A 兜底）
	if (buttons & IN_ATTACK)
	{
		buttons &= ~IN_ATTACK2;
	}

	// === 强行被喷（保持存在，但默认 Cvar=0 不会生效；你说“不要打开”） ============
	if (g_hForceBile.BoolValue && (buttons & IN_ATTACK) && !in_bile_interval[client] && IsValidSurvivor(target))
	{
		in_bile_interval[client] = true;
		for (i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || !IsPlayerAlive(i)) { continue; }
			float target_eye_pos2[3];
			GetClientEyePosition(i, target_eye_pos2);
			if (GetVectorDistance(self_eye_pos, target_eye_pos2) > g_hVomitRange.FloatValue) { continue; }
			Handle trace = TR_TraceRayFilterEx(self_eye_pos, target_eye_pos2, MASK_VISIBLE, RayType_EndPoint, TR_VomitClientFilter, client);
			if (!TR_DidHit(trace) || TR_GetEntityIndex(trace) == i)
			{
				#if DEBUG_ALL
					PrintToConsoleAll("[Ai-Boomer]：开启强制被喷：目标：%N，强制被喷", i);
				#endif
				delete trace;
				L4D_CTerrorPlayer_OnVomitedUpon(i, client);	
				isInBileState[target] = true;
			}
			delete trace;
		}
		CreateTimer(g_hVomitInterval.FloatValue, Timer_ResetAbility, client);
	}

	// 连跳
	if (g_hAllowBhop.BoolValue && has_sight && (flags & FL_ONGROUND) && ((0.5 * g_hVomitRange.FloatValue) < targetDist && targetDist < 1000.0) && cur_speed > 160.0 && IsValidSurvivor(target))
	{
		vel_buffer = CalculateVel(self_pos, targetPos, g_hBhopSpeed.FloatValue);
		buttons |= IN_JUMP;
		buttons |= IN_DUCK;
		if (Do_Bhop(client, buttons, vel_buffer)) { return Plugin_Changed; }
	}

	/* 爬梯子时，禁止连跳，蹲下与喷吐 */
	if (GetEntityMoveType(client) & MOVETYPE_LADDER)
	{
		buttons &= ~IN_ATTACK;
		buttons &= ~IN_ATTACK2;
		buttons &= ~IN_JUMP;
		buttons &= ~IN_DUCK;
	}
	return Plugin_Continue;
}

bool secondCheck(int client, int target)
{
	if (!IsBoomer(client) || !IsPlayerAlive(client) || !IsValidSurvivor(target) || !IsPlayerAlive(target)) { return false; }
	/* 目标有效，检测角度，可见性，距离 */
	float selfPos[3] = {0.0}, targetPos[3] = {0.0}, dist;
	GetClientEyePosition(client, selfPos);
	GetClientEyePosition(target, targetPos);
	dist = GetVectorDistance(selfPos, targetPos);
	if (dist > g_hVomitRange.FloatValue || !isInAimOffset(client, target, g_hAllowInDegreeForceBile.FloatValue) || isInBileState[target]) { return false; }
	Handle trace = TR_TraceRayFilterEx(selfPos, targetPos, MASK_VISIBLE, RayType_EndPoint, TR_VomitClientFilter, client);
	if (!TR_DidHit(trace) || TR_GetEntityIndex(trace) == target)
	{
		delete trace;
		return true;
	}
	delete trace;
	return false;
}

bool TR_VomitClientFilter(int entity, int contentsMask, int self)
{
	/* 被喷的玩家，射线可以通过 */
	if (entity > 0 && entity <= MaxClients && isInBileState[entity]) { return false; }
	return entity != self;
}

// 重置胖子能力使用限制
public Action Timer_ResetAbility(Handle timer, int client)
{
	if (IsBoomer(client) && IsPlayerAlive(client))
	{
		can_bile[client] = true;
		in_bile_interval[client] = false;
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public Action Timer_ResetBile(Handle timer, int client)
{
	if (IsBoomer(client) && IsPlayerAlive(client))
	{
		can_bile[client] = false;
		in_bile_interval[client] = true;
		// 喷吐时间过后，清除目标集合数据
		if (targetList[client] != null) targetList[client].Clear();
		bile_frame[client][0] = bile_frame[client][1] = 0;
		CreateTimer(g_hVomitInterval.FloatValue, Timer_ResetAbility, client);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

// 获取目标
public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{
	if (IsBoomer(specialInfected) && IsPlayerAlive(specialInfected))
	{
		float eyePos[3] = {0.0}, targetEyePos[3] = {0.0}, dist = 0.0;
		GetClientEyePosition(specialInfected, eyePos);
		// 寻找范围内符合要求的玩家，优先找被控或者倒地的
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) && (IsClientIncapped(i) || IsClientPinned(i)))
			{
				GetClientEyePosition(i, targetEyePos);
				eyePos[2] = targetEyePos[2] = 0.0;
				dist = GetVectorDistance(eyePos, targetEyePos);
				if (g_hBileFindRange.FloatValue > 0.0 && dist <= g_hBileFindRange.FloatValue)
				{
					Handle hTrace = TR_TraceRayFilterEx(eyePos, targetEyePos, MASK_VISIBLE, RayType_EndPoint, TR_VomitClientFilter, specialInfected);
					if (!TR_DidHit(hTrace) || TR_GetEntityIndex(hTrace) == i)
					{
						curTarget = i;
						return Plugin_Changed;
					}
					delete hTrace;
				}
			}
		}
	}
	return Plugin_Continue;
}

// 当生还被胖子喷中时，开始计算范围内的玩家
public Action L4D_OnVomitedUpon(int victim, int &attacker, bool &boomerExplosion)
{
	isInBileState[victim] = true;
	/* 每次喷吐排除当前被喷目标与已经被喷了的目标，选择最近目标继续喷吐 */
	if (targetList[attacker] == null) { targetList[attacker] = new ArrayList(2); }
	if (!IsBoomer(attacker) && targetList[attacker].Length > 1) { return Plugin_Continue; }

	// 当前 Boomer 目标集合中没有目标，开始获取目标
	int i;
	float eyePos[3] = {0.0}, targetEyePos[3] = {0.0}, dist, angle;
	GetClientEyePosition(attacker, eyePos);
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || !IsPlayerAlive(i) || isInBileState[i]) { continue; }
		GetClientEyePosition(i, targetEyePos);
		dist = GetVectorDistance(eyePos, targetEyePos);
		if (dist > g_hVomitRange.FloatValue) { continue; }
		Handle trace = TR_TraceRayFilterEx(eyePos, targetEyePos, MASK_VISIBLE, RayType_EndPoint, TR_VomitClientFilter, attacker);
		// 按照与当前胖子眼睛视线的角度大小来定位玩家
		if (!TR_DidHit(trace) || TR_GetEntityIndex(trace) == i)
		{
			angle = getSelfTargetAngle(attacker, i);
			targetList[attacker].Set(targetList[attacker].Push(angle), i, 1);
			#if DEBUG_ALL
				PrintToConsoleAll("[Ai-Boomer]：%N 的下一个目标是：%N", attacker, i);
			#endif
		}
		delete trace;
	}
	if (targetList[attacker].Length > 1) { targetList[attacker].Sort(Sort_Ascending, Sort_Float); }
	return Plugin_Continue;
}

// 方法，是否 AI 胖子
bool IsBoomer(int client)
{
	return view_as<bool>(GetInfectedClass(client) == view_as<int>(ZC_BOOMER) && IsFakeClient(client));
}

// 计算与目标之间的向量
float[] CalculateVel(float self_pos[3], float target_pos[3], float force)
{
	float vecbuffer[3] = {0.0};
	SubtractVectors(target_pos, self_pos, vecbuffer);
	NormalizeVector(vecbuffer, vecbuffer);
	ScaleVector(vecbuffer, force);
	return vecbuffer;
}

// 检测下一帧的位置是否会撞墙或向下受到伤害或会掉落
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

	// 由自身位置 +NAV_MESH_HEIGHT 高度 向前射出大小为 mins，maxs 的固体，检测前方 NAV_MESH_HEIGHT 距离是否能撞到，撞到则不允许连跳
	Handle hTrace = TR_TraceHullFilterEx(selfpos, resultpos, mins, maxs, MASK_NPCSOLID_BRUSHONLY, TR_EntityFilter);
	if (TR_DidHit(hTrace))
	{
		hullrayhit = true;
		TR_GetEndPosition(hullray_endpos, hTrace);
		if (GetVectorDistance(selfpos, hullray_endpos) <= NAV_MESH_HEIGHT)
		{
			delete hTrace;
			return false;
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
		// 如果向下的射线撞到的位置减去起始位置的高度大于 FALL_DETECT_HEIGHT 则说明会掉下去，返回 false
		if (FloatAbs(down_hullray_startpos[2] - down_hullray_hitpos[2]) > FALL_DETECT_HEIGHT)
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
	if (entity > 0 && entity <= MaxClients) { return false; }
	else
	{
		char classname[32] = {'\0'};
		GetEdictClassname(entity, classname, sizeof(classname));
		if (strcmp(classname, "infected") == 0 || strcmp(classname, "witch") == 0 || strcmp(classname, "prop_physics") == 0 || strcmp(classname, "tank_rock") == 0) { return false; }
	}
	return true;
}

// 胖子连跳
bool Do_Bhop(int client, int &buttons, float vec[3])
{
	if (buttons & IN_FORWARD || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT) { if (ClientPush(client, vec)) { return true; } }
	return false;
}

bool ClientPush(int client, float vec[3])
{
	float curvel[3] = {0.0};
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", curvel);
	AddVectors(curvel, vec, curvel);
	if (Dont_HitWall_Or_Fall(client, curvel))
	{
		if (GetVectorLength(curvel) <= 250.0)
		{
			NormalizeVector(curvel, curvel);
			ScaleVector(curvel, 251.0);
		}
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, curvel);
		return true;
	}
	return false;
}

void ComputeAimAngles(int client, int target, float angles[3], AimType type = AimEye)
{
	float selfpos[3], targetpos[3], lookat[3];
	GetClientEyePosition(client, selfpos);
	switch (type)
	{
		case AimEye:  { GetClientEyePosition(target, targetpos); }
		case AimBody: { GetClientAbsOrigin(target, targetpos); }
		case AimChest:
		{
			GetClientAbsOrigin(target, targetpos);
			targetpos[2] += 45.0;
		}
	}
	MakeVectorFromPoints(selfpos, targetpos, lookat);
	GetVectorAngles(lookat, angles);
}

static bool isInAimOffset(int attacker, int target, float offset)
{
	if (!IsBoomer(attacker) || !IsPlayerAlive(attacker) || !IsValidSurvivor(target) || !IsPlayerAlive(target)) { return false; }
	static float angle;
	angle = getSelfTargetAngle(attacker, target);
	return angle != -1.0 && angle <= offset;
}

static float getSelfTargetAngle(int attacker, int target)
{
	if (!IsBoomer(attacker) || !IsPlayerAlive(attacker) || !IsValidSurvivor(target) || !IsPlayerAlive(target)) { return -1.0; }
	static float selfEyePos[3], targetEyePos[3], resultPos[3], selfEyeVector[3];
	// 和目标的方向向量，要在 NormalizeVector 前将向量 xz 方向设置为 0
	GetClientEyePosition(attacker, selfEyePos);
	GetClientEyePosition(target, targetEyePos);
	selfEyePos[2] = targetEyePos[2] = 0.0;
	MakeVectorFromPoints(selfEyePos, targetEyePos, resultPos);
	NormalizeVector(resultPos, resultPos);
	// 自己眼睛看的方向向量
	GetClientEyeAngles(attacker, selfEyePos);
	selfEyePos[0] = selfEyePos[2] = 0.0;
	GetAngleVectors(selfEyePos, selfEyeVector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(selfEyeVector, selfEyeVector);
	return RadToDeg(ArcCosine(GetVectorDotProduct(selfEyeVector, resultPos)));
}
