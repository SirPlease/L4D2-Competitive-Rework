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

void lilac_warn_admins(int client, int cheat, int detections)
{
	char name[MAX_NAME_LENGTH];
	char type[16];
	int admins[MAXPLAYERS + 1];
	int n = 0;
	
	/* We'll assume the player is valid, as this function
	 * should never be called on invalid clients in the first place. */
	/* if (!is_player_valid(client))
		return; */
	
	/* Setup a list of admins. */
	for (int i = 1; i <= MaxClients; i++) {
		if (!is_player_valid(i))
			continue;
		
		if (IsFakeClient(i))
			continue;
		
		if (is_player_admin(i))
			admins[n++] = i;
	}
	
	/* No admins are on. */
	if (!n)
		return;
	
	switch (cheat) {
	case CHEAT_BHOP: { strcopy(type, sizeof(type), "Bhop"); }
	case CHEAT_AIMBOT: { strcopy(type, sizeof(type), "Aimbot"); }
	case CHEAT_AIMLOCK: { strcopy(type, sizeof(type), "Aimlock"); }
	/* Macros have their own warning system. */
	default: { return; }
	}
	
	if (!GetClientName(client, name, sizeof(name)))
		strcopy(name, sizeof(name), "[NAME_ERROR]");
	
	for (int i = 0; i < n; i++)
		PrintToChat(admins[i],
			"[Lilac] %T", "admin_chat_warning_generic",
			admins[i], name, type, detections);
}

/* Useless Todo: I should update this soon... But I won't :P */
bool bullettime_can_shoot(int client)
{
	int weapon;

	if (!IsPlayerAlive(client))
		return false;

	weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if (!IsValidEntity(weapon))
		return false;

	if (GetEntPropFloat(client, Prop_Data, "m_flSimulationTime") + GetTickInterval()
		>= GetEntPropFloat(weapon, Prop_Data, "m_flNextPrimaryAttack"))
		return true;

	return false;
}

void lilac_reset_client(int client)
{
	lilac_backtrack_reset_client(client);
	lilac_bhop_reset_client(client);
	lilac_macro_reset_client(client);
#if !defined TF2C
	/* Noise maker file is empty if compiled for TF2Classic. */
	lilac_noisemaker_reset_client(client);
#endif
	lilac_aimbot_reset_client(client);
	lilac_ping_reset_client(client);
	lilac_convar_reset_client(client);
	lilac_lerp_reset_client(client);

	playerinfo_index[client] = 0;
	playerinfo_aimlock_sus[client] = 0;
	playerinfo_aimlock[client] = 0;
	playerinfo_time_bumpercart[client] = 0.0;
	playerinfo_time_teleported[client] = 0.0;
	playerinfo_time_aimlock[client] = 0.0;
	playerinfo_time_process_aimlock[client] = 0.0;

	for (int i = 0; i < CHEAT_MAX; i++) {
		playerinfo_time_forward[client][i] = 0.0;
		playerinfo_banned_flags[client][i] = false;
	}

	for (int i = 0; i < CMD_LENGTH; i++) {
		playerinfo_buttons[client][i] = 0;
		playerinfo_actions[client][i] = 0;
		playerinfo_time_usercmd[client][i] = 0.0;

		set_player_log_angles(client, view_as<float>({0.0, 0.0, 0.0}), i);
	}
}

void lilac_log_setup_client(int client)
{
	char date[512], steamid[64], ip[64];

	FormatTime(date, sizeof(date), dateformat, GetTime());

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true);
	GetClientIP(client, ip, sizeof(ip), true);

	FormatEx(line_buffer, sizeof(line_buffer),
		"%s [Version %s] {Name: \"%N\" | SteamID: %s | IP: %s}",
		date, PLUGIN_VERSION, client, steamid, ip);
}

