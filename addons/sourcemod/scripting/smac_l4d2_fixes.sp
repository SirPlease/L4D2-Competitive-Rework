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
#include <sdkhooks>
#include <smac>

/* Plugin Info */
public Plugin myinfo =
{
    name =          "SMAC L4D2 Exploit Fixes",
    author =        SMAC_AUTHOR,
    description =   "Blocks general Left 4 Dead 2 cheats & exploits",
    version =       SMAC_VERSION,
    url =           SMAC_URL
};

/* Globals */
#define L4D2_ZOMBIECLASS_TANK 8
#define RESET_USE_TIME 0.5
#define RECENT_TEAM_CHANGE_TIME 1.0

bool g_bProhibitUse[MAXPLAYERS+1];
bool g_didRecentlyChangeTeam[MAXPLAYERS + 1];

/* Plugin Functions */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if (GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, SMAC_MOD_ERROR);
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

public void OnPluginStart()
{
    // Hooks.
    HookEvent("player_use", Event_PlayerUse, EventHookMode_Post);
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
}

public void OnAllPluginsLoaded()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
        }
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    if (event.GetBool("disconnect"))
    {
        return;
    }

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IS_CLIENT(client) || !IsClientInGame(client) || IsFakeClient(client))
    {
        return;
    }

    g_didRecentlyChangeTeam[client] = true;
    CreateTimer(RECENT_TEAM_CHANGE_TIME, Timer_ResetRecentTeamChange, client);
}

public Action Timer_ResetRecentTeamChange(Handle timer, any client)
{
    g_didRecentlyChangeTeam[client] = false;
    return Plugin_Stop;
}

public Action Hook_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3])
{
    // Prevent infected players from killing survivor bots by changing teams in trigger_hurt areas
    if (IS_CLIENT(victim) && g_didRecentlyChangeTeam[victim])
    {
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt("targetid");

    if (entity <= MaxClients || entity >= MAX_EDICTS || !IsValidEntity(entity))
    {
        return;
    }

    char netclass[16];
    GetEntityNetClass(entity, netclass, 16);

    if (!StrEqual(netclass, "CPistol"))
    {
        return;
    }

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IS_CLIENT(client) || !IsClientInGame(client) || IsFakeClient(client) || g_bProhibitUse[client])
    {
        return;
    }

    g_bProhibitUse[client] = true;
    CreateTimer(RESET_USE_TIME, Timer_ResetUse, client);
}

public Action Timer_ResetUse(Handle timer, any client)
{
    g_bProhibitUse[client] = false;
    return Plugin_Stop;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    // Block pistol spam.
    if (g_bProhibitUse[client] && (buttons & IN_USE))
    {
        buttons ^= IN_USE;
    }

    // Block tank double-attack.
    if ((buttons & IN_ATTACK) && (buttons & IN_ATTACK2) && 
        GetClientTeam(client) == 3 && IsPlayerAlive(client) && 
        GetEntProp(client, Prop_Send, "m_zombieClass") == L4D2_ZOMBIECLASS_TANK)
    {
        buttons ^= IN_ATTACK2;
    }

    return Plugin_Continue;
}