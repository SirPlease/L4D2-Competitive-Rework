/**
// ====================================================================================================
Change Log:

1.0.7 (10-October-2021)
    - Added cvar to allow beam use by dead players. (thanks "Beatles" for requesting)

1.0.6 (01-October-2021)
    - Fixed beams not disappearing on L4D1. (thanks "Beatles" for reporting)

1.0.5 (26-April-2021)
    - Added Hungarian (hu) translation. (thanks to "KasperH")
    - Added Romanian (ro) translation. (thanks to "CryWolf")

1.0.4 (17-April-2021)
    - Added Simplified Chinese (chi) and Traditional Chinese (zho) translations. (thanks to "HarryPotter")

1.0.3 (14-April-2021)
    - Added display type cvars for the messages.

1.0.2 (09-April-2021)
    - Fixed rare invalid client index on OnPlayerRunCmdPost. (thanks "Shao" for reporting)

1.0.1 (03-April-2021)
    - Added animation to field.
    - Added sound and message notifications. (thanks "Benjamin38" for request and snippet code)
    - Added intro, cooldown and team warning messages (chat and hint).
    - Added support to translation. (en / es / pt / pt_p)

1.0.0 (16-March-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Spot Marker"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Allow teammates to create spot markers visible only to them"
#define PLUGIN_VERSION                "1.0.7"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=331347"

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
#define CONFIG_FILENAME               "l4d_spot_marker"
#define TRANSLATION_FILENAME          "l4d_spot_marker.phrases"

// ====================================================================================================
// Defines
// ====================================================================================================
#define ENTITY_WORLDSPAWN             0

#define TEAM_SPECTATOR                1
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

#define FLAG_TEAM_NONE                (0 << 0) // 0 | 0000
#define FLAG_TEAM_SURVIVOR            (1 << 0) // 1 | 0001
#define FLAG_TEAM_INFECTED            (1 << 1) // 2 | 0010
#define FLAG_TEAM_SPECTATOR           (1 << 2) // 4 | 0100
#define FLAG_TEAM_HOLDOUT             (1 << 3) // 8 | 1000

#define FLAG_MSG_DISPLAY_CHAT         (1 << 0) // 1 | 01
#define FLAG_MSG_DISPLAY_HINT         (1 << 1) // 2 | 10

#define DIRECTION_OUT                 0
#define DIRECTION_IN                  1

#define L4D1_BEAM_LIFE_MIN            0.11 // less than 0.11 reads as 0 in L4D1
#define L4D2_BEAM_LIFE_MIN            0.1

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Duration;
ConVar g_hCvar_Cooldown;
ConVar g_hCvar_SkillReadySound;
ConVar g_hCvar_UseSound;
ConVar g_hCvar_Team;
ConVar g_hCvar_Alive;
ConVar g_hCvar_Field;
ConVar g_hCvar_FieldModel;
ConVar g_hCvar_FieldColor;
ConVar g_hCvar_FieldAlpha;
ConVar g_hCvar_FieldDuration;
ConVar g_hCvar_FieldRepeat;
ConVar g_hCvar_FieldStartRadius;
ConVar g_hCvar_FieldEndRadius;
ConVar g_hCvar_FieldWidth;
ConVar g_hCvar_FieldAmplitude;
ConVar g_hCvar_FieldOffset;
ConVar g_hCvar_Sprite;
ConVar g_hCvar_SpriteZAxis;
ConVar g_hCvar_SpriteModel;
ConVar g_hCvar_SpriteAlpha;
ConVar g_hCvar_SpriteScale;
ConVar g_hCvar_SpriteColor;
ConVar g_hCvar_SpriteFadeDistance;
ConVar g_hCvar_SpriteSpeed;
ConVar g_hCvar_SpriteMinMax;
ConVar g_hCvar_SyncRandomColor;
ConVar g_hCvar_ColorPerClient;
ConVar g_hCvar_Intro;
ConVar g_hCvar_IntroMsg;
ConVar g_hCvar_SkillReadyMsg;
ConVar g_hCvar_SpotMarkedMsg;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bCvar_Enabled;
bool g_bCvar_SkillReadySound;
bool g_bCvar_UseSound;
bool g_bCvar_Alive;
bool g_bCvar_Field;
bool g_bCvar_RandomFieldColor;
bool g_bCvar_Sprite;
bool g_bCvar_RandomSpriteColor;
bool g_bCvar_SpriteSpeed;
bool g_bCvar_SpriteMinMax;
bool g_bCvar_SyncRandomColor;
bool g_bCvar_ColorPerClient;
bool g_bCvar_Intro;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_Team;
int g_iCvar_FieldColor[3];
int g_iCvar_FieldAlpha;
int g_iCvar_SpriteAlpha;
int g_iCvar_SpriteFadeDistance;
int g_iCvar_IntroMsg;
int g_iCvar_SkillReadyMsg;
int g_iCvar_SpotMarkedMsg;
int g_iFieldModelIndex = -1;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fBeamLife;
float g_fCvar_Duration;
float g_fCvar_Cooldown;
float g_fCvar_FieldDuration;
float g_fCvar_FieldRepeat;
float g_fCvar_FieldStartRadius;
float g_fCvar_FieldEndRadius;
float g_fCvar_FieldWidth;
float g_fCvar_FieldAmplitude;
float g_fCvar_FieldOffset;
float g_fCvar_SpriteZAxis;
float g_fCvar_SpriteScale;
float g_fCvar_SpriteSpeed;
float g_fCvar_SpriteMinMax;
float g_fCvar_Intro;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
char g_sCvar_SkillReadySound[PLATFORM_MAX_PATH];
char g_sCvar_UseSound[PLATFORM_MAX_PATH];
char g_sCvar_FieldModel[PLATFORM_MAX_PATH];
char g_sCvar_FieldColor[12];
char g_sCvar_SpriteModel[PLATFORM_MAX_PATH];
char g_sCvar_SpriteAlpha[4];
char g_sCvar_SpriteScale[5];
char g_sCvar_SpriteColor[12];
char g_sCvar_SpriteFadeDistance[5];
char g_sKillInput[50];

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
float gc_fLastTime[MAXPLAYERS+1];
int gc_iClientColorR[MAXPLAYERS+1];
int gc_iClientColorG[MAXPLAYERS+1];
int gc_iClientColorB[MAXPLAYERS+1];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
bool ge_bMoveUp[MAXENTITIES+1];
int ge_iTeam[MAXENTITIES+1];

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
    g_fBeamLife = (g_bL4D2 ? L4D2_BEAM_LIFE_MIN : L4D1_BEAM_LIFE_MIN);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadPluginTranslations();

    CreateConVar("l4d_spot_marker_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled            = CreateConVar("l4d_spot_marker_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Duration           = CreateConVar("l4d_spot_marker_duration", "10.0", "Duration (seconds) of the spot marker.", CVAR_FLAGS, true, 0.0);
    g_hCvar_Cooldown           = CreateConVar("l4d_spot_marker_cooldown", "10.0", "Cooldown (seconds) to use the spot marker.", CVAR_FLAGS, true, 0.0);
    g_hCvar_SkillReadySound    = CreateConVar("l4d_spot_marker_skill_ready_sound", "ui/alert_clink.wav", "Skill ready sound.\nEmpty = OFF.", CVAR_FLAGS);
    g_hCvar_UseSound           = CreateConVar("l4d_spot_marker_use_sound", "buttons/blip1.wav", "Use sound.\nEmpty = OFF.", CVAR_FLAGS);
    g_hCvar_Team               = CreateConVar("l4d_spot_marker_team", "3", "Which teams should be able to create spot markers.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
    g_hCvar_Alive              = CreateConVar("l4d_spot_marker_alive", "1", "Allow the command to be used only by alive players.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Field              = CreateConVar("l4d_spot_marker_field", "1", "Create a beacon field.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_FieldModel         = CreateConVar("l4d_spot_marker_field_model", "sprites/laserbeam.vmt", "Beacon field model.");
    g_hCvar_FieldColor         = CreateConVar("l4d_spot_marker_field_color", "255 255 0", "Beacon field color.\nUse \"random\" for random colors.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\").", CVAR_FLAGS);
    g_hCvar_FieldAlpha         = CreateConVar("l4d_spot_marker_field_alpha", "255", "Beacon field alpha transparency.\n0 = Invisible, 255 = Fully Visible.", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_FieldDuration      = CreateConVar("l4d_spot_marker_field_duration", "1.0", "Beacon field duration (seconds).", CVAR_FLAGS, true, 0.1);
    g_hCvar_FieldRepeat        = CreateConVar("l4d_spot_marker_field_repeat", "1.0", "Repeat interval to create a beacon field.", CVAR_FLAGS, true, 0.0);
    g_hCvar_FieldStartRadius   = CreateConVar("l4d_spot_marker_field_start_radius", "75.0", "Beacon field start radius.", CVAR_FLAGS, true, 0.0);
    g_hCvar_FieldEndRadius     = CreateConVar("l4d_spot_marker_field_end_radius", "100.0", "Beacon field end radius.", CVAR_FLAGS, true, 0.0);
    g_hCvar_FieldWidth         = CreateConVar("l4d_spot_marker_field_width", "2.0", "Beacon field width.", CVAR_FLAGS, true, 0.0);
    g_hCvar_FieldAmplitude     = CreateConVar("l4d_spot_marker_field_amplitude", "0.0", "Beacon field amplitude.", CVAR_FLAGS, true, 0.0);
    g_hCvar_FieldOffset        = CreateConVar("l4d_spot_marker_field_offset", "24.0", "Beacon field offset (Z pos).", CVAR_FLAGS, true, 0.0);
    g_hCvar_Sprite             = CreateConVar("l4d_spot_marker_sprite", "1", "Create a sprite.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_SpriteZAxis        = CreateConVar("l4d_spot_marker_sprite_z_axis", "50.0", "Additional Z axis to the sprite.", CVAR_FLAGS, true, 0.0);
    g_hCvar_SpriteModel        = CreateConVar("l4d_spot_marker_sprite_model", "vgui/icon_download.vmt", "Sprite model.");
    g_hCvar_SpriteColor        = CreateConVar("l4d_spot_marker_sprite_color", "255 255 0", "Sprite color.\nUse \"random\" for random colors.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\").", CVAR_FLAGS);
    g_hCvar_SpriteAlpha        = CreateConVar("l4d_spot_marker_sprite_alpha", "255", "Sprite alpha transparency.\nNote: Some models don't allow to change the alpha.\n0 = Invisible, 255 = Fully Visible", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_SpriteScale        = CreateConVar("l4d_spot_marker_sprite_scale", "0.25", "Sprite scale (increases both height and width).\nSome range values maintain the size the same.", CVAR_FLAGS, true, 0.0);
    g_hCvar_SpriteFadeDistance = CreateConVar("l4d_spot_marker_sprite_fade_distance", "-1", "Minimum distance that a client must be before the sprite fades.\n-1 = Always visible.", CVAR_FLAGS, true, -1.0, true, 9999.0);
    g_hCvar_SpriteSpeed        = CreateConVar("l4d_spot_marker_sprite_speed", "1.0", "Speed that the sprite will move at the Z axis.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_SpriteMinMax       = CreateConVar("l4d_spot_marker_sprite_min_max", "4.0", "Minimum/Maximum distance between the original position that the sprite should reach before inverting the vertical direction.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_SyncRandomColor    = CreateConVar("l4d_spot_marker_sync_random_color", "1", "Apply the same random color for both field and sprite.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ColorPerClient     = CreateConVar("l4d_spot_marker_color_per_client", "1", "Preserve random color per player.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Intro              = CreateConVar("l4d_spot_marker_intro", "60.0", "Show intro message in chat this many seconds after a client joins.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_IntroMsg           = CreateConVar("l4d_spot_marker_intro_msg", "1", "Display type for the \"Intro\" message.\n0 = OFF, 1 = CHAT, 2 = HINT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", displays the message in CHAT and as a HINT.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_SkillReadyMsg      = CreateConVar("l4d_spot_marker_skill_ready_msg", "1", "Display type for the \"Skill Ready\" message.\n0 = OFF, 1 = CHAT, 2 = HINT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", displays the message in CHAT and as a HINT.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_SpotMarkedMsg      = CreateConVar("l4d_spot_marker_spot_marked_msg", "1", "Display type for the \"Spot Marked\" message.\n0 = OFF, 1 = CHAT, 2 = HINT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", displays the message in CHAT and as a HINT.", CVAR_FLAGS, true, 0.0, true, 3.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Duration.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Cooldown.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SkillReadySound.AddChangeHook(Event_ConVarChanged);
    g_hCvar_UseSound.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Team.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Alive.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Field.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldModel.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldColor.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldAlpha.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldDuration.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldRepeat.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldStartRadius.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldEndRadius.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldWidth.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldAmplitude.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldOffset.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Sprite.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteZAxis.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteModel.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteColor.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteAlpha.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteScale.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteFadeDistance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteSpeed.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteMinMax.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SyncRandomColor.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Intro.AddChangeHook(Event_ConVarChanged);
    g_hCvar_IntroMsg.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SkillReadyMsg.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpotMarkedMsg.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Player Commands
    RegConsoleCmd("sm_spot", SpotCmd);

    // Admin Commands
    RegAdminCmd("sm_spotmarker", CmdSpotMarker, ADMFLAG_ROOT, "Create a spot marker on self crosshair (no args) or specified targets crosshair. Example: self -> sm_spotmarker / target -> sm_spotmarker @bots");
    RegAdminCmd("sm_print_cvars_l4d_spot_marker", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

void LoadPluginTranslations()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
    if (FileExists(path))
        LoadTranslations(TRANSLATION_FILENAME);
    else
        SetFailState("Missing required translation file on \"translations/%s.txt\", please re-download.", TRANSLATION_FILENAME);
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    int entity;
    char targetname[17];

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "info_target")) != INVALID_ENT_REFERENCE)
    {
        GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
        if (StrEqual(targetname, "l4d_spot_marker"))
            AcceptEntityInput(entity, "Kill");
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "env_sprite")) != INVALID_ENT_REFERENCE)
    {
        GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
        if (StrEqual(targetname, "l4d_spot_marker"))
            AcceptEntityInput(entity, "Kill");
    }
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    LateLoad();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_fCvar_Duration = g_hCvar_Duration.FloatValue;
    g_fCvar_Cooldown = g_hCvar_Cooldown.FloatValue;
    g_hCvar_SkillReadySound.GetString(g_sCvar_SkillReadySound, sizeof(g_sCvar_SkillReadySound));
    TrimString(g_sCvar_SkillReadySound);
    g_bCvar_SkillReadySound = (g_sCvar_SkillReadySound[0] != 0);
    if (g_bCvar_SkillReadySound)
        PrecacheSound(g_sCvar_SkillReadySound, true);
    g_hCvar_UseSound.GetString(g_sCvar_UseSound, sizeof(g_sCvar_UseSound));
    TrimString(g_sCvar_UseSound);
    g_bCvar_UseSound = (g_sCvar_UseSound[0] != 0);
    if (g_bCvar_UseSound)
        PrecacheSound(g_sCvar_UseSound, true);
    g_iCvar_Team = g_hCvar_Team.IntValue;
    g_bCvar_Alive = g_hCvar_Alive.BoolValue;
    g_hCvar_FieldModel.GetString(g_sCvar_FieldModel, sizeof(g_sCvar_FieldModel));
    TrimString(g_sCvar_FieldModel);
    g_iFieldModelIndex = PrecacheModel(g_sCvar_FieldModel, true);
    g_bCvar_Field = g_hCvar_Field.BoolValue;
    g_hCvar_FieldColor.GetString(g_sCvar_FieldColor, sizeof(g_sCvar_FieldColor));
    TrimString(g_sCvar_FieldColor);
    g_bCvar_RandomFieldColor = StrEqual(g_sCvar_FieldColor, "random", false);
    g_iCvar_FieldColor = ConvertRGBToIntArray(g_sCvar_FieldColor);
    g_iCvar_FieldAlpha = g_hCvar_FieldAlpha.IntValue;
    g_fCvar_FieldDuration = g_hCvar_FieldDuration.FloatValue;
    g_fCvar_FieldRepeat = g_hCvar_FieldRepeat.FloatValue;
    g_fCvar_FieldStartRadius = g_hCvar_FieldStartRadius.FloatValue;
    g_fCvar_FieldEndRadius = g_hCvar_FieldEndRadius.FloatValue;
    g_fCvar_FieldWidth = g_hCvar_FieldWidth.FloatValue;
    g_fCvar_FieldAmplitude = g_hCvar_FieldAmplitude.FloatValue;
    g_fCvar_FieldOffset = g_hCvar_FieldOffset.FloatValue;
    g_bCvar_Sprite = g_hCvar_Sprite.BoolValue;
    g_fCvar_SpriteZAxis = g_hCvar_SpriteZAxis.FloatValue;
    g_hCvar_SpriteModel.GetString(g_sCvar_SpriteModel, sizeof(g_sCvar_SpriteModel));
    TrimString(g_sCvar_SpriteModel);
    PrecacheModel(g_sCvar_SpriteModel, true);
    g_iCvar_SpriteAlpha = g_hCvar_SpriteAlpha.IntValue;
    IntToString(g_iCvar_SpriteAlpha, g_sCvar_SpriteAlpha, sizeof(g_sCvar_SpriteAlpha));
    g_fCvar_SpriteScale = g_hCvar_SpriteScale.FloatValue;
    FloatToString(g_fCvar_SpriteScale, g_sCvar_SpriteScale, sizeof(g_sCvar_SpriteScale));
    g_hCvar_SpriteColor.GetString(g_sCvar_SpriteColor, sizeof(g_sCvar_SpriteColor));
    TrimString(g_sCvar_SpriteColor);
    g_bCvar_RandomSpriteColor = StrEqual(g_sCvar_SpriteColor, "random", false);
    g_iCvar_SpriteFadeDistance = g_hCvar_SpriteFadeDistance.IntValue;
    IntToString(g_iCvar_SpriteFadeDistance, g_sCvar_SpriteFadeDistance, sizeof(g_sCvar_SpriteFadeDistance));
    g_fCvar_SpriteSpeed = g_hCvar_SpriteSpeed.FloatValue;
    g_bCvar_SpriteSpeed = (g_fCvar_SpriteSpeed > 0.0);
    g_fCvar_SpriteMinMax = g_hCvar_SpriteMinMax.FloatValue;
    g_bCvar_SpriteMinMax = (g_fCvar_SpriteMinMax > 0.0);
    g_bCvar_SyncRandomColor = g_hCvar_SyncRandomColor.BoolValue;
    g_bCvar_ColorPerClient = g_hCvar_ColorPerClient.BoolValue;
    g_fCvar_Intro = g_hCvar_Intro.FloatValue;
    g_bCvar_Intro = (g_fCvar_Intro > 0.0);
    g_iCvar_IntroMsg = g_hCvar_IntroMsg.IntValue;
    g_iCvar_SkillReadyMsg = g_hCvar_SkillReadyMsg.IntValue;
    g_iCvar_SpotMarkedMsg = g_hCvar_SpotMarkedMsg.IntValue;
    FormatEx(g_sKillInput, sizeof(g_sKillInput), "OnUser1 !self:Kill::%.1f:-1", g_fCvar_Duration);
}

/****************************************************************************************************/

