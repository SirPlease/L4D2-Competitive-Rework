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
#include <sdkhooks>
#include <smac>

/* Plugin Info */
public Plugin myinfo =
{
    name =          "SMAC CS:S Anti-Smoke",
    author =        SMAC_AUTHOR,
    description =   "Prevents anti-smoke cheats from working",
    version =       SMAC_VERSION,
    url =           SMAC_URL
};

/* Globals */
#define SMOKE_DELAYTIME	0.75	// Seconds until smoke is fully deployed
#define SMOKE_FADETIME	15.0	// Seconds until a smoke begins to fade away
#define SMOKE_RADIUS	2025	// (45^2) Radius to check for a player inside a smoke cloud

Handle g_hSmokeLoop = INVALID_HANDLE;
Handle g_hSmokes = INVALID_HANDLE;
bool g_bIsInSmoke[MAXPLAYERS+1];
int g_iRoundCount;

/* Plugin Functions */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if (GetEngineVersion() != Engine_CSS)
    {
        strcopy(error, err_max, SMAC_MOD_ERROR);
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

public void OnPluginStart()
{
    g_hSmokes = CreateArray(3);

    // Hooks.
    HookEvent("smokegrenade_detonate", Event_SmokeDetonate, EventHookMode_Post);
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void OnMapEnd()
{
    AntiSmoke_UnhookAll();
    g_iRoundCount = 0;
}

public void OnClientPutInServer(int client)
{
    if (g_hSmokeLoop != INVALID_HANDLE)
    {
        SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
    }
}

public void OnClientDisconnect(int client)
{
    g_bIsInSmoke[client] = false;
}

public Action Event_SmokeDetonate(Event event, const char[] name, bool dontBroadcast)
{
    /* Delay immersion tests until smoke is fully deployed. */
    Handle hPack;
    CreateDataTimer(SMOKE_DELAYTIME, Timer_SmokeDeployed, hPack, TIMER_FLAG_NO_MAPCHANGE);
    WritePackCell(hPack, g_iRoundCount);
    WritePackFloat(hPack, GetEventFloat(event, "x"));
    WritePackFloat(hPack, GetEventFloat(event, "y"));
    WritePackFloat(hPack, GetEventFloat(event, "z"));

    CreateTimer(SMOKE_FADETIME, Timer_SmokeEnded, g_iRoundCount, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    /* Smokes disappear on round start. */
    AntiSmoke_UnhookAll();
    g_iRoundCount++;
}

public Action Timer_SmokeDeployed(Handle timer, Handle hPack)
{
    ResetPack(hPack);
	
    /* Make sure the smoke still exists. */
    if (g_iRoundCount == ReadPackCell(hPack))
    {
        float vSmoke[3];
        vSmoke[0] = ReadPackFloat(hPack);
        vSmoke[1] = ReadPackFloat(hPack);
        vSmoke[2] = ReadPackFloat(hPack);

        PushArrayArray(g_hSmokes, vSmoke);

        AntiSmoke_HookAll();
    }

    return Plugin_Stop;
}

public Action Timer_SmokeEnded(Handle timer, any iRoundCount)
{
    /* Make sure we're tampering with the right smokes. */
    if (g_iRoundCount == iRoundCount)
    {
        /* If this was the last active smoke, unhook everything. */
        if (GetArraySize(g_hSmokes))
        {
            RemoveFromArray(g_hSmokes, 0);
        }

        if (!GetArraySize(g_hSmokes))
        {
            AntiSmoke_UnhookAll();
        }
    }

    return Plugin_Stop;
}

public Action Timer_SmokeCheck(Handle timer)
{
    /* Check if a player is immersed in a smoke. */
    float vClient[3], vSmoke[3];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            GetClientAbsOrigin(i, vClient);
            g_bIsInSmoke[i] = false;

            for (int idx = 0; idx < GetArraySize(g_hSmokes); idx++)
            {
                GetArrayArray(g_hSmokes, idx, vSmoke);

                if (GetVectorDistance(vClient, vSmoke, true) < SMOKE_RADIUS)
                {
                    g_bIsInSmoke[i] = true;
                    break;
                }
            }
        }
    }

    return Plugin_Continue;
}

public Action Hook_SetTransmit(int entity, int client)
{
    /* Don't send client data to players that are immersed in smoke. */
    if (entity != client && g_bIsInSmoke[client])
    {
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

void AntiSmoke_HookAll()
{
    if (g_hSmokeLoop != INVALID_HANDLE)
    {
        return;
    }

    g_hSmokeLoop = CreateTimer(0.1, Timer_SmokeCheck, _, TIMER_REPEAT);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_SetTransmit, Hook_SetTransmit);
        }
    }
}

void AntiSmoke_UnhookAll()
{
    if (g_hSmokeLoop == INVALID_HANDLE)
    {
        return;
    }
    
    KillTimer(g_hSmokeLoop);
    g_hSmokeLoop = INVALID_HANDLE;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            g_bIsInSmoke[i] = false;
            SDKUnhook(i, SDKHook_SetTransmit, Hook_SetTransmit);
        }
    }

    ClearArray(g_hSmokes);
}