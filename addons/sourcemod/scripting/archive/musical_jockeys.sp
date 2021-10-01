// replaced by a plugin 'l4d2_unsilent_jockey'

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define SOUND_NAME "music/bacteria/jockeybacterias.wav"

#define Z_JOCKEY 5
#define TEAM_INFECTED 3

public Plugin myinfo = 
{
	name = "Musical Jockeys",
	author = "Jacob",
	description = "Prevents the Jockey from having silent spawns.",
	version = "1.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnMapStart()
{
	PrecacheSound(SOUND_NAME);
}

public Action Event_PlayerSpawn(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (client > 0 && !IsFakeClient(client) && GetClientTeam(client) == TEAM_INFECTED) {
		int zClass = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (zClass == Z_JOCKEY) {
			EmitSoundToAll(SOUND_NAME, _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0);
		}
	}
}
