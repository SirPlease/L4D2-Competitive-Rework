/*  SM Fortnite Emotes Extended
 *
 *  Copyright (C) 2020 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma newdecls required


#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_BONEMERGE_FASTCULL       (1 << 7)
#define EF_NORECEIVESHADOW          (1 << 6)
#define EF_PARENT_ANIMATES          (1 << 9)
#define HIDEHUD_ALL                 (1 << 2)
#define HIDEHUD_CROSSHAIR           (1 << 8)
#define CVAR_FLAGS			FCVAR_NOTIFY


ConVar g_cvHidePlayers;

TopMenu hTopMenu;

ConVar g_cvFlagEmotesMenu;
ConVar g_cvFlagDancesMenu;
ConVar g_cvCooldown;
ConVar g_cvSoundVolume;
ConVar g_cvEmotesSounds;
ConVar g_cvHideWeapons;
ConVar g_cvTeleportBack;
ConVar g_cvSpeed;

int g_iEmoteEnt[MAXPLAYERS+1];
int g_iEmoteSoundEnt[MAXPLAYERS+1];

int g_EmotesTarget[MAXPLAYERS+1];

char g_sEmoteSound[MAXPLAYERS+1][PLATFORM_MAX_PATH];

bool g_bClientDancing[MAXPLAYERS+1];


Handle CooldownTimers[MAXPLAYERS+1];
bool g_bEmoteCooldown[MAXPLAYERS+1];

int g_iWeaponHandEnt[MAXPLAYERS+1];

Handle g_EmoteForward;
Handle g_EmoteForward_Pre;
bool g_bHooked[MAXPLAYERS + 1];

float g_fLastAngles[MAXPLAYERS+1][3];
float g_fLastPosition[MAXPLAYERS+1][3];


public Plugin myinfo =
{
	name = "SM Fortnite Emotes Extended - L4D Version",
	author = "Kodua, Franc1sco franug, TheBO$$, Foxhound",
	description = "This plugin is for demonstration of some animations from Fortnite in L4D2",
	version = "1.4.3",
	url = "https://forums.alliedmods.net/showthread.php?t=318981"
};

EngineVersion _Game;

public void OnPluginStart() {
	
	_Game = GetEngineVersion();
	
	LoadTranslations("common.phrases");
	LoadTranslations("fnemotes.phrases");

	RegConsoleCmd("sm_emotes", Command_Menu, "");
	RegConsoleCmd("sm_emote", Command_Menu, "");
	RegConsoleCmd("sm_dances", Command_Menu, "");
	RegConsoleCmd("sm_dance", Command_Menu, "");
	RegAdminCmd("sm_setemotes", Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]", "");
	RegAdminCmd("sm_setemote", Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]", "");
	RegAdminCmd("sm_setdances", Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]", "");
	RegAdminCmd("sm_setdance", Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]", "");

	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);

	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);

	HookEvent("round_start", Event_Start);

	/**
		Convars
	**/

	g_cvEmotesSounds = CreateConVar("sm_emotes_sounds", "1", "Enable/Disable sounds for emotes.", CVAR_FLAGS);
	g_cvCooldown = CreateConVar("sm_emotes_cooldown", "2.0", "Cooldown for emotes in seconds. -1 or 0 = no cooldown.", CVAR_FLAGS);
	g_cvSoundVolume = CreateConVar("sm_emotes_soundvolume", "1.0", "Sound volume for the emotes.", CVAR_FLAGS);
	g_cvFlagEmotesMenu = CreateConVar("sm_emotes_admin_flag_menu", "", "admin flag for emotes (empty for all players)", CVAR_FLAGS);
	g_cvFlagDancesMenu = CreateConVar("sm_dances_admin_flag_menu", "", "admin flag for dances (empty for all players)", CVAR_FLAGS);
	g_cvHideWeapons = CreateConVar("sm_emotes_hide_weapons", "1", "Hide weapons when dancing", CVAR_FLAGS);
	g_cvHidePlayers = CreateConVar("sm_emotes_hide_enemies", "0", "Hide enemy players when dancing", CVAR_FLAGS);
	g_cvTeleportBack = CreateConVar("sm_emotes_teleportonend", "0", "Teleport back to the exact position when he started to dance. (Some maps need this for teleport triggers)", CVAR_FLAGS);
	g_cvSpeed = CreateConVar("sm_emotes_speed", "0.80", "Sets the playback speed of the animation. default (1.0)", CVAR_FLAGS);

	AutoExecConfig(true, "fortnite_emotes_extended_l4d");

	/**
		End Convars
	**/

	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null)) {
		OnAdminMenuReady(topmenu);
	}

	g_EmoteForward = CreateGlobalForward("fnemotes_OnEmote", ET_Ignore, Param_Cell);
	g_EmoteForward_Pre = CreateGlobalForward("fnemotes_OnEmote_Pre", ET_Event, Param_Cell);
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
            if (IsValidClient(i) && g_bClientDancing[i]) {
				StopEmote(i);
			}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("fnemotes");
	CreateNative("fnemotes_IsClientEmoting", Native_IsClientEmoting);
	return APLRes_Success;
}



int Native_IsClientEmoting(Handle plugin, int numParams)
{
	return g_bClientDancing[GetNativeCell(1)];
}

public void OnMapStart()
{
	
	AddFileToDownloadsTable("models/player/custom_player/foxhound/fortnite_dances_emotes_ok.mdl");
	AddFileToDownloadsTable("models/player/custom_player/foxhound/fortnite_dances_emotes_ok.vvd");
	AddFileToDownloadsTable("models/player/custom_player/foxhound/fortnite_dances_emotes_ok.dx90.vtx");



	// edit
	// add the sound file routes here

	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/ninja_dance_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/dance_soldier_03.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Hip_Hop_Good_Vibes_Mix_01_Loop.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_zippy_A.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_electroshuffle_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_aerobics_01.mp3"); 
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_music_emotes_bendy.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_bandofthefort_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_boogiedown.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_flapper_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_chicken_foley_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_cry.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_music_boneless.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emotes_music_shoot_v7.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Athena_Emotes_Music_SwipeIt.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_disco.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_worm_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_music_emotes_takethel.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_breakdance_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Dance_Pump.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_ridethepony_music_01.mp3"); 
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_facepalm_foley_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Athena_Emotes_OnTheHook_02.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_floss_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_FlippnSexy.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_fresh_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_groove_jam_a.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/br_emote_shred_guitar_mix_03_loop.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_HeelClick.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/s5_hiphop_breakin_132bmp_loop.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Hotstuff.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_hula_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_infinidab.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_Intensity.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_irish_jig_foley_music_loop.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Athena_Music_Emotes_KoreanEagle.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_kpop_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_laugh_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_LivingLarge_A.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Luchador.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Hillbilly_Shuffle.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_samba_new_B.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_makeitrain_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Athena_Emote_PopLock.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_PopRock_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_robot_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_salute_foley_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Snap1.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_stagebow.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Dino_Complete.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_founders_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emotes_music_twist.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Warehouse.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Wiggle_Music_Loop.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Yeet.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/youre_awesome_emote_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emotes_lankylegs_loop_02.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/eastern_bloc_musc_setup_d.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_hot_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_capoeira.mp3");
    

	// this dont touch
	PrecacheModel("models/player/custom_player/foxhound/fortnite_dances_emotes_ok.mdl", true);

	// edit
	// add mp3 files without sound/
	// add wav files with */

	
	PrecacheSound("kodua/fortnite_emotes/ninja_dance_01.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/dance_soldier_03.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Hip_Hop_Good_Vibes_Mix_01_Loop.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/emote_zippy_A.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_electroshuffle_music.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/emote_aerobics_01.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_music_emotes_bendy.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_bandofthefort_music.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/emote_boogiedown.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/emote_capoeira.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_flapper_music.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_chicken_foley_01.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/emote_cry.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_music_boneless.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emotes_music_shoot_v7.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Athena_Emotes_Music_SwipeIt.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_disco.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_worm_music.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_music_emotes_takethel.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_breakdance_music.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Emote_Dance_Pump.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_ridethepony_music_01.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_facepalm_foley_01.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Athena_Emotes_OnTheHook_02.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_floss_music.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Emote_FlippnSexy.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_fresh_music.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/emote_groove_jam_a.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/br_emote_shred_guitar_mix_03_loop.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Emote_HeelClick.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/s5_hiphop_breakin_132bmp_loop.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Emote_Hotstuff.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/emote_hula_01.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_infinidab.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/emote_Intensity.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/emote_irish_jig_foley_music_loop.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Athena_Music_Emotes_KoreanEagle.mp3");
	PrecacheSound("kodua/fortnite_emotes/emote_kpop_01.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/emote_laugh_01.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/emote_LivingLarge_A.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Emote_Luchador.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Emote_Hillbilly_Shuffle.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/emote_samba_new_B.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_makeitrain_music.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Athena_Emote_PopLock.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Emote_PopRock_01.mp3");
	PrecacheSound("kodua/fortnite_emotes/athena_emote_robot_music.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_salute_foley_01.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Emote_Snap1.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/emote_stagebow.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Emote_Dino_Complete.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_founders_music.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emotes_music_twist.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Emote_Warehouse.mp3");
	PrecacheSound("kodua/fortnite_emotes/Wiggle_Music_Loop.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/Emote_Yeet.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/youre_awesome_emote_music.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emotes_lankylegs_loop_02.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/eastern_bloc_musc_setup_d.mp3");//ok
	PrecacheSound("kodua/fortnite_emotes/athena_emote_hot_music.mp3");//ok
	
}

