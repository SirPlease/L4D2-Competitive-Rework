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

static int aimbot_detection[MAXPLAYERS + 1];
static int aimbot_autoshoot[MAXPLAYERS + 1];
static int aimbot_timertick[MAXPLAYERS + 1];

void lilac_aimbot_reset_client(int client)
{
	aimbot_detection[client] = 0;
	aimbot_autoshoot[client] = 0;
	aimbot_timertick[client] = 0;
}

int lilac_aimbot_get_client_detections(int client)
{
	return aimbot_detection[client];
}

public Action event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int attackerid;
	int victimid;
	int client;
	
	if (!icvar[CVAR_ENABLE])
		return Plugin_Continue;
	
	attackerid = GetEventInt(event, "attacker", -1);
	victimid = GetEventInt(event, "userid", -1);
	client = GetClientOfUserId(victimid);
	
	if (!is_player_valid(client))
		return Plugin_Continue;
	
	/* This prevents running multiple aimbot checks on the same tick.
	 * This can happen with explosives, like some projectiles.
	 * This variable gets set in the "shared event" function. */
	if (aimbot_timertick[client] == GetGameTickCount())
		return Plugin_Continue;
	
	event_death_shared(attackerid,
		GetClientOfUserId(attackerid),
		client, false);
	
	return Plugin_Continue;
}

public Action event_player_death_tf2(Event event, const char[] name, bool dontBroadcast)
{
	char wep[64];
	int userid, client, victim, killtype;

	if (!icvar[CVAR_ENABLE])
		return Plugin_Continue;


	victim = GetClientOfUserId(GetEventInt(event, "userid", -1));

	if (!is_player_valid(victim))
		return Plugin_Continue;
	
	/* Same as above, prevent multiple aimbot checks on the same tick. */
	if (aimbot_timertick[victim] == GetGameTickCount())
		return Plugin_Continue;

	GetEventString(event, "weapon_logclassname", wep, sizeof(wep), "");

	/* Ignore sentries & world in TF2. */
	if (!strncmp(wep, "obj_", 4, false) || !strncmp(wep, "world", 5, false))
		return Plugin_Continue;

	userid = GetEventInt(event, "attacker", -1);
	client = GetClientOfUserId(userid);
	killtype = GetEventInt(event, "customkill", 0);

	/* killtype 3 == flamethrower,
	 * ignore snap detections as pyros sometimes,
	 * sway their aim around. */
	event_death_shared(userid, client, victim, ((killtype == 3) ? true : false));

	return Plugin_Continue;
}

void event_death_shared(int userid, int client, int victim, bool skip_delta)
{
	DataPack pack;
	float killpos[3], deathpos[3];
	int skip_snap = 0;

	if (client == victim
		|| !is_player_valid(client)
		/* || !is_player_valid(victim) Already checked. */
		|| IsFakeClient(client)
		|| !IsPlayerAlive(client)
		|| playerinfo_banned_flags[client][CHEAT_AIMBOT]
		|| GetClientTime(client) < 10.1)
		return;

	if (icvar[CVAR_AIMLOCK_LIGHT])
		lilac_aimlock_light_test(client);

	if (!icvar[CVAR_AIMBOT])
		return;

	/* Prevent multiple aimbot timer checks on the same tick. */
	aimbot_timertick[client] = GetGameTickCount();

	GetClientEyePosition(client, killpos);
	GetClientEyePosition(victim, deathpos);

	/* Killer and victim are too close to each other, skip some detections. */
	if (GetVectorDistance(killpos, deathpos) < 350.0 || skip_delta)
		skip_snap = 1;

	CreateDataTimer(0.5, timer_check_aimbot, pack);
	pack.WriteCell(userid);
	pack.WriteCell(skip_snap);
	pack.WriteCell(playerinfo_index[client]); /* Fallback to this tick if the shot isn't found. */
	pack.WriteFloat(killpos[0]);
	pack.WriteFloat(killpos[1]);
	pack.WriteFloat(killpos[2]);
	pack.WriteFloat(deathpos[0]);
	pack.WriteFloat(deathpos[1]);
	pack.WriteFloat(deathpos[2]);
}

