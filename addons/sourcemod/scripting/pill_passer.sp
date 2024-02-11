#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>
#undef REQUIRE_PLUGIN
#include <l4d2_lagcomp_manager>

#define USE_GIVEPLAYERITEM		0		// Works correctly only in the latest version of sourcemod 1.11 (GivePlayerItem sourcemod native)

public Plugin myinfo =
{
	name = "Easier Pill Passer",
	author = "CanadaRox, A1m`, Forgetest",
	description = "Lets players pass pills and adrenaline with +reload when they are holding one of those items",
	version = "1.6.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

bool g_bLateLoad, g_bLagCompAvailable;
float g_flSqRange;
bool g_bLOSClear, g_bLagComp;
int g_iPasser = -1;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin supports L4D2 only");
		return APLRes_SilentFailure;
	}
	
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVarHook("pill_passer_range",
				"274.0",
				"Max distance to transfer pills between players.",
				FCVAR_CHEAT,
				true, 0.0, false, 0.0,
				CvarChg_Range);
	
	CreateConVarHook("pill_passer_los_clear",
				"0",
				"Whether to require LOS clear when passing pills.",
				FCVAR_CHEAT,
				true, 0.0, true, 1.0,
				CvarChg_LOSClear);
	
	CreateConVarHook("pill_passer_lag_compensate",
				"1",
				"Whether to enable lag compensation when passing pills.",
				FCVAR_CHEAT,
				true, 0.0, true, 1.0,
				CvarChg_LagComp);
	
	if (g_bLateLoad)
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i)) OnClientPutInServer(i);
		}
	}
}

public void OnAllPluginsLoaded()
{
	g_bLagCompAvailable = LibraryExists("l4d2_lagcomp_manager");
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, "l4d2_lagcomp_manager") == 0)
		g_bLagCompAvailable = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, "l4d2_lagcomp_manager") == 0)
		g_bLagCompAvailable = false;
}

void CvarChg_Range(ConVar convar, const char[] oldValue, const char[] newValue)
{
	float val = convar.FloatValue;
	g_flSqRange = val * val;
}

void CvarChg_LOSClear(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bLOSClear = convar.BoolValue;
}

void CvarChg_LagComp(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bLagComp = convar.BoolValue;
}

public Action L4D2_LagComp_OnWantsLagCompensationOnEntity(int client, int entity, bool &result, int buttons, int impulse)
{
	if (client != g_iPasser)
		return Plugin_Continue;
	
	if (entity <= 0 || entity > MaxClients || !IsClientInGame(entity))
		return Plugin_Continue;
	
	if (GetClientTeam(entity) != 2)
		return Plugin_Continue;
	
	if (!IsPlayerAlive(entity))
		return Plugin_Continue;
	
	result = true;
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
		SDKHook(client, SDKHook_PostThinkPost, SDK_OnPostThink_Post);
}

void SDK_OnPostThink_Post(int iClient)
{
	int buttons = GetClientButtons(iClient);
	if (buttons & IN_RELOAD && !(buttons & IN_USE)) {
		char sWeaponName[ENTITY_MAX_NAME_LENGTH];
		GetClientWeapon(iClient, sWeaponName, sizeof(sWeaponName));
		
		int iWeapId = WeaponNameToId(sWeaponName);
		if (iWeapId == WEPID_PAIN_PILLS || iWeapId == WEPID_ADRENALINE) {
			if (g_bLagCompAvailable && g_bLagComp) {
				g_iPasser = iClient; // better detection in "WantsLagCompensationOnEntity"
				L4D2_LagComp_StartLagCompensation(iClient, LAG_COMPENSATE_BOUNDS);
			}
			
			int iTarget = -1;
			if (g_bLOSClear)
				iTarget = GetClientAimTargetLOS(iClient, true);
			else
				iTarget = GetClientAimTarget(iClient, true);
			
			if (iTarget > 0 && GetClientTeam(iTarget) == L4D2Team_Survivor && !IsPlayerIncap(iTarget)) {
				int iTargetWeaponIndex = GetPlayerWeaponSlot(iTarget, L4D2WeaponSlot_LightHealthItem);
				
				if (iTargetWeaponIndex == -1) {
					float fClientOrigin[3], fTargetOrigin[3];
					GetClientAbsOrigin(iClient, fClientOrigin);
					GetClientAbsOrigin(iTarget, fTargetOrigin);
					
					if (GetVectorDistance(fClientOrigin, fTargetOrigin, true) < g_flSqRange) {
						// Remove item
						int iGiverWeaponIndex = GetPlayerWeaponSlot(iClient, L4D2WeaponSlot_LightHealthItem);
						RemovePlayerItem(iClient, iGiverWeaponIndex);
						
						#if (SOURCEMOD_V_MINOR == 11) || USE_GIVEPLAYERITEM
							RemoveEntity(iGiverWeaponIndex);
							iGiverWeaponIndex = GivePlayerItem(iTarget, sWeaponName); // Fixed only in the latest version of sourcemod 1.11
						#else
							EquipPlayerWeapon(iTarget, iGiverWeaponIndex);
						#endif
						
						// If the entity was sucessfully given to the player
						if (iGiverWeaponIndex > 0) {
							// Call Event
							Handle hFakeEvent = CreateEvent("weapon_given");
							SetEventInt(hFakeEvent, "userid", GetClientUserId(iTarget));
							SetEventInt(hFakeEvent, "giver", GetClientUserId(iClient));
							SetEventInt(hFakeEvent, "weapon", iWeapId);
							SetEventInt(hFakeEvent, "weaponentid", iGiverWeaponIndex);
							
							FireEvent(hFakeEvent);
						}
					}
				}
			}
			
			if (g_bLagCompAvailable && g_bLagComp) {
				L4D2_LagComp_FinishLagCompensation(iClient);
				g_iPasser = -1;
			}
		}
	}
}

int GetClientAimTargetLOS(int client, bool only_clients = true)
{
	float pos[3], ang[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, ang);
	
	// "GetClientAimTarget" uses (MASK_SOLID|CONTENTS_HITBOX|CONTENTS_DEBRIS)
	static const int LOS_CLEAR_FLAGS = MASK_VISIBLE_AND_NPCS|CONTENTS_GRATE|CONTENTS_HITBOX|CONTENTS_DEBRIS;
	Handle tr = TR_TraceRayFilterEx(pos, ang, LOS_CLEAR_FLAGS, RayType_Infinite, TraceFilter_IgnoreSelf, client);
	
	int entity = -1;
	float end[3];
	if (TR_DidHit(tr))
	{
		entity = TR_GetEntityIndex(tr);
		TR_GetEndPosition(end, tr);
	}
	
	delete tr;
	
	if (entity == -1)
		return -1;
	
	if (only_clients)
	{
		if (!entity || entity > MaxClients)
			return -1;
	}
	
	return entity;
}

bool TraceFilter_IgnoreSelf(int entity, int contentsMask, any data)
{
	return data != entity;
}

bool IsPlayerIncap(int iClient)
{
	return (GetEntProp(iClient, Prop_Send, "m_isIncapacitated", 1) == 1);
}

ConVar CreateConVarHook(const char[] name,
	const char[] defaultValue,
	const char[] description="",
	int flags=0,
	bool hasMin=false, float min=0.0,
	bool hasMax=false, float max=0.0,
	ConVarChanged callback)
{
	ConVar cv = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	
	Call_StartFunction(INVALID_HANDLE, callback);
	Call_PushCell(cv);
	Call_PushNullString();
	Call_PushNullString();
	Call_Finish();
	
	cv.AddChangeHook(callback);
	
	return cv;
}
