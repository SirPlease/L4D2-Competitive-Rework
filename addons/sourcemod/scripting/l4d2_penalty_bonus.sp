/*
	Changelog
	=========
		0.1.1
			- added PBONUS_RequestFinalUpdate() forward.
			- replaced netprop round tracking with bool. (odd behaviour fix?)

		0.0.1 - 0.0.9
			- added library registration ('penaltybonus')
			- simplified round-end: L4D2_OnEndVersusRound instead of a bunch of hooked events.
			- added native to change defib penalty (since it can vary in Random!)
			- where possible, neatly divides total bonus through bonuses/penalties,
			  to improve end-of-round overview. Only works for single-value bonus/penalty
			  setups.
			- fixed double minus signs appearing on reports for negative changes.
			- fixed incorrect reporting on round end (twice the 2nd team's score).
			- added enable cvar.
			- avoided messing with bonus unless it's really necessary.
			- fixed for config-set custom defib penalty values.
			- optional report of changes to bonus as they happen.
			- removed sm_bonus command effects when display mode is off.
			- fixed report error.
			- added sm_bonus command to display bonus.
			- optional simple tank/witch kill bonus (off by default).
			- optional bonus reporting on round end.
			- allows setting bonus through natives.
			- bonus calculation, taking defib use into account.
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util> //IsTank

//L4D2_OnEndVersusModeRound
#include <left4dhooks> //#include <left4downtown>

#define DEBUG_MODE 0

Handle
	g_hForwardRequestUpdate = null; // request final update before round ends

ConVar
	g_hCvarEnabled = null,
	g_hCvarDoDisplay = null,
	g_hCvarReportChange = null,
	g_hCvarBonusTank = null,
	g_hCvarBonusWitch = null,
	g_hCvarDefibPenalty = null;

bool
	g_bSecondHalf = false,
	g_bFirstMapStartDone = false,		// so we can set the config-set defib penalty
	g_bRoundOver[2] = {false, false},	// tank/witch deaths don't count after this true
	g_bSetSameChange = true;			// whether we've already determined that there is a same-change or not (true = it's still 'the same' if not 0)

int
	g_iOriginalPenalty = 25,			// original defib penalty
	g_iSameChange = 0,					// if all changes to the bonus are by the same amount, this is it (-1 = not set)
	g_iDefibsUsed[2] = {0, 0},			// defibs used this round
	g_iBonus[2] = {0, 0};				// bonus to be added when this round ends

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int sErrMax)
{
	// this forward requests all plugins to return their final modifications
	//  the cell parameter will be updated for each plugin responding to this forward
	//  so the last return value is the total of the final update modifications
	g_hForwardRequestUpdate = CreateGlobalForward("PBONUS_RequestFinalUpdate", ET_Single, Param_CellByRef);

	CreateNative("PBONUS_GetRoundBonus", Native_GetRoundBonus);
	CreateNative("PBONUS_ResetRoundBonus", Native_ResetRoundBonus);
	CreateNative("PBONUS_SetRoundBonus", Native_SetRoundBonus);
	CreateNative("PBONUS_AddRoundBonus", Native_AddRoundBonus);
	CreateNative("PBONUS_GetDefibsUsed", Native_GetDefibsUsed);
	CreateNative("PBONUS_SetDefibPenalty", Native_SetDefibPenalty);

	RegPluginLibrary("penaltybonus");
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "Penalty bonus system",
	author = "Tabun, A1m`",
	description = "Allows other plugins to set bonuses for a round that will be given even if the saferoom is not reached.",
	version = "2.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

// Init and round handling
// -----------------------
public void OnPluginStart()
{
	// store original penalty
	g_hCvarDefibPenalty = FindConVar("vs_defib_penalty");

	// cvars
	g_hCvarEnabled = CreateConVar("sm_pbonus_enable", "1", "Whether the penalty-bonus system is enabled.", _, true, 0.0, true, 1.0);
	g_hCvarDoDisplay = CreateConVar("sm_pbonus_display", "1", "Whether to display bonus at round-end and with !bonus.", _, true, 0.0, true, 1.0);
	g_hCvarReportChange = CreateConVar("sm_pbonus_reportchanges", "1", "Whether to report changes when they are made to the current bonus.", _, true, 0.0, true, 1.0);
	g_hCvarBonusTank = CreateConVar("sm_pbonus_tank", "0", "Give this much bonus when a tank is killed (0 to disable entirely).", _, true, 0.0);
	g_hCvarBonusWitch = CreateConVar("sm_pbonus_witch", "0", "Give this much bonus when a witch is killed (0 to disable entirely).", _, true, 0.0);

	// hook events
	HookEvent("defibrillator_used", Event_DefibUsed, EventHookMode_PostNoCopy);
	HookEvent("witch_killed", Event_WitchKilled, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);

	// Chat cleaning (bequit already doing it)
	/*AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");*/

	RegConsoleCmd("sm_bonus", Cmd_Bonus, "Prints the current extra bonus(es) for this round.");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public void OnPluginEnd()
{
	g_hCvarDefibPenalty.SetInt(g_iOriginalPenalty);
}

