#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define ENT_CHECK_INTERVAL 1.0
#define TRACE_TOLERANCE 75.0

enum
{
	eiEntRef = 0,
	ebHasBeenSeen,
	
	eArray_Size
};

static const int g_iIdsToBlock[] =
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
	g_hBlockedEntities = null;

public Plugin myinfo =
{
	name = "Blind Infected",
	author = "CanadaRox, ProdigySim, A1m`",
	description = "Hides specified weapons from the infected team until they are (possibly) visible to one of the survivors to prevent SI scouting the map",
	version = "1.2.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	L4D2Weapons_Init();
	g_hBlockedEntities = new ArrayList(eArray_Size);
	
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);

	CreateTimer(ENT_CHECK_INTERVAL, Timer_EntCheck, _, TIMER_REPEAT);
}

public Action Timer_EntCheck(Handle hTimer)
{
	char sTmp[PLATFORM_MAX_PATH];
	int iCurrentEnt[eArray_Size], iEntity, iSize = g_hBlockedEntities.Length;
	
	for (int i = 0; i < iSize; i++) {
		g_hBlockedEntities.GetArray(i, iCurrentEnt[0], sizeof(iCurrentEnt));
		iEntity = EntRefToEntIndex(iCurrentEnt[eiEntRef]);
		
		if (iEntity != INVALID_ENT_REFERENCE && !iCurrentEnt[ebHasBeenSeen] && IsVisibleToSurvivors(iEntity)) {
			GetEntPropString(iEntity, Prop_Data, "m_ModelName", sTmp, sizeof(sTmp));
			iCurrentEnt[ebHasBeenSeen] = true;
			
			g_hBlockedEntities.SetArray(i, iCurrentEnt[0], sizeof(iCurrentEnt));
		}
	}

	return Plugin_Continue;
}

public void RoundStart_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	g_hBlockedEntities.Clear();
	
	CreateTimer(1.2, RoundStartDelay_Timer, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action RoundStartDelay_Timer(Handle hTimer)
{
	int iWeapon;
	int iBhTemp[eArray_Size], iEntityCount = GetEntityCount();

	for (int i = (MaxClients + 1); i < iEntityCount; i++) {
		iWeapon = IdentifyWeapon(i);
		if (iWeapon) {
			for (int j = 0; j < sizeof(g_iIdsToBlock); j++) {
				if (iWeapon == g_iIdsToBlock[j]) {
					SDKHook(i, SDKHook_SetTransmit, OnTransmit);
					
					iBhTemp[eiEntRef] = EntIndexToEntRef(i);
					iBhTemp[ebHasBeenSeen] = false;
					
					g_hBlockedEntities.PushArray(iBhTemp[0], sizeof(iBhTemp));
					
					break;
				}
			}
		}
	}

	return Plugin_Stop;
}

public Action OnTransmit(int iEntity, int iClient)
{
	if (GetClientTeam(iClient) != L4D2Team_Infected) {
		return Plugin_Continue;
	}
	
	int iCurrentEnt[eArray_Size], iSize = g_hBlockedEntities.Length;
	for (int i = 0; i < iSize; i++) {
		g_hBlockedEntities.GetArray(i, iCurrentEnt[0], sizeof(iCurrentEnt));
		
		if (iEntity == EntRefToEntIndex(iCurrentEnt[eiEntRef])) {
			return (iCurrentEnt[ebHasBeenSeen]) ? Plugin_Continue : Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

// from http://code.google.com/p/srsmod/source/browse/src/scripting/srs.despawninfected.sp
bool IsVisibleToSurvivors(int iEntity)
{
	int iSurvCount = 0;

	for (int i = 1; i <= MaxClients && iSurvCount < 4; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == L4D2Team_Survivor) {
			iSurvCount++;
			
			if (IsPlayerAlive(i) && IsVisibleTo(i, iEntity)) {
				return true;
			}
		}
	}

	return false;
}

bool IsVisibleTo(int iClient, int iEntity) // check an entity for being visible to a client
{
	float fAngles[3], fOrigin[3], fEnt[3], fLookAt[3];
	
	GetClientEyePosition(iClient, fOrigin); // get both player and zombie position
	
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fEnt);
	
	MakeVectorFromPoints(fOrigin, fEnt, fLookAt); // compute vector from player to zombie
	
	GetVectorAngles(fLookAt, fAngles); // get angles from vector for trace
	
	// execute Trace
	Handle hTrace = TR_TraceRayFilterEx(fOrigin, fAngles, MASK_SHOT, RayType_Infinite, TraceFilter);
	
	bool bIsVisible = false;
	if (TR_DidHit(hTrace)) {
		float fStart[3];
		TR_GetEndPosition(fStart, hTrace); // retrieve our trace endpoint
		
		if ((GetVectorDistance(fOrigin, fStart, false) + TRACE_TOLERANCE) >= GetVectorDistance(fOrigin, fEnt)) {
			bIsVisible = true; // if trace ray lenght plus tolerance equal or bigger absolute distance, you hit the targeted zombie
		}
	} else {
		//Debug_Print("Zombie Despawner Bug: Player-Zombie Trace did not hit anything, WTF");
		bIsVisible = true;
	}
	
	delete hTrace;

	return bIsVisible;
}

public bool TraceFilter(int iEntity, int iContentsMask)
{
	if (iEntity <= MaxClients || !IsValidEntity(iEntity)) { // dont let WORLD, players, or invalid entities be hit
		return false;
	}
	
	char sClassName[ENTITY_MAX_NAME_LENGTH];
	GetEdictClassname(iEntity, sClassName, sizeof(sClassName)); // Ignore prop_physics since some can be seen through
	
	return (strcmp(sClassName, "prop_physics", false) != 0);
}
