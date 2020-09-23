#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

public Plugin:myinfo = 
{
	name = "Musical Jockeys",
	author = "Jacob",
	description = "Prevents the Jockey from having silent spawns.",
	version = "1.2",
	url = "Earth"
}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public OnMapStart()
{
	PrecacheSound("music/bacteria/jockeybacterias.wav");
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidPlayer(client) && GetClientTeam(client) == 3)
	{
		int zClass = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (zClass == 5) EmitSoundToAll("music/bacteria/jockeybacterias.wav", _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0);
	}
}

bool:IsValidPlayer(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	return true;
}