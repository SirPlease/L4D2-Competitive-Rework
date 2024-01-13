/*
*	Left 4 DHooks Direct
*	Copyright (C) 2024 Silvers
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



#define PLUGIN_VERSION		"1.142"
#define PLUGIN_VERLONG		1142

#define DEBUG				0
// #define DEBUG			1	// Prints addresses + detour info (only use for debugging, slows server down).

#define DETOUR_ALL			0	// Only enable required detours, for public release.
// #define DETOUR_ALL		1	// Enable all detours, for testing.

#define KILL_VSCRIPT		0	// 0=Keep VScript entity after using for "GetVScriptOutput". 1=Kill the entity after use (more resourceful to keep recreating, use if you're maxing out entities and reaching the limit regularly).

#define ALLOW_UPDATER		1	// 0=Off. 1=Allow the plugin to auto-update using the "Updater" plugin by "GoD-Tony". 2=Allow updating and reloading after update.



/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Left 4 DHooks Direct
*	Author	:	SilverShot
*	Descrp	:	Left 4 Downtown and L4D Direct conversion and merger.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=321696
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

	- See forum thread: https://forums.alliedmods.net/showthread.php?t=321696
	- OR: See the "scripting/l4dd/left4dhooks_changelog.txt" file.

========================================================================================
	To Do:

		Re-write dynamic detour enabler?
			- All working but looks ugly. Could be cleaner?
			- Optional extra-api.ext support

========================================================================================
	Thanks:

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Original Left4Downtown extension:		https://forums.alliedmods.net/showthread.php?t=91132
		"Downtown1" and "XBetaAlpha" - authors of the original Left4Downtown.
		"pRED*" for his TF2 tools code, I looked at it a lot . and for answering questions on IRC
		"Fyren" for being so awesome and inspiring me from his sdktools patch to do custom |this| calls.
		"ivailosp" for providing the Windows addresses that needed to be patched to get player slot unlocking to work.
		"dvander" for making sourcemod and teaching me about the mod r/m bytes.
		"DDRKhat" for letting me use his Linux server to test this.
		"Frustian" for being a champ and poking around random Linux sigs so I could the one native I actually needed.
		"XBetaAlpha" for making this a team effort rather than one guy writing all the code.

*	Original Left4Downtown2 extension:		https://forums.alliedmods.net/showthread.php?t=134032
		"Downtown1" and "XBetaAlpha" - authors of the original Left4Downtown.
		"ProdigySim" - Confogl developer interested in expanding and updating Left4Downtown.
		"AtomicStryker" - Sourcemod plugin developer, and part of the original Left4Downtown team.
		"psychonic" - Resident Sourcemod insider, started Left4Downtown2.
		"asherkin" - Hosting the autobuild server.
		"CanadaRox", "vintik", "rochellecrab", and anyone else who has submitted code in any way.

*	Left 4 Downtown 2 Extension updates:	https://forums.alliedmods.net/showpost.php?p=1970730&postcount=397?p=1970730&postcount=397
		"Visor" for "l4d2_addons_eclipse" cvar and new forwards.

*	Left 4 Downtown 2 Extension updates
		"Attano" for various github commits.

*	Left 4 Downtown 2 Extension updates
		"Accelerator74" for various github commits.

*	"ProdigySim" and the "ConfoglTeam" for "L4D2Direct" plugin:
		https://forums.alliedmods.net/showthread.php?t=180028

*	"raziEiL" for "L4D_Direct Port" offsets and addresses:
		https://github.com/raziEiL/l4d_direct-port

*	"AtomicStryker" and whoever else contributed to "l4d2addresses.txt" gamedata file.

*	"Dragokas" for "String Tables Dumper" some code used to get melee weapon IDs.
		https://forums.alliedmods.net/showthread.php?t=322674

*	"Dysphie" for "ReadMemoryString" function code.

===================================================================================================*/



#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <dhooks>
#include <left4dhooks>

// ====================================================================================================
// UPDATER
#define UPDATE_URL					"https://raw.githubusercontent.com/SilvDev/Left4DHooks/main/sourcemod/updater.txt"

native void Updater_AddPlugin(const char[] url);
// ====================================================================================================



// PROFILER
#if DEBUG
#include <profiler>
Profiler g_vProf;
float g_fProf;
#endif

// NEW SOURCEMOD ONLY
#if SOURCEMOD_V_MINOR < 11
 #error Plugin "Left 4 DHooks" only supports SourceMod version 1.11 and newer
#endif



// Plugin
#define GAMEDATA_1							"left4dhooks.l4d1"
#define GAMEDATA_2							"left4dhooks.l4d2"
#define GAMEDATA_TEMP						"left4dhooks.temp"
#define NATIVE_UNSUPPORTED1					"\n==========\nThis Native is only supported in L4D1.\nPlease fix the code to avoid calling this native from L4D2.\n=========="
#define NATIVE_UNSUPPORTED2					"\n==========\nThis Native is only supported in L4D2.\nPlease fix the code to avoid calling this native from L4D1.\n=========="
#define NATIVE_TOO_EARLY					"\n==========\nNative '%s' should not be used before OnMapStart, please report to 3rd party plugin author.\n=========="
#define COMPILE_FROM_MAIN					true



// Tank animations
#define L4D2_ACT_HULK_THROW					761
#define L4D2_ACT_TANK_OVERHEAD_THROW		762
#define L4D2_ACT_HULK_ATTACK_LOW			763
#define L4D2_ACT_TERROR_ATTACK_MOVING		790
#define L4D2_SEQ_PUNCH_UPPERCUT				40
#define L4D2_SEQ_PUNCH_RIGHT_HOOK			43
#define L4D2_SEQ_PUNCH_LEFT_HOOK			45
#define L4D2_SEQ_PUNCH_POUND_GROUND1		46
#define L4D2_SEQ_PUNCH_POUND_GROUND2		47
#define L4D2_SEQ_THROW_UNDERCUT				48
#define L4D2_SEQ_THROW_1HAND_OVER			49
#define L4D2_SEQ_THROW_FROM_HIP				50
#define L4D2_SEQ_THROW_2HAND_OVER			51

#define L4D1_ACT_HULK_THROW					1254
#define L4D1_ACT_TANK_OVERHEAD_THROW		1255
#define L4D1_ACT_HULK_ATTACK_LOW			1256
#define L4D1_ACT_TERROR_ATTACK_MOVING		1282
#define L4D1_SEQ_PUNCH_UPPERCUT				38
#define L4D1_SEQ_PUNCH_RIGHT_HOOK			41
#define L4D1_SEQ_PUNCH_LEFT_HOOK			43
#define L4D1_SEQ_PUNCH_POUND_GROUND1		44
#define L4D1_SEQ_PUNCH_POUND_GROUND2		45
#define L4D1_SEQ_THROW_UNDERCUT				46
#define L4D1_SEQ_THROW_1HAND_OVER			47
#define L4D1_SEQ_THROW_FROM_HIP				48
#define L4D1_SEQ_THROW_2HAND_OVER			49



