#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <treeutil>

#define CVAR_FLAG FCVAR_NOTIFY
#define NAV_MESH_HEIGHT 20.0
#define FALL_DETECT_HEIGHT 120.0

public Plugin myinfo = 
{
	name 			= "Ai Charger 增强 2.0 版本",
	author 			= "夜羽真白",
	description 	= "Ai Charger 2.0",
	version 		= "2.0.0.0 / 2022/7/14",
	url 			= "https://steamcommunity.com/id/saku_ra/"
}

// ConVars
ConVar g_hAllowBhop, g_hBhopSpeed, g_hChargeDist, g_hExtraTargetDist, g_hAimOffset, g_hChargerTarget, g_hAllowMeleeAvoid, g_hChargerMeleeDamage, g_hChargeInterval, g_hChargeHeightDiff;
// Float
float
	charge_interval[MAXPLAYERS + 1] = {0.0},
	min_dist,
	max_dist;
// Bools
bool can_attack_pinned[MAXPLAYERS + 1] = {false}, is_charging[MAXPLAYERS + 1] = {false};
// Ints
int survivor_num = 0, ranged_client[MAXPLAYERS + 1][MAXPLAYERS + 1], ranged_index[MAXPLAYERS + 1] = {0};

public void OnPluginStart()
{
	// CreateConVars
	g_hAllowBhop = CreateConVar("ai_ChargerBhop", "1", "是否开启 Charger 连跳", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hBhopSpeed = CreateConVar("ai_ChagrerBhopSpeed", "90.0", "Charger 连跳速度", CVAR_FLAG, true, 0.0);
	g_hChargeDist = CreateConVar("ai_ChargerChargeDistance", "250.0", "Charger 只能在与目标小于这一距离时冲锋", CVAR_FLAG, true, 0.0);
	g_hExtraTargetDist = CreateConVar("ai_ChargerExtraTargetDistance", "0,350", "Charger 会在这一范围内寻找其他有效的目标（中间用逗号隔开，不要有空格）", CVAR_FLAG);
	g_hAimOffset = CreateConVar("ai_ChargerAimOffset", "30.0", "目标的瞄准水平与 Charger 处在这一范围内，Charger 不会冲锋", CVAR_FLAG, true, 0.0);
	g_hAllowMeleeAvoid = CreateConVar("ai_ChargerMeleeAvoid", "1", "是否开启 Charger 近战回避", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hChargerMeleeDamage = CreateConVar("ai_ChargerMeleeDamage", "350", "Charger 血量小于这个值，将不会直接冲锋拿着近战的生还者", CVAR_FLAG, true, 0.0);
	g_hChargerTarget = CreateConVar("ai_ChargerTarget", "1", "Charger目标选择：1=自然目标选择，2=优先取最近目标，3=优先撞人多处", CVAR_FLAG, true, 1.0, true, 2.0);
	g_hChargeHeightDiff = CreateConVar("ai_ChargerChargeHeightDiff", "80.0", "允许直接冲锋时目标高出自身的最大高度差（小于等于 0 关闭检测）", CVAR_FLAG);
	g_hChargeInterval = FindConVar("z_charge_interval");
	g_hExtraTargetDist.AddChangeHook(extraTargetDistChangeHandler);
	// HookEvents
	HookEvent("player_spawn", evt_PlayerSpawn);
	// GetOtherTarget
	getOtherRangedTarget();
}

void extraTargetDistChangeHandler(ConVar convar, const char[] oldValue, const char[] newValue)
{
	getOtherRangedTarget();
}

// 事件
public void evt_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsCharger(client))
	{
		// 牛生成时，将冲锋时间戳记为 0.0 - 冲锋 CD 的时间，否则由于刚开始小于冲锋 CD 会导致无法对没看着自身的目标挥拳而是直接冲锋
		charge_interval[client] = 0.0 - g_hChargeInterval.FloatValue;
		is_charging[client] = false;
	}
}
// 主要
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsCharger(client) && IsPlayerAlive(client))
	{
		if(GetEntPropEnt(client, Prop_Send, "m_pummelVictim") > 0 || GetEntPropEnt(client, Prop_Send, "m_carryVictim") > 0)
			return Plugin_Continue;
		if (L4D_IsPlayerStaggering(client))
			return Plugin_Continue;
		bool has_sight = view_as<bool>(GetEntProp(client, Prop_Send, "m_hasVisibleThreats"));
		int target = GetClientAimTarget(client, true), closet_survivor_distance = GetClosetSurvivorDistance(client), ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
		float self_pos[3] = {0.0}, target_pos[3] = {0.0}, vec_speed[3] = {0.0}, vel_buffer[3] = {0.0}, cur_speed = 0.0;
		GetClientAbsOrigin(client, self_pos);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec_speed);
		cur_speed = SquareRoot(Pow(vec_speed[0], 2.0) + Pow(vec_speed[1], 2.0));
		survivor_num = GetSurvivorCount(true, false);
		// charge_interval 记录每次冲锋结束的时间戳
		if (IsValidEntity(ability) && !is_charging[client] && GetEntProp(ability, Prop_Send, "m_isCharging") == 1)
		{
			is_charging[client] = true;
		}
		else if (IsValidEntity(ability) && is_charging[client] && GetEntProp(ability, Prop_Send, "m_isCharging") != 1)
		{
			charge_interval[client] = GetGameTime();
			is_charging[client] = false;
		}
		// 冲锋时，将 vel 三方向置 0.0
		if (buttons & IN_ATTACK)
		{
			vel[0] = vel[1] = vel[2] = 0.0;
		}
		// 建立在距离小于冲锋限制距离，有视野且生还者有效的情况下
		if (closet_survivor_distance < g_hChargeDist.IntValue)
		{
			if (has_sight && IsValidSurvivor(target) && !IsClientIncapped(target) && !IsClientPinned(target) && !IsInChargeDuration(client))
			{
				// 目标没有正在看着自身（被控不算看着自身），自身可以冲锋且血量大于限制血量，阻止冲锋，对目标挥拳
				if (GetClientHealth(client) >= g_hChargerMeleeDamage.IntValue && !Is_Target_Watching_Attacker(client, target, g_hAimOffset.IntValue))
				{
					buttons &= ~IN_ATTACK;
					BlockCharge(client);
					// 查找冲锋范围内是否有其他正在看着自身的玩家
					for (int i = 0; i < ranged_index[client]; i++)
					{
						if (ranged_client[client][i] != target && !IsClientPinned(ranged_client[client][i]) && Is_Target_Watching_Attacker(client, ranged_client[client][i], g_hAimOffset.IntValue) && !Is_InGetUp_Or_Incapped(ranged_client[client][i]) && GetEntProp(ability, Prop_Send, "m_isCharging") != 1 && IsGrounded(client))
						{
							SetCharge(client);
							float new_target_pos[3] = {0.0};
							GetClientAbsOrigin(ranged_client[client][i], new_target_pos);
							MakeVectorFromPoints(self_pos, new_target_pos, new_target_pos);
							GetVectorAngles(new_target_pos, new_target_pos);
							TeleportEntity(client, NULL_VECTOR, new_target_pos, NULL_VECTOR);
							buttons |= IN_ATTACK2;
							buttons |= IN_ATTACK;
							return Plugin_Changed;
						}
					}
				}
				// 目标正在看着自身，自身可以冲锋且目标未处于倒地/起身状态
				else if (Is_Target_Watching_Attacker(client, target, g_hAimOffset.IntValue) && !Is_InGetUp_Or_Incapped(target) && GetEntProp(ability, Prop_Send, "m_isCharging") != 1 && IsGrounded(client))
				{
					bool targetHasMelee = g_hAllowMeleeAvoid.BoolValue && Client_MeleeCheck(target);
					bool allowHeightCharge = true;
					float heightLimit = g_hChargeHeightDiff != null ? g_hChargeHeightDiff.FloatValue : 0.0;
					if (heightLimit > 0.0)
					{
						GetClientAbsOrigin(target, target_pos);
						if ((target_pos[2] - self_pos[2]) > heightLimit)
						{
							allowHeightCharge = false;
						}
					}
					if (allowHeightCharge && (!targetHasMelee || GetClientHealth(client) >= g_hChargerMeleeDamage.IntValue))
					{
						SetCharge(client);
						buttons |= IN_ATTACK2;
						buttons |= IN_ATTACK;
						return Plugin_Changed;
					}
				}
				else if (Is_InGetUp_Or_Incapped(target))
				{
					buttons &= ~IN_ATTACK;
					BlockCharge(client);
					buttons |= IN_ATTACK2;
				}
			}
			// 自身血量大于冲锋限制血量，且目标是被控的人时，检测冲锋范围内是否有其他人（可能拿着近战），有则对其冲锋，自身血量小于冲锋限制血量，对着被控的人冲锋
			else if (has_sight && IsValidSurvivor(target) && IsClientPinned(target) && !IsInChargeDuration(client))
			{
				if (GetClientHealth(client) >= g_hChargerMeleeDamage.IntValue)
				{
					can_attack_pinned[client] = true;
					buttons &= ~IN_ATTACK;
					BlockCharge(client);
					buttons |= IN_ATTACK2;
					return Plugin_Changed;
				}
				else if (Is_InGetUp_Or_Incapped(target))
				{
					buttons &= ~IN_ATTACK;
					BlockCharge(client);
					buttons |= IN_ATTACK2;
				}
				else
				{
					can_attack_pinned[client] = false;
				}
			}
		}
		else if (!IsInChargeDuration(client) && GetEntProp(ability, Prop_Send, "m_isCharging") != 1)
		{
			buttons &= ~IN_ATTACK;
			BlockCharge(client);
			buttons |= IN_ATTACK2;
		}
		// 连跳，并阻止冲锋，可以攻击被控的人的时，将最小距离置 0，连跳追上被控的人
		int bhopMinDist = can_attack_pinned[client] ? 60 : g_hChargeDist.IntValue;
		if (has_sight && g_hAllowBhop.BoolValue && bhopMinDist < closet_survivor_distance < 10000 && cur_speed > 175.0 && IsValidSurvivor(target))
		{
			if (IsGrounded(client))
			{
				GetClientAbsOrigin(target, target_pos);
				vel_buffer = CalculateVel(self_pos, target_pos, g_hBhopSpeed.FloatValue);
				buttons |= IN_JUMP;
				buttons |= IN_DUCK;
				if (Do_Bhop(client, buttons, vel_buffer))
				{
					return Plugin_Changed;
				}
			}
		}
		// 梯子上，阻止连跳
		if (GetEntityMoveType(client) & MOVETYPE_LADDER)
		{
			buttons &= ~IN_JUMP;
			buttons &= ~IN_DUCK;
		}
	}
	return Plugin_Continue;
}
// 目标选择
public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{
	int new_target = 0;
	if (IsCharger(specialInfected))
	{
		if(GetEntPropEnt(specialInfected, Prop_Send, "m_pummelVictim") > 0 || GetEntPropEnt(specialInfected, Prop_Send, "m_carryVictim") > 0)
			return Plugin_Continue;
		float self_pos[3] = {0.0};
		GetClientEyePosition(specialInfected, self_pos);
		FindRangedClients(specialInfected, min_dist, max_dist);
		if (IsValidSurvivor(curTarget) && IsPlayerAlive(curTarget))
		{
			// curTarget 先验为有效目标，获取自身体位后进行可见性与目标转换判断
			for (int i = 0; i < ranged_index[specialInfected]; i++)
			{
				// 1. 范围内有人被控且自身血量大于限制血量，则先去对被控的人挥拳
				if (GetClientHealth(specialInfected) > g_hChargerMeleeDamage.IntValue && !IsInChargeDuration(specialInfected) && (GetEntPropEnt(ranged_client[specialInfected][i], Prop_Send, "m_pounceAttacker") > 0 || GetEntPropEnt(ranged_client[specialInfected][i], Prop_Send, "m_tongueOwner") > 0 || GetEntPropEnt(ranged_client[specialInfected][i], Prop_Send, "m_jockeyAttacker") > 0))
				{
					can_attack_pinned[specialInfected] = true;
					curTarget = ranged_client[specialInfected][i];
					BlockCharge(specialInfected);
					return Plugin_Changed;
				}
				can_attack_pinned[specialInfected] = false;
			}
			if (!IsClientIncapped(curTarget) && !IsClientPinned(curTarget))
			{
				bool target_has_melee = g_hAllowMeleeAvoid.BoolValue && Client_MeleeCheck(curTarget);
				bool is_low_health = (GetClientHealth(specialInfected) < g_hChargerMeleeDamage.IntValue);
				// 仅在自身血量较低且对方拿着近战时才尝试换目标或停止冲锋
				if (target_has_melee && is_low_health)
				{
					int melee_num = 0;
					Get_MeleeNum(melee_num, new_target);
					// 1. 优先尝试换到没有近战的可视目标
					if (melee_num < survivor_num && IsValidSurvivor(new_target) && Player_IsVisible_To(specialInfected, new_target))
					{
						curTarget = new_target;
						return Plugin_Changed;
					}
					// 2. 找一个没有正面盯着自己的目标（无论武器）
					for (int i = 0; i < ranged_index[specialInfected]; i++)
					{
						int altTarget = ranged_client[specialInfected][i];
						if (IsValidSurvivor(altTarget) && IsPlayerAlive(altTarget) && !IsClientIncapped(altTarget) && !IsClientPinned(altTarget)
							&& !Is_Target_Watching_Attacker(specialInfected, altTarget, g_hAimOffset.IntValue))
						{
							curTarget = altTarget;
							return Plugin_Changed;
						}
					}
					// 3. 实在没人可换，直接撞最近的活动生还者
					int fallbackTarget = GetClosetMobileSurvivor(specialInfected);
					if (IsValidSurvivor(fallbackTarget))
					{
						curTarget = fallbackTarget;
						return Plugin_Changed;
					}
				}

				// 目标选择
				switch (g_hChargerTarget.IntValue)
				{
					case 2:
					{
						new_target = GetClosetMobileSurvivor(specialInfected);
						if (IsValidSurvivor(new_target))
						{
							curTarget = new_target;
							return Plugin_Changed;
						}
					}
					case 3:
					{
						new_target = GetCrowdPlace(survivor_num);
						if (IsValidSurvivor(new_target))
						{
							curTarget = new_target;
							return Plugin_Changed;
						}
					}
				}
			}
		}
		else if (!IsValidSurvivor(curTarget))
		{
			new_target = GetClosetMobileSurvivor(specialInfected);
			if (IsValidSurvivor(new_target))
			{
				curTarget = new_target;
				return Plugin_Changed;
			}
		}
	}
	if (!can_attack_pinned[specialInfected] && IsCharger(specialInfected) && IsValidSurvivor(curTarget) && (IsClientIncapped(curTarget) || IsClientPinned(curTarget)))
	{
		new_target = GetClosetMobileSurvivor(specialInfected);
		if (IsValidSurvivor(new_target))
		{
			curTarget = new_target;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
void Get_MeleeNum(int &melee_num, int &new_target)
{
	int active_weapon = -1;
	char weapon_name[48] = {'\0'};
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == view_as<int>(TEAM_SURVIVOR) && IsPlayerAlive(client) && !IsClientIncapped(client) && !IsClientPinned(client))
		{
			active_weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (IsValidEntity(active_weapon) && IsValidEdict(active_weapon))
			{
				GetEdictClassname(active_weapon, weapon_name, sizeof(weapon_name));
				if (strcmp(weapon_name[7], "melee") == 0 || strcmp(weapon_name, "weapon_chainsaw") == 0)
				{
					melee_num += 1;
				}
				else
				{
					new_target = client;
				}
			}
		}
	}
}
bool Client_MeleeCheck(int client)
{
	int active_weapon = -1;
	char weapon_name[48] = {'\0'};
	if (IsValidSurvivor(client) && IsPlayerAlive(client) && !IsClientIncapped(client) && !IsClientPinned(client))
	{
		active_weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(active_weapon) && IsValidEdict(active_weapon))
		{
			GetEdictClassname(active_weapon, weapon_name, sizeof(weapon_name));
			if (strcmp(weapon_name[7], "melee") == 0 || strcmp(weapon_name, "weapon_chainsaw") == 0)
			{
				return true;
			}
		}
	}
	return false;
}
// From：http://github.com/PaimonQwQ/L4D2-Plugins/smartspitter.sp
int GetCrowdPlace(int num_survivors)
{
	if (num_survivors > 0)
	{
		int index = 0, iTarget = 0;
		int[] iSurvivors = new int[num_survivors];
		float fDistance[MAXPLAYERS + 1] = {-1.0};
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client) && GetClientTeam(client) == view_as<int>(TEAM_SURVIVOR))
			{
				iSurvivors[index++] = client;
			}
		}
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == view_as<int>(TEAM_SURVIVOR))
			{
				fDistance[client] = 0.0;
				float fClientPos[3] = {0.0};
				GetClientAbsOrigin(client, fClientPos);
				for (int i = 0; i < num_survivors; i++)
				{
					float fPos[3] = {0.0};
					GetClientAbsOrigin(iSurvivors[i], fPos);
					fDistance[client] += GetVectorDistance(fClientPos, fPos, true);
				}
			}
		}
		for (int i = 0; i < num_survivors; i++)
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

