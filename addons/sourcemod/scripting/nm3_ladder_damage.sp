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
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_SURVIVOR(%1)         (GetClientTeam(%1) == 2)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_SURVIVOR(%1)   (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))

bool g_bIsSewers = false;

public Plugin myinfo = 
{
	name = "No Mercy 3 Ladder Fix",
	author = "Jacob",
	description = "Blocks players getting incapped from full hp on the ladder.",
	version = "1.1",
	url = "github.com/jacob404/myplugins"
};

public void OnMapStart()
{
	char sMapName[64];
	GetCurrentMap(sMapName, sizeof(sMapName));

	g_bIsSewers = (strcmp(sMapName, "c8m3_sewers") == 0);
}

public void OnClientPostAdminCheck(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public void OnClientDisconnect(int iClient)
{
	SDKUnhook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public Action Hook_OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype)
{
	int iPounceVictim = GetEntProp(iVictim, Prop_Send, "m_pounceAttacker");
	int iJockeyVictim = GetEntProp(iVictim, Prop_Send, "m_jockeyAttacker");

	if (iPounceVictim <= 0 && iJockeyVictim <= 0) {
		return Plugin_Continue;
	}

	if (!g_bIsSewers) {
		return Plugin_Continue;
	}

	if(IS_VALID_SURVIVOR(iVictim) && fDamage > 30.0 && iDamagetype == DMG_FALL) {
		fDamage = 30.0;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}
