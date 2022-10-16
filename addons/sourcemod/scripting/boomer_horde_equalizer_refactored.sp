/*

======= Version 1.0 - 1.1
------> by Visor & Jacob. 
- Fix boomer hordes being different sizes based on wandering common infected.

======= Version 1.2 - 1.4
------> by A1m`
- Added error output.
- Fixed offset.
- Windows support.

======= Version 1.5
------> by Forgetest
- Replace code_patcher with Sourcescramble.

======= Version 1.6
------> by Sir
------> Thanks to Spoon for his l4d2_boomer_horde_control plugin, giving me the idea to support non-static numbers per biled Survivor. (And copy pasta explanation)
------> Thanks to Alan for reviewing the code, testing and input.
- Refactored the plugin to allow for more control over the amount of horde spawned and its behaviour.
- Added support for non-Boomer related L4D_OnSpawnITMob events (Boomer Bile & Custom stuff).
- With this plugin I highly recommend tweaking the "z_notice_it_range" it ConVar, as wandering common will still pile in on top of this within a certain range. (Default 1500)

* ----------------------------------------------------------------------------------------------------------------
*
*	Please note, the amount of specified horde will spawn once the boomed survivor count reaches that amount. 
*	Meaning, if you want a TOTAL of 15 common to spawn when two survivors are boomed you could use this:
*
*	boomer_horde_amount 	1 	5 		-		Spawn 5 common when 1 survivor gets boomed
*	boomer_horde_amount 	2 	10 		-		Spawn 10 common when 2nd survivor gets boomed (Total of 15 spawned.)
*
*
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>
#include <left4dhooks>

#define GAMEDATA "boomer_horde_equalizer"
#define KEY_WANDERERSCONDITION "WanderersCondition"

// Debuggin'?
// #define _DEBUG

ConVar
	g_hPatchEnable,
	g_hMobMaxSize,
	g_hOldBehaviourEvents;

MemoryPatch
	g_hPatch_WanderersCondition = null;

int 
	BoomHordeEvent[32],
	BoomedSurvivorCount,
	iMobSize;

bool
	bOldBehaviourEvents, 
	bBiledSurvivor[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Boomer Horde Equalizer (Refactored)",
	author = "Visor, Jacob, A1m`, Sir",
	version = "1.6",
	description = "Fixes boomer hordes being different sizes based on wandering commons (1.5) as well as adding zombies to the queue rather than relying on max_mob_size",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();

	// Events
	HookEvent("player_no_longer_it", Event_PlayerBoomedExpired);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("bot_player_replace", Event_BotPlayerReplace);

	// ConVars.
	g_hPatchEnable           = CreateConVar("boomer_horde_equalizer", "1", "Fix boomer hordes being different sizes based on wandering commons. (1 - enable, 0 - disable)", _, true, 0.0, true, 1.0);
	g_hOldBehaviourEvents    = CreateConVar("boomer_horde_equalizer_events_default", "1", "Use default boomer behaviour during event hordes? - 1:Yes - 0:Override", _, true, 0.0, true, 1.0);
	g_hMobMaxSize            = FindConVar("z_mob_spawn_max_size");

	// Server Commands.
	RegServerCmd("boomer_horde_amount", ServerCmdSetBoomHorde, "Usage: boomer_horde_amount <amount of boomed survivors> <amount of horde to spawn>");

	// Initialize
	iMobSize                = g_hMobMaxSize.IntValue;
	bOldBehaviourEvents     = g_hOldBehaviourEvents.BoolValue;

	g_hPatchEnable.AddChangeHook(Cvars_Changed);
	g_hMobMaxSize.AddChangeHook(Cvars_Changed);
	g_hOldBehaviourEvents.AddChangeHook(Cvars_Changed);

	// Go & Hook.
	CheckPatch(g_hPatchEnable.BoolValue);
}

public void OnPluginEnd()
{
	CheckPatch(false);
}

/* =================================================================================
									CONVARS
================================================================================= */
public void Cvars_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	CheckPatch(g_hPatchEnable.BoolValue);
	iMobSize               = g_hMobMaxSize.IntValue;
	bOldBehaviourEvents    = g_hOldBehaviourEvents.BoolValue;
}

/* =================================================================================
								SERVER COMMANDS
================================================================================= */
public Action ServerCmdSetBoomHorde(int args)
{
	// Check to make sure the arguments are set up right.
	if (args != 2) 
	  return Plugin_Continue;

	// Get the amount of Survivors boomed.
	char RequiredSurvivorsBoomed[32];
	GetCmdArg(1, RequiredSurvivorsBoomed, sizeof(RequiredSurvivorsBoomed));
	StripQuotes(RequiredSurvivorsBoomed);
	
	// Get the amount of horde to spawn as a result.
	char ResultHordeSize[32];
	GetCmdArg(2, ResultHordeSize, sizeof(ResultHordeSize));
	StripQuotes(ResultHordeSize);
		
	// Store it in an array!
	BoomHordeEvent[StringToInt(RequiredSurvivorsBoomed, 10)] = StringToInt(ResultHordeSize, 10);
	return Plugin_Continue;
}


/* =================================================================================
									EVENTS
================================================================================= */
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// Just in case.
	BoomedSurvivorCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		bBiledSurvivor[i] = false;
	}
}

public void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));

	if (bBiledSurvivor[player])
	{
		int bot = GetClientOfUserId(event.GetInt("bot"));
		bBiledSurvivor[player] = false;
		bBiledSurvivor[bot] = true;

		#if defined _DEBUG
			PrintToChatAll("%N passed on bBiledSurvivor to %N", player, bot);
		#endif
	}
}

