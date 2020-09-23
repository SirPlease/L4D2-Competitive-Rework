#pragma semicolon 1

/* This is the "safe zone" around the tank spawn */
#define MIN_BOSS_VARIANCE (0.2)
#define DEBUG 0

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <l4d2lib>

public Plugin:myinfo =
{
	name = "Tank and no Witch ifier!",
	author = "CanadaRox, Sir",
	version = "1",
	description = "Sets a tank spawn and removes witch spawn point on every map"
};

new Handle:g_hVsBossBuffer;
new Handle:g_hVsBossFlowMax;
new Handle:g_hVsBossFlowMin;
new Handle:hStaticTankMaps;

public OnPluginStart()
{
	g_hVsBossBuffer = FindConVar("versus_boss_buffer");
	g_hVsBossFlowMax = FindConVar("versus_boss_flow_max");
	g_hVsBossFlowMin = FindConVar("versus_boss_flow_min");

	hStaticTankMaps = CreateTrie();

#if !DEBUG
	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);
#endif

	RegServerCmd("static_tank_map", StaticTank_Command);
	RegServerCmd("reset_static_maps", Reset_Command);

#if DEBUG
	RegConsoleCmd("sm_doshit", DoShit_Cmd);
#endif
}

public Action:L4D_OnSpawnWitch(const Float:vector[3], const Float:qangle[3])
{
	return Plugin_Handled;
}

public Action:L4D_OnSpawnWitchBride(const Float:vector[3], const Float:qangle[3])
{
	return Plugin_Handled;
}

public Action:StaticTank_Command(args)
{
	decl String:mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	SetTrieValue(hStaticTankMaps, mapname, true);
#if DEBUG
	PrintToChatAll("Added %s", mapname);
#endif
}

public Action:Reset_Command(args)
{
	ClearTrie(hStaticTankMaps);
}

#if !DEBUG
public RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.5, AdjustBossFlow);
}
#endif

#if DEBUG
public Action:DoShit_Cmd(client, args)
{
	PrintToChatAll("Doing shit!");
	CreateTimer(0.5, AdjustBossFlow);
}
#endif

public Action:AdjustBossFlow(Handle:timer)
{
	if (InSecondHalfOfRound()) return;

	decl String:sCurMap[64];
	decl dummy;
	GetCurrentMap(sCurMap, sizeof(sCurMap));

	new Float:fCvarMinFlow = GetConVarFloat(g_hVsBossFlowMin);
	new Float:fCvarMaxFlow = GetConVarFloat(g_hVsBossFlowMax);

	new Float:fTankFlow = -1.0;

	if (!GetTrieValue(hStaticTankMaps, sCurMap, dummy))
	{
#if DEBUG
		PrintToChatAll("Not static tank map");
#endif
		new Float:fMinBanFlow = L4D2_GetMapValueInt("tank_ban_flow_min", -1) / 100.0;
		new Float:fMaxBanFlow = L4D2_GetMapValueInt("tank_ban_flow_max", -1) / 100.0;
		new Float:fBanRange = fMaxBanFlow - fMinBanFlow;
		if (fMinBanFlow > 0 && fMinBanFlow < fCvarMinFlow)
		{
			fBanRange -= (fCvarMinFlow - fMinBanFlow);
		}

		fTankFlow = GetRandomFloat(fCvarMinFlow, fCvarMaxFlow - fBanRange);
#if DEBUG
		PrintToChatAll("fTankFlow_pre: %f", fTankFlow);
#endif
		if (fTankFlow > fMinBanFlow)
		{
			fTankFlow += fBanRange;
		}
#if DEBUG
		PrintToChatAll("fTankFlow_post: %f", fTankFlow);
#endif
		L4D2Direct_SetVSTankToSpawnThisRound(0, true);
		L4D2Direct_SetVSTankToSpawnThisRound(1, true);
		L4D2Direct_SetVSTankFlowPercent(0, fTankFlow);
		L4D2Direct_SetVSTankFlowPercent(1, fTankFlow);
	}
	else
	{
		L4D2Direct_SetVSTankToSpawnThisRound(0, false);
		L4D2Direct_SetVSTankToSpawnThisRound(1, false);
#if DEBUG
		PrintToChatAll("Static tank map");
#endif
	}

	L4D2Direct_SetVSWitchToSpawnThisRound(0, false);
	L4D2Direct_SetVSWitchToSpawnThisRound(1, false);
}

stock Float:GetTankFlow(round)
{
	return L4D2Direct_GetVSTankFlowPercent(round) - Float:GetConVarInt(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance();
}

stock InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound");
}