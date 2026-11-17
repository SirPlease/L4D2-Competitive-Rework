#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define GAMEDATA_FILE "l4d2_voice_mechanics_fix"
#define KEY_ONVOICETRANSMIT "CTerrorPlayer::OnVoiceTransmit"

/*
	Every voice packet a player sends ends up affecting the game in some way
	- Infected:
		Plays a Zombie.Voice growl to the other teams and
		pushes their actual idle lines back by 2 whoppin' seconds
		(most noticeable would be the Jockey)
	- Survivors:
		Increases the noise level of the Survivors as well as resetting their "decay timer"
		This results into the Survivors showing brighter glows and
		being selected when an infected is getting their ghost spawn.
*/

DynamicHook g_hDHook_OnVoiceTransmit;

public Plugin myinfo =
{
	name = "[L4D2] Voice Chat Mechanics Fix",
	author = "Sir",
	description = "Stops in-game voice chat from affecting game mechanics & audio.",
	version = "1.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	GameData conf = new GameData(GAMEDATA_FILE);
	if (!conf) {
		SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	}

	g_hDHook_OnVoiceTransmit = DynamicHook.FromConf(conf, KEY_ONVOICETRANSMIT);
	if (!g_hDHook_OnVoiceTransmit) {
		SetFailState("Missing dhook setup for \""...KEY_ONVOICETRANSMIT..."\"");
	}

	delete conf;

	for (int client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client)) {
			OnClientPutInServer(client);
		}
	}
}

public void OnClientPutInServer(int client)
{
	g_hDHook_OnVoiceTransmit.HookEntity(Hook_Pre, client, DHook_OnVoiceTransmit);
}

// Relax, this will only block the side effects and not actual voice chat itself..
MRESReturn DHook_OnVoiceTransmit(int client)
{
	return MRES_Supercede;
}
