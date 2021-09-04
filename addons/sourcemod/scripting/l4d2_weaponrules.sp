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
#include <sdktools>
#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>

#define DEBUG 0

int
	g_GlobalWeaponRules[view_as<int>(WEPID_SIZE)] = {-1, ...},
	// state tracking for roundstart looping
	g_bRoundStartHit,
	g_bConfigsExecuted;

public Plugin myinfo =
{
	name = "L4D2 Weapon Rules",
	author = "ProdigySim", //Update syntax and add support sm1.11 - A1m`
	version = "1.0.2",
	description = "^",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	RegServerCmd("l4d2_addweaponrule", AddWeaponRuleCb);
	RegServerCmd("l4d2_resetweaponrules", ResetWeaponRulesCb);
	
	HookEvent("round_start", RoundStartCb, EventHookMode_PostNoCopy);
	
	ResetWeaponRules();
}

public Action ResetWeaponRulesCb(int args)
{
	ResetWeaponRules();

	return Plugin_Handled;
}

void ResetWeaponRules()
{
	for (int i = 0; i < view_as<int>(WEPID_SIZE); i++) {
		g_GlobalWeaponRules[i] = -1;
	}
}

public void RoundStartCb(Event hEvent, const char[] eName, bool dontBroadcast)
{
	CreateTimer(0.3, RoundStartDelay, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapStart()
{
	g_bRoundStartHit = false;
	g_bConfigsExecuted = false;
}

public void OnConfigsExecuted()
{
	g_bConfigsExecuted = true;
	
	if (g_bRoundStartHit) {
		WeaponSearchLoop();
	}
}

public Action RoundStartDelay(Handle hTimer)
{
	g_bRoundStartHit = true;
	
	if (g_bConfigsExecuted) {
		WeaponSearchLoop();
	}
}

public Action AddWeaponRuleCb(int args)
{
	if (args < 2) {
		PrintToServer("Usage: l4d2_addweaponrule <match> <replace>");
		return Plugin_Handled;
	}
	
	char weaponbuf[64];

	GetCmdArg(1, weaponbuf, sizeof(weaponbuf));
	WeaponId match = WeaponNameToId2(weaponbuf);

	GetCmdArg(2, weaponbuf, sizeof(weaponbuf));
	WeaponId to = WeaponNameToId2(weaponbuf);

	AddWeaponRule(match, view_as<int>(to));

	return Plugin_Handled;
}


void AddWeaponRule(WeaponId match, int to)
{
	if (IsValidWeaponId(match) && (to == -1 || IsValidWeaponId(view_as<WeaponId>(to)))) {
		g_GlobalWeaponRules[match] = to;
		#if DEBUG
		PrintToServer("Added weapon rule: %d to %d", match, to);
		#endif
	}
}

void WeaponSearchLoop()
{
	int entcnt = GetEntityCount();
	for (int ent = 1; ent <= entcnt; ent++) {
		WeaponId source = IdentifyWeapon(ent);
		if (source > WEPID_NONE && g_GlobalWeaponRules[source] != -1) {
			if (g_GlobalWeaponRules[source] == view_as<int>(WEPID_NONE)) {
				AcceptEntityInput(ent, "kill");
				#if DEBUG
				PrintToServer("Found Weapon %d, killing", source);
				#endif
			} else {
				#if DEBUG
				PrintToServer("Found Weapon %d, converting to %d", source, g_GlobalWeaponRules[source]);
				#endif
				ConvertWeaponSpawn(ent, view_as<WeaponId>(g_GlobalWeaponRules[source]));
			}
		}
	}
}

// Tries the given weapon name directly, and upon failure,
// tries prepending "weapon_" to the given name
WeaponId WeaponNameToId2(const char[] name)
{
	static char namebuf[64] = "weapon_";
	WeaponId wepid = WeaponNameToId(name);
	
	if (wepid == WEPID_NONE) {
		strcopy(namebuf[7], sizeof(namebuf) - 7, name);
		wepid = WeaponNameToId(namebuf);
	}

	return wepid;
}
