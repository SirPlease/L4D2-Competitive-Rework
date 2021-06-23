/*
	SourcePawn is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2008 ITB CompuPhase.
	Source is Copyright (C) Valve Corporation.
	All trademarks are property of their respective owners.

	This program is free software: you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#pragma newdecls optional
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>
#pragma newdecls required

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define ARRAY_INDEX_TIMESTAMP 0 //DT_IntervalTimer

ConVar 
	z_ghost_delay_min;
	
Handle 
	hTongueParalyzeTimer = null;

int
	iDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];

float 
	fGhostDelay,
	fReported[MAXPLAYERS + 1][MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "L4D2 Display Infected HP",
	author = "Visor, A1m`",
	version = "1.5",
	description = "Survivors receive damage reports after they get capped",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("charger_carry_start", Event_CHJ_Attack);
	HookEvent("charger_pummel_start", Event_CHJ_Attack);
	HookEvent("lunge_pounce", Event_CHJ_Attack);
	HookEvent("jockey_ride", Event_CHJ_Attack);
	HookEvent("tongue_grab", Event_SmokerAttackFirst);
	HookEvent("choke_start", Event_SmokerAttackSecond);
	
	z_ghost_delay_min = FindConVar("z_ghost_delay_min");
	
	fGhostDelay = z_ghost_delay_min.FloatValue;
	z_ghost_delay_min.AddChangeHook(Cvar_Changed);
}

public void Cvar_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	fGhostDelay = convar.FloatValue;
}

public void OnMapEnd()
{
	hTongueParalyzeTimer = null; //if TIMER_FLAG_NO_MAPCHANGE
}

public void Event_PlayerHurt(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int victim = GetClientOfUserId(hEvent.GetInt("userid"));
	if (victim > 0 && IsClientInGame(victim) 
	&& GetClientTeam(victim) == TEAM_INFECTED && IsTargetedSi(victim) > 0
	) {
		int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
		if (attacker > 0 && IsClientInGame(attacker) 
		&& GetClientTeam(attacker) == TEAM_SURVIVOR 
		&& !IsFakeClient(attacker) && IsPlayerAlive(attacker)
		) {
			iDamage[attacker][victim] += hEvent.GetInt("dmg_health");
		}
	}
}

public void Event_PlayerDeath(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (client == 0 || !IsClientInGame(client) 
	|| GetClientTeam(client) != TEAM_INFECTED
	) {
		return;
	}
	
	int zombieclass = IsTargetedSi(client);
	if (zombieclass < 0) {
		return;
	}
	
	for (int i = 0; i <= MAXPLAYERS; i++) {
		iDamage[i][client] = 0;
	}

	if (zombieclass == view_as<int>(L4D2Infected_Smoker)) {
		ClearTimer();
	}
}

public void Event_CHJ_Attack(Event hEvent, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(hEvent.GetInt("userid"));
	if (attacker == 0 || !IsClientInGame(attacker) 
	|| GetClientTeam(attacker) != TEAM_INFECTED 
	|| !IsPlayerAlive(attacker)
	) {
		return;
	}
	
	int victim = GetClientOfUserId(hEvent.GetInt("victim"));
	if (victim == 0 || !IsClientInGame(victim) 
	|| GetClientTeam(victim) != TEAM_SURVIVOR 
	|| IsFakeClient(victim) || !IsPlayerAlive(victim)
	) {
		return;
	}
	
	PrintInflictedDamage(victim, attacker);
}

public void Event_SmokerAttackFirst(Event hEvent, const char[] name, bool dontBroadcast)
{
	int attacker_userid = hEvent.GetInt("userid");
	int attacker = GetClientOfUserId(attacker_userid);
	int victim_userid = hEvent.GetInt("victim");
	int victim = GetClientOfUserId(victim_userid);
	
	if (attacker > 0 && victim > 0) {
		//int checks = 0;
		ArrayStack hEventMembers = new ArrayStack(3);
		hEventMembers.Push(attacker_userid);
		hEventMembers.Push(victim_userid);
		//hEventMembers.Push(checks);

		// It takes exactly 1.0s of dragging to get paralyzed, so we'll give the timer additional 0.1s to update
		ClearTimer();
		hTongueParalyzeTimer = CreateTimer(1.1, CheckSurvivorState, hEventMembers, TIMER_FLAG_NO_MAPCHANGE | TIMER_HNDL_CLOSE);
	}
}

public Action CheckSurvivorState(Handle hTimer, ArrayStack hEventMembers)
{
	/* Fix warning 204: symbol is assigned a value that is never used: "checks"*/
	static int /*checks, */victim, attacker;
	if (!hEventMembers.Empty) {
		//checks = hEventMembers.Pop();
		victim = GetClientOfUserId(hEventMembers.Pop());
		attacker = GetClientOfUserId(hEventMembers.Pop());
		if (victim > 0 && attacker > 0) { //if players in game
			if (IsSurvivorParalyzed(victim)) {
				PrintInflictedDamage(victim, attacker);
			}
		}
	}
	//delete hEventMembers; //TIMER_HNDL_CLOSE, the timer will do for us
	
	hTongueParalyzeTimer = null;
}

/* @A1m:
 * Big problem, I don't know what it is 13292
 * it was a long time before I realized:
 * 13288 + 4 = 13292 old, new 13256 + 4 = 13260
 * Table: m_tongueVictimTimer (offset 13288) (type DT_IntervalTimer)
 * Member: m_timestamp (offset 4) (type float) (bits 0) (NoScale)
*/
bool IsSurvivorParalyzed(int client)
{
	float fVictimTimer = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_tongueVictimTimer", ARRAY_INDEX_TIMESTAMP);
	return (fVictimTimer >= 1.0 && GetEntProp(client, Prop_Send, "m_tongueOwner") != -1);
}

public void Event_SmokerAttackSecond(Event hEvent, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(hEvent.GetInt("userid"));
	int victim = GetClientOfUserId(hEvent.GetInt("victim"));

	ClearTimer();
	PrintInflictedDamage(victim, attacker);
}

void PrintInflictedDamage(int iSurvivor, int iInfected)
{
	float fGameTime = GetGameTime();
	if ((fReported[iSurvivor][iInfected] + fGhostDelay) >= fGameTime) {// Used as a workaround to prevent double prints that might happen for Charger/Smoker
		return;
	}
	
	if (iDamage[iSurvivor][iInfected] == 0) { // Don't bother
		return;
	}
	
	int iZClass = GetEntProp(iInfected, Prop_Send, "m_zombieClass");
	
	PrintToChat(iSurvivor, "\x04[DmgReport]\x01 \x03%N\x01(\x04%s\x01) took \x05%d\x01 damage from you!", 
								iInfected, 
								L4D2_InfectedNames[iZClass - 1], 
								iDamage[iSurvivor][iInfected]);

	fReported[iSurvivor][iInfected] = GetGameTime();
	iDamage[iSurvivor][iInfected] = 0;
}

int IsTargetedSi(int client)
{
	L4D2_Infected zombieclass = view_as<L4D2_Infected>(GetEntProp(client, Prop_Send, "m_zombieClass"));

	if (zombieclass == L4D2Infected_Charger 
	|| zombieclass == L4D2Infected_Hunter 
	|| zombieclass == L4D2Infected_Jockey 
	|| zombieclass == L4D2Infected_Smoker
	) {
		return view_as<int>(zombieclass);
	}
	
	return -1;
}

void ClearTimer()
{
	if (hTongueParalyzeTimer != null) {
		KillTimer(hTongueParalyzeTimer);
		hTongueParalyzeTimer = null;
	}
}
