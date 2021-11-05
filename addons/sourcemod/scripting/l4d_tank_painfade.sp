/*
	SourcePawn is Copyright (C) 2006-2015 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2015 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2015 ITB CompuPhase.
	Source is Copyright (C) Valve Corporation.
	All trademarks are property of their respective owners.

	This program is free software: you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define FADE_COLOR_R         128
#define FADE_COLOR_G         0
#define FADE_COLOR_B         0
#define FADE_ALPHA_LEVEL     128

#define FLAG_UZI             1
#define FLAG_SHOTGUN         2
#define FLAG_SNIPER          4
#define FLAG_MELEE           8

new Handle:g_hCvarEnabled;
new Handle:g_hCvarFadeDuration;
new Handle:g_hCvarWeaponFlags;

new iFadeDuration;
new iWeaponFlags;

new bool:bEnabled; 
new bool:bIsTankInPlay = false; 

public Plugin:myinfo =
{
    name        = "L4D Tank Pain Fade",
    author      = "Visor",
    version     = "1.1",
    description = "Tank's screen fades into red when taking damage",
    url         = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
    g_hCvarEnabled = CreateConVar("l4d_tank_painfade", "1", "Enable/disable plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarFadeDuration = CreateConVar("l4d_tank_painfade_duration", "150", "Fade duration in ticks");
    g_hCvarWeaponFlags = CreateConVar("l4d_tank_painfade_flags", "8", "What kind of weapons will cause the fade effect(1:Uzi,2:Shotgun,4:Sniper,8:Melee)", FCVAR_NOTIFY, true, 1.0, true, 15.0);
    
    bEnabled = GetConVarBool(g_hCvarEnabled);
    iFadeDuration = GetConVarInt(g_hCvarFadeDuration);
    iWeaponFlags = GetConVarInt(g_hCvarWeaponFlags);
    
    HookEvent("tank_spawn", TankSpawn, EventHookMode_PostNoCopy);
    HookEvent("player_death", PlayerDeath);
}

public OnClientDisconnect(client) 
{
    if (bEnabled && IsTank(client)) 
    {
        CreateTimer(0.1, CheckForTanksDelay, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action:TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!bEnabled || bIsTankInPlay) return;
    
    bIsTankInPlay = true;
    AttachEffect();
}

public Action:PlayerDeath( Handle:event, const String:name[], bool:dontBroadcast ) 
{
    if (!bEnabled) return;
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (IsTank(client)) 
    {
        CreateTimer(0.1, CheckForTanksDelay, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action:CheckForTanksDelay( Handle:timer ) 
{
    if (FindTank() == -1) 
    {
        bIsTankInPlay = false;
        DetachEffect();
    }
}

public Action:OnTankDamaged(victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3]) 
{
    if (!attacker || weapon < 1 || !IsTank(victim))
        return Plugin_Continue;
    
    if (iWeaponFlags & IdentifyWeapon(weapon))
    {
        UTIL_ScreenFade(victim, 1, iFadeDuration, 0, FADE_COLOR_R, FADE_COLOR_G, FADE_COLOR_B, FADE_ALPHA_LEVEL);    
    }
    
    return Plugin_Continue;
}

AttachEffect()
{
    for (new i = 1; i < MaxClients+1; i++) 
    {
        if (!IsClientConnected(i) || !IsClientInGame(i))
            continue;
        
        if (IsInfected(i)) SDKHook(i, SDKHook_OnTakeDamage, OnTankDamaged);
    }
}

DetachEffect()
{
    for (new i = 1; i < MaxClients+1; i++) 
    {
        if (!IsClientConnected(i) || !IsClientInGame(i))
            continue;
        
        SDKUnhook(i, SDKHook_OnTakeDamage, OnTankDamaged);
    }
}

IdentifyWeapon(ent_id) 
{
    if (ent_id < 1)
        return false;
    
    decl String:ent_name[64];
    GetEdictClassname(ent_id, ent_name, sizeof(ent_name));
    
    if (StrContains(ent_name, "smg", false) != -1)
        return FLAG_UZI;
    else if (StrContains(ent_name, "shotgun", false) != -1)
        return FLAG_SHOTGUN;
    else if (StrContains(ent_name, "hunting_rifle", false) != -1 || StrContains(ent_name, "sniper", false) != -1)
        return FLAG_SNIPER;
    else if (StrContains(ent_name, "melee", false) != -1)
        return FLAG_MELEE;
    
    return 0;
}

bool:IsInfected(client) 
{
    if (!IsClientInGame(client) || GetClientTeam(client) != 3) {
        return false;
    }
    return true;
}

FindTank() 
{
    for ( new i = 1; i <= MaxClients; i++ ) {
        if ( IsTank(i) && IsPlayerAlive(i) ) {
            return i;
        }
    }
    
    return -1;
}

bool:IsTank( client ) 
{
    if ( client <= 0 || !IsInfected(client) ) {
        return false;
    }
    
    if ( GetEntProp(client, Prop_Send, "m_zombieClass") == 8 ) {
        return true;
    }
    
    return false;
}

/**
 * Fade a player's screen to a specified color.
 *
 * @note Refer to https://developer.valvesoftware.com/wiki/UTIL_ScreenFade for the list of flags and more info
 *
 * @param client		Client id whose screen we need faded
 * @param duration		Time(in engine ticks) the fade holds for
 * @param time			Time(in engine ticks) it takes to fade
 * @param flags			Flags to apply to the fade effect
 * @param r				Amount of red
 * @param g				Amount of green
 * @param b				Amount of blue
 * @param a				Alpha level
 * @noreturn
 */
stock UTIL_ScreenFade(client, duration, time, flags, r, g, b, a)
{
    new clients[1], Handle:bf;
    clients[0] = client;

    bf = StartMessage("Fade", clients, 1);
    BfWriteShort(bf, duration);
    BfWriteShort(bf, time);
    BfWriteShort(bf, flags);
    BfWriteByte(bf, r);
    BfWriteByte(bf, g);
    BfWriteByte(bf, b);
    BfWriteByte(bf, a);
    EndMessage();
}
