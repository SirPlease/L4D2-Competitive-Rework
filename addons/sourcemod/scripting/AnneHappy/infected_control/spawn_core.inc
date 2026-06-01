#if defined _infected_control_spawn_core_included
    #endinput
#endif
#define _infected_control_spawn_core_included

enum struct SpawnFilterStats
{
    int cooldown;
    int flags;
    int flow;
    int distance;
    int separation;
    int stuck;
    int visibility;
    int path;
    int position;
    int score;
    int bucket;
}

static void SpawnCore_CopyPos(float dest[3], const float src[3])
{
    dest[0] = src[0];
    dest[1] = src[1];
    dest[2] = src[2];
}

// 通过 areaIdx 反查分桶：优先使用缓存，其次使用 Flow 百分比。
stock bool TryGetBucketByAreaIdx(int areaIdx, int &outBucket)
{
    outBucket = -1;
    if (areaIdx < 0) return false;

    if (g_AreaPct != null && areaIdx < g_AreaPct.Length)
    {
        int bucket = view_as<int>(g_AreaPct.Get(areaIdx));
        if (bucket >= 0 && bucket <= 100)
        {
            outBucket = bucket;
            return true;
        }
    }

    if (g_AllNavAreasCache != null && areaIdx < g_NavAreasCacheCount)
    {
        Address areaAddr = g_AllNavAreasCache.Get(areaIdx);
        if (areaAddr != Address_Null)
        {
            NavArea area = view_as<NavArea>(areaAddr);
            if (area)
            {
                float flow = area.GetFlow();
                float maxFlow = L4D2Direct_GetMapMaxFlowDistance();
                if (flow >= 0.0 && flow <= maxFlow)
                {
                    outBucket = ClampInt(FlowDistanceToPercent(flow), 0, 100);
                    return true;
                }
            }
        }
    }
    return false;
}

static bool SpawnCore_EvaluateNavCandidate(int zc,
                                           int targetSurvivor,
                                           float searchRange,
                                           bool teleportMode,
                                           int areaIdx,
                                           int knownBucket,
                                           bool rejectBadFlow,
                                           float mapMaxFlowDist,
                                           bool finaleArea,
                                           const float center[3],
                                           int sectors,
                                           int preferredSector,
                                           float allMinZ,
                                           float allMaxZ,
                                           int centerBucket,
                                           float refEyeZ,
                                           float minScore,
                                           SpawnScoreDbg candDbg,
                                           SpawnFilterStats stats)
{
    if (IsNavOnCooldown(areaIdx, GetGameTime()))
    {
        stats.cooldown++;
        return false;
    }

    if (areaIdx < 0 || areaIdx >= g_NavAreasCacheCount)
    {
        stats.position++;
        return false;
    }

    Address areaAddr = g_AllNavAreasCache.Get(areaIdx);
    NavArea area = view_as<NavArea>(areaAddr);

    if (!area || !IsValidFlags(area.SpawnAttributes, finaleArea))
    {
        stats.flags++;
        return false;
    }

    float flow = area.GetFlow();
    if (rejectBadFlow && IsFlowAbnormal(flow, mapMaxFlowDist))
    {
        stats.flow++;
        return false;
    }

    float pos[3];
    area.GetRandomPoint(pos);

    int candidateBucket = knownBucket;
    if (candidateBucket < 0)
        candidateBucket = FlowDistanceToPercent(flow);
    candidateBucket = ClampInt(candidateBucket, 0, 100);

    float bucketMinZ = g_BucketMinZ[candidateBucket];
    float bucketMaxZ = g_BucketMaxZ[candidateBucket];
    if (bucketMaxZ <= bucketMinZ)
    {
        bucketMinZ = allMinZ - 50.0;
        bucketMaxZ = allMaxZ + 50.0;
    }

    float slack = 0.0;
    if (zc != view_as<int>(SI_Charger) && zc != view_as<int>(SI_Jockey))
        slack = HeightRingSlack(pos, bucketMinZ, bucketMaxZ, allMaxZ);

    float ringEff = FloatMin(searchRange + slack, gCV.fSpawnMax);
    float dminEye = GetMinEyeDistToAnySurvivor(pos);

    if (!(dminEye >= gCV.fSpawnMin && dminEye <= ringEff))
    {
        stats.distance++;
        return false;
    }
    if (!PassMinSeparation(pos))
    {
        stats.separation++;
        return false;
    }
    if (!PassRealPositionCheck(pos, targetSurvivor, zc))
    {
        stats.position++;
        return false;
    }
    if (WillStuck(pos))
    {
        stats.stuck++;
        return false;
    }
    if (IsPosVisibleSDK(pos, teleportMode))
    {
        stats.visibility++;
        return false;
    }
    if (PathPenalty_NoBuild(pos, targetSurvivor, searchRange, gCV.fSpawnMax) != 0.0)
    {
        stats.path++;
        return false;
    }
    if (!PassBucketShareLimit(candidateBucket))
    {
        stats.bucket++;
        return false;
    }

    bool rawBadFlow = IsFlowAbnormal(flow, mapMaxFlowDist);
    int sector = ComputeSectorIndex(center, pos, sectors);
    if (!SpawnScore_BuildCandidate(zc, pos, dminEye, ringEff, slack,
                                   candidateBucket, centerBucket, rawBadFlow,
                                   refEyeZ, allMaxZ, sector, preferredSector,
                                   areaIdx, candDbg))
    {
        stats.flow++;
        return false;
    }

    if (candDbg.total < minScore)
    {
        stats.score++;
        return false;
    }

    return true;
}

