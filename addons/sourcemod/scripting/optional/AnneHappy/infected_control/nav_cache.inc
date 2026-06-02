#if defined _infected_control_nav_cache_included
    #endinput
#endif
#define _infected_control_nav_cache_included

// NavArea 缓存与 NavID 索引。
stock void EnsureNavAreasCache()
{
    if (g_AllNavAreasCache == null)
    {
        g_AllNavAreasCache = new ArrayList();
        L4D_GetAllNavAreas(g_AllNavAreasCache);
        g_NavAreasCacheCount = g_AllNavAreasCache.Length;
        Debug_Print("[NAV CACHE] Initialized: %d areas", g_NavAreasCacheCount);
    }
}

stock void ClearNavAreasCache()
{
    if (g_AllNavAreasCache != null)
    {
        delete g_AllNavAreasCache;
        g_AllNavAreasCache = null;
        g_NavAreasCacheCount = 0;
        Debug_Print("[NAV CACHE] Cleared");
    }
}

stock void RebuildNavAreasCache()
{
    ClearNavAreasCache();
    EnsureNavAreasCache();
}

void BuildNavIdIndexMap()
{
    if (g_NavIdToIndex != null)
    {
        delete g_NavIdToIndex;
        g_NavIdToIndex = null;
    }
    g_NavIdToIndex = new StringMap();

    EnsureNavAreasCache();

    for (int i = 0; i < g_NavAreasCacheCount; i++)
    {
        Address area = g_AllNavAreasCache.Get(i);
        int navid = L4D_GetNavAreaID(area);
        if (navid < 0)
            continue;

        char key[16];
        IntToString(navid, key, sizeof key);
        g_NavIdToIndex.SetValue(key, view_as<any>(i));
    }
}

int GetAreaIndexByNavID_Int(int navid)
{
    if (g_NavIdToIndex == null)
        BuildNavIdIndexMap();

    char key[16];
    IntToString(navid, key, sizeof key);

    any idx;
    return g_NavIdToIndex.GetValue(key, idx) ? view_as<int>(idx) : -1;
}

// 采样 NavArea 的几何中心近似和高度范围。
void SampleAreaCenterAndZ(Address areaAddr, float &cx, float &cy, float &zAvg, float &zMin, float &zMax, int samples = 3)
{
    cx = 0.0;
    cy = 0.0;
    zAvg = 0.0;
    zMin = 1.0e9;
    zMax = -1.0e9;

    if (areaAddr == Address_Null || samples <= 0)
    {
        zMin = 0.0;
        zMax = 0.0;
        zAvg = 0.0;
        return;
    }

    NavArea area = view_as<NavArea>(areaAddr);
    float pos[3];

    for (int i = 0; i < samples; i++)
    {
        area.GetRandomPoint(pos);
        cx += pos[0];
        cy += pos[1];
        zAvg += pos[2];
        if (pos[2] < zMin) zMin = pos[2];
        if (pos[2] > zMax) zMax = pos[2];
    }

    float inv = 1.0 / float(samples);
    cx *= inv;
    cy *= inv;
    zAvg *= inv;
}

