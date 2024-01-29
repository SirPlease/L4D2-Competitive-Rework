#if defined __confogl_survivor_index_included
	#endinput
#endif
#define __confogl_survivor_index_included

#define SI_MODULE_NAME				"SurvivorIndex"

static int
	iSurvivorIndex[NUM_OF_SURVIVORS] = {0, ...};

void SI_OnModuleStart()
{
	HookEvent("round_start", SI_BuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", SI_BuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", SI_BuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", SI_BuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_death", SI_BuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", SI_BuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("bot_player_replace", SI_BuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("defibrillator_used", SI_BuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_team", SI_BuildIndexDelay_Event, EventHookMode_PostNoCopy);
}

static void SI_BuildIndex()
{
	if (!IsServerProcessing() || !IsPluginEnabled()) {
		return;
	}

	int ifoundsurvivors = 0, character = 0;

	// Make sure kicked survivors don't freak us out.
	for (int i = 0; i < NUM_OF_SURVIVORS; i++) {
		iSurvivorIndex[i] = 0;
	}

	for (int client = 1; client <= MaxClients; client++) {
		if (ifoundsurvivors == NUM_OF_SURVIVORS) {
			break;
		}

		if (!IsClientInGame(client) || GetClientTeam(client) != L4D2Team_Survivor) {
			continue;
		}

		character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		ifoundsurvivors++;

		if (character > 3 || character < 0) {
			continue;
		}

		iSurvivorIndex[character] = 0;

		if (!IsPlayerAlive(client)) {
			continue;
		}

		iSurvivorIndex[character] = client;
	}
}

static void SI_BuildIndexDelay_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	CreateTimer(0.3, SI_BuildIndex_Timer, _, TIMER_FLAG_NO_MAPCHANGE);
}

static Action SI_BuildIndex_Timer(Handle hTimer)
{
	SI_BuildIndex();

	return Plugin_Stop;
}

static void SI_BuildIndex_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	SI_BuildIndex();
}

stock int GetSurvivorIndex(int index)
{
	if (index < 0 || index > 3) {
		return 0;
	}

	return iSurvivorIndex[index];
}

stock bool IsAnySurvivorsAlive()
{
	for (int index = 0; index < NUM_OF_SURVIVORS; index++) {
		if (iSurvivorIndex[index]) {
			return true;
		}
	}

	return false;
}