// Dissolver
#define SPRITE_GLOW							"sprites/blueglow1.vmt"

// GasCan model for damage hook
#define MODEL_GASCAN						"models/props_junk/gascan001a.mdl"

// PipeBomb particles
#define PARTICLE_FUSE						"weapon_pipebomb_fuse"
#define PARTICLE_LIGHT						"weapon_pipebomb_blinking_light"



// Precache models for spawning
static const char g_sModels1[][] =
{
	"models/infected/witch.mdl",
	"models/infected/hulk.mdl",
	"models/infected/smoker.mdl",
	"models/infected/boomer.mdl",
	"models/infected/hunter.mdl"
};

static const char g_sModels2[][] =
{
	"models/infected/witch_bride.mdl",
	"models/infected/spitter.mdl",
	"models/infected/jockey.mdl",
	"models/infected/charger.mdl"
};



// Dynamic Detours:
#define MAX_FWD_LEN							64		// Maximum string length of forward and signature names, used for ArrayList

// ToDo: When using extra-api.ext (or hopefully one day native SM forwards), g_aDetoursHooked will store the number of plugins using each forward
// so we can disable when the value is 0 and not have to check all plugins just to determine if still required
ArrayList g_aDetoursHooked;					// Identifies if the detour hook is enabled or disabled
ArrayList g_aDetourHandles;					// Stores detour handles to enable/disable as required
ArrayList g_aGameDataSigs;					// Stores Signature names
ArrayList g_aForwardNames;					// Stores Forward names
ArrayList g_aUseLastIndex;					// Use last index
ArrayList g_aForwardIndex;					// Stores Detour indexes
ArrayList g_aForceDetours;					// Determines if a detour should be forced on without any forward using it
ArrayList g_aDetourHookIDsPre;				// Hook IDs created by DynamicHook type detours
ArrayList g_aDetourHookIDsPost;				// Hook IDs created by DynamicHook type detours
int g_iSmallIndex;							// Index for each detour while created
int g_iLargeIndex;							// Index for each detour while created
bool g_bCreatedDetours;						// To determine first time creation of detours, or if enabling or disabling
float g_fLoadTime;							// When the plugin was loaded, to ignore when "AP_OnPluginUpdate" fires
Handle g_hThisPlugin;						// Ignore checking this plugin
GameData g_hGameData;						// GameData file - to speed up loading
GameData g_hTempGameData;					// TempGameData file
int g_iScriptVMDetourIndex;
float g_fCvar_Adrenaline, g_fCvar_PillsDecay;
int g_iCvar_AddonsEclipse, g_iCvar_RescueDeadTime;



// Animation Hook
int g_iAnimationDetourIndex;
bool g_bAnimationRemoveHook;
ArrayList g_iAnimationHookedClients;
ArrayList g_iAnimationHookedPlugins;
ArrayList g_hAnimationActivityList;
PrivateForward g_hAnimationCallbackPre[MAXPLAYERS+1];
PrivateForward g_hAnimationCallbackPost[MAXPLAYERS+1];



// Weapons
StringMap g_aWeaponPtrs;					// Stores weapon pointers to retrieve CCSWeaponInfo and CTerrorWeaponInfo data
StringMap g_aWeaponIDs;						// Store weapon IDs to get above pointers
StringMap g_aMeleeIDs;						// Store melee IDs
ArrayList g_aMeleePtrs;						// Stores melee pointers



// Offsets - Addons Eclipse
int g_iOff_AddonEclipse1;
int g_iOff_AddonEclipse2;
int g_iOff_VanillaModeOffset;
Address g_pVanillaModeAddress;

// Various offsets
int g_iOff_LobbyReservation;
int g_iOff_VersusStartTimer;
int g_iOff_m_rescueCheckTimer;
int g_iOff_m_iszScriptId;
int g_iOff_m_flBecomeGhostAt;
int g_iOff_MobSpawnTimer;
int g_iOff_m_iSetupNotifyTime;
int g_iOff_VersusMaxCompletionScore;
int g_iOff_OnBeginRoundSetupTime;
int g_iOff_m_iTankCount;
int g_iOff_m_iWitchCount;
int g_iOff_m_PlayerAnimState;
int g_iOff_m_eCurrentMainSequenceActivity;
int g_iOff_m_bIsCustomSequence;
int g_iOff_m_iCampaignScores;
int g_iOff_m_fTankSpawnFlowPercent;
int g_iOff_m_fWitchSpawnFlowPercent;
int g_iOff_m_iTankPassedCount;
int g_iOff_m_bTankThisRound;
int g_iOff_m_bWitchThisRound;
int g_iOff_OvertimeGraceTimer;
int g_iOff_InvulnerabilityTimer;
int g_iOff_m_iTankTickets;
int g_iOff_m_iSurvivorHealthBonus;
int g_iOff_m_bFirstSurvivorLeftStartArea;
// int g_iOff_m_iShovePenalty;
// int g_iOff_m_fNextShoveTime;
int g_iOff_m_preIncapacitatedHealth;
int g_iOff_m_preIncapacitatedHealthBuffer;
int g_iOff_m_maxFlames;
int g_iOff_m_flow;
int g_iOff_m_PendingMobCount;
int g_iOff_m_nFirstClassIndex;
int g_iOff_m_fMapMaxFlowDistance;
int g_iOff_m_chapter;
int g_iOff_m_attributeFlags;
int g_iOff_m_spawnAttributes;
int g_iOff_NavAreaID;
// int g_iOff_m_iClrRender; // NULL PTR - METHOD (kept for demonstration)
// int ClearTeamScore_A;
// int ClearTeamScore_B;
// Address TeamScoresAddress;

// l4d2timers.inc
int L4D2CountdownTimer_Offsets[10];
int L4D2IntervalTimer_Offsets[6];

// l4d2weapons.inc
int L4D2IntWeapon_Offsets[7];
int L4D2FloatWeapon_Offsets[21];
int L4D2BoolMeleeWeapon_Offsets[1];
int L4D2IntMeleeWeapon_Offsets[2];
int L4D2FloatMeleeWeapon_Offsets[3];



// Pointers
int g_pScriptedEventManager;
int g_pVersusMode;
int g_pSurvivalMode;
int g_pScavengeMode;
Address g_pServer;
Address g_pAmmoDef;
Address g_pDirector;
Address g_pGameRules;
Address g_pTheNavAreas;
Address g_pTheNavAreas_List;
Address g_pTheNavAreas_Size;
Address g_pNavMesh;
Address g_pZombieManager;
Address g_pMeleeWeaponInfoStore;
Address g_pWeaponInfoDatabase;
Address g_pScriptVM;
Address g_pCTerrorPlayer_CanBecomeGhost;



// CanBecomeGhost patch
ArrayList g_hCanBecomeGhost;
int g_iCanBecomeGhostOffset;



