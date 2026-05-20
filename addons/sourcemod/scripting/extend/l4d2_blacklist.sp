/*
 * L4D2 BlockList 1.3.1 (Auto MySQL/SQLite)
 * ---------------------------------------------------------
 * - DB & 配额 & 管理免疫 & 多语言 & 日志
 * - 菜单操作（sm_blmenu）
 * - 延迟生效（按“被屏蔽者”的会话）：
 *   黑名单仅在“被屏蔽者下次入服”生效；
 *   只要他本次会话没有断线，换图/过关都不生效、不踢。
 * - 自动兼容 MySQL / SQLite：连接后自动判断驱动并创建合适的表结构
 *
 * 作者: morzlee / ChatGPT
 * 依赖: SourceMod 1.10+（SQLite 或 MySQL）
 * 译文: 需要 translations/l4d2_blocklist.phrases.txt（UTF-8 无 BOM）
 * 编译: spcomp l4d2_blocklist_1_3_1_mysql_auto.sp
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_NAME        "L4D2 BlockList"
#define PLUGIN_AUTHOR      "morzlee"
#define PLUGIN_DESC        "DB-based per-player join block with limits, admin immunity, i18n, logging, menus, delayed activation (by blocked user's session), MySQL/SQLite auto"
#define PLUGIN_VERSION     "1.3.1"

public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESC,
    version     = PLUGIN_VERSION,
    url         = "https://github.com/fantasylidong/CompetitiveWithAnne"
};

/* -------------------- ConVars -------------------- */
Handle g_hDb = INVALID_HANDLE;

ConVar gCvarEnable;
ConVar gCvarDBSection;
ConVar gCvarTableName;
ConVar gCvarKickMsg;
ConVar gCvarLimitUser;
ConVar gCvarLimitAdmin;
ConVar gCvarAdminFlag;
ConVar gCvarConsiderTeams;

ConVar gCvarImmuneFlag;    // 拥有该 flag 的“加入者”免疫屏蔽检查
ConVar gCvarQuiet;         // 静音（不通知触发者）
ConVar gCvarExposeBlocker; // 是否在踢出提示里暴露屏蔽者ID
ConVar gCvarLogEnable;
ConVar gCvarLogFile;
ConVar gCvarUseI18NKick;   // 踢出提示使用翻译短语

char g_sTable[64]      = "player_blocks";
char g_sKickMsg[192]   = "这个服务器有人屏蔽了你，无法进入。";
char g_sDBSection[64]  = "l4dstats";
char g_sLogFile[64]    = "l4d2_blocklist.log";

int  g_iLimitUser      = 20;
int  g_iLimitAdmin     = 100;
int  g_iAdminFlags     = 0;    // 享受管理员上限
int  g_iImmuneFlags    = 0;    // 加入免疫
bool g_bConsiderTeamsOnly = true; // 只考虑在场游玩(2/3)玩家
bool g_bQuiet          = true;
bool g_bExposeBlocker  = false;
bool g_bLogEnable      = true;
bool g_bUseI18NForKick = true;

// 互斥（双向不共存）
ConVar gCvarMutual;
bool g_bMutual = true;

/* 以 SteamID64 为键，记录“该玩家本次在服会话开始时间”。
 * 仅在首次授权(OnClientAuthorized)写入；仅在断线(OnClientDisconnect)删除。
 * 换图/过关不影响该记录（继续视为同一会话）。 */
StringMap g_SessionStartBySteam64;

/* -------------------- 工具函数 -------------------- */
bool IsValidHumanClient(int client)
{
    return (client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}

bool IsActivePlayingTeam(int client) // 生还=2, 感染=3
{
    int t = GetClientTeam(client);
    return (t == 2 || t == 3);
}

bool HasFlagsBits(int client, int bits)
{
    if (bits == 0) return false;
    return (GetUserFlagBits(client) & bits) != 0;
}

int GetBlockLimitFor(int client)
{
    return HasFlagsBits(client, g_iAdminFlags) ? g_iLimitAdmin : g_iLimitUser;
}

bool GetClientSteam64(int client, char outSteam64[32])
{
    return GetClientAuthId(client, AuthId_SteamID64, outSteam64, sizeof(outSteam64), true);
}

int FindClientBySteam64(const char steam64[32])
{
    char s[32];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidHumanClient(i)) continue;
        if (!GetClientSteam64(i, s)) continue;
        if (StrEqual(s, steam64)) return i;
    }
    return 0;
}

void BL_Log(const char[] fmt, any ...)
{
    if (!g_bLogEnable) return;

    static char path[128];
    gCvarLogFile.GetString(path, sizeof(path));
    if (!path[0]) strcopy(path, sizeof(path), g_sLogFile);

    char buffer[512];
    VFormat(buffer, sizeof(buffer), fmt, 2);
    LogToFileEx(path, "%s", buffer);
}

