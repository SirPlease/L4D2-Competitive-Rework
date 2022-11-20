#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <left4dhooks>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR  2
#define TEAM_INFECTED  3
#define FLAG_SPECTATOR (1 << TEAM_SPECTATOR)
#define FLAG_SURVIVOR  (1 << TEAM_SURVIVOR)
#define FLAG_INFECTED  (1 << TEAM_INFECTED)

#define ZC_SMOKER  1
#define ZC_BOOMER  2
#define ZC_HUNTER  3
#define ZC_SPITTER 4
#define ZC_JOCKEY  5
#define ZC_CHARGER 6
#define ZC_WITCH   7
#define ZC_TANK    8

#define BREV_SI       1
#define BREV_CI       2
#define BREV_FF       4
#define BREV_RANK     8
//#define BREV_???              16
#define BREV_PERCENT  32
#define BREV_ABSOLUTE 64

#define CONBUFSIZE      1024
#define CONBUFSIZELARGE 4096

#define CHARTHRESHOLD 160    // detecting unicode stuff

/**
 * Issues:
 *  - Add damage received from common
 */

/*
Changelog
---------
0.2c
- added console output table for more stats, fixed it's display
- fixed console display to always display each player on the survivor team

0.1
- fixed common MVP ranks being messed up.
- finally worked in PluginEnabled cvar
- made FF tracking switch to enabled automatically if brevity flag 4 is unset
- fixed a bug that caused FF to always report as "no friendly fire" when tracking was disabled
- adjusted formatting a bit
- made FF stat hidden by default
- made convars actually get tracked (doh)
- added friendly fire tracking (sm_survivor_mvp_trackff 1/0)
- added brevity-flags cvar for changing verbosity of MVP report (sm_survivor_mvp_brevity bitwise, as shown)
- discount FF damage before match is live if RUP is active.
- fixed problem with clients disconnecting before mvp report
- improved consistency after client reconnect (name-based)
- fixed mvp stats double showing in scavenge (round starts)
- now shows if MVP is a bot
- cleaned up code
- fixed for scavenge, now shows stats for every scavenge round
- fixed damage/kills getting recorded for infected players, skewing MVP stats
- added rank display for non-MVP clients
*/
/*
Brevity flags:
1       leave out SI stats
2       leave out CI stats
4       leave out FF stats
8       leave out rank notification
16   (reserved)
32      leave out percentages
64      leave out absolutes

*/
public Plugin myinfo =
{
	name        = "Survivor MVP notification",
	author      = "Tabun, Artifacial",
	description = "Shows MVP for survivor team at end of round",
	version     = "0.4",
	url         = "https://github.com/alexberriman/l4d2_survivor_mvp"
};

ConVar
	hPluginEnabled,
	hCountTankDamage,     // whether we're tracking tank damage for MVP-selection
	hCountWitchDamage,    // whether we're tracking witch damage for MVP-selection
	hTrackFF,             // whether we're tracking friendly-fire damage (separate stat)
	hBrevityFlags,        // how verbose/brief the output should be:
	hRUPActive;           // whether the ready up mod is active

bool
	bCountTankDamage,
	bCountWitchDamage,
	bTrackFF;
int
	iBrevityFlags;
bool
	bRUPActive;

Handle
	hGameMode = INVALID_HANDLE;
char
	sGameMode[24] = "\0",
	sClientName[MAXPLAYERS + 1][64];    // which name is connected to the clientId?

// Basic statistics
int
	iGotKills[MAXPLAYERS + 1],          // SI kills             track for each client
	iGotCommon[MAXPLAYERS + 1],         // CI kills
	iDidDamage[MAXPLAYERS + 1],         // SI only              these are a bit redundant, but will keep anyway for now
	iDidDamageAll[MAXPLAYERS + 1],      // SI + tank + witch
	iDidDamageTank[MAXPLAYERS + 1],     // tank only
	iDidDamageWitch[MAXPLAYERS + 1],    // witch only
	iDidFF[MAXPLAYERS + 1];             // friendly fire damage

// Detailed statistics
int
	iDidDamageClass[MAXPLAYERS + 1][ZC_TANK + 1],    // si classes
	timesPinned[MAXPLAYERS + 1][ZC_TANK + 1],        // times pinned
	totalPinned[MAXPLAYERS + 1],                     // total times pinned
	pillsUsed[MAXPLAYERS + 1],                       // total pills eaten
	boomerPops[MAXPLAYERS + 1],                      // total boomer pops
	damageReceived[MAXPLAYERS + 1];                  // Damage received

// Tank stats
bool
	tankSpawned = false,    // When tank is spawned
	tankThrow;              // Whether or not the tank has thrown a rock
int
	commonKilledDuringTank[MAXPLAYERS + 1],    // Common killed during the tank
	ttlCommonKilledDuringTank = 0,             // Common killed during the tank
	siDmgDuringTank[MAXPLAYERS + 1],           // SI killed during the tank
	rocksEaten[MAXPLAYERS + 1],                // The amount of rocks a player 'ate'.
	ttlPinnedDuringTank[MAXPLAYERS + 1],       // The total times we were pinned when the tank was up
	rockIndex;                                 // The index of the rock (to detect how many times we were rocked)

int
	iTotalKills,    // prolly more efficient to store than to recalculate
	iTotalCommon,
	iTotalDamageAll,
	iTotalFF;

int
	iRoundNumber;
