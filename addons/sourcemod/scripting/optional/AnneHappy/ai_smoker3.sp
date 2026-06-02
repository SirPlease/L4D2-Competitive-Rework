#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>
#include <treeutil>
#include <logger2>
#include <actions>

#define CVAR_FLAGS FCVAR_NOTIFY
// 将插件日志前缀改成自己插件的日志前缀
#define PLUGIN_PREFIX "Ai-Smoker3"

#define GAMEDATA "l4d2_ai_smoker3"
#define SIG_SMOKER_MOVE_2_ATTACK_POSITION			"SmokerMoveToAttackPosition::SmokerMoveToAttackPosition"
#define SIG_GET_RUN_TOP_SPEED						"CTerrorPlayer::GetRunTopSpeed"
#define SIG_SMOKER_MOVE_2_ATTACK_POSITION_UPDATE	"SmokerMoveToAttackPosition::Update"
#define SIG_SMOKER_TONGUE_VICTIM					"SmokerTongueVictim::SmokerTongueVictim"

#define ACT_NAME_MOVE_TO_ATTACK_POSITION			"SmokerMoveToAttackPosition"
#define ACT_NAME_TONGUE_VICTIM						"SmokerTongueVictim"
#define ACT_NAME_RETREAT							"SmokerRetreatToCover"
#define ACT_NAME_MOVETO								"BehaviorMoveTo"

#define ACT_SIZE_TONGUE_VICTIM						72	// 0x48u

#define DEFAULT_TONGUE_RANGE						750.0

ConVar
	g_cvPluginName,
	g_cvEnableBhop,
	g_cvBhopImpulse,
	g_cvBhopNoVision,
	g_cvBhopMinSpeed,
	g_cvBhopMaxSpeed,
	g_cvBhopMinDist,
	g_cvBhopMaxDist,
	g_cvBhopSideMinAng,
	g_cvBhopSideMaxAng,
	g_cvAirVecModifyDegree,
	g_cvBhopNoVisionMaxAng,
	g_cvAirVecModifyMaxDegree,
	g_cvAirVecModifyInterval,
	g_cvImmPull,
	g_cvPullBackVision,
	g_cvAntiRetreat,
	g_cvMove2NewTarInterval,
	g_cvStopSmokerWarnSnd,
	g_cvLogLevel;

ConVar
	cvTongueRange;

float
	g_fTongueRange;

bool
	g_bLateLoad;

Logger log;

ActionConstructor
	g_hSmokerMove2AtkPosConstructor;

Handle
	g_hSdkGetRunTopSpeed,
	g_hSdkSmokerTongueVictim;

enum struct AiSmoker {
	int		m_iTarget;					// 当前目标的 userId
	bool	m_bIsMove2ChangeTar;		// 是否是无技能追击时转换目标 (BehaviroMoveTo -> ChangeNewTarget)
	float	m_vecMoveToPos[3];			// 当前无技能追击的目标位置
	float	m_flLastMoveToTime;			// 上次移动到目标位置的时间, 用于更新追击位置
	float	m_flLastAirModifyTime;		// 上次防止连跳过头空中速度修正时间
	bool	m_bIsVisible2Target;		// 当前目标是否可见
	bool 	m_bToggleSide;				// 连跳时方向是否向左偏移, 若向左偏移, 则下次连跳向右偏移
	float	m_flLastAtkBtnPressTime;	// 上次按下攻击键的时间, 用于判断是否可以进行攻击

	void initData() {
		this.m_iTarget = -1;
		this.m_bIsMove2ChangeTar = false;
		this.m_vecMoveToPos = NULL_VECTOR;
		this.m_flLastMoveToTime = 0.0;
		this.m_flLastAirModifyTime = 0.0;
		this.m_bIsVisible2Target = false;
		this.m_bToggleSide = false;
		this.m_flLastAtkBtnPressTime = 0.0;
	}
}
AiSmoker g_AiSmokers[MAXPLAYERS + 1];

#include "./stocks.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	EngineVersion test = GetEngineVersion();
    //API
	if (test != Engine_Left4Dead && test != Engine_Left4Dead2) {
		strcopy(error, err_max, "Plugin Supports L4D(2) Only!");
		return APLRes_SilentFailure;
	}
	g_bLateLoad = late;
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name 			= "Ai-Smoker 3.0",
	author 			= "夜羽真白",
	description 	= "Ai-Smoker 增强 3.0 版本",
	version 		= "1.0.0.0",
	url 			= "https://steamcommunity.com/id/saku_ra/"
}