// Other
Address g_pScriptId;
int g_iPlayerResourceRef;
int g_iOffsetAmmo;
int g_iPrimaryAmmoType;
int g_iCurrentMode;
int g_iMaxChapters;
int g_iClassTank;
int g_iGasCanModel;
char g_sSystem[16];
bool g_bLinuxOS;
bool g_bLeft4Dead2;
bool g_bFinalCheck;
bool g_bMapStarted;
bool g_bRoundEnded;
bool g_bCheckpointFirst[MAXPLAYERS+1];
bool g_bCheckpointLast[MAXPLAYERS+1];
ConVar g_hCvar_VScriptBuffer;
ConVar g_hCvar_AddonsEclipse;
ConVar g_hCvar_RescueDeadTime;
ConVar g_hCvar_PillsDecay;
ConVar g_hCvar_Adrenaline;
ConVar g_hCvar_Revives;
ConVar g_hCvar_MPGameMode;
DynamicHook g_hScriptHook;



#if DEBUG
bool g_bLateLoad;
#endif





// TARGET FILTERS
#include "l4dd/l4dd_targetfilters.sp"

// NATIVES
#include "l4dd/l4dd_natives.sp"

// DETOURS - FORWARDS
#include "l4dd/l4dd_forwards.sp"

// GAMEDATA
#include "l4dd/l4dd_gamedata.sp"

// SETUP FORWARDS AND NATIVES
#include "l4dd/l4dd_setup.sp"





// ====================================================================================================
//										PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Left 4 DHooks Direct",
	author = "SilverShot",
	description = "Left 4 Downtown and L4D Direct conversion and merger.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=321696"
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

	#if DEBUG
	g_bLateLoad = late;
	#endif



	g_hThisPlugin = myself;



	// =================
	// UPDATER
	// =================
	MarkNativeAsOptional("Updater_AddPlugin");



	// =================
	// DUPLICATE PLUGIN RUNNING
	// =================
	if( GetFeatureStatus(FeatureType_Native, "L4D_BecomeGhost") == FeatureStatus_Available )
	{
		strcopy(error, err_max, "\n====================\nPlugin \"Left 4 DHooks\" is already running. Please remove the duplicate plugin.\n====================");
		return APLRes_SilentFailure;
	}



	// =================
	// EXTENSION BLOCK
	// =================
	if( GetFeatureStatus(FeatureType_Native, "L4D_RestartScenarioFromVote") != FeatureStatus_Unknown )
	{
		strcopy(error, err_max, "\n====================\nThis plugin replaces Left4Downtown. Delete the extension to run.\n====================");
		return APLRes_SilentFailure;
	}



	// =================
	// SETUP FORWARDS AND NATIVES
	// =================
	SetupForwardsNatives(); // From: "l4dd/l4dd_setup.sp"



	// =================
	// END SETUP
	// =================
	RegPluginLibrary("left4dhooks");



	return APLRes_Success;
}



