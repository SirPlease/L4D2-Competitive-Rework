#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define MAX_ENTITY_NAME_SIZE 64
#define MAX_MAP_NAME_SIZE 64

#define PLUGIN_TAG "l4d2_ledgeblock"

bool
    g_bIsBlockEnable = false;

float
    g_fBlockSquare[4] = {0.0, ...};

StringMap
    g_hLedgeBlockSquares = null;

public Plugin myinfo =
{
    name = "L4D2 Ledge Blocker",
    author = "ProdigySim, Estoopi, Jacob, Visor, A1m`",
    description = "Blocks ledge hanging on various maps",
    version = "1.0",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
    g_hLedgeBlockSquares = new StringMap();

    RegServerCmd("ledge_block_square", AddLedgeBlockSquare);
    RegServerCmd("ledge_remove_block_square", RemoveLedgeBlockSquare);
}

public Action AddLedgeBlockSquare(int iArgs)
{
    float fSquare[4];
    char sMapName[MAX_MAP_NAME_SIZE], sBuffer[32], sGetCmd[128];

    if (iArgs != 5)
    {
        GetCmdArgString(sGetCmd, sizeof(sGetCmd));
        ErrorAnnounce("[%s] You entered the wrong number of arguments '%f'. Need 5 arguments.", PLUGIN_TAG, sGetCmd);
        ErrorAnnounce("[%s] Usage: ledge_block_square <mapname> <x1> <y1> <x2> <y2>.", PLUGIN_TAG);
        return Plugin_Handled;
    }

    GetCmdArg(1, sMapName, sizeof(sMapName));

    for (int i = 0; i < 4; i++) {
        GetCmdArg(2 + i, sBuffer, sizeof(sBuffer));
        fSquare[i] = StringToFloat(sBuffer);
    }

    g_hLedgeBlockSquares.SetArray(sMapName, fSquare, sizeof(fSquare), true);

    OnMapStart();

    return Plugin_Handled;
}

public Action RemoveLedgeBlockSquare(int iArgs)
{
    float fSquare[4];
    char sMapName[MAX_MAP_NAME_SIZE], sGetCmd[128];

    if (iArgs != 1) {
        GetCmdArgString(sGetCmd, sizeof(sGetCmd));
        ErrorAnnounce("[%s] You entered the wrong number of arguments '%f'. Need 1 argument.", PLUGIN_TAG, sGetCmd);
        ErrorAnnounce("[%s] Usage: ledge_remove_block_square <mapname>.", PLUGIN_TAG);
        return Plugin_Handled;
    }

    GetCmdArg(1, sMapName, sizeof(sMapName));
    if (g_hLedgeBlockSquares.GetArray(sMapName, fSquare, sizeof(fSquare)))
    {
        g_hLedgeBlockSquares.Remove(sMapName);
        PrintToServer("[%s] Ledge block square removed on this map '%s'.", PLUGIN_TAG, sMapName);
    }
    else
        PrintToServer("[%s] Сould not find the specified map '%s'.", PLUGIN_TAG, sMapName);

    OnMapStart();

    return Plugin_Handled;
}

public void OnMapStart()
{
    char sMapName[MAX_MAP_NAME_SIZE];
    GetCurrentMap(sMapName, sizeof(sMapName));

    if (g_hLedgeBlockSquares.GetArray(sMapName, g_fBlockSquare, sizeof(g_fBlockSquare)))
    {
        g_bIsBlockEnable = true;
        return;
    }

    for (int i = 0; i < sizeof(g_fBlockSquare); i++)
        g_fBlockSquare[i] = 0.0;

    g_bIsBlockEnable = false;
}

public Action L4D_OnLedgeGrabbed(int client)
{
    if (!g_bIsBlockEnable)
        return Plugin_Continue;

    float fOrigin[3];
    GetClientAbsOrigin(client, fOrigin);

    if (isPointIn2DBox(fOrigin[0], fOrigin[1], g_fBlockSquare[0], g_fBlockSquare[1], g_fBlockSquare[2], g_fBlockSquare[3]))
        return Plugin_Handled;

    return Plugin_Continue;
}

// Is x0, y0 in the box defined by x1, y1 and x2, y2
bool isPointIn2DBox(float x0, float y0, float x1, float y1, float x2, float y2)
{
    if (x1 > x2) {
        if (y1 > y2) {
            return (x0 <= x1 && x0 >= x2 && y0 <= y1 && y0 >= y2);
        } else {
            return (x0 <= x1 && x0 >= x2 && y0 >= y1 && y0 <= y2);
        }
    } else {
        if(y1 > y2) {
            return (x0 >= x1 && x0 <= x2 && y0 <= y1 && y0 >= y2);
        } else {
            return (x0 >= x1 && x0 <= x2 && y0 >= y1 && y0 <= y2);
        }
    }
}

void ErrorAnnounce(const char[] szFormat, any ...)
{
    int iLen = strlen(szFormat) + 255;
    char[] szBuffer = new char[iLen];
    VFormat(szBuffer, iLen, szFormat, 2);

    LogError(szBuffer);
    PrintToServer(szBuffer);
}
