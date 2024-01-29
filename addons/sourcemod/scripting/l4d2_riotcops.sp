/*
	SourcePawn is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2008 ITB CompuPhase.
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
#include <sdkhooks>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define PARISH_PREFIX "c5m"

bool
	g_bPluginActive = false;

public Plugin myinfo =
{
	name		= "L4D2 Riot Cops",
	author		= "Jahze, Visor, A1m`",
	version		= "1.6.1",
	description	= "Allow riot cops to be killed by a headshot"
}

public void OnMapStart()
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	String_ToLower(sMap, sizeof(sMap));
	
	g_bPluginActive = (strncmp(sMap, PARISH_PREFIX, 3) == 0);
}

public void OnEntityCreated(int iEntity, const char[] sClassName)
{
	if (sClassName[0] != 'i' || !g_bPluginActive) {
		return;
	}
	
	if (strcmp("infected", sClassName) == 0) {
		SDKHook(iEntity, SDKHook_SpawnPost, RiotCopSpawn);
	}
}

public void RiotCopSpawn(int iEntity)
{
	if (IsRiotCop(iEntity)) {
		SDKHook(iEntity, SDKHook_TraceAttack, RiotCopTraceAttack);
	}
}

public Action RiotCopTraceAttack(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType, \
										int &iAmmoType, int iHitBox, int iHitGroup)
{
	if (iHitGroup != HITGROUP_HEAD || !IsRiotCop(iVictim)) {
		return Plugin_Continue;
	}
	
	if (!IsValidSurvivor(iAttacker)) {
		return Plugin_Continue;
	}
	
	SDKHooks_TakeDamage(iVictim, iInflictor, iAttacker, fDamage, DMG_GENERIC);
	return Plugin_Continue;
}

bool IsRiotCop(int iEntity)
{
	return (iEntity > MaxClients && IsValidEntity(iEntity) && GetGender(iEntity) == L4D2Gender_Riot_Control);
}