// ====================================================================================================
//									UPDATER
// ====================================================================================================
#if ALLOW_UPDATER
public void OnLibraryAdded(const char[] name)
{
	if( strcmp(name, "updater") == 0 )
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
#endif

#if ALLOW_UPDATER == 2
public void Updater_OnPluginUpdated()
{
	char filename[64];
	GetPluginFilename(null, filename, sizeof(filename));
	ServerCommand("sm plugins reload %s", filename);
}
#endif



// ====================================================================================================
//									SETUP
// ====================================================================================================
public void OnPluginStart()
{
	g_fLoadTime = GetEngineTime();

	g_iClassTank = g_bLeft4Dead2 ? 8 : 5;

	g_hCanBecomeGhost = new ArrayList();

	g_iOffsetAmmo = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	g_iPrimaryAmmoType = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");



	// NULL PTR - METHOD (kept for demonstration)
	// Null pointer - by Dragokas
	/*
	g_iOff_m_iClrRender = FindSendPropInfo("CBaseEntity", "m_clrRender");
	if( g_iOff_m_iClrRender == -1 )
	{
		SetFailState("Error: m_clrRender not found.");
	}
	*/



	// ====================================================================================================
	//									LOAD GAMEDATA
	// ====================================================================================================
	LoadGameData();



	// ====================================================================================================
	//									TARGET FILTERS
	// ====================================================================================================
	LoadTargetFilters();



	// ====================================================================================================
	//									ANIMMATION HOOK
	// ====================================================================================================
	g_hAnimationActivityList = new ArrayList(ByteCountToCells(48));
	ParseActivityConfig();

	g_iAnimationHookedClients = new ArrayList();
	g_iAnimationHookedPlugins = new ArrayList(2);

	for( int i = 1; i <= MaxClients; i++ )
	{
		g_hAnimationCallbackPre[i]		= new PrivateForward(ET_Event, Param_Cell, Param_CellByRef);
		g_hAnimationCallbackPost[i]		= new PrivateForward(ET_Event, Param_Cell, Param_CellByRef);
	}



	// ====================================================================================================
	//									WEAPON IDS
	// ====================================================================================================
	g_aWeaponPtrs = new StringMap();
	g_aWeaponIDs = new StringMap();

	if( !g_bLeft4Dead2 )
	{
		g_aWeaponIDs.SetValue("weapon_none",						0);
		g_aWeaponIDs.SetValue("weapon_pistol",						1);
		g_aWeaponIDs.SetValue("weapon_smg",							2);
		g_aWeaponIDs.SetValue("weapon_pumpshotgun",					3);
		g_aWeaponIDs.SetValue("weapon_autoshotgun",					4);
		g_aWeaponIDs.SetValue("weapon_rifle",						5);
		g_aWeaponIDs.SetValue("weapon_hunting_rifle",				6);
		g_aWeaponIDs.SetValue("weapon_first_aid_kit",				8);
		g_aWeaponIDs.SetValue("weapon_molotov",						9);
		g_aWeaponIDs.SetValue("weapon_pipe_bomb",					10);
		g_aWeaponIDs.SetValue("weapon_pain_pills",					12);
		g_aWeaponIDs.SetValue("weapon_gascan",						14);
		g_aWeaponIDs.SetValue("weapon_propanetank",					15);
		g_aWeaponIDs.SetValue("weapon_oxygentank",					16);
		g_aWeaponIDs.SetValue("weapon_tank_claw",					17);
		g_aWeaponIDs.SetValue("weapon_hunter_claw",					18);
		g_aWeaponIDs.SetValue("weapon_boomer_claw",					19);
		g_aWeaponIDs.SetValue("weapon_smoker_claw",					20);
		g_aWeaponIDs.SetValue("weapon_ammo_spawn",					29);
	} else {
		g_aWeaponIDs.SetValue("weapon_none",						0);
		g_aWeaponIDs.SetValue("weapon_pistol",						1);
		g_aWeaponIDs.SetValue("weapon_smg",							2);
		g_aWeaponIDs.SetValue("weapon_pumpshotgun",					3);
		g_aWeaponIDs.SetValue("weapon_autoshotgun",					4);
		g_aWeaponIDs.SetValue("weapon_rifle",						5);
		g_aWeaponIDs.SetValue("weapon_hunting_rifle",				6);
		g_aWeaponIDs.SetValue("weapon_smg_silenced",				7);
		g_aWeaponIDs.SetValue("weapon_shotgun_chrome",				8);
		g_aWeaponIDs.SetValue("weapon_rifle_desert",				9);
		g_aWeaponIDs.SetValue("weapon_sniper_military",				10);
		g_aWeaponIDs.SetValue("weapon_shotgun_spas",				11);
		g_aWeaponIDs.SetValue("weapon_first_aid_kit",				12);
		g_aWeaponIDs.SetValue("weapon_molotov",						13);
		g_aWeaponIDs.SetValue("weapon_pipe_bomb",					14);
		g_aWeaponIDs.SetValue("weapon_pain_pills",					15);
		g_aWeaponIDs.SetValue("weapon_gascan",						16);
		g_aWeaponIDs.SetValue("weapon_propanetank",					17);
		g_aWeaponIDs.SetValue("weapon_oxygentank",					18);
		g_aWeaponIDs.SetValue("weapon_melee",						19);
		g_aWeaponIDs.SetValue("weapon_chainsaw",					20);
		g_aWeaponIDs.SetValue("weapon_grenade_launcher",			21);
		// g_aWeaponIDs.SetValue("weapon_ammo_pack",				22); // Unavailable
		g_aWeaponIDs.SetValue("weapon_adrenaline",					23);
		g_aWeaponIDs.SetValue("weapon_defibrillator",				24);
		g_aWeaponIDs.SetValue("weapon_vomitjar",					25);
		g_aWeaponIDs.SetValue("weapon_rifle_ak47",					26);
		g_aWeaponIDs.SetValue("weapon_gnome",						27);
		g_aWeaponIDs.SetValue("weapon_cola_bottles",				28);
		g_aWeaponIDs.SetValue("weapon_fireworkcrate",				29);
		g_aWeaponIDs.SetValue("weapon_upgradepack_incendiary",		30);
		g_aWeaponIDs.SetValue("weapon_upgradepack_explosive",		31);
		g_aWeaponIDs.SetValue("weapon_pistol_magnum",				32);
		g_aWeaponIDs.SetValue("weapon_smg_mp5",						33);
		g_aWeaponIDs.SetValue("weapon_rifle_sg552",					34);
		g_aWeaponIDs.SetValue("weapon_sniper_awp",					35);
		g_aWeaponIDs.SetValue("weapon_sniper_scout",				36);
		g_aWeaponIDs.SetValue("weapon_rifle_m60",					37);
		g_aWeaponIDs.SetValue("weapon_tank_claw",					38);
		g_aWeaponIDs.SetValue("weapon_hunter_claw",					39);
		g_aWeaponIDs.SetValue("weapon_charger_claw",				40);
		g_aWeaponIDs.SetValue("weapon_boomer_claw",					41);
		g_aWeaponIDs.SetValue("weapon_smoker_claw",					42);
		g_aWeaponIDs.SetValue("weapon_spitter_claw",				43);
		g_aWeaponIDs.SetValue("weapon_jockey_claw",					44);
		g_aWeaponIDs.SetValue("weapon_ammo_spawn",					54);

		g_aMeleePtrs = new ArrayList(2);
		g_aMeleeIDs = new StringMap();
		g_aMeleeIDs.SetValue("fireaxe",								0);
		g_aMeleeIDs.SetValue("frying_pan",							1);
		g_aMeleeIDs.SetValue("machete",								2);
		g_aMeleeIDs.SetValue("baseball_bat",						3);
		g_aMeleeIDs.SetValue("crowbar",								4);
		g_aMeleeIDs.SetValue("cricket_bat",							5);
		g_aMeleeIDs.SetValue("tonfa",								6);
		g_aMeleeIDs.SetValue("katana",								7);
		g_aMeleeIDs.SetValue("electric_guitar",						8);
		g_aMeleeIDs.SetValue("knife",								9);
		g_aMeleeIDs.SetValue("golfclub",							10);
		g_aMeleeIDs.SetValue("pitchfork",							11);
		g_aMeleeIDs.SetValue("shovel",								12);
	}



	// ====================================================================================================
	//									COMMANDS
	// ====================================================================================================
	// When adding or removing plugins that use any detours during gameplay. To optimize forwards by disabling unused or enabling required functions that were previously unused. TODO: Not needed when using extra-api.ext
	RegAdminCmd("sm_l4dd_unreserve",	CmdLobby,	ADMFLAG_ROOT, "Removes lobby reservation.");
	RegAdminCmd("sm_l4dd_reload",		CmdReload,	ADMFLAG_ROOT, "Reloads the detour hooks, enabling or disabling depending if they're required by other plugins.");
	RegAdminCmd("sm_l4dd_detours",		CmdDetours,	ADMFLAG_ROOT, "Lists the currently active forwards and the plugins using them.");
	RegAdminCmd("sm_l4dhooks_reload",	CmdReload,	ADMFLAG_ROOT, "Reloads the detour hooks, enabling or disabling depending if they're required by other plugins.");
	RegAdminCmd("sm_l4dhooks_detours",	CmdDetours,	ADMFLAG_ROOT, "Lists the currently active forwards and the plugins using them.");



	// ====================================================================================================
	//									CVARS
	// ====================================================================================================
	ConVar hVersion = CreateConVar("left4dhooks_version", PLUGIN_VERSION,	"Left 4 DHooks Direct plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hVersion.SetString(PLUGIN_VERSION); // Force version cvar to update if server updates the plugin but doesn't reboot, so it's reporting the current version in use

	if( g_bLeft4Dead2 )
	{
		g_hCvar_VScriptBuffer = CreateConVar("l4d2_vscript_return", "", "Buffer used to return VScript values. Do not use.", FCVAR_DONTRECORD);
		g_hCvar_AddonsEclipse = CreateConVar("l4d2_addons_eclipse", "-1", "Addons Manager (-1: use addonconfig; 0: disable addons; 1: enable addons.)", FCVAR_NOTIFY);

		g_hCvar_AddonsEclipse.AddChangeHook(ConVarChanged_Addons);
		g_iCvar_AddonsEclipse = g_hCvar_AddonsEclipse.IntValue;

		g_hCvar_Adrenaline = FindConVar("adrenaline_health_buffer");
		g_hCvar_Adrenaline.AddChangeHook(ConVarChanged_Cvars);
		g_fCvar_Adrenaline = g_hCvar_Adrenaline.FloatValue;
	} else {
		g_hCvar_Revives = FindConVar("survivor_max_incapacitated_count");
	}

	g_hCvar_PillsDecay = FindConVar("pain_pills_decay_rate");
	g_hCvar_PillsDecay.AddChangeHook(ConVarChanged_Cvars);
	g_fCvar_PillsDecay = g_hCvar_PillsDecay.FloatValue;

	g_hCvar_RescueDeadTime = FindConVar("rescue_min_dead_time");
	g_hCvar_RescueDeadTime.AddChangeHook(ConVarChanged_Cvars);
	g_iCvar_RescueDeadTime = g_hCvar_RescueDeadTime.IntValue;

	g_hCvar_MPGameMode = FindConVar("mp_gamemode");
	g_hCvar_MPGameMode.AddChangeHook(ConVarChanged_Mode);



	// ====================================================================================================
	//									EVENTS
	// ====================================================================================================
	HookEvent("round_start",					Event_RoundStart);

	if( !g_bLeft4Dead2 )
	{
		HookEvent("round_end",						Event_RoundEnd);
		HookEvent("player_entered_start_area",		Event_EnteredStartArea);
		HookEvent("player_left_start_area",			Event_LeftStartArea);
		HookEvent("player_entered_checkpoint",		Event_EnteredCheckpoint);
		HookEvent("player_left_checkpoint",			Event_LeftCheckpoint);
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundEnded = false;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	// Reset checkpoints
	if( !g_bLeft4Dead2 )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			g_bCheckpointFirst[i] = false;
			g_bCheckpointLast[i] = false;
		}
	}
}

void Event_EnteredStartArea(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bCheckpointFirst[client] = true;
}

void Event_LeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bCheckpointFirst[client] = false;
}

