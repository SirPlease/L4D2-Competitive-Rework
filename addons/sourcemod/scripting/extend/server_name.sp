#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <SteamWorks>

#define DESC_RECOMPUTE_INTERVAL 10.0

/*
 * =====================================================
 *  Anne 系列：服务器名 + GameDescription 动态更新
 *  规则：
 *  - 未载入配置（l4d_ready_cfg_name 为空/无）：GameDescription = "电信服"
 *  - 载入配置：GameDescription = "电信服-<模式>[<几特><几秒>]"
 *      * <模式>：普通药役/硬核药役/Anne战役/Anne写实/牛牛冲刺/HT训练/女巫派对/单人装逼/或原 cfg 名
 *      * Anne战役/Anne写实：几特几秒来自 dirspawn_count / dirspawn_interval
 *      * 其它：来自 l4d_infected_limit / versus_special_respawn_interval
 *  - 服务器名（房间名）：{hostname}{gamemode}
 *      => hostname设置的名字[<模式>][缺人][无mod][<几特><几秒>]
 *      * [缺人]：未满员显示（Anne 系列只看幸存者位）
 *      * [无mod]：l4d2_addons_eclipse == 0 时显示
 *
 *  性能与节流：
 *  - 开服 / OnConfigsExecuted：立即重算一次 description（仅写缓存）
 *  - 每 10 秒重算一次 description（仅写缓存）
 *  - OnGameFrame：每帧推送当前缓存到 SteamWorks
 * =====================================================
 */

public Plugin myinfo =
{
    name        = "Anne ServerName & GameDescription",
    author      = "东",
    description = "动态服务器名 + GameDescription [几特几秒]",
    version     = "1.4.5",
    url         = ""
};

// -----------------------------
// ConVars
// -----------------------------
ConVar
    cvarServerNameFormatCase1,   // 用于生成服务器名后缀（{Confogl}{Full}{MOD}{AnneHappy}）
    cvarMpGameMode,              // 实际是 l4d_ready_cfg_name
    cvarSI,                      // l4d_infected_limit
    cvarMpGameMin,               // versus_special_respawn_interval
    cvarHostName,                // hostname
    cvarMainName,                // sn_main_name（默认“电信服”）
    cvarMod,                     // l4d2_addons_eclipse
    cvarHostPort,                // hostport
    cvarDirCount,                // dirspawn_count
    cvarDirInterval;             // dirspawn_interval

// -----------------------------
// 其它全局
// -----------------------------
Handle HostName = INVALID_HANDLE; // KeyValues: 端口 → servername 映射

char SavePath[256];
char g_sDefaultN[68];

ConVar g_hHostNameFormat;        // sn_hostname_format（默认 "{hostname}{gamemode}"）

// ======= GameDescription 推送缓存与定时器 =======
static char  g_sDescComputed[128];   // 最近一次“重算”得到的描述

// -----------------------------
// Lifecycle
// -----------------------------
public void OnPluginStart()
{
    HostName = CreateKeyValues("AnneHappy");
    BuildPath(Path_SM, SavePath, sizeof(SavePath) - 1, "configs/hostname/hostname.txt");
    if (FileExists(SavePath))
    {
        FileToKeyValues(HostName, SavePath);
    }

    cvarHostName = FindConVar("hostname");
    cvarHostPort = FindConVar("hostport");

    // 默认主名按你的要求设为“电信服”
    cvarMainName = CreateConVar("sn_main_name", "电信服");

    // {hostname}{gamemode}：{gamemode} 会被我们构造的后缀替换
    g_hHostNameFormat = CreateConVar("sn_hostname_format", "{hostname}{gamemode}");

    // 用于生成服务器名后缀的模板
    cvarServerNameFormatCase1 = CreateConVar("sn_hostname_format1", "{Confogl}{Full}{MOD}{AnneHappy}");

    cvarMod = FindConVar("l4d2_addons_eclipse");

    // 人数变化时刷新服务器名（不触发 description 重算）
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
    HookEvent("player_bot_replace", Event_PlayerTeam, EventHookMode_Post);
    HookEvent("bot_player_replace", Event_PlayerTeam, EventHookMode_Post);
}

public void OnAllPluginsLoaded()
{
    cvarSI          = FindConVar("l4d_infected_limit");
    cvarMpGameMin   = FindConVar("versus_special_respawn_interval");
    cvarMpGameMode  = FindConVar("l4d_ready_cfg_name");
    cvarMod         = FindConVar("l4d2_addons_eclipse");

    cvarDirCount    = FindConVar("dirspawn_count");
    cvarDirInterval = FindConVar("dirspawn_interval");
    StartDescriptionTimer();
}

