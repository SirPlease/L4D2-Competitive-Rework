#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <weaponhandling>
#include <left4dhooks>

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define ZOMBIECLASS_TANK 8

#define MAX_WEAPON_NAME 64
#define MAX_RULE_KEY 160
#define MAX_SELECTOR 64

#define ATTR_COUNT 10

enum PerPlayerWeaponAttr
{
    Attr_Damage = 0,
    Attr_TankDamage,
    Attr_Rate,
    Attr_Reload,
    Attr_Deploy,
    Attr_Melee,
    Attr_Throw,
    Attr_Speed,
    Attr_Clip,
    Attr_Reserve
};

static const char g_sAttrNames[ATTR_COUNT][24] =
{
    "damage",
    "tankdamage",
    "rate",
    "reload",
    "deploy",
    "melee",
    "throw",
    "speed",
    "clip",
    "reserve"
};

StringMap g_hSessionRules[MAXPLAYERS + 1];
StringMap g_hConfigRules = null;
StringMap g_hClipApplied = null;
StringMap g_hReserveApplied = null;

ConVar g_hEnabled = null;
ConVar g_hSyncInterval = null;
ConVar g_hClipMode = null;
ConVar g_hReserveMode = null;
ConVar g_hSurvivorsOnly = null;
ConVar g_hDebug = null;

Handle g_hSyncTimer = null;

int g_iLastWeaponRef[MAXPLAYERS + 1];
bool g_bLateLoad = false;
bool g_bWeaponHandling = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int errMax)
{
    EngineVersion engine = GetEngineVersion();
    if (engine != Engine_Left4Dead2) {
        strcopy(error, errMax, "This plugin only supports Left 4 Dead 2.");
        return APLRes_SilentFailure;
    }

    g_bLateLoad = late;
    return APLRes_Success;
}

public Plugin myinfo =
{
    name = "L4D2 Per-Player Weapon Attributes",
    author = "morzlee, Codex",
    description = "Applies per-player weapon attribute overrides without touching global weapon scripts.",
    version = "0.1.0",
    url = ""
};

public void OnPluginStart()
{
    CreateConVar("l4d2_pwa_version", "0.1.0", "L4D2 per-player weapon attributes version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    g_hEnabled = CreateConVar("l4d2_pwa_enable", "1", "Enable per-player weapon attributes.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hSyncInterval = CreateConVar("l4d2_pwa_sync_interval", "0.25", "Interval for speed/ammo synchronization.", FCVAR_NOTIFY, true, 0.05, true, 2.0);
    g_hClipMode = CreateConVar("l4d2_pwa_clip_mode", "0", "0=cap clip only, 1=set clip once per weapon entity.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hReserveMode = CreateConVar("l4d2_pwa_reserve_mode", "0", "0=cap reserve only, 1=set reserve once per client/ammo type, 2=force every sync.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
    g_hSurvivorsOnly = CreateConVar("l4d2_pwa_survivors_only", "1", "Only apply player weapon attributes to survivors.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hDebug = CreateConVar("l4d2_pwa_debug", "0", "Enable debug output.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hSyncInterval.AddChangeHook(OnSyncIntervalChanged);
    g_bWeaponHandling = LibraryExists("WeaponHandling");

    g_hConfigRules = new StringMap();
    g_hClipApplied = new StringMap();
    g_hReserveApplied = new StringMap();

    for (int i = 1; i <= MaxClients; i++) {
        g_hSessionRules[i] = new StringMap();
        g_iLastWeaponRef[i] = INVALID_ENT_REFERENCE;
    }

    RegAdminCmd("sm_pwa", Cmd_SetAttr, ADMFLAG_ROOT, "sm_pwa <target> <weapon|*> <attr> <value>");
    RegAdminCmd("sm_pwa_set", Cmd_SetAttr, ADMFLAG_ROOT, "sm_pwa_set <target> <weapon|*> <attr> <value>");
    RegAdminCmd("sm_pwa_reset", Cmd_ResetAttr, ADMFLAG_ROOT, "sm_pwa_reset <target> [weapon|*] [attr|all]");
    RegAdminCmd("sm_pwa_list", Cmd_ListAttr, ADMFLAG_GENERIC, "sm_pwa_list [target]");
    RegAdminCmd("sm_pwa_reload", Cmd_ReloadConfig, ADMFLAG_ROOT, "Reload configs/l4d2_player_weapon_attrs.cfg");

    HookEvent("round_start", Event_RoundReset, EventHookMode_PostNoCopy);
    HookEvent("item_pickup", Event_PlayerMayNeedSync);
    HookEvent("weapon_fire", Event_PlayerMayNeedSync);
    HookEvent("ammo_pickup", Event_PlayerMayNeedSync);
    HookEvent("player_spawn", Event_PlayerMayNeedSync);

    AutoExecConfig(true, "l4d2_player_weapon_attrs");
    LoadAttributeConfig();
    RestartSyncTimer();

    if (g_bLateLoad) {
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i)) {
                OnClientPutInServer(i);
            }
        }
    }
}

