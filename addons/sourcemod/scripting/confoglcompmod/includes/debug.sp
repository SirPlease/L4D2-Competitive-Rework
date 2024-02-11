#if defined __confogl_debug_included
	#endinput
#endif
#define __confogl_debug_included

static char
	g_sLogAction[256];

static ConVar
	g_hCvarCustomErrorLog = null,
	g_hCvarDebugConVar = null;

void Debug_OnModuleStart()
{
	g_hCvarDebugConVar = CreateConVarEx("debug", "0", "Turn on debug logging in all confogl modules", _, true, 0.0, true, 1.0);
	//confogl_custom_error_logs
	g_hCvarCustomErrorLog = CreateConVarEx( \
		"custom_error_logs", \
		"1", \
		"Write logs to custom error log file (0 - use sourcemod error log file, 1 - use custom error log file)", \
		_, true, 0.0, true, 1.0 \
	);

#if DEBUG_ALL
	g_hCvarDebugConVar.BoolValue = true;
#endif

	char sTime[64], sBuffer[64];
	FormatTime(sTime, sizeof(sTime), "%Y%m%d");
	FormatEx(sBuffer, sizeof(sBuffer), "logs/confoglcompmod/errors_%s.log", sTime); //errors_20211201.log
	BuildPath(Path_SM, g_sLogAction, sizeof(g_sLogAction), sBuffer);

	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "logs/confoglcompmod");
	if (!DirExists(sBuffer)) {
		CreateDirectory(sBuffer, 511);
	}
}

stock bool IsDebugEnabled()
{
	return (g_hCvarDebugConVar.BoolValue);
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
