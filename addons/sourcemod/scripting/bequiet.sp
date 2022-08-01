#pragma semicolon 1

#pragma newdecls required
#include <colors>
#include <l4d2util>
#include <left4dhooks>
#include <sourcemod>

ConVar
	hCvarCvarChange,
	hCvarNameChange,
	hCvarSpecNameChange,
	hCvarSpecSeeChat,
	hCvarSTVSeeChat,
	hCvarSTVSeeTChat;
bool
	bCvarChange,
	bNameChange,
	bSpecNameChange,
	bSpecSeeChat,
	bCvarSTVSeeChat,
	bCvarSTVSeeTChat;

public Plugin myinfo =
{
	name        = "BeQuiet",
	author      = "Sir",
	description = "Please be Quiet!",
	version     = "1.4",
	url         = "https://github.com/SirPlease/SirCoding"

}

public void OnPluginStart()
{
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
	hCvarSTVSeeChat     = CreateConVar("bq_show_player_chat_stv", "0", "Show SourceTV General chat?");
	hCvarSTVSeeTChat    = CreateConVar("bq_show_player_team_chat_stv", "0", "Show SourceTV Team chat?");

	bCvarChange      = GetConVarBool(hCvarCvarChange);
	bNameChange      = GetConVarBool(hCvarNameChange);
	bSpecNameChange  = GetConVarBool(hCvarSpecNameChange);
	bSpecSeeChat     = GetConVarBool(hCvarSpecSeeChat);
	bCvarSTVSeeChat  = GetConVarBool(hCvarSTVSeeChat);
	bCvarSTVSeeTChat = GetConVarBool(hCvarSTVSeeTChat);

	hCvarCvarChange.AddChangeHook(cvarChanged);
	hCvarNameChange.AddChangeHook(cvarChanged);
	hCvarSpecNameChange.AddChangeHook(cvarChanged);
	hCvarSpecSeeChat.AddChangeHook(cvarChanged);
	hCvarSTVSeeChat.AddChangeHook(cvarChanged);
	hCvarSTVSeeTChat.AddChangeHook(cvarChanged);

	AutoExecConfig(true, "bequiet");
}

public Action Say_Callback(int client, char[] command, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	char sayWord[MAX_NAME_LENGTH];
	GetCmdArg(1, sayWord, sizeof(sayWord));

	if (sayWord[0] == '!' || sayWord[0] == '/')
	{
		return Plugin_Handled;
	}

	if (bCvarSTVSeeChat)
	{
		char sChat[256];
		GetCmdArgString(sChat, 256);
		StripQuotes(sChat);
		int ClientTeam = GetClientTeam(client);
		int i = 1;
		while (i <= MaxClients)
		{
			if (IsValidClient(i) && IsClientSourceTV(i))    // Chat from STV
			{
				switch (ClientTeam)
				{
					case L4D_TEAM_SPECTATOR:
						CPrintToChat(i, "{default}*SPEC* %N : %s", client, sChat);
					case L4D_TEAM_SURVIVOR:
						CPrintToChat(i, "{blue}%N {default}: %s", client, sChat);
					case L4D_TEAM_INFECTED:
						CPrintToChat(i, "{red}%N {default}: %s", client, sChat);
				}
			}
			i++;
		}
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
		int i          = 1;
		while (i <= MaxClients)
		{
			if (bCvarSTVSeeTChat && IsValidClient(i) && IsClientSourceTV(i))    // TeamChat from STV
			{
				switch (ClientTeam)
				{
					case L4D_TEAM_SPECTATOR:
						CPrintToChat(i, "{default}(Spected) %N : %s", client, sChat);
					case L4D_TEAM_SURVIVOR:
						CPrintToChat(i, "{default}(Survivor) {blue}%N {default}: %s", client, sChat);
					case L4D_TEAM_INFECTED:
						CPrintToChat(i, "{default}(Infected) {red}%N {default}: %s", client, sChat);
				}
			}
			if (IsValidClient(i) && GetClientTeam(i) == L4D_TEAM_SPECTATOR && GetClientTeam(client) != L4D_TEAM_SPECTATOR && !IsClientSourceTV(i))    // TeamChat for Spect
			{
				switch (ClientTeam)
				{
					case L4D_TEAM_SURVIVOR:
						CPrintToChat(i, "{default}(Survivor) {blue}%N {default}: %s", client, sChat);
					case L4D_TEAM_INFECTED:
						CPrintToChat(i, "{default}(Infected) {red}%N {default}: %s", client, sChat);
				}
			}
			i++;
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
		if (GetClientTeam(client) == L4D_TEAM_SPECTATOR && bSpecNameChange)
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
	bCvarChange      = hCvarCvarChange.BoolValue;
	bNameChange      = hCvarNameChange.BoolValue;
	bSpecNameChange  = hCvarSpecNameChange.BoolValue;
	bSpecSeeChat     = hCvarSpecSeeChat.BoolValue;
	bCvarSTVSeeChat  = hCvarSTVSeeChat.BoolValue;
	bCvarSTVSeeTChat = hCvarSTVSeeTChat.BoolValue;
}

stock bool IsValidClient(int client)
{
	if (!IsValidClientIndex(client) || !IsClientInGame(client) || !IsClientConnected(client))
	{
		return false;
	}
	return true;
}
