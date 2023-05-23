#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define FIXFLY			1
#define DEBUG			0
#define BOOST			90.0
#define PLAYER_HEIGHT	72.0

ConVar
	g_hChargerBhop,
	g_hChargeProximity,
	g_hHealthThreshold,
	g_hAimOffsetSensitivity,
	#if DEBUG
	g_hFallSpeedFatal,
	#endif
	g_hChargeMaxSpeed,
	g_hChargeStartSpeed;

float
	g_fChargeProximity,
	g_fAimOffsetSensitivity,
	#if DEBUG
	g_fFallSpeedFatal,
	#endif
	g_fChargeMaxSpeed,
	g_fChargeStartSpeed;

int
	g_iHealthThreshold;

bool
	g_bChargerBhop,
	g_bShouldCharge[MAXPLAYERS + 1];

public Plugin myinfo = {
	name = "AI CHARGER",
	author = "Breezy",
	description = "Improves the AI behaviour of special infected",
	version = "1.0",
	url = "github.com/breezyplease"
};

public void OnPluginStart() {
	g_hChargerBhop =			CreateConVar("ai_charger_bhop",						"1",		"Flag to enable bhop facsimile on AI chargers");
	g_hChargeProximity =		CreateConVar("ai_charge_proximity",					"200.0",	"How close a client will approach before charging");
	g_hHealthThreshold =		CreateConVar("ai_health_threshold_charger",			"300",		"Charger will charge if its health drops to this level");
	g_hAimOffsetSensitivity =	CreateConVar("ai_aim_offset_sensitivity_charger",	"22.5",		"If the charger has a target, it will not straight charge if the target's aim on the horizontal axis is within this radius", _, true, 0.0, true, 180.0);
	#if DEBUG
	g_hFallSpeedFatal = 		FindConVar("fall_speed_fatal");
	#endif
	g_hChargeMaxSpeed =			FindConVar("z_charge_max_speed");
	g_hChargeStartSpeed =		FindConVar("z_charge_start_speed");

	g_hChargerBhop.AddChangeHook(CvarChanged);
	g_hChargeProximity.AddChangeHook(CvarChanged);
	g_hHealthThreshold.AddChangeHook(CvarChanged);
	g_hAimOffsetSensitivity.AddChangeHook(CvarChanged);
	#if DEBUG
	g_hFallSpeedFatal.AddChangeHook(CvarChanged);
	#endif
	g_hChargeMaxSpeed.AddChangeHook(CvarChanged);
	g_hChargeStartSpeed.AddChangeHook(CvarChanged);

	HookEvent("player_spawn",			Event_PlayerSpawn);
	HookEvent("charger_charge_start",	Event_ChargerChargeStart);
}

public void OnConfigsExecuted() {
	GetCvars();
}

void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	GetCvars();
}

void GetCvars() {
	g_bChargerBhop =			g_hChargerBhop.BoolValue;
	g_fChargeProximity =		g_hChargeProximity.FloatValue;
	g_iHealthThreshold =		g_hHealthThreshold.IntValue;
	g_fAimOffsetSensitivity =	g_hAimOffsetSensitivity.FloatValue;
	#if DEBUG
	g_fFallSpeedFatal = 		g_hFallSpeedFatal.FloatValue;
	#endif
	g_fChargeMaxSpeed =			g_hChargeMaxSpeed.FloatValue;
	g_fChargeStartSpeed =		g_hChargeStartSpeed.FloatValue;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	g_bShouldCharge[GetClientOfUserId(event.GetInt("userid"))] = false;
}

void Event_ChargerChargeStart(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || !IsFakeClient(client))
		return;

	ChargerCharge(client);
}

#if FIXFLY
// 避免charger仰角携带玩家冲出地图外
public void L4D2_OnStartCarryingVictim_Post(int victim, int attacker) {
	if (GetEntPropEnt(attacker, Prop_Send, "m_carryVictim") != -1) {
		DataPack dPack = new DataPack();
		dPack.WriteCell(GetClientUserId(victim));
		dPack.WriteCell(GetClientUserId(attacker));
		RequestFrame(NextFrame_SetVelocity, dPack);
	}
}

