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
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>

#define PARISH_PREFIX "c5m"

bool
	bPluginActive;

public Plugin myinfo =
{
	name		= "L4D2 Riot Cops",
	author		= "Jahze, Visor",
	version		= "1.3", //new syntax A1m`
	description	= "Allow riot cops to be killed by a headshot"
}

public void OnMapStart()
{
	char sMap[128];
	GetCurrentMap(sMap, sizeof(sMap));

	bPluginActive = (StrContains(sMap, PARISH_PREFIX, false) > -1) ? true : false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (bPluginActive && strcmp("infected", classname) == 0) {
		SDKHook(entity, SDKHook_SpawnPost, RiotCopSpawn);
	}
}

public void RiotCopSpawn(int entity)
{
	if (IsValidEntity(entity) && GetGender(entity) == L4D2Gender_RiotCop) {
		SDKHook(entity, SDKHook_TraceAttack, RiotCopTraceAttack);
	}
}

public Action RiotCopTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (hitgroup == 1 && IsValidEntity(victim)) {
		if (IS_VALID_CLIENT(attacker) && IsSurvivor(attacker)) {
			SDKHooks_TakeDamage(victim, 0, attacker, damage);
		}
	}
	return Plugin_Continue;
}
