#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "No Tank",
	author = "Don",
	description = "Slays any tanks that spawn. Designed for 1v1 configs",
	version = "1.1",
	url = "https://bitbucket.org/DonSanchez/random-sourcemod-stuff"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGame[12];
	GetGameFolderName(sGame, sizeof(sGame));
	if (StrEqual(sGame, "left4dead") || StrEqual(sGame, "left4dead2"))	// Only load the plugin if the server is running Left 4 Dead or Left 4 Dead 2.
	{
		return APLRes_Success;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports L4D1/2");
		return APLRes_Failure;
	}
}

new iSpawned;

public OnPluginStart()
{
	HookEvent("tank_spawn", Event_tank_spawn_Callback);
}

public Event_tank_spawn_Callback(Handle:event, const String:name[], bool:dontBroadcast)
{
	iSpawned = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInGame(iSpawned) && IsPlayerAlive(iSpawned))
	{
		CreateTimer(1.0, SlayTank);	// Slaying or kicking tanks instantly would break finale maps.
	}
}

public Action:SlayTank(Handle:timer)
{
	ForcePlayerSuicide(iSpawned);
}
