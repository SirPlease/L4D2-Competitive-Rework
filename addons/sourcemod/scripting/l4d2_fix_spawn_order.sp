#pragma semicolon 1

#include <sourcemod>
#include <left4dhooks>
#include <colors>

#undef REQUIRE_PLUGIN
#include "readyup"

// Spawn Storage
bool PlayerSpawned[MAXPLAYERS + 1];
bool bRespawning[MAXPLAYERS + 1];
int storedClass[MAXPLAYERS + 1];

// Small Timer to Fix AI Tank pass
float fTankPls[MAXPLAYERS + 1];
bool bKeepChecking[MAXPLAYERS + 1];

// Array
Handle g_SpawnsArray;

// Ready-up
bool readyUpIsAvailable;
bool bLive;

// cvars
Handle hDominators;
Handle hSpitterLimit;
Handle hMaxSI;
int dominators;
int spitterlimit;
int maxSI;

/* These class numbers are the same ones used internally in L4D2 SIClass enum*/
enum {
	SI_None=0,
	SI_Smoker=1,
	SI_Boomer,
	SI_Hunter,
	SI_Spitter,
	SI_Jockey,
	SI_Charger,
	SI_Witch,
	SI_Tank,
	
	SI_MAX_SIZE
};

char g_sSIClassNames[SI_MAX_SIZE][] = {
	"",
	"Smoker",
	"Boomer",
	"Hunter",
	"Spitter",
	"Jockey",
	"Charger",
	"Witch",
	"Tank"
};

public Plugin myinfo =
{
	name = "L4D2 Proper Sack Order",
	author = "Sir",
	description = "Finally fix that pesky spawn rotation not being reliable",
	version = "1.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	// Events
	HookEvent("round_start", CleanUp);
	HookEvent("round_end", CleanUp);
	HookEvent("player_team", PlayerTeam);
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath);

	// Array
	g_SpawnsArray = CreateArray(16);

	hMaxSI = FindConVar("z_max_player_zombies");
	maxSI = GetConVarInt(hMaxSI);

	hSpitterLimit = FindConVar("z_versus_spitter_limit");
	spitterlimit = GetConVarInt(hSpitterLimit);

	HookConVarChange(hMaxSI, cvarChanged);
	HookConVarChange(hSpitterLimit, cvarChanged);
}

// Ready-up Checks
public void OnAllPluginsLoaded()
{
	readyUpIsAvailable = LibraryExists("readyup");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "readyup"))
		readyUpIsAvailable = false;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "readyup"))
		readyUpIsAvailable = true;
}

public void OnConfigsExecuted() 
{
	dominators = 53;
	hDominators = FindConVar("l4d2_dominators");
	
	if (hDominators != INVALID_HANDLE)
		dominators = GetConVarInt(hDominators);
}

// events
public void CleanUp(Handle event, const char[] name, bool dontBroadcast)
{
	CleanSlate();
}

public void PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	// Check if the Player is Valid and Infected.
	// Triggered when a Player actually spawns in (Players spawn out of Ghost Mode, AI Takes over existing Spawn)
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsValidClient(client)
		|| IsFakeClient(client)
		|| GetClientTeam(client) != 3
		|| !bLive
		|| GetEntProp(client, Prop_Send, "m_zombieClass") == SI_Tank)
	{
		return;
	}

	PlayerSpawned[client] = true;
	bRespawning[client] = false;
}

public void PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int oldteam = GetEventInt(event, "oldteam");

	// 1.3 Notes: Investigate if I did these because they have issues, considering I didn't document this anywhere.
	//--------------------------------------------------------------------------------------------------------------
	// - Why am I checking for Tank here if we only care about Ghost Infected? 
	// - Why not reset stats on players regardless (for safety) prior to the Ghost/Tank check?
	//--------------------------------------------------------------------------------------------------------------
	if (!IsValidClient(client)
		|| oldteam != 3
		|| !bLive
		|| GetEntProp(client, Prop_Send, "m_isGhost") < 1
		|| GetEntProp(client, Prop_Send, "m_zombieClass") == SI_Tank)
	{
		return;
	}

	PlayerSpawned[client] = false;
	bRespawning[client] = false;
	storedClass[client] = 0;

	if (GetArraySize(g_SpawnsArray) > 0)
		ShiftArrayUp(g_SpawnsArray, 0);
	
	SetArrayCell(g_SpawnsArray, 0, GetEntProp(client, Prop_Send, "m_zombieClass"));
}

public void OnClientDisconnect(int client)
{
	if (!IsValidClient(client) || IsFakeClient(client)) {
		return;
	} else {
		PlayerSpawned[client] = false;
		bRespawning[client] = false;
	}
}

