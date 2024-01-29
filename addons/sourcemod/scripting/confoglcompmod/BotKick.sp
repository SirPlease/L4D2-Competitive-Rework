#if defined __bot_kick_included
	#endinput
#endif
#define __bot_kick_included

#define BK_MODULE_NAME				"BotKick"

#define CHECKALLOWEDTIME			0.1
#define BOTREPLACEVALIDTIME			0.2

static const char InfectedNames[][] =
{
	"smoker",
	"boomer",
	"hunter",
	"spitter",
	"jockey",
	"charger"
};

static int
	BK_iEnable = 0,
	BK_lastvalidbot = -1;

static ConVar
	BK_hEnable = null;

void BK_OnModuleStart()
{
	BK_hEnable = CreateConVarEx( \
		"blockinfectedbots", \
		"1", \
		"Blocks infected bots from joining the game, minus when a tank spawns (1 allows bots from tank spawns, 2 removes all infected bots)", \
		_, true, 0.0, true, 2.0 \
	);

	BK_iEnable = BK_hEnable.IntValue;
	BK_hEnable.AddChangeHook(BK_ConVarChange);

	HookEvent("player_bot_replace", BK_PlayerBotReplace);
}

static void BK_ConVarChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	BK_iEnable = BK_hEnable.IntValue;
}

bool BK_OnClientConnect(int iClient)
{
	if (BK_iEnable == 0 || !IsPluginEnabled() || !IsFakeClient(iClient)) { // If the BK_iEnable is 0, we don't do anything
		return true;
	}

	// If the client doesn't have a bot infected's name, let it in
	if (IsInvalidInfected(iClient)) {
		return true;
	}

	if (BK_iEnable == 1 && GT_IsTankInPlay()) { // Bots only allowed to try to connect when there's a tank in play.
		// Check this bot in CHECKALLOWEDTIME seconds to see if he's supposed to be allowed.
		CreateTimer(CHECKALLOWEDTIME, BK_CheckInfBotReplace_Timer, iClient, TIMER_FLAG_NO_MAPCHANGE);
		//BK_bAllowBot = false;
		return true;
	}

	KickClient(iClient, "[Confogl] Kicking infected bot..."); // If all else fails, bots arent allowed and must be kicked

	return false;
}

static Action BK_CheckInfBotReplace_Timer(Handle hTimer, any iClient)
{
	if (iClient != BK_lastvalidbot && IsClientInGame(iClient) && IsFakeClient(iClient)) {
		KickClient(iClient, "[Confogl] Kicking late infected bot...");
	} else {
		BK_lastvalidbot = -1;
	}

	return Plugin_Stop;
}

static void BK_PlayerBotReplace(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!GT_IsTankInPlay()) {
		return;
	}

	int iClient = GetClientOfUserId(hEvent.GetInt("player"));

	if (iClient > 0 && IsClientInGame(iClient) && GetClientTeam(iClient) == L4D2Team_Infected) {
		BK_lastvalidbot = GetClientOfUserId(hEvent.GetInt("bot"));
		CreateTimer(BOTREPLACEVALIDTIME, BK_CancelValidBot_Timer, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

static Action BK_CancelValidBot_Timer(Handle hTimer)
{
	BK_lastvalidbot = -1;

	return Plugin_Stop;
}

static bool IsInvalidInfected(int iClient)
{
	char sBotName[11];
	GetClientName(iClient, sBotName, sizeof(sBotName));

	for (int i = 0; i < sizeof(InfectedNames); i++) {
		if (StrContains(sBotName, InfectedNames[i], false) != -1) {
			return false;
		}
	}

	return true;
}
