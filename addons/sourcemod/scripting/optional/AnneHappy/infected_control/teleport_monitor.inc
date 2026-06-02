#if defined _infected_control_teleport_monitor_included
    #endinput
#endif
#define _infected_control_teleport_monitor_included

// 传送监督（1s）：出生宽限 + 跑男/anti-bait 快通道。
Action Timer_TeleportTick(Handle timer)
{
    if (g_bPauseLib && IsInPause())
        return Plugin_Continue;

    RefreshLastGoodSurPctTick();
    AntiBait_Update();

    if (Survivors_AllPinnedOrDown())
        return Plugin_Continue;

    float now = GetGameTime();

    for (int c = 1; c <= MaxClients; c++)
    {
        if (!CanBeTeleport(c))
            continue;

        if (gCV.fTeleportSpawnGrace > 0.0)
        {
            float born = g_LastSpawnTime[c];
            if (born > 0.0 && (now - born) < gCV.fTeleportSpawnGrace)
            {
                if (gST.teleCount[c] != 0) gST.teleCount[c] = 0;
                continue;
            }
        }

        float eyes[3];
        GetClientEyePosition(c, eyes);
        bool vis = IsPosVisibleSDK(eyes, true);

        if (!vis)
        {
            if (TeleportQueue_Length() == 0)
                gST.teleportDistCur = gCV.fSpawnMin;

            int zc = GetInfectedClass(c);
            if (zc == view_as<int>(SI_Smoker) && g_bSmokerLib)
            {
                if (!IsSmokerReadyToAttack(c))
                {
                    gST.teleCount[c]++;
                    if (gST.teleCount[c] > 0 && gST.teleCount[c] % 5 == 0)
                        LogMsg("[TP] smoker %N: ability not ready -> skip teleport (tick=%d)", c, gST.teleCount[c]);
                    continue;
                }
            }

            gST.teleCount[c]++;

            float needSecs = float(gCV.iTeleportCheckTime);
            bool runnerFastPath = (gST.bPickRushMan && TeleportQueue_Length() == 0);
            if (runnerFastPath && gCV.fTeleportRunnerFast > 0.0 && gCV.fTeleportRunnerFast < needSecs)
                needSecs = gCV.fTeleportRunnerFast;
            if (AntiBait_ShouldFastTeleport(c) && gCV.fAntiBaitFastTeleport < needSecs)
                needSecs = gCV.fAntiBaitFastTeleport;
            if (needSecs < MIN_TELEPORT_SECONDS) needSecs = MIN_TELEPORT_SECONDS;

            if (float(gST.teleCount[c]) >= needSecs)
            {
                if (zc >= 1 && zc <= 6)
                {
                    TeleportQueue_Push(zc);

                    if (gST.siAlive[zc - 1] > 0) gST.siAlive[zc - 1]--; else gST.siAlive[zc - 1] = 0;
                    if (gST.totalSI > 0) gST.totalSI--; else gST.totalSI = 0;
                    InvalidateBucketShareCache();

                    LogMsg("[TP] %N class=%s invisible for %.1f sec%s -> teleport respawn",
                           c, g_sInfectedClassNames[zc], float(gST.teleCount[c]),
                           runnerFastPath ? " (runner-fast)" : "");

                    KickClient(c, "Teleport SI");
                    RecalcSiCapFromAlive(false);
                    gST.teleCount[c] = 0;
                }
            }
        }
        else
        {
            if (gST.teleCount[c] > 0 && (gST.teleCount[c] % 5 == 0))
                LogMsg("[TP] %N visible again (reset tick=%d)", c, gST.teleCount[c]);

            gST.teleCount[c] = 0;
        }
    }

    gST.targetSurvivor = ChooseTargetSurvivor();
    return Plugin_Continue;
}
