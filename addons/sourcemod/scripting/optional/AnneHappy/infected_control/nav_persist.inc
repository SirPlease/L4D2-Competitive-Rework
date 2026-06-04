#if defined _infected_control_nav_persist_included
    #endinput
#endif
#define _infected_control_nav_persist_included

// Nav 分桶磁盘缓存读写。
static void MakeBucketCachePath()
{
    char map[64];
    GetCurrentMap(map, sizeof map);

    char dir[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, dir, sizeof dir, "data/infd_buckets");
    CreateDirectory(dir, 511);
    BuildPath(Path_SM, g_sBucketCachePath, sizeof g_sBucketCachePath, "data/infd_buckets/%s.kv", map);
}

bool TryLoadBucketsFromCache()
{
    if (!gCV.bNavCacheEnable) return false;

    MakeBucketCachePath();
    if (!FileExists(g_sBucketCachePath)) return false;

    KeyValues kv = new KeyValues("BucketsCache");
    if (!kv.ImportFromFile(g_sBucketCachePath))
    {
        delete kv;
        return false;
    }

    kv.Rewind();
    char ver[64];
    kv.GetString("version", ver, sizeof ver, "");
    if (!StrEqual(ver, BUCKET_CACHE_VER))
    {
        delete kv;
        return false;
    }

    char map[64], currentMap[64];
    GetCurrentMap(currentMap, sizeof currentMap);
    kv.GetString("map", map, sizeof map, "");
    if (!StrEqual(map, currentMap))
    {
        delete kv;
        return false;
    }

    EnsureNavAreasCache();
    int currentAreaCount = g_NavAreasCacheCount;

    int areaCount = kv.GetNum("area_count", -1);
    if (areaCount <= 0 || areaCount != currentAreaCount)
    {
        delete kv;
        return false;
    }

    float maxFlowCur = L4D2Direct_GetMapMaxFlowDistance();
    float maxFlowCached = kv.GetFloat("max_flow", -1.0);
    if (FloatAbs(maxFlowCached - maxFlowCur) > 0.1)
    {
        delete kv;
        return false;
    }

    float bufferCur = gCV.VsBossFlowBuffer.FloatValue;
    float bufferCached = kv.GetFloat("vsboss_buffer", 0.0);
    int mapInvalidCur = gCV.bNavBucketMapInvalid ? 1 : 0;
    int mapInvalidCached = kv.GetNum("map_invalid", 1);
    float assignRadiusCur = gCV.fNavBucketAssignRadius;
    float assignRadiusCached = kv.GetFloat("assign_radius", 0.0);

    if (FloatAbs(bufferCur - bufferCached) > 0.01 || mapInvalidCur != mapInvalidCached ||
        FloatAbs(assignRadiusCur - assignRadiusCached) > 0.5)
    {
        delete kv;
        return false;
    }

    ClearNavBuckets();
    BuildNavIdIndexMap();

    g_AreaZCore = new ArrayList();
    g_AreaZMin  = new ArrayList();
    g_AreaZMax  = new ArrayList();
    g_AreaCX    = new ArrayList();
    g_AreaCY    = new ArrayList();
    g_AreaPct   = new ArrayList();

    for (int i = 0; i < areaCount; i++)
    {
        g_AreaZCore.Push(0.0);
        g_AreaZMin.Push(0.0);
        g_AreaZMax.Push(0.0);
        g_AreaCX.Push(0.0);
        g_AreaCY.Push(0.0);
        g_AreaPct.Push(-1);
    }

    for (int bucketIdx = 0; bucketIdx < FLOW_BUCKETS; bucketIdx++)
    {
        g_BucketMinZ[bucketIdx] = 1.0e9;
        g_BucketMaxZ[bucketIdx] = -1.0e9;
    }

    if (kv.JumpToKey("bucket_zrange", false))
    {
        for (int bucketIdx = 0; bucketIdx <= 100; bucketIdx++)
        {
            char key[8];
            IntToString(bucketIdx, key, sizeof key);
            if (kv.JumpToKey(key, false))
            {
                g_BucketMinZ[bucketIdx] = kv.GetFloat("min", 0.0);
                g_BucketMaxZ[bucketIdx] = kv.GetFloat("max", 0.0);
                kv.GoBack();
            }
        }
        kv.GoBack();
    }

    if (!kv.JumpToKey("areas", false))
    {
        delete kv;
        return false;
    }

    if (kv.GotoFirstSubKey(false))
    {
        do {
            char navKey[16];
            kv.GetSectionName(navKey, sizeof navKey);
            int navid = StringToInt(navKey);
            int areaIdx = GetAreaIndexByNavID_Int(navid);
            if (areaIdx < 0) continue;

            int bucketIdx = kv.GetNum("bucket", -1);
            if (bucketIdx < 0 || bucketIdx > 100) continue;

            g_AreaCX.Set(areaIdx, kv.GetFloat("cx", 0.0));
            g_AreaCY.Set(areaIdx, kv.GetFloat("cy", 0.0));
            g_AreaZCore.Set(areaIdx, kv.GetFloat("zCore", 0.0));

            float zMin = kv.GetFloat("zMin", 0.0);
            float zMax = kv.GetFloat("zMax", 0.0);
            g_AreaZMin.Set(areaIdx, zMin);
            g_AreaZMax.Set(areaIdx, zMax);
            g_AreaPct.Set(areaIdx, bucketIdx);

            if (g_FlowBuckets[bucketIdx] == null)
                g_FlowBuckets[bucketIdx] = new ArrayList();
            g_FlowBuckets[bucketIdx].Push(areaIdx);

            // 冗余保护：确保桶高度范围即使 bucket_zrange 缺失也能正确构建
            if (zMin < g_BucketMinZ[bucketIdx]) g_BucketMinZ[bucketIdx] = zMin;
            if (zMax > g_BucketMaxZ[bucketIdx]) g_BucketMaxZ[bucketIdx] = zMax;

        } while (kv.GotoNextKey(false));
        kv.GoBack();
    }

    delete kv;
    g_BucketsReady = true;
    Debug_Print("[BUCKET] loaded from cache: %s", g_sBucketCachePath);
    return true;
}

