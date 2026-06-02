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

#define PL_VERSION		"1.3.2"

public Plugin myinfo =
{
	name = "Blocks heatseeking chargers",
	description = "Blocks heatseeking chargers",
	author = "sheo, A1m`",
	version = PL_VERSION,
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
}

void Event_PlayerBotReplace(Event hEvent, const char[] sEntityName, bool bDontBroadcast)
{
	int iBot = GetClientOfUserId(hEvent.GetInt("bot"));
	if (iBot < 1) {
		return;
	}
	
	int iAbility = GetEntPropEnt(iBot, Prop_Send, "m_customAbility");
	if (iAbility == -1) {
		return;
	}
	
	char sAbilityName[64];
	GetEntityClassname(iAbility, sAbilityName, sizeof(sAbilityName));
	if (strcmp(sAbilityName, "ability_charge") != 0) {
		return;
	}
	
	if (GetEntProp(iAbility, Prop_Send, "m_isCharging", 1) > 0) {
		SetEntityFlags(iBot, GetEntityFlags(iBot) | FL_FROZEN);
	}
}