bool
	bInRound,
	bPlayerLeftStartArea;    // used for tracking FF when RUP enabled

/*
 *      Natives
 *      =======
 */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("SURVMVP_GetMVP", Native_GetMVP);
	CreateNative("SURVMVP_GetMVPDmgCount", Native_GetMVPDmgCount);
	CreateNative("SURVMVP_GetMVPKills", Native_GetMVPKills);
	CreateNative("SURVMVP_GetMVPDmgPercent", Native_GetMVPDmgPercent);
	CreateNative("SURVMVP_GetMVPCI", Native_GetMVPCI);
	CreateNative("SURVMVP_GetMVPCIKills", Native_GetMVPCIKills);
	CreateNative("SURVMVP_GetMVPCIPercent", Native_GetMVPCIPercent);
	RegPluginLibrary("survivor_mvp");
	return APLRes_Success;
}

// ========================
//  Natives
// ========================

// simply return current round MVP client
public int Native_GetMVP(Handle plugin, int numParams)
{
	int client = findMVPSI();
	return client;
}

// return damage of client
public int Native_GetMVPDmgCount(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int dmg    = client && iTotalDamageAll > 0 ? iDidDamageAll[client] : 0;
	return dmg;
}

// return SI kills of client
public int Native_GetMVPKills(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int dmg    = client && iTotalKills > 0 ? iGotKills[client] : 0;
	return dmg;
}

// return damage percent of client
public any Native_GetMVPDmgPercent(Handle plugin, int numParams)
{
	int   client = GetNativeCell(1);
	float dmgprc = client && iTotalDamageAll > 0 ? (float(iDidDamageAll[client]) / float(iTotalDamageAll)) * 100 : 0.0;
	return dmgprc;
}

// simply return current round MVP client (Common)
public int Native_GetMVPCI(Handle plugin, int numParams)
{
	int client = findMVPCommon();
	return client;
}

// return common kills for client
public int Native_GetMVPCIKills(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int dmg    = client && iTotalCommon > 0 ? iGotCommon[client] : 0;
	return dmg;
}

// return CI percent of client
public any Native_GetMVPCIPercent(Handle plugin, int numParams)
{
	int   client = GetNativeCell(1);
	float dmgprc = client && iTotalCommon > 0 ? (float(iGotCommon[client]) / float(iTotalCommon)) * 100 : 0.0;
	return dmgprc;
}

/*
 *      init
 *      ====
 */
public void OnPluginStart()
{
	// Translation
	LoadTranslation("survivor_mvp.phrases");

	// Round triggers
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
	HookEvent("map_transition", RoundEnd_Event, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_start", ScavRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", PlayerLeftStartArea, EventHookMode_PostNoCopy);
	HookEvent("pills_used", pillsUsedEvent);
	HookEvent("boomer_exploded", boomerExploded);
	HookEvent("charger_carry_end", chargerCarryEnd);
	HookEvent("jockey_ride", jockeyRide);
	HookEvent("lunge_pounce", hunterLunged);
	HookEvent("choke_start", smokerChoke);
	HookEvent("tank_killed", tankKilled);
	HookEvent("tank_spawn", tankSpawn);
	HookEvent("ability_use", abilityUseEvent);

	// Catching data
	HookEvent("player_hurt", PlayerHurt_Event, EventHookMode_Post);
	HookEvent("player_death", PlayerDeath_Event, EventHookMode_Post);
	HookEvent("infected_hurt", InfectedHurt_Event, EventHookMode_Post);
	HookEvent("infected_death", InfectedDeath_Event, EventHookMode_Post);

	// check gamemode (for scavenge fix)
	hGameMode = FindConVar("mp_gamemode");

	// Cvars
	hPluginEnabled    = CreateConVar("sm_survivor_mvp_enabled", "1", "Enable display of MVP at end of round");
	hCountTankDamage  = CreateConVar("sm_survivor_mvp_counttank", "0", "Damage on tank counts towards MVP-selection if enabled.");
	hCountWitchDamage = CreateConVar("sm_survivor_mvp_countwitch", "0", "Damage on witch counts towards MVP-selection if enabled.");
	hTrackFF          = CreateConVar("sm_survivor_mvp_showff", "1", "Track Friendly-fire stat.");
	hBrevityFlags     = CreateConVar("sm_survivor_mvp_brevity", "0", "Flags for setting brevity of MVP report (hide 1:SI, 2:CI, 4:FF, 8:rank, 32:perc, 64:abs).");

	bCountTankDamage  = hCountTankDamage.BoolValue;
	bCountWitchDamage = hCountWitchDamage.BoolValue;
	bTrackFF          = hTrackFF.BoolValue;
	iBrevityFlags     = hBrevityFlags.IntValue;

	// for now, force FF tracking on:
	bTrackFF = true;

	HookConVarChange(hCountTankDamage, ConVarChange_CountTankDamage);
	HookConVarChange(hCountWitchDamage, ConVarChange_CountWitchDamage);
	HookConVarChange(hTrackFF, ConVarChange_TrackFF);
	HookConVarChange(hBrevityFlags, ConVarChange_BrevityFlags);

	if (!(iBrevityFlags & BREV_FF)) { bTrackFF = true; }    // force tracking on if we're showing FF

	// RUP?
	hRUPActive = FindConVar("l4d_ready_enabled");
	if (hRUPActive != null)
	{
		// hook changes for this, and set state appropriately
		bRUPActive = hRUPActive.BoolValue;
		HookConVarChange(hRUPActive, ConVarChange_RUPActive);
	}
	else {
		// not loaded
		bRUPActive = false;
	}
	bPlayerLeftStartArea = false;

	// Commands
	RegConsoleCmd("sm_mvp", SurvivorMVP_Cmd, "Prints the current MVP for the survivor team");
	RegConsoleCmd("sm_mvpme", ShowMVPStats_Cmd, "Prints the client's own MVP-related stats");

	RegConsoleCmd("say", Say_Cmd);
	RegConsoleCmd("say_team", Say_Cmd);
}

