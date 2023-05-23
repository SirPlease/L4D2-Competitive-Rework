#define PLUGIN_VERSION 		"1.7"

/*=======================================================================================
	Change Log:
1.7 (14-Feb-2022) by Harry
	- Remove soul when player changes team.
	- Remove CPR
	
1.6 (22-Oct-2019)
	- Added L4D2 support
	- Fixed case when fader is not worked for negative values
	- Kill soul when player disconnects
	- Kill all souls on round end (for safe)
	- Other safe checks

1.5 (22-Aug-2019)
	- Client is replaced by UserId in sound timer (for safe).

1.4 (05-Apr-2019)
	- Add disconnect
	
1.3 (30-Mar-2019)
	- Laser trace is now begins from the ground regardless if user died in the air
	
1.2 (12-Feb-2019)
	- Added safe plugin unloading
	
1.1 (09-Feb-2019)
	- Fixed "Client is not connected" in DissolveDelayed
	
1.0 (02-Feb-2019)
	- Initial release.

=========================================================================================

	Credits:
	
	- SilverShot - for ragdoll dissolver and basic L4D1 glow support, also L4D2 tests
	https://forums.alliedmods.net/showthread.php?t=306789
	
	- Mehis - for "func_tracktrain" code
	https://forums.alliedmods.net/showpost.php?p=2444932&postcount=3
	
	- 8guawong - for pointing me to above smooth moving code.

=========================================================================================

	Recommended plugins:

	- "Emergency Treatment With First Aid Kit And CPR" by panxiaohai
	https://forums.alliedmods.net/showthread.php?p=1178894
	
	- AutoRespawn (e.g. by Dragokas :) - currently, private only
	
=========================================================================================	

	TODO:
	
	 - Realistic soul origin and angle + reliable fading: they should match the ragdoll position
	 at the end of landing (looks like it is impossible due to client side ragdoll;
	 alternatively: convert client side ragdoll to server side,
	 however, according to Valve wiki it could produce a lot of performance load,
	 so it is not worth the effort)
	 
	 - find a way to fade L4D2 ragdolls.
	 
	 - Increase soul sound volume even more (somehow?)
	 
	 - add other specific animation variants (it require changing the model angle as well)
	 
=======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY

#define SPRITE_GLOW			"sprites/blueglow1.vmt"

#define SF_NOUSERCONTROL    2
#define SF_PASSABLE         8
#define SF_UNBLOCKABLE      512

// max. number of simultaneous effects and objects
// ------------------------------------------------------
const int TRACKS_PER_TRAIN = 2;

#define MAX_DISSOLVE		3
#define MAX_SOUL			4
#define MAX_TRAIN			MAX_SOUL
#define MAX_TRACK			MAX_SOUL * TRACKS_PER_TRAIN
// ------------------------------------------------------

#define SOUL_TIMEOUT		60.0	// maximum life time of soul
#define FALL_SPEED			"300.0" // should be the maximum speed of all values
#define INIT_SPEED			"15.0"	// initial speed of soul
#define INCREASED_SPEED		"50.0"	// speed of soul when CPR timeout
#define FALL_DISSOLVE_DELAY 1.0		// delay after soul finished falling and its dissolving
#define FALL_DISSOLVE_TIME	0.1		// duration of dissolving after falling
#define DISSOLVE_TIME		3.0		// duration of dissolving after death
#define SOUL_ALPHA_CHANNEL	"75"
#define SOUL_COLOR			"255 255 255"
#define SOUL_MAX_HEIGHT		3000.0
#define LASER_BEACON_COLOR	{0, 0, 255, 128}

float BEACON_START_DELAY  = 0.5; 	// default, when CPR plugin is not installed

#define SOUL_SND_LEVEL		SNDLEVEL_GUNFIRE + 10
#define SOUL_SND_MAX_DIST	250.0
#define SOUL_SND_DELAY		4.0

#define SOUND_UP_1			"ambient/atmosphere/cave_hit6.wav"
#define SOUND_UP_2			"music/zombiechoir/zombiechoir_03.wav"
#define SOUND_UP_3			"music/zombiechoir/zombiechoir_04.wav"
#define SOUND_ACCEL_1		"ambient/animal/crow_1.wav"
#define SOUND_ACCEL_1_ALT	"ambient/animal/crow_2.wav"
#define SOUND_ACCEL_2		"ambient/random_amb_sfx/forest_bird01.wav"
#define SOUND_ACCEL_2_ALT	"ambient/random_amb_sfx/forest_bird03.wav"
#define SOUND_ACCEL_3		"ambient/random_amb_sfx/forest_bird01b.wav"
#define SOUND_ACCEL_3_ALT	"ambient/random_amb_sfx/forest_bird02b.wav"
#define SOUND_ACCEL_4		"ambient/random_amb_sfx/rur_random_coyote03.wav"
#define SOUND_ACCEL_4_ALT	"ambient/random_amb_sfx/rur_random_coyote04.wav"
#define SOUND_ACCEL_5		"ambient/random_amb_sfx/rur5b_seagull01.wav"

char g_sAnim[8][64] = {
		"deathpose_front",
		"namvet_intro_wave",
		"Idle_Fall_From_Tongue_germany",
		"Idle_Incap_Standing_SmokerChoke_germany",
		"Idle_Tongued_choking_ground",
		"Idle_Incap_Hanging1",
		"Idle_Incap_Hanging3",
		"Melee_Sweep_Standing_Rifle",
	};

ConVar g_hCvarAllow;
ConVar g_hCvarCprDur;
ConVar g_hCvarCprMaxTime;
ConVar g_hCvarReviveMaxTime;

bool g_bCanDiss, g_bEnabled, g_bLate, g_bLeft4dead2;
int g_iRoundStart, g_iPlayerSpawn, g_iBeaconSprite;
float g_fMaxReviveTime = 0.0;
Handle sdkDissolveCreate;
int g_iSoulAlpha, g_iSoulColor_R, g_iSoulColor_G, g_iSoulColor_B;
int g_iDissolvers[MAX_DISSOLVE];
int g_iSoul[MAX_SOUL];
int g_iTrack[MAX_TRACK];
int g_iTrain[MAX_TRAIN];
int g_iSoulClient[MAXPLAYERS+1];
int g_iEffectClient[MAXPLAYERS+1];
int g_iTrainClient[MAXPLAYERS+1];
int g_iTrackClient[MAXPLAYERS+1][TRACKS_PER_TRAIN];
int g_iRagdoll[MAXPLAYERS+1];
float vVecRagdoll[MAXPLAYERS+1][3];
float g_fDeadTime[MAXPLAYERS+1];


public Plugin myinfo =
{
	name = "[L4D] Death Soul",
	author = "Alex Dragokas, Harry",
	description = "Soul of the dead survivor flies away to the afterlife",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLeft4dead2 = (test == Engine_Left4Dead2);
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	// SDKCalls
	Handle hGameConf = LoadGameConfigFile("l4d_death_soul");
	if( hGameConf == null )
		SetFailState("Couldn't find the offsets and signatures file. Please, check that it is installed correctly.");
	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CEntityDissolve_Create") == false )
		SetFailState("Could not load the \"CEntityDissolve_Create\" gamedata signature.");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	sdkDissolveCreate = EndPrepSDKCall();
	if( sdkDissolveCreate == null )
		SetFailState("Could not prep the \"CEntityDissolve_Create\" function.");
	delete hGameConf;
	
	//RegAdminCmd("sm_b", CmdB, ADMFLAG_ROOT, "");
	
	// CVars
	g_hCvarAllow = CreateConVar(		"l4d_death_soul_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	
	CreateConVar(						"l4d_death_soul_version",			PLUGIN_VERSION,	"Dissolve Infected plugin version.", FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_death_soul");
	
	if (g_bLate) OnAutoConfigsBuffered();
	g_hCvarAllow.AddChangeHook(ConVarChanged_Cvars);
	
	char sColors[3][4];
	ExplodeString(SOUL_COLOR, " ", sColors, sizeof(sColors), sizeof(sColors[]));
	g_iSoulColor_R = StringToInt(sColors[0]);
	g_iSoulColor_G = StringToInt(sColors[1]);
	g_iSoulColor_B = StringToInt(sColors[2]);
	g_iSoulAlpha = StringToInt(SOUL_ALPHA_CHANNEL);
}

/*
public Action CmdB(int client, int args)
{
	float vLoc[3], vAng[3];
	
	GetClientAbsOrigin(client, vLoc);
	GetClientEyeAngles(client, vAng);
	
	vLoc[0] += 50.0;
	vLoc[1] += 70.0;
	vLoc[2] += 30.0;
	
	vAng[0] = 270.0;
	
	int ent;
	
	ent = CreateSoul(client, 15.0);
	TeleportEntity(ent, vLoc, vAng, NULL_VECTOR);
	SetAnimation(ent, "deathpose_front");
	
	//ent = CreateRagdollReplacement(client, vLoc);
	
	PrintToChat(client, "Spawned soul: %i", ent);
	
	return Plugin_Handled;
}
*/

