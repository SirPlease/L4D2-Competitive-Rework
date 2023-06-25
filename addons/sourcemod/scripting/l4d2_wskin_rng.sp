/**
// ====================================================================================================
Change Log:

1.1.0 (17-September-2022)
    - Added cvar to ignore weapons that already have a skin different than default. (thanks "HarryPotter" for requesting)

1.0.9 (14-March-2022)
    - Added safe check while getting the entity skin to prevent errors. (thanks "HarryPotter" for reporting)

1.0.8 (12-March-2022)
    - Fixed gascans not applying skin on pickup. (thanks to "Toranks" for reporting and "ryzewash" for the code snippet to fix it)

1.0.7 (17-October-2021)
    - Fixed prop_physics gascans not changing their skin when enabled. (thanks to "ryzewash" for reporting)

1.0.6 (04-June-2021)
    - Added gascan option. (thanks to "TrevorSoldier" for requesting)

1.0.5 (10-November-2020)
    - Fixed logic to apply RNG skin only after the config is loaded.
    - Fixed error when the StringMaps weren't initialized yet. (thanks to "Krufftys Killers" for reporting)

1.0.4 (10-November-2020)
    - Added cvar to select which weapons should have RNG skin. (thanks to "larrybrains" for requesting)

1.0.3 (03-November-2020)
    - Fixed spawner entities' skin logic.
    - Removed RNG logic from owned weapons.
    - Added admin command to scramble weapon skins in real-time.
    - Fixed compatibility with the skin menu plugin.

1.0.2 (30-September-2020)
    - Fixed a bug where sometimes it didn't apply the correct skin when picking up an item from a spawner with count = 1. (thanks "Tonblader" for reporting)

1.0.1 (30-September-2020)
    - Removed EventHookMode_PostNoCopy from hook events. (thanks "AK978" for reporting)

1.0.0 (29-September-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Weapons Skins RNG"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Applies random skins to spawned weapons"
#define PLUGIN_VERSION                "1.1.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=327609"

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
#define CONFIG_FILENAME               "l4d2_wskin_rng"

// ====================================================================================================
// Defines
// ====================================================================================================
#define L4D2_WEPID_PISTOL_MAGNUM      "32"
#define L4D2_WEPID_SMG_UZI            "2"
#define L4D2_WEPID_SMG_SILENCED       "7"
#define L4D2_WEPID_PUMP_SHOTGUN       "3"
#define L4D2_WEPID_SHOTGUN_CHROME     "8"
#define L4D2_WEPID_AUTO_SHOTGUN       "4"
#define L4D2_WEPID_RIFLE_M16          "5"
#define L4D2_WEPID_RIFLE_AK47         "26"
#define L4D2_WEPID_HUNTING_RIFLE      "6"

#define MODEL_W_CROWBAR               "models/weapons/melee/w_crowbar.mdl"
#define MODEL_W_CRICKET_BAT           "models/weapons/melee/w_cricket_bat.mdl"

#define MODEL_GASCAN                  "models/props_junk/gascan001a.mdl"

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_IgnoreSkin;
ConVar g_hCvar_PistolMagnum;
ConVar g_hCvar_PumpShotgun;
ConVar g_hCvar_ShotgunChrome;
ConVar g_hCvar_AutoShotgun;
ConVar g_hCvar_SMGUzi;
ConVar g_hCvar_SMGSilenced;
ConVar g_hCvar_RifleM16;
ConVar g_hCvar_RifleAK47;
ConVar g_hCvar_HuntingRifle;
ConVar g_hCvar_CricketBat;
ConVar g_hCvar_Crowbar;
ConVar g_hCvar_Gascan;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_IgnoreSkin;
bool g_bCvar_PistolMagnum;
bool g_bCvar_PumpShotgun;
bool g_bCvar_ShotgunChrome;
bool g_bCvar_AutoShotgun;
bool g_bCvar_SMGUzi;
bool g_bCvar_SMGSilenced;
bool g_bCvar_RifleM16;
bool g_bCvar_RifleAK47;
bool g_bCvar_HuntingRifle;
bool g_bCvar_CricketBat;
bool g_bCvar_Crowbar;
bool g_bCvar_Melee;
bool g_bCvar_Gascan;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iModel_Gascan = -1;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bItemPickup[MAXPLAYERS+1];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
bool ge_bIsGascan[MAXENTITIES+1];

// ====================================================================================================
// StringMap - Plugin Variables
// ====================================================================================================
StringMap g_smWeaponIdToClassname;
StringMap g_smWeaponCount;
StringMap g_smMeleeModelCount;

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
ArrayList g_alClassname;

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    g_alClassname = new ArrayList(ByteCountToCells(36));
    g_smWeaponIdToClassname = new StringMap();
    g_smWeaponCount = new StringMap();
    g_smMeleeModelCount = new StringMap();

    BuildClassnameArrayList();
    BuildWeaponStringMap();

    CreateConVar("l4d2_wskin_rng_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled       = CreateConVar("l4d2_wskin_rng_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_IgnoreSkin    = CreateConVar("l4d2_wskin_rng_ignore_skin", "1", "Ignore weapons that already have a skin different than default.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_PistolMagnum  = CreateConVar("l4d2_wskin_rng_pistol_magnum", "1", "Weapon skin RNG for Pistol Magnum.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_PumpShotgun   = CreateConVar("l4d2_wskin_rng_pump_shotgun", "1", "Weapon skin RNG for Pump Shotgun.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ShotgunChrome = CreateConVar("l4d2_wskin_rng_shotgun_chrome", "1", "Weapon skin RNG for Chrome Shotgun.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_AutoShotgun   = CreateConVar("l4d2_wskin_rng_auto_shotgun", "1", "Weapon skin RNG for Auto Shotgun.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_SMGUzi        = CreateConVar("l4d2_wskin_rng_smg_uzi", "1", "Weapon skin RNG for SMG Uzi.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_SMGSilenced   = CreateConVar("l4d2_wskin_rng_smg_silenced", "1", "Weapon skin RNG for Silenced SMG.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_RifleM16      = CreateConVar("l4d2_wskin_rng_rifle_m16", "1", "Weapon skin RNG for M16 Rifle.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_RifleAK47     = CreateConVar("l4d2_wskin_rng_rifle_ak47", "1", "Weapon skin RNG for AK47 Rifle.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HuntingRifle  = CreateConVar("l4d2_wskin_rng_hunting_rifle", "1", "Weapon skin RNG for Hunting Rifle.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_CricketBat    = CreateConVar("l4d2_wskin_rng_cricket_bat", "1", "Weapon skin RNG for Cricket Bat melee.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Crowbar       = CreateConVar("l4d2_wskin_rng_crowbar", "1", "Weapon skin RNG for Crowbar melee.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Gascan        = CreateConVar("l4d2_wskin_rng_gascan", "1", "Weapon skin RNG for Gascan.\nNote: Enabling this may glitch some plugins that check the gascan skin to detect if is a scavenge one.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_IgnoreSkin.AddChangeHook(Event_ConVarChanged);
    g_hCvar_PistolMagnum.AddChangeHook(Event_ConVarChanged);
    g_hCvar_PumpShotgun.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ShotgunChrome.AddChangeHook(Event_ConVarChanged);
    g_hCvar_AutoShotgun.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SMGUzi.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SMGSilenced.AddChangeHook(Event_ConVarChanged);
    g_hCvar_RifleM16.AddChangeHook(Event_ConVarChanged);
    g_hCvar_RifleAK47.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HuntingRifle.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CricketBat.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Crowbar.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Gascan.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_wskin_rng", CmdWSkinRng, ADMFLAG_ROOT, "Scramble the weapon skins randomly in real time.");
    RegAdminCmd("sm_print_cvars_l4d2_wskin_rng", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

void BuildClassnameArrayList()
{
    g_alClassname.Clear();
    g_alClassname.PushString("weapon_melee");
    g_alClassname.PushString("weapon_melee_spawn");
    g_alClassname.PushString("weapon_spawn");
    g_alClassname.PushString("weapon_pistol_magnum");
    g_alClassname.PushString("weapon_pistol_magnum_spawn");
    g_alClassname.PushString("weapon_smg");
    g_alClassname.PushString("weapon_smg_spawn");
    g_alClassname.PushString("weapon_smg_silenced");
    g_alClassname.PushString("weapon_smg_silenced_spawn");
    g_alClassname.PushString("weapon_pumpshotgun");
    g_alClassname.PushString("weapon_pumpshotgun_spawn");
    g_alClassname.PushString("weapon_shotgun_chrome");
    g_alClassname.PushString("weapon_shotgun_chrome_spawn");
    g_alClassname.PushString("weapon_autoshotgun");
    g_alClassname.PushString("weapon_autoshotgun_spawn");
    g_alClassname.PushString("weapon_rifle");
    g_alClassname.PushString("weapon_rifle_spawn");
    g_alClassname.PushString("weapon_rifle_ak47");
    g_alClassname.PushString("weapon_rifle_ak47_spawn");
    g_alClassname.PushString("weapon_hunting_rifle");
    g_alClassname.PushString("weapon_hunting_rifle_spawn");
    g_alClassname.PushString("weapon_gascan");
}

/****************************************************************************************************/

