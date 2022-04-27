/**
 * ===============================
 * L4D2 Tank Rock Lag Compensation
 * ===============================
 * 
 * This plugin provides lag compensation as well as cvars for weapon 
 * damage & range values on tank rocks.
 * 
 * -------------------------------
 * Lag compensation for tank rocks
 * -------------------------------
 * 
 * The lag compensation is done by keeping track of the position vector history
 * of the tank rock(s) for each previous n frames (defined by MAX_HISTORY_FRAMES). 
 * When a survivor fires his weapon, the client frame is calculated by this formula:
 * 
 * Command Execution Time = Current Server Time - Packet Latency - Client View Interpolation
 *
 * Once the frame number that the client is running at is known, the plugin
 * draws an abstract sphere about the size of the rock at the origin vector
 * of the rock at client frame time. A line-sphere intersection is then calculated 
 * to detect collision. At that point, the weapon damages and ranges come into play.
 *
 * -------------
 * Weapon Damage
 * -------------
 *
 * For a given weapon damage, the damage is equal to the range at which one bullet
 * will kill the rock. For example, a damage of 200 for a gun will kill a rock
 * in one bullet at or below the range of 200 units. Damage is scaled based on
 * distance with this formula:
 *
 * Final Damage = Damage / Distance 
 *
 * ------------
 * Weapon Range
 * ------------
 *
 * The weapon range is set to prevent all damages above a certain range. For
 * example, a range of 2000 on a gun category will mean that this type of gun
 * will do no damage to the rock above 2000 units.
 *
 * -------
 * Credits
 * -------
 * 
 * Author: Luckylock
 * 
 * Contributors: Lux (Windows support)
 *
 * Testers & Feedback: Adam, Impulse, Ohzy, Presto, Elk, Noc
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define GAMEDATA "rock_lagcomp"

#define MAX_STR_LEN 100
#define MAX_HISTORY_FRAMES 100
#define ROCK_HEALTH 100
#define CURR_GAME_TIME RoundFloat(GetGameTime() * 1000)

#define ROCK_PRINT GetConVarInt(cvarRockPrint)
#define ROCK_HITBOX_ENABLED GetConVarInt(cvarRockHitbox)
#define LAG_COMP_ENABLED GetConVarInt(cvarRockTankLagComp)
#define ROCK_GODFRAMES_TIME RoundFloat(GetConVarFloat(cvarRockGodframes) * 1000)
#define ROCK_GODFRAMES_RENDER GetConVarInt(cvarRockGodframesRender)
#define SPHERE_HITBOX_RADIUS GetConVarFloat(cvarRockHitboxRadius)

#define DAMAGE_MAX_ALL_ float(10000)
#define DAMAGE_PISTOL GetConVarFloat(cvarDamagePistol)
#define DAMAGE_MAGNUM GetConVarFloat(cvarDamageMagnum)
#define DAMAGE_SHOTGUN GetConVarFloat(cvarDamageShotgun)
#define DAMAGE_SMG GetConVarFloat(cvarDamageSmg)
#define DAMAGE_RIFLE GetConVarFloat(cvarDamageRifle)
#define DAMAGE_MELEE GetConVarFloat(cvarDamageMelee)
#define DAMAGE_SNIPER GetConVarFloat(cvarDamageSniper)
#define DAMAGE_MINIGUN GetConVarFloat(cvarDamageMinigun)
#define DAMAGE_MOUNTED_MACHINEGUN GetConVarFloat(cvarDamageMountedMachineGun)

#define RANGE_MAX_ALL_ float(10000)
#define RANGE_MAX_ALL GetConVarFloat(cvarRangeMaxAll)
#define RANGE_MIN_ALL GetConVarFloat(cvarRangeMinAll)
#define RANGE_PISTOL GetConVarFloat(cvarRangePistol)
#define RANGE_MAGNUM GetConVarFloat(cvarRangeMagnum)
#define RANGE_SHOTGUN GetConVarFloat(cvarRangeShotgun)
#define RANGE_SMG GetConVarFloat(cvarRangeSmg)
#define RANGE_RIFLE GetConVarFloat(cvarRangeRifle)
#define RANGE_MELEE GetConVarFloat(cvarRangeMelee)
#define RANGE_SNIPER GetConVarFloat(cvarRangeSniper)
#define RANGE_MINIGUN GetConVarFloat(cvarRangeMinigun)
#define RANGE_MOUNTED_MACHINEGUN GetConVarFloat(cvarRangeMountedMachineGun)

#define BLOCK_ENT_REF 0
#define BLOCK_POS_HISTORY 1
#define BLOCK_DMG_DEALT 2
#define BLOCK_START_TIME 3

new ConVar:cvarRockPrint;
new ConVar:cvarRockHitbox;
new ConVar:cvarRockTankLagComp;
new ConVar:cvarRockGodframes;
new ConVar:cvarRockGodframesRender;
new ConVar:cvarRockHitboxRadius;

new ConVar:cvarDamagePistol;
new ConVar:cvarDamageMagnum;
new ConVar:cvarDamageShotgun;
new ConVar:cvarDamageSmg;
new ConVar:cvarDamageRifle;
new ConVar:cvarDamageMelee;
new ConVar:cvarDamageSniper;
new ConVar:cvarDamageMinigun;
new ConVar:cvarDamageMountedMachineGun;

new ConVar:cvarRangeMinAll;
new ConVar:cvarRangeMaxAll;
new ConVar:cvarRangePistol;
new ConVar:cvarRangeMagnum;
new ConVar:cvarRangeShotgun;
new ConVar:cvarRangeSmg;
new ConVar:cvarRangeRifle;
new ConVar:cvarRangeMelee;
new ConVar:cvarRangeSniper;
new ConVar:cvarRangeMinigun;
new ConVar:cvarRangeMountedMachineGun;

/**
 * Block BLOCK_ENT_REF: Entity Index
 * Block BLOCK_POS_HISTORY: Array of x,y,z rock positions history where: 
 * (frame number) % MAX_HISTORY_FRAMES == (array index)
 * Block BLOCK_DMG_DEAL: Damage dealt to rock
 * Block BLOCK_START_TIME: Entry time of the rock (for godframes)
 */
