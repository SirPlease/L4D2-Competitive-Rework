#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_VERSION "2.2"

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
	HookEvent("player_bot_replace", Event_player_bot_replace);
	HookEvent("bot_player_replace", Event_bot_player_replace);
	HookEvent("jockey_ride_end", Event_JockeyRideEnd);
}

void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!victim || !IsClientInGame(victim))
		return;
	
	FixHitbox(victim);
}

void Event_player_bot_replace(Event event, const char[] name, bool dontBroadcast)
{
	HandlePlayerReplace(event.GetInt("bot"));
}

void Event_bot_player_replace(Event event, const char[] name, bool dontBroadcast)
{
	HandlePlayerReplace(event.GetInt("player"));
}

void HandlePlayerReplace(int replacer)
{
	replacer = GetClientOfUserId(replacer);
	if (!replacer || !IsClientInGame(replacer))
		return;
	
	if (!IsPlayerAlive(replacer))
		return;
	
	FixHitbox(replacer);
}

void FixHitbox(int client)
{
	if (!FixHitboxInternal(client))
		return;
	
	SDKHook(client, SDKHook_PostThink, SDK_OnPostThink);
}

Action SDK_OnPostThink(int client)
{
	if (IsClientInGame(client))
	{
		if (!FixHitboxInternal(client))
		{
			SDKUnhook(client, SDKHook_PostThink, SDK_OnPostThink);
		}
	}
	return Plugin_Continue;
}

bool FixHitboxInternal(int client)
{
	if (GetClientTeam(client) != 2)
		return false;
	
	// in all circumstances this should make sure the client is being jockeyed
	int attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if (attacker == -1)
		return false;
	
	// Fix bounding box
	int flags = GetEntityFlags(client);
	if (flags & FL_DUCKING)
	{
		SetEntityFlags(client, flags & ~FL_DUCKING);
	}
	
	// https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/baseanimating.cpp#L1800
	/**
	 *   // adjust hit boxes based on IK driven offset
	 *   Vector adjOrigin = GetAbsOrigin() + Vector( 0, 0, m_flEstIkOffset );
	 */
	int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	
	float flOffset = HumanHeight * (GetCharacterScale(character) - 1.0);
	if (flOffset != GetEntDataFloat(attacker, g_iOffs_m_flEstIkOffset))
	{
		SetEntDataFloat(attacker, g_iOffs_m_flEstIkOffset, flOffset);
	}
	
	return true;
}

void Event_JockeyRideEnd(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!attacker || !IsClientInGame(attacker))
		return;
	
	SetEntDataFloat(attacker, g_iOffs_m_flEstIkOffset, 0.0);
}

float GetCharacterScale(int survivorCharacter)
{
	static const float k_flScales[] = {
		1.0,	// Nick
		0.888,	// Rochelle
		1.05,	// Coach
		0.955,	// Ellis
		1.0,	// Bill
		0.888,	// Zoey
		1.0,	// Francis
		1.0,	// Louis

		1.0,	// Unknown
	};
	
	return k_flScales[ConvertToExternalCharacter(survivorCharacter)];
}

int ConvertToExternalCharacter(int survivorCharacter)
{
	if (survivorCharacter < 0 || survivorCharacter > 4)
		return 8;

	if (L4D2_GetSurvivorSetMod() == 1)
		return survivorCharacter + 4;
	
	return survivorCharacter;
}