void lilac_log_extra(int client)
{
	char map[128], weapon[64];
	float pos[3], ang[3];

	GetClientAbsOrigin(client, pos);
	GetCurrentMap(map, sizeof(map));
	GetClientWeapon(client, weapon, sizeof(weapon));

	get_player_log_angles(client, 0, true, ang);

	FormatEx(line_buffer, sizeof(line_buffer),
		"\tPos={%.0f,%.0f,%.0f}, Angles={%.5f,%.5f,%.5f}, Map=\"%s\", Team={%d}, Weapon=\"%s\", Latency={Inc:%f,Out:%f}, Loss={Inc:%f,Out:%f}, Choke={Inc:%f,Out:%f}, ConnectionTime={%f seconds}, GameTime={%f seconds}",
		pos[0], pos[1], pos[2],
		ang[0], ang[1], ang[2],
		map, GetClientTeam(client), weapon,
		GetClientAvgLatency(client, NetFlow_Incoming),
		GetClientAvgLatency(client, NetFlow_Outgoing),
		GetClientAvgLoss(client, NetFlow_Incoming),
		GetClientAvgLoss(client, NetFlow_Outgoing),
		GetClientAvgChoke(client, NetFlow_Incoming),
		GetClientAvgChoke(client, NetFlow_Outgoing),
		GetClientTime(client), GetGameTime());

	lilac_log(false);
}

void lilac_log(bool cleanup)
{
	Handle file = OpenFile(log_file, "a");

	if (file == null) {
		PrintToServer("[Lilac] Cannot open log file.");
		return;
	}

	/* Remove invalid characters.
	 * This doesn't care about invalid utf-8 formatting,
	 * only ASCII control characters. */
	if (cleanup) {
		for (int i = 0; line_buffer[i]; i++) {
			if (line_buffer[i] == '\n' || line_buffer[i] == 0x0d)
				line_buffer[i] = '*';
			else if (line_buffer[i] < 32)
				line_buffer[i] = '#';
		}
	}

	WriteFileLine(file, "%s", line_buffer);
	/* Just echo log lines to SourceIRC */
	if (icvar[CVAR_SOURCEIRC] && NATIVE_EXISTS("IRC_MsgFlaggedChannels")) {
		/* Note- SourceIRC Expects messages to be clean with no \r or \n, so clean it if not already done. */
		if (!cleanup) {
			for (int i = 0; line_buffer[i]; i++) {
				if (line_buffer[i] == '\n' || line_buffer[i] == 0x0d)
					line_buffer[i] = '*';
				else if (line_buffer[i] < 32)
					line_buffer[i] = '#';
			}
		}
		IRC_MsgFlaggedChannels("lilac", "[LILAC] %s", line_buffer);
	}
	CloseHandle(file);
}

void lilac_log_first_time_setup()
{
	/* Some admins may not understand how to interpret cheat logs
	 * correctly, thus, we should warn them so they don't panic
	 * over trivial stuff. */
	if (!FileExists(log_file, false, NULL_STRING)) {
		FormatEx(line_buffer, sizeof(line_buffer),
"=========[Notice]=========\n\
Thank you for installing Little Anti-Cheat %s!\n\
Just a few notes about this Anti-Cheat:\n\n\
If a player is logged as \"suspected\" of using cheats, they are not necessarily cheating.\n\
If the suspicions logged are few and rare, they are likely false positives.\n\
An automatic ban is triggered by 5 or more \"suspicions\" or by one \"detection\".\n\
If you think a ban may be incorrect, please do not hesitate to let me know.\n\n\
That is all, have a wonderful day~\n\n\n", PLUGIN_VERSION);
		lilac_log(false);
	}
}

