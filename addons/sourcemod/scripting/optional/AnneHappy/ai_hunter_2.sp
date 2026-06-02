#pragma semicolon 1
#pragma newdecls required

// ===== 头文件 =====
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <treeutil>

// ===== 兼容常量（若环境里已有则不会重复定义）=====
#if !defined TEAM_SURVIVOR
    #define TEAM_SURVIVOR 2
#endif
#if !defined TEAM_INFECTED
    #define TEAM_INFECTED 3
#endif

// ===== 插件信息 =====
public Plugin myinfo =
{
    name        = "Ai Hunter 2.0 (fixed)",
    author      = "夜羽真白, patch by ChatGPT",
    description = "Ai Hunter 增强（修正若干编译/运行问题与健壮性）",
    version     = "2025-09-24",
    url         = "https://steamcommunity.com/id/saku_ra/"
};

// ===== 宏&常量 =====
#define CVAR_FLAG               FCVAR_NOTIFY
#define LUNGE_LEFT              45.0
#define LUNGE_RIGHT             315.0
#define INVALID_CLIENT          -1
#define INVALID_NAV_AREA        0
#define HURT_CHECK_INTERVAL     0.2
#define CROUCH_HEIGHT           20.0
#define POUNCE_LEFT_IDX         0     // FIX: 拼写统一
#define POUNCE_RIGHT_IDX        1
#define DEBUG                   0

// ===== 基本 cvar =====
ConVar
    g_hFastPounceDistance,
    g_hPounceVerticalAngle,
    g_hPounceAngleMean,
    g_hPounceAngleStd,
    g_hStraightPounceDistance,
    g_hAimOffset,
    g_hNoSightPounceRange,          // FIX: 正名 no_sight
    g_hNoSightPounceRangeLegacy,    // 兼容旧名 no_sign
    g_hBackVision,
    g_hMeleeFirst,
    g_hHighPounceHeight,
    g_hWallDetectDistance,
    g_hAnglePounceCount;

// ===== 其他 cvar（只读/外部）=====
ConVar
    g_hLungeInterval,
    g_hPounceReadyRange,
    g_hPounceLoftAngle,
    g_hPounceGiveUpRange,
    g_hPounceSilenceRange,
    g_hCommitAttackRange,
    g_hLungePower,
    g_hHunterPatchConvertLeap,
    g_hHunterPatchCrouchPounce;

// ===== 运行时状态 =====
bool
    ignoreCrouch,
    hasQueuedLunge[MAXPLAYERS + 1],
    canBackVision[MAXPLAYERS + 1][2]; // [0]=已抽签, [1]=是否背视

float
    canLungeTime[MAXPLAYERS + 1],
    meleeMinRange,
    meleeMaxRange,
    noSightPounceRange,
    noSightPounceHeight;

int
    anglePounceCount[MAXPLAYERS + 1][2],
    hunterCurrentTarget[MAXPLAYERS + 1];

// ===== 安全获取 CVar 的工具函数 =====
static float CvarFloat(ConVar c, float defVal)
{
    return (c != null) ? c.FloatValue : defVal;
}
static int CvarInt(ConVar c, int defVal)
{
    return (c != null) ? c.IntValue : defVal;
}
static void CvarSetFloatSafe(ConVar c, float v)
{
    if (c != null) c.SetFloat(v);
}
static void CvarRestoreSafe(ConVar c)
{
    if (c != null) c.RestoreDefault();
}

