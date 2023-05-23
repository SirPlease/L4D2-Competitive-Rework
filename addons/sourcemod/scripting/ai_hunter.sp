#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

ConVar
	g_hLungeInterval,
	g_hHunterPounceRe,
	g_hFastPounceProximity,
	g_hPounceVerticalAngle,
	g_hPounceAngleMean,
	g_hPounceAngleStd,
	g_hStraightPounceProximity,
	g_hAimOffsetSensitivityHunter,
	g_hWallDetectionDistance;

float
	g_fLungeInterval,
	g_fFastPounceProximity,
	g_fPounceVerticalAngle,
	g_fPounceAngleMean,
	g_fPounceAngleStd,
	g_fStraightPounceProximity,
	g_fWallDetectionDistance,
	g_fAimOffsetSensitivityHunter,
	g_fCanLungeTime[MAXPLAYERS + 1];

bool
	g_bIgnoreCrouch,
	g_bHasQueuedLunge[MAXPLAYERS + 1];

public Plugin myinfo = {
	name = "AI HUNTER",
	author = "Breezy",
	description = "Improves the AI behaviour of special infected",
	version = "1.0",
	url = "github.com/breezyplease"
};

public void OnPluginStart() {	
	g_hFastPounceProximity = 		CreateConVar("ai_fast_pounce_proximity",			"1000.0",	"At what distance to start pouncing fast");
	g_hPounceVerticalAngle = 		CreateConVar("ai_pounce_vertical_angle",			"7.0",		"Vertical angle to which AI hunter pounces will be restricted");
	g_hPounceAngleMean = 			CreateConVar("ai_pounce_angle_mean",				"10.0",		"Mean angle produced by Gaussian RNG");
	g_hPounceAngleStd = 			CreateConVar("ai_pounce_angle_std",					"20.0",		"One standard deviation from mean as produced by Gaussian RNG");
	g_hStraightPounceProximity =	CreateConVar("ai_straight_pounce_proximity",		"200.0",	"Distance to nearest survivor at which hunter will consider pouncing straight");
	g_hAimOffsetSensitivityHunter =	CreateConVar("ai_aim_offset_sensitivity_hunter",	"180.0",	"If the hunter has a target, it will not straight pounce if the target's aim on the horizontal axis is within this radius", _, true, 0.0, true, 180.0);
	g_hWallDetectionDistance = 		CreateConVar("ai_wall_detection_distance",			"-1.0",		"How far in front of himself infected bot will check for a wall. Use '-1' to disable feature");
	g_hLungeInterval = 				FindConVar("z_lunge_interval");
	g_hHunterPounceRe = 			FindConVar("hunter_pounce_ready_range");

	g_hLungeInterval.AddChangeHook(CvarChanged);
	g_hFastPounceProximity.AddChangeHook(CvarChanged);
	g_hPounceVerticalAngle.AddChangeHook(CvarChanged);
	g_hPounceAngleMean.AddChangeHook(CvarChanged);
	g_hPounceAngleStd.AddChangeHook(CvarChanged);
	g_hStraightPounceProximity.AddChangeHook(CvarChanged);
	g_hAimOffsetSensitivityHunter.AddChangeHook(CvarChanged);
	g_hWallDetectionDistance.AddChangeHook(CvarChanged);
	
	HookEvent("round_end",		Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_spawn",	Event_PlayerSpawn);
	HookEvent("ability_use",	Event_AbilityUse);
}

public void OnAllPluginsLoaded() {
	g_bIgnoreCrouch = false;

	ConVar cv = FindConVar("l4d2_hunter_patch_convert_leap");
	if (cv && cv.IntValue == 1) {
		cv = FindConVar("l4d2_hunter_patch_crouch_pounce");
		if (cv && cv.IntValue == 2)
			g_bIgnoreCrouch = true;
	}

	g_hHunterPounceRe.FloatValue = g_bIgnoreCrouch ? 0.0 : 1000.0;
}

public void OnPluginEnd() {
	FindConVar("z_pounce_crouch_delay").RestoreDefault();
	FindConVar("z_pounce_silence_range").RestoreDefault();
	FindConVar("hunter_pounce_ready_range").RestoreDefault();
	FindConVar("hunter_pounce_max_loft_angle").RestoreDefault();
	FindConVar("hunter_committed_attack_range").RestoreDefault();
	FindConVar("hunter_leap_away_give_up_range").RestoreDefault();
}

public void OnConfigsExecuted() {
	GetCvars();
	TweakSettings();
}

void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	GetCvars();
}

