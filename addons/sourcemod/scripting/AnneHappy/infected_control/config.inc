#if defined _infected_control_config_included
    #endinput
#endif
#define _infected_control_config_included

static const float DEFAULT_AI_WAVE_CHECK_RATIO[AI_LEVEL_SLOTS] = { 0.0, 0.90, 0.80, 0.65, 0.50, 0.35 };
static const float DEFAULT_AI_WAVE_FLOOR_RATIO[AI_LEVEL_SLOTS] = { 0.0, 1.35, 1.25, 1.12, 1.00, 1.00 };
static const float DEFAULT_AI_WAVE_LOW_SI_RATIO[AI_LEVEL_SLOTS] = { 0.0, 0.12, 0.20, 0.27, 0.34, 0.50 };
static const float DEFAULT_AI_DIST_SWEET_OFFSET[AI_LEVEL_SLOTS] = { 0.0, 0.00, 0.00, 0.00, 0.00, 0.00 };
static const float DEFAULT_AI_DIST_WIDTH_SCALE[AI_LEVEL_SLOTS] = { 0.0, 1.25, 1.15, 1.08, 1.00, 1.00 };
static const float DEFAULT_AI_SPAWN_BUDGET_BONUS[AI_LEVEL_SLOTS] = { 0.0, -3.0, -2.0, -1.0, 0.0, 0.0 };

static void Config_ParseDifficultyFloatList(ConVar convar, const float defaults[AI_LEVEL_SLOTS], float values[AI_LEVEL_SLOTS], float minValue, float maxValue)
{
    char buffer[256];
    char parts[AI_DIFFICULTY_LEVELS][24];
    convar.GetString(buffer, sizeof(buffer));

    int count = ExplodeString(buffer, " ", parts, AI_DIFFICULTY_LEVELS, 24);
    for (int level = 1; level <= AI_DIFFICULTY_LEVELS; level++)
    {
        float value = defaults[level];
        if (level <= count)
            value = StringToFloat(parts[level - 1]);

        values[level] = ClampFloat(value, minValue, maxValue);
    }
}

enum struct Config
{
    ConVar SpawnMin;
    ConVar SpawnMax;
    ConVar TeleportEnable;
    ConVar TeleportSpawnMin;
    ConVar LegacyTeleportSpawnMin;
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
    ConVar SurvivorLimit;
    ConVar DirectorNoSpecials;
    ConVar AiDifficultyLevel;

    // —— AI 难度联动策略 —— //
    ConVar AiDifficultyLink;
    ConVar AiDifficultyFallbackLevel;
    ConVar AiWaveCheckRatio;
    ConVar AiWaveFloorRatio;
    ConVar AiWaveLowSiRatio;
    ConVar AiDistSweetOffset;
    ConVar AiDistWidthScale;
    ConVar AiSpawnBudgetBonus;

    // —— Nav 分桶 —— //
    ConVar NavBucketEnable;
    ConVar NavBucketWindow;

    // —— 动态分桶 —— //
    ConVar NavBucketLinkToRing;   // 1=跟随扩圈动态调整桶窗口
    ConVar NavBucketWindowMin;    // ring<=MinAt 时窗口(±N)
    ConVar NavBucketWindowMax;    // ring>=MaxAt 时窗口(±N)
    ConVar NavBucketMinAt;        // ring 下界
    ConVar NavBucketMaxAt;        // ring 上界

    // —— 分桶策略增强 —— //
    ConVar NavBucketFirstFit;     // 找到第一个合格点就返回
    ConVar NavBucketIncludeCtr;   // 是否包含中心桶 s

    // —— 死亡CD（两档） —— //
    ConVar DeathCDKiller;
    ConVar DeathCDSupport;

    // —— 死亡CD放宽的“双保险” —— //
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
    ConVar NavBucketMapInvalid;        // 将坏flow的NavArea映射到就近正常桶
    ConVar NavBucketAssignRadius;      // 可选：就近半径上限(0=不限)
    ConVar gCvarNavCacheEnable;
    // 评分系统权重与参数
    ConVar Score_w_dist;
    ConVar Score_w_hght;
    ConVar Score_w_flow;
    ConVar Score_w_disp;

