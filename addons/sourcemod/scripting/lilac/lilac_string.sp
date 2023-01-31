/*
	Little Anti-Cheat
	Copyright (C) 2018-2023 J_Tanzanite

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	int flags;

	if (!icvar[CVAR_ENABLE])
		return Plugin_Continue;

	/* Prevent players banned for Chat-Clear from spamming chat.
	 * Helps legit players see the cheater was banned. */
	if (playerinfo_banned_flags[client][CHEAT_CHATCLEAR])
		return Plugin_Stop;

	if (!icvar[CVAR_FILTER_CHAT])
		return Plugin_Continue;

	/* Just for future reference, because it may be unclear
	 * how "is_string_valid()" works.
	 * Normally, it will set the "flags" variable with bits
	 * telling you what's wrong with a string and return false.
	 * But the wide-char-spam bit is an exception,
	 * it will set the bit, but won't return false.
	 * This is because wide-char spam gets its own message
	 * when blocking the chat.
	 * Plus, it's still technically a valid string. */

	/* Invalid string and no newlines/carriage returns.
	 * Newlines in chat will we dealt with in post.
	 * This is just so people can see that the player did indeed
	 * clear the chat before banning, otherwise people
	 * would be confused and think the ban was an error. */
	if (!(is_string_valid(sArgs, flags)) && !(flags & STRFLAG_NEWLINE)) {
		PrintToChat(client, "[Lilac] %T", "chat_invalid_characters", client);
		return Plugin_Stop;
	}
	else if ((flags & STRFLAG_WIDE_CHAR_SPAM)) {
		/* Wide char spam (Example: Bismillah spam),
		 * as explained by 3kliksphilip here: https://youtu.be/hP1N1YRitlM?t=94
		 * this clears the chat and is annoying.
		 * Block this exploit. */
		PrintToChat(client, "[Lilac] %T", "chat_wide_char_spam", client);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	/* Chat-Clear doesn't work in CS:GO. */
	if (ggame == GAME_CSGO)
		return;

	/* Todo: CVAR_CHAT is... Now an outdated name... */
	if (!icvar[CVAR_ENABLE] || !icvar[CVAR_CHAT])
		return;

	/* Don't log chat-clear more than once. */
	if (playerinfo_banned_flags[client][CHEAT_CHATCLEAR])
		return;

	if (does_string_contain_newline(sArgs)) {
		if (lilac_forward_allow_cheat_detection(client, CHEAT_CHATCLEAR) == false)
			return;

		playerinfo_banned_flags[client][CHEAT_CHATCLEAR] = true;
		lilac_forward_client_cheat(client, CHEAT_CHATCLEAR);

		if (icvar[CVAR_LOG]) {
			lilac_log_setup_client(client);
			Format(line_buffer, sizeof(line_buffer),
				"%s was detected and banned for Chat-Clear (Chat message: %s)",
				line_buffer, sArgs);

			lilac_log(true);

			if (icvar[CVAR_LOG_EXTRA])
				lilac_log_extra(client);
		}
		database_log(client, "chat_clear", DATABASE_BAN);

		lilac_ban_client(client, CHEAT_CHATCLEAR);
	}
}

/* Quick and fast, better to use this than validate the entire string twice. */
static bool does_string_contain_newline(const char []string)
{
	for (int i = 0; string[i]; i++) {
		/* Newline or carriage return. */
		if (string[i] == '\n' || string[i] == '\r')
			return true;
	}

	return false;
}

public Action event_namechange(Event event, const char[] name, bool dontBroadcast)
{
	int client;
	char client_name[MAX_NAME_LENGTH];

	client = GetClientOfUserId(GetEventInt(event, "userid", 0));

	if (skip_name_check(client))
		return Plugin_Continue;

	GetEventString(event, "newname", client_name, sizeof(client_name), "");
	check_name(client, client_name);

	return Plugin_Continue;
}

void lilac_string_check_name(int client)
{
	char name[MAX_NAME_LENGTH];

	if (skip_name_check(client))
		return;

	if (!GetClientName(client, name, sizeof(name)))
		return;

	check_name(client, name);
}

static bool skip_name_check(int client)
{
	if (!icvar[CVAR_ENABLE]
		|| !icvar[CVAR_FILTER_NAME]
		|| !is_player_valid(client)
		|| IsFakeClient(client))
		return true;

	return false;
}