void Event_EnteredCheckpoint(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("userid");
	if( client )
	{
		client = GetClientOfUserId(client);
		if( client )
		{
			int door = event.GetInt("door");

			if( door == GetCheckpointFirst() )
			{
				g_bCheckpointFirst[client] = true;
			}
			else if( door == GetCheckpointLast() )
			{
				g_bCheckpointLast[client] = true;
			}
		}
	}
}

void Event_LeftCheckpoint(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("userid");
	if( client )
	{
		client = GetClientOfUserId(client);
		if( client )
		{
			g_bCheckpointFirst[client] = false;
			g_bCheckpointLast[client] = false;
		}
	}
}



// ====================================================================================================
//										CLEAN UP
// ====================================================================================================
public void OnPluginEnd()
{
	// Unpatch AddonsDisabler
	if( g_bLeft4Dead2 )
		AddonsDisabler_Unpatch();

	// Unpatch CanBecomeGhost
	int count = g_hCanBecomeGhost.Length;
	for( int i = 0; i < count; i++ )
	{
		StoreToAddress(g_pCTerrorPlayer_CanBecomeGhost + view_as<Address>(g_iCanBecomeGhostOffset + i), g_hCanBecomeGhost.Get(i), NumberType_Int8, true);
	}

	// Target Filters
	UnloadTargetFilters();
}



// ====================================================================================================
//										GAME MODE
// ====================================================================================================
void ConVarChanged_Mode(Handle convar, const char[] oldValue, const char[] newValue)
{
	// Want to rescan max chapters on mode change
	g_iMaxChapters = 0;

	// For game mode native/forward
	GetGameMode();
}

void GetGameMode() // Forward "L4D_OnGameModeChange"
{
	g_iCurrentMode = 0;

	static char sMode[10];

	if( g_bLeft4Dead2 )
	{
		ValidateAddress(g_pDirector, "g_pDirector");
		ValidateNatives(g_hSDK_CDirector_GetGameModeBase, "CDirector::GetGameModeBase");

		//PrintToServer("#### CALL g_hSDK_CDirector_GetGameModeBase");
		SDKCall(g_hSDK_CDirector_GetGameModeBase, g_pDirector, sMode, sizeof(sMode));

		if( strcmp(sMode,			"coop") == 0 )		g_iCurrentMode = GAMEMODE_COOP;
		else if( strcmp(sMode,		"realism") == 0 )	g_iCurrentMode = GAMEMODE_COOP;
		else if( strcmp(sMode,		"survival") == 0 )	g_iCurrentMode = GAMEMODE_SURVIVAL;
		else if( strcmp(sMode,		"versus") == 0 )	g_iCurrentMode = GAMEMODE_VERSUS;
		else if( strcmp(sMode,		"scavenge") == 0 )	g_iCurrentMode = GAMEMODE_SCAVENGE;
	} else {
		g_hCvar_MPGameMode.GetString(sMode, sizeof(sMode));

		if( strcmp(sMode,			"coop") == 0 )		g_iCurrentMode = GAMEMODE_COOP;
		else if( strcmp(sMode,		"survival") == 0 )	g_iCurrentMode = GAMEMODE_SURVIVAL;
		else if( strcmp(sMode,		"versus") == 0 )	g_iCurrentMode = GAMEMODE_VERSUS;
	}

	// Forward
	static int mode;

	if( mode != g_iCurrentMode )
	{
		mode = g_iCurrentMode;

		Call_StartForward(g_hFWD_GameModeChange);
		Call_PushCell(mode);
		Call_Finish();
	}
}

int Native_Internal_GetGameMode(Handle plugin, int numParams) // Native "L4D_GetGameModeType"
{
	return g_iCurrentMode;
}

int Native_CTerrorGameRules_IsGenericCooperativeMode(Handle plugin, int numParams) // Native "L4D2_IsGenericCooperativeMode"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	if( !g_bMapStarted )
	{
		ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_TOO_EARLY, "L4D2_IsGenericCooperativeMode");
		return false;
	}

	ValidateAddress(g_pGameRules, "g_pGameRules");
	ValidateNatives(g_hSDK_CTerrorGameRules_IsGenericCooperativeMode, "CTerrorGameRules::IsGenericCooperativeMode");

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_IsGenericCooperativeMode");
	return SDKCall(g_hSDK_CTerrorGameRules_IsGenericCooperativeMode, g_pGameRules);
}

int Native_Internal_IsCoopMode(Handle plugin, int numParams) // Native "L4D_IsCoopMode"
{
	return g_iCurrentMode == GAMEMODE_COOP;
}

int Native_Internal_IsRealismMode(Handle plugin, int numParams) // Native "L4D2_IsRealismMode"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	if( !g_bMapStarted )
	{
		ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_TOO_EARLY, "L4D2_IsRealismMode");
		return false;
	}

	ValidateAddress(g_pGameRules, "g_pGameRules");
	ValidateNatives(g_hSDK_CTerrorGameRules_IsRealismMode, "CTerrorGameRules::IsRealismMode");

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_IsRealismMode");
	return SDKCall(g_hSDK_CTerrorGameRules_IsRealismMode, g_pGameRules);
}

int Native_Internal_IsSurvivalMode(Handle plugin, int numParams) // Native "L4D_IsSurvivalMode"
{
	return g_iCurrentMode == GAMEMODE_SURVIVAL;
}

int Native_Internal_IsScavengeMode(Handle plugin, int numParams) // Native "L4D2_IsScavengeMode"
{
	return g_iCurrentMode == GAMEMODE_SCAVENGE;
}

int Native_Internal_IsVersusMode(Handle plugin, int numParams) // Native "L4D_IsVersusMode"
{
	return g_iCurrentMode == GAMEMODE_VERSUS;
}



