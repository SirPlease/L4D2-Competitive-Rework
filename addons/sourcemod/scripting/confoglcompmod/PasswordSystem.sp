#if defined __password_system_included
	#endinput
#endif
#define __password_system_included

#define PS_MODULE_NAME			"PasswordSystem"

static char
	PS_sPassword[128] = "\0";

static bool
	PS_bIsPassworded = false,
	PS_bSuppress = false;

static ConVar
	PS_hReloaded = null,
	PS_hPassword = null;

void PS_OnModuleStart()
{
	PS_hPassword = CreateConVarEx( \
		"password", \
		"", \
		"Set a password on the server, if empty password disabled. See Confogl's wiki for more information", \
		FCVAR_DONTRECORD|FCVAR_PROTECTED \
	);

	PS_hReloaded = FindConVarEx("password_reloaded");

	if (PS_hReloaded == null) {
		PS_hReloaded = CreateConVarEx( \
			"password_reloaded", \
			"", \
			"DONT TOUCH THIS CVAR! This will is to make sure that the password gets set upon the plugin is reloaded", \
			FCVAR_DONTRECORD|FCVAR_UNLOGGED \
		);
	} else {
		char sBuffer[128];
		PS_hReloaded.GetString(sBuffer, sizeof(sBuffer));

		PS_hPassword.SetString(sBuffer);
		PS_hReloaded.SetString("");

		PS_hPassword.GetString(PS_sPassword, sizeof(PS_sPassword));

		PS_bIsPassworded = true;
		PS_SetPasswordOnClients();
	}

	PS_hPassword.AddChangeHook(PS_ConVarChange);

	HookEvent("player_disconnect", PS_SuppressDisconnectMsg, EventHookMode_Pre);
}

void PS_OnModuleEnd()
{
	if (!PS_bIsPassworded) {
		return;
	}

	PS_hReloaded.SetString(PS_sPassword);
}

static void PS_CheckPassword(int client)
{
	if (!PS_bIsPassworded || !IsPluginEnabled() || IsFakeClient(client)) {
		return;
	}

	CreateTimer(0.1, PS_CheckPassword_Timer, GetClientUserId(client), TIMER_REPEAT);
}

static Action PS_CheckPassword_Timer(Handle hTimer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client < 1) {
		return Plugin_Stop;
	}

	if (!IsClientInGame(client)) {
		return Plugin_Continue;
	}

	QueryClientConVar(client, "sv_password", PS_ConVarDone, userid);

	return Plugin_Stop;
}

static void PS_ConVarDone(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, int userid)
{
	if (result == ConVarQuery_Okay) {
		char buffer[128];
		PS_hPassword.GetString(buffer, sizeof(buffer));

		if (strcmp(buffer, cvarValue) == 0) {
			return;
		}
	}

	if (client == GetClientOfUserId(userid) && IsClientConnected(client)) {
		PS_bSuppress = true;

		KickClient(client, "Bad password");
	}
}

static void PS_ConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	PS_hPassword.GetString(PS_sPassword, sizeof(PS_sPassword));

	if (strlen(PS_sPassword) > 0) {
		PS_bIsPassworded = true;
		PS_SetPasswordOnClients();
	} else {
		PS_bIsPassworded = false;
	}
}

static Action PS_SuppressDisconnectMsg(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (bDontBroadcast || !PS_bSuppress) {
		return Plugin_Continue;
	}

	char clientName[33], networkID[22], reason[65];
	hEvent.GetString("name", clientName, sizeof(clientName));
	hEvent.GetString("networkid", networkID, sizeof(networkID));
	hEvent.GetString("reason", reason, sizeof(reason));

	Handle newEvent = CreateEvent("player_disconnect", true);
	SetEventInt(newEvent, "userid", hEvent.GetInt("userid"));
	SetEventString(newEvent, "reason", reason);
	SetEventString(newEvent, "name", clientName);
	SetEventString(newEvent, "networkid", networkID);
	FireEvent(newEvent, true);

	PS_bSuppress = false;

	return Plugin_Handled;
}

void PS_OnMapEnd()
{
	PS_SetPasswordOnClients();
}

void PS_OnClientPutInServer(int client)
{
	PS_CheckPassword(client);
}

static void PS_SetPasswordOnClients()
{
	char pwbuffer[128];
	PS_hPassword.GetString(pwbuffer, sizeof(pwbuffer));

	for (int client = 1; client <= MaxClients; client++) {
		if (!IsClientInGame(client) || IsFakeClient(client)){
			continue;
		}

		LogMessage("[%s] Set password on %N, password %s", PS_MODULE_NAME, client, pwbuffer);
		ClientCommand(client, "sv_password \"%s\"", pwbuffer);
	}
}
