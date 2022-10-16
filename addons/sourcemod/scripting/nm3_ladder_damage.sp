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

#define TEAM_SURVIVOR 2

bool
	g_bIsSewers = false,
	g_bLateLoad = false;

public Plugin myinfo = 
{
	name = "No Mercy 3 Ladder Fix",
	author = "Jacob",
	description = "Blocks players getting incapped from full hp on the ladder.",
	version = "1.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoad = bLate;

	return APLRes_Success;
}

public void OnPluginStart()
{
	if (!g_bLateLoad) {
		return;
	}

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnMapStart()
{
	char sMapName[64];
	GetCurrentMap(sMapName, sizeof(sMapName));

	g_bIsSewers = (strcmp(sMapName, "c8m3_sewers") == 0);
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

/*public void OnClientDisconnect(int iClient)
{
	SDKUnhook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}*/

public Action Hook_OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype)
{
	if (iDamagetype != DMG_FALL || !g_bIsSewers || fDamage <= 30.0) {
		return Plugin_Continue;
	}

	if (iVictim < 1 || iVictim > MaxClients || GetClientTeam(iVictim) != TEAM_SURVIVOR) {
		return Plugin_Continue;
	}

	int iPounceVictim = GetEntPropEnt(iVictim, Prop_Send, "m_pounceAttacker");
	int iJockeyVictim = GetEntPropEnt(iVictim, Prop_Send, "m_jockeyAttacker");

	if (iPounceVictim < 1 && iJockeyVictim < 1) {
		return Plugin_Continue;
	}

	fDamage = 30.0;
	return Plugin_Changed;
}
