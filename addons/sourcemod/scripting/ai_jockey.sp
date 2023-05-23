#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

ConVar
	g_hJockeyLeapRange,
	g_hJockeyLeapAgain,
	g_hJockeyStumbleRadius,
	g_hHopActivationProximity;

float
	g_fJockeyLeapRange,
	g_fJockeyLeapAgain,
	g_fJockeyStumbleRadius,
	g_fHopActivationProximity,
	g_fLeapAgainTime[MAXPLAYERS + 1];
	
bool
	g_bDoNormalJump[MAXPLAYERS + 1];

public Plugin myinfo = {
	name = "AI JOCKEY",
	author = "Breezy",
	description = "Improves the AI behaviour of special infected",
	version = "1.0",
	url = "github.com/breezyplease"
};

public void OnPluginStart() {
	g_hJockeyStumbleRadius =	CreateConVar("ai_jockey_stumble_radius",	"50.0",		"Stumble radius of a client landing a ride");
	g_hHopActivationProximity =	CreateConVar("ai_hop_activation_proximity",	"800.0",	"How close a client will approach before it starts hopping");
	g_hJockeyLeapRange =		FindConVar("z_jockey_leap_range");
	g_hJockeyLeapAgain =		FindConVar("z_jockey_leap_again_timer");

	g_hJockeyLeapRange.AddChangeHook(CvarChanged);
	g_hJockeyLeapAgain.AddChangeHook(CvarChanged);
	g_hJockeyStumbleRadius.AddChangeHook(CvarChanged);
	g_hHopActivationProximity.AddChangeHook(CvarChanged);

	HookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("player_spawn",	Event_PlayerSpawn);
	HookEvent("jockey_ride",	Event_JockeyRide,	EventHookMode_Pre);
}

public void OnConfigsExecuted() {
	GetCvars();
}

void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	GetCvars();
}

void GetCvars() {
	g_fJockeyLeapRange =		g_hJockeyLeapRange.FloatValue;
	g_fJockeyLeapAgain =		g_hJockeyLeapAgain.FloatValue;
	g_fJockeyStumbleRadius =	g_hJockeyStumbleRadius.FloatValue;
	g_fHopActivationProximity =	g_hHopActivationProximity.FloatValue;
}

public void OnMapEnd() {
	for (int i = 1; i <= MaxClients; i++)
		g_fLeapAgainTime[i] = 0.0;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	for (int i = 1; i <= MaxClients; i++)
		g_fLeapAgainTime[i] = 0.0;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	g_fLeapAgainTime[GetClientOfUserId(event.GetInt("userid"))] = 0.0;
}

void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast) {	
	if (g_fJockeyStumbleRadius <= 0.0 || !L4D2_IsGenericCooperativeMode())
		return;

	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!victim || !IsClientInGame(victim))
		return;

	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!attacker || !IsClientInGame(attacker))
		return;

	StumbleByStanders(victim, attacker);
}

void StumbleByStanders(int target, int pinner) {
	float vecPos[3];
	float vecTarget[3];
	GetClientAbsOrigin(target, vecPos);
	for (int i = 1; i <= MaxClients; i++) {
		if (i == target || i == pinner || !IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i) || IsPinned(i))
			continue;

		GetClientAbsOrigin(i, vecTarget);
		if (GetVectorDistance(vecPos, vecTarget) <= g_fJockeyStumbleRadius)
			L4D_StaggerPlayer(i, i, vecPos);
	}
}

