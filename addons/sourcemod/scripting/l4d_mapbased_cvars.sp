#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
//#include <confogl>

#define KV_MAPCVAR              "/mapcvars.txt"
#define MAX_CONFIG_LEN          128
#define MAX_VARLENGTH           64
#define MAX_VALUELENGTH         128
#define MAX_SETVARS             64

#define DEBUG                   0


new Handle: g_hUseConfigDir;
new String: g_sUseConfigDir[MAX_CONFIG_LEN];     // which directory in cfgogl are we using? none = cfg/

/*
    to do:
        - make it work with confogl (lgofnoc?)
    
    0.1b
        - works properly with config dir changes on the fly
        - unloads properly now (resets values) 
        
 */


new Handle: g_hKvOrig = INVALID_HANDLE;         // kv to store original values in



public Plugin:myinfo = {
    name        = "L4D(2) map-based convar loader.",
    author      = "Tabun",
    version     = "0.1b",
    description = "Loads convars on map-load, based on currently active map and confogl config."
};


public OnPluginStart() {
    g_hUseConfigDir = CreateConVar("l4d_mapcvars_configdir", "", "Which cfgogl config are we using?", FCVAR_NONE);
    GetConVarString(g_hUseConfigDir, g_sUseConfigDir, MAX_CONFIG_LEN);
    HookConVarChange(g_hUseConfigDir, CvarConfigChange);
    
    // prepare KV for saving old states
    g_hKvOrig = CreateKeyValues("MapCvars_Orig");     // store original values
}

public OnPluginEnd() {
    ResetMapPrefs();
    if (g_hKvOrig != INVALID_HANDLE) { CloseHandle(g_hKvOrig); }
}


public CvarConfigChange( Handle:cvar, const String:oldValue[], const String:newValue[] ) {
    strcopy(g_sUseConfigDir, MAX_CONFIG_LEN, newValue);

    #if DEBUG
    PrintToServer("[mcv] config directory changed [%s], reloading values.", newValue);
    #endif
    ResetMapPrefs();    // reset old
    GetThisMapPrefs();  // apply new
}


public OnMapStart() {
    GetThisMapPrefs();
}

public OnMapEnd() {
    ResetMapPrefs();
}


