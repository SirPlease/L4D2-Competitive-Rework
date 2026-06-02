#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "L4D2 Fireworks Noise Blocker",
	description = "Focus on SI!",
	author = "Visor",
	version = "0.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	AddNormalSoundHook(Hook_OnNormalSound);
	AddAmbientSoundHook(Hook_OnAmbientSound);
}

Action Hook_OnNormalSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, \
									float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	return (StrContains(sample, "firewerks", true) > -1) ? Plugin_Stop : Plugin_Continue;
}

Action Hook_OnAmbientSound(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, \
									int &pitch, float pos[3], int &flags, float &delay)
{
	return (StrContains(sample, "firewerks", true) > -1) ? Plugin_Stop : Plugin_Continue;
}
