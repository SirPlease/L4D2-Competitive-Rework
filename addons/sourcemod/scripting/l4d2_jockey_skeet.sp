#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <colors>

#define Z_JOCKEY 5
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

ConVar 
	z_leap_damage_interrupt,
	z_jockey_health,
	jockey_skeet_report;

float 
	jockeySkeetDmg,
	jockeyHealth,
	inflictedDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];

bool 
	reportJockeySkeets,
	lateLoad;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	lateLoad = late;
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "L4D2 Jockey Skeet",
	author = "Visor, A1m`",
	description = "A dream come true",
	version = "1.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	z_leap_damage_interrupt = CreateConVar("z_leap_damage_interrupt", "195.0", "Taking this much damage interrupts a leap attempt", _, true, 10.0, true, 325.0);
	jockey_skeet_report = CreateConVar("jockey_skeet_report", "1", "Report jockey skeets in chat?", _, true, 0.0, true, 1.0);
	z_jockey_health = FindConVar("z_jockey_health");

	if (lateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnConfigsExecuted()
{
	jockeySkeetDmg = z_leap_damage_interrupt.FloatValue;
	reportJockeySkeets = jockey_skeet_report.BoolValue;
	jockeyHealth = z_jockey_health.FloatValue;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
							float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!IsJockey(victim) || !IsSurvivor(attacker) || IsFakeClient(attacker)) {
		return Plugin_Continue;
	}
	
	if (!HasJockeyTarget(victim) && IsAttachable(victim) && IsShotgun(weapon)) {
		inflictedDamage[victim][attacker] += damage;
		if (inflictedDamage[victim][attacker] >= jockeySkeetDmg) {
			if (reportJockeySkeets) {
				CPrintToChat(victim, "{green}★★{default} You were {blue}skeeted{default} by {olive}%N{default}.", attacker);
				CPrintToChat(attacker, "{green}★★{default} You {blue}skeeted {olive}%N{default}'s Jockey.", victim);
				
				for (int i = 1; i <= MaxClients; i++)  {
					if (i == victim || i == attacker)
						continue;

					if (IsClientInGame(i) && !IsFakeClient(i)) {
						CPrintToChat(i, "{green}★★{default} {olive}%N{default}'s Jockey was {blue}skeeted{default} by {olive}%N{default}.", victim, attacker);
					}
				}
			}
			
			damage = jockeyHealth;
			return Plugin_Changed;
		}
		CreateTimer(0.1, ResetDamageCounter, victim);
	}
	return Plugin_Continue;	
}

public Action ResetDamageCounter(Handle hTimer, any jockey)
{
	for (int i = 1; i <= MaxClients; i++) {
		inflictedDamage[jockey][i] = 0.0;
	}
}

bool IsSurvivor(int client)
{
	return (client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client) 
		&& GetClientTeam(client) == TEAM_SURVIVOR);
}

bool IsJockey(int client)
{
	return (client > 0
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& GetClientTeam(client) == TEAM_INFECTED
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == Z_JOCKEY
		&& view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost")));
}

bool HasJockeyTarget(int infected)
{
	int client = GetEntPropEnt(infected, Prop_Send, "m_jockeyVictim");
	
	return (IsSurvivor(client) && IsPlayerAlive(client));
}

// A function conveniently named & implemented after the Jockey's ability of
// capping Survivors without actually using the ability itself.
bool IsAttachable(int jockey)
{
	return (!(GetEntityFlags(jockey) & FL_ONGROUND));
}

bool IsShotgun(int weapon)
{
	char classname[64];
	GetEdictClassname(weapon, classname, sizeof(classname));
	return (StrEqual(classname, "weapon_pumpshotgun") || StrEqual(classname, "weapon_shotgun_chrome")
		/*|| StrEqual(classname, "weapon_autoshotgun") || StrEqual(classname, "weapon_shotgun_spas")*/); //visor code need?
}