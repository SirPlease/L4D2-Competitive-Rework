#if defined _infected_control_nav_debug_included
    #endinput
#endif
#define _infected_control_nav_debug_included

#if defined DEBUG_NAV

// ===== 准星 NavArea 查看命令 =====
public Action Cmd_NavPeek(int client, int args)
{
    if (!client || !IsClientInGame(client))
        return Plugin_Handled;

    float hit[3];
    if (!NavDebug_GetAimHitPos(client, hit))
    {
        CPrintToChat(client, "%t", "InfectedControl_ICFailedObtainCrosshairHit");
        return Plugin_Handled;
    }

    // 命中点所在的 TerrorNavArea；不行就找最近
    Address area = L4D2Direct_GetTerrorNavArea(hit);
    if (area == Address_Null)
        area = view_as<Address>(L4D_GetNearestNavArea(hit, 300.0, false, false, false, TEAM_INFECTED));

    if (area == Address_Null)
    {
        CPrintToChat(client, "%t", "InfectedControl_ICNoNavAreaNearby");
        return Plugin_Handled;
    }

    NavArea na = view_as<NavArea>(area);
    int navid  = L4D_GetNavAreaID(area);
    int index  = NavDebug_FindNavIndexByAddress(area);

    float flowDist = na.GetFlow();                      // 可能为负(无效)
    float maxFlow  = L4D2Direct_GetMapMaxFlowDistance();
    int   bucketC  = (flowDist >= 0.0 && maxFlow > 0.0) ? FlowDistanceToPercent(flowDist) : -1;

    // 若预分桶已就绪，拿“归档桶”和区域高度统计
    int   bucketA = -1;
    float aZCore = 0.0, aZMin = 0.0, aZMax = 0.0;
    float bZMin  = 0.0, bZMax  = 0.0;

    if (g_BucketsReady && index >= 0 && g_AreaPct != null)
    {
        bucketA = view_as<int>(g_AreaPct.Get(index));
        aZCore  = view_as<float>(g_AreaZCore.Get(index));
        aZMin   = view_as<float>(g_AreaZMin.Get(index));
        aZMax   = view_as<float>(g_AreaZMax.Get(index));
        if (0 <= bucketA && bucketA <= 100)
        {
            bZMin = g_BucketMinZ[bucketA];
            bZMax = g_BucketMaxZ[bucketA];
        }
    }

    // 解析 Nav flags
    int flags = na.SpawnAttributes;
    char flagBuf[256];
    NavDebug_DescribeNavFlags(flags, flagBuf, sizeof flagBuf);

    // —— 控制台详细 —— //
    PrintToConsole(client, "=== [IC] NavPeek ===");
    PrintToConsole(client, "pos = (%.1f, %.1f, %.1f)", hit[0], hit[1], hit[2]);
    PrintToConsole(client, "navid = %d, index = %d", navid, index);
    if (bucketC >= 0)
        PrintToConsole(client, "flow = %.1f / %.1f  -> bucket(computed) = %d", flowDist, maxFlow, bucketC);
    else
        PrintToConsole(client, "flow = (invalid) -> bucket(computed) = N/A");

    if (g_BucketsReady)
    {
        PrintToConsole(client, "bucket(assigned) = %d", bucketA);
        PrintToConsole(client, "areaZ(core/min/max) = %.1f / %.1f / %.1f", aZCore, aZMin, aZMax);
        if (0 <= bucketA && bucketA <= 100)
            PrintToConsole(client, "bucketZ[min..max] = [%.1f .. %.1f]", bZMin, bZMax);
    }
    PrintToConsole(client, "flags = %s", flagBuf[0] ? flagBuf : "(none)");

    // —— 聊天简要 —— //
    if (bucketC >= 0)
        CPrintToChat(client, "%t", "InfectedControl_ICNavidBucketCalculationReturn", navid, bucketC, bucketA, flagBuf);
    else
        CPrintToChat(client, "%t", "InfectedControl_ICNavidBucketReturnFlag", navid, bucketA, flagBuf);

    // DebugMode>=3：画一条短暂的准星射线，直观确认命中点
    if (gCV.iDebugMode >= 3)
        NavDebug_DrawAimLineOnce(client, hit);

    return Plugin_Handled;
}

