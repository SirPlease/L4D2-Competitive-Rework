/**
 * Version 2.4
 *
 * Additions:
 * - Added ConVar `tongue_damage_continuity` (Default 0: OFF)
 *
 * 	When enabled the internal damage timer carries over between dragging a survivor & choking a survivor.
 *  In Vanilla the timer gets reset to its full duration when transitioning between states.
 *
 * Gamedata:
 * - We now use our own gamedata as we need some additional info.
 *
 * Version 2.3 by A1m`
 *
 * Changes:
 * 1. Removed duplicate plugins:
 *    - l4d2_smoker_drag_damage_interval_zone
 *    - l4d2_smoker_drag_damage_interval.
 *
 * 2. Removed untrusted timer-based code:
 *    - Replaced with safer, hook-based implementation using OnTakeDamage.
 *    - Ensures more stable and reliable drag damage behavior without unnecessary timers.
 *
 * Notes:
 *    The timing of damage is not perfect, as 'CTerrorPlayer::PostThink' is not called every frame,
 *    but after a certain period of time depending on the number of players and the tick rate (see function 'CTerrorPlayer::ShouldPostThink').
 *    For this reason, it is difficult to calculate using game netprops whether this was the first damage dealt or not,
 *    the code becomes too complicated, so we introduce our own variables to determine this.
**/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <dhooks>

#define DEBUG					0
#define GAMEDATA				"l4d2_smoker_drag_damage_interval"

// DMG_CHOKE = 1048576 = 0x100000 = (1 << 20)
#define DMG_CHOKE				(1 << 20)

#define CT_DURATION_OFFSET		4
#define CT_TIMESTAMP_OFFSET		8

#define TEAM_SURVIVOR			2
#define TEAM_INFECTED			3

#define EPSILON					0.001

#if DEBUG
float
	g_fDebugDamageInterval = 0.0;
#endif

enum
{
	eUserId = 0,
	eHitCount,

	eDamageInfo_Size
};

int
	g_iTongueHitCount[MAXPLAYERS + 1][eDamageInfo_Size],
	g_iTongueDragDamageTimerDurationOffset = -1,
	g_iTongueDragDamageTimerTimeStampOffset = -1,
	g_iTongueChokeDamageTimerTimeStampOffset = -1,
	g_iTongueReleaseTick[MAXPLAYERS + 1];

float
	g_fDragTimestampSnapshot[MAXPLAYERS + 1];

bool
	g_bSnapshotValid[MAXPLAYERS + 1];

ConVar
	g_hTongueDragDamageInterval = null,
	g_hTongueDragFirstDamageInterval = null,
	g_hTongueDragFirstDamage = null,
	g_hTongueDamageContinuity = null;

DynamicDetour
	g_hOnStartHangingFromTongue = null;

public Plugin myinfo =
{
	name = "L4D2 smoker drag damage interval",
	author = "Visor, Sir, A1m`",
	description = "Implements a native-like cvar and functionality that should've been there out of the box",
	version = "2.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();

	HookEvent("tongue_grab", Event_OnTongueGrab);
	HookEvent("tongue_release", Event_OnTongueRelease);
	HookEvent("choke_end", Event_OnChokeEnd);

	// Get the default value of cvar 'tongue_choke_damage_interval'
	char sCvarVal[32];
	ConVar hTongueChokeDamageInterval = FindConVar("tongue_choke_damage_interval");
	hTongueChokeDamageInterval.GetDefault(sCvarVal, sizeof(sCvarVal));

	g_hTongueDragDamageInterval = CreateConVar("tongue_drag_damage_interval", sCvarVal, "How often the drag does damage. Allowed values: 0.01 - 15.0.", _, true, 0.01, true, 15.0);
	g_hTongueDragFirstDamageInterval = CreateConVar("tongue_drag_first_damage_interval", "-1.0", "After how many seconds do we apply our first tick of damage? 0.0 - disable, max value - 15.0.", _, false, 0.0, true, 15.0);
	g_hTongueDragFirstDamage = CreateConVar("tongue_drag_first_damage", "-1.0", "How much damage do we apply on the first tongue hit? 0.0 - disable", _, false, 0.0, true, 100.0);
	g_hTongueDamageContinuity = CreateConVar("tongue_damage_continuity", "0", "Preserve damage timer between drag <-> choke transitions. 0 = Vanilla behavior, 1 = carry over remaining time of the choke/drag to the next timer", _, true, 0.0, true, 1.0);

	LateLoad();
}