void NextFrame_SetVelocity(DataPack dPack) {
	dPack.Reset();
	int victim = dPack.ReadCell();
	int attacker = dPack.ReadCell();
	delete dPack;

	victim = GetClientOfUserId(victim);
	if (!victim || !IsClientInGame(victim))
		return;

	attacker = GetClientOfUserId(attacker);
	if (!attacker || !IsClientInGame(attacker))
		return;

	if (GetEntPropEnt(attacker, Prop_Send, "m_carryVictim") == -1)
		return;

	if (GetEntPropEnt(attacker, Prop_Send, "m_pummelVictim") != -1)
		return;

	float vVel[3];
	GetEntPropVector(attacker, Prop_Data, "m_vecVelocity", vVel);
	float vel = GetVectorLength(vVel);
	#if DEBUG
	if (vel > g_fFallSpeedFatal && GetDistanceToRoof(attacker) > 250.0) {
		vVel[0] = vVel[1] = 0.0;
		vVel[2] = vel;
	}
	else if (vVel[2] > 0.0){
		vVel[2] = 0.0;
		NormalizeVector(vVel, vVel);
		ScaleVector(vVel, vel);
	}
	#else
	if (vVel[2] <= 0.0)
		return;

	vVel[2] = 0.0;
	NormalizeVector(vVel, vVel);
	ScaleVector(vVel, vel);
	#endif

	TeleportEntity(attacker, NULL_VECTOR, NULL_VECTOR, vVel);
}
#endif

public void L4D_OnFalling(int client) {
	if (!IsFakeClient(client) || GetClientTeam(client) != 3 || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_zombieClass") != 6)
		return;

	int victim = GetEntPropEnt(client, Prop_Send, "m_carryVictim");
	if (IsAliveSur(victim)) {
		L4D2_Charger_EndPummel(victim, client);
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityMoveType(victim, MOVETYPE_WALK);
	}
}

#if DEBUG
float GetDistanceToRoof(int client, float maxheight = 3000.0) {
	float vMins[3], vMaxs[3], vOrigin[3], vEnd[3], vStart[3], distance;
	GetClientAbsOrigin(client, vStart);
	vStart[2] += 10.0;
	vEnd[0] = vStart[0];
	vEnd[1] = vStart[1];
	vEnd[2] = vStart[2] + maxheight;
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);
	GetClientAbsOrigin(client, vOrigin);
	Handle hndl = TR_TraceHullFilterEx(vOrigin, vEnd, vMins, vMaxs, MASK_PLAYERSOLID, TraceEntityFilter);
	if (TR_DidHit(hndl)) {
		float fEndPos[3];
		TR_GetEndPosition(fEndPos, hndl);
		vStart[2] -= 10.0;
		distance = GetVectorDistance(vStart, fEndPos);
	}
	else
		distance = maxheight;

	delete hndl;
	return distance;
}
#endif

int g_iCurTarget[MAXPLAYERS + 1];
public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget) {
	g_iCurTarget[specialInfected] = curTarget;
	return Plugin_Continue;
}

