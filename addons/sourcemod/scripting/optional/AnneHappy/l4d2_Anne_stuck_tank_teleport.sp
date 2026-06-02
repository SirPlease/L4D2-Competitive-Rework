#pragma semicolon 1
#pragma newdecls required

/**
 * Anne Stuck Tank Teleport System (ASTT) — Door-Threshold & No-Checkpoint
 * 规则：
 *  - 若“目标生还者”与最近的 CHECKPOINT Nav 距离 <= door_threshold → 传“门口”（安全门外）
 *  - 否则 → 传“生还者附近”
 * 两者共同条件：不可见 + 非 CHECKPOINT + Hull 不卡 + Nav 可达 + 与最近生还者保持最小分隔
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <treeutil>
#include <l4d2_saferoom_detect>

// ───────────────────────────────────────────────────────────────────────────────
// 常量 / 宏
// ───────────────────────────────────────────────────────────────────────────────
#define PLUGIN_VERSION          "2.4.1-door-threshold-fixed"
#define TEAM_SURVIVOR           2
#define TEAM_INFECTED           3
#define CVAR_FLAGS              FCVAR_NOTIFY
#define NAV_MESH_HEIGHT         20.0

// 搜点参数
#define TP_BOX_RADIUS           1000.0      // 围绕参考点的最大找点半径（传近点）
#define TP_MINDIST_SEP          400.0       // 候选点与最近生还者最小分隔
#define TP_ATTEMPTS             48          // 近点随机尝试次数上限
#define TP_VISIBLE_NEAR         400.0       // 小于此距离视为“太近/可见”
static float HULL_MIN[3] = {-16.0, -16.0, 0.0};
static float HULL_MAX[3] = { 16.0,  16.0, 72.0};

// “门口”采样参数
#define DOOR_SEARCH_RADIUS      2000.0      // 在生还附近搜索最近 CHECKPOINT 的半径上限
#define DOOR_RING_START         60.0        // 从 CHECKPOINT 中心向外的起始半径（门口“外沿”）
#define DOOR_RING_END           600.0       // 外沿最大半径
#define DOOR_RING_STEP          40.0        // 外沿采样步长
#define DOOR_ANG_STEPS          24          // 每一圈的角度采样次数

#define TANK_CLAW_RANGE         100.0       // “附近有倒地人就别传”的保护圈

// ── 调试打印（函数版，避免宏 ... 不被 Pawn 支持）
bool g_bDebug = false;
stock void DBG(const char[] fmt, any ...)
{
    if (!g_bDebug) return;
    static char buffer[256];
    VFormat(buffer, sizeof(buffer), fmt, 2);
    PrintToServer("%s", buffer);
}

// ───────────────────────────────────────────────────────────────────────────────
// 插件信息
// ───────────────────────────────────────────────────────────────────────────────
public Plugin myinfo =
{
    name        = "Anne Stuck Tank Teleport System (ASTT)",
    author      = "东, re-arch by ChatGPT",
    description = "Tank卡住/跑男：按门口阈值决定传门口或传近点（均排除 CHECKPOINT）",
    version     = PLUGIN_VERSION,
    url         = "https://github.com/fantasylidong/CompetitiveWithAnne"
};

// ───────────────────────────────────────────────────────────────────────────────
// CVar
// ───────────────────────────────────────────────────────────────────────────────
ConVar g_hEnable;
ConVar g_hCheckInterval;
ConVar g_hNonStuckRadius;

ConVar g_hRusherPunish;
ConVar g_hRusherDist;
ConVar g_hRusherCheckTimes;
ConVar g_hRusherCheckInterv;
ConVar g_hRusherMinPlayers;

ConVar g_hBlockCheckpoint;      // 禁止传送到 CHECKPOINT（默认 1）
ConVar g_hDoorThreshold;        // 生还者—安全门距离阈值（默认 1000）
ConVar g_hDebug;                // 调试

// ───────────────────────────────────────────────────────────────────────────────
// 运行时状态
// ───────────────────────────────────────────────────────────────────────────────
Handle g_hTimerRusher = null;

float  g_LastPos[MAXPLAYERS+1][3];
int    g_iRushTimes[MAXPLAYERS+1];
int    g_iStuckTimes[MAXPLAYERS+1];
int    g_iTanksCount;

bool   g_bEnabled = true;
bool   g_bSuccessTeleport = true;

// ───────────────────────────────────────────────────────────────────────────────
// 生命周期
// ───────────────────────────────────────────────────────────────────────────────
public void OnPluginStart()
{
    CreateConVar("l4d2_Anne_stuck_tank_teleport", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD);

    g_hEnable          = CreateConVar("l4d2_astt_enable",                   "1",   "Enable plugin (1/0)", CVAR_FLAGS);
    g_hCheckInterval   = CreateConVar("l4d2_astt_stuck_check_interval",     "3",   "Tank stuck check interval (sec)", CVAR_FLAGS);
    g_hNonStuckRadius  = CreateConVar("l4d2_astt_non_stuck_radius",        "20",   "Movement < this within interval counts as stuck", CVAR_FLAGS);

    g_hRusherPunish        = CreateConVar("l4d2_astt_rusher_punish",       "1",   "Punish rusher by teleporting tank (1/0)", CVAR_FLAGS);
    g_hRusherDist          = CreateConVar("l4d2_astt_rusher_dist",      "2800",   "Distance to nearest tank considered as rusher", CVAR_FLAGS);
    g_hRusherCheckTimes    = CreateConVar("l4d2_astt_rusher_checks",       "6",   "Checks before confirming rusher", CVAR_FLAGS);
    g_hRusherCheckInterv   = CreateConVar("l4d2_astt_rusher_interval",     "3",   "Rusher check interval (sec)", CVAR_FLAGS);
    g_hRusherMinPlayers    = CreateConVar("l4d2_astt_rusher_minplayers",   "2",   "Min alive survivors to enable rusher rule", CVAR_FLAGS);

    g_hBlockCheckpoint     = CreateConVar("l4d2_astt_block_checkpoint",     "1",  "Disallow teleporting into CHECKPOINT nav (1/0)", CVAR_FLAGS);
    g_hDoorThreshold       = CreateConVar("l4d2_astt_door_threshold",    "1000",  "If survivor↔saferoom distance <= this, teleport to DOOR; else NEAR (units)", CVAR_FLAGS);
    g_hDebug               = CreateConVar("l4d2_astt_debug",                "0",  "Debug prints (1/0)", CVAR_FLAGS);

    HookConVarChange(g_hEnable,          CvarChanged);
    HookConVarChange(g_hBlockCheckpoint, CvarChanged);
    HookConVarChange(g_hDoorThreshold,   CvarChanged);
    HookConVarChange(g_hDebug,           CvarChanged);

    g_bEnabled = g_hEnable.BoolValue;
    g_bDebug   = g_hDebug.BoolValue;

    HookEvent("tank_spawn",      Event_TankSpawn,      EventHookMode_Post);
    HookEvent("player_death",    Event_PlayerDeath,    EventHookMode_Pre);
    HookEvent("round_start",     Event_RoundStart,     EventHookMode_PostNoCopy);
    HookEvent("round_end",       Event_RoundEnd,       EventHookMode_PostNoCopy);
    HookEvent("finale_win",      Event_RoundEnd,       EventHookMode_PostNoCopy);
    HookEvent("mission_lost",    Event_RoundEnd,       EventHookMode_PostNoCopy);
    HookEvent("map_transition",  Event_RoundEnd,       EventHookMode_PostNoCopy);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsTank(i))
            BeginTankTracing(i);
    }
}

public void OnMapStart()
{
    g_hTimerRusher = null;
    g_iTanksCount = 0;
    g_bSuccessTeleport = true;

    for (int i = 1; i <= MaxClients; i++)
    {
        g_iRushTimes[i] = 0;
        g_iStuckTimes[i] = 0;
        g_LastPos[i][0] = g_LastPos[i][1] = g_LastPos[i][2] = 0.0;
    }
}

public void OnMapEnd()
{
    g_iTanksCount = 0;
}

public void CvarChanged(ConVar convar, const char[] ov, const char[] nv)
{
    g_bEnabled = g_hEnable.BoolValue;
    g_bDebug   = g_hDebug.BoolValue;

    if (g_hTimerRusher != null && !g_hRusherPunish.BoolValue)
    {
        delete g_hTimerRusher;
        g_hTimerRusher = null;
    }
}

// ───────────────────────────────────────────────────────────────────────────────
// 事件
// ───────────────────────────────────────────────────────────────────────────────
public void Event_TankSpawn(Event e, const char[] name, bool dontBroadcast)
{
    if (!g_bEnabled) return;

    int tank = GetClientOfUserId(e.GetInt("userid"));
    if (tank > 0)
    {
        BeginTankTracing(tank);
        BeginRusherTracing(true);
    }
}

public void Event_PlayerDeath(Event e, const char[] name, bool dontBroadcast)
{
    if (!g_bEnabled) return;

    int client = GetClientOfUserId(e.GetInt("userid"));
    if (client <= 0) return;

    if (IsTank(client))
    {
        CreateTimer(1.0, Timer_UpdateTankCount, _, TIMER_FLAG_NO_MAPCHANGE);
    }
    else if (GetClientTeam(client) == TEAM_SURVIVOR)
    {
        ResetSurvivorRuntime(client);
    }

    g_bSuccessTeleport = true;
}

public Action Event_RoundStart(Event e, const char[] name, bool dontBroadcast) { return Plugin_Continue; }
public Action Event_RoundEnd  (Event e, const char[] name, bool dontBroadcast) { return Plugin_Continue; }
public void   Event_PlayerDisconnect(Event e, const char[] name, bool dontBroadcast)
{
    ResetSurvivorRuntime(GetClientOfUserId(e.GetInt("userid")));
}

public Action Timer_UpdateTankCount(Handle timer)
{
    UpdateTankCount();
    return Plugin_Continue;
}

static void UpdateTankCount()
{
    int cnt = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsTank(i)) cnt++;

    g_iTanksCount = cnt;

    if (cnt == 0 && g_hTimerRusher != null)
    {
        delete g_hTimerRusher;
        g_hTimerRusher = null;
    }
}

// ───────────────────────────────────────────────────────────────────────────────
// 定时器：卡住 / 跑男
// ───────────────────────────────────────────────────────────────────────────────
static void BeginTankTracing(int tank)
{
    g_iStuckTimes[tank] = 0;
    GetClientAbsOrigin(tank, g_LastPos[tank]);
    CreateTimer(g_hCheckInterval.FloatValue, Timer_CheckPos, GetClientUserId(tank), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

static void BeginRusherTracing(bool reset = true)
{
    if (!g_hRusherPunish.BoolValue) return;

    if (reset)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && !IsFakeClient(i))
            {
                GetClientAbsOrigin(i, g_LastPos[i]);
                g_iRushTimes[i] = 0;
            }
        }
    }

    if (g_hTimerRusher == null)
        g_hTimerRusher = CreateTimer(g_hRusherCheckInterv.FloatValue, Timer_CheckRusher, _, TIMER_REPEAT);
}

public Action Timer_CheckPos(Handle timer, int userid)
{
    if (!g_bEnabled) return Plugin_Stop;

    int tank = GetClientOfUserId(userid);
    if (tank <= 0 || !IsClientInGame(tank) || !IsPlayerAlive(tank) || !IsTank(tank))
        return Plugin_Stop;

    float pos[3];
    GetClientAbsOrigin(tank, pos);

    float moved = GetVectorDistance(pos, g_LastPos[tank], false);
    DBG("ASTT: Tank moved = %.1f", moved);

    if (moved < g_hNonStuckRadius.FloatValue && !IsPointHasIncappedNearby(pos) && !IsTankAttacking(tank))
    {
        if (g_iStuckTimes[tank] > 6 && g_bSuccessTeleport)
        {
            SDKHook(tank, SDKHook_PostThinkPost, SDK_UpdateThink_Stuck);
            g_bSuccessTeleport = false;
        }
        g_iStuckTimes[tank]++;
    }
    else
    {
        g_iStuckTimes[tank] = 0;
    }

    g_LastPos[tank] = pos;
    return Plugin_Continue;
}

public void SDK_UpdateThink_Stuck(int tank)
{
    SDKUnhook(tank, SDKHook_PostThinkPost, SDK_UpdateThink_Stuck);
    TeleportTankStuck(tank);
}

public Action Timer_CheckRusher(Handle timer)
{
    if (!g_bEnabled) return Plugin_Stop;

    if (g_iTanksCount == 0)
        return Plugin_Stop;

    if (L4D_IsMissionFinalMap())
        return Plugin_Continue; // 救援关不惩罚

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || !IsPlayerAlive(i) || IsFakeClient(i))
            continue;

        if (IsPinned(i) || IsIncapped(i))
            continue;

        if (GetSurvivorCountAlive() < g_hRusherMinPlayers.IntValue)
            continue;

        int tank = GetNearestTankTo(i);
        if (tank == 0) continue;

        float spos[3], tpos[3];
        GetClientAbsOrigin(i,   spos);
        GetClientAbsOrigin(tank, tpos);

        float dist = GetVectorDistance(spos, tpos, false);

        float flowTank = L4D2Direct_GetFlowDistance(tank);
        float flowSur  = L4D2Direct_GetFlowDistance(i);

        if (flowTank == 0.0 || flowSur == 0.0 || flowTank >= flowSur)
        {
            g_iRushTimes[i] = 0;
            continue;
        }

        if (dist > g_hRusherDist.FloatValue)
        {
            g_iRushTimes[i]++;
            if (g_iRushTimes[i] >= g_hRusherCheckTimes.IntValue)
            {
                bool ok = TeleportNearOrDoor_ByThreshold(tank, i);
                if (ok)
                    PrintToChatAll("\x03%N \x04 跑太快，按门口阈值传送 Tank。", i);
                g_iRushTimes[i] = 0;
            }
        }
        else
        {
            g_iRushTimes[i] = 0;
        }
    }

    return Plugin_Continue;
}

// ───────────────────────────────────────────────────────────────────────────────
// 传送实现（门口阈值逻辑）
// ───────────────────────────────────────────────────────────────────────────────
static void TeleportTankStuck(int tank)
{
    if (!IsClientInGame(tank) || !IsPlayerAlive(tank) || !IsTank(tank))
    {
        g_bSuccessTeleport = true;
        return;
    }

    int target = GetClosestMobileSurvivorTo(tank);
    if (!IsValidSurvivor(target))
    {
        g_bSuccessTeleport = true;
        return;
    }

    bool ok = TeleportNearOrDoor_ByThreshold(tank, target);
    if (ok)
        PrintHintTextToAll("注意：Tank 卡住，按门口阈值传送（非安全门）。");

    g_bSuccessTeleport = true;
}

/**
 * 根据“生还者与安全门距离”决定传“门口”或“近点”
 * 返回 true 表示传送成功
 */