public void OnConfigsExecuted()
{
    if (cvarSI == null)                cvarSI = FindConVar("l4d_infected_limit");
    if (cvarMpGameMin == null)         cvarMpGameMin = FindConVar("versus_special_respawn_interval");
    if (cvarMpGameMode == null)        cvarMpGameMode = FindConVar("l4d_ready_cfg_name");
    if (cvarMod == null)               cvarMod = FindConVar("l4d2_addons_eclipse");
    if (cvarDirCount == null)          cvarDirCount = FindConVar("dirspawn_count");
    if (cvarDirInterval == null)       cvarDirInterval = FindConVar("dirspawn_interval");

    // 关心的 ConVar 仅用于“服务器名”即时刷新；description 改为定时重算
    if (cvarSI != null)                cvarSI.AddChangeHook(OnCvarChanged);
    if (cvarMpGameMin != null)         cvarMpGameMin.AddChangeHook(OnCvarChanged);
    if (cvarMpGameMode != null)        cvarMpGameMode.AddChangeHook(OnCvarChanged);
    if (cvarMod != null)               cvarMod.AddChangeHook(OnCvarChanged);
    if (cvarDirCount != null)          cvarDirCount.AddChangeHook(OnCvarChanged);
    if (cvarDirInterval != null)       cvarDirInterval.AddChangeHook(OnCvarChanged);

    // 开服后：立即重算一次（只写缓存）
    RecomputeDescriptionCached();

    // 刷新服务器名（房间名）
    Update();
}

public void OnMapStart()
{
    if (HostName != INVALID_HANDLE)
        CloseHandle(HostName);

    HostName = CreateKeyValues("AnneHappy");
    BuildPath(Path_SM, SavePath, sizeof(SavePath) - 1, "configs/hostname/hostname.txt");
    if (FileExists(SavePath))
    {
        FileToKeyValues(HostName, SavePath);
    }

    // 换图时也重算一次缓存
    RecomputeDescriptionCached();
}

public void OnPluginEnd()
{
    if (HostName != INVALID_HANDLE) {
        CloseHandle(HostName);
        HostName = INVALID_HANDLE;
    }

    cvarMpGameMode   = null;
    cvarMpGameMin    = null;
    cvarSI           = null;
    cvarMod          = null;
    cvarDirCount     = null;
    cvarDirInterval  = null;
}

public void Event_PlayerTeam(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    // 人员变化：只更新服务器名（不重算 description）
    Update();
}

public void OnCvarChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
    // ConVar 变化：只更新服务器名（description 交给 10s 定时器）
    Update();
}

// -----------------------------
// 主更新入口（仅服务器名；description 不在此推送）
// -----------------------------
public void Update()
{
    if (cvarMpGameMode == null) {
        ChangeServerName();
    } else {
        UpdateServerName();
    }
}

// -----------------------------
// 每帧推送当前缓存到 SteamWorks。
// -----------------------------
public void OnGameFrame()
{
    SteamWorks_SetGameDescription(g_sDescComputed);
}

// -----------------------------
// 启动 10s GameDescription 缓存重算定时器
// -----------------------------
void StartDescriptionTimer()
{
    CreateTimer(DESC_RECOMPUTE_INTERVAL, Timer_RecomputeDesc, _, TIMER_REPEAT);
}

// -----------------------------
// 定时重算（10s），只更新缓存
// -----------------------------
public Action Timer_RecomputeDesc(Handle timer, any data)
{
    RecomputeDescriptionCached();
    return Plugin_Continue;
}

// -----------------------------
// 立即按当前 cvar 重算一次描述（只写入缓存）
// -----------------------------
void RecomputeDescriptionCached()
{
    char desc[128];
    BuildGameDescription(desc, sizeof(desc));
    strcopy(g_sDescComputed, sizeof(g_sDescComputed), desc);
}

