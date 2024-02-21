#include <sourcemod>
#include <sdktools>

#pragma semicolon 1; // Force strict semicolon mode.
#pragma newdecls required; 

// l4dt native (for lobby unreserve)
native bool L4D_LobbyUnreserve();

// l4dt forward (to add more SI bots)
forward Action L4D_OnGetScriptValueInt(const char[] key, int &retVal);

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
#define PLUGIN_VERSION		       "2.5"
#define CVAR_FLAGS			FCVAR_NOTIFY
#define TEAM_SPECTATOR	               1
#define TEAM_SURVIVOR	               2
#define TEAM_INFECTED	               3
#define DELAY_KICK_NONEEDBOT         0.7
#define DELAY_KICK_FAKECLIENT        0.1
#define ZC_ZOMBIE                      0
#define ZC_SMOKER                      1
#define ZC_BOOMER                      2
#define ZC_HUNTER                      3
#define ZC_SPITTER                     4
#define ZC_JOCKEY                      5
#define ZC_CHARGER                     6
#define ZC_WITCH                       7
#define ZC_TANK                        8

ConVar TankVersusHealth;
ConVar TankExpertHealth;
ConVar TankAdvancedHealth;
ConVar TankNormalHealth;
ConVar TankEasyHealth;

ConVar CIMobSpawnFinaleSize;
ConVar CIMobSpawnMaxSize;
ConVar CIMobSpawnMinSize;
ConVar CIMegaMobSize;
ConVar CICommonMobLimit;
ConVar CIBackgroundMobSize;

ConVar ITMobSpawnMaxIntervalEasy;
ConVar ITMobSpawnMaxIntervalNormal;
ConVar ITMobSpawnMaxIntervalHard;
ConVar ITMobSpawnMaxIntervalExpert;
ConVar ITMobSpawnMinIntervalEasy;
ConVar ITMobSpawnMinIntervalNormal;
ConVar ITMobSpawnMinIntervalHard;
ConVar ITMobSpawnMinIntervalExpert;

ConVar ITMegaMobSpawnMaxInterval;
ConVar ITMegaMobSpawnMinInterval;
ConVar ITDirectorSpecialRespawnInterval;
ConVar ITDirectorSpecialBattlefieldRespawnInterval;
ConVar ITDirectorSpecialFinaleOfferLength;
ConVar ITDirectorSpecialInitialSpawnDelayMax;
ConVar ITDirectorSpecialInitialSpawnDelayMaxExtra;
ConVar ITDirectorSpecialInitialSpawnDelayMin;
ConVar ITDirectorSpecialOriginalOfferLength;

ConVar SISmokerHealth;
ConVar SIHunterHealth;
ConVar SIBoomerHealth;
ConVar SISpitterHealth;
ConVar SIChargerHealth;
ConVar SIJockeyHealth;

char gameMode[16];
char gameName[16];
bool L4D1;
bool InfectedAllowed;

ConVar SurvivorLimit;
ConVar InfectedLimit;

ConVar L4DInfectedLimit;
ConVar L4DSurvivorLimit;
ConVar AfkTimeout;
ConVar GhostDelayMax;
ConVar L4DHooks;
ConVar L4DTown;
ConVar GameType;
ConVar Difficulty;
ConVar SmokerHealth;
ConVar BoomerHealth;
ConVar HunterHealth;
ConVar SpitterHealth;
ConVar JockeyHealth;
ConVar ChargerHealth;
ConVar TankHealth;
ConVar SurvMaxIncap;
ConVar PainPillsDR;
ConVar MinionLimit;
ConVar szMobSpawnFinale;
ConVar szMobSpawnMax;
ConVar szMobSpawnMin;
ConVar szMobMega; 
ConVar szMobLimit;
ConVar szBGLimit;
ConVar intvlMobSpawnMaxEasy;
ConVar intvlMobSpawnMaxNormal;
ConVar intvlMobSpawnMaxHard;
ConVar intvlMobSpawnMaxExpert;
ConVar intvlMobSpawnMinEasy;
ConVar intvlMobSpawnMinNormal;
ConVar intvlMobSpawnMinHard;
ConVar intvlMobSpawnMinExpert;
ConVar intvlMobMegaSpawnMax;
ConVar intvlMobMegaSpawnMin;
ConVar directSpecialRespawn;
ConVar directSpecialFinalRespawn;
ConVar directSpecialFinalOffer;
ConVar directSpecialSpawnDelayMax;
ConVar directSpecialSpawnDelayMaxExtra;
ConVar directSpecialSpawnDelayMin;
ConVar directSpecialOriginalOffer;

ConVar ExtraFirstAid;
ConVar FinaleExtraFirstAid;
ConVar KillRes;
ConVar RespawnJoin;
ConVar MoreSiBotsVersus;
ConVar AfkMode;
ConVar AutoJoin;
ConVar Management;

ConVar AutoDifficulty;
ConVar TankHpMulti;
ConVar SiHpMulti;
ConVar CiSpMulti;
ConVar SiSpMore;
ConVar SiSpMoreDelay;
ConVar ITHordeTimers;
ConVar cvar_minsurvivor;

Handle MedkitTimer					= null;
Handle SubDirector					= null;
Handle BotsUpdateTimer				= null;
Handle DifficultyTimer				= null;
Handle TeamPanelTimer[MAXPLAYERS+1];
Handle AfkTimer[MAXPLAYERS+1];

bool MedkitsGiven = false;
bool RoundStarted = false;

bool  CheckIdle[MAXPLAYERS+1];
int   iButtons[MAXPLAYERS+1];
float fEyeAngles[MAXPLAYERS+1][3];

float SiTimes[MAXPLAYERS+1] = 0.0;

int MaxSpecials = 2;

StringMap SteamIDs;

public Plugin myinfo =
{
	name        = "Super Versus Reloaded",
	author      = "DDRKhat, Marcus101RR, Merudo, Foxhound27, Senip, RainyDagger, Shao",
	description = "Allows up to 32 players on Left 4 Dead.",
	version     = PLUGIN_VERSION,
	url         = "https://forums.alliedmods.net/showthread.php?p=2704058#post2704058"
}