public void OnPluginEnd()
{
    if (g_hSyncTimer != null) {
        KillTimer(g_hSyncTimer);
        g_hSyncTimer = null;
    }

}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
    g_iLastWeaponRef[client] = INVALID_ENT_REFERENCE;
}

public void OnClientDisconnect(int client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);

    if (g_hSessionRules[client] != null) {
        g_hSessionRules[client].Clear();
    }

    g_iLastWeaponRef[client] = INVALID_ENT_REFERENCE;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (strcmp(classname, "infected") == 0 || strcmp(classname, "witch") == 0) {
        SDKHook(entity, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
    }
}

public void OnMapStart()
{
    ClearEntityApplyCaches();
    RestartSyncTimer();
}

public void OnMapEnd()
{
    g_hSyncTimer = null;
}

public void OnConfigsExecuted()
{
    LoadAttributeConfig();
}

void OnSyncIntervalChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    RestartSyncTimer();
}

public void OnLibraryAdded(const char[] name)
{
    if (strcmp(name, "WeaponHandling") == 0) {
        g_bWeaponHandling = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (strcmp(name, "WeaponHandling") == 0) {
        g_bWeaponHandling = false;
    }
}

Action Cmd_SetAttr(int client, int args)
{
    if (args < 4) {
        ReplyToCommand(client, "Usage: sm_pwa <target> <weapon|*> <attr> <value>");
        ReplyToCommand(client, "Attrs: damage, tankdamage, rate, reload, deploy, melee, throw, speed, clip, reserve");
        return Plugin_Handled;
    }

    char targetArg[64], weapon[MAX_WEAPON_NAME], attrArg[32], valueArg[32];
    GetCmdArg(1, targetArg, sizeof(targetArg));
    GetCmdArg(2, weapon, sizeof(weapon));
    GetCmdArg(3, attrArg, sizeof(attrArg));
    GetCmdArg(4, valueArg, sizeof(valueArg));

    NormalizeWeaponName(weapon, sizeof(weapon));

    int attr = FindAttrIndex(attrArg);
    if (attr == -1) {
        ReplyToCommand(client, "[PWA] Unknown attribute: %s", attrArg);
        return Plugin_Handled;
    }

    float value = 0.0;
    if (!ParseStrictFloat(valueArg, value)) {
        ReplyToCommand(client, "[PWA] Invalid numeric value: %s", valueArg);
        return Plugin_Handled;
    }

    if (!IsValidAttrValue(attr, value)) {
        ReplyToCommand(client, "[PWA] Invalid value %.3f for %s.", value, g_sAttrNames[attr]);
        return Plugin_Handled;
    }

    int targets[MAXPLAYERS], count;
    char targetName[MAX_TARGET_LENGTH];
    bool tnIsMl;
    count = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tnIsMl);

    if (count <= 0) {
        ReplyToTargetError(client, count);
        return Plugin_Handled;
    }

    for (int i = 0; i < count; i++) {
        SetSessionRule(targets[i], weapon, view_as<PerPlayerWeaponAttr>(attr), value);
        SyncClient(targets[i]);
    }

    ReplyToCommand(client, "[PWA] Set %s %s = %.3f for %s.", weapon, g_sAttrNames[attr], value, targetName);
    if (RequiresWeaponHandling(view_as<PerPlayerWeaponAttr>(attr)) && !g_bWeaponHandling) {
        ReplyToCommand(client, "[PWA] Note: %s requires WeaponHandling.smx, which is not loaded.", g_sAttrNames[attr]);
    }
    return Plugin_Handled;
}

