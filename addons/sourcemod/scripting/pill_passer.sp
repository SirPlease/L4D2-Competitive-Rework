#pragma semicolon 1

#include <sourcemod>
#include <weapons.inc>

#define TEAM_SURVIVOR 2
#define MAX_DIST_SQUARED 75076 /* 274^2 */

public Plugin:myinfo =
{
	name = "Easier Pill Passer",
	author = "CanadaRox",
	description = "Lets players pass pills and adrenaline with +reload when they are holding one of those items",
	version = "0.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_RELOAD && !(buttons & IN_USE))
	{
		decl String:weapon_name[64];
		GetClientWeapon(client, weapon_name, sizeof(weapon_name));
		new WeaponId:wep = WeaponNameToId(weapon_name);
		if (wep == WEPID_PAIN_PILLS || wep == WEPID_ADRENALINE)
		{
			new target = GetClientAimTarget(client);
			if (target != -1 && GetClientTeam(target) == TEAM_SURVIVOR && GetPlayerWeaponSlot(target, 4) == -1 && !IsPlayerIncap(target))
			{
				decl Float:clientOrigin[3], Float:targetOrigin[3];
				GetClientAbsOrigin(client, clientOrigin);
				GetClientAbsOrigin(target, targetOrigin);
				if (GetVectorDistance(clientOrigin, targetOrigin, true) < MAX_DIST_SQUARED)
				{
					AcceptEntityInput(GetPlayerWeaponSlot(client, 4), "Kill");
					new ent = CreateEntityByName(WeaponNames[wep]);
					DispatchSpawn(ent);
					EquipPlayerWeapon(target, ent);
					new Handle:hFakeEvent = CreateEvent("weapon_given");
					SetEventInt(hFakeEvent, "userid", GetClientUserId(target));
					SetEventInt(hFakeEvent, "giver", GetClientUserId(client));
					SetEventInt(hFakeEvent, "weapon", _:wep);
					SetEventInt(hFakeEvent, "weaponentid", ent);
					FireEvent(hFakeEvent);
				}
			}
		}
	}
}

stock bool:IsPlayerIncap(client) return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");