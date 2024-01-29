#if defined __finale_spawn_included
	#endinput
#endif
#define __finale_spawn_included

#define FS_MODULE_NAME			"FinaleSpawn"

#define SPAWN_RANGE				150

static ConVar
	FS_hEnabled = null;

static bool
	FS_bIsFinale = false,
	FS_bEnabled = true;

void FS_OnModuleStart()
{
	FS_hEnabled = CreateConVarEx("reduce_finalespawnrange", "1", "Adjust the spawn range on finales for infected, to normal spawning range", _, true, 0.0, true, 1.0);

	FS_bEnabled = FS_hEnabled.BoolValue;
	FS_hEnabled.AddChangeHook(FS_ConVarChange);

	HookEvent("round_end", FS_Round_Event, EventHookMode_PostNoCopy);
	HookEvent("round_start", FS_Round_Event, EventHookMode_PostNoCopy);
	HookEvent("finale_start", FS_FinaleStart_Event, EventHookMode_PostNoCopy);
}

static void FS_Round_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	FS_bIsFinale = false;
}

static void FS_FinaleStart_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	FS_bIsFinale = true;
}

static void FS_ConVarChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	FS_bEnabled = FS_hEnabled.BoolValue;
}

void FS_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThinkPost, HookCallback);
}

static void HookCallback(int client)
{
	if (!FS_bIsFinale) {
		return;
	}

	//if (!FS_bEnabled) { // rework version
	if (!FS_bEnabled || !IsPluginEnabled()) { // original
		return;
	}

	if (GetClientTeam(client) != L4D2Team_Infected) {
		return;
	}

	if (GetEntProp(client, Prop_Send, "m_isGhost", 1) != 1) {
		return;
	}

	if (GetEntProp(client, Prop_Send, "m_ghostSpawnState") == SPAWNFLAG_TOOCLOSE) {
		if (!TooClose(client)) {
			SetEntProp(client, Prop_Send, "m_ghostSpawnState", SPAWNFLAG_READY);
		}
	}
}

static bool TooClose(int client)
{
	int index = 0;
	float fInfLocation[3], fSurvLocation[3], fVector[3];
	GetClientAbsOrigin(client, fInfLocation);

	for (int i = 0; i < 4; i++) {
		index = GetSurvivorIndex(i);
		if (index == 0) {
			continue;
		}

		if (!IsPlayerAlive(index)) {
			continue;
		}

		GetClientAbsOrigin(index, fSurvLocation);
		MakeVectorFromPoints(fInfLocation, fSurvLocation, fVector);

		if (GetVectorLength(fVector) <= SPAWN_RANGE) {
			return true;
		}
	}

	return false;
}
