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


static int ping_high[MAXPLAYERS + 1];
static int ping_warn[MAXPLAYERS + 1];

void lilac_ping_reset_client(int client)
{
	ping_high[client] = 0;
	ping_warn[client] = 0;
}

public Action timer_check_ping(Handle timer)
{
	static bool toggle = true;
	char reason[128];
	float ping;

	if (!icvar[CVAR_ENABLE] || icvar[CVAR_MAX_PING] < 100)
		return Plugin_Continue;

	for (int i = 1; i <= MaxClients; i++) {
		if (!is_player_valid(i) || IsFakeClient(i))
			continue;

		/* Player recently joined, don't check ping yet. */
		if (GetClientTime(i) < 120.0)
			continue;

		ping = GetClientAvgLatency(i, NetFlow_Outgoing) * 1000.0;

		if (ping < float(icvar[CVAR_MAX_PING])) {
			if (toggle && ping_high[i] > 0)
				ping_high[i]--;

			if (ping_high[i] < ping_warn[i] - 2 && ping_warn[i] > 0) {

				ping_warn[i] = 0;
				PrintToChat(i, "[Lilac] Your ping appears to be fine again, it is safe to rejoin a team and play.");
			}

			continue;
		}

		if (++ping_high[i] >= icvar[CVAR_MAX_PING_SPEC] / 5
			&& icvar[CVAR_MAX_PING_SPEC] >= 30) {
			ChangeClientTeam(i, 1); /* Move this player to spectators. */

			ping_warn[i] = ping_high[i];

			PrintToChat(i, "[Lilac] WARNING: You will be kicked in %d seconds if your ping stays too high! (%.0f / %d max)",
				100 - (ping_high[i] * 5),
				ping, icvar[CVAR_MAX_PING]);
		}

		/* Player has a higher ping than maximum for 100 seconds. */
		if (ping_high[i] < 20)
			continue;

		if (icvar[CVAR_LOG_MISC]) {
			lilac_log_setup_client(i);
			Format(line_buffer, sizeof(line_buffer),
				"%s was kicked for having too high ping (%.3fms / %dms max).",
				line_buffer, ping, icvar[CVAR_MAX_PING]);

			lilac_log(true);

			if (icvar[CVAR_LOG_EXTRA] == 2)
				lilac_log_extra(i);
		}
		database_log(i, "high_ping", DATABASE_KICK);

		Format(reason, sizeof(reason), "[Lilac] %T", "tban_ping_high", i,
			ping, icvar[CVAR_MAX_PING]);

		/* Ban the client for three minutes to avoid instant reconnects. */
		BanClient(i, 3, BANFLAG_AUTHID, reason, reason, "lilac", 0);
	}

	toggle = !toggle;

	return Plugin_Continue;
}
