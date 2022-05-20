#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

bool
	g_bNoCans = true,
	g_bNoPropane = true,
	g_bNoOxygen = true,
	g_bNoFireworks = true;

public const char
	CAN_GASCAN[] = "models/props_junk/gascan001a.mdl",
	CAN_PROPANE[] = "models/props_junk/propanecanister001a.mdl",
	CAN_OXYGEN[] = "models/props_equipment/oxygentank01.mdl",
	CAN_FIREWORKS[] = "models/props_junk/explosive_box001.mdl";

ConVar
	g_hCvarNoCans = null,
	g_hCvarNoPropane = null,
	g_hCvarNoOxygen = null,
	g_hCvarNoFireworks = null;

public Plugin myinfo =
{
	name = "L4D2 Remove Cans",
	author = "Jahze, Sir",
	version = "0.6",
	description = "Provides the ability to remove Gascans, Propane, Oxygen Tanks and Fireworks"
};

public void OnPluginStart()
{
	g_hCvarNoCans = CreateConVar("l4d_no_cans", "1", "Remove Gascans?", FCVAR_NONE);
	g_hCvarNoPropane = CreateConVar("l4d_no_propane", "1", "Remove Propane Tanks?", FCVAR_NONE);
	g_hCvarNoOxygen = CreateConVar("l4d_no_oxygen", "1", "Remove Oxygen Tanks?", FCVAR_NONE);
	g_hCvarNoFireworks = CreateConVar("l4d_no_fireworks", "1", "Remove Fireworks?", FCVAR_NONE);

	g_hCvarNoCans.AddChangeHook(NoCansChange);
	g_hCvarNoPropane.AddChangeHook(NoPropaneChange);
	g_hCvarNoOxygen.AddChangeHook(NoOxygenChange);
	g_hCvarNoFireworks.AddChangeHook(NoFireworksChange);

	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

public void Event_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	CreateTimer(1.0, Timer_RoundStartDelay, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void NoCansChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if (StringToInt(sNewValue) == 0) {
		g_bNoCans = false;
	} else {
		g_bNoCans = true;
	}
}

public void NoPropaneChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if (StringToInt(sNewValue) == 0) {
		g_bNoPropane = false;
	} else {
		g_bNoPropane = true;
	}
}

public void NoOxygenChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if (StringToInt(sNewValue) == 0) {
		g_bNoOxygen = false;
	} else {
		g_bNoOxygen = true;
	}
}

public void NoFireworksChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if (StringToInt(sNewValue) == 0) {
		g_bNoFireworks = false;
	} else {
		g_bNoFireworks = true;
	}
}

public Action Timer_RoundStartDelay(Handle hTimer)
{
	int iEntity = -1;

	while ((iEntity = FindEntityByClassname(iEntity, "prop_physics")) != -1) {
		if (!IsValidEdict(iEntity) || !IsValidEntity(iEntity)) {
			continue;
		}

		// Let's see what we got here!
		if (IsCan(iEntity)) {
			AcceptEntityInput(iEntity, "Kill");
		}
	}

	return Plugin_Stop;
}

bool IsCan(int iEntity)
{
	char sModelName[128];
	GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));

	if (view_as<bool>(GetEntProp(iEntity, Prop_Send, "m_isCarryable", 1))) {
		if (strcmp(sModelName, CAN_GASCAN, false) == 0 && g_bNoCans) {
			return true;
		} else if (strcmp(sModelName, CAN_PROPANE, false) == 0 && g_bNoPropane) {
			return true;
		} else if (strcmp(sModelName, CAN_OXYGEN, false) == 0 && g_bNoOxygen) {
			return true;
		} else if (strcmp(sModelName, CAN_FIREWORKS, false) == 0 && g_bNoFireworks) {
			return true;
		}
	}

	return false;
}
