#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <builtinvotes>
#include <left4dhooks>
#include <colors>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>
#undef REQUIRE_PLUGIN
#include <readyup>
#include <pause>
#include <l4d2_boss_percents>
#include <l4d2_hybrid_scoremod>
#include <l4d2_scoremod>
#include <l4d2_health_temp_bonus>
#include <l4d_tank_control_eq>
#include <lerpmonitor>
#include <witch_and_tankifier>

#define PLUGIN_VERSION	"3.8.4"

public Plugin myinfo = 
{
	name = "Hyper-V HUD Manager",
	author = "Visor, Forgetest",
	description = "Provides different HUDs for spectators",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

// ======================================================================
//  Macros
// ======================================================================
#define SPECHUD_DRAW_INTERVAL   0.5
#define TRANSLATION_FILE "spechud.phrases"

// ======================================================================
//  Plugin Vars
// ======================================================================
int g_Gamemode;

//int storedClass[MAXPLAYERS+1];

// Game Var
ConVar survivor_limit, versus_boss_buffer, sv_maxplayers, tank_burn_duration;
int iSurvivorLimit, iMaxPlayers;
float fVersusBossBuffer, fTankBurnDuration;

// Plugin Cvar
ConVar l4d_tank_percent, l4d_witch_percent, hServerNamer, l4d_ready_cfg_name;

// Plugin Var
char sReadyCfgName[64], sHostname[64];
bool bRoundLive;

// Boss Spawn Scheme
StringMap hFirstTankSpawningScheme, hSecondTankSpawningScheme;		// eq_finale_tanks (Zonemod, Acemod, etc.)
StringMap hFinaleExceptionMaps;										// finale_tank_blocker (Promod and older?)
StringMap hCustomTankScriptMaps;									// Handled by this plugin

// Flow Bosses
int iTankCount, iWitchCount;
int iTankFlow, iWitchFlow;
bool bRoundHasFlowTank, bRoundHasFlowWitch, bFlowTankActive, bCustomBossSys;

// Score & Scoremod
//int iFirstHalfScore;
bool bScoremod, bHybridScoremod, bNextScoremod;
int iMaxDistance;

// Tank Control EQ
bool bTankSelection;

// Witch and Tankifier
bool bTankifier;
bool bStaticTank, bStaticWitch;

// Hud Toggle & Hint Message
bool bSpecHudActive[MAXPLAYERS+1], bTankHudActive[MAXPLAYERS+1];
bool bSpecHudHintShown[MAXPLAYERS+1], bTankHudHintShown[MAXPLAYERS+1];

/**********************************************************************************************/

// ======================================================================
//  Plugin Start
// ======================================================================
public void OnPluginStart()
{
	LoadPluginTranslations();
	
	(	survivor_limit			= FindConVar("survivor_limit")			).AddChangeHook(GameConVarChanged);
	(	versus_boss_buffer		= FindConVar("versus_boss_buffer")		).AddChangeHook(GameConVarChanged);
	(	sv_maxplayers			= FindConVar("sv_maxplayers")			).AddChangeHook(GameConVarChanged);
	(	tank_burn_duration		= FindConVar("tank_burn_duration")		).AddChangeHook(GameConVarChanged);

	GetGameCvars();
	
	FillBossPercents();
	FillServerNamer();
	FillReadyConfig();
	
	InitTankSpawnSchemeTrie();
	
	RegConsoleCmd("sm_spechud", ToggleSpecHudCmd);
	RegConsoleCmd("sm_tankhud", ToggleTankHudCmd);
	
	HookEvent("round_start",		Event_RoundStart,		EventHookMode_PostNoCopy);
	HookEvent("round_end",			Event_RoundEnd,			EventHookMode_PostNoCopy);
	HookEvent("player_death",		Event_PlayerDeath,		EventHookMode_Post);
	HookEvent("witch_killed",		Event_WitchDeath,		EventHookMode_PostNoCopy);
	HookEvent("player_team",		Event_PlayerTeam,		EventHookMode_Post);
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		bSpecHudActive[i] = false;
		bSpecHudHintShown[i] = false;
		bTankHudActive[i] = true;
		bTankHudHintShown[i] = false;
	}
	
	CreateTimer(SPECHUD_DRAW_INTERVAL, HudDrawTimer, _, TIMER_REPEAT);
}

/**********************************************************************************************/

// ======================================================================
//  ConVar Maintenance
// ======================================================================
void GetGameCvars()
{
	iSurvivorLimit		= survivor_limit.IntValue;
	fVersusBossBuffer	= versus_boss_buffer.FloatValue;
	iMaxPlayers			= sv_maxplayers.IntValue;
	fTankBurnDuration	= tank_burn_duration.FloatValue;
}

void GetCurrentGameMode()
{
	g_Gamemode = L4D_GetGameModeType();
}

// ======================================================================
//  Dependency Maintenance
// ======================================================================
void FillBossPercents()
{
	l4d_tank_percent	= FindConVar("l4d_tank_percent");
	l4d_witch_percent	= FindConVar("l4d_witch_percent");
}

void FillServerNamer()
{
	ConVar convar = null;
	if ((convar = FindConVar("l4d_ready_server_cvar")) != null)
	{
		char buffer[64];
		convar.GetString(buffer, sizeof(buffer));
		convar = FindConVar(buffer);
	}
	
	if (convar == null)
	{
		convar = FindConVar("hostname");
	}
	
	if (hServerNamer == null)
	{
		hServerNamer = convar;
		hServerNamer.AddChangeHook(ServerCvarChanged);
	}
	else if (hServerNamer != convar)
	{
		hServerNamer.RemoveChangeHook(ServerCvarChanged);
		hServerNamer = convar;
		hServerNamer.AddChangeHook(ServerCvarChanged);
	}
	
	hServerNamer.GetString(sHostname, sizeof(sHostname));
}

