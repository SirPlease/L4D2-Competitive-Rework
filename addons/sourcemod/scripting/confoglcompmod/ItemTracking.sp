#if defined __item_tracking_included
    #endinput
#endif
#define __item_tracking_included

#define IT_MODULE_NAME			"ItemTracking"

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
#if SOURCEMOD_V_MINOR > 9
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
#else
enum ItemTracking
{
    IT_entity,
    Float:IT_origins,
    Float:IT_origins1,
    Float:IT_origins2,
    Float:IT_angles,
    Float:IT_angles1,
    Float:IT_angles2
};
#endif

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
    g_hCvarLimits[ItemList_Size] = {null, ...}; // CVAR Handle Array for item limits

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

    char sNameBuf[64], sCvarDescBuf[256];
    // Create itemlimit cvars
    for (int i = 0; i < ItemList_Size; i++) {
        Format(sNameBuf, sizeof(sNameBuf), "%s_limit", g_sItemNames[i][IN_shortname]);
        Format(sCvarDescBuf, sizeof(sCvarDescBuf), "Limits the number of %s on each map. -1: no limit; >=0: limit to cvar value", g_sItemNames[i][IN_longname]);

        g_hCvarLimits[i] = CreateConVarEx(sNameBuf, "-1", sCvarDescBuf);
    }

    // Create name translation trie
    CreateItemListTrie();

    // Create item spawns array;
#if SOURCEMOD_V_MINOR > 9
    ItemTracking curitem;
#else
    ItemTracking curitem[ItemTracking];
#endif

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
    RemoveToLimits();
}

static void GenerateStoredSpawns()
{
    KillRegisteredItems();
    SpawnItems();
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
#if SOURCEMOD_V_MINOR > 9
    ItemTracking curitem;
#else
    ItemTracking curitem[ItemTracking];
#endif

    float origins[3], angles[3];
    int arrsize = 0, itement = 0, wepid = 0;
    char sModelname[PLATFORM_MAX_PATH];

    for (int itemidx = 0; itemidx < ItemList_Size; itemidx++) {
        Format(sModelname, sizeof(sModelname), "models/w_models/weapons/w_eq_%s.mdl", g_sItemNames[itemidx][IN_modelname]);

        arrsize = g_hItemSpawns[itemidx].Length;

        for (int idx = 0; idx < arrsize; idx++) {
            #if SOURCEMOD_V_MINOR > 9
                g_hItemSpawns[itemidx].GetArray(idx, curitem, sizeof(curitem));
            #else
                g_hItemSpawns[itemidx].GetArray(idx, curitem[0], sizeof(curitem));
            #endif

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
        }
    }
}

static void EnumerateSpawns()
{
#if SOURCEMOD_V_MINOR > 9
    ItemTracking curitem;
#else
    ItemTracking curitem[ItemTracking];
#endif

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
                    #if SOURCEMOD_V_MINOR > 9
                        curitem.IT_entity = i;
                    #else
                        curitem[IT_entity] = i;
                    #endif

                    GetEntPropVector(i, Prop_Send, "m_vecOrigin", origins);
                    GetEntPropVector(i, Prop_Send, "m_angRotation", angles);

                    if (IsDebugEnabled()) {
                        LogMessage("[%s] Saving spawn #%d at %.02f %.02f %.02f", IT_MODULE_NAME, g_hItemSpawns[itemindex].Length, origins[0], origins[1], origins[2]);
                    }

                    SetSpawnOrigins(origins, curitem);
                    SetSpawnAngles(angles, curitem);

                    // Push this instance onto our array for that item
                    #if SOURCEMOD_V_MINOR > 9
                        g_hItemSpawns[itemindex].PushArray(curitem, sizeof(curitem));
                    #else
                        g_hItemSpawns[itemindex].PushArray(curitem[0], sizeof(curitem));
                    #endif
                }
            }
        }
    }
}

static void RemoveToLimits()
{
#if SOURCEMOD_V_MINOR > 9
    ItemTracking curitem;
#else
    ItemTracking curitem[ItemTracking];
#endif

    int curlimit = 0, killidx = 0;

    for (int itemidx = 0; itemidx < ItemList_Size; itemidx++) {
        curlimit = g_iItemLimits[itemidx];

        if (curlimit > 0) {
            // Kill off item spawns until we've reduced the item to the limit
            while (g_hItemSpawns[itemidx].Length > curlimit) {
                // Pick a random
                killidx = GetURandomIntRange(0, (g_hItemSpawns[itemidx].Length - 1));

                if (IsDebugEnabled()) {
                    LogMessage("[%s] Killing randomly chosen %s (%d) #%d", IT_MODULE_NAME, g_sItemNames[itemidx][IN_longname], itemidx, killidx);
                }

                #if SOURCEMOD_V_MINOR > 9
                    g_hItemSpawns[itemidx].GetArray(killidx, curitem, sizeof(curitem));

                    if (IsValidEdict(curitem.IT_entity)) {
                        KillEntity(curitem.IT_entity);

                        /*if (!AcceptEntityInput(curitem.IT_entity, "kill")) {
                            Debug_LogError(IT_MODULE_NAME, "Error killing instance of item %s", g_sItemNames[itemidx][IN_longname]);
                        }*/
                    }
                #else
                    g_hItemSpawns[itemidx].GetArray(killidx, curitem[0], sizeof(curitem));

                    if (IsValidEdict(curitem[IT_entity])) {
                        KillEntity(curitem[IT_entity]);

                        /*if (!AcceptEntityInput(curitem[IT_entity], "kill")) {
                            Debug_LogError(IT_MODULE_NAME, "Error killing instance of item %s", g_sItemNames[itemidx][IN_longname]);
                        }*/
                    }
                #endif

                g_hItemSpawns[itemidx].Erase(killidx);
            }
        }
        // If limit is 0, they're already dead. If it's negative, we kill nothing.
    }
}

#if SOURCEMOD_V_MINOR > 9
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
#else
static void SetSpawnOrigins(const float buf[3], ItemTracking spawn[ItemTracking])
{
    spawn[IT_origins] = buf[0];
    spawn[IT_origins1] = buf[1];
    spawn[IT_origins2] = buf[2];
}

static void SetSpawnAngles(const float buf[3], ItemTracking spawn[ItemTracking])
{
    spawn[IT_angles] = buf[0];
    spawn[IT_angles1] = buf[1];
    spawn[IT_angles2] = buf[2];
}

static void GetSpawnOrigins(float buf[3], const ItemTracking spawn[ItemTracking])
{
    buf[0] = spawn[IT_origins];
    buf[1] = spawn[IT_origins1];
    buf[2] = spawn[IT_origins2];
}

static void GetSpawnAngles(float buf[3], const ItemTracking spawn[ItemTracking])
{
    buf[0] = spawn[IT_angles];
    buf[1] = spawn[IT_angles1];
    buf[2] = spawn[IT_angles2];
}
#endif

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