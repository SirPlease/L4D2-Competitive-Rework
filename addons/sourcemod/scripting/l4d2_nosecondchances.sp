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

#define TEAM_INFECTED 3

static const char L4D2_SI_Victim_NetProps[][] = {
	"",
	"m_tongueVictim",	// Smoker
	"",
	"m_pounceVictim",	// Hunter
	"",
	"m_jockeyVictim",    // Jockey
	"m_pummelVictim",    // Charger
	"",
	""
};

ConVar bot_kick_delay;

public Plugin myinfo = 
{
	name = "L4D2 No Second Chances",
	author = "Visor, Jacob, A1m`",
	description = "Previously human-controlled SI bots with a cap won't die",
	version = "1.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	HookEvent("player_bot_replace", PlayerBotReplace);
	
	bot_kick_delay = CreateConVar("bot_kick_delay", "0", "How long should we wait before kicking infected bots?", _, true, 0.0, true, 30.0);
}

public void PlayerBotReplace(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int iUserID = hEvent.GetInt("bot");
	int iBot = GetClientOfUserId(iUserID);

	if (IsClientInGame(iBot) && GetClientTeam(iBot) == TEAM_INFECTED && IsFakeClient(iBot)) {
		float delay = bot_kick_delay.FloatValue;
		if (delay >= 1.0) {
			CreateTimer(delay, KillBot, iUserID, TIMER_FLAG_NO_MAPCHANGE);
		} else if (ShouldBeKicked(iBot)) {
			ForcePlayerSuicide(iBot);
		}
	}
}

bool ShouldBeKicked(int iBot)
{
	int iZombieClassType = GetEntProp(iBot, Prop_Send, "m_zombieClass");
	
	if (strlen(L4D2_SI_Victim_NetProps[iZombieClassType]) == 0) {
		return false;
	}
	
	if (GetEntPropEnt(iBot, Prop_Send, L4D2_SI_Victim_NetProps[iZombieClassType]) != -1) {
		return false;
	}

	return true;
}

public Action KillBot(Handle hTimer, any iUserID)
{
	int iBot = GetClientOfUserId(iUserID);
	if (iBot > 0 && ShouldBeKicked(iBot))
	{
		ForcePlayerSuicide(iBot);
	}
}
