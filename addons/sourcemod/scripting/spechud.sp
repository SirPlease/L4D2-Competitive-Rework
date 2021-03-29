#include <sourcemod>
#include <sdktools>
#include <builtinvotes>
#include <l4d2_weapon_stocks>
#include <colors>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <readyup>
#include <pause>
#include <l4d2_boss_percents>
#include <l4d2_hybrid_scoremod>
#include <l4d2_scoremod>
#include <l4d2_health_temp_bonus>
#include <l4d_tank_control_eq>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION	"3.4.5"

public Plugin myinfo = 
{
	name = "Hyper-V HUD Manager",
	author = "Visor, Forgetest",
	description = "Provides different HUDs for spectators",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define SPECHUD_DRAW_INTERVAL   0.5

#define ZOMBIECLASS_NAME(%0) (L4D2SI_Names[(%0)])

#define CLAMP(%0,%1,%2) (((%0) > (%2)) ? (%2) : (((%0) < (%1)) ? (%1) : (%0)))
#define MAX(%0,%1) (((%0) > (%1)) ? (%0) : (%1))
#define MIN(%0,%1) (((%0) < (%1)) ? (%0) : (%1))

#define TEAM_NONE 0
#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

enum L4D2Gamemode
{
	L4D2Gamemode_None,
	L4D2Gamemode_Versus,
	L4D2Gamemode_Scavenge
};
L4D2Gamemode g_Gamemode;

enum L4D2SI 
{
	ZC_None,
	ZC_Smoker,
	ZC_Boomer,
	ZC_Hunter,
	ZC_Spitter,
	ZC_Jockey,
	ZC_Charger,
	ZC_Witch,
	ZC_Tank
};
//L4D2SI storedClass[MAXPLAYERS+1];

static const char L4D2SI_Names[][] = 
{
	"None",
	"Smoker",
	"Boomer",
	"Hunter",
	"Spitter",
	"Jockey",
	"Charger",
	"Witch",
	"Tank"
};

enum SurvivorCharacter
{
	SC_NONE=-1,
	SC_NICK=0,
	SC_ROCHELLE,
	SC_COACH,
	SC_ELLIS,
	SC_BILL,
	SC_ZOEY,
	SC_LOUIS,
	SC_FRANCIS
};

// Game Var
ConVar survivor_limit, z_max_player_zombies, versus_boss_buffer, mp_gamemode, sv_maxplayers, tank_burn_duration, pain_pills_decay_rate;
int iSurvivorLimit, iMaxPlayerZombies, iMaxPlayers;
float fVersusBossBuffer, fTankBurnDuration, fPainPillsDecayRate;

// Network Var
ConVar cVarMinUpdateRate, cVarMaxUpdateRate, cVarMinInterpRatio, cVarMaxInterpRatio;
float fMinUpdateRate, fMaxUpdateRate, fMinInterpRatio, fMaxInterpRatio;

// Plugin Cvar
ConVar l4d_tank_percent, l4d_witch_percent, hServerNamer, l4d_ready_cfg_name;

// Plugin Var
char sReadyCfgName[64], sHostname[64];
bool bPendingArrayRefresh, bRoundLive;
int iSurvivorArray[MAXPLAYERS+1];

// Plugin Handle
//ArrayList hSurvivorArray;

// Finale Tank Spawn Scheme
StringMap hFirstTankSpawningScheme, hSecondTankSpawningScheme;		// eq_finale_tanks (Zonemod, Acemod, etc.)
StringMap hFinaleExceptionMaps;										// finale_tank_blocker (Promod and older?)

// Flow Bosses
int iTankCount, iWitchCount;
bool bRoundHasFlowTank, bRoundHasFlowWitch, bFlowTankActive;

// Score & Scoremod
//int iFirstHalfScore;
bool bScoremod, bHybridScoremod, bNextScoremod;

// Tank Control EQ
bool bTankSelection;

// Hud Toggle & Hint Message
bool bSpecHudActive[MAXPLAYERS+1], bTankHudActive[MAXPLAYERS+1], bDebugActive[MAXPLAYERS+1];
bool bSpecHudHintShown[MAXPLAYERS+1], bTankHudHintShown[MAXPLAYERS+1];

public void OnPluginStart()
{
	survivor_limit			= FindConVar("survivor_limit");
	z_max_player_zombies	= FindConVar("z_max_player_zombies");
	versus_boss_buffer		= FindConVar("versus_boss_buffer");
	mp_gamemode				= FindConVar("mp_gamemode");
	sv_maxplayers			= FindConVar("sv_maxplayers");
	tank_burn_duration		= FindConVar("tank_burn_duration");
	pain_pills_decay_rate	= FindConVar("pain_pills_decay_rate");
	
	l4d_tank_percent		= FindConVar("l4d_tank_percent");
	l4d_witch_percent		= FindConVar("l4d_witch_percent");
	l4d_ready_cfg_name		= FindConVar("l4d_ready_cfg_name");
	
	if ((hServerNamer = FindConVar("sn_main_name")) == null)
	{
		hServerNamer = FindConVar("hostname");
	}
	hServerNamer.GetString(sHostname, sizeof(sHostname));
	hServerNamer.AddChangeHook(OnHostnameChanged);
	
	l4d_ready_cfg_name.GetString(sReadyCfgName, sizeof(sReadyCfgName));
	
	cVarMinUpdateRate		= FindConVar("sv_minupdaterate");
	cVarMaxUpdateRate		= FindConVar("sv_maxupdaterate");
	cVarMinInterpRatio		= FindConVar("sv_client_min_interp_ratio");
	cVarMaxInterpRatio		= FindConVar("sv_client_max_interp_ratio");
	
	iSurvivorLimit		= survivor_limit.IntValue;
	iMaxPlayerZombies	= z_max_player_zombies.IntValue;
	fVersusBossBuffer	= versus_boss_buffer.FloatValue;
	GetCurrentGameMode();
	iMaxPlayers			= sv_maxplayers.IntValue;
	fTankBurnDuration	= tank_burn_duration.FloatValue;
	fPainPillsDecayRate	= pain_pills_decay_rate.FloatValue;
	
	survivor_limit.AddChangeHook(OnGameConVarChanged);
	z_max_player_zombies.AddChangeHook(OnGameConVarChanged);
	versus_boss_buffer.AddChangeHook(OnGameConVarChanged);
	mp_gamemode.AddChangeHook(OnGameConVarChanged);
	sv_maxplayers.AddChangeHook(OnGameConVarChanged);
	
	fMinUpdateRate		= cVarMinUpdateRate.FloatValue;
	fMaxUpdateRate		= cVarMaxUpdateRate.FloatValue;
	fMinInterpRatio		= cVarMinInterpRatio.FloatValue;
	fMaxInterpRatio		= cVarMaxInterpRatio.FloatValue;
	
	cVarMinUpdateRate.AddChangeHook(OnNetworkConVarChanged);
	cVarMaxUpdateRate.AddChangeHook(OnNetworkConVarChanged);
	cVarMinInterpRatio.AddChangeHook(OnNetworkConVarChanged);
	cVarMaxInterpRatio.AddChangeHook(OnNetworkConVarChanged);
	
	hFirstTankSpawningScheme	= new StringMap();
	hSecondTankSpawningScheme	= new StringMap();
	hFinaleExceptionMaps		= new StringMap();
	
	RegConsoleCmd("sm_spechud", ToggleSpecHudCmd);
	RegConsoleCmd("sm_tankhud", ToggleTankHudCmd);
	
	RegServerCmd("tank_map_flow_and_second_event",	SetMapFirstTankSpawningScheme);
	RegServerCmd("tank_map_only_first_event",		SetMapSecondTankSpawningScheme);
	RegServerCmd("finale_tank_default",				SetFinaleExceptionMap);
	
	RegAdminCmd("sm_debugspechud", DebugSpecHudCmd, ADMFLAG_CHEATS);
	
	HookEvent("round_end",		view_as<EventHook>(Event_RoundEnd), EventHookMode_PostNoCopy);
	HookEvent("player_death",	Event_PlayerDeath);
	HookEvent("witch_killed",	Event_WitchDeath);
	HookEvent("player_team",	Event_PlayerTeam);
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		bSpecHudActive[i] = false;
		bSpecHudHintShown[i] = false;
		bTankHudActive[i] = true;
		bTankHudHintShown[i] = false;
	}
	
	CreateTimer(SPECHUD_DRAW_INTERVAL, HudDrawTimer, _, TIMER_REPEAT);
}

