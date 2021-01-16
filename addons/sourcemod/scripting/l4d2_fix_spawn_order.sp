#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <l4d2lib>
#include <colors>

#undef REQUIRE_PLUGIN
#include "readyup"

// Spawn Storage
new bool:PlayerSpawned[MAXPLAYERS + 1];
new bool:bRespawning[MAXPLAYERS + 1];
new storedClass[MAXPLAYERS + 1];

// Small Timer to Fix AI Tank pass
new Float:fTankPls[MAXPLAYERS + 1];
new bool:bKeepChecking[MAXPLAYERS + 1];

// Array
new Handle:g_SpawnsArray;

// Ready-up
new bool:readyUpIsAvailable;
new bool:bLive;

// Changing SI
new Handle:g_hSetClass;
new Handle:g_hCreateAbility;
new g_oAbility;

// Get dem Cvars
new Handle:hDominators;
new Handle:hSpitterLimit;
new Handle:hMaxSI;
new dominators;
new spitterlimit;
new maxSI;

/* These class numbers are the same ones used internally in L4D2 */
enum SIClass
{
	SI_None=0,
	SI_Smoker=1,
	SI_Boomer,
	SI_Hunter,
	SI_Spitter,
	SI_Jockey,
	SI_Charger,
	SI_Witch,
	SI_Tank
};

stock const String:g_sSIClassNames[SIClass][] = 
{	"", "Smoker", "Boomer", "Hunter", "Spitter", "Jockey", "Charger", "Witch", "Tank" };

public Plugin:myinfo = 
{
	name = "L4D2 Proper Sack Order",
	author = "Sir",
	description = "Finally fix that pesky spawn rotation not being reliable",
	version = "1.3",
	url = "nah"
};

public OnPluginStart()
{
	// Events
	HookEvent("round_start", CleanUp);
	HookEvent("round_end", CleanUp);
	HookEvent("player_team", PlayerTeam);
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath);

	// Gamedata
	Sub_HookGameData();

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
public OnAllPluginsLoaded() { readyUpIsAvailable = LibraryExists("readyup"); }
public OnLibraryRemoved(const String:name[]){ if (StrEqual(name, "readyup")) readyUpIsAvailable = false; }
public OnLibraryAdded(const String:name[]) { if (StrEqual(name, "readyup")) readyUpIsAvailable = true; }
public OnConfigsExecuted() 
{
	dominators = 53;
	hDominators = FindConVar("l4d2_dominators");
	if (hDominators != INVALID_HANDLE) dominators = GetConVarInt(hDominators);
}

// Events
public CleanUp(Handle:event, const String:name[], bool:dontBroadcast) { CleanSlate(); }

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if the Player is Valid and Infected.
	// Triggered when a Player actually spawns in (Players spawn out of Ghost Mode, AI Takes over existing Spawn)
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client) || IsFakeClient(client) || GetClientTeam(client) != 3 || !bLive || GetEntProp(client, Prop_Send, "m_zombieClass") == _:SI_Tank) return;

	PlayerSpawned[client] = true;
	bRespawning[client] = false;
}

public PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new oldteam = GetEventInt(event, "oldteam");

	// 1.3 Notes: Investigate if I did these because they have issues, considering I didn't document this anywhere.
	//--------------------------------------------------------------------------------------------------------------
	// - Why am I checking for Tank here if we only care about Ghost Infected? 
	// - Why not reset stats on players regardless (for safety) prior to the Ghost/Tank check?
	//--------------------------------------------------------------------------------------------------------------
	if (!IsValidClient(client) || oldteam != 3 || !bLive || GetEntProp(client, Prop_Send, "m_isGhost") < 1 || GetEntProp(client, Prop_Send, "m_zombieClass") == _:SI_Tank) return;

	PlayerSpawned[client] = false;
	bRespawning[client] = false;
	storedClass[client] = 0;

	if (GetArraySize(g_SpawnsArray) > 0) ShiftArrayUp(g_SpawnsArray, 0);
	SetArrayCell(g_SpawnsArray, 0, GetEntProp(client, Prop_Send, "m_zombieClass"));
}

public OnClientDisconnect(client)
{
	if (!IsValidClient(client) || IsFakeClient(client)) return;
	else 
	{
		PlayerSpawned[client] = false;
		bRespawning[client] = false;
	}
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if the Player is Valid and Infected.
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client) || GetClientTeam(client) != 3 || !bLive) return;

	// Don't want Tanks in our Array.. do we?!
	// Also includes a tiny Fix.
	new SI = GetEntProp(client, Prop_Send, "m_zombieClass");
	if (SI != _:SI_Tank && fTankPls[client] < GetGameTime()) 
	{
		if (storedClass[client] == 0) PushArrayCell(g_SpawnsArray, GetEntProp(client, Prop_Send, "m_zombieClass"));
	}

	if (SI == _:SI_Tank) storedClass[client] = 0;

	if (!IsFakeClient(client)) PlayerSpawned[client] = false;
}

