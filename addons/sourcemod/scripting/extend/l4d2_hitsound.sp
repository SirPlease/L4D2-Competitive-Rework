/**  
 * l4d2_hitsound_plus.sp
 *
 * 本版要点：
 * - 仅使用 6 个数据库字段：hitsound_head/hit/kill、hiticon_head/hit/kill（0=关闭；>=1=套装编号）
 * - 非管理员：按“套装”选择音效/图标；“特定开关”里可把单项设为 0（关闭）
 * - 管理员：可将命中/击杀/爆头的音效或图标分别指定为任意套装
 * - KV fallback 同步为 6 键（保留对旧 KV 键 Snd/Overlay 的一次性继承；数据库旧列已彻底移除）
 * - 保留 FastDL、builtin=1 跳过、统一预缓存、RegPluginLibrary、sm_hitui 快捷开关等
 *
 * 配置文件：
 *   addons/sourcemod/configs/hitsound_sets.cfg   （音效套装：headshot/hit/kill，支持 builtin）
 *   addons/sourcemod/configs/hiticon_sets.cfg    （图标套装：head/hit/kill，支持 builtin）
 *
 * 重要编号约定：
 *   - 套装ID：1..N，0 表示禁用
 *   - 数组索引：内部数组存放为 0..N-1（故读取时用 setId-1）
 *
 * SQL（示例，表名默认 ConVar: sm_hitsound_db_table = RPG）:
 *   ALTER TABLE `RPG`
 *     ADD COLUMN `hitsound_head`  TINYINT NOT NULL DEFAULT 0,
 *     ADD COLUMN `hitsound_hit`   TINYINT NOT NULL DEFAULT 0,
 *     ADD COLUMN `hitsound_kill`  TINYINT NOT NULL DEFAULT 0,
 *     ADD COLUMN `hiticon_head`   TINYINT NOT NULL DEFAULT 0,
 *     ADD COLUMN `hiticon_hit`    TINYINT NOT NULL DEFAULT 0,
 *     ADD COLUMN `hiticon_kill`   TINYINT NOT NULL DEFAULT 0,
 *     ADD COLUMN `hitsound_si_only` TINYINT NOT NULL DEFAULT 0,
 *     ADD COLUMN `hiticon_si_only`  TINYINT NOT NULL DEFAULT 0;
 *
 * commands:
 *   !snd    -> 主菜单（音效/图标套装（玩家） + 特定开关 + 管理员单独设置）
 *   !hitui  -> 快速将覆盖图标三项在 禁用/套装1 之间切换（玩家一键）
 *   sm_hitsound_reload -> 重新从 DB/KV 读取所有在线玩家的偏好
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <adminmenu>

#define PLUGIN_VERSION "2.1.0"
#define CVAR_FLAGS     FCVAR_NOTIFY
#define IsValidClient(%1) (1 <= %1 && %1 <= MaxClients && IsClientInGame(%1))

// --------------------- Library expose ---------------------
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("l4d2_hitsound_plus");
    RegPluginLibrary("l4d2_hitsound"); // 兼容别名
    return APLRes_Success;
}

// --------------------- ConVars ---------------------
ConVar cv_enable;
ConVar cv_debug; // 调试总开关
ConVar cv_sound_enable;
ConVar cv_pic_enable;     // 全局启/停覆盖图功能（大总开关）
ConVar cv_blast;
ConVar cv_showtime;
// 新玩家默认是否启用覆盖图：1=给默认套装1（若存在），0=默认禁用
ConVar cv_overlay_default_enable;

ConVar cv_db_enable;
ConVar cv_db_conf;
ConVar cv_db_table;       // 可配置表名（默认 RPG）

// --------------------- State ---------------------
// 「最近套装」用于非管理员在“特定开关”重新开启时恢复为最近一次套装选择（不入库）
int  g_SndSuite [MAXPLAYERS + 1] = {0, ...}; // 最近一次“音效套装（玩家）”
int  g_IcSuite  [MAXPLAYERS + 1] = {0, ...}; // 最近一次“图标套装（玩家）”

// 六字段（真正用于表现/入库）：0=关闭；>=1=套装编号（与配置文件顺序一致）
int  g_SndHead  [MAXPLAYERS + 1] = {0, ...};
int  g_SndHit   [MAXPLAYERS + 1] = {0, ...};
int  g_SndKill  [MAXPLAYERS + 1] = {0, ...};

int  g_IcHead   [MAXPLAYERS + 1] = {0, ...};
int  g_IcHit    [MAXPLAYERS + 1] = {0, ...};
int  g_IcKill   [MAXPLAYERS + 1] = {0, ...};

bool g_SndSpecialOnly[MAXPLAYERS + 1] = { false, ... };
bool g_IcSpecialOnly [MAXPLAYERS + 1] = { false, ... };

bool g_PrefsLoaded[MAXPLAYERS + 1] = { false, ... };
bool g_PrefsDirty [MAXPLAYERS + 1] = { false, ... };

Handle g_hDB = INVALID_HANDLE;
Handle g_taskDBRetry = INVALID_HANDLE;
Handle g_taskDBKeepAlive = INVALID_HANDLE;
Handle g_taskLoadRetry[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
int    g_LoadRetryCount[MAXPLAYERS + 1] = { 0, ... };
int    g_DBRetryCount = 0;
bool   g_DBConnecting = false;

Handle g_taskClean[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
bool   g_IsVictimDeadPlayer[MAXPLAYERS + 1] = { false, ... };

#define DB_LOAD_RETRY_DELAY 0.5
#define DB_LOAD_RETRY_MAX   20
#define DB_CONNECT_RETRY_DELAY 10.0
#define DB_KEEPALIVE_INTERVAL 45.0

// Fallback KV
Handle g_SoundStore = INVALID_HANDLE;
char   g_SavePath[256];

// --------------------- Sound sets ---------------------
Handle g_SetNames    = INVALID_HANDLE;
Handle g_SetHeadshot = INVALID_HANDLE;
Handle g_SetHit      = INVALID_HANDLE;
Handle g_SetKill     = INVALID_HANDLE;
int    g_SetCount    = 0; // 套装总数（音效），套装ID有效范围：1..g_SetCount

// --------------------- Overlay icon sets（玩家自选） ---------------------
Handle g_OvNames = INVALID_HANDLE;
Handle g_OvHead  = INVALID_HANDLE; // materials 基名（不含扩展名）
Handle g_OvHit   = INVALID_HANDLE;
Handle g_OvKill  = INVALID_HANDLE;
int    g_OvCount = 0; // 套装总数（图标），套装ID有效范围：1..g_OvCount

// --------------------- Enums ---------------------
enum OverlayType
{
    KILL_HEADSHOT = 0,
    HIT_ARMOR,
    KILL_NORMAL
};

// --------------------- Plugin Info ---------------------
public Plugin myinfo =
{
    name = "L4D2 Hit/Kill Feedback Plus (6-field)",
    author = "TsukasaSato , Hesh233 (branch) , merged/updated by ChatGPT",
    description = "音效三项+图标三项（套装ID）入库，非管按套装+单项开关，管理员单项自由设定",
    version = PLUGIN_VERSION
};

// ========================================================
// Helpers
// ========================================================
stock void DBG(const char[] fmt, any ...)
{
    if (!GetConVarBool(cv_debug)) return;
    char buf[512];
    VFormat(buf, sizeof(buf), fmt, 2); // 2 = 第一个可变参数位置
    LogMessage("[hitsound-dbg] %s", buf);
}

static int SafeFetchInt(Handle hndl, int col)
{
    return (col < SQL_GetFieldCount(hndl)) ? SQL_FetchInt(hndl, col) : 0;
}
static void ClampSetSnd(int &v)
{
    if (v < 0) v = 0;
    // 有效范围 1..g_SetCount
    if (v > g_SetCount) v = 0;
}
static void ClampSetIc(int &v)
{
    if (v < 0) v = 0;
    // 有效范围 1..g_OvCount
    if (v > g_OvCount) v = 0;
}
static void MarkDirtyAndSave(int client)
{
    g_PrefsDirty[client] = true;

    if (GetConVarBool(cv_db_enable) && g_hDB != INVALID_HANDLE) {
        DB_SavePlayerPrefs(client);         // 不再要求 g_PrefsLoaded==true
        g_PrefsDirty[client] = false;
    } else {
        KV_SavePlayer(client);
        g_PrefsDirty[client] = false;
    }
}

static bool IsSpecialInfectedClient(int client)
{
    if (!IsValidClient(client) || GetClientTeam(client) != 3) return false;

    int zClass = GetEntProp(client, Prop_Send, "m_zombieClass");
    return (1 <= zClass && zClass <= 6) || zClass == 8;
}

static bool ShouldShowIconFeedback(int attacker, bool specialTarget)
{
    return !g_IcSpecialOnly[attacker] || specialTarget;
}

static bool ShouldPlaySoundFeedback(int attacker, bool specialTarget)
{
    return !g_SndSpecialOnly[attacker] || specialTarget;
}

// 根据“音效套装ID(1..N)”与类型取路径：which 0=headshot, 1=hit, 2=kill
static bool GetSoundPath_BySet(int setId, int which, char[] out, int maxlen)
{
    if (setId <= 0 || setId > g_SetCount) { out[0] = '\0'; return false; }
    int idx = setId - 1;
    if (which == 0)      GetArrayString(g_SetHeadshot, idx, out, maxlen);
    else if (which == 1) GetArrayString(g_SetHit,      idx, out, maxlen);
    else                 GetArrayString(g_SetKill,     idx, out, maxlen);
    return (out[0] != '\0');
}

// 根据“图标套装ID(1..N)”与类型取 base：which 0=head 1=hit 2=kill
static bool GetOverlayBase_BySet(int setId, int which, char[] out, int maxlen)
{
    if (setId <= 0 || setId > g_OvCount) { out[0]='\0'; return false; }
    int idx = setId - 1;
    if (which == 0)      GetArrayString(g_OvHead, idx, out, maxlen);
    else if (which == 1) GetArrayString(g_OvHit,  idx, out, maxlen);
    else                 GetArrayString(g_OvKill, idx, out, maxlen);
    return (out[0] != '\0');
}

static void ShowOverlayBySet(int client, int setId, int which)
{
    if (GetConVarInt(cv_pic_enable) == 0) return;
    if (setId <= 0) return;

    char base[PLATFORM_MAX_PATH];
    if (!GetOverlayBase_BySet(setId, which, base, sizeof(base))) return;

    char vmt[PLATFORM_MAX_PATH], vtf[PLATFORM_MAX_PATH];
    Format(vmt, sizeof(vmt), "%s.vmt", base);
    Format(vtf, sizeof(vtf), "%s.vtf", base);
    PrecacheDecal(vmt, true);
    PrecacheDecal(vtf, true);

    int iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
    SetCommandFlags("r_screenoverlay", iFlags);
    ClientCommand(client, "r_screenoverlay \"%s\"", base);

    if (g_taskClean[client] != INVALID_HANDLE) {
        KillTimer(g_taskClean[client]);
        g_taskClean[client] = INVALID_HANDLE;
    }
    g_taskClean[client] = CreateTimer(GetConVarFloat(cv_showtime), Timer_CleanOverlay, client);
}

// ========================================================
// Init
// ========================================================
public void OnPluginStart()
{
    char game[64];
    GetGameFolderName(game, sizeof(game));
    if (!StrEqual(game, "left4dead2", false))
    {
        SetFailState("本插件仅支持 L4D2!");
    }

    CreateConVar("l4d2_hitsound_plus_ver", PLUGIN_VERSION, "Plugin version", 0);

    cv_enable                 = CreateConVar("sm_hitsound_enable", "1", "是否开启本插件(0关,1开)", CVAR_FLAGS);
    cv_sound_enable           = CreateConVar("sm_hitsound_sound_enable", "1", "是否开启音效(0关,1开)", CVAR_FLAGS);
    cv_pic_enable             = CreateConVar("sm_hitsound_pic_enable", "1", "是否开启覆盖图标(0关,1开 总开关)", CVAR_FLAGS);
    cv_blast                  = CreateConVar("sm_blast_damage_enable", "0", "是否开启爆炸反馈提示(0关,1开 建议关)", CVAR_FLAGS);
    cv_showtime               = CreateConVar("sm_hitsound_showtime", "0.3", "覆盖图标显示时长(秒)", CVAR_FLAGS);
    cv_overlay_default_enable = CreateConVar("sm_hitsound_overlay_default", "1", "新玩家默认是否启用覆盖图(1给套装1,0禁用)", CVAR_FLAGS);

    cv_db_enable              = CreateConVar("sm_hitsound_db_enable", "1", "是否启用 RPG 表存储(1启用,0禁用)", CVAR_FLAGS);
    cv_db_conf                = CreateConVar("sm_hitsound_db_conf", "rpg", "databases.cfg 中的连接名", CVAR_FLAGS);
    cv_db_table               = CreateConVar("sm_hitsound_db_table", "RPG", "存储表名", CVAR_FLAGS);
    cv_debug                  = CreateConVar("sm_hitsound_debug", "0", "调试输出(0关,1开)", CVAR_FLAGS);

    // Fallback KV
    g_SoundStore = CreateKeyValues("SoundSelect6");
    BuildPath(Path_SM, g_SavePath, sizeof(g_SavePath), "data/SoundSelect.txt");
    if (FileExists(g_SavePath)) FileToKeyValues(g_SoundStore, g_SavePath);
    else KeyValuesToFile(g_SoundStore, g_SavePath);

    // Arrays
    g_SetNames    = CreateArray(64);
    g_SetHeadshot = CreateArray(PLATFORM_MAX_PATH);
    g_SetHit      = CreateArray(PLATFORM_MAX_PATH);
    g_SetKill     = CreateArray(PLATFORM_MAX_PATH);

    g_OvNames = CreateArray(64);
    g_OvHead  = CreateArray(PLATFORM_MAX_PATH);
    g_OvHit   = CreateArray(PLATFORM_MAX_PATH);
    g_OvKill  = CreateArray(PLATFORM_MAX_PATH);

    // Load configs
    LoadHitSoundSets();
    LoadHitIconSets();

    RegConsoleCmd("sm_snd",   Cmd_MenuMain, "主菜单：音效/图标套装（玩家）+ 特定开关 + 管理员单独设置");
    RegConsoleCmd("sm_hitui", Cmd_ToggleUI,  "快速在禁用与套装1间切换覆盖图三项");
    RegAdminCmd ("sm_hitsound_reload", Cmd_ReloadAll, ADMFLAG_ROOT, "重新从 DB/KV 读取所有在线玩家的偏好");

    AutoExecConfig(true, "l4d2_hitsound_plus");

    if (GetConVarInt(cv_enable) == 1)
    {
        HookEvent("infected_hurt",       Event_InfectedHurt,  EventHookMode_Pre);
        HookEvent("infected_death",      Event_InfectedDeath);
        HookEvent("player_death",        Event_PlayerDeath);
        HookEvent("player_hurt",         Event_PlayerHurt,    EventHookMode_Pre);
        HookEvent("tank_spawn",          Event_TankSpawn);
        HookEvent("player_spawn",        Event_PlayerSpawn);
        HookEvent("round_start",         Event_RoundStart,    EventHookMode_Post);
        HookEvent("player_incapacitated",Event_PlayerIncap);
    }
}

public void OnMapEnd()
{
    // flow offloading 已修复，不再需要换图时主动断连。
    DB_StopKeepAlive();

    if (g_taskDBRetry != INVALID_HANDLE)
    {
        KillTimer(g_taskDBRetry);
        g_taskDBRetry = INVALID_HANDLE;
    }

    // 不关闭 g_hDB，连接保持跨地图复用
    g_DBConnecting = false;
}

// 在执行完 cfg（例如加载模式/exec zonemod/药抗）后，重新加载在线玩家的偏好
public void OnConfigsExecuted()
{
    if (GetConVarBool(cv_db_enable) && g_hDB == INVALID_HANDLE)
    {
        StartDBConnect();
    }

    ReloadAllPlayersPrefs();
}

public void OnPluginEnd()
{
    DB_StopKeepAlive();

    if (g_taskDBRetry != INVALID_HANDLE)
    {
        KillTimer(g_taskDBRetry);
        g_taskDBRetry = INVALID_HANDLE;
    }

    if (g_hDB != INVALID_HANDLE)
    {
        CloseHandle(g_hDB);
        g_hDB = INVALID_HANDLE;
    }
}

// ========================================================
// Config loading
// ========================================================
void LoadHitSoundSets()
{
    ClearArray(g_SetNames);
    ClearArray(g_SetHeadshot);
    ClearArray(g_SetHit);
    ClearArray(g_SetKill);
    g_SetCount = 0;

    Handle kv = CreateKeyValues("HitSoundSets");
    if (!FileToKeyValues(kv, "addons/sourcemod/configs/hitsound_sets.cfg"))
    {
        // 未找到：依然允许“禁用=0”，但没有可选套装
        LogError("[hitsound] 未找到 hitsound_sets.cfg，只有禁用(0)可用。");
        CloseHandle(kv);
        return;
    }

    KvRewind(kv);
    if (KvGotoFirstSubKey(kv))
    {
        do {
            char name[64];
            char sh[PLATFORM_MAX_PATH], hi[PLATFORM_MAX_PATH], ki[PLATFORM_MAX_PATH];
            int  isbuiltin = 0;

            KvGetString(kv, "name", name, sizeof(name), "未命名音效套装");
            KvGetString(kv, "headshot", sh, sizeof(sh), "");
            KvGetString(kv, "hit",      hi, sizeof(hi), "");
            KvGetString(kv, "kill",     ki, sizeof(ki), "");
            isbuiltin = KvGetNum(kv, "builtin", 0);
            DBG("SoundSet #%d '%s' builtin=%d hs='%s' hit='%s' kill='%s'",
                g_SetCount+1, name, isbuiltin, sh, hi, ki);

            PushArrayString(g_SetNames, name);
            PushArrayString(g_SetHeadshot, sh);
            PushArrayString(g_SetHit, hi);
            PushArrayString(g_SetKill, ki);
            g_SetCount++;

            if (!isbuiltin)
            {
                if (sh[0] != '\0') { char p[PLATFORM_MAX_PATH]; Format(p, sizeof(p), "sound/%s", sh); DBG("FDL add: %s", p); AddFileToDownloadsTable(p); }
                if (hi[0] != '\0') { char p[PLATFORM_MAX_PATH]; Format(p, sizeof(p), "sound/%s", hi); DBG("FDL add: %s", p); AddFileToDownloadsTable(p); }
                if (ki[0] != '\0') { char p[PLATFORM_MAX_PATH]; Format(p, sizeof(p), "sound/%s", ki); DBG("FDL add: %s", p); AddFileToDownloadsTable(p); }
            }
            else
            {
                if (sh[0] != '\0') DBG("FDL skip(builtin): sound/%s", sh);
                if (hi[0] != '\0') DBG("FDL skip(builtin): sound/%s", hi);
                if (ki[0] != '\0') DBG("FDL skip(builtin): sound/%s", ki);
            }
        } while (KvGotoNextKey(kv));
    }
    CloseHandle(kv);

    LogMessage("[hitsound] 已加载 %d 套音效配置。", g_SetCount);
}

void LoadHitIconSets()
{
    ClearArray(g_OvNames);
    ClearArray(g_OvHead);
    ClearArray(g_OvHit);
    ClearArray(g_OvKill);
    g_OvCount = 0;

    Handle kv = CreateKeyValues("HitIconSets");
    if (!FileToKeyValues(kv, "addons/sourcemod/configs/hiticon_sets.cfg"))
    {
        LogMessage("[hitsound] 未找到 hiticon_sets.cfg，玩家仅可选择禁用(0)。");
        CloseHandle(kv);
        return;
    }

    KvRewind(kv);
    if (KvGotoFirstSubKey(kv))
    {
        do {
            char name[64];
            char head[PLATFORM_MAX_PATH], hit[PLATFORM_MAX_PATH], kill[PLATFORM_MAX_PATH];
            int  isbuiltin = 0;

            KvGetString(kv, "name", name, sizeof(name), "未命名图标套装");
            // 支持 headshot/head
            KvGetString(kv, "head", head, sizeof(head), "");
            if (head[0] == '\0') KvGetString(kv, "headshot", head, sizeof(head), "");
            KvGetString(kv, "hit",  hit,  sizeof(hit),  "");
            KvGetString(kv, "kill", kill, sizeof(kill), "");
            isbuiltin = KvGetNum(kv, "builtin", 0);
            DBG("IconSet  #%d '%s' builtin=%d head='%s' hit='%s' kill='%s'",
                g_OvCount+1, name, isbuiltin, head, hit, kill);

            PushArrayString(g_OvNames, name);
            PushArrayString(g_OvHead, head);
            PushArrayString(g_OvHit, hit);
            PushArrayString(g_OvKill, kill);
            g_OvCount++;

            if (!isbuiltin)
            {
                if (head[0] != '\0') {
                    char p1[PLATFORM_MAX_PATH]; Format(p1, sizeof(p1), "materials/%s.vmt", head); DBG("FDL add: %s", p1); AddFileToDownloadsTable(p1);
                    char p2[PLATFORM_MAX_PATH]; Format(p2, sizeof(p2), "materials/%s.vtf", head); DBG("FDL add: %s", p2); AddFileToDownloadsTable(p2);
                }
                if (hit[0] != '\0') {
                    char p1[PLATFORM_MAX_PATH]; Format(p1, sizeof(p1), "materials/%s.vmt", hit);  DBG("FDL add: %s", p1); AddFileToDownloadsTable(p1);
                    char p2[PLATFORM_MAX_PATH]; Format(p2, sizeof(p2), "materials/%s.vtf", hit);  DBG("FDL add: %s", p2); AddFileToDownloadsTable(p2);
                }
                if (kill[0] != '\0') {
                    char p1[PLATFORM_MAX_PATH]; Format(p1, sizeof(p1), "materials/%s.vmt", kill); DBG("FDL add: %s", p1); AddFileToDownloadsTable(p1);
                    char p2[PLATFORM_MAX_PATH]; Format(p2, sizeof(p2), "materials/%s.vtf", kill); DBG("FDL add: %s", p2); AddFileToDownloadsTable(p2);
                }
            }
            else
            {
                if (head[0] != '\0') { DBG("FDL skip(builtin): materials/%s.vmt", head); DBG("FDL skip(builtin): materials/%s.vtf", head); }
                if (hit[0]  != '\0') { DBG("FDL skip(builtin): materials/%s.vmt", hit ); DBG("FDL skip(builtin): materials/%s.vtf", hit ); }
                if (kill[0] != '\0') { DBG("FDL skip(builtin): materials/%s.vmt", kill); DBG("FDL skip(builtin): materials/%s.vtf", kill); }
            }
        } while (KvGotoNextKey(kv));
    }
    CloseHandle(kv);

    LogMessage("[hitsound] 已加载 %d 套图标覆盖主题（0=禁用）。", g_OvCount);
}

// ========================================================
// DB Connect callback
// ========================================================
static void StartDBConnect()
{
    if (!GetConVarBool(cv_db_enable)) return;
    if (g_hDB != INVALID_HANDLE || g_DBConnecting) return;

    char confName[32];
    GetConVarString(cv_db_conf, confName, sizeof(confName));
    TrimString(confName);

    if (!SQL_CheckConfig(confName))
    {
        LogError("[hitsound] databases.cfg 缺少 '%s' 配置。", confName);
        ScheduleDBConnectRetry();
        return;
    }

    g_DBConnecting = true;

    char error[256];
    g_hDB = SQL_Connect(confName, false, error, sizeof(error));
    g_DBConnecting = false;

    if (g_hDB == INVALID_HANDLE)
    {
        LogError("[hitsound] 数据库连接失败: %s", error);
        ScheduleDBConnectRetry();
        return;
    }

    g_DBRetryCount = 0;
    if (!SQL_SetCharset(g_hDB, "utf8mb4"))
        LogError("[hitsound] 设置数据库字符集 utf8mb4 失败。");
    SQL_FastQuery(g_hDB, "SET NAMES 'utf8mb4'");

    LogMessage("[hitsound] 数据库连接成功。");

    DB_StartKeepAlive();
    DB_EnsureExtraColumns();

    // 插件重载/晚加载时，在线玩家不会触发 OnClientPutInServer，这里主动补一次
    ReloadAllPlayersPrefs();
}

static void ScheduleDBConnectRetry()
{
    if (!GetConVarBool(cv_db_enable)) return;
    if (g_hDB != INVALID_HANDLE) return;
    if (g_taskDBRetry != INVALID_HANDLE) return;

    g_DBRetryCount++;
    g_taskDBRetry = CreateTimer(DB_CONNECT_RETRY_DELAY, Timer_RetryDBConnect);
}

public Action Timer_RetryDBConnect(Handle timer, any data)
{
    g_taskDBRetry = INVALID_HANDLE;
    StartDBConnect();
    return Plugin_Stop;
}

bool DB_IsConnectionLostError(const char[] error)
{
    return StrContains(error, "Lost connection", false) != -1
        || StrContains(error, "server has gone away", false) != -1;
}

void DB_MarkConnectionLost(const char[] error)
{
    if (!DB_IsConnectionLostError(error))
        return;

    DB_StopKeepAlive();

    if (g_hDB != INVALID_HANDLE)
    {
        CloseHandle(g_hDB);
        g_hDB = INVALID_HANDLE;
    }

    ScheduleDBConnectRetry();
}

/* -------------------- KeepAlive -------------------- */
static void DB_StartKeepAlive()
{
    if (g_taskDBKeepAlive != INVALID_HANDLE)
        return;
    g_taskDBKeepAlive = CreateTimer(DB_KEEPALIVE_INTERVAL, Timer_HitsoundKeepAlive, _, TIMER_REPEAT);
}

