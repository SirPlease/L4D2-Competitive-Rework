#if defined _infected_control_nav_types_included
    #endinput
#endif
#define _infected_control_nav_types_included

// =========================
// NavArea wrappers
// =========================
methodmap TheNavAreas
{
    public int Count()
    {
        EnsureNavAreasCache();
        return g_NavAreasCacheCount;
    }

    public Address GetAreaByIndex(int i)
    {
        EnsureNavAreasCache();
        if (i < 0 || i >= g_NavAreasCacheCount)
            return Address_Null;
        return g_AllNavAreasCache.Get(i);
    }
}

methodmap NavArea
{
    public bool IsNull()
    {
        return view_as<Address>(this) == Address_Null;
    }

    public void GetRandomPoint(float outPos[3])
    {
        L4D_FindRandomSpot(view_as<int>(this), outPos);
    }

    property int SpawnAttributes
    {
        public get()
        {
            return L4D_GetNavArea_SpawnAttributes(view_as<Address>(this));
        }
        public set(int v)
        {
            L4D_SetNavArea_SpawnAttributes(view_as<Address>(this), v);
        }
    }

    public float GetFlow()
    {
        return L4D2Direct_GetTerrorNavAreaFlow(view_as<Address>(this));
    }
}

// Nav flags（参考 wiki / fdxx）
enum
{
    TERROR_NAV_EMPTY                = 1 << 1,
    TERROR_NAV_STOP_SCAN            = 1 << 2,
    TERROR_NAV_BATTLESTATION        = 1 << 5,
    TERROR_NAV_FINALE               = 1 << 6,
    TERROR_NAV_PLAYER_START         = 1 << 7,
    TERROR_NAV_BATTLEFIELD          = 1 << 8,
    TERROR_NAV_IGNORE_VISIBILITY    = 1 << 9,
    TERROR_NAV_NOT_CLEARABLE        = 1 << 10,
    TERROR_NAV_CHECKPOINT           = 1 << 11,
    TERROR_NAV_OBSCURED             = 1 << 12,
    TERROR_NAV_NO_MOBS              = 1 << 13,
    TERROR_NAV_THREAT               = 1 << 14,
    TERROR_NAV_RESCUE_VEHICLE       = 1 << 15,
    TERROR_NAV_RESCUE_CLOSET        = 1 << 16,
    TERROR_NAV_ESCAPE_ROUTE         = 1 << 17,
    TERROR_NAV_DOOR                 = 1 << 18,
    TERROR_NAV_NOTHREAT             = 1 << 19
}