static bool TeleportNearOrDoor_ByThreshold(int tank, int survivor)
{
    float sPos[3]; GetClientAbsOrigin(survivor, sPos);

    // 找最近 CHECKPOINT（安全门）参考点
    float doorPos[3], doorDist = 0.0;
    bool hasDoor = FindNearestCheckpointPos(sPos, DOOR_SEARCH_RADIUS, doorPos, doorDist);

    float spawn[3];
    bool ok = false;

    if (hasDoor && doorDist <= g_hDoorThreshold.FloatValue)
    {
        // 近门：找“门口外沿”的落点
        if (FindDoorstepOutsideCheckpointNear(doorPos, spawn))
            ok = true;
        else
            DBG("ASTT: Doorstep search failed, fallback to NEAR.");
    }

    // 不满足“门口”条件或找不到门口 → 传近点
    if (!ok)
        ok = FindHiddenTeleportSpotNear(sPos, TP_BOX_RADIUS, spawn);

    if (!ok) return false;

    TeleportEntity(tank, spawn, NULL_VECTOR, NULL_VECTOR);

    #if defined COMMANDABOT_RESET
        int newtarget = GetClosestMobileSurvivorTo(tank);
        if (IsValidSurvivor(newtarget))
        {
            Logic_RunScript(COMMANDABOT_RESET,  GetClientUserId(tank), GetClientUserId(newtarget));
            Logic_RunScript(COMMANDABOT_ATTACK, GetClientUserId(tank), GetClientUserId(newtarget));
        }
    #endif

    return true;
}