// ====================================================================================================
//										ANIMATION HOOK
// ====================================================================================================
public void OnMapEnd()
{
	// Reset vars
	g_bMapStarted = false;
	g_bFinalCheck = false;
	g_iMaxChapters = 0;

	// Reset checkpoints
	if( !g_bLeft4Dead2 )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			g_bCheckpointFirst[i] = false;
			g_bCheckpointLast[i] = false;
		}
	}

	// Reset hooks
	g_iAnimationHookedClients.Clear();
	g_iAnimationHookedPlugins.Clear();

	// Remove all hooked functions from private forward
	Handle hIter = GetPluginIterator();
	Handle hPlug;

	// Iterate plugins - remove animation hooks
	while( MorePlugins(hIter) )
	{
		hPlug = ReadPlugin(hIter);

		for( int i = 1; i <= MaxClients; i++ )
		{
			g_hAnimationCallbackPre[i].RemoveAllFunctions(hPlug);
			g_hAnimationCallbackPost[i].RemoveAllFunctions(hPlug);
		}
	}

	delete hIter;
}

public void OnClientDisconnect(int client)
{
	g_bCheckpointFirst[client] = false;
	g_bCheckpointLast[client] = false;



	// Remove client from hooked list
	int index = g_iAnimationHookedClients.FindValue(client);
	if( index != -1 )
	{
		g_iAnimationHookedClients.Erase(index);

		// Remove PrivateForward for client
		Handle hIter = GetPluginIterator();
		Handle hPlug;

		while( MorePlugins(hIter) )
		{
			hPlug = ReadPlugin(hIter);

			g_hAnimationCallbackPre[client].RemoveAllFunctions(hPlug);
			g_hAnimationCallbackPost[client].RemoveAllFunctions(hPlug);
		}

		delete hIter;
	}



	// Loop through all anim hooks for specific client
	int length = g_iAnimationHookedPlugins.Length;

	int i, target;
	while( i < length )
	{
		// Get hooked client
		target = g_iAnimationHookedPlugins.Get(i, 1);

		// Verify client to unhook
		if( client == target )
		{
			g_iAnimationHookedPlugins.Erase(i);
			length--;
		}
		else
		{
			i++;
		}
	}



	// Acid damage, no sound fix
	if( g_bLeft4Dead2 )
	{
		if( !IsClientInGame(client) || (GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == L4D2_ZOMBIE_CLASS_SPITTER) )
		{
			int entity = -1;
			while( (entity = FindEntityByClassname(entity, "insect_swarm")) != INVALID_ENT_REFERENCE )
			{
				if( GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") == client )
				{
					AcidDamageTest(0, entity); // See the "l4dd_natives.sp" file
				}
			}
		}
	}
}

public void OnNotifyPluginUnloaded(Handle plugin)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_hAnimationCallbackPre[i].RemoveAllFunctions(plugin);
		g_hAnimationCallbackPost[i].RemoveAllFunctions(plugin);
	}
}



// =========================
// ANIMATION NATIVES
// =========================
int Native_AnimHookEnable(Handle plugin, int numParams) // Native "AnimHookEnable"
{
	// Validate client
	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients || !IsClientInGame(client) ) return false;

	// Check if detour enabled, otherwise enable.
	int index = g_aForwardIndex.Get(g_iAnimationDetourIndex);
	if( g_aDetoursHooked.Get(index) == 0 )
	{
		g_aDetoursHooked.Set(index, 1);
		g_aForceDetours.Set(g_iAnimationDetourIndex, 1);

		DynamicDetour hDetour = g_aDetourHandles.Get(index);
		hDetour.Enable(Hook_Pre, DTR_CBaseAnimating_SelectWeightedSequence_Pre);
		hDetour.Enable(Hook_Post, DTR_CBaseAnimating_SelectWeightedSequence_Post);
	}

	// Add callback
	if( GetNativeFunction(2) != INVALID_FUNCTION ) g_hAnimationCallbackPre[client].AddFunction(plugin, GetNativeFunction(2));
	if( GetNativeFunction(3) != INVALID_FUNCTION ) g_hAnimationCallbackPost[client].AddFunction(plugin, GetNativeFunction(3));

	g_iAnimationHookedClients.Push(client);

	// Add multiple callbacks, validate by client
	index = g_iAnimationHookedPlugins.Push(plugin);
	g_iAnimationHookedPlugins.Set(index, client, 1);

	g_bAnimationRemoveHook = false;

	return true;
}

int Native_AnimHookDisable(Handle plugin, int numParams) // Native "AnimHookDisable"
{
	int client = GetNativeCell(1);

	// Remove callbacks, if required
	Handle target;
	bool keep;
	int entity;

	// Loop through all anim hooks
	int length = g_iAnimationHookedPlugins.Length;
	for( int i = 0; i < length; i++ )
	{
		// Get hooked plugin handle
		target = g_iAnimationHookedPlugins.Get(i, 0);

		// Match to plugin requesting unhook
		if( target == plugin )
		{
			// Get hooked client from that plugin
			entity = g_iAnimationHookedPlugins.Get(i, 1);

			// Verify client to unhook
			if( client == entity )
			{
				g_iAnimationHookedPlugins.Erase(i);
				if( i > 0 ) i--;
				length--;
			} else {
				keep = true;
			}
		}
	}

	int index = g_aForwardIndex.Get(g_iAnimationDetourIndex);

	// Delete callback, client not being hooked from target plugin any more
	if( !keep )
	{
		if( GetNativeFunction(2) != INVALID_FUNCTION ) g_hAnimationCallbackPre[client].RemoveFunction(plugin, GetNativeFunction(2));
		if( GetNativeFunction(3) != INVALID_FUNCTION ) g_hAnimationCallbackPost[client].RemoveFunction(plugin, GetNativeFunction(3));
	}

	// Remove detour, no more plugins using it
	if( length == 0 && g_aDetoursHooked.Get(index) == 1 && g_aForceDetours.Get(g_iAnimationDetourIndex) == 1 )
	{
		g_bAnimationRemoveHook = true;
		RequestFrame(OnFrameRemoveDetour);
	}

	// Remove client from checking array
	index = g_iAnimationHookedClients.FindValue(client);
	if( index != -1 )
	{
		g_iAnimationHookedClients.Erase(index);
		return true;
	}

	return false;
}

void OnFrameRemoveDetour()
{
	if( g_bAnimationRemoveHook )
	{
		g_bAnimationRemoveHook = false;

		int index = g_aForwardIndex.Get(g_iAnimationDetourIndex);
		g_aDetoursHooked.Set(index, 0);
		g_aForceDetours.Set(g_iAnimationDetourIndex, 0);

		DynamicDetour hDetour = g_aDetourHandles.Get(index);
		hDetour.Disable(Hook_Pre, DTR_CBaseAnimating_SelectWeightedSequence_Pre);
		hDetour.Disable(Hook_Post, DTR_CBaseAnimating_SelectWeightedSequence_Post);
	}
}

int Native_AnimGetActivity(Handle plugin, int numParams) // Native "AnimGetActivity"
{
	int sequence = GetNativeCell(1);
	int maxlength = GetNativeCell(3);
	char[] activity = new char[maxlength];

	if( g_hAnimationActivityList.GetString(sequence, activity, maxlength) )
	{
		SetNativeString(2, activity, maxlength);
		return true;
	}

	return false;
}

