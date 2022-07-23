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

#define PLUGIN_VERSION "3.6"

public Plugin myinfo =
{
	name		= "L4D2 Equalise Alarm Cars",
	author		= "Jahze, Forgetest",
	version		= PLUGIN_VERSION,
	description	= "Make the alarmed car and its color spawns the same for each team in versus",
	url			= "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

enum alarmArray
{
	ENTRY_RELAY_ON,
	ENTRY_RELAY_OFF,
	ENTRY_START_STATE,
	ENTRY_ALARM_CAR,
	ENTRY_COLOR,
	
	alarmArray_SIZE
}
static const int NULL_ALARMARRAY[alarmArray_SIZE] = {-1, ...};
ArrayList
	g_aAlarmArray;

StringMap
	g_smCarNameMap;

ConVar
	g_cvStartDisabled,
	g_cvDebug;

bool
	g_bRoundIsLive,
	g_bIsSecondHalf;

#define RGBA_INT(%0,%1,%2,%3) (((%0)<<24) + ((%1)<<16) + ((%2)<<8) + (%3))
static const int g_iOffColors[] =
{
//	R,G,B,A
	RGBA_INT(99,	135,	157,	255),
	RGBA_INT(173,	186,	172,	255),
	RGBA_INT(52,	70,		114,	255),
	RGBA_INT(9,		41,		138,	255),
	RGBA_INT(68,	91,		183,	255),
	RGBA_INT(212,	158,	70,		255),
	RGBA_INT(84,	101,	144,	255),
	RGBA_INT(253,	251,	203,	255)
};

int GetRandomOffColor()
{
	return g_iOffColors[GetRandomInt(0, sizeof(g_iOffColors)-1)];
}

public void OnPluginStart()
{
	g_cvStartDisabled = CreateConVar("l4d_equalise_alarm_start_disabled", "1", "Makes alarmed cars spawn disabled before game goes live.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvDebug = CreateConVar("l4d_equalise_alarm_debug", "0", "Debug info for alarm stuff.", FCVAR_HIDDEN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	g_smCarNameMap = new StringMap();
	g_aAlarmArray = new ArrayList(alarmArray_SIZE);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundIsLive = false;
	CreateTimer(0.1, Timer_RoundStartDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(5.0, Timer_InitiateCars, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_RoundStartDelay(Handle timer)
{
	g_bIsSecondHalf = !!GameRules_GetProp("m_bInSecondHalfOfRound");
	
	if (!g_bIsSecondHalf)
	{
		g_smCarNameMap.Clear();
		g_aAlarmArray.Clear();
	}
	
	char sKey[64], sName[128];
	
	int ent = MaxClients+1;
	while ((ent = FindEntityByClassname(ent, "prop_car_alarm")) != INVALID_ENT_REFERENCE)
	{
		GetEntityName(ent, sName, sizeof(sName));
		if (ExtractCarName(sName, "caralarm_car1", sKey, sizeof(sKey)) != 0)
		{
			int entry = -1;
			if (!g_smCarNameMap.GetValue(sKey, entry)) // creates a new entry
			{
				entry = g_aAlarmArray.PushArray(NULL_ALARMARRAY);
				g_smCarNameMap.SetValue(sKey, entry);
				g_aAlarmArray.Set(entry, EntIndexToEntRef(ent), ENTRY_ALARM_CAR);
			}
			else // updates the alarm car index
			{
				g_aAlarmArray.Set(entry, EntIndexToEntRef(ent), ENTRY_ALARM_CAR);
			}
		}
	}
	
	ent = MaxClients+1;
	while ((ent = FindEntityByClassname(ent, "logic_relay")) != INVALID_ENT_REFERENCE)
	{
		GetEntityName(ent, sName, sizeof(sName));
		
		int entry = -1;
		if ((entry = StrContains(sName, "relay_caralarm_o")) != -1)
		{
			bool type = (sName[entry+16] == 'n');
			
			ExtractCarName(sName,
							type ? "relay_caralarm_on" : "relay_caralarm_off",
							sKey, sizeof(sKey));
			
			if (g_smCarNameMap.GetValue(sKey, entry))
			{
				g_aAlarmArray.Set(entry,
									ent,
									type ? ENTRY_RELAY_ON : ENTRY_RELAY_OFF);
				
				HookSingleEntityOutput(ent,
										"OnTrigger",
										type ? EntO_AlarmRelayOnTriggered : EntO_AlarmRelayOffTriggered);
			}
		}
	}
	
	ent = MaxClients+1;
	while ((ent = FindEntityByClassname(ent, "logic_case")) != INVALID_ENT_REFERENCE)
	{
		GetEntityName(ent, sName, sizeof(sName));
		if (ExtractCarName(sName, "case_car_color_off", sKey, sizeof(sKey)) != 0)
		{
			int entry = -1;
			if (g_smCarNameMap.GetValue(sKey, entry))
			{
				RemoveEntity(ent);
			}
		}
	}
	
	CreateTimer(g_bIsSecondHalf ? 3.0 : 20.0, Timer_DebugPrints, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

Action Timer_InitiateCars(Handle timer)
{
	if (!g_bIsSecondHalf && g_cvStartDisabled.BoolValue)
	{
		DisableCars();
	}
	
	return Plugin_Stop;
}

void EntO_AlarmRelayOnTriggered(const char[] output, int caller, int activator, float delay)
{
	int entry = g_aAlarmArray.FindValue(caller, ENTRY_RELAY_ON);
	if (entry == -1)
	{
		// this should not happen...
		ThrowEntryError(ENTRY_RELAY_ON, caller);
	}
	
	PrintDebug("\x03(ALARM) #%i: relay_on [activator: %i | delay: %.2f]", entry, activator, delay);
	
	if (IsValidEntity(activator) && !activator)
	{
		RequestFrame(ResetCarColor, entry);
		return;
	}
	
	if (!g_bIsSecondHalf)
	{
		// first half, record
		g_aAlarmArray.Set(entry, true, ENTRY_START_STATE);
		RequestFrame(RecordCarColor, entry);
	}
	else if (!g_aAlarmArray.Get(entry, ENTRY_START_STATE) || (g_cvStartDisabled.BoolValue && !g_bRoundIsLive))
	{
		// second half, but differs from first half / needs start disabled
		int relayOff = g_aAlarmArray.Get(entry, ENTRY_RELAY_OFF);
		CreateTimer(delay + 0.1, Timer_SafeRelayTrigger, relayOff, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		// second half, the same as first half
		RequestFrame(ResetCarColor, entry);
	}
}

void EntO_AlarmRelayOffTriggered(const char[] output, int caller, int activator, float delay)
{
	int entry = g_aAlarmArray.FindValue(caller, ENTRY_RELAY_OFF);
	if (entry == -1)
	{
		// this should not happen...
		ThrowEntryError(ENTRY_RELAY_OFF, caller);
	}
	
	PrintDebug("\x05(ALARM) #%i: relay_off [activator: %i | delay: %.2f]", entry, activator, delay);
	
	// If a car is turned off because of a tank punch or because it was
	// triggered the activator is the car itself. When the cars get
	// randomised the activator is the player who entered the trigger area.
	if (IsValidEntity(activator) && (!activator || activator > MaxClients))
	{
		RequestFrame(ResetCarColor, entry);
		return;
	}
	
	if (!g_bIsSecondHalf)
	{
		// first half, record
		g_aAlarmArray.Set(entry, false, ENTRY_START_STATE);
		g_aAlarmArray.Set(entry, GetRandomOffColor(), ENTRY_COLOR);
		RequestFrame(ResetCarColor, entry);
	}
	else if (g_aAlarmArray.Get(entry, ENTRY_START_STATE) && (!g_cvStartDisabled.BoolValue || g_bRoundIsLive))
	{
		// second half, but differs from first half, and not start disabled
		int relayOn = g_aAlarmArray.Get(entry, ENTRY_RELAY_ON);
		CreateTimer(delay + 0.1, Timer_SafeRelayTrigger, relayOn, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		// second half, the same as first half
		RequestFrame(ResetCarColor, entry);
	}
}

void Event_PlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bRoundIsLive)
	{
		g_bRoundIsLive = true;
		EnableCars();
	}
}

void EnableCars()
{
	for (int i = 0; i < g_aAlarmArray.Length; ++i)
	{
		int relayOn = g_aAlarmArray.Get(i, ENTRY_RELAY_ON);
		
		if (relayOn != -1 && g_aAlarmArray.Get(i, ENTRY_START_STATE))
		{
			Timer_SafeRelayTrigger(null, relayOn);
		}
	}
}

stock void DisableCars()
{
	for (int i = 0; i < g_aAlarmArray.Length; ++i)
	{
		int relayOff = g_aAlarmArray.Get(i, ENTRY_RELAY_OFF);
		
		if (relayOff != -1 && g_aAlarmArray.Get(i, ENTRY_START_STATE))
		{
			Timer_SafeRelayTrigger(null, relayOff);
		}
	}
}

void RecordCarColor(int entry)
{
	int alarmCar = EntRefToEntIndex(g_aAlarmArray.Get(entry, ENTRY_ALARM_CAR));
	g_aAlarmArray.Set(entry, GetEntityRenderColorEx(alarmCar), ENTRY_COLOR);
}

void ResetCarColor(int entry)
{
	int alarmCar = EntRefToEntIndex(g_aAlarmArray.Get(entry, ENTRY_ALARM_CAR));
	SetEntityRenderColorEx(alarmCar, g_aAlarmArray.Get(entry, ENTRY_COLOR));
}

Action Timer_SafeRelayTrigger(Handle timer, int relay)
{
	if (relay == -1)
		return Plugin_Stop;
	
	AcceptEntityInput(relay, "Trigger", 0);
	return Plugin_Stop;
}

int ExtractCarName(const char[] sName, const char[] sCompare, char[] sBuffer, int iSize)
{
	int index = SplitString(sName, "-", sBuffer, iSize);
	if (index == -1) {
		// Spilt delimiter doesn't exist.
		return 0;
	}
	
	if (strcmp(sName[index], sCompare)) {
		// Compare string is before spilt delimiter.
		strcopy(sBuffer, iSize, sName[index]);
		return -1;
	}
	
	// Compare string is after spilt delimiter.
	return 1;
}

void GetEntityName(int entity, char[] buffer, int maxlen)
{
	GetEntPropString(entity, Prop_Data, "m_iName", buffer, maxlen);
}

int GetEntityRenderColorEx(int entity)
{
	int r, g, b, a;
	GetEntityRenderColor(entity, r, g, b, a);
	return (r << 24) + (g << 16) + (b << 8) + a;
}

void SetEntityRenderColorEx(int entity, int color)
{
	int r, g, b, a;
	ExtractColorBytes(color, r, g, b, a);
	SetEntityRenderColor(entity, r, g, b, a);
}

Action Timer_DebugPrints(Handle timer)
{
	StringMapSnapshot ss = g_smCarNameMap.Snapshot();
	char sName[128];
	int entry;
	
	for (int i = 0; i < ss.Length; ++i)
	{
		ss.GetKey(i, sName, sizeof(sName));
		g_smCarNameMap.GetValue(sName, entry);
		
		int r, g, b, a;
		ExtractColorBytes(g_aAlarmArray.Get(entry, ENTRY_COLOR), r, g, b, a);
		
		PrintDebug("\x04(ALARM) #%i [ %s | %s | %s | %s | %i %i %i ]",
					entry,
					g_aAlarmArray.Get(entry, ENTRY_RELAY_ON) == -1 ? "null" : "valid",
					g_aAlarmArray.Get(entry, ENTRY_RELAY_OFF) == -1 ? "null" : "valid",
					g_aAlarmArray.Get(entry, ENTRY_START_STATE) ? "On" : "Off",
					g_aAlarmArray.Get(entry, ENTRY_ALARM_CAR) == -1 ? "null" : "valid",
					r, g, b);
	}
	
	delete ss;
	
	return Plugin_Stop;
}

void PrintDebug(const char[] format, any ...)
{
	if (g_cvDebug.BoolValue)
	{
		char msg[256];
		VFormat(msg, sizeof(msg), format, 2);
		PrintToChatAll("%s", msg);
	}
}

stock void ExtractColorBytes(int color, int &r, int &g, int &b, int &a)
{
	r = (color & 0xFF000000) >> 24;
	g = (color & 0x00FF0000) >> 16;
	b = (color & 0x0000FF00) >> 8;
	a = (color & 0x000000FF);
}

stock void ThrowEntryError(alarmArray entry, int entity)
{
	char sName[128];
	GetEntityName(entity, sName, sizeof(sName));
	ThrowError("Fatal: Could not find entry (#%i) for %s", entry, sName);
}

stock void ThrowEmptyError(alarmArray entry, int entity)
{
	char sName[128];
	GetEntityName(entity, sName, sizeof(sName));
	ThrowError("Fatal: Could not get data (#%i) for %s", entry, sName);
}