    ConVar PathCacheEnable;
    ConVar PathCacheQuantize;
    ConVar FrameThinkStep;
    ConVar FrameThinkStepActive;
    ConVar SpawnCandidateBudget;
    ConVar BucketCountCacheTTL;
    // 轻度惩罚 badflow：仅扣 Flow 分项一点点分数（0 关闭）
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

    // === Anti-baiter / 停滞压力控制 ===
    ConVar AntiBaitEnable;
    ConVar LegacyAntiBaitEnable;
    ConVar AntiBaitGrace;
    ConVar AntiBaitWindow;
    ConVar AntiBaitProgressPct;
    ConVar AntiBaitMinSiRatio;
    ConVar AntiBaitForceAfter;
    ConVar AntiBaitRecover;
    ConVar AntiBaitAction;
    ConVar AntiBaitRunnerGapPct;
    ConVar AntiBaitRunnerNearDist;
    ConVar AntiBaitFastTeleport;
    ConVar AntiBaitLatestBaseScale;
    ConVar AntiBaitLatestScaleStep;
    ConVar AntiBaitClusterDist;
    ConVar AntiBaitTeamDist;
    ConVar AntiBaitPairDist;
    ConVar AntiBaitIsolateDist;
    ConVar AntiBaitDebug;
    bool   bAntiBaitEnable;
    float  fAntiBaitGrace;
    float  fAntiBaitWindow;
    int    iAntiBaitProgressPct;
    float  fAntiBaitMinSiRatio;
    float  fAntiBaitForceAfter;
    float  fAntiBaitRecover;
    int    iAntiBaitAction;
    int    iAntiBaitRunnerGapPct;
    float  fAntiBaitRunnerNearDist;
    float  fAntiBaitFastTeleport;
    float  fAntiBaitLatestBaseScale;
    float  fAntiBaitLatestScaleStep;
    float  fAntiBaitClusterDist;
    float  fAntiBaitTeamDist;
    float  fAntiBaitPairDist;
    float  fAntiBaitIsolateDist;
    bool   bAntiBaitDebug;

    // 缓存值
    float fFlowBadPenalty;

    bool  bPathCacheEnable;
    float fPathCacheQuantize;
    float fFrameThinkStep;
    float fFrameThinkStepActive;
    float fBucketCountCacheTTL;
    int   iSpawnCandidateBudget;

    bool  bAiDifficultyLink;
    int   iAiDifficultyFallbackLevel;
    float fAiWaveCheckRatio[AI_LEVEL_SLOTS];
    float fAiWaveFloorRatio[AI_LEVEL_SLOTS];
    float fAiWaveLowSiRatio[AI_LEVEL_SLOTS];
    float fAiDistSweetOffset[AI_LEVEL_SLOTS];
    float fAiDistWidthScale[AI_LEVEL_SLOTS];
    float fAiSpawnBudgetBonus[AI_LEVEL_SLOTS];

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

    // —— 动态分桶 —— //
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

    void RefreshRuntimeConVars()
    {
        if (this.SurvivorLimit == null)
            this.SurvivorLimit = FindConVar("survivor_limit");
        if (this.DirectorNoSpecials == null)
            this.DirectorNoSpecials = FindConVar("director_no_specials");
        if (this.AiDifficultyLevel == null)
            this.AiDifficultyLevel = FindConVar("ah_ai_dynamic_current_level");
    }

