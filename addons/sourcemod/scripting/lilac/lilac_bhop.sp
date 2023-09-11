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

static int jump_ticks[MAXPLAYERS + 1];
static int perfect_bhops[MAXPLAYERS + 1];
static int next_bhop[MAXPLAYERS + 1];
static int detections[MAXPLAYERS + 1];


static void bhop_reset(int client)
{
	/* -1 because the initial jump doesn't count. */
	jump_ticks[client] = -1;
	perfect_bhops[client] = -1;
	next_bhop[client] = GetGameTickCount();
}

void lilac_bhop_reset_client(int client)
{
	bhop_reset(client);
	detections[client] = 0;
}

void lilac_bhop_check(int client, const int buttons, int last_buttons)
{
	/* Player already banned / logged enough, no need to test anything. */
	if (playerinfo_banned_flags[client][CHEAT_BHOP])
		return;

	if ((buttons & IN_JUMP))
		jump_ticks[client]++;

	int flags = GetEntityFlags(client);
	if ((buttons & IN_JUMP) && !(last_buttons & IN_JUMP)) {
		if ((flags & FL_ONGROUND)) {
			if (GetGameTickCount() > next_bhop[client]) {
				next_bhop[client] = GetGameTickCount() + bhop_settings[BHOP_INDEX_AIR];
				perfect_bhops[client]++;
				check_bhop_max(client);
			}
			else {
				bhop_reset(client);
			}
		}
	}
	else if ((flags & FL_ONGROUND)) {
		check_bhop_min(client);
		bhop_reset(client);
	}
}

static void check_bhop_max(int client)
{
	/* Invalid max, disable max bhop bans. */
	if (bhop_settings[BHOP_INDEX_MAX] < bhop_settings_min[BHOP_INDEX_MAX])
		return;

	if (perfect_bhops[client] < bhop_settings[BHOP_INDEX_MAX])
		return;

	if (lilac_forward_allow_cheat_detection(client, CHEAT_BHOP) == false)
		return;

	/* Client just hit the max threshhold, insta ban. */
	lilac_detected_bhop(client, true, true);
	lilac_ban_bhop(client);
}

static void check_bhop_min(int client)
{
	/* Invalid min-Bhop settings. */
	if (bhop_settings[BHOP_INDEX_MIN] < bhop_settings_min[BHOP_INDEX_MIN])
		return;

	if (perfect_bhops[client] < bhop_settings[BHOP_INDEX_MIN])
		return;

	/* Jump ticks buffer is set and jump ticks is higher than max, ignore. */
	if (bhop_settings[BHOP_INDEX_JUMP] > -1
		&& jump_ticks[client] > bhop_settings[BHOP_INDEX_JUMP]
		+ bhop_settings[BHOP_INDEX_MIN])
		return;

	if (lilac_forward_allow_cheat_detection(client, CHEAT_BHOP) == false)
		return;

	lilac_detected_bhop(client, false, false);
}

static void lilac_detected_bhop(int client, bool force_log, bool banning)
{
	lilac_forward_client_cheat(client, CHEAT_BHOP);

	/* Detection expires in 10 minutes. */
	CreateTimer(600.0, timer_decrement_bhop, GetClientUserId(client));

	/* Don't log the first detection. */
	if (++detections[client] < 2 && force_log == false)
		return;

	if (icvar[CVAR_CHEAT_WARN]
		&& !banning
		&& detections[client] < bhop_settings[BHOP_INDEX_TOTAL])
		lilac_warn_admins(client, CHEAT_BHOP, detections[client]);

	if (icvar[CVAR_LOG]) {
		lilac_log_setup_client(client);
		Format(line_buffer, sizeof(line_buffer),
			"%s is suspected of using Bhop (Detection: %d | Bhops: %d | JumpTicks: %d).",
			line_buffer, detections[client], perfect_bhops[client],
			jump_ticks[client]);
		lilac_log(true);

		if (icvar[CVAR_LOG_EXTRA] == 2)
			lilac_log_extra(client);
	}
	database_log(client, "bhop", detections[client], float(perfect_bhops[client]), float(jump_ticks[client]));

	if (detections[client] >= bhop_settings[BHOP_INDEX_TOTAL])
		lilac_ban_bhop(client);
}

static void lilac_ban_bhop(int client)
{
	/* Already been banned, ignore. */
	if (playerinfo_banned_flags[client][CHEAT_BHOP])
		return;

	playerinfo_banned_flags[client][CHEAT_BHOP] = true;

	if (icvar[CVAR_LOG]) {
		lilac_log_setup_client(client);
		Format(line_buffer, sizeof(line_buffer),
			"%s was detected and banned for Bhop.",
			line_buffer);
		lilac_log(true);

		if (icvar[CVAR_LOG_EXTRA])
			lilac_log_extra(client);
	}
	database_log(client, "bhop", DATABASE_BAN);

	lilac_ban_client(client, CHEAT_BHOP);
}

public Action timer_decrement_bhop(Handle timer, int userid)
{
	int client;

	client = GetClientOfUserId(userid);

	if (!is_player_valid(client))
		return Plugin_Continue;

	if (detections[client] > 0)
		detections[client]--;

	return Plugin_Continue;
}
