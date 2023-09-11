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

/* Delet dis! */
#if defined TF2C
	#endinput
#endif

void lilac_anti_duck_delay_check(int client, const int buttons)
{
	if (!(buttons & IN_BULLRUSH))
		return;

	if (playerinfo_banned_flags[client][CHEAT_ANTI_DUCK_DELAY])
		return;

	/* Spam prevention. */
	if (playerinfo_time_forward[client][CHEAT_ANTI_DUCK_DELAY] > GetGameTime())
		return;

	if (lilac_forward_allow_cheat_detection(client, CHEAT_ANTI_DUCK_DELAY) == false) {
		/* Don't spam this forward again for the next 10 seconds. */
		playerinfo_time_forward[client][CHEAT_ANTI_DUCK_DELAY] = GetGameTime() + 10.0;
		return;
	}

	playerinfo_banned_flags[client][CHEAT_ANTI_DUCK_DELAY] = true;

	lilac_forward_client_cheat(client, CHEAT_ANTI_DUCK_DELAY);

	if (icvar[CVAR_LOG]) {
		lilac_log_setup_client(client);
		Format(line_buffer, sizeof(line_buffer), "%s was detected and banned for Anti-Duck-Delay.", line_buffer);

		lilac_log(true);

		if (icvar[CVAR_LOG_EXTRA])
			lilac_log_extra(client);
	}
	database_log(client, "anti_duck_delay", DATABASE_BAN);

	lilac_ban_client(client, CHEAT_ANTI_DUCK_DELAY);
}
