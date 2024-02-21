/**
// ====================================================================================================
Change Log:

1.0.2 (13-February-2023)
    - Added "random", "default" and "disable" options to menu.

1.0.1 (12-February-2023)
    - Public release.

1.0.0 (20-December-2022)
    - Private release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Jump Beam Ring"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Creates a colored beam ring on player jump"
#define PLUGIN_VERSION                "1.0.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=341804"

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
#include <clientprefs>
#include <readyup>

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
#define CONFIG_FILENAME               "l4d_jump_beamring"

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

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar l4d_jump_beamring_version;
    ConVar l4d_jump_beamring_enable;
    ConVar l4d_jump_beamring_model;
    ConVar l4d_jump_beamring_color;
    ConVar l4d_jump_beamring_alpha;
    ConVar l4d_jump_beamring_duration;
    ConVar l4d_jump_beamring_start_radius;
    ConVar l4d_jump_beamring_end_radius;
    ConVar l4d_jump_beamring_width;
    ConVar l4d_jump_beamring_amplitude;
    ConVar l4d_jump_beamring_offset;
    ConVar l4d_jump_beamring_team;

    void Init()
    {
        this.l4d_jump_beamring_version      = CreateConVar("l4d_jump_beamring_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.l4d_jump_beamring_enable       = CreateConVar("l4d_jump_beamring_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_jump_beamring_model        = CreateConVar("l4d_jump_beamring_model", "sprites/laserbeam.vmt", "Beam model.");
        this.l4d_jump_beamring_color        = CreateConVar("l4d_jump_beamring_color", "random", "Beam color.\nUse \"random\" for random colors.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\").", CVAR_FLAGS);
        this.l4d_jump_beamring_alpha        = CreateConVar("l4d_jump_beamring_alpha", "255", "Beam alpha transparency.\n0 = Invisible, 255 = Fully Visible.", CVAR_FLAGS, true, 0.0, true, 255.0);
        this.l4d_jump_beamring_duration     = CreateConVar("l4d_jump_beamring_duration", "1.0", "Beam duration (seconds).", CVAR_FLAGS, true, 0.1);
        this.l4d_jump_beamring_start_radius = CreateConVar("l4d_jump_beamring_start_radius", "35.0", "Beam start radius.", CVAR_FLAGS, true, 0.0);
        this.l4d_jump_beamring_end_radius   = CreateConVar("l4d_jump_beamring_end_radius", "70.0", "Beam end radius.", CVAR_FLAGS, true, 0.0);
        this.l4d_jump_beamring_width        = CreateConVar("l4d_jump_beamring_width", "1.0", "Beam width.", CVAR_FLAGS, true, 0.0);
        this.l4d_jump_beamring_amplitude    = CreateConVar("l4d_jump_beamring_amplitude", "0.0", "Beam amplitude.", CVAR_FLAGS, true, 0.0);
        this.l4d_jump_beamring_offset       = CreateConVar("l4d_jump_beamring_offset", "24.0", "Beam offset (Z index) from client's foot.", CVAR_FLAGS, true, 0.0);
        this.l4d_jump_beamring_team         = CreateConVar("l4d_jump_beamring_team", "5", "Which teams can trigger the beam.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);

        this.l4d_jump_beamring_enable.AddChangeHook(Event_ConVarChanged);
        this.l4d_jump_beamring_model.AddChangeHook(Event_ConVarChanged);
        this.l4d_jump_beamring_color.AddChangeHook(Event_ConVarChanged);
        this.l4d_jump_beamring_alpha.AddChangeHook(Event_ConVarChanged);
        this.l4d_jump_beamring_duration.AddChangeHook(Event_ConVarChanged);
        this.l4d_jump_beamring_start_radius.AddChangeHook(Event_ConVarChanged);
        this.l4d_jump_beamring_end_radius.AddChangeHook(Event_ConVarChanged);
        this.l4d_jump_beamring_width.AddChangeHook(Event_ConVarChanged);
        this.l4d_jump_beamring_amplitude.AddChangeHook(Event_ConVarChanged);
        this.l4d_jump_beamring_offset.AddChangeHook(Event_ConVarChanged);
        this.l4d_jump_beamring_team.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/
bool g_enb;
public void OnRoundIsLive()
{
    g_enb = false;
}

public void OnReadyUpInitiate()
{
    g_enb = true;
}
/****************************************************************************************************/
enum struct PluginCookies
{
    Cookie g_cColor;

