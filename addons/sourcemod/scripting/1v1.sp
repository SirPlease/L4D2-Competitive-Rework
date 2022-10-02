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

ConVar
	g_hCvarDmgThreshold = null;

public Plugin myinfo =
{
	name = "1v1 EQ",
	author = "Blade + Confogl Team, Tabun, Visor",
	description = "A plugin designed to support 1v1.",
	version = "0.2.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	LoadTranslations("1v1.phrases");
	g_hCvarDmgThreshold = CreateConVar("sm_1v1_dmgthreshold", "24", "Amount of damage done (at once) before SI suicides.", _, true, 1.0);

	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
}

public void Event_PlayerHurt(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int fDamage = hEvent.GetInt("dmg_health");
	if (fDamage < g_hCvarDmgThreshold.IntValue) {
		return;
	}
	
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
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
	// [1v1] AI (Hunter) had 250 health remaining!
	
	char sName[MAX_NAME_LENGTH];
	if (IsFakeClient(iAttacker)) {
		Format(sName, sizeof(sName), "%t", "AI");
	} else {
		GetClientName(iAttacker, sName, sizeof(sName));
	}
	
	CPrintToChatAll("%t %t", "Tag", "HealthRemaining", sName, L4D2_InfectedNames[iZclass], iRemainingHealth);
	
	ForcePlayerSuicide(iAttacker);
	
	if (iRemainingHealth == 1) {
		CPrintToChat(iVictim, "%t", "UMad");
	}
}

bool IsClientAndInGame(int iClient)
{
	return (iClient > 0 && IsClientInGame(iClient));
}
