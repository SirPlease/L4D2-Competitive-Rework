#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <l4d2lib>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <CreateSurvivorBot>
#include <witch_and_tankifier>

// =============================================
// AnneServer Server Function (structured + BeQuiet-style)
// 仅保留你要求的静音功能：
//   - 抑制 server_cvar 改动广播
//   - 抑制玩家改名广播（含仅旁观者的选项）
//   - 旁观可见队内聊天
//   - 屏蔽以 ! / 开头的聊天命令输出
// 其他 TextMsg/PZDmgMsg、死亡/倒地/离开/电击器 等屏蔽项全部移除。
// 版本：2025-10-20
// =============================================

#define CVAR_FLAGS                     FCVAR_NOTIFY
#define IsValidClient(%1)              (1 <= %1 && %1 <= MaxClients && IsClientInGame(%1))
#define IsValidAliveClient(%1)         (IsValidClient(%1) && IsPlayerAlive(%1))

enum ZombieClass
{
    ZC_SMOKER = 1,
    ZC_BOOMER,
    ZC_HUNTER,
    ZC_SPITTER,
    ZC_JOCKEY,
    ZC_CHARGER,
    ZC_WITCH,
    ZC_TANK
};

static const char sFinalMapName[14][] =
{
    "c1m4_atrium",
    "c2m5_concert",
    "c3m4_plantation",
    "c4m5_milltown_escape",
    "c5m5_bridge",
    "c6m3_port",
    "c7m3_port",
    "c8m5_rooftop",
    "c9m2_lots",
    "c10m5_houseboat",
    "c11m5_runway",
    "c12m5_cornfield",
    "c13m4_cutthroatcreek",
    "c14m2_lighthouse"
};

public Plugin myinfo =
{
    name        = "AnneServer Server Function (quiet minimal)",
    author      = "def075, Caibiii, 东, simplified by ChatGPT",
    description = "Helpers + BeQuiet-style suppressors only (server_cvar / namechange / spec chat)",
    version     = "2025.10.20",
    url         = "https://github.com/Caibiii/AnneServer"
};

// ====== 全局 ConVar / 状态（保留原生还管理等） ======
ConVar hMaxSurvivors, hSurvivorsManagerEnable, hCvarAutoKickTank;
ConVar g_cvResetOnTransition;          // 满血+清背包（原逻辑）
ConVar g_cvHeal50OnTransition;         // 新增：通关/切图最低50实血+重置倒地次数

int   iMaxSurvivors, iEnable, iAutoKickTankEnable;
int   g_RoundWipeCount = 0;

bool  g_bWitchAndTankSystemAvailable = false;

// ---- 黑白提醒 ----
ConVar g_cvBWEnable, g_cvBWTeam, g_cvBWSound;
bool   g_bwAnnounced[MAXPLAYERS + 1];
char   g_bwSound[PLATFORM_MAX_PATH];

// ---- 仅保留 BeQuiet 风格静音开关 ----
ConVar hCvarCvarChange, hCvarNameChange, hCvarSpecNameChange, hCvarSpecSeeChat;
bool   bCvarChange, bNameChange, bSpecNameChange, bSpecSeeChat;

