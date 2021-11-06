#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>

bool
	g_bIsEventHook;

ConVar
	g_hCvarServerMessageToggle,
	g_hCvarServerWelcomeMessage;

public Plugin myinfo =
{
	name = "sv_consistency fixes",
	author = "step, Sir, A1m`",
	description = "Fixes multiple sv_consistency issues.",
	version = "1.4.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework/"
};

public void OnPluginStart()
{
	if (!FileExists("whitelist.cfg")) {
		SetFailState("Couldn't find whitelist.cfg");
	}
	
	g_hCvarServerMessageToggle = g_hCvarServerWelcomeMessage = CreateConVar( \
		"svctyfix_message_enable", \
		"1.0", \
		"Enable print message in console when player join.", \
		_, true, 0.0, true, 1.0 \
	);
	
	g_hCvarServerWelcomeMessage = CreateConVar( \
		"svctyfix_welcome_message", \
		"a SoundM Protected Server", \
		"Message to show to Players in console" \
	);
	
	ConVar hConsistencyCheckInterval = CreateConVar( \
		"cl_consistencycheck_interval", \
		"180.0", \
		"Perform a consistency check after this amount of time (seconds) has passed since the last.", \
		FCVAR_REPLICATED \
	);
	
	ToggleMessage();
	g_hCvarServerMessageToggle.AddChangeHook(Cvar_Changed);
	
	RegAdminCmd("sm_consistencycheck", Cmd_ConsistencyCheck, ADMFLAG_RCON, "Performs a consistency check on all players.");

	hConsistencyCheckInterval.SetInt(999999);
	
	LoadTranslations("common.phrases"); // Load translations (for targeting player)
}

void ToggleMessage()
{
	if (g_hCvarServerMessageToggle.BoolValue) {
		if (!g_bIsEventHook) {
			HookEvent("player_connect_full", Event_PlayerConnectFull, EventHookMode_Post);
			g_bIsEventHook = true;
		}
	} else {
		if (g_bIsEventHook) {
			UnhookEvent("player_connect_full", Event_PlayerConnectFull, EventHookMode_Post);
			g_bIsEventHook = false;
		}
	}
}

public void Cvar_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ToggleMessage();
}

public void OnClientConnected(int client)
{
	ClientCommand(client, "cl_consistencycheck");
}

public void Event_PlayerConnectFull(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iUserId = hEvent.GetInt("userid");
	CreateTimer(0.2, PrintWhitelist, iUserId, TIMER_FLAG_NO_MAPCHANGE);
}

public Action PrintWhitelist(Handle hTimer, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	if (iClient > 0) {
		char sMessage[128];
		GetConVarString(g_hCvarServerWelcomeMessage, sMessage, sizeof(sMessage));

		PrintToConsole(iClient, " ");
		PrintToConsole(iClient, " ");
		PrintToConsole(iClient, "// -------------------------------- \\");
		PrintToConsole(iClient, "/| --> Welcome to %s <--", sMessage);
		PrintToConsole(iClient, "|");
		PrintToConsole(iClient, "| Your Sound Files have been checked.");
		PrintToConsole(iClient, "| Don't be a filthy Cheater.");
		PrintToConsole(iClient, "| Enjoy your Stay, or don't.");
		PrintToConsole(iClient, "|");
		PrintToConsole(iClient, "/| --> Welcome to %s <--", sMessage);
		PrintToConsole(iClient, "// -------------------------------- \\");
		PrintToConsole(iClient, " ");
		PrintToConsole(iClient, " ");
	}
	return Plugin_Stop;
}

public Action Cmd_ConsistencyCheck(int iClient, int iArgs)
{
	if (iArgs < 1) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
				ClientCommand(i, "cl_consistencycheck");
			}
		}
		
		ReplyToCommand(iClient, "Started checking the consistency of files for all players!");
		return Plugin_Handled;
	}

	char sArg1[MAX_NAME_LENGTH];
	GetCmdArg(1, sArg1, sizeof(sArg1));

	// Try and find a matching player
	int iTarget = FindTarget(iClient, sArg1, true);
	if (iTarget == -1) {
		return Plugin_Handled;
	}
	
	ClientCommand(iTarget, "cl_consistencycheck");

	ReplyToCommand(iClient, "Started checking the consistency of files for the player %N (%d)", iTarget, iTarget);
	
	return Plugin_Handled;
}