void BuildWeaponStringMap()
{
    g_smWeaponIdToClassname.Clear();
    g_smWeaponIdToClassname.SetString(L4D2_WEPID_PISTOL_MAGNUM, "weapon_pistol_magnum");
    g_smWeaponIdToClassname.SetString(L4D2_WEPID_SMG_UZI, "weapon_smg");
    g_smWeaponIdToClassname.SetString(L4D2_WEPID_SMG_SILENCED, "weapon_smg_silenced");
    g_smWeaponIdToClassname.SetString(L4D2_WEPID_PUMP_SHOTGUN, "weapon_pumpshotgun");
    g_smWeaponIdToClassname.SetString(L4D2_WEPID_SHOTGUN_CHROME, "weapon_shotgun_chrome");
    g_smWeaponIdToClassname.SetString(L4D2_WEPID_AUTO_SHOTGUN, "weapon_autoshotgun");
    g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_M16, "weapon_rifle");
    g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_AK47, "weapon_rifle_ak47");
    g_smWeaponIdToClassname.SetString(L4D2_WEPID_HUNTING_RIFLE, "weapon_hunting_rifle");
}

/****************************************************************************************************/

void BuildMaps()
{
    g_smWeaponCount.Clear();

    g_smWeaponCount.SetValue("weapon_spawn", 0);

    if (g_bCvar_Melee)
    {
        g_smWeaponCount.SetValue("weapon_melee", 0);
        g_smWeaponCount.SetValue("weapon_melee_spawn", 0);
    }
    if (g_bCvar_PistolMagnum)
    {
        g_smWeaponCount.SetValue("weapon_pistol_magnum", 2);
        g_smWeaponCount.SetValue("weapon_pistol_magnum_spawn", 2);
    }
    if (g_bCvar_SMGUzi)
    {
        g_smWeaponCount.SetValue("weapon_smg", 1);
        g_smWeaponCount.SetValue("weapon_smg_spawn", 1);
    }
    if (g_bCvar_SMGSilenced)
    {
        g_smWeaponCount.SetValue("weapon_smg_silenced", 1);
        g_smWeaponCount.SetValue("weapon_smg_silenced_spawn", 1);
    }
    if (g_bCvar_PumpShotgun)
    {
        g_smWeaponCount.SetValue("weapon_pumpshotgun", 1);
        g_smWeaponCount.SetValue("weapon_pumpshotgun_spawn", 1);
    }
    if (g_bCvar_ShotgunChrome)
    {
        g_smWeaponCount.SetValue("weapon_shotgun_chrome", 1);
        g_smWeaponCount.SetValue("weapon_shotgun_chrome_spawn", 1);
    }
    if (g_bCvar_AutoShotgun)
    {
        g_smWeaponCount.SetValue("weapon_autoshotgun", 1);
        g_smWeaponCount.SetValue("weapon_autoshotgun_spawn", 1);
    }
    if (g_bCvar_RifleM16)
    {
        g_smWeaponCount.SetValue("weapon_rifle", 2);
        g_smWeaponCount.SetValue("weapon_rifle_spawn", 2);
    }
    if (g_bCvar_RifleAK47)
    {
        g_smWeaponCount.SetValue("weapon_rifle_ak47", 2);
        g_smWeaponCount.SetValue("weapon_rifle_ak47_spawn", 2);
    }
    if (g_bCvar_HuntingRifle)
    {
        g_smWeaponCount.SetValue("weapon_hunting_rifle", 1);
        g_smWeaponCount.SetValue("weapon_hunting_rifle_spawn", 1);
    }
    if (g_bCvar_CricketBat)
    {
        g_smWeaponCount.SetValue("cricket_bat", 1);
    }
    if (g_bCvar_Crowbar)
    {
        g_smWeaponCount.SetValue("crowbar", 1);
    }
    if (g_bCvar_Gascan)
    {
        g_smWeaponCount.SetValue("weapon_gascan", 3);
    }

    g_smMeleeModelCount.Clear();

    if (!g_bCvar_Melee)
        return;

    if (g_bCvar_CricketBat)
        g_smMeleeModelCount.SetValue(MODEL_W_CRICKET_BAT, 1);

    if (g_bCvar_Crowbar)
        g_smMeleeModelCount.SetValue(MODEL_W_CROWBAR, 1);
}

