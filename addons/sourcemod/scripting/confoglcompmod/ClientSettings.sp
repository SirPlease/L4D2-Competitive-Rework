#if defined __client_settings_include
	#endinput
#endif
#define __client_settings_include

#define CLS_MODULE_NAME				"ClientSettings"

#define CLS_CVAR_MAXLEN				64
#define CLIENT_CHECK_INTERVAL		5.0

enum /*CLSAction*/
{
	CLSA_Kick = 0,
	CLSA_Log
};

#if SOURCEMOD_V_MINOR > 9
enum struct CLSEntry
{
	bool CLSE_hasMin;
	float CLSE_min;
	bool CLSE_hasMax;
	float CLSE_max;
	int CLSE_action;
	char CLSE_cvar[CLS_CVAR_MAXLEN];
}
#else
enum CLSEntry
{
	bool:CLSE_hasMin,
	Float:CLSE_min,
	bool:CLSE_hasMax,
	Float:CLSE_max,
	CLSE_action,
	String:CLSE_cvar[CLS_CVAR_MAXLEN]
};
#endif

static ArrayList
	ClientSettingsArray = null;

static Handle
	ClientSettingsCheckTimer = null;

void CLS_OnModuleStart()
{
#if SOURCEMOD_V_MINOR > 9
	CLSEntry clsetting;
#else
	CLSEntry clsetting[CLSEntry];
#endif

	ClientSettingsArray = new ArrayList(sizeof(clsetting));

	RegConsoleCmd("confogl_clientsettings", _ClientSettings_Cmd, "List Client settings enforced by confogl");

	/* Using Server Cmd instead of admin because these shouldn't really be changed on the fly */
	RegServerCmd("confogl_trackclientcvar", _TrackClientCvar_Cmd, "Add a Client CVar to be tracked and enforced by confogl");
	RegServerCmd("confogl_resetclientcvars", _ResetTracking_Cmd, "Remove all tracked client cvars. Cannot be called during matchmode");
	RegServerCmd("confogl_startclientchecking", _StartClientChecking_Cmd, "Start checking and enforcing client cvars tracked by this plugin");
}

static void ClearAllSettings()
{
	ClientSettingsArray.Clear();
}

/*#if SOURCEMOD_V_MINOR > 9
static void ClearCLSEntry(CLSEntry entry)
{
	entry.CLSE_hasMin = false;
	entry.CLSE_min = 0.0;
	entry.CLSE_hasMax = false;
	entry.CLSE_max = 0.0;
	entry.CLSE_cvar[0] = 0;
}
#else
static void ClearCLSEntry(CLSEntry entry[CLSEntry])
{
	entry[CLSE_hasMin] = false;
	entry[CLSE_min] = 0.0;
	entry[CLSE_hasMax] = false;
	entry[CLSE_max] = 0.0;
	entry[CLSE_cvar][0] = 0;
}
#endif*/

static Action _CheckClientSettings_Timer(Handle hTimer)
{
	if (!IsPluginEnabled()) {
		if (IsDebugEnabled()) {
			LogMessage("[%s] Stopping client settings tracking", CLS_MODULE_NAME);
		}

		ClientSettingsCheckTimer = null;
		return Plugin_Stop;
	}

	EnforceAllCliSettings();
	return Plugin_Continue;
}

static void EnforceAllCliSettings()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			EnforceCliSettings(i);
		}
	}
}

static void EnforceCliSettings(int client)
{
	int iSize = ClientSettingsArray.Length;
#if SOURCEMOD_V_MINOR > 9
	CLSEntry clsetting;
	for (int i = 0; i < iSize; i++) {
		ClientSettingsArray.GetArray(i, clsetting, sizeof(clsetting));

		QueryClientConVar(client, clsetting.CLSE_cvar, _EnforceCliSettings_QueryReply, i);
	}
#else
	CLSEntry clsetting[CLSEntry];
	for (int i = 0; i < iSize; i++) {
		ClientSettingsArray.GetArray(i, clsetting[0], sizeof(clsetting));

		QueryClientConVar(client, clsetting[CLSE_cvar], _EnforceCliSettings_QueryReply, i);
	}
#endif
}

