#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define BOOST			90.0
#define PLAYER_HEIGHT	72.0

ConVar
	g_hTankBhop,
	g_hTankAttackRange,
	g_hTankThrowForce,
	g_hAimOffsetSensitivity;

bool
	g_bTankBhop;

float
	g_fTankAttackRange,
	g_fTankThrowForce,
	g_fAimOffsetSensitivity;

public Plugin myinfo = {
	name = "AI TANK",
	author = "Breezy",
	description = "Improves the AI behaviour of special infected",
	version = "1.0",
	url = "github.com/breezyplease"
};

public void OnPluginStart() {
	g_hTankBhop =				CreateConVar("ai_tank_bhop",					"1",	"Flag to enable bhop facsimile on AI tanks");
	g_hAimOffsetSensitivity =	CreateConVar("ai_aim_offset_sensitivity_tank",	"22.5",	"If the tank has a target, it will not straight throw if the target's aim on the horizontal axis is within this radius", _, true, 0.0, true, 180.0);
	g_hTankAttackRange =		FindConVar("tank_attack_range");
	g_hTankThrowForce =			FindConVar("z_tank_throw_force");

	g_hTankBhop.AddChangeHook(CvarChanged);
	g_hTankAttackRange.AddChangeHook(CvarChanged);
	g_hTankThrowForce.AddChangeHook(CvarChanged);
	g_hAimOffsetSensitivity.AddChangeHook(CvarChanged);
}

public void OnConfigsExecuted() {
	GetCvars();
}

void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	GetCvars();
}

void GetCvars() {
	g_bTankBhop =				g_hTankBhop.BoolValue;
	g_fTankAttackRange =		g_hTankAttackRange.FloatValue;
	g_fTankThrowForce =			g_hTankThrowForce.FloatValue;
	g_fAimOffsetSensitivity =	g_hAimOffsetSensitivity.FloatValue;
}

int g_iCurTarget[MAXPLAYERS + 1];
public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget) {
	g_iCurTarget[specialInfected] = curTarget;
	return Plugin_Continue;
}

float g_fRunTopSpeed[MAXPLAYERS + 1];
public Action L4D_OnGetRunTopSpeed(int target, float &retVal) {
	g_fRunTopSpeed[target] = retVal;
	return Plugin_Continue;
}

