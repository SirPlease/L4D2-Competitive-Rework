#define PLUGIN_VERSION 		"3.0"

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

#define GAMEDATA            "l4d2_ladderrambos"

// Setting up ConVar Handles
ConVar	Cvar_Enabled;
ConVar	Cvar_M2;
ConVar	Cvar_Reload;
ConVar	Cvar_SgReload;
ConVar	Cvar_Switch;

// ConVar Storage
bool	bCvar_Enabled;
bool	bCvar_M2;
bool	bCvar_Reload;
bool	bCvar_SgReload;
int		iCvar_Switch;

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

// Block shotgun reload
Handle hSDKCall_AbortReload;
Handle hSDKCall_PlayReloadAnim;

// Block empty-clip gun being pulled out 
Handle hSDKCall_Holster;

// Temp storage for shove time
float fSavedShoveTime[MAXPLAYERS+1];

// ====================================================================================================
// myinfo - Basic plugin information
// ====================================================================================================

public Plugin myinfo =
{
	name			=	"Ladder Rambos Dhooks [Merged]",
	author			=	"$atanic $pirit, Lux, Forgetest",
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
	Cvar_Enabled	= CreateConVar(
								"cssladders_enabled",
								"1",
								"Enable the Survivors to shoot from ladders?\n" ...
								"1 to enable, 0 to disable.",
								FCVAR_NOTIFY|FCVAR_SPONLY,
								true, 0.0, true, 1.0);
	Cvar_M2			= CreateConVar(
								"cssladders_allow_m2",
								"0",
								"Allow shoving whilst on a ladder?\n" ...
								"1 to allow, 0 to block.",
								FCVAR_NOTIFY|FCVAR_SPONLY,
								true, 0.0, true, 1.0);
	Cvar_Reload		= CreateConVar(
								"cssladders_allow_reload",
								"1",
								"Allow reloading whilst on a ladder?\n" ...
								"1 to allow, 0 to block.",
								FCVAR_NOTIFY|FCVAR_SPONLY,
								true, 0.0, true, 1.0);
	Cvar_SgReload	= CreateConVar(
								"cssladders_allow_shotgun_reload",
								"1",
								"Allow shotgun reloading whilst on a ladder?\n" ...
								"1 to allow, 0 to block.",
								FCVAR_NOTIFY|FCVAR_SPONLY,
								true, 0.0, true, 1.0);
	Cvar_Switch		= CreateConVar(
								"cssladders_allow_switch",
								"1",
								"Allow switching to other inventory whilst on a ladder?" ...
								"2 to allow all, 1 to allow only between guns, 0 to block.",
								FCVAR_NOTIFY|FCVAR_SPONLY,
								true, 0.0, true, 2.0);
	
	// Setup ConVars change hook
	Cvar_Enabled.AddChangeHook(OnEnableDisable);
	Cvar_M2.AddChangeHook(OnConVarChanged);
	Cvar_Reload.AddChangeHook(OnConVarChanged);
	Cvar_SgReload.AddChangeHook(OnConVarChanged);
	Cvar_Switch.AddChangeHook(OnConVarChanged);
	
	// ConVar Storage
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
	
	StartPrepSDKCall(SDKCall_Entity);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseCombatWeapon::AbortReload")) {
		SetFailState("Failed to find offset \"CBaseCombatWeapon::AbortReload\"");
	} else {
		hSDKCall_AbortReload = EndPrepSDKCall();
		if (hSDKCall_AbortReload == null)
			SetFailState("Failed to setup SDKCall \"CBaseCombatWeapon::AbortReload\"");
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseShotgun::PlayReloadAnim")) {
		SetFailState("Failed to find offset \"CBaseShotgun::PlayReloadAnim\"");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		hSDKCall_PlayReloadAnim = EndPrepSDKCall();
		if (hSDKCall_PlayReloadAnim == null)
			SetFailState("Failed to setup SDKCall \"CBaseShotgun::PlayReloadAnim\"");
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseCombatWeapon::Holster")) {
		SetFailState("Failed to find offset \"CBaseCombatWeapon::Holster\"");
	} else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
		hSDKCall_Holster = EndPrepSDKCall();
		if (hSDKCall_Holster == null)
			SetFailState("Failed to setup SDKCall \"CBaseCombatWeapon::Holster\"");
	}
	
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
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
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
	bCvar_SgReload = Cvar_SgReload.BoolValue;
	iCvar_Switch = Cvar_Switch.IntValue;
}

// ====================================================================================================
// OnClientPutInServer - Reset temp values
// ====================================================================================================

public void OnClientPutInServer(int client)
{
	fSavedShoveTime[client] = 0.0;
}

// ====================================================================================================
// Event_RoundStart - Reset temp values
// ====================================================================================================

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		fSavedShoveTime[i] = 0.0;
}

// ====================================================================================================
// Detour_CanDeployFor - Constantly called to check if player can pull out a weapon
// ====================================================================================================