bool FindSpawnPosViaNavArea(int zc, int targetSurvivor, float searchRange, bool teleportMode,
                            float outPos[3], int &outAreaIdx, SpawnScoreDbg dbgOut)
{
    if (!GetSurPosData())
    {
        Debug_Print("[FIND FAIL] no survivor data");
        return false;
    }

    EnsureNavAreasCache();
    int areaCount = g_NavAreasCacheCount;

    float mapMaxFlowDist = L4D2Direct_GetMapMaxFlowDistance();
    bool finaleArea = L4D_IsMissionFinalMap() && L4D2_GetCurrentFinaleStage() < FINALE_STAGE_ESCAPE;

    float center[3];
    GetSectorCenter(center, targetSurvivor);
    int sectors = GetCurrentSectors();
    int preferredSector = PickSector(sectors);

    float allMinZ = 1.0e9;
    float allMaxZ = -1.0e9;
    SurPosData data;
    for (int i = 0; i < g_iSurPosDataLen; i++)
    {
        g_aSurPosData.GetArray(i, data);
        if (data.fPos[2] < allMinZ) allMinZ = data.fPos[2];
        if (data.fPos[2] > allMaxZ) allMaxZ = data.fPos[2];
    }

    int centerBucket = 50;
    if (IsValidSurvivor(targetSurvivor) && IsPlayerAlive(targetSurvivor) && !L4D_IsPlayerIncapacitated(targetSurvivor))
    {
        int pct;
        if (TryGetClientFlowPercentSafe(targetSurvivor, pct))
            centerBucket = pct;
    }
    else
    {
        float bestFlow = -1.0;
        SurPosData fallbackData;
        for (int i = 0; i < g_iSurPosDataLen; i++)
        {
            g_aSurPosData.GetArray(i, fallbackData);
            if (fallbackData.fFlow > bestFlow) bestFlow = fallbackData.fFlow;
        }
        if (bestFlow >= 0.0)
            centerBucket = FlowDistanceToPercent(bestFlow);
    }

    float refEyeZ = allMaxZ;
    if (IsValidSurvivor(targetSurvivor) && IsPlayerAlive(targetSurvivor) && !L4D_IsPlayerIncapacitated(targetSurvivor))
    {
        float eye[3];
        GetClientEyePosition(targetSurvivor, eye);
        refEyeZ = eye[2];
    }

    bool found = false;
    float bestScore = -1.0e9;
    int acceptedHits = 0;

    bool useBuckets = (gCV.bNavBucketEnable && g_BucketsReady);
    bool firstFit = gCV.bNavBucketFirstFit;
    float minScore = gCV.fSpawnScoreFloor;
    float firstFitScore = FloatMax(ComputeFFThresholdForClass(zc), minScore);
    int candidateBudget = DifficultyStrategy_GetCandidateBudget();

    SpawnScoreDbg bestDbg;
    SpawnFilterStats stats;

    if (useBuckets)
    {
        int win = ClampInt(ComputeDynamicBucketWindow(searchRange), 0, 100);
        int order[FLOW_BUCKETS];
        int orderLen = BuildBucketOrder(centerBucket, win, gCV.bNavBucketIncludeCtr, order);

        for (int orderIdx = 0; orderIdx < orderLen; orderIdx++)
        {
            int bucketIdx = order[orderIdx];
            if (bucketIdx < 0 || bucketIdx > 100 || g_FlowBuckets[bucketIdx] == null)
                continue;

            int bucketLen = g_FlowBuckets[bucketIdx].Length;
            if (bucketLen <= 0)
                continue;

            for (int row = 0; row < bucketLen && acceptedHits < candidateBudget; row++)
            {
                int areaIdx = g_FlowBuckets[bucketIdx].Get(row);
                SpawnScoreDbg candDbg;
                if (!SpawnCore_EvaluateNavCandidate(zc, targetSurvivor, searchRange, teleportMode,
                                                     areaIdx, bucketIdx, false,
                                                     mapMaxFlowDist, finaleArea, center,
                                                     sectors, preferredSector, allMinZ, allMaxZ,
                                                     centerBucket, refEyeZ, minScore,
                                                     candDbg, stats))
                {
                    continue;
                }

                acceptedHits++;

                if (firstFit && candDbg.total >= firstFitScore)
                {
                    SpawnScore_CopyDbg(dbgOut, candDbg);
                    SpawnCore_CopyPos(outPos, candDbg.pos);
                    outAreaIdx = areaIdx;
                    return true;
                }

                if (!found || candDbg.total > bestScore)
                {
                    found = true;
                    bestScore = candDbg.total;
                    SpawnScore_CopyDbg(bestDbg, candDbg);
                }
            }
            if (acceptedHits >= candidateBudget)
                break;
        }
    }
    else
    {
        for (int areaIdx = 0; areaIdx < areaCount && acceptedHits < candidateBudget; areaIdx++)
        {
            SpawnScoreDbg candDbg;
            if (!SpawnCore_EvaluateNavCandidate(zc, targetSurvivor, searchRange, teleportMode,
                                                 areaIdx, -1, true,
                                                 mapMaxFlowDist, finaleArea, center,
                                                 sectors, preferredSector, allMinZ, allMaxZ,
                                                 centerBucket, refEyeZ, minScore,
                                                 candDbg, stats))
            {
                continue;
            }

            acceptedHits++;

            if (firstFit && candDbg.total >= firstFitScore)
            {
                SpawnScore_CopyDbg(dbgOut, candDbg);
                SpawnCore_CopyPos(outPos, candDbg.pos);
                outAreaIdx = areaIdx;
                return true;
            }

            if (!found || candDbg.total > bestScore)
            {
                found = true;
                bestScore = candDbg.total;
                SpawnScore_CopyDbg(bestDbg, candDbg);
            }
        }
    }

    if (!found)
    {
        Debug_Print("[FIND FAIL] ring=%.1f. Filters: cd=%d,flag=%d,flow=%d,dist=%d,sep=%d,stuck=%d,vis=%d,path=%d,pos=%d,score=%d,bkt=%d",
                    searchRange, stats.cooldown, stats.flags, stats.flow, stats.distance, stats.separation,
                    stats.stuck, stats.visibility, stats.path, stats.position, stats.score, stats.bucket);
        return false;
    }

    SpawnScore_CopyDbg(dbgOut, bestDbg);
    SpawnCore_CopyPos(outPos, bestDbg.pos);
    outAreaIdx = bestDbg.areaIdx;
    return true;
}

// 计算到任意幸存者“眼睛”的最小距离，用于刷出硬下限判定。
float GetMinEyeDistToAnySurvivor(const float pos[3])
{
    float best = 999999.0;
    float eyes[3];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidSurvivor(i) || !IsPlayerAlive(i))
            continue;

        GetClientEyePosition(i, eyes);
        float distance = GetVectorDistance(pos, eyes);
        if (distance < best)
            best = distance;
    }
    return best;
}