Action Cmd_ResetAttr(int client, int args)
{
    if (args < 1) {
        ReplyToCommand(client, "Usage: sm_pwa_reset <target> [weapon|*] [attr|all]");
        return Plugin_Handled;
    }

    char targetArg[64], weapon[MAX_WEAPON_NAME], attrArg[32];
    GetCmdArg(1, targetArg, sizeof(targetArg));

    if (args >= 2) {
        GetCmdArg(2, weapon, sizeof(weapon));
    } else {
        strcopy(weapon, sizeof(weapon), "*");
    }
    NormalizeWeaponName(weapon, sizeof(weapon));

    int attr = -1;
    if (args >= 3) {
        GetCmdArg(3, attrArg, sizeof(attrArg));
        if (strcmp(attrArg, "all", false) != 0 && strcmp(attrArg, "*", false) != 0) {
            attr = FindAttrIndex(attrArg);
            if (attr == -1) {
                ReplyToCommand(client, "[PWA] Unknown attribute: %s", attrArg);
                return Plugin_Handled;
            }
        }
    }

    int targets[MAXPLAYERS], count;
    char targetName[MAX_TARGET_LENGTH];
    bool tnIsMl;
    count = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tnIsMl);

    if (count <= 0) {
        ReplyToTargetError(client, count);
        return Plugin_Handled;
    }

    int removed = 0;
    for (int i = 0; i < count; i++) {
        removed += RemoveSessionRules(targets[i], weapon, attr);
        SyncClient(targets[i]);
    }

    ReplyToCommand(client, "[PWA] Removed %d session rule(s) for %s.", removed, targetName);
    return Plugin_Handled;
}

Action Cmd_ListAttr(int client, int args)
{
    char targetArg[64];
    if (args >= 1) {
        GetCmdArg(1, targetArg, sizeof(targetArg));
    } else if (client > 0) {
        Format(targetArg, sizeof(targetArg), "#%d", GetClientUserId(client));
    } else {
        strcopy(targetArg, sizeof(targetArg), "@all");
    }

    int targets[MAXPLAYERS], count;
    char targetName[MAX_TARGET_LENGTH];
    bool tnIsMl;
    count = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tnIsMl);

    if (count <= 0) {
        ReplyToTargetError(client, count);
        return Plugin_Handled;
    }

    for (int i = 0; i < count; i++) {
        PrintClientRules(client, targets[i]);
    }

    return Plugin_Handled;
}

Action Cmd_ReloadConfig(int client, int args)
{
    LoadAttributeConfig();

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            SyncClient(i);
        }
    }

    ReplyToCommand(client, "[PWA] Config reloaded. %d config rule(s).", g_hConfigRules.Size);
    return Plugin_Handled;
}

void Event_RoundReset(Event event, const char[] name, bool dontBroadcast)
{
    ClearEntityApplyCaches();

    for (int i = 1; i <= MaxClients; i++) {
        g_iLastWeaponRef[i] = INVALID_ENT_REFERENCE;
        if (IsClientInGame(i)) {
            SyncClient(i);
        }
    }
}

void Event_PlayerMayNeedSync(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);
    if (IsClientInGameSafe(client)) {
        CreateTimer(0.1, Timer_SyncOneUserId, userid, TIMER_FLAG_NO_MAPCHANGE);
    }
}

Action Timer_SyncOneUserId(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (IsClientInGameSafe(client)) {
        SyncClient(client);
    }

    return Plugin_Stop;
}

