#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <sdktools>
#include <colors>

#define Z_TANK 8
#define TEAM_INFECTED 3

#define ZOMBIEMANAGER_GAMEDATA "l4d2_zombiemanager"
#define LEFT4FRAMEWORK_GAMEDATA "left4dhooks.l4d2"

Address
	pZombieManager = Address_Null;

ConVar
	g_hBypassFlowDistance,
	g_hBypassExtraFlowDistance;

Handle
	g_hFlowCheckTimer;

float
	fFurthestFlow,
	fBypassFlow,
	fProgressFlowPercent,
	fPushWarningPercent;

int
	m_nPendingMobCount;

bool
	announcedTankSpawn,
	announcedHordeResume,
	announcedHordeMax,
	tankInPlay,
	tankInPlayDelay;

public Plugin myinfo = 
{
	name = "L4D2 Tank Horde Monitor",
	author = "Derpduck, Visor (l4d2_horde_equaliser)",
	description = "Monitors and changes state of infinite hordes during tanks",
	version = "1.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();
	
	g_hBypassFlowDistance = FindConVar("director_tank_bypass_max_flow_travel");
	g_hBypassExtraFlowDistance = CreateConVar("l4d2_tank_bypass_extra_flow", "1500.0", "Extra allowed flow distance to bypass tanks during infinite events (0 = disabled)", FCVAR_NONE, true, 0.0);
	
	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEndEvent, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", TankSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_death", TankDeath);
}

void InitGameData()
{
	Handle hDamedata = LoadGameConfigFile(LEFT4FRAMEWORK_GAMEDATA);
	if (!hDamedata) {
		SetFailState("%s gamedata missing or corrupt", LEFT4FRAMEWORK_GAMEDATA);
	}

	pZombieManager = GameConfGetAddress(hDamedata, "ZombieManager");
	if (!pZombieManager) {
		SetFailState("Couldn't find the 'ZombieManager' address");
	}
	
	delete hDamedata;

	Handle hDamedata2 = LoadGameConfigFile(ZOMBIEMANAGER_GAMEDATA);
	if (!hDamedata2) {
		SetFailState("%s gamedata missing or corrupt", ZOMBIEMANAGER_GAMEDATA);
	}
	
	m_nPendingMobCount = GameConfGetOffset(hDamedata2, "ZombieManager->m_nPendingMobCount");
	if (m_nPendingMobCount == -1) {
		SetFailState("Failed to get offset 'ZombieManager->m_nPendingMobCount'.");
	}

	delete hDamedata2;
}

public void RoundStartEvent(Event hEvent, const char[] name, bool dontBroadcast)
{
	ResetWarnings();
	TimerCleanUp();
	fBypassFlow = 0.0;
	fFurthestFlow = 0.0;
	fProgressFlowPercent = 0.0;
}

public void RoundEndEvent(Event hEvent, const char[] name, bool dontBroadcast)
{
	ResetWarnings();
	TimerCleanUp();
	fBypassFlow = 0.0;
	fFurthestFlow = 0.0;
	fProgressFlowPercent = 0.0;
}

public void OnMapEnd()
{
	ResetWarnings();
	TimerCleanUp();
	fBypassFlow = 0.0;
	fFurthestFlow = 0.0;
	fProgressFlowPercent = 0.0;
}

public void TankSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	if (!tankInPlay){
		tankInPlay = true;

		// Find current highest flow, and where the bypass point is
		fFurthestFlow = L4D2_GetFurthestSurvivorFlow();
		fBypassFlow = fFurthestFlow + g_hBypassFlowDistance.FloatValue;

		if (IsInfiniteHordeActive() && !announcedTankSpawn){
			AnnounceTankSpawn();
		}
	}
}

public void TankDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && IsInfected(client) && IsTank(client)) {
		CreateTimer(0.1, Timer_CheckTank);
	}
}

public void OnClientDisconnect(int client)
{
	// Was a bot tank kicked
	if (client > 0 && IsInfected(client) && IsTank(client) && IsFakeClient(client)) {
		CreateTimer(0.1, Timer_CheckTank);
	}
}

public Action Timer_CheckTank(Handle timer)
{
	int tankclient = FindTankClient();
	if (!tankclient || !IsPlayerAlive(tankclient)) {
		ResetWarnings();
		TimerCleanUp();
	}

	return Plugin_Stop;
}

public void AnnounceTankSpawn()
{
	fProgressFlowPercent = GetFlowUntilBypass(fFurthestFlow, fBypassFlow);
	CPrintToChatAll("<{olive}Horde{default}> Horde has {blue}paused{default} due to tank in play! Progressing by {blue}%0.1f%%{default} will start the horde.", fProgressFlowPercent);
	announcedTankSpawn = true;

	// Begin repeating flow checker
	g_hFlowCheckTimer = CreateTimer(2.0, FlowCheckTimer, _, TIMER_REPEAT);
}

