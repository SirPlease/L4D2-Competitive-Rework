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


//Requires https://github.com/nosoop/SMExt-SourceScramble

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define GAMEDATA "hunter_pounce_alignment_fix"
#define PLUGIN_VERSION	"2.0"

#define MAX_PATCH_SIZE 16 //highest amount of patch bytes needed
#define LINUX_PATCH_SIZE 16
#define WINDOWS_PATCH_SIZE 12

Address SetAbsOrigin_address;
int SetAbsOrigin_bytes[MAX_PATCH_SIZE];

Handle g_hSetAbsOrigin;
Handle g_hSetAbsVelocity;

enum OS_Type
{
	OS_windows = 0,
	OS_linux
}

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
	name = "[L4D2]hunter_pounce_alignment_fix",
	author = "Lux",
	description = "Restores l4d1 style hunter alignment.",
	version = PLUGIN_VERSION,
	url = "https://github.com/LuxLuma/Left-4-fix/tree/master/left%204%20fix/hunter/Hunter_pounce_alignment_fix"
};

public void OnPluginStart()
{
	CreateConVar("hunter_pounce_alignment_fix_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	StartPrepSDKCall(SDKCall_Entity);
	if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CBaseEntity::SetAbsOrigin"))
		SetFailState("Error finding the 'CBaseEntity::SetAbsOrigin' signature.");
	
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	g_hSetAbsOrigin = EndPrepSDKCall();
	if(g_hSetAbsOrigin == null)
		SetFailState("Unable to prep SDKCall 'CBaseEntity::SetAbsOrigin'");
	
	StartPrepSDKCall(SDKCall_Entity);
	if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CBaseEntity::SetAbsVelocity"))
		SetFailState("Error finding the 'CBaseEntity::SetAbsVelocity' signature.");
	
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	g_hSetAbsVelocity = EndPrepSDKCall();
	if(g_hSetAbsVelocity == null)
		SetFailState("Unable to prep SDKCall 'CBaseEntity::SetAbsVelocity'");
	
	//nop it :)
	UpdatePounce_Patch(hGamedata);
	delete hGamedata;
}

void UpdatePounce_Patch(Handle &hGamedata)
{
	OS_Type os = view_as<OS_Type>(GameConfGetOffset(hGamedata, "OS"));
	SetAbsOrigin_address = GameConfGetAddress(hGamedata, "CTerrorPlayer::UpdatePounce::SetAbsVelocity");
	if(SetAbsOrigin_address == Address_Null)
	{
		LogError("Failed to find address 'CTerrorPlayer::UpdatePounce::SetAbsVelocity'");
		return;
	}
	
	for(int i = 0; i < MAX_PATCH_SIZE; i++)
	{
		SetAbsOrigin_bytes[i] = LoadFromAddress(SetAbsOrigin_address + view_as<Address>(i), NumberType_Int8);
	}
	
	switch(os)
	{
		case OS_windows:
		{
			for(int i = 0; i < WINDOWS_PATCH_SIZE; i++)
			{
				StoreToAddress(SetAbsOrigin_address + view_as<Address>(i), 0x90, NumberType_Int8);
			}
		}
		case OS_linux:
		{
			for(int i = 0; i < LINUX_PATCH_SIZE; i++)
			{
				StoreToAddress(SetAbsOrigin_address + view_as<Address>(i), 0x90, NumberType_Int8);
			}
		}
	}
	PrintToServer("Patched 'CTerrorPlayer::UpdatePounce->CBaseEntity::SetAbsVelocity'");
}

public void OnPluginEnd()
{
	if(SetAbsOrigin_address != Address_Null)
	{
		for(int i = 0; i < MAX_PATCH_SIZE; i++)
		{
			StoreToAddress(SetAbsOrigin_address + view_as<Address>(i), SetAbsOrigin_bytes[i], NumberType_Int8);
		}
		PrintToServer("Restored 'CTerrorPlayer::UpdatePounce->CBaseEntity::SetAbsVelocity'");
	}
}


public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if(sClassname[0] == 'h' && StrEqual(sClassname, "hunter", false))
		SDKHook(iEntity, SDKHook_PostThink, PostThinkHunter);
}

public void OnClientPutInServer(int iClient)
{
	if(!IsFakeClient(iClient))
		SDKHook(iClient, SDKHook_PostThink, PostThinkHunter);
}

public void PostThinkHunter(int iHunter)
{
	if(!IsPlayerAlive(iHunter) || GetClientTeam(iHunter) != 3)
		return;
	
	int iPounceVictim = GetEntPropEnt(iHunter, Prop_Send, "m_pounceVictim");
	if(iPounceVictim < 1 || !IsPlayerAlive(iPounceVictim) || 
		GetEntPropEnt(iPounceVictim, Prop_Send, "m_pounceAttacker") != iHunter)// just incase
		return;
	
	//copy all the victims origin and velocity data so velocity interpolation can happen clientside
	//and lagcomp is as correct as it can be
	static float vecPos[3];
	static float vecVel[3];
	GetEntPropVector(iPounceVictim, Prop_Data, "m_vecAbsOrigin", vecPos);//worldspace origin
	GetEntPropVector(iPounceVictim, Prop_Data, "m_vecAbsVelocity", vecVel);
	
	//TeleportEntity seems to make the hunter's outline flash to avoid this don't use it :P
	SDKCall(g_hSetAbsOrigin, iHunter, vecPos);
	SDKCall(g_hSetAbsVelocity, iHunter, vecVel);
}