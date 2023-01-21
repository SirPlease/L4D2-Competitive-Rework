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
#include <l4d2util_constants>

enum
{
	DoorsTypeTracked_None = -1,
	DoorsTypeTracked_Prop_Door_Rotating = 0,
	DoorTypeTracked_Prop_Door_Rotating_Checkpoint = 1
};

static const char g_szDoors_Type_Tracked[][ENTITY_MAX_NAME_LENGTH] = 
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

ConVar
	g_hCvarDoorSpeed;

float
	g_fDoorSpeed;

public Plugin myinfo = 
{
	name = "Tickrate Fixes",
	author = "Sir, Griffin, A1m`",
	description = "Fixes a handful of silly Tickrate bugs",
	version = "1.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	// Slow Doors
	g_hCvarDoorSpeed = CreateConVar("tick_door_speed", "1.3", "Sets the speed of all prop_door entities on a map. 1.05 means = 105% speed");
	g_fDoorSpeed = g_hCvarDoorSpeed.FloatValue;

	g_hCvarDoorSpeed.AddChangeHook(Cvar_Changed);
	
	Door_ClearSettingsAll();
	Door_GetSettingsAll();
	Door_SetSettingsAll();
	
	// Gravity
	ConVar g_hCvarGravity = FindConVar("sv_gravity");
	if (g_hCvarGravity.IntValue != 750) {
		g_hCvarGravity.SetInt(750, true, false);
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
		if (strcmp(sClassName, g_szDoors_Type_Tracked[i], false) != 0) {
			continue;
		}
	
		SDKHook(iEntity, SDKHook_SpawnPost, Hook_DoorSpawnPost);
	}
}

void Hook_DoorSpawnPost(int iEntity)
{
	if (!IsValidEntity(iEntity)) {
		return;
	}
	
	char sClassName[ENTITY_MAX_NAME_LENGTH];
	GetEntityClassname(iEntity, sClassName, sizeof(sClassName));

	// Save Original Settings.
	for (int i = 0; i < sizeof(g_szDoors_Type_Tracked); i++) {
		if (strcmp(sClassName, g_szDoors_Type_Tracked[i], false) != 0) {
			continue;
		}

		Door_GetSettings(iEntity, i);
	}

	// Set Settings.
	Door_SetSettings(iEntity);
}

void Cvar_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_fDoorSpeed = g_hCvarDoorSpeed.FloatValue;

	Door_SetSettingsAll();
}

void Door_SetSettingsAll()
{
	int iEntity = -1;

	for (int i = 0; i < sizeof(g_szDoors_Type_Tracked); i++) {
		while ((iEntity = FindEntityByClassname(iEntity, g_szDoors_Type_Tracked[i])) != INVALID_ENT_REFERENCE) {
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
		while ((iEntity = FindEntityByClassname(iEntity, g_szDoors_Type_Tracked[i])) != INVALID_ENT_REFERENCE) {
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
	
	for (int i = 0; i < sizeof(g_szDoors_Type_Tracked); i++) {
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
