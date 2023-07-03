#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_VERSION "2.0.1"

public Plugin myinfo = 
{
	name = "[L4D2] Fix Jockey Hitbox",
	author = "Forgetest",
	description = "Fix jockey hitbox issues when riding survivors.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

// source-sdk: src/game/server/nav.h
#define HumanHeight 71

int g_iOffs_m_flEstIkOffset;

public void OnPluginStart()
{
	g_iOffs_m_flEstIkOffset = FindSendPropInfo("CBaseAnimating", "m_flModelScale") + 24;
	
	HookEvent("jockey_ride", Event_JockeyRide);
	HookEvent("jockey_ride_end", Event_JockeyRideEnd);
}

void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!victim || !IsClientInGame(victim))
		return;
	
	// Fix bounding box
	if (GetEntityFlags(victim) & FL_DUCKING)
	{
		SetEntityFlags(victim, GetEntityFlags(victim) & ~FL_DUCKING);
	}
	
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!attacker || !IsClientInGame(attacker))
		return;
	
	// https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/baseanimating.cpp#L1800
	/**
	 *   // adjust hit boxes based on IK driven offset
	 *   Vector adjOrigin = GetAbsOrigin() + Vector( 0, 0, m_flEstIkOffset );
	 */
	int character = GetEntProp(victim, Prop_Send, "m_survivorCharacter");
	
	float flModelScale = GetCharacterScale(character);
	SetEstIkOffset(attacker, HumanHeight * (flModelScale - 1.0));
}

void Event_JockeyRideEnd(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!attacker || !IsClientInGame(attacker))
		return;
	
	SetEstIkOffset(attacker, 0.0);
}

void SetEstIkOffset(int client, float value)
{
	SetEntDataFloat(client, g_iOffs_m_flEstIkOffset, value);
}

float GetCharacterScale(int survivorCharacter)
{
	static const float s_flScales[] = {
		0.888,	// Rochelle
		1.05,	// Coach
		0.955,	// Ellis
		1.0,	// Bill
		0.888	// Zoey
	};
	
	int index = ConvertToExternalCharacter(survivorCharacter) - 1;
	
	return (index >= 0 && index < sizeof(s_flScales)) ? s_flScales[index] : 1.0;
}

int ConvertToExternalCharacter(int survivorCharacter)
{
	if (L4D2_GetSurvivorSetMod() == 1)
	{
		if (survivorCharacter >= 0)
		{
			switch (survivorCharacter)
			{
				case 2: return 7;
				case 3: return 6;
				default: return survivorCharacter + 4;
			}
		}
	}
	
	return survivorCharacter;
}