public Action timer_check_aimbot(Handle timer, DataPack pack)
{
	int ind;
	int client;
	int fallback;
	int shotindex = -1;
	int detected = 0;
	float delta = 0.0;
	float tdelta = 0.0;
	float total_delta = 0.0;
	float aimdist, laimdist;
	float ideal[3], ang[3], lang[3];
	float killpos[3], deathpos[3];
	bool skip_snap = false;
	bool skip_autoshoot = false;
	bool skip_repeat = false;

	pack.Reset();
	client = GetClientOfUserId(pack.ReadCell());
	skip_snap = pack.ReadCell();
	fallback = pack.ReadCell();
	killpos[0] = pack.ReadFloat();
	killpos[1] = pack.ReadFloat();
	killpos[2] = pack.ReadFloat();
	deathpos[0] = pack.ReadFloat();
	deathpos[1] = pack.ReadFloat();
	deathpos[2] = pack.ReadFloat();

	/* Killer may have left the game, cancel. */
	if (!is_player_valid(client))
		return Plugin_Continue;

	/* Locate when the shot was fired. */
	ind = playerinfo_index[client];
	/* 0.5 (datapacktimer delay) + 0.5 (snap test) + 0.1 (buffer).
	 * We are looking this far back in case of a projectile aimbot shot,
	 * as the death event happens way later after the shot. */
	for (int i = 0; i < CMD_LENGTH - time_to_ticks(0.5 + 0.5 + 0.1); i++) {
		if (--ind < 0)
			ind += CMD_LENGTH;

		/* The shot needs to have happened at least 0.3 seconds ago. */
		if (GetGameTime() - playerinfo_time_usercmd[client][ind] < 0.3)
			continue;

		if ((playerinfo_actions[client][ind] & ACTION_SHOT)) {
			shotindex = ind;
			break;
		}
	}

	/* Shot not found, use fallback. */
	if (shotindex == -1) {
		shotindex = fallback;

		/* If the latest index is the same as the fallback, then no
		 * more usercmds have been processed since the death event.
		 * These detections are thus unstable and will be ignored
		 * (They require at least one tick after the shot to work). */
		if (playerinfo_index[client] == fallback) {
			skip_autoshoot = true;
			skip_repeat = true;
		}
	}
	else {
		/* Don't detect the same shot twice. */
		playerinfo_actions[client][shotindex] = 0;
	}

	/* Skip repeat detections if players are too close to each other. */
	if (skip_snap)
		skip_repeat = true;

	/* Player taunted within 0.5 seconds
	 * of taking a shot leading to a kill.
	 * Ignore snap detections. */
	if (-0.1 < playerinfo_time_usercmd[client][shotindex] - playerinfo_time_teleported[client] < 0.5 + 0.1)
		skip_snap = true;

	/* Aimsnap and total delta test. */
	if (skip_snap == false) {
		aim_at_point(killpos, deathpos, ideal);

		ind = shotindex;
		/* Check angle history 0.5 seconds prior to a shot. */
		for (int i = 0; i < time_to_ticks(0.5); i++) {
			if (ind < 0)
				ind += CMD_LENGTH;

			/* We're looking back further than 0.5 seconds prior to the shot, abort. */
			if (playerinfo_time_usercmd[client][shotindex] - playerinfo_time_usercmd[client][ind] > 0.5)
				break;

			laimdist = angle_delta(playerinfo_angles[client][ind], ideal);
			get_player_log_angles(client, ind, false, ang);

			/* Skip first iteration as we need angle deltas. */
			if (i) {
				tdelta = angle_delta(lang, ang);

				/* Store largest delta. */
				if (tdelta > delta)
					delta = tdelta;

				total_delta += tdelta;

				if (aimdist < laimdist * 0.2 && tdelta > 10.0)
					detected |= AIMBOT_FLAG_SNAP;

				if (aimdist < laimdist * 0.1 && tdelta > 5.0)
					detected |= AIMBOT_FLAG_SNAP2;
			}

			lang = ang;
			aimdist = laimdist;
			ind--;
		}
	}

	/* Packetloss is too high, skip all detections but total_delta. */
	if (skip_due_to_loss(client)) {
		skip_autoshoot = true;
		skip_repeat = true;
		detected = 0;
	}

	/* Angle-repeat test. */
	if (skip_repeat == false) {
		get_player_log_angles(client, shotindex - 1, false, ang);
		get_player_log_angles(client, shotindex + 1, false, lang);
		tdelta = angle_delta(ang, lang);
		get_player_log_angles(client, shotindex, false, lang);

		if (tdelta < 10.0 && angle_delta(ang, lang) > 0.5
			&& angle_delta(ang, lang) > tdelta * 5.0)
			detected |= AIMBOT_FLAG_REPEAT;
	}

	/* Autoshoot test. */
	if (skip_autoshoot == false && icvar[CVAR_AIMBOT_AUTOSHOOT]) {
		int tmp = 0;
		ind = shotindex + 1;
		for (int i = 0; i < 3; i++) {
			if (ind < 0)
				ind += CMD_LENGTH;
			else if (ind >= CMD_LENGTH)
				ind -= CMD_LENGTH;

			if ((playerinfo_buttons[client][ind] & IN_ATTACK))
				tmp++;

			ind--;
		}

		/* Onetick perfect shot.
		 * Players must get two of them in a row leading to a kill
		 * or something else must have been detected to get this flag. */
		if (tmp == 1) {
			if (detected || ++aimbot_autoshoot[client] > 1)
				detected |= AIMBOT_FLAG_AUTOSHOOT;
		}
		else {
			aimbot_autoshoot[client] = 0;
		}
	}

	if (detected || total_delta > AIMBOT_MAX_TOTAL_DELTA)
		lilac_detected_aimbot(client, delta, total_delta, detected);

	return Plugin_Continue;
}