void LoadTranslation(char[] sTranslation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", sTranslation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file %s.txt", sTranslation);
	}
	LoadTranslations(sTranslation);
}

public void OnClientPutInServer(int client)
{
	char tmpBuffer[128];
	GetClientName(client, tmpBuffer, sizeof(tmpBuffer));

	// if previously stored name for same client is not the same, delete stats & overwrite name
	if (strcmp(tmpBuffer, sClientName[client], true) != 0)
	{
		iGotKills[client]       = 0;
		iGotCommon[client]      = 0;
		iDidDamage[client]      = 0;
		iDidDamageAll[client]   = 0;
		iDidDamageWitch[client] = 0;
		iDidDamageTank[client]  = 0;
		iDidFF[client]          = 0;

		//@todo detailed statistics - set to 0
		for (int siClass = ZC_SMOKER; siClass <= ZC_TANK; siClass++)
		{
			iDidDamageClass[client][siClass] = 0;
			timesPinned[client][siClass]     = 0;
		}
		pillsUsed[client]              = 0;
		boomerPops[client]             = 0;
		damageReceived[client]         = 0;
		totalPinned[client]            = 0;
		commonKilledDuringTank[client] = 0;
		siDmgDuringTank[client]        = 0;
		rocksEaten[client]             = 0;
		ttlPinnedDuringTank[client]    = 0;

		// store name for later reference
		strcopy(sClientName[client], sizeof(tmpBuffer), tmpBuffer);
	}
}

/*
 *      convar changes
 *      ==============
 */
public void ConVarChange_CountTankDamage(Handle cvar, const char[] oldValue, const char[] newValue)
{
	bCountTankDamage = StringToInt(newValue) != 0;
}

public void ConVarChange_CountWitchDamage(Handle cvar, const char[] oldValue, const char[] newValue)
{
	bCountWitchDamage = StringToInt(newValue) != 0;
}

public void ConVarChange_TrackFF(Handle cvar, const char[] oldValue, const char[] newValue)
{
	// if (StringToInt(newValue) == 0) { bTrackFF = false; } else { bTrackFF = true; }
	//  for now, disable FF tracking toggle (always on)
}

public void ConVarChange_BrevityFlags(Handle cvar, const char[] oldValue, const char[] newValue)
{
	iBrevityFlags = StringToInt(newValue);
	if (!(iBrevityFlags & BREV_FF))
	{
		bTrackFF = true;
	}    // force tracking on if we're showing FF
}

public void ConVarChange_RUPActive(Handle cvar, const char[] oldValue, const char[] newValue)
{
	bRUPActive = StringToInt(newValue) != 0;
}

/*
 *      map load / round start/end
 *      ==========================
 */
public Action PlayerLeftStartArea(Handle event, const char[] name, bool dontBroadcast)
{
	// if RUP active, now we can start tracking FF
	bPlayerLeftStartArea = true;
	return Plugin_Continue;
}

public void OnMapStart()
{
	bPlayerLeftStartArea = false;
	// get gamemode string for scavenge fix
	GetConVarString(hGameMode, sGameMode, sizeof(sGameMode));
}

public void OnMapEnd()
{
	iRoundNumber = 0;
	bInRound     = false;
}

public void ScavRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	// clear mvp stats
	int
		i,
		maxplayers = MaxClients;
	for (i = 1; i <= maxplayers; i++)
	{
		iGotKills[i]       = 0;
		iGotCommon[i]      = 0;
		iDidDamage[i]      = 0;
		iDidDamageAll[i]   = 0;
		iDidDamageWitch[i] = 0;
		iDidDamageTank[i]  = 0;
		iDidFF[i]          = 0;

		//@todo detailed statistics - set to 0
		for (int siClass = ZC_SMOKER; siClass <= ZC_TANK; siClass++)
		{
			iDidDamageClass[i][siClass] = 0;
			timesPinned[i][siClass]     = 0;
		}
		pillsUsed[i]              = 0;
		boomerPops[i]             = 0;
		damageReceived[i]         = 0;
		totalPinned[i]            = 0;
		commonKilledDuringTank[i] = 0;
		siDmgDuringTank[i]        = 0;
		rocksEaten[i]             = 0;
		ttlPinnedDuringTank[i]    = 0;
	}
	iTotalKills               = 0;
	iTotalCommon              = 0;
	iTotalDamageAll           = 0;
	iTotalFF                  = 0;
	ttlCommonKilledDuringTank = 0;
	tankThrow                 = false;

	bInRound    = true;
	tankSpawned = false;
}

