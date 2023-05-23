/*
*	Use Priority Patch
*	Copyright (C) 2022 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION 		"2.5"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Use Priority Patch
*	Author	:	SilverShot
*	Descrp	:	Patches CBaseEntity::GetUsePriority preventing attached entities blocking +USE.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=327511
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

2.5 (22-Nov-2022)
	- Fixed crash on L4D1 on Windows. Thanks to "ZBzibing" for testing.

2.4 (01-Aug-2022)
	- Plugin updated to restore Windows L4D1 functionality. Unable to replicate the crash.

2.3 (12-Sep-2021)
	- GameData and plugin updated to ignore Windows L4D1 due to crashing. Seems to be caused by last game update.

2.2b (26-Aug-2021)
	- GameData updated. Fixed possible rare instance of crashing the server.

2.2a (10-Aug-2021)
	- L4D1: GameData updated. Fixed breaking from 1.0.4.0 update.

2.2 (13-Jul-2021)
	- Fixed "Entity -1" errors. Thanks to "HarryPotter" for reporting.

2.1 (04-May-2021)
	- Fixed not being able to interact with objects attached to things other than clients. Thanks to "Proaxel" for reporting.

2.0 (12-Apr-2021)
	- Change from patch method to detour method. Should work completely now.
	- Now requires "DHooks (Experimental dynamic detour support)" extension.

1.0 (24-Sep-2020)
	- Initial release.

======================================================================================*/

// Testing: Charms plugin with Jockey Arms on Pistol @  2347.632812 4986.759277 448.031250     7.792390 -96.644767 0.000000 c1m2_streets.
// Also with Hats plugin enabled.

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"l4d_use_priority"



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Use Priority Patch",
	author = "SilverShot",
	description = "Patches CBaseEntity::GetUsePriority preventing attached entities blocking +USE.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=327511"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	// ====================================================================================================
	// Detours
	// ====================================================================================================
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	Handle hDetour = DHookCreateFromConf(hGameData, "CBaseEntity::GetUsePriority");
	if( !hDetour )
		SetFailState("Failed to find \"CBaseEntity::GetUsePriority\" signature.");
	if( !DHookEnableDetour(hDetour, false, GetUsePriority_Pre) )
		SetFailState("Failed to detour \"CBaseEntity::GetUsePriority\" pre.");

	delete hDetour;
	delete hGameData;

	// ====================================================================================================
	// CVAR
	// ====================================================================================================
	CreateConVar("l4d_use_priority_version", PLUGIN_VERSION, "Use Priority Patch plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}



// ====================================================================================================
//					DETOURS
// ====================================================================================================
MRESReturn GetUsePriority_Pre(int pThis, Handle hReturn, Handle hParams)
{
	if( pThis == -1 ) return MRES_Ignored;
	int parent = GetEntPropEnt(pThis, Prop_Send, "moveparent");

	// Is attached to something attached to clients?
	while( parent > MaxClients )
	{
		parent = GetEntPropEnt(parent, Prop_Send, "moveparent");
	}

	// Don't allow using
	if( parent > 0 && parent <= MaxClients )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Override;
		// return MRES_Supercede; // Infinite loop crash with DHooks
	}

	return MRES_Ignored;
}