public Action:L4D_OnFirstSurvivorLeftSafeArea(client)
{
	// Is the Game actually live?
	if (readyUpIsAvailable && IsInReady()) bLive = false;
	else 
	{
		// Clear Array here.
		// Fill Array with existing spawns (from lowest SI Class to Highest, ie. 2 Hunters, if available, will be spawned before a Spitter as they're SI Class 3 and a Spitter is 4)
		ClearArray(g_SpawnsArray);
		FillArray(g_SpawnsArray);
		bLive = true;
	}
}

public L4D_OnEnterGhostState(client)
{
	// Is Game live?
	// Is Valid Client?
	// Is Infected?
	// Instant spawn after passing Tank to AI? (Gets slain) - NOTE: We don't need to reset fTankPls thanks to nodeathcamskip.smx
	if (!bLive || !IsValidClient(client) || GetClientTeam(client) != 3 || fTankPls[client] > GetGameTime()) return;

	// Is Player Respawning?
	if (PlayerSpawned[client]) 
	{
		bRespawning[client] = true; 
		return;
	}

	// Switch Class and Pass Client Info as he will already be counted in the total.
	// If for some reason the returned SI is invalid or if the Array isn't filled up yet: allow Director to continue.
	new SI = ReturnNextSIInQueue(client);
	if (SI > 0) Sub_DetermineClass(client, SI);
	if (bKeepChecking[client]) 
	{
		storedClass[client] = SI;
		bKeepChecking[client] = false;
	}
}

public Action:L4D_OnTryOfferingTankBot(tank_index, &bool:enterStasis)
{
	if (IsFakeClient(tank_index))
	{
		// Because Tank Control sets the Tank Tickets as well.
		// This method will work, but it will only work with Configs/Server setups that use L4D Tank Control
		CreateTimer(0.01, CheckTankie);
	}
}

public L4D2_OnTankPassControl(oldTank, newTank, passCount)
{
	if (!IsFakeClient(newTank))
	{
		if (storedClass[newTank] > 0)
		{
			if (!PlayerSpawned[newTank] || bRespawning[newTank]) 
			{
				PushArrayCell(g_SpawnsArray, storedClass[newTank]);
				bRespawning[newTank] = false;
			}
		}
		bKeepChecking[newTank] = false;
	}
	else 
	{
		fTankPls[oldTank] = GetGameTime() + 2.0;
		storedClass[oldTank] = 0;
	}
}

public Action:CheckTankie(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i) && GetClientTeam(i) == 3)
		{
			if (L4D2Direct_GetTankTickets(i) == 20000)
			{
				if (GetEntProp(i, Prop_Send, "m_isGhost") > 0) storedClass[i] = GetEntProp(i, Prop_Send, "m_zombieClass");
				else bKeepChecking[i] = true;
			}
		}
	}
}

//--------------------------------------------------------------------------------- Gamedata // SDK Stuff

public Sub_HookGameData()
{
	new Handle:g_hGameConf = LoadGameConfigFile("l4d2_zcs");

	if (g_hGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "SetClass");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSetClass = EndPrepSDKCall();

		if (g_hSetClass == INVALID_HANDLE)
			SetFailState("Unable to find SetClass signature.");

		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CreateAbility");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hCreateAbility = EndPrepSDKCall();

		if (g_hCreateAbility == INVALID_HANDLE)
			SetFailState("Unable to find CreateAbility signature.");

		g_oAbility = GameConfGetOffset(g_hGameConf, "oAbility");

		CloseHandle(g_hGameConf);
	}

	else SetFailState("Unable to load l4d2_zcs.txt");
}

// Sets the class of a client.
public Sub_DetermineClass(any:Client, any:ZClass)
{
	new WeaponIndex;
	while ((WeaponIndex = GetPlayerWeaponSlot(Client, 0)) != -1)
	{
		RemovePlayerItem(Client, WeaponIndex);
		RemoveEdict(WeaponIndex);
	}

	SDKCall(g_hSetClass, Client, ZClass);
	AcceptEntityInput(MakeCompatEntRef(GetEntProp(Client, Prop_Send, "m_customAbility")), "Kill");
	SetEntProp(Client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_hCreateAbility, Client), g_oAbility));
}

public cvarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	maxSI = GetConVarInt(hMaxSI);
	spitterlimit = GetConVarInt(hSpitterLimit);
}

//--------------------------------------------------------------------------------- Stocks & Such