public void OnGameConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	iSurvivorLimit		= survivor_limit.IntValue;
	iMaxPlayerZombies	= z_max_player_zombies.IntValue;
	fVersusBossBuffer	= versus_boss_buffer.FloatValue;
	GetCurrentGameMode();
	iMaxPlayers			= sv_maxplayers.IntValue;
	fTankBurnDuration	= tank_burn_duration.FloatValue;
	fPainPillsDecayRate	= pain_pills_decay_rate.FloatValue;
}

public void OnNetworkConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	fMinUpdateRate	= cVarMinUpdateRate.FloatValue;
	fMaxUpdateRate	= cVarMaxUpdateRate.FloatValue;
	fMinInterpRatio	= cVarMinInterpRatio.FloatValue;
	fMaxInterpRatio	= cVarMaxInterpRatio.FloatValue;
}

public void OnHostnameChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	hServerNamer.GetString(sHostname, sizeof(sHostname));
}

public void OnAllPluginsLoaded()
{
	bScoremod = LibraryExists("l4d2_scoremod");
	bHybridScoremod = LibraryExists("l4d2_hybrid_scoremod") || LibraryExists("l4d2_hybrid_scoremod_zone");
	bNextScoremod = LibraryExists("l4d2_health_temp_bonus");
	if ((hServerNamer = FindConVar("sn_main_name")) == null)
	{
		hServerNamer = FindConVar("hostname");
		hServerNamer.RemoveChangeHook(OnHostnameChanged);
		hServerNamer.GetString(sHostname, sizeof(sHostname));
		hServerNamer.AddChangeHook(OnHostnameChanged);
	}
	if (l4d_ready_cfg_name == null) l4d_ready_cfg_name = FindConVar("l4d_ready_cfg_name");
	
	bTankSelection = (GetFeatureStatus(FeatureType_Native, "GetTankSelection") != FeatureStatus_Unknown);
	
	if (LibraryExists("l4d_boss_percent"))
	{
		if (!l4d_tank_percent) l4d_tank_percent = FindConVar("l4d_tank_percent");
		if (!l4d_witch_percent) l4d_witch_percent = FindConVar("l4d_witch_percent");
	}
}
public void OnLibraryAdded(const char[] name)
{
	if (!strcmp(name, "l4d2_scoremod"))bScoremod = true;
	if (!strcmp(name, "l4d2_hybrid_scoremod") || !strcmp(name, "l4d2_hybrid_scoremod_zone"))bHybridScoremod = true;
	if (!strcmp(name, "l4d2_health_temp_bonus"))bNextScoremod = true;
	if (!strcmp(name, "l4d_boss_percent"))
	{
		l4d_tank_percent = FindConVar("l4d_tank_percent");
		l4d_witch_percent = FindConVar("l4d_witch_percent");
	}
}
public void OnLibraryRemoved(const char[] name)
{
	if (!strcmp(name, "l4d2_scoremod"))bScoremod = false;
	if (!strcmp(name, "l4d2_hybrid_scoremod") || !strcmp(name, "l4d2_hybrid_scoremod_zone"))bHybridScoremod = false;
	if (!strcmp(name, "l4d2_health_temp_bonus"))bNextScoremod = false;
	if (!strcmp(name, "l4d_boss_percent"))
	{
		l4d_tank_percent = null;
		l4d_witch_percent = null;
	}
}