public void OnMapStart()
{
	// save original defib penalty setting
	if (!g_bFirstMapStartDone) {
		g_iOriginalPenalty = g_hCvarDefibPenalty.IntValue;
		g_bFirstMapStartDone = true;
	}

	g_hCvarDefibPenalty.SetInt(g_iOriginalPenalty);

	g_bSecondHalf = false;

	for (int i = 0; i < 2; i++) {
		g_bRoundOver[i] = false;
		g_iDefibsUsed[i] = 0;
	}
}

public void OnMapEnd()
{
	g_bSecondHalf = false;
}

public void Event_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	// reset
	g_hCvarDefibPenalty.SetInt(g_iOriginalPenalty);

	g_iBonus[RoundNum()] = 0;
	g_iSameChange = -1;
}

public void Event_RoundEnd(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	// Fix double event call
	float fRoundEndTime = GameRules_GetPropFloat("m_flRoundEndTime");
	if (fRoundEndTime != GetGameTime()) {
		return;
	}

	g_bRoundOver[RoundNum()] = true;
	g_bSecondHalf = true;

	if (g_hCvarEnabled.BoolValue && g_hCvarDoDisplay.BoolValue) {
		DisplayBonus();
	}
}

public Action Cmd_Bonus(int iClient, int iArgs)
{
	if (!g_hCvarEnabled.BoolValue || !g_hCvarDoDisplay.BoolValue) {
		return Plugin_Continue;
	}

	DisplayBonus(iClient);
	return Plugin_Handled;
}

/*public Action Command_Say(int iClient, const char[] sCommand, int iArgs)
{
	if (!g_hCvarEnabled.BoolValue || !g_hCvarDoDisplay.BoolValue) {
		return Plugin_Continue;
	}

	if (IsChatTrigger()) {
		char sMessage[MAX_NAME_LENGTH];
		GetCmdArg(1, sMessage, sizeof(sMessage));

		if (strcmp(sMessage, "!bonus") == 0 || strcmp(sMessage, "!sm_bonus") == 0) {
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}*/

// Tank and Witch tracking
// -----------------------
public void Event_PlayerDeath(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!g_hCvarEnabled.BoolValue) {
		return;
	}

	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	if (iClient && IsTank(iClient)) {
		TankKilled();
	}
}

void TankKilled()
{
	int iTankBonus = g_hCvarBonusTank.IntValue;

	if (iTankBonus == 0 || g_bRoundOver[RoundNum()]) {
		return;
	}

	g_iBonus[RoundNum()] += iTankBonus;

	if (g_bSetSameChange) {
		g_iSameChange = iTankBonus;
	} else if (g_iSameChange != iTankBonus) {
		g_iSameChange = 0;
		g_bSetSameChange = false;
	}

	ReportChange(iTankBonus);
}

public void Event_WitchKilled(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!g_hCvarEnabled.BoolValue) {
		return;
	}

	int iWitchBonus = g_hCvarBonusWitch.IntValue;
	if (iWitchBonus == 0 || g_bRoundOver[RoundNum()]) {
		return;
	}

	g_iBonus[RoundNum()] += iWitchBonus;

	if (g_bSetSameChange) {
		g_iSameChange = iWitchBonus;
	} else if (g_iSameChange != iWitchBonus) {
		g_iSameChange = 0;
		g_bSetSameChange = false;
	}

	ReportChange(iWitchBonus);
}

// Special Check (test)
// --------------------
public Action L4D2_OnEndVersusModeRound(bool bCountSurvivors)
{
	int iUpdateScore = 0, iUpdateResult = 0;

	// get update before setting the bonus
	Call_StartForward(g_hForwardRequestUpdate);
	Call_PushCellRef(iUpdateScore);
	Call_Finish(iUpdateResult);

	// add the update to the round's bonus
	g_iBonus[RoundNum()] += iUpdateResult;
	g_iSameChange = 0;
	g_bSetSameChange = false;

	SetBonus();

	return Plugin_Continue;
}

// Bonus
// -----
void SetBonus()
{
	// only change anything if there's a bonus to set at all
	if (g_iBonus[RoundNum()] == 0) {
		g_hCvarDefibPenalty.SetInt(g_iOriginalPenalty );
		return;
	}

	// set the bonus as though only 1 defib was used: so 1 * CalculateBonus
	int iBonus = CalculateBonus();

	// set the bonus to a neatly divisible value if possible
	int iFakeDefibs = 1;
	if (g_bSetSameChange && g_iSameChange != 0 && !g_iDefibsUsed[RoundNum()]) {
		iFakeDefibs = g_iBonus[RoundNum()] / g_iSameChange;
		iBonus = 0 - g_iSameChange;  // flip sign, so bonus = - penalty

		// only do it this way if fakedefibs stays small enough:
		if (iFakeDefibs > 15) {
			iFakeDefibs = 1;
			iBonus = 0 - g_iBonus[RoundNum()];
		}
	}

	// set bonus(penalty) cvar
	g_hCvarDefibPenalty.SetInt(iBonus);

	// only set the amount of defibs used to 1 if there is a bonus to set
	GameRules_SetProp("m_iVersusDefibsUsed", (iBonus != 0) ? iFakeDefibs : 0, 4, GameRules_GetProp("m_bAreTeamsFlipped", 4, 0));
}

