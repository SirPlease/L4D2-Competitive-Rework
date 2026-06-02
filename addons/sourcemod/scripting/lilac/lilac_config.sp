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

void lilac_config_setup()
{
	Handle tcvar;

	cvar[CVAR_ENABLE] = CreateConVar("lilac_enable", "1",
		"Enable Little Anti-Cheat.",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_WELCOME] = CreateConVar("lilac_welcome", "1",
		"Welcome connecting players saying that the server is protected.",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_SB] = CreateConVar("lilac_sourcebans", "1",
		"Ban players via sourcebans++ (If it isn't installed, it will default to basebans).",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_MA] = CreateConVar("lilac_materialadmin", "0",
		"Ban players via Material-Admin (Fork of Sourcebans++. If it isn't installed, will default to sourcebans++ or basebans).",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_SOURCEIRC] = CreateConVar("lilac_sourceirc", "0",
		"Enable reflecting log messages to SourceIRC channels flagged with 'lilac', if SourceIRC is available.",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_LOG] = CreateConVar("lilac_log", "1",
		"Enable cheat logging.",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_LOG_EXTRA] = CreateConVar("lilac_log_extra", "1",
		"0 = Disabled.\n1 = Log extra information on player banned.\n2 = Log extra information on everything.",
		FCVAR_PROTECTED, true, 0.0, true, 2.0);
	cvar[CVAR_LOG_MISC] = CreateConVar("lilac_log_misc", "1",
		"Log when players are kicked for misc features, like interp exploits, too high ping and on convar response failure.",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_LOG_DATE] = CreateConVar("lilac_log_date", "{year}/{month}/{day} {hour}:{minute}:{second}",
		"Which date & time format to use when logging. Type: \"lilac_date_list\" for more info.",
		FCVAR_PROTECTED, false, 0.0, false, 0.0);
	cvar[CVAR_BAN] = CreateConVar("lilac_ban", "1",
		"Enable banning of cheaters, set to 0 if you want to test Lilac before fully trusting it with bans.",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_BAN_LENGTH] = CreateConVar("lilac_ban_length", "0",
		"How long bans should last in minutes (0 = forever).",
		FCVAR_PROTECTED, true, 0.0, false, 0.0);
	cvar[CVAR_BAN_LANGUAGE] = CreateConVar("lilac_ban_language", "1",
		"Ban reason language.\n0 = Use server's language.\n1 = Use the language of the cheater.",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_ANGLES] = CreateConVar("lilac_angles", "-1",
		"Detect Angle-Cheats (Basic Anti-Aim, Legit Anti-Backstab and Duckspeed).\n-1 = Log only.\n0 = Disabled.\n1 = Enabled.",
		FCVAR_PROTECTED, true, -1.0, true, 1.0);
	cvar[CVAR_PATCH_ANGLES] = CreateConVar("lilac_angles_patch", "1",
		"Patch Angle-Cheats (Basic Anti-Aim, Legit Anti-Backstab and Duckspeed).",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_CHAT] = CreateConVar("lilac_chatclear", "-1",
		"Detect Chat-Clear.\n-1 = Log only.\n0 = Disabled.\n1 = Enabled.",
		FCVAR_PROTECTED, true, -1.0, true, 1.0);
	cvar[CVAR_CONVAR] = CreateConVar("lilac_convar", "1",
		"Detect basic invalid ConVars.\n-1 = Log only.\n0 = Disabled.\n1 = Enabled.",
		FCVAR_PROTECTED, true, -1.0, true, 1.0);
	cvar[CVAR_NOLERP] = CreateConVar("lilac_nolerp", "1",
		"Detect NoLerp.\n-1 = Log only.\n0 = Disabled.\n1 = Enabled.",
		FCVAR_PROTECTED, true, -1.0, true, 1.0);
	cvar[CVAR_BHOP] = CreateConVar("lilac_bhop", "5",
		"Bhop detection mode (Negative values = log-only).\n0 = Disabled.\n1&2 = Reserved (Invalid).\n3 = Custom (unlocks lilac_bhop_set command).\n4 = Low.\n5 = Medium.\n6 = High.",
		FCVAR_PROTECTED, true, -6.0, true, 6.0);
	cvar[CVAR_AIMBOT] = CreateConVar("lilac_aimbot", "8",
		"Detect basic Aimbots.\n0 = Disabled.\n1 = Log only.\n5 or more = ban on n'th detection (Minimum possible is 5)",
		FCVAR_PROTECTED, true, 0.0, false, 0.0);
	cvar[CVAR_AIMBOT_AUTOSHOOT] = CreateConVar("lilac_aimbot_autoshoot", "0",
		"Detect Autoshoot.",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_AIMLOCK] = CreateConVar("lilac_aimlock", "10",
		"Detect Aimlock.\n0 = Disabled.\n1 = Log only.\n5 or more = ban on n'th detection (Minimum possible is 5).",
		FCVAR_PROTECTED, true, 0.0, false, 0.0);
	cvar[CVAR_AIMLOCK_LIGHT] = CreateConVar("lilac_aimlock_light", "1",
		"Only process at most 5 suspicious players for aimlock.\nDO NOT DISABLE THIS UNLESS YOUR SERVER CAN HANDLE IT!",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_ANTI_DUCK_DELAY] = CreateConVar("lilac_anti_duck_delay", "0",
		"CS:GO Only, detect Anti-Duck-Delay/FastDuck.\n-1 = Log only.\n0 = Disabled.\n1 = Enabled.",
		FCVAR_PROTECTED, true, -1.0, true, 1.0);
	cvar[CVAR_NOISEMAKER_SPAM] = CreateConVar("lilac_noisemaker", "0",
		"TF2 Only, detect infinite noisemaker spam. STILL IN BETA, DOES NOT BAN, ONLY LOGS! MAY HAVE SOME ISSUES!\n-1 = Log only.\n0 = Disabled.\n1 = Enabled.",
		FCVAR_PROTECTED, true, -1.0, true, 1.0);
	cvar[CVAR_BACKTRACK_PATCH] = CreateConVar("lilac_backtrack_patch", "0",
		"Patch Backtrack.\n0 = Disabled (Recommended setting for SMAC compatibility).\n1 = Enabled.",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_BACKTRACK_TOLERANCE] = CreateConVar("lilac_backtrack_tolerance", "0",
		"How tolerant the backtrack patch will be of tickcount changes.\n0 = No tolerance (recommended).\n1+ = n ticks tolerant.",
		FCVAR_PROTECTED, true, 0.0, true, 3.0);
	cvar[CVAR_MAX_PING] = CreateConVar("lilac_max_ping", "0",
		"Ban players with too high of a ping for 3 minutes.\nThis is meant to deal with fakelatency, the ban length is just to prevent instant reconnects.\n0 = no ping limit, minimum possible is 100.",
		FCVAR_PROTECTED, true, 0.0, true, 1000.0);
	cvar[CVAR_MAX_PING_SPEC] = CreateConVar("lilac_max_ping_spec", "0",
		"Move players with a high ping to spectator and warn them after this many seconds (Minimum possible is 30).",
		FCVAR_PROTECTED, true, 0.0, true, 90.0);
	cvar[CVAR_MAX_LERP] = CreateConVar("lilac_max_lerp", "105",
		"Kicks players attempting to exploit interpolation, any interp higher than this value = kick.\nMinimum value possible = 105 (Default interp in games = 100).\n0 or less than 105 = Disabled.",
		FCVAR_PROTECTED, true, 0.0, true, 510.0); // 500 is max possible.
	cvar[CVAR_MACRO] = CreateConVar("lilac_macro", "0",
		"Detect macros.\n-1 = Log only.\n0 = Disabled.\n1 = Enabled.\n2 = Enabled, but no logging.",
		FCVAR_PROTECTED, true, -1.0, true, 2.0);
	cvar[CVAR_MACRO_WARNING] = CreateConVar("lilac_macro_warning", "1",
		"Warning mode for Macro detection:\n0 = No warning.\n1 = Warn player using macro.\n2 = Warn admins on server.\n3 = Warn everyone.",
		FCVAR_PROTECTED, true, 0.0, true, 3.0);
	cvar[CVAR_MACRO_DEAL_METHOD] = CreateConVar("lilac_macro_method", "0",
		"What to do with players detected of using macros:\n0 = Kick.\n1 = Ban.",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_MACRO_MODE] = CreateConVar("lilac_macro_mode", "0",
		"What types of macros to detect:\n0 = All.\n1 = Auto-Jump.\n2 = Auto-Shoot.",
		FCVAR_PROTECTED, true, 0.0, true, 3.0);
	cvar[CVAR_FILTER_NAME] = CreateConVar("lilac_filter_name", "2",
		"Filter invalid names (kicks players with invalid names).\n-1 = Log-Only.\n0 = Disabled.\n1 = Enabled, kick only.\n2 = Ban cheaters with newlines in names.",
		FCVAR_PROTECTED, true, -1.0, true, 2.0);
	cvar[CVAR_FILTER_CHAT] = CreateConVar("lilac_filter_chat", "1",
		"Filter invalid characters in chat (block chat messages).",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_LOSS_FIX] = CreateConVar("lilac_loss_fix", "1",
		"Ignore some cheat detections for players who have too much packet loss (bad connection to the server).",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_AUTO_UPDATE] = CreateConVar("lilac_auto_update", "0",
		"Automatically update Little Anti-Cheat.",
		FCVAR_PROTECTED, true, 0.0, true, 1.0);
	cvar[CVAR_DATABASE] = CreateConVar("lilac_database", "l4dstats",
		"Database to log detections to.\nempty = don't log to database\ndatabase name = log to this database (MySQL & SQLite supported)",
		FCVAR_PROTECTED);

	for (int i = 0; i < CVAR_MAX; i++) {
		if (i != CVAR_LOG_DATE)
			icvar[i] = GetConVarInt(cvar[i]);

		HookConVarChange(cvar[i], cvar_change);
	}

	if ((tcvar = FindConVar("sv_maxupdaterate")) != null) {
		HookConVarChange(tcvar, cvar_change);
		lilac_lerp_maxupdaterate_changed(GetConVarInt(tcvar));
	}
	else {
		// Assume the value is 0 if we can't fetch it.
		lilac_lerp_maxupdaterate_changed(0);
	}

	// If the server allows clients to set the interp ratio to
	//     whatever they want, then false positives become possible.
	// Thanks RoseTheFox / Bud for reporting this :)
	if ((tcvar = FindConVar("sv_client_min_interp_ratio")) != null) {
		HookConVarChange(tcvar, cvar_change);
		lilac_lerp_ratio_changed(GetConVarInt(tcvar));

		if ((tcvar = FindConVar("sv_client_max_interp_ratio")) != null) {
			HookConVarChange(tcvar, cvar_change);
			lilac_lerp_ratio_changed(GetConVarInt(tcvar));
		}
		else {
			lilac_lerp_ratio_changed(0);
		}
	}
	else {
		lilac_lerp_ratio_changed(0);
	}

	if ((tcvar = FindConVar("sv_cheats")) != null) {
		HookConVarChange(tcvar, cvar_change);
		sv_cheats = GetConVarInt(tcvar);
	}
	else {
		sv_cheats = 1;
	}

	RegServerCmd("lilac_date_list", lilac_date_list, "Lists date formatting options", 0);
	RegServerCmd("lilac_set_ban_length", lilac_set_ban_length, "Sets custom ban lengths for specific cheats.", 0);
	RegServerCmd("lilac_ban_status", lilac_ban_status, "Prints banning status to server console.", 0);
	RegServerCmd("lilac_bhop_set", lilac_bhop_set, "Sets Custom Bhop settings", 0);

	// Legacy check, execute old config location.
	if (FileExists("cfg/lilac_config.cfg", false, NULL_STRING))
		AutoExecConfig(true, "lilac_config", "");
	else
		AutoExecConfig(true, "lilac_config", "sourcemod");
}

