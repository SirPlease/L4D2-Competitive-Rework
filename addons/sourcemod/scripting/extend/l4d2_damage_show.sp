#pragma semicolon 1 
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>
#include <colors>

// =========================
// Plugin constants / config
// =========================
#define PLUGIN_VERSION  "2.2-mysql-cookie(db-first)+asyncconnect+queue-save+steam2+fixes"
#define SPRITE_MATERIAL "materials/sprites/laserbeam.vmt"
#define DMG_HEADSHOT    (1 << 30)
#define L4D2_MAXPLAYERS 32
#define ZC_BOOMER       2
#define ZC_TANK         8
#define UPDATE_INTERVAL 0.10 // 累加帧间隔（不要低于 0.05）

// ====== 数据层：MySQL + Cookie ======
#define DB_CONF_NAME "rpg"        // databases.cfg 中的配置名
#define COOKIE_NAME  "l4d2_dmgshow_v2"

// rpgdamage 表结构（使用 Steam2 作为主键，保持与你现表一致）
// CREATE TABLE IF NOT EXISTS `rpgdamage` (
//   `steamid`     VARCHAR(64) NOT NULL PRIMARY KEY,
//   `enable`      TINYINT     NOT NULL DEFAULT 0,
//   `see_others`  TINYINT     NOT NULL DEFAULT 1,
//   `share_scope` TINYINT     NOT NULL DEFAULT 0,
//   `size`        FLOAT       NOT NULL DEFAULT 5.0,
//   `gap`         FLOAT       NOT NULL DEFAULT 5.0,
//   `alpha`       INT         NOT NULL DEFAULT 70,
//   `xoff`        FLOAT       NOT NULL DEFAULT 20.0,
//   `yoff`        FLOAT       NOT NULL DEFAULT 10.0,
//   `showdist`    FLOAT       NOT NULL DEFAULT 1500.0,
//   `summode`     TINYINT     NOT NULL DEFAULT 1,
//   `sg_merge`    TINYINT     NOT NULL DEFAULT 1
// ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

// ============ 结构体 ============

enum struct PlayerSetData
{
    // 运行期缓存
    int   wpn_id;
    int   wpn_type; // 0狙 1步冲 2近战 3其它 4火焰 5投掷类
    bool  show_other;    // “允许别人看到我的数字”（仅管理员可真）
    float last_set_time;

    // 可持久化 per-client 样式
    bool  enable;        // 伤害显示开关（默认 false）
    bool  see_others;    // 我是否能看到“他人分享”的数字（默认 true）
    int   share_scope;   // 我把伤害分享给谁：0仅自己/1队友（仅管理员有效）
    float size;          // 字号
    float gap;           // 字距
    int   alpha;         // 透明度 0-255
    float xoff;          // X 偏移
    float yoff;          // Y 偏移
    float showdist;      // 显示距离上限
    bool  summode;       // 累加模式
    bool  sgmerge;       // 霰弹合并
}

enum struct ReturnTwoFloat
{
    float startPt[3];
    float endPt[3];
}

enum struct ShotgunDamageData
{
    int   victim;
    int   attacker;
    int   totalDamage;
    float damagePosition[3];
    int   damageType;
    int   weapon;
    bool  isHeadshot;
    bool  isCreated;
}

enum struct SumShowMode
{
    bool  needShow;
    int   totalDamage;
    int   damageType;
    int   weapon;
    bool  isHeadshot;
    float damagePosition[3];
    float lastShowTime;
    float lastHitTime;
}

enum struct DamageTrans
{
    bool forceHeadshot;
    int  damage;
}

// ============ 全局 ============

PlayerSetData      g_Plr[L4D2_MAXPLAYERS + 1];
ShotgunDamageData  g_SGbuf[L4D2_MAXPLAYERS + 1][L4D2_MAXPLAYERS + 1]; // [attacker][victim]
SumShowMode        g_Sum[L4D2_MAXPLAYERS + 1][L4D2_MAXPLAYERS + 1];
DamageTrans        g_AttackCache[L4D2_MAXPLAYERS + 1][L4D2_MAXPLAYERS + 1];

ConVar g_hMaxTE;
// ★ 新增：按管理员 Flag 白名单控制
ConVar g_hAllowedFlags;
char   g_sAllowedFlags[64];
int    g_iAllowedBits = 0;
bool   g_bGateActive  = false; // true=必须有这些flag之一才允许用

bool  g_bNeverFire[L4D2_MAXPLAYERS + 1];
int   g_sprite;
int   g_iVitcimHealth[L4D2_MAXPLAYERS + 1][L4D2_MAXPLAYERS + 1];
float g_fTankIncap[L4D2_MAXPLAYERS + 1];

// === 旁观管理员：查看所有人开关（默认关） ===
bool  g_bAdminObsViewAll[MAXPLAYERS + 1];

// ============ DB / Cookie ============

Handle g_DB = INVALID_HANDLE;
bool   g_UseMySQL = false;

// 异步连接状态
bool  g_DbConnecting = false;
bool  g_DbReady      = false;
float g_DbRetryAfter = 0.0;
#define DB_RETRY_COOLDOWN 10.0

Cookie g_ck = null;

// === 防止“加载前保存覆盖”的标记 ===
enum LoadState
{
    LS_None = 0,     // 未开始
    LS_DBPending,    // 等待 DB 回调
    LS_Ready         // 已完成（DB 优先；若无则 cookie/默认并回写）
};
LoadState g_LoadState[MAXPLAYERS + 1];
bool g_HaveCookie[MAXPLAYERS + 1];
char g_CookieRaw[MAXPLAYERS + 1][256];

// 保存排队：在未加载完成时点了“保存”，把当时的设置拍个快照
bool          g_PendingSave[MAXPLAYERS + 1];

static void ResetClientState(int client)
{
    g_LoadState[client] = LS_None;
    g_HaveCookie[client] = false;
    g_CookieRaw[client][0] = '\0';
    g_PendingSave[client] = false;
}
PlayerSetData g_SaveSnapshot[MAXPLAYERS + 1];

static const int color[][3] = {
    {  0,255,  0}, // 绿：友伤
    {255,255,  0}, // 黄：未用
    {255,255,255}, // 白：打 SI/CI
    {  0,255,255}, // 蓝
    {255,  0,  0}  // 红：爆头
};

// ============ 菜单（分两层） ============
#define MENU_TIME 20

// ============ 日志小工具 ============

#define LOG_PREFIX "[DMGSHOW]"

stock void LogInfo(const char[] fmt, any ...)
{
    char msg[1024];
    VFormat(msg, sizeof(msg), fmt, 2);
    LogMessage("%s %s", LOG_PREFIX, msg);
}

stock void LogErr(const char[] fmt, any ...)
{
    char msg[1024];
    VFormat(msg, sizeof(msg), fmt, 2);
    LogError("%s %s", LOG_PREFIX, msg);
}

// --------- 工具函数 ----------
static bool IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

static bool IsAdminOrRoot(int client) {
    return CheckCommandAccess(client, "dmg_admin_gate", ADMFLAG_GENERIC, true);
}

static void ClampStyle(int client)
{
    if (g_Plr[client].size < 0.0)     g_Plr[client].size = 0.0;
    if (g_Plr[client].size > 100.0)   g_Plr[client].size = 100.0;
    if (g_Plr[client].gap < 0.0)      g_Plr[client].gap = 0.0;
    if (g_Plr[client].gap > 100.0)    g_Plr[client].gap = 100.0;
    if (g_Plr[client].alpha < 0)      g_Plr[client].alpha = 0;
    if (g_Plr[client].alpha > 255)    g_Plr[client].alpha = 255;
    if (g_Plr[client].xoff < -100.0)  g_Plr[client].xoff = -100.0;
    if (g_Plr[client].xoff >  100.0)  g_Plr[client].xoff =  100.0;
    if (g_Plr[client].yoff < -100.0)  g_Plr[client].yoff = -100.0;
    if (g_Plr[client].yoff >  100.0)  g_Plr[client].yoff =  100.0;
    if (g_Plr[client].showdist < 0.0) g_Plr[client].showdist = 0.0;
    if (g_Plr[client].showdist > 8192.0) g_Plr[client].showdist = 8192.0;

    if (g_Plr[client].share_scope < 0) g_Plr[client].share_scope = 0;
    if (g_Plr[client].share_scope > 1) g_Plr[client].share_scope = 1;

    // 非管理员：强制不对外分享（仅自己）
    if (!IsAdminOrRoot(client)) {
        g_Plr[client].show_other = false;
        g_Plr[client].share_scope = 0;
    }
}

// ===============================
// SQL 拼接工具（避免相邻 ""）
// ===============================
stock void SQLCat(char[] buffer, int maxlen, const char[] piece)
{
    int blen = strlen(buffer);
    int plen = strlen(piece);
    if (blen + plen + 1 >= maxlen)
    {
        LogErr("[DB] SQL buffer full, skip append: '%s'", piece);
        return;
    }
    StrCat(buffer, maxlen, piece);
}