public void RoundStart_Event(Handle event, const char[] name, bool dontBroadcast)
{
	bPlayerLeftStartArea = false;

	if (!bInRound)
	{
		bInRound = true;
		iRoundNumber++;
	}

	// clear mvp stats
	int i, maxplayers = MaxClients;
	for (i = 1; i <= maxplayers; i++)
	{
		iGotKills[i]       = 0;
		iGotCommon[i]      = 0;
		iDidDamage[i]      = 0;
		iDidDamageAll[i]   = 0;
		iDidDamageWitch[i] = 0;
		iDidDamageTank[i]  = 0;
		iDidFF[i]          = 0;

		//@todo detailed statistics init to 0
		for (int siClass = ZC_SMOKER; siClass <= ZC_TANK; siClass++)
		{
			iDidDamageClass[i][siClass] = 0;
			timesPinned[i][siClass]     = 0;
		}
		pillsUsed[i]              = 0;
		boomerPops[i]             = 0;
		damageReceived[i]         = 0;
		totalPinned[i]            = 0;
		commonKilledDuringTank[i] = 0;
		siDmgDuringTank[i]        = 0;
		rocksEaten[i]             = 0;
		ttlPinnedDuringTank[i]    = 0;
	}
	iTotalKills               = 0;
	iTotalCommon              = 0;
	iTotalDamageAll           = 0;
	iTotalFF                  = 0;
	ttlCommonKilledDuringTank = 0;
	tankThrow                 = false;

	tankSpawned = false;
}

public void RoundEnd_Event(Handle event, const char[] name, bool dontBroadcast)
{
	if (StrEqual(sGameMode, "coop", false))
	{
		if (bInRound)
		{
			if (hPluginEnabled.BoolValue)
				CreateTimer(0.01, delayedMVPPrint);    // shorter delay for scavenge.
			bInRound = false;
		}
	}
	else
	{
		// versus or other
		if (bInRound && !StrEqual(name, "map_transition", false))
		{
			// only show / log stuff when the round is done "the first time"
			if (hPluginEnabled.BoolValue)
				CreateTimer(2.0, delayedMVPPrint);
			bInRound = false;
		}
	}

	tankSpawned = false;
}

/*
 *      cmds / reports
 *      ==============
 */
public Action Say_Cmd(int client, int args)
{
	if (!client)
	{
		return Plugin_Continue;
	}

	char sMessage[MAX_NAME_LENGTH];
	GetCmdArg(1, sMessage, sizeof(sMessage));

	if (StrEqual(sMessage, "!mvp") || StrEqual(sMessage, "!mvpme"))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action SurvivorMVP_Cmd(int client, int args)
{
	char
		printBuffer[4096],
		strLines[8][192];

	GetMVPString(printBuffer, sizeof(printBuffer));

	// PrintToChat has a max length. Split it in to individual lines to output separately
	int intPieces = ExplodeString(printBuffer, "\n", strLines, sizeof(strLines), sizeof(strLines[]));

	if (client && IsClientConnected(client))
	{
		for (int i = 0; i < intPieces; i++)
		{
			CPrintToChat(client, "%s", strLines[i]);
		}
	}
	PrintLoserz(true, client);
	return Plugin_Continue;
}

public Action ShowMVPStats_Cmd(int client, int args)
{
	PrintLoserz(true, client);
	return Plugin_Continue;
}

public Action delayedMVPPrint(Handle timer)
{
	char
		printBuffer[4096],
		strLines[8][192];

	GetMVPString(printBuffer, sizeof(printBuffer));

	// PrintToChatAll has a max length. Split it in to individual lines to output separately
	int intPieces = ExplodeString(printBuffer, "\n", strLines, sizeof(strLines), sizeof(strLines[]));
	for (int i = 0; i < intPieces; i++)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client)) CPrintToChat(client, "{default}%s", strLines[i]);
		}
	}
	CreateTimer(0.1, PrintLosers);
	return Plugin_Continue;
}

public Action PrintLosers(Handle timer)
{
	PrintLoserz(false, -1);
	return Plugin_Continue;
}

