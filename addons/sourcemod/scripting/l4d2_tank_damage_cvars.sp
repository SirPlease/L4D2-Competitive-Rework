#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define DEBUG 0

ConVar
	g_hCvarVsTankPoundDamage = null,
	g_hCvarVsTankRockDamage = null;

bool
	g_bLateLoad = false;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoad = bLate;
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "L4D2 Tank Damage Cvars",
	author = "Visor, A1m`",
	description = "Toggle Tank attack damage per type",
	version = "2.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	g_hCvarVsTankPoundDamage = CreateConVar("vs_tank_pound_damage", "24.0", "Amount of damage done by a vs tank's melee attack on incapped survivors (a zero and negative value disables this).");
	g_hCvarVsTankRockDamage = CreateConVar("vs_tank_rock_damage", "24.0", "Amount of damage done by a vs tank's rock (a zero and negative value disables this).");

	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public void OnClientDisconnect(int iClient)
{
	SDKUnhook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public Action Hook_OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype)
{
	if (iDamagetype != DMG_CLUB) {
		return Plugin_Continue;
	}

	if (!IsValidSurvivor(iVictim) || !IsValidTank(iAttacker)) {
		return Plugin_Continue;
	}

	if (iInflictor <= MaxClients || !IsValidEdict(iInflictor)) {
		return Plugin_Continue;
	}

	char sClassName[ENTITY_MAX_NAME_LENGTH];
	GetEdictClassname(iInflictor, sClassName, sizeof(sClassName));

#if DEBUG
	PrintToChatAll("iVictim: %N, iAttacker: %N, iInflictor, %s (%d), fDamage: %f, iDamagetype: %d", \
							iVictim, iAttacker, sClassName, iInflictor, fDamage, iDamagetype);
#endif

	if (strcmp("weapon_tank_claw", sClassName) == 0) {
		if (IsIncapacitated(iVictim) && g_hCvarVsTankPoundDamage.FloatValue > 0) {
			fDamage = g_hCvarVsTankPoundDamage.FloatValue;

			return Plugin_Changed;
		}
	} else if (strcmp("tank_rock", sClassName) == 0) {
		if (g_hCvarVsTankRockDamage.FloatValue > 0) {
			fDamage = g_hCvarVsTankRockDamage.FloatValue;
		}

		return Plugin_Changed;
	}

	return Plugin_Continue;
}