void RestartSyncTimer()
{
    if (g_hSyncTimer != null) {
        KillTimer(g_hSyncTimer);
        g_hSyncTimer = null;
    }

    g_hSyncTimer = CreateTimer(g_hSyncInterval.FloatValue, Timer_SyncAll, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_SyncAll(Handle timer)
{
    if (!g_hEnabled.BoolValue) {
        return Plugin_Continue;
    }

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGameSafe(i)) {
            SyncClient(i);
        }
    }

    return Plugin_Continue;
}

Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_hEnabled.BoolValue || damage <= 0.0 || !IsManagedClient(attacker)) {
        return Plugin_Continue;
    }

    char weapon[MAX_WEAPON_NAME];
    if (!GetDamageWeaponName(attacker, inflictor, weapon, sizeof(weapon))) {
        return Plugin_Continue;
    }

    bool changed = false;
    float mult = 1.0;
    if (ResolveFloatAttr(attacker, weapon, Attr_Damage, mult)) {
        damage *= mult;
        changed = true;
    }

    if (IsTankVictim(victim) && ResolveFloatAttr(attacker, weapon, Attr_TankDamage, mult)) {
        damage *= mult;
        changed = true;
    }

    if (changed) {
        DebugLog("damage attacker=%N weapon=%s damage=%.3f", attacker, weapon, damage);
        return Plugin_Changed;
    }

    return Plugin_Continue;
}

public void WH_OnReloadModifier(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
    ApplyHandlingModifier(client, weapon, Attr_Reload, speedmodifier);
}

public void WH_OnGetRateOfFire(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
    ApplyHandlingModifier(client, weapon, Attr_Rate, speedmodifier);
}

public void WH_OnDeployModifier(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
    ApplyHandlingModifier(client, weapon, Attr_Deploy, speedmodifier);
}

public void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier)
{
    ApplyHandlingModifier(client, weapon, Attr_Melee, speedmodifier);
}

public void WH_OnStartThrow(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
    ApplyHandlingModifier(client, weapon, Attr_Throw, speedmodifier);
}

public void WH_OnReadyingThrow(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
    ApplyHandlingModifier(client, weapon, Attr_Throw, speedmodifier);
}

public Action L4D_OnGetRunTopSpeed(int target, float &retVal)
{
    return ApplySpeedModifier(target, retVal);
}

public Action L4D_OnGetWalkTopSpeed(int target, float &retVal)
{
    return ApplySpeedModifier(target, retVal);
}

public Action L4D_OnGetCrouchTopSpeed(int target, float &retVal)
{
    return ApplySpeedModifier(target, retVal);
}

void ApplyHandlingModifier(int client, int weapon, PerPlayerWeaponAttr attr, float &speedmodifier)
{
    if (!g_hEnabled.BoolValue || !g_bWeaponHandling || !IsManagedClient(client) || !IsValidEntitySafe(weapon)) {
        return;
    }

    char weaponName[MAX_WEAPON_NAME];
    if (!GetWeaponEntityName(weapon, weaponName, sizeof(weaponName))) {
        return;
    }

    float mult = 1.0;
    if (!ResolveFloatAttr(client, weaponName, attr, mult)) {
        return;
    }

    speedmodifier *= mult;
    DebugLog("handling client=%N weapon=%s attr=%s mult=%.3f", client, weaponName, g_sAttrNames[attr], mult);
}

void SyncClient(int client)
{
    if (!g_hEnabled.BoolValue || !IsManagedClient(client)) {
        return;
    }

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (!IsValidEntitySafe(weapon)) {
        g_iLastWeaponRef[client] = INVALID_ENT_REFERENCE;
        return;
    }

    char weaponName[MAX_WEAPON_NAME];
    if (!GetWeaponEntityName(weapon, weaponName, sizeof(weaponName))) {
        g_iLastWeaponRef[client] = INVALID_ENT_REFERENCE;
        return;
    }

    int weaponRef = EntIndexToEntRef(weapon);
    g_iLastWeaponRef[client] = weaponRef;

    SyncWeaponClip(client, weapon, weaponName);
    SyncReserveAmmo(client, weapon, weaponName);
}

