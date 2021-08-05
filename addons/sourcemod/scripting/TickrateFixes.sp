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

#define TEAM_SURVIVORS	2

#define MAX_EDICTS		2048 //(1 << 11)
#define ENTITY_MAX_NAME 64

//Tracking
enum DoorsTypeTracked
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
	DoorsTypeTracked DoorsData_Type;
	float DoorsData_Speed;
	bool DoorsData_ForceClose;
}

DoorsData
	g_ddDoors[MAX_EDICTS];

#else
enum DoorsData
{
	DoorsTypeTracked:DoorsData_Type,
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
	hCvarDoorSpeed,
	g_hCvarGravity;

//Floats
float
	g_fNextAttack[MAXPLAYERS + 1],
	g_fPistolDelayDualies = 0.1,
	g_fPistolDelaySingle = 0.2,
	g_fPistolDelayIncapped = 0.3,
	fDoorSpeed;

bool
	bLateLoad;

public Plugin myinfo = 
{
	name = "Tickrate Fixes",
	author = "Sir, Griffin, A1m`",
	description = "Fixes a handful of silly Tickrate bugs",
	version = "1.3",
	url = "https://github.com/A1mDev/L4D2-Competitive-Rework"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLateLoad = late;
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
	hCvarDoorSpeed = CreateConVar("tick_door_speed", "1.3", "Sets the speed of all prop_door entities on a map. 1.05 means = 105% speed");
	fDoorSpeed = hCvarDoorSpeed.FloatValue;

	hCvarDoorSpeed.AddChangeHook(cvarChanged);
	
	Door_ClearSettingsAll();
	Door_GetSettingsAll();
	Door_SetSettingsAll();
		
	//Gravity
	g_hCvarGravity = FindConVar("sv_gravity");
	if (g_hCvarGravity.IntValue != 750) {
		g_hCvarGravity.SetInt(750, true, false);
	}
	
	//Hook Pistols
	if (bLateLoad) {
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

public void OnEntityCreated(int entity, const char[] classname)
{
	if (classname[0] != 'p') {
		return;
	}
	
	for (int i = 0; i < sizeof(g_szDoors_Type_Tracked); i++) {
		if (strcmp(classname, g_szDoors_Type_Tracked[i], false) == 0) {
			SDKHook(entity, SDKHook_SpawnPost, DoorSpawnPost);
		}
	}
}

public void DoorSpawnPost(int entity)
{
	if (!IsValidEntity(entity)) {
		return;
	}
	
	char classname[ENTITY_MAX_NAME];
	GetEntityClassname(entity, classname, sizeof(classname));

	// Save Original Settings.
	for (int i = 0; i < sizeof(g_szDoors_Type_Tracked); i++) {
		if (strcmp(classname, g_szDoors_Type_Tracked[i], false) == 0) {
			Door_GetSettings(entity, view_as<DoorsTypeTracked>(i));
		}
	}

	// Set Settings.
	Door_SetSettings(entity);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThink, Hook_OnPreThink);

	g_fNextAttack[client] = 0.0;
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_PreThink, Hook_OnPreThink);
}

public void Cvar_PistolDelay(ConVar convar, const char[] oldValue, const char[] newValue)
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

public void Hook_OnPreThink(int client)
{
	// Human survivors only
	if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != TEAM_SURVIVORS) {
		return;
	}

	int activeweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEdict(activeweapon)) {
		return;
	}
	
	char wName[ENTITY_MAX_NAME];
	GetEdictClassname(activeweapon, wName, sizeof(wName));
	if (strcmp(wName, "weapon_pistol") != 0) {
		return;
	}
	
	float old_value = GetEntPropFloat(activeweapon, Prop_Send, "m_flNextPrimaryAttack");
	float new_value = g_fNextAttack[client];

	// Never accidentally speed up fire rate
	if (new_value > old_value) {
		// PrintToChatAll("Readjusting delay: Old=%f, New=%f", old_value, new_value);
		SetEntPropFloat(activeweapon, Prop_Send, "m_flNextPrimaryAttack", new_value);
	}
}