static void _EnforceCliSettings_QueryReply(QueryCookie cookie, int client, ConVarQueryResult result, \
												const char[] cvarName, const char[] cvarValue, any value)
{
	if (!IsClientConnected(client) || !IsClientInGame(client) || IsClientInKickQueue(client)) {
		// Client disconnected or got kicked already
		return;
	}

	if (result) {
		LogMessage("[%s] Couldn't retrieve cvar %s from %L, kicked from server", CLS_MODULE_NAME, cvarName, client);
		KickClient(client, "CVar '%s' protected or missing! Hax?", cvarName);
		return;
	}

	float fCvarVal = StringToFloat(cvarValue);
	int clsetting_index = value;

#if SOURCEMOD_V_MINOR > 9
	CLSEntry clsetting;
	ClientSettingsArray.GetArray(clsetting_index, clsetting, sizeof(clsetting));

	if ((clsetting.CLSE_hasMin && fCvarVal < clsetting.CLSE_min)
		|| (clsetting.CLSE_hasMax && fCvarVal > clsetting.CLSE_max)
	) {
		switch (clsetting.CLSE_action) {
			case CLSA_Kick: {
				LogMessage("[%s] Kicking %L for bad %s value (%f). Min: %d %f Max: %d %f", \
									CLS_MODULE_NAME, client, cvarName, fCvarVal, clsetting.CLSE_hasMin, \
										clsetting.CLSE_min, clsetting.CLSE_hasMax, clsetting.CLSE_max);

				/*PrintToChatAll("\x01[\x05Confogl\x01] Kicking \x04%L\x01 for having an illegal value for '\x04%s\x01' (\x04%f\x01) !!!", \
									client, cvarName, fCvarVal);*/
				CPrintToChatAll("{blue}[{default}Confogl{blue}] {olive}%L{default} was kicked for having an illegal value for '{green}%s{default}' {blue}({default}%f{blue})", \
									client, cvarName, fCvarVal);

				char kickMessage[256] = "Illegal Client Value for ";
				Format(kickMessage, sizeof(kickMessage), "%s%s (%.2f)", kickMessage, cvarName, fCvarVal);

				if (clsetting.CLSE_hasMin) {
					Format(kickMessage, sizeof(kickMessage), "%s, Min %.2f", kickMessage, clsetting.CLSE_min);
				}

				if (clsetting.CLSE_hasMax) {
					Format(kickMessage, sizeof(kickMessage), "%s, Max %.2f", kickMessage, clsetting.CLSE_max);
				}

				KickClient(client, "%s", kickMessage);
			}
			case CLSA_Log: {
				LogMessage("[%s] Client %L has a bad %s value (%f). Min: %d %f Max: %d %f", \
									CLS_MODULE_NAME, client, cvarName, fCvarVal, clsetting.CLSE_hasMin, \
										clsetting.CLSE_min, clsetting.CLSE_hasMax, clsetting.CLSE_max);
			}
		}
	}
#else
	CLSEntry clsetting[CLSEntry];
	ClientSettingsArray.GetArray(clsetting_index, clsetting[0], sizeof(clsetting));

	if ((clsetting[CLSE_hasMin] && fCvarVal < clsetting[CLSE_min])
		|| (clsetting[CLSE_hasMax] && fCvarVal > clsetting[CLSE_max])
	) {
		switch (clsetting[CLSE_action]) {
			case CLSA_Kick: {
				LogMessage("[%s] Kicking %L for bad %s value (%f). Min: %d %f Max: %d %f", \
									CLS_MODULE_NAME, client, cvarName, fCvarVal, clsetting[CLSE_hasMin], \
										clsetting[CLSE_min], clsetting[CLSE_hasMax], clsetting[CLSE_max]);

				/*PrintToChatAll("\x01[\x05Confogl\x01] Kicking \x04%L\x01 for having an illegal value for '\x04%s\x01' (\x04%f\x01) !!!", \
									client, cvarName, fCvarVal);*/
				CPrintToChatAll("{blue}[{default}Confogl{blue}] {olive}%L{default} was kicked for having an illegal value for '{green}%s{default}' {blue}({default}%f{blue})", \
									client, cvarName, fCvarVal);

				char kickMessage[256] = "Illegal Client Value for ";
				Format(kickMessage, sizeof(kickMessage), "%s%s (%.2f)", kickMessage, cvarName, fCvarVal);

				if (clsetting[CLSE_hasMin]) {
					Format(kickMessage, sizeof(kickMessage), "%s, Min %.2f", kickMessage, clsetting[CLSE_min]);
				}

				if (clsetting[CLSE_hasMax]) {
					Format(kickMessage, sizeof(kickMessage), "%s, Max %.2f", kickMessage, clsetting[CLSE_max]);
				}

				KickClient(client, "%s", kickMessage);
			}
			case CLSA_Log: {
				LogMessage("[%s] Client %L has a bad %s value (%f). Min: %d %f Max: %d %f", \
									CLS_MODULE_NAME, client, cvarName, fCvarVal, clsetting[CLSE_hasMin], \
										clsetting[CLSE_min], clsetting[CLSE_hasMax], clsetting[CLSE_max]);
			}
		}
	}
#endif
}

