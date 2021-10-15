#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <confogl>
#define REQUIRE_PLUGIN
#include <sdktools>

bool
	g_bConfogl = false;

// Modules
#include "l4d2lib/rounds.inc"
#include "l4d2lib/mapinfo.inc"
#include "l4d2lib/tanks.inc"
#include "l4d2lib/survivors.inc"

#define LIBRARYNAME "l4d2lib"

public Plugin myinfo =
{
	name = "L4D2Lib",
	author = "Confogl Team",
	description = "Useful natives and fowards for L4D2 Plugins",
	version = "2.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", TankSpawn_Event);
	HookEvent("item_pickup", ItemPickup_Event);
	HookEvent("player_death", PlayerDeath_Event);
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", PlayerSpawn_Event, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", PlayerBotReplace_Event, EventHookMode_PostNoCopy);
	HookEvent("bot_player_replace", BotPlayerReplace_Event, EventHookMode_PostNoCopy);
	HookEvent("defibrillator_used", DefibrillatorUsed_Event, EventHookMode_PostNoCopy);
	HookEvent("player_team", PlayerTeam_Event, EventHookMode_PostNoCopy);

	MapInfo_Init();
}

public void OnPluginEnd()
{
	MapInfo_OnPluginEnd();
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	/* Plugin Native Declarations */
	CreateNative("L4D2_GetCurrentRound", _native_GetCurrentRound);
	CreateNative("L4D2_CurrentlyInRound", _native_CurrentlyInRound);
	CreateNative("L4D2_GetSurvivorCount", _native_GetSurvivorCount);
	CreateNative("L4D2_GetSurvivorOfIndex", _native_GetSurvivorOfIndex);
	CreateNative("L4D2_IsMapDataAvailable", _native_IsMapDataAvailable);
	CreateNative("L4D2_IsEntityInSaferoom", _native_IsEntityInSaferoom);
	CreateNative("L4D2_GetMapStartOrigin", _native_GetMapStartOrigin);
	CreateNative("L4D2_GetMapEndOrigin", _native_GetMapEndOrigin);
	CreateNative("L4D2_GetMapStartDistance", _native_GetMapStartDist);
	CreateNative("L4D2_GetMapStartExtraDistance", _native_GetMapStartExtraDist);
	CreateNative("L4D2_GetMapEndDistance", _native_GetMapEndDist);
	CreateNative("L4D2_GetMapValueInt", _native_GetMapValueInt);
	CreateNative("L4D2_GetMapValueFloat", _native_GetMapValueFloat);
	CreateNative("L4D2_GetMapValueVector", _native_GetMapValueVector);
	CreateNative("L4D2_GetMapValueString", _native_GetMapValueString);
	CreateNative("L4D2_CopyMapSubsection", _native_CopyMapSubsection);

	/* Plugin Forward Declarations */
	g_hFwdRoundStart = CreateGlobalForward("L4D2_OnRealRoundStart", ET_Ignore, Param_Cell);
	g_hFwdRoundEnd = CreateGlobalForward("L4D2_OnRealRoundEnd", ET_Ignore, Param_Cell);
	g_hFwdFirstTankSpawn = CreateGlobalForward("L4D2_OnTankFirstSpawn", ET_Ignore, Param_Cell);
	g_hFwdTankPassControl = CreateGlobalForward("L4D2_OnTankPassControl", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hFwdTankDeath = CreateGlobalForward("L4D2_OnTankDeath", ET_Ignore, Param_Cell);

	/* Register our library */
	RegPluginLibrary(LIBRARYNAME);

	return APLRes_Success;
}

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

public void OnMapStart()
{
	MapInfo_OnMapStart_Update();
	Tanks_OnMapStart();
}

public void OnMapEnd()
{
	MapInfo_OnMapEnd_Update();
	Rounds_OnMapEnd_Update();
}

/* Events */
public void RoundEnd_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Rounds_OnRoundEnd_Update();
}

public void RoundStart_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Rounds_OnRoundStart_Update();
	Tanks_RoundStart();
	Survivors_RebuildArray();
}

public void TankSpawn_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Tanks_TankSpawn(hEvent);
}

public void ItemPickup_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Tanks_ItemPickup(hEvent);
}

public void PlayerDeath_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Tanks_PlayerDeath(hEvent);
	Survivors_RebuildArray();
}

public void PlayerSpawn_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Survivors_RebuildArray();
}

public void PlayerDisconnect_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	Survivors_RebuildArray();
	MapInfo_PlayerDisconnect_Event(hEvent);
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

