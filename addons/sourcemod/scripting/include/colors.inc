/**************************************************************************
 *                                                                        *
 *                       Colored Chat Functions                           *
 *                   Author: exvel, Editor: Popoklopsi, Powerlord, Bara   *
 *                           Version: 1.3.2                               *
 *                                                                        *
 **************************************************************************/

#if defined _colors_included
	#endinput
#endif
#define _colors_included

#define CSOURCETV				1 // Enable print for SourceTV

#define MAX_MESSAGE_LENGTH		250
#define MAX_COLORS				12

#define SERVER_INDEX			0
#define NO_INDEX				-1
#define NO_PLAYER				-2

enum Colors
{
	Color_Default = 0,
	Color_Darkred,
	Color_Green,
	Color_Lightgreen,
	Color_Red,
	Color_Blue,
	Color_Olive,
	Color_Lime,
	Color_Lightred,
	Color_Purple,
	Color_Grey,
	Color_Orange
};

/* Colors' properties */
stock char CTag[][] =
{
	"{default}",
	"{darkred}",
	"{green}",
	"{lightgreen}",
	"{red}",
	"{blue}",
	"{olive}",
	"{lime}",
	"{lightred}",
	"{purple}",
	"{grey}",
	"{orange}"
};

stock char CTagCode[][] =
{
	"\x01",
	"\x02",
	"\x04",
	"\x03",
	"\x03",
	"\x03",
	"\x05",
	"\x06",
	"\x07",
	"\x03",
	"\x08",
	"\x09"
};

stock bool CTagReqSayText2[] =
{
	false,
	false,
	false,
	true,
	true,
	true,
	false,
	false,
	false,
	false,
	false,
	false
};

stock bool CEventIsHooked = false;
stock bool CSkipList[MAXPLAYERS + 1] = {false, ...};

/* Game default profile */
stock bool CProfile_Colors[] =
{
	true,
	false,
	true,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false
};

stock bool CProfile_SayText2 = false;

stock int CProfile_TeamIndex[10] = {NO_INDEX, ...};

stock static ConVar g_hCvarSmShowActivity = null;

/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags.
 *
 * @param client	  Client index.
 * @param szMessage   Message (formatting rules).
 * @return			  No return
 *
 * On error/Errors:   If the client is not connected an error will be thrown.
 */
stock void CPrintToChat(int client, const char[] szMessage, any ...)
{
	if (client < 1 || client > MaxClients) {
		ThrowError("Invalid client index %d", client);
	}

	if (!IsClientInGame(client)) {
		ThrowError("Client %d is not in game", client);
	}

	char szBuffer[MAX_MESSAGE_LENGTH];
	char szCMessage[MAX_MESSAGE_LENGTH];

	SetGlobalTransTarget(client);

	Format(szBuffer, sizeof(szBuffer), "\x01%s", szMessage);
	VFormat(szCMessage, sizeof(szCMessage), szBuffer, 3);

	int index = CFormat(szCMessage, sizeof(szCMessage));

	if (index == NO_INDEX) {
		PrintToChat(client, "%s", szCMessage);

		return;
	}

	CSayText2(client, index, szCMessage);
}

/**
 * Reples to a message in a command. A client index of 0 will use PrintToServer().
 * If the command was from the console, PrintToConsole() is used. If the command was from chat, CPrintToChat() is used.
 * Supports color tags.
 *
 * @param client	  Client index, or 0 for server.
 * @param szMessage   Formatting rules.
 * @param ...         Variable number of format parameters.
 * @return			  No return
 *
 * On error/Errors:   If the client is not connected or invalid.
 */
stock void CReplyToCommand(int client, const char[] szMessage, any ...)
{
	char szCMessage[MAX_MESSAGE_LENGTH];

	SetGlobalTransTarget(client);
	VFormat(szCMessage, sizeof(szCMessage), szMessage, 3);

	if (client == 0) {
		CRemoveTags(szCMessage, sizeof(szCMessage));
		PrintToServer("%s", szCMessage);

		return;
	}

	if (GetCmdReplySource() == SM_REPLY_TO_CONSOLE) {
		CRemoveTags(szCMessage, sizeof(szCMessage));
		PrintToConsole(client, "%s", szCMessage);

		return;
	}

	CPrintToChat(client, "%s", szCMessage);
}

