#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define DATA_FILE_PATH "data/protected_plugins_list.txt"

#define PL_NONE    0
#define PL_UNLOCK  (1 << 0)
#define PL_UNLOAD  (1 << 1)
#define PL_REFRESH (1 << 2)
#define PL_LOAD    (1 << 3)
#define PL_LOCK    (1 << 4)

int  g_iActions = PL_NONE;
bool g_bNextFrameQueued;
bool g_bUnloadQueued;

ArrayList g_alProtectedPlugins;
ArrayList g_alPluginUnloadQueue;
ArrayList g_alPluginLoadQueue;

public Plugin myinfo = {
    name        = "Plugin Unload Protect",
    author      = "0x0c",
    description = "Wrapper around sm plugins to prevent certain plugins from being unloaded",
    version     = "1.1.0",
    url         = "https://solaris-servers.ru/"
}

public void OnPluginStart() {
    g_alProtectedPlugins  = new ArrayList(PLATFORM_MAX_PATH);
    g_alPluginLoadQueue   = new ArrayList(PLATFORM_MAX_PATH);
    g_alPluginUnloadQueue = new ArrayList(PLATFORM_MAX_PATH);

    RegAdminCmd("sm_plugins_protect",      Cmd_Protect,    ADMFLAG_RCON);
    RegAdminCmd("sm_plugins_unprotect",    Cmd_Unprotect,  ADMFLAG_RCON);
    RegAdminCmd("sm_plugins_protect_list", Cmd_List,       ADMFLAG_RCON);
    RegAdminCmd("sm_plugins_load_lock",    Cmd_LoadLock,   ADMFLAG_RCON);
    RegAdminCmd("sm_plugins_load_unlock",  Cmd_LoadUnlock, ADMFLAG_RCON);
    RegAdminCmd("sm_plugins_refresh",      Cmd_Refresh,    ADMFLAG_RCON);
    RegAdminCmd("sm_plugins_load",         Cmd_Load,       ADMFLAG_RCON);
    RegAdminCmd("sm_plugins_unload",       Cmd_Unload,     ADMFLAG_RCON);
    RegAdminCmd("sm_plugins_unload_all",   Cmd_UnloadAll,  ADMFLAG_RCON);

    ReadOrCreateDataFile();
}

public void OnAllPluginsLoaded() {
    char szFilename[PLATFORM_MAX_PATH];
    Handle hPlugin = null;
    Handle hIterator = GetPluginIterator();

    while (MorePlugins(hIterator)) {
        hPlugin = ReadPlugin(hIterator);
        GetPluginFilename(hPlugin, szFilename, sizeof(szFilename));
        // add self to protected list
        if (IsDefaultProtected(szFilename) && !IsPluginProtected(szFilename)) {
            g_alProtectedPlugins.PushString(szFilename);
        }
    }
    delete hIterator;
}

void ReadOrCreateDataFile() {
    char szDataPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szDataPath, sizeof(szDataPath), "%s", DATA_FILE_PATH);
    File file;

    if (!FileExists(szDataPath)) {
        // file does not existt, simply create it and bail
        file = OpenFile(szDataPath, "w");
        delete file;
        return;
    }

    char szLine[PLATFORM_MAX_PATH];
    file = OpenFile(szDataPath, "r");

    while (!file.EndOfFile()) {
        file.ReadLine(szLine, PLATFORM_MAX_PATH);
        NormalizePluginFileName(szLine);
        ServerCommand("sm_plugins_protect %s", szLine);
    }

    delete file;
}

Action Cmd_Protect(int iClient, int iArgs) {
    if (iArgs < 1) {
        ReplyToCommand(iClient, "Usage: sm_protect <plugin>");
        return Plugin_Handled;
    }

    char szFilename[PLATFORM_MAX_PATH];
    GetCmdArg(1, szFilename, sizeof(szFilename));
    NormalizePluginFileName(szFilename);
    // check for duplicates
    if (IsPluginProtected(szFilename)) {
        ReplyToCommand(iClient, "[PluginUnloadProtect] %s is already protected", szFilename);
        return Plugin_Handled;
    }
    // check that such a file exists
    char szFullPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szFullPath, sizeof(szFullPath), "plugins/%s", szFilename);
    if (!FileExists(szFullPath)) {
        LogError("[PluginUnloadProtect] File %s does not exist", szFullPath);
        return Plugin_Handled;
    }

    g_alProtectedPlugins.PushString(szFilename);

    return Plugin_Handled;
}

