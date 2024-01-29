#if defined __unprohibit_bosses_included
	#endinput
#endif
#define __unprohibit_bosses_included

#define UB_MODULE_NAME			"UnprohibitBosses"

static bool
	UB_bEnabled = true;

static ConVar
	UB_hEnable = null;

void UB_OnModuleStart()
{
	UB_hEnable = CreateConVarEx("boss_unprohibit", "1", "Enable bosses spawning on all maps, even through they normally aren't allowed", _, true, 0.0, true, 1.0);

	UB_bEnabled = UB_hEnable.BoolValue; //turns on when changing cvar only
	UB_hEnable.AddChangeHook(UB_ConVarChange);
}

static void UB_ConVarChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	UB_bEnabled = UB_hEnable.BoolValue;
}

Action UB_OnGetScriptValueInt(const char[] key, int &retVal)
{
	if (IsPluginEnabled() && UB_bEnabled) {
		if (strcmp(key, "DisallowThreatType") == 0) {
			retVal = 0;
			return Plugin_Handled;
		}

		if (strcmp(key, "ProhibitBosses") == 0) {
			retVal = 0;
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

Action UB_OnGetMissionVSBossSpawning()
{
	//if (IsPluginEnabled() && UB_bEnabled) {
	if (UB_bEnabled) {
		char mapbuf[32];
		GetCurrentMap(mapbuf, sizeof(mapbuf));
		if (strcmp(mapbuf, "c7m1_docks") == 0 || strcmp(mapbuf, "c13m2_southpinestream") == 0) {
			return Plugin_Continue;
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}