bool g_bModify[MAXPLAYERS + 1];
public Action OnPlayerRunCmd(int client, int &buttons) {
	if (!g_bTankBhop)
		return Plugin_Continue;

	if (!IsClientInGame(client) || !IsFakeClient(client) || GetClientTeam(client) != 3 || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_zombieClass") != 8 || GetEntProp(client, Prop_Send, "m_isGhost") == 1)
		return Plugin_Continue;

	if (L4D_IsPlayerStaggering(client))
		return Plugin_Continue;

	if (GetEntityMoveType(client) == MOVETYPE_LADDER || GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1 || (!GetEntProp(client, Prop_Send, "m_hasVisibleThreats") && !TargetSur(client)))
		return Plugin_Continue;

	static float val;
	static float vVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
	vVel[2] = 0.0;
	val = GetVectorLength(vVel);
	if (!CheckPlayerMove(client, val))
		return Plugin_Continue;

	static float vAng[3];
	if (IsGrounded(client)) {
		g_bModify[client] = false;

		static float curTargetDist;
		static float nearestSurDist;
		GetSurDistance(client, curTargetDist, nearestSurDist);
		if (curTargetDist > 0.5 * g_fTankAttackRange && -1.0 < nearestSurDist < 1500.0) {
			GetClientEyeAngles(client, vAng);
			return BunnyHop(client, buttons, vAng);
		}
	}
	else {
		if (g_bModify[client] || val < GetEntPropFloat(client, Prop_Send, "m_flMaxspeed") + BOOST)
			return Plugin_Continue;

		static int target;
		target = g_iCurTarget[client];//GetClientAimTarget(client, true);
		/*if (!IsAliveSur(target))
			target = g_iCurTarget[client];*/

		if (!IsAliveSur(target))
			return Plugin_Continue;

		static float vPos[3];
		static float vTar[3];
		static float vEye1[3];
		static float vEye2[3];
		GetClientAbsOrigin(client, vPos);
		GetClientAbsOrigin(target, vTar);
		val = GetVectorDistance(vPos, vTar);
		if (val < g_fTankAttackRange || val > 440.0)
			return Plugin_Continue;

		GetClientEyePosition(client, vEye1);
		if (vEye1[2] < vTar[2])
			return Plugin_Continue;

		GetClientEyePosition(target, vEye2);
		if (vPos[2] > vEye2[2])
			return Plugin_Continue;

		vAng = vVel;
		vAng[2] = 0.0;
		NormalizeVector(vAng, vAng);

		static float vBuf[3];
		MakeVectorFromPoints(vPos, vTar, vBuf);
		vBuf[2] = 0.0;
		NormalizeVector(vBuf, vBuf);
		if (RadToDeg(ArcCosine(GetVectorDotProduct(vAng, vBuf))) < 90.0)
			return Plugin_Continue;

		if (vecHitWall(client, vPos, vTar))
			return Plugin_Continue;

		MakeVectorFromPoints(vPos, vEye2, vVel);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
		g_bModify[client] = true;
	}
	
	return Plugin_Continue;
}

bool IsGrounded(int client) {
	return GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1;
}

bool TargetSur(int client) {
	return IsAliveSur(GetClientAimTarget(client, true));
}

bool CheckPlayerMove(int client, float vel) {
	return vel > 0.9 * GetEntPropFloat(client, Prop_Send, "m_flMaxspeed") > 0.0;
}

Action BunnyHop(int client, int &buttons, const float vAng[3]) {
	float vVec[3];
	if (buttons & IN_FORWARD && !(buttons & IN_BACK)) {
		GetAngleVectors(vAng, vVec, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vVec, vVec);
		ScaleVector(vVec, BOOST * 2.0);
		float vVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vVel);
		AddVectors(vVel, vVec, vVel);
		if (CheckHopVel(client, vAng, vVel)) {
			buttons |= IN_DUCK;
			buttons |= IN_JUMP;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
			return Plugin_Changed;
		}
	}
	else if (buttons & IN_BACK && !(buttons & IN_FORWARD)) {
		GetAngleVectors(vAng, vVec, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vVec, vVec);
		ScaleVector(vVec, -BOOST);
		float vVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vVel);
		AddVectors(vVel, vVec, vVel);
		if (CheckHopVel(client, vAng, vVel)) {
			buttons |= IN_DUCK;
			buttons |= IN_JUMP;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
			return Plugin_Changed;
		}
	}

	if (buttons & IN_MOVERIGHT && !(buttons & IN_MOVELEFT)) {
		GetAngleVectors(vAng, NULL_VECTOR, vVec, NULL_VECTOR);
		NormalizeVector(vVec, vVec);
		ScaleVector(vVec, BOOST);
		float vVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vVel);
		AddVectors(vVel, vVec, vVel);
		if (CheckHopVel(client, vAng, vVel)) {
			buttons |= IN_DUCK;
			buttons |= IN_JUMP;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
			return Plugin_Changed;
		}
	}
	else if (buttons & IN_MOVELEFT && !(buttons & IN_MOVERIGHT)) {
		GetAngleVectors(vAng, NULL_VECTOR, vVec, NULL_VECTOR);
		NormalizeVector(vVec, vVec);
		ScaleVector(vVec, -BOOST);
		float vVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vVel);
		AddVectors(vVel, vVec, vVel);
		if (CheckHopVel(client, vAng, vVel)) {
			buttons |= IN_DUCK;
			buttons |= IN_JUMP;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

bool CheckHopVel(int client, const float vAng[3], const float vVel[3]) {
	static float vMins[3];
	static float vMaxs[3];
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);

	static float vPos[3];
	static float vEnd[3];
	GetClientAbsOrigin(client, vPos);
	float vel = GetVectorLength(vVel);
	NormalizeVector(vVel, vEnd);
	ScaleVector(vEnd, vel + FloatAbs(vMaxs[0] - vMins[0]) + 3.0);
	AddVectors(vPos, vEnd, vEnd);

	static bool hit;
	static Handle hndl;
	static float vVec[3];
	static float vNor[3];
	static float vPlane[3];

	hit = false;
	vPos[2] += 10.0;
	vEnd[2] += 10.0;
	hndl = TR_TraceHullFilterEx(vPos, vEnd, vMins, vMaxs, MASK_PLAYERSOLID, TraceEntityFilter);
	if (TR_DidHit(hndl)) {
		hit = true;
		TR_GetEndPosition(vVec, hndl);

		NormalizeVector(vVel, vNor);
		TR_GetPlaneNormal(hndl, vPlane);
		if (RadToDeg(ArcCosine(GetVectorDotProduct(vNor, vPlane))) > 165.0) {
			delete hndl;
			return false;
		}

		vNor[1] = vAng[1];
		vNor[0] = vNor[2] = 0.0;
		GetAngleVectors(vNor, vNor, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vNor, vNor);
		if (RadToDeg(ArcCosine(GetVectorDotProduct(vNor, vPlane))) > 165.0) {
			delete hndl;
			return false;
		}
	}
	else {
		vNor[1] = vAng[1];
		vNor[0] = vNor[2] = 0.0;
		GetAngleVectors(vNor, vNor, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vNor, vNor);
		vPlane = vNor;
		ScaleVector(vPlane, 128.0);
		AddVectors(vPos, vPlane, vPlane);
		delete hndl;
		hndl = TR_TraceHullFilterEx(vPos, vPlane, view_as<float>({-16.0, -16.0, 0.0}), view_as<float>({16.0, 16.0, 33.0}), MASK_PLAYERSOLID, TraceWallFilter, client);
		if (TR_DidHit(hndl)) {
			TR_GetPlaneNormal(hndl, vPlane);
			if (RadToDeg(ArcCosine(GetVectorDotProduct(vNor, vPlane))) > 165.0) {
				delete hndl;
				return false;
			}
		}

		delete hndl;
	}

	delete hndl;
	if (!hit)
		vVec = vEnd;

	static float vDown[3];
	vDown[0] = vVec[0];
	vDown[1] = vVec[1];
	vDown[2] = vVec[2] - 100000.0;

	hndl = TR_TraceHullFilterEx(vVec, vDown, vMins, vMaxs, MASK_PLAYERSOLID, TraceSelfFilter, client);
	if (!TR_DidHit(hndl)) {
		delete hndl;
		return false;
	}

	TR_GetEndPosition(vEnd, hndl);
	delete hndl;
	return vVec[2] - vEnd[2] < 104.0;
}

