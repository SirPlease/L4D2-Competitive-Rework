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

#include <sourcemod>
#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>

#pragma newdecls required

#define TIMESTAMP_OFFSET 4 //DT_IntervalTimer

int
	m_tongueVictimTimerTimeStamp;
	
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
	version = "1.4",
	description = "Survivors receive damage reports after they get capped",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	int m_tongueVictimTimer;
	if ((m_tongueVictimTimer = FindSendPropInfo("CTerrorPlayer", "m_tongueVictimTimer")) <= 0) {
		SetFailState("Could not find offset for CTerrorPlayer::m_tongueVictimTimer"); 
	}
	
	m_tongueVictimTimerTimeStamp = m_tongueVictimTimer + TIMESTAMP_OFFSET;
	
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
	ClearTimer();
}

public void Event_PlayerHurt(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int victim = GetClientOfUserId(hEvent.GetInt("userid"));
	if (IsInfected(victim) && IsTargetedSi(victim) > 0) {
		int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
		if (attacker > 0 && IsClientInGame(attacker) && IsSurvivor(attacker) && !IsFakeClient(attacker) && IsPlayerAlive(attacker)) {
			iDamage[attacker][victim] += hEvent.GetInt("dmg_health");
		}
	}
}

public void Event_PlayerDeath(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (client == 0 || !IsClientInGame(client) || !IsInfected(client)) {
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
	if (attacker == 0 || !IsClientInGame(attacker) || !IsInfected(attacker) || !IsPlayerAlive(attacker)) {
		return;
	}
	
	int victim = GetClientOfUserId(hEvent.GetInt("victim"));
	if (victim == 0 || !IsClientInGame(victim) || !IsSurvivor(victim) || IsFakeClient(victim) || !IsPlayerAlive(victim)) {
		return;
	}
	
	PrintInflictedDamage(victim, attacker);
}

public void Event_SmokerAttackFirst(Event hEvent, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(hEvent.GetInt("userid"));
	int victim = GetClientOfUserId(hEvent.GetInt("victim"));
	int checks = 0;

	ArrayStack hEventMembers = new ArrayStack(3);
	hEventMembers.Push(attacker);
	hEventMembers.Push(victim);
	hEventMembers.Push(checks);

	// It takes exactly 1.0s of dragging to get paralyzed, so we'll give the timer additional 0.1s to update
	hTongueParalyzeTimer = CreateTimer(1.1, CheckSurvivorState, hEventMembers);
}

public Action CheckSurvivorState(Handle hTimer, ArrayStack hEventMembers)
{
	static int checks, victim, attacker;
	if (!hEventMembers.Empty) {
		hEventMembers.Pop(checks);
		hEventMembers.Pop(victim);
		hEventMembers.Pop(attacker);
	}
	
	delete hEventMembers;

	if (IsSurvivorParalyzed(victim)) {
		PrintInflictedDamage(victim, attacker);
	}
	hTongueParalyzeTimer = null;
}

/* Big problem, I don't know what it is 13292
 * it was a long time before I realized:
 * 13288 + 4 = 13292 old, new 13256 + 4 = 13260
 * Table: m_tongueVictimTimer (offset 13288) (type DT_IntervalTimer)
 * Member: m_timestamp (offset 4) (type float) (bits 0) (NoScale)
*/
bool IsSurvivorParalyzed(int client)
{
	float fVictimTimer = GetGameTime() - GetEntDataFloat(client, m_tongueVictimTimerTimeStamp);
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
								L4D2_InfectedNames[iZClass-1], 
								iDamage[iSurvivor][iInfected]);

	fReported[iSurvivor][iInfected] = GetGameTime();
	iDamage[iSurvivor][iInfected] = 0;
}

int IsTargetedSi(int client)
{
	L4D2_Infected zombieclass = GetInfectedClass(client);

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
