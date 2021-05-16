#define PLUGIN_VERSION 		"1.0"

/*
*	Ladder Rambos Dhooks
*	Copyright (C) 2021 $atanic $pirit
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

/*
// ====================================================================================================
//
// Special thanks to:
// 
// 	* Ilya 'Visor' Komarov	- Original creator of ladder rambos extension.
// 	* Crasher_3637			- For providing the windows signature for CTerrorGun::Holster function.
// 	* Lux					- For providing the windows signature for CBaseShotgun::Reload function.
// 	* Silver				- For providing the various signatures, being a very knowledgeable coder and plugin release format. Learned a lot from his work. 
// 
// ====================================================================================================
*/


#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define GAMEDATA			"l4d2_ladderrambos"

// Setting up ConVAr Handles
ConVar	Cvar_Enabled;
ConVar	Cvar_M2;
ConVar	Cvar_Reload;
ConVar	Cvar_Debug;

// Global variables to hold offset.
Address	g_pAddress;
int		g_iOffsetPrethink;

// ====================================================================================================
// myinfo - Basic plugin information
// ====================================================================================================

public Plugin myinfo =
{
	name			=	"Ladder Rambos Dhooks",
	author			=	"$atanic $pirit",
	description		=	"Allows players to shoot from Ladders",
	version			=	PLUGIN_VERSION,
	url				=	""
}

// ====================================================================================================
// OnPluginStart - Setting CVARS and Configuring Hooks
// ====================================================================================================
	
public void OnPluginStart()
{	
	// Setup plugin ConVars
	Cvar_Enabled	= CreateConVar("cssladders_enabled",			"1",	"Enable the Survivors to shoot from ladders? 1 to enable, 0 to disable.");
	Cvar_M2			= CreateConVar("cssladders_allow_m2",			"0",	"Allow shoving whilst on a ladder? 1 to allow M2, 0 to block.");
	Cvar_Reload		= CreateConVar("cssladders_allow_reload",		"1",	"Allow reloading whilst on a ladder? 1 to allow M2, 0 to block. Keep in mind that shotguns are broken and won't reload on ladders no matter what.");
	Cvar_Debug		= CreateConVar("cssladders_debug",				"0",	"On/Off switch to log debug messages");
	
	// Load the GameData file.
	GameData hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	//Get signature for Holster.			
	Handle hDetour_Holster = DHookCreateFromConf(hGameData, "CTerrorGun::Holster");
	if( !hDetour_Holster )
		SetFailState("Failed to setup detour for hDetour_Holster");
		
	// Get signature for reload weapon.			
	Handle hDetour_Reload = DHookCreateFromConf(hGameData, "CTerrorGun::Reload");
	if( !hDetour_Reload )
		SetFailState("Failed to setup detour for hDetour_Reload");

	// Get signature for reload shotgun specific			
	Handle hDetour_ShotgunReload = DHookCreateFromConf(hGameData, "CBaseShotgun::Reload");
	if( !hDetour_ShotgunReload )
		SetFailState("Failed to setup detour for hDetour_ShotgunReload");
	
	// Get signature for Prethink
	g_pAddress			= hGameData.GetAddress("CTerrorPlayer::PreThink");
	if(!g_pAddress)
		SetFailState("Failed to get 'CTerrorPlayer::PreThink' signature.");
	
	// Get offset for SafeDropPatch
	g_iOffsetPrethink	= hGameData.GetOffset("CTerrorPlayer::PreThink__SafeDropLogic");
	if(!g_iOffsetPrethink)
		SetFailState("Failed to get 'CTerrorPlayer::PreThink__SafeDropLogic' offset.");

	delete hGameData;
	
	// And a pre hook for CTerrorGun::Holster.
	if (!DHookEnableDetour(hDetour_Holster, false, Detour_Holster))
		SetFailState("Failed to detour CTerrorGun::Holster post.");
		
	
	// And a pre hook for CTerrorGun::Reload.
	if (!DHookEnableDetour(hDetour_Reload, false, Detour_Reload))
		SetFailState("Failed to detour CTerrorGun::Reload post.");
	
	// And a pre hook for CBaseShotgun::Reload.
	if (!DHookEnableDetour(hDetour_ShotgunReload, false, Detour_ShotgunReload))
		SetFailState("Failed to detour CBaseShotgun::Reload post.");
	
	// Apply our patch
	SafeDropPatch(true);
}

