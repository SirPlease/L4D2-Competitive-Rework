/*  
*    Fixes for gamebreaking bugs and stupid gameplay aspects
*    Copyright (C) 2019  LuxLuma		acceliacat@gmail.com
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#pragma newdecls required

#define GAMEDATA "witch_allow_in_safezone"

#define PLUGIN_VERSION	"1.1"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion CurrentEngine = GetEngineVersion();
	if(CurrentEngine != Engine_Left4Dead2 && CurrentEngine != Engine_Left4Dead)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1/2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

// Harry Potter
// https://github.com/fbef0102
public Plugin myinfo =
{
	name = "[L4D1/2]Witch_allow_in_safezone",
	author = "Lux & Harry Potter",
	description = "Allows witches to chase victims into safezones",
	version = PLUGIN_VERSION,
	url = "-"
}

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	Handle hDetour;
	
	if(GetEngineVersion() == Engine_Left4Dead2)
	{
		hDetour = DHookCreateFromConf(hGamedata, "CDirector::AllowWitchesInCheckpoints");
		if(!hDetour)
			SetFailState("Failed to find \"CDirector::AllowWitchesInCheckpoints\" signature.");
			
		if(!DHookEnableDetour(hDetour, true, AllowWitchesInCheckpoints))
			SetFailState("Failed to detour \"CDirector::AllowWitchesInCheckpoints\".");
	}
	else
	{
		hDetour = DHookCreateFromConf(hGamedata, "WitchLocomotion::IsAreaTraversable");
		if(!hDetour)
			SetFailState("Failed to find \"WitchLocomotion::IsAreaTraversable\" signature.");
			
		if(!DHookEnableDetour(hDetour, true, AllowWitchesInCheckpoints))
			SetFailState("Failed to detour \"WitchLocomotion::IsAreaTraversable\".");
	}
	
	delete hGamedata;
}

public MRESReturn AllowWitchesInCheckpoints(Handle hReturn)
{
	DHookSetReturn(hReturn, true);
	return MRES_Override;
}