new ArrayList:rockEntitiesArray;

public Plugin myinfo =
{
    name = "L4D(2) Tank Rock Lag Compensation",
    author = "Luckylockm,harry,Silvers",
    description = "Provides lag compensation for tank rock entities",
    version = "1.13",
    url = "https://github.com/LuckyServ/"
};

public void OnPluginStart()
{
    cvarRockPrint = CreateConVar("sm_rock_print", "0", "Toggle printing of rock damage and range values", FCVAR_NONE, true, 0.0, true, 1.0);
    cvarRockHitbox = CreateConVar("sm_rock_hitbox", "1", "Toggle for rock custom hitbox", FCVAR_NONE, true, 0.0, true, 1.0);
    cvarRockTankLagComp = CreateConVar("sm_rock_lagcomp", "1", "Toggle for lag compensation", FCVAR_NONE, true, 0.0, true, 1.0);
    cvarRockGodframes = CreateConVar("sm_rock_godframes", "1.7", "Godframe time for rock (in seconds)", FCVAR_NONE, true, 0.0, true, 10.0);
    cvarRockGodframesRender = CreateConVar("sm_rock_godframes_render", "1", "Toggle visual godframes feedback", FCVAR_NONE, true, 0.0, true, 1.0);
    cvarRockHitboxRadius = CreateConVar("sm_rock_hitbox_radius", "30", "Rock hitbox radius", FCVAR_NONE, true, 0.0, true, 10000.0);
    
    cvarDamagePistol = CreateConVar("sm_rock_damage_pistol", "75", "Gun category damage", FCVAR_NONE, true, 0.0, true, DAMAGE_MAX_ALL_);
    cvarDamageMagnum = CreateConVar("sm_rock_damage_magnum", "1000", "Gun category damage", FCVAR_NONE, true, 0.0, true, DAMAGE_MAX_ALL_);
    cvarDamageShotgun = CreateConVar("sm_rock_damage_shotgun", "600", "Gun category damage", FCVAR_NONE, true, 0.0, true, DAMAGE_MAX_ALL_);
    cvarDamageSmg = CreateConVar("sm_rock_damage_smg", "75", "Gun category damage", FCVAR_NONE, true, 0.0, true, DAMAGE_MAX_ALL_);
    cvarDamageRifle = CreateConVar("sm_rock_damage_rifle", "200", "Gun category damage", FCVAR_NONE, true, 0.0, true, DAMAGE_MAX_ALL_);
    cvarDamageMelee = CreateConVar("sm_rock_damage_melee", "1000", "Gun category damage", FCVAR_NONE, true, 0.0, true, DAMAGE_MAX_ALL_);
    cvarDamageSniper = CreateConVar("sm_rock_damage_sniper", "10000", "Gun category damage", FCVAR_NONE, true, 0.0, true, DAMAGE_MAX_ALL_);
    cvarDamageMinigun = CreateConVar("sm_rock_damage_minigun", "300", "Gun category damage", FCVAR_NONE, true, 0.0, true, DAMAGE_MAX_ALL_);
    cvarDamageMountedMachineGun = CreateConVar("sm_rock_damage_mounted_machinegun", "10000", "Gun category damage", FCVAR_NONE, true, 0.0, true, DAMAGE_MAX_ALL_);
	
    cvarRangeMinAll = CreateConVar("sm_rock_range_min_all", "1", "Gun category range", FCVAR_NONE, true, 0.0, true, RANGE_MAX_ALL_);
    cvarRangeMaxAll = CreateConVar("sm_rock_range_max_all", "2000", "Gun category range", FCVAR_NONE, true, 0.0, true, RANGE_MAX_ALL_);
    cvarRangePistol = CreateConVar("sm_rock_range_pistol", "2000", "Gun category range", FCVAR_NONE, true, 0.0, true, RANGE_MAX_ALL_);
    cvarRangeMagnum = CreateConVar("sm_rock_range_magnum", "2000", "Gun category range", FCVAR_NONE, true, 0.0, true, RANGE_MAX_ALL_);
    cvarRangeShotgun = CreateConVar("sm_rock_range_shotgun", "1000", "Gun category range", FCVAR_NONE, true, 0.0, true, RANGE_MAX_ALL_);
    cvarRangeSmg = CreateConVar("sm_rock_range_smg", "2000", "Gun category range", FCVAR_NONE, true, 0.0, true, RANGE_MAX_ALL_);
    cvarRangeRifle = CreateConVar("sm_rock_range_rifle", "2000", "Gun category range", FCVAR_NONE, true, 0.0, true, RANGE_MAX_ALL_);
    cvarRangeMelee = CreateConVar("sm_rock_range_melee", "200", "Gun category range", FCVAR_NONE, true, 0.0, true, RANGE_MAX_ALL_);
    cvarRangeSniper = CreateConVar("sm_rock_range_sniper", "10000", "Gun category range", FCVAR_NONE, true, 0.0, true, RANGE_MAX_ALL_);
    cvarRangeMinigun = CreateConVar("sm_rock_range_minigun", "2000", "Gun category range", FCVAR_NONE, true, 0.0, true, RANGE_MAX_ALL_);
    cvarRangeMountedMachineGun = CreateConVar("sm_rock_range_mounted_machinegun", "10000", "Gun category range", FCVAR_NONE, true, 0.0, true, RANGE_MAX_ALL_);
	
    rockEntitiesArray = CreateArray(4);
    HookEvent("weapon_fire", ProcessRockHitboxes);
}