// ───────────────────────────────────────────────────────────────────────────────
// 落点搜索：近点（非 CHECKPOINT）
// ───────────────────────────────────────────────────────────────────────────────
static bool FindHiddenTeleportSpotNear(const float around[3], float maxRadius, float outPos[3])
{
    float mins[3], maxs[3], tryPos[3], endPos[3];
    mins[0] = around[0] - maxRadius;
    mins[1] = around[1] - maxRadius;
    mins[2] = around[2];
    maxs[0] = around[0] + maxRadius;
    maxs[1] = around[1] + maxRadius;
    maxs[2] = around[2] + maxRadius;

    float down[3] = {90.0, 0.0, 0.0};

    for (int n = 0; n < TP_ATTEMPTS; n++)
    {
        tryPos[0] = GetRandomFloat(mins[0], maxs[0]);
        tryPos[1] = GetRandomFloat(mins[1], maxs[1]);
        tryPos[2] = GetRandomFloat(around[2], maxs[2]);

        TR_TraceRay(tryPos, down, MASK_SOLID, RayType_Infinite);
        if (TR_DidHit())
        {
            TR_GetEndPosition(endPos);
            tryPos[0] = endPos[0];
            tryPos[1] = endPos[1];
            tryPos[2] = endPos[2] + NAV_MESH_HEIGHT;
        }

        if (!IsOnValidMesh_NoCheckpoint(tryPos))
            continue;

        if (IsPointVisibleToAnySurvivor(tryPos, true))
            continue;

        if (IsHullStuck(tryPos))
            continue;

        // 与最近生还者分隔 + 可达
        int nearSur = 0; float nearDist = 9999999.0, s[3];
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsValidSurvivor(i)) continue;
            GetClientEyePosition(i, s);
            float d = GetVectorDistance(tryPos, s, false);
            if (d < nearDist) { nearDist = d; nearSur = i; }
        }
        if (nearSur == 0) continue;
        if (nearDist < TP_MINDIST_SEP) continue;

        s[2] -= 60.0;
        if (!NavPathReachable_Infected(tryPos, s, TP_BOX_RADIUS * 1.73))
            continue;

        outPos[0] = tryPos[0];
        outPos[1] = tryPos[1];
        outPos[2] = tryPos[2];
        return true;
    }
    return false;
}

