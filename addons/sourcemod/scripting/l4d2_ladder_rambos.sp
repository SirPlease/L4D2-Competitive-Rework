#define PLUGIN_VERSION 		"2.3"

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

#define REQUIRE_EXTENSIONS
#include <sourcescramble>

#define GAMEDATA			"l4d2_ladderrambos"

// Setting up ConVAr Handles
ConVar	Cvar_Enabled;
ConVar	Cvar_M2;
ConVar	Cvar_Reload;
ConVar	Cvar_Debug;

// ConVAr Storage
bool	bCvar_Enabled;
bool	bCvar_M2;
bool	bCvar_Reload;
bool	bCvar_Debug;

// Patching from [l4d2_cs_ladders] credit to Lux
#define PLUGIN_NAME_KEY "[cs_ladders]"
#define TERROR_CAN_DEPLOY_FOR_KEY "CTerrorWeapon::CanDeployFor__movetype_patch"
#define TERROR_PRE_THINK_KEY "CTerrorPlayer::PreThink__SafeDropLogic_patch"
#define TERROR_ON_LADDER_MOUNT_KEY "CTerrorPlayer::OnLadderMount__WeaponHolster_patch"
#define TERROR_ON_LADDER_DISMOUNT_KEY "CTerrorPlayer::OnLadderDismount__WeaponDeploy_patch"

MemoryPatch hPatch_CanDeployFor;
MemoryPatch hPatch_PreThink;
MemoryPatch hPatch_OnLadderMount;
MemoryPatch hPatch_OnLadderDismount;

// ====================================================================================================
// myinfo - Basic plugin information
// ====================================================================================================

public Plugin myinfo =
{
	name			=	"Ladder Rambos Dhooks [Merged]",
	author			=	"$atanic $pirit, Lux",
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
	
	// Setup ConVars change hook
	Cvar_Enabled.AddChangeHook(OnEnableDisable);
	Cvar_M2.AddChangeHook(OnConVarChanged);
	Cvar_Reload.AddChangeHook(OnConVarChanged);
	Cvar_Debug.AddChangeHook(OnConVarChanged);
	
	// ConVAr Storage
	GetCvars();
	
	// Load the GameData file.
	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	//Get signature for CanDeployFor.
	Handle hDetour_CanDeployFor = DHookCreateFromConf(hGameData, "CTerrorWeapon::CanDeployFor");
	if( !hDetour_CanDeployFor )
		SetFailState("Failed to setup detour for hDetour_CanDeployFor");
	
	// Get signature for reload weapon.
	Handle hDetour_Reload = DHookCreateFromConf(hGameData, "CTerrorGun::Reload");
	if( !hDetour_Reload )
		SetFailState("Failed to setup detour for hDetour_Reload");

	// Get signature for reload shotgun specific
	Handle hDetour_ShotgunReload = DHookCreateFromConf(hGameData, "CBaseShotgun::Reload");
	if( !hDetour_ShotgunReload )
		SetFailState("Failed to setup detour for hDetour_ShotgunReload");
	
	hPatch_CanDeployFor = MemoryPatch.CreateFromConf(hGameData, TERROR_CAN_DEPLOY_FOR_KEY);
	if(!hPatch_CanDeployFor.Validate())
		SetFailState("%s Failed to validate patch \"%s\"", PLUGIN_NAME_KEY, TERROR_CAN_DEPLOY_FOR_KEY);
	
	hPatch_PreThink = MemoryPatch.CreateFromConf(hGameData, TERROR_PRE_THINK_KEY);
	if(!hPatch_PreThink.Validate())
		SetFailState("%s Failed to validate patch \"%s\"", PLUGIN_NAME_KEY, TERROR_PRE_THINK_KEY);
	
	// not as important as first 2 patches, can still function enough to be good enough.
	hPatch_OnLadderMount = MemoryPatch.CreateFromConf(hGameData, TERROR_ON_LADDER_MOUNT_KEY);
	if(!hPatch_OnLadderMount.Validate())
		LogError("%s Failed to validate patch \"%s\"", PLUGIN_NAME_KEY, TERROR_ON_LADDER_MOUNT_KEY);
	
	hPatch_OnLadderDismount = MemoryPatch.CreateFromConf(hGameData, TERROR_ON_LADDER_DISMOUNT_KEY);
	if(!hPatch_OnLadderDismount.Validate())
		LogError("%s Failed to validate patch \"%s\"", PLUGIN_NAME_KEY, TERROR_ON_LADDER_DISMOUNT_KEY);
	
	delete hGameData;
	
	// And a pre hook for CTerrorWeapon::CanDeployFor.
	if (!DHookEnableDetour(hDetour_CanDeployFor, false, Detour_CanDeployFor))
		SetFailState("Failed to detour CTerrorWeapon::CanDeployFor post.");
	
	// And a pre hook for CTerrorGun::Reload.
	if (!DHookEnableDetour(hDetour_Reload, false, Detour_Reload))
		SetFailState("Failed to detour CTerrorGun::Reload post.");
	
	// And a pre hook for CBaseShotgun::Reload.
	if (!DHookEnableDetour(hDetour_ShotgunReload, false, Detour_ShotgunReload))
		SetFailState("Failed to detour CBaseShotgun::Reload post.");
	
	// Apply our patch
	ApplyPatch((bCvar_Enabled = Cvar_Enabled.BoolValue));
}

