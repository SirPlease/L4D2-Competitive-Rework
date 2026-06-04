#if defined _infected_control_spawn_memory_included
    #endinput
#endif
#define _infected_control_spawn_memory_included

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

    for (int i = lastSpawns.Length - 1; i >= 0; i--)
    {
        float rec[4];
        lastSpawns.GetArray(i, rec);
        if (now - rec[3] > SEP_TTL)
            lastSpawns.Erase(i);
    }

    int cap = GetSepMax();
    while (lastSpawns.Length > cap)
        lastSpawns.Erase(0);
}

stock bool PassMinSeparation(const float pos[3])
{
    if (lastSpawns == null || lastSpawns.Length == 0) return true;

    float now = GetGameTime();
    float k = PenLimitScale();
    float sepRadiusEff = SEP_RADIUS * k;
    float sep2 = sepRadiusEff * sepRadiusEff;

    for (int i = lastSpawns.Length - 1; i >= 0; i--)
    {
        float rec[4];
        lastSpawns.GetArray(i, rec);

        if (now - rec[3] > SEP_TTL)
        {
            lastSpawns.Erase(i);
            continue;
        }

        float rec3[3];
        rec3[0] = rec[0];
        rec3[1] = rec[1];
        rec3[2] = rec[2];

        if (GetVectorDistance(pos, rec3, true) < sep2)
            return false;
    }
    return true;
}

stock bool PassRealPositionCheck(float candPos[3], int targetSur, int si = 0)
{
    int candPercent = GetPositionBucketPercent(candPos);
    if (candPercent < 0)
        return true;

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

    if (surPercent < 0)
    {
        int fpct;
        if (GetFallbackSurPct(fpct))
            surPercent = fpct;
    }

    // 所有进度获取方式均失败：无法判断身前/身后，放行以避免卡住刷特
    if (surPercent < 0)
        return true;

    if (candPercent < surPercent - 6)
        return false;

    float minFootZ;
    if (TryGetLowestSurvivorFootZ(minFootZ))
    {
        if (candPercent < surPercent
            && (candPos[2] <= (minFootZ - 180.0)
                || (si != view_as<int>(SI_Smoker) && candPos[2] >= (minFootZ + 200.0))))
            return false;
    }

    return true;
}

stock bool TryGetLowestSurvivorFootZ(float &outMinZ)
{
    bool found = false;
    float bestZ = 0.0;
    float s[3];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidSurvivor(i) || !IsPlayerAlive(i))
            continue;

        GetClientAbsOrigin(i, s);
        if (!found || s[2] < bestZ)
        {
            bestZ = s[2];
            found = true;
        }
    }

    if (found) outMinZ = bestZ;
    return found;
}

stock int GetNavIDByIndex(int idx)
{
    EnsureNavAreasCache();

    if (idx < 0 || idx >= g_NavAreasCacheCount)
        return -1;

    Address area = g_AllNavAreasCache.Get(idx);
    return L4D_GetNavAreaID(area);
}

stock int ComputeSectorIndex(const float center[3], const float pt[3], int sectors)
{
    float dx = pt[0] - center[0];
    float dy = pt[1] - center[1];
    float ang = ArcTangent2(dy, dx);
    if (ang < 0.0) ang += 2.0 * FLOAT_PI;

    float w = (2.0 * FLOAT_PI) / float(sectors);
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
        if (IsValidSurvivor(i) && IsPlayerAlive(i))
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
    rec[0] = pos[0];
    rec[1] = pos[1];
    rec[2] = pos[2];
    rec[3] = now;
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

int GetCurrentSectors()
{
    int T = gCV.iSiLimit;
    int n = (T <= 2) ? 2 : (RoundToCeil(float(T) / 2.0) + 1);
    if (n < DYN_SECTORS_MIN) n = DYN_SECTORS_MIN;
    if (n > SECTORS_MAX)     n = SECTORS_MAX;
    return n;
}

bool IsValidFlags(int iFlags, bool bFinaleArea)
{
    if (!iFlags)
        return true;

    if (bFinaleArea && (iFlags & TERROR_NAV_FINALE) == 0)
        return false;

    return (iFlags & (TERROR_NAV_RESCUE_CLOSET | TERROR_NAV_RESCUE_VEHICLE | TERROR_NAV_CHECKPOINT)) == 0;
}

stock void ShuffleArrayList(ArrayList L)
{
    int n = L.Length;
    for (int i = n - 1; i > 0; i--)
    {
        int j = GetRandomInt(0, i);
        if (j == i) continue;
        int ai = L.Get(i), aj = L.Get(j);
        L.Set(i, aj);
        L.Set(j, ai);
    }
}