public void OnConfigsExecuted()
{
	static bool run_status_ban = true;

	if (run_status_ban)
		lilac_ban_status(0);

	lilac_bhop_set_preset(); // We need to call this here, in case of a plugin reload.

	run_status_ban = false;
	
	Database_OnConfigExecuted();
}

public Action lilac_bhop_set(int args)
{
	char buffer[16];
	int value = 0;
	int index = 0;

	if (intabs(icvar[CVAR_BHOP]) != BHOP_MODE_CUSTOM) {
		PrintToServer("Error: Must be in custom mode, set 'lilac_bhop' to %d.",
			BHOP_MODE_CUSTOM);
		return Plugin_Handled;
	}
	else if (args < 2) {
		PrintToServer("Error: too few arguments.\nUsage: lilac_bhop_set <type> <value>");
		PrintToServer("Examples:");
		PrintToServer("\tlilac_bhop_set min 7");
		PrintToServer("\tlilac_bhop_set ticks -1");
		PrintToServer("\tlilac_bhop_set max 15");
		PrintToServer("\tlilac_bhop_set total 4.");
		PrintToServer("\nType list:");
		PrintToServer("\tmin   - Minimum consecutive perfect bhops to trigger a detection.");
		PrintToServer("\tticks - Jump tick buffer before min is ignored.");
		PrintToServer("\tmax   - Maximum consecutive perfect bhops to trigger an instant ban.");
		PrintToServer("\ttotal - How many detections before banning.");
		PrintToServer("\n");
		print_current_bhop_settings();

		return Plugin_Handled;
	}

	GetCmdArg(2, buffer, sizeof(buffer));
	value = StringToInt(buffer, 10);
	GetCmdArg(1, buffer, sizeof(buffer));

	// Working with strings is always the least fun part ):
	if (StrEqual(buffer, "min", false)
		|| StrEqual(buffer, "minimal", false)
		|| StrEqual(buffer, "minimum", false)) {
		index = BHOP_INDEX_MIN;
	}
	else if (StrEqual(buffer, "jump", false)
		|| StrEqual(buffer, "jumps", false)
		|| StrEqual(buffer, "tick", false)
		|| StrEqual(buffer, "ticks", false)
		|| StrEqual(buffer, "buf", false)
		|| StrEqual(buffer, "buff", false)
		|| StrEqual(buffer, "buffer", false)
		|| StrEqual(buffer, "jump_tick", false)
		|| StrEqual(buffer, "jump_ticks", false)
		|| StrEqual(buffer, "jumptick", false)
		|| StrEqual(buffer, "jumpticks", false)) {
		index = BHOP_INDEX_JUMP;
	}
	else if (StrEqual(buffer, "max", false)
		|| StrEqual(buffer, "maximal", false)
		|| StrEqual(buffer, "maximum", false)) {
		index = BHOP_INDEX_MAX;
	}
	else if (StrEqual(buffer, "tot", false)
		|| StrEqual(buffer, "total", false)
		|| StrEqual(buffer, "all", false)
		|| StrEqual(buffer, "detection", false)
		|| StrEqual(buffer, "detections", false)) {
		index = BHOP_INDEX_TOTAL;
	}
	else {
		PrintToServer("Error: Unknown type \"%s\"", buffer);
		return Plugin_Handled;
	}

	if (value < bhop_settings_min[index]) {
		// Total setting CANNOT be set to be lower than the min,
		// 	no matter what!
		if (index == BHOP_INDEX_TOTAL) {
			value = bhop_settings_min[index];
		}
		else if (value != 0) {
			PrintToServer("Warning: Minimum value is %d, use '0' to disable feature.",
				bhop_settings_min[index]);
			value = bhop_settings_min[index];
		}
	}

	PrintToServer("[Lilac] Changed Bhop setting \"%s\" to %d.",
		buffer, value);

	bhop_settings[index] = value;
	print_current_bhop_settings();

	// Both being 0 means we won't detect anything, lol.
	// So let's warn the admin :)
	if (!bhop_settings[BHOP_INDEX_MIN] && !bhop_settings[BHOP_INDEX_MAX])
		PrintToServer("Warning: Min and Max are set to 0, bhop detection is now disabled!");

	return Plugin_Handled;
}