public void OnClientPutInServer(int client)
{
	if (IsValidClient(client))
	{	
		ResetCam(client);
		TerminateEmote(client);
		g_iWeaponHandEnt[client] = INVALID_ENT_REFERENCE;

		if (CooldownTimers[client] != null)
		{
			KillTimer(CooldownTimers[client]);
		}
	}
}

public void OnClientDisconnect(int client)
{
	if (IsValidClient(client))
	{
		ResetCam(client);
		TerminateEmote(client);

		if (CooldownTimers[client] != null)
		{
			KillTimer(CooldownTimers[client]);
			CooldownTimers[client] = null;
			g_bEmoteCooldown[client] = false;
		}
	}
	g_bHooked[client] = false;
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client))
	{
		ResetCam(client);
		StopEmote(client);
	}
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) 
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client)) {
		return Plugin_Continue;
	}

	if (attacker!=client)
	{
		
		StopEmote(client);
	}

	return Plugin_Continue;
}

public Action Event_Start(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
            if (IsValidClient(i, false) && g_bClientDancing[i]) {
				ResetCam(i);
				//StopEmote(client);
				WeaponUnblock(i);
				
				g_bClientDancing[i] = false;

			}

	return Plugin_Continue;
}

public Action Command_Menu(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;


	char sBuffer[32];
	g_cvFlagEmotesMenu.GetString(sBuffer, sizeof(sBuffer));

	if (CheckAdminFlags(client, ReadFlagString(sBuffer)))
	{
		Menu_Dance(client);
	}
	else CPrintToChat(client, "%t", "NO_DANCES_ACCESS_FLAG");	

	return Plugin_Handled;
}

Action CreateEmote(int client, const char[] anim1, const char[] anim2, const char[] soundName, bool isLooped) {
	if (!IsValidClient(client)) return Plugin_Handled;

	if (g_EmoteForward_Pre != null) {
		Action res = Plugin_Continue;
		Call_StartForward(g_EmoteForward_Pre);
		Call_PushCell(client);
		Call_Finish(res);

		if (res != Plugin_Continue) {
			return Plugin_Handled;
		}
	}

	if (!IsPlayerAlive(client)) {
		CPrintToChat(client, "%t", "MUST_BE_ALIVE");
		return Plugin_Handled;
	}

	if (! (GetEntityFlags(client) & FL_ONGROUND)) {
		CPrintToChat(client, "%t", "STAY_ON_GROUND");
		return Plugin_Handled;
	}

	if (CooldownTimers[client]) {
		CPrintToChat(client, "%t", "COOLDOWN_EMOTES");
		return Plugin_Handled;
	}

	if (StrEqual(anim1, "")) {
		CPrintToChat(client, "%t", "AMIN_1_INVALID");
		return Plugin_Handled;
	}

	if (g_iEmoteEnt[client]) StopEmote(client);

	if (GetEntityMoveType(client) == MOVETYPE_NONE) {
		CPrintToChat(client, "%t", "CANNOT_USE_NOW");
		return Plugin_Handled;
	}

	int EmoteEnt = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(EmoteEnt)) {
		SetEntityMoveType(client, MOVETYPE_NONE);
		WeaponBlock(client);

		float vec[3],
		ang[3];
		GetClientAbsOrigin(client, vec);
		GetClientAbsAngles(client, ang);

		g_fLastPosition[client] = vec;
		g_fLastAngles[client] = ang;

		char emoteEntName[16];
		FormatEx(emoteEntName, sizeof(emoteEntName), "emoteEnt%i", GetRandomInt(1000000, 9999999));

		DispatchKeyValue(EmoteEnt, "targetname", emoteEntName);
		DispatchKeyValue(EmoteEnt, "model", "models/player/custom_player/foxhound/fortnite_dances_emotes_ok.mdl");

		DispatchKeyValue(EmoteEnt, "solid", "0");
		DispatchKeyValue(EmoteEnt, "rendermode", "10");

		ActivateEntity(EmoteEnt);
		DispatchSpawn(EmoteEnt);

		TeleportEntity(EmoteEnt, vec, ang, NULL_VECTOR);

		SetVariantString(emoteEntName);
		AcceptEntityInput(client, "SetParent", client, client, 0);

		g_iEmoteEnt[client] = EntIndexToEntRef(EmoteEnt);

		SetEntProp(client, Prop_Send, "m_fEffects", EF_BONEMERGE | EF_NOSHADOW | EF_NORECEIVESHADOW | EF_BONEMERGE_FASTCULL | EF_PARENT_ANIMATES);

		//Sound

		if (g_cvEmotesSounds.BoolValue && !StrEqual(soundName, "")) {
			int EmoteSoundEnt = CreateEntityByName("info_target");
			if (IsValidEntity(EmoteSoundEnt)) {
				char soundEntName[16];
				FormatEx(soundEntName, sizeof(soundEntName), "soundEnt%i", GetRandomInt(1000000, 9999999));

				DispatchKeyValue(EmoteSoundEnt, "targetname", soundEntName);

				DispatchSpawn(EmoteSoundEnt);

				vec[2] += 72.0;
				TeleportEntity(EmoteSoundEnt, vec, NULL_VECTOR, NULL_VECTOR);

				SetVariantString(emoteEntName);
				AcceptEntityInput(EmoteSoundEnt, "SetParent");

				g_iEmoteSoundEnt[client] = EntIndexToEntRef(EmoteSoundEnt);

				//Formatting sound path

				char soundNameBuffer[64];

				if (StrEqual(soundName, "ninja_dance_01") || StrEqual(soundName, "dance_soldier_03")) {
					int randomSound = GetRandomInt(0, 1);

					soundNameBuffer = randomSound ? "ninja_dance_01":"dance_soldier_03";

				} else {
					FormatEx(soundNameBuffer, sizeof(soundNameBuffer), "%s", soundName);
				}

				FormatEx(g_sEmoteSound[client], PLATFORM_MAX_PATH, "kodua/fortnite_emotes/%s.mp3", soundNameBuffer);

				EmitSoundToAll(g_sEmoteSound[client], EmoteSoundEnt, SNDCHAN_AUTO, SNDLEVEL_CONVO, _, g_cvSoundVolume.FloatValue, _, _, vec, _, _, _);
			}
		} else {
			g_sEmoteSound[client] = "";
		}

		if (StrEqual(anim2, "none", false)) {
			HookSingleEntityOutput(EmoteEnt, "OnAnimationDone", EndAnimation, true);
		} else {
			SetVariantString(anim2);
			AcceptEntityInput(EmoteEnt, "SetDefaultAnimation", -1, -1, 0);
		}

		SetVariantString(anim1);
		AcceptEntityInput(EmoteEnt, "SetAnimation", -1, -1, 0);

		if (g_cvSpeed.FloatValue != 1.0) SetEntPropFloat(EmoteEnt, Prop_Send, "m_flPlaybackRate", g_cvSpeed.FloatValue);

		SetCam(client);

		g_bClientDancing[client] = true;

		if (g_cvHidePlayers.BoolValue) {
			for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(client) && !g_bHooked[i]) {
				SDKHook(i, SDKHook_SetTransmit, SetTransmit);
				g_bHooked[i] = true;
			}
		}

		if (g_cvCooldown.FloatValue > 0.0) {
			CooldownTimers[client] = CreateTimer(g_cvCooldown.FloatValue, ResetCooldown, client);
		}

		if (g_EmoteForward != null) {
			Call_StartForward(g_EmoteForward);
			Call_PushCell(client);
			Call_Finish();
		}

		if(isLooped){}
	}

	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
	if (g_bClientDancing[client] && !(GetEntityFlags(client) & FL_ONGROUND))
		StopEmote(client);

	static int iAllowedButtons = IN_BACK | IN_FORWARD | IN_MOVELEFT | IN_MOVERIGHT | IN_WALK | IN_SPEED | IN_SCORE;

	if (iButtons == 0)
		return Plugin_Continue;

	if (g_iEmoteEnt[client] == 0)
		return Plugin_Continue;

	if ((iButtons & iAllowedButtons) && !(iButtons &~ iAllowedButtons)) 
		return Plugin_Continue;

	StopEmote(client);

	return Plugin_Continue;
}

void EndAnimation(const char[] output, int caller, int activator, float delay) 
{
	if (caller > 0)
	{
		activator = GetEmoteActivator(EntIndexToEntRef(caller));
		StopEmote(activator);
	}
}

int GetEmoteActivator(int iEntRefDancer)
{
	if (iEntRefDancer == INVALID_ENT_REFERENCE)
		return 0;
	
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (g_iEmoteEnt[i] == iEntRefDancer) 
		{
			return i;
		}
	}
	return 0;
}