/**
 * Reples to a message in a command. A client index of 0 will use PrintToServer().
 * If the command was from the console, PrintToConsole() is used. If the command was from chat, CPrintToChat() is used.
 * Supports color tags.
 *
 * @param client	  Client index, or 0 for server.
 * @param author      Author index whose color will be used for teamcolor tag.
 * @param szMessage   Formatting rules.
 * @param ...         Variable number of format parameters.
 * @return			  No return
 *
 * On error/Errors:   If the client is not connected or invalid.
 */
stock void CReplyToCommandEx(int client, int author, const char[] szMessage, any ...)
{
	char szCMessage[MAX_MESSAGE_LENGTH];
	SetGlobalTransTarget(client);
	VFormat(szCMessage, sizeof(szCMessage), szMessage, 4);

	if (client == 0) {
		CRemoveTags(szCMessage, sizeof(szCMessage));
		PrintToServer("%s", szCMessage);

		return;
	}

	if (GetCmdReplySource() == SM_REPLY_TO_CONSOLE) {
		CRemoveTags(szCMessage, sizeof(szCMessage));
		PrintToConsole(client, "%s", szCMessage);

		return;
	}

	CPrintToChatEx(client, author, "%s", szCMessage);
}

/**
 * Prints a message to all clients in the chat area.
 * Supports color tags.
 *
 * @param client	  Client index.
 * @param szMessage   Message (formatting rules)
 * @return			  No return
 */
stock void CPrintToChatAll(const char[] szMessage, any ...)
{
	char szBuffer[MAX_MESSAGE_LENGTH];

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)
		#if CSOURCETV
			&& (!IsFakeClient(i) || IsClientSourceTV(i))
		#else
			&& !IsFakeClient(i)
		#endif
			&& !CSkipList[i]
		) {
			SetGlobalTransTarget(i);
			VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);

			CPrintToChat(i, "%s", szBuffer);
		}

		CSkipList[i] = false;
	}
}

/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags and teamcolor tag.
 *
 * @param client	  Client index.
 * @param author	  Author index whose color will be used for teamcolor tag.
 * @param szMessage   Message (formatting rules).
 * @return			  No return
 *
 * On error/Errors:   If the client or author are not connected an error will be thrown.
 */
stock void CPrintToChatEx(int client, int author, const char[] szMessage, any ...)
{
	if (client < 1 || client > MaxClients) {
		ThrowError("Invalid client index %d", client);
	}

	if (!IsClientInGame(client)) {
		ThrowError("Client %d is not in game", client);
	}

	if (author < 0 || author > MaxClients) {
		ThrowError("Invalid client index %d", author);
	}

	char szBuffer[MAX_MESSAGE_LENGTH];
	char szCMessage[MAX_MESSAGE_LENGTH];

	SetGlobalTransTarget(client);

	Format(szBuffer, sizeof(szBuffer), "\x01%s", szMessage);
	VFormat(szCMessage, sizeof(szCMessage), szBuffer, 4);

	int index = CFormat(szCMessage, sizeof(szCMessage), author);

	if (index == NO_INDEX) {
		PrintToChat(client, "%s", szCMessage);

		return;
	}

	CSayText2(client, author, szCMessage);
}

/**
 * Prints a message to all clients in the chat area.
 * Supports color tags and teamcolor tag.
 *
 * @param author	  Author index whos color will be used for teamcolor tag.
 * @param szMessage   Message (formatting rules).
 * @return			  No return
 *
 * On error/Errors:   If the author is not connected an error will be thrown.
 */
stock void CPrintToChatAllEx(int author, const char[] szMessage, any ...)
{
	if (author < 0 || author > MaxClients) {
		ThrowError("Invalid client index %d", author);
	}

	if (!IsClientInGame(author)) {
		ThrowError("Client %d is not in game", author);
	}

	char szBuffer[MAX_MESSAGE_LENGTH];

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)
		#if CSOURCETV
			&& (!IsFakeClient(i) || IsClientSourceTV(i))
		#else
			&& !IsFakeClient(i)
		#endif
			&& !CSkipList[i]
		) {
			SetGlobalTransTarget(i);
			VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);

			CPrintToChatEx(i, author, "%s", szBuffer);
		}

		CSkipList[i] = false;
	}
}

