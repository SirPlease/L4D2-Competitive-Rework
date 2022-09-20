#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new bool:WS_bEnabled = true;
new Handle:WS_hEnable;
new Handle:WS_hFactor;

new bool:WS_bPlayerInWater[MAXPLAYERS+1];
new bool:WS_bJockeyInWater = false;

WS_OnModuleStart()
{
	WS_hEnable = CreateConVarEx("waterslowdown","1", "Enables additional water slowdown");
	WS_hFactor = CreateConVarEx("slowdown_factor", "0.90", "Sets how much water will slow down survivors. 1.00 = Vanilla");
	
	HookConVarChange(WS_hEnable,WS_ConVarChange);
	HookEvent("round_start", WS_RoundStart);
	HookEvent("jockey_ride", WS_JockeyRide);
	HookEvent("jockey_ride_end", WS_JockeyRideEnd);
}

WS_OnModuleEnd()
{
	WS_SetStatus(false);
}

WS_OnGameFrame()
{
	if(!IsServerProcessing() || !IsPluginEnabled() || !WS_bEnabled){return;}
	decl client, flags;
	
	for(new i=0;i<NUM_OF_SURVIVORS;i++)
	{
		client = GetSurvivorIndex(i);
		if(client != 0 && IsValidEntity(client))
		{
			flags = GetEntityFlags(client);
			
			if(!(flags & IN_JUMP && WS_bPlayerInWater[client]))
			{
				if(flags & FL_INWATER)
				{
					if(!WS_bPlayerInWater[client])
					{
						WS_bPlayerInWater[client] = true;
						SetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue",GetConVarFloat(WS_hFactor));
					}
				}
				else
				{
					if(WS_bPlayerInWater[client])
					{
						WS_bPlayerInWater[client] = false;
						SetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue",1.0);
					}
				}
			}
		}
	}
}

public WS_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	WS_SetStatus();
}

public Action:WS_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	WS_SetStatus();
}

WS_OnMapEnd()
{
	WS_SetStatus(false);
}

public Action:WS_JockeyRide(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new jockey = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(WS_bPlayerInWater[victim] && !WS_bJockeyInWater)
	{
		WS_bJockeyInWater = true;
		SetEntPropFloat(jockey,Prop_Send,"m_flLaggedMovementValue",GetConVarFloat(WS_hFactor));
	}
	else if(!WS_bPlayerInWater[victim] && WS_bJockeyInWater)
	{
		WS_bJockeyInWater = false;
		SetEntPropFloat(jockey,Prop_Send,"m_flLaggedMovementValue",1.0);
	}
}

public Action:WS_JockeyRideEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new jockey = GetClientOfUserId(GetEventInt(event, "userid"));
	
	WS_bJockeyInWater = false;
	if(jockey && IsValidEntity(jockey))
	{
		SetEntPropFloat(jockey,Prop_Send,"m_flLaggedMovementValue",1.0);
	}
}

WS_SetStatus(bool:enable=true)
{
	if(!enable)
	{
		WS_bEnabled = false;
		return;
	}
	WS_bEnabled = GetConVarBool(WS_hEnable);
}