void StopEmote(int client)
{
	if (!g_iEmoteEnt[client])
		return;

	int iEmoteEnt = EntRefToEntIndex(g_iEmoteEnt[client]);
	if (iEmoteEnt && iEmoteEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteEnt))
	{
		char emoteEntName[50];
		GetEntPropString(iEmoteEnt, Prop_Data, "m_iName", emoteEntName, sizeof(emoteEntName));
		SetVariantString(emoteEntName);
		AcceptEntityInput(client, "ClearParent", iEmoteEnt, iEmoteEnt, 0);
		DispatchKeyValue(iEmoteEnt, "OnUser1", "!self,Kill,,1.0,-1");
		AcceptEntityInput(iEmoteEnt, "FireUser1");
		
		if(g_cvTeleportBack.BoolValue)
			TeleportEntity(client, g_fLastPosition[client], g_fLastAngles[client], NULL_VECTOR);
		
		ResetCam(client);
		WeaponUnblock(client);
		SetEntityMoveType(client, MOVETYPE_WALK);

		g_iEmoteEnt[client] = 0;
		g_bClientDancing[client] = false;
	} else
	{
		g_iEmoteEnt[client] = 0;
		g_bClientDancing[client] = false;
	}

	if (g_iEmoteSoundEnt[client])
	{
		int iEmoteSoundEnt = EntRefToEntIndex(g_iEmoteSoundEnt[client]);

		if (!StrEqual(g_sEmoteSound[client], "") && iEmoteSoundEnt && iEmoteSoundEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteSoundEnt))
		{
			StopSound(iEmoteSoundEnt, SNDCHAN_AUTO, g_sEmoteSound[client]);
			AcceptEntityInput(iEmoteSoundEnt, "Kill");
			g_iEmoteSoundEnt[client] = 0;
		} else
		{
			g_iEmoteSoundEnt[client] = 0;
		}
	}
}

void TerminateEmote(int client)
{
	if (!g_iEmoteEnt[client])
		return;

	int iEmoteEnt = EntRefToEntIndex(g_iEmoteEnt[client]);
	if (iEmoteEnt && iEmoteEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteEnt))
	{
		char emoteEntName[50];
		GetEntPropString(iEmoteEnt, Prop_Data, "m_iName", emoteEntName, sizeof(emoteEntName));
		SetVariantString(emoteEntName);
		AcceptEntityInput(client, "ClearParent", iEmoteEnt, iEmoteEnt, 0);
		DispatchKeyValue(iEmoteEnt, "OnUser1", "!self,Kill,,1.0,-1");
		AcceptEntityInput(iEmoteEnt, "FireUser1");

		g_iEmoteEnt[client] = 0;
		g_bClientDancing[client] = false;
	} else
	{
		g_iEmoteEnt[client] = 0;
		g_bClientDancing[client] = false;
	}

	if (g_iEmoteSoundEnt[client])
	{
		int iEmoteSoundEnt = EntRefToEntIndex(g_iEmoteSoundEnt[client]);

		if (!StrEqual(g_sEmoteSound[client], "") && iEmoteSoundEnt && iEmoteSoundEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteSoundEnt))
		{
			StopSound(iEmoteSoundEnt, SNDCHAN_AUTO, g_sEmoteSound[client]);
			AcceptEntityInput(iEmoteSoundEnt, "Kill");
			g_iEmoteSoundEnt[client] = 0;
		} else
		{
			g_iEmoteSoundEnt[client] = 0;
		}
	}
}

void WeaponBlock(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUseSwitch);
	SDKHook(client, SDKHook_WeaponSwitch, WeaponCanUseSwitch);
	
	if(g_cvHideWeapons.BoolValue)
		SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
		
	int iEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(iEnt != -1)
	{
		g_iWeaponHandEnt[client] = EntIndexToEntRef(iEnt);
		
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
	}
}

void WeaponUnblock(int client)
{
	SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUseSwitch);
	SDKUnhook(client, SDKHook_WeaponSwitch, WeaponCanUseSwitch);
	
	//Even if are not activated, there will be no errors
	SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	
	if(GetEmotePeople() == 0)
	{
		for(int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && g_bHooked[i])
			{
				SDKUnhook(i, SDKHook_SetTransmit, SetTransmit);
				g_bHooked[i] = false;
			}
	}
	
	if(IsPlayerAlive(client) && g_iWeaponHandEnt[client] != INVALID_ENT_REFERENCE)
	{
		int iEnt = EntRefToEntIndex(g_iWeaponHandEnt[client]);
		if(iEnt != INVALID_ENT_REFERENCE)
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iEnt);
		}
	}
	
	g_iWeaponHandEnt[client] = INVALID_ENT_REFERENCE;
}

Action WeaponCanUseSwitch(int client, int weapon)
{
	return Plugin_Stop;
}

void OnPostThinkPost(int client)
{
	SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
}

public Action SetTransmit(int entity, int client) 
{ 
	if(g_bClientDancing[client] && IsPlayerAlive(client) && GetClientTeam(client) != GetClientTeam(entity)) return Plugin_Handled;
	
	return Plugin_Continue; 
} 


void SetCam(int client)
{

    //L4D1
    if(_Game == Engine_Left4Dead)
	{
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDEHUD_CROSSHAIR);
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
	}
	else{
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDEHUD_CROSSHAIR);
	}

}

void ResetCam(int client)
{

    //L4D1
	if(_Game == Engine_Left4Dead)
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDEHUD_CROSSHAIR);
	}
	else{
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDEHUD_CROSSHAIR);
	}


} 


Action ResetCooldown(Handle timer, any client)
{
	CooldownTimers[client] = null;
}

Action Menu_Dance(int client)
{
	Menu menu = new Menu(MenuHandler1);

	char title[65];
	Format(title, sizeof(title), "%T:", "TITLE_MAIM_MENU", client);
	menu.SetTitle(title);	

	AddTranslatedMenuItem(menu, "", "RANDOM_EMOTE", client);
	AddTranslatedMenuItem(menu, "", "RANDOM_DANCE", client);
	AddTranslatedMenuItem(menu, "", "EMOTES_LIST", client);
	AddTranslatedMenuItem(menu, "", "DANCES_LIST", client);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
 
	return Plugin_Handled;
}