/**
 * Removes color tags from the string.
 *
 * @param szMessage   String.
 * @return			  No return
 */
stock void CRemoveTags(char[] szMessage, int maxlength)
{
	for (int i = 0; i < MAX_COLORS; i++) {
		ReplaceString(szMessage, maxlength, CTag[i], "", false);
	}

	ReplaceString(szMessage, maxlength, "{teamcolor}", "", false);
}

/**
 * Checks whether a color is allowed or not
 *
 * @param tag   		Color Tag.
 * @return			 	True when color is supported, otherwise false
 */
stock bool CColorAllowed(Colors color)
{
	if (!CEventIsHooked) {
		CSetupProfile();

		CEventIsHooked = true;
	}

	return CProfile_Colors[color];
}

/**
 * Replace the color with another color
 * Handle with care!
 *
 * @param color   			color to replace.
 * @param newColor   		color to replace with.
 * @noreturn
 */
stock void CReplaceColor(Colors color, Colors newColor)
{
	if (!CEventIsHooked) {
		CSetupProfile();

		CEventIsHooked = true;
	}

	CProfile_Colors[color] = CProfile_Colors[newColor];
	CProfile_TeamIndex[color] = CProfile_TeamIndex[newColor];

	CTagReqSayText2[color] = CTagReqSayText2[newColor];
	Format(CTagCode[color], sizeof(CTagCode[]), CTagCode[newColor])
}

/**
 * This function should only be used right in front of
 * CPrintToChatAll or CPrintToChatAllEx and it tells
 * to those funcions to skip specified client when printing
 * message to all clients. After message is printed client will
 * no more be skipped.
 *
 * @param client   Client index
 * @return		   No return
 */
stock void CSkipNextClient(int client)
{
	if (client < 1 || client > MaxClients) {
		ThrowError("Invalid client index %d", client);
	}

	CSkipList[client] = true;
}

/**
 * Replaces color tags in a string with color codes
 *
 * @param szMessage   String.
 * @param maxlength   Maximum length of the string buffer.
 * @return			  Client index that can be used for SayText2 author index
 *
 * On error/Errors:   If there is more then one team color is used an error will be thrown.
 */
stock int CFormat(char[] szMessage, int maxlength, int author = NO_INDEX)
{
	char szGameName[30];
	GetGameFolderName(szGameName, sizeof(szGameName));

	/* Hook event for auto profile setup on map start */
	if (!CEventIsHooked) {
		CSetupProfile();
		HookEvent("server_spawn", Event_MapStart, EventHookMode_PostNoCopy);

		CEventIsHooked = true;
	}

	int iRandomPlayer = NO_INDEX;

	// On CS:GO set invisible precolor
	if (StrEqual(szGameName, "csgo", false)) {
		Format(szMessage, maxlength, " \x01\x0B\x01%s", szMessage);
	}

	/* If author was specified replace {teamcolor} tag */
	if (author != NO_INDEX) {
		if (CProfile_SayText2) {
			ReplaceString(szMessage, maxlength, "{teamcolor}", "\x03", false);

			iRandomPlayer = author;
		} else { /* If saytext2 is not supported by game replace {teamcolor} with green tag */
			ReplaceString(szMessage, maxlength, "{teamcolor}", CTagCode[Color_Green], false);
		}
	} else {
		ReplaceString(szMessage, maxlength, "{teamcolor}", "", false);
	}

	/* For other color tags we need a loop */
	for (int i = 0; i < MAX_COLORS; i++) {
		/* If tag not found - skip */
		if (StrContains(szMessage, CTag[i], false) == -1) {
			continue;
		}

		if (!CProfile_Colors[i]) { /* If tag is not supported by game replace it with green tag */
			ReplaceString(szMessage, maxlength, CTag[i], CTagCode[Color_Green], false);

			continue;
		}

		if (!CTagReqSayText2[i]) { /* If tag doesn't need saytext2 simply replace */
			ReplaceString(szMessage, maxlength, CTag[i], CTagCode[i], false);

			continue;
		}

		/* Tag needs saytext2 */
		/* If saytext2 is not supported by game replace tag with green tag */
		if (!CProfile_SayText2) {
			ReplaceString(szMessage, maxlength, CTag[i], CTagCode[Color_Green], false);

			continue;
		}

		/* Game supports saytext2 */
		/* If random player for tag wasn't specified replace tag and find player */
		if (iRandomPlayer == NO_INDEX) {
			/* Searching for valid client for tag */
			iRandomPlayer = CFindRandomPlayerByTeam(CProfile_TeamIndex[i]);

			/* If player not found replace tag with green color tag */
			if (iRandomPlayer == NO_PLAYER) {
				ReplaceString(szMessage, maxlength, CTag[i], CTagCode[Color_Green], false);
			} else { /* If player was found simply replace */
				ReplaceString(szMessage, maxlength, CTag[i], CTagCode[i], false);
			}

			continue;
		}

		/* If found another team color tag throw error */
		//ReplaceString(szMessage, maxlength, CTag[i], "");
		ThrowError("Using two team colors in one message is not allowed");
	}

	return iRandomPlayer;
}