stock ReturnNextSIInQueue(client)
{
	new QueuedSI = _:SI_None;
	new QueuedIndex = 0;
	new ArraySize = GetArraySize(g_SpawnsArray);
	
	// Do we have Spawns in our Array yet?
	if (ArraySize > 0)
	{
		// Check if we actually need a "Support" SI at this time.
		// Requirements:
		// - No Quadcap Plugin.
		// - No Tank Alive.
		// - A Full Infected Team (4 Players)
		// - No "Support" SI Alive.
		if (dominators != 0 && !IsTankInPlay() && !IsSupportSIAlive(client) && IsInfectedTeamFull())
		{
			// Look for the Boomer's position in the Array.
			QueuedSI = _:SI_Boomer;
			QueuedIndex = FindValueInArray(g_SpawnsArray, 2);
		
			// Look for the Spitter's position in the Array.
			new iTempIndex = FindValueInArray(g_SpawnsArray, 4);

			// Check if the Spitter should be selected for Spawning (because she died before the Boomer did)
			//
			// Additional Check:
			// -----------------
			// If the Boomer position returns -1 (it shouldn't, considering we've checked for any Support SI being alive)
			// Perhaps a non-Boomer config? :D
			if (QueuedIndex > iTempIndex || QueuedIndex == -1 ) 
			{ 
				QueuedSI = _:SI_Spitter; 
				QueuedIndex = iTempIndex; 
			}		
		}
		// We get to enforce the first available Spawn in the Array!
		else
		{
			// Simple, just take the Array's very first Index value.
			QueuedSI = GetArrayCell(g_SpawnsArray, 0);

			// Hold up, no spitters when Tank is up!
			// Luckily all the plugin does is change the spitter limit to 0, so we can easily track it.
			if (QueuedSI == _:SI_Spitter && spitterlimit == 0)
			{
				// Let's take the next SI in the array then.
				QueuedSI = GetArrayCell(g_SpawnsArray, 1);
				QueuedIndex = 1;
			}
		}

		// Remove SI from Array.
		if (QueuedSI != _:SI_None) RemoveFromArray(g_SpawnsArray, QueuedIndex);
	}

	// return Queued SI to function caller.
	return QueuedSI;
}

stock CleanSlate()
{
	// Clear Bool.
	bLive = false;

	//Clear Spawn Storage
	for(new i = 1; i <= MAXPLAYERS; i++)
	{
		PlayerSpawned[i] = false;
		fTankPls[i] = 0.0;
		storedClass[i] = 0;
		bKeepChecking[i] = false;
		bRespawning[i] = false;
	}
}

stock bool:IsTankInPlay() 
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && IsTank(i)) return true;
	}
	return false;
}

stock bool:IsInfectedTeamFull()
{
	new SI;
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i) && GetClientTeam(i) == 3)
		{
			SI++;
		}
	}

	if (SI >= maxSI) return true;
	return false;
}

stock bool:IsSupportSIAlive(client)
{
	new iSupport;
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && i != client)
		{
			if (IsSupport(i)) iSupport++;
		}
	}

	// No Support SI Alive, send back-up!
	return false;
}

stock bool:IsSupport(client) 
{
	new ZClass = GetEntProp(client, Prop_Send, "m_zombieClass");
	return (ZClass == _:SI_Boomer || ZClass == _:SI_Spitter);
}

stock FillArray(Handle:array)
{
	new smokers = GetConVarInt(FindConVar("z_versus_smoker_limit"));
	new boomers = GetConVarInt(FindConVar("z_versus_boomer_limit"));
	new hunters = GetConVarInt(FindConVar("z_versus_hunter_limit"));
	new spitters = GetConVarInt(FindConVar("z_versus_spitter_limit"));
	new jockeys = GetConVarInt(FindConVar("z_versus_jockey_limit"));
	new chargers = GetConVarInt(FindConVar("z_versus_charger_limit"));

	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i) && GetClientTeam(i) == 3)
		{
			new SI = GetEntProp(i, Prop_Send, "m_zombieClass");
			switch (SI)
			{
				case 1: smokers--;
				case 2: boomers--;
				case 3: hunters--;
				case 4: spitters--;
				case 5: jockeys--;
				case 6: chargers--;
			}
		}
	}

	while (smokers > 0) { smokers--; PushArrayCell(array, _:SI_Smoker); }
	while (boomers > 0) { boomers--; PushArrayCell(array, _:SI_Boomer); }
	while (hunters > 0) { hunters--; PushArrayCell(array, _:SI_Hunter); }
	while (spitters > 0) { spitters--; PushArrayCell(array, _:SI_Spitter); }
	while (jockeys > 0) { jockeys--; PushArrayCell(array, _:SI_Jockey); }
	while (chargers > 0) { chargers--; PushArrayCell(array, _:SI_Charger); }
}

bool:IsTank(client) { return GetEntProp(client, Prop_Send, "m_zombieClass") == _:SI_Tank; }

bool:IsValidClient(client) { 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client)) return false;
    return (IsClientInGame(client)); 
}