    void Init()
    {
        this.g_cColor = new Cookie("l4d_jump_beamring_color", "Jump Beam Ring Color", CookieAccess_Protected);

        for (int client = 1; client <= MaxClients; client++)
        {
            if (!IsClientInGame(client))
                continue;

            if (IsFakeClient(client))
                continue;

            if (AreClientCookiesCached(client))
                OnClientCookiesCached(client);
        }
    }
}

/****************************************************************************************************/

enum struct ClientData
{
    bool manual;
    bool disable;
    bool random;
    int color[3];
    char sColor[12];
}

ClientData clients[MAXPLAYERS+1];

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;
    PluginCookies cookies;

    bool eventsHooked;
    bool enabled;
    char model[PLATFORM_MAX_PATH];
    int modelIndex;
    char sColor[12];
    bool randomColor;
    int color[3];
    int alpha;
    float duration;
    float startRadius;
    float endRadius;
    float width;
    float amplitude;
    float offset;
    int team;

    void Init()
    {
        this.cvars.Init();
        this.cookies.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enabled = this.cvars.l4d_jump_beamring_enable.BoolValue;
        this.cvars.l4d_jump_beamring_model.GetString(this.model, sizeof(this.model));
        TrimString(this.model);
        if (this.model[0] != 0)
            plugin.modelIndex = PrecacheModel(plugin.model, true);
        this.cvars.l4d_jump_beamring_color.GetString(this.sColor, sizeof(this.sColor));
        TrimString(this.sColor);
        this.randomColor = StrEqual(this.sColor, "random", false);
        this.color = ConvertRGBToIntArray(this.sColor);
        this.alpha = this.cvars.l4d_jump_beamring_alpha.IntValue;
        this.duration = this.cvars.l4d_jump_beamring_duration.FloatValue;
        this.startRadius = this.cvars.l4d_jump_beamring_start_radius.FloatValue;
        this.endRadius = this.cvars.l4d_jump_beamring_end_radius.FloatValue;
        this.width = this.cvars.l4d_jump_beamring_width.FloatValue;
        this.amplitude = this.cvars.l4d_jump_beamring_amplitude.FloatValue;
        this.offset = this.cvars.l4d_jump_beamring_offset.FloatValue;
        this.team = this.cvars.l4d_jump_beamring_team.IntValue;
    }

    void RegisterCmds()
    {
        RegConsoleCmd("sm_jumpcolor", CmdBeamJumpColor, "Open a menu to client select their jump beam ring color. Usage: sm_jumpcolor <255> <255> <255>");
        RegAdminCmd("sm_print_cvars_l4d_jump_beamring", Cmd_PrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
    }
}

// ====================================================================================================
// Menu - Plugin Variables
// ====================================================================================================
Menu g_hColorMenu;

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

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    BuildMenus();
    plugin.Init();
}

/****************************************************************************************************/

void BuildMenus()
{
    g_hColorMenu = new Menu(MenuHandlerColor);
    g_hColorMenu.ExitBackButton = true;
    g_hColorMenu.AddItem("random", "Random");
    g_hColorMenu.AddItem("255 0 0", "Red");
    g_hColorMenu.AddItem("0 255 0", "Green");
    g_hColorMenu.AddItem("0 0 255", "Blue");
    g_hColorMenu.AddItem("255 255 0", "Yellow");
    g_hColorMenu.AddItem("0 255 255", "Cyan");
    g_hColorMenu.AddItem("155 0 255", "Purple");
    g_hColorMenu.AddItem("255 155 0", "Orange");
    g_hColorMenu.AddItem("255 255 255", "White");
    g_hColorMenu.AddItem("255 0 155", "Pink");
    g_hColorMenu.AddItem("128 255 0", "Lime");
    g_hColorMenu.AddItem("128 0 0", "Maroon");
    g_hColorMenu.AddItem("0 128 128", "Teal");
    g_hColorMenu.AddItem("128 128 128", "Grey");
    g_hColorMenu.AddItem("default", "Default");
    g_hColorMenu.AddItem("disable", "Disable");
}

