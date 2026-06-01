#if defined _infected_control_spawn_attempts_included
    #endinput
#endif
#define _infected_control_spawn_attempts_included

static bool FallbackDirectorPosAtMax(int zc, int target, bool teleportMode, float outPos[3])
{
    float bestPt[3];
    bool have = false;
    float bestDelta = 999999.0;

    float spawnMax = gCV.fSpawnMax;
    float spawnMin = gCV.fSpawnMin;

    int tgt = target;
    if (!IsValidSurvivor(tgt) || !IsPlayerAlive(tgt))
        tgt = GetHighestFlowSurvivorSafe();

    if (!IsValidSurvivor(tgt) || !IsPlayerAlive(tgt))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidSurvivor(i) && IsPlayerAlive(i))
            {
                tgt = i;
                break;
            }
        }
    }

    if (!IsValidSurvivor(tgt) || !IsPlayerAlive(tgt))
    {
        Debug_Print("[FALLBACK] no valid survivor to reference, abort");
        return false;
    }

    float tFeet[3];
    GetClientAbsOrigin(tgt, tFeet);
    Address navTarget = L4D2Direct_GetTerrorNavArea(tFeet);
    if (navTarget == Address_Null)
        navTarget = view_as<Address>(L4D_GetNearestNavArea(tFeet, 300.0, false, false, false, TEAM_INFECTED));
    if (navTarget == Address_Null)
        return false;

    for (int i = 0; i < DIRECTOR_FALLBACK_TRIES; i++)
    {
        float pt[3];
        if (!L4D_GetRandomPZSpawnPosition(tgt, zc, 7, pt)) continue;

        float minD = GetMinDistToAnySurvivor(pt);
        if (minD < spawnMin || minD > spawnMax + 200.0) continue;
        if (IsPosVisibleSDK(pt, teleportMode)) continue;
        if (WillStuck(pt)) continue;

        float delta = FloatAbs(spawnMax - minD);
        bool prefer = (minD <= spawnMax);

        if (!have)
        {
            bestPt = pt;
            have = true;
            bestDelta = delta;
        }
        else
        {
            float bestMinD = GetMinDistToAnySurvivor(bestPt);
            bool bestPrefer = (bestMinD <= spawnMax);
            if ((prefer && !bestPrefer) || (prefer == bestPrefer && delta < bestDelta))
            {
                bestPt = pt;
                bestDelta = delta;
            }
        }
    }

    if (!have) return false;
    outPos = bestPt;
    return true;
}

static bool DoSpawnAt(const float pos[3], int zc)
{
    if (GetMinEyeDistToAnySurvivor(pos) < gCV.fSpawnMin)
    {
        Debug_Print("[SPAWN BLOCK] too close (< SpawnMin=%.1f) at (%.1f %.1f %.1f)",
                    gCV.fSpawnMin, pos[0], pos[1], pos[2]);
        return false;
    }

    int idx = L4D2_SpawnSpecial(zc, pos, NULL_VECTOR);
    if (idx > 0)
    {
        g_LastSpawnOkTime = GetGameTime();
        InvalidateBucketShareCache();
        Debug_Print("[SPAWN OK] %s idx=%d at (%.1f %.1f %.1f)", g_sInfectedClassNames[zc], idx, pos[0], pos[1], pos[2]);
        RecalcSiCapFromAlive(false);
        return true;
    }

    Debug_Print("[SPAWN FAIL] %s at (%.1f %.1f %.1f) -> idx=%d", g_sInfectedClassNames[zc], pos[0], pos[1], pos[2], idx);
    return false;
}

static void BypassAndExecuteCommand(const char[] cmd)
{
    if (!CheatsOn()) return;
    ServerCommand("%s", cmd);
}

static bool CheatsOn()
{
    ConVar sv = FindConVar("sv_cheats");
    return (sv != null && sv.BoolValue);
}