public void OnClientDisconnect(int client)
{
	bSpecHudHintShown[client] = false;
	bTankHudHintShown[client] = false;
	
	if (bDebugActive[client])
	{
		bDebugActive[client] = false;
		bSpecHudActive[client] = false;
		bTankHudActive[client] = true;
	}
}

public void OnMapStart() { bRoundLive = false; }
public void Event_RoundEnd() { bRoundLive = false; }
public void OnRoundIsLive()
{
	l4d_ready_cfg_name.GetString(sReadyCfgName, sizeof(sReadyCfgName));
	
	bRoundLive = true;
	
	GetCurrentGameMode();
	
	//for (int i = 1; i <= MaxClients; ++i) storedClass[i] = ZC_None;
	
	if (g_Gamemode == L4D2Gamemode_Versus)
	{
		bRoundHasFlowTank = RoundHasFlowTank();
		bRoundHasFlowWitch = RoundHasFlowWitch();
		
		iTankCount = 0;
		iWitchCount = (GetConVarBool(l4d_witch_percent) ? 1 : 0);
		
		if (GetConVarBool(l4d_tank_percent))
		{
			iTankCount = 1;
			bFlowTankActive = bRoundHasFlowTank;
			
			static char mapname[64], dummy;
			GetCurrentMap(mapname, sizeof(mapname));
			
			if (strcmp(mapname, "hf03_themansion") == 0) iTankCount += 1;
			else if (!IsDarkCarniRemix() && L4D_IsMissionFinalMap())
			{
				iTankCount = 3
							- view_as<int>(hFirstTankSpawningScheme.GetValue(mapname, dummy))
							- view_as<int>(hSecondTankSpawningScheme.GetValue(mapname, dummy))
							- view_as<int>(hFinaleExceptionMaps.Size > 0 && !hFinaleExceptionMaps.GetValue(mapname, dummy))
							- view_as<int>(IsStaticTankMap());
			}
		}
	}
}

//public void L4D2_OnEndVersusModeRound_Post() { if (!InSecondHalfOfRound()) iFirstHalfScore = L4D_GetTeamScore(GetRealTeam(0) + 1); }

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsInfected(client)) return;
	
	if (GetInfectedClass(client) == ZC_Tank)
	{
		if (iTankCount > 0) iTankCount--;
		if (!bRoundHasFlowTank) bFlowTankActive = false;
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
	int oldteam = event.GetInt("oldteam");
	
	if (team == TEAM_NONE) { // Player disconnecting
		bSpecHudActive[client] = false;
		bTankHudActive[client] = true;
	}
	
	if (team == TEAM_SURVIVOR || oldteam == TEAM_SURVIVOR) bPendingArrayRefresh = true;
	
	//if (team == 3) storedClass[client] = ZC_None;
}

public Action ToggleSpecHudCmd(int client, int args) 
{
	bSpecHudActive[client] = !bSpecHudActive[client];
	CPrintToChat(client, "<{olive}HUD{default}> Spectator HUD is now %s.", (bSpecHudActive[client] ? "{blue}on{default}" : "{red}off{default}"));
}

public Action ToggleTankHudCmd(int client, int args) 
{
	bTankHudActive[client] = !bTankHudActive[client];
	CPrintToChat(client, "<{olive}HUD{default}> Tank HUD is now %s.", (bTankHudActive[client] ? "{blue}on{default}" : "{red}off{default}"));
}

public Action DebugSpecHudCmd(int client, int args)
{
	bDebugActive[client] = !bDebugActive[client];
	CPrintToChat(client, "<{olive}HUD{default}> Spectator HUD debugging is now %s.", (bDebugActive[client] ? "{blue}on{default}" : "{red}off{default}"));
	
	if (bDebugActive[client])
	{
		ShowActivity2(client, "\x04[SM] ", "\x01Admin (\x05%N\x01) enabled \x04Debug Spectator HUD\x01.", client);
		ShowActivity2(client, "\x04[SM] ", "\x01Suspect \x05%N \x01for \x04cheating \x01according to the situation.", client);
	}
}

