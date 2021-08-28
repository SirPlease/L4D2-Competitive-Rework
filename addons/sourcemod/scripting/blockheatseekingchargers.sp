/* -------------------CHANGELOG--------------------
 1.2
 - Implemented new method of blocking charger`s auto-aim, now it just continues charging instead of stopping the attack (thanks to dcx2)

 1.1
 - Fixed possible non-changer infected detecting as heatseeking charger
 
 1.0
 - Initial release
^^^^^^^^^^^^^^^^^^^^CHANGELOG^^^^^^^^^^^^^^^^^^^^ */



#include <sourcemod>

#define PL_VERSION "1.2"

public Plugin myinfo =
{
	name = "Blocks heatseeking chargers",
	version = PL_VERSION,
	author = "sheo",
}

public void OnPluginStart()
{
	HookEvent("player_bot_replace", BotReplacesPlayer);
	HookEvent("charger_charge_start", Event_ChargeStart);
	HookEvent("charger_charge_end", Event_ChargeEnd);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	
	CreateConVar("l4d2_block_heatseeking_chargers_version", PL_VERSION, "Block heatseeking chargers fix version");
}

public Event_ChargeStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    IsInCharge[GetClientOfUserId(GetEventInt(event, "userid"))] = true;
}

public Event_ChargeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    IsInCharge[GetClientOfUserId(GetEventInt(event, "userid"))] = false;
}

public Action BotReplacesPlayer(Event hEvent, const char[] sEntityName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "player"));
	if (iClient > 0 && IsInCharge[client]) {
		int iBot = GetClientOfUserId(GetEventInt(event, "bot"));
		
		int iFlags = GetEntityFlags(iBot);
		SetEntityFlags(iBot, iFlags | FL_FROZEN);
		IsInCharge[client] = false;
	}
}

public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	IsInCharge[GetClientOfUserId(GetEventInt(event, "userid"))] = false;
}

public Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	IsInCharge[GetClientOfUserId(GetEventInt(event, "userid"))] = false;
}