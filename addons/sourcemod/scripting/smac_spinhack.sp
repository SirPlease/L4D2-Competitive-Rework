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
    name =          "SMAC Spinhack Detector",
    author =        SMAC_AUTHOR,
    description =   "Monitors players to detect the use of spinhacks",
    version =       SMAC_VERSION,
    url =           SMAC_URL
};

/* Globals */
#define SPIN_DETECTIONS     15		// Seconds of non-stop spinning before spinhack is detected
#define SPIN_ANGLE_CHANGE   1440.0	// Max angle deviation over one second before being flagged
#define SPIN_SENSITIVITY    6		// Ignore players with a higher mouse sensitivity than this

float g_fPrevAngle[MAXPLAYERS+1];
float g_fAngleDiff[MAXPLAYERS+1];
float g_fAngleBuffer;
float g_fSensitivity[MAXPLAYERS+1];

int g_iSpinCount[MAXPLAYERS+1];

/* Plugin Functions */
public void OnPluginStart()
{
    LoadTranslations("smac.phrases");

    CreateTimer(1.0, Timer_CheckSpins, _, TIMER_REPEAT);
}

public void OnClientDisconnect(int client)
{
    g_iSpinCount[client] = 0;
    g_fSensitivity[client] = 0.0;
}

public Action Timer_CheckSpins(Handle timer)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
        {
            continue;
        }

        if (g_fAngleDiff[i] > SPIN_ANGLE_CHANGE && IsPlayerAlive(i))
        {
            g_iSpinCount[i]++;

            if (g_iSpinCount[i] == 1)
            {
                QueryClientConVar(i, "sensitivity", Query_MouseCheck, GetClientSerial(i));
            }

            if (g_iSpinCount[i] == SPIN_DETECTIONS && g_fSensitivity[i] <= SPIN_SENSITIVITY)
            {
                Spinhack_Detected(i);
            }
        }
        else
        {
            g_iSpinCount[i] = 0;
        }

        g_fAngleDiff[i] = 0.0;
    }

    return Plugin_Continue;
}

public void Query_MouseCheck(QueryCookie cookie,int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any serial)
{
    if (result == ConVarQuery_Okay && GetClientFromSerial(serial) == client)
    {
        g_fSensitivity[client] = StringToFloat(cvarValue);
    }
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if (!(buttons & IN_LEFT || buttons & IN_RIGHT))
    {
        // Only checking the Z axis here.
        g_fAngleBuffer = FloatAbs(angles[1] - g_fPrevAngle[client]);
        g_fAngleDiff[client] += (g_fAngleBuffer > 180.0) ? (g_fAngleBuffer - 360.0) * -1.0 : g_fAngleBuffer;
        g_fPrevAngle[client] = angles[1];
    }

    return Plugin_Continue;
}

void Spinhack_Detected(int client)
{
    if (SMAC_CheatDetected(client, Detection_Spinhack, INVALID_HANDLE) == Plugin_Continue)
    {
        SMAC_PrintAdminNotice("%t", "SMAC_SpinhackDetected", client);
        SMAC_LogAction(client, "is suspected of using a spinhack.");
    }
}