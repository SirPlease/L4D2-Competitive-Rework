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

#pragma newdecls required

#define PLUGIN_VERSION	"1.0"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D2]Witch_Double_Start_Fix",
	author = "Lux",
	description = "Fixes witch when wandering playing startle twice by forcing the NextThink to end the startle.",
	version = PLUGIN_VERSION,
	url = "forums.alliedmods.net/showthread.php?p=2647014"
};

public void OnPluginStart()
{
	CreateConVar("witch_double_start_fix", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if(sClassname[0] != 'w' || !StrEqual(sClassname, "witch", false))
		return;
	
	SDKHook(iEntity, SDKHook_Think, OnThink);
}


public void OnThink(int iWitch)
{
	if(GetEntProp(iWitch, Prop_Data, "m_iHealth") < 1)
		return;
	
	if(GetEntProp(iWitch, Prop_Send, "m_nSequence", 2) == 30)
		SetEntPropFloat(iWitch, Prop_Send, "m_flCycle", 1.0);
}


