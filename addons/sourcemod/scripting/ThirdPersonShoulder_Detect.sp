#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.5.3"

public Plugin myinfo =
{
	name = "ThirdPersonShoulder_Detect",
	author = "MasterMind420 & Lux",
	description = "Detects thirdpersonshoulder command for other plugins to use",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2529779"
};

static bool bVersus = false;
static bool bThirdPerson[MAXPLAYERS+1] = false;
static bool bThirdPersonFix[MAXPLAYERS+1] = false;

static Handle hCvar_GameMode = INVALID_HANDLE;
Handle g_hOnThirdPersonChanged = INVALID_HANDLE;



public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_hOnThirdPersonChanged = CreateGlobalForward("TP_OnThirdPersonChanged", ET_Event, Param_Cell, Param_Cell);
	RegPluginLibrary("ThirdPersonShoulder_Detect");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("ThirdPersonShoulder_Detect_Version", PLUGIN_VERSION, "Version Of Plugin", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);

	HookEvent("player_team", eTeamChange);
	HookEvent("player_death", ePlayerDeath);
	HookEvent("survivor_rescued", eSurvivorRescued);

	
	hCvar_GameMode = FindConVar("mp_gamemode");
	HookConVarChange(hCvar_GameMode, eConvarChanged);
	
	
	CreateTimer(0.25, tThirdPersonCheck, INVALID_HANDLE, TIMER_REPEAT);
}

public void OnMapStart()
{
	CvarsChanged();
}

public void eConvarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	CvarsChanged();
}

void CvarsChanged()
{
	char sGamemode[7];
	GetConVarString(hCvar_GameMode, sGamemode, sizeof(sGamemode));
	
	static bool bWasVersus;
	bVersus = StrEqual("versus", sGamemode, false);
	if(bVersus)
	{
		for(int i = 1; i <= MaxClients; i++)
			if(__IsValidClient(i))
				TP_PushForwardToPlugins(i, true, false);
		bWasVersus = true;
	}
	else
	{
		if(bWasVersus)
			for(int i = 1; i <= MaxClients; i++)
				if(__IsValidClient(i))
					TP_PushForwardToPlugins(i);
				
		bWasVersus = false;
	}
}

public Action tThirdPersonCheck(Handle hTimer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!__IsValidClient(i) || IsFakeClient(i))
			continue;
		
		QueryClientConVar(i, "c_thirdpersonshoulder", QueryClientConVarCallback);
	}
}

public void QueryClientConVarCallback(QueryCookie sCookie, int iClient, ConVarQueryResult sResult, const char[] sCvarName, const char[] sCvarValue)
{
	static bool bLastVal;
	bLastVal = bThirdPerson[iClient];
	
	//THIRDPERSON
	if(!StrEqual(sCvarValue, "0"))
	{
		if(bThirdPersonFix[iClient])
		{
			bThirdPerson[iClient] = false;
		}
		else
			bThirdPerson[iClient] = true;
	}
	else //FIRSTPERSON
	{
		if(IsClientInGame(iClient) && IsPlayerAlive(iClient))// just incase tps gets toggled while dead.
			bThirdPersonFix[iClient] = false;
		bThirdPerson[iClient] = false;
	}
	
	if(bLastVal == bThirdPerson[iClient])
		return;
	
	if(bVersus)
	{
		TP_PushForwardToPlugins(iClient, true, false);
		return;
	}
	TP_PushForwardToPlugins(iClient);
}

static void TP_PushForwardToPlugins(int iClient, bool bOverride=false, bool bIsThirdPerson=false)
{
	Call_StartForward(g_hOnThirdPersonChanged);
	Call_PushCell(iClient);
	if(bOverride)
	{
		Call_PushCell(bIsThirdPerson);
	}
	else
	{
		Call_PushCell(bThirdPerson[iClient]);
	}
	Call_Finish();
}

public void ePlayerDeath(Handle hEvent, const char[] sMame, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!__IsValidClient(iClient) || IsFakeClient(iClient))
		return;
	
	bThirdPersonFix[iClient] = true;
}

public void eSurvivorRescued(Handle hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "victim"));
	
	if(!__IsValidClient(iClient) || IsFakeClient(iClient))
		return;
	
	bThirdPersonFix[iClient] = true;
}

public void eTeamChange(Handle hEvent, const char[] sMame, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!__IsValidClient(iClient) || IsFakeClient(iClient))
		return;
	
	bThirdPersonFix[iClient] = true;
}

public void OnClientPutInServer(int iClient)
{
	if(!IsFakeClient(iClient))
		TP_PushForwardToPlugins(iClient, true, false);
	bThirdPersonFix[iClient] = true;
}

public void OnClientDisconnect(int iClient)
{
	bThirdPersonFix[iClient] = false;
	bThirdPerson[iClient] = false;
}

static bool __IsValidClient(int iClient)
{
	return (iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient));
}