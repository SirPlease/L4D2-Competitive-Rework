/**
 * L4D2 Tank Rock Lag Compensation
 *
 * Keeps a short server-side position history for tank rocks and tests survivor
 * weapon_fire rays against the position the shooter saw. Weapon damage/range
 * are read from the current Left4DHooks weapon attributes.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define MAX_WEAPON_NAME 64
#define MAX_HISTORY_FRAMES 100
#define ROCK_HEALTH 100.0

#define BLOCK_ENT_REF 0
#define BLOCK_POS_HISTORY 1
#define BLOCK_DMG_DEALT 2
#define BLOCK_SPAWN_TIME 3
#define BLOCK_RELEASED 4
#define BLOCK_DETONATING 5
#define BLOCK_COUNT 6

ConVar g_cvRockPrint;
ConVar g_cvRockHitbox;
ConVar g_cvRockLagComp;
ConVar g_cvRockGodframes;
ConVar g_cvRockGodframesRender;
ConVar g_cvRockHitboxRadius;
ConVar g_cvRangeMinAll;
ConVar g_cvRangeMaxAll;

ArrayList g_aRockEntities;

public Plugin myinfo =
{
	name = "L4D(2) Tank Rock Lag Compensation",
	author = "Luckylockm, harry, Silvers, AnneHappy",
	description = "Provides lag compensation and weapon-attribute damage handling for tank rocks",
	version = "2.0-anne",
	url = "https://github.com/LuckyServ/"
};

public void OnPluginStart()
{
	LoadTranslations("l4d_rock_lagcomp.phrases");
	g_cvRockPrint = CreateConVar("sm_rock_print", "0", "Toggle printing of rock damage and range values", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvRockHitbox = CreateConVar("sm_rock_hitbox", "1", "Toggle custom rock hitbox and damage handling", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvRockLagComp = CreateConVar("sm_rock_lagcomp", "1", "Toggle lag compensation for hitscan rock shots", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvRockGodframes = CreateConVar("sm_rock_godframes", "1.7", "Fallback protection seconds if tank rock release is not seen; release always ends protection immediately", FCVAR_NONE, true, 0.0, true, 10.0);
	g_cvRockGodframesRender = CreateConVar("sm_rock_godframes_render", "1", "Toggle visual feedback while a rock is protected before release", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvRockHitboxRadius = CreateConVar("sm_rock_hitbox_radius", "30", "Custom rock hitbox radius", FCVAR_NONE, true, 0.0, true, 10000.0);
	g_cvRangeMinAll = CreateConVar("sm_rock_range_min_all", "1", "Global minimum distance for hitscan rock damage", FCVAR_NONE, true, 0.0, true, 10000.0);
	g_cvRangeMaxAll = CreateConVar("sm_rock_range_max_all", "2000", "Global maximum distance for rock damage; 0 disables this cap", FCVAR_NONE, true, 0.0, true, 10000.0);

	g_aRockEntities = new ArrayList(BLOCK_COUNT);

	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
}

public void OnMapStart()
{
	ClearTrackedRocks();
}

public void OnPluginEnd()
{
	ClearTrackedRocks();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!StrEqual(classname, "tank_rock")) {
		return;
	}

	int rockRef = EntIndexToEntRef(entity);
	SDKHook(entity, SDKHook_OnTakeDamage, OnRockTakeDamage);
	SDKHook(entity, SDKHook_SpawnPost, OnRockSpawnPost);
	AddTrackedRock(rockRef);

	UpdateRockRenderByRef(rockRef);
}

public void OnRockSpawnPost(int entity)
{
	if (!IsValidEntity(entity)) {
		return;
	}

	if (GetEntProp(entity, Prop_Data, "m_iHammerID") == 92950) {
		RemoveTrackedRock(EntIndexToEntRef(entity));
	}
}

public void OnEntityDestroyed(int entity)
{
	if (IsRock(entity)) {
		RemoveTrackedRock(EntIndexToEntRef(entity));
	}
}

public void L4D_TankRock_OnRelease_Post(int tank, int rock, const float vecPos[3], const float vecAng[3], const float vecVel[3], const float vecRot[3])
{
	if (rock <= MaxClients || !IsValidEntity(rock)) {
		return;
	}

	int rockRef = EntIndexToEntRef(rock);
	int rockIndex = FindTrackedRock(rockRef);

	if (rockIndex == -1) {
		SDKHook(rock, SDKHook_OnTakeDamage, OnRockTakeDamage);
		AddTrackedRock(rockRef);
		rockIndex = FindTrackedRock(rockRef);
	}

	if (rockIndex == -1) {
		return;
	}

	g_aRockEntities.Set(rockIndex, 1, BLOCK_RELEASED);
	SeedRockHistory(rockIndex, vecPos);
	UpdateRockRender(rockIndex);
}

public void OnGameFrame()
{
	if (g_aRockEntities == null || g_aRockEntities.Length == 0) {
		return;
	}

	float pos[3];
	int historyIndex = GetHistoryIndex(GetGameTickCount());

	for (int i = g_aRockEntities.Length - 1; i >= 0; i--) {
		int rockRef = g_aRockEntities.Get(i, BLOCK_ENT_REF);
		int entity = EntRefToEntIndex(rockRef);

		if (entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity)) {
			RemoveTrackedRockByIndex(i);
			continue;
		}

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);

		ArrayList posHistory = view_as<ArrayList>(g_aRockEntities.Get(i, BLOCK_POS_HISTORY));
		posHistory.SetArray(historyIndex, pos, sizeof(pos));

		UpdateRockRender(i);
	}
}

public Action OnRockTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!g_cvRockHitbox.BoolValue) {
		return Plugin_Continue;
	}

	float incomingDamage = damage;
	damage = 0.0;

	if (!IsSurvivor(attacker)) {
		return Plugin_Handled;
	}

	int rockIndex = FindTrackedRock(EntIndexToEntRef(victim));
	if (rockIndex == -1 || !IsRockDamageAllowed(rockIndex)) {
		return Plugin_Handled;
	}

	char weaponName[MAX_WEAPON_NAME];
	if (!GetNativeDamageWeaponName(attacker, inflictor, weaponName, sizeof(weaponName))) {
		return Plugin_Handled;
	}

	if (IsHitscanWeaponName(weaponName) || incomingDamage <= 0.0) {
		return Plugin_Handled;
	}


	float eyePos[3];
	float rockPos[3];
	GetClientEyePosition(attacker, eyePos);
	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", rockPos);

	ApplyDamageToRock(rockIndex, EntIndexToEntRef(victim), weaponName, incomingDamage, 0.0, 1.0, GetVectorDistance(eyePos, rockPos), true);
	return Plugin_Handled;
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvRockHitbox.BoolValue || g_aRockEntities.Length == 0) {
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(client)) {
		return Plugin_Continue;
	}

	char weaponName[MAX_WEAPON_NAME];
	event.GetString("weapon", weaponName, sizeof(weaponName));
	NormalizeWeaponName(weaponName, weaponName, sizeof(weaponName));

	float weaponDamage;
	float weaponRange;
	float weaponRangeModifier;
	if (!GetHitscanWeaponAttributes(weaponName, weaponDamage, weaponRange, weaponRangeModifier)) {
		return Plugin_Continue;
	}

	float eyeAng[3];
	float eyePos[3];
	float direction[3];

	GetClientEyeAngles(client, eyeAng);
	GetClientEyePosition(client, eyePos);
	GetAngleVectors(eyeAng, direction, NULL_VECTOR, NULL_VECTOR);

	float clientLerp = GetClientInterp(client);
	float lagTime = IsFakeClient(client) ? 0.0 : GetClientLatency(client, NetFlow_Both) + clientLerp;
	int rollbackTick = g_cvRockLagComp.BoolValue ? GetGameTickCount() - RoundToNearest(lagTime / GetTickInterval()) : GetGameTickCount();
	int historyIndex = GetHistoryIndex(rollbackTick);

	for (int i = g_aRockEntities.Length - 1; i >= 0; i--) {
		int rockRef = g_aRockEntities.Get(i, BLOCK_ENT_REF);
		int entity = EntRefToEntIndex(rockRef);

		if (entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity)) {
			RemoveTrackedRockByIndex(i);
			continue;
		}

		if (!IsRockDamageAllowed(i)) {
			continue;
		}

		float center[3];
		ArrayList posHistory = view_as<ArrayList>(g_aRockEntities.Get(i, BLOCK_POS_HISTORY));
		posHistory.GetArray(historyIndex, center, sizeof(center));

		if (RayIntersectsSphere(eyePos, direction, center, g_cvRockHitboxRadius.FloatValue)) {
			ApplyDamageToRock(i, rockRef, weaponName, weaponDamage, weaponRange, weaponRangeModifier, GetVectorDistance(eyePos, center), false);
		}
	}

	return Plugin_Continue;
}

void NormalizeWeaponName(const char[] input, char[] output, int maxlen)
{
	char weaponName[MAX_WEAPON_NAME];
	strcopy(weaponName, sizeof(weaponName), input);
	TrimString(weaponName);
	StripQuotes(weaponName);
	StringToLowerCase(weaponName);

	if (strncmp(weaponName, "weapon_", 7, false) == 0) {
		strcopy(weaponName, sizeof(weaponName), weaponName[7]);
	}

	strcopy(output, maxlen, weaponName);
}

bool GetNativeDamageWeaponName(int attacker, int inflictor, char[] weaponName, int maxlen)
{
	char classname[MAX_WEAPON_NAME];

	if (inflictor > MaxClients && IsValidEntity(inflictor) && GetEntityClassname(inflictor, classname, sizeof(classname))) {
		NormalizeWeaponName(classname, weaponName, maxlen);
		if (IsMountedGunWeaponName(weaponName)) {
			return true;
		}
	}

	int activeWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if (activeWeapon > MaxClients && IsValidEntity(activeWeapon) && GetEntityClassname(activeWeapon, classname, sizeof(classname))) {
		NormalizeWeaponName(classname, weaponName, maxlen);
		return weaponName[0] != '\0';
	}

	return false;
}

bool GetHitscanWeaponAttributes(const char[] weaponName, float &damage, float &range, float &rangeModifier)
{
	char normalized[MAX_WEAPON_NAME];
	NormalizeWeaponName(weaponName, normalized, sizeof(normalized));

	if (!IsWeaponAttributeReadable(normalized)) {
		return false;
	}

	int weaponType = L4D2_GetIntWeaponAttribute(normalized, L4D2IWA_WeaponType);
	if (!IsHitscanWeaponType(weaponType)) {
		return false;
	}

	int baseDamage = L4D2_GetIntWeaponAttribute(normalized, L4D2IWA_Damage);
	if (baseDamage <= 0) {
		return false;
	}

	int bullets = L4D2_GetIntWeaponAttribute(normalized, L4D2IWA_Bullets);
	if (bullets < 1) {
		bullets = 1;
	}

	damage = float(baseDamage * bullets);
	range = L4D2_GetFloatWeaponAttribute(normalized, L4D2FWA_Range);
	rangeModifier = L4D2_GetFloatWeaponAttribute(normalized, L4D2FWA_RangeModifier);
	return range > 0.0;
}

bool IsHitscanWeaponName(const char[] weaponName)
{
	char normalized[MAX_WEAPON_NAME];
	NormalizeWeaponName(weaponName, normalized, sizeof(normalized));

	if (!IsWeaponAttributeReadable(normalized)) {
		return false;
	}

	return IsHitscanWeaponType(L4D2_GetIntWeaponAttribute(normalized, L4D2IWA_WeaponType));
}

bool IsWeaponAttributeReadable(const char[] weaponName)
{
	return weaponName[0] != '\0' && L4D_GetWeaponID(weaponName) != -1 && L4D2_IsValidWeapon(weaponName);
}

bool IsHitscanWeaponType(int weaponType)
{
	return weaponType == view_as<int>(WEAPONTYPE_PISTOL)
		|| weaponType == view_as<int>(WEAPONTYPE_SMG)
		|| weaponType == view_as<int>(WEAPONTYPE_RIFLE)
		|| weaponType == view_as<int>(WEAPONTYPE_SHOTGUN)
		|| weaponType == view_as<int>(WEAPONTYPE_SNIPERRIFLE)
		|| weaponType == view_as<int>(WEAPONTYPE_MACHINEGUN);
}

bool IsMountedGunWeaponName(const char[] weaponName)
{
	return StrEqual(weaponName, "prop_minigun")
		|| StrEqual(weaponName, "prop_minigun_l4d1")
		|| StrEqual(weaponName, "prop_mounted_machine_gun");
}

float GetClientInterp(int client)
{
	char buffer[32];
	GetClientInfo(client, "cl_interp", buffer, sizeof(buffer));
	return Clamp(StringToFloat(buffer), 0.0, 0.5);
}

bool RayIntersectsSphere(const float origin[3], const float direction[3], const float center[3], float radius)
{
	float originMinusCenter[3];
	SubtractVectors(origin, center, originMinusCenter);

	float dot = GetVectorDotProduct(direction, originMinusCenter);
	float delta = dot * dot - GetVectorLength(originMinusCenter, true) + radius * radius;
	if (delta < 0.0) {
		return false;
	}

	float firstHit = -dot - SquareRoot(delta);
	float secondHit = -dot + SquareRoot(delta);
	return firstHit >= 0.0 || secondHit >= 0.0;
}

void ApplyDamageToRock(int rockIndex, int rockRef, const char[] weaponName, float weaponDamage, float weaponRange, float weaponRangeModifier, float distance, bool nativeDamage)
{
	if (rockIndex < 0 || rockIndex >= g_aRockEntities.Length || g_aRockEntities.Get(rockIndex, BLOCK_DETONATING)) {
		return;
	}

	if (distance <= 0.0) {
		distance = 1.0;
	}

	if (weaponDamage <= 0.0 || !IsDistanceAllowed(distance, weaponRange, nativeDamage)) {
		return;
	}

	float appliedDamage = weaponDamage;
	if (!nativeDamage && weaponRangeModifier > 0.0 && weaponRangeModifier < 1.0) {
		appliedDamage *= Pow(weaponRangeModifier, distance / 500.0);
	}

	float rockDamage = g_aRockEntities.Get(rockIndex, BLOCK_DMG_DEALT);
	rockDamage += appliedDamage;

	if (g_cvRockPrint.BoolValue) {
		PrintToChatAll("%t", "L4DRockLagcomp_WeaponRangeDamageRockHealth", weaponName, distance, appliedDamage, FloatMax(0.0, ROCK_HEALTH - rockDamage));
	}

	if (rockDamage >= ROCK_HEALTH) {
		g_aRockEntities.Set(rockIndex, 1, BLOCK_DETONATING);
		RequestFrame(Frame_DetonateRock, rockRef);
		return;
	}

	g_aRockEntities.Set(rockIndex, rockDamage, BLOCK_DMG_DEALT);
}

bool IsDistanceAllowed(float distance, float weaponRange, bool nativeDamage)
{
	float maxRange = g_cvRangeMaxAll.FloatValue;
	if (maxRange > 0.0 && distance > maxRange) {
		return false;
	}

	if (!nativeDamage && distance < g_cvRangeMinAll.FloatValue) {
		return false;
	}

	return weaponRange <= 0.0 || distance <= weaponRange;
}

void Frame_DetonateRock(any data)
{
	int entity = EntRefToEntIndex(data);
	if (entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity)) {
		return;
	}

	L4D_DetonateProjectile(entity);
}

void AddTrackedRock(int rockRef)
{
	if (FindTrackedRock(rockRef) != -1) {
		return;
	}

	int index = g_aRockEntities.Push(rockRef);
	ArrayList posHistory = new ArrayList(3, MAX_HISTORY_FRAMES);
	g_aRockEntities.Set(index, posHistory, BLOCK_POS_HISTORY);
	g_aRockEntities.Set(index, 0.0, BLOCK_DMG_DEALT);
	g_aRockEntities.Set(index, GetGameTime(), BLOCK_SPAWN_TIME);
	g_aRockEntities.Set(index, 0, BLOCK_RELEASED);
	g_aRockEntities.Set(index, 0, BLOCK_DETONATING);

	float pos[3];
	int entity = EntRefToEntIndex(rockRef);
	if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity)) {
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	}

	SeedRockHistory(index, pos);
}

void RemoveTrackedRock(int rockRef)
{
	int rockIndex = FindTrackedRock(rockRef);
	if (rockIndex != -1) {
		RemoveTrackedRockByIndex(rockIndex);
	}
}

void RemoveTrackedRockByIndex(int index)
{
	ArrayList posHistory = view_as<ArrayList>(g_aRockEntities.Get(index, BLOCK_POS_HISTORY));
	delete posHistory;
	g_aRockEntities.Erase(index);
}

void ClearTrackedRocks()
{
	if (g_aRockEntities == null) {
		return;
	}

	for (int i = g_aRockEntities.Length - 1; i >= 0; i--) {
		RemoveTrackedRockByIndex(i);
	}
}

int FindTrackedRock(int rockRef)
{
	for (int i = 0; i < g_aRockEntities.Length; i++) {
		if (g_aRockEntities.Get(i, BLOCK_ENT_REF) == rockRef) {
			return i;
		}
	}

	return -1;
}

void SeedRockHistory(int rockIndex, const float pos[3])
{
	ArrayList posHistory = view_as<ArrayList>(g_aRockEntities.Get(rockIndex, BLOCK_POS_HISTORY));
	for (int i = 0; i < MAX_HISTORY_FRAMES; i++) {
		posHistory.SetArray(i, pos, 3);
	}
}

bool IsRockDamageAllowed(int rockIndex)
{
	if (g_aRockEntities.Get(rockIndex, BLOCK_RELEASED) != 0) {
		return true;
	}

	float fallbackTime = g_cvRockGodframes.FloatValue;
	if (fallbackTime <= 0.0) {
		return true;
	}

	return GetGameTime() - g_aRockEntities.Get(rockIndex, BLOCK_SPAWN_TIME) >= fallbackTime;
}

void UpdateRockRenderByRef(int rockRef)
{
	int rockIndex = FindTrackedRock(rockRef);
	if (rockIndex != -1) {
		UpdateRockRender(rockIndex);
	}
}

void UpdateRockRender(int rockIndex)
{
	int rockRef = g_aRockEntities.Get(rockIndex, BLOCK_ENT_REF);
	int entity = EntRefToEntIndex(rockRef);

	if (entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity)) {
		return;
	}

	if (g_cvRockGodframesRender.BoolValue && !IsRockDamageAllowed(rockIndex)) {
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 255, 255, 255, 200);
		return;
	}

	SetEntityRenderMode(entity, RENDER_NORMAL);
	SetEntityRenderColor(entity, 255, 255, 255, 255);
}

int GetHistoryIndex(int tick)
{
	int index = tick % MAX_HISTORY_FRAMES;
	return index < 0 ? index + MAX_HISTORY_FRAMES : index;
}

bool IsRock(int entity)
{
	if (entity <= MaxClients || !IsValidEntity(entity)) {
		return false;
	}

	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	return StrEqual(classname, "tank_rock");
}

bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

void StringToLowerCase(char[] text)
{
	int length = strlen(text);
	for (int i = 0; i < length; i++) {
		text[i] = CharToLower(text[i]);
	}
}

float Clamp(float value, float valueMin, float valueMax)
{
	if (value < valueMin) {
		return valueMin;
	}

	if (value > valueMax) {
		return valueMax;
	}

	return value;
}

float FloatMax(float a, float b)
{
	return a > b ? a : b;
}
