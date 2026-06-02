#pragma semicolon 1
#pragma newdecls required

/**
 * Infected Control (fdxx-style NavArea spot picking + max-distance fallback + 动态FLOW分桶)
 *
 * ── 模块地图（Modules）
 *  1. 头文件 & 常量/宏
 *  2. 数据结构：Config / State / Queues / 全局缓存（NavAreas/FlowBuckets/冷却/路径缓存…）
 *  3. 插件生命周期：OnPluginStart/OnPluginEnd/Map & Round 事件
 *  4. CVar 管理：Config::Create / Refresh / 变更回调
 *  5. 运行时时序：
 *     - 帧驱动 OnGameFrame → 队列维护 → 常规刷新尝试
 *     - 传送监督定时器 Timer_TeleportTick（1s）
 *     - Spawn 波控制：StartWave/Timer_CheckSpawnWindow/Timer_StartNewWave
 *  6. 选类与队列：稀缺度优先、死亡CD与双保险、上限闸门
 *  7. 刷点核心（NavArea主路）：距离/可视/卡壳/路径/分散度/Flow 评分与 First-Fit
 *  8. Nav 分桶与缓存：BuildNavBuckets / KV 读写 / 桶窗口序列（含本文件补完的 BuildBucketOrder）
 *  9. Flow 与 Survivor 进度：安全获取、回退 TTL、每秒刷新“最后一次有效团队进度”
 * 10. 跑男检测与目标生还者选择
 * 11. 工具函数：可视/线段/碰撞/冷却/扇区/日志
 *
 * ── 行为要点（Behavior）
 *  - 预建 Nav Flow 分桶（0..100%），刷点时仅在“目标生还者附近 ±N 桶”内扫描
 *  - 扩圈 SpawnMin→SpawnMax；到达上限走导演兜底
 *  - 评分四因子：距离 / 高度偏好 / Flow / 分散度（可调权重）
 *  - badflow 仅作轻度扣分（不强制禁用），支持空间映射就近归桶
 *  - 传送监督：出生宽限、跑男快通道（但≥0.8s）、Smoker 技能未就绪不传
 *  - 生还者进度“本地回退”：所有人统计失败时，短期采用“最后一次有效平均进度”
 *
 * Compatible with SM 1.10+ / L4D2 / left4dhooks
 * Authors: 东, Caibiii, 夜羽真白 , Paimon-Kawaii, fdxx (思路), merge & cleanup by ChatGPT
 */

#include <sourcemod>
#include <sdktools>
#include <sdktools_tempents>
#include <left4dhooks>
#include <sourcescramble>
#undef REQUIRE_PLUGIN
#include <si_target_limit>  // 可选
#include <pause>            // 可选

// =========================
// 常量/宏
// =========================
#define CVAR_FLAG                 FCVAR_NOTIFY
#define TEAM_SURVIVOR             2
#define TEAM_INFECTED             3
#define NAV_MESH_HEIGHT           20.0
#define PLAYER_CHEST              45.0

#define BAIT_DISTANCE             200.0
#define RING_SLACK                350.0
#define SUPPORT_EXPAND_MAX        1200.0

// 扩圈节奏
#define LOW_SCORE_EXPAND          100.0

#define ENABLE_SMOKER             (1 << 0)
#define ENABLE_BOOMER             (1 << 1)
#define ENABLE_HUNTER             (1 << 2)
#define ENABLE_SPITTER            (1 << 3)
#define ENABLE_JOCKEY             (1 << 4)
#define ENABLE_CHARGER            (1 << 5)

#define SPIT_INTERVAL             2.0
#define RUSH_MAN_DISTANCE         1200.0

#define FRAME_THINK_STEP          0.02

// Support SI gating
#define SUPPORT_SPAWN_DELAY_SECS  1.0
#define SUPPORT_NEED_KILLERS      1

// —— 分散度四件套参数 —— //
#define PI                        3.1415926535
#define SEP_TTL                   3.0    // 最近刷点保留秒数
//#define SEP_MAX                   20     // 记录上限（防止无限增长）
// === Dispersion tuning (lighter penalties) ===
#define SEP_RADIUS                80.0
#define NAV_CD_SECS               0.5
#define SECTORS_BASE              6       // 基准
#define SECTORS_MAX               8       // 动态上限（建议 6~8 之间）
#define DYN_SECTORS_MIN           3       // 动态下限
// 可调参数（想热调也能做成 CVar，这里先给常量）
#define PEN_LIMIT_SCALE_HI        1.00   // L=1 时：正向惩罚略强一点
#define PEN_LIMIT_SCALE_LO        0.50   // L=20 时：正向惩罚明显减弱
#define PEN_LIMIT_MINL            1
#define PEN_LIMIT_MAXL            16

// [新增] —— PathPenalty_NoBuild 结果缓存（key -> result / expire）
static StringMap g_PathCacheRes = null;  // key -> int(0/1)

#define PATH_NO_BUILD_PENALTY     1999.0

// === Dispersion tuning (penalties at BASE=4) ===
#define SECTOR_PREF_BONUS_BASE   -8.0
#define SECTOR_OFF_PENALTY_BASE   4.0
#define RECENT_PENALTY_0_BASE     3.6
#define RECENT_PENALTY_1_BASE     2.4
#define RECENT_PENALTY_2_BASE     2.0

// Nav Flow 分桶
#define FLOW_BUCKETS              101     // 0..100
#define BUCKET_CACHE_VER "2025.10.26"  // 和插件版号保持同步

// 记录最近使用过的 navArea -> 过期时间
StringMap g_NavCooldown;

static const char INFDN[10][] =
{
    "common","smoker","boomer","hunter","spitter","jockey","charger","witch","tank","survivor"
};
// ✅ 添加：NavAreas 全局缓存
static ArrayList g_AllNavAreasCache = null;
static int g_NavAreasCacheCount = 0;
// —— Nav 高度“核心”缓存 & 每桶高度范围 —— //
static ArrayList g_AreaZCore = null;   // float per areaIdx（核心高度=多次随机点的 z 均值）
static ArrayList g_AreaZMin  = null;   // float per areaIdx
static ArrayList g_AreaZMax  = null;   // float per areaIdx
static float g_BucketMinZ[FLOW_BUCKETS];
static float g_BucketMaxZ[FLOW_BUCKETS];
static float g_LastSpawnTime[MAXPLAYERS+1];

static StringMap g_NavIdToIndex = null;  // navid -> areaIdx
static char g_sBucketCachePath[PLATFORM_MAX_PATH] = "";
// —— 生还者进度回退（最后一次成功统计） —— //
static int   g_LastGoodSurPct     = -1;   // 0..100
static float g_LastGoodSurPctTime = 0.0;  // game time

// =========================
// 修改 TheNavAreas methodmap
// =========================
methodmap TheNavAreas
{
    // 使用 left4dhooks 的 L4D_GetAllNavAreas 替代
    public int Count()
    {
        EnsureNavAreasCache();  // ✅ 确保缓存存在
        return g_NavAreasCacheCount;
    }
    
    public Address GetAreaByIndex(int i)
    {
        EnsureNavAreasCache();  // ✅ 确保缓存存在
        if (i < 0 || i >= g_NavAreasCacheCount)
            return Address_Null;
        return g_AllNavAreasCache.Get(i);
    }
}
// =========================
// 修改 NavArea methodmap
// =========================
methodmap NavArea
{
    public bool IsNull()
    {
        return view_as<Address>(this) == Address_Null;
    }

    // ✅ 使用 L4D_FindRandomSpot 替代 SDK call
    public void GetRandomPoint(float outPos[3])
    {
        L4D_FindRandomSpot(view_as<int>(this), outPos);
    }

    // ✅ 使用 L4D_GetNavArea_SpawnAttributes 替代 offset
    property int SpawnAttributes
    {
        public get()
        {
            return L4D_GetNavArea_SpawnAttributes(view_as<Address>(this));
        }
        public set(int v)
        {
            L4D_SetNavArea_SpawnAttributes(view_as<Address>(this), v);
        }
    }

    // ✅ 使用 L4D2Direct_GetTerrorNavAreaFlow 替代 offset
    public float GetFlow()
    {
        return L4D2Direct_GetTerrorNavAreaFlow(view_as<Address>(this));
    }
}

// Nav flags（参考 wiki / fdxx）
enum
{
    TERROR_NAV_EMPTY                = 1 << 1,
    TERROR_NAV_STOP_SCAN            = 1 << 2,
    TERROR_NAV_BATTLESTATION        = 1 << 5,
    TERROR_NAV_FINALE               = 1 << 6,
    TERROR_NAV_PLAYER_START         = 1 << 7,
    TERROR_NAV_BATTLEFIELD          = 1 << 8,
    TERROR_NAV_IGNORE_VISIBILITY    = 1 << 9,
    TERROR_NAV_NOT_CLEARABLE        = 1 << 10,
    TERROR_NAV_CHECKPOINT           = 1 << 11,
    TERROR_NAV_OBSCURED             = 1 << 12,
    TERROR_NAV_NO_MOBS              = 1 << 13,
    TERROR_NAV_THREAT               = 1 << 14,
    TERROR_NAV_RESCUE_VEHICLE       = 1 << 15,
    TERROR_NAV_RESCUE_CLOSET        = 1 << 16,
    TERROR_NAV_ESCAPE_ROUTE         = 1 << 17,
    TERROR_NAV_DOOR                 = 1 << 18,
    TERROR_NAV_NOTHREAT             = 1 << 19
}

// [ADD] 单次最终入选刷点的评分快照（只打印最终点）
enum struct SpawnScoreDbg
{
    float total;
    float dist;
    float hght;
    float flow;
    float dispRaw;
    float dispScaled;
    float penK;

    float dminEye;
    float ringEff;
    float slack;

    int candBucket;
    int centerBucket;
    int deltaFlow;
    int sector;
    int areaIdx;

    float pos[3];
}


// =========================
// 枚举/结构
// =========================
enum SIClass
{
    SI_None    = 0,
    SI_Smoker  = 1,
    SI_Boomer  = 2,
    SI_Hunter  = 3,
    SI_Spitter = 4,
    SI_Jockey  = 5,
    SI_Charger = 6
};

enum struct Config
{
    ConVar SpawnMin;
    ConVar SpawnMax;
    ConVar TeleportEnable;
    ConVar TeleportSpawnMin;
    ConVar TeleportCheckTime;
    ConVar EnableMask;
    ConVar AllCharger;
    ConVar AllHunter;
    ConVar AutoSpawnTime;
    ConVar IgnoreIncapSight;
    ConVar AddDmgSmoker;
    ConVar SiLimit;
    ConVar SiInterval;
    ConVar DebugMode;

    ConVar MaxPlayerZombies;
    ConVar VsBossFlowBuffer;

    // —— Nav 分桶 —— //
    ConVar NavBucketEnable;      
    ConVar NavBucketWindow;      

    // —— 动态分桶（新增） —— //
    ConVar NavBucketLinkToRing;   // 1=跟随扩圈动态调整桶窗口
    ConVar NavBucketWindowMin;    // ring<=MinAt 时窗口(±N)
    ConVar NavBucketWindowMax;    // ring>=MaxAt 时窗口(±N)
    ConVar NavBucketMinAt;        // ring 下界
    ConVar NavBucketMaxAt;        // ring 上界

    // —— 分桶策略增强 —— //
    ConVar NavBucketFirstFit;     // 找到第一个合格点就返回
    ConVar NavBucketIncludeCtr;   // 是否包含中心桶 s

    // —— 新增：死亡CD（两档） —— //
    ConVar DeathCDKiller;        
    ConVar DeathCDSupport;       

    // —— 新增：死亡CD放宽的“双保险” —— //
    ConVar DeathCDBypassAfter;   
    ConVar DeathCDUnderfill;     

    ConVar ZSmokerLimit;
    ConVar ZBoomerLimit;
    ConVar ZHunterLimit;
    ConVar ZSpitterLimit;
    ConVar ZJockeyLimit;
    ConVar ZChargerLimit;
    ConVar TeleportSpawnGrace;   // 新刷出来后多少秒内不允许传送
    ConVar TeleportRunnerFast;   // 跑男时的快速阈值（秒），最低也要有个门槛
    // —— 支援特感解锁 —— //
    ConVar SupportUnlockKillers;
    ConVar SupportUnlockRatio;
    ConVar SupportUnlockGrace;
    // Config 字段（在 enum struct Config 里补充）
    ConVar NavBucketMapInvalid;        // 将坏flow的NavArea映射到就近正常桶
    ConVar NavBucketAssignRadius;      // 可选：就近半径上限(0=不限)
    // Config 里已有占位：ConVar gCvarNavCacheEnable; 这里补 bool 并在 Refresh 里赋值
    ConVar gCvarNavCacheEnable;
    // [新增] 新版评分系统权重与参数
    // [ADD] New scoring system weights & parameters
    ConVar Score_w_dist;
    ConVar Score_w_hght;
    ConVar Score_w_flow;
    ConVar Score_w_disp;

    ConVar PathCacheEnable;
    ConVar PathCacheQuantize;
    // [ADD] —— 轻度惩罚 badflow：仅扣 Flow 分项一点点分数（0 关闭）
    ConVar FlowBadPenaltyPoints;
    ConVar SpawnScoreFloor;      // 总分下限
    ConVar FlowBucketShare;      // Flow 桶占比上限
    // === 可视射线控制 ===
    ConVar VisEyeRayMode;        // 0=仅中线；1=中+左+右；2=自动：>4只中线，<=4三线
    int    iVisRayMode;

    // === 生还者进度本地回退 ===
    ConVar SurFlowFallbackEnable; // 0/1：启用“最后一次有效进度”回退
    ConVar SurFlowFallbackTTL;    // 回退进度的有效期（秒）
    bool   bSurFlowFallback;
    float  fSurFlowFallbackTTL;

    // [ADD] 缓存值
    float fFlowBadPenalty;

    bool  bPathCacheEnable;
    float fPathCacheQuantize;

    float w_dist[7];
    float w_hght[7];
    float w_flow[7];
    float w_disp[7];
    bool  bNavCacheEnable;

    bool  bNavBucketMapInvalid;
    float fNavBucketAssignRadius;
    float  fTeleportSpawnGrace;
    float  fTeleportRunnerFast;
    int   iSupportUnlockKillers;
    float fSupportUnlockRatio;
    float fSupportUnlockGrace;

    float fSpawnMin;
    float fSpawnMax;
    float fTeleportSpawnMin;
    float fSiInterval;
    int   iSiLimit;
    int   iEnableMask;
    int   iTeleportCheckTime;
    int   iDebugMode;
    bool  bTeleport;
    bool  bAutoSpawn;
    bool  bIgnoreIncapSight;
    bool  bAddDmgSmoker;

    // —— Nav 分桶 —— //
    bool  bNavBucketEnable;
    int   iNavBucketWindow;

    // —— 动态分桶（新增） —— //
    bool  bNavBucketLinkToRing;
    int   iNavBucketWindowMin;
    int   iNavBucketWindowMax;
    float fNavBucketMinAt;
    float fNavBucketMaxAt;

    // —— 分桶策略增强 —— //
    bool  bNavBucketFirstFit;
    bool  bNavBucketIncludeCtr;

    float fDeathCDKiller;
    float fDeathCDSupport;
    float fDeathCDBypassAfter;
    float fDeathCDUnderfill;
    float fSpawnScoreFloor;
    float fBucketSpawnRatio;
    int   iBucketMaxPerFlow;

    void Create()
    {
        this.SpawnMin          = CreateConVar("inf_SpawnDistanceMin", "250.0", "特感复活离生还者最近的距离限制", CVAR_FLAG, true, 0.0);
        this.TeleportSpawnMin  = CreateConVar("inf_TeleportDistanceMin", "400.0", "特感传送复活离生还者最近的距离限制", CVAR_FLAG, true, 0.0);
        this.SpawnMax          = CreateConVar("inf_SpawnDistanceMax", "1500.0", "特感复活离生还者最远的距离限制", CVAR_FLAG, true, this.SpawnMin.FloatValue);
        this.TeleportEnable    = CreateConVar("inf_TeleportSi", "1", "是否开启特感超时传送", CVAR_FLAG, true, 0.0, true, 1.0);
        this.TeleportCheckTime = CreateConVar("inf_TeleportCheckTime", "5", "特感几秒后没被看到开始传送", CVAR_FLAG, true, 0.0);
        this.EnableMask        = CreateConVar("inf_EnableSIoption", "63", "启用生成的特感类型位掩码 (1~63)", CVAR_FLAG, true, 0.0, true, 63.0);
        this.AllCharger        = CreateConVar("inf_AllChargerMode", "0", "是否是全牛模式", CVAR_FLAG, true, 0.0, true, 1.0);
        this.AllHunter         = CreateConVar("inf_AllHunterMode", "0", "是否是全猎人模式", CVAR_FLAG, true, 0.0, true, 1.0);
        this.AutoSpawnTime     = CreateConVar("inf_EnableAutoSpawnTime", "1", "是否开启自动增时", CVAR_FLAG, true, 0.0, true, 1.0);
        this.IgnoreIncapSight  = CreateConVar("inf_IgnoreIncappedSurvivorSight", "1", "传送检测是否忽略倒地/挂边视线", CVAR_FLAG, true, 0.0, true, 1.0);
        this.AddDmgSmoker      = CreateConVar("inf_AddDamageToSmoker", "0", "单人时Smoker拉人对Smoker增伤5x", CVAR_FLAG, true, 0.0, true, 1.0);
        this.SiLimit           = CreateConVar("l4d_infected_limit", "6", "一次刷出多少特感", CVAR_FLAG, true, 0.0);
        this.SiInterval        = CreateConVar("versus_special_respawn_interval", "16.0", "对抗刷新间隔", CVAR_FLAG, true, 0.0);
        this.DebugMode         = CreateConVar("inf_DebugMode", "0","0=off,1=log,2=console+log,3=console+log(+beam)", CVAR_FLAG, true, 0.0, true, 3.0);

        // —— Nav 分桶（静态窗口） —— //
        this.NavBucketEnable   = CreateConVar("inf_NavBucketEnable", "1", "启用 Nav 进度分桶筛选(0=禁用,1=启用)", CVAR_FLAG, true, 0.0, true, 1.0);
        this.NavBucketWindow   = CreateConVar("inf_NavBucketWindow", "10", "按进度百分比搜索的桶半径(±N)", CVAR_FLAG, true, 0.0, true, 100.0);

        // —— 动态分桶（新增） —— //
        this.NavBucketLinkToRing = CreateConVar("inf_NavBucketLinkToRing", "1", "扩圈时动态调整桶窗口(0=关闭,1=开启)", CVAR_FLAG, true, 0.0, true, 1.0);
        this.NavBucketWindowMin  = CreateConVar("inf_NavBucketWindowMin", "6", "ring<=MinAt时使用的桶窗口(±N)", CVAR_FLAG, true, 0.0, true, 100.0);
        this.NavBucketWindowMax  = CreateConVar("inf_NavBucketWindowMax", "12", "ring>=MaxAt时使用的桶窗口(±N)", CVAR_FLAG, true, 0.0, true, 100.0);
        this.NavBucketMinAt      = CreateConVar("inf_NavBucketMinAt", "500.0", "小桶阈值对应的ring", CVAR_FLAG, true, 0.0);
        this.NavBucketMaxAt      = CreateConVar("inf_NavBucketMaxAt", "1500.0", "大桶阈值对应的ring", CVAR_FLAG, true, 0.0);

        // —— 分桶策略增强 —— //
        this.NavBucketFirstFit   = CreateConVar("inf_NavBucketFirstFit", "0",  "找到第一个合格点就返回(1=是,0=否)", CVAR_FLAG, true, 0.0, true, 1.0);
        this.NavBucketIncludeCtr = CreateConVar("inf_NavBucketIncludeCenter", "1", "是否把中心桶 s 也加入扫描序列(1=是,0=否)", CVAR_FLAG, true, 0.0, true, 1.0);

        // —— 死亡CD —— //
        this.DeathCDKiller     = CreateConVar("inf_DeathCooldownKiller",  "1.0","同类击杀后最小补位CD（秒）：Hunter/Smoker/Jockey/Charger", CVAR_FLAG, true, 0.0, true, 30.0);
        this.DeathCDSupport    = CreateConVar("inf_DeathCooldownSupport", "2.0","同类击杀后最小补位CD（秒）：Boomer/Spitter", CVAR_FLAG, true, 0.0, true, 30.0);

        // —— 双保险 —— //
        this.DeathCDBypassAfter = CreateConVar("inf_DeathCooldown_BypassAfter", "1.5","距离上次成功刷出超过该秒数时，临时忽略死亡CD", CVAR_FLAG, true, 0.0, true, 10.0);
        this.DeathCDUnderfill   = CreateConVar("inf_DeathCooldown_Underfill", "0.5","当【场上活着特感】< iSiLimit * 本值 时，忽略死亡CD", CVAR_FLAG, true, 0.0, true, 1.0);
        this.TeleportSpawnGrace = CreateConVar("inf_TeleportSpawnGrace", "2.5",
            "特感生成后多少秒内禁止传送", CVAR_FLAG, true, 0.0, true, 10.0);
        this.TeleportRunnerFast = CreateConVar("inf_TeleportRunnerFast", "1.5",
            "跑男时的快速传送阈值（秒），仍需达到该不可见时长才可传送", CVAR_FLAG, true, 0.0, true, 10.0);
        this.SupportUnlockKillers = CreateConVar("inf_support_unlock_killers", "-1",
            "支援特感(Smoker/Spitter/Boomer)解锁所需的优先特感(Jockey/Hunter/Charger)数量；<0 表示按 inf_support_unlock_ratio 自动计算，0 关闭限制。",
            CVAR_FLAG, true, -1.0, true, 12.0);
        this.SupportUnlockRatio = CreateConVar("inf_support_unlock_ratio", "0.4",
            "当 inf_support_unlock_killers < 0 时，所需优先特感 = RoundToFloor(limit * ratio)。0 关闭比例限制。",
            CVAR_FLAG, true, 0.0, true, 1.0);
        this.SupportUnlockGrace = CreateConVar("inf_support_unlock_grace", "1.0",
            "当优先类不足时等待多少秒后自动放开支援限制；0 = 永不自动放开。",
            CVAR_FLAG, true, 0.0, true, 30.0);
        // Create() 里，紧跟“Nav 分桶”相关 CVar 后面加入：
        this.NavBucketMapInvalid   = CreateConVar("inf_NavBucketMapInvalid", "1",
            "Map invalid-flow NavAreas to nearest valid-flow bucket (0=off,1=on)", CVAR_FLAG, true, 0.0, true, 1.0);
        this.NavBucketAssignRadius = CreateConVar("inf_NavBucketAssignRadius", "2000.0",
            "Optional XY max distance when reassigning invalid-flow areas; 0 = unlimited", CVAR_FLAG, true, 0.0);
        this.gCvarNavCacheEnable = CreateConVar(
            "inf_NavCacheEnable", "1",
            "Enable on-disk cache for Nav flow buckets (0=off,1=on)",
            CVAR_FLAG, true, 0.0, true, 1.0);
        // [新增] 为新评分系统创建CVar
        // [ADD] Create CVars for the new scoring system
        this.Score_w_dist = CreateConVar("inf_score_w_dist", "1.35 1.10 1.20 1.05 1.20 1.25", "距离分权重(S,H,P,B,J,C)", CVAR_FLAG);
        this.Score_w_hght = CreateConVar("inf_score_w_hght", "2.20 1.10 1.60 1.40 0.60 0.60", "高度分权重(S,H,P,B,J,C)", CVAR_FLAG);
        this.Score_w_flow = CreateConVar("inf_score_w_flow", "1.40 1.00 1.20 1.35 1.10 1.20", "流程分权重(S,H,P,B,J,C)", CVAR_FLAG);
        this.Score_w_disp = CreateConVar("inf_score_w_disp", "1.25 1.05 1.15 1.30 0.90 0.80", "分散度分权重(S,H,P,B,J,C)", CVAR_FLAG);
        this.PathCacheEnable   = CreateConVar("inf_PathCacheEnable", "1",
            "Enable PathPenalty_NoBuild cache (0/1)", CVAR_FLAG, true, 0.0, true, 1.0);
        this.PathCacheQuantize = CreateConVar("inf_PathCacheQuantize", "50.0",
            "Quantization step for limitCost when caching (world units)",
            CVAR_FLAG, true, 1.0, true, 500.0);
        // [ADD] badflow 轻度惩罚（仅影响 Flow 分项；默认 2 分）
        this.FlowBadPenaltyPoints = CreateConVar(
            "inf_flow_bad_penalty_points",
            "30.0",
            "Mild points to subtract from FLOW score when the area has invalid raw flow (mapped badflow). 0 disables.",
            CVAR_FLAG, 
            true, 0.0, true, 100.0
        );
        // 可视射线：0=仅中线；1=三线；2=自动（>4生还者仅中线）
        this.VisEyeRayMode = CreateConVar(
            "inf_VisEyeRayMode", "2",
            "0=center only; 1=center+left+right; 2=auto (if alive survivors > 4 -> center only)",
            CVAR_FLAG, true, 0.0, true, 2.0
        );
        this.SpawnScoreFloor = CreateConVar(
            "inf_spawn_score_floor", "50.0",
            "最小总评分阈值，低于该值的刷点直接丢弃；0=关闭限制。",
            CVAR_FLAG, true, -1000.0, true, 5000.0
        );
        this.FlowBucketShare = CreateConVar(
            "inf_spawn_bucket_ratio", "50.0",
            "同一 Flow 桶中允许同时存在的特感占比（相对 l4d_infected_limit）；0=关闭。",
            CVAR_FLAG, true, 0.0, true, 1.0
        );

        // 生还者进度回退
        this.SurFlowFallbackEnable = CreateConVar(
            "inf_SurProgressFallback", "1",
            "Enable survivor progress fallback when all flows are invalid (0/1)",
            CVAR_FLAG, true, 0.0, true, 1.0
        );
        this.SurFlowFallbackTTL = CreateConVar(
            "inf_SurProgressFallbackTTL", "20.0",
            "TTL (seconds) for last-good survivor progress fallback",
            CVAR_FLAG, true, 1.0, true, 120.0
        );

        // 变更回调
        this.VisEyeRayMode.AddChangeHook(OnCfgChanged);
        this.SurFlowFallbackEnable.AddChangeHook(OnCfgChanged);
        this.SurFlowFallbackTTL.AddChangeHook(OnCfgChanged);
        this.FlowBadPenaltyPoints.AddChangeHook(OnCfgChanged);
        this.SpawnScoreFloor.AddChangeHook(OnCfgChanged);
        this.FlowBucketShare.AddChangeHook(OnCfgChanged);

        this.PathCacheEnable.AddChangeHook(OnCfgChanged);
        this.PathCacheQuantize.AddChangeHook(OnCfgChanged);
        this.Score_w_dist.AddChangeHook(OnCfgChanged);
        this.Score_w_hght.AddChangeHook(OnCfgChanged);
        this.Score_w_flow.AddChangeHook(OnCfgChanged);
        this.Score_w_disp.AddChangeHook(OnCfgChanged);
        this.gCvarNavCacheEnable.AddChangeHook(OnCfgChanged);

        this.NavBucketMapInvalid.AddChangeHook(OnCfgChanged);
        this.NavBucketAssignRadius.AddChangeHook(OnCfgChanged);
        this.TeleportSpawnGrace.AddChangeHook(OnCfgChanged);
        this.TeleportRunnerFast.AddChangeHook(OnCfgChanged);
        this.SupportUnlockKillers.AddChangeHook(OnCfgChanged);
        this.SupportUnlockRatio.AddChangeHook(OnCfgChanged);
        this.SupportUnlockGrace.AddChangeHook(OnCfgChanged);
        this.MaxPlayerZombies  = FindConVar("z_max_player_zombies");
        this.VsBossFlowBuffer  = FindConVar("versus_boss_buffer");
        this.ZSmokerLimit  = FindConVar("z_smoker_limit");
        this.ZBoomerLimit  = FindConVar("z_boomer_limit");
        this.ZHunterLimit  = FindConVar("z_hunter_limit");
        this.ZSpitterLimit = FindConVar("z_spitter_limit");
        this.ZJockeyLimit  = FindConVar("z_jockey_limit");
        this.ZChargerLimit = FindConVar("z_charger_limit");
        this.DeathCDKiller.AddChangeHook(OnCfgChanged);
        this.DeathCDSupport.AddChangeHook(OnCfgChanged);
        this.DeathCDBypassAfter.AddChangeHook(OnCfgChanged);
        this.DeathCDUnderfill.AddChangeHook(OnCfgChanged);

        SetConVarInt(FindConVar("director_no_specials"), 1);

        this.SpawnMax.AddChangeHook(OnCfgChanged);
        this.SpawnMin.AddChangeHook(OnCfgChanged);
        this.TeleportSpawnMin.AddChangeHook(OnCfgChanged);
        this.TeleportEnable.AddChangeHook(OnCfgChanged);
        this.TeleportCheckTime.AddChangeHook(OnCfgChanged);
        this.SiInterval.AddChangeHook(OnCfgChanged);
        this.IgnoreIncapSight.AddChangeHook(OnCfgChanged);
        this.EnableMask.AddChangeHook(OnCfgChanged);
        this.AllCharger.AddChangeHook(OnCfgChanged);
        this.AllHunter.AddChangeHook(OnCfgChanged);
        this.AutoSpawnTime.AddChangeHook(OnCfgChanged);
        this.AddDmgSmoker.AddChangeHook(OnCfgChanged);
        this.SiLimit.AddChangeHook(OnSiLimitChanged);
        this.DebugMode.AddChangeHook(OnCfgChanged);

        // Nav 分桶
        this.NavBucketEnable.AddChangeHook(OnCfgChanged);
        this.NavBucketWindow.AddChangeHook(OnCfgChanged);
        this.NavBucketLinkToRing.AddChangeHook(OnCfgChanged);
        this.NavBucketWindowMin.AddChangeHook(OnCfgChanged);
        this.NavBucketWindowMax.AddChangeHook(OnCfgChanged);
        this.NavBucketMinAt.AddChangeHook(OnCfgChanged);
        this.NavBucketMaxAt.AddChangeHook(OnCfgChanged);
        this.NavBucketFirstFit.AddChangeHook(OnCfgChanged);
        this.NavBucketIncludeCtr.AddChangeHook(OnCfgChanged);

        this.VsBossFlowBuffer.AddChangeHook(OnFlowBufferChanged); // Flow百分比受它影响 → 变更时重建桶

        this.Refresh();
        this.ApplyMaxZombieBound();
    }

