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
	with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <l4d2util_constants>

#define TAUNT_HIGH_THRESHOLD            0.4
#define TAUNT_MID_THRESHOLD             0.2
#define TAUNT_LOW_THRESHOLD             0.04

static char SINames[7][] =
{
	"",
    "gas",          // smoker
    "exploding",    // boomer
    "hunter",
    "spitter",
    "jockey",
    "charger",
};

ConVar
	g_hCvarPvEMode = null,
	g_hSpecialInfectedHP[7],
	g_hCvarDmgThreshold = null;

public Plugin myinfo =
{
	name = "1v1 EQ",
	author = "Blade + Confogl Team, Tabun, Visor",
	description = "A plugin designed to support 1v1.",
	version = "0.2.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	char buffer[17];
	for (int i = 1; i < 7; i++)
	{
		Format(buffer, sizeof(buffer), "z_%s_health", SINames[i]);
		g_hSpecialInfectedHP[i] = FindConVar(buffer);
	}
	LoadTranslations("1v1.phrases");
	g_hCvarDmgThreshold = CreateConVar("sm_1v1_dmgthreshold", "24", "Amount of damage done (at once) before SI suicides.", _, true, 1.0);
	g_hCvarPvEMode = CreateConVar("sm_1v1_PvEMode", "0", "Is this Mode Is PvE.", _, true, 0.0, true, 1.0);

	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
}

void Event_PlayerHurt(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int fDamage = hEvent.GetInt("dmg_health");
	if (fDamage < g_hCvarDmgThreshold.IntValue) {
		return;
	}
	
	int iAttackerId = hEvent.GetInt("attacker");
	int iAttacker = GetClientOfUserId(iAttackerId);
	if (!IsClientAndInGame(iAttacker) || GetClientTeam(iAttacker) != L4D2Team_Infected) {
		return;
	}
	
	int iZclass = GetEntProp(iAttacker, Prop_Send, "m_zombieClass");
	
	if (iZclass < L4D2Infected_Smoker || iZclass > L4D2Infected_Charger) {
		return;
	}
	
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	if (!IsClientAndInGame(iVictim) || GetClientTeam(iVictim) != L4D2Team_Survivor) {
		return;
	}
	
	int iRemainingHealth = GetClientHealth(iAttacker);

	// [1v1] Player (Hunter) had 250 health remaining!
	// [1v1] [BOT] Hunter had 250 health remaining!
	
	char sName[MAX_NAME_LENGTH];
	if (IsFakeClient(iAttacker)) {
		Format(sName, sizeof(sName), "%t", "AI");
	} else {
		GetClientName(iAttacker, sName, sizeof(sName));
	}
	if(g_hCvarPvEMode.BoolValue)
	{
		CPrintToChatAll("%t %t", "TagPvE", "HealthRemaining", sName, L4D2_InfectedNames[iZclass], iRemainingHealth);
	}
	else
	{
		CPrintToChatAll("%t %t", "Tag", "HealthRemaining", sName, L4D2_InfectedNames[iZclass], iRemainingHealth);
	}
	
	RequestFrame(NextFrame_PlayerHurt, iAttackerId);
	
	int maxHealth = g_hSpecialInfectedHP[iZclass].IntValue;
	if (iRemainingHealth == 1) {
		CPrintToChat(iVictim, "%t", "UMad");
	}
	else if (iRemainingHealth <= RoundToCeil(maxHealth * TAUNT_LOW_THRESHOLD))
    {
		CPrintToChat(iVictim, "%t", "Sad");
	}
	else if (iRemainingHealth <= RoundToCeil(maxHealth * TAUNT_MID_THRESHOLD))
    {
		CPrintToChat(iVictim, "%t", "Close");
    }
	else if (iRemainingHealth <= RoundToCeil(maxHealth * TAUNT_HIGH_THRESHOLD))
	{
		CPrintToChat(iVictim, "%t", "NBad");
	}
}

void NextFrame_PlayerHurt(int userid)
{
	int iAttacker = GetClientOfUserId(userid);
	if (!IsClientAndInGame(iAttacker) || GetClientTeam(iAttacker) != L4D2Team_Infected || !IsPlayerAlive(iAttacker)) {
		return;
	}

	int iZclass = GetEntProp(iAttacker, Prop_Send, "m_zombieClass");
	
	if (iZclass < L4D2Infected_Smoker || iZclass > L4D2Infected_Charger) {
		return;
	}
	
	ForcePlayerSuicide(iAttacker);
}

bool IsClientAndInGame(int iClient)
{
	return (iClient > 0 && IsClientInGame(iClient));
}
