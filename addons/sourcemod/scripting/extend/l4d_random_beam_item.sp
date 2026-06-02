/**
// ====================================================================================================
Change Log:

1.0.3 (29-May-2022)
    - Improved performance.
    - Fixed logic running twice on plugin load.
    - Fixed glow color not being applied.
    - Fixed some beams not being removed. (thanks "AsphyxiaJLSA" and "VladimirTk" for reporting and testing)
    - Removed targetname support.

1.0.2 (04-October-2021)
    - Fixed carryable items not restoring beam on drop after being picked up.

1.0.1 (12-September-2021)
    - Added new commands to manually add/remove beam.
    - Added support to model-based config in the data file.
    - Halo changed to disabled by default.

1.0.0 (29-August-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Random Beam Item"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Gives a random beam to items on the map"
#define PLUGIN_VERSION                "1.0.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=334110"

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
#define CONFIG_FILENAME               "l4d_random_beam_item"
#define DATA_FILENAME                 "l4d_random_beam_item"

// ====================================================================================================
// Defines
// ====================================================================================================
#define MODEL_HALO_SPRITE_DEFAULT     "sprites/light_glow03.vmt"
#define MODEL_BEAM_SPRITE_DEFAULT     "sprites/glow_test02.vmt"
#define MODEL_HALO_SPRITE_PLUGIN      "sprites/light_glow02_add_noz.vmt"

#define MODEL_MELEE_FIREAXE           "models/weapons/melee/w_fireaxe.mdl"
#define MODEL_MELEE_FRYING_PAN        "models/weapons/melee/w_frying_pan.mdl"
#define MODEL_MELEE_MACHETE           "models/weapons/melee/w_machete.mdl"
#define MODEL_MELEE_BASEBALL_BAT      "models/weapons/melee/w_bat.mdl"
#define MODEL_MELEE_CROWBAR           "models/weapons/melee/w_crowbar.mdl"
#define MODEL_MELEE_CRICKET_BAT       "models/weapons/melee/w_cricket_bat.mdl"
#define MODEL_MELEE_TONFA             "models/weapons/melee/w_tonfa.mdl"
#define MODEL_MELEE_KATANA            "models/weapons/melee/w_katana.mdl"
#define MODEL_MELEE_ELECTRIC_GUITAR   "models/weapons/melee/w_electric_guitar.mdl"
#define MODEL_MELEE_KNIFE             "models/w_models/weapons/w_knife_t.mdl"
#define MODEL_MELEE_GOLFCLUB          "models/weapons/melee/w_golfclub.mdl"
#define MODEL_MELEE_PITCHFORK         "models/weapons/melee/w_pitchfork.mdl"
#define MODEL_MELEE_SHOVEL            "models/weapons/melee/w_shovel.mdl"
#define MODEL_MELEE_RIOTSHIELD        "models/weapons/melee/w_riotshield.mdl"

#define MODEL_GNOME                   "models/props_junk/gnome.mdl"
#define MODEL_COLA                    "models/w_models/weapons/w_cola.mdl"

#define MODEL_GASCAN                  "models/props_junk/gascan001a.mdl"
#define MODEL_PROPANECANISTER         "models/props_junk/propanecanister001a.mdl"
#define MODEL_OXYGENTANK              "models/props_equipment/oxygentank01.mdl"
#define MODEL_FIREWORKS_CRATE         "models/props_junk/explosive_box001.mdl"

#define L4D2_WEPID_PISTOL                     "1"
#define L4D2_WEPID_SMG                        "2"
#define L4D2_WEPID_PUMPSHOTGUN                "3"
#define L4D2_WEPID_AUTOSHOTGUN                "4"
#define L4D2_WEPID_RIFLE                      "5"
#define L4D2_WEPID_HUNTING_RIFLE              "6"
#define L4D2_WEPID_SMG_SILENCED               "7"
#define L4D2_WEPID_SHOTGUN_CHROME             "8"
#define L4D2_WEPID_RIFLE_DESERT               "9"
#define L4D2_WEPID_SNIPER_MILITARY            "10"
#define L4D2_WEPID_SHOTGUN_SPAS               "11"
#define L4D2_WEPID_FIRST_AID_KIT              "12"
#define L4D2_WEPID_MOLOTOV                    "13"
#define L4D2_WEPID_PIPE_BOMB                  "14"
#define L4D2_WEPID_PAIN_PILLS                 "15"
#define L4D2_WEPID_GASCAN                     "16"
#define L4D2_WEPID_PROPANETANK                "17"
#define L4D2_WEPID_OXYGENTANK                 "18"
#define L4D2_WEPID_CHAINSAW                   "20"
#define L4D2_WEPID_GRENADE_LAUNCHER           "21"
#define L4D2_WEPID_ADRENALINE                 "23"
#define L4D2_WEPID_DEFIBRILLATOR              "24"
#define L4D2_WEPID_VOMITJAR                   "25"
#define L4D2_WEPID_RIFLE_AK47                 "26"
#define L4D2_WEPID_GNOME                      "27"
#define L4D2_WEPID_COLA_BOTTLES               "28"
#define L4D2_WEPID_FIREWORKCRATE              "29"
#define L4D2_WEPID_UPGRADEPACK_INCENDIARY     "30"
#define L4D2_WEPID_UPGRADEPACK_EXPLOSIVE      "31"
#define L4D2_WEPID_PISTOL_MAGNUM              "32"
#define L4D2_WEPID_SMG_MP5                    "33"
#define L4D2_WEPID_RIFLE_SG552                "34"
#define L4D2_WEPID_SNIPER_AWP                 "35"
#define L4D2_WEPID_SNIPER_SCOUT               "36"
#define L4D2_WEPID_RIFLE_M60                  "37"

#define CONFIG_ENABLE                 0
#define CONFIG_RANDOM                 1
#define CONFIG_R                      2
#define CONFIG_G                      3
#define CONFIG_B                      4
#define CONFIG_LENGTH                 5
#define CONFIG_WIDTH                  6
#define CONFIG_HDR                    7
#define CONFIG_HALO                   8
#define CONFIG_ARRAYSIZE              9

#define MAXENTITIES                   2048

#define MAX_BEAM_WIDTH                102.3

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_RemoveSpawner;
ConVar g_hCvar_MinBrightness;
ConVar g_hCvar_UseGlowColor;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_RemoveSpawner;
bool g_bCvar_UseGlowColor;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iHalo = -1;
int g_iDefaultConfig[CONFIG_ARRAYSIZE];

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_vAngles[3] = { 270.0 , 0.0 , 0.0 };
float g_fExtraPosZ = 0.25;
float g_fCvar_MinBrightness;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bWeaponEquipPostHooked[MAXPLAYERS+1];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
bool ge_bUsePostHooked[MAXENTITIES+1];
bool ge_bVPhysicsUpdatePostHooked[MAXENTITIES+1];
bool ge_bTurnOn[MAXENTITIES+1];
int ge_iParentEntRef[MAXENTITIES+1] = { INVALID_ENT_REFERENCE, ... };
int ge_iChildEntRef[MAXENTITIES+1] = { INVALID_ENT_REFERENCE, ... };

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
ArrayList g_alPluginEntities;

// ====================================================================================================
// StringMap - Plugin Variables
// ====================================================================================================
StringMap g_smWeaponIdToClassname;
StringMap g_smMeleeModelToName;
StringMap g_smPropModelToClassname;
StringMap g_smClassnameConfig;
StringMap g_smMeleeConfig;
StringMap g_smModelConfig;

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
	LoadTranslations("l4d_random_beam_item.phrases");
    g_alPluginEntities = new ArrayList();
    g_smWeaponIdToClassname = new StringMap();
    g_smMeleeModelToName = new StringMap();
    g_smPropModelToClassname = new StringMap();
    g_smClassnameConfig = new StringMap();
    g_smMeleeConfig = new StringMap();
    g_smModelConfig = new StringMap();

    BuildMaps();

    LoadConfigs();

    CreateConVar("l4d_random_beam_item_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled          = CreateConVar("l4d_random_beam_item_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_RemoveSpawner    = CreateConVar("l4d_random_beam_item_remove_spawner", "1", "Delete *_spawn entities when its count reaches 0.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_MinBrightness    = CreateConVar("l4d_random_beam_item_min_brightness", "0.5", "Algorithm value to detect the beam minimum brightness for a random color (not accurate).", CVAR_FLAGS, true, 0.0, true, 1.0);
    if (g_bL4D2)
        g_hCvar_UseGlowColor = CreateConVar("l4d_random_beam_item_use_glow_color", "1", "(L4D2 only) Apply the same color from glow.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_RemoveSpawner.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MinBrightness.AddChangeHook(Event_ConVarChanged);
    if (g_bL4D2)
        g_hCvar_UseGlowColor.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_beaminfo", CmdInfo, ADMFLAG_ROOT, "Outputs to the chat the beam info about the entity at your crosshair.");
    RegAdminCmd("sm_beamreload", CmdReload, ADMFLAG_ROOT, "Reload the beam configs.");
    RegAdminCmd("sm_beamremove", CmdRemove, ADMFLAG_ROOT, "Remove plugin beam from entity at crosshair.");
    RegAdminCmd("sm_beamremoveall", CmdRemoveAll, ADMFLAG_ROOT, "Remove all beams created by the plugin.");
    RegAdminCmd("sm_beamadd", CmdAdd, ADMFLAG_ROOT, "Add a beam (with default config) to entity at crosshair.");
    RegAdminCmd("sm_print_cvars_l4d_random_beam_item", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

void BuildMaps()
{
    if (g_bL4D2)
    {
        g_smWeaponIdToClassname.Clear();
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_PISTOL, "weapon_pistol");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SMG, "weapon_smg");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_PUMPSHOTGUN, "weapon_pumpshotgun");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_AUTOSHOTGUN, "weapon_autoshotgun");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE, "weapon_rifle");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_HUNTING_RIFLE, "weapon_hunting_rifle");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SMG_SILENCED, "weapon_smg_silenced");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SHOTGUN_CHROME, "weapon_shotgun_chrome");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_DESERT, "weapon_rifle_desert");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SNIPER_MILITARY, "weapon_sniper_military");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SHOTGUN_SPAS, "weapon_shotgun_spas");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_FIRST_AID_KIT, "weapon_first_aid_kit");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_MOLOTOV, "weapon_molotov");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_PIPE_BOMB, "weapon_pipe_bomb");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_PAIN_PILLS, "weapon_pain_pills");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_GASCAN, "weapon_gascan");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_PROPANETANK, "weapon_propanetank");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_OXYGENTANK, "weapon_oxygentank");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_CHAINSAW, "weapon_chainsaw");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_GRENADE_LAUNCHER, "weapon_grenade_launcher");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_ADRENALINE, "weapon_adrenaline");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_DEFIBRILLATOR, "weapon_defibrillator");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_VOMITJAR, "weapon_vomitjar");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_AK47, "weapon_rifle_ak47");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_GNOME, "weapon_gnome");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_COLA_BOTTLES, "weapon_cola_bottles");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_FIREWORKCRATE, "weapon_fireworkcrate");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_UPGRADEPACK_INCENDIARY, "weapon_upgradepack_incendiary");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_UPGRADEPACK_EXPLOSIVE, "weapon_upgradepack_explosive");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_PISTOL_MAGNUM, "weapon_pistol_magnum");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SMG_MP5, "weapon_smg_mp5");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_SG552, "weapon_rifle_sg552");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SNIPER_AWP, "weapon_sniper_awp");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SNIPER_SCOUT, "weapon_sniper_scout");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_M60, "weapon_rifle_m60");

        g_smMeleeModelToName.Clear();
        g_smMeleeModelToName.SetString(MODEL_MELEE_FIREAXE, "fireaxe");
        g_smMeleeModelToName.SetString(MODEL_MELEE_FRYING_PAN, "frying_pan");
        g_smMeleeModelToName.SetString(MODEL_MELEE_MACHETE, "machete");
        g_smMeleeModelToName.SetString(MODEL_MELEE_BASEBALL_BAT, "baseball_bat");
        g_smMeleeModelToName.SetString(MODEL_MELEE_CROWBAR, "crowbar");
        g_smMeleeModelToName.SetString(MODEL_MELEE_CRICKET_BAT, "cricket_bat");
        g_smMeleeModelToName.SetString(MODEL_MELEE_TONFA, "tonfa");
        g_smMeleeModelToName.SetString(MODEL_MELEE_KATANA, "katana");
        g_smMeleeModelToName.SetString(MODEL_MELEE_ELECTRIC_GUITAR, "electric_guitar");
        g_smMeleeModelToName.SetString(MODEL_MELEE_KNIFE, "knife");
        g_smMeleeModelToName.SetString(MODEL_MELEE_GOLFCLUB, "golfclub");
        g_smMeleeModelToName.SetString(MODEL_MELEE_PITCHFORK, "pitchfork");
        g_smMeleeModelToName.SetString(MODEL_MELEE_SHOVEL, "shovel");
        g_smMeleeModelToName.SetString(MODEL_MELEE_RIOTSHIELD, "riotshield");

        g_smPropModelToClassname.Clear();
        g_smPropModelToClassname.SetString(MODEL_GNOME, "weapon_gnome");
        g_smPropModelToClassname.SetString(MODEL_COLA, "weapon_cola_bottles");
        g_smPropModelToClassname.SetString(MODEL_GASCAN, "weapon_gascan");
        g_smPropModelToClassname.SetString(MODEL_PROPANECANISTER, "weapon_propanetank");
        g_smPropModelToClassname.SetString(MODEL_OXYGENTANK, "weapon_oxygentank");
        g_smPropModelToClassname.SetString(MODEL_FIREWORKS_CRATE, "weapon_fireworkcrate");
    }
    else
    {
        g_smPropModelToClassname.Clear();
        g_smPropModelToClassname.SetString(MODEL_GASCAN, "weapon_gascan");
        g_smPropModelToClassname.SetString(MODEL_PROPANECANISTER, "weapon_propanetank");
        g_smPropModelToClassname.SetString(MODEL_OXYGENTANK, "weapon_oxygentank");
    }
}

/****************************************************************************************************/