// ===== 生命周期 =====
public void OnPluginStart()
{
    // ---- 定义本插件的 CVar（修正 min/max）----
    g_hFastPounceDistance   = CreateConVar("ai_hunter_fast_pounce_distance", "1000.0",
        "hunter 开始进行快速突袭的距离", CVAR_FLAG, true, 0.0); // FIX: 去掉 hasMax 1.0
    g_hPounceVerticalAngle  = CreateConVar("ai_hunter_vertical_angle", "7.0",
        "hunter 突袭的垂直角度不会超过这个大小（度）", CVAR_FLAG, true, 0.0);
    g_hPounceAngleMean      = CreateConVar("ai_hunter_angle_mean", "10.0",
        "由随机数生成的基本角度", CVAR_FLAG, true, 0.0);
    g_hPounceAngleStd       = CreateConVar("ai_hunter_angle_std", "20.0",
        "与基本角度允许的偏差范围", CVAR_FLAG, true, 0.0);
    g_hStraightPounceDistance = CreateConVar("ai_hunter_straight_pounce_distance", "200.0",
        "hunter 允许直扑的范围", CVAR_FLAG, true, 0.0);
    g_hAimOffset            = CreateConVar("ai_hunter_aim_offset", "360.0",
        "与目标水平角度在这一范围内且在直扑范围外，ht 不会直扑", CVAR_FLAG, true, 0.0, true, 360.0);

    // 正名：no_sight；同时尝试兼容旧名 no_sign
    g_hNoSightPounceRange   = CreateConVar("ai_hunter_no_sight_pounce_range", "300.0,250.0",
        "不可见目标允许飞扑的范围（水平,垂直；0 代表该维度禁用）", CVAR_FLAG);
    g_hNoSightPounceRangeLegacy = FindConVar("ai_hunter_no_sign_pounce_range"); // 兼容

    g_hBackVision           = CreateConVar("ai_hunter_back_vision", "25",
        "hunter 在空中背对生还者视角的概率(%)，0=禁用", CVAR_FLAG, true, 0.0, true, 100.0);

    g_hMeleeFirst           = CreateConVar("ai_hunter_melee_first", "300.0,1000.0",
        "每次准备突袭时是否先按右键（最小,最大距离；0=禁用）", CVAR_FLAG);

    g_hHighPounceHeight     = CreateConVar("ai_hunter_high_pounce", "400",
        "高度差超过该值时可直接高扑（单位：Hammer 坐标 Z）", CVAR_FLAG, true, 0.0);

    // FIX: 允许 -1 关闭，不设 min/max，避免默认被夹成 0
    g_hWallDetectDistance   = CreateConVar("ai_hunter_wall_detect_distance", "-1.0",
        "视线前方墙体检测的射线长度；-1 关闭", CVAR_FLAG);

    g_hAnglePounceCount     = CreateConVar("ai_hunter_angle_diff", "3",
        "随机侧飞时左右累计次数差的上限", CVAR_FLAG, true, 0.0);

    // ---- 监听变动 ----
    g_hMeleeFirst.AddChangeHook(meleeFirstRangeChangedHandler);
    g_hNoSightPounceRange.AddChangeHook(noSightPounceRangeChangedHandler);
    if (g_hNoSightPounceRangeLegacy != null)
        g_hNoSightPounceRangeLegacy.AddChangeHook(noSightPounceRangeChangedHandler);

    // ---- 读取外部 CVar ----
    g_hLungeInterval       = FindConVar("z_lunge_interval");
    g_hPounceReadyRange    = FindConVar("hunter_pounce_ready_range");
    g_hPounceLoftAngle     = FindConVar("hunter_pounce_max_loft_angle");
    g_hPounceGiveUpRange   = FindConVar("hunter_leap_away_give_up_range");
    g_hPounceSilenceRange  = FindConVar("z_pounce_silence_range");
    g_hCommitAttackRange   = FindConVar("hunter_committed_attack_range");
    g_hLungePower          = FindConVar("z_lunge_power");

    // ---- 事件 ----
    HookEvent("player_spawn", playerSpawnHandler);
    HookEvent("ability_use", abilityUseHandler);
    HookEvent("round_end", roundEndHandler);

    // ---- 初始化运行参数 ----
    getHunterMeleeFirstRange();
    getNoSightPounceRange();
    setCvarValue(true);
}

public void OnPluginEnd()
{
    setCvarValue(false);
}

public void OnMapEnd()
{
    resetCanLungeTime();
}

public void OnAllPluginsLoaded()
{
    // 兼容 hunter_patch，并监听动态难度运行时切换。
    g_hHunterPatchConvertLeap = FindConVar("l4d2_hunter_patch_convert_leap");
    g_hHunterPatchCrouchPounce = FindConVar("l4d2_hunter_patch_crouch_pounce");

    if (g_hHunterPatchConvertLeap != null)
        g_hHunterPatchConvertLeap.AddChangeHook(hunterPatchChangedHandler);

    if (g_hHunterPatchCrouchPounce != null)
        g_hHunterPatchCrouchPounce.AddChangeHook(hunterPatchChangedHandler);

    updateHunterPatchCompatibility();
}

void hunterPatchChangedHandler(ConVar convar, const char[] oldValue, const char[] newValue)
{
    updateHunterPatchCompatibility();
}

