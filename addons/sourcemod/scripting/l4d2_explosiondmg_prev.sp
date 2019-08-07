#include <sourcemod>
#include <sdkhooks>

new bool:bLateLoad;

public Plugin:myinfo =
{
	name = "L4D2 Explosion Damage Prevention",
	author = "Sir",
	version = "1.0",
	description = "No more explosion damage from attacker (world)",
	url = ""
};

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax) 
{
	bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	if (bLateLoad) 
	{
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (!IsClientInGame(i))
				continue;

			OnClientPutInServer(i);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	// Is the Victim an infected molested by Explosive damage caused by a non-client?
	if (!IsInfected(victim) || IsValidClient(attacker) || !(damagetype & DMG_BLAST)) return Plugin_Continue;
	return Plugin_Handled;
}

bool:IsInfected(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}

bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return (IsClientInGame(client));
}