public void OnPluginStart() {

	// bhop enable?
	g_cvEnableBhop = CreateConVar("ai_smoker3_bhop", "1", "是否允许Smoker进行连跳操作", CVAR_FLAGS, true, 0.0, true, 1.0);
	// Smoker can continue to bhop when he has no target survivor's sight
	g_cvBhopNoVision = CreateConVar("ai_smoker3_bhop_no_vision", "1", "是否允许无目标视野情况下进行连跳操作", CVAR_FLAGS, true, 0.0, true, 1.0);
	// used to control the speed acceleration during Smoker each jump from the ground
	g_cvBhopImpulse = CreateConVar("ai_SmokerBhopSpeed", "120", "连跳加速度", CVAR_FLAGS, true, 0.0);
	// when Smoker's speed is higher than 'ai_smoker3_bhop_min_speed', he is allowed to bhop, and his max bhop speed will not above 'ai_smoker3_bhop_max_speed'
	g_cvBhopMinSpeed = CreateConVar("ai_smoker3_bhop_min_speed", "200", "允许连跳的最小速度", CVAR_FLAGS, true, 0.0);
	g_cvBhopMaxSpeed = CreateConVar("ai_smoker3_bhop_max_speed", "1000", "连跳时的最大速度", CVAR_FLAGS, true, 0.0);
	// Smoker can bhop when he and his target are within the distance (ai_smoker3_bhop_min_dist, ai_smoker3_bhop_max_dist) 
	g_cvBhopMinDist = CreateConVar("ai_smoker3_bhop_min_dist", "75", "允许连跳的最小距离, 与目标距离小于这个值不允许连跳", CVAR_FLAGS, true, 0.0);
	g_cvBhopMaxDist = CreateConVar("ai_smoker3_bhop_max_dist", "9999", "允许连跳的最大距离, 与目标距离大于这个值时不允许连跳", CVAR_FLAGS, true, 0.0);
	// when Smoker bhop towards his target, the direction of velocity vector will deviate horizontally by [ai_smoker3_bhop_side_minang, ai_smoker3_bhop_side_maxang]
	g_cvBhopSideMinAng = CreateConVar("ai_smoker3_bhop_side_minang", "15.0", "连跳时连跳方向最小左右侧偏角度", CVAR_FLAGS, true, 0.0, true, 180.0);
	g_cvBhopSideMaxAng = CreateConVar("ai_smoker3_bhop_side_maxang", "30.0", "连跳时连跳方向最大左右侧偏角度", CVAR_FLAGS, true, 0.0, true, 180.0);
	// when Smoker has no sight of any survivors, he is allowed to bhop when his speed vector and eye angle forward vector within this degree
	g_cvBhopNoVisionMaxAng = CreateConVar("_ai_smoker3_bhop_nvis_maxang", "75.0", "无生还者视野时速度向量与视角前向向量在这个角度范围内, 允许连跳", CVAR_FLAGS, true, 0.0);
	// when the angle that Smoker's speed vector and his direction vector towards the target is within (ai_smoker3_airvec_modify_degree, ai_smoker3_airvec_modify_degree_max), when Smoker is in air, Smoker will modify the speed vector at interval: ai_smoker3_airvec_modify_interval (this will push Smoker to his target direction)
	g_cvAirVecModifyDegree = CreateConVar("ai_smoker3_airvec_modify_degree", "50.0", "在空中速度方向与自身到目标方向角度超过这个值进行速度修正", CVAR_FLAGS, true, 0.0);
	g_cvAirVecModifyMaxDegree = CreateConVar("ai_smoker3_airvec_modify_degree_max", "105.0", "在空中速度方向与自身到目标方向角度超过这个值不进行速度修正", CVAR_FLAGS, true, 0.0);
	g_cvAirVecModifyInterval = CreateConVar("ai_smoker3_airvec_modify_interval", "0.3", "空中速度修正间隔", CVAR_FLAGS, true, 0.1);
	// allowed for Smoker to fire his tongue immediately once the target distance is less than tongue_range
	g_cvImmPull = CreateConVar("ai_smoker3_imm_pull", "1", "是否允许Smoker与目标距离一旦满足TongueRange立刻拉人", CVAR_FLAGS, true, 0.0, true, 1.0);
	// allow Smoker to turn it's vision to behind when he is pulling survivor
	g_cvPullBackVision = CreateConVar("ai_smoker3_pull_back_vision", "0", "是否允许Smoker拉人时视角转向背后", CVAR_FLAGS, true, 0.0, true, 1.0);

	// prevent smoker from retreating to cover when he has no ability?
	g_cvAntiRetreat = CreateConVar("ai_smoker3_anti_retreat", "0", "是否防止Smoker无技能时逃跑 (将无技能逃跑改为追击)", CVAR_FLAGS, true, 0.0, true, 1.0);
	// when move to target and has no ability, the time interval for detecting the nearest survivor and changing targets (it is recommended not to be less than 0.5, otherwise it will cause Smoker movement lagging)
	g_cvMove2NewTarInterval = CreateConVar("ai_smoker3_move2_newtar_interval", "1.0", "无技能追击时, 检测距离最近的生还者并更换目标的时间间隔 (建议不要小于 0.5 否则会导致Smoker移动卡顿)", CVAR_FLAGS, true, 0.0);

	// stop the warning sound effect when Smoker is about to fire his tongue?
	g_cvStopSmokerWarnSnd = CreateConVar("ai_smoker3_stop_warn_snd", "0", "是否停止Smoker准备吐舌时发出的警告音效", CVAR_FLAGS, true, 0.0, true, 1.0);

	// 将插件名称改成自己插件名称
	g_cvPluginName = CreateConVar("ai_smoker3_plugin_name", "ai_smoker3");

	char cvName[64];
	g_cvPluginName.GetString(cvName, sizeof(cvName));
	FormatEx(cvName, sizeof(cvName), "%s_log_level", cvName);
	g_cvLogLevel = CreateConVar(cvName, "32", "日志记录级别, 1=关闭, 2=控制台输出, 4=log文件输出, 8=聊天框输出, 16=服务器控制台输出, 32=error文件输出, 数字相加", CVAR_FLAGS);

	HookEvent("player_spawn", evtPlayerSpawn);

	log = new Logger(PLUGIN_PREFIX, g_cvLogLevel.IntValue);

	// 添加声音 Hook
	AddNormalSoundHook(sndHookSmokerWarn);

	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (!isAiSmoker(i))
				continue;
			g_AiSmokers[i].initData();
		}
	}

}