static void check_name(int client, const char []name)
{
	int flags;

	if (is_string_valid(name, flags))
		return;

	/* Todo: Currently logging "const char []name" because on the
	 * event name_change, we don't actually log the player's
	 * most recent name, rather their previous name.
	 * I should fix that, but for now, lets do this instead (tmp fix). */

	/* Player was detected of having a newline or carriage return in their name, which is a cheat feature... */
	if (icvar[CVAR_FILTER_NAME] == 2 && (flags & STRFLAG_NEWLINE)) {
		if (playerinfo_banned_flags[client][CHEAT_NEWLINE_NAME])
			return;

		if (lilac_forward_allow_cheat_detection(client, CHEAT_NEWLINE_NAME) == false)
			return;

		playerinfo_banned_flags[client][CHEAT_NEWLINE_NAME] = true;
		lilac_forward_client_cheat(client, CHEAT_NEWLINE_NAME);

		if (icvar[CVAR_LOG]) {
			lilac_log_setup_client(client);
			Format(line_buffer, sizeof(line_buffer),
				"%s was banned of having newline characters in their name (%s).", line_buffer, name);

			lilac_log(true);

			if (icvar[CVAR_LOG_EXTRA])
				lilac_log_extra(client);
		}
		database_log(client, "name_newline", DATABASE_BAN);

		lilac_ban_client(client, CHEAT_NEWLINE_NAME);
	}
	else {
		/* Invalid name. */
		if (icvar[CVAR_LOG_MISC]) {
			lilac_log_setup_client(client);
			Format(line_buffer, sizeof(line_buffer),
				"%s was kicked for having invalid characters in their name (%s).", line_buffer, name);

			lilac_log(true);

			if (icvar[CVAR_LOG_EXTRA])
				lilac_log_extra(client);
		}
		database_log(client, "name_invalid", DATABASE_KICK);

		/* Log only. */
		if (icvar[CVAR_FILTER_NAME] > 0)
			KickClient(client, "[Lilac] %T", "kick_bad_name", client);
	}
}



/*
	UTF-8 validater and Blacklist...
	My old UTF-8 checker was soooo ugly, I had to change it.

	Note: 5 and 6 byte encodings aren't valid in UTF-8 anymore.
	Originally, UTF-8 could have up to 6 byte long encodings, but in
	2003 it was changed to be maximum 4 bytes, to match the limitations
	of UTF-16.

	2003 was long ago, and so the 4 byte maximum is used here.
*/


static bool is_string_valid(const char []string, int &flags)
{
	int widechars = 0;
	int i = 0;
	flags = 0;

	while (string[i]) {
		int codepoint = 0;
		int len = utf8_decode(string[i], codepoint); /* SPawn pointer logic sucks :( */

		/* Invalid UTF-8 encoding. */
		if (len == 0)
			return false;

		switch (codepoint) {
		case '\n', '\r': {
			flags = STRFLAG_NEWLINE;
			return false;
		}
		case 0xfdfd /* Bismillah. */ : {
			if (++widechars > 3)
				flags |= STRFLAG_WIDE_CHAR_SPAM;
		}
		}

		/* Other than the UTF-16 ranges and unicode limit,
		 * these are just blacklisted codepoints and are valid UTF-8.
		 * Private Use Areas and Control Characters are not allowed. */

		/* UTF-16 reserved surgate halves, not valid codepoint. */
		if (codepoint >= 0xd800 && codepoint <= 0xdfff)
			return false;
		else if (codepoint > 0x10ffff) /* Unicode limit. */
			return false;
		else if (codepoint < 0x20 && codepoint != '\t') /* C0 control chars.*/
			return false;
		else if (codepoint == 0x7f) /* Not really C0, but will count as one. */
			return false;
		else if (codepoint >= 0x80 && codepoint <= 0x9f) /* C1 control chars. */
			return false;
		else if (codepoint >= 0xe000 && codepoint <= 0xf8ff) /* PUA. */
			return false;
		else if (codepoint >= 0xf0000 && codepoint <= 0xfffff) /* PUA. */
			return false;
		else if (codepoint >= 0x100000 && codepoint <= 0x10fffd) /* PUA. */
			return false;

		i += len;
	}

	/* No invalid encodings or codepoints found :) */
	return true;
}

/* This function does not check for valid codepoints.
 * However, this will check for overlong encodings.
 * Returns the length of the encoding, 0 on error. */
static int utf8_decode(const char []ptr, int &codepoint)
{
	static const int mask[] = {0, 0, 0x1f, 0x0f, 0x07};

	int len = utf8_header_length(ptr[0]);
	if (len == 0) {
		return 0;
	}
	else if (len == 1) {
		codepoint = ptr[0];
		return 1;
	}

	codepoint = ptr[0] & mask[len];
	for (int i = 1; i < len; i++) {
		if ((ptr[i] & 0xc0) != 0x80)
			return 0;

		codepoint = (codepoint << 6) | (ptr[i] & 0x3f);
	}

	if (len != codepoint_to_utf8_length(codepoint))
		return 0;

	return len;
}

static int utf8_header_length(char c)
{
	/* Codepoint will always be above the U+10ffff limit. */
	if (c >= 0xf5)
		return 0;
	/* Can only be invalid codepoints; two byte ASCII. */
	else if (c == 0xc0 || c == 0xc1)
		return 0;

	switch ((c & 0xf0)) {
	/* Masking can include an extra bit for two byte encodings. */
	case 0xc0, 0xd0: return 2;
	case 0xe0: return 3;
	case 0xf0: return 4;
	default: return 1;
	}
}

static int codepoint_to_utf8_length(int codepoint)
{
	if (codepoint < 0x80)
		return 1;
	else if (codepoint < 0x800)
		return 2;
	else if (codepoint < 0x10000)
		return 3;
	else if (codepoint < 0x110000) /* U+10ffff + 1 */
		return 4;
	else
		return 0;
}
