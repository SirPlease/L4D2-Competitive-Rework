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

static int macro_history[MAXPLAYERS + 1][MACRO_ARRAY][MACRO_LOG_LENGTH];
static int macro_detected[MAXPLAYERS + 1][MACRO_ARRAY];

void lilac_macro_reset_client(int client)
{
	for (int i = 0; i < MACRO_ARRAY; i++) {
		macro_detected[client][i] = 0;
		lilac_macro_reset_client_history(client, i);
	}
}

static void lilac_macro_reset_client_history(int client, int type)
{
	if (type < 0 || type >= MACRO_ARRAY)
		return;

	for (int i = 0; i < MACRO_LOG_LENGTH; i++)
		macro_history[client][type][i] = false;
}

void lilac_macro_check(int client, const int buttons, int last_buttons)
{
	static int index[MAXPLAYERS + 1];

	if (++index[client] >= tick_rate)
		index[client] = 0;

	for (int i = 0; i < MACRO_ARRAY; i++) {
		/* Skip macros we aren't checking for. */
		if (!process_macro_type(i))
			continue;

		int input = get_macro_input(i);

		/* Player pressed the key. */
		bool key = (!(last_buttons & input) && (buttons & input)) ? true : false;
		macro_history[client][i][index[client]] = key;

		/* Only check for spam when the key is pressed. */
		if (!key)
			continue;

		int acc = 0;

		for (int k = 0; k < tick_rate; k++) {
			if (macro_history[client][i][k])
				acc++;
		}

		if (acc >= macro_max)
			lilac_detected_macro(client, i);
	}
}

static bool process_macro_type(int macro_type)
{
	/* Invalid macro type. */
	if (macro_type >= MACRO_ARRAY || macro_type < 0)
		return false;

	/* 0 == Test for all types. */
	if (!icvar[CVAR_MACRO_MODE])
		return true;

	/* Check bit. */
	return (icvar[CVAR_MACRO_MODE] & (1 << macro_type)) ? true : false;
}

static int get_macro_input(int macro_type)
{
	switch (macro_type) {
	case MACRO_AUTOJUMP: return IN_JUMP;
	case MACRO_AUTOSHOOT: return IN_ATTACK;
	default: return 0;
	}
}

static void lilac_detected_macro(int client, int type)
{
	char string[20];

	/* Clear history, prevents overlap. */
	lilac_macro_reset_client_history(client, type);

	/* Already been logged once, ignore. */
	if (playerinfo_banned_flags[client][CHEAT_MACRO])
		return;

	/* Spam prevention. */
	if (playerinfo_time_forward[client][CHEAT_MACRO] > GetGameTime())
		return;

	if (lilac_forward_allow_cheat_detection(client, CHEAT_MACRO) == false) {
		playerinfo_time_forward[client][CHEAT_MACRO] = GetGameTime() + 5.0;
		return;
	}

	switch (type) {
	case MACRO_AUTOJUMP: { strcopy(string, sizeof(string), "Auto-Jump"); }
	case MACRO_AUTOSHOOT: { strcopy(string, sizeof(string), "Auto-Shoot"); }
	default: { return; } /* Invalid type. */
	}

	lilac_forward_client_cheat(client, CHEAT_MACRO);

	/* Ignore the first detection. */
	if (++macro_detected[client][type] < 2)
		return;

	/* Log (2 == detect, but no logging). */
	if (icvar[CVAR_LOG] && icvar[CVAR_MACRO] < 2) {
		lilac_log_setup_client(client);
		Format(line_buffer, sizeof(line_buffer),
			"%s was detected of using Macro %s (Detection: %d | Max presses: %d).",
			line_buffer, string, macro_detected[client][type], macro_max);

		lilac_log(true);

		if (icvar[CVAR_LOG_EXTRA])
			lilac_log_extra(client);
	}

	int char_index;
	while (string[char_index]) {
		string[char_index] = CharToLower(string[char_index]); /* lower each character */
		char_index++;
	}
	Format(string, sizeof(string), "macro_%s", string);
	database_log(client, string, macro_detected[client][type], float(macro_max));

	/* If we are using log-only, then don't warn, there's no point. */
	if (icvar[CVAR_MACRO] > -1) {
		/* Warnings. */
		switch (icvar[CVAR_MACRO_WARNING]) {
		case 1: {
			PrintCenterText(client, "[Little Anti-Cheat] Warning: Macro usage isn't allowed!");
			PrintToChat(client, "[Little Anti-Cheat] Warning: Macro usage isn't allowed!");
		}
		case 2: {
			for (int i = 1; macro_detected[client][type] == 2 && i <= MaxClients; i++) {
				if (!is_player_valid(i) || IsFakeClient(i))
					continue;

				if (!is_player_admin(i))
					continue;

				PrintToChat(i, "[Little Anti-Cheat] %N was detected of using Macro %s.",
					client, string);
			}
		}
		case 3: {
			/* Warn everyone once... */
			if (macro_detected[client][type] == 2)
				PrintToChatAll("[Little Anti-Cheat] %N was detected of using Macro %s.",
					client, string);
		}
		}
	}

	if (macro_detected[client][type] < 5)
		return;

	playerinfo_banned_flags[client][CHEAT_MACRO] = true;

	if (icvar[CVAR_MACRO] == -1)
		return;

	if (icvar[CVAR_MACRO_DEAL_METHOD] == 0)
		KickClient(client, "[Lilac] %T", "kick_macro", client, string);
	else
		lilac_ban_client(client, CHEAT_MACRO);
}

/* Macro detections decrement every 5 minutes.
 * Todo: Might wanna make it more frequent? */
public Action timer_decrement_macro(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++) {
		for (int k = 0; k < MACRO_ARRAY; k++) {
			if (macro_detected[i][k] > 0)
				macro_detected[i][k]--;
		}
	}

	return Plugin_Continue;
}