public Action HudDrawTimer(Handle hTimer)
{
	if (IsInReady() || IsInPause())
		return Plugin_Continue;

	bool bSpecsOnServer = false;
	for (int i = 1; i <= MaxClients; ++i)
	{
		// 1. Debug active.
		// 2. Human spectator with spechud active. 
		// 3. SourceTV active.
		if( IsClientInGame(i) && (bDebugActive[i] || IsClientSourceTV(i) || (GetClientTeam(i) == TEAM_SPECTATOR && bSpecHudActive[i])) )
		{
			bSpecsOnServer = true;
			break;
		}
	}

	if (bSpecsOnServer) // Only bother if someone's watching us
	{
		Panel specHud = new Panel();

		FillHeaderInfo(specHud);
		FillSurvivorInfo(specHud);
		FillScoreInfo(specHud);
		FillInfectedInfo(specHud);
		if (!FillTankInfo(specHud))
			FillGameInfo(specHud);

		for (int i = 1; i <= MaxClients; ++i)
		{
			// - Client is in game.
			//    1. Client is debug active.
			//    2. Client is non-bot and spectator with spechud active.
			//    3. Client is bot as SourceTV.
			if (!IsClientInGame(i) || (!bDebugActive[i] 
										&& (GetClientTeam(i) != TEAM_SPECTATOR || !bSpecHudActive[i] || (IsFakeClient(i) && !IsClientSourceTV(i)))))
				continue;

			if (IsBuiltinVoteInProgress() && IsClientInBuiltinVotePool(i))
				continue;

			SendPanelToClient(specHud, i, DummySpecHudHandler, 3);
			if (!bSpecHudHintShown[i])
			{
				bSpecHudHintShown[i] = true;
				CPrintToChat(i, "<{olive}HUD{default}> Type {green}!spechud{default} into chat to toggle the {blue}Spectator HUD{default}.");
			}
		}
		delete specHud;
	}
	
	Panel tankHud = new Panel();
	if (FillTankInfo(tankHud, true)) // No tank -- no HUD
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			// Client is in game and non-bot
			//   1. Client is in infected team or spectator team with tankhud active, spechud inactive.
			if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) == TEAM_SURVIVOR || bDebugActive[i] || !bTankHudActive[i] || (bSpecHudActive[i] && GetClientTeam(i) == TEAM_SPECTATOR))
				continue;
			
			if (IsBuiltinVoteInProgress() && IsClientInBuiltinVotePool(i))
				continue;
	
			SendPanelToClient(tankHud, i, DummyTankHudHandler, 3);
			if (!bTankHudHintShown[i])
			{
				bTankHudHintShown[i] = true;
				CPrintToChat(i, "<{olive}HUD{default}> Type {green}!tankhud{default} into chat to toggle the {red}Tank HUD{default}.");
			}
		}
	}
	
	delete tankHud;
	return Plugin_Continue;
}

public int DummySpecHudHandler(Menu hMenu, MenuAction action, int param1, int param2) {}
public int DummyTankHudHandler(Menu hMenu, MenuAction action, int param1, int param2) {}

void FillHeaderInfo(Panel hSpecHud)
{
	static char buf[64];
	Format(buf, sizeof(buf), "Server: %s [Slots %i/%i | %iT]", sHostname, GetRealClientCount(), iMaxPlayers, RoundToNearest(1.0 / GetTickInterval()));
	DrawPanelText(hSpecHud, buf);
}

void GetMeleePrefix(int client, char[] prefix, int length)
{
	int secondary = GetPlayerWeaponSlot(client, view_as<int>(L4D2WeaponSlot_Secondary));
	WeaponId secondaryWep = IdentifyWeapon(secondary);

	static char buf[4];
	switch (secondaryWep)
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
	int primaryWep = GetPlayerWeaponSlot(client, view_as<int>(L4D2WeaponSlot_Primary));
	WeaponId activeWepId = IdentifyWeapon(activeWep);
	WeaponId primaryWepId = IdentifyWeapon(primaryWep);
	
	// Let's begin with what player is holding,
	// but cares only pistols if holding secondary.
	switch (activeWepId)
	{
		case WEPID_PISTOL, WEPID_PISTOL_MAGNUM:
		{
			if (activeWepId == WEPID_PISTOL && !!GetEntProp(activeWep, Prop_Send, "m_isDualWielding"))
			{
				// Dual Pistols Scene
				// Straight use the prefix since full name is a bit long.
				Format(buffer, sizeof(buffer), "DP");
			}
			else GetLongWeaponName(activeWepId, buffer, sizeof(buffer));
			
			FormatEx(info, length, "%s %i", buffer, GetWeaponClip(activeWep));
		}
		default:
		{
			GetLongWeaponName(primaryWepId, buffer, sizeof(buffer));
			FormatEx(info, length, "%s %i/%i", buffer, GetWeaponClip(primaryWep), GetWeaponAmmo(client, primaryWepId));
		}
	}
	
	// Format our result info
	if (primaryWep == -1)
	{
		// In case with no primary,
		// show the melee full name.
		if (activeWepId == WEPID_MELEE || activeWepId == WEPID_CHAINSAW)
		{
			MeleeWeaponId meleeWepId = IdentifyMeleeWeapon(activeWep);
			GetLongMeleeWeaponName(meleeWepId, info, length);
		}
	}
	else
	{
		// Default display -> [Primary <In Detail> | Secondary <Prefix>]
		// Holding melee included in this way
		// i.e. [Chrome 8/56 | M]
		if (GetSlotFromWeaponId(activeWepId) != 1 || activeWepId == WEPID_MELEE || activeWepId == WEPID_CHAINSAW)
		{
			GetMeleePrefix(client, buffer, sizeof(buffer));
			Format(info, length, "%s | %s", info, buffer);
		}

		// Secondary active -> [Secondary <In Detail> | Primary <Ammo Sum>]
		// i.e. [Deagle 8 | Mac 700]
		else
		{
			GetLongWeaponName(primaryWepId, buffer, sizeof(buffer));
			Format(info, length, "%s | %s %i", info, buffer, GetWeaponClip(primaryWep) + GetWeaponAmmo(client, primaryWepId));
		}
	}
}

