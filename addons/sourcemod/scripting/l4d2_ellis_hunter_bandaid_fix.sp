#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>
#include <left4dhooks>

#define ANIM_ELLIS_HUNTER_GETUP 625

/**
  * Modify m_flPlaybackRate based on the following:
  * 
  * Ellis Hunter Pounce Getup Anim:    79 Frames.
  * Other Survivors Pounce Getup Anim: 64 Frames.
  * 79 / 64 = 1.234375
*/
#define ANIM_PLAYBACK_RATE_MULTIPLIER 1.234375

public Plugin myinfo =
{
	name = "L4D2 Ellis Hunter Band aid Fix",
	author = "Sir (with pointers from Rena)",
	description = "Band-aid fix for Ellis' getup not matching the other Survivors",
	version = "1.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	HookEvent("pounce_end", Event_PounceEnd);
	HookEvent("player_bot_replace", Event_Replaced);
	HookEvent("bot_player_replace", Event_Replaced);
}

// A player/bot swap hands the get-up to another client, so keep the speed-up on whoever has it now.
void Event_Replaced(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt(name[0] == 'p' ? "bot" : "player"));
	if (client < 1 || !IsClientInGame(client) || GetClientTeam(client) != L4D2Team_Survivor) {
		return;
	}

	if (IdentifySurvivorFast(client) == L4D2Util_SurvivorCharacter_Ellis && GetEntProp(client, Prop_Send, "m_nSequence") == ANIM_ELLIS_HUNTER_GETUP) {
		SDKUnhook(client, SDKHook_PostThinkPost, UpdateThink);
		SDKHook(client, SDKHook_PostThinkPost, UpdateThink);
	}
}

void Event_PounceEnd(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client < 1 || !IsClientInGame(client)) {
		return;
	}

	int charIndex = IdentifySurvivorFast(client); // Already contains checks inside

	if (charIndex == L4D2Util_SurvivorCharacter_Ellis) {
		AnimHookEnable(client, INVALID_FUNCTION, EllisPostPounce);
	}
}

void UpdateThink(int client)
{
	// We can assume client is valid as SDKUnhook is called automatically on disconnect.
	// Check the team and sequence, should suffice.
	int iSequence = GetEntProp(client, Prop_Send, "m_nSequence");

	if (GetClientTeam(client) == L4D2Team_Survivor && iSequence == ANIM_ELLIS_HUNTER_GETUP) {
		SetEntPropFloat(client, Prop_Send, "m_flPlaybackRate", ANIM_PLAYBACK_RATE_MULTIPLIER);
		return;
	}

	SDKUnhook(client, SDKHook_PostThinkPost, UpdateThink);
}

Action EllisPostPounce(int client, int &sequence)
{
	// Ellis Hunter get up animation?
	if (sequence == ANIM_ELLIS_HUNTER_GETUP) {
		SDKHook(client, SDKHook_PostThinkPost, UpdateThink);
		AnimHookDisable(client, INVALID_FUNCTION, EllisPostPounce);
	}

	return Plugin_Continue;
}
