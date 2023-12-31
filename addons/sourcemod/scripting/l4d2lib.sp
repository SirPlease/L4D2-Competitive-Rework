#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <confogl>
#define REQUIRE_PLUGIN
#include <sdktools>

// A value of 0 will remove the module from the plugin assembly
#define MODULE_ROUNDS 0
#define MODULE_MAPINFO 1
#define MODULE_TANKS 1
#define MODULE_SURVIVORS 0

// Modules
#if MODULE_ROUNDS
	#include "l4d2lib/rounds.sp"
#endif

#if MODULE_MAPINFO
	bool g_bConfogl = false;

	#include "l4d2lib/mapinfo.sp"
#endif

#if MODULE_TANKS
	#include "l4d2lib/tanks.sp"
#endif

#if MODULE_SURVIVORS
	#include "l4d2lib/survivors.sp"
#endif

public Plugin myinfo =
{
	name = "L4D2Lib",
	author = "Confogl Team",
	description = "Useful natives and fowards for L4D2 Plugins",
	version = "3.2.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
#if MODULE_ROUNDS || MODULE_TANKS || MODULE_SURVIVORS
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
#endif

#if MODULE_ROUNDS
	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
#endif

#if MODULE_TANKS
	HookEvent("tank_spawn", TankSpawn_Event, EventHookMode_Post);
	HookEvent("item_pickup", ItemPickup_Event, EventHookMode_Post);
#endif

#if MODULE_TANKS || MODULE_SURVIVORS
	HookEvent("player_death", PlayerDeath_Event, EventHookMode_Post);
#endif

#if MODULE_SURVIVORS || MODULE_MAPINFO
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Post);
#endif

#if MODULE_SURVIVORS
	HookEvent("player_spawn", PlayerSpawn_Event, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", PlayerBotReplace_Event, EventHookMode_PostNoCopy);
	HookEvent("bot_player_replace", BotPlayerReplace_Event, EventHookMode_PostNoCopy);
	HookEvent("defibrillator_used", DefibrillatorUsed_Event, EventHookMode_PostNoCopy);
	HookEvent("player_team", PlayerTeam_Event, EventHookMode_PostNoCopy);
#endif

#if MODULE_MAPINFO
	MapInfo_Init();
#endif
}

#if MODULE_MAPINFO
public void OnPluginEnd()
{
	MapInfo_OnPluginEnd();
}
#endif

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	/* Plugin Native Declarations */
#if MODULE_ROUNDS
	Rounds_AskPluginLoad2();
#endif

#if MODULE_MAPINFO
	MapInfo_AskPluginLoad2();
#endif

#if MODULE_TANKS
	Tanks_AskPluginLoad2();
#endif

#if MODULE_SURVIVORS
	Survivors_AskPluginLoad2();
#endif

	/* Register our library */
	RegPluginLibrary("l4d2lib");
	return APLRes_Success;
}

#if MODULE_MAPINFO
public void OnLibraryAdded(const char[] sPluginName)
{
	if (strcmp(sPluginName, "confogl", true) == 0) {
		g_bConfogl = true;

		MapInfo_Reload();
	}
}

public void OnLibraryRemoved(const char[] sPluginName)
{
	if (strcmp(sPluginName, "confogl", true) == 0) {
		g_bConfogl = false;

		MapInfo_Reload();
	}
}
#endif

#if MODULE_MAPINFO || MODULE_TANKS
public void OnMapStart()
{
#if MODULE_MAPINFO
	MapInfo_OnMapStart_Update();
#endif

#if MODULE_TANKS
	Tanks_OnMapStart();
#endif
}
#endif

#if MODULE_MAPINFO || MODULE_ROUNDS
public void OnMapEnd()
{
#if MODULE_MAPINFO
	MapInfo_OnMapEnd_Update();
#endif

#if MODULE_ROUNDS
	Rounds_OnMapEnd_Update();
#endif
}
#endif

/* Events */
#if MODULE_ROUNDS
public void RoundEnd_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Rounds_OnRoundEnd_Update();
}
#endif

#if MODULE_ROUNDS || MODULE_TANKS || MODULE_SURVIVORS
public void RoundStart_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
#if MODULE_ROUNDS
	Rounds_OnRoundStart_Update();
#endif

#if MODULE_TANKS
	Tanks_RoundStart();
#endif

#if MODULE_SURVIVORS
	Survivors_RebuildArray();
#endif
}
#endif

#if MODULE_TANKS
public void TankSpawn_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Tanks_TankSpawn(hEvent);
}

public void ItemPickup_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Tanks_ItemPickup(hEvent);
}
#endif

#if MODULE_TANKS || MODULE_SURVIVORS
public void PlayerDeath_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
#if MODULE_TANKS
	Tanks_PlayerDeath(hEvent);
#endif

#if MODULE_SURVIVORS
	Survivors_RebuildArray();
#endif
}
#endif

#if MODULE_SURVIVORS || MODULE_MAPINFO
public void PlayerDisconnect_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
#if MODULE_SURVIVORS
	Survivors_RebuildArray();
#endif

#if MODULE_MAPINFO
	MapInfo_PlayerDisconnect_Event(hEvent);
#endif
}
#endif

#if MODULE_SURVIVORS
public void PlayerSpawn_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Survivors_RebuildArray();
}

public void PlayerBotReplace_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Survivors_RebuildArray();
}

public void BotPlayerReplace_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Survivors_RebuildArray();
}

public void DefibrillatorUsed_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Survivors_RebuildArray();
}

public void PlayerTeam_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Survivors_RebuildArray_Delay();
}
#endif

