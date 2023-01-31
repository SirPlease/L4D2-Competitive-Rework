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
    name =          "SMAC CS:S Exploit Fixes",
    author =        SMAC_AUTHOR,
    description =   "Blocks general Counter-Strike: Source exploits",
    version =       SMAC_VERSION,
    url =           SMAC_URL
};

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
    LoadTranslations("smac.phrases");

    ConVar hCvar = null;

    hCvar = SMAC_CreateConVar("smac_css_defusefix", "1", "Block illegal defuses.", 0, true, 0.0, true, 1.0);
    OnDefuseFixChanged(hCvar, "", "");
    HookConVarChange(hCvar, OnDefuseFixChanged);

    hCvar = SMAC_CreateConVar("smac_css_respawnfix", "1", "Block players from respawning through rejoins.", 0, true, 0.0, true, 1.0);
    OnRespawnFixChanged(hCvar, "", "");
    HookConVarChange(hCvar, OnRespawnFixChanged);
}

public void OnMapStart()
{
    ClearDefuseData();
}

public void OnMapEnd()
{
    ClearSpawnData();
}

/**
 * Defuse Fix
 */
bool g_bDefuseFixEnabled;
float g_fNextCheck[MAXPLAYERS+1];
bool g_bAllowDefuse[MAXPLAYERS+1];

int g_iDefuserEnt = -1;
float g_vBombPos[3];

public void OnDefuseFixChanged(ConVar convar, char[] oldValue, char[] newValue)
{
    bool bNewValue = convar.BoolValue;
    if (bNewValue && !g_bDefuseFixEnabled)
    {
        HookEvent("bomb_planted", Event_BombPlanted, EventHookMode_PostNoCopy);
        HookEvent("bomb_begindefuse", Event_BombBeginDefuse, EventHookMode_Post);

        HookEvent("round_start", Event_ResetDefuser, EventHookMode_PostNoCopy);
        HookEvent("bomb_abortdefuse", Event_ResetDefuser, EventHookMode_PostNoCopy);

        BombPlanted();
    }
    else if (!bNewValue && g_bDefuseFixEnabled)
    {
        UnhookEvent("bomb_planted", Event_BombPlanted, EventHookMode_PostNoCopy);
        UnhookEvent("bomb_begindefuse", Event_BombBeginDefuse, EventHookMode_Post);

        UnhookEvent("round_start", Event_ResetDefuser, EventHookMode_PostNoCopy);
        UnhookEvent("bomb_abortdefuse", Event_ResetDefuser, EventHookMode_PostNoCopy);

        ClearDefuseData();
    }
    g_bDefuseFixEnabled = bNewValue;
}

void ClearDefuseData()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        g_fNextCheck[i] = 0.0;
    }
    g_iDefuserEnt = -1;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if (g_bDefuseFixEnabled && (buttons & IN_USE))
    {
        if (g_fNextCheck[client] > GetGameTime())
        {
            if (!g_bAllowDefuse[client])
            {
                buttons &= ~IN_USE;
            }
        }
        else if (g_iDefuserEnt == client)
        {
            float vEyePos[3];
            GetClientEyePosition(client, vEyePos);

            TR_TraceRayFilter(vEyePos, g_vBombPos, MASK_VISIBLE, RayType_EndPoint, Filter_WorldOnly);

            g_bAllowDefuse[client] = (TR_GetFraction() == 1.0);
            if (!g_bAllowDefuse[client])
            {
                PrintHintText(client, "%t", "SMAC_IllegalDefuse");
                buttons &= ~IN_USE;
            }
            g_fNextCheck[client] = GetGameTime() + 2.0;
        }
    }

    return Plugin_Continue;
}

public bool Filter_WorldOnly(int entity, int contentsMask)
{
    return false;
}

public Action Event_BombPlanted(Event event, const char[] name, bool dontBroadcast)
{
    BombPlanted();
}

void BombPlanted()
{
    int iBombEnt = FindEntityByClassname(-1, "planted_c4");
    if (iBombEnt != -1)
    {
        GetEntPropVector(iBombEnt, Prop_Send, "m_vecOrigin", g_vBombPos);
        g_vBombPos[2] += 5.0;
    }
}

