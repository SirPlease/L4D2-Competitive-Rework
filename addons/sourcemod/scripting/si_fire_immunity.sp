#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:infected_fire_immunity;
new bool:inWait[MAXPLAYERS + 1] = false;

public Plugin:myinfo = 
{
    name = "SI Fire Immunity",
    author = "Jacob",
    description = "Special Infected fire damage management.",
    version = "2.0",
    url = "github.com/jacob404/myplugins"
}

public OnPluginStart()
{
	infected_fire_immunity = CreateConVar("infected_fire_immunity", "0", "What type of fire immunity should infected have? 0 = None, 3 = Extinguish burns, 2 = Prevent burns, 1 = Complete immunity", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	HookEvent("player_hurt",SIOnFire);
}

public OnMapStart()
{
	for(new i = 1; i < MaxClients+1; i++)
	{
		inWait[i] = false;
	}
}

public Action:SIOnFire(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(IsValidClient(client) && (GetClientTeam(client) == 3) && GetEventInt(event,"type") == 8)
	{
		if(GetEntProp(client, Prop_Send, "m_zombieClass") == 8) ExtinguishEntity(client);

		if(GetConVarInt(infected_fire_immunity) == 3) CreateTimer(1.0, Extinguish, client);

		if(GetConVarInt(infected_fire_immunity) <= 2) ExtinguishEntity(client);
		
		if(GetConVarInt(infected_fire_immunity) == 1)
		{
			new CurHealth = GetClientHealth(client);
			new DmgDone	= GetEventInt(event,"dmg_health");
			SetEntityHealth(client,(CurHealth + DmgDone));
		}
	}
}
 
public Action:Extinguish(Handle:timer, any:client)
{
    if(!inWait[client])
    {
        ExtinguishEntity(client);
        inWait[client] = true;
        CreateTimer(0.9, ExtinguishWait, client);
    }
}

public Action:ExtinguishWait(Handle:timer, any:client)
{
   inWait[client] = false;
}

stock bool:IsValidClient(client, bool:nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    {
        return false; 
    }
    return IsClientInGame(client); 
}  