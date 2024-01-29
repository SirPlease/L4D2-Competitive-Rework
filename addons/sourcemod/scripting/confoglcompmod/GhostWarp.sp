#if defined __ghost_warp_included
	#endinput
#endif
#define __ghost_warp_included

#define GW_MODULE_NAME			"GhostWarp"

static int
	GW_iLastTarget[MAXPLAYERS + 1] = {-1, ...};

static bool
	GW_bEnabled = true,
	GW_bReload = false,
	GW_bDelay[MAXPLAYERS + 1] = {false, ...};

static ConVar
	GW_hGhostWarp = null,
	GW_hGhostWarpReload = null;

void GW_OnModuleStart()
{
	// GhostWarp
	GW_hGhostWarp = CreateConVarEx("ghost_warp", "1", "Sets whether infected ghosts can right click for warp to next survivor", _, true, 0.0, true, 1.0);
	GW_hGhostWarpReload = CreateConVarEx("ghost_warp_reload", "0", "Sets whether to use mouse2 or reload for ghost warp.", _, true, 0.0, true, 1.0);

	// Ghost Warp
	GW_bEnabled = GW_hGhostWarp.BoolValue;
	GW_bReload = GW_hGhostWarpReload.BoolValue;

	GW_hGhostWarp.AddChangeHook(GW_ConVarsChanged);
	GW_hGhostWarpReload.AddChangeHook(GW_ConVarsChanged);

	RegConsoleCmd("sm_warptosurvivor", GW_Cmd_WarpToSurvivor);

	HookEvent("player_death", GW_PlayerDeath_Event);
	HookEvent("round_start", GW_RoundStart);
}

static void GW_ConVarsChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	GW_bEnabled = GW_hGhostWarp.BoolValue;
	GW_bReload = GW_hGhostWarpReload.BoolValue;
}

bool GW_OnPlayerRunCmd(int iClient, int iButtons)
{
	if (!IsPluginEnabled() || !GW_bEnabled || GW_bDelay[iClient]) {
		return false;
	}

	if (/*!IsClientInGame(iClient) || */GetClientTeam(iClient) != L4D2Team_Infected || GetEntProp(iClient, Prop_Send, "m_isGhost", 1) != 1) {
		return false;
	}

	if (GW_bReload && !(iButtons & IN_RELOAD)) {
		return false;
	}

	if (!GW_bReload && !(iButtons & IN_ATTACK2)) {
		return false;
	}

	GW_bDelay[iClient] = true;
	CreateTimer(0.25, GW_ResetDelay, iClient, TIMER_FLAG_NO_MAPCHANGE);
	GW_WarpToSurvivor(iClient, 0);

	return true;
}

static void GW_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) {
		GW_bDelay[i] = false;
		GW_iLastTarget[i] = -1;
	}
}

static void GW_PlayerDeath_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	GW_iLastTarget[iClient] = -1;
}

static Action GW_ResetDelay(Handle hTimer, any iClient)
{
	GW_bDelay[iClient] = false;

	return Plugin_Stop;
}

static Action GW_Cmd_WarpToSurvivor(int iClient, int iArgs)
{
	if (iClient < 1 || iArgs != 1) {
		return Plugin_Handled;
	}

	if (!IsPluginEnabled() || !GW_bEnabled) {
		return Plugin_Handled;
	}

	if (GetClientTeam(iClient) != L4D2Team_Infected || GetEntProp(iClient, Prop_Send, "m_isGhost", 1) != 1) {
		return Plugin_Handled;
	}

	char sBuffer[2];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));
	if (strlen(sBuffer) == 0) {
		return Plugin_Handled;
	}

	int iCharacter = StringToInt(sBuffer);
	GW_WarpToSurvivor(iClient, iCharacter);

	return Plugin_Handled;
}

static void GW_WarpToSurvivor(int iClient, int iCharacter)
{
	int iTarget = 0;

	if (iCharacter <= 0) {
		iTarget = GW_FindNextSurvivor(iClient, GW_iLastTarget[iClient]);
	} else if (iCharacter <= 4) {
		iTarget = GetSurvivorIndex(iCharacter - 1);
	} else {
		return;
	}

	if (iTarget == 0) {
		return;
	}

	// Prevent people from spawning and then warp to survivor
	SetEntProp(iClient, Prop_Send, "m_ghostSpawnState", SPAWNFLAG_TOOCLOSE);

	float fPosition[3], fAnglestarget[3];
	GetClientAbsOrigin(iTarget, fPosition);
	GetClientAbsAngles(iTarget, fAnglestarget);

	TeleportEntity(iClient, fPosition, fAnglestarget, NULL_VECTOR);
}

static int GW_FindNextSurvivor(int iClient, int iCharacter)
{
	if (!IsAnySurvivorsAlive()) {
		return 0;
	}

	bool bHavelooped = false;
	iCharacter++;

	if (iCharacter >= NUM_OF_SURVIVORS) {
		iCharacter = 0;
	}

	for (int i = iCharacter; i <= MaxClients; i++) {
		if (i >= NUM_OF_SURVIVORS) {
			if (bHavelooped) {
				break;
			}

			bHavelooped = true;
			i = 0;
		}

		if (GetSurvivorIndex(i) == 0) {
			continue;
		}

		GW_iLastTarget[iClient] = i;
		return GetSurvivorIndex(i);
	}

	return 0;
}