Action ApplySpeedModifier(int client, float &speed)
{
    if (!g_hEnabled.BoolValue || !IsManagedClient(client) || !IsPlayerAlive(client)) {
        return Plugin_Continue;
    }

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (!IsValidEntitySafe(weapon)) {
        return Plugin_Continue;
    }

    char weaponName[MAX_WEAPON_NAME];
    if (!GetWeaponEntityName(weapon, weaponName, sizeof(weaponName))) {
        return Plugin_Continue;
    }

    float mult = 1.0;
    if (!ResolveFloatAttr(client, weaponName, Attr_Speed, mult)) {
        return Plugin_Continue;
    }

    speed *= mult;
    return Plugin_Handled;
}

void SyncWeaponClip(int client, int weapon, const char[] weaponName)
{
    float value = 0.0;
    if (!ResolveFloatAttr(client, weaponName, Attr_Clip, value)) {
        return;
    }

    int target = RoundToNearest(value);
    if (target <= 0 || !HasEntProp(weapon, Prop_Send, "m_iClip1")) {
        return;
    }

    int current = GetEntProp(weapon, Prop_Send, "m_iClip1");
    if (current < 0) {
        return;
    }

    if (current > target) {
        SetEntProp(weapon, Prop_Send, "m_iClip1", target);
        return;
    }

    if (g_hClipMode.IntValue < 1) {
        return;
    }

    char key[MAX_RULE_KEY];
    Format(key, sizeof(key), "%d|%d|%d", GetClientUserId(client), EntIndexToEntRef(weapon), target);

    int applied = 0;
    if (g_hClipApplied.GetValue(key, applied)) {
        return;
    }

    SetEntProp(weapon, Prop_Send, "m_iClip1", target);
    g_hClipApplied.SetValue(key, 1);
}

void SyncReserveAmmo(int client, int weapon, const char[] weaponName)
{
    float value = 0.0;
    if (!ResolveFloatAttr(client, weaponName, Attr_Reserve, value)) {
        return;
    }

    int target = RoundToNearest(value);
    if (target < 0 || !HasEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType")) {
        return;
    }

    int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if (ammoType < 0) {
        return;
    }

    int current = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType);
    int mode = g_hReserveMode.IntValue;

    if (mode == 0) {
        if (current > target) {
            SetEntProp(client, Prop_Send, "m_iAmmo", target, _, ammoType);
        }
        return;
    }

    if (mode == 1) {
        char key[MAX_RULE_KEY];
        Format(key, sizeof(key), "%d|%d|%d", GetClientUserId(client), ammoType, target);

        int applied = 0;
        if (g_hReserveApplied.GetValue(key, applied)) {
            return;
        }

        SetEntProp(client, Prop_Send, "m_iAmmo", target, _, ammoType);
        g_hReserveApplied.SetValue(key, 1);
        return;
    }

    if (current != target) {
        SetEntProp(client, Prop_Send, "m_iAmmo", target, _, ammoType);
    }
}

void LoadAttributeConfig()
{
    if (g_hConfigRules == null) {
        g_hConfigRules = new StringMap();
    }

    g_hConfigRules.Clear();

    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/l4d2_player_weapon_attrs.cfg");

    KeyValues kv = new KeyValues("PlayerWeaponAttributes");
    if (!kv.ImportFromFile(path)) {
        delete kv;
        DebugLog("config missing: %s", path);
        return;
    }

    if (!kv.GotoFirstSubKey()) {
        delete kv;
        return;
    }

    do {
        char selector[MAX_SELECTOR];
        kv.GetSectionName(selector, sizeof(selector));
        TrimString(selector);

        if (!kv.GotoFirstSubKey()) {
            continue;
        }

        do {
            char weapon[MAX_WEAPON_NAME];
            kv.GetSectionName(weapon, sizeof(weapon));
            NormalizeWeaponName(weapon, sizeof(weapon));

            for (int attr = 0; attr < ATTR_COUNT; attr++) {
                char value[32];
                kv.GetString(g_sAttrNames[attr], value, sizeof(value), "");
                TrimString(value);

                if (value[0] == '\0') {
                    continue;
                }

                float fValue = 0.0;
                if (!ParseStrictFloat(value, fValue)) {
                    continue;
                }

                if (IsValidAttrValue(attr, fValue)) {
                    SetConfigRule(selector, weapon, view_as<PerPlayerWeaponAttr>(attr), fValue);
                }
            }
        } while (kv.GotoNextKey());

        kv.GoBack();
    } while (kv.GotoNextKey());

    delete kv;
    DebugLog("loaded %d config rules", g_hConfigRules.Size);
}

