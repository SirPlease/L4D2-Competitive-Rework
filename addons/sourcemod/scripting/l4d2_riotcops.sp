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

#define L4D2UTIL_STOCKS_ONLY 1

#include <sourcemod>
#include <sdkhooks>
#include <l4d2util>

#define PARISH_PREFIX   "c5m"

new bool:bPluginActive;

public Plugin:myinfo = {
    name        = "L4D2 Riot Cops",
    author      = "Jahze, Visor",
    version     = "1.2",
    description = "Allow riot cops to be killed by a headshot"
}

public OnMapStart() {
    decl String:sMap[128];
    GetCurrentMap(sMap, sizeof(sMap));

    bPluginActive = StrContains(sMap, PARISH_PREFIX, false) > -1 ? true : false;
}

public OnEntityCreated(entity, const String:classname[]) {
    if (!bPluginActive) {
        return;
    }

    if (entity <= 0 || entity > 2048) {
        return;
    }

    if (StrEqual("infected", classname)) {
        SDKHook(entity, SDKHook_SpawnPost, RiotCopSpawn);
    }
}

public RiotCopSpawn(entity) {
    if (GetGender(entity) == L4D2Gender_RiotCop) {
        SDKHook(entity, SDKHook_TraceAttack, RiotCopTraceAttack);
    }
}

public Action:RiotCopTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damageType, &ammotype, hitbox, hitgroup) {
    if (! attacker) {
        return Plugin_Continue;
    }

    if (hitgroup == 1) {
        SDKHooks_TakeDamage(victim, 0, attacker, damage);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