// *********************************************************************************
// METHODS FOR GAME START & END
// *********************************************************************************
public void OnPluginStart()
{
	GetGameFolderName(gameName, sizeof(gameName));
	L4D1 = StrEqual(gameName, "left4dead", false);

	CreateConVar("sm_superversus_version", PLUGIN_VERSION, "L4D Super Versus", CVAR_FLAGS|FCVAR_DONTRECORD);
	
	L4DSurvivorLimit = FindConVar("survivor_limit");
	L4DInfectedLimit = FindConVar("z_max_player_zombies");
	SurvivorLimit = CreateConVar("l4d_survivor_limit", "4", "Maximum amount of survivors", CVAR_FLAGS,true, 1.00, true, 24.00);
	InfectedLimit = CreateConVar("l4d_infected_limit", "4", "Max amount of infected (will not affect bots)", CVAR_FLAGS, true, 4.00, true, 24.00);
	cvar_minsurvivor = CreateConVar("l4d_static_minimum_survivor", "4", "Static minimum amount of team survivor", CVAR_FLAGS, true, 4.00, true, 24.00);

	// Remove limits for survivor/infected
	SetConVarBounds(L4DSurvivorLimit, ConVarBound_Upper, true, 24.0);
	SetConVarBounds(L4DInfectedLimit, ConVarBound_Upper, true, 24.0);
	HookConVarChange(InfectedLimit, OnInfectedChanged);	HookConVarChange(L4DInfectedLimit, OnInfectedChanged);
	HookConVarChange(SurvivorLimit, OnSurvivorChanged);	HookConVarChange(L4DSurvivorLimit, OnSurvivorChanged);

	TankVersusHealth = CreateConVar("tank_health_versus", "6000.0", "Sets the default health for a tank on Versus.", CVAR_FLAGS);
	TankExpertHealth = CreateConVar("tank_health_expert", "8000.0", "Sets the default health for a tank on Expert.", CVAR_FLAGS);
	TankAdvancedHealth = CreateConVar("tank_health_advanced", "8000.0", "Sets the default health for a tank on Hard.", CVAR_FLAGS);
	TankNormalHealth = CreateConVar("tank_health_normal", "4000.0", "Sets the default health for a tank on Normal.", CVAR_FLAGS);
	TankEasyHealth = CreateConVar("tank_health_easy", "3000.0", "Sets the default health for a tank on Easy.", CVAR_FLAGS);

	CIMobSpawnFinaleSize = CreateConVar("ci_mob_spawn_finale_size", "20.0", "Sets the finale mob size.", CVAR_FLAGS);
	CIMobSpawnMaxSize = CreateConVar("ci_mob_spawn_max_size", "30.0", "Sets the max mob size.", CVAR_FLAGS);
	CIMobSpawnMinSize = CreateConVar("ci_mob_spawn_min_size", "10.0", "Sets the min mob size.", CVAR_FLAGS);
	CIMegaMobSize = CreateConVar("ci_mega_mob_size", "50.0", "Sets the mega mob size.", CVAR_FLAGS);
	CICommonMobLimit = CreateConVar("ci_common_mob_limit_size", "30.0", "Sets the max mobs able to spawn.", CVAR_FLAGS);
	CIBackgroundMobSize = CreateConVar("ci_background_mob_size", "20.0", "Sets the mobs spawned in the background of an area.", CVAR_FLAGS);
	
	ITMobSpawnMaxIntervalEasy = CreateConVar("it_mob_spawn_max_interval_easy", "240.0", "", CVAR_FLAGS);
	ITMobSpawnMaxIntervalNormal = CreateConVar("it_mob_spawn_max_interval_normal", "180.0", "", CVAR_FLAGS);
	ITMobSpawnMaxIntervalHard = CreateConVar("it_mob_spawn_max_interval_hard", "180.0", "", CVAR_FLAGS);
	ITMobSpawnMaxIntervalExpert = CreateConVar("it_mob_spawn_max_interval_expert", "180.0", "", CVAR_FLAGS);
	ITMobSpawnMinIntervalEasy = CreateConVar("it_mob_spawn_min_interval_easy", "120.0", "", CVAR_FLAGS);
	ITMobSpawnMinIntervalNormal = CreateConVar("it_mob_spawn_min_interval_normal", "90.0", "", CVAR_FLAGS);
	ITMobSpawnMinIntervalHard = CreateConVar("it_mob_spawn_min_interval_hard", "90.0", "", CVAR_FLAGS);
	ITMobSpawnMinIntervalExpert = CreateConVar("it_mob_spawn_min_interval_expert", "90.0", "", CVAR_FLAGS);
	ITMegaMobSpawnMaxInterval = CreateConVar("it_mega_mob_spawn_max_interval", "900.0", "", CVAR_FLAGS);
	ITMegaMobSpawnMinInterval = CreateConVar("it_mega_mob_spawn_min_interval", "420.0", "", CVAR_FLAGS);
	ITDirectorSpecialRespawnInterval = CreateConVar("it_director_special_respawn_interval", "45.0", "", CVAR_FLAGS);
	ITDirectorSpecialBattlefieldRespawnInterval = CreateConVar("it_director_special_battlefield_respawn_interval", "10.0", "", CVAR_FLAGS);
	ITDirectorSpecialFinaleOfferLength = CreateConVar("it_director_special_finale_offer_length", "10.0", "", CVAR_FLAGS);
	ITDirectorSpecialInitialSpawnDelayMax = CreateConVar("it_director_special_initial_spawn_delay_max", "60.0", "", CVAR_FLAGS);
	ITDirectorSpecialInitialSpawnDelayMaxExtra = CreateConVar("it_director_special_initial_spawn_delay_max_extra", "180.0", "", CVAR_FLAGS);
	ITDirectorSpecialInitialSpawnDelayMin = CreateConVar("it_director_special_initial_spawn_delay_min", "30.0", "", CVAR_FLAGS);
	ITDirectorSpecialOriginalOfferLength = CreateConVar("it_director_special_original_offer_length", "30.0", "", CVAR_FLAGS);

	SISmokerHealth = CreateConVar("si_smoker_health", "250.0", "", CVAR_FLAGS);
	SIHunterHealth = CreateConVar("si_hunter_health", "250.0", "", CVAR_FLAGS);
	SIBoomerHealth = CreateConVar("si_boomer_health", "50.0", "", CVAR_FLAGS);
	SISpitterHealth = CreateConVar("si_spitter_health", "100.0", "", CVAR_FLAGS);
	SIChargerHealth = CreateConVar("si_charger_health", "600.0", "", CVAR_FLAGS);
	SIJockeyHealth = CreateConVar("si_jockey_health", "325.0", "", CVAR_FLAGS);

	KillRes = CreateConVar("l4d_killreservation","0","Should we clear Lobby reservation? (Requires Left 4 Downtown/Left 4 DHooks.)", CVAR_FLAGS,true,0.0,true,1.0);
	ExtraFirstAid = CreateConVar("l4d_extra_first_aid", "1" , "Allow extra first aid kits for extra players. 0: No extra kits. 1: One extra kit per player above four.", CVAR_FLAGS, true, 0.0, true, 1.0);
	FinaleExtraFirstAid = CreateConVar("l4d_finale_extra_first_aid", "1" , "Allow extra first aid kits for extra players when the finale is activated. 0: No extra kits. 1: One extra kit per player above four.", CVAR_FLAGS, true, 0.0, true, 1.0);
	
	RespawnJoin = CreateConVar("l4d_respawn_on_join", "1" , "Respawn alive when joining as an extra survivor? 0: No, 1: Yes (first time only)", CVAR_FLAGS, true, 0.0, true, 1.0);
	MoreSiBotsVersus =  CreateConVar("l4d_versus_si_more", "1" , "If less infected players than l4d_infected_limit in versus/scavenge, spawn SI bots?", CVAR_FLAGS, true, 0.0, true, 1.0);
	AfkMode =  CreateConVar("l4d_versus_afk", "1" , "If player is afk on versus, 0: Do nothing, 1: Become idle, 2: Become spectator, 3: Kicked", CVAR_FLAGS, true, 0.0, true, 3.0);
	AutoJoin = CreateConVar("l4d_autojoin", "2" , "Once a player connects, 3: Put them in Spectate. 2: In Co-op will put them on Survivor team, In Versus, will put them on a random team. 1: Show teammenu, 0: Do nothing", CVAR_FLAGS, true, 0.0, true, 3.0);
	Management = CreateConVar("l4d_management", "3", "3: Enable teammenu & commands, 2: commands only, 1: !infected,!survivor,!join only, 0: Nothing", CVAR_FLAGS, true, 0.0, true, 4.0);
	
	AutoDifficulty = CreateConVar("director_auto_difficulty", "1", "Change Difficulty", CVAR_FLAGS, true, 0.0, true, 1.0);
	TankHpMulti    = CreateConVar("director_tank_hpmulti","0.25","Tanks HP Multiplier (multi*(survivors-4)). Requires director_auto_difficulty 1", CVAR_FLAGS,true,0.00,true,1.00);
	SiHpMulti      = CreateConVar("director_si_hpmulti","0.00","SI HP Multiplier (multi*(survivors-4)). Requires director_auto_difficulty 1", CVAR_FLAGS,true,0.00,true,1.00);
	CiSpMulti      = CreateConVar("director_ci_multi","0.25","Infected spawning rate Multiplier (multi*(survivors-4)). Requires director_auto_difficulty 1", CVAR_FLAGS,true,0.00,true,1.00);
	SiSpMore       = CreateConVar("director_si_more","1","In coop, spawn 1 more SI per extra player? Requires director_auto_difficulty 1 and Left 4 Downtown/Left 4 DHooks to work.", CVAR_FLAGS,true,0.0,true,1.0);
	SiSpMoreDelay  = CreateConVar("director_si_more_delay","5","Delay in seconds added to z_ghost_delay_max for SI bots spawning in versus", CVAR_FLAGS);
	ITHordeTimers  = CreateConVar("director_horde_timers","1","Choose whether CiSpMulti affects Mob intervals.", CVAR_FLAGS, true, 0.0, true, 1.0);
	
	//Cache CVArs
	AfkTimeout = FindConVar("director_afk_timeout");
	GhostDelayMax = FindConVar("z_ghost_delay_max");
	L4DHooks = FindConVar("left4dhooks_version");
	L4DTown = FindConVar("left4downtown_version");
	GameType = FindConVar("mp_gamemode");
	Difficulty = FindConVar("z_difficulty");
	SmokerHealth = FindConVar("z_gas_health");
	BoomerHealth = FindConVar("z_exploding_health");
	HunterHealth = FindConVar("z_hunter_health");
	SpitterHealth = FindConVar("z_spitter_health");
	JockeyHealth = FindConVar("z_jockey_health");
	ChargerHealth = FindConVar("z_charger_health");
	TankHealth = FindConVar("z_tank_health");
	SurvMaxIncap = FindConVar("survivor_max_incapacitated_count");
	PainPillsDR = FindConVar("pain_pills_decay_rate");
	MinionLimit = FindConVar("z_minion_limit");
	szMobSpawnFinale = FindConVar("z_mob_spawn_finale_size");
	szMobSpawnMax = FindConVar("z_mob_spawn_max_size");
	szMobSpawnMin = FindConVar("z_mob_spawn_min_size");
	szMobMega = FindConVar("z_mega_mob_size"); 
	szMobLimit = FindConVar("z_common_limit");
	szBGLimit = FindConVar("z_background_limit");
	intvlMobSpawnMaxEasy = FindConVar("z_mob_spawn_max_interval_easy");
	intvlMobSpawnMaxNormal = FindConVar("z_mob_spawn_max_interval_normal");
	intvlMobSpawnMaxHard = FindConVar("z_mob_spawn_max_interval_hard");
	intvlMobSpawnMaxExpert = FindConVar("z_mob_spawn_max_interval_expert");
	intvlMobSpawnMinEasy = FindConVar("z_mob_spawn_min_interval_easy");
	intvlMobSpawnMinNormal = FindConVar("z_mob_spawn_min_interval_normal");
	intvlMobSpawnMinHard = FindConVar("z_mob_spawn_min_interval_hard");
	intvlMobSpawnMinExpert = FindConVar("z_mob_spawn_min_interval_expert");
	intvlMobMegaSpawnMax = FindConVar("z_mega_mob_spawn_max_interval");
	intvlMobMegaSpawnMin = FindConVar("z_mega_mob_spawn_min_interval");
	directSpecialRespawn = FindConVar("director_special_respawn_interval");
	directSpecialFinalRespawn = FindConVar("director_special_battlefield_respawn_interval");
	directSpecialFinalOffer = FindConVar("director_special_finale_offer_length");
	directSpecialSpawnDelayMax = FindConVar("director_special_initial_spawn_delay_max");
	directSpecialSpawnDelayMaxExtra = FindConVar("director_special_initial_spawn_delay_max_extra");
	directSpecialSpawnDelayMin = FindConVar("director_special_initial_spawn_delay_min");
	directSpecialOriginalOffer = FindConVar("director_special_original_offer_length");
	
	RegConsoleCmd("sm_join", Join_Game, "Join Survivor or Infected team");
	RegConsoleCmd("sm_survivor", Join_Survivor, "Join Survivor Team");
	RegConsoleCmd("sm_infected", Join_Infected, "Join Infected Team");
	RegConsoleCmd("sm_spectate", Join_Spectator, "Join Spectator Team");
	RegConsoleCmd("sm_afk", GO_AFK, "Go Idle (Survivor) or Join Spectator Team (Infected)");
	RegConsoleCmd("sm_teams", TeamMenu, "Opens Team Panel with Selection");
	RegConsoleCmd("sm_changeteam", TeamMenu, "Opens Team Panel with Selection");
	RegAdminCmd("sm_createplayer", Create_Player, ADMFLAG_CONVARS, "Create Survivor Bot");

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_bot_replace", Event_BotReplacedPlayer);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_Post);
	HookEvent("player_left_checkpoint", Event_PlayerLeftStartArea, EventHookMode_Post);
	HookEvent("player_afk", Event_PlayerWentAFK, EventHookMode_Pre);
	HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
	HookEvent("difficulty_changed", Event_Difficulty, EventHookMode_Post);
	HookEvent("finale_start", Event_FinaleStart, EventHookMode_Post);

	AddCommandListener(Cmd_spec_next, "spec_next");
	
	SteamIDs = new StringMap();

	AutoExecConfig(true, "l4d_superversus");
}

public void OnInfectedChanged (Handle c, const char[] o, const char[] n)  {L4DInfectedLimit.IntValue = InfectedLimit.IntValue;}
public void OnSurvivorChanged (Handle c, const char[] o, const char[] n)  {L4DSurvivorLimit.IntValue = SurvivorLimit.IntValue;}


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){MarkNativeAsOptional("L4D_LobbyUnreserve"); return APLRes_Success;}