int Native_AnimGetFromActivity(Handle plugin, int numParams) // Native "AnimGetFromActivity"
{
	int maxlength;
	GetNativeStringLength(1, maxlength);
	maxlength += 1;
	char[] activity = new char[maxlength];
	GetNativeString(1, activity, maxlength);

	int sequence = g_hAnimationActivityList.FindString(activity);
	return sequence;
}



// =========================
// ACTIVITY CONFIG
// =========================
bool ParseActivityConfig()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/%s.cfg", g_bLeft4Dead2 ? GAMEDATA_2 : GAMEDATA_1);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	SMCParser parser = new SMCParser();
	parser.OnEnterSection = ColorConfig_NewSection;
	parser.OnKeyValue = ColorConfig_KeyValue;
	parser.OnLeaveSection = ColorConfig_EndSection;
	parser.OnEnd = ColorConfig_End;

	char error[128];
	int line = 0, col = 0;
	SMCError result = parser.ParseFile(sPath, line, col);

	if( result != SMCError_Okay )
	{
		parser.GetErrorString(result, error, sizeof(error));
		SetFailState("%s on line %d, col %d of %s [%d]", error, line, col, sPath, result);
	}

	delete parser;
	return (result == SMCError_Okay);
}

SMCResult ColorConfig_NewSection(SMCParser parser, const char[] section, bool quotes)
{
	return SMCParse_Continue;
}

SMCResult ColorConfig_KeyValue(SMCParser parser, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	g_hAnimationActivityList.PushString(key);
	return SMCParse_Continue;
}

SMCResult ColorConfig_EndSection(SMCParser parser)
{
	return SMCParse_Continue;
}

void ColorConfig_End(SMCParser parser, bool halted, bool failed)
{
	if( failed )
		SetFailState("Error: Cannot load the Activity config.");
}



// ====================================================================================================
//										DISABLE ADDONS
// ====================================================================================================
public void OnConfigsExecuted()
{
	if( g_bLeft4Dead2 )
		ConVarChanged_Addons(null, "", "");

	ConVarChanged_Cvars(null, "", "");
}

bool g_bAddonsPatched;

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	if( g_bLeft4Dead2 )
		g_fCvar_Adrenaline = g_hCvar_Adrenaline.FloatValue;
	g_fCvar_PillsDecay = g_hCvar_PillsDecay.FloatValue;
	g_iCvar_RescueDeadTime = g_hCvar_RescueDeadTime.IntValue;
}

void ConVarChanged_Addons(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iCvar_AddonsEclipse = g_hCvar_AddonsEclipse.IntValue;

	if( g_iCvar_AddonsEclipse > -1 )
		AddonsDisabler_Patch();
	else
		AddonsDisabler_Unpatch();
}

int AddonsDisabler_Restore[3];
void AddonsDisabler_Patch()
{
	if( !g_bAddonsPatched )
	{
		g_bAddonsPatched = true;
		AddonsDisabler_Restore[0] = LoadFromAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset), NumberType_Int8);
		AddonsDisabler_Restore[1] = LoadFromAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset + 1), NumberType_Int8);
		AddonsDisabler_Restore[2] = LoadFromAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset + 2), NumberType_Int8);
	}

	//PrintToServer("Addons restore: %02x%02x%02x", AddonsDisabler_Restore[0], AddonsDisabler_Restore[1], AddonsDisabler_Restore[2]);
	StoreToAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset), 0x0F, NumberType_Int8);
	StoreToAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset + 1), 0x1F, NumberType_Int8);
	StoreToAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset + 2), 0x00, NumberType_Int8);
}

void AddonsDisabler_Unpatch()
{
	if( g_bAddonsPatched )
	{
		g_bAddonsPatched = false;
		StoreToAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset), AddonsDisabler_Restore[0], NumberType_Int8);
		StoreToAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset + 1), AddonsDisabler_Restore[1], NumberType_Int8);
		StoreToAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset + 2), AddonsDisabler_Restore[2], NumberType_Int8);
	}
}



// ====================================================================================================
//										ADDONS DISABLER DETOUR
// ====================================================================================================
MRESReturn DTR_AddonsDisabler(int pThis, Handle hReturn, DHookParam hParams) // Forward "L4D2_OnClientDisableAddons"
{
	// Details on finding offsets can be found here: https://github.com/ProdigySim/left4dhooks/pull/1
	// Big thanks to "ProdigySim" for updating for The Last Stand update.

	#if DEBUG
	PrintToServer("##### DTR_AddonsDisabler");
	#endif

	int cvar = g_iCvar_AddonsEclipse;
	if( cvar != -1 )
	{
		int ptr = hParams.Get(1);

		// This is `m_nPlayerSlot` on the `SVC_ServerInfo`.
		// It represents the client index of the connecting user.
		int playerSlot = LoadFromAddress(view_as<Address>(ptr + g_iOff_AddonEclipse1), NumberType_Int8);
		// The playerslot is an index into `CBaseServer::m_Clients`, and SourceMod's client entity indexes are just `m_Clients` index plus 1.
		int client = playerSlot + 1;

		#if DEBUG
		PrintToServer("#### AddonCheck for %d", client);
		#endif

		if( client > 0 && client <= MaxClients && IsClientConnected(client) )
		{
			// Yes False, because we need SteamID soon as connected, this is how downtown worked.
			static char netID[32];
			GetClientAuthId(client, AuthId_Steam2, netID, sizeof(netID), false);

			#if DEBUG
			PrintToServer("#### AddonCheck for %d [%s] (%N)", client, netID, client);
			#endif

			Action aResult = Plugin_Continue;
			Call_StartForward(g_hFWD_AddonsDisabler);
			Call_PushString(netID);
			Call_Finish(aResult);

			// 1 to tell the client it should use "vanilla mode"--no addons. 0 to enable addons.
			int bVanillaMode = aResult == Plugin_Handled ? 0 : view_as<int>(!cvar);
			StoreToAddress(view_as<Address>(ptr + g_iOff_AddonEclipse2), bVanillaMode, NumberType_Int8, false);

			#if DEBUG
			PrintToServer("#### AddonCheck VanillaMode for %d [%s] (%N): %d", client, netID, client, bVanillaMode);
			#endif
		}
	}

	return MRES_Ignored;
}



// ====================================================================================================
//										DYNAMIC DETOURS SETUP
// ====================================================================================================
Action CmdReload(int client, int args)
{
	float timing = GetEngineTime();
	OnMapStart();
	ReplyToCommand(client, "[Left4DHooks: Detours reloaded in %f seconds.", GetEngineTime() - timing);
	return Plugin_Handled;
}

Action CmdDetours(int client, int args)
{
	CallCheckRequiredDetours(client + 1);
	return Plugin_Handled;
}

public void AP_OnPluginUpdate(int pre) // From "Autoreload Plugins" by "Dragokas"
{
	if( pre == 0 && GetEngineTime() - g_fLoadTime > 5.0 )
	{
		CallCheckRequiredDetours();
	}
}

