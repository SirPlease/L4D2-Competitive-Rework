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
#include <colors>

new const String:SI_Names[][] =
{
	"Unknown",
	"Smoker",
	"Boomer",
	"Hunter",
	"Spitter",
	"Jockey",
	"Charger",
	"Witch",
	"Tank",
	"Not SI"
};

new Handle:hCvarDmgThreshold;

public Plugin:myinfo =
{
	name = "1v1 EQ",
	author = "Blade + Confogl Team, Tabun, Visor",
	description = "A plugin designed to support 1v1.",
	version = "0.1.1",
	url = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{      
	hCvarDmgThreshold = CreateConVar("sm_1v1_dmgthreshold", "24", "Amount of damage done (at once) before SI suicides.", FCVAR_NONE, true, 1.0);

	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
}
 
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsClientAndInGame(attacker))
		return;

	new damage = GetEventInt(event, "dmg_health");
	new zombie_class = GetZombieClass(attacker);

	if (GetClientTeam(attacker) == 3 && zombie_class != 8 && damage >= GetConVarInt(hCvarDmgThreshold))
	{
		new remaining_health = GetClientHealth(attacker);
		CPrintToChatAll("[{olive}1v1{default}] {red}%N{default}({green}%s{default}) had {olive}%d{default} health remaining!", attacker, SI_Names[zombie_class], remaining_health);

		ForcePlayerSuicide(attacker);    

		if (remaining_health == 1)
		{
			CPrintToChat(victim, "You don't have to be mad...");
		}
	}
}

stock GetZombieClass(client) return GetEntProp(client, Prop_Send, "m_zombieClass");

stock bool:IsClientAndInGame(index)
{
	if (index > 0 && index <= MaxClients)
	{
		return IsClientInGame(index);
	}
	return false;
}