public void OnMapStart()
{
    g_iHalo = PrecacheModel(MODEL_HALO_SPRITE_PLUGIN, true);
    PrecacheModel(MODEL_HALO_SPRITE_DEFAULT, true); // Will late precache anyway
    PrecacheModel(MODEL_BEAM_SPRITE_DEFAULT, true); // Will late precache anyway
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    HookEvents();

    LateLoad();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents();

    RemoveAll();

    LateLoad();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_RemoveSpawner = g_hCvar_RemoveSpawner.BoolValue;
    g_fCvar_MinBrightness = g_hCvar_MinBrightness.FloatValue;
    if (g_bL4D2)
        g_bCvar_UseGlowColor = g_hCvar_UseGlowColor.BoolValue;
}

/****************************************************************************************************/

void LoadConfigs()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/%s.cfg", DATA_FILENAME);

    if (!FileExists(path))
    {
        SetFailState("Missing required data file on \"data/%s.cfg\", please re-download.", DATA_FILENAME);
        return;
    }

    KeyValues kv = new KeyValues(DATA_FILENAME);
    kv.ImportFromFile(path);

    g_smClassnameConfig.Clear();
    g_smMeleeConfig.Clear();
    g_smModelConfig.Clear();

    int default_enable;
    int default_random;
    char default_color[12];
    int default_length;
    int default_width;
    int default_hdr;
    int default_halo;

    int iColor[3];

    if (kv.JumpToKey("default"))
    {
        default_enable = kv.GetNum("enable", 0);
        default_random = kv.GetNum("random", 0);
        kv.GetString("color", default_color, sizeof(default_color), "255 255 255");
        default_length = kv.GetNum("length", 0);
        default_width = kv.GetNum("width", 0);
        default_hdr = kv.GetNum("hdr", 0);
        default_halo = kv.GetNum("halo", 0);

        iColor = ConvertRGBToIntArray(default_color);

        if (default_width > MAX_BEAM_WIDTH) // prevent clamping warning message
            default_width = 102;

        g_iDefaultConfig[CONFIG_ENABLE] = default_enable;
        g_iDefaultConfig[CONFIG_RANDOM] = default_random;
        g_iDefaultConfig[CONFIG_R] = iColor[0];
        g_iDefaultConfig[CONFIG_G] = iColor[1];
        g_iDefaultConfig[CONFIG_B] = iColor[2];
        g_iDefaultConfig[CONFIG_LENGTH] = default_length;
        g_iDefaultConfig[CONFIG_WIDTH] = default_width;
        g_iDefaultConfig[CONFIG_HDR] = default_hdr;
        g_iDefaultConfig[CONFIG_HALO] = default_halo;
    }

    kv.Rewind();

    char section[64];
    int enable;
    int random;
    char color[12];
    int length;
    int width;
    int hdr;
    int halo;

    int config[CONFIG_ARRAYSIZE];

    if (kv.JumpToKey("classnames"))
    {
        if (kv.GotoFirstSubKey())
        {
            do
            {
                enable = kv.GetNum("enable", default_enable);
                if (enable == 0)
                    continue;

                random = kv.GetNum("random", default_random);
                kv.GetString("color", color, sizeof(color), default_color);
                length = kv.GetNum("length", default_length);
                width = kv.GetNum("width", default_width);
                hdr = kv.GetNum("hdr", default_hdr);
                halo = kv.GetNum("halo", default_halo);

                iColor = ConvertRGBToIntArray(color);

                if (width > MAX_BEAM_WIDTH) // prevent clamping warning message
                    width = 102;

                config[CONFIG_ENABLE] = enable;
                config[CONFIG_RANDOM] = random;
                config[CONFIG_R] = iColor[0];
                config[CONFIG_G] = iColor[1];
                config[CONFIG_B] = iColor[2];
                config[CONFIG_LENGTH] = length;
                config[CONFIG_WIDTH] = width;
                config[CONFIG_HDR] = hdr;
                config[CONFIG_HALO] = halo;

                kv.GetSectionName(section, sizeof(section));
                TrimString(section);
                StringToLowerCase(section);

                g_smClassnameConfig.SetArray(section, config, sizeof(config));
            } while (kv.GotoNextKey());
        }
    }

    kv.Rewind();

    if (kv.JumpToKey("melees"))
    {
        if (kv.GotoFirstSubKey())
        {
            do
            {
                enable = kv.GetNum("enable", default_enable);
                if (enable == 0)
                    continue;

                random = kv.GetNum("random", default_random);
                kv.GetString("color", color, sizeof(color), default_color);
                length = kv.GetNum("length", default_length);
                width = kv.GetNum("width", default_width);
                hdr = kv.GetNum("hdr", default_hdr);
                halo = kv.GetNum("halo", default_halo);

                iColor = ConvertRGBToIntArray(color);

                if (width > MAX_BEAM_WIDTH) // prevent clamping warning message
                    width = 102;

                config[CONFIG_ENABLE] = enable;
                config[CONFIG_RANDOM] = random;
                config[CONFIG_R] = iColor[0];
                config[CONFIG_G] = iColor[1];
                config[CONFIG_B] = iColor[2];
                config[CONFIG_LENGTH] = length;
                config[CONFIG_WIDTH] = width;
                config[CONFIG_HDR] = hdr;
                config[CONFIG_HALO] = halo;

                kv.GetSectionName(section, sizeof(section));
                TrimString(section);
                StringToLowerCase(section);

                g_smMeleeConfig.SetArray(section, config, sizeof(config));
            } while (kv.GotoNextKey());
        }
    }

    kv.Rewind();

    char modelname[PLATFORM_MAX_PATH];
    if (kv.JumpToKey("models"))
    {
        if (kv.GotoFirstSubKey())
        {
            do
            {
                enable = kv.GetNum("enable", default_enable);
                if (enable == 0)
                    continue;

                random = kv.GetNum("random", default_random);
                kv.GetString("color", color, sizeof(color), default_color);
                length = kv.GetNum("length", default_length);
                width = kv.GetNum("width", default_width);
                hdr = kv.GetNum("hdr", default_hdr);
                halo = kv.GetNum("halo", default_halo);

                iColor = ConvertRGBToIntArray(color);

                if (width > MAX_BEAM_WIDTH) // prevent clamping warning message
                    width = 102;

                config[CONFIG_ENABLE] = enable;
                config[CONFIG_RANDOM] = random;
                config[CONFIG_R] = iColor[0];
                config[CONFIG_G] = iColor[1];
                config[CONFIG_B] = iColor[2];
                config[CONFIG_LENGTH] = length;
                config[CONFIG_WIDTH] = width;
                config[CONFIG_HDR] = hdr;
                config[CONFIG_HALO] = halo;

                kv.GetSectionName(modelname, sizeof(modelname));
                TrimString(modelname);
                StringToLowerCase(modelname);

                g_smModelConfig.SetArray(modelname, config, sizeof(config));
            } while (kv.GotoNextKey());
        }
    }

    kv.Rewind();

    delete kv;
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        if (g_bL4D2)
            HookEvent("weapon_drop", Event_WeaponDrop);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        if (g_bL4D2)
            UnhookEvent("weapon_drop", Event_WeaponDrop);

        return;
    }
}

