#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>
#undef REQUIRE_PLUGIN
#include <l4d2_lagcomp_manager>

#define ENTITY_MAX_NAME_LENGTH	64
#define MAX_DIST_SQUARED		75076	// 274^2
#define USE_GIVEPLAYERITEM		0		// Works correctly only in the latest version of sourcemod 1.11 (GivePlayerItem sourcemod native)

public Plugin myinfo =
{
	name = "Easier Pill Passer",
	author = "CanadaRox, A1m`, Forgetest",
	description = "Lets players pass pills and adrenaline with +reload when they are holding one of those items",
	version = "1.5.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

bool g_bLateLoad;

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
	if (g_bLateLoad)
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i)) OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
		SDKHook(client, SDKHook_PostThink, SDK_OnPostThink);
}

Action SDK_OnPostThink(int iClient)
{
	int buttons = GetClientButtons(iClient);
	if (buttons & IN_RELOAD && !(buttons & IN_USE)) {
		char sWeaponName[ENTITY_MAX_NAME_LENGTH];
		GetClientWeapon(iClient, sWeaponName, sizeof(sWeaponName));
		
		int iWeapId = WeaponNameToId(sWeaponName);
		if (iWeapId == WEPID_PAIN_PILLS || iWeapId == WEPID_ADRENALINE) {
			int iTarget = GetClientAimTarget(iClient, true);
			
			if (iTarget > 0 && GetClientTeam(iTarget) == L4D2Team_Survivor && !IsPlayerIncap(iTarget)) {
				int iTargetWeaponIndex = GetPlayerWeaponSlot(iTarget, L4D2WeaponSlot_LightHealthItem);
				
				if (iTargetWeaponIndex == -1) {
					L4D2_LagComp_StartLagCompensation(iClient, LAG_COMPENSATE_BOUNDS);
					
					float fClientOrigin[3], fTargetOrigin[3];
					GetClientAbsOrigin(iClient, fClientOrigin);
					GetClientAbsOrigin(iTarget, fTargetOrigin);
					
					if (GetVectorDistance(fClientOrigin, fTargetOrigin, true) < MAX_DIST_SQUARED) {
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
					
					L4D2_LagComp_FinishLagCompensation(iClient);
				}
			}
		}
	}

	return Plugin_Continue;
}

bool IsPlayerIncap(int iClient)
{
	return (GetEntProp(iClient, Prop_Send, "m_isIncapacitated", 1) == 1);
}
