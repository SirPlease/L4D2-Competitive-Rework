#include <sourcemod>
#include <dhooks>

#define CLEAP_ONTOUCH_OFFSET    216

new Handle:hCLeap_OnTouch;

public Plugin:myinfo =
{
	name = "L4D2 Jockeyed Charger Fix",
	author = "Visor",
	description = "Prevent jockeys and chargers from capping the same target simultaneously",
	version = "1.3",
	url = "https://github.com/Attano/smplugins"
}

public OnPluginStart()
{
	hCLeap_OnTouch = DHookCreate(CLEAP_ONTOUCH_OFFSET, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CLeap_OnTouch);
	DHookAddParam(hCLeap_OnTouch, HookParamType_CBaseEntity);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "ability_leap"))
	{
		DHookEntity(hCLeap_OnTouch, false, entity); 
	}
}

public MRESReturn:CLeap_OnTouch(ability, Handle:hParams)
{
	new jockey = GetEntPropEnt(ability, Prop_Send, "m_owner");
	new survivor = DHookGetParam(hParams, 1);
	if (IsValidJockey(jockey)/* probably redundant */ && IsSurvivor(survivor))
	{
		if (IsValidCharger(GetCarrier(survivor)) || IsValidCharger(GetPummelQueueAttacker(survivor)) || IsValidCharger(GetPummelAttacker(survivor)))
		{
			return MRES_Supercede;
		}
	}
	return MRES_Ignored;
}

bool:IsSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

bool:IsValidJockey(client)
{
	return (client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client) 
		&& GetClientTeam(client) == 3 
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == 5);
}

bool:IsValidCharger(client)
{
	return (client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client) 
		&& GetClientTeam(client) == 3 
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == 6);
}

GetCarrier(survivor)
{
	return GetEntDataEnt2(survivor, 10860);
}

GetPummelQueueAttacker(survivor)
{
	return GetEntDataEnt2(survivor, 15988);
}

GetPummelAttacker(survivor)
{
	return GetEntDataEnt2(survivor, 15976);
}