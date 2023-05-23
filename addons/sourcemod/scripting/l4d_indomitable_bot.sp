#define PLUGIN_VERSION		"1.9"
#define PLUGIN_PREFIX		"l4d_"
#define PLUGIN_NAME			"indomitable_bot"
#define PLUGIN_NAME_FULL	"[L4D & L4D2] Indomitable Survivor Bot"
#define PLUGIN_DESCRIPTION	"bot is immortal than cockroach now"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?t=336751"

/**
 *	v1.0 just releases; 10-March-2022
 *	v1.1 optional regen methods 'recovery only', 're-generate'; 10-March-2022(night)
 *	v1.2 new features:
 *		optional infinity ammo methods 'infinity clip', 'infinity reserved'
 *		optional 'restrict damage resistance source'; 12-March-2022
 *	v1.3 new features:
 *		optional 'movement speed modifier',
 *		optional 'gravity multiplier',
 *		optional regen methods 'recovery but limited max' ; 1-May-2022
 *	v1.3.1 fix listener not remove when client disconnect; 1-May-2022(afternoon)
 *	v1.4 fix some damage source(like tank fist) bypass the plugin cause not works,
 *		add feature: prevents be control from charger/jockey/smoker/hunter/ledge grab, require 'Left 4 Dhooks Direct',
 *		add feature: optional temporary disable the bot indomitable abilities when human gets down,
 *		remove enabler ConVar, if you need disabled just unmount the plugin; 22-October-2022
 *
 * 	v1.4.1 a negligence cause ConVar block_control detail config not work yet; 22-October-2022(2nd time)
 * 	v1.4.2 a little negligence cause damage modifier stacks after every map changed; 25-October-2022
 * 	v1.5 if damage reducement finally less than 1 then make it be random. because 0.99 cannot cause real damage; 26-October-2022
 * 	v1.6 Fixed changing bots gravity when they are being flung, compatibility support for the "Detonation Force" plugin (update by Silvers); 10-November-2022
 * 	v1.7 Fixed compatibility issue with "Weapons Movement Speed" plugin by "Silvers" (update by Silvers); 11-November-2022
 * 	v1.8 Now optionally uses the "Lagged Movement" plugin by "Silvers" to prevent conflicts when multiple plugins try to set player speed: (update by Silvers); 12-November-2022
 * 	v1.9 new features and fixes
 * 		fix ConVar *_infinity_ammo giving ammo even bot fire failure,
 * 		*_infinity_ammo can accepts float value between -1.0 and 1.0,
 * 			0.5 mean 50% chance to give one reserved ammo,
 * 			-0.5 mean 50% chance to give one clip ammo,
 * 		*_infinity_ammo will keep chainsaw clip full, not overflow,
 * 		change code variable style to hungarian notation,
 * 		if set *_movement_rate, survivor bot will back to regular movement speed temporary when bot be controlled by special infected,
 * 		new ConVar *_infinity_throwable to allow bot infinity throwable usage, combine to use with third-party plugins. 0.5 mean half chance; 2-December-2022
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define debug 0

#define IsClientIndex(%1) (1 <= %1 <= MaxClients)
#define IsClient(%1) (IsClientIndex(%1) && IsValidEntity(%1) && IsClientInGame(%1))
#define IsBot(%1) (IsClient(%1) && IsFakeClient(%1))

#if debug
	#define IsBot(%1) (IsClient(%1))
#endif

#define IsSurvivorBot(%1) (IsBot(%1) && GetClientTeam(%1) == 2)
#define IsSurvivorHumanAlive(%1) (IsClient(%1) && !IsFakeClient(%1) && GetClientTeam(%1) == 2 && IsPlayerAlive(%1))
#define IsPlayerDown(%1) (GetEntProp(client, Prop_Send, "m_isIncapacitated") || GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))

bool g_bLaggedMovement;
native any L4D_LaggedMovement(int client, float value, bool force = false);

forward void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier);
forward void WH_OnReloadModifier(int client, int weapon, int weapontype, float &speedmodifier);
forward void WH_OnGetRateOfFire(int client, int weapon, int weapontype, float &speedmodifier);
forward void WH_OnDeployModifier(int client, int weapon, int weapontype, float &speedmodifier);
forward void WH_OnStartThrow(int client, int weapon, int weapontype, float &speedmodifier);
forward void WH_OnReadyingThrow(int client, int weapon, int weapontype, float &speedmodifier);

forward Action L4D_OnPouncedOnSurvivor(int victim, int attacker);		//hunter
forward Action L4D_OnGrabWithTongue(int victim, int attacker);			//smoker
forward Action L4D2_OnJockeyRide(int victim, int attacker);				//jockey
forward Action L4D2_OnStartCarryingVictim(int victim, int attacker);	//charger
forward void L4D_OnLedgeGrabbed_Post(int client);						//ledge grabbed
native void L4D_ReviveSurvivor(int client);

bool bIsL4D2 = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	if (GetEngineVersion() == Engine_Left4Dead2)
		bIsL4D2 = true;

	MarkNativeAsOptional("L4D_ReviveSurvivor");
	MarkNativeAsOptional("L4D_LaggedMovement");

	return APLRes_Success;
}

enum {
	Firing =			(1 << 0),
	Deploying =			(1 << 1),
	Reloading =			(1 << 2),
	MeleeSwinging =		(1 << 3),
	Throwing =			(1 << 4)
}

enum Source {
	CommonInfected =	(1 << 0),
	SpecialInfected =	(1 << 1),
	BotSurvivors =		(1 << 2),
	HumanSurvivors =	(1 << 3),
	Others =			(1 << 4)
}

enum {
	ChargerCarry =		(1 << 0),
	HunterPounce =		(1 << 1),
	SmokerTongue =		(1 << 2),
	JockeyRide =		(1 << 3),
}

ConVar cBoostActions;		int iBoostActions;
ConVar cBoostRate;			float flBoostRate;
ConVar cResDamageRate;		float flResDamageRate;
ConVar cResDamageAmount;	float flResDamageAmount;
ConVar cResDamageRegen;		int iResDamageRegen;
ConVar cInfinityAmmo;		float flInfinityAmmo;
ConVar cResDamageSources;	int iResDamageSources;
ConVar cMovementRate;		float flMovementRate;
ConVar cGravityRate;		float flGravityRate;
ConVar cBlockControl;		int iBlockControl;
ConVar cBlockLedgegrab;		float flBlockLedgegrab;
ConVar cNeedHuman;			int iNeedHuman;
ConVar cInfinityThrowable;	float flInfinityThrowable;


public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};


public void OnPluginStart() {

	CreateConVar						(PLUGIN_NAME ... "_version", PLUGIN_VERSION,	"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cBoostActions =			CreateConVar(PLUGIN_NAME ... "_boost_actions", "-1",		"which actions will be bosost on bot, add numbers together you want\n -1=All 31=All 1=firing 2=deploying 4=reloading 8=melee 16=throwing", FCVAR_NOTIFY);
	cBoostRate =			CreateConVar(PLUGIN_NAME ... "_boost_rate", "1.5",			"rate of boost weapon speed", FCVAR_NOTIFY);
	cResDamageAmount =		CreateConVar(PLUGIN_NAME ... "_res_damage_amount", "2.0",	"amount of resistance damage, calculate after res_rate multiplied 0=disable", FCVAR_NOTIFY);
	cResDamageRegen =		CreateConVar(PLUGIN_NAME ... "_res_damage_regen", "-1",		"allow regenerate health when damage resistance calculated as negative value\n0=disable -1=recovery only 1=regen and no limited 2=recovery but limited max", FCVAR_NOTIFY);
	cResDamageRate =		CreateConVar(PLUGIN_NAME ... "_res_damage_rate", "0.5",		"multiplier of resistance damage 0.1=90% resistanced 0=disable", FCVAR_NOTIFY);
	cInfinityAmmo =			CreateConVar(PLUGIN_NAME ... "_infinity_ammo", "1",			"allow infinity ammo 1=infinity clip 2=infinity reserved ammo 0=disable\n0.5=half chance to reserved ammo -0.5=half chance to clip ammo", FCVAR_NOTIFY);
	cResDamageSources =		CreateConVar(PLUGIN_NAME ... "_res_damage_sources", "2",	"which sources of receive damage will be resistance\n1=common zomobie 2=special infected 4=survivor bot 8=survivor human 16=others -1=All 31=All", FCVAR_NOTIFY);
	cMovementRate =			CreateConVar(PLUGIN_NAME ... "_movement_rate", "2.0",		"speed rate of bot movement", FCVAR_NOTIFY);
	cGravityRate =			CreateConVar(PLUGIN_NAME ... "_gravity_rate", "1.0",		"gravity rate of bot jumping and fallen", FCVAR_NOTIFY);
	cBlockControl =			CreateConVar(PLUGIN_NAME ... "_block_control", "0",		"prevent be control from: 1=charger 2=hunter 4=smoker 8=jockey -1=All 15=All\nadd numbers together you want, require 'Left 4 Dhooks Direct'", FCVAR_NOTIFY);
	cBlockLedgegrab =		CreateConVar(PLUGIN_NAME ... "_block_ledgegrab", "5.0",		"auto revive from ledge grabbed -1=dont revive 0=instantly 1.0=revive after 1.0 seconds, require 'Left 4 Dhooks Direct'", FCVAR_NOTIFY);
	cNeedHuman =			CreateConVar(PLUGIN_NAME ... "_need_human", "2",			"make bot indomitable abilities need alive human, 1=need alive 2=need stand on ground 0=do not check", FCVAR_NOTIFY);
	cInfinityThrowable =	CreateConVar(PLUGIN_NAME ... "_infinity_throwable", "0.0",	"does allow bot has infinity throwable usage,\nremember on vanilla game bot cant throw anything,\ncombine to use with third-party plugins. 0.5 mean half chance", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);
	HookEvent("weapon_fire", OnWeaponFire);

	cBoostActions.AddChangeHook(OnConVarChanged);
	cBoostRate.AddChangeHook(OnConVarChanged);
	cResDamageRate.AddChangeHook(OnConVarChanged);
	cResDamageAmount.AddChangeHook(OnConVarChanged);
	cResDamageRegen.AddChangeHook(OnConVarChanged);
	cInfinityAmmo.AddChangeHook(OnConVarChanged);
	cResDamageSources.AddChangeHook(OnConVarChanged);
	cMovementRate.AddChangeHook(OnConVarChanged);
	cGravityRate.AddChangeHook(OnConVarChanged);
	cBlockControl.AddChangeHook(OnConVarChanged);
	cBlockLedgegrab.AddChangeHook(OnConVarChanged);
	cNeedHuman.AddChangeHook(OnConVarChanged);
	cInfinityThrowable.AddChangeHook(OnConVarChanged);
	
	ApplyCvars();

	// Late load
	for( int i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) )
			OnClientPutInServer(i);
}

public void OnLibraryAdded(const char[] name)
{
	if( strcmp(name, "LaggedMovement") == 0 )
	{
		g_bLaggedMovement = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if( strcmp(name, "LaggedMovement") == 0 )
	{
		g_bLaggedMovement = false;
	}
}

void ApplyCvars() {

	iBoostActions = cBoostActions.IntValue;
	flBoostRate = cBoostRate.FloatValue;
	flResDamageRate = cResDamageRate.FloatValue;
	flResDamageAmount = cResDamageAmount.FloatValue;
	iResDamageRegen = cResDamageRegen.IntValue;
	flInfinityAmmo = cInfinityAmmo.FloatValue;
	iResDamageSources = cResDamageSources.IntValue;
	flMovementRate = cMovementRate.FloatValue;
	flGravityRate = cGravityRate.FloatValue;
	iBlockControl = cBlockControl.IntValue;
	flBlockLedgegrab = cBlockLedgegrab.FloatValue;
	iNeedHuman = cNeedHuman.IntValue;
	flInfinityThrowable = cInfinityThrowable.FloatValue;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

public void OnClientPutInServer(int client) {

	if (IsBot(client)) {
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_PreThinkPost, OnPreThinkPost);
	}
}

bool bBeControlled [MAXPLAYERS + 1];

public void OnClientDisconnect_Post(int client) {
	bBeControlled[client] = false;
}

Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype) {

	if ((flResDamageRate || flResDamageAmount) && GetClientTeam(victim) == 2 && (iResDamageSources & view_as<int>(GetEntitySource(attacker))) && checkHumanRequirement()) {

		if (flResDamageRate)
			damage *= flResDamageRate;

		if (flResDamageAmount) {

			damage -= flResDamageAmount;

			if (iResDamageRegen && damage < 0) {

				AddHealth(victim, LuckyFloat(-damage));
				damage = 0.0;
			}

			if (1 > damage > 0 && damage > GetURandomFloat()) {
				damage = 1.0;
			}
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

void OnWeaponFire(Event event, const char[] name, bool dontBroadcast) {

	int	client = GetClientOfUserId(event.GetInt("userid"));

	if ( (flInfinityAmmo || flInfinityThrowable) && IsSurvivorBot(client) ) {

		int bullets = event.GetInt("count"),
			weapon_actived = L4D_GetPlayerCurrentWeapon(client);
		
		if (bullets > 0 && weapon_actived != -1) {

			if (flInfinityAmmo == 1)

				ClipAmmoAdd(weapon_actived, 1);

			else if (flInfinityAmmo == 2)

				ReservedAmmoAdd(weapon_actived, client, 1);

			else if ( 1 > flInfinityAmmo > 0 && flInfinityAmmo > GetURandomFloat())

				ReservedAmmoAdd(weapon_actived, client, 1);

			else if ( -1 < flInfinityAmmo < 0 && -flInfinityAmmo > GetURandomFloat())

				ClipAmmoAdd(weapon_actived, 1);

		} else {

			int id_weapon = event.GetInt("weaponid");

			switch (id_weapon) {

				case 20 :  //chainsaw
					if (FloatAbs(flInfinityAmmo))
						Weapon_SetPrimaryClip(weapon_actived, 30);

				case 13, 14, 25 : { //moly, pipe, vomit

					if ( flInfinityThrowable > GetURandomFloat() && weapon_actived != -1)
						ReservedAmmoAdd(weapon_actived, client, 1);
				}
			}
		}
	}
}

Source GetEntitySource(int client) {

	if (IsClient(client)) {

		switch (GetClientTeam(client)) {

			case 2 : return IsFakeClient(client) ? BotSurvivors : HumanSurvivors;

			case 3 : return SpecialInfected;

			default : return Others;
		}

	} else if (IsValidEntity(client)) {

		static char name_class[32];
		GetEntityNetClass(client, name_class, sizeof(name_class));

		if (strcmp(name_class, "Infected") == 0)
			return CommonInfected;

		if (strcmp(name_class, "Witch") == 0)
			return SpecialInfected;
	}
	return Others;
}

void AddHealth(int client, int health) {

	int healthy = GetClientHealth(client),
		health_max = getMaxHealth(client);

	if (healthy + health > health_max) { //try overflow

		if (iResDamageRegen < 0) {

			if (healthy >= health_max) //dont change if reached max
				return;
			else // try overflow but limited to max
				SetEntityHealth(client, health_max);
		} else if (iResDamageRegen == 2) {
			SetEntityHealth(client, health_max); //limited to max even already have more
		}
	} else
		SetEntityHealth(client, healthy + health); //no limited just add
}

int LuckyFloat(float floating) {

	int floor = RoundToFloor(floating);

	int luck = (floating - floor) > GetURandomFloat();

	return floor + luck;
}

void ClipAmmoAdd(int weapon, int amount) {
	int	clip = Weapon_GetPrimaryClip(weapon);
	if (clip + amount > 0)
		Weapon_SetPrimaryClip(weapon, clip + amount);
}

void ReservedAmmoAdd(int weapon, int client, int amount) {
	int reserved = GetReservedAmmo(weapon, client);
	if (reserved + amount > 0)
		SetReservedAmmo(weapon, client, reserved + amount);
}

public void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier) {
	if (iBoostActions & MeleeSwinging && IsSurvivorBot(client))
		speedmodifier *= flBoostRate;
}

public  void WH_OnReloadModifier(int client, int weapon, int weapontype, float &speedmodifier) {
	if (iBoostActions & Reloading && IsSurvivorBot(client))
		speedmodifier *= flBoostRate;
}

public void WH_OnGetRateOfFire(int client, int weapon, int weapontype, float &speedmodifier) {
	if (iBoostActions & Firing && IsSurvivorBot(client))
		speedmodifier *= flBoostRate;
}

public void WH_OnDeployModifier(int client, int weapon, int weapontype, float &speedmodifier) {
	if (iBoostActions & Deploying && IsSurvivorBot(client))
		speedmodifier *= flBoostRate;
}

public void WH_OnReadyingThrow(int client, int weapon, int weapontype, float &speedmodifier) {
	if (iBoostActions & Throwing && IsSurvivorBot(client))
		speedmodifier *= flBoostRate;
}

public void WH_OnStartThrow(int client, int weapon, int weapontype, float &speedmodifier) {
	if (iBoostActions & Throwing && IsSurvivorBot(client))
		speedmodifier *= flBoostRate;
}

stock int getMaxHealth(int client) {

	if (HasEntProp(client, Prop_Send, "m_iMaxHealth"))
		return GetEntProp(client, Prop_Send, "m_iMaxHealth");

	return -1;
}

void OnPreThinkPost(int client) {

	if (IsSurvivorBot(client)) {

		// ==========
		// Code taken from "Weapons Movement Speed" by "Silvers"
		// ==========
		// Fix movement speed bug when jumping or staggering
		if( GetEntProp(client, Prop_Send, "m_hGroundEntity") == -1 || GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) > -1.0 )
		{
			// Fix jumping resetting velocity to default
			float value = GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
			if( value != 1.0 )
			{
				float vVec[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVec);
				float height = vVec[2];

				ScaleVector(vVec, value);
				vVec[2] = height; // Maintain default jump height

				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVec);
			}

			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_bLaggedMovement ? L4D_LaggedMovement(client, 1.0, true) : 1.0);
			return;
		}
		// ==========

		if ( bBeControlled[client] && L4D_GetPinnedInfected(client)) { // this variable for optimize

			SetEntityGravity(client, 1.0);
			SetTerrorMovement(client, 1.0);

		} else {

			bBeControlled[client] = false;

			SetEntityGravity(client, flGravityRate);
			SetTerrorMovement(client, flMovementRate);
		}
	}
}

void SetTerrorMovement(int entity, float rate) {
	SetEntPropFloat(entity, Prop_Send, "m_flLaggedMovementValue", g_bLaggedMovement ? L4D_LaggedMovement(entity, rate) : rate);
}

public Action L4D_OnPouncedOnSurvivor(int victim, int attacker) {

	if (iBlockControl & HunterPounce && IsSurvivorBot(victim))
		return Plugin_Handled;

	bBeControlled[victim] = true;
	return Plugin_Continue;
}

public Action L4D_OnGrabWithTongue(int victim, int attacker) {

	if (iBlockControl & SmokerTongue && IsSurvivorBot(victim))
		return Plugin_Handled;

	bBeControlled[victim] = true;
	return Plugin_Continue;
}

public Action L4D2_OnJockeyRide(int victim, int attacker) {

	if (iBlockControl & JockeyRide && IsSurvivorBot(victim))
		return Plugin_Handled;

	bBeControlled[victim] = true;
	return Plugin_Continue;
}

public Action L4D2_OnStartCarryingVictim(int victim, int attacker) {

	if (iBlockControl & ChargerCarry && IsSurvivorBot(victim))
		return Plugin_Handled;

	bBeControlled[victim] = true;
	return Plugin_Continue;
}

public void L4D_OnLedgeGrabbed_Post(int client) {

	if (flBlockLedgegrab >= 0 && IsSurvivorBot(client))
		CreateTimer(flBlockLedgegrab, TimerRevive, GetClientUserId(client));
}

Action TimerRevive(Handle timer, int client) {

	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) )
	{
		L4D_ReviveSurvivor(client);
	}
	return Plugin_Stop;
}


bool checkHumanRequirement() {

	if (!iNeedHuman)
		return true;

	for (int client = 1; client <= MaxClients; client++) {

		if (IsSurvivorHumanAlive(client)) {

			if (iNeedHuman == 1)

				return true;

			else if (iNeedHuman == 2)

				return !IsPlayerDown(client);
		}
	}

	return false;
}


/*Stocks below*/

