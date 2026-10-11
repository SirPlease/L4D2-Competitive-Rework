#if defined __item_tracking_included
    #endinput
#endif
#define __item_tracking_included

#define IT_MODULE_NAME			"ItemTracking"

#define PF_KEEP        0
#define PF_CULL_WINDOW 1
#define PF_CULL_SEP    2
#define PF_CULL_LIMIT  3
#define PF_NO_FLOW     -1   // no nav/flow data: always kept, excluded from spacing

static int PF_GLOW_KEEP[3] = {255, 255, 255};   // white
static int PF_GLOW_CULL[4][3] = {
    {0, 0, 0},          // PF_KEEP (unused)
    {255, 0, 0},        // PF_CULL_WINDOW: red
    {255, 165, 0},      // PF_CULL_SEP: orange
    {0, 255, 255}       // PF_CULL_LIMIT: cyan
};

// Item lists for tracking/decoding/etc
enum /*ItemList*/
{
    IL_PainPills,
    IL_Adrenaline,
    // Not sure we need these.
    //IL_FirstAid,
    //IL_Defib,
    IL_PipeBomb,
    IL_Molotov,
    IL_VomitJar,

    ItemList_Size
};

// Names for cvars, kv, descriptions
// [ItemIndex][shortname = 0, fullname = 1, spawnname = 2]
enum /*ItemNames*/
{
    IN_shortname,
    IN_longname,
    IN_officialname,
    IN_modelname,

    ItemNames_Size
};

// Settings for item limiting.
/*enum ItemLimitSettings
{
    Handle:cvar,
    limitnum
};*/

// For spawn entires adt_array
enum struct ItemTracking
{
    int IT_entity;
    float IT_origins;
    float IT_origins1;
    float IT_origins2;
    float IT_angles;
    float IT_angles1;
    float IT_angles2;
}

static const char g_sItemNames[ItemList_Size][ItemNames_Size][] =
{
    {
        "pills",
        "pain pills",
        "pain_pills",
        "painpills"
    },
    {
        "adrenaline",
        "adrenaline shots",
        "adrenaline",
        "adrenaline"
    },
    /*{
        "kits",
        "first aid kits",
        "first_aid_kit",
        "medkit"
    },
    {
        "defib",
        "defibrillators",
        "defibrillator",
        "defibrillator"
    },*/
    {
        "pipebomb",
        "pipe bombs",
        "pipe_bomb",
        "pipebomb"
    },
    {
        "molotov",
        "molotovs",
        "molotov",
        "molotov"
    },
    {
        "vomitjar",
        "bile bombs",
        "vomitjar",
        "bile_flask"
    }
};

static int
    g_iItemLimits[ItemList_Size] = {0, ...}, // Current item limits array
    g_iSaferoomCount[2] = {0, ...};

static bool
    g_bIsRound1Over = false; // Is round 1 over?

static ConVar
    g_hCvarEnabled = null,
    g_hSurvivorLimit = null,
    g_hCvarConsistentSpawns = null,
    g_hCvarMapSpecificSpawns = null,
    g_hCvarIgnorePlayerItems = null,
    g_hCvarPillFlowMin = null,
    g_hCvarPillFlowMax = null,
    g_hCvarPillFlowSeparation = null,
    g_hCvarPillFlowFinale = null,
    g_hCvarPillFlowVisualize = null,
    g_hCvarLimits[ItemList_Size] = {null, ...}; // CVAR Handle Array for item limits

static bool
    g_bPillLimitHandled = false; // Pill flow filter ran and owns the pills limit this round

static ArrayList
    g_hItemSpawns[ItemList_Size] = {null, ...}; // ADT Array Handle for actual item spawns

static StringMap
    g_hItemListTrie = null;