void updateHunterPatchCompatibility()
{
    ignoreCrouch = g_hHunterPatchConvertLeap != null
        && g_hHunterPatchConvertLeap.IntValue == 1
        && g_hHunterPatchCrouchPounce != null
        && g_hHunterPatchCrouchPounce.IntValue == 2;

    if (ignoreCrouch)
    {
        if (g_hPounceReadyRange) g_hPounceReadyRange.FloatValue = 0.0;
        ConVar c = FindConVar("z_pounce_crouch_delay");
        if (c) c.FloatValue = 0.0;
        c = FindConVar("hunter_committed_attack_range");
        if (c) c.FloatValue = 0.0;
    }
    else
    {
        if (g_hPounceReadyRange) g_hPounceReadyRange.FloatValue = 3000.0;
        ConVar c = FindConVar("z_pounce_crouch_delay");
        if (c) c.RestoreDefault();
        c = FindConVar("hunter_committed_attack_range");
        if (c) c.FloatValue = 3000.0;
    }
}

// 统一设置/还原几个外部 CVar
void setCvarValue(bool set)
{
    if (set)
    {
        CvarSetFloatSafe(g_hPounceLoftAngle,     0.0);
        CvarSetFloatSafe(g_hPounceGiveUpRange,   0.0);
        CvarSetFloatSafe(g_hPounceSilenceRange,  999999.0);
        return;
    }
    CvarRestoreSafe(g_hPounceReadyRange);
    CvarRestoreSafe(g_hPounceLoftAngle);
    CvarRestoreSafe(g_hPounceGiveUpRange);
    CvarRestoreSafe(g_hPounceSilenceRange);
    CvarRestoreSafe(g_hCommitAttackRange);
}

// ===== 主逻辑 =====
public Action OnPlayerRunCmd(int hunter, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if (!isValidHunter(hunter)) return Plugin_Continue;

    int target = hunterCurrentTarget[hunter];
    int ability = GetEntPropEnt(hunter, Prop_Send, "m_customAbility");
    if (!IsValidEntity(ability) || !IsValidEdict(ability) || !IsValidSurvivor(target))
        return Plugin_Continue;

    // 时间与向量
    float timestamp = GetEntPropFloat(ability, Prop_Send, "m_timestamp");
    float gametime  = GetGameTime();

    float lungeVector[3];
    GetEntPropVector(ability, Prop_Send, "m_queuedLunge", lungeVector);

    bool hasSight   = view_as<bool>(GetEntProp(hunter, Prop_Send, "m_hasVisibleThreats"));
    bool isDucking  = view_as<bool>(GetEntProp(hunter, Prop_Send, "m_bDucked"));
    bool isLunging  = view_as<bool>(GetEntProp(ability, Prop_Send, "m_isLunging"));

    float selfPos[3], targetPos[3];
    GetClientAbsOrigin(hunter, selfPos);
    GetEntPropVector(target,  Prop_Send, "m_vecOrigin", targetPos);
    float targetDistance = GetVectorDistance(selfPos, targetPos);

    // 空中：一次性决定是否背对
    if (isLunging)
    {
        if (!canBackVision[hunter][0])
        {
            float backVisionChance = GetRandomFloat(0.0, 100.0); // FIX: 函数名
            canBackVision[hunter][1] = (backVisionChance <= CvarFloat(g_hBackVision, 0.0));
            canBackVision[hunter][0] = true;
        }
        if (canBackVision[hunter][1])
        {
            // 背对“目标方向”而非“飞扑方向”，视觉表现更稳定
            float lungeVectorNegate[3];
            MakeVectorFromPoints(selfPos, targetPos, lungeVectorNegate);
            NegateVector(lungeVectorNegate);
            NormalizeVector(lungeVectorNegate, lungeVectorNegate);
            GetVectorAngles(lungeVectorNegate, lungeVectorNegate);
            TeleportEntity(hunter, NULL_VECTOR, lungeVectorNegate, NULL_VECTOR);
            return Plugin_Changed;
        }
        return Plugin_Continue;
    }

    if (!isOnGround(hunter)) return Plugin_Continue;
    canBackVision[hunter][0] = false;

    // ===== 无视野：允许“排队起扑”与“近身右键” =====
    if (!hasSight && IsValidSurvivor(target))
    {
        if (!isDucking) return Plugin_Changed;

        if (g_hMeleeFirst.BoolValue &&
            ((gametime > timestamp - 0.1) && (gametime < timestamp)) &&
            ((targetDistance < meleeMaxRange) && (targetDistance > meleeMinRange)))
        {
            buttons |= IN_ATTACK2;
        }
        else if (gametime > timestamp)
        {
            // 高度/距离阈值（0 代表该维度禁用）
            if (noSightPounceRange  > 0.0 && targetDistance > noSightPounceRange)  return Plugin_Continue;
            if (noSightPounceHeight > 0.0 && FloatAbs(selfPos[2] - targetPos[2]) > noSightPounceHeight) return Plugin_Continue;

            if (!hasQueuedLunge[hunter])
            {
                hasQueuedLunge[hunter] = true;
                canLungeTime[hunter]   = gametime + CvarFloat(g_hLungeInterval, 0.1); // SAFE 默认
            }
            else if (gametime > canLungeTime[hunter])
            {
                buttons |= IN_ATTACK;
                hasQueuedLunge[hunter] = false;
            }
        }
        return Plugin_Changed;
    }

    // ===== 有视野：飞扑前按右键（挠） =====
    if (isDucking && g_hMeleeFirst.BoolValue &&
        ((gametime > timestamp - 0.1) && (gametime < timestamp)) &&
        ((targetDistance < meleeMaxRange) && (targetDistance > meleeMinRange)))
    {
        buttons |= IN_ATTACK2;
    }

    // 距离门限内，开始“排队起扑”
    if (!isOnGround(hunter) || targetDistance > CvarFloat(g_hFastPounceDistance, 1000.0))
        return Plugin_Continue;

    buttons &= ~IN_ATTACK;

    if (!hasQueuedLunge[hunter])
    {
        hasQueuedLunge[hunter] = true;
        canLungeTime[hunter]   = gametime + CvarFloat(g_hLungeInterval, 0.1); // SAFE
    }
    else if (canLungeTime[hunter] < gametime)
    {
        buttons |= IN_ATTACK;
        hasQueuedLunge[hunter] = false;
    }

    // 梯子上禁止跳/蹲，并清空排队（避免下梯瞬间起扑）
    if (GetEntityMoveType(hunter) == MOVETYPE_LADDER)
    {
        buttons &= ~IN_JUMP;
        buttons &= ~IN_DUCK;
        hasQueuedLunge[hunter] = false; // SAFE
    }

    return Plugin_Changed;
}

