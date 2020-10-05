#pragma semicolon 1

#include <sourcemod>

new Handle:tongue_drag_damage_interval;

public Plugin:myinfo =
{
	name = "L4D2 Smoker Drag Damage Interval",
	author = "Visor",
	description = "Implements a native-like cvar that should've been there out of the box",
	version = "0.6",
	url = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
	HookEvent("tongue_grab", OnTongueGrab);

	new String:value[32];
	GetConVarString(FindConVar("tongue_choke_damage_interval"), value, sizeof(value));
	tongue_drag_damage_interval = CreateConVar("tongue_drag_damage_interval", value, "How often the drag does damage.");
	
	HookConVarChange(FindConVar("tongue_choke_damage_amount"), tongue_choke_damage_amount_ValueChanged);
}

public tongue_choke_damage_amount_ValueChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarInt(convar, 1); // hack-hack: game tries to change this cvar for some reason, can't be arsed so HARDCODETHATSHIT
}

public OnTongueGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	
	UpdateDragDamageInterval(client);
	
	CreateTimer(
			GetConVarFloat(tongue_drag_damage_interval) + 0.1, 
			FixDragInterval, 
			client, 
			TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE
	);
}

public Action:FixDragInterval(Handle:timer, any:client)
{
	if (!IsSurvivor(client) || !IsSurvivorBeingDragged(client))
	{
		return Plugin_Stop;
	}

	UpdateDragDamageInterval(client);
	return Plugin_Continue;
}

UpdateDragDamageInterval(client)
{
	SetEntDataFloat(client, 13352, (GetGameTime() + GetConVarFloat(tongue_drag_damage_interval)));
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