// ------------------------------------------------------------------------
// Return true if lobby unreserve and SiSpMore is supported
// ------------------------------------------------------------------------
bool l4dt()
{
	if(L4DHooks != null || L4DTown != null)
	{
		return true;
	}
	return false;
} // Is Left4DHooks OR Left 4 Downtown 1/2 loaded? 

public void OnMapStart() 
{
	GameType.GetString(gameMode, sizeof(gameMode));
	InfectedAllowed = AreInfectedAllowed();
}

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
public void OnMapEnd()
{
	GameEnd();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	GameEnd();
}

// ------------------------------------------------------------------------
//  Clean up the timers at the game end
// ------------------------------------------------------------------------
void GameEnd()
{
	delete SubDirector;
	delete MedkitTimer;
	delete BotsUpdateTimer;
	delete DifficultyTimer;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		delete TeamPanelTimer[i];
		delete AfkTimer[i];
		TakeOver(i);
	}

	// Reset SteamIDs, so previous players who join next round can respawn alive
	SteamIDs.Clear();
	
	RoundStarted = false;
}

// ------------------------------------------------------------------------
// Event_RoundStart
// ------------------------------------------------------------------------
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	MedkitsGiven = false;
	RoundStarted = true;
}

// ------------------------------------------------------------------------
//  MedKit timer. Used to spawn extra medkits in safehouse
// ------------------------------------------------------------------------
public Action Timer_SpawnExtraMedKit(Handle hTimer)
{
	MedkitTimer = null;

	int client = GetAnyAliveSurvivor();
	int amount = GetSurvivorTeam() - 4;
	
	if(amount > 0 && client > 0)
	{
		for(int i = 1; i <= amount; i++)
		{
			CheatCommand(client, "give", "first_aid_kit", "");
		}
	}
}
// ------------------------------------------------------------------------
//  Spawn extra medkits at the finale based on survivors on the team after the finale starts.
// ------------------------------------------------------------------------
public void Event_FinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	if(FinaleExtraFirstAid.BoolValue)
	{
		int client = GetAnyAliveSurvivor();
		int amount = GetSurvivorTeam() - 4;

		if(amount > 0 && client > 0)
		{
			for(int i = 1; i <= amount; i++)
			{
			CheatCommand(client, "give", "first_aid_kit", "");
			}
		}
	}
}
// ------------------------------------------------------------------------
// FinaleEnd() Thanks to Damizean for smarter method of detecting safe survivors.
// ------------------------------------------------------------------------
public void Event_FinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
	int edict_index = FindEntityByClassname(-1, "info_survivor_position");
	if (edict_index != -1)
	{
		float pos[3];
		GetEntPropVector(edict_index, Prop_Send, "m_vecOrigin", pos);
		for(int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientConnected(i)) continue;
			if (!IsClientInGame(i)) continue;
			if (GetClientTeam(i) != TEAM_SURVIVOR) continue;
			if (!IsPlayerAlive(i)) continue;
			if (GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) == 1) continue;
			TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

// *********************************************************************************
// METHODS RELATED TO PLAYER/BOT SPAWN AND KICK
// *********************************************************************************

// ------------------------------------------------------------------------
//  Each time a survivor spawns, setup timer to kick / spawn bots a bit later
// ------------------------------------------------------------------------
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	ADPlayerSpawn(event);
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	// Adds very brief invulnerability to spawned SI infected bots in versus/scavenge. Otherwise they keep respawning dead
	if (GetClientTeam(client) == TEAM_INFECTED && InfectedAllowed && MoreSiBotsVersus.BoolValue && IsFakeClient(client)) SetGodMode(client, 0.1);
	
	// Each time a new survivor spawns, check difficulty & record steam id (to prevent free respawning)
	if (GetClientTeam(client) == TEAM_SURVIVOR)
	{
		// Reset the bot check timer, if one exists	
		delete BotsUpdateTimer;
		BotsUpdateTimer = CreateTimer(2.0, Timer_BotsUpdate);
		
		if (!IsFakeClient(client) && !InfectedAllowed && IsFirstTime(client))
			RecordSteamID(client); // Record SteamID of player.
			
		SetGhostStatus(client, false); // Prevents invinsible & invisible survivor bug
	}
	
	//  If Si bot spawns, remove oldest Si in queue
	if (IsFakeClient(client) && GetClientTeam(client) == TEAM_INFECTED)
	{
		int OldestSi = GetOldestSi();
		if (OldestSi != -1) SiTimes[OldestSi] == 0.0;
	}
}


public int GetClientZC(int client)
{

	if (!IsValidEntity(client) || !IsValidEdict(client))
	{
		return 0;
	}
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}

////////////////////////////////////////////////////////////////////

// ------------------------------------------------------------------------
//  When a tank spawns, Its health is factored by difficultyHP times ExtraPlayers times the Given percent in the CFG.
// ------------------------------------------------------------------------

public Action Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(AutoDifficulty.BoolValue) CreateTimer(1.0, SetTankHp, GetClientOfUserId(event.GetInt("userid")), TIMER_FLAG_NO_MAPCHANGE );
}

////////////////////////////////////////////////////////////////////

int ADPlayerSpawn(Event event)
{
	if(!AutoDifficulty.BoolValue) return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client) && GetClientTeam(client) == TEAM_INFECTED) switch(GetClientZC(client))
	{
		case ZC_SMOKER: SetEntityHealth(client, SmokerHealth.IntValue);
		case ZC_BOOMER: SetEntityHealth(client, BoomerHealth.IntValue);
		case ZC_HUNTER: SetEntityHealth(client, HunterHealth.IntValue);
		case ZC_SPITTER: SetEntityHealth(client, SpitterHealth.IntValue);
		case ZC_JOCKEY: SetEntityHealth(client, JockeyHealth.IntValue);
		case ZC_CHARGER: SetEntityHealth(client, ChargerHealth.IntValue);
	}
}

////////////////////////////////////////////////////////////////////


public Action SetTankHp(Handle hTimer, int client)
{

SetEntProp(client,Prop_Send,"m_iHealth", TankHealth.IntValue);
SetEntProp(client,Prop_Send,"m_iMaxHealth", TankHealth.IntValue);
SetEntityHealth(client, TankHealth.IntValue);
 
}


////////////////////////////////////////////////////////////////////

bool IsValidClient(int client)
{
	if (! (1 <= client <= MaxClients) || !IsClientInGame(client)) return false;

	return true;
}

////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////


// ------------------------------------------------------------------------
// If player disconnect, set timer to spawn/kick bots as needed. Manages difficulty on survivor bot disconnect.
// ------------------------------------------------------------------------
public void OnClientDisconnect(int client)
{
	if(AutoDifficulty.BoolValue && IsFakeClient(client) && GetClientTeam(client) == TEAM_SURVIVOR) DifficultyTimer = CreateTimer(5.0, Timer_Difficulty);

	delete AfkTimer[client];				//	Clean up Afk timer
	delete TeamPanelTimer[client];			//	Clean up Panel timer
	CheckIdle[client] = false;				//  Turn off idle check

	if(RoundStarted)			// if not bot or during transition
	{
		// Reset the timer, if one exists
		delete BotsUpdateTimer;
		BotsUpdateTimer = CreateTimer(1.0, Timer_BotsUpdate);	// re-update the bots
	}
}

// ------------------------------------------------------------------------
// Bots are kicked/spawned after every survivor spawned and every player joined
// ------------------------------------------------------------------------
public Action Timer_BotsUpdate(Handle hTimer)
{
	BotsUpdateTimer = null;

	if (AreAllInGame() == true)
	{

		SpawnCheck();

		// Give medkit (start of round)
		if (MedkitTimer == null && !MedkitsGiven && ExtraFirstAid.BoolValue)
		{
			MedkitsGiven = true;
			MedkitTimer = CreateTimer(2.0, Timer_SpawnExtraMedKit);
		}
		// Update the difficulty
		delete DifficultyTimer;
		if (AutoDifficulty.BoolValue) DifficultyTimer = CreateTimer(5.0, Timer_Difficulty);
	}
	else
	{
		BotsUpdateTimer = CreateTimer(1.0, Timer_BotsUpdate); // if not everyone joined, delay update
	}
}

// ------------------------------------------------------------------------
// Update the difficulty on difficulty change
// ------------------------------------------------------------------------
public void Event_Difficulty(Event event, const char[] name, bool dontBroadcast)
{
	if (AutoDifficulty.BoolValue) DifficultyTimer = CreateTimer(5.0, Timer_Difficulty);
}

// ------------------------------------------------------------------------
// Check the # of survivors, and kick/spawn bots as needed
// ------------------------------------------------------------------------
void SpawnCheck()
{
	if(RoundStarted != true)  return;      // if during transition, don't do anything
	
	int iSurvivor       = GetSurvivorTeam();
	//int iHumanSurvivor  = InfectedAllowed ? GetTeamPlayers(TEAM_SURVIVOR, false) : GetHumanCount();  // survivors excluding bots but including idles. If coop, counts spectators too (may be idles)
	//int iSurvivorLim    = SurvivorLimit.IntValue;
	//int iSurvivorMax    = iHumanSurvivor  >  iSurvivorLim ? iHumanSurvivor  : iSurvivorLim ;
	
	// iSurvivorMax is the maximum # of survivor we allow - we never kick human survivors

	if (iSurvivor >= cvar_minsurvivor.IntValue)  return;
	for(; iSurvivor < cvar_minsurvivor.IntValue; iSurvivor++) SpawnFakeSurvivorClient();
}

// ------------------------------------------------------------------------
// Kick an unused survivor bot
// ------------------------------------------------------------------------

stock bool IsValidSurvivorBot(int client)
{
	if (!client) return false;
	if (!IsClientInGame(client)) return false;
	if (!IsFakeClient(client)) return false;
	if (GetClientTeam(client) != TEAM_SURVIVOR) return false;
	return true;
}
// ------------------------------------------------------------------------
// Spawn a survivor bot
// ------------------------------------------------------------------------