/* -------------------- DB 连接（自动 MySQL/SQLite） -------------------- */
void DB_Close()
{
    if (g_hDb != INVALID_HANDLE)
    {
        CloseHandle(g_hDb);
        g_hDb = INVALID_HANDLE;
    }
}

bool DB_Connect()
{
    if (g_hDb != INVALID_HANDLE)
        return true;

    if (!SQL_CheckConfig(g_sDBSection))
    {
        LogError("[BlockList] databases.cfg missing '%s' entry", g_sDBSection);
        return false;
    }

    char error[256];
    g_hDb = SQL_Connect(g_sDBSection, true, error, sizeof(error));
    if (g_hDb == INVALID_HANDLE)
    {
        LogError("[BlockList] DB connect failed: %s", error);
        return false;
    }

    char ident[32];
    SQL_ReadDriver(g_hDb, ident, sizeof(ident));
    bool isMySQL = StrEqual(ident, "mysql", false);

    if (isMySQL)
    {
        if (!SQL_SetCharset(g_hDb, "utf8mb4"))
            LogError("[BlockList] failed to set DB charset utf8mb4");
        SQL_FastQuery(g_hDb, "SET NAMES 'utf8mb4'");
    }

    char sql[512];
    if (isMySQL)
    {
        Format(sql, sizeof(sql),
            "CREATE TABLE IF NOT EXISTS `%s` ( \
              `blocker` VARCHAR(32) NOT NULL, \
              `blocked` VARCHAR(32) NOT NULL, \
              `created_at` INT NOT NULL, \
              PRIMARY KEY (`blocker`,`blocked`) \
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;", g_sTable);
    }
    else
    {
        Format(sql, sizeof(sql),
            "CREATE TABLE IF NOT EXISTS `%s` ( \
              `blocker` TEXT NOT NULL, \
              `blocked` TEXT NOT NULL, \
              `created_at` INTEGER NOT NULL, \
              PRIMARY KEY (`blocker`,`blocked`) \
            );", g_sTable);
    }

    SQL_TQuery(g_hDb, DB_GenericCallback, sql);
    return true;
}

public void DB_GenericCallback(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == INVALID_HANDLE && error[0] != '\0')
    {
        LogError("[BlockList] SQL error: %s", error);
    }
}

