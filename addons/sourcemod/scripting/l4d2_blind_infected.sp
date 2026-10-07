#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

// The whole pending list is checked once every ENT_CHECK_SLICE * ENT_CHECK_SLICES seconds.
#define ENT_CHECK_SLICE 0.1
#define ENT_CHECK_SLICES 10

#define TRACE_TOLERANCE 75.0
#define MAX_ENTS 2048

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

bool g_bBlocked[MAX_ENTS + 1];

// Entity references not yet seen by survivors.
ArrayList g_hPending = null;

int g_iCursor = 0;

public Plugin myinfo =
{
	name = "Blind Infected",
	author = "CanadaRox, ProdigySim, A1m`, Ferks-FK",
	description = "Hides specified weapons from the infected team until they are (possibly) visible to one of the survivors to prevent SI scouting the map",
	version = "1.2.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	L4D2Weapons_Init();

	g_hPending = new ArrayList();

	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
	CreateTimer(ENT_CHECK_SLICE, Timer_EntCheck, _, TIMER_REPEAT);

	// Late load.
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

// Once equipped, a weapon is parented to the player and its m_vecOrigin becomes
// relative, so the visibility trace would never reach it and it would stay hidden.
void OnWeaponEquipPost(int iClient, int iWeapon)
{
	if (iWeapon > MaxClients && iWeapon <= MAX_ENTS && g_bBlocked[iWeapon]) {
		UnblockEntity(iWeapon);
	}
}

void UnblockEntity(int iEntity)
{
	SDKUnhook(iEntity, SDKHook_SetTransmit, OnTransmit);
	g_bBlocked[iEntity] = false;
}

public void OnMapStart()
{
	ClearAll();
}

// Prevents a recycled entity index from inheriting the blocked state.
public void OnEntityDestroyed(int iEntity)
{
	if (iEntity > 0 && iEntity <= MAX_ENTS) {
		g_bBlocked[iEntity] = false;
	}
}

void ClearAll()
{
	for (int i = 0; i <= MAX_ENTS; i++) {
		g_bBlocked[i] = false;
	}

	if (g_hPending != null) {
		g_hPending.Clear();
	}

	g_iCursor = 0;
}

void RoundStart_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	ClearAll();
	CreateTimer(1.2, RoundStartDelay_Timer, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action RoundStartDelay_Timer(Handle hTimer)
{
	// Entity indices can have gaps, so GetEntityCount() is not a valid upper bound.
	int iMax = GetMaxEntities();

	for (int i = (MaxClients + 1); i < iMax; i++) {
		if (!IsValidEntity(i)) {
			continue;
		}

		int iWeapon = IdentifyWeapon(i);
		if (!iWeapon) {
			continue;
		}

		// Already equipped, e.g. the survivors' starting pistols.
		int iOwner = GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity");
		if (iOwner > 0 && iOwner <= MaxClients) {
			continue;
		}

		for (int j = 0; j < sizeof(g_iIdsToBlock); j++) {
			if (iWeapon == g_iIdsToBlock[j]) {
				SDKHook(i, SDKHook_SetTransmit, OnTransmit);
				g_bBlocked[i] = true;
				g_hPending.Push(EntIndexToEntRef(i));
				break;
			}
		}
	}

	return Plugin_Stop;
}

Action OnTransmit(int iEntity, int iClient)
{
	if (iEntity < 0 || iEntity > MAX_ENTS || !g_bBlocked[iEntity]) {
		return Plugin_Continue;
	}

	if (GetClientTeam(iClient) != L4D2Team_Infected) {
		return Plugin_Continue;
	}

	return Plugin_Handled;
}

Action Timer_EntCheck(Handle hTimer)
{
	int iSize = g_hPending.Length;
	if (iSize == 0) {
		return Plugin_Continue;
	}

	int iBatch = (iSize + ENT_CHECK_SLICES - 1) / ENT_CHECK_SLICES;

	if (g_iCursor >= iSize) {
		g_iCursor = 0;
	}

	int iProcessed = 0;

	while (iProcessed < iBatch && g_iCursor < g_hPending.Length) {
		int iRef = g_hPending.Get(g_iCursor);
		int iEntity = EntRefToEntIndex(iRef);

		if (iEntity == INVALID_ENT_REFERENCE || !g_bBlocked[iEntity]) {
			g_hPending.Erase(g_iCursor);
			iProcessed++;
			continue;
		}

		if (IsVisibleToSurvivors(iEntity)) {
			UnblockEntity(iEntity);
			g_hPending.Erase(g_iCursor);
			iProcessed++;
			continue;
		}

		g_iCursor++;
		iProcessed++;
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

bool TraceFilter(int iEntity, int iContentsMask)
{
	if (iEntity <= MaxClients || !IsValidEntity(iEntity)) { // dont let WORLD, players, or invalid entities be hit
		return false;
	}
	
	char sClassName[ENTITY_MAX_NAME_LENGTH];
	GetEdictClassname(iEntity, sClassName, sizeof(sClassName)); // Ignore prop_physics since some can be seen through
	
	return (strcmp(sClassName, "prop_physics", false) != 0);
}