stock void SQLCatF(char[] buffer, int maxlen, const char[] fmt, any ...)
{
    char tmp[512];
    VFormat(tmp, sizeof(tmp), fmt, 4); // buffer(1) maxlen(2) fmt(3) → 可变参起始=4
    SQLCat(buffer, maxlen, tmp);
}

// ===============================
// Cookie / 默认
// ===============================
static void Settings_Default(int client)
{
    g_Plr[client].enable        = false;  // 默认不开
    g_Plr[client].see_others    = true;   // 允许看“管理员分享”
    g_Plr[client].share_scope   = 0;      // 仅自己
    g_Plr[client].size          = 5.0;
    g_Plr[client].gap           = 5.0;
    g_Plr[client].alpha         = 70;
    g_Plr[client].xoff          = 20.0;
    g_Plr[client].yoff          = 10.0;
    g_Plr[client].showdist      = 1500.0;
    g_Plr[client].summode       = true;
    g_Plr[client].sgmerge       = true;
    g_Plr[client].show_other    = false; // 非管理员默认 false
}

static bool ApplyCookieRawString(int client, const char[] raw)
{
    if (!raw[0]) return false;

    char part[11][32];
    int n = ExplodeString(raw, "|", part, sizeof(part), sizeof(part[]));
    if (n < 11) return false;

    g_Plr[client].enable      = (StringToInt(part[0]) != 0);
    g_Plr[client].see_others  = (StringToInt(part[1]) != 0);
    g_Plr[client].share_scope = StringToInt(part[2]);
    g_Plr[client].size        = StringToFloat(part[3]);
    g_Plr[client].gap         = StringToFloat(part[4]);
    g_Plr[client].alpha       = StringToInt(part[5]);
    g_Plr[client].xoff        = StringToFloat(part[6]);
    g_Plr[client].yoff        = StringToFloat(part[7]);
    g_Plr[client].showdist    = StringToFloat(part[8]);
    g_Plr[client].summode     = (StringToInt(part[9]) != 0);
    g_Plr[client].sgmerge     = (StringToInt(part[10]) != 0);

    g_Plr[client].show_other = false; // cookie 模式非管理员也不允许开放
    ClampStyle(client);
    // ★ 新增：Cookie 应用后也要过门禁
    Gate_EnforceFor(client, "cookie-apply");
    return true;
}

// 允许强制保存：force=true 时即便还没加载完成也写入 Cookie，防丢
static void Cookie_Save(int client, bool force = false)
{
    if (g_ck == null || IsFakeClient(client)) return;
    if ((g_LoadState[client] != LS_Ready) && !force) return;

    char buf[256];
    Format(buf, sizeof(buf), "%d|%d|%d|%.1f|%.1f|%d|%.1f|%.1f|%.1f|%d|%d",
        g_Plr[client].enable ? 1 : 0,
        g_Plr[client].see_others ? 1 : 0,
        g_Plr[client].share_scope,
        g_Plr[client].size,
        g_Plr[client].gap,
        g_Plr[client].alpha,
        g_Plr[client].xoff,
        g_Plr[client].yoff,
        g_Plr[client].showdist,
        g_Plr[client].summode ? 1 : 0,
        g_Plr[client].sgmerge ? 1 : 0
    );
    g_ck.Set(client, buf);
    LogInfo("[Cookie] Saved (force=%d) for client %d: %s", force ? 1 : 0, client, buf);
}

// ===============================
// MySQL 连接 / 会话字符集 / 调试
// ===============================
static void DB_DebugDumpSession()
{
    if (g_DB == INVALID_HANDLE) return;

    SQL_TQuery(g_DB, SQLCB_OnSessionDump,
        "SELECT @@character_set_client,@@character_set_connection,@@character_set_results,@@collation_connection", 0);
}

static void DB_BeginConnect()
{
    if (g_DbConnecting) return;
    if (g_DB != INVALID_HANDLE) return;
    if (GetGameTime() < g_DbRetryAfter) return;

    if (!SQL_CheckConfig(DB_CONF_NAME))
    {
        LogErr("[DB] databases.cfg is missing or invalid for '%s'", DB_CONF_NAME);
        g_UseMySQL = false;
        g_DB = INVALID_HANDLE;
        g_DbReady = false;
        return;
    }

    g_DbConnecting = true;
    g_UseMySQL = true;   // 有配置就视为启用，真正就绪看 g_DbReady
    g_DbReady = false;

    // 正确参数顺序：SQL_TConnect(回调, 配置名, 持久化, 可选data)
    SQL_TConnect(SQLCB_OnConnect, DB_CONF_NAME, true);
    LogInfo("[DB] SQL_TConnect issued (async) for '%s'", DB_CONF_NAME);
} 

static bool DB_EnsureReady()
{
    if (g_DbReady && g_DB != INVALID_HANDLE) return true;
    DB_BeginConnect();
    return (g_DbReady && g_DB != INVALID_HANDLE);
}

static bool DB_IsConnectionLostError(const char[] error)
{
    return StrContains(error, "Lost connection", false) != -1
        || StrContains(error, "server has gone away", false) != -1;
}

static void DB_MarkConnectionLost(const char[] error)
{
    if (!DB_IsConnectionLostError(error))
        return;

    if (g_DB != INVALID_HANDLE)
    {
        CloseHandle(g_DB);
        g_DB = INVALID_HANDLE;
    }

    g_DbReady = false;
    g_DbConnecting = false;
    g_DbRetryAfter = GetGameTime() + DB_RETRY_COOLDOWN;
}

public void SQLCB_OnConnect(Handle owner, Handle hndl, const char[] error, any data)
{
    LogInfo("[DB] SQLCB_OnConnect fired. hndl=%p error='%s'",
        hndl, (error[0] ? error : "(none)"));

    g_DbConnecting = false;

    if (hndl == INVALID_HANDLE)
    {
        LogErr("[DB] connect failed: %s", error);
        g_DB = INVALID_HANDLE;
        g_DbReady = false;
        g_DbRetryAfter = GetGameTime() + DB_RETRY_COOLDOWN;
        return;
    }

    g_DB = hndl;
    g_DbReady = true;

    // 统一会话字符集（双保险）
    SQL_SetCharset(g_DB, "utf8mb4");
    SQL_TQuery(g_DB, SQLCB_OnSetNames, "SET NAMES utf8mb4", 0);

    DB_DebugDumpSession();

    LogInfo("[DB] connected (async), handle=%p", g_DB);
}

public void SQLCB_OnSetNames(Handle owner, Handle hndl, const char[] error, any data)
{
    if (error[0]) LogErr("[DB] SET NAMES utf8mb4 failed: %s", error);
    else          LogInfo("[DB] SET NAMES utf8mb4 OK");
}

public void SQLCB_OnSessionDump(Handle owner, Handle hndl, const char[] error, any data)
{
    if (error[0])
    {
        LogErr("[DB] session snapshot failed: %s", error);
        DB_MarkConnectionLost(error);
        return;
    }
    if (hndl != INVALID_HANDLE && SQL_FetchRow(hndl))
    {
        char a[64], b[64], c[64], d[64];
        SQL_FetchString(hndl, 0, a, sizeof a);
        SQL_FetchString(hndl, 1, b, sizeof b);
        SQL_FetchString(hndl, 2, c, sizeof c);
        SQL_FetchString(hndl, 3, d, sizeof d);
        LogInfo("[DB] session charset: client=%s connection=%s results=%s coll=%s", a,b,c,d);
    }
}

public void SQLCB_Nop(Handle owner, Handle hndl, const char[] error, any data)
{
    if (error[0] != '\0')
    {
        LogErr("[DB] SQL error in NOP: %s", error);
        DB_MarkConnectionLost(error);
    }
}

// ========== DB 加载 / 保存（DB 优先 + 队列保存） ==========
static void DB_Load(int client)
{
    if (IsFakeClient(client)) { g_LoadState[client] = LS_Ready; return; }

    if (!DB_EnsureReady())
    {
        // DB 不可用 → 如果有 Cookie 用 Cookie，否则默认
        bool ok = false;
        if (g_HaveCookie[client])
            ok = ApplyCookieRawString(client, g_CookieRaw[client]);
        if (!ok) Settings_Default(client);

        g_LoadState[client] = LS_Ready;
        LogInfo("[Load] DB not ready, used %s for client %d.",
                ok ? "cookie" : "defaults", client);
        return;
    }

    g_LoadState[client] = LS_DBPending;

    char sid2[64], sid_esc[128];
    if (!GetClientAuthId(client, AuthId_Steam2, sid2, sizeof sid2) || StrEqual(sid2, "BOT"))
    {
        bool ok = false;
        if (g_HaveCookie[client])
            ok = ApplyCookieRawString(client, g_CookieRaw[client]);
        if (!ok) Settings_Default(client);
        g_LoadState[client] = LS_Ready;
        LogInfo("[Load] No Steam2 (or BOT), used %s for client %d.",
                ok ? "cookie" : "defaults", client);
        return;
    }

    SQL_EscapeString(g_DB, sid2, sid_esc, sizeof sid_esc);

    char q[512];
    Format(q, sizeof q,
        "SELECT enable,see_others,share_scope,size,gap,alpha,xoff,yoff,showdist,summode,sg_merge FROM rpgdamage WHERE steamid='%s' LIMIT 1", sid_esc);

    LogInfo("[Load] DB_Load SQL: %s", q);
    SQL_TQuery(g_DB, SQLCB_Load, q, GetClientUserId(client));
}

