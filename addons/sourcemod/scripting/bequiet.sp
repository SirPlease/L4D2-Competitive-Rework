#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <sourcemod>

enum
{
	//	L4D_TEAM_UNASSIGNED			= 0,
	L4D_TEAM_SPECTATOR = 1,
	L4D_TEAM_SURVIVOR  = 2,
	L4D_TEAM_INFECTED  = 3,
	//	L4D_TEAM_FOUR				= 4
}

ConVar
	hCvarCvarChange,
	hCvarNameChange,
	hCvarSpecNameChange,
	hCvarSpecSeeChat;
bool
	bCvarChange,
	bNameChange,
	bSpecNameChange,
	bSpecSeeChat;

public Plugin myinfo =
{
	name        = "BeQuiet",
	author      = "Sir",
	description = "Please be Quiet!",
	version     = "1.33.8",
	url         = "https://github.com/SirPlease/SirCoding"


}

public void OnPluginStart()
{
	LoadTranslations("bequiet.phrases");
	AddCommandListener(Say_Callback, "say");
	AddCommandListener(TeamSay_Callback, "say_team");

	// Server CVar
	HookEvent("server_cvar", Event_ServerConVar, EventHookMode_Pre);
	HookEvent("player_changename", Event_NameChange, EventHookMode_Pre);

	// Cvars
	hCvarCvarChange     = CreateConVar("bq_cvar_change_suppress", "1", "Silence Server Cvars being changed, this makes for a clean chat with no disturbances.");
	hCvarNameChange     = CreateConVar("bq_name_change_suppress", "1", "Silence Player name Changes.");
	hCvarSpecNameChange = CreateConVar("bq_name_change_spec_suppress", "1", "Silence Spectating Player name Changes.");
	hCvarSpecSeeChat    = CreateConVar("bq_show_player_team_chat_spec", "1", "Show Spectators Team chat?");

	bCvarChange     = GetConVarBool(hCvarCvarChange);
	bNameChange     = GetConVarBool(hCvarNameChange);
	bSpecNameChange = GetConVarBool(hCvarSpecNameChange);
	bSpecSeeChat    = GetConVarBool(hCvarSpecSeeChat);

	hCvarCvarChange.AddChangeHook(cvarChanged);
	hCvarNameChange.AddChangeHook(cvarChanged);
	hCvarSpecNameChange.AddChangeHook(cvarChanged);
	hCvarSpecSeeChat.AddChangeHook(cvarChanged);

	AutoExecConfig(true, "bequiet");
}

public Action Say_Callback(int client, char[] command, int args)
{
	char sayWord[MAX_NAME_LENGTH];
	GetCmdArg(1, sayWord, sizeof(sayWord));

	if (sayWord[0] == '!' || sayWord[0] == '/')
	{
		return Plugin_Handled;
	}

	if (IsClientSourceTV(client))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action TeamSay_Callback(int client, char[] command, int args)
{
	char sayWord[MAX_NAME_LENGTH];
	GetCmdArg(1, sayWord, sizeof(sayWord));

	if (sayWord[0] == '!' || sayWord[0] == '/')
	{
		return Plugin_Handled;
	}

	if (bSpecSeeChat)
	{
		char sChat[256];
		GetCmdArgString(sChat, 256);
		StripQuotes(sChat);
		int ClientTeam = GetClientTeam(client);

		if (ClientTeam != L4D_TEAM_SPECTATOR)
		{
			for (int ClientIndex = 1; ClientIndex <= MaxClients; ClientIndex++)
			{
				if (IsValidClient(ClientIndex) && GetClientTeam(ClientIndex) == L4D_TEAM_SPECTATOR && !IsClientSourceTV(ClientIndex))    // TeamChat for Spect
				{
					switch (ClientTeam)
					{
						case L4D_TEAM_SURVIVOR:
							CPrintToChat(ClientIndex, "%t", "Survivor", client, sChat);
						case L4D_TEAM_INFECTED:
							CPrintToChat(ClientIndex, "%t", "Infected", client, sChat);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_ServerConVar(Event event, const char[] name, bool dontBroadcast)
{
	if (bCvarChange) return Plugin_Handled;
	return Plugin_Continue;
}

public Action Event_NameChange(Event event, const char[] name, bool dontBroadcast)
{
	int clientid = event.GetInt("userid");
	int client   = GetClientOfUserId(clientid);
	if (IsValidClient(client))
	{
		if (bSpecNameChange && GetClientTeam(client) == L4D_TEAM_SPECTATOR)
		{
			return Plugin_Handled;
		}
		else if (bNameChange)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void cvarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	bCvarChange     = hCvarCvarChange.BoolValue;
	bNameChange     = hCvarNameChange.BoolValue;
	bSpecNameChange = hCvarSpecNameChange.BoolValue;
	bSpecSeeChat    = hCvarSpecSeeChat.BoolValue;
}

stock bool IsValidClient(int client)
{
	if ((client > 0 && client <= MaxClients) && IsClientInGame(client) && IsClientConnected(client))
	{
		return true;
	}
	return false;
}