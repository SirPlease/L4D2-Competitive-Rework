#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
    name        = "L4D2 Dynamic Ammo (dirspawn only)",
    author      = "morzlee",
    description = "仅依据 dirspawn_count 与 dirspawn_interval 动态调整弹药",
    version     = "1.0.1",
    url         = ""
};

// 外部 cvar（仅此二者）
ConVar g_DirCount = null;      // dirspawn_count
ConVar g_DirItv   = null;      // dirspawn_interval

// 算法参数
ConVar g_Enable;
ConVar g_BaseSI;               // 基准 SI（默认 4）
ConVar g_BaseItv;              // 基准间隔（默认 35.0s）
ConVar g_Alpha;                // SI 影响指数（默认 1.0）
ConVar g_Beta;                 // 间隔影响指数（默认 0.5）
ConVar g_MinMult;              // 倍率下限（默认 0.6）
ConVar g_MaxMult;              // 倍率上限（默认 3.0）
ConVar g_RefillMode;           // 0仅限上限 1回满上限 2强制等于目标
ConVar g_Debug;

// 各类武器“预备弹药”基准
ConVar g_BaseSMG;              // SMG/MAC/MP5     默认 650
ConVar g_BaseRifle;            // 步枪            默认 360
ConVar g_BasePump;             // 泵动霰弹        默认 72
ConVar g_BaseAuto;             // 连发霰弹        默认 90
ConVar g_BaseSniper;           // 狙击            默认 180
ConVar g_BaseGL;               // 榴弹            默认 30
ConVar g_AllowM60;             // 是否处理 M60    默认 0

float g_LastMult = 1.0;

static void DBG(const char[] fmt, any ...)
{
    if (!g_Debug || !g_Debug.BoolValue) return;

    char buf[256];
    VFormat(buf, sizeof(buf), fmt, 2);  // 2 = 从可变参开始的第一个参数索引
    PrintToServer("[DynAmmo] %s", buf);
}

// ———————————— 绑定/监听外部 cvar ————————————
void TryBindExternalCvars()
{
    if (g_DirCount == null)
    {
        ConVar cv = FindConVar("dirspawn_count");
        if (cv != null) { g_DirCount = cv; HookConVarChange(g_DirCount, OnDirChanged); }
    }
    if (g_DirItv == null)
    {
        ConVar cv = FindConVar("dirspawn_interval");
        if (cv != null) { g_DirItv = cv; HookConVarChange(g_DirItv, OnDirChanged); }
    }
}

public void OnDirChanged(ConVar cvar, const char[] ov, const char[] nv)
{
    RecalcAndApply(true);
}

// ———————————— 倍率计算 ————————————
float ComputeMultiplier()
{
    if (g_DirCount == null || g_DirItv == null)
    {
        DBG("未发现 dirspawn_count / dirspawn_interval，使用 1.0 倍。");
        return 1.0;
    }

    float si   = float(g_DirCount.IntValue);
    float itv  = g_DirItv.FloatValue;

    float bsi  = g_BaseSI.FloatValue;
    float bitv = g_BaseItv.FloatValue;
    float a    = g_Alpha.FloatValue;
    float b    = g_Beta.FloatValue;
    float lo   = g_MinMult.FloatValue;
    float hi   = g_MaxMult.FloatValue;

    if (si <= 0.0 || itv <= 0.0) return 1.0;

    float mult = Pow(si / bsi, a) * Pow(bitv / itv, b);

    if (mult < lo) mult = lo;
    if (mult > hi) mult = hi;

    DBG("si=%.1f itv=%.1f  -> mult=%.3f", si, itv, mult);
    return mult;
}

// ———————————— 武器分类/读取设置预备弹药 ————————————
enum WeaponCat { W_NONE, W_SMG, W_RIFLE, W_PUMP, W_AUTO, W_SNIPER, W_GL, W_M60 }