stock static int ammo_offset = -1;

stock int GetReservedAmmo(int weapon, int client) {

	if (ammo_offset == -1)
		ammo_offset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

	return GetEntData( client, ammo_offset + Weapon_GetPrimaryAmmoType(weapon) * 4 );
}

stock void SetReservedAmmo(int weapon, int client, int amount) {

	if (ammo_offset == -1)
		ammo_offset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

	SetEntData( client, ammo_offset + Weapon_GetPrimaryAmmoType(weapon) * 4, amount);
}

// ==================================================
// ENTITY STOCKS (left4dhooks_stocks.inc)
// ==================================================

/**
 * @brief Returns a players current weapon, or -1 if none.
 *
 * @param client			Client ID of the player to check
 *
 * @return weapon entity index or -1 if none
 */
stock int L4D_GetPlayerCurrentWeapon(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}


// ==================================================
// PINNED CHECKS (left4dhooks_silver.inc)
// ==================================================

/**
 * @brief Returns the attacker when a Survivor is pinned by a Special Infected
 *
 * @param client			Client ID of the player to check
 *
 * @return Attacker client index, or 0 if none
 */
stock int L4D_GetPinnedInfected(int client)
{
	int attacker;

	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker")) > 0 )
		return attacker;

	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner")) > 0 )
		return attacker;

	if( bIsL4D2 )
	{
		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker")) > 0 )
			return attacker;

		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker")) > 0 )
			return attacker;

		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker")) > 0 )
			return attacker;
	}

	return 0;
}


// ==================================================
// SMLib (smlib/weapons.inc)
// ==================================================

/*
 * Gets the primary clip count of a weapon.
 * 
 * @param weapon		Weapon Entity.
 * @return				Primary Clip count.
 */
stock int Weapon_GetPrimaryClip(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iClip1");
}

/*
 * Sets the primary clip count of a weapon.
 * 
 * @param weapon		Weapon Entity.
 * @param value			Clip Count value.
 */
stock void Weapon_SetPrimaryClip(int weapon, int value)
{
	SetEntProp(weapon, Prop_Data, "m_iClip1", value);
}

/**
 * Gets the primary ammo Type (int offset)
 * 
 * @param weapon		Weapon Entity.
 * @return				Primary ammo type value.
 */
stock int Weapon_GetPrimaryAmmoType(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
}
