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
#include <sdkhooks>
#include <sdktools>

#define TEAM_SURVIVORS		2

#define MAX_EDICTS			2048 //(1 << 11)
#define ENTITY_MAX_NAME		64

//Tracking
enum /*DoorsTypeTracked*/
{
	DoorsTypeTracked_None = -1,
	DoorsTypeTracked_Prop_Door_Rotating = 0,
	DoorTypeTracked_Prop_Door_Rotating_Checkpoint = 1
};

static const char g_szDoors_Type_Tracked[][MAX_NAME_LENGTH] = 
{
	"prop_door_rotating",
	"prop_door_rotating_checkpoint"
};

#if SOURCEMOD_V_MINOR > 9
enum struct DoorsData
{
	int DoorsData_Type;
	float DoorsData_Speed;
	bool DoorsData_ForceClose;
}

DoorsData
	g_ddDoors[MAX_EDICTS];

#else
enum DoorsData
{
	DoorsData_Type,
	Float:DoorsData_Speed,
	bool:DoorsData_ForceClose
};

DoorsData
	g_ddDoors[MAX_EDICTS][DoorsData];
#endif

//<<<<<<<<<<<<<<<<<<<<< TICKRATE FIXES >>>>>>>>>>>>>>>>>>
//// ------- Fast Pistols ---------
// ***************************** 
ConVar
	g_hPistolDelayDualies,
	g_hPistolDelaySingle,
	g_hPistolDelayIncapped,
	g_hCvarDoorSpeed,
	g_hCvarGravity;

//Floats
float
	g_fNextAttack[MAXPLAYERS + 1],
	g_fPistolDelayDualies = 0.1,
	g_fPistolDelaySingle = 0.2,
	g_fPistolDelayIncapped = 0.3,
	g_fDoorSpeed;

bool
	g_bLateLoad;

public Plugin myinfo = 
{
	name = "Tickrate Fixes",
	author = "Sir, Griffin, A1m`",
	description = "Fixes a handful of silly Tickrate bugs",
	version = "1.3",
	url = "https://github.com/A1mDev/L4D2-Competitive-Rework"
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoad = bLate;

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hPistolDelayDualies = CreateConVar("l4d_pistol_delay_dualies", "0.1", "Minimum time (in seconds) between dual pistol shots",FCVAR_SPONLY | FCVAR_NOTIFY, true, 0.0, true, 5.0);
	g_hPistolDelaySingle = CreateConVar("l4d_pistol_delay_single", "0.2", "Minimum time (in seconds) between single pistol shots", FCVAR_SPONLY | FCVAR_NOTIFY, true, 0.0, true, 5.0);
	g_hPistolDelayIncapped = CreateConVar("l4d_pistol_delay_incapped", "0.3", "Minimum time (in seconds) between pistol shots while incapped", FCVAR_SPONLY | FCVAR_NOTIFY, true, 0.0, true, 5.0);

	UpdatePistolDelays();
	
	g_hPistolDelayDualies.AddChangeHook(Cvar_PistolDelay);
	g_hPistolDelaySingle.AddChangeHook(Cvar_PistolDelay);
	g_hPistolDelayIncapped.AddChangeHook(Cvar_PistolDelay);
	
	HookEvent("weapon_fire", Event_WeaponFire);

	// Slow Doors
	g_hCvarDoorSpeed = CreateConVar("tick_door_speed", "1.3", "Sets the speed of all prop_door entities on a map. 1.05 means = 105% speed");
	g_fDoorSpeed = g_hCvarDoorSpeed.FloatValue;

	g_hCvarDoorSpeed.AddChangeHook(Cvar_Changed);
	
	Door_ClearSettingsAll();
	Door_GetSettingsAll();
	Door_SetSettingsAll();
	
	//Gravity
	g_hCvarGravity = FindConVar("sv_gravity");
	if (g_hCvarGravity.IntValue != 750) {
		g_hCvarGravity.SetInt(750, true, false);
	}
	
	//Hook Pistols
	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnPluginEnd()
{
	Door_ResetSettingsAll();
}

public void OnEntityCreated(int iEntity, const char[] sClassName)
{
	if (sClassName[0] != 'p') {
		return;
	}
	
	for (int i = 0; i < sizeof(g_szDoors_Type_Tracked); i++) {
		if (strcmp(sClassName, g_szDoors_Type_Tracked[i], false) == 0) {
			SDKHook(iEntity, SDKHook_SpawnPost, Hook_DoorSpawnPost);
		}
	}
}

public void Hook_DoorSpawnPost(int iEntity)
{
	if (!IsValidEntity(iEntity)) {
		return;
	}
	
	char sClassName[ENTITY_MAX_NAME];
	GetEntityClassname(iEntity, sClassName, sizeof(sClassName));

	// Save Original Settings.
	for (int i = 0; i < sizeof(g_szDoors_Type_Tracked); i++) {
		if (strcmp(sClassName, g_szDoors_Type_Tracked[i], false) == 0) {
			Door_GetSettings(iEntity, i);
		}
	}

	// Set Settings.
	Door_SetSettings(iEntity);
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_PreThink, Hook_OnPreThink);

	g_fNextAttack[iClient] = 0.0;
}