public void OnAllPluginsLoaded() {
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "gamedata/%s.txt", GAMEDATA);
	if (!FileExists(path))
		SetFailState("Mising required gamedata file: %s.", path);

	GameData hGamedata = new GameData(GAMEDATA);
	if (!hGamedata)
		SetFailState("Failed to load %s gamedata.", GAMEDATA);

	// ============================================================
	// Read action constructor of action'SmokerMoveToAttackPosition'
	// ============================================================
	g_hSmokerMove2AtkPosConstructor = ActionConstructor.SetupFromConf(hGamedata, SIG_SMOKER_MOVE_2_ATTACK_POSITION);
	if (!g_hSmokerMove2AtkPosConstructor)
		SetFailState("Failed to find signature: %s in gamedata file: %s.", SIG_SMOKER_MOVE_2_ATTACK_POSITION, GAMEDATA);
	
	// ============================================================
	// Read SDK function 'CTerrorPlayer::GetRunTopSpeed'
	// ============================================================
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, SIG_GET_RUN_TOP_SPEED);
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
	g_hSdkGetRunTopSpeed = EndPrepSDKCall();
	if (!g_hSdkGetRunTopSpeed)
		SetFailState("Failed to find signature: %s in gamedata file: %s.", SIG_GET_RUN_TOP_SPEED, GAMEDATA);

	// ============================================================
	// Search for action constructor of 'SmokerTongueVictim'
	// ============================================================
	OS_Type osType = GetOSType();
	if (osType == OS_windows) {
		// 获取父函数入口地址
		Address pSmokerMove2AtkPosUpdate = hGamedata.GetMemSig(SIG_SMOKER_MOVE_2_ATTACK_POSITION_UPDATE);
		if (pSmokerMove2AtkPosUpdate == Address_Null)
			SetFailState("Failed to find signature address: %s in gamedata file: %s.", SIG_SMOKER_MOVE_2_ATTACK_POSITION_UPDATE, GAMEDATA);
		// 读取 call SmokerTongueVictim 语句距离父函数起始位置的偏移量
		int offset = hGamedata.GetOffset(SIG_SMOKER_TONGUE_VICTIM);
		if (offset < 0)
			SetFailState("Failed to get offset of signature: %s in gamedata file: %s.", SIG_SMOKER_TONGUE_VICTIM, GAMEDATA);
		// E8 imm32, 从 call 指令首地址 +1 字节位置读入 SmokerTongueVictim 函数入口地址的偏移量
		Address pCall = pSmokerMove2AtkPosUpdate + view_as<Address>(offset);
		int rel = LoadFromAddress(pCall + view_as<Address>(1), NumberType_Int32);
		// 计算入口地址
		Address pFunc = pCall + view_as<Address>(5) + view_as<Address>(rel);
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetAddress(pFunc);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSdkSmokerTongueVictim = EndPrepSDKCall();
	} else {
		// Linux and Mac
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, SIG_SMOKER_TONGUE_VICTIM);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSdkSmokerTongueVictim = EndPrepSDKCall();
	}
	if (!g_hSdkSmokerTongueVictim)
		SetFailState("Failed to find signature address: %s in gamedata file: %s.", SIG_SMOKER_TONGUE_VICTIM, GAMEDATA);

	delete hGamedata;
}

public void OnConfigsExecuted() {
	if (!cvTongueRange)
		cvTongueRange = FindConVar("tongue_range");
	g_fTongueRange = !cvTongueRange ? DEFAULT_TONGUE_RANGE : cvTongueRange.FloatValue;
	if (cvTongueRange)
		cvTongueRange.AddChangeHook(cvTongueRangeChangeHook);
}

public void OnPluginEnd() {
	delete log;
	delete g_hSdkGetRunTopSpeed;
	delete g_hSdkSmokerTongueVictim;
}

void evtPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	static int client;
	client = GetClientOfUserId(event.GetInt("userid"));
	if (!isAiSmoker(client))
		return;
	
	g_AiSmokers[client].initData();
}