// ===== 事件 =====
public void playerSpawnHandler(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!isValidHunter(client)) return;

    hasQueuedLunge[client]      = false;
    canBackVision[client][0]    = false;
    canBackVision[client][1]    = false;
    canLungeTime[client]        = 0.0;
    anglePounceCount[client][POUNCE_LEFT_IDX]  = 0;
    anglePounceCount[client][POUNCE_RIGHT_IDX] = 0;
}

public void abilityUseHandler(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!isValidHunter(client)) return;

    char ability[32];
    event.GetString("ability", ability, sizeof(ability));
    if (strcmp(ability, "ability_lunge") == 0)
    {
        hunterOnPounce(client);
    }
}

public void roundEndHandler(Event event, const char[] name, bool dontBroadcast)
{
    resetCanLungeTime();
}

// ===== 飞扑起点：决定是否侧飞&修正角度 =====
public void hunterOnPounce(int hunter)
{
    if (!isValidHunter(hunter)) return;

    int lungeEntity = GetEntPropEnt(hunter, Prop_Send, "m_customAbility");

    float selfPos[3], selfEyeAngle[3];
    GetClientAbsOrigin(hunter, selfPos);
    GetClientEyeAngles(hunter, selfEyeAngle);

    // 前方墙体检测（-1 关闭）
    if (CvarFloat(g_hWallDetectDistance, -1.0) > -1.0)
    {
        float start[3], fwd[3], endpos[3];
        start = selfPos;
        start[2] += CROUCH_HEIGHT;

        GetAngleVectors(selfEyeAngle, fwd, NULL_VECTOR, NULL_VECTOR);
        NormalizeVector(fwd, fwd);

        endpos[0] = start[0] + fwd[0] * CvarFloat(g_hWallDetectDistance, 0.0);
        endpos[1] = start[1] + fwd[1] * CvarFloat(g_hWallDetectDistance, 0.0);
        endpos[2] = start[2] + fwd[2] * CvarFloat(g_hWallDetectDistance, 0.0);

        Handle ray = TR_TraceHullFilterEx(start, endpos,
            view_as<float>({-16.0, -16.0, 0.0}),
            view_as<float>({ 16.0,  16.0, 33.0}),
            MASK_NPCSOLID_BRUSHONLY, traceRayFilter, hunter);

        if (TR_DidHit(ray))
        {
            float normal[3]; TR_GetPlaneNormal(ray, normal);
            float ang = RadToDeg(ArcCosine(GetVectorDotProduct(fwd, normal)));
            if (ang > 165.0)
            {
                #if DEBUG
                    float hitpos[3]; TR_GetEndPosition(hitpos, ray); // FIX: 正确打印命中点距离
                    PrintToConsoleAll("[Ai-Hunter] 前方 %.1f 处检测到墙体，改为侧飞", GetVectorDistance(start, hitpos));
                #endif
                delete ray;
                angleLunge(INVALID_CLIENT, INVALID_CLIENT, lungeEntity, GetRandomInt(0, 1) ? LUNGE_LEFT : LUNGE_RIGHT); // FIX: 函数名
                return;
            }
        }
        delete ray;
    }

    int target = hunterCurrentTarget[hunter];
    if (!IsValidSurvivor(target)) return;

    float targetPos[3];
    GetClientAbsOrigin(target, targetPos);

    bool canSide =
        isWatchingBy(hunter, target, CvarFloat(g_hAimOffset, 360.0)) &&
        (GetClientDistance(hunter, target) > g_hStraightPounceDistance.IntValue ||
         FloatAbs(targetPos[2] - selfPos[2]) < CvarFloat(g_hHighPounceHeight, 400.0));

    if (canSide)
    {
        #if DEBUG
            PrintToConsoleAll("[Ai-Hunter] 与目标 %N 距离 %d, 高差 %.1f, 选择侧飞",
                target, GetClientDistance(hunter, target), FloatAbs(targetPos[2] - selfPos[2]));
        #endif

        int angle = xorShiftGetRandomInt( -CvarInt(g_hPounceAngleMean, 10) - CvarInt(g_hPounceAngleStd, 20),
                                           CvarInt(g_hPounceAngleMean, 10) + CvarInt(g_hPounceAngleStd, 20),
                                           CvarInt(g_hPounceAngleStd, 20));

        // 左右平衡限制：若差值超过阈值，翻转方向（FIX: -angle）
        if ( (angle > 0 && (anglePounceCount[hunter][POUNCE_LEFT_IDX]  - anglePounceCount[hunter][POUNCE_RIGHT_IDX]) > g_hAnglePounceCount.IntValue) ||
             (angle < 0 && (anglePounceCount[hunter][POUNCE_RIGHT_IDX] - anglePounceCount[hunter][POUNCE_LEFT_IDX])  > g_hAnglePounceCount.IntValue) )
        {
            angle = -angle; // FIX
        }

        if (angle > 0) anglePounceCount[hunter][POUNCE_LEFT_IDX]++;
        else           anglePounceCount[hunter][POUNCE_RIGHT_IDX]++;

        angleLunge(hunter, target, lungeEntity, float(angle));
        limitLungeVerticality(lungeEntity);

        #if DEBUG
            PrintToConsoleAll("[Ai-Hunter] 最终侧飞角度: %d°", angle);
        #endif
    }
}