bool TraceSelfFilter(int entity, int contentsMask, any data) {
	return entity != data;
}

bool TraceWallFilter(int entity, int contentsMask, any data) {
	if (entity != data) {
		static char cls[5];
		GetEdictClassname(entity, cls, sizeof cls);
		return cls[3] != 'e' && cls[3] != 'c';
	}

	return false;
}

bool TraceEntityFilter(int entity, int contentsMask) {
	if (!entity || entity > MaxClients) {
		static char cls[5];
		GetEdictClassname(entity, cls, sizeof cls);
		return cls[3] != 'e' && cls[3] != 'c';
	}

	return false;
}

void GetSurDistance(int client, float &curTargetDist, float &nearestSurDist) {
	static float vPos[3];
	static float vTar[3];

	GetClientAbsOrigin(client, vPos);
	if (!IsAliveSur(g_iCurTarget[client]))
		curTargetDist = -1.0;
	else {
		GetClientAbsOrigin(g_iCurTarget[client], vTar);
		curTargetDist = GetVectorDistance(vPos, vTar);
	}

	static int i;
	static float dist;

	nearestSurDist = -1.0;
	GetClientAbsOrigin(client, vPos);
	for (i = 1; i <= MaxClients; i++) {
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			GetClientAbsOrigin(i, vTar);
			dist = GetVectorDistance(vPos, vTar);
			if (nearestSurDist == -1.0 || dist < nearestSurDist)
				nearestSurDist = dist;
		}
	}
}