Action sndHookSmokerWarn(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity,
						int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed) {
	if (entity <= 0 || entity > MaxClients || !isAiSmoker(entity))
		return Plugin_Continue;
	if (g_cvStopSmokerWarnSnd.BoolValue &&
		((StrContains(sample, "Smoker_Warn", false) >= 0) || (StrContains(sample, "Smoker_LaunchTongue", false) >= 0))) {
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void cvTongueRangeChangeHook(ConVar convar, const char[] oldValue, const char[] newValue) {
	g_fTongueRange = convar.FloatValue;
}

// ============================================================
// Main
// ============================================================
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon) {
	if (!isAiSmoker(client))
		return Plugin_Continue;

	static int target;
	target = GetClientOfUserId(g_AiSmokers[client].m_iTarget);
	if (!IsValidSurvivor(target) || !IsPlayerAlive(target))
		return Plugin_Continue;

	static float pos[3], targetPos[3], dist;
	GetClientAbsOrigin(client, pos);
	GetClientEyePosition(target, targetPos);
	dist = GetVectorDistance(pos, targetPos);
	
	static bool visible;
	visible = L4D2_IsVisibleToPlayer(client, TEAM_INFECTED, 0, 0, targetPos);
	g_AiSmokers[client].m_bIsVisible2Target = visible;

	// 无法立刻攻击时, 判断是否允许进行连跳操作
	checkeEnableBhop(client, target, buttons, pos, targetPos, dist, visible);
	// 是否允许拉人时视角转向背后
	checkShouldBackVision(client);
}

/**
* 检测目标是否进入到 tongue_range 范围内
* @param client Smoker 客户端索引
* @param target 目标索引
* @param dist 传入的检测距离
* @return bool 是否进入攻击范围
**/
stock bool isTargetEnterAttackRange(int client, int target, const float dist) {
	if (!isAiSmoker(client) || !IsValidSurvivor(target) || !IsPlayerAlive(target))
		return false;
	// 检查是否可以直视目标
	if (!g_AiSmokers[client].m_bIsVisible2Target)
		return false;
	// 保留一点余量
	return dist <= (g_fTongueRange * 0.95);
}

// ============================================================
// Pulling Survivor Turn Vision Back 拉人时是否允许视角转向身后
// ============================================================
Action checkShouldBackVision(int client) {
	if (!g_cvPullBackVision.BoolValue || !isAiSmoker(client))
		return Plugin_Continue;
	
	static int animSeq;
	animSeq = GetEntProp(client, Prop_Send, "m_nSequence");
	// Smoker 拉人时, 30 ACT_HOP, 把人拉到面前后 31 ACT_LEAP
	if (animSeq < 0 || (animSeq != L4D2_ACT_HOP && animSeq != L4D2_ACT_LEAP))
		return Plugin_Continue;

	static int victim;
	victim = GetEntPropEnt(client, Prop_Send, "m_tongueVictim");
	if (!IsValidSurvivor(victim) || !IsPlayerAlive(victim))
		return Plugin_Continue;

	static float pos[3], targetPos[3], vDir[3];
	GetClientAbsOrigin(client, pos);
	GetClientAbsOrigin(victim, targetPos);
	MakeVectorFromPoints(pos, targetPos, vDir);
	GetVectorAngles(vDir, vDir);
	vDir[1] += 180.0;
	vDir[1] = angleNormalize(vDir[1]);
	
	TeleportEntity(client, NULL_VECTOR, vDir, NULL_VECTOR);
	return Plugin_Continue;
}

/**
* 检查 Smoker 是否处于拉人状态
* @param client 客户端索引
* @return bool 是否处于拉人状态
**/
stock bool isPullingSomeone(int client) {
	if (!isAiSmoker(client))
		return false;

	static int animSeq;
	animSeq = GetEntProp(client, Prop_Send, "m_nSequence");
	// Smoker 拉人时, 30 ACT_HOP, 把人拉到面前后 31 ACT_LEAP
	if (animSeq < 0 || (animSeq != L4D2_ACT_HOP && animSeq != L4D2_ACT_LEAP))
		return false;

	static int victim;
	victim = GetEntPropEnt(client, Prop_Send, "m_tongueVictim");
	if (!IsValidSurvivor(victim) || !IsPlayerAlive(victim))
		return false;
	
	return true;
}

/**
* 检查 Smoker 技能是否冷却完毕
* @param client 客户端索引
* @return bool 是否冷却完毕
**/
stock bool isSmokerReadyToAttack(int client) {
	if (!isAiSmoker(client))
		return false;

	static int ability;
	ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (!IsValidEdict(ability))
		return false;
	static char clsName[32];
	GetEntityClassname(ability, clsName, sizeof(clsName));
	if (strcmp(clsName, "ability_tongue", false) != 0)
		return false;
	
	static float timestamp;
	timestamp = GetEntPropFloat(ability, Prop_Send, "m_timestamp");
	return GetGameTime() >= timestamp;
}

// ============================================================
// Bhop 连跳操作
// ============================================================
Action checkeEnableBhop(int client, int target, int& buttons, const float pos[3], const float targetPos[3], const float dist, const bool visible) {
	if (!g_cvEnableBhop.BoolValue || !isAiSmoker(client) || !IsValidSurvivor(target))
		return Plugin_Continue;
	// 无生还视野不允许连跳
	if (!g_cvBhopNoVision.BoolValue && !visible)
		return Plugin_Continue;
	// 开启进入范围内秒拉, 则技能准备就绪后自身与目标范围满足 tongue_range 之后不允许连跳
	if (g_cvImmPull.BoolValue && isSmokerReadyToAttack(client) && isTargetEnterAttackRange(client, target, dist))
		return Plugin_Continue;

	if (L4D_IsPlayerStaggering(client))
		return Plugin_Continue;

	if (GetEntityMoveType(client) == MOVETYPE_LADDER || GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1)
		return Plugin_Continue;
	
	static float vecVel[3], speed;
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVel);
	speed = SquareRoot(Pow(vecVel[0], 2.0) + Pow(vecVel[1], 2.0));
	if (speed < g_cvBhopMinSpeed.FloatValue)
		return Plugin_Continue;

	if (dist < g_cvBhopMinDist.FloatValue || dist > g_cvBhopMaxDist.FloatValue)
		return Plugin_Continue;

	static float vAbsVelVec[3], vTargetAbsVelVec[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vAbsVelVec);
	GetEntPropVector(target, Prop_Data, "m_vecAbsVelocity", vTargetAbsVelVec);

	if (IsClientOnGround(client) && nextTickPosCheck(client, visible)) {
		static float vPredict[3], vDir[3], vFwd[3], vRight[3];
		// 不可见目标的情况下, 使用当前速度向量角度进行连跳加速
		if (!visible) {
			GetVectorAngles(vecVel, vDir);
			GetAngleVectors(vDir, vFwd, vRight, NULL_VECTOR);
		} else {
			// 计算目标下一帧的位置, 然后根据这个位置进行连跳加速
			AddVectors(targetPos, vTargetAbsVelVec, vPredict);
			MakeVectorFromPoints(pos, vPredict, vDir);
			vDir[2] = 0.0;
			NormalizeVector(vDir, vDir);
			// vFwd 为加速度方向向量, vDir 为到目标方向向量
			vFwd = vDir;
			// 增加水平偏移让跳跃轨迹稍微左右摆动
			if (g_cvBhopSideMaxAng.FloatValue > 0.0) {
				static float vFwdAng[3], yawOff;
				GetVectorAngles(vFwd, vFwdAng);
				yawOff = GetRandomFloatInRange(g_cvBhopSideMinAng.FloatValue, g_cvBhopSideMaxAng.FloatValue);
				if (!g_AiSmokers[client].m_bToggleSide)
					yawOff = -yawOff;
				g_AiSmokers[client].m_bToggleSide = !g_AiSmokers[client].m_bToggleSide;
				// 应用水平方向偏移
				vFwdAng[1] = angleNormalize(vFwdAng[1] + yawOff);
				// 转回向量
				GetAngleVectors(vFwdAng, vFwd, NULL_VECTOR, NULL_VECTOR);
			}
		}

		buttons |= IN_DUCK;
		buttons |= IN_JUMP;

		static bool fwdOnly, backOnly, leftOnly, rightOnly;
		fwdOnly = ((buttons & IN_FORWARD) && !(buttons & IN_BACK));
		backOnly = ((buttons & IN_BACK) && !(buttons & IN_FORWARD));
		leftOnly = ((buttons & IN_LEFT) && !(buttons & IN_RIGHT));
		rightOnly = ((buttons & IN_RIGHT) && !(buttons & IN_LEFT));

		// Smoker 在有生还者视野时可能也会向后走, 因此要 IN_FORWARD 和 IN_BACK 要分开处理
		if (fwdOnly) {
			if (!visible) {
				// 无生还者视野, vFwd 为当前速度方向, 使用当前速度方向作为加速度方向
				NormalizeVector(vFwd, vFwd);
				ScaleVector(vFwd, g_cvBhopImpulse.FloatValue);
				AddVectors(vAbsVelVec, vFwd, vAbsVelVec);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vAbsVelVec);
			} else {
				// 有生还者视野, 向前时, 直接使用原来已经计算好的前向向量替换当前速度向量, 达到轨迹左右摆动效果
				NormalizeVector(vFwd, vFwd);
				ScaleVector(vFwd, (speed + g_cvBhopImpulse.FloatValue));
				AddVectors(vAbsVelVec, vFwd, vAbsVelVec);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vFwd);
			}
		} else if (backOnly && (vecVel[0] > 0.0 && vecVel[1] > 0.0)) {
			vFwd[0] = vecVel[0];
			vFwd[1] = vecVel[1];
			vFwd[2] = 0.0;
			NormalizeVector(vFwd, vFwd);
			ScaleVector(vFwd, g_cvBhopImpulse.FloatValue);
			AddVectors(vAbsVelVec, vFwd, vAbsVelVec);
			// 向后连跳, 使用当前速度方向作为加速度方向
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vAbsVelVec);
		} else {
			static float baseFwd[3];
			if (fwdOnly) {
				baseFwd[0] = vFwd[0];
				baseFwd[1] = vFwd[1];
				baseFwd[2] = 0.0;
			} else if (backOnly && (vecVel[0] > 0.0 && vecVel[1] > 0.0)) {
				baseFwd[0] = vecVel[0];
				baseFwd[1] = vecVel[1];
				baseFwd[2] = 0.0;
			} else {
				baseFwd[0] = vDir[0];
				baseFwd[1] = vDir[1];
				baseFwd[2] = 0.0;
			}
			GetVectorCrossProduct({0.0, 0.0, 1.0}, baseFwd, vRight);
			NormalizeVector(vRight, vRight);
			// 避免左右键同时按下仍触发侧向加速
			if (rightOnly ^ leftOnly) {
				ScaleVector(vRight, g_cvBhopImpulse.FloatValue * (rightOnly ? 1.0 : -1.0));
				AddVectors(vAbsVelVec, vRight, vAbsVelVec);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vAbsVelVec);
			}
		}
		return Plugin_Changed;
	}

	// 检查空速是否大于限制速度
	if (speed > g_cvBhopMaxSpeed.FloatValue) {
		NormalizeVector(vecVel, vecVel);
		ScaleVector(vecVel, g_cvBhopMaxSpeed.FloatValue);
		SetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVel);
	}
	// 在空中的时候, 检查是否连跳过头
	static float angle, vDir[3], vAbsVelVecCpy[3];
	vAbsVelVecCpy = vAbsVelVec;
	NormalizeVector(vAbsVelVec, vAbsVelVec);
	MakeVectorFromPoints(pos, targetPos, vDir);
	NormalizeVector(vDir, vDir);
	vAbsVelVec[2] = vDir[2] = 0.0;

	static float dx, dz, pitch;
	dx = SquareRoot(Pow(targetPos[0] - pos[0], 2.0) + Pow(targetPos[1] - pos[1], 2.0));
	dz = targetPos[2] - pos[2];
	pitch = RadToDeg(ArcTangent(dz / dx));
	// 如果玩家处在Smoker上方或者下方, 俯仰角大于 45 度, 放弃速度修正
	// if target is above or below Smoker, pitch > 45°, give up air velocity vector direction modify
	if (pitch > 45.0)
		return Plugin_Continue;

	// 计算夹角, 夹角不超过范围, 且可视, 没有按后退键才允许修正
	angle = RadToDeg(ArcCosine(GetVectorDotProduct(vAbsVelVec, vDir)));
	if (visible
		&& angle > g_cvAirVecModifyDegree.FloatValue && angle < g_cvAirVecModifyMaxDegree.FloatValue
		&& GetEngineTime() - g_AiSmokers[client].m_flLastAirModifyTime > g_cvAirVecModifyInterval.FloatValue
		&& ((buttons & IN_FORWARD) && !(buttons & IN_BACK))) {
			log.debugAll("%N triggered air speed modify, current vector angle: %.2f", client, angle);
			static float runTopSpeed;
			runTopSpeed = SDKCall(g_hSdkGetRunTopSpeed, client);
			ScaleVector(vDir, runTopSpeed + g_cvBhopImpulse.FloatValue);
			log.debugAll("%N's run top speed: %.2f, speed vec len: %.2f, new vector length: %.2f", client, runTopSpeed, speed, GetVectorLength(vDir));
			vDir[2] = vAbsVelVecCpy[2];
			// 应用新的速度方向
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vDir);
			g_AiSmokers[client].m_flLastAirModifyTime = GetEngineTime();
	}

	return Plugin_Continue;
}

