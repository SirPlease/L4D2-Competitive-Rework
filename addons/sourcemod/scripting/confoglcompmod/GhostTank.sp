#if defined __ghost_tank_included
	#endinput
#endif
#define __ghost_tank_included

#define GT_MODULE_NAME				"GhostTank"

#define THROWRANGE					99999999.0
#define FIREIMMUNITY_TIME			5.0

static int
	g_iPasses = 0,
	g_iGT_TankClient = 0;

static bool
	g_bGT_FinaleVehicleIncoming = false,
	g_bGT_TankIsInPlay = false,
	g_bGT_TankHasFireImmunity = false,
	g_bGT_HordesDisabled = false;

static Handle
	g_hGT_TankDeathTimer = null;

static ConVar
	g_hGT_Enabled = null,
	g_hCvarTankThrowAllowRange = null,
	g_hCvarDirectorTankLotterySelectionTime = null,
	g_hCvarZMobSpawnMinIntervalNormal = null,
	g_hCvarZMobSpawnMaxIntervalNormal = null,
	g_hCvarMobSpawnMinSize = null,
	g_hCvarMobSpawnMaxSize = null,
	g_hGT_RemoveEscapeTank = null,
	g_hGT_BlockPunchRock = null,
	g_hGT_DisableTankHordes = null; // Disable Tank Hordes items