bool IsPinned(int client) {
	if (GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0)
		return true;
	return false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3]) {
	
	if (!IsClientInGame(client) || !IsFakeClient(client) || GetClientTeam(client) != 3 || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_zombieClass") != 5 || GetEntProp(client, Prop_Send, "m_isGhost") || !GetEntProp(client, Prop_Send, "m_hasVisibleThreats"))
		return Plugin_Continue;

	if (L4D_IsPlayerStaggering(client))
		return Plugin_Continue;

	static float distance;
	distance = NearestSurDistance(client);
	if (distance > g_fHopActivationProximity)
		return Plugin_Continue;

	if (!IsGrounded(client)) {
		buttons &= ~IN_JUMP;
		buttons &= ~IN_ATTACK;
	}

	if (g_bDoNormalJump[client]) {
		g_bDoNormalJump[client] = false;
		if (buttons & IN_FORWARD && WithinViewAngle(client, 60.0)) {
			switch (Math_GetRandomInt(0, 1)) {
				case 0:
					buttons |= IN_MOVELEFT;
	
				case 1:
					buttons |= IN_MOVERIGHT;
			}
		}

		buttons |= IN_JUMP;

		switch (Math_GetRandomInt(0, 2)) {
			case 0:
				buttons |= IN_DUCK;
	
			case 1:
				buttons |= IN_ATTACK2;
		}
	}
	else {
		static float time;
		time = GetGameTime();
		if (g_fLeapAgainTime[client] < time) {
			if (distance < g_fJockeyLeapRange )
				buttons |= IN_ATTACK;

			g_bDoNormalJump[client] = true;
			g_fLeapAgainTime[client] = time + g_fJockeyLeapAgain;
		}
	}

	return Plugin_Changed;
}

bool IsGrounded(int client) {
	return GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1;
}

bool IsAliveSur(int client) {
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

float NearestSurDistance(int client) {
	static int i;
	static float vPos[3];
	static float vTar[3];
	static float dist;
	static float minDist;

	minDist = -1.0;
	GetClientAbsOrigin(client, vPos);
	for (i = 1; i <= MaxClients; i++) {
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			GetClientAbsOrigin(i, vTar);
			dist = GetVectorDistance(vPos, vTar);
			if (minDist == -1.0 || dist < minDist)
				minDist = dist;
		}
	}

	return minDist;
}

bool WithinViewAngle(int client, float offsetThreshold) {
	static int target;
	target = GetClientAimTarget(client);
	if (!IsAliveSur(target))
		return true;
	
	static float vSrc[3];
	static float vTar[3];
	static float vAng[3];
	GetClientEyePosition(target, vSrc);
	GetClientEyePosition(client, vTar);
	if (IsVisibleTo(vSrc, vTar)) {
		GetClientEyeAngles(target, vAng);
		return PointWithinViewAngle(vSrc, vTar, vAng, GetFOVDotProduct(offsetThreshold));
	}

	return false;
}

// credits = "AtomicStryker"
bool IsVisibleTo(const float vPos[3], const float vTarget[3]) {
	static float vLookAt[3];
	MakeVectorFromPoints(vPos, vTarget, vLookAt);
	GetVectorAngles(vLookAt, vLookAt);

	static Handle hndl;
	hndl = TR_TraceRayFilterEx(vPos, vLookAt, MASK_VISIBLE, RayType_Infinite, TraceEntityFilter);

	static bool isVisible;
	isVisible = false;
	if (TR_DidHit(hndl)) {
		static float vStart[3];
		TR_GetEndPosition(vStart, hndl);

		if ((GetVectorDistance(vPos, vStart, false) + 25.0) >= GetVectorDistance(vPos, vTarget))
			isVisible = true;
	}

	delete hndl;
	return isVisible;
}

bool TraceEntityFilter(int entity, int contentsMask) {
	if (!entity || entity > MaxClients) {
		static char cls[5];
		GetEdictClassname(entity, cls, sizeof cls);
		return cls[3] != 'e' && cls[3] != 'c';
	}

	return false;
}

// https://github.com/nosoop/stocksoup

/**
 * Checks if a point is in the field of view of an object.  Supports up to 180 degree FOV.
 * I forgot how the dot product stuff works.
 * 
 * Direct port of the function of the same name from the Source SDK:
 * https://github.com/ValveSoftware/source-sdk-2013/blob/beaae8ac45a2f322a792404092d4482065bef7ef/sp/src/public/mathlib/vector.h#L461-L477
 * 
 * @param vecSrcPosition	Source position of the view.
 * @param vecTargetPosition	Point to check if within view angle.
 * @param vecLookDirection	The direction to look towards.  Note that this must be a forward
 * 							angle vector.
 * @param flCosHalfFOV		The width of the forward view cone as a dot product result. For
 * 							subclasses of CBaseCombatCharacter, you can use the
 * 							`m_flFieldOfView` data property.  To manually calculate for a
 * 							desired FOV, use `GetFOVDotProduct(angle)` from math.inc.
 * @return					True if the point is within view from the source position at the
 * 							specified FOV.
 */
bool PointWithinViewAngle(const float vecSrcPosition[3], const float vecTargetPosition[3], const float vecLookDirection[3], float flCosHalfFOV) {
	static float vecDelta[3];
	SubtractVectors(vecTargetPosition, vecSrcPosition, vecDelta);
	static float cosDiff;
	cosDiff = GetVectorDotProduct(vecLookDirection, vecDelta);
	if (cosDiff < 0.0)
		return false;

	// a/sqrt(b) > c  == a^2 > b * c ^2
	return cosDiff * cosDiff >= GetVectorLength(vecDelta, true) * flCosHalfFOV * flCosHalfFOV;
}

/**
 * Calculates the width of the forward view cone as a dot product result from the given angle.
 * This manually calculates the value of CBaseCombatCharacter's `m_flFieldOfView` data property.
 *
 * For reference: https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/hl2/npc_bullseye.cpp#L151
 *
 * @param angle     The FOV value in degree
 * @return          Width of the forward view cone as a dot product result
 */
float GetFOVDotProduct(float angle) {
	return Cosine(DegToRad(angle) / 2.0);
}

// https://github.com/bcserv/smlib/blob/transitional_syntax/scripting/include/smlib/math.inc
/**
 * Returns a random, uniform Integer number in the specified (inclusive) range.
 * This is safe to use multiple times in a function.
 * The seed is set automatically for each plugin.
 * Rewritten by MatthiasVance, thanks.
 *
 * @param min			Min value used as lower border
 * @param max			Max value used as upper border
 * @return				Random Integer number between min and max
 */
int Math_GetRandomInt(int min, int max)
{
	int random = GetURandomInt();

	if (random == 0) {
		random++;
	}

	return RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
}