bool SpawnFakeSurvivorClient()
{
	int ClientsCount = GetSurvivorTeam();
	
	bool fakeclientKicked = false;
	
	// create fakeclient
	int fakeclient = 0;

	if (ClientsCount < SurvivorLimit.IntValue)
	{
		fakeclient = CreateFakeClient("SurvivorBot");
	}
	
	// if entity is valid
	if (fakeclient != 0)
	{
		// move into survivor team
		ChangeClientTeam(fakeclient, TEAM_SURVIVOR);
		
		// check if entity classname is survivorbot
		if (DispatchKeyValue(fakeclient, "classname", "survivorbot") == true)
		{
			// spawn the client
			if (DispatchSpawn(fakeclient) == true)
			{	
				// kick the fake client to make the bot take over
				CreateTimer(DELAY_KICK_FAKECLIENT, Timer_KickFakeBot, fakeclient, TIMER_REPEAT);
				fakeclientKicked = true;
			}
		}			
		// if something went wrong, kick the created FakeClient
		if (fakeclientKicked == false) KickClient(fakeclient, "Kicking FakeClient");
	}
	return fakeclientKicked;
}


// ------------------------------------------------------------------------
// If lobby full, unreserve it. Autojoin survivors if coop & spectator
// ------------------------------------------------------------------------
public void OnClientPostAdminCheck(int client)
{
	// If lobby is full, KillRes is true and l4dt is present, unreserve lobby
	if(KillRes.BoolValue && IsServerLobbyFull() && l4dt())
	{
		L4D_LobbyUnreserve();
	}
	
	if (IsFakeClient(client)) return;
	
	if (GetClientTeam(client) <= TEAM_SPECTATOR) // Sets on a random team in versus if lobby is 8+ player. l4d_autojoin 2 required.
	{
		CreateTimer(5.0, Timer_AutoJoinTeam, GetClientUserId(client));
	}
	if (GetClientTeam(client) == TEAM_SURVIVOR && !InfectedAllowed) // Sets on survivor team in coop regardless of the character without creating an extra survivor that could be dead on connection. l4d_autojoin 2 required.
	{
		CreateTimer(0.5, Timer_AutoJoinTeam, GetClientUserId(client));
	}
	delete AfkTimer[client];
}

// ------------------------------------------------------------------------
// If connect as spectator, either auto-join survivor or show team menu
// ------------------------------------------------------------------------
public Action Timer_AutoJoinTeam(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	// If joined the game already or not valid, don't do anything
	if (!client || !IsClientInGame(client) || IsFakeClient(client) || GetBotOfIdle(client)) return;
	
	if (BotsUpdateTimer != null || !RoundStarted || !AreAllInGame() || GetClientTeam(client) == 0)
	{
		CreateTimer(1.0, Timer_AutoJoinTeam, GetClientUserId(client)); // if during transition, delay autojoin
	}
	else
	{
		if(AutoJoin.IntValue > 0)
		{
			if(AutoJoin.IntValue == 3) FakeClientCommand(client, "sm_spectate");  // Autojoin Spectate
			else if(!InfectedAllowed && AutoJoin.IntValue == 2) FakeClientCommand(client, "sm_survivor"); // Autojoin Survivor
			else if(AutoJoin.IntValue == 2) FakeClientCommand(client, "sm_join"); // Autojoin random team
			else if(AutoJoin.IntValue == 1) FakeClientCommand(client, "sm_teams"); // Show team selection menu
		}
	}
}

// *********************************************************************************
// IDLE FIX
// *********************************************************************************

// ------------------------------------------------------------------------
// If player goes AFK, activate idle bug check
// ------------------------------------------------------------------------
public Action Event_PlayerWentAFK(Event event, const char[] name, bool dontBroadcast)
{
	// Event is triggered when a player goes AFK
	int client = GetClientOfUserId(event.GetInt("player"));
	CheckIdle[client] = true;
}

// ------------------------------------------------------------------------
// When survivor bot replace player AND player went afk, trigger fix
// ------------------------------------------------------------------------
public Action Event_BotReplacedPlayer(Event event, const char[] name, bool dontBroadcast)
{
	// Event is triggered when a bot takes over a player
	int player	= GetClientOfUserId(event.GetInt("player"));
	int bot		= GetClientOfUserId(event.GetInt("bot"));

	if (GetClientTeam(bot) == TEAM_SURVIVOR) CreateTimer(DELAY_KICK_NONEEDBOT, Timer_KickNoNeededBot, bot);
	
	if (IsFakeClient(player)) return; 		// if "player" is a bot, don't do anything (side effect of creating new bots)

	// Create a datapack as we are moving 2+ pieces of data through a timer
	if(player > 0 && IsClientInGame(player) && GetClientTeam(bot)==TEAM_SURVIVOR) 
	{
		Handle datapack = CreateDataPack();
		WritePackCell(datapack, player);
		WritePackCell(datapack, bot);
		CreateTimer(0.2, Timer_ActivateFix, datapack, TIMER_FLAG_NO_MAPCHANGE);
	}
}

// ------------------------------------------------------------------------
// Fix the idle bug by setting pseudo idle mode
// ------------------------------------------------------------------------
public Action Timer_ActivateFix(Handle Timer, any datapack)
{
	// Reset the data pack
	ResetPack(datapack);

	// Retrieve values from datapack
	int player = ReadPackCell(datapack);
	int bot = ReadPackCell(datapack);

	// If  player left game, is not spectator, or is correctly idle, skip the fix
	// If  bot is occupied (should not happen unless something happened in .2 sec) , try to get another
	
	if (!IsClientInGame(player) || GetClientTeam(player) != TEAM_SPECTATOR || GetBotOfIdle(player) ||  IsFakeClient(player)) CheckIdle[player] = false;	
	if (!IsBotValid(bot) || GetClientTeam(bot) != TEAM_SURVIVOR) bot = GetAnyValidSurvivorBot(); if (bot < 1) CheckIdle[player] = false; 

	// If the player went AFK and failed, continue on
	if(CheckIdle[player])
	{
		CheckIdle[player] = false;
		SetHumanIdle(bot, player);
	}
}

// ------------------------------------------------------------------------
// When player dies, forces takeover of the bot
// ------------------------------------------------------------------------
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// Event is triggered when a player dies
	int client = GetClientOfUserId(event.GetInt("userid"));
	TakeOver(client);
}

void TakeOver(int bot)
{
	if(bot > 0 && IsClientInGame(bot) &&  IsFakeClient(bot) && GetClientTeam(bot) == TEAM_SURVIVOR && GetIdlePlayer(bot))
	{
		int idleplayer = GetIdlePlayer(bot);
		SetHumanIdle(bot, idleplayer);
		TakeOverBot(idleplayer);		
	}
}

// ------------------------------------------------------------------------
// Store vision angle & button, if changed reset afk timer
// ------------------------------------------------------------------------
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsFakeClient(client)) return;

	if (InfectedAllowed && AfkMode.BoolValue && GetClientTeam(client) > TEAM_SPECTATOR && IsPlayerAlive(client) && RoundStarted)
	{	
		if ( (iButtons[client] != buttons) ||  (FloatAbs(angles[0] - fEyeAngles[client][0]) > 2.0) || (FloatAbs(angles[1] - fEyeAngles[client][1]) > 2.0) || (FloatAbs(angles[2] - fEyeAngles[client][2]) > 2.0) ) 
		{
			delete AfkTimer[client];  // Reset timer
		}
		if (AfkTimer[client] == null) AfkTimer[client] = CreateTimer(AfkTimeout.FloatValue, Timer_AFK, client); 
		
		iButtons[client]   = buttons;
		fEyeAngles[client] = angles; 
	} else delete AfkTimer[client];
}

// ------------------------------------------------------------------------
// Reset timer if client say something in chat
// ------------------------------------------------------------------------
public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) // Player Chat
{
	if (!client || IsFakeClient(client)) return;
	
	delete AfkTimer[client];	
	
	if (InfectedAllowed && AfkMode.BoolValue && GetClientTeam(client) > TEAM_SPECTATOR && IsPlayerAlive(client) && RoundStarted)
	{
		AfkTimer[client] = CreateTimer(AfkTimeout.FloatValue, Timer_AFK, client);
	}
}

// ------------------------------------------------------------------------
// If afk timer ran out, deal with afk client
// ------------------------------------------------------------------------
public Action Timer_AFK(Handle Timer, int client)
{
	AfkTimer[client] = null;

	if (IsClientInGame(client) && InfectedAllowed && AfkMode.BoolValue && GetClientTeam(client) > TEAM_SPECTATOR && IsPlayerAlive(client) && RoundStarted)
	{
		if ( GetTeamPlayers(GetClientTeam(client), false) > 0) // if more than 1 human player on the team
		{
			if (AfkMode.IntValue == 1) FakeClientCommand(client, "sm_afk");
			if (AfkMode.IntValue == 2) FakeClientCommand(client, "sm_spectate");
			if (AfkMode.IntValue == 3) KickClient(client, "Afk");
		}
	}
}

// *********************************************************************************
// COMMANDS FOR JOINING TEAMS
// *********************************************************************************

// ------------------------------------------------------------------------
// If press left mouse button as spectator, show menu to join game. Useful in case of idle bug
// ------------------------------------------------------------------------
public Action Cmd_spec_next(int client, char[] command, int argc)
{
	if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR && !GetBotOfIdle(client))
	{
		FakeClientCommand(client, "sm_teams");
	}
	return Plugin_Continue;	
}

// ------------------------------------------------------------------------
// Join survivor or infected
// ------------------------------------------------------------------------
public Action Join_Game(int client, int args)
{
	if (!Management.BoolValue) return Plugin_Continue;

	if (!InfectedAllowed || GetBotOfIdle(client) || GetClientTeam(client) == TEAM_SURVIVOR) FakeClientCommand(client,"sm_survivor"); 
	else if (GetClientTeam(client) == TEAM_INFECTED) FakeClientCommand(client,"sm_infected");
	else if (InfectedLimit.IntValue <= GetTeamPlayers(TEAM_INFECTED, false) && SurvivorLimit.IntValue <= GetTeamPlayers(TEAM_SURVIVOR, false))
	{
		PrintToChat(client, "Both teams are full.");
	}
	else if (InfectedLimit.IntValue <= GetTeamPlayers(TEAM_INFECTED, false)) FakeClientCommand(client,"sm_survivor");
	else if (SurvivorLimit.IntValue <= GetTeamPlayers(TEAM_SURVIVOR, false)) FakeClientCommand(client,"sm_infected");
	else if (GetTeamPlayers(TEAM_INFECTED, false) > GetTeamPlayers(TEAM_SURVIVOR, false) ) FakeClientCommand(client,"sm_survivor");
	else if (GetTeamPlayers(TEAM_INFECTED, false) < GetTeamPlayers(TEAM_SURVIVOR, false) ) FakeClientCommand(client,"sm_infected");
	else if (GetRandomInt(0, 1)) FakeClientCommand(client,"sm_survivor");
	else FakeClientCommand(client,"sm_infected");
	return Plugin_Handled;
}