void TryNormalSpawnOnce()
{
    static const float EPS_RADIUS = 1.0;
    if (SpawnQueue_Length() <= 0)
        return;

    int want = 0;
    while (SpawnQueue_Length() > 0)
    {
        SpawnQueue_Peek(want);
        if (!IsSupportGateClassInt(want) || !SupportRestrictionActive())
            break;

        Debug_Print("[QUEUE DROP] support %s blocked (need killers)", g_sInfectedClassNames[want]);
        SpawnQueue_DropHead(want);
    }

    if (SpawnQueue_Length() <= 0)
        return;

    if (HasReachedLimit(want))
    {
        Debug_Print("[SPAWN DROP] class=%s reached alive-cap, drop head", g_sInfectedClassNames[want]);
        SpawnQueue_DropHead(want);
        return;
    }

    if (!PassDeathCooldown(want) && !ShouldRelaxDeathCD())
    {
        SpawnQueue_RotateHead(want);
        Debug_Print("[QUEUE ROTATE] %s under death-cooldown, rotate to tail", g_sInfectedClassNames[want]);
        return;
    }

    bool isSupport = (want == view_as<int>(SI_Boomer) || want == view_as<int>(SI_Spitter));

    float pos[3];
    int areaIdx = -1;
    float ring = gST.spawnDistCur;

    float maxR = gCV.fSpawnMax;
    if (isSupport && SUPPORT_EXPAND_MAX < maxR)
        maxR = SUPPORT_EXPAND_MAX;

    SpawnScoreDbg bestDbg;
    bool ok = FindSpawnPosViaNavArea(want, gST.targetSurvivor, ring, false, pos, areaIdx, bestDbg);

    if (ok && IsPosVisibleSDK(pos, false)) ok = false;

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

        float center[3];
        GetSectorCenter(center, gST.targetSurvivor);
        RememberSpawn(pos, center);

        gST.siQueueCount--;
        gST.siAlive[want - 1]++;
        gST.totalSI++;
        SpawnQueue_DropHead(want);

        BypassAndExecuteCommand("nb_assault");

        float nextStart = ring * 0.7;
        if (nextStart < gCV.fSpawnMin) nextStart = gCV.fSpawnMin;
        if (nextStart > gCV.fSpawnMax) nextStart = gCV.fSpawnMax;
        gST.spawnDistCur = nextStart;

        Debug_Print("[SPAWN] success ring=%.1f -> nextStart=%.1f", ring, gST.spawnDistCur);
        return;
    }

    if (triedSpawn && !spawnOk && areaIdx >= 0)
        TouchNavCooldown(areaIdx, GetGameTime(), 0.8);

    float nextR = gST.spawnDistCur + LOW_SCORE_EXPAND;
    if (nextR > maxR) nextR = maxR;
    gST.spawnDistCur = nextR;

    Debug_Print("[SPAWN] expand -> %.1f (max=%.1f) class=%s", gST.spawnDistCur, maxR, g_sInfectedClassNames[want]);

    if (gST.spawnDistCur + EPS_RADIUS >= maxR)
    {
        float pt[3];
        if (FallbackDirectorPosAtMax(want, gST.targetSurvivor, false, pt) && DoSpawnAt(pt, want))
        {
            float center[3];
            GetSectorCenter(center, gST.targetSurvivor);
            RememberSpawn(pt, center);

            gST.siQueueCount--;
            gST.siAlive[want - 1]++;
            gST.totalSI++;
            SpawnQueue_DropHead(want);

            BypassAndExecuteCommand("nb_assault");

            gST.spawnDistCur *= 0.8;
            Debug_Print("[SPAWN] fallback@max success");
        }
        else
        {
            Debug_Print("[SPAWN FAIL] fallback@max failed class=%s", g_sInfectedClassNames[want]);
        }
    }
}

void TryTeleportSpawnOnce()
{
    static const float EPS_RADIUS = 1.0;

    int want = 0;
    if (!TeleportQueue_Peek(want))
        return;
    if (gST.totalSI >= gCV.iSiLimit || HasReachedLimit(want))
        return;

    float pos[3];
    int areaIdx = -1;
    float ring = gST.teleportDistCur;
    float maxR = gCV.fSpawnMax;

    SpawnScoreDbg bestDbg;
    bool ok = FindSpawnPosViaNavArea(want, gST.targetSurvivor, ring, true, pos, areaIdx, bestDbg);

    if (ok && IsPosVisibleSDK(pos, true)) ok = false;

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

        float center[3];
        GetSectorCenter(center, gST.targetSurvivor);
        RememberSpawn(pos, center);

        gST.siAlive[want - 1]++;
        gST.totalSI++;
        TeleportQueue_DropHead(want);

        float nextTP = ring * 0.8;
        if (nextTP < gCV.fSpawnMin) nextTP = gCV.fSpawnMin;
        if (nextTP > gCV.fSpawnMax) nextTP = gCV.fSpawnMax;
        gST.teleportDistCur = nextTP;

        if (TeleportQueue_Length() == 0)
            gST.teleportDistCur = gCV.fSpawnMin;

        Debug_Print("[TP] success ring=%.1f -> nextStart=%.1f", ring, gST.teleportDistCur);
        return;
    }

    if (triedSpawn && !spawnOk && areaIdx >= 0)
        TouchNavCooldown(areaIdx, GetGameTime(), 0.8);

    float nextR = gST.teleportDistCur + LOW_SCORE_EXPAND;
    if (nextR > maxR) nextR = maxR;
    gST.teleportDistCur = nextR;

    Debug_Print("[TP] expand -> %.1f (max=%.1f) class=%s", gST.teleportDistCur, maxR, g_sInfectedClassNames[want]);

    if (gST.teleportDistCur + EPS_RADIUS >= maxR)
    {
        float pt[3];
        if (FallbackDirectorPosAtMax(want, gST.targetSurvivor, true, pt) && DoSpawnAt(pt, want))
        {
            float center[3];
            GetSectorCenter(center, gST.targetSurvivor);
            RememberSpawn(pt, center);

            gST.siAlive[want - 1]++;
            gST.totalSI++;
            TeleportQueue_DropHead(want);

            gST.teleportDistCur = FloatMax(gCV.fSpawnMin, gST.teleportDistCur * 0.7);
            Debug_Print("[TP] fallback@max success, ring now %.1f", gST.teleportDistCur);
        }
        else
        {
            Debug_Print("[TP FAIL] fallback@max failed class=%s", g_sInfectedClassNames[want]);
        }
    }
}
