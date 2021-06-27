#pragma semicolon 1
#pragma newdecls required;

#include <sourcemod>
#include <sdktools>
#include <sdkhooks> //add define DMG_BURN

#define Z_TANK 8
#define TEAM_INFECTED 3

ConVar
	infected_fire_immunity,
	tank_fire_immunity,
	infected_extinguish_time,
	tank_extinguish_time;

float
	fWaitTime[MAXPLAYERS + 1] = {0.0, ...};

public Plugin myinfo = 
{
	name = "SI Fire Immunity",
	author = "Jacob, darkid, A1m`",
	description = "Special Infected fire damage management.",
	version = "3.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	infected_fire_immunity = CreateConVar("infected_fire_immunity", 
	"3", 
	"What type of fire immunity should infected have? 0 = None, 3 = Extinguish burns, 2 = Prevent burns, 1 = Complete immunity", 
	_, true, 0.0, true, 3.0);
	
	tank_fire_immunity = CreateConVar("tank_fire_immunity", 
	"2", 
	"What type of fire immunity should the tank have? 0 = None, 3 = Extinguish burns, 2 = Prevent burns, 1 = Complete immunity", 
	_, true, 0.0, true, 3.0);
	
	infected_extinguish_time = CreateConVar("infected_extinguish_time", 
	"1.0", 
	"After what time will the infected player be extinguished, works if cvar 'infected_fire_immunity' equal 3", 
	_, true, 0.0, true, 999.0);
	
	tank_extinguish_time = CreateConVar("tank_extinguish_time", 
	"1.0", 
	"After what time will the tanl player be extinguished, works if cvar 'tank_fire_immunity' equal 3", 
	_, true, 0.0, true, 999.0);
	
	HookEvent("player_hurt", SIOnFire, EventHookMode_Post);
	HookEvent("round_start", view_as<EventHook>(EventReset), EventHookMode_PostNoCopy);
	HookEvent("round_end", view_as<EventHook>(EventReset), EventHookMode_PostNoCopy);
}

/* @A1m`:
 * This is necessary because each round starts from 0.0.
*/
public void EventReset()
{
	for (int i = 0; i <= MAXPLAYERS; i++) {
		fWaitTime[i] = 0.0;
	}
}

/* @A1m`:
 * "player_hurt"
 * {
 * 		"local"		"1"			// Not networked
 * 		"userid"	"short"   	// user ID who was hurt
 * 		"attacker"	"short"	 	// user id who attacked
 * 		"attackerentid"	"long"	// entity id who attacked, if attacker not a player, and userid therefore invalid
 * 		"health"	"short"		// remaining health points
 * 		"armor"		"byte"		// remaining armor points
 * 		"weapon"	"string"	// weapon name attacker used, if not the world
 * 		"dmg_health"	"short"	// damage done to health
 * 		"dmg_armor"	"byte"		// damage done to armor
 * 		"hitgroup"	"byte"		// hitgroup that was damaged
 * 		"type"		"long"		// damage type
 * }
 * char weapon[64];
 * hEvent.GetString("weapon", weapon, sizeof(weapon));
 *
 * This returns an empty string, and this plugin calls the function every time if attacker == 0
 * The new method described here will work much better
 *
 * Incendiary ammo:
 * SIOnFire: Hunter, attacker: 2 (entityclassname player), attackerentid: 1 (entityclassname player)
 * Event string weapon: entityflame, type: 268435464 
 *
 * Static fire on the map:
 * SIOnFire: A1m`, attacker: 0 (entityclassname entityflame), attackerentid: 277 (entityclassname entityflame)
 * Event string weapon: , type: 268435464 //weapon empty =/
 *
 * Molotov:
 * SIOnFire: Tank, attacker: 2 (entityclassname player), attackerentid: 1 (entityclassname player)
 * weapon: inferno, type: 8
 * SIOnFire: Tank, attacker: 2 (entityclassname player), attackerentid: 1 (entityclassname player)
 * Event string weapon: entityflame, type: 268435464
 *
 * Сanister:
 * SIOnFire: Tank, attacker: 2 (entityclassname player), attackerentid: 1 (entityclassname player)
 * Event string weapon: entityflame, type: 268435464
 *
 * Fireworks:
 * SIOnFire: A1m`, attacker: 2 (entityclassname player), attackerentid: 0 (entityclassname player)
 * Event string weapon: fire_cracker_blast, type: 8 //fire_cracker_blast need check?
 * SIOnFire: A1m`, attacker: 2 (entityclassname player), attackerentid: 0 (entityclassname player)
 * Event string weapon: entityflame, type: 268435464
 *
*/
public void SIOnFire(Event hEvent, const char[] eName, bool dontBroadcast)
{
	/*
	 * This event 'player_hurt' is called very often
	 */
	int type = hEvent.GetInt("type");
	if (!(type & DMG_BURN)) { //more performance
		return;
	}

	char sEntityName[32];
	int attackerentid = hEvent.GetInt("attackerentid");
	if (attackerentid > MaxClients) { //The entity should not have a weapon =)
		GetEntityClassname(attackerentid, sEntityName, sizeof(sEntityName));
	} else {
		hEvent.GetString("weapon", sEntityName, sizeof(sEntityName));
	}
	
	/* @A1m`:
	 * 'fire_cracker_blast' - if you remove this check, 
	 * even if you set cvar tank_fire_immunity or infected_fire_immunity to 1, 
	 * then the damage will be done to the infected and the tank,
	 * if the player was set on fire with fireworks
	*/
	if (strcmp(sEntityName, "inferno") != 0 
	&& strcmp(sEntityName, "entityflame") != 0 
	&& strcmp(sEntityName, "fire_cracker_blast") != 0) {
		return;
	}

	int userid = hEvent.GetInt("userid");
	int client = GetClientOfUserId(userid);

	if (client < 1 || !IsLiveInfected(client)) {
		return;
	}

	int iDamage = hEvent.GetInt("dmg_health");
	ExtinguishType(client, userid, iDamage);
}

void ExtinguishType(int client, int userid, int iDamage)
{
	bool IsTank = (GetEntProp(client, Prop_Send, "m_zombieClass") == Z_TANK);
	int iCvarValue = (IsTank) ? tank_fire_immunity.IntValue : infected_fire_immunity.IntValue;

	if (iCvarValue == 3) {
		float fNow = GetGameTime();
		
		if (fWaitTime[client] - fNow <= 0.0) {
			float iExtinguishTime = (IsTank) ? tank_extinguish_time.FloatValue : infected_extinguish_time.FloatValue;
			/* @A1m`:
			 * + 0.1 -> We already know that the timer has definitely expired so as to call another timer
			 * Old code started many timers
			*/
			fWaitTime[client] = GetGameTime() + iExtinguishTime + 0.1; //maybe 0.01 next frame? =D

			CreateTimer(iExtinguishTime, TimerWait, userid, TIMER_FLAG_NO_MAPCHANGE);
		}
	} else if (iCvarValue == 1 || iCvarValue == 2) {
		ExtinguishEntity(client);
		if (iCvarValue == 1) {
			int iHealth = GetClientHealth(client) + iDamage;
			SetEntityHealth(client, iHealth);
		}
	}
}

public Action TimerWait(Handle hTimer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsLiveInfected(client)) {
		// A1m`: maybe this has already been checked in the game code, well, let it be)
		if (GetEntityFlags(client) & FL_ONFIRE) { 
			ExtinguishEntity(client);
		}
	}
}

bool IsLiveInfected(int client)
{
	return (GetClientTeam(client) == TEAM_INFECTED && IsPlayerAlive(client));
}
