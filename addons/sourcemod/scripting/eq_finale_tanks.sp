#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>

// from https://developer.valvesoftware.com/wiki/L4D2_Director_Scripts
enum ()
{
	FINALE_GAUNTLET_1 = 0,
	FINALE_HORDE_ATTACK_1 = 1,
	FINALE_HALFTIME_BOSS = 2,
	FINALE_GAUNTLET_2 = 3,
	FINALE_HORDE_ATTACK_2 = 4,
	FINALE_FINAL_BOSS = 5,
	FINALE_HORDE_ESCAPE	= 6,
	FINALE_CUSTOM_PANIC	= 7,
	FINALE_CUSTOM_TANK	= 8,
	FINALE_CUSTOM_SCRIPTED	= 9,
	FINALE_CUSTOM_DELAY	= 10,
	FINALE_CUSTOM_CLEAROUT = 11,
	FINALE_GAUNTLET_START = 12,
	FINALE_GAUNTLET_HORDE = 13,
	FINALE_GAUNTLET_HORDE_BONUSTIME	= 14,
	FINALE_GAUNTLET_BOSS_INCOMING = 15,
	FINALE_GAUNTLET_BOSS = 16,
	FINALE_GAUNTLET_ESCAPE = 17
};

enum TankSpawningScheme
{
	Skip,
	FlowAndSecondOnEvent,
	FirstOnEvent
};

new Handle:hFirstTankSpawningScheme;
new Handle:hSecondTankSpawningScheme;

new TankSpawningScheme:spawnScheme;
new tankCount;

public Plugin:myinfo =
{
	name = "EQ2 Finale Tank Manager",
	author = "Visor, Electr0",
	description = "Either two event tanks or one flow and one (second) event tank",
	version = "2.5.1",
	url = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);

	hFirstTankSpawningScheme = CreateTrie();
	hSecondTankSpawningScheme = CreateTrie();

	RegServerCmd("tank_map_flow_and_second_event", SetMapFirstTankSpawningScheme);
	RegServerCmd("tank_map_only_first_event", SetMapSecondTankSpawningScheme);
}

public Action:SetMapFirstTankSpawningScheme(args)
{
	decl String:mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	SetTrieValue(hFirstTankSpawningScheme, mapname, true);
}

public Action:SetMapSecondTankSpawningScheme(args)
{
	decl String:mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	SetTrieValue(hSecondTankSpawningScheme, mapname, true);
}

public Action:RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(8.0, ProcessTankSpawn);
}

public Action:ProcessTankSpawn(Handle:timer) 
{
	spawnScheme = Skip;
	tankCount = 0;
	
	decl String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	
	new bool:dummy;
	if (GetTrieValue(hFirstTankSpawningScheme, mapname, dummy))
	{
		spawnScheme = FlowAndSecondOnEvent;
	}
	if (GetTrieValue(hSecondTankSpawningScheme, mapname, dummy))
	{
		spawnScheme = FirstOnEvent;
	}
	
	if (IsTankAllowed() && spawnScheme != Skip)
	{
		L4D2Direct_SetVSTankToSpawnThisRound(InSecondHalfOfRound(), (spawnScheme == FlowAndSecondOnEvent));
	}
}

public Action:L4D2_OnChangeFinaleStage(&finaleType, const String:arg[]) 
{	
	if (spawnScheme != Skip && (finaleType == FINALE_CUSTOM_TANK || finaleType == FINALE_GAUNTLET_BOSS || finaleType == FINALE_GAUNTLET_ESCAPE))
	{
		//PrintToChatAll("Finale type %i has commenced", finaleType);
		
		tankCount++;
		
		if ((spawnScheme == FlowAndSecondOnEvent && tankCount != 2)
			|| (spawnScheme == FirstOnEvent && tankCount != 1))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound");
}

bool:IsTankAllowed()
{
	return GetConVarFloat(FindConVar("versus_tank_chance_finale")) > 0.0;
}