/****************************************************************************************************/

void LateLoad()
{
    if (g_bL4D2)
    {
        for (int client = 1; client <= MaxClients; client++)
        {
            if (!IsClientInGame(client))
                continue;

            OnClientPutInServer(client);
        }
    }

    int entity;
    char classname[36];

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
    {
        if (entity < 0)
            continue;

        GetEntityClassname(entity, classname, sizeof(classname));
        OnEntityCreated(entity, classname);
    }
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bWeaponEquipPostHooked[client] = false;
}

/****************************************************************************************************/

public void OnClientPutInServer(int client)
{
    if (!g_bL4D2)
        return;

    if (gc_bWeaponEquipPostHooked[client])
        return;

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    OnWeaponEquipPost(client, weapon);

    gc_bWeaponEquipPostHooked[client] = true;
    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

/****************************************************************************************************/

void OnWeaponEquipPost(int client, int weapon)
{
    if (!g_bCvar_Enabled)
        return;

    if (!IsValidEntity(weapon))
        return;

    if (ge_iChildEntRef[weapon] != INVALID_ENT_REFERENCE)
    {
        int beam = EntRefToEntIndex(ge_iChildEntRef[weapon]);
        if (beam != INVALID_ENT_REFERENCE)
            AcceptEntityInput(beam, "Kill");

        ge_iChildEntRef[weapon] = INVALID_ENT_REFERENCE;
    }

    int find = g_alPluginEntities.FindValue(EntIndexToEntRef(weapon));
    if (find != -1)
        g_alPluginEntities.Erase(find);
}

/****************************************************************************************************/

void Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt("propid");
    char classname[36];
    GetEntityClassname(entity, classname, sizeof(classname));
    OnEntityCreated(entity, classname);
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bCvar_Enabled)
        return;

    if (entity < 0)
        return;

    if (StrEqual(classname, "beam_spotlight")) // prevent loops
        return;

    if (g_bCvar_UseGlowColor && HasEntProp(entity, Prop_Send, "m_glowColorOverride"))
        RequestFrame(OnNextFrameGlow, EntIndexToEntRef(entity));
    else
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_bUsePostHooked[entity] = false;
    ge_bVPhysicsUpdatePostHooked[entity] = false;
    ge_bTurnOn[entity] = false;

    if (ge_iParentEntRef[entity] != INVALID_ENT_REFERENCE)
    {
        int parent = EntRefToEntIndex(ge_iParentEntRef[entity]);
        if (parent != INVALID_ENT_REFERENCE)
            ge_iChildEntRef[parent] = INVALID_ENT_REFERENCE;
    }
    ge_iParentEntRef[entity] = INVALID_ENT_REFERENCE;

    if (ge_iChildEntRef[entity] != INVALID_ENT_REFERENCE)
    {
        int beam = EntRefToEntIndex(ge_iChildEntRef[entity]);
        if (beam != INVALID_ENT_REFERENCE)
            AcceptEntityInput(beam, "Kill");
    }
    ge_iChildEntRef[entity] = INVALID_ENT_REFERENCE;

    int find = g_alPluginEntities.FindValue(EntIndexToEntRef(entity));
    if (find != -1)
        g_alPluginEntities.Erase(find);
}