public void OnPluginStart()
{
    // ---- 声音屏蔽（烟花/演唱会）----
    AddNormalSoundHook(view_as<NormalSHook>(OnNormalSound));
    AddAmbientSoundHook(view_as<AmbientSHook>(OnAmbientSound));

    // ---- 事件注册（保留原逻辑）----
    HookEvent("witch_killed",            WitchKilled_Event);
    HookEvent("round_start",             RoundStart_Event);
    HookEvent("finale_win",              ResetSurvivors);
    HookEvent("map_transition",          ResetSurvivors);
    HookEvent("player_spawn",            Event_PlayerSpawn);
    HookEvent("player_incapacitated",    OnPlayerIncappedOrDeath);
    HookEvent("player_death",            OnPlayerIncappedOrDeath);

    // ---- 管理命令 ----
    RegConsoleCmd("sm_setbot", SetBot);
    RegAdminCmd("sm_kicktank", KickMoreTankThanOne, ADMFLAG_KICK, "有多只Tank时，随机踢至只有一只");
    SetConVarBounds(FindConVar("survivor_limit"), ConVarBound_Upper, true, 31.0);
    RegAdminCmd("sm_addbot",   ADMAddBot, ADMFLAG_ROOT, "添加一个生还者Bot（不会被本插件踢）");
    RegAdminCmd("sm_delbot",   ADMDelBot, ADMFLAG_ROOT, "删除一个未被接管的生还者Bot");
    RegConsoleCmd("sm_zs", ZiSha);
    RegConsoleCmd("sm_kill", ZiSha);

    // ---- 生还管理 ConVar ----
    hSurvivorsManagerEnable = CreateConVar("l4d_multislots_survivors_manager_enable", "0",
        "是否启用生还者数量管理 (0/1)", CVAR_FLAGS, true, 0.0, true, 1.0);
    hMaxSurvivors = CreateConVar("l4d_multislots_max_survivors", "4",
        "生还者最大人数（仅踢Bot，不踢真人，最小4，最大8）", CVAR_FLAGS, true, 4.0, true, 8.0);
    hCvarAutoKickTank = CreateConVar("l4d_multislots_autokicktank", "0",
        "当场上Tank>1时，是否自动踢至只剩1只 (0/1)", CVAR_FLAGS, true, 0.0, true, 1.0);

    // ---- 切图/通关重置开关 ----
    g_cvResetOnTransition = CreateConVar("anne_reset_on_transition", "0",
        "通关/切图时是否执行 RestoreHealth + ResetInventory (0=否,1=是)", CVAR_FLAGS, true, 0.0, true, 1.0);

    // ---- 最低50实血（仅在未启用满血清背包时使用）----
    g_cvHeal50OnTransition = CreateConVar("anne_heal50_on_transition", "0",
        "通关/切图时，若生还者实血<50则补至50，并重置倒地次数；>=50不变。仅在 anne_reset_on_transition=0 时生效",
        CVAR_FLAGS, true, 0.0, true, 1.0);

    // ---- 黑白提醒 ----
    HookEvent("revive_success",       Event_ReviveSuccess);
    HookEvent("heal_success",         Event_HealSuccess);
    HookEvent("defibrillator_used",   Event_DefibUsed);

    g_cvBWEnable = CreateConVar("l4d_bw_notify_enable", "1", "启用生还黑白提醒 (0/1)", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_cvBWTeam   = CreateConVar("l4d_bw_notify_team",   "1", "0=只提醒本人, 1=全队广播", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_cvBWSound  = CreateConVar("l4d_bw_notify_sound",  "ui/beep07.wav", "黑白时播放的音效（留空不播）", CVAR_FLAGS);
    g_cvBWSound.GetString(g_bwSound, sizeof(g_bwSound));
    g_cvBWSound.AddChangeHook(CvarChanged_BWSound);

    // ---- BeQuiet 风格：CVAR + 事件 + 聊天监听 ----
    hCvarCvarChange      = CreateConVar("bq_cvar_change_suppress", "1", "Silence Server Cvars being changed, this makes for a clean chat with no disturbances.");
    hCvarNameChange      = CreateConVar("bq_name_change_suppress", "1", "Silence Player name Changes.");
    hCvarSpecNameChange  = CreateConVar("bq_name_change_spec_suppress", "1", "Silence Spectating Player name Changes.");
    hCvarSpecSeeChat     = CreateConVar("bq_show_player_team_chat_spec", "1", "Show Spectators Survivors and Infected Team chat?");

    bCvarChange     = GetConVarBool(hCvarCvarChange);
    bNameChange     = GetConVarBool(hCvarNameChange);
    bSpecNameChange = GetConVarBool(hCvarSpecNameChange);
    bSpecSeeChat    = GetConVarBool(hCvarSpecSeeChat);

    hCvarCvarChange.AddChangeHook(cvarChanged);
    hCvarNameChange.AddChangeHook(cvarChanged);
    hCvarSpecNameChange.AddChangeHook(cvarChanged);
    hCvarSpecSeeChat.AddChangeHook(cvarChanged);

    // Events (Pre)
    HookEvent("server_cvar",       Event_ServerCvar_Pre,       EventHookMode_Pre);
    HookEvent("player_changename", Event_PlayerChangeName_Pre, EventHookMode_Pre);

    // Chat listeners
    AddCommandListener(Say_Callback,     "say");
    AddCommandListener(TeamSay_Callback, "say_team");

    // ---- 监听变更 & 初始化 ----
    hSurvivorsManagerEnable.AddChangeHook(ConVarChanged_Cvars);
    hMaxSurvivors.AddChangeHook(ConVarChanged_Cvars);
    hCvarAutoKickTank.AddChangeHook(ConVarChanged_Cvars);

    AutoExecConfig(true, "anne_server_helper"); // 统一写入 cfg/sourcemod/anne_server_helper.cfg

    ConVarChanged_Cvars(null, "", ""); // 初始化读取
    cvarChanged(null, "", "");        // 同步 BeQuiet 开关
}

public void OnAllPluginsLoaded()
{
    g_bWitchAndTankSystemAvailable = LibraryExists("witch_and_tankifier");
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "witch_and_tankifier")) g_bWitchAndTankSystemAvailable = true;
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "witch_and_tankifier")) g_bWitchAndTankSystemAvailable = false;
}