void IT_OnModuleStart()
{
    g_hCvarEnabled = CreateConVarEx("enable_itemtracking", "0", "Enable the itemtracking module", _, true, 0.0, true, 1.0);
    g_hCvarConsistentSpawns = CreateConVarEx("itemtracking_savespawns", "0", "Keep item spawns the same on both rounds", _, true, 0.0, true, 1.0);
    g_hCvarMapSpecificSpawns = CreateConVarEx("itemtracking_mapspecific", "0", "Change how mapinfo.txt overrides work. 0 = ignore mapinfo.txt, 1 = allow limit reduction, 2 = allow limit increases.", _, true, 0.0, true, 3.0);
    g_hCvarIgnorePlayerItems = CreateConVarEx("itemtracking_playeritems", "0", "Ignore items that players spawn with. 0 = Nope, 1 = Yes. (Non-issue in versus modes)", _, true, 0.0, true, 1.0);

    // Pill flow window. Per-map override keys in mapinfo.txt (map section):
    // "pillflow_min", "pillflow_max", "pillflow_separation" (floats, same meaning as the cvars).
    g_hCvarPillFlowMin = CreateConVarEx("pills_flow_min", "0", "Minimum map flow fraction (0.0-1.0) where pain pills may spawn. Pills earlier than this are removed. 0 with max 1 and separation 0 = flow filter off.", _, true, 0.0, true, 1.0);
    g_hCvarPillFlowMax = CreateConVarEx("pills_flow_max", "1", "Maximum map flow fraction (0.0-1.0) where pain pills may spawn. Pills later than this are removed.", _, true, 0.0, true, 1.0);
    g_hCvarPillFlowSeparation = CreateConVarEx("pills_flow_separation", "0", "Minimum flow-fraction gap between two kept pill spawns (0.05 = 5% of map flow). Of a too-close pair the earlier spawn wins. 0 = no separation enforced.", _, true, 0.0, true, 1.0);
    g_hCvarPillFlowFinale = CreateConVarEx("pills_flow_finale", "0", "Apply the pill flow window on finale maps. 0 = finales exempt.", _, true, 0.0, true, 1.0);
    g_hCvarPillFlowVisualize = CreateConVarEx("pills_flow_visualize", "0", "Debug: 1 = don't remove pills, glow instead: white = kept, red = outside flow window, orange = too close to previous pill, cyan = over the pills limit. 2 = remove as normal, then glow the surviving pills white.", _, true, 0.0, true, 2.0);

    char sNameBuf[64], sCvarDescBuf[256];
    // Create itemlimit cvars
    for (int i = 0; i < ItemList_Size; i++) {
        FormatEx(sNameBuf, sizeof(sNameBuf), "%s_limit", g_sItemNames[i][IN_shortname]);
        FormatEx(sCvarDescBuf, sizeof(sCvarDescBuf), "Limits the number of %s on each map. -1: no limit; >=0: limit to cvar value", g_sItemNames[i][IN_longname]);

        g_hCvarLimits[i] = CreateConVarEx(sNameBuf, "-1", sCvarDescBuf);
    }

    // Create name translation trie
    CreateItemListTrie();

    // Create item spawns array;
    ItemTracking curitem;

    for (int i = 0; i < ItemList_Size; i++) {
        g_hItemSpawns[i] = new ArrayList(sizeof(curitem));
    }

    HookEvent("round_start", _IT_RoundStartEvent, EventHookMode_PostNoCopy);
    HookEvent("round_end", _IT_RoundEndEvent, EventHookMode_PostNoCopy);

    g_hSurvivorLimit = FindConVar("survivor_limit");
}

void IT_OnMapStart()
{
    for (int i = 0; i < ItemList_Size; i++) {
        g_iItemLimits[i] = g_hCvarLimits[i].IntValue;
    }

    int iCvarValue = g_hCvarMapSpecificSpawns.IntValue;
    if (iCvarValue) {
        int itemlimit = 0, temp = 0;
        KeyValues kOverrideLimits = new KeyValues("ItemLimits");
        CopyMapSubsection(kOverrideLimits, "ItemLimits");

        for (int i = 0; i < ItemList_Size; i++) {
            itemlimit = g_hCvarLimits[i].IntValue;

            temp = kOverrideLimits.GetNum(g_sItemNames[i][IN_officialname], itemlimit);

            if (((g_iItemLimits[i] > temp) && (iCvarValue & 1)) || ((g_iItemLimits[i] < temp) && (iCvarValue & 2))) {
                g_iItemLimits[i] = temp;
            }

            g_hItemSpawns[i].Clear();
        }

        delete kOverrideLimits;
    }

    g_bIsRound1Over = false;
}

