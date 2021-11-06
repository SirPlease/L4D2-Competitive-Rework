#pragma semicolon 1
#pragma newdecls required;

#include <sourcemod>
#include <sdktools>
#include <sdkhooks> //DMG_BURN

#define Z_TANK 8
#define TEAM_INFECTED 3

#define ENTITY_MAX_NAME 64

enum
{
	eDisable = 0,
	eCompleteImmunity,
	ePreventBurns,
	eExtinguishBurnsThroughTime
};

static const char sEntityList[][] = 
{
	"inferno",
	"entityflame",
	"fire_cracker_blast",
	"trigger_hurt"
};

ConVar
	infected_fire_immunity = null,
	tank_fire_immunity = null,
	infected_extinguish_time = null,
	tank_extinguish_time = null;

float
	g_fWaitTime[MAXPLAYERS + 1] = {0.0, ...};

public Plugin myinfo =
{
	name = "SI Fire Immunity",
	author = "Jacob, darkid, A1m`",
	description = "Special Infected fire damage management.",
	version = "3.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	infected_fire_immunity = CreateConVar( \
		"infected_fire_immunity", \
		"3", \
		"What type of fire immunity should infected have? 0 = None, 3 = Extinguish burns through time, 2 = Prevent burns, 1 = Complete immunity", \
		_, true, 0.0, true, 3.0 \
	);
	
	tank_fire_immunity = CreateConVar( \
		"tank_fire_immunity", \
		"2", \
		"What type of fire immunity should the tank have? 0 = None, 3 = Extinguish burns through time, 2 = Prevent burns, 1 = Complete immunity", \
		_, true, 0.0, true, 3.0 \
	);
	
	infected_extinguish_time = CreateConVar( \
		"infected_extinguish_time", \
		"1.0", \
		"After what time will the infected player be extinguished, works if cvar 'infected_fire_immunity' equal 3", \
		_, true, 0.0, true, 999.0 \
	);
	
	tank_extinguish_time = CreateConVar( \
		"tank_extinguish_time", \
		"1.0", \
		"After what time will the tank player be extinguished, works if cvar 'tank_fire_immunity' equal 3", \
		_, true, 0.0, true, 999.0 \
	);
	
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("round_start", EventReset, EventHookMode_PostNoCopy);
	HookEvent("round_end", EventReset, EventHookMode_PostNoCopy);
}

public void EventReset(Event hEvent, const char[] eName, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) {
		g_fWaitTime[i] = 0.0;
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
 *
 * If the attacker is not a player but an entity, then the parameter 'weapon' in the event returns an empty string
 *
 * Incendiary ammo:
 * Event_PlayerHurt: Hunter, attacker: 2 (entityclassname player), attackerentid: 1 (entityclassname player)
 * Event string weapon: entityflame, type: 268435464 
 *
 * Static fire on the map:
 * Event_PlayerHurt: A1m`, attacker: 0 (entityclassname entityflame), attackerentid: 277 (entityclassname entityflame)
 * Event string weapon: , type: 268435464 //weapon empty =/
 *
 * Molotov:
 * Event_PlayerHurt: Tank, attacker: 2 (entityclassname player), attackerentid: 1 (entityclassname player)
 * weapon: inferno, type: 8
 * Event_PlayerHurt: Tank, attacker: 2 (entityclassname player), attackerentid: 1 (entityclassname player)
 * Event string weapon: entityflame, type: 268435464
 *
 * Сanister:
 * Event_PlayerHurt: Tank, attacker: 2 (entityclassname player), attackerentid: 1 (entityclassname player)
 * Event string weapon: entityflame, type: 268435464
 *
 * Fireworks:
 * Event_PlayerHurt: A1m`, attacker: 2 (entityclassname player), attackerentid: 0 (entityclassname player)
 * Event string weapon: fire_cracker_blast, type: 8 //fire_cracker_blast need check?
 * Event_PlayerHurt: A1m`, attacker: 2 (entityclassname player), attackerentid: 0 (entityclassname player)
 * Event string weapon: entityflame, type: 268435464
*/
public void Event_PlayerHurt(Event hEvent, const char[] eName, bool dontBroadcast)
{
	/*
	 * This event 'player_hurt' is called very often
	 */
	int iDmgType = hEvent.GetInt("type");
	if (!(iDmgType & DMG_BURN)) { //more performance
		return;
	}

	char sEntityName[ENTITY_MAX_NAME];
	int iAttackerentID = hEvent.GetInt("attackerentid");
	if (iAttackerentID > MaxClients) { //The entity should not have a weapon =)
		GetEntityClassname(iAttackerentID, sEntityName, sizeof(sEntityName));
	} else {
		hEvent.GetString("weapon", sEntityName, sizeof(sEntityName));
	}

	if (!IsFireEntity(sEntityName)) {
		return;
	}
	
	int iUserID = hEvent.GetInt("userid");
	int iClient = GetClientOfUserId(iUserID);

	if (iClient < 1 || !IsLiveInfected(iClient)) {
		return;
	}

	int iDamage = hEvent.GetInt("dmg_health");
	ExtinguishType(iClient, iUserID, iDamage);
}

void ExtinguishType(int iClient, int iUserID, int iDamage)
{
	bool bIsTank = (GetEntProp(iClient, Prop_Send, "m_zombieClass") == Z_TANK);
	int iCvarValue = (bIsTank) ? tank_fire_immunity.IntValue : infected_fire_immunity.IntValue;

	if (iCvarValue == eExtinguishBurnsThroughTime) {
		float fNow = GetGameTime();
		
		if (g_fWaitTime[iClient] - fNow <= 0.0) {
			float fExtinguishTime = (bIsTank) ? tank_extinguish_time.FloatValue : infected_extinguish_time.FloatValue;
			
			/* @A1m`:
			 * + 0.1 -> We already know that the timer has definitely expired so as to call another timer
			 * Old code started many timers
			*/
			g_fWaitTime[iClient] = fNow + fExtinguishTime + 0.1;

			CreateTimer(fExtinguishTime, ExtinguishDelay, iUserID, TIMER_FLAG_NO_MAPCHANGE);
		}
	} else if (iCvarValue == eCompleteImmunity || iCvarValue == ePreventBurns) {
		ExtinguishFire(iClient);
		
		if (iCvarValue == eCompleteImmunity) {
			int iHealth = GetClientHealth(iClient) + iDamage;
			SetEntityHealth(iClient, iHealth);
		}
	}
}

public Action ExtinguishDelay(Handle hTimer, any iUserID)
{
	int iClient = GetClientOfUserId(iUserID);
	if (iClient > 0 && IsLiveInfected(iClient)) {
		ExtinguishFire(iClient);
	}

	return Plugin_Stop;
}

bool IsLiveInfected(int iClient)
{
	return (GetClientTeam(iClient) == TEAM_INFECTED && IsPlayerAlive(iClient));
}

void ExtinguishFire(int iClient)
{
	if (GetEntityFlags(iClient) & FL_ONFIRE) {
		ExtinguishEntity(iClient);
	}
}

bool IsFireEntity(char[] sEntityName)
{
	for (int i = 0; i < sizeof(sEntityList); i++) {
		if (strcmp(sEntityName, sEntityList[i]) == 0) {
			return true;
		}
	}

	return false;
}