public void PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	// Check if the Player is Valid and Infected.
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client) || GetClientTeam(client) != 3 || !bLive)
		return;

	// Don't want Tanks in our Array.. do we?!
	// Also includes a tiny Fix.
	int SI = GetEntProp(client, Prop_Send, "m_zombieClass");
	if (SI != SI_Tank && fTankPls[client] < GetGameTime()) {
		if (storedClass[client] == 0) {
			PushArrayCell(g_SpawnsArray, GetEntProp(client, Prop_Send, "m_zombieClass"));
		}
	}

	if (SI == SI_Tank)
		storedClass[client] = 0;

	if (!IsFakeClient(client))
		PlayerSpawned[client] = false;
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	// Is the Game actually live?
	if (readyUpIsAvailable && IsInReady()) {
		bLive = false;
	} else {
		// Clear Array here.
		// Fill Array with existing spawns (from lowest SI Class to Highest, ie. 2 Hunters, if available, will be spawned before a Spitter as they're SI Class 3 and a Spitter is 4)
		ClearArray(g_SpawnsArray);
		FillArray(g_SpawnsArray);
		bLive = true;
	}

	return Plugin_Continue;
}

public void L4D_OnEnterGhostState(int client)
{
	// Is Game live?
	// Is Valid Client?
	// Is Infected?
	// Instant spawn after passing Tank to AI? (Gets slain) - NOTE: We don't need to reset fTankPls thanks to nodeathcamskip.smx
	if (!bLive
		|| !IsValidClient(client)
		|| GetClientTeam(client) != 3
		|| fTankPls[client] > GetGameTime())
	{
		return;
	}

	// Is Player Respawning?
	if (PlayerSpawned[client]) {
		bRespawning[client] = true; 
		return;
	}

	// Switch Class and Pass Client Info as he will already be counted in the total.
	// If for some reason the returned SI is invalid or if the Array isn't filled up yet: allow Director to continue.
	int SI = ReturnNextSIInQueue(client);
	if (SI > 0) {
		L4D_SetClass(client, SI);
	}
	
	if (bKeepChecking[client]) {
		storedClass[client] = SI;
		bKeepChecking[client] = false;
	}
}

public Action L4D_OnTryOfferingTankBot(int tank_index, bool &enterStasis)
{
	if (IsFakeClient(tank_index)) {
		// Because Tank Control sets the Tank Tickets as well.
		// This method will work, but it will only work with Configs/Server setups that use L4D Tank Control
		CreateTimer(0.01, CheckTankie);
	}

	return Plugin_Continue;
}

public void L4D2_OnTankPassControl(int oldTank, int newTank, int passCount)
{
	if (!IsFakeClient(newTank)) {
		if (storedClass[newTank] > 0) {
			if (!PlayerSpawned[newTank] || bRespawning[newTank]) {
				PushArrayCell(g_SpawnsArray, storedClass[newTank]);
				bRespawning[newTank] = false;
			}
		}
		bKeepChecking[newTank] = false;
	} else {
		fTankPls[oldTank] = GetGameTime() + 2.0;
		storedClass[oldTank] = 0;
	}
}

public Action CheckTankie(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i) && !IsFakeClient(i) && GetClientTeam(i) == 3) {
			if (L4D2Direct_GetTankTickets(i) == 20000) {
				if (GetEntProp(i, Prop_Send, "m_isGhost") > 0) {
					storedClass[i] = GetEntProp(i, Prop_Send, "m_zombieClass");
				} else {
					bKeepChecking[i] = true;
				}
			}
		}
	}

	return Plugin_Stop;
}

public void cvarChanged(Handle cvar, const char[] oldValue, const char[] newValue)
{
	maxSI = GetConVarInt(hMaxSI);
	spitterlimit = GetConVarInt(hSpitterLimit);
}