// ───────────────────────────────────────────────────────────────────────────────
// 落点搜索：门口（CHECKPOINT 外沿的非 CHECKPOINT 区域）
// ───────────────────────────────────────────────────────────────────────────────
static bool FindNearestCheckpointPos(const float from[3], float searchRadius, float outPos[3], float &outDist)
{
    float down[3] = {90.0, 0.0, 0.0};
    float bestPos[3] = {0.0, 0.0, 0.0};
    float bestDist = 9999999.0;

    // 近→远分圈采样
    static float rings[6] = {200.0, 400.0, 800.0, 1200.0, 1600.0, 2000.0};
    for (int r = 0; r < 6; r++)
    {
        if (rings[r] > searchRadius) break;

        for (int k = 0; k < DOOR_ANG_STEPS; k++)
        {
            float ang = float(k) * (360.0 / float(DOOR_ANG_STEPS));

            float a[3]; a[0] = 0.0; a[1] = ang; a[2] = 0.0;
            float dir[3];
            GetAngleVectors(a, dir, NULL_VECTOR, NULL_VECTOR);

            float probe[3];
            probe[0] = from[0] + dir[0] * rings[r];
            probe[1] = from[1] + dir[1] * rings[r];
            probe[2] = from[2] + 200.0;

            TR_TraceRay(probe, down, MASK_SOLID, RayType_Infinite);
            if (!TR_DidHit()) continue;

            float hit[3];
            TR_GetEndPosition(hit);

            Address area = L4D2Direct_GetTerrorNavArea(hit);
            if (area == Address_Null) continue;

            int attrs = L4D_GetNavArea_SpawnAttributes(area);
            if (!(attrs & CHECKPOINT)) continue; // 仅考虑 CHECKPOINT

            float d = GetVectorDistance(from, hit, false);
            if (d < bestDist)
            {
                bestDist = d;
                bestPos[0] = hit[0];
                bestPos[1] = hit[1];
                bestPos[2] = hit[2];
            }
        }
    }

    if (bestDist < 9999999.0)
    {
        outPos[0] = bestPos[0];
        outPos[1] = bestPos[1];
        outPos[2] = bestPos[2];
        outDist   = bestDist;
        return true;
    }
    return false;
}