static void print_current_bhop_settings()
{
	// Yeah, a little messy...
	PrintToServer("Current Custom Bhop values:");
	PrintToServer("    Type  : Min possible : Current");
	PrintToServer("    Min   : %2d           : %d", bhop_settings_min[BHOP_INDEX_MIN], bhop_settings[BHOP_INDEX_MIN]);
	if (bhop_settings[BHOP_INDEX_JUMP] == -1)
		PrintToServer("    Ticks : %2d           : %d", bhop_settings_min[BHOP_INDEX_JUMP], bhop_settings[BHOP_INDEX_JUMP]);
	else
		PrintToServer("    Ticks : %2d           : %d (+%d = %d total)", bhop_settings_min[BHOP_INDEX_JUMP], bhop_settings[BHOP_INDEX_JUMP], bhop_settings[BHOP_INDEX_MIN], bhop_settings[BHOP_INDEX_JUMP] + bhop_settings[BHOP_INDEX_MIN]);
	PrintToServer("    Max   : %2d           : %d", bhop_settings_min[BHOP_INDEX_MAX], bhop_settings[BHOP_INDEX_MAX]);
	PrintToServer("    Total : %2d           : %d", bhop_settings_min[BHOP_INDEX_TOTAL], bhop_settings[BHOP_INDEX_TOTAL]);
}