bool ResolveFloatAttr(int client, const char[] weapon, PerPlayerWeaponAttr attr, float &value)
{
    if (GetSessionRule(client, weapon, attr, value)) {
        return true;
    }

    char selector[MAX_SELECTOR];
    if (!IsFakeClient(client) && GetClientAuthId(client, AuthId_Steam2, selector, sizeof(selector), true)) {
        if (GetConfigRule(selector, weapon, attr, value)) {
            return true;
        }
    }

    strcopy(selector, sizeof(selector), IsFakeClient(client) ? "@bots" : "@humans");
    if (GetConfigRule(selector, weapon, attr, value)) {
        return true;
    }

    return GetConfigRule("@all", weapon, attr, value);
}

bool GetSessionRule(int client, const char[] weapon, PerPlayerWeaponAttr attr, float &value)
{
    if (g_hSessionRules[client] == null) {
        return false;
    }

    char key[MAX_RULE_KEY];
    MakeSessionKey(weapon, attr, key, sizeof(key));
    if (g_hSessionRules[client].GetValue(key, value)) {
        return true;
    }

    MakeSessionKey("*", attr, key, sizeof(key));
    return g_hSessionRules[client].GetValue(key, value);
}

bool GetConfigRule(const char[] selector, const char[] weapon, PerPlayerWeaponAttr attr, float &value)
{
    char key[MAX_RULE_KEY];
    MakeConfigKey(selector, weapon, attr, key, sizeof(key));
    if (g_hConfigRules.GetValue(key, value)) {
        return true;
    }

    MakeConfigKey(selector, "*", attr, key, sizeof(key));
    return g_hConfigRules.GetValue(key, value);
}

void SetSessionRule(int client, const char[] weapon, PerPlayerWeaponAttr attr, float value)
{
    if (g_hSessionRules[client] == null) {
        g_hSessionRules[client] = new StringMap();
    }

    char key[MAX_RULE_KEY];
    MakeSessionKey(weapon, attr, key, sizeof(key));
    g_hSessionRules[client].SetValue(key, value, true);
}

void SetConfigRule(const char[] selector, const char[] weapon, PerPlayerWeaponAttr attr, float value)
{
    char key[MAX_RULE_KEY];
    MakeConfigKey(selector, weapon, attr, key, sizeof(key));
    g_hConfigRules.SetValue(key, value, true);
}

int RemoveSessionRules(int client, const char[] weapon, int attr)
{
    if (g_hSessionRules[client] == null || g_hSessionRules[client].Size == 0) {
        return 0;
    }

    int removed = 0;
    StringMapSnapshot snap = g_hSessionRules[client].Snapshot();

    for (int i = 0; i < snap.Length; i++) {
        char key[MAX_RULE_KEY];
        snap.GetKey(i, key, sizeof(key));

        if (RuleKeyMatches(key, weapon, attr)) {
            if (g_hSessionRules[client].Remove(key)) {
                removed++;
            }
        }
    }

    delete snap;
    return removed;
}

bool RuleKeyMatches(const char[] key, const char[] weapon, int attr)
{
    if (strcmp(weapon, "*") != 0) {
        int weaponLen = strlen(weapon);
        if (strncmp(key, weapon, weaponLen) != 0 || key[weaponLen] != '|') {
            return false;
        }
    }

    if (attr != -1) {
        char suffix[32];
        Format(suffix, sizeof(suffix), "|%s", g_sAttrNames[attr]);

        int keyLen = strlen(key);
        int suffixLen = strlen(suffix);
        if (keyLen < suffixLen || strcmp(key[keyLen - suffixLen], suffix) != 0) {
            return false;
        }
    }

    return true;
}

