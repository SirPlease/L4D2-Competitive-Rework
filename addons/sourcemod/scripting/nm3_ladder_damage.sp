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

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_SURVIVOR(%1)         (GetClientTeam(%1) == 2)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_SURVIVOR(%1)   (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))

new bool:g_bIsSewers = false;

public Plugin:myinfo = 
{
    name = "No Mercy 3 Ladder Fix",
    author = "Jacob",
    description = "Blocks players getting incapped from full hp on the ladder.",
    version = "1.0",
    url = "github.com/jacob404/myplugins"
}

public OnMapStart()
{
    decl String:mapname[64];
    GetCurrentMap(mapname, sizeof(mapname));
    if(StrEqual(mapname, "c8m3_sewers"))
    {
        g_bIsSewers = true;
    }
    else
    {
        g_bIsSewers = false;
    }
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	new iPounceVictim = GetEntProp(victim, Prop_Send, "m_pounceAttacker");
	new iJockeyVictim = GetEntProp(victim, Prop_Send, "m_jockeyAttacker");
	
	if(iPounceVictim <= 0 && iJockeyVictim <= 0) {
		return Plugin_Continue;
	}
	
	if(!g_bIsSewers){
		return Plugin_Continue;
	}
	
	if(IS_VALID_SURVIVOR(victim) && damage > 30.0 && damagetype == DMG_FALL)
	{
		damage = 30.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