public void SQLCB_Load(Handle owner, Handle hndl, const char[] error, any data)
{
    int client = GetClientOfUserId(data);
    if (!IsValidClient(client)) return;

    if (error[0])
    {
        bool ok = false;
        if (g_HaveCookie[client])
            ok = ApplyCookieRawString(client, g_CookieRaw[client]);
        if (!ok) Settings_Default(client);

        g_LoadState[client] = LS_Ready;
        LogErr("[Load] SQL error: %s. Used %s for client %d.",
               error, ok ? "cookie" : "defaults", client);
        DB_MarkConnectionLost(error);
        return;
    }

    if (hndl != INVALID_HANDLE && SQL_FetchRow(hndl))
    {
        // ★ DB 有记录 → 用 DB
        g_Plr[client].enable      = (SQL_FetchInt(hndl, 0) != 0);
        g_Plr[client].see_others  = (SQL_FetchInt(hndl, 1) != 0);
        g_Plr[client].share_scope = SQL_FetchInt(hndl, 2);
        g_Plr[client].size        = SQL_FetchFloat(hndl, 3);
        g_Plr[client].gap         = SQL_FetchFloat(hndl, 4);
        g_Plr[client].alpha       = SQL_FetchInt(hndl, 5);
        g_Plr[client].xoff        = SQL_FetchFloat(hndl, 6);
        g_Plr[client].yoff        = SQL_FetchFloat(hndl, 7);
        g_Plr[client].showdist    = SQL_FetchFloat(hndl, 8);
        g_Plr[client].summode     = (SQL_FetchInt(hndl, 9) != 0);
        g_Plr[client].sgmerge     = (SQL_FetchInt(hndl,10) != 0);

        g_Plr[client].show_other = false; // 非管理员不对外
        ClampStyle(client);

        g_LoadState[client] = LS_Ready;
        // ★ 新增：DB 数据落地后，执行门禁并保存
        Gate_EnforceFor(client, "db-load");
        LogInfo("[Load] Loaded settings from DB for client %d.", client);
    }
    else
    {
        // ★ DB 无记录 → 有 Cookie 则用 Cookie，再插入；否则默认并插入
        bool fromCookie = false;
        if (g_HaveCookie[client])
            fromCookie = ApplyCookieRawString(client, g_CookieRaw[client]);
        if (!fromCookie)
            Settings_Default(client);

        char sid2[64], sid_esc[128];
        GetClientAuthId(client, AuthId_Steam2, sid2, sizeof sid2);
        SQL_EscapeString(g_DB, sid2, sid_esc, sizeof sid_esc);

        char q[1024]; q[0]='\0';
        SQLCat(q, sizeof q, "INSERT INTO rpgdamage ");
        SQLCat(q, sizeof q, "(steamid,enable,see_others,share_scope,size,gap,alpha,xoff,yoff,showdist,summode,sg_merge) ");
        SQLCatF(q, sizeof q,
            "VALUES ('%s',%d,%d,%d,%.1f,%.1f,%d,%.1f,%.1f,%.1f,%d,%d) ",
            sid_esc,
            g_Plr[client].enable?1:0,
            g_Plr[client].see_others?1:0,
            g_Plr[client].share_scope,
            g_Plr[client].size,
            g_Plr[client].gap,
            g_Plr[client].alpha,
            g_Plr[client].xoff,
            g_Plr[client].yoff,
            g_Plr[client].showdist,
            g_Plr[client].summode?1:0,
            g_Plr[client].sgmerge?1:0
        );
        SQLCat(q, sizeof q, "ON DUPLICATE KEY UPDATE ");
        SQLCat(q, sizeof q, "enable=VALUES(enable), see_others=VALUES(see_others), share_scope=VALUES(share_scope), ");
        SQLCat(q, sizeof q, "size=VALUES(size), gap=VALUES(gap), alpha=VALUES(alpha), xoff=VALUES(xoff), yoff=VALUES(yoff), ");
        SQLCat(q, sizeof q, "showdist=VALUES(showdist), summode=VALUES(summode), sg_merge=VALUES(sg_merge)");

        LogInfo("[Load] No DB row; applying %s and inserting: %s",
                fromCookie ? "cookie" : "defaults", q);
        SQL_TQuery(g_DB, SQLCB_Nop, q);

        g_LoadState[client] = LS_Ready;
        // ★ 新增：DB 数据落地后，执行门禁并保存
        Gate_EnforceFor(client, "db-load");
    }

    // 若期间用户点过“保存”，立即把当时的快照写库（避免丢变更）
    if (g_PendingSave[client])
    {
        g_PendingSave[client] = false;
        int rc = DB_Save_Snapshot(client);
        LogInfo("[SavePending] Flushed queued save for client %d, rc=%d", client, rc);
    }
}

// 供回调把“排队快照”落库（不依赖 g_Plr 当前值）
static int DB_Save_Snapshot(int client)
{
    if (!g_UseMySQL || g_DB == INVALID_HANDLE || IsFakeClient(client))
        return 0;

    char sid2[64], sid_esc[128];
    if (!GetClientAuthId(client, AuthId_Steam2, sid2, sizeof sid2) || StrEqual(sid2, "BOT"))
        return 0;

    SQL_EscapeString(g_DB, sid2, sid_esc, sizeof sid_esc);

    char q[1024]; q[0] = '\0';
    SQLCat(q, sizeof q, "INSERT INTO rpgdamage ");
    SQLCat(q, sizeof q, "(steamid,enable,see_others,share_scope,size,gap,alpha,xoff,yoff,showdist,summode,sg_merge) ");
    SQLCatF(q, sizeof q,
        "VALUES ('%s',%d,%d,%d,%.1f,%.1f,%d,%.1f,%.1f,%.1f,%d,%d) ",
        sid_esc,
        g_SaveSnapshot[client].enable?1:0,
        g_SaveSnapshot[client].see_others?1:0,
        g_SaveSnapshot[client].share_scope,
        g_SaveSnapshot[client].size,
        g_SaveSnapshot[client].gap,
        g_SaveSnapshot[client].alpha,
        g_SaveSnapshot[client].xoff,
        g_SaveSnapshot[client].yoff,
        g_SaveSnapshot[client].showdist,
        g_SaveSnapshot[client].summode?1:0,
        g_SaveSnapshot[client].sgmerge?1:0
    );
    SQLCat(q, sizeof q, "ON DUPLICATE KEY UPDATE ");
    SQLCat(q, sizeof q, "enable=VALUES(enable), see_others=VALUES(see_others), share_scope=VALUES(share_scope), ");
    SQLCat(q, sizeof q, "size=VALUES(size), gap=VALUES(gap), alpha=VALUES(alpha), xoff=VALUES(xoff), yoff=VALUES(yoff), ");
    SQLCat(q, sizeof q, "showdist=VALUES(showdist), summode=VALUES(summode), sg_merge=VALUES(sg_merge)");

    LogInfo("[SaveSnapshot] Exec SQL (client=%d): %s", client, q);
    SQL_TQuery(g_DB, SQLCB_Save, q, client);
    return 2;
}

