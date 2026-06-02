/*====================================================
1.0
	- Initial release
======================================================*/
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <dhooks>

bool bTransition, bIsVersus
Handle hServerShutdown
Address pCDirector

public Plugin myinfo = 
{
	name = "Transition Info Fix",
	author = "IA/NanaNana",
	description = "Fix the transition info bug",
	version = "1.0",
	url = "http://steamcommunity.com/profiles/76561198291983872"
}

public void OnPluginStart()
{
	Handle h = LoadGameConfigFile("l4d2_transition_info_fix"), z

	if((z = DHookCreateFromConf(h, "ChangeLevelNow"))) DHookEnableDetour(z, true, DH_ChangeLevelNow)
	else SetFailState("Detour ChangeLevelNow invalid.");

	if(!(pCDirector = GameConfGetAddress(h, "CDirector"))) SetFailState("Address CDirector invalid.")

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(h, SDKConf_Signature, "ServerShutdown")
	if(!(hServerShutdown = EndPrepSDKCall())) SetFailState("Signature ServerShutdown invalid.")

	HookEntityOutput("info_gamemode", "OnCoop", OnGameMode)
	HookEntityOutput("info_gamemode", "OnVersus", OnGameMode)
	HookEntityOutput("info_gamemode", "OnSurvival", OnGameMode)
	HookEntityOutput("info_gamemode", "OnScavenge", OnGameMode)

	CloseHandle(h)
}

public void OnGameMode(const char[] output, int caller, int activator, float delay)
{
	bIsVersus = strcmp(output[2], "Versus") == 0
}

public MRESReturn DH_ChangeLevelNow(int i, Handle hReturn, Handle hParams)
{
	bTransition = true
}

public void OnMapEnd()
{
	if(!bTransition && !bIsVersus)
	{
		SDKCall(hServerShutdown, pCDirector)
	}
	bTransition = false
}