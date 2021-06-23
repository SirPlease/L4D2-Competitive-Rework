#define PLUGIN_VERSION 		"1.0"

/*
* ============================================================================
*
*  Description:	Prevents people from blocking players who climb on the ladder.
*
*  Credits:		Original code taken from Rotoblin2 project
*					written by Me and ported to l4d2.
*					See rotoblin.ExpolitFixes.sp module
*
*	Site:			http://code.google.com/p/rotoblin2/
*
*  Copyright (C) 2012 raziEiL <war4291@mail.ru>
*
*  This program is free software: you can redistribute it and/or modify
*  it under the terms of the GNU General Public License as published by
*  the Free Software Foundation, either version 3 of the License, or
*  (at your option) any later version.
*
*  This program is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
* ============================================================================
*/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int
	g_iCvarFlags, 
	g_iCvarImmune,
	inCharge [MAXPLAYERS + 1];
	
ConVar
	g_hFlags,
	g_hImmune;

bool
	g_bLoadLate;

public Plugin myinfo =
{
	name = "StopTrolls",
	author = "raziEiL [disawar1]",
	description = "Prevents people from blocking players who climb on the ladder.",
	version = PLUGIN_VERSION,
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2) {
		strcopy(error, err_max, "Plugin only support L4D2 engine");
		return APLRes_Failure;
	}

	g_bLoadLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("stop_trolls_version", PLUGIN_VERSION, "StopTrolls plugin version", FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hFlags = CreateConVar("stop_trolls_flags", "862", "Who can push trolls when climbs on the ladder. 0=Disable, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 64=Charger, 256=Tank, 512=Survivors, 862=All");
	g_hImmune = CreateConVar("stop_trolls_immune", "256", "What class is immune. 0=Disable, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 256=Tank, 512=Survivors, 894=All");
	//AutoExecConfig(true, "StopTrollss"); // If u want a cfg file uncomment it. But I don't like.

	HookEvent("charger_charge_start", Charging);
	HookEvent("charger_charge_end", NotCharging);

	HookConVarChange(g_hFlags, OnCvarChange_Flags);
	HookConVarChange(g_hImmune, OnCvarChange_Immune);
	ST_GetCvars();

	if (g_iCvarFlags && g_bLoadLate) {
		ST_ToogleHook(true);
	}
}

public void OnClientPutInServer(int client)
{
	inCharge[client] = 0;
	if (g_iCvarFlags) {
		SDKHook(client, SDKHook_Touch, SDKHook_cb_Touch);
	}
}

public void Charging(Event hEvent, const char[] name, bool dontBroadcast)
{
	int charger = GetClientOfUserId(hEvent.GetInt("userid"));
	inCharge[charger] = 1;
}

public void NotCharging(Event hEvent, const char[] name, bool dontBroadcast)
{
	int charger = GetClientOfUserId(hEvent.GetInt("userid"));
	inCharge[charger] = 0;
}

public Action SDKHook_cb_Touch(int entity, int other)
{
	if (other > MaxClients || other < 1) {
		return;
	}

	if (IsGuyTroll(entity, other)) {
		int iClass = GetEntProp(entity, Prop_Send, "m_zombieClass");
		
		if (iClass != 5 && g_iCvarFlags & (1 << iClass)) {
			// Tank AI and Witch have this skill but Valve method is sucks because ppl get STUCKS!
			if (iClass == 8 && IsFakeClient(entity)) {
				return;
			}
			
			iClass = GetEntProp(other, Prop_Send, "m_zombieClass");

			/* @A1m`:
			 * Can use netprop m_carryVictim, I'll do it later if I remember))
			*/
			if (g_iCvarImmune & (1 << iClass) || inCharge[other]) {
				return;
			}
			
			if (IsOnLadder(other)) {
				float vOrg[3];
				GetClientAbsOrigin(other, vOrg);
				vOrg[2] += 2.5;
				TeleportEntity(other, vOrg, NULL_VECTOR, NULL_VECTOR);
			} else {
				TeleportEntity(other, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 251.0}));
			}
		}
	}
}

bool IsGuyTroll(int victim, int troll)
{
	return (IsOnLadder(victim) && GetClientTeam(victim) != GetClientTeam(troll) && GetEntPropFloat(victim, Prop_Send, "m_vecOrigin[2]") < GetEntPropFloat(troll, Prop_Send, "m_vecOrigin[2]"));
}

bool IsOnLadder(int entity)
{
	return (GetEntityMoveType(entity) == MOVETYPE_LADDER);
}

void ST_ToogleHook(bool bHook)
{
	for (int i = 1; i <= MaxClients; i++){
		if (IsClientInGame(i)) {
			if (bHook) {
				SDKHook(i, SDKHook_Touch, SDKHook_cb_Touch);
			} else {
				SDKUnhook(i, SDKHook_Touch, SDKHook_cb_Touch);
			}
		}
	}
}

public void OnCvarChange_Flags(ConVar hConvar, const char[] oldValue, const char[] newValue)
{
	if (StrEqual(oldValue, newValue)) {
		return;
	}

	g_iCvarFlags = g_hFlags.IntValue;

	if (!StringToInt(oldValue)) {
		ST_ToogleHook(true);
	} else if (!g_iCvarFlags) {
		ST_ToogleHook(false);
	}
}

public void OnCvarChange_Immune(ConVar hConvar, const char[] oldValue, const char[] newValue)
{
	if (!StrEqual(oldValue, newValue)) {
		g_iCvarImmune = g_hImmune.IntValue;
	}
}

void ST_GetCvars()
{
	g_iCvarFlags = g_hFlags.IntValue;
	g_iCvarImmune = g_hImmune.IntValue;
}