static Action _ClientSettings_Cmd(int client, int args)
{
	int iSize = ClientSettingsArray.Length;
	ReplyToCommand(client, "[Confogl] Tracked Client CVars (Total %d)", iSize);

#if SOURCEMOD_V_MINOR > 9
	CLSEntry clsetting;
#else
	CLSEntry clsetting[CLSEntry];
#endif

	char message[256], shortbuf[64];
	for (int i = 0; i < iSize; i++) {
		#if SOURCEMOD_V_MINOR > 9
			ClientSettingsArray.GetArray(i, clsetting, sizeof(clsetting));
			Format(message, sizeof(message), "[Confogl] Client CVar: %s ", clsetting.CLSE_cvar);

			if (clsetting.CLSE_hasMin) {
				Format(shortbuf, sizeof(shortbuf), "Min: %f ", clsetting.CLSE_min);
				StrCat(message, sizeof(message), shortbuf);
			}

			if (clsetting.CLSE_hasMax) {
				Format(shortbuf, sizeof(shortbuf), "Max: %f ", clsetting.CLSE_max);
				StrCat(message, sizeof(message), shortbuf);
			}

			switch (clsetting.CLSE_action) {
				case CLSA_Kick: {
					StrCat(message, sizeof(message), "Action: Kick");
				}
				case CLSA_Log: {
					StrCat(message, sizeof(message), "Action: Log");
				}
			}
		#else
			ClientSettingsArray.GetArray(i, clsetting[0], sizeof(clsetting));
			Format(message, sizeof(message), "[Confogl] Client CVar: %s ", clsetting[CLSE_cvar]);

			if (clsetting[CLSE_hasMin]) {
				Format(shortbuf, sizeof(shortbuf), "Min: %f ", clsetting[CLSE_min]);
				StrCat(message, sizeof(message), shortbuf);
			}

			if (clsetting[CLSE_hasMax]) {
				Format(shortbuf, sizeof(shortbuf), "Max: %f ", clsetting[CLSE_max]);
				StrCat(message, sizeof(message), shortbuf);
			}

			switch (clsetting[CLSE_action]) {
				case CLSA_Kick: {
					StrCat(message, sizeof(message), "Action: Kick");
				}
				case CLSA_Log: {
					StrCat(message, sizeof(message), "Action: Log");
				}
			}
		#endif

		ReplyToCommand(client, message);
	}

	return Plugin_Handled;
}

static Action _TrackClientCvar_Cmd(int args)
{
	if (args < 3 || args == 4) {
		PrintToServer("Usage: confogl_trackclientcvar <cvar> <hasMin> <min> [<hasMax> <max> [<action>]]");

		if (IsDebugEnabled()) {
			char cmdbuf[128];
			GetCmdArgString(cmdbuf, sizeof(cmdbuf));
			Debug_LogError(CLS_MODULE_NAME, "Invalid track client cvar: %s", cmdbuf);
		}

		return Plugin_Handled;
	}

	char sBuffer[CLS_CVAR_MAXLEN], cvar[CLS_CVAR_MAXLEN];
	bool hasMax;
	float max;
	int action = CLSA_Kick;

	GetCmdArg(1, cvar, sizeof(cvar));

	if (!strlen(cvar)) {
		PrintToServer("Unreadable cvar");

		if (IsDebugEnabled()) {
			char cmdbuf[128];
			GetCmdArgString(cmdbuf, sizeof(cmdbuf));
			Debug_LogError(CLS_MODULE_NAME, "Invalid track client cvar: %s", cmdbuf);
		}

		return Plugin_Handled;
	}

	GetCmdArg(2, sBuffer, sizeof(sBuffer));
	bool hasMin = view_as<bool>(StringToInt(sBuffer));

	GetCmdArg(3, sBuffer, sizeof(sBuffer));
	float min = StringToFloat(sBuffer);

	if (args >= 5) {
		GetCmdArg(4, sBuffer, sizeof(sBuffer));
		hasMax = view_as<bool>(StringToInt(sBuffer));

		GetCmdArg(5, sBuffer, sizeof(sBuffer));
		max = StringToFloat(sBuffer);
	}

	if (args >= 6) {
		GetCmdArg(6, sBuffer, sizeof(sBuffer));
		action = StringToInt(sBuffer);
	}

	_AddClientCvar(cvar, hasMin, min, hasMax, max, action);

	return Plugin_Handled;
}