/**
 * Rock is created add it to the array to be tracked.
 */
public void OnEntityCreated(int entity, const char[] classname)
{
	new entityRef;
	
	if (IsRock(entity)) {
		entityRef = EntIndexToEntRef(entity);
		SDKHook(entityRef, SDKHook_OnTakeDamage, PreventDamage);
		SDKHook(entityRef, SDKHook_SpawnPost, SpawnPost);
		Array_AddNewRock(rockEntitiesArray, entityRef);
		
		if (ROCK_GODFRAMES_RENDER) {
			SetEntityRenderMode(entityRef, RenderMode:3);
			SetEntityRenderColor(entityRef, 255, 255, 255, 200);
		}
	}
}

// Add this below outside "OnEntityCreated" function.
void SpawnPost(int entity)
{
	if( GetEntProp(entity, Prop_Data, "m_iHammerID") == 92950 )
	{
		Array_RemoveRock(rockEntitiesArray, EntIndexToEntRef(entity));
	}
}

/*
 * Rock is destroyed, remove it from the array.
 */
public void OnEntityDestroyed(int entity)
{
	if (IsRock(entity)) {
		Array_RemoveRock(rockEntitiesArray, EntIndexToEntRef(entity));
	}
}

/*
 * Turn off all damage dealt to the rock, since we're using a custom hitbox.
 */ 
public Action PreventDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype) {
	if (ROCK_HITBOX_ENABLED) {
		damage = 0.0;
		return Plugin_Handled;
	} else {
		return Plugin_Continue;
	}
}