// ===== 射线过滤：不穿透自己/玩家/部分实体 =====
stock bool traceRayFilter(int entity, int contentsMask, any data)
{
    if (entity == data || (entity > 0 && entity <= MaxClients))
        return false;

    char className[64];
    GetEntityClassname(entity, className, sizeof(className));
    if (className[0] == 'i' || className[0] == 'p' || className[0] == 't' || className[0] == 'w')
    {
        if (strcmp(className, "infected") == 0 ||
            strcmp(className, "witch") == 0 ||
            strcmp(className, "prop_dynamic") == 0 ||
            strcmp(className, "prop_physics") == 0 ||
            strcmp(className, "tank_rock") == 0)
        {
            return false;
        }
    }
    return true;
}

// ===== 选择目标：若当前不可见，则换最近可见目标 =====
// 注意：你的环境若使用 3 参签名，请改为带 distance 的版本
public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{
    if (!isValidHunter(specialInfected) || !IsValidSurvivor(curTarget) || !IsPlayerAlive(curTarget) || L4D_IsPlayerIncapacitated(curTarget))
        return Plugin_Continue;

    float targetPos[3];
    GetEntPropVector(curTarget, Prop_Send, "m_vecOrigin", targetPos);

    if (!L4D2_IsVisibleToPlayer(specialInfected, TEAM_INFECTED, curTarget, INVALID_NAV_AREA, targetPos))
    {
        int newTarget = getClosestSurvivor(specialInfected);
        if (!IsValidSurvivor(newTarget))
        {
            hunterCurrentTarget[specialInfected] = curTarget;
            return Plugin_Continue;
        }
        hunterCurrentTarget[specialInfected] = newTarget;
        curTarget = newTarget;
        return Plugin_Changed;
    }

    hunterCurrentTarget[specialInfected] = curTarget;
    return Plugin_Continue;
}