    void Refresh()
    {
        this.fSpawnMax          = this.SpawnMax.FloatValue;
        this.fSpawnMin          = this.SpawnMin.FloatValue;
        this.fTeleportSpawnMin  = this.TeleportSpawnMin.FloatValue;
        this.bTeleport          = this.TeleportEnable.BoolValue;
        this.fSiInterval        = this.SiInterval.FloatValue;
        this.iSiLimit           = this.SiLimit.IntValue;
        this.iTeleportCheckTime = this.TeleportCheckTime.IntValue;
        this.iEnableMask        = this.EnableMask.IntValue;
        this.bAddDmgSmoker      = this.AddDmgSmoker.BoolValue;
        this.bAutoSpawn         = this.AutoSpawnTime.BoolValue;
        this.bIgnoreIncapSight  = this.IgnoreIncapSight.BoolValue;
        this.iDebugMode         = this.DebugMode.IntValue;

        // Nav 分桶
        this.bNavBucketEnable   = this.NavBucketEnable.BoolValue;
        this.iNavBucketWindow   = this.NavBucketWindow.IntValue;

        // 动态分桶
        this.bNavBucketLinkToRing = this.NavBucketLinkToRing.BoolValue;
        this.iNavBucketWindowMin  = this.NavBucketWindowMin.IntValue;
        this.iNavBucketWindowMax  = this.NavBucketWindowMax.IntValue;
        this.fNavBucketMinAt      = this.NavBucketMinAt.FloatValue;
        this.fNavBucketMaxAt      = this.NavBucketMaxAt.FloatValue;

        // 分桶策略增强
        this.bNavBucketFirstFit   = this.NavBucketFirstFit.BoolValue;
        this.bNavBucketIncludeCtr = this.NavBucketIncludeCtr.BoolValue;

        // 死亡CD & 放宽
        this.fDeathCDKiller     = this.DeathCDKiller.FloatValue;
        this.fDeathCDSupport    = this.DeathCDSupport.FloatValue;
        this.fDeathCDBypassAfter= this.DeathCDBypassAfter.FloatValue;
        this.fDeathCDUnderfill  = this.DeathCDUnderfill.FloatValue;
        this.fTeleportSpawnGrace = this.TeleportSpawnGrace.FloatValue;
        this.fTeleportRunnerFast = this.TeleportRunnerFast.FloatValue;
        this.iSupportUnlockKillers = this.SupportUnlockKillers.IntValue;
        this.fSupportUnlockRatio   = this.SupportUnlockRatio.FloatValue;
        if (this.fSupportUnlockRatio < 0.0) this.fSupportUnlockRatio = 0.0;
        if (this.fSupportUnlockRatio > 1.0) this.fSupportUnlockRatio = 1.0;
        this.fSupportUnlockGrace   = this.SupportUnlockGrace.FloatValue;
        if (this.fSupportUnlockGrace < 0.0) this.fSupportUnlockGrace = 0.0;

        this.bNavBucketMapInvalid   = this.NavBucketMapInvalid.BoolValue;
        this.fNavBucketAssignRadius = this.NavBucketAssignRadius.FloatValue;
        this.bNavCacheEnable = this.gCvarNavCacheEnable.BoolValue;
        // [新增] 刷新新评分系统的权重值 (已修正 ExplodeString 用法)
        // [ADD] Refresh weights for the new scoring system (ExplodeString usage corrected)
        char buffer[256];
        char parts[6][16];
        int numParts;

        // [新增] —— 权重兜底：当 CVar 给的值不足或为 0 时，回退到 1.0，避免意外禁用某因子
        for (int i = 1; i <= 6; i++) {
            if (this.w_dist[i] <= 0.0) this.w_dist[i] = 1.0;
            if (this.w_hght[i] <= 0.0) this.w_hght[i] = 1.0;
            if (this.w_flow[i] <= 0.0) this.w_flow[i] = 1.0;
            if (this.w_disp[i] <= 0.0) this.w_disp[i] = 1.0;
        }

        this.Score_w_dist.GetString(buffer, sizeof(buffer));
        numParts = ExplodeString(buffer, " ", parts, 6, 16);
        for (int i = 0; i < numParts && i < 6; i++) {
            this.w_dist[i+1] = StringToFloat(parts[i]);
        }

        this.Score_w_hght.GetString(buffer, sizeof(buffer));
        numParts = ExplodeString(buffer, " ", parts, 6, 16);
        for (int i = 0; i < numParts && i < 6; i++) {
            this.w_hght[i+1] = StringToFloat(parts[i]);
        }

        this.Score_w_flow.GetString(buffer, sizeof(buffer));
        numParts = ExplodeString(buffer, " ", parts, 6, 16);
        for (int i = 0; i < numParts && i < 6; i++) {
            this.w_flow[i+1] = StringToFloat(parts[i]);
        }

        this.Score_w_disp.GetString(buffer, sizeof(buffer));
        numParts = ExplodeString(buffer, " ", parts, 6, 16);
        for (int i = 0; i < numParts && i < 6; i++) {
            this.w_disp[i+1] = StringToFloat(parts[i]);
        }
        
        this.bPathCacheEnable   = this.PathCacheEnable.BoolValue;
        this.fPathCacheQuantize = this.PathCacheQuantize.FloatValue;
        if (this.fPathCacheQuantize < 1.0) this.fPathCacheQuantize = 1.0;
        // [ADD] 读取 badflow 轻度惩罚
        this.fFlowBadPenalty = this.FlowBadPenaltyPoints.FloatValue;
        if (this.fFlowBadPenalty < 0.0) this.fFlowBadPenalty = 0.0;
        if (this.fFlowBadPenalty > 100.0) this.fFlowBadPenalty = 100.0;
        this.iVisRayMode        = this.VisEyeRayMode.IntValue;
        this.fSpawnScoreFloor   = this.SpawnScoreFloor.FloatValue;
        this.fBucketSpawnRatio  = this.FlowBucketShare.FloatValue;
        if (this.fBucketSpawnRatio <= 0.0)
        {
            this.fBucketSpawnRatio = 0.0;
            this.iBucketMaxPerFlow = 0;
        }
        else
        {
            if (this.fBucketSpawnRatio > 1.0) this.fBucketSpawnRatio = 1.0;
            int cap = RoundToCeil(float(this.iSiLimit) * this.fBucketSpawnRatio);
            if (cap < 1) cap = 1;
            this.iBucketMaxPerFlow = cap;
        }

        this.bSurFlowFallback   = this.SurFlowFallbackEnable.BoolValue;
        this.fSurFlowFallbackTTL= this.SurFlowFallbackTTL.FloatValue;
        if (this.fSurFlowFallbackTTL < 1.0) this.fSurFlowFallbackTTL = 1.0;
    }

    void ApplyMaxZombieBound()
    {
        SetConVarBounds(this.MaxPlayerZombies, ConVarBound_Upper, true, float(this.iSiLimit));
        this.MaxPlayerZombies.IntValue = this.iSiLimit;
    }
}


enum struct Queues
{
    ArrayList spawn;      // of int SIClass
    ArrayList teleport;   // of int SIClass

    void Create()
    {
        this.spawn    = new ArrayList();
        this.teleport = new ArrayList();
    }
    void Clear()
    {
        this.spawn.Clear();
        this.teleport.Clear();
    }
}

enum struct State
{
    Handle hCheck;
    Handle hSpawn;
    Handle hTeleport;

    bool   bLate;
    bool   bPickRushMan;
    bool   bShouldCheck;

    bool   bPauseLib;
    bool   bSmokerLib;
    bool   bTargetLimitLib;

    int    totalSI;
    int    siQueueCount;
    int    teleCount[MAXPLAYERS+1];
    int    siAlive[6];
    int    siCap[6];
    int    teleportQueueSize;
    int    spawnQueueSize;
    int    waveIndex;
    int    lastSpawnSecs;
    int    rushManIndex;
    int    targetSurvivor;

    int    survCount;
    int    survIdx[8];

    float  lastWaveStartTime;
    float  unpauseDelay;
    float  lastWaveAvgFlow;
    float  spawnDistCur;
    float  teleportDistCur;
    float  spitterSpitTime[MAXPLAYERS+1];

    float  nextFrameThink;

    void Reset()
    {
        if (this.hTeleport != INVALID_HANDLE) { delete this.hTeleport; this.hTeleport = INVALID_HANDLE; }
        if (this.hCheck    != INVALID_HANDLE) { delete this.hCheck;    this.hCheck    = INVALID_HANDLE; }
        if (this.hSpawn    != INVALID_HANDLE) { KillTimer(this.hSpawn); this.hSpawn    = INVALID_HANDLE; }

        this.bPickRushMan = false;
        this.bShouldCheck = false;
        this.bLate        = false;

        this.siQueueCount = 0;
        this.lastWaveStartTime = 0.0;
        this.unpauseDelay      = 0.0;
        this.lastWaveAvgFlow   = 0.0;
        this.totalSI           = 0;
        this.spawnQueueSize    = 0;
        this.teleportQueueSize = 0;
        this.waveIndex         = 0;
        this.rushManIndex      = -1;
        this.targetSurvivor    = -1;
        this.spawnDistCur      = 0.0;
        this.teleportDistCur   = 0.0;
        this.nextFrameThink    = 0.0;

        for (int i = 0; i <= MAXPLAYERS; i++)
        {
            this.spitterSpitTime[i] = 0.0;
            this.teleCount[i]       = 0;
        }
        for (int i = 0; i < 6; i++) this.siAlive[i] = 0;
        for (int i = 0; i <= MAXPLAYERS; i++) g_LastSpawnTime[i] = 0.0;
    }
}


// —— 可选库可用性 —— 
static bool g_bPauseLib       = false;
static bool g_bSmokerLib      = false;
static bool g_bTargetLimitLib = false;

// Survivor 数据缓存（fdxx风格）
enum struct SurPosData 
{ 
    float fFlow; 
    float fPos[3]; 
}
static ArrayList g_aSurPosData = null;
static int g_iSurPosDataLen = 0;
static int g_iSurvivors[MAXPLAYERS+1];
static int g_iSurCount = 0;

// —— 分散度：最近扇区 & 最近刷点 —— //
int recentSectors[3] = { -1, -1, -1 };   // 最近 3 次使用的扇区
ArrayList lastSpawns = null;             // 每条记录 [x,y,z,time]

// —— 新增：死亡CD时间戳 & 最近一次成功刷出 —— //
static float g_LastDeathTime[6];     // zc-1 索引
static float g_LastSpawnOkTime = 0.0;
static float g_SupportShortageStart = 0.0;

// —— Nav Flow 分桶 —— //
static ArrayList g_FlowBuckets[FLOW_BUCKETS]; // 每桶存 NavArea 索引 i
static bool g_BucketsReady = false;

// —— 供就近归桶使用的中心点 & 预分配的桶百分比 —— //
static ArrayList g_AreaCX  = null;  // float per areaIdx
static ArrayList g_AreaCY  = null;  // float per areaIdx
static ArrayList g_AreaPct = null;  // int   per areaIdx（-1=未知/坏flow，否则0..100）

// 跑男通知 forward
Handle g_hRushManNotifyForward = INVALID_HANDLE;

// =========================
// 全局
// =========================
public Plugin myinfo =
{
    name        = "Direct InfectedSpawn (fdxx-nav + buckets + maxdist-fallback)",
    author      = "东, Caibiii, 夜羽真白, Paimon-Kawaii, fdxx (inspiration), ChatGPT",
    description = "特感刷新控制 / 传送 / 跑男 / fdxx NavArea选点 + 进度分桶 + 最大距离兜底",
    version     = "2025.10.26",
    url         = "https://github.com/fantasylidong/CompetitiveWithAnne"
};

static Config gCV;
static State  gST;
static Queues gQ;

static char g_sLogFile[PLATFORM_MAX_PATH] = "addons/sourcemod/logs/infected_control_fdxxnav.txt";

// =========================
// 前置：事件 & 库
// =========================
public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    RegPluginLibrary("infected_control");                           // 供其他插件依赖
    g_hRushManNotifyForward = CreateGlobalForward("OnDetectRushman", // 跑男 forward：传入幸存者 index
                                                  ET_Ignore, Param_Cell);
    CreateNative("GetNextSpawnTime", Native_GetNextSpawnTime);       // native：下一次刷特剩余秒数
    return APLRes_Success;
}
public void OnAllPluginsLoaded()
{
    g_bTargetLimitLib = LibraryExists("si_target_limit");
    g_bSmokerLib      = LibraryExists("ai_smoker_new");
    g_bPauseLib       = LibraryExists("pause");
}
public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "si_target_limit")) g_bTargetLimitLib = true;
    else if (StrEqual(name, "ai_smoker_new")) g_bSmokerLib   = true;
    else if (StrEqual(name, "pause"))         g_bPauseLib    = true;
}
public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "si_target_limit")) g_bTargetLimitLib = false;
    else if (StrEqual(name, "ai_smoker_new")) g_bSmokerLib   = false;
    else if (StrEqual(name, "pause"))         g_bPauseLib    = false;
}
//native
public any Native_GetNextSpawnTime(Handle plugin, int numParams)
{
    // -1：还没开始刷特（或未知）
    if (!gST.bLate)
        return view_as<any>(-1.0);

    float now = GetGameTime();

    // 如果在暂停，返回预计恢复倒计时
    if (g_bPauseLib && IsInPause())
    {
        float rem = gST.unpauseDelay;
        if (rem <= 0.0) rem = -1.0;
        return view_as<any>(rem);
    }

    // 如果“下一波定时器”存在，按 (间隔 - 已经过的时间) 粗略估算
    if (gST.hSpawn != INVALID_HANDLE)
    {
        float rem = gCV.fSiInterval - (now - gST.lastWaveStartTime);
        if (rem < 0.0) rem = 0.0;
        return view_as<any>(rem);
    }

    // 没有定时器则表示由窗口逻辑随时可能触发，返回 刷特间隔
    return view_as<any>(gCV.fSiInterval);
}

// =========================
// 插件生命周期
// =========================
public void OnPluginStart()
{
    gCV.Create();
    gQ.Create();
    gST.Reset();
    InitSDK_FromGamedata();   // ← 加载 NavArea SDK/偏移
    BuildNavIdIndexMap();
    BuildNavBuckets();        // ← 预建 FLOW 分桶
    RecalcSiCapFromAlive(true);

    // 分散度：初始化
    g_NavCooldown = new StringMap();
    lastSpawns = new ArrayList(4);
    recentSectors[0] = recentSectors[1] = recentSectors[2] = -1;
    // [新增] Path 缓存初始化
    g_PathCacheRes = new StringMap();

    // 初始化死亡时间戳
    g_LastSpawnOkTime = 0.0;
    g_SupportShortageStart = 0.0;
    for (int i = 0; i < 6; i++) g_LastDeathTime[i] = 0.0;

    RegAdminCmd("sm_startspawn", Cmd_StartSpawn, ADMFLAG_ROOT, "管理员重置刷特时钟");
    RegAdminCmd("sm_stopspawn",  Cmd_StopSpawn,  ADMFLAG_ROOT, "管理员停止刷特");
    RegAdminCmd("sm_rebuildnavcache", Cmd_RebuildNavCache, ADMFLAG_ROOT, "Rebuild Nav bucket cache for current map");
    RegAdminCmd("sm_navpeek", Cmd_NavPeek, ADMFLAG_GENERIC, "查看准星 Nav 的分桶与属性");
    RegAdminCmd("sm_np",      Cmd_NavPeek, ADMFLAG_GENERIC, "查看准星 Nav 的分桶与属性(别名)");
    RegAdminCmd("sm_navtest", Cmd_NavTest, ADMFLAG_GENERIC, "测试准星 Nav 能否生成特感及评分");
    RegAdminCmd("sm_nt",      Cmd_NavTest, ADMFLAG_GENERIC, "测试准星 Nav 能否生成特感及评分(别名)");

    HookEvent("finale_win",      evt_RoundEnd);
    HookEvent("mission_lost",    evt_RoundEnd);
    HookEvent("map_transition",  evt_RoundEnd);
    HookEvent("round_start",     evt_RoundStart);
    HookEvent("player_spawn",    evt_PlayerSpawn);
    HookEvent("player_death",    evt_PlayerDeath);
    HookEvent("ability_use",     evt_AbilityUse);
    HookEvent("player_hurt",     evt_PlayerHurt);
    TweakSettings();
}

public void OnPluginEnd()
{
    if (gCV.AllCharger.IntValue == 1)
    {
        FindConVar("z_charger_health").RestoreDefault();
        FindConVar("z_charge_max_speed").RestoreDefault();
        FindConVar("z_charge_start_speed").RestoreDefault();
        FindConVar("z_charger_pound_dmg").RestoreDefault();
        FindConVar("z_charge_max_damage").RestoreDefault();
        FindConVar("z_charge_interval").RestoreDefault();
    }
    // [新增] —— 每波开始即清理 Path 缓存（波级作用域）
    ClearPathCache();
}
public void OnMapEnd()
{
    if (g_NavCooldown != null) g_NavCooldown.Clear();
    if (lastSpawns != null) lastSpawns.Clear();
    recentSectors[0] = recentSectors[1] = recentSectors[2] = -1;

    g_LastSpawnOkTime = 0.0;
    g_SupportShortageStart = 0.0;
    for (int i = 0; i < 6; i++) g_LastDeathTime[i] = 0.0;

    ClearNavBuckets();
    g_BucketsReady = false;
    for (int i = 0; i <= MAXPLAYERS; i++) g_LastSpawnTime[i] = 0.0;
    if (g_NavIdToIndex != null) { delete g_NavIdToIndex; g_NavIdToIndex = null; }
    // [新增] —— 每波开始即清理 Path 缓存（波级作用域）
    ClearPathCache();
    // ✅ 添加：清理 NavAreas 缓存
    ClearNavAreasCache();
}
// =========================
// NavAreas 缓存管理
// =========================

// ✅ 新增：确保缓存已初始化
stock void EnsureNavAreasCache()
{
    if (g_AllNavAreasCache == null)
    {
        g_AllNavAreasCache = new ArrayList();
        L4D_GetAllNavAreas(g_AllNavAreasCache);
        g_NavAreasCacheCount = g_AllNavAreasCache.Length;
        Debug_Print("[NAV CACHE] Initialized: %d areas", g_NavAreasCacheCount);
    }
}

// ✅ 新增：清理缓存
stock void ClearNavAreasCache()
{
    if (g_AllNavAreasCache != null)
    {
        delete g_AllNavAreasCache;
        g_AllNavAreasCache = null;
        g_NavAreasCacheCount = 0;
        Debug_Print("[NAV CACHE] Cleared");
    }
}

// ✅ 新增：强制重建缓存
stock void RebuildNavAreasCache()
{
    ClearNavAreasCache();
    EnsureNavAreasCache();
}
void TweakSettings()
{
    if (gCV.AllCharger.IntValue == 1)
    {
        FindConVar("z_charger_health").SetFloat(500.0);
        FindConVar("z_charge_max_speed").SetFloat(750.0);
        FindConVar("z_charge_start_speed").SetFloat(350.0);
        FindConVar("z_charger_pound_dmg").SetFloat(10.0);
        FindConVar("z_charge_max_damage").SetFloat(6.0);
        FindConVar("z_charge_interval").SetFloat(2.0);
    }
}

// =========================
// 调试输出
// =========================
stock void Debug_Print(const char[] format, any ...)
{
    if (gCV.iDebugMode <= 0) return;
    char buf[512];
    VFormat(buf, sizeof buf, format, 2);
    LogToFile(g_sLogFile, "%s", buf);
    if (gCV.iDebugMode >= 2)
        PrintToConsoleAll("[IC] %s", buf);
}
stock void LogMsg(const char[] fmt, any ...)
{
    if (gCV.iDebugMode <= 0) return;
    char b[512];
    VFormat(b, sizeof b, fmt, 2);
    LogToFile(g_sLogFile, "%s", b);
    if (gCV.iDebugMode >= 2) PrintToServer("[IC] %s", b);
}

// =========================
// 管理指令
// =========================
public Action Cmd_StartSpawn(int client, int args)
{
    if (L4D_HasAnySurvivorLeftSafeArea())
    {
        ResetMatchState();
        CreateTimer(0.1, Timer_SpawnFirstWave);
        ReadSiCap();
        TweakSettings();
    }
    return Plugin_Handled;
}
public Action Cmd_StopSpawn(int client, int args)
{
    StopAll();
    return Plugin_Handled;
}

// ✅ 修改：重建时也重建 NavAreas 缓存
public Action Cmd_RebuildNavCache(int client, int args)
{
    // 强制重建 NavAreas 缓存
    RebuildNavAreasCache();
    
    // 强制重建并覆盖 Bucket 缓存
    ClearNavBuckets();
    g_BucketsReady = false;
    BuildNavBuckets();
    
    ReplyToCommand(client, "[IC] Rebuilt Nav bucket cache.");
    return Plugin_Handled;
}