void FillReadyConfig()
{
	if (l4d_ready_cfg_name != null || (l4d_ready_cfg_name = FindConVar("l4d_ready_cfg_name")) != null)
		l4d_ready_cfg_name.GetString(sReadyCfgName, sizeof(sReadyCfgName));
}

void FindScoreMod()
{
	bScoremod = LibraryExists("l4d2_scoremod");
	bHybridScoremod = LibraryExists("l4d2_hybrid_scoremod") || LibraryExists("l4d2_hybrid_scoremod_zone");
	bNextScoremod = LibraryExists("l4d2_health_temp_bonus");
}

void FindTankSelection()
{
	bTankSelection = (GetFeatureStatus(FeatureType_Native, "GetTankSelection") != FeatureStatus_Unknown);
}

void FindTankifier()
{
	bTankifier = LibraryExists("witch_and_tankifier");
}

void LoadPluginTranslations()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "translations/"...TRANSLATION_FILE... ".txt");
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file \""...TRANSLATION_FILE...".txt\"");
	}
	LoadTranslations(TRANSLATION_FILE);
}

// ======================================================================
//  Dependency Monitor
// ======================================================================
public void GameConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetGameCvars();
}

public void ServerCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	FillServerNamer();
}

public void OnAllPluginsLoaded()
{
	FindScoreMod();
	
	FillBossPercents();
	FillServerNamer();
	FillReadyConfig();
	
	FindTankSelection();
	FindTankifier();
}

public void OnLibraryAdded(const char[] name)
{
	FindScoreMod();
	FillBossPercents();
	FindTankifier();
}

public void OnLibraryRemoved(const char[] name)
{
	FindScoreMod();
	FillBossPercents();
	FindTankifier();
}

public void L4D_OnGameModeChange(int gamemode)
{
	GetCurrentGameMode();
}

// ======================================================================
//  Bosses Caching
// ======================================================================
void BuildCustomTrieEntries()
{
	// Haunted Forest 3
	hCustomTankScriptMaps.SetValue("hf03_themansion", true);
}

void InitTankSpawnSchemeTrie()
{
	hFirstTankSpawningScheme	= new StringMap();
	hSecondTankSpawningScheme	= new StringMap();
	hFinaleExceptionMaps		= new StringMap();
	hCustomTankScriptMaps		= new StringMap();
	
	RegServerCmd("tank_map_flow_and_second_event",	SetMapFirstTankSpawningScheme);
	RegServerCmd("tank_map_only_first_event",		SetMapSecondTankSpawningScheme);
	RegServerCmd("finale_tank_default",				SetFinaleExceptionMap);
	
	BuildCustomTrieEntries();
}

public Action SetMapFirstTankSpawningScheme(int args)
{
	char mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	hFirstTankSpawningScheme.SetValue(mapname, true);

	return Plugin_Handled;
}

public Action SetMapSecondTankSpawningScheme(int args)
{
	char mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	hSecondTankSpawningScheme.SetValue(mapname, true);
	return Plugin_Handled;
}

public Action SetFinaleExceptionMap(int args)
{
	char mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	hFinaleExceptionMaps.SetValue(mapname, true);
	return Plugin_Handled;
}

/**********************************************************************************************/

// ======================================================================
//  Forwards
// ======================================================================
public void OnClientDisconnect(int client)
{
	bSpecHudHintShown[client] = false;
	bTankHudHintShown[client] = false;
}

public void OnMapStart() { bRoundLive = false; }
public void OnMapEnd() {}
public void OnRoundIsLive()
{
	FillReadyConfig();
	
	bRoundLive = true;
	
	GetCurrentGameMode();
	
	//for (int i = 1; i <= MaxClients; ++i) storedClass[i] = ZC_None;
	
	if (g_Gamemode == GAMEMODE_VERSUS)
	{
		bRoundHasFlowTank = RoundHasFlowTank();
		bRoundHasFlowWitch = RoundHasFlowWitch();
		bFlowTankActive = bRoundHasFlowTank;
		
		bCustomBossSys = IsDarkCarniRemix();
		
		bStaticTank = bTankifier && IsStaticTankMap();
		bStaticWitch = bTankifier && IsStaticWitchMap();
		
		iMaxDistance = L4D_GetVersusMaxCompletionScore() / 4 * iSurvivorLimit;
		
		iTankCount = 0;
		iWitchCount = 0;
		
		if (l4d_tank_percent != null && l4d_tank_percent.BoolValue)
		{
			if (GetFeatureStatus(FeatureType_Native, "GetStoredTankPercent") != FeatureStatus_Unknown)
				iTankFlow = GetStoredTankPercent();
			else
				iTankFlow = GetRoundTankFlow();
				
			iTankCount = 1;
			
			char mapname[64];
			bool dummy;
			GetCurrentMap(mapname, sizeof(mapname));
			
			// TODO: individual plugin served as an interface to tank counts?
			if (hCustomTankScriptMaps.GetValue(mapname, dummy)) iTankCount += 1;
			
			else if (!bCustomBossSys && L4D_IsMissionFinalMap())
			{
				iTankCount = 3
							- view_as<int>(hFirstTankSpawningScheme.GetValue(mapname, dummy))
							- view_as<int>(hSecondTankSpawningScheme.GetValue(mapname, dummy))
							- view_as<int>(hFinaleExceptionMaps.Size > 0 && !hFinaleExceptionMaps.GetValue(mapname, dummy))
							- view_as<int>(bStaticTank);
			}
		}
		
		if (l4d_witch_percent != null && l4d_witch_percent.BoolValue)
		{
			if (GetFeatureStatus(FeatureType_Native, "GetStoredWitchPercent") != FeatureStatus_Unknown)
				iWitchFlow = GetStoredWitchPercent();
			else
				iWitchFlow = GetRoundWitchFlow();
			
			iWitchCount = 1;
		}
	}
}

//public void L4D2_OnEndVersusModeRound_Post() { if (!InSecondHalfOfRound()) iFirstHalfScore = L4D_GetTeamScore(GetRealTeam(0) + 1); }