/****************************************************************************************************/

int MenuHandlerColor(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            int client = param1;
            int index = param2;

            char sColor[12];
            menu.GetItem(index, sColor, sizeof(sColor));
            FakeClientCommand(client, "sm_jumpcolor %s", sColor);
            g_hColorMenu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
        }
    }

    return 0;
}

/****************************************************************************************************/

public void OnMapStart()
{
    if (plugin.enabled && plugin.model[0] != 0)
        plugin.modelIndex = PrecacheModel(plugin.model, true);
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    plugin.GetCvarValues();

    HookEvents();
}

/****************************************************************************************************/

public void OnClientCookiesCached(int client)
{
    if (IsFakeClient(client))
        return;

    char sColor[12];
    plugin.cookies.g_cColor.Get(client, sColor, sizeof(sColor));

    if (sColor[0] == 0)
        return;

    clients[client].manual = true;
    strcopy(clients[client].sColor, 12, sColor);

    if (StrEqual(sColor, "random", false))
    {
        clients[client].random = true;
    }
    else if (StrEqual(sColor, "disable", false))
    {
        clients[client].disable = true;
    }
    else
    {
        int color = StringToInt(sColor);

        int rgb[3];
        rgb[0] = ((color >> 00) & 0xFF);
        rgb[1] = ((color >> 08) & 0xFF);
        rgb[2] = ((color >> 16) & 0xFF);

        clients[client].color = rgb;
    }
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    clients[client].manual = false;
    clients[client].disable = false;
    clients[client].random = false;
    clients[client].color[0] = 0;
    clients[client].color[1] = 0;
    clients[client].color[2] = 0;
    clients[client].sColor = "";
}

/****************************************************************************************************/

void HookEvents()
{
    if (plugin.enabled && !plugin.eventsHooked)
    {
        plugin.eventsHooked = true;

        HookEvent("player_jump", Event_PlayerJump);

        return;
    }

    if (!plugin.enabled && plugin.eventsHooked)
    {
        plugin.eventsHooked = false;

        UnhookEvent("player_jump", Event_PlayerJump);

        return;
    }
}

/****************************************************************************************************/

public void Event_PlayerJump(Handle event, char[] error, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (client == 0)
        return;

    int clientTeam = GetClientTeam(client);

    if (!(GetTeamFlag(clientTeam) & plugin.team))
        return;

    float vPos[3];
    GetClientAbsOrigin(client, vPos);
    vPos[2] += plugin.offset;

    int color[4];
    if (clients[client].manual)
    {
        if (!clients[client].disable)
        {
            if (clients[client].random)
            {
                color[0] = GetRandomInt(0, 255);
                color[1] = GetRandomInt(0, 255);
                color[2] = GetRandomInt(0, 255);
            }
            else
            {
                color[0] = clients[client].color[0];
                color[1] = clients[client].color[1];
                color[2] = clients[client].color[2];
            }
        }
    }
    else
    {
        if (plugin.randomColor)
        {
            color[0] = GetRandomInt(0, 255);
            color[1] = GetRandomInt(0, 255);
            color[2] = GetRandomInt(0, 255);
        }
        else
        {
            color = plugin.color;
        }
    }
    color[3] = plugin.alpha;

    int[] targets = new int[MaxClients];
    int targetsCount;

    for (int target = 1; target <= MaxClients; target++)
    {
        if (!IsClientInGame(target))
            continue;

        if (IsFakeClient(target))
            continue;

        if (GetClientTeam(target) != clientTeam)
            continue;

        targets[targetsCount++] = target;
    }
    if (g_enb){
        TE_SetupBeamRingPoint(vPos, plugin.startRadius, plugin.endRadius, plugin.modelIndex, 0, 0, 0, plugin.duration, plugin.width, plugin.amplitude, color, 0, 0);
        TE_Send(targets, targetsCount);
    }
}