Action Cmd_Unprotect(int iClient, int iArgs) {
    if (iArgs < 1) {
        ReplyToCommand(iClient, "Usage: sm_unprotect <plugin>");
        return Plugin_Handled;
    }

    char szFilename[PLATFORM_MAX_PATH];
    GetCmdArg(1, szFilename, sizeof(szFilename));
    NormalizePluginFileName(szFilename);

    if (IsDefaultProtected(szFilename)) {
        ReplyToCommand(iClient, "[PluginUnloadProtect] Can not unprotect default plugin");
        return Plugin_Handled;
    }

    int iItem = g_alProtectedPlugins.FindString(szFilename);
    if (iItem == -1) {
        ReplyToCommand(iClient, "[PluginUnloadProtect] %s is not protected", szFilename);
        return Plugin_Handled;
    }
    g_alProtectedPlugins.Erase(iItem);

    return Plugin_Handled;
}

Action Cmd_List(int iClient, int iArgs) {
    ReplyToCommand(iClient, "[PluginUnloadProtect] List of protected plugins (%i):", g_alProtectedPlugins.Length);
    char szFilename[PLATFORM_MAX_PATH];
    for (int i = 0; i < g_alProtectedPlugins.Length; i++) {
        g_alProtectedPlugins.GetString(i, szFilename, sizeof(szFilename));
        ReplyToCommand(iClient, "- %s", szFilename);
    }

    return Plugin_Handled;
}

Action Cmd_LoadLock(int iClient, int iArgs) {
    g_iActions |= PL_LOCK;
    ScheduleActions();
    return Plugin_Handled;
}

Action Cmd_LoadUnlock(int iClient, int iArgs) {
    g_iActions |= PL_UNLOCK;
    ScheduleActions();
    return Plugin_Handled;
}

Action Cmd_Refresh(int iClient, int iArgs) {
    g_iActions |= PL_REFRESH;
    ScheduleActions();
    return Plugin_Handled;
}

Action Cmd_Load(int iClient, int iArgs) {
    if (iArgs < 1) {
        ReplyToCommand(iClient, "Usage: sm_plugins_load <plugin>");
        return Plugin_Handled;
    }
    
    char szFilename[PLATFORM_MAX_PATH];
    GetCmdArg(1, szFilename, sizeof(szFilename));
    NormalizePluginFileName(szFilename);
    g_alPluginLoadQueue.PushString(szFilename);
    g_iActions |= PL_LOAD;
    ScheduleActions();

    return Plugin_Handled;
}

Action Cmd_Unload(int iClient, int iArgs) {
    if (iArgs < 1) {
        ReplyToCommand(iClient, "Usage: sm_plugins_unload <plugin>");
        return Plugin_Handled;
    }
    
    char szFilename[PLATFORM_MAX_PATH];
    GetCmdArg(1, szFilename, sizeof(szFilename));
    NormalizePluginFileName(szFilename);

    if (IsPluginProtected(szFilename)) {
        ReplyToCommand(iClient, "[PluginUnloadProtect] Plugin %s can not be unloaded, because it is currently protected", szFilename);
        return Plugin_Handled;
    }
    
    g_alPluginUnloadQueue.PushString(szFilename);
    g_iActions |= PL_UNLOAD;
    ScheduleActions();

    return Plugin_Handled;
}

Action Cmd_UnloadAll(int iClient, int iArgs) {
    if (g_alPluginUnloadQueue.Length > 0) {
        ReplyToCommand(iClient, "[PluginUnloadProtect] Could not execute the command, plugins are currently being unloaded");
        return Plugin_Handled;
    }
    
    char szFilename[PLATFORM_MAX_PATH];
    Handle hPlugin = null;
    Handle hIterator = GetPluginIterator();

    while (MorePlugins(hIterator)) {
        hPlugin = ReadPlugin(hIterator);
        GetPluginFilename(hPlugin, szFilename, sizeof(szFilename));
        if (IsPluginProtected(szFilename))
            continue;
        
        g_alPluginUnloadQueue.PushString(szFilename);
    }
    
    delete hIterator;
    g_iActions |= PL_UNLOAD;
    ScheduleActions();

    return Plugin_Handled;
}