static bool FindDoorstepOutsideCheckpointNear(const float checkpointPos[3], float outPos[3])
{
    float down[3] = {90.0, 0.0, 0.0};

    for (float radius = DOOR_RING_START; radius <= DOOR_RING_END; radius += DOOR_RING_STEP)
    {
        for (int k = 0; k < DOOR_ANG_STEPS; k++)
        {
            float ang = float(k) * (360.0 / float(DOOR_ANG_STEPS));

            float a[3]; a[0] = 0.0; a[1] = ang; a[2] = 0.0;
            float dir[3];
            GetAngleVectors(a, dir, NULL_VECTOR, NULL_VECTOR);

            float probe[3];
            probe[0] = checkpointPos[0] + dir[0] * radius;
            probe[1] = checkpointPos[1] + dir[1] * radius;
            probe[2] = checkpointPos[2] + 200.0;

            TR_TraceRay(probe, down, MASK_SOLID, RayType_Infinite);
            if (!TR_DidHit()) continue;

            float hit[3];
            TR_GetEndPosition(hit);
            hit[2] += NAV_MESH_HEIGHT;

            if (!IsOnValidMesh_NoCheckpoint(hit))
                continue;

            if (IsPointVisibleToAnySurvivor(hit, true))
                continue;

            if (IsHullStuck(hit))
                continue;

            int nearSur = 0; float nearDist = 9999999.0, s[3];
            for (int i = 1; i <= MaxClients; i++)
            {
                if (!IsValidSurvivor(i)) continue;
                GetClientEyePosition(i, s);
                float d = GetVectorDistance(hit, s, false);
                if (d < nearDist) { nearDist = d; nearSur = i; }
            }
            if (nearSur == 0) continue;
            if (nearDist < TP_MINDIST_SEP) continue;

            s[2] -= 60.0;
            if (!NavPathReachable_Infected(hit, s, DOOR_RING_END * 2.0))
                continue;

            outPos[0] = hit[0];
            outPos[1] = hit[1];
            outPos[2] = hit[2];
            return true;
        }
    }
    return false;
}

