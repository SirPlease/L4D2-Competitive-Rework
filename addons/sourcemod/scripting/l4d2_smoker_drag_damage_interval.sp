/**
 * Version 2.2 by A1m`
 *
 * Changes:
 * 1. Removed duplicate plugins:
 *    - l4d2_smoker_drag_damage_interval_zone
 *    - l4d2_smoker_drag_damage_interval.
 *
 * 2. Removed untrusted timer-based code:
 *    - Replaced with safer, hook-based implementation using OnTakeDamage and netprops.
 *    - Ensures more stable and reliable drag damage behavior without unnecessary timers.
 *
 * 3. Supports late loading.
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

int
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
	version = "2.2",
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

	int iTongueDragDamageTimer = GameConfGetOffset(hGamedata, "CTerrorPlayer::m_tongueDragDamageTimer");
	if (iTongueDragDamageTimer == -1) {
		SetFailState("Failed to get offset 'CTerrorPlayer::m_tongueDragDamageTimer'.");
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

#if DEBUG
	g_fDebugDamageInterval = GetGameTime();
#endif
}

Action Hook_OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType)
{
	// Replacing the function patch 'CTerrorPlayer::UpdateHangingFromTongue'.
	if (!(iDamageType & DMG_CHOKE)) {
		return Plugin_Continue;
	}

	int iTongueOwner = GetEntPropEnt(iVictim, Prop_Send, "m_tongueOwner");
	if (iTongueOwner < 1 || iTongueOwner > MaxClients || iTongueOwner != iAttacker) {
		return Plugin_Continue;
	}

	// Stop dragging.
	bool bIsHangingFromTongue = (GetEntProp(iVictim, Prop_Send, "m_isHangingFromTongue", 1) > 0);
	if (bIsHangingFromTongue) {
		return Plugin_Continue;
	}

	// Fix damage interval.
	SetDragDamageTimer(iVictim, g_hTongueDragDamageInterval.FloatValue);

	// First damage if cvar enabled.
	bool bFirstDamage = false;
	float fTongueDragFirstDamage = g_hTongueDragFirstDamage.FloatValue;

	if (fTongueDragFirstDamage > 0.0) {
		float fTongueVictimTimer = GetEntPropFloat(iVictim, Prop_Send, "m_tongueVictimTimer", IT_TIMESTAMP_INDEX);

		if (FloatCompareEps(fTongueVictimTimer, GetFirstDamageInterval()) == 0) {
			fDamage = fTongueDragFirstDamage;
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

// For small differences in tick interval.
int FloatCompareEps(float fOne, float fTwo, float fEps = EPSILON)
{
	if (FloatAbs(fOne - fTwo) < fEps) {
		return 0;
	} else if (fOne > fTwo) {
		return 1;
	}

	return -1;
}

#if DEBUG
void DebugPrint(int iVictim, float fDamage, bool bFirstDamage)
{
	PrintToChatAll("[DEBUG] Victim: %N, %sdamage: %f, time: %f, game time: %f", \
						iVictim, (bFirstDamage) ? "first " : "", fDamage, GetGameTime() - g_fDebugDamageInterval, GetGameTime());

	g_fDebugDamageInterval = GetGameTime();
}
#endif