public void OnMapStart()
{
    if (g_bwSound[0] != ' ')
        PrecacheSound(g_bwSound, true);
}

public void OnConfigsExecuted()
{
    // 同步一次 CVar
    cvarChanged(null, "", "");
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
    iEnable             = hSurvivorsManagerEnable.IntValue;
    iMaxSurvivors       = hMaxSurvivors.IntValue;
    iAutoKickTankEnable = hCvarAutoKickTank.IntValue;

    if (!iEnable) return;

    int cur = GetSurvivorCount();
    if (cur < iMaxSurvivors)
    {
        int need = iMaxSurvivors - cur;
        for (int i = 0; i < need; i++)
            SpawnFakeClientNearRandomSurvivor();
    }
    else if (cur > iMaxSurvivors)
    {
        int over = cur - iMaxSurvivors;
        for (int i = 0; i < over; i++)
            if (!KickAnySurvivorBot()) break;
    }
}

// ====== BeQuiet：变更监听聚合 ======
void cvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    bCvarChange     = GetConVarBool(hCvarCvarChange);
    bNameChange     = GetConVarBool(hCvarNameChange);
    bSpecNameChange = GetConVarBool(hCvarSpecNameChange);
    bSpecSeeChat    = GetConVarBool(hCvarSpecSeeChat);
}

// ====== 事件抑制（仅保留这两个） ======
public Action Event_ServerCvar_Pre(Event event, const char[] name, bool dontBroadcast)
{
    if (bCvarChange) return Plugin_Handled;
    return Plugin_Continue;
}

public Action Event_PlayerChangeName_Pre(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(client)) return Plugin_Continue;

    if (GetClientTeam(client) == 1 && bSpecNameChange)
        return Plugin_Handled; // 旁观者改名静音

    if (bNameChange)
        return Plugin_Handled; // 全部改名静音

    return Plugin_Continue;
}

