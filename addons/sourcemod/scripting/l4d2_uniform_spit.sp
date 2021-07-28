#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks> //#include <l4d2d_timers>

#define GAMEDATA "l4d2_si_ability"

#define TICK_TIME 0.200072
#define TEAM_SURVIVOR 2

#define DMG_TYPE_SPIT (DMG_RADIATION|DMG_ENERGYBEAM)

ConVar
	hCvarDamagePerTick,
	hCvarAlternateDamagePerTwoTicks,
	hCvarMaxTicks,
	hCvarGodframeTicks;

StringMap
	hPuddles;

int
	m_activeTimerOffset,
	maxTicks,
	godframeTicks;

bool
	bLateLoad;

float
	damagePerTick,
	alternatePerTick;

enum struct eVictimStruct
{
	int eiCount;
	bool ebAltTick;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLateLoad = late;
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "L4D2 Uniform Spit",
	author = "Visor, Sir, A1m`",
	description = "Make the spit deal a set amount of DPS under all circumstances",
	version = "1.3.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();
	hCvarDamagePerTick = CreateConVar("l4d2_spit_dmg", "-1.0", "Damage per tick the spit inflicts. -1 to skip damage adjustments");
	hCvarAlternateDamagePerTwoTicks = CreateConVar("l4d2_spit_alternate_dmg", "-1.0", "Damage per alternate tick. -1 to disable");
	hCvarMaxTicks = CreateConVar("l4d2_spit_max_ticks", "28", "Maximum number of acid damage ticks");
	hCvarGodframeTicks = CreateConVar("l4d2_spit_godframe_ticks", "4", "Number of initial godframed acid ticks");

	hPuddles = new StringMap();

	if (bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPutInServer(i);
			}
		}
	}
}

void InitGameData()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);

	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}
	
	m_activeTimerOffset = GameConfGetOffset(hGamedata, "CInferno->m_activeTimer");
	if (m_activeTimerOffset == -1) {
		SetFailState("Failed to get offset 'CInferno->m_activeTimer'.");
	}
	
	delete hGamedata;
}

public void OnMapEnd()
{
	hPuddles.Clear();
}

public void OnConfigsExecuted()
{
	damagePerTick = hCvarDamagePerTick.FloatValue;
	alternatePerTick = hCvarAlternateDamagePerTwoTicks.FloatValue;
	maxTicks = hCvarMaxTicks.IntValue;
	godframeTicks = hCvarGodframeTicks.IntValue;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strcmp(classname, "insect_swarm") == 0) {
		char trieKey[8];
		IntToString(entity, trieKey, sizeof(trieKey));
		
		eVictimStruct victimArray[MAXPLAYERS + 1];
		hPuddles.SetArray(trieKey, victimArray[0], (sizeof(victimArray) * sizeof(eVictimStruct)));
	}
}

public void OnEntityDestroyed(int entity)
{
	if (IsInsectSwarm(entity)) {
		char trieKey[8];
		IntToString(entity, trieKey, sizeof(trieKey));

		hPuddles.Remove(trieKey);
	}
}

/*
 * signed int CInsectSwarm::GetDamageType()
 * {
 *   return 263168; //DMG_RADIATION|DMG_ENERGYBEAM
 * }
*/
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!(damagetype & DMG_TYPE_SPIT)) { //for performance
		return Plugin_Continue;
	}

	if (!IsInsectSwarm(inflictor) || !IsSurvivor(victim)) {
		return Plugin_Continue;
	}
	
	char trieKey[8];
	IntToString(inflictor, trieKey, sizeof(trieKey));

	eVictimStruct victimArray[MAXPLAYERS + 1];
	if (hPuddles.GetArray(trieKey, victimArray[0], (sizeof(victimArray) * sizeof(eVictimStruct)))) {
		victimArray[victim].eiCount++;
		
		// Check to see if it's a godframed tick
		if ((GetPuddleLifetime(inflictor) >= godframeTicks * TICK_TIME) && victimArray[victim].eiCount < godframeTicks) {
			victimArray[victim].eiCount = godframeTicks + 1;
		}

		// Let's see what do we have here
		if (damagePerTick > -1.0) {
			if (alternatePerTick > -1.0 && victimArray[victim].ebAltTick) {
				victimArray[victim].ebAltTick = false;
				damage = alternatePerTick;
			} else {
				damage = damagePerTick;
				victimArray[victim].ebAltTick = true;
			}
		}
		
		// Update the array with stored tickcounts
		hPuddles.SetArray(trieKey, victimArray[0], (sizeof(victimArray) * sizeof(eVictimStruct)));
		
		if (godframeTicks >= victimArray[victim].eiCount || victimArray[victim].eiCount > maxTicks) {
			damage = 0.0;
		}
		
		if (victimArray[victim].eiCount > maxTicks) {
			AcceptEntityInput(inflictor, "Kill");
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

float GetPuddleLifetime(int puddle)
{
	return ITimer_GetElapsedTime(view_as<IntervalTimer>(GetEntityAddress(puddle) + view_as<Address>(m_activeTimerOffset)));
}

bool IsInsectSwarm(int entity) //=D
{
	if (IsValidEntity(entity)) {
		char classname[32];
		GetEntityClassname(entity, classname, sizeof(classname));
		return (strcmp(classname, "insect_swarm") == 0);
	}

	return false;
}

bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients /*&& IsClientInGame(client)*/ && GetClientTeam(client) == TEAM_SURVIVOR);
}