public Action L4D2_OnSelectTankAttack(int client, int &sequence) {
	if (sequence != 50 || !IsFakeClient(client))
		return Plugin_Continue;

	sequence = Math_GetRandomInt(0, 1) ? 49 : 51;
	return Plugin_Handled;
}

public Action L4D_TankRock_OnRelease(int tank, int rock, float vecPos[3], float vecAng[3], float vecVel[3], float vecRot[3]) {
	if (rock <= MaxClients || !IsValidEntity(rock))
		return Plugin_Continue;

	if (tank < 1 || tank > MaxClients || !IsClientInGame(tank)|| GetClientTeam(tank) != 3 || GetEntProp(tank, Prop_Send, "m_zombieClass") != 8)
		return Plugin_Continue;

	if (!IsFakeClient(tank) && (!CheckCommandAccess(tank, "", ADMFLAG_ROOT) || GetClientButtons(tank) & IN_SPEED == 0))
		return Plugin_Continue;

	int target = GetClientAimTarget(tank, true);
	if (IsAliveSur(target) && !Incapacitated(target) && !IsPinned(target) && !RockHitWall(tank, rock, target) && !WithinViewAngle(tank, target, g_fAimOffsetSensitivity))
		return Plugin_Continue;
	
	target = GetClosestSur(tank, rock, 2.0 * g_fTankThrowForce, target);
	if (!IsAliveSur(target))
		return Plugin_Continue;

	float vPos[3];
	float vTar[3];
	float vVec[3];
	GetClientAbsOrigin(tank, vPos);
	GetClientAbsOrigin(target, vTar);

	vVec[2] = vPos[2];
	vPos[2] = vTar[2];
	vTar[2] += GetVectorDistance(vPos, vTar) / g_fTankThrowForce * PLAYER_HEIGHT;

	vPos[2] = vVec[2];
	float delta = vTar[2] - vPos[2];
	if (delta > PLAYER_HEIGHT)
		vTar[2] += delta / PLAYER_HEIGHT * 7.2;
	else {
		bool success;
		while (delta < PLAYER_HEIGHT) {
			if (!RockHitWall(tank, rock, -1, vTar)) {
				success = true;
				break;
			}

			delta += 7.0;
			vTar[2] += 7.0;
		}

		if (!success)
			vTar[2] -= 14.0;
	}

	GetClientEyePosition(tank, vPos);
	MakeVectorFromPoints(vPos, vTar, vVec);
	GetVectorAngles(vVec, vTar);
	vecAng = vTar;

	float vel = GetVectorLength(vVec);
	vel = vel > g_fTankThrowForce ? vel : g_fTankThrowForce;
	NormalizeVector(vVec, vVec);
	ScaleVector(vVec, vel + g_fRunTopSpeed[target]);
	vecVel = vVec;
	return Plugin_Changed;
}

