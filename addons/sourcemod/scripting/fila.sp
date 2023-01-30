// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "Fila"
#define PLUGIN_AUTHOR                 "Altair"
#define PLUGIN_DESCRIPTION            "Fila"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    ""

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
    // Public Commands
    RegConsoleCmd("sm_fila", CmdFila, "Exibe a fila atual.");

    CreateTimer(60.0, TimerFila, _, TIMER_REPEAT);
}

// ====================================================================================================
// Public Commands
// ====================================================================================================
public Action CmdFila(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    GetFila(client);

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action TimerFila(Handle timer)
{
    GetFila(0);

    return Plugin_Continue;
}

/****************************************************************************************************/

public void GetFila(int caller)
{
    int specs[MAXPLAYERS+1][2];

    for (int client = 1; client <= MaxClients; client++)
    {
        specs[client][0] = client;

        if (!IsClientInGame(client))
            continue;

        if (IsFakeClient(client))
            continue;

        if (GetClientTeam(client) != 1)
            continue;

        specs[client][1] = RoundFloat(GetClientTime(client));
    }

    SortCustom2D(specs, sizeof(specs), CustomCompare);

    char buffer[250];

    for (int i = 0; i < MaxClients; i++)
    {
        if (specs[i][1] == 0)
            continue;

        if (!IsClientInGame(specs[i][0]))
            continue;

        if (buffer[0] == 0)
            FormatEx(buffer, sizeof(buffer), "\x04Fila: \x03 %N", specs[i][0]);
        else
            Format(buffer, sizeof(buffer), "%s\x01, \x03%N", buffer, specs[i][0]);
    }

    if (buffer[0] == 0)
        return;

    if (caller == 0)
    {
        for (int client = 1; client <= MaxClients; client++)
        {
            if (!IsClientInGame(client))
                continue;

            if (IsFakeClient(client))
                continue;

            SayText2(client, -1, buffer);
        }
    }
    else
        SayText2(caller, -1, buffer);
}

/****************************************************************************************************/

public int CustomCompare(int[] elem1, int[] elem2, const int[][] array, Handle hndl)
{
    if (elem2[1] == 0)
        return -1;

    if (elem1[1] > elem2[1])
        return -1;

    if (elem1[1] < elem2[1])
        return 1;

    return 0;
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


void SayText2(int client, int author, const char[] format, any ...)
{
    char message[250];
    VFormat(message, sizeof(message), format, 4);

    Handle hBuffer = StartMessageOne("SayText2", client);
    BfWriteByte(hBuffer, author);
    BfWriteByte(hBuffer, true);
    BfWriteString(hBuffer, message);
    EndMessage();
}