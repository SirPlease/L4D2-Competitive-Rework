#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <sourcecomms>
#include <basecomm>
#define REQUIRE_PLUGIN

#define CHAT_SYMBOL '@'

ConVar
	g_cvarCvarChange,
	g_cvarNameChange,
	g_cvarSpecSeeChat,
	g_cvarBaseChat;

bool
	g_bSourceComms,
	g_bBaseComm,
	g_bLateload;

enum L4DTeam
{
	L4DTeam_Unassigned = 0,
	L4DTeam_Spectator  = 1,
	L4DTeam_Survivor   = 2,
	L4DTeam_Infected   = 3
}

public Plugin myinfo =
{
	name		= "BeQuiet",
	author		= "Sir",
	description = "Please be Quiet!",
	version		= "1.4",
	url			= "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public APLRes APLResAskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max)
{
	g_bLateload = bLate;
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	g_bSourceComms = LibraryExists("sourcecomms++");
	g_bBaseComm	   = LibraryExists("basecomm");
}

public void OnLibraryAdded(const char[] sName)
{
	if (StrEqual(sName, "sourcecomms++"))
		g_bSourceComms = true;
	else if (StrEqual(sName, "basecomm"))
		g_bBaseComm = true;
}

public void OnLibraryRemoved(const char[] sName)
{
	if (StrEqual(sName, "sourcecomms++"))
		g_bSourceComms = false;
	else if (StrEqual(sName, "basecomm"))
		g_bBaseComm = false;
}

public void OnPluginStart()
{
	LoadTranslation("bequiet.phrases");
	AddCommandListener(TeamSay_Callback, "say_team");

	HookEvent("server_cvar", Event_ServerConVar, EventHookMode_Pre);
	HookUserMessage(GetUserMessageId("SayText2"), TextMsg, true);

	g_cvarCvarChange  = CreateConVar("bq_cvar_change_suppress", "1", "Silence Server Cvars being changed, this makes for a clean chat with no disturbances.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarNameChange  = CreateConVar("bq_name_change_suppress", "1", "Silence Player name Changes.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarSpecSeeChat = CreateConVar("bq_show_player_team_chat_spec", "1", "Show Spectators Survivors and Infected Team chat?", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarBaseChat	  = CreateConVar("bq_basechat", "1", "basechat support?", FCVAR_NONE, true, 0.0, true, 1.0);

	AutoExecConfig(true, "bequiet");

	if (!g_bLateload)
		return;

	g_bSourceComms = LibraryExists("sourcecomms++");
	g_bBaseComm	   = LibraryExists("basecomm");
}

Action TeamSay_Callback(int iClient, char[] command, int argss)
{
	if (!g_cvarSpecSeeChat.BoolValue)
		return Plugin_Continue;

	if (IsPunishedPlayer(iClient))
		return Plugin_Handled;

	char sayWord[MAX_NAME_LENGTH];
	GetCmdArg(1, sayWord, sizeof(sayWord));

	if (sayWord[0] == '/')
		return Plugin_Handled;

	if (g_cvarBaseChat.BoolValue && sayWord[0] == CHAT_SYMBOL)
		return Plugin_Handled;

	char sChat[256];
	GetCmdArgString(sChat, 256);
	StripQuotes(sChat);
	SpecSeeTeamChat(iClient, sChat);
	return Plugin_Handled;
}

Action Event_ServerConVar(Event event, const char[] name, bool dontBroadcast)
{
	if (g_cvarCvarChange.BoolValue)
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action TextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	msg.ReadByte();	   // Skip first parameter
	msg.ReadByte();	   // Skip second parameter

	char buffer[100];
	buffer[0] = '\0';
	msg.ReadString(buffer, sizeof(buffer), false);

	// left4dead2/resource/left4dead2_english.txt, found "Cstrike_Name_Change"
	if (StrContains(buffer, "Cstrike_Name_Change") == -1)
		return Plugin_Continue;

	if (g_cvarNameChange.BoolValue)
		return Plugin_Handled;

	return Plugin_Continue;
}

/**
 * This function handles the display of team chat messages to spectators in the game.
 * It formats the chat message with the team name and author, and then sends it to the appropriate clients.
 *
 * @param iAuthor The client index of the message author.
 * @param sChat The chat message to be displayed.
 */
void SpecSeeTeamChat(int iAuthor, char[] sChat)
{
	char
		sTeamAuthor[16],
		sMessage[500];

	L4DTeam
		L4DTeamAuthor = L4D_GetClientTeam(iAuthor);

	switch (L4DTeamAuthor)
	{
		case L4DTeam_Survivor:
			Format(sTeamAuthor, sizeof(sTeamAuthor), "%t", "Team_Survivor");
		case L4DTeam_Infected:
			Format(sTeamAuthor, sizeof(sTeamAuthor), "%t", "Team_Infected");
		case L4DTeam_Spectator:
			Format(sTeamAuthor, sizeof(sTeamAuthor), "%t", "Team_Spectator");
	}

	Format(sMessage, sizeof(sMessage), "(%s) %N:  %s", sTeamAuthor, iAuthor, sChat);
	CRemoveTags(sMessage, sizeof(sMessage));
	PrintToServer("%s", sMessage);

	sMessage[0] = '\0';
	Format(sMessage, sizeof(sMessage), "(%s) \x03%N\x01:  %s", sTeamAuthor, iAuthor, sChat);
	for (int iTarget = 1; iTarget <= MaxClients; iTarget++)
	{
		if (IsClientConnected(iTarget) && (IsClientSourceTV(iTarget) || IsClientReplay(iTarget)))
		{
			CPrintToChatEx(iTarget, iAuthor, sMessage);
			continue;
		}

		if (!IsClientInGame(iTarget) || IsFakeClient(iTarget))
			continue;

		L4DTeam L4DTeamTarget = L4D_GetClientTeam(iTarget);

		// Don't show spectator chat to survivors or infected
		if (L4DTeamAuthor == L4DTeam_Spectator && (L4DTeamTarget == L4DTeam_Survivor || L4DTeamTarget == L4DTeam_Infected))
			continue;

		// Don't show infected chat to survivors and vice versa
		if ((L4DTeamAuthor == L4DTeam_Survivor && L4DTeamTarget == L4DTeam_Infected) || (L4DTeamAuthor == L4DTeam_Infected && L4DTeamTarget == L4DTeam_Survivor))
			continue;

		CPrintToChatEx(iTarget, iAuthor, sMessage);
	}
}

/**
 * Checks if a player is punished.
 *
 * @param iClient The iClient index of the player to check.
 * @return True if the player is punished, false otherwise.
 */
bool IsPunishedPlayer(int iClient)
{
	if (g_bSourceComms)
		return bNot != SourceComms_GetClientGagType(iClient);

	if (g_bBaseComm)
		return BaseComm_IsClientGagged(iClient);

	return false;
}

/**
 * Returns the iClients team using L4DTeam.
 *
 * @param iClient		Player's index.
 * @return				Current L4DTeam of player.
 * @error				Invalid iClient index.
 */
stock L4DTeam L4D_GetClientTeam(int iClient)
{
	return view_as<L4DTeam>(GetClientTeam(iClient));
}

/**
 * Loads a translation file for the specified translation.
 *
 * @param sTranslation The name of the translation to load.
 */
void LoadTranslation(char[] sTranslation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", sTranslation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);

	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", sTranslation);
	LoadTranslations(sTranslation);
}