static void DB_StopKeepAlive()
{
    if (g_taskDBKeepAlive == INVALID_HANDLE)
        return;
    KillTimer(g_taskDBKeepAlive);
    g_taskDBKeepAlive = INVALID_HANDLE;
}

public Action Timer_HitsoundKeepAlive(Handle timer, any data)
{
    if (g_hDB == INVALID_HANDLE)
    {
        g_taskDBKeepAlive = INVALID_HANDLE;
        return Plugin_Stop;
    }
    SQL_TQuery(g_hDB, SQLCB_HitsoundKeepAlive, "SELECT 1", _, DBPrio_Low);
    return Plugin_Continue;
}

public void SQLCB_HitsoundKeepAlive(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == INVALID_HANDLE && error[0] != '\0')
    {
        LogError("[hitsound] KeepAlive failed: %s", error);
        DB_MarkConnectionLost(error);
    }
}

// ========================================================
// Persistence: DB + Fallback
// ========================================================
static void DB_EnsureExtraColumns()
{
    if (g_hDB == INVALID_HANDLE) return;

    char table[64];
    GetConVarString(cv_db_table, table, sizeof(table));

    DB_EnsureExtraColumn(table, "hitsound_si_only");
    DB_EnsureExtraColumn(table, "hiticon_si_only");
}

