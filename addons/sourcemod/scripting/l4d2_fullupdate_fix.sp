#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define GAMEDATA_FILE "l4d2_fullupdate_fix"
#define KEY_CREATENOISE "CTerrorPlayer::CreateNoise"

/*
	Client can be behind the server's current status by up to one snapshot,
	so we need to give a little grace time before fading the noise level to 0.
*/
#define NOISE_GRACE_TIME 0.1

#define PARTICLE_DISPATCH_FROM_ENTITY (1 << 0)

ConVar
	g_hCvarHoldTime,
	g_hCvarFadeRate;

DynamicHook g_hDHook_CreateNoise;

Handle g_hClearTimer[MAXPLAYERS + 1];

int
	g_iNoiseLevelOffset,
	g_iNoiseLatchOffset,
	g_iPreLatch,
	g_iParticleEffect = INVALID_STRING_INDEX,
	g_iSmokeCloud = INVALID_STRING_INDEX;

float g_fNoiseTime[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "[L4D2] Full Update Exploit Fixes",
	author = "Sir",
	description = "Stops full updates (demo recording) from revealing silent survivors or clearing smoker clouds.",
	version = "1.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	g_iNoiseLevelOffset = FindSendPropInfo("CTerrorPlayer", "m_noiseLevel");
	g_iNoiseLatchOffset = FindSendPropInfo("CTerrorPlayer", "m_noiseLevelLatch");
	if (g_iNoiseLevelOffset <= 0 || g_iNoiseLatchOffset <= 0) {
		SetFailState("Missing CTerrorPlayer::m_noiseLevel / m_noiseLevelLatch.");
	}

	GameData conf = new GameData(GAMEDATA_FILE);
	if (!conf) {
		SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	}

	g_hDHook_CreateNoise = DynamicHook.FromConf(conf, KEY_CREATENOISE);
	if (!g_hDHook_CreateNoise) {
		SetFailState("Missing dhook setup for \""...KEY_CREATENOISE..."\"");
	}

	delete conf;

	g_hCvarHoldTime = FindConVar("z_noise_level_hold_time");
	g_hCvarFadeRate = FindConVar("z_noise_level_fade_rate");

	AddTempEntHook("EffectDispatch", Hook_EffectDispatch);

	// Late load: we don't know when their last noise was, so count it as made just now.
	for (int client = 1; client <= MaxClients; client++) {
		if (!IsClientInGame(client)) {
			continue;
		}

		OnClientPutInServer(client);
		if (GetEntDataFloat(client, g_iNoiseLevelOffset) > 0.0) {
			OnNoiseMade(client);
		}
	}
}

public void OnMapStart()
{
	g_iParticleEffect = FindStringIndex(FindStringTable("EffectDispatch"), "ParticleEffect");
	g_iSmokeCloud = FindStringIndex(FindStringTable("ParticleEffectNames"), "smoker_smokecloud");
}

public void OnClientPutInServer(int client)
{
	g_hDHook_CreateNoise.HookEntity(Hook_Pre, client, DHook_OnCreateNoise_Pre);
	g_hDHook_CreateNoise.HookEntity(Hook_Post, client, DHook_OnCreateNoise_Post);
}

public void OnClientDisconnect(int client)
{
	delete g_hClearTimer[client];
}

MRESReturn DHook_OnCreateNoise_Pre(int client, DHookParam hParams)
{
	g_iPreLatch = GetEntData(client, g_iNoiseLatchOffset);
	return MRES_Ignored;
}

// The game only bumps the latch when it accepts the noise, which is also what restarts the fade on clients.
MRESReturn DHook_OnCreateNoise_Post(int client, DHookParam hParams)
{
	if (GetEntData(client, g_iNoiseLatchOffset) != g_iPreLatch) {
		OnNoiseMade(client);
	}

	return MRES_Ignored;
}

void OnNoiseMade(int client)
{
	g_fNoiseTime[client] = GetGameTime();

	// Only need to do this if the fade timer isn't already running
	if (g_hClearTimer[client] == null) {
		ScheduleClear(client);
	}
}

void ScheduleClear(int client)
{
	float fadeRate = g_hCvarFadeRate.FloatValue;
	if (fadeRate <= 0.0) {
		return;
	}

	// Basically CTerrorPlayer::GetNoiseLevel().
	float level = GetEntDataFloat(client, g_iNoiseLevelOffset);
	float delay = g_fNoiseTime[client] + g_hCvarHoldTime.FloatValue + level / fadeRate + NOISE_GRACE_TIME - GetGameTime();

	g_hClearTimer[client] = CreateTimer(delay > 0.0 ? delay : 0.0, Timer_ClearNoise, client);
}

Action Timer_ClearNoise(Handle timer, int client)
{
	g_hClearTimer[client] = null;

	if (!IsClientInGame(client)) {
		return Plugin_Stop;
	}

	float fadeRate = g_hCvarFadeRate.FloatValue;
	float level = GetEntDataFloat(client, g_iNoiseLevelOffset);
	if (level <= 0.0 || fadeRate <= 0.0) {
		return Plugin_Stop;
	}

	if (GetGameTime() < g_fNoiseTime[client] + g_hCvarHoldTime.FloatValue + level / fadeRate + NOISE_GRACE_TIME) {
		ScheduleClear(client);
	}
	else {
		SetEntDataFloat(client, g_iNoiseLevelOffset, 0.0, true);
	}

	return Plugin_Stop;
}

Action Hook_EffectDispatch(const char[] te_name, const int[] players, int numClients, float delay)
{
	if (g_iSmokeCloud == INVALID_STRING_INDEX || TE_ReadNum("m_iEffectName") != g_iParticleEffect || TE_ReadNum("m_nHitBox") != g_iSmokeCloud) {
		return Plugin_Continue;
	}

	int flags = TE_ReadNum("m_fFlags");
	if (flags & PARTICLE_DISPATCH_FROM_ENTITY) {
		TE_WriteNum("m_fFlags", flags & ~PARTICLE_DISPATCH_FROM_ENTITY);
	}

	return Plugin_Continue;
}