public void OnClientDisconnect(int iClient)
{
	SDKUnhook(iClient, SDKHook_PreThink, Hook_OnPreThink);
}

public void Cvar_PistolDelay(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	UpdatePistolDelays();
}

void UpdatePistolDelays()
{
	g_fPistolDelayDualies = g_hPistolDelayDualies.FloatValue;
	if (g_fPistolDelayDualies < 0.0) {
		g_fPistolDelayDualies = 0.0;
	} else if (g_fPistolDelayDualies > 5.0) {
		g_fPistolDelayDualies = 5.0;
	}
	
	g_fPistolDelaySingle = g_hPistolDelaySingle.FloatValue;
	if (g_fPistolDelaySingle < 0.0) {
		g_fPistolDelaySingle = 0.0;
	} else if (g_fPistolDelaySingle > 5.0) {
		g_fPistolDelaySingle = 5.0;
	}
	
	g_fPistolDelayIncapped = g_hPistolDelayIncapped.FloatValue;
	if (g_fPistolDelayIncapped < 0.0) {
		g_fPistolDelayIncapped = 0.0;
	} else if (g_fPistolDelayIncapped > 5.0) {
		g_fPistolDelayIncapped = 5.0;
	}
}

public void Hook_OnPreThink(int iClient)
{
	// Human survivors only
	if (!IsClientInGame(iClient) || IsFakeClient(iClient) || GetClientTeam(iClient) != TEAM_SURVIVORS) {
		return;
	}

	int iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEdict(iActiveWeapon)) {
		return;
	}
	
	char sWeaponName[ENTITY_MAX_NAME];
	GetEdictClassname(iActiveWeapon, sWeaponName, sizeof(sWeaponName));
	if (strcmp(sWeaponName, "weapon_pistol") != 0) {
		return;
	}
	
	float fOldValue = GetEntPropFloat(iActiveWeapon, Prop_Send, "m_flNextPrimaryAttack");
	float fNewValue = g_fNextAttack[iClient];

	// Never accidentally speed up fire rate
	if (fNewValue > fOldValue) {
		// PrintToChatAll("Readjusting delay: Old=%f, New=%f", fOldValue, fNewValue);
		SetEntPropFloat(iActiveWeapon, Prop_Send, "m_flNextPrimaryAttack", fNewValue);
	}
}

public void Event_WeaponFire(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iClient < 1 || IsFakeClient(iClient) || GetClientTeam(iClient) != TEAM_SURVIVORS) {
		return;
	}
	
	int iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEdict(iActiveWeapon)) {
		return;
	}
	
	char sWeaponName[ENTITY_MAX_NAME];
	GetEdictClassname(iActiveWeapon, sWeaponName, sizeof(sWeaponName));
	if (strcmp(sWeaponName, "weapon_pistol") != 0) {
		return;
	}
	
	// int iDualies = GetEntProp(iActiveWeapon, Prop_Send, "m_hasDualWeapons");

	if (GetEntProp(iClient, Prop_Send, "m_isIncapacitated")) {
		g_fNextAttack[iClient] = GetGameTime() + g_fPistolDelayIncapped;
	} else if (GetEntProp(iActiveWeapon, Prop_Send, "m_isDualWielding")) { // What is the difference between m_isDualWielding and m_hasDualWeapons ?
		g_fNextAttack[iClient] = GetGameTime() + g_fPistolDelayDualies;
	} else {
		g_fNextAttack[iClient] = GetGameTime() + g_fPistolDelaySingle;
	}
}