void lilac_ban_client(int client, int cheat)
{
	char reason[128];
	int lang = LANG_SERVER;
	bool log_only = false;

	/* Banning has been disabled, don't forward the ban and don't ban. */
	if (!icvar[CVAR_BAN])
		return;

	/* Check if log only mode has been enabled, in which case, don't ban. */
	switch (cheat) {
	case CHEAT_ANGLES: { log_only = icvar[CVAR_ANGLES] < 0; }
	case CHEAT_CHATCLEAR: { log_only = icvar[CVAR_CHAT] < 0; }
	case CHEAT_CONVAR: { log_only = icvar[CVAR_CONVAR] < 0; }
	case CHEAT_NOLERP: { log_only = icvar[CVAR_NOLERP] < 0; }
	case CHEAT_BHOP: { log_only = icvar[CVAR_BHOP] < 0; }
	/* Aimbot and Aimlock have their own dedicated log-only mode. */
	case CHEAT_ANTI_DUCK_DELAY: { log_only = icvar[CVAR_ANTI_DUCK_DELAY] < 0; }
	case CHEAT_NOISEMAKER_SPAM: { log_only = icvar[CVAR_NOISEMAKER_SPAM] < 0; }
	case CHEAT_MACRO: { log_only = icvar[CVAR_MACRO] < 0; }
	case CHEAT_NEWLINE_NAME: { log_only = icvar[CVAR_FILTER_NAME] < 0; }
	}

	if (log_only)
		return;

	if (icvar[CVAR_BAN_LANGUAGE])
		lang = client;

	switch (cheat) {
	case CHEAT_ANGLES: { Format(reason, sizeof(reason),
		"[Little Anti-Cheat %s] %T", PLUGIN_VERSION, "ban_angle", lang); }
	case CHEAT_CHATCLEAR: { Format(reason, sizeof(reason),
		"[Little Anti-Cheat %s] %T", PLUGIN_VERSION, "ban_chat_clear", lang); }
	case CHEAT_CONVAR: { Format(reason, sizeof(reason),
		"[Little Anti-Cheat %s] %T", PLUGIN_VERSION, "ban_convar", lang); }
	case CHEAT_NOLERP: { Format(reason, sizeof(reason),
		"[Little Anti-Cheat %s] %T", PLUGIN_VERSION, "ban_nolerp", lang); }
	case CHEAT_BHOP: { Format(reason, sizeof(reason),
		"[Little Anti-Cheat %s] %T", PLUGIN_VERSION, "ban_bhop", lang); }
	case CHEAT_AIMBOT: { Format(reason, sizeof(reason),
		"[Little Anti-Cheat %s] %T", PLUGIN_VERSION, "ban_aimbot", lang); }
	case CHEAT_AIMLOCK: { Format(reason, sizeof(reason),
		"[Little Anti-Cheat %s] %T", PLUGIN_VERSION, "ban_aimlock", lang); }
	case CHEAT_ANTI_DUCK_DELAY: { Format(reason, sizeof(reason),
		"[Little Anti-Cheat %s] %T", PLUGIN_VERSION, "ban_anti_duck_delay", lang); }
	case CHEAT_NOISEMAKER_SPAM: { Format(reason, sizeof(reason),
		"[Little Anti-Cheat %s] %T", PLUGIN_VERSION, "ban_noisemaker", lang); }
	case CHEAT_MACRO: { Format(reason, sizeof(reason),
		"[Little Anti-Cheat %s] %T", PLUGIN_VERSION, "ban_macro", lang); }
	case CHEAT_NEWLINE_NAME: { Format(reason, sizeof(reason),
		"[Little Anti-Cheat %s] %T", PLUGIN_VERSION, "ban_name_newline", lang); }
	default: return;
	}

	lilac_forward_client_ban(client, cheat);


	/* Try to ban with MateralAdmin first,
	 * if that fails, proceed to SourceBans, then SourceBans++,
	 * And lastly, BaseBans. */


	if (icvar[CVAR_MA] && NATIVE_EXISTS("MABanPlayer")) {
		MABanPlayer(0, client, MA_BAN_STEAM, get_ban_length(cheat), reason);
		CreateTimer(5.0, timer_kick, GetClientUserId(client));
		return;
	}


	if (icvar[CVAR_SB]) {
		if (NATIVE_EXISTS("SBPP_BanPlayer")) {
			SBPP_BanPlayer(0, client, get_ban_length(cheat), reason);
			CreateTimer(5.0, timer_kick, GetClientUserId(client));
			return;
		}
		else if (NATIVE_EXISTS("SBBanPlayer")) {
			SBBanPlayer(0, client, get_ban_length(cheat), reason);
			CreateTimer(5.0, timer_kick, GetClientUserId(client));
			return;
		}
	}


	BanClient(client, get_ban_length(cheat), BANFLAG_AUTO, reason, reason, "lilac", 0);
	CreateTimer(5.0, timer_kick, GetClientUserId(client));
}

public Action timer_kick(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (is_player_valid(client))
		KickClient(client, "%T", "kick_ban_generic", client);
		
	return Plugin_Continue;
}

