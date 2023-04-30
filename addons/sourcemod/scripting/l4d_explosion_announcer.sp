/**
// ====================================================================================================
Change Log:

1.0.7 (04-March-2022)
    - Fixed compability with other plugins. (thanks "ddd123" for reporting)

1.0.6 (26-February-2021)
    - Added support for explosive oil drum (custom model - can be found on GoldenEye 4 Dead custom map)

1.0.5 (04-January-2021)
    - Added support for gas pump. (found on No Mercy, 3rd map)

1.0.4 (29-November-2020)
    - Added support to physics_prop, prop_physics_override and prop_physics_multiplayer.

1.0.3 (28-November-2020)
    - Changed the detection method of explosion, from OnEntityDestroyed to break_prop/OnKilled event.
    - Fixed message being sent when pick up a breakable prop item while on ignition.
    - Fixed message being sent from fuel barrel parts explosion.
    - Added Hungarian (hu) translations. (thanks to "KasperH")

1.0.2 (21-October-2020)
    - Fixed a bug while printing to chat for multiple clients. (thanks to "KRUTIK" for reporting)
    - Added Russian (ru) translations. (thanks to "KRUTIK")
    - Fixed some Russian (ru) lines. (thanks to " Angerfist2188")

1.0.1 (20-October-2020)
    - Added Simplified Chinese (chi) and Traditional Chinese (zho) translations. (thanks to "HarryPotter")
    - Fixed some Simplified Chinese (chi) lines. (thanks to "viaxiamu")

1.0.0 (20-October-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Explosion Announcer"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Outputs to the chat who exploded some props"
#define PLUGIN_VERSION                "1.0.7"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=328006"

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Cvar Flags
// ====================================================================================================
#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

// ====================================================================================================
// Filenames
// ====================================================================================================
#define CONFIG_FILENAME               "l4d_explosion_announcer"
//#define TRANSLATION_FILENAME          "l4d_explosion_announcer.phrases"

// ====================================================================================================
// Defines
// ====================================================================================================
#define MODEL_GASCAN                  "models/props_junk/gascan001a.mdl"
#define MODEL_FUEL_BARREL             "models/props_industrial/barrel_fuel.mdl"
#define MODEL_PROPANECANISTER         "models/props_junk/propanecanister001a.mdl"
#define MODEL_OXYGENTANK              "models/props_equipment/oxygentank01.mdl"
#define MODEL_BARRICADE_GASCAN        "models/props_unique/wooden_barricade_gascans.mdl"
#define MODEL_GAS_PUMP                "models/props_equipment/gas_pump_nodebris.mdl"
#define MODEL_FIREWORKS_CRATE         "models/props_junk/explosive_box001.mdl"
#define MODEL_OILDRUM_EXPLOSIVE       "models/props_c17/oildrum001_explosive.mdl" // Custom Model - can be found on GoldenEye 4 Dead custom map

#define TEAM_SPECTATOR                1
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

#define FLAG_TEAM_NONE                (0 << 0) // 0 | 0000
#define FLAG_TEAM_SURVIVOR            (1 << 0) // 1 | 0001
#define FLAG_TEAM_INFECTED            (1 << 1) // 2 | 0010
#define FLAG_TEAM_SPECTATOR           (1 << 2) // 4 | 0100
#define FLAG_TEAM_HOLDOUT             (1 << 3) // 8 | 1000

#define TYPE_NONE                     0
#define TYPE_GASCAN                   1
#define TYPE_FUEL_BARREL              2
#define TYPE_PROPANECANISTER          3
#define TYPE_OXYGENTANK               4
#define TYPE_BARRICADE_GASCAN         5
#define TYPE_GAS_PUMP                 6
#define TYPE_FIREWORKS_CRATE          7
#define TYPE_OIL_DRUM_EXPLOSIVE       8

#define MAX_TYPES                     8

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_SpamProtection;
static ConVar g_hCvar_SpamTypeCheck;
static ConVar g_hCvar_Team;
static ConVar g_hCvar_Self;
static ConVar g_hCvar_Gascan;
static ConVar g_hCvar_FuelBarrel;
static ConVar g_hCvar_PropaneCanister;
static ConVar g_hCvar_OxygenTank;
static ConVar g_hCvar_BarricadeGascan;
static ConVar g_hCvar_GasPump;
static ConVar g_hCvar_FireworksCrate;
static ConVar g_hCvar_OilDrumExplosive;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bEventsHooked;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_SpamProtection;
static bool   g_bCvar_SpamTypeCheck;
static bool   g_bCvar_Self;
static bool   g_bCvar_Gascan;
static bool   g_bCvar_FuelBarrel;
static bool   g_bCvar_PropaneCanister;
static bool   g_bCvar_OxygenTank;
static bool   g_bCvar_BarricadeGascan;
static bool   g_bCvar_GasPump;
static bool   g_bCvar_FireworksCrate;
static bool   g_bCvar_OilDrumExplosive;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iModel_Gascan = -1;
static int    g_iModel_FuelBarrel = -1;
static int    g_iModel_PropaneCanister = -1;
static int    g_iModel_OxygenTank = -1;
static int    g_iModel_BarricadeGascan = -1;
static int    g_iModel_GasPump = -1;
static int    g_iModel_FireworksCrate = -1;
static int    g_iModel_OilDrumExplosive = -1;
static int    g_iCvar_Team;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_SpamProtection;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
static float  gc_fLastChatOccurrence[MAXPLAYERS+1][MAX_TYPES+1];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
static int    ge_iType[MAXENTITIES+1];
static int    ge_iLastAttacker[MAXENTITIES+1];

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    g_bL4D2 = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    //LoadPluginTranslations();

    CreateConVar("l4d_explosion_announcer_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled            = CreateConVar("l4d_explosion_announcer_enable", "1", "启用此插件? 0=禁用, 1=启用.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_SpamProtection     = CreateConVar("l4d_explosion_announcer_spam_protection", "3.0", "来自同一个客户端的消息延迟多少秒输出到聊天窗. 0=关闭.", CVAR_FLAGS, true, 0.0);
    g_hCvar_SpamTypeCheck      = CreateConVar("l4d_explosion_announcer_spam_type_check", "1", "按照实体类型来套用聊天信息保护? 例如: \"汽油罐\" 和 \"煤气瓶\" 是不一样的实体类型. 0=关闭, 1=开启.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Team               = CreateConVar("l4d_explosion_announcer_team", "1", "提示消息发送给那些团队. 0=没有, 1=幸存者, 2=感染者, 4=旁观者, 8=幸存者NPC. 如需启用多个把数字加起来. 例如: 3=幸存者+感染者.", CVAR_FLAGS, true, 0.0, true, 15.0);
    g_hCvar_Self               = CreateConVar("l4d_explosion_announcer_self", "1", "提示消息发送给点燃或引爆者?. 0=关闭, 1=开启.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Gascan             = CreateConVar("l4d_explosion_announcer_gascan", "1", "启用幸存者引燃汽油桶提示? 0=关闭, 1=开启.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_FuelBarrel         = CreateConVar("l4d_explosion_announcer_fuelbarrel", "1", "启用幸存者打爆白色大油桶提示? 0=关闭, 1=开启.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_PropaneCanister    = CreateConVar("l4d_explosion_announcer_propanecanister", "1", "启用幸存者打爆煤气罐提示? 0=关闭, 1=开启.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_OxygenTank         = CreateConVar("l4d_explosion_announcer_oxygentank", "1", "启用幸存者打爆氧气罐提示? 0=关闭, 1=开启.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_BarricadeGascan    = CreateConVar("l4d_explosion_announcer_barricadegascan", "1", "启用幸存者引燃路障油桶提示? 0=关闭, 1=开启.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_GasPump            = CreateConVar("l4d_explosion_announcer_gaspump", "1", "启用幸存者打爆汽油泵提示? 0=关闭, 1=开启.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_OilDrumExplosive   = CreateConVar("l4d_explosion_announcer_oildrumexplosive", "1", "启用幸存者打爆(自定义)大油桶提示? 0=关闭, 1=开启.", CVAR_FLAGS, true, 0.0, true, 1.0);
    if (g_bL4D2)
        g_hCvar_FireworksCrate = CreateConVar("l4d_explosion_announcer_fireworkscrate", "1", "启用幸存者点燃烟花盒提示? 0=关闭, 1=开启.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpamProtection.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpamTypeCheck.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Team.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Self.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Gascan.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FuelBarrel.AddChangeHook(Event_ConVarChanged);
    g_hCvar_PropaneCanister.AddChangeHook(Event_ConVarChanged);
    g_hCvar_OxygenTank.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BarricadeGascan.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GasPump.AddChangeHook(Event_ConVarChanged);
    g_hCvar_OilDrumExplosive.AddChangeHook(Event_ConVarChanged);
    if (g_bL4D2)
        g_hCvar_FireworksCrate.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_explosion_announcer", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
}
/*
public void LoadPluginTranslations()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
    if (FileExists(path))
        LoadTranslations(TRANSLATION_FILENAME);
    else
        SetFailState("Missing required translation file on \"translations/%s.txt\", please re-download.", TRANSLATION_FILENAME);
}
*/
/****************************************************************************************************/

