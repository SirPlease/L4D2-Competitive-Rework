#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define BOOMER_ZOMBIE_CLASS  2
#define SPITTER_ZOMBIE_CLASS 4

bool 
	bLateLoad,
	IsEnabled;

ConVar 
	CbashKills;

public Plugin myinfo =
{
	name = "L4D2 Bash Kills",
	author = "Jahze, A1m`",
	version = "1.3",
	description = "Stop special infected getting bashed to death",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CbashKills = CreateConVar("l4d_no_bash_kills", "1", "Prevent special infected from getting bashed to death", _, true, 0.0, true, 1.0);
	IsEnabled = CbashKills.BoolValue;
	CbashKills.AddChangeHook(BashKills_Changed);

	if (bLateLoad) {
		for(int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPutInServer(i);
			}
		}
	}
}

public void BashKills_Changed(ConVar Cvar, const char[] oldValue, const char[] newValue)
{
	IsEnabled = Cvar.BoolValue;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnHurt);
}

public Action OnHurt(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3])
{
	if (!IsEnabled) {
		return Plugin_Continue;
	}
	
	if (damagetype == DMG_CLUB && weapon == -1 && damage == 250.0) {
		if (IsSurvivor(attacker) && IsValidSI(victim)) {
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

bool IsValidSI(int client)
{
	if (GetClientTeam(client) == TEAM_INFECTED && IsPlayerAlive(client)) {
		int playerClass = GetEntProp(client, Prop_Send, "m_zombieClass");
		// Allow boomer and spitter m2 kills
		if (playerClass == BOOMER_ZOMBIE_CLASS || playerClass == SPITTER_ZOMBIE_CLASS) {
			return false;
		}
		return true;
	}

	return false;
}

bool IsSurvivor(int client)
{
	return (client > 0 
	&& client <= MaxClients 
	&& IsClientInGame(client) 
	&& GetClientTeam(client) == TEAM_SURVIVOR 
	/*&& IsPlayerAlive(client)*/);
}
