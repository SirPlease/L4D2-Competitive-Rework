#if defined _infected_control_path_cache_included
    #endinput
#endif
#define _infected_control_path_cache_included

#define PATH_NO_BUILD_PENALTY     1999.0

static StringMap g_PathCacheRes = null;  // key -> int(0/1)

void PathCache_Init()
{
    if (g_PathCacheRes == null)
        g_PathCacheRes = new StringMap();
}

// 生成缓存 Key（NavAreaID + 量化后的 limitCost）
static void PathCache_BuildKey(Address navGoal, Address navStart, float limitCost, char[] outKey, int maxlen)
{
    int idG = (navGoal  != Address_Null) ? L4D_GetNavAreaID(navGoal)  : -1;
    int idS = (navStart != Address_Null) ? L4D_GetNavAreaID(navStart) : -1;
    int q   = RoundToNearest(limitCost / gCV.fPathCacheQuantize); // 量化，避免 key 激增
    Format(outKey, maxlen, "%d|%d|%d", idG, idS, q);
}

// 简单读写（无 TTL）
static bool PathCache_TryGetSimple(const char[] key, bool &okOut)
{
    if (g_PathCacheRes == null) return false;
    any resAny;
    if (!g_PathCacheRes.GetValue(key, resAny)) return false;
    okOut = (view_as<int>(resAny) != 0);
    return true;
}

static void PathCache_PutSimple(const char[] key, bool ok)
{
    if (g_PathCacheRes == null) return;
    g_PathCacheRes.SetValue(key, view_as<any>(ok ? 1 : 0));
}

// 仅清结果表。
void ClearPathCache()
{
    if (g_PathCacheRes != null) g_PathCacheRes.Clear();
}

// 使用波级缓存（无 TTL）。
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