int ReturnNextSIInQueue(int client)
{
	int QueuedSI = SI_None;
	int QueuedIndex = 0;
	int ArraySize = GetArraySize(g_SpawnsArray);
	
	// Do we have Spawns in our Array yet?
	if (ArraySize > 0) {
		// Check if we actually need a "Support" SI at this time.
		// Requirements:
		// - No Quadcap Plugin.
		// - No Tank Alive.
		// - A Full Infected Team (4 Players)
		// - No "Support" SI Alive.
		if (dominators != 0
			&& !IsTankInPlay()
			&& !IsSupportSIAlive(client)
			&& IsInfectedTeamFull()
			&& IsInfectedTeamAlive() >= (maxSI - 1))
		{				
			// Look for the Boomer's position in the Array.
			QueuedSI = SI_Boomer;
			QueuedIndex = FindValueInArray(g_SpawnsArray, 2);
		
			// Look for the Spitter's position in the Array.
			int iTempIndex = FindValueInArray(g_SpawnsArray, 4);

			// Check if the Spitter should be selected for Spawning (because she died before the Boomer did)
			//
			// Additional Check:
			// -----------------
			// If the Boomer position returns -1 (it shouldn't, considering we've checked for any Support SI being alive)
			// Perhaps a non-Boomer config? :D
			if (QueuedIndex > iTempIndex || QueuedIndex == -1) { 
				QueuedSI = SI_Spitter; 
				QueuedIndex = iTempIndex; 
			}
		} else {
			// enforce the first available Spawn in the Array	
			// Simple, just take the Array's very first Index value.
			QueuedSI = GetArrayCell(g_SpawnsArray, 0);

			// Hold up, no spitters when Tank is up!
			// Luckily all the plugin does is change the spitter limit to 0, so we can easily track it.
			if (QueuedSI == SI_Spitter && spitterlimit == 0) {
				// Let's take the next SI in the array then.
				QueuedSI = GetArrayCell(g_SpawnsArray, 1);
				QueuedIndex = 1;
			}
		}

		// Remove SI from Array.
		if (QueuedSI != SI_None)
			RemoveFromArray(g_SpawnsArray, QueuedIndex);
	}

	// return Queued SI to function caller.
	return QueuedSI;
}

void CleanSlate()
{
	// Clear Bool.
	bLive = false;

	//Clear Spawn Storage
	for (int i = 1; i <= MAXPLAYERS; i++) {
		PlayerSpawned[i] = false;
		fTankPls[i] = 0.0;
		storedClass[i] = 0;
		bKeepChecking[i] = false;
		bRespawning[i] = false;
	}
}

bool IsTankInPlay() 
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i)
			&& GetClientTeam(i) == 3
			&& IsPlayerAlive(i)
			&& !IsFakeClient(i)
			&& IsTank(i))
		{
			return true;
		}
	}
	return false;
}

bool IsInfectedTeamFull()
{
	int SI;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i)
			&& !IsFakeClient(i)
			&& GetClientTeam(i) == 3)
		{
			SI++;
		}
	}

	if (SI >= maxSI)
		return true;
	
	return false;
}

int IsInfectedTeamAlive()
{
	int SI;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i)
			&& !IsFakeClient(i)
			&& GetClientTeam(i) == 3
			&& IsPlayerAlive(i))
		{
			SI++;
		}
	}

	return SI;
}

bool IsSupportSIAlive(int client)
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i)
			&& GetClientTeam(i) == 3
			&& IsPlayerAlive(i)
			&& i != client)
		{
			if (IsSupport(i))
				return true;
		}
	}

	// No Support SI Alive, send back-up!
	return false;
}

bool IsSupport(int client) 
{
	int ZClass = GetEntProp(client, Prop_Send, "m_zombieClass");
	return (ZClass == SI_Boomer || ZClass == SI_Spitter);
}

void FillArray(Handle array)
{
	int smokers = GetConVarInt(FindConVar("z_versus_smoker_limit"));
	int boomers = GetConVarInt(FindConVar("z_versus_boomer_limit"));
	int hunters = GetConVarInt(FindConVar("z_versus_hunter_limit"));
	int spitters = GetConVarInt(FindConVar("z_versus_spitter_limit"));
	int jockeys = GetConVarInt(FindConVar("z_versus_jockey_limit"));
	int chargers = GetConVarInt(FindConVar("z_versus_charger_limit"));

	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i)
			&& !IsFakeClient(i)
			&& GetClientTeam(i) == 3)
		{
			int SI = GetEntProp(i, Prop_Send, "m_zombieClass");
			switch (SI)	{
			case 1:
				smokers--;
			case 2:
				boomers--;
			case 3:
				hunters--;
			case 4:
				spitters--;
			case 5:
				jockeys--;
			case 6:
				chargers--;
			}
		}
	}

	while (smokers > 0) {
		smokers--;
		PushArrayCell(array, SI_Smoker);
	}
	while (boomers > 0) {
		boomers--;
		PushArrayCell(array, SI_Boomer);
	}
	while (hunters > 0) {
		hunters--;
		PushArrayCell(array, SI_Hunter);
	}
	while (spitters > 0) {
		spitters--;
		PushArrayCell(array, SI_Spitter);
	}
	while (jockeys > 0) {
		jockeys--;
		PushArrayCell(array, SI_Jockey);
	}
	while (chargers > 0) {
		chargers--;
		PushArrayCell(array, SI_Charger);
	}
}

bool IsTank(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass") == SI_Tank;
}

bool IsValidClient(int client)
{
    if (client <= 0 || client > MaxClients || !IsClientConnected(client))
		return false;

    return IsClientInGame(client);
}
