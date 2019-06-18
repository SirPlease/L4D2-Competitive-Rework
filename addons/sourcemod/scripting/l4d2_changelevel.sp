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

#define PLUGIN_VERSION "1.1.2"

//static Handle hInfoMapChange;
static Handle hDirectorChangeLevel;

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
	url = "https://forums.alliedmods.net/showthread.php?p=2607394"
};

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile("l4d2_changelevel");
	if(hGamedata == null) 
		SetFailState("Failed to load \"l4d2_changelevel.txt\" gamedata.");
	
	/*StartPrepSDKCall(SDKCall_Entity);
	if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "InfoChangelevel::ChangeLevelNow"))
		SetFailState("Error finding the 'InfoChangelevel::ChangeLevelNow' signature.");
	
	hInfoMapChange = EndPrepSDKCall();
	if(hInfoMapChange == null)
		SetFailState("Unable to prep SDKCall 'InfoChangelevel::ChangeLevelNow'");*/
		
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
	
	delete hGamedata;
	
	RegServerCmd("sm_changelevelex", ChangelevelEx, "L4D2 changelevel method to release all resources");
	RegAdminCmd("sm_changelevel", Changelevel, ADMFLAG_ROOT, "L4D2 changelevel method to release all resources");
}

public Action CmdMapChange(int iClient, const char[] sCommand, int iArg)
{
	if(GetCmdArgs() < 1)
		return Plugin_Continue;
		
	char sMapName[256];
	GetCmdArg(1, sMapName, sizeof(sMapName));
	if(sMapName[0] == '\0')
		return Plugin_Continue;
	
	char temp[1];
	if(FindMap(sMapName, temp, sizeof(temp)) == FindMap_NotFound)
		return Plugin_Continue;
	
	L4D2_ChangeLevel(sMapName);
	return Plugin_Handled;
}

public Action ChangelevelEx(int iArg)
{
	char sMapName[PLATFORM_MAX_PATH];
	char temp[1];
	
	GetCmdArg(1, sMapName, sizeof(sMapName));
	if(sMapName[0] == '\0' || FindMap(sMapName, temp, sizeof(temp)) == FindMap_NotFound)
	{
		PrintToServer("sm_changelevelex Unable to find map \"%s\"", sMapName);
		return Plugin_Handled;
	}
	
	L4D2_ChangeLevel(sMapName);
	return Plugin_Handled;
}
public Action Changelevel(int iClient, int iArg)
{
	char sMapName[PLATFORM_MAX_PATH];
	char temp[1];
	
	GetCmdArg(1, sMapName, sizeof(sMapName));
	if(sMapName[0] == '\0' || FindMap(sMapName, temp, sizeof(temp)) == FindMap_NotFound)
	{
		ReplyToCommand(iClient, "sm_changelevel Unable to find map \"%s\"", sMapName);
		return Plugin_Handled;
	}
	
	L4D2_ChangeLevel(sMapName);
	return Plugin_Handled;
}

/*stock bool L4D2_ChangeLevel(const char[] sMapName)
{
	int iInfoChangelevel = CreateEntityByName("info_changelevel");
	if(iInfoChangelevel < 1 || !IsValidEntity(iInfoChangelevel))
		return false;
	
	DispatchKeyValue(iInfoChangelevel, "map", sMapName);
	if(!DispatchSpawn(iInfoChangelevel))
	{
		AcceptEntityInput(iInfoChangelevel, "Kill");
		return false;
	}
	
	PrintToServer("SDKCall changelevel to %s", sMapName);
	SDKCall(hInfoMapChange, iInfoChangelevel);	//don't allow invalid maps get here or it will break level changing.
	AcceptEntityInput(iInfoChangelevel, "Kill");
	return true;
}*/

void L4D2_ChangeLevel(const char[] sMapName)
{
	PrintToServer("[SM] Changelevel to %s", sMapName);
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
	
	L4D2_ChangeLevel(sMapName);
}