int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{		
		case MenuAction_Select:
		{
			int client = param1;
			
			switch (param2)
			{
				case 0: 
				{
					RandomEmote(client);
					Menu_Dance(client);
				}		
				case 1: 
				{
					RandomDance(client);
					Menu_Dance(client);
				}		
				case 2: EmotesMenu(client);
				case 3: DancesMenu(client);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}


Action EmotesMenu(int client)
{
	char sBuffer[32];
	g_cvFlagEmotesMenu.GetString(sBuffer, sizeof(sBuffer));

	if (!CheckAdminFlags(client, ReadFlagString(sBuffer)))
	{
		CPrintToChat(client, "%t", "NO_EMOTES_ACCESS_FLAG");
		return Plugin_Handled;
	}
	Menu menu = new Menu(MenuHandlerEmotes);
	
	char title[65];
	Format(title, sizeof(title), "%T:", "TITLE_EMOTES_MENU", client);
	menu.SetTitle(title);	

	AddTranslatedMenuItem(menu, "1", "Emote_Fonzie_Pistol", client);
	AddTranslatedMenuItem(menu, "2", "Emote_Bring_It_On", client);
	AddTranslatedMenuItem(menu, "3", "Emote_ThumbsDown", client);
	AddTranslatedMenuItem(menu, "4", "Emote_ThumbsUp", client);
	AddTranslatedMenuItem(menu, "5", "Emote_Celebration_Loop", client);
	AddTranslatedMenuItem(menu, "6", "Emote_BlowKiss", client);
	AddTranslatedMenuItem(menu, "7", "Emote_Calculated", client);
	AddTranslatedMenuItem(menu, "8", "Emote_Confused", client);	
	AddTranslatedMenuItem(menu, "9", "Emote_Chug", client);
	AddTranslatedMenuItem(menu, "10", "Emote_Cry", client);
	AddTranslatedMenuItem(menu, "11", "Emote_DustingOffHands", client);
	AddTranslatedMenuItem(menu, "12", "Emote_DustOffShoulders", client);	
	AddTranslatedMenuItem(menu, "13", "Emote_Facepalm", client);
	AddTranslatedMenuItem(menu, "14", "Emote_Fishing", client);
	AddTranslatedMenuItem(menu, "15", "Emote_Flex", client);
	AddTranslatedMenuItem(menu, "16", "Emote_golfclap", client);	
	AddTranslatedMenuItem(menu, "17", "Emote_HandSignals", client);
	AddTranslatedMenuItem(menu, "18", "Emote_HeelClick", client);
	AddTranslatedMenuItem(menu, "19", "Emote_Hotstuff", client);
	AddTranslatedMenuItem(menu, "20", "Emote_IBreakYou", client);	
	AddTranslatedMenuItem(menu, "21", "Emote_IHeartYou", client);
	AddTranslatedMenuItem(menu, "22", "Emote_Kung-Fu_Salute", client);
	AddTranslatedMenuItem(menu, "23", "Emote_Laugh", client);
	AddTranslatedMenuItem(menu, "24", "Emote_Luchador", client);	
	AddTranslatedMenuItem(menu, "25", "Emote_Make_It_Rain", client);
	AddTranslatedMenuItem(menu, "26", "Emote_NotToday", client);
	AddTranslatedMenuItem(menu, "27", "Emote_RockPaperScissor_Paper", client);
	AddTranslatedMenuItem(menu, "28", "Emote_RockPaperScissor_Rock", client);	
	AddTranslatedMenuItem(menu, "29", "Emote_RockPaperScissor_Scissor", client);
	AddTranslatedMenuItem(menu, "30", "Emote_Salt", client);
	AddTranslatedMenuItem(menu, "31", "Emote_Salute", client);
	AddTranslatedMenuItem(menu, "32", "Emote_SmoothDrive", client);	
	AddTranslatedMenuItem(menu, "33", "Emote_Snap", client);
	AddTranslatedMenuItem(menu, "34", "Emote_StageBow", client);
	AddTranslatedMenuItem(menu, "35", "Emote_Wave2", client);
	AddTranslatedMenuItem(menu, "36", "Emote_Yeet", client);

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
 
	return Plugin_Handled;
}

int MenuHandlerEmotes(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{		
		case MenuAction_Select:
		{
			char info[16];
			if(menu.GetItem(param2, info, sizeof(info)))
			{
				int iParam2 = StringToInt(info);

				switch (iParam2)
				{
					case 1:
					CreateEmote(client, "Emote_Fonzie_Pistol", "none", "", false);
					case 2:
					CreateEmote(client, "Emote_Bring_It_On", "none", "", false);
					case 3:
					CreateEmote(client, "Emote_ThumbsDown", "none", "", false);
					case 4:
					CreateEmote(client, "Emote_ThumbsUp", "none", "", false);
					case 5:
					CreateEmote(client, "Emote_Celebration_Loop", "", "", false);
					case 6:
					CreateEmote(client, "Emote_BlowKiss", "none", "", false);
					case 7:
					CreateEmote(client, "Emote_Calculated", "none", "", false);
					case 8:
					CreateEmote(client, "Emote_Confused", "none", "", false);
					case 9:
					CreateEmote(client, "Emote_Chug", "none", "", false);
					case 10:
					CreateEmote(client, "Emote_Cry", "none", "emote_cry", false);
					case 11:
					CreateEmote(client, "Emote_DustingOffHands", "none", "athena_emote_bandofthefort_music", true);
					case 12:
					CreateEmote(client, "Emote_DustOffShoulders", "none", "athena_emote_hot_music", true);
					case 13:
					CreateEmote(client, "Emote_Facepalm", "none", "athena_emote_facepalm_foley_01", false);
					case 14:
					CreateEmote(client, "Emote_Fishing", "none", "Athena_Emotes_OnTheHook_02", false);
					case 15:
					CreateEmote(client, "Emote_Flex", "none", "", false);
					case 16:
					CreateEmote(client, "Emote_golfclap", "none", "", false);
					case 17:
					CreateEmote(client, "Emote_HandSignals", "none", "", false);
					case 18:
					CreateEmote(client, "Emote_HeelClick", "none", "Emote_HeelClick", false);
					case 19:
					CreateEmote(client, "Emote_Hotstuff", "none", "Emote_Hotstuff", false);	
					case 20:
					CreateEmote(client, "Emote_IBreakYou", "none", "", false);	
					case 21:
					CreateEmote(client, "Emote_IHeartYou", "none", "", false);
					case 22:
					CreateEmote(client, "Emote_Kung-Fu_Salute", "none", "", false);
					case 23:
					CreateEmote(client, "Emote_Laugh", "Emote_Laugh_CT", "emote_laugh_01.mp3", false);		
					case 24:
					CreateEmote(client, "Emote_Luchador", "none", "Emote_Luchador", false);
					case 25:
					CreateEmote(client, "Emote_Make_It_Rain", "none", "athena_emote_makeitrain_music", false);
					case 26:
					CreateEmote(client, "Emote_NotToday", "none", "", false);	
					case 27:
					CreateEmote(client, "Emote_RockPaperScissor_Paper", "none", "", false);
					case 28:
					CreateEmote(client, "Emote_RockPaperScissor_Rock", "none", "", false);
					case 29:
					CreateEmote(client, "Emote_RockPaperScissor_Scissor", "none", "", false);
					case 30:
					CreateEmote(client, "Emote_Salt", "none", "", false);
					case 31:
					CreateEmote(client, "Emote_Salute", "none", "athena_emote_salute_foley_01", false);
					case 32:
					CreateEmote(client, "Emote_SmoothDrive", "none", "", false);
					case 33:
					CreateEmote(client, "Emote_Snap", "none", "Emote_Snap1", false);
					case 34:
					CreateEmote(client, "Emote_StageBow", "none", "emote_stagebow", false);		
					case 35:
					CreateEmote(client, "Emote_Wave2", "none", "", false);
					case 36:
					CreateEmote(client, "Emote_Yeet", "none", "Emote_Yeet", false);				
					
				}
			}
			menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_Dance(client);
			}
		}
	}
}

Action DancesMenu(int client)
{
	char sBuffer[32];
	g_cvFlagDancesMenu.GetString(sBuffer, sizeof(sBuffer));

	if (!CheckAdminFlags(client, ReadFlagString(sBuffer)))
	{
		CPrintToChat(client, "%t", "NO_DANCES_ACCESS_FLAG");
		return Plugin_Handled;
	}
	Menu menu = new Menu(MenuHandlerDances);
	
	char title[65];
	Format(title, sizeof(title), "%T:", "TITLE_DANCES_MENU", client);
	menu.SetTitle(title);	
	
	AddTranslatedMenuItem(menu, "1", "DanceMoves", client);
	AddTranslatedMenuItem(menu, "2", "Emote_Mask_Off_Intro", client);
	AddTranslatedMenuItem(menu, "3", "Emote_Zippy_Dance", client);
	AddTranslatedMenuItem(menu, "4", "ElectroShuffle", client);
	AddTranslatedMenuItem(menu, "5", "Emote_AerobicChamp", client);
	AddTranslatedMenuItem(menu, "6", "Emote_Bendy", client);
	AddTranslatedMenuItem(menu, "7", "Emote_BandOfTheFort", client);
	AddTranslatedMenuItem(menu, "8", "Emote_Boogie_Down_Intro", client);	
	AddTranslatedMenuItem(menu, "9", "Emote_Capoeira", client);
	AddTranslatedMenuItem(menu, "10", "Emote_Charleston", client);
	AddTranslatedMenuItem(menu, "11", "Emote_Chicken", client);
	AddTranslatedMenuItem(menu, "12", "Emote_Dance_NoBones", client);	
	AddTranslatedMenuItem(menu, "13", "Emote_Dance_Shoot", client);
	AddTranslatedMenuItem(menu, "14", "Emote_Dance_SwipeIt", client);
	AddTranslatedMenuItem(menu, "15", "Emote_Dance_Disco_T3", client);
	AddTranslatedMenuItem(menu, "16", "Emote_DG_Disco", client);	
	AddTranslatedMenuItem(menu, "17", "Emote_Dance_Worm", client);
	AddTranslatedMenuItem(menu, "18", "Emote_Dance_Loser", client);
	AddTranslatedMenuItem(menu, "19", "Emote_Dance_Breakdance", client);
	AddTranslatedMenuItem(menu, "20", "Emote_Dance_Pump", client);	
	AddTranslatedMenuItem(menu, "21", "Emote_Dance_RideThePony", client);
	AddTranslatedMenuItem(menu, "22", "Emote_Dab", client);
	AddTranslatedMenuItem(menu, "23", "Emote_EasternBloc_Start", client);
	AddTranslatedMenuItem(menu, "24", "Emote_FancyFeet", client);	
	AddTranslatedMenuItem(menu, "25", "Emote_FlossDance", client);
	AddTranslatedMenuItem(menu, "26", "Emote_FlippnSexy", client);
	AddTranslatedMenuItem(menu, "27", "Emote_Fresh", client);
	AddTranslatedMenuItem(menu, "28", "Emote_GrooveJam", client);	
	AddTranslatedMenuItem(menu, "29", "Emote_guitar", client);
	AddTranslatedMenuItem(menu, "30", "Emote_Hillbilly_Shuffle_Intro", client);
	AddTranslatedMenuItem(menu, "31", "Emote_Hiphop_01", client);
	AddTranslatedMenuItem(menu, "32", "Emote_Hula_Start", client);	
	AddTranslatedMenuItem(menu, "33", "Emote_InfiniDab_Intro", client);
	AddTranslatedMenuItem(menu, "34", "Emote_Intensity_Start", client);
	AddTranslatedMenuItem(menu, "35", "Emote_IrishJig_Start", client);
	AddTranslatedMenuItem(menu, "36", "Emote_KoreanEagle", client);	
	AddTranslatedMenuItem(menu, "37", "Emote_Kpop_02", client);
	AddTranslatedMenuItem(menu, "38", "Emote_LivingLarge", client);
	AddTranslatedMenuItem(menu, "39", "Emote_Maracas", client);
	AddTranslatedMenuItem(menu, "40", "Emote_PopLock", client);
	AddTranslatedMenuItem(menu, "41", "Emote_PopRock", client);
	AddTranslatedMenuItem(menu, "42", "Emote_RobotDance", client);
	AddTranslatedMenuItem(menu, "43", "Emote_T-Rex", client);	
	AddTranslatedMenuItem(menu, "44", "Emote_TechnoZombie", client);
	AddTranslatedMenuItem(menu, "45", "Emote_Twist", client);
	AddTranslatedMenuItem(menu, "46", "Emote_WarehouseDance_Start", client);
	AddTranslatedMenuItem(menu, "47", "Emote_Wiggle", client);
	AddTranslatedMenuItem(menu, "48", "Emote_Youre_Awesome", client);		

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
 
	return Plugin_Handled;
}

int MenuHandlerDances(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{		
		case MenuAction_Select:
		{
			char info[16];
			if(menu.GetItem(param2, info, sizeof(info)))
			{
				int iParam2 = StringToInt(info);

				switch (iParam2)
				{
					case 1:
					CreateEmote(client, "DanceMoves", "none", "ninja_dance_01", false);
					case 2:
					CreateEmote(client, "Emote_Mask_Off_Intro", "Emote_Mask_Off_Loop", "Hip_Hop_Good_Vibes_Mix_01_Loop", true);					
					case 3:
					CreateEmote(client, "Emote_Zippy_Dance", "none", "emote_zippy_A", true);
					case 4:
					CreateEmote(client, "ElectroShuffle", "none", "athena_emote_electroshuffle_music", true);
					case 5:
					CreateEmote(client, "Emote_AerobicChamp", "none", "emote_aerobics_01", true);
					case 6:
					CreateEmote(client, "Emote_Bendy", "none", "athena_music_emotes_bendy", true);
					case 7:
					CreateEmote(client, "Emote_BandOfTheFort", "none", "athena_emote_bandofthefort_music", true);	
					case 8:
					CreateEmote(client, "Emote_Boogie_Down_Intro", "Emote_Boogie_Down", "emote_boogiedown", true);	
					case 9:
					CreateEmote(client, "Emote_Capoeira", "none", "emote_capoeira", false);
					case 10:
					CreateEmote(client, "Emote_Charleston", "none", "athena_emote_flapper_music", true);
					case 11:
					CreateEmote(client, "Emote_Chicken", "none", "athena_emote_chicken_foley_01", true);
					case 12:
					CreateEmote(client, "Emote_Dance_NoBones", "none", "athena_emote_music_boneless", true);
					case 13:
					CreateEmote(client, "Emote_Dance_Shoot", "none", "athena_emotes_music_shoot_v7", true);
					case 14:
					CreateEmote(client, "Emote_Dance_SwipeIt", "none", "Athena_Emotes_Music_SwipeIt", true);
					case 15:
					CreateEmote(client, "Emote_Dance_Disco_T3", "none", "athena_emote_disco", true);
					case 16:
					CreateEmote(client, "Emote_DG_Disco", "none", "athena_emote_disco", true); 					
					case 17:
					CreateEmote(client, "Emote_Dance_Worm", "none", "athena_emote_worm_music", false);
					case 18:
					CreateEmote(client, "Emote_Dance_Loser", "Emote_Dance_Loser_CT", "athena_music_emotes_takethel", true);
					case 19:
					CreateEmote(client, "Emote_Dance_Breakdance", "none", "athena_emote_breakdance_music", false);
					case 20:
					CreateEmote(client, "Emote_Dance_Pump", "none", "Emote_Dance_Pump", true);
					case 21:
					CreateEmote(client, "Emote_Dance_RideThePony", "none", "athena_emote_ridethepony_music_01", false);
					case 22:
					CreateEmote(client, "Emote_Dab", "none", "", false);
					case 23:
					CreateEmote(client, "Emote_EasternBloc_Start", "Emote_EasternBloc", "eastern_bloc_musc_setup_d", true);
					case 24:
					CreateEmote(client, "Emote_FancyFeet", "Emote_FancyFeet_CT", "athena_emotes_lankylegs_loop_02", true); 
					case 25:
					CreateEmote(client, "Emote_FlossDance", "none", "athena_emote_floss_music", true);
					case 26:
					CreateEmote(client, "Emote_FlippnSexy", "none", "Emote_FlippnSexy", false);
					case 27:
					CreateEmote(client, "Emote_Fresh", "none", "athena_emote_fresh_music", true);
					case 28:
					CreateEmote(client, "Emote_GrooveJam", "none", "emote_groove_jam_a", true);	
					case 29:
					CreateEmote(client, "Emote_guitar", "none", "br_emote_shred_guitar_mix_03_loop", true);	
					case 30:
					CreateEmote(client, "Emote_Hillbilly_Shuffle_Intro", "Emote_Hillbilly_Shuffle", "Emote_Hillbilly_Shuffle", true); 
					case 31:
					CreateEmote(client, "Emote_Hiphop_01", "Emote_Hip_Hop", "s5_hiphop_breakin_132bmp_loop", true);	
					case 32:
					CreateEmote(client, "Emote_Hula_Start", "Emote_Hula", "emote_hula_01", true);
					case 33:
					CreateEmote(client, "Emote_InfiniDab_Intro", "Emote_InfiniDab_Loop", "athena_emote_infinidab", true);	
					case 34:
					CreateEmote(client, "Emote_Intensity_Start", "Emote_Intensity_Loop", "emote_Intensity", true);
					case 35:
					CreateEmote(client, "Emote_IrishJig_Start", "Emote_IrishJig", "emote_irish_jig_foley_music_loop", true);
					case 36:
					CreateEmote(client, "Emote_KoreanEagle", "none", "Athena_Music_Emotes_KoreanEagle", true);
					case 37:
					CreateEmote(client, "Emote_Kpop_02", "none", "emote_kpop_01", true);	
					case 38:
					CreateEmote(client, "Emote_LivingLarge", "none", "emote_LivingLarge_A", true);	
					case 39:
					CreateEmote(client, "Emote_Maracas", "none", "emote_samba_new_B", true);
					case 40:
					CreateEmote(client, "Emote_PopLock", "none", "Athena_Emote_PopLock", true);
					case 41:
					CreateEmote(client, "Emote_PopRock", "none", "Emote_PopRock_01", true);		
					case 42:
					CreateEmote(client, "Emote_RobotDance", "none", "athena_emote_robot_music", true);	
					case 43:
					CreateEmote(client, "Emote_T-Rex", "none", "Emote_Dino_Complete", false);
					case 44:
					CreateEmote(client, "Emote_TechnoZombie", "none", "athena_emote_founders_music", true);		
					case 45:
					CreateEmote(client, "Emote_Twist", "none", "athena_emotes_music_twist", true);
					case 46:
					CreateEmote(client, "Emote_WarehouseDance_Start", "Emote_WarehouseDance_Loop", "Emote_Warehouse", true);
					case 47:
					CreateEmote(client, "Emote_Wiggle", "none", "Wiggle_Music_Loop", true);
					case 48:
					CreateEmote(client, "Emote_Youre_Awesome", "none", "youre_awesome_emote_music", false);	
				}
			}
			menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_Dance(client);
			}
		}
	}
}