public Action lilac_ban_status(int args)
{
	int ban_type = 0;
	char tmp[24];

	PrintToServer("====[Little Anti-Cheat %s - Ban Status]====", PLUGIN_VERSION);
	PrintToServer("Checking ban plugins:");
	PrintToServer("Material-Admin:");
	PrintToServer("\tLoaded: %s", ((materialadmin_exist) ? "Yes" : "No"));
	PrintToServer("\tNative Exists: %s", ((NATIVE_EXISTS("MABanPlayer")) ? "Yes" : "No"));
	PrintToServer("\tConVar: lilac_materialadmin = %d", icvar[CVAR_MA]);

#if !defined _materialadmin_included
	PrintToServer("\tWARNING: Material-Admin was NOT included when compiled, banning through MA won't work!");
	PrintToServer("\tПредупреждение: Material-Admin НЕ БЫЛ включен при компиляции, баны через MA не будут работать!");
#else
	ban_type = ((icvar[CVAR_MA] && NATIVE_EXISTS("MABanPlayer")) ? 2 : 0);
#endif

	PrintToServer("Sourcebans++:");
	PrintToServer("\tLoaded: %s", ((sourcebanspp_exist) ? "Yes" : "No"));
	PrintToServer("\tNative Exists: %s", ((NATIVE_EXISTS("SBPP_BanPlayer")) ? "Yes" : "No"));
	PrintToServer("\tConVar: lilac_sourcebans = %d", icvar[CVAR_SB]);

#if !defined _sourcebanspp_included
	PrintToServer("\tWARNING: Sourcebans++ was NOT included when compiled, banning through SB++ won't work!");
#else
	if (!ban_type)
		ban_type = (icvar[CVAR_SB] && NATIVE_EXISTS("SBPP_BanPlayer"));
#endif

	PrintToServer("SourceIRC:");
	PrintToServer("\tNative Exists: %s", ((NATIVE_EXISTS("IRC_MsgFlaggedChannels")) ? "Yes" : "No"));
	PrintToServer("\tConVar: lilac_sourceirc = %d", icvar[CVAR_SOURCEIRC]);
	if (icvar[CVAR_SOURCEIRC] && NATIVE_EXISTS("IRC_MsgFlaggedChannels")) {
		IRC_MsgFlaggedChannels("lilac", "[LILAC] is active and logging to SourceIRC!");
	}

	switch (ban_type) {
	case 0: { strcopy(tmp, sizeof(tmp), "BaseBans"); }
	case 1: { strcopy(tmp, sizeof(tmp), "Sourcebans++"); }
	case 2: { strcopy(tmp, sizeof(tmp), "Material-Admin"); }
	default: return Plugin_Handled;
	}

	PrintToServer("\nBanning will go though %s.\n", tmp);

	return Plugin_Handled;
}

