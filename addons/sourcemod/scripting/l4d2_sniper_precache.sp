#pragma semicolon 1
#pragma newdecls required;

#include <sourcemod>
#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

static const int snipers[] =
{
	35,		// SNIPER_AWP
	36		// SNIPER_SCOUT
};

public Plugin myinfo =
{
	name		= "L4D2 Sniper Precache",
	author		= "Visor, A1m`",
	version		= "2.2",
	description	= "Unlocks German sniper weapons",
	url 		= "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnMapStart()
{
	char sBuffer[64];
	for (int i = 0; i < sizeof(snipers); i++) {
		PrecacheModel(WeaponModels[snipers[i]]);
		
		GetWeaponName(snipers[i], sBuffer, sizeof(sBuffer));
		SpawnWeaponByName(sBuffer);
	}
}

void SpawnWeaponByName(const char[] sWeaponName)
{
	int iEntity = CreateEntityByName(sWeaponName);
	if (iEntity == -1) {
		return;
	}
	
	DispatchSpawn(iEntity);
	
	#if SOURCEMOD_V_MINOR > 8
		RemoveEntity(iEntity);
	#else
		AcceptEntityInput(iEntity, "Kill");
	#endif
}