bool g_bModify[MAXPLAYERS + 1];
public Action OnPlayerRunCmd(int client, int &buttons) {
	if (!IsClientInGame(client) || !IsFakeClient(client) || GetClientTeam(client) != 3 || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_zombieClass") != 6 || GetEntProp(client, Prop_Send, "m_isGhost"))
		return Plugin_Continue;

	if (L4D_IsPlayerStaggering(client))
		return Plugin_Continue;

	static float nearestSurDist;
	nearestSurDist = NearestSurDistance(client);
	if (nearestSurDist > g_fChargeProximity && GetEntProp(client, Prop_Data, "m_iHealth") > g_iHealthThreshold) {
		if (!g_bShouldCharge[client])
			ResetAbilityTime(client, 0.1);
	}
	else
		g_bShouldCharge[client] = true;
		
	if (g_bShouldCharge[client] && CanCharge(client)) {
		static int target;
		target = GetClientAimTarget(client, false);
		if (IsAliveSur(target) && !Incapacitated(target) && GetEntPropEnt(target, Prop_Send, "m_carryAttacker") == -1) {
			static float vPos[3];
			static float vTar[3];
			GetClientAbsOrigin(client, vPos);
			GetClientAbsOrigin(target, vTar);
			if (GetVectorDistance(vPos, vTar) < 100.0 && !entHitWall(client, target)) {
				buttons |= IN_ATTACK;
				buttons |= IN_ATTACK2;
				return Plugin_Changed;
			}
		}
	}

	if (!g_bChargerBhop || GetEntityMoveType(client) == MOVETYPE_LADDER || GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1 || !GetEntProp(client, Prop_Send, "m_hasVisibleThreats"))
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

		if (CurTargetDistance(client) > 100.0 && -1.0 < nearestSurDist < 1500.0) {
			GetClientEyeAngles(client, vAng);
			return BunnyHop(client, buttons, vAng);
		}
	}
	else {
		if (g_bModify[client] || val < GetEntPropFloat(client, Prop_Send, "m_flMaxspeed") + BOOST)
			return Plugin_Continue;

		if (IsCharging(client))
			return Plugin_Continue;

		static int target;
		target = GetClientAimTarget(client, false);
		if (!IsAliveSur(target))
			target = g_iCurTarget[client];

		if (!IsAliveSur(target))
			return Plugin_Continue;

		static float vPos[3];
		static float vTar[3];
		static float vEye1[3];
		static float vEye2[3];
		GetClientAbsOrigin(client, vPos);
		GetClientAbsOrigin(target, vTar);
		val = GetVectorDistance(vPos, vTar);
		if (val < 100.0 || val > 440.0)
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

float CurTargetDistance(int client) {
	if (!IsAliveSur(g_iCurTarget[client]))
		return -1.0;

	static float vPos[3];
	static float vTar[3];
	GetClientAbsOrigin(client, vPos);
	GetClientAbsOrigin(g_iCurTarget[client], vTar);
	return GetVectorDistance(vPos, vTar);
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

bool entHitWall(int client, int target) {
	static float vPos[3];
	static float vTar[3];
	GetClientAbsOrigin(client, vPos);
	GetClientAbsOrigin(target, vTar);
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
	vMins[2] += dist > 49.0 ? 10.0 : 44.0;
	vMaxs[2] -= 10.0;

	static bool hit;
	static Handle hndl;
	hndl = TR_TraceHullFilterEx(vPos, vTar, vMins, vMaxs, MASK_PLAYERSOLID, TraceEntityFilter);
	hit = TR_DidHit(hndl);
	delete hndl;
	return hit;
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

bool IsCharging(int client) {
	static int ent;
	ent = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	return ent > MaxClients && GetEntProp(ent, Prop_Send, "m_isCharging");
}

bool CanCharge(int client) {
	if (GetEntPropEnt(client, Prop_Send, "m_pummelVictim") > 0 || GetEntPropEnt(client, Prop_Send, "m_carryVictim") > 0)
		return false;

	static int ent;
	ent = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	return ent > MaxClients && !GetEntProp(ent, Prop_Send, "m_isCharging") && GetEntPropFloat(ent, Prop_Send, "m_timestamp") < GetGameTime();
}

void ResetAbilityTime(int client, float time) {
	static int ent;
	ent = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (ent > MaxClients)
		SetEntPropFloat(ent, Prop_Send, "m_timestamp", GetGameTime() + time);
}

void ChargerCharge(int client) {
	int target = GetClientAimTarget(client, false); //g_iCurTarget[client];
	if (!IsAliveSur(target) || Incapacitated(target) || IsPinned(target) || entHitWall(client, target) || WithinViewAngle(client, target, g_fAimOffsetSensitivity))
		target = GetClosestSur(client, g_fChargeMaxSpeed, target);

	if (!IsAliveSur(target))
		return;

	float vVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vVel);

	float vel = GetVectorLength(vVel);
	vel = vel < g_fChargeStartSpeed ? g_fChargeStartSpeed : vel;

	float vPos[3], vTar[3];
	GetClientAbsOrigin(client, vPos);
	GetClientAbsOrigin(target, vTar);
	float height = vTar[2] - vPos[2];
	if (height >= 44.0) {
		vTar[2] += 44.0;
		vel += FloatAbs(height);
		vTar[2] += GetVectorDistance(vPos, vTar) / vel * PLAYER_HEIGHT;
	}

	if (!IsGrounded(client))
		vel += g_fChargeMaxSpeed;

	MakeVectorFromPoints(vPos, vTar, vVel);

	float vAng[3];
	GetVectorAngles(vVel, vAng);
	NormalizeVector(vVel, vVel);
	ScaleVector(vVel, vel);

	int flags = GetEntityFlags(client);
	SetEntityFlags(client, (flags & ~FL_FROZEN) & ~FL_ONGROUND);
	TeleportEntity(client, NULL_VECTOR, vAng, vVel);
	SetEntityFlags(client, flags);
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

int GetClosestSur(int client, float range, int exclude = -1) {
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

		if (GetClientTeam(clients[i]) != 2 || !IsPlayerAlive(clients[i]) || Incapacitated(clients[i]) || IsPinned(clients[i]) || entHitWall(client, clients[i]))
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
	i = al_targets.Get(index != -1 && al_targets.Get(index, 0) < 0.5 * range ? index : 0, 1);
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