Action RandomEmote(int i)
{
					char sBuffer[32];
					g_cvFlagEmotesMenu.GetString(sBuffer, sizeof(sBuffer));

					if (!CheckAdminFlags(i, ReadFlagString(sBuffer)))
					{
						CPrintToChat(i, "%t", "NO_EMOTES_ACCESS_FLAG");
						return;
					}
					
					int number = GetRandomInt(1, 36);
					
					switch (number)
					{
						case 1:
						CreateEmote(i, "Emote_Fonzie_Pistol", "none", "", false);
						case 2:
						CreateEmote(i, "Emote_Bring_It_On", "none", "", false);
						case 3:
						CreateEmote(i, "Emote_ThumbsDown", "none", "", false);
						case 4:
						CreateEmote(i, "Emote_ThumbsUp", "none", "", false);
						case 5:
						CreateEmote(i, "Emote_Celebration_Loop", "", "", false);
						case 6:
						CreateEmote(i, "Emote_BlowKiss", "none", "", false);
						case 7:
						CreateEmote(i, "Emote_Calculated", "none", "", false);
						case 8:
						CreateEmote(i, "Emote_Confused", "none", "", false);
						case 9:
						CreateEmote(i, "Emote_Chug", "none", "", false);
						case 10:
						CreateEmote(i, "Emote_Cry", "none", "emote_cry", false);
						case 11:
						CreateEmote(i, "Emote_DustingOffHands", "none", "athena_emote_bandofthefort_music", true);
						case 12:
						CreateEmote(i, "Emote_DustOffShoulders", "none", "athena_emote_hot_music", true);
						case 13:
						CreateEmote(i, "Emote_Facepalm", "none", "athena_emote_facepalm_foley_01", false);
						case 14:
						CreateEmote(i, "Emote_Fishing", "none", "Athena_Emotes_OnTheHook_02", false);
						case 15:
						CreateEmote(i, "Emote_Flex", "none", "", false);
						case 16:
						CreateEmote(i, "Emote_golfclap", "none", "", false);
						case 17:
						CreateEmote(i, "Emote_HandSignals", "none", "", false);
						case 18:
						CreateEmote(i, "Emote_HeelClick", "none", "Emote_HeelClick", false);
						case 19:
						CreateEmote(i, "Emote_Hotstuff", "none", "Emote_Hotstuff", false);	
						case 20:
						CreateEmote(i, "Emote_IBreakYou", "none", "", false);	
						case 21:
						CreateEmote(i, "Emote_IHeartYou", "none", "", false);
						case 22:
						CreateEmote(i, "Emote_Kung-Fu_Salute", "none", "", false);
						case 23:
						CreateEmote(i, "Emote_Laugh", "Emote_Laugh_CT", "emote_laugh_01.mp3", false);		
						case 24:
						CreateEmote(i, "Emote_Luchador", "none", "Emote_Luchador", false);
						case 25:
						CreateEmote(i, "Emote_Make_It_Rain", "none", "athena_emote_makeitrain_music", false);
						case 26:
						CreateEmote(i, "Emote_NotToday", "none", "", false);	
						case 27:
						CreateEmote(i, "Emote_RockPaperScissor_Paper", "none", "", false);
						case 28:
						CreateEmote(i, "Emote_RockPaperScissor_Rock", "none", "", false);
						case 29:
						CreateEmote(i, "Emote_RockPaperScissor_Scissor", "none", "", false);
						case 30:
						CreateEmote(i, "Emote_Salt", "none", "", false);
						case 31:
						CreateEmote(i, "Emote_Salute", "none", "athena_emote_salute_foley_01", false);
						case 32:
						CreateEmote(i, "Emote_SmoothDrive", "none", "", false);
						case 33:
						CreateEmote(i, "Emote_Snap", "none", "Emote_Snap1", false);
						case 34:
						CreateEmote(i, "Emote_StageBow", "none", "emote_stagebow", false);		
						case 35:
						CreateEmote(i, "Emote_Wave2", "none", "", false);
						case 36:
						CreateEmote(i, "Emote_Yeet", "none", "Emote_Yeet", false);	
					}	

}