// ====== 聊天监听：拦截命令、旁观可见队内聊天 ======
public Action Say_Callback(int client, const char[] command, int args)
{
    // 无条件屏蔽以 ! 或 / 开头的命令输出（与 BeQuiet 一致）
    if (args >= 1)
    {
        char first[MAX_NAME_LENGTH];
        GetCmdArg(1, first, sizeof first);
        if (first[0] == '!' || first[0] == '/')
            return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action TeamSay_Callback(int client, const char[] command, int args)
{
    // 无条件屏蔽以 ! 或 / 开头的命令输出
    if (args >= 1)
    {
        char first[MAX_NAME_LENGTH];
        GetCmdArg(1, first, sizeof first);
        if (first[0] == '!' || first[0] == '/')
            return Plugin_Handled;
    }

    // 旁观可见队内聊天
    if (bSpecSeeChat && IsValidClient(client) && GetClientTeam(client) != 1)
    {
        char sChat[256];
        GetCmdArgString(sChat, sizeof sChat);
        StripQuotes(sChat);

        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsValidClient(i) || GetClientTeam(i) != 1) continue;
            if (GetClientTeam(client) == 2)
                CPrintToChat(i, "[{olive}旁观{default}] {blue}%N{default}：%s", client, sChat);
            else
                CPrintToChat(i, "[{olive}旁观{default}] {red}%N{default}：%s", client, sChat);
        }
    }
    return Plugin_Continue;
}

// ====== 原有逻辑：对局与管理 ======
public Action L4D2_OnEndVersusModeRound(bool countSurvivors)
{
    if (!countSurvivors && L4D_HasAnySurvivorLeftSafeArea())
    {
        g_RoundWipeCount++;
        CPrintToChatAll("[{olive}提示{default}] 这是你们第 {blue}%d{default} 次团灭，请继续努力", g_RoundWipeCount);
    }
    return Plugin_Continue;
}

public void Event_PlayerSpawn(Event hEvent, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(hEvent.GetInt("userid"));

    if (IsValidClient(client) && IsAiTank(client) && iAutoKickTankEnable)
        KickMoreTank(true);

    if (IsValidClient(client) && GetClientTeam(client) == 2)
        g_bwAnnounced[client] = false;
}

public void OnPlayerIncappedOrDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(client)) return;
    if (GetClientTeam(client) != 2)    return;

    if (IsTeamImmobilised())
        SlaySurvivors();
}

bool IsTeamImmobilised()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsSurvivor(i) && IsPlayerAlive(i))
        {
            if (!L4D_IsPlayerIncapacitated(i))
                return false;
        }
    }
    return true;
}

void SlaySurvivors()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsSurvivor(i) && IsPlayerAlive(i))
            ForcePlayerSuicide(i);
    }
}

// ====== 管理命令：生还者 Bot 增/删 & 对齐 ======
public Action ADMAddBot(int client, int args)
{
    if (client == 0 || !iEnable) return Plugin_Handled;

    AdminId id = GetUserAdmin(client);
    if (id == INVALID_ADMIN_ID || GetAdminImmunityLevel(id) < 90)
        return Plugin_Handled;

    if (IsAnySurvivorBotExists())
    {
        PrintToChat(client, "还有未接管的Bot，请先接管或等生还队满再试。");
        return Plugin_Handled;
    }

    ConVar surLimit = FindConVar("survivor_limit");
    if (surLimit.IntValue < 8)
    {
        PrintToChat(client, "不是 8 人运动，还没达到上限呢！");
        return Plugin_Handled;
    }

    if (SpawnFakeClientNearRandomSurvivor())
    {
        PrintToChat(client, "一个生还者Bot已生成。");
        SetConVarInt(surLimit, surLimit.IntValue + 1);
    }
    else
    {
        PrintToChat(client, "暂时无法生成生还者Bot。");
    }
    return Plugin_Handled;
}

public Action ADMDelBot(int client, int args)
{
    if (client == 0 || !iEnable) return Plugin_Handled;

    AdminId id = GetUserAdmin(client);
    if (id == INVALID_ADMIN_ID || GetAdminImmunityLevel(id) < 90)
        return Plugin_Handled;

    if (!KickAnySurvivorBot())
    {
        PrintToChat(client, "不存在未接管的Bot。");
    }
    else
    {
        ConVar surLimit = FindConVar("survivor_limit");
        SetConVarInt(surLimit, surLimit.IntValue - 1);
    }
    return Plugin_Handled;
}