public Action lilac_set_ban_length(int args)
{
	char feature[32], length[32];
	int index = -1;
	int time;

	if (args < 2) {
		PrintToServer("Error: Too few arguments.\nUsage: lilac_set_ban_length <cheat> <minutes>");
		PrintToServer("Example:\n\tlilac_set_ban_length bhop 15\n\t(Sets bhop ban to 15 minutes)");
		PrintToServer("\nIf ban length is -1, then the ban length will be the ConVar lilac_ban_length's value.");
		PrintToServer("\nPossible cheat arguments:");
		PrintToServer("\tlilac_set_ban_length angles <minutes>");
		PrintToServer("\tlilac_set_ban_length chatclear <minutes>");
		PrintToServer("\tlilac_set_ban_length convar <minutes>");
		PrintToServer("\tlilac_set_ban_length nolerp <minutes>");
		PrintToServer("\tlilac_set_ban_length bhop <minutes>");
		PrintToServer("\tlilac_set_ban_length aimbot <minutes>");
		PrintToServer("\tlilac_set_ban_length aimlock <minutes>");
		PrintToServer("\tlilac_set_ban_length antiduckdelay <minutes>");
		PrintToServer("\tlilac_set_ban_length noisemaker <minutes>");
		PrintToServer("\tlilac_set_ban_length macro <minutes>");
		PrintToServer("\tlilac_set_ban_length name <minutes>\n");

		return Plugin_Handled;
	}

	GetCmdArg(1, feature, sizeof(feature));

	if (StrEqual(feature, "angles", false) || StrEqual(feature, "angle", false)) {
		index = CHEAT_ANGLES;
	}
	else if (StrEqual(feature, "chat", false) || StrEqual(feature, "chatclear", false)) {
		index = CHEAT_CHATCLEAR;
	}
	else if (StrEqual(feature, "convar", false) || StrEqual(feature, "cvar", false)) {
		index = CHEAT_CONVAR;
	}
	else if (StrEqual(feature, "nolerp", false)) {
		index = CHEAT_NOLERP;
	}
	else if (StrEqual(feature, "bhop", false) || StrEqual(feature, "bunnyhop", false)) {
		index = CHEAT_BHOP;
	}
	else if (StrEqual(feature, "aimbot", false) || StrEqual(feature, "aim", false)) {
		index = CHEAT_AIMBOT;
	}
	else if (StrEqual(feature, "aimlock", false) || StrEqual(feature, "lock", false)) {
		index = CHEAT_AIMLOCK;
	}
	// ( @~@) Bruh.... This is... B R U H
	else if (StrEqual(feature, "duck", false) || StrEqual(feature, "crouch", false)
		|| StrEqual(feature, "antiduck", false) || StrEqual(feature, "antiduckdelay", false)
		|| StrEqual(feature, "fastduck", false)) {
		index = CHEAT_ANTI_DUCK_DELAY;
	}
	else if (StrEqual(feature, "noisemaker", false) || StrEqual(feature, "noise", false)) {
		index = CHEAT_NOISEMAKER_SPAM;
	}
	else if (StrEqual(feature, "macro", false)) {
		index = CHEAT_MACRO;
	}
	else if (StrEqual(feature, "name", false) || StrEqual(feature, "filter", false)) {
		index = CHEAT_NEWLINE_NAME;
	}
	else {
		PrintToServer("Error: Unknown cheat feature \"%s\"", feature);
		return Plugin_Handled;
	}

	GetCmdArg(2, length, sizeof(length));
	time = StringToInt(length, 10);

	// Macro exception.
	if (index == CHEAT_MACRO) {
		if (time > 60)
			time = 60;
		else if (time < 15)
			time = 15;
	}
	else if (time < -1)
		time = -1;

	ban_length_overwrite[index] = time;

	// Todo: Add message showing new times? Like the bhop set command :)

	return Plugin_Handled;
}