// ======================================================================
//  Events
// ======================================================================
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	bRoundLive = false;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	bRoundLive = false;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsInfected(client)) return;
	
	if (GetInfectedClass(client) == L4D2Infected_Tank)
	{
		if (iTankCount > 0) iTankCount--;
		if (!RoundHasFlowTank()) bFlowTankActive = false;
	}
}

public void Event_WitchDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (iWitchCount > 0) iWitchCount--;
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client) return;
	
	int team = event.GetInt("team");
	
	if (team == L4D2Team_None) // Player disconnecting
	{
		bSpecHudActive[client] = false;
		bTankHudActive[client] = true;
	}
	
	//if (team == 3) storedClass[client] = ZC_None;
}

/**********************************************************************************************/

// ======================================================================
//  HUD Command Callbacks
// ======================================================================
public Action ToggleSpecHudCmd(int client, int args) 
{
	if (GetClientTeam(client) != L4D2Team_Spectator)
		return Plugin_Handled;
	
	bSpecHudActive[client] = !bSpecHudActive[client];
	
	CPrintToChat(client, "%t", "Notify_SpechudState", (bSpecHudActive[client] ? "on" : "off"));
	return Plugin_Handled;
}

public Action ToggleTankHudCmd(int client, int args) 
{
	int team = GetClientTeam(client);
	if (team == L4D2Team_Survivor)
		return Plugin_Handled;
	
	bTankHudActive[client] = !bTankHudActive[client];
	
	CPrintToChat(client, "%t", "Notify_TankhudState", (bTankHudActive[client] ? "on" : "off"));
	return Plugin_Handled;
}

/**********************************************************************************************/

// ======================================================================
//  HUD Handle
// ======================================================================
public Action HudDrawTimer(Handle hTimer)
{
	if (IsInReady() || IsInPause())
		return Plugin_Continue;

	int tankHud_total = 0;
	int[] tankHud_clients = new int[MaxClients];
	int specHud_total = 0;
	int[] specHud_clients = new int[MaxClients];
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i))
			continue;
		
		if (IsClientSourceTV(i))
		{
			specHud_clients[specHud_total++] = i;
			continue;
		}
		
		int team = GetClientTeam(i);
		switch (team)
		{
		case 3:
			{
				if (bTankHudActive[i])
					tankHud_clients[tankHud_total++] = i;
			}
		case 1:
			{
				if (bSpecHudActive[i])
					specHud_clients[specHud_total++] = i;
				else if (bTankHudActive[i])
					tankHud_clients[tankHud_total++] = i;
			}
		}
	}
	
	if (specHud_total) // Only bother if someone's watching us
	{
		Panel specHud = new Panel();
		
		FillHeaderInfo(specHud);
		FillSurvivorInfo(specHud);
		FillScoreInfo(specHud);
		FillInfectedInfo(specHud);
		if (!FillTankInfo(specHud))
			FillGameInfo(specHud);

		for (int i = 0; i < specHud_total; ++i)
		{
			int client = specHud_clients[i];
			
			switch (GetClientMenu(client))
			{
				case MenuSource_External, MenuSource_Normal: continue;
			}
			
			specHud.Send(client, DummySpecHudHandler, 3);
			if (!bSpecHudHintShown[client])
			{
				bSpecHudHintShown[client] = true;
				CPrintToChat(client, "%t", "Notify_SpechudUsage");
			}
		}
		delete specHud;
	}
	
	if (!tankHud_total) return Plugin_Continue;
	
	Panel tankHud = new Panel();
	if (FillTankInfo(tankHud, true)) // No tank -- no HUD
	{
		for (int i = 0; i < tankHud_total; ++i)
		{
			int client = tankHud_clients[i];
			
			switch (GetClientMenu(client))
			{
				case MenuSource_External, MenuSource_Normal: continue;
			}
			
			tankHud.Send(client, DummyTankHudHandler, 3);
			if (!bTankHudHintShown[client])
			{
				bTankHudHintShown[client] = true;
				CPrintToChat(client, "%t", "Notify_TankhudUsage");
			}
		}
	}
	
	delete tankHud;
	return Plugin_Continue;
}

public int DummySpecHudHandler(Menu hMenu, MenuAction action, int param1, int param2) { return 1; }
public int DummyTankHudHandler(Menu hMenu, MenuAction action, int param1, int param2) { return 1; }

/**********************************************************************************************/

// ======================================================================
//  HUD Content
// ======================================================================
void FillHeaderInfo(Panel hSpecHud)
{
	static int iTickrate = 0;
	if (iTickrate == 0 && IsServerProcessing())
		iTickrate = RoundToNearest(1.0 / GetTickInterval());
	
	static char buf[64];
	Format(buf, sizeof(buf), "Server: %s [Slots %i/%i | %iT]", sHostname, GetRealClientCount(), iMaxPlayers, iTickrate);
	DrawPanelText(hSpecHud, buf);
}

void GetMeleePrefix(int client, char[] prefix, int length)
{
	int secondary = GetPlayerWeaponSlot(client, L4D2WeaponSlot_Secondary);
	if (secondary == -1)
		return;
	
	static char buf[4];
	switch (IdentifyWeapon(secondary))
	{
		case WEPID_NONE: buf = "N";
		case WEPID_PISTOL: buf = (GetEntProp(secondary, Prop_Send, "m_isDualWielding") ? "DP" : "P");
		case WEPID_PISTOL_MAGNUM: buf = "DE";
		case WEPID_MELEE: buf = "M";
		default: buf = "?";
	}

	strcopy(prefix, length, buf);
}