public Action SetBot(int client, int args)
{
    if (!iEnable) return Plugin_Handled;

    int cur = GetSurvivorCount();
    if (cur < iMaxSurvivors)
    {
        int need = iMaxSurvivors - cur;
        for (int i = 0; i < need; i++)
            SpawnFakeClientNearRandomSurvivor();
    }
    else if (cur > iMaxSurvivors)
    {
        int over = cur - iMaxSurvivors;
        for (int i = 0; i < over; i++)
            if (!KickAnySurvivorBot()) break;
    }
    return Plugin_Handled;
}

public Action ZiSha(int client, int args)
{
    ForcePlayerSuicide(client);
    return Plugin_Handled;
}

// ====== 生还工具 ======
int GetSurvivorCount()
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsSurvivor(i))
            count++;
    return count;
}

bool IsAnySurvivorBotExists()
{
    for (int i = 1; i <= MaxClients; i++)
        if (IsValidClient(i) && GetClientTeam(i) == 2 && IsFakeClient(i))
            return true;
    return false;
}

bool KickAnySurvivorBot()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && GetClientTeam(i) == 2 && IsFakeClient(i))
        {
            KickClient(i, "AnneServer: remove surplus survivor bot.");
            return true;
        }
    }
    return false;
}

bool SpawnFakeClientNearRandomSurvivor()
{
    int anchor = PickRandomSurvivor(true);
    if (anchor == 0) return false;

    int fakeclient = CreateSurvivorBot();
    if (fakeclient > 0 && IsClientInGame(fakeclient))
    {
        float pos[3];
        GetClientAbsOrigin(anchor, pos);
        TeleportEntity(fakeclient, pos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }
    return false;
}

int PickRandomSurvivor(bool aliveOnly)
{
    int list[33];
    int n = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i) || GetClientTeam(i) != 2)
            continue;
        if (aliveOnly && !IsPlayerAlive(i))
            continue;
        list[n++] = i;
    }
    if (n == 0) return 0;
    return list[GetRandomInt(0, n - 1)];
}

// ====== 多Tank 踢出 ======
public Action KickMoreTankThanOne(int client, int args)
{
    if (client == 0) return Plugin_Continue;
    KickMoreTank(false);
    return Plugin_Handled;
}

void KickMoreTank(bool autoKick)
{
    int tanks[33];
    int tn = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i)) continue;
        if (IsAiTank(i))
            tanks[tn++] = i;
    }

    if (tn <= 1)
    {
        if (!autoKick)
            PrintToChatAll("一切正常，还想踢克逃课？");
        return;
    }

    int keepIndex = GetRandomInt(0, tn - 1);
    int keep = tanks[keepIndex];

    for (int k = 0; k < tn; k++)
    {
        int c = tanks[k];
        if (c == keep) continue;
        KickClient(c, "过分了啊，一个克就够难了, %N 被踢出", c);
    }
    PrintToChatAll("已经踢出多余的克");
}

bool IsAiTank(int client)
{
    return (GetInfectedClass(client) == view_as<int>(ZC_TANK) && IsFakeClient(client));
}

int GetInfectedClass(int client)
{
    if (IsValidInfected(client))
        return GetEntProp(client, Prop_Send, "m_zombieClass");
    return 0;
}

bool IsValidInfected(int client)
{
    return (IsValidClient(client) && GetClientTeam(client) == 3);
}