public void OnMapStart()
{
    g_iModel_Gascan = PrecacheModel(MODEL_GASCAN, true);
    g_iModel_FuelBarrel = PrecacheModel(MODEL_FUEL_BARREL, true);
    g_iModel_PropaneCanister = PrecacheModel(MODEL_PROPANECANISTER, true);
    g_iModel_OxygenTank = PrecacheModel(MODEL_OXYGENTANK, true);
    g_iModel_BarricadeGascan = PrecacheModel(MODEL_BARRICADE_GASCAN, true);
    g_iModel_GasPump = PrecacheModel(MODEL_GAS_PUMP, true);
    if (g_bL4D2)
        g_iModel_FireworksCrate = PrecacheModel(MODEL_FIREWORKS_CRATE, true);

    if (IsModelPrecached(MODEL_OILDRUM_EXPLOSIVE))
        g_iModel_OilDrumExplosive = PrecacheModel(MODEL_OILDRUM_EXPLOSIVE, true);
    else
        g_iModel_OilDrumExplosive = -1;
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    LateLoad();

    HookEvents();
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents();
}

/****************************************************************************************************/

public void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_fCvar_SpamProtection = g_hCvar_SpamProtection.FloatValue;
    g_bCvar_SpamProtection = (g_fCvar_SpamProtection > 0.0);
    g_bCvar_SpamTypeCheck = g_hCvar_SpamTypeCheck.BoolValue;
    g_iCvar_Team = g_hCvar_Team.IntValue;
    g_bCvar_Self = g_hCvar_Self.BoolValue;
    g_bCvar_Gascan = g_hCvar_Gascan.BoolValue;
    g_bCvar_FuelBarrel = g_hCvar_FuelBarrel.BoolValue;
    g_bCvar_PropaneCanister = g_hCvar_PropaneCanister.BoolValue;
    g_bCvar_OxygenTank = g_hCvar_OxygenTank.BoolValue;
    g_bCvar_BarricadeGascan = g_hCvar_BarricadeGascan.BoolValue;
    g_bCvar_GasPump = g_hCvar_GasPump.BoolValue;
    g_bCvar_OilDrumExplosive = g_hCvar_OilDrumExplosive.BoolValue;
    if (g_bL4D2)
        g_bCvar_FireworksCrate = g_hCvar_FireworksCrate.BoolValue;
}

