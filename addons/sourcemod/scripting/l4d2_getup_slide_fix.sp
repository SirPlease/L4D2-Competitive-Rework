#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

static const int getUpAnimations[SurvivorCharacter_Size][5] = 
{
	//l4d2
	// 0: Nick, 1: Rochelle, 2: Coach, 3: Ellis
	//[][4] = Flying animation from being hit by a tank
	{620, 667, 671, 672, 629}, //Nick
	{629, 674, 678, 679, 637}, //Rochelle
	{621, 656, 660, 661, 629}, //Coach
	{625, 671, 675, 676, 634}, //Ellis
	
	//l4d1
	// 4: Bill, 5: Zoey, 6: Louis, 7: Francis
	{528, 759, 763, 764, 537}, //Bill
	{537, 819, 823, 824, 546}, //Zoey
	{528, 759, 763, 764, 537}, //Louis
	{531, 762, 766, 767, 540} //Francis
};

bool
	isSurvivorStaggerBlocked[SurvivorCharacter_Size];

public Plugin myinfo =
{
	name		= "Stagger Blocker",
	author		= "Standalone (aka Manu), Visor, Sir, A1m`",
	description	= "Block players from being staggered by Jockeys and Hunters for a time while getting up from a Hunter pounce & Charger pummel",
	version		= "1.4",
	url		= "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	HookEvent("pounce_stopped", Event_PounceChargeEnd);
	HookEvent("charger_pummel_end", Event_PounceChargeEnd);
	HookEvent("charger_carry_end", Event_PounceChargeEnd);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("bot_player_replace", Event_BotPlayerReplace);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public void Event_RoundEnd(Event hEvent, const char[] eName, bool dontBroadcast)
{
	ResetStaggerBlocked();
}

public void OnMapEnd()
{
	ResetStaggerBlocked();
}

//Called when a Player replaces a Bot
public void Event_BotPlayerReplace(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int player = GetClientOfUserId(hEvent.GetInt("player"));
	int charIndex = IdentifySurvivor(player);
	if (charIndex == SurvivorCharacter_Invalid) {
		return;
	}
	
	if (isSurvivorStaggerBlocked[charIndex]) {
		SDKHook(player, SDKHook_PostThink, OnThink);
	}
}

//Called when a Bot replaces a Player
public void Event_PlayerBotReplace(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int bot = GetClientOfUserId(hEvent.GetInt("bot"));
	int charIndex = IdentifySurvivor(bot);
	if (charIndex == SurvivorCharacter_Invalid) {
		return;
	}
	
	if (isSurvivorStaggerBlocked[charIndex]) {
		SDKHook(bot, SDKHook_PostThink, OnThink);
	}
}

public void Event_PounceChargeEnd(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("victim"));
	int charIndex = IdentifySurvivor(client);
	if (charIndex == SurvivorCharacter_Invalid) {
		return;
	}
	
	CreateTimer(0.2, HookOnThink, client);
	isSurvivorStaggerBlocked[charIndex] = true;
}

public Action HookOnThink(Handle hTimer, any client)
{
	if (client && IsSurvivor(client)) {
		SDKHook(client, SDKHook_PostThink, OnThink);
	}

	return Plugin_Stop;
}

public void OnThink(int client)
{
	int charIndex = IdentifySurvivor(client);
	if (charIndex == SurvivorCharacter_Invalid) {
		return;
	}
	
	int sequence = GetEntProp(client, Prop_Send, "m_nSequence");
	if (sequence != getUpAnimations[charIndex][0] && sequence != getUpAnimations[charIndex][1] && sequence != getUpAnimations[charIndex][2] && sequence != getUpAnimations[charIndex][3] && sequence != getUpAnimations[charIndex][4]) {
		isSurvivorStaggerBlocked[charIndex] = false;
		SDKUnhook(client, SDKHook_PostThink, OnThink);
	}
}

public Action L4D2_OnStagger(int target, int source)
{
	if (IsValidInfected(source)) {
		int sourceClass = GetInfectedClass(source);
		
		if (sourceClass == L4D2Infected_Hunter || sourceClass == L4D2Infected_Jockey) {
			int charIndex = IdentifySurvivor(target);
			if (charIndex == SurvivorCharacter_Invalid) {
				return Plugin_Continue;
			}
			
			if (isSurvivorStaggerBlocked[charIndex]) {
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public Action L4D2_OnPounceOrLeapStumble(int victim, int attacker)
{
	if (IsValidInfected(attacker)) {
		int sourceClass = GetInfectedClass(attacker);
		
		if (sourceClass == L4D2Infected_Hunter || sourceClass == L4D2Infected_Jockey) {
			int charIndex = IdentifySurvivor(victim);
			if (charIndex == SurvivorCharacter_Invalid) {
				return Plugin_Continue;
			}
			
			if (isSurvivorStaggerBlocked[charIndex]) {
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

void ResetStaggerBlocked()
{
	for (int i = 0; i < SurvivorCharacter_Size; i++) {
		isSurvivorStaggerBlocked[i] = false;
	}
}
