#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <weapons.inc>

#define SURVIVOR_TEAM 2
#define INFECTED_TEAM 3
#define ENT_CHECK_INTERVAL 1.0
#define TRACE_TOLERANCE 75.0

public Plugin:myinfo =
{
	name = "Blind Infected",
	author = "CanadaRox, ProdigySim",
	description = "Hides specified weapons from the infected team until they are (possibly) visible to one of the survivors to prevent SI scouting the map",
	version = "1.0.1",
	url = "https://github.com/CanadaRox/sourcemod-plugins/tree/master/blind_infected_l4d2"
};

enum EntInfo
{
	iEntRef,
	bool:hasBeenSeen
}

new const WeaponId:iIdsToBlock[] =
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

new Handle:hBlockedEntities;

public OnPluginStart()
{
	L4D2Weapons_Init();

	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);

	hBlockedEntities = CreateArray(_:EntInfo);

	CreateTimer(ENT_CHECK_INTERVAL, EntCheck_Timer, _, TIMER_REPEAT);
}

public Action:EntCheck_Timer(Handle:timer)
{
	new size = GetArraySize(hBlockedEntities);
	decl currentEnt[EntInfo];

	for (new i; i < size; i++)
	{
		GetArrayArray(hBlockedEntities, i, currentEnt[0]);
		new ent = EntRefToEntIndex(currentEnt[iEntRef]);
		if (ent != INVALID_ENT_REFERENCE && !currentEnt[hasBeenSeen] && IsVisibleToSurvivors(ent))
		{
			decl String:tmp[128];
			GetEntPropString(ent, Prop_Data, "m_ModelName", tmp, sizeof(tmp));
			currentEnt[hasBeenSeen] = true;
			SetArrayArray(hBlockedEntities, i, currentEnt[0]);
		}
	}
}

public RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	ClearArray(hBlockedEntities);
	CreateTimer(1.2, RoundStartDelay_Timer);
}

public Action:RoundStartDelay_Timer(Handle:timer)
{
	decl bhTemp[EntInfo];
	decl WeaponId:weapon;
	new psychonic = GetEntityCount();

	for (new i = MaxClients+1; i <= psychonic; i++)
	{
		weapon = IdentifyWeapon(i);
		if (weapon)
		{
			for (new j; j < sizeof(iIdsToBlock); j++)
			{
				if (weapon == iIdsToBlock[j])
				{
					SDKHook(i, SDKHook_SetTransmit, OnTransmit);
					bhTemp[iEntRef] = EntIndexToEntRef(i);
					bhTemp[hasBeenSeen] = false;
					PushArrayArray(hBlockedEntities, bhTemp[0]);
					break;
				}
			}
		}
	}
}

public Action:OnTransmit(entity, client)
{
	if (GetClientTeam(client) != INFECTED_TEAM) return Plugin_Continue;

	new size = GetArraySize(hBlockedEntities);
	decl currentEnt[EntInfo];

	for (new i; i < size; i++)
	{
		GetArrayArray(hBlockedEntities, i, currentEnt[0]);
		if (entity == EntRefToEntIndex(currentEnt[iEntRef]))
		{
			if (currentEnt[hasBeenSeen]) return Plugin_Continue;
			else return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

// from http://code.google.com/p/srsmod/source/browse/src/scripting/srs.despawninfected.sp
stock bool:IsVisibleToSurvivors(entity)
{
	new iSurv;

	for (new i = 1; i <= MaxClients && iSurv < 4; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == SURVIVOR_TEAM)
		{
			iSurv++
			if (IsPlayerAlive(i) && IsVisibleTo(i, entity))
			{
				return true;
			}
		}
	}

	return false;
}

stock bool:IsVisibleTo(client, entity) // check an entity for being visible to a client
{
	decl Float:vAngles[3], Float:vOrigin[3], Float:vEnt[3], Float:vLookAt[3];
	
	GetClientEyePosition(client,vOrigin); // get both player and zombie position
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vEnt);
	
	MakeVectorFromPoints(vOrigin, vEnt, vLookAt); // compute vector from player to zombie
	
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace
	
	// execute Trace
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilter);
	
	new bool:isVisible = false;
	if (TR_DidHit(trace))
	{
		decl Float:vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
		
		if ((GetVectorDistance(vOrigin, vStart, false) + TRACE_TOLERANCE) >= GetVectorDistance(vOrigin, vEnt))
		{
			isVisible = true; // if trace ray lenght plus tolerance equal or bigger absolute distance, you hit the targeted zombie
		}
	}
	else
	{
		//Debug_Print("Zombie Despawner Bug: Player-Zombie Trace did not hit anything, WTF");
		isVisible = true;
	}
	CloseHandle(trace);
	return isVisible;
}

public bool:TraceFilter(entity, contentsMask)
{
	if (entity <= MaxClients || !IsValidEntity(entity)) // dont let WORLD, players, or invalid entities be hit
	{
		return false;
	}
	
	decl String:class[128];
	GetEdictClassname(entity, class, sizeof(class)); // Ignore prop_physics since some can be seen through
	
	return !StrEqual(class, "prop_physics", false);
}
