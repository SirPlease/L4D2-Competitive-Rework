/* -------------------CHANGELOG--------------------
 1.2
 - Implemented new method of blocking charger`s auto-aim, now it just continues charging instead of stopping the attack (thanks to dcx2)

 1.1
 - Fixed possible non-changer infected detecting as heatseeking charger
 
 1.0
 - Initial release
^^^^^^^^^^^^^^^^^^^^CHANGELOG^^^^^^^^^^^^^^^^^^^^ */



#include <sourcemod>
new IsInCharge[MAXPLAYERS + 1] = false;

#define PL_VERSION "1.2"

public Plugin:myinfo =
{
	name = "Blocks heatseeking chargers",
	version = PL_VERSION,
	author = "sheo",
}

public OnPluginStart()
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

public Action:BotReplacesPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	if (IsInCharge[client])
	{
		//SetEntityMoveType(GetClientOfUserId(GetEventInt(event, "bot")), MOVETYPE_NONE); //Old method, by me
		new bot = GetClientOfUserId(GetEventInt(event, "bot"));
		SetEntProp(bot, Prop_Send, "m_fFlags", GetEntProp(bot, Prop_Send, "m_fFlags") | FL_FROZEN); //New method, by dcx2
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