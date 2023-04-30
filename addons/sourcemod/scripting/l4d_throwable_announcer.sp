/**
// ====================================================================================================
Change Log:

1.0.8 (05-September-2021)
    - Added Traditional Chinese (zho) translation. (thanks to "in2002")

1.0.7 (11-April-2021)
    - Added Russian (ru) translation. (thanks to "Zheldorg")

1.0.6 (05-March-2021)
    - Fixed fake throw announces. (thanks "KadabraZz" for reporting)

1.0.5 (16-October-2020)
    - Added better cvar handling for L4D1.

1.0.4 (15-October-2020)
    - Added two detection methods. (OnEntityCreated x weapon_fire+molotov_thrown[L4D2])

1.0.3 (30-September-2020)
    - Moved molotov check to "molotov_thrown" event. (L4D2 only)
    - Updated translation file to be more color friendly and highlighted the throwables.
    - Removed EventHookMode_PostNoCopy from hook events.

1.0.2 (29-September-2020)
    - Changed the validation from weapon name to weapon id.
    - Code optimization. (thanks to "Silvers")
    - Added colors.inc replacer. (thanks to "Silvers")

1.0.1 (29-September-2020)
    - Added Hungarian (hu) translation. (thanks to "KasperH")

1.0.0 (29-September-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Throwable Announcer"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Outputs to the chat who threw a throwable"
#define PLUGIN_VERSION                "1.0.8"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=327613"

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
#define CONFIG_FILENAME               "l4d_throwable_announcer"
//#define TRANSLATION_FILENAME          "l4d_throwable_announcer.phrases"

// ====================================================================================================
// Defines
// ====================================================================================================
#define TEAM_SPECTATOR                1
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

#define FLAG_TEAM_NONE                (0 << 0) // 0 | 0000
#define FLAG_TEAM_SURVIVOR            (1 << 0) // 1 | 0001
#define FLAG_TEAM_INFECTED            (1 << 1) // 2 | 0010
#define FLAG_TEAM_SPECTATOR           (1 << 2) // 4 | 0100
#define FLAG_TEAM_HOLDOUT             (1 << 3) // 8 | 1000

#define L4D1_WEPID_MOLOTOV            9
#define L4D1_WEPID_PIPE_BOMB          10

#define L4D2_WEPID_PIPE_BOMB          14
#define L4D2_WEPID_VOMITJAR           25

#define TYPE_NONE                     0
#define TYPE_MOLOTOV                  1
#define TYPE_PIPEBOMB                 2
#define TYPE_VOMITJAR                 3

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_FakeThrow;
static ConVar g_hCvar_Team;
static ConVar g_hCvar_Self;
static ConVar g_hCvar_Molotov;
static ConVar g_hCvar_Pipebomb;
static ConVar g_hCvar_Vomitjar;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bEventsHooked;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_Team;
static bool   g_bCvar_Self;
static bool   g_bCvar_Molotov;
static bool   g_bCvar_Pipebomb;
static bool   g_bCvar_Vomitjar;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iCvar_Team;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_FakeThrow;

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
static int    ge_iType[MAXENTITIES+1];
static float  ge_fLastThrown[MAXENTITIES+1];

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

    CreateConVar("l4d_throwable_announcer_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled         = CreateConVar("l4d_throwable_announcer_enable", "1", "启用此插件? 0=禁用, 1=启用.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_FakeThrow       = CreateConVar("l4d_throwable_announcer_fake_throw", "0.3", "等待多少秒后检测是不是假投掷物. 0=关闭, 1=开启.", CVAR_FLAGS, true, 0.0);
    g_hCvar_Team            = CreateConVar("l4d_throwable_announcer_team", "1", "抛出投掷物的提示消息发送给那些团队. 0=没有, 1=幸存者, 2=感染者, 4=旁观者, 8=幸存者NPC. 如需启用多个把数字加起来. 例如: 3=幸存者+感染者.", CVAR_FLAGS, true, 0.0, true, 15.0);
    g_hCvar_Self            = CreateConVar("l4d_throwable_announcer_self", "1", "抛出投掷物的提示消息发送给使用者? 0=关闭, 1=开启.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Molotov         = CreateConVar("l4d_throwable_announcer_molotov", "1", "每次抛出燃烧瓶时提示. 0=关闭, 1=开启.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Pipebomb        = CreateConVar("l4d_throwable_announcer_pipebomb", "1", "每次抛出土制炸弹时提示. 0=关闭, 1=开启.", CVAR_FLAGS, true, 0.0, true, 1.0);
    if (g_bL4D2)
        g_hCvar_Vomitjar    = CreateConVar("l4d_throwable_announcer_vomitjar", "1", "每次抛出胆汁罐时提示. 0=关闭, 1=开启.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FakeThrow.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Team.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Self.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Molotov.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Pipebomb.AddChangeHook(Event_ConVarChanged);
    if (g_bL4D2)
        g_hCvar_Vomitjar.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_throwable_announcer", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/
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

public void OnConfigsExecuted()
{
    GetCvars();

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
    g_fCvar_FakeThrow = g_hCvar_FakeThrow.FloatValue;
    g_iCvar_Team = g_hCvar_Team.IntValue;
    g_bCvar_Team = (g_iCvar_Team > 0);
    g_bCvar_Self = g_hCvar_Self.BoolValue;
    g_bCvar_Molotov = g_hCvar_Molotov.BoolValue;
    g_bCvar_Pipebomb = g_hCvar_Pipebomb.BoolValue;
    if (g_bL4D2)
        g_bCvar_Vomitjar = g_hCvar_Vomitjar.BoolValue;
}

/****************************************************************************************************/

