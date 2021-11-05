#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define BOOMER_ZOMBIE_CLASS		2
#define SPITTER_ZOMBIE_CLASS	4

bool
	g_bLateLoad = false,
	g_bIsEnabled = false;

ConVar
	g_hNoBashKills = null;

public Plugin myinfo =
{
	name = "L4D2 Bash Kills",
	author = "Jahze, A1m`",
	version = "1.4",
	description = "Stop special infected getting bashed to death",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoad = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hNoBashKills = CreateConVar("l4d_no_bash_kills", "1", "Prevent special infected from getting bashed to death", _, true, 0.0, true, 1.0);

	g_bIsEnabled = g_hNoBashKills.BoolValue;
	g_hNoBashKills.AddChangeHook(BashKills_Changed);

	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPutInServer(i);
			}
		}
	}
}

public void BashKills_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_bIsEnabled = hConVar.BoolValue;
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public Action Hook_OnTakeDamage(int iVictim, int& iAttacker, int& iInflictor, float& fDamage, \
									int& iDamageType, int& iWeapon, float fDamageForce[3], float fDamagePosition[3])
{
	if (!g_bIsEnabled) {
		return Plugin_Continue;
	}

	if (iDamageType == DMG_CLUB && iWeapon == -1 && fDamage == 250.0) {
		if (IsSurvivor(iAttacker) && IsValidSI(iVictim)) {
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

bool IsValidSI(int iClient)
{
	if (GetClientTeam(iClient) == TEAM_INFECTED && IsPlayerAlive(iClient)) {
		int iZClass = GetEntProp(iClient, Prop_Send, "m_zombieClass");
		// Allow boomer and spitter m2 kills
		if (iZClass == BOOMER_ZOMBIE_CLASS || iZClass == SPITTER_ZOMBIE_CLASS) {
			return false;
		}
		
		return true;
	}

	return false;
}

bool IsSurvivor(int iClient)
{
	return (iClient > 0
		&& iClient <= MaxClients
		&& IsClientInGame(iClient)
		&& GetClientTeam(iClient) == TEAM_SURVIVOR
		/*&& IsPlayerAlive(iClient)*/);
}
