#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#pragma newdecls optional
#include <l4d2lib>
#pragma newdecls required
#include <sdkhooks>
#include <sdktools>

#define Z_TANK 8
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define ZOMBIEMANAGER_GAMEDATA "l4d2_zombiemanager"
#define LEFT4FRAMEWORK_GAMEDATA "left4dhooks.l4d2"

float 
	fSavedTime;

ConVar 
	hCvarCommonLimit,
	hCvarSurvivorLimit;

int 
	iCommonLimit,
	iSurvivorLimit,
	m_nPendingMobCount;

Address 
	pZombieManager = Address_Null;

public Plugin myinfo = 
{
	name = "L4D2 Horde",
	author = "Visor, Sir, A1m`",
	description = "Modifies Event Horde sizes and stops it completely during Tank",
	version = "1.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();

	hCvarCommonLimit = FindConVar("z_common_limit");
	hCvarSurvivorLimit = FindConVar("survivor_limit");

	HookEvent("round_start", view_as<EventHook>(RoundStart), EventHookMode_PostNoCopy);
}

void InitGameData()
{
	Handle hDamedata = LoadGameConfigFile(LEFT4FRAMEWORK_GAMEDATA);
	if (!hDamedata) {
		SetFailState("%s gamedata missing or corrupt", LEFT4FRAMEWORK_GAMEDATA);
	}

	pZombieManager = GameConfGetAddress(hDamedata, "ZombieManager");
	if (!pZombieManager) {
		SetFailState("Couldn't find the 'ZombieManager' address");
	}

	delete hDamedata;

	Handle hDamedata2 = LoadGameConfigFile(ZOMBIEMANAGER_GAMEDATA);
	if (!hDamedata2) {
		SetFailState("%s gamedata missing or corrupt", ZOMBIEMANAGER_GAMEDATA);
	}
	
	m_nPendingMobCount = GameConfGetOffset(hDamedata2, "ZombieManager->m_nPendingMobCount");
	if (m_nPendingMobCount == -1) {
		SetFailState("Failed to get offset 'ZombieManager->m_nPendingMobCount'.");
	}

	delete hDamedata2;
}

public void OnConfigsExecuted()
{
	iCommonLimit = hCvarCommonLimit.IntValue;
	iSurvivorLimit = hCvarSurvivorLimit.IntValue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strcmp (classname, "infected") == 0) {
		if (IsInfiniteHordeActive() && !IsTankUp() && !ArePlayersBiled() && iSurvivorLimit > 1) {
			SDKHook(entity, SDKHook_SpawnPost, CommonSpawnPost);
		}
	}
}

public void CommonSpawnPost(int entity)
{
	if (IsValidEntity(entity)) {
		if (GetAllCommon() > (iCommonLimit - 8)) {
			AcceptEntityInput(entity, "Kill");
		}
	}
}

public void RoundStart()
{
	fSavedTime = 0.0;
}

public Action L4D_OnSpawnMob(int &amount)
{
	/////////////////////////////////////
	// - Called on Event Hordes.
	// - Called on Panic Event Hordes.
	// - Called on Natural Hordes.
	// - Called on Onslaught (Mini-finale or finale Scripts)

	// - Not Called on Boomer Hordes.
	// - Not Called on z_spawn mob.
	////////////////////////////////////
	
	float fTime = GetGameTime();
	float fHordeTimer;

	// "Pause" the infinite horde during the Tank fight
	if (IsInfiniteHordeActive()) {
		if (IsTankUp()) {
			SetPendingMobCount(0);
			amount = 0;
			return Plugin_Handled;
		} else {
			// Horde Timer
			if (fTime - fSavedTime > 10.0) {
				fHordeTimer = 0.0;
			} else {
				// Scale Horde depending on how often the timer triggers.
				fHordeTimer = fTime - fSavedTime;
				amount = RoundToCeil(fHordeTimer) * 2;
			}
		}

		fSavedTime = fTime;
	}
	return Plugin_Continue;
}

bool IsInfiniteHordeActive()
{
	int countdown = GetHordeCountdown();
	return (/*GetPendingMobCount() > 0 &&*/ countdown > -1 && countdown <= 10);
}

/*int GetPendingMobCount()
{
	return LoadFromAddress(pZombieManager + view_as<Address>(m_nPendingMobCount), NumberType_Int32);
}*/

void SetPendingMobCount(int count)
{
	StoreToAddress(pZombieManager + view_as<Address>(m_nPendingMobCount), count, NumberType_Int32);
}

int GetHordeCountdown()
{
	return (CTimer_HasStarted(L4D2Direct_GetMobSpawnTimer())) ? RoundFloat(CTimer_GetRemainingTime(L4D2Direct_GetMobSpawnTimer())) : -1;
}

int GetAllCommon()
{
	int count, entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != -1) {
		if (IsValidEntity(entity) && GetEntProp(entity, Prop_Send, "m_mobRush") > 0) {
			count++;
		}
	}

	return count;
}

bool ArePlayersBiled()
{
	float fVomitFade, fNow = GetGameTime();
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR) {
			fVomitFade = GetEntPropFloat(i, Prop_Send, "m_vomitFadeStart");
			if (fVomitFade != 0.0 && fVomitFade + 8.0 > fNow) {
				return true;
			}
		}
	}

	return false;
}

bool IsTankUp()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED) {
			if (GetEntProp(i, Prop_Send, "m_zombieClass") == Z_TANK && IsPlayerAlive(i)) {
				return true;
			}
		}
	}

	return false;
}