public GetThisMapPrefs()
{
    new iNumChanged = 0;                                // how many cvars were changed for this map
    
    // reopen original keyvalues for clean slate:
    if (g_hKvOrig != INVALID_HANDLE) { CloseHandle(g_hKvOrig); }
    g_hKvOrig = CreateKeyValues("MapCvars_Orig");       // store original values for this map
    
    
    // build path to current config's keyvalues file
    new String:usePath[PLATFORM_MAX_PATH];
    if (strlen(g_sUseConfigDir) > 0)
    {
        usePath = "../../cfg/cfgogl/";
        StrCat(usePath, PLATFORM_MAX_PATH, g_sUseConfigDir);
        StrCat(usePath, PLATFORM_MAX_PATH, KV_MAPCVAR);
    } else {
        usePath = "../../cfg"; 
        StrCat(usePath, PLATFORM_MAX_PATH, KV_MAPCVAR);
    }
    BuildPath(Path_SM, usePath, sizeof(usePath), usePath);
    
    if (!FileExists(usePath)) {
        #if DEBUG
        PrintToServer("[mcv] file does not exist! (%s)", usePath);
        #endif
        return 0;
    }
    
    #if DEBUG
    PrintToServer("[mcv] trying keyvalue read (from [%s])...", usePath);
    #endif
    
    new Handle: hKv = CreateKeyValues("MapCvars");
    FileToKeyValues(hKv, usePath);
    
    if (hKv == INVALID_HANDLE) {
        #if DEBUG
        PrintToServer("[mcv] couldn't read file.");
        #endif
        return 0;
    }
    
    // read keyvalues for current map
    new String:sMapName[64];
    GetCurrentMap(sMapName, 64);
    
    if (!KvJumpToKey(hKv, sMapName))
    {
        // no special settings for this map
        CloseHandle(hKv);
        #if DEBUG
        PrintToServer("[mcv] couldn't find map (%s)", sMapName);
        #endif
        return 0;
    }
    
    // find all cvar keys and save the original values
    // then execute the change
    new String:tmpKey[MAX_VARLENGTH];
    new String:tmpValueNew[MAX_VALUELENGTH];
    new String:tmpValueOld[MAX_VALUELENGTH];
    new Handle: hConVar = INVALID_HANDLE;
    //new iConVarFlags = 0;
    
    
    if (KvGotoFirstSubKey(hKv, false))                              // false to get values
    {
        do
        {
            // read key stuff
            KvGetSectionName(hKv, tmpKey, sizeof(tmpKey));              // the subkey is a key-value pair, so get this to get the 'convar'
            #if DEBUG
            PrintToServer("[mcv] kv key found: [%s], reading value...", tmpKey);
            #endif
            
            // is it a convar?
            hConVar = FindConVar(tmpKey);
            /*
                // what to do with non-existant cvars?
                // don't add, for now
            if (hConVar == INVALID_HANDLE) {
                hConVar = CreateConVar(tmpKey, "", "[mcv] added because it didn't exist yet...", FCVAR_NONE);
            }
            */
            
            if (hConVar != INVALID_HANDLE) {
                // get type..
                //iConVarFlags = GetConVarFlags(hConVar);
                
                // types?
                //      FCVAR_CHEAT
                
                KvGetString(hKv, NULL_STRING, tmpValueNew, sizeof(tmpValueNew), "[:none:]");
                #if DEBUG
                PrintToServer("[mcv] kv value read: [%s] => [%s])", tmpKey, tmpValueNew);
                #endif
                
                // read, save and set value
                if (!StrEqual(tmpValueNew,"[:none:]")) {
                    GetConVarString(hConVar, tmpValueOld, sizeof(tmpValueOld));
                    PrintToServer("[mcv] cvar value changed: [%s] => [%s] (saved old: [%s]))", tmpKey, tmpValueNew, tmpValueOld);
                    
                    if (!StrEqual(tmpValueNew,tmpValueOld)) {
                        // different, save the old
                        iNumChanged++;
                        KvSetString(g_hKvOrig, tmpKey, tmpValueOld);
                        
                        // apply the new
                        SetConVarString(hConVar, tmpValueNew);
                        //if (iConVarFlags & FCVAR_CHEAT) {
                            
                        //}
                    }
                }
            } else {
                #if DEBUG
                PrintToServer("[mcv] convar doesn't exist: [%s], not changing it.", tmpKey);
                #endif
            }
        } while (KvGotoNextKey(hKv, false));
    } 
    
    KvSetString(g_hKvOrig, "__EOF__", "1");             // a test-safeguard
    
    CloseHandle(hKv);
    return iNumChanged;
}

public ResetMapPrefs()
{
    KvRewind(g_hKvOrig);
    
    #if DEBUG
    PrintToServer("[mcv] attempting to reset values, if any...");
    #endif
    
    // find all cvar keys and reset to original values
    new String: tmpKey[64];
    new String: tmpValueOld[512];
    new Handle: hConVar = INVALID_HANDLE;
    
    if (KvGotoFirstSubKey(g_hKvOrig, false))                              // false to get values
    {
        do
        {
            // read key stuff
            KvGetSectionName(g_hKvOrig, tmpKey, sizeof(tmpKey));      // the subkey is a key-value pair, so get this to get the 'convar'
            
            if (StrEqual(tmpKey, "__EOF__")) { 
                #if DEBUG
                PrintToServer("[mcv] kv original settings, all read. (EOF).");
                #endif
                break;
            }
            else
            {
            
                #if DEBUG
                PrintToServer("[mcv] kv original saved setting found: [%s], reading value...", tmpKey);
                #endif
                
                // is it a convar?
                hConVar = FindConVar(tmpKey);
                
                if (hConVar != INVALID_HANDLE) {
                    
                    KvGetString(g_hKvOrig, NULL_STRING, tmpValueOld, sizeof(tmpValueOld), "[:none:]");
                    #if DEBUG
                    PrintToServer("[mcv] kv saved value read: [%s] => [%s])", tmpKey, tmpValueOld);
                    #endif
                    
                    // read, save and set value
                    if (!StrEqual(tmpValueOld,"[:none:]")) {
                        
                        // reset the old
                        SetConVarString(hConVar, tmpValueOld);
                        PrintToServer("[mcv] cvar value reset to original: [%s] => [%s])", tmpKey, tmpValueOld);
                    }
                } else {
                    #if DEBUG
                    PrintToServer("[mcv] convar doesn't exist: [%s], not resetting it.", tmpKey);
                    #endif
                }
            }
            
        } while (KvGotoNextKey(g_hKvOrig, false));
    }
}
