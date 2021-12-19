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
	fStartingFlow,
	fFurthestFlow,
	fBypassFlow,
	fLastWarningPrint;

int
	m_nPendingMobCount;

bool
	announcedTankSpawn,
	announcedHordeResume,
	announcedHordeMax;

public Plugin myinfo = 
{
	name = "L4D2 Tank Horde Monitor",
	author = "Derpduck, Visor (l4d2_horde_equaliser)",
	description = "Monitors and changes state of infinite hordes during tanks",
	version = "1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();
	
	g_hBypassFlowDistance = FindConVar("director_tank_bypass_max_flow_travel");
	g_hBypassExtraFlowDistance = CreateConVar("l4d2_tank_bypass_extra_flow", "1500.0", "Extra allowed flow distance to bypass tanks during infinite events (0 = disabled)", FCVAR_NONE, true, 0.0);
	
	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEndEvent, EventHookMode_PostNoCopy);
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
	announcedTankSpawn = false;
	announcedHordeResume = false;
	announcedHordeMax = false;
	fStartingFlow = 0.0;
	fBypassFlow = 0.0;
	fFurthestFlow = 0.0;
	fLastWarningPrint = 0.0;
}

public void RoundEndEvent(Event hEvent, const char[] name, bool dontBroadcast)
{
	TimerCleanUp();
}

public Action L4D_OnSpawnTank(const float vecPos[3], const float vecAng[3])
{
	// Has tank has spawned during an infinite event?
	if (IsInfiniteHordeActive()){
		fStartingFlow = L4D2_GetFurthestSurvivorFlow();
		fBypassFlow = L4D2_GetFurthestSurvivorFlow() + g_hBypassFlowDistance.FloatValue;

		float fProgressFlowPercent = GetFlowUntilBypass(fStartingFlow, fBypassFlow);
		fLastWarningPrint = fProgressFlowPercent;

		if (!announcedTankSpawn){
			CPrintToChatAll("<{olive}Horde{default}> Horde has {blue}paused{default} due to tank in play! Progressing by {blue}%0.1f%%{default} will start the horde.", fProgressFlowPercent);
			announcedTankSpawn = true;
		}

		// Begin periodic flow checker
		g_hFlowCheckTimer = CreateTimer(1.0, FlowCheckTimer, _, TIMER_REPEAT);
	}
}

public Action FlowCheckTimer(Handle hTimer)
{
	g_hFlowCheckTimer = null;
	
	if (!IsTankUp()){
		TimerCleanUp();
		return Plugin_Stop;
	}

	// Return furthest achieved survivor flow
	fFurthestFlow = L4D2_GetFurthestSurvivorFlow();

	// If approaching the bypass limit, print warnings
	float fWarningPercent = GetFlowUntilBypass(fFurthestFlow, fBypassFlow);

	if (fLastWarningPrint - fWarningPercent >= 1.0 && !announcedHordeResume){
		fLastWarningPrint = fWarningPercent;
		CPrintToChatAll("<{olive}Horde{default}> {blue}%0.1f%%{default} left until horde starts...", fWarningPercent);
	}

	return Plugin_Continue;
}

public void TimerCleanUp()
{
	if (g_hFlowCheckTimer != null){
		delete g_hFlowCheckTimer;
	}
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
	
	// Adjust horde amount based on how far survivors have pushed the tank
	// Scale original horde size as a percentage of highest achieved flow between director_tank_bypass_max_flow_travel and l4d2_tank_bypass_extra_flow
	if (IsTankUp() && IsInfiniteHordeActive()){
		float fPushAmount = (fFurthestFlow - fBypassFlow) / (g_hBypassFlowDistance.FloatValue + g_hBypassExtraFlowDistance.FloatValue);

		// Clamp values
		if (fPushAmount < 0){
			fPushAmount = 0.0;
		} else if (fPushAmount > 1){
			fPushAmount = 1.0;
		}

		int iNewAmount = iNewAmount = RoundToNearest(amount * fPushAmount);

		SetPendingMobCount(iNewAmount);
		amount = iNewAmount;

		if (!announcedHordeResume){
			TimerCleanUp();
			CPrintToChatAll("<{olive}Horde{default}> Survivors are pushing the tank, {green}ramping up{default} the horde as they push!");
			announcedHordeResume = true;
		}

		if (!announcedHordeMax && fPushAmount == 1.0){
			CPrintToChatAll("<{olive}Horde{default}> Survivors have pushed too far, horde is now at {red}max{default}!");
			announcedHordeMax = true;
		}

		return Plugin_Handled;
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

bool IsTankUp()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED) {
			if (GetEntProp(i, Prop_Send, "m_zombieClass") == Z_TANK && IsPlayerAlive(i)) {
				return true;
			}
		}
	}

	return false;
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