// ===== 准星 NavArea 查看命令 =====
public Action Cmd_NavPeek(int client, int args)
{
    if (!client || !IsClientInGame(client))
        return Plugin_Handled;

    float hit[3];
    if (!GetAimHitPos(client, hit))
    {
        PrintToChat(client, "\x04[IC]\x01 未能获取准星命中点。");
        return Plugin_Handled;
    }

    // 命中点所在的 TerrorNavArea；不行就找最近
    Address area = L4D2Direct_GetTerrorNavArea(hit);
    if (area == Address_Null)
        area = view_as<Address>(L4D_GetNearestNavArea(hit, 300.0, false, false, false, TEAM_INFECTED));

    if (area == Address_Null)
    {
        PrintToChat(client, "\x04[IC]\x01 附近没有 NavArea。");
        return Plugin_Handled;
    }

    NavArea na = view_as<NavArea>(area);
    int navid  = L4D_GetNavAreaID(area);
    int index  = FindNavIndexByAddress(area);

    float flowDist = na.GetFlow();                      // 可能为负(无效)
    float maxFlow  = L4D2Direct_GetMapMaxFlowDistance();
    int   bucketC  = (flowDist >= 0.0 && maxFlow > 0.0) ? FlowDistanceToPercent(flowDist) : -1;

    // 若预分桶已就绪，拿“归档桶”和区域高度统计
    int   bucketA = -1;
    float aZCore = 0.0, aZMin = 0.0, aZMax = 0.0;
    float bZMin  = 0.0, bZMax  = 0.0;

    if (g_BucketsReady && index >= 0 && g_AreaPct != null)
    {
        bucketA = view_as<int>(g_AreaPct.Get(index));
        aZCore  = view_as<float>(g_AreaZCore.Get(index));
        aZMin   = view_as<float>(g_AreaZMin.Get(index));
        aZMax   = view_as<float>(g_AreaZMax.Get(index));
        if (0 <= bucketA && bucketA <= 100)
        {
            bZMin = g_BucketMinZ[bucketA];
            bZMax = g_BucketMaxZ[bucketA];
        }
    }

    // 解析 Nav flags
    int flags = na.SpawnAttributes;
    char flagBuf[256];
    DescribeNavFlags(flags, flagBuf, sizeof flagBuf);

    // —— 控制台详细 —— //
    PrintToConsole(client, "=== [IC] NavPeek ===");
    PrintToConsole(client, "pos = (%.1f, %.1f, %.1f)", hit[0], hit[1], hit[2]);
    PrintToConsole(client, "navid = %d, index = %d", navid, index);
    if (bucketC >= 0)
        PrintToConsole(client, "flow = %.1f / %.1f  -> bucket(computed) = %d", flowDist, maxFlow, bucketC);
    else
        PrintToConsole(client, "flow = (invalid) -> bucket(computed) = N/A");

    if (g_BucketsReady)
    {
        PrintToConsole(client, "bucket(assigned) = %d", bucketA);
        PrintToConsole(client, "areaZ(core/min/max) = %.1f / %.1f / %.1f", aZCore, aZMin, aZMax);
        if (0 <= bucketA && bucketA <= 100)
            PrintToConsole(client, "bucketZ[min..max] = [%.1f .. %.1f]", bZMin, bZMax);
    }
    PrintToConsole(client, "flags = %s", flagBuf[0] ? flagBuf : "(none)");

    // —— 聊天简要 —— //
    if (bucketC >= 0)
        PrintToChat(client, "\x04[IC]\x01 navid=%d  桶=%d(算) / %d(归)  flag=%s", navid, bucketC, bucketA, flagBuf);
    else
        PrintToChat(client, "\x04[IC]\x01 navid=%d  桶=N/A / %d(归)  flag=%s", navid, bucketA, flagBuf);

    // DebugMode>=3：画一条短暂的准星射线，直观确认命中点
    if (gCV.iDebugMode >= 3)
        DrawAimLineOnce(client, hit);

    return Plugin_Handled;
}

// —— 计算准星命中点（忽略玩家/感染者/女巫，优先世界几何）——
static bool GetAimHitPos(int client, float outPos[3])
{
    float start[3], ang[3], dir[3], end[3];
    GetClientEyePosition(client, start);
    GetClientEyeAngles(client, ang);
    GetAngleVectors(ang, dir, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(dir, 5000.0);
    AddVectors(start, dir, end);

    Handle tr = TR_TraceRayFilterEx(start, end, MASK_SOLID, RayType_EndPoint, TraceFilter);
    if (TR_DidHit(tr))
    {
        TR_GetEndPosition(outPos, tr);
        delete tr;
        return true;
    }
    delete tr;
    outPos = end;
    return true;
}

// [MOD] Nav 测试命令：正常 flow 仍按 ScoreFlowSmooth；仅 raw badflow 叠加“高度差惩罚”，并允许 flow 分变为负分（下限 -200）
public Action Cmd_NavTest(int client, int args) 
{
    if (!client || !IsClientInGame(client))
        return Plugin_Handled;

    float hit[3];
    if (!GetAimHitPos(client, hit))
    {
        PrintToChat(client, "\x04[IC]\x01 未能获取准星命中点。");
        return Plugin_Handled;
    }

    Address area = L4D2Direct_GetTerrorNavArea(hit);
    if (area == Address_Null)
        area = view_as<Address>(L4D_GetNearestNavArea(hit, 300.0, false, false, false, TEAM_INFECTED));

    if (area == Address_Null)
    {
        PrintToChat(client, "\x04[IC]\x01 附近没有 NavArea。");
        return Plugin_Handled;
    }

    NavArea na = view_as<NavArea>(area);
    int navid  = L4D_GetNavAreaID(area);
    int index  = FindNavIndexByAddress(area);

    float testPos[3];
    na.GetRandomPoint(testPos);

    PrintToConsole(client, "");
    PrintToConsole(client, "========================================");
    PrintToConsole(client, "=== [IC] Nav Spawn Test ===");
    PrintToConsole(client, "========================================");
    PrintToConsole(client, "NavID: %d | Index: %d", navid, index);
    PrintToConsole(client, "Test Pos: (%.1f, %.1f, %.1f)", testPos[0], testPos[1], testPos[2]);
    PrintToConsole(client, "");

    float now = GetGameTime();
    bool bFinaleArea = L4D_IsMissionFinalMap() && L4D2_GetCurrentFinaleStage() < 18;

    // 1. 冷却
    bool passCooldown = !IsNavOnCooldown(index, now);
    PrintToConsole(client, "[1] Cooldown Check: %s", passCooldown ? "PASS" : "FAIL (on cooldown)");

    // 2. Flags
    int flags = na.SpawnAttributes;
    bool passFlags = IsValidFlags(flags, bFinaleArea);
    char flagBuf[256];
    DescribeNavFlags(flags, flagBuf, sizeof flagBuf);
    PrintToConsole(client, "[2] Flags Check: %s | Flags: %s", passFlags ? "PASS" : "FAIL", flagBuf[0] ? flagBuf : "(none)");

    // 3. Flow
    float flowDist = na.GetFlow();
    float maxFlow  = L4D2Direct_GetMapMaxFlowDistance();
    bool  passFlowRaw = (flowDist >= 0.0 && flowDist <= maxFlow);

    int mappedPct = -1;
    if (gCV.bNavBucketEnable && g_BucketsReady && g_AreaPct != null && index >= 0 && index < g_AreaPct.Length) {
        mappedPct = view_as<int>(g_AreaPct.Get(index));  // 0..100 或 -1
    }
    bool passFlow = passFlowRaw || (mappedPct >= 0 && mappedPct <= 100);
    int  flowPercent = passFlowRaw ? FlowDistanceToPercent(flowDist) : mappedPct;

    PrintToConsole(client, "[3] Flow Check: %s | Flow: %.1f / %.1f (%d%%)%s",
        passFlow ? "PASS" : "FAIL (invalid flow)",
        flowDist, maxFlow, passFlow ? flowPercent : -1,
        (!passFlowRaw && passFlow) ? " [mapped]" : "");

    // 4. 距离
    float dminEye = GetMinEyeDistToAnySurvivor(testPos);
    float dminFeet = GetMinDistToAnySurvivor(testPos);
    bool passDist = (dminEye >= gCV.fSpawnMin && dminEye <= gCV.fSpawnMax);
    PrintToConsole(client, "[4] Distance Check: %s | Eye: %.1f | Feet: %.1f | Range: %.1f-%.1f", 
        passDist ? "PASS" : "FAIL", dminEye, dminFeet, gCV.fSpawnMin, gCV.fSpawnMax);

    // 5. 位置关系
    int targetSur = ChooseTargetSurvivor();
    bool passPosition = PassRealPositionCheck(testPos, targetSur, view_as<int>(SI_Smoker));
    int candPercent = GetPositionBucketPercent(testPos);
    int surPercent = -1;
    if (IsValidSurvivor(targetSur)) TryGetClientFlowPercentSafe(targetSur, surPercent);
    int deltaReal = candPercent - surPercent;
    PrintToConsole(client, "[5] Position Check: %s | Cand: %d%% | Sur: %d%% | Delta: %d%%", 
        passPosition ? "PASS" : "FAIL (behind/underfoot)", candPercent, surPercent, deltaReal);

    // 6. 分散度
    bool passSeparation = PassMinSeparation(testPos);
    PrintToConsole(client, "[6] Dispersion Check: %s | Min Sep: %s ", 
        (passSeparation ) ? "PASS" : "FAIL",
        passSeparation ? "OK" : "FAIL");

    // 7. 卡壳
    bool passStuck = !WillStuck(testPos);
    PrintToConsole(client, "[7] Stuck Check: %s", passStuck ? "PASS" : "FAIL (will stuck)");

    // 8. 视线
    bool passVis = !IsPosVisibleSDK(testPos, false);
    PrintToConsole(client, "[8] Visibility Check: %s", passVis ? "PASS" : "FAIL (visible)");

    // 9. 路径
    float pathPenalty = PathPenalty_NoBuild(testPos, targetSur, gCV.fSpawnMax, gCV.fSpawnMax);
    bool passPath = (pathPenalty == 0.0);
    PrintToConsole(client, "[9] Path Check: %s | Penalty: %.1f", passPath ? "PASS" : "FAIL (no path)", pathPenalty);

    // === 评分演算 ===
    PrintToConsole(client, "");
    PrintToConsole(client, "--- Score Breakdown (as Smoker) ---");
    
    int zc = view_as<int>(SI_Smoker);
    float center[3]; GetSectorCenter(center, targetSur);
    int sectors = GetCurrentSectors();
    int preferredSector = PickSector(sectors);
    int sidx = ComputeSectorIndex(center, testPos, sectors);
    
    float sweet, width;
    GetClassDistanceProfile(zc, gCV.fSpawnMin, gCV.fSpawnMax, sweet, width);
    float score_dist = ScoreDistSmooth(dminEye, sweet, width);
    PrintToConsole(client, "  Distance Score: %.1f (sweet: %.1f, width: %.1f)", score_dist, sweet, width);

    // 高度“偏好”分（独立正向项，不是扣分器）
    float refEyeZ = 0.0;
    if (IsValidSurvivor(targetSur) && IsPlayerAlive(targetSur))
    {
        float e[3]; GetClientEyePosition(targetSur, e);
        refEyeZ = e[2];
    }
    float score_hght = CalculateScore_Height(zc, testPos, refEyeZ);
    PrintToConsole(client, "  Height Score: %.1f (refZ: %.1f, candZ: %.1f, delta: %.1f)", 
        score_hght, refEyeZ, testPos[2], testPos[2] - refEyeZ);

    // 计算全队最高眼睛高度，用于 badflow 惩罚参考面
    float bestEyeZ = -1.0e9;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidSurvivor(i) && IsPlayerAlive(i))
        {
            float ez[3]; GetClientEyePosition(i, ez);
            if (ez[2] > bestEyeZ) bestEyeZ = ez[2];
        }
    }
    if (bestEyeZ <= -1.0e8) bestEyeZ = refEyeZ; // 兜底

    // Flow：正常按 ScoreFlowSmooth；仅 raw badflow 扣“高度惩罚”
    int centerBucket = surPercent;
    int deltaFlow    = candPercent - centerBucket;

    float flow_base = ScoreFlowSmooth(deltaFlow); // 通常 0..100
    bool  rawBadFlow = (!passFlowRaw && passFlow);
    float flow_pen   = rawBadFlow ? ComputeBadFlowHeightPenalty(testPos[2], bestEyeZ) : 0.0;

    // 【关键修改】允许变成负分（最低 -200），才能体现“>100 的扣分”
    float score_flow = flow_base - flow_pen;
    if (score_flow > 100.0) score_flow = 100.0;
    if (score_flow < -200.0) score_flow = -200.0;

    if (rawBadFlow)
    {
        PrintToConsole(client, "  Flow Score: base=%.1f, penalty=%.1f -> %.1f (delta: %d)%s",
            flow_base, flow_pen, score_flow, deltaFlow, " [mapped]");
    }
    else
    {
        PrintToConsole(client, "  Flow Score: %.1f (delta: %d)", score_flow, deltaFlow);
    }

    float score_disp = CalculateScore_Dispersion(sidx, preferredSector, recentSectors);
    float penK = ComputePenScaleByLimit(gCV.iSiLimit);
    float dispScaled = ScaleNegativeOnly(score_disp, penK);
    PrintToConsole(client, "  Dispersion Score: %.1f -> %.1f (penK: %.2f, sector: %d/%d, pref: %d)", 
        score_disp, dispScaled, penK, sidx, sectors, preferredSector);

    float totalScore = gCV.w_dist[zc]*score_dist + gCV.w_hght[zc]*score_hght
                     + gCV.w_flow[zc]*score_flow + gCV.w_disp[zc]*dispScaled;
    PrintToConsole(client, "");
    PrintToConsole(client, "  TOTAL SCORE: %.1f", totalScore);
    PrintToConsole(client, "  (weights: dist=%.2f, hght=%.2f, flow=%.2f, disp=%.2f)",
        gCV.w_dist[zc], gCV.w_hght[zc], gCV.w_flow[zc], gCV.w_disp[zc]);

    PrintToConsole(client, "");
    bool canSpawn = passCooldown && passFlags && passFlow && passDist && passPosition 
                 && passSeparation && passStuck && passVis && passPath;
    PrintToConsole(client, "========================================");
    PrintToConsole(client, "=== RESULT: %s ===", canSpawn ? "CAN SPAWN" : "CANNOT SPAWN");
    PrintToConsole(client, "========================================");
    
    if (canSpawn)
        PrintToChat(client, "\x04[IC]\x01 Nav %d \x05可以生成\x01 | 总分: \x03%.1f\x01 | 详情见控制台", navid, totalScore);
    else
        PrintToChat(client, "\x04[IC]\x01 Nav %d \x03不能生成\x01 | 详情见控制台", navid);

    if (gCV.iDebugMode >= 3)
    {
        int color[4] = {255, 255, 255, 255};
        if (canSpawn) color = {0, 255, 0, 255};
        else          color = {255, 0, 0, 255};
        
        float beamEnd[3]; beamEnd = testPos; beamEnd[2] += 100.0;
        TE_SetupBeamPoints(testPos, beamEnd, 0, 0, 0, 5, 2.0, 5.0, 5.0, 0, 0.0, color, 0);
        TE_SendToClient(client);
    }

    return Plugin_Handled;
}


// =========================
// 修改 FindNavIndexByAddress（用于调试命令）
// =========================
static int FindNavIndexByAddress(Address addr)
{
    if (addr == Address_Null) return -1;
    
    EnsureNavAreasCache();  // ✅ 确保缓存存在
    
    for (int i = 0; i < g_NavAreasCacheCount; i++)
    {
        if (g_AllNavAreasCache.Get(i) == addr)
            return i;
    }
    
    return -1;
}

// —— 将 SpawnAttributes 的位标记转成人类可读文本 ——
// 输出示例： "EMPTY|BATTLEFIELD|OBSCURED"
static void DescribeNavFlags(int f, char[] out, int maxlen)
{
    out[0] = '\0';
    AppendFlag(out, maxlen, f, TERROR_NAV_EMPTY,             "EMPTY");
    AppendFlag(out, maxlen, f, TERROR_NAV_STOP_SCAN,         "STOP");
    AppendFlag(out, maxlen, f, TERROR_NAV_BATTLESTATION,     "BATTLESTATION");
    AppendFlag(out, maxlen, f, TERROR_NAV_FINALE,            "FINALE");
    AppendFlag(out, maxlen, f, TERROR_NAV_PLAYER_START,      "PLAYER_START");
    AppendFlag(out, maxlen, f, TERROR_NAV_BATTLEFIELD,       "BATTLEFIELD");
    AppendFlag(out, maxlen, f, TERROR_NAV_IGNORE_VISIBILITY, "IGNORE_VIS");
    AppendFlag(out, maxlen, f, TERROR_NAV_NOT_CLEARABLE,     "NOT_CLEARABLE");
    AppendFlag(out, maxlen, f, TERROR_NAV_CHECKPOINT,        "CHECKPOINT");
    AppendFlag(out, maxlen, f, TERROR_NAV_OBSCURED,          "OBSCURED");
    AppendFlag(out, maxlen, f, TERROR_NAV_NO_MOBS,           "NO_MOBS");
    AppendFlag(out, maxlen, f, TERROR_NAV_THREAT,            "THREAT");
    AppendFlag(out, maxlen, f, TERROR_NAV_RESCUE_VEHICLE,    "RESCUE_VEH");
    AppendFlag(out, maxlen, f, TERROR_NAV_RESCUE_CLOSET,     "RESCUE_CLOSET");
    AppendFlag(out, maxlen, f, TERROR_NAV_ESCAPE_ROUTE,      "ESCAPE_ROUTE");
    AppendFlag(out, maxlen, f, TERROR_NAV_DOOR,              "DOOR");
    AppendFlag(out, maxlen, f, TERROR_NAV_NOTHREAT,          "NOTHREAT");

    // 去掉可能多余的前导 '|'
    if (out[0] == '|' && out[1] == ' ') {
        strcopy(out, maxlen, out[2]);
    }
}

static void AppendFlag(char[] out, int maxlen, int f, int bit, const char[] name)
{
    if ((f & bit) == 0) return;
    if (out[0] != '\0') StrCat(out, maxlen, "|");
    StrCat(out, maxlen, name);
}

// —— Debug: 画一条一次性光束，帮助确认你指到哪 ——
// 需要已包含 <sdktools_tempents>
static void DrawAimLineOnce(int client, const float end[3])
{
    float start[3];
    GetClientEyePosition(client, start);
    TE_SetupBeamPoints(start, end, 0, 0, 0, 5, 0.7, 2.0, 2.0, 0, 0.0, {255,255,255,255}, 0);
    TE_SendToClient(client);
}
// =========================
static void StopAll()
{
    gQ.Clear();
    gST.Reset();
    if (lastSpawns != null) lastSpawns.Clear();
    recentSectors[0] = recentSectors[1] = recentSectors[2] = -1;

    g_LastSpawnOkTime = 0.0;
    g_SupportShortageStart = 0.0;
    for (int i = 0; i < 6; i++) g_LastDeathTime[i] = 0.0;
    for (int i = 0; i <= MAXPLAYERS; i++) g_LastSpawnTime[i] = 0.0;
}
static Action Timer_ApplyMaxSpecials(Handle timer)
{
    gCV.ApplyMaxZombieBound();
    return Plugin_Continue;
}
static Action Timer_ResetAtSaferoom(Handle timer)
{
    ResetMatchState();
    return Plugin_Continue;
}
static Action Timer_SpawnFirstWave(Handle timer)
{
    if (!gST.bLate)
    {
        gST.bLate = true;
        gST.hCheck    = CreateTimer(1.0, Timer_CheckSpawnWindow, _, TIMER_REPEAT);
        StartWave();
        if (gCV.bTeleport)
            gST.hTeleport = CreateTimer(1.0, Timer_TeleportTick, _, TIMER_REPEAT);
    }
    return Plugin_Stop;
}

// =========================
// 事件
// =========================
public void evt_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    StopAll();
    CreateTimer(0.1, Timer_ApplyMaxSpecials);
    CreateTimer(1.0,  Timer_ResetAtSaferoom, _, TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(2.0, Timer_RebuildBuckets, _, TIMER_FLAG_NO_MAPCHANGE); // 地图开局重建分桶
    // [新增] —— 每波开始即清理 Path 缓存（波级作用域）
    ClearPathCache();
}
public void evt_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    StopAll();
    // [新增] —— 每波开始即清理 Path 缓存（波级作用域）
    ClearPathCache();
}
public void evt_PlayerSpawn(Event event, const char[] name, bool dont_broadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!client || !IsClientInGame(client) || !IsFakeClient(client)) return;

    g_LastSpawnTime[client] = GetGameTime();     // ★ 记录出生时间
    gST.teleCount[client]   = 0;                 // ★ 清计数，避免继承旧值

    if (IsSpitter(client))
        gST.spitterSpitTime[client] = GetGameTime();
}

public void evt_AbilityUse(Event event, const char[] name, bool dont_broadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!client || !IsClientInGame(client) || !IsFakeClient(client))
        return;
    char ability[16];
    event.GetString("ability", ability, sizeof ability);
    if (strcmp(ability, "ability_spit") == 0)
        gST.spitterSpitTime[client] = GetGameTime();
}
public void evt_PlayerHurt(Event event, const char[] name, bool dont_broadcast)
{
    if (!gCV.bAddDmgSmoker) return;
    int victim   = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int dmg      = GetEventInt(event, "dmg_health");
    int evHealth = GetEventInt(event, "health");
    if (IsValidSurvivor(attacker) && IsInfectedBot(victim) && GetEntProp(victim, Prop_Send, "m_zombieClass") == view_as<int>(SI_Smoker))
    {
        int bonus = 0;
        if (GetEntPropEnt(victim, Prop_Send, "m_tongueVictim") > 0)
            bonus = dmg * 5;
        int hp = evHealth - bonus;
        if (hp < 0) hp = 0;
        SetEntityHealth(victim, hp);
        SetEventInt(event, "health", hp);
    }
}
public void evt_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsInfectedBot(client)) return;

    int zc = GetEntProp(client, Prop_Send, "m_zombieClass");
    if (zc != view_as<int>(SI_Spitter))
        CreateTimer(0.5, Timer_KickBot, client);

    if (zc >= 1 && zc <= 6)
    {
        // —— 这里改成“只在未处于冷却期时触发一次CD”，冷却中死亡不重置 —— //
        TouchDeathCooldownOnce(zc);

        int idx = zc - 1;
        if (gST.siAlive[idx] > 0) gST.siAlive[idx]--; else gST.siAlive[idx] = 0;
        if (gST.totalSI > 0) gST.totalSI--; else gST.totalSI = 0;
    }
    gST.teleCount[client] = 0;
    RecalcSiCapFromAlive(false);  // 保持：死亡后刷新剩余额度
}
static Action Timer_KickBot(Handle timer, int client)
{
    if (IsClientInGame(client) && !IsClientInKickQueue(client) && IsFakeClient(client))
    {
        KickClient(client, "SI teleport cleanup");
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

// =========================
// 波/时序
// =========================
static void StartWave()
{
    // [新增] —— 每波开始即清理 Path 缓存（波级作用域）
    ClearPathCache();
    RecalcSiCapFromAlive(true);   // 每波开始，先用“在场活着的”刷新剩余额度
    gST.survCount = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsValidSurvivor(i) && IsPlayerAlive(i))
            gST.survIdx[gST.survCount++] = i;

    gST.teleportDistCur = gCV.fTeleportSpawnMin;
    gST.spawnDistCur    = gCV.fSpawnMin;
    gST.siQueueCount   += gCV.iSiLimit;

    gST.bShouldCheck = true;
    gST.waveIndex++;
    gST.lastWaveAvgFlow = GetSurAvrFlow();
    gST.lastSpawnSecs   = 0;
    gST.lastWaveStartTime = GetGameTime();

    if (gST.siQueueCount > gCV.iSiLimit)
        gST.siQueueCount = gCV.iSiLimit;

    Debug_Print("Start wave %d", gST.waveIndex);
}
public void OnUnpause()
{
    float delay = (gST.unpauseDelay > 0.1) ? gST.unpauseDelay : 1.0;
    UnpauseSpawnTimer(delay);
}
static Action Timer_StartNewWave(Handle timer)
{
    StartWave();
    gST.hSpawn = INVALID_HANDLE;
    gST.lastWaveStartTime = GetGameTime();
    return Plugin_Stop;
}

// =========================
// CVar / 上限
// =========================
static void OnCfgChanged(ConVar convar, const char[] ov, const char[] nv)
{
    gCV.Refresh();
}
static void OnFlowBufferChanged(ConVar convar, const char[] ov, const char[] nv)
{
    // Flow 百分比变化会影响分桶 → 重建
    RebuildNavBuckets();
}
static void OnSiLimitChanged(ConVar convar, const char[] ov, const char[] nv)
{
    gCV.iSiLimit = gCV.SiLimit.IntValue;
    CreateTimer(0.1, Timer_ApplyMaxSpecials);

    // 立刻按新上限收缩记录
    CleanupLastSpawns(GetGameTime());
    gCV.Refresh();
}
static void ResetMatchState()
{
    gST.totalSI = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsInfectedBot(i) && IsPlayerAlive(i))
        {
            gST.teleCount[i] = 0;
            int zc = GetEntProp(i, Prop_Send, "m_zombieClass");
            if (zc >= 1 && zc <= 6)
            {
                gST.siAlive[zc - 1]++;
                gST.totalSI++;
            }
        }
        if (IsValidSurvivor(i) && !IsPlayerAlive(i))
            L4D_RespawnPlayer(i);
    }
    // 重置死亡记录
    g_LastSpawnOkTime = 0.0;
    g_SupportShortageStart = 0.0;
    for (int k = 0; k < 6; k++) g_LastDeathTime[k] = 0.0;
}
// 扫描在场特感 → gST.siAlive[] / gST.totalSI；再用“上限 - 活着 = 剩余额度”写回 gST.siCap[]
static void RecalcSiCapFromAlive(bool log = false)
{
    for (int i = 0; i < 6; i++) gST.siAlive[i] = 0;
    gST.totalSI = 0;

    for (int c = 1; c <= MaxClients; c++)
    {
        if (IsInfectedBot(c) && IsPlayerAlive(c))
        {
            int zc = GetEntProp(c, Prop_Send, "m_zombieClass");
            if (1 <= zc && zc <= 6)
            {
                gST.siAlive[zc - 1]++;
                gST.totalSI++;
            }
        }
    }

    int baseCap[6];
    baseCap[0] = gCV.ZSmokerLimit.IntValue;
    baseCap[1] = gCV.ZBoomerLimit.IntValue;
    baseCap[2] = gCV.ZHunterLimit.IntValue;
    baseCap[3] = gCV.ZSpitterLimit.IntValue;
    baseCap[4] = gCV.ZJockeyLimit.IntValue;
    baseCap[5] = gCV.ZChargerLimit.IntValue;

    for (int i = 0; i < 6; i++)
    {
        int remain = baseCap[i] - gST.siAlive[i];
        if (remain < 0) remain = 0;
        gST.siCap[i] = remain;
    }

    // —— 全猎/全牛：忽略各类原上限，强制该类 = l4d_infected_limit，其它类 = 0 —— //
    int forced = 0;
    if (gCV.AllHunter.BoolValue)  forced = view_as<int>(SI_Hunter);
    if (gCV.AllCharger.BoolValue) forced = view_as<int>(SI_Charger);
    if (forced != 0)
    {
        for (int i = 0; i < 6; i++) gST.siCap[i] = 0;
        int idx = forced - 1;
        int want = gCV.iSiLimit - gST.siAlive[idx];
        if (want < 0) want = 0;
        gST.siCap[idx] = want;
    }

    if (log) Debug_Print("[CAP] remain S=%d B=%d H=%d P=%d J=%d C=%d | alive S=%d B=%d H=%d P=%d J=%d C=%d | total=%d%s",
        gST.siCap[0], gST.siCap[1], gST.siCap[2], gST.siCap[3], gST.siCap[4], gST.siCap[5],
        gST.siAlive[0], gST.siAlive[1], gST.siAlive[2], gST.siAlive[3], gST.siAlive[4], gST.siAlive[5],
        gST.totalSI,
        (forced!=0) ? " [forced mode]" : "");
}
static void ReadSiCap()
{
    gST.siCap[0] = gCV.ZSmokerLimit.IntValue;
    gST.siCap[1] = gCV.ZBoomerLimit.IntValue;
    gST.siCap[2] = gCV.ZHunterLimit.IntValue;
    gST.siCap[3] = gCV.ZSpitterLimit.IntValue;
    gST.siCap[4] = gCV.ZJockeyLimit.IntValue;
    gST.siCap[5] = gCV.ZChargerLimit.IntValue;

    // —— 全猎/全牛：强制把该类上限改成 l4d_infected_limit，其它类清 0 —— //
    int forced = 0;
    if (gCV.AllHunter.BoolValue)  forced = view_as<int>(SI_Hunter);
    if (gCV.AllCharger.BoolValue) forced = view_as<int>(SI_Charger);
    if (forced != 0)
    {
        for (int i = 0; i < 6; i++) gST.siCap[i] = 0;
        int idx = forced - 1;
        int want = gCV.iSiLimit - gST.siAlive[idx];
        if (want < 0) want = 0;
        gST.siCap[idx] = want;
    }

    Debug_Print("[CAP] caps S=%d B=%d H=%d P=%d J=%d C=%d%s",
        gST.siCap[0], gST.siCap[1], gST.siCap[2], gST.siCap[3], gST.siCap[4], gST.siCap[5],
        (forced!=0) ? " [forced mode]" : "");
}

