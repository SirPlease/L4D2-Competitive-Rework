#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define STATE_SPAWNREADY 0
#define STATE_TOOCLOSE 256
#define SPAWN_RANGE 150

new Handle:FS_hEnabled;

new bool:FS_bIsFinale;
new bool:FS_bEnabled = true;

public FS_OnModuleStart()
{
	FS_hEnabled = CreateConVarEx("reduce_finalespawnrange", "1", "Adjust the spawn range on finales for infected, to normal spawning range");
	
	HookConVarChange(FS_hEnabled, FS_ConVarChange);
	
	FS_bEnabled = GetConVarBool(FS_hEnabled);
	
	HookEvent("round_end", FS_Round_Event, EventHookMode_PostNoCopy);
	HookEvent("round_start", FS_Round_Event, EventHookMode_PostNoCopy);
	HookEvent("finale_start", FS_FinaleStart_Event, EventHookMode_PostNoCopy);
}

public Action:FS_Round_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	FS_bIsFinale = false;
}

public Action:FS_FinaleStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	FS_bIsFinale = true;
}

public FS_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	FS_bEnabled = GetConVarBool(FS_hEnabled);
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_PreThinkPost, HookCallback);
}

public HookCallback(client)
{
	if (!FS_bEnabled) return;
	if (!FS_bIsFinale) return;
	if (GetClientTeam(client) != TEAM_INFECTED) return;
	if (GetEntProp(client,Prop_Send,"m_isGhost",1) != 1) return;
	
	if (GetEntProp(client, Prop_Send, "m_ghostSpawnState") == STATE_TOOCLOSE)
	{
		if (!TooClose(client))
		{
			SetEntProp(client, Prop_Send, "m_ghostSpawnState", STATE_SPAWNREADY);
		}
	}
}

bool:TooClose(client)
{
	decl Float:fInfLocation[3], Float:fSurvLocation[3], Float:fVector[3];
	GetClientAbsOrigin(client, fInfLocation);
	
	for (new i = 0; i < 4; i++)
	{
		new index = GetSurvivorIndex(i);
		if (index == 0) continue;
		if (!IsPlayerAlive(index)) continue;
		GetClientAbsOrigin(index, fSurvLocation);
		
		MakeVectorFromPoints(fInfLocation, fSurvLocation, fVector);
		
		if (GetVectorLength(fVector) <= SPAWN_RANGE) return true;
	}
	return false;
}