public Action Join_Spectator(int client, int args)
{
	if (Management.IntValue < 2) return Plugin_Continue;

	ChangeClientTeam(client,TEAM_SPECTATOR);
	return Plugin_Handled;
}

public Action Join_Survivor(int client, int args) {

	if (CountAvailableBots(TEAM_SURVIVOR) == 0) {
		Create_Player(client, 0);
		Join_Survivor2(client, 0);
	} else if (CountAvailableBots(TEAM_SURVIVOR) > 0) {

		Join_Survivor2(client, 0);

	}

}

public Action Join_Survivor2(int client, int args)
{
	if (!Management.BoolValue) return Plugin_Continue;

	if(!IsClientInGame(client)) return Plugin_Handled;
	
	if(GetClientTeam(client) != TEAM_SURVIVOR && !GetBotOfIdle(client))
	{
		if(CountAvailableBots(TEAM_SURVIVOR) == 0 && !InfectedAllowed)
		{
			bool canRespawn = (RespawnJoin.BoolValue && IsFirstTime(client)) ;
			
			ChangeClientTeam(client, TEAM_SURVIVOR);  // Add extra survivor. Triggers player_spawn, which makes IsFirstTime false
			
			if (!IsPlayerAlive(client) && !GetBotOfIdle(client) && canRespawn)
			{
				Respawn(client);
				TeleportToSurvivor(client);
				SetGodMode(client, 1.0); // 1 sec of god mode after spawning
				
				GiveAverageWeapon(client);				
				if(ExtraFirstAid.BoolValue && MedkitsGiven && MedkitTimer == null) // if medkits already given				
					CheatCommand(client, "give", "first_aid_kit", "");
			} else if (!IsPlayerAlive(client) && !GetBotOfIdle(client) && RespawnJoin.BoolValue)
			{
				PrintToChat(client, "\x03[SV] \x01You already played on the \x04Survivor Team\x01 this round. You will spawn dead.");
			}
		}
		else
		{
			FakeClientCommand(client,"jointeam 2");
		}
	}
	
	if(GetBotOfIdle(client))  TakeOver(GetBotOfIdle(client));
	
	if(GetClientTeam(client) == TEAM_SURVIVOR)
	{		
		if(IsPlayerAlive(client) == true && InfectedAllowed)
		{
			PrintToChat(client, "\x03[SV] \x01You are on the \x04Survivor Team\x01.");
		}
		else if(IsPlayerAlive(client) == false && CountAvailableBots(TEAM_SURVIVOR) != 0)  // Takeover a bot
		{
			ChangeClientTeam(client, TEAM_SPECTATOR);
			FakeClientCommand(client,"jointeam 2");
		}
		else if(IsPlayerAlive(client) == false && CountAvailableBots(TEAM_SURVIVOR) == 0)
		{
			PrintToChat(client, "\x03[SV] \x01You are \x04Dead\x01. No \x05Bot(s) \x01Available.");
		}
	}
	return Plugin_Handled;
}

public Action Join_Infected(int client, int args) {
	if (!Management.BoolValue) return Plugin_Continue;

	if (GetClientTeam(client) == TEAM_INFECTED) {
		PrintToChat(client, "\x03[SV] \x01You are on the \x05Infected Team\x01.");
	}
	else if (!InfectedAllowed) {
		PrintToChat(client, "\x03[SV] \x01[\x04ERROR\x01] The \x05Infected Team\x01 is not available in %s.", gameMode);
	}
	else if (InfectedLimit.IntValue <= GetTeamPlayers(TEAM_INFECTED, false)) {
		PrintToChat(client, "\x03[SV] \x01[\x04ERROR\x01] The \x05Infected Team\x01 is Full.");
	}
	else {
		ChangeClientTeam(client, TEAM_INFECTED);
	}
	return Plugin_Handled;
}



public Action GO_AFK(int client, int args) {
	if (Management.IntValue < 2) return Plugin_Continue;

	if (GetClientTeam(client) == TEAM_SURVIVOR) // Infected can't go idle, they spectate instead
	{
		CheckIdle[client] = true; // Check for fix
		FakeClientCommand(client, "go_away_from_keyboard");
	}
	if (GetClientTeam(client) != TEAM_SPECTATOR) FakeClientCommand(client, "sm_spectate");
	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Create a bot. Useful if less bots than SurvivorLimit because the later got increased
// ------------------------------------------------------------------------
public Action Create_Player(int client, int args) {

	bool fakeclientKicked = false;

	int ClientsCount = GetSurvivorTeam();

	if (Management.IntValue < 2) return Plugin_Continue;

	char arg[MAX_NAME_LENGTH];
	if (args > 0) {
		GetCmdArg(1, arg, sizeof(arg));
		PrintToChatAll("\x03[SV] \x01Player %s has joined the game", arg);
		CreateFakeClient(arg);
	}
	else {
		// create fakeclient
		int Bot = 0;

		if (ClientsCount < SurvivorLimit.IntValue) {
			Bot = CreateFakeClient("SurvivorBot");
		}

		if (Bot == 0) return Plugin_Handled;

		ChangeClientTeam(Bot, TEAM_SURVIVOR);
		if (!DispatchKeyValue(Bot, "classname", "survivorbot")) return Plugin_Handled;

		if (!DispatchSpawn(Bot)) return Plugin_Handled; // if dispatch failed		

		if (!IsPlayerAlive(Bot)) Respawn(Bot);

		// check if entity classname is survivorbot
		if (DispatchKeyValue(Bot, "classname", "survivorbot") == true) {
			// spawn the client
			if (DispatchSpawn(Bot) == true) {

				// teleport client to the position of any active alive player
				TeleportToSurvivor(Bot);
				GiveAverageWeapon(Bot);
				if (ExtraFirstAid.BoolValue) CheatCommand(Bot, "give", "first_aid_kit", "");
				// kick the fake client to make the bot take over
				CreateTimer(DELAY_KICK_FAKECLIENT, Timer_KickFakeBot, Bot, TIMER_REPEAT);
				fakeclientKicked = true;
			}
		}
		// if something went wrong, kick the created FakeClient
		if (fakeclientKicked == false) KickClient(Bot, "Kicking FakeClient");

	}
	return Plugin_Handled;
}

public Action Timer_KickFakeBot(Handle timer, any Bot)
{
	if (IsClientConnected(Bot))
	{
		KickClient(Bot, "Kicking FakeClient");		
		return Plugin_Stop;
	}	
	return Plugin_Continue;
}

public Action TeamMenu(int client, int args)
{
	if (Management.IntValue < 3) return Plugin_Continue;

	if(TeamPanelTimer[client] == null)
	{
		DisplayTeamMenu(client);
	}
	return Plugin_Handled;
}

// *********************************************************************************
// RETURN PROPERTIES OF INFECTED/SURVIVOR TEAMS, BOTS, & PLAYERS
// *********************************************************************************

char survivor_only_modes[23][] =
{
	"coop", "realism", "survival",
	"m60s", "hardcore", "l4d1coop",
	"mutation1",	"mutation2",	"mutation3",	"mutation4",
	"mutation5",	"mutation6",	"mutation7",	"mutation8",
	"mutation9",	"mutation10",	"mutation16",	"mutation17", "mutation20",
	"community1",	"community2",	"community4",	"community5"
};

// ------------------------------------------------------------------------
// Returns true if players in team infected are allowed
// ------------------------------------------------------------------------
bool AreInfectedAllowed()
{
	for (int i = 0; i < sizeof(survivor_only_modes); i++)
	{
		if (StrEqual(gameMode, survivor_only_modes[i], false))
		{
			return false;
		}
	}
	return true;   // includes versus, realism versus, scavenge, & some mutations
}

// ------------------------------------------------------------------------
// Returns true if all connected players are in the game
// ------------------------------------------------------------------------
bool AreAllInGame()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && !IsFakeClient(i))
		{
			if (!IsClientInGame(i)) return false;
		}
	}
	return true;
}

// ------------------------------------------------------------------------
// Returns true if lobby full. Used to unreserve the lobby
// ------------------------------------------------------------------------
bool IsServerLobbyFull()
{
	int humans = GetHumanCount();

	if (humans >= 8) return true;
	if( !InfectedAllowed && humans >= 4) return true;
	return false;
}

// ------------------------------------------------------------------------
// Returns true if client never spawned as survivor this game. Used to allow 1 free spawn
// ------------------------------------------------------------------------
bool IsFirstTime(int client)
{
	if(!IsClientInGame(client) || IsFakeClient(client)) return false;
	
	char SteamID[64];
	bool valid = GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));		
	
	if (valid == false) return false;

	bool Allowed;
	if (!SteamIDs.GetValue(SteamID, Allowed))  // If can't find the entry in map
	{
		SteamIDs.SetValue(SteamID, true, true);
		Allowed = true;
	}
	return Allowed;
}

// ------------------------------------------------------------------------
// Stores the Steam ID, so if reconnect we don't allow free respawn
// ------------------------------------------------------------------------
void RecordSteamID(int client)
{
	// Stores the Steam ID, so if reconnect we don't allow free respawn
	char SteamID[64];
	bool valid = GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	if (valid) SteamIDs.SetValue(SteamID, false, true);
}

// ------------------------------------------------------------------------
// Returns the idle player of the bot, returns 0 if none
// ------------------------------------------------------------------------
int GetIdlePlayer(int bot)
{
	if(IsClientInGame(bot) && GetClientTeam(bot) == TEAM_SURVIVOR && IsPlayerAlive(bot) && IsFakeClient(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if(strcmp(sNetClass, "SurvivorBot") == 0)
		{
			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
			if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR)
			{
				return client;
			}
		}
	}
	return 0;
}

// ------------------------------------------------------------------------
// Returns the bot of the idle client, returns 0 if none 
// ------------------------------------------------------------------------
int GetBotOfIdle(int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (GetIdlePlayer(i) == client) return i;
	}
	return 0;
}

// ------------------------------------------------------------------------
// Get the number of players on the team (includes idles)
// includeBots == true : counts bots
// ------------------------------------------------------------------------
int GetTeamPlayers(int team, bool includeBots)
{
	int players = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team)
		{
			if(IsFakeClient(i) && !includeBots && !GetIdlePlayer(i))
				continue;
			players++;
		}
	}
	return players;
}