void GetWeaponInfo(int client, char[] info, int length)
{
	static char buffer[32];
	
	int activeWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int primaryWep = GetPlayerWeaponSlot(client, L4D2WeaponSlot_Primary);
	int activeWepId = IdentifyWeapon(activeWep);
	int primaryWepId = IdentifyWeapon(primaryWep);
	
	// Let's begin with what player is holding,
	// but cares only pistols if holding secondary.
	switch (activeWepId)
	{
		case WEPID_PISTOL, WEPID_PISTOL_MAGNUM:
		{
			if (activeWepId == WEPID_PISTOL && !!GetEntProp(activeWep, Prop_Send, "m_isDualWielding"))
			{
				// Dual Pistols Scenario
				// Straight use the prefix since full name is a bit long.
				Format(buffer, sizeof(buffer), "DP");
			}
			else GetLongWeaponName(activeWepId, buffer, sizeof(buffer));
			
			FormatEx(info, length, "%s %i", buffer, GetWeaponClipAmmo(activeWep));
		}
		default:
		{
			GetLongWeaponName(primaryWepId, buffer, sizeof(buffer));
			FormatEx(info, length, "%s %i/%i", buffer, GetWeaponClipAmmo(primaryWep), GetWeaponExtraAmmo(client, primaryWepId));
		}
	}
	
	// Format our result info
	if (primaryWep == -1)
	{
		// In case with no primary,
		// show the melee full name.
		if (activeWepId == WEPID_MELEE || activeWepId == WEPID_CHAINSAW)
		{
			int meleeWepId = IdentifyMeleeWeapon(activeWep);
			GetLongMeleeWeaponName(meleeWepId, info, length);
		}
	}
	else
	{
		// Default display -> [Primary <In Detail> | Secondary <Prefix>]
		// Holding melee included in this way
		// i.e. [Chrome 8/56 | M]
		if (GetSlotFromWeaponId(activeWepId) != L4D2WeaponSlot_Secondary || activeWepId == WEPID_MELEE || activeWepId == WEPID_CHAINSAW)
		{
			GetMeleePrefix(client, buffer, sizeof(buffer));
			Format(info, length, "%s | %s", info, buffer);
		}

		// Secondary active -> [Secondary <In Detail> | Primary <Ammo Sum>]
		// i.e. [Deagle 8 | Mac 700]
		else
		{
			GetLongWeaponName(primaryWepId, buffer, sizeof(buffer));
			Format(info, length, "%s | %s %i", info, buffer, GetWeaponClipAmmo(primaryWep) + GetWeaponExtraAmmo(client, primaryWepId));
		}
	}
}

int SortSurvByCharacter(int elem1, int elem2, const int[] array, Handle hndl)
{
	int sc1 = IdentifySurvivor(elem1);
	int sc2 = IdentifySurvivor(elem2);

	if (sc1 > sc2) { return 1; }
	else if (sc1 < sc2) { return -1; }
	else { return 0; }
}

void FillSurvivorInfo(Panel hSpecHud)
{
	static char info[100];
	static char name[MAX_NAME_LENGTH];

	int SurvivorTeamIndex = GameRules_GetProp("m_bAreTeamsFlipped");

	switch (g_Gamemode)
	{
		case GAMEMODE_SCAVENGE:
		{
			int score = GetScavengeMatchScore(SurvivorTeamIndex);
			FormatEx(info, sizeof(info), "->1. Survivors [%d of %d]", score, GetScavengeRoundLimit());
		}
		case GAMEMODE_VERSUS:
		{
			if (bRoundLive)
			{
				FormatEx(info, sizeof(info), "->1. Survivors [%d]",
							L4D2Direct_GetVSCampaignScore(SurvivorTeamIndex) + GetVersusProgressDistance(SurvivorTeamIndex));
			}
			else
			{
				FormatEx(info, sizeof(info), "->1. Survivors [%d]",
							L4D2Direct_GetVSCampaignScore(SurvivorTeamIndex));
			}
		}
	}
	
	DrawPanelText(hSpecHud, " ");
	DrawPanelText(hSpecHud, info);
	
	int total = 0;
	int[] clients = new int[MaxClients];
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;
		
		clients[total++] = i;
	}
	
	SortCustom1D(clients, total, SortSurvByCharacter);
	
	for (int i = 0; i < total; ++i)
	{
		int client = clients[i];
		
		GetClientFixedName(client, name, sizeof(name));
		if (!IsPlayerAlive(client))
		{
			FormatEx(info, sizeof(info), "%s: Dead", name);
		}
		else
		{
			if (IsHangingFromLedge(client))
			{
				// Nick: <300HP@Hanging>
				FormatEx(info, sizeof(info), "%s: <%iHP@Hanging>", name, GetClientHealth(client));
			}
			else if (IsIncapacitated(client))
			{
				int activeWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				GetLongWeaponName(IdentifyWeapon(activeWep), info, sizeof(info));
				// Nick: <300HP@1st> [Deagle 8]
				Format(info, sizeof(info), "%s: <%iHP@%s> [%s %i]", name, GetClientHealth(client), (GetSurvivorIncapCount(client) == 1 ? "2nd" : "1st"), info, GetWeaponClipAmmo(activeWep));
			}
			else
			{
				GetWeaponInfo(client, info, sizeof(info));
				
				int tempHealth = GetSurvivorTemporaryHealth(client);
				int health = GetClientHealth(client) + tempHealth;
				int incapCount = GetSurvivorIncapCount(client);
				if (incapCount == 0)
				{
					// "#" indicates that player is bleeding.
					// Nick: 99HP# [Chrome 8/72]
					Format(info, sizeof(info), "%s: %iHP%s [%s]", name, health, (tempHealth > 0 ? "#" : ""), info);
				}
				else
				{
					// Player ever incapped should always be bleeding.
					// Nick: 99HP (#1st) [Chrome 8/72]
					Format(info, sizeof(info), "%s: %iHP (#%s) [%s]", name, health, (incapCount == 2 ? "2nd" : "1st"), info);
				}
			}
		}
		
		DrawPanelText(hSpecHud, info);
	}
}

