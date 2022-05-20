#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define DEBUG 0

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
	author = "Jahze, Sir, A1m`",
	version = "1.0",
	description = "Provides the ability to remove Gascans, Propane, Oxygen Tanks and Fireworks",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	g_hCvarNoCans = CreateConVar("l4d_no_cans", "1", "Remove Gascans?", _, true, 0.0, true, 1.0);
	g_hCvarNoPropane = CreateConVar("l4d_no_propane", "1", "Remove Propane Tanks?", _, true, 0.0, true, 1.0);
	g_hCvarNoOxygen = CreateConVar("l4d_no_oxygen", "1", "Remove Oxygen Tanks?", _, true, 0.0, true, 1.0);
	g_hCvarNoFireworks = CreateConVar("l4d_no_fireworks", "1", "Remove Fireworks?", _, true, 0.0, true, 1.0);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void Event_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	CreateTimer(1.0, Timer_RoundStartDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	// Some canisters will spawn much later. For example a map c2m1_highway
	CreateTimer(10.0, Timer_RoundStartDelay, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_RoundStartDelay(Handle hTimer)
{
	int iEntity = -1;

	while ((iEntity = FindEntityByClassname(iEntity, "prop_physics")) != -1) {
		if (!IsValidEdict(iEntity) || !IsCan(iEntity)) {
			continue;
		}

		RemoveEntity(iEntity);
	}

	return Plugin_Stop;
}

bool IsCan(int iEntity)
{
	if (GetEntProp(iEntity, Prop_Send, "m_isCarryable", 1) < 1) {
		return false;
	}

	char sModelName[PLATFORM_MAX_PATH];
	GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));

#if DEBUG
	char sEntityName[64];
	GetEdictClassname(iEntity, sEntityName, sizeof(sEntityName));
	PrintToChatAll("iEntity: %d (%s), model: %s", iEntity, sEntityName, sModelName);
#endif

	if (strcmp(sModelName, CAN_GASCAN, false) == 0) {
		return (g_hCvarNoCans.BoolValue);
	} else if (strcmp(sModelName, CAN_PROPANE, false) == 0) {
		return (g_hCvarNoPropane.BoolValue);
	} else if (strcmp(sModelName, CAN_OXYGEN, false) == 0) {
		return (g_hCvarNoOxygen.BoolValue);
	} else if (strcmp(sModelName, CAN_FIREWORKS, false) == 0) {
		return (g_hCvarNoFireworks.BoolValue);
	}

	return false;
}
