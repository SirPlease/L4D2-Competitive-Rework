#if defined __reg_match_included
	#endinput
#endif
#define __reg_match_included

#define RM_DEBUG				0
#define RM_MODULE_NAME			"ReqMatch"

#define MAPRESTARTTIME			3.0
#define RESETMINTIME			60.0

static bool
	//RM_bMatchRequest[2] = {false, ...},
	RM_bIsMatchModeLoaded = false,
	RM_bIsAMatchActive = false,
	RM_bIsPluginsLoaded = false,
	RM_bIsMapRestarted = false;

static Handle
	RM_hFwdMatchLoad = null,
	RM_hFwdMatchUnload = null;

static ConVar
	RM_hSbAllBotGame = null,
	RM_hDoRestart = null,
	//RM_hAllowVoting = null,
	RM_hReloaded = null,
	RM_hAutoLoad = null,
	RM_hAutoCfg = null,
	RM_hConfigFile_On = null,
	RM_hConfigFile_Plugins = null,
	RM_hConfigFile_Off = null;

void RM_APL()
{
	RM_hFwdMatchLoad = CreateGlobalForward("LGO_OnMatchModeLoaded", ET_Ignore);
	RM_hFwdMatchUnload = CreateGlobalForward("LGO_OnMatchModeUnloaded", ET_Ignore);

	CreateNative("LGO_IsMatchModeLoaded", native_IsMatchModeLoaded);
}

void RM_OnModuleStart()
{
	RM_hDoRestart = CreateConVarEx("match_restart", "1", "Sets whether the plugin will restart the map upon match mode being forced or requested", _, true, 0.0, true, 1.0);
	//RM_hAllowVoting = CreateConVarEx("match_allowvoting", "1", "Sets whether players can vote/request for match mode", _, true, 0.0, true, 1.0);
	RM_hAutoLoad = CreateConVarEx("match_autoload", "0", "Has match mode start up automatically when a player connects and the server is not in match mode", _, true, 0.0, true, 1.0);
	RM_hAutoCfg = CreateConVarEx("match_autoconfig", "", "Specify which config to load if the autoloader is enabled");
	RM_hConfigFile_On = CreateConVarEx("match_execcfg_on", "confogl.cfg", "Execute this config file upon match mode starts and every map after that.");
	//RM_hConfigFile_Plugins = CreateConVarEx("match_execcfg_plugins", "confogl_plugins.cfg", "Execute this config file upon match mode starts. This will only get executed once and meant for plugins that needs to be loaded."); //original
	RM_hConfigFile_Plugins = CreateConVarEx("match_execcfg_plugins", "generalfixes.cfg;confogl_plugins.cfg;sharedplugins.cfg", "Execute this config file upon match mode starts. This will only get executed once and meant for plugins that needs to be loaded."); //rework
	RM_hConfigFile_Off = CreateConVarEx("match_execcfg_off", "confogl_off.cfg", "Execute this config file upon match mode ends.");

	//RegConsoleCmd("sm_match", RM_Cmd_Match);
	RegAdminCmd("sm_forcematch", RM_Cmd_ForceMatch, ADMFLAG_CONFIG, "Forces the game to use match mode");
	RegAdminCmd("sm_fm", RM_Cmd_ForceMatch, ADMFLAG_CONFIG, "Forces the game to use match mode");
	RegAdminCmd("sm_resetmatch", RM_Cmd_ResetMatch, ADMFLAG_CONFIG, "Forces match mode to turn off REGRADLESS for always on or forced match");

	RM_hSbAllBotGame = FindConVar("sb_all_bot_game");

	RM_hReloaded = FindConVarEx("match_reloaded");
	if (RM_hReloaded == null) {
		RM_hReloaded = CreateConVarEx("match_reloaded", "0", "DONT TOUCH THIS CVAR! This is to prevent match feature keep looping, however the plugin takes care of it. Don't change it!", FCVAR_DONTRECORD|FCVAR_UNLOGGED);
	}

	if (RM_hReloaded.BoolValue) {
		if (RM_DEBUG || IsDebugEnabled()) {
			LogMessage("[%s] Plugin was reloaded from match mode, executing match load", RM_MODULE_NAME);
		}

		RM_bIsPluginsLoaded = true;
		RM_hReloaded.SetInt(0);
		RM_Match_Load();
	}
}

void RM_OnMapStart()
{
	if (!RM_bIsMatchModeLoaded) {
		return;
	}

	if (RM_DEBUG || IsDebugEnabled()) {
		LogMessage("[%s] New map, executing match config...", RM_MODULE_NAME);
	}

	RM_Match_Load();
}

void RM_OnClientPutInServer()
{
	if (!RM_hAutoLoad.BoolValue || RM_bIsAMatchActive) {
		return;
	}

	char buffer[128];
	RM_hAutoCfg.GetString(buffer, sizeof(buffer));

	RM_UpdateCfgOn(buffer);
	RM_Match_Load();
}

