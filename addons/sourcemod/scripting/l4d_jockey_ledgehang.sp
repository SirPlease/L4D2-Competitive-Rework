#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define ARRAY_INDEX_DURATION 0
#define ARRAY_INDEX_TIMESTAMP 1

float fLedgeHangInterval;

ConVar hCvarJockeyLedgeHang;

public Plugin myinfo =
{
	name = "L4D2 Jockey Ledge Hang Recharge",
	author = "Jahze, A1m`",
	version = "1.3",
	description = "Adds a cvar to adjust the recharge timer of a jockey after he ledge hangs a survivor.",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	hCvarJockeyLedgeHang = CreateConVar("z_leap_interval_post_ledge_hang", "10", "How long before a jockey can leap again after a ledge hang");
	fLedgeHangInterval = hCvarJockeyLedgeHang.FloatValue;
	hCvarJockeyLedgeHang.AddChangeHook(JockeyLedgeHangChange);

	HookEvent("jockey_ride_end", JockeyRideEnd, EventHookMode_Post);
}

public void JockeyLedgeHangChange(ConVar cVar, const char[] oldValue, const char[] newValue)
{
	fLedgeHangInterval = hCvarJockeyLedgeHang.FloatValue;
}

public void JockeyRideEnd(Event hEvent, const char[] name, bool dontBroadcast) 
{
	int jockeyVictim = GetClientOfUserId(GetEventInt(hEvent, "victim"));

	if (jockeyVictim > 0 && IsHangingFromLedge(jockeyVictim)) {
		int jockeyAttacker = GetClientOfUserId(hEvent.GetInt("userid"));
		if (jockeyAttacker > 0) {
			int ability = GetEntPropEnt(jockeyAttacker, Prop_Send, "m_customAbility");
			if (ability != -1 && IsValidEntity(ability)) {
				char abName[32];
				GetEntityClassname(ability, abName, sizeof(abName));
				if (strcmp(abName, "ability_leap") == 0) {
					/*
					 * Table: m_nextActivationTimer (offset 1104) (type DT_CountdownTimer)
					 *	Member: m_duration (offset 4) (type float) (bits 0) (NoScale)
					 *	Member: m_timestamp (offset 8) (type float) (bits 0) (NoScale)
					*/
					SetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", fLedgeHangInterval, ARRAY_INDEX_DURATION);
					SetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", GetGameTime() + fLedgeHangInterval, ARRAY_INDEX_TIMESTAMP);
				}
			}
		}
	}
}

bool IsHangingFromLedge(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}
