/*
*	First Map - Skip Intro Cutscenes
*	Copyright (C) 2022 Silvers
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



#define PLUGIN_VERSION		"1.13"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] First Map - Skip Intro Cutscenes
*	Author	:	SilverShot
*	Descrp	:	Makes players skip seeing the intro cutscene on first maps, so they can move right away.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=321993
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.13 (10-Apr-2022)
	- Fixed the "l4d_skip_intro_modes_tog" cvar always turning off the plugin. Thanks to "Thefollors" for reporting.

1.12 (01-Dec-2021)
	- Changes to fix warnings when compiling on SourceMod 1.11.
	- Minor change to fix bad coding practice.

1.11 (11-Jul-2021)
	- Slight optimization and change to fix the unhook event errors.

1.10 (21-Jun-2021)
	- Changes to fix the last update potentially not working for all maps.

1.9 (20-Jun-2021)
	- Changed some code to prevent adding multiple identical outputs.

1.8 (15-Feb-2021)
	- Blocked working on finale maps when not using left4dhooks. Thanks to "Zheldorg" for reporting.

1.7 (10-Oct-2020)
	- Minor change again to hopefully fix unhook event errors.

1.6 (05-Oct-2020)
	- Changes to hopefully fix unhook event errors.

1.5 (01-Oct-2020)
	- Changes to support "The Last Stand" update.
	- Fixed lateload not enabling the plugin.

1.4 (10-May-2020)
	- Added cvars: "l4d_skip_intro_allow", "l4d_skip_intro_modes", "l4d_skip_intro_modes_off" and "l4d_skip_intro_modes_tog".
	- Cvar config saved as "l4d_skip_intro.cfg" in "cfgs/sourcemod" folder.
	- Extra checks to skip intro on some addon maps that use a different entity.
	- Thanks to "TiTz" for reporting.

1.3 (29-Apr-2020)
	- Increased the timer delay from 0.1 to 1.0 due to some conditions failing to skip intro. Thanks to "TiTz" for reporting.

1.2 (08-Apr-2020)
	- Added a check incase the director entity was not found. Thanks to "TiTz" for reporting.

1.1 (16-Mar-2020)
	- Fixed not working on all maps when info_director is named differently.

1.0 (10-Mar-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
bool g_bCvarAllow, g_bMapStarted, g_bLeft4DHooks, g_bFaded, g_bOutput1, g_bOutput2;



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
native bool L4D_IsFirstMapInScenario(); // So it compiles on forum, optional native.

public Plugin myinfo =
{
	name = "[L4D & L4D2] First Map - Skip Intro Cutscenes",
	author = "SilverShot",
	description = "Makes players skip seeing the intro cutscene on first maps, so they can move right away.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=321993"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	MarkNativeAsOptional("L4D_IsFirstMapInScenario");

	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	g_bLeft4DHooks = GetFeatureStatus(FeatureType_Native, "L4D_IsFirstMapInScenario") == FeatureStatus_Available;
}

public void OnPluginStart()
{
	g_hCvarAllow = CreateConVar(	"l4d_skip_intro_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(	"l4d_skip_intro_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(	"l4d_skip_intro_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(	"l4d_skip_intro_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	CreateConVar(					"l4d_skip_intro_version",		PLUGIN_VERSION,	"Skip Intro plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d_skip_intro");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);

	HookEvent("gameinstructor_nodraw", Event_NoDraw, EventHookMode_PostNoCopy); // Because round_start can be too early when clients are not in-game. This triggers when the cutscene starts.
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
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
//					EVENTS
// ====================================================================================================
public void Event_NoDraw(Event event, const char[] name, bool dontBroadcast)
{
	if( g_bCvarAllow && (!g_bLeft4DHooks || L4D_IsFirstMapInScenario()) )
	{
		// Block finale
		if( !g_bLeft4DHooks && FindEntityByClassname(-1, "trigger_finale") != INVALID_ENT_REFERENCE )
			return;

		g_bFaded = false;
		g_bOutput1 = false;
		g_bOutput2 = false;

		// Multiple times to make sure it works
		CreateTimer(1.0, TimerStart);
		CreateTimer(5.0, TimerStart);
		CreateTimer(6.0, TimerStart);
		CreateTimer(6.5, TimerStart);
		CreateTimer(7.0, TimerStart);
		CreateTimer(8.0, TimerStart);
	}
}

public Action TimerStart(Handle timer)
{
	char buffer[128]; // 128 should be long enough, 3rd party maps could be longer than Valves ~52 chars (including OnUser1 below)?

	char director[32];
	int entity = FindEntityByClassname(-1, "info_director"); // Every map should have a director, but apparently some still throw -1 error.
	if( entity != -1 )
	{
		GetEntPropString(entity, Prop_Data, "m_iName", director, sizeof(director));

		for( int i = 0; i < 2; i++ )
		{
			entity = -1;
			while( (entity = FindEntityByClassname(entity, i == 0 ? "point_viewcontrol_survivor" : "point_viewcontrol_multiplayer")) != INVALID_ENT_REFERENCE )
			{
				// ALLOW CONTROL
				if( (i == 0 && !g_bOutput1) || (i == 1 && !g_bOutput2) )
				{
					// Testing outputs
					// static int tester;
					// FormatEx(buffer, sizeof(buffer), "OnUser1 silvers_point_cmd:Command:say test%d:0:-1", tester++);
					// SetVariantString(buffer);
					// AcceptEntityInput(entity, "AddOutput");

					// ALLOW MOVEMENT
					FormatEx(buffer, sizeof(buffer), "OnUser1 %s:ReleaseSurvivorPositions::0:-1", director);
					SetVariantString(buffer);
					AcceptEntityInput(entity, "AddOutput");

					FormatEx(buffer, sizeof(buffer), "OnUser1 %s:FinishIntro::0:-1", director);
					SetVariantString(buffer);
					AcceptEntityInput(entity, "AddOutput");

					AcceptEntityInput(entity, "FireUser1");

					if( i == 0 )			g_bOutput1 = true;
					else if( i == 1 )		g_bOutput2 = true;
				} else {
					AcceptEntityInput(entity, "FireUser1");
				}

				// STOP SCENE
				SetVariantString("!self");
				AcceptEntityInput(entity, "StartMovement");

				// RemoveEntity(entity); // Kill works good, but maybe some 3rd party maps use this for other scenes, so better to not kill.. especially if no left4dhooks and checking every map.
			}
		}

		// FADE IN
		if( (g_bOutput1 || g_bOutput2 ) && !g_bFaded )
		{
			g_bFaded = true;

			entity = CreateEntityByName("env_fade");
			DispatchKeyValue(entity, "spawnflags", "1");
			DispatchKeyValue(entity, "rendercolor", "0 0 0");
			DispatchKeyValue(entity, "renderamt", "255");
			DispatchKeyValue(entity, "holdtime", "1");
			DispatchKeyValue(entity, "duration", "1");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "Fade");

			SetVariantString("OnUser1 !self:Kill::2.5:-1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");

			// Testing outputs
			// entity = CreateEntityByName("point_servercommand");
			// DispatchKeyValue(entity, "targetname", "silvers_point_cmd");
			// DispatchSpawn(entity);
		}
	}

	return Plugin_Continue;
}