#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <l4d2weapons>

#define HITGROUP_STOMACH	3

new bool:bLateLoad;

public APLRes:AskPluginLoad2( Handle:plugin, bool:late, String:error[], errMax )
{
	bLateLoad = late;
	return APLRes_Success;
}

public Plugin:myinfo =
{
	name = "L4D2 Sniper Hunter Bodyshot",
	author = "Visor",
	description = "Remove sniper weapons' stomach hitgroup damage multiplier against hunters",
	version = "1.1",
	url = "https://github.com/Attano/L4D2-Competitive-Framework"
};

public OnPluginStart()
{
	if (bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
}

public Action:TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (!IsHunter(victim) || !IsSurvivor(attacker) || IsFakeClient(attacker))
		return Plugin_Continue;

	new weapon = GetClientActiveWeapon(attacker);
	if (!IsValidSniper(weapon))
		return Plugin_Continue;
	
	// decl String:szHitgroup[32];
	// HitgroupToString(hitgroup, szHitgroup, sizeof(szHitgroup));
	// PrintToChatAll("Victim %N attacker %N hitgroup %s", victim, attacker, szHitgroup);
	if (hitgroup == HITGROUP_STOMACH)
	{
		damage = GetWeaponDamage(weapon) / 1.25;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

// HitgroupToString(hitgroup, String:destination[], maxlength)
// {
	// new String:buffer[32];
	// switch (hitgroup)
	// {
		// case 0:
		// {
			// buffer = "generic";
		// }
		// case 1:
		// {
			// buffer = "head";
		// }
		// case 2:
		// {
			// buffer = "chest";
		// }
		// case 3:
		// {
			// buffer = "stomach";
		// }
		// case 4:
		// {
			// buffer = "left arm";
		// }
		// case 5:
		// {
			// buffer = "right arm";
		// }
		// case 6:
		// {
			// buffer = "left leg";
		// }
		// case 7:
		// {
			// buffer = "right leg";
		// }
		// case 10:
		// {
			// buffer = "gear";
		// }
	// }
	// strcopy(destination, maxlength, buffer);
// }

GetClientActiveWeapon(client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

GetWeaponDamage(weapon)
{
	decl String:classname[64];
	GetEdictClassname(weapon, classname, sizeof(classname));
	return L4D2_GetIntWeaponAttribute(classname, L4D2IntWeaponAttributes:L4D2IWA_Damage);
}

bool:IsValidSniper(weapon)
{
	decl String:classname[64];
	GetEdictClassname(weapon, classname, sizeof(classname));
	return (StrEqual(classname, "weapon_sniper_scout") || StrEqual(classname, "weapon_sniper_awp"));
}

bool:IsSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

bool:IsHunter(client)
{
	return (client > 0
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& GetClientTeam(client) == 3
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == 3
		&& GetEntProp(client, Prop_Send, "m_isGhost") != 1);
}