public Action FlowCheckTimer(Handle hTimer)
{
	if (!tankInPlay || announcedHordeResume || announcedHordeMax){
		g_hFlowCheckTimer = null;
		return Plugin_Stop;
	}

	// Extra check to prevent rush warning misfiring if tank spawns on the same frame as a horde spawn
	if (!tankInPlayDelay){
		tankInPlayDelay = true;
	}

	// Return furthest achieved survivor flow
	fFurthestFlow = L4D2_GetFurthestSurvivorFlow();

	// Print warnings if approaching the bypass limit
	float fWarningPercent = GetFlowUntilBypass(fFurthestFlow, fBypassFlow);

	if (fProgressFlowPercent - fWarningPercent >= 1.0){
		fProgressFlowPercent = fWarningPercent;
		CPrintToChatAll("<{olive}Horde{default}> {blue}%0.1f%%{default} left until horde starts...", fWarningPercent);
	}

	return Plugin_Continue;
}

public Action L4D_OnSpawnMob(int &amount)
{
	/////////////////////////////////////
	// - Called on Event Hordes.
	// - Called on Panic Event Hordes.
	// - Called on Natural Hordes.
	// - Called on Onslaught (Mini-finale or finale Scripts)

	// - Not Called on Boomer Hordes.
	// - Not Called on z_spawn mob.
	////////////////////////////////////

	if (tankInPlay && IsInfiniteHordeActive()){
		// If survivors have already pushed past the extra bypass distance we can ignore this
		if (announcedHordeMax){
			return Plugin_Continue;
		} else {
			// Calculate how far survivors have pushed
			fFurthestFlow = L4D2_GetFurthestSurvivorFlow();
			float fPushAmount = (fFurthestFlow - fBypassFlow) / (g_hBypassFlowDistance.FloatValue + g_hBypassExtraFlowDistance.FloatValue);

			// Clamp values
			if (fPushAmount < 0.0){
				fPushAmount = 0.0;
			} else if (fPushAmount > 1.0){
				fPushAmount = 1.0;
			}

			// Have survivors pushed past the bypass point?
			if (!announcedHordeResume && tankInPlayDelay && fPushAmount >= 0.05){
				fPushWarningPercent = fPushAmount;
				int iPushPercent = RoundToNearest(fPushAmount * 100.0);
				CPrintToChatAll("<{olive}Horde{default}> Horde has {blue}resumed{default} at {green}%i%% strength{default}, pushing will increase the horde.", iPushPercent);
				announcedHordeResume = true;
			}

			// Horde strength prints
			if (fPushAmount - fPushWarningPercent >= 0.20 && fPushAmount != 1.0 && announcedHordeResume){
				fPushWarningPercent = fPushAmount;
				int iPushPercent = RoundToNearest(fPushAmount * 100.0);
				CPrintToChatAll("<{olive}Horde{default}> Horde is at {green}%i%% strength{default}...", iPushPercent);
			}

			// Have survivors have pushed past the extra distance we allow?
			if (fPushAmount == 1.0){
				CPrintToChatAll("<{olive}Horde{default}> Survivors have pushed too far, horde is at {green}100%% strength{default}!");
				announcedHordeMax = true;
			}

			// Scale amount of horde per mob with how far survivors have pushed
			int iNewAmount = RoundToNearest(amount * fPushAmount);

			SetPendingMobCount(iNewAmount);
			amount = iNewAmount;

			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

bool IsInfiniteHordeActive()
{
	int countdown = GetHordeCountdown();
	return (/*GetPendingMobCount() > 0 &&*/ countdown > -1 && countdown <= 10);
}

/*
int GetPendingMobCount()
{
	return LoadFromAddress(pZombieManager + view_as<Address>(m_nPendingMobCount), NumberType_Int32);
}
*/

void SetPendingMobCount(int count)
{
	StoreToAddress(pZombieManager + view_as<Address>(m_nPendingMobCount), count, NumberType_Int32);
}

int GetHordeCountdown()
{
	return (CTimer_HasStarted(L4D2Direct_GetMobSpawnTimer())) ? RoundFloat(CTimer_GetRemainingTime(L4D2Direct_GetMobSpawnTimer())) : -1;
}

bool IsInfected(int client)
{
	return (IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED);
}

bool IsTank(int client)
{
	return (GetEntProp(client, Prop_Send, "m_zombieClass") == Z_TANK);
}

int FindTankClient()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsInfected(i) || !IsTank(i) || !IsPlayerAlive(i)) {
			continue;
		}
		
		return i; // Found tank, return
	}
	return 0;
}

float GetFlowUntilBypass(float fCurrentFlowValue, float fBypassFlowValue)
{
	float fCurrentFlowPercent = (fCurrentFlowValue / L4D2Direct_GetMapMaxFlowDistance());
	float fBypassFlowPercent = (fBypassFlowValue / L4D2Direct_GetMapMaxFlowDistance());
	float result = (fBypassFlowPercent - fCurrentFlowPercent) * 100;

	if (result < 0){
		result = 0.0;
	}

	return result;
}

public void TimerCleanUp()
{
	if (g_hFlowCheckTimer != null){
		delete g_hFlowCheckTimer;
		g_hFlowCheckTimer = null;
	}
}

public void ResetWarnings()
{
	tankInPlay = false;
	tankInPlayDelay = false;
	announcedTankSpawn = false;
	announcedHordeResume = false;
	announcedHordeMax = false;
	fPushWarningPercent = 0.0;
}