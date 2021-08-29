/* -------------------CHANGELOG--------------------
 1.2
 - Implemented new method of blocking charger`s auto-aim, now it just continues charging instead of stopping the attack (thanks to dcx2)

 1.1
 - Fixed possible non-changer infected detecting as heatseeking charger
 
 1.0
 - Initial release
^^^^^^^^^^^^^^^^^^^^CHANGELOG^^^^^^^^^^^^^^^^^^^^ */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PL_VERSION "1.2.1"

bool
	IsInCharge[MAXPLAYERS + 1] = {false, ...};

public Plugin myinfo =
{
	name = "Blocks heatseeking chargers",
	description = "Blocks heatseeking chargers",
	author = "sheo",
	version = PL_VERSION,
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_block_heatseeking_chargers_version", PL_VERSION, "Block heatseeking chargers fix version");
	
	HookEvent("player_bot_replace", BotReplacesPlayer);
	HookEvent("charger_charge_start", Event_ChargeStart);
	HookEvent("charger_charge_end", Event_ChargeEnd);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	
	HookEvent("round_start", Event_Reset, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_Reset, EventHookMode_PostNoCopy);
}

void ResetArray()
{
	for (int i = 0; i <= MaxClients; i++) {
		IsInCharge[i] = false;
	}
}

public void Event_Reset(Event hEvent, const char[] sEntityName, bool bDontBroadcast)
{
	ResetArray();
}

public void Event_ChargeStart(Event hEvent, const char[] sEntityName, bool bDontBroadcast)
{
	IsInCharge[GetClientOfUserId(hEvent.GetInt("userid"))] = true;
}

public void Event_ChargeEnd(Event hEvent, const char[] sEntityName, bool bDontBroadcast)
{
	IsInCharge[GetClientOfUserId(hEvent.GetInt("userid"))] = false;
}

public void BotReplacesPlayer(Event hEvent, const char[] sEntityName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("player"));
	if (iClient > 0 && IsInCharge[iClient]) {
		int iBot = GetClientOfUserId(hEvent.GetInt("bot"));
		
		SetEntityFlags(iBot, GetEntityFlags(iBot) | FL_FROZEN);
		IsInCharge[iClient] = false;
	}
}

public void Event_OnPlayerSpawn(Event hEvent, const char[] sEntityName, bool bDontBroadcast)
{
	IsInCharge[GetClientOfUserId(hEvent.GetInt("userid"))] = false;
}

public void Event_OnPlayerDeath(Event hEvent, const char[] sEntityName, bool bDontBroadcast)
{
	IsInCharge[GetClientOfUserId(hEvent.GetInt("userid"))] = false;
}