    void Create()
    {
        this.SpawnMin          = CreateConVar("inf_SpawnDistanceMin", "250.0", "特感复活离生还者最近的距离限制", CVAR_FLAG, true, 0.0);
        this.TeleportSpawnMin  = CreateConVar("inf_TeleportDistanceMin", "400.0", "特感传送复活离生还者最近的距离限制", CVAR_FLAG, true, 0.0);
        this.LegacyTeleportSpawnMin = CreateConVar("inf_TeleportDistance", "400.0", "兼容旧配置：特感传送复活离生还者最近的距离限制", CVAR_FLAG, true, 0.0);
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

        this.AiDifficultyLink = CreateConVar(
            "inf_ai_difficulty_link", "1",
            "Link infected_control spawn strategy to ah_ai_dynamic_current_level (0/1)",
            CVAR_FLAG, true, 0.0, true, 1.0
        );
        this.AiDifficultyFallbackLevel = CreateConVar(
            "inf_ai_difficulty_fallback_level", "3",
            "Fallback spawn strategy level when dynamic AI difficulty is missing or not locked (1-5)",
            CVAR_FLAG, true, 1.0, true, 5.0
        );
        this.AiWaveCheckRatio = CreateConVar(
            "inf_ai_wave_check_ratio", "0.90 0.80 0.65 0.50 0.35",
            "Per AI level: when to start checking next-wave conditions, as respawn interval ratio",
            CVAR_FLAG
        );
        this.AiWaveFloorRatio = CreateConVar(
            "inf_ai_wave_floor_ratio", "1.35 1.25 1.12 1.00 1.00",
            "Per AI level: earliest normal next-wave time, as respawn interval ratio",
            CVAR_FLAG
        );
        this.AiWaveLowSiRatio = CreateConVar(
            "inf_ai_wave_low_si_ratio", "0.12 0.20 0.27 0.34 0.50",
            "Per AI level: alive SI ratio low enough to allow the next wave",
            CVAR_FLAG
        );
        this.AiDistSweetOffset = CreateConVar(
            "inf_ai_dist_sweet_offset", "0.00 0.00 0.00 0.00 0.00",
            "Per AI level: normalized offset applied to class spawn distance sweet spot; default keeps class-specific sweet spots unchanged",
            CVAR_FLAG
        );
        this.AiDistWidthScale = CreateConVar(
            "inf_ai_dist_width_scale", "1.25 1.15 1.08 1.00 1.00",
            "Per AI level: width multiplier for spawn distance scoring sweet zone",
            CVAR_FLAG
        );
        this.AiSpawnBudgetBonus = CreateConVar(
            "inf_ai_spawn_budget_bonus", "-3 -2 -1 0 0",
            "Per AI level: additive candidate budget adjustment for spawn scoring",
            CVAR_FLAG
        );

        // —— Nav 分桶（静态窗口） —— //
        this.NavBucketEnable   = CreateConVar("inf_NavBucketEnable", "1", "启用 Nav 进度分桶筛选(0=禁用,1=启用)", CVAR_FLAG, true, 0.0, true, 1.0);
        this.NavBucketWindow   = CreateConVar("inf_NavBucketWindow", "10", "按进度百分比搜索的桶半径(±N)", CVAR_FLAG, true, 0.0, true, 100.0);

        // —— 动态分桶 —— //
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
        this.NavBucketMapInvalid   = CreateConVar("inf_NavBucketMapInvalid", "1",
            "Map invalid-flow NavAreas to nearest valid-flow bucket (0=off,1=on)", CVAR_FLAG, true, 0.0, true, 1.0);
        this.NavBucketAssignRadius = CreateConVar("inf_NavBucketAssignRadius", "2000.0",
            "Optional XY max distance when reassigning invalid-flow areas; 0 = unlimited", CVAR_FLAG, true, 0.0);
        this.gCvarNavCacheEnable = CreateConVar(
            "inf_NavCacheEnable", "1",
            "Enable on-disk cache for Nav flow buckets (0=off,1=on)",
            CVAR_FLAG, true, 0.0, true, 1.0);
        // 评分系统权重
        this.Score_w_dist = CreateConVar("inf_score_w_dist", "1.35 1.10 1.20 1.05 1.20 1.25", "距离分权重(S,H,P,B,J,C)", CVAR_FLAG);
        this.Score_w_hght = CreateConVar("inf_score_w_hght", "2.20 1.10 1.60 1.40 0.60 0.60", "高度分权重(S,H,P,B,J,C)", CVAR_FLAG);
        this.Score_w_flow = CreateConVar("inf_score_w_flow", "1.40 1.00 1.20 1.35 1.10 1.20", "流程分权重(S,H,P,B,J,C)", CVAR_FLAG);
        this.Score_w_disp = CreateConVar("inf_score_w_disp", "1.25 1.05 1.15 1.30 0.90 0.80", "分散度分权重(S,H,P,B,J,C)", CVAR_FLAG);
        this.PathCacheEnable   = CreateConVar("inf_PathCacheEnable", "1",
            "Enable PathPenalty_NoBuild cache (0/1)", CVAR_FLAG, true, 0.0, true, 1.0);
        this.PathCacheQuantize = CreateConVar("inf_PathCacheQuantize", "50.0",
            "Quantization step for limitCost when caching (world units)",
            CVAR_FLAG, true, 1.0, true, 500.0);
        this.FrameThinkStep = CreateConVar(
            "inf_FrameThinkStep", "0.05",
            "Idle seconds between spawn queue think slices; active work uses inf_FrameThinkStepActive",
            CVAR_FLAG, true, 0.01, true, 0.25
        );
        this.FrameThinkStepActive = CreateConVar(
            "inf_FrameThinkStepActive", "0.02",
            "Seconds between spawn queue think slices while spawn/teleport work is queued",
            CVAR_FLAG, true, 0.01, true, 0.25
        );
        this.SpawnCandidateBudget = CreateConVar(
            "inf_spawn_candidate_budget", "8",
            "Accepted spawn candidates to score per attempt before choosing best",
            CVAR_FLAG, true, 1.0, true, 24.0
        );
        this.BucketCountCacheTTL = CreateConVar(
            "inf_BucketCountCacheTTL", "0.20",
            "Seconds to cache alive-SI Flow bucket counts during spawn candidate filtering",
            CVAR_FLAG, true, 0.0, true, 2.0
        );
        // badflow 轻度惩罚（仅影响 Flow 分项）
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
            "inf_spawn_bucket_ratio", "0.50",
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

        this.AntiBaitEnable = CreateConVar(
            "inf_antibait_enable", "1",
            "Enable anti-bait pressure controller (0/1)",
            CVAR_FLAG, true, 0.0, true, 1.0
        );
        this.LegacyAntiBaitEnable = CreateConVar(
            "inf_AntiBaitMode", "1",
            "兼容旧配置：Enable anti-bait pressure controller (0/1)",
            CVAR_FLAG, true, 0.0, true, 1.0
        );
        this.AntiBaitGrace = CreateConVar(
            "inf_antibait_grace", "8.0",
            "Seconds after each wave before anti-bait observes survivor progress",
            CVAR_FLAG, true, 0.0, true, 60.0
        );
        this.AntiBaitWindow = CreateConVar(
            "inf_antibait_window", "12.0",
            "Seconds without enough survivor progress before pressure can start",
            CVAR_FLAG, true, 1.0, true, 120.0
        );
        this.AntiBaitProgressPct = CreateConVar(
            "inf_antibait_progress_pct", "2",
            "Average or max survivor flow percent needed to reset anti-bait baseline",
            CVAR_FLAG, true, 1.0, true, 20.0
        );
        this.AntiBaitMinSiRatio = CreateConVar(
            "inf_antibait_min_si_ratio", "0.50",
            "Minimum alive SI ratio before anti-bait can enter pressure",
            CVAR_FLAG, true, 0.0, true, 1.0
        );
        this.AntiBaitForceAfter = CreateConVar(
            "inf_antibait_force_after", "25.0",
            "Seconds in pressure before anti-bait may request action",
            CVAR_FLAG, true, 0.0, true, 180.0
        );
        this.AntiBaitRecover = CreateConVar(
            "inf_antibait_recover", "4.0",
            "Seconds to stay in recover state after survivors make progress",
            CVAR_FLAG, true, 0.0, true, 60.0
        );
        this.AntiBaitAction = CreateConVar(
            "inf_antibait_action", "2",
            "0=debug only, 1=cap latest wave delay, 2=also fast-teleport invisible SI",
            CVAR_FLAG, true, 0.0, true, 2.0
        );
        this.AntiBaitRunnerGapPct = CreateConVar(
            "inf_antibait_runner_gap_pct", "12",
            "Highest survivor flow percent lead over median to mark a runner",
            CVAR_FLAG, true, 0.0, true, 100.0
        );
        this.AntiBaitRunnerNearDist = CreateConVar(
            "inf_antibait_runner_near_dist", "1200.0",
            "Runner is ignored when another survivor is within this world distance",
            CVAR_FLAG, true, 0.0, true, 5000.0
        );
        this.AntiBaitFastTeleport = CreateConVar(
            "inf_antibait_fast_tp", "1.5",
            "Invisible seconds needed for anti-bait fast teleport; still respects spawn grace",
            CVAR_FLAG, true, 0.8, true, 10.0
        );
        this.AntiBaitLatestBaseScale = CreateConVar(
            "inf_antibait_latest_scale", "1.50",
            "Latest wave delay multiplier at AI difficulty 1; base respawn interval remains the lower bound",
            CVAR_FLAG, true, 1.0, true, 3.0
        );
        this.AntiBaitLatestScaleStep = CreateConVar(
            "inf_antibait_latest_scale_step", "0.10",
            "How much higher AI difficulty reduces latest wave delay multiplier per level",
            CVAR_FLAG, true, 0.0, true, 0.5
        );
        this.AntiBaitClusterDist = CreateConVar(
            "inf_antibait_cluster_dist", "650.0",
            "Hard cluster distance: all active survivors within this max spread are considered holding a bait position",
            CVAR_FLAG, true, 0.0, true, 3000.0
        );
        this.AntiBaitTeamDist = CreateConVar(
            "inf_antibait_team_dist", "1300.0",
            "Soft team spread distance: above this, survivors are considered spread enough to attack normally",
            CVAR_FLAG, true, 0.0, true, 5000.0
        );
        this.AntiBaitPairDist = CreateConVar(
            "inf_antibait_pair_dist", "700.0",
            "Average nearest-teammate distance under this means the team still has mutual cover",
            CVAR_FLAG, true, 0.0, true, 3000.0
        );
        this.AntiBaitIsolateDist = CreateConVar(
            "inf_antibait_isolate_dist", "950.0",
            "A survivor whose nearest teammate is farther than this releases anti-bait pressure as pickable",
            CVAR_FLAG, true, 0.0, true, 3000.0
        );
        this.AntiBaitDebug = CreateConVar(
            "inf_antibait_debug", "0",
            "Log anti-bait state transitions even when inf_DebugMode is off",
            CVAR_FLAG, true, 0.0, true, 1.0
        );

        // 变更回调
        this.AiDifficultyLink.AddChangeHook(OnCfgChanged);
        this.AiDifficultyFallbackLevel.AddChangeHook(OnCfgChanged);
        this.AiWaveCheckRatio.AddChangeHook(OnCfgChanged);
        this.AiWaveFloorRatio.AddChangeHook(OnCfgChanged);
        this.AiWaveLowSiRatio.AddChangeHook(OnCfgChanged);
        this.AiDistSweetOffset.AddChangeHook(OnCfgChanged);
        this.AiDistWidthScale.AddChangeHook(OnCfgChanged);
        this.AiSpawnBudgetBonus.AddChangeHook(OnCfgChanged);
        this.VisEyeRayMode.AddChangeHook(OnCfgChanged);
        this.SurFlowFallbackEnable.AddChangeHook(OnCfgChanged);
        this.SurFlowFallbackTTL.AddChangeHook(OnCfgChanged);
        this.FlowBadPenaltyPoints.AddChangeHook(OnCfgChanged);
        this.SpawnScoreFloor.AddChangeHook(OnCfgChanged);
        this.FlowBucketShare.AddChangeHook(OnCfgChanged);
        this.AntiBaitEnable.AddChangeHook(OnCfgChanged);
        this.LegacyAntiBaitEnable.AddChangeHook(OnCfgChanged);
        this.AntiBaitGrace.AddChangeHook(OnCfgChanged);
        this.AntiBaitWindow.AddChangeHook(OnCfgChanged);
        this.AntiBaitProgressPct.AddChangeHook(OnCfgChanged);
        this.AntiBaitMinSiRatio.AddChangeHook(OnCfgChanged);
        this.AntiBaitForceAfter.AddChangeHook(OnCfgChanged);
        this.AntiBaitRecover.AddChangeHook(OnCfgChanged);
        this.AntiBaitAction.AddChangeHook(OnCfgChanged);
        this.AntiBaitRunnerGapPct.AddChangeHook(OnCfgChanged);
        this.AntiBaitRunnerNearDist.AddChangeHook(OnCfgChanged);
        this.AntiBaitFastTeleport.AddChangeHook(OnCfgChanged);
        this.AntiBaitLatestBaseScale.AddChangeHook(OnCfgChanged);
        this.AntiBaitLatestScaleStep.AddChangeHook(OnCfgChanged);
        this.AntiBaitClusterDist.AddChangeHook(OnCfgChanged);
        this.AntiBaitTeamDist.AddChangeHook(OnCfgChanged);
        this.AntiBaitPairDist.AddChangeHook(OnCfgChanged);
        this.AntiBaitIsolateDist.AddChangeHook(OnCfgChanged);
        this.AntiBaitDebug.AddChangeHook(OnCfgChanged);

        this.PathCacheEnable.AddChangeHook(OnCfgChanged);
        this.PathCacheQuantize.AddChangeHook(OnCfgChanged);
        this.FrameThinkStep.AddChangeHook(OnCfgChanged);
        this.FrameThinkStepActive.AddChangeHook(OnCfgChanged);
        this.SpawnCandidateBudget.AddChangeHook(OnCfgChanged);
        this.BucketCountCacheTTL.AddChangeHook(OnCfgChanged);
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
        this.SurvivorLimit     = FindConVar("survivor_limit");
        this.DirectorNoSpecials = FindConVar("director_no_specials");
        this.AiDifficultyLevel = FindConVar("ah_ai_dynamic_current_level");
        if (this.AiDifficultyLevel != null)
            this.AiDifficultyLevel.AddChangeHook(OnCfgChanged);
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

        if (this.DirectorNoSpecials != null)
            SetConVarInt(this.DirectorNoSpecials, 1);

        this.SpawnMax.AddChangeHook(OnCfgChanged);
        this.SpawnMin.AddChangeHook(OnCfgChanged);
        this.TeleportSpawnMin.AddChangeHook(OnCfgChanged);
        this.LegacyTeleportSpawnMin.AddChangeHook(OnCfgChanged);
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
        this.RefreshRuntimeConVars();
        float teleportSpawnMinModern = this.TeleportSpawnMin.FloatValue;
        float teleportSpawnMinLegacy = this.LegacyTeleportSpawnMin.FloatValue;
        this.fSpawnMax          = this.SpawnMax.FloatValue;
        this.fSpawnMin          = this.SpawnMin.FloatValue;
        this.fTeleportSpawnMin  = (FloatAbs(teleportSpawnMinLegacy - 400.0) > 0.01) ? teleportSpawnMinLegacy : teleportSpawnMinModern;
        this.bTeleport          = this.TeleportEnable.BoolValue;
        this.fSiInterval        = this.SiInterval.FloatValue;
        this.iSiLimit           = this.SiLimit.IntValue;
        this.iTeleportCheckTime = this.TeleportCheckTime.IntValue;
        this.iEnableMask        = this.EnableMask.IntValue;
        this.bAddDmgSmoker      = this.AddDmgSmoker.BoolValue;
        this.bAutoSpawn         = this.AutoSpawnTime.BoolValue;
        this.bIgnoreIncapSight  = this.IgnoreIncapSight.BoolValue;
        this.iDebugMode         = this.DebugMode.IntValue;

        this.bAiDifficultyLink = this.AiDifficultyLink.BoolValue;
        this.iAiDifficultyFallbackLevel = ClampInt(this.AiDifficultyFallbackLevel.IntValue, 1, AI_DIFFICULTY_LEVELS);
        Config_ParseDifficultyFloatList(this.AiWaveCheckRatio, DEFAULT_AI_WAVE_CHECK_RATIO, this.fAiWaveCheckRatio, 0.05, 2.50);
        Config_ParseDifficultyFloatList(this.AiWaveFloorRatio, DEFAULT_AI_WAVE_FLOOR_RATIO, this.fAiWaveFloorRatio, 1.00, 3.00);
        Config_ParseDifficultyFloatList(this.AiWaveLowSiRatio, DEFAULT_AI_WAVE_LOW_SI_RATIO, this.fAiWaveLowSiRatio, 0.0, 1.0);
        Config_ParseDifficultyFloatList(this.AiDistSweetOffset, DEFAULT_AI_DIST_SWEET_OFFSET, this.fAiDistSweetOffset, -0.40, 0.40);
        Config_ParseDifficultyFloatList(this.AiDistWidthScale, DEFAULT_AI_DIST_WIDTH_SCALE, this.fAiDistWidthScale, 0.40, 2.50);
        Config_ParseDifficultyFloatList(this.AiSpawnBudgetBonus, DEFAULT_AI_SPAWN_BUDGET_BONUS, this.fAiSpawnBudgetBonus, -12.0, 12.0);

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
        // 刷新评分系统权重。
        char buffer[256];
        char parts[SI_COUNT][16];
        int numParts;

        // 权重兜底：CVar 值不足或为 0 时回退到 1.0，避免意外禁用某因子。
        for (int i = 1; i <= SI_COUNT; i++) {
            if (this.w_dist[i] <= 0.0) this.w_dist[i] = 1.0;
            if (this.w_hght[i] <= 0.0) this.w_hght[i] = 1.0;
            if (this.w_flow[i] <= 0.0) this.w_flow[i] = 1.0;
            if (this.w_disp[i] <= 0.0) this.w_disp[i] = 1.0;
        }

        this.Score_w_dist.GetString(buffer, sizeof(buffer));
        numParts = ExplodeString(buffer, " ", parts, SI_COUNT, 16);
        for (int i = 0; i < numParts && i < SI_COUNT; i++) {
            this.w_dist[i+1] = StringToFloat(parts[i]);
        }

        this.Score_w_hght.GetString(buffer, sizeof(buffer));
        numParts = ExplodeString(buffer, " ", parts, SI_COUNT, 16);
        for (int i = 0; i < numParts && i < SI_COUNT; i++) {
            this.w_hght[i+1] = StringToFloat(parts[i]);
        }

        this.Score_w_flow.GetString(buffer, sizeof(buffer));
        numParts = ExplodeString(buffer, " ", parts, SI_COUNT, 16);
        for (int i = 0; i < numParts && i < SI_COUNT; i++) {
            this.w_flow[i+1] = StringToFloat(parts[i]);
        }

        this.Score_w_disp.GetString(buffer, sizeof(buffer));
        numParts = ExplodeString(buffer, " ", parts, SI_COUNT, 16);
        for (int i = 0; i < numParts && i < SI_COUNT; i++) {
            this.w_disp[i+1] = StringToFloat(parts[i]);
        }

        this.bPathCacheEnable   = this.PathCacheEnable.BoolValue;
        this.fPathCacheQuantize = this.PathCacheQuantize.FloatValue;
        if (this.fPathCacheQuantize < 1.0) this.fPathCacheQuantize = 1.0;
        this.fFrameThinkStep    = this.FrameThinkStep.FloatValue;
        if (this.fFrameThinkStep < 0.01) this.fFrameThinkStep = 0.01;
        if (this.fFrameThinkStep > 0.25) this.fFrameThinkStep = 0.25;
        this.fFrameThinkStepActive = this.FrameThinkStepActive.FloatValue;
        if (this.fFrameThinkStepActive < 0.01) this.fFrameThinkStepActive = 0.01;
        if (this.fFrameThinkStepActive > 0.25) this.fFrameThinkStepActive = 0.25;
        this.iSpawnCandidateBudget = this.SpawnCandidateBudget.IntValue;
        if (this.iSpawnCandidateBudget < 1) this.iSpawnCandidateBudget = 1;
        if (this.iSpawnCandidateBudget > 24) this.iSpawnCandidateBudget = 24;
        this.fBucketCountCacheTTL = this.BucketCountCacheTTL.FloatValue;
        if (this.fBucketCountCacheTTL < 0.0) this.fBucketCountCacheTTL = 0.0;
        if (this.fBucketCountCacheTTL > 2.0) this.fBucketCountCacheTTL = 2.0;
        // 读取 badflow 轻度惩罚。
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

        this.bAntiBaitEnable = this.AntiBaitEnable.BoolValue && this.LegacyAntiBaitEnable.BoolValue;
        this.fAntiBaitGrace = this.AntiBaitGrace.FloatValue;
        this.fAntiBaitWindow = this.AntiBaitWindow.FloatValue;
        this.iAntiBaitProgressPct = this.AntiBaitProgressPct.IntValue;
        this.fAntiBaitMinSiRatio = this.AntiBaitMinSiRatio.FloatValue;
        this.fAntiBaitForceAfter = this.AntiBaitForceAfter.FloatValue;
        this.fAntiBaitRecover = this.AntiBaitRecover.FloatValue;
        this.iAntiBaitAction = this.AntiBaitAction.IntValue;
        this.iAntiBaitRunnerGapPct = this.AntiBaitRunnerGapPct.IntValue;
        this.fAntiBaitRunnerNearDist = this.AntiBaitRunnerNearDist.FloatValue;
        this.fAntiBaitFastTeleport = this.AntiBaitFastTeleport.FloatValue;
        this.fAntiBaitLatestBaseScale = this.AntiBaitLatestBaseScale.FloatValue;
        this.fAntiBaitLatestScaleStep = this.AntiBaitLatestScaleStep.FloatValue;
        this.fAntiBaitClusterDist = this.AntiBaitClusterDist.FloatValue;
        this.fAntiBaitTeamDist = this.AntiBaitTeamDist.FloatValue;
        this.fAntiBaitPairDist = this.AntiBaitPairDist.FloatValue;
        this.fAntiBaitIsolateDist = this.AntiBaitIsolateDist.FloatValue;
        this.bAntiBaitDebug = this.AntiBaitDebug.BoolValue;
        if (this.fAntiBaitMinSiRatio < 0.0) this.fAntiBaitMinSiRatio = 0.0;
        if (this.fAntiBaitMinSiRatio > 1.0) this.fAntiBaitMinSiRatio = 1.0;
        if (this.fAntiBaitLatestBaseScale < 1.0) this.fAntiBaitLatestBaseScale = 1.0;
        if (this.fAntiBaitFastTeleport < 0.8) this.fAntiBaitFastTeleport = 0.8;
        if (this.fAntiBaitClusterDist < 0.0) this.fAntiBaitClusterDist = 0.0;
        if (this.fAntiBaitTeamDist < 0.0) this.fAntiBaitTeamDist = 0.0;
        if (this.fAntiBaitPairDist < 0.0) this.fAntiBaitPairDist = 0.0;
        if (this.fAntiBaitIsolateDist < 0.0) this.fAntiBaitIsolateDist = 0.0;
    }

    void ApplyMaxZombieBound()
    {
        SetConVarBounds(this.MaxPlayerZombies, ConVarBound_Upper, true, float(this.iSiLimit));
        this.MaxPlayerZombies.IntValue = this.iSiLimit;
    }
}
