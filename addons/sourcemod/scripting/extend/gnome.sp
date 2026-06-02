/*
*	Healing Gnome
*	Copyright (C) 2021 Silvers
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



#define PLUGIN_VERSION 		"1.16"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Healing Gnome
*	Author	:	SilverShot
*	Descrp	:	Heals players with temporary or main health when they hold the Gnome.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=179267
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.16 (15-Sep-2021)
	- Added cvar "l4d2_gnome_healing_field_self" to determine if the Healing Field can heal yourself or not.
	- Changed cvar "l4d2_gnome_temp" to be a chance of giving temporary health.
	- Fixed Healing Field not healing players with the cvar specified amount. Thanks to "Maur0" for the reporting.

1.15 (12-Sep-2021)
	- Re-wrote the heal client logic. Fixing various issues when reaching limits.
	- Now has two defines in the source code to set maximum health. MAX_INCAP_HEALTH for incap temp health. MAX_MAIN_HEALTH inclues main and temp health.

1.14 (30-Aug-2021)
	- Fixed losing temporary health when the limit was reached. Thanks to "Shao" for reporting.

1.13 (31-Jul-2021)
	- Added cvars "l4d2_gnome_max_main" and "l4d2_gnome_max_temp" to control the maximum main and temporary health allowed to heal to.
	- Fixed cvar "l4d2_gnome_heal" when set to "0" not allowing the healing field feature to work. Again.
	- Now ignores healing the holder with the standard healing when healing field is enabled.

1.12 (01-Jun-2021)
	- Fixed cvar "l4d2_gnome_heal" when set to "0" not allowing the Healing Field feature to work. Thanks to "ddd123" for reporting.

1.11 (02-Apr-2021)
	- Healing Field update - by "Marttt":
	- This enables healing around a person carrying the Gnome. Uses the same healing field effect like the "Medic" grenade from "Prototype Grenades" plugin.

	- Added cvars:
		"l4d2_gnome_healing_field", "l4d2_gnome_healing_field_refresh_time", "l4d2_gnome_healing_field_heal_amount", "l4d2_gnome_healing_field_heal_amount_incap",
		"l4d2_gnome_healing_field_heal_beacon", "l4d2_gnome_healing_field_color", "l4d2_gnome_healing_field_start_radius", "l4d2_gnome_healing_field_end_radius",
		"l4d2_gnome_healing_field_duration", "l4d2_gnome_healing_field_width", "l4d2_gnome_healing_field_amplitude".

	- See threads main post for details on the cvars.

1.10 (31-Mar-2021)
	- Changed cvar "l4d2_gnome_full" to give full health and remove the black and white effect, either on temporary or main health.

1.9 (29-Mar-2021)
	- Added cvar "l4d2_gnome_full" to give full health and remove the black and white effect. Requested by "weffer" and "Tonblader".

1.8 (14-Aug-2020)
	- Fixed heal timer duplicating. Thanks to "Electr000999" for reporting.

1.7 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.
	- Various optimizations and fixes.

1.6 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.5 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.4 (21-Jul-2013)
	- Removed Sort_Random work-around. This was fixed in SourceMod 1.4.7, all should update or spawning issues will occur.

1.3 (01-Jul-2012)
	- Added cvars "l4d2_gnome_glow" and "l4d2_gnome_glow_color" to make the gnome glow.
	- Fixed healing players above 100 HP.

1.2 (10-May-2012)
	- Added cvar "l4d2_gnome_modes_off" to control which game modes the plugin works in.
	- Added cvar "l4d2_gnome_modes_tog" same as above.
	- Renamed command "sm_gnomewipe" to "sm_gnomekill", due to command name conflict.
	- Changed cvar "l4d2_gnome_safe", 1=Spawn in saferoom, 2=Equip to random player.

1.1 (01-Mar-2012)
	- Added command sm_gnomeglow to display the gnome positions.
	- Added command sm_gnometele to teleport to gnome positions.

1.0 (28-Feb-2012)
	- Initial release.

========================================================================================
	Thanks:

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	"Zuko & McFlurry" for "[L4D2] Weapon/Zombie Spawner" - Modified SetTeleportEndPoint function.
	https://forums.alliedmods.net/showthread.php?t=109659

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Gnome\x04] \x01"
#define CONFIG_SPAWNS		"data/l4d2_gnome.cfg"

#define MAX_GNOMES			32
#define MAX_MAIN_HEALTH		100 // Maximum health someone can have (main + temporary health)
#define MAX_INCAP_HEALTH	300 // Maximum health someone can have while incapped (main + temporary health)

#define MODEL_GNOME			"models/props_junk/gnome.mdl"


Handle g_hTimerHeal;
Menu g_hMenuAng, g_hMenuPos;
ConVar g_hCvarAllow, g_hCvarDecayRate, g_hCvarGlow, g_hCvarGlowCol, g_hCvarFull, g_hCvarHeal, g_hCvarMaxM, g_hCvarMaxT, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRandom, g_hCvarRate, g_hCvarSafe, g_hCvarTemp; // g_hCvarMaxHealth
int g_iGnomeCount, g_iGnome[MAXPLAYERS+1], g_iGnomes[MAX_GNOMES][2], g_iCvarGlow, g_iCvarGlowCol, g_iCvarFull, g_iCvarHeal, g_iCvarMaxM, g_iCvarRandom, g_iCvarSafe, g_iCvarTemp, g_iMap, g_iPlayerSpawn, g_iRoundStart; // g_iCvarMaxHealth
bool g_bCvarAllow, g_bMapStarted, g_bLoaded;
float g_fCvarMaxT, g_fCvarDecayRate, g_fCvarRate, g_fHealTime[MAXPLAYERS+1];


// Healing Field stuff:
#define SPRITE_BEAM			"materials/sprites/laserbeam.vmt"
#define SPRITE_HALO			"materials/sprites/glow01.vmt"
#define DIST_TOLERANCE		25.0

Handle g_hTimerHealingField;
ConVar g_hCvarIncapHealth, g_hCvarField, g_hCvarFieldRefreshTime, g_hCvarFieldHealAmount, g_hCvarFieldHealAmountIncap, g_hCvarFieldHealSelf, g_hCvarFieldBeacon, g_hCvarFieldColor, g_hCvarFieldStartRadius, g_hCvarFieldEndRadius, g_hCvarFieldDuration, g_hCvarFieldWidth, g_hCvarFieldAmplitude;
int g_iBeamSprite, g_iHaloSprite, g_iCvarIncapHealth, g_iCvarFieldColor[4];
bool g_bCvarField, g_bCvarFieldHealSelf, g_bCvarFieldBeacon, g_bCvarFieldColorRandom;
float g_fCvarFieldRefreshTime, g_fCvarFieldHealAmount, g_fCvarFieldHealAmountIncap, g_fCvarFieldStartRadius, g_fCvarFieldEndRadius, g_fCvarFieldDuration, g_fCvarFieldWidth, g_fCvarFieldAmplitude;
char g_sCvarFieldColor[12];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Healing Gnome",
	author = "SilverShot",
	description = "Heals players with temporary or main health when they hold the Gnome.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=179267"
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
	LoadTranslations("gnome.phrases");
	g_hCvarAllow =		CreateConVar(	"l4d2_gnome_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarGlow =		CreateConVar(	"l4d2_gnome_glow",			"200",			"0=Off. Sets the max range at which the gnome glows.", CVAR_FLAGS );
	g_hCvarGlowCol =	CreateConVar(	"l4d2_gnome_glow_color",	"255 0 0",		"0=Default glow color. Three values between 0-255 separated by spaces. RGB: Red Green Blue.", CVAR_FLAGS );
	g_hCvarFull =		CreateConVar(	"l4d2_gnome_full",			"0",			"0=Off, Remove black and white effect and give full health when regenerated to maximum health with: 1=Temporary health. 2=Main health.", CVAR_FLAGS );
	g_hCvarHeal =		CreateConVar(	"l4d2_gnome_heal",			"1",			"0=Off, 1=Heal players holding the gnome using cvars not from the Healing Field. Does not affect Healing Field.", CVAR_FLAGS );
	g_hCvarMaxM =		CreateConVar(	"l4d2_gnome_max_main",		"100",			"Maximum main health to heal clients to.", CVAR_FLAGS );
	g_hCvarMaxT =		CreateConVar(	"l4d2_gnome_max_temp",		"100.0",		"Maximum temporary health to heal clients to.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d2_gnome_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d2_gnome_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d2_gnome_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRandom =		CreateConVar(	"l4d2_gnome_random",		"0",			"-1=All, 0=None. Otherwise randomly select this many gnomes to spawn from the maps config.", CVAR_FLAGS );
	g_hCvarSafe =		CreateConVar(	"l4d2_gnome_safe",			"0",			"On round start spawn the gnome: 0=Off, 1=In the saferoom, 2=Equip to random player.", CVAR_FLAGS );
	g_hCvarTemp =		CreateConVar(	"l4d2_gnome_temp",			"-1",			"-1=Add temporary health, 0=Add to main health. Values between 1 and 100 creates a chance to give temp health, else main health.", CVAR_FLAGS );
	g_hCvarField =					CreateConVar(	"l4d2_gnome_healing_field",						"0",			"0=Off. 1=Heal players around the player holding the gnome.", CVAR_FLAGS, true, 0.0, true, 1.0 );
	g_hCvarFieldRefreshTime =		CreateConVar(	"l4d2_gnome_healing_field_refresh_time",		"2.0",			"0=Off. Interval in seconds, for the healing field trigger the heal and beacon again.", CVAR_FLAGS, true, 0.0 );
	g_hCvarFieldHealAmount =		CreateConVar(	"l4d2_gnome_healing_field_heal_amount",			"1",			"Heal amount from being inside the healing field.", CVAR_FLAGS, true, 0.0 );
	g_hCvarFieldHealAmountIncap =	CreateConVar(	"l4d2_gnome_healing_field_heal_amount_incap",	"0",			"Heal amount for incapped players from being inside the healing field.", CVAR_FLAGS, true, 0.0 );
	g_hCvarFieldHealSelf =			CreateConVar(	"l4d2_gnome_healing_field_self",				"1",			"0=Only healing others. 1=Heal self and others.", CVAR_FLAGS );
	g_hCvarFieldBeacon =			CreateConVar(	"l4d2_gnome_healing_field_heal_beacon",			"0",			"0=Off. 1=Generates a beacon.", CVAR_FLAGS, true, 0.0, true, 1.0 );
	g_hCvarFieldColor =				CreateConVar(	"l4d2_gnome_healing_field_color",				"0 255 0",		"Healing field color. Three values between 0-255 separated by spaces. RGB: Red Green Blue.\nUse \"random\" to generate random colors.", CVAR_FLAGS );
	g_hCvarFieldStartRadius =		CreateConVar(	"l4d2_gnome_healing_field_start_radius",		"100.0",		"Healing field start radius.", CVAR_FLAGS, true, 0.0 );
	g_hCvarFieldEndRadius =			CreateConVar(	"l4d2_gnome_healing_field_end_radius",			"350.0",		"Healing field end radius. Also determines the max distance to heal players around the player holding the gnome.\nMax distance = (l4d2_gnome_healing_field_end_radius / 2) because of the diameter.", CVAR_FLAGS, true, 0.0 );
	g_hCvarFieldDuration =			CreateConVar(	"l4d2_gnome_healing_field_duration",			"1.0",			"How many seconds the healing field should last.", CVAR_FLAGS, true, 0.0 );
	g_hCvarFieldWidth =				CreateConVar(	"l4d2_gnome_healing_field_width",				"3.0",			"Healing field width.", CVAR_FLAGS, true, 0.0 );
	g_hCvarFieldAmplitude =			CreateConVar(	"l4d2_gnome_healing_field_amplitude",			"0.0",			"Healing field amplitude.", CVAR_FLAGS, true, 0.0 );
	CreateConVar(									"l4d2_gnome_version",							PLUGIN_VERSION,	"Healing Gnome plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	//AutoExecConfig(true,							"l4d2_gnome");

	// g_hCvarMaxHealth = FindConVar("first_aid_kit_max_heal");
	g_hCvarDecayRate = FindConVar("pain_pills_decay_rate");
	g_hCvarRate = FindConVar("sv_healing_gnome_replenish_rate");
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarFull.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHeal.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxM.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxT.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRandom.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSafe.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTemp.AddChangeHook(ConVarChanged_Cvars);
	// g_hCvarMaxHealth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDecayRate.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRate.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarIncapHealth = FindConVar("survivor_incap_health");
	g_hCvarIncapHealth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarField.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFieldRefreshTime.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFieldHealAmount.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFieldHealAmountIncap.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFieldHealSelf.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFieldBeacon.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFieldColor.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFieldStartRadius.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFieldEndRadius.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFieldDuration.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFieldWidth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFieldAmplitude.AddChangeHook(ConVarChanged_Cvars);

	RegAdminCmd("sm_gnome",			CmdGnomeTemp,		ADMFLAG_ROOT, 	"Spawns a temporary gnome at your crosshair.");
	RegAdminCmd("sm_gnomesave",		CmdGnomeSave,		ADMFLAG_ROOT, 	"Spawns a gnome at your crosshair and saves to config.");
	RegAdminCmd("sm_gnomedel",		CmdGnomeDelete,		ADMFLAG_ROOT, 	"Removes the gnome you are pointing at and deletes from the config if saved.");
	RegAdminCmd("sm_gnomekill",		CmdGnomeWipe,		ADMFLAG_ROOT, 	"Removes all gnomes from the current map and deletes them from the config.");
	RegAdminCmd("sm_gnomeglow",		CmdGnomeGlow,		ADMFLAG_ROOT, 	"Toggle to enable glow on all gnomes to see where they are placed.");
	RegAdminCmd("sm_gnomelist",		CmdGnomeList,		ADMFLAG_ROOT, 	"Display a list gnome positions and the total number of.");
	RegAdminCmd("sm_gnometele",		CmdGnomeTele,		ADMFLAG_ROOT, 	"Teleport to a gnome (Usage: sm_gnometele <index: 1 to MAX_GNOMES>).");
	RegAdminCmd("sm_gnomeang",		CmdGnomeAng,		ADMFLAG_ROOT, 	"Displays a menu to adjust the gnome angles your crosshair is over.");
	RegAdminCmd("sm_gnomepos",		CmdGnomePos,		ADMFLAG_ROOT, 	"Displays a menu to adjust the gnome origin your crosshair is over.");
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;
	PrecacheModel(MODEL_GNOME, true);
	g_iBeamSprite = PrecacheModel(SPRITE_BEAM, true);
	g_iHaloSprite = PrecacheModel(SPRITE_HALO, true);
}

public void OnMapEnd()
{
	g_iMap = 1;
	g_bMapStarted = false;
	ResetPlugin(false);
}

int GetColor(ConVar hCvar)
{
	char sTemp[12];
	hCvar.GetString(sTemp, sizeof(sTemp));

	if( sTemp[0] == 0 )
		return 0;

	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, sizeof(sColors), sizeof(sColors[]));

	if( color != 3 )
		return 0;

	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);

	return color;
}

void GetColors(char[] sColor, int colors[4])
{
	if( sColor[0] == 0 )
		return;

	char sColors[3][4];
	int color = ExplodeString(sColor, " ", sColors, sizeof(sColors), sizeof(sColors[]));

	if( color != 3 )
		return;

	colors[0] = StringToInt(sColors[0]);
	colors[1] = StringToInt(sColors[1]);
	colors[2] = StringToInt(sColors[2]);
	colors[3] = 255;
}

void GetRandomColors(int colors[4])
{
	colors[0] = GetRandomInt(0, 255);
	colors[1] = GetRandomInt(0, 255);
	colors[2] = GetRandomInt(0, 255);
	colors[3] = 255;
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
	g_iCvarGlow = g_hCvarGlow.IntValue;
	g_iCvarGlowCol = GetColor(g_hCvarGlowCol);
	g_iCvarFull = g_hCvarFull.IntValue;
	g_iCvarHeal = g_hCvarHeal.IntValue;
	g_iCvarMaxM = g_hCvarMaxM.IntValue;
	g_fCvarMaxT = g_hCvarMaxT.FloatValue;
	g_iCvarRandom = g_hCvarRandom.IntValue;
	g_iCvarSafe = g_hCvarSafe.IntValue;
	g_iCvarTemp = g_hCvarTemp.IntValue;
	// g_iCvarMaxHealth = g_hCvarMaxHealth.IntValue;
	g_fCvarDecayRate = g_hCvarDecayRate.FloatValue;
	g_fCvarRate = g_hCvarRate.FloatValue;
	g_iCvarIncapHealth = g_hCvarIncapHealth.IntValue;
	g_bCvarField = g_hCvarField.BoolValue;
	g_fCvarFieldRefreshTime = g_hCvarFieldRefreshTime.FloatValue;
	g_fCvarFieldHealAmount = g_hCvarFieldHealAmount.FloatValue;
	g_fCvarFieldHealAmountIncap = g_hCvarFieldHealAmountIncap.FloatValue;
	g_bCvarFieldHealSelf = g_hCvarFieldHealSelf.BoolValue;
	g_bCvarFieldBeacon = g_hCvarFieldBeacon.BoolValue;
	g_hCvarFieldColor.GetString(g_sCvarFieldColor, sizeof(g_sCvarFieldColor));
	g_bCvarFieldColorRandom = StrEqual(g_sCvarFieldColor, "random");
	GetColors(g_sCvarFieldColor, g_iCvarFieldColor);
	g_fCvarFieldStartRadius = g_hCvarFieldStartRadius.FloatValue;
	g_fCvarFieldEndRadius = g_hCvarFieldEndRadius.FloatValue;
	g_fCvarFieldDuration = g_hCvarFieldDuration.FloatValue;
	g_fCvarFieldWidth = g_hCvarFieldWidth.FloatValue;
	g_fCvarFieldAmplitude = g_hCvarFieldAmplitude.FloatValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		LoadGnomes();
		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		HookEvent("item_pickup",		Event_ItemPickup);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		ResetPlugin();
		g_bCvarAllow = false;
		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		UnhookEvent("item_pickup",		Event_ItemPickup);
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
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin(false);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(g_iMap == 1 ? 5.0 : 1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(g_iMap == 1 ? 5.0 : 1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action TimerStart(Handle timer)
{
	g_iMap = 0;
	ResetPlugin();
	LoadGnomes();

	if( g_iCvarSafe == 1 )
	{
		int iClients[MAXPLAYERS+1], count;

		for( int i = 1; i <= MaxClients; i++ )
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
				iClients[count++] = i;

		int client = GetRandomInt(0, count-1);
		client = iClients[client];

		if( client )
		{
			float vPos[3], vAng[3];
			GetClientAbsOrigin(client, vPos);
			GetClientAbsAngles(client, vAng);
			vPos[2] += 25.0;
			CreateGnome(vPos, vAng);
		}
	}
	else if( g_iCvarSafe == 2 )
	{
		int iClients[MAXPLAYERS+1], count;

		for( int i = 1; i <= MaxClients; i++ )
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
				iClients[count++] = i;

		int client = GetRandomInt(0, count-1);
		client = iClients[client];

		if( client )
		{
			int entity = GivePlayerItem(client, "weapon_gnome");
			if( entity != -1 )
				EquipPlayerWeapon(client, entity);
		}
	}
	return Plugin_Stop;
}

public void Event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCvarHeal || g_bCvarField )
	{
		char sTemp[6];
		event.GetString("item", sTemp, sizeof(sTemp));
		if( strcmp(sTemp, "gnome") == 0 )
		{
			int client = GetClientOfUserId(event.GetInt("userid"));
			g_iGnome[client] = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

			if( g_iCvarHeal && g_hTimerHeal == null )
			{
				g_hTimerHeal = CreateTimer(0.1, TimerHeal, _, TIMER_REPEAT);
			}

			if( g_bCvarField && g_hTimerHealingField == null )
			{
				g_hTimerHealingField = CreateTimer(g_fCvarFieldRefreshTime, TimerHealingField, _, TIMER_REPEAT);
			}
		}
	}
}

public Action TimerHeal(Handle timer)
{
	int entity;
	bool healed;

	if( g_iCvarHeal )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			entity = g_iGnome[i];
			if( entity )
			{
				if( IsClientInGame(i) && IsPlayerAlive(i) && entity == GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon") )
				{
					HealClient(i);
					healed = true;
				}
				else
					g_iGnome[i] = 0;
			}
		}
	}

	if( healed == false )
	{
		g_hTimerHeal = null;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void HealClient(int client)
{
	int iHealth = GetClientHealth(client);

	float fGameTime = GetGameTime();
	float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (fGameTime - fHealthTime) * g_fCvarDecayRate;

	// Heal temp health
	if( g_iCvarTemp == -1 || (g_iCvarTemp != 0 && GetRandomInt(1, 100) <= g_iCvarTemp) )
	{
		if( fHealth < 0.0 )
			fHealth = 0.0;

		// How much temp health to give
		float fBuff = (0.1 * g_fCvarRate);
		fHealth += fBuff;

		// Maximum health reached, do we full heal?
		if( g_iCvarFull == 1 && fHealth >= g_fCvarMaxT )
		{
			HealPlayer(client);
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
			SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
		}
		// Reached maximum health
		else if( iHealth + fHealth >= MAX_MAIN_HEALTH )
		{
			// Heal to max allowed temp, or to max main health
			if( fHealth >= g_fCvarMaxT )
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", g_fCvarMaxT);
			else
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(MAX_MAIN_HEALTH - iHealth));
			SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
		}

		// Temp buff is less than maximum allowed
		else if( fHealth < g_fCvarMaxT )
		{
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth);
			SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
		}
	}
	else
	{
		// Heal main health
		if( fGameTime - g_fHealTime[client] > 1.0 )
		{
			g_fHealTime[client] = fGameTime;

			int iBuff = RoundToFloor(g_fCvarRate);
			iHealth += iBuff;

			if( g_iCvarFull == 2 && iHealth >= g_iCvarMaxM )
			{
				HealPlayer(client);
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
			}

			else if( iHealth >= MAX_MAIN_HEALTH )
			{
				iHealth = MAX_MAIN_HEALTH;

				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
			}

			else if( iHealth + fHealth >= MAX_MAIN_HEALTH )
			{
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(MAX_MAIN_HEALTH - iHealth));
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
			}

			if( iHealth <= g_iCvarMaxM && iHealth <= MAX_MAIN_HEALTH )
			{
				SetEntityHealth(client, iHealth);
			}
		}
	}
}



// ====================================================================================================
//					HEALING FIELD
// ====================================================================================================
public Action TimerHealingField(Handle timer)
{
	if( !g_bCvarField )
	{
		g_hTimerHealingField = null;
		return Plugin_Stop;
	}

	int entity;
	bool healed;

	for( int i = 1; i <= MaxClients; i++ )
	{
		entity = g_iGnome[i];
		if( entity )
		{
			if( IsClientInGame(i) && IsPlayerAlive(i) && entity == GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon") )
			{
				float vPos[3];
				GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vPos);

				if( g_bCvarFieldBeacon )
					CreateBeamRing(vPos);

				HealingField(i, vPos);

				healed = true;
			}
			else
				g_iGnome[i] = 0;
		}
	}

	if( healed == false )
	{
		g_hTimerHealingField = null;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void HealingField(int healer, float vPos[3])
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( !g_bCvarFieldHealSelf && i == healer )
			continue;

		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
		{
			float vEnd[3];
			GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vEnd);

			if( (GetVectorDistance(vPos, vEnd) - DIST_TOLERANCE) <= (g_fCvarFieldEndRadius / 2) )
				HealClientOnHealingField(i);
		}
	}
}

void HealClientOnHealingField(int client)
{
	bool bIsIncap = (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1);

	if( bIsIncap )
	{
		int iHealth = GetClientHealth(client);
		if( iHealth >= g_iCvarIncapHealth )
			return;

		int iBuff = RoundToFloor(g_fCvarFieldHealAmountIncap);
		iHealth += iBuff;
		if( iHealth > g_iCvarIncapHealth )
			iHealth = g_iCvarIncapHealth;

		SetEntityHealth(client, iHealth);
	}
	else
	{
		int iHealth = GetClientHealth(client);

		float fGameTime = GetGameTime();
		float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
		fHealth -= (fGameTime - fHealthTime) * g_fCvarDecayRate;

		// Heal temp health
		if( g_iCvarTemp == -1 || (g_iCvarTemp != 0 && GetRandomInt(1, 100) <= g_iCvarTemp) )
		{
			if( fHealth < 0.0 )
				fHealth = 0.0;

			// How much temp health to give
			float fBuff = g_fCvarFieldHealAmount;
			fHealth += fBuff;

			// Maximum health reached, do we full heal?
			if( g_iCvarFull == 1 && fHealth >= g_fCvarMaxT )
			{
				HealPlayer(client);
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
			}
			// Reached maximum health
			else if( iHealth + fHealth >= MAX_MAIN_HEALTH )
			{
				// Heal to max allowed temp, or to max main health
				if( fHealth >= g_fCvarMaxT )
					SetEntPropFloat(client, Prop_Send, "m_healthBuffer", g_fCvarMaxT);
				else
					SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(MAX_MAIN_HEALTH - iHealth));
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
			}

			// Temp buff is less than maximum allowed
			else if( fHealth < g_fCvarMaxT )
			{
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
			}
		}
		else
		{
			// Heal main health
			if( fGameTime - g_fHealTime[client] > 1.0 )
			{
				g_fHealTime[client] = fGameTime;

				int iBuff = RoundToFloor(g_fCvarFieldHealAmount);
				iHealth += iBuff;

				if( g_iCvarFull == 2 && iHealth >= g_iCvarMaxM )
				{
					HealPlayer(client);
					SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
					SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
				}

				else if( iHealth >= MAX_MAIN_HEALTH )
				{
					iHealth = MAX_MAIN_HEALTH;

					SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
					SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
				}

				else if( iHealth + fHealth >= MAX_MAIN_HEALTH )
				{
					SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(MAX_MAIN_HEALTH - iHealth));
					SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
				}

				if( iHealth <= g_iCvarMaxM && iHealth <= MAX_MAIN_HEALTH )
				{
					SetEntityHealth(client, iHealth);
				}
			}
		}
	}
}

void CreateBeamRing(float vPos[3])
{
	int colors[4];

	if( g_bCvarFieldColorRandom )
		GetRandomColors(colors);
	else
	{
		colors[0] = g_iCvarFieldColor[0];
		colors[1] = g_iCvarFieldColor[1];
		colors[2] = g_iCvarFieldColor[2];
		colors[3] = g_iCvarFieldColor[3];
	}

	vPos[2] += 10.0;
	TE_SetupBeamRingPoint(vPos, g_fCvarFieldStartRadius, g_fCvarFieldEndRadius, g_iBeamSprite, g_iHaloSprite, 0, 0, g_fCvarFieldDuration, g_fCvarFieldWidth, g_fCvarFieldAmplitude, colors, 0, 0 );
	TE_SendToAll();
}



// ====================================================================================================
//					LOAD GNOMES
// ====================================================================================================
void LoadGnomes()
{
	if( g_bLoaded || g_iCvarRandom == 0 ) return;
	g_bLoaded = true;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	KeyValues hFile = new KeyValues("gnomes");
	if( !hFile.ImportFromFile(sPath) )
	{
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		delete hFile;
		return;
	}

	// Retrieve how many gnomes to display
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return;
	}

	// Spawn only a select few gnomes?
	int iIndexes[MAX_GNOMES+1];
	if( iCount > MAX_GNOMES )
		iCount = MAX_GNOMES;

	// Spawn saved gnomes or create random
	int iRandom = g_iCvarRandom;
	if( iRandom == -1 || iRandom > iCount)
		iRandom = iCount;
	if( iRandom != -1 )
	{
		for( int i = 1; i <= iCount; i++ )
			iIndexes[i-1] = i;

		SortIntegers(iIndexes, iCount, Sort_Random);
		iCount = iRandom;
	}

	// Get the gnome origins and spawn
	char sTemp[4];
	float vPos[3], vAng[3];
	int index;
	for( int i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		IntToString(index, sTemp, sizeof(sTemp));

		if( hFile.JumpToKey(sTemp) )
		{
			hFile.GetVector("angle", vAng);
			hFile.GetVector("origin", vPos);

			if( vPos[0] == 0.0 && vPos[0] == 0.0 && vPos[0] == 0.0 ) // Should never happen.
				LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Random=%d. Count=%d.", i, index, iRandom, iCount);
			else
				CreateGnome(vPos, vAng, index);
			hFile.GoBack();
		}
	}

	delete hFile;
}



// ====================================================================================================
//					CREATE GNOME
// ====================================================================================================
void CreateGnome(const float vOrigin[3], const float vAngles[3], int index = 0)
{
	if( g_iGnomeCount >= MAX_GNOMES )
		return;

	int iGnomeIndex = -1;
	for( int i = 0; i < MAX_GNOMES; i++ )
	{
		if( g_iGnomes[i][0] == 0 )
		{
			iGnomeIndex = i;
			break;
		}
	}

	if( iGnomeIndex == -1 )
		return;

	int entity = CreateEntityByName("prop_physics");
	if( entity == -1 )
		ThrowError("Failed to create gnome model.");

	g_iGnomes[iGnomeIndex][0] = EntIndexToEntRef(entity);
	g_iGnomes[iGnomeIndex][1] = index;
	DispatchKeyValue(entity, "model", MODEL_GNOME);
	DispatchSpawn(entity);
	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);

	if( g_iCvarGlow )
	{
		SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarGlow);
		SetEntProp(entity, Prop_Send, "m_iGlowType", 1);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowCol);
		AcceptEntityInput(entity, "StartGlowing");
	}

	g_iGnomeCount++;
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
//					sm_gnome
// ====================================================================================================
public Action CmdGnomeTemp(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Gnome] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}
	else if( g_iGnomeCount >= MAX_GNOMES )
	{
		PrintToChat(client, "%t", "Gnome_ErrorAddAnymoreGnomesUsed", CHAT_TAG, g_iGnomeCount, MAX_GNOMES);
		return Plugin_Handled;
	}

	float vPos[3], vAng[3];
	if( !SetTeleportEndPoint(client, vPos, vAng) )
	{
		PrintToChat(client, "%t", "Gnome_CannotPlaceGnomeTryAgain", CHAT_TAG);
		return Plugin_Handled;
	}

	CreateGnome(vPos, vAng);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_gnomesave
// ====================================================================================================
public Action CmdGnomeSave(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Gnome] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}
	else if( g_iGnomeCount >= MAX_GNOMES )
	{
		PrintToChat(client, "%t", "Gnome_ErrorAddAnymoreGnomesUsed", CHAT_TAG, g_iGnomeCount, MAX_GNOMES);
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
	}

	// Load config
	KeyValues hFile = new KeyValues("gnomes");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%t", "Gnome_ErrorCannotReadGnomeConfig", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !hFile.JumpToKey(sMap, true) )
	{
		PrintToChat(client, "%t", "Gnome_ErrorFailedAddMapGnome", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many gnomes are saved
	int iCount = hFile.GetNum("num", 0);
	if( iCount >= MAX_GNOMES )
	{
		PrintToChat(client, "%t", "Gnome_ErrorAddAnymoreGnomesUsed", CHAT_TAG, iCount, MAX_GNOMES);
		delete hFile;
		return Plugin_Handled;
	}

	// Save count
	iCount++;
	hFile.SetNum("num", iCount);

	char sTemp[4];
	IntToString(iCount, sTemp, sizeof(sTemp));

	if( hFile.JumpToKey(sTemp, true) )
	{
		// Set player position as gnome spawn location
		float vPos[3], vAng[3];
		if( !SetTeleportEndPoint(client, vPos, vAng) )
		{
			PrintToChat(client, "%t", "Gnome_CannotPlaceGnomeTryAgain", CHAT_TAG);
			delete hFile;
			return Plugin_Handled;
		}

		// Save angle / origin
		hFile.SetVector("angle", vAng);
		hFile.SetVector("origin", vPos);

		CreateGnome(vPos, vAng, iCount);

		// Save cfg
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%t", "Gnome_SavedPosAng", CHAT_TAG, iCount, MAX_GNOMES, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	}
	else
		PrintToChat(client, "%t", "Gnome_FailedSaveGnome", CHAT_TAG, iCount, MAX_GNOMES);

	delete hFile;
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_gnomedel
// ====================================================================================================
public Action CmdGnomeDelete(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Gnome] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return Plugin_Handled;
	entity = EntIndexToEntRef(entity);

	int cfgindex, index = -1;
	for( int i = 0; i < MAX_GNOMES; i++ )
	{
		if( g_iGnomes[i][0] == entity )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
		return Plugin_Handled;

	cfgindex = g_iGnomes[index][1];
	if( cfgindex == 0 )
	{
		RemoveGnome(index);
		return Plugin_Handled;
	}

	for( int i = 0; i < MAX_GNOMES; i++ )
	{
		if( g_iGnomes[i][1] > cfgindex )
			g_iGnomes[i][1]--;
	}

	g_iGnomeCount--;

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%t", "Gnome_ErrorCannotFindGnomeConfig", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	KeyValues hFile = new KeyValues("gnomes");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%t", "Gnome_ErrorCannotLoadGnomeConfig", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%t", "Gnome_ErrorCurrentMapNotGnome", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many gnomes
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return Plugin_Handled;
	}

	bool bMove;
	char sTemp[4];

	// Move the other entries down
	for( int i = cfgindex; i <= iCount; i++ )
	{
		IntToString(i, sTemp, sizeof(sTemp));

		if( hFile.JumpToKey(sTemp) )
		{
			if( !bMove )
			{
				bMove = true;
				hFile.DeleteThis();
				RemoveGnome(index);
			}
			else
			{
				IntToString(i-1, sTemp, sizeof(sTemp));
				hFile.SetSectionName(sTemp);
			}
		}

		hFile.Rewind();
		hFile.JumpToKey(sMap);
	}

	if( bMove )
	{
		iCount--;
		hFile.SetNum("num", iCount);

		// Save to file
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%t", "Gnome_RemovedConfig", CHAT_TAG, iCount, MAX_GNOMES);
	}
	else
		PrintToChat(client, "%t", "Gnome_FailedRemoveGnomeConfig", CHAT_TAG, iCount, MAX_GNOMES);

	delete hFile;
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_gnomewipe
// ====================================================================================================
public Action CmdGnomeWipe(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Gnome] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%t", "Gnome_ErrorCannotFindGnomeConfig", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = new KeyValues("gnomes");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%t", "Gnome_ErrorCannotLoadGnomeConfig", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap, false) )
	{
		PrintToChat(client, "%t", "Gnome_ErrorCurrentMapNotGnome", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	hFile.DeleteThis();
	ResetPlugin();

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	PrintToChat(client, "%t", "Gnome_0AllGnomesRemovedConfig", CHAT_TAG, MAX_GNOMES);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_gnomeglow
// ====================================================================================================
public Action CmdGnomeGlow(int client, int args)
{
	static bool glow;
	glow = !glow;
	PrintToChat(client, "%t", "Gnome_GlowTurned", CHAT_TAG, glow ? "on" : "off");

	VendorGlow(glow);
	return Plugin_Handled;
}

void VendorGlow(int glow)
{
	int ent;

	for( int i = 0; i < MAX_GNOMES; i++ )
	{
		ent = g_iGnomes[i][0];
		if( IsValidEntRef(ent) )
		{
			SetEntProp(ent, Prop_Send, "m_iGlowType", 3);
			SetEntProp(ent, Prop_Send, "m_glowColorOverride", 65535);
			SetEntProp(ent, Prop_Send, "m_nGlowRange", glow ? 0 : 50);
			ChangeEdictState(ent, FindSendPropInfo("prop_dynamic", "m_nGlowRange"));
		}
	}
}

// ====================================================================================================
//					sm_gnomelist
// ====================================================================================================
public Action CmdGnomeList(int client, int args)
{
	float vPos[3];
	int count;
	for( int i = 0; i < MAX_GNOMES; i++ )
	{
		if( IsValidEntRef(g_iGnomes[i][0]) )
		{
			count++;
			GetEntPropVector(g_iGnomes[i][0], Prop_Data, "m_vecOrigin", vPos);
			if( client )	PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
			else			PrintToConsole(client, "[Gnome] %d) %f %f %f", i+1, vPos[0], vPos[1], vPos[2]);
		}
	}

	if( client )	PrintToChat(client, "%t", "Gnome_Total", CHAT_TAG, count);
	else			PrintToConsole(client, "[Gnome] Total: %d.", count);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_gnometele
// ====================================================================================================
public Action CmdGnomeTele(int client, int args)
{
	if( args == 1 )
	{
		char arg[4];
		GetCmdArg(1, arg, sizeof(arg));
		int index = StringToInt(arg) - 1;
		if( index > -1 && index < MAX_GNOMES && IsValidEntRef(g_iGnomes[index][0]) )
		{
			float vPos[3];
			GetEntPropVector(g_iGnomes[index][0], Prop_Data, "m_vecOrigin", vPos);
			vPos[2] += 20.0;
			TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
			PrintToChat(client, "%t", "Gnome_Teleported", CHAT_TAG, index + 1);
			return Plugin_Handled;
		}

		PrintToChat(client, "%t", "Gnome_CouldNotFindIndexTeleportation", CHAT_TAG);
	}
	else
		PrintToChat(client, "%t", "Gnome_UsageSMGnometeleIndex1", CHAT_TAG, MAX_GNOMES);
	return Plugin_Handled;
}

// ====================================================================================================
//					MENU ANGLE
// ====================================================================================================
public Action CmdGnomeAng(int client, int args)
{
	ShowMenuAng(client);
	return Plugin_Handled;
}

void ShowMenuAng(int client)
{
	CreateMenus();
	g_hMenuAng.Display(client, MENU_TIME_FOREVER);
}

public int AngMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		if( index == 6 )
			SaveData(client);
		else
			SetAngle(client, index);
		ShowMenuAng(client);
	}
	return 0;
}

void SetAngle(int client, int index)
{
	int aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		float vAng[3];
		int entity;
		aim = EntIndexToEntRef(aim);

		for( int i = 0; i < MAX_GNOMES; i++ )
		{
			entity = g_iGnomes[i][0];

			if( entity == aim  )
			{
				GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

				switch( index )
				{
					case 0: vAng[0] += 5.0;
					case 1: vAng[1] += 5.0;
					case 2: vAng[2] += 5.0;
					case 3: vAng[0] -= 5.0;
					case 4: vAng[1] -= 5.0;
					case 5: vAng[2] -= 5.0;
				}

				TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);

				PrintToChat(client, "%t", "Gnome_NewAngles", CHAT_TAG, vAng[0], vAng[1], vAng[2]);
				break;
			}
		}
	}
}

// ====================================================================================================
//					MENU ORIGIN
// ====================================================================================================
public Action CmdGnomePos(int client, int args)
{
	ShowMenuPos(client);
	return Plugin_Handled;
}

void ShowMenuPos(int client)
{
	CreateMenus();
	g_hMenuPos.Display(client, MENU_TIME_FOREVER);
}

public int PosMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		if( index == 6 )
			SaveData(client);
		else
			SetOrigin(client, index);
		ShowMenuPos(client);
	}
	return 0;
}

void SetOrigin(int client, int index)
{
	int aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		float vPos[3];
		int entity;
		aim = EntIndexToEntRef(aim);

		for( int i = 0; i < MAX_GNOMES; i++ )
		{
			entity = g_iGnomes[i][0];

			if( entity == aim  )
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

				switch( index )
				{
					case 0: vPos[0] += 0.5;
					case 1: vPos[1] += 0.5;
					case 2: vPos[2] += 0.5;
					case 3: vPos[0] -= 0.5;
					case 4: vPos[1] -= 0.5;
					case 5: vPos[2] -= 0.5;
				}

				TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

				PrintToChat(client, "%t", "Gnome_NewOrigin", CHAT_TAG, vPos[0], vPos[1], vPos[2]);
				break;
			}
		}
	}
}

void SaveData(int client)
{
	int entity, index;
	int aim = GetClientAimTarget(client, false);
	if( aim == -1 )
		return;

	aim = EntIndexToEntRef(aim);

	for( int i = 0; i < MAX_GNOMES; i++ )
	{
		entity = g_iGnomes[i][0];

		if( entity == aim  )
		{
			index = g_iGnomes[i][1];
			break;
		}
	}

	if( index == 0 )
		return;

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%t", "Gnome_ErrorCannotFindGnomeConfig", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	KeyValues hFile = new KeyValues("gnomes");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%t", "Gnome_ErrorCannotLoadGnomeConfig", CHAT_TAG, sPath);
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%t", "Gnome_ErrorCurrentMapNotGnome", CHAT_TAG);
		delete hFile;
		return;
	}

	float vAng[3], vPos[3];
	char sTemp[4];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

	IntToString(index, sTemp, sizeof(sTemp));
	if( hFile.JumpToKey(sTemp) )
	{
		hFile.SetVector("angle", vAng);
		hFile.SetVector("origin", vPos);

		// Save cfg
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%t", "Gnome_SavedOriginAnglesDataConfig", CHAT_TAG);
	}
}

void CreateMenus()
{
	if( g_hMenuAng == null )
	{
		g_hMenuAng = new Menu(AngMenuHandler);
		g_hMenuAng.AddItem("", "X + 5.0");
		g_hMenuAng.AddItem("", "Y + 5.0");
		g_hMenuAng.AddItem("", "Z + 5.0");
		g_hMenuAng.AddItem("", "X - 5.0");
		g_hMenuAng.AddItem("", "Y - 5.0");
		g_hMenuAng.AddItem("", "Z - 5.0");
		g_hMenuAng.AddItem("", "SAVE");
		g_hMenuAng.SetTitle("Set Angle");
		g_hMenuAng.ExitButton = true;
	}

	if( g_hMenuPos == null )
	{
		g_hMenuPos = new Menu(PosMenuHandler);
		g_hMenuPos.AddItem("", "X + 0.5");
		g_hMenuPos.AddItem("", "Y + 0.5");
		g_hMenuPos.AddItem("", "Z + 0.5");
		g_hMenuPos.AddItem("", "X - 0.5");
		g_hMenuPos.AddItem("", "Y - 0.5");
		g_hMenuPos.AddItem("", "Z - 0.5");
		g_hMenuPos.AddItem("", "SAVE");
		g_hMenuPos.SetTitle("Set Position");
		g_hMenuPos.ExitButton = true;
	}
}



// ====================================================================================================
//					STUFF
// ====================================================================================================
bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

void ResetPlugin(bool all = true)
{
	g_bLoaded = false;
	g_iGnomeCount = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;

	for( int i = 1; i <= MAXPLAYERS; i++ )
	{
		g_fHealTime[i] = 0.0;
		g_iGnome[i] = 0;
	}

	if( all )
		for( int i = 0; i < MAX_GNOMES; i++ )
			RemoveGnome(i);

	delete g_hTimerHeal;

	delete g_hTimerHealingField;
}

void RemoveGnome(int index)
{
	int entity = g_iGnomes[index][0];
	g_iGnomes[index][0] = 0;

	if( IsValidEntRef(entity) )
		RemoveEntity(entity);
}

void HealPlayer(int client)
{
	int bits = GetUserFlagBits(client);
	int flags = GetCommandFlags("give");
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give health");
	SetUserFlagBits(client, bits);
	SetCommandFlags("give", flags);
}



// ====================================================================================================
//					POSITION
// ====================================================================================================
void MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	fDistance *= -1.0;
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
}

void MoveSideway(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	fDistance *= -1.0;
	float vDir[3];
	GetAngleVectors(vAng, NULL_VECTOR, vDir, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
}

bool SetTeleportEndPoint(int client, float vPos[3], float vAng[3])
{
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, _TraceFilter);

	if( TR_DidHit(trace) )
	{
		float vNorm[3];
		TR_GetEndPosition(vPos, trace);
		TR_GetPlaneNormal(trace, vNorm);
		float angle = vAng[1];
		GetVectorAngles(vNorm, vAng);

		vPos[2] += 25.0;

		if( vNorm[2] == 1.0 )
		{
			vAng[0] = 0.0;
			vAng[1] += angle;
			MoveSideway(vPos, vAng, vPos, -8.0);
		}
		else
		{
			vAng[0] = 0.0;
			vAng[1] += angle - 90.0;
			MoveForward(vPos, vAng, vPos, -10.0);
		}
	}
	else
	{
		delete trace;
		return false;
	}

	delete trace;
	return true;
}

public bool _TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}