// 方法，是否是 AI 牛
bool IsCharger(int client)
{
	return view_as<bool>(GetInfectedClass(client) == view_as<int>(ZC_CHARGER) && IsFakeClient(client));
}
// 判断目标是否处于正在起身或正在倒地状态
bool Is_InGetUp_Or_Incapped(int client)
{
	int character_index = IdentifySurvivor(client);
	if (character_index != view_as<int>(SC_INVALID))
	{
		int sequence = GetEntProp(client, Prop_Send, "m_nSequence");
		if (sequence == GetUpAnimations[character_index][ID_HUNTER] || sequence == GetUpAnimations[character_index][ID_CHARGER] || sequence == GetUpAnimations[character_index][ID_CHARGER_WALL] || sequence == GetUpAnimations[character_index][ID_CHARGER_GROUND])
		{
			return true;
		}
		else if (sequence == IncappAnimations[character_index][ID_SINGLE_PISTOL] || sequence == IncappAnimations[character_index][ID_DUAL_PISTOLS])
		{
			return true;
		}
		return false;
	}
	return false;
}
// 阻止牛冲锋
void BlockCharge(int client)
{
	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (IsValidEntity(ability) && GetEntProp(ability, Prop_Send, "m_isCharging") != 1)
	{
		SetEntPropFloat(ability, Prop_Send, "m_timestamp", GetGameTime() + g_hChargeInterval.FloatValue);
	}
}
// 让牛冲锋
void SetCharge(int client)
{
	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (IsValidEntity(ability) && GetEntProp(ability, Prop_Send, "m_isCharging") != 1)
	{
		SetEntPropFloat(ability, Prop_Send, "m_timestamp", GetGameTime() - 0.5);
	}
}
// 是否在冲锋间隔
bool IsInChargeDuration(int client)
{
	return view_as<bool>((GetGameTime() - (g_hChargeInterval.FloatValue + charge_interval[client])) < 0.0);
}
// 查找范围内可视的有效的（未倒地，未死亡，未被控）的玩家
int FindRangedClients(int client, float min_range, float max_range)
{
	int index = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == view_as<int>(TEAM_SURVIVOR) && IsPlayerAlive(i) && !IsClientIncapped(i))
		{
			float self_eye_pos[3] = {0.0}, target_eye_pos[3] = {0.0}, dist = 0.0;
			GetClientEyePosition(client, self_eye_pos);
			GetClientEyePosition(i, target_eye_pos);
			dist = GetVectorDistance(self_eye_pos, target_eye_pos);
			if (dist >= min_range && dist <= max_range)
			{
				Handle hTrace = TR_TraceRayFilterEx(self_eye_pos, target_eye_pos, MASK_VISIBLE, RayType_EndPoint, TR_RayFilter, client);
				if (!TR_DidHit(hTrace) || TR_GetEntityIndex(hTrace) == i)
				{
					ranged_client[client][index] = i;
					index += 1;
				}
				delete hTrace;
				hTrace = INVALID_HANDLE;
			}
		}
	}
	ranged_index[client] = index;
	return index;
}
// 牛连跳
bool Do_Bhop(int client, int &buttons, float vec[3])
{
	if (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT)
	{
		if (ClientPush(client, vec))
		{
			return true;
		}
	}
	return false;
}
bool ClientPush(int client, float vec[3])
{
	float curvel[3] = {0.0};
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", curvel);
	AddVectors(curvel, vec, curvel);
	if (GetVectorLength(curvel) <= 250.0)
	{
		NormalizeVector(curvel, curvel);
		ScaleVector(curvel, 251.0);
	}
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, curvel);
	return true;
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
stock bool Dont_HitWall_Or_Fall(int client, float vel[3])
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
// 目标与牛的 x 距离是否在限制内
bool Is_Target_Watching_Attacker(int client, int target, int offset)
{
	if (IsValidInfected(client) && IsValidSurvivor(target) && IsPlayerAlive(client) && IsPlayerAlive(target) && !IsClientIncapped(target) && !IsClientPinned(target) && !Is_InGetUp_Or_Incapped(target))
	{
		int aim_offset = RoundToNearest(Get_Player_Aim_Offset(target, client));
		if (aim_offset <= offset)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	return false;
}
float Get_Player_Aim_Offset(int client, int target)
{
	if (IsValidClient(client) && IsValidClient(target) && IsPlayerAlive(client) && IsPlayerAlive(target))
	{
		float self_pos[3] = {0.0}, target_pos[3] = {0.0}, aim_vector[3] = {0.0}, dir_vector[3] = {0.0}, result_angle = 0.0;
		GetClientEyeAngles(client, aim_vector);
		aim_vector[0] = aim_vector[2] = 0.0;
		GetAngleVectors(aim_vector, aim_vector, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(aim_vector, aim_vector);
		GetClientAbsOrigin(target, target_pos);
		GetClientAbsOrigin(client, self_pos);
		self_pos[2] = target_pos[2] = 0.0;
		MakeVectorFromPoints(self_pos, target_pos, dir_vector);
		NormalizeVector(dir_vector, dir_vector);
		result_angle = RadToDeg(ArcCosine(GetVectorDotProduct(aim_vector, dir_vector)));
		return result_angle;
	}
	return -1.0;
}

void getOtherRangedTarget()
{
	// 获取在冲锋范围内的目标，从 Cvar 中获取最下与最大范围
	static char cvar_dist[16], result_dist[2][16];
	g_hExtraTargetDist.GetString(cvar_dist, sizeof(cvar_dist));
	if (!IsNullString(cvar_dist))
	{
		ExplodeString(cvar_dist, ",", result_dist, 2, sizeof(result_dist[]));
		min_dist = StringToFloat(result_dist[0]);
		max_dist = StringToFloat(result_dist[1]);
	}
	else
	{
		max_dist = 350.0;
	}
}