/****************************************************************************************************/

public void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("break_prop", Event_BreakProp);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("break_prop", Event_BreakProp);

        return;
    }
}

/****************************************************************************************************/

public void Event_BreakProp(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bCvar_Enabled)
        return;

    int entity = event.GetInt("entindex");

    int type = ge_iType[entity];

    if (type == TYPE_NONE)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        client = GetClientOfUserId(ge_iLastAttacker[entity]);

    if (!IsValidClient(client))
        return;

    OutputMessage(client, type);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    for (int type = TYPE_NONE; type <= MAX_TYPES; type++)
    {
        gc_fLastChatOccurrence[client][type] = 0.0;
    }
}

/****************************************************************************************************/

public void LateLoad()
{
    int entity;

    if (g_bL4D2)
    {
        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "weapon_gascan")) != INVALID_ENT_REFERENCE)
        {
            RequestFrame(OnNextFrameWeaponGascan, EntIndexToEntRef(entity));
        }
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "prop_fuel_barrel")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "prop_physics*")) != INVALID_ENT_REFERENCE)
    {
        if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
            RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "physics_prop")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!IsValidEntityIndex(entity))
        return;

    ge_iType[entity] = TYPE_NONE;
    ge_iLastAttacker[entity] = 0;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!IsValidEntityIndex(entity))
        return;

    switch (classname[0])
    {
        case 'w':
        {
            if (!g_bL4D2)
                return;

            if (classname[1] != 'e') // weapon_*
                return;

            if (StrEqual(classname, "weapon_gascan"))
            {
                RequestFrame(OnNextFrameWeaponGascan, EntIndexToEntRef(entity));
            }
        }
        case 'p':
        {
            if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
                RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
        }
    }
}