/*
 * Tracking origin vector of every rock for every frame (for rollback).
 */
public void OnGameFrame()
{
	new Float:pos[3];
	new rockEntity;
	new index = GetGameTickCount() % MAX_HISTORY_FRAMES; 
	
	for (int i = 0; i < rockEntitiesArray.Length; ++i) {
		rockEntity = rockEntitiesArray.Get(i, BLOCK_ENT_REF); 
		if( !rockEntity || EntRefToEntIndex(rockEntity) == INVALID_ENT_REFERENCE )
		{
			Array_RemoveRock(rockEntitiesArray, rockEntity);
			continue;
		}
		GetEntPropVector(rockEntity, Prop_Send, "m_vecOrigin", pos); 
		new ArrayList:posArray = rockEntitiesArray.Get(i, BLOCK_POS_HISTORY);
		posArray.Set(index, pos[0], 0);
		posArray.Set(index, pos[1], 1);
		posArray.Set(index, pos[2], 2);
		if (ROCK_GODFRAMES_RENDER && Array_IsRockAllowedDmg(i)) {
			SetEntityRenderMode(rockEntity, RenderMode:0);
			SetEntityRenderColor(rockEntity, 255, 255, 255, 255);
		}
	}
}

/**
 * Array Methods
 */

/**
 * Adds a new rock to the array.
 *
 * @param array array of rocks
 * @param entity entity index of the rock
 */
public void Array_AddNewRock(ArrayList array, int entity)
{
	new index = array.Push(entity);
	array.Set(index, CreateArray(3, MAX_HISTORY_FRAMES), BLOCK_POS_HISTORY);
	array.Set(index, 0, BLOCK_DMG_DEALT);
	array.Set(index, CURR_GAME_TIME, BLOCK_START_TIME);
}

/**
 * Remove a rock from the array.
 *
 * @param array array of rocks
 * @param entity entity index of the rock
 */
public void Array_RemoveRock(ArrayList array, int rockEntity)
{
	new rockIndex = Array_SearchRock(array, rockEntity);
	
	if (rockIndex >= 0) {
		new ArrayList:rockPos = array.Get(rockIndex, BLOCK_POS_HISTORY);
		rockPos.Clear();
		CloseHandle(rockPos);
		RemoveFromArray(array, rockIndex); 
	}
}

/**
 * Searches a rock in the array.
 *
 * @param array array of rocks
 * @param entity entity index to search for
 * @return array index if found, -1 if not found.
 */
public int Array_SearchRock(ArrayList array, rockEntity)
{
	for (int i = 0; i < array.Length; ++i) {
		new cRockEntity = array.Get(i, BLOCK_ENT_REF);
		if (rockEntity == cRockEntity) {
			return i;
		} 
	}
	
	return -1;
}

/*
 * Checks if rock is allowed to be dealt damage.
 */
public bool Array_IsRockAllowedDmg(rockIndex)
{
	return CURR_GAME_TIME - rockEntitiesArray.Get(rockIndex, BLOCK_START_TIME) >= ROCK_GODFRAMES_TIME;
}

/**
 * Ray Methods
 */

/*
 * Handles the weapon_fire event. Calculates a line-sphere intersection between
 * the shooting survivors and the rock(s). Deals damages accordingly.
 */