// ====================================================================================================
// Commands
// ====================================================================================================
Action CmdBeamJumpColor(int client, int args)
{
    if (!plugin.enabled)
        return Plugin_Handled;

    if (!IsValidClient(client))
        return Plugin_Handled;

    if (args == 0)
    {
        g_hColorMenu.Display(client, MENU_TIME_FOREVER);
        return Plugin_Handled;
    }

    char sArg1[12];
    GetCmdArg(1, sArg1, sizeof(sArg1));

    if (StrEqual(sArg1, "default", false))
    {
        clients[client].manual = false;
        clients[client].disable = false;
        clients[client].random = false;
        clients[client].color[0] = 0;
        clients[client].color[1] = 0;
        clients[client].color[2] = 0;
        clients[client].sColor = "";

        plugin.cookies.g_cColor.Set(client, clients[client].sColor);
    }
    else if (StrEqual(sArg1, "random", false))
    {
        clients[client].manual = true;
        clients[client].disable = false;
        clients[client].random = true;
        clients[client].color[0] = 0;
        clients[client].color[1] = 0;
        clients[client].color[2] = 0;
        clients[client].sColor = "random";

        plugin.cookies.g_cColor.Set(client, clients[client].sColor);
    }
    else if (StrEqual(sArg1, "disable", false))
    {
        clients[client].manual = false;
        clients[client].disable = true;
        clients[client].random = false;
        clients[client].color[0] = 0;
        clients[client].color[1] = 0;
        clients[client].color[2] = 0;
        clients[client].sColor = "disable";

        plugin.cookies.g_cColor.Set(client, clients[client].sColor);
    }
    else
    {
        char sRed[4];
        GetCmdArg(1, sRed, sizeof(sRed));
        int red = StringToInt(sRed);

        char sGreen[4];
        GetCmdArg(2, sGreen, sizeof(sGreen));
        int green = StringToInt(sGreen);

        char sBlue[4];
        GetCmdArg(3, sBlue, sizeof(sBlue));
        int blue = StringToInt(sBlue);

        int rgb = red + (green * 256) + (blue * 65536);

        char sColor[12];
        IntToString(rgb, sColor, sizeof(sColor));

        clients[client].manual = true;
        clients[client].random = false;
        clients[client].color[0] = red;
        clients[client].color[1] = green;
        clients[client].color[2] = blue;
        clients[client].sColor = sColor;

        plugin.cookies.g_cColor.Set(client, clients[client].sColor);
    }

    return Plugin_Handled;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action Cmd_PrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "------------------ Plugin Cvars (l4d_jump_beamring) ------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_jump_beamring_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_jump_beamring_enable : %b (%s)", plugin.enabled, plugin.enabled ? "true" : "false");
    PrintToConsole(client, "l4d_jump_beamring_model : \"%s\"", plugin.model);
    PrintToConsole(client, "l4d_jump_beamring_color : \"%s\"", plugin.sColor);
    PrintToConsole(client, "l4d_jump_beamring_alpha : %i", plugin.alpha);
    PrintToConsole(client, "l4d_jump_beamring_duration : %.1f", plugin.duration);
    PrintToConsole(client, "l4d_jump_beamring_start_radius : %.1f", plugin.startRadius);
    PrintToConsole(client, "l4d_jump_beamring_end_radius : %.1f", plugin.endRadius);
    PrintToConsole(client, "l4d_jump_beamring_width : %.1f", plugin.width);
    PrintToConsole(client, "l4d_jump_beamring_amplitude : %.1f", plugin.amplitude);
    PrintToConsole(client, "l4d_jump_beamring_offset : %.1f", plugin.offset);
    PrintToConsole(client, "l4d_jump_beamring_team : %i (SPECTATOR = %s | SURVIVOR = %s | INFECTED = %s | HOLDOUT = %s)", plugin.team,
    plugin.team & FLAG_TEAM_SPECTATOR ? "true" : "false", plugin.team & FLAG_TEAM_SURVIVOR ? "true" : "false", plugin.team & FLAG_TEAM_INFECTED ? "true" : "false", plugin.team & FLAG_TEAM_HOLDOUT ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------------------- Client Cookies ---------------------------");
    PrintToConsole(client, "");
    for (int target = 1; target <= MaxClients; target++)
    {
        if (!IsClientInGame(target))
            continue;

        if (IsFakeClient(target))
            continue;

        if (!AreClientCookiesCached(target))
            continue;

        PrintToConsole(client, "%N\nl4d_jump_beamring_color: %i %i %i (%s)", target, clients[target].color[0], clients[target].color[1], clients[target].color[2], clients[target].sColor);
    }
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