// =========================
// 帧驱动
// =========================
public void OnGameFrame()
{
    if (gCV.iSiLimit > gCV.MaxPlayerZombies.IntValue)
        CreateTimer(0.1, Timer_ApplyMaxSpecials);

    float now = GetGameTime();
    if (now < gST.nextFrameThink)
        return;
    gST.nextFrameThink = now + FRAME_THINK_STEP;

    if (gST.totalSI >= gCV.iSiLimit)
        return;

    MaintainSpawnQueueOnce();

    if (!gST.bLate)
        return;

    if (gST.teleportQueueSize > 0 && gST.totalSI < gCV.iSiLimit)
    {
        TryTeleportSpawnOnce();
        return;
    }

    if (gST.siQueueCount > 0 && gST.spawnQueueSize > 0 && gST.totalSI < gCV.iSiLimit)
    {
        TryNormalSpawnOnce();
    }
}

// -------------------------
// 队列维护 & 选类规则（更新）
// -------------------------
static bool IsKillerClassInt(int zc)
{
    return  zc == view_as<int>(SI_Hunter) || zc == view_as<int>(SI_Jockey) || zc == view_as<int>(SI_Charger) || zc == view_as<int>(SI_Smoker);
}
static bool IsSupportClassInt(int zc)
{
    return zc == view_as<int>(SI_Boomer) || zc == view_as<int>(SI_Spitter);
}
static bool IsSupportGateClassInt(int zc)
{
    return zc == view_as<int>(SI_Smoker)
        || zc == view_as<int>(SI_Boomer)
        || zc == view_as<int>(SI_Spitter);
}
static bool IsPriorityUnlockClassInt(int zc)
{
    return zc == view_as<int>(SI_Hunter)
        || zc == view_as<int>(SI_Jockey)
        || zc == view_as<int>(SI_Charger);
}
static int CountKillersAlive()
{
    return gST.siAlive[view_as<int>(SI_Smoker)-1]
         + gST.siAlive[view_as<int>(SI_Hunter)-1]
         + gST.siAlive[view_as<int>(SI_Jockey)-1]
         + gST.siAlive[view_as<int>(SI_Charger)-1];
}
static int CountKillersQueued()
{
    int c = 0;
    for (int i = 0; i < gQ.spawn.Length; i++)
    {
        int t = gQ.spawn.Get(i);
        if (IsKillerClassInt(t)) c++;
    }
    return c;
}
static int CountPriorityUnlockersAlive()
{
    return gST.siAlive[view_as<int>(SI_Hunter)-1]
         + gST.siAlive[view_as<int>(SI_Jockey)-1]
         + gST.siAlive[view_as<int>(SI_Charger)-1];
}
static int CountPriorityUnlockersQueued()
{
    int total = 0;
    for (int i = 0; i < gQ.spawn.Length; i++)
    {
        int t = gQ.spawn.Get(i);
        if (IsPriorityUnlockClassInt(t))
            total++;
    }
    return total;
}
static int GetSupportUnlockNeed()
{
    int req = gCV.iSupportUnlockKillers;
    if (req == 0)
        return 0;

    if (req < 0)
    {
        if (gCV.fSupportUnlockRatio <= 0.0)
            return 0;

        req = RoundToFloor(float(gCV.iSiLimit) * gCV.fSupportUnlockRatio);
    }

    if (req < 0) req = 0;
    return req;
}
static bool SupportRestrictionActive()
{
    int need = GetSupportUnlockNeed();
    if (need <= 0)
    {
        g_SupportShortageStart = 0.0;
        return false;
    }

    int have = CountPriorityUnlockersAlive() + CountPriorityUnlockersQueued();
    if (have >= need)
    {
        g_SupportShortageStart = 0.0;
        return false;
    }

    float grace = gCV.fSupportUnlockGrace;
    if (grace > 0.0)
    {
        float now = GetGameTime();
        if (g_SupportShortageStart <= 0.0)
            g_SupportShortageStart = now;
        else if ((now - g_SupportShortageStart) >= grace)
            return false;
    }
    else
    {
        g_SupportShortageStart = 0.0;
    }

    return true;
}

// 让“是否存在可入队的杀手类”也考虑死亡CD或放宽逻辑
static bool AnyEligibleKillerToQueue()
{
    static int ks[4] = { view_as<int>(SI_Smoker), view_as<int>(SI_Hunter), view_as<int>(SI_Jockey), view_as<int>(SI_Charger) };
    bool relax = ShouldRelaxDeathCD();
    bool supportLocked = SupportRestrictionActive();
    for (int i = 0; i < 4; i++)
    {
        int k = ks[i];
        if (!CheckClassEnabled(k) || !CanQueueClass(k) )
            continue;
        if (!relax && !PassDeathCooldown(k))
            continue;
        if (supportLocked && IsSupportGateClassInt(k))
            continue;
        return true;
    }
    return false;
}

// 被 MaintainSpawnQueueOnce() 调用的挑选函数（优先在杀手类里随机挑一个满足条件的）
static int PickEligibleKillerClass()
{
    static int ks[4] = { view_as<int>(SI_Smoker), view_as<int>(SI_Hunter), view_as<int>(SI_Jockey), view_as<int>(SI_Charger) };
    bool relax = ShouldRelaxDeathCD();
    bool supportLocked = SupportRestrictionActive();

    // 随机尝试若干次，先走随机
    for (int tries = 0; tries < 8; tries++)
    {
        int k = ks[GetRandomInt(0, 3)];
        if (!CheckClassEnabled(k) || HasReachedLimit(k))
            continue;
        if (!relax && !PassDeathCooldown(k))
            continue;
        if (supportLocked && IsSupportGateClassInt(k))
            continue;
        return k;
    }

    // 兜底：线性扫一遍
    for (int i = 0; i < 4; i++)
    {
        int k = ks[i];
        if (CheckClassEnabled(k) && !HasReachedLimit(k) && (relax || PassDeathCooldown(k))
            && (!supportLocked || !IsSupportGateClassInt(k)))
            return k;
    }
    return 0;
}
// —— 新增：死亡CD判断 —— //
static bool PassDeathCooldown(int zc)
{
    if (zc < 1 || zc > 6) return true;
    float now = GetGameTime();
    float last = g_LastDeathTime[zc - 1];
    if (last <= 0.01) return true;

    float need = IsSupportClassInt(zc) ? gCV.fDeathCDSupport : gCV.fDeathCDKiller;
    return (now - last) >= need;
}

// 仅在“无活动冷却”时开启一次死亡CD；若已在CD中则忽略本次死亡
static void TouchDeathCooldownOnce(int zc)
{
    int idx = zc - 1;
    if (idx < 0 || idx >= 6) return;

    float need = IsSupportClassInt(zc) ? gCV.fDeathCDSupport : gCV.fDeathCDKiller;
    if (need <= 0.01)
    {
        // 冷却为 0 时不做限制；保持可立即补位
        g_LastDeathTime[idx] = 0.0;
        return;
    }

    float now  = GetGameTime();
    float last = g_LastDeathTime[idx];

    // 若从未启动过，或上一个冷却已结束 → 以“本次死亡”启动新的冷却
    if (last <= 0.01 || (now - last) >= need)
    {
        g_LastDeathTime[idx] = now;
        Debug_Print("[DEATHCD] start %s at %.2f (CD=%.2f)", INFDN[zc], now, need);
    }
    else
    {
        // 仍在冷却期：忽略，不刷新时间戳（不把CD往后推）
        Debug_Print("[DEATHCD] ignore %s death at %.2f (remain=%.2f)",
            INFDN[zc], now, need - (now - last));
    }
}

// —— 新增：是否放宽CD（永不饿死双保险） —— //
static bool ShouldRelaxDeathCD()
{
    float now = GetGameTime();

    // 1) 最近无成功刷出超过阈值（防饿死）
    if (gCV.fDeathCDBypassAfter > 0.01
        && (g_LastSpawnOkTime <= 0.01 || (now - g_LastSpawnOkTime) >= gCV.fDeathCDBypassAfter))
        return true;

    // 2) 场上活着数低于“下限保有量”
    float uf = gCV.fDeathCDUnderfill;
    if (uf < 0.0) uf = 0.0;
    if (uf > 1.0) uf = 1.0;
    int floorAlive = RoundToCeil(float(gCV.iSiLimit) * uf);
    if (floorAlive < 1) floorAlive = 1;

    if (gST.totalSI < floorAlive)
        return true;

    return false;
}

// —— 新增：稀缺度优先选类（两遍：严格CD → 放宽CD） —— //
static int PickScarceClass()
{
    int pick = PickScarceClassImpl(/*relaxCD=*/false);
    if (pick == 0 && ShouldRelaxDeathCD())
        pick = PickScarceClassImpl(/*relaxCD=*/true);
    return pick;
}
static int PickScarceClassImpl(bool relaxCD)
{
    float bestScore = 9999.0;
    int bestZc = 0;
    bool supportLocked = SupportRestrictionActive();

    for (int zc = 1; zc <= 6; zc++)
    {
        if (!CheckClassEnabled(zc))    continue;
        if (!CanQueueClass(zc))        continue;
        if (!relaxCD && !PassDeathCooldown(zc)) continue;
        if (supportLocked && IsSupportGateClassInt(zc)) continue;

        int idx      = zc - 1;
        int alive    = gST.siAlive[idx];
        int capTotal = alive + gST.siCap[idx];
        if (capTotal <= 0) continue;

        // 稀缺度：alive / (alive + remain)，越小越稀缺
        float ratio = float(alive) / float(capTotal);

        // 刷新开头给杀手类一点优先（小幅）
        if (gST.lastSpawnSecs < SUPPORT_SPAWN_DELAY_SECS && IsKillerClassInt(zc))
            ratio -= 0.05;

        if (ratio < bestScore)
        {
            bestScore = ratio;
            bestZc = zc;
        }
    }
    return bestZc;
}

// -------------------------
// 队列维护 & 选类规则（修复版）
// -------------------------
static void MaintainSpawnQueueOnce()
{
    RecalcSiCapFromAlive(false);  // 入队前刷新“剩余额度”
    if (gST.spawnQueueSize >= gCV.iSiLimit) return;

    int zc = 0;
    bool relax = ShouldRelaxDeathCD();  // 是否放宽死亡CD
    bool supportLocked = SupportRestrictionActive();

    // 模式锁定
    if (gCV.AllCharger.BoolValue)      zc = view_as<int>(SI_Charger);
    else if (gCV.AllHunter.BoolValue)  zc = view_as<int>(SI_Hunter);

    // 稀缺度优先（默认）
    if (zc == 0)
        zc = PickScarceClass();

    // 若仍未挑到（比如所有类都临时不适合），则按旧策略兜底
    if (zc == 0)
    {
        float waveAge    = float(gST.lastSpawnSecs);
        int killersNow   = CountKillersAlive() + CountKillersQueued();
        bool preferKiller= (waveAge < SUPPORT_SPAWN_DELAY_SECS
                           && killersNow < SUPPORT_NEED_KILLERS
                           && AnyEligibleKillerToQueue());
        if (preferKiller)
            zc = PickEligibleKillerClass();

        // 【修复点 #1】随机兜底分支在不放宽时也过滤死亡CD
        if (zc == 0)
        {
            for (int tries = 0; tries < 8; tries++)
            {
                int pick = GetRandomInt(1, 6);
                if (!CheckClassEnabled(pick) || !CanQueueClass(pick))
                    continue;
                if (!relax && !PassDeathCooldown(pick)) // ★ 不放宽时跳过处于CD的类
                    continue;
                if (supportLocked && IsSupportGateClassInt(pick))
                    continue;

                zc = pick;
                break;
            }
        }
    }

    // 入队前的最终资格判断 + CD处理
    if (zc != 0 && CanQueueClass(zc) && CheckClassEnabled(zc))
    {
        // 【修复点 #2】当稀缺度/兜底挑中的类处于CD，且当前不放宽时，尝试一次“替补”
        if (!PassDeathCooldown(zc) && !relax)
        {
            int alt = PickEligibleKillerClass(); // 已内部考虑CD/放宽

            // 仍找不到就再做一轮“非杀手限定”的随机替补（不放宽时必须通过CD）
            if (alt == 0)
            {
                for (int tries = 0; tries < 8; tries++)
                {
                    int p = GetRandomInt(1, 6);
                    if (!CheckClassEnabled(p) || !CanQueueClass(p))
                        continue;
                    if (!PassDeathCooldown(p)) // relax 为 false，此处必须通过CD
                        continue;
                    if (supportLocked && IsSupportGateClassInt(p))
                        continue;

                    alt = p;
                    break;
                }
            }

            if (alt == 0)
            {
                Debug_Print("<SpawnQ> no eligible class (CD on %s) -> wait", INFDN[zc]);
                return; // 本帧确实无可用类，等待下一帧
            }

            Debug_Print("<SpawnQ> substitute %s -> %s (CD active on original)", INFDN[zc], INFDN[alt]);
            zc = alt; // 用替补继续入队
        }

        if (supportLocked && IsSupportGateClassInt(zc))
        {
            int alt2 = PickEligibleKillerClass();
            if (alt2 == 0)
            {
                Debug_Print("<SpawnQ> support %s locked (need killers) -> wait", INFDN[zc]);
                return;
            }

            Debug_Print("<SpawnQ> substitute %s -> %s (support locked)", INFDN[zc], INFDN[alt2]);
            zc = alt2;
        }

        // 入队
        gQ.spawn.Push(zc);
        gST.spawnQueueSize++;
        Debug_Print("<SpawnQ> +%s size=%d", INFDN[zc], gST.spawnQueueSize);
    }
}


// =========================
// 修改 BuildNavIdIndexMap（简化）
// =========================
static void BuildNavIdIndexMap()
{
    if (g_NavIdToIndex != null) { delete g_NavIdToIndex; g_NavIdToIndex = null; }
    g_NavIdToIndex = new StringMap();
    
    EnsureNavAreasCache();  // ✅ 确保缓存存在
    
    for (int i = 0; i < g_NavAreasCacheCount; i++)
    {
        Address area = g_AllNavAreasCache.Get(i);
        int navid = L4D_GetNavAreaID(area);
        if (navid < 0) continue;
        
        char key[16]; 
        IntToString(navid, key, sizeof key);
        g_NavIdToIndex.SetValue(key, view_as<any>(i));
    }
}
static int GetAreaIndexByNavID_Int(int navid)
{
    if (g_NavIdToIndex == null) BuildNavIdIndexMap();
    char key[16]; IntToString(navid, key, sizeof key);
    any idx;
    return g_NavIdToIndex.GetValue(key, idx) ? view_as<int>(idx) : -1;
}
static void MakeBucketCachePath()
{
    char map[64];
    GetCurrentMap(map, sizeof map);
    char dir[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, dir, sizeof dir, "data/infd_buckets");
    CreateDirectory(dir, 511);
    BuildPath(Path_SM, g_sBucketCachePath, sizeof g_sBucketCachePath, "data/infd_buckets/%s.kv", map);
}

// ===========================
// 单次正常生成尝试（fdxx-NavArea 主路）
// ===========================
// ===========================
// 单次正常生成尝试（fdxx-NavArea 主路）— 改：DoSpawnAt 失败给 NavArea 短冷却
// ===========================
static void TryNormalSpawnOnce()
{
    static const float EPS_RADIUS = 1.0;
    if (gST.spawnQueueSize <= 0)
        return;

    int want = 0;
    while (gST.spawnQueueSize > 0)
    {
        want = gQ.spawn.Get(0);
        if (!IsSupportGateClassInt(want) || !SupportRestrictionActive())
            break;

        Debug_Print("[QUEUE DROP] support %s blocked (need killers)", INFDN[want]);
        gQ.spawn.Erase(0);
        gST.spawnQueueSize--;
    }

    if (gST.spawnQueueSize <= 0)
        return;

    // 生成前“只看活着的”上限闸门
    if (HasReachedLimit(want))
    {
        Debug_Print("[SPAWN DROP] class=%s reached alive-cap, drop head", INFDN[want]);
        gQ.spawn.Erase(0);
        gST.spawnQueueSize--;
        return;
    }

    // 死亡CD：若队头处于死亡CD且当前不放宽，则旋转到末尾
    if (!PassDeathCooldown(want) && !ShouldRelaxDeathCD())
    {
        gQ.spawn.Erase(0);
        gQ.spawn.Push(want);
        Debug_Print("[QUEUE ROTATE] %s under death-cooldown, rotate to tail", INFDN[want]);
        return;
    }

    bool isSupport = (want == view_as<int>(SI_Boomer) || want == view_as<int>(SI_Spitter));

    float pos[3];
    int areaIdx = -1;
    float ring = gST.spawnDistCur;

    float maxR = gCV.fSpawnMax;
    if (isSupport && SUPPORT_EXPAND_MAX < maxR)
        maxR = SUPPORT_EXPAND_MAX;
    // [ADD] 本地 best 调试包
    SpawnScoreDbg bestDbg;
    bool ok = FindSpawnPosViaNavArea(want, gST.targetSurvivor, ring, false, pos, areaIdx, bestDbg);

    if (ok && IsPosVisibleSDK(pos, false)) { ok = false; }

    bool triedSpawn = false;
    bool spawnOk = false;

    if (ok)
    {
        triedSpawn = true;
        spawnOk = DoSpawnAt(pos, want);
    }

    if (ok && spawnOk)
    {
        LogChosenSpawnScore(want, bestDbg);
        // 分散度：成功后记录冷却与最近刷点
        if (areaIdx >= 0) TouchNavCooldown(areaIdx, GetGameTime(), NAV_CD_SECS);
        float center[3]; GetSectorCenter(center, gST.targetSurvivor);
        RememberSpawn(pos, center);

        gST.siQueueCount--;
        gST.siAlive[want - 1]++; gST.totalSI++;
        gQ.spawn.Erase(0);        gST.spawnQueueSize--;

        BypassAndExecuteCommand("nb_assault");

        float nextStart = ring * 0.7;
        if (nextStart < gCV.fSpawnMin) nextStart = gCV.fSpawnMin;
        if (nextStart > gCV.fSpawnMax) nextStart = gCV.fSpawnMax;
        gST.spawnDistCur = nextStart;

        Debug_Print("[SPAWN] success ring=%.1f -> nextStart=%.1f", ring, gST.spawnDistCur);
        return;
    }
    else
    {
        // —— 新增：若确实调用了 DoSpawnAt 且失败，并且拿到了 NavArea 编号，则给该 Area 一个短失败冷却 —— //
        if (triedSpawn && !spawnOk && areaIdx >= 0)
            TouchNavCooldown(areaIdx, GetGameTime(), 0.8);
    }

    // 扩圈
    float nextR = gST.spawnDistCur + LOW_SCORE_EXPAND;
    if (nextR > maxR) nextR = maxR;
    gST.spawnDistCur = nextR;

    Debug_Print("[SPAWN] expand -> %.1f (max=%.1f) class=%s", gST.spawnDistCur, maxR, INFDN[want]);

    // —— 到达最大半径：触发“最大距离兜底” —— //
    if (gST.spawnDistCur + EPS_RADIUS >= maxR)
    {
        float pt[3];
        if (FallbackDirectorPosAtMax(want, gST.targetSurvivor, /*teleportMode=*/false, pt) && DoSpawnAt(pt, want))
        {
            // 兜底不绑定具体 NavArea，记录坐标分散度即可
            float center[3]; GetSectorCenter(center, gST.targetSurvivor);
            RememberSpawn(pt, center);

            gST.siQueueCount--;
            gST.siAlive[want - 1]++; gST.totalSI++;
            gQ.spawn.Erase(0);        gST.spawnQueueSize--;

            BypassAndExecuteCommand("nb_assault");

            gST.spawnDistCur *= 0.8; // 兜底后略收缩
            Debug_Print("[SPAWN] fallback@max success");
        }
        else
        {
            Debug_Print("[SPAWN FAIL] fallback@max failed class=%s", INFDN[want]);
        }
    }
}


// ===========================
// 单次传送尝试（fdxx-NavArea 主路）
// ===========================
static void TryTeleportSpawnOnce()
{
    static const float EPS_RADIUS = 1.0;

    int want = gQ.teleport.Get(0);
    if (gST.totalSI >= gCV.iSiLimit || HasReachedLimit(want))
        return;

    float pos[3];
    int areaIdx = -1;
    float ring = gST.teleportDistCur;
    float maxR = gCV.fSpawnMax;
    // [ADD] 本地 best 调试包
    SpawnScoreDbg bestDbg;
    bool ok = FindSpawnPosViaNavArea(want, gST.targetSurvivor, ring, true, pos, areaIdx, bestDbg);

    if (ok && IsPosVisibleSDK(pos, true)) { ok = false; }

    bool triedSpawn = false;
    bool spawnOk = false;

    if (ok)
    {
        triedSpawn = true;
        spawnOk = DoSpawnAt(pos, want);
    }

    if (ok && spawnOk)
    {
        LogChosenSpawnScore(want, bestDbg);
        if (areaIdx >= 0) TouchNavCooldown(areaIdx, GetGameTime(), NAV_CD_SECS);
        float center[3]; GetSectorCenter(center, gST.targetSurvivor);
        RememberSpawn(pos, center);

        gST.siAlive[want - 1]++; gST.totalSI++;
        gQ.teleport.Erase(0);    gST.teleportQueueSize--;

        float nextTP = ring * 0.8;
        if (nextTP < gCV.fSpawnMin) nextTP = gCV.fSpawnMin;
        if (nextTP > gCV.fSpawnMax) nextTP = gCV.fSpawnMax;
        gST.teleportDistCur = nextTP;

        if (gST.teleportQueueSize == 0)
            gST.teleportDistCur = gCV.fSpawnMin;

        Debug_Print("[TP] success ring=%.1f -> nextStart=%.1f", ring, gST.teleportDistCur);
        return;
    }
    else
    {
        // —— 新增：若确实调用了 DoSpawnAt 且失败，并且拿到了 NavArea 编号，则给该 Area 一个短失败冷却 —— //
        if (triedSpawn && !spawnOk && areaIdx >= 0)
            TouchNavCooldown(areaIdx, GetGameTime(), 0.8);
    }

    // 扩圈
    float nextR = gST.teleportDistCur + LOW_SCORE_EXPAND;
    if (nextR > maxR) nextR = maxR;
    gST.teleportDistCur = nextR;

    Debug_Print("[TP] expand -> %.1f (max=%.1f) class=%s", gST.teleportDistCur, maxR, INFDN[want]);

    // —— 到达最大半径：触发“最大距离兜底” —— //
    if (gST.teleportDistCur + EPS_RADIUS >= maxR)
    {
        float pt[3];
        if (FallbackDirectorPosAtMax(want, gST.targetSurvivor, /*teleportMode=*/true, pt) && DoSpawnAt(pt, want))
        {
            float center[3]; GetSectorCenter(center, gST.targetSurvivor);
            RememberSpawn(pt, center);

            gST.siAlive[want - 1]++; gST.totalSI++;
            gQ.teleport.Erase(0);    gST.teleportQueueSize--;

            gST.teleportDistCur = FloatMax(gCV.fSpawnMin, gST.teleportDistCur * 0.7);
            Debug_Print("[TP] fallback@max success, ring now %.1f", gST.teleportDistCur);
        }
        else
        {
            Debug_Print("[TP FAIL] fallback@max failed class=%s", INFDN[want]);
        }
    }
}