void CallCheckRequiredDetours(int client = 0)
{
	#if DEBUG
	g_vProf = new Profiler();
	g_fProf = 0.0;
	g_vProf.Start();
	#endif

	CheckRequiredDetours(client);

	#if DEBUG
	g_vProf.Stop();
	g_fProf += g_vProf.Time;
	PrintToServer("");
	PrintToServer("Dynamic Detours finished in %f seconds.", g_fProf);
	PrintToServer("");
	delete g_vProf;
	#endif
}



// ====================================================================================================
//										MAP START - INITIALIZE - (LOAD GAMEDATA, DETOURS etc)
// ====================================================================================================
public void OnMapStart()
{
	g_bRoundEnded = false;



	// Load PlayerResource
	int iPlayerResource = FindEntityByClassname(-1, "terror_player_manager");

	g_iPlayerResourceRef = (iPlayerResource != INVALID_ENT_REFERENCE) ? EntIndexToEntRef(iPlayerResource) : INVALID_ENT_REFERENCE;



	// Putting this here so g_pGameRules is valid. Changes for each map.
	LoadGameDataRules(g_hGameData);



	// Load detours, first load from plugin start
	if( !g_bCreatedDetours )
	{
		g_pScriptId = view_as<Address>(FindDataMapInfo(0, "m_iszScriptId") - 16);

		SetupDetours(g_hGameData);
	}



	// Benchmark
	#if DEBUG
	g_vProf = new Profiler();
	g_fProf = 0.0;
	g_vProf.Start();
	#endif



	// Enable or Disable detours as required.
	CheckRequiredDetours();

	#if DEBUG
	g_vProf.Stop();
	g_fProf += g_vProf.Time;
	PrintToServer("");
	PrintToServer("Dynamic Detours finished in %f seconds.", g_fProf);
	PrintToServer("");
	delete g_vProf;
	#endif



	// Because reload command calls this function. We only want these loaded on actual map start.
	if( !g_bMapStarted )
	{
		GetGameMode(); // Get current game mode



		// Precache Models, prevent crashing when spawning with SpawnSpecial()
		for( int i = 0; i < sizeof(g_sModels1); i++ )
			PrecacheModel(g_sModels1[i]);

		PrecacheModel(SPRITE_GLOW, true); // Dissolver

		if( g_bLeft4Dead2 )
		{
			for( int i = 0; i < sizeof(g_sModels2); i++ )
				PrecacheModel(g_sModels2[i]);

			for( int i = 0; i < sizeof(g_sAcidSounds); i++ )
				PrecacheSound(g_sAcidSounds[i]);

			for( int i = 0; i < 2048; i++ )
				g_iAcidEntity[i] = 0;
		}

		g_iGasCanModel = PrecacheModel(MODEL_GASCAN);

		// PipeBomb projectile
		PrecacheParticle(PARTICLE_FUSE);
		PrecacheParticle(PARTICLE_LIGHT);



		// Director Variables initialized before the plugin is able to hook.
		// Extension was able to process these and fire the forwards accordingly.
		// Some plugins want to overwrite these values from the forward. Please report which ones are required.
		static bool bDirectorVars;
		if( g_bLeft4Dead2 && bDirectorVars == false )
		{
			bDirectorVars = true;

			// Variable + default value you're passing, which may be used if the director var is not set. Probably uses cvar instead. Unknown.
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "MaxSpecials",			1); // This doesn't appear to work in the finale. At least for some maps.

			// These only appear to work in the Finale, or maybe some specific maps. Unknown.
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "SmokerLimit",			1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "BoomerLimit",			1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "HunterLimit",			1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "SpitterLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "JockeyLimit",			1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "ChargerLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "TankLimit",			1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "DominatorLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "WitchLimit",			1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "CommonLimit",			1);

			// Challenge mode required?
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_MaxSpecials",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_BaseSpecialLimit",	1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_SmokerLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_BoomerLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_HunterLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_SpitterLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_JockeyLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_ChargerLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_TankLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_DominatorLimit",	1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_WitchLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_CommonLimit",		1);

			// These also exist, required?
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "TotalSmokers",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "TotalBoomers",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "TotalHunters",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "TotalSpitter",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "TotalJockey",			1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "TotalCharger",		1);
		}



		// Melee weapon IDs - They can change when switching map depending on what melee weapons are enabled
		if( g_bLeft4Dead2 )
		{
			delete g_aMeleePtrs;
			delete g_aMeleeIDs;

			g_aMeleePtrs = new ArrayList(2);
			g_aMeleeIDs = new StringMap();

			int iTable = FindStringTable("meleeweapons");
			if( iTable == INVALID_STRING_TABLE ) // Default to known IDs
			{
				g_aMeleeIDs.SetValue("fireaxe",				0);
				g_aMeleeIDs.SetValue("frying_pan",			1);
				g_aMeleeIDs.SetValue("machete",				2);
				g_aMeleeIDs.SetValue("baseball_bat",		3);
				g_aMeleeIDs.SetValue("crowbar",				4);
				g_aMeleeIDs.SetValue("cricket_bat",			5);
				g_aMeleeIDs.SetValue("tonfa",				6);
				g_aMeleeIDs.SetValue("katana",				7);
				g_aMeleeIDs.SetValue("electric_guitar",		8);
				g_aMeleeIDs.SetValue("knife",				9);
				g_aMeleeIDs.SetValue("golfclub",			10);
				g_aMeleeIDs.SetValue("pitchfork",			11);
				g_aMeleeIDs.SetValue("shovel",				12);
			} else {
				// Get actual IDs
				int iNum = GetStringTableNumStrings(iTable);
				char sName[PLATFORM_MAX_PATH];

				for( int i = 0; i < iNum; i++ )
				{
					ReadStringTable(iTable, i, sName, sizeof(sName));
					g_aMeleeIDs.SetValue(sName, i);
				}
			}
		}

		g_bMapStarted = true;
	}
}



// ====================================================================================================
//										STOCKS - HEALTH
// ====================================================================================================
float GetTempHealth(int client)
{
	float fGameTime = GetGameTime();
	float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (fGameTime - fHealthTime) * g_fCvar_PillsDecay;
	return fHealth < 0.0 ? 0.0 : fHealth;
}

void SetTempHealth(int client, float fHealth)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}



// ====================================================================================================
//										STOCKS - AMMO
// ====================================================================================================
// Thanks to "Root" or whoever for this method of not hard-coding offsets: https://github.com/zadroot/AmmoManager/blob/master/scripting/ammo_manager.sp
int GetReserveAmmo(int client, int weapon)
{
	int offset = GetEntData(weapon, g_iPrimaryAmmoType) * 4;
	if( offset )
	{
		return GetEntData(client, g_iOffsetAmmo + offset);
	}

	return 0;
}

void SetReserveAmmo(int client, int weapon, int ammo)
{
	int offset = GetEntData(weapon, g_iPrimaryAmmoType) * 4;
	if( offset )
	{
		SetEntData(client, g_iOffsetAmmo + offset, ammo);
	}
}