/**
// ====================================================================================================
Change Log:

1.0.2 (01-May-2021)
    - Added support to special characters in static HUD texts through a data file. (thanks "Voevoda" for requesting)
    - Added a required file at data folder.

1.0.1 (13-March-2021)
    - Added cvars to make the next animated. (thanks "Source" for requesting)
    - Increased some cvars min/max bounds to fit more screen resolutions.

1.0.0 (10-March-2021)
    - Initial release.

// ====================================================================================================
*/

/**
// ====================================================================================================
More info about HUD can be found here:
https://developer.valvesoftware.com/wiki/L4D2_EMS/Appendix:_HUD
// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Scripted HUD"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Display text for up to 4 scripted HUD slots on the screen"
#define PLUGIN_VERSION                "1.0.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=331212"

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
#include <basecomm>
#include <left4dhooks>

//#define REQUIRE_PLUGIN
#undef REQUIRE_PLUGIN
#include <witch_and_tankifier>

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
#define CONFIG_FILENAME               "l4d2_scripted_hud"
#define DATA_FILENAME                 "l4d2_scripted_hud"

// ====================================================================================================
// Defines
// ====================================================================================================
#define HUD1                          0
#define HUD2                          1
#define HUD3                          2
#define HUD4                          3

#define HUD_LEFT_TOP                  0
#define HUD_LEFT_BOT                  1
#define HUD_MID_TOP                   2
#define HUD_MID_BOT                   3
// #define HUD_RIGHT_TOP                 4
// #define HUD_RIGHT_BOT                 5
// #define HUD_TICKER                    6
// #define HUD_FAR_LEFT                  7
// #define HUD_FAR_RIGHT                 8
// #define HUD_MID_BOX                   9
// #define HUD_SCORE_TITLE               10
// #define HUD_SCORE_1                   11
// #define HUD_SCORE_2                   12
// #define HUD_SCORE_3                   13
// #define HUD_SCORE_4                   14

#define HUD_FLAG_NONE                 0     // no flag
#define HUD_FLAG_PRESTR               1     // do you want a string/value pair to start(pre) with the static string (default is PRE)
#define HUD_FLAG_POSTSTR              2     // do you want a string/value pair to end(post) with the static string
#define HUD_FLAG_BEEP                 4     // Makes a countdown timer blink
#define HUD_FLAG_BLINK                8     // do you want this field to be blinking
#define HUD_FLAG_AS_TIME              16    // ?
#define HUD_FLAG_COUNTDOWN_WARN       32    // auto blink when the timer gets under 10 seconds
#define HUD_FLAG_NOBG                 64    // dont draw the background box for this UI element
#define HUD_FLAG_ALLOWNEGTIMER        128   // by default Timers stop on 0:00 to avoid briefly going negative over network, this keeps that from happening
#define HUD_FLAG_ALIGN_LEFT           256   // Left justify this text
#define HUD_FLAG_ALIGN_CENTER         512   // Center justify this text
#define HUD_FLAG_ALIGN_RIGHT          768   // Right justify this text
#define HUD_FLAG_TEAM_SURVIVORS       1024  // only show to the survivor team
#define HUD_FLAG_TEAM_INFECTED        2048  // only show to the special infected team
#define HUD_FLAG_TEAM_MASK            3072  // ?
#define HUD_FLAG_UNKNOWN1             4096  // ?
#define HUD_FLAG_TEXT                 8192  // ?
#define HUD_FLAG_NOTVISIBLE           16384 // if you want to keep the slot data but keep it from displaying

#define HUD_TEAM_ALL                  0
#define HUD_TEAM_SURVIVOR             1
#define HUD_TEAM_INFECTED             2

#define HUD_TEXT_ALIGN_LEFT           1
#define HUD_TEXT_ALIGN_CENTER         2
#define HUD_TEXT_ALIGN_RIGHT          3

#define HUD_X_LEFT_TO_RIGHT           0
#define HUD_X_RIGHT_TO_LEFT           1

#define HUD_Y_TOP_TO_BOTTOM           0
#define HUD_Y_BOTTOM_TO_TOP           1

#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3

#define L4D2_ZOMBIECLASS_SMOKER       1
#define L4D2_ZOMBIECLASS_BOOMER       2
#define L4D2_ZOMBIECLASS_HUNTER       3
#define L4D2_ZOMBIECLASS_SPITTER      4
#define L4D2_ZOMBIECLASS_JOCKEY       5
#define L4D2_ZOMBIECLASS_CHARGER      6
#define L4D2_ZOMBIECLASS_TANK         8

// ====================================================================================================
// Native Cvars
// ====================================================================================================
static ConVar g_hCvar_pain_pills_decay_rate;

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_UpdateInterval;
ConVar g_hVsBossBuffer;
static ConVar g_hCvar_HUD1_Text;
static ConVar g_hCvar_HUD1_TextAlign;
static ConVar g_hCvar_HUD1_BlinkTank;
static ConVar g_hCvar_HUD1_Blink;
static ConVar g_hCvar_HUD1_Beep;
static ConVar g_hCvar_HUD1_Visible;
static ConVar g_hCvar_HUD1_Background;
static ConVar g_hCvar_HUD1_Team;
static ConVar g_hCvar_HUD1_Flag_Debug;
static ConVar g_hCvar_HUD1_X;
static ConVar g_hCvar_HUD1_Y;
static ConVar g_hCvar_HUD1_X_Speed;
static ConVar g_hCvar_HUD1_Y_Speed;
static ConVar g_hCvar_HUD1_X_Direction;
static ConVar g_hCvar_HUD1_Y_Direction;
static ConVar g_hCvar_HUD1_X_Min;
static ConVar g_hCvar_HUD1_Y_Min;
static ConVar g_hCvar_HUD1_X_Max;
static ConVar g_hCvar_HUD1_Y_Max;
static ConVar g_hCvar_HUD1_Width;
static ConVar g_hCvar_HUD1_Height;

static ConVar g_hCvar_HUD2_Text;
static ConVar g_hCvar_HUD2_TextAlign;
static ConVar g_hCvar_HUD2_BlinkTank;
static ConVar g_hCvar_HUD2_Blink;
static ConVar g_hCvar_HUD2_Beep;
static ConVar g_hCvar_HUD2_Visible;
static ConVar g_hCvar_HUD2_Background;
static ConVar g_hCvar_HUD2_Team;
static ConVar g_hCvar_HUD2_Flag_Debug;
static ConVar g_hCvar_HUD2_X;
static ConVar g_hCvar_HUD2_Y;
static ConVar g_hCvar_HUD2_X_Speed;
static ConVar g_hCvar_HUD2_Y_Speed;
static ConVar g_hCvar_HUD2_X_Direction;
static ConVar g_hCvar_HUD2_Y_Direction;
static ConVar g_hCvar_HUD2_X_Min;
static ConVar g_hCvar_HUD2_Y_Min;
static ConVar g_hCvar_HUD2_X_Max;
static ConVar g_hCvar_HUD2_Y_Max;
static ConVar g_hCvar_HUD2_Width;
static ConVar g_hCvar_HUD2_Height;

static ConVar g_hCvar_HUD3_Text;
static ConVar g_hCvar_HUD3_TextAlign;
static ConVar g_hCvar_HUD3_BlinkTank;
static ConVar g_hCvar_HUD3_Blink;
static ConVar g_hCvar_HUD3_Beep;
static ConVar g_hCvar_HUD3_Visible;
static ConVar g_hCvar_HUD3_Background;
static ConVar g_hCvar_HUD3_Team;
static ConVar g_hCvar_HUD3_Flag_Debug;
static ConVar g_hCvar_HUD3_X;
static ConVar g_hCvar_HUD3_Y;
static ConVar g_hCvar_HUD3_X_Speed;
static ConVar g_hCvar_HUD3_Y_Speed;
static ConVar g_hCvar_HUD3_X_Direction;
static ConVar g_hCvar_HUD3_Y_Direction;
static ConVar g_hCvar_HUD3_X_Min;
static ConVar g_hCvar_HUD3_Y_Min;
static ConVar g_hCvar_HUD3_X_Max;
static ConVar g_hCvar_HUD3_Y_Max;
static ConVar g_hCvar_HUD3_Width;
static ConVar g_hCvar_HUD3_Height;

static ConVar g_hCvar_HUD4_Text;
static ConVar g_hCvar_HUD4_TextAlign;
static ConVar g_hCvar_HUD4_BlinkTank;
static ConVar g_hCvar_HUD4_Blink;
static ConVar g_hCvar_HUD4_Beep;
static ConVar g_hCvar_HUD4_Visible;
static ConVar g_hCvar_HUD4_Background;
static ConVar g_hCvar_HUD4_Team;
static ConVar g_hCvar_HUD4_Flag_Debug;
static ConVar g_hCvar_HUD4_X;
static ConVar g_hCvar_HUD4_Y;
static ConVar g_hCvar_HUD4_X_Speed;
static ConVar g_hCvar_HUD4_Y_Speed;
static ConVar g_hCvar_HUD4_X_Direction;
static ConVar g_hCvar_HUD4_Y_Direction;
static ConVar g_hCvar_HUD4_X_Min;
static ConVar g_hCvar_HUD4_Y_Min;
static ConVar g_hCvar_HUD4_X_Max;
static ConVar g_hCvar_HUD4_Y_Max;
static ConVar g_hCvar_HUD4_Width;
static ConVar g_hCvar_HUD4_Height;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bEventsHooked;
static bool   g_bAliveTank;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_HUD1_BlinkTank;
static bool   g_bCvar_HUD1_Blink;
static bool   g_bCvar_HUD1_Beep;
static bool   g_bCvar_HUD1_Visible;
static bool   g_bCvar_HUD1_Background;
static bool   g_bCvar_HUD1_Flag_Debug;
static bool   g_bCvar_HUD1_X_Speed;
static bool   g_bCvar_HUD1_Y_Speed;
static bool   g_bCvar_HUD2_BlinkTank;
static bool   g_bCvar_HUD2_Blink;
static bool   g_bCvar_HUD2_Beep;
static bool   g_bCvar_HUD2_Visible;
static bool   g_bCvar_HUD2_Background;
static bool   g_bCvar_HUD2_Flag_Debug;
static bool   g_bCvar_HUD2_X_Speed;
static bool   g_bCvar_HUD2_Y_Speed;
static bool   g_bCvar_HUD3_BlinkTank;
static bool   g_bCvar_HUD3_Blink;
static bool   g_bCvar_HUD3_Beep;
static bool   g_bCvar_HUD3_Visible;
static bool   g_bCvar_HUD3_Background;
static bool   g_bCvar_HUD3_Flag_Debug;
static bool   g_bCvar_HUD3_X_Speed;
static bool   g_bCvar_HUD3_Y_Speed;
static bool   g_bCvar_HUD4_BlinkTank;
static bool   g_bCvar_HUD4_Blink;
static bool   g_bCvar_HUD4_Beep;
static bool   g_bCvar_HUD4_Visible;
static bool   g_bCvar_HUD4_Background;
static bool   g_bCvar_HUD4_Flag_Debug;
static bool   g_bCvar_HUD4_X_Speed;
static bool   g_bCvar_HUD4_Y_Speed;
static bool   g_bCvar_HUD1_Text;
static bool   g_bCvar_HUD2_Text;
static bool   g_bCvar_HUD3_Text;
static bool   g_bCvar_HUD4_Text;
static bool   g_bCvar_BlinkTank;
static bool   g_bData_HUD1_Text;
static bool   g_bData_HUD2_Text;
static bool   g_bData_HUD3_Text;
static bool   g_bData_HUD4_Text;
bool g_bWitchAndTankSystemAvailable = false;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iCvar_HUD1_TextAlign;
static int    g_iCvar_HUD1_Team;
static int    g_iCvar_HUD1_X_Direction;
static int    g_iCvar_HUD1_Y_Direction;
static int    g_iCvar_HUD1_Flag_Debug;
static int    g_iCvar_HUD2_TextAlign;
static int    g_iCvar_HUD2_Team;
static int    g_iCvar_HUD2_Flag_Debug;
static int    g_iCvar_HUD2_X_Direction;
static int    g_iCvar_HUD2_Y_Direction;
static int    g_iCvar_HUD3_TextAlign;
static int    g_iCvar_HUD3_Team;
static int    g_iCvar_HUD3_Flag_Debug;
static int    g_iCvar_HUD3_X_Direction;
static int    g_iCvar_HUD3_Y_Direction;
static int    g_iCvar_HUD4_TextAlign;
static int    g_iCvar_HUD4_Team;
static int    g_iCvar_HUD4_Flag_Debug;
static int    g_iCvar_HUD4_X_Direction;
static int    g_iCvar_HUD4_Y_Direction;
static int    g_iHUD1Flags;
static int    g_iHUD2Flags;
static int    g_iHUD3Flags;
static int    g_iHUD4Flags;
static int    g_iPlayerNum;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_pain_pills_decay_rate;
static float  g_fCvar_UpdateInterval;
static float  g_fCvar_HUD1_X;
static float  g_fCvar_HUD1_Y;
static float  g_fCvar_HUD1_X_Speed;
static float  g_fCvar_HUD1_Y_Speed;
static float  g_fCvar_HUD1_X_Min;
static float  g_fCvar_HUD1_Y_Min;
static float  g_fCvar_HUD1_X_Max;
static float  g_fCvar_HUD1_Y_Max;
static float  g_fCvar_HUD1_Width;
static float  g_fCvar_HUD1_Height;
static float  g_fCvar_HUD2_X;
static float  g_fCvar_HUD2_Y;
static float  g_fCvar_HUD2_X_Speed;
static float  g_fCvar_HUD2_Y_Speed;
static float  g_fCvar_HUD2_X_Min;
static float  g_fCvar_HUD2_Y_Min;
static float  g_fCvar_HUD2_X_Max;
static float  g_fCvar_HUD2_Y_Max;
static float  g_fCvar_HUD2_Width;
static float  g_fCvar_HUD2_Height;
static float  g_fCvar_HUD3_X;
static float  g_fCvar_HUD3_Y;
static float  g_fCvar_HUD3_X_Speed;
static float  g_fCvar_HUD3_Y_Speed;
static float  g_fCvar_HUD3_X_Min;
static float  g_fCvar_HUD3_Y_Min;
static float  g_fCvar_HUD3_X_Max;
static float  g_fCvar_HUD3_Y_Max;
static float  g_fCvar_HUD3_Width;
static float  g_fCvar_HUD3_Height;
static float  g_fCvar_HUD4_X;
static float  g_fCvar_HUD4_Y;
static float  g_fCvar_HUD4_X_Speed;
static float  g_fCvar_HUD4_Y_Speed;
static float  g_fCvar_HUD4_X_Min;
static float  g_fCvar_HUD4_Y_Min;
static float  g_fCvar_HUD4_X_Max;
static float  g_fCvar_HUD4_Y_Max;
static float  g_fCvar_HUD4_Width;
static float  g_fCvar_HUD4_Height;
static float  g_fHUD1_X;
static float  g_fHUD1_Y;
static float  g_fHUD2_X;
static float  g_fHUD2_Y;
static float  g_fHUD3_X;
static float  g_fHUD3_Y;
static float  g_fHUD4_X;
static float  g_fHUD4_Y;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
static char   g_sCvar_HUD1_Text[128];
static char   g_sCvar_HUD2_Text[128];
static char   g_sCvar_HUD3_Text[128];
static char   g_sCvar_HUD4_Text[128];
static char   g_sData_HUD1_Text[128];
static char   g_sData_HUD2_Text[128];
static char   g_sData_HUD3_Text[128];
static char   g_sData_HUD4_Text[128];
static char   g_sHUD1_Text[128];
static char   g_sHUD2_Text[128];
static char   g_sHUD3_Text[128];
static char   g_sHUD4_Text[128];
static char   g_sHUD_Text[512];
static char   g_sHUD_TextArray[4][128];
static char   g_sBuffer[128];
static char   g_sSpaces[128] = "                                                                                                                               ";

// ====================================================================================================
// Timer - Plugin Variables
// ====================================================================================================
Handle g_tUpdateInterval;

/****************************************************************************************************/

