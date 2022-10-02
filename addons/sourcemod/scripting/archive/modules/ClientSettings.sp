

#if defined __CLIENTSETTINGS_MODULE__
#endinput
#endif

#define __CLIENTSETTINGS_MODULE__

#define CLS_CVAR_MAXLEN	64

static const Float:CLIENT_CHECK_INTERVAL = 5.0;


enum CLSAction{
	CLSA_Kick=0,
	CLSA_Log
};

enum CLSEntry {
	bool:CLSE_hasMin,
	Float:CLSE_min,
	bool:CLSE_hasMax,
	Float:CLSE_max,
	CLSAction:CLSE_action,
	String:CLSE_cvar[CLS_CVAR_MAXLEN]
};

static Handle:ClientSettingsArray;
static Handle:ClientSettingsCheckTimer;


CLS_OnModuleStart()
{
	ClientSettingsArray = CreateArray(_:CLSEntry);
	RegConsoleCmd("confogl_clientsettings", _ClientSettings_Cmd, "List Client settings enforced by confogl");
	/* Using Server Cmd instead of admin because these shouldn't really be changed on the fly */
	RegServerCmd("confogl_trackclientcvar", _TrackClientCvar_Cmd, "Add a Client CVar to be tracked and enforced by confogl");
	RegServerCmd("confogl_resetclientcvars", _ResetTracking_Cmd, "Remove all tracked client cvars. Cannot be called during matchmode");
	RegServerCmd("confogl_startclientchecking", _StartClientChecking_Cmd, "Start checking and enforcing client cvars tracked by this plugin");
}

static ClearAllSettings()
{
	ClearArray(ClientSettingsArray);
}

stock static ClearCLSEntry(entry[CLSEntry])
{
	entry[CLSE_hasMin]=false;
	entry[CLSE_min]=0.0;
	entry[CLSE_hasMax]=false;
	entry[CLSE_max]=0.0;
	entry[CLSE_cvar][0]=0;
}

public Action:_CheckClientSettings_Timer(Handle:timer)
{
	if(!IsPluginEnabled())
	{
		if(IsDebugEnabled())
		{
			LogMessage("[confogl] ClientSettings: Stopping client settings tracking");
		}
		ClientSettingsCheckTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	EnforceAllCliSettings();
	return Plugin_Continue;
}

static EnforceAllCliSettings()
{
	for(new client = 1; client < MaxClients+1; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			EnforceCliSettings(client);
		}
	}
}

static EnforceCliSettings(client)
{
	new clsetting[CLSEntry];
	for(new i = 0; i < GetArraySize(ClientSettingsArray); i++)
	{
		GetArrayArray(ClientSettingsArray, i, clsetting[0]);
		QueryClientConVar(client, clsetting[CLSE_cvar], _EnforceCliSettings_QueryReply, i);
	}
}

