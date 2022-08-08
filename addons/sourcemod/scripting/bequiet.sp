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
		int L4D_TEAM_CLIENT = GetClientTeam(client);

		for (int CLIENT_INDEX = 1; CLIENT_INDEX <= MaxClients; CLIENT_INDEX++)
		{
			if (IsValidClient(CLIENT_INDEX) && IsClientSourceTV(CLIENT_INDEX))    // Chat from STV
			{
				switch (L4D_TEAM_CLIENT)
				{
					case L4D_TEAM_SPECTATOR:
						CPrintToChat(CLIENT_INDEX, "{default}*SPEC* %N : %s", client, sChat);
					case L4D_TEAM_SURVIVOR:
						CPrintToChat(CLIENT_INDEX, "{blue}%N {default}: %s", client, sChat);
					case L4D_TEAM_INFECTED:
						CPrintToChat(CLIENT_INDEX, "{red}%N {default}: %s", client, sChat);
				}
			}
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
		int L4D_TEAM_CLIENT	= GetClientTeam(client);
		
		for (int CLIENT_INDEX = 1; CLIENT_INDEX <= MaxClients; CLIENT_INDEX++)
		{
			int L4D_TEAM_INDEX = GetClientTeam(CLIENT_INDEX);
			if(IsValidClient(CLIENT_INDEX))
			{
				if (bCvarSTVSeeTChat && IsClientSourceTV(CLIENT_INDEX))    // TeamChat from STV
				{
					switch (L4D_TEAM_CLIENT)
					{
						case L4D_TEAM_SPECTATOR:
							CPrintToChat(CLIENT_INDEX, "{default}(Spected) %N : %s", client, sChat);
						case L4D_TEAM_SURVIVOR:
							CPrintToChat(CLIENT_INDEX, "{default}(Survivor) {blue}%N {default}: %s", client, sChat);
						case L4D_TEAM_INFECTED:
							CPrintToChat(CLIENT_INDEX, "{default}(Infected) {red}%N {default}: %s", client, sChat);
					}
				}
				if (L4D_TEAM_INDEX == L4D_TEAM_SPECTATOR && L4D_TEAM_CLIENT != L4D_TEAM_SPECTATOR && !IsClientSourceTV(CLIENT_INDEX))	// TeamChat for Spect
				{
					switch (L4D_TEAM_CLIENT)
					{
						case L4D_TEAM_SURVIVOR:
							CPrintToChat(CLIENT_INDEX, "{default}(Survivor) {blue}%N {default}: %s", client, sChat);
						case L4D_TEAM_INFECTED:
							CPrintToChat(CLIENT_INDEX, "{default}(Infected) {red}%N {default}: %s", client, sChat);
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
	int clientid 		= event.GetInt("userid");
	int client   		= GetClientOfUserId(clientid);
	int L4D_TEAM_CLIENT = GetClientTeam(client);
	if (IsValidClient(client))
	{
		if (L4D_TEAM_CLIENT == L4D_TEAM_SPECTATOR && bSpecNameChange)
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