WeaponCat GetWeaponCategory(int weapon)
{
    if (!IsValidEntity(weapon)) return W_NONE;
    char cls[64]; GetEntityClassname(weapon, cls, sizeof(cls));

    if (StrContains(cls, "weapon_rifle_m60", false) >= 0)            return W_M60;
    if (StrContains(cls, "weapon_grenade_launcher", false) >= 0)     return W_GL;

    if (StrContains(cls, "weapon_smg", false) >= 0)                  return W_SMG;
    if (StrContains(cls, "weapon_rifle", false) >= 0)                return W_RIFLE;

    if (StrContains(cls, "weapon_shotgun_spas", false) >= 0
     || StrContains(cls, "weapon_autoshotgun", false) >= 0)          return W_AUTO;

    if (StrContains(cls, "weapon_shotgun_chrome", false) >= 0
     || StrContains(cls, "weapon_pumpshotgun", false) >= 0
     || StrContains(cls, "weapon_shotgun", false) >= 0)              return W_PUMP;

    if (StrContains(cls, "weapon_hunting_rifle", false) >= 0
     || StrContains(cls, "weapon_sniper_military", false) >= 0
     || StrContains(cls, "weapon_sniper_awp", false) >= 0
     || StrContains(cls, "weapon_sniper_scout", false) >= 0)         return W_SNIPER;

    return W_NONE;
}

int BaseReserveFor(WeaponCat c)
{
    switch (c)
    {
        case W_SMG:   return g_BaseSMG.IntValue;
        case W_RIFLE: return g_BaseRifle.IntValue;
        case W_PUMP:  return g_BasePump.IntValue;
        case W_AUTO:  return g_BaseAuto.IntValue;
        case W_SNIPER:return g_BaseSniper.IntValue;
        case W_GL:    return g_BaseGL.IntValue;
        case W_M60:   return 0; // 默认不改 M60
    }
    return 0;
}

bool ValidSurvivorAlive(int cl)
{
    return (1 <= cl <= MaxClients) && IsClientInGame(cl) && IsPlayerAlive(cl) && GetClientTeam(cl) == 2;
}

bool GetAmmoType(int weapon, int &type)
{
    if (!IsValidEntity(weapon)) return false;
    type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    return type >= 0;
}

int GetReserve(int cl, int type)  { return GetEntProp(cl, Prop_Send, "m_iAmmo", _, type); }
void SetReserve(int cl, int type, int val) { SetEntProp(cl, Prop_Send, "m_iAmmo", val, _, type); }

// 应用到单人
void ApplyToClient(int cl, float mult)
{
    int wep = GetPlayerWeaponSlot(cl, 0);
    if (!IsValidEntity(wep)) return;

    WeaponCat cat = GetWeaponCategory(wep);
    if (cat == W_M60 && !g_AllowM60.BoolValue) return;

    int base = BaseReserveFor(cat);
    if (base <= 0) return;

    int type;
    if (!GetAmmoType(wep, type)) return;

    int target = RoundToNearest(float(base) * mult);
    int cur    = GetReserve(cl, type);

    int mode   = g_RefillMode.IntValue;
    int out    = cur;

    if (mode == 0) { if (cur > target) out = target; }
    else if (mode == 1) { if (cur < target) out = target; }
    else { out = target; } // 2

    if (out != cur) { SetReserve(cl, type, out); DBG("Apply #%d cat=%d base=%d cur=%d -> %d", cl, cat, base, cur, out); }
}

void ApplyToAll(float mult)
{
    for (int i = 1; i <= MaxClients; i++) if (ValidSurvivorAlive(i)) ApplyToClient(i, mult);
}

// ———————————— 重算 + 应用 ————————————
void RecalcAndApply(bool forceApply=false)
{
    if (!g_Enable.BoolValue) return;

    float m = ComputeMultiplier();
    if (forceApply || FloatAbs(m - g_LastMult) > 0.02)
    {
        g_LastMult = m;
        ApplyToAll(m);
    }
}