Action RandomDance(int i)
{
					char sBuffer[32];
					g_cvFlagDancesMenu.GetString(sBuffer, sizeof(sBuffer));

					if (!CheckAdminFlags(i, ReadFlagString(sBuffer)))
					{
						CPrintToChat(i, "%t", "NO_DANCES_ACCESS_FLAG");
						return;
					}
					int number = GetRandomInt(1, 48);
					
					switch (number)
					{
						case 1:
						CreateEmote(i, "DanceMoves", "none", "ninja_dance_01", false);
						case 2:
						CreateEmote(i, "Emote_Mask_Off_Intro", "Emote_Mask_Off_Loop", "Hip_Hop_Good_Vibes_Mix_01_Loop", true);						
						case 3:
						CreateEmote(i, "Emote_Zippy_Dance", "none", "emote_zippy_A", true);
						case 4:
						CreateEmote(i, "ElectroShuffle", "none", "athena_emote_electroshuffle_music", true);
						case 5:
						CreateEmote(i, "Emote_AerobicChamp", "none", "emote_aerobics_01", true);
						case 6:
						CreateEmote(i, "Emote_Bendy", "none", "athena_music_emotes_bendy", true);
						case 7:
						CreateEmote(i, "Emote_BandOfTheFort", "none", "athena_emote_bandofthefort_music", true);	
						case 8:
						CreateEmote(i, "Emote_Boogie_Down_Intro", "Emote_Boogie_Down", "emote_boogiedown", true);	
						case 9:
						CreateEmote(i, "Emote_Capoeira", "none", "emote_capoeira", false);
						case 10:
						CreateEmote(i, "Emote_Charleston", "none", "athena_emote_flapper_music", true);
						case 11:
						CreateEmote(i, "Emote_Chicken", "none", "athena_emote_chicken_foley_01", true);
						case 12:
						CreateEmote(i, "Emote_Dance_NoBones", "none", "athena_emote_music_boneless", true);
						case 13:
						CreateEmote(i, "Emote_Dance_Shoot", "none", "athena_emotes_music_shoot_v7", true);
						case 14:
						CreateEmote(i, "Emote_Dance_SwipeIt", "none", "Athena_Emotes_Music_SwipeIt", true);
						case 15:
						CreateEmote(i, "Emote_Dance_Disco_T3", "none", "athena_emote_disco", true);
						case 16:
						CreateEmote(i, "Emote_DG_Disco", "none", "athena_emote_disco", true); 					
						case 17:
						CreateEmote(i, "Emote_Dance_Worm", "none", "athena_emote_worm_music", false);
						case 18:
						CreateEmote(i, "Emote_Dance_Loser", "Emote_Dance_Loser_CT", "athena_music_emotes_takethel", true);
						case 19:
						CreateEmote(i, "Emote_Dance_Breakdance", "none", "athena_emote_breakdance_music", false);
						case 20:
						CreateEmote(i, "Emote_Dance_Pump", "none", "Emote_Dance_Pump", true);
						case 21:
						CreateEmote(i, "Emote_Dance_RideThePony", "none", "athena_emote_ridethepony_music_01", false);
						case 22:
						CreateEmote(i, "Emote_Dab", "none", "", false);
						case 23:
						CreateEmote(i, "Emote_EasternBloc_Start", "Emote_EasternBloc", "eastern_bloc_musc_setup_d", true);
						case 24:
						CreateEmote(i, "Emote_FancyFeet", "Emote_FancyFeet_CT", "athena_emotes_lankylegs_loop_02", true); 
						case 25:
						CreateEmote(i, "Emote_FlossDance", "none", "athena_emote_floss_music", true);
						case 26:
						CreateEmote(i, "Emote_FlippnSexy", "none", "Emote_FlippnSexy", false);
						case 27:
						CreateEmote(i, "Emote_Fresh", "none", "athena_emote_fresh_music", true);
						case 28:
						CreateEmote(i, "Emote_GrooveJam", "none", "emote_groove_jam_a", true);	
						case 29:
						CreateEmote(i, "Emote_guitar", "none", "br_emote_shred_guitar_mix_03_loop", true);	
						case 30:
						CreateEmote(i, "Emote_Hillbilly_Shuffle_Intro", "Emote_Hillbilly_Shuffle", "Emote_Hillbilly_Shuffle", true); 
						case 31:
						CreateEmote(i, "Emote_Hiphop_01", "Emote_Hip_Hop", "s5_hiphop_breakin_132bmp_loop", true);	
						case 32:
						CreateEmote(i, "Emote_Hula_Start", "Emote_Hula", "emote_hula_01", true);
						case 33:
						CreateEmote(i, "Emote_InfiniDab_Intro", "Emote_InfiniDab_Loop", "athena_emote_infinidab", true);	
						case 34:
						CreateEmote(i, "Emote_Intensity_Start", "Emote_Intensity_Loop", "emote_Intensity", true);
						case 35:
						CreateEmote(i, "Emote_IrishJig_Start", "Emote_IrishJig", "emote_irish_jig_foley_music_loop", true);
						case 36:
						CreateEmote(i, "Emote_KoreanEagle", "none", "Athena_Music_Emotes_KoreanEagle", true);
						case 37:
						CreateEmote(i, "Emote_Kpop_02", "none", "emote_kpop_01", true);	
						case 38:
						CreateEmote(i, "Emote_LivingLarge", "none", "emote_LivingLarge_A", true);	
						case 39:
						CreateEmote(i, "Emote_Maracas", "none", "emote_samba_new_B", true);
						case 40:
						CreateEmote(i, "Emote_PopLock", "none", "Athena_Emote_PopLock", true);
						case 41:
						CreateEmote(i, "Emote_PopRock", "none", "Emote_PopRock_01", true);		
						case 42:
						CreateEmote(i, "Emote_RobotDance", "none", "athena_emote_robot_music", true);	
						case 43:
						CreateEmote(i, "Emote_T-Rex", "none", "Emote_Dino_Complete", false);
						case 44:
						CreateEmote(i, "Emote_TechnoZombie", "none", "athena_emote_founders_music", true);		
						case 45:
						CreateEmote(i, "Emote_Twist", "none", "athena_emotes_music_twist", true);
						case 46:
						CreateEmote(i, "Emote_WarehouseDance_Start", "Emote_WarehouseDance_Loop", "Emote_Warehouse", true);
						case 47:
						CreateEmote(i, "Emote_Wiggle", "none", "Wiggle_Music_Loop", true);
						case 48:
						CreateEmote(i, "Emote_Youre_Awesome", "none", "youre_awesome_emote_music", false);	
					}	
}