// 返回：0 未保存/失败；1 仅 Cookie；2 已发起 DB 异步保存
static int DB_Save(int client)
{
    ClampStyle(client);

    // 1) 若还没 Ready：排队保存（拍快照），并写本地 Cookie 兜底
    if (g_LoadState[client] != LS_Ready)
    {
        g_SaveSnapshot[client] = g_Plr[client]; // 关键：真拷贝到快照
        g_PendingSave[client] = true;

        Cookie_Save(client, true); // 强制写 Cookie 防丢
        CPrintToChat(client, "{olive}[HUD]{default} 已保存到本地（Cookie），并已排队，待加载完成后写入数据库。");
        LogInfo("[Save] Queued (not ready). client=%d state=%d", client, view_as<int>(g_LoadState[client]));
        return 1;
    }

    // 2) DB 不可用：只写 Cookie
    if (!g_UseMySQL || g_DB == INVALID_HANDLE || IsFakeClient(client))
    {
        Cookie_Save(client);
        CPrintToChat(client, "{olive}[HUD]{default} 设置已保存到本地（Cookie）。MySQL 未启用或不可用。");
        LogInfo("[Save] DB not available, saved to Cookie. client=%d", client);
        return 1;
    }

    // 3) 正常 DB 写入（UPSERT）
    char sid2[64], sid_esc[128];
    if (!GetClientAuthId(client, AuthId_Steam2, sid2, sizeof sid2) || StrEqual(sid2, "BOT"))
    {
        Cookie_Save(client);
        CPrintToChat(client, "{olive}[HUD]{default} 设置已保存到本地（Cookie）。无法获取有效 SteamID。");
        LogErr("[Save] No valid Steam2, saved to Cookie. client=%d", client);
        return 1;
    }
    SQL_EscapeString(g_DB, sid2, sid_esc, sizeof sid_esc);

    char q[1024]; q[0]='\0';
    SQLCat(q, sizeof q, "INSERT INTO rpgdamage ");
    SQLCat(q, sizeof q, "(steamid,enable,see_others,share_scope,size,gap,alpha,xoff,yoff,showdist,summode,sg_merge) ");
    SQLCatF(q, sizeof q,
        "VALUES ('%s',%d,%d,%d,%.1f,%.1f,%d,%.1f,%.1f,%.1f,%d,%d) ",
        sid_esc,
        g_Plr[client].enable?1:0,
        g_Plr[client].see_others?1:0,
        g_Plr[client].share_scope,
        g_Plr[client].size,
        g_Plr[client].gap,
        g_Plr[client].alpha,
        g_Plr[client].xoff,
        g_Plr[client].yoff,
        g_Plr[client].showdist,
        g_Plr[client].summode?1:0,
        g_Plr[client].sgmerge?1:0
    );
    SQLCat(q, sizeof q, "ON DUPLICATE KEY UPDATE ");
    SQLCat(q, sizeof q, "enable=VALUES(enable), see_others=VALUES(see_others), share_scope=VALUES(share_scope), ");
    SQLCat(q, sizeof q, "size=VALUES(size), gap=VALUES(gap), alpha=VALUES(alpha), xoff=VALUES(xoff), yoff=VALUES(yoff), ");
    SQLCat(q, sizeof q, "showdist=VALUES(showdist), summode=VALUES(summode), sg_merge=VALUES(sg_merge)");

    LogInfo("[Save] Exec SQL (client=%d): %s", client, q);
    SQL_TQuery(g_DB, SQLCB_Save, q, client);

    // 双写 Cookie：本地立即生效
    Cookie_Save(client);
    CPrintToChat(client, "{olive}[HUD]{default} 设置已保存（本地 Cookie + 数据库）。");
    return 2;
}

public void SQLCB_Save(Handle owner, Handle hndl, const char[] error, any data)
{
    int client = data;
    if (error[0] != '\0')
    {
        LogErr("[Save] SQL error for client %d: %s", client, error);
        DB_MarkConnectionLost(error);
    }
    else
    {
        LogInfo("[Save] SQL OK for client %d.", client);
    }
}

// ============ 插件信息 ============
public Plugin myinfo =
{
    name        = "[L4D2] Damage HUD (MySQL+Cookie, DB-first, fixes)",
    author      = "Loqi + you (mod by ChatGPT)",
    description = "Per-client damage digits with DB-first persistence + cookies + menus + admin sharing gate",
    version     = PLUGIN_VERSION,
    url         = "https://"
};

// ============ 生命周期 ============
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("damage_show");
    if (GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "仅支持 L4D2");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_hMaxTE = FindConVar("sv_multiplayer_maxtempentities");
    if (g_hMaxTE != null) g_hMaxTE.SetInt(512);

    // Cookie
    g_ck = new Cookie(COOKIE_NAME, "damage hud per-client", CookieAccess_Protected);

    // DB（异步）
    DB_BeginConnect();

    // 命令
    RegConsoleCmd("sm_dmgmenu", Cmd_Menu, "打开伤害数字设置菜单");
    RegAdminCmd("sm_dmgcookie",          Cmd_DmgCookie,        Admin_Generic, "Dump cookie & current settings");
    RegAdminCmd("sm_dmgdbstat",          Cmd_DmgDBStat,        Admin_Generic, "Show DB status & session charset");
    RegAdminCmd("sm_dmgforcesavecookie", Cmd_DmgForceSaveCookie, Admin_Generic, "Force save current settings to cookie");
    RegAdminCmd("sm_dmgdbprobe",         Cmd_DmgDBProbe,       Admin_Generic, "One-shot sync DB probe");
    // ★ 新增：允许使用本插件所需的管理员 Flag（留空=所有人可用；示例："bc"）
    g_hAllowedFlags = CreateConVar(
        "sm_dmg_allowed_flags",
        "",
        "Which admin flags are allowed to USE this plugin. Empty = everyone. Example: \"bc\"",
        FCVAR_NOTIFY
    );
    Gate_UpdateFromCvar();

    // ★ CVar 变更：即时重算并对全体生效
    g_hAllowedFlags.AddChangeHook(OnCvarChanged_AllowedFlags);

    // 事件/钩子
    HookEvent("player_left_safe_area", E_LeftSafe, EventHookMode_PostNoCopy);
    HookEvent("player_hurt", E_PlayerHurt);
    for (int i=1;i<=MaxClients;i++)
        if (IsClientInGame(i)) SDKHook(i, SDKHook_OnTakeDamagePost, SDK_OnTakeDamagePost);
}

public void OnClientConnected(int client)
{
    ResetClientState(client);
}

public void OnClientPutInServer(int client)
{
    g_bAdminObsViewAll[client] = false;

    SDKHook(client, SDKHook_OnTakeDamagePost, SDK_OnTakeDamagePost);

    if (IsFakeClient(client))
    {
        g_LoadState[client] = LS_Ready;
        return;
    }

    // 重新加入的真人默认置为“未加载”，但保留已经在进行中的 DB 读
    if (g_LoadState[client] != LS_DBPending)
        g_LoadState[client] = LS_None;

    // 看门狗：2 秒后若仍未加载且 DB Ready，则补发一次 DB_Load
    CreateTimer(2.0, Timer_DBEnsureLoad, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void OnCvarChanged_AllowedFlags(ConVar convar, const char[] oldValue, const char[] newValue)
{
    Gate_UpdateFromCvar();

    // 对当前在线玩家逐一执行门禁并保存
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
            Gate_EnforceFor(i, "cvar-change");
    }
}

// 在玩家通过 Steam 认证/权限检查后，立即触发 DB 加载（不依赖 Cookie 回调）
public void OnClientPostAdminCheck(int client)
{
    if (IsFakeClient(client)) return;

    Settings_Default(client); // 占位，避免 UI 空白
    DB_Load(client);          // DB 优先加载
    // ★ 新增：即时门禁（先把占位/加载中的状态压回禁用）
    Gate_EnforceFor(client, "postadmincheck");
}

// 仅缓存 Cookie（不在这里触发 DB_Load，避免某些时序下缺失）
public void OnClientCookiesCached(int client)
{
    if (IsFakeClient(client)) return;

    if (g_ck != null)
    {
        g_CookieRaw[client][0] = '\0';
        g_ck.Get(client, g_CookieRaw[client], sizeof(g_CookieRaw[]));
        g_HaveCookie[client] = (g_CookieRaw[client][0] != '\0');
    }
    else
    {
        g_HaveCookie[client] = false;
        g_CookieRaw[client][0] = '\0';
    }
}

public Action Timer_DBEnsureLoad(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client)) return Plugin_Stop;
    if (IsFakeClient(client))
    {
        g_LoadState[client] = LS_Ready;
        return Plugin_Stop;
    }

    if (g_LoadState[client] == LS_None && DB_EnsureReady())
    {
        Settings_Default(client);
        DB_Load(client);
        LogInfo("[LoadWatchdog] reissue DB_Load for client %d", client);
    }
    return Plugin_Stop;
}

public void OnMapStart()
{
    g_sprite = PrecacheModel(SPRITE_MATERIAL, true);

    // 仅清理运行期缓存（不要重置 g_Plr 的持久化字段）
    for (int i = 1; i <= L4D2_MAXPLAYERS; i++)
    {
        g_Plr[i].wpn_id         = -1;
        g_Plr[i].wpn_type       = -1;
        g_Plr[i].last_set_time  = 0.0;

        g_bNeverFire[i] = true;
        g_fTankIncap[i] = 0.0;

        for (int j = 1; j <= L4D2_MAXPLAYERS; j++)
        {
            g_SGbuf[i][j].victim = 0;
            g_SGbuf[i][j].attacker = 0;
            g_SGbuf[i][j].totalDamage = 0;
            g_SGbuf[i][j].isHeadshot = false;
            g_SGbuf[i][j].isCreated = false;

            g_Sum[i][j].needShow = false;
            g_Sum[i][j].totalDamage = 0;
            g_Sum[i][j].lastShowTime = 0.0;
            g_Sum[i][j].lastHitTime = 0.0;

            g_iVitcimHealth[i][j] = 0;
        }
    }
}