// -----------------------------
// 构造 GameDescription 文本（跟随模式标签）：
// 未载入配置：电信服
// 已载入配置：电信服-<模式>[<几特><几秒>]
// -----------------------------
void BuildGameDescription(char[] out, int maxlen)
{
    // 读取模式 cvar
    char cfg[128];
    cfg[0] = '\0';
    if (cvarMpGameMode != null) {
        GetConVarString(cvarMpGameMode, cfg, sizeof(cfg));
    }

    // 未载入配置：只显示“电信服”
    if (cfg[0] == '\0') {
        Format(out, maxlen, "电信服");
        return;
    }

    // 模式识别
    bool isAnneHappy    = (StrContains(cfg, "AnneHappy",   false) != -1);
    bool isHardCore     = (StrContains(cfg, "HardCore",    false) != -1);
    bool isShotgun      = (StrContains(cfg, "Shotgun",     false) != -1);
    bool isAnneCoop     = (StrContains(cfg, "AnneCoop",    false) != -1);
    bool isAnneRealism  = (StrContains(cfg, "AnneRealism", false) != -1);
    bool isAllCharger   = (StrContains(cfg, "AllCharger",  false) != -1);
    bool is1vHunters    = (StrContains(cfg, "1vHunters",   false) != -1);
    bool isWitchParty   = (StrContains(cfg, "WitchParty",  false) != -1);
    bool isAlone        = (StrContains(cfg, "Alone",       false) != -1);

    // 标签文本
    char mode[32];
    if (isAnneHappy) {
        if (isShotgun) {
            strcopy(mode, sizeof(mode), "喷子药役");
        } else {
            strcopy(mode, sizeof(mode), isHardCore ? "硬核药役" : "普通药役");
        }
    } else if (isAnneCoop) {
        strcopy(mode, sizeof(mode), "Anne战役");
    } else if (isAnneRealism) {
        strcopy(mode, sizeof(mode), "Anne写实");
    } else if (isAllCharger) {
        strcopy(mode, sizeof(mode), "牛牛冲刺");
    } else if (is1vHunters) {
        strcopy(mode, sizeof(mode), "HT训练");
    } else if (isWitchParty) {
        strcopy(mode, sizeof(mode), "女巫派对");
    } else if (isAlone) {
        strcopy(mode, sizeof(mode), "单人装逼");
    } else {
        // 未识别到 Anne 系列就直接显示原 cfg 值
        strcopy(mode, sizeof(mode), cfg);
    }

    // 选择“几特几秒”的来源
    bool usesDirSpawn = (isAnneCoop || isAnneRealism);
    int  siCount      = 0;
    int  siInterval   = -1;

    if (usesDirSpawn) {
        if (cvarDirCount != null)        siCount = GetConVarInt(cvarDirCount);
        else if (cvarSI != null)         siCount = GetConVarInt(cvarSI);

        if (cvarDirInterval != null)     siInterval = RoundToNearest(GetConVarFloat(cvarDirInterval));
        else if (cvarMpGameMin != null)  siInterval = GetConVarInt(cvarMpGameMin);
    } else {
        if (cvarSI != null)              siCount = GetConVarInt(cvarSI);
        if (cvarMpGameMin != null)       siInterval = GetConVarInt(cvarMpGameMin);
    }

    // 最终格式：电信服-<模式>[<几特><几秒>]
    if (siCount > 0 && siInterval >= 0) {
        Format(out, maxlen, "电信服-%s[%d特%d秒]", mode, siCount, siInterval);
    } else {
        Format(out, maxlen, "电信服-%s", mode);
    }
}

