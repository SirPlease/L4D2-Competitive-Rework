#pragma semicolon 1
#pragma newdecls required;

#include <sourcemod>
#include <sdktools>

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
	version = "2.7",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	infected_fire_immunity = CreateConVar("infected_fire_immunity", 
	"3", 
	"What type of fire immunity should infected have? 0 = None, 3 = Extinguish burns, 2 = Prevent burns, 1 = Complete immunity",_, true, 0.0, true, 3.0);
	tank_fire_immunity = CreateConVar("tank_fire_immunity", 
	"2", 
	"What type of fire immunity should the tank have? 0 = None, 3 = Extinguish burns, 2 = Prevent burns, 1 = Complete immunity",_, true, 0.0, true, 3.0);
	
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

public void SIOnFire(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int attacker = hEvent.GetInt("attacker");
	if (attacker == 0) { //more performance
		/* @A1m`:
		 * char weapon[64];
		 * hEvent.GetString("weapon", weapon, sizeof(weapon));
		 *
		 * This returns an empty string, and this plugin calls the function every time if attacker == 0
		 * The new method described here will work much better
		 * Сan try event damagetype, but I don’t know..
		*/
		int attackerentid = hEvent.GetInt("attackerentid");
		if (attackerentid > 0 && IsValidEntity(attackerentid)) { //attackerentid > MaxClients ?
			char entName[64];
			GetEntityClassname(attackerentid, entName, sizeof(entName));

			if (strcmp(entName, "inferno") == 0 || strcmp(entName, "entityflame") == 0) {
				int userid = hEvent.GetInt("userid");
				int client = GetClientOfUserId(userid);
				if (client > 0 && IsLiveInfected(client)) {
					int damage = hEvent.GetInt("dmg_health");
					/* @A1m`:
					 * It damages every onthink.
					*/
					ExtinguishType(client, userid, damage);
				}
			}
		}
	}
}

void ExtinguishType(int client, int userid, const int iDamage)
{
	bool IsTank = (GetEntProp(client, Prop_Send, "m_zombieClass") == Z_TANK);
	int iCvarValue = (IsTank) ? tank_fire_immunity.IntValue : infected_fire_immunity.IntValue;

	if (iCvarValue == 3) {
		float fNow = GetGameTime();
		
		if (fWaitTime[client] - fNow <= 0.0) {
			float iExtinguishTime = (IsTank) ? tank_extinguish_time.FloatValue : infected_extinguish_time.FloatValue;
			/* @A1m`:
			 * + 0.2 -> We already know that the timer has definitely expired so as to call another timer
			 * Old code started many timers
			*/
			fWaitTime[client] = GetGameTime() + iExtinguishTime + 0.2; 

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
	return (GetClientTeam(client) == TEAM_INFECTED 
		&& IsPlayerAlive(client));
}