static void DB_EnsureExtraColumn(const char[] table, const char[] column)
{
    char q[256];
    Format(q, sizeof(q),
        "ALTER TABLE `%s` ADD COLUMN `%s` TINYINT NOT NULL DEFAULT 0;",
        table, column);
    SQL_TQuery(g_hDB, SQL_OnEnsureColumn, q);
}

public void SQL_OnEnsureColumn(Handle owner, Handle hndl, const char[] error, any data)
{
    if ((hndl == INVALID_HANDLE || error[0] != '\0')
        && StrContains(error, "Duplicate column", false) == -1
        && StrContains(error, "duplicate column", false) == -1)
    {
        if (DB_IsConnectionLostError(error))
        {
            DB_MarkConnectionLost(error);
            return;
        }

        LogError("[hitsound] 自动补充数据库列失败: %s", error);
    }
}

public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client)) return;

    // 最近套装（仅内存）
    g_SndSuite[client] = 0;
    g_IcSuite [client] = (GetConVarBool(cv_overlay_default_enable) && g_OvCount >= 1) ? 1 : 0;

    // 六字段默认
    g_SndHead[client] = 0;
    g_SndHit [client] = 0;
    g_SndKill[client] = 0;

    if (g_IcSuite[client] >= 1) {
        g_IcHead[client] = g_IcSuite[client];
        g_IcHit [client] = g_IcSuite[client];
        g_IcKill[client] = g_IcSuite[client];
    } else {
        g_IcHead[client] = g_IcHit[client] = g_IcKill[client] = 0;
    }

    g_SndSpecialOnly[client] = false;
    g_IcSpecialOnly [client] = false;

    g_PrefsLoaded[client] = false;
    g_PrefsDirty [client] = false;
    g_LoadRetryCount[client] = 0;

    if (GetConVarBool(cv_db_enable) && g_hDB != INVALID_HANDLE)
    {
        TryLoadPlayerPrefs(client);
    }
    else
    {
        ScheduleLoadRetry(client);
    }
}

