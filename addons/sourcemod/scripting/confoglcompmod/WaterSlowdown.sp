#if defined __water_slowdown_included
	#endinput
#endif
#define __water_slowdown_included

#define WS_MODULE_NAME			"WaterSlowdown"

static float
	WS_fSlowdownFactor = 0.90;

static bool
	WS_bEnabled = true,
	WS_bJockeyInWater = false,
	WS_bPlayerInWater[MAXPLAYERS + 1] = {false, ...};

static ConVar
	WS_hEnable = null,
	WS_hFactor = null;

void WS_OnModuleStart()
{
	WS_hEnable = CreateConVarEx("waterslowdown", "1", "Enables additional water slowdown", _, true, 0.0, true, 1.0);
	WS_hFactor = CreateConVarEx("slowdown_factor", "0.90", "Sets how much water will slow down survivors. 1.00 = Vanilla");

	WS_SetStatus();
	WS_fSlowdownFactor = WS_hFactor.FloatValue;

	WS_hEnable.AddChangeHook(WS_ConVarChange);
	WS_hFactor.AddChangeHook(WS_FactorConVarChange);

	HookEvent("round_start", WS_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("jockey_ride", WS_JockeyRide);
	HookEvent("jockey_ride_end", WS_JockeyRideEnd);
}

static void WS_FactorConVarChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	WS_fSlowdownFactor = WS_hFactor.FloatValue;
}

static void WS_ConVarChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	WS_SetStatus();
}

void WS_OnMapEnd()
{
	WS_SetStatus(false);
}

void WS_OnModuleEnd()
{
	WS_SetStatus(false);
}

void WS_OnGameFrame()
{
	if (!IsServerProcessing() || !IsPluginEnabled() || !WS_bEnabled) {
		return;
	}

	int client, flags;

	for (int i = 0; i < NUM_OF_SURVIVORS; i++) {
		client = GetSurvivorIndex(i);

		if (client != 0 && IsValidEntity(client)) {
			flags = GetEntityFlags(client);

			if (!(flags & IN_JUMP && WS_bPlayerInWater[client])) {
				if (flags & FL_INWATER) {
					if (!WS_bPlayerInWater[client]) {
						WS_bPlayerInWater[client] = true;
						SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", WS_fSlowdownFactor);
					}
				} else {
					if (WS_bPlayerInWater[client]) {
						WS_bPlayerInWater[client] = false;
						SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
					}
				}
			}
		}
	}
}

static void WS_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	WS_SetStatus();
}

static void WS_JockeyRide(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int victim = GetClientOfUserId(hEvent.GetInt("victim"));
	int jockey = GetClientOfUserId(hEvent.GetInt("userid"));

	if (WS_bPlayerInWater[victim] && !WS_bJockeyInWater) {
		WS_bJockeyInWater = true;
		SetEntPropFloat(jockey, Prop_Send, "m_flLaggedMovementValue", WS_fSlowdownFactor);
	} else if (!WS_bPlayerInWater[victim] && WS_bJockeyInWater) {
		WS_bJockeyInWater = false;
		SetEntPropFloat(jockey, Prop_Send, "m_flLaggedMovementValue", 1.0);
	}
}

static void WS_JockeyRideEnd(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int jockey = GetClientOfUserId(hEvent.GetInt("userid"));

	WS_bJockeyInWater = false;

	if (jockey > 0 && IsValidEntity(jockey)) {
		SetEntPropFloat(jockey, Prop_Send, "m_flLaggedMovementValue", 1.0);
	}
}

static void WS_SetStatus(bool bEnable = true)
{
	if (!bEnable) {
		WS_bEnabled = false;
		return;
	}

	WS_bEnabled = WS_hEnable.BoolValue;
}
