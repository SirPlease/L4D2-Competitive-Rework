#pragma semicolon 1

#include <sourcemod>
#include "rounds.inc"
#include "mapinfo.inc"
#include "tanks.inc"
#include "survivors.inc"

#define LIBRARYNAME "l4d2lib"

new bool:g_bConfogl = false;

public Plugin:myinfo = 
{
	name = "L4D2Lib",
	author = "Confogl Team",
	description = "Useful natives and fowards for L4D2 Plugins",
	version = "1.0.1",
	url = "https://bitbucket.org/ProdigySim/misc-sourcemod-plugins"
}

public OnPluginStart()
{
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", TankSpawn_Event);
	HookEvent("item_pickup", ItemPickup_Event);
	HookEvent("player_death", PlayerDeath_Event);
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("player_spawn" , PlayerSpawn_Event, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect" , PlayerDisconnect_Event, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace" , PlayerBotReplace_Event, EventHookMode_PostNoCopy);
	HookEvent("bot_player_replace" , BotPlayerReplace_Event, EventHookMode_PostNoCopy);
	HookEvent("defibrillator_used" , DefibrillatorUsed_Event, EventHookMode_PostNoCopy);
	HookEvent("player_team" , PlayerTeam_Event, EventHookMode_PostNoCopy);
}

public OnPluginEnd()
{
	MapInfo_OnPluginEnd();

}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
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
	hFwdRoundStart = CreateGlobalForward("L4D2_OnRealRoundStart", ET_Ignore, Param_Cell);
	hFwdRoundEnd = CreateGlobalForward("L4D2_OnRealRoundEnd", ET_Ignore, Param_Cell);
	hFwdFirstTankSpawn = CreateGlobalForward("L4D2_OnTankFirstSpawn", ET_Ignore, Param_Cell);
	hFwdTankPassControl = CreateGlobalForward("L4D2_OnTankPassControl", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	hFwdTankDeath = CreateGlobalForward("L4D2_OnTankDeath", ET_Ignore, Param_Cell);
	
	/* Register our library */
	RegPluginLibrary(LIBRARYNAME);
	
	return APLRes_Success;
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "confogl"))
	{
		MapInfo_Init();
		g_bConfogl = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "confogl"))
	{
		g_bConfogl = false;
	}
}

public OnMapStart()
{
	if (g_bConfogl)
	{
		MapInfo_OnMapStart_Update();
		Tanks_OnMapStart();
	}
}

public OnMapEnd()
{
	MapInfo_OnMapEnd_Update();
	Rounds_OnMapEnd_Update();
}

/* Events */
public Action:RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	Rounds_OnRoundEnd_Update();
}

public Action:RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	Rounds_OnRoundStart_Update();
	Tanks_RoundStart();
	Survivors_RebuildArray();
}

public Action:TankSpawn_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	Tanks_TankSpawn(event);
}

public Action:ItemPickup_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	Tanks_ItemPickup(event);
}

public Action:PlayerDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	Tanks_PlayerDeath(event);
	Survivors_RebuildArray();
}

public Action:PlayerSpawn_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	Survivors_RebuildArray();
}

public Action:PlayerDisconnect_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	Survivors_RebuildArray();
	MapInfo_PlayerDisconnect_Event(event);
}

public Action:PlayerBotReplace_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	Survivors_RebuildArray();
}

public Action:BotPlayerReplace_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	Survivors_RebuildArray();
}

public Action:DefibrillatorUsed_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	Survivors_RebuildArray();
}

public Action:PlayerTeam_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	Survivors_RebuildArray_Delay();
}


/* Plugin Natives */
public _native_GetCurrentRound(Handle:plugin, numParams)
{
	return GetCurrentRound();
}

public _native_CurrentlyInRound(Handle:plugin, numParams)
{
	return _:CurrentlyInRound();
}

public _native_GetSurvivorCount(Handle:plugin, numParams)
{
	return GetSurvivorCount();
}

public _native_GetSurvivorOfIndex(Handle:plugins, numParams)
{
	return GetSurvivorOfIndex(GetNativeCell(1));
}

public _native_IsMapDataAvailable(Handle:plugin, numParams)
{
	return IsMapDataAvailable();
}

public _native_IsEntityInSaferoom(Handle:plugin, numParams)
{
	return _:IsEntityInSaferoom(GetNativeCell(1));
}

public _native_GetMapStartOrigin(Handle:plugin, numParams)
{
	decl Float:origin[3];
	GetNativeArray(1, origin, 3);
	GetMapStartOrigin(origin);
	SetNativeArray(1, origin, 3);
}

public _native_GetMapEndOrigin(Handle:plugin, numParams)
{
	decl Float:origin[3];
	GetNativeArray(1, origin, 3);
	GetMapEndOrigin(origin);
	SetNativeArray(1, origin, 3);
}

public _native_GetMapStartDist(Handle:plugin, numParams)
{
	return _:GetMapStartDist();
}

public _native_GetMapStartExtraDist(Handle:plugin, numParams)
{
	return _:GetMapStartExtraDist();
}

public _native_GetMapEndDist(Handle:plugin, numParams)
{
	return _:GetMapEndDist();
}

public _native_GetMapValueInt(Handle:plugin, numParams)
{
	if (!g_bConfogl) return 0;

	decl len, defval;
	
	GetNativeStringLength(1, len);
	new String:key[len+1];
	GetNativeString(1, key, len+1);
	
	defval = GetNativeCell(2);
	
	return GetMapValueInt(key, defval);
}
public _native_GetMapValueFloat(Handle:plugin, numParams)
{
	if (!g_bConfogl) return 0;

	decl len, Float:defval;
	
	GetNativeStringLength(1, len);
	new String:key[len+1];
	GetNativeString(1, key, len+1);
	
	defval = GetNativeCell(2);
	
	return _:GetMapValueFloat(key, defval);
}

public _native_GetMapValueVector(Handle:plugin, numParams)
{
	if (!g_bConfogl) return;

	decl len, Float:defval[3], Float:value[3];
	
	GetNativeStringLength(1, len);
	new String:key[len+1];
	GetNativeString(1, key, len+1);
	
	GetNativeArray(3, defval, 3);
	
	GetMapValueVector(key, value, defval);
	
	SetNativeArray(2, value, 3);
}

public _native_GetMapValueString(Handle:plugin, numParams)
{
	if (!g_bConfogl) return;

	decl len;
	GetNativeStringLength(1, len);
	new String:key[len+1];
	GetNativeString(1, key, len+1);
	
	GetNativeStringLength(4, len);
	new String:defval[len+1];
	GetNativeString(4, defval, len+1);
	
	len = GetNativeCell(3);
	new String:buf[len+1];
	
	GetMapValueString(key, buf, len, defval);
	
	SetNativeString(2, buf, len);
}

public _native_CopyMapSubsection(Handle:plugin, numParams)
{
	if (!g_bConfogl) return;

	decl len, Handle:kv;
	GetNativeStringLength(2, len);
	new String:key[len+1];
	GetNativeString(2, key, len+1);
	
	kv = GetNativeCell(1);
	
	CopyMapSubsection(kv, key);
}