/* -------------------- 生命周期 -------------------- */
public void OnPluginStart()
{
    LoadTranslations("l4d2_blocklist.phrases.txt");

    g_SessionStartBySteam64 = new StringMap();

    RegConsoleCmd("sm_block",     Cmd_Block,     "屏蔽某人: sm_block <#userid|steam64|名字>");
    RegConsoleCmd("sm_unblock",   Cmd_Unblock,   "解除屏蔽: sm_unblock <#userid|steam64|名字>");
    RegConsoleCmd("sm_blocklist", Cmd_BlockList, "查看屏蔽列表: sm_blocklist [#userid|steam64|名字]");
    RegConsoleCmd("sm_blocklimit",Cmd_BlockLimit,"查看你的屏蔽上限");
    RegConsoleCmd("sm_blmenu",    Cmd_Menu,      "打开黑名单菜单");

    gCvarEnable          = CreateConVar("sm_bl_enable",            "1",    "启用插件(1/0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gCvarDBSection       = CreateConVar("sm_bl_db_section",        g_sDBSection, "databases.cfg 区块名", FCVAR_NOTIFY);
    gCvarTableName       = CreateConVar("sm_bl_table",             g_sTable,     "数据库表名", FCVAR_NOTIFY);
    gCvarKickMsg         = CreateConVar("sm_bl_kick_msg",          g_sKickMsg,   "踢出提示（留空使用翻译短语）", FCVAR_NOTIFY);
    gCvarLimitUser       = CreateConVar("sm_bl_limit_user",        "3",   "普通玩家屏蔽上限", FCVAR_NOTIFY, true, 0.0);
    gCvarLimitAdmin      = CreateConVar("sm_bl_limit_admin",       "10",  "管理员屏蔽上限", FCVAR_NOTIFY, true, 0.0);
    gCvarAdminFlag       = CreateConVar("sm_bl_admin_flag",        "b",    "享管理员上限的 flag(留空=无)", FCVAR_NOTIFY);
    gCvarConsiderTeams   = CreateConVar("sm_bl_consider_teams",    "0",    "仅检查队伍2/3(1/0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    gCvarImmuneFlag      = CreateConVar("sm_bl_immune_flag",       "z",    "加入免疫 flag(拥有则忽略屏蔽检查;留空=关闭)", FCVAR_NOTIFY);
    gCvarQuiet           = CreateConVar("sm_bl_quiet",             "1",    "静音提示：不通知触发屏蔽的玩家(1=静默,0=通知)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gCvarLogEnable       = CreateConVar("sm_bl_log",               "1",    "启用日志记录(1/0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gCvarLogFile         = CreateConVar("sm_bl_log_file",          g_sLogFile, "日志文件名(位于 logs/ 下)", FCVAR_NOTIFY);
    gCvarExposeBlocker   = CreateConVar("sm_bl_expose_blocker",    "0",    "踢出提示是否包含屏蔽者信息(1/0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gCvarUseI18NKick     = CreateConVar("sm_bl_use_i18n_kick",     "1",    "踢出提示使用翻译短语(1)；否则优先使用 cvar 文本", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    // 双向不共存：加入者若屏蔽了在场玩家，也禁止加入
    gCvarMutual         = CreateConVar("sm_bl_mutual",            "1",    "启用双向不共存(1/0)：加入者若屏蔽了在场玩家也禁止加入", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    AutoExecConfig(true, "l4d2_blocklist");

    // 初始值
    gCvarTableName.GetString(g_sTable, sizeof(g_sTable));
    gCvarKickMsg.GetString(g_sKickMsg, sizeof(g_sKickMsg));
    gCvarDBSection.GetString(g_sDBSection, sizeof(g_sDBSection));
    gCvarLogFile.GetString(g_sLogFile, sizeof(g_sLogFile));

    g_iLimitUser = gCvarLimitUser.IntValue;
    g_iLimitAdmin = gCvarLimitAdmin.IntValue;
    g_bConsiderTeamsOnly = gCvarConsiderTeams.BoolValue;
    g_bQuiet = gCvarQuiet.BoolValue;
    g_bLogEnable = gCvarLogEnable.BoolValue;
    g_bExposeBlocker = gCvarExposeBlocker.BoolValue;
    g_bUseI18NForKick = gCvarUseI18NKick.BoolValue;
    g_bMutual = gCvarMutual.BoolValue;

    char flagstr[16]; int f;
    gCvarAdminFlag.GetString(flagstr, sizeof(flagstr));
    g_iAdminFlags  = (ReadFlagString(flagstr, f) ? f : 0);
    gCvarImmuneFlag.GetString(flagstr, sizeof(flagstr));
    g_iImmuneFlags = (ReadFlagString(flagstr, f) ? f : 0);

    // 监听 CVar 变化（运行中可热改）
    HookConVarChange(gCvarTableName,     OnCvarChanged);
    HookConVarChange(gCvarKickMsg,       OnCvarChanged);
    HookConVarChange(gCvarDBSection,     OnCvarChanged);
    HookConVarChange(gCvarLimitUser,     OnCvarChanged);
    HookConVarChange(gCvarLimitAdmin,    OnCvarChanged);
    HookConVarChange(gCvarAdminFlag,     OnCvarChanged);
    HookConVarChange(gCvarConsiderTeams, OnCvarChanged);
    HookConVarChange(gCvarImmuneFlag,    OnCvarChanged);
    HookConVarChange(gCvarQuiet,         OnCvarChanged);
    HookConVarChange(gCvarLogEnable,     OnCvarChanged);
    HookConVarChange(gCvarLogFile,       OnCvarChanged);
    HookConVarChange(gCvarExposeBlocker, OnCvarChanged);
    HookConVarChange(gCvarUseI18NKick,   OnCvarChanged);
    HookConVarChange(gCvarMutual,       OnCvarChanged);

    DB_Connect();
}

public void OnMapEnd()
{
    // 数据库连接保持跨地图运行。
}

public void OnPluginEnd()
{
    DB_Close();
}

public void OnCvarChanged(ConVar cvar, const char[] o, const char[] n)
{
    if (cvar == gCvarTableName)        strcopy(g_sTable, sizeof(g_sTable), n);
    else if (cvar == gCvarKickMsg)     strcopy(g_sKickMsg, sizeof(g_sKickMsg), n);
    else if (cvar == gCvarDBSection)   { strcopy(g_sDBSection, sizeof(g_sDBSection), n); DB_Close(); DB_Connect(); }
    else if (cvar == gCvarLimitUser)   g_iLimitUser = StringToInt(n);
    else if (cvar == gCvarLimitAdmin)  g_iLimitAdmin = StringToInt(n);
    else if (cvar == gCvarConsiderTeams) g_bConsiderTeamsOnly = StringToInt(n) != 0;
    else if (cvar == gCvarQuiet)       g_bQuiet = StringToInt(n) != 0;
    else if (cvar == gCvarLogEnable)   g_bLogEnable = StringToInt(n) != 0;
    else if (cvar == gCvarLogFile)     strcopy(g_sLogFile, sizeof(g_sLogFile), n);
    else if (cvar == gCvarExposeBlocker) g_bExposeBlocker = StringToInt(n) != 0;
    else if (cvar == gCvarUseI18NKick)  g_bUseI18NForKick = StringToInt(n) != 0;
    else if (cvar == gCvarMutual)       g_bMutual = StringToInt(n) != 0;
    else if (cvar == gCvarAdminFlag)
    {
        int f; g_iAdminFlags = (ReadFlagString(n, f) ? f : 0);
    }
    else if (cvar == gCvarImmuneFlag)
    {
        int f; g_iImmuneFlags = (ReadFlagString(n, f) ? f : 0);
    }
}

/* 注意：不在 OnClientPutInServer 里重置 session。
 * 只在首次授权时记录；断线时清除。换图/过关不影响“本次会话”。 */
public void OnClientAuthorized(int client, const char[] auth)
{
    if (!IsClientConnected(client) || IsFakeClient(client)) return;

    char s64[32];
    if (!GetClientSteam64(client, s64)) return;

    int dummy;
    if (!g_SessionStartBySteam64.GetValue(s64, dummy))
    {
        int now = GetTime();
        g_SessionStartBySteam64.SetValue(s64, now);
        BL_Log("[SessionStart] %N(%L) start=%d", client, client, now);
    }

    // 入服屏蔽检查
    if (!gCvarEnable.BoolValue || g_hDb == INVALID_HANDLE) return;

    // 免疫：拥有免疫 flag 的加入者跳过检查
    if (HasFlagsBits(client, g_iImmuneFlags))
    {
        BL_Log("[ImmuneJoin] %N(%L) bypassed block check", client, client);
        return;
    }

    // 构造在场游玩者 IN 子句
    char inClause[768]; inClause[0] = '\0';
    int countIn = 0; char esc[64];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidHumanClient(i)) continue;
        if (g_bConsiderTeamsOnly && !IsActivePlayingTeam(i)) continue;
        if (i == client) continue;

        char t64[32];
        if (!GetClientSteam64(i, t64)) continue;

        SQL_EscapeString(g_hDb, t64, esc, sizeof(esc));
        if (countIn == 0) Format(inClause, sizeof(inClause), "'%s'", esc);
        else Format(inClause, sizeof(inClause), "%s,'%s'", inClause, esc);
        countIn++;
    }
    if (countIn == 0) return;

    char joinerEsc[64];
    SQL_EscapeString(g_hDb, s64, joinerEsc, sizeof(joinerEsc));

    // 查询两种命中：
    // dir=0: 在场玩家屏蔽了加入者（受延迟生效保护）
    // dir=1: 加入者屏蔽了在场玩家（双向不共存，可立即生效）
    char sql[1024];
    Format(sql, sizeof(sql),
        "SELECT 0 AS dir, blocker, created_at FROM `%s` WHERE blocked='%s' AND blocker IN (%s) UNION ALL SELECT 1 AS dir, blocked, created_at FROM `%s` WHERE blocker='%s' AND blocked IN (%s);",
        g_sTable, joinerEsc, inClause,
        g_sTable, joinerEsc, inClause);

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientSerial(client));
    pack.WriteString(s64); // 传入加入者 Steam64
    SQL_TQuery(g_hDb, DB_CheckJoinBlock_Callback, sql, pack);
}

public void OnClientDisconnect(int client)
{
    if (IsFakeClient(client)) return;
    char s64[32];
    if (!GetClientSteam64(client, s64)) return;

    if (g_SessionStartBySteam64.Remove(s64))
    {
        BL_Log("[SessionEnd] %N(%L) end", client, client);
    }
}

/* -------------------- 入服检查回调 -------------------- */
public void DB_CheckJoinBlock_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();
    int serial = pack.ReadCell();
    char joiner64[32]; pack.ReadString(joiner64, sizeof(joiner64));
    delete pack;

    if (error[0] != '\0' || hndl == INVALID_HANDLE)
    {
        LogError("[BlockList] CheckJoin SQL error: %s", error);
        return;
    }

    int client = GetClientFromSerial(serial);
    if (client == 0 || !IsClientConnected(client)) return;

    // 取出“被屏蔽者(=加入者)”的会话开始时间
    int joinerSession = 0;
    g_SessionStartBySteam64.GetValue(joiner64, joinerSession);

    bool shouldKick = false;
    char kicker64[32]; kicker64[0] = '\0';

    // 遍历命中：
    bool isSelf = false;            // true=加入者屏蔽了在场玩家
    char other64[32]; other64[0] = '\0'; // byOthers: blocker / bySelf: target

    while (SQL_FetchRow(hndl))
    {
        int dir = SQL_FetchInt(hndl, 0);
        char id64[32]; SQL_FetchString(hndl, 1, id64, sizeof(id64));
        int created_at = SQL_FetchInt(hndl, 2);

        if (dir == 0)
        {
            // 在场玩家屏蔽了加入者：仅当黑名单早于加入者本会话开始才生效（防当场拉黑→踢）
            if (joinerSession > 0 && created_at < joinerSession)
            {
                shouldKick = true;
                isSelf = false;
                strcopy(other64, sizeof(other64), id64);
                break; // 优先此方向
            }
        }
        else if (dir == 1 && g_bMutual)
        {
            // 加入者屏蔽了在场玩家：双向不共存，立即禁止加入
            shouldKick = true;
            isSelf = true;
            strcopy(other64, sizeof(other64), id64);
            // 不 break 也行，但没有必要继续
            break;
        }
    }

    if (!shouldKick) return;

    if (!isSelf)
    {
        int blockerClient = FindClientBySteam64(other64);
        BL_Log("[JoinBlocked] joiner=%N(%L) blockedBy=%s(%N)", client, client, other64, blockerClient);

        if (!g_bQuiet && blockerClient > 0 && IsClientInGame(blockerClient))
        {
            PrintToChat(blockerClient, "%t", "Notify_Blocker", client);
        }

        char msg[256];
        bool useCustom = (g_sKickMsg[0] != '\0') && !g_bUseI18NForKick;
        if (useCustom)
            strcopy(msg, sizeof(msg), g_sKickMsg);
        else
            (g_bExposeBlocker)
                ? FormatEx(msg, sizeof(msg), "%T", "Kick_By_Blocked_With_Blocker", client, other64)
                : FormatEx(msg, sizeof(msg), "%T", "Kick_By_Blocked", client);

        KickClient(client, "%s", msg);
    }
    else
    {
        // 自己屏蔽了在场玩家 → 禁止加入
        BL_Log("[JoinDeniedSelf] joiner=%N(%L) conflictedWith=%s(%N)", client, client, other64, FindClientBySteam64(other64));

        char msg[256];
        if (g_bExposeBlocker)
            FormatEx(msg, sizeof(msg), "%T", "Kick_By_SelfBlocked_With_Target", client, other64);
        else
            FormatEx(msg, sizeof(msg), "%T", "Kick_By_SelfBlocked", client);

        KickClient(client, "%s", msg);
    }
}

/* -------------------- 文本命令 -------------------- */
int ResolveTargetOrSteam64(int caller, const char[] arg, char outSteam64[32])
{
    // 纯数字且 >=15 位 → 视为 steam64
    bool digits = true;
    int len = strlen(arg);
    if (len >= 15)
    {
        for (int i = 0; i < len; i++) { if (arg[i] < '0' || arg[i] > '9') { digits = false; break; } }
        if (digits) { strcopy(outSteam64, 32, arg); return 1; }
    }

    // 名字 / #userid
    int target = FindTarget(caller, arg, true, false);
    if (target <= 0 || !IsClientInGame(target) || IsFakeClient(target)) return 0;
    if (!GetClientSteam64(target, outSteam64)) return 0;
    return 1;
}

public Action Cmd_Block(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client)) return Plugin_Handled;

    if (args < 1)
    {
        ReplyToCommand(client, "%t", "Usage_Block");
        return Plugin_Handled;
    }
    if (g_hDb == INVALID_HANDLE)
    {
        ReplyToCommand(client, "%t", "DB_NotReady");
        return Plugin_Handled;
    }

    char arg[64]; GetCmdArg(1, arg, sizeof(arg));
    char target64[32];
    if (!ResolveTargetOrSteam64(client, arg, target64))
    {
        ReplyToCommand(client, "%t", "Resolve_Failed");
        return Plugin_Handled;
    }
    DoToggleBlock(client, target64);
    return Plugin_Handled;
}

