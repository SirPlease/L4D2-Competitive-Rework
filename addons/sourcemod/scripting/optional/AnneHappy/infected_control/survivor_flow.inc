#if defined _infected_control_survivor_flow_included
    #endinput
#endif
#define _infected_control_survivor_flow_included

// Survivor 数据缓存（fdxx风格）
enum struct SurPosData
{
    float fFlow;
    float fPos[3];
}

ArrayList g_aSurPosData = null;
int g_iSurPosDataLen = 0;
int g_iSurvivors[MAXPLAYERS+1];
int g_iSurCount = 0;

// 生还者进度回退（最后一次成功统计）
static int   g_LastGoodSurPct     = -1;   // 0..100
static float g_LastGoodSurPctTime = 0.0;  // game time
static int   g_BucketAliveCount[FLOW_BUCKETS];
static float g_BucketAliveCountTime = -9999.0;

void InvalidateBucketShareCache()
{
    g_BucketAliveCountTime = -9999.0;
}

// 每秒轻量刷新一次“最后一次有效团队进度”(0..100)
// 设计：至少有1名生还者拿到有效进度才更新；无效则保持旧值不变。
void RefreshLastGoodSurPctTick()
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

bool IsPosAheadOfHighest(float ref[3], int target = -1)
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

// 根据坐标查询其在分桶系统中的百分比。
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

static void RefreshAliveSpecialBucketCounts()
{
    float now = GetGameTime();
    if (gCV.fBucketCountCacheTTL > 0.0 && (now - g_BucketAliveCountTime) <= gCV.fBucketCountCacheTTL)
        return;

    for (int b = 0; b < FLOW_BUCKETS; b++)
        g_BucketAliveCount[b] = 0;

    float pos[3];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsInfectedBot(i) || !IsPlayerAlive(i) || IsGhost(i))
            continue;

        GetClientAbsOrigin(i, pos);
        int b = GetPositionBucketPercent(pos);
        if (b >= 0 && b < FLOW_BUCKETS)
            g_BucketAliveCount[b]++;
    }
    g_BucketAliveCountTime = now;
}

static int CountAliveSpecialsInBucket(int bucket)
{
    if (bucket < 0 || bucket > 100) return 0;

    RefreshAliveSpecialBucketCounts();
    return g_BucketAliveCount[bucket];
}

bool PassBucketShareLimit(int bucket)
{
    int cap = gCV.iBucketMaxPerFlow;
    if (cap <= 0) return true;
    if (bucket < 0 || bucket > 100) return true;

    return CountAliveSpecialsInBucket(bucket) < cap;
}

stock int Calculate_Flow(Address area)
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

int FlowDistanceToPercent(float flowDist)
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

int ChooseTargetSurvivor()
{
    int antiBaitTarget = AntiBait_GetPreferredTarget();
    if (antiBaitTarget > 0)
        return antiBaitTarget;

    if (gST.bPickRushMan && IsValidSurvivor(gST.rushManIndex) && IsPlayerAlive(gST.rushManIndex) && !IsPinned(gST.rushManIndex))
        return gST.rushManIndex;

    int cand[MAX_SURVIVOR_SLOTS];
    int n = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidSurvivor(i) && IsPlayerAlive(i) && !L4D_IsPlayerIncapacitated(i))
        {
            if (g_bTargetLimitLib && IsClientReachLimit(i))
            {
                LogMsg("[TARGET] skip %N: reach limit", i);
                continue;
            }
            cand[n++] = i;
            if (n >= sizeof(cand)) break;
        }
    }
    if (n > 0) return cand[GetRandomInt(0, n-1)];
    int fb = GetHighestFlowSurvivorSafe();
    LogMsg("[TARGET] fallback to highest-flow %N", fb);
    return fb;
}

stock bool IsAllKillersDown()
{
    int sum = gST.siAlive[view_as<int>(SI_Charger) - 1] + gST.siAlive[view_as<int>(SI_Hunter) - 1] + gST.siAlive[view_as<int>(SI_Jockey) - 1] + gST.siAlive[view_as<int>(SI_Smoker) - 1];
    return sum == 0;
}

float GetSurAvrFlow()
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
        TouchLastGoodSurPctFromAverage(avgPct);   // 记录最后一次有效进度。
        return sumPct / float(n);
    }

    // 没有任何有效进度 → 尝试回退
    int fpct;
    if (GetFallbackSurPct(fpct))
        return float(fpct);

    return 0.0;
}

// 判异常：flow < 0 或 > 地图最大 flow
bool IsFlowAbnormal(float flowDist, float maxFlow)
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

// 为 client 获取安全 flow 距离。
// 1) 直接读玩家 flow；异常 → 2) 用 L4D_GetLastKnownArea(client) 取 Nav flow；仍异常 → 3) 最近 NavArea。
static bool TryGetClientFlowDistanceSafe(int client, float &outFlow)
{
    float maxFlow = L4D2Direct_GetMapMaxFlowDistance();

    float d = L4D2Direct_GetFlowDistance(client);
    if (!IsFlowAbnormal(d, maxFlow)) { outFlow = d; return true; }

    // 显式兜底：使用 L4D_GetLastKnownArea。
    Address last = view_as<Address>(L4D_GetLastKnownArea(client));
    if (TryGetFlowDistanceFromArea(last, outFlow)) return true;

    float pos[3];
    GetClientAbsOrigin(client, pos);
    Address near = L4D_GetNearestNavArea(pos, 300.0, false, false, false, TEAM_SURVIVOR);
    if (TryGetFlowDistanceFromArea(near, outFlow)) return true;

    return false;
}

// 百分比封装
bool TryGetClientFlowPercentSafe(int client, int &outPct)
{
    float d;
    if (!TryGetClientFlowDistanceSafe(client, d)) return false;
    outPct = FlowDistanceToPercent(d);
    if (outPct < 0) outPct = 0;
    if (outPct > 100) outPct = 100;
    return true;
}

// 最高进度幸存者（安全版）
int GetHighestFlowSurvivorSafe()
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
int CountAliveSurvivors()
{
    int n = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsValidSurvivor(i) && IsPlayerAlive(i))
            n++;
    return n;
}

// 取得“当前有效的回退进度”（满足开启且未过期）
bool GetFallbackSurPct(int &outPct)
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
bool GetSurPosData()
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
