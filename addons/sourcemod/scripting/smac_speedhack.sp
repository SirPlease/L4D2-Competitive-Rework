/*
    SourceMod Anti-Cheat
    Copyright (C) 2011-2016 SMAC Development Team 
    Copyright (C) 2007-2011 CodingDirect LLC
   
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#pragma semicolon 1
#pragma newdecls required

/* SM Includes */
#include <sourcemod>
#include <sdktools>
#include <smac>

/* Plugin Info */
public Plugin myinfo =
{
    name =          "SMAC Anti-Speedhack",
    author =        SMAC_AUTHOR,
    description =   "Prevents speedhack cheats from working",
    version =       SMAC_VERSION,
    url =           SMAC_URL
};

/* Globals */
int g_iTicksLeft[MAXPLAYERS+1];
int g_iMaxTicks;

#define MAX_DETECTIONS 30
int g_iDetections[MAXPLAYERS+1];
float g_fDetectedTime[MAXPLAYERS+1];
float g_fPrevLatency[MAXPLAYERS+1];

/* Plugin Functions */
public void OnPluginStart()
{
    LoadTranslations("smac.phrases");

    // The server's tickrate * 2.0 as a buffer zone.
    g_iMaxTicks = RoundToCeil(1.0 / GetTickInterval() * 2.0);

    for (int i = 0; i < sizeof(g_iTicksLeft); i++)
    {
        g_iTicksLeft[i] = g_iMaxTicks;
    }

    CreateTimer(0.1, Timer_AddTicks, _, TIMER_REPEAT);
}

public void OnClientConnected(int client)
{
    g_iTicksLeft[client] = g_iMaxTicks;
    g_iDetections[client] = 0;
    g_fDetectedTime[client] = 0.0;
    g_fPrevLatency[client] = 0.0;
}

public Action Timer_AddTicks(Handle timer)
{
    static float fLastProcessed;
    int iNewTicks = RoundToCeil((GetEngineTime() - fLastProcessed) / GetTickInterval());

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            // Make sure latency didn't spike more than 5ms.
            // We want to avoid writing a lagging client to logs.
            float fLatency = GetClientLatency(i, NetFlow_Outgoing);

            if (!g_iTicksLeft[i] && FloatAbs(g_fPrevLatency[i] - fLatency) <= 0.005)
            {
                if (++g_iDetections[i] >= MAX_DETECTIONS && GetGameTime() > g_fDetectedTime[i])
                {
                    if (SMAC_CheatDetected(i, Detection_Speedhack, INVALID_HANDLE) == Plugin_Continue)
                    {
                        SMAC_PrintAdminNotice("%t", "SMAC_SpeedhackDetected", i);

                        // Only log once per connection.
                        if (g_fDetectedTime[i] == 0.0)
                        {
                            SMAC_LogAction(i, "is suspected of using speedhack.");
                        }
                    }

                    g_fDetectedTime[i] = GetGameTime() + 30.0;
                }
            }
            else if (g_iDetections[i])
            {
                g_iDetections[i]--;
            }

            g_fPrevLatency[i] = fLatency;
        }

        if ((g_iTicksLeft[i] += iNewTicks) > g_iMaxTicks)
        {
            g_iTicksLeft[i] = g_iMaxTicks;
        }
    }

    fLastProcessed = GetEngineTime();
    return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{   
    if (!IsClientInGame(client))
    {
        return Plugin_Handled;
    }

    if (!g_iTicksLeft[client])
    {
        return Plugin_Handled;
    }

    if (IsPlayerAlive(client))
    {
        g_iTicksLeft[client]--;
    }

    return Plugin_Continue;
}
