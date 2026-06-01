#if defined _infected_control_anti_baiter_included
    #endinput
#endif
#define _infected_control_anti_baiter_included

enum AntiBaitState
{
    AB_Off = 0,
    AB_Grace,
    AB_Observe,
    AB_Pressure,
    AB_Recover
}

enum struct AntiBaitRuntime
{
    AntiBaitState state;
    int baselineAvgPct;
    int baselineMaxPct;
    int lastAvgPct;
    int lastMaxPct;
    int lastMedianPct;
    int runner;
    int isolatedCount;
    int groupCount;
    float stateSince;
    float lastProgressTime;
    float pressureSince;
    float lastSpreadDist;
    float lastAvgNearestDist;
    bool teamHolding;
    bool attackableSpread;
    bool allPinned;

    void Reset()
    {
        this.state = AB_Off;
        this.baselineAvgPct = -1;
        this.baselineMaxPct = -1;
        this.lastAvgPct = -1;
        this.lastMaxPct = -1;
        this.lastMedianPct = -1;
        this.runner = -1;
        this.isolatedCount = 0;
        this.groupCount = 0;
        this.stateSince = 0.0;
        this.lastProgressTime = 0.0;
        this.pressureSince = 0.0;
        this.lastSpreadDist = 0.0;
        this.lastAvgNearestDist = 0.0;
        this.teamHolding = false;
        this.attackableSpread = false;
        this.allPinned = false;
    }
}

static AntiBaitRuntime gAB;

static const char g_sAntiBaitStateName[][] =
{
    "Off",
    "Grace",
    "Observe",
    "Pressure",
    "Recover"
};

static void AntiBait_Debug(const char[] fmt, any ...)
{
    if (!gCV.bAntiBaitDebug && gCV.iDebugMode <= 0)
        return;

    char msg[256];
    VFormat(msg, sizeof msg, fmt, 2);
    Debug_Print("[AB] %s", msg);
}

static void AntiBait_SetState(AntiBaitState next, float now, const char[] reason)
{
    if (gAB.state == next)
        return;

    AntiBait_Debug("%s -> %s (%s)", g_sAntiBaitStateName[view_as<int>(gAB.state)], g_sAntiBaitStateName[view_as<int>(next)], reason);
    gAB.state = next;
    gAB.stateSince = now;
    if (next == AB_Pressure)
        gAB.pressureSince = now;
}

static int AntiBait_ClampPct(int pct)
{
    if (pct < 0) return 0;
    if (pct > 100) return 100;
    return pct;
}

static bool AntiBait_GetProgressSnapshot(int &avgPct,
                                         int &maxPct,
                                         int &medianPct,
                                         int &highestClient,
                                         float &spreadDist,
                                         float &avgNearestDist,
                                         int &isolatedCount,
                                         int &groupCount)
{
    int pcts[MAX_SURVIVOR_SLOTS];
    int n = 0;
    int sum = 0;
    maxPct = -1;
    highestClient = -1;
    spreadDist = 0.0;
    avgNearestDist = 0.0;
    isolatedCount = 0;
    groupCount = 0;
    float pos[MAX_SURVIVOR_SLOTS][3];
    float nearest[MAX_SURVIVOR_SLOTS];
    bool linked[MAX_SURVIVOR_SLOTS][MAX_SURVIVOR_SLOTS];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidSurvivor(i) || !IsPlayerAlive(i) || L4D_IsPlayerIncapacitated(i))
            continue;

        int pct;
        if (!TryGetClientFlowPercentSafe(i, pct))
            continue;

        pct = AntiBait_ClampPct(pct);
        if (n < sizeof(pcts))
        {
            pcts[n] = pct;
            GetClientAbsOrigin(i, pos[n]);
            nearest[n] = 999999.0;
            n++;
        }
        sum += pct;
        if (pct > maxPct)
        {
            maxPct = pct;
            highestClient = i;
        }
    }

    if (n <= 0)
        return false;

    SortIntegers(pcts, n, Sort_Ascending);
    avgPct = RoundToNearest(float(sum) / float(n));
    medianPct = pcts[n / 2];

    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
            linked[i][j] = (i == j);
    }

    for (int i = 0; i < n; i++)
    {
        for (int j = i + 1; j < n; j++)
        {
            float dist = GetVectorDistance(pos[i], pos[j]);
            if (dist > spreadDist)
                spreadDist = dist;
            if (dist < nearest[i])
                nearest[i] = dist;
            if (dist < nearest[j])
                nearest[j] = dist;
            if (gCV.fAntiBaitPairDist > 0.0 && dist <= gCV.fAntiBaitPairDist)
            {
                linked[i][j] = true;
                linked[j][i] = true;
            }
        }
    }

    if (gCV.fAntiBaitPairDist > 0.0)
    {
        bool seen[MAX_SURVIVOR_SLOTS];
        int stack[MAX_SURVIVOR_SLOTS];
        for (int i = 0; i < n; i++)
            seen[i] = false;

        for (int i = 0; i < n; i++)
        {
            if (seen[i])
                continue;

            groupCount++;
            int top = 0;
            stack[top++] = i;
            seen[i] = true;

            while (top > 0)
            {
                int cur = stack[--top];
                for (int j = 0; j < n; j++)
                {
                    if (seen[j] || !linked[cur][j])
                        continue;

                    seen[j] = true;
                    if (top < sizeof(stack))
                        stack[top++] = j;
                }
            }
        }
    }
    else
    {
        groupCount = 1;
    }

    if (n > 1)
    {
        float nearestSum = 0.0;
        for (int i = 0; i < n; i++)
        {
            nearestSum += nearest[i];
            if (gCV.fAntiBaitIsolateDist > 0.0 && nearest[i] >= gCV.fAntiBaitIsolateDist)
                isolatedCount++;
        }
        avgNearestDist = nearestSum / float(n);
    }

    return true;
}

