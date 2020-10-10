#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2_weapon_stocks>

new Handle:hCvarReloadSpeedUzi;
new Handle:hCvarReloadSpeedSilencedSmg;

public Plugin:myinfo =
{
	name = "L4D2 SMG Reload Speed Tweaker",
	description = "Allows cvar'd control over the reload durations for both types of SMG",
	author = "Visor",
	version = "1.1",
	url = "https://github.com/Attano/L4D2-Competitive-Framework"
};

public OnPluginStart()
{
	hCvarReloadSpeedUzi = CreateConVar("l4d2_reload_speed_uzi", "0", "Reload duration of Uzi(normal SMG)", FCVAR_CHEAT|FCVAR_NOTIFY, true, 0.0, true, 10.0);
	hCvarReloadSpeedSilencedSmg = CreateConVar("l4d2_reload_speed_silenced_smg", "0", "Reload duration of Silenced SMG", FCVAR_CHEAT|FCVAR_NOTIFY, true, 0.0, true, 10.0);
	HookEvent("weapon_reload", OnWeaponReload, EventHookMode_Post);
}

public OnWeaponReload(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client))
		return;

	new Float:originalReloadDuration = 0.0;
	new Float:alteredReloadDuration = 0.0;
	new weapon = GetPlayerWeaponSlot(client, 0);
	new WeaponId:weaponId = IdentifyWeapon(weapon);
	if (weaponId == WEPID_SMG)
	{
		originalReloadDuration = 2.235352;
		alteredReloadDuration = GetConVarFloat(hCvarReloadSpeedUzi);
	}
	else if (weaponId == WEPID_SMG_SILENCED)
	{
		originalReloadDuration = 2.235291;
		alteredReloadDuration = GetConVarFloat(hCvarReloadSpeedSilencedSmg);
	}
	else
	{
		return;
	}

	if (alteredReloadDuration <= 0.0)
	{
		return;
	}

	new Float:oldNextAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 0);
	new Float:newNextAttack = oldNextAttack - originalReloadDuration + alteredReloadDuration;
	new Float:playbackRate = originalReloadDuration / alteredReloadDuration;
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", newNextAttack);
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", newNextAttack);
	SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", playbackRate);
}

public Action:OnPlayerRunCmd(client, &buttons)
{
	if (!(buttons & IN_ATTACK2))
		return Plugin_Continue;

	if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client))
		return Plugin_Continue;

	new Float:originalReloadDuration = 0.0;
	new Float:alteredReloadDuration = 0.0;
	new weapon = GetPlayerWeaponSlot(client, 0);
	new WeaponId:weaponId = IdentifyWeapon(weapon);
	if (weaponId == WEPID_SMG)
	{
		originalReloadDuration = 2.235352;
		alteredReloadDuration = GetConVarFloat(hCvarReloadSpeedUzi);
	}
	else if (weaponId == WEPID_SMG_SILENCED)
	{
		originalReloadDuration = 2.235291;
		alteredReloadDuration = GetConVarFloat(hCvarReloadSpeedSilencedSmg);
	}
	else
	{
		return Plugin_Continue;
	}
	new Float:playbackRate = originalReloadDuration / alteredReloadDuration;
	SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", playbackRate);
}

bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