public Action Cmd_Unblock(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client)) return Plugin_Handled;
    if (args < 1)
    {
        ReplyToCommand(client, "%t", "Usage_Unblock");
        return Plugin_Handled;
    }
    if (g_hDb == INVALID_HANDLE)
    {
        ReplyToCommand(client, "%t", "DB_NotReady");
        return Plugin_Handled;
    }
    char arg[64]; GetCmdArg(1, arg, sizeof(arg));
    char target64[32];
    if (!ResolveTargetOrSteam64(client, arg, target64))
    {
        ReplyToCommand(client, "%t", "Resolve_Failed");
        return Plugin_Handled;
    }
    DoRemoveBlock(client, target64);
    return Plugin_Handled;
}

public Action Cmd_BlockList(int client, int args)
{
    if (g_hDb == INVALID_HANDLE)
    {
        if (client > 0) ReplyToCommand(client, "%t", "DB_NotReady");
        return Plugin_Handled;
    }

    char target64[32];
    if (args >= 1)
    {
        char arg[64]; GetCmdArg(1, arg, sizeof(arg));
        if (!ResolveTargetOrSteam64(client, arg, target64))
        {
            ReplyToCommand(client, "%t", "Resolve_Failed");
            return Plugin_Handled;
        }
    }
    else
    {
        if (!GetClientSteam64(client, target64))
        {
            ReplyToCommand(client, "%t", "Self_Steam_Failed");
            return Plugin_Handled;
        }
    }

    char e[64];
    SQL_EscapeString(g_hDb, target64, e, sizeof(e));

    char sql[256];
    Format(sql, sizeof(sql),
        "SELECT blocked, created_at FROM `%s` WHERE blocker='%s' ORDER BY created_at DESC LIMIT 200;",
        g_sTable, e);

    SQL_TQuery(g_hDb, DB_BlockList_Callback, sql, GetClientSerial(client));
    return Plugin_Handled;
}

