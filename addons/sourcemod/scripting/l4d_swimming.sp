/*
*	Swimming
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



#define PLUGIN_VERSION 		"1.9"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Swimming
*	Author	:	SilverShot
*	Descrp	:	Lets players Swim and Dive in water.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=187565
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.9 (11-Dec-2022)
	- Changes to fix compile warnings on SourceMod 1.11.

1.8 (30-Sep-2020)
	- Fixed compile errors on SM 1.11.

1.7 (18-Sep-2020)
	- Added cvar "l4d_swim_incap" to control if being incapacitated in the water drowns the player.
	- Fixed rare "OnPlayerRunCmd" throwing client "not connected" or "not in game" errors.

1.6 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.

1.5 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.4 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed cvar "l4d_swim_modes_tog" now supports L4D1.

1.3 (10-Jul-2012)
	- Fixed hook event errors in L4D1. Thanks to "Herbie_06" for reporting.

1.2 (23-Jun-2012)
	- Removed "player_ledge_grab" event hook, prevents drowning after using ledge release.

1.1 (20-Jun-2012)
	- Playes who heal under water receive full oxygen, but does not affect main health.

1.0 (15-Jun-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <readyup>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Swimming] \x01"


ConVar g_hCvarAllow, g_hCvarDecayRate, g_hCvarDive, g_hCvarDrown, g_hCvarIncap, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRate, g_hCvarSpeedDown, g_hCvarSpeedIdle, g_hCvarSpeedJmp, g_hCvarSpeedUp;
int g_iCvarDive, g_iCvarDrown, g_iCvarIncap, g_iHealth[MAXPLAYERS+1], g_iPlayerEnum[MAXPLAYERS+1], g_iSwimming[MAXPLAYERS+1], g_iWater[MAXPLAYERS+1];
float g_fCvarDecayRate, g_fCvarRate, g_fCvarSpeedDown, g_fCvarSpeedIdle, g_fCvarSpeedJmp, g_fCvarSpeedUp, g_fHealth[MAXPLAYERS+1];
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2;

enum
{
	BLOCKED = 1,
	POUNCED = 2
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Swimming",
	author = "SilverShot",
	description = "Lets players Swim and Dive in water.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=187565"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d_swim_allow",		"0",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_swim_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_swim_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_swim_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarDive =		CreateConVar(	"l4d_swim_dive",		"0",			"0=Only bobbin on the surface, 1=Allows players to dive.", CVAR_FLAGS);
	g_hCvarDrown =		CreateConVar(	"l4d_swim_drown",		"1",			"0=Stay on surface when caught by infected, 1=Sink when caught.", CVAR_FLAGS);
	g_hCvarIncap =		CreateConVar(	"l4d_swim_incap",		"1",			"0=Allow being incapacitated when swimming (they float). 1=Stops the player swimming letting them drown.", CVAR_FLAGS);
	g_hCvarRate =		CreateConVar(	"l4d_swim_rate",		"0.0",			"0.0=Off. How much air is lost per second when diving. Players die when they have 0 air.", CVAR_FLAGS);
	g_hCvarSpeedDown =	CreateConVar(	"l4d_swim_speed_down",	"-30.0",		"How fast to teleport downwards when they hold DUCK.", CVAR_FLAGS);
	g_hCvarSpeedIdle =	CreateConVar(	"l4d_swim_speed_idle",	"15.0",			"How fast to teleport players when they are not pressing any keys.", CVAR_FLAGS);
	g_hCvarSpeedJmp =	CreateConVar(	"l4d_swim_speed_jump",	"400.0",		"How fast to teleport players when jumping out of the water.", CVAR_FLAGS);
	g_hCvarSpeedUp =	CreateConVar(	"l4d_swim_speed_up",	"30.0",			"How fast to teleport players who are pressing the SPRINT/WALK key.", CVAR_FLAGS);
	CreateConVar(						"l4d_swim_version",		PLUGIN_VERSION, "Swimming plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	//AutoExecConfig(true,				"l4d_swim");

	g_hCvarDecayRate = FindConVar("pain_pills_decay_rate");
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarDive.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDrown.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarIncap.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRate.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpeedDown.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpeedIdle.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpeedJmp.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpeedUp.AddChangeHook(ConVarChanged_Cvars);
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
}

void ResetPlugin()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_iPlayerEnum[i] = 0;
		g_iSwimming[i] = 0;
		g_iWater[i] = 0;
		g_iHealth[i] = 0;
		g_fHealth[i] = 0.0;
	}
}


public void OnRoundIsLivePre(){
	ResetPlugin();
	g_hCvarAllow.IntValue = 0;
}

public void OnReadyUpInitiate(){
	g_hCvarAllow.IntValue = 1;
}

// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarDive = g_hCvarDive.IntValue;
	g_iCvarIncap = g_hCvarIncap.IntValue;
	g_iCvarDrown = g_hCvarDrown.IntValue;
	g_fCvarRate = g_hCvarRate.FloatValue;
	g_fCvarDecayRate = g_hCvarDecayRate.FloatValue;
	g_fCvarSpeedDown = g_hCvarSpeedDown.FloatValue;
	g_fCvarSpeedIdle = g_hCvarSpeedIdle.FloatValue;
	g_fCvarSpeedJmp = g_hCvarSpeedJmp.FloatValue;
	g_fCvarSpeedUp = g_hCvarSpeedUp.FloatValue;
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
		ResetPlugin();
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

void OnGamemode(const char[] output, int caller, int activator, float delay)
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
void HookEvents()
{
	HookEvent("round_start",			Event_RoundStart);
	HookEvent("heal_success",			Event_HealSuccess);
	HookEvent("revive_success",			Event_ReviveSuccess);
	HookEvent("player_death",			Event_Unblock);
	HookEvent("player_spawn",			Event_Unblock);
	HookEvent("lunge_pounce",			Event_BlockHunter);
	HookEvent("pounce_end",				Event_BlockEndHunt);
	HookEvent("tongue_grab",			Event_BlockStart);
	HookEvent("tongue_release",			Event_BlockEnd);

	if( g_bLeft4Dead2 == true )
	{
		HookEvent("charger_pummel_start",	Event_BlockStart);
		HookEvent("charger_carry_start",	Event_BlockStart);
		HookEvent("charger_carry_end",		Event_BlockEnd);
		HookEvent("charger_pummel_end",		Event_BlockEnd);
	}
}

void UnhookEvents()
{
	UnhookEvent("round_start",				Event_RoundStart);
	UnhookEvent("heal_success",				Event_HealSuccess);
	UnhookEvent("revive_success",			Event_ReviveSuccess);
	UnhookEvent("player_death",				Event_Unblock);
	UnhookEvent("player_spawn",				Event_Unblock);
	UnhookEvent("lunge_pounce",				Event_BlockHunter);
	UnhookEvent("pounce_end",				Event_BlockEndHunt);
	UnhookEvent("tongue_grab",				Event_BlockStart);
	UnhookEvent("tongue_release",			Event_BlockEnd);

	if( g_bLeft4Dead2 == true )
	{
		UnhookEvent("charger_pummel_start",		Event_BlockStart);
		UnhookEvent("charger_carry_start",		Event_BlockStart);
		UnhookEvent("charger_carry_end",		Event_BlockEnd);
		UnhookEvent("charger_pummel_end",		Event_BlockEnd);
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

void Event_BlockStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if( client > 0 )
		g_iPlayerEnum[client] |= BLOCKED;
}

void Event_BlockEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if( client > 0 )
		g_iPlayerEnum[client] &= ~BLOCKED;
}

void Event_BlockHunter(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if( client > 0 )
		g_iPlayerEnum[client] |= POUNCED;

	client = GetClientOfUserId(event.GetInt("userid"));
	if( client > 0 )
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

void Event_BlockEndHunt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if( client > 0 )
		g_iPlayerEnum[client] &= ~POUNCED;

	client = GetClientOfUserId(event.GetInt("userid"));
	if( client > 0 )
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client > 0 && g_iSwimming[client] == 1 )
	{
		SetEntityHealth(client, 1);
		SetTempHealth(client, 100.0);
	}
}

void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if( client > 0 )
		g_iPlayerEnum[client] = 0;
}

void Event_Unblock(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client > 0)
		g_iPlayerEnum[client] = 0;

	if( g_iSwimming[client] )
	{
		g_iSwimming[client] = 0;
		g_iHealth[client] = 0;
		g_fHealth[client] = 0.0;
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if( g_bCvarAllow && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
	{
		int swimming = g_iSwimming[client];
		int water = GetEntProp(client, Prop_Send, "m_nWaterLevel");
		g_iWater[client] = water;

		if( water >= 1 && (!g_iCvarIncap || GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 0) )
		{
			if( water == 1 )
			{
				if( swimming == 1 && g_fCvarRate && g_iHealth[client] != 0 )
				{
					SetEntityHealth(client, g_iHealth[client]);
					SetTempHealth(client, g_fHealth[client]);
					g_iHealth[client] = 0;
					g_fHealth[client] = 0.0;
				}
			}
			else
			{
				if( swimming == 0 )
				{
					g_iSwimming[client] = 1;

					SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
				}

				float vVel[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);

				if( (g_iCvarDive && buttons & IN_DUCK) || (g_iCvarDrown && g_iPlayerEnum[client]) )
				{
					vVel[2] = g_fCvarSpeedDown;
				}
				else if( buttons & IN_JUMP )
				{
					if( water == 2 )
					{
						AcceptEntityInput(client, "DisableLedgeHang");
						vVel[2] = g_fCvarSpeedJmp;
					}
					else
					{
						vVel[2] = g_fCvarSpeedUp;
					}
				}
				else
				{
					vVel[2] = g_fCvarSpeedIdle;
				}

				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);

				if( g_fCvarRate && water > 2 )
				{
					if( g_iHealth[client] == 0 )
					{
						g_iHealth[client] = GetClientHealth(client);
						g_fHealth[client] = GetTempHealth(client);

						SetEntityHealth(client, 1);
						SetTempHealth(client, 100.0);
					}

					float fHealth = GetTempHealth(client) - g_fCvarRate;
					if( fHealth <= 0 )
					{
						ForcePlayerSuicide(client);
					}
					else
					{
						SetTempHealth(client, fHealth);
					}
				}
			}
		}
		else if( swimming == 1 )
		{
			if( water == 0 )
			{
				g_iSwimming[client] = 0;

				SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
				AcceptEntityInput(client, "EnableLedgeHang");
			}
		}
	}

	return Plugin_Continue;
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( damagetype == DMG_DROWN )
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	else if( damagetype == DMG_FALL && damage == 5000.0 )
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

float GetTempHealth(int client)
{
	float fGameTime = GetGameTime();
	float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");

	fHealth -= (fGameTime - fHealthTime) * g_fCvarDecayRate;
	if( fHealth < 0.0 )
		fHealth = 0.0;

	return fHealth;
}

void SetTempHealth(int client, float fHealth)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}