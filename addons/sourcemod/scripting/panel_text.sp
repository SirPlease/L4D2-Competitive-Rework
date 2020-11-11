#pragma semicolon 1

#include <sourcemod>
#include <readyup>
#define PLUGIN_VERSION "1 point 1"
#define MAX_TEXT_LENGTH 65

public Plugin:myinfo =
{
	name = "Add Text To Readyup Panel",
	author = "epilimic",
	description = "Displays custom text in the readyup panel. Spanks for the help CanadaRox!",
	version = PLUGIN_VERSION,
	url = "http://buttsecs.org"
};

new String:panelText[10][MAX_TEXT_LENGTH];
new stringCount = 0;
new bool:areStringsLocked;
new Handle:sm_readypaneltextdelay;

public OnPluginStart()
{
	RegServerCmd("sm_addreadystring", AddReadyString_Cmd, "Sets the string to add to the ready-up panel", FCVAR_NONE);
	RegServerCmd("sm_resetstringcount", ResetStringCount_Cmd, "Resets the string count", FCVAR_NONE);
	RegServerCmd("sm_lockstrings", LockStrings_Cmd, "Locks the strings", FCVAR_NONE);
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
	sm_readypaneltextdelay = CreateConVar("sm_readypaneltextdelay", "4.0", "Delay before adding the text to the ready-up panel for order control", FCVAR_NONE, true, 0.0, true, 10.0);
}

public Action:LockStrings_Cmd(args)
{
	areStringsLocked = true;
	return Plugin_Handled;
}

public Action:AddReadyString_Cmd(args)
{
	if (stringCount < 10 && !areStringsLocked)
	{
		GetCmdArg(1, panelText[stringCount], MAX_TEXT_LENGTH);
		++stringCount;
	}
	return Plugin_Handled;
}

public Action:ResetStringCount_Cmd(args)
{
	stringCount = 0;
	areStringsLocked = false;
	return Plugin_Handled;
}

public RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(GetConVarFloat(sm_readypaneltextdelay), panelTimer);
}

public Action:panelTimer(Handle:timer)
{
	for (new i = 0; i < stringCount && AddStringToReadyFooter(panelText[i]); i++)
	{ }
}
