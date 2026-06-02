/*
*	[L4D2] Ladder Server Crash - Patch Fix
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



#define PLUGIN_VERSION 		"1.1"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Ladder Server Crash - Patch Fix
*	Author	:	SilverShot
*	Descrp	:	Fixes a server crash from NavLadder::GetPosAtHeight. Patches out AvoidNeighbors.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=336298
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.1 (12-Feb-2022)
	- Detour method scrapped in favour of patching out calls to 'AvoidNeighbors' function.
	- Plugin and GameData file updated.

1.0 (10-Feb-2022)
	- Official release.

0.4 (21-Jan-2022)
	- Added debugging log when an error is detected. Saved to "logs/ladder_patch.log" printing map and position of ladder.

0.3 (21-Jan-2022)
	- Beta release checking the problem offset. Thanks to "Dragokas" for reporting.

0.2 (21-Jan-2022)
	- Beta release with MemoryEx support.

0.1 (21-Jan-2022)
	- Initial beta release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
// #include <dhooks>
// #include <MemoryEx>

#define GAMEDATA			"l4d2_ladder_patch"

// #define DEBUG				1 // 0=Off. 1=Log the map and ladder position and which error was detected. Saved to "logs/ladder_patch.log"

// #define LINUX				0
// #define WINDOWS				1

// int g_iOffset;
// int g_iOS;

public Plugin myinfo =
{
	name = "[L4D2] Ladder Server Crash - Patch Fix",
	author = "SilverShot and Peace-Maker",
	description = "Fixes a server crash from NavLadder::GetPosAtHeight. Patches out AvoidNeighbors.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=336298"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_ladder_patch_version", PLUGIN_VERSION, "Ladder Server Crash - Fix plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	GameData hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	int byte;
	int offset;
	Address patch;

	// Patch 1
	offset = GameConfGetOffset(hGameData, "Patch_ChaseVictim");
	patch = GameConfGetAddress(hGameData, "ChaseVictim::Update");
	if( !patch ) SetFailState("Error finding the \"ChaseVictim::Update\" signature.");

	byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
	if( byte == 0xE8 )
	{
		for( int i = 0; i < 5; i++ )
			StoreToAddress(patch + view_as<Address>(offset + i), 0x90, NumberType_Int8);
	}
	else if( byte != 0x90 )
	{
		SetFailState("Error: the \"Patch_ChaseVictim\" offset %d is incorrect.", offset);
	}

	// Patch 2
	offset = GameConfGetOffset(hGameData, "Patch_InfectedFlee");
	patch = GameConfGetAddress(hGameData, "InfectedFlee::Update");
	if( !patch ) SetFailState("Error finding the \"InfectedFlee::Update\" signature.");

	byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
	if( byte == 0xE8 )
	{
		for( int i = 0; i < 5; i++ )
			StoreToAddress(patch + view_as<Address>(offset + i), 0x90, NumberType_Int8);
	}
	else if( byte != 0x90 )
	{
		SetFailState("Error: the \"Patch_InfectedFlee\" offset %d is incorrect.", offset);
	}

	delete hGameData;



	// Detour version - obsolete
	/*
	g_iOffset = hGameData.GetOffset("Crash_Offset");
	if( g_iOffset == -1 ) SetFailState("Failed to find \"%s.txt\" offset.", GAMEDATA);

	// g_iOS = hGameData.GetOffset("OS");
	// if( g_iOS == -1 ) SetFailState("Failed to find \"%s.txt\" offset.", GAMEDATA);

	Handle hDetour = DHookCreateFromConf(hGameData, "NavLadder::GetPosAtHeight");
	delete hGameData;

	if( !hDetour )
		SetFailState("Failed to find \"NavLadder::GetPosAtHeight\" signature.");

	if( !DHookEnableDetour(hDetour, false, GetPosAtHeight) )
		SetFailState("Failed to detour \"NavLadder::GetPosAtHeight\".");

	delete hDetour;

	CheckInitPEB();
	// */
}



// ====================================================================================================
// Detour
// ====================================================================================================
// Detour version - obsolete
/*
public MRESReturn GetPosAtHeight(int pThis, Handle hReturn, Handle hParams)
{
	// if( pThis == 0 || IsValidPointer(pThis) == false || (g_iOS == WINDOWS ? IsValidPointer(pThis + g_iOffset) == false : IsValidPointer(LOWORD(pThis) + g_iOffset) == false) )

	int bug;

	if( pThis == 0 )
		bug = 1;
	else if( IsValidPointer(pThis) == false )
		bug = 2;
	else if( IsValidPointer(pThis + g_iOffset) == false )
		bug = 3;

	if( bug )
	{
		#if DEBUG
		static char sTemp[256];
		GetCurrentMap(sTemp, sizeof(sTemp));

		Format(sTemp, sizeof(sTemp), "%s %d", sTemp, bug);
		LogCustom(sTemp);

		float vPos[3];
		vPos[0] = view_as<float>(LoadFromAddress(view_as<Address>(pThis + 4), NumberType_Int32));
		vPos[1] = view_as<float>(LoadFromAddress(view_as<Address>(pThis + 8), NumberType_Int32));
		vPos[2] = view_as<float>(LoadFromAddress(view_as<Address>(pThis + 12), NumberType_Int32)); 

		Format(sTemp, sizeof(sTemp), "(%0.2f %0.2f %0.2f)", vPos[0], vPos[1], vPos[2]);
		LogCustom(sTemp);
		#endif

		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

stock int LOWORD(int num)
{
	return num & 0xFFFF;
}

#if DEBUG
void LogCustom(const char[] format, any ...)
{
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);

	File file;
	char sFile[PLATFORM_MAX_PATH], sTime[256];
	FormatTime(sTime, sizeof(sTime), "%Y%m%d");
	BuildPath(Path_SM, sFile, sizeof(sFile), "logs/ladder_patch.log");
	file = OpenFile(sFile, "a+");
	FormatTime(sTime, sizeof(sTime), "%d-%b-%Y %H:%M:%S");
	file.WriteLine("%s  %s", sTime, buffer);
	FlushFile(file);
	delete file;
}
#endif
// */