// ====== 最终章 Tank 限制 ======
public void RoundStart_Event(Event event, const char[] name, bool dontBroadcast)
{
    CreateTimer(1.0, Timer_SetFinaleTankRule, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_SetFinaleTankRule(Handle timer)
{
    if (!g_bWitchAndTankSystemAvailable) return Plugin_Stop;
    if (!L4D_IsMissionFinalMap()) return Plugin_Stop;

    char mapname[64];
    GetCurrentMap(mapname, sizeof(mapname));

    if (!IsOfficialFinal(mapname))
    {
        ServerCommand("static_tank_map %s", mapname);
        ServerCommand("tank_map_only_first_event %s", mapname);
    }
    return Plugin_Stop;
}

bool IsOfficialFinal(const char[] mapname)
{
    for (int i = 0; i < sizeof(sFinalMapName); i++)
    {
        if (StrEqual(sFinalMapName[i], mapname, false))
            return true;
    }
    return false;
}

// ====== 通关/切图重置 ======
public Action ResetSurvivors(Event event, const char[] name, bool dontBroadcast)
{
    g_RoundWipeCount = 0;

    if (g_cvResetOnTransition.BoolValue)
    {
        RestoreHealth();
        ResetInventory();
    }
    else if (g_cvHeal50OnTransition.BoolValue)
    {
        ApplyHealFloorTo50();
    }

    for (int i = 1; i <= MaxClients; i++)
        g_bwAnnounced[i] = false;

    return Plugin_Continue;
}

// 首离安全区：补给（含 Bot 复活）
public Action L4D_OnFirstSurvivorLeftSafeArea()
{
    SetBot(0, 0);
    if (!IsRealismORCoop())
        CreateTimer(0.5, Timer_AutoGive, _, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Stop;
}

public Action Timer_AutoGive(Handle timer)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsSurvivor(i)) continue;

        if (!IsPlayerAlive(i))
            L4D_RespawnPlayer(i);

        BypassAndExecuteCommand(i, "give", "pain_pills");
        BypassAndExecuteCommand(i, "give", "health");
        SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 0.0);
        SetEntProp(i,   Prop_Send, "m_currentReviveCount", 0);
        SetEntProp(i,   Prop_Send, "m_bIsOnThirdStrike", false);

        if (IsFakeClient(i))
        {
            for (int s = 0; s < 2; s++)
                DeleteInventoryItem(i, s);

            BypassAndExecuteCommand(i, "give", "smg_silenced");
            BypassAndExecuteCommand(i, "give", "pistol_magnum");
        }
    }
    return Plugin_Continue;
}

// ====== 巫婆奖励回血 ======
public void WitchKilled_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(client) || GetClientTeam(client) != 2) return;
    if (!IsPlayerAlive(client) || IsPlayerIncap(client))      return;

    int maxhp = GetEntProp(client, Prop_Data, "m_iMaxHealth");
    int target = GetSurvivorPermHealth(client) + 15;
    if (target > maxhp) target = maxhp;

    SetSurvivorPermHealth(client, target);
}

// ====== 背包/血量工具 ======
void ResetInventory()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsSurvivor(i)) continue;

        for (int s = 0; s <= 4; s++)
            DeleteInventoryItem(i, s);

        BypassAndExecuteCommand(i, "give", "pistol");
    }
}

void DeleteInventoryItem(int client, int slot)
{
    int item = GetPlayerWeaponSlot(client, slot);
    if (item > MaxClients)
        RemovePlayerItem(client, item);
}

void RestoreHealth()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsSurvivor(i)) continue;

        BypassAndExecuteCommand(i, "give", "health");
        SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 0.0);
        SetEntProp(i,   Prop_Send, "m_currentReviveCount", 0);
        SetEntProp(i,   Prop_Send, "m_bIsOnThirdStrike", false);
    }
}

// 最低 50 实血 + 重置倒地次数（>=50 不变）
void ApplyHealFloorTo50()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsSurvivor(i)) continue;

        int hp = GetSurvivorPermHealth(i);
        if (hp < 50)
            SetSurvivorPermHealth(i, 50);

        SetEntProp(i, Prop_Send, "m_currentReviveCount", 0);
        SetEntProp(i, Prop_Send, "m_bIsOnThirdStrike", false);
    }
}

void BypassAndExecuteCommand(int client, const char[] cmd, const char[] arg1)
{
    int flags = GetCommandFlags(cmd);
    SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", cmd, arg1);
    SetCommandFlags(cmd, flags);
}

// ====== 生还/常用判断 ======
stock bool IsSurvivor(int client)
{
    return (IsValidClient(client) && GetClientTeam(client) == 2);
}

