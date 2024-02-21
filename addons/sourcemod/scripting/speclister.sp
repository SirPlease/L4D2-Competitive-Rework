#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>

#define VOICE_NORMAL	0	/**< Allow the client to listen and speak normally. */
#define VOICE_MUTED		1	/**< Mutes the client from speaking to everyone. */
#define VOICE_SPEAKALL	2	/**< Allow the client to speak to everyone. */
#define VOICE_LISTENALL	4	/**< Allow the client to listen to everyone. */
#define VOICE_TEAM		8	/**< Allow the client to always speak to team, even when dead. */
#define VOICE_LISTENTEAM	16	/**< Allow the client to always hear teammates, including dead ones. */

#define TEAM_SPEC 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define MUTE_TAG		"[X]"
#define UNMUTE_TAG		"[√]"
#define ITEMMARK(%0)	(%0 - (%0 % 7))

Handle hAllTalk;

int g_iMenuSelection[MAXPLAYERS+1];
bool g_bIsClientMuteTarget[MAXPLAYERS+1][MAXPLAYERS+1];
char g_sClientauthId[MAXPLAYERS+1][32];

#define PLUGIN_VERSION "2.1"
public Plugin myinfo = 
{
	name = "SpecLister",
	author = "waertf & bear modded by bman,Bred",
	description = "Allows spectator listen others team voice for l4d and mute a teammates",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=95474"
}


public void OnPluginStart()
{
	HookEvent("player_team",Event_PlayerChangeTeam);
	RegConsoleCmd("hear", Cmd_hear);
	
	//Fix for End of round all-talk.
	hAllTalk = FindConVar("sv_alltalk");
	HookConVarChange(hAllTalk, OnAlltalkChange);
	
	ResetListenOverride();

	LoadTranslations("SpecLister.phrases");
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client)) {
		char authId[32];
		GetClientAuthId(client, AuthId_SteamID64, authId, sizeof(authId));
		if (StrEqual(g_sClientauthId[client], authId))
			SetListenOverrideEx(client);
		else {
			strcopy(g_sClientauthId[client], 32, authId);
			ResetListenOverride(client, 0);
			ResetListenOverride(0, client);
		}
	}
}

public Action Cmd_hear(int client,any args)
{
	if (IsValidClient(client))
		CreateMuteMenu(client);
	return Plugin_Handled;
}

void CreateMuteMenu(int client) {
	Menu menu = new Menu(MuteMenu_VoteHandler);
	menu.SetTitle(Translate(client, "%t", "Mute_Menu_Title"));
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	
	int team = GetClientTeam(client);
	char name[MAX_NAME_LENGTH], playerid[32];
	
	if (team == TEAM_SPEC) {
		Format(name, sizeof(name), "%s %s", GetClientListeningFlags(client) == VOICE_LISTENALL ? UNMUTE_TAG : MUTE_TAG, Translate(client, "%t", "Speclisten"));
		menu.AddItem("-2", name);
	}
	
	menu.AddItem("-1", Translate(client, "%t", "Mute_Team_All"));
	menu.AddItem("0", Translate(client, "%t", "UnMute_Team_All"));
	
	for(int i = 1;i <= MaxClients; i++)
	{
		if(IsValidClient(i) && client != i && GetClientTeam(i) == team)
		{
			Format(playerid, sizeof(playerid), "%i", GetClientUserId(i));
			if(GetClientName(i, name, sizeof(name))) {
				menu.AddItem(playerid, NameAddTag(client, i, name));
			}
		}		
	}
	menu.DisplayAt(client, ITEMMARK(g_iMenuSelection[client]), MENU_TIME_FOREVER);	
}

int MuteMenu_VoteHandler(Menu menu, MenuAction action, int client, int position) {
	if (action == MenuAction_End) 
		delete menu;
/* 	else if (action == MenuAction_Cancel)
		CreateMuteMenu(client); */
	else if (action == MenuAction_Select) {
		char sInfo[8], dispBuf[32];
		menu.GetItem(position, sInfo, sizeof(sInfo), _, dispBuf, sizeof(dispBuf));
		int target = StringToInt(sInfo);
		
		switch (target) {
			case -2: {
				if (GetClientTeam(client) == TEAM_SPEC) {
				
					if (GetClientListeningFlags(client) == VOICE_LISTENALL) {
						SetClientListeningFlags(client, VOICE_NORMAL);
						CPrintToChat(client, "%t", "Speclisten_Off" );
					}
					else {
						SetClientListeningFlags(client, VOICE_LISTENALL);
						CPrintToChat(client, "%t", "Speclisten_On" );
					}
				}
			}
			case -1: 
				ToggleMuteTeamAll(client, GetClientTeam(client), true);
			case 0:
				ToggleMuteTeamAll(client, GetClientTeam(client), false);
			default: {
				target = GetClientOfUserId(target);
				if (target && GetClientTeam(client) == GetClientTeam(target))
				{
					g_bIsClientMuteTarget[client][target] = !g_bIsClientMuteTarget[client][target];
					SetListenOverride(client, target, GetListenOverride(client, target) == Listen_No ? Listen_Default : Listen_No);
				}
			}
		}
		CreateMuteMenu(client);
	}
	
	return 0;
}

stock void ToggleMuteTeamAll(int client, int team, bool mute) {
	for(int i = 1;i <= MaxClients; i++) {
		if (IsValidClient(i) && GetClientTeam(i) == team && client != i)
		{
			g_bIsClientMuteTarget[client][i] = mute;
			SetListenOverride(client, i, mute ? Listen_No : Listen_Default);
		}
	}
}

public void Event_PlayerChangeTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int userID = GetClientOfUserId(GetEventInt(event, "userid"));
	int userTeam = GetEventInt(event, "team");
	if(userID == 0) return;
	
	SetClientListeningFlags(userID, userTeam == TEAM_SPEC ? VOICE_LISTENALL : VOICE_NORMAL);
}

public void OnAlltalkChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 1)
			{
				SetClientListeningFlags(i, VOICE_LISTENALL);
			}
		}
	}
}

void ResetListenOverride(int client = 0, int target = 0) {
	for (int i = (client ? client : 1); i <= (client ? client : MaxClients); i++) {
		if (IsValidClient(i)) {
			for (int j = (target ? target : 1); j <= (target ? target : MaxClients); j++) {
				if (IsValidClient(j) && i != j) {
					SetListenOverride(i, j, Listen_Default);
					g_bIsClientMuteTarget[i][j] = false;
				}
			}
		}
	}
}

void SetListenOverrideEx(int client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i) && i != client) {
			SetListenOverride(client, i, g_bIsClientMuteTarget[client][i] ? Listen_No : Listen_Default);
			SetListenOverride(i, client, g_bIsClientMuteTarget[i][client] ? Listen_No : Listen_Default);
		}
	}
}

stock char[] Translate(int client, const char[] format, any ...)
{
	char buffer[64];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	return buffer;
}

stock char[] NameAddTag(int client, int target, char[] name)
{
	char buffer[64];
	Format(buffer, sizeof(buffer), "%s %s", (GetListenOverride(client, target) == Listen_No ? MUTE_TAG : UNMUTE_TAG), name);
	return buffer;
}

stock bool IsValidClient(int client)
{
    return (client > 0 && IsClientInGame(client) && !IsFakeClient(client));
}

stock bool IsValidClientTest(int client)
{
    return (0 < client <= MaxClients && IsClientInGame(client));
}