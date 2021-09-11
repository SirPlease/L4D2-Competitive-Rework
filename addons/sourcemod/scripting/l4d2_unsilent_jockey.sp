#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks> // For checking respawns.

#define MAX_SOUNDFILE_LENGTH    64
#define MAX_JOCKEYSOUND         15

#define TEAM_INFECTED           3
#define ZC_JOCKEY               5
#define ZC_TANK                 8
#define SNDCHAN_VOICE           2


ConVar 
    hPluginEnabled,
    hJockeyVoiceInterval,
    hDebug;

Handle 
    hJockeySoundTimer[MAXPLAYERS+1];

bool
    isEnabled,
    isDebug;

float
    fJockeyVoiceInterval;

char sJockeySound[MAX_JOCKEYSOUND+1][] =
{
    "player/jockey/voice/idle/jockey_recognize02.wav",
    "player/jockey/voice/idle/jockey_recognize06.wav",
    "player/jockey/voice/idle/jockey_recognize07.wav",
    "player/jockey/voice/idle/jockey_recognize08.wav",
    "player/jockey/voice/idle/jockey_recognize09.wav",
    "player/jockey/voice/idle/jockey_recognize10.wav",
    "player/jockey/voice/idle/jockey_recognize11.wav",
    "player/jockey/voice/idle/jockey_recognize12.wav",
    "player/jockey/voice/idle/jockey_recognize13.wav",
    "player/jockey/voice/idle/jockey_recognize15.wav",
    "player/jockey/voice/idle/jockey_recognize16.wav",
    "player/jockey/voice/idle/jockey_recognize17.wav",
    "player/jockey/voice/idle/jockey_recognize18.wav",
    "player/jockey/voice/idle/jockey_recognize19.wav",
    "player/jockey/voice/idle/jockey_recognize20.wav",
    "player/jockey/voice/idle/jockey_recognize24.wav"
};

/*
-----------------------------------------------------------------------------------------------------------------------------------------------------


Changelog
---------
0.3 (Sir)
- Updated the code to the latest syntax.
- Add additional checks/optimization to resolve potential and existing issues with 0.2-alpha.
0.2-alpha (robex)
- make sound always at a regular interval
0.1b (Tabun)
- fix error log spam
0.1a (Tabun)
- plays sound at set time after jockey spawns up
- but only if the jockey isn't already making noise

-----------------------------------------------------------------------------------------------------------------------------------------------------
*/

public Plugin myinfo = 
{
    name = "Unsilent Jockey",
    author = "Tabun, robex, Sir",
    description = "Makes jockeys emit sound constantly.",
    version = "0.3",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

/* -------------------------------
*      Init
* ------------------------------- */

public void OnPluginStart()
{
    // ConVars
    hPluginEnabled          = CreateConVar("sm_unsilentjockey_enabled", "1", "Enable unsilent jockey mode.", _, true, 0.0, true, 1.0);
    hJockeyVoiceInterval    = CreateConVar("sm_unsilentjockey_interval", "2.0", "Interval between forced jockey sounds.");
    hDebug                  = CreateConVar("sm_unsilentjockey_debug", "0", "Enable debug mode.", _, true, 0.0, true, 1.0);

    isEnabled            = hPluginEnabled.BoolValue;
    isDebug              = hDebug.BoolValue;
    fJockeyVoiceInterval = hJockeyVoiceInterval.FloatValue;

    hPluginEnabled.AddChangeHook(ConVar_Changed);
    hJockeyVoiceInterval.AddChangeHook(ConVar_Changed);
    hDebug.AddChangeHook(ConVar_Changed);

    // Events
    HookEvent("player_spawn", PlayerSpawn_Event);
    HookEvent("player_death", PlayerDeath_Event);
    HookEvent("player_team", PlayerTeam_Event);
    HookEvent("jockey_ride", JockeyRideStart_Event);
    HookEvent("jockey_ride_end", JockeyRideEnd_Event);
}

public void ConVar_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
    isEnabled            = hPluginEnabled.BoolValue;
    isDebug              = hDebug.BoolValue;
    fJockeyVoiceInterval = hJockeyVoiceInterval.FloatValue;
}

public void OnMapStart()
{
    // Precache
    for (int i = 0; i <= MAX_JOCKEYSOUND; i++)
    {
        PrefetchSound(sJockeySound[i]);
        PrecacheSound(sJockeySound[i], true);
    }
}


