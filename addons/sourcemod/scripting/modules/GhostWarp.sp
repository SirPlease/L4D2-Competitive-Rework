#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:GW_hGhostWarp;
new bool:GW_bEnabled = true;
new bool:GW_bDelay[MAXPLAYERS+1];
new GW_iLastTarget[MAXPLAYERS+1] = -1;

GW_OnModuleStart()
{
	// GhostWarp
	GW_hGhostWarp = CreateConVarEx("ghost_warp", "1", "Sets whether infected ghosts can right click for warp to next survivor");
	
	// Ghost Warp
	HookEvent("player_death",GW_PlayerDeath_Event);
	HookConVarChange(GW_hGhostWarp,GW_ConVarChange);
	RegConsoleCmd("sm_warptosurvivor",GW_Cmd_WarpToSurvivor);
	
	GW_bEnabled = GetConVarBool(GW_hGhostWarp);
}

bool:GW_OnPlayerRunCmd(client, buttons)
{
	if (!IsPluginEnabled() || !GW_bEnabled || !(buttons & IN_ATTACK2) || GW_bDelay[client]){return false;}
	if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED || GetEntProp(client,Prop_Send,"m_isGhost",1) != 1){return false;}
	
	GW_bDelay[client] = true;
	CreateTimer(0.25, GW_ResetDelay, client);
	
	GW_WarpToSurvivor(client,0);
	
	return true;
}

public GW_PlayerDeath_Event(Handle:event, const String:name[], bool:dB)
{
	decl client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	GW_iLastTarget[client] = -1;
}

public GW_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GW_bEnabled = GetConVarBool(GW_hGhostWarp);
}

public Action:GW_ResetDelay(Handle:timer, any:client)
{
	GW_bDelay[client] = false;
}

public Action:GW_Cmd_WarpToSurvivor(client,args)
{
	if (!IsPluginEnabled() || !GW_bEnabled || args != 1 || !IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED || GetEntProp(client,Prop_Send,"m_isGhost",1) != 1){return Plugin_Handled;}
	
	decl String:buffer[2];
	GetCmdArg(1, buffer, 2);
	if(strlen(buffer) == 0){return Plugin_Handled;}
	new charz = (StringToInt(buffer));
	
	GW_WarpToSurvivor(client,charz);
	
	return Plugin_Handled;
}

GW_WarpToSurvivor(client,charz)
{
	decl target;
	
	if(charz <= 0)
	{
		target = GW_FindNextSurvivor(client,GW_iLastTarget[client]);
	}
	else if(charz <= 4)
	{
		target = GetSurvivorIndex(charz-1);
	}
	else
	{
		return;
	}
	
	if(target == 0){return;}
	
	// Prevent people from spawning and then warp to survivor
	SetEntProp(client,Prop_Send,"m_ghostSpawnState",256);
	
	decl Float:position[3], Float:anglestarget[3];
	
	GetClientAbsOrigin(target, position);
	GetClientAbsAngles(target, anglestarget);
	TeleportEntity(client, position, anglestarget, NULL_VECTOR);
	
	return;
}

GW_FindNextSurvivor(client,charz)
{
	if (!IsAnySurvivorsAlive())
	{
		return 0;
	}
	
	new havelooped = false;
	charz++;
	if (charz >= NUM_OF_SURVIVORS)
	{
		charz = 0;
	}
	
	for(new index = charz;index<=MaxClients;index++)
	{
		if (index >= NUM_OF_SURVIVORS)
		{
			if (havelooped)
			{
				break;
			}
			havelooped = true;
			index = 0;
		}
		
		if (GetSurvivorIndex(index) == 0)
		{
			continue;
		}
		
		GW_iLastTarget[client] = index;
		return GetSurvivorIndex(index);
	}
	
	return 0;
}