/****************************************************************************************************/

// Extra frame to get netprops updated
public void OnNextFrameWeaponGascan(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    if (ge_iType[entity] != TYPE_NONE)
        return;

    if (GetEntProp(entity, Prop_Data, "m_iHammerID") == -1) // Ignore entities with hammerid -1
        return;

    RenderMode rendermode = GetEntityRenderMode(entity);
    int rgba[4];
    GetEntityRenderColor(entity, rgba[0], rgba[1], rgba[2], rgba[3]);

    if (rendermode == RENDER_NONE || (rendermode == RENDER_TRANSCOLOR && rgba[3] == 0)) // Other plugins support, ignore invisible entities
        return;

    ge_iType[entity] = TYPE_GASCAN;
    SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
    HookSingleEntityOutput(entity, "OnKilled", OnKilled, true);
}

/****************************************************************************************************/

// Extra frame to get netprops updated
public void OnNextFrame(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    if (ge_iType[entity] != TYPE_NONE)
        return;

    if (GetEntProp(entity, Prop_Data, "m_iHammerID") == -1) // Ignore entities with hammerid -1
        return;

    RenderMode rendermode = GetEntityRenderMode(entity);
    int rgba[4];
    GetEntityRenderColor(entity, rgba[0], rgba[1], rgba[2], rgba[3]);

    if (rendermode == RENDER_NONE || (rendermode == RENDER_TRANSCOLOR && rgba[3] == 0)) // Other plugins support, ignore invisible entities
        return;

    int modelIndex = GetEntProp(entity, Prop_Send, "m_nModelIndex");

    if (modelIndex == g_iModel_Gascan)
    {
        ge_iType[entity] = TYPE_GASCAN;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_FuelBarrel)
    {
        ge_iType[entity] = TYPE_FUEL_BARREL;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_PropaneCanister)
    {
        ge_iType[entity] = TYPE_PROPANECANISTER;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_OxygenTank)
    {
        ge_iType[entity] = TYPE_OXYGENTANK;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_BarricadeGascan)
    {
        ge_iType[entity] = TYPE_BARRICADE_GASCAN;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_GasPump)
    {
        ge_iType[entity] = TYPE_GAS_PUMP;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_OilDrumExplosive && g_iModel_OilDrumExplosive != -1)
    {
        ge_iType[entity] = TYPE_OIL_DRUM_EXPLOSIVE;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (!g_bL4D2)
        return;

    if (modelIndex == g_iModel_FireworksCrate)
    {
        ge_iType[entity] = TYPE_FIREWORKS_CRATE;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }
}

/****************************************************************************************************/

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (IsValidClient(attacker))
        ge_iLastAttacker[victim] = GetClientUserId(attacker);

    return Plugin_Continue;
}

/****************************************************************************************************/

public void OnKilled(const char[] output, int caller, int activator, float delay)
{
    if (!g_bCvar_Enabled)
        return;

    int type = ge_iType[caller];

    if (type == TYPE_NONE)
        return;

    if (IsValidClient(activator))
        ge_iLastAttacker[caller] = GetClientUserId(activator);

    if (ge_iLastAttacker[caller] == 0)
        return;

    int client = GetClientOfUserId(ge_iLastAttacker[caller]);

    if (!IsValidClient(client))
        return;

    OutputMessage(client, type);
}