static bool AntiBait_IsEventBlocked()
{
    if (!gCV.bAntiBaitEnable)
        return true;
    if (!gST.bLate)
        return true;
    if (g_bPauseLib && IsInPause())
        return true;
    if (IsAnyTankOrAboveHalfSurvivorDownOrDied(1))
        return true;
    if (gAB.allPinned)
        return true;
    return false;
}

static float AntiBait_GetSpawnLatestScale()
{
    int level = DifficultyStrategy_GetLevel();

    // 档位越高，允许拖延的“最晚开波”越接近基础刷新时间；绝不低于基础刷新间隔。
    float scale = gCV.fAntiBaitLatestBaseScale - (float(level - 1) * gCV.fAntiBaitLatestScaleStep);
    if (scale < 1.0)
        scale = 1.0;
    if (scale > 3.0)
        scale = 3.0;
    return scale;
}

static float AntiBait_GetLatestWaveDelay()
{
    return gCV.fSiInterval * AntiBait_GetSpawnLatestScale();
}

static bool AntiBait_HasReachedEarliestSpawnTime()
{
    return DifficultyStrategy_CanStartNormalWave();
}

static float AntiBait_GetPressureAge()
{
    if (gAB.state != AB_Pressure || gAB.pressureSince <= 0.0)
        return 0.0;

    return GetGameTime() - gAB.pressureSince;
}

static bool AntiBait_HasEnoughSiPressure()
{
    if (gCV.iSiLimit <= 0)
        return false;

    float ratio = float(gST.totalSI) / float(gCV.iSiLimit);
    return ratio >= gCV.fAntiBaitMinSiRatio;
}

static bool AntiBait_IsSpawnWindowPressure()
{
    if (AntiBait_HasEnoughSiPressure())
        return true;

    if (gST.siQueueCount > 0 || SpawnQueue_Length() > 0 || TeleportQueue_Length() > 0)
        return true;

    return DifficultyStrategy_CanEvaluateWave();
}

static bool AntiBait_TeamHoldingFormation(float spreadDist, float avgNearestDist, int isolatedCount, int groupCount)
{
    if (groupCount > 1)
        return false;

    if (isolatedCount > 0)
        return false;

    if (gCV.fAntiBaitClusterDist > 0.0 && spreadDist <= gCV.fAntiBaitClusterDist)
        return true;

    if (gCV.fAntiBaitTeamDist > 0.0 && spreadDist > gCV.fAntiBaitTeamDist)
        return false;

    return gCV.fAntiBaitPairDist <= 0.0 || avgNearestDist <= gCV.fAntiBaitPairDist;
}