void TweakSettings() {
	OnAllPluginsLoaded();
	FindConVar("z_pounce_crouch_delay").FloatValue =			0.0;
	FindConVar("z_pounce_silence_range").FloatValue =			999999.0;
	FindConVar("hunter_pounce_max_loft_angle").FloatValue =		0.0;
	FindConVar("hunter_committed_attack_range").FloatValue =	600.0;
	FindConVar("hunter_leap_away_give_up_range").FloatValue =	0.0;
}

void GetCvars() {
	g_fLungeInterval =				g_hLungeInterval.FloatValue;
	g_fFastPounceProximity =		g_hFastPounceProximity.FloatValue;
	g_fPounceVerticalAngle =		g_hPounceVerticalAngle.FloatValue;
	g_fPounceAngleMean =			g_hPounceAngleMean.FloatValue;
	g_fPounceAngleStd =				g_hPounceAngleStd.FloatValue;
	g_fStraightPounceProximity =	g_hStraightPounceProximity.FloatValue;
	g_fAimOffsetSensitivityHunter =	g_hAimOffsetSensitivityHunter.FloatValue;
	g_fWallDetectionDistance =		g_hWallDetectionDistance.FloatValue;
}

public void OnMapEnd() {
	for (int i = 1; i <= MaxClients; i++)
		g_fCanLungeTime[i] = 0.0;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	OnMapEnd();
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_fCanLungeTime[client] = 0.0;
	g_bHasQueuedLunge[client] = false;
}

void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || !IsFakeClient(client))
		return;

	static char ability[16];
	event.GetString("ability", ability, sizeof ability);
	if (strcmp(ability, "ability_lunge") == 0)
		HunterPounce(client);
}

public Action OnPlayerRunCmd(int client, int &buttons) {
	if (!IsClientInGame(client) || !IsFakeClient(client) || GetClientTeam(client) != 3 || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_zombieClass") != 3 || GetEntProp(client, Prop_Send, "m_isGhost"))
		return Plugin_Continue;

	if (L4D_IsPlayerStaggering(client))
		return Plugin_Continue;

	static int flags;
	flags = GetEntityFlags(client);
	if (flags & FL_ONGROUND == 0 || (!g_bIgnoreCrouch && flags & FL_DUCKING == 0) ||!GetEntProp(client, Prop_Send, "m_hasVisibleThreats"))
		return Plugin_Continue;
	
	buttons &= ~IN_ATTACK2;

	static float vPos[3];
	GetClientAbsOrigin(client, vPos);
	if (NearestSurDistance(client, vPos) > g_fFastPounceProximity)
		return Plugin_Changed;

	buttons &= ~IN_ATTACK;	
	if (!g_bHasQueuedLunge[client]) {
		g_bHasQueuedLunge[client] = true;
		g_fCanLungeTime[client] = GetGameTime() + g_fLungeInterval;
	}
	else if (g_fCanLungeTime[client] < GetGameTime()) {
		buttons |= IN_ATTACK;
		g_bHasQueuedLunge[client] = false;
	}	

	return Plugin_Changed;
}

float NearestSurDistance(int client, const float vPos[3]) {
	static int i;
	static float vTar[3];
	static float dist;
	static float minDist;

	minDist = -1.0;
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

void HunterPounce(int client) {
	static int iEnt;
	static float vPos[3];
	GetClientAbsOrigin(client, vPos);
	if (g_fWallDetectionDistance > 0.0 && HitWall(client, vPos)) {
		iEnt = GetEntPropEnt(client, Prop_Send, "m_customAbility");
		AngleLunge(iEnt, Math_GetRandomInt(0, 1) ? 45.0 : 315.0);
	}
	else {
		if (WithinViewAngle(client, g_fAimOffsetSensitivityHunter)/*IsBeingWatched(client, g_fAimOffsetSensitivityHunter)*/ && NearestSurDistance(client, vPos) > g_fStraightPounceProximity) {
			iEnt = GetEntPropEnt(client, Prop_Send, "m_customAbility");
			AngleLunge(iEnt, GaussianRNG(g_fPounceAngleMean, g_fPounceAngleStd));
			LimitLungeVerticality(iEnt);
		}	
	}
}

#define OBSTACLE_HEIGHT 18.0
bool HitWall(int client, float vStart[3]) {
	vStart[2] += OBSTACLE_HEIGHT;
	static float vAng[3];
	static float vEnd[3];
	GetClientEyeAngles(client, vAng);
	GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAng, vAng);
	vEnd = vAng;
	ScaleVector(vEnd, g_fWallDetectionDistance);
	AddVectors(vStart, vEnd, vEnd);

	static Handle hndl;
	hndl = TR_TraceHullFilterEx(vStart, vEnd, view_as<float>({-16.0, -16.0, 0.0}), view_as<float>({16.0, 16.0, 33.0}), MASK_PLAYERSOLID_BRUSHONLY, TraceEntityFilter);
	if (TR_DidHit(hndl)) {
		static float vPlane[3];
		TR_GetPlaneNormal(hndl, vPlane);
		if (RadToDeg(ArcCosine(GetVectorDotProduct(vAng, vPlane))) > 165.0) {
			delete hndl;
			return true;
		}
	}

	delete hndl;
	return false;
}

stock bool IsBeingWatched(int client, float offsetThreshold) {
	static int target;
	target = GetClientAimTarget(client);
	return !IsAliveSur(target) || GetPlayerAimOffset(client, target) <= offsetThreshold;
}

float GetPlayerAimOffset(int client, int target) {
	static float vAng[3];
	static float vPos[3];
	static float vDir[3];
	GetClientEyeAngles(target, vAng);
	vAng[0] = vAng[2] = 0.0;
	GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAng, vAng);

	GetClientAbsOrigin(client, vPos);
	GetClientAbsOrigin(target, vDir);
	vPos[2] = vDir[2] = 0.0;
	MakeVectorFromPoints(vDir, vPos, vDir);
	NormalizeVector(vDir, vDir);

	return RadToDeg(ArcCosine(GetVectorDotProduct(vAng, vDir)));
}