int CreateSoul(int client, float fTimeout = 0.0)
{
	int entity = -1;
	char sName[32], sModel[PLATFORM_MAX_PATH];
	int idx = GetSoulIndex();
	if (idx != -1) {
		Format(sName, sizeof(sName), "soul%i", idx);
		GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel)); // clone model
		
		if (g_bLeft4dead2)
		{
			entity = CreateEntityByName("prop_dynamic_override"); // CDynamicProp
			if (entity != -1) {
				DispatchKeyValue(entity, "targetname", sName);
				DispatchKeyValue(entity, "spawnflags", "0");
				DispatchKeyValue(entity, "solid", "0");
				DispatchKeyValue(entity, "disableshadows", "1");
				//DispatchKeyValue(entity, "rendermode", "1");
				//DispatchKeyValue(entity, "renderamt", "75");
				//DispatchKeyValue(entity, "rendercolor", "255 255 255");
				DispatchKeyValue(entity, "disablereceiveshadows", "1");
				DispatchKeyValue(entity, "model", sModel);
				DispatchKeyValue(entity, "DefaultAnim", g_sAnim[GetRandomInt(0, sizeof(g_sAnim) - 1)] );
				DispatchSpawn(entity);
				AcceptEntityInput(entity, "TurnOn");
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR); 											// for some reason DispatchKeyValue is not working
				SetEntityRenderColor(entity, g_iSoulColor_R,g_iSoulColor_G,g_iSoulColor_B,g_iSoulAlpha);	// for these values in L4D2
				SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
				SetEntProp(entity, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", 180);
				int R = 200, G = 200, B = 200;
				SetEntProp(entity, Prop_Send, "m_glowColorOverride", R + (G << 8) + (B << 16));
				//SetEntProp(entity, Prop_Send, "m_bFlashing", 0);
			}
		}
		else {
			entity = CreateEntityByName("prop_glowing_object"); // CPropGlowingObject
			if (entity != -1) {
				DispatchKeyValue(entity, "targetname", sName);
				DispatchKeyValue(entity, "spawnflags", "0");
				DispatchKeyValue(entity, "solid", "0");
				DispatchKeyValue(entity, "disableshadows", "1");
				DispatchKeyValue(entity, "rendermode", "1");
				DispatchKeyValue(entity, "renderamt", SOUL_ALPHA_CHANNEL);
				DispatchKeyValue(entity, "rendercolor", SOUL_COLOR);
				DispatchKeyValue(entity, "disablereceiveshadows", "1");
				DispatchKeyValue(entity, "model", sModel);
				//DispatchKeyValue(entity, "DefaultAnim", "Shoved_Backward");
				DispatchKeyValue(entity, "DefaultAnim", g_sAnim[GetRandomInt(0, sizeof(g_sAnim) - 1)] );
				DispatchSpawn(entity);
				AcceptEntityInput(entity, "TurnOn");
			}
		}
		if (entity != -1) {
			if (fTimeout >= 0.0) {
				if (fTimeout == 0.0) fTimeout = SOUL_TIMEOUT - 0.1;
				SetEntityKillTimer(entity, fTimeout);
			}
			g_iSoul[idx] = EntIndexToEntRef(entity);
			g_iSoulClient[client] = g_iSoul[idx];
		}
	}
	return entity;
}