/****************************************************************************************************/

void OnNextFrameGlow(int entityRef)
{
    RequestFrame(OnNextFrame, entityRef);
}

/****************************************************************************************************/

void OnNextFrame(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    if (ge_iChildEntRef[entity] != INVALID_ENT_REFERENCE)
        return;

    if (g_bL4D2)
    {
        if (!HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
        {
            if (HasEntProp(entity, Prop_Send, "m_hOwnerEntity") && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != -1)
                return;
        }
    }

    char modelname[PLATFORM_MAX_PATH];
    GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
    StringToLowerCase(modelname);

    char classname[36];
    GetEntityClassname(entity, classname, sizeof(classname));

    if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
        g_smPropModelToClassname.GetString(modelname, classname, sizeof(classname));

    bool isMelee;
    char melee[16];

    if (StrContains(classname, "weapon_melee") == 0)
    {
        isMelee = true;

        if (StrEqual(classname, "weapon_melee"))
            GetEntPropString(entity, Prop_Data, "m_strMapSetScriptName", melee, sizeof(melee));
        else //weapon_melee_spawn
            g_smMeleeModelToName.GetString(modelname, melee, sizeof(melee));
    }

    if (StrEqual(classname, "weapon_spawn"))
    {
        int weaponId = GetEntProp(entity, Prop_Data, "m_weaponID");
        char sWeaponId[3];
        IntToString(weaponId, sWeaponId, sizeof(sWeaponId));

        if (!g_smWeaponIdToClassname.GetString(sWeaponId, classname, sizeof(classname)))
            return;
    }

    if (classname[0] == 'w')
        ReplaceString(classname, sizeof(classname), "_spawn", "");

    int config[CONFIG_ARRAYSIZE];

    if (config[CONFIG_ENABLE] == 0)
        g_smModelConfig.GetArray(modelname, config, sizeof(config));

    if (isMelee && config[CONFIG_ENABLE] == 0)
        g_smMeleeConfig.GetArray(melee, config, sizeof(config));

    if (config[CONFIG_ENABLE] == 0)
        g_smClassnameConfig.GetArray(classname, config, sizeof(config));

    if (config[CONFIG_ENABLE] == 0)
        return;

    if (g_bCvar_UseGlowColor && HasEntProp(entity, Prop_Send, "m_glowColorOverride") && GetEntProp(entity, Prop_Send, "m_glowColorOverride") != 0)
    {
        int glowColor = GetEntProp(entity, Prop_Send, "m_glowColorOverride");
        config[CONFIG_R] = ((glowColor >> 00) & 0xFF);
        config[CONFIG_G] = ((glowColor >> 08) & 0xFF);
        config[CONFIG_B] = ((glowColor >> 16) & 0xFF);
    }
    else if (config[CONFIG_RANDOM] == 1)
    {
        int colorRandom[3];
        do
        {
            colorRandom[0] = GetRandomInt(0, 255);
            colorRandom[1] = GetRandomInt(0, 255);
            colorRandom[2] = GetRandomInt(0, 255);
        }
        while (GetRGB_Brightness(colorRandom) < g_fCvar_MinBrightness);

        config[CONFIG_R] = colorRandom[0];
        config[CONFIG_G] = colorRandom[1];
        config[CONFIG_B] = colorRandom[2];
    }

    if (HasEntProp(entity, Prop_Data, "m_itemCount")) // *_spawn entities
    {
        if (!ge_bUsePostHooked[entity])
        {
            ge_bUsePostHooked[entity] = true;
            SDKHook(entity, SDKHook_UsePost, OnUsePostSpawner);
        }
    }

    CreateBeam(entity, config);
}

/****************************************************************************************************/

void CreateBeam(int target, int[] config)
{
    char rendercolor[12];
    FormatEx(rendercolor, sizeof(rendercolor), "%i %i %i", config[CONFIG_R], config[CONFIG_G], config[CONFIG_B]);

    float vPos[3];
    GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPos);
    vPos[2] += g_fExtraPosZ;

    int entity = CreateEntityByName("beam_spotlight");
    DispatchKeyValue(entity, "targetname", "l4d_random_beam_item");
    DispatchKeyValue(entity, "spawnflags", "3");
    DispatchKeyValue(entity, "rendercolor", rendercolor);
    DispatchKeyValueFloat(entity, "SpotlightLength", float(config[CONFIG_LENGTH]));
    DispatchKeyValueFloat(entity, "SpotlightWidth", float(config[CONFIG_WIDTH]));
    DispatchKeyValueFloat(entity, "HDRColorScale", config[CONFIG_HDR]/10.0);
    DispatchKeyValueVector(entity, "origin", vPos);
    DispatchKeyValueVector(entity, "angles", g_vAngles);
    DispatchSpawn(entity);

    g_alPluginEntities.Push(EntIndexToEntRef(entity));

    SetEntProp(entity, Prop_Send, "m_nHaloIndex", config[CONFIG_HALO] == 1 ? g_iHalo : -1); // After dispatch spawn otherwise won't work

    ge_bTurnOn[entity] = true;
    ge_iParentEntRef[entity] = EntIndexToEntRef(target);
    ge_iChildEntRef[target] = EntIndexToEntRef(entity);

    if (!ge_bVPhysicsUpdatePostHooked[target])
    {
        ge_bVPhysicsUpdatePostHooked[target] = true;
        SDKHook(target, SDKHook_VPhysicsUpdatePost, OnVPhysicsUpdatePost);
    }
}

