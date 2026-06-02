#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

#define DEBUG					0

#define TEAM_SURVIVOR			2
#define TEAM_ZOMBIE				3

#define ZC_CHARGER				6

bool
	g_bLateLoad = false;

ConVar
	g_hCvarZChargerPoundDmg = null,
	g_hCvarDmgIncappedPound = null;

public Plugin myinfo =
{
	name = "Incapped Charger Damage",
	author = "Sir, A1m`",
	description = "Modify Charger pummel damage done to Survivors",
	version = "2.1.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoad = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarDmgIncappedPound = CreateConVar("charger_dmg_incapped", "-1.0", "Pound Damage dealt to incapped Survivors.");

	g_hCvarZChargerPoundDmg = FindConVar("z_charger_pound_dmg");
	
	LateLoadPlugin();
}

void LateLoadPlugin()
{
	// hook already existing clients if loading late
	if (!g_bLateLoad) {
		return;
	}
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) {
			continue;
		}

		OnClientPutInServer(i);
	}
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

/* @A1m`:
Pound damage:
- damageForce = 0 0 0
- Damage equal to convar 'z_charger_pound_dmg', def 15
- Game function: CTerrorPlayer::HandleAnimEvent

[Hook_OnTakeDamage] Victim: Ellis (4), attacker: A1m` (2), inflictor: player (2), damage: 15.000000, damagetype: 128
	weapon: None (-1), damageForce: 0.000000 0.000000 0.000000, damagePosition: 0.000000 0.000000 0.000000
	m_carryVictim: -1, m_pummelVictim: 4, m_isCharging: 0
*/
Action Hook_OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype, \
								int &iWeapon, float fDamageForce[3], float fDamagePosition[3])
{
	if (iDamagetype != DMG_CLUB 
		|| fDamage != g_hCvarZChargerPoundDmg.FloatValue
		|| g_hCvarDmgIncappedPound.FloatValue <= 0.0
	) {
		return Plugin_Continue;
	}

	if (GetClientTeam(iVictim) != TEAM_SURVIVOR
		|| GetEntProp(iVictim, Prop_Send, "m_isIncapacitated", 1) < 1
	) {
		return Plugin_Continue;
	}

	if (iAttacker < 1 || iAttacker > MaxClients
		|| GetClientTeam(iAttacker) != TEAM_ZOMBIE
		|| GetEntProp(iAttacker, Prop_Send, "m_zombieClass") != ZC_CHARGER
	) {
		return Plugin_Continue;
	}

	int iPummelVictim = GetEntPropEnt(iAttacker, Prop_Send, "m_pummelVictim");
	if (iPummelVictim != iVictim) {
		return Plugin_Continue;
	}

#if DEBUG
	PrintToChatAll("[Hook_OnTakeDamage] Victim: (%N) %d, attacker: (%N) %d, inflictor: %d, damage: %f, damagetype: %d ", \
										iVictim, iVictim, iAttacker, iAttacker, iInflictor, fDamage, iDamagetype);
	PrintToChatAll("[Hook_OnTakeDamage] Weapon: %d, damageforce: %f %f %f, damageposition: %f %f %f", \
										iWeapon, fDamageForce[0], fDamageForce[1], fDamageForce[2], fDamagePosition[0], fDamagePosition[1], fDamagePosition[2]);
#endif

	fDamage = g_hCvarDmgIncappedPound.FloatValue;
	return Plugin_Changed;
}

