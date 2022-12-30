/*
*	Console Spam Patches
*	Copyright (C) 2021 Silvers
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



#define PLUGIN_VERSION 		"1.3b"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Console Spam Patches
*	Author	:	SilverShot
*	Descrp	:	Prevents certain errors/warnings from being displayed in the server console.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=316612
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.3b (20-Jul-2021)
	- Fixed a few messages not being patched. GameData file updated.

1.3a (10-Jul-2021)
	- Added some more lines to block to the gamedata file.

1.3 (06-Jul-2021)
	- Added a "MAX_PATCHES" define to the source to fix L4D1 not reading all entries on failure to find one.
	- Added some more lines to remove to the gamedata file.

1.2 (10-May-2020)
	- Added better error log message when gamedata file is missing.
	- Various changes to tidy up code.

1.1 (29-Jun-2019)
	- Renamed gamedata vars "SpamPatch_Add" to "SpamPatch_Sig" for easier editing and duplication.
	- If updating from 1.0 either rename these strings or download the new gamedata.

1.0 (01-Jun-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define GAMEDATA			"l4d_console_spam"
#define MAX_PATCHES			50



public Plugin myinfo =
{
	name = "[L4D & L4D2] Console Spam Patches",
	author = "SilverShot",
	description = "Prevents certain errors/warnings from being displayed in the server console.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=316612"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_console_spam_version", PLUGIN_VERSION, "Console Spam Patches version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile("l4d_console_spam");
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	if( hGameData )
	{
		Address patchAddr;
		char sTemp[32];
		int loop = 1;
		int done = 0;

		while( loop <= MAX_PATCHES )
		{
			Format(sTemp, sizeof(sTemp), "SpamPatch_Sig%d", loop);
			patchAddr = GameConfGetAddress(hGameData, sTemp);

			if( patchAddr )
			{
				// PrintToServer("Patching console message: %d", loop);
				StoreToAddress(patchAddr, 0x00, NumberType_Int8);
				done++;
			}

			loop++;
		}

		PrintToServer("[Console Spam] patched %d entries.", done);
	}

	delete hGameData;
}