/****************************************************************************************************/

public void OnMapStart()
{
    g_iModel_Gascan = PrecacheModel(MODEL_GASCAN, true);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    LateLoad();

    HookEvents();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_IgnoreSkin = g_hCvar_IgnoreSkin.BoolValue;
    g_bCvar_PistolMagnum = g_hCvar_PistolMagnum.BoolValue;
    g_bCvar_PumpShotgun = g_hCvar_PumpShotgun.BoolValue;
    g_bCvar_ShotgunChrome = g_hCvar_ShotgunChrome.BoolValue;
    g_bCvar_AutoShotgun = g_hCvar_AutoShotgun.BoolValue;
    g_bCvar_SMGUzi = g_hCvar_SMGUzi.BoolValue;
    g_bCvar_SMGSilenced = g_hCvar_SMGSilenced.BoolValue;
    g_bCvar_RifleM16 = g_hCvar_RifleM16.BoolValue;
    g_bCvar_RifleAK47 = g_hCvar_RifleAK47.BoolValue;
    g_bCvar_HuntingRifle = g_hCvar_HuntingRifle.BoolValue;
    g_bCvar_CricketBat = g_hCvar_CricketBat.BoolValue;
    g_bCvar_Crowbar = g_hCvar_Crowbar.BoolValue;
    g_bCvar_Melee = (g_bCvar_CricketBat || g_bCvar_Crowbar);
    g_bCvar_Gascan = g_hCvar_Gascan.BoolValue;

    BuildMaps();
}

