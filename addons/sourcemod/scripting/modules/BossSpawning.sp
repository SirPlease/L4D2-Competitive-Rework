#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define DEBUG_BS	0

#define MAX_TANKS		5
#define MAX_WITCHES	5

new Handle:BS_hEnabled;

new bool:BS_bEnabled = true;
new bool:BS_bIsFirstRound = true;
new bool:BS_bDeleteWitches = false;
new bool:BS_bFinaleStarted = false;
new bool:BS_bExpectTankSpawn = false;

new BS_iTankCount[2];
new BS_iWitchCount[2];

new Float:BS_fTankSpawn[MAX_TANKS][3];
new Float:BS_fWitchSpawn[MAX_WITCHES][2][3];

new String:BS_sMap[64];

public BS_OnModuleStart()
{
	BS_hEnabled = CreateConVarEx("lock_boss_spawns", "1", "Enables forcing same coordinates for tank and witch spawns");
	HookConVarChange(BS_hEnabled, BS_ConVarChange);
	
	BS_bEnabled = GetConVarBool(BS_hEnabled);
	
	HookEvent("tank_spawn", BS_TankSpawn);
	HookEvent("witch_spawn", BS_WitchSpawn);
	HookEvent("round_end", BS_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("finale_start", BS_FinaleStart, EventHookMode_PostNoCopy);
}

public BS_OnMapStart()
{
	BS_bIsFirstRound = true;
	BS_bFinaleStarted = false;
	BS_bExpectTankSpawn = false;
	BS_iTankCount[0] = 0;
	BS_iTankCount[1] = 0;
	BS_iWitchCount[0] = 0;
	BS_iWitchCount[1] = 0;
	
	GetCurrentMap(BS_sMap, sizeof(BS_sMap));
}

public BS_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	BS_bEnabled = GetConVarBool(BS_hEnabled);
}

public Action:BS_WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!BS_bEnabled || !IsPluginEnabled()) return;
	
	new iWitch = GetEventInt(event, "witchid");
	
	if (BS_bDeleteWitches)
	{
		// Used to delete round2 extra witches, which spawn on round start instead of by flow
		AcceptEntityInput(iWitch, "Kill");
		return;
	}
	
	// Can't track more witches if our witch array is full
	if (BS_iWitchCount[!BS_bIsFirstRound] >= MAX_WITCHES) return;
	
	if (BS_bIsFirstRound)
	{
		// If it's the first round, track our witch.
		GetEntPropVector(iWitch, Prop_Send, "m_vecOrigin", BS_fWitchSpawn[BS_iWitchCount[0]][0]);
		GetEntPropVector(iWitch, Prop_Send, "m_angRotation", BS_fWitchSpawn[BS_iWitchCount[0]][1]);
		BS_iWitchCount[0]++;
	}
	else if (BS_iWitchCount[0] > BS_iWitchCount[1])
	{
		// Until we have found the same number of witches as from round1, teleport them to round1 locations
		TeleportEntity(iWitch, BS_fWitchSpawn[BS_iWitchCount[1]][0], BS_fWitchSpawn[BS_iWitchCount[1]][1], NULL_VECTOR);
		BS_iWitchCount[1]++;
	}
}

Action:BS_OnTankSpawn_Forward()
{
	if(BS_bEnabled && IsPluginEnabled())
		BS_bExpectTankSpawn = true;
	return Plugin_Continue;
}

