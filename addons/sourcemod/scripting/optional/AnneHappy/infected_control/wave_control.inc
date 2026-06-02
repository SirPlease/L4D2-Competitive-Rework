#if defined _infected_control_wave_control_included
    #endinput
#endif
#define _infected_control_wave_control_included

// 波控制：负责开波、自动刷特窗口以及暂停恢复。
void StartWave()
{
    ClearPathCache();
    RecalcSiCapFromAlive(true);

    gST.survCount = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidSurvivor(i) && IsPlayerAlive(i) && gST.survCount < sizeof(gST.survIdx))
            gST.survIdx[gST.survCount++] = i;
    }

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

    AntiBait_OnWaveStart();
    Debug_Print("Start wave %d", gST.waveIndex);
}

Action Timer_StartNewWave(Handle timer)
{
    StartWave();
    gST.hSpawn = INVALID_HANDLE;
    gST.lastWaveStartTime = GetGameTime();
    return Plugin_Stop;
}

Action Timer_CheckSpawnWindow(Handle timer)
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
    AntiBait_Update();

    if (!gST.bShouldCheck || gST.hSpawn != INVALID_HANDLE) return Plugin_Continue;

    int survivorLimit = (gCV.SurvivorLimit != null) ? gCV.SurvivorLimit.IntValue : 4;
    if (survivorLimit >= 2 && IsAnyTankOrAboveHalfSurvivorDownOrDied(1) && !DifficultyStrategy_CanEvaluateWave())
        return Plugin_Continue;

    bool canEvaluateWave = DifficultyStrategy_CanEvaluateWave();
    bool reachedSpawnFloor = DifficultyStrategy_CanStartNormalWave();
    bool lowSiPressure = DifficultyStrategy_IsLowSiPressure();
    bool shouldStartByLatest = AntiBait_ShouldStartWaveByLatest();
    bool shouldStartByPressure = AntiBait_ShouldStartWaveEarly();

    if (!gCV.bAutoSpawn)
    {
        if (gST.siQueueCount == gCV.iSiLimit)
        {
            gST.lastSpawnSecs = 0;
        }
        else if (reachedSpawnFloor || shouldStartByLatest || shouldStartByPressure)
        {
            gST.bShouldCheck = false;
            gST.hSpawn = CreateTimer(0.1, Timer_StartNewWave);
        }
    }
    else if (reachedSpawnFloor && (
        (IsAllKillersDown() && gST.siQueueCount == 0)
        || (lowSiPressure && gST.siQueueCount == 0)
        || shouldStartByLatest
        || shouldStartByPressure))
    {
        if (gST.siQueueCount == gCV.iSiLimit)
        {
            gST.lastSpawnSecs = 0;
        }
        else
        {
            gST.bShouldCheck = false;
            gST.hSpawn = CreateTimer(0.1, Timer_StartNewWave);
        }
    }
    else if (canEvaluateWave && shouldStartByPressure)
    {
        gST.bShouldCheck = false;
        gST.hSpawn = CreateTimer(0.1, Timer_StartNewWave);
    }

    return Plugin_Continue;
}

void PauseSpawnTimer()
{
    if (gST.hSpawn != INVALID_HANDLE)
    {
        gST.unpauseDelay = gCV.fSiInterval - (GetGameTime() - gST.lastWaveStartTime);
        KillTimer(gST.hSpawn);
        gST.hSpawn = INVALID_HANDLE;
        Debug_Print("Pause spawn timer, resume after %.2f", gST.unpauseDelay);
    }
}

void UnpauseSpawnTimer(float delay)
{
    if (gST.hSpawn == INVALID_HANDLE)
    {
        gST.hSpawn = CreateTimer(delay, Timer_StartNewWave);
        Debug_Print("Resume spawn in %.2f", delay);
    }
}