public void OnClientAuthorized(int client, const char[] auth)
{
    if (client <= 0 || client > MaxClients || IsFakeClient(client)) return;
    if (!IsClientInGame(client)) return;
    if (g_PrefsLoaded[client]) return;

    if (GetConVarBool(cv_db_enable))
        TryLoadPlayerPrefs(client);
}

public void OnClientDisconnect(int client)
{
    if (IsFakeClient(client)) return;

    if (GetConVarBool(cv_db_enable) && g_hDB != INVALID_HANDLE)
    {
        if (g_PrefsLoaded[client] && g_PrefsDirty[client])
        {
            DB_SavePlayerPrefs(client);
        }
    }
    else
    {
        if (g_PrefsDirty[client])
        {
            KV_SavePlayer(client);
        }
    }

    if (g_taskClean[client] != INVALID_HANDLE)
    {
        KillTimer(g_taskClean[client]);
        g_taskClean[client] = INVALID_HANDLE;
    }
    if (g_taskLoadRetry[client] != INVALID_HANDLE)
    {
        KillTimer(g_taskLoadRetry[client]);
        g_taskLoadRetry[client] = INVALID_HANDLE;
    }

    g_PrefsLoaded[client] = false;
    g_PrefsDirty [client] = false;
    g_LoadRetryCount[client] = 0;
}

static void ScheduleLoadRetry(int client)
{
    if (client <= 0 || client > MaxClients) return;
    if (!IsClientInGame(client) || IsFakeClient(client)) return;
    if (g_PrefsLoaded[client]) return;
    if (!GetConVarBool(cv_db_enable))
    {
        KV_LoadPlayer(client);
        g_PrefsLoaded[client] = true;
        g_PrefsDirty [client] = false;
        return;
    }
    if (g_LoadRetryCount[client] >= DB_LOAD_RETRY_MAX)
    {
        LogError("[hitsound] 玩家 %N 的数据库配置加载重试超时，临时使用 KV/default。", client);
        KV_LoadPlayer(client);
        g_PrefsLoaded[client] = true;
        g_PrefsDirty [client] = false;
        return;
    }
    if (g_taskLoadRetry[client] != INVALID_HANDLE) return;

    g_LoadRetryCount[client]++;
    g_taskLoadRetry[client] = CreateTimer(DB_LOAD_RETRY_DELAY, Timer_RetryLoadPrefs, GetClientUserId(client));
}

public Action Timer_RetryLoadPrefs(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client <= 0 || !IsClientInGame(client))
        return Plugin_Stop;

    g_taskLoadRetry[client] = INVALID_HANDLE;
    TryLoadPlayerPrefs(client);
    return Plugin_Stop;
}

static void TryLoadPlayerPrefs(int client)
{
    if (client <= 0 || client > MaxClients) return;
    if (!IsClientInGame(client) || IsFakeClient(client)) return;
    if (g_PrefsLoaded[client]) return;

    if (!GetConVarBool(cv_db_enable))
    {
        KV_LoadPlayer(client);
        g_PrefsLoaded[client] = true;
        g_PrefsDirty [client] = false;
        return;
    }

    if (g_hDB == INVALID_HANDLE)
    {
        StartDBConnect();
        ScheduleLoadRetry(client);
        return;
    }

    char sid[64];
    if (!GetClientAuthId(client, AuthId_Steam2, sid, sizeof(sid), true) || sid[0] == '\0')
    {
        ScheduleLoadRetry(client);
        return;
    }

    DB_RequestLoadPlayer(client, sid);
}

// 主动为一个玩家发起 DB 读取
public void DB_RequestLoadPlayer(int client, const char[] sid)
{
    char table[64];
    GetConVarString(cv_db_table, table, sizeof(table));

    char q[512];
    Format(q, sizeof(q),
        "SELECT \
           hitsound_head, hitsound_hit, hitsound_kill, \
           hiticon_head,  hiticon_hit,  hiticon_kill, \
           hitsound_si_only, hiticon_si_only \
         FROM `%s` \
         WHERE steamid='%s' \
         LIMIT 1;",
        table, sid);

    SQL_TQuery(g_hDB, SQL_OnLoadPrefs, q, GetClientUserId(client));
}

// 为所有在线玩家重新加载偏好（插件重载 / 执行模式 cfg 后调用）
public void ReloadAllPlayersPrefs()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;

        g_PrefsLoaded[i] = false;
        g_PrefsDirty [i] = false;

        if (GetConVarBool(cv_db_enable) && g_hDB != INVALID_HANDLE)
        {
            TryLoadPlayerPrefs(i);
        }
        else
        {
            ScheduleLoadRetry(i);
        }
    }
}

public void SQL_OnLoadPrefs(Handle owner, Handle hndl, const char[] error, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client <= 0 || !IsClientInGame(client)) return;

    if (hndl == INVALID_HANDLE)
    {
        if (DB_IsConnectionLostError(error))
            DB_MarkConnectionLost(error);
        else
            LogError("[hitsound] 加载玩家配置失败: %s", error);
        ScheduleLoadRetry(client);
        return;
    }

    if (SQL_GetRowCount(hndl) > 0 && SQL_FetchRow(hndl))
    {
        int hs_head = SafeFetchInt(hndl, 0);
        int hs_hit  = SafeFetchInt(hndl, 1);
        int hs_kill = SafeFetchInt(hndl, 2);
        int ic_head = SafeFetchInt(hndl, 3);
        int ic_hit  = SafeFetchInt(hndl, 4);
        int ic_kill = SafeFetchInt(hndl, 5);
        int snd_si_only = SafeFetchInt(hndl, 6);
        int ic_si_only  = SafeFetchInt(hndl, 7);

        ClampSetSnd(hs_head); ClampSetSnd(hs_hit); ClampSetSnd(hs_kill);
        ClampSetIc (ic_head); ClampSetIc (ic_hit); ClampSetIc (ic_kill);

        g_SndHead[client] = hs_head;
        g_SndHit [client] = hs_hit;
        g_SndKill[client] = hs_kill;

        g_IcHead [client] = ic_head;
        g_IcHit  [client] = ic_hit;
        g_IcKill [client] = ic_kill;

        g_SndSpecialOnly[client] = (snd_si_only != 0);
        g_IcSpecialOnly [client] = (ic_si_only != 0);

        // 推断最近套装（三项相同才记录）
        if (g_SndHead[client]>0 && g_SndHead[client]==g_SndHit[client] && g_SndHead[client]==g_SndKill[client])
            g_SndSuite[client] = g_SndHead[client];
        if (g_IcHead[client]>0 && g_IcHead[client]==g_IcHit[client] && g_IcHead[client]==g_IcKill[client])
            g_IcSuite[client] = g_IcHead[client];

        g_PrefsLoaded[client] = true;
        g_PrefsDirty [client] = false;
        g_LoadRetryCount[client] = 0;
    }
    else
    {
        // 无行：不立即 insert，等玩家改动时再写库
        g_PrefsLoaded[client] = true;
        g_PrefsDirty [client] = false;
        g_LoadRetryCount[client] = 0;
    }
}

void DB_SavePlayerPrefs(int client)
{
    if (g_hDB == INVALID_HANDLE) return;

    char sid[64]; GetClientAuthId(client, AuthId_Steam2, sid, sizeof(sid), true);
    char table[64]; GetConVarString(cv_db_table, table, sizeof(table));

    int hs_head = g_SndHead[client], hs_hit = g_SndHit[client], hs_kill = g_SndKill[client];
    int ic_head = g_IcHead [client], ic_hit = g_IcHit [client], ic_kill = g_IcKill[client];
    int snd_si_only = g_SndSpecialOnly[client] ? 1 : 0;
    int ic_si_only  = g_IcSpecialOnly [client] ? 1 : 0;

    char q[1536];
    Format(q, sizeof(q),
        "INSERT INTO `%s` ( \
            steamid, hitsound_head, hitsound_hit, hitsound_kill, \
            hiticon_head, hiticon_hit, hiticon_kill, \
            hitsound_si_only, hiticon_si_only \
        ) \
        VALUES ('%s', %d, %d, %d, %d, %d, %d, %d, %d) \
        ON DUPLICATE KEY UPDATE \
            hitsound_head=VALUES(hitsound_head), \
            hitsound_hit =VALUES(hitsound_hit), \
            hitsound_kill=VALUES(hitsound_kill), \
            hiticon_head =VALUES(hiticon_head), \
            hiticon_hit  =VALUES(hiticon_hit), \
            hiticon_kill =VALUES(hiticon_kill), \
            hitsound_si_only=VALUES(hitsound_si_only), \
            hiticon_si_only =VALUES(hiticon_si_only);",
        table, sid, hs_head, hs_hit, hs_kill, ic_head, ic_hit, ic_kill, snd_si_only, ic_si_only);

    SQL_TQuery(g_hDB, SQL_OnSavePrefs, q, GetClientUserId(client));
}

