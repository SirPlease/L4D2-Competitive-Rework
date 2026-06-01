#if defined _infected_control_class_queue_included
    #endinput
#endif
#define _infected_control_class_queue_included

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

bool IsSupportGateClassInt(int zc)
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

bool SupportRestrictionActive()
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

// —— 死亡CD判断 —— //
bool PassDeathCooldown(int zc)
{
    if (zc < 1 || zc > 6) return true;
    float now = GetGameTime();
    float last = g_LastDeathTime[zc - 1];
    if (last <= 0.01) return true;

    float need = IsSupportClassInt(zc) ? gCV.fDeathCDSupport : gCV.fDeathCDKiller;
    return (now - last) >= need;
}

// 仅在“无活动冷却”时开启一次死亡CD；若已在CD中则忽略本次死亡
void TouchDeathCooldownOnce(int zc)
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
        Debug_Print("[DEATHCD] start %s at %.2f (CD=%.2f)", g_sInfectedClassNames[zc], now, need);
    }
    else
    {
        // 仍在冷却期：忽略，不刷新时间戳（不把CD往后推）
        Debug_Print("[DEATHCD] ignore %s death at %.2f (remain=%.2f)",
            g_sInfectedClassNames[zc], now, need - (now - last));
    }
}

// —— 是否放宽 CD（永不饿死双保险） —— //
bool ShouldRelaxDeathCD()
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

// —— 稀缺度优先选类（两遍：严格 CD → 放宽 CD） —— //
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
void MaintainSpawnQueueOnce()
{
    RecalcSiCapFromAlive(false);  // 入队前刷新“剩余额度”
    if (SpawnQueue_Length() >= gCV.iSiLimit) return;

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
                if (!relax && !PassDeathCooldown(pick)) // 不放宽时跳过处于 CD 的类
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
                Debug_Print("<SpawnQ> no eligible class (CD on %s) -> wait", g_sInfectedClassNames[zc]);
                return; // 本帧确实无可用类，等待下一帧
            }

            Debug_Print("<SpawnQ> substitute %s -> %s (CD active on original)", g_sInfectedClassNames[zc], g_sInfectedClassNames[alt]);
            zc = alt; // 用替补继续入队
        }

        if (supportLocked && IsSupportGateClassInt(zc))
        {
            int alt2 = PickEligibleKillerClass();
            if (alt2 == 0)
            {
                Debug_Print("<SpawnQ> support %s locked (need killers) -> wait", g_sInfectedClassNames[zc]);
                return;
            }

            Debug_Print("<SpawnQ> substitute %s -> %s (support locked)", g_sInfectedClassNames[zc], g_sInfectedClassNames[alt2]);
            zc = alt2;
        }

        // 入队
        SpawnQueue_Push(zc);
        Debug_Print("<SpawnQ> +%s size=%d", g_sInfectedClassNames[zc], SpawnQueue_Length());
    }
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
bool HasReachedLimit(int zc)
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