/**
 * Founds a random player with specified team
 *
 * @param color_team  Client team.
 * @return			  Client index or NO_PLAYER if no player found
 */
stock int CFindRandomPlayerByTeam(int color_team)
{
	if (color_team == SERVER_INDEX) {
		return 0;
	}

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == color_team) {
			return i;
		}
	}

	return NO_PLAYER;
}

/**
 * Sends a SayText2 usermessage to a client
 *
 * @param szMessage   Client index
 * @param maxlength   Author index
 * @param szMessage   Message
 * @return			  No return.
 */
stock void CSayText2(int client, int author, const char[] szMessage)
{
	Handle hBuffer = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) {
		PbSetInt(hBuffer, "ent_idx", author);
		PbSetBool(hBuffer, "chat", true);
		PbSetString(hBuffer, "msg_name", szMessage);
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
	} else {
		BfWriteByte(hBuffer, author);
		BfWriteByte(hBuffer, true);
		BfWriteString(hBuffer, szMessage);
	}

	EndMessage();
}

/**
 * Creates game color profile
 * This function must be edited if you want to add more games support
 *
 * @return			  No return.
 */
stock void CSetupProfile()
{
	char szGameName[30];
	GetGameFolderName(szGameName, sizeof(szGameName));

	if (strcmp(szGameName, "cstrike", false) == 0) {
		CProfile_Colors[Color_Lightgreen] = true;
		CProfile_Colors[Color_Red] = true;
		CProfile_Colors[Color_Blue] = true;
		CProfile_Colors[Color_Olive] = true;

		CProfile_TeamIndex[Color_Lightgreen] = SERVER_INDEX;
		CProfile_TeamIndex[Color_Red] = 2;
		CProfile_TeamIndex[Color_Blue] = 3;

		CProfile_SayText2 = true;

		return;
	}

	if (strcmp(szGameName, "csgo", false) == 0) {
		CProfile_Colors[Color_Red] = true;
		CProfile_Colors[Color_Blue] = true;
		CProfile_Colors[Color_Olive] = true;
		CProfile_Colors[Color_Darkred] = true;
		CProfile_Colors[Color_Lime] = true;
		CProfile_Colors[Color_Lightred] = true;
		CProfile_Colors[Color_Purple] = true;
		CProfile_Colors[Color_Grey] = true;
		CProfile_Colors[Color_Orange] = true;

		CProfile_TeamIndex[Color_Red] = 2;
		CProfile_TeamIndex[Color_Blue] = 3;

		CProfile_SayText2 = true;

		return;
	}

	if (strcmp(szGameName, "tf", false) == 0) {
		CProfile_Colors[Color_Lightgreen] = true;
		CProfile_Colors[Color_Red] = true;
		CProfile_Colors[Color_Blue] = true;
		CProfile_Colors[Color_Olive] = true;

		CProfile_TeamIndex[Color_Lightgreen] = SERVER_INDEX;
		CProfile_TeamIndex[Color_Red] = 2;
		CProfile_TeamIndex[Color_Blue] = 3;
	
		CProfile_SayText2 = true;

		return;
	}

	if (strcmp(szGameName, "left4dead", false) == 0
		|| strcmp(szGameName, "left4dead2", false) == 0
	) {
		CProfile_Colors[Color_Lightgreen] = true;
		CProfile_Colors[Color_Red] = true;
		CProfile_Colors[Color_Blue] = true;
		CProfile_Colors[Color_Olive] = true;

		CProfile_TeamIndex[Color_Lightgreen] = SERVER_INDEX;
		CProfile_TeamIndex[Color_Red] = 3;
		CProfile_TeamIndex[Color_Blue] = 2;

		CProfile_SayText2 = true;

		return;
	}

	if (strcmp(szGameName, "hl2mp", false) == 0) {
		/* hl2mp profile is based on mp_teamplay convar */
		static ConVar hCvarMpTeamPlay = null;
		if (hCvarMpTeamPlay == null) {
			hCvarMpTeamPlay = FindConVar("mp_teamplay")
		}

		if (hCvarMpTeamPlay.BoolValue) {
			CProfile_Colors[Color_Red] = true;
			CProfile_Colors[Color_Blue] = true;
			CProfile_Colors[Color_Olive] = true;

			CProfile_TeamIndex[Color_Red] = 3;
			CProfile_TeamIndex[Color_Blue] = 2;

			CProfile_SayText2 = true;
		} else {
			CProfile_SayText2 = false;
	
			CProfile_Colors[Color_Olive] = true;
		}

		return;
	}

	if (strcmp(szGameName, "dod", false) == 0) {
		CProfile_Colors[Color_Olive] = true;

		CProfile_SayText2 = false;

		return;
	}

	/* Profile for other games */
	if (GetUserMessageId("SayText2") == INVALID_MESSAGE_ID) {
		CProfile_SayText2 = false;

		return;
	}

	CProfile_Colors[Color_Red] = true;
	CProfile_Colors[Color_Blue] = true;

	CProfile_TeamIndex[Color_Red] = 2;
	CProfile_TeamIndex[Color_Blue] = 3;

	CProfile_SayText2 = true;
}