void SaveBucketsToCache()
{
    if (!gCV.bNavCacheEnable || !g_BucketsReady) return;

    MakeBucketCachePath();

    KeyValues kv = new KeyValues("BucketsCache");
    kv.SetString("version", BUCKET_CACHE_VER);

    char map[64];
    GetCurrentMap(map, sizeof map);
    kv.SetString("map", map);

    EnsureNavAreasCache();
    int areaCount = g_NavAreasCacheCount;

    kv.SetNum("area_count", areaCount);
    kv.SetFloat("max_flow", L4D2Direct_GetMapMaxFlowDistance());
    kv.SetFloat("vsboss_buffer", gCV.VsBossFlowBuffer.FloatValue);
    kv.SetNum("map_invalid", gCV.bNavBucketMapInvalid ? 1 : 0);
    kv.SetFloat("assign_radius", gCV.fNavBucketAssignRadius);

    kv.JumpToKey("bucket_zrange", true);
    for (int bucketIdx = 0; bucketIdx <= 100; bucketIdx++)
    {
        char key[8];
        IntToString(bucketIdx, key, sizeof key);
        kv.JumpToKey(key, true);
        kv.SetFloat("min", g_BucketMinZ[bucketIdx]);
        kv.SetFloat("max", g_BucketMaxZ[bucketIdx]);
        kv.GoBack();
    }
    kv.GoBack();

    kv.JumpToKey("areas", true);
    for (int areaIdx = 0; areaIdx < areaCount; areaIdx++)
    {
        int navid = GetNavIDByIndex(areaIdx);
        if (navid < 0) continue;

        int bucketIdx = view_as<int>(g_AreaPct.Get(areaIdx));
        if (bucketIdx < 0 || bucketIdx > 100) continue;

        char navKey[16];
        IntToString(navid, navKey, sizeof navKey);
        kv.JumpToKey(navKey, true);

        kv.SetNum("bucket", bucketIdx);
        kv.SetFloat("cx", view_as<float>(g_AreaCX.Get(areaIdx)));
        kv.SetFloat("cy", view_as<float>(g_AreaCY.Get(areaIdx)));
        kv.SetFloat("zCore", view_as<float>(g_AreaZCore.Get(areaIdx)));
        kv.SetFloat("zMin", view_as<float>(g_AreaZMin.Get(areaIdx)));
        kv.SetFloat("zMax", view_as<float>(g_AreaZMax.Get(areaIdx)));

        kv.GoBack();
    }
    kv.GoBack();

    kv.ExportToFile(g_sBucketCachePath);
    delete kv;
    Debug_Print("[BUCKET] saved to cache: %s", g_sBucketCachePath);
}