// =========================
// Anti-bait 定时器 / 波时序（去掉梯子相关）
// =========================
static Action Timer_CheckSpawnWindow(Handle timer)
{
    if (g_bPauseLib && IsInPause())
    {
        if (gST.hSpawn != INVALID_HANDLE)
        {
            gST.unpauseDelay = gCV.fSiInterval - (GetGameTime() - gST.lastWaveStartTime);
            KillTimer(gST.hSpawn);
            gST.hSpawn = INVALID_HANDLE;
        }
        return Plugin_Continue;
    }

    gST.lastSpawnSecs++;
    if (!gST.bLate) return Plugin_Stop;

    if (!gST.bShouldCheck || gST.hSpawn != INVALID_HANDLE) return Plugin_Continue;

    if (FindConVar("survivor_limit").IntValue >= 2 && IsAnyTankOrAboveHalfSurvivorDownOrDied(1) && gST.lastSpawnSecs < RoundToFloor(gCV.fSiInterval / 2))
        return Plugin_Continue;

    if (!gCV.bAutoSpawn)
    {
        if (gST.siQueueCount == gCV.iSiLimit)
        {
            gST.lastSpawnSecs = 0;
        }
        else
        {
            gST.bShouldCheck = false;
            gST.hSpawn = CreateTimer(gCV.fSiInterval * 1.5, Timer_StartNewWave);
        }
    }
    else if ((IsAllKillersDown() && gST.siQueueCount == 0) || (gST.totalSI <= (RoundToFloor(gCV.iSiLimit / 4.0) + 1) && gST.siQueueCount == 0) || (gST.lastSpawnSecs >= gCV.fSiInterval * 0.5))
    {
        if (gST.siQueueCount == gCV.iSiLimit)
        {
            gST.lastSpawnSecs = 0;
        }
        else
        {
            gST.bShouldCheck = false;
            gST.hSpawn = CreateTimer(gCV.fSiInterval, Timer_StartNewWave);
        }
    }

    return Plugin_Continue;
}
static void PauseSpawnTimer()
{
    if (gST.hSpawn != INVALID_HANDLE)
    {
        gST.unpauseDelay = gCV.fSiInterval - (GetGameTime() - gST.lastWaveStartTime);
        KillTimer(gST.hSpawn);
        gST.hSpawn = INVALID_HANDLE;
        Debug_Print("Pause spawn timer, resume after %.2f", gST.unpauseDelay);
    }
}
static void UnpauseSpawnTimer(float delay)
{
    if (gST.hSpawn == INVALID_HANDLE)
    {
        gST.hSpawn = CreateTimer(delay, Timer_StartNewWave);
        Debug_Print("Resume spawn in %.2f", delay);
    }
}

// 每秒轻量刷新一次“最后一次有效团队进度”(0..100)
// 设计：至少有1名生还者拿到有效进度才更新；无效则保持旧值不变。
static void RefreshLastGoodSurPctTick()
{
    if (!gCV.bSurFlowFallback) return;

    int n = 0;
    float sum = 0.0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidSurvivor(i) || !IsPlayerAlive(i))
            continue;

        int pct;
        if (TryGetClientFlowPercentSafe(i, pct))
        {
            sum += float(pct);
            n++;
        }
    }

    if (n > 0)
    {
        int avgPct = RoundToNearest(sum / float(n));
        TouchLastGoodSurPctFromAverage(avgPct);  // 会自动记录 g_LastGoodSurPct 与时间戳
    }
    // n==0: 所有人都拿不到进度 → 不更新，沿用旧值直到 TTL 过期
}

// ===========================
// 传送监督（1s）— 加入“出生宽限 + 跑男最小不可见秒数”
// 依赖：g_LastSpawnTime[]、gCV.fTeleportSpawnGrace、gCV.fTeleportRunnerFast（若未加 CVar，也可设默认值为 0.0）
// ===========================
static Action Timer_TeleportTick(Handle timer)
{
    if (g_bPauseLib && IsInPause())
        return Plugin_Continue;
    // ★ 每秒刷新一次团队平均进度（用于 SurProgressFallback）
    RefreshLastGoodSurPctTick();

    // 全队被控或倒地：暂停传送监督
    if (CheckRushManAndAllPinned())
        return Plugin_Continue;

    float now = GetGameTime();

    for (int c = 1; c <= MaxClients; c++)
    {
        // 基本资格
        if (!CanBeTeleport(c))
            continue;

        // —— 出生宽限（避免“刚生成就传送”）——
        // 若你尚未把宽限接到 CanBeTeleport，这里再兜一层
        if (gCV.fTeleportSpawnGrace > 0.0)
        {
            float born = g_LastSpawnTime[c];  // 需要在 evt_PlayerSpawn 中记录
            if (born > 0.0 && (now - born) < gCV.fTeleportSpawnGrace)
            {
                // 宽限期内不累计不可见秒数，重置计数防止溢出
                if (gST.teleCount[c] != 0) gST.teleCount[c] = 0;
                continue;
            }
        }

        // 视线检测（以“眼睛”为目标点，与 IsPosVisibleSDK 的口径一致）
        float eyes[3];
        GetClientEyePosition(c, eyes);
        bool vis = IsPosVisibleSDK(eyes, true);

        if (!vis)
        {
            // 第一次入队前，重置传送找点半径
            if (gST.teleportQueueSize == 0)
                gST.teleportDistCur = gCV.fSpawnMin;

            // Smoker 能力未就绪则不传（避免浪费），并清空计数
            int zc = GetInfectedClass(c);
            if (zc == view_as<int>(SI_Smoker) && g_bSmokerLib)
            {
                if (!isSmokerReadyToAttack(c))
                {
                    if (gST.teleCount[c] % 5 == 0)
                        LogMsg("[TP] smoker %N: ability not ready -> skip teleport (tick=%d)", c, gST.teleCount[c]);
                    gST.teleCount[c] = 0;
                    continue;
                }
            }

            // —— 累计不可见秒数（本计时器 1s 调一次）——
            gST.teleCount[c]++;

            // 计算本次需要的不可见阈值（秒）
            // 常规：iTeleportCheckTime；跑男快通道：min(常规, TeleportRunnerFast)，但不低于 0.8s
            float needSecs = float(gCV.iTeleportCheckTime);
            bool  runnerFastPath = (gST.bPickRushMan && gST.teleportQueueSize == 0);
            if (runnerFastPath && gCV.fTeleportRunnerFast > 0.0)
            {
                if (gCV.fTeleportRunnerFast < needSecs)
                    needSecs = gCV.fTeleportRunnerFast;
            }
            if (needSecs < 0.8) needSecs = 0.8; // 防止“闪现即传”

            // 达标：进入传送队列
            if (float(gST.teleCount[c]) >= needSecs)
            {
                int zcx = GetInfectedClass(c);
                if (zcx >= 1 && zcx <= 6)
                {
                    gQ.teleport.Push(zcx);
                    gST.teleportQueueSize++;

                    // 从“在场计数”里扣除（保持与原逻辑一致）
                    if (gST.siAlive[zcx-1] > 0) gST.siAlive[zcx-1]--; else gST.siAlive[zcx-1] = 0;
                    if (gST.totalSI > 0) gST.totalSI--; else gST.totalSI = 0;

                    LogMsg("[TP] %N class=%s invisible for %.1f sec%s -> teleport respawn",
                           c, INFDN[zcx], float(gST.teleCount[c]),
                           runnerFastPath ? " (runner-fast)" : "");

                    // 踢掉原实体，进入传送重生流程
                    KickClient(c, "Teleport SI");

                    // 立刻刷新上限/剩余额度
                    RecalcSiCapFromAlive(false);

                    // 清零计数，避免残留
                    gST.teleCount[c] = 0;
                }
            }
        }
        else
        {
            // 再次可见：每 5s 打一条复位日志，并清零计数
            if (gST.teleCount[c] > 0 && (gST.teleCount[c] % 5 == 0))
                LogMsg("[TP] %N visible again (reset tick=%d)", c, gST.teleCount[c]);

            gST.teleCount[c] = 0;
        }
    }

    // 周期性刷新目标幸存者
    gST.targetSurvivor = ChooseTargetSurvivor();

    return Plugin_Continue;
}


// =========================
// 资格/可传送
// =========================
static bool IsInfectedBot(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client)
           && GetClientTeam(client) == TEAM_INFECTED && (GetEntProp(client, Prop_Send, "m_zombieClass") >= 1 && GetEntProp(client, Prop_Send, "m_zombieClass") <= 6);
}
/**
* 检查 Smoker 技能是否冷却完毕
* @param client 客户端索引
* @return bool 是否冷却完毕
**/
stock bool isSmokerReadyToAttack(int client) {
	if (!IsAiSmoker(client))
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
static bool IsValidClient(int c) { return c > 0 && c <= MaxClients && IsClientInGame(c); }
static bool IsValidSurvivor(int c) { return IsValidClient(c) && GetClientTeam(c) == TEAM_SURVIVOR; }
static bool IsSpitter(int client)
{
    return IsInfectedBot(client) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == view_as<int>(SI_Spitter);
}
static int  GetInfectedClass(int client) { return GetEntProp(client, Prop_Send, "m_zombieClass"); }
static bool IsGhost(int client) { return IsValidClient(client) && view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost")); }

static bool IsAiSmoker(int c)
{
    return c && c <= MaxClients && IsClientInGame(c) && IsPlayerAlive(c) && IsFakeClient(c)
        && GetClientTeam(c) == TEAM_INFECTED && GetEntProp(c, Prop_Send, "m_zombieClass") == view_as<int>(SI_Smoker) && !IsGhost(c);
}
static bool IsAiTank(int c)
{
    return c && c <= MaxClients && IsClientInGame(c) && IsPlayerAlive(c) && IsFakeClient(c)
        && GetClientTeam(c) == TEAM_INFECTED && GetEntProp(c, Prop_Send, "m_zombieClass") == 8 && !IsGhost(c);
}
static bool IsPinned(int client)
{
    if (!(IsValidSurvivor(client) && IsPlayerAlive(client))) return false;
    return GetEntPropEnt(client, Prop_Send, "m_tongueOwner")   > 0
        || GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0
        || GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker")> 0
        || GetEntPropEnt(client, Prop_Send, "m_pounceAttacker")> 0
        || GetEntPropEnt(client, Prop_Send, "m_pummelAttacker")> 0;
}
static bool IsPinningSomeone(int client)
{
    if (!IsInfectedBot(client)) return false;
    return GetEntPropEnt(client, Prop_Send, "m_tongueVictim") > 0
        || GetEntPropEnt(client, Prop_Send, "m_jockeyVictim") > 0
        || GetEntPropEnt(client, Prop_Send, "m_pounceVictim") > 0
        || GetEntPropEnt(client, Prop_Send, "m_pummelVictim") > 0
        || GetEntPropEnt(client, Prop_Send, "m_carryVictim")  > 0;
}
static float GetClosestSurvivorDistance(int client)
{
    float p[3]; GetClientAbsOrigin(client, p);
    float best = 999999.0, s[3];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidSurvivor(i) || !IsPlayerAlive(i)) continue;
        GetClientAbsOrigin(i, s);
        float d = GetVectorDistance(p, s);
        if (d < best) best = d;
    }
    return best;
}
static bool CanBeTeleport(int client)
{
    if (!IsInfectedBot(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
        return false;
    if (GetEntProp(client, Prop_Send, "m_zombieClass") == 8)  // Tank
        return false;
    if (IsPinningSomeone(client))
        return false;

    // ★ 新增：出生宽限（统一闸门）
    if (gCV.fTeleportSpawnGrace > 0.0)
    {
        float born = g_LastSpawnTime[client];
        if (born > 0.0 && (GetGameTime() - born) < gCV.fTeleportSpawnGrace)
            return false;
    }

    if (IsSpitter(client) && (GetGameTime() - gST.spitterSpitTime[client]) < SPIT_INTERVAL)
        return false;

    if (GetClosestSurvivorDistance(client) < gCV.fSpawnMin)
        return false;

    if (IsAiSmoker(client) && g_bSmokerLib && !isSmokerReadyToAttack(client))
        return false;

    float p[3];
    GetClientAbsOrigin(client, p);
    if (IsPosAheadOfHighest(p))
        return false;

    return true;
}

// 工具：从 src 到 dst 的可视（只认“既挡视线又挡子弹”的阻挡）
static bool RayClear(const float src[3], const float dst[3], int mask)
{
    Handle tr = TR_TraceRayFilterEx(src, dst, mask, RayType_EndPoint, TraceFilter);
    bool ok = (!TR_DidHit(tr) || TR_GetFraction(tr) >= 0.99);
    delete tr;
    return ok;
}

static bool IsPosVisibleSDK(float pos[3], bool teleportMode)
{
    float head[3];
    head[0] = pos[0]; head[1] = pos[1]; head[2] = pos[2] + 62.0;

    float chest[3];
    chest[0] = pos[0]; chest[1] = pos[1]; chest[2] = pos[2] + 32.0;

    const int visMask = (MASK_VISIBLE & MASK_SHOT);
    const float SIDE = 16.0;

    // 计算“有效射线模式”
    // 0 = 仅中线；1 = 三线；2 = 自动（>4生还者→仅中线，否则三线）
    int effMode = gCV.iVisRayMode;
    if (effMode == 2)
        effMode = (CountAliveSurvivors() > 4) ? 0 : 1;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || !IsPlayerAlive(i))
            continue;
        if (teleportMode && L4D_IsPlayerIncapacitated(i) && gCV.bIgnoreIncapSight)
            continue;

        float eyes[3];
        GetClientEyePosition(i, eyes);

        // 先试“中线 → 头”
        if (effMode != 1 && RayClear(eyes, head, visMask))
            return true;

        // 若模式要求三线，再做左右偏移
        if (effMode == 1)
        {
            float ang[3], fwd[3], right[3], up[3];
            GetClientEyeAngles(i, ang);
            GetAngleVectors(ang, fwd, right, up);

            float eyesL[3];
            eyesL[0] = eyes[0] - right[0] * SIDE;
            eyesL[1] = eyes[1] - right[1] * SIDE;
            eyesL[2] = eyes[2] - right[2] * SIDE;

            float eyesR[3];
            eyesR[0] = eyes[0] + right[0] * SIDE;
            eyesR[1] = eyes[1] + right[1] * SIDE;
            eyesR[2] = eyes[2] + right[2] * SIDE;

            if (RayClear(eyesL, head, visMask) || RayClear(eyesR, head, visMask))
                return true;
        }

        // 引擎可视（到胸）兜底
        if (L4D2_IsVisibleToPlayer(i, TEAM_SURVIVOR, TEAM_INFECTED, 0, chest))
            return true;
    }

    return false;
}

stock bool TraceFilter_Stuck(int entity, int contentsMask)
{
    if (entity <= MaxClients || !IsValidEntity(entity))
        return false;

    static char sClassName[20];
    GetEntityClassname(entity, sClassName, sizeof(sClassName));
    if (strcmp(sClassName, "env_physics_blocker") == 0 && !EnvBlockType(entity))
        return false;

    return true;
}
stock bool EnvBlockType(int entity)
{
    int BlockType = GetEntProp(entity, Prop_Data, "m_nBlockType");
    return !(BlockType == 1 || BlockType == 2);
}

static bool WillStuck(const float at[3]) 
{
    static const float mins[3] = { -16.0, -16.0, 0.0 };
    static const float maxs[3] = {  16.0,  16.0, 71.0 };
    Handle tr = TR_TraceHullFilterEx(at, at, mins, maxs, MASK_PLAYERSOLID, TraceFilter_Stuck);
    bool hit = TR_DidHit(tr);
    delete tr;
    return hit;
}

stock bool TraceFilter(int entity, int contentsMask)
{
    if (entity <= MaxClients || !IsValidEntity(entity))
        return false;

    static char sClassName[9];
    GetEntityClassname(entity, sClassName, sizeof(sClassName));
    if (strcmp(sClassName, "infected") == 0 || strcmp(sClassName, "witch") == 0)
        return false;

    return true;
}

// =========================
// 前方/Flow/层级判定
// =========================
static bool IsPosAheadOfHighest(float ref[3], int target = -1)
{
    int posPercent = GetPositionBucketPercent(ref);
    if (posPercent < 0) return false;

    int tPct = -1;

    // 1) 正常路径：拿最高进度玩家
    if (target == -1) target = GetHighestFlowSurvivorSafe();
    if (IsValidSurvivor(target))
    {
        if (TryGetClientFlowPercentSafe(target, tPct))
            return posPercent >= tPct;
    }

    // 2) 全部失效 → 尝试回退进度
    if (GetFallbackSurPct(tPct))
        return posPercent >= tPct;

    return false;
}

// ✅ 新增：根据坐标查询其在分桶系统中的百分比
stock int GetPositionBucketPercent(float pos[3])
{
    // 1. 先找最近的 NavArea
    Address nav = L4D2Direct_GetTerrorNavArea(pos);
    if (nav == Address_Null)
        nav = L4D_GetNearestNavArea(pos, 300.0, false, false, false, TEAM_INFECTED);
    
    if (nav == Address_Null) return -1;
    
    // 2. 查询该 NavArea 在分桶系统中的归属
    int navid = L4D_GetNavAreaID(nav);
    int areaIdx = GetAreaIndexByNavID_Int(navid);
    
    if (areaIdx < 0 || areaIdx >= g_AreaPct.Length)
        return -1;
    
    // 3. 返回分桶系统中的百分比（已处理异常flow映射）
    int bucket = view_as<int>(g_AreaPct.Get(areaIdx));
    return (bucket >= 0 && bucket <= 100) ? bucket : -1;
}

static int CountAliveSpecialsInBucket(int bucket)
{
    if (bucket < 0 || bucket > 100) return 0;

    int count = 0;
    float pos[3];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsInfectedBot(i) || !IsPlayerAlive(i) || IsGhost(i))
            continue;

        GetClientAbsOrigin(i, pos);
        int b = GetPositionBucketPercent(pos);
        if (b == bucket)
            count++;
    }
    return count;
}
static bool PassBucketShareLimit(int bucket)
{
    int cap = gCV.iBucketMaxPerFlow;
    if (cap <= 0) return true;
    if (bucket < 0 || bucket > 100) return true;

    return CountAliveSpecialsInBucket(bucket) < cap;
}

stock static int Calculate_Flow(Address area)
{
    float maxd = L4D2Direct_GetMapMaxFlowDistance();
    if (maxd <= 1.0) maxd = 1.0;

    // 读原始 flow 距离（单位：world units），对 NaN/负数/越界做钳位
    float d = 0.0;
    if (area != Address_Null)
        d = L4D2Direct_GetTerrorNavAreaFlow(area);

    if (!(d >= 0.0)) d = 0.0;     // 拦截 NaN 和负数
    if (d > maxd)    d = maxd;    // 上界

    // 叠加 BossBuffer（距离制），再做一次钳位
    float prox = d + gCV.VsBossFlowBuffer.FloatValue;
    if (!(prox >= 0.0)) prox = 0.0;
    if (prox > maxd)    prox = maxd;

    return RoundToNearest((prox / maxd) * 100.0); // → 0..100
}

static int FlowDistanceToPercent(float flowDist)
{
    float maxd = L4D2Direct_GetMapMaxFlowDistance();
    if (maxd <= 1.0) maxd = 1.0;

    // 传入的是“距离”而非比例：做 NaN/负数/越界钳位
    float d = flowDist;
    if (!(d >= 0.0)) d = 0.0;     // NaN/负数 → 0
    if (d > maxd)    d = maxd;    // 距离上限

    // 按距离口径叠加 BossBuffer（也是距离）
    float prox = d + gCV.VsBossFlowBuffer.FloatValue;
    if (!(prox >= 0.0)) prox = 0.0;
    if (prox > maxd)    prox = maxd;

    return RoundToNearest((prox / maxd) * 100.0); // → 0..100
}

// =========================
// 目标选择 & 跑男（简化版保留）
// =========================
static int ChooseTargetSurvivor()
{
    if (gST.bPickRushMan && IsValidSurvivor(gST.rushManIndex) && IsPlayerAlive(gST.rushManIndex) && !IsPinned(gST.rushManIndex))
        return gST.rushManIndex;

    int cand[8]; int n = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidSurvivor(i) && IsPlayerAlive(i) && !L4D_IsPlayerIncapacitated(i))
        {
            if (g_bTargetLimitLib && IsClientReachLimit(i))
            {
                LogMsg("[TARGET] skip %N: reach limit", i);
                continue;
            }
            cand[n++] = i; if (n >= 8) break;
        }
    }
    if (n > 0) return cand[GetRandomInt(0, n-1)];
    int fb = GetHighestFlowSurvivorSafe();
    LogMsg("[TARGET] fallback to highest-flow %N", fb);
    return fb;
}

static bool CheckRushManAndAllPinned()
{
    bool old = gST.bPickRushMan;

    int surv[8]; int ns = 0; int pinned = 0;
    int infected[MAXPLAYERS]; int ni = 0;
    float sPos[8][3]; float iPos[MAXPLAYERS][3]; float tmp[3];

    for (int c = 1; c <= MaxClients; c++)
    {
        if (IsValidSurvivor(c) && IsPlayerAlive(c))
        {
            if (IsPinned(c) || L4D_IsPlayerIncapacitated(c)) pinned++;
            GetClientAbsOrigin(c, tmp);
            if (ns < 8) { sPos[ns] = tmp; surv[ns++] = c; }
        }
        else if (IsInfectedBot(c) && IsPlayerAlive(c))
        {
            infected[ni] = c;
            GetClientAbsOrigin(c, tmp); iPos[ni++] = tmp;
        }
    }

    if (ns == 1) return false;

    int target = GetHighestFlowSurvivorSafe(); // ★
    if (ns >= 1 && IsValidClient(target))
    {
        GetClientAbsOrigin(target, tmp);
        bool nearAnotherSurvivor = false;
        for (int i = 0; i < ns; i++)
        {
            if (IsPinned(target) || L4D_IsPlayerIncapacitated(target) ||
                (surv[i] != target && GetVectorDistance(sPos[i], tmp, true) <= Pow(RUSH_MAN_DISTANCE, 2.0)))
            { nearAnotherSurvivor = true; break; }
        }

        if (!nearAnotherSurvivor || gST.totalSI < (gCV.iSiLimit / 2 + 1))
        {
            gST.bPickRushMan = false; gST.rushManIndex = -1;
            if (old != gST.bPickRushMan) LogMsg("Runner state OFF");
            return pinned == ns;
        }
        else
        {
            for (int i = 0; i < ni; i++)
            {
                if (IsPinned(target) || L4D_IsPlayerIncapacitated(target) ||
                    (GetVectorDistance(iPos[i], tmp, true) <= Pow(RUSH_MAN_DISTANCE, 2.0) * 1.3))
                {
                    gST.bPickRushMan = false; gST.rushManIndex = -1;
                    if (old != gST.bPickRushMan) LogMsg("Runner state OFF");
                    return pinned == ns;
                }
            }
        }

        gST.bPickRushMan = true;
        gST.rushManIndex = target;
        if (old != gST.bPickRushMan)
        {
            LogMsg("Runner state ON: %N", target);
            EmitRushmanForward(target);
        }
    }
    return pinned == ns;
}


// =========================
// Flow / 平均
// =========================
static bool IsAllKillersDown()
{
    int sum = gST.siAlive[view_as<int>(SI_Charger) - 1] + gST.siAlive[view_as<int>(SI_Hunter) - 1] + gST.siAlive[view_as<int>(SI_Jockey) - 1] + gST.siAlive[view_as<int>(SI_Smoker) - 1];
    return sum == 0;
}
static bool IsAnyTankOrAboveHalfSurvivorDownOrDied(int limit = 0)
{
    int down = 0; int survMax = FindConVar("survivor_limit").IntValue;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsAiTank(i)) return true;
        if (IsValidSurvivor(i) && (L4D_IsPlayerIncapacitated(i) || !IsPlayerAlive(i))) down++;
    }
    if (limit == 0)
        return down >= RoundToCeil(float(survMax) / 2.0);
    else
        return down >= limit;
}

static float GetSurAvrFlow()
{
    int n = 0;
    float sumPct = 0.0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidSurvivor(i)) continue;
        int pct;
        if (!TryGetClientFlowPercentSafe(i, pct)) continue;
        sumPct += float(pct);
        n++;
    }

    if (n > 0)
    {
        int avgPct = RoundToNearest(sumPct / float(n));
        TouchLastGoodSurPctFromAverage(avgPct);   // ★ 记录“最后一次有效进度”
        return sumPct / float(n);
    }

    // 没有任何有效进度 → 尝试回退
    int fpct;
    if (GetFallbackSurPct(fpct))
        return float(fpct);

    return 0.0;
}

// 【新增】只在 raw badflow 时使用：返回“应扣的分值”，而不是改后的分。
// 规则：candZ < 眼睛Z + 120u 开始扣；到 眼睛Z - 60u 扣分 > 100；最大不超过 200。
float ComputeBadFlowHeightPenalty(float candZ, float refBestEyeZ)
{
    const float CAP = 200.0;

    // candZ 相对眼睛高度（低为正）
    float delta = refBestEyeZ - candZ;

    // 高于 眼睛+120u ⇒ 不扣
    if (delta < -120.0)
        return 0.0;

    float pen;
    if (delta <= 0.0) {
        // 区间 [眼睛+120, 眼睛] ：温和线性 0 → 60
        // （0.5 分/uu，-120 → 0 线性过渡）
        pen = 0.5 * (delta + 120.0);         // 0..60
    } else if (delta <= 60.0) {
        // 区间 (眼睛, 眼睛-60] ：更陡线性 60 → 180
        // （2 分/uu，满足到 -60 已 >100 的要求，这里到 180）
        pen = 60.0 + 2.0 * delta;            // 60..180
    } else {
        // 低于 眼睛-60 ：封顶
        pen = CAP;                           // 200
    }

    if (pen < 0.0) pen = 0.0;
    if (pen > CAP) pen = CAP;
    return pen;
}

