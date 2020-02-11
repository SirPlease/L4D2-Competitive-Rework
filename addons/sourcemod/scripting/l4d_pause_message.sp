#pragma newdecls required

#include <sourcemod>

ConVar hPauseCvar;
bool bPausable;

public Plugin myinfo =
{
	name = "Block Pause/Unpause Spam in Console ",
	author = "Sir (Simplified version of Silver's)",
	description = "Simply block pause commands when the server doesn't even support pausing.",
	version = "1.0",
	url = "Nah."
}

public void OnPluginStart()
{
	hPauseCvar = FindConVar("sv_pausable");
	bPausable = hPauseCvar.BoolValue;
	hPauseCvar.AddChangeHook(PauseChange);

	AddCommandListener(pauseCmd, "pause");
	AddCommandListener(pauseCmd, "setpause");
	AddCommandListener(pauseCmd, "unpause");
}

public Action pauseCmd(int client, const char[] command, int argc) 
{
	if (!bPausable) return Plugin_Handled;
	return Plugin_Continue;
}

public void PauseChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	int Value = StringToInt(newValue);

	switch(Value)
	{
		case 0: bPausable = false;
		default: bPausable = true;
	}
}