void AngleLunge(int iEnt, float turnAngle) {
	static float vLunge[3];
	GetEntPropVector(iEnt, Prop_Send, "m_queuedLunge", vLunge);
	turnAngle = DegToRad(turnAngle);

	static float vForcedLunge[3];
	vForcedLunge[0] = vLunge[0] * Cosine(turnAngle) - vLunge[1] * Sine(turnAngle);
	vForcedLunge[1] = vLunge[0] * Sine(turnAngle) + vLunge[1] * Cosine(turnAngle);
	vForcedLunge[2] = vLunge[2];

	SetEntPropVector(iEnt, Prop_Send, "m_queuedLunge", vForcedLunge);
}

void LimitLungeVerticality(int iEnt) {
	static float vLunge[3];
	GetEntPropVector(iEnt, Prop_Send, "m_queuedLunge", vLunge);

	static float fVertAngle;
	fVertAngle = DegToRad(g_fPounceVerticalAngle);

	static float vFlatLunge[3];
	vFlatLunge[1] = vLunge[1] * Cosine(fVertAngle) - vLunge[2] * Sine(fVertAngle);
	vFlatLunge[2] = vLunge[1] * Sine(fVertAngle) + vLunge[2] * Cosine(fVertAngle);
	vFlatLunge[0] = vLunge[0] * Cosine(fVertAngle) + vLunge[2] * Sine(fVertAngle);
	vFlatLunge[2] = vLunge[0] * -Sine(fVertAngle) + vLunge[2] * Cosine(fVertAngle);
	
	SetEntPropVector(iEnt, Prop_Send, "m_queuedLunge", vFlatLunge);
}

/** 
 * Thanks to Newteee:
 * Random number generator fit to a bellcurve. Function to generate Gaussian Random Number fit to a bellcurve with a specified mean and std
 * Uses Polar Form of the Box-Muller transformation
*/
float GaussianRNG(float mean, float std) {
	static float x1;
	static float x2;
	static float w;

	do {
		x1 = 2.0 * Math_GetRandomFloat(0.0, 1.0) - 1.0;
		x2 = 2.0 * Math_GetRandomFloat(0.0, 1.0) - 1.0;
		w = Pow(x1, 2.0) + Pow(x2, 2.0);
	} while (w >= 1.0);
	
	static const float e = 2.71828;
	w = SquareRoot(-2.0 * (Logarithm(w, e) / w));

	static float y1;
	static float y2;
	y1 = x1 * w;
	y2 = x2 * w;

	static float z1;
	static float z2;
	z1 = y1 * std + mean;
	z2 = y2 * std - mean;

	return Math_GetRandomFloat(0.0, 1.0) < 0.5 ? z1 : z2;
}

bool IsAliveSur(int client) {
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

// https://github.com/bcserv/smlib/blob/transitional_syntax/scripting/include/smlib/math.inc
#define SIZE_OF_INT	2147483647 // without 0
int Math_GetRandomInt(int min, int max) {
	int random = GetURandomInt();
	if (random == 0)
		random++;

	return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}

float Math_GetRandomFloat(float min, float max) {
	return (GetURandomFloat() * (max  - min)) + min;
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