// =========================
// 兜底（导演 at MaxDistance）— 安全版：容错 target 无效
// =========================
static bool FallbackDirectorPosAtMax(int zc, int target, bool teleportMode, float outPos[3])
{
    const int kTries = 48;

    float bestPt[3];
    bool  have = false;
    float bestDelta = 999999.0;

    float spawnMax = gCV.fSpawnMax;
    float spawnMin = gCV.fSpawnMin;

    int tgt = target;
    if (!IsValidSurvivor(tgt) || !IsPlayerAlive(tgt))
        tgt = GetHighestFlowSurvivorSafe(); // ★

    if (!IsValidSurvivor(tgt) || !IsPlayerAlive(tgt))
    {
        for (int i = 1; i <= MaxClients; i++)
            if (IsValidSurvivor(i) && IsPlayerAlive(i)) { tgt = i; break; }
    }
    if (!IsValidSurvivor(tgt) || !IsPlayerAlive(tgt))
    {
        Debug_Print("[FALLBACK] no valid survivor to reference, abort");
        return false;
    }

    float tFeet[3]; GetClientAbsOrigin(tgt, tFeet);
    Address navTarget = L4D2Direct_GetTerrorNavArea(tFeet);
    if (navTarget == Address_Null)
        navTarget = view_as<Address>(L4D_GetNearestNavArea(tFeet, 300.0, false, false, false, TEAM_INFECTED));
    if (navTarget == Address_Null)
        return false;

    for (int i = 0; i < kTries; i++)
    {
        float pt[3];
        if (!L4D_GetRandomPZSpawnPosition(tgt, zc, 7, pt)) continue;

        float minD = GetMinDistToAnySurvivor(pt);
        if (minD < spawnMin || minD > spawnMax + 200.0) continue;
        if (IsPosVisibleSDK(pt, teleportMode)) continue;
        if (WillStuck(pt)) continue;

        float delta = FloatAbs(spawnMax - minD);
        bool prefer = (minD <= spawnMax);

        if (!have) { bestPt = pt; have = true; bestDelta = delta; }
        else
        {
            float bestMinD = GetMinDistToAnySurvivor(bestPt);
            bool bestPrefer = (bestMinD <= spawnMax);
            if ((prefer && !bestPrefer) || (prefer == bestPrefer && delta < bestDelta))
            { bestPt = pt; bestDelta = delta; }
        }
    }

    if (!have) return false;
    outPos = bestPt;
    return true;
}


static float GetMinDistToAnySurvivor(const float p[3])
{
    float best = 999999.0;
    float s[3];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidSurvivor(i) || !IsPlayerAlive(i)) continue;
        GetClientAbsOrigin(i, s);
        float d = GetVectorDistance(p, s);
        if (d < best) best = d;
    }
    return best;
}

// =========================
// 分散度工具（冷却/扇区/间距/并列最小随机）
// =========================
// === 原实现改名：以 NavAreaID 为 key ===
bool IsNavOnCooldownID(int areaID, float now)
{
    if (areaID < 0 || g_NavCooldown == null) return false;

    char key[16];
    IntToString(areaID, key, sizeof key);

    any stored;
    if (g_NavCooldown.GetValue(key, stored))
    {
        float until = view_as<float>(stored);
        return (now < until);
    }
    return false;
}

void TouchNavCooldownID(int areaID, float now, float cooldown = 8.0)
{
    if (areaID < 0) return;
    if (g_NavCooldown == null) g_NavCooldown = new StringMap();

    char key[16];
    IntToString(areaID, key, sizeof key);
    g_NavCooldown.SetValue(key, view_as<any>(now + cooldown));
}

// === 兼容包装：仍然接受 areaIdx（内部转 NavAreaID）===
stock bool IsNavOnCooldown(int areaIdx, float now)
{
    return IsNavOnCooldownID(GetNavIDByIndex(areaIdx), now);
}
stock void TouchNavCooldown(int areaIdx, float now, float cooldown = 8.0)
{
    TouchNavCooldownID(GetNavIDByIndex(areaIdx), now, cooldown);
}

stock void CleanupLastSpawns(float now)
{
    if (lastSpawns == null) return;

    // 先按时间 (SEP_TTL) 清
    for (int i = lastSpawns.Length - 1; i >= 0; i--)
    {
        float rec[4];
        lastSpawns.GetArray(i, rec); // [x,y,z,t]
        if (now - rec[3] > SEP_TTL)
            lastSpawns.Erase(i);
    }

    // 再按“数量上限 = iSiLimit”裁旧
    int cap = GetSepMax();
    while (lastSpawns.Length > cap)
        lastSpawns.Erase(0);
}

stock bool PassMinSeparation(const float pos[3])
{
    if (lastSpawns == null || lastSpawns.Length == 0) return true;

    float now = GetGameTime();
    float k = PenLimitScale();                     // 1.00 → 0.50 (随上限增大而变小)
    float SEP_RADIUS_EFF = SEP_RADIUS * k;         // 半径随之缩小，更容易靠近
    float sep2 = SEP_RADIUS_EFF * SEP_RADIUS_EFF;

    for (int i = lastSpawns.Length - 1; i >= 0; i--)
    {
        float rec[4];
        lastSpawns.GetArray(i, rec); // [x, y, z, t]

        // 过期清理
        if (now - rec[3] > SEP_TTL)
        {
            lastSpawns.Erase(i);
            continue;
        }

        // 只取前三个分量参与距离计算
        float rec3[3];
        rec3[0] = rec[0];
        rec3[1] = rec[1];
        rec3[2] = rec[2];

        // 用平方距离避免开方
        if (GetVectorDistance(pos, rec3, true) < sep2)
            return false;
    }
    return true;
}

stock bool PassRealPositionCheck(float candPos[3], int targetSur, int si=0) 
{
    // 1) 候选点的分桶百分比
    int candPercent = GetPositionBucketPercent(candPos);
    if (candPercent < 0) 
        return true;  // 无法判断就放行，避免误杀

    // 2) 目标（或最高进度）生还者的分桶百分比
    int surPercent = -1;
    if (IsValidSurvivor(targetSur) && IsPlayerAlive(targetSur))
    {
        if (!TryGetClientFlowPercentSafe(targetSur, surPercent))
            surPercent = -1;
    }
    else
    {
        int fb = GetHighestFlowSurvivorSafe();
        if (!IsValidSurvivor(fb) || !TryGetClientFlowPercentSafe(fb, surPercent))
            surPercent = -1;
    }

    // ★ 拿不到任何生还者进度 → 尝试“回退进度”
    if (surPercent < 0)
    {
        int fpct;
        if (GetFallbackSurPct(fpct))
            surPercent = fpct;
    }

    // 3) 后方超过 6 个桶：直接禁止
    if (candPercent < surPercent - 6)
        return false;

    // 4) 你的需求：若“候选桶在生还进度后方” 且 “候选点 Z <= 所有生还者最低脚部 Z - 200u”，则禁止
    float minFootZ;
    if (TryGetLowestSurvivorFootZ(minFootZ))
    {
        // 严格“后方”：candPercent < surPercent（不含相等）
        if (candPercent < surPercent && (candPos[2] <= (minFootZ - 180.0)|| (si != view_as<int>(SI_Smoker) && candPos[2] >= (minFootZ + 200.0))))
            return false;
    }
    // 如果没找到生还者（极端情况），保持放行
    return true;
}

// 返回 true 表示找到至少一名有效、生还且有坐标的生还者；outMinZ 为他们脚底 Z 的最小值
stock bool TryGetLowestSurvivorFootZ(float &outMinZ)
{
    bool found = false;
    float bestZ = 0.0;
    float s[3];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidSurvivor(i) || !IsPlayerAlive(i))
            continue;

        GetClientAbsOrigin(i, s); // Source 中 origin 在脚底附近，符合“脚部 Z”的语义
        if (!found || s[2] < bestZ)
        {
            bestZ = s[2];
            found = true;
        }
    }

    if (found) outMinZ = bestZ;
    return found;
}
// =========================
// 修改 GetNavIDByIndex（需要重新获取）
// =========================
stock int GetNavIDByIndex(int idx)
{
    EnsureNavAreasCache();  // ✅ 确保缓存存在
    
    if (idx < 0 || idx >= g_NavAreasCacheCount)
        return -1;
    
    Address area = g_AllNavAreasCache.Get(idx);
    return L4D_GetNavAreaID(area);
}

stock int ComputeSectorIndex(const float center[3], const float pt[3], int sectors)
{
    float dx = pt[0] - center[0];
    float dy = pt[1] - center[1];
    float ang = ArcTangent2(dy, dx); // -pi..pi
    if (ang < 0.0) ang += 2.0 * PI;

    float w = (2.0 * PI) / float(sectors);
    int idx = RoundToFloor(ang / w);
    if (idx < 0) idx = 0;
    if (idx >= sectors) idx = sectors - 1;
    return idx;
}

stock void GetSectorCenter(float outCenter[3], int targetSur)
{
    if (IsValidSurvivor(targetSur))
    {
        GetClientAbsOrigin(targetSur, outCenter);
        return;
    }

    int fb = GetHighestFlowSurvivorSafe();
    if (IsValidSurvivor(fb))
    {
        GetClientAbsOrigin(fb, outCenter);
        return;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidSurvivor(i))
        {
            GetClientAbsOrigin(i, outCenter);
            return;
        }
    }

    outCenter[0] = outCenter[1] = outCenter[2] = 0.0;
}

stock void RememberSpawn(const float pos[3], const float center[3])
{
    float now = GetGameTime();
    CleanupLastSpawns(now);

    float rec[4];
    rec[0] = pos[0]; rec[1] = pos[1]; rec[2] = pos[2]; rec[3] = now;
    lastSpawns.PushArray(rec);

    int sectors = GetCurrentSectors();
    int s = ComputeSectorIndex(center, pos, sectors);
    recentSectors[2] = recentSectors[1];
    recentSectors[1] = recentSectors[0];
    recentSectors[0] = s;
}

stock int ArgMinFloat(const float[] a, int n, float eps = 0.0001)
{
    if (n <= 0) return -1;

    float best = a[0];
    for (int i = 1; i < n; i++)
        if (a[i] < best) best = a[i];

    int ties = 0;
    for (int i = 0; i < n; i++)
        if (a[i] <= best + eps) ties++;

    int pick = GetRandomInt(1, ties);
    for (int i = 0; i < n; i++)
        if (a[i] <= best + eps && --pick == 0) return i;

    return 0;
}

int PickSector(int sectors)
{
    float score[SECTORS_MAX];
    for (int s = 0; s < sectors; s++)
        score[s] = GetRandomFloat(0.0, 1.0);

    if (recentSectors[0] >= 0 && recentSectors[0] < sectors) score[recentSectors[0]] += 1.5;
    if (recentSectors[1] >= 0 && recentSectors[1] < sectors) score[recentSectors[1]] += 1.0;
    if (recentSectors[2] >= 0 && recentSectors[2] < sectors) score[recentSectors[2]] += 0.5;

    return ArgMinFloat(score, sectors);
}

// 运行时计算当前扇区数：最低2；其余= ceil(目标T/2)+1；再夹在 [2, SECTORS_MAX]
static int GetCurrentSectors()
{
    int T = gCV.iSiLimit;
    int n = (T <= 2) ? 2 : (RoundToCeil(float(T) / 2.0) + 1);
    if (n < DYN_SECTORS_MIN) n = DYN_SECTORS_MIN;
    if (n > SECTORS_MAX)     n = SECTORS_MAX;
    return n;
}

// 判异常：flow < 0 或 > 地图最大 flow
static bool IsFlowAbnormal(float flowDist, float maxFlow)
{
    if (maxFlow <= 0.0) return true;
    return (flowDist < 0.0 || flowDist > maxFlow);
}

static bool TryGetFlowDistanceFromArea(Address area, float &outFlow)
{
    if (area == Address_Null) return false;
    float d = L4D2Direct_GetTerrorNavAreaFlow(area);
    float maxFlow = L4D2Direct_GetMapMaxFlowDistance();
    if (IsFlowAbnormal(d, maxFlow)) return false;
    outFlow = d;
    return true;
}

// ★核心兜底：为 client 拿“安全 flow 距离”
// 1) 直接读玩家 flow；异常 → 2) 用 L4D_GetLastKnownArea(client) 取 Nav flow；仍异常 → 3) 最近 NavArea。
static bool TryGetClientFlowDistanceSafe(int client, float &outFlow)
{
    float maxFlow = L4D2Direct_GetMapMaxFlowDistance();

    float d = L4D2Direct_GetFlowDistance(client);
    if (!IsFlowAbnormal(d, maxFlow)) { outFlow = d; return true; }

    // ★ 显式兜底：使用 L4D_GetLastKnownArea（你要求的函数）
    Address last = view_as<Address>(L4D_GetLastKnownArea(client));
    if (TryGetFlowDistanceFromArea(last, outFlow)) return true;

    float pos[3];
    GetClientAbsOrigin(client, pos);
    Address near = L4D_GetNearestNavArea(pos, 300.0, false, false, false, TEAM_SURVIVOR);
    if (TryGetFlowDistanceFromArea(near, outFlow)) return true;

    return false;
}

// 百分比封装
static bool TryGetClientFlowPercentSafe(int client, int &outPct)
{
    float d;
    if (!TryGetClientFlowDistanceSafe(client, d)) return false;
    outPct = FlowDistanceToPercent(d);
    if (outPct < 0) outPct = 0;
    if (outPct > 100) outPct = 100;
    return true;
}

// 最高进度幸存者（安全版）
static int GetHighestFlowSurvivorSafe()
{
    int best = -1, bestPct = -1;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidSurvivor(i) || !IsPlayerAlive(i)) continue;
        int pct;
        if (!TryGetClientFlowPercentSafe(i, pct)) continue;
        if (pct > bestPct) { bestPct = pct; best = i; }
    }
    if (best != -1) return best;
    // 若全部失败，退回引擎原生（极端保护）
    return L4D_GetHighestFlowSurvivor();
}
// 存活生还者数量
static int CountAliveSurvivors()
{
    int n = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsValidSurvivor(i) && IsPlayerAlive(i))
            n++;
    return n;
}

// 取得“当前有效的回退进度”（满足开启且未过期）
static bool GetFallbackSurPct(int &outPct)
{
    if (!gCV.bSurFlowFallback) return false;
    if (g_LastGoodSurPct < 0)  return false;
    float now = GetGameTime();
    if ((now - g_LastGoodSurPctTime) > gCV.fSurFlowFallbackTTL) return false;
    outPct = g_LastGoodSurPct;
    return true;
}

// 在成功统计到生还者进度时，更新“最后一次有效进度”
static void TouchLastGoodSurPctFromAverage(int avgPct)
{
    if (avgPct < 0)   avgPct = 0;
    if (avgPct > 100) avgPct = 100;
    g_LastGoodSurPct = avgPct;
    g_LastGoodSurPctTime = GetGameTime();
}

// =========================
// Survivor数据辅助
// =========================
static bool GetSurPosData()
{
    if (g_aSurPosData != null) { delete g_aSurPosData; g_aSurPosData = null; }
    g_aSurPosData = new ArrayList(sizeof(SurPosData));
    g_iSurPosDataLen = 0; g_iSurCount = 0;

    SurPosData data;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) && !L4D_IsPlayerIncapacitated(i))
        {
            float flowDist;
            if (!TryGetClientFlowDistanceSafe(i, flowDist))
            {
                // 实在拿不到就按 0 处理（开局/重生点），避免把异常流量灌进 allMinFlowBucket
                flowDist = 0.0;
            }
            data.fFlow = flowDist;
            GetClientEyePosition(i, data.fPos);
            g_aSurPosData.PushArray(data);
            g_iSurvivors[g_iSurCount++] = i;
        }
    }
    return (g_iSurPosDataLen = g_aSurPosData.Length) > 0;
}

static bool IsValidFlags(int iFlags, bool bFinaleArea)
{
    if (!iFlags)
        return true;

    if (bFinaleArea && (iFlags & TERROR_NAV_FINALE) == 0)
        return false;

    return (iFlags & (TERROR_NAV_RESCUE_CLOSET|TERROR_NAV_RESCUE_VEHICLE|TERROR_NAV_CHECKPOINT)) == 0;
}

// [修改] —— 高度感知的 ring 弹性（加入近距离屋顶衰减因子）
static float HeightRingSlack(const float p[3], float bucketMinZ, float bucketMaxZ, float allMaxEyeZ)
{
    float zRange = bucketMaxZ - bucketMinZ;
    if (zRange < 1.0) zRange = 1.0;

    // 桶内高度归一化（越高越接近 1）
    float zNorm  = (p[2] - bucketMinZ) / zRange;
    if (zNorm < 0.0) zNorm = 0.0;
    if (zNorm > 1.0) zNorm = 1.0;

    // 基础弹性：线性从 0..zRange（上限 2*RING_SLACK）
    float base = FloatMin(zRange + 50.0, RING_SLACK * 2.0) * zNorm;

    // 超过“所有幸存者最大眼睛 + 200u”后，对弹性做竖直衰减
    float over   = FloatMax(0.0, p[2] - (allMaxEyeZ + 200.0));
    float taperZ = 1.0 / (1.0 + over / 150.0);  // 150u 每级衰减

    return base * taperZ;
}

// =========================
// Nav Flow 分桶：构建 / 清理 / 计时器回调
// =========================
static void ClearNavBuckets()
{
    for (int i = 0; i < FLOW_BUCKETS; i++)
    {
        if (g_FlowBuckets[i] != null) { delete g_FlowBuckets[i]; g_FlowBuckets[i] = null; }
        g_BucketMinZ[i] = 0.0;
        g_BucketMaxZ[i] = 0.0;
    }

    if (g_AreaZCore != null) { delete g_AreaZCore; g_AreaZCore = null; }
    if (g_AreaZMin  != null) { delete g_AreaZMin;  g_AreaZMin  = null; }
    if (g_AreaZMax  != null) { delete g_AreaZMax;  g_AreaZMax  = null; }
    if (g_AreaCX  != null) { delete g_AreaCX;  g_AreaCX  = null; }
    if (g_AreaCY  != null) { delete g_AreaCY;  g_AreaCY  = null; }
    if (g_AreaPct != null) { delete g_AreaPct; g_AreaPct = null; }
}

static int ComputeDynamicBucketWindow(float ring)
{
    // 如果没启用动态联动，直接返回静态窗口
    if (!gCV.bNavBucketLinkToRing)
        return gCV.iNavBucketWindow;

    float a = gCV.fNavBucketMinAt;
    float b = gCV.fNavBucketMaxAt;
    int   w0 = gCV.iNavBucketWindowMin;
    int   w1 = gCV.iNavBucketWindowMax;

    if (b < a) { float t=a; a=b; b=t; } // 容错：交换

    float t;
    if (ring <= a)       t = 0.0;
    else if (ring >= b)  t = 1.0;
    else                 t = (ring - a) / (b - a);

    // 线性插值并四舍五入
    float w = float(w0) + (float(w1) - float(w0)) * t;
    int   win = RoundToNearest(w);

    if (win < 0)   win = 0;
    if (win > 100) win = 100;
    return win;
}

// 小工具：整型夹取
static int ClampInt(int v, int lo, int hi)
{
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}

/**
 * 生成“扫描桶顺序”（中心 s 起，前2后1推进；若前>后累计差>4，则两侧批量+1）
 * 例如：s, s+1, s+2, s-1, s+3, s+4, s-2, s+5, s+6, s-3, ...
 * @param s             中心桶（0..100）
 * @param win           窗口半径（±win）
 * @param includeCenter 是否把中心桶也加入序列
 * @param outBuckets    输出序列（长度上限 FLOW_BUCKETS）
 * @return              实际写入数量
 */
static int BuildBucketOrder(int s, int win, bool includeCenter, int outBuckets[FLOW_BUCKETS])
{
    s   = ClampInt(s,   0, 100);
    win = ClampInt(win, 0, 100);

    int n = 0;
    if (includeCenter)
        outBuckets[n++] = s;

    int fdist = 1;   // 向前偏移距离（s+fdist）
    int bdist = 1;   // 向后偏移距离（s-bdist）

    int fwdRun  = 2; // 每轮先推“前”多少个
    int backRun = 1; // 然后推“后”多少个

    int addedF = 0;  // 实际加入的前/后桶累计（考虑越界后可能没加上）
    int addedB = 0;

    while ((fdist <= win || bdist <= win) && n < FLOW_BUCKETS)
    {
        // 前 fwdRun
        int pushedF = 0;
        for (int k = 0; k < fwdRun && fdist <= win && n < FLOW_BUCKETS; k++, fdist++)
        {
            int b = s + fdist;
            if (b <= 100) { outBuckets[n++] = b; pushedF++; }
        }
        addedF += pushedF;

        // 后 backRun
        int pushedB = 0;
        for (int k = 0; k < backRun && bdist <= win && n < FLOW_BUCKETS; k++, bdist++)
        {
            int a = s - bdist;
            if (a >= 0) { outBuckets[n++] = a; pushedB++; }
        }
        addedB += pushedB;

        // 不平衡修正：前比后“实际加入”多 > 4，则两侧批量都+1
        if ((addedF - addedB) > 4)
        {
            fwdRun++;
            backRun++;
        }
    }
    return n;
}

