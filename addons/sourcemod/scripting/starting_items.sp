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

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN

#define HEALTH_FIRST_AID_KIT    1
#define HEALTH_DEFIBRILLATOR    2
#define HEALTH_PAIN_PILLS       4
#define HEALTH_ADRENALINE       8

#define THROWABLE_PIPE_BOMB     16
#define THROWABLE_MOLOTOV       32
#define THROWABLE_VOMITJAR      64


public Plugin:myinfo =
{
    name = "Starting Items",
    author = "CircleSquared + Jacob",
    description = "Gives health items and throwables to survivors at the start of each round",
    version = "1.1",
    url = "none"
}

new Handle:hCvarItemType;
new iItemFlags;
new bool:g_bReadyUpAvailable = false;

public OnPluginStart()
{
    hCvarItemType = CreateConVar("starting_item_flags", "0", "Item flags to give on leaving the saferoom (1: Kit, 2: Defib, 4: Pills, 8: Adren, 16: Pipebomb, 32: Molotov, 64: Bile)", FCVAR_NONE);
    HookEvent("player_left_start_area", PlayerLeftStartArea);
}

public OnAllPluginsLoaded()
{
    g_bReadyUpAvailable = LibraryExists("readyup");
}
public OnLibraryRemoved(const String:name[])
{
    if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = false; }
}
public OnLibraryAdded(const String:name[])
{
    if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = true; }
}

public OnRoundIsLive()
{
    DetermineItems();
}

public Action:PlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!g_bReadyUpAvailable) DetermineItems();
}	

public DetermineItems()
{
    new String:strItemName[32];
    iItemFlags = GetConVarInt(hCvarItemType);

    if (iItemFlags)
	{
        if (iItemFlags & HEALTH_FIRST_AID_KIT)
		{
            strItemName = "weapon_first_aid_kit";
            giveStartingItem(strItemName);
        }
        else if (iItemFlags & HEALTH_DEFIBRILLATOR)
		{
            strItemName = "weapon_defibrillator";
            giveStartingItem(strItemName);
        }
        if (iItemFlags & HEALTH_PAIN_PILLS)
		{
            strItemName = "weapon_pain_pills";
            giveStartingItem(strItemName);
        }
        else if (iItemFlags & HEALTH_ADRENALINE)
		{
            strItemName = "weapon_adrenaline";
            giveStartingItem(strItemName);
        }
        if (iItemFlags & THROWABLE_PIPE_BOMB)
		{
            strItemName = "weapon_pipe_bomb";
            giveStartingItem(strItemName);
        }
        else if (iItemFlags & THROWABLE_MOLOTOV)
		{
            strItemName = "weapon_molotov";
            giveStartingItem(strItemName);
        }
        else if (iItemFlags & THROWABLE_VOMITJAR)
		{
            strItemName = "weapon_vomitjar";
            giveStartingItem(strItemName);
        }
    }
}

giveStartingItem(const String:strItemName[32])
{
    new startingItem;
    new Float:clientOrigin[3];

    for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
            startingItem = CreateEntityByName(strItemName);
            GetClientAbsOrigin(i, clientOrigin);
            TeleportEntity(startingItem, clientOrigin, NULL_VECTOR, NULL_VECTOR);
            DispatchSpawn(startingItem);
            EquipPlayerWeapon(i, startingItem);
        }
    }
}