static bool AntiBait_TeamAttackableSpread(float spreadDist, int isolatedCount, int groupCount)
{
    if (groupCount > 1)
        return true;

    if (isolatedCount > 0)
        return true;

    return gCV.fAntiBaitTeamDist > 0.0 && spreadDist >= gCV.fAntiBaitTeamDist;
}

static bool AntiBait_IsRunnerCandidate(int client, int maxPct, int medianPct)
{
    if (!IsValidSurvivor(client) || !IsPlayerAlive(client) || IsPinned(client) || L4D_IsPlayerIncapacitated(client))
        return false;

    if ((maxPct - medianPct) < gCV.iAntiBaitRunnerGapPct)
        return false;

    float runnerPos[3], otherPos[3];
    GetClientAbsOrigin(client, runnerPos);

    bool hasNearbySurvivor = false;
    float nearDist2 = gCV.fAntiBaitRunnerNearDist * gCV.fAntiBaitRunnerNearDist;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == client || !IsValidSurvivor(i) || !IsPlayerAlive(i) || L4D_IsPlayerIncapacitated(i))
            continue;

        GetClientAbsOrigin(i, otherPos);
        if (GetVectorDistance(runnerPos, otherPos, true) <= nearDist2)
        {
            hasNearbySurvivor = true;
            break;
        }
    }

    return !hasNearbySurvivor;
}

static void AntiBait_UpdateRunner(int highestClient, int maxPct, int medianPct)
{
    bool oldOn = gST.bPickRushMan;
    int oldRunner = gST.rushManIndex;

    if (AntiBait_IsRunnerCandidate(highestClient, maxPct, medianPct))
    {
        gAB.runner = highestClient;
        gST.bPickRushMan = true;
        gST.rushManIndex = highestClient;

        if (!oldOn || oldRunner != highestClient)
        {
            LogMsg("Runner state ON: %N", highestClient);
            EmitRushmanForward(highestClient);
        }
    }
    else
    {
        gAB.runner = -1;
        gST.bPickRushMan = false;
        gST.rushManIndex = -1;
        if (oldOn)
            LogMsg("Runner state OFF");
    }
}

static void AntiBait_ClearRunner()
{
    if (gST.bPickRushMan)
        LogMsg("Runner state OFF");

    gAB.runner = -1;
    gST.bPickRushMan = false;
    gST.rushManIndex = -1;
}

void AntiBait_OnRoundStart()
{
    gAB.Reset();
}

void AntiBait_OnWaveStart()
{
    float now = GetGameTime();
    gAB.Reset();
    gAB.state = gCV.bAntiBaitEnable ? AB_Grace : AB_Off;
    gAB.stateSince = now;
    gAB.lastProgressTime = now;

    int avgPct, maxPct, medianPct, highest, isolatedCount, groupCount;
    float spreadDist, avgNearestDist;
    if (AntiBait_GetProgressSnapshot(avgPct, maxPct, medianPct, highest, spreadDist, avgNearestDist, isolatedCount, groupCount))
    {
        gAB.baselineAvgPct = avgPct;
        gAB.baselineMaxPct = maxPct;
        gAB.lastAvgPct = avgPct;
        gAB.lastMaxPct = maxPct;
        gAB.lastMedianPct = medianPct;
        gAB.lastSpreadDist = spreadDist;
        gAB.lastAvgNearestDist = avgNearestDist;
        gAB.isolatedCount = isolatedCount;
        gAB.groupCount = groupCount;
        gAB.teamHolding = AntiBait_TeamHoldingFormation(spreadDist, avgNearestDist, isolatedCount, groupCount);
        gAB.attackableSpread = AntiBait_TeamAttackableSpread(spreadDist, isolatedCount, groupCount);
    }
}

