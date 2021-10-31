#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <caster_system>

ArrayList h_whosHadTank;
char queuedTankSteamId[64];
ConVar hTankPrint, hTankDebug;
bool casterSystemAvailable;
int tankClassIndex;
Handle selectionForward;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead: tankClassIndex = 5;
		case Engine_Left4Dead2: tankClassIndex = 8;
		default: return APLRes_SilentFailure;
	}
	CreateNative("GetTankSelection", _Native_GetTankSelection);
	selectionForward = CreateGlobalForward("OnTankSelection", ET_Ignore, Param_Cell);
	return APLRes_Success;
}

public int _Native_GetTankSelection(Handle plugin, int numParams) { return getInfectedPlayerBySteamId(queuedTankSteamId); }

public Plugin myinfo = 
{
	name = "L4D2 Tank Control",
	author = "arti", //Add support sm1.11 - A1m`
	description = "Distributes the role of the tank evenly throughout the team",
	version = "0.0.18",
	url = "https://github.com/alexberriman/l4d2-plugins/tree/master/l4d_tank_control"
}

public void OnPluginStart()
{
	// Load translations (for targeting player)
	LoadTranslations("common.phrases");
	
	// Event hooks
	HookEvent("player_left_start_area", PlayerLeftStartArea_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
	HookEvent("player_team", PlayerTeam_Event, EventHookMode_Post);
	HookEvent("player_death", PlayerDeath_Event, EventHookMode_Post);
	
	// Initialise the tank arrays/data values
	h_whosHadTank = new ArrayList(ByteCountToCells(64));
	
	// Admin commands
	RegAdminCmd("sm_tankshuffle", TankShuffle_Cmd, ADMFLAG_SLAY, "Re-picks at random someone to become tank.");
	RegAdminCmd("sm_givetank", GiveTank_Cmd, ADMFLAG_SLAY, "Gives the tank to a selected player");

	// Register the boss commands
	RegConsoleCmd("sm_tank", Tank_Cmd, "Shows who is becoming the tank.");
	RegConsoleCmd("sm_boss", Tank_Cmd, "Shows who is becoming the tank.");
	RegConsoleCmd("sm_witch", Tank_Cmd, "Shows who is becoming the tank.");
	
	// Cvars
	hTankPrint = CreateConVar("tankcontrol_print_all", "0", "Who gets to see who will become the tank? (0 = Infected, 1 = Everyone)");
	hTankDebug = CreateConVar("tankcontrol_debug", "0", "Whether or not to debug to console");
}

public void OnAllPluginsLoaded()
{
	casterSystemAvailable = LibraryExists("caster_system");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "caster_system")) casterSystemAvailable = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "caster_system")) casterSystemAvailable = false;
}

/*public void OnClientDisconnect(int client) 
{
	char tmpSteamId[64];
	
	if (client)
	{
		GetClientAuthId(client, AuthId_Steam2, tmpSteamId, sizeof(tmpSteamId));
		if (strcmp(queuedTankSteamId, tmpSteamId) == 0)
		{
			chooseTank(0);
			outputTankToAll(0);
		}
	}
}*/

/**
 * When a new game starts, reset the tank pool.
 */
 
public Action L4D_OnClearTeamScores(bool newCampaign)
{
	CreateTimer(10.0, newGame);
}

public Action newGame(Handle timer)
{
	int teamAScore = L4D2Direct_GetVSCampaignScore(0);
	int teamBScore = L4D2Direct_GetVSCampaignScore(1);
	
	// If it's a new game, reset the tank pool
	if (teamAScore == 0 && teamBScore == 0)
	{
		h_whosHadTank.Clear();
		queuedTankSteamId = "";
	}
}

/**
 * When the round ends, reset the active tank.
 */
 
public void RoundEnd_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
	queuedTankSteamId = "";
}

/**
 * When a player leaves the start area, choose a tank and output to all.
 */
 
public void PlayerLeftStartArea_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
	chooseTank(0);
	outputTankToAll(0);
}

/**
 * When the queued tank switches teams, choose a new one
 */
 
public void PlayerTeam_Event(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	if (client && hEvent.GetInt("oldteam") == 3)
	{
		char tmpSteamId[64];
		if (GetClientAuthId(client, AuthId_Steam2, tmpSteamId, sizeof(tmpSteamId))
			&& strcmp(queuedTankSteamId, tmpSteamId) == 0
		) {
			RequestFrame(chooseTank, 0);
			RequestFrame(outputTankToAll, 0);
		}
	}
}

/**
 * When the tank dies, requeue a player to become tank (for finales)
 */
 