public void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));

	if (bBiledSurvivor[bot])
	{
		int player = GetClientOfUserId(event.GetInt("player"));
		bBiledSurvivor[bot] = false;
		bBiledSurvivor[player] = true;

		#if defined _DEBUG
			PrintToChatAll("%N passed on bBiledSurvivor to %N", bot, player);
		#endif
	}
}

public void Event_PlayerBoomedExpired(Event event, const char[] name, bool dontBroadcast)
{
	// This event only triggers on players (Bile bomb on SI or Boomer bile on Survivors)
	// Will only have to check if the player is a Survivor.
	int nolongerit = GetClientOfUserId(event.GetInt("userid"));

	if (bBiledSurvivor[nolongerit]) 
	{
		BoomedSurvivorCount--;
		bBiledSurvivor[nolongerit] = false;

		#if defined _DEBUG
			PrintToChatAll("%N no longer it (BoomedSurvivorCount: %i)", nolongerit, BoomedSurvivorCount);
		#endif
	}
}

public Action L4D_OnSpawnITMob(int &iAmount)
{
	// Rather than spawning common through this, we add them to the pending queue.
	// This allows us to go past the z_common_limit
	// Keep in mind that the default value of wandering common is 20 and will be added to the outcome of the calculation if they are within the default range of 3000 units.
	// Which happens in the following two cases: 
	// - Players Biled * Horde per Player size exceeds z_common_limit
	// - Pulled Wanderers + (Players Biled * Horde per Player size) exceeds z_common_limit

	// Set default Horde to the z_mob_spawn_max_size convar.
	int HordeToQueue = iMobSize;

	// An additional check for Infinite Hordes (events)
	// We'll use "old-school" boomer_horde_equalizer method in this case, unless plugin user prefers the new method (not recommended)
	if (bOldBehaviourEvents && IsInfiniteHordeActive()) 
	{
		iAmount = HordeToQueue;
		return Plugin_Changed;
	}

	// We do not know yet whether a Survivor was biled.
	// We'll use this for client storage.
	int clientPassed;

	for (int i = 1; i <= MaxClients; i++) 
	{
		if (bBiledSurvivor[i] || !IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;

		if (IsBoomed(i))
		{
			// We 'break' here because this will trigger every time someone gets biled (for the first time) by either a boomer
			// or bilebomb (also triggers on groundhit for Bilebomb)
			// This way we don't increase BoomedSurvivorCount unless an actual Survivor is biled.
			BoomedSurvivorCount++;
			bBiledSurvivor[i] = true;
			clientPassed = i;

			#if defined _DEBUG
				PrintToChatAll("%N boomed (Total: %d)", i, BoomedSurvivorCount);
			#endif

			break;
		}
	}

	// Actual Survivor bile that triggered this?
	if (clientPassed > 0)
	{
		// Did we specify the amount of common for this amount of Survivors biled?
		if (BoomHordeEvent[BoomedSurvivorCount] > 0)
		{
			HordeToQueue = BoomHordeEvent[BoomedSurvivorCount];

			#if defined _DEBUG
				PrintToChatAll("BoomHordeEvent[BoomedSurvivorCount] : %i", BoomHordeEvent[BoomedSurvivorCount]);
			#endif
		}
	}

	// This will fire in cases where it wasn't a Survivor that got biled.
	// We'll use "old-school" boomer_horde_equalizer method in this case, unless plugin user prefers the new method (most DEFINITELY NOT recommended)
	else {

		#if defined _DEBUG
			PrintToChatAll("Uncovered Bile Event");
		#endif

		iAmount = HordeToQueue;
		return Plugin_Changed;
	}

	L4D2Direct_SetPendingMobCount(L4D2Direct_GetPendingMobCount() + HordeToQueue);
	return Plugin_Handled;
}

/* =================================================================================
									STOCKS
================================================================================= */
void InitGameData()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);

	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}
	
	g_hPatch_WanderersCondition = MemoryPatch.CreateFromConf(hGamedata, KEY_WANDERERSCONDITION);
	if (g_hPatch_WanderersCondition == null || !g_hPatch_WanderersCondition.Validate()) {
		SetFailState("Failed to validate MemoryPatch \"" ... KEY_WANDERERSCONDITION ... "\"");
	}
	
	delete hGamedata;
}

void CheckPatch(bool bIsPatch)
{
	static bool bIsPatched = false;
	if (bIsPatch) {
		if (bIsPatched) {
			PrintToServer("[" ... GAMEDATA ... "] Plugin already enabled");
			return;
		}
		if (!g_hPatch_WanderersCondition.Enable()) {
			SetFailState("[" ... GAMEDATA ... "] Failed to enable patch '" ... KEY_WANDERERSCONDITION ... "'.");
		}
		PrintToServer("[" ... GAMEDATA ... "] Successfully patched '" ... KEY_WANDERERSCONDITION ... "'."); //GAMEDATA == plugin name
		bIsPatched = true;
	} else {
		if (!bIsPatched) {
			PrintToServer("[" ... GAMEDATA ... "] Plugin already disabled");
			return;
		}
		g_hPatch_WanderersCondition.Disable();
		bIsPatched = false;
	}
}

bool IsBoomed(int client)
{
	return ((GetEntPropFloat(client, Prop_Send, "m_vomitStart") + 0.01) > GetGameTime());
}

bool IsInfiniteHordeActive()
{
	int countdown = GetHordeCountdown();
	return (countdown > -1 && countdown <= 10);
}

int GetHordeCountdown()
{
	return (CTimer_HasStarted(L4D2Direct_GetMobSpawnTimer())) ? RoundFloat(CTimer_GetRemainingTime(L4D2Direct_GetMobSpawnTimer())) : -1;
}