/****************************************************************************************************/

void LateLoad()
{
    int entity;
    int count;
    char classname[36];

    for (int i = 0; i < g_alClassname.Length; i++)
    {
        g_alClassname.GetString(i, classname, sizeof(classname));

        if (!g_smWeaponCount.GetValue(classname, count))
            continue;

        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, classname)) != INVALID_ENT_REFERENCE)
        {
            OnSpawnPost(entity);
        }
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "prop_physics*")) != INVALID_ENT_REFERENCE)
    {
        if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
            OnSpawnPostPhysicsProp(entity);
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "physics_prop")) != INVALID_ENT_REFERENCE)
    {
        OnSpawnPostPhysicsProp(entity);
    }
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("item_pickup", Event_ItemPickup);
        HookEvent("player_use", Event_PlayerUse);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("item_pickup", Event_ItemPickup);
        UnhookEvent("player_use", Event_PlayerUse);

        return;
    }
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bItemPickup[client] = false;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 0)
        return;

    switch (classname[0])
    {
        case 'w':
        {
            if (classname[1] != 'e') // weapon_*
                return;

            int count;
            if (!g_smWeaponCount.GetValue(classname, count))
                return;

            SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
        }
        case 'p':
        {
            if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
                SDKHook(entity, SDKHook_SpawnPost, OnSpawnPostPhysicsProp);
        }
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_bIsGascan[entity] = false;
}

/****************************************************************************************************/

void OnSpawnPost(int entity)
{
    RequestFrame(OnNextFrame, EntIndexToEntRef(entity)); // 1 frame later required to get skin (m_nSkin) updated
}

/****************************************************************************************************/

void OnSpawnPostPhysicsProp(int entity)
{
    if (!g_bCvar_Gascan)
        return;

    if (GetEntProp(entity, Prop_Send, "m_nModelIndex") != g_iModel_Gascan)
        return;

    ge_bIsGascan[entity] = true;
    RequestFrame(OnNextFrame, EntIndexToEntRef(entity)); // 1 frame later required to get skin (m_nSkin) updated
}

/****************************************************************************************************/

void OnNextFrame(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    UpdateWeaponSkin(entity);
}

/****************************************************************************************************/