// ===== 工具函数 =====
bool isValidHunter(int client)
{
    return (client >= 1 && client <= MaxClients &&
            IsClientInGame(client) &&
            GetClientTeam(client) == TEAM_INFECTED &&
            IsPlayerAlive(client) &&
            GetInfectedClass(client) == ZC_HUNTER &&
            IsFakeClient(client));
}


// 选最近“可见且未被控”的生还者
static int getClosestSurvivor(int client)
{
    if (!isValidHunter(client)) return INVALID_CLIENT;

    float selfPos[3];
    GetClientAbsOrigin(client, selfPos);

    int best = INVALID_CLIENT;
    float bestDist = 999999.0;

    float targetPos[3];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidSurvivor(i)) continue;
        // 若你的环境没有 IsClientPinned，可去掉或替换为你自己的判断
        if (IsClientPinned(i)) continue;

        GetEntPropVector(i, Prop_Send, "m_vecOrigin", targetPos);
        if (!L4D2_IsVisibleToPlayer(client, TEAM_INFECTED, i, INVALID_NAV_AREA, targetPos))
            continue;

        float d = GetVectorDistance(selfPos, targetPos);
        if (d < bestDist)
        {
            bestDist = d;
            best     = i;
        }
    }
    return best;
}

// 目标是否“看着” hunter（仅角度，不做遮挡）
bool isWatchingBy(int hunter, int target, float offset)
{
    if (!isValidHunter(hunter) || !IsValidSurvivor(target) || !IsPlayerAlive(target))
        return false;
    return (getPlayerAimingOffset(hunter, target) <= offset);
}

// 计算目标视线与 hunter 方位的夹角
float getPlayerAimingOffset(int hunter, int target)
{
    float look[3], selfPos[3], targetPos[3];

    GetClientEyeAngles(hunter, look);
    look[0] = look[2] = 0.0;
    GetAngleVectors(look, look, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(look, look);

    GetClientAbsOrigin(hunter, selfPos);
    GetClientAbsOrigin(target, targetPos);
    selfPos[2] = targetPos[2] = 0.0;

    float toSelf[3];
    MakeVectorFromPoints(selfPos, targetPos, toSelf); // 注意方向：用 self->target 或 target->self 皆可，只要一致
    NormalizeVector(toSelf, toSelf);

    return RadToDeg(ArcCosine(GetVectorDotProduct(look, toSelf)));
}

// 限制飞扑的“仰角”，不改变水平向量，只夹 Z 分量（稳定、简单）
void limitLungeVerticality(int ability)
{
    if (!IsValidEntity(ability) || !IsValidEdict(ability)) return;

    float v[3];
    GetEntPropVector(ability, Prop_Send, "m_queuedLunge", v);

    float rad  = DegToRad(CvarFloat(g_hPounceVerticalAngle, 7.0));
    float cx   = Cosine(rad), sx = Sine(rad);
    float tanv = (cx != 0.0) ? (sx / cx) : 9999.0;

    float h    = SquareRoot(v[0]*v[0] + v[1]*v[1]);
    float maxZ = h * tanv;

    if (maxZ > 0.0)
    {
        if (v[2] >  maxZ) v[2] =  maxZ;
        if (v[2] < -maxZ) v[2] = -maxZ;
    }

    SetEntPropVector(ability, Prop_Send, "m_queuedLunge", v);
}

// 增加水平角度；若给定 hunter/target，则先将向量对准目标再旋转
void angleLunge(int hunter, int target, int lungeEntity, float turnAngle)
{
    if (!IsValidEntity(lungeEntity) || !IsValidEdict(lungeEntity)) return;

    float lungeVec[3];
    GetEntPropVector(lungeEntity, Prop_Send, "m_queuedLunge", lungeVec);

    if (isValidHunter(hunter) && IsValidSurvivor(target) && IsPlayerAlive(target))
    {
        float selfPos[3], targetPos[3];
        GetClientAbsOrigin(hunter, selfPos);
        GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPos);
        SubtractVectors(targetPos, selfPos, lungeVec);
        NormalizeVector(lungeVec, lungeVec);
        ScaleVector(lungeVec, CvarFloat(g_hLungePower, 400.0)); // SAFE 默认
    }

    float r = DegToRad(turnAngle);
    float result[3];
    result[0] = lungeVec[0] * Cosine(r) - lungeVec[1] * Sine(r);
    result[1] = lungeVec[0] * Sine(r)   + lungeVec[1] * Cosine(r);
    result[2] = lungeVec[2];

    SetEntPropVector(lungeEntity, Prop_Send, "m_queuedLunge", result);
}