public Action lilac_date_list(int args)
{
	PrintToServer("=======[Lilac Date Formatting]=======");
	PrintToServer("Manual formatting:");
	PrintToServer("\t{raw} = Skips the special formatting listed here");
	PrintToServer("\t        and lets you insert your own formatting");
	PrintToServer("\t        (see: http://www.cplusplus.com/reference/ctime/strftime/).");
	PrintToServer("Example:\n\t{raw}%%Y/%%m/%%d %%H:%%M:%%S");
	PrintToServer("Dates:");
	PrintToServer("\t{year}    = Numerical year  (2020).");
	PrintToServer("\t{month}   = Numerical month   (12).");
	PrintToServer("\t{day}     = Numerical day     (28).");
	PrintToServer("Time:");
	PrintToServer("\t{hour}    = 24 hour format.");
	PrintToServer("\t{hours}   = 24 hour format.");
	PrintToServer("\t{24hour}  = 24 hour format.");
	PrintToServer("\t{24hours} = 24 hour format.");
	PrintToServer("\t{12hour}  = 12 hour format.");
	PrintToServer("\t{12hours} = 12 hour format.");
	PrintToServer("\t{pm}      = Insert AM/PM.");
	PrintToServer("\t{am}      = Insert AM/PM.");
	PrintToServer("\t{minute}  = Minute.");
	PrintToServer("\t{minutes} = Minute.");
	PrintToServer("\t{second}  = Second.");
	PrintToServer("\t{seconds} = Second.");
	PrintToServer("Using flags example: {year}/{month}/{day} {hour}:{minute}:{second}");
	return Plugin_Handled;
}

