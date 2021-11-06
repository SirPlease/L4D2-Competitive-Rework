#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks> //#include <l4d2_direct>

#define MAP_NAME_MAX_LENGTH 64

#if !defined _l4dh_included
// from https://developer.valvesoftware.com/wiki/L4D2_Director_Scripts
enum
{
	FINALE_GAUNTLET_1 = 0,
	FINALE_HORDE_ATTACK_1 = 1,
	FINALE_HALFTIME_BOSS = 2,
	FINALE_GAUNTLET_2 = 3,
	FINALE_HORDE_ATTACK_2 = 4,
	FINALE_FINAL_BOSS = 5,
	FINALE_HORDE_ESCAPE = 6,
	FINALE_CUSTOM_PANIC = 7,
	FINALE_CUSTOM_TANK = 8,
	FINALE_CUSTOM_SCRIPTED = 9,
	FINALE_CUSTOM_DELAY = 10,
	FINALE_CUSTOM_CLEAROUT = 11,
	FINALE_GAUNTLET_START = 12,
	FINALE_GAUNTLET_HORDE = 13,
	FINALE_GAUNTLET_HORDE_BONUSTIME	= 14,
	FINALE_GAUNTLET_BOSS_INCOMING = 15,
	FINALE_GAUNTLET_BOSS = 16,
	FINALE_GAUNTLET_ESCAPE = 17
};
#endif

enum TankSpawningScheme
{
	Skip,
	FlowAndSecondOnEvent,
	FirstOnEvent
};

ConVar
	hVersusTankChanceFinale = null;

StringMap
	hFirstTankSpawningScheme = null,
	hSecondTankSpawningScheme = null;

TankSpawningScheme
	spawnScheme = Skip;

int
	tankCount = 0;

public Plugin myinfo =
{
	name = "EQ2 Finale Tank Manager",
	author = "Visor, Electr0",
	description = "Either two event tanks or one flow and one (second) event tank",
	version = "2.5.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	hFirstTankSpawningScheme = new StringMap();
	hSecondTankSpawningScheme = new StringMap();

	hVersusTankChanceFinale = FindConVar("versus_tank_chance_finale");

	RegServerCmd("tank_map_flow_and_second_event", SetMapFirstTankSpawningScheme);
	RegServerCmd("tank_map_only_first_event", SetMapSecondTankSpawningScheme);

	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);
}

public Action SetMapFirstTankSpawningScheme(int args)
{
	if (args != 1) {
		PrintToServer("Usage: tank_map_flow_and_second_event <mapname>");
		LogError("Usage: tank_map_flow_and_second_event <mapname>");
		return Plugin_Handled;
	}
	
	char mapname[MAP_NAME_MAX_LENGTH];
	GetCmdArg(1, mapname, sizeof(mapname));
	hFirstTankSpawningScheme.SetValue(mapname, true);

	return Plugin_Handled;
}

public Action SetMapSecondTankSpawningScheme(int args)
{
	if (args != 1) {
		PrintToServer("Usage: tank_map_only_first_event <mapname>");
		LogError("Usage: tank_map_only_first_event <mapname>");
		return Plugin_Handled;
	}
	
	char mapname[MAP_NAME_MAX_LENGTH];
	GetCmdArg(1, mapname, sizeof(mapname));
	hSecondTankSpawningScheme.SetValue(mapname, true);

	return Plugin_Handled;
}

public void RoundStartEvent(Event hEvent, const char[] name, bool dontBroadcast)
{
	CreateTimer(8.0, ProcessTankSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action ProcessTankSpawn(Handle hTimer)
{
	spawnScheme = Skip;
	tankCount = 0;
	
	char mapname[MAP_NAME_MAX_LENGTH];
	GetCurrentMap(mapname, sizeof(mapname));
	
	int iValue;
	if (hFirstTankSpawningScheme.GetValue(mapname, iValue)) {
		spawnScheme = FlowAndSecondOnEvent;
	}
	
	if (hSecondTankSpawningScheme.GetValue(mapname, iValue)) {
		spawnScheme = FirstOnEvent;
	}
	
	if (IsTankAllowed() && spawnScheme != Skip) {
		bool bIsSpawn = (spawnScheme == FlowAndSecondOnEvent);
		L4D2Direct_SetVSTankToSpawnThisRound(InSecondHalfOfRound(), bIsSpawn);
	}

	return Plugin_Stop;
}

public Action L4D2_OnChangeFinaleStage(int &finaleType, const char[] arg)
{
	if (spawnScheme != Skip
		&& (finaleType == FINALE_CUSTOM_TANK
		|| finaleType == FINALE_GAUNTLET_BOSS
		|| finaleType == FINALE_GAUNTLET_ESCAPE)
	) {
		//PrintToChatAll("Finale type %i has commenced", finaleType);
		
		tankCount++;
		
		if ((spawnScheme == FlowAndSecondOnEvent && tankCount != 2)
			|| (spawnScheme == FirstOnEvent && tankCount != 1)
		) {
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

int InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound");
}

bool IsTankAllowed()
{
	return (hVersusTankChanceFinale.FloatValue > 0.0);
}
