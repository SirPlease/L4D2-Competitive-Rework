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
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define ARRAY_INDEX_TIMESTAMP 0 //DT_IntervalTimer

ConVar
	g_hGhostDelayMin = null;

Handle
	g_hTongueParalyzeTimer = null;

int
	g_iDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];

float
	g_fGhostDelay = 0.0,
	g_fReported[MAXPLAYERS + 1][MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "L4D2 Display Infected HP",
	author = "Visor, A1m`",
	version = "1.5.3",
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
	
	g_hGhostDelayMin = FindConVar("z_ghost_delay_min");
	
	g_fGhostDelay = g_hGhostDelayMin.FloatValue;
	g_hGhostDelayMin.AddChangeHook(Cvar_Changed);
}

public void Cvar_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_fGhostDelay = hConVar.FloatValue;
}

public void OnMapEnd()
{
	g_hTongueParalyzeTimer = null; //if TIMER_FLAG_NO_MAPCHANGE
}

public void Event_PlayerHurt(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iVictim > 0
		&& IsClientInGame(iVictim)
		&& GetClientTeam(iVictim) == TEAM_ZOMBIE
		&& IsTargetedSi(iVictim) > 0
	) {
		
		int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
		if (iAttacker > 0
			&& IsClientInGame(iAttacker)
			&& GetClientTeam(iAttacker) == TEAM_SURVIVOR
			&& !IsFakeClient(iAttacker)
			&& IsPlayerAlive(iAttacker)
		) {
			g_iDamage[iAttacker][iVictim] += hEvent.GetInt("dmg_health");
		}
	}
}

public void Event_PlayerDeath(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iClient == 0 
		|| !IsClientInGame(iClient) 
		|| GetClientTeam(iClient) != TEAM_ZOMBIE
	) {
		return;
	}
	
	int iZClass = IsTargetedSi(iClient);
	if (iZClass < 0) {
		return;
	}
	
	for (int i = 1; i <= MAXPLAYERS; i++) {
		g_iDamage[i][iClient] = 0;
	}

	if (iZClass == L4D2Infected_Smoker) {
		ClearTimer();
	}
}

public void Event_CHJ_Attack(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iAttacker = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iAttacker == 0 
		|| !IsClientInGame(iAttacker) 
		|| GetClientTeam(iAttacker) != TEAM_ZOMBIE 
		|| !IsPlayerAlive(iAttacker)
	) {
		return;
	}
	
	int iVictim = GetClientOfUserId(hEvent.GetInt("victim"));
	if (iVictim == 0 
		|| !IsClientInGame(iVictim)
		|| GetClientTeam(iVictim) != TEAM_SURVIVOR
		|| IsFakeClient(iVictim) 
		|| !IsPlayerAlive(iVictim)
	) {
		return;
	}
	
	PrintInflictedDamage(iVictim, iAttacker);
}

public void Event_SmokerAttackFirst(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iAttackerUserid = hEvent.GetInt("userid");
	int iAttacker = GetClientOfUserId(iAttackerUserid);
	int iVictimUserid = hEvent.GetInt("victim");
	int iVictim = GetClientOfUserId(iVictimUserid);
	
	if (iAttacker > 0 && iVictim > 0) {
		// int checks = 0;
		ArrayStack hEventMembers = new ArrayStack(2); // new ArrayStack(3)
		hEventMembers.Push(iAttackerUserid);
		hEventMembers.Push(iVictimUserid);
		// hEventMembers.Push(checks);

		// It takes exactly 1.0s of dragging to get paralyzed, so we'll give the timer additional 0.1s to update
		ClearTimer();
		g_hTongueParalyzeTimer = CreateTimer(1.1, CheckSurvivorState, hEventMembers, TIMER_FLAG_NO_MAPCHANGE | TIMER_HNDL_CLOSE);
	}
}

public Action CheckSurvivorState(Handle hTimer, ArrayStack hEventMembers)
{
	/* Fix warning 204: symbol is assigned a value that is never used: "checks"*/
	if (!hEventMembers.Empty) {
		// int checks = hEventMembers.Pop();
		int iVictim = GetClientOfUserId(hEventMembers.Pop());
		int iAttacker = GetClientOfUserId(hEventMembers.Pop());
		if (iVictim > 0 && iAttacker > 0) { //if players in game
			if (IsSurvivorParalyzed(iVictim)) {
				PrintInflictedDamage(iVictim, iAttacker);
			}
		}
	}
	
	// delete hEventMembers; // TIMER_HNDL_CLOSE, the timer will do for us
	
	g_hTongueParalyzeTimer = null;
	return Plugin_Stop;
}

public void Event_SmokerAttackSecond(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iAttacker = GetClientOfUserId(hEvent.GetInt("userid"));
	int iVictim = GetClientOfUserId(hEvent.GetInt("victim"));

	ClearTimer();
	PrintInflictedDamage(iVictim, iAttacker);
}

/*
 * Table: m_tongueVictimTimer (offset 13288) (type DT_IntervalTimer)
 * Member: m_timestamp (offset 4) (type float) (bits 0) (NoScale)
*/
bool IsSurvivorParalyzed(int iClient)
{
	int iTongueOwner = GetEntProp(iClient, Prop_Send, "m_tongueOwner");
	if (iTongueOwner != -1) {
		float fVictimTimer = GetGameTime() - GetEntPropFloat(iClient, Prop_Send, "m_tongueVictimTimer", ARRAY_INDEX_TIMESTAMP);
		return (fVictimTimer >= 1.0);
	}
	
	return false;
}

void PrintInflictedDamage(int iSurvivor, int iInfected)
{
	float fGameTime = GetGameTime();
	
	// Used as a workaround to prevent double prints that might happen for Charger/Smoker
	if ((g_fReported[iSurvivor][iInfected] + g_fGhostDelay) >= fGameTime) {
		return;
	}
	
	if (g_iDamage[iSurvivor][iInfected] == 0) { // Don't bother
		return;
	}
	
	int iZClass = GetEntProp(iInfected, Prop_Send, "m_zombieClass");
	
	PrintToChat(iSurvivor, "\x04[DmgReport]\x01 \x03%N\x01(\x04%s\x01) took \x05%d\x01 damage from you!", iInfected, L4D2_InfectedNames[iZClass], g_iDamage[iSurvivor][iInfected]);

	g_fReported[iSurvivor][iInfected] = GetGameTime();
	g_iDamage[iSurvivor][iInfected] = 0;
}

int IsTargetedSi(int iClient)
{
	int iZClass = GetEntProp(iClient, Prop_Send, "m_zombieClass");

	if (iZClass == L4D2Infected_Smoker
		|| iZClass == L4D2Infected_Hunter
		|| iZClass == L4D2Infected_Jockey
		|| iZClass == L4D2Infected_Charger
	) {
		return iZClass;
	}
	
	return -1;
}

void ClearTimer()
{
	if (g_hTongueParalyzeTimer != null) {
		KillTimer(g_hTongueParalyzeTimer);
		g_hTongueParalyzeTimer = null;
	}
}
