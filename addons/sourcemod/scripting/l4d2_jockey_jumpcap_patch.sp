#pragma semicolon 1

#include <sourcemod>
#include <dhooks>

#define CLEAP_ONTOUCH_OFFSET    216

new Handle:hCLeap_OnTouch;

new bool:blockJumpCap[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "L4D2 Jockey Jump-Cap Patch",
	author = "Visor",
	description = "Prevent Jockeys from being able to land caps with non-ability jumps in unfair situations",
	version = "1.2.1",
	url = "https://github.com/Attano/L4D2-Competitive-Framework"
};

public OnPluginStart()
{
	hCLeap_OnTouch = DHookCreate(CLEAP_ONTOUCH_OFFSET, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CLeap_OnTouch);
	DHookAddParam(hCLeap_OnTouch, HookParamType_CBaseEntity);
	
	HookEvent("round_start", EventHook:RoundStartEvent, EventHookMode_PostNoCopy);
	HookEvent("player_shoved", OnPlayerShoved);
}

public RoundStartEvent()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		blockJumpCap[i] = false;
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "ability_leap"))
	{
		DHookEntity(hCLeap_OnTouch, false, entity); 
	}
}

public Action:OnPlayerShoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	new shovee = GetClientOfUserId(GetEventInt(event, "userid"));
	new shover = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (IsSurvivor(shover) && IsJockey(shovee))
	{
		blockJumpCap[shovee] = true;
		CreateTimer(3.0, ResetJumpcapState, shovee, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:ResetJumpcapState(Handle:timer, any:jockey)
{
	blockJumpCap[jockey] = false;
	return Plugin_Handled;
}

public MRESReturn:CLeap_OnTouch(ability, Handle:hParams)
{
	new jockey = GetEntPropEnt(ability, Prop_Send, "m_owner");
	new survivor = DHookGetParam(hParams, 1);
	if (IsJockey(jockey) && !IsFakeClient(jockey) && IsSurvivor(survivor))
	{
		if (!IsAbilityActive(ability) && blockJumpCap[jockey])
		{
			return MRES_Supercede;
		}
	}
	return MRES_Ignored;
}

bool:IsAbilityActive(ability)
{
	return bool:GetEntData(ability, 1148);
}

bool:IsJockey(client)
{
	return (client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client) 
		&& GetClientTeam(client) == 3 
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == 5);
}

bool:IsSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}