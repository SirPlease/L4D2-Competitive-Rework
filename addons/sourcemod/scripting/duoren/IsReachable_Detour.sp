#define PLUGIN_VERSION		"1.0"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define DEBUG 1
#define GAMEDATA		"IsReachable_Detour"

public Plugin myinfo =
{
	name = "[L4D2][NIX] IsReachable_Detour",
	author = "Dragokas",
	description = "Fixing the valve crash with null pointer dereference in SurvivorBot::IsReachable(CBaseEntity *)",
	version = PLUGIN_VERSION,
	url = "https://github.com/ValveSoftware/Source-1-Games/issues/3432"
}

Handle hDetour;

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
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	SetupDetour(hGameData);
	
	delete hGameData;
}

public void OnPluginEnd()
{
	if( !DHookDisableDetour(hDetour, false, IsReachable) )
		SetFailState("Failed to disable detour \"SurvivorBot::IsReachable\".");
}

void SetupDetour(Handle hGameData)
{
	hDetour = DHookCreateFromConf(hGameData, "SurvivorBot::IsReachable");
	if( !hDetour )
		SetFailState("Failed to find \"SurvivorBot::IsReachable\" signature.");
	if( !DHookEnableDetour(hDetour, false, IsReachable) )
		SetFailState("Failed to start detour \"SurvivorBot::IsReachable\".");
}

public MRESReturn IsReachable(Handle hReturn, Handle hParams)
{
	/*
	  v9 = *((_DWORD *)this + 13);
	  v10 = 0;
	  if ( v9 != -1 )
	  {
		v11 = (char *)g_pEntityList + 16 * (*((_DWORD *)this + 13) & 0xFFF);
		if ( *((_DWORD *)v11 + 2) == v9 >> 12 )
		  v10 = (CBaseEntity *)*((_DWORD *)v11 + 1);
	  }
	  v6 = 0;
	  if ( !(unsigned __int8)SurvivorBot::IsReachable(a3, v10) )
	  
	  // Missing if( v10 != NULL ) check; we just intercept it in "IsReachable" func, and check it in pre-hook
	  
	*/
	
	int ptr = DHookGetParam(hParams, 1);
	
	if( ptr == 0 )
	{
		#if DEBUG
			PrintToServer("########### SurvivorBot::IsReachable. Crash is successfully prevented!", ptr);
		#endif
	
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	
	//#if DEBUG
	//	PrintToServer("########### SurvivorBot::IsReachable. CBaseEntity ptr = %i", ptr);
	//#endif
	
	return MRES_Ignored;
}