stock void PrintLoserz(bool bSolo, int client)
{
	char tmpBuffer[512];
	// also find the three non-mvp survivors and tell them they sucked
	// tell them they sucked with SI
	if (iTotalDamageAll > 0)
	{
		int
			mvp_SI = findMVPSI(),
			mvp_SI_losers[3];
		mvp_SI_losers[0] = findMVPSI(mvp_SI);                                        // second place
		mvp_SI_losers[1] = findMVPSI(mvp_SI, mvp_SI_losers[0]);                      // third
		mvp_SI_losers[2] = findMVPSI(mvp_SI, mvp_SI_losers[0], mvp_SI_losers[1]);    // fourth

		for (int i = 0; i <= 2; i++)
		{
			if (IsClientAndInGame(mvp_SI_losers[i]) && !IsFakeClient(mvp_SI_losers[i]))
			{
				if (bSolo)
				{
					if (mvp_SI_losers[i] == client)
					{
						Format(tmpBuffer, sizeof(tmpBuffer), "%t", "YourRankSI", (i + 2), iDidDamageAll[mvp_SI_losers[i]], (float(iDidDamageAll[mvp_SI_losers[i]]) / float(iTotalDamageAll)) * 100, iGotKills[mvp_SI_losers[i]], (float(iGotKills[mvp_SI_losers[i]]) / float(iTotalKills)) * 100);
						CPrintToChat(mvp_SI_losers[i], "%s", tmpBuffer);
					}
				}
				else
				{
					Format(tmpBuffer, sizeof(tmpBuffer), "%t", "YourRankSI", (i + 2), iDidDamageAll[mvp_SI_losers[i]], (float(iDidDamageAll[mvp_SI_losers[i]]) / float(iTotalDamageAll)) * 100, iGotKills[mvp_SI_losers[i]], (float(iGotKills[mvp_SI_losers[i]]) / float(iTotalKills)) * 100);
					CPrintToChat(mvp_SI_losers[i], "%s", tmpBuffer);
				}
			}
		}
	}

	// tell them they sucked with Common
	if (iTotalCommon > 0)
	{
		int
			mvp_CI = findMVPCommon(),
			mvp_CI_losers[3];
		mvp_CI_losers[0] = findMVPCommon(mvp_CI);                                        // second place
		mvp_CI_losers[1] = findMVPCommon(mvp_CI, mvp_CI_losers[0]);                      // third
		mvp_CI_losers[2] = findMVPCommon(mvp_CI, mvp_CI_losers[0], mvp_CI_losers[1]);    // fourth

		for (int i = 0; i <= 2; i++)
		{
			if (IsClientAndInGame(mvp_CI_losers[i]) && !IsFakeClient(mvp_CI_losers[i]))
			{
				if (bSolo)
				{
					if (mvp_CI_losers[i] == client)
					{
						Format(tmpBuffer, sizeof(tmpBuffer), "%t", "YourRankCI", (i + 2), iGotCommon[mvp_CI_losers[i]], (float(iGotCommon[mvp_CI_losers[i]]) / float(iTotalCommon)) * 100);
						CPrintToChat(mvp_CI_losers[i], "%s", tmpBuffer);
					}
				}
				else
				{
					Format(tmpBuffer, sizeof(tmpBuffer), "%t", "YourRankCI", (i + 2), iGotCommon[mvp_CI_losers[i]], (float(iGotCommon[mvp_CI_losers[i]]) / float(iTotalCommon)) * 100);
					CPrintToChat(mvp_CI_losers[i], "%s", tmpBuffer);
				}
			}
		}
	}

	// tell them they were better with FF (I know, I know, losers = winners)
	if (iTotalFF > 0)
	{
		int
			mvp_FF = findLVPFF(),
			mvp_FF_losers[3];
		mvp_FF_losers[0] = findLVPFF(mvp_FF);                                        // second place
		mvp_FF_losers[1] = findLVPFF(mvp_FF, mvp_FF_losers[0]);                      // third
		mvp_FF_losers[2] = findLVPFF(mvp_FF, mvp_FF_losers[0], mvp_FF_losers[1]);    // fourth

		for (int i = 0; i <= 2; i++)
		{
			if (IsClientAndInGame(mvp_FF_losers[i]) && !IsFakeClient(mvp_FF_losers[i]))
			{
				if (bSolo)
				{
					if (mvp_FF_losers[i] == client)
					{
						Format(tmpBuffer, sizeof(tmpBuffer), "%t", "YourRankFF", (i + 2), iDidFF[mvp_FF_losers[i]], (float(iDidFF[mvp_FF_losers[i]]) / float(iTotalFF)) * 100);
						CPrintToChat(mvp_FF_losers[i], "%s", tmpBuffer);
					}
				}
				else
				{
					Format(tmpBuffer, sizeof(tmpBuffer), "%t", "YourRankFF", (i + 2), iDidFF[mvp_FF_losers[i]], (float(iDidFF[mvp_FF_losers[i]]) / float(iTotalFF)) * 100);
					CPrintToChat(mvp_FF_losers[i], "%s", tmpBuffer);
				}
			}
		}
	}
}
/**
 * When an entity is created (which we use to track rocks)
 * don't actually need this
 */
public void OnEntityCreated(int entity, const char[] classname)
{
	if (!tankThrow)
	{
		return;
	}

	if (StrEqual(classname, "tank_rock", true))
	{
		rockIndex = entity;
		tankThrow = true;
	}
}

/**
 * When an entity has been destroyed (i.e. when a rock lands on someone)
 */
public void OnEntityDestroyed(int entity)
{
	// The rock has been destroyed
	if (rockIndex == entity)
	{
		tankThrow = false;
	}
}

/**
 * When an infected uses their ability
 */
public Action abilityUseEvent(Handle event, const char[] name, bool dontBroadcast)
{
	char ability[32];
	GetEventString(event, "ability", ability, 32);

	// If tank is throwing a rock
	if (StrEqual(ability, "ability_throw", true))
	{
		tankThrow = true;
	}
	return Plugin_Continue;
}

/**
 * Track pill usage
 */
public void pillsUsedEvent(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == 0 || !IsClientInGame(client))
	{
		return;
	}

	pillsUsed[client]++;
}

/**
 * Track boomer pops
 */
public void boomerExploded(Handle event, const char[] name, bool dontBroadcast)
{
	// We only want to track pops where the boomer didn't bile anyone
	bool biled = GetEventBool(event, "splashedbile");
	if (!biled)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (attacker == 0 || !IsClientInGame(attacker))
		{
			return;
		}
		boomerPops[attacker]++;
	}
}

/**
 * Track when someone gets charged (end of charge for level, or if someone shoots you off etc.)
 */
public void chargerCarryEnd(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (client == 0 || !IsClientInGame(client))
	{
		return;
	}

	timesPinned[client][ZC_CHARGER]++;
	totalPinned[client]++;

	if (tankSpawned)
	{
		ttlPinnedDuringTank[client]++;
	}
}

/**
 * Track when someone gets jockeyed.
 */