void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientPutInServer(client);
    }
}

/****************************************************************************************************/

public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client))
        return;

    if (g_bCvar_Intro)
        CreateTimer(g_fCvar_Intro, TimerIntro, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

    gc_iClientColorR[client] = GetRandomInt(0, 255);
    gc_iClientColorG[client] = GetRandomInt(0, 255);
    gc_iClientColorB[client] = GetRandomInt(0, 255);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_fLastTime[client] = 0.0;
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_bMoveUp[entity] = false;
    ge_iTeam[entity] = 0;
}

/****************************************************************************************************/

public void OnPlayerRunCmdPost(int client, int buttons)
{
    if ((buttons & IN_SPEED) && (buttons & IN_USE)) // SHIFT + E
        TryCreateSpotMarker(client);
}

/****************************************************************************************************/

void TryCreateSpotMarker(int client)
{
    if (!g_bCvar_Enabled)
        return;

    if (!IsValidClientIndex(client))
        return;

    if (IsFakeClient(client))
        return;

    CreateSpotMarker(client);
}

/****************************************************************************************************/

void CreateSpotMarker(int client)
{
    if (gc_fLastTime[client] != 0.0 && GetGameTime() - gc_fLastTime[client] < g_fCvar_Cooldown)
        return;

    if (g_bCvar_Alive && !IsPlayerAlive(client))
        return;

    int clientTeam = GetClientTeam(client);

    if (!(GetTeamFlag(clientTeam) & g_iCvar_Team))
        return;


    bool hit;
    float vEndPos[3];

    int clientAim = GetClientAimTarget(client, true);

    if (IsValidClientIndex(clientAim))
    {
        hit = true;
        GetClientAbsOrigin(clientAim, vEndPos);
    }
    else
    {
        float vPos[3];
        GetClientEyePosition(client, vPos);

        float vAng[3];
        GetClientEyeAngles(client, vAng);

        Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_ALL, RayType_Infinite, TraceFilter, client);

        if (TR_DidHit(trace))
        {
            hit = true;
            TR_GetEndPosition(vEndPos, trace);
        }

        delete trace;
    }

    if (!hit)
        return;

    gc_fLastTime[client] = GetGameTime();

    CreateTimer(g_fCvar_Cooldown, TimerCooldown, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

    for (int target = 1; target <= MaxClients; target++)
    {
        if (!IsClientInGame(target))
            continue;

        if (IsFakeClient(target))
            continue;

        if (clientTeam != GetClientTeam(target))
            continue;

        if (g_bCvar_UseSound)
            EmitSoundToClient(target, g_sCvar_UseSound);

        if (g_iCvar_SpotMarkedMsg & FLAG_MSG_DISPLAY_CHAT)
            CPrintToChat(target, "%t", "Spot Marked", client);

        if (g_iCvar_SpotMarkedMsg & FLAG_MSG_DISPLAY_HINT)
            CPrintHintText(target, "%t", "Spot Marked", client);
    }

    int randomColor[3];
    if (g_bCvar_SyncRandomColor)
    {
        randomColor[0] = GetRandomInt(0, 255);
        randomColor[1] = GetRandomInt(0, 255);
        randomColor[2] = GetRandomInt(0, 255);
    }

    if (g_bCvar_ColorPerClient)
    {
        randomColor[0] = gc_iClientColorR[client];
        randomColor[1] = gc_iClientColorG[client];
        randomColor[2] = gc_iClientColorB[client];
    }

    if (g_bCvar_Field)
    {
        float vBeamPos[3];
        vBeamPos = vEndPos;
        vBeamPos[2] += g_fCvar_FieldOffset;

        int color[4];
        if (g_bCvar_RandomFieldColor)
        {
            if (g_bCvar_SyncRandomColor)
            {
                color[0] = randomColor[0];
                color[1] = randomColor[1];
                color[2] = randomColor[2];
            }
            else
            {
                color[0] = GetRandomInt(0, 255);
                color[1] = GetRandomInt(0, 255);
                color[2] = GetRandomInt(0, 255);
            }
            color[3] = g_iCvar_FieldAlpha;
        }
        else
        {
            color[0] = g_iCvar_FieldColor[0];
            color[1] = g_iCvar_FieldColor[1];
            color[2] = g_iCvar_FieldColor[2];
            color[3] = g_iCvar_FieldAlpha;
        }

        int direction = DIRECTION_IN;
        float timeLimit = GetGameTime() + g_fCvar_Duration;

        DataPack pack;
        CreateDataTimer(g_fCvar_FieldRepeat, TimerField, pack, TIMER_FLAG_NO_MAPCHANGE);
        pack.WriteCell(clientTeam);
        pack.WriteCell(direction);
        pack.WriteCell(color[0]);
        pack.WriteCell(color[1]);
        pack.WriteCell(color[2]);
        pack.WriteCell(color[3]);
        pack.WriteFloat(timeLimit);
        pack.WriteFloat(vBeamPos[0]);
        pack.WriteFloat(vBeamPos[1]);
        pack.WriteFloat(vBeamPos[2]);

        float fieldDuration = (timeLimit - GetGameTime() < g_fCvar_FieldDuration ? timeLimit - GetGameTime() : g_fCvar_FieldDuration);

        if (fieldDuration < g_fBeamLife)
            fieldDuration = g_fBeamLife;

        int[] targets = new int[MaxClients];
        int targetsCount;

        for (int target = 1; target <= MaxClients; target++)
        {
            if (!IsClientInGame(target))
                continue;

            if (IsFakeClient(target))
                continue;

            if (clientTeam != GetClientTeam(target))
                continue;

            targets[targetsCount++] = target;
        }

        TE_SetupBeamRingPoint(vBeamPos, g_fCvar_FieldStartRadius, g_fCvar_FieldEndRadius, g_iFieldModelIndex, 0, 0, 0, fieldDuration, g_fCvar_FieldWidth, g_fCvar_FieldAmplitude, color, 0, 0);
        TE_Send(targets, targetsCount);
    }

    if (g_bCvar_Sprite)
    {
        float vSpritePos[3];
        vSpritePos = vEndPos;
        vSpritePos[2] += g_fCvar_SpriteZAxis;

        char targetname[19];
        FormatEx(targetname, sizeof(targetname), "%s-%02i", "l4d_spot_marker", client);

        char color[12];
        if (g_bCvar_RandomSpriteColor)
        {
            if (g_bCvar_SyncRandomColor)
                FormatEx(color, sizeof(color), "%i %i %i", randomColor[0], randomColor[1], randomColor[2]);
            else
                FormatEx(color, sizeof(color), "%i %i %i", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
        }
        else
        {
            color = g_sCvar_SpriteColor;
        }

        int infoTarget = CreateEntityByName("info_target");
        DispatchKeyValue(infoTarget, "targetname", targetname);
        DispatchKeyValueVector(infoTarget, "origin", vSpritePos);
        DispatchSpawn(infoTarget);

        SetEntPropEnt(infoTarget, Prop_Send, "m_hOwnerEntity", client);

        SetVariantString(g_sKillInput);
        AcceptEntityInput(infoTarget, "AddOutput");
        AcceptEntityInput(infoTarget, "FireUser1");

        int sprite = CreateEntityByName("env_sprite");
        ge_iTeam[sprite] = clientTeam;
        DispatchKeyValue(sprite, "targetname", targetname);
        DispatchKeyValue(sprite, "spawnflags", "1");
        SDKHook(sprite, SDKHook_SetTransmit, OnSetTransmit);

        DispatchKeyValue(sprite, "model", g_sCvar_SpriteModel);
        DispatchKeyValue(sprite, "rendercolor", color);
        DispatchKeyValue(sprite, "renderamt", g_sCvar_SpriteAlpha); // If renderamt goes before rendercolor, it doesn't render
        DispatchKeyValue(sprite, "scale", g_sCvar_SpriteScale);
        DispatchKeyValue(sprite, "fademindist", g_sCvar_SpriteFadeDistance);
        DispatchKeyValueVector(sprite, "origin", vSpritePos);
        DispatchSpawn(sprite);

        SetVariantString("!activator");
        AcceptEntityInput(sprite, "SetParent", infoTarget); // We need parent the entity to an info_target, otherwise SetTransmit won't work

        SetEntPropEnt(sprite, Prop_Send, "m_hOwnerEntity", client);
        AcceptEntityInput(sprite, "ShowSprite");
        SetVariantString(g_sKillInput);
        AcceptEntityInput(sprite, "AddOutput");
        AcceptEntityInput(sprite, "FireUser1");

        if (g_bCvar_SpriteSpeed && g_bCvar_SpriteMinMax)
            CreateTimer(0.1, TimerMoveSprite, EntIndexToEntRef(sprite), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
}

/****************************************************************************************************/

Action TimerField(Handle timer, DataPack pack)
{
    int clientTeam;
    int direction;
    int color[4];
    float timeLimit;
    float vBeamPos[3];

    pack.Reset();
    clientTeam = pack.ReadCell();
    direction = pack.ReadCell();
    color[0] = pack.ReadCell();
    color[1] = pack.ReadCell();
    color[2] = pack.ReadCell();
    color[3] = pack.ReadCell();
    timeLimit = pack.ReadFloat();
    vBeamPos[0] = pack.ReadFloat();
    vBeamPos[1] = pack.ReadFloat();
    vBeamPos[2] = pack.ReadFloat();

    if (timeLimit < GetGameTime())
        return Plugin_Stop;

    float fieldDuration = (timeLimit - GetGameTime() < g_fCvar_FieldDuration ? timeLimit - GetGameTime() : g_fCvar_FieldDuration);

    if (fieldDuration < g_fBeamLife)
        fieldDuration = g_fBeamLife;

    int[] targets = new int[MaxClients];
    int targetsCount;

    for (int target = 1; target <= MaxClients; target++)
    {
        if (!IsClientInGame(target))
            continue;

        if (IsFakeClient(target))
            continue;

        if (clientTeam != GetClientTeam(target))
            continue;

        targets[targetsCount++] = target;
    }

    switch (direction)
    {
        case DIRECTION_OUT:
        {
            direction = DIRECTION_IN;
            TE_SetupBeamRingPoint(vBeamPos, g_fCvar_FieldStartRadius, g_fCvar_FieldEndRadius, g_iFieldModelIndex, 0, 0, 0, fieldDuration, g_fCvar_FieldWidth, g_fCvar_FieldAmplitude, color, 0, 0);
            TE_Send(targets, targetsCount);
        }
        case DIRECTION_IN:
        {
            direction = DIRECTION_OUT;
            TE_SetupBeamRingPoint(vBeamPos, g_fCvar_FieldEndRadius, g_fCvar_FieldStartRadius, g_iFieldModelIndex, 0, 0, 0, fieldDuration, g_fCvar_FieldWidth, g_fCvar_FieldAmplitude, color, 0, 0);
            TE_Send(targets, targetsCount);
        }
    }

    DataPack pack2;
    CreateDataTimer(g_fCvar_FieldRepeat, TimerField, pack2, TIMER_FLAG_NO_MAPCHANGE);
    pack2.WriteCell(clientTeam);
    pack2.WriteCell(direction);
    pack2.WriteCell(color[0]);
    pack2.WriteCell(color[1]);
    pack2.WriteCell(color[2]);
    pack2.WriteCell(color[3]);
    pack2.WriteFloat(timeLimit);
    pack2.WriteFloat(vBeamPos[0]);
    pack2.WriteFloat(vBeamPos[1]);
    pack2.WriteFloat(vBeamPos[2]);

    return Plugin_Stop;
}

/****************************************************************************************************/

Action TimerMoveSprite(Handle timer, int entityRef)
{
    if (!g_bCvar_Enabled)
        return Plugin_Stop;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return Plugin_Stop;

    float vPos[3];
    GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos); // Don't use m_vecAbsOrigin cause is parented

    if (ge_bMoveUp[entity])
    {
        vPos[2] += g_fCvar_SpriteSpeed;

        if (vPos[2] >= g_fCvar_SpriteMinMax)
            ge_bMoveUp[entity] = false;
    }
    else
    {
        vPos[2] -= g_fCvar_SpriteSpeed;

        if (vPos[2] <= -g_fCvar_SpriteMinMax)
            ge_bMoveUp[entity] = true;
    }

    TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

    return Plugin_Continue;
}

/****************************************************************************************************/

Action OnSetTransmit(int entity, int client)
{
    if (IsFakeClient(client))
        return Plugin_Handled;

    if (ge_iTeam[entity] != GetClientTeam(client))
        return Plugin_Handled;

    return Plugin_Continue;
}

/****************************************************************************************************/

bool TraceFilter(int entity, int contentsMask, int client)
{
    if (entity == client)
        return false;

    if (entity == ENTITY_WORLDSPAWN || IsValidClientIndex(entity))
        return true;

    return false;
}

/****************************************************************************************************/

Action TimerCooldown(Handle timer, int userid)
{
    if (!g_bCvar_Enabled)
        return Plugin_Stop;

    int client = GetClientOfUserId(userid);

    if (client == 0)
        return Plugin_Stop;

    if (g_bCvar_SkillReadySound)
        EmitSoundToClient(client, g_sCvar_SkillReadySound);

    if (g_iCvar_SkillReadyMsg & FLAG_MSG_DISPLAY_CHAT)
        CPrintToChat(client, "%t", "Skill Ready");

    if (g_iCvar_SkillReadyMsg & FLAG_MSG_DISPLAY_HINT)
        CPrintHintText(client, "%t", "Skill Ready");

    return Plugin_Stop;
}

/****************************************************************************************************/

Action TimerIntro(Handle timer, int userid)
{
    if (!g_bCvar_Enabled)
        return Plugin_Stop;

    int client = GetClientOfUserId(userid);

    if (client == 0)
        return Plugin_Stop;

    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
        return Plugin_Stop;

    if (g_iCvar_IntroMsg & FLAG_MSG_DISPLAY_CHAT)
        CPrintToChat(client, "%t", "Intro");

    if (g_iCvar_IntroMsg & FLAG_MSG_DISPLAY_HINT)
        CPrintHintText(client, "%t", "Intro");

    return Plugin_Stop;
}

// ====================================================================================================
// Player Commands
// ====================================================================================================
public Action SpotCmd(int client, int args)
{
	TryCreateSpotMarker(client);

	return Plugin_Handled;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdSpotMarker(int client, int args)
{
    int target_count;
    int target_list[MAXPLAYERS];

    if (args == 0) // self
    {
        if (IsValidClient(client))
        {
            target_count = 1;
            target_list[0] = client;
        }
    }
    else // specified target
    {
        char arg1[MAX_TARGET_LENGTH];
        GetCmdArg(1, arg1, sizeof(arg1));

        char target_name[MAX_TARGET_LENGTH];
        bool tn_is_ml;

        if ((target_count = ProcessTargetString(
            arg1,
            client,
            target_list,
            sizeof(target_list),
            COMMAND_FILTER_ALIVE,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
        {
            ReplyToTargetError(client, target_count);
        }
    }

    for (int i = 0; i < target_count; i++)
    {
        CreateSpotMarker(target_list[i]);
    }

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d_spot_marker) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_spot_marker_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_spot_marker_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_spot_marker_duration : %.1f", g_fCvar_Duration);
    PrintToConsole(client, "l4d_spot_marker_cooldown : %.1f", g_fCvar_Cooldown);
    PrintToConsole(client, "l4d_spot_marker_skill_ready_sound : \"%s\" (%s)", g_sCvar_SkillReadySound, g_bCvar_SkillReadySound ? "true" : "false");
    PrintToConsole(client, "l4d_spot_marker_use_sound : \"%s\" (%s)", g_sCvar_UseSound, g_bCvar_UseSound ? "true" : "false");
    PrintToConsole(client, "l4d_spot_marker_team : %i (SPECTATOR = %s | SURVIVOR = %s | INFECTED = %s | HOLDOUT = %s)", g_iCvar_Team,
    g_iCvar_Team & FLAG_TEAM_SPECTATOR ? "true" : "false", g_iCvar_Team & FLAG_TEAM_SURVIVOR ? "true" : "false", g_iCvar_Team & FLAG_TEAM_INFECTED ? "true" : "false", g_iCvar_Team & FLAG_TEAM_HOLDOUT ? "true" : "false");
    PrintToConsole(client, "l4d_spot_marker_alive : %b (%s)", g_bCvar_Alive, g_bCvar_Alive ? "true" : "false");
    PrintToConsole(client, "l4d_spot_marker_field : %b (%s)", g_bCvar_Field, g_bCvar_Field ? "true" : "false");
    PrintToConsole(client, "l4d_spot_marker_field_model : \"%s\"", g_sCvar_FieldModel);
    PrintToConsole(client, "l4d_spot_marker_field_color : \"%s\"", g_sCvar_FieldColor);
    PrintToConsole(client, "l4d_spot_marker_field_alpha : %i", g_iCvar_FieldAlpha);
    PrintToConsole(client, "l4d_spot_marker_field_duration : %.1f", g_fCvar_FieldDuration);
    PrintToConsole(client, "l4d_spot_marker_field_repeat : %.1f", g_fCvar_FieldRepeat);
    PrintToConsole(client, "l4d_spot_marker_field_start_radius : %.1f", g_fCvar_FieldStartRadius);
    PrintToConsole(client, "l4d_spot_marker_field_end_radius : %.1f", g_fCvar_FieldEndRadius);
    PrintToConsole(client, "l4d_spot_marker_field_width : %.1f", g_fCvar_FieldWidth);
    PrintToConsole(client, "l4d_spot_marker_field_amplitude : %.1f", g_fCvar_FieldAmplitude);
    PrintToConsole(client, "l4d_spot_marker_field_offset : %.1f", g_fCvar_FieldOffset);
    PrintToConsole(client, "l4d_spot_marker_sprite : %b (%s)", g_bCvar_Sprite, g_bCvar_Sprite ? "true" : "false");
    PrintToConsole(client, "l4d_spot_marker_sprite_z_axis : %.1f", g_fCvar_SpriteZAxis);
    PrintToConsole(client, "l4d_spot_marker_sprite_model : \"%s\"", g_sCvar_SpriteModel);
    PrintToConsole(client, "l4d_spot_marker_sprite_color : \"%s\"", g_sCvar_SpriteColor);
    PrintToConsole(client, "l4d_spot_marker_sprite_alpha : %i", g_iCvar_SpriteAlpha);
    PrintToConsole(client, "l4d_spot_marker_sprite_scale : %.1f", g_fCvar_SpriteScale);
    PrintToConsole(client, "l4d_spot_marker_sprite_fade_distance : %i", g_iCvar_SpriteFadeDistance);
    PrintToConsole(client, "l4d_spot_marker_sprite_speed : %.1f (%s)", g_fCvar_SpriteSpeed, g_bCvar_SpriteSpeed ? "true" : "false");
    PrintToConsole(client, "l4d_spot_marker_sprite_min_max : %.1f (%s)", g_fCvar_SpriteMinMax, g_bCvar_SpriteMinMax ? "true" : "false");
    PrintToConsole(client, "l4d_spot_marker_sync_random_color : %b (%s)", g_bCvar_SyncRandomColor, g_bCvar_SyncRandomColor ? "true" : "false");
    PrintToConsole(client, "l4d_spot_marker_color_per_client : %b (%s)", g_bCvar_ColorPerClient, g_bCvar_ColorPerClient ? "true" : "false");
    PrintToConsole(client, "l4d_spot_marker_intro : %.1f (%s)", g_fCvar_Intro, g_bCvar_Intro ? "true" : "false");
    PrintToConsole(client, "l4d_spot_marker_intro_msg : %i (CHAT: %s | HINT: %s)", g_iCvar_IntroMsg, g_iCvar_IntroMsg & FLAG_MSG_DISPLAY_CHAT ? "ON" : "OFF", g_iCvar_IntroMsg & FLAG_MSG_DISPLAY_HINT ? "ON" : "OFF");
    PrintToConsole(client, "l4d_spot_marker_skill_ready_msg : %i (CHAT: %s | HINT: %s)", g_iCvar_SkillReadyMsg, g_iCvar_SkillReadyMsg & FLAG_MSG_DISPLAY_CHAT ? "ON" : "OFF", g_iCvar_SkillReadyMsg & FLAG_MSG_DISPLAY_HINT ? "ON" : "OFF");
    PrintToConsole(client, "l4d_spot_marker_spot_marked_msg : %i (CHAT: %s | HINT: %s)", g_iCvar_SpotMarkedMsg, g_iCvar_SpotMarkedMsg & FLAG_MSG_DISPLAY_CHAT ? "ON" : "OFF", g_iCvar_SpotMarkedMsg & FLAG_MSG_DISPLAY_HINT ? "ON" : "OFF");
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
void CPrintToChat(int client, char[] message, any ...)
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

/****************************************************************************************************/

/**
 * Prints a message to a specific client in the hint area.
 * Remove color tags.
 *
 * @param client        Client index.
 * @param message       Message (formatting rules).
 *
 * On error/Errors:     If the client is not connected an error will be thrown.
 */
void CPrintHintText(int client, char[] message, any ...)
{
    char buffer[512];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), message, 3);

    ReplaceString(buffer, sizeof(buffer), "{default}", "");
    ReplaceString(buffer, sizeof(buffer), "{white}", "");
    ReplaceString(buffer, sizeof(buffer), "{cyan}", "");
    ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "");
    ReplaceString(buffer, sizeof(buffer), "{orange}", "");
    ReplaceString(buffer, sizeof(buffer), "{green}", "");
    ReplaceString(buffer, sizeof(buffer), "{olive}", "");

    ReplaceString(buffer, sizeof(buffer), "\x01", ""); // Default
    ReplaceString(buffer, sizeof(buffer), "\x03", ""); // Light Green
    ReplaceString(buffer, sizeof(buffer), "\x04", ""); // Orange
    ReplaceString(buffer, sizeof(buffer), "\x05", ""); // Olive

    PrintHintText(client, buffer);
}