Action Command_Admin_Emotes(int client, int args)
{
	if (args < 1)
	{
		CPrintToChat(client, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");
		return Plugin_Handled;
	}
	
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	int amount=1;
	if (args > 1)
	{
		char arg2[3];
		GetCmdArg(2, arg2, sizeof(arg2));
		if (StringToIntEx(arg2, amount) < 1 || StringToIntEx(arg2, amount) > 86)
		{
			CPrintToChat(client, "%t", "INVALID_EMOTE_ID");
			return Plugin_Handled;
		}
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	
	for (int i = 0; i < target_count; i++)
	{
		PerformEmote(client, target_list[i], amount);
	}	
	
	return Plugin_Handled;
}

void PerformEmote(int client, int target, int amount)
{
		switch (amount)
		{
					case 1:
					CreateEmote(target, "Emote_Fonzie_Pistol", "none", "", false);
					case 2:
					CreateEmote(target, "Emote_Bring_It_On", "none", "", false);
					case 3:
					CreateEmote(target, "Emote_ThumbsDown", "none", "", false);
					case 4:
					CreateEmote(target, "Emote_ThumbsUp", "none", "", false);
					case 5:
					CreateEmote(target, "Emote_Celebration_Loop", "", "", false);
					case 6:
					CreateEmote(target, "Emote_BlowKiss", "none", "", false);
					case 7:
					CreateEmote(target, "Emote_Calculated", "none", "", false);
					case 8:
					CreateEmote(target, "Emote_Confused", "none", "", false);
					case 9:
					CreateEmote(target, "Emote_Chug", "none", "", false);
					case 10:
					CreateEmote(target, "Emote_Cry", "none", "emote_cry", false);
					case 11:
					CreateEmote(target, "Emote_DustingOffHands", "none", "athena_emote_bandofthefort_music", true);
					case 12:
					CreateEmote(target, "Emote_DustOffShoulders", "none", "athena_emote_hot_music", true);
					case 13:
					CreateEmote(target, "Emote_Facepalm", "none", "athena_emote_facepalm_foley_01", false);
					case 14:
					CreateEmote(target, "Emote_Fishing", "none", "Athena_Emotes_OnTheHook_02", false);
					case 15:
					CreateEmote(target, "Emote_Flex", "none", "", false);
					case 16:
					CreateEmote(target, "Emote_golfclap", "none", "", false);
					case 17:
					CreateEmote(target, "Emote_HandSignals", "none", "", false);
					case 18:
					CreateEmote(target, "Emote_HeelClick", "none", "Emote_HeelClick", false);
					case 19:
					CreateEmote(target, "Emote_Hotstuff", "none", "Emote_Hotstuff", false);	
					case 20:
					CreateEmote(target, "Emote_IBreakYou", "none", "", false);	
					case 21:
					CreateEmote(target, "Emote_IHeartYou", "none", "", false);
					case 22:
					CreateEmote(target, "Emote_Kung-Fu_Salute", "none", "", false);
					case 23:
					CreateEmote(target, "Emote_Laugh", "Emote_Laugh_CT", "emote_laugh_01.mp3", false);		
					case 24:
					CreateEmote(target, "Emote_Luchador", "none", "Emote_Luchador", false);
					case 25:
					CreateEmote(target, "Emote_Make_It_Rain", "none", "athena_emote_makeitrain_music", false);
					case 26:
					CreateEmote(target, "Emote_NotToday", "none", "", false);	
					case 27:
					CreateEmote(target, "Emote_RockPaperScissor_Paper", "none", "", false);
					case 28:
					CreateEmote(target, "Emote_RockPaperScissor_Rock", "none", "", false);
					case 29:
					CreateEmote(target, "Emote_RockPaperScissor_Scissor", "none", "", false);
					case 30:
					CreateEmote(target, "Emote_Salt", "none", "", false);
					case 31:
					CreateEmote(target, "Emote_Salute", "none", "athena_emote_salute_foley_01", false);
					case 32:
					CreateEmote(target, "Emote_SmoothDrive", "none", "", false);
					case 33:
					CreateEmote(target, "Emote_Snap", "none", "Emote_Snap1", false);
					case 34:
					CreateEmote(target, "Emote_StageBow", "none", "emote_stagebow", false);			
					case 35:
					CreateEmote(target, "Emote_Wave2", "none", "", false);
					case 36:
					CreateEmote(target, "Emote_Yeet", "none", "Emote_Yeet", false);	
					case 37:
					CreateEmote(target, "DanceMoves", "none", "ninja_dance_01", false);
					case 38:
					CreateEmote(target, "Emote_Mask_Off_Intro", "Emote_Mask_Off_Loop", "Hip_Hop_Good_Vibes_Mix_01_Loop", true);						
					case 39:
					CreateEmote(target, "Emote_Zippy_Dance", "none", "emote_zippy_A", true);
					case 40:
					CreateEmote(target, "ElectroShuffle", "none", "athena_emote_electroshuffle_music", true);
					case 41:
					CreateEmote(target, "Emote_AerobicChamp", "none", "emote_aerobics_01", true);
					case 42:
					CreateEmote(target, "Emote_Bendy", "none", "athena_music_emotes_bendy", true);
					case 43:
					CreateEmote(target, "Emote_BandOfTheFort", "none", "athena_emote_bandofthefort_music", true);	
					case 44:
					CreateEmote(target, "Emote_Boogie_Down_Intro", "Emote_Boogie_Down", "emote_boogiedown", true);	
					case 45:
					CreateEmote(target, "Emote_Capoeira", "none", "emote_capoeira", false);
					case 46:
					CreateEmote(target, "Emote_Charleston", "none", "athena_emote_flapper_music", true);
					case 47:
					CreateEmote(target, "Emote_Chicken", "none", "athena_emote_chicken_foley_01", true);
					case 48:
					CreateEmote(target, "Emote_Dance_NoBones", "none", "athena_emote_music_boneless", true);
					case 49:
					CreateEmote(target, "Emote_Dance_Shoot", "none", "athena_emotes_music_shoot_v7", true);
					case 50:
					CreateEmote(target, "Emote_Dance_SwipeIt", "none", "Athena_Emotes_Music_SwipeIt", true);
					case 51:
					CreateEmote(target, "Emote_Dance_Disco_T3", "none", "athena_emote_disco", true);
					case 52:
					CreateEmote(target, "Emote_DG_Disco", "none", "athena_emote_disco", true); 					
					case 53:
					CreateEmote(target, "Emote_Dance_Worm", "none", "athena_emote_worm_music", false);
					case 54:
					CreateEmote(target, "Emote_Dance_Loser", "Emote_Dance_Loser_CT", "athena_music_emotes_takethel", true);
					case 55:
					CreateEmote(target, "Emote_Dance_Breakdance", "none", "athena_emote_breakdance_music", false);
					case 56:
					CreateEmote(target, "Emote_Dance_Pump", "none", "Emote_Dance_Pump", true);
					case 57:
					CreateEmote(target, "Emote_Dance_RideThePony", "none", "athena_emote_ridethepony_music_01", false);
					case 58:
					CreateEmote(target, "Emote_Dab", "none", "", false);
					case 59:
					CreateEmote(target, "Emote_EasternBloc_Start", "Emote_EasternBloc", "eastern_bloc_musc_setup_d", true);
					case 60:
					CreateEmote(target, "Emote_FancyFeet", "Emote_FancyFeet_CT", "athena_emotes_lankylegs_loop_02", true); 
					case 61:
					CreateEmote(target, "Emote_FlossDance", "none", "athena_emote_floss_music", true);
					case 62:
					CreateEmote(target, "Emote_FlippnSexy", "none", "Emote_FlippnSexy", false);
					case 63:
					CreateEmote(target, "Emote_Fresh", "none", "athena_emote_fresh_music", true);
					case 64:
					CreateEmote(target, "Emote_GrooveJam", "none", "emote_groove_jam_a", true);	
					case 65:
					CreateEmote(target, "Emote_guitar", "none", "br_emote_shred_guitar_mix_03_loop", true);	
					case 66:
					CreateEmote(target, "Emote_Hillbilly_Shuffle_Intro", "Emote_Hillbilly_Shuffle", "Emote_Hillbilly_Shuffle", true); 
					case 67:
					CreateEmote(target, "Emote_Hiphop_01", "Emote_Hip_Hop", "s5_hiphop_breakin_132bmp_loop", true);	
					case 68:
					CreateEmote(target, "Emote_Hula_Start", "Emote_Hula", "emote_hula_01", true);
					case 69:
					CreateEmote(target, "Emote_InfiniDab_Intro", "Emote_InfiniDab_Loop", "athena_emote_infinidab", true);	
					case 70:
					CreateEmote(target, "Emote_Intensity_Start", "Emote_Intensity_Loop", "emote_Intensity", true);
					case 71:
					CreateEmote(target, "Emote_IrishJig_Start", "Emote_IrishJig", "emote_irish_jig_foley_music_loop", true);
					case 72:
					CreateEmote(target, "Emote_KoreanEagle", "none", "Athena_Music_Emotes_KoreanEagle", true);
					case 73:
					CreateEmote(target, "Emote_Kpop_02", "none", "emote_kpop_01", true);	
					case 74:
					CreateEmote(target, "Emote_LivingLarge", "none", "emote_LivingLarge_A", true);	
					case 75:
					CreateEmote(target, "Emote_Maracas", "none", "emote_samba_new_B", true);
					case 76:
					CreateEmote(target, "Emote_PopLock", "none", "Athena_Emote_PopLock", true);
					case 77:
					CreateEmote(target, "Emote_PopRock", "none", "Emote_PopRock_01", true);		
					case 78:
					CreateEmote(target, "Emote_RobotDance", "none", "athena_emote_robot_music", true);	
					case 79:
					CreateEmote(target, "Emote_T-Rex", "none", "Emote_Dino_Complete", false);
					case 80:
					CreateEmote(target, "Emote_TechnoZombie", "none", "athena_emote_founders_music", true);		
					case 81:
					CreateEmote(target, "Emote_Twist", "none", "athena_emotes_music_twist", true);
					case 82:
					CreateEmote(target, "Emote_WarehouseDance_Start", "Emote_WarehouseDance_Loop", "Emote_Warehouse", true);
					case 83:
					CreateEmote(target, "Emote_Wiggle", "none", "Wiggle_Music_Loop", true);
					case 84:
					CreateEmote(target, "Emote_Youre_Awesome", "none", "youre_awesome_emote_music", false);						
					default:
					CPrintToChat(client, "%t", "INVALID_EMOTE_ID");
		}
}

void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	/* Find the "Player Commands" category */
	TopMenuObject player_commands = hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		hTopMenu.AddItem("sm_setemotes", AdminMenu_Emotes, player_commands, "sm_setemotes", ADMFLAG_SLAY);
	}
}

void AdminMenu_Emotes(TopMenu topmenu, 
					  TopMenuAction action,
					  TopMenuObject object_id,
					  int param,
					  char[] buffer,
					  int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "EMOTE_PLAYER", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayEmotePlayersMenu(param);
	}
}