/****************************************************************************************************/

public void OutputMessage(int attacker, int type)
{
    if (g_iCvar_Team == FLAG_TEAM_NONE)
        return;

    if (g_bCvar_SpamProtection)
    {
        if (g_bCvar_SpamTypeCheck)
        {
            if (gc_fLastChatOccurrence[attacker][type] != 0.0 && GetGameTime() - gc_fLastChatOccurrence[attacker][type] < g_fCvar_SpamProtection)
                return;

            gc_fLastChatOccurrence[attacker][type] = GetGameTime();
        }
        else
        {
            if (gc_fLastChatOccurrence[attacker][TYPE_NONE] != 0.0 && GetGameTime() - gc_fLastChatOccurrence[attacker][TYPE_NONE] < g_fCvar_SpamProtection)
                return;

            gc_fLastChatOccurrence[attacker][TYPE_NONE] = GetGameTime();
        }
    }

    switch (type)
    {
        case TYPE_GASCAN:
        {
            if (!g_bCvar_Gascan)
                return;

            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                if (client == attacker)
                {
                    if (!g_bCvar_Self)
                        continue;
                }
                else
                {
                    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
                        continue;
                }

                PrintToChat(client, "\x04[提示]\x03%N\x05引燃了汽油桶!", attacker);
            }
        }

        case TYPE_FUEL_BARREL:
        {
            if (!g_bCvar_FuelBarrel)
                return;

            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                if (client == attacker)
                {
                    if (!g_bCvar_Self)
                        continue;
                }
                else
                {
                    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
                        continue;
                }

                PrintToChat(client, "\x04[提示]\x03%N\x05打爆了白色大油桶!", attacker);
            }
        }

        case TYPE_PROPANECANISTER:
        {
            if (!g_bCvar_PropaneCanister)
                return;

            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                if (client == attacker)
                {
                    if (!g_bCvar_Self)
                        continue;
                }
                else
                {
                    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
                        continue;
                }

                PrintToChat(client, "\x04[提示]\x03%N\x05打爆了煤气罐!", attacker);
            }
        }

        case TYPE_OXYGENTANK:
        {
            if (!g_bCvar_OxygenTank)
                return;

            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                if (client == attacker)
                {
                    if (!g_bCvar_Self)
                        continue;
                }
                else
                {
                    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
                        continue;
                }

                PrintToChat(client, "\x04[提示]\x03%N\x05打爆了氧气瓶!", attacker);
            }
        }

        case TYPE_BARRICADE_GASCAN:
        {
            if (!g_bCvar_BarricadeGascan)
                return;

            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                if (client == attacker)
                {
                    if (!g_bCvar_Self)
                        continue;
                }
                else
                {
                    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
                        continue;
                }

                PrintToChat(client, "\x04[提示]\x03%N\x05引燃了路障油桶!", attacker);
            }
        }

        case TYPE_GAS_PUMP:
        {
            if (!g_bCvar_GasPump)
                return;

            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                if (client == attacker)
                {
                    if (!g_bCvar_Self)
                        continue;
                }
                else
                {
                    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
                        continue;
                }

                PrintToChat(client, "\x04[提示]\x03%N\x05打爆了汽油泵!", attacker);
            }
        }

        case TYPE_FIREWORKS_CRATE:
        {
            if (!g_bCvar_FireworksCrate)
                return;

            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                if (client == attacker)
                {
                    if (!g_bCvar_Self)
                        continue;
                }
                else
                {
                    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
                        continue;
                }

                PrintToChat(client, "\x04[提示]\x03%N\x05点燃了烟花盒!", attacker);
            }
        }

        case TYPE_OIL_DRUM_EXPLOSIVE:
        {
            if (!g_bCvar_OilDrumExplosive)
                return;

            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                if (client == attacker)
                {
                    if (!g_bCvar_Self)
                        continue;
                }
                else
                {
                    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
                        continue;
                }

                PrintToChat(client, "\x04[提示]\x03%N\x05打爆了爆炸大油桶!", attacker);
            }
        }
    }
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (l4d_explosion_announcer) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_explosion_announcer_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_explosion_announcer_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_spam_protection : %.1f", g_fCvar_SpamProtection);
    PrintToConsole(client, "l4d_explosion_announcer_spam_type_check : %b (%s)", g_bCvar_SpamTypeCheck, g_bCvar_SpamTypeCheck ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_team : %i (SPECTATOR = %s | SURVIVOR = %s | INFECTED = %s | HOLDOUT = %s)", g_iCvar_Team,
    g_iCvar_Team & FLAG_TEAM_SPECTATOR ? "true" : "false", g_iCvar_Team & FLAG_TEAM_SURVIVOR ? "true" : "false", g_iCvar_Team & FLAG_TEAM_INFECTED ? "true" : "false", g_iCvar_Team & FLAG_TEAM_HOLDOUT ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_self : %b (%s)", g_bCvar_Self, g_bCvar_Self ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_gascan : %b (%s)", g_bCvar_Gascan, g_bCvar_Gascan ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_fuelbarrel : %b (%s)", g_bCvar_FuelBarrel, g_bCvar_FuelBarrel ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_propanecanister : %b (%s)", g_bCvar_PropaneCanister, g_bCvar_PropaneCanister ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_oxygentank : %b (%s)", g_bCvar_OxygenTank, g_bCvar_OxygenTank ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_barricadegascan : %b (%s)", g_bCvar_BarricadeGascan, g_bCvar_BarricadeGascan ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_gaspump : %b (%s)", g_bCvar_GasPump, g_bCvar_GasPump ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_oildrumexplosive : %b (%s)", g_bCvar_OilDrumExplosive, g_bCvar_OilDrumExplosive ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_explosion_announcer_fireworkscrate : %b (%s)", g_bCvar_FireworksCrate, g_bCvar_FireworksCrate ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Validates if is a valid client index.
 *
 * @param client        Client index.
 * @return              True if client index is valid, false otherwise.
 */
bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

/****************************************************************************************************/

/**
 * Validates if is a valid client.
 *
 * @param client        Client index.
 * @return              True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}

/****************************************************************************************************/

/**
 * Validates if is a valid entity index (between MaxClients+1 and 2048).
 *
 * @param entity        Entity index.
 * @return              True if entity index is valid, false otherwise.
 */
bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
}