public Action ProcessRockHitboxes(Event event, const char[] name, 
		bool dontBroadcast)
{
	if (rockEntitiesArray.Length == 0) {
		return Plugin_Handled;
	}
	
	new client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!IsSurvivor(client)) {
		return Plugin_Handled;
	}
	
	new Float:eyeAng[3];
	new Float:eyePos[3];
	
	// Rollback rock position
	new String:buffer[MAX_STR_LEN];
	GetClientInfo(client, "cl_interp", buffer, MAX_STR_LEN);
	new Float:clientLerp = Clamp(StringToFloat(buffer), 0.0, 0.5);
	new Float:lagTime = !IsFakeClient(client) ? GetClientLatency(client, NetFlow_Both) + clientLerp : 0.0;
	new rollBackTick = LAG_COMP_ENABLED ? 
	GetGameTickCount() - RoundToNearest(lagTime / GetTickInterval()) : GetGameTickCount();
	
	GetClientEyeAngles(client, eyeAng);
	GetClientEyePosition(client, eyePos);
	
	// Abstract sphere hitbox implementation
	// https://en.wikipedia.org/wiki/Line%E2%80%93sphere_intersection
	
	// Get unit vector l
	new Float:l[3];
	GetAngleVectors(eyeAng, l, NULL_VECTOR, NULL_VECTOR);
	
	// Get origin of line o
	new Float:o[3];
	o[0] = eyePos[0];
	o[1] = eyePos[1];
	o[2] = eyePos[2];
	new Float:o_Minus_c[3];
	
	// Sphere vectors
	new Float:radius = SPHERE_HITBOX_RADIUS;
	new Float:c[3];
	
	new ArrayList:rockPositionsArray;
	new entity;
	new index = rollBackTick % MAX_HISTORY_FRAMES;
	new Float:delta;
	
	//PrintToChatAll("%d - %d = %d", GetGameTickCount(), rollBackTick, GetGameTickCount() - rollBackTick);
	
	for (int i = 0; i < rockEntitiesArray.Length; ++i) {
		
		if (Array_IsRockAllowedDmg(i)) {
			entity = rockEntitiesArray.Get(i, BLOCK_ENT_REF); 
			rockPositionsArray = rockEntitiesArray.Get(i, BLOCK_POS_HISTORY);
			
			c[0] = rockPositionsArray.Get(index, 0);
			c[1] = rockPositionsArray.Get(index, 1);
			c[2] = rockPositionsArray.Get(index, 2);
			SubtractVectors(o,c,o_Minus_c);
			
			delta = GetVectorDotProduct(l, o_Minus_c) * GetVectorDotProduct(l, o_Minus_c) 
			- GetVectorLength(o_Minus_c, true) + radius*radius;
			
			if (delta >= 0.0) {
				ApplyDamageOnRock(i, client, eyePos, c, event, entity);
			}
		}
	}
	
	return Plugin_Handled;
}

/*
 * Apply damage on rock depending on weapon and distance.
 */
public void ApplyDamageOnRock(rockIndex, client, float eyePos[3], float c[3], Event event,
		rockEntity)
{
	new String:weaponName[MAX_STR_LEN]; 
	event.GetString("weapon", weaponName, MAX_STR_LEN);
	new Float:range = GetVectorDistance(eyePos, c);
	
	if (ROCK_PRINT) {
		PrintToChatAll("Weapon: %s | Range: %.2f", weaponName, range);
	}
	
	if ((!ROCK_HITBOX_ENABLED) || range > RANGE_MAX_ALL || (range < RANGE_MIN_ALL && !IsMelee(weaponName))) {
		return;
		
	} else if (IsSmg(weaponName)) {
		if (range > RANGE_SMG) return;
		ApplyBulletToRock(rockIndex, rockEntity, DAMAGE_SMG, range);
		
	} else if (IsPistol(weaponName)) {
		if (range > RANGE_PISTOL) return;
		ApplyBulletToRock(rockIndex, rockEntity, DAMAGE_PISTOL, range);
		
	} else if (IsMagnum(weaponName)) {
		if (range > RANGE_MAGNUM) return;
		ApplyBulletToRock(rockIndex, rockEntity, DAMAGE_MAGNUM, range);
		
	} else if (IsShotgun(weaponName)) {
		if (range > RANGE_SHOTGUN) return;
		ApplyBulletToRock(rockIndex, rockEntity, DAMAGE_SHOTGUN, range);
		
	} else if (IsRifle(weaponName)) {
		if (range > RANGE_RIFLE) return;
		ApplyBulletToRock(rockIndex, rockEntity, DAMAGE_RIFLE, range);
		
	} else if (IsMelee(weaponName)) {
		if (range > RANGE_MELEE) return;
		ApplyBulletToRock(rockIndex, rockEntity, DAMAGE_MELEE, range);
		
	} else if (IsSniper(weaponName)) {
		if (range > RANGE_SNIPER) return;
		ApplyBulletToRock(rockIndex, rockEntity, DAMAGE_SNIPER, range);
		
	} else if (IsMiniGun(weaponName)) {
		if (range > RANGE_MINIGUN) return;
		ApplyBulletToRock(rockIndex, rockEntity, DAMAGE_MINIGUN, range);
		
	} else if (IsMountedMachineGun(weaponName)){
		if (range > RANGE_MOUNTED_MACHINEGUN) return;
		ApplyBulletToRock(rockIndex, rockEntity, DAMAGE_MOUNTED_MACHINEGUN, range);
    }
}

/*
 * Applies a single bullet damage to a single rock.
 */
