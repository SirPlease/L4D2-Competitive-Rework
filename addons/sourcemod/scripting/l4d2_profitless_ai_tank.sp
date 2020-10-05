#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new lastHumanTank = -1;

public Plugin:myinfo =
{
	name = "L4D2 Profitless AI Tank",
	author = "Visor",
	description = "Passing control to AI Tank will no longer be rewarded with an instant respawn",
	version = "0.3",
	url = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
	HookEvent("tank_frustrated", OnTankFrustrated, EventHookMode_Post);
}

public OnTankFrustrated(Handle:event, const String:name[], bool:dontBroadcast)
{
	new tank = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsFakeClient(tank))
	{
		lastHumanTank = tank;
		CreateTimer(0.1, CheckForAITank, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:CheckForAITank(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsTank(i) && IsFakeClient(i))
		{
			if (IsInfected(lastHumanTank))
			{
				ForcePlayerSuicide(lastHumanTank);
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

bool:IsTank(client)
{
	return (IsInfected(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

bool:IsInfected(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3);
}