void InitGameData()
{
	GameData gd = new GameData(GAMEDATA);
	if (!gd) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}

	int iTongueDragDamageTimer = gd.GetOffset("CTerrorPlayer->m_tongueDragDamageTimer");
	if (iTongueDragDamageTimer == -1) {
		SetFailState("Failed to get offset 'CTerrorPlayer->m_tongueDragDamageTimer'.");
	}
	g_iTongueDragDamageTimerDurationOffset = iTongueDragDamageTimer + CT_DURATION_OFFSET;
	g_iTongueDragDamageTimerTimeStampOffset = iTongueDragDamageTimer + CT_TIMESTAMP_OFFSET;

	int iTongueChokeDamageTimer = gd.GetOffset("CTerrorPlayer->m_tongueChokeDamageTimer");
	if (iTongueChokeDamageTimer == -1) {
		SetFailState("Failed to get offset 'CTerrorPlayer->m_tongueChokeDamageTimer'.");
	}
	g_iTongueChokeDamageTimerTimeStampOffset = iTongueChokeDamageTimer + CT_TIMESTAMP_OFFSET;

	g_hOnStartHangingFromTongue = DynamicDetour.FromConf(gd, "CTerrorPlayer::OnStartHangingFromTongue");
	if (!g_hOnStartHangingFromTongue) {
		SetFailState("Failed to set up detour for 'CTerrorPlayer::OnStartHangingFromTongue'.");
	}
	if (!g_hOnStartHangingFromTongue.Enable(Hook_Pre, Detour_OnStartHangingFromTongue_Pre)) {
		SetFailState("Failed to enable Pre detour on 'CTerrorPlayer::OnStartHangingFromTongue'.");
	}
	if (!g_hOnStartHangingFromTongue.Enable(Hook_Post, Detour_OnStartHangingFromTongue_Post)) {
		SetFailState("Failed to enable Post detour on 'CTerrorPlayer::OnStartHangingFromTongue'.");
	}

	delete gd;
}

void LateLoad()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) {
			continue;
		}

		OnClientPutInServer(i);
	}
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	g_fDragTimestampSnapshot[iClient] = -1.0;
	g_bSnapshotValid[iClient] = false;
	g_iTongueReleaseTick[iClient] = -1;
}

public void OnClientDisconnect(int iClient)
{
	g_fDragTimestampSnapshot[iClient] = -1.0;
	g_bSnapshotValid[iClient] = false;
	g_iTongueReleaseTick[iClient] = -1;
}

void Event_OnTongueGrab(Event hEvent, const char[] eName, bool bDontBroadcast)
{
	// Replacing variable value 'CTerrorPlayer::m_tongueDragDamageTimer',
	// ​​after calling a function 'CTerrorPlayer::OnGrabbedByTongue'.
	// Fix damage interval.

	int iVictim = GetClientOfUserId(hEvent.GetInt("victim"));
	bool bIsHangingFromTongue = (GetEntProp(iVictim, Prop_Send, "m_isHangingFromTongue", 1) > 0);

	if (!bIsHangingFromTongue) { // Dragging?
		SetDragDamageTimer(iVictim, GetFirstDamageInterval());
	}

	g_iTongueHitCount[iVictim][eUserId] = hEvent.GetInt("victim");
	g_iTongueHitCount[iVictim][eHitCount] = 0;

#if DEBUG
	g_fDebugDamageInterval = GetGameTime();
#endif
}

Action Hook_OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType)
{
	// Replacing the function patch 'CTerrorPlayer::UpdateHangingFromTongue'.
	// This dmg function is called after variable 'CTerrorPlayer::m_tongueDragDamageTimer' is set, we can't get it here.
	if (!(iDamageType & DMG_CHOKE)) {
		return Plugin_Continue;
	}

	int iTongueOwner = GetEntPropEnt(iVictim, Prop_Send, "m_tongueOwner");
	if (iTongueOwner < 1 || iTongueOwner > MaxClients || iTongueOwner != iAttacker) {
		return Plugin_Continue;
	}

	// Stop dragging.
	if (GetEntProp(iVictim, Prop_Send, "m_isHangingFromTongue", 1) > 0) {
		return Plugin_Continue;
	}

	// Fix damage interval.
	SetDragDamageTimer(iVictim, g_hTongueDragDamageInterval.FloatValue);

	// First damage if cvar enabled.
	g_iTongueHitCount[iVictim][eHitCount]++;
	bool bFirstDamage = false;

	if (g_hTongueDragFirstDamage.FloatValue > 0.0) {
		if (g_iTongueHitCount[iVictim][eHitCount] == 1 && g_iTongueHitCount[iVictim][eUserId] == GetClientUserId(iVictim)) {
			fDamage = g_hTongueDragFirstDamage.FloatValue;
			bFirstDamage = true;
		}
	}

#if DEBUG
	DebugPrint(iVictim, fDamage, bFirstDamage);
#endif

	return (bFirstDamage) ? Plugin_Changed : Plugin_Continue;
}

MRESReturn Detour_OnStartHangingFromTongue_Pre(int client, DHookParam hParams)
{
	if (client < 1 || client > MaxClients) {
		return MRES_Ignored;
	}

	// Set it to false here as it's called non-stop during the pull, easy reset.
	g_bSnapshotValid[client] = false;

	if (GetEntProp(client, Prop_Send, "m_isHangingFromTongue", 1) > 0) {
		return MRES_Ignored;
	}

	// We only land here when the client is about to officially StartHangingFromTongue.
	g_fDragTimestampSnapshot[client] = GetEntDataFloat(client, g_iTongueDragDamageTimerTimeStampOffset);
	g_bSnapshotValid[client] = true;
	return MRES_Ignored;
}

