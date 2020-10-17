#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "L4D2 Finale Incap Distance Fixifier",
	author = "CanadaRox",
	description = "Kills survivors before the score is calculated so you don't get full distance if you are incapped as the rescue vehicle leaves.",
	version = "1.0.1",
	url = "https://bitbucket.org/CanadaRox/random-sourcemod-stuff"
};

public OnPluginStart()
{
	HookEvent("finale_vehicle_leaving", FinaleEnd_Event, EventHookMode_PostNoCopy);
}

public FinaleEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerIncap(i))
		{
			ForcePlayerSuicide(i);
		}
	}
}

stock IsPlayerIncap(client) return GetEntProp(client, Prop_Send, "m_isIncapacitated");