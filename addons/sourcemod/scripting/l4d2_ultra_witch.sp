#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <l4d2_direct>

new Handle:z_witch_damage;

new bool:lateLoad;

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax) 
{
	lateLoad = late;
	return APLRes_Success;    
}

public Plugin:myinfo =
{
	name = "L4D2 Ultra Witch",
	author = "Visor",
	description = "The Witch's hit deals a set amount of damage instead of instantly incapping, while also sending the survivor flying. Fixes convar z_witch_damage",
	version = "1.1",
	url = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
	z_witch_damage = FindConVar("z_witch_damage");

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
	if (!IsSurvivor(victim) || !IsWitch(attacker))
	{
		return Plugin_Continue;
	}
	
	if (IsIncapped(victim))
	{
		return Plugin_Continue;
	}
	
	new Float:witchDamage = GetConVarFloat(z_witch_damage);
	if (witchDamage >= (GetSurvivorPermanentHealth(victim) + GetSurvivorTemporaryHealth(victim)))
	{
		return Plugin_Continue;
	}
	
	// Replication of tank punch throw algorithm from CTankClaw::OnPlayerHit()
	new Float:victimPos[3], Float:witchPos[3], Float:throwForce[3];
	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
	GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", witchPos);

	NormalizeVector(victimPos, victimPos);
	NormalizeVector(witchPos, witchPos);
	throwForce[0] = Clamp((360000.0 * (victimPos[0] - witchPos[0])), -400.0, 400.0);
	throwForce[1] = Clamp((90000.0 * (victimPos[1] - witchPos[1])), -400.0, 400.0);
	throwForce[2] = 300.0;
	
	ApplyAbsVelocityImpulse(victim, throwForce);
	L4D2Direct_DoAnimationEvent(victim, 96);
	damage = witchDamage;
	
	return Plugin_Changed;
}

GetSurvivorTemporaryHealth(client)
{
	new temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
	return (temphp > 0 ? temphp : 0);
}

GetSurvivorPermanentHealth(client)
{
	return GetEntProp(client, Prop_Send, "m_currentReviveCount") > 0 ? 0 : (GetEntProp(client, Prop_Send, "m_iHealth") > 0 ? GetEntProp(client, Prop_Send, "m_iHealth") : 0);
}

bool:IsIncapped(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool:IsWitch(entity)
{
    if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
    {
        decl String:strClassName[64];
        GetEdictClassname(entity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "witch");
    }
    return false;
}

bool:IsSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

Float:Clamp(Float:value, Float:min, Float:max)
{
	if (value > max) return max;
	if (value < min) return min;
	return value;
}

ApplyAbsVelocityImpulse(client, const Float:impulseForce[3])
{
	static Handle:call = INVALID_HANDLE;

	if (call == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN11CBaseEntity23ApplyAbsVelocityImpulseERK6Vector", 0))
		{
			return;
		}
		
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		call = EndPrepSDKCall();
		
		if (call == INVALID_HANDLE)
		{
			return;
		}
	}

	SDKCall(call, client, impulseForce);
}