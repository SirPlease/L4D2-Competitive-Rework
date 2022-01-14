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
    version = "1.0",
    url = "URL"
};

public void OnPluginStart()
{
	HookEvent("pounce_end", Event_PounceEnd);
}

public void Event_PounceEnd(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client > 0 && IsClientInGame(client)) 
	{
		int charIndex = IdentifySurvivor(client);
		if (charIndex == SurvivorCharacter_Ellis) 
		  AnimHookEnable(client, INVALID_FUNCTION, EllisPostPounce);
	}
}

void UpdateThink(int client)
{
	// We can assume client is valid as SDKUnhook is called automatically on disconnect.
	// Check the team and sequence, should suffice.
	if (GetClientTeam(client) == 2 && GetEntProp(client, Prop_Send, "m_nSequence") == ANIM_ELLIS_HUNTER_GETUP)
	{
		SetEntPropFloat(client, Prop_Send, "m_flPlaybackRate", ANIM_PLAYBACK_RATE_MULTIPLIER);
	}
	else SDKUnhook(client, SDKHook_PostThinkPost, UpdateThink);
}

Action EllisPostPounce(int client, int &sequence)
{
	// Ellis Hunter get up animation?
	if (sequence == ANIM_ELLIS_HUNTER_GETUP)
	{
		SDKHook(client, SDKHook_PostThinkPost, UpdateThink);
		AnimHookDisable(client, INVALID_FUNCTION, EllisPostPounce);
	}
	return Plugin_Continue;
}