public void DB_BlockList_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
    int client = GetClientFromSerial(data);
    if (client == 0) return;

    if (error[0] != '\0' || hndl == INVALID_HANDLE)
    {
        ReplyToCommand(client, "%t", "Query_Failed_Generic");
        LogError("[BlockList] List SQL error: %s", error);
        return;
    }

    int rows = SQL_GetRowCount(hndl);
    ReplyToCommand(client, "%t", "BlockList_Header", rows);

    char blocked[32];
    int ts;
    while (SQL_FetchRow(hndl))
    {
        SQL_FetchString(hndl, 0, blocked, sizeof(blocked));
        ts = SQL_FetchInt(hndl, 1);
        ReplyToCommand(client, "  -> %s (%d)", blocked, ts);
    }
}

public Action Cmd_BlockLimit(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client)) return Plugin_Handled;
    ReplyToCommand(client, "%t", "BlockLimit_Info", GetBlockLimitFor(client));
    return Plugin_Handled;
}

/* -------------------- 屏蔽/解除 辅助 -------------------- */
void DoToggleBlock(int client, const char[] target64)
{
    if (g_hDb == INVALID_HANDLE)
    {
        if (client > 0) ReplyToCommand(client, "%t", "DB_NotReady");
        return;
    }

    char self64[32];
    if (!GetClientSteam64(client, self64))
    {
        ReplyToCommand(client, "%t", "Self_Steam_Failed");
        return;
    }
    if (StrEqual(self64, target64))
    {
        ReplyToCommand(client, "%t", "Block_SelfDenied");
        return;
    }

    // 先查是否已有
    char eSelf[64], eTarget[64];
    SQL_EscapeString(g_hDb, self64, eSelf, sizeof(eSelf));
    SQL_EscapeString(g_hDb, target64, eTarget, sizeof(eTarget));

    char sql[256];
    Format(sql, sizeof(sql),
        "SELECT 1 FROM `%s` WHERE blocker='%s' AND blocked='%s' LIMIT 1;",
        g_sTable, eSelf, eTarget);

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientSerial(client));
    pack.WriteString(self64);
    pack.WriteString(target64);
    SQL_TQuery(g_hDb, DB_CheckExist_Callback, sql, pack);
}