// -----------------------------
// 服务器名构建（hostname设置的名字[<模式>][缺人][无mod][<几特><几秒>]）
// -----------------------------
public void UpdateServerName()
{
    char sReadyUpCfgName[128], FinalHostname[128], buffer[128];
    bool IsAnne = false;

    GetConVarString(cvarServerNameFormatCase1, FinalHostname, sizeof(FinalHostname));

    if (cvarMpGameMode != null)
        GetConVarString(cvarMpGameMode, sReadyUpCfgName, sizeof(sReadyUpCfgName));
    else
        sReadyUpCfgName[0] = '\0';

    // 模式判定
    bool isAnneHappy    = (StrContains(sReadyUpCfgName, "AnneHappy",   false) != -1);
    bool isHardCore     = (StrContains(sReadyUpCfgName, "HardCore",    false) != -1);
    bool isShotgun      = (StrContains(sReadyUpCfgName, "Shotgun",     false) != -1);
    bool isAnneCoop     = (StrContains(sReadyUpCfgName, "AnneCoop",    false) != -1);
    bool isAnneRealism  = (StrContains(sReadyUpCfgName, "AnneRealism", false) != -1);
    bool isAllCharger   = (StrContains(sReadyUpCfgName, "AllCharger",  false) != -1);
    bool is1vHunters    = (StrContains(sReadyUpCfgName, "1vHunters",   false) != -1);
    bool isWitchParty   = (StrContains(sReadyUpCfgName, "WitchParty",  false) != -1);
    bool isAlone        = (StrContains(sReadyUpCfgName, "Alone",       false) != -1);

    if (isAnneHappy) {
        if (isShotgun) {
            ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}", "[喷子药役]");
        } else {
            ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}", isHardCore ? "[硬核药役]" : "[普通药役]");
        }
        IsAnne = true;
    }
    else if (isAnneCoop) {
        ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}", "[Anne战役]");
        IsAnne = true;
    }
    else if (isAnneRealism) {
        ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}", "[Anne写实]");
        IsAnne = true;
    }
    else if (isAllCharger) {
        ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}", "[牛牛冲刺]");
        IsAnne = true;
    }
    else if (is1vHunters) {
        ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}", "[HT训练]");
        IsAnne = true;
    }
    else if (isWitchParty) {
        ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}", "[女巫派对]");
        IsAnne = true;
    }
    else if (isAlone) {
        ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}", "[单人装逼]");
        IsAnne = true;
    }
    else {
        // 未识别：显示原 cfg 值，避免留空
        if (sReadyUpCfgName[0] != '\0') {
            Format(buffer, sizeof(buffer), "[%s]", sReadyUpCfgName);
            ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}", buffer);
        } else {
            ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}", "");
        }
        IsAnne = false;
    }

    // [缺人]
    if (IsTeamFull(IsAnne)) {
        ReplaceString(FinalHostname, sizeof(FinalHostname), "{Full}", "");
    } else {
        ReplaceString(FinalHostname, sizeof(FinalHostname), "{Full}", "[缺人]");
    }

    // [无MOD]
    if (cvarMod == null || GetConVarInt(cvarMod) != 0) {
        ReplaceString(FinalHostname, sizeof(FinalHostname), "{MOD}", "");
    } else {
        ReplaceString(FinalHostname, sizeof(FinalHostname), "{MOD}", "[无MOD]");
    }

    // 统一拼接“[几特几秒]”
    int siCount = 0;
    int siInterval = -1;

    if (isAnneCoop || isAnneRealism) {
        if (cvarDirCount != null)        siCount = GetConVarInt(cvarDirCount);
        else if (cvarSI != null)         siCount = GetConVarInt(cvarSI);

        if (cvarDirInterval != null)     siInterval = RoundToNearest(GetConVarFloat(cvarDirInterval));
        else if (cvarMpGameMin != null)  siInterval = GetConVarInt(cvarMpGameMin);
    } else if (IsAnne) {
        if (cvarSI != null)              siCount = GetConVarInt(cvarSI);
        if (cvarMpGameMin != null)       siInterval = GetConVarInt(cvarMpGameMin);
    }

    if (IsAnne && siCount > 0 && siInterval >= 0) {
        Format(buffer, sizeof(buffer), "[%d特%d秒]", siCount, siInterval);
        ReplaceString(FinalHostname, sizeof(FinalHostname), "{AnneHappy}", buffer);
    } else {
        ReplaceString(FinalHostname, sizeof(FinalHostname), "{AnneHappy}", "");
    }

    // 注入为 {gamemode}，与 {hostname} 拼合
    ChangeServerName(FinalHostname);
}

// 是否满员（Anne：只看幸存者；其他：幸存者+特感玩家）
bool IsTeamFull(bool IsAnne = false)
{
    int sum = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsPlayer(i) && !IsFakeClient(i)) {
            sum++;
        }
    }
    if (sum == 0) {
        return true;
    }
    if (IsAnne) {
        return sum >= GetConVarInt(FindConVar("survivor_limit"));
    } else {
        return sum >= (GetConVarInt(FindConVar("survivor_limit")) + GetConVarInt(FindConVar("z_max_player_zombies")));
    }
}

bool IsPlayer(int client)
{
    return (IsValidClient(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3));
}

public bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

// -----------------------------
// 应用最终服务器名（支持端口映射）
// {hostname}{gamemode}：gamemode 即我们构造的“[<模式>][缺人][无mod][<几特><几秒>]”
// -----------------------------
void ChangeServerName(const char[] suffix = "")
{
    char sPath[128], ServerPort[128];
    GetConVarString(cvarHostPort, ServerPort, sizeof(ServerPort));

    if (HostName == INVALID_HANDLE)
        HostName = CreateKeyValues("AnneHappy");

    KvJumpToKey(HostName, ServerPort, false);
    KvGetString(HostName, "servername", sPath, sizeof(sPath));
    KvGoBack(HostName);

    char sNewName[128];
    if (strlen(sPath) == 0)
    {
        GetConVarString(cvarMainName, sNewName, sizeof(sNewName));
    }
    else
    {
        GetConVarString(g_hHostNameFormat, sNewName, sizeof(sNewName)); // 默认 "{hostname}{gamemode}"
        ReplaceString(sNewName, sizeof(sNewName), "{hostname}", sPath);
        ReplaceString(sNewName, sizeof(sNewName), "{gamemode}", suffix);
    }

    SetConVarString(cvarHostName, sNewName);
    SetConVarString(cvarMainName, sNewName);
    strcopy(g_sDefaultN, sizeof(g_sDefaultN), sNewName);
}