stock void Event_MapStart(Event hEvent, const char[] name, bool dontBroadcast)
{
	CSetupProfile();

	for (int i = 1; i <= MaxClients; i++) {
		CSkipList[i] = false;
	}
}

/**
 * Displays usage of an admin command to users depending on the
 * setting of the sm_show_activity cvar.
 *
 * This version does not display a message to the originating client
 * if used from chat triggers or menus.  If manual replies are used
 * for these cases, then this function will suffice.  Otherwise,
 * CShowActivity2() is slightly more useful.
 * Supports color tags.
 *
 * @param client		Client index doing the action, or 0 for server.
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @noreturn
 * @error
 */
stock void CShowActivity(int client, const char[] format, any ...)
{
	if (g_hCvarSmShowActivity == null) {
		g_hCvarSmShowActivity = FindConVar("sm_show_activity");
	}

	char tag[] = "[SM] ", szBuffer[MAX_MESSAGE_LENGTH];

	//char szCMessage[MAX_MESSAGE_LENGTH];
	int value = g_hCvarSmShowActivity.IntValue;
	ReplySource replyto = GetCmdReplySource();

	char name[MAX_NAME_LENGTH] = "Console";
	char sign[MAX_NAME_LENGTH] = "ADMIN";

	bool display_in_chat = false;
	if (client != 0) {
		// Function 'GetClientName' already has these checks inside
		/*if (client < 0 || client > MaxClients || !IsClientConnected(client)) {
			ThrowError("Client index %d is invalid", client);
		}*/

		GetClientName(client, name, sizeof(name));

		AdminId id = GetUserAdmin(client);
		if (id == INVALID_ADMIN_ID || !GetAdminFlag(id, Admin_Generic, Access_Effective)) {
			sign = "PLAYER";
		}

		/* Display the message to the client? */
		if (replyto == SM_REPLY_TO_CONSOLE) {
			SetGlobalTransTarget(client);
			VFormat(szBuffer, sizeof(szBuffer), format, 3);

			CRemoveTags(szBuffer, sizeof(szBuffer));
			PrintToConsole(client, "%s%s\n", tag, szBuffer);
		}
	} else {
		SetGlobalTransTarget(LANG_SERVER);
		VFormat(szBuffer, sizeof(szBuffer), format, 3);

		CRemoveTags(szBuffer, sizeof(szBuffer));
		PrintToServer("%s%s\n", tag, szBuffer);
	}

	if (!value) {
		return;
	}

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)
		#if CSOURCETV
			|| (IsFakeClient(i) && !IsClientSourceTV(i))
		#else
			|| IsFakeClient(i)
		#endif
			|| (display_in_chat && i == client)
		) {
			continue;
		}

		SetGlobalTransTarget(i);

		AdminId id = GetUserAdmin(i);
		if (id == INVALID_ADMIN_ID || !GetAdminFlag(id, Admin_Generic, Access_Effective)) {
			/* Treat this as a normal user. */
			if ((value & 1) | (value & 2)) {
				char newsign[MAX_NAME_LENGTH];

				newsign = sign;
				if ((value & 2) || (i == client)) {
					newsign = name;
				}

				VFormat(szBuffer, sizeof(szBuffer), format, 3);
				CPrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
			}

			continue;
		}

		/* Treat this as an admin user */
		bool is_root = GetAdminFlag(id, Admin_Root, Access_Effective);

		if ((value & 4) || (value & 8) || ((value & 16) && is_root)) {
			char newsign[MAX_NAME_LENGTH]

			newsign = sign;
			if ((value & 8) || ((value & 16) && is_root) || (i == client)) {
				newsign = name;
			}

			VFormat(szBuffer, sizeof(szBuffer), format, 3);
			CPrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
		}
	}
}