public void DB_CheckExist_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();
    int serial = pack.ReadCell();
    char self64[32];   pack.ReadString(self64, sizeof(self64));
    char target64[32]; pack.ReadString(target64, sizeof(target64));
    delete pack;

    int client = GetClientFromSerial(serial);
    if (client == 0) return;

    if (error[0] != '\0' || hndl == INVALID_HANDLE)
    {
        ReplyToCommand(client, "%t", "Query_Failed_Generic");
        LogError("[BlockList] Exist SQL error: %s", error);
        return;
    }

    if (SQL_FetchRow(hndl))
    {
        // 已存在 → 删除
        DoRemoveBlock(client, target64);
    }
    else
    {
        // 不存在 → 添加（检查配额）
        int limit = GetBlockLimitFor(client);

        char eSelf[64], eTarget[64];
        SQL_EscapeString(g_hDb, self64, eSelf, sizeof(eSelf));
        SQL_EscapeString(g_hDb, target64, eTarget, sizeof(eTarget));

        char sql[256];
        Format(sql, sizeof(sql),
            "SELECT COUNT(*) FROM `%s` WHERE blocker='%s';",
            g_sTable, eSelf);

        DataPack pack2 = new DataPack();
        pack2.WriteCell(serial);
        pack2.WriteString(self64);
        pack2.WriteString(target64);
        pack2.WriteCell(limit);
        SQL_TQuery(g_hDb, DB_Block_Count_Callback, sql, pack2);
    }
}