public void SQL_OnSavePrefs(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == INVALID_HANDLE)
    {
        int client = GetClientOfUserId(data);
        if (client > 0 && IsClientInGame(client))
            g_PrefsDirty[client] = true;

        if (DB_IsConnectionLostError(error))
            DB_MarkConnectionLost(error);
        else
            LogError("[hitsound] 保存玩家配置失败: %s", error);
    }
}

// KeyValues fallback
void KV_SavePlayer(int client)
{
    char uid[128] = "";
    GetClientAuthId(client, AuthId_Engine, uid, sizeof(uid), true);

    KvJumpToKey(g_SoundStore, uid, true);

    KvSetNum(g_SoundStore, "SndSuite", g_SndSuite[client]);
    KvSetNum(g_SoundStore, "IcSuite",  g_IcSuite[client]);

    KvSetNum(g_SoundStore, "SndHead", g_SndHead[client]);
    KvSetNum(g_SoundStore, "SndHit",  g_SndHit[client]);
    KvSetNum(g_SoundStore, "SndKill", g_SndKill[client]);

    KvSetNum(g_SoundStore, "IcHead",  g_IcHead[client]);
    KvSetNum(g_SoundStore, "IcHit",   g_IcHit[client]);
    KvSetNum(g_SoundStore, "IcKill",  g_IcKill[client]);

    KvSetNum(g_SoundStore, "SndSpecialOnly", g_SndSpecialOnly[client] ? 1 : 0);
    KvSetNum(g_SoundStore, "IcSpecialOnly",  g_IcSpecialOnly [client] ? 1 : 0);

    KvGoBack(g_SoundStore);
    KvRewind(g_SoundStore);
    KeyValuesToFile(g_SoundStore, g_SavePath);
}

void KV_LoadPlayer(int client)
{
    char uid[128] = "";
    GetClientAuthId(client, AuthId_Engine, uid, sizeof(uid), true);

    KvJumpToKey(g_SoundStore, uid, true);

    g_SndSuite[client] = KvGetNum(g_SoundStore, "SndSuite", 0);
    g_IcSuite [client] = KvGetNum(g_SoundStore, "IcSuite",
        (GetConVarBool(cv_overlay_default_enable) && g_OvCount >= 1) ? 1 : 0 );

    g_SndHead[client] = KvGetNum(g_SoundStore, "SndHead", 0);
    g_SndHit [client] = KvGetNum(g_SoundStore, "SndHit",  0);
    g_SndKill[client] = KvGetNum(g_SoundStore, "SndKill", 0);

    g_IcHead[client]  = KvGetNum(g_SoundStore, "IcHead", 0);
    g_IcHit [client]  = KvGetNum(g_SoundStore, "IcHit",  0);
    g_IcKill[client]  = KvGetNum(g_SoundStore, "IcKill", 0);

    g_SndSpecialOnly[client] = (KvGetNum(g_SoundStore, "SndSpecialOnly", 0) != 0);
    g_IcSpecialOnly [client] = (KvGetNum(g_SoundStore, "IcSpecialOnly",  0) != 0);

    // 兼容旧 KV 键：若音效三项全0，尝试旧 Snd
    if (g_SndHead[client]==0 && g_SndHit[client]==0 && g_SndKill[client]==0) {
        int old = KvGetNum(g_SoundStore, "Snd", 0);
        if (old>0 && old<=g_SetCount) g_SndHead[client]=g_SndHit[client]=g_SndKill[client]=old;
    }
    // 兼容旧 KV 键：若图标三项全0，若 IcSuite>=1 就给三项=IcSuite；否则尝试旧 Overlay
    if (g_IcHead[client]==0 && g_IcHit[client]==0 && g_IcKill[client]==0) {
        if (g_IcSuite[client]>=1) {
            g_IcHead[client]=g_IcHit[client]=g_IcKill[client]=g_IcSuite[client];
        } else {
            int oldOv = KvGetNum(g_SoundStore, "Overlay", 0);
            if (oldOv>0 && oldOv<=g_OvCount) g_IcHead[client]=g_IcHit[client]=g_IcKill[client]=oldOv;
        }
    }

    KvGoBack(g_SoundStore);
    KvRewind(g_SoundStore);
}

// ========================================================
// Events
// ========================================================
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client > 0 && client <= MaxClients)
        g_IsVictimDeadPlayer[client] = false;
}

public Action Event_PlayerIncap(Handle event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    if (IsValidClient(victim) && GetClientTeam(victim) == 3 && GetEntProp(victim, Prop_Send, "m_zombieClass") == 8)
        g_IsVictimDeadPlayer[victim] = true;
    return Plugin_Continue;
}

