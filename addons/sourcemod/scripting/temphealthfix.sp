#pragma newdecls required

#include <sourcemod>

float fTemp[MAXPLAYERS + 1][2]

public Plugin myinfo =
{
	name = "Temp Health Fixer",
	author = "CanadaRox, Sir",
	description = "Ensures that survivors that have been incapacitated with a hittable or ledged get their temp health set correctly",
	version = "2.0",
	url = "https://bitbucket.org/CanadaRox/random-sourcemod-stuff/"
};

public void OnPluginStart() 
{
	// Important Stuff
	HookEvent("player_incapacitated_start", Incap_Event);
	HookEvent("player_ledge_grab", Incap_Event);
	HookEvent("revive_success", Revive_Event);

	// Security (:
	HookEvent("player_bot_replace", PlayerChange_Event);
	HookEvent("bot_player_replace", PlayerChange_Event);
}

public Action Incap_Event(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	// Limited to ledge grab event.
	if (StrEqual(name, "player_ledge_grab"))
	{
		// Store healthBuffer information.
		fTemp[client][0] = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
		fTemp[client][1] = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	}

	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
}

public Action Revive_Event(Event event, const char[] name, bool dontBroadcast)
{
	if (event.GetBool("ledge_hang"))
	{
		int client = GetClientOfUserId(event.GetInt("subject"));

		// Set healthBuffer information.
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fTemp[client][0]);
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fTemp[client][1]);
	}
}

public Action PlayerChange_Event(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"))
	int player = GetClientOfUserId(event.GetInt("player"))

	if (!isLedged(bot) 
	&& !isLedged(player))
		return;

	// Player replaced by bot
	if (StrContains(name, "p") == 0)
	{
		fTemp[bot][0] = fTemp[player][0];
		fTemp[bot][1] = fTemp[player][1];
	}
	// Bot replaced by player
	else
	{
		fTemp[player][0] = fTemp[bot][0];
		fTemp[player][1] = fTemp[bot][1];
	}
}

bool isLedged(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge"));
}