public void DB_Block_Count_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();
    int serial = pack.ReadCell();
    char self64[32];   pack.ReadString(self64, sizeof(self64));
    char target64[32]; pack.ReadString(target64, sizeof(target64));
    int limit = pack.ReadCell();
    delete pack;

    int client = GetClientFromSerial(serial);
    if (client == 0) return;

    if (error[0] != '\0' || hndl == INVALID_HANDLE)
    {
        ReplyToCommand(client, "%t", "Block_Failed_Generic");
        LogError("[BlockList] Count SQL error: %s", error);
        return;
    }

    int cur = 0;
    if (SQL_FetchRow(hndl)) cur = SQL_FetchInt(hndl, 0);
    if (cur >= limit)
    {
        ReplyToCommand(client, "%t", "Block_LimitReached", limit);
        return;
    }

    int now = GetTime();
    char eSelf[64], eTarget[64];
    SQL_EscapeString(g_hDb, self64, eSelf, sizeof(eSelf));
    SQL_EscapeString(g_hDb, target64, eTarget, sizeof(eTarget));

    char sql[256];
    Format(sql, sizeof(sql),
        "REPLACE INTO `%s` (blocker,blocked,created_at) VALUES ('%s','%s',%d);",
        g_sTable, eSelf, eTarget, now);

    DataPack pack2 = new DataPack();
    pack2.WriteCell(serial);
    pack2.WriteString(target64);
    SQL_TQuery(g_hDb, DB_Block_Insert_Callback, sql, pack2);
}

public void DB_Block_Insert_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
    DataPack pack2 = view_as<DataPack>(data);
    pack2.Reset();
    int serial = pack2.ReadCell();
    char target64[32]; pack2.ReadString(target64, sizeof(target64));
    delete pack2;

    int client = GetClientFromSerial(serial);
    if (client == 0) return;

    if (error[0] != '\0' || hndl == INVALID_HANDLE)
    {
        ReplyToCommand(client, "%t", "Block_Failed_Generic");
        LogError("[BlockList] Insert SQL error: %s", error);
        return;
    }

    BL_Log("[BlockAdd] %N(%L) -> %s", client, client, target64);
    ReplyToCommand(client, "%t", "Block_Added", target64);
}

void DoRemoveBlock(int client, const char[] target64)
{
    if (g_hDb == INVALID_HANDLE)
    {
        ReplyToCommand(client, "%t", "DB_NotReady");
        return;
    }

    char self64[32];
    if (!GetClientSteam64(client, self64))
    {
        ReplyToCommand(client, "%t", "Self_Steam_Failed");
        return;
    }

    char eSelf[64], eTarget[64];
    SQL_EscapeString(g_hDb, self64, eSelf, sizeof(eSelf));
    SQL_EscapeString(g_hDb, target64, eTarget, sizeof(eTarget));

    char sql[256];
    Format(sql, sizeof(sql),
        "DELETE FROM `%s` WHERE blocker='%s' AND blocked='%s';",
        g_sTable, eSelf, eTarget);

    SQL_TQuery(g_hDb, DB_Unblock_Callback, sql, GetClientSerial(client));
}

public void DB_Unblock_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
    int client = GetClientFromSerial(data);
    if (client == 0) return;

    if (error[0] != '\0' || hndl == INVALID_HANDLE)
    {
        ReplyToCommand(client, "%t", "Unblock_Failed_Generic");
        LogError("[BlockList] Delete SQL error: %s", error);
        return;
    }

    int affected = SQL_GetAffectedRows(hndl);
    if (affected > 0)
    {
        ReplyToCommand(client, "%t", "Unblock_Removed");
        BL_Log("[BlockRemove] %N(%L) -> removed (affected=%d)", client, client, affected);
    }
    else
    {
        ReplyToCommand(client, "%t", "Unblock_NotFound");
    }
}

/* -------------------- 菜单 -------------------- */
public Action Cmd_Menu(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client)) return Plugin_Handled;
    ShowMainMenu(client);
    return Plugin_Handled;
}

void ShowMainMenu(int client)
{
    Menu m = new Menu(MainMenuHandler);
    m.SetTitle("%T", "Menu_Title", client);

    // Menu::AddItem 不支持 "%t" 直接翻译，先 Format 再 AddItem
    char lbl1[64], lbl2[64];
    FormatEx(lbl1, sizeof(lbl1), "%T", "Menu_BlockOnline", client);
    FormatEx(lbl2, sizeof(lbl2), "%T", "Menu_MyBlockList", client);

    m.AddItem("online", lbl1);
    m.AddItem("mylist",  lbl2);
    m.ExitButton = true;
    m.Display(client, 30);
}

