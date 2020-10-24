#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <colors>

new Handle:tongue_drag_damage_interval;
new Handle:tongue_drag_first_damage_interval;
new Handle:tongue_drag_first_damage;

public Plugin:myinfo =
{
	name = "L4D2 Smoker Drag Damage Interval",
	author = "Visor, Sir",
	description = "Implements a native-like cvar that should've been there out of the box",
	version = "0.7",
	url = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
	HookEvent("tongue_grab", OnTongueGrab);

	new String:value[32];
	GetConVarString(FindConVar("tongue_choke_damage_interval"), value, sizeof(value));
	tongue_drag_damage_interval = CreateConVar("tongue_drag_damage_interval", value, "How often the drag does damage.");
	tongue_drag_first_damage_interval = CreateConVar("tongue_drag_first_damage_interval", "0.0", "After how many seconds do we apply our first tick of damage? | 0.0 to Disable.");
	tongue_drag_first_damage = CreateConVar("tongue_drag_first_damage", "3.0", "How much damage do we apply on the first tongue hit? | Only applies when first_damage_interval is used");

	HookConVarChange(FindConVar("tongue_choke_damage_amount"), tongue_choke_damage_amount_ValueChanged);
}

public tongue_choke_damage_amount_ValueChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarInt(convar, 1); // hack-hack: game tries to change this cvar for some reason, can't be arsed so HARDCODETHATSHIT
}

public OnTongueGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	new Float:fFirst = GetConVarFloat(tongue_drag_first_damage_interval);

	if (fFirst > 0.0)
	{
		UpdateDragDamageInterval(client, tongue_drag_first_damage_interval);
		CreateTimer(fFirst, FirstDamage, client);
	}
	else
	{
		UpdateDragDamageInterval(client, tongue_drag_damage_interval);
		
		CreateTimer(
				GetConVarFloat(tongue_drag_damage_interval) + 0.1, 
				FixDragInterval, 
				client, 
				TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE
		);
	}
}

public Action:FirstDamage(Handle:timer, any:client)
{
	if (!IsSurvivor(client) || !IsSurvivorBeingDragged(client))
	{
		return Plugin_Stop;
	}

	for (new i = 1; i < MaxClients + 1; i++)
	{
		if (IsTongue(i))
		{
			SDKHooks_TakeDamage(client, i, i, GetConVarFloat(tongue_drag_first_damage) - 1.0);
			break;
		}
	}

	UpdateDragDamageInterval(client, tongue_drag_damage_interval);
	return Plugin_Continue;
}

public Action:FixDragInterval(Handle:timer, any:client)
{
	if (!IsSurvivor(client) || !IsSurvivorBeingDragged(client))
	{
		return Plugin_Stop;
	}

	UpdateDragDamageInterval(client, tongue_drag_damage_interval);
	return Plugin_Continue;
}

UpdateDragDamageInterval(client, Handle:convar)
{
	SetEntDataFloat(client, 13352, (GetGameTime() + GetConVarFloat(convar)));
}

bool:IsSurvivorBeingDragged(client)
{
	return ((GetEntData(client, 13284) > 0) && !IsSurvivorBeingChoked(client));
}

bool:IsSurvivorBeingChoked(client)
{
	return (GetEntData(client, 13308) > 0);
}

bool:IsSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

bool:IsTongue(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetEntPropEnt(client, Prop_Send, "m_tongueVictim") > 0);
}