#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util> //#include <weapons.inc>

#define SURVIVOR_TEAM 2
#define INFECTED_TEAM 3
#define ENT_CHECK_INTERVAL 1.0
#define TRACE_TOLERANCE 75.0

#if SOURCEMOD_V_MINOR > 9
enum struct EntInfo
{
	int iEntRef;
	bool hasBeenSeen;
}
#else
enum EntInfo
{
	iEntRef,
	bool:hasBeenSeen
};
#endif

static const WeaponId iIdsToBlock[] =
{
	WEPID_PISTOL,
	WEPID_SMG,
	WEPID_PUMPSHOTGUN,
	WEPID_AUTOSHOTGUN,
	WEPID_RIFLE,
	WEPID_HUNTING_RIFLE,
	WEPID_SMG_SILENCED,
	WEPID_SHOTGUN_CHROME,
	WEPID_RIFLE_DESERT,
	WEPID_SNIPER_MILITARY,
	WEPID_SHOTGUN_SPAS,
	WEPID_FIRST_AID_KIT,
	WEPID_MOLOTOV,
	WEPID_PIPE_BOMB,
	WEPID_PAIN_PILLS,
	WEPID_MELEE,
	WEPID_CHAINSAW,
	WEPID_GRENADE_LAUNCHER,
	WEPID_AMMO_PACK,
	WEPID_ADRENALINE,
	WEPID_DEFIBRILLATOR,
	WEPID_VOMITJAR,
	WEPID_RIFLE_AK47,
	WEPID_INCENDIARY_AMMO,
	WEPID_FRAG_AMMO,
	WEPID_PISTOL_MAGNUM,
	WEPID_SMG_MP5,
	WEPID_RIFLE_SG552,
	WEPID_SNIPER_SCOUT,
	WEPID_SNIPER_AWP
};

ArrayList
	hBlockedEntities;

public Plugin myinfo =
{
	name = "Blind Infected",
	author = "CanadaRox, ProdigySim, A1m`",
	description = "Hides specified weapons from the infected team until they are (possibly) visible to one of the survivors to prevent SI scouting the map",
	version = "1.0.5",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	L4D2Weapons_Init();

	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);

#if SOURCEMOD_V_MINOR > 9
	hBlockedEntities = new ArrayList(sizeof(EntInfo));
#else
	hBlockedEntities = new ArrayList(view_as<int>(EntInfo));
#endif

	CreateTimer(ENT_CHECK_INTERVAL, EntCheck_Timer, _, TIMER_REPEAT);
}

public Action EntCheck_Timer(Handle hTimer)
{
	char tmp[PLATFORM_MAX_PATH];
	int iSize = hBlockedEntities.Length;

#if SOURCEMOD_V_MINOR > 9
	EntInfo currentEnt;
	for (int i = 0; i < iSize; i++) {
		hBlockedEntities.GetArray(i, currentEnt, sizeof(EntInfo));
		int ent = EntRefToEntIndex(currentEnt.iEntRef);
		if (ent != INVALID_ENT_REFERENCE && !currentEnt.hasBeenSeen && IsVisibleToSurvivors(ent)) {
			GetEntPropString(ent, Prop_Data, "m_ModelName", tmp, sizeof(tmp));
			currentEnt.hasBeenSeen = true;
			hBlockedEntities.SetArray(i, currentEnt, sizeof(EntInfo));
		}
	}
#else
	EntInfo currentEnt[EntInfo];
	for (int i = 0; i < iSize; i++) {
		hBlockedEntities.GetArray(i, currentEnt[0], view_as<int>(EntInfo));
		int ent = EntRefToEntIndex(currentEnt[iEntRef]);
		if (ent != INVALID_ENT_REFERENCE && !currentEnt[hasBeenSeen] && IsVisibleToSurvivors(ent)) {
			GetEntPropString(ent, Prop_Data, "m_ModelName", tmp, sizeof(tmp));
			currentEnt[hasBeenSeen] = true;
			hBlockedEntities.SetArray(i, currentEnt[0], view_as<int>(EntInfo));
		}
	}
#endif

}

