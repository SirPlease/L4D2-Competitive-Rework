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
#include <sourcemod>
#include <left4dhooks>

new const LINUX_SI_DOMINATION_OFFSETS[4] = {
    13284,    // smoker
    16008,    // hunter
    16128,    // jockey
    15976     // charger
};

new const FLAGS[3] = {
    1 << 0, // boomer
    1 << 1, // charger
    1 << 2, // witch
};

new Handle:hCvarInfectedFlags;

new iActiveFlags;

public Plugin:myinfo = 
{
    name = "L4D2 No SI Friendly Staggers",
    author = "Visor",
    description = "Removes SI staggers caused by other SI(Boomer, Charger, Witch)",
    version = "1.1",
    url = ""
};

public OnPluginStart()
{
    hCvarInfectedFlags = CreateConVar("l4d2_disable_si_friendly_staggers", "0", "Remove SI staggers caused by other SI(bitmask: 1-Boomer/2-Charger/4-Witch)");
    iActiveFlags = GetConVarInt(hCvarInfectedFlags);
    HookConVarChange(hCvarInfectedFlags, PluginActivityChanged);
}

public PluginActivityChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
    iActiveFlags = GetConVarInt(hCvarInfectedFlags);
}

public Action:L4D2_OnStagger(target, source)
{
    // IndexOfEdict() returns random shit when used on a NULL edict
    // For some reason, Valve chose to set a null source for charger impact staggers
    // Since there aren't really any other possible calls for this function,
    // assume (source == 0) as a charger impact stagger
    // TODO: Patch the binary to pass on the Charger's client ID instead of nothing?
    // Probably not worth it, for now, at least

    if (!IsValidEdict(source))
        return Plugin_Continue;

    if (!iActiveFlags)  // Is the plugin active at all?
        return Plugin_Continue;

    if (GetInfectedClass(source) == 2 && !(iActiveFlags & FLAGS[0]))  // Is the Boomer eligible?
        return Plugin_Continue;

    if (!source && !(iActiveFlags & FLAGS[1]))  // Is the Charger eligible?
        return Plugin_Continue;

    if (GetClientTeam(target) == 2 && IsBeingAttacked(target))  // Capped Survivors should not get staggered
        return Plugin_Handled;

    if (GetClientTeam(target) != 3) // We'll only need SI for the following checks
        return Plugin_Continue;

    if (!source && GetInfectedClass(target) != 6)    // Allow Charger selfstaggers through
        return Plugin_Handled;

    if (source <= MaxClients && GetInfectedClass(source) == 2) // Cancel any staggers caused by a Boomer explosion
        return Plugin_Handled;
    
    decl String:classname[64];
    GetEdictClassname(source, classname, sizeof(classname));
    if ((iActiveFlags & FLAGS[2]) && StrEqual(classname, "witch"))  // Cancel any staggers caused by a running Witch(if eligible)
        return Plugin_Handled;
    
    return Plugin_Continue;  // Is this even reachable? Probably yes, in case some plugin has used the L4D_StaggerPlayer() native
}

bool:IsBeingAttacked(survivor)
{
    new Address:pEntity = GetEntityAddress(survivor);
    if (pEntity == Address_Null)
        return false;
    
    new survivorState = 0;
    for (new i = 0; i < sizeof(LINUX_SI_DOMINATION_OFFSETS); i++)
    {    
        survivorState += LoadFromAddress(pEntity + Address:LINUX_SI_DOMINATION_OFFSETS[i], NumberType_Int32);
    }
    
    return survivorState > 0 ? true : false;
}

GetInfectedClass(client)
{
    if (client > 0 && client <= MaxClients && IsClientInGame(client))
    {
        return GetEntProp(client, Prop_Send, "m_zombieClass");
    }

    return -1;
}