void FillScoreInfo(Panel hSpecHud)
{
	static char info[64];
	
	switch (g_Gamemode)
	{
		case GAMEMODE_SCAVENGE:
		{
			bool bSecondHalf = InSecondHalfOfRound();
			bool bTeamFlipped = !!GameRules_GetProp("m_bAreTeamsFlipped");
			
			float fDuration = GetScavengeRoundDuration(bTeamFlipped);
			int iMinutes = RoundToFloor(fDuration / 60);
			
			DrawPanelText(hSpecHud, " ");
				
			FormatEx(info, sizeof(info), "> Accumulated Time [%02d:%02.0f]", iMinutes, fDuration - 60 * iMinutes);
			DrawPanelText(hSpecHud, info);
			
			if (bSecondHalf)
			{
				fDuration = GetScavengeRoundDuration(!bTeamFlipped);
				iMinutes = RoundToFloor(fDuration / 60);
				
				FormatEx(info, sizeof(info), "> Opponent Duration [%02d:%05.2f]", iMinutes, fDuration - 60 * iMinutes);
				DrawPanelText(hSpecHud, info);
			}
		}
		
		case GAMEMODE_VERSUS:
		{
			if (bHybridScoremod)
			{
				int healthBonus	= SMPlus_GetHealthBonus(),	maxHealthBonus	= SMPlus_GetMaxHealthBonus();
				int damageBonus	= SMPlus_GetDamageBonus(),	maxDamageBonus	= SMPlus_GetMaxDamageBonus();
				int pillsBonus	= SMPlus_GetPillsBonus(),	maxPillsBonus	= SMPlus_GetMaxPillsBonus();
				
				int totalBonus		= healthBonus		+ damageBonus		+ pillsBonus;
				int maxTotalBonus	= maxHealthBonus	+ maxDamageBonus	+ maxPillsBonus;
				
				DrawPanelText(hSpecHud, " ");
				
				// > HB: 100% | DB: 100% | Pills: 60 / 100%
				// > Bonus: 860 <100.0%>
				// > Distance: 400
				
				FormatEx(	info,
							sizeof(info),
							"> HB: %.0f%% | DB: %.0f%% | Pills: %i / %.0f%%",
							L4D2Util_IntToPercentFloat(healthBonus, maxHealthBonus),
							L4D2Util_IntToPercentFloat(damageBonus, maxDamageBonus),
							pillsBonus, L4D2Util_IntToPercentFloat(pillsBonus, maxPillsBonus));
				DrawPanelText(hSpecHud, info);
				
				FormatEx(info, sizeof(info), "> Bonus: %i <%.1f%%>", totalBonus, L4D2Util_IntToPercentFloat(totalBonus, maxTotalBonus));
				DrawPanelText(hSpecHud, info);
				
				FormatEx(info, sizeof(info), "> Distance: %i", iMaxDistance);
				//if (InSecondHalfOfRound())
				//{
				//	Format(info, sizeof(info), "%s | R#1: %i <%.1f%%>", info, iFirstHalfScore, L4D2Util_IntToPercentFloat(iFirstHalfScore, L4D_GetVersusMaxCompletionScore() + maxTotalBonus));
				//}
				DrawPanelText(hSpecHud, info);
			}
			
			else if (bScoremod)
			{
				int healthBonus = HealthBonus();
				
				DrawPanelText(hSpecHud, " ");
				
				// > Health Bonus: 860
				// > Distance: 400
				
				FormatEx(info, sizeof(info), "> Health Bonus: %i", healthBonus);
				DrawPanelText(hSpecHud, info);
				
				FormatEx(info, sizeof(info), "> Distance: %i", iMaxDistance);
				//if (InSecondHalfOfRound())
				//{
				//	Format(info, sizeof(info), "%s | R#1: %i", info, iFirstHalfScore);
				//}
				DrawPanelText(hSpecHud, info);
			}
			
			else if (bNextScoremod)
			{
				int permBonus	= SMNext_GetPermBonus(),	maxPermBonus	= SMNext_GetMaxPermBonus();
				int tempBonus	= SMNext_GetTempBonus(),	maxTempBonus	= SMNext_GetMaxTempBonus();
				int pillsBonus	= SMNext_GetPillsBonus(),	maxPillsBonus	= SMNext_GetMaxPillsBonus();
				
				int totalBonus		= permBonus		+ tempBonus		+ pillsBonus;
				int maxTotalBonus	= maxPermBonus	+ maxTempBonus	+ maxPillsBonus;
				
				DrawPanelText(hSpecHud, " ");
				
				// > Perm: 114 | Temp: 514 | Pills: 810
				// > Bonus: 114514 <100.0%>
				// > Distance: 191
				// never ever played on Next so take it easy.
				
				FormatEx(	info,
							sizeof(info),
							"> Perm: %i | Temp: %i | Pills: %i",
							permBonus, tempBonus, pillsBonus);
				DrawPanelText(hSpecHud, info);
				
				FormatEx(info, sizeof(info), "> Bonus: %i <%.1f%%>", totalBonus, L4D2Util_IntToPercentFloat(totalBonus, maxTotalBonus));
				DrawPanelText(hSpecHud, info);
				
				FormatEx(info, sizeof(info), "> Distance: %i", iMaxDistance);
				//if (InSecondHalfOfRound())
				//{
				//	Format(info, sizeof(info), "%s | R#1: %i <%.1f%%>", info, iFirstHalfScore, ToPercent(iFirstHalfScore, L4D_GetVersusMaxCompletionScore() + maxTotalBonus));
				//}
				DrawPanelText(hSpecHud, info);
			}
		}
	}
}