// 改写后的随机函数：避免使用不存在的 Abs，并确保不会除以 0
static int xorShiftGetRandomInt(int min, int max, int std)
{
    if (max < min) return min;

    static int x = 123456789, y = 362436069, z = 521288629, w = 88675123;
    int t = x ^ (x << 11);
    x = y; y = z; z = w;
    w ^= (w >> 19) ^ (t ^ (t >> 8));

    int range = (max - min + 1);
    if (range <= 0) range = 1; // 保险（理论上不会发生）
    int ww = w;
    if (ww < 0) ww = -ww;      // 手动取绝对值，避免 Abs
    int base = min + (ww % range);

    // 50% 概率 +std / -std
    int off = GetRandomInt(0, 1) ? std : -std;
    int val = base + off;

    if (val < min) val = min;
    if (val > max) val = max;
    return val;
}

bool isOnGround(int client)
{
    if (!isValidHunter(client)) return false;
    return GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1;
}

// 解析 meleeFirst 距离范围
void getHunterMeleeFirstRange()
{
    char cvarStr[64];
    g_hMeleeFirst.GetString(cvarStr, sizeof(cvarStr));
    if (IsNullString(cvarStr))
    {
        meleeMinRange = 400.0;
        meleeMaxRange = 1000.0;
        return;
    }

    char tempStr[2][16];
    ExplodeString(cvarStr, ",", tempStr, 2, sizeof(tempStr[]));
    meleeMinRange = StringToFloat(tempStr[0]);
    meleeMaxRange = StringToFloat(tempStr[1]);
}

// 解析“无视野允许飞扑”的高度/距离
void getNoSightPounceRange()
{
    char cvarStr[64];

    g_hNoSightPounceRange.GetString(cvarStr, sizeof(cvarStr));
    if (IsNullString(cvarStr) && g_hNoSightPounceRangeLegacy != null)
        g_hNoSightPounceRangeLegacy.GetString(cvarStr, sizeof(cvarStr)); // 兼容旧名

    if (IsNullString(cvarStr))
    {
        noSightPounceRange  = 300.0;
        noSightPounceHeight = 250.0;
        return;
    }

    char tempStr[2][16];
    ExplodeString(cvarStr, ",", tempStr, 2, sizeof(tempStr[]));
    noSightPounceRange  = StringToFloat(tempStr[0]);
    noSightPounceHeight = StringToFloat(tempStr[1]);
}

bool isVisibleTo(int hunter, int target, float offset) // 保留原 API，内部仍旧仅角度
{
    return isWatchingBy(hunter, target, offset);
}

void resetCanLungeTime()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        canLungeTime[i] = 0.0;
        anglePounceCount[i][POUNCE_LEFT_IDX]  = 0;
        anglePounceCount[i][POUNCE_RIGHT_IDX] = 0;
        hunterCurrentTarget[i] = 0;
        hasQueuedLunge[i] = false;
        canBackVision[i][0] = canBackVision[i][1] = false;
    }
}

// ===== CVar 变动处理 =====
void meleeFirstRangeChangedHandler(ConVar convar, const char[] oldValue, const char[] newValue)
{
    getHunterMeleeFirstRange();
}
void noSightPounceRangeChangedHandler(ConVar convar, const char[] oldValue, const char[] newValue)
{
    getNoSightPounceRange();
}