public void PlayerDeath_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int victimId = hEvent.GetInt("userid");
	int victim = GetClientOfUserId(victimId);
	
	if (victim)
	{
		int zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
		if (zombieClass == tankClassIndex) 
		{
			PrintDebug("[TC] Tank died(1), choosing a new tank");
			chooseTank(0);
			outputTankToAll(0);
		}
	}
}

/**
 * When a player wants to find out whos becoming tank,
 * output to them.
 */
 
public Action Tank_Cmd(int client, int args)
{
	if (!IsClientInGame(client)) 
	  return Plugin_Handled;

	// Only output if we have a queued tank
	if (! strlen(queuedTankSteamId))
	{
		return Plugin_Handled;
	}
	
	int tankClient = getInfectedPlayerBySteamId(queuedTankSteamId);
	if (tankClient != -1)
	{
		// If on infected, print to entire team
		if (GetClientTeam(client) == 3 || (casterSystemAvailable && IsClientCaster(client)))
		{
			if (client == tankClient) CPrintToChat(client, "{red}<{default}Tank Selection{red}> {green}You {default}will become the {red}Tank{default}!");
			else CPrintToChat(client, "{red}<{default}Tank Selection{red}> {olive}%N {default}will become the {red}Tank!", tankClient);
		}
	}
	
	return Plugin_Handled;
}

/**
 * Shuffle the tank (randomly give to another player in
 * the pool.
 */
 
public Action TankShuffle_Cmd(int client, int args)
{
	chooseTank(0);
	outputTankToAll(0);
	
	return Plugin_Handled;
}

/**
 * Give the tank to a specific player.
 */
 
public Action GiveTank_Cmd(int client, int args)
{    
	// Who are we targetting?
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	// Try and find a matching player
	int target = FindTarget(client, arg1, true, false);
	
	// Set the tank
	if (target != -1)
	{
		// Checking if on our desired team
		if (GetClientTeam(target) != 3)
		{
			CPrintToChatAll("{red}<{default}Tank Selection{red}> {default}Unable to target %N who is not on infected.", target);
			return Plugin_Handled;
		}
		
		chooseTank(target);
		outputTankToAll(0);
	}
	
	return Plugin_Handled;
}

/**
 * Selects a player on the infected team from random who hasn't been
 * tank and gives it to them.
 */
 
public void chooseTank(any target)
{
	if (!target)
	{
		// Create our pool of players to choose from
		ArrayList infectedPool = new ArrayList(ByteCountToCells(64));
		addTeamSteamIdsToArray(infectedPool, 3);
		
		// If there is nobody on the infected team, return (otherwise we'd be stuck trying to select forever)
		if (infectedPool.Length == 0)
		{
			delete infectedPool;
			return;
		}
		
		// Remove players who've already had tank from the pool.
		removeTanksFromPool(infectedPool, h_whosHadTank);
		
		// If the infected pool is empty, remove infected players from pool
		if (infectedPool.Length == 0) // (when nobody on infected ,error)
		{
			ArrayList infectedTeam = new ArrayList(ByteCountToCells(64));
			addTeamSteamIdsToArray(infectedTeam, 3);
			if (infectedTeam.Length > 1)
			{
				removeTanksFromPool(h_whosHadTank, infectedTeam);
				chooseTank(0);
			}
			else
			{
				queuedTankSteamId = "";
			}
			
			delete infectedTeam;
			delete infectedPool;
			return;
		}
		
		// Select a random person to become tank
		int rndIndex = GetRandomInt(0, infectedPool.Length - 1);
		infectedPool.GetString(rndIndex, queuedTankSteamId, sizeof(queuedTankSteamId));
		target = getInfectedPlayerBySteamId(queuedTankSteamId);
		delete infectedPool;
	}
	else
	{
		GetClientAuthId(target, AuthId_Steam2, queuedTankSteamId, sizeof(queuedTankSteamId));
	}
	
	Call_StartForward(selectionForward);
	Call_PushCell(target);
	Call_Finish();
}

/**
 * Make sure we give the tank to our queued player.
 */
 