void FillInfectedInfo(Panel hSpecHud)
{
	static char info[80];
	static char buffer[16];
	static char name[MAX_NAME_LENGTH];

	int InfectedTeamIndex = !GameRules_GetProp("m_bAreTeamsFlipped");
	
	switch (g_Gamemode)
	{
		case GAMEMODE_SCAVENGE:
		{
			int score = GetScavengeMatchScore(InfectedTeamIndex);
			FormatEx(info, sizeof(info), "->2. Infected [%d of %d]", score, GetScavengeRoundLimit());
		}
		case GAMEMODE_VERSUS:
		{
			FormatEx(info, sizeof(info), "->2. Infected [%d]",
						L4D2Direct_GetVSCampaignScore(InfectedTeamIndex));
		}
	}
	
	DrawPanelText(hSpecHud, " ");
	DrawPanelText(hSpecHud, info);

	int infectedCount = 0;
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (!IsClientInGame(client) || GetClientTeam(client) != 3)
			continue;
		
		GetClientFixedName(client, name, sizeof(name));
		if (!IsPlayerAlive(client)) 
		{
			int timeLeft = RoundToFloor(L4D_GetPlayerSpawnTime(client));
			if (timeLeft < 0) // Deathcam
			{
				// verygood: Dead
				FormatEx(info, sizeof(info), "%s: Dead", name);
			}
			else // Ghost Countdown
			{
				FormatEx(buffer, sizeof(buffer), "%is", timeLeft);
				// verygood: Dead (15s)
				FormatEx(info, sizeof(info), "%s: Dead (%s)", name, (timeLeft ? buffer : "Spawning..."));
				
				//char zClassName[10];
				//GetInfectedClassName(storedClass[client], zClassName, sizeof zClassName);
				//if (storedClass[client] > L4D2Team_None)
				//{
				//	FormatEx(info, sizeof(info), "%s: Dead (%s) [%s]", name, zClassName, (RoundToNearest(timeLeft) ? buffer : "Spawning..."));
				//} else {
				//	FormatEx(info, sizeof(info), "%s: Dead (%s)", name, (RoundToNearest(timeLeft) ? buffer : "Spawning..."));
				//}
			}
		}
		else
		{
			int zClass = GetInfectedClass(client);
			if (zClass == L4D2Infected_Tank)
				continue;
				
			char zClassName[10];
			GetInfectedClassName(zClass, zClassName, sizeof(zClassName));
			
			int iHP = GetClientHealth(client), iMaxHP = GetEntProp(client, Prop_Send, "m_iMaxHealth");
			if (IsInfectedGhost(client))
			{
				// DONE: Handle a case of respawning chipped SI, show the ghost's health
				if (iHP < iMaxHP)
				{
					// verygood: Charger (Ghost@1HP)
					FormatEx(info, sizeof(info), "%s: %s (Ghost@%iHP)", name, zClassName, iHP);
				}
				else
				{
					// verygood: Charger (Ghost)
					FormatEx(info, sizeof(info), "%s: %s (Ghost)", name, zClassName);
				}
			}
			else
			{
				buffer[0] = '\0';
				
				float fTimestamp, fDuration;
				if (GetInfectedAbilityTimer(client, fTimestamp, fDuration))
				{
					int iCooldown = RoundToCeil(fTimestamp - GetGameTime());
					
					if (iCooldown > 0
						&& fDuration > 1.0
						&& fDuration != 3600
						&& GetInfectedVictim(client) <= 0)
					{
						FormatEx(buffer, sizeof(buffer), " [%is]", iCooldown);
					}
				}
				
				if (GetEntityFlags(client) & FL_ONFIRE)
				{
					// verygood: Charger (1HP) [On Fire] [6s]
					FormatEx(info, sizeof(info), "%s: %s (%iHP) [On Fire]%s", name, zClassName, iHP, buffer);
				}
				else
				{
					// verygood: Charger (1HP) [6s]
					FormatEx(info, sizeof(info), "%s: %s (%iHP)%s", name, zClassName, iHP, buffer);
				}
			}
		}

		infectedCount++;
		DrawPanelText(hSpecHud, info);
	}
	
	if (!infectedCount)
	{
		DrawPanelText(hSpecHud, "There is no SI at this moment.");
	}
}

bool FillTankInfo(Panel hSpecHud, bool bTankHUD = false)
{
	int tank = FindTankClient(-1);
	if (tank == -1 || !IsPlayerAlive(tank))
		return false;

	static char info[64];
	static char name[MAX_NAME_LENGTH];

	if (bTankHUD)
	{
		FormatEx(info, sizeof(info), "%s :: Tank HUD", sReadyCfgName);
		ValvePanel_ShiftInvalidString(info, sizeof(info));
		DrawPanelText(hSpecHud, info);
		
		int len = strlen(info);
		for (int i = 0; i < len; ++i) info[i] = '_';
		DrawPanelText(hSpecHud, info);
	}
	else
	{
		DrawPanelText(hSpecHud, " ");
		DrawPanelText(hSpecHud, "->3. Tank");
	}

	// Draw owner & pass counter
	int passCount = L4D2Direct_GetTankPassedCount();
	switch (passCount)
	{
		case 0: FormatEx(info, sizeof(info), "native");
		case 1: FormatEx(info, sizeof(info), "%ist", passCount);
		case 2: FormatEx(info, sizeof(info), "%ind", passCount);
		case 3: FormatEx(info, sizeof(info), "%ird", passCount);
		default: FormatEx(info, sizeof(info), "%ith", passCount);
	}

	if (!IsFakeClient(tank))
	{
		GetClientFixedName(tank, name, sizeof(name));
		Format(info, sizeof(info), "Control : %s (%s)", name, info);
	}
	else
	{
		Format(info, sizeof(info), "Control : AI (%s)", info);
	}
	DrawPanelText(hSpecHud, info);

	// Draw health
	int health = GetClientHealth(tank);
	int maxhealth = GetEntProp(tank, Prop_Send, "m_iMaxHealth");
	float healthPercent = L4D2Util_IntToPercentFloat(health, maxhealth); // * 100 already
	
	if (health <= 0 || IsIncapacitated(tank))
	{
		info = "Health  : Dead";
	}
	else
	{
		FormatEx(info, sizeof(info), "Health  : %i / %i%%", health, L4D2Util_GetMax(1, RoundFloat(healthPercent)));
	}
	DrawPanelText(hSpecHud, info);

	// Draw frustration
	if (!IsFakeClient(tank))
	{
		FormatEx(info, sizeof(info), "Frustr.  : %d%%", GetTankFrustration(tank));
	}
	else
	{
		info = "Frustr.  : AI";
	}
	DrawPanelText(hSpecHud, info);

	// Draw network
	if (!IsFakeClient(tank))
	{
		FormatEx(info, sizeof(info), "Network: %ims / %.1f", RoundToNearest(GetClientAvgLatency(tank, NetFlow_Both) * 1000.0), LM_GetLerpTime(tank) * 1000.0);
	}
	else
	{
		info = "Network: AI";
	}
	DrawPanelText(hSpecHud, info);

	// Draw fire status
	if (GetEntityFlags(tank) & FL_ONFIRE)
	{
		int timeleft = RoundToCeil(healthPercent / 100.0 * fTankBurnDuration);
		FormatEx(info, sizeof(info), "On Fire : %is", timeleft);
		DrawPanelText(hSpecHud, info);
	}
	
	return true;
}