// ====================================================================================================
// OnPluginEnd - Remove our SafeDropPatch to avoid crashes
// ====================================================================================================
public void OnPluginEnd()
{
	// Remove our patch
	SafeDropPatch(false);
}

// ====================================================================================================
// Detour_Holster - When does a survivor pull out a gun?
// ====================================================================================================

public MRESReturn Detour_Holster(Address pThis, Handle hReturn)
{	
	if(!Cvar_Enabled.BoolValue)
		return MRES_Ignored;
	
	int client = GetClientFromPointer(pThis);
	
	if(IsPlayerOnLadder(client) && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		if(!Cvar_M2.BoolValue)
			SetEntPropFloat(client, Prop_Send, "m_flNextShoveTime", GetGameTime() + 0.3);
		
		LogAcitivity("Function::Detour_Holster IsPlayerOnLadder: %d, %N", client, client);
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

// ====================================================================================================
// Detour_Reload - Block reload based on ConVar
// ====================================================================================================

public MRESReturn Detour_Reload(Address pThis, Handle hReturn)
{
	int client = GetClientFromPointer(pThis);
	if(!Cvar_Reload.BoolValue && IsPlayerOnLadder(client))
	{
		LogAcitivity("Function::Detour_Reload blocking reload for %d, %N", client, client);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

// ====================================================================================================
// Detour_ShotgunReload - Block reload based on ConVar
// ====================================================================================================

public MRESReturn Detour_ShotgunReload(Address pThis, Handle hReturn)
{
	int client = GetClientFromPointer(pThis);
	if(!Cvar_Reload.BoolValue && IsPlayerOnLadder(client))
	{
		LogAcitivity("Function::Detour_ShotgunReload blocking reload for %d, %N", client, client);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

// ====================================================================================================
// IsPlayerOnLadder - Is player's move type ladder?
// ====================================================================================================

stock bool IsPlayerOnLadder(int client)
{
	return GetEntityMoveType(client) == MOVETYPE_LADDER;
}

// ====================================================================================================
// GetClientFromPointer - Get the entity owner, which is our client.
// ====================================================================================================

stock int GetClientFromPointer(Address pThis)
{	
	return GetEntPropEnt(view_as<int>(pThis), Prop_Data, "m_hOwnerEntity");
}

// ====================================================================================================
// LogAcitivity - Log debug messages
// ====================================================================================================

stock void LogAcitivity(const char[] format, any ...)
{
	if(Cvar_Debug.BoolValue)
	{
		char LogFilePath[PLATFORM_MAX_PATH];
		
		// Build LogFile path
		BuildPath(Path_SM, LogFilePath, sizeof(LogFilePath), "logs/l4d2_LadderRambos.txt");

		char buffer[512];
		VFormat(buffer, sizeof(buffer), format, 2);
		LogToFile(LogFilePath, "%s", buffer);
	}
}


// ====================================================================================================
// SafeDropPatch - Patching/UnPatching the memory
// ====================================================================================================

stock void SafeDropPatch(bool enable)
{	
	int patchBytes = 0x14;
	int originalBytes = 0x09;
	int CurrentoriginalBytes = LoadFromAddress(g_pAddress + view_as<Address>(g_iOffsetPrethink), NumberType_Int8);
	int patch = enable? patchBytes : originalBytes;
	
	LogAcitivity("SafeDropPatch: Current Original Byte: %x - %d", CurrentoriginalBytes, CurrentoriginalBytes);

	if (CurrentoriginalBytes != patch)
	{
		StoreToAddress(g_pAddress + view_as<Address>(g_iOffsetPrethink), patch, NumberType_Int8);
		int ret = LoadFromAddress(g_pAddress + view_as<Address>(g_iOffsetPrethink), NumberType_Int8);
		LogAcitivity("SafeDropPatch: Checking the byte: %x - %d.", ret, ret);
	}
	/*
	
	This is my hacky way of finding physical offsets. I know the byte I'm looking for is 0x09, so i just run a loop and test the offsets. In this case it was the second instance of 0x09 on windows. Linux offset was copied from ladder rambos extension.
	
	Leaving it in here for future use.
	
	int Byte;
	for(int i; i <= 500; i++)
	{
		Byte = LoadFromAddress(g_pAddress + view_as<Address>(i), NumberType_Int8);
		LogAcitivity("SafeDropPatch Loop: Current Byte: %x - %d", Byte, Byte);
		if(Byte == 0x09)
		{
			LogAcitivity("SafeDropPatch Loop: Offset: %x - %d", i, i);
		}
		continue;
	}
	*/
}