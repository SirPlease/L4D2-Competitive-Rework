/*
	Changelog
	---------
		0.6 (A1m`)
			- Removed unnecessary comments, unnecessary functions and extra code.
			- Fixed return value in repeat timer, timer must be called more than 1 time. Replaced return value from 'Plugin_Stop' to 'Plugin_Continue'.
			- Fixed a possible problem when starting a new timer, the old one will always be deleted.
		0.5 (A1m`)
			-Fixed warnings when compiling a plugin on sourcemod 1.11.
		0.4 (Sir)
			- Refined the code a bit, simpler code.
			- Fixes an issue with timers still existing on players.
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
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks> // For checking respawns.

#define TEAM_INFECTED			3
#define ZC_JOCKEY				5

ConVar
	g_hJockeyVoiceInterval = null;

Handle
	g_hJockeySoundTimer[MAXPLAYERS + 1] = {null, ...};

public const char g_sJockeySound[][] =
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

public Plugin myinfo =
{
	name = "Unsilent Jockey",
	author = "Tabun, robex, Sir, A1m`",
	description = "Makes jockeys emit sound constantly.",
	version = "0.7",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	// ConVars
	g_hJockeyVoiceInterval = CreateConVar("sm_unsilentjockey_interval", "2.0", "Interval between forced jockey sounds.");

	// Events
	HookEvent("player_spawn", PlayerSpawn_Event);
	HookEvent("player_death", PlayerDeath_Event);
	HookEvent("player_team", PlayerTeam_Event);
	HookEvent("jockey_ride", JockeyRideStart_Event);
	HookEvent("jockey_ride_end", JockeyRideEnd_Event);
}

public void OnMapStart()
{
	// Precache
	for (int i = 0; i < sizeof(g_sJockeySound); i++) {
		PrecacheSound(g_sJockeySound[i], true);
	}
}

public void L4D_OnEnterGhostState(int client)
{
	// Simply disable the timer if the client enters ghost mode and has the timer set.
	ChangeJockeyTimerStatus(client, false);
}

public void PlayerSpawn_Event(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	// Valve
	if (client < 1 || !IsClientInGame(client)) {
		return;
	}

	// Kill the sound timer if it exists (this will also trigger if you switch to Tank)
	ChangeJockeyTimerStatus(client, false);

	if (GetClientTeam(client) != TEAM_INFECTED) {
		return;
	}

	if (GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_JOCKEY) {
		return;
	}

	// Setup the sound interval
	RequestFrame(JockeyRideEnd_NextFrame, GetClientUserId(client));
}

public void PlayerDeath_Event(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	// Valve
	if (client < 1 || !IsClientInGame(client)) {
		return;
	}

	// Kill the sound timer if it exists
	ChangeJockeyTimerStatus(client, false);
}

public void PlayerTeam_Event(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	// Valve
	if (client < 1 || !IsClientInGame(client)) {
		return;
	}

	// Kill the sound timer if it exists
	ChangeJockeyTimerStatus(client, false);
}

public void JockeyRideStart_Event(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	// Jockey ridin' a Survivor
	ChangeJockeyTimerStatus(client, false);
}

public void JockeyRideEnd_Event(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	// Check if our beloved Jockey is alive on the very next frame
	RequestFrame(JockeyRideEnd_NextFrame, GetClientUserId(client));
}

void JockeyRideEnd_NextFrame(any userid)
{
	int client = GetClientOfUserId(userid);

	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && !GetEntProp(client, Prop_Send, "m_isGhost")) {
		// Resume our sound spam as the Jockey is still alive
		if (GetClientTeam(client) == TEAM_INFECTED && GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_JOCKEY) {
			ChangeJockeyTimerStatus(client, true);
		}
	}
}

Action delayedJockeySound(Handle timer, any client)
{
	int rndPick = GetRandomInt(0, (sizeof(g_sJockeySound) - 1));
	EmitSoundToAll(g_sJockeySound[rndPick], client, SNDCHAN_VOICE);

	return Plugin_Continue;
}

void ChangeJockeyTimerStatus(int client, bool bEnable)
{
	if (g_hJockeySoundTimer[client] != null) {
		KillTimer(g_hJockeySoundTimer[client], false);
		g_hJockeySoundTimer[client] = null;
	}
	
	if (bEnable) {
		g_hJockeySoundTimer[client] = CreateTimer(g_hJockeyVoiceInterval.FloatValue, delayedJockeySound, client, TIMER_REPEAT);
	}
}