public void cvar_change(ConVar convar, const char[] oldValue, const char[] newValue)
{
	char cvarname[64];
	char testdate[512];

	// Thanks to MAGNAT2645 for informing me I could do this!
	if (view_as<Handle>(convar) == cvar[CVAR_ENABLE]) {
		icvar[CVAR_ENABLE] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_WELCOME]) {
		icvar[CVAR_WELCOME] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_SB]) {
		icvar[CVAR_SB] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_MA]) {
		icvar[CVAR_MA] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_SOURCEIRC]) {
		icvar[CVAR_SOURCEIRC] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_LOG]) {
		icvar[CVAR_LOG] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_LOG_EXTRA]) {
		icvar[CVAR_LOG_EXTRA] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_LOG_MISC]) {
		icvar[CVAR_LOG_MISC] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_LOG_DATE]) {
		lilac_setup_date_format(newValue);

		FormatTime(testdate, sizeof(testdate), dateformat, GetTime());
		PrintToServer("Date Format Preview: %s", testdate);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_BAN]) {
		icvar[CVAR_BAN] = StringToInt(newValue, 10);

		if (!icvar[CVAR_BAN])
			PrintToServer("[Little Anti-Cheat %s] WARNING: 'lilac_ban' has been set to 0, banning of cheaters has been disabled.", PLUGIN_VERSION);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_BAN_LENGTH]) {
		icvar[CVAR_BAN_LENGTH] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_BAN_LANGUAGE]) {
		icvar[CVAR_BAN_LANGUAGE] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_ANGLES]) {
		icvar[CVAR_ANGLES] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_PATCH_ANGLES]) {
		icvar[CVAR_PATCH_ANGLES] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_CHAT]) {
		icvar[CVAR_CHAT] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_CONVAR]) {
		icvar[CVAR_CONVAR] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_NOLERP]) {
		icvar[CVAR_NOLERP] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_BHOP]) {
		icvar[CVAR_BHOP] = StringToInt(newValue, 10);
		lilac_bhop_set_preset();
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_AIMBOT]) {
		icvar[CVAR_AIMBOT] = StringToInt(newValue, 10);

		if (icvar[CVAR_AIMBOT] > 1 &&
			icvar[CVAR_AIMBOT] < AIMBOT_BAN_MIN)
			icvar[CVAR_AIMBOT] = 5;
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_AIMBOT_AUTOSHOOT]) {
		icvar[CVAR_AIMBOT_AUTOSHOOT] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_AIMLOCK]) {
		icvar[CVAR_AIMLOCK] = StringToInt(newValue, 10);

		if (icvar[CVAR_AIMLOCK] > 1
			&& icvar[CVAR_AIMLOCK] < AIMLOCK_BAN_MIN)
			icvar[CVAR_AIMLOCK] = 5;
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_AIMLOCK_LIGHT]) {
		icvar[CVAR_AIMLOCK_LIGHT] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_ANTI_DUCK_DELAY]) {
		icvar[CVAR_ANTI_DUCK_DELAY] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_NOISEMAKER_SPAM]) {
		icvar[CVAR_NOISEMAKER_SPAM] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_BACKTRACK_PATCH]) {
		icvar[CVAR_BACKTRACK_PATCH] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_BACKTRACK_TOLERANCE]) {
		icvar[CVAR_BACKTRACK_TOLERANCE] = StringToInt(newValue, 10);

		if (icvar[CVAR_BACKTRACK_TOLERANCE] > 2)
			PrintToServer("[Little Anti-Cheat %s] WARNING: It is not recommeded to set backtrack tolerance above 2, only do this if you understand what this means.", PLUGIN_VERSION);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_MAX_PING]) {
		icvar[CVAR_MAX_PING] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_MAX_PING_SPEC]) {
		icvar[CVAR_MAX_PING_SPEC] = StringToInt(newValue, 10);

		if (icvar[CVAR_MAX_PING_SPEC] < 30)
			icvar[CVAR_MAX_PING_SPEC] = 0;
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_MAX_LERP]) {
		icvar[CVAR_MAX_LERP] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_MACRO]) {
		icvar[CVAR_MACRO] = StringToInt(newValue, 10);

		if (icvar[CVAR_MACRO] > 0)
			PrintToServer("[Little Anti-Cheat %s] WARNING: It's recommended to use log-only method for now.", PLUGIN_VERSION);

		// Settings changed, reset counters.
		for (int i = 1; i <= MaxClients; i++)
			lilac_macro_reset_client(i);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_MACRO_WARNING]) {
		icvar[CVAR_MACRO_WARNING] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_MACRO_DEAL_METHOD]) {
		icvar[CVAR_MACRO_DEAL_METHOD] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_MACRO_MODE]) {
		icvar[CVAR_MACRO_MODE] = StringToInt(newValue, 10);
	}

	else if (view_as<Handle>(convar) == cvar[CVAR_FILTER_NAME]) {
		icvar[CVAR_FILTER_NAME] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_FILTER_CHAT]) {
		icvar[CVAR_FILTER_CHAT] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_LOSS_FIX]) {
		icvar[CVAR_LOSS_FIX] = StringToInt(newValue, 10);
	}
	else if (view_as<Handle>(convar) == cvar[CVAR_AUTO_UPDATE]) {
		icvar[CVAR_AUTO_UPDATE] = StringToInt(newValue, 10);

		lilac_update_url();
	}
	else {
		GetConVarName(convar, cvarname, sizeof(cvarname));

		if (StrEqual(cvarname, "sv_autobunnyhopping", false)) {
			force_disable_bhop = StringToInt(newValue, 10);
		}
		else if (StrEqual(cvarname, "sv_maxupdaterate", false)) {
			// NoLerp checks need to know this value.
			lilac_lerp_maxupdaterate_changed(StringToInt(newValue));

			// Changing this convar mid-game can cause false positives.
			// 	Ignore players already in-game.
			for (int i = 1; i <= MaxClients; i++)
				lilac_lerp_ignore_nolerp_client(i);
		}
		else if (StrEqual(cvarname, "sv_client_min_interp_ratio", false)) {
			lilac_lerp_ratio_changed(StringToInt(newValue));
		}
		else if (StrEqual(cvarname, "sv_client_max_interp_ratio", false)) {
			lilac_lerp_ratio_changed(StringToInt(newValue));
		}
		else if (StrEqual(cvarname, "sv_cheats", false)) {
			sv_cheats = StringToInt(newValue);

			// Delay convar checks for 30 seconds.
			time_sv_cheats = GetTime() + QUERY_TIMEOUT;
		}
	}
}