// ------------------------------------------------------------------------
// Get the number of survivors on the team, including bots
// ------------------------------------------------------------------------
int GetSurvivorTeam()
{
	return GetTeamPlayers(TEAM_SURVIVOR, true);
}

int GetHumanCount()
{
	int humans = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
			humans++;
	}
	return humans;
}

// ------------------------------------------------------------------------
// Is the bot valid? (either survivor or infected)
// ------------------------------------------------------------------------
bool IsBotValid(int client)
{
	if(client > 0 && IsClientInGame(client) && IsFakeClient(client) && !GetIdlePlayer(client) && !IsClientInKickQueue(client))
		return true;
	return false;
}

// ------------------------------------------------------------------------
// Get any valid survivor bot (may be dead). Last bot created is found first
// ------------------------------------------------------------------------
int GetAnyValidSurvivorBot()
{
	for(int i = MaxClients ; i >= 1; i--)  // kick bots in reverse order they have been spawned
	{
		if (IsBotValid(i) && GetClientTeam(i) == TEAM_SURVIVOR)
			return i;
	}
	return -1;
}

// ------------------------------------------------------------------------
// Check if how many alive bots without an idle are available in a team
// ------------------------------------------------------------------------
int CountAvailableBots(int team)
{
	int num = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsBotValid(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
					num++;
	}
	return num;
}

// ------------------------------------------------------------------------
// Check if how many bots are in a team without idle. Can be dead
// ------------------------------------------------------------------------
stock int CountBots(int team)
{
	int num = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsBotValid(i) && GetClientTeam(i) == team)
					num++;
	}
	return num;
}

int GetAnyValidClient()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientInKickQueue(i) )
			return i;
	} 
	return -1;
}

int GetAnyAliveSurvivor()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientInKickQueue(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i))
		{
			return i;
		}
	}
	return -1;
}

bool AnySurvivorLeftSafeArea()
{
	int ent = -1, maxents = GetMaxEntities();
	for (int i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			char netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource", false))
			{
				ent = i;
				break;
			}
		}
	}
	
	if (ent > -1)
	{
		if(GetEntProp(ent, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
		{
			return true;
		}
	}
	return false;
}

// *********************************************************************************
// TEAM MENU
// *********************************************************************************

void DisplayTeamMenu(int client)
{
	Handle TeamPanel = CreatePanel();

	SetPanelTitle(TeamPanel, "SuperVersus Team Panel");

	char title_spectator[32];
	Format(title_spectator, sizeof(title_spectator), "Spectator (%d)", GetTeamPlayers(TEAM_SPECTATOR, false));
	DrawPanelItem(TeamPanel, title_spectator);
		
	// Draw Spectator Group
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SPECTATOR)
		{
			char text_client[32];
			char ClientUserName[MAX_TARGET_LENGTH];
			GetClientName(i, ClientUserName, sizeof(ClientUserName));
			ReplaceString(ClientUserName, sizeof(ClientUserName), "[", "");

			Format(text_client, sizeof(text_client), "%s", ClientUserName);
			DrawPanelText(TeamPanel, text_client);
		}
	}

	char title_survivor[32];
	Format(title_survivor, sizeof(title_survivor), "Survivors (%d/%d) - %d Bot(s)", GetTeamPlayers(TEAM_SURVIVOR, false), SurvivorLimit.IntValue, CountAvailableBots(TEAM_SURVIVOR));
	DrawPanelItem(TeamPanel, title_survivor);
	
	// Draw Survivor Group
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
			char text_client[32];
			char ClientUserName[MAX_TARGET_LENGTH];

			GetClientName(i, ClientUserName, sizeof(ClientUserName));
			ReplaceString(ClientUserName, sizeof(ClientUserName), "[", "");

			char m_iHealth[MAX_TARGET_LENGTH];
			if(IsPlayerAlive(i))
			{
				if(GetEntProp(i, Prop_Send, "m_isIncapacitated"))
				{
					Format(m_iHealth, sizeof(m_iHealth), "DOWN - %d HP - ", GetEntData(i, FindDataMapInfo(i, "m_iHealth"), 4));
				}
				else if(GetEntProp(i, Prop_Send, "m_currentReviveCount") == SurvMaxIncap.IntValue)
				{
					Format(m_iHealth, sizeof(m_iHealth), "BLWH - ");
				}
				else
				{
					Format(m_iHealth, sizeof(m_iHealth), "%d HP - ", GetClientRealHealth(i));
				}
	
			}
			else
			{
				Format(m_iHealth, sizeof(m_iHealth), "DEAD - ");
			}

			Format(text_client, sizeof(text_client), "%s%s", m_iHealth, ClientUserName);
			DrawPanelText(TeamPanel, text_client);
		}
	}

	char title_infected[32];
	
	if (GetClientTeam(client) == TEAM_INFECTED || Management.IntValue == 4)
	{
		if ( InfectedAllowed) Format(title_infected, sizeof(title_infected), "Infected (%d/%d) - %d Bot(s)", GetTeamPlayers(TEAM_INFECTED, false), InfectedLimit.IntValue, CountAvailableBots(TEAM_INFECTED));
		if (!InfectedAllowed) Format(title_infected, sizeof(title_infected), "Infected - %d Bot(s)", CountAvailableBots(TEAM_INFECTED));
	}
	else if (!InfectedAllowed)
	{
		if (SiSpMore.BoolValue && AutoDifficulty.BoolValue && l4dt())
			Format(title_infected, sizeof(title_infected), "Infected - Max %d Bot(s)", MaxSpecials);  // doesn't show how many bots are alive, but show max bots
		else Format(title_infected, sizeof(title_infected), "Infected");  // don't show max bots if not known
	}
	else if ( InfectedAllowed)
	{
		Format(title_infected, sizeof(title_infected), "Infected (%d/%d)", GetTeamPlayers(TEAM_INFECTED, false), InfectedLimit.IntValue);  // doesn't show how many bots are alive
	}
	
	DrawPanelItem(TeamPanel, title_infected);
		
	// Draw Infected Group
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			if (GetClientTeam(client) != TEAM_INFECTED && IsFakeClient(i) &&  Management.IntValue != 4) continue ;    // Don't show anything about infected bots to survivors
		
			char text_client[32];
			char ClientUserName[MAX_TARGET_LENGTH];
			
			GetClientName(i, ClientUserName, sizeof(ClientUserName));
			ReplaceString(ClientUserName, sizeof(ClientUserName), "[", "");

			if (GetClientTeam(client) == TEAM_INFECTED || Management.IntValue == 4) // Only show HP of infected to infected
			{
				char m_iHealth[MAX_TARGET_LENGTH];
				if(IsPlayerAlive(i))
				{
					if(GetEntProp(i, Prop_Send, "m_isIncapacitated"))
					{
						Format(m_iHealth, sizeof(m_iHealth), "DOWN - %d HP - ", GetEntData(i, FindDataMapInfo(i, "m_iHealth"), 4));
					}
					if(GetEntProp(i, Prop_Send, "m_isGhost"))
					{
						Format(m_iHealth, sizeof(m_iHealth), "GHOST - ");
					}
					else
					{
						Format(m_iHealth, sizeof(m_iHealth), "%d HP - ", GetEntData(i,  FindDataMapInfo(i, "m_iHealth"), 4));
					}
				}
				else
				{
					Format(m_iHealth, sizeof(m_iHealth), "DEAD - ");
				}
				Format(text_client, sizeof(text_client), "%s%s", m_iHealth, ClientUserName);
			}
			else Format(text_client, sizeof(text_client), "%s", ClientUserName);
			
			DrawPanelText(TeamPanel, text_client);
		}
	}

	DrawPanelItem(TeamPanel, "Close");
		
	SendPanelToClient(TeamPanel, client, TeamMenuHandler, 30);
	CloseHandle(TeamPanel);
	TeamPanelTimer[client] = CreateTimer(1.0, Timer_TeamMenuHandler, client);
}

public int TeamMenuHandler(Handle UpgradePanel, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {
		if (param2 == 1) {
			FakeClientCommand(client, "sm_spectate");
		}
		else if (param2 == 2) {


				FakeClientCommand(client, "sm_survivor");

		}
		else if (param2 == 3) {
			FakeClientCommand(client, "sm_infected");
		}
		else if (param2 == 4) {
			delete TeamPanelTimer[client];
		}
	}
	else if (action == MenuAction_Cancel) {
		// Nothing
	}
}

public Action Timer_TeamMenuHandler(Handle hTimer, int client)
{
	DisplayTeamMenu(client);
}

int GetClientRealHealth(int client)
{
	if(!client || !IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsClientObserver(client))
	{
		return -1;
	}
	if(GetClientTeam(client) != TEAM_SURVIVOR)
	{
		return GetClientHealth(client);
	}
  
	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float TempHealth;
	int PermHealth = GetClientHealth(client);
	if(buffer <= 0.0)
	{
		TempHealth = 0.0;
	}
	else
	{
		float difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		float decay = PainPillsDR.FloatValue;
		float constant = 1.0/decay;	TempHealth = buffer - (difference / constant);
	}
	
	if(TempHealth < 0.0)
	{
		TempHealth = 0.0;
	}
	return RoundToFloor(PermHealth + TempHealth);
}

// *********************************************************************************
// DIRECTOR DIFFICULTY METHODS
// *********************************************************************************