public _EnforceCliSettings_QueryReply(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], any:value)
{
	if(!IsClientConnected(client) || !IsClientInGame(client) || IsClientInKickQueue(client))
	{
		// Client disconnected or got kicked already
		return;
	}
	if(result)
	{
		LogMessage("[Confogl] ClientSettings: Couldn't retrieve cvar %s from %L, kicked from server", cvarName, client);
		KickClient(client, "CVar '%s' protected or missing! Hax?", cvarName);
		return;
	}
	new Float:fCvarVal = StringToFloat(cvarValue);
	new clsetting_index = value;
	decl clsetting[CLSEntry];
	GetArrayArray(ClientSettingsArray, clsetting_index, clsetting[0]);
	
	if((clsetting[CLSE_hasMin] && fCvarVal < clsetting[CLSE_min])
		|| (clsetting[CLSE_hasMax] && fCvarVal > clsetting[CLSE_max]))
	{
		switch (clsetting[CLSE_action])
		{
			case CLSA_Kick:
			{
				LogMessage("[Confogl] ClientSettings: Kicking %L for bad %s value (%f). Min: %d %f Max: %d %f", \
					client, cvarName, fCvarVal, clsetting[CLSE_hasMin], clsetting[CLSE_min], clsetting[CLSE_hasMax], clsetting[CLSE_max]);
				CPrintToChatAll("{blue}[{default}Confogl{blue}] {olive}%L {default} was kicked for having an illegal value for {green}%s {blue}({default}%f{blue})", client, cvarName, fCvarVal);
				new String:kickMessage[256] = "Illegal Client Value for ";
				Format(kickMessage, sizeof(kickMessage), "%s%s (%.2f)", kickMessage, cvarName, fCvarVal);
				if (clsetting[CLSE_hasMin])
					Format(kickMessage, sizeof(kickMessage), "%s, Min %.2f", kickMessage, clsetting[CLSE_min]);
				if (clsetting[CLSE_hasMax])
					Format(kickMessage, sizeof(kickMessage), "%s, Max %.2f", kickMessage, clsetting[CLSE_max]);
				KickClient(client, "%s", kickMessage);
			}
			case CLSA_Log:
			{
				LogMessage("[Confogl] ClientSettings: Client %L has a bad %s value (%f). Min: %d %f Max: %d %f", \
					client, cvarName, fCvarVal, clsetting[CLSE_hasMin], clsetting[CLSE_min], clsetting[CLSE_hasMax], clsetting[CLSE_max]);
			}
		}
	}
	
}

public Action:_ClientSettings_Cmd(client, args)
{
	new clscount = GetArraySize(ClientSettingsArray);
	ReplyToCommand(client, "[Confogl] Tracked Client CVars (Total %d)", clscount);
	for(new i = 0; i < clscount; i++)
	{
		static clsetting[CLSEntry];
		static String:message[256], String:shortbuf[64];
		GetArrayArray(ClientSettingsArray, i, clsetting[0]);
		Format(message, sizeof(message), "[Confogl] Client CVar: %s ", clsetting[CLSE_cvar]);
		if(clsetting[CLSE_hasMin])
		{
			Format(shortbuf, sizeof(shortbuf), "Min: %f ", clsetting[CLSE_min]);
			StrCat(message, sizeof(message), shortbuf);
		}
		if(clsetting[CLSE_hasMax])
		{
			Format(shortbuf, sizeof(shortbuf), "Max: %f ", clsetting[CLSE_max]);
			StrCat(message, sizeof(message), shortbuf);
		}
		switch(clsetting[CLSE_action])
		{
			case CLSA_Kick:
			{
				StrCat(message, sizeof(message), "Action: Kick");
			}
			case CLSA_Log:
			{
				StrCat(message, sizeof(message), "Action: Log");
			}
		}
		ReplyToCommand(client, message);
	}
	return Plugin_Handled;
}

public Action:_TrackClientCvar_Cmd(args)
{
	if(args < 3 || args == 4)
	{
		PrintToServer("Usage: confogl_trackclientcvar <cvar> <hasMin> <min> [<hasMax> <max> [<action>]]");
		if(IsDebugEnabled())
		{
			decl String:cmdbuf[128];
			GetCmdArgString(cmdbuf, sizeof(cmdbuf));
			LogError("[confogl] Invalid track client cvar: %s", cmdbuf);
		}
		return Plugin_Handled;
	}
	decl String:sBuffer[CLS_CVAR_MAXLEN], String:cvar[CLS_CVAR_MAXLEN];
	new bool:hasMin, bool:hasMax, Float:min, Float:max, CLSAction:action=CLSA_Kick;
	GetCmdArg(1, cvar, sizeof(cvar));
	if(!strlen(cvar))
	{
		PrintToServer("Unreadable cvar");
		if(IsDebugEnabled())
		{
			decl String:cmdbuf[128];
			GetCmdArgString(cmdbuf, sizeof(cmdbuf));
			LogError("[confogl] Invalid track client cvar: %s", cmdbuf);
		}
		return Plugin_Handled;
	}
	GetCmdArg(2, sBuffer, sizeof(sBuffer));
	hasMin = bool:StringToInt(sBuffer);
	GetCmdArg(3, sBuffer, sizeof(sBuffer));
	min = StringToFloat(sBuffer);
	if(args >= 5)
	{
		GetCmdArg(4, sBuffer, sizeof(sBuffer));
		hasMax = bool:StringToInt(sBuffer);
		GetCmdArg(5, sBuffer, sizeof(sBuffer));
		max = StringToFloat(sBuffer);
	}
	if(args >= 6)
	{
		GetCmdArg(6, sBuffer, sizeof(sBuffer));
		action = CLSAction:StringToInt(sBuffer);
	}
	
	_AddClientCvar(cvar, hasMin, min, hasMax, max, action);	
	
	return Plugin_Handled;
}