/****************************************************************************************************/

void OnVPhysicsUpdatePost(int entity)
{
    if (ge_iChildEntRef[entity] == INVALID_ENT_REFERENCE)
        return;

    int beam = EntRefToEntIndex(ge_iChildEntRef[entity]);
    if (beam == INVALID_ENT_REFERENCE)
    {
        ge_iChildEntRef[entity] = INVALID_ENT_REFERENCE;
        return;
    }

    float vPos[3];
    GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
    vPos[2] += g_fExtraPosZ;

    TeleportEntity(beam, vPos, g_vAngles, NULL_VECTOR);
}

/****************************************************************************************************/

void OnUsePostSpawner(int entity, int activator, int caller, UseType type, float value)
{
    if (!g_bCvar_Enabled)
        return;

    if (!g_bCvar_RemoveSpawner)
        return;

    if (GetEntProp(entity, Prop_Data, "m_itemCount") == 0)
        AcceptEntityInput(entity, "Kill");
}

/****************************************************************************************************/

public void OnGameFrame()
{
    if (g_bL4D2)
        return;

    if (!g_bCvar_Enabled)
        return;

    int entity;
    int parent;

    bool turnOff;
    bool turnOn;

    for (int i = 0; i < g_alPluginEntities.Length; i++)
    {
        entity = EntRefToEntIndex(g_alPluginEntities.Get(i));

        if (entity == INVALID_ENT_REFERENCE)
            continue;

        parent = EntRefToEntIndex(ge_iParentEntRef[entity]);

        if (parent == INVALID_ENT_REFERENCE)
            continue;

        if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
            continue;

        // Fixes L4D1 picked up/dropped weapons
        if (ge_bTurnOn[entity])
        {
            turnOff = (HasEntProp(parent, Prop_Send, "m_hOwnerEntity") && GetEntPropEnt(parent, Prop_Send, "m_hOwnerEntity") != -1);

            if (turnOff)
            {
                ge_bTurnOn[entity] = false;
                AcceptEntityInput(entity, "LightOff");
            }
        }
        else
        {
            turnOn = (HasEntProp(parent, Prop_Send, "m_hOwnerEntity") && GetEntPropEnt(parent, Prop_Send, "m_hOwnerEntity") == -1);

            if (turnOn)
            {
                ge_bTurnOn[entity] = true;
                AcceptEntityInput(entity, "LightOn");
            }
        }
    }
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    RemoveAll();
}