/****************************************************************************************************/

/**
 * Returns the team flag from a team.
 *
 * @param team          Team index.
 * @return              Team flag.
 */
int GetTeamFlag(int team)
{
    switch (team)
    {
        case TEAM_SURVIVOR:
            return FLAG_TEAM_SURVIVOR;
        case TEAM_INFECTED:
            return FLAG_TEAM_INFECTED;
        case TEAM_SPECTATOR:
            return FLAG_TEAM_SPECTATOR;
        case TEAM_HOLDOUT:
            return FLAG_TEAM_HOLDOUT;
        default:
            return FLAG_TEAM_NONE;
    }
}

// ====================================================================================================
// colors.inc replacement (Thanks to Silvers)
// ====================================================================================================
/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags.
 *
 * @param client        Client index.
 * @param message       Message (formatting rules).
 *
 * On error/Errors:     If the client is not connected an error will be thrown.
 */
public void CPrintToChat(int client, char[] message, any ...)
{
    char buffer[512];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), message, 3);

    ReplaceString(buffer, sizeof(buffer), "{default}", "\x01");
    ReplaceString(buffer, sizeof(buffer), "{white}", "\x01");
    ReplaceString(buffer, sizeof(buffer), "{cyan}", "\x03");
    ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "\x03");
    ReplaceString(buffer, sizeof(buffer), "{orange}", "\x04");
    ReplaceString(buffer, sizeof(buffer), "{green}", "\x04"); // Actually orange in L4D1/L4D2, but replicating colors.inc behaviour
    ReplaceString(buffer, sizeof(buffer), "{olive}", "\x05");

    PrintToChat(client, buffer);
}