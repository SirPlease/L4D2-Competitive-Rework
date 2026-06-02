#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
    name = "[L4D2] Fix Rocket Pull",
    author = "Alan, Forgetest",
    description = "Fix smoker pull launching survivor up",
    version = "0.2"
};

public void OnPluginStart()
{
	HookEvent("tongue_grab", Event_TongueGrab, EventHookMode_Post);
}

void Event_TongueGrab(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (victim <= 0)
		return;

	if (GetEntityMoveType(victim) == MOVETYPE_CUSTOM)
		SetEntityMoveType(victim, MOVETYPE_WALK);
}