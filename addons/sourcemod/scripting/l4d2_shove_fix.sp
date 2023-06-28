#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <actions>

public Plugin myinfo =
{
	name   = "[L4D2] Shove Direction Fix",
	author = "BHaType"
};

public void OnActionCreated(BehaviorAction action, int owner, const char[] name)
{
	if (strcmp(name, "InfectedShoved") == 0)
		action.OnShoved = OnShoved;
}

public Action OnShoved(BehaviorAction action, int actor, int shover, ActionDesiredResult result)
{
	return Plugin_Handled;
}