// —— 计算准星命中点（忽略玩家/感染者/女巫，优先世界几何）——
static bool NavDebug_GetAimHitPos(int client, float outPos[3])
{
    float start[3], ang[3], dir[3], end[3];
    GetClientEyePosition(client, start);
    GetClientEyeAngles(client, ang);
    GetAngleVectors(ang, dir, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(dir, 5000.0);
    AddVectors(start, dir, end);

    Handle tr = TR_TraceRayFilterEx(start, end, MASK_SOLID, RayType_EndPoint, TraceFilter);
    if (TR_DidHit(tr))
    {
        TR_GetEndPosition(outPos, tr);
        delete tr;
        return true;
    }
    delete tr;
    outPos = end;
    return true;
}

// Nav 测试命令：正常 flow 仍按 ScoreFlowSmooth；raw badflow 叠加高度差惩罚。
public Action Cmd_NavTest(int client, int args)
{
    if (!client || !IsClientInGame(client))
        return Plugin_Handled;

    float hit[3];
    if (!NavDebug_GetAimHitPos(client, hit))
    {
        CPrintToChat(client, "%t", "InfectedControl_ICFailedObtainCrosshairHit");
        return Plugin_Handled;
    }

    Address area = L4D2Direct_GetTerrorNavArea(hit);
    if (area == Address_Null)
        area = view_as<Address>(L4D_GetNearestNavArea(hit, 300.0, false, false, false, TEAM_INFECTED));

    if (area == Address_Null)
    {
        CPrintToChat(client, "%t", "InfectedControl_ICNoNavAreaNearby");
        return Plugin_Handled;
    }

    NavArea na = view_as<NavArea>(area);
    int navid  = L4D_GetNavAreaID(area);
    int index  = NavDebug_FindNavIndexByAddress(area);

    float testPos[3];
    na.GetRandomPoint(testPos);

    PrintToConsole(client, "");
    PrintToConsole(client, "========================================");
    PrintToConsole(client, "=== [IC] Nav Spawn Test ===");
    PrintToConsole(client, "========================================");
    PrintToConsole(client, "NavID: %d | Index: %d", navid, index);
    PrintToConsole(client, "Test Pos: (%.1f, %.1f, %.1f)", testPos[0], testPos[1], testPos[2]);
    PrintToConsole(client, "");

    float now = GetGameTime();
    bool bFinaleArea = L4D_IsMissionFinalMap() && L4D2_GetCurrentFinaleStage() < FINALE_STAGE_ESCAPE;

    // 1. 冷却
    bool passCooldown = !IsNavOnCooldown(index, now);
    PrintToConsole(client, "[1] Cooldown Check: %s", passCooldown ? "PASS" : "FAIL (on cooldown)");

    // 2. Flags
    int flags = na.SpawnAttributes;
    bool passFlags = IsValidFlags(flags, bFinaleArea);
    char flagBuf[256];
    NavDebug_DescribeNavFlags(flags, flagBuf, sizeof flagBuf);
    PrintToConsole(client, "[2] Flags Check: %s | Flags: %s", passFlags ? "PASS" : "FAIL", flagBuf[0] ? flagBuf : "(none)");

    // 3. Flow
    float flowDist = na.GetFlow();
    float maxFlow  = L4D2Direct_GetMapMaxFlowDistance();
    bool  passFlowRaw = (flowDist >= 0.0 && flowDist <= maxFlow);

    int mappedPct = -1;
    if (gCV.bNavBucketEnable && g_BucketsReady && g_AreaPct != null && index >= 0 && index < g_AreaPct.Length) {
        mappedPct = view_as<int>(g_AreaPct.Get(index));  // 0..100 或 -1
    }
    bool passFlow = passFlowRaw || (mappedPct >= 0 && mappedPct <= 100);
    int  flowPercent = passFlowRaw ? FlowDistanceToPercent(flowDist) : mappedPct;

    PrintToConsole(client, "[3] Flow Check: %s | Flow: %.1f / %.1f (%d%%)%s",
        passFlow ? "PASS" : "FAIL (invalid flow)",
        flowDist, maxFlow, passFlow ? flowPercent : -1,
        (!passFlowRaw && passFlow) ? " [mapped]" : "");

    // 4. 距离
    float dminEye = GetMinEyeDistToAnySurvivor(testPos);
    float dminFeet = GetMinDistToAnySurvivor(testPos);
    bool passDist = (dminEye >= gCV.fSpawnMin && dminEye <= gCV.fSpawnMax);
    PrintToConsole(client, "[4] Distance Check: %s | Eye: %.1f | Feet: %.1f | Range: %.1f-%.1f",
        passDist ? "PASS" : "FAIL", dminEye, dminFeet, gCV.fSpawnMin, gCV.fSpawnMax);

    // 5. 位置关系
    int targetSur = ChooseTargetSurvivor();
    bool passPosition = PassRealPositionCheck(testPos, targetSur, view_as<int>(SI_Smoker));
    int candPercent = GetPositionBucketPercent(testPos);
    int surPercent = -1;
    if (IsValidSurvivor(targetSur)) TryGetClientFlowPercentSafe(targetSur, surPercent);
    int deltaReal = candPercent - surPercent;
    PrintToConsole(client, "[5] Position Check: %s | Cand: %d%% | Sur: %d%% | Delta: %d%%",
        passPosition ? "PASS" : "FAIL (behind/underfoot)", candPercent, surPercent, deltaReal);

    // 6. 分散度
    bool passSeparation = PassMinSeparation(testPos);
    PrintToConsole(client, "[6] Dispersion Check: %s | Min Sep: %s ",
        (passSeparation ) ? "PASS" : "FAIL",
        passSeparation ? "OK" : "FAIL");

    // 7. 卡壳
    bool passStuck = !WillStuck(testPos);
    PrintToConsole(client, "[7] Stuck Check: %s", passStuck ? "PASS" : "FAIL (will stuck)");

    // 8. 视线
    bool passVis = !IsPosVisibleSDK(testPos, false);
    PrintToConsole(client, "[8] Visibility Check: %s", passVis ? "PASS" : "FAIL (visible)");

    // 9. 路径
    float pathPenalty = PathPenalty_NoBuild(testPos, targetSur, gCV.fSpawnMax, gCV.fSpawnMax);
    bool passPath = (pathPenalty == 0.0);
    PrintToConsole(client, "[9] Path Check: %s | Penalty: %.1f", passPath ? "PASS" : "FAIL (no path)", pathPenalty);

    // === 评分演算 ===
    PrintToConsole(client, "");
    PrintToConsole(client, "--- Score Breakdown (as Smoker) ---");

    int zc = view_as<int>(SI_Smoker);
    float center[3]; GetSectorCenter(center, targetSur);
    int sectors = GetCurrentSectors();
    int preferredSector = PickSector(sectors);
    int sidx = ComputeSectorIndex(center, testPos, sectors);

    // 高度“偏好”分（独立正向项，不是扣分器）
    float refEyeZ = 0.0;
    if (IsValidSurvivor(targetSur) && IsPlayerAlive(targetSur))
    {
        float e[3]; GetClientEyePosition(targetSur, e);
        refEyeZ = e[2];
    }

    // 计算全队最高眼睛高度，用于 badflow 惩罚参考面
    float bestEyeZ = -1.0e9;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidSurvivor(i) && IsPlayerAlive(i))
        {
            float ez[3]; GetClientEyePosition(i, ez);
            if (ez[2] > bestEyeZ) bestEyeZ = ez[2];
        }
    }
    if (bestEyeZ <= -1.0e8) bestEyeZ = refEyeZ; // 兜底

    int centerBucket = surPercent;
    bool  rawBadFlow = (!passFlowRaw && passFlow);
    SpawnScoreDbg scoreDbg;
    bool passScoreEval = SpawnScore_BuildCandidate(zc, testPos, dminEye, gCV.fSpawnMax, 0.0,
                                                   candPercent, centerBucket, rawBadFlow,
                                                   refEyeZ, bestEyeZ, sidx, preferredSector,
                                                   index, scoreDbg);

    PrintToConsole(client, "  Distance Score: %.1f (sweet: %.1f, width: %.1f)",
        scoreDbg.dist, scoreDbg.sweet, scoreDbg.width);
    PrintToConsole(client, "  Height Score: %.1f (refZ: %.1f, candZ: %.1f, delta: %.1f)",
        scoreDbg.hght, refEyeZ, testPos[2], testPos[2] - refEyeZ);

    if (rawBadFlow)
    {
        PrintToConsole(client, "  Flow Score: base=%.1f, penalty=%.1f -> %.1f (delta: %d)%s",
            scoreDbg.flowBase, scoreDbg.flowPenalty, scoreDbg.flow, scoreDbg.deltaFlow, " [mapped]");
    }
    else
    {
        PrintToConsole(client, "  Flow Score: %.1f (delta: %d)", scoreDbg.flow, scoreDbg.deltaFlow);
    }

    PrintToConsole(client, "  Dispersion Score: %.1f -> %.1f (penK: %.2f, sector: %d/%d, pref: %d)",
        scoreDbg.dispRaw, scoreDbg.dispScaled, scoreDbg.penK, sidx, sectors, preferredSector);

    float totalScore = scoreDbg.total;
    PrintToConsole(client, "");
    PrintToConsole(client, "  TOTAL SCORE: %.1f", totalScore);
    if (!passScoreEval)
        PrintToConsole(client, "  SCORE FILTER: FAIL (raw badflow after height penalty)");
    PrintToConsole(client, "  (weights: dist=%.2f, hght=%.2f, flow=%.2f, disp=%.2f)",
        gCV.w_dist[zc], gCV.w_hght[zc], gCV.w_flow[zc], gCV.w_disp[zc]);

    PrintToConsole(client, "");
    bool canSpawn = passCooldown && passFlags && passFlow && passDist && passPosition
                 && passSeparation && passStuck && passVis && passPath && passScoreEval;
    PrintToConsole(client, "========================================");
    PrintToConsole(client, "=== RESULT: %s ===", canSpawn ? "CAN SPAWN" : "CANNOT SPAWN");
    PrintToConsole(client, "========================================");

    if (canSpawn)
        CPrintToChat(client, "%t", "InfectedControl_ICNavCanGenerateTotal", navid, totalScore);
    else
        CPrintToChat(client, "%t", "InfectedControl_ICNavCannotGenerateSee", navid);

    if (gCV.iDebugMode >= 3)
    {
        int color[4] = {255, 255, 255, 255};
        if (canSpawn) color = {0, 255, 0, 255};
        else          color = {255, 0, 0, 255};

        float beamEnd[3]; beamEnd = testPos; beamEnd[2] += 100.0;
        TE_SetupBeamPoints(testPos, beamEnd, 0, 0, 0, 5, 2.0, 5.0, 5.0, 0, 0.0, color, 0);
        TE_SendToClient(client);
    }

    return Plugin_Handled;
}

