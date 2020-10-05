/*
2.0 - Griffin

More or less cribbed tankdamageannounce's tank tracking, which itself is
heavily based off of ZACK/Rotoblin.  Credit to Mr Zero.

This is in response to the following L4D Nation thread:
http://www.l4dnation.com/confogl-and-other-configs/low-hanging-fruit/60/

Specifically:

> If the bot tank is kicked via sourcemod, you won't get any more
> spitters for the rest of the map.
- fig newtons

and

> If the survivors wipe and the Tank is still in play of the Infected
> (and controlled by a player) and the Tank player disconnects/types
> quit into console as the game begins to transition to the load screen
> to transition the players to the next map, the no-spitter plugin stays
> loaded in.
- 3yebex

*/

#pragma semicolon 1

#include <sourcemod>

new TEAM_INFECTED = 3;
new g_iZombieClass_Tank = 8;
new g_iSpitterLimit;
new g_iTankClient;
new bool:g_bIsTankInPlay;
new Handle:g_hSpitterLimit;

public Plugin:myinfo =
{
	name = "No Spitter During Tank",
	author = "Don, epilimic, Griffin",
	description = "Prevents the director from giving the infected team a spitter while the tank is alive",
	version = "2.0",
	url = "https://bitbucket.org/DonSanchez/random-sourcemod-stuff"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGame[12];
	GetGameFolderName(sGame, sizeof(sGame));
	if (StrEqual(sGame, "left4dead2"))	// Only load the plugin if the server is running Left 4 Dead 2.
	{
		return APLRes_Success;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports L4D2");
		return APLRes_Failure;
	}
}

public OnPluginStart()
{
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("player_death", Event_PlayerKilled);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);

	g_hSpitterLimit = FindConVar("z_versus_spitter_limit");
	HookConVarChange(g_hSpitterLimit, Cvar_SpitterLimit);

	g_iSpitterLimit = GetConVarInt(g_hSpitterLimit);
}

public Cvar_SpitterLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (g_bIsTankInPlay || StringToInt(oldValue) == 0) return;
	g_iSpitterLimit = StringToInt(newValue);
}

public OnMapStart()
{
	// In cases where a tank spawns and map is changed manually, bypassing round end
	// OR apparently there's a race condition where tank leaves near round_end; this should
	// protect from those scenarios.
	if (g_iSpitterLimit > 0 && GetConVarInt(g_hSpitterLimit) == 0)
	{
		SetConVarInt(g_hSpitterLimit, g_iSpitterLimit);
	}
}

public OnClientDisconnect_Post(client)
{
	if (!g_bIsTankInPlay || client != g_iTankClient) return;
	// Use a delayed timer due to bugs where the tank passes to another player
	CreateTimer(0.5, Timer_CheckTank, client);
}

public Event_PlayerKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bIsTankInPlay) return;

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (victim != g_iTankClient) return;

	// Use a delayed timer due to a bug where the tank passes to another player
	// (Does this happen in L4D2?)
	CreateTimer(0.5, Timer_CheckTank, victim);
}

public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iTankClient = client;

	if (g_bIsTankInPlay) return; // Tank passed

	g_bIsTankInPlay = true;
	SetConVarInt(g_hSpitterLimit, 0);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bIsTankInPlay = false;
	g_iTankClient = 0;
	if (g_iSpitterLimit > 0 && GetConVarInt(g_hSpitterLimit) == 0)
	{
		SetConVarInt(g_hSpitterLimit, g_iSpitterLimit);
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// A bit redundant to do it on both start/end, but there are cases where those events are bypassed
	// specifically by admin commands
	g_bIsTankInPlay = false;
	if (g_iSpitterLimit > 0 && GetConVarInt(g_hSpitterLimit) == 0)
	{
		SetConVarInt(g_hSpitterLimit, g_iSpitterLimit);
	}
}

public Action:Timer_CheckTank(Handle:timer, any:oldtankclient)
{
	// We already saw tank pass via another event firing
	if (g_iTankClient != oldtankclient) return;

	// Check ourselves for a tank pass
	new tankclient = FindTankClient();
	if (tankclient && tankclient != oldtankclient)
	{
		g_iTankClient = tankclient;
		return;
	}

	// Can't find tank, it's gone
	g_bIsTankInPlay = false;
	if (g_iSpitterLimit > 0 && GetConVarInt(g_hSpitterLimit) == 0)
	{
		SetConVarInt(g_hSpitterLimit, g_iSpitterLimit);
	}
}

FindTankClient()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) ||
			GetClientTeam(client) != TEAM_INFECTED ||
			!IsPlayerAlive(client) ||
			GetEntProp(client, Prop_Send, "m_zombieClass") != g_iZombieClass_Tank)
			continue;

		return client;
	}
	return 0;
}

public OnPluginEnd()
{
	if (g_iSpitterLimit > 0 && GetConVarInt(g_hSpitterLimit) == 0)
		SetConVarInt(g_hSpitterLimit, g_iSpitterLimit);
}