// ───────────────────────────────────────────────────────────────────────────────
// 可见性 / 地形
// ───────────────────────────────────────────────────────────────────────────────
static bool IsPointVisibleToAnySurvivor(const float pos[3], bool treatNearAsVisible = true)
{
    float eye[3];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidSurvivor(i)) continue;

        GetClientEyePosition(i, eye);

        if (treatNearAsVisible && GetVectorDistance(pos, eye, false) < TP_VISIBLE_NEAR)
            return true;

        if (RayVisibleTo(i, pos))
            return true;

        float head[3];
		head = pos;
		head[2] += 62.0;
        if (RayVisibleTo(i, head))
            return true;
    }

    return false;
}

static bool RayVisibleTo(int client, const float target[3])
{
    float eye[3], dir[3], ang[3];
    GetClientEyePosition(client, eye);

    MakeVectorFromPoints(target, eye, dir);
    GetVectorAngles(dir, ang);

    Handle tr = TR_TraceRayFilterEx(target, ang, MASK_VISIBLE, RayType_Infinite,
                                    TR_FilterSkipPlayers, client);
    bool vis = false;

    if (TR_DidHit(tr))
    {
        float hit[3];
        TR_GetEndPosition(hit, tr);
        if ((GetVectorDistance(target, hit, false) + 75.0) >= GetVectorDistance(eye, target))
            vis = true;
    }
    else
    {
        vis = true;
    }

    delete tr;
    return vis;
}

