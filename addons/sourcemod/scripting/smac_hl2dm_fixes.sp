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
    name =          "SMAC HL2:DM Exploit Fixes",
    author =        SMAC_AUTHOR,
    description =   "Blocks general Half-Life 2: Deathmatch exploits",
    version =       SMAC_VERSION,
    url =           SMAC_URL
};

/* Globals */
float g_fBlockTime[MAXPLAYERS+1];
bool g_bHasCrossbow[MAXPLAYERS+1];

/* Plugin Functions */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if (GetEngineVersion() != Engine_HL2DM)
    {
        strcopy(error, err_max, SMAC_MOD_ERROR);
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

public void OnPluginStart()
{
    // Hooks.
    AddTempEntHook("Shotgun Shot", Hook_FireBullets);
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
}

public void OnClientPutInServer(int client)
{
    g_fBlockTime[client] = 0.0;
    g_bHasCrossbow[client] = false;

    SDKHook(client, SDKHook_WeaponCanSwitchTo, Hook_WeaponCanSwitchTo);
    SDKHook(client, SDKHook_WeaponSwitchPost, Hook_WeaponSwitchPost);
}

public Action Hook_WeaponCanSwitchTo(int client, int weapon)
{
    char sWeapon[32];

    if (!IsValidEdict(weapon) || !GetEdictClassname(weapon, sWeapon, sizeof(sWeapon)))
    {
        return Plugin_Continue;
    }
    
    // Block gravity gun toggle after a bullet has fired.
    if (g_fBlockTime[client] > GetGameTime() && StrEqual(sWeapon, "weapon_physcannon"))
    {
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public Action Hook_WeaponSwitchPost(int client, int weapon)
{
    // Monitor the crossbow for shots. OnEntityCreated/OnSpawn is too early.
    char sWeapon[32];

    g_bHasCrossbow[client] = IsValidEdict(weapon) && 
            GetEdictClassname(weapon, sWeapon, sizeof(sWeapon)) && 
            StrEqual(sWeapon, "weapon_crossbow");
}

public Action Hook_FireBullets(const char[] te_name, const int[] Players, int numClients, float delay)
{
    int client = TE_ReadNum("m_iPlayer");

    if (IS_CLIENT(client))
    {
        g_fBlockTime[client] = GetGameTime() + 0.1;
    }

    return Plugin_Continue;
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    // Slay players that execute a team change while using an active gravity gun.
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IS_CLIENT(client) && IsClientInGame(client) && IsPlayerAlive(client))
    {
        char sWeapon[32];
        int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

        if (IsValidEdict(weapon) && 
            GetEdictClassname(weapon, sWeapon, sizeof(sWeapon)) && 
            StrEqual(sWeapon, "weapon_physcannon") && 
            GetEntProp(weapon, Prop_Send, "m_bActive", 1) && 
            SMAC_CheatDetected(client, Detection_GravityGunExploit, INVALID_HANDLE) == Plugin_Continue)
        {
            SMAC_LogAction(client, "was slayed for attempting to exploit the gravity gun.");
            ForcePlayerSuicide(client);
        }
    }

    return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    // Detecting a crossbow shot.
    if ((buttons & IN_ATTACK) && g_bHasCrossbow[client])
    {
        int iWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

        if (IsValidEdict(iWeapon) && GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack") < GetGameTime())
        {
            g_fBlockTime[client] = GetGameTime() + 0.1;
        }
    }

    // Don't let the player crouch if they are in the process of standing up.
    if ((buttons & IN_DUCK) && GetEntProp(client, Prop_Send, "m_bDucked", 1) && GetEntProp(client, Prop_Send, "m_bDucking", 1))
    {
        buttons ^= IN_DUCK;
    }

    // Only allow sprint if the player is alive.
    if ((buttons & IN_SPEED) && !IsPlayerAlive(client))
    {
        buttons ^= IN_SPEED;
    }

    // Block flashlight/weapon toggle after a bullet has fired.
    if ((impulse == 51) || (impulse == 100 && g_fBlockTime[client] > GetGameTime()))
    {
        impulse = 0;
    }
    if (weapon && IsValidEdict(weapon) && g_fBlockTime[client] > GetGameTime())
    {
        char sWeapon[32];
        GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));

        if (StrEqual(sWeapon, "weapon_physcannon"))
        {
            weapon = 0;
        }
    }

    return Plugin_Continue;
}