public void Cvar_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_fDoorSpeed = g_hCvarDoorSpeed.FloatValue;

	Door_SetSettingsAll();
}

void Door_SetSettingsAll()
{
	int iEntity = -1;

	for (int i = 0; i < sizeof(g_szDoors_Type_Tracked); i++) {
		while ((iEntity = FindEntityByClassname(iEntity, g_szDoors_Type_Tracked[i])) != -1) {
			Door_SetSettings(iEntity);
			SetEntProp(iEntity, Prop_Data, "m_bForceClosed", false);
		}
		
		iEntity = -1;
	}
}

void Door_SetSettings(int iEntity)
{
#if SOURCEMOD_V_MINOR > 9
	float fSpeed = g_ddDoors[iEntity].DoorsData_Speed * g_fDoorSpeed;
#else
	float fSpeed = g_ddDoors[iEntity][DoorsData_Speed] * g_fDoorSpeed;
#endif

	SetEntPropFloat(iEntity, Prop_Data, "m_flSpeed", fSpeed);
}

void Door_ResetSettingsAll()
{
	int iEntity = -1;

	for (int i = 0; i < sizeof(g_szDoors_Type_Tracked); i++) {
		while ((iEntity = FindEntityByClassname(iEntity, g_szDoors_Type_Tracked[i])) != -1) {
			Door_ResetSettings(iEntity);
		}
		
		iEntity = -1;
	}
}

void Door_ResetSettings(int iEntity)
{
#if SOURCEMOD_V_MINOR > 9
	float fSpeed = g_ddDoors[iEntity].DoorsData_Speed;
#else
	float fSpeed = g_ddDoors[iEntity][DoorsData_Speed];
#endif

	SetEntPropFloat(iEntity, Prop_Data, "m_flSpeed", fSpeed);
}

void Door_GetSettingsAll()
{
	int iEntity = -1;
	
	for (int i = 0;i < sizeof(g_szDoors_Type_Tracked); i++) {
		while ((iEntity = FindEntityByClassname(iEntity, g_szDoors_Type_Tracked[i])) != INVALID_ENT_REFERENCE) {
			Door_GetSettings(iEntity, i);
		}
		
		iEntity = -1;
	}
}

void Door_GetSettings(int iEntity, int iDoorType)
{
#if SOURCEMOD_V_MINOR > 9
	g_ddDoors[iEntity].DoorsData_Type = iDoorType;
	g_ddDoors[iEntity].DoorsData_Speed = GetEntPropFloat(iEntity, Prop_Data, "m_flSpeed");
	g_ddDoors[iEntity].DoorsData_ForceClose = view_as<bool>(GetEntProp(iEntity, Prop_Data, "m_bForceClosed"));
#else
	g_ddDoors[iEntity][DoorsData_Type] = iDoorType;
	g_ddDoors[iEntity][DoorsData_Speed] = GetEntPropFloat(iEntity, Prop_Data, "m_flSpeed");
	g_ddDoors[iEntity][DoorsData_ForceClose] = view_as<bool>(GetEntProp(iEntity, Prop_Data, "m_bForceClosed"));
#endif
}

void Door_ClearSettingsAll()
{
	for (int i = 0; i < MAX_EDICTS; i++) {
		#if SOURCEMOD_V_MINOR > 9
			g_ddDoors[i].DoorsData_Type = DoorsTypeTracked_None;
			g_ddDoors[i].DoorsData_Speed = 0.0;
			g_ddDoors[i].DoorsData_ForceClose = false;
		#else
			g_ddDoors[i][DoorsData_Type] = DoorsTypeTracked_None;
			g_ddDoors[i][DoorsData_Speed] = 0.0;
			g_ddDoors[i][DoorsData_ForceClose] = false;
		#endif
	}
}
