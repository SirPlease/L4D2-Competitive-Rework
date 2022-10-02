#if defined __confogl_debug_included
	#endinput
#endif
#define __confogl_debug_included

#if DEBUG_ALL
	#define DEBUG_DEFAULT "1"
#else
	#define DEBUG_DEFAULT "0"
#endif

static char
	g_sLogAction[256];

static bool
	g_bConfoglDebug = false;

static ConVar
	g_hCvarCustomErrorLog = null,
	g_hCvarDebugConVar = null;

void Debug_OnModuleStart()
{
	g_hCvarDebugConVar = CreateConVarEx("debug", DEBUG_DEFAULT, "Turn on Debug Logging in all Confogl Modules", _, true, 0.0, true, 1.0);

	//confogl_custom_error_logs
	g_hCvarCustomErrorLog = CreateConVarEx( \
		"custom_error_logs", \
		"1", \
		"Write logs to custom error log file (0 - use sourcemod error log file, 1 - use custom error log file)", \
		_, true, 0.0, true, 1.0 \
	);

	g_bConfoglDebug = g_hCvarDebugConVar.BoolValue;
	g_hCvarDebugConVar.AddChangeHook(Debug_ConVarChange);

	char sTime[64], sBuffer[64];
	FormatTime(sTime, sizeof(sTime), "%Y%m%d");
	FormatEx(sBuffer, sizeof(sBuffer), "logs/confoglcompmod/errors_%s.log", sTime); //errors_20211201.log
	BuildPath(Path_SM, g_sLogAction, sizeof(g_sLogAction), sBuffer);

	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "logs/confoglcompmod");
	if (!DirExists(sBuffer)) {
		CreateDirectory(sBuffer, 511);
	}
}

public void Debug_ConVarChange(ConVar hConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_bConfoglDebug = hConvar.BoolValue;
}

stock bool IsDebugEnabled()
{
	return (g_bConfoglDebug || DEBUG_ALL);
}

stock void Debug_LogError(const char[] sModuleName, const char[] sMessage, any ...)
{
	static char sFormat[512];
	VFormat(sFormat, sizeof(sFormat), sMessage, 3);

	static char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	Format(sFormat, sizeof(sFormat), "[%s] [%s] %s", sModuleName, sMap, sFormat);

	if (!g_hCvarCustomErrorLog.BoolValue) {
		// L 12/16/2021 - 12:10:15: [confoglcompmod.smx] [CvarSettings] [c4m1_milltown_a] Could not find CVar specified (l4d2_meleecontrol_enable)
		LogError(sFormat);
		return;
	}

	// Same as LogToFile(), except no plugin logtag is prepended.
	// L 12/16/2021 - 12:11:45: [CvarSettings] [c4m1_milltown_a] Could not find CVar specified (l4d2_meleecontrol_enable)
	LogToFileEx(g_sLogAction, sFormat);
}
