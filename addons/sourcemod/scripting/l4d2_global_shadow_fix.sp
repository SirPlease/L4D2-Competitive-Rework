/*
*	Global Shadow Fix
*	Copyright (C) 2022 Silvers
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



#define PLUGIN_VERSION		"1.3"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Global Shadow Fix
*	Author	:	SilverShot
*	Descp	:	Corrects the global shadow position on some official maps.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=149041
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.3 (11-Dec-2022)
	- Changes to fix compile warnings on SourceMod 1.11.

1.2 (10-May-2020)
	- Various changes to tidy up code.

1.1 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.0 (01-Feb-2011)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#define ALLOW_EDITING		false		// Enables the "sm_shadow*" commands to move the shadow position

#include <sourcemod>
#include <sdktools>



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Global Shadow Fix",
	author = "SilverShot",
	description = "Corrects the global shadow position on some official maps.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=149041"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	// Cvars
	CreateConVar("l4d2_global_shadow_fix_version", PLUGIN_VERSION, "Shadow Fix version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Reset to the new values and manually change the shadow direction
	#if ALLOW_EDITING
	RegAdminCmd("sm_shadows", CmdSh, ADMFLAG_ROOT);
	RegAdminCmd("sm_shadowx", CmdShX, ADMFLAG_ROOT);
	RegAdminCmd("sm_shadowy", CmdShY, ADMFLAG_ROOT);
	RegAdminCmd("sm_shadowz", CmdShZ, ADMFLAG_ROOT);
	#endif
}

// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public void OnConfigsExecuted()
{
	SetPos();
}

bool SetPos()
{
	float fCorrected[3];
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	// Dead Center:
	if( strcmp(sMap, "c1m1_hotel", false) == 0 )		//-0.612372 0.353553 -0.707106
		fCorrected = view_as<float>({ 0.587627, 0.353553, -0.207106 });

	else if( strcmp(sMap, "c1m2_streets") == 0 )		//0.150383 0.086824 -0.984807
		fCorrected = view_as<float>({ 0.750383, 0.486824, -0.484807 });

	else if( strcmp(sMap, "c1m3_mall") == 0 )			//01.187627 0.553553 -0.707106
		fCorrected = view_as<float>({ 2.587627, 0.953553, -0.207106 });

	else if( strcmp(sMap, "c1m4_atrium") == 0 )		//-0.612372 0.353553 -0.707106
		fCorrected = view_as<float>({ 2.587627, 0.353553, -0.207106 });

	// Hard Rain:
	else if( strcmp(sMap, "c4m1_milltown_a") == 0 )	//0.330366 -0.088521 -0.939692
		fCorrected = view_as<float>({ 1.130365, 0.711478, -0.439692 });

	else
		return false;	// No other maps

	int ent = -1;
	while( (ent = FindEntityByClassname(ent, "shadow_control")) != INVALID_ENT_REFERENCE )
	{
		SetEntPropVector(ent, Prop_Send, "m_shadowDirection", fCorrected);
	}

	return true;
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
#if ALLOW_EDITING
Action CmdSh(int client, int args)
{
	if( SetPos() == true )
		PrintToChat(client, "\x04[\x01Shadow Fix\x04]\x01 Corrected!");
	else
		PrintToChat(client, "\x04[\x01Shadow Fix\x04]\x01 Wrong Map!");
	return Plugin_Handled;
}

Action CmdShX(int client, int args)
{
	SetShadow(client, 1, args);
	return Plugin_Handled;
}

Action CmdShY(int client, int args)
{
	SetShadow(client, 2, args);
	return Plugin_Handled;
}

Action CmdShZ(int client, int args)
{
	SetShadow(client, 3, args);
	return Plugin_Handled;
}

void SetShadow(int client, int type, any ...)
{
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));

	int entity = -1;
	float fCorrected[3];
	float fDistance = StringToFloat(arg1);

	while( (entity = FindEntityByClassname(entity, "shadow_control")) != INVALID_ENT_REFERENCE )
	{
		GetEntPropVector(entity, Prop_Send, "m_shadowDirection", fCorrected);
		PrintToChat(client, "\x04[\x01Shadow Fix\x04]\x01 Was: %f %f %f", fCorrected[0], fCorrected[1], fCorrected[2]);
		switch(type)
		{
			case 1:	fCorrected[0] += fDistance;
			case 2:	fCorrected[1] += fDistance;
			case 3:	fCorrected[2] += fDistance;
		}
		SetEntPropVector(entity, Prop_Send, "m_shadowDirection", fCorrected);
		PrintToChat(client, "\x04[\x01Shadow Fix\x04]\x01 Now: %f %f %f", fCorrected[0], fCorrected[1], fCorrected[2]);
	}
}
#endif