void PrintClientRules(int replyTo, int target)
{
    if (!IsClientInGameSafe(target)) {
        return;
    }

    char activeWeapon[MAX_WEAPON_NAME] = "(none)";
    int weapon = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
    if (IsValidEntitySafe(weapon)) {
        GetWeaponEntityName(weapon, activeWeapon, sizeof(activeWeapon));
    }

    ReplyToCommand(replyTo, "[PWA] %N active weapon: %s", target, activeWeapon);

    for (int attr = 0; attr < ATTR_COUNT; attr++) {
        float value = 0.0;
        if (ResolveFloatAttr(target, activeWeapon, view_as<PerPlayerWeaponAttr>(attr), value)) {
            ReplyToCommand(replyTo, "  effective %s = %.3f", g_sAttrNames[attr], value);
        }
    }

    if (g_hSessionRules[target] == null || g_hSessionRules[target].Size == 0) {
        ReplyToCommand(replyTo, "  session rules: none");
        return;
    }

    ReplyToCommand(replyTo, "  session rules:");
    StringMapSnapshot snap = g_hSessionRules[target].Snapshot();
    for (int i = 0; i < snap.Length; i++) {
        char key[MAX_RULE_KEY];
        float value = 0.0;
        snap.GetKey(i, key, sizeof(key));
        g_hSessionRules[target].GetValue(key, value);
        ReplyToCommand(replyTo, "  - %s = %.3f", key, value);
    }
    delete snap;
}

bool GetDamageWeaponName(int attacker, int inflictor, char[] buffer, int maxLen)
{
    if (IsValidEntitySafe(inflictor)) {
        char className[MAX_WEAPON_NAME];
        GetEntityClassname(inflictor, className, sizeof(className));

        if (strncmp(className, "weapon_", 7) == 0 && GetWeaponEntityName(inflictor, buffer, maxLen)) {
            return true;
        }
    }

    int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
    if (IsValidEntitySafe(weapon)) {
        return GetWeaponEntityName(weapon, buffer, maxLen);
    }

    GetClientWeapon(attacker, buffer, maxLen);
    NormalizeWeaponName(buffer, maxLen);
    return buffer[0] != '\0';
}

bool GetWeaponEntityName(int weapon, char[] buffer, int maxLen)
{
    if (!IsValidEntitySafe(weapon)) {
        buffer[0] = '\0';
        return false;
    }

    GetEntityClassname(weapon, buffer, maxLen);
    if (strcmp(buffer, "weapon_melee", false) == 0 && HasEntProp(weapon, Prop_Data, "m_strMapSetScriptName")) {
        GetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", buffer, maxLen);
    }

    NormalizeWeaponName(buffer, maxLen);
    return buffer[0] != '\0';
}

void NormalizeWeaponName(char[] weapon, int maxLen)
{
    TrimString(weapon);
    ToLowerString(weapon);

    if (weapon[0] == '\0' || strcmp(weapon, "*") == 0) {
        strcopy(weapon, maxLen, "*");
        return;
    }

    if (strncmp(weapon, "weapon_", 7) == 0) {
        return;
    }

    if (!IsKnownMeleeScriptName(weapon)) {
        Format(weapon, maxLen, "weapon_%s", weapon);
    }
}

bool IsKnownMeleeScriptName(const char[] weapon)
{
    static const char meleeNames[][] =
    {
        "baseball_bat",
        "cricket_bat",
        "crowbar",
        "electric_guitar",
        "fireaxe",
        "frying_pan",
        "golfclub",
        "katana",
        "knife",
        "machete",
        "pitchfork",
        "shovel",
        "tonfa"
    };

    for (int i = 0; i < sizeof(meleeNames); i++) {
        if (strcmp(weapon, meleeNames[i], false) == 0) {
            return true;
        }
    }

    return false;
}