stock bool nextTickPosCheck(int client, bool visible) {
	if (!isAiSmoker(client))
		return false;

	static float vMins[3], vMaxs[3];
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);

	static float pos[3], endPos[3], vecVel[3], speed;
	GetClientAbsOrigin(client, pos);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVel);
	speed = GetVectorLength(vecVel);
	NormalizeVector(vecVel, vecVel);
	// 为下一帧检测的位置留出一些余量 (bbox 宽度 + 3), endPos 为下一帧位置
	ScaleVector(vecVel, speed + FloatAbs(vMaxs[0] - vMins[0]) + 3.0);
	AddVectors(pos, vecVel, endPos);
	pos[2] += 10.0;
	endPos[2] += 10.0;

	// 射线检测
	static Handle hTrace;
	hTrace = TR_TraceHullFilterEx(pos, endPos, {-36.0, -36.0, 10.0}, {36.0, 36.0, 72.0}, MASK_PLAYERSOLID, _TraceWallFilter, client);
	if (TR_DidHit(hTrace)) {
		// 防止下次连跳速度方向撞墙 (速度方向与墙的法向量垂直为 180 度)
		static float rayEndPos[3], hitNormal[3];
		TR_GetEndPosition(rayEndPos, hTrace);
		TR_GetPlaneNormal(hTrace, hitNormal);
		NormalizeVector(hitNormal, hitNormal);
		NormalizeVector(vecVel, vecVel);
		if (RadToDeg(ArcCosine(GetVectorDotProduct(hitNormal, vecVel))) > 165.0) {
			delete hTrace;
			return false;
		}
	}

	if (!visible) {
		// 无视野情况, 计算视角与速度向量夹角, 若太大则禁止连跳
		static float eyeAng[3], dir[3], angle;
		GetClientEyeAngles(client, eyeAng);
		GetAngleVectors(eyeAng, dir, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(dir, dir);
		NormalizeVector(vecVel, vecVel);
		dir[2] = vecVel[2] = 0.0;
		angle = RadToDeg(ArcCosine(GetVectorDotProduct(dir, vecVel)));
		if (floatIsNan(angle) || angle > g_cvBhopNoVisionMaxAng.FloatValue) {
			delete hTrace;
			return false;
		}
	}

	delete hTrace;
	// 检测下一帧向下的位置是否会死亡
	static float downPos[3];
	downPos = endPos;
	downPos[2] -= 99999.0;
	hTrace = TR_TraceHullFilterEx(endPos, downPos, {-16.0, -16.0, 0.0}, {16.0, 16.0, 0.0}, MASK_PLAYERSOLID, _TraceWallFilter, client);
	// 太高了, 返回 false
	if (!TR_DidHit(hTrace)) {
		delete hTrace;
		return false;
	}

	static int hitEnt;
	hitEnt = TR_GetEntityIndex(hTrace);
	if (IsValidEntity(hitEnt)) {
		static char className[32];
		GetEntityClassname(hitEnt, className, sizeof(className));
		if (strcmp(className, "trigger_hurt", false) == 0) {
			delete hTrace;
			return false;
		}
	}
	delete hTrace;
	return true;
}

