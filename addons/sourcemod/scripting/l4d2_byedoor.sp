#pragma semicolon 1
#pragma newdecls required;

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "Byebye Door",
	description = "Time to kill Saferoom Doors.",
	author = "Sir", //update syntax, little fix A1m`
	version = "1.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void Event_RoundStart(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int EntityCount = GetEntityCount();
	char EdictClassName[128];
	for (int i = 0; i <= EntityCount; i++){
		if (IsValidEntity(i)) {
			GetEdictClassname(i, EdictClassName, 128);
			if (StrContains(EdictClassName, "prop_door_rotating_checkpoint", false) != -1 
					&& GetEntProp(i, Prop_Send, "m_bLocked", 4) == 1) {
				AcceptEntityInput(i, "Kill", -1, -1, 0);
				return;
			}
		}
	}
}
