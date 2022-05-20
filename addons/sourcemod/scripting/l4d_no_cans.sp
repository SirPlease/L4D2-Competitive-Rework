#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

bool
	bNoCans = true,
	bNoPropane = true,
	bNoOxygen = true,
	bNoFireworks = true;

public const char
	CAN_GASCAN[] = "models/props_junk/gascan001a.mdl",
	CAN_PROPANE[] = "models/props_junk/propanecanister001a.mdl",
	CAN_OXYGEN[] = "models/props_equipment/oxygentank01.mdl",
	CAN_FIREWORKS[] = "models/props_junk/explosive_box001.mdl";

ConVar
	cvar_noCans = null,
	cvar_noPropane = null,
	cvar_noOxygen = null,
	cvar_noFireworks = null;

public Plugin myinfo =
{
	name = "L4D2 Remove Cans",
	author = "Jahze, Sir",
	version = "0.5",
	description = "Provides the ability to remove Gascans, Propane, Oxygen Tanks and Fireworks"
};

public void OnPluginStart()
{
	cvar_noCans = CreateConVar("l4d_no_cans", "1", "Remove Gascans?", FCVAR_NONE);
	cvar_noPropane = CreateConVar("l4d_no_propane", "1", "Remove Propane Tanks?", FCVAR_NONE);
	cvar_noOxygen = CreateConVar("l4d_no_oxygen", "1", "Remove Oxygen Tanks?", FCVAR_NONE);
	cvar_noFireworks = CreateConVar("l4d_no_fireworks", "1", "Remove Fireworks?", FCVAR_NONE);

	cvar_noCans.AddChangeHook(NoCansChange);
	cvar_noPropane.AddChangeHook(NoPropaneChange);
	cvar_noOxygen.AddChangeHook(NoOxygenChange);
	cvar_noFireworks.AddChangeHook(NoFireworksChange);

	HookEvent("round_start", RoundStartHook, EventHookMode_Post);
}

public void RoundStartHook(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	CreateTimer(1.0, RoundStartNoCans, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void NoCansChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if (StringToInt(sNewValue) == 0) {
		bNoCans = false;
	} else {
		bNoCans = true;
	}
}

public void NoPropaneChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if (StringToInt(sNewValue) == 0) {
		bNoPropane = false;
	} else {
		bNoPropane = true;
	}
}

public void NoOxygenChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if (StringToInt(sNewValue) == 0) {
		bNoOxygen = false;
	} else {
		bNoOxygen = true;
	}
}

public void NoFireworksChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if (StringToInt(sNewValue) == 0) {
		bNoFireworks = false;
	} else {
		bNoFireworks = true;
	}
}

public Action RoundStartNoCans(Handle hTimer)
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
		if (strcmp(sModelName, CAN_GASCAN, false) == 0 && bNoCans) {
			return true;
		} else if (strcmp(sModelName, CAN_PROPANE, false) == 0 && bNoPropane) {
			return true;
		} else if (strcmp(sModelName, CAN_OXYGEN, false) == 0 && bNoOxygen) {
			return true;
		} else if (strcmp(sModelName, CAN_FIREWORKS, false) == 0 && bNoFireworks) {
			return true;
		}
	}

	return false;
}