public void OnClientDisconnect(int client)
{
    if (IsClientConnected(client) && !IsFakeClient(client))
    {
        if (g_LoadState[client] == LS_Ready)
        {
            DB_Save(client); // Ready 才写库
        }
        else
        {
            Cookie_Save(client, true); // 未 Ready：仅 Cookie 兜底
            LogInfo("[Save@Disconnect] Not ready (state=%d), skip DB save; cookie only.", view_as<int>(g_LoadState[client]));
        }
    }

    ResetClientState(client);
    g_bAdminObsViewAll[client] = false;
}

// ============ 调试命令 ============
public Action Cmd_DmgCookie(int client, int args)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    PrintToConsole(client, "[DMGSHOW] ---- Cookie Dump ----");
    PrintToConsole(client, "[DMGSHOW] LoadState=%d UseMySQL=%d", view_as<int>(g_LoadState[client]), g_UseMySQL ? 1 : 0);

    if (g_ck == null)
    {
        PrintToConsole(client, "[DMGSHOW] Cookie object is NULL.");
        return Plugin_Handled;
    }

    char raw[256];
    raw[0] = '\0';
    g_ck.Get(client, raw, sizeof(raw));
    PrintToConsole(client, "[DMGSHOW] Raw cookie: %s", raw[0] ? raw : "(empty)");

    PrintToConsole(client, "[DMGSHOW] Current settings in memory:");
    PrintToConsole(client, "  enable=%d see_others=%d share_scope=%d", g_Plr[client].enable ? 1 : 0, g_Plr[client].see_others ? 1 : 0, g_Plr[client].share_scope);
    PrintToConsole(client, "  size=%.1f gap=%.1f alpha=%d", g_Plr[client].size, g_Plr[client].gap, g_Plr[client].alpha);
    PrintToConsole(client, "  xoff=%.1f yoff=%.1f showdist=%.1f", g_Plr[client].xoff, g_Plr[client].yoff, g_Plr[client].showdist);
    PrintToConsole(client, "  summode=%d sgmerge=%d", g_Plr[client].summode ? 1 : 0, g_Plr[client].sgmerge ? 1 : 0);
    return Plugin_Handled;
}

public Action Cmd_DmgDBStat(int client, int args)
{
    PrintToConsole(client, "[DMGSHOW] ---- DB Status ----");
    PrintToConsole(client, "[DMGSHOW] Ready=%d Connecting=%d Handle=%p RetryAfter=%.2f Now=%.2f",
        g_DbReady ? 1:0, g_DbConnecting ? 1:0, g_DB, g_DbRetryAfter, GetGameTime());

    if (!g_DbReady || g_DB == INVALID_HANDLE)
        return Plugin_Handled;

    Handle h = SQL_Query(g_DB,
        "SELECT @@character_set_client,@@character_set_connection,@@character_set_results,@@collation_connection");
    if (h == INVALID_HANDLE)
    {
        PrintToConsole(client, "[DMGSHOW] SQL_Query failed for session snapshot.");
        return Plugin_Handled;
    }
    if (SQL_FetchRow(h))
    {
        char a[64], b[64], c[64], d[64];
        SQL_FetchString(h, 0, a, sizeof a);
        SQL_FetchString(h, 1, b, sizeof b);
        SQL_FetchString(h, 2, c, sizeof c);
        SQL_FetchString(h, 3, d, sizeof d);
        PrintToConsole(client, "[DMGSHOW] Session charset: client=%s connection=%s results=%s coll=%s", a,b,c,d);
    }
    CloseHandle(h);
    return Plugin_Handled;
}

public Action Cmd_DmgForceSaveCookie(int client, int args)
{
    if (!IsValidClient(client)) return Plugin_Handled;
    Cookie_Save(client, true); // 强制
    PrintToConsole(client, "[DMGSHOW] Forced cookie save done.");
    return Plugin_Handled;
}

public Action Cmd_DmgDBProbe(int client, int args)
{
    char err[256];
    Handle tmp = SQL_Connect(DB_CONF_NAME, false, err, sizeof(err));
    if (tmp == INVALID_HANDLE)
    {
        PrintToConsole(client, "[DMGSHOW] Probe: SQL_Connect FAILED: %s", err);
        return Plugin_Handled;
    }

    bool ok = SQL_FastQuery(tmp, "SET NAMES utf8mb4");
    PrintToConsole(client, "[DMGSHOW] Probe: SET NAMES utf8mb4 -> %s", ok ? "OK" : "FAILED");

    Handle h = SQL_Query(tmp, "SELECT 1");
    if (h == INVALID_HANDLE)
    {
        PrintToConsole(client, "[DMGSHOW] Probe: SELECT 1 failed.");
    }
    else
    {
        PrintToConsole(client, "[DMGSHOW] Probe: SELECT 1 OK.");
        CloseHandle(h);
    }

    CloseHandle(tmp);
    return Plugin_Handled;
}

// ============ 菜单（分面板） ============

public Action Cmd_Menu(int client, int args)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    // ★ 新增：不满足则直接关并提示（也会保存）
    if (!Gate_ClientAllowed(client))
    {
        Gate_EnforceFor(client, "open-menu");
        CPrintToChat(client, "{olive}[HUD]{default} 未满足管理员 Flag 要求，无法使用此菜单。");
        return Plugin_Handled;
    }

    OpenRootMenu(client);
    return Plugin_Handled;
}

// 根菜单
static void OpenRootMenu(int client)
{
    Menu m = new Menu(Menu_Root);
    char state[32];
    switch (g_LoadState[client])
    {
        case LS_Ready:     strcopy(state, sizeof state, "已加载"); 
        case LS_DBPending: strcopy(state, sizeof state, "加载中"); 
        default:           strcopy(state, sizeof state, "未开始"); 
    }

    char title[128];
    Format(title, sizeof title, "伤害数字设置（根）\n配置状态：%s\n请选择一个分面板：", state);
    m.SetTitle(title);

    m.AddItem("style", "① 显示样式 / 字体 / 偏移");
    m.AddItem("share", "② 分享 / 可见性 / 管理功能");

    // 允许随时点保存；未就绪则走排队保存逻辑
    m.AddItem("save",  "保存当前设置");

    m.Display(client, MENU_TIME);
}

public int Menu_Root(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_End) { delete menu; return 0; }
    if (action != MenuAction_Select) return 0;

    char key[16];
    menu.GetItem(param2, key, sizeof key);

    if (StrEqual(key, "style")) OpenStyleMenu(client);
    else if (StrEqual(key, "share")) OpenShareMenu(client);
    else if (StrEqual(key, "save"))
    {
        ClampStyle(client);
        DB_Save(client);
        CPrintToChat(client, "{olive}[HUD]{default} 设置已保存。");
        OpenRootMenu(client);
    }
    return 0;
}

// 样式面板
static void OpenStyleMenu(int client)
{
    Menu m = new Menu(Menu_Style);
    char title[256];
    Format(title, sizeof title,
        "① 显示样式 / 字体 / 偏移\n开关: %s\n字号: %.1f  间距: %.1f  透明度: %d\nX偏移: %.1f  Y偏移: %.1f  最大距离: %.0f\n累加模式: %s  霰弹合并: %s",
        g_Plr[client].enable ? "开" : "关",
        g_Plr[client].size, g_Plr[client].gap, g_Plr[client].alpha,
        g_Plr[client].xoff, g_Plr[client].yoff, g_Plr[client].showdist,
        g_Plr[client].summode ? "开" : "关",
        g_Plr[client].sgmerge ? "开" : "关"
    );
    m.SetTitle(title);

    m.AddItem("toggle_enable", "切换：显示开关");
    m.AddItem("size+", "字号 +0.5");
    m.AddItem("size-", "字号 -0.5");
    m.AddItem("gap+",  "间距 +0.5");
    m.AddItem("gap-",  "间距 -0.5");
    m.AddItem("alpha+", "透明度 +10");
    m.AddItem("alpha-", "透明度 -10");
    m.AddItem("x+", "X偏移 +2");
    m.AddItem("x-", "X偏移 -2");
    m.AddItem("y+", "Y偏移 +2");
    m.AddItem("y-", "Y偏移 -2");
    m.AddItem("dist+", "最大距离 +250");
    m.AddItem("dist-", "最大距离 -250");
    m.AddItem("sum", "切换：累加模式");
    m.AddItem("sg",  "切换：霰弹合并");
    m.AddItem("back", "返回：根菜单");

    m.Display(client, MENU_TIME);
}
public int Menu_Style(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_End) { delete menu; return 0; }
    if (action != MenuAction_Select) return 0;

    char key[32];
    menu.GetItem(param2, key, sizeof key);

    if (StrEqual(key, "toggle_enable")) g_Plr[client].enable = !g_Plr[client].enable;
    else if (StrEqual(key, "size+")) g_Plr[client].size += 0.5;
    else if (StrEqual(key, "size-")) g_Plr[client].size -= 0.5;
    else if (StrEqual(key, "gap+"))  g_Plr[client].gap  += 0.5;
    else if (StrEqual(key, "gap-"))  g_Plr[client].gap  -= 0.5;
    else if (StrEqual(key, "alpha+")) g_Plr[client].alpha += 10;
    else if (StrEqual(key, "alpha-")) g_Plr[client].alpha -= 10;
    else if (StrEqual(key, "x+")) g_Plr[client].xoff += 2.0;
    else if (StrEqual(key, "x-")) g_Plr[client].xoff -= 2.0;
    else if (StrEqual(key, "y+")) g_Plr[client].yoff += 2.0;
    else if (StrEqual(key, "y-")) g_Plr[client].yoff -= 2.0;
    else if (StrEqual(key, "dist+")) g_Plr[client].showdist += 250.0;
    else if (StrEqual(key, "dist-")) g_Plr[client].showdist -= 250.0;
    else if (StrEqual(key, "sum")) g_Plr[client].summode = !g_Plr[client].summode;
    else if (StrEqual(key, "sg"))  g_Plr[client].sgmerge = !g_Plr[client].sgmerge;
    else if (StrEqual(key, "back")) { OpenRootMenu(client); return 0; }

    ClampStyle(client);
    OpenStyleMenu(client);
    return 0;
}