static void lilac_detected_aimbot(int client, float delta, float td, int flags)
{
	if (playerinfo_banned_flags[client][CHEAT_AIMBOT])
		return;

	if (lilac_forward_allow_cheat_detection(client, CHEAT_AIMBOT) == false)
		return;

	/* Detection expires in 10 minutes. */
	CreateTimer(600.0, timer_decrement_aimbot, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	lilac_forward_client_cheat(client, CHEAT_AIMBOT);

	/* Don't log the first detection. */
	if (++aimbot_detection[client] < 2)
		return;

	if (icvar[CVAR_CHEAT_WARN])
		lilac_warn_admins(client, CHEAT_AIMBOT, aimbot_detection[client]);

	if (icvar[CVAR_LOG]) {
		lilac_log_setup_client(client);
		Format(line_buffer, sizeof(line_buffer),
			"%s is suspected of using an aimbot (Detection: %d | Delta: %.0f | TotalDelta: %.0f | Detected:%s%s%s%s%s).",
			line_buffer, aimbot_detection[client], delta, td,
			((flags & AIMBOT_FLAG_SNAP)      ? " Aim-Snap"     : ""),
			((flags & AIMBOT_FLAG_SNAP2)     ? " Aim-Snap2"    : ""),
			((flags & AIMBOT_FLAG_AUTOSHOOT) ? " Autoshoot"    : ""),
			((flags & AIMBOT_FLAG_REPEAT)    ? " Angle-Repeat" : ""),
			((td > AIMBOT_MAX_TOTAL_DELTA)   ? " Total-Delta"  : ""));

		lilac_log(true);

		if (icvar[CVAR_LOG_EXTRA] == 2)
			lilac_log_extra(client);
	}
	database_log(client, "aimbot", aimbot_detection[client], float(flags), td);

	if (aimbot_detection[client] >= icvar[CVAR_AIMBOT]
		&& icvar[CVAR_AIMBOT] >= AIMBOT_BAN_MIN) {

		if (icvar[CVAR_LOG]) {
			lilac_log_setup_client(client);
			Format(line_buffer, sizeof(line_buffer),
				"%s was banned for Aimbot.", line_buffer);

			lilac_log(true);

			if (icvar[CVAR_LOG_EXTRA])
				lilac_log_extra(client);
		}
		database_log(client, "aimbot", DATABASE_BAN);

		playerinfo_banned_flags[client][CHEAT_AIMBOT] = true;
		lilac_ban_client(client, CHEAT_AIMBOT);
	}
}

public Action timer_decrement_aimbot(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (!is_player_valid(client))
		return Plugin_Continue;

	if (aimbot_detection[client] > 0)
		aimbot_detection[client]--;

	return Plugin_Continue;
}