void SetAnimation(int entity, char[] sAnimName)
{
	SetEntPropFloat(entity, Prop_Send, "m_flCycle", 1.0);
	SetVariantString(sAnimName);
	AcceptEntityInput(entity, "SetDefaultAnimation");
	SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", 1.0);
}

int CreateRagdollReplacement(int client, float vecOrigin[3])
{
	int entity = CreateEntityByName("prop_dynamic_override"); // CDynamicProp
	if (entity != -1) {
		char sModel[PLATFORM_MAX_PATH];
		GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel)); // clone model
		DispatchKeyValue(entity, "spawnflags", "0");
		DispatchKeyValue(entity, "solid", "0");
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchKeyValue(entity, "rendermode", "1");
		DispatchKeyValue(entity, "renderfx", "6");
		DispatchKeyValue(entity, "renderamt", "0");
		DispatchKeyValue(entity, "rendercolor", "255 255 255");
		DispatchKeyValue(entity, "disablereceiveshadows", "1");
		DispatchKeyValue(entity, "model", sModel);
		DispatchKeyValue(entity, "DefaultAnim", "ragdoll");
		DispatchKeyValueVector(entity, "origin", vecOrigin);
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "TurnOn");
	}
	return entity;
}

public void OnMapStart()
{
	PrecacheModel(SPRITE_GLOW, true);
	if (g_bLeft4dead2)
	{
		g_iBeaconSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	}
	else {
		g_iBeaconSprite = PrecacheModel("materials/sprites/laser.vmt");	
	}
	PrecacheGeneric("particles/fire_01.pcf", true);
	PrecacheGeneric("particles/fire_01l4d.pcf", true);
	PrecacheParticleEffect("burning_wood_01");
	PrecacheParticleEffect("burning_wood_01b");
	PrecacheParticleEffect("fire_window_glow");
	PrecacheSound(SOUND_UP_1, true);
	PrecacheSound(SOUND_UP_2, true);
	PrecacheSound(SOUND_UP_3, true);
	PrecacheSound(SOUND_ACCEL_1, true);
	PrecacheSound(SOUND_ACCEL_1_ALT, true);
	PrecacheSound(SOUND_ACCEL_2, true);
	PrecacheSound(SOUND_ACCEL_2_ALT, true);
	PrecacheSound(SOUND_ACCEL_3, true);
	PrecacheSound(SOUND_ACCEL_3_ALT, true);
	PrecacheSound(SOUND_ACCEL_4, true);
	PrecacheSound(SOUND_ACCEL_4_ALT, true);
	PrecacheSound(SOUND_ACCEL_5, true);
}

public void OnPluginEnd()
{
	ResetPlugin();
}

void ResetPlugin()
{
	g_bCanDiss = false;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	for (int i = 1; i <= MaxClients; i++)
		KillSoul(i);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(2.0, tmrLoad, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
	
	for (int i = 0; i <= MaxClients; i++) {
		g_iSoulClient[i] = 0;
		g_iEffectClient[i] = 0;
		g_iRagdoll[i] = 0;
		g_iTrainClient[i] = 0;
		for (int j = 0; j < TRACKS_PER_TRAIN; j++)
			g_iTrackClient[i][j] = 0;
	}
	for (int i = 0; i < MAX_DISSOLVE; i++) g_iDissolvers[i] = 0;
	for (int i = 0; i < MAX_SOUL; i++) g_iSoul[i] = 0;
	for (int i = 0; i < MAX_TRACK; i++) g_iTrack[i] = 0;
	for (int i = 0; i < MAX_TRAIN; i++) g_iTrain[i] = 0;
}

public Action tmrLoad(Handle timer)
{
	LoadPlugin();

	return Plugin_Continue;
}

void LoadPlugin()
{
	g_bCanDiss = true;
}

// ====================================================================================================
//					CVARS
// ====================================================================================================

public void OnAutoConfigsBuffered() // to allow CPR plugin to create own convars
{
	// ReviveCPR plugin support
	g_hCvarCprDur = FindConVar("l4d_CPR_duration");
	g_hCvarCprMaxTime = FindConVar("l4d_CPR_maxtime");
	g_hCvarReviveMaxTime = FindConVar("l4d_revive_maxtime");
	
	if (g_hCvarCprDur != null) g_hCvarCprDur.AddChangeHook(ConVarChanged_Cvars);
	if (g_hCvarCprMaxTime != null) g_hCvarCprMaxTime.AddChangeHook(ConVarChanged_Cvars);
	if (g_hCvarReviveMaxTime != null) g_hCvarReviveMaxTime.AddChangeHook(ConVarChanged_Cvars);
	
	GetCvars();
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_hCvarAllow.BoolValue;
	
	if (g_hCvarCprMaxTime != null && g_hCvarCprDur != null)
	{
		g_fMaxReviveTime = g_hCvarReviveMaxTime.FloatValue;
		BEACON_START_DELAY = g_hCvarCprMaxTime.FloatValue - g_hCvarCprDur.FloatValue - 1.0; // should indicate the moment when you can't CPR
		if (BEACON_START_DELAY <= 0.0) BEACON_START_DELAY = 0.5;
	}
	InitHook();
}

void InitHook()
{
	static bool bHooked;

	if (g_bEnabled) {
		if (!bHooked) {
			HookEvent("round_end",			Event_RoundEnd,			EventHookMode_PostNoCopy);
			HookEvent("finale_win", 		Event_RoundEnd,			EventHookMode_PostNoCopy);
			HookEvent("mission_lost", 		Event_RoundEnd,			EventHookMode_PostNoCopy);
			HookEvent("map_transition", 	Event_RoundEnd,			EventHookMode_PostNoCopy);
			HookEvent("round_start",		Event_RoundStart,		EventHookMode_PostNoCopy);
			HookEvent("player_spawn",		Event_PlayerSpawn);
			HookEvent("survivor_rescued", 	Event_Survivor_Rescued);
			HookEvent("player_disconnect", 	Event_PlayerDisconnect, EventHookMode_Pre);	
			HookEvent("player_death",		Event_Death,			EventHookMode_Pre);
			HookEvent("player_team", Event_PlayerTeam);
			bHooked = true;
			LoadPlugin();
		}
	} else {
		if (bHooked) {
			UnhookEvent("round_end",		Event_RoundEnd,			EventHookMode_PostNoCopy);
			UnhookEvent("finale_win", 		Event_RoundEnd,			EventHookMode_PostNoCopy);
			UnhookEvent("mission_lost", 	Event_RoundEnd,			EventHookMode_PostNoCopy);
			UnhookEvent("map_transition", 	Event_RoundEnd,			EventHookMode_PostNoCopy);
			UnhookEvent("round_start",		Event_RoundStart,		EventHookMode_PostNoCopy);
			UnhookEvent("player_spawn",		Event_PlayerSpawn);
			UnhookEvent("survivor_rescued", Event_Survivor_Rescued);
			UnhookEvent("player_disconnect",Event_PlayerDisconnect, EventHookMode_Pre);	
			UnhookEvent("player_death",		Event_Death,			EventHookMode_Pre);
			UnhookEvent("player_team", Event_PlayerTeam);
			bHooked = false;
			ResetPlugin();
		}
	}
}

// ====================================================================================================
//					EVENT
// ====================================================================================================

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (client != 0) {
		KillSoul(client);
	}
	return Plugin_Continue;
}