static int NavDebug_FindNavIndexByAddress(Address addr)
{
    if (addr == Address_Null) return -1;

    EnsureNavAreasCache();

    for (int i = 0; i < g_NavAreasCacheCount; i++)
    {
        if (g_AllNavAreasCache.Get(i) == addr)
            return i;
    }

    return -1;
}

// —— 将 SpawnAttributes 的位标记转成人类可读文本 ——
// 输出示例： "EMPTY|BATTLEFIELD|OBSCURED"
static void NavDebug_DescribeNavFlags(int f, char[] out, int maxlen)
{
    out[0] = '\0';
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_EMPTY,             "EMPTY");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_STOP_SCAN,         "STOP");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_BATTLESTATION,     "BATTLESTATION");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_FINALE,            "FINALE");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_PLAYER_START,      "PLAYER_START");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_BATTLEFIELD,       "BATTLEFIELD");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_IGNORE_VISIBILITY, "IGNORE_VIS");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_NOT_CLEARABLE,     "NOT_CLEARABLE");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_CHECKPOINT,        "CHECKPOINT");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_OBSCURED,          "OBSCURED");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_NO_MOBS,           "NO_MOBS");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_THREAT,            "THREAT");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_RESCUE_VEHICLE,    "RESCUE_VEH");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_RESCUE_CLOSET,     "RESCUE_CLOSET");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_ESCAPE_ROUTE,      "ESCAPE_ROUTE");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_DOOR,              "DOOR");
    NavDebug_AppendFlag(out, maxlen, f, TERROR_NAV_NOTHREAT,          "NOTHREAT");

    // 去掉可能多余的前导 '|'
    if (out[0] == '|' && out[1] == ' ') {
        strcopy(out, maxlen, out[2]);
    }
}

static void NavDebug_AppendFlag(char[] out, int maxlen, int f, int bit, const char[] name)
{
    if ((f & bit) == 0) return;
    if (out[0] != '\0') StrCat(out, maxlen, "|");
    StrCat(out, maxlen, name);
}

// —— Debug: 画一条一次性光束，帮助确认你指到哪 ——
// 需要已包含 <sdktools_tempents>
static void NavDebug_DrawAimLineOnce(int client, const float end[3])
{
    float start[3];
    GetClientEyePosition(client, start);
    TE_SetupBeamPoints(start, end, 0, 0, 0, 5, 0.7, 2.0, 2.0, 0, 0.0, {255,255,255,255}, 0);
    TE_SendToClient(client);
}

#else

public Action Cmd_NavPeek(int client, int args)
{
    ReplyToCommand(client, "[IC] Nav 调试命令未编译；需要时请用 DEBUG_NAV 重新编译。");
    return Plugin_Handled;
}

public Action Cmd_NavTest(int client, int args)
{
    ReplyToCommand(client, "[IC] Nav 调试命令未编译；需要时请用 DEBUG_NAV 重新编译。");
    return Plugin_Handled;
}

#endif