int get_ban_length(int cheat)
{
	return ((ban_length_overwrite[cheat] <= -1) ? icvar[CVAR_BAN_LENGTH] : ban_length_overwrite[cheat]);
}

void get_player_log_angles(int client, int tick, bool latest, float writeto[3])
{
	int i = tick;

	if (latest) {
		i = playerinfo_index[client];
	}
	else {
		while (i < 0)
			i += CMD_LENGTH;
		while (i >= CMD_LENGTH)
			i -= CMD_LENGTH;
	}

	writeto[0] = playerinfo_angles[client][i][0];
	writeto[1] = playerinfo_angles[client][i][1];
	writeto[2] = playerinfo_angles[client][i][2];
}

void set_player_log_angles(int client, float ang[3], int tick)
{
	int i = tick;

	/* Normalize tick. */
	while (i < 0)
		i += CMD_LENGTH;
	while (i >= CMD_LENGTH)
		i -= CMD_LENGTH;

	playerinfo_angles[client][i][0] = ang[0];
	playerinfo_angles[client][i][1] = ang[1];
	playerinfo_angles[client][i][2] = ang[2];
}

void aim_at_point(const float p1[3], const float p2[3], float writeto[3])
{
	SubtractVectors(p2, p1, writeto);
	GetVectorAngles(writeto, writeto);

	while (writeto[0] > 90.0)
		writeto[0] -= 360.0;
	while (writeto[0] < -90.0)
		writeto[0] += 360.0;
	while (writeto[1] > 180.0)
		writeto[1] -= 360.0;
	while (writeto[1] < -180.0)
		writeto[1] += 360.0;

	writeto[2] = 0.0;
}

float angle_delta(float []a1, float []a2)
{
	int normal = 5;
	float p1[3], p2[3], delta;

	p1[0] = a1[0];
	p2[0] = a2[0];
	p2[1] = a2[1];
	p1[1] = a1[1];

	/* We don't care about roll. */
	p1[2] = 0.0;
	p2[2] = 0.0;

	delta = GetVectorDistance(p1, p2);

	/* Normalize maximum 5 times, yaw can sometimes be odd. */
	while (delta > 180.0 && normal > 0) {
		normal--;
		delta = FloatAbs(delta - 360.0);
	}

	return delta;
}

bool skip_due_to_loss(int client)
{
	/* Debate: What percentage should this be at?
	 * Skip detection if the loss is more than 50% */
	if (icvar[CVAR_LOSS_FIX])
		return GetClientAvgLoss(client, NetFlow_Both) > 0.5;

	return false;
}

int time_to_ticks(float time)
{
	if (time > 0.0)
		return RoundToNearest(time / GetTickInterval());

	return 0;
}

int intabs(int num)
{
	return ((num < 0) ? num * -1 : num);
}

bool is_player_admin(int client)
{
	/* Todo: I don't know if this is correct. */
	return CheckCommandAccess(client, "", ADMFLAG_GENERIC | ADMFLAG_KICK | ADMFLAG_SLAY, true);
}

bool is_player_valid(int client)
{
	return (client >= 1 && client <= MaxClients
		&& IsClientConnected(client) && IsClientInGame(client)
		&& !IsClientSourceTV(client));
}

void lilac_forward_client_cheat(int client, int cheat)
{
	int dummy;

	if (forwardhandle == null)
		return;

	Call_StartForward(forwardhandle);
	Call_PushCell(client);
	Call_PushCell(cheat);
	Call_Finish(dummy);
}

void lilac_forward_client_ban(int client, int cheat)
{
	int dummy;

	if (forwardhandleban == null)
		return;

	Call_StartForward(forwardhandleban);
	Call_PushCell(client);
	Call_PushCell(cheat);
	Call_Finish(dummy);
}

bool lilac_forward_allow_cheat_detection(int client, int cheat)
{
	Action result = Plugin_Continue;

	if (forwardhandleallow == null)
		return true;

	Call_StartForward(forwardhandleallow);
	Call_PushCell(client);
	Call_PushCell(cheat);
	Call_Finish(result);

	if (result == Plugin_Continue)
		return true;

	return false;
}
