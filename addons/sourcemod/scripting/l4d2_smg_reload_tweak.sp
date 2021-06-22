#pragma semicolon 1
#pragma newdecls required;

#include <sourcemod>
#include <sdktools>

#pragma newdecls optional;
#include <l4d2_weapon_stocks>
#pragma newdecls required;

#define TEAM_SURVIVOR 2

ConVar hCvarReloadSpeedUzi;
ConVar hCvarReloadSpeedSilencedSmg;

public Plugin myinfo =
{
	name = "L4D2 SMG Reload Speed Tweaker",
	description = "Allows cvar'd control over the reload durations for both types of SMG",
	author = "Visor", //update syntax A1m`, little fix
	version = "1.1.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework/"
};

public void OnPluginStart()
{
	hCvarReloadSpeedUzi = CreateConVar("l4d2_reload_speed_uzi", "0", "Reload duration of Uzi(normal SMG)", FCVAR_CHEAT|FCVAR_NOTIFY, true, 0.0, true, 10.0);
	hCvarReloadSpeedSilencedSmg = CreateConVar("l4d2_reload_speed_silenced_smg", "0", "Reload duration of Silenced SMG", FCVAR_CHEAT|FCVAR_NOTIFY, true, 0.0, true, 10.0);
	
	HookEvent("weapon_reload", OnWeaponReload, EventHookMode_Post);
}

public void OnWeaponReload(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client)) {
		return;
	}
	
	float originalReloadDuration = 0.0, alteredReloadDuration = 0.0;

	int weapon = GetPlayerWeaponSlot(client, 0);
	WeaponId weaponId = IdentifyWeapon(weapon);

	switch (weaponId) {
		case WEPID_SMG: {
			originalReloadDuration = 2.235352;
			alteredReloadDuration = hCvarReloadSpeedUzi.FloatValue;
		}
		case WEPID_SMG_SILENCED: {
			originalReloadDuration = 2.235291;
			alteredReloadDuration = hCvarReloadSpeedSilencedSmg.FloatValue;
		}
		default: {
			return;
		}
	}
	
	if (alteredReloadDuration <= 0.0) {
		return;
	}

	float oldNextAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 0);
	float newNextAttack = oldNextAttack - originalReloadDuration + alteredReloadDuration;
	float playbackRate = originalReloadDuration / alteredReloadDuration;
	
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", newNextAttack);
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", newNextAttack);
	SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", playbackRate);
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (!(buttons & IN_ATTACK2)) {
		return Plugin_Continue;
	}
	
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client)) {
		return Plugin_Continue;
	}
	
	float originalReloadDuration = 0.0, alteredReloadDuration = 0.0;
	
	int weapon = GetPlayerWeaponSlot(client, 0);
	WeaponId weaponId = IdentifyWeapon(weapon);

	switch (weaponId) {
		case WEPID_SMG: {
			originalReloadDuration = 2.235352;
			alteredReloadDuration = hCvarReloadSpeedUzi.FloatValue;
		}
		case WEPID_SMG_SILENCED: {
			originalReloadDuration = 2.235291;
			alteredReloadDuration = hCvarReloadSpeedSilencedSmg.FloatValue;
		}
		default: {
			return Plugin_Continue;
		}
	}

	float playbackRate = originalReloadDuration / alteredReloadDuration;
	SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", playbackRate);
	
	return Plugin_Continue;
}

bool IsSurvivor(int client)
{
	return (client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client) 
		&& GetClientTeam(client) == TEAM_SURVIVOR);
}
