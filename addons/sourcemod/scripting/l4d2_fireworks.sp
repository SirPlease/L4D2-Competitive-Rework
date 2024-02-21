/*
*	Fireworks Party
*	Copyright (C) 2020 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION		"1.10"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Fireworks Party
*	Author	:	SilverShot (idea by jjjapan)
*	Descrp	:	Adds fireworks to the firework crate explosions.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=153783
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.10 (30-Sep-2020)
	- Fixed compile errors on SM 1.11.

1.9 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.

1.8 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.7.1 (28-Jun-2019)
	- Changed PrecacheParticle function method.

1.7 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Fixed "l4d2_fireworks_modes_tog" was never activated.

1.6 (10-May-2012)
	- Added cvar "l4d2_fireworks_modes" to control which game modes the plugin works in.
	- Added cvar "l4d2_fireworks_modes_off" same as above.
	- Added cvar "l4d2_fireworks_modes_tog" same as above.
	- Optimized the plugin by hooking cvar changes.
	- Fixed a bug which could cause a server to lock up.
	- Removed max entity check and related error logging.

1.5 (22-May-2011)
	- Added check for scavenge items to disable converting of gascans.
	- Added check to not spawn fireworks when GetEntityCount reaches MAX_ENTITIES.
	- Added 6 second delay after the first player spawns or round_start to convert items to firework crates.
	- Changed cvar defaults for "l4d2_fireworks_convert_propane", "l4d2_fireworks_convert_oxygen", "l4d2_fireworks_convert_gas" to "50".
	- Changed cvar default for "l4d2_fireworks_chase" from 10 to 15.
	- Changed cvar default for "l4d2_fireworks_allow_gas" from 1 to 0.

1.4 (18-May-2011)
	- Added cvar "l4d2_fireworks_chase" - which controls how long zombies are attracted to firework explosions.

1.3 (10-Apr-2011)
	- Added admin command "sm_fw" or "sm_fireworks" to spawn fireworks on crosshair position.

1.2 (03-Apr-2011)
	- Added cvar "l4d2_fireworks_allow_gas" to display fireworks on gascan explosions.
	- Added cvar "l4d2_fireworks_allow_oxygen" to display fireworks on oxygen tank explosions.
	- Added cvar "l4d2_fireworks_allow_propane" to display fireworks on propane tank explosions.
	- Added cvar "l4d2_fireworks_convert_oxygen" to convert a percentage of oxygen tanks into firework crates.
	- Added cvar "l4d2_fireworks_convert_propane" to convert a percentage of propane tanks into firework crates.

1.1 (02-Apr-2011)
	- Added cvar "l4d2_fireworks_convert_gas" to convert a percentage of gascans into firework crates.
	- Changed various default cvars and cvar limits.

1.0 (29-Mar-2011)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "honorcode23" for PrecacheParticle()

*	"Zuko & McFlurry" for "[L4D2] Weapon/Zombie Spawner" - Modified the SetTeleportEndPoint()
	https://forums.alliedmods.net/showthread.php?t=109659

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS				FCVAR_NOTIFY
#define MAX_PARTICLES			50 // WARNING: excessive amounts of fireworks can crash the game!

#define MODEL_CRATE				"models/props_junk/explosive_box001.mdl"
#define MODEL_GASCAN			"models/props_junk/gascan001a.mdl"
#define MODEL_OXYGEN			"models/props_equipment/oxygentank01.mdl"
#define MODEL_PROPANE			"models/props_junk/propanecanister001a.mdl"


// Cvar handles
ConVar g_hCvarAllow, g_hCvarChase, g_hCvarConvert1, g_hCvarConvert2, g_hCvarConvert3, g_hCvarDelayMax, g_hCvarDelayMin, g_hCvarDelayRan, g_hCvarGas, g_hCvarInitMax, g_hCvarInitMin, g_hCvarMPGameMode, g_hCvarMaxTime, g_hCvarMinTime, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarOxy, g_hCvarPro, g_hCvarType;
int g_iCvarChase, g_iCvarConvert1, g_iCvarConvert2, g_iCvarConvert3, g_iCvarDelayMax, g_iCvarDelayMin, g_iCvarDelayRan, g_iCvarGas, g_iCvarInitMax, g_iCvarInitMin, g_iCvarOxy, g_iCvarPro, g_iCvarType;
bool g_bCvarAllow, g_bMapStarted;
float g_fCvarMaxTime, g_fCvarMinTime;

// Globals
int g_iParticleCount, g_iPlayerSpawn, g_iRoundStart;
float g_fLastPlayed;

// Firework types
enum
{
	TYPE_RED	= (1 << 0),
	TYPE_BLUE	= (1 << 1),
	TYPE_GOLD	= (1 << 2),
	TYPE_FLASH	= (1 << 3),
}

static const char g_sParticles[4][16] =
{
	"fireworks_01",
	"fireworks_02",
	"fireworks_03",
	"fireworks_04"
};

static const char g_sSoundsLaunch[6][45] =
{
	"ambient/atmosphere/firewerks_launch_01.wav",
	"ambient/atmosphere/firewerks_launch_02.wav",
	"ambient/atmosphere/firewerks_launch_03.wav",
	"ambient/atmosphere/firewerks_launch_04.wav",
	"ambient/atmosphere/firewerks_launch_05.wav",
	"ambient/atmosphere/firewerks_launch_06.wav"
};

static const char g_sSoundsBursts[4][45] =
{
	"ambient/atmosphere/firewerks_burst_01.wav",
	"ambient/atmosphere/firewerks_burst_02.wav",
	"ambient/atmosphere/firewerks_burst_03.wav",
	"ambient/atmosphere/firewerks_burst_04.wav"
};



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Fireworks Party",
	author = "SilverShot",
	description = "Adds fireworks to the firework crate explosions.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=153783"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d2_fireworks_allow",				"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarGas =		CreateConVar(	"l4d2_fireworks_allow_gas",			"0",			"Allow gascan explosions to display fireworks (only works on cans which have not been picked up).", CVAR_FLAGS);
	g_hCvarOxy =		CreateConVar(	"l4d2_fireworks_allow_oxygen",		"0",			"Allow oxygen tank explosions to display fireworks.", CVAR_FLAGS);
	g_hCvarPro =		CreateConVar(	"l4d2_fireworks_allow_propane",		"0",			"Allow propane tank explosions to display fireworks.", CVAR_FLAGS);
	g_hCvarChase =		CreateConVar(	"l4d2_fireworks_chase",				"10",			"0=Off. How long zombies are attracted to firework explosions.", CVAR_FLAGS, true, 0.0, true, 20.0);
	g_hCvarConvert1 =	CreateConVar(	"l4d2_fireworks_convert_gas",		"50",			"Percentage of gascans to convert into firework crates.", CVAR_FLAGS, true, 0.0, true, 100.0);
	g_hCvarConvert2 =	CreateConVar(	"l4d2_fireworks_convert_oxygen",	"50",			"Percentage of oxygen tanks to convert into firework crates.", CVAR_FLAGS, true, 0.0, true, 100.0);
	g_hCvarConvert3 =	CreateConVar(	"l4d2_fireworks_convert_propane",	"50",			"Percentage of propane tanks to convert into firework crates.", CVAR_FLAGS, true, 0.0, true, 100.0);
	g_hCvarDelayMax =	CreateConVar(	"l4d2_fireworks_delay_max",			"10",			"Maximum delayed fireworks to display (0 disables delayed).", CVAR_FLAGS, true, 0.0, true, 20.0);
	g_hCvarDelayMin =	CreateConVar(	"l4d2_fireworks_delay_min",			"3",			"Minimum delayed fireworks to display.", CVAR_FLAGS, true, 0.0, true, 10.0);
	g_hCvarDelayRan =	CreateConVar(	"l4d2_fireworks_delay_ran",			"1",			"Randomise how many delayed fireworks display. 0=Max, 1=Random.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarMaxTime =	CreateConVar(	"l4d2_fireworks_delay_time_max",	"10.0",			"Max time after explosion for delayed fireworks to be created.", CVAR_FLAGS, true, 2.0, true, 20.0);
	g_hCvarMinTime =	CreateConVar(	"l4d2_fireworks_delay_time_min",	"0.2",			"Min time after explosion before delayed fireworks can show.", CVAR_FLAGS, true, 0.1, true, 15.0);
	g_hCvarInitMax =	CreateConVar(	"l4d2_fireworks_init_max",			"3",			"Maximum fireworks to display on initial explosion (0 disables).", CVAR_FLAGS, true, 0.0, true, 10.0);
	g_hCvarInitMin =	CreateConVar(	"l4d2_fireworks_init_min",			"0",			"Minimum fireworks to display on initial explosion.", CVAR_FLAGS, true, 0.0, true, 10.0);
	g_hCvarModes =		CreateConVar(	"l4d2_fireworks_modes",				"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d2_fireworks_modes_off",			"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d2_fireworks_modes_tog",			"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarType =		CreateConVar(	"l4d2_fireworks_type",				"15",			"Which fireworks to display. Bit flags, add up the numbers. 1=Red; 2=Blue; 4=Gold; 8=Flash.", CVAR_FLAGS);
	CreateConVar(						"l4d2_fireworks_version",			PLUGIN_VERSION,	"Fireworks Party plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d2_fireworks_party");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarGas.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarOxy.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPro.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarChase.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarInitMax.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarInitMin.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDelayMax.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDelayMin.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDelayRan.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxTime.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMinTime.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarType.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarConvert1.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarConvert2.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarConvert3.AddChangeHook(ConVarChanged_Cvars);

	RegAdminCmd("sm_fireworks", CmdFireworks, ADMFLAG_ROOT);
	RegAdminCmd("sm_fw", CmdFireworks, ADMFLAG_ROOT);
}

public void OnMapStart()
{
	g_bMapStarted = true;

	int i;
	for( i = 0; i <= 3; i++ ) PrecacheParticle(g_sParticles[i]);
	for( i = 0; i <= 3; i++ ) PrecacheSound(g_sSoundsBursts[i], true);
	for( i = 0; i <= 5; i++ ) PrecacheSound(g_sSoundsLaunch[i], true);
	PrecacheModel(MODEL_CRATE, true);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarGas = g_hCvarGas.IntValue;
	g_iCvarOxy = g_hCvarOxy.IntValue;
	g_iCvarPro = g_hCvarPro.IntValue;
	g_iCvarChase = g_hCvarChase.IntValue;
	g_iCvarInitMax = g_hCvarInitMax.IntValue;
	g_iCvarInitMin = g_hCvarInitMin.IntValue;
	g_iCvarDelayMax = g_hCvarDelayMax.IntValue;
	g_iCvarDelayMin = g_hCvarDelayMin.IntValue;
	g_iCvarDelayRan = g_hCvarDelayRan.IntValue;
	g_fCvarMaxTime = g_hCvarMaxTime.FloatValue;
	g_fCvarMinTime = g_hCvarMinTime.FloatValue;
	g_iCvarType = g_hCvarType.IntValue;
	g_iCvarConvert1 = g_hCvarConvert1.IntValue;
	g_iCvarConvert2 = g_hCvarConvert2.IntValue;
	g_iCvarConvert3 = g_hCvarConvert3.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvents();
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvents();
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					ADMIN COMMANDS
// ====================================================================================================
public Action CmdFireworks(int client, int args)
{
	if( client && IsClientInGame(client) )
	{
		float vPos[3];
		if( SetTeleportEndPoint(client, vPos) )
			MakeFireworks(vPos);
	}
	return Plugin_Handled;
}

bool SetTeleportEndPoint(int client, float vPos[3])
{
	float vAng[3], vBuffer[3], vStart[3];

	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vPos, vStart, false);
		GetAngleVectors(vAng, vBuffer, NULL_VECTOR, NULL_VECTOR);
		vPos[0] = vStart[0] + (vBuffer[0] * 35.0);
		vPos[1] = vStart[1] + (vBuffer[1] * 35.0);
		vPos[2] = vStart[2] + (vBuffer[2] * 35.0);
	}
	else
	{
		delete trace;
		return false;
	}

	delete trace;
	return true;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients && !entity;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void HookEvents()
{
	HookEvent("break_prop",			Event_BreakProp,		EventHookMode_Pre);
	HookEvent("player_spawn",		Event_PlayerSpawn,		EventHookMode_PostNoCopy);
	HookEvent("round_start",		Event_RoundStart,		EventHookMode_PostNoCopy);
	HookEvent("round_end",			Event_RoundEnd,			EventHookMode_PostNoCopy);
}

void UnhookEvents()
{
	UnhookEvent("break_prop",		Event_BreakProp,		EventHookMode_Pre);
	UnhookEvent("player_spawn",		Event_PlayerSpawn,		EventHookMode_PostNoCopy);
	UnhookEvent("round_start",		Event_RoundStart,		EventHookMode_PostNoCopy);
	UnhookEvent("round_end",		Event_RoundEnd,			EventHookMode_PostNoCopy);
}

public void Event_BreakProp(Event event, const char[] name, bool dontBroadcast)
{
	char sTemp[42];
	float vPos[3];
	int entity = event.GetInt("entindex");
	GetEdictClassname(entity, sTemp, sizeof(sTemp));

	if( strcmp(sTemp, "prop_physics") == 0 )
	{
		GetEntPropString(entity, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));

		if( strcmp(sTemp, MODEL_CRATE) == 0 ||
			(g_iCvarGas && strcmp(sTemp, MODEL_GASCAN) == 0 ) ||
			(g_iCvarOxy && strcmp(sTemp, MODEL_OXYGEN) == 0 ) ||
			(g_iCvarPro && strcmp(sTemp, MODEL_PROPANE) == 0 )
		)
		{
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
			MakeFireworks(vPos);

			if( g_iCvarChase )
			{
				entity = CreateEntityByName("info_goal_infected_chase");
				if( entity != -1 )
				{
					DispatchSpawn(entity);
					vPos[2] += 2.0;
					TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
					Format(sTemp, sizeof(sTemp), "OnUser1 !self:kill::%d:1", g_iCvarChase);
					SetVariantString(sTemp);
					AcceptEntityInput(entity, "AddOutput");
					AcceptEntityInput(entity, "FireUser1");
					AcceptEntityInput(entity, "Enable");
				}
			}
		}
	}
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	g_iParticleCount = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_iParticleCount = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
	{
		CreateTimer(8.0, TimerConvert);
	}

	if( g_iPlayerSpawn == 0 )
	{
		g_iPlayerSpawn = 1;
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
	{
		CreateTimer(8.0, TimerConvert);
	}

	if( g_iRoundStart == 0 )
	{
		g_iRoundStart = 1;
	}
}

public Action TimerConvert(Handle timer)
{
	ConvertToCrates();
	return Plugin_Continue;
}

void ConvertToCrates()
{
	int iReplace1 = g_iCvarConvert1;
	int iReplace2 = g_iCvarConvert2;
	int iReplace3 = g_iCvarConvert3;

	if( iReplace1 + iReplace2 + iReplace3 == 0 )
		return;

	char sTemp[64];
	int entity, iCount1, iCount2, iCount3, iDone, iResult;


	// ======================================================================================
	// Do not replace gascans if 'gas_nozzle' is found
	// ======================================================================================
	if( iReplace1 )
	{
		entity = -1;
		while( (entity = FindEntityByClassname(entity, "point_prop_use_target")) != INVALID_ENT_REFERENCE )
		{
			GetEntPropString(entity, Prop_Data, "m_sGasNozzleName", sTemp, sizeof(sTemp));
			if( strcmp(sTemp, "gas_nozzle") == 0 )
			{
				iReplace1 = 0;
				break;
			}
		}
	}


	// ======================================================================================
	// Find 'prop_physics', gascan/oxygen/propane - COUNT
	// ======================================================================================
	entity = -1;

	while( (entity = FindEntityByClassname(entity, "prop_physics")) != INVALID_ENT_REFERENCE )
	{
		GetEntPropString(entity, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));
		if( iReplace1 && strcmp(sTemp, MODEL_GASCAN) == 0 )
			iCount1++;
		else if( iReplace2 && strcmp(sTemp, MODEL_OXYGEN) == 0 )
			iCount2++;
		else if( iReplace3 && strcmp(sTemp, MODEL_PROPANE) == 0 )
			iCount3++;
	}


	// Percentage to replace
	if( iReplace1 && iCount1 )
		iResult = (iReplace1 * iCount1) / 100;
	if( iReplace2 )
		iResult += (iReplace2 * iCount2) / 100;
	if( iReplace3 )
		iResult += (iReplace3 * iCount3) / 100;


	// ======================================================================================
	// Find 'prop_physics', gascan/oxygen/propane - REPLACE
	// ======================================================================================
	iReplace1 = 0;
	iReplace2 = 0;
	iReplace3 = 0;
	entity = -1;

	while( (entity = FindEntityByClassname(entity, "prop_physics")) != INVALID_ENT_REFERENCE )
	{
		if( iDone < iResult )
		{
			GetEntPropString(entity, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));

			if( iReplace1 < iCount1 && strcmp(sTemp, MODEL_GASCAN) == 0 )
			{
				iReplace1++;
				iDone++;
				ReplaceCan(entity);
			}
			else if( iReplace2 < iCount2 && strcmp(sTemp, MODEL_OXYGEN) == 0 )
			{
				iReplace2++;
				iDone++;
				ReplaceCan(entity);
			}
			else if( iReplace3 < iCount3 && strcmp(sTemp, MODEL_PROPANE) == 0 )
			{
				iReplace3++;
				iDone++;
				ReplaceCan(entity);
			}
		}
		else
			break;
	}
}

int ReplaceCan(int entity)
{
	float vPos[3], vAng[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAng);
	AcceptEntityInput(entity, "kill");

	vAng[0] += 90;
	vPos[2] += 5.0;

	entity = CreateEntityByName("physics_prop");
	if( entity != -1 )
	{
		SetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
		SetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAng);
		SetEntityModel(entity, MODEL_CRATE);
		DispatchSpawn(entity);
	}
	return entity;
}



// ====================================================================================================
//					FIREWORKS
// ====================================================================================================
void MakeFireworks(const float vOrigin[3])
{
	int iAmount;
	float vPos[3];
	vPos = vOrigin;

	// Display fireworks on initial explosion?
	if( g_iCvarInitMax )
	{
		iAmount = GetRandomInt(g_iCvarInitMin, g_iCvarInitMax);

		if( iAmount > 0 )
		{
			int iFirework;
			float fHeight, vAng[3];

			for( int i = 0; i < iAmount; i++ )
			{
				fHeight = GetRandomFloat(300.0, 1400.0);
				vPos[2] -= fHeight;
				vAng[0] = GetRandomFloat(-10.0, 10.0);
				vAng[1] = GetRandomFloat(-10.0, 10.0);
				vAng[2] = GetRandomFloat(-10.0, 10.0);

				// Show fireworks and play sound
				iFirework = GetRandomFirework();
				ShowParticle(vPos, vAng, g_sParticles[iFirework]);
				PlaySound(vPos);

				// Reset origin
				vPos[2] += fHeight;
			}
		}
	}

	// Display random delayed fireworks?
	iAmount = g_iCvarDelayMax;
	if( iAmount )
	{
		// Random amount of fireworks? Or fixed amount?
		if( g_iCvarDelayRan )
			iAmount = GetRandomInt(g_iCvarDelayMin, iAmount);

		if( iAmount > 0 )
		{
			float fTime;
			DataPack hPack;
			for( int i = 0; i < iAmount; i++ )
			{
				// Create timers to make delayed fireworks
				fTime = GetRandomFloat( g_fCvarMinTime, g_fCvarMaxTime );
				hPack = null;
				CreateDataTimer(fTime, TimerRandomFirework, hPack);
				hPack.WriteFloat(vPos[0]);
				hPack.WriteFloat(vPos[1]);
				hPack.WriteFloat(vPos[2]);
			}
		}
	}
}

public Action TimerRandomFirework(Handle timer, DataPack hPack)
{
	float vPos[3], vAng[3];

	hPack.Reset();
	vPos[0] = hPack.ReadFloat();
	vPos[1] = hPack.ReadFloat();
	vPos[2] = hPack.ReadFloat();

	int i = GetRandomFirework();
	vPos[2] -= GetRandomFloat(300.0, 1400.0);

	vAng[0] = GetRandomFloat(-10.0, 10.0);
	vAng[1] = GetRandomFloat(-10.0, 10.0);
	vAng[2] = GetRandomFloat(-10.0, 10.0);
	ShowParticle(vPos, vAng, g_sParticles[i]);

	PlaySound(vPos); // Play whistle now and explosion sound in 2 seconds.
	return Plugin_Continue;
}

// Get a random firework type from the cvars enum and display
int GetRandomFirework()
{
	int iCount, iArray[4], iType = g_iCvarType;

	if( iType & TYPE_RED )
	{
		iArray[iCount] = 0;
		iCount++;
	}
	if( iType & TYPE_BLUE )
	{
		iArray[iCount] = 1;
		iCount++;
	}
	if( iType & TYPE_GOLD )
	{
		iArray[iCount] = 2;
		iCount++;
	}
	if( iType & TYPE_FLASH )
	{
		iArray[iCount] = 3;
		iCount++;
	}

	iType = GetRandomInt(0, iCount -1);
	return iArray[iType];
}



// ====================================================================================================
//					PARTICLES
// ====================================================================================================
void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

void ShowParticle(float vPos[3], float vAng[3], char[] sParticle)
{
	if( g_iParticleCount >= MAX_PARTICLES )
		return;

	int entity = CreateEntityByName("info_particle_system");
	if( entity != -1 )
	{
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		DispatchKeyValue(entity, "effect_name", sParticle);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");
		SetVariantString("OnUser1 !self:Kill::5.0.0:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
		g_iParticleCount++;
	}
}



// ====================================================================================================
//					SOUNDS
// ====================================================================================================
void PlaySound(float vPos[3])
{
	// Limit sounds so they are not played more than once during 0.3 seconds.
	float fTime = GetGameTime();
	if( (fTime - g_fLastPlayed) <= 0.3 )
		return;
	g_fLastPlayed = fTime;

	int iChance = 3;

	// Whistle sound
	if( GetRandomInt(1, 5) <= iChance )	// 3/5 chance to play sound
		PlayAmbient(g_sSoundsLaunch[GetRandomInt(0, 5)], vPos);

	// Explosion sound (in 2 seconds when the particle explodes)
	if( GetRandomInt(1, 5) <= iChance )	// 3/5 chance to play fireworks explosion sound
	{
		DataPack hPack;
		CreateDataTimer(2.0, TimerPlayBurst, hPack);
		hPack.WriteFloat(vPos[0]);
		hPack.WriteFloat(vPos[1]);
		hPack.WriteFloat(vPos[2]);
	}
}

public Action TimerPlayBurst(Handle timer, DataPack hPack)
{
	float vPos[3];

	hPack.Reset();
	vPos[0] = hPack.ReadFloat();
	vPos[1] = hPack.ReadFloat();
	vPos[2] = hPack.ReadFloat() + 400.0;

	PlayAmbient(g_sSoundsBursts[GetRandomInt(0, 3)], vPos);
	return Plugin_Continue;
}

void PlayAmbient(char[] sName, float vPos[3])
{
	vPos[2] += 200.0;
	EmitAmbientSound(sName, vPos, SOUND_FROM_WORLD, SNDLEVEL_HELICOPTER, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
}