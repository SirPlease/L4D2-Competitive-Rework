#include <sourcemod>

public Plugin:myinfo =
{
	name = "Hittable Temp Health Fixer",
	author = "CanadaRox",
	description = "Ensures that survivors that have been incapacitated with a hittable object get their temp health set correctly",
	version = "13.3.7",
	url = "https://bitbucket.org/CanadaRox/random-sourcemod-stuff/"
};

public OnPluginStart() HookEvent("player_incapacitated_start", Incap_Event);

public Incap_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
}