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

void lilac_angles_check(int client, float angles[3])
{
	/* Angles in L4D1&2 aren't always normalized properly. */
	if (ggame == GAME_L4D2 || ggame == GAME_L4D)
		return;

	if (!IsPlayerAlive(client)
		|| playerinfo_time_teleported[client] + 5.0 > GetGameTime())
		return;

	/* In TF2, if players use the bumpercarts outside of
	 * official halloween map areas while standing on
	 * weird inclines, you can trigger a false positive.
	 * Yes... It's weird... Yes, this is rare and only happens
	 * on community servers where they provide carts outside
	 * of official halloween map areas...
	 * Anyway, thanks WOLFA22 for reporting this! */
#if !defined TF2C
	if (ggame == GAME_TF2) {
		if (TF2_IsPlayerInCondition(client, TFCond_HalloweenKart)) {
			playerinfo_time_bumpercart[client] = GetGameTime();
			return;
		}
		else if (GetGameTime() - playerinfo_time_bumpercart[client] < 5.0) {
			return;
		}
	}
#endif

	if ((FloatAbs(angles[0]) > max_angles[0] && max_angles[0])
		|| (FloatAbs(angles[2]) > max_angles[2] && max_angles[2]))
		lilac_detected_angles(client, angles);
}

void lilac_angles_patch(float angles[3])
{
	/* Patch Pitch. */
	if (max_angles[0] != 0.0) {
		if (angles[0] > max_angles[0])
			angles[0] = max_angles[0];
		else if (angles[0] < (max_angles[0] * -1.0))
			angles[0] = (max_angles[0] * -1.0);
	}

	/* Patch roll. */
	angles[2] = 0.0;
}

static void lilac_detected_angles(int client, float ang[3])
{
	if (playerinfo_banned_flags[client][CHEAT_ANGLES])
		return;

	/* Spam prevention. */
	if (playerinfo_time_forward[client][CHEAT_ANGLES] > GetGameTime())
		return;

	if (lilac_forward_allow_cheat_detection(client, CHEAT_ANGLES) == false) {
		/* Don't spam this forward again for the next 20 seconds. */
		playerinfo_time_forward[client][CHEAT_ANGLES] = GetGameTime() + 20.0;
		return;
	}

	playerinfo_banned_flags[client][CHEAT_ANGLES] = true;

	lilac_forward_client_cheat(client, CHEAT_ANGLES);

	if (icvar[CVAR_LOG]) {
		lilac_log_setup_client(client);
		Format(line_buffer, sizeof(line_buffer),
			"%s was detected and banned for Angle-Cheats (Pitch: %.2f, Yaw: %.2f, Roll: %.2f).",
			line_buffer, ang[0], ang[1], ang[2]);

		lilac_log(true);

		if (icvar[CVAR_LOG_EXTRA])
			lilac_log_extra(client);
	}

	/* no need to add more data, these 3 angles are already included. */
	database_log(client, "angles", DATABASE_BAN);

	lilac_ban_client(client, CHEAT_ANGLES);
}