void GT_OnModuleStart()
{
	g_hGT_Enabled = CreateConVarEx( \
		"boss_tank", \
		"1", \
		"Tank can't be prelight, frozen and ghost until player takes over, punch fix, and no rock throw for AI tank while waiting for player", \
		_, true, 0.0, true, 1.0 \
	);

	g_hGT_RemoveEscapeTank = CreateConVarEx("remove_escape_tank", "1", "Remove tanks that spawn as the rescue vehicle is incoming on finales.", _, true, 0.0, true, 1.0);
	g_hGT_DisableTankHordes = CreateConVarEx("disable_tank_hordes", "0", "Disable natural hordes while tanks are in play", _, true, 0.0, true, 1.0);
	g_hGT_BlockPunchRock = CreateConVarEx("block_punch_rock", "0", "Block tanks from punching and throwing a rock at the same time", _, true, 0.0, true, 1.0);

	g_hCvarTankThrowAllowRange = FindConVar("tank_throw_allow_range");
	g_hCvarDirectorTankLotterySelectionTime = FindConVar("director_tank_lottery_selection_time");
	g_hCvarZMobSpawnMinIntervalNormal = FindConVar("z_mob_spawn_min_interval_normal");
	g_hCvarZMobSpawnMaxIntervalNormal = FindConVar("z_mob_spawn_max_interval_normal");
	g_hCvarMobSpawnMinSize = FindConVar("z_mob_spawn_min_size");
	g_hCvarMobSpawnMaxSize = FindConVar("z_mob_spawn_max_size");

	HookEvent("round_start", GT_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", GT_TankSpawn);
	HookEvent("player_death", GT_TankKilled);
	HookEvent("player_hurt", GT_TankOnFire);
	HookEvent("item_pickup", GT_ItemPickup);
	HookEvent("finale_vehicle_incoming", GT_FinaleVehicleIncoming, EventHookMode_PostNoCopy);
	HookEvent("finale_vehicle_ready", GT_FinaleVehicleIncoming, EventHookMode_PostNoCopy);
}

Action GT_OnTankSpawn_Forward()
{
	if (IsPluginEnabled() && g_hGT_RemoveEscapeTank.BoolValue && g_bGT_FinaleVehicleIncoming) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

Action GT_OnCThrowActivate()
{
	if (IsPluginEnabled()
		&& g_bGT_TankIsInPlay
		&& g_hGT_BlockPunchRock.BoolValue
		&& GetClientButtons(g_iGT_TankClient) & IN_ATTACK
	) {
		if (IsDebugEnabled()) {
			LogMessage("[%s] Blocking Haymaker on %L", GT_MODULE_NAME, g_iGT_TankClient);
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

Action GT_OnSpawnMob_Forward(int &amount)
{
	// quick fix. needs normalize_hordes 1
	if (IsPluginEnabled()) {
		if (IsDebugEnabled()) {
			LogMessage("[%s] SpawnMob(%d), HordesDisabled: %d TimerDuration: %f Minimum: %f Remaining: %f", \
							GT_MODULE_NAME, amount, g_bGT_HordesDisabled, L4D2_CTimerGetCountdownDuration(L4D2CT_MobSpawnTimer), \
								g_hCvarZMobSpawnMinIntervalNormal.FloatValue, L4D2_CTimerGetRemainingTime(L4D2CT_MobSpawnTimer));
		}

		if (g_bGT_HordesDisabled) {
			if (amount < g_hCvarMobSpawnMinSize.IntValue || amount > g_hCvarMobSpawnMaxSize.IntValue) {
				return Plugin_Continue;
			}

			if (!L4D2_CTimerIsElapsed(L4D2CT_MobSpawnTimer)) {
				return Plugin_Continue;
			}

			float duration = L4D2_CTimerGetCountdownDuration(L4D2CT_MobSpawnTimer);
			if (duration < g_hCvarZMobSpawnMinIntervalNormal.FloatValue || duration > g_hCvarZMobSpawnMaxIntervalNormal.FloatValue) {
				return Plugin_Continue;
			}

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

// Disable stasis when we're using GhostTank
Action GT_OnTryOfferingTankBot(bool &enterStasis)
{
	g_iPasses++;

	if (IsPluginEnabled()) {
		if (g_hGT_Enabled.BoolValue) {
			enterStasis = false;
		}

		if (g_hGT_RemoveEscapeTank.BoolValue && g_bGT_FinaleVehicleIncoming) {
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

static void GT_FinaleVehicleIncoming(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	g_bGT_FinaleVehicleIncoming = true;

	if (g_bGT_TankIsInPlay && IsFakeClient(g_iGT_TankClient)) {
		KickClient(g_iGT_TankClient);
		GT_Reset();
	}
}

static void GT_ItemPickup(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!g_bGT_TankIsInPlay) {
		return;
	}

	char item[MAX_ENTITY_NAME_LENGTH];
	hEvent.GetString("item", item, sizeof(item));

	if (strcmp(item, "tank_claw") != 0) {
		return;
	}

	g_iGT_TankClient = GetClientOfUserId(hEvent.GetInt("userid"));

	if (g_hGT_TankDeathTimer != null) {
		KillTimer(g_hGT_TankDeathTimer);
		g_hGT_TankDeathTimer = null;
	}
}

static void GT_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	g_bGT_FinaleVehicleIncoming = false;
	GT_Reset();
}

static void GT_TankKilled(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!g_bGT_TankIsInPlay) {
		return;
	}

	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (client != g_iGT_TankClient) {
		return;
	}

	g_hGT_TankDeathTimer = CreateTimer(1.0, GT_TankKilled_Timer);
}

static void GT_TankSpawn(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	g_iGT_TankClient = client;

	if (g_bGT_TankIsInPlay) {
		return;
	}

	g_bGT_TankIsInPlay = true;

	if (g_hGT_DisableTankHordes.BoolValue) {
		g_bGT_HordesDisabled = true;
	}

	if (!IsPluginEnabled() || !g_hGT_Enabled.BoolValue) {
		return;
	}

	float fFireImmunityTime = FIREIMMUNITY_TIME;
	float fSelectionTime = g_hCvarDirectorTankLotterySelectionTime.FloatValue;

	if (IsFakeClient(client)) {
		GT_PauseTank();
		CreateTimer(fSelectionTime, GT_ResumeTankTimer);
		fFireImmunityTime += fSelectionTime;
	}

	CreateTimer(fFireImmunityTime, GT_FireImmunityTimer);
}

static void GT_TankOnFire(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int dmgtype = hEvent.GetInt("type");

	if (!(dmgtype & DMG_BURN)) { //more performance
		return;
	}

	if (!g_bGT_TankIsInPlay || !g_bGT_TankHasFireImmunity || !IsPluginEnabled() || !g_hGT_Enabled.BoolValue) {
		return;
	}

	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (client < 1 || g_iGT_TankClient != client || !IsClientInGame(client) || GetClientTeam(client) != L4D2Team_Infected) {
		return;
	}

	ExtinguishEntity(client);

	int iSetHealth = GetClientHealth(client) + hEvent.GetInt("dmg_health");
	SetEntityHealth(client, iSetHealth);
}

static Action GT_ResumeTankTimer(Handle hTimer)
{
	GT_ResumeTank();

	return Plugin_Stop;
}

static Action GT_FireImmunityTimer(Handle hTimer)
{
	g_bGT_TankHasFireImmunity = false;

	return Plugin_Stop;
}

static void GT_PauseTank()
{
	g_hCvarTankThrowAllowRange.SetFloat(THROWRANGE);

	if (!IsValidEntity(g_iGT_TankClient)) {
		return;
	}

	SetEntityMoveType(g_iGT_TankClient, MOVETYPE_NONE);
	SetEntProp(g_iGT_TankClient, Prop_Send, "m_isGhost", 1, 1);
}

static void GT_ResumeTank()
{
	g_hCvarTankThrowAllowRange.RestoreDefault();

	if (!IsValidEntity(g_iGT_TankClient)) {
		return;
	}

	SetEntityMoveType(g_iGT_TankClient, MOVETYPE_CUSTOM);
	SetEntProp(g_iGT_TankClient, Prop_Send, "m_isGhost", 0, 1);
}

static void GT_Reset()
{
	g_iPasses = 0;
	g_hGT_TankDeathTimer = null;

	if (g_bGT_HordesDisabled) {
		g_bGT_HordesDisabled = false;
	}

	g_bGT_TankIsInPlay = false;
	g_bGT_TankHasFireImmunity = true;
}

static Action GT_TankKilled_Timer(Handle hTimer)
{
	GT_Reset();

	return Plugin_Stop;
}

// For other modules to use
stock bool GT_IsTankInPlay()
{
	return (g_bGT_TankIsInPlay);
}