public Action:_ResetTracking_Cmd(args)
{
	if(ClientSettingsCheckTimer != INVALID_HANDLE)
	{
		PrintToServer("Can't reset tracking in the middle of a match");
		return Plugin_Handled;
	}
	ClearAllSettings();
	PrintToServer("Client CVar Tracking Information Reset!");
	return Plugin_Handled;
}

public Action:_StartClientChecking_Cmd(args)
{
	_StartTracking();
}

static _StartTracking()
{
	if(IsPluginEnabled() && ClientSettingsCheckTimer == INVALID_HANDLE)
	{
		if(IsDebugEnabled())
		{
			LogMessage("[Confogl] ClientSettings: Starting repeating check timer");
		}
		ClientSettingsCheckTimer = CreateTimer(CLIENT_CHECK_INTERVAL, _CheckClientSettings_Timer, _, TIMER_REPEAT);
	}
	else
	{
		PrintToServer("Can't start plugin tracking or tracking already started");
	}
}

static _AddClientCvar(const String:cvar[], bool:hasMin, Float:min, bool:hasMax, Float:max, CLSAction:action)
{
	if(ClientSettingsCheckTimer != INVALID_HANDLE)
	{
		PrintToServer("Can't track new cvars in the middle of a match");
		if(IsDebugEnabled())
		{
			LogMessage("[Confogl] ClientSettings: Attempt to track new cvar %s during a match!", cvar);
		}
		return;
	}
	if(!(hasMin || hasMax))
	{
		LogError("[Confogl] ClientSettings: Client CVar %s specified without max or min", cvar);
		return;
	}
	if(hasMin && hasMax && max < min)
	{
		LogError("[Confogl] ClientSettings: Client CVar %s specified max < min (%f < %f)", cvar, max, min);
		return;
	}
	if(strlen(cvar) >= CLS_CVAR_MAXLEN)
	{
		LogError("[Confogl] ClientSettings: CVar Specified (%s) is longer than max cvar length (%d)", cvar, CLS_CVAR_MAXLEN);
		return;
	}
	
	decl newEntry[CLSEntry];
	for(new i = 0; i < GetArraySize(ClientSettingsArray); i++)
	{
		GetArrayArray(ClientSettingsArray, i, newEntry[0]);
		if(StrEqual(newEntry[CLSE_cvar], cvar, false))
		{
			LogError("[Confogl] ClientSettings: Attempt to track CVar %s, which is already being tracked.", cvar);
			return;
		}
	}
		
	newEntry[CLSE_hasMin]=hasMin;
	newEntry[CLSE_min]=min;
	newEntry[CLSE_hasMax]=hasMax;
	newEntry[CLSE_max]=max;
	newEntry[CLSE_action]=action;
	strcopy(newEntry[CLSE_cvar], CLS_CVAR_MAXLEN, cvar);
	
	if(IsDebugEnabled())
	{
		LogMessage("[Confogl] ClientSettings: Tracking Cvar %s Min %d %f Max %d %f Action %d", cvar, hasMin, min, hasMax, max, action);
	}
	
	PushArrayArray(ClientSettingsArray, newEntry[0]);
}