public MRESReturn Detour_CanDeployFor(int pThis, Handle hReturn)
{
	if (!bCvar_Enabled)
		return MRES_Ignored;
	
	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwner");
	if (client == -1)
		return MRES_Ignored;
	
	bool bIsOnLadder = GetEntityMoveType(client) == MOVETYPE_LADDER;
	
	if (!bIsOnLadder)
	{
		if (fSavedShoveTime[client] > 0.0)
		{
			SetEntPropFloat(client, Prop_Send, "m_flNextShoveTime", fSavedShoveTime[client]);
			fSavedShoveTime[client] = 0.0;
		}
		return MRES_Ignored;
	}
	
	// Infected triggers this though, will be blocked
	if (GetClientTeam(client) != 2)
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	
	// v2.4: Forgot melees, block them
	// v2.5: Forgot other inventories :(
	if (iCvar_Switch < 2 && ( Weapon_IsMelee(pThis) || !Weapon_IsGun(pThis) ))
	{
		// Mimic how original ladder rambos performs
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (weapon != pThis && iCvar_Switch < 1)
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	
	if (!bCvar_M2)
	{
		if (fSavedShoveTime[client] == 0.0)
		{
			fSavedShoveTime[client] = GetEntPropFloat(client, Prop_Send, "m_flNextShoveTime");
		}
		SetEntPropFloat(client, Prop_Send, "m_flNextShoveTime", GetGameTime() + 0.2);
	}
	
	bool bIsShotgun = Weapon_IsShotgun(pThis);
	
	if (bIsShotgun ? (!bCvar_SgReload) : (!bCvar_Reload))
	{
		if (GetEntProp(pThis, Prop_Send, "m_bInReload"))
		{
			Weapon_AbortReload(pThis);
			
			// 1418 = L4D2_ACT_VM_RELOAD_END	(see left4dhooks_anim.inc)
			//    6 = ANIM_RELOAD_SHOTGUN_FINAL	(see l4d2util_constants.inc)
			if (bIsShotgun) Shotgun_PlayReloadAnim(pThis, 1418, 6);
		}
		
		if (GetEntProp(pThis, Prop_Send, "m_iClip1") == 0)
		{
			// TODO: Weapon clip empty check.
			int secondary = GetPlayerWeaponSlot(client, 1);
			if (iCvar_Switch == 0 || (iCvar_Switch == 1 && (secondary == -1 || Weapon_IsMelee(secondary))))
			{
				// Mimic how original ladder rambos performs
				Weapon_Holster(pThis);
				DHookSetReturn(hReturn, 0);
				return MRES_Supercede;
			}
		}
	}
	
	return MRES_Ignored;
}

// ====================================================================================================
// Detour_Reload - Block reload based on ConVar
// ====================================================================================================

public MRESReturn Detour_Reload(int pThis, Handle hReturn)
{
	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwner");
	bool bIsOnLadder = GetEntityMoveType(client) == MOVETYPE_LADDER;
	
	if (bIsOnLadder && !bCvar_Reload)
	{
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

// ====================================================================================================
// Detour_ShotgunReload - Block reload based on ConVar
// ====================================================================================================

public MRESReturn Detour_ShotgunReload(int pThis, Handle hReturn)
{
	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwner");
	
	if (GetEntityMoveType(client) == MOVETYPE_LADDER && !bCvar_SgReload)
	{
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

// ====================================================================================================
// Weapon_IsMelee - Stock method to check if weapon is melee
// ====================================================================================================

bool Weapon_IsMelee(int weapon)
{
	return HasEntProp(weapon, Prop_Send, "m_bInMeleeSwing") || HasEntProp(weapon, Prop_Send, "m_bHitting");
}

// ====================================================================================================
// Weapon_IsGun - Stock method to check if weapon is gun
// ====================================================================================================

bool Weapon_IsGun(int weapon)
{
	return HasEntProp(weapon, Prop_Send, "m_isDualWielding");
}

// ====================================================================================================
// Weapon_IsShotgun - Stock method to check if weapon is shotgun
// ====================================================================================================

bool Weapon_IsShotgun(int weapon)
{
	return HasEntProp(weapon, Prop_Send, "m_reloadNumShells");
}

// ====================================================================================================
// Shotgun_PlayReloadAnim - SDKCall to play specific shotgun reload animation
// ====================================================================================================

void Shotgun_PlayReloadAnim(int weapon, int activity, int event)
{
	SDKCall(hSDKCall_PlayReloadAnim, weapon, activity, event, 0);
}

// ====================================================================================================
// Weapon_AbortReload - SDKCall to abort weapon reload
// ====================================================================================================

void Weapon_AbortReload(int weapon)
{
	SDKCall(hSDKCall_AbortReload, weapon);
}

// ====================================================================================================
// Weapon_Holster - SDKCall to stop pulling out weapon
// ====================================================================================================

void Weapon_Holster(int weapon)
{
	SDKCall(hSDKCall_Holster, weapon, 0);
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