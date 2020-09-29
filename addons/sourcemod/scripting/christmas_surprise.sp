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

#include <sourcemod>
#include <sdktools>
#include <colors>

public Plugin:myinfo =
{
	name = "Christmas Surprise",
	author = "Jacob",
	description = "Happy Holidays",
	version = "1.1",
	url = "https://github.com/jacob404/myplugins"
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public OnMapStart()
{
	CreateTimer(0.5, MakeSnow);
}

public Action:MakeSnow(Handle:timer)
{
	new iSnow = -1;
	while ((iSnow = FindEntityByClassname(iSnow , "func_precipitation")) != INVALID_ENT_REFERENCE) AcceptEntityInput(iSnow, "Kill");
	iSnow = -1;
	iSnow = CreateEntityByName("func_precipitation");
	if (iSnow != -1)
	{
		decl String:sMap[64], Float:vMins[3], Float:vMax[3], Float:vBuff[3];
		GetCurrentMap(sMap, 64);
		Format(sMap, sizeof(sMap), "maps/%s.bsp", sMap);
		PrecacheModel(sMap, true);
		DispatchKeyValue(iSnow, "model", sMap);
		DispatchKeyValue(iSnow, "preciptype", "3");
		GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMax);
		GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);
		SetEntPropVector(iSnow, Prop_Send, "m_vecMins", vMins);
		SetEntPropVector(iSnow, Prop_Send, "m_vecMaxs", vMax);
		vBuff[0] = vMins[0] + vMax[0];
		vBuff[1] = vMins[1] + vMax[1];
		vBuff[2] = vMins[2] + vMax[2];
		TeleportEntity(iSnow, vBuff, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(iSnow);
		ActivateEntity(iSnow);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.7, MakeSnow);
}