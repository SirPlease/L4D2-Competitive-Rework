#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
	name = "L4D2 Floating Smoker Target",
	author = "SilverShot",
	description = "Fixes smoker pulls causing targets to float if they weren't touching the ground while being pulled.",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=318959"
}

public void OnPluginStart()
{
	HookEvent("tongue_grab", Event_GrabStart);
}

public void Event_GrabStart(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("victim");
	int client = GetClientOfUserId(userid);
	if( client && IsClientInGame(client) )
	{
		// Fix floating bug
		if( GetEntityFlags(client) & FL_ONGROUND == 0 )
			SetEntityMoveType(client, MOVETYPE_WALK);
	}
}