public bool TR_FilterSkipPlayers(int entity, int contentsMask, any data)
{
    if (entity == data) return false;
    if (entity >= 1 && entity <= MaxClients) return false;
    return true;
}

static bool IsOnValidMesh_NoCheckpoint(float where[3])
{
    Address area = L4D2Direct_GetTerrorNavArea(where);
    if (area == Address_Null) return false;

    if (g_hBlockCheckpoint.BoolValue)
    {
        int attrs = L4D_GetNavArea_SpawnAttributes(area);
        if (attrs & CHECKPOINT)
            return false;
    }
    return true;
}

static bool IsHullStuck(const float at[3])
{
    Handle tr = TR_TraceHullFilterEx(at, at, HULL_MIN, HULL_MAX, MASK_PLAYERSOLID, TR_FilterForHull, 0);
    bool hit = TR_DidHit(tr);
    delete tr;
    return hit;
}

public bool TR_FilterForHull(int entity, int contentsMask, any data)
{
    if (entity <= MaxClients || !IsValidEntity(entity))
        return false;

    static char cls[32];
    GetEntityClassname(entity, cls, sizeof cls);

    // 忽略仅拦 AI 的 blocker（避免把“反AI区块”当实体撞上）
    if (StrEqual(cls, "env_physics_blocker"))
    {
        int t = GetEntProp(entity, Prop_Data, "m_nBlockType");
        if (t == 1 || t == 2) // block infected / infected+physics
            return false;
    }
    return true;
}

static bool NavPathReachable_Infected(const float from[3], const float to[3], float maxDist)
{
    Address a = L4D_GetNearestNavArea(from, 120.0, false, false, false, TEAM_INFECTED);
    Address b = L4D_GetNearestNavArea(to,   120.0, false, false, false, TEAM_INFECTED);
    if (a == Address_Null || b == Address_Null) return false;
    if (a == b) return true;
    return L4D2_NavAreaBuildPath(a, b, maxDist, TEAM_INFECTED, false);
}

// ───────────────────────────────────────────────────────────────────────────────
// 便捷 / 状态
// ───────────────────────────────────────────────────────────────────────────────
static bool IsTankAttacking(int tank)
{
    return GetEntProp(tank, Prop_Send, "m_fireLayerSequence") > 0;
}

static bool IsPointHasIncappedNearby(const float origin[3])
{
    float p[3];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidSurvivor(i) && IsIncapped(i))
        {
            GetClientAbsOrigin(i, p);
            if (GetVectorDistance(p, origin, false) <= TANK_CLAW_RANGE)
                return true;
        }
    }
    return false;
}

static bool IsTank(int client)
{
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client)) return false;
    if (GetClientTeam(client) != TEAM_INFECTED) return false;
    return (GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

static bool IsIncapped(int client)
{
    return GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 1;
}

static bool IsPinned(int client)
{
    return L4D_IsPlayerPinned(client);
}

static int GetSurvivorCountAlive()
{
    int c = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsValidSurvivor(i)) c++;
    return c;
}

static void ResetSurvivorRuntime(int client)
{
    g_LastPos[client][0] = g_LastPos[client][1] = g_LastPos[client][2] = 0.0;
    g_iRushTimes[client] = 0;
}

static int GetNearestTankTo(int client)
{
    if (!IsClientInGame(client)) return 0;

    float me[3], pos[3];
    GetClientAbsOrigin(client, me);

    float mind = 9999999.0;
    int ret = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsTank(i)) continue;
        GetClientAbsOrigin(i, pos);
        float d = GetVectorDistance(me, pos, false);
        if (d < mind) { mind = d; ret = i; }
    }
    return ret;
}

static int GetClosestMobileSurvivorTo(int tank)
{
    float tpos[3], spos[3];
    GetClientAbsOrigin(tank, tpos);

    float mind = 9999999.0;
    int ret = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidSurvivor(i)) continue;
        if (IsPinned(i) || IsIncapped(i)) continue;

        GetClientAbsOrigin(i, spos);
        float d = GetVectorDistance(tpos, spos, false);
        if (d < mind) { mind = d; ret = i; }
    }
    return ret;
}