public Action Event_BombBeginDefuse(Event event, const char[] name, bool dontBroadcast)
{
    g_iDefuserEnt = GetClientOfUserId(GetEventInt(event, "userid"));
}

public Action Event_ResetDefuser(Event event, const char[] name, bool dontBroadcast)
{
    g_iDefuserEnt = -1;
}

/**
 * Respawn Fix
 */
bool g_bRespawnFixEnabled;

Handle g_hFreezeTime = INVALID_HANDLE;
Handle g_hRespawnElapsed = INVALID_HANDLE;
Handle g_hClientSpawned = INVALID_HANDLE;
int g_iClientClass[MAXPLAYERS+1] = {-1, ...};

public void OnRespawnFixChanged(ConVar convar, char[] oldValue, char[] newValue)
{
    if (g_hClientSpawned == INVALID_HANDLE)
    {
        g_hClientSpawned = CreateTrie();
    }

    bool bNewValue = convar.BoolValue;
    if (bNewValue && !g_bRespawnFixEnabled)
    {
        if (g_hFreezeTime == INVALID_HANDLE)
        {
            g_hFreezeTime = FindConVar("mp_freezetime");
        }

        HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
        HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

        AddCommandListener(Command_JoinClass, "joinclass");
    }
    else if (!bNewValue && g_bRespawnFixEnabled)
    {
        UnhookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
        UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

        RemoveCommandListener(Command_JoinClass, "joinclass");
		
        ClearSpawnData();
    }
    g_bRespawnFixEnabled = bNewValue;
}

public void OnClientDisconnect(int client)
{
    g_iClientClass[client] = -1;
}

public Action Command_JoinClass(int client, const char[] command, int argc)
{
    if (!IS_CLIENT(client) || !IsClientInGame(client) || IsFakeClient(client))
    {
        return Plugin_Continue;
    }

    // Allow users to join empty teams unhindered.
    int iTeam = GetClientTeam(client);

    if (iTeam > 1 && GetTeamClientCount(iTeam) > 1)
    {
        char sAuthID[MAX_AUTHID_LENGTH], dummy;

        if (GetClientAuthId(client, AuthId_Steam2, sAuthID, sizeof(sAuthID), false) && GetTrieValue(g_hClientSpawned, sAuthID, dummy))
        {
            char sBuffer[64];
            GetCmdArgString(sBuffer, sizeof(sBuffer));

            if ((g_iClientClass[client] = StringToInt(sBuffer)) < 0)
            {
                g_iClientClass[client] = 0;
            }

            FakeClientCommandEx(client, "spec_mode");
            return Plugin_Handled;
        }
    }

    return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int userid = GetEventInt(event, "userid");
    int client = GetClientOfUserId(userid);

    if (IS_CLIENT(client))
    {
        // Fix for warmup/force respawn plugins
        g_iClientClass[client] = -1;

        // Delay so it doesn't fire before Event_RoundStart
        CreateTimer(0.01, Timer_PlayerSpawned, userid, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_PlayerSpawned(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);

    if (IS_CLIENT(client) && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) > 1)
    {
        char sAuthID[MAX_AUTHID_LENGTH];
        if (GetClientAuthId(client, AuthId_Steam2, sAuthID, sizeof(sAuthID), false))
        {
            SetTrieValue(g_hClientSpawned, sAuthID, true);
        }
    }

    return Plugin_Stop;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    ClearSpawnData();
    g_hRespawnElapsed = CreateTimer(GetConVarFloat(g_hFreezeTime) + 21.0, Timer_RespawnElapsed);
}

public Action Timer_RespawnElapsed(Handle timer)
{
    g_hRespawnElapsed = INVALID_HANDLE;
    ClearSpawnData();
    return Plugin_Stop;
}

void ClearSpawnData()
{
    ClearTrie(g_hClientSpawned);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_iClientClass[i] != -1)
        {
            if (IsClientInGame(i))
            {
                FakeClientCommandEx(i, "joinclass %d", g_iClientClass[i]);
            }

            g_iClientClass[i] = -1;
        }
    }

    if (g_hRespawnElapsed != INVALID_HANDLE)
    {
        Handle hTemp = g_hRespawnElapsed;
        g_hRespawnElapsed = INVALID_HANDLE;

        CloseHandle(hTemp);
    }
}