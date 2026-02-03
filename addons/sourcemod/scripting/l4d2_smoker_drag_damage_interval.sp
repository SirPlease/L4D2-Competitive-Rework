/**
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

#define DEBUG					0
#define GAMEDATA				"l4d2_si_ability"

// DMG_CHOKE = 1048576 = 0x100000 = (1 << 20)
#define DMG_CHOKE				(1 << 20)

#define IT_TIMESTAMP_INDEX		0
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
	g_iTongueDragDamageTimerTimeStampOffset = -1;

ConVar
	g_hTongueDragDamageInterval = null,
	g_hTongueDragFirstDamageInterval = null,
	g_hTongueDragFirstDamage = null;

public Plugin myinfo =
{
	name = "L4D2 smoker drag damage interval",
	author = "Visor, Sir, A1m`",
	description = "Implements a native-like cvar that should've been there out of the box",
	version = "2.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();

	HookEvent("tongue_grab", Event_OnTongueGrab);

	// Get the default value of cvar 'tongue_choke_damage_interval'
	char sCvarVal[32];
	ConVar hTongueChokeDamageInterval = FindConVar("tongue_choke_damage_interval");
	hTongueChokeDamageInterval.GetDefault(sCvarVal, sizeof(sCvarVal));

	g_hTongueDragDamageInterval = CreateConVar("tongue_drag_damage_interval", sCvarVal, "How often the drag does damage. Allowed values: 0.01 - 15.0.", _, true, 0.01, true, 15.0);
	g_hTongueDragFirstDamageInterval = CreateConVar("tongue_drag_first_damage_interval", "-1.0", "After how many seconds do we apply our first tick of damage? 0.0 - disable, max value - 15.0.", _, false, 0.0, true, 15.0);
	g_hTongueDragFirstDamage = CreateConVar("tongue_drag_first_damage", "-1.0", "How much damage do we apply on the first tongue hit? 0.0 - disable", _, false, 0.0, true, 100.0);

	LateLoad();
}

void InitGameData()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);

	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}

	int iTongueDragDamageTimer = GameConfGetOffset(hGamedata, "CTerrorPlayer->m_tongueDragDamageTimer");
	if (iTongueDragDamageTimer == -1) {
		SetFailState("Failed to get offset 'CTerrorPlayer->m_tongueDragDamageTimer'.");
	}

	g_iTongueDragDamageTimerDurationOffset = iTongueDragDamageTimer + CT_DURATION_OFFSET;
	g_iTongueDragDamageTimerTimeStampOffset = iTongueDragDamageTimer + CT_TIMESTAMP_OFFSET;

	delete hGamedata;
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
