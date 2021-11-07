#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define ENTITY_MAX_NAME_LENGTH	64
#define MAX_DIST_SQUARED		75076	// 274^2
#define USE_GIVEPLAYERITEM		0		// Works correctly only in the latest version of sourcemod 1.11 (GivePlayerItem sourcemod native)

public Plugin myinfo =
{
	name = "Easier Pill Passer",
	author = "CanadaRox, A1m`",
	description = "Lets players pass pills and adrenaline with +reload when they are holding one of those items",
	version = "1.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], \
									int &iWeapon, int &iSubtype, int &iCmdNum, int &iTickCount, int &iSeed, int iMouse[2])
{
	if (iButtons & IN_RELOAD && !(iButtons & IN_USE)) {
		char sWeaponName[ENTITY_MAX_NAME_LENGTH];
		GetClientWeapon(iClient, sWeaponName, sizeof(sWeaponName));
		
		int iWeapId = WeaponNameToId(sWeaponName);
		if (iWeapId == WEPID_PAIN_PILLS || iWeapId == WEPID_ADRENALINE) {
			int iTarget = GetClientAimTarget(iClient, true);
			
			if (iTarget > 0 && GetClientTeam(iTarget) == L4D2Team_Survivor && !IsPlayerIncap(iTarget)) {
				int iTargetWeaponIndex = GetPlayerWeaponSlot(iTarget, L4D2WeaponSlot_LightHealthItem);
				
				if (iTargetWeaponIndex == -1) {
					float fClientOrigin[3], fTargetOrigin[3];
					GetClientAbsOrigin(iClient, fClientOrigin);
					GetClientAbsOrigin(iTarget, fTargetOrigin);
					
					if (GetVectorDistance(fClientOrigin, fTargetOrigin, true) < MAX_DIST_SQUARED) {
						// Remove item
						int iGiverWeaponIndex = GetPlayerWeaponSlot(iClient, L4D2WeaponSlot_LightHealthItem);
						RemovePlayerItem(iClient, iGiverWeaponIndex);
						
						#if (SOURCEMOD_V_MINOR == 11) || USE_GIVEPLAYERITEM
							RemoveEntity(iGiverWeaponIndex);
							iGiverWeaponIndex = GivePlayerItem(iClient, sWeaponName); // Fixed only in the latest version of sourcemod 1.11
							
							// If the entity was not given to the player
							if (iGiverWeaponIndex < 1) {
								return Plugin_Continue;
							}
						#else
							EquipPlayerWeapon(iTarget, iGiverWeaponIndex);
						#endif
						
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
	}

	return Plugin_Continue;
}

bool IsPlayerIncap(int iClient)
{
	return (GetEntProp(iClient, Prop_Send, "m_isIncapacitated", 1) == 1);
}