public void Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	if( g_bCanDiss)
	{
		int UserId = event.GetInt("userid");
		int target = GetClientOfUserId(UserId);
		
		if (target != 0 && IsClientInGame(target) && GetClientTeam(target) == 2) {
		
			int ragdoll;
			
			if (g_bLeft4dead2)
			{
				// ragdoll is important entity in L4D2, so don't touch it
				GetClientAbsOrigin(target, vVecRagdoll[target]);
				ragdoll = CreateRagdollReplacement(target, vVecRagdoll[target]);
				g_iRagdoll[target] = -1; // fader is not work on L4D2 ragdolls (why?)
			}
			else {
				ragdoll = GetEntPropEnt(target, Prop_Send, "m_hRagdoll"); // CCSRagdoll
				if( ragdoll > 0 && IsValidEntity(ragdoll) )
				{
					g_iRagdoll[target] = EntIndexToEntRef(ragdoll);
					GetEntPropVector(target, Prop_Data, "m_vecOrigin", vVecRagdoll[target]);
				}
			}
			
			if (ragdoll > 0)
			{
				vVecRagdoll[target][2] += 10.0 - GetDistanceToFloor(target);
				DissolveTarget(ragdoll);
			}
			else {
				GetClientAbsOrigin(target, vVecRagdoll[target]);
			}
			
			// if previous soul had no time to dissolve => kill it
			KillSoul(target);
			
			CreateFlySoul(target);
			
			/* for dissolving entity on the highest point
			int track = EntRefToEntIndex(g_iTrackClient[target][TRACKS_PER_TRAIN - 1]);
			
			if (track && track != INVALID_ENT_REFERENCE && IsValidEntity(track))
			{
				HookSingleEntityOutput(track, "OnPass", Callback_TrainPointPass, true);
			}
			*/

			g_fDeadTime[target] = GetEngineTime();
			CreateTimer(BEACON_START_DELAY, Timer_SetBeacon, UserId, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(BEACON_START_DELAY, Timer_TrainSpeed, UserId, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(SOUL_SND_DELAY, Timer_PlaySound, UserId, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	KillSoul(client);
}

public Action Timer_PlaySound(Handle timer, int UserId) // set increased speed of the train when CPR timeout
{
	int client = GetClientOfUserId(UserId);
	if (client != 0) {
		int soul = EntRefToEntIndex(g_iSoulClient[client]);
		
		if (soul && soul != INVALID_ENT_REFERENCE && IsValidEntity(soul))
		{
			PlaySoundAmbient(client, false);
		}
	}

	return Plugin_Continue;
}

void PlaySoundAmbient(int victim, bool bSoulAccel)
{
	if (bSoulAccel) {
		switch(GetRandomInt(1, 5))
		{
			case 1: EmitAmbientSound(GetRandomInt(0, 1) == 0 ? SOUND_ACCEL_1 : SOUND_ACCEL_1_ALT, vVecRagdoll[victim], SOUND_FROM_WORLD, SOUL_SND_LEVEL, SND_NOFLAGS, 1.0);
			case 2: EmitAmbientSound(GetRandomInt(0, 1) == 0 ? SOUND_ACCEL_2 : SOUND_ACCEL_2_ALT, vVecRagdoll[victim], SOUND_FROM_WORLD, SOUL_SND_LEVEL, SND_NOFLAGS, 1.0);
			case 3: EmitAmbientSound(GetRandomInt(0, 1) == 0 ? SOUND_ACCEL_3 : SOUND_ACCEL_3_ALT, vVecRagdoll[victim], SOUND_FROM_WORLD, SOUL_SND_LEVEL, SND_NOFLAGS, 1.0);
			case 4: EmitAmbientSound(GetRandomInt(0, 1) == 0 ? SOUND_ACCEL_4 : SOUND_ACCEL_4_ALT, vVecRagdoll[victim], SOUND_FROM_WORLD, SOUL_SND_LEVEL, SND_NOFLAGS, 1.0);
			case 5: EmitAmbientSound(SOUND_ACCEL_5, vVecRagdoll[victim], SOUND_FROM_WORLD, SOUL_SND_LEVEL, SND_NOFLAGS, 1.0);
		}
	}
	else {
		// max. volume level for these kind of sounds is too quiet, that's why I'm using own "ambient" version based on the max. distance to player + EmitSound directly to player
		// + some timer + pitch magik :)
		EmitSoundToAllDist(vVecRagdoll[victim], SOUL_SND_MAX_DIST, SOUND_UP_1, _, _, SOUL_SND_LEVEL, _, _, SNDPITCH_HIGH); 		// general channel
		CreateTimer(0.3, Timer_SoundPitch, GetClientUserId(victim), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE); 					// music channel
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(2.0, tmrLoad, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;

	int UserId = event.GetInt("userid");
	if (UserId != 0)
	{
		int client = GetClientOfUserId(UserId);
		if (client != 0 && GetClientTeam(client) == 2)
			OnSurvivorSpawn(client);
	}
}

public void Event_Survivor_Rescued(Event event, const char[] name, bool dontBroadcast)
{
	int UserId = event.GetInt("victim");
	if (UserId != 0)
	{
		int client = GetClientOfUserId(UserId);
		if (client != 0)
			OnSurvivorSpawn(client);
	}
}

void OnSurvivorSpawn(int client)
{
	if (!g_bCanDiss) return;

	int train = EntRefToEntIndex(g_iTrainClient[client]);

	if (train && train != INVALID_ENT_REFERENCE && IsValidEntity(train))
	{
		SetVariantString(FALL_SPEED);
		AcceptEntityInput(train, "SetSpeedReal");
		AcceptEntityInput(train, "Reverse");
	}
	
	int track = EntRefToEntIndex(g_iTrackClient[client][0]);
	
	if (track && track != INVALID_ENT_REFERENCE && IsValidEntity(track))
	{
		HookSingleEntityOutput(track, "OnPass", Callback_TrainPointPass, true);
	}
	
	// remove previous effect
	int effect = EntRefToEntIndex(g_iEffectClient[client]);

	if (effect && effect != INVALID_ENT_REFERENCE && IsValidEntity(effect))
	{
		AcceptEntityInput(effect, "Kill");
		g_iEffectClient[client] = 0;
	}
	
	int soul = EntRefToEntIndex(g_iSoulClient[client]);
	
	if (soul && soul != INVALID_ENT_REFERENCE && IsValidEntity(soul))
	{
		SetAnimation(soul, "Idle_Falling");
	}
	
	if( g_iRagdoll[client] != 0) { // remove original ragdoll if player is alive
		FadeRagdoll( _, client );  // pass saved vector, because ragdoll entity is no more valid
		g_iRagdoll[client] = 0;
	}
}

public void Callback_TrainPointPass(const char[] output, int caller, int activator, float delay) // the train went back to the starting point
{
	if (!g_bCanDiss) return;
	
	int iTrackRef = EntIndexToEntRef(caller);
	
	for (int client = 1; client <= MaxClients; client++) {
		// find client (owner)
		if (g_iTrackClient[client][0] == iTrackRef) {
			
			int soul = EntRefToEntIndex(g_iSoulClient[client]);
			
			if (soul && soul != INVALID_ENT_REFERENCE && IsValidEntity(soul))
			{
				SpawnEffect(client, soul, "fire_window_glow", FALL_DISSOLVE_DELAY + FALL_DISSOLVE_TIME, 90.0); // fast bright glow
				
				DissolveDelayed(client, g_iSoulClient[client], FALL_DISSOLVE_DELAY, FALL_DISSOLVE_TIME);
			}
			break;
		}
	}
}

// ====================================================================================================
//					TIMERS
// ====================================================================================================

public Action Timer_TrainSpeed(Handle timer, int UserId) // set increased speed of the train when CPR timeout
{
	int client = GetClientOfUserId(UserId);
	if (client != 0 && g_bCanDiss)
	{
		int train = EntRefToEntIndex(g_iTrainClient[client]);
		
		if (train && train != INVALID_ENT_REFERENCE && IsValidEntity(train))
		{
			SetVariantString(INCREASED_SPEED);
			AcceptEntityInput(train, "SetSpeedReal");
		}
		
		int soul = EntRefToEntIndex(g_iSoulClient[client]);
		
		if (soul && soul != INVALID_ENT_REFERENCE && IsValidEntity(soul))
		{
			switch (GetRandomInt(0, 1)) {
				case 0: {
					SpawnEffect(client, soul, "burning_wood_01", SOUL_TIMEOUT - 0.2, g_bLeft4dead2 ? 0.0 : 90.0);
				}
				case 1: {
					SpawnEffect(client, soul, "burning_wood_01b", SOUL_TIMEOUT - 0.2, 90.0);
				}
			}
			
			PlaySoundAmbient(client, true);
		}
	}

	return Plugin_Continue;
}

void DissolveDelayed(int client, int iEntRef, float fTimeout, float dissTime) // delay to let people see animation and bright glow effect
{
	if (IsClientInGame(client)) {
		DataPack dp = new DataPack();
		dp.WriteCell(GetClientUserId(client));
		dp.WriteCell(iEntRef);
		dp.WriteFloat(dissTime);
		CreateTimer(fTimeout, Timer_Dissolve, dp, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
	}
}

public Action Timer_Dissolve(Handle timer, DataPack dp)
{
	dp.Reset();
	int client = GetClientOfUserId(dp.ReadCell());
	int soul = EntRefToEntIndex(dp.ReadCell());
	float dissTime = dp.ReadFloat();
	DissolveTarget(soul, dissTime, client);

	return Plugin_Continue;
}

public Action Timer_SetBeacon(Handle timer, int UserId) // pulse laser beacon
{
	int client = GetClientOfUserId(UserId);
	
	if (client != 0 && IsClientInGame(client) && !IsPlayerAlive(client) && GetClientTeam(client) == 2 && g_bCanDiss)
	{
		if (g_fMaxReviveTime > 0.0 && (GetEngineTime() - g_fDeadTime[client]) > g_fMaxReviveTime) // stop laser when no more possible to revive
			return Plugin_Stop;
		
		float vAura[3];
		//GetClientAbsOrigin(client, vAura);
		Array_Copy(vVecRagdoll[client], vAura, sizeof(vAura));
		
		float end[3];
		end[0] = vAura[0];
		end[1] = vAura[1];
		end[2] = vAura[2] + SOUL_MAX_HEIGHT;
		
		if (g_bLeft4dead2) {
			TE_SetupBeamPoints(vAura, end, g_iBeaconSprite, 0, 30, 0, 3.5, 1.0, 20.0, 7, 0.0, LASER_BEACON_COLOR, 0);
		}
		else {
			TE_SetupBeamPoints(vAura, end, g_iBeaconSprite, 0, 30, 0, 3.5, 10.0, 100.0, 7, 0.0, LASER_BEACON_COLOR, 0);
		}
		TE_SendToAll();
		
		CreateTimer(3.0, Timer_SetBeacon, UserId, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

// ====================================================================================================
//					FUNCTIONS
// ====================================================================================================

void DissolveTarget(int target, float time = 3.0, int client = 0)
{
	// CreateEntityByName "env_entity_dissolver" has broken particles, this way works 100% of the time
	
	if (target && IsValidEntity(target))
	{
		int index = GetDissolveIndex();
		if (index != -1 && g_bCanDiss)
		{
			int dissolver = SDKCall(sdkDissolveCreate, target, "", GetGameTime() + time, 2, false);
			
			if( dissolver > MaxClients && IsValidEntity(dissolver) )
			{
				g_iDissolvers[index] = EntIndexToEntRef(dissolver);
				SetEntPropFloat(dissolver, Prop_Send, "m_flFadeOutStart", 0.0); // Fixes broken particles
			}
			// target entity is being killed by dissolver after a while
		}
		else {
			char sClass[32];
			GetEntityNetClass(target, sClass, sizeof(sClass));
			if (strcmp(sClass, "CCSRagdoll") != 0) // don't touch ragdolls since they are controlled by the game
			{
				AcceptEntityInput(target, "Kill");
			}
		}
	}
	// do not clear objects if player is dead again! - in that case old objects are already cleared by Event_Death
	if (client != 0	&& (!IsClientInGame(client) || (IsClientInGame(client) && IsPlayerAlive(client)))) {
		CreateTimer(time + 0.1, Timer_KillSoul, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	//CreateTimer(5.0, Timer_GetRagdolls);
}

/*
public Action Timer_GetRagdolls(Handle timer)
{
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "cs_ragdoll")) != -1)
	{
		PrintToChatAll("Found ragdoll = %i", ent);
	}
}
*/

void FadeRagdoll(int ragdoll = -1, int client = -1)
{
	int fader = CreateEntityByName("func_ragdoll_fader");
	if( fader != -1 )
	{
		if (ragdoll != -1) {
			float vec[3];
			GetEntPropVector(ragdoll, Prop_Data, "m_vecOrigin", vec);
			TeleportEntity(fader, vec, NULL_VECTOR, NULL_VECTOR);
		}
		else if (client != -1) {
			TeleportEntity(fader, vVecRagdoll[client], NULL_VECTOR, NULL_VECTOR);
		}
		DispatchSpawn(fader);
		
		SetEntPropVector(fader, Prop_Send, "m_vecMaxs", view_as<float>({ 30.0, 30.0, 30.0 }));
		SetEntPropVector(fader, Prop_Send, "m_vecMins", view_as<float>({ -30.0, -30.0, -30.0 }));
		
		SetEntProp(fader, Prop_Send, "m_nSolidType", 2);

		SetVariantString("OnUser1 !self:Kill::0.1:1");
		AcceptEntityInput(fader, "AddOutput");
		AcceptEntityInput(fader, "FireUser1");
	}
}

int CreateFlySoul(int client)
{
	// Create all paths and link them together.
	// This has to be done in reverse since target linking is done on entity activation.
	char trackname[32], trainname[32];
	char prevtrackname[32];
	int idx, track, soul = -1;
	float vLoc[3], vVecTracks[TRACKS_PER_TRAIN][3];
	
	//GetClientAbsOrigin(client, vLoc);
	Array_Copy(	vVecRagdoll[client], vLoc, sizeof(vLoc));
	
	// Y-axis (starting point), reduction in height is required for preventing a glitch of rebounding the train from the first point, when speed is too high
	vLoc[2] -= 40.0; 
	Array_Copy(vLoc, vVecTracks[0], sizeof(vLoc));
	Array_Copy(vLoc, vVecTracks[1], sizeof(vLoc));
	vVecTracks[1][2] += SOUL_MAX_HEIGHT; // max vertical pos
	
	for ( int i = TRACKS_PER_TRAIN - 1; i >= 0; i-- )
	{
		idx = GetTrackIndex();
		if (idx == -1) return -1;
	
		Format( trackname, sizeof( trackname ), "_track%i", idx );
		
		track = CreatePath( trackname, vVecTracks[i], prevtrackname );
		
		g_iTrack[idx] = EntIndexToEntRef(track);
		g_iTrackClient[client][i] = g_iTrack[idx];
		
		strcopy( prevtrackname, sizeof( prevtrackname ), trackname );
	}
	
	// Create func_tracktrain
	
	idx = GetTrainIndex();
	if (idx == -1) return -1;
	
	Format( trainname, sizeof( trainname ), "_train%i", idx );
	
	int train = CreateTrackTrain( trainname, trackname );
	
	if (train != -1)
	{
		g_iTrain[idx] = EntIndexToEntRef(train);
		g_iTrainClient[client] = g_iTrain[idx];
	
		// Create our entity that requires to move
		soul = CreateSoul(client);
		
		if (soul != -1) {
			//CreateGlow(soul, client);
			
			// Parent it to func_tracktrain
			ParentToEntity( soul, train );
		}
	}
	return soul;
}

stock void Array_Copy(const any[] array, any[] newArray, int size)
{
	for (int i=0; i < size; i++) {
		newArray[i] = array[i];
	}
}

void SetEntityKillTimer(int ent, float time)
{
	char sRemove[64];
	Format(sRemove, sizeof(sRemove), "OnUser1 !self:Kill::%f:1", time);
	SetVariantString(sRemove);
	AcceptEntityInput(ent, "AddOutput");
	AcceptEntityInput(ent, "FireUser1");
}

int CreateTrackTrain( char[] name, char[] firstpath)
{
	int ent = CreateEntityByName( "func_tracktrain" ); // CFuncTrackTrain
	if ( ent < 1 )
	{
		LogError( "Couldn't create func_tracktrain!" );
		return -1;
	}
	char spawnflags[12];
	Format( spawnflags, sizeof( spawnflags ), "%i", SF_NOUSERCONTROL | SF_PASSABLE | SF_UNBLOCKABLE );
	
	DispatchKeyValue( ent, "targetname", name );
	DispatchKeyValue( ent, "target", firstpath );
	DispatchKeyValue( ent, "startspeed", FALL_SPEED ); // max speed (WTF. Drunked SDK developers)
	DispatchKeyValue( ent, "speed", INIT_SPEED ); // start speed
	//DispatchKeyValue( ent, "velocitytype", "2" ); // non-zero value broke "Reverse" input! ("Stop", "Resume" walkaround is work partially only)
	
	// Make turning smoother, remove the shadow of attached entity
	DispatchKeyValue( ent, "wheels", "256" );
	DispatchKeyValue( ent, "bank", "20" );
	DispatchKeyValue( ent, "orientationtype", "0" ); // 0 - do not change the angle of attached entity when train dir. changed
	
	DispatchKeyValue( ent, "spawnflags", spawnflags );
	DispatchSpawn( ent );
	
	SetEntityKillTimer(ent, SOUL_TIMEOUT);
	
	// Brush model specific stuff
	//SetEntProp( ent, Prop_Send, "m_fEffects", 32 );
	return ent;
}

int CreatePath( char[] name, float pos[3], char[] nexttarget )
{
	int ent = CreateEntityByName( "path_track" );
	if ( ent < 1 )
	{
		LogError( "Couldn't create path_track!" );
		return -1;
	}
	DispatchKeyValue( ent, "targetname", name );
	DispatchKeyValue( ent, "target", nexttarget );
	DispatchSpawn( ent );
	
	// path_tracks have to be activated to assign targets.
	ActivateEntity( ent );
	TeleportEntity( ent, pos, NULL_VECTOR, NULL_VECTOR );
	SetEntityKillTimer(ent, SOUL_TIMEOUT + 0.1); // paths should be removed not sooner than train, otherwise - crash!
	return ent;
}

bool ParentToEntity( int ent, int target )
{
	SetVariantEntity( target );
	return AcceptEntityInput( ent, "SetParent" );
}

int SpawnEffect(int client, int target, char[] sParticleName, float fTimeout, float XRotation)
{
	int iEntity = CreateEntityByName("info_particle_system", -1);
	if (iEntity != -1)
	{
		float vLoc[3], vAng[3];
		
		vLoc[0] = 0.0;
		vLoc[1] = -10.0;
		vLoc[2] = 0.0;
		
		vAng[0] = 0.0;
		vAng[1] = XRotation;
		vAng[2] = 0.0;
		
		DispatchKeyValue(iEntity, "effect_name", sParticleName);
		//GetEntPropVector(target, Prop_Data, "m_vecOrigin", vLoc);
		//DispatchKeyValueVector(iEntity, "origin", vLoc);
		//DispatchKeyValueVector(iEntity, "angles", vAng);
		DispatchSpawn(iEntity);
		
		SetVariantString("!activator"); 
		AcceptEntityInput(iEntity, "SetParent", target);
		SetVariantString("spine");
		AcceptEntityInput(iEntity, "SetParentAttachment");
		
		TeleportEntity(iEntity, vLoc, vAng, NULL_VECTOR);
		
		ActivateEntity(iEntity);
		AcceptEntityInput(iEntity, "Start");
		SetEntityKillTimer(iEntity, fTimeout);
		g_iEffectClient[client] = EntIndexToEntRef(iEntity);
	}
	return iEntity;
}

stock void PrecacheEffect(const char[] sEffectName) // thanks to Dr. Api
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
    {
        table = FindStringTable("EffectDispatch");
    }
    bool save = LockStringTables(false);
    AddToStringTable(table, sEffectName);
    LockStringTables(save);
}

stock void PrecacheParticleEffect(const char[] sEffectName) // thanks to Dr. Api
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
    {
        table = FindStringTable("ParticleEffectNames");
    }
    bool save = LockStringTables(false);
    AddToStringTable(table, sEffectName);
    LockStringTables(save);
}

stock void EmitSoundToAllDist(float vOrigin[3],
				float maxdist,
				const char[] sample,
				int entity = SOUND_FROM_PLAYER,
				int channel = SNDCHAN_AUTO,
				int level = SNDLEVEL_NORMAL,
				int flags = SND_NOFLAGS,
				float volume = SNDVOL_NORMAL,
				int pitch = SNDPITCH_NORMAL,
				int speakerentity = -1,
				const float origin[3] = NULL_VECTOR,
				const float dir[3] = NULL_VECTOR,
				bool updatePos = true,
				float soundtime = 0.0)
{
	float vPos[3];
	for (int client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client) && !IsFakeClient(client)) {
			GetClientAbsOrigin(client, vPos);
			if (GetVectorDistance(vOrigin, vPos) <= maxdist)
				EmitSoundToClient(client, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
		}
	}
}

public Action Timer_SoundPitch(Handle timer, int UserId)
{
	static int pitch = SNDPITCH_HIGH + 30, times = 0;
	static char sSnd[PLATFORM_MAX_PATH];
	
	int client = GetClientOfUserId(UserId);
	if (client == 0)
		return Plugin_Stop;
	
	if (times == 0) {
		switch(GetRandomInt(1, 3)) {
			case 1: strcopy(sSnd, sizeof(sSnd), SOUND_UP_1);
			case 2: strcopy(sSnd, sizeof(sSnd), SOUND_UP_2);
			case 3: strcopy(sSnd, sizeof(sSnd), SOUND_UP_3);
		}
	}
	EmitAmbientSound(sSnd, vVecRagdoll[client], SOUND_FROM_WORLD, SOUL_SND_LEVEL, SND_CHANGEVOL | SND_CHANGEPITCH, 1.0, pitch, 0.0);
	pitch++;
	times++;

	if (times >= 4) {
		times = 0;
		pitch = SNDPITCH_HIGH + 30;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

stock float GetDistanceToFloor(int client)
{ 
	float fStart[3], fDistance = 0.0;
	
	if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == 0)
		return 0.0;
	
	GetClientAbsOrigin(client, fStart);
	
	fStart[2] += 10.0;
	
	Handle hTrace = TR_TraceRayFilterEx(fStart, view_as<float>({90.0, 0.0, 0.0}), MASK_PLAYERSOLID, RayType_Infinite, TraceRayNoPlayers, client); 
	if (hTrace != INVALID_HANDLE)
	{
		if(TR_DidHit(hTrace))
		{
			float fEndPos[3];
			TR_GetEndPosition(fEndPos, hTrace);
			fStart[2] -= 10.0;
			fDistance = GetVectorDistance(fStart, fEndPos);
		}
		else {
			//PrintToChat(client, "Trace did not hit anything!");
		}
		CloseHandle(hTrace);
	}
	return fDistance; 
}

public bool TraceRayNoPlayers(int entity, int mask, any data)
{
    if(entity == data || (entity >= 1 && entity <= MaxClients))
    {
        return false;
    }
    return true;
}

// ====================================================================================================
//					CLEAN & LIMITS
// ====================================================================================================

public Action Timer_KillSoul (Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	if (client != 0)
		KillSoul(client);

	return Plugin_Continue;
}

void KillSoul(int client)
{
	//if (!g_bCanDiss) return;

	int effect = EntRefToEntIndex(g_iEffectClient[client]);

	if (effect && effect != INVALID_ENT_REFERENCE && IsValidEntity(effect))
	{
		AcceptEntityInput(effect, "Kill");
		g_iEffectClient[client] = 0;
	}
	
	int soul = EntRefToEntIndex(g_iSoulClient[client]);
	
	if (soul && soul != INVALID_ENT_REFERENCE && IsValidEntity(soul))
	{
		AcceptEntityInput(soul, "Kill");
		g_iSoulClient[client] = 0;
	}
	
	int train = EntRefToEntIndex(g_iTrainClient[client]);

	if (train && train != INVALID_ENT_REFERENCE && IsValidEntity(train))
	{
		AcceptEntityInput(train, "Kill");
		g_iTrainClient[client] = 0;
	}
	
	int track;
	for (int i = 0; i < sizeof(g_iTrackClient[]); i++) {
		track = EntRefToEntIndex(g_iTrackClient[client][i]);
		
		if (track && track != INVALID_ENT_REFERENCE && IsValidEntity(track))
		{
			AcceptEntityInput(track, "Kill");
			g_iTrackClient[client][i] = 0;
		}
	}
}

// entity limits
int GetDissolveIndex()
{
	int index = -1;
	for( int i = 0; i < MAX_DISSOLVE; i++ )
	{
		if( g_iDissolvers[i] == 0 || EntRefToEntIndex(g_iDissolvers[i]) == INVALID_ENT_REFERENCE )
		{
			index = i;
			break;
		}
	}
	return index;
}

int GetSoulIndex()
{
	int index = -1;
	for( int i = 0; i < MAX_SOUL; i++ )
	{
		if( g_iSoul[i] == 0 || EntRefToEntIndex(g_iSoul[i]) == INVALID_ENT_REFERENCE )
		{
			index = i;
			break;
		}
	}
	return index;
}

int GetTrackIndex()
{
	int index = -1;
	for( int i = 0; i < MAX_TRACK; i++ )
	{
		if( g_iTrack[i] == 0 || EntRefToEntIndex(g_iTrack[i]) == INVALID_ENT_REFERENCE )
		{
			index = i;
			break;
		}
	}
	return index;
}

int GetTrainIndex()
{
	int index = -1;
	for( int i = 0; i < MAX_TRAIN; i++ )
	{
		if( g_iTrain[i] == 0 || EntRefToEntIndex(g_iTrain[i]) == INVALID_ENT_REFERENCE )
		{
			index = i;
			break;
		}
	}
	return index;
}