// ———————————— 生命周期/事件 ————————————
public void OnPluginStart()
{
    CreateConVar("l4d2_dynamic_ammo_version", "1.0.1", "dirspawn-only dynamic ammo", FCVAR_NOTIFY|FCVAR_DONTRECORD);

    g_Enable     = CreateConVar("l4d2_dynamic_ammo_enable", "1", "启用(1/0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_BaseSI     = CreateConVar("l4d2_dynamic_ammo_base_si", "4", "基准 SI", FCVAR_NOTIFY, true, 1.0);
    g_BaseItv    = CreateConVar("l4d2_dynamic_ammo_base_interval", "35.0", "基准刷特间隔(秒)", FCVAR_NOTIFY, true, 1.0);
    g_Alpha      = CreateConVar("l4d2_dynamic_ammo_alpha", "1.0", "SI 指数", FCVAR_NOTIFY, true, 0.0);
    g_Beta       = CreateConVar("l4d2_dynamic_ammo_beta", "0.5", "间隔指数", FCVAR_NOTIFY, true, 0.0);
    g_MinMult    = CreateConVar("l4d2_dynamic_ammo_min_mult", "1.0", "倍率下限", FCVAR_NOTIFY, true, 0.1);
    g_MaxMult    = CreateConVar("l4d2_dynamic_ammo_max_mult", "6.0", "倍率上限", FCVAR_NOTIFY, true, 0.5);
    g_RefillMode = CreateConVar("l4d2_dynamic_ammo_refill_mode", "1", "0仅限上限 1回满上限(默认) 2强制等于目标", FCVAR_NOTIFY, true, 0.0, true, 2.0);
    g_AllowM60   = CreateConVar("l4d2_dynamic_ammo_allow_m60", "0", "是否处理 M60", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_Debug      = CreateConVar("l4d2_dynamic_ammo_debug", "0", "调试输出", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    g_BaseSMG    = CreateConVar("l4d2_dynamic_ammo_base_smg", "650", "SMG 基础预备弹", FCVAR_NOTIFY);
    g_BaseRifle  = CreateConVar("l4d2_dynamic_ammo_base_rifle", "360", "步枪 基础预备弹", FCVAR_NOTIFY);
    g_BasePump   = CreateConVar("l4d2_dynamic_ammo_base_pump", "72",  "泵动 基础预备弹", FCVAR_NOTIFY);
    g_BaseAuto   = CreateConVar("l4d2_dynamic_ammo_base_auto", "90",  "连发 基础预备弹", FCVAR_NOTIFY);
    g_BaseSniper = CreateConVar("l4d2_dynamic_ammo_base_sniper","180","狙击 基础预备弹", FCVAR_NOTIFY);
    g_BaseGL     = CreateConVar("l4d2_dynamic_ammo_base_gl", "30",   "榴弹 基础预备弹", FCVAR_NOTIFY);

    HookEvent("round_start",   E_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("item_pickup",   E_ItemPickup);
    HookEvent("ammo_pickup",   E_AmmoPickup);
    HookEvent("player_spawn",  E_PlayerSpawn);

    RegAdminCmd("sm_da_recalc", Cmd_Recalc, ADMFLAG_GENERIC, "手动重算并应用");

    AutoExecConfig(true, "l4d2_dynamic_ammo");

    TryBindExternalCvars();
    RecalcAndApply(true);
}

public void OnMapStart() { TryBindExternalCvars(); }

public void OnClientPutInServer(int cl)   { SDKHook(cl, SDKHook_WeaponEquipPost, OnEquipPost); }
public void OnClientDisconnect(int cl)    { SDKUnhook(cl, SDKHook_WeaponEquipPost, OnEquipPost); }

public void OnEquipPost(int cl, int wep)
{
    if (!g_Enable.BoolValue) return;
    if (!ValidSurvivorAlive(cl)) return;
    ApplyToClient(cl, g_LastMult);
}

public void E_RoundStart(Event e, const char[] name, bool dontBroadcast)
{
    g_LastMult = 1.0;
    RecalcAndApply(true);
}

public void E_ItemPickup(Event e, const char[] name, bool nb)
{
    int cl = GetClientOfUserId(e.GetInt("userid"));
    if (ValidSurvivorAlive(cl)) ApplyToClient(cl, g_LastMult);
}

public void E_AmmoPickup(Event e, const char[] name, bool nb)
{
    int cl = GetClientOfUserId(e.GetInt("userid"));
    if (ValidSurvivorAlive(cl)) ApplyToClient(cl, g_LastMult);
}

public void E_PlayerSpawn(Event e, const char[] name, bool nb)
{
    int cl = GetClientOfUserId(e.GetInt("userid"));
    if (ValidSurvivorAlive(cl)) ApplyToClient(cl, g_LastMult);
}

public Action Cmd_Recalc(int cl, int args)
{
    RecalcAndApply(true);
    ReplyToCommand(cl, "[DynAmmo] 已重算并应用。当前倍率=%.3f", g_LastMult);
    return Plugin_Handled;
}