void FillSurvivorInfo(Panel hSpecHud)
{
	static char info[100];
	static char name[MAX_NAME_LENGTH];

	int SurvivorTeamIndex = L4D2_AreTeamsFlipped();
	
	if (bRoundLive) {
		int distance = 0;
		for (int i = 0; i < 4; ++i) {
			distance += GameRules_GetProp("m_iVersusDistancePerSurvivor", _, i + 4 * SurvivorTeamIndex);
		}
		FormatEx(info, sizeof(info), "->1. Survivors [%d]",
					L4D2Direct_GetVSCampaignScore(SurvivorTeamIndex) + (bRoundLive ? distance : 0));
	} else {
		FormatEx(info, sizeof(info), "->1. Survivors [%d]",
					L4D2Direct_GetVSCampaignScore(SurvivorTeamIndex));
	}
	
	DrawPanelText(hSpecHud, " ");
	DrawPanelText(hSpecHud, info);
	
	if (bPendingArrayRefresh)
	{
		bPendingArrayRefresh = false;
		PushSerialSurvivors();
	}
	
	for (int i = 0; i < iSurvivorLimit; ++i)
	{
		int client = iSurvivorArray[i];
		if (!client) continue;
		
		GetClientFixedName(client, name, sizeof(name));
		if (!IsPlayerAlive(client))
		{
			FormatEx(info, sizeof(info), "%s: Dead", name);
		}
		else
		{
			if (IsSurvivorHanging(client))
			{
				FormatEx(info, sizeof(info), "%s: <%iHP@Hanging>", name, GetClientHealth(client));
			}
			else if (IsIncapacitated(client))
			{
				int activeWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				GetLongWeaponName(IdentifyWeapon(activeWep), info, sizeof(info));
				Format(info, sizeof(info), "%s: <%iHP@%s> [%s %i]", name, GetClientHealth(client), (GetSurvivorIncapCount(client) == 1 ? "2nd" : "1st"), info, GetWeaponClip(activeWep));
			}
			else
			{
				GetWeaponInfo(client, info, sizeof(info));
				
				int tempHealth = GetSurvivorTemporaryHealth(client);
				int health = GetClientHealth(client) + tempHealth;
				int incapCount = GetSurvivorIncapCount(client);
				if (incapCount == 0)
				{
					//FormatEx(buffer, sizeof(buffer), "#%iT", tempHealth);
					Format(info, sizeof(info), "%s: %iHP%s [%s]", name, health, (tempHealth > 0 ? "#" : ""), info);
				}
				else
				{
					//FormatEx(buffer, sizeof(buffer), "%i incap%s", incapCount, (incapCount > 1 ? "s" : ""));
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

	if (bHybridScoremod)
	{
		int healthBonus	= SMPlus_GetHealthBonus(),	maxHealthBonus	= SMPlus_GetMaxHealthBonus();
		int damageBonus	= SMPlus_GetDamageBonus(),	maxDamageBonus	= SMPlus_GetMaxDamageBonus();
		int pillsBonus	= SMPlus_GetPillsBonus(),	maxPillsBonus	= SMPlus_GetMaxPillsBonus();
		
		int totalBonus		= healthBonus		+ damageBonus		+ pillsBonus;
		int maxTotalBonus	= maxHealthBonus	+ maxDamageBonus	+ maxPillsBonus;
		
		DrawPanelText(hSpecHud, " ");
		
		FormatEx(	info,
					sizeof(info),
					"> HB: %.0f%% | DB: %.0f%% | Pills: %i / %.0f%%",
					ToPercent(healthBonus, maxHealthBonus),
					ToPercent(damageBonus, maxDamageBonus),
					pillsBonus, ToPercent(pillsBonus, maxPillsBonus));
		DrawPanelText(hSpecHud, info);
		
		FormatEx(info, sizeof(info), "> Bonus: %i <%.1f%%>", totalBonus, ToPercent(totalBonus, maxTotalBonus));
		DrawPanelText(hSpecHud, info);
		
		FormatEx(info, sizeof(info), "> Distance: %i", L4D_GetVersusMaxCompletionScore() / 4 * iSurvivorLimit);
		//if (InSecondHalfOfRound())
		//{
		//	Format(info, sizeof(info), "%s | R#1: %i <%.1f%%>", info, iFirstHalfScore, ToPercent(iFirstHalfScore, L4D_GetVersusMaxCompletionScore() + maxTotalBonus));
		//}
		DrawPanelText(hSpecHud, info);
	}
	
	else if (bScoremod)
	{
		int healthBonus = HealthBonus();
		
		DrawPanelText(hSpecHud, " ");
		
		FormatEx(info, sizeof(info), "> Health Bonus: %i", healthBonus);
		DrawPanelText(hSpecHud, info);
		
		FormatEx(info, sizeof(info), "> Distance: %i", L4D_GetVersusMaxCompletionScore() / 4 * iSurvivorLimit);
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
		
		FormatEx(	info,
					sizeof(info),
					"> Perm: %i | Temp: %i | Pills: %i",
					permBonus, tempBonus, pillsBonus);
		DrawPanelText(hSpecHud, info);
		
		FormatEx(info, sizeof(info), "> Bonus: %i <%.1f%%>", totalBonus, ToPercent(totalBonus, maxTotalBonus));
		DrawPanelText(hSpecHud, info);
		
		FormatEx(info, sizeof(info), "> Distance: %i", L4D_GetVersusMaxCompletionScore() / 4 * iSurvivorLimit);
		//if (InSecondHalfOfRound())
		//{
		//	Format(info, sizeof(info), "%s | R#1: %i <%.1f%%>", info, iFirstHalfScore, ToPercent(iFirstHalfScore, L4D_GetVersusMaxCompletionScore() + maxTotalBonus));
		//}
		DrawPanelText(hSpecHud, info);
	}
}

void FillInfectedInfo(Panel hSpecHud)
{
	static char info[80];
	static char buffer[16];
	static char name[MAX_NAME_LENGTH];

	int InfectedTeamIndex = !L4D2_AreTeamsFlipped();
	
	FormatEx(info, sizeof(info), "->2. Infected [%d]", L4D2Direct_GetVSCampaignScore(InfectedTeamIndex));
	DrawPanelText(hSpecHud, " ");
	DrawPanelText(hSpecHud, info);

	int infectedCount;
	for (int client = 1; client <= MaxClients && infectedCount < iMaxPlayerZombies; ++client) 
	{
		if (!IsInfected(client))
			continue;

		GetClientFixedName(client, name, sizeof(name));
		if (!IsPlayerAlive(client)) 
		{
			int timeLeft = RoundToFloor(L4D_GetPlayerSpawnTime(client));
			if (timeLeft < 0)
			{
				FormatEx(info, sizeof(info), "%s: Dead", name);
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%is", timeLeft);
				FormatEx(info, sizeof(info), "%s: Dead (%s)", name, (timeLeft ? buffer : "Spawning..."));
				//if (storedClass[client] > ZC_None) {
				//	FormatEx(info, sizeof(info), "%s: Dead (%s) [%s]", name, ZOMBIECLASS_NAME(storedClass[client]), (RoundToNearest(timeLeft) ? buffer : "Spawning..."));
				//} else {
				//	FormatEx(info, sizeof(info), "%s: Dead (%s)", name, (RoundToNearest(timeLeft) ? buffer : "Spawning..."));
				//}
			}
		}
		else
		{
			L4D2SI zClass = GetInfectedClass(client);
			if (zClass == ZC_Tank)
				continue;
			
			int iHP = GetClientHealth(client), iMaxHP = GetEntProp(client, Prop_Send, "m_iMaxHealth");
			if (IsInfectedGhost(client))
			{
				// DONE: Handle a case of respawning chipped SI, show the ghost's health
				if (iHP < iMaxHP)
				{
					FormatEx(info, sizeof(info), "%s: %s (Ghost@%iHP)", name, ZOMBIECLASS_NAME(zClass), iHP);
				}
				else
				{
					FormatEx(info, sizeof(info), "%s: %s (Ghost)", name, ZOMBIECLASS_NAME(zClass));
				}
			}
			else
			{
				int iCooldown = RoundToNearest(GetAbilityCooldown(client));
				if (iCooldown > 0)
				{
					if (GetAbilityCooldownDuration(client) > 1.0
						&& !HasAbilityVictim(client, zClass))
					{
						FormatEx(buffer, sizeof(buffer), " [%is]", info, iCooldown);
					}
				}
				else { buffer[0] = '\0'; }
				
				if (GetEntityFlags(client) & FL_ONFIRE)
				{
					FormatEx(info, sizeof(info), "%s: %s (%iHP) [On Fire]%s", name, ZOMBIECLASS_NAME(zClass), iHP, buffer);
				}
				else
				{
					FormatEx(info, sizeof(info), "%s: %s (%iHP)%s", name, ZOMBIECLASS_NAME(zClass), iHP, buffer);
				}
			}
		}

		infectedCount++;
		DrawPanelText(hSpecHud, info);
	}
	
	if (!infectedCount)
	{
		DrawPanelText(hSpecHud, "There are no SI at this moment.");
	}
}

bool FillTankInfo(Panel hSpecHud, bool bTankHUD = false)
{
	int tank = FindTank();
	if (tank == -1)
		return false;

	static char info[64];
	static char name[MAX_NAME_LENGTH];

	if (bTankHUD)
	{
		FormatEx(info, sizeof(info), "%s :: Tank HUD", sReadyCfgName);
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
		Format(info, sizeof(info), "Control: %s (%s)", name, info);
	}
	else
	{
		Format(info, sizeof(info), "Control: AI (%s)", info);
	}
	DrawPanelText(hSpecHud, info);

	// Draw health
	int health = GetClientHealth(tank);
	int maxhealth = GetEntProp(tank, Prop_Send, "m_iMaxHealth");
	if (health <= 0 || IsIncapacitated(tank) || !IsPlayerAlive(tank))
	{
		info = "Health : Dead";
	}
	else
	{
		int healthPercent = RoundFloat((100.0 / maxhealth) * health);
		FormatEx(info, sizeof(info), "Health : %i / %i%%", health, ((healthPercent < 1) ? 1 : healthPercent));
	}
	DrawPanelText(hSpecHud, info);

	// Draw frustration
	if (!IsFakeClient(tank))
	{
		FormatEx(info, sizeof(info), "Frustr. : %d%%", GetTankFrustration(tank));
	}
	else
	{
		info = "Frustr. : AI";
	}
	DrawPanelText(hSpecHud, info);

	// Draw network
	if (!IsFakeClient(tank))
	{
		FormatEx(info, sizeof(info), "Network: %ims / %.1f", RoundToNearest(GetClientAvgLatency(tank, NetFlow_Both) * 1000.0), GetLerpTime(tank) * 1000.0);
	}
	else
	{
		info = "Network: AI";
	}
	DrawPanelText(hSpecHud, info);

	// Draw fire status
	if (GetEntityFlags(tank) & FL_ONFIRE)
	{
		int timeleft = RoundToCeil(health / (maxhealth / fTankBurnDuration));
		FormatEx(info, sizeof(info), "On Fire : %is", timeleft);
		DrawPanelText(hSpecHud, info);
	}
	
	return true;
}

void FillGameInfo(Panel hSpecHud)
{
	// Turns out too much info actually CAN be bad, funny ikr
	static char info[64];
	static char buffer[8];

	if (g_Gamemode == L4D2Gamemode_Scavenge)
	{
		FormatEx(info, sizeof(info), "->3. %s", sReadyCfgName);
		
		DrawPanelText(hSpecHud, " ");
		DrawPanelText(hSpecHud, info);

		int round = GetScavengeRoundNumber();
		switch (round)
		{
			case 0: Format(buffer, sizeof(buffer), "N/A");
			case 1: Format(buffer, sizeof(buffer), "%ist", round);
			case 2: Format(buffer, sizeof(buffer), "%ind", round);
			case 3: Format(buffer, sizeof(buffer), "%ird", round);
			default: Format(buffer, sizeof(buffer), "%ith", round);
		}

		FormatEx(info, sizeof(info), "Half: %s | Round: %s", (InSecondHalfOfRound() ? "2nd" : "1st"), buffer);
		DrawPanelText(hSpecHud, info);
	}
	else
	{
		FormatEx(info, sizeof(info), "->3. %s (R#%d)", sReadyCfgName, InSecondHalfOfRound() + 1);
		DrawPanelText(hSpecHud, " ");
		DrawPanelText(hSpecHud, info);

		int tankPercent = GetStoredTankPercent();
		int witchPercent = GetStoredWitchPercent();
		int survivorFlow = GetHighestSurvivorFlow();
		if (survivorFlow == -1)
			survivorFlow = GetFurthestSurvivorFlow();
		
		bool bDivide = false;
				
		// tank percent
		if (iTankCount > 0)
		{
			bDivide = true;
			FormatEx(buffer, sizeof(buffer), "%i%%", tankPercent);
			
			if ((bFlowTankActive && bRoundHasFlowTank) || IsDarkCarniRemix())
			{
				FormatEx(info, sizeof(info), "Tank: %s", buffer);
			}
			else
			{
				FormatEx(info, sizeof(info), "Tank: %s", (IsStaticTankMap() ? "Static" : "Event"));
			}
		}
		
		// witch percent
		if (iWitchCount > 0)
		{
			FormatEx(buffer, sizeof(buffer), "%i%%", witchPercent);
			
			if (bDivide) {
				Format(info, sizeof(info), "%s | Witch: %s", info, (bRoundHasFlowWitch ? buffer : (IsStaticWitchMap() ? "Static" : "Event")));
			} else {
				bDivide = true;
				FormatEx(info, sizeof(info), "Witch: %s", (bRoundHasFlowWitch ? buffer : (IsStaticWitchMap() ? "Static" : "Event")));
			}
		}
		
		// current
		if (bDivide) {
			Format(info, sizeof(info), "%s | Cur: %i%%", info, survivorFlow);
		} else {
			FormatEx(info, sizeof(info), "Cur: %i%%", survivorFlow);
		}
		
		DrawPanelText(hSpecHud, info);
		
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

public Action SetMapFirstTankSpawningScheme(int args)
{
	char mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	SetTrieValue(hFirstTankSpawningScheme, mapname, true);
}

public Action SetMapSecondTankSpawningScheme(int args)
{
	char mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	SetTrieValue(hSecondTankSpawningScheme, mapname, true);
}

public Action SetFinaleExceptionMap(int args)
{
	char mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	SetTrieValue(hFinaleExceptionMaps, mapname, true);
}

/**
 *	Stocks
**/
float GetAbilityCooldownDuration(int client)
{
	int ability = GetInfectedCustomAbility(client);
	if (ability != -1 && GetEntProp(ability, Prop_Send, "m_hasBeenUsed"))
	{
		return GetCountdownDuration(ability);
	}
	return 0.0;
}

float GetAbilityCooldown(int client)
{
	int ability = GetInfectedCustomAbility(client);
	if (ability != -1 && GetEntProp(ability, Prop_Send, "m_hasBeenUsed"))
	{
		if (GetCountdownDuration(ability) != 3600.0)
			return GetCountdownTimestamp(ability) - GetGameTime();
	}
	return 0.0;
}

float GetCountdownDuration(int entity)
{
	return GetEntPropFloat(entity, Prop_Send, "m_duration");
}

float GetCountdownTimestamp(int entity)
{
	return GetEntPropFloat(entity, Prop_Send, "m_timestamp");
}

int GetInfectedCustomAbility(int client)
{
	if (HasEntProp(client, Prop_Send, "m_customAbility")) {
		return GetEntPropEnt(client, Prop_Send, "m_customAbility");
	}
	
	return -1;
}

//int GetRealTeam(int team)
//{
//	return team ^ view_as<int>(!!InSecondHalfOfRound() != L4D2_AreTeamsFlipped());
//}

bool HasAbilityVictim(int client, L4D2SI zClass)
{
	switch (zClass)
	{
		case ZC_Smoker: return GetEntPropEnt(client, Prop_Send, "m_tongueVictim") > 0;
		case ZC_Hunter: return GetEntPropEnt(client, Prop_Send, "m_pounceVictim") > 0;
		case ZC_Jockey: return GetEntPropEnt(client, Prop_Send, "m_jockeyVictim") > 0;
		case ZC_Charger: return GetEntPropEnt(client, Prop_Send, "m_pummelVictim") > 0 || GetEntPropEnt(client, Prop_Send, "m_carryVictim") > 0;
	}
	return false;
}

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

stock int GetWeaponAmmo(int client, WeaponId wepid)
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

stock int GetWeaponClip(int weapon)
{
	return (weapon > 0 ? GetEntProp(weapon, Prop_Send, "m_iClip1") : -1);
}

void PushSerialSurvivors()
{
	int survivorCount = 0;
	for (int client = 1; client <= MaxClients && survivorCount < iSurvivorLimit; ++client) 
	{
		if (IsSurvivor(client))
		{
			iSurvivorArray[survivorCount++] = client;
		}
	}
	iSurvivorArray[survivorCount] = 0;
	
	SortCustom1D(iSurvivorArray, survivorCount, SortSurvArray);
}

public int SortSurvArray(int elem1, int elem2, const int[] array, Handle hndl)
{
	SurvivorCharacter sc1 = GetFixedSurvivorCharacter(elem1);
	SurvivorCharacter sc2 = GetFixedSurvivorCharacter(elem2);
	
	if (sc1 > sc2) { return 1; }
	else if (sc1 < sc2) { return -1; }
	else { return 0; }
}

SurvivorCharacter GetFixedSurvivorCharacter(int client)
{
	int sc = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	
	switch (sc)
	{
		case 6:						// Francis' netprop is 6
			return SC_FRANCIS;		// but here to match the official serial
			
		case 7:						// Louis' netprop is 7
			return SC_LOUIS;		// but here to match the official serial
			
		case 9, 11:					// Bill's alternative netprop
			return SC_BILL;			// match it correctly
	}
	return view_as<SurvivorCharacter>(sc);
}

float GetLerpTime(int client)
{
	static char value[16];
	
	if (!GetClientInfo(client, "cl_updaterate", value, sizeof(value))) value = "";
	int updateRate = StringToInt(value);
	updateRate = RoundFloat(CLAMP(float(updateRate), fMinUpdateRate, fMaxUpdateRate));
	
	if (!GetClientInfo(client, "cl_interp_ratio", value, sizeof(value))) value = "";
	float flLerpRatio = StringToFloat(value);
	
	if (!GetClientInfo(client, "cl_interp", value, sizeof(value))) value = "";
	float flLerpAmount = StringToFloat(value);
	
	if (cVarMinInterpRatio != null && cVarMaxInterpRatio != null && fMinInterpRatio != -1.0 ) {
		flLerpRatio = CLAMP(flLerpRatio, fMinInterpRatio, fMaxInterpRatio );
	}
	
	return MAX(flLerpAmount, flLerpRatio / updateRate);
}

stock float ToPercent(int score, int maxbonus)
{
	return (score < 1 ? 0.0 : (100.0 * score / maxbonus));
}

void GetClientFixedName(int client, char[] name, int length)
{
	GetClientName(client, name, length);

	if (name[0] == '[')
	{
		char temp[MAX_NAME_LENGTH];
		strcopy(temp, sizeof(temp), name);
		temp[sizeof(temp)-2] = 0;
		strcopy(name[1], length-1, temp);
		name[0] = ' ';
	}

	if (strlen(name) > 18)
	{
		name[15] = name[16] = name[17] = '.';
		name[18] = 0;
	}
}

int GetRealClientCount() 
{
	int clients = 0;
	for (int i = 1; i <= MaxClients; ++i) 
	{
		if (IsClientConnected(i) && !IsFakeClient(i)) clients++;
	}
	return clients;
}

int InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound");
}

int GetScavengeRoundNumber()
{
	return GameRules_GetProp("m_nRoundNumber");
}

int GetFurthestSurvivorFlow()
{
	int flow = RoundToNearest(100.0 * (L4D2_GetFurthestSurvivorFlow() + fVersusBossBuffer) / L4D2Direct_GetMapMaxFlowDistance());
	return MIN(flow, 100);
}

//float GetClientFlow(int client)
//{
//	return (L4D2Direct_GetFlowDistance(client) / L4D2Direct_GetMapMaxFlowDistance());
//}

int GetHighestSurvivorFlow()
{
	int flow = -1;
	
	int client = L4D_GetHighestFlowSurvivor();
	if (client > 0) {
		flow = RoundToNearest(100.0 * (L4D2Direct_GetFlowDistance(client) + fVersusBossBuffer) / L4D2Direct_GetMapMaxFlowDistance());
	}
	
	return MIN(flow, 100);
}

bool RoundHasFlowTank()
{
	return L4D2Direct_GetVSTankToSpawnThisRound(InSecondHalfOfRound());
}

bool RoundHasFlowWitch()
{
	return L4D2Direct_GetVSWitchToSpawnThisRound(InSecondHalfOfRound());
}

//bool IsSpectator(int client)
//{
//	return IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR;
//}

bool IsSurvivor(int client)
{
	return IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR;
}

bool IsInfected(int client)
{
	return IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED;
}

bool IsInfectedGhost(int client) 
{
	return !!GetEntProp(client, Prop_Send, "m_isGhost");
}

L4D2SI GetInfectedClass(int client)
{
	return view_as<L4D2SI>(GetEntProp(client, Prop_Send, "m_zombieClass"));
}

int FindTank() 
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsInfected(i) && GetInfectedClass(i) == ZC_Tank && IsPlayerAlive(i))
			return i;
	}

	return -1;
}

int GetTankFrustration(int tank)
{
	return (100 - GetEntProp(tank, Prop_Send, "m_frustration"));
}

bool IsIncapacitated(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool IsSurvivorHanging(int client)
{
	return !!(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") | GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

int GetSurvivorIncapCount(int client)
{
	return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}

int GetSurvivorTemporaryHealth(int client)
{
	int temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * fPainPillsDecayRate)) - 1;
	return (temphp > 0 ? temphp : 0);
}

void GetCurrentGameMode()
{
	char sGameMode[32];
	GetConVarString(mp_gamemode, sGameMode, sizeof(sGameMode));
	
	if (strcmp(sGameMode, "scavenge") == 0)
	{
		g_Gamemode = L4D2Gamemode_Scavenge;
	}
	if (strcmp(sGameMode, "versus") == 0
		|| strcmp(sGameMode, "mutation12") == 0) // realism versus
	{
		g_Gamemode = L4D2Gamemode_Versus;
	}
	else
	{
		g_Gamemode = L4D2Gamemode_None; // Unsupported
	}
}