public Action Event_TankSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    int tank = GetClientOfUserId(GetEventInt(event, "userid"));
    if (IsValidClient(tank))
        g_IsVictimDeadPlayer[tank] = false;
    return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    int victim     = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker   = GetClientOfUserId(GetEventInt(event, "attacker"));
    bool headshot  = GetEventBool(event, "headshot");
    int  damagetype= GetEventInt(event, "type");

    if (damagetype & DMG_DIRECT) return Plugin_Changed;
    if (GetConVarInt(cv_blast) == 0 && (damagetype & DMG_BLAST)) return Plugin_Changed;

    if (IsValidClient(victim) && GetClientTeam(victim) == 3 &&
        IsValidClient(attacker) && GetClientTeam(attacker) == 2 && !IsFakeClient(attacker))
    {
        bool specialTarget = IsSpecialInfectedClient(victim);

        // 图标（按项）
        if (GetConVarInt(cv_pic_enable) == 1 && ShouldShowIconFeedback(attacker, specialTarget))
        {
            int setId = headshot ? g_IcHead[attacker] : g_IcKill[attacker];
            if (setId > 0) ShowOverlayBySet(attacker, setId, headshot ? 0 : 2);
        }

        // 音效（按项）
        if (GetConVarInt(cv_sound_enable) == 1 && ShouldPlaySoundFeedback(attacker, specialTarget))
        {
            char s[PLATFORM_MAX_PATH];
            int setId = headshot ? g_SndHead[attacker] : g_SndKill[attacker];
            if (setId > 0 && GetSoundPath_BySet(setId, headshot ? 0 : 2, s, sizeof(s)))
            {
                PrecacheSound(s, true);
                EmitSoundToClient(attacker, s, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
            }
        }
    }

    return Plugin_Continue;
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
    int victim     = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker   = GetClientOfUserId(GetEventInt(event, "attacker"));
    int dmg        = GetEventInt(event, "dmg_health");
    int health     = GetEventInt(event, "health");
    int damagetype = GetEventInt(event, "type");

    char weapon[64]; GetEventString(event, "weapon", weapon, sizeof(weapon));
    bool inferno = (StrEqual(weapon, "entityflame", false) || StrEqual(weapon, "inferno", false));

    if (damagetype & DMG_DIRECT) return Plugin_Changed;
    if (GetConVarInt(cv_blast) == 0 && (damagetype & DMG_BLAST)) return Plugin_Changed;

    if (IsValidClient(victim) && IsValidClient(attacker) && !IsFakeClient(attacker) && GetClientTeam(victim) == 3)
    {
        bool specialTarget = IsSpecialInfectedClient(victim);
        float AddDamage = 0.0;
        if (RoundToNearest(float(health - dmg) - AddDamage) <= 0.0)
            g_IsVictimDeadPlayer[victim] = true;

        if (!g_IsVictimDeadPlayer[victim])
        {
            // 图标：命中
            if (GetConVarInt(cv_pic_enable) == 1 && ShouldShowIconFeedback(attacker, specialTarget))
            {
                int setId = g_IcHit[attacker];
                if (setId > 0) ShowOverlayBySet(attacker, setId, 1);
            }

            // 音效：命中
            if (GetConVarInt(cv_sound_enable) == 1 && !inferno && ShouldPlaySoundFeedback(attacker, specialTarget))
            {
                char s2[PLATFORM_MAX_PATH];
                int setId = g_SndHit[attacker];
                if (setId > 0 && GetSoundPath_BySet(setId, 1, s2, sizeof(s2)))
                {
                    PrecacheSound(s2, true);
                    EmitSoundToClient(attacker, s2, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
                }
            }
        }
    }
    return Plugin_Changed;
}

public Action Event_InfectedDeath(Handle event, const char[] name, bool dontBroadcast)
{
    int attacker   = GetClientOfUserId(GetEventInt(event, "attacker"));
    bool headshot  = GetEventBool(event, "headshot");
    bool blast     = GetEventBool(event, "blast");
    int  weaponID  = GetEventInt(event, "weapon_id");

    if (weaponID == 0) return Plugin_Changed;
    if (GetConVarInt(cv_blast) == 0 && blast) return Plugin_Changed;

    if (IsValidClient(attacker) && GetClientTeam(attacker) == 2 && !IsFakeClient(attacker))
    {
        bool specialTarget = false;

        // 图标：击杀/爆头
        if (GetConVarInt(cv_pic_enable) == 1 && ShouldShowIconFeedback(attacker, specialTarget))
        {
            int setId = headshot ? g_IcHead[attacker] : g_IcKill[attacker];
            if (setId > 0) ShowOverlayBySet(attacker, setId, headshot ? 0 : 2);
        }

        // 音效：击杀/爆头
        if (GetConVarInt(cv_sound_enable) == 1 && ShouldPlaySoundFeedback(attacker, specialTarget))
        {
            char s[PLATFORM_MAX_PATH];
            int setId = headshot ? g_SndHead[attacker] : g_SndKill[attacker];
            if (setId > 0 && GetSoundPath_BySet(setId, headshot ? 0 : 2, s, sizeof(s)))
            {
                PrecacheSound(s, true);
                EmitSoundToClient(attacker, s, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
            }
        }
    }
    return Plugin_Continue;
}

public Action Event_InfectedHurt(Handle event, const char[] name, bool dontBroadcast)
{
    int victim     = GetEventInt(event, "entityid");
    int attacker   = GetClientOfUserId(GetEventInt(event, "attacker"));
    int dmg        = GetEventInt(event, "amount");
    int hp         = GetEntProp(victim, Prop_Data, "m_iHealth");
    int damagetype = GetEventInt(event, "type");

    if (damagetype & DMG_DIRECT) return Plugin_Changed;
    if (GetConVarInt(cv_blast) == 0 && (damagetype & DMG_BLAST)) return Plugin_Changed;

    if (IsValidClient(attacker) && !IsFakeClient(attacker))
    {
        bool specialTarget = false;
        bool dead = ((hp - dmg) <= 0);

        if (!dead)
        {
            // 图标：命中
            if (GetConVarInt(cv_pic_enable) == 1 && ShouldShowIconFeedback(attacker, specialTarget))
            {
                int setId = g_IcHit[attacker];
                if (setId > 0) ShowOverlayBySet(attacker, setId, 1);
            }

            // 音效：命中
            if (GetConVarInt(cv_sound_enable) == 1 && ShouldPlaySoundFeedback(attacker, specialTarget))
            {
                char s2[PLATFORM_MAX_PATH];
                int setId = g_SndHit[attacker];
                if (setId > 0 && GetSoundPath_BySet(setId, 1, s2, sizeof(s2)))
                {
                    PrecacheSound(s2, true);
                    EmitSoundToClient(attacker, s2, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
                }
            }
        }
    }
    return Plugin_Changed;
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    // 清理残留计时器
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_taskClean[i] != INVALID_HANDLE)
        {
            KillTimer(g_taskClean[i]);
            g_taskClean[i] = INVALID_HANDLE;
        }
    }
}

// ========================================================
// Overlay clean timer
// ========================================================
public Action Timer_CleanOverlay(Handle timer, int client)
{
    g_taskClean[client] = INVALID_HANDLE;

    int iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
    SetCommandFlags("r_screenoverlay", iFlags);
    ClientCommand(client, "r_screenoverlay \"\" ");

    return Plugin_Stop;
}

// ========================================================
// Map start: rebuild downloads + precache all
// ========================================================
public void OnMapStart()
{
    DBG("OnMapStart: rebuild downloads table (soundSets=%d, iconSets=%d)", g_SetCount, g_OvCount);
    LoadHitSoundSets();
    LoadHitIconSets();
    PrecacheAllAssets();
}

static void PrecacheAllAssets()
{
    // ---- Sounds ----
    char s[PLATFORM_MAX_PATH];
    for (int i = 0; i < g_SetCount; i++)
    {
        GetArrayString(g_SetHeadshot, i, s, sizeof(s));
        if (s[0]) PrecacheSound(s, true);

        GetArrayString(g_SetHit, i, s, sizeof(s));
        if (s[0]) PrecacheSound(s, true);

        GetArrayString(g_SetKill, i, s, sizeof(s));
        if (s[0]) PrecacheSound(s, true);
    }

    // ---- Overlays (materials) ----
    char b[PLATFORM_MAX_PATH], vmt[PLATFORM_MAX_PATH], vtf[PLATFORM_MAX_PATH];
    for (int j = 0; j < g_OvCount; j++)
    {
        GetArrayString(g_OvHead, j, b, sizeof(b));
        if (b[0]) {
            Format(vmt, sizeof(vmt), "%s.vmt", b); PrecacheDecal(vmt, true);
            Format(vtf, sizeof(vtf), "%s.vtf", b); PrecacheDecal(vtf, true);
        }

        GetArrayString(g_OvHit, j, b, sizeof(b));
        if (b[0]) {
            Format(vmt, sizeof(vmt), "%s.vmt", b); PrecacheDecal(vmt, true);
            Format(vtf, sizeof(vtf), "%s.vtf", b); PrecacheDecal(vtf, true);
        }

        GetArrayString(g_OvKill, j, b, sizeof(b));
        if (b[0]) {
            Format(vmt, sizeof(vmt), "%s.vmt", b); PrecacheDecal(vmt, true);
            Format(vtf, sizeof(vtf), "%s.vtf", b); PrecacheDecal(vtf, true);
        }
    }

    DBG("PrecacheAllAssets done: soundSets=%d, iconSets=%d", g_SetCount, g_OvCount);
}

// ========================================================
// Commands & Menus
// ========================================================
public Action Cmd_ToggleUI(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client)) return Plugin_Handled;

    // 在 0 与 套装1（若存在）之间切换图标三项
    if (g_OvCount >= 1)
    {
        bool turnOn = (g_IcHead[client]==0 && g_IcHit[client]==0 && g_IcKill[client]==0);
        int v = turnOn ? 1 : 0;
        g_IcSuite[client] = turnOn ? 1 : 0;
        g_IcHead[client]  = v;
        g_IcHit[client]   = v;
        g_IcKill[client]  = v;
        PrintToChat(client, "覆盖图标：%s（%s）", turnOn ? "开启" : "关闭", turnOn ? "套装1" : "禁用");
        MarkDirtyAndSave(client);
    }
    else
    {
        PrintToChat(client, "当前没有可用的图标套装。");
    }
    return Plugin_Handled;
}

public Action Cmd_ReloadAll(int client, int args)
{
    ReloadAllPlayersPrefs();
    if (client > 0)
        ReplyToCommand(client, "[hitsound] 已尝试重新读取所有在线玩家的设置。");
    return Plugin_Handled;
}