/**
 * Same as CShowActivity(), except the tag parameter is used instead of "[SM] " (note that you must supply any spacing).
 * Supports color tags.
 *
 * @param client		Client index doing the action, or 0 for server.
 * @param tags			Tag to display with.
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @noreturn
 * @error
 */
stock void CShowActivityEx(int client, const char[] tag, const char[] format, any ...)
{
	if (g_hCvarSmShowActivity == null) {
		g_hCvarSmShowActivity = FindConVar("sm_show_activity");
	}

	char szBuffer[MAX_MESSAGE_LENGTH];
	//decl String:szCMessage[MAX_MESSAGE_LENGTH];
	int value = g_hCvarSmShowActivity.IntValue;
	ReplySource replyto = GetCmdReplySource();

	char name[MAX_NAME_LENGTH] = "Console";
	char sign[MAX_NAME_LENGTH] = "ADMIN";

	bool display_in_chat = false;
	if (client != 0) {
		// Function 'GetClientName' already has these checks inside
		/*if (client < 0 || client > MaxClients || !IsClientConnected(client)) {
			ThrowError("Client index %d is invalid", client);
		}*/

		GetClientName(client, name, sizeof(name));

		AdminId id = GetUserAdmin(client);
		if (id == INVALID_ADMIN_ID || !GetAdminFlag(id, Admin_Generic, Access_Effective)){
			sign = "PLAYER";
		}

		/* Display the message to the client? */
		if (replyto == SM_REPLY_TO_CONSOLE) {
			SetGlobalTransTarget(client);
			VFormat(szBuffer, sizeof(szBuffer), format, 4);

			CRemoveTags(szBuffer, sizeof(szBuffer));
			PrintToConsole(client, "%s%s\n", tag, szBuffer);
		}
	} else {
		SetGlobalTransTarget(LANG_SERVER);
		VFormat(szBuffer, sizeof(szBuffer), format, 4);

		CRemoveTags(szBuffer, sizeof(szBuffer));
		PrintToServer("%s%s\n", tag, szBuffer);
	}

	if (!value) {
		return;
	}

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)
		#if CSOURCETV
			|| (IsFakeClient(i) && !IsClientSourceTV(i))
		#else
			|| IsFakeClient(i)
		#endif
			|| (display_in_chat && i == client)
		) {
			continue;
		}

		SetGlobalTransTarget(i);

		AdminId id = GetUserAdmin(i);
		if (id == INVALID_ADMIN_ID || !GetAdminFlag(id, Admin_Generic, Access_Effective)) {
			/* Treat this as a normal user. */
			if ((value & 1) | (value & 2)) {
				char newsign[MAX_NAME_LENGTH];

				newsign = sign;
				if ((value & 2) || (i == client)) {
					newsign = name;
				}

				VFormat(szBuffer, sizeof(szBuffer), format, 4);
				CPrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
			}

			continue;
		}

		/* Treat this as an admin user */
		bool is_root = GetAdminFlag(id, Admin_Root, Access_Effective);

		if ((value & 4) || (value & 8) || ((value & 16) && is_root)) {
			char newsign[MAX_NAME_LENGTH];

			newsign = sign;
			if ((value & 8) || ((value & 16) && is_root) || (i == client)) {
				newsign = name;
			}

			VFormat(szBuffer, sizeof(szBuffer), format, 4);
			CPrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
		}
	}
}

