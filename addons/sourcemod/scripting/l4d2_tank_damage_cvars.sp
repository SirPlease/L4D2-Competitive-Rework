#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

new Handle:vs_tank_pound_damage;
new Handle:vs_tank_rock_damage;

new bool:lateLoad;

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax) 
{
	lateLoad = late;
	return APLRes_Success;    
}

public Plugin:myinfo =
{
	name = "L4D2 Tank Damage Cvars",
	author = "Visor",
	description = "Toggle Tank attack damage per type",
	version = "1.1",
	url = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
	vs_tank_pound_damage = CreateConVar("vs_tank_pound_damage", "24", "Amount of damage done by a vs tank's melee attack on incapped survivors");
	vs_tank_rock_damage = CreateConVar("vs_tank_rock_damage", "24", "Amount of damage done by a vs tank's rock");
	
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
	if (!IsSurvivor(victim) || !IsTank(attacker))
	{
		return Plugin_Continue;
	}
	
	if (IsIncapped(victim) && IsTank(inflictor))
	{
		damage = GetConVarFloat(vs_tank_pound_damage);
	}
	else if (IsTankRock(inflictor))
	{
		damage = GetConVarFloat(vs_tank_rock_damage);
	}
	return Plugin_Changed;
}

bool:IsIncapped(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
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