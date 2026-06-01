#if defined _infected_control_nav_buckets_included
    #endinput
#endif
#define _infected_control_nav_buckets_included

// =========================
// Nav Flow 分桶：构建 / 清理 / 计时器回调
// =========================
void ClearNavBuckets()
{
    for (int i = 0; i < FLOW_BUCKETS; i++)
    {
        if (g_FlowBuckets[i] != null) { delete g_FlowBuckets[i]; g_FlowBuckets[i] = null; }
        g_BucketMinZ[i] = 0.0;
        g_BucketMaxZ[i] = 0.0;
    }

    if (g_AreaZCore != null) { delete g_AreaZCore; g_AreaZCore = null; }
    if (g_AreaZMin  != null) { delete g_AreaZMin;  g_AreaZMin  = null; }
    if (g_AreaZMax  != null) { delete g_AreaZMax;  g_AreaZMax  = null; }
    if (g_AreaCX  != null) { delete g_AreaCX;  g_AreaCX  = null; }
    if (g_AreaCY  != null) { delete g_AreaCY;  g_AreaCY  = null; }
    if (g_AreaPct != null) { delete g_AreaPct; g_AreaPct = null; }
}

int ComputeDynamicBucketWindow(float ring)
{
    // 如果没启用动态联动，直接返回静态窗口
    if (!gCV.bNavBucketLinkToRing)
        return gCV.iNavBucketWindow;

    float a = gCV.fNavBucketMinAt;
    float b = gCV.fNavBucketMaxAt;
    int   w0 = gCV.iNavBucketWindowMin;
    int   w1 = gCV.iNavBucketWindowMax;

    if (b < a) { float t=a; a=b; b=t; } // 容错：交换

    float t;
    if (ring <= a)       t = 0.0;
    else if (ring >= b)  t = 1.0;
    else                 t = (ring - a) / (b - a);

    // 线性插值并四舍五入
    float w = float(w0) + (float(w1) - float(w0)) * t;
    int   win = RoundToNearest(w);

    if (win < 0)   win = 0;
    if (win > 100) win = 100;
    return win;
}

/**
 * 生成“扫描桶顺序”（中心 s 起，前2后1推进；若前>后累计差>4，则两侧批量+1）
 * 例如：s, s+1, s+2, s-1, s+3, s+4, s-2, s+5, s+6, s-3, ...
 * @param s             中心桶（0..100）
 * @param win           窗口半径（±win）
 * @param includeCenter 是否把中心桶也加入序列
 * @param outBuckets    输出序列（长度上限 FLOW_BUCKETS）
 * @return              实际写入数量
 */
int BuildBucketOrder(int s, int win, bool includeCenter, int outBuckets[FLOW_BUCKETS])
{
    s   = ClampInt(s,   0, 100);
    win = ClampInt(win, 0, 100);

    int n = 0;
    if (includeCenter)
        outBuckets[n++] = s;

    int fdist = 1;   // 向前偏移距离（s+fdist）
    int bdist = 1;   // 向后偏移距离（s-bdist）

    int fwdRun  = 2; // 每轮先推“前”多少个
    int backRun = 1; // 然后推“后”多少个

    int addedF = 0;  // 实际加入的前/后桶累计（考虑越界后可能没加上）
    int addedB = 0;

    while ((fdist <= win || bdist <= win) && n < FLOW_BUCKETS)
    {
        // 前 fwdRun
        int pushedF = 0;
        for (int k = 0; k < fwdRun && fdist <= win && n < FLOW_BUCKETS; k++, fdist++)
        {
            int b = s + fdist;
            if (b <= 100) { outBuckets[n++] = b; pushedF++; }
        }
        addedF += pushedF;

        // 后 backRun
        int pushedB = 0;
        for (int k = 0; k < backRun && bdist <= win && n < FLOW_BUCKETS; k++, bdist++)
        {
            int a = s - bdist;
            if (a >= 0) { outBuckets[n++] = a; pushedB++; }
        }
        addedB += pushedB;

        // 不平衡修正：前比后“实际加入”多 > 4，则两侧批量都+1
        if ((addedF - addedB) > 4)
        {
            fwdRun++;
            backRun++;
        }
    }
    return n;
}