public void jockeyRide(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (client == 0 || !IsClientInGame(client))
	{
		return;
	}

	timesPinned[client][ZC_JOCKEY]++;
	totalPinned[client]++;

	if (tankSpawned)
	{
		ttlPinnedDuringTank[client]++;
	}
}

/**
 * Track when someone gets huntered.
 */
public void hunterLunged(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (client == 0 || !IsClientInGame(client))
	{
		return;
	}

	timesPinned[client][ZC_HUNTER]++;
	totalPinned[client]++;

	if (tankSpawned)
	{
		ttlPinnedDuringTank[client]++;
	}
}

/**
 * Track when someone gets smoked (we track when they start getting smoked, because anyone can get smoked)
 */
public void smokerChoke(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (client == 0 || !IsClientInGame(client))
	{
		return;
	}

	timesPinned[client][ZC_SMOKER]++;
	totalPinned[client]++;

	if (tankSpawned)
	{
		ttlPinnedDuringTank[client]++;
	}
}

/**
 * When the tank spawns
 */
public void tankSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	tankSpawned = true;
}

/**
 * When the tank is killed
 */
public void tankKilled(Handle event, const char[] name, bool dontBroadcast)
{
	tankSpawned = false;
}

/*
 *      track damage/kills
 *      ==================
 */
public void PlayerHurt_Event(Handle event, const char[] name, bool dontBroadcast)
{
	int
		zombieClass = 0,
		// Victim details
		victimId    = GetEventInt(event, "userid"),
		victim      = GetClientOfUserId(victimId),
		// Attacker details
		attackerId  = GetEventInt(event, "attacker"),
		attacker    = GetClientOfUserId(attackerId),
		// Misc details
		damageDone  = GetEventInt(event, "dmg_health");

	// no world damage or flukes or whatevs, no bot attackers, no infected-to-infected damage
	if (victimId && attackerId && IsClientAndInGame(victim) && IsClientAndInGame(attacker))
	{
		// If a survivor is attacking infected
		if (GetClientTeam(attacker) == TEAM_SURVIVOR && GetClientTeam(victim) == TEAM_INFECTED)
		{
			zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

			// Increment the damage for that class to the total
			iDidDamageClass[attacker][zombieClass] += damageDone;

			// separately store SI and tank damage
			if (zombieClass >= ZC_SMOKER && zombieClass < ZC_WITCH)
			{
				// If the tank is up, let's store separately
				if (tankSpawned)
				{
					siDmgDuringTank[attacker] += damageDone;
				}

				iDidDamage[attacker] += damageDone;
				iDidDamageAll[attacker] += damageDone;
				iTotalDamageAll += damageDone;
			}
			else if (zombieClass == ZC_TANK && damageDone != 5000)    // For some reason the last attacker does 5k damage?
			{
				// We want to track tank damage even if we're not factoring it in to our mvp result
				iDidDamageTank[attacker] += damageDone;

				// If we're factoring it in, include it in our overall damage
				if (bCountTankDamage)
				{
					iDidDamageAll[attacker] += damageDone;
					iTotalDamageAll += damageDone;
				}
			}
		}

		// Otherwise if friendly fire
		else if (GetClientTeam(attacker) == TEAM_SURVIVOR && GetClientTeam(victim) == TEAM_SURVIVOR && bTrackFF)    // survivor on survivor action == FF
		{
			if (!bRUPActive || GetEntityMoveType(victim) != MOVETYPE_NONE || bPlayerLeftStartArea)
			{
				// but don't record while frozen in readyup / before leaving saferoom
				iDidFF[attacker] += damageDone;
				iTotalFF += damageDone;
			}
		}

		// Otherwise if infected are inflicting damage on a survivor
		else if (GetClientTeam(attacker) == TEAM_INFECTED && GetClientTeam(victim) == TEAM_SURVIVOR)
		{
			zombieClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");

			// If we got hit by a tank, let's see what type of damage it was
			// If it was from a rock throw
			if (tankThrow && zombieClass == ZC_TANK && damageDone == 24)
			{
				rocksEaten[victim]++;
			}
			damageReceived[victim] += damageDone;
		}
	}
}

/**
 * When the infected are hurt (i.e. when a survivor hurts an SI)
 * We want to use this to track damage done to the witch.
 */