public void RoundStart_Event(Event hEvent, const char[] name, bool dontBroadcast)
{
	hBlockedEntities.Clear();
	CreateTimer(1.2, RoundStartDelay_Timer, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action RoundStartDelay_Timer(Handle hTimer)
{
#if SOURCEMOD_V_MINOR > 9
	EntInfo bhTemp;
#else
	EntInfo bhTemp[EntInfo];
#endif
	
	WeaponId weapon;
	int psychonic = GetEntityCount();

	for (int i = MaxClients + 1; i <= psychonic; i++) {
		weapon = IdentifyWeapon(i);
		if (weapon) {
			for (int j = 0; j < sizeof(iIdsToBlock); j++) {
				if (weapon == iIdsToBlock[j]) {
					SDKHook(i, SDKHook_SetTransmit, OnTransmit);
					
					#if SOURCEMOD_V_MINOR > 9
						bhTemp.iEntRef = EntIndexToEntRef(i);
						bhTemp.hasBeenSeen = false;
						hBlockedEntities.PushArray(bhTemp, sizeof(EntInfo));
					#else
						bhTemp[iEntRef] = EntIndexToEntRef(i);
						bhTemp[hasBeenSeen] = false;
						hBlockedEntities.PushArray(bhTemp[0], view_as<int>(EntInfo));
					#endif
					
					break;
				}
			}
		}
	}
}

public Action OnTransmit(int entity, int client)
{
	if (GetClientTeam(client) != INFECTED_TEAM) {
		return Plugin_Continue;
	}
	
#if SOURCEMOD_V_MINOR > 9
	EntInfo currentEnt;
#else
	EntInfo currentEnt[EntInfo];
#endif
	
	int iSize = hBlockedEntities.Length;
	for (int i = 0 ; i < iSize; i++) {
		#if SOURCEMOD_V_MINOR > 9
			hBlockedEntities.GetArray(i, currentEnt, sizeof(EntInfo));
			if (entity == EntRefToEntIndex(currentEnt.iEntRef)) {
				return (currentEnt.hasBeenSeen) ? Plugin_Continue : Plugin_Handled;
			}
		#else
			hBlockedEntities.GetArray(i, currentEnt[0], view_as<int>(EntInfo));
			if (entity == EntRefToEntIndex(currentEnt[iEntRef])) {
				return (currentEnt[hasBeenSeen]) ? Plugin_Continue : Plugin_Handled;
			}
		#endif
	}
	
	return Plugin_Continue;
}

// from http://code.google.com/p/srsmod/source/browse/src/scripting/srs.despawninfected.sp
stock bool IsVisibleToSurvivors(int entity)
{
	int iSurv = 0;

	for (int i = 1; i <= MaxClients && iSurv < 4; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == SURVIVOR_TEAM) {
			iSurv++;
			if (IsPlayerAlive(i) && IsVisibleTo(i, entity)) {
				return true;
			}
		}
	}

	return false;
}

bool IsVisibleTo(int client, int entity) // check an entity for being visible to a client
{
	float vAngles[3], vOrigin[3], vEnt[3], vLookAt[3];
	
	GetClientEyePosition(client,vOrigin); // get both player and zombie position
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vEnt);
	
	MakeVectorFromPoints(vOrigin, vEnt, vLookAt); // compute vector from player to zombie
	
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace
	
	// execute Trace
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilter);
	
	bool isVisible = false;
	if (TR_DidHit(trace)) {
		float vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
		
		if ((GetVectorDistance(vOrigin, vStart, false) + TRACE_TOLERANCE) >= GetVectorDistance(vOrigin, vEnt)) {
			isVisible = true; // if trace ray lenght plus tolerance equal or bigger absolute distance, you hit the targeted zombie
		}
	} else {
		//Debug_Print("Zombie Despawner Bug: Player-Zombie Trace did not hit anything, WTF");
		isVisible = true;
	}
	
	CloseHandle(trace);

	return isVisible;
}

public bool TraceFilter(int entity, int contentsMask)
{
	if (entity <= MaxClients || !IsValidEntity(entity)) { // dont let WORLD, players, or invalid entities be hit
		return false;
	}
	
	char class[128];
	GetEdictClassname(entity, class, sizeof(class)); // Ignore prop_physics since some can be seen through
	
	return !StrEqual(class, "prop_physics", false);
}
