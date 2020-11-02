#pragma newdecls required
#include <sourcemod>
#include <sdktools>

ConVar cvarSoundFlags;
int iSoundFlags;

int SOUNDFLAGS[3] = {
    1 << 0, // Heartbeat
    1 << 1, // Heavy Hittable Sounds (Introduced in The Last Stand)
    1 << 2, // Incapacitated screams (Commmon/FF/Bleeding out)
};

public Plugin myinfo = 
{
	name = "Sound Manipulation: REWORK",
	author = "Sir",
	description = "Allows control over certain sounds",
	version = "1.0",
	url = "The webternet."
}

public void OnPluginStart()
{
	cvarSoundFlags = CreateConVar("sound_flags", "0", "Prevent Sounds from playing - Bitmask: 0-Nothing | 1-Heartbeat | 2-Heavy Hittable Sounds | 4- Incapacitated Injury");
	iSoundFlags = cvarSoundFlags.IntValue;
	HookConVarChange(cvarSoundFlags, FlagsChanged);
	
	// Sound Hook
	AddNormalSoundHook(SoundHook);
}

public Action SoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH],int &entity, int &channel, float &volume, int &level, int &pitch, int &flags,char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (!iSoundFlags) // Are we even blocking sounds?
	  return Plugin_Continue;

	if (StrEqual(sample, "player/heartbeatloop.wav", false) && iSoundFlags & SOUNDFLAGS[0]) // Are we blocking Heartbeat sounds?
	  return Plugin_Stop;

	if (StrContains(sample, "vehicle_impact_heavy") != -1 && iSoundFlags & SOUNDFLAGS[1]) // Are we blocking Heavy Impact sounds on Hittables?
	  return Plugin_Stop;

	if (StrContains(sample, "incapacitatedinjury", false) != -1 && iSoundFlags & SOUNDFLAGS[2]) // Are we blocking Incapacitated Injury noises?
	  return Plugin_Stop;

	// That'll be all.
	return Plugin_Continue;
}

public void FlagsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    iSoundFlags = cvarSoundFlags.IntValue;
}