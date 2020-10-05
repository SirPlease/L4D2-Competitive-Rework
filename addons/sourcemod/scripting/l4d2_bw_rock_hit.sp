#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

new bool:lateLoad;

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax) 
{
	lateLoad = late;
	return APLRes_Success;    
}

public Plugin:myinfo =
{
	name = "L4D2 Black&White Rock Hit",
	author = "Visor",
	description = "Stops rocks from passing through soon-to-be-dead Survivors",
	version = "1.0",
	url = "https://github.com/Attano/L4D2-Competitive-Framework"
};

public OnPluginStart()
{      
	if (lateLoad) 
	{
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (IsClientInGame(i)) 
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3]) 
{
	// decl String:classname[64];
	// GetEdictClassname(inflictor, classname, sizeof(classname));
	// PrintToChatAll("Victim %d attacker %d inflictor %d damageType %d weapon %d", victim, attacker, inflictor, damageType, weapon);
	// PrintToChatAll("Victim %N(%i/%i) attacker %N classname %s", victim, GetSurvivorPermanentHealth(victim), GetSurvivorTemporaryHealth(victim), attacker, classname);
	
	// Not what we need
	if (!IsSurvivor(victim) || !IsTank(attacker) || !IsTankRock(inflictor))
	{
		return Plugin_Continue;
	}
	
	// Not b&w
	if (!IsOnCriticalStrike(victim))
	{
		return Plugin_Continue;
	}
	
	// Gotcha
	if (GetSurvivorTemporaryHealth(victim) <= GetConVarInt(FindConVar("vs_tank_damage")))
	{
		// SDKHooks_TakeDamage(inflictor, attacker, attacker, 300.0, DMG_CLUB, GetActiveWeapon(victim));
		// AcceptEntityInput(inflictor, "Kill");
		// StopSound(attacker, SNDCHAN_AUTO, "player/tank/attack/thrown_missile_loop_1.wav");
		CTankRock__Detonate(inflictor);
	}
	return Plugin_Continue;
}

GetSurvivorTemporaryHealth(client)
{
	new temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
	return (temphp > 0 ? temphp : 0);
}

IsOnCriticalStrike(client)
{
	return (GetConVarInt(FindConVar("survivor_max_incapacitated_count")) == GetEntProp(client, Prop_Send, "m_currentReviveCount"));
}

bool:IsSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

bool:IsTank(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(client));
}

bool:IsTankRock(entity)
{
    if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
    {
        decl String:classname[64];
        GetEdictClassname(entity, classname, sizeof(classname));
        return StrEqual(classname, "tank_rock");
    }
    return false;
}

CTankRock__Detonate(rock)
{
	static Handle:call = INVALID_HANDLE;
	if (call == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Entity);
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN9CTankRock8DetonateEv", 0))
		{
			return;
		}
		call = EndPrepSDKCall();
		if (call == INVALID_HANDLE)
		{
			return;
		}
	}
	SDKCall(call, rock);
}