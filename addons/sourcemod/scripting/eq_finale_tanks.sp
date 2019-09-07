#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>

#define FINALE_STAGE_TANK 8

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
	author = "Visor",
	description = "Either two event tanks or one flow and one (second) event tank",
	version = "2.4",
	url = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);

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

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
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
	// PrintToChatAll("Finale type %i has commenced", finaleType);
	if (finaleType == FINALE_STAGE_TANK) 
	{
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