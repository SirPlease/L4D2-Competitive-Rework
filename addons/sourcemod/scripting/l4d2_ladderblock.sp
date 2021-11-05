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

#define PLUGIN_VERSION		"1.2"

int
	g_iCvarFlags = 0,
	g_iCvarImmune = 0;

ConVar
	g_hFlags = null,
	g_hImmune = null;

bool
	g_bLoadLate = false,
	g_iInCharge[MAXPLAYERS + 1] = {false, ...};

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

public void OnClientPutInServer(int iClient)
{
	g_iInCharge[iClient] = false;

	if (g_iCvarFlags) {
		SDKHook(iClient, SDKHook_Touch, SDKHook_cb_Touch);
	}
}

public void Charging(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iCharger = GetClientOfUserId(hEvent.GetInt("userid"));
	g_iInCharge[iCharger] = true;
}

public void NotCharging(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iCharger = GetClientOfUserId(hEvent.GetInt("userid"));
	g_iInCharge[iCharger] = false;
}

public Action SDKHook_cb_Touch(int iEntity, int iOther)
{
	if (iOther > MaxClients || iOther < 1) {
		return Plugin_Continue;
	}

	if (IsGuyTroll(iEntity, iOther)) {
		int iClass = GetEntProp(iEntity, Prop_Send, "m_zombieClass");
		
		if (iClass != 5 && g_iCvarFlags & (1 << iClass)) {
			// Tank AI and Witch have this skill but Valve method is sucks because ppl get STUCKS!
			if (iClass == 8 && IsFakeClient(iEntity)) {
				return Plugin_Continue;
			}
			
			iClass = GetEntProp(iOther, Prop_Send, "m_zombieClass");

			/* @A1m`:
			 * Can use netprop m_carryVictim, I'll do it later if I remember))
			*/
			if (g_iCvarImmune & (1 << iClass) || g_iInCharge[iOther]) {
				return Plugin_Continue;
			}
			
			if (GetEntityMoveType(iOther) == MOVETYPE_LADDER) {
				float fOrigin[3];
				GetClientAbsOrigin(iOther, fOrigin);
				fOrigin[2] += 2.5;
				TeleportEntity(iOther, fOrigin, NULL_VECTOR, NULL_VECTOR);
			} else {
				TeleportEntity(iOther, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 251.0}));
			}
		}
	}
	return Plugin_Continue;
}

bool IsGuyTroll(int iVictim, int iTroll)
{
	return (GetEntityMoveType(iVictim) == MOVETYPE_LADDER
		&& GetClientTeam(iVictim) != GetClientTeam(iTroll)
		&& GetEntPropFloat(iVictim, Prop_Send, "m_vecOrigin[2]") < GetEntPropFloat(iTroll, Prop_Send, "m_vecOrigin[2]"));
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

public void OnCvarChange_Flags(ConVar hConvar, const char[] sOldValue, const char[] sNewValue)
{
	if (strcmp(sOldValue, sNewValue) == 0) {
		return;
	}

	g_iCvarFlags = g_hFlags.IntValue;

	if (!StringToInt(sOldValue)) {
		ST_ToogleHook(true);
	} else if (!g_iCvarFlags) {
		ST_ToogleHook(false);
	}
}

public void OnCvarChange_Immune(ConVar hConvar, const char[] sOldValue, const char[] sNewValue)
{
	if (strcmp(sOldValue, sNewValue) != 0) {
		g_iCvarImmune = g_hImmune.IntValue;
	}
}

void ST_GetCvars()
{
	g_iCvarFlags = g_hFlags.IntValue;
	g_iCvarImmune = g_hImmune.IntValue;
}
