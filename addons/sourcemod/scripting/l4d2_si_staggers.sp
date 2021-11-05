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
#include <left4dhooks>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define DEBUG 0

#define ENTITY_NAME_MAX_LENTH 64

#define BLOCK_BOOMER	(1 << 0)
#define BLOCK_CHARGER	(1 << 1)
#define BLOCK_WITCH		(1 << 2)

ConVar
	hCvarInfectedFlags;

int
	iActiveFlags;

public Plugin myinfo = 
{
	name = "L4D2 No SI Friendly Staggers",
	author = "Visor, A1m`",
	description = "Removes SI staggers caused by other SI(Boomer, Charger, Witch)",
	version = "1.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	hCvarInfectedFlags = CreateConVar("l4d2_disable_si_friendly_staggers", "0", "Remove SI staggers caused by other SI(bitmask: 1-Boomer/2-Charger/4-Witch)", _, true, 0.0, true, 7.0);
	
	iActiveFlags = hCvarInfectedFlags.IntValue;
	hCvarInfectedFlags.AddChangeHook(PluginActivityChanged);
}

public void PluginActivityChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iActiveFlags = hCvarInfectedFlags.IntValue;
}

public Action L4D2_OnStagger(int target, int source)
{
	// For some reason, Valve chose to set a null source for charger impact staggers.
	// And Left4DHooks converts this null source to -1.
	// Since there aren't really any other possible calls for this function,
	// assume (source == -1) as a charger impact stagger
	// TODO: Patch the binary to pass on the Charger's client ID instead of nothing?
	// Probably not worth it, for now, at least
	#if DEBUG
	PrintToServer("OnStagger(target=%d, source=%d) SourceValid: %d, SourceInfectedClass %d",
						target, source, IsValidEdict(source), GetInfectedClass(source));
	#endif
	
	if (!iActiveFlags) { // Is the plugin active at all?
		return Plugin_Continue;
	}
	
	if (source != -1 && !IsValidEdict(source)) {
		return Plugin_Continue;
	}
	
	if (GetInfectedZClass(source) == L4D2Infected_Boomer && !(iActiveFlags & BLOCK_BOOMER)) { // Is the Boomer eligible?
		return Plugin_Continue;
	}
	
	if (source == -1 && !(iActiveFlags & BLOCK_CHARGER)) { // Is the Charger eligible?
		return Plugin_Continue;
	}
	
	if (GetClientTeam(target) == L4D2Team_Survivor && IsSurvivorAttacked(target)) { // Capped Survivors should not get staggered
		return Plugin_Handled;
	}
	
	if (GetClientTeam(target) != L4D2Team_Infected) { // We'll only need SI for the following checks
		return Plugin_Continue;
	}
	
	if (source == -1 && GetInfectedZClass(target) != L4D2Infected_Charger) { // Allow Charger selfstaggers through
		return Plugin_Handled;
	}
	
	if (source <= MaxClients && GetInfectedZClass(source) == L4D2Infected_Boomer) { // Cancel any staggers caused by a Boomer explosion
		return Plugin_Handled;
	}
	
	if ((iActiveFlags & BLOCK_WITCH) && source != -1) { // Return early if we don't have a valid edict.
		char classname[ENTITY_NAME_MAX_LENTH];
		GetEdictClassname(source, classname, sizeof(classname));
		if (StrContains(classname, "witch") != -1) { // Cancel any staggers caused by a running Witch or Witch Bride(if eligible)
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue; // Is this even reachable? Probably yes, in case some plugin has used the L4D_StaggerPlayer() native
}

int GetInfectedZClass(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client)) {
		return GetEntProp(client, Prop_Send, "m_zombieClass");
	}

	return -1;
}