public int MainMenuHandler(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_End) { delete menu; }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param, info, sizeof(info));
        if (StrEqual(info, "online"))
        {
            ShowOnlineMenu(client);
        }
        else if (StrEqual(info, "mylist"))
        {
            QueryMyBlockListMenu(client);
        }
    }
    return 0;
}

void ShowOnlineMenu(int client)
{
    Menu m = new Menu(OnlineMenuHandler);
    m.SetTitle("%T", "Menu_BlockOnline_Title", client);

    char item[64], disp[96], s64[32];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidHumanClient(i)) continue;
        if (i == client) continue;

        if (!GetClientSteam64(i, s64)) continue;
        IntToString(i, item, sizeof(item)); // 存 client index
        FormatEx(disp, sizeof(disp), "%N (%s)", i, s64);
        m.AddItem(item, disp);
    }
    if (m.ItemCount == 0) m.AddItem("none", "(no players)", ITEMDRAW_DISABLED);

    m.ExitBackButton = true; // back -> main
    m.Display(client, 30);
}

public int OnlineMenuHandler(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_End) { delete menu; }
    else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
    {
        ShowMainMenu(client);
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param, info, sizeof(info));
        if (StrEqual(info, "none")) { ShowOnlineMenu(client); return 0; }

        int target = StringToInt(info);
        if (!IsValidHumanClient(target))
        {
            PrintToChat(client, "%t", "Target_Left");
            ShowOnlineMenu(client);
            return 0;
        }
        char s64[32];
        if (!GetClientSteam64(target, s64))
        {
            PrintToChat(client, "%t", "Resolve_Failed");
            ShowOnlineMenu(client);
            return 0;
        }
        DoToggleBlock(client, s64);
        // 操作后刷新列表
        CreateTimer(0.1, Timer_ShowOnlineAgain, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
    }
    return 0;
}

public Action Timer_ShowOnlineAgain(Handle timer, any data)
{
    int client = GetClientFromSerial(data);
    if (client > 0 && IsClientInGame(client))
        ShowOnlineMenu(client);
    return Plugin_Stop;
}

/* ------- My BlockList menu (query DB -> build menu) ------- */
void QueryMyBlockListMenu(int client)
{
    if (g_hDb == INVALID_HANDLE)
    {
        PrintToChat(client, "%t", "DB_NotReady");
        return;
    }
    char self64[32];
    if (!GetClientSteam64(client, self64))
    {
        PrintToChat(client, "%t", "Self_Steam_Failed");
        return;
    }
    char e[64];
    SQL_EscapeString(g_hDb, self64, e, sizeof(e));

    char sql[256];
    Format(sql, sizeof(sql),
        "SELECT blocked, created_at FROM `%s` WHERE blocker='%s' ORDER BY created_at DESC LIMIT 200;",
        g_sTable, e);

    SQL_TQuery(g_hDb, DB_BuildMyListMenu, sql, GetClientSerial(client));
}

public void DB_BuildMyListMenu(Handle owner, Handle hndl, const char[] error, any data)
{
    int client = GetClientFromSerial(data);
    if (client == 0 || !IsClientInGame(client)) return;

    if (error[0] != '\0' || hndl == INVALID_HANDLE)
    {
        PrintToChat(client, "%t", "Query_Failed_Generic");
        LogError("[BlockList] Menu SQL error: %s", error);
        return;
    }

    Menu m = new Menu(MyListMenuHandler);
    m.SetTitle("%T", "Menu_MyBlockList_Title", client);

    char blocked[32], disp[96];
    int ts, cnt = 0;
    while (SQL_FetchRow(hndl))
    {
        SQL_FetchString(hndl, 0, blocked, sizeof(blocked));
        ts = SQL_FetchInt(hndl, 1);
        FormatEx(disp, sizeof(disp), "%s  (ts:%d)", blocked, ts);
        m.AddItem(blocked, disp);
        cnt++;
    }
    if (cnt == 0) m.AddItem("none", "(empty)", ITEMDRAW_DISABLED);

    m.ExitBackButton = true;
    m.Display(client, 30);
}

public int MyListMenuHandler(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_End) { delete menu; }
    else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
    {
        ShowMainMenu(client);
    }
    else if (action == MenuAction_Select)
    {
        char steam64[64];
        menu.GetItem(param, steam64, sizeof(steam64));
        if (StrEqual(steam64, "none"))
        {
            QueryMyBlockListMenu(client);
            return 0;
        }
        DoRemoveBlock(client, steam64);
        CreateTimer(0.1, Timer_ShowMyListAgain, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
    }
    return 0;
}

public Action Timer_ShowMyListAgain(Handle timer, any data)
{
    int client = GetClientFromSerial(data);
    if (client > 0 && IsClientInGame(client))
        QueryMyBlockListMenu(client);
    return Plugin_Stop;
}