void FillGameInfo(Panel hSpecHud)
{
	// Turns out too much info actually CAN be bad, funny ikr
	static char info[64];
	static char buffer[10];

	switch (g_Gamemode)
	{
		case GAMEMODE_SCAVENGE:
		{
			FormatEx(info, sizeof(info), "->3. %s (R#%i)", sReadyCfgName, GetScavengeRoundNumber());
			
			DrawPanelText(hSpecHud, " ");
			DrawPanelText(hSpecHud, info);
			
			FormatEx(info, sizeof(info), "Best of %i", GetScavengeRoundLimit());
			DrawPanelText(hSpecHud, info);
		}
		
		case GAMEMODE_VERSUS:
		{
			FormatEx(info, sizeof(info), "->3. %s (R#%d)", sReadyCfgName, 1 + view_as<int>(InSecondHalfOfRound()));
			DrawPanelText(hSpecHud, " ");
			DrawPanelText(hSpecHud, info);
			
			if (l4d_tank_percent != null && l4d_witch_percent != null)
			{
				int survivorFlow = GetHighestSurvivorFlow();
				if (survivorFlow == -1)
					survivorFlow = GetFurthestSurvivorFlow();
				
				bool bDivide = false;
						
				// tank percent
				if (iTankCount > 0)
				{
					bDivide = true;
					FormatEx(buffer, sizeof(buffer), "%i%%", iTankFlow);
					
					if ((bFlowTankActive && bRoundHasFlowTank) || bCustomBossSys)
					{
						FormatEx(info, sizeof(info), "Tank: %s", buffer);
					}
					else
					{
						FormatEx(info, sizeof(info), "Tank: %s", (bStaticTank ? "Static" : "Event"));
					}
				}
				
				// witch percent
				if (iWitchCount > 0)
				{
					FormatEx(buffer, sizeof(buffer), "%i%%", iWitchFlow);
					
					if (bDivide) {
						Format(info, sizeof(info), "%s | Witch: %s", info, ((bRoundHasFlowWitch || bCustomBossSys) ? buffer : (bStaticWitch ? "Static" : "Event")));
					} else {
						bDivide = true;
						FormatEx(info, sizeof(info), "Witch: %s", ((bRoundHasFlowWitch || bCustomBossSys) ? buffer : (bStaticWitch ? "Static" : "Event")));
					}
				}
				
				// current
				if (bDivide) {
					Format(info, sizeof(info), "%s | Cur: %i%%", info, survivorFlow);
				} else {
					FormatEx(info, sizeof(info), "Cur: %i%%", survivorFlow);
				}
				
				DrawPanelText(hSpecHud, info);
			}
			
			// tank selection
			if (bTankSelection && iTankCount > 0)
			{
				int tankClient = GetTankSelection();
				if (tankClient > 0 && IsClientInGame(tankClient))
				{
					FormatEx(info, sizeof(info), "Tank -> %N", tankClient);
					DrawPanelText(hSpecHud, info);
				}
			}
		}
	}
}

/**
 *	Stocks
**/
/**
 *	Datamap m_iAmmo
 *	offset to add - gun(s) - control cvar
 *	
 *	+12: M4A1, AK74, Desert Rifle, also SG552 - ammo_assaultrifle_max
 *	+20: both SMGs, also the MP5 - ammo_smg_max
 *	+28: both Pump Shotguns - ammo_shotgun_max
 *	+32: both autoshotguns - ammo_autoshotgun_max
 *	+36: Hunting Rifle - ammo_huntingrifle_max
 *	+40: Military Sniper, AWP, Scout - ammo_sniperrifle_max
 *	+68: Grenade Launcher - ammo_grenadelauncher_max
 */

#define	ASSAULT_RIFLE_OFFSET_IAMMO		12;
#define	SMG_OFFSET_IAMMO				20;
#define	PUMPSHOTGUN_OFFSET_IAMMO		28;
#define	AUTO_SHOTGUN_OFFSET_IAMMO		32;
#define	HUNTING_RIFLE_OFFSET_IAMMO		36;
#define	MILITARY_SNIPER_OFFSET_IAMMO	40;
#define	GRENADE_LAUNCHER_OFFSET_IAMMO	68;

stock int GetWeaponExtraAmmo(int client, int wepid)
{
	static int ammoOffset;
	if (!ammoOffset) ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	
	int offset;
	switch (wepid)
	{
		case WEPID_RIFLE, WEPID_RIFLE_AK47, WEPID_RIFLE_DESERT, WEPID_RIFLE_SG552:
			offset = ASSAULT_RIFLE_OFFSET_IAMMO
		case WEPID_SMG, WEPID_SMG_SILENCED:
			offset = SMG_OFFSET_IAMMO
		case WEPID_PUMPSHOTGUN, WEPID_SHOTGUN_CHROME:
			offset = PUMPSHOTGUN_OFFSET_IAMMO
		case WEPID_AUTOSHOTGUN, WEPID_SHOTGUN_SPAS:
			offset = AUTO_SHOTGUN_OFFSET_IAMMO
		case WEPID_HUNTING_RIFLE:
			offset = HUNTING_RIFLE_OFFSET_IAMMO
		case WEPID_SNIPER_MILITARY, WEPID_SNIPER_AWP, WEPID_SNIPER_SCOUT:
			offset = MILITARY_SNIPER_OFFSET_IAMMO
		case WEPID_GRENADE_LAUNCHER:
			offset = GRENADE_LAUNCHER_OFFSET_IAMMO
		default:
			return -1;
	}
	return GetEntData(client, ammoOffset + offset);
} 

