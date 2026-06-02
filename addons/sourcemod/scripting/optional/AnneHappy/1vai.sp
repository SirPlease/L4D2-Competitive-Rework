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
#include <sdkhooks>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "1vai function(quick standup, give damage and release survivor)",
	author = "东",
	description = "A plugin designed to support 1vAI.",
	version = "1.2",
	url = "https://github.com/fantasylidong/CompetitiveWithAnne"
};

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	SDKHook(client, SDKHook_PostThinkPost, CancelGetup);	
	return Plugin_Continue;
}

public Action CancelGetup(int client)
{
	if (IsClientAndInGame(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flCycle", 1000.0, 0);
	}
	return Plugin_Continue;
}

stock bool IsClientAndInGame(int iClient)
{
	return (iClient > 0 && IsClientInGame(iClient));
}
