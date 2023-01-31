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

static float min_lerp_possible = 0.0;
static bool ignore_nolerp[MAXPLAYERS + 1];
static bool ignore_nolerp_all = false;

void lilac_lerp_reset_client(int client)
{
	ignore_nolerp[client] = false;
}

void lilac_lerp_ignore_nolerp_client(int client)
{
	ignore_nolerp[client] = true;
}

void lilac_lerp_ratio_changed(int value)
{
	/* Permamently disable nolerp checks.
	 * Yes, this is a little harsh, but if servers allow
	 * any interp ratio, they are unlikely to change
	 * it back to any restrictive value. */
	if (value < 1)
		ignore_nolerp_all = true;
}

void lilac_lerp_maxupdaterate_changed(int value)
{
	if (ignore_nolerp_all)
		return;

	min_lerp_possible = ((value > 0) ? 1.0 / float(value) : 0.0);
}

public Action timer_check_lerp(Handle timer)
{
	if (!icvar[CVAR_ENABLE])
		return Plugin_Continue;

	for (int i = 1; i <= MaxClients; i++) {
		if (!is_player_valid(i) || IsFakeClient(i))
			continue;

		float lerp = GetEntPropFloat(i, Prop_Data, "m_fLerpTime");

		if (lerp * 1000.0 > float(icvar[CVAR_MAX_LERP]) && icvar[CVAR_MAX_LERP] >= 105) {
			detected_lerp_exploit(i, lerp);
			continue;
		}

		if (!icvar[CVAR_NOLERP]
			|| ignore_nolerp_all
			|| ignore_nolerp[i]
			|| playerinfo_banned_flags[i][CHEAT_NOLERP]
			|| min_lerp_possible < 0.005) /* Minvalue invalid or too low. */
			continue;

		if (lerp > min_lerp_possible * 0.95 /* buffer */)
			continue;

		detected_nolerp(i, lerp);
	}

	return Plugin_Continue;
}

static void detected_lerp_exploit(int client, float lerp)
{
	if (icvar[CVAR_LOG_MISC]) {
		lilac_log_setup_client(client);
		Format(line_buffer, sizeof(line_buffer),
			"%s was kicked for exploiting interpolation (%.3fms / %dms max).",
			line_buffer, lerp * 1000.0, icvar[CVAR_MAX_LERP]);

		lilac_log(true);
		if (icvar[CVAR_LOG_EXTRA] == 2)
			lilac_log_extra(client);
	}
	database_log(client, "lerp_exploit", DATABASE_KICK, lerp * 1000.0, float(icvar[CVAR_MAX_LERP]));

	KickClient(client, "[Lilac] %T", "kick_interp_exploit", client,
		lerp * 1000.0, icvar[CVAR_MAX_LERP],
		float(icvar[CVAR_MAX_LERP]) / 999.9);
}

static void detected_nolerp(int client, float lerp)
{
	if (lilac_forward_allow_cheat_detection(client, CHEAT_NOLERP) == false)
		return;

	playerinfo_banned_flags[client][CHEAT_NOLERP] = true;

	lilac_forward_client_cheat(client, CHEAT_NOLERP);

	if (icvar[CVAR_LOG]) {
		lilac_log_setup_client(client);
		Format(line_buffer, sizeof(line_buffer), "%s was detected and banned for NoLerp (%fms).",
			line_buffer, lerp * 1000.0);

		lilac_log(true);

		if (icvar[CVAR_LOG_EXTRA])
			lilac_log_extra(client);
	}
	database_log(client, "nolerp", DATABASE_BAN, lerp * 1000.0);

	lilac_ban_client(client, CHEAT_NOLERP);
}