static void RM_Match_Load()
{
	if (RM_DEBUG || IsDebugEnabled()) {
		LogMessage("[%s] Match Load", RM_MODULE_NAME);
	}

	if (!RM_bIsAMatchActive) {
		RM_bIsAMatchActive = true;
	}

	RM_hSbAllBotGame.SetInt(1);
	char sBuffer[128];

	if (!RM_bIsPluginsLoaded) {
		if (RM_DEBUG || IsDebugEnabled()) {
			LogMessage("[%s] Loading plugins and reload self", RM_MODULE_NAME);
		}

		RM_hReloaded.SetInt(1);
		RM_hConfigFile_Plugins.GetString(sBuffer, sizeof(sBuffer));

		//ExecuteCfg(sBuffer); //original
		//rework
		char sPieces[32][256];
		int iNumPieces = ExplodeString(sBuffer, ";", sPieces, sizeof(sPieces), sizeof(sPieces[]));

		// Unlocking and Unloading Plugins.
		ServerCommand("sm plugins load_unlock");
		ServerCommand("sm plugins unload_all");

		// Loading Plugins.
		for (int i = 0; i < iNumPieces; i++) {
			ExecuteCfg(sPieces[i]);
		}
		//rework end

		return;
	}

	RM_hConfigFile_On.GetString(sBuffer, sizeof(sBuffer));
	ExecuteCfg(sBuffer);

	if (RM_DEBUG || IsDebugEnabled()) {
		LogMessage("[%s] Match config executed", RM_MODULE_NAME);
	}

	if (RM_bIsMatchModeLoaded) {
		return;
	}

	if (RM_DEBUG || IsDebugEnabled()) {
		LogMessage("[%s] Setting match mode active", RM_MODULE_NAME);
	}

	RM_bIsMatchModeLoaded = true;
	IsPluginEnabled(true, true);

	//PrintToChatAll("\x01[\x05Confogl\x01] Match mode loaded!");
	CPrintToChatAll("{blue}[{default}Confogl{blue}]{default} Match mode loaded!");

	if (!RM_bIsMapRestarted && RM_hDoRestart.BoolValue) {
		//PrintToChatAll("\x01[\x05Confogl\x01] Restarting map!");
		CPrintToChatAll("{blue}[{default}Confogl{blue}]{default} Restarting map!");

		CreateTimer(MAPRESTARTTIME, RM_Match_MapRestart_Timer);
	}

	if (RM_DEBUG || IsDebugEnabled()) {
		LogMessage("[%s] Match mode loaded!", RM_MODULE_NAME);
	}

	Call_StartForward(RM_hFwdMatchLoad);
	Call_Finish();
}

static void RM_Match_Unload(bool bForced = false)
{
	bool bIsHumansOnServer = IsHumansOnServer();

	if (!bIsHumansOnServer || bForced) {
		if (RM_DEBUG || IsDebugEnabled()) {
			LogMessage("[%s] Match is no longer active, sb_all_bot_game reset to 0, IsHumansOnServer %b, bForced %b", RM_MODULE_NAME, bIsHumansOnServer, bForced);
		}

		RM_bIsAMatchActive = false;
		RM_hSbAllBotGame.SetInt(0);
	}

	if (bIsHumansOnServer && !bForced) {
		return;
	}

	if (RM_DEBUG || IsDebugEnabled()) {
		LogMessage("[%s] Unloading match mode...", RM_MODULE_NAME);
	}

	char sBuffer[128];
	RM_bIsMatchModeLoaded = false;
	IsPluginEnabled(true, false);
	RM_bIsMapRestarted = false;
	RM_bIsPluginsLoaded = false;

	Call_StartForward(RM_hFwdMatchUnload);
	Call_Finish();

	//PrintToChatAll("\x01[\x05Confogl\x01] Match mode unloaded!");
	CPrintToChatAll("{blue}[{default}Confogl{blue}]{default} Match mode unloaded!");

	RM_hConfigFile_Off.GetString(sBuffer, sizeof(sBuffer));
	ExecuteCfg(sBuffer);

	if (RM_DEBUG || IsDebugEnabled()) {
		LogMessage("[%s] Match mode unloaded!", RM_MODULE_NAME);
	}
}

public Action RM_Match_MapRestart_Timer(Handle hTimer)
{
	ServerCommand("sm plugins load_lock"); //rework

	if (RM_DEBUG || IsDebugEnabled()) {
		LogMessage("[%s] Restarting map...", RM_MODULE_NAME);
	}

	char sBuffer[128];
	GetCurrentMap(sBuffer, sizeof(sBuffer));
	ServerCommand("changelevel %s", sBuffer);
	RM_bIsMapRestarted = true;

	return Plugin_Stop;
}

static bool RM_UpdateCfgOn(const char[] cfgfile, bool bIsPrint = true)
{
	if (SetCustomCfg(cfgfile)) {
		//PrintToChatAll("\x01[\x05Confogl\x01] Using \"\x04%s\x01\" config.", cfgfile);
		CPrintToChatAll("{blue}[{default}Confogl{blue}]{default} Loading '{olive}%s{default}'.", cfgfile);

		if (RM_DEBUG || IsDebugEnabled()) {
			LogMessage("[%s] Starting match on config %s", RM_MODULE_NAME, cfgfile);
		}

		return true;
	}

	if (bIsPrint) {
		//PrintToChatAll("\x01[\x05Confogl\x01] Config \"\x04%s\x01\" not found, using default config!", cfgfile);
		CPrintToChatAll("{blue}[{default}Confogl{blue}]{default} Config '{olive}%s{default}' not found, using default config!", cfgfile);
	}

	return false;
}