int FindAttrIndex(const char[] rawAttr)
{
    char attr[32];
    strcopy(attr, sizeof(attr), rawAttr);
    TrimString(attr);
    ToLowerString(attr);

    if (strcmp(attr, "dmg") == 0 || strcmp(attr, "damagemult") == 0) {
        return Attr_Damage;
    }
    if (strcmp(attr, "tank") == 0 || strcmp(attr, "tankdamagemult") == 0 || strcmp(attr, "tankdmg") == 0) {
        return Attr_TankDamage;
    }
    if (strcmp(attr, "rof") == 0 || strcmp(attr, "firerate") == 0) {
        return Attr_Rate;
    }
    if (strcmp(attr, "reloadspeed") == 0 || strcmp(attr, "reloadmult") == 0) {
        return Attr_Reload;
    }
    if (strcmp(attr, "deployspeed") == 0 || strcmp(attr, "deploymult") == 0) {
        return Attr_Deploy;
    }
    if (strcmp(attr, "meleespeed") == 0 || strcmp(attr, "meleemult") == 0) {
        return Attr_Melee;
    }
    if (strcmp(attr, "throwspeed") == 0 || strcmp(attr, "throwmult") == 0) {
        return Attr_Throw;
    }
    if (strcmp(attr, "movespeed") == 0 || strcmp(attr, "speedmult") == 0) {
        return Attr_Speed;
    }
    if (strcmp(attr, "clipsize") == 0) {
        return Attr_Clip;
    }
    if (strcmp(attr, "ammo") == 0 || strcmp(attr, "reserveammo") == 0) {
        return Attr_Reserve;
    }

    for (int i = 0; i < ATTR_COUNT; i++) {
        if (strcmp(attr, g_sAttrNames[i]) == 0) {
            return i;
        }
    }

    return -1;
}

bool IsValidAttrValue(int attr, float value)
{
    switch (attr) {
        case Attr_Clip:
        {
            return value > 0.0 && value <= 999.0;
        }
        case Attr_Reserve:
        {
            return value >= 0.0 && value <= 9999.0;
        }
    }

    return value > 0.0 && value <= 20.0;
}

bool IsTankVictim(int victim)
{
    return IsClientInGameSafe(victim)
        && GetClientTeam(victim) == TEAM_INFECTED
        && IsPlayerAlive(victim)
        && GetEntProp(victim, Prop_Send, "m_zombieClass") == ZOMBIECLASS_TANK;
}

bool IsClientInGameSafe(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool IsManagedClient(int client)
{
    if (!IsClientInGameSafe(client)) {
        return false;
    }

    if (g_hSurvivorsOnly.BoolValue && GetClientTeam(client) != TEAM_SURVIVOR) {
        return false;
    }

    return true;
}

bool RequiresWeaponHandling(PerPlayerWeaponAttr attr)
{
    return attr == Attr_Rate
        || attr == Attr_Reload
        || attr == Attr_Deploy
        || attr == Attr_Melee
        || attr == Attr_Throw;
}

bool ParseStrictFloat(const char[] input, float &value)
{
    char buffer[32];
    strcopy(buffer, sizeof(buffer), input);
    TrimString(buffer);

    int len = strlen(buffer);
    return len > 0 && StringToFloatEx(buffer, value) == len;
}

bool IsValidEntitySafe(int entity)
{
    return entity > MaxClients && IsValidEntity(entity);
}

void MakeSessionKey(const char[] weapon, int attr, char[] key, int maxLen)
{
    Format(key, maxLen, "%s|%s", weapon, g_sAttrNames[attr]);
}

void MakeConfigKey(const char[] selector, const char[] weapon, int attr, char[] key, int maxLen)
{
    Format(key, maxLen, "%s|%s|%s", selector, weapon, g_sAttrNames[attr]);
}

void ClearEntityApplyCaches()
{
    if (g_hClipApplied != null) {
        g_hClipApplied.Clear();
    }

    if (g_hReserveApplied != null) {
        g_hReserveApplied.Clear();
    }
}

void ToLowerString(char[] text)
{
    int len = strlen(text);
    for (int i = 0; i < len; i++) {
        text[i] = CharToLower(text[i]);
    }
}

void DebugLog(const char[] fmt, any ...)
{
    if (g_hDebug == null || !g_hDebug.BoolValue) {
        return;
    }

    char buffer[256];
    VFormat(buffer, sizeof(buffer), fmt, 2);
    PrintToServer("[PWA] %s", buffer);
}