public Action Cmd_MenuMain(int client, int args)
{
    Handle menu = CreateMenu(MenuHandler_Main);
    char title[256];

    char sndHead[32], sndHit[32], sndKill[32];
    char icHead[32],  icHit[32],  icKill[32];
    char sndScope[16], icScope[16];

    if (g_SndHead[client] > 0 && g_SndHead[client] <= g_SetCount) GetArrayString(g_SetNames, g_SndHead[client]-1, sndHead, sizeof(sndHead)); else strcopy(sndHead, sizeof(sndHead), "关闭");
    if (g_SndHit [client] > 0 && g_SndHit [client] <= g_SetCount) GetArrayString(g_SetNames, g_SndHit [client]-1, sndHit,  sizeof(sndHit )); else strcopy(sndHit , sizeof(sndHit ), "关闭");
    if (g_SndKill[client] > 0 && g_SndKill[client] <= g_SetCount) GetArrayString(g_SetNames, g_SndKill[client]-1, sndKill, sizeof(sndKill)); else strcopy(sndKill, sizeof(sndKill), "关闭");

    if (g_IcHead[client]  > 0 && g_IcHead[client]  <= g_OvCount) GetArrayString(g_OvNames, g_IcHead[client]-1,  icHead, sizeof(icHead)); else strcopy(icHead, sizeof(icHead), "关闭");
    if (g_IcHit [client]  > 0 && g_IcHit [client]  <= g_OvCount) GetArrayString(g_OvNames, g_IcHit [client]-1,  icHit,  sizeof(icHit )); else strcopy(icHit , sizeof(icHit ), "关闭");
    if (g_IcKill[client]  > 0 && g_IcKill[client]  <= g_OvCount) GetArrayString(g_OvNames, g_IcKill[client]-1,  icKill, sizeof(icKill)); else strcopy(icKill, sizeof(icKill), "关闭");

    strcopy(sndScope, sizeof(sndScope), g_SndSpecialOnly[client] ? "仅特感" : "全部");
    strcopy(icScope,  sizeof(icScope),  g_IcSpecialOnly [client] ? "仅特感" : "全部");

    Format(title, sizeof(title),
        "命中反馈设置\n音效(爆头/命中/击杀): %s / %s / %s [%s]\n图标(爆头/命中/击杀): %s / %s / %s [%s]",
        sndHead, sndHit, sndKill, sndScope, icHead, icHit, icKill, icScope);
    SetMenuTitle(menu, title);

    // 玩家：按套装设置
    AddMenuItem(menu, "sound_sets", "音效套装（玩家）");
    AddMenuItem(menu, "icon_sets",  "图标套装（玩家）");

    // 快捷：一键开关图标三项（0 <-> 套装1）
    AddMenuItem(menu, "overlay_quick", "覆盖图标一键开关（玩家）");

    // 特定开关（非管理员也可用）：三项在 0 与 最近套装ID 之间切
    AddMenuItem(menu, "snd_toggle_each", "特定音效开关（命中/击杀/爆头）");
    AddMenuItem(menu, "ico_toggle_each", "特定图标开关（命中/击杀/爆头）");
    AddMenuItem(menu, "snd_special_only", g_SndSpecialOnly[client] ? "音效范围：仅特感/Tank" : "音效范围：全部感染者");
    AddMenuItem(menu, "ico_special_only", g_IcSpecialOnly [client] ? "图标范围：仅特感/Tank" : "图标范围：全部感染者");

    // 管理员专用：单独设置成任意套装ID（含 0=关闭）
    if (CheckCommandAccess(client, "hitsound_admin", ADMFLAG_GENERIC, true)) {
        AddMenuItem(menu, "snd_set_hit",      "击中音效单独设置 [管理员专用]");
        AddMenuItem(menu, "snd_set_kill",     "击杀音效单独设置 [管理员专用]");
        AddMenuItem(menu, "snd_set_headshot", "爆头音效单独设置 [管理员专用]");

        AddMenuItem(menu, "ico_set_hit",      "击中图标单独设置 [管理员专用]");
        AddMenuItem(menu, "ico_set_kill",     "击杀图标单独设置 [管理员专用]");
        AddMenuItem(menu, "ico_set_headshot", "爆头图标单独设置 [管理员专用]");
    }

    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public int MenuHandler_Main(Handle menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End) { CloseHandle(menu); }

    if (action == MenuAction_Select)
    {
        char info[32]; GetMenuItem(menu, item, info, sizeof(info));

        if (StrEqual(info, "sound_sets"))
        {
            OpenSoundSetMenu_Player(client);
            return 0;
        }
        if (StrEqual(info, "icon_sets"))
        {
            OpenIconSetMenu_Player(client);
            return 0;
        }
        if (StrEqual(info, "overlay_quick"))
        {
            Cmd_ToggleUI(client, 0);
            Cmd_MenuMain(client, 0);
            return 0;
        }
        if (StrEqual(info, "snd_toggle_each"))
        {
            OpenToggleEachMenu(client, true);
            return 0;
        }
        if (StrEqual(info, "ico_toggle_each"))
        {
            OpenToggleEachMenu(client, false);
            return 0;
        }
        if (StrEqual(info, "snd_special_only"))
        {
            g_SndSpecialOnly[client] = !g_SndSpecialOnly[client];
            PrintToChat(client, "音效范围：%s", g_SndSpecialOnly[client] ? "仅特感/Tank" : "全部感染者");
            MarkDirtyAndSave(client);
            Cmd_MenuMain(client, 0);
            return 0;
        }
        if (StrEqual(info, "ico_special_only"))
        {
            g_IcSpecialOnly[client] = !g_IcSpecialOnly[client];
            PrintToChat(client, "图标范围：%s", g_IcSpecialOnly[client] ? "仅特感/Tank" : "全部感染者");
            MarkDirtyAndSave(client);
            Cmd_MenuMain(client, 0);
            return 0;
        }

        // 管理员单独设置
        if (StrEqual(info, "snd_set_hit"))       { OpenAdminSelectSetMenu(client, true,  1); return 0; }
        if (StrEqual(info, "snd_set_kill"))      { OpenAdminSelectSetMenu(client, true,  2); return 0; }
        if (StrEqual(info, "snd_set_headshot"))  { OpenAdminSelectSetMenu(client, true,  0); return 0; }
        if (StrEqual(info, "ico_set_hit"))       { OpenAdminSelectSetMenu(client, false, 1); return 0; }
        if (StrEqual(info, "ico_set_kill"))      { OpenAdminSelectSetMenu(client, false, 2); return 0; }
        if (StrEqual(info, "ico_set_headshot"))  { OpenAdminSelectSetMenu(client, false, 0); return 0; }
    }
    return 0;
}

// ------------------ 子菜单：音效套装（玩家） ------------------
static void OpenSoundSetMenu_Player(int client)
{
    Handle m = CreateMenu(MenuHandler_SndSets_Player);
    char title[128];
    char cur[64] = "关闭";
    if (g_SndHead[client]>0 && g_SndHead[client]==g_SndHit[client] && g_SndHead[client]==g_SndKill[client] && g_SndHead[client] <= g_SetCount)
        GetArrayString(g_SetNames, g_SndHead[client]-1, cur, sizeof(cur));
    Format(title, sizeof(title), "选择音效套装（玩家，当前: %s）", cur);
    SetMenuTitle(m, title);

    AddMenuItem(m, "snd_0", "0 - 关闭三项音效");
    for (int i = 1; i <= g_SetCount; i++)
    {
        char key[16], name[64], label[96];
        Format(key, sizeof(key), "snd_%d", i);
        GetArrayString(g_SetNames, i-1, name, sizeof(name));
        Format(label, sizeof(label), "%d - %s", i, name);
        AddMenuItem(m, key, label);
    }

    SetMenuExitBackButton(m, true);
    DisplayMenu(m, client, MENU_TIME_FOREVER);
}

public int MenuHandler_SndSets_Player(Handle menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End) { CloseHandle(menu); }
    if (action == MenuAction_Cancel && item == MenuCancel_ExitBack)
    {
        Cmd_MenuMain(client, 0);
        return 0;
    }
    if (action == MenuAction_Select)
    {
        char info[16]; GetMenuItem(menu, item, info, sizeof(info));
        if (StrContains(info, "snd_", false) == 0)
        {
            ReplaceString(info, sizeof(info), "snd_", "");
            int val = StringToInt(info); // 0..g_SetCount
            if (val < 0) val = 0;
            if (val > g_SetCount) val = 0;

            g_SndSuite[client] = val; // 记住最近套装（非管理员开关用）
            g_SndHead[client] = g_SndHit[client] = g_SndKill[client] = val;

            PrintToChat(client, "[Hitsound] 音效套装(三项)已设置为: %d", val);
            MarkDirtyAndSave(client);

            OpenSoundSetMenu_Player(client);
        }
    }
    return 0;
}

// ------------------ 子菜单：图标套装（玩家） ------------------
static void OpenIconSetMenu_Player(int client)
{
    Handle m = CreateMenu(MenuHandler_OvSets_Player);
    char title[128];
    char cur[64] = "关闭";
    if (g_IcHead[client]>0 && g_IcHead[client]==g_IcHit[client] && g_IcHead[client]==g_IcKill[client] && g_IcHead[client] <= g_OvCount)
        GetArrayString(g_OvNames, g_IcHead[client]-1, cur, sizeof(cur));
    Format(title, sizeof(title), "选择图标套装（玩家，当前: %s）", cur);
    SetMenuTitle(m, title);

    AddMenuItem(m, "ov_0", "0 - 关闭三项图标");
    for (int i = 1; i <= g_OvCount; i++)
    {
        char key[16], name[64], label[96];
        Format(key, sizeof(key), "ov_%d", i);
        GetArrayString(g_OvNames, i-1, name, sizeof(name));
        Format(label, sizeof(label), "%d - %s", i, name);
        AddMenuItem(m, key, label);
    }

    SetMenuExitBackButton(m, true);
    DisplayMenu(m, client, MENU_TIME_FOREVER);
}

public int MenuHandler_OvSets_Player(Handle menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End) { CloseHandle(menu); }
    if (action == MenuAction_Cancel && item == MenuCancel_ExitBack)
    {
        Cmd_MenuMain(client, 0);
        return 0;
    }
    if (action == MenuAction_Select)
    {
        char info[16]; GetMenuItem(menu, item, info, sizeof(info));
        if (StrContains(info, "ov_", false) == 0)
        {
            ReplaceString(info, sizeof(info), "ov_", "");
            int val = StringToInt(info); // 0..g_OvCount
            if (val < 0) val = 0;
            if (val > g_OvCount) val = 0;

            g_IcSuite[client] = val; // 记住最近套装
            g_IcHead[client] = g_IcHit[client] = g_IcKill[client] = val;

            char name[64] = "关闭";
            if (val >= 1 && val <= g_OvCount) GetArrayString(g_OvNames, val-1, name, sizeof(name));
            PrintToChat(client, "[Hitsound] 图标套装(三项)已设置为: %d - %s", val, name);

            MarkDirtyAndSave(client);
            OpenIconSetMenu_Player(client);
        }
    }
    return 0;
}

// ------------------ 子菜单：特定开关（非管理员也可用） ------------------
static void OpenToggleEachMenu(int client, bool sound)
{
    Handle m = CreateMenu(MenuHandler_ToggleEach);
    SetMenuTitle(m, sound ? "特定音效开关" : "特定图标开关");

    AddMenuItem(m, sound ? "tgsnd_hit"  : "tgico_hit",      sound ? "命中音效 开/关" : "命中图标 开/关");
    AddMenuItem(m, sound ? "tgsnd_kill" : "tgico_kill",     sound ? "击杀音效 开/关" : "击杀图标 开/关");
    AddMenuItem(m, sound ? "tgsnd_head" : "tgico_head",     sound ? "爆头音效 开/关" : "爆头图标 开/关");

    SetMenuExitBackButton(m, true);
    DisplayMenu(m, client, MENU_TIME_FOREVER);
}

