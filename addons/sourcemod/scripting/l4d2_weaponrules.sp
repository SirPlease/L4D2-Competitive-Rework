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
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define DEBUG 0

int
	g_GlobalWeaponRules[WEPID_SIZE] = {-1, ...},
	// state tracking for roundstart looping
	g_bRoundStartHit,
	g_bConfigsExecuted;

public Plugin myinfo =
{
	name = "L4D2 Weapon Rules",
	author = "ProdigySim",
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
	for (int i = 0; i < WEPID_SIZE; i++) {
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

	return Plugin_Stop;
}

public Action AddWeaponRuleCb(int args)
{
	if (args < 2) {
		PrintToServer("Usage: l4d2_addweaponrule <match> <replace>");
		return Plugin_Handled;
	}
	
	char weaponbuf[64];

	GetCmdArg(1, weaponbuf, sizeof(weaponbuf));
	int match = WeaponNameToId2(weaponbuf);

	GetCmdArg(2, weaponbuf, sizeof(weaponbuf));
	int to = WeaponNameToId2(weaponbuf);

	AddWeaponRule(match, to);

	return Plugin_Handled;
}


void AddWeaponRule(int match, int to)
{
	if (IsValidWeaponId(match) && (to == -1 || IsValidWeaponId(to))) {
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
		int source = IdentifyWeapon(ent);
		if (source > WEPID_NONE && g_GlobalWeaponRules[source] != -1) {
			if (g_GlobalWeaponRules[source] == WEPID_NONE) {
				AcceptEntityInput(ent, "kill");
				#if DEBUG
				PrintToServer("Found Weapon %d, killing", source);
				#endif
			} else {
				#if DEBUG
				PrintToServer("Found Weapon %d, converting to %d", source, g_GlobalWeaponRules[source]);
				#endif
				ConvertWeaponSpawn(ent, g_GlobalWeaponRules[source]);
			}
		}
	}
}

// Tries the given weapon name directly, and upon failure,
// tries prepending "weapon_" to the given name
int WeaponNameToId2(const char[] name)
{
	char namebuf[64] = "weapon_";
	int wepid = WeaponNameToId(name);
	
	if (wepid == WEPID_NONE) {
		strcopy(namebuf[7], sizeof(namebuf) - 7, name);
		wepid = WeaponNameToId(namebuf);
	}

	return wepid;
}
