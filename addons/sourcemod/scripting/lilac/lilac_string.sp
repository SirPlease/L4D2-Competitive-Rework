/*
	Little Anti-Cheat
	Copyright (C) 2018-2021 J_Tanzanite

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

	// Prevent players banned for Chat-Clear from spamming chat.
	//     Helps legit players see the cheater was banned.
	if (playerinfo_banned_flags[client][CHEAT_CHATCLEAR])
		return Plugin_Stop;

	if (!icvar[CVAR_FILTER_CHAT])
		return Plugin_Continue;

	// Just for future reference, because it may be unclear
	//     how "is_string_valid()" works.
	// Normally, it will set the "flags" variable with bits
	//     telling you what's wrong with a string and return false.
	// But the wide-char-spam bit is an exception,
	//     it will set the bit, but won't return false.
	// This is because wide-char spam gets its own message
	//     when blocking the chat.
	// Plus, it's still technically a valid string.

	// Invalid string and no newlines/carriage returns.
	// Newlines in chat will we dealt with in post.
	// This is just so people can see that the player did indeed
	//     clear the chat before banning, otherwise people
	//     would be confused and think the ban was an error.
	if (!(is_string_valid(sArgs, flags)) && !(flags & (STRFLAG_NEWLINE | STRFLAG_CRETURN))) {
		PrintToChat(client, "[Lilac] %T", "chat_invalid_characters", client);
		return Plugin_Stop;
	}
	else if ((flags & STRFLAG_WIDE_CHAR_SPAM)) {
		// Wide char spam (Example: Bismillah spam),
		//     as explained by 3kliksphilip here: https://youtu.be/hP1N1YRitlM?t=94
		//     this clears the chat and is annoying.
		// Block this exploit.
		PrintToChat(client, "[Lilac] %T", "chat_wide_char_spam", client);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	// Chat-Clear doesn't work in CS:GO.
	if (ggame == GAME_CSGO)
		return;

	// Todo: CVAR_CHAT is... Now an outdated name...
	if (!icvar[CVAR_ENABLE] || !icvar[CVAR_CHAT])
		return;

	// Don't log chat-clear more than once.
	if (playerinfo_banned_flags[client][CHEAT_CHATCLEAR])
		return;

	if (does_string_contain_newline(sArgs)) {
		if (lilac_forward_allow_cheat_detection(client, CHEAT_CHATCLEAR) == false)
			return;

		playerinfo_banned_flags[client][CHEAT_CHATCLEAR] = true;
		lilac_forward_client_cheat(client, CHEAT_CHATCLEAR);

		if (icvar[CVAR_LOG]) {
			lilac_log_setup_client(client);
			Format(line, sizeof(line),
				"%s was detected and banned for Chat-Clear (Chat message: %s)",
				line, sArgs);

			lilac_log(true);

			if (icvar[CVAR_LOG_EXTRA])
				lilac_log_extra(client);
		}
		database_log(client, "chat_clear", DATABASE_BAN);

		lilac_ban_client(client, CHEAT_CHATCLEAR);
	}
}

// Quick and fast, better to use this than validate the entire string twice.
static bool does_string_contain_newline(const char []string)
{
	for (int i = 0; string[i]; i++) {
		// Newline or carriage return.
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

	// Todo: Currently logging "const char []name" because on the
	//     event name_change, we don't actually log the player's
	//     most recent name, rather their previous name.
	// I should fix that, but for now, lets do this instead (tmp fix).

	// Player was detected of having a newline or carriage return in their name, which is a cheat feature...
	if (icvar[CVAR_FILTER_NAME] == 2 && (flags & (STRFLAG_NEWLINE | STRFLAG_CRETURN))) {
		if (playerinfo_banned_flags[client][CHEAT_NEWLINE_NAME])
			return;

		if (lilac_forward_allow_cheat_detection(client, CHEAT_NEWLINE_NAME) == false)
			return;

		playerinfo_banned_flags[client][CHEAT_NEWLINE_NAME] = true;
		lilac_forward_client_cheat(client, CHEAT_NEWLINE_NAME);

		if (icvar[CVAR_LOG]) {
			lilac_log_setup_client(client);
			Format(line, sizeof(line),
				"%s was banned of having newline characters in their name (%s).", line, name);

			lilac_log(true);

			if (icvar[CVAR_LOG_EXTRA])
				lilac_log_extra(client);
		}
		database_log(client, "name_newline", DATABASE_BAN);

		lilac_ban_client(client, CHEAT_NEWLINE_NAME);
	}
	else {
		// Invalid name.
		if (icvar[CVAR_LOG_MISC]) {
			lilac_log_setup_client(client);
			Format(line, sizeof(line),
				"%s was kicked for having invalid characters in their name (%s).", line, name);

			lilac_log(true);

			if (icvar[CVAR_LOG_EXTRA])
				lilac_log_extra(client);
		}
		database_log(client, "name_invalid", DATABASE_KICK);

		// Log only.
		if (icvar[CVAR_FILTER_NAME] > 0)
			KickClient(client, "[Lilac] %T", "kick_bad_name", client);
	}
}



/*
	UTF-8 code from an old C project of mine... Fixed it up a bit.

	Note: 5 and 6 byte encodings aren't valid in UTF-8 anymore.
	Originally, UTF-8 could have up to 6 byte long encodings, but in
	2003 it was changed to be maximum 4 bytes, to match the limitations
	of UTF-16.

	2003 was long ago, and so the 4 byte maximum is used here.
*/