/**
 * Displays usage of an admin command to users depending on the setting of the sm_show_activity cvar.
 * All users receive a message in their chat text, except for the originating client,
 * who receives the message based on the current ReplySource.
 * Supports color tags.
 *
 * @param client		Client index doing the action, or 0 for server.
 * @param tags			Tag to prepend to the message.
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @noreturn
 * @error
 */
stock void CShowActivity2(int client, const char[] tag, const char[] format, any ...)
{
	if (g_hCvarSmShowActivity == null) {
		g_hCvarSmShowActivity = FindConVar("sm_show_activity");
	}

	char szBuffer[MAX_MESSAGE_LENGTH];
	//decl String:szCMessage[MAX_MESSAGE_LENGTH];
	int value = g_hCvarSmShowActivity.IntValue;
	ReplySource replyto = GetCmdReplySource();

	char name[MAX_NAME_LENGTH] = "Console";
	char sign[MAX_NAME_LENGTH] = "ADMIN";

	if (client != 0) {
		// Function 'GetClientName' already has these checks inside
		/*if (client < 0 || client > MaxClients || !IsClientConnected(client)) {
			ThrowError("Client index %d is invalid", client);
		}*/

		GetClientName(client, name, sizeof(name));

		AdminId id = GetUserAdmin(client);
		if (id == INVALID_ADMIN_ID || !GetAdminFlag(id, Admin_Generic, Access_Effective)) {
			sign = "PLAYER";
		}

		SetGlobalTransTarget(client);
		VFormat(szBuffer, sizeof(szBuffer), format, 4);

		/* We don't display directly to the console because the chat text
		 * simply gets added to the console, so we don't want it to print
		 * twice.
		 */
		if (replyto == SM_REPLY_TO_CONSOLE) {
			#if 0
				PrintToConsole(client, "%s%s\n", tag, szBuffer);
			#endif

			CPrintToChatEx(client, client, "%s%s", tag, szBuffer);
		} else {
			CPrintToChatEx(client, client, "%s%s", tag, szBuffer);
		}
	} else {
		SetGlobalTransTarget(LANG_SERVER);
		VFormat(szBuffer, sizeof(szBuffer), format, 4);

		CRemoveTags(szBuffer, sizeof(szBuffer));
		PrintToServer("%s%s\n", tag, szBuffer);
	}

	if (!value) {
		return;
	}

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)
		#if CSOURCETV
			|| (IsFakeClient(i) && !IsClientSourceTV(i))
		#else
			|| IsFakeClient(i)
		#endif
			|| i == client
		) {
			continue;
		}

		SetGlobalTransTarget(i);

		AdminId id = GetUserAdmin(i);
		if (id == INVALID_ADMIN_ID || !GetAdminFlag(id, Admin_Generic, Access_Effective)) {
			/* Treat this as a normal user. */
			if ((value & 1) | (value & 2)) {
				char newsign[MAX_NAME_LENGTH];

				newsign = sign;
				if ((value & 2)) {
					newsign = name;
				}

				VFormat(szBuffer, sizeof(szBuffer), format, 4);
				CPrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
			}

			continue;
		}

		/* Treat this as an admin user */
		bool is_root = GetAdminFlag(id, Admin_Root, Access_Effective);

		if ((value & 4) || (value & 8) || ((value & 16) && is_root)) {
			char newsign[MAX_NAME_LENGTH];

			newsign = sign;
			if ((value & 8) || ((value & 16) && is_root)) {
				newsign = name;
			}

			VFormat(szBuffer, sizeof(szBuffer), format, 4);
			CPrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
		}
	}
}