void ScheduleActions() {
    if (g_bNextFrameQueued)
        return;
    
    g_bNextFrameQueued = true;
    RequestFrame(ScheduleActions_NextFrame);
}

void ScheduleActions_NextFrame() {
    if (g_iActions == PL_NONE) {
        g_bNextFrameQueued = false;
        return;
    }
    
    if (g_iActions & PL_UNLOCK == PL_UNLOCK) {
        ServerCommand("sm plugins load_unlock");
        g_iActions &= ~PL_UNLOCK;
    } else if (g_iActions & PL_UNLOAD == PL_UNLOAD) {
        if (g_bUnloadQueued) {
            AwaitUnload();
        } else {
            ExecuteUnload();
        }
    } else if (g_iActions & PL_REFRESH == PL_REFRESH) {
        ServerCommand("sm plugins refresh");
        g_iActions &= ~PL_REFRESH;
    } else if (g_iActions & PL_LOAD == PL_LOAD) {
        ExecuteLoad();
        g_iActions &= ~PL_LOAD;
    } else if (g_iActions & PL_LOCK == PL_LOCK) {
        ServerCommand("sm plugins load_lock");
        g_iActions &= ~PL_LOCK;
    } else {
        g_iActions = PL_NONE;
    }

    RequestFrame(ScheduleActions_NextFrame);
}

void ExecuteUnload() {
    char szFilename[PLATFORM_MAX_PATH];

    for (int i = g_alPluginUnloadQueue.Length - 1; i >= 0; i--) {
        g_alPluginUnloadQueue.GetString(i, szFilename, sizeof(szFilename));
        ServerCommand("sm plugins unload %s", szFilename);
    }
    
    g_bUnloadQueued = true;
}

void AwaitUnload() {
    char szFilename[PLATFORM_MAX_PATH];

    for (int i = g_alPluginUnloadQueue.Length - 1; i >= 0; i--) {
        Handle hPlugin = null;
        Handle hIterator = GetPluginIterator();

        while (MorePlugins(hIterator)) {
            hPlugin = ReadPlugin(hIterator);
            GetPluginFilename(hPlugin, szFilename, sizeof(szFilename));
            g_bUnloadQueued = g_alPluginUnloadQueue.FindString(szFilename) > -1;
            if (g_bUnloadQueued) {
                break;
            }
        }
        
        delete hIterator;
        if (g_bUnloadQueued) {
            break;
        }
    }

    if (!g_bUnloadQueued) {
        g_alPluginUnloadQueue.Clear();
        g_iActions &= ~PL_UNLOAD;
    }
}

void ExecuteLoad() {
    char szFilename[PLATFORM_MAX_PATH];
    for (int i = 0; i < g_alPluginLoadQueue.Length; i++) {
        g_alPluginLoadQueue.GetString(i, szFilename, sizeof(szFilename));
        ServerCommand("sm plugins load %s", szFilename);
    }
    
    g_alPluginLoadQueue.Clear();
}

bool IsPluginProtected(const char[] szFilename) {
    return g_alProtectedPlugins.FindString(szFilename) > -1;
}

void NormalizePluginFileName(char[] szFilename) {
    TrimString(szFilename);
    if (StrContains(szFilename, ".smx", true) == -1) {
        StrCat(szFilename, PLATFORM_MAX_PATH, ".smx");
    }
}

bool IsDefaultProtected(const char[] szFilename) {
    static const char szProtectedDefault[][PLATFORM_MAX_PATH] = {
        "plugin_unload_protect"
    };
    
    char szFilenameWithoutExt[PLATFORM_MAX_PATH];
    strcopy(szFilenameWithoutExt, sizeof(szFilenameWithoutExt), szFilename);
    ReplaceString(szFilenameWithoutExt, sizeof(szFilenameWithoutExt), ".smx", "", false);
    
    char szDefaultPluginWithoutExt[PLATFORM_MAX_PATH];
    for (int i = 0; i < sizeof(szProtectedDefault); i++) {
        strcopy(szDefaultPluginWithoutExt, sizeof(szDefaultPluginWithoutExt), szProtectedDefault[i]);
        ReplaceString(szDefaultPluginWithoutExt, sizeof(szDefaultPluginWithoutExt), ".smx", "", false);
        if (strcmp(szFilenameWithoutExt, szDefaultPluginWithoutExt, false) == 0) {
            return true;
        }
    }
    
    return false;
}