public void InfectedHurt_Event(Handle event, const char[] name, bool dontBroadcast)
{
	// catch damage done to witch
	int victimEntId = GetEventInt(event, "entityid");

	if (IsWitch(victimEntId))
	{
		int
			attackerId = GetEventInt(event, "attacker"),
			attacker   = GetClientOfUserId(attackerId),
			damageDone = GetEventInt(event, "amount");

		// no world damage or flukes or whatevs, no bot attackers
		if (attackerId && IsClientAndInGame(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR)
		{
			// We want to track the witch damage regardless of whether we're counting it in our mvp stat
			iDidDamageWitch[attacker] += damageDone;

			// If we're counting witch damage in our mvp stat, lets add the amount of damage done to the witch
			if (bCountWitchDamage)
			{
				iDidDamageAll[attacker] += damageDone;
				iTotalDamageAll += damageDone;
			}
		}
	}
}

public void PlayerDeath_Event(Handle event, const char[] name, bool dontBroadcast)
{
	// Get the victim details
	int
		zombieClass = 0,
		victimId    = GetEventInt(event, "userid"),
		victim      = GetClientOfUserId(victimId),
		// Get the attacker details
		attackerId  = GetEventInt(event, "attacker"),
		attacker    = GetClientOfUserId(attackerId);

	// no world kills or flukes or whatevs, no bot attackers
	if (victimId && attackerId && IsClientAndInGame(victim) && IsClientAndInGame(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR)
	{
		zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

		// only SI, not the tank && only player-attackers
		if (zombieClass >= ZC_SMOKER && zombieClass < ZC_WITCH)
		{
			// store kill to count for attacker id
			iGotKills[attacker]++;
			iTotalKills++;
		}
	}

	/**
	 * Are we tracking the tank?
	 * This is a secondary measure. For some reason when I test locally in PM, the
	 * tank_killed event is triggered, but when I test in a custom config, it's not.
	 * Hopefully this should fix it.
	 */
	if (victimId && IsClientAndInGame(victim))
	{
		zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
		if (zombieClass == ZC_TANK)
		{
			tankSpawned = false;
		}
	}
}

// Was the zombie a hunter?
public bool isHunter(int zombieClass)
{
	return zombieClass == ZC_HUNTER;
}

public void InfectedDeath_Event(Handle event, const char[] name, bool dontBroadcast)
{
	int
		attackerId = GetEventInt(event, "attacker"),
		attacker   = GetClientOfUserId(attackerId);

	if (attackerId && IsClientAndInGame(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR)
	{
		// If the tank is up, let's store separately
		if (tankSpawned)
		{
			commonKilledDuringTank[attacker]++;
			ttlCommonKilledDuringTank++;
		}

		iGotCommon[attacker]++;
		iTotalCommon++;
		// if victimType > 2, it's an "uncommon" (of some type or other) -- do nothing with this ftpresent.
	}
}

/*
 *      MVP string & 'sorting'
 *      ======================
 */
void GetMVPString(char[] printBuffer, const int iSize)
{
	printBuffer[0] = '\0';
	char
		tmpBuffer[1024],
		tmpName[128],
		botName[16],
		nobodyName[16],
		mvp_SI_name[128],
		mvp_Common_name[128],
		mvp_FF_name[128];

	int
		mvp_SI     = 0,
		mvp_Common = 0,
		mvp_FF     = 0;

	Format(botName, sizeof(botName), "%t", "BotName");
	Format(nobodyName, sizeof(nobodyName), "%t", "NobodyName");
	// calculate MVP per category:
	//  1. SI damage & SI kills + damage to tank/witch
	//  2. common kills

	// SI MVP
	if (!(iBrevityFlags & BREV_SI))
	{
		mvp_SI = findMVPSI();
		if (mvp_SI > 0)
		{
			// get name from client if connected -- if not, use sClientName array
			if (IsClientConnected(mvp_SI))
			{
				GetClientName(mvp_SI, tmpName, sizeof(tmpName));
				if (IsFakeClient(mvp_SI))
				{
					StrCat(tmpName, sizeof(tmpName), botName);
				}
			}
			else
			{
				strcopy(tmpName, sizeof(tmpName), sClientName[mvp_SI]);
			}
			mvp_SI_name = tmpName;
		}
		else
		{
			mvp_SI_name = nobodyName;
		}
	}

	// Common MVP
	if (!(iBrevityFlags & BREV_CI))
	{
		mvp_Common = findMVPCommon();
		if (mvp_Common > 0)
		{
			// get name from client if connected -- if not, use sClientName array
			if (IsClientConnected(mvp_Common))
			{
				GetClientName(mvp_Common, tmpName, sizeof(tmpName));
				if (IsFakeClient(mvp_Common))
				{
					StrCat(tmpName, sizeof(tmpName), botName);
				}
			}
			else
			{
				strcopy(tmpName, sizeof(tmpName), sClientName[mvp_Common]);
			}
			mvp_Common_name = tmpName;
		}
		else
		{
			mvp_Common_name = nobodyName;
		}
	}

	// FF LVP
	if (!(iBrevityFlags & BREV_FF) && bTrackFF)
	{
		mvp_FF = findLVPFF();
		if (mvp_FF > 0)
		{
			// get name from client if connected -- if not, use sClientName array
			if (IsClientConnected(mvp_FF))
			{
				GetClientName(mvp_FF, tmpName, sizeof(tmpName));
				if (IsFakeClient(mvp_FF))
				{
					StrCat(tmpName, sizeof(tmpName), botName);
				}
			}
			else {
				strcopy(tmpName, sizeof(tmpName), sClientName[mvp_FF]);
			}
			mvp_FF_name = tmpName;
		}
		else
		{
			mvp_FF_name = nobodyName;
		}
	}

	// report

	if (mvp_SI == 0 && mvp_Common == 0 && !(iBrevityFlags & BREV_SI && iBrevityFlags & BREV_CI))
	{
		Format(tmpBuffer, sizeof(tmpBuffer), "%t %t\n", "Tag", "NotEnoughAction");
		StrCat(printBuffer, iSize, tmpBuffer);
	}
	else
	{
		if (!(iBrevityFlags & BREV_SI))
		{
			if (mvp_SI > 0)
			{
				if (iBrevityFlags & BREV_PERCENT)
				{
					Format(tmpBuffer, sizeof(tmpBuffer), "%t %t\n", "Tag", "ReportSI_Absolute", mvp_SI_name, iDidDamageAll[mvp_SI], iGotKills[mvp_SI]);
				}
				else if (iBrevityFlags & BREV_ABSOLUTE)
				{
					Format(tmpBuffer, sizeof(tmpBuffer), "%t %t\n", "Tag", "ReportSI_Percent", mvp_SI_name, (float(iDidDamageAll[mvp_SI]) / float(iTotalDamageAll)) * 100, (float(iGotKills[mvp_SI]) / float(iTotalKills)) * 100);
				}
				else
				{
					Format(tmpBuffer, sizeof(tmpBuffer), "%t %t\n", "Tag", "ReportSI_Full", mvp_SI_name, iDidDamageAll[mvp_SI], (float(iDidDamageAll[mvp_SI]) / float(iTotalDamageAll)) * 100, iGotKills[mvp_SI], (float(iGotKills[mvp_SI]) / float(iTotalKills)) * 100);
				}
				StrCat(printBuffer, iSize, tmpBuffer);
			}
			else
			{
				Format(tmpBuffer, sizeof(tmpBuffer), "%t %t\n", "Tag", "ReportSI_Nobody");
				StrCat(printBuffer, iSize, tmpBuffer);
			}
		}

		if (!(iBrevityFlags & BREV_CI))
		{
			if (mvp_Common > 0)
			{
				if (iBrevityFlags & BREV_PERCENT)
				{
					Format(tmpBuffer, sizeof(tmpBuffer), "%t %t\n", "Tag", "ReportCI_Absolute", mvp_Common_name, iGotCommon[mvp_Common]);
				}
				else if (iBrevityFlags & BREV_ABSOLUTE)
				{
					Format(tmpBuffer, sizeof(tmpBuffer), "%t %t\n", "Tag", "ReportCI_Percent", mvp_Common_name, (float(iGotCommon[mvp_Common]) / float(iTotalCommon)) * 100);
				}
				else
				{
					Format(tmpBuffer, sizeof(tmpBuffer), "%t %t\n", "Tag", "ReportCI_Full", mvp_Common_name, iGotCommon[mvp_Common], (float(iGotCommon[mvp_Common]) / float(iTotalCommon)) * 100);
				}
				StrCat(printBuffer, iSize, tmpBuffer);
			}
		}
	}

	// FF
	if (!(iBrevityFlags & BREV_FF) && bTrackFF)
	{
		if (mvp_FF == 0)
		{
			Format(tmpBuffer, sizeof(tmpBuffer), "%t %t\n", "Tag", "NoFF");
			StrCat(printBuffer, iSize, tmpBuffer);
		}
		else
		{
			if (iBrevityFlags & BREV_PERCENT)
			{
				Format(tmpBuffer, sizeof(tmpBuffer), "%t %t\n", "Tag", "ReportFF_Absolute", mvp_FF_name, iDidFF[mvp_FF]);
			}
			else if (iBrevityFlags & BREV_ABSOLUTE)
			{
				Format(tmpBuffer, sizeof(tmpBuffer), "%t %t\n", "Tag", "ReportFF_Percent", mvp_FF_name, (float(iDidFF[mvp_FF]) / float(iTotalFF)) * 100);
			}
			else
			{
				Format(tmpBuffer, sizeof(tmpBuffer), "%t %t\n", "Tag", "ReportFF_Full", mvp_FF_name, iDidFF[mvp_FF], (float(iDidFF[mvp_FF]) / float(iTotalFF)) * 100);
			}
			StrCat(printBuffer, iSize, tmpBuffer);
		}
	}
}

int findMVPSI(int excludeMeA = 0, int excludeMeB = 0, int excludeMeC = 0)
{
	int
		i,
		maxIndex = 0;
	for (i = 1; i < sizeof(iDidDamageAll); i++)
	{
		if (iDidDamageAll[i] > iDidDamageAll[maxIndex] && i != excludeMeA && i != excludeMeB && i != excludeMeC)
			maxIndex = i;
	}
	return maxIndex;
}

int findMVPCommon(int excludeMeA = 0, int excludeMeB = 0, int excludeMeC = 0)
{
	int
		i,
		maxIndex = 0;
	for (i = 1; i < sizeof(iGotCommon); i++)
	{
		if (iGotCommon[i] > iGotCommon[maxIndex] && i != excludeMeA && i != excludeMeB && i != excludeMeC)
			maxIndex = i;
	}
	return maxIndex;
}

int findLVPFF(int excludeMeA = 0, int excludeMeB = 0, int excludeMeC = 0)
{
	int i, maxIndex = 0;
	for (i = 1; i < sizeof(iDidFF); i++)
	{
		if (iDidFF[i] > iDidFF[maxIndex] && i != excludeMeA && i != excludeMeB && i != excludeMeC)
			maxIndex = i;
	}
	return maxIndex;
}

/*
 *      general functions
 *      =================
 */

stock bool IsClientAndInGame(int index)
{
	return (index > 0 && index <= MaxClients && IsClientInGame(index));
}

stock bool IsSurvivor(int client)
{
	return IsClientAndInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR;
}

stock bool IsInfected(int client)
{
	return IsClientAndInGame(client) && GetClientTeam(client) == TEAM_INFECTED;
}

stock bool IsWitch(int iEntity)
{
	if (iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		char strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}

stock int getSurvivor(int exclude[4])
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i))
		{
			bool tagged = false;
			// exclude already tagged survs
			for (int j = 0; j < 4; j++)
			{
				if (exclude[j] == i)
				{
					tagged = true;
				}
			}
			if (!tagged)
			{
				return i;
			}
		}
	}
	return 0;
}