int CalculateBonus()
{
	// negative = actual bonus, otherwise it is a penalty
	return (g_iOriginalPenalty * g_iDefibsUsed[RoundNum()]) - g_iBonus[RoundNum()];
}

void DisplayBonus(int iClient = -1)
{
	char sMsgPartHdr[48], sMsgPartBon[48];

	int iRoundNum = RoundNum();

	for (int iRound = 0; iRound <= iRoundNum; iRound++) {
		if (g_bRoundOver[iRound]) {
			Format(sMsgPartHdr, sizeof(sMsgPartHdr), "Round \x05%i\x01 extra bonus", iRound + 1);
		} else {
			Format(sMsgPartHdr, sizeof(sMsgPartHdr), "Current extra bonus");
		}

		Format(sMsgPartBon, sizeof(sMsgPartBon), "\x04%4d\x01", g_iBonus[iRound]);

		if (g_iDefibsUsed[iRound]) {
			Format(sMsgPartBon, sizeof(sMsgPartBon), "%s (- \x04%d\x01 defib penalty)", sMsgPartBon, g_iOriginalPenalty * g_iDefibsUsed[iRound]);
		}

		if (iClient == -1) {
			PrintToChatAll("\x01%s: %s", sMsgPartHdr, sMsgPartBon);
		} else if (iClient) {
			PrintToChat(iClient, "\x01%s: %s", sMsgPartHdr, sMsgPartBon);
		}
	}
}

void ReportChange(int iBonusChange, int iClient = -1, bool bAbsoluteSet = false)
{
	if (iBonusChange == 0 && !bAbsoluteSet) {
		return;
	}

	// report bonus to all
	char sMsgPartBon[48];
	if (bAbsoluteSet) { // set to a specific value
		Format(sMsgPartBon, sizeof(sMsgPartBon), "Extra bonus set to: \x04%i\x01", g_iBonus[RoundNum()]);
	} else {
		Format(sMsgPartBon, sizeof(sMsgPartBon), "Extra bonus change: %s\x04%i\x01", (iBonusChange > 0) ? "\x04+\x01" : "\x03-\x01", RoundFloat(FloatAbs(float(iBonusChange))));
	}

	if (iClient == -1) {
		PrintToChatAll("\x01%s", sMsgPartBon);
	} else if (iClient) {
		PrintToChat(iClient, "\x01%s", sMsgPartBon);
	}
}

// Defib tracking
// --------------
public void Event_DefibUsed(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	g_iDefibsUsed[RoundNum()]++;
}

// Support functions
// -----------------
int RoundNum()
{
	return (g_bSecondHalf) ? 1 : 0;
	//return GameRules_GetProp("m_bInSecondHalfOfRound");
}

/*
public PrintDebug(const char[] Message, any ...)
{
#if DEBUG_MODE
	char DebugBuff[256];
	VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
	LogMessage(DebugBuff);
	//PrintToServer(DebugBuff);
	//PrintToChatAll(DebugBuff);
#endif
}
*/

// Natives
// -------
public int Native_GetRoundBonus(Handle hPlugin, int iNumParams)
{
	return g_iBonus[RoundNum()];
}

public int Native_ResetRoundBonus(Handle hPlugin, int iNumParams)
{
	g_iBonus[RoundNum()] = 0;

	g_iSameChange = 0;
	g_bSetSameChange = true;

	return 1;
}

public int Native_SetRoundBonus(Handle hPlugin, int iNumParams)
{
	int iBonus = GetNativeCell(1);

	if (g_bSetSameChange) {
		g_iSameChange = g_iBonus[RoundNum()] - iBonus;
	} else if (g_iSameChange != g_iBonus[RoundNum()] - iBonus) {
		g_iSameChange = 0;
		g_bSetSameChange = false;
	}

	g_iBonus[RoundNum()] = iBonus;

	if (g_hCvarReportChange.BoolValue) {
		ReportChange(0, -1, true);
	}

	return 1;
}

public int Native_AddRoundBonus(Handle hPlugin, int iNumParams)
{
	bool bNoReport = false;
	int iBonus = GetNativeCell(1);

	g_iBonus[RoundNum()] += iBonus;

	if (g_bSetSameChange) {
		g_iSameChange = iBonus;
	} else if (g_iSameChange != iBonus) {
		g_iSameChange = 0;
		g_bSetSameChange = false;
	}

	if (iNumParams > 1) {
		bNoReport = view_as<bool>(GetNativeCell(2));
	}

	if (!bNoReport) {
		if (g_hCvarReportChange.BoolValue) {
			ReportChange(iBonus);
		}
	}

	return 1;
}

public int Native_GetDefibsUsed(Handle hPlugin, int iNumParams)
{
	return g_iDefibsUsed[RoundNum()];
}

public int Native_SetDefibPenalty(Handle hPlugin, int iNumParams)
{
	int iPenalty = GetNativeCell(1);

	g_iOriginalPenalty = iPenalty;

	return 1;
}