void DisplayEmotePlayersMenu(int client)
{
	Menu menu = new Menu(MenuHandler_EmotePlayers);
	
	char title[65];
	Format(title, sizeof(title), "%T:", "EMOTE_PLAYER", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	AddTargetsToMenu(menu, client, true, true);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_EmotePlayers(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu)
		{
			hTopMenu.Display(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int userid, target;
		
		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			CPrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			CPrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			g_EmotesTarget[param1] = userid;
			DisplayEmotesAmountMenu(param1);
			return;	// Return, because we went to a new menu and don't want the re-draw to occur.
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayEmotePlayersMenu(param1);
		}
	}
	
	return;
}

void DisplayEmotesAmountMenu(int client)
{
	Menu menu = new Menu(MenuHandler_EmotesAmount);
	
	char title[65];
	Format(title, sizeof(title), "%T: %N", "SELECT_EMOTE", client, GetClientOfUserId(g_EmotesTarget[client]));
	menu.SetTitle(title);
	menu.ExitBackButton = true;

	AddTranslatedMenuItem(menu, "1", "Emote_Fonzie_Pistol", client);
	AddTranslatedMenuItem(menu, "2", "Emote_Bring_It_On", client);
	AddTranslatedMenuItem(menu, "3", "Emote_ThumbsDown", client);
	AddTranslatedMenuItem(menu, "4", "Emote_ThumbsUp", client);
	AddTranslatedMenuItem(menu, "5", "Emote_Celebration_Loop", client);
	AddTranslatedMenuItem(menu, "6", "Emote_BlowKiss", client);
	AddTranslatedMenuItem(menu, "7", "Emote_Calculated", client);
	AddTranslatedMenuItem(menu, "8", "Emote_Confused", client);	
	AddTranslatedMenuItem(menu, "9", "Emote_Chug", client);
	AddTranslatedMenuItem(menu, "10", "Emote_Cry", client);
	AddTranslatedMenuItem(menu, "11", "Emote_DustingOffHands", client);
	AddTranslatedMenuItem(menu, "12", "Emote_DustOffShoulders", client);	
	AddTranslatedMenuItem(menu, "13", "Emote_Facepalm", client);
	AddTranslatedMenuItem(menu, "14", "Emote_Fishing", client);
	AddTranslatedMenuItem(menu, "15", "Emote_Flex", client);
	AddTranslatedMenuItem(menu, "16", "Emote_golfclap", client);	
	AddTranslatedMenuItem(menu, "17", "Emote_HandSignals", client);
	AddTranslatedMenuItem(menu, "18", "Emote_HeelClick", client);
	AddTranslatedMenuItem(menu, "19", "Emote_Hotstuff", client);
	AddTranslatedMenuItem(menu, "20", "Emote_IBreakYou", client);	
	AddTranslatedMenuItem(menu, "21", "Emote_IHeartYou", client);
	AddTranslatedMenuItem(menu, "22", "Emote_Kung-Fu_Salute", client);
	AddTranslatedMenuItem(menu, "23", "Emote_Laugh", client);
	AddTranslatedMenuItem(menu, "24", "Emote_Luchador", client);	
	AddTranslatedMenuItem(menu, "25", "Emote_Make_It_Rain", client);
	AddTranslatedMenuItem(menu, "26", "Emote_NotToday", client);
	AddTranslatedMenuItem(menu, "27", "Emote_RockPaperScissor_Paper", client);
	AddTranslatedMenuItem(menu, "28", "Emote_RockPaperScissor_Rock", client);	
	AddTranslatedMenuItem(menu, "29", "Emote_RockPaperScissor_Scissor", client);
	AddTranslatedMenuItem(menu, "30", "Emote_Salt", client);
	AddTranslatedMenuItem(menu, "31", "Emote_Salute", client);
	AddTranslatedMenuItem(menu, "32", "Emote_SmoothDrive", client);	
	AddTranslatedMenuItem(menu, "33", "Emote_Snap", client);
	AddTranslatedMenuItem(menu, "34", "Emote_StageBow", client);	
	AddTranslatedMenuItem(menu, "35", "Emote_Wave2", client);
	AddTranslatedMenuItem(menu, "36", "Emote_Yeet", client);
	AddTranslatedMenuItem(menu, "37", "DanceMoves", client);
	AddTranslatedMenuItem(menu, "38", "Emote_Mask_Off_Intro", client);
	AddTranslatedMenuItem(menu, "39", "Emote_Zippy_Dance", client);
	AddTranslatedMenuItem(menu, "40", "ElectroShuffle", client);
	AddTranslatedMenuItem(menu, "41", "Emote_AerobicChamp", client);
	AddTranslatedMenuItem(menu, "42", "Emote_Bendy", client);
	AddTranslatedMenuItem(menu, "43", "Emote_BandOfTheFort", client);
	AddTranslatedMenuItem(menu, "44", "Emote_Boogie_Down_Intro", client);	
	AddTranslatedMenuItem(menu, "45", "Emote_Capoeira", client);
	AddTranslatedMenuItem(menu, "46", "Emote_Charleston", client);
	AddTranslatedMenuItem(menu, "47", "Emote_Chicken", client);
	AddTranslatedMenuItem(menu, "48", "Emote_Dance_NoBones", client);	
	AddTranslatedMenuItem(menu, "49", "Emote_Dance_Shoot", client);
	AddTranslatedMenuItem(menu, "50", "Emote_Dance_SwipeIt", client);
	AddTranslatedMenuItem(menu, "51", "Emote_Dance_Disco_T3", client);
	AddTranslatedMenuItem(menu, "52", "Emote_DG_Disco", client);	
	AddTranslatedMenuItem(menu, "53", "Emote_Dance_Worm", client);
	AddTranslatedMenuItem(menu, "54", "Emote_Dance_Loser", client);
	AddTranslatedMenuItem(menu, "55", "Emote_Dance_Breakdance", client);
	AddTranslatedMenuItem(menu, "56", "Emote_Dance_Pump", client);	
	AddTranslatedMenuItem(menu, "57", "Emote_Dance_RideThePony", client);
	AddTranslatedMenuItem(menu, "58", "Emote_Dab", client);
	AddTranslatedMenuItem(menu, "59", "Emote_EasternBloc_Start", client);
	AddTranslatedMenuItem(menu, "60", "Emote_FancyFeet", client);	
	AddTranslatedMenuItem(menu, "61", "Emote_FlossDance", client);
	AddTranslatedMenuItem(menu, "62", "Emote_FlippnSexy", client);
	AddTranslatedMenuItem(menu, "63", "Emote_Fresh", client);
	AddTranslatedMenuItem(menu, "64", "Emote_GrooveJam", client);	
	AddTranslatedMenuItem(menu, "65", "Emote_guitar", client);
	AddTranslatedMenuItem(menu, "66", "Emote_Hillbilly_Shuffle_Intro", client);
	AddTranslatedMenuItem(menu, "67", "Emote_Hiphop_01", client);
	AddTranslatedMenuItem(menu, "68", "Emote_Hula_Start", client);	
	AddTranslatedMenuItem(menu, "69", "Emote_InfiniDab_Intro", client);
	AddTranslatedMenuItem(menu, "70", "Emote_Intensity_Start", client);
	AddTranslatedMenuItem(menu, "71", "Emote_IrishJig_Start", client);
	AddTranslatedMenuItem(menu, "72", "Emote_KoreanEagle", client);	
	AddTranslatedMenuItem(menu, "73", "Emote_Kpop_02", client);
	AddTranslatedMenuItem(menu, "74", "Emote_LivingLarge", client);
	AddTranslatedMenuItem(menu, "75", "Emote_Maracas", client);
	AddTranslatedMenuItem(menu, "76", "Emote_PopLock", client);
	AddTranslatedMenuItem(menu, "77", "Emote_PopRock", client);
	AddTranslatedMenuItem(menu, "78", "Emote_RobotDance", client);
	AddTranslatedMenuItem(menu, "79", "Emote_T-Rex", client);	
	AddTranslatedMenuItem(menu, "80", "Emote_TechnoZombie", client);
	AddTranslatedMenuItem(menu, "81", "Emote_Twist", client);
	AddTranslatedMenuItem(menu, "82", "Emote_WarehouseDance_Start", client);
	AddTranslatedMenuItem(menu, "83", "Emote_Wiggle", client);
	AddTranslatedMenuItem(menu, "84", "Emote_Youre_Awesome", client);	
	
	menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_EmotesAmount(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu)
		{
			hTopMenu.Display(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int amount;
		int target;
		
		menu.GetItem(param2, info, sizeof(info));
		amount = StringToInt(info);

		if ((target = GetClientOfUserId(g_EmotesTarget[param1])) == 0)
		{
			CPrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			CPrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			char name[MAX_NAME_LENGTH];
			GetClientName(target, name, sizeof(name));
			
			PerformEmote(param1, target, amount);
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayEmotePlayersMenu(param1);
		}
	}
}

void AddTranslatedMenuItem(Menu menu, const char[] opt, const char[] phrase, int client)
{
	char buffer[128];
	Format(buffer, sizeof(buffer), "%T", phrase, client);
	menu.AddItem(opt, buffer);
}

stock bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}

bool CheckAdminFlags(int client, int iFlag)
{
	int iUserFlags = GetUserFlagBits(client);
	return (iUserFlags & ADMFLAG_ROOT || (iUserFlags & iFlag) == iFlag);
}

int GetEmotePeople()
{
	int count;
	for(int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && g_bClientDancing[i])
			count++;
			
	return count;
}


void CPrintToChat(int client, char[] message, any ...)
{
	static char buffer[256];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 2);
	ReplaceColor(buffer, sizeof(buffer));
	PrintToChat(client, buffer);
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{default}", "\x01", false);
    ReplaceString(message, maxLen, "{darkred}", "\x04", false);
    ReplaceString(message, maxLen, "{olive}", "\x05", false);
}

bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}