stock int GetWeaponClipAmmo(int weapon)
{
	return (weapon > 0 ? GetEntProp(weapon, Prop_Send, "m_iClip1") : -1);
}

stock void GetClientFixedName(int client, char[] name, int length)
{
	GetClientName(client, name, length);

	ValvePanel_ShiftInvalidString(name, length);

	if (strlen(name) > 18)
	{
		name[15] = name[16] = name[17] = '.';
		name[18] = 0;
	}
}

stock bool ValvePanel_ShiftInvalidString(char[] str, int maxlen)
{
	switch (str[0])
	{
	case '[':
		{
			char[] temp = new char[maxlen];
			strcopy(temp, maxlen, str) + 1;
			
			int size = strcopy(str[1], maxlen-1, temp) + 1;
			
			str[0] = ' ';
			str[size < maxlen ? size : maxlen-1] = '\0';
			
			return true;
		}
	}
	
	return false;
}

//stock int GetRealTeam(int team)
//{
//	return team ^ view_as<int>(InSecondHalfOfRound() != GameRules_GetProp("m_bAreTeamsFlipped"));
//}

stock int GetRealClientCount() 
{
	int clients = 0;
	for (int i = 1; i <= MaxClients; ++i) 
	{
		if (IsClientConnected(i) && !IsFakeClient(i)) clients++;
	}
	return clients;
}

stock int GetVersusProgressDistance(int teamIndex)
{
	int distance = 0;
	for (int i = 0; i < 4; ++i)
	{
		distance += GameRules_GetProp("m_iVersusDistancePerSurvivor", _, i + 4 * teamIndex);
	}
	return distance;
}

/*
 * Future use
 */
stock void FillScavengeScores(int arr[2][5])
{
	for (int i = 1; i <= GetScavengeRoundLimit(); ++i)
	{
		arr[0][i-1] = GetScavengeTeamScore(0, i);
		arr[1][i-1] = GetScavengeTeamScore(1, i);
	}
}

stock int FormatScavengeRoundTime(char[] buffer, int maxlen, int teamIndex, bool nodecimalpoint = false)
{
	float seconds = GetScavengeRoundDuration(teamIndex);
	int minutes = RoundToFloor(seconds) / 60;
	seconds -= 60 * minutes;
	
	return nodecimalpoint ?
				Format(buffer, maxlen, "%d:%02.0f", minutes, seconds) :
				Format(buffer, maxlen, "%d:%05.2f", minutes, seconds);
}

/* 
 * GetScavengeRoundDuration & GetScavengeTeamScore
 * credit to ProdigySim
 */
stock float GetScavengeRoundDuration(int teamIndex)
{
	float flRoundStartTime = GameRules_GetPropFloat("m_flRoundStartTime");
	if (teamIndex == view_as<int>(GameRules_GetProp("m_bAreTeamsFlipped")) && flRoundStartTime != 0.0 && GameRules_GetPropFloat("m_flRoundEndTime") == 0.0)
	{
		// Survivor team still playing round.
		return GetGameTime() - flRoundStartTime;
	}
	return GameRules_GetPropFloat("m_flRoundDuration", teamIndex);
}

stock int GetScavengeTeamScore(int teamIndex, int round=-1)
{
	if (!(1 <= round <= 5))
	{
		round = GameRules_GetProp("m_nRoundNumber");
	}
	return GameRules_GetProp("m_iScavengeTeamScore", _, (2*(round-1)) + teamIndex);
}

stock int GetScavengeMatchScore(int teamIndex)
{
	return GameRules_GetProp("m_iScavengeMatchScore", _, teamIndex);
}

stock int GetScavengeRoundNumber()
{
	return GameRules_GetProp("m_nRoundNumber");
}

stock int GetScavengeRoundLimit()
{
	return GameRules_GetProp("m_nRoundLimit");
}

stock int GetFurthestSurvivorFlow()
{
	int flow = RoundToNearest(100.0 * (L4D2_GetFurthestSurvivorFlow() + fVersusBossBuffer) / L4D2Direct_GetMapMaxFlowDistance());
	return flow < 100 ? flow : 100;
}

//stock float GetClientFlow(int client)
//{
//	return (L4D2Direct_GetFlowDistance(client) / L4D2Direct_GetMapMaxFlowDistance());
//}

stock int GetHighestSurvivorFlow()
{
	int flow = -1;
	
	int client = L4D_GetHighestFlowSurvivor();
	if (client > 0) {
		flow = RoundToNearest(100.0 * (L4D2Direct_GetFlowDistance(client) + fVersusBossBuffer) / L4D2Direct_GetMapMaxFlowDistance());
	}
	
	return flow < 100 ? flow : 100;
}

stock int GetRoundTankFlow()
{
	return RoundToNearest(L4D2Direct_GetVSTankFlowPercent(InSecondHalfOfRound()) + fVersusBossBuffer / L4D2Direct_GetMapMaxFlowDistance());
}

stock int GetRoundWitchFlow()
{
	return RoundToNearest(L4D2Direct_GetVSWitchFlowPercent(InSecondHalfOfRound()) + fVersusBossBuffer / L4D2Direct_GetMapMaxFlowDistance());
}

stock bool RoundHasFlowTank()
{
	return L4D2Direct_GetVSTankToSpawnThisRound(InSecondHalfOfRound());
}

stock bool RoundHasFlowWitch()
{
	return L4D2Direct_GetVSWitchToSpawnThisRound(InSecondHalfOfRound());
}