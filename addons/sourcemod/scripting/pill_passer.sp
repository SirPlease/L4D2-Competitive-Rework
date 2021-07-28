#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util> //#include <weapons>

#define TEAM_SURVIVOR 2
#define MAX_DIST_SQUARED 75076 /* 274^2 */

public Plugin myinfo =
{
	name = "Easier Pill Passer",
	author = "CanadaRox",
	description = "Lets players pass pills and adrenaline with +reload when they are holding one of those items",
	version = "0.3", //Update syntax A1m`
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (buttons & IN_RELOAD && !(buttons & IN_USE)) {
		char weapon_name[64];
		GetClientWeapon(client, weapon_name, sizeof(weapon_name));
		WeaponId wep = WeaponNameToId(weapon_name);
		if (wep == WEPID_PAIN_PILLS || wep == WEPID_ADRENALINE) {
			int target = GetClientAimTarget(client);
			if (target != -1 && GetClientTeam(target) == TEAM_SURVIVOR && GetPlayerWeaponSlot(target, 4) == -1 && !IsPlayerIncap(target)) {
				float clientOrigin[3], targetOrigin[3];
				GetClientAbsOrigin(client, clientOrigin);
				GetClientAbsOrigin(target, targetOrigin);
				if (GetVectorDistance(clientOrigin, targetOrigin, true) < MAX_DIST_SQUARED) {
					AcceptEntityInput(GetPlayerWeaponSlot(client, 4), "Kill");
					int ent = CreateEntityByName(WeaponNames[wep]);
					DispatchSpawn(ent);
					EquipPlayerWeapon(target, ent);
					
					CallEvent(client, target, view_as<int>(wep), ent);
				}
			}
		}
	}
}

void CallEvent(int client, int target, int wid, int weaponIndex)
{
	Handle hFakeEvent = CreateEvent("weapon_given");
	SetEventInt(hFakeEvent, "userid", GetClientUserId(target));
	SetEventInt(hFakeEvent, "giver", GetClientUserId(client));
	SetEventInt(hFakeEvent, "weapon", wid);
	SetEventInt(hFakeEvent, "weaponentid", weaponIndex);
	FireEvent(hFakeEvent);
}

bool IsPlayerIncap(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}
