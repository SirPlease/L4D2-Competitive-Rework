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

#define GAMEDATA "charger_collision_patch"
#define PLUGIN_VERSION	"1.1"

static float g_fPreventDamage[MAXPLAYERS+1][MAXPLAYERS+1];

Address Collision_Address = Address_Null;

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
	name = "[L4D2]Charger_Collision_Patch",
	author = "Lux",
	description = "Fixes charger only allow to his 1 survivor index & allows charging same target more than once",
	version = PLUGIN_VERSION,
	url = "forums.alliedmods.net/showthread.php?p=2647017"
};


public void OnPluginStart()
{
	CreateConVar("charger_collision_patch_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	Address patch = GameConfGetAddress(hGamedata, "CCharge::HandleCustomCollision");
	
	if(!patch) 
		SetFailState("Error finding the 'CCharge::HandleCustomCollision' signature.");
	
	int offset = GameConfGetOffset(hGamedata, "CCharge::HandleCustomCollision");
	if( offset == -1 ) 
		SetFailState("Invalid offset for 'CCharge::HandleCustomCollision'.");
	
	int byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
	if(byte == 0x01)
	{
		Collision_Address = patch + view_as<Address>(offset);
		StoreToAddress(Collision_Address, 0x00, NumberType_Int8);
		PrintToServer("ChargerCollision patch applied 'CCharge::HandleCustomCollision'");
		
		Handle hConvar = FindConVar("z_charge_max_force");
		SetConVarFloat(hConvar, GetConVarFloat(hConvar) * 0.25);
		HookConVarChange(hConvar, ScaleDownCvar);
		
		hConvar = FindConVar("z_charge_min_force");
		SetConVarFloat(hConvar, GetConVarFloat(hConvar) * 0.25);
		HookConVarChange(hConvar, ScaleDownCvar);
		HookEvent("charger_impact", eChargerImpact, EventHookMode_Pre);
		
	}
	else
	{
		LogError("Error: the Nothing is correct!");
	}
	delete hGamedata;
}

public void ScaleDownCvar(ConVar hConvar, const char[] sOldValue, const char[] sNewValue)
{
	static bool bIgnore = false;
	if(bIgnore)
		return;
	
	bIgnore = true;
	SetConVarFloat(hConvar, GetConVarFloat(hConvar) * 0.25);
	bIgnore = false;
}

public void eChargerImpact(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("victim"));
	if(iVictim < 1 || !IsClientInGame(iVictim) || !IsPlayerAlive(iVictim))
		return;

	int iCharger = GetClientOfUserId(hEvent.GetInt("userid"));
	if(iCharger < 1 || !IsClientInGame(iCharger) || !IsPlayerAlive(iCharger))
		return;
	
	g_fPreventDamage[iCharger][iVictim] = GetEngineTime() + 0.5;
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if(sClassname[0] != 's' || !StrEqual(sClassname, "survivor_bot"))
	 	return;
	 
	SDKHook(iEntity, SDKHook_OnTakeDamage, BlockRecursiveDamage);
}

public void OnClientPutInServer(int iClient)
{
	if(!IsFakeClient(iClient))
		SDKHook(iClient, SDKHook_OnTakeDamage, BlockRecursiveDamage);
}

public Action BlockRecursiveDamage(int iVictim, int &iCharger, int &iInflictor, float &fDamage, int &iDamagetype)
{
	if(GetClientTeam(iVictim) != 2)
		return Plugin_Continue;
	
	if(iCharger < 1 || iCharger > MaxClients || 
		GetClientTeam(iCharger) != 3 || !IsPlayerAlive(iCharger) || 
		GetEntProp(iCharger, Prop_Send, "m_zombieClass", 1) != 6 )
		return Plugin_Continue;
	
	int iAbility = GetEntPropEnt(iCharger, Prop_Send, "m_customAbility");
	if(iAbility <= MaxClients || !HasEntProp(iAbility, Prop_Send, "m_isCharging"))
		return Plugin_Continue;
	
	if(GetEntProp(iAbility, Prop_Send, "m_isCharging", 1))
	{
		if(GetEntPropEnt(iVictim, Prop_Send, "m_carryAttacker") == iCharger &&
			GetEntPropEnt(iCharger, Prop_Send, "m_carryVictim") == iVictim)
			return Plugin_Continue;
			
		if(g_fPreventDamage[iCharger][iVictim] > GetEngineTime())
			return Plugin_Handled;
			
	}
	return Plugin_Continue;
}

public void OnPluginEnd()
{
	if(Collision_Address == Address_Null)
		return;
	
	StoreToAddress(Collision_Address, 0x01, NumberType_Int8);
	PrintToServer("ChargerCollision patch restored 'CCharge::HandleCustomCollision'");
	
	Handle hConvar = FindConVar("z_charge_max_force");
	UnhookConVarChange(hConvar, ScaleDownCvar);
	SetConVarFloat(hConvar, GetConVarFloat(hConvar) / 0.25);
	
	hConvar = FindConVar("z_charge_min_force");
	UnhookConVarChange(hConvar, ScaleDownCvar);
	SetConVarFloat(hConvar, GetConVarFloat(hConvar) / 0.25);
	
	PrintToServer("ChargerCollision restored 'z_charge_max_force/z_charge_min_force' convars'");
}