static void lilac_bhop_set_preset()
{
	int mode = intabs(icvar[CVAR_BHOP]);

	switch (mode) {
	// Backwards compatibility, mode 1 & 2 don't exist anymore.
	// If a config is already set to use these, change mode to medium.
	case BHOP_MODE_RESERVED_1, BHOP_MODE_RESERVED_2: {
		PrintToServer("[Lilac] Warning: Bhop mode 1 & 2 has been disabled, setting Bhop mode to %d (Medium).",
			BHOP_MODE_MEDIUM);
		SetConVarInt(cvar[CVAR_BHOP], BHOP_MODE_MEDIUM, false, false);
	}
	case BHOP_MODE_LOW, BHOP_MODE_CUSTOM: {
		// Can't do switch fall-through in SourcePawn.
		// Makes me miss C :(
		if (mode == BHOP_MODE_CUSTOM) {
			PrintToServer("[Lilac] WARNING: DO NOT USE CUSTOM BHOP MODE UNLESS YOU KNOW WHAT YOU ARE DOING!");
			PrintToServer("[Lilac] ВНИМАНИЕ: НЕ ИСПОЛЬЗУЙТЕ ПОЛЬЗОВАТЕЛЬСКИЙ РЕЖИМ BHOP, ЕСЛИ ВЫ НЕ ЗНАЕТЕ, ЧТО ВЫ ДЕЛАЕТЕ!");
		}

		bhop_settings[BHOP_INDEX_MIN] = 7;
		bhop_settings[BHOP_INDEX_JUMP] = 5;
		bhop_settings[BHOP_INDEX_MAX] = 20;
		if (bhop_settings_min[BHOP_INDEX_TOTAL] <= 3)
			bhop_settings[BHOP_INDEX_TOTAL] = 3;
		else // >-> ...
			bhop_settings[BHOP_INDEX_TOTAL] = bhop_settings_min[BHOP_INDEX_TOTAL];
	}
	case BHOP_MODE_MEDIUM: {
		bhop_settings[BHOP_INDEX_MIN] = 7;
		bhop_settings[BHOP_INDEX_JUMP] = -1;
		bhop_settings[BHOP_INDEX_MAX] = 15;
		bhop_settings[BHOP_INDEX_TOTAL] = 4;
	}
	case BHOP_MODE_HIGH: {
		bhop_settings[BHOP_INDEX_MIN] = 5;
		bhop_settings[BHOP_INDEX_JUMP] = -1;
		bhop_settings[BHOP_INDEX_MAX] = 12;
		if (bhop_settings_min[BHOP_INDEX_TOTAL] <= 3)
			bhop_settings[BHOP_INDEX_TOTAL] = 3;
		else
			bhop_settings[BHOP_INDEX_TOTAL] = bhop_settings_min[BHOP_INDEX_TOTAL];
	}
	}
}

static void lilac_setup_date_format(const char []format)
{
	strcopy(dateformat, sizeof(dateformat), format);

	if (ReplaceString(dateformat, sizeof(dateformat), "{raw}", "", false))
		return;

	ReplaceString(dateformat, sizeof(dateformat), "%%", "%%%%", false);

	ReplaceString(dateformat, sizeof(dateformat), "{year}", "%Y", false);
	ReplaceString(dateformat, sizeof(dateformat), "{month}", "%m", false);
	ReplaceString(dateformat, sizeof(dateformat), "{day}", "%d", false);

	ReplaceString(dateformat, sizeof(dateformat), "{hour}", "%H", false);
	ReplaceString(dateformat, sizeof(dateformat), "{hours}", "%H", false);
	ReplaceString(dateformat, sizeof(dateformat), "{24hour}", "%H", false);
	ReplaceString(dateformat, sizeof(dateformat), "{24hours}", "%H", false);
	ReplaceString(dateformat, sizeof(dateformat), "{12hour}", "%I", false);
	ReplaceString(dateformat, sizeof(dateformat), "{12hours}", "%I", false);
	ReplaceString(dateformat, sizeof(dateformat), "{pm}", "%p", false);
	ReplaceString(dateformat, sizeof(dateformat), "{am}", "%p", false);

	ReplaceString(dateformat, sizeof(dateformat), "{minute}", "%M", false);
	ReplaceString(dateformat, sizeof(dateformat), "{minutes}", "%M", false);
	ReplaceString(dateformat, sizeof(dateformat), "{second}", "%S", false);
	ReplaceString(dateformat, sizeof(dateformat), "{seconds}", "%S", false);
}