// 分享/可见性面板
static void OpenShareMenu(int client)
{
    Menu m = new Menu(Menu_Share);
    char title[256];
    char scopeText[16];
    strcopy(scopeText, sizeof scopeText, g_Plr[client].share_scope == 0 ? "仅自己" : "队友");
    Format(title, sizeof title,
        "② 分享 / 可见性 / 管理功能\n看他人（用于接收分享）: %s\n分享范围（只对管理员有效）: %s\n管理员对外分享权限: %s\n%s",
        g_Plr[client].see_others ? "开" : "关",
        scopeText,
        (IsAdminOrRoot(client) && g_Plr[client].show_other) ? "开启" : "关闭",
        (GetClientTeam(client) == 1 && IsAdminOrRoot(client)) ?
        (g_bAdminObsViewAll[client] ? "旁观：查看所有人生还者伤害【开】" : "旁观：查看所有人生还者伤害【关】") : ""
    );
    m.SetTitle(title);

    m.AddItem("toggle_see",    "切换：看他人（接收分享）");

    if (IsAdminOrRoot(client)) m.AddItem("scope", "切换：分享范围（仅自己/队友）");
    else                       m.AddItem("scope", "切换：分享范围（仅管理员可设）", ITEMDRAW_DISABLED);

    if (IsAdminOrRoot(client))
        m.AddItem("admin_showother", "切换：管理员对外分享权限");
    else
        m.AddItem("admin_showother", "管理员对外分享权限（需要管理员）", ITEMDRAW_DISABLED);

    if (GetClientTeam(client) == 1 && IsAdminOrRoot(client))
        m.AddItem("spec_view_all", "旁观：切换“查看所有人生还者伤害”");

    m.AddItem("back", "返回：根菜单");
    m.Display(client, MENU_TIME);
}

public int Menu_Share(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_End) { delete menu; return 0; }
    if (action != MenuAction_Select) return 0;

    char key[32];
    menu.GetItem(param2, key, sizeof key);

    if (StrEqual(key, "toggle_see"))
        g_Plr[client].see_others = !g_Plr[client].see_others;
    else if (StrEqual(key, "scope"))
    {
        if (IsAdminOrRoot(client))
            g_Plr[client].share_scope = (g_Plr[client].share_scope + 1) % 2;
        else
            CPrintToChat(client, "{olive}[HUD]{default} 只有管理员可以修改分享范围。");
    }
    else if (StrEqual(key, "admin_showother"))
    {
        if (IsAdminOrRoot(client))
        {
            g_Plr[client].show_other = !g_Plr[client].show_other;
            CPrintToChat(client, "{olive}[HUD]{default} 管理员对外分享已%s。", g_Plr[client].show_other ? "开启" : "关闭");
        }
        else CPrintToChat(client, "{olive}[HUD]{default} 只有管理员可开启该选项。");
    }
    else if (StrEqual(key, "spec_view_all"))
    {
        if (GetClientTeam(client) == 1 && IsAdminOrRoot(client))
        {
            g_bAdminObsViewAll[client] = !g_bAdminObsViewAll[client];
            PrintToChat(client, "\x04旁观显示\x01已切换：\x05%s",
                g_bAdminObsViewAll[client] ? "查看所有人生还者伤害【开】" : "查看所有人生还者伤害【关】");
        }
        else
        {
            PrintToChat(client, "\x03只有旁观中的管理员可以使用该开关。");
        }
    }
    else if (StrEqual(key, "back")) { OpenRootMenu(client); return 0; }

    ClampStyle(client);
    OpenShareMenu(client);
    return 0;
}

// ============ 提示 ============
void E_LeftSafe(Event event, const char[] name, bool dontBroadcast)
{
    // PrintToChatAll("\x04[伤害显示]\x05 输入 !dmgmenu 打开设置菜单。");
}

// ============ 事件/绘制 ============
public void E_PlayerHurt(Event hEvent, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
    int victim   = GetClientOfUserId(hEvent.GetInt("userid"));

    if (!IsValidClient(attacker) || !IsValidClient(victim)) return;
    if (GetClientTeam(attacker) != 2 || IsFakeClient(attacker)) return;
    // ★ 新增：门禁（就算其他插件改了 enable，也会被这里拦下）
    if (!Gate_ClientAllowed(attacker)) return;
    // 自己的功能开关（默认 false）
    if (!g_Plr[attacker].enable) return;

    int remain = hEvent.GetInt("health");
    int damage = hEvent.GetInt("dmg_health");
    bool forceHS = false;

    if (remain > 1) {
        g_iVitcimHealth[attacker][victim] = remain;
    } else {
        if (g_iVitcimHealth[attacker][victim] == 0)
            damage = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
        else
            damage = g_iVitcimHealth[attacker][victim];
        g_iVitcimHealth[attacker][victim] = 0;
        forceHS = true; // 致死一枪；在累加模式里仍会进入 Sum 缓存，最终一帧统一显示
    }
    g_AttackCache[attacker][victim].damage = damage;
    g_AttackCache[attacker][victim].forceHeadshot = forceHS;
}

public void SDK_OnTakeDamagePost(int victim, int attacker, int inflictor, float fdamage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3])
{
    if (!IsValidClient(attacker) || !IsValidClient(victim)) return;
    if (GetClientTeam(attacker) != 2 || IsFakeClient(attacker)) return;
    if (!g_Plr[attacker].enable) return;
    if (!Gate_ClientAllowed(attacker)) return;

    int wpn = (weapon == -1) ? inflictor : weapon;
    int dval = g_AttackCache[attacker][victim].damage;
    bool forceHS = g_AttackCache[attacker][victim].forceHeadshot;

    // 霰弹合并
    #if defined DMG_BUCKSHOT
    if (g_Plr[attacker].sgmerge && (damagetype & DMG_BUCKSHOT))
        Handle_Shotgun(attacker, victim, wpn, dval, damagetype, damagePosition, forceHS);
    else
        DisplayDamage(victim, attacker, wpn, dval, damagetype, damagePosition, forceHS);
    #else
        DisplayDamage(victim, attacker, wpn, dval, damagetype, damagePosition, forceHS);
    #endif

    g_AttackCache[attacker][victim].damage = 0;
    g_AttackCache[attacker][victim].forceHeadshot = false;
}

static void Handle_Shotgun(int attacker, int victim, int weapon, int damage, int damagetype, const float pos[3], bool forceHS)
{
    if (g_SGbuf[attacker][victim].isCreated)
    {
        g_SGbuf[attacker][victim].totalDamage += damage;
        if (forceHS) g_SGbuf[attacker][victim].isHeadshot = true;
    }
    else
    {
        g_SGbuf[attacker][victim].victim = victim;
        g_SGbuf[attacker][victim].attacker = attacker;
        g_SGbuf[attacker][victim].totalDamage = damage;
        g_SGbuf[attacker][victim].damageType = damagetype;
        g_SGbuf[attacker][victim].weapon     = weapon;
        g_SGbuf[attacker][victim].isHeadshot = forceHS;
        g_SGbuf[attacker][victim].damagePosition[0] = pos[0];
        g_SGbuf[attacker][victim].damagePosition[1] = pos[1];
        g_SGbuf[attacker][victim].damagePosition[2] = pos[2];

        DataPack pack = new DataPack();
        pack.WriteCell(attacker);
        pack.WriteCell(victim);
        g_SGbuf[attacker][victim].isCreated = true;
        RequestFrame(NextFrame_SG, pack);
    }
}
public void NextFrame_SG(DataPack pack)
{
    pack.Reset();
    int attacker = pack.ReadCell();
    int victim   = pack.ReadCell();
    delete pack;

    if (!IsValidClient(attacker) || !IsValidClient(victim)) {
        g_SGbuf[attacker][victim].isCreated = false;
        return;
    }

    if (g_SGbuf[attacker][victim].totalDamage > 0)
    {
        float tmp[3];
        tmp[0]=g_SGbuf[attacker][victim].damagePosition[0];
        tmp[1]=g_SGbuf[attacker][victim].damagePosition[1];
        tmp[2]=g_SGbuf[attacker][victim].damagePosition[2];

        DisplayDamage(
            victim, attacker,
            g_SGbuf[attacker][victim].weapon,
            g_SGbuf[attacker][victim].totalDamage,
            g_SGbuf[attacker][victim].damageType,
            tmp, g_SGbuf[attacker][victim].isHeadshot
        );
        g_SGbuf[attacker][victim].totalDamage = 0;
        g_SGbuf[attacker][victim].isHeadshot = false;
    }
    g_SGbuf[attacker][victim].isCreated = false;
}