stock bool IsValidPlayer(int client, bool AllowBot = true, bool AllowDeath = true)
{
    if (!IsValidClient(client)) return false;
    if (!AllowBot && IsFakeClient(client)) return false;
    if (!AllowDeath && !IsPlayerAlive(client)) return false;
    return true;
}

stock bool IsPlayerIncap(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

stock int  GetSurvivorPermHealth(int client)
{
    return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock void SetSurvivorPermHealth(int client, int health)
{
    SetEntProp(client, Prop_Send, "m_iHealth", health);
}

// ====== 黑白提醒 ======
void AnnounceBW(int client)
{
    if (!IsValidClient(client) || GetClientTeam(client) != 2) return;

    bool teamBroadcast = g_cvBWTeam.BoolValue;

    if (teamBroadcast)
    {
        CPrintToChatAll("[{olive}提示{default}] {green}%N{default} 已经 {olive}黑白{default}，请优先保护并治疗！", client);
        for (int i = 1; i <= MaxClients; i++)
            if (IsValidClient(i) && GetClientTeam(i) == 2)
                PrintHintText(i, "%N 已经黑白（再次倒地会直接死亡）！", client);
    }
    else
    {
        CPrintToChat(client, "[{olive}提示{default}] 你现在 {green}黑白{default}，请尽快治疗！");
        PrintHintText(client, "你现在黑白（再次倒地会直接死亡）！");
    }

    if (g_bwSound[0] != ' ')
    {
        for (int i = 1; i <= MaxClients; i++)
            if (IsValidClient(i) && GetClientTeam(i) == 2)
                EmitSoundToClient(i, g_bwSound);
    }
}

public Action Timer_CheckBW(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client) || GetClientTeam(client) != 2)
        return Plugin_Stop;

    if (g_cvBWEnable.BoolValue && IsThirdStrike(client) && !g_bwAnnounced[client])
    {
        AnnounceBW(client);
        g_bwAnnounced[client] = true;
    }
    return Plugin_Stop;
}

public void CvarChanged_BWSound(ConVar convar, const char[] oldValue, const char[] newValue)
{
    convar.GetString(g_bwSound, sizeof(g_bwSound));
    if (g_bwSound[0] != ' ')
        PrecacheSound(g_bwSound, true);
}

public void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
    int subject = GetClientOfUserId(event.GetInt("subject"));
    if (!IsValidClient(subject) || GetClientTeam(subject) != 2) return;

    CreateTimer(0.1, Timer_CheckBW, GetClientUserId(subject), TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
    int subject = GetClientOfUserId(event.GetInt("subject"));
    if (IsValidClient(subject) && GetClientTeam(subject) == 2)
        g_bwAnnounced[subject] = false;
}

public void Event_DefibUsed(Event event, const char[] name, bool dontBroadcast)
{
    int subject = GetClientOfUserId(event.GetInt("subject"));
    if (IsValidClient(subject) && GetClientTeam(subject) == 2)
        g_bwAnnounced[subject] = false;
}

bool IsThirdStrike(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike"));
}

// ====== 声音屏蔽（烟花/演唱会）======
public Action OnNormalSound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH],
                            int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
    return (StrContains(sample, "firewerks", true) > -1 && !IsRealismORCoop()) ? Plugin_Stop : Plugin_Continue;
}

public Action OnAmbientSound(char sample[PLATFORM_MAX_PATH], int &entity, float &volume,
                             int &level, int &pitch, float pos[3], int &flags, float &delay)
{
    return (StrContains(sample, "firewerks", true) > -1 && !IsRealismORCoop()) ? Plugin_Stop : Plugin_Continue;
}

stock bool IsRealismORCoop()
{
    char plugin_name[120];
    ConVar h = FindConVar("l4d_ready_cfg_name");
    if (h == null)
        return false;

    h.GetString(plugin_name, sizeof(plugin_name));
    return (StrContains(plugin_name, "AnneCoop", false) != -1 || StrContains(plugin_name, "AnneRealism", false) != -1);
}