void UpdateWeaponSkin(int entity)
{
    if (!g_bCvar_Enabled)
        return;

    if (g_bCvar_IgnoreSkin && GetEntProp(entity, Prop_Send, "m_nSkin") > 0)
        return;

    if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != -1)
        return;

    char classname[36];
    if (ge_bIsGascan[entity])
        classname = "weapon_gascan";
    else
        GetEntityClassname(entity, classname, sizeof(classname));

    int count;

    if (StrEqual(classname, "weapon_melee"))
    {
        char sMeleeName[16];
        GetEntPropString(entity, Prop_Data, "m_strMapSetScriptName", sMeleeName, sizeof(sMeleeName));

        if (!g_smWeaponCount.GetValue(sMeleeName, count))
            return;
    }
    else if (StrEqual(classname, "weapon_melee_spawn"))
    {
        char modelname[PLATFORM_MAX_PATH];
        GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
        StringToLowerCase(modelname);

        if (!g_smMeleeModelCount.GetValue(modelname, count))
            return;
    }
    else if (StrEqual(classname, "weapon_spawn"))
    {
        int weaponId = GetEntProp(entity, Prop_Data, "m_weaponID");
        char sWeaponId[3];
        IntToString(weaponId, sWeaponId, sizeof(sWeaponId));

        char weaponClassname[36];
        if (!g_smWeaponIdToClassname.GetString(sWeaponId, weaponClassname, sizeof(weaponClassname)))
            return;

        if (!g_smWeaponCount.GetValue(weaponClassname, count))
            return;
    }
    else
    {
        if (!g_smWeaponCount.GetValue(classname, count))
            return;
    }

    if (count == 0)
        return;

    int skin = GetRandomInt(0, count);

    SetEntProp(entity, Prop_Send, "m_nSkin", skin);

    if (HasEntProp(entity, Prop_Data, "m_nWeaponSkin"))
        SetEntProp(entity, Prop_Data, "m_nWeaponSkin", skin);
}

/****************************************************************************************************/

void Event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    gc_bItemPickup[client] = true;
}

/****************************************************************************************************/

void Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int targetid = event.GetInt("targetid");

    if (client == 0)
        return;

    if (!gc_bItemPickup[client])
        return;

    gc_bItemPickup[client] = false;

    if (!IsValidClient(client))
        return;

    int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

    if (activeWeapon == -1)
        return;

    if (activeWeapon == targetid)
        return;

    if (!HasEntProp(targetid, Prop_Send, "m_nSkin"))
        return;

    int skin = GetEntProp(targetid, Prop_Send, "m_nSkin");

    SetEntProp(activeWeapon, Prop_Send, "m_nSkin", skin);

    int viewModel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");

    if (viewModel == -1)
        return;

    SetEntProp(viewModel, Prop_Send, "m_nSkin", skin);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdWSkinRng(int client, int args)
{
    LateLoad();

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "------------------- Plugin Cvars (l4d2_wskin_rng) --------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_wskin_rng_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_wskin_rng_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_ignore_skin : %b (%s)", g_bCvar_IgnoreSkin, g_bCvar_IgnoreSkin ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_pistol_magnum : %b (%s)", g_bCvar_PistolMagnum, g_bCvar_PistolMagnum ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_pump_shotgun : %b (%s)", g_bCvar_PumpShotgun, g_bCvar_PumpShotgun ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_shotgun_chrome : %b (%s)", g_bCvar_ShotgunChrome, g_bCvar_ShotgunChrome ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_auto_shotgun : %b (%s)", g_bCvar_AutoShotgun, g_bCvar_AutoShotgun ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_smg_uzi : %b (%s)", g_bCvar_SMGUzi, g_bCvar_SMGUzi ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_smg_silenced : %b (%s)", g_bCvar_SMGSilenced, g_bCvar_SMGSilenced ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_rifle_m16 : %b (%s)", g_bCvar_RifleM16, g_bCvar_RifleM16 ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_rifle_ak47 : %b (%s)", g_bCvar_RifleAK47, g_bCvar_RifleAK47 ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_hunting_rifle : %b (%s)", g_bCvar_HuntingRifle, g_bCvar_HuntingRifle ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_cricket_bat : %b (%s)", g_bCvar_CricketBat, g_bCvar_CricketBat ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_crowbar : %b (%s)", g_bCvar_Crowbar, g_bCvar_Crowbar ? "true" : "false");
    PrintToConsole(client, "l4d2_wskin_rng_gascan : %b (%s)", g_bCvar_Gascan, g_bCvar_Gascan ? "true" : "false");
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
 * Converts the string to lower case.
 *
 * @param input         Input string.
 */
void StringToLowerCase(char[] input)
{
    for (int i = 0; i < strlen(input); i++)
    {
        input[i] = CharToLower(input[i]);
    }
}