// ============================================================
// 目标缓存
// ============================================================
public Action L4D2_OnChooseVictim(int smoker, int &curTarget) {
	if (!isAiSmoker(smoker) || !IsValidSurvivor(curTarget))
		return Plugin_Continue;
	// Smoker 无能力强制追击目标且处于切换更近目标状态时, 不覆盖
	if (g_AiSmokers[smoker].m_bIsMove2ChangeTar)
		return Plugin_Continue;

	if (!IsValidSurvivor(g_AiSmokers[smoker].m_iTarget) || GetClientOfUserId(g_AiSmokers[smoker].m_iTarget) != curTarget)
		g_AiSmokers[smoker].m_iTarget = GetClientUserId(curTarget);

	return Plugin_Continue;
}

// ============================================================
// Actions Hook 是否启用无技能追击
// ============================================================
public void OnActionCreated(BehaviorAction action, int actor, const char[] name) {
	if (!isAiSmoker(actor))
		return;

	// 防止 Smoker 舌头被切断后卡在 TongueVictim 行为
	if (strcmp(name, ACT_NAME_TONGUE_VICTIM, false) == 0) {
		action.OnUpdate = onSmokerTongueVictimOnUpdate;
	}

	if (g_cvImmPull.BoolValue) {
		// Smoker 进入 tongue_range 范围内立刻将 MoveToAttackPosition 行为替换为 TongueVictim 行为, 令其吐舌头
		if (strcmp(name, ACT_NAME_MOVE_TO_ATTACK_POSITION, false) == 0) {
			action.OnUpdate = onSmokerMoveToAtkPosOnUpdate;
		}
	}

	if (g_cvAntiRetreat.BoolValue) {
		// Smoker 正在逃跑的时候, hook OnUpdate 每帧更新函数
		// 需要检测能力 timestamp 因为 Smoker 拉人的时候也是 RetreatToCover 状态, 去除 tongueVictim 检测, 因为 tongueVictim 不会在舌头一断立即无效
		if (strcmp(name, ACT_NAME_RETREAT, false) == 0 && !isSmokerReadyToAttack(actor)) {
			action.OnUpdate = onSmokerRetreatOnUpdate;
		}
		// 移动到目标位置过程中检测每帧调用的 OnUpdate 函数
		// 如果不 hook BehaviorMovrTo 状态, 因为目标位置在生还者的脚底下, Smoker 无法到达, 就会一直抠人, 舌头 CD 好了也不会放技能, 要手动取消 MoveTo 状态
		if (strcmp(name, ACT_NAME_MOVETO, false) == 0) {
			action.OnUpdate = onMove2Change2Attack;
		}
	}
}

