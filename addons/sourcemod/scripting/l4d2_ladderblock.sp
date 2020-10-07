#define PLUGIN_VERSION 		"1.0"

/*
* ============================================================================
*
*  Description:	Prevents people from blocking players who climb on the ladder.
*
*  Credits:		Original code taken from Rotoblin2 project
*					written by Me and ported to l4d2.
*					See rotoblin.ExpolitFixes.sp module
*
*	Site:			http://code.google.com/p/rotoblin2/
*
*  Copyright (C) 2012 raziEiL <war4291@mail.ru>
*
*  This program is free software: you can redistribute it and/or modify
*  it under the terms of the GNU General Public License as published by
*  the Free Software Foundation, either version 3 of the License, or
*  (at your option) any later version.
*
*  This program is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
* ============================================================================
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
new			inCharge		[MAXPLAYERS + 1];

public Plugin:myinfo =
{
    name = "StopTrolls",
    author = "raziEiL [disawar1]",
    description = "Prevents people from blocking players who climb on the ladder.",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/id/raziEiL"
}

static		Handle:g_hFlags, Handle:g_hImmune, g_iCvarFlags, g_iCvarImmune, bool:g_bLoadLate;

public OnPluginStart()
{
    CreateConVar("stop_trolls_version", PLUGIN_VERSION, "StopTrolls plugin version", FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    g_hFlags = CreateConVar("stop_trolls_flags", "862", "Who can push trolls when climbs on the ladder. 0=Disable, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 64=Charger, 256=Tank, 512=Survivors, 862=All");
    g_hImmune = CreateConVar("stop_trolls_immune", "256", "What class is immune. 0=Disable, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 256=Tank, 512=Survivors, 894=All");
    //AutoExecConfig(true, "StopTrollss"); // If u want a cfg file uncomment it. But I don't like.
    
    HookEvent("charger_charge_start", Charging);
    HookEvent("charger_charge_end", NotCharging);
    
    HookConVarChange(g_hFlags, OnCvarChange_Flags);
    HookConVarChange(g_hImmune, OnCvarChange_Immune);
    ST_GetCvars();
    
    if (g_iCvarFlags && g_bLoadLate)
        ST_ToogleHook(true);
}

public OnClientPutInServer(client)
{
    inCharge[client] = 0;
    if (g_iCvarFlags && client)
        SDKHook(client, SDKHook_Touch, SDKHook_cb_Touch);
    
}

public Charging(Handle:event, const String:name[], bool:dontBroadcast)
{
    new ChargerID = GetEventInt(event, "userid");
    new charger = GetClientOfUserId(ChargerID);
    
    inCharge[charger] = 1;
}

public NotCharging(Handle:event, const String:name[], bool:dontBroadcast)
{
    new ChargerID = GetEventInt(event, "userid");
    new charger = GetClientOfUserId(ChargerID);
    
    inCharge[charger] = 0;
}


public Action:SDKHook_cb_Touch(entity, other)
{
    if (other > MaxClients || other < 1) return;
    
    if (IsGuyTroll(entity, other)){
        
        new iClass = GetEntProp(entity, Prop_Send, "m_zombieClass");
        
        if (iClass != 5 && g_iCvarFlags & (1 << iClass)){
            
            // Tank AI and Witch have this skill but Valve method is sucks because ppl get STUCKS!
            if (iClass == 8 && IsFakeClient(entity)) return;
            
            iClass = GetEntProp(other, Prop_Send, "m_zombieClass");
            
            if (g_iCvarImmune & (1 << iClass)) return;
            
            if (inCharge[other]) return;
            
            if (IsOnLadder(other)){
                
                decl Float:vOrg[3];
                GetClientAbsOrigin(other, vOrg);
                vOrg[2] += 2.5;
                TeleportEntity(other, vOrg, NULL_VECTOR, NULL_VECTOR);
            }
            else
            TeleportEntity(other, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 251.0});
        }
    }
}

bool:IsGuyTroll(victim, troll)
{
    return IsOnLadder(victim) && GetClientTeam(victim) != GetClientTeam(troll) && GetEntPropFloat(victim, Prop_Send, "m_vecOrigin[2]") < GetEntPropFloat(troll, Prop_Send, "m_vecOrigin[2]");
}

bool:IsOnLadder(entity)
{
    return GetEntityMoveType(entity) == MOVETYPE_LADDER;
}

ST_ToogleHook(bool:bHook)
{
    for (new i = 1; i <= MaxClients; i++){
        
        if (!IsClientInGame(i)) continue;
        
        if (bHook)
            SDKHook(i, SDKHook_Touch, SDKHook_cb_Touch);
        else
        SDKUnhook(i, SDKHook_Touch, SDKHook_cb_Touch);
    }
}

public OnCvarChange_Flags(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
    if (StrEqual(oldValue, newValue)) return;
    
    g_iCvarFlags = GetConVarInt(g_hFlags);
    
    if (!StringToInt(oldValue))
        ST_ToogleHook(true);
    else if (!g_iCvarFlags)
        ST_ToogleHook(false);
}

public OnCvarChange_Immune(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
    if (!StrEqual(oldValue, newValue))
        g_iCvarImmune = GetConVarInt(g_hImmune);
}

ST_GetCvars()
{
    g_iCvarFlags = GetConVarInt(g_hFlags);
    g_iCvarImmune = GetConVarInt(g_hImmune);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    if (GuessSDKVersion() != SOURCE_SDK_LEFT4DEAD2){
        
        strcopy(error, err_max, "Plugin only support L4D2 engine");
        return APLRes_Failure;
    }
    
    g_bLoadLate = late;
    return APLRes_Success;
}