/****************************************************************************************************/

void RemoveAll()
{
    if (g_alPluginEntities.Length > 0)
    {
        int entity;

        ArrayList g_alPluginEntitiesClone = g_alPluginEntities.Clone();

        for (int i = 0; i < g_alPluginEntitiesClone.Length; i++)
        {
            entity = EntRefToEntIndex(g_alPluginEntitiesClone.Get(i));

            if (entity == INVALID_ENT_REFERENCE)
                continue;

            AcceptEntityInput(entity, "Kill");
        }

        delete g_alPluginEntitiesClone;

        g_alPluginEntities.Clear();
    }
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdInfo(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int entity = GetClientAimTarget(client, false);

    if (entity == -1)
    {
        PrintToChat(client, "%t", "L4DRandomBeamItem_InvalidTarget");
        return Plugin_Handled;
    }

    if (ge_iChildEntRef[entity] == INVALID_ENT_REFERENCE)
    {
        PrintToChat(client, "%t", "L4DRandomBeamItem_TargetEntityNoBeam");
        return Plugin_Handled;
    }

    int beam = EntRefToEntIndex(ge_iChildEntRef[entity]);
    if (beam == INVALID_ENT_REFERENCE)
    {
        ge_iChildEntRef[entity] = INVALID_ENT_REFERENCE;
        PrintToChat(client, "%t", "L4DRandomBeamItem_TargetEntityNoBeam");
        return Plugin_Handled;
    }

    float length = GetEntPropFloat(beam, Prop_Send, "m_flSpotlightMaxLength");
    float width = GetEntPropFloat(beam, Prop_Send, "m_flSpotlightGoalWidth");
    float hdrColorScale = GetEntPropFloat(beam, Prop_Send, "m_flHDRColorScale");

    int color = GetEntProp(beam, Prop_Send, "m_clrRender");
    int rgb[3];
    rgb[0] = ((color >> 00) & 0xFF);
    rgb[1] = ((color >> 08) & 0xFF);
    rgb[2] = ((color >> 16) & 0xFF);

    char classname[36];
    GetEntityClassname(entity, classname, sizeof(classname));

    char modelname[PLATFORM_MAX_PATH];
    GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));

    PrintToChat(client, "%t", "L4DRandomBeamItem_BeamIndexTargetIndexClassname", beam, entity, classname, modelname, rgb[0], rgb[1], rgb[2], color, GetRGB_Brightness(rgb), RoundFloat(length), RoundFloat(width), hdrColorScale);

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdReload(int client, int args)
{
    LoadConfigs();

    RemoveAll();

    LateLoad();

    if (IsValidClient(client))
        PrintToChat(client, "%t", "L4DRandomBeamItem_BeamConfigsReloaded");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdRemove(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int entity = GetClientAimTarget(client, false);

    if (entity == -1)
    {
        PrintToChat(client, "%t", "L4DRandomBeamItem_InvalidTarget");
        return Plugin_Handled;
    }

    if (ge_iChildEntRef[entity] == INVALID_ENT_REFERENCE)
    {
        PrintToChat(client, "%t", "L4DRandomBeamItem_TargetEntityNoBeam");
        return Plugin_Handled;
    }

    int beam = EntRefToEntIndex(ge_iChildEntRef[entity]);
    if (beam == INVALID_ENT_REFERENCE)
    {
        ge_iChildEntRef[entity] = INVALID_ENT_REFERENCE;
        PrintToChat(client, "%t", "L4DRandomBeamItem_TargetEntityNoBeam");
        return Plugin_Handled;
    }
    else
    {
        AcceptEntityInput(beam, "Kill");
        PrintToChat(client, "%t", "L4DRandomBeamItem_RemovedTargetEntityPluginBeam");
        return Plugin_Handled;
    }
}

/****************************************************************************************************/

Action CmdRemoveAll(int client, int args)
{
    RemoveAll();

    if (IsValidClient(client))
        PrintToChat(client, "%t", "L4DRandomBeamItem_RemovedAllBeamsCreatedPlugin");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdAdd(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int entity = GetClientAimTarget(client, false);

    if (entity == -1)
    {
        PrintToChat(client, "%t", "L4DRandomBeamItem_InvalidTarget");
        return Plugin_Handled;
    }

    int beam = EntRefToEntIndex(ge_iChildEntRef[entity]);
    if (beam != INVALID_ENT_REFERENCE)
    {
        AcceptEntityInput(beam, "Kill");
    }
    else
    {
        ge_iChildEntRef[entity] = INVALID_ENT_REFERENCE;
    }

    if (g_bCvar_UseGlowColor && HasEntProp(entity, Prop_Send, "m_glowColorOverride") && GetEntProp(entity, Prop_Send, "m_glowColorOverride") != 0)
    {
        int glowColor = GetEntProp(entity, Prop_Send, "m_glowColorOverride");
        g_iDefaultConfig[CONFIG_R] = ((glowColor >> 00) & 0xFF);
        g_iDefaultConfig[CONFIG_G] = ((glowColor >> 08) & 0xFF);
        g_iDefaultConfig[CONFIG_B] = ((glowColor >> 16) & 0xFF);
    }
    else if (g_iDefaultConfig[CONFIG_RANDOM] == 1)
    {
        int colorRandom[3];
        do
        {
            colorRandom[0] = GetRandomInt(0, 255);
            colorRandom[1] = GetRandomInt(0, 255);
            colorRandom[2] = GetRandomInt(0, 255);
        }
        while (GetRGB_Brightness(colorRandom) < g_fCvar_MinBrightness);

        g_iDefaultConfig[CONFIG_R] = colorRandom[0];
        g_iDefaultConfig[CONFIG_G] = colorRandom[1];
        g_iDefaultConfig[CONFIG_B] = colorRandom[2];
    }

    CreateBeam(entity, g_iDefaultConfig);

    PrintToChat(client, "%t", "L4DRandomBeamItem_BeamAddedTargetEntity");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d_random_beam_item) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_random_beam_item_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_random_beam_item_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_random_beam_item_remove_spawner : %b (%s)", g_bCvar_RemoveSpawner, g_bCvar_RemoveSpawner ? "true" : "false");
    PrintToConsole(client, "l4d_random_beam_item_min_brightness : %.1f", g_fCvar_MinBrightness);
    if (g_bL4D2) PrintToConsole(client, "l4d_random_beam_item_use_glow_color : %b (%s)", g_bCvar_UseGlowColor, g_bCvar_UseGlowColor ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------------------- Array List -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "g_alPluginEntities count : %i", g_alPluginEntities.Length);
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
 * @param client          Client index.
 * @return                True if client index is valid, false otherwise.
 */
bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

/****************************************************************************************************/

/**
 * Validates if is a valid client.
 *
 * @param client          Client index.
 * @return                True if client index is valid and client is in game, false otherwise.
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

/****************************************************************************************************/

/**
 * Returns the integer array value of a RGB string.
 * Format: Three values between 0-255 separated by spaces. "<0-255> <0-255> <0-255>"
 * Example: "255 255 255"
 *
 * @param sColor        RGB color string.
 * @return              Integer array (int[3]) value of the RGB string or {0,0,0} if not in specified format.
 */
int[] ConvertRGBToIntArray(char[] sColor)
{
    int color[3];

    if (sColor[0] == 0)
        return color;

    char sColors[3][4];
    int count = ExplodeString(sColor, " ", sColors, sizeof(sColors), sizeof(sColors[]));

    switch (count)
    {
        case 1:
        {
            color[0] = StringToInt(sColors[0]);
        }
        case 2:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
        }
        case 3:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
            color[2] = StringToInt(sColors[2]);
        }
    }

    return color;
}

/****************************************************************************************************/

/**
 * Source: https://stackoverflow.com/a/12216661
 * Returns the RGB brightness of a RGB integer array value.
 *
 * @param rgb           RGB integer array (int[3]).
 * @return              Brightness float value between 0.0 and 1.0.
 */
float GetRGB_Brightness(int[] rgb)
{
    int r = rgb[0];
    int g = rgb[1];
    int b = rgb[2];

    int cmax = (r > g) ? r : g;
    if (b > cmax) cmax = b;
    return cmax / 255.0;
}