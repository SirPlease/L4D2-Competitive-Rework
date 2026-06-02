#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <readyup>

#define MAX_TEXT_LENGTH 65
#define MAX_STRING_COUNT 10

char g_sPanelText[MAX_STRING_COUNT][MAX_TEXT_LENGTH];

int g_iStringCount = 0;

bool g_bAreStringsLocked = false;

ConVar g_hCvarReadyPanelTextDelay = null;

public Plugin myinfo =
{
	name = "Add Text To Readyup Panel",
	author = "epilimic",
	description = "Displays custom text in the readyup panel. Spanks for the help CanadaRox!",
	version = "1.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework/"
};

public void OnPluginStart()
{
	g_hCvarReadyPanelTextDelay = CreateConVar("sm_readypaneltextdelay", "4.0", "Delay before adding the text to the ready-up panel for order control", _, true, 0.0, true, 10.0);

	RegServerCmd("sm_addreadystring", Cmd_AddReadyString, "Sets the string to add to the ready-up panel");
	RegServerCmd("sm_resetstringcount", Cmd_ResetStringCount, "Resets the string count");
	RegServerCmd("sm_lockstrings", Cmd_LockStrings, "Locks the strings");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

Action Cmd_LockStrings(int iArgs)
{
	g_bAreStringsLocked = true;
	return Plugin_Handled;
}

Action Cmd_AddReadyString(int iArgs)
{
	if (g_iStringCount < MAX_STRING_COUNT && !g_bAreStringsLocked) {
		GetCmdArg(1, g_sPanelText[g_iStringCount], MAX_TEXT_LENGTH);

		++g_iStringCount;
	}

	return Plugin_Handled;
}

Action Cmd_ResetStringCount(int iArgs)
{
	g_iStringCount = 0;
	g_bAreStringsLocked = false;

	return Plugin_Handled;
}

void Event_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	float fTime = g_hCvarReadyPanelTextDelay.FloatValue;
	CreateTimer(fTime, panelTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action panelTimer(Handle hTimer)
{
	for (int i = 0; i < g_iStringCount; i++) {
		if (!AddStringToReadyFooter(g_sPanelText[i])) {
			break;
		}
	}

	return Plugin_Stop;
}
