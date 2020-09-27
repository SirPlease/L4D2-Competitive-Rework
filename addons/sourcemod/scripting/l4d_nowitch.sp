#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "No Witch",
	author = "Sir",
	description = "Slays any Witch that spwns",
	version = "1",
	url = "Nuh-uh"
}

public OnPluginStart()
{
	HookEvent("witch_spawn", WitchSpawn);
}

public WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iEnt = GetEventInt(event, "witchid");
	if (IsValidEntity(iEnt))
	{
		AcceptEntityInput(iEnt, "Kill" );
	}
}