// ------------------------------------------------------------------------
//  Change the director variable MaxSpecials. Won't do anything unless l4dt present
// ------------------------------------------------------------------------
public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)
{
	if (!InfectedAllowed && StrEqual(key, "MaxSpecials") && SiSpMore.BoolValue && AutoDifficulty.BoolValue)
	{
		retVal = MaxSpecials;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// ------------------------------------------------------------------------
//  Difficulty timer. Triggered by Timer_BotsUpdate
// ------------------------------------------------------------------------
public Action Timer_Difficulty(Handle hTimer)
{
	DifficultyTimer = null;
	AutoDifficultyCheck();
}

void AutoDifficultyCheck()
{
	int extrasurvivors = GetSurvivorTeam() - 4;
	extrasurvivors = (extrasurvivors > 0) ? extrasurvivors : 0;// Don't make game easier if less than 4 survivors 
	
	float TankHp_Multi = 1 + TankHpMulti.FloatValue * extrasurvivors;// More Survivors = More Tank Health
	float setHP;
	char z_difficulty[16];
	GetConVarString(Difficulty, z_difficulty, sizeof(z_difficulty));
	if (AreInfectedAllowed())
		setHP = TankVersusHealth.FloatValue;
	else if (StrEqual(z_difficulty, "Impossible", false))
		setHP = TankExpertHealth.FloatValue;
	else if (StrEqual(z_difficulty, "Hard", false))
		setHP = TankAdvancedHealth.FloatValue;
	else if (StrEqual(z_difficulty, "Normal", false))
		setHP = TankNormalHealth.FloatValue;
	else if (StrEqual(z_difficulty, "Easy", false))
		setHP = TankEasyHealth.FloatValue;
	TankHealth.IntValue = RoundToNearest(setHP * TankHp_Multi);

	float spawn_multi = 1 + CiSpMulti.FloatValue * extrasurvivors ;// More Survivors = More Commons
	szMobSpawnFinale.IntValue	= RoundFloat(CIMobSpawnFinaleSize.FloatValue*spawn_multi);
	szMobSpawnMax.IntValue		= RoundFloat(CIMobSpawnMaxSize.FloatValue*spawn_multi);
	szMobSpawnMin.IntValue		= RoundFloat(CIMobSpawnMinSize.FloatValue*spawn_multi);
	szMobMega.IntValue			= RoundFloat(CIMegaMobSize.FloatValue*spawn_multi);
	szMobLimit.IntValue			= RoundFloat(CICommonMobLimit.FloatValue*spawn_multi);
	szBGLimit.IntValue			= RoundFloat(CIBackgroundMobSize.FloatValue*spawn_multi);

	if(ITHordeTimers.BoolValue)// Should timers be affected too?
	{
		intvlMobSpawnMaxEasy.IntValue				= RoundToFloor(ITMobSpawnMaxIntervalEasy.FloatValue / spawn_multi);
		intvlMobSpawnMaxNormal.IntValue				= RoundToFloor(ITMobSpawnMaxIntervalNormal.FloatValue / spawn_multi);
		intvlMobSpawnMaxHard.IntValue				= RoundToFloor(ITMobSpawnMaxIntervalHard.FloatValue / spawn_multi);
		intvlMobSpawnMaxExpert.IntValue				= RoundToFloor(ITMobSpawnMaxIntervalExpert.FloatValue / spawn_multi);
		intvlMobSpawnMinEasy.IntValue				= RoundToFloor(ITMobSpawnMinIntervalEasy.FloatValue / spawn_multi);
		intvlMobSpawnMinNormal.IntValue				= RoundToFloor(ITMobSpawnMinIntervalNormal.FloatValue / spawn_multi);
		intvlMobSpawnMinHard.IntValue				= RoundToFloor(ITMobSpawnMinIntervalHard.FloatValue / spawn_multi);
		intvlMobSpawnMinExpert.IntValue				= RoundToFloor(ITMobSpawnMinIntervalExpert.FloatValue / spawn_multi);
		intvlMobMegaSpawnMax.IntValue				= RoundToFloor(ITMegaMobSpawnMaxInterval.FloatValue / spawn_multi);
		intvlMobMegaSpawnMin.IntValue				= RoundToFloor(ITMegaMobSpawnMinInterval.FloatValue / spawn_multi);
		directSpecialRespawn.IntValue				= RoundToFloor(ITDirectorSpecialRespawnInterval.FloatValue / spawn_multi);
		directSpecialFinalRespawn.IntValue			= RoundToFloor(ITDirectorSpecialBattlefieldRespawnInterval.FloatValue / spawn_multi);
		directSpecialFinalOffer.IntValue			= RoundToFloor(ITDirectorSpecialFinaleOfferLength.FloatValue / spawn_multi);
		directSpecialSpawnDelayMax.IntValue			= RoundToFloor(ITDirectorSpecialInitialSpawnDelayMax.FloatValue / spawn_multi);
		directSpecialSpawnDelayMaxExtra.IntValue	= RoundToFloor(ITDirectorSpecialInitialSpawnDelayMaxExtra.FloatValue / spawn_multi);
		directSpecialSpawnDelayMin.IntValue			= RoundToFloor(ITDirectorSpecialInitialSpawnDelayMin.FloatValue / spawn_multi);
		directSpecialOriginalOffer.IntValue			= RoundToFloor(ITDirectorSpecialOriginalOfferLength.FloatValue / spawn_multi);
	}

	float sihp_Multi = 1 + SiHpMulti.FloatValue * extrasurvivors;// More Survivors = More SI Health
	SmokerHealth.IntValue		= RoundToCeil	(SISmokerHealth.FloatValue * sihp_Multi);
	HunterHealth.IntValue		= RoundToCeil	(SIHunterHealth.FloatValue * sihp_Multi);
	BoomerHealth.IntValue		= RoundToCeil	(SIBoomerHealth.FloatValue * sihp_Multi);
	SpitterHealth.IntValue		= RoundToCeil	(SISpitterHealth.FloatValue * sihp_Multi);
	ChargerHealth.IntValue		= RoundToCeil	(SIChargerHealth.FloatValue * sihp_Multi);
	JockeyHealth.IntValue		= RoundToCeil	(SIJockeyHealth.FloatValue * sihp_Multi);

	// Increase limit of special infected as bots. 
	if(!InfectedAllowed && SiSpMore.BoolValue && l4dt() && !StrEqual(gameMode, "survival")) // Not in survival, versus, scavenge or realism versus, l4dt required
	{
		// Increase overall infected limit
		MaxSpecials = 2 + RoundToNearest(extrasurvivors * SiSpMore.FloatValue);
		MinionLimit.IntValue = MaxSpecials; 	// For L4D1?
		
		// Increase limits of infected classes
		char iType[6][24] = {"z_smoker_limit", "z_boomer_limit", "z_hunter_limit", "z_spitter_limit", "z_charger_limit", "z_jockey_limit"};
		int maxTypes = L4D1 ? 3 : 6;
		if(L4D1)
		{
			ReplaceString(iType[0], sizeof(iType[]), "smoker", "gas", false);
			ReplaceString(iType[1], sizeof(iType[]), "boomer", "exploding", false);		
		}

		int SIperclass = RoundToCeil(MaxSpecials/3.0);  // 0 to 3 SI: 1 per class, 4 to 6 SI: 2 per class, 7 to 9 SI: 3 per class, etc

		for(int i = 0; i < maxTypes; i++)
		{
			FindConVar(iType[i]).IntValue = SIperclass;  // Increase each SI class limit
		}
	}
	PrintToConsoleAll("[SV] - Tank HP: %.0f%%\tSI HP: %.0f%%\tCI spawn rate: %.0f%%\tMaxSpecials: %d", 100.0*TankHp_Multi, 100.0*sihp_Multi, 100.0*spawn_multi, MaxSpecials);
}

// *********************************************************************************
// INFECTED COUNTER, for Versus / Scavenge
// *********************************************************************************

// ------------------------------------------------------------------------
//  Start counter when a survivor leaves safe area
// ------------------------------------------------------------------------
public void Event_PlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast)
{ 
	if(SubDirector == null && InfectedAllowed && AnySurvivorLeftSafeArea())
	{
		SubDirector = CreateTimer(5.0, BotInfectedCounter, true);
	}
}

// ------------------------------------------------------------------------
//  Counter periodically checks if need to add SI to queue, or spawn extra SI
// ------------------------------------------------------------------------
public Action BotInfectedCounter(Handle timer, bool recheck)
{
	SubDirector = null;

	if (recheck && !AnySurvivorLeftSafeArea()) return;  // Disable counter if false start due to round restart
	
	if (!MoreSiBotsVersus.BoolValue || GetTeamPlayers(TEAM_INFECTED, false) >= InfectedLimit.IntValue) // if no extra bots wanted
	{
		SubDirector = CreateTimer(10.0, BotInfectedCounter, false); // check back in 10 secs to see if setting changed
		return ;
	}
	
	SiSpawnCheck();
	
	SubDirector = CreateTimer(2.0, BotInfectedCounter, false);
}

// ------------------------------------------------------------------------
//  Check if Si to be added to respawn Queue, or spawn a Si
// ------------------------------------------------------------------------
void SiSpawnCheck()
{
	// For each missing SI, add to queue
	for (int i = GetTeamPlayers(TEAM_INFECTED, true) + CountSiQueue(); i < InfectedLimit.IntValue; i++)
	{
		AddSiToQueue();
	}
	
	// For each Si over the limit, remove youngest in queue
	for (int i = GetTeamPlayers(TEAM_INFECTED, true) + CountSiQueue(); i > InfectedLimit.IntValue; i--)
	{
		int YoungestSi = GetYoungestSi();
		if (YoungestSi != -1)  	SiTimes[YoungestSi] = 0.0;		
	}
	
	// For each Si over the limit, spawn it
	int OldestSi = GetOldestSi();
	if (OldestSi != -1 && (GetGameTime() - SiTimes[OldestSi]) > GhostDelayMax.FloatValue + SiSpMoreDelay.FloatValue)
	{
		SiSpawn();
	}
}

// ------------------------------------------------------------------------
//  Get Si that has been in the spawn queue the longest
// ------------------------------------------------------------------------
int GetOldestSi()
{
	float fOldest     =  GetGameTime()+1.0; // More recent that any can be
	int   iOldest     =   			    -1;
	for (int i = 0; i < InfectedLimit.IntValue; i++)
	{
		if (SiTimes[i] > 0.0 && SiTimes[i] < fOldest)
		{
			iOldest   = i;
			fOldest   = SiTimes[i];
		}
	}
	return iOldest;
}

// ------------------------------------------------------------------------
//  Get Si that has been in the spawn queue the shortest
// ------------------------------------------------------------------------
int GetYoungestSi()
{
	float fYoungest     =                  0.0; // Older than any can be
	int   iYoungest     =   			    -1;
	for (int i = 0; i < InfectedLimit.IntValue; i++)
	{
		if (SiTimes[i] > fYoungest)
		{
			iYoungest   = i;
			fYoungest   = SiTimes[i];
		}
	}
	return iYoungest;
}

// ------------------------------------------------------------------------
//  Add new Si to spawn queue
// ------------------------------------------------------------------------
void AddSiToQueue()
{
	for (int i = 0; i < InfectedLimit.IntValue; i++)
	{
		if (SiTimes[i] == 0.0)
		{
			SiTimes[i] = GetGameTime();
			return;
		}
	}
}

// ------------------------------------------------------------------------
// Count how many SI are in the queue
// ------------------------------------------------------------------------
int CountSiQueue()
{
	int count = 0;
	for (int i = 0; i < InfectedLimit.IntValue; i++)
	{
		if (SiTimes[i] > 0.0)
		{
			count = count + 1;
		}
	}
	return count;
}

// ------------------------------------------------------------------------
//  Spawn a Special Infected bot
// ------------------------------------------------------------------------
void SetGhostStatus(int client, bool ghost) { SetEntProp(client, Prop_Send, "m_isGhost",   ghost); }
void SetLifeState  (int client, bool ready) { SetEntProp(client, Prop_Send, "m_lifeState", ready); }
bool IsPlayerGhost (int client) 			{ return GetEntProp(client, Prop_Send, "m_isGhost") ? true : false;}
char SiNames[9][] = {"none", "smoker", "boomer", "hunter", "spitter", "jockey", "charger", "witch", "tank"};

int GetSiType(int client)
{
	char modelName[32];
	GetClientModel(client, modelName, sizeof(modelName));
	for (int type = 1; type <= 8; type++)
	{
		if (StrEqual(modelName, SiNames[type])) return type;
	}
	return 0;
}

void SiSpawn(int type = -1)
{
	if (type == -1) type = PickSiType();
	if (type == -1) return;

	// Stores Ghost / Life, & set to nonghost/not alive. Otherwise players may autospawn
	/////////////////////////////////////////////////////
	bool resetGhost[MAXPLAYERS+1];
	bool resetLife[MAXPLAYERS+1];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			if(IsPlayerGhost(i))
			{
				resetGhost[i] = true;
				SetGhostStatus(i, false);
			}
			else if(!IsPlayerAlive(i))
			{
				resetLife[i] = true;
				SetLifeState(i, false);
			}
		}
	}

	int client = GetAnyValidClient();
	if (client > 0) 
	{
		int Bot = CreateFakeClient("InfectedBot");
		if(Bot != 0)
		{
			ChangeClientTeam(Bot, TEAM_INFECTED);
			DispatchKeyValue(Bot, "classname", "InfectedBot");
			if (L4D1) CheatCommand(client, "z_spawn", SiNames[type], "auto");
			else  CheatCommand(client, "z_spawn_old", SiNames[type], "auto"); // z_spawn_old required or they spawn in front of survivors
			KickClient(Bot, "Kicked Fake Bot");
		}
	}
	
	// We restore the player's status
	/////////////////////////////////
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			if (resetGhost[i]) SetGhostStatus(i, true); 
			if ( resetLife[i]) SetLifeState(i, true);
		}
	}
}

