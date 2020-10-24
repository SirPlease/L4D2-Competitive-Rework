#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Byebye Door",
	description = "Time to kill Saferoom Doors.",
	author = "Sir",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

public Action:Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	new EntityCount = GetEntityCount();
	new String:EdictClassName[128];
	for (new i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, 128);
			if (StrContains(EdictClassName, "prop_door_rotating_checkpoint", false) != -1 && GetEntProp(i, Prop_Send, "m_bLocked", 4) == 1)
			{
				AcceptEntityInput(i, "Kill", -1, -1, 0);
				return Plugin_Continue;
			}
		}
	}
}