bool IsAliveSur(int client) {
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

bool Incapacitated(int client) {
	return !!GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool IsPinned(int client) {
	/*if (GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
		return true;*/
	if (GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	/*if (GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0)
		return true;*/
	if (GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0)
		return true;
	return false;
}

bool vecHitWall(int client, float vPos[3], float vTar[3]) {
	vPos[2] += 10.0;
	vTar[2] += 10.0;
	MakeVectorFromPoints(vPos, vTar, vTar);
	static float dist;
	dist = GetVectorLength(vTar);
	NormalizeVector(vTar, vTar);
	ScaleVector(vTar, dist);
	AddVectors(vPos, vTar, vTar);

	static float vMins[3];
	static float vMaxs[3];
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);
	vMins[2] += 10.0;
	vMaxs[2] -= 10.0;

	static bool hit;
	static Handle hndl;
	hndl = TR_TraceHullFilterEx(vPos, vTar, vMins, vMaxs, MASK_PLAYERSOLID, TraceEntityFilter);
	hit = TR_DidHit(hndl);
	delete hndl;
	return hit;
}

bool RockHitWall(int tank, int ent, int target = -1, const float vEnd[3] = NULL_VECTOR) {
	static float vSrc[3];
	static float vTar[3];
	GetClientEyePosition(tank, vSrc);

	if (target == -1)
		vTar = vEnd;
	else
		GetClientEyePosition(target, vTar);

	static float vMins[3];
	static float vMaxs[3];
	GetEntPropVector(ent, Prop_Send, "m_vecMins", vMins);
	GetEntPropVector(ent, Prop_Send, "m_vecMaxs", vMaxs);

	static bool hit;
	static Handle hndl;
	hndl = TR_TraceHullFilterEx(vSrc, vTar, vMins, vMaxs, MASK_SOLID, TraceRockFilter, ent);
	hit = TR_DidHit(hndl);
	delete hndl;
	return hit;
}

bool TraceRockFilter(int entity, int contentsMask, any data) {
	if (entity == data)
		return false;

	if (!entity || entity > MaxClients) {
		static char cls[5];
		GetEdictClassname(entity, cls, sizeof cls);
		return cls[3] != 'e' && cls[3] != 'c';
	}

	return false;
}

int GetClosestSur(int client, int ent, float range, int exclude = -1) {
	static int i;
	static int num;
	static int index;
	static float dist;
	static float vAng[3];
	static float vSrc[3];
	static float vTar[3];
	static int clients[MAXPLAYERS + 1];
	
	num = 0;
	GetClientEyePosition(client, vSrc);
	num = GetClientsInRange(vSrc, RangeType_Visibility, clients, MAXPLAYERS);

	if (!num)
		return exclude;

	static ArrayList al_targets;
	al_targets = new ArrayList(3);
	float fov = GetFOVDotProduct(g_fAimOffsetSensitivity);
	for (i = 0; i < num; i++) {
		if (!clients[i] || clients[i] == exclude)
			continue;

		if (GetClientTeam(clients[i]) != 2 || !IsPlayerAlive(clients[i]) || Incapacitated(clients[i]) || IsPinned(clients[i]) || RockHitWall(client, ent, clients[i]))
			continue;

		GetClientEyePosition(clients[i], vTar);
		dist = GetVectorDistance(vSrc, vTar);
		if (dist < range) {
			index = al_targets.Push(dist);
			al_targets.Set(index, clients[i], 1);

			GetClientEyeAngles(clients[i], vAng);
			al_targets.Set(index, !PointWithinViewAngle(vTar, vSrc, vAng, fov) ? 0 : 1, 2);
		}
	}

	if (!al_targets.Length) {
		delete al_targets;
		return exclude;
	}

	al_targets.Sort(Sort_Ascending, Sort_Float);
	index = al_targets.FindValue(0, 2);
	i = al_targets.Get(index != -1 && al_targets.Get(index, 0) < g_fTankThrowForce ? index : Math_GetRandomInt(0, RoundToCeil((al_targets.Length - 1) * 0.8)), 1);
	delete al_targets;
	return i;
}

bool WithinViewAngle(int client, int viewer, float offsetThreshold) {
	static float vSrc[3];
	static float vTar[3];
	static float vAng[3];
	GetClientEyePosition(viewer, vSrc);
	GetClientEyePosition(client, vTar);
	if (IsVisibleTo(vSrc, vTar)) {
		GetClientEyeAngles(viewer, vAng);
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
#define SIZE_OF_INT	2147483647 // without 0
int Math_GetRandomInt(int min, int max) {
	int random = GetURandomInt();
	if (random == 0)
		random++;

	return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}