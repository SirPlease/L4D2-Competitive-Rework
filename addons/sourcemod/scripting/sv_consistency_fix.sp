#pragma semicolon 1
#include <sourcemod>
#include <colors>

#define PLUGIN_VERSION "1.3"
#define PLUGIN_URL "http://step.l4dnation.com/"

//Convars
new Handle:hCvarServerMessage;

#define LINE_SIZE 512

public Plugin:myinfo =
{
	name = "sv_consistency fixes",
	author = "step, Sir",
	description = "Fixes multiple sv_consistency issues.",
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart()
{
	if (!FileExists("whitelist.cfg"))
	{
		SetFailState("Couldn't find whitelist.cfg");
	}
	
	hCvarServerMessage = CreateConVar("soundm_server_message", "a SoundM Protected Server", "Message to show to Players in console");

	HookEvent("player_connect_full", Event_PlayerConnectFull, EventHookMode_Post);
	RegAdminCmd("sm_consistencycheck", Command_ConsistencyCheck, ADMFLAG_RCON, "Performs a consistency check on all players.", "", FCVAR_NONE);
	SetConVarInt(CreateConVar("cl_consistencycheck_interval", "180.0", "Perform a consistency check after this amount of time (seconds) has passed since the last.", FCVAR_REPLICATED), 999999);
}

public Action:Event_PlayerConnectFull(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, PrintWhitelist, GetClientOfUserId(GetEventInt(event, "userid")));
	return Plugin_Continue;
}

public Action:PrintWhitelist(Handle:timer, any:client)
{
	new String:sMessage[128];
	GetConVarString(hCvarServerMessage, sMessage, sizeof(sMessage));

	PrintToConsole(client, " ");
	PrintToConsole(client, " ");
	PrintToConsole(client, "// -------------------------------- \\");
	PrintToConsole(client, "/| --> Welcome to %s <--", sMessage);
	PrintToConsole(client, "|");
	PrintToConsole(client, "| Your Sound Files have been checked.");
	PrintToConsole(client, "| Don't be a filthy Cheater.");
	PrintToConsole(client, "| Enjoy your Stay, or don't.");
	PrintToConsole(client, "|");
	PrintToConsole(client, "/| --> Welcome to %s <--", sMessage);
	PrintToConsole(client, "// -------------------------------- \\");
	PrintToConsole(client, " ");
	PrintToConsole(client, " ");
}

public Action:Command_ConsistencyCheck(client, args)
{
	if (args < 1) 
	{
		ConsistencyCheck(0);
		return Plugin_Handled;
	}

	new String:sPlayer[32];
	GetCmdArg(1, sPlayer, sizeof(sPlayer));

	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientConnected(i)) continue;
		new String:sOther[32];
		GetClientName(i, sOther, sizeof(sOther));

		if (StrEqual(sPlayer, sOther, false)) ConsistencyCheck(i);
	}
	return Plugin_Handled;
}

public ConsistencyCheck(client)
{
	if (!client)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				ClientCommand(i, "cl_consistencycheck");
			}
		}
		return;
	}

	ClientCommand(client, "cl_consistencycheck");
}

public OnClientConnected(client)
{
	ClientCommand(client, "cl_consistencycheck");
}