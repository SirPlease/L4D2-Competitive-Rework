#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks> //#include <l4d2d_timers>

#define GAMEDATA "l4d2_si_ability"

#define MAX_ENTITY_NAME_SIZE 64
#define MAX_INT_STRING_SIZE 8

#define TICK_TIME 0.200072
#define TEAM_SURVIVOR 2

#define DMG_TYPE_SPIT (DMG_RADIATION|DMG_ENERGYBEAM)

enum
{
	eCount = 0,
	eAltTick,
	
	eArray_Size
};

ConVar
	g_hCvarDamagePerTick,
	g_hCvarAlternateDamagePerTwoTicks,
	g_hCvarMaxTicks,
	g_hCvarGodframeTicks;

StringMap
	g_hPuddles;

int
	g_iActiveTimerOffset,
	g_iMaxTicks,
	g_iGodframeTicks;

bool
	g_bLateLoad;

float
	g_fDamagePerTick,
	g_fAlternatePerTick;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoad = bLate;
	
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "L4D2 Uniform Spit",
	author = "Visor, Sir, A1m`",
	description = "Make the spit deal a set amount of DPS under all circumstances",
	version = "1.5",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();

	g_hCvarDamagePerTick = CreateConVar("l4d2_spit_dmg", "-1.0", "Damage per tick the spit inflicts. -1 to skip damage adjustments");
	g_hCvarAlternateDamagePerTwoTicks = CreateConVar("l4d2_spit_alternate_dmg", "-1.0", "Damage per alternate tick. -1 to disable");
	g_hCvarMaxTicks = CreateConVar("l4d2_spit_max_ticks", "28", "Maximum number of acid damage ticks");
	g_hCvarGodframeTicks = CreateConVar("l4d2_spit_godframe_ticks", "4", "Number of initial godframed acid ticks");
	
	g_hCvarDamagePerTick.AddChangeHook(CvarsChanged);
	g_hCvarAlternateDamagePerTwoTicks.AddChangeHook(CvarsChanged);
	g_hCvarMaxTicks.AddChangeHook(CvarsChanged);
	g_hCvarGodframeTicks.AddChangeHook(CvarsChanged);
	
	g_hPuddles = new StringMap();
	
	HookEvent("round_start", Event_RoundReset, EventHookMode_PostNoCopy);
	//HookEvent("round_end", Event_RoundReset, EventHookMode_PostNoCopy);
	
	if (g_bLateLoad) {
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
	
	g_iActiveTimerOffset = GameConfGetOffset(hGamedata, "CInferno->m_activeTimer");
	if (g_iActiveTimerOffset == -1) {
		SetFailState("Failed to get offset 'CInferno->m_activeTimer'.");
	}
	
	delete hGamedata;
}

public void CvarsChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	CvarsToType();
}

public void OnConfigsExecuted()
{
	CvarsToType();
}

void CvarsToType()
{
	g_fDamagePerTick = g_hCvarDamagePerTick.FloatValue;
	g_fAlternatePerTick = g_hCvarAlternateDamagePerTwoTicks.FloatValue;
	g_iMaxTicks = g_hCvarMaxTicks.IntValue;
	g_iGodframeTicks = g_hCvarGodframeTicks.IntValue;
}

public void Event_RoundReset(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	g_hPuddles.Clear();
}

public void OnMapEnd()
{
	g_hPuddles.Clear();
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public void OnClientDisconnect(int iClient)
{
	SDKUnhook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public void OnEntityCreated(int iEntity, const char[] sClassName)
{
	if (sClassName[0] != 'i') {
		return;
	}
	
	if (strcmp(sClassName, "insect_swarm") == 0) {
		char sTrieKey[MAX_INT_STRING_SIZE];
		IntToString(iEntity, sTrieKey, sizeof(sTrieKey));

		int iVictimArray[MAXPLAYERS + 1][eArray_Size];
		g_hPuddles.SetArray(sTrieKey, iVictimArray[0][0], (sizeof(iVictimArray) * sizeof(iVictimArray[])));
	}
}

public void OnEntityDestroyed(int iEntity)
{
	if (IsInsectSwarm(iEntity)) {
		char sTrieKey[MAX_INT_STRING_SIZE];
		IntToString(iEntity, sTrieKey, sizeof(sTrieKey));

		g_hPuddles.Remove(sTrieKey);
	}
}

/*
 * signed int CInsectSwarm::GetDamageType()
 * {
 *   return 263168; //DMG_RADIATION|DMG_ENERGYBEAM
 * }
*/
public Action Hook_OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &fDamageType)
{
	if (!(fDamageType & DMG_TYPE_SPIT)) { //for performance
		return Plugin_Continue;
	}

	if (!IsInsectSwarm(iInflictor) || !IsSurvivor(iVictim)) {
		return Plugin_Continue;
	}
	
	char sTrieKey[MAX_INT_STRING_SIZE];
	IntToString(iInflictor, sTrieKey, sizeof(sTrieKey));

	int iVictimArray[MAXPLAYERS + 1][eArray_Size];
	if (g_hPuddles.GetArray(sTrieKey, iVictimArray[0][0], (sizeof(iVictimArray) * sizeof(iVictimArray[])))) {
		iVictimArray[iVictim][eCount]++;
		
		// Check to see if it's a godframed tick
		if ((GetPuddleLifetime(iInflictor) >= g_iGodframeTicks * TICK_TIME) && iVictimArray[iVictim][eCount] < g_iGodframeTicks) {
			iVictimArray[iVictim][eCount] = g_iGodframeTicks + 1;
		}

		// Let's see what do we have here
		if (g_fDamagePerTick > -1.0) {
			if (g_fAlternatePerTick > -1.0 && iVictimArray[iVictim][eAltTick]) {
				iVictimArray[iVictim][eAltTick] = false;
				fDamage = g_fAlternatePerTick;
			} else {
				fDamage = g_fDamagePerTick;
				iVictimArray[iVictim][eAltTick] = true;
			}
		}
		
		// Update the array with stored tickcounts
		g_hPuddles.SetArray(sTrieKey, iVictimArray[0][0], (sizeof(iVictimArray) * sizeof(iVictimArray[])));
		
		if (g_iGodframeTicks >= iVictimArray[iVictim][eCount] || iVictimArray[iVictim][eCount] > g_iMaxTicks) {
			fDamage = 0.0;
		}
		
		if (iVictimArray[iVictim][eCount] > g_iMaxTicks) {
			KillEntity(iInflictor);
		}
		
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

float GetPuddleLifetime(int iPuddle)
{
	return ITimer_GetElapsedTime(view_as<IntervalTimer>(GetEntityAddress(iPuddle) + view_as<Address>(g_iActiveTimerOffset)));
}

bool IsInsectSwarm(int iEntity)
{
	if (iEntity <= MaxClients || !IsValidEdict(iEntity)) {
		return false;
	}

	char sClassName[MAX_ENTITY_NAME_SIZE];
	GetEdictClassname(iEntity, sClassName, sizeof(sClassName));
	return (strcmp(sClassName, "insect_swarm") == 0);
}

bool IsSurvivor(int iClient)
{
	return (iClient > 0
		&& iClient <= MaxClients
		&& IsClientInGame(iClient)
		&& GetClientTeam(iClient) == TEAM_SURVIVOR);
}

void KillEntity(int iEntity)
{
#if SOURCEMOD_V_MINOR > 8
	RemoveEntity(iEntity);
#else
	AcceptEntityInput(iEntity, "Kill");
#endif
}