static void _IT_RoundEndEvent(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
    g_bIsRound1Over = true;
}

static void _IT_RoundStartEvent(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
    g_iSaferoomCount[START_SAFEROOM - 1] = 0;
    g_iSaferoomCount[END_SAFEROOM - 1] = 0;

    // Since OnMapStart only happens once on scavenge mode, g_bIsRound1Over can only be once false because 
    // evey round_end event will turn it to true. This casues items spawning at the same position during the whole scavenge match.
    if (IsScavengeMode()) {
        if (!InSecondHalfOfRound()) {
            g_bIsRound1Over = false;
        }
    }

    // Mapstart happens after round_start most of the time, so we need to wait for g_bIsRound1Over.
    // Plus, we don't want to have conflicts with EntityRemover.
    CreateTimer(1.0, IT_RoundStartTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

static Action IT_RoundStartTimer(Handle hTimer)
{
    if (!g_bIsRound1Over) {
        // Round1
        if (IsModuleEnabled()) {
            EnumAndElimSpawns();
        }
    } else {
        // Round2
        if (IsModuleEnabled()) {
            if (g_hCvarConsistentSpawns.BoolValue) {
                GenerateStoredSpawns();
            } else {
                EnumAndElimSpawns();
            }
        }
    }

    return Plugin_Stop;
}

static void EnumAndElimSpawns()
{
    if (IsDebugEnabled()) {
        LogMessage("[%s] Resetting g_iSaferoomCount and Enumerating and eliminating spawns...", IT_MODULE_NAME);
    }

    EnumerateSpawns();
    g_bPillLimitHandled = ApplyPillFlowFilter();
    RemoveToLimits();
}

static void GenerateStoredSpawns()
{
    KillRegisteredItems();
    SpawnItems();

    // Repaint glows on the respawned entities.
    if (g_hCvarPillFlowVisualize.IntValue > 0) {
        ApplyPillFlowFilter();
    }
}

// l4d2lib plugin
// For 3.0 rounds library
/*public void L4D2_OnRealRoundStart(int roundNum)
{
    if (roundNum == 1) {
        EnumerateSpawns();
        RemoveToLimits();
    } else {
        // We kill off all items we recognize.
        // Unlimited items will be replaced, limited items will be spawned,
        // and killed items will stay killed
        KillRegisteredItems();
        // Spawn up the same items that existed in round 1
        SpawnItems();
    }
}*/

// Produces the lookup trie for weapon spawn entities
//		to translate to our ADT array of spawns
static void CreateItemListTrie()
{
    g_hItemListTrie = new StringMap();
    g_hItemListTrie.SetValue("weapon_pain_pills_spawn", IL_PainPills);
    g_hItemListTrie.SetValue("weapon_pain_pills", IL_PainPills);
    g_hItemListTrie.SetValue("weapon_adrenaline_spawn", IL_Adrenaline);
    g_hItemListTrie.SetValue("weapon_adrenaline", IL_Adrenaline);
    g_hItemListTrie.SetValue("weapon_pipe_bomb_spawn", IL_PipeBomb);
    g_hItemListTrie.SetValue("weapon_pipe_bomb", IL_PipeBomb);
    g_hItemListTrie.SetValue("weapon_molotov_spawn", IL_Molotov);
    g_hItemListTrie.SetValue("weapon_molotov", IL_Molotov);
    g_hItemListTrie.SetValue("weapon_vomitjar_spawn", IL_VomitJar);
    g_hItemListTrie.SetValue("weapon_vomitjar", IL_VomitJar);
}

static void KillRegisteredItems()
{
    int itemindex = 0, psychonic = GetEntityCount();
    int iSurvivorLimit = g_hSurvivorLimit.IntValue;
    bool bKeepPlayerItems = g_hCvarIgnorePlayerItems.BoolValue;

    for (int i = (MaxClients + 1); i <= psychonic; i++) {
        if (!IsValidEdict(i)) {
            continue;
        }

        itemindex = GetItemIndexFromEntity(i);
        if (itemindex >= 0/* && !IsEntityInSaferoom(i)*/) {
            if (IsEntityInSaferoom(i, START_SAFEROOM) && g_iSaferoomCount[START_SAFEROOM - 1] < iSurvivorLimit) {
                g_iSaferoomCount[START_SAFEROOM - 1]++;
            } else if (IsEntityInSaferoom(i, END_SAFEROOM) && g_iSaferoomCount[END_SAFEROOM - 1] < iSurvivorLimit) {
                g_iSaferoomCount[END_SAFEROOM - 1]++;
            } else {
                // Kill items we're tracking;
                // Exception for if the item is in a player's inventory.
                if (bKeepPlayerItems && HasEntProp(i, Prop_Send, "m_hOwner") && GetEntPropEnt(i, Prop_Send, "m_hOwner") > 0)
                  continue;
                
                KillEntity(i);
                /*if (!AcceptEntityInput(i, "kill")) {
                    Debug_LogError(IT_MODULE_NAME, "Error killing instance of item %s", g_sItemNames[itemindex][IN_longname]);
                }*/
            }
        }
    }
}

static void SpawnItems()
{
    ItemTracking curitem;

    float origins[3], angles[3];
    int arrsize = 0, itement = 0, wepid = 0;
    char sModelname[PLATFORM_MAX_PATH];

    for (int itemidx = 0; itemidx < ItemList_Size; itemidx++) {
        FormatEx(sModelname, sizeof(sModelname), "models/w_models/weapons/w_eq_%s.mdl", g_sItemNames[itemidx][IN_modelname]);

        arrsize = g_hItemSpawns[itemidx].Length;

        for (int idx = 0; idx < arrsize; idx++) {
            g_hItemSpawns[itemidx].GetArray(idx, curitem, sizeof(curitem));

            GetSpawnOrigins(origins, curitem);
            GetSpawnAngles(angles, curitem);
            wepid = GetWeaponIDFromItemList(itemidx);

            if (IsDebugEnabled()) {
                LogMessage("[%s] Spawning an instance of item %s (%d, wepid %d), number %d, at %.02f %.02f %.02f", \
                                IT_MODULE_NAME, g_sItemNames[itemidx][IN_officialname], itemidx, wepid, idx, origins[0], origins[1], origins[2]);
            }

            itement = CreateEntityByName("weapon_spawn");
            if (itement == -1) {
                continue;
            }

            SetEntProp(itement, Prop_Send, "m_weaponID", wepid);
            SetEntityModel(itement, sModelname);
            DispatchKeyValue(itement, "count", "1");
            TeleportEntity(itement, origins, angles, NULL_VECTOR);
            DispatchSpawn(itement);
            SetEntityMoveType(itement, MOVETYPE_NONE);

            /*
                Keep the stored entry pointing at the live entity so passes that
                run after the respawn (e.g. the pill flow filter) address the
                round-2 entity, not the killed round-1 one.
            */
            curitem.IT_entity = itement;
            g_hItemSpawns[itemidx].SetArray(idx, curitem, sizeof(curitem));
        }
    }
}

static void EnumerateSpawns()
{
    /*
        Start every enumeration from a clean slate.
        Without this, configs running savespawns 0 stack round-2 entries on round-1 leftovers
        and mapspecific 0 leaks spawns across maps (OnMapStart only clears when mapspecific != 0)
    */
    for (int i = 0; i < ItemList_Size; i++) {
        g_hItemSpawns[i].Clear();
    }

    ItemTracking curitem;

    float origins[3], angles[3];
    int itemindex = 0, psychonic = GetEntityCount();
    int iSurvivorLimit = g_hSurvivorLimit.IntValue;

    for (int i = (MaxClients + 1); i <= psychonic; i++) {
        if (!IsValidEdict(i)) {
            continue;
        }

        itemindex = GetItemIndexFromEntity(i);
        if (itemindex >= 0/* && !IsEntityInSaferoom(i)*/) {
            if (IsEntityInSaferoom(i, START_SAFEROOM)) {
                if (g_iSaferoomCount[START_SAFEROOM - 1] < iSurvivorLimit) {
                    g_iSaferoomCount[START_SAFEROOM - 1]++;
                } else {
                    KillEntity(i);
                    /*if (!AcceptEntityInput(i, "kill")) {
                        Debug_LogError(IT_MODULE_NAME, "Error killing instance of item %s", g_sItemNames[itemindex][IN_longname]);
                    }*/
                }
            } else if (IsEntityInSaferoom(i, END_SAFEROOM)) {
                if (g_iSaferoomCount[END_SAFEROOM - 1] < iSurvivorLimit) {
                    g_iSaferoomCount[END_SAFEROOM - 1]++;
                } else {
                    KillEntity(i);
                    /*if (!AcceptEntityInput(i, "kill")) {
                        Debug_LogError(IT_MODULE_NAME, "Error killing instance of item %s", g_sItemNames[itemindex][IN_longname]);
                    }*/
                }
            } else {
                int mylimit = g_iItemLimits[itemindex];
                if (IsDebugEnabled()) {
                    LogMessage("[%s] Found an instance of item %s (%d), with limit %d", IT_MODULE_NAME, g_sItemNames[itemindex][IN_longname], itemindex, mylimit);
                }

                // Item limit is zero, justkill it as we find it
                if (!mylimit) {
                    if (IsDebugEnabled()) {
                        LogMessage("[%s] Killing spawn", IT_MODULE_NAME);
                    }

                    KillEntity(i);
                    /*if (!AcceptEntityInput(i, "kill")) {
                        Debug_LogError(IT_MODULE_NAME, "Error killing instance of item %s", g_sItemNames[itemindex][IN_longname]);
                    }*/
                } else {
                    // Store entity, angles, origin
                    curitem.IT_entity = i;

                    GetEntPropVector(i, Prop_Send, "m_vecOrigin", origins);
                    GetEntPropVector(i, Prop_Send, "m_angRotation", angles);

                    if (IsDebugEnabled()) {
                        LogMessage("[%s] Saving spawn #%d at %.02f %.02f %.02f", IT_MODULE_NAME, g_hItemSpawns[itemindex].Length, origins[0], origins[1], origins[2]);
                    }

                    SetSpawnOrigins(origins, curitem);
                    SetSpawnAngles(angles, curitem);

                    // Push this instance onto our array for that item
                    g_hItemSpawns[itemindex].PushArray(curitem, sizeof(curitem));
                }
            }
        }
    }
}

static void RemoveToLimits()
{
    ItemTracking curitem;

    int curlimit = 0, killidx = 0;

    for (int itemidx = 0; itemidx < ItemList_Size; itemidx++) {
        // The pill flow filter already enforced the pills limit (evenly spaced by flow instead of random)
        if (itemidx == IL_PainPills && g_bPillLimitHandled) {
            continue;
        }

        curlimit = g_iItemLimits[itemidx];

        if (curlimit > 0) {
            // Kill off item spawns until we've reduced the item to the limit
            while (g_hItemSpawns[itemidx].Length > curlimit) {
                // Pick a random
                killidx = GetURandomIntRange(0, (g_hItemSpawns[itemidx].Length - 1));

                if (IsDebugEnabled()) {
                    LogMessage("[%s] Killing randomly chosen %s (%d) #%d", IT_MODULE_NAME, g_sItemNames[itemidx][IN_longname], itemidx, killidx);
                }

                g_hItemSpawns[itemidx].GetArray(killidx, curitem, sizeof(curitem));

                if (IsValidEdict(curitem.IT_entity)) {
                    KillEntity(curitem.IT_entity);

                    /*if (!AcceptEntityInput(curitem.IT_entity, "kill")) {
                        Debug_LogError(IT_MODULE_NAME, "Error killing instance of item %s", g_sItemNames[itemidx][IN_longname]);
                    }*/
                }

                g_hItemSpawns[itemidx].Erase(killidx);
            }
        }
        // If limit is 0, they're already dead. If it's negative, we kill nothing.
    }
}

static float PF_GetSetting(const char[] sKey, ConVar hCvar)
{
    if (IsMapDataAvailable()) {
        return GetMapValueFloat(sKey, hCvar.FloatValue);
    }

    return hCvar.FloatValue;
}

// Returns true when the filter is active (= it owns the pills limit this round).
static bool ApplyPillFlowFilter()
{
    float fFlowMin = PF_GetSetting("pillflow_min", g_hCvarPillFlowMin);
    float fFlowMax = PF_GetSetting("pillflow_max", g_hCvarPillFlowMax);
    float fSep = PF_GetSetting("pillflow_separation", g_hCvarPillFlowSeparation);

    if (fFlowMin <= 0.0 && fFlowMax >= 1.0 && fSep <= 0.0) {
        return false;
    }

    if (fFlowMax < fFlowMin) {
        LogError("[%s] pillflow_max (%.2f) < pillflow_min (%.2f); pill flow filter disabled.", IT_MODULE_NAME, fFlowMax, fFlowMin);
        return false;
    }

    if (!g_hCvarPillFlowFinale.BoolValue && L4D_IsMissionFinalMap()) {
        if (IsDebugEnabled()) {
            LogMessage("[%s] Finale map, pill flow filter skipped.", IT_MODULE_NAME);
        }
        return false;
    }

    float fMaxFlowDist = L4D2Direct_GetMapMaxFlowDistance();
    if (fMaxFlowDist <= 0.0) {
        return false;
    }

    ArrayList hSpawns = g_hItemSpawns[IL_PainPills];
    int iCount = hSpawns.Length;
    if (!iCount) {
        return true;
    }

    int iVisualize = g_hCvarPillFlowVisualize.IntValue;
    bool bVisualize = (iVisualize == 1);   // mode 1 glows instead of removing; mode 2 removes and glows survivors
    ItemTracking curitem;
    float fOrigins[3];

    // Resolve each stored pill spawn to a flow fraction and apply the window.
    float[] fPct = new float[iCount];
    int[] iReason = new int[iCount];

    for (int i = 0; i < iCount; i++) {
        hSpawns.GetArray(i, curitem, sizeof(curitem));
        GetSpawnOrigins(fOrigins, curitem);

        Address pNav = L4D_GetNearestNavArea(fOrigins, 120.0, true, false, false, 2);
        if (pNav == Address_Null) {
            pNav = L4D2Direct_GetTerrorNavArea(fOrigins);
        }

        float fFlow = (pNav != Address_Null) ? L4D2Direct_GetTerrorNavAreaFlow(pNav) : -1.0;
        if (fFlow < 0.0) {
            fPct[i] = -1.0;
            iReason[i] = PF_NO_FLOW;
            continue;
        }

        fPct[i] = fFlow / fMaxFlowDist;
        if (fPct[i] > 1.0) {
            fPct[i] = 1.0;
        }

        if (fPct[i] < fFlowMin || fPct[i] > fFlowMax) {
            iReason[i] = PF_CULL_WINDOW;
        }
    }

    // Index order sorted by ascending flow (spacing passes walk the map start->end).
    int[] iOrder = new int[iCount];
    for (int i = 0; i < iCount; i++) {
        iOrder[i] = i;
    }
    for (int i = 1; i < iCount; i++) {
        int tmp = iOrder[i];
        int j = i - 1;
        while (j >= 0 && fPct[iOrder[j]] > fPct[tmp]) {
            iOrder[j + 1] = iOrder[j];
            j--;
        }
        iOrder[j + 1] = tmp;
    }

    // Minimum flow separation; of a too-close cluster the earliest spawn wins.
    if (fSep > 0.0) {
        float fLastKept = -1.0;
        for (int k = 0; k < iCount; k++) {
            int i = iOrder[k];
            if (iReason[i] != PF_KEEP) {
                continue;
            }
            if (fLastKept >= 0.0 && fPct[i] - fLastKept < fSep) {
                iReason[i] = PF_CULL_SEP;
            } else {
                fLastKept = fPct[i];
            }
        }
    }

    /*
        Enforce the pills limit here, evenly spaced by flow.
        Spawns without flow data can't be spaced, so they occupy limit slots off the top.
    */
    int iLimit = g_iItemLimits[IL_PainPills];
    if (iLimit >= 0) {
        int iKept = 0, iNoFlow = 0;
        for (int i = 0; i < iCount; i++) {
            if (iReason[i] == PF_KEEP) {
                iKept++;
            } else if (iReason[i] == PF_NO_FLOW) {
                iNoFlow++;
            }
        }

        int iSlots = iLimit - iNoFlow;
        if (iSlots < 0) {
            /*
                More flowless spawns than the limit alone allows: remove the extra.
                No flow data means there is nothing to space them by, so array order decides
            */
            int iExcess = -iSlots;
            for (int i = iCount - 1; i >= 0 && iExcess > 0; i--) {
                if (iReason[i] == PF_NO_FLOW) {
                    iReason[i] = PF_CULL_LIMIT;
                    iExcess--;
                }
            }
            iSlots = 0;
        }

        if (iSlots < iKept) {
            bool[] bSelected = new bool[iCount];
            for (int slot = 0; slot < iSlots; slot++) {
                // Ideal flow for this slot
                float fWant = fFlowMin + (fFlowMax - fFlowMin) * (float(slot) + 0.5) / float(iSlots);

                int best = -1;
                float fBestDist = 0.0;
                for (int i = 0; i < iCount; i++) {
                    if (iReason[i] != PF_KEEP || bSelected[i]) {
                        continue;
                    }
                    float d = fPct[i] - fWant;
                    if (d < 0.0) {
                        d = -d;
                    }
                    if (best == -1 || d < fBestDist) {
                        best = i;
                        fBestDist = d;
                    }
                }
                if (best != -1) {
                    bSelected[best] = true;
                }
            }

            for (int i = 0; i < iCount; i++) {
                if (iReason[i] == PF_KEEP && !bSelected[i]) {
                    iReason[i] = PF_CULL_LIMIT;
                }
            }
        }
    }

    // Apply: kill+erase culled spawns (descending so indices stay valid), or
    // just glow everything in visualize mode.
    int iRemoved[4] = {0, ...};   // indexed by PF_CULL_* reason

    for (int i = iCount - 1; i >= 0; i--) {
        hSpawns.GetArray(i, curitem, sizeof(curitem));

        if (iReason[i] <= PF_KEEP) {
            if (IsDebugEnabled()) {
                LogMessage("[%s] Pill spawn %d flow=%.1f%% KEPT%s", IT_MODULE_NAME, curitem.IT_entity,
                    fPct[i] * 100.0, iReason[i] == PF_NO_FLOW ? " (no flow data)" : "");
            }
            if (iVisualize > 0) {
                L4D2_SetEntityGlow(curitem.IT_entity, L4D2Glow_Constant, 0, 0, PF_GLOW_KEEP, false);
            }
            continue;
        }

        if (IsDebugEnabled()) {
            static const char sReasons[4][] = {"", "outside window", "separation", "limit spacing"};
            LogMessage("[%s] Pill spawn %d flow=%.1f%% %s (%s)", IT_MODULE_NAME, curitem.IT_entity,
                fPct[i] * 100.0, bVisualize ? "WOULD REMOVE" : "REMOVED", sReasons[iReason[i]]);
        }
        iRemoved[iReason[i]]++;

        if (bVisualize) {
            L4D2_SetEntityGlow(curitem.IT_entity, L4D2Glow_Constant, 0, 0, PF_GLOW_CULL[iReason[i]], false);
        } else {
            if (IsValidEdict(curitem.IT_entity)) {
                KillEntity(curitem.IT_entity);
            }
            hSpawns.Erase(i);
        }
    }

    if (IsDebugEnabled()) {
        LogMessage("[%s] Pill flow window %.0f%%-%.0f%% sep %.1f%%: %d kept, %d %s (window), %d (separation), %d (limit spacing).%s",
            IT_MODULE_NAME, fFlowMin * 100.0, fFlowMax * 100.0, fSep * 100.0,
            iCount - iRemoved[PF_CULL_WINDOW] - iRemoved[PF_CULL_SEP] - iRemoved[PF_CULL_LIMIT],
            iRemoved[PF_CULL_WINDOW], bVisualize ? "flagged" : "removed",
            iRemoved[PF_CULL_SEP], iRemoved[PF_CULL_LIMIT],
            bVisualize ? " (visualize: nothing deleted; white = kept, red = window, orange = separation, cyan = limit)" : "");
    }

    return true;
}

static void SetSpawnOrigins(const float buf[3], ItemTracking spawn)
{
    spawn.IT_origins = buf[0];
    spawn.IT_origins1 = buf[1];
    spawn.IT_origins2 = buf[2];
}

static void SetSpawnAngles(const float buf[3], ItemTracking spawn)
{
    spawn.IT_angles = buf[0];
    spawn.IT_angles1 = buf[1];
    spawn.IT_angles2 = buf[2];
}

static void GetSpawnOrigins(float buf[3], const ItemTracking spawn)
{
    buf[0] = spawn.IT_origins;
    buf[1] = spawn.IT_origins1;
    buf[2] = spawn.IT_origins2;
}

static void GetSpawnAngles(float buf[3], const ItemTracking spawn)
{
    buf[0] = spawn.IT_angles;
    buf[1] = spawn.IT_angles1;
    buf[2] = spawn.IT_angles2;
}

static int GetWeaponIDFromItemList(int id)
{
    switch (id) {
        case IL_PainPills: {
            return WEPID_PAIN_PILLS;
        }
        case IL_Adrenaline: {
            return  WEPID_ADRENALINE;
        }
        case IL_PipeBomb: {
            return WEPID_PIPE_BOMB;
        }
        case IL_Molotov: {
            return WEPID_MOLOTOV;
        }
        case IL_VomitJar: {
            return WEPID_VOMITJAR;
        }
    }

    return -1;
}

static int GetItemIndexFromEntity(int entity)
{
    char classname[MAX_ENTITY_NAME_LENGTH];
    int index;

    GetEdictClassname(entity, classname, sizeof(classname));
    if (g_hItemListTrie.GetValue(classname, index)) {
        return index;
    }

    if (strcmp(classname, "weapon_spawn") == 0 || strcmp(classname, "weapon_item_spawn") == 0) {
        int id = GetEntProp(entity, Prop_Send, "m_weaponID");
        switch (id) {
            case WEPID_VOMITJAR: {
                return IL_VomitJar;
            }
            case WEPID_PIPE_BOMB: {
                return IL_PipeBomb;
            }
            case WEPID_MOLOTOV: {
                return IL_Molotov;
            }
            case WEPID_PAIN_PILLS: {
                return IL_PainPills;
            }
            case WEPID_ADRENALINE: {
                return IL_Adrenaline;
            }
        }
    }

    return -1;
}

static bool IsModuleEnabled()
{
    return (IsPluginEnabled() && g_hCvarEnabled.BoolValue);
}

stock bool IsScavengeMode()
{
    char   sCurGameMode[64];
    ConVar hCurGameMode = FindConVar("mp_gamemode");
    hCurGameMode.GetString(sCurGameMode, sizeof(sCurGameMode));
    if (strcmp(sCurGameMode, "scavenge") == 0)
        return true;
    else
        return false;
}

stock bool InSecondHalfOfRound()
{
    return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound"));
}