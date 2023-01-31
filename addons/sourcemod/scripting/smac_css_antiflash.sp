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
    name =          "SMAC CS:S Anti-Flash",
    author =        SMAC_AUTHOR,
    description =   "Prevents anti-flashbang cheats from working",
    version =       SMAC_VERSION,
    url =           SMAC_URL
};

/* Globals */
float g_fFlashedUntil[MAXPLAYERS+1];
bool g_bFlashHooked = false;

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
    // Hooks.
    HookEvent("player_blind", Event_PlayerBlind, EventHookMode_Post);
}

public void OnClientPutInServer(int client)
{
    if (g_bFlashHooked)
    {
        SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
    }
}

public void OnClientDisconnect(int client)
{
    g_fFlashedUntil[client] = 0.0;
}

public Action Event_PlayerBlind(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IS_CLIENT(client) && !IsFakeClient(client))
    {
        float alpha = GetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha");

        if (alpha < 255.0)
        {
            // New flashes override previous ones.
            g_fFlashedUntil[client] = 0.0;
            return;
        }

        float duration = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");

        if (duration > 2.9)
        {
            g_fFlashedUntil[client] = GetGameTime() + duration - 2.9;
        }
        else
        {
            g_fFlashedUntil[client] = GetGameTime() + duration * 0.1;
        }

        // Fade in the flash.
        SendMsgFadeUser(client, RoundToNearest(duration * 1000.0));

        if (!g_bFlashHooked)
        {
            AntiFlash_HookAll();
        }

        CreateTimer(duration, Timer_FlashEnded);
    }
}

public Action Timer_FlashEnded(Handle timer)
{
    /* Check if there are any other flashes being processed. Otherwise, we can unhook. */
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_fFlashedUntil[i])
        {
            return Plugin_Stop;
        }
    }

    if (g_bFlashHooked)
    {
        AntiFlash_UnhookAll();
    }

    return Plugin_Stop;
}

public Action Hook_SetTransmit(int entity, int client)
{
    /* Don't send client data to players that are fully blind. */
    if (g_fFlashedUntil[client])
    {
        if (g_fFlashedUntil[client] > GetGameTime())
        {
            return (entity == client) ? Plugin_Continue : Plugin_Handled;
        }

        // Fade out the flash.
        SendMsgFadeUser(client, 0);
        g_fFlashedUntil[client] = 0.0;
    }

    return Plugin_Continue;
}

void AntiFlash_HookAll()
{
    g_bFlashHooked = true;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_SetTransmit, Hook_SetTransmit);
        }
    }
}

void AntiFlash_UnhookAll()
{
    g_bFlashHooked = false;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKUnhook(i, SDKHook_SetTransmit, Hook_SetTransmit);
        }
    }
}

void SendMsgFadeUser(int client,int duration)
{
    static UserMsg msgFadeUser = INVALID_MESSAGE_ID;

    if (msgFadeUser == INVALID_MESSAGE_ID)
    {
        msgFadeUser = GetUserMessageId("Fade");
    }

    int players[1];
    players[0] = client;

    Handle bf = StartMessageEx(msgFadeUser, players, 1);
    BfWriteShort(bf, (duration > 0) ? duration : 50); // duration
    BfWriteShort(bf, (duration > 0) ? 1000 : 0); // hold time
    BfWriteShort(bf, FFADE_IN|FFADE_PURGE);
    BfWriteByte(bf, 255); // r
    BfWriteByte(bf, 255); // g
    BfWriteByte(bf, 255); // b
    BfWriteByte(bf, 255); // a

    EndMessage();
}