/* Plugin Natives */
public int _native_GetCurrentRound(Handle hPlugin, int iNumParams)
{
	return GetCurrentRound();
}

public int _native_CurrentlyInRound(Handle hPlugin, int iNumParams)
{
	return CurrentlyInRound();
}

public int _native_GetSurvivorCount(Handle hPlugin, int iNumParams)
{
	return GetSurvivorCount();
}

public int _native_GetSurvivorOfIndex(Handle hPlugin, int iNumParams)
{
	return GetSurvivorOfIndex(GetNativeCell(1));
}

public int _native_IsMapDataAvailable(Handle hPlugin, int iNumParams)
{
	return IsMapDataAvailable();
}

public int _native_IsEntityInSaferoom(Handle hPlugin, int iNumParams)
{
	return IsEntityInSaferoom(GetNativeCell(1));
}

public int _native_GetMapStartOrigin(Handle hPlugin, int iNumParams)
{
	float fOrigin[3];
	GetNativeArray(1, fOrigin, sizeof(fOrigin));
	
	GetMapStartOrigin(fOrigin);
	SetNativeArray(1, fOrigin, sizeof(fOrigin));
}

public int _native_GetMapEndOrigin(Handle hPlugin, int iNumParams)
{
	float fOrigin[3];
	GetNativeArray(1, fOrigin, sizeof(fOrigin));
	
	GetMapEndOrigin(fOrigin);
	SetNativeArray(1, fOrigin, sizeof(fOrigin));
}

public int _native_GetMapStartDist(Handle hPlugin, int iNumParams)
{
	return view_as<int>(GetMapStartDist());
}

public int _native_GetMapStartExtraDist(Handle hPlugin, int iNumParams)
{
	return view_as<int>(GetMapStartExtraDist());
}

public int _native_GetMapEndDist(Handle hPlugin, int iNumParams)
{
	return view_as<int>(GetMapEndDist());
}

public int _native_GetMapValueInt(Handle hPlugin, int iNumParams)
{
	int iLen;
	GetNativeStringLength(1, iLen);
	
	int iNewLen = iLen + 1;
	char[] sKey = new char[iNewLen];
	GetNativeString(1, sKey, iNewLen);

	int iDefVal = GetNativeCell(2);
	return GetMapValueInt(sKey, iDefVal);
}

public int _native_GetMapValueFloat(Handle hPlugin, int iNumParams)
{
	int iLen;
	GetNativeStringLength(1, iLen);
	
	int iNewLen = iLen + 1;
	char[] sKey = new char[iNewLen];
	GetNativeString(1, sKey, iNewLen);

	float fDefVal = GetNativeCell(2);

	return view_as<int>(GetMapValueFloat(sKey, fDefVal));
}

public int _native_GetMapValueVector(Handle hPlugin, int iNumParams)
{
	int iLen;
	GetNativeStringLength(1, iLen);
	
	int iNewLen = iLen + 1;
	char[] sKey = new char[iNewLen];
	GetNativeString(1, sKey, iNewLen);
	
	float fDefval[3], fValue[3];
	GetNativeArray(3, fDefval, 3);

	GetMapValueVector(sKey, fValue, fDefval);

	SetNativeArray(2, fValue, 3);
	return 1;
}

public int _native_GetMapValueString(Handle hPlugin, int iNumParams)
{
	int iLen;
	GetNativeStringLength(1, iLen);
	
	int iNewLen = iLen + 1;
	char[] sKey = new char[iNewLen];
	GetNativeString(1, sKey, iNewLen);

	GetNativeStringLength(4, iLen);
	
	iNewLen = iLen + 1;
	char[] sDefVal = new char[iNewLen];
	GetNativeString(4, sDefVal, iNewLen);

	iLen = GetNativeCell(3);
	iNewLen = iLen + 1;
	char[] sBuf = new char[iNewLen];
	
	GetMapValueString(sKey, sBuf, iNewLen, sDefVal);

	SetNativeString(2, sBuf, iNewLen);
	return 1;
}

public int _native_CopyMapSubsection(Handle hPlugin, int iNumParams)
{
	int iLen;
	GetNativeStringLength(2, iLen);

	int iNewLen = iLen + 1;
	char[] sKey = new char[iNewLen];
	GetNativeString(2, sKey, iNewLen);

	KeyValues hKv = GetNativeCell(1);

	CopyMapSubsection(hKv, sKey);

	return 1;
}