/**
* Smoker 技能已经准备就绪, 进入 SmokerMoveToAttackPosition 行为, 进行攻击找位, Hook OnUpdate 每帧更新函数
* 检测若与目标距离在 tongue_range 范围内, 则将 MoveToAttackPosition 行为更改为 TongueVictim 行为, 令其吐舌头
* @param action 当前动作
* @param actor 动作父实体
* @param interval 上一次调用到这次调用的间隔时间
* @param result 上一次执行子行为的返回结果
* @return Action
**/
Action onSmokerMoveToAtkPosOnUpdate(BehaviorAction action, int actor, float interval, ActionResult result) {
	if (!g_cvImmPull.BoolValue || !isAiSmoker(actor))
    	return Plugin_Continue;
	
	static int target;
	target = GetClientOfUserId(g_AiSmokers[actor].m_iTarget);
	if (!IsValidSurvivor(target) || !IsPlayerAlive(target))
		return Plugin_Continue;
	static float pos[3], targetPos[3], dist;
	GetClientAbsOrigin(actor, pos);
	GetClientEyePosition(target, targetPos);
	dist = GetVectorDistance(pos, targetPos);
	// 目标没有进入到攻击范围, 不处理
	if (!isTargetEnterAttackRange(actor, target, dist))
		return Plugin_Continue;
	
	static BehaviorAction newAction;
	newAction = createSmokerTongueVictim(target);
	if (!newAction)
		return Plugin_Continue;
	
	action.ChangeTo(newAction);
	return Plugin_Changed;
}

