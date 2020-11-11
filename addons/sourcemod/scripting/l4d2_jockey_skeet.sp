#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <colors>

new Handle:z_leap_damage_interrupt;
new Handle:z_jockey_health;
new Handle:jockey_skeet_report;

new Float:jockeySkeetDmg;
new Float:jockeyHealth;
new Float:inflictedDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];

new bool:reportJockeySkeets;
new bool:lateLoad;

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax) 
{
	lateLoad = late;
	return APLRes_Success;    
}

public Plugin:myinfo = 
{
	name = "L4D2 Jockey Skeet",
	author = "Visor",
	description = "A dream come true",
	version = "1.3",
	url = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
	z_leap_damage_interrupt = CreateConVar("z_leap_damage_interrupt", "195.0", "Taking this much damage interrupts a leap attempt", FCVAR_NONE, true, 10.0, true, 325.0);
	jockey_skeet_report = CreateConVar("jockey_skeet_report", "1", "Report jockey skeets in chat?", FCVAR_NONE, true, 0.0, true, 1.0);
	z_jockey_health = FindConVar("z_jockey_health");

	if (lateLoad) 
	{
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (IsClientInGame(i)) 
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
}

public OnConfigsExecuted()
{
	jockeySkeetDmg = GetConVarFloat(z_leap_damage_interrupt);
	reportJockeySkeets = GetConVarBool(jockey_skeet_report);
	jockeyHealth = GetConVarFloat(z_jockey_health);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3]) 
{
	if (!IsJockey(victim) || !IsSurvivor(attacker) || IsFakeClient(attacker))
		return Plugin_Continue;

	if (!HasJockeyTarget(victim) && IsAttachable(victim) && IsShotgun(weapon))
	{
		inflictedDamage[victim][attacker] += damage;
		if (inflictedDamage[victim][attacker] >= jockeySkeetDmg)
		{
			if (reportJockeySkeets)
			{
				CPrintToChat(victim, "{green}★★{default} You were {blue}skeeted{default} by {olive}%N{default}.", attacker);
				CPrintToChat(attacker, "{green}★★{default} You {blue}skeeted {olive}%N{default}'s Jockey.", victim);
				for (new i = 1; i <= MaxClients; i++) 
				{
					if (i == victim || i == attacker)
						continue;

					if (IsClientInGame(i) && !IsFakeClient(i)) 
					{
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

public Action:ResetDamageCounter(Handle:timer, any:jockey)
{
    for (new i = 1; i <= MaxClients; i++) 
	{
		inflictedDamage[jockey][i] = 0.0;
	}
}

bool:IsSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

bool:IsJockey(client)
{
	return (client > 0
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& GetClientTeam(client) == 3
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == 5
		&& GetEntProp(client, Prop_Send, "m_isGhost") != 1);
}

bool:HasJockeyTarget(infected)
{
	new client = GetEntDataEnt2(infected, 16124);
	return (IsSurvivor(client) && IsPlayerAlive(client));
}

// A function conveniently named & implemented after the Jockey's ability of
// capping Survivors without actually using the ability itself.
bool:IsAttachable(jockey)
{
	return !(GetEntityFlags(jockey) & FL_ONGROUND);
}

bool:IsShotgun(weapon)
{
	decl String:classname[64];
	GetEdictClassname(weapon, classname, sizeof(classname));
	return (StrEqual(classname, "weapon_pumpshotgun") || StrEqual(classname, "weapon_shotgun_chrome"));
}