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

//Forces move failure type 2 to always happen.

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define GAMEDATA "witch_prevent_target_loss"
#define PLUGIN_VERSION	"1.1.1"


Address OnMoveToFailure_1 = Address_Null;
int MoveFailureBytesStore_1[2];

Address OnMoveToFailure_2 = Address_Null;
int MoveFailureBytesStore_2[2];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion CurrentEngine = GetEngineVersion();
	if(CurrentEngine != Engine_Left4Dead2 && CurrentEngine != Engine_Left4Dead)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1/2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D1/2]witch_prevent_target_loss",
	author = "Lux",
	description = "Prevents the witch from randomly loosing target.",
	version = PLUGIN_VERSION,
	url = "forums.alliedmods.net/showthread.php?p=2647014"
};

public void OnPluginStart()
{
	CreateConVar("witch_prevent_target_loss", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
		
	Address patch;
	int offset;
	int byte;
	
	patch = GameConfGetAddress(hGamedata, "WitchAttack::OnMoveToFailure");
	if(patch) 
	{
		offset = GameConfGetOffset(hGamedata, "WitchAttack::OnMoveToFailure_1");
		if(offset != -1) 
		{
			byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
			if(byte == 0x74 || byte == 0x75)
			{
				OnMoveToFailure_1 = patch + view_as<Address>(offset);
				MoveFailureBytesStore_1[0] = LoadFromAddress(OnMoveToFailure_1, NumberType_Int8);
				MoveFailureBytesStore_1[1] = LoadFromAddress(OnMoveToFailure_1 + view_as<Address>(1), NumberType_Int8);
				
				if(byte == 0x74)
				{
					StoreToAddress(OnMoveToFailure_1, 0x90, NumberType_Int8);
					StoreToAddress(OnMoveToFailure_1 + view_as<Address>(1), 0x90, NumberType_Int8);
				}
				else
				{
					StoreToAddress(OnMoveToFailure_1, 0xEB, NumberType_Int8);
				}
				PrintToServer("WitchPatch Preventloss patch applied 'WitchAttack::OnMoveToFailure_1'");
			}
			else
			{
				LogError("Incorrect offset for 'WitchAttack::OnMoveToFailure_1'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'WitchAttack::OnMoveToFailure_1'.");
		}
		
		offset = GameConfGetOffset(hGamedata, "WitchAttack::OnMoveToFailure_2");
		if(offset != -1) 
		{
			byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
			if(byte == 0x74 || byte == 0x75)
			{
				OnMoveToFailure_2 = patch + view_as<Address>(offset);
				MoveFailureBytesStore_2[0] = LoadFromAddress(OnMoveToFailure_2, NumberType_Int8);
				MoveFailureBytesStore_2[1] = LoadFromAddress(OnMoveToFailure_2 + view_as<Address>(1), NumberType_Int8);
				
				StoreToAddress(OnMoveToFailure_2, 0x90, NumberType_Int8);
				StoreToAddress(OnMoveToFailure_2 + view_as<Address>(1), 0x90, NumberType_Int8);
				PrintToServer("WitchPatch Preventloss patch applied 'WitchAttack::OnMoveToFailure_2'");
			}
			else
			{
				LogError("Incorrect offset for 'WitchAttack::OnMoveToFailure_2'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'WitchAttack::OnMoveToFailure_2'.");
		}
	
	}
	else
	{
		LogError("Error finding the 'WitchAttack::OnMoveToFailure' signature.");
	}
	
	delete hGamedata;
}

public void OnPluginEnd()
{
	if(OnMoveToFailure_1 != Address_Null)
	{
		StoreToAddress(OnMoveToFailure_1, MoveFailureBytesStore_1[0], NumberType_Int8);
		StoreToAddress(OnMoveToFailure_1 + view_as<Address>(1), MoveFailureBytesStore_1[1], NumberType_Int8);
		PrintToServer("WitchPatch restored 'WitchAttack::OnMoveToFailure_1'");
	}
	if(OnMoveToFailure_2 != Address_Null)
	{
		StoreToAddress(OnMoveToFailure_2, MoveFailureBytesStore_2[0], NumberType_Int8);
		StoreToAddress(OnMoveToFailure_2 + view_as<Address>(1), MoveFailureBytesStore_2[1], NumberType_Int8);
		PrintToServer("WitchPatch restored 'WitchAttack::OnMoveToFailure_2'");
	}
}