public int MenuHandler_ToggleEach(Handle menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End) { CloseHandle(menu); }
    if (action == MenuAction_Cancel && item == MenuCancel_ExitBack)
    {
        Cmd_MenuMain(client, 0);
        return 0;
    }
    if (action == MenuAction_Select)
    {
        char info[32]; GetMenuItem(menu, item, info, sizeof(info));

        // 音效三项
        if (StrEqual(info, "tgsnd_hit"))
        {
            if (g_SndHit[client] == 0) {
                if (g_SndSuite[client] <= 0) { PrintToChat(client, "请先在『音效套装（玩家）』里选择一个套装。"); }
                else { g_SndHit[client] = g_SndSuite[client]; PrintToChat(client, "命中音效：已开启（套装 %d）", g_SndHit[client]); MarkDirtyAndSave(client); }
            } else {
                g_SndHit[client] = 0; PrintToChat(client, "命中音效：已关闭"); MarkDirtyAndSave(client);
            }
            OpenToggleEachMenu(client, true);
            return 0;
        }
        if (StrEqual(info, "tgsnd_kill"))
        {
            if (g_SndKill[client] == 0) {
                if (g_SndSuite[client] <= 0) { PrintToChat(client, "请先在『音效套装（玩家）』里选择一个套装。"); }
                else { g_SndKill[client] = g_SndSuite[client]; PrintToChat(client, "击杀音效：已开启（套装 %d）", g_SndKill[client]); MarkDirtyAndSave(client); }
            } else {
                g_SndKill[client] = 0; PrintToChat(client, "击杀音效：已关闭"); MarkDirtyAndSave(client);
            }
            OpenToggleEachMenu(client, true);
            return 0;
        }
        if (StrEqual(info, "tgsnd_head"))
        {
            if (g_SndHead[client] == 0) {
                if (g_SndSuite[client] <= 0) { PrintToChat(client, "请先在『音效套装（玩家）』里选择一个套装。"); }
                else { g_SndHead[client] = g_SndSuite[client]; PrintToChat(client, "爆头音效：已开启（套装 %d）", g_SndHead[client]); MarkDirtyAndSave(client); }
            } else {
                g_SndHead[client] = 0; PrintToChat(client, "爆头音效：已关闭"); MarkDirtyAndSave(client);
            }
            OpenToggleEachMenu(client, true);
            return 0;
        }

        // 图标三项
        if (StrEqual(info, "tgico_hit"))
        {
            if (g_IcHit[client] == 0) {
                if (g_IcSuite[client] <= 0) { PrintToChat(client, "请先在『图标套装（玩家）』里选择一个套装。"); }
                else { g_IcHit[client] = g_IcSuite[client]; PrintToChat(client, "命中图标：已开启（套装 %d）", g_IcHit[client]); MarkDirtyAndSave(client); }
            } else {
                g_IcHit[client] = 0; PrintToChat(client, "命中图标：已关闭"); MarkDirtyAndSave(client);
            }
            OpenToggleEachMenu(client, false);
            return 0;
        }
        if (StrEqual(info, "tgico_kill"))
        {
            if (g_IcKill[client] == 0) {
                if (g_IcSuite[client] <= 0) { PrintToChat(client, "请先在『图标套装（玩家）』里选择一个套装。"); }
                else { g_IcKill[client] = g_IcSuite[client]; PrintToChat(client, "击杀图标：已开启（套装 %d）", g_IcKill[client]); MarkDirtyAndSave(client); }
            } else {
                g_IcKill[client] = 0; PrintToChat(client, "击杀图标：已关闭"); MarkDirtyAndSave(client);
            }
            OpenToggleEachMenu(client, false);
            return 0;
        }
        if (StrEqual(info, "tgico_head"))
        {
            if (g_IcHead[client] == 0) {
                if (g_IcSuite[client] <= 0) { PrintToChat(client, "请先在『图标套装（玩家）』里选择一个套装。"); }
                else { g_IcHead[client] = g_IcSuite[client]; PrintToChat(client, "爆头图标：已开启（套装 %d）", g_IcHead[client]); MarkDirtyAndSave(client); }
            } else {
                g_IcHead[client] = 0; PrintToChat(client, "爆头图标：已关闭"); MarkDirtyAndSave(client);
            }
            OpenToggleEachMenu(client, false);
            return 0;
        }
    }
    return 0;
}

// ------------------ 子菜单：管理员单项设置 ------------------
static void OpenAdminSelectSetMenu(int client, bool sound, int which) // which: 0=head/1=hit/2=kill
{
    if (!CheckCommandAccess(client, "hitsound_admin", ADMFLAG_GENERIC, true)) {
        PrintToChat(client, "你没有权限使用此菜单。");
        Cmd_MenuMain(client, 0);
        return;
    }

    Handle m = CreateMenu(MenuHandler_AdminPick);
    if (sound) {
        if (which==0) SetMenuTitle(m, "爆头音效：选择套装ID（含0=关闭）");
        if (which==1) SetMenuTitle(m, "命中音效：选择套装ID（含0=关闭）");
        if (which==2) SetMenuTitle(m, "击杀音效：选择套装ID（含0=关闭）");
    } else {
        if (which==0) SetMenuTitle(m, "爆头图标：选择套装ID（含0=关闭）");
        if (which==1) SetMenuTitle(m, "命中图标：选择套装ID（含0=关闭）");
        if (which==2) SetMenuTitle(m, "击杀图标：选择套装ID（含0=关闭）");
    }

    // 0=关闭
    AddMenuItem(m, sound ? "adm_snd_0" : "adm_ic_0", "0 - 关闭此项");

    int count = sound ? g_SetCount : g_OvCount;
    Handle arr = sound ? g_SetNames : g_OvNames;

    for (int i = 1; i <= count; i++)
    {
        char key[32], name[64], label[96];
        Format(key, sizeof(key), sound ? "adm_snd_%d_%d" : "adm_ic_%d_%d", which, i); // which + setId
        GetArrayString(arr, i-1, name, sizeof(name));
        Format(label, sizeof(label), "%d - %s", i, name);
        AddMenuItem(m, key, label);
    }

    SetMenuExitBackButton(m, true);
    DisplayMenu(m, client, MENU_TIME_FOREVER);
}

public int MenuHandler_AdminPick(Handle menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End) { CloseHandle(menu); }
    if (action == MenuAction_Cancel && item == MenuCancel_ExitBack)
    {
        Cmd_MenuMain(client, 0);
        return 0;
    }
    if (action == MenuAction_Select)
    {
        char info[32]; GetMenuItem(menu, item, info, sizeof(info));

        bool sound = (StrContains(info, "adm_snd_", false) == 0);
        bool icon  = (StrContains(info, "adm_ic_",  false) == 0);

        if (!sound && !icon) return 0;

        int which = 0;
        int setId = 0;

        if (sound) {
            // 可能是 "adm_snd_0" 或 "adm_snd_<which>_<setId>"
            if (StrEqual(info, "adm_snd_0")) { which = -1; setId = 0; }
            else {
                ReplaceString(info, sizeof(info), "adm_snd_", "");
                char parts[2][8];
                ExplodeString(info, "_", parts, sizeof(parts), sizeof(parts[]));
                which = StringToInt(parts[0]);
                setId = StringToInt(parts[1]);
            }
        } else if (icon) {
            if (StrEqual(info, "adm_ic_0")) { which = -1; setId = 0; }
            else {
                ReplaceString(info, sizeof(info), "adm_ic_", "");
                char parts[2][8];
                ExplodeString(info, "_", parts, sizeof(parts), sizeof(parts[]));
                which = StringToInt(parts[0]);
                setId = StringToInt(parts[1]);
            }
        }

        // 统一设置
        if (sound)
        {
            if (which == -1) { // 关闭单项需要知道是哪一项，这里统一为三项都关，请管理员回到主菜单单项分别设置。
                g_SndHead[client]=g_SndHit[client]=g_SndKill[client]=0;
                PrintToChat(client, "音效三项：已全部关闭");
            } else {
                ClampSetSnd(setId);
                if (which==0) { g_SndHead[client]=setId; PrintToChat(client, "爆头音效：已设置为 %d", setId); }
                if (which==1) { g_SndHit [client]=setId; PrintToChat(client, "命中音效：已设置为 %d", setId); }
                if (which==2) { g_SndKill[client]=setId; PrintToChat(client, "击杀音效：已设置为 %d", setId); }
                if (g_SndHead[client]>0 && g_SndHead[client]==g_SndHit[client] && g_SndHead[client]==g_SndKill[client]) g_SndSuite[client]=g_SndHead[client];
            }
        }
        else // icon
        {
            if (which == -1) {
                g_IcHead[client]=g_IcHit[client]=g_IcKill[client]=0;
                PrintToChat(client, "图标三项：已全部关闭");
            } else {
                ClampSetIc(setId);
                if (which==0) { g_IcHead[client]=setId; PrintToChat(client, "爆头图标：已设置为 %d", setId); }
                if (which==1) { g_IcHit [client]=setId; PrintToChat(client, "命中图标：已设置为 %d", setId); }
                if (which==2) { g_IcKill[client]=setId; PrintToChat(client, "击杀图标：已设置为 %d", setId); }
                if (g_IcHead[client]>0 && g_IcHead[client]==g_IcHit[client] && g_IcHead[client]==g_IcKill[client]) g_IcSuite[client]=g_IcHead[client];
            }
        }

        MarkDirtyAndSave(client);
        OpenAdminSelectSetMenu(client, sound, (which==-1?0:which));
    }
    return 0;
}
