#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

// We will not be resetting this value anywhere for the simple reason that it is not relied upon outside of PreThink
// -> PreThink itself also verifies that the player is currently jockeyed before teleporting them.
// In the event that for some reason the `m_jockeyAttacker` netprop still returns true on map transitions/etc, Hooks unhook themselves by default on transitions.

float fPreviousOrigin[MAXPLAYERS + 1][3];

#define MAX_SINGLE_FRAME_UNITS 400.0
#define DEBUG 0

public Plugin myinfo = 
{
    name = "[L4D2] Jockey Teleport Fix", 
    author = "Sir", 
    description = "A fix for Jockeys teleporting (whether done maliciously with cheats, or caused by a glitch)", 
    version = "1.1", 
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart() {

    // The one to start it all
    // - Heavily relying on this one to start monitoring the player.
    // - If the victim is teleported prior to this event being fired or after the jockey is no longer considered as `m_jockeyAttacker`, the issue will still occur.
    HookEvent("jockey_ride", Event_JockeyRide, EventHookMode_Pre);

    // Gotta keep those players/bots that join mid-ride in mind.
    HookEvent("bot_player_replace", Event_PlayerReplacedByBot);
    HookEvent("player_bot_replace", Event_BotReplacedByPlayer);
}

public void Event_JockeyRide(Event hEvent, char[] name, bool dontBroadcast) {

    int client = GetClientOfUserId(hEvent.GetInt("victim"));
    float currentOrigin[3];
    GetClientAbsOrigin(client, currentOrigin);
    fPreviousOrigin[client] = currentOrigin;

    #if DEBUG
        PrintToChatAll("%N's currently recorded Origin has been set to: %f %f %f", client, currentOrigin[0], currentOrigin[1], currentOrigin[2])
    #endif

    SDKHook(client, SDKHook_PreThink, OnPreThink);
}

public void Event_BotReplacedByPlayer(Event hEvent, char[] name, bool dontBroadcast) {

    int client = GetClientOfUserId(hEvent.GetInt("player"));
    int bot    = GetClientOfUserId(hEvent.GetInt("bot"));

    if (GetClientTeam(bot) != 2
    || !IsJockeyVictim(bot))
      return;

    // Unhook bot, copy stored origin from bot to player, hook player.
    SDKUnhook(bot, SDKHook_PreThink, OnPreThink);
    fPreviousOrigin[client] = fPreviousOrigin[bot];
    SDKHook(client, SDKHook_PreThink, OnPreThink);
}

public void Event_PlayerReplacedByBot(Event hEvent, char[] name, bool dontBroadcast) {

    int client = GetClientOfUserId(hEvent.GetInt("player"));
    int bot    = GetClientOfUserId(hEvent.GetInt("bot"));

    if (GetClientTeam(client) != 2
    || !IsJockeyVictim(client))
      return;

    // Unhook player, copy stored origin from player to bot, hook bot.
    SDKUnhook(client, SDKHook_PreThink, OnPreThink);
    fPreviousOrigin[bot] = fPreviousOrigin[client];
    SDKHook(bot, SDKHook_PreThink, OnPreThink);
}

void OnPreThink(int client) {

    // Unhook self if no longer jockeyed.
    if (!IsJockeyVictim(client)) {

        #if DEBUG
            PrintToChatAll("%N is no longer jockeyed", client);
        #endif

        SDKUnhook(client, SDKHook_PreThink, OnPreThink);
        return;
    }

    float safeVector[3];
    safeVector = fPreviousOrigin[client];

    float preVector[3];
    GetClientAbsOrigin(client, preVector);

    // Teleporting
    if (GetVectorDistance(safeVector, preVector) > MAX_SINGLE_FRAME_UNITS) {

        #if DEBUG
            PrintToChatAll("Prevented %N from being teleported to %f %f %f", client, preVector[0], preVector[1], preVector[2]);
            PrintToChatAll("Teleported back to %f %f %f", safeVector[0], safeVector[1], safeVector[2]);
        #endif

        TeleportEntity(client, safeVector, NULL_VECTOR, NULL_VECTOR);
        return;
    }

    // Normal behaviour
    fPreviousOrigin[client] = preVector;
}

bool IsJockeyVictim(int client) {
    return GetEntProp(client, Prop_Send, "m_jockeyAttacker") > 0;
}