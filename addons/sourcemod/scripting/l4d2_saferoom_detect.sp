#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <confogl>

#define SR_DEBUG_MODE       0               // outputs some coordinate data

#define DETMODE_LGO         0               // use mapinfo.txt (through confogl)
#define DETMODE_EXACT       1               // use exact list (coordinate-in-box)

#define SR_RADIUS           200.0           // the radius used to check distance from saferoom-coordinate (LGO mapinfo default)

#define STRMAX_MAPNAME      64


static const String:MAPINFO_PATH[] = "configs/saferoominfo.txt";


/*

    To Do
    =========
        - add custom campaign: Dead Before Dawn (DC) (problematic loading...)
        
    Changelog
    =========
    
        0.0.8
            - Replace lgofnoc with confogl.
    
        0.0.7
            - Built in safeguard against trying to find values before keyvalues file is loaded.

        0.0.6
            - Fixed problems with entities that don't have location data
            
        0.0.1 - 0.0.5
            - Got rid of dependency on l4d2lib. Now falls back on lgofnoc, if loaded.
            - Now regged as 'saferoom_detect'
            - Fixed swapped start/end saferoom problem.
            - Better saferoom detection for weird saferooms (Death Toll church, Dead Air greenhouse), two-part saferoom checks.
            - Uses KeyValues file now: saferoominfo.txt in sourcemod/configs/
            - All official maps done (even Cold Stream).
        
*/

public Plugin:myinfo = 
{
    name = "Precise saferoom detection",
    author = "Tabun, devilesk",
    description = "Allows checks whether a coordinate/entity/player is in start or end saferoom (uses saferoominfo.txt).",
    version = "0.0.8",
    url = "https://github.com/devilesk/rl4d2l-plugins"
}

new     bool:           g_bLGOIsAvailable                                   = false;                // whether confogl is loaded

new     Handle:         g_kSIData                                           = INVALID_HANDLE;       // keyvalues handle for SaferoomInfo.txt
new                     g_iMode                                             = DETMODE_LGO;          // detection mode for this map (LGO = mapinfo.txt 'vague radius' mode)
new     String:         g_sMapname[STRMAX_MAPNAME];

new     bool:           g_bHasStart;                                                                // if DETMODE_EXACT, whether start saferoom is known
new     bool:           g_bHasStartExtra;                                                           // whether it's a 2-part saferoom box
new     Float:          g_fStartLocA[3];                                                            // coordinates of 1 corner of the start saferoom box
new     Float:          g_fStartLocB[3];                                                            // and its opposite corner
new     Float:          g_fStartLocC[3];                                                            // second box for saferoom?
new     Float:          g_fStartLocD[3];
new     Float:          g_fStartRotate;                                                             // rotated saferoom by this many degrees (for easy in-box coordinate checking)

new     bool:           g_bHasEnd;
new     bool:           g_bHasEndExtra;
new     Float:          g_fEndLocA[3];
new     Float:          g_fEndLocB[3];
new     Float:          g_fEndLocC[3];
new     Float:          g_fEndLocD[3];
new     Float:          g_fEndRotate;


// Natives
// -------
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("SAFEDETECT_IsEntityInStartSaferoom", Native_IsEntityInStartSaferoom);
	CreateNative("SAFEDETECT_IsPlayerInStartSaferoom", Native_IsPlayerInStartSaferoom);
	CreateNative("SAFEDETECT_IsEntityInEndSaferoom", Native_IsEntityInEndSaferoom);
	CreateNative("SAFEDETECT_IsPlayerInEndSaferoom", Native_IsPlayerInEndSaferoom);    

	MarkNativeAsOptional("LGO_IsMapDataAvailable");
	MarkNativeAsOptional("LGO_GetMapValueVector");
	MarkNativeAsOptional("LGO_GetMapValueFloat");

	RegPluginLibrary("l4d2_saferoom_detect");

	return APLRes_Success;
}

public OnAllPluginsLoaded()
{
    g_bLGOIsAvailable = LibraryExists("confogl");
}