public Action:BS_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!BS_bEnabled || !IsPluginEnabled()) return;
	// Don't touch tanks on finale events
	if (BS_bFinaleStarted) return;
	// Stop if this isn't the first tank_spawn for this tank
	if(!BS_bExpectTankSpawn) return;
	BS_bExpectTankSpawn = false;
	// Don't track tank spawns on c5m5 or tank can spawn behind other team.
	if(StrEqual(BS_sMap, "c5m5_bridge")) return; 
	
	new iTankClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetMapValueInt("tank_z_fix")) FixZDistance(iTankClient); // fix stuck tank spawns, ex c1m1
	
	// If we reach MAX_TANKS, we don't have any room to store their locations
	if (BS_iTankCount[!BS_bIsFirstRound] >= MAX_TANKS) return;
	
	if(DEBUG_BS || IsDebugEnabled())
		LogMessage("[BS] Tracking this tank spawn. Currently, %d tanks", BS_iTankCount[!BS_bIsFirstRound]);
	
	if (BS_bIsFirstRound)
	{
		GetClientAbsOrigin(iTankClient, BS_fTankSpawn[BS_iTankCount[0]]);
		if(DEBUG_BS || IsDebugEnabled())
			LogMessage("[BS] Saving tank at %f %f %f", 
				BS_fTankSpawn[BS_iTankCount[0]][0],  
				BS_fTankSpawn[BS_iTankCount[0]][1],  
				BS_fTankSpawn[BS_iTankCount[0]][2]);
		
		BS_iTankCount[0]++;
	}
	else if (BS_iTankCount[0] > BS_iTankCount[1])
	{
		TeleportEntity(iTankClient, BS_fTankSpawn[BS_iTankCount[1]], NULL_VECTOR, NULL_VECTOR);
		if(DEBUG_BS || IsDebugEnabled())
			LogMessage("[BS] Teleporting tank to tank at %f %f %f", 
				BS_fTankSpawn[BS_iTankCount[1]][0],  
				BS_fTankSpawn[BS_iTankCount[1]][1],  
				BS_fTankSpawn[BS_iTankCount[1]][2]);
				
		BS_iTankCount[1]++;
	}
	else if(DEBUG_BS || IsDebugEnabled())
	{
		LogMessage("[BS] Not first round and not acceptable tank");
		LogMessage("[BS] IsFirstRound: %d  R1Count: %d R2Count: %d", 
			BS_bIsFirstRound, BS_iTankCount[0], BS_iTankCount[1]);
	}
}

public Action:BS_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	BS_bIsFirstRound = false;
	BS_bFinaleStarted = false;
	if(StrEqual(BS_sMap, "c6m1_riverbank")) {
		BS_bDeleteWitches = false;
	} else {
		BS_bDeleteWitches = true;
		CreateTimer(5.0, BS_WitchTimerReset);
	}
}

public Action:BS_FinaleStart(Handle:event, const String:name[], bool:dontBroadcast) BS_bFinaleStarted = true;

public Action:BS_WitchTimerReset(Handle:timer)
{
	BS_bDeleteWitches = false;
}

FixZDistance(iTankClient)
{
	decl Float:TankLocation[3];
	decl Float:TempSurvivorLocation[3];
	decl index;
	
	GetClientAbsOrigin(iTankClient, TankLocation);
	
	if (DEBUG_BS || IsDebugEnabled())
	{
		LogMessage("[BS] tank z spawn check... Map: %s, Tank Location: %f, %f, %f", BS_sMap, TankLocation[0], TankLocation[1], TankLocation[2]);
	}
	
	for (new i = 0; i < NUM_OF_SURVIVORS; i++)
	{
		new Float:distance = GetMapValueFloat("max_tank_z", 99999999999999.9);
		index = GetSurvivorIndex(i);
		if (index != 0 && IsValidEntity(index))
		{
			GetClientAbsOrigin(index, TempSurvivorLocation);
			
			if (DEBUG_BS || IsDebugEnabled()) LogMessage("[BS] Survivor %d Location: %f, %f, %f", i, TempSurvivorLocation[0], TempSurvivorLocation[1], TempSurvivorLocation[2]);
			
			if (FloatAbs(TempSurvivorLocation[2] - TankLocation[2]) > distance)
			{
				new Float:WarpToLocation[3];
				GetMapValueVector("tank_warpto", WarpToLocation);
				if (!GetVectorLength(WarpToLocation, true))
				{
					LogMessage("[BS] tank_warpto missing from mapinfo.txt");
					return;
				}
				TeleportEntity(iTankClient, WarpToLocation, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}






