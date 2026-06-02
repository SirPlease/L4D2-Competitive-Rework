/*
	SourcePawn is Copyright (C) 2006-2015 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2015 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2015 ITB CompuPhase.
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

#include <colors>
#include <sourcemod>

#define L4D_TEAM_SPECTATOR 1

public Plugin myinfo =
{
	name        = "Block Trolls",
	description = "Prevents calling votes while others are loading",
	author      = "ProdigySim, CanadaRox, darkid",
	version     = "2.0.1.2",
	url         = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

bool g_bBlockCallvote = false;
int  loadedPlayers 	  = 0;

public void OnPluginStart()
{
	LoadTranslations("blocktrolls.phrases");
	AddCommandListener(Vote_Listener, "callvote");
	AddCommandListener(Vote_Listener, "vote");
	HookEvent("player_team", Event_OnPlayerJoin);
}

public void OnMapStart()
{
	g_bBlockCallvote = true;
	loadedPlayers    = 0;
	CreateTimer(40.0, EnableCallvoteTimer);
}

void Event_OnPlayerJoin(Event event, char[] name, bool dontBroadcast)
{
	if (event.GetInt("oldteam") == 0)
	{
		loadedPlayers++;

		if (loadedPlayers == 6)
			g_bBlockCallvote = false;
	}
}

Action Vote_Listener(int client, const char[] command, int argc)
{
	if (!client)
	{
		ReplyToCommand(client, "%T", "NotConsoleVote", LANG_SERVER);
		return Plugin_Handled;
	}

	if (!IsClientInGame(client))
		return Plugin_Handled;

	if (g_bBlockCallvote)
	{
		CPrintToChat(client, "%t %t", "Tag", "VotingNotEnabled");
		return Plugin_Handled;
	}

	if (GetClientTeam(client) == L4D_TEAM_SPECTATOR)
	{
		CPrintToChat(client, "%t %t", "Tag", "NotSpectatorVote");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

Action EnableCallvoteTimer(Handle timer)
{
	g_bBlockCallvote = false;
	return Plugin_Stop;
}