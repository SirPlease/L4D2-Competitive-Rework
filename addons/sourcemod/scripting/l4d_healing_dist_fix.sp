/**
// ====================================================================================================
Change Log:

1.0.2 (25-January-2023)
    - Changed the radius check to be based on player_use_radius cvar.

1.0.1 (03-January-2023)
    - Added L4D1 support. (thanks "KadabraZz" for reporting)

1.0.0 (02-January-2023)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Healing Distance Exploit Fix"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Resets the healing progress bar when the healer distance exceeds the maximum allowed"
#define PLUGIN_VERSION                "1.0.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=341128"

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
#define CONFIG_FILENAME               "l4d_healing_dist_fix"

// ====================================================================================================
// Defines
// ====================================================================================================
#define L4D2_USEACTION_HEALING        1

#define MAXENTITIES                   2048

// ====================================================================================================
// Game Cvars
// ====================================================================================================
ConVar g_hCvar_player_use_radius;

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bCvar_Enabled;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fCvar_player_use_radius;

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
bool ge_bValidRange[MAXENTITIES+1];

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
    g_hCvar_player_use_radius = FindConVar("player_use_radius");

    CreateConVar("l4d_healing_dist_fix_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("l4d_healing_dist_fix_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_player_use_radius.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_healing_dist_fix", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

void GetCvars()
{
    g_fCvar_player_use_radius = g_hCvar_player_use_radius.FloatValue;
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
}

/****************************************************************************************************/

public void OnPlayerRunCmdPost(int client, int buttons)
{
    if (!g_bCvar_Enabled)
        return;

    if (client == -1)
        return;

    g_bL4D2 ? OnPlayerRunCmdPostL4D2(client, buttons) : OnPlayerRunCmdPostL4D1(client);
}

/****************************************************************************************************/

void OnPlayerRunCmdPostL4D2(int client, int buttons)
{
    if (!(buttons & IN_ATTACK2))
        return;

    if (GetEntProp(client, Prop_Send, "m_iCurrentUseAction") != L4D2_USEACTION_HEALING)
        return;

    int target = GetEntPropEnt(client, Prop_Send, "m_useActionTarget");

    if (target == -1)
        return;

    if (target == client) // Self healing
        return;

    float vPos[3];
    GetClientEyePosition(client, vPos);

    ge_bValidRange[target] = false;
    TR_EnumerateEntitiesSphere(vPos, g_fCvar_player_use_radius, PARTITION_SOLID_EDICTS, TraceEntityEnumeratorFilter, target);

    if (!ge_bValidRange[target])
    {
        SetEntProp(client, Prop_Send, "m_useActionTarget", 0);
        SetEntProp(client, Prop_Send, "m_useActionOwner", 0);
        SetEntProp(client, Prop_Send, "m_iCurrentUseAction", 0);
        SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
        SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);

        if (IsValidClientIndex(target))
        {
            SetEntProp(target, Prop_Send, "m_useActionTarget", 0);
            SetEntProp(target, Prop_Send, "m_useActionOwner", 0);
            SetEntProp(target, Prop_Send, "m_iCurrentUseAction", 0);
            SetEntPropFloat(target, Prop_Send, "m_flProgressBarDuration", 0.0);
            SetEntPropFloat(target, Prop_Send, "m_flProgressBarStartTime", 0.0);
        }
    }
    else
    {
        ge_bValidRange[target] = false;
    }
}

/****************************************************************************************************/

// L4D1: Won't check for buttons. Workaround fix for when the hidden cvar "first_aid_kit_continuous_fire" is "0"
void OnPlayerRunCmdPostL4D1(int client)
{
    int target = GetEntPropEnt(client, Prop_Send, "m_healTarget");

    if (target == -1)
        return;

    if (target == client) // Self healing
        return;

    float vPos[3];
    GetClientEyePosition(client, vPos);

    ge_bValidRange[target] = false;
    TR_EnumerateEntitiesSphere(vPos, g_fCvar_player_use_radius, PARTITION_SOLID_EDICTS, TraceEntityEnumeratorFilter, target);

    if (!ge_bValidRange[target])
    {
        SetEntProp(client, Prop_Send, "m_healTarget", 0);
        SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
        SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);

        if (IsValidClientIndex(target))
        {
            SetEntProp(target, Prop_Send, "m_healOwner", 0);
            SetEntProp(target, Prop_Send, "m_iProgressBarDuration", 0);
            SetEntPropFloat(target, Prop_Send, "m_flProgressBarStartTime", 0.0);
        }
    }
    else
    {
        ge_bValidRange[target] = false;
    }
}

/****************************************************************************************************/

bool TraceEntityEnumeratorFilter(int entity, int target)
{
    if (entity == target)
    {
        ge_bValidRange[target] = true;
        return false; // after found, stop looping through entities
    }

    return true;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "-------------- Plugin Cvars (l4d_healing_dist_fix) --------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_healing_dist_fix_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_healing_dist_fix_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
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