// ====================================================================================================
// VoiceHook extension - uncomment if you have SM1.10 and the extension and want to show up who is speaking at the hud.
// You can download it here: https://github.com/Accelerator74/VoiceHook/releases
// Requires MetaMod 1.11: https://www.sourcemm.net/downloads.php/?branch=1.11-dev&all=1
// For SM1.11+ is not necessary, cause its already a native.
// Note: Don't forget to uncomment the inner code too on GetHUD4_Text method.
// ====================================================================================================
// public Extension __ext_voice =
// {
    // name = "voicehook",
    // file = "voicehook.ext",
    // autoload = 1,
    // required = 1
// }

// native bool IsClientSpeaking(int client);

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
    LoadPluginData();

    g_hCvar_pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");

    CreateConVar("l4d2_scripted_hud_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled          = CreateConVar("l4d2_scripted_hud_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_UpdateInterval   = CreateConVar("l4d2_scripted_hud_update_interval", "0.1", "Interval in seconds to update the HUD.", CVAR_FLAGS, true, 0.1);
    g_hCvar_HUD1_Text        = CreateConVar("l4d2_scripted_hud_hud1_text", "", "The text you want to display in the HUD.\nNote: When cvar is empty \"\", plugin will use the predefined HUD text set in the code, check GetHUD*_Text functions.", CVAR_FLAGS);
    g_hCvar_HUD1_TextAlign   = CreateConVar("l4d2_scripted_hud_hud1_text_align", "1", "Aligns the text horizontally.\n1 = LEFT, 2 = CENTER, 3 = RIGHT.", CVAR_FLAGS, true, 1.0, true, 3.0);
    g_hCvar_HUD1_BlinkTank   = CreateConVar("l4d2_scripted_hud_hud1_blink_tank", "1", "Makes the text blink from white to red while a tank is alive.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD1_Blink       = CreateConVar("l4d2_scripted_hud_hud1_blink", "0", "Makes the text blink from white to red.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD1_Beep        = CreateConVar("l4d2_scripted_hud_hud1_beep", "0", "Makes the text play a beep sound while blinking.\n0 = OFF, 1 = ON. Note: the blink cvar must be \"1\" to play the beep sound.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD1_Visible     = CreateConVar("l4d2_scripted_hud_hud1_visible", "1", "Makes the text visible.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD1_Background  = CreateConVar("l4d2_scripted_hud_hud1_background", "0", "Shows the text inside a black transparent background.\nNote: the background may not draw properly when initialized as \"0\", start the map with \"1\" to render properly.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD1_Team        = CreateConVar("l4d2_scripted_hud_hud1_team", "0", "Which team should see the text.\n0 = ALL, 1 = SURVIVOR, 2 = INFECTED.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD1_Flag_Debug  = CreateConVar("l4d2_scripted_hud_hud1_flag_debug", "0", "Overwrite the HUD flag.\nFor debug purposes only.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 32767.0);
    g_hCvar_HUD1_X           = CreateConVar("l4d2_scripted_hud_hud1_x", "0.05", "X (horizontal) position of the text.\nNote: setting it to less than 0.0 may cut/hide the text at screen.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD1_Y           = CreateConVar("l4d2_scripted_hud_hud1_y", "0.0", "Y (vertical) position of the text.\nNote: setting it to less than 0.0 may cut/hide the text at screen.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD1_X_Speed     = CreateConVar("l4d2_scripted_hud_hud1_x_speed", "0.0", "Animated X (horizontal) movement speed of the text.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD1_Y_Speed     = CreateConVar("l4d2_scripted_hud_hud1_y_speed", "0.0", "Animated Y (vertical) movement speed of the text.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD1_X_Direction = CreateConVar("l4d2_scripted_hud_hud1_x_direction", "0", "Animated X (horizontal) direction that the text will move.\n0 = Right to Left, 1 = Left to Right.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD1_Y_Direction = CreateConVar("l4d2_scripted_hud_hud1_y_direction", "0", "Animated Y (vertical) direction that the text will move.\n0 = Top to Bottom, 1 = Bottom to Top.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD1_X_Min       = CreateConVar("l4d2_scripted_hud_hud1_x_min", "0.0", "Animated X (horizontal) minimum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD1_Y_Min       = CreateConVar("l4d2_scripted_hud_hud1_y_min", "0.0", "Animated Y (vertical) minimum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD1_X_Max       = CreateConVar("l4d2_scripted_hud_hud1_x_max", "1.0", "Animated X (horizontal) maximum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD1_Y_Max       = CreateConVar("l4d2_scripted_hud_hud1_y_max", "1.0", "Animated Y (vertical) maximum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD1_Width       = CreateConVar("l4d2_scripted_hud_hud1_width", "1.0", "Text area Width.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD1_Height      = CreateConVar("l4d2_scripted_hud_hud1_height", "0.026", "Text area Height.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD2_Text        = CreateConVar("l4d2_scripted_hud_hud2_text", "", "The text you want to display in the HUD.\nNote: When cvar is empty \"\", plugin will use the predefined HUD text set in the code, check GetHUD*_Text functions.", CVAR_FLAGS);
    g_hCvar_HUD2_TextAlign   = CreateConVar("l4d2_scripted_hud_hud2_text_align", "1", "Aligns the text horizontally.\n1 = LEFT, 2 = CENTER, 3 = RIGHT.", CVAR_FLAGS, true, 1.0, true, 3.0);
    g_hCvar_HUD2_BlinkTank   = CreateConVar("l4d2_scripted_hud_hud2_blink_tank", "0", "Makes the text blink from white to red while a tank is alive.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD2_Blink       = CreateConVar("l4d2_scripted_hud_hud2_blink", "0", "Makes the text blink from white to red.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD2_Beep        = CreateConVar("l4d2_scripted_hud_hud2_beep", "0", "Makes the text play a beep sound while blinking.\n0 = OFF, 1 = ON. Note: the blink cvar must be \"1\" to play the beep sound.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD2_Visible     = CreateConVar("l4d2_scripted_hud_hud2_visible", "1", "Makes the text visible.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD2_Background  = CreateConVar("l4d2_scripted_hud_hud2_background", "0", "Shows the text inside a black transparent background.\nNote: the background may not draw properly when initialized as \"0\", start the map with \"1\" to render properly.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD2_Team        = CreateConVar("l4d2_scripted_hud_hud2_team", "0", "Which team should see the text.\n0 = ALL, 1 = SURVIVOR, 2 = INFECTED.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD2_Flag_Debug  = CreateConVar("l4d2_scripted_hud_hud2_flag_debug", "0", "Overwrite the HUD flag.\nFor debug purposes only.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 32767.0);
    g_hCvar_HUD2_X           = CreateConVar("l4d2_scripted_hud_hud2_x", "0.65", "X (horizontal) position of the text.\nNote: setting it to less than 0.0 may cut/hide the text at screen.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD2_Y           = CreateConVar("l4d2_scripted_hud_hud2_y", "0.00", "Y (vertical) position of the text.\nNote: setting it to less than 0.0 may cut/hide the text at screen.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD2_X_Speed     = CreateConVar("l4d2_scripted_hud_hud2_x_speed", "0.0", "Animated X (horizontal) movement speed of the text.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD2_Y_Speed     = CreateConVar("l4d2_scripted_hud_hud2_y_speed", "0.0", "Animated Y (vertical) movement speed of the text.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD2_X_Direction = CreateConVar("l4d2_scripted_hud_hud2_x_direction", "0", "Animated X (horizontal) direction that the text will move.\n0 = Left to Right, 1 = Right to Left.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD2_Y_Direction = CreateConVar("l4d2_scripted_hud_hud2_y_direction", "0", "Animated Y (vertical) direction that the text will move.\n0 = Top to Bottom, 1 = Bottom to Top.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD2_X_Min       = CreateConVar("l4d2_scripted_hud_hud2_x_min", "0.0", "Animated X (horizontal) minimum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD2_Y_Min       = CreateConVar("l4d2_scripted_hud_hud2_y_min", "0.0", "Animated Y (vertical) minimum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD2_X_Max       = CreateConVar("l4d2_scripted_hud_hud2_x_max", "1.0", "Animated X (horizontal) maximum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD2_Y_Max       = CreateConVar("l4d2_scripted_hud_hud2_y_max", "1.0", "Animated Y (vertical) maximum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD2_Width       = CreateConVar("l4d2_scripted_hud_hud2_width", "1.0", "Text area Width.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD2_Height      = CreateConVar("l4d2_scripted_hud_hud2_height", "0.026", "Text area Height.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD3_Text        = CreateConVar("l4d2_scripted_hud_hud3_text", "", "The text you want to display in the HUD.\nNote: When cvar is empty \"\", plugin will use the predefined HUD text set in the code, check GetHUD*_Text functions.", CVAR_FLAGS);
    g_hCvar_HUD3_TextAlign   = CreateConVar("l4d2_scripted_hud_hud3_text_align", "1", "Aligns the text horizontally.\n1 = LEFT, 2 = CENTER, 3 = RIGHT.", CVAR_FLAGS, true, 1.0, true, 3.0);
    g_hCvar_HUD3_BlinkTank   = CreateConVar("l4d2_scripted_hud_hud3_blink_tank", "0", "Makes the text blink from white to red while a tank is alive.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD3_Blink       = CreateConVar("l4d2_scripted_hud_hud3_blink", "0", "Makes the text blink from white to red.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD3_Beep        = CreateConVar("l4d2_scripted_hud_hud3_beep", "0", "Makes the text play a beep sound while blinking.\n0 = OFF, 1 = ON. Note: the blink cvar must be \"1\" to play the beep sound.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD3_Visible     = CreateConVar("l4d2_scripted_hud_hud3_visible", "0", "Makes the text visible.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD3_Background  = CreateConVar("l4d2_scripted_hud_hud3_background", "0", "Shows the text inside a black transparent background.\nNote: the background may not draw properly when initialized as \"0\", start the map with \"1\" to render properly.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD3_Team        = CreateConVar("l4d2_scripted_hud_hud3_team", "2", "Which team should see the text.\n0 = ALL, 1 = SURVIVOR, 2 = INFECTED.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD3_Flag_Debug  = CreateConVar("l4d2_scripted_hud_hud3_flag_debug", "0", "Overwrite the HUD flag.\nFor debug purposes only.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 32767.0);
    g_hCvar_HUD3_X           = CreateConVar("l4d2_scripted_hud_hud3_x", "0.8", "X (horizontal) position of the text.\nNote: setting it to less than 0.0 may cut/hide the text at screen.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD3_Y           = CreateConVar("l4d2_scripted_hud_hud3_y", "0.11", "Y (vertical) position of the text.\nNote: setting it to less than 0.0 may cut/hide the text at screen.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD3_X_Speed     = CreateConVar("l4d2_scripted_hud_hud3_x_speed", "0.0", "Animated X (horizontal) movement speed of the text.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD3_Y_Speed     = CreateConVar("l4d2_scripted_hud_hud3_y_speed", "0.0", "Animated Y (vertical) movement speed of the text.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD3_X_Direction = CreateConVar("l4d2_scripted_hud_hud3_x_direction", "0", "Animated X (horizontal) direction that the text will move.\n0 = Left to Right, 1 = Right to Left.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD3_Y_Direction = CreateConVar("l4d2_scripted_hud_hud3_y_direction", "0", "Animated Y (vertical) direction that the text will move.\n0 = Top to Bottom, 1 = Bottom to Top.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD3_X_Min       = CreateConVar("l4d2_scripted_hud_hud3_x_min", "0.0", "Animated X (horizontal) minimum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD3_Y_Min       = CreateConVar("l4d2_scripted_hud_hud3_y_min", "0.0", "Animated Y (vertical) minimum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD3_X_Max       = CreateConVar("l4d2_scripted_hud_hud3_x_max", "1.0", "Animated X (horizontal) maximum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD3_Y_Max       = CreateConVar("l4d2_scripted_hud_hud3_y_max", "1.0", "Animated Y (vertical) maximum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD3_Width       = CreateConVar("l4d2_scripted_hud_hud3_width", "1.5", "Text area Width.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD3_Height      = CreateConVar("l4d2_scripted_hud_hud3_height", "0.026", "Text area Height.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD4_Text        = CreateConVar("l4d2_scripted_hud_hud4_text", "", "The text you want to display in the HUD.\nNote: When cvar is empty \"\", plugin will use the predefined HUD text set in the code, check GetHUD*_Text functions.", CVAR_FLAGS);
    g_hCvar_HUD4_TextAlign   = CreateConVar("l4d2_scripted_hud_hud4_text_align", "1", "Aligns the text horizontally.\n1 = LEFT, 2 = CENTER, 3 = RIGHT.", CVAR_FLAGS, true, 1.0, true, 3.0);
    g_hCvar_HUD4_BlinkTank   = CreateConVar("l4d2_scripted_hud_hud4_blink_tank", "1", "Makes the text blink from white to red while a tank is alive.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD4_Blink       = CreateConVar("l4d2_scripted_hud_hud4_blink", "0", "Makes the text blink from white to red.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD4_Beep        = CreateConVar("l4d2_scripted_hud_hud4_beep", "0", "Makes the text play a beep sound while blinking.\n0 = OFF, 1 = ON. Note: the blink cvar must be \"1\" to play the beep sound.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD4_Visible     = CreateConVar("l4d2_scripted_hud_hud4_visible", "0", "Makes the text visible.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD4_Background  = CreateConVar("l4d2_scripted_hud_hud4_background", "0", "Shows the text inside a black transparent background.\nNote: the background may not draw properly when initialized as \"0\", start the map with \"1\" to render properly.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD4_Team        = CreateConVar("l4d2_scripted_hud_hud4_team", "0", "Which team should see the text.\n0 = ALL, 1 = SURVIVOR, 2 = INFECTED.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD4_Flag_Debug  = CreateConVar("l4d2_scripted_hud_hud4_flag_debug", "0", "Overwrite the HUD flag.\nFor debug purposes only.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 32767.0);
    g_hCvar_HUD4_X           = CreateConVar("l4d2_scripted_hud_hud4_x", "0.75", "X (horizontal) position of the text.\nNote: setting it to less than 0.0 may cut/hide the text at screen.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD4_Y           = CreateConVar("l4d2_scripted_hud_hud4_y", "0.35", "Y (vertical) position of the text.\nNote: setting it to less than 0.0 may cut/hide the text at screen.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD4_X_Speed     = CreateConVar("l4d2_scripted_hud_hud4_x_speed", "0.0", "Animated X (horizontal) movement speed of the text.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD4_Y_Speed     = CreateConVar("l4d2_scripted_hud_hud4_y_speed", "0.0", "Animated Y (vertical) movement speed of the text.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD4_X_Direction = CreateConVar("l4d2_scripted_hud_hud4_x_direction", "0", "Animated X (horizontal) direction that the text will move.\n0 = Left to Right, 1 = Right to Left.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD4_Y_Direction = CreateConVar("l4d2_scripted_hud_hud4_y_direction", "0", "Animated Y (vertical) direction that the text will move.\n0 = Top to Bottom, 1 = Bottom to Top.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HUD4_X_Min       = CreateConVar("l4d2_scripted_hud_hud4_x_min", "0.0", "Animated X (horizontal) minimum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD4_Y_Min       = CreateConVar("l4d2_scripted_hud_hud4_y_min", "0.0", "Animated Y (vertical) minimum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD4_X_Max       = CreateConVar("l4d2_scripted_hud_hud4_x_max", "1.0", "Animated X (horizontal) maximum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD4_Y_Max       = CreateConVar("l4d2_scripted_hud_hud4_y_max", "1.0", "Animated Y (vertical) maximum position that the HUD can reach.", CVAR_FLAGS, true, -1.0, true, 1.0);
    g_hCvar_HUD4_Width       = CreateConVar("l4d2_scripted_hud_hud4_width", "1.5", "Text area Width.", CVAR_FLAGS, true, 0.0, true, 2.0);
    g_hCvar_HUD4_Height      = CreateConVar("l4d2_scripted_hud_hud4_height", "0.026", "Text area Height.", CVAR_FLAGS, true, 0.0, true, 2.0);	
    g_hVsBossBuffer 		 = FindConVar("versus_boss_buffer");
    
    // Hook plugin ConVars change
    g_hCvar_pain_pills_decay_rate.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_UpdateInterval.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_Text.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_TextAlign.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_BlinkTank.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_Blink.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_Beep.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_Visible.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_Background.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_Team.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_Flag_Debug.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_X.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_Y.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_X_Speed.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_Y_Speed.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_X_Direction.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_Y_Direction.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_X_Min.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_Y_Min.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_X_Max.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_Y_Max.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_Width.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD1_Height.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_Text.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_TextAlign.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_BlinkTank.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_Blink.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_Beep.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_Visible.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_Background.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_Team.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_Flag_Debug.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_X.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_Y.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_X_Speed.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_Y_Speed.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_X_Direction.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_Y_Direction.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_X_Min.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_Y_Min.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_X_Max.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_Y_Max.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_Width.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD2_Height.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_Text.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_TextAlign.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_BlinkTank.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_Blink.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_Beep.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_Visible.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_Background.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_Team.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_Flag_Debug.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_X.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_Y.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_X_Speed.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_Y_Speed.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_X_Direction.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_Y_Direction.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_X_Min.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_Y_Min.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_X_Max.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_Y_Max.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_Width.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD3_Height.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_Text.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_TextAlign.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_BlinkTank.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_Blink.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_Beep.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_Visible.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_Background.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_Team.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_Flag_Debug.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_X.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_Y.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_X_Speed.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_Y_Speed.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_X_Direction.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_Y_Direction.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_X_Min.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_Y_Min.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_X_Max.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_Y_Max.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_Width.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HUD4_Height.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    //AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_l4d2_scripted_hud_reload_data", CmdReloadData, ADMFLAG_ROOT, "Reload the HUD texts set in the data file.");
    RegAdminCmd("sm_print_cvars_l4d2_scripted_hud", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
    RegConsoleCmd("sm_spechudon", ShowSpecHud, "打开spechud");
    RegConsoleCmd("sm_spechudoff", offSpecHud, "打开spechud");
}

/****************************************************************************************************/

public void LoadPluginData()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "data/%s.cfg", DATA_FILENAME);

    if (!FileExists(path))
    {
        SetFailState("Missing required data file on \"data/%s.cfg\", please re-download.", DATA_FILENAME);
        return;
    }

    KeyValues kv = new KeyValues("l4d2_scripted_hud");
    kv.ImportFromFile(path);
    kv.JumpToKey("HUD_Texts");

    kv.GetString("HUD1", g_sData_HUD1_Text, sizeof(g_sData_HUD1_Text));
    TrimString(g_sData_HUD1_Text);
    g_bData_HUD1_Text = (g_sData_HUD1_Text[0] != 0);

    kv.GetString("HUD2", g_sData_HUD2_Text, sizeof(g_sData_HUD2_Text));
    TrimString(g_sData_HUD2_Text);
    g_bData_HUD2_Text = (g_sData_HUD2_Text[0] != 0);

    kv.GetString("HUD3", g_sData_HUD3_Text, sizeof(g_sData_HUD3_Text));
    TrimString(g_sData_HUD3_Text);
    g_bData_HUD3_Text = (g_sData_HUD3_Text[0] != 0);

    kv.GetString("HUD4", g_sData_HUD4_Text, sizeof(g_sData_HUD4_Text));
    TrimString(g_sData_HUD4_Text);
    g_bData_HUD4_Text = (g_sData_HUD4_Text[0] != 0);

    delete kv;
}

public void OnAllPluginsLoaded(){
	g_bWitchAndTankSystemAvailable = LibraryExists("witch_and_tankifier");
}
public void OnLibraryAdded(const char[] name)
{
    if ( StrEqual(name, "witch_and_tankifier") ) { g_bWitchAndTankSystemAvailable = true; }
}
public void OnLibraryRemoved(const char[] name)
{
    if ( StrEqual(name, "witch_and_tankifier") ) { g_bWitchAndTankSystemAvailable = true; }
}
//玩家连接
public void OnClientConnected(int client)
{
	if (!IsFakeClient(client))
		g_iPlayerNum += 1;
}

//玩家离开.
public void OnClientDisconnect(int client)
{
	if (!IsFakeClient(client))
		g_iPlayerNum -= 1;
}
//地图开始
public void OnMapStart()
{
	g_iPlayerNum = 0;
}
/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    LateLoad();

    HookEvents();

    delete g_tUpdateInterval;
    g_tUpdateInterval = CreateTimer(g_fCvar_UpdateInterval, TimerUpdateHUD, _, TIMER_REPEAT);
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar == g_hCvar_HUD1_Background)
        RequestFrame(OnNextFrameHUDBackground, HUD1);
    else if (convar == g_hCvar_HUD2_Background)
        RequestFrame(OnNextFrameHUDBackground, HUD2);
    else if (convar == g_hCvar_HUD3_Background)
        RequestFrame(OnNextFrameHUDBackground, HUD3);
    else if (convar == g_hCvar_HUD4_Background)
        RequestFrame(OnNextFrameHUDBackground, HUD4);

    GetCvars();

    HookEvents();

    delete g_tUpdateInterval;
    g_tUpdateInterval = CreateTimer(g_fCvar_UpdateInterval, TimerUpdateHUD, _, TIMER_REPEAT);
}

/****************************************************************************************************/

public void OnNextFrameHUDBackground(int hudid)
{
    if (!g_bCvar_Enabled)
        return;

    // if the background has been changed we need to set it invisible first to refresh the changes
    GameRules_SetProp("m_iScriptedHUDFlags", HUD_FLAG_NOTVISIBLE, _, hudid);
}

/****************************************************************************************************/

public void LateLoad()
{
    if (g_bCvar_BlinkTank)
        g_bAliveTank = HasAnyTankAlive();
}

/****************************************************************************************************/

void GetCvars()
{
    g_fCvar_pain_pills_decay_rate = g_hCvar_pain_pills_decay_rate.FloatValue;

    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_fCvar_UpdateInterval = g_hCvar_UpdateInterval.FloatValue;

    g_hCvar_HUD1_Text.GetString(g_sCvar_HUD1_Text, sizeof(g_sCvar_HUD1_Text));
    g_bCvar_HUD1_Text = (g_sCvar_HUD1_Text[0] != 0);
    g_iCvar_HUD1_TextAlign = g_hCvar_HUD1_TextAlign.IntValue;
    g_bCvar_HUD1_BlinkTank = g_hCvar_HUD1_BlinkTank.BoolValue;
    g_bCvar_HUD1_Blink = g_hCvar_HUD1_Blink.BoolValue;
    g_bCvar_HUD1_Beep = g_hCvar_HUD1_Beep.BoolValue;
    g_bCvar_HUD1_Visible = g_hCvar_HUD1_Visible.BoolValue;
    g_bCvar_HUD1_Background = g_hCvar_HUD1_Background.BoolValue;
    g_iCvar_HUD1_Team = g_hCvar_HUD1_Team.IntValue;
    g_iCvar_HUD1_Flag_Debug = g_hCvar_HUD1_Flag_Debug.IntValue;
    g_bCvar_HUD1_Flag_Debug = (g_iCvar_HUD1_Flag_Debug > 0);
    g_fCvar_HUD1_X = g_hCvar_HUD1_X.FloatValue;
    g_fHUD1_X = g_fCvar_HUD1_X;
    g_fCvar_HUD1_Y = g_hCvar_HUD1_Y.FloatValue;
    g_fHUD1_Y = g_fCvar_HUD1_Y;
    g_fCvar_HUD1_X_Speed = g_hCvar_HUD1_X_Speed.FloatValue;
    g_bCvar_HUD1_X_Speed = (g_fCvar_HUD1_X_Speed > 0.0);
    g_fCvar_HUD1_Y_Speed = g_hCvar_HUD1_Y_Speed.FloatValue;
    g_bCvar_HUD1_Y_Speed = (g_fCvar_HUD1_Y_Speed > 0.0);
    g_iCvar_HUD1_X_Direction = g_hCvar_HUD1_X_Direction.IntValue;
    g_iCvar_HUD1_Y_Direction = g_hCvar_HUD1_Y_Direction.IntValue;
    g_fCvar_HUD1_X_Min = g_hCvar_HUD1_X_Min.FloatValue;
    g_fCvar_HUD1_Y_Min = g_hCvar_HUD1_Y_Min.FloatValue;
    g_fCvar_HUD1_X_Max = g_hCvar_HUD1_X_Max.FloatValue;
    g_fCvar_HUD1_Y_Max = g_hCvar_HUD1_Y_Max.FloatValue;
    g_fCvar_HUD1_Width = g_hCvar_HUD1_Width.FloatValue;
    g_fCvar_HUD1_Height = g_hCvar_HUD1_Height.FloatValue;

    g_hCvar_HUD2_Text.GetString(g_sCvar_HUD2_Text, sizeof(g_sCvar_HUD2_Text));
    g_bCvar_HUD2_Text = (g_sCvar_HUD2_Text[0] != 0);
    g_iCvar_HUD2_TextAlign = g_hCvar_HUD2_TextAlign.IntValue;
    g_bCvar_HUD2_BlinkTank = g_hCvar_HUD2_BlinkTank.BoolValue;
    g_bCvar_HUD2_Blink = g_hCvar_HUD2_Blink.BoolValue;
    g_bCvar_HUD2_Beep = g_hCvar_HUD2_Beep.BoolValue;
    g_bCvar_HUD2_Visible = g_hCvar_HUD2_Visible.BoolValue;
    g_bCvar_HUD2_Background = g_hCvar_HUD2_Background.BoolValue;
    g_iCvar_HUD2_Team = g_hCvar_HUD2_Team.IntValue;
    g_iCvar_HUD2_Flag_Debug = g_hCvar_HUD2_Flag_Debug.IntValue;
    g_bCvar_HUD2_Flag_Debug = (g_iCvar_HUD2_Flag_Debug > 0);
    g_fCvar_HUD2_X = g_hCvar_HUD2_X.FloatValue;
    g_fHUD2_X = g_fCvar_HUD2_X;
    g_fCvar_HUD2_Y = g_hCvar_HUD2_Y.FloatValue;
    g_fHUD2_Y = g_fCvar_HUD2_Y;
    g_fCvar_HUD2_X_Speed = g_hCvar_HUD2_X_Speed.FloatValue;
    g_bCvar_HUD2_X_Speed = (g_fCvar_HUD2_X_Speed > 0.0);
    g_fCvar_HUD2_Y_Speed = g_hCvar_HUD2_Y_Speed.FloatValue;
    g_bCvar_HUD2_Y_Speed = (g_fCvar_HUD2_Y_Speed > 0.0);
    g_iCvar_HUD2_X_Direction = g_hCvar_HUD2_X_Direction.IntValue;
    g_iCvar_HUD2_Y_Direction = g_hCvar_HUD2_Y_Direction.IntValue;
    g_fCvar_HUD2_X_Min = g_hCvar_HUD2_X_Min.FloatValue;
    g_fCvar_HUD2_Y_Min = g_hCvar_HUD2_Y_Min.FloatValue;
    g_fCvar_HUD2_X_Max = g_hCvar_HUD2_X_Max.FloatValue;
    g_fCvar_HUD2_Y_Max = g_hCvar_HUD2_Y_Max.FloatValue;
    g_fCvar_HUD2_Width = g_hCvar_HUD2_Width.FloatValue;
    g_fCvar_HUD2_Height = g_hCvar_HUD2_Height.FloatValue;

    g_hCvar_HUD3_Text.GetString(g_sCvar_HUD3_Text, sizeof(g_sCvar_HUD3_Text));
    g_bCvar_HUD3_Text = (g_sCvar_HUD3_Text[0] != 0);
    g_iCvar_HUD3_TextAlign = g_hCvar_HUD3_TextAlign.IntValue;
    g_bCvar_HUD3_BlinkTank = g_hCvar_HUD3_BlinkTank.BoolValue;
    g_bCvar_HUD3_Blink = g_hCvar_HUD3_Blink.BoolValue;
    g_bCvar_HUD3_Beep = g_hCvar_HUD3_Beep.BoolValue;
    g_bCvar_HUD3_Visible = g_hCvar_HUD3_Visible.BoolValue;
    g_bCvar_HUD3_Background = g_hCvar_HUD3_Background.BoolValue;
    g_iCvar_HUD3_Team = g_hCvar_HUD3_Team.IntValue;
    g_iCvar_HUD3_Flag_Debug = g_hCvar_HUD3_Flag_Debug.IntValue;
    g_bCvar_HUD3_Flag_Debug = (g_iCvar_HUD3_Flag_Debug > 0);
    g_fCvar_HUD3_X = g_hCvar_HUD3_X.FloatValue;
    g_fHUD3_X = g_fCvar_HUD3_X;
    g_fCvar_HUD3_Y = g_hCvar_HUD3_Y.FloatValue;
    g_fHUD3_Y = g_fCvar_HUD3_Y;
    g_fCvar_HUD3_X_Speed = g_hCvar_HUD3_X_Speed.FloatValue;
    g_bCvar_HUD3_X_Speed = (g_fCvar_HUD3_X_Speed > 0.0);
    g_fCvar_HUD3_Y_Speed = g_hCvar_HUD3_Y_Speed.FloatValue;
    g_bCvar_HUD3_Y_Speed = (g_fCvar_HUD3_Y_Speed > 0.0);
    g_iCvar_HUD3_X_Direction = g_hCvar_HUD3_X_Direction.IntValue;
    g_iCvar_HUD3_Y_Direction = g_hCvar_HUD3_Y_Direction.IntValue;
    g_fCvar_HUD3_X_Min = g_hCvar_HUD3_X_Min.FloatValue;
    g_fCvar_HUD3_Y_Min = g_hCvar_HUD3_Y_Min.FloatValue;
    g_fCvar_HUD3_X_Max = g_hCvar_HUD3_X_Max.FloatValue;
    g_fCvar_HUD3_Y_Max = g_hCvar_HUD3_Y_Max.FloatValue;
    g_fCvar_HUD3_Width = g_hCvar_HUD3_Width.FloatValue;
    g_fCvar_HUD3_Height = g_hCvar_HUD3_Height.FloatValue;

    g_hCvar_HUD4_Text.GetString(g_sCvar_HUD4_Text, sizeof(g_sCvar_HUD4_Text));
    g_bCvar_HUD4_Text = (g_sCvar_HUD4_Text[0] != 0);
    g_iCvar_HUD4_TextAlign = g_hCvar_HUD4_TextAlign.IntValue;
    g_bCvar_HUD4_BlinkTank = g_hCvar_HUD4_BlinkTank.BoolValue;
    g_bCvar_HUD4_Blink = g_hCvar_HUD4_Blink.BoolValue;
    g_bCvar_HUD4_Beep = g_hCvar_HUD4_Beep.BoolValue;
    g_bCvar_HUD4_Visible = g_hCvar_HUD4_Visible.BoolValue;
    g_bCvar_HUD4_Background = g_hCvar_HUD4_Background.BoolValue;
    g_iCvar_HUD4_Team = g_hCvar_HUD4_Team.IntValue;
    g_iCvar_HUD4_Flag_Debug = g_hCvar_HUD4_Flag_Debug.IntValue;
    g_bCvar_HUD4_Flag_Debug = (g_iCvar_HUD4_Flag_Debug > 0);
    g_fCvar_HUD4_X = g_hCvar_HUD4_X.FloatValue;
    g_fHUD4_X = g_fCvar_HUD4_X;
    g_fCvar_HUD4_Y = g_hCvar_HUD4_Y.FloatValue;
    g_fHUD4_Y = g_fCvar_HUD4_Y;
    g_fCvar_HUD4_X_Speed = g_hCvar_HUD4_X_Speed.FloatValue;
    g_bCvar_HUD4_X_Speed = (g_fCvar_HUD4_X_Speed > 0.0);
    g_fCvar_HUD4_Y_Speed = g_hCvar_HUD4_Y_Speed.FloatValue;
    g_bCvar_HUD4_Y_Speed = (g_fCvar_HUD4_Y_Speed > 0.0);
    g_iCvar_HUD4_X_Direction = g_hCvar_HUD4_X_Direction.IntValue;
    g_iCvar_HUD4_Y_Direction = g_hCvar_HUD4_Y_Direction.IntValue;
    g_fCvar_HUD4_X_Min = g_hCvar_HUD4_X_Min.FloatValue;
    g_fCvar_HUD4_Y_Min = g_hCvar_HUD4_Y_Min.FloatValue;
    g_fCvar_HUD4_X_Max = g_hCvar_HUD4_X_Max.FloatValue;
    g_fCvar_HUD4_Y_Max = g_hCvar_HUD4_Y_Max.FloatValue;
    g_fCvar_HUD4_Width = g_hCvar_HUD4_Width.FloatValue;
    g_fCvar_HUD4_Height = g_hCvar_HUD4_Height.FloatValue;

    g_bCvar_BlinkTank = (g_bCvar_HUD1_BlinkTank || g_bCvar_HUD2_BlinkTank || g_bCvar_HUD3_BlinkTank || g_bCvar_HUD4_BlinkTank);

    GetHUD_Flags();
}

/****************************************************************************************************/

void GetHUD_Flags()
{
    if (g_bCvar_HUD1_Flag_Debug)
    {
        g_iHUD1Flags = g_iCvar_HUD1_Flag_Debug;
    }
    else
    {
        g_iHUD1Flags = HUD_FLAG_TEXT;

        switch (g_iCvar_HUD1_TextAlign)
        {
            case 1: g_iHUD1Flags |= HUD_FLAG_ALIGN_LEFT;
            case 2: g_iHUD1Flags |= HUD_FLAG_ALIGN_CENTER;
            case 3: g_iHUD1Flags |= HUD_FLAG_ALIGN_RIGHT;
        }

        switch (g_iCvar_HUD1_Team)
        {
            case 1: g_iHUD1Flags |= HUD_FLAG_TEAM_SURVIVORS;
            case 2: g_iHUD1Flags |= HUD_FLAG_TEAM_INFECTED;
        }

        if (!g_bCvar_HUD1_Visible)
            g_iHUD1Flags |= HUD_FLAG_NOTVISIBLE;

        if (!g_bCvar_HUD1_Background)
            g_iHUD1Flags |= HUD_FLAG_NOBG;

        if (g_bCvar_HUD1_Blink)
            g_iHUD1Flags |= HUD_FLAG_BLINK;

        if (g_bCvar_HUD1_Beep)
            g_iHUD1Flags |= HUD_FLAG_BEEP;
    }

    if (g_bCvar_HUD2_Flag_Debug)
    {
        g_iHUD2Flags = g_iCvar_HUD2_Flag_Debug;
    }
    else
    {
        g_iHUD2Flags = HUD_FLAG_TEXT;

        switch (g_iCvar_HUD2_TextAlign)
        {
            case 1: g_iHUD2Flags |= HUD_FLAG_ALIGN_LEFT;
            case 2: g_iHUD2Flags |= HUD_FLAG_ALIGN_CENTER;
            case 3: g_iHUD2Flags |= HUD_FLAG_ALIGN_RIGHT;
        }

        switch (g_iCvar_HUD2_Team)
        {
            case 1: g_iHUD2Flags |= HUD_FLAG_TEAM_SURVIVORS;
            case 2: g_iHUD2Flags |= HUD_FLAG_TEAM_INFECTED;
        }

        if (!g_bCvar_HUD2_Visible)
            g_iHUD2Flags |= HUD_FLAG_NOTVISIBLE;

        if (!g_bCvar_HUD2_Background)
            g_iHUD2Flags |= HUD_FLAG_NOBG;

        if (g_bCvar_HUD2_Blink)
            g_iHUD2Flags |= HUD_FLAG_BLINK;

        if (g_bCvar_HUD2_Beep)
            g_iHUD2Flags |= HUD_FLAG_BEEP;
    }

    if (g_bCvar_HUD3_Flag_Debug)
    {
        g_iHUD3Flags = g_iCvar_HUD3_Flag_Debug;
    }
    else
    {
        g_iHUD3Flags = HUD_FLAG_TEXT;

        switch (g_iCvar_HUD3_TextAlign)
        {
            case 1: g_iHUD3Flags |= HUD_FLAG_ALIGN_LEFT;
            case 2: g_iHUD3Flags |= HUD_FLAG_ALIGN_CENTER;
            case 3: g_iHUD3Flags |= HUD_FLAG_ALIGN_RIGHT;
        }

        switch (g_iCvar_HUD3_Team)
        {
            case 1: g_iHUD3Flags |= HUD_FLAG_TEAM_SURVIVORS;
            case 2: g_iHUD3Flags |= HUD_FLAG_TEAM_INFECTED;
        }

        if (!g_bCvar_HUD3_Visible)
            g_iHUD3Flags |= HUD_FLAG_NOTVISIBLE;

        if (!g_bCvar_HUD3_Background)
            g_iHUD3Flags |= HUD_FLAG_NOBG;

        if (g_bCvar_HUD3_Blink)
            g_iHUD3Flags |= HUD_FLAG_BLINK;

        if (g_bCvar_HUD3_Beep)
            g_iHUD3Flags |= HUD_FLAG_BEEP;
    }

    if (g_bCvar_HUD4_Flag_Debug)
    {
        g_iHUD4Flags = g_iCvar_HUD4_Flag_Debug;
    }
    else
    {
        g_iHUD4Flags = HUD_FLAG_TEXT;

        switch (g_iCvar_HUD4_TextAlign)
        {
            case 1: g_iHUD4Flags |= HUD_FLAG_ALIGN_LEFT;
            case 2: g_iHUD4Flags |= HUD_FLAG_ALIGN_CENTER;
            case 3: g_iHUD4Flags |= HUD_FLAG_ALIGN_RIGHT;
        }

        switch (g_iCvar_HUD4_Team)
        {
            case 1: g_iHUD4Flags |= HUD_FLAG_TEAM_SURVIVORS;
            case 2: g_iHUD4Flags |= HUD_FLAG_TEAM_INFECTED;
        }

        if (!g_bCvar_HUD4_Visible)
            g_iHUD4Flags |= HUD_FLAG_NOTVISIBLE;

        if (!g_bCvar_HUD4_Background)
            g_iHUD4Flags |= HUD_FLAG_NOBG;

        if (g_bCvar_HUD4_Blink)
            g_iHUD4Flags |= HUD_FLAG_BLINK;

        if (g_bCvar_HUD4_Beep)
            g_iHUD4Flags |= HUD_FLAG_BEEP;
    }
}

/****************************************************************************************************/

public void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("tank_spawn", Event_TankSpawn);
        HookEvent("player_death", Event_TankKilled);
        HookEvent("round_start", Event_RoundStart);
        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("tank_spawn", Event_TankSpawn);
        UnhookEvent("player_death", Event_TankKilled);
        UnhookEvent("round_start", Event_RoundStart);
        return;
    }
}

/****************************************************************************************************/

public void Event_TankKilled(Handle event, const char[] name, bool dontBroadcast)
{
	if (!g_bAliveTank) return; // No tank in play; no damage to record
	
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsAiTank(victim))
    {
        g_bAliveTank = false;
    }
}

public  void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_bAliveTank = false;
}

bool IsAiTank(int tank)
{
	if (tank != 0 && GetClientTeam(tank) == 3 && GetEntProp(tank, Prop_Send, "m_zombieClass") == 8)
	{
		return true;
	}
	return false;
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bCvar_BlinkTank)
        g_bAliveTank = true;
}

/****************************************************************************************************/

public Action TimerUpdateHUD(Handle timer)
{
    if (g_bCvar_Enabled)
        UpdateHUD();

    return Plugin_Continue;
}

/****************************************************************************************************/

public void UpdateHUD()
{
    GetHUD_Texts();
    GetHUD_Pos();

    if (g_bCvar_HUD1_BlinkTank && g_bAliveTank)
        GameRules_SetProp("m_iScriptedHUDFlags", g_iHUD1Flags | HUD_FLAG_BLINK, _, HUD1);
    else
        GameRules_SetProp("m_iScriptedHUDFlags", g_iHUD1Flags, _, HUD1);
    GameRules_SetPropFloat("m_fScriptedHUDPosX", g_fHUD1_X, HUD1);
    GameRules_SetPropFloat("m_fScriptedHUDPosY", g_fHUD1_Y, HUD1);
    GameRules_SetPropFloat("m_fScriptedHUDWidth", g_fCvar_HUD1_Width, HUD1);
    GameRules_SetPropFloat("m_fScriptedHUDHeight", g_fCvar_HUD1_Height * (CountCharInString(g_sHUD_TextArray[HUD1], '\n') + 1), HUD1);

    if (g_bCvar_HUD2_BlinkTank && g_bAliveTank)
        GameRules_SetProp("m_iScriptedHUDFlags", g_iHUD2Flags | HUD_FLAG_BLINK, _, HUD2);
    else
        GameRules_SetProp("m_iScriptedHUDFlags", g_iHUD2Flags, _, HUD2);
    GameRules_SetPropFloat("m_fScriptedHUDPosX", g_fHUD2_X, HUD2);
    GameRules_SetPropFloat("m_fScriptedHUDPosY", g_fHUD2_Y, HUD2);
    GameRules_SetPropFloat("m_fScriptedHUDWidth", g_fCvar_HUD2_Width, HUD2);
    GameRules_SetPropFloat("m_fScriptedHUDHeight", g_fCvar_HUD2_Height * (CountCharInString(g_sHUD_TextArray[HUD2], '\n') + 1), HUD2);

    if (g_bCvar_HUD3_BlinkTank && g_bAliveTank)
        GameRules_SetProp("m_iScriptedHUDFlags", g_iHUD3Flags | HUD_FLAG_BLINK, _, HUD3);
    else
        GameRules_SetProp("m_iScriptedHUDFlags", g_iHUD3Flags, _, HUD3);
    GameRules_SetPropFloat("m_fScriptedHUDPosX", g_fHUD3_X, HUD3);
    GameRules_SetPropFloat("m_fScriptedHUDPosY", g_fHUD3_Y, HUD3);
    GameRules_SetPropFloat("m_fScriptedHUDWidth", g_fCvar_HUD3_Width, HUD3);
    GameRules_SetPropFloat("m_fScriptedHUDHeight", g_fCvar_HUD3_Height * (CountCharInString(g_sHUD_TextArray[HUD3], '\n') + 1), HUD3);

    if (g_bCvar_HUD4_BlinkTank && g_bAliveTank)
        GameRules_SetProp("m_iScriptedHUDFlags", g_iHUD4Flags | HUD_FLAG_BLINK, _, HUD4);
    else
        GameRules_SetProp("m_iScriptedHUDFlags", g_iHUD4Flags, _, HUD4);
    GameRules_SetPropFloat("m_fScriptedHUDPosX", g_fHUD4_X, HUD4);
    GameRules_SetPropFloat("m_fScriptedHUDPosY", g_fHUD4_Y, HUD4);
    GameRules_SetPropFloat("m_fScriptedHUDWidth", g_fCvar_HUD4_Width, HUD4);
    GameRules_SetPropFloat("m_fScriptedHUDHeight", g_fCvar_HUD4_Height * (CountCharInString(g_sHUD_TextArray[HUD4], '\n') + 1), HUD4);

    ImplodeStrings(g_sHUD_TextArray, sizeof(g_sHUD_TextArray), " ", g_sHUD_Text, sizeof(g_sHUD_Text));
    GameRules_SetPropString("m_szScriptedHUDStringSet", g_sHUD_Text);
}

/****************************************************************************************************/

void GetHUD_Pos()
{
    if (g_bCvar_HUD1_X_Speed)
    {
        switch (g_iCvar_HUD1_X_Direction)
        {
            case HUD_X_LEFT_TO_RIGHT:
            {
                g_fHUD1_X += g_fCvar_HUD1_X_Speed;

                if (g_fHUD1_X > g_fCvar_HUD1_X_Max)
                    g_fHUD1_X = g_fCvar_HUD1_X_Min;
            }
            case HUD_X_RIGHT_TO_LEFT:
            {
                g_fHUD1_X -= g_fCvar_HUD1_X_Speed;

                if (g_fHUD1_X < g_fCvar_HUD1_X_Min)
                    g_fHUD1_X = g_fCvar_HUD1_X_Max;
            }
        }
    }

    if (g_bCvar_HUD1_Y_Speed)
    {
        switch (g_iCvar_HUD1_Y_Direction)
        {
            case HUD_Y_TOP_TO_BOTTOM:
            {
                g_fHUD1_Y += g_fCvar_HUD1_Y_Speed;

                if (g_fHUD1_Y > g_fCvar_HUD1_Y_Max)
                    g_fHUD1_Y = g_fCvar_HUD1_Y_Min;
            }
            case HUD_Y_BOTTOM_TO_TOP:
            {
                g_fHUD1_Y -= g_fCvar_HUD1_Y_Speed;

                if (g_fHUD1_Y < g_fCvar_HUD1_Y_Min)
                    g_fHUD1_Y = g_fCvar_HUD1_X_Max;
            }
        }
    }

    if (g_bCvar_HUD2_X_Speed)
    {
        switch (g_iCvar_HUD2_X_Direction)
        {
            case HUD_X_LEFT_TO_RIGHT:
            {
                g_fHUD2_X += g_fCvar_HUD2_X_Speed;

                if (g_fHUD2_X > g_fCvar_HUD2_X_Max)
                    g_fHUD2_X = g_fCvar_HUD2_X_Min;
            }
            case HUD_X_RIGHT_TO_LEFT:
            {
                g_fHUD2_X -= g_fCvar_HUD2_X_Speed;

                if (g_fHUD2_X < g_fCvar_HUD2_X_Min)
                    g_fHUD2_X = g_fCvar_HUD2_X_Max;
            }
        }
    }

    if (g_bCvar_HUD2_Y_Speed)
    {
        switch (g_iCvar_HUD2_Y_Direction)
        {
            case HUD_Y_TOP_TO_BOTTOM:
            {
                g_fHUD2_Y += g_fCvar_HUD2_Y_Speed;

                if (g_fHUD2_Y > g_fCvar_HUD2_Y_Max)
                    g_fHUD2_Y = g_fCvar_HUD2_Y_Min;
            }
            case HUD_Y_BOTTOM_TO_TOP:
            {
                g_fHUD2_Y -= g_fCvar_HUD2_Y_Speed;

                if (g_fHUD2_Y < g_fCvar_HUD2_Y_Min)
                    g_fHUD2_Y = g_fCvar_HUD2_X_Max;
            }
        }
    }

    if (g_bCvar_HUD3_X_Speed)
    {
        switch (g_iCvar_HUD3_X_Direction)
        {
            case HUD_X_LEFT_TO_RIGHT:
            {
                g_fHUD3_X += g_fCvar_HUD3_X_Speed;

                if (g_fHUD3_X > g_fCvar_HUD3_X_Max)
                    g_fHUD3_X = g_fCvar_HUD3_X_Min;
            }
            case HUD_X_RIGHT_TO_LEFT:
            {
                g_fHUD3_X -= g_fCvar_HUD3_X_Speed;

                if (g_fHUD3_X < g_fCvar_HUD3_X_Min)
                    g_fHUD3_X = g_fCvar_HUD3_X_Max;
            }
        }
    }

    if (g_bCvar_HUD3_Y_Speed)
    {
        switch (g_iCvar_HUD3_Y_Direction)
        {
            case HUD_Y_TOP_TO_BOTTOM:
            {
                g_fHUD3_Y += g_fCvar_HUD3_Y_Speed;

                if (g_fHUD3_Y > g_fCvar_HUD3_Y_Max)
                    g_fHUD3_Y = g_fCvar_HUD3_Y_Min;
            }
            case HUD_Y_BOTTOM_TO_TOP:
            {
                g_fHUD3_Y -= g_fCvar_HUD3_Y_Speed;

                if (g_fHUD3_Y < g_fCvar_HUD3_Y_Min)
                    g_fHUD3_Y = g_fCvar_HUD3_X_Max;
            }
        }
    }

    if (g_bCvar_HUD4_X_Speed)
    {
        switch (g_iCvar_HUD4_X_Direction)
        {
            case HUD_X_LEFT_TO_RIGHT:
            {
                g_fHUD4_X += g_fCvar_HUD4_X_Speed;

                if (g_fHUD4_X > g_fCvar_HUD4_X_Max)
                    g_fHUD4_X = g_fCvar_HUD4_X_Min;
            }
            case HUD_X_RIGHT_TO_LEFT:
            {
                g_fHUD4_X -= g_fCvar_HUD4_X_Speed;

                if (g_fHUD4_X < g_fCvar_HUD4_X_Min)
                    g_fHUD4_X = g_fCvar_HUD4_X_Max;
            }
        }
    }

    if (g_bCvar_HUD4_Y_Speed)
    {
        switch (g_iCvar_HUD4_Y_Direction)
        {
            case HUD_Y_TOP_TO_BOTTOM:
            {
                g_fHUD4_Y += g_fCvar_HUD4_Y_Speed;

                if (g_fHUD4_Y > g_fCvar_HUD4_Y_Max)
                    g_fHUD4_Y = g_fCvar_HUD4_Y_Min;
            }
            case HUD_Y_BOTTOM_TO_TOP:
            {
                g_fHUD4_Y -= g_fCvar_HUD4_Y_Speed;

                if (g_fHUD4_Y < g_fCvar_HUD4_Y_Min)
                    g_fHUD4_Y = g_fCvar_HUD4_X_Max;
            }
        }
    }
}

/****************************************************************************************************/

void GetHUD_Texts()
{
    g_sBuffer = "\0";
    if (g_bData_HUD1_Text)
    {
        FormatEx(g_sBuffer, sizeof(g_sBuffer), "%s%s", g_sData_HUD1_Text, g_sSpaces);
    }
    else if (g_bCvar_HUD1_Text)
    {
        FormatEx(g_sBuffer, sizeof(g_sBuffer), "%s%s", g_sCvar_HUD1_Text, g_sSpaces);
    }
    else
    {
        GetHUD1_Text(g_sHUD1_Text, sizeof(g_sHUD1_Text));
        FormatEx(g_sBuffer, sizeof(g_sBuffer), "%s%s", g_sHUD1_Text, g_sSpaces);
    }
    g_sHUD_TextArray[HUD1] = g_sBuffer;

    g_sBuffer = "\0";
    if (g_bData_HUD2_Text)
    {
        FormatEx(g_sBuffer, sizeof(g_sBuffer), "%s%s", g_sData_HUD2_Text, g_sSpaces);
    }
    else if (g_bCvar_HUD2_Text)
    {
        FormatEx(g_sBuffer, sizeof(g_sBuffer), "%s%s", g_sCvar_HUD2_Text, g_sSpaces);
    }
    else
    {
        GetHUD2_Text(g_sHUD2_Text, sizeof(g_sHUD2_Text));
        FormatEx(g_sBuffer, sizeof(g_sBuffer), "%s%s", g_sHUD2_Text, g_sSpaces);
    }
    g_sHUD_TextArray[HUD2] = g_sBuffer;

    g_sBuffer = "\0";
    if (g_bData_HUD3_Text)
    {
        FormatEx(g_sBuffer, sizeof(g_sBuffer), "%s%s", g_sData_HUD3_Text, g_sSpaces);
    }
    else if (g_bCvar_HUD3_Text)
    {
        FormatEx(g_sBuffer, sizeof(g_sBuffer), "%s%s", g_sCvar_HUD3_Text, g_sSpaces);
    }
    else
    {
        GetHUD3_Text(g_sHUD3_Text, sizeof(g_sHUD3_Text));
        FormatEx(g_sBuffer, sizeof(g_sBuffer), "%s%s", g_sHUD3_Text, g_sSpaces);
    }
    g_sHUD_TextArray[HUD3] = g_sBuffer;

    g_sBuffer = "\0";
    if (g_bData_HUD4_Text)
    {
        FormatEx(g_sBuffer, sizeof(g_sBuffer), "%s%s", g_sData_HUD4_Text, g_sSpaces);
    }
    else if (g_bCvar_HUD4_Text)
    {
        FormatEx(g_sBuffer, sizeof(g_sBuffer), "%s%s", g_sCvar_HUD4_Text, g_sSpaces);
    }
    else
    {
        GetHUD4_Text(g_sHUD4_Text, sizeof(g_sHUD4_Text));
        FormatEx(g_sBuffer, sizeof(g_sBuffer), "%s%s", g_sHUD4_Text, g_sSpaces);
    }
    g_sHUD_TextArray[HUD4] = g_sBuffer;
}

/****************************************************************************************************/
/*
void GetHUD1_Text(char[] output, int size)
{
   	FormatEx(output, size, "\0");
	int boss_proximity = RoundToNearest(GetBossProximity() * 100.0);
	int g_fWitchPercent, g_fTankPercent;
	if(GetWitchFlow(0))
	{
		g_fWitchPercent = RoundToNearest(GetWitchFlow(0) * 100.0);
	}
	else
	{
		g_fWitchPercent = 0;
	}
	if(GetTankFlow(0))
	{
		g_fTankPercent = RoundToNearest(GetTankFlow(0) * 100.0);
	}
	else
	{
		g_fTankPercent = 0;
	}
	if(g_fTankPercent)
	{
		if(g_fWitchPercent)
		{
			FormatEx(output, size, "当前: [%d] 坦克: [%d] 女巫: [%d]", boss_proximity, g_fTankPercent, g_fWitchPercent);
		}
		else
		{
			FormatEx(output, size, "当前: [%d] 坦克: [%d] 女巫: [Null]", boss_proximity, g_fTankPercent);
		}
	} 
	else if(g_fWitchPercent)
	{
		FormatEx(output, size, "当前: [%d] 坦克: [Null] 女巫: [%d]", boss_proximity, g_fWitchPercent);
	}
	else
	{
		FormatEx(output, size, "当前: [%d] 坦克: [Null] 女巫: [Null]", boss_proximity);
	}
}
*/


void GetHUD1_Text(char[] output, int size)
{
	int IsStaticTank = 0, IsStaticWitch = 0;
	ConVar cv;
	if(g_bWitchAndTankSystemAvailable){
		cv = FindConVar("sm_tank_can_spawn");
		if(cv.IntValue){
			if(IsStaticTankMap()){
				IsStaticTank = 2;
			}else{
				IsStaticTank = 1;
			}
	        
	    }
		cv = FindConVar("sm_witch_can_spawn");
		if(cv.IntValue){
			if(IsStaticWitchMap())
			{
				IsStaticWitch = 2;
			}else
			{
				IsStaticWitch = 1;
			}	    
		}
	}	
	
	FormatEx(output, size, "\0");
	int boss_proximity = RoundToNearest(GetBossProximity() * 100.0);
	int g_fWitchPercent, g_fTankPercent;
	g_fTankPercent = RoundToNearest(GetTankFlow(0)* 100.0);
	g_fWitchPercent = RoundToNearest(GetWitchFlow(0) * 100.0);
	//int max_dist = GetConVarInt(FindConVar("inf_SpawnDistanceMin"));
	FormatEx(output, size, "进度: [ %d%% ]", boss_proximity);
	if(IsStaticTank == 1 || (!g_bWitchAndTankSystemAvailable && g_fTankPercent))
	{
		
		FormatEx(output, size, "%s    坦克: [ %d%% ]", output, g_fTankPercent);
	}else if(IsStaticTank == 2)
	{
		FormatEx(output, size, "%s    坦克: [ 固定 ]", output);
	}
	if(IsStaticWitch == 1 || (!g_bWitchAndTankSystemAvailable && g_fWitchPercent))
	{
		
		FormatEx(output, size, "%s    女巫: [ %d%% ]", output, g_fWitchPercent);
	}
	else if(IsStaticWitch == 2)
	{
		FormatEx(output, size, "%s    女巫: [ 固定 ]", output);
	}
	//PrintToConsoleAll("tank: %d witch: %d", IsStaticTank, IsStaticTank);
}

/****************************************************************************************************/
float GetBossProximity()
{
	float proximity = GetMaxSurvivorCompletion() + g_hVsBossBuffer.FloatValue / L4D2Direct_GetMapMaxFlowDistance();

	return (proximity > 1.0) ? 1.0 : proximity;
}

float GetMaxSurvivorCompletion()
{
	float flow = 0.0, tmp_flow = 0.0, origin[3];
	Address pNavArea;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			GetClientAbsOrigin(i, origin);
			pNavArea = L4D2Direct_GetTerrorNavArea(origin);
			if (pNavArea == Address_Null) 
			{
				pNavArea = L4D_GetNearestNavArea(origin, 300.0, false, false, false, 2);
			}
			if (pNavArea != Address_Null) {
				tmp_flow = L4D2Direct_GetTerrorNavAreaFlow(pNavArea);
				flow = (flow > tmp_flow) ? flow : tmp_flow;
			}
		}
	}

	return (flow / L4D2Direct_GetMapMaxFlowDistance());
}

// This method will return the Tank flow for a specified round
stock float GetTankFlow(int round)
{
	return L4D2Direct_GetVSTankFlowPercent(round);
}

stock float GetWitchFlow(int round)
{
	return L4D2Direct_GetVSWitchFlowPercent(round);
}
stock int GetPlayerNumber()
{
	int number = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			number ++;
	}
	return number;
}
void GetHUD2_Text(char[] output, int size)
{
	FormatEx(output, size, "\0");
	int PlayerLimit = GetConVarInt(FindConVar("sv_maxplayers"));
	char hostname[64];
 	FindConVar("hostname").GetString(hostname,sizeof(hostname));   
 	FormatEx(output, size, "%s(%d/%d/%d)",  hostname, GetPlayerNumber(), g_iPlayerNum, PlayerLimit);
}

/****************************************************************************************************/

bool HavePills(int client)
{
	char weapon[32];
	int KidSlot=GetPlayerWeaponSlot(client, 4);
 
	if(KidSlot !=-1)
	{
		GetEdictClassname(KidSlot, weapon, 32);
		if(StrEqual(weapon, "weapon_pain_pills"))
		{
			return true;
		}
 	}
	return false;
}

void GetHUD3_Text(char[] output, int size)
{
	FormatEx(output, size, "\0");
		
	int num = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		    continue;

		if (GetClientTeam(client) != TEAM_SURVIVOR)
		    continue;
		num += 1;
		if (num > 4)
			continue;
		char health[64];
		if (!IsPlayerAlive(client))
		    FormatEx(health, sizeof(health), "☠");
		else if(L4D_IsPlayerIncapacitated(client))
			FormatEx(health, sizeof(health), "(%dHP)",GetClientHealth(client) + GetClientTempHealth(client));
		else
		    FormatEx(health, sizeof(health), "%dHP", GetClientHealth(client) + GetClientTempHealth(client));
		char name[12];
		GetClientName(client,name,sizeof(name));
		if (output[0] == 0)
			FormatEx(output, size, "玩家状态[药][倒地]\n%s: %s", name, health);
		else
			Format(output, size, "%s\n%s: %s", output, name, health);
		if(HavePills(client)&&IsPlayerAlive(client))
			Format(output, size, "%s[%s][%d]", output, "有",L4D_GetPlayerReviveCount(client));  
		else if(!HavePills(client)&&IsPlayerAlive(client))
			Format(output, size, "%s[%s][%d]", output, "无",L4D_GetPlayerReviveCount(client));	
    }
}

/****************************************************************************************************/

void GetHUD4_Text(char[] output, int size)
{
    FormatEx(output, size, "\0");

    // for (int client = 1; client <= MaxClients; client++)
    // {
        // if (!IsClientInGame(client))
            // continue;

        // if (IsFakeClient(client))
            // continue;

        // if (BaseComm_IsClientMuted(client))
            // continue;

        // if (!IsClientSpeaking(client))
            // continue;

        // if (output[0] == 0)
            // FormatEx(output, size, "Players Speaking:\n%N", client);
        // else
            // Format(output, size, "%s\n%N", output, client);
    // }
}

public Action ShowSpecHud(int client, int args)
{
    g_hCvar_HUD3_Visible.SetInt(1);
    return Plugin_Continue;
}

public Action offSpecHud(int client, int args)
{
    g_hCvar_HUD3_Visible.SetInt(0);
    return Plugin_Continue;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdReloadData(int client, int args)
{
    LoadPluginData();

    if (IsValidClient(client))
        PrintToChat(client, "\x04[HUD texts from data file reloaded]");

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "------------------ Plugin Cvars (l4d2_scripted_hud) ------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_scripted_hud_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_scripted_hud_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_update_interval : %.1f", g_fCvar_UpdateInterval);
    PrintToConsole(client, "l4d2_scripted_hud_hud1_text : \"%s\"", g_sCvar_HUD1_Text);
    PrintToConsole(client, "l4d2_scripted_hud_hud1_text_align : %i (%s)", g_iCvar_HUD1_TextAlign, g_iCvar_HUD1_TextAlign == HUD_TEXT_ALIGN_LEFT ? "LEFT" : g_iCvar_HUD1_TextAlign == HUD_TEXT_ALIGN_CENTER ? "CENTER" : "RIGHT");
    PrintToConsole(client, "l4d2_scripted_hud_hud1_blink_tank : %b (%s)", g_bCvar_HUD1_BlinkTank, g_bCvar_HUD1_BlinkTank ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud1_blink : %b (%s)", g_bCvar_HUD1_Blink, g_bCvar_HUD1_Blink ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud1_beep : %b (%s)", g_bCvar_HUD1_Beep, g_bCvar_HUD1_Beep ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud1_visible : %b (%s)", g_bCvar_HUD1_Visible, g_bCvar_HUD1_Visible ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud1_background : %i (%s)", g_bCvar_HUD1_Background, g_bCvar_HUD1_Background ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud1_team : %i (%s)", g_iCvar_HUD1_Team, g_iCvar_HUD1_Team == HUD_TEAM_ALL ? "ALL" : g_iCvar_HUD1_Team == HUD_TEAM_SURVIVOR ? "SURVIVOR" : "INFECTED");
    PrintToConsole(client, "l4d2_scripted_hud_hud1_flag_debug : %i (%s)", g_iCvar_HUD1_Flag_Debug, g_bCvar_HUD1_Flag_Debug ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud1_x : %.4f", g_fCvar_HUD1_X);
    PrintToConsole(client, "l4d2_scripted_hud_hud1_y : %.4f", g_fCvar_HUD1_Y);
    PrintToConsole(client, "l4d2_scripted_hud_hud1_x_speed : %.4f", g_fCvar_HUD1_X_Speed);
    PrintToConsole(client, "l4d2_scripted_hud_hud1_y_speed : %.4f", g_fCvar_HUD1_Y_Speed);
    PrintToConsole(client, "l4d2_scripted_hud_hud1_x_direction : %i (%s)", g_iCvar_HUD1_X_Direction, g_iCvar_HUD1_X_Direction == HUD_X_LEFT_TO_RIGHT ? "Left to Right" : "Right to Left");
    PrintToConsole(client, "l4d2_scripted_hud_hud1_y_direction : %i (%s)", g_iCvar_HUD1_Y_Direction, g_iCvar_HUD1_Y_Direction == HUD_Y_TOP_TO_BOTTOM ? "Top to Bottom" : "Bottom to Top");
    PrintToConsole(client, "l4d2_scripted_hud_hud1_x_min : %.4f", g_fCvar_HUD1_X_Min);
    PrintToConsole(client, "l4d2_scripted_hud_hud1_y_min : %.4f", g_fCvar_HUD1_Y_Min);
    PrintToConsole(client, "l4d2_scripted_hud_hud1_x_max : %.4f", g_fCvar_HUD1_X_Max);
    PrintToConsole(client, "l4d2_scripted_hud_hud1_y_max : %.4f", g_fCvar_HUD1_Y_Max);
    PrintToConsole(client, "l4d2_scripted_hud_hud1_width : %.4f", g_fCvar_HUD1_Width);
    PrintToConsole(client, "l4d2_scripted_hud_hud1_height : %.4f", g_fCvar_HUD1_Height);
    PrintToConsole(client, "l4d2_scripted_hud_hud2_text : \"%s\"", g_sCvar_HUD2_Text);
    PrintToConsole(client, "l4d2_scripted_hud_hud2_text_align : %i (%s)", g_iCvar_HUD2_TextAlign, g_iCvar_HUD2_TextAlign == HUD_TEXT_ALIGN_LEFT ? "LEFT" : g_iCvar_HUD2_TextAlign == HUD_TEXT_ALIGN_CENTER ? "CENTER" : "RIGHT");
    PrintToConsole(client, "l4d2_scripted_hud_hud2_blink_tank : %b (%s)", g_bCvar_HUD2_BlinkTank, g_bCvar_HUD2_BlinkTank ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud2_blink : %b (%s)", g_bCvar_HUD2_Blink, g_bCvar_HUD2_Blink ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud2_beep : %b (%s)", g_bCvar_HUD2_Beep, g_bCvar_HUD2_Beep ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud2_visible : %b (%s)", g_bCvar_HUD2_Visible, g_bCvar_HUD2_Visible ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud2_background : %i (%s)", g_bCvar_HUD2_Background, g_bCvar_HUD2_Background ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud2_team : %i (%s)", g_iCvar_HUD2_Team, g_iCvar_HUD2_Team == HUD_TEAM_ALL ? "ALL" : g_iCvar_HUD2_Team == HUD_TEAM_SURVIVOR ? "SURVIVOR" : "INFECTED");
    PrintToConsole(client, "l4d2_scripted_hud_hud2_flag_debug : %i (%s)", g_iCvar_HUD2_Flag_Debug, g_bCvar_HUD2_Flag_Debug ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud2_x : %.4f", g_fCvar_HUD2_X);
    PrintToConsole(client, "l4d2_scripted_hud_hud2_y : %.4f", g_fCvar_HUD2_Y);
    PrintToConsole(client, "l4d2_scripted_hud_hud2_x_speed : %.4f", g_fCvar_HUD2_X_Speed);
    PrintToConsole(client, "l4d2_scripted_hud_hud2_y_speed : %.4f", g_fCvar_HUD2_Y_Speed);
    PrintToConsole(client, "l4d2_scripted_hud_hud2_x_direction : %i (%s)", g_iCvar_HUD2_X_Direction, g_iCvar_HUD2_X_Direction == HUD_X_LEFT_TO_RIGHT ? "Left to Right" : "Right to Left");
    PrintToConsole(client, "l4d2_scripted_hud_hud2_y_direction : %i (%s)", g_iCvar_HUD2_Y_Direction, g_iCvar_HUD2_Y_Direction == HUD_Y_TOP_TO_BOTTOM ? "Top to Bottom" : "Bottom to Top");
    PrintToConsole(client, "l4d2_scripted_hud_hud2_x_min : %.4f", g_fCvar_HUD2_X_Min);
    PrintToConsole(client, "l4d2_scripted_hud_hud2_y_min : %.4f", g_fCvar_HUD2_Y_Min);
    PrintToConsole(client, "l4d2_scripted_hud_hud2_x_max : %.4f", g_fCvar_HUD2_X_Max);
    PrintToConsole(client, "l4d2_scripted_hud_hud2_y_max : %.4f", g_fCvar_HUD2_Y_Max);
    PrintToConsole(client, "l4d2_scripted_hud_hud2_width : %.4f", g_fCvar_HUD2_Width);
    PrintToConsole(client, "l4d2_scripted_hud_hud2_height : %.4f", g_fCvar_HUD2_Height);
    PrintToConsole(client, "l4d2_scripted_hud_hud3_text : \"%s\"", g_sCvar_HUD3_Text);
    PrintToConsole(client, "l4d2_scripted_hud_hud3_text_align : %i (%s)", g_iCvar_HUD3_TextAlign, g_iCvar_HUD3_TextAlign == HUD_TEXT_ALIGN_LEFT ? "LEFT" : g_iCvar_HUD3_TextAlign == HUD_TEXT_ALIGN_CENTER ? "CENTER" : "RIGHT");
    PrintToConsole(client, "l4d2_scripted_hud_hud3_blink_tank : %b (%s)", g_bCvar_HUD3_BlinkTank, g_bCvar_HUD3_BlinkTank ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud3_blink : %b (%s)", g_bCvar_HUD3_Blink, g_bCvar_HUD3_Blink ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud3_beep : %b (%s)", g_bCvar_HUD3_Beep, g_bCvar_HUD3_Beep ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud3_visible : %b (%s)", g_bCvar_HUD3_Visible, g_bCvar_HUD3_Visible ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud3_background : %i (%s)", g_bCvar_HUD3_Background, g_bCvar_HUD3_Background ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud3_team : %i (%s)", g_iCvar_HUD3_Team, g_iCvar_HUD3_Team == HUD_TEAM_ALL ? "ALL" : g_iCvar_HUD3_Team == HUD_TEAM_SURVIVOR ? "SURVIVOR" : "INFECTED");
    PrintToConsole(client, "l4d2_scripted_hud_hud3_flag_debug : %i (%s)", g_iCvar_HUD3_Flag_Debug, g_bCvar_HUD3_Flag_Debug ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud3_x : %.4f", g_fCvar_HUD3_X);
    PrintToConsole(client, "l4d2_scripted_hud_hud3_y : %.4f", g_fCvar_HUD3_Y);
    PrintToConsole(client, "l4d2_scripted_hud_hud3_x_speed : %.4f", g_fCvar_HUD3_X_Speed);
    PrintToConsole(client, "l4d2_scripted_hud_hud3_y_speed : %.4f", g_fCvar_HUD3_Y_Speed);
    PrintToConsole(client, "l4d2_scripted_hud_hud3_x_direction : %i (%s)", g_iCvar_HUD3_X_Direction, g_iCvar_HUD3_X_Direction == HUD_X_LEFT_TO_RIGHT ? "Left to Right" : "Right to Left");
    PrintToConsole(client, "l4d2_scripted_hud_hud3_y_direction : %i (%s)", g_iCvar_HUD3_Y_Direction, g_iCvar_HUD3_Y_Direction == HUD_Y_TOP_TO_BOTTOM ? "Top to Bottom" : "Bottom to Top");
    PrintToConsole(client, "l4d2_scripted_hud_hud3_x_min : %.4f", g_fCvar_HUD3_X_Min);
    PrintToConsole(client, "l4d2_scripted_hud_hud3_y_min : %.4f", g_fCvar_HUD3_Y_Min);
    PrintToConsole(client, "l4d2_scripted_hud_hud3_x_max : %.4f", g_fCvar_HUD3_X_Max);
    PrintToConsole(client, "l4d2_scripted_hud_hud3_y_max : %.4f", g_fCvar_HUD3_Y_Max);
    PrintToConsole(client, "l4d2_scripted_hud_hud3_width : %.4f", g_fCvar_HUD3_Width);
    PrintToConsole(client, "l4d2_scripted_hud_hud3_height : %.4f", g_fCvar_HUD3_Height);
    PrintToConsole(client, "l4d2_scripted_hud_hud4_text : \"%s\"", g_sCvar_HUD4_Text);
    PrintToConsole(client, "l4d2_scripted_hud_hud4_text_align : %i (%s)", g_iCvar_HUD4_TextAlign, g_iCvar_HUD4_TextAlign == HUD_TEXT_ALIGN_LEFT ? "LEFT" : g_iCvar_HUD4_TextAlign == HUD_TEXT_ALIGN_CENTER ? "CENTER" : "RIGHT");
    PrintToConsole(client, "l4d2_scripted_hud_hud4_blink_tank : %b (%s)", g_bCvar_HUD4_BlinkTank, g_bCvar_HUD4_BlinkTank ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud4_blink : %b (%s)", g_bCvar_HUD4_Blink, g_bCvar_HUD4_Blink ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud4_beep : %b (%s)", g_bCvar_HUD4_Beep, g_bCvar_HUD4_Beep ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud4_visible : %b (%s)", g_bCvar_HUD4_Visible, g_bCvar_HUD4_Visible ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud4_background : %i (%s)", g_bCvar_HUD4_Background, g_bCvar_HUD4_Background ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud4_team : %i (%s)", g_iCvar_HUD4_Team, g_iCvar_HUD4_Team == HUD_TEAM_ALL ? "ALL" : g_iCvar_HUD4_Team == HUD_TEAM_SURVIVOR ? "SURVIVOR" : "INFECTED");
    PrintToConsole(client, "l4d2_scripted_hud_hud4_flag_debug : %i (%s)", g_iCvar_HUD4_Flag_Debug, g_bCvar_HUD4_Flag_Debug ? "true" : "false");
    PrintToConsole(client, "l4d2_scripted_hud_hud4_x : %.4f", g_fCvar_HUD4_X);
    PrintToConsole(client, "l4d2_scripted_hud_hud4_y : %.4f", g_fCvar_HUD4_Y);
    PrintToConsole(client, "l4d2_scripted_hud_hud4_x_speed : %.4f", g_fCvar_HUD4_X_Speed);
    PrintToConsole(client, "l4d2_scripted_hud_hud4_y_speed : %.4f", g_fCvar_HUD4_Y_Speed);
    PrintToConsole(client, "l4d2_scripted_hud_hud4_x_direction : %i (%s)", g_iCvar_HUD4_X_Direction, g_iCvar_HUD4_X_Direction == HUD_X_LEFT_TO_RIGHT ? "Left to Right" : "Right to Left");
    PrintToConsole(client, "l4d2_scripted_hud_hud4_y_direction : %i (%s)", g_iCvar_HUD4_Y_Direction, g_iCvar_HUD4_Y_Direction == HUD_Y_TOP_TO_BOTTOM ? "Top to Bottom" : "Bottom to Top");
    PrintToConsole(client, "l4d2_scripted_hud_hud4_x_min : %.4f", g_fCvar_HUD4_X_Min);
    PrintToConsole(client, "l4d2_scripted_hud_hud4_y_min : %.4f", g_fCvar_HUD4_Y_Min);
    PrintToConsole(client, "l4d2_scripted_hud_hud4_x_max : %.4f", g_fCvar_HUD4_X_Max);
    PrintToConsole(client, "l4d2_scripted_hud_hud4_y_max : %.4f", g_fCvar_HUD4_Y_Max);
    PrintToConsole(client, "l4d2_scripted_hud_hud4_width : %.4f", g_fCvar_HUD4_Width);
    PrintToConsole(client, "l4d2_scripted_hud_hud4_height : %.4f", g_fCvar_HUD4_Height);
    PrintToConsole(client, "");
    PrintToConsole(client, "-------------------------- HUD Texts (data)---------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "HUD1 : \"%s\"", g_sData_HUD1_Text);
    PrintToConsole(client, "HUD2 : \"%s\"", g_sData_HUD2_Text);
    PrintToConsole(client, "HUD3 : \"%s\"", g_sData_HUD3_Text);
    PrintToConsole(client, "HUD4 : \"%s\"", g_sData_HUD4_Text);
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------------------------------------------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "HUD 1 Flags : %i", g_iHUD1Flags);
    PrintToConsole(client, "HUD 2 Flags : %i", g_iHUD2Flags);
    PrintToConsole(client, "HUD 3 Flags : %i", g_iHUD3Flags);
    PrintToConsole(client, "HUD 4 Flags : %i", g_iHUD4Flags);
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
 * Gets the client L4D1/L4D2 zombie class id.
 *
 * @param client     Client index.
 * @return L4D1      1=SMOKER, 2=BOOMER, 3=HUNTER, 4=WITCH, 5=TANK, 6=NOT INFECTED
 * @return L4D2      1=SMOKER, 2=BOOMER, 3=HUNTER, 4=SPITTER, 5=JOCKEY, 6=CHARGER, 7=WITCH, 8=TANK, 9=NOT INFECTED
 */
int GetZombieClass(int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass"));
}

/****************************************************************************************************/

/**
 * Returns if the client is in ghost state.
 *
 * @param client        Client index.
 * @return              True if client is in ghost state, false otherwise.
 */
bool IsPlayerGhost(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isGhost") == 1);
}

/****************************************************************************************************/

/**
 * Validates if the client is incapacitated.
 *
 * @param client        Client index.
 * @return              True if the client is incapacitated, false otherwise.
 */
bool IsPlayerIncapacitated(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1);
}

/****************************************************************************************************/

/**
 * Returns if the client is a valid tank.
 *
 * @param client        Client index.
 * @return              True if client is a tank, false otherwise.
 */
bool IsPlayerTank(int client)
{
    if (GetClientTeam(client) != TEAM_INFECTED)
        return false;

    if (GetZombieClass(client) != L4D2_ZOMBIECLASS_TANK)
        return false;

    if (!IsPlayerAlive(client))
        return false;

    if (IsPlayerGhost(client))
        return false;

    return true;
}

/****************************************************************************************************/

/**
 * Returns if any tank is alive.
 *
 * @return              True if any tank is alive, false otherwise.
 */
bool HasAnyTankAlive()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (!IsPlayerTank(client))
            continue;

        if (IsPlayerIncapacitated(client))
            continue;

        return true;
    }

    return false;
}

/****************************************************************************************************/

/**
 * Counts the number of occurences of a character in a string.
 *
 * @param str           String.
 * @param c             Character to count.
 * @return              The number of occurences of the character in the string.
 */
int CountCharInString(const char[] str, char c)
{
    int i;
    int count;

    while (str[i] != 0)
    {
        if (str[i++] == c)
            count++;
    }

    return count;
}

/****************************************************************************************************/

// ====================================================================================================
// Thanks to Silvers
// ====================================================================================================
/**
 * Returns the client temporary health.
 *
 * @param client        Client index.
 * @return              Client temporary health.
 */
int GetClientTempHealth(int client)
{
    int tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_fCvar_pain_pills_decay_rate));
    return tempHealth < 0 ? 0 : tempHealth;
}