public void Event_WeaponFire(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (client < 1 || IsFakeClient(client) || GetClientTeam(client) != TEAM_SURVIVORS) {
		return;
	}
	
	int activeweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEdict(activeweapon)) {
		return;
	}
	
	char wName[ENTITY_MAX_NAME];
	GetEdictClassname(activeweapon, wName, sizeof(wName));
	if (strcmp(wName, "weapon_pistol") != 0) {
		return;
	}
	
	// int dualies = GetEntProp(activeweapon, Prop_Send, "m_hasDualWeapons");

	if (GetEntProp(client, Prop_Send, "m_isIncapacitated")) {
		g_fNextAttack[client] = GetGameTime() + g_fPistolDelayIncapped;
	} else if (GetEntProp(activeweapon, Prop_Send, "m_isDualWielding")) { // What is the difference between m_isDualWielding and m_hasDualWeapons ?
		g_fNextAttack[client] = GetGameTime() + g_fPistolDelayDualies;
	} else {
		g_fNextAttack[client] = GetGameTime() + g_fPistolDelaySingle;
	}
}

public void cvarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fDoorSpeed = hCvarDoorSpeed.FloatValue;

	Door_SetSettingsAll();
}

void Door_SetSettingsAll()
{
	int entity = -1, countEnts = 0;

	for (int i = 0; i < sizeof(g_szDoors_Type_Tracked); i++) {
		while ((entity = FindEntityByClassname(entity, g_szDoors_Type_Tracked[i])) != INVALID_ENT_REFERENCE) {
			Door_SetSettings(entity);
			Entity_SetForceClose(entity, false);
			countEnts++;
		}
		
		entity = -1;
	}
}

void Door_SetSettings(int entity)
{
#if SOURCEMOD_V_MINOR > 9
	Entity_SetSpeed(entity, g_ddDoors[entity].DoorsData_Speed * fDoorSpeed);
#else
	Entity_SetSpeed(entity, g_ddDoors[entity][DoorsData_Speed] * fDoorSpeed);
#endif
}

void Door_ResetSettingsAll()
{
	int entity = -1, countEnts = 0;

	for (int i = 0; i < sizeof(g_szDoors_Type_Tracked); i++) {
		while ((entity = FindEntityByClassname(entity, g_szDoors_Type_Tracked[i])) != INVALID_ENT_REFERENCE) {
			Door_ResetSettings(entity);
			countEnts++;
		}
		
		entity = -1;
	}
}

void Door_ResetSettings(int entity)
{
#if SOURCEMOD_V_MINOR > 9
	Entity_SetSpeed(entity, g_ddDoors[entity].DoorsData_Speed);
#else
	Entity_SetSpeed(entity, g_ddDoors[entity][DoorsData_Speed]);
#endif
}

void Door_GetSettingsAll()
{
	int entity = -1, countEnts = 0;
	
	for (int i = 0;i < sizeof(g_szDoors_Type_Tracked); i++) {
		while ((entity = FindEntityByClassname(entity, g_szDoors_Type_Tracked[i])) != INVALID_ENT_REFERENCE) {
			Door_GetSettings(entity, view_as<DoorsTypeTracked>(i));
			countEnts++;
		}
		
		entity = -1;
	}
}

void Door_GetSettings(int entity, DoorsTypeTracked type)
{
#if SOURCEMOD_V_MINOR > 9
	g_ddDoors[entity].DoorsData_Type = type;
	g_ddDoors[entity].DoorsData_Speed = Entity_GetSpeed(entity);
	g_ddDoors[entity].DoorsData_ForceClose = Entity_GetForceClose(entity);
#else
	g_ddDoors[entity][DoorsData_Type] = type;
	g_ddDoors[entity][DoorsData_Speed] = Entity_GetSpeed(entity);
	g_ddDoors[entity][DoorsData_ForceClose] = Entity_GetForceClose(entity);
#endif
}

void Door_ClearSettingsAll()
{
	for (int i = 0;i < MAX_EDICTS; i++) {
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

void Entity_SetSpeed(int entity, float speed)
{
	SetEntPropFloat(entity, Prop_Data, "m_flSpeed", speed);
}

float Entity_GetSpeed(int entity)
{
	return GetEntPropFloat(entity, Prop_Data, "m_flSpeed");
}

void Entity_SetForceClose(int entity, bool forceClose)
{
	SetEntProp(entity, Prop_Data, "m_bForceClosed", forceClose);
}

bool Entity_GetForceClose(int entity)
{
	return view_as<bool>(GetEntProp(entity, Prop_Data, "m_bForceClosed"));
}