void BuildNavBuckets()
{
    // 1) 尝试读缓存（成功就直接返回）
    if (TryLoadBucketsFromCache())
        return;

    // 2) 清理旧数据、准备索引与缓存
    ClearNavBuckets();
    BuildNavIdIndexMap();
    EnsureNavAreasCache();

    int iAreaCount = g_NavAreasCacheCount;
    float fMapMaxFlowDist = L4D2Direct_GetMapMaxFlowDistance();
    bool  bFinaleArea     = L4D_IsMissionFinalMap() && L4D2_GetCurrentFinaleStage() < FINALE_STAGE_ESCAPE;

    float t0 = GetEngineTime();
    Debug_Print("[BUCKET] begin build: areas=%d", iAreaCount);

    // 3) 初始化 per-area / per-bucket 容器
    g_AreaZCore = new ArrayList();
    g_AreaZMin  = new ArrayList();
    g_AreaZMax  = new ArrayList();
    g_AreaCX    = new ArrayList();
    g_AreaCY    = new ArrayList();
    g_AreaPct   = new ArrayList();

    for (int i = 0; i < iAreaCount; i++)
    {
        g_AreaZCore.Push(0.0);
        g_AreaZMin.Push(0.0);
        g_AreaZMax.Push(0.0);
        g_AreaCX.Push(0.0);
        g_AreaCY.Push(0.0);
        g_AreaPct.Push(-1); // -1 = 未归桶/坏flow
    }

    for (int b = 0; b < FLOW_BUCKETS; b++)
    {
        g_FlowBuckets[b] = null;
        g_BucketMinZ[b]  =  1.0e9;
        g_BucketMaxZ[b]  = -1.0e9;
    }

    ArrayList badIdxs   = new ArrayList();
    ArrayList validIdxs = new ArrayList();

    int addedValid = 0, addedBad = 0, skippedFlag = 0;

    // 4) 第一遍：采样中心/高度，正常 flow 直接入桶
    for (int i = 0; i < iAreaCount; i++)
    {
        Address areaAddr = g_AllNavAreasCache.Get(i);
        if (areaAddr == Address_Null) continue;

        NavArea pArea = view_as<NavArea>(areaAddr);

        // 过滤不合规的 Nav flags（救援/安全屋等）
        if (!IsValidFlags(pArea.SpawnAttributes, bFinaleArea))
        {
            skippedFlag++;
            continue;
        }

        // 采样中心与高度统计（最多 3 次）
        float cx, cy, zAvg, zMin, zMax;
        SampleAreaCenterAndZ(areaAddr, cx, cy, zAvg, zMin, zMax, 3);
        g_AreaCX.Set(i, cx);
        g_AreaCY.Set(i, cy);
        g_AreaZCore.Set(i, zAvg);
        g_AreaZMin.Set(i,  zMin);
        g_AreaZMax.Set(i,  zMax);

        // 原始 flow 到百分比（无效则进坏列表）
        float fFlow = pArea.GetFlow();
        bool  flowOK = (fFlow >= 0.0 && fFlow <= fMapMaxFlowDist);

        if (flowOK)
        {
            int percent = FlowDistanceToPercent(fFlow);
            if (percent < 0)   percent = 0;
            if (percent > 100) percent = 100;

            if (g_FlowBuckets[percent] == null)
                g_FlowBuckets[percent] = new ArrayList();
            g_FlowBuckets[percent].Push(i);

            if (zMin < g_BucketMinZ[percent]) g_BucketMinZ[percent] = zMin;
            if (zMax > g_BucketMaxZ[percent]) g_BucketMaxZ[percent] = zMax;

            g_AreaPct.Set(i, percent);
            validIdxs.Push(i);
            addedValid++;
        }
        else
        {
            badIdxs.Push(i);
            addedBad++;
        }
    }

    Debug_Print("[BUCKET] pass1 done: valid=%d bad=%d skipped=%d took=%.3fs",
        addedValid, addedBad, skippedFlag, GetEngineTime() - t0);

    // 5) 第二遍：把坏 flow 的区域映射到最近“有效桶”（二维栅格 + 成本/时间保护）
    if (gCV.bNavBucketMapInvalid && validIdxs.Length > 0 && badIdxs.Length > 0)
    {
        // 5.1 估算成本与时间预算
        int B = badIdxs.Length, V = validIdxs.Length;
        float estCostM = float(B) * float(V) / 1.0e6;
        const float hardCostM   = 5.0;  // ≈500万配对：超过则跳过映射
        const float timeBudgetS = 0.60; // 总时间预算：>0.6s 就中止映射

        float t1 = GetEngineTime();
        if (estCostM > hardCostM)
        {
            Debug_Print("[BUCKET] pass2 SKIP(cost): B=%d V=%d est≈%.1fM", B, V, estCostM);
        }
        else
        {
            // 5.2 构建“有效区”二维栅格
            const float cell = 2000.0; // 栅格边长（可按地图尺度调整）
            float radius = gCV.fNavBucketAssignRadius; // 0=不限
            if (radius < 0.0) radius = 0.0;

            StringMap cellMap = new StringMap();
            ArrayList ownedLists = new ArrayList(); // 收尾 delete

            for (int i = 0; i < V; i++)
            {
                int vidx = validIdxs.Get(i);
                float vx = view_as<float>(g_AreaCX.Get(vidx));
                float vy = view_as<float>(g_AreaCY.Get(vidx));
                int   cx = RoundToFloor(vx / cell);
                int   cy = RoundToFloor(vy / cell);

                char key[32];
                Format(key, sizeof key, "%d,%d", cx, cy);

                any h;
                ArrayList lst;
                if (!cellMap.GetValue(key, h))
                {
                    lst = new ArrayList();
                    ownedLists.Push(lst);
                    cellMap.SetValue(key, view_as<any>(lst));
                }
                else
                {
                    lst = view_as<ArrayList>(h);
                }
                lst.Push(vidx);
            }

            // 5.3 邻格扩环检索参数
            int   maxLayer = (radius > 0.1) ? RoundToCeil(radius / cell) : 6;
            if (maxLayer < 0)  maxLayer = 0;
            if (maxLayer > 48) maxLayer = 48;
            float r2 = (radius > 0.1) ? (radius * radius) : -1.0;

            int mapped = 0, dropped = 0;
            bool aborted = false;

            // 5.4 对每个坏区做邻格扩环搜索
            for (int bi = 0; bi < B; bi++)
            {
                // 时间预算：每 1024 个检查一次
                if ((bi & 1023) == 0)
                {
                    float el = GetEngineTime() - t1;
                    if (el > timeBudgetS)
                    {
                        Debug_Print("[BUCKET] pass2 ABORT(time): bi=%d/%d mapped=%d dropped=%d el=%.3fs",
                                    bi, B, mapped, dropped, el);
                        aborted = true;
                        break;
                    }
                }

                int aidx = badIdxs.Get(bi);
                float ax = view_as<float>(g_AreaCX.Get(aidx));
                float ay = view_as<float>(g_AreaCY.Get(aidx));
                int   acx = RoundToFloor(ax / cell);
                int   acy = RoundToFloor(ay / cell);

                float bestD2 = 1.0e20;
                int   bestV  = -1;

                // 扩环：layer=0..maxLayer（只扫 ring 外框，避免 O(layer^2)）
                for (int layer = 0; layer <= maxLayer; layer++)
                {
                    bool foundThisRing = false;
                    int minX = acx - layer, maxX = acx + layer;
                    int minY = acy - layer, maxY = acy + layer;

                    for (int cy = minY; cy <= maxY; cy++)
                    {
                        for (int cx = minX; cx <= maxX; cx++)
                        {
                            bool onEdge = (cx == minX || cx == maxX || cy == minY || cy == maxY);
                            if (!onEdge) continue;

                            char key[32];
                            Format(key, sizeof key, "%d,%d", cx, cy);

                            any h;
                            if (!cellMap.GetValue(key, h)) continue;
                            ArrayList lst = view_as<ArrayList>(h);

                            for (int k = 0; k < lst.Length; k++)
                            {
                                int vidx = lst.Get(k);
                                float vx = view_as<float>(g_AreaCX.Get(vidx));
                                float vy = view_as<float>(g_AreaCY.Get(vidx));
                                float dx = ax - vx, dy = ay - vy;
                                float d2 = dx*dx + dy*dy;

                                if (r2 > 0.0 && d2 > r2) continue;
                                if (d2 < bestD2)
                                {
                                    bestD2 = d2;
                                    bestV  = vidx;
                                    foundThisRing = true;
                                }
                            }
                        }
                    }

                    if (foundThisRing)
                        break;
                }

                if (bestV != -1)
                {
                    int percent = view_as<int>(g_AreaPct.Get(bestV));
                    if (percent < 0)   percent = 0;
                    if (percent > 100) percent = 100;

                    if (g_FlowBuckets[percent] == null)
                        g_FlowBuckets[percent] = new ArrayList();
                    g_FlowBuckets[percent].Push(aidx);

                    float zmin = view_as<float>(g_AreaZMin.Get(aidx));
                    float zmax = view_as<float>(g_AreaZMax.Get(aidx));
                    if (zmin < g_BucketMinZ[percent]) g_BucketMinZ[percent] = zmin;
                    if (zmax > g_BucketMaxZ[percent]) g_BucketMaxZ[percent] = zmax;

                    g_AreaPct.Set(aidx, percent);
                    mapped++;
                }
                else
                {
                    dropped++;
                }

                if ((bi % 2048) == 0)
                    Debug_Print("[BUCKET] pass2 prog: %d/%d mapped=%d dropped=%d", bi, B, mapped, dropped);
            }

            Debug_Print("[BUCKET] pass2 %s: B=%d V=%d mapped=%d dropped=%d took=%.3fs",
                aborted ? "done(partial)" : "done",
                B, V, mapped, dropped, GetEngineTime() - t1);

            // 5.5 释放 cellMap 内存
            for (int i = 0; i < ownedLists.Length; i++)
            {
                ArrayList lst = ownedLists.Get(i);
                if (lst != null) delete lst;
            }
            delete ownedLists;
            delete cellMap;
        }
    }
    else
    {
        Debug_Print("[BUCKET] pass2 skip: mapInvalid=%d valid=%d bad=%d",
            gCV.bNavBucketMapInvalid ? 1 : 0, validIdxs.Length, badIdxs.Length);
    }

    // 6) 完成：标记就绪 & 存缓存
    g_BucketsReady = true;
    Debug_Print("[BUCKET] build done: took=%.3fs", GetEngineTime() - t0);

    SaveBucketsToCache(); // 若启用缓存将写入 .kv（你已有实现）
}

// 重建 Buckets 时确保缓存新鲜。
Action Timer_RebuildBuckets(Handle timer)
{
    // 如果本局本图已经有可用缓存，就别动了
    if (g_BucketsReady && g_AllNavAreasCache != null && g_NavAreasCacheCount > 0)
    {
        // Debug_Print("[NAV CACHE] Skip rebuild (already warm)");
        return Plugin_Stop;
    }

    // 只在“没有缓存”时，补齐一次（不会触发 Cleared 日志）
    EnsureNavAreasCache();   // 仅确保存在，不清空
    BuildNavBuckets();       // 内部会 TryLoadBucketsFromCache()
    return Plugin_Stop;
}

void RebuildNavBuckets()
{
    BuildNavBuckets();
}
