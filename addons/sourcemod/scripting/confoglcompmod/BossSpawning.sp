#if defined __boss_spawning_included
	#endinput
#endif
#define __boss_spawning_included

#define DEBUG_BS			false
#define BS_MODULE_NAME		"BossSpawning"

#define MAX_TANKS			5
#define MAX_WITCHES			5
#define ROUND_MAX_COUNT		2

static char
	BS_sMap[64] = "\0";

static bool
	BS_bDebugEnabled = DEBUG_BS,
	BS_bEnabled = true,
	BS_bIsFirstRound = true,
	BS_bDeleteWitches = false,
	BS_bFinaleStarted = false;

static int
	BS_iTankCount[ROUND_MAX_COUNT] = {0, ...},
	BS_iWitchCount[ROUND_MAX_COUNT] = {0, ...};

static float
	BS_fTankSpawn[MAX_TANKS][3],
	BS_fWitchSpawn[MAX_WITCHES][2][3];

static ConVar
	BS_hEnabled = null;

void BS_OnModuleStart()
{
	BS_hEnabled = CreateConVarEx("lock_boss_spawns", "1", "Enables forcing same coordinates for tank and witch spawns", _, true, 0.0, true, 1.0);

	BS_bEnabled = BS_hEnabled.BoolValue;
	BS_hEnabled.AddChangeHook(BS_ConVarChange);

	HookEvent("witch_spawn", BS_WitchSpawn);
	HookEvent("round_end", BS_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("finale_start", BS_FinaleStart, EventHookMode_PostNoCopy);

	GetCurrentMap(BS_sMap, sizeof(BS_sMap));
}

void BS_OnMapStart()
{
	BS_bIsFirstRound = true;
	BS_bFinaleStarted = false;

	for (int i = 0; i < ROUND_MAX_COUNT; i++) {
		BS_iTankCount[i] = 0;
		BS_iWitchCount[i] = 0;
	}

	GetCurrentMap(BS_sMap, sizeof(BS_sMap));
}

static void BS_ConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	BS_bEnabled = BS_hEnabled.BoolValue;
}

static void BS_WitchSpawn(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!BS_bEnabled || !IsPluginEnabled()) {
		return;
	}

	int iWitch = hEvent.GetInt("witchid");

	if (BS_bDeleteWitches) {
		// Used to delete round2 extra witches, which spawn on round start instead of by flow
		KillEntity(iWitch);

		return;
	}

	// Can't track more witches if our witch array is full
	if (BS_iWitchCount[view_as<int>(!BS_bIsFirstRound)] >= MAX_WITCHES) {
		Debug_LogError(BS_MODULE_NAME, "Failed to save a large number of witches to the array. Count: %d, Max: %d", \
											BS_iWitchCount[view_as<int>(!BS_bIsFirstRound)], MAX_WITCHES);
		return;
	}

	if (BS_bIsFirstRound) {
		// If it's the first round, track our witch.
		GetEntPropVector(iWitch, Prop_Send, "m_vecOrigin", BS_fWitchSpawn[BS_iWitchCount[0]][0]);
		GetEntPropVector(iWitch, Prop_Send, "m_angRotation", BS_fWitchSpawn[BS_iWitchCount[0]][1]);
		BS_iWitchCount[0]++;
	} else if (BS_iWitchCount[0] > BS_iWitchCount[1]) {
		// Until we have found the same number of witches as from round1, teleport them to round1 locations
		TeleportEntity(iWitch, BS_fWitchSpawn[BS_iWitchCount[1]][0], BS_fWitchSpawn[BS_iWitchCount[1]][1], NULL_VECTOR);
		BS_iWitchCount[1]++;
	}
}