public Action RM_Cmd_ForceMatch(int client, int args)
{
	if (RM_bIsMatchModeLoaded) {
		return Plugin_Handled;
	}

	if (RM_DEBUG || IsDebugEnabled()) {
		LogMessage("[%s] Match mode forced to load!", RM_MODULE_NAME);
	}

	if (args < 1) {
		//SetCustomCfg(""); //old code
		//RM_Match_Load(); //old code

		if (client == 0) {
			PrintToServer("[Confogl] Please specify a config to load.");
		} else {
			//PrintToChat(client, "\x01[\x05Confogl\x01] Please specify a \x04config\x01 to load.");
			CPrintToChat(client, "{blue}[{default}Confogl{blue}]{default} Please specify a {olive}config{default} to load.");
		}
		return Plugin_Handled;
	}

	char sBuffer[128];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));

	//RM_UpdateCfgOn(sBuffer); //old code

	if (!RM_UpdateCfgOn(sBuffer, false)) {
		if (client == 0) {
			PrintToServer("[Confogl] Config %s not found!", sBuffer);
		} else {
			//PrintToChat(client, "\x01[\x05Confogl\x01] Please specify a \"\x04%s\x01\" to load.", sBuffer);
			CPrintToChat(client, "{blue}[{default}Confogl{blue}]{default} Config '{olive}%s{default}' not found!", sBuffer);
		}

		return Plugin_Handled;
	}

	RM_Match_Load();

	return Plugin_Handled;
}

public Action RM_Cmd_ResetMatch(int client, int args)
{
	if (!RM_bIsMatchModeLoaded) {
		return Plugin_Handled;
	}

	if (RM_DEBUG || IsDebugEnabled()) {
		LogMessage("[%s] Match mode forced to unload!", RM_MODULE_NAME);
	}

	RM_Match_Unload(true);

	return Plugin_Handled;
}

/*public Action RM_Cmd_Match(int client, int args)
{
	if (RM_bIsMatchModeLoaded || (!IsVersus() && !IsScavenge()) || !RM_hAllowVoting.BoolValue) {
		return Plugin_Handled;
	}

	int iTeam = GetClientTeam(client);
	if ((iTeam == L4D2Team_Survivor || iTeam == L4D2Team_Infected) && !RM_bMatchRequest[iTeam - 2]) {
		RM_bMatchRequest[iTeam - 2] = true;
	} else {
		return Plugin_Handled;
	}

	if (RM_bMatchRequest[0] && RM_bMatchRequest[1]) {
		//PrintToChatAll("\x01[\x05Confogl\x01] Both teams have agreed to start a competitive match!");
		CPrintToChatAll("{blue}[{default}Confogl{blue}]{default} Both teams have agreed to start a competitive match!");

		RM_Match_Load();
	} else if (RM_bMatchRequest[0] || RM_bMatchRequest[1]) {
		//PrintToChatAll("\x01[\x05Confogl\x01] The \x04%s\x01 have requested to start a competitive match. The \x04%s\x01 must accept with match command!",
								//g_sTeamName[iTeam + 4], g_sTeamName[iTeam + 3]);
		CPrintToChatAll("{blue}[{default}Confogl{blue}]{default} The {olive}%s{default} have requested to start a competitive match. The {olive}%s{default} must accept with match command!", \
								g_sTeamName[iTeam + 4], g_sTeamName[iTeam + 3]);

		if (args > 0) { // cfgfile specified
			char sBuffer[128];
			GetCmdArg(1, sBuffer, sizeof(sBuffer));
			RM_UpdateCfgOn(sBuffer);
		} else {
			SetCustomCfg("");
		}

		CreateTimer(30.0, RM_MatchRequestTimeout);
	}

	return Plugin_Handled;
}

public Action RM_MatchRequestTimeout(Handle hTimer)
{
	RM_ResetMatchRequest();

	return Plugin_Stop;
}*/

void RM_OnClientDisconnect(int client)
{
	if (!RM_bIsMatchModeLoaded || IsFakeClient(client)) {
		return;
	}

	CreateTimer(RESETMINTIME, RM_MatchResetTimer);
}

public Action RM_MatchResetTimer(Handle hTimer)
{
	RM_Match_Unload();

	return Plugin_Stop;
}

/*static void RM_ResetMatchRequest()
{
	RM_hConfigFile_On.RestoreDefault();

	RM_bMatchRequest[0] = false;
	RM_bMatchRequest[1] = false;
}*/

stock bool IsAMatchActive()
{
	return RM_bIsAMatchActive;
}

public int native_IsMatchModeLoaded(Handle plugin, int numParams)
{
	return RM_bIsMatchModeLoaded;
}