static bool is_string_valid(const char []string, int &flags)
{
	int widechar = 0;
	flags = 0;

	for (int i = 0; string[i]; i++) {
		int length = utf8_get_header_length(string[i]);

		// Multi-Byte.
		if (length > 1) {
			// Check if it's valid UTF-8.
			int codepoint = utf8_decode(string[i], flags);

			if (codepoint == -1)
				return false;

			// Wide character spam (Maximum 3 uses).
			switch (codepoint) {
			case 0xfdfd: { // Bismillah.
				if (++widechar > 3)
					flags |= STRFLAG_WIDE_CHAR_SPAM;
			}
			}

			if (codepoint >= 0x80 && codepoint <= 0x9f) {
				// C1 Control characters are illegal.
				flags |= STRFLAG_CTRL_1;
				return false;
			}

			i += length - 1;
		}
		else { // ASCII.
			if (string[i] == '\n') { // Newline.
				flags |= STRFLAG_NEWLINE;
				return false;
			}
			else if (string[i] == 0x0d) { // Carriage return.
				flags |= STRFLAG_CRETURN;
				return false;
			}
			else if (string[i] < 32) { // Control character.
				flags |= STRFLAG_CTRL_0;
				return false;
			}
			else if (string[i] == 0x7f) { // Del.
				flags |= STRFLAG_DEL;
				return false;
			}
		}
	}

	return true;
}

static bool utf8_is_valid_header(char c, int &flags)
{
	// 0xf5 is always higher than the U+10ffff limit.
	// Also, prevents 5 byte long encodings.
	if (c >= 0xf5) {
		flags |= STRFLAG_OVER_LIMIT;
		return false;
	}

	// Two byte encoding for single ASCII byte.
	if (c == 0xc0 || c == 0xc1) {
		flags |= STRFLAG_OVERLONG;
		return false;
	}

	// Must have 2 high order bits set.
	if ((c & 0b11000000) != 0b11000000) {
		flags |= STRFLAG_BAD_HEADER;
		return false;
	}

	return true;
}

static int utf8_get_header_length(char c)
{
	switch ((c & 0b11110000)) {
	// Masking can sometimes include this extra bit.
	case 0b11010000, 0b11000000: return 2;
	case 0b11100000: return 3;
	case 0b11110000: return 4; // The one extra bit (5 byte long encoding) issue is covered above by the 0xf5 check.
	}

	return 1;
}

static int utf8_decode(const char []c, int &flags)
{
	static int header_bits[] = {
		0, 0, // Fillers.
		0b00011111,
		0b00001111,
		0b00000111
	};

	int codepoint = 0;
	int length = utf8_get_header_length(c[0]);

	for (int i = 0; i < length; i++) {
		// Invalid byte.
		if (!(c[i] & 0b10000000)) {
			flags |= STRFLAG_BAD_HEADER;
			return -1;
		}

		if (!i) {
			if (utf8_is_valid_header(c[i], flags) == false) {
				flags |= STRFLAG_BAD_HEADER;
				return -1;
			}

			codepoint = (header_bits[length] & c[i]);
		}
		else {
			if ((c[i] & 0b11000000) != 0b10000000) {
				flags |= STRFLAG_BAD_CONT;
				return -1;
			}

			codepoint <<= 6;
			codepoint += (0b00111111 & c[i]);
		}
	}

	// Check for overlong encoding.
	if (codepoint_to_length(codepoint) != length) {
		flags |= STRFLAG_OVERLONG;
		return -1;
	}

	// Reserved for UTF-16.
	if (codepoint >= 0xd800 && codepoint <= 0xdfff) {
		flags |= STRFLAG_UTF16;
		return -1;
	}

	// Greater values than this aren't valid.
	if (codepoint > 0x10ffff) {
		flags |= STRFLAG_OVER_LIMIT;
		return -1;
	}

	return codepoint;
}

static int codepoint_to_length(int n)
{
	if (n <= 0b1111111) // 7 bits
		return 1;
	else if (n <= 0b11111111111) // 11 bits
		return 2;
	else if (n <= 0b1111111111111111) // 16 bits
		return 3;
	else if (n <= 0b111111111111111111111) // 21 bits
		return 4;

	return 0;
}
