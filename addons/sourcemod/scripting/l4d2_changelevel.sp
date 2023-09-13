// Not used now

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

#define PLUGIN_VERSION "1.2.1"

static Handle hDirectorChangeLevel;
static Handle hDirectorClearTeamScores;

//Credit ProdigySim for l4d2_direct reading of TheDirector class https://forums.alliedmods.net/showthread.php?t=180028
static Address TheDirector = Address_Null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	
	RegPluginLibrary("l4d2_changelevel");
	CreateNative("L4D2_ChangeLevel", L4D2_ChangeLevelNV);
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "l4d2_changelevel",
	author = "Lux",
	description = "Creates a clean way to change maps, sm_map causes leaks and other spooky stuff causing server perf to be worse over time.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2669850"
};

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile("l4d2_changelevel");
	if(hGamedata == null) 
		SetFailState("Failed to load \"l4d2_changelevel.txt\" gamedata.");
	
	StartPrepSDKCall(SDKCall_Raw);
	if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CDirector::OnChangeChapterVote"))
		SetFailState("Error finding the 'CDirector::OnChangeChapterVote' signature.");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	
	hDirectorChangeLevel = EndPrepSDKCall();
	if(hDirectorChangeLevel == null)
		SetFailState("Unable to prep SDKCall 'CDirector::OnChangeChapterVote'");
	
	TheDirector = GameConfGetAddress(hGamedata, "CDirector");
	if(TheDirector == Address_Null)
		SetFailState("Unable to get 'CDirector' Address");
	
	
	StartPrepSDKCall(SDKCall_Raw);
	if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CDirector::ClearTeamScores"))
		SetFailState("Error finding the 'CDirector::ClearTeamScores' signature.");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	
	hDirectorClearTeamScores = EndPrepSDKCall();
	if(hDirectorClearTeamScores == null)
		SetFailState("Unable to prep SDKCall 'CDirector::ClearTeamScores'");
	
	delete hGamedata;
	
	RegAdminCmd("sm_changelevel", Changelevel, ADMFLAG_ROOT, "L4D2 changelevel method to release all resources");
}

public Action Changelevel(int iClient, int iArg)
{
	char sMapName[PLATFORM_MAX_PATH];
	char temp[2];
	
	GetCmdArg(1, sMapName, sizeof(sMapName));
	if(sMapName[0] == '\0' || FindMap(sMapName, temp, sizeof(temp)) == FindMap_NotFound)
	{
		ReplyToCommand(iClient, "sm_changelevel Unable to find map \"%s\"", sMapName);
		return Plugin_Handled;
	}
	bool bResetScores = true;
	if(GetCmdArgs() >= 2)
	{
		GetCmdArg(2, temp, sizeof(temp));
		bResetScores = view_as<bool>(StringToInt(temp));
	}
	
	L4D2_ChangeLevel(sMapName, bResetScores);
	return Plugin_Handled;
}

void L4D2_ChangeLevel(const char[] sMapName, bool bShouldResetScores=true)
{
	PrintToServer("[SM] Changelevel to %s", sMapName);
	if(bShouldResetScores)
	{
		SDKCall(hDirectorClearTeamScores, TheDirector, 1);
	}
	SDKCall(hDirectorChangeLevel, TheDirector, sMapName);
}

public int L4D2_ChangeLevelNV(Handle plugin, int numParams)
{
	if(numParams < 1)
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	char sMapName[PLATFORM_MAX_PATH];
	GetNativeString(1, sMapName, sizeof(sMapName));
	
	char temp[1];
	if(sMapName[0] == '\0' || FindMap(sMapName, temp, sizeof(temp)) == FindMap_NotFound)
		ThrowNativeError(SP_ERROR_PARAM, "Unable to change to that map \"%s\"", sMapName);
	
	bool bResetScores = true;
	if(numParams >= 2)
		bResetScores = view_as<bool>(GetNativeCell(2));
	
	L4D2_ChangeLevel(sMapName, bResetScores);
	return 1;
}