public void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("weapon_fire", Event_WeaponFire);

        if (g_bL4D2)
            HookEvent("molotov_thrown", Event_MolotovThrown_L4D2); // L4D1 doesn't have "molotov_thrown" event

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("weapon_fire", Event_WeaponFire);

        if (g_bL4D2)
            UnhookEvent("molotov_thrown", Event_MolotovThrown_L4D2); // L4D1 doesn't have "molotov_thrown" event

        return;
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!IsValidEntityIndex(entity))
        return;

    ge_iType[entity] = TYPE_NONE;
    ge_fLastThrown[entity] = 0.0;
}

/****************************************************************************************************/

public void Event_MolotovThrown_L4D2(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bCvar_Enabled)
        return;

    if (!g_bCvar_Team)
        return;

    if (!g_bCvar_Molotov)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(client))
        return;

    OutputMessage(client, TYPE_MOLOTOV);
}

/****************************************************************************************************/

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bCvar_Enabled)
        return;

    if (!g_bCvar_Team)
        return;

    int weaponid = event.GetInt("weaponid");

    if (g_bL4D2)
    {
        switch (weaponid)
        {
            case L4D2_WEPID_PIPE_BOMB:
            {
                int client = GetClientOfUserId(event.GetInt("userid"));

                if (!IsValidClient(client))
                    return;

                int entity = GetPlayerWeaponSlot(client, 2);

                if (entity == -1)
                    return;

                ge_iType[entity] = TYPE_PIPEBOMB;
                ge_fLastThrown[entity] = GetGameTime();
                RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
            }
            case L4D2_WEPID_VOMITJAR:
            {
                int client = GetClientOfUserId(event.GetInt("userid"));

                if (!IsValidClient(client))
                    return;

                int entity = GetPlayerWeaponSlot(client, 2);

                if (entity == -1)
                    return;

                ge_iType[entity] = TYPE_VOMITJAR;
                ge_fLastThrown[entity] = GetGameTime();
                RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
            }
        }
    }
    else
    {
        switch (weaponid)
        {
            case L4D1_WEPID_MOLOTOV:
            {
                int client = GetClientOfUserId(event.GetInt("userid"));

                if (!IsValidClient(client))
                    return;

                int entity = GetPlayerWeaponSlot(client, 2);

                if (entity == -1)
                    return;

                ge_iType[entity] = TYPE_MOLOTOV;
                ge_fLastThrown[entity] = GetGameTime();
                RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
            }
            case L4D1_WEPID_PIPE_BOMB:
            {
                int client = GetClientOfUserId(event.GetInt("userid"));

                if (!IsValidClient(client))
                    return;

                int entity = GetPlayerWeaponSlot(client, 2);

                if (entity == -1)
                    return;

                ge_iType[entity] = TYPE_PIPEBOMB;
                ge_fLastThrown[entity] = GetGameTime();
                RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
            }
        }
    }
}

/****************************************************************************************************/

public void OnNextFrame(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    if (GetGameTime() - ge_fLastThrown[entity] > g_fCvar_FakeThrow) // Probably was a fake thrown, average time to set "m_bRedraw = 1" is 0.24 seconds
        return;

    if (GetEntProp(entity, Prop_Send, "m_bRedraw") == 0)
    {
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
        return;
    }

    int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

    if (!IsValidClient(client))
        return;

    OutputMessage(client, ge_iType[entity]);
}

/****************************************************************************************************/

void OutputMessage(int attacker, int type)
{
    switch (type)
    {
        case TYPE_MOLOTOV:
        {
            if (!g_bCvar_Molotov)
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

                PrintToChat(client, "\x04[提示]\x03%N\x05投掷了燃烧瓶!", attacker);
            }
        }

        case TYPE_PIPEBOMB:
        {
            if (!g_bCvar_Pipebomb)
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

                PrintToChat(client, "\x04[提示]\x03%N\x05投掷了土制炸弹!", attacker);
            }
        }

        case TYPE_VOMITJAR:
        {
            if (!g_bCvar_Vomitjar)
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

                PrintToChat(client, "\x04[提示]\x03%N\x05投掷了胆汁罐!", attacker);
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
    PrintToConsole(client, "--------------- Plugin Cvars (l4d_throwable_announcer) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_throwable_announcer_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_throwable_announcer_fake_throw : %.1f", g_fCvar_FakeThrow);
    PrintToConsole(client, "l4d_throwable_announcer_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_throwable_announcer_team : %i (SPECTATOR = %s | SURVIVOR = %s | INFECTED = %s | HOLDOUT = %s)", g_iCvar_Team,
    g_iCvar_Team & FLAG_TEAM_SPECTATOR ? "true" : "false", g_iCvar_Team & FLAG_TEAM_SURVIVOR ? "true" : "false", g_iCvar_Team & FLAG_TEAM_INFECTED ? "true" : "false", g_iCvar_Team & FLAG_TEAM_HOLDOUT ? "true" : "false");
    PrintToConsole(client, "l4d_throwable_announcer_self : %b (%s)", g_bCvar_Self, g_bCvar_Self ? "true" : "false");
    PrintToConsole(client, "l4d_throwable_announcer_molotov : %b (%s)", g_bCvar_Molotov, g_bCvar_Molotov ? "true" : "false");
    PrintToConsole(client, "l4d_throwable_announcer_pipebomb : %b (%s)", g_bCvar_Pipebomb, g_bCvar_Pipebomb ? "true" : "false");
    if (g_bL4D2)
        PrintToConsole(client, "l4d_throwable_announcer_vomitjar : %b (%s)", g_bCvar_Vomitjar, g_bCvar_Vomitjar ? "true" : "false");
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