#include <sourcemod>
#include <left4dhooks>

new Float:origin[3];
new Float:angles[3];

public Plugin:myinfo =
{
	name = "L4D2 Witch Restore",
	author = "Visor",
	description = "Witch is restored at the same spot if she gets killed by a Tank.",
	version = "1.0",
	url = "https://github.com/Attano/smplugins"
};

public OnPluginStart()
{
	HookEvent("witch_killed", OnWitchKilled, EventHookMode_Pre);
}

public Action:OnWitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new witch = GetEventInt(event, "witchid");
	if (IsValidTank(client))
	{
		GetEntPropVector(witch, Prop_Send, "m_vecOrigin", origin);
		GetEntPropVector(witch, Prop_Send, "m_angRotation", angles);
		CreateTimer(3.0, RestoreWitch, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:RestoreWitch(Handle:timer)
{
	L4D2_SpawnWitch(origin, angles);
}

bool:IsValidTank(client)
{
	return (client > 0
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& GetClientTeam(client) == 3
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}