void BS_OnTankSpawnPost_Forward(int iTankClient)
{
	if (!BS_bEnabled || !IsPluginEnabled()) {
		return;
	}

	// Don't touch tanks on finale events
	if (BS_bFinaleStarted) {
		return;
	}

	// Don't track tank spawns on c5m5 or tank can spawn behind other team.
	if (strcmp(BS_sMap, "c5m5_bridge") == 0) {
		return;
	}

	if (GetMapValueInt("tank_z_fix")) {
		FixZDistance(iTankClient); // fix stuck tank spawns, ex c1m1
	}

	// If we reach MAX_TANKS, we don't have any room to store their locations
	if (BS_iTankCount[view_as<int>(!BS_bIsFirstRound)] >= MAX_TANKS) {
		Debug_LogError(BS_MODULE_NAME, "Failed to save a large number of tanks to the array. Count: %d, Max: %d", \
											BS_iTankCount[view_as<int>(!BS_bIsFirstRound)], MAX_TANKS);
		return;
	}

	if (BS_bDebugEnabled || IsDebugEnabled()) {
		LogMessage("[%s] Tracking this tank spawn. Currently, %d tanks", BS_MODULE_NAME, BS_iTankCount[view_as<int>(!BS_bIsFirstRound)]);
	}

	if (BS_bIsFirstRound) {
		GetClientAbsOrigin(iTankClient, BS_fTankSpawn[BS_iTankCount[0]]);
		if (BS_bDebugEnabled || IsDebugEnabled()) {
			LogMessage("[%s] Saving tank at %f %f %f", \
							BS_MODULE_NAME, BS_fTankSpawn[BS_iTankCount[0]][0], BS_fTankSpawn[BS_iTankCount[0]][1], BS_fTankSpawn[BS_iTankCount[0]][2]);
		}

		BS_iTankCount[0]++;
	} else if (BS_iTankCount[0] > BS_iTankCount[1]) {
		TeleportEntity(iTankClient, BS_fTankSpawn[BS_iTankCount[1]], NULL_VECTOR, NULL_VECTOR);

		if (BS_bDebugEnabled || IsDebugEnabled()) {
			LogMessage("[%s] Teleporting tank to tank at %f %f %f", \
							BS_MODULE_NAME, BS_fTankSpawn[BS_iTankCount[1]][0], BS_fTankSpawn[BS_iTankCount[1]][1], BS_fTankSpawn[BS_iTankCount[1]][2]);
		}

		BS_iTankCount[1]++;
	} else if (BS_bDebugEnabled || IsDebugEnabled()) {
		LogMessage("[%s] Not first round and not acceptable tank", BS_MODULE_NAME);
		LogMessage("[%s] IsFirstRound: %d  R1Count: %d R2Count: %d", BS_MODULE_NAME, BS_bIsFirstRound, BS_iTankCount[0], BS_iTankCount[1]);
	}
}

static void BS_RoundEnd(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	BS_bIsFirstRound = false;
	BS_bFinaleStarted = false;

	if (strcmp(BS_sMap, "c6m1_riverbank") == 0) {
		BS_bDeleteWitches = false;
	} else {
		BS_bDeleteWitches = true;

		CreateTimer(5.0, BS_WitchTimerReset);
	}
}

static void BS_FinaleStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	BS_bFinaleStarted = true;
}

static Action BS_WitchTimerReset(Handle hTimer)
{
	BS_bDeleteWitches = false;

	return Plugin_Stop;
}

static void FixZDistance(int iTankClient)
{
	int index = 0;
	float distance = 99999999999999.9;
	float WarpToLocation[3], TankLocation[3], TempSurvivorLocation[3];
	GetClientAbsOrigin(iTankClient, TankLocation);

	if (BS_bDebugEnabled || IsDebugEnabled()) {
		LogMessage("[%s] tank z spawn check... Map: %s, Tank Location: %f, %f, %f", BS_MODULE_NAME, BS_sMap, TankLocation[0], TankLocation[1], TankLocation[2]);
	}

	for (int i = 0; i < NUM_OF_SURVIVORS; i++) {
		distance = GetMapValueFloat("max_tank_z", 99999999999999.9);
		index = GetSurvivorIndex(i);

		if (index != 0 && IsValidEntity(index)) {
			GetClientAbsOrigin(index, TempSurvivorLocation);

			if (BS_bDebugEnabled || IsDebugEnabled()) {
				LogMessage("[%s] Survivor %d Location: %f, %f, %f", BS_MODULE_NAME, i, TempSurvivorLocation[0], TempSurvivorLocation[1], TempSurvivorLocation[2]);
			}

			if (FloatAbs(TempSurvivorLocation[2] - TankLocation[2]) > distance) {
				GetMapValueVector("tank_warpto", WarpToLocation);

				if (!GetVectorLength(WarpToLocation, true)) {
					LogMessage("[%s] tank_warpto missing from mapinfo.txt", BS_MODULE_NAME);
					return;
				}

				TeleportEntity(iTankClient, WarpToLocation, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}