/**
* 由于 checkShouldAttack 函数存在, Smoker 一旦生成在距离目标 tongue_range 范围内, 则会立刻攻击, 若此时舌头被砍断, 则会卡在 SmokerTongueVictim 行为中, 无法转换到逃跑行为
* 因此 Hook 这个行为的 OnUpdate 函数, 检测若 Smoker 技能未冷却完毕且不是在拉人状态中卡在这个行为, 则将这个行为结束
* SmokerTongueVictim 行为每帧的更新函数
* @param action 当前动作
* @param actor 动作父实体
* @param interval 上一次调用到这次调用的间隔时间
* @param result 上一次执行子行为的返回结果
* @return Action
**/
Action onSmokerTongueVictimOnUpdate(BehaviorAction action, int actor, float interval, ActionResult result) {
	if (!isAiSmoker(actor))
		return Plugin_Continue;

	// 如果舌头技能未冷却完毕, 且没有在拉人, 这时候如果处于 TongueVictim 行为则会令舌头卡住, 结束这个行为
	if (!isSmokerReadyToAttack(actor) && !isPullingSomeone(actor)) {
		action.Done();
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

/**
* 当 Smoker 处于无技能逃跑状态时, 每帧触发这个 Update 回调, 我们将 SmokerRetreat 动作更改为 MoveTo, 令其接近目标
* 原始行为: 朝掩体方向移动 -> 等待技能 CD 结束 -> MoveToAttackPosition -> TongueVictim
* 修改行为: 使用 CommandABot 命令, 生成一个 BehaviorMoveTo 行为, 延迟 Retreat 行为, 令 Smoker 移动到目标位置
* @param action 当前动作
* @param actor 动作父实体
* @param interval 上一次调用到这次调用的间隔时间
* @param result 上一次执行子行为的返回结果
* @return Action
**/
Action onSmokerRetreatOnUpdate(BehaviorAction action, int actor, float interval, ActionResult result) {
	if (!isAiSmoker(actor))
		return Plugin_Continue;

	static int target;
	target = GetClientOfUserId(g_AiSmokers[actor].m_iTarget);
	if (!IsValidSurvivor(target)) {
		g_AiSmokers[actor].m_bIsMove2ChangeTar = false;
		return Plugin_Continue;
	}

	// Smoker 拉到人时, 也会触发 SmokerRetreatToCover
	if (isPullingSomeone(actor))
		return Plugin_Continue;

	log.debugAll("Retreat on update, Smoker(%N) target %N, change to move to %N", actor, target, target);
	GetClientAbsOrigin(target, g_AiSmokers[actor].m_vecMoveToPos);
	L4D2_CommandABot(actor, target, BOT_CMD_MOVE, g_AiSmokers[actor].m_vecMoveToPos);
	// 记录最后一次移动命令时间，以便移动中切换目标时使用
	g_AiSmokers[actor].m_flLastMoveToTime = GetEngineTime();

	// 这里不使用 action.Done() 保持当前行为树 BehaviorMoveTo<<SmokerRetreatToCover<<SmokerAttack
	// 如果使用 action.Done() 就会变成 BehaviorMoveTo<<SmokerAttack
	// action.Done();

	return Plugin_Changed;
}

/**
* 受到 CommandABot 命令时转换为 BehaviorMoveTo 状态, 该状态的 Update 函数
* 检查条件: 
* 1. Smoker 技能冷却时间已结束, 则立即切换到攻击目标的 MoveToAttackPosition 行为寻找攻击位置攻击
* 2. 或者发现比当前目标更近的生还者，则切换追击目标
* @param action 当前动作
* @param actor 动作父实体
* @return Action
**/
Action onMove2Change2Attack(BehaviorAction action, int actor, float interval, ActionResult result) {
	if (!isAiSmoker(actor))
		return Plugin_Continue;

	static int target, nearestTar;
	target = GetClientOfUserId(g_AiSmokers[actor].m_iTarget);
	// 当前目标 (无论是缓存的原目标, 还是更换的更近的目标) 一旦无效, 立即释放 m_bIsMove2ChangeTar, 让 L4D2_OnChooseVictim 选择目标
	if (!IsValidSurvivor(target)) {
		g_AiSmokers[actor].m_bIsMove2ChangeTar = false;
		// 立即完成当前动作, 回到 RetreatToCover 状态决策下一步动作
		action.Done();
		return Plugin_Changed;
	}
	
	// 检查 Smoker 技能冷却时间, 如果冷却完了, 立即构造 SmokerMoveToAttackPosition 令 Smoker 攻击目标
	if (isSmokerReadyToAttack(actor)) {
		log.debugAll("Smoker(%N) cooldown end, force him to attack %N", actor, target);
		// 更改当前动作
		static BehaviorAction newAction;
		newAction = createSmokerMoveToPosition(target);
		if (!newAction)
			return Plugin_Continue;
		
		// 直到技能冷却结束, 允许之后使用 L4D2_OnChooseVictim 中的目标覆盖缓存中的目标, 然后将当前 BehaviorMoveTo 行为更改为 MoveToAttackPosition 行为
		g_AiSmokers[actor].m_bIsMove2ChangeTar = false;
		action.ChangeTo(newAction, "Cooldown End, Force Attack");
		return Plugin_Changed;
	}

	// 每隔一定时间间隔, 检测是否还有比当前目标更近的生还者, 如果有, 则改为追更近的生还者
	nearestTar = getClosestSurvivorAndValid(actor, -1);
	static float targetPos[3];
	static bool shouldInvalidate;
	shouldInvalidate = false;

	if (IsValidSurvivor(nearestTar)) {
		// 获取最近目标位置, 定时与 Smoker 结构体中的 m_vecMoveToPos 比对
		GetClientAbsOrigin(nearestTar, targetPos);
		shouldInvalidate = (
			!vectorsEqual(g_AiSmokers[actor].m_vecMoveToPos, targetPos) &&
			GetEngineTime() - g_AiSmokers[actor].m_flLastMoveToTime > g_cvMove2NewTarInterval.FloatValue
		);
		// 最近目标不是当前目标或者位置变了
		if (target != nearestTar) {
			// 更换当前目标到最近的生还者
			g_AiSmokers[actor].m_iTarget = GetClientUserId(nearestTar);
			g_AiSmokers[actor].m_bIsMove2ChangeTar = true;
			log.debugAll("Smoker(%N) target %N, find a nearer target %N, change to move to %N", actor, target, nearestTar, nearestTar);
		}
	} else {
		GetClientAbsOrigin(target, targetPos);
		shouldInvalidate = (
			!vectorsEqual(g_AiSmokers[actor].m_vecMoveToPos, targetPos) &&
			GetEngineTime() - g_AiSmokers[actor].m_flLastMoveToTime > g_cvMove2NewTarInterval.FloatValue
		);
	}
	if (shouldInvalidate) {
		// 结束当前 BehaviorMoveTo 移动行为, 若舌头 CD 还没好, 则回到 RetreatToCover 重新触发移动到新的目标位置
		action.Done();
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

/**
* 创建 SmokerMoveToPosition 行为
* @param target 目标生还者索引
* @return BehaviorAction
**/
stock BehaviorAction createSmokerMoveToPosition(int target) {
	if (!IsValidSurvivor(target))
		return INVALID_ACTION;
	
	// 调用构造函数初始化申请的内存块
	return g_hSmokerMove2AtkPosConstructor.Execute(target);
}

/**
* 创建 SmokerTongueVictim 行为
* @param target 目标生还者索引
* @return BehaviorAction
**/
stock BehaviorAction createSmokerTongueVictim(int target) {
	if (!IsValidSurvivor(target))
		return INVALID_ACTION;

	static BehaviorAction action;
	action = ActionsManager.Allocate(ACT_SIZE_TONGUE_VICTIM);
	if (action == INVALID_ACTION)
		return INVALID_ACTION;
	
	SDKCall(g_hSdkSmokerTongueVictim, action, target);
	return action;
}

stock int getClosestSurvivorAndValid(int smoker, int excludeTar = -1) {
	if (!isAiSmoker(smoker))
		return -1;
	
	static int target;
	static float pos[3], targetPos[3];
	static ArrayList targets;
	if (!targets)
		targets = new ArrayList(2);

	GetClientAbsOrigin(smoker, pos);
	for (int i = 1; i <= MaxClients; i++) {
		if (i == smoker || i == excludeTar)
			continue;
		if (!IsValidSurvivor(i) || !IsPlayerAlive(i) || IsClientPinned(i) || IsClientIncapped(i) || IsClientHanging(i))
			continue;

		GetClientAbsOrigin(i, targetPos);
		targets.Set(targets.Push(GetVectorDistance(pos, targetPos)), i, 1);
	}

	if (targets.Length < 1) {
		delete targets;
		return -1;
	}

	SortADTArray(targets, Sort_Ascending, Sort_Float);
	target = targets.Get(0, 1);
	delete targets;
	return target;
}