static void BuildNavBuckets()
{
    // 1) 尝试读缓存（成功就直接返回）
    if (TryLoadBucketsFromCache())
        return;

    // 2) 清理旧数据、准备索引与缓存
    ClearNavBuckets();
    BuildNavIdIndexMap();
    EnsureNavAreasCache();

    int iAreaCount = g_NavAreasCacheCount;
    float fMapMaxFlowDist = L4D2Direct_GetMapMaxFlowDistance();
    bool  bFinaleArea     = L4D_IsMissionFinalMap() && L4D2_GetCurrentFinaleStage() < 18;

    float t0 = GetEngineTime();
    Debug_Print("[BUCKET] begin build: areas=%d", iAreaCount);

    // 3) 初始化 per-area / per-bucket 容器
    g_AreaZCore = new ArrayList();
    g_AreaZMin  = new ArrayList();
    g_AreaZMax  = new ArrayList();
    g_AreaCX    = new ArrayList();
    g_AreaCY    = new ArrayList();
    g_AreaPct   = new ArrayList();

    for (int i = 0; i < iAreaCount; i++)
    {
        g_AreaZCore.Push(0.0);
        g_AreaZMin.Push(0.0);
        g_AreaZMax.Push(0.0);
        g_AreaCX.Push(0.0);
        g_AreaCY.Push(0.0);
        g_AreaPct.Push(-1); // -1 = 未归桶/坏flow
    }

    for (int b = 0; b < FLOW_BUCKETS; b++)
    {
        g_FlowBuckets[b] = null;
        g_BucketMinZ[b]  =  1.0e9;
        g_BucketMaxZ[b]  = -1.0e9;
    }

    ArrayList badIdxs   = new ArrayList();
    ArrayList validIdxs = new ArrayList();

    int addedValid = 0, addedBad = 0, skippedFlag = 0;

    // 4) 第一遍：采样中心/高度，正常 flow 直接入桶
    for (int i = 0; i < iAreaCount; i++)
    {
        Address areaAddr = g_AllNavAreasCache.Get(i);
        if (areaAddr == Address_Null) continue;

        NavArea pArea = view_as<NavArea>(areaAddr);

        // 过滤不合规的 Nav flags（救援/安全屋等）
        if (!IsValidFlags(pArea.SpawnAttributes, bFinaleArea))
        {
            skippedFlag++;
            continue;
        }

        // 采样中心与高度统计（最多 3 次）
        float cx, cy, zAvg, zMin, zMax;
        SampleAreaCenterAndZ(areaAddr, cx, cy, zAvg, zMin, zMax, 3);
        g_AreaCX.Set(i, cx);
        g_AreaCY.Set(i, cy);
        g_AreaZCore.Set(i, zAvg);
        g_AreaZMin.Set(i,  zMin);
        g_AreaZMax.Set(i,  zMax);

        // 原始 flow 到百分比（无效则进坏列表）
        float fFlow = pArea.GetFlow();
        bool  flowOK = (fFlow >= 0.0 && fFlow <= fMapMaxFlowDist);

        if (flowOK)
        {
            int percent = FlowDistanceToPercent(fFlow);
            if (percent < 0)   percent = 0;
            if (percent > 100) percent = 100;

            if (g_FlowBuckets[percent] == null)
                g_FlowBuckets[percent] = new ArrayList();
            g_FlowBuckets[percent].Push(i);

            if (zMin < g_BucketMinZ[percent]) g_BucketMinZ[percent] = zMin;
            if (zMax > g_BucketMaxZ[percent]) g_BucketMaxZ[percent] = zMax;

            g_AreaPct.Set(i, percent);
            validIdxs.Push(i);
            addedValid++;
        }
        else
        {
            badIdxs.Push(i);
            addedBad++;
        }
    }

    Debug_Print("[BUCKET] pass1 done: valid=%d bad=%d skipped=%d took=%.3fs",
        addedValid, addedBad, skippedFlag, GetEngineTime() - t0);

    // 5) 第二遍：把坏 flow 的区域映射到最近“有效桶”（二维栅格 + 成本/时间保护）
    if (gCV.bNavBucketMapInvalid && validIdxs.Length > 0 && badIdxs.Length > 0)
    {
        // 5.1 估算成本与时间预算
        int B = badIdxs.Length, V = validIdxs.Length;
        float estCostM = float(B) * float(V) / 1.0e6;
        const float hardCostM   = 5.0;  // ≈500万配对：超过则跳过映射
        const float timeBudgetS = 0.60; // 总时间预算：>0.6s 就中止映射

        float t1 = GetEngineTime();
        if (estCostM > hardCostM)
        {
            Debug_Print("[BUCKET] pass2 SKIP(cost): B=%d V=%d est≈%.1fM", B, V, estCostM);
        }
        else
        {
            // 5.2 构建“有效区”二维栅格
            const float cell = 2000.0; // 栅格边长（可按地图尺度调整）
            float radius = gCV.fNavBucketAssignRadius; // 0=不限
            if (radius < 0.0) radius = 0.0;

            StringMap cellMap = new StringMap();
            ArrayList ownedLists = new ArrayList(); // 收尾 delete

            for (int i = 0; i < V; i++)
            {
                int vidx = validIdxs.Get(i);
                float vx = view_as<float>(g_AreaCX.Get(vidx));
                float vy = view_as<float>(g_AreaCY.Get(vidx));
                int   cx = RoundToFloor(vx / cell);
                int   cy = RoundToFloor(vy / cell);

                char key[32];
                Format(key, sizeof key, "%d,%d", cx, cy);

                any h;
                ArrayList lst;
                if (!cellMap.GetValue(key, h))
                {
                    lst = new ArrayList();
                    ownedLists.Push(lst);
                    cellMap.SetValue(key, view_as<any>(lst));
                }
                else
                {
                    lst = view_as<ArrayList>(h);
                }
                lst.Push(vidx);
            }

            // 5.3 邻格扩环检索参数
            int   maxLayer = (radius > 0.1) ? RoundToCeil(radius / cell) : 6;
            if (maxLayer < 0)  maxLayer = 0;
            if (maxLayer > 48) maxLayer = 48;
            float r2 = (radius > 0.1) ? (radius * radius) : -1.0;

            int mapped = 0, dropped = 0;
            bool aborted = false;

            // 5.4 对每个坏区做邻格扩环搜索
            for (int bi = 0; bi < B; bi++)
            {
                // 时间预算：每 1024 个检查一次
                if ((bi & 1023) == 0)
                {
                    float el = GetEngineTime() - t1;
                    if (el > timeBudgetS)
                    {
                        Debug_Print("[BUCKET] pass2 ABORT(time): bi=%d/%d mapped=%d dropped=%d el=%.3fs",
                                    bi, B, mapped, dropped, el);
                        aborted = true;
                        break;
                    }
                }

                int aidx = badIdxs.Get(bi);
                float ax = view_as<float>(g_AreaCX.Get(aidx));
                float ay = view_as<float>(g_AreaCY.Get(aidx));
                int   acx = RoundToFloor(ax / cell);
                int   acy = RoundToFloor(ay / cell);

                float bestD2 = 1.0e20;
                int   bestV  = -1;

                // 扩环：layer=0..maxLayer（只扫 ring 外框，避免 O(layer^2)）
                for (int layer = 0; layer <= maxLayer; layer++)
                {
                    bool foundThisRing = false;
                    int minX = acx - layer, maxX = acx + layer;
                    int minY = acy - layer, maxY = acy + layer;

                    for (int cy = minY; cy <= maxY; cy++)
                    {
                        for (int cx = minX; cx <= maxX; cx++)
                        {
                            bool onEdge = (cx == minX || cx == maxX || cy == minY || cy == maxY);
                            if (!onEdge) continue;

                            char key[32];
                            Format(key, sizeof key, "%d,%d", cx, cy);

                            any h;
                            if (!cellMap.GetValue(key, h)) continue;
                            ArrayList lst = view_as<ArrayList>(h);

                            for (int k = 0; k < lst.Length; k++)
                            {
                                int vidx = lst.Get(k);
                                float vx = view_as<float>(g_AreaCX.Get(vidx));
                                float vy = view_as<float>(g_AreaCY.Get(vidx));
                                float dx = ax - vx, dy = ay - vy;
                                float d2 = dx*dx + dy*dy;

                                if (r2 > 0.0 && d2 > r2) continue;
                                if (d2 < bestD2)
                                {
                                    bestD2 = d2;
                                    bestV  = vidx;
                                    foundThisRing = true;
                                }
                            }
                        }
                    }

                    if (foundThisRing)
                        break;
                }

                if (bestV != -1)
                {
                    int percent = view_as<int>(g_AreaPct.Get(bestV));
                    if (percent < 0)   percent = 0;
                    if (percent > 100) percent = 100;

                    if (g_FlowBuckets[percent] == null)
                        g_FlowBuckets[percent] = new ArrayList();
                    g_FlowBuckets[percent].Push(aidx);

                    float zmin = view_as<float>(g_AreaZMin.Get(aidx));
                    float zmax = view_as<float>(g_AreaZMax.Get(aidx));
                    if (zmin < g_BucketMinZ[percent]) g_BucketMinZ[percent] = zmin;
                    if (zmax > g_BucketMaxZ[percent]) g_BucketMaxZ[percent] = zmax;

                    g_AreaPct.Set(aidx, percent);
                    mapped++;
                }
                else
                {
                    dropped++;
                }

                if ((bi % 2048) == 0)
                    Debug_Print("[BUCKET] pass2 prog: %d/%d mapped=%d dropped=%d", bi, B, mapped, dropped);
            }

            Debug_Print("[BUCKET] pass2 %s: B=%d V=%d mapped=%d dropped=%d took=%.3fs",
                aborted ? "done(partial)" : "done",
                B, V, mapped, dropped, GetEngineTime() - t1);

            // 5.5 释放 cellMap 内存
            for (int i = 0; i < ownedLists.Length; i++)
            {
                ArrayList lst = ownedLists.Get(i);
                if (lst != null) delete lst;
            }
            delete ownedLists;
            delete cellMap;
        }
    }
    else
    {
        Debug_Print("[BUCKET] pass2 skip: mapInvalid=%d valid=%d bad=%d",
            gCV.bNavBucketMapInvalid ? 1 : 0, validIdxs.Length, badIdxs.Length);
    }

    // 6) 完成：标记就绪 & 存缓存
    g_BucketsReady = true;
    Debug_Print("[BUCKET] build done: took=%.3fs", GetEngineTime() - t0);

    SaveBucketsToCache(); // 若启用缓存将写入 .kv（你已有实现）
}


// ✅ 新增：获取所有生还者的最低脚位置（约第2850行）
stock float GetLowestSurvivorFootZ()
{
    float lowest = 999999.0;
    float pos[3];
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidSurvivor(i) || !IsPlayerAlive(i))
            continue;
        
        GetClientAbsOrigin(i, pos);
        if (pos[2] < lowest)
            lowest = pos[2];
    }
    
    // 如果没有生还者（异常情况），返回一个合理的默认值
    return (lowest < 999999.0) ? lowest : 0.0;
}

stock void ShuffleArrayList(ArrayList L)
{
    int n = L.Length;
    for (int i = n - 1; i > 0; i--)
    {
        int j = GetRandomInt(0, i);
        if (j == i) continue;
        int ai = L.Get(i), aj = L.Get(j);
        L.Set(i, aj); L.Set(j, ai);
    }
}

// ✅ 修改：重建 Buckets 时确保缓存新鲜
static Action Timer_RebuildBuckets(Handle timer)
{
    // 如果本局本图已经有可用缓存，就别动了
    if (g_BucketsReady && g_AllNavAreasCache != null && g_NavAreasCacheCount > 0)
    {
        // Debug_Print("[NAV CACHE] Skip rebuild (already warm)");
        return Plugin_Stop;
    }

    // 只在“没有缓存”时，补齐一次（不会触发 Cleared 日志）
    EnsureNavAreasCache();   // 仅确保存在，不清空
    BuildNavBuckets();       // 内部会 TryLoadBucketsFromCache()
    return Plugin_Stop;
}

static void RebuildNavBuckets()
{
    BuildNavBuckets();
}

static bool FindDropLanding(const float from[3], float outLand[3], float maxDrop = 480.0)
{
    float start[3];
    start[0] = from[0];
    start[1] = from[1];
    start[2] = from[2] + 1.0;

    float end[3];
    end[0] = from[0];
    end[1] = from[1];
    end[2] = from[2] - maxDrop;

    Handle tr = TR_TraceRayFilterEx(start, end, MASK_SOLID, RayType_EndPoint, TraceFilter);
    if (!TR_DidHit(tr))
    {
        delete tr;
        return false;
    }

    TR_GetEndPosition(outLand, tr);
    delete tr;

    Address nav = L4D_GetNearestNavArea(outLand, 120.0, false, false, false, TEAM_INFECTED);
    return nav != Address_Null;
}

// [新增] 解决 error 017: undefined symbol "Clamp"
stock float clamp(float val, float min, float max)
{
    if (val < min) return min;
    if (val > max) return max;
    return val;
}

// [新增] 新评分系统 - 计算距离得分 (0-100)
// [ADD] New Scoring System - Calculate Distance Score (0-100)
stock float CalculateScore_Distance(float dist, float min, float max)
{
    if (max <= min) return 50.0;
    float sweetSpot = min + (max - min) * 0.4; // 黄金距离点，略靠近最小距离
    float distFromSweet = FloatAbs(dist - sweetSpot);
    
    // 离黄金点越远，分数越低。使用线性衰减模型。
    float score = 100.0 - (distFromSweet / (max - min)) * 100.0;
    
    return clamp(score, 20.0, 100.0); // 最低给予20分
}

// [新增] 新评分系统 - 计算高度得分 (可为负)
// [ADD] New Scoring System - Calculate Height Score (can be negative)
stock float CalculateScore_Height(int zc, const float p[3], float refEyeZ)
{
    float zRel = p[2] - refEyeZ;

    // --- 平面型特感 (Charger / Jockey) ---
    if (zc == view_as<int>(SI_Charger) || zc == view_as<int>(SI_Jockey))
    {
        const float CJ_ALLOWED_PLANE = 150.0;
        float distPlane = FloatAbs(zRel);
        if (distPlane <= CJ_ALLOWED_PLANE)
        {
            return 90.0 - (distPlane / CJ_ALLOWED_PLANE) * 20.0; // 在平面内，分数 70-90
        }
        else
        {
            return 60.0 - (distPlane - CJ_ALLOWED_PLANE) * 0.2; // 偏离平面则分数骤减
        }
    }

    // --- 垂直/通用型特感 ---
    float score = 0.0;
    const float HEIGHT_PEAK_WINDOW = 400.0;
    const float TAPER_BASE_DIST = 250.0;

    if (zRel <= 20.0) // 在下方或略高，不加分
    {
        score = 0.0;
    }
    else if (zRel <= HEIGHT_PEAK_WINDOW) // 在理想高度区间内，线性加分
    {
        score = (zRel / HEIGHT_PEAK_WINDOW) * 100.0;
    }
    else // 超出理想高度，分数衰减
    {
        float over = zRel - HEIGHT_PEAK_WINDOW;
        float taper = 1.0 / (1.0 + (over / TAPER_BASE_DIST));
        score = 100.0 * taper;
    }

    // 空降潜力加分
    float land[3];
    if (FindDropLanding(p, land))
    {
        float d = GetMinDistToAnySurvivor(land);
        if (d < 450.0) score += 40.0 * (1.0 - d/450.0); // 离落点越近，加分越多
    }
    
    return score;
}

// [新增] 新评分系统 - 计算流程位置得分 (0-100)
// [ADD] New Scoring System - Calculate Flow Position Score (0-100)
stock float CalculateScore_Flow(int candBucket, int survBucket)
{
    int delta = candBucket - survBucket;

    if (delta > 0 && delta <= 8) // 在生还者前方不远处，是最佳埋伏点
    {
        return 100.0;
    }
    else if (delta > 8 && delta <= 20) // 在前方较远处
    {
        return 70.0;
    }
    else if (delta == 0) // 与生还者在同一进度
    {
        return 50.0;
    }
    else if (delta < 0 && delta >= -10) // 在后方不远处
    {
        return 30.0;
    }

    return 10.0; // 在遥远的后方或前方
}

// [新增] 新评分系统 - 计算分散度得分 (-50 - 100)
// [ADD] New Scoring System - Calculate Dispersion Score (-50 to 100)
// [修改] 解决 warning 219: local variable "recentSectors" shadows a variable
stock float CalculateScore_Dispersion(int sidx, int preferredSector, const int a_recentSectors[3])
{
    float k = PenLimitScale(); // 1.00..0.50
    if (sidx == preferredSector)      return 100.0;      // 正向奖励不缩
    if (sidx == a_recentSectors[0])   return -50.0 * k;  // 最近扇区的负分随上限减半
    if (sidx == a_recentSectors[1])   return -25.0 * k;  // 次近扇区同理
    if (sidx == a_recentSectors[2])   return 0.0;
    return 50.0;
}
// [新增] —— 计算某类的自适应 First-Fit 阈值（按理论上限的比例）
stock float ComputeFFThresholdForClass(int zc)
{
    float maxDist = 100.0, maxFlow = 100.0, maxDisp = 100.0, maxHght = 140.0; // 高度含空降加分上限略高
    float theoMax = gCV.w_dist[zc]*maxDist + gCV.w_hght[zc]*maxHght
                  + gCV.w_flow[zc]*maxFlow + gCV.w_disp[zc]*maxDisp;
    // 建议 0.85，可考虑做成 CVar
    return 0.85 * theoMax;
}

// [新增] —— 简易 e^x 封装（SourcePawn 没有 Exp，改用 Pow）
#define M_E 2.718281828459045
stock float ExpF(float x)
{
    return Pow(M_E, x);
}

// [新增] —— Logistic 距离评分（0..100），围绕“类目甜点”对称衰减
// [修改] —— 距离平滑评分：以“甜点距离 sweet”为中心的对称衰减
stock float ScoreDistSmooth(float dminEye, float sweet, float width)
{
    // 防御：宽度太小会过于尖锐
    if (width < 1.0) width = 1.0;

    // 归一化偏差
    float t = FloatAbs(dminEye - sweet) / width;

    // 100 / (1 + e^(k*t))，t 越大衰减越多；k 适中给点锐度
    float k = 1.5;
    float s = 100.0 / (1.0 + ExpF(k * t));

    // 限幅，避免因为极端参数出 0 分或 100+ 分
    return clamp(s, 10.0, 100.0);
}

// [新增] —— 各类的甜点距离与宽度（可按需改成 CVar）
stock void GetClassDistanceProfile(int zc, float min, float max, float &sweet, float &width)
{
    float span = FloatMax(1.0, max - min);
    switch (zc) {
        case view_as<int>(SI_Boomer): { sweet = min + 0.25*span; width = 0.22*span; }
        case view_as<int>(SI_Hunter): { sweet = min + 0.45*span; width = 0.28*span; }
        case view_as<int>(SI_Smoker): { sweet = min + 0.60*span; width = 0.30*span; }
        case view_as<int>(SI_Spitter):{ sweet = min + 0.40*span; width = 0.25*span; }
        case view_as<int>(SI_Jockey): { sweet = min + 0.35*span; width = 0.24*span; }
        case view_as<int>(SI_Charger):{ sweet = min + 0.38*span; width = 0.26*span; }
        default: { sweet = min + 0.40*span; width = 0.25*span; }
    }
}

// [ADD] —— 通过 areaIdx 直接反查分桶（优先缓存，其次 Flow→Percent）
stock bool TryGetBucketByAreaIdx(int areaIdx, int &outBucket)
{
    outBucket = -1;
    if (areaIdx < 0) return false;

    if (g_AreaPct != null && areaIdx < g_AreaPct.Length)
    {
        int b = view_as<int>(g_AreaPct.Get(areaIdx));
        if (b >= 0 && b <= 100) { outBucket = b; return true; }
    }

    if (g_AllNavAreasCache != null && areaIdx < g_NavAreasCacheCount)
    {
        Address areaAddr = g_AllNavAreasCache.Get(areaIdx);
        if (areaAddr != Address_Null)
        {
            NavArea area = view_as<NavArea>(areaAddr);
            if (area)
            {
                float f   = area.GetFlow();
                float max = L4D2Direct_GetMapMaxFlowDistance();
                if (f >= 0.0 && f <= max)
                {
                    int b2 = FlowDistanceToPercent(f);
                    if (b2 < 0) b2 = 0; if (b2 > 100) b2 = 100;
                    outBucket = b2;
                    return true;
                }
            }
        }
    }
    return false;
}

// [MOD] —— 覆盖：无重叠、可读的 Flow 评分
// 语义：略微领先（+1..+5）最好；过远前方衰减；同进度中性；落后扣分。
stock float ScoreFlowSmooth(int deltaFlow)
{
    // 后方：-12 以下直接给极低
    if (deltaFlow <= -12) return 0.0;

    // 后方：-11..-1 线性爬升到 30 分（仍然是偏低，鼓励前置）
    if (deltaFlow < 0)
    {
        // -11 -> 5 分,  -1 -> 30 分
        float t = float(deltaFlow + 11) / 10.0;      // 0..1
        return 5.0 + t * 25.0;                       // 5..30
    }

    // 同进度：给中性 50 分
    if (deltaFlow == 0) return 50.0;

    // 前方近距离最佳：+1..+5 → 100 分
    if (deltaFlow <= 5) return 100.0;

    // 前方中距离：+6..+12 从 85 线性降到 45
    if (deltaFlow <= 12)
    {
        float t = float(deltaFlow - 6) / 6.0;        // 0..1
        return 85.0 - t * 40.0;                      // 85..45
    }

    // 前方太远（>+12）：缓慢衰减到 30~40 的平台
    // 用个平滑函数避免突变
    float over = float(deltaFlow - 12);
    float s = 40.0 / (1.0 + (over / 8.0));           // 40 → 渐近 0
    return 30.0 + clamp(s, 0.0, 40.0);               // 30..70（但很快收敛到 30~40）
}

// === Limit-aware penalty scale (uses PEN_LIMIT_* macros) ===
stock float PenLimitScale()
{
    // iSiLimit 在 gCV 里；把它压到 [PEN_LIMIT_MINL .. PEN_LIMIT_MAXL]
    float L = float(gCV.iSiLimit);
    float t = Clamp01((L - float(PEN_LIMIT_MINL)) / float(PEN_LIMIT_MAXL - PEN_LIMIT_MINL));
    // L=MINL 时返回 1.0（惩罚原强度）；L=MAXL 及以上时返回 0.5（惩罚减半）
    return PEN_LIMIT_SCALE_HI + (PEN_LIMIT_SCALE_LO - PEN_LIMIT_SCALE_HI) * t;
}

static bool FindSpawnPosViaNavArea(int zc, int targetSur, float searchRange, bool teleportMode,
                                   float outPos[3], int &outAreaIdx, SpawnScoreDbg dbgOut)
{
    const int TOPK = 12;
    if (!GetSurPosData()) { Debug_Print("[FIND FAIL] no survivor data"); return false; }

    EnsureNavAreasCache();
    int iAreaCount = g_NavAreasCacheCount;
    
    float fMapMaxFlowDist    = L4D2Direct_GetMapMaxFlowDistance();
    bool  bFinaleArea        = L4D_IsMissionFinalMap() && L4D2_GetCurrentFinaleStage() < 18;
    float now                = GetGameTime();

    float center[3]; GetSectorCenter(center, targetSur);
    int   sectors         = GetCurrentSectors();
    int   preferredSector = PickSector(sectors);

    float allMinZ = 1.0e9, allMaxZ = -1.0e9;
    int   allMinFlowBucket = 100;
    SurPosData data;
    for (int si = 0; si < g_iSurPosDataLen; si++) {
        g_aSurPosData.GetArray(si, data);
        if (data.fPos[2] < allMinZ) allMinZ = data.fPos[2];
        if (data.fPos[2] > allMaxZ) allMaxZ = data.fPos[2];
        int sb = FlowDistanceToPercent(data.fFlow);
        if (sb < allMinFlowBucket) allMinFlowBucket = sb;
    }

    int centerBucket = 50;
    if (IsValidSurvivor(targetSur) && IsPlayerAlive(targetSur) && !L4D_IsPlayerIncapacitated(targetSur)) {
        int pct;
        if (TryGetClientFlowPercentSafe(targetSur, pct)) centerBucket = pct;
    } else {
        float bestFlow = -1.0; SurPosData data2;
        for (int si = 0; si < g_iSurPosDataLen; si++) {
            g_aSurPosData.GetArray(si, data2);
            if (data2.fFlow > bestFlow) bestFlow = data2.fFlow;
        }
        if (bestFlow >= 0.0) centerBucket = FlowDistanceToPercent(bestFlow);
    }

    float refEyeZ = allMaxZ;
    if (IsValidSurvivor(targetSur) && IsPlayerAlive(targetSur) && !L4D_IsPlayerIncapacitated(targetSur)) {
        float e[3]; GetClientEyePosition(targetSur, e); refEyeZ = e[2];
    }

    bool  found     = false;
    float bestScore = -1.0e9;
    int   bestIdx   = -1;
    float bestPos[3];
    int acceptedHits = 0;
    int cFilt_CD=0, cFilt_Flag=0, cFilt_Flow=0, cFilt_Dist=0, cFilt_Sep=0, cFilt_Stuck=0, cFilt_Vis=0, cFilt_Path=0, cFilt_Pos=0, cFilt_Score=0, cFilt_Bucket=0;

    bool  useBuckets = (gCV.bNavBucketEnable && g_BucketsReady);
    bool  firstFit   = gCV.bNavBucketFirstFit;
    float ffThresh   = ComputeFFThresholdForClass(zc);
    float minScore   = gCV.fSpawnScoreFloor;
    float ffScoreThresh = FloatMax(ffThresh, minScore);

    SpawnScoreDbg bestDbg;

    if (useBuckets)
    {
        int win = ComputeDynamicBucketWindow(searchRange);
        if (win < 0) win = 0; if (win > 100) win = 100;

        int order[FLOW_BUCKETS];
        int orderLen = BuildBucketOrder(centerBucket, win, gCV.bNavBucketIncludeCtr, order);

        for (int oi = 0; oi < orderLen; oi++)
        {
            int b = order[oi];
            if (b < 0 || b > 100 || g_FlowBuckets[b] == null) continue;

            int L = g_FlowBuckets[b].Length;
            if (L <= 0) continue;

            for (int r = 0; r < L && acceptedHits < TOPK; r++)
            {
                int ai = g_FlowBuckets[b].Get(r);

                if (IsNavOnCooldown(ai, now)) { cFilt_CD++; continue; }

                Address areaAddr = g_AllNavAreasCache.Get(ai);
                NavArea pArea = view_as<NavArea>(areaAddr);
                
                if (!pArea || !IsValidFlags(pArea.SpawnAttributes, bFinaleArea)) 
                { 
                    cFilt_Flag++; 
                    continue; 
                }

                float p[3]; pArea.GetRandomPoint(p);

                float bMinZ = g_BucketMinZ[b], bMaxZ = g_BucketMaxZ[b];
                if (bMaxZ <= bMinZ) { bMinZ = allMinZ - 50.0; bMaxZ = allMaxZ + 50.0; }

                float slack = 0.0;
                if (zc != view_as<int>(SI_Charger) && zc != view_as<int>(SI_Jockey))
                    slack = HeightRingSlack(p, bMinZ, bMaxZ, allMaxZ);

                float ringEff = FloatMin(searchRange + slack, gCV.fSpawnMax);
                float dminEye = GetMinEyeDistToAnySurvivor(p);

                if (!(dminEye >= gCV.fSpawnMin && dminEye <= ringEff)) { cFilt_Dist++; continue; }
                if (!PassMinSeparation(p))           { cFilt_Sep++;   continue; }
                if (!PassRealPositionCheck(p, targetSur, zc)) { cFilt_Pos++; continue; }
                if (WillStuck(p))                    { cFilt_Stuck++; continue; }
                if (IsPosVisibleSDK(p, teleportMode)){ cFilt_Vis++;   continue; }
                if (PathPenalty_NoBuild(p, targetSur, searchRange, gCV.fSpawnMax) != 0.0) { cFilt_Path++; continue; }

                // --- 评分 ---
                int   candBucket = b;
                if (!PassBucketShareLimit(candBucket)) { cFilt_Bucket++; continue; }

                // 这里 candBucket 仍用桶号；但我们额外取一遍原始 flow，判断“raw badflow”
                float fRaw = pArea.GetFlow();
                bool  rawBadFlow = IsFlowAbnormal(fRaw, fMapMaxFlowDist);   // [MOD] 新增：只用于决定是否套高度惩罚

                int   sidx       = ComputeSectorIndex(center, p, sectors);
                int   deltaFlow  = candBucket - centerBucket;

                float sweet, width; GetClassDistanceProfile(zc, gCV.fSpawnMin, ringEff, sweet, width);
                float score_dist = ScoreDistSmooth(dminEye, sweet, width);
                float score_hght = CalculateScore_Height(zc, p, refEyeZ);

                // 使用 base - penalty（与 NavPeek 一致）
                float flow_base = ScoreFlowSmooth(deltaFlow);
                float flow_pen  = rawBadFlow ? ComputeBadFlowHeightPenalty(/*candZ=*/p[2], /*refBestEyeZ=*/allMaxZ) : 0.0;
                float score_flow = flow_base - flow_pen;

                // 与 NavPeek 同样的上下限
                if (score_flow > 100.0) score_flow = 100.0;
                if (score_flow < -200.0) score_flow = -200.0;

                // ★ 关键：坏 flow 且评分 < 0 直接丢弃，不进入总分
                if (rawBadFlow && score_flow < 0.0) { cFilt_Flow++; continue; }

                float score_disp = CalculateScore_Dispersion(sidx, preferredSector, recentSectors);

                float penK       = ComputePenScaleByLimit(gCV.iSiLimit);
                float dispScaled = ScaleNegativeOnly(score_disp, penK);

                float totalScore = gCV.w_dist[zc]*score_dist + gCV.w_hght[zc]*score_hght
                                + gCV.w_flow[zc]*score_flow + gCV.w_disp[zc]*dispScaled;

                if (totalScore < minScore) { cFilt_Score++; continue; }

                acceptedHits++;

                if (firstFit && totalScore >= ffScoreThresh) {
                    dbgOut.total = totalScore; dbgOut.dist = score_dist; dbgOut.hght = score_hght; dbgOut.flow = score_flow;
                    dbgOut.dispRaw = score_disp; dbgOut.dispScaled = dispScaled; dbgOut.penK = penK;
                    dbgOut.dminEye = dminEye; dbgOut.ringEff = ringEff; dbgOut.slack = slack;
                    dbgOut.candBucket = candBucket; dbgOut.centerBucket = centerBucket; dbgOut.deltaFlow = deltaFlow;
                    dbgOut.sector = sidx; dbgOut.areaIdx = ai; dbgOut.pos = p;

                    outPos = p; outAreaIdx = ai;
                    return true;
                }

                if (!found || totalScore > bestScore) {
                    found     = true;
                    bestScore = totalScore;
                    bestIdx   = ai;
                    bestPos   = p;

                    bestDbg.total = totalScore; bestDbg.dist = score_dist; bestDbg.hght = score_hght; bestDbg.flow = score_flow;
                    bestDbg.dispRaw = score_disp; bestDbg.dispScaled = dispScaled; bestDbg.penK = penK;
                    bestDbg.dminEye = dminEye; bestDbg.ringEff = ringEff; bestDbg.slack = slack;
                    bestDbg.candBucket = candBucket; bestDbg.centerBucket = centerBucket; bestDbg.deltaFlow = deltaFlow;
                    bestDbg.sector = sidx; bestDbg.areaIdx = ai; bestDbg.pos = p;
                }
            }
            if (acceptedHits >= TOPK) break;
        }
    }
    else
    {
        for (int ai = 0; ai < iAreaCount && acceptedHits < TOPK; ai++)
        {
            if (IsNavOnCooldown(ai, now)) { cFilt_CD++; continue; }

            Address areaAddr = g_AllNavAreasCache.Get(ai);
            NavArea pArea = view_as<NavArea>(areaAddr);
            
            if (!pArea || !IsValidFlags(pArea.SpawnAttributes, bFinaleArea)) 
            { 
                cFilt_Flag++; 
                continue; 
            }

            float fFlow = pArea.GetFlow();
            if (fFlow < 0.0 || fFlow > fMapMaxFlowDist) { cFilt_Flow++; continue; }  // 非桶模式：原本就直接过滤掉 badflow

            float p[3]; pArea.GetRandomPoint(p);

            int candBucketForHeight = FlowDistanceToPercent(fFlow);
            float bMinZ = g_BucketMinZ[candBucketForHeight], bMaxZ = g_BucketMaxZ[candBucketForHeight];
            if (bMaxZ <= bMinZ) { bMinZ = allMinZ - 50.0; bMaxZ = allMaxZ + 50.0; }

            float slack = 0.0;
            if (zc != view_as<int>(SI_Charger) && zc != view_as<int>(SI_Jockey))
                slack = HeightRingSlack(p, bMinZ, bMaxZ, allMaxZ);

            float ringEff = FloatMin(searchRange + slack, gCV.fSpawnMax);
            float dminEye = GetMinEyeDistToAnySurvivor(p);

            if (!(dminEye >= gCV.fSpawnMin && dminEye <= ringEff)) { cFilt_Dist++; continue; }
            if (!PassMinSeparation(p))           { cFilt_Sep++;   continue; }
            if (!PassRealPositionCheck(p, targetSur, zc)) { cFilt_Pos++; continue; }
            if (WillStuck(p))                    { cFilt_Stuck++; continue; }
            if (IsPosVisibleSDK(p, teleportMode)){ cFilt_Vis++;   continue; }
            if (PathPenalty_NoBuild(p, targetSur, searchRange, gCV.fSpawnMax) != 0.0) { cFilt_Path++; continue; }

            // --- 评分 ---
            int   candBucket = FlowDistanceToPercent(fFlow);
            if (!PassBucketShareLimit(candBucket)) { cFilt_Bucket++; continue; }
            bool  rawBadFlow = IsFlowAbnormal(fFlow, fMapMaxFlowDist);   // [MOD] 新增：只用于决定是否套高度惩罚
            int   sidx       = ComputeSectorIndex(center, p, sectors);
            int   deltaFlow  = candBucket - centerBucket;

            float sweet, width; GetClassDistanceProfile(zc, gCV.fSpawnMin, ringEff, sweet, width);
            float score_dist = ScoreDistSmooth(dminEye, sweet, width);
            float score_hght = CalculateScore_Height(zc, p, refEyeZ);
            float flow_base = ScoreFlowSmooth(deltaFlow);
            float flow_pen  = rawBadFlow ? ComputeBadFlowHeightPenalty(/*candZ=*/p[2], /*refBestEyeZ=*/allMaxZ) : 0.0;
            float score_flow = flow_base - flow_pen;

            if (score_flow > 100.0) score_flow = 100.0;
            if (score_flow < -200.0) score_flow = -200.0;

            if (rawBadFlow && score_flow < 0.0) { cFilt_Flow++; continue; }

            float score_disp = CalculateScore_Dispersion(sidx, preferredSector, recentSectors);

            float penK       = ComputePenScaleByLimit(gCV.iSiLimit);
            float dispScaled = ScaleNegativeOnly(score_disp, penK);

            float totalScore = gCV.w_dist[zc]*score_dist + gCV.w_hght[zc]*score_hght
                             + gCV.w_flow[zc]*score_flow + gCV.w_disp[zc]*dispScaled;

            if (totalScore < minScore) { cFilt_Score++; continue; }

            acceptedHits++;

            if (firstFit && totalScore >= ffScoreThresh) {
                dbgOut.total = totalScore; dbgOut.dist = score_dist; dbgOut.hght = score_hght; dbgOut.flow = score_flow;
                dbgOut.dispRaw = score_disp; dbgOut.dispScaled = dispScaled; dbgOut.penK = penK;
                dbgOut.dminEye = dminEye; dbgOut.ringEff = ringEff; dbgOut.slack = slack;
                dbgOut.candBucket = candBucket; dbgOut.centerBucket = centerBucket; dbgOut.deltaFlow = deltaFlow;
                dbgOut.sector = sidx; dbgOut.areaIdx = ai; dbgOut.pos = p;

                outPos = p; outAreaIdx = ai;
                return true;
            }

            if (!found || totalScore > bestScore) {
                found     = true;
                bestScore = totalScore;
                bestIdx   = ai;
                bestPos   = p;

                bestDbg.total = totalScore; bestDbg.dist = score_dist; bestDbg.hght = score_hght; bestDbg.flow = score_flow;
                bestDbg.dispRaw = score_disp; bestDbg.dispScaled = dispScaled; bestDbg.penK = penK;
                bestDbg.dminEye = dminEye; bestDbg.ringEff = ringEff; bestDbg.slack = slack;
                bestDbg.candBucket = candBucket; bestDbg.centerBucket = centerBucket; bestDbg.deltaFlow = deltaFlow;
                bestDbg.sector = sidx; bestDbg.areaIdx = ai; bestDbg.pos = p;
            }
        }
    }

    if (!found) {
        Debug_Print("[FIND FAIL] ring=%.1f. Filters: cd=%d,flag=%d,flow=%d,dist=%d,sep=%d,stuck=%d,vis=%d,path=%d,pos=%d,score=%d,bkt=%d",
                    searchRange, cFilt_CD, cFilt_Flag, cFilt_Flow, cFilt_Dist, cFilt_Sep, cFilt_Stuck, cFilt_Vis, cFilt_Path, cFilt_Pos, cFilt_Score, cFilt_Bucket);
        return false;
    }

    outPos = bestPos; outAreaIdx = bestIdx; dbgOut = bestDbg; return true;
}