public Action L4D_OnTryOfferingTankBot(int tank_index, bool &enterStatis)
{    
	// Reset the tank's frustration if need be
	if (! IsFakeClient(tank_index)) 
	{
		PrintHintText(tank_index, "Rage Meter Refilled");
		for (int i = 1; i <= MaxClients; i++) 
		{
			if (! IsClientInGame(i) || GetClientTeam(i) != 3)
				continue;

			if (tank_index == i) CPrintToChat(i, "{red}<{default}Tank Rage{red}> {olive}Rage Meter {red}Refilled");
			else CPrintToChat(i, "{red}<{default}Tank Rage{red}> {default}({green}%N{default}'s) {olive}Rage Meter {red}Refilled", tank_index);
		}
		
		SetTankFrustration(tank_index, 100);
		L4D2Direct_SetTankPassedCount(L4D2Direct_GetTankPassedCount() + 1);
		
		return Plugin_Handled;
	}
	
	// If we don't have a queued tank, choose one
	if (! strlen(queuedTankSteamId))
		chooseTank(0);
	
	// Mark the player as having had tank
	else
	{
		setTankTickets(queuedTankSteamId, 20000);
		h_whosHadTank.PushString(queuedTankSteamId);
	}
	
	return Plugin_Continue;
}

/**
 * Sets the amount of tickets for a particular player, essentially giving them tank.
 */
 
void setTankTickets(const char[] steamId, int tickets)
{
	int tankClientId = getInfectedPlayerBySteamId(steamId);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && ! IsFakeClient(i) && GetClientTeam(i) == 3)
		{
			L4D2Direct_SetTankTickets(i, (i == tankClientId) ? tickets : 0);
		}
	}
}

/**
 * Output who will become tank
 */
 
public void outputTankToAll(any data)
{
	int tankClient = getInfectedPlayerBySteamId(queuedTankSteamId);
	
	if (tankClient != -1)
	{
		if (hTankPrint.BoolValue)
		{
			CPrintToChatAll("{red}<{default}Tank Selection{red}> {olive}%N {default}will become the {red}Tank!", tankClient);
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++) 
			{
				if (!IsClientInGame(i) || IsFakeClient(i))
				continue;

				if (GetClientTeam(i) != 3 && !IsClientCaster(i))
				continue;

				if (tankClient == i) CPrintToChat(i, "{red}<{default}Tank Selection{red}> {green}You {default}will become the {red}Tank{default}!");
				else CPrintToChat(i, "{red}<{default}Tank Selection{red}> {olive}%N {default}will become the {red}Tank!", tankClient);
			}
		}
	}
}

/**
 * Adds steam ids for a particular team to an array.
 * 
 * @ param Handle:steamIds
 *     The array steam ids will be added to.
 * @param L4D2Team:team
 *     The team to get steam ids for.
 */
 
void addTeamSteamIdsToArray(ArrayList steamIds, int team)
{
	char steamId[64];

	for (int i = 1; i <= MaxClients; i++)
	{
		// Basic check
		if (IsClientInGame(i) && ! IsFakeClient(i))
		{
			// Checking if on our desired team
			if (GetClientTeam(i) != team)
				continue;
		
			if (GetClientAuthId(i, AuthId_Steam2, steamId, sizeof(steamId)))
				steamIds.PushString(steamId);
		}
	}
}

/**
 * Removes steam ids from the tank pool if they've already had tank.
 * 
 * @param Handle:steamIdTankPool
 *     The pool of potential steam ids to become tank.
 * @ param Handle:tanks
 *     The steam ids of players who've already had tank.
 * 
 * @return
 *     The pool of steam ids who haven't had tank.
 */
 
void removeTanksFromPool(ArrayList steamIdTankPool, ArrayList tanks)
{
	int index;
	char steamId[64];
	
	int ArraySize = tanks.Length;
	for (int i = 0; i < ArraySize; i++)
	{
		tanks.GetString(i, steamId, sizeof(steamId));
		index = steamIdTankPool.FindString(steamId);
		
		if (index != -1)
		{
			steamIdTankPool.Erase(index);
		}
	}
}

/**
 * Retrieves a player's client index by their steam id.
 * 
 * @param const String:steamId[]
 *     The steam id to look for.
 * 
 * @return
 *     The player's client index.
 */
 
int getInfectedPlayerBySteamId(const char[] steamId) 
{
	char tmpSteamId[64];
   
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 3)
			continue;
		
		if (!GetClientAuthId(i, AuthId_Steam2, tmpSteamId, sizeof(tmpSteamId)))     
			continue;
		
		if (strcmp(steamId, tmpSteamId) == 0)
			return i;
	}
	
	return -1;
}

void PrintDebug(const char[] format, any ...)
{
	if (hTankDebug.BoolValue)
	{
		char buffer[512];
		VFormat(buffer, sizeof buffer, format, 2);
		PrintToConsoleAll(buffer);
	}
}

void SetTankFrustration(int iTankClient, int iFrustration) {
	if (iFrustration < 0 || iFrustration > 100) {
		return;
	}
	
	SetEntProp(iTankClient, Prop_Send, "m_frustration", 100-iFrustration);
}