// ====================================================================================================
// OnPluginEnd - Remove our SafeDropPatch to avoid crashes
// ====================================================================================================

public void OnPluginEnd()
{
	// Remove our patch
	ApplyPatch(false);
}

// ====================================================================================================
// OnConfigExecuted - Patch or unpatch
// ====================================================================================================

public void OnConfigsExecuted()
{
	ApplyPatch(bCvar_Enabled);
}

// ====================================================================================================
// OnEnableDisable - Patch or unpatch
// ====================================================================================================

public void OnEnableDisable(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ApplyPatch((bCvar_Enabled = Cvar_Enabled.BoolValue));
}

// ====================================================================================================
// OnConVarChanged - Refresh ConVar storage
// ====================================================================================================

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

// ====================================================================================================
// GetCvars - Cache the values of ConVars to improve performance
// ====================================================================================================

void GetCvars()
{
	bCvar_M2 = Cvar_M2.BoolValue;
	bCvar_Reload = Cvar_Reload.BoolValue;
	bCvar_Debug = Cvar_Debug.BoolValue;
}

// ====================================================================================================
// Detour_CanDeployFor - Constantly called to check if player can pull out a weapon
// ====================================================================================================

public MRESReturn Detour_CanDeployFor(int pThis, Handle hReturn)
{
	if(!bCvar_Enabled)
		return MRES_Ignored;
	
	int client = GetEntPropEnt(pThis, Prop_Data, "m_hOwnerEntity");
	if (client == -1)
		return MRES_Ignored;
	
	bool bIsOnLadder = GetEntityMoveType(client) == MOVETYPE_LADDER;
	
	if (bIsOnLadder)
	{
		if (GetClientTeam(client) == 2) // Infected triggers this though, will be blocked
		{
			if(!bCvar_M2)
				SetEntPropFloat(client, Prop_Send, "m_flNextShoveTime", GetGameTime() + 0.1);
			
			int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
			if (weapon == pThis || weapon == EntRefToEntIndex(pThis)/* Safety? */)
				return MRES_Ignored;
			
			LogAcitivity("Function::Detour_CanDeployFor IsPlayerOnLadder: %d, %N", bIsOnLadder, client);
		}
		
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

// ====================================================================================================
// Detour_Reload - Block reload based on ConVar
// ====================================================================================================

public MRESReturn Detour_Reload(int pThis, Handle hReturn)
{
	int client = GetEntPropEnt(pThis, Prop_Data, "m_hOwnerEntity");
	bool bIsOnLadder = GetEntityMoveType(client) == MOVETYPE_LADDER;
	if(!bCvar_Reload && bIsOnLadder)
	{
		LogAcitivity("Function::Detour_Reload blocking reload for %d, %N", bIsOnLadder, client);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

// ====================================================================================================
// Detour_ShotgunReload - Block reload based on ConVar
// ====================================================================================================

public MRESReturn Detour_ShotgunReload(int pThis, Handle hReturn)
{
	int client = GetEntPropEnt(pThis, Prop_Data, "m_hOwnerEntity");
	bool bIsOnLadder = GetEntityMoveType(client) == MOVETYPE_LADDER;
	if(!bCvar_Reload && bIsOnLadder)
	{
		LogAcitivity("Function::Detour_ShotgunReload blocking reload for %d, %N", bIsOnLadder, client);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

// ====================================================================================================
// LogAcitivity - Log debug messages
// ====================================================================================================

stock void LogAcitivity(const char[] format, any ...)
{
	if(bCvar_Debug)
	{
		static char LogFilePath[PLATFORM_MAX_PATH];
		
		// Build LogFile path
		if (LogFilePath[0] == '\0')
		{
			BuildPath(Path_SM, LogFilePath, sizeof(LogFilePath), "logs/l4d2_LadderRambos.txt");
		}

		char buffer[512];
		VFormat(buffer, sizeof(buffer), format, 2);
		LogToFile(LogFilePath, buffer);
		PrintToChatAll(buffer);
	}
}


// ====================================================================================================
// SafeDropPatch - Patching/UnPatching the memory
// ====================================================================================================

stock void ApplyPatch(bool patch)
{	
	static bool patched = false;
	if (patch && !patched)
	{
		if(hPatch_CanDeployFor.Enable())
			PrintToServer("%s Enabled \"%s\" patch", PLUGIN_NAME_KEY, TERROR_CAN_DEPLOY_FOR_KEY);
		
		if(hPatch_PreThink.Enable())
			PrintToServer("%s Enabled \"%s\" patch", PLUGIN_NAME_KEY, TERROR_PRE_THINK_KEY);
		
		if(hPatch_OnLadderMount.Enable())
			PrintToServer("%s Enabled \"%s\" patch", PLUGIN_NAME_KEY, TERROR_ON_LADDER_MOUNT_KEY);
		
		if(hPatch_OnLadderDismount.Enable())
			PrintToServer("%s Enabled \"%s\" patch", PLUGIN_NAME_KEY, TERROR_ON_LADDER_DISMOUNT_KEY);
		
		patched = true;
	}
	else if (!patch && patched)
	{
		hPatch_CanDeployFor.Disable();
		hPatch_PreThink.Disable();
		hPatch_OnLadderMount.Disable();
		hPatch_OnLadderDismount.Disable();
		
		patched = false;
	}
}