// [新增] —— 生成缓存 Key（NavAreaID + 量化后的 limitCost）
stock void PathCache_BuildKey(Address navGoal, Address navStart, float limitCost, char[] outKey, int maxlen)
{
    int idG = (navGoal  != Address_Null) ? L4D_GetNavAreaID(navGoal)  : -1;
    int idS = (navStart != Address_Null) ? L4D_GetNavAreaID(navStart) : -1;
    int q   = RoundToNearest(limitCost / gCV.fPathCacheQuantize); // 量化，避免 key 激增
    Format(outKey, maxlen, "%d|%d|%d", idG, idS, q);
}

// [新增] —— 简单读写（无 TTL）
stock bool PathCache_TryGetSimple(const char[] key, bool &okOut)
{
    if (g_PathCacheRes == null) return false;
    any resAny;
    if (!g_PathCacheRes.GetValue(key, resAny)) return false;
    okOut = (view_as<int>(resAny) != 0);
    return true;
}

stock void PathCache_PutSimple(const char[] key, bool ok)
{
    if (g_PathCacheRes == null) return;
    g_PathCacheRes.SetValue(key, view_as<any>(ok ? 1 : 0));
}
// [修改] —— 仅清结果表
static void ClearPathCache()
{
    if (g_PathCacheRes != null) g_PathCacheRes.Clear();
}

// [修改] —— 整函数覆盖：使用波级缓存（无 TTL）
stock float PathPenalty_NoBuild(const float candPos[3], int targetSur, float ring, float spawnmax)
{
    // 选目标幸存者：优先 targetSur，其次任意存活
    int surv = -1;
    if (IsValidSurvivor(targetSur) && IsPlayerAlive(targetSur) && !L4D_IsPlayerIncapacitated(targetSur))
    {
        surv = targetSur;
    }
    else
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidSurvivor(i) && IsPlayerAlive(i) && !L4D_IsPlayerIncapacitated(i))
            { surv = i; break; }
        }
    }
    if (surv == -1) return PATH_NO_BUILD_PENALTY; // 没有可用幸存者，按“不可达”

    // 生还者位置（与你 SpawnInfected 的口径一致）
    float survPos[3];
    GetClientEyePosition(surv, survPos);
    survPos[2] -= 60.0;

    // 找最近 NavArea
    Address navGoal  = L4D_GetNearestNavArea(candPos, 120.0, false, false, false, TEAM_INFECTED);
    Address navStart = L4D_GetNearestNavArea(survPos, 120.0, false, false, false, TEAM_INFECTED);
    if (!navGoal || !navStart) return PATH_NO_BUILD_PENALTY;

    // 代价上限：min(ring*3, spawnmax*1.5)
    float limitCost = FloatMin(ring * 3.0, spawnmax * 1.5);

    if (gCV.bPathCacheEnable)
    {
        char key[64];
        PathCache_BuildKey(navGoal, navStart, limitCost, key, sizeof key);

        bool okCached;
        if (PathCache_TryGetSimple(key, okCached))
            return okCached ? 0.0 : PATH_NO_BUILD_PENALTY;

        bool ok = L4D2_NavAreaBuildPath(navGoal, navStart, limitCost, TEAM_INFECTED, false);
        PathCache_PutSimple(key, ok);
        return ok ? 0.0 : PATH_NO_BUILD_PENALTY;
    }

    // 不启用缓存：直接判定
    bool ok = L4D2_NavAreaBuildPath(navGoal, navStart, limitCost, TEAM_INFECTED, false);
    return ok ? 0.0 : PATH_NO_BUILD_PENALTY;
}


// =========================
// Spawn / Command helpers
// =========================
// =========================
// Spawn / Command helpers（改：使用眼睛距离判定 SpawnMin）
// =========================
static bool DoSpawnAt(const float pos[3], int zc)
{
    // 使用“眼睛距离”作为硬下限口径，统一与你想要的判定方式
    if (GetMinEyeDistToAnySurvivor(pos) < gCV.fSpawnMin)
    {
        Debug_Print("[SPAWN BLOCK] too close (< SpawnMin=%.1f) at (%.1f %.1f %.1f)",
                    gCV.fSpawnMin, pos[0], pos[1], pos[2]);
        return false;
    }

    int idx = L4D2_SpawnSpecial(zc, pos, NULL_VECTOR);
    if (idx > 0)
    {
        // 记录“最近一次成功刷出”的时间（用于超时放宽）
        g_LastSpawnOkTime = GetGameTime();

        Debug_Print("[SPAWN OK] %s idx=%d at (%.1f %.1f %.1f)", INFDN[zc], idx, pos[0], pos[1], pos[2]);
        RecalcSiCapFromAlive(false);
        return true;
    }

    Debug_Print("[SPAWN FAIL] %s at (%.1f %.1f %.1f) -> idx=%d", INFDN[zc], pos[0], pos[1], pos[2], idx);
    return false;
}

// 采样 NavArea 的“几何中心近似 + 高度统计”
static void SampleAreaCenterAndZ(Address areaAddr, float &cx, float &cy, float &zAvg, float &zMin, float &zMax, int samples = 3)
{
    cx = cy = 0.0; zAvg = 0.0; zMin = 1.0e9; zMax = -1.0e9;
    if (areaAddr == Address_Null || samples <= 0) { zMin = zMax = zAvg = 0.0; return; }

    NavArea area = view_as<NavArea>(areaAddr);
    float p[3];

    for (int i = 0; i < samples; i++)
    {
        area.GetRandomPoint(p);
        cx   += p[0];
        cy   += p[1];
        zAvg += p[2];
        if (p[2] < zMin) zMin = p[2];
        if (p[2] > zMax) zMax = p[2];
    }
    float inv = 1.0 / float(samples);
    cx   *= inv;
    cy   *= inv;
    zAvg *= inv;
}

static void BypassAndExecuteCommand(const char[] cmd)
{
    if (!CheatsOn()) return;
    ServerCommand("%s", cmd);
}
// 计算到任意幸存者“眼睛”的最小距离（用于 DoSpawnAt 的硬下限判定）
static float GetMinEyeDistToAnySurvivor(const float p[3])
{
    float best = 999999.0;
    float eyes[3];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidSurvivor(i) || !IsPlayerAlive(i))
            continue;

        GetClientEyePosition(i, eyes);
        float d = GetVectorDistance(p, eyes);
        if (d < best) best = d;
    }
    return best;
}

// =========================
// SI 选择 / 限制
// =========================
static bool CheckClassEnabled(int zc)
{
    int bit = 1 << (zc - 1);
    return (gCV.iEnableMask & bit) != 0;
}

// 重要：只按“活着的”判断是否到达每类上限（不把队列算进上限）
static bool HasReachedLimit(int zc)
{
    int idx = zc - 1;
    if (idx < 0 || idx >= 6) return true;

    int cap = gST.siAlive[idx] + gST.siCap[idx];
    return gST.siAlive[idx] >= cap;
}
// 统计 spawn 队列中某类的数量（不含 teleport 队列）
static int CountQueuedOfClass(int zc)
{
    int n = 0;
    for (int i = 0; i < gQ.spawn.Length; i++)
    {
        if (gQ.spawn.Get(i) == zc)
            n++;
    }
    return n;
}

// 是否还能把该类加入 spawn 队列：活着 + 已入队 < 该类总额度（alive + remain）
static bool CanQueueClass(int zc)
{
    int idx = zc - 1;
    if (idx < 0 || idx >= 6) return false;

    int capTotal = gST.siAlive[idx] + gST.siCap[idx];
    return (gST.siAlive[idx] + CountQueuedOfClass(zc)) < capTotal;
}

static bool TryLoadBucketsFromCache()
{
    if (!gCV.bNavCacheEnable) return false;

    MakeBucketCachePath();
    if (!FileExists(g_sBucketCachePath)) return false;

    KeyValues kv = new KeyValues("BucketsCache");
    if (!kv.ImportFromFile(g_sBucketCachePath)) { delete kv; return false; }

    kv.Rewind();
    char ver[64]; kv.GetString("version", ver, sizeof ver, "");
    if (!StrEqual(ver, BUCKET_CACHE_VER))
    { delete kv; return false; }

    char map[64], mapCur[64];
    GetCurrentMap(mapCur, sizeof mapCur);
    kv.GetString("map", map, sizeof map, "");
    if (!StrEqual(map, mapCur))
    { delete kv; return false; }

    // ✅ 使用缓存
    EnsureNavAreasCache();
    int currentAreaCount = g_NavAreasCacheCount;

    int areaCount = kv.GetNum("area_count", -1);
    if (areaCount <= 0 || areaCount != currentAreaCount)
    { delete kv; return false; }

    float maxFlowCur = L4D2Direct_GetMapMaxFlowDistance();
    float maxFlowCached = kv.GetFloat("max_flow", -1.0);
    if (FloatAbs(maxFlowCached - maxFlowCur) > 0.1)
    { delete kv; return false; }

    // 影响分桶的运行参数（变了就作废）
    float bufCur = gCV.VsBossFlowBuffer.FloatValue;
    float bufCached = kv.GetFloat("vsboss_buffer", 0.0);
    int   mapInvalidCur = gCV.bNavBucketMapInvalid ? 1 : 0;
    int   mapInvalidCac = kv.GetNum("map_invalid", 1);
    float assignRcur    = gCV.fNavBucketAssignRadius;
    float assignRcac    = kv.GetFloat("assign_radius", 0.0);

    // 【修改】去掉 stuck_probe 的一致性校验
    if (FloatAbs(bufCur-bufCached)>0.01 || mapInvalidCur!=mapInvalidCac ||
        FloatAbs(assignRcur-assignRcac)>0.5)
    { delete kv; return false; }

    // 清理并初始化容器
    ClearNavBuckets();
    BuildNavIdIndexMap();

    g_AreaZCore = new ArrayList();
    g_AreaZMin  = new ArrayList();
    g_AreaZMax  = new ArrayList();
    g_AreaCX    = new ArrayList();
    g_AreaCY    = new ArrayList();
    g_AreaPct   = new ArrayList();

    for (int i = 0; i < areaCount; i++)
    { g_AreaZCore.Push(0.0); g_AreaZMin.Push(0.0); g_AreaZMax.Push(0.0); g_AreaCX.Push(0.0); g_AreaCY.Push(0.0); g_AreaPct.Push(-1); }

    for (int b = 0; b < FLOW_BUCKETS; b++)
    { g_BucketMinZ[b] =  1.0e9; g_BucketMaxZ[b] = -1.0e9; }

    // 桶 Z 范围
    if (kv.JumpToKey("bucket_zrange", false))
    {
        for (int b = 0; b <= 100; b++)
        {
            char k[8]; IntToString(b, k, sizeof k);
            if (kv.JumpToKey(k, false))
            {
                g_BucketMinZ[b] = kv.GetFloat("min", 0.0);
                g_BucketMaxZ[b] = kv.GetFloat("max", 0.0);
                kv.GoBack();
            }
        }
        kv.GoBack();
    }

    // areas
    if (!kv.JumpToKey("areas", false))
    { delete kv; return false; }

    if (kv.GotoFirstSubKey(false))
    {
        do {
            char sNav[16]; kv.GetSectionName(sNav, sizeof sNav);
            int navid = StringToInt(sNav);
            int idx = GetAreaIndexByNavID_Int(navid);
            if (idx < 0) continue;

            int bucket = kv.GetNum("bucket", -1);
            if (bucket < 0 || bucket > 100) continue;

            float cx = kv.GetFloat("cx", 0.0);
            float cy = kv.GetFloat("cy", 0.0);
            float zc = kv.GetFloat("zCore", 0.0);
            float zmin = kv.GetFloat("zMin", 0.0);
            float zmax = kv.GetFloat("zMax", 0.0);

            g_AreaCX.Set(idx, cx);
            g_AreaCY.Set(idx, cy);
            g_AreaZCore.Set(idx, zc);
            g_AreaZMin.Set(idx, zmin);
            g_AreaZMax.Set(idx, zmax);
            g_AreaPct.Set(idx, bucket);

            if (g_FlowBuckets[bucket] == null)
                g_FlowBuckets[bucket] = new ArrayList();
            g_FlowBuckets[bucket].Push(idx);

        } while (kv.GotoNextKey(false));
        kv.GoBack();
    }

    delete kv;
    g_BucketsReady = true;
    Debug_Print("[BUCKET] loaded from cache: %s", g_sBucketCachePath);
    return true;
}

static void SaveBucketsToCache()
{
    if (!gCV.bNavCacheEnable || !g_BucketsReady) return;

    MakeBucketCachePath();

    KeyValues kv = new KeyValues("BucketsCache");
    kv.SetString("version", BUCKET_CACHE_VER);

    char map[64]; GetCurrentMap(map, sizeof map);
    kv.SetString("map", map);

    // ✅ 使用缓存
    EnsureNavAreasCache();
    int areaCount = g_NavAreasCacheCount;

    kv.SetNum("area_count", areaCount);
    kv.SetFloat("max_flow", L4D2Direct_GetMapMaxFlowDistance());
    kv.SetFloat("vsboss_buffer", gCV.VsBossFlowBuffer.FloatValue);
    kv.SetNum("map_invalid", gCV.bNavBucketMapInvalid ? 1 : 0);
    kv.SetFloat("assign_radius", gCV.fNavBucketAssignRadius);

    // 桶 Z 范围
    kv.JumpToKey("bucket_zrange", true);
    for (int b = 0; b <= 100; b++)
    {
        char k[8]; IntToString(b, k, sizeof k);
        kv.JumpToKey(k, true);
        kv.SetFloat("min", g_BucketMinZ[b]);
        kv.SetFloat("max", g_BucketMaxZ[b]);
        kv.GoBack();
    }
    kv.GoBack();

    // areas
    kv.JumpToKey("areas", true);
    for (int i = 0; i < areaCount; i++)
    {
        int navid = GetNavIDByIndex(i);
        if (navid < 0) continue;

        int bucket = view_as<int>(g_AreaPct.Get(i));
        if (bucket < 0 || bucket > 100) continue;

        char sNav[16]; IntToString(navid, sNav, sizeof sNav);
        kv.JumpToKey(sNav, true);

        kv.SetNum("bucket", bucket);
        kv.SetFloat("cx", view_as<float>(g_AreaCX.Get(i)));
        kv.SetFloat("cy", view_as<float>(g_AreaCY.Get(i)));
        kv.SetFloat("zCore", view_as<float>(g_AreaZCore.Get(i)));
        kv.SetFloat("zMin", view_as<float>(g_AreaZMin.Get(i)));
        kv.SetFloat("zMax", view_as<float>(g_AreaZMax.Get(i)));

        kv.GoBack();
    }
    kv.GoBack();

    kv.ExportToFile(g_sBucketCachePath);
    delete kv;
    Debug_Print("[BUCKET] saved to cache: %s", g_sBucketCachePath);
}

// =========================
// Gamedata / SDK（简化版 - 只保留 MaxSpecial unlock）
// =========================
static void InitSDK_FromGamedata()
{
    char sBuffer[128];

    strcopy(sBuffer, sizeof(sBuffer), "infected_control");
    GameData hGameData = new GameData(sBuffer);
    if (hGameData == null)
        SetFailState("Failed to load \"%s.txt\" gamedata.", sBuffer);

    // Unlock Max SI limit - 这是唯一需要保留的 gamedata patch
    strcopy(sBuffer, sizeof(sBuffer), "CDirector::GetMaxPlayerZombies");
    MemoryPatch mPatch = MemoryPatch.CreateFromConf(hGameData, sBuffer);
    if (!mPatch.Validate())
        SetFailState("Failed to verify patch: %s", sBuffer);
    if (!mPatch.Enable())
        SetFailState("Failed to Enable patch: %s", sBuffer);

    delete hGameData;
}

// --- Math helpers --- 
stock float FloatMax(float a, float b) { return (a > b) ? a : b; } 
stock float FloatMin(float a, float b) { return (a < b) ? a : b; }
stock float Clamp01(float v) { if (v < 0.0) return 0.0; if (v > 1.0) return 1.0; return v; }
// [ADD] int 夹取
stock int clampi(int v, int lo, int hi) { if (v<lo) return lo; if (v>hi) return hi; return v; }

// [ADD] 负向分散度惩罚随上限 L 变弱（用你给的宏）
stock float ComputePenScaleByLimit(int L) {
    int Lc = clampi(L, PEN_LIMIT_MINL, PEN_LIMIT_MAXL);
    float t = float(Lc - PEN_LIMIT_MINL) / float(PEN_LIMIT_MAXL - PEN_LIMIT_MINL); // 0..1
    return PEN_LIMIT_SCALE_HI + (PEN_LIMIT_SCALE_LO - PEN_LIMIT_SCALE_HI) * t;
}
stock float ScaleNegativeOnly(float v, float k) { return (v < 0.0) ? (v * k) : v; }

// 在 LogChosenSpawnScore 中增加（约第2900行）
static void LogChosenSpawnScore(int zc, const SpawnScoreDbg dbg) 
{
    if (gCV.iDebugMode <= 0) return;
    
    // ✅ 计算真实位置关系
    int candReal = GetPositionBucketPercent(dbg.pos);
    int surReal = -1;
    int fb = GetHighestFlowSurvivorSafe();
    TryGetClientFlowPercentSafe(fb, surReal);
    
    Debug_Print("[SCORE-CHOSEN] %s pos=(%.1f,%.1f,%.1f) area=%d | tot=%.1f | dist=%.1f h=%.1f flow=%.1f disp=%.1f->%.1f(pK=%.2f) | dEye=%.1f ringEff=%.1f slack=%.1f | bkt=%d ctr=%d dF=%d sec=%d | REAL: cand=%d%% sur=%d%% delta=%d%%",
        INFDN[zc], dbg.pos[0], dbg.pos[1], dbg.pos[2], dbg.areaIdx,
        dbg.total, dbg.dist, dbg.hght, dbg.flow, dbg.dispRaw, dbg.dispScaled, dbg.penK,
        dbg.dminEye, dbg.ringEff, dbg.slack, 
        dbg.candBucket, dbg.centerBucket, dbg.deltaFlow, dbg.sector,
        candReal, surReal, candReal - surReal);  // ✅ 真实位置关系
}
// --- pause
public void OnPause()
{
    PauseSpawnTimer();
}
static bool CheatsOn()
{
    ConVar sv = FindConVar("sv_cheats");
    return (sv != null && sv.BoolValue);
}

static void EmitRushmanForward(int survivor)
{
    if (g_hRushManNotifyForward != INVALID_HANDLE)
    {
        Call_StartForward(g_hRushManNotifyForward);
        Call_PushCell(survivor);   // 跑男目标
        Call_Finish();
    }
}
stock int GetSepMax()
{
    int cap = gCV.iSiLimit;       // 与特感数量上限一致
    if (cap < 0)  cap = 0;        // 下限保护
    if (cap > 20) cap = 20;       // 上限保护（可按需调大）
    return cap;
}