static Action _ResetTracking_Cmd(int args)
{
	if (ClientSettingsCheckTimer != null) {
		PrintToServer("Can't reset tracking in the middle of a match");
		return Plugin_Handled;
	}

	ClearAllSettings();
	PrintToServer("Client CVar Tracking Information Reset!");

	return Plugin_Handled;
}

static Action _StartClientChecking_Cmd(int args)
{
	_StartTracking();

	return Plugin_Handled;
}

static void _StartTracking()
{
	if (IsPluginEnabled() && ClientSettingsCheckTimer == null) {
		if (IsDebugEnabled()) {
			LogMessage("[%s] Starting repeating check timer", CLS_MODULE_NAME);
		}

		ClientSettingsCheckTimer = CreateTimer(CLIENT_CHECK_INTERVAL, _CheckClientSettings_Timer, _, TIMER_REPEAT);
	} else {
		PrintToServer("Can't start plugin tracking or tracking already started");
	}
}

static void _AddClientCvar(const char[] cvar, bool hasMin, float min, bool hasMax, float max, int action)
{
	if (ClientSettingsCheckTimer != null) {
		PrintToServer("Can't track new cvars in the middle of a match");

		if (IsDebugEnabled()) {
			LogMessage("[%s] Attempt to track new cvar %s during a match!", CLS_MODULE_NAME, cvar);
		}

		return;
	}

	if (!(hasMin || hasMax)) {
		Debug_LogError(CLS_MODULE_NAME, "Client CVar %s specified without max or min", cvar);
		return;
	}

	if (hasMin && hasMax && max < min) {
		Debug_LogError(CLS_MODULE_NAME, "Client CVar %s specified max < min (%f < %f)", cvar, max, min);
		return;
	}

	if (strlen(cvar) >= CLS_CVAR_MAXLEN) {
		Debug_LogError(CLS_MODULE_NAME, "CVar Specified (%s) is longer than max cvar length (%d)", cvar, CLS_CVAR_MAXLEN);
		return;
	}

	int iSize = ClientSettingsArray.Length;

#if SOURCEMOD_V_MINOR > 9
	CLSEntry newEntry;
	for (int i = 0; i < iSize; i++) {
		ClientSettingsArray.GetArray(i, newEntry, sizeof(newEntry));
		if (strcmp(newEntry.CLSE_cvar, cvar, false) == 0) {
			Debug_LogError(CLS_MODULE_NAME, "Attempt to track CVar %s, which is already being tracked.", cvar);
			return;
		}
	}

	newEntry.CLSE_hasMin = hasMin;
	newEntry.CLSE_min = min;
	newEntry.CLSE_hasMax = hasMax;
	newEntry.CLSE_max = max;
	newEntry.CLSE_action = action;
	strcopy(newEntry.CLSE_cvar, CLS_CVAR_MAXLEN, cvar);

	if (IsDebugEnabled()) {
		LogMessage("[%s] Tracking Cvar %s Min %d %f Max %d %f Action %d", CLS_MODULE_NAME, cvar, hasMin, min, hasMax, max, action);
	}

	ClientSettingsArray.PushArray(newEntry, sizeof(newEntry));
#else
	CLSEntry newEntry[CLSEntry];
	for (int i = 0; i < iSize; i++) {
		ClientSettingsArray.GetArray(i, newEntry[0], sizeof(newEntry));
		if (strcmp(newEntry[CLSE_cvar], cvar, false) == 0) {
			Debug_LogError(CLS_MODULE_NAME, "Attempt to track CVar %s, which is already being tracked.", cvar);
			return;
		}
	}

	newEntry[CLSE_hasMin] = hasMin;
	newEntry[CLSE_min] = min;
	newEntry[CLSE_hasMax] = hasMax;
	newEntry[CLSE_max] = max;
	newEntry[CLSE_action] = action;
	strcopy(newEntry[CLSE_cvar], CLS_CVAR_MAXLEN, cvar);

	if (IsDebugEnabled()) {
		LogMessage("[%s] Tracking Cvar %s Min %d %f Max %d %f Action %d", CLS_MODULE_NAME, cvar, hasMin, min, hasMax, max, action);
	}

	ClientSettingsArray.PushArray(newEntry[0], sizeof(newEntry));
#endif
}
