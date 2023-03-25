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

#define GAMEDATA "witch_target_patch"
#define PLUGIN_VERSION	"1.4"

#define OS_WINDOWS 1
#define OS_LINUX 2

Address GetVictim = Address_Null;
Address OnStart = Address_Null;
Address OnAnimationEvent = Address_Null;
Address Update = Address_Null;
Address OnContact = Address_Null;

int GetVictimBytesStore[2];
int OnStartBytesStore[6];
int OnAnimationEventBytesStore[2];
int UpdateBytesStore[6];
int OnContactBytesStore[6];

int CurrentOS;


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
	name = "[L4D1/2]Witch_Target_Patch",
	author = "Lux",
	description = "Fixes witch targeting wrong person",
	version = PLUGIN_VERSION,
	url = "forums.alliedmods.net/showthread.php?p=2647014"
};

public void OnPluginStart()
{
	CreateConVar("witch_target_patch_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
		
	CurrentOS = GameConfGetOffset(hGamedata, "WindowsOrLinux");
	
	if(GetEngineVersion() == Engine_Left4Dead)
	{
		L4D1_Specific(hGamedata);
	}
	else
	{
		L4D2_Specific(hGamedata);
	}
	
	delete hGamedata;
}

void L4D2_Specific(Handle &hGamedata)
{
	Address patch;
	int offset;
	int byte;
	
	patch = GameConfGetAddress(hGamedata, "WitchAttack::GetVictim");
	if(patch) 
	{
		offset = GameConfGetOffset(hGamedata, "WitchAttack::GetVictim");
		if(offset != -1) 
		{
			byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
			if(byte == 0x74)
			{
				GetVictim = patch + view_as<Address>(offset);
				
				GetVictimBytesStore[0] = LoadFromAddress(GetVictim, NumberType_Int8);
				GetVictimBytesStore[1] = LoadFromAddress(GetVictim + view_as<Address>(1), NumberType_Int8);
				
				StoreToAddress(GetVictim, 0xEB, NumberType_Int8);
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::GetVictim'");
				return;
			}
			else if(byte == 0x75)
			{
				GetVictim = patch + view_as<Address>(offset);
				
				GetVictimBytesStore[0] = LoadFromAddress(GetVictim, NumberType_Int8);
				GetVictimBytesStore[1] = LoadFromAddress(GetVictim + view_as<Address>(1), NumberType_Int8);
				
				StoreToAddress(GetVictim, 0x90, NumberType_Int8);
				StoreToAddress(GetVictim + view_as<Address>(1), 0x90, NumberType_Int8);
				
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::GetVictim'");
			}
			else
			{
				LogError("Incorrect offset for 'WitchAttack::GetVictim'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'WitchAttack::GetVictim'.");
		}
	}
	else
	{
		LogError("Error finding the 'WitchAttack::GetVictim' signature.");
	}
	
	
	patch = GameConfGetAddress(hGamedata, "WitchAttack::OnStart");
	if(patch) 
	{
		offset = GameConfGetOffset(hGamedata, "WitchAttack::OnStart");
		if(offset != -1) 
		{
			byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
			if(byte == 0x75)
			{
				OnStart = patch + view_as<Address>(offset);
				
				for(int i = 0; i <= 5; i++)
				{
					OnStartBytesStore[i] = LoadFromAddress(OnStart + view_as<Address>(i), NumberType_Int8);
				}
				
				StoreToAddress(OnStart, 0x90, NumberType_Int8);
				StoreToAddress(OnStart + view_as<Address>(1), 0x90, NumberType_Int8);
				
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::OnStart'");
			}
			else
			{
				LogError("Incorrect offset for 'WitchAttack::OnStart'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'WitchAttack::OnStart'.");
		}
	}
	else
	{
		LogError("Error finding the 'WitchAttack::OnStart' signature.");
	}
	
	patch = GameConfGetAddress(hGamedata, "WitchAttack::OnAnimationEvent");
	if(patch)
	{
		offset = GameConfGetOffset(hGamedata, "WitchAttack::OnAnimationEvent");
		if(offset != -1) 
		{
			byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
			if(byte == 0x75)
			{
				OnAnimationEvent = patch + view_as<Address>(offset);
				
				OnAnimationEventBytesStore[0] = LoadFromAddress(OnAnimationEvent, NumberType_Int8);
				OnAnimationEventBytesStore[1] = LoadFromAddress(OnAnimationEvent + view_as<Address>(1), NumberType_Int8);
				
				StoreToAddress(OnAnimationEvent, 0x90, NumberType_Int8);
				StoreToAddress(OnAnimationEvent + view_as<Address>(1), 0x90, NumberType_Int8);
				
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::OnAnimationEvent'");
			}
			else
			{
				LogError("Incorrect offset for 'WitchAttack::OnAnimationEvent'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'WitchAttack::OnAnimationEvent'.");
		}
	}
	else
	{
		LogError("Error finding the 'WitchAttack::OnAnimationEvent' signature.");
	}
	
	patch = GameConfGetAddress(hGamedata, "WitchAttack::Update");
	if(patch) 
	{
		offset = GameConfGetOffset(hGamedata, "WitchAttack::Update");
		if(offset != -1) 
		{
			byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
			if(byte == 0x75)
			{
				Update = patch + view_as<Address>(offset);
				
				for(int i = 0; i <= 5; i++)
				{
					UpdateBytesStore[i] = LoadFromAddress(Update + view_as<Address>(i), NumberType_Int8);
				}
				
				StoreToAddress(Update, 0x90, NumberType_Int8);
				StoreToAddress(Update + view_as<Address>(1), 0x90, NumberType_Int8);
				
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::Update'");
			}
			else
			{
				LogError("Incorrect offset for 'WitchAttack::Update'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'WitchAttack::Update'.");
		}
	}
	else
	{
		LogError("Error finding the 'WitchAttack::Update' signature.");
	}
}

void L4D1_Specific(Handle &hGamedata)
{
	Address patch;
	int offset;
	int byte;
	
	patch = GameConfGetAddress(hGamedata, "WitchAttack::GetVictim");// looks to be unused on linux patched it anyway
	if(patch) 
	{
		offset = GameConfGetOffset(hGamedata, "WitchAttack::GetVictim");
		if(offset != -1) 
		{
			byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
			if(byte == 0x74)
			{
				GetVictim = patch + view_as<Address>(offset);
				
				GetVictimBytesStore[0] = LoadFromAddress(GetVictim, NumberType_Int8);
				GetVictimBytesStore[1] = LoadFromAddress(GetVictim + view_as<Address>(1), NumberType_Int8);
				
				StoreToAddress(GetVictim, 0xEB, NumberType_Int8);
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::GetVictim'");
			}
			else if(byte == 0x75)
			{
				GetVictim = patch + view_as<Address>(offset);
				
				GetVictimBytesStore[0] = LoadFromAddress(GetVictim, NumberType_Int8);
				GetVictimBytesStore[1] = LoadFromAddress(GetVictim + view_as<Address>(1), NumberType_Int8);
				
				StoreToAddress(GetVictim, 0x90, NumberType_Int8);
				StoreToAddress(GetVictim + view_as<Address>(1), 0x90, NumberType_Int8);
				
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::GetVictim'");
			}
			else
			{
				LogError("Incorrect offset for 'WitchAttack::GetVictim'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'WitchAttack::GetVictim'.");
		}
	}
	else
	{
		LogError("Error finding the 'WitchAttack::GetVictim' signature.");
	}
	
	patch = GameConfGetAddress(hGamedata, "WitchAttack::OnStart");
	if(patch) 
	{
		offset = GameConfGetOffset(hGamedata, "WitchAttack::OnStart");
		if(offset != -1) 
		{
			byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
			if(byte == 0x75)
			{
				OnStart = patch + view_as<Address>(offset);
				
				for(int i = 0; i <= 5; i++)
				{
					OnStartBytesStore[i] = LoadFromAddress(OnStart + view_as<Address>(i), NumberType_Int8);
				}
				
				StoreToAddress(OnStart, 0x90, NumberType_Int8);
				StoreToAddress(OnStart + view_as<Address>(1), 0x90, NumberType_Int8);
				
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::OnStart'");
			}
			else if(byte == 0x04)
			{
				OnStart = patch + view_as<Address>(offset);
				
				for(int i = 0; i <= 5; i++)
				{
					OnStartBytesStore[i] = LoadFromAddress(OnStart + view_as<Address>(i), NumberType_Int8);
				}
				
				StoreToAddress(OnStart, 0x08, NumberType_Int8);
				StoreToAddress(OnStart + view_as<Address>(2), 0x85, NumberType_Int8);
			}
			else
			{
				LogError("Incorrect offset for 'WitchAttack::OnStart'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'WitchAttack::OnStart'.");
		}
	}
	else
	{
		LogError("Error finding the 'WitchAttack::OnStart' signature.");
	}
	
	patch = GameConfGetAddress(hGamedata, "WitchAttack::OnAnimationEvent");
	if(patch)
	{
		offset = GameConfGetOffset(hGamedata, "WitchAttack::OnAnimationEvent");
		if(offset != -1) 
		{
			byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
			if(byte == 0x75)
			{
				OnAnimationEvent = patch + view_as<Address>(offset);
				
				OnAnimationEventBytesStore[0] = LoadFromAddress(OnAnimationEvent, NumberType_Int8);
				OnAnimationEventBytesStore[1] = LoadFromAddress(OnAnimationEvent + view_as<Address>(1), NumberType_Int8);
				
				StoreToAddress(OnAnimationEvent, 0x90, NumberType_Int8);
				StoreToAddress(OnAnimationEvent + view_as<Address>(1), 0x90, NumberType_Int8);
				
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::OnAnimationEvent'");
			}
			else if(byte == 0x74)
			{
				OnAnimationEvent = patch + view_as<Address>(offset);
				
				OnAnimationEventBytesStore[0] = LoadFromAddress(OnAnimationEvent, NumberType_Int8);
				OnAnimationEventBytesStore[1] = LoadFromAddress(OnAnimationEvent + view_as<Address>(1), NumberType_Int8);
				
				StoreToAddress(OnAnimationEvent, 0x76, NumberType_Int8);//functions flipped around jump if below and equal which will be always true
				//StoreToAddress(OnAnimationEvent + view_as<Address>(1), 0x90, NumberType_Int8);
				
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::OnAnimationEvent'");
			}
			else
			{
				LogError("Incorrect offset for 'WitchAttack::OnAnimationEvent'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'WitchAttack::OnAnimationEvent'.");
		}
	}
	else
	{
		LogError("Error finding the 'WitchAttack::OnAnimationEvent' signature.");
	}
	
	patch = GameConfGetAddress(hGamedata, "WitchAttack::Update");
	if(patch) 
	{
		offset = GameConfGetOffset(hGamedata, "WitchAttack::Update");
		if(offset != -1) 
		{
			byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
			if(byte == 0x75)
			{
				Update = patch + view_as<Address>(offset);
				
				for(int i = 0; i <= 5; i++)
				{
					UpdateBytesStore[i] = LoadFromAddress(Update + view_as<Address>(i), NumberType_Int8);
				}
				
				StoreToAddress(Update, 0x90, NumberType_Int8);
				StoreToAddress(Update + view_as<Address>(1), 0x90, NumberType_Int8);
				
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::Update'");
			}
			else if(byte == 0x04)
			{
				Update = patch + view_as<Address>(offset);
				
				for(int i = 0; i <= 5; i++)
				{
					UpdateBytesStore[i] = LoadFromAddress(Update + view_as<Address>(i), NumberType_Int8);
				}
				
				StoreToAddress(Update, 0x08, NumberType_Int8);
				StoreToAddress(Update + view_as<Address>(2), 0x85, NumberType_Int8);
			}
			else
			{
				LogError("Incorrect offset for 'WitchAttack::Update'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'WitchAttack::Update'.");
		}
	}
	else
	{
		LogError("Error finding the 'WitchAttack::Update' signature.");
	}
	
	
	if(CurrentOS != OS_LINUX)
		return;
	
	patch = GameConfGetAddress(hGamedata, "WitchAttack::OnContact");
	if(patch) 
	{
		offset = GameConfGetOffset(hGamedata, "WitchAttack::OnContact");
		if(offset != -1) 
		{
			byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
			if(byte == 0x0F)
			{
				OnContact = patch + view_as<Address>(offset);
				
				for(int i = 0; i <= 5; i++)
				{
					OnContactBytesStore[i] = LoadFromAddress(OnContact + view_as<Address>(i), NumberType_Int8);
					StoreToAddress(OnContact + view_as<Address>(i), 0x90, NumberType_Int8);
				}
				
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::OnContact'");
			}
			else
			{
				LogError("Incorrect offset for 'WitchAttack::OnContact'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'WitchAttack::OnContact'.");
		}
	}
	else
	{
		LogError("Error finding the 'WitchAttack::OnContact' signature.");
	}
}

public void OnPluginEnd()
{
	if(GetVictim != Address_Null)
	{
		StoreToAddress(GetVictim, GetVictimBytesStore[0], NumberType_Int8);
		StoreToAddress(GetVictim + view_as<Address>(1), GetVictimBytesStore[1], NumberType_Int8);
		PrintToServer("WitchPatch restored 'WitchAttack::GetVictim'");
	}
	
	if(OnStart != Address_Null)
	{
		for(int i = 0; i <= 5; i++)
		{
			StoreToAddress(OnStart + view_as<Address>(i), OnStartBytesStore[i], NumberType_Int8);
		}
		PrintToServer("WitchPatch restored 'WitchAttack::OnStart'");
	}
	
	if(OnAnimationEvent != Address_Null)
	{
		StoreToAddress(OnAnimationEvent, OnAnimationEventBytesStore[0], NumberType_Int8);
		StoreToAddress(OnAnimationEvent + view_as<Address>(1), OnAnimationEventBytesStore[1], NumberType_Int8);
		PrintToServer("WitchPatch restored 'WitchAttack::OnAnimationEvent'");
	}
	
	if(Update != Address_Null)
	{
		for(int i = 0; i <= 5; i++)
		{
			StoreToAddress(Update + view_as<Address>(i), UpdateBytesStore[i], NumberType_Int8);
		}
		PrintToServer("WitchPatch restored 'WitchAttack::Update'");
	}
	
	if(OnContact != Address_Null)
	{
		for(int i = 0; i <= 5; i++)
		{
			StoreToAddress(OnContact + view_as<Address>(i), OnContactBytesStore[i], NumberType_Int8);
		}
		PrintToServer("WitchPatch restored 'WitchAttack::Update'");
	}
}