void AntiBait_Update()
{
    float now = GetGameTime();
    gAB.allPinned = Survivors_AllPinnedOrDown();

    if (!gCV.bAntiBaitEnable)
    {
        AntiBait_ClearRunner();
        AntiBait_SetState(AB_Off, now, "disabled");
        return;
    }

    if (AntiBait_IsEventBlocked())
    {
        AntiBait_ClearRunner();
        if (gAB.state != AB_Off)
            AntiBait_Debug("blocked state=%s allPinned=%d", g_sAntiBaitStateName[view_as<int>(gAB.state)], gAB.allPinned);
        return;
    }

    int avgPct, maxPct, medianPct, highest, isolatedCount, groupCount;
    float spreadDist, avgNearestDist;
    if (!AntiBait_GetProgressSnapshot(avgPct, maxPct, medianPct, highest, spreadDist, avgNearestDist, isolatedCount, groupCount))
        return;

    gAB.lastAvgPct = avgPct;
    gAB.lastMaxPct = maxPct;
    gAB.lastMedianPct = medianPct;
    gAB.lastSpreadDist = spreadDist;
    gAB.lastAvgNearestDist = avgNearestDist;
    gAB.isolatedCount = isolatedCount;
    gAB.groupCount = groupCount;
    gAB.teamHolding = AntiBait_TeamHoldingFormation(spreadDist, avgNearestDist, isolatedCount, groupCount);
    gAB.attackableSpread = AntiBait_TeamAttackableSpread(spreadDist, isolatedCount, groupCount);
    AntiBait_UpdateRunner(highest, maxPct, medianPct);

    if (gAB.baselineAvgPct < 0 || gAB.baselineMaxPct < 0)
    {
        gAB.baselineAvgPct = avgPct;
        gAB.baselineMaxPct = maxPct;
        gAB.lastProgressTime = now;
    }

    bool progressed = ((avgPct - gAB.baselineAvgPct) >= gCV.iAntiBaitProgressPct)
                   || ((maxPct - gAB.baselineMaxPct) >= gCV.iAntiBaitProgressPct);
    bool releasedBySpread = gAB.attackableSpread;

    if (progressed || releasedBySpread)
    {
        if (progressed)
        {
            gAB.baselineAvgPct = avgPct;
            gAB.baselineMaxPct = maxPct;
        }
        gAB.lastProgressTime = now;
        if (gAB.state == AB_Pressure)
            AntiBait_SetState(AB_Recover, now, progressed ? "progress" : "spread");
        else if (gAB.state == AB_Recover && (now - gAB.stateSince) >= gCV.fAntiBaitRecover)
            AntiBait_SetState(AB_Observe, now, "recovered");
        return;
    }

    if (gAB.state == AB_Grace)
    {
        if ((now - gAB.stateSince) >= gCV.fAntiBaitGrace)
            AntiBait_SetState(AB_Observe, now, "grace done");
        return;
    }

    if (gAB.state == AB_Recover)
    {
        if ((now - gAB.stateSince) >= gCV.fAntiBaitRecover)
            AntiBait_SetState(AB_Observe, now, "recover done");
        return;
    }

    if (gAB.state == AB_Observe)
    {
        bool stalled = (now - gAB.lastProgressTime) >= gCV.fAntiBaitWindow;
        if (stalled && AntiBait_IsSpawnWindowPressure() && gAB.teamHolding)
            AntiBait_SetState(AB_Pressure, now, "team holding near spawn window");
    }
}

bool AntiBait_ShouldStartWaveByLatest()
{
    if (!gCV.bAntiBaitEnable || gST.hSpawn != INVALID_HANDLE || !gST.bShouldCheck)
        return false;
    if (!AntiBait_HasReachedEarliestSpawnTime())
        return false;

    return float(gST.lastSpawnSecs) >= AntiBait_GetLatestWaveDelay();
}

bool AntiBait_ShouldStartWaveEarly()
{
    if (!gCV.bAntiBaitEnable || gCV.iAntiBaitAction < 1)
        return false;
    if (gAB.state != AB_Pressure)
        return false;
    if (!AntiBait_HasReachedEarliestSpawnTime())
        return false;

    return AntiBait_GetPressureAge() >= gCV.fAntiBaitForceAfter;
}

bool AntiBait_ShouldFastTeleport(int client)
{
    if (!gCV.bAntiBaitEnable || gCV.iAntiBaitAction < 2)
        return false;
    if (gAB.state != AB_Pressure)
        return false;
    if (!CanBeTeleport(client))
        return false;

    return true;
}

int AntiBait_GetPreferredTarget()
{
    if (!gCV.bAntiBaitEnable)
        return -1;
    if (gAB.runner > 0 && IsValidSurvivor(gAB.runner) && IsPlayerAlive(gAB.runner) && !IsPinned(gAB.runner))
        return gAB.runner;

    return -1;
}
