#include <sourcemod>

public Plugin myinfo =
{
	name = "[L4D2] Client IP Protector [2024]",
	author = "backwards",
	description = "Prevents clients with hacks from obtaining other players IP Addresses.",
	version = "1.0"
};

public void OnPluginStart()
{
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
}

Action Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
    event.BroadcastDisabled = true;
    return Plugin_Continue;
}