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
    name =          "SMAC AutoTrigger Detector",
    author =        SMAC_AUTHOR,
    description =   "Detects cheats that automatically press buttons for players",
    version =       SMAC_VERSION,
    url =           SMAC_URL
};

/* Globals */
#define TRIGGER_DETECTIONS  20		// Amount of detections needed to perform action.
#define MIN_JUMP_TIME       0.500	// Minimum amount of air-time for a jump to count.

// Detection methods.
#define METHOD_BUNNYHOP     0
#define METHOD_AUTOFIRE     1
#define METHOD_MAX          2

ConVar g_hCvarBan = null;
int g_iDetections[METHOD_MAX][MAXPLAYERS+1];
int g_iAttackMax = 66;

/* Plugin Functions */
public void OnPluginStart()
{
    LoadTranslations("smac.phrases");

    // Convars.
    g_hCvarBan = SMAC_CreateConVar("smac_autotrigger_ban", "0", "Automatically ban players on auto-trigger detections.", 0, true, 0.0, true, 1.0);

    // Initialize.
    g_iAttackMax = RoundToNearest(1.0 / GetTickInterval() / 3.0);
    CreateTimer(4.0, Timer_DecreaseCount, _, TIMER_REPEAT);
}

public void OnClientDisconnect_Post(int client)
{
    for (int i = 0; i < METHOD_MAX; i++)
    {
        g_iDetections[i][client] = 0;
    }
}

public Action Timer_DecreaseCount(Handle timer)
{
    for (int i = 0; i < METHOD_MAX; i++)
    {
        for (int j = 1; j <= MaxClients; j++)
        {
            if (g_iDetections[i][j])
            {
                g_iDetections[i][j]--;
            }
        }
    }

    return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    static int iPrevButtons[MAXPLAYERS+1];

    /* BunnyHop */
    static float fCheckTime[MAXPLAYERS+1];

    // Player didn't jump immediately after the last jump.
    if (!(buttons & IN_JUMP) && (GetEntityFlags(client) & FL_ONGROUND) && fCheckTime[client] > 0.0)
    {
        fCheckTime[client] = 0.0;
    }

    // Ignore this jump if the player is in a tight space or stuck in the ground.
    if ((buttons & IN_JUMP) && !(iPrevButtons[client] & IN_JUMP))
    {
        // Player is on the ground and about to trigger a jump.
        if (GetEntityFlags(client) & FL_ONGROUND)
        {
            float fGameTime = GetGameTime();

            // Player jumped on the exact frame that allowed it.
            if (fCheckTime[client] > 0.0 && fGameTime > fCheckTime[client])
            {
                AutoTrigger_Detected(client, METHOD_BUNNYHOP);
            }
            else
            {
                fCheckTime[client] = fGameTime + MIN_JUMP_TIME;
            }
        }
        else
        {
            fCheckTime[client] = 0.0;
        }
    }

    /* Auto-Fire */
    static int iAttackAmt[MAXPLAYERS+1];
    static bool bResetNext[MAXPLAYERS+1];

    if (((buttons & IN_ATTACK) && !(iPrevButtons[client] & IN_ATTACK)) || 
        (!(buttons & IN_ATTACK) && (iPrevButtons[client] & IN_ATTACK)))
    {
        if (++iAttackAmt[client] >= g_iAttackMax)
        {
            AutoTrigger_Detected(client, METHOD_AUTOFIRE);
            iAttackAmt[client] = 0;
        }

        bResetNext[client] = false;
    }
    else if (bResetNext[client])
    {
        iAttackAmt[client] = 0;
        bResetNext[client] = false;
    }
    else
    {
        bResetNext[client] = true;
    }

    iPrevButtons[client] = buttons;

    return Plugin_Continue;
}

void AutoTrigger_Detected(int client,int method)
{
    if (!IsFakeClient(client) && IsPlayerAlive(client) && ++g_iDetections[method][client] >= TRIGGER_DETECTIONS)
    {
        char sMethod[32];

        switch (method)
        {
            case METHOD_BUNNYHOP:
            {
                strcopy(sMethod, sizeof(sMethod), "BunnyHop");
            }
            case METHOD_AUTOFIRE:
            {
                strcopy(sMethod, sizeof(sMethod), "Auto-Fire");
            }
        }

        Handle info = CreateKeyValues("");
        KvSetString(info, "method", sMethod);

        if (SMAC_CheatDetected(client, Detection_AutoTrigger, info) == Plugin_Continue)
        {
            SMAC_PrintAdminNotice("%t", "SMAC_AutoTriggerDetected", client, sMethod);

            if (GetConVarBool(g_hCvarBan))
            {
                SMAC_LogAction(client, "was banned for using auto-trigger cheat: %s", sMethod);
                SMAC_Ban(client, "AutoTrigger Detection: %s", sMethod);
            }
            else
            {
                SMAC_LogAction(client, "is suspected of using auto-trigger cheat: %s", sMethod);
            }
        }

        CloseHandle(info);

        g_iDetections[method][client] = 0;
    }
}