char L4D1_limits[4][] = {"none", "z_gas_limit",			  "z_exploding_limit",	   "z_hunter_limit"};
char L4D2_limits[7][] = {"none", "z_versus_smoker_limit", "z_versus_boomer_limit", "z_versus_hunter_limit", "z_versus_spitter_limit", "z_versus_charger_limit", "z_versus_jockey_limit"};

// ------------------------------------------------------------------------
//  Find which SI should be spawned
// ------------------------------------------------------------------------
int PickSiType()
{
	// first element is nothing, to simplify since enum starts at 1
	//////////////////////////////////////////////////////////////
	int SIleft[7] = {-1,  0,0,0, 0,0,0};
	int maxTypes = L4D1 ? 3 : 6;
	
	// Record SI type limits
	////////////////////////
	int SIfromTypes = 0; // 
	for (int type = 1; type <= maxTypes; type++)
	{
		SIleft[type] = L4D1? FindConVar(L4D1_limits[type]).IntValue : FindConVar(L4D2_limits[type]).IntValue;
		SIfromTypes  = SIfromTypes + SIleft[type] ;
	}

	int iInfected = InfectedLimit.IntValue;
	MinionLimit.IntValue = iInfected; 

	// Check if SI from types are enough
	///////////////////////////////////////
	if (SIfromTypes < iInfected)   // if not enough 
	{
		int extraSiPerType =  RoundToCeil((iInfected - SIfromTypes)/3.0);
		
		for(int i = 1; i <= maxTypes; i++)
		{
			SIleft[i] = SIleft[i] + extraSiPerType;
			if (L4D1) FindConVar(L4D1_limits[i]).IntValue = SIleft[i];  // Increase each SI class limit
			else      FindConVar(L4D2_limits[i]).IntValue = SIleft[i];
		}
	}
	
	// counts infected left that can be spawned.
	//////////////////////////////////////////			
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED)
		{			
			SIleft[GetSiType(i)]--;
		}
	}
	
	// Pick available types;
	int nmax = 0;
	int SIfree[7];
	
	for (int type = 1; type <= 6; type++)
	{
		if (SIleft[type] > 0)
		{
			nmax++;
			SIfree[nmax] = type;
		}
	}
		
	if (nmax != 0)  return SIfree[GetRandomInt(1, nmax)];
	else 			return -1;
}

// *********************************************************************************
// SIGNATURE METHODS
// *********************************************************************************

void Respawn(int client)
{
	static Handle hRoundRespawn;
	if (hRoundRespawn == null)
	{
		Handle hGameConf = LoadGameConfigFile("l4d_superversus");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();

  	}
	SDKCall(hRoundRespawn, client);
}

void SetHumanIdle(int bot, int client)
{
	static Handle hSpec;
	if (hSpec == null)
	{
		Handle hGameConf = LoadGameConfigFile("l4d_superversus");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSpec = EndPrepSDKCall();


	}

	SDKCall(hSpec, bot, client);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 5);
}

void TakeOverBot(int client)
{
	static Handle hSwitch;
	if (hSwitch == null)
	{
		Handle hGameConf = LoadGameConfigFile("l4d_superversus");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TakeOverBot");
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hSwitch = EndPrepSDKCall();

	}
	SDKCall(hSwitch, client, true);
}

// *********************************************************************************
// CHEAT METHODS
// *********************************************************************************

void CheatCommand(int client, const char[] command, const char[] argument1, const char[] argument2)
{
	int userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, argument1, argument2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

stock void PrintConsoleToAll(const char[] format, any ...) 
{ 
	char text[192];
	VFormat(text, sizeof(text), format, 2);
	
	for (int i = 1; i <= MaxClients; i++)
	{ 
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			PrintToConsole(i, "%s", text);
		}
	}
}

// ------------------------------------------------------------------------
// Teleport client to survivor
// ------------------------------------------------------------------------
void TeleportToSurvivor(int Bot) 
{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && (GetClientTeam(i) == TEAM_SURVIVOR) && !IsFakeClient(i) && IsAlive(i) && i != Bot)
					{						
						// get the position coordinates of any active alive player
						float teleportOrigin[3];
						GetClientAbsOrigin(i, teleportOrigin);			
						TeleportEntity(Bot, teleportOrigin, NULL_VECTOR, NULL_VECTOR);					
						break;
					}
				}
}

// ------------------------------------------------------------------------
// Get the average weapon tier of survivors, and give a weapon of that tier to client
// ------------------------------------------------------------------------
char tier1_weapons[5][] =
{
	"weapon_smg",
	"weapon_pumpshotgun",
	"weapon_smg_silenced",		// L4D2 only
	"weapon_shotgun_chrome",	// L4D2 only
	"weapon_smg_mp5"			// International only
};
bool IsWeaponTier1(int iWeapon)
{
	char sWeapon[128];
	GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));
	for (int i = 0; i < sizeof(tier1_weapons); i++)
	{
		if (StrEqual(sWeapon, tier1_weapons[i], false)) return true;
	}
	return false;
}
void GiveAverageWeapon(int client)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR || !IsPlayerAlive(client)) return;

	int iWeapon;
	int wtotal=0; int total=0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) && client != i)
		{
			total = total+1;	
			iWeapon = GetPlayerWeaponSlot(i, 0);
			if (iWeapon < 0 || !IsValidEntity(iWeapon) || !IsValidEdict(iWeapon)) continue; // no primary weapon

			if (IsWeaponTier1(iWeapon)) wtotal = wtotal + 1;  // tier 1
			else wtotal = wtotal + 2; // tier 2 or more
		}
	}
	int average = total > 0 ? RoundToNearest(1.0 * wtotal/total) : 0;
	switch(average)
	{
		case 0: CheatCommand(client, "give", "pistol", "");	
		case 1: CheatCommand(client, "give", "smg", "");
		case 2: CheatCommand(client, "give", "weapon_rifle", "");
	}
}

void SetGodMode(int client, float duration)
{
	if (!IsClientInGame(client)) return;
	
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1); // god mode
	
	if (duration > 0.0) CreateTimer(duration, Timer_mortal, GetClientUserId(client));
}

public Action Timer_mortal(Handle hTimer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client)) return;
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1); // mortal
}



stock int TotalSurvivors() // total bots, including players
{
	int l = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if (IsClientInGame(i) && (GetClientTeam(i) == TEAM_SURVIVOR)) l++;
		}
	}
	return l;
}



public Action Timer_KickNoNeededBot(Handle timer, any bot)
{
	if ((TotalSurvivors() <= cvar_minsurvivor.IntValue)) return Plugin_Handled;
	if (IsClientConnected(bot) && IsClientInGame(bot))
	{
		char BotName[100];
		GetClientName(bot, BotName, sizeof(BotName));				
		if (StrEqual(BotName, "SurvivorBot", true)) return Plugin_Handled;
		if (!HasIdlePlayer(bot))
		{
			StripWeapons(bot);
			KickClient(bot, "Kicking No Needed Bot");
		}
	}
	
	//ServerCommand("sm_kickextrabots");
	
	return Plugin_Handled;
}


stock int StripWeapons(int client) // strip all items from client
{
	int itemIdx;
	for (int x = 0; x <= 3; x++)
	{
		if ((itemIdx = GetPlayerWeaponSlot(client, x)) != -1)
		{  
			RemovePlayerItem(client, itemIdx);
			RemoveEdict(itemIdx);
		}
	}
}

stock bool HasIdlePlayer(int bot)
{
	if (IsValidEntity(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if (strcmp(sNetClass, "SurvivorBot") == 0)
		{
			if (!GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
				return false;

			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));
			if (client)
			{
				// Do not count bots
				// Do not count 3rd person view players
				if (IsClientInGame(client) && !IsFakeClient(client) && (GetClientTeam(client) != TEAM_SURVIVOR)) return true;
			}
			else return false;
		}
	}
	return false;
}


bool IsAlive(int client)
{
	if (!GetEntProp(client, Prop_Send, "m_lifeState")) return true;
	return false;
}