public Native_IsEntityInStartSaferoom(Handle:plugin, numParams)
{
    new entity = GetNativeCell(1);
    return _: IsEntityInStartSaferoom(entity);
}
public Native_IsEntityInEndSaferoom(Handle:plugin, numParams)
{
    new entity = GetNativeCell(1);
    return _: IsEntityInEndSaferoom(entity);
}

public Native_IsPlayerInStartSaferoom(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    return _: IsPlayerInStartSaferoom(client);
}
public Native_IsPlayerInEndSaferoom(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    return _: IsPlayerInEndSaferoom(client);
}



// Init
// ----

public OnPluginStart()
{
    // fill a huge trie with maps that we have data for
    SI_KV_Load();
}

public OnPluginEnd()
{
    SI_KV_Close();
}

public OnMapStart()
{
    // get and store map data for this round
    GetCurrentMap(g_sMapname, sizeof(g_sMapname));
    
    g_iMode = ( SI_KV_UpdateSaferoomInfo() ) ? DETMODE_EXACT : DETMODE_LGO;
}

public OnMapEnd()
{
    KvRewind(g_kSIData);
}


// Checks
// ------

public IsEntityInStartSaferoom(entity)
{
    if ( !IsValidEntity(entity) || GetEntSendPropOffs(entity, "m_vecOrigin", true) == -1 ) { return false; }
    
    // get entity location
    new Float: location[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", location);
    
    return IsPointInStartSaferoom(location);
}

public IsEntityInEndSaferoom(entity)
{
    if ( !IsValidEntity(entity) || GetEntSendPropOffs(entity, "m_vecOrigin", true) == -1 ) { return false; }
    
    // get entity location
    new Float: location[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", location);
    
    return IsPointInEndSaferoom(location);
}


public IsPlayerInStartSaferoom(client)
{
    if (client < 1 || client > MaxClients || !IsClientInGame(client)) { return false; }
    
    // get client location
    new Float: locationA[3];
    new Float: locationB[3];
    
    // try both abs & eye
    GetClientAbsOrigin(client, locationA);
    GetClientEyePosition(client, locationB);
    
    return bool: (IsPointInStartSaferoom(locationA) || IsPointInStartSaferoom(locationB));
}

public IsPlayerInEndSaferoom(client)
{
    if (client < 1 || client > MaxClients || !IsClientInGame(client)) { return false; }
    
    // get client location
    new Float: locationA[3];
    new Float: locationB[3];
    
    // try both abs & eye
    GetClientAbsOrigin(client, locationA);
    GetClientEyePosition(client, locationB);
    
    return bool: (IsPointInEndSaferoom(locationA) || IsPointInEndSaferoom(locationB));
}


IsPointInStartSaferoom(Float:location[3], entity=-1)
{
    if (g_iMode == DETMODE_EXACT)
    {
        if (!g_bHasStart) { return false; }
        
        new bool: inSaferoom = false;
        
        // rotate point if necessary
        if (g_fStartRotate)
        {
            RotatePoint(g_fStartLocA, location[0], location[1], g_fStartRotate);
        }
        
        // check if the point is inside the box (end or start)
        new Float: xMin, Float: xMax;
        new Float: yMin, Float: yMax;
        new Float: zMin, Float: zMax;
        
        if (g_fStartLocA[0] < g_fStartLocB[0]) { xMin = g_fStartLocA[0]; xMax = g_fStartLocB[0]; } else { xMin = g_fStartLocB[0]; xMax = g_fStartLocA[0]; }
        if (g_fStartLocA[1] < g_fStartLocB[1]) { yMin = g_fStartLocA[1]; yMax = g_fStartLocB[1]; } else { yMin = g_fStartLocB[1]; yMax = g_fStartLocA[1]; }
        if (g_fStartLocA[2] < g_fStartLocB[2]) { zMin = g_fStartLocA[2]; zMax = g_fStartLocB[2]; } else { zMin = g_fStartLocB[2]; zMax = g_fStartLocA[2]; }
        
        PrintDebug("dimensions checked: %f - %f (%f) -- %f - %f (%f) -- %f - %f (%f)", xMin, xMax, location[0], yMin, yMax, location[1], zMin, zMax, location[2]);
        
        inSaferoom =  bool: (   location[0] >= xMin && location[0] <= xMax
                            &&  location[1] >= yMin && location[1] <= yMax
                            &&  location[2] >= zMin && location[2] <= zMax  );
            
        // two-part saferooms:
        if (!inSaferoom && g_bHasStartExtra)
        {
            if (g_fStartLocC[0] < g_fStartLocD[0]) { xMin = g_fStartLocC[0]; xMax = g_fStartLocD[0]; } else { xMin = g_fStartLocD[0]; xMax = g_fStartLocC[0]; }
            if (g_fStartLocC[1] < g_fStartLocD[1]) { yMin = g_fStartLocC[1]; yMax = g_fStartLocD[1]; } else { yMin = g_fStartLocD[1]; yMax = g_fStartLocC[1]; }
            if (g_fStartLocC[2] < g_fStartLocD[2]) { zMin = g_fStartLocC[2]; zMax = g_fStartLocD[2]; } else { zMin = g_fStartLocD[2]; zMax = g_fStartLocC[2]; }
            
            PrintDebug("extra dimensions checked: %f - %f (%f) -- %f - %f (%f) -- %f - %f (%f)", xMin, xMax, location[0], yMin, yMax, location[1], zMin, zMax, location[2]);
            
            inSaferoom =  bool: (   location[0] >= xMin && location[0] <= xMax
                                &&  location[1] >= yMin && location[1] <= yMax
                                &&  location[2] >= zMin && location[2] <= zMax  );
        }
        
        return inSaferoom;
    }
    else if (g_bLGOIsAvailable)
    {
        // trust confogl / mapinfo
        
        new Float:saferoom_distance = LGO_GetMapValueFloat("start_dist", SR_RADIUS);
        new Float:saferoom_distance_extra = LGO_GetMapValueFloat("start_extra_dist", 0.0);
        new Float:saferoom[3];
        LGO_GetMapValueVector("start_point", saferoom, NULL_VECTOR);
        
        if ( entity != -1 && IsValidEntity(entity) && GetEntSendPropOffs(entity, "m_vecOrigin", true) != -1 )
        {
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", location);
        }
        
        // distance to entity
        return bool: ( GetVectorDistance(location, saferoom) <= ((saferoom_distance_extra > saferoom_distance) ? saferoom_distance_extra : saferoom_distance) );
    }
    
    return false;
    
}

IsPointInEndSaferoom(Float:location[3], entity = -1)
{    
    if (g_iMode == DETMODE_EXACT)
    {
        if (!g_bHasEnd) { return false; }
        
        new bool: inSaferoom = false;
        
        // rotate point if necessary
        if (g_fEndRotate)
        {
            RotatePoint(g_fEndLocA, location[0], location[1], g_fEndRotate);
        }
        
        
        // check if the point is inside the box (end or start)
        new Float: xMin, Float: xMax;
        new Float: yMin, Float: yMax;
        new Float: zMin, Float: zMax;
        
        if (g_fEndLocA[0] < g_fEndLocB[0]) { xMin = g_fEndLocA[0]; xMax = g_fEndLocB[0]; } else { xMin = g_fEndLocB[0]; xMax = g_fEndLocA[0]; }
        if (g_fEndLocA[1] < g_fEndLocB[1]) { yMin = g_fEndLocA[1]; yMax = g_fEndLocB[1]; } else { yMin = g_fEndLocB[1]; yMax = g_fEndLocA[1]; }
        if (g_fEndLocA[2] < g_fEndLocB[2]) { zMin = g_fEndLocA[2]; zMax = g_fEndLocB[2]; } else { zMin = g_fEndLocB[2]; zMax = g_fEndLocA[2]; }
        
        PrintDebug("dimensions checked: %f - %f (%f) -- %f - %f (%f) -- %f - %f (%f)", xMin, xMax, location[0], yMin, yMax, location[1], zMin, zMax, location[2]);
        
        inSaferoom =  bool: (   location[0] >= xMin && location[0] <= xMax
                            &&  location[1] >= yMin && location[1] <= yMax
                            &&  location[2] >= zMin && location[2] <= zMax  );
        
        // two-part saferooms:
        if (!inSaferoom && g_bHasEndExtra)
        {
            if (g_fEndLocC[0] < g_fEndLocD[0]) { xMin = g_fEndLocC[0]; xMax = g_fEndLocD[0]; } else { xMin = g_fEndLocD[0]; xMax = g_fEndLocC[0]; }
            if (g_fEndLocC[1] < g_fEndLocD[1]) { yMin = g_fEndLocC[1]; yMax = g_fEndLocD[1]; } else { yMin = g_fEndLocD[1]; yMax = g_fEndLocC[1]; }
            if (g_fEndLocC[2] < g_fEndLocD[2]) { zMin = g_fEndLocC[2]; zMax = g_fEndLocD[2]; } else { zMin = g_fEndLocD[2]; zMax = g_fEndLocC[2]; }
            
            PrintDebug("extra dimensions checked: %f - %f (%f) -- %f - %f (%f) -- %f - %f (%f)", xMin, xMax, location[0], yMin, yMax, location[1], zMin, zMax, location[2]);
            
            inSaferoom =  bool: (   location[0] >= xMin && location[0] <= xMax
                                &&  location[1] >= yMin && location[1] <= yMax
                                &&  location[2] >= zMin && location[2] <= zMax  );
        }
        
        return inSaferoom;
    }
    else if (g_bLGOIsAvailable)
    {
        // trust confogl / mapinfo
        
        new Float:saferoom_distance = LGO_GetMapValueFloat("end_dist", SR_RADIUS);
        new Float:saferoom[3];
        LGO_GetMapValueVector("end_point", saferoom, NULL_VECTOR);
        
        if ( entity != -1 && IsValidEntity(entity) && GetEntSendPropOffs(entity, "m_vecOrigin", true) != -1 )
        {
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", location);
        }
        
        // distance to entity
        return bool: ( GetVectorDistance(location, saferoom) <= saferoom_distance );
    }
    
    return false;
}


// KeyValues
// ---------

SI_KV_Close()
{
    if (g_kSIData == INVALID_HANDLE) { return; }
    CloseHandle(g_kSIData);
    g_kSIData = INVALID_HANDLE;
}

SI_KV_Load()
{
    decl String:sNameBuff[PLATFORM_MAX_PATH];

    g_kSIData = CreateKeyValues("SaferoomInfo");
    BuildPath(Path_SM, sNameBuff, sizeof(sNameBuff), MAPINFO_PATH);
    
    if (!FileToKeyValues(g_kSIData, sNameBuff))
    {
        LogError("[SI] Couldn't load SaferoomInfo data!");
        SI_KV_Close();
        return;
    }
}

bool: SI_KV_UpdateSaferoomInfo()
{
    if (g_kSIData == INVALID_HANDLE) {
        LogError("[SI] No saferoom keyvalues loaded!");
        return false;
    }

    // defaults
    g_bHasStart = false;        g_bHasStartExtra = false;
    g_bHasEnd = false;          g_bHasEndExtra = false;
    g_fStartLocA = NULL_VECTOR; g_fStartLocB = NULL_VECTOR; g_fStartLocC = NULL_VECTOR; g_fStartLocD = NULL_VECTOR;
    g_fEndLocA = NULL_VECTOR;   g_fEndLocB = NULL_VECTOR;   g_fEndLocC = NULL_VECTOR;   g_fEndLocD = NULL_VECTOR;
    g_fStartRotate = 0.0;       g_fEndRotate = 0.0;
    
    // get keyvalues
    if (KvJumpToKey(g_kSIData, g_sMapname))
    {
        KvGetVector(g_kSIData, "start_loc_a", g_fStartLocA);
        KvGetVector(g_kSIData, "start_loc_b", g_fStartLocB);
        KvGetVector(g_kSIData, "start_loc_c", g_fStartLocC);
        KvGetVector(g_kSIData, "start_loc_d", g_fStartLocD);
        g_fStartRotate = KvGetFloat(g_kSIData, "start_rotate", g_fStartRotate);
        KvGetVector(g_kSIData, "end_loc_a", g_fEndLocA);
        KvGetVector(g_kSIData, "end_loc_b", g_fEndLocB);
        KvGetVector(g_kSIData, "end_loc_c", g_fEndLocC);
        KvGetVector(g_kSIData, "end_loc_d", g_fEndLocD);
        g_fEndRotate = KvGetFloat(g_kSIData, "end_rotate", g_fEndRotate);
        
        // check data:
        if (g_fStartLocA[0] != 0.0 && g_fStartLocA[1] != 0.0 && g_fStartLocA[2] != 0.0 && g_fStartLocB[0] != 0.0 && g_fStartLocB[1] != 0.0 && g_fStartLocB[2] != 0.0) { g_bHasStart = true; }
        if (g_fStartLocC[0] != 0.0 && g_fStartLocC[1] != 0.0 && g_fStartLocC[2] != 0.0 && g_fStartLocD[0] != 0.0 && g_fStartLocD[1] != 0.0 && g_fStartLocD[2] != 0.0) { g_bHasStartExtra = true; }
        if (g_fEndLocA[0] != 0.0 && g_fEndLocA[1] != 0.0 && g_fEndLocA[2] != 0.0 && g_fEndLocB[0] != 0.0 && g_fEndLocB[1] != 0.0 && g_fEndLocB[2] != 0.0) { g_bHasEnd = true; }
        if (g_fEndLocC[0] != 0.0 && g_fEndLocC[1] != 0.0 && g_fEndLocC[2] != 0.0 && g_fEndLocD[0] != 0.0 && g_fEndLocD[1] != 0.0 && g_fEndLocD[2] != 0.0) { g_bHasEndExtra = true; }
        
        // rotate if necessary:
        if (g_fStartRotate != 0.0) {
            RotatePoint(g_fStartLocA, g_fStartLocB[0], g_fStartLocB[1], g_fStartRotate);
            if (g_bHasStartExtra) {
                RotatePoint(g_fStartLocA, g_fStartLocC[0], g_fStartLocC[1], g_fStartRotate);
                RotatePoint(g_fStartLocA, g_fStartLocD[0], g_fStartLocD[1], g_fStartRotate);
            }
        }
        if (g_fEndRotate != 0.0) {
            RotatePoint(g_fEndLocA, g_fEndLocB[0], g_fEndLocB[1], g_fEndRotate);
            if (g_bHasEndExtra) {
                RotatePoint(g_fEndLocA, g_fEndLocC[0], g_fEndLocC[1], g_fEndRotate);
                RotatePoint(g_fEndLocA, g_fEndLocD[0], g_fEndLocD[1], g_fEndRotate);
            }
        }
        
        return true;
    }
    else
    {
        LogMessage("[SI] SaferoomInfo for %s is missing.", g_sMapname);
        
        return false;
    }
}


// Support functions
// -----------------

// rotate a point (x,y) over an angle, with ref. to an origin (x,y plane only)
stock RotatePoint(Float:origin[3], &Float:pointX, &Float:pointY, Float:angle)
{
    // translate angle to radians:
    new Float: newPoint[2];
    angle = angle / 57.2957795130823;
    
    newPoint[0] = (Cosine(angle) * (pointX - origin[0])) - (Sine(angle) * (pointY - origin[1]))   + origin[0];
    newPoint[1] = (Sine(angle) * (pointX - origin[0]))   + (Cosine(angle) * (pointY - origin[1])) + origin[1];
    
    pointX = newPoint[0];
    pointY = newPoint[1];
    
    return;
}

public PrintDebug(const String:Message[], any:...)
{
    #if SR_DEBUG_MODE
        decl String:DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
        LogMessage(DebugBuff);
        //PrintToServer(DebugBuff);
        //PrintToChatAll(DebugBuff);
    #endif
}