MRESReturn Detour_OnStartHangingFromTongue_Post(int client, DHookParam hParams)
{
	if (client < 1 || client > MaxClients) {
		return MRES_Ignored;
	}

	// Store current & reset
	bool bValid = g_bSnapshotValid[client];
	float fSnapshot = g_fDragTimestampSnapshot[client];
	g_bSnapshotValid[client] = false;
	g_fDragTimestampSnapshot[client] = -1.0;

	// Player is already hanging
	if (!bValid) {
		return MRES_Ignored;
	}

	if (!g_hTongueDamageContinuity.BoolValue) {
		return MRES_Ignored;
	}

	// Shouldn't happen, but just in case. (Lets Vanilla behavior continue)
	if (fSnapshot < 0.0) {
		return MRES_Ignored;
	}

	float fNow = GetGameTime();
	float fRemaining = fSnapshot - fNow;
	if (fRemaining < 0.0) {
		fRemaining = 0.0;
	}

	/*
		Game just set its choke_timer.m_timestamp to now + tongue_choke_damage_interval
		Replace with now + remaining_drag_time so the damage timer continues instead of restarting.
		We leave m_duration alone because UpdateHangingFromTongue restamps it to the cvar on the first choke tick.
	*/
#if DEBUG
	float fEngineChokeTs = GetEntDataFloat(client, g_iTongueChokeDamageTimerTimeStampOffset);
	float fEngineWouldFireIn = fEngineChokeTs - fNow;
	PrintToChatAll("[tongue_continuity] %N drag->choke: damage clock CONTINUED - next damage in %.2fs (vanilla would have reset to %.2fs)", \
		client, fRemaining, fEngineWouldFireIn);
#endif

	SetEntDataFloat(client, g_iTongueChokeDamageTimerTimeStampOffset, fNow + fRemaining, false);

	return MRES_Ignored;
}

void Event_OnTongueRelease(Event hEvent, const char[] eName, bool bDontBroadcast)
{
	// Store the exact tick on which a player got released from a tongue.
	int iVictim = GetClientOfUserId(hEvent.GetInt("victim"));
	if (iVictim < 1 || iVictim > MaxClients) {
		return;
	}

	g_iTongueReleaseTick[iVictim] = GetGameTickCount();
}

void Event_OnChokeEnd(Event hEvent, const char[] eName, bool bDontBroadcast)
{
	if (!g_hTongueDamageContinuity.BoolValue) {
		return;
	}

	int iVictim = GetClientOfUserId(hEvent.GetInt("victim"));
	if (iVictim < 1 || iVictim > MaxClients) {
		return;
	}

	// If tongue_release fired on the exact same tick, then it's guaranteed to be a survivor clear rather than transition.
	if (g_iTongueReleaseTick[iVictim] == GetGameTickCount()) {
		return;
	}

	float fChokeTs = GetEntDataFloat(iVictim, g_iTongueChokeDamageTimerTimeStampOffset);
	float fNow = GetGameTime();
	float fRemaining = fChokeTs - fNow;
	if (fRemaining < 0.0) {
		fRemaining = 0.0;
	}

	SetEntDataFloat(iVictim, g_iTongueDragDamageTimerTimeStampOffset, fNow + fRemaining, false);

#if DEBUG
	PrintToChatAll("[tongue_continuity] %N choke->drag: damage clock CONTINUED - next damage in %.2fs (vanilla would have fired immediately)", \
		iVictim, fRemaining);
#endif
}

float GetFirstDamageInterval()
{
	float fTongueFirstDamageInterval = g_hTongueDragFirstDamageInterval.FloatValue;
	if (fTongueFirstDamageInterval > 0.0) {
		return fTongueFirstDamageInterval;
	}

	return g_hTongueDragDamageInterval.FloatValue;
}

void SetDragDamageTimer(int iClient, float fDuration)
{
	// 'CTerrorPlayer::m_tongueDragDamageTimer', this is not netprop
	float fTimeStamp = GetGameTime() + fDuration;

	SetEntDataFloat(iClient, g_iTongueDragDamageTimerDurationOffset, fDuration, false); // 'CountdownTimer::duration'
	SetEntDataFloat(iClient, g_iTongueDragDamageTimerTimeStampOffset, fTimeStamp, false); // 'CountdownTimer::timestamp'
}

#if DEBUG
void DebugPrint(int iVictim, float fDamage, bool bFirstDamage)
{
	PrintToChatAll("[DEBUG] Victim: %N, %sdamage: %f, time: %f, game time: %f", \
						iVictim, (bFirstDamage) ? "first " : "", fDamage, GetGameTime() - g_fDebugDamageInterval, GetGameTime());

	g_fDebugDamageInterval = GetGameTime();
}
#endif