/* -------------------------------
*      Events
* ------------------------------- */

public void L4D_OnEnterGhostState(int client)
{
    // Simply disable the timer if the client enters ghost mode and has the timer set.

    /// --- DEBUG
    if (isDebug)
        PrintToChatAll("\x04uj: \x01Removed Jockey timer on Ghost Mode \x03%N\x01.", client);

    ChangeJockeyTimerStatus(client, false);
}

public Action PlayerSpawn_Event(Event event, const char[] name, bool dontBroadcast)
{
    if (!isEnabled)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsClientAndInGame(client))
        return;

    if (!IsInfected(client))
        return;

    // Check if the player is becoming the Tank to get rid of the timer, or else it would keep playing.
    if (IsTank(client))
    {
        // If we have a timer running, get rid of it here.
        ChangeJockeyTimerStatus(client, false);
        return;
    }

    if (!IsJockey(client))
        return;

    /// --- DEBUG
    if (isDebug)
        PrintToChatAll("\x04uj: \x01Jockey spawned: \x03%N\x01.", client);

    // Setup the sound interval
    ChangeJockeyTimerStatus(client, true);
}

public Action PlayerDeath_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsClientAndInGame(client))
        return;

    if (!IsInfected(client))
        return;

    if (!IsJockey(client))
        return;

    /// --- DEBUG
    if (isDebug)
        PrintToChatAll("\x04uj: \x01 Jockey died: \x03%N\x01.", client);

    // Kill Sound timer.
    ChangeJockeyTimerStatus(client, false);
}

public Action PlayerTeam_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int oldTeam = event.GetInt("oldteam");

    // Switched team
    if (oldTeam == TEAM_INFECTED) 
    {
        /// --- DEBUG
        if (isDebug)
            PrintToChatAll("\x04uj: \x01Removed Jockey timer on team change: \x03%N\x01.", client);

        // Kill Sound timer if it's active
        ChangeJockeyTimerStatus(client, false);
    }
}

public Action JockeyRideStart_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    /// --- DEBUG
    if (isDebug)
        PrintToChatAll("\x03%N\x04: \x01Jockey sound ended because of a cap.", client);

    ChangeJockeyTimerStatus(client, false);
}

public Action JockeyRideEnd_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    // Check if our beloved Jockey is alive on the very next frame
    RequestFrame(JockeyRideEnd_NextFrame, GetClientUserId(client));
}

public void JockeyRideEnd_NextFrame(any userid)
{
    int client = GetClientOfUserId(userid);

    if (IsClientAndInGame(client)
        && IsPlayerAlive(client)) {

        // Resume our sound spam
        ChangeJockeyTimerStatus(client, true);
        
        /// --- DEBUG
        if (isDebug)
            PrintToChatAll("\x04uj: \x01 Jockey(\x03%N\x01) got cleared, but is \x04alive\x01.", client);
    }
}

/* -------------------------------
*      Our Timer
* ------------------------------- */

public Action delayedJockeySound(Handle timer, any client)
{
    /// --- DEBUG
    if (isDebug)
        PrintToChatAll("\x03%N\x04: \x01Jockey sound...", client);

    int rndPick = GetRandomInt(0, MAX_JOCKEYSOUND);
    EmitSoundToAll(sJockeySound[rndPick], client, SNDCHAN_VOICE);
}

/* --------------------------------------
*     Shared function(s)
* -------------------------------------- */

bool IsClientAndInGame(int index)
{
    return (index > 0 && index <= MaxClients && IsClientInGame(index));
}

bool IsInfected(int client)
{
    return GetClientTeam(client) == TEAM_INFECTED;
}

bool IsJockey(int client)
{
    return GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_JOCKEY;
}

bool IsTank(int client)
{
    return GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK;
}

void ChangeJockeyTimerStatus(int client, bool bEnable)
{
    if (!bEnable)
    {
        if (hJockeySoundTimer[client] != null)
        {
            KillTimer(hJockeySoundTimer[client], false);
            hJockeySoundTimer[client] = null;
        }
    }
    else hJockeySoundTimer[client] = CreateTimer(fJockeyVoiceInterval, delayedJockeySound, client, TIMER_REPEAT);
}