static int PrintDigitsInOrder(int number)
{
    if (number < 0) return 0;
    if (number == 0) return 1;
    int cnt=0, t=number;
    while (t!=0) { cnt++; t/=10; }
    return cnt;
}

static int GetWpnType(int weapon)
{
    char s[64];
    if (!IsValidEdict(weapon)) return 3;
    GetEdictClassname(weapon, s, sizeof s);

    if (StrContains(s, "inferno", false) != -1 || StrContains(s, "entityflame", false) != -1) return 4;
    if (StrContains(s, "hunting", false) != -1 || StrContains(s, "sniper", false) != -1)   return 0;
    if (StrContains(s, "rifle", false)  != -1 || StrContains(s, "smg", false) != -1)       return 1;
    if (StrContains(s, "melee", false)  != -1) return 2;
    if (StrContains(s, "projectile", false) != -1) return 5;
    return 3;
}

static ReturnTwoFloat CalculatePoint(int client, const float base[3], float x1, float y1, float z1, float x2, float y2, float z2)
{
    ReturnTwoFloat val;
    float ang[3], dir[3];
    GetClientEyeAngles(client, ang);
    GetAngleVectors(ang, dir, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(dir, dir);
    NegateVector(dir);

    float up[3] = {0.0,0.0,1.0};
    float localX[3], localY[3];

    if (GetVectorDotProduct(dir, up) > 0.99)
    {
        float right[3] = {0.0,1.0,0.0};
        GetVectorCrossProduct(dir, right, localX);
    } else {
        GetVectorCrossProduct(dir, up, localX);
    }
    NormalizeVector(localX, localX);
    GetVectorCrossProduct(localX, dir, localY);
    NormalizeVector(localY, localY);

    float p1[3], p2[3], v1[3], v2[3];
    v1[0] = x1*localX[0] + y1*localY[0]; v1[1] = x1*localX[1] + y1*localY[1]; v1[2] = x1*localX[2] + y1*localY[2];
    v2[0] = x2*localX[0] + y2*localY[0]; v2[1] = x2*localX[1] + y2*localY[1]; v2[2] = x2*localX[2] + y2*localY[2];
    float n1[3], n2[3];
    n1[0] = z1*dir[0]; n1[1]=z1*dir[1]; n1[2]=z1*dir[2];
    n2[0] = z2*dir[0]; n2[1]=z2*dir[1]; n2[2]=z2*dir[2];

    p1[0] = base[0] + v1[0] + n1[0];
    p1[1] = base[1] + v1[1] + n1[1];
    p1[2] = base[2] + v1[2] + n1[2];

    p2[0] = base[0] + v2[0] + n2[0];
    p2[1] = base[1] + v2[1] + n2[1];
    p2[2] = base[2] + v2[2] + n2[2];

    val.startPt = p1;
    val.endPt   = p2;
    return val;
}

static void DrawNumber(const float StartPos[3], const float EndPos[3], int number, const int[] clients, int totals, float life, const int rgba[4], int speed, float width, float size)
{
    int Ptid[18], totalPt=0;
    switch (number)
    {
        case 0: { int tmp[]={1,5, 0,4, 0,1, 4,5}; for (int i=0;i<8;i++) Ptid[totalPt++]=tmp[i]; }
        case 1: { int tmp[]={1,5}; for (int i=0;i<2;i++) Ptid[totalPt++]=tmp[i]; }
        case 2: { int tmp[]={0,1, 1,3, 3,2, 2,4, 4,5}; for (int i=0;i<10;i++) Ptid[totalPt++]=tmp[i]; }
        case 3: { int tmp[]={0,1, 1,5, 5,4, 2,3}; for (int i=0;i<8;i++) Ptid[totalPt++]=tmp[i]; }
        case 4: { int tmp[]={0,2, 2,3, 1,5}; for (int i=0;i<6;i++) Ptid[totalPt++]=tmp[i]; }
        case 5: { int tmp[]={0,1, 0,2, 3,2, 3,5, 4,5}; for (int i=0;i<10;i++) Ptid[totalPt++]=tmp[i]; }
        case 6: { int tmp[]={0,1, 0,4, 3,2, 3,5, 4,5}; for (int i=0;i<10;i++) Ptid[totalPt++]=tmp[i]; }
        case 7: { int tmp[]={0,1, 1,5}; for (int i=0;i<4;i++) Ptid[totalPt++]=tmp[i]; }
        case 8: { int tmp[]={0,1, 1,5, 3,2, 4,0, 4,5}; for (int i=0;i<10;i++) Ptid[totalPt++]=tmp[i]; }
        case 9: { int tmp[]={0,1, 1,5, 3,2, 2,0, 4,5}; for (int i=0;i<10;i++) Ptid[totalPt++]=tmp[i]; }
    }

    float pt[6][3];
    pt[1] = EndPos; pt[1][2] = StartPos[2];
    pt[2] = StartPos; pt[2][2] = StartPos[2] - size;
    pt[3] = EndPos; pt[3][2] = EndPos[2] + size;
    pt[4] = StartPos; pt[4][2] = EndPos[2];
    pt[0] = StartPos; pt[5] = EndPos;

    for (int k=0;k<9;k++)
    {
        if (2*k+1 > totalPt) break;
        TE_SetupBeamPoints(pt[Ptid[2*k]], pt[Ptid[2*k+1]], g_sprite, 0, 0, 0, life, width, width, 1, 0.0, rgba, speed);
        TE_Send(clients, totals, 0.0);
    }
}

public void OnGameFrame()
{
    // 累加模式帧驱动
    for (int i=1;i<=L4D2_MAXPLAYERS;i++)
    {
        if (g_bNeverFire[i]) continue;
        if (!IsValidClient(i) || !IsPlayerAlive(i) || g_Sum[i][0].lastHitTime + 0.5 < GetGameTime())
        {
            g_bNeverFire[i] = true;
            g_Sum[i][0].needShow = false;
            continue;
        }
        for (int j=1;j<=L4D2_MAXPLAYERS;j++)
        {
            if (!g_Sum[i][j].needShow) continue;
            if (g_Sum[i][j].lastShowTime + UPDATE_INTERVAL >= GetGameTime()) continue;

            if (g_Sum[i][j].lastHitTime + 0.5 < GetGameTime())
            {
                g_Sum[i][j].needShow = false;
                g_Sum[i][j].totalDamage = 0;
                continue;
            }
            DisplayDamage(
                j, i,
                g_Sum[i][j].weapon,
                g_Sum[i][j].totalDamage,
                g_Sum[i][j].damageType,
                g_Sum[i][j].damagePosition,
                g_Sum[i][j].isHeadshot,
                true
            );
            g_Sum[i][j].lastShowTime = GetGameTime();
        }
    }
}

// —— 可见性/分享规则要点 ——
// 1) 自己永远能看见自己的数字（只要 enable=true）。
// 2) “看他人”仅决定我是否接收他人分享（默认 true 便于看管理员分享）。
// 3) 只有管理员可分享（show_other=true）并按 share_scope=0/1（仅自己/队友）分发；普通玩家强制仅自己，不对外分享。
// 4) 旁观管理员可选“查看所有人生还者伤害”。

static void BuildReceivers(int attacker, int recv[MAXPLAYERS], int &total)
{
    total = 0;
    for (int i=1;i<=MaxClients;i++)
    {
        if (!IsValidClient(i)) continue;

        // 1) 攻击者本人：始终接收
        if (i == attacker) { recv[total++]=i; continue; }

        // 2) 旁观者
        if (GetClientTeam(i) == 1)
        {
            if (IsAdminOrRoot(i) && g_bAdminObsViewAll[i])
                recv[total++] = i; // 旁观管理员“全览”
            continue;
        }

        // 3) 非旁观玩家：只有在攻击者“允许分享+管理员”时才有资格接收
        if (!(IsAdminOrRoot(attacker) && g_Plr[attacker].show_other)) continue;

        // 分享范围：仅自己/队友
        if (g_Plr[attacker].share_scope == 1) // 队友
        {
            if (GetClientTeam(i) != GetClientTeam(attacker)) continue;
        }
        else // 仅自己
        {
            continue; // 不向他人发
        }

        // 对方还需开启“看他人”
        if (!g_Plr[i].see_others) continue;

        recv[total++] = i;
    }
}

static void DisplayDamage(int victim, int attacker, int weapon, int damage, int damagetype, const float damagePosition[3], bool forceHeadshot=false, bool UpdateFrame=false)
{
    if (!IsValidClient(attacker) || !IsValidClient(victim)) return;
    if (!g_Plr[attacker].enable) return;
    if (!Gate_ClientAllowed(attacker)) return;

    if (g_Plr[attacker].wpn_id != weapon && weapon != -1 && IsValidEdict(weapon))
    {
        g_Plr[attacker].wpn_id   = weapon;
        g_Plr[attacker].wpn_type = GetWpnType(weapon);
    }

    int recv[MAXPLAYERS], total;
    BuildReceivers(attacker, recv, total);
    if (total <= 0) return;

    int zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
    if (zombieClass == ZC_TANK && (GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 1 || g_fTankIncap[victim] + 1.0 > GetGameTime()))
    {
        g_fTankIncap[victim] = GetGameTime();
        return;
    }

    int val = damage;
    if (val < 2 && g_Plr[attacker].wpn_type == 5) return;

    int rgba[4];
    int colorIndex;
    if ((damagetype & DMG_HEADSHOT) || forceHeadshot) colorIndex = 4;
    else if (GetClientTeam(victim) == 2) colorIndex = 0;
    else colorIndex = 2;
    rgba[0] = color[colorIndex][0];
    rgba[1] = color[colorIndex][1];
    rgba[2] = color[colorIndex][2];
    rgba[3] = g_Plr[attacker].alpha;

    float life;
    switch (g_Plr[attacker].wpn_type)
    {
        case 0: life = 0.8;
        case 1: life = 0.2;
        case 2: life = 0.6;
        case 3: life = 0.75;
        case 4: life = 0.1;
        case 5: life = 1.5;
        default: life = 0.6;
    }
    if (zombieClass == ZC_BOOMER) if (life < 0.5) life = 0.5;
    if (UpdateFrame) life = UPDATE_INTERVAL;

    // ★ 累加模式： lethal 一枪也进入合并，最后一帧统一显示
    if (g_Plr[attacker].summode && !UpdateFrame)
    {
        if (!g_Sum[attacker][victim].needShow || !g_Sum[attacker][0].needShow)
        {
            g_Sum[attacker][victim].needShow = true;
            g_Sum[attacker][0].needShow = true;
            g_Sum[attacker][victim].lastShowTime = 0.0;
            g_Sum[attacker][victim].totalDamage = val;
            g_bNeverFire[attacker] = false;
        }
        else g_Sum[attacker][victim].totalDamage += val;

        g_Sum[attacker][victim].damagePosition = damagePosition;
        g_Sum[attacker][victim].damageType = damagetype;
        g_Sum[attacker][victim].weapon = weapon;
        g_Sum[attacker][victim].isHeadshot = forceHeadshot;

        float now = GetGameTime();
        if (IsPlayerAlive(victim))
        {
            int zc = GetEntProp(victim, Prop_Send, "m_zombieClass");
            if (zc == ZC_TANK) now += 3.0;
            else if (g_Plr[attacker].wpn_type == 3) now += 0.5;
        }
        g_Sum[attacker][victim].lastHitTime = now;
        g_Sum[attacker][0].lastHitTime = now;
        return;
    }

    if (forceHeadshot)
    {
        // 在非累加路径下，致死一枪的展示时间稍微延长一点
        float temp_life = g_Sum[attacker][victim].lastHitTime + 0.5 - GetGameTime();
        life = (temp_life > 0.5) ? temp_life : 0.5;
        g_Sum[attacker][victim].needShow = false;
    }

    float z_distance = 40.0, distance, gap, size, width=0.8, vecPos[3], vecOrg[3];
    GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", vecPos);
    GetEntPropVector(victim,   Prop_Send, "m_vecOrigin", vecOrg);

    gap    = g_Plr[attacker].gap;
    size   = g_Plr[attacker].size;

    distance = GetVectorDistance(vecPos, vecOrg, true);
    if (distance > g_Plr[attacker].showdist * g_Plr[attacker].showdist && GetEntProp(attacker, Prop_Send, "m_hZoomOwner") == -1)
        return;

    bool is_near = false;
    if (distance <= 120.0 * 120.0)
    {
        float scale2 = (120.0 * 120.0) / distance;
        if (scale2 > 4.0) scale2 = 4.0;
        gap   /= scale2;
        size  /= scale2;
        z_distance = 1.0;
        width /= scale2;
        is_near = true;
    }
    else if (distance > 70.0 * 70.0 * 100.0)
    {
        float scale3 = distance / (70.0 * 70.0 * 100.0);
        if (scale3 > 2.0) scale3 = 2.0;
        gap   *= scale3;
        size  *= scale3;
        width *= scale3;
    }

    float dmgpos[3];
    dmgpos = damagePosition;
    if (dmgpos[0] == 0.0 || g_Plr[attacker].wpn_type == 2 || g_Plr[attacker].wpn_type == 5)
    {
        dmgpos = vecOrg;
        if (!is_near)
        {
            dmgpos[0] += GetRandomFloat(-20.0, 20.0);
            dmgpos[1] += GetRandomFloat(-20.0, 20.0);
        }
        dmgpos[2] += 56.0;
    }

    int count = PrintDigitsInOrder(val);
    int divisor = 1;
    for (int i=1;i<count;i++) divisor *= 10;

    float half_width = size * float(count) / 2.0;
    float x_start = half_width;
    float scale = (damagePosition[0] < vecOrg[0]) ? -1.0 : 1.0;
    if (is_near) scale = 0.0;

    int rgbaFull[4];
    rgbaFull[0] = rgba[0];
    rgbaFull[1] = rgba[1];
    rgbaFull[2] = rgba[2];
    rgbaFull[3] = rgba[3];

    int v = val;
    for (int i=0;i<count;i++)
    {
        float x_end = x_start - size;
        int digit = v / divisor;
        ReturnTwoFloat fval;
        fval = CalculatePoint(attacker,
            dmgpos,
            x_start + scale * g_Plr[attacker].xoff, g_Plr[attacker].yoff + size, z_distance,
            x_end   + scale * g_Plr[attacker].xoff, g_Plr[attacker].yoff - size, z_distance
        );
        DrawNumber(fval.startPt, fval.endPt, digit, recv, total, life,  rgbaFull, 1, width, size);
        v %= divisor;
        divisor /= 10;
        x_start = x_start - size - gap;
    }
}
// ★ 工具：从 cvar 读取并解析 flag 字符串（如 "bc"）
static void Gate_UpdateFromCvar()
{
    g_hAllowedFlags.GetString(g_sAllowedFlags, sizeof g_sAllowedFlags);
    TrimString(g_sAllowedFlags);

    if (g_sAllowedFlags[0] == '\0')
    {
        g_bGateActive = false;
        g_iAllowedBits = 0;
        return;
    }

    g_bGateActive = true;
    ReadFlagString(g_sAllowedFlags, g_iAllowedBits); // 解析为位掩码
}

// ★ 判定：该玩家是否被允许使用插件
static bool Gate_ClientAllowed(int client)
{
    if (!IsValidClient(client) || IsFakeClient(client)) return false;
    if (!g_bGateActive) return true; // 没有限制 → 放行

    // ROOT 永远放行
    int ufb = GetUserFlagBits(client);
    if ((ufb & ADMFLAG_ROOT) == ADMFLAG_ROOT) return true;

    // 允许：拥有任意一个指定 flag
    return (ufb & g_iAllowedBits) != 0;
}

// ★ 强制执行门禁 & 持久化（把不符合的人关掉并保存）
static void Gate_EnforceFor(int client, const char[] reason = "")
{
    if (!IsValidClient(client) || IsFakeClient(client)) return;

    if (Gate_ClientAllowed(client))
        return;

    bool changed = false;

    if (g_Plr[client].enable)        { g_Plr[client].enable = false; changed = true; }
    if (g_Plr[client].see_others)    { g_Plr[client].see_others = false; changed = true; }
    if (g_Plr[client].show_other)    { g_Plr[client].show_other = false; changed = true; }
    if (g_Plr[client].share_scope)   { g_Plr[client].share_scope = 0; changed = true; }

    if (changed)
    {
        ClampStyle(client);

        // 已加载 → 写 DB；未加载 → 写 Cookie 并排队
        if (g_LoadState[client] == LS_Ready) DB_Save(client);
        else Cookie_Save(client, true);

        if (IsClientInGame(client))
        {
            CPrintToChat(client, "{olive}[HUD]{default} 功能已禁用：未满足管理员 Flag 要求（%s）。",
                g_sAllowedFlags[0] ? g_sAllowedFlags : "无");
        }
        LogInfo("[Gate] client=%d blocked (%s), settings saved.", client, reason);
    }
}