public void ApplyBulletToRock(rockIndex, rockEntity, float damage, float range)
{
	new Float:rockDamage = float(rockEntitiesArray.Get(rockIndex, BLOCK_DMG_DEALT));
	rockDamage += damage / range * 100;
	
	if (RoundFloat(rockDamage) > ROCK_HEALTH) {
		RequestFrame(CTankRock__Detonate, rockEntity);
	} else {
		rockEntitiesArray.Set(rockIndex, RoundFloat(rockDamage), BLOCK_DMG_DEALT);
	}
	
	if (ROCK_PRINT) {
		PrintToChatAll("Rock health: %d\%", RoundFloat(ROCK_HEALTH - rockDamage));
	}
}

public bool IsPistol(const char[] weaponName)
{
	return StrEqual(weaponName, "pistol");
}

public bool IsMagnum(const char[] weaponName)
{
	return StrEqual("pistol_magnum", weaponName);
}

public bool IsShotgun(const char[] weaponName)
{
	return StrEqual(weaponName, "shotgun_chrome")
		|| StrEqual(weaponName, "shotgun_spas")
		|| StrEqual(weaponName, "autoshotgun")
		|| StrEqual(weaponName, "pumpshotgun");
}

public bool IsSmg(const char[] weaponName)
{
	return StrEqual(weaponName, "smg")
		|| StrEqual(weaponName, "smg_silenced")
		|| StrEqual(weaponName, "smg_mp5");
}

public bool IsRifle(const char[] weaponName)
{
	return StrEqual(weaponName, "rifle")
		|| StrEqual(weaponName, "rifle_ak47")
		|| StrEqual(weaponName, "rifle_desert")
		|| StrEqual(weaponName, "rifle_m60")
		|| StrEqual(weaponName, "rifle_sg552");
}

public bool IsMelee(const char[] weaponName)
{
	return StrEqual(weaponName, "chainsaw")
		|| StrEqual(weaponName, "melee");
}

public bool IsSniper(const char[] weaponName)
{
	return StrEqual(weaponName, "sniper_awp")
		|| StrEqual(weaponName, "sniper_military")
		|| StrEqual(weaponName, "sniper_scout")
		|| StrEqual(weaponName, "hunting_rifle");
}

public bool IsMiniGun(const char[] weaponName)
{
	return StrEqual(weaponName, "prop_minigun_l4d1")
		|| StrEqual(weaponName, "prop_minigun");
	
}

public bool IsMountedMachineGun(const char[] weaponName)
{
    return StrEqual(weaponName, "prop_mounted_machine_gun");
}

/**
 * Print Methods
 */

public void PrintEntityLocation(int entity)
{
	if (IsValidEntity(entity)) {
		new String:classname[MAX_STR_LEN];
		new Float:position[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
		GetEntityClassname(entity, classname, MAX_STR_LEN);
		PrintToChatAll("Entity %s (%d) is at location: (%.2f, %.2f, %.2f)",
				classname, entity, position[0], position[1], position[2]);
	}
}

public bool IsRock(int entity)
{
	if (IsValidEntity(entity)) {
		new String:classname[MAX_STR_LEN];
		GetEntityClassname(entity, classname, MAX_STR_LEN);
		return StrEqual(classname, "tank_rock");
	}
	return false;
}

// Credits to Visor
CTankRock__Detonate(rock)
{
	static Handle:call = INVALID_HANDLE;
	
	if (call == INVALID_HANDLE) {
		StartPrepSDKCall(SDKCall_Entity);
		
		new Handle:hGamedata = LoadGameConfigFile(GAMEDATA);
		if(hGamedata == INVALID_HANDLE) 
			SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
		
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTankRock::Detonate");
		
		/*if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN9CTankRock8DetonateEv", 0)) {
			return;
		}*/
		
		call = EndPrepSDKCall();
		delete hGamedata;
		
		if (call == INVALID_HANDLE) {
			return;
		}
	}
	SDKCall(call, rock);
}

/**
 * Vector functions
 */

public void Vector_Print(float v[3])
{
	PrintToChatAll("(%.2f, %.2f, %.2f)", v[0],v[1],v[2]);
}

/**
 * Stocks
 */

bool:IsSurvivor(client)														 
{																			   
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

public float Clamp(float value, float valueMin, float valueMax)
{
	if (value < valueMin) {
		return valueMin;
	} else if (value > valueMax) {
		return valueMax;
	} else {
		return value;
	}
}
