#pragma semicolon 1
#pragma newdecls required

#define __IN_L4D2UTIL__

#define ROUNDS_MODULE_ENABLE 1
#define TANKS_MODULE_ENABLE 0

#include <l4d2util>

#if ROUNDS_MODULE_ENABLE
#include "l4d2util/rounds.sp"
#endif

#if TANKS_MODULE_ENABLE
#include "l4d2util/tanks.sp"
#endif

public const char sLibraryName[] = "l4d2util";

public Plugin myinfo =
{
	name = "L4D2 Utilities",
	author = "Confogl Team",
	description = "Useful functions and forwards for Left 4 Dead 2 SourceMod plugins",
	version = "2.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
#if ROUNDS_MODULE_ENABLE
	HookEvent("round_start", L4D2Util_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", L4D2Util_RoundEnd, EventHookMode_PostNoCopy);
#endif

#if TANKS_MODULE_ENABLE
	L4D2Util_Tanks_Init();
	
	HookEvent("tank_spawn", L4D2Util_TankSpawn);
	HookEvent("player_death", L4D2Util_PlayerDeath);
#endif
}

public void OnMapEnd()
{
#if ROUNDS_MODULE_ENABLE
	L4D2Util_Rounds_OnMapEnd();
#endif
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
#if ROUNDS_MODULE_ENABLE
	L4D2Util_Rounds_CreateForwards();
#endif

#if TANKS_MODULE_ENABLE
	L4D2Util_Tanks_CreateForwards();
#endif

	RegPluginLibrary(sLibraryName);
	return APLRes_Success;
}

public void L4D2Util_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
#if ROUNDS_MODULE_ENABLE
	L4D2Util_Rounds_OnRoundStart();
#endif

#if TANKS_MODULE_ENABLE
	L4D2Util_Tanks_OnRoundStart();
#endif
}

public void L4D2Util_RoundEnd(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
#if ROUNDS_MODULE_ENABLE
	L4D2Util_Rounds_OnRoundEnd();
#endif
}

#if TANKS_MODULE_ENABLE
public void L4D2Util_TankSpawn(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iTank = GetClientOfUserId(hEvent.GetInt("userid"));

	L4D2Util_Tanks_TankSpawn(iTank);
}

public void L4D2Util_PlayerDeath(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iPlayer = GetClientOfUserId(hEvent.GetInt("userid"));

	L4D2Util_Tanks_PlayerDeath(iPlayer);
}
#endif
