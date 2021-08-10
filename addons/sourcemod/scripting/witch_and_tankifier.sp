#pragma semicolon 1

#define DEBUG 0

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <confogl>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util_rounds>

public Plugin myinfo = {
	name = "Tank and Witch ifier!",
	author = "CanadaRox, Sir, devilesk, Derpduck",
	version = "2.3.1",
	description = "Sets a tank spawn and has the option to remove the witch spawn point on every map",
	url = "https://github.com/devilesk/rl4d2l-plugins"
};

ConVar
	g_hVsBossBuffer,
	g_hVsBossFlowMax,
	g_hVsBossFlowMin;
	
StringMap
	hStaticTankMaps,
	hStaticWitchMaps;
	
ConVar
	g_hCvarDebug = null,
	g_hCvarWitchCanSpawn = null,
	g_hCvarWitchAvoidTank = null;
	
char
	g_sCurrentMap[64];
	
ArrayList
	hValidTankFlows,
	hValidWitchFlows;

enum struct Interval
{
	int l;
	int r;
	bool border;
	bool operate_reset;
	
	void SetDefault(int l = 0, int r = 0) {
		static int dft_l = 0;
		static int dft_r = 0;
		
		if (dft_l == 0 && dft_r == 0) {
			if (l == 0 && r == 0) return;
			
			dft_l = l, dft_r = r;
		}
		
		this.l = dft_l, this.r = dft_r;
	}
	
	bool Valid() {
		return (this.r - this.l) > 0;
	}
	
	/*int Size() {
		if (!this.Valid()) return 0;
		return this.border ? (this.r+1 - this.l+1) : (this.r - this.l);
	}*/
	
	bool Within(int num) {
		return this.border ? (this.l <= num <= this.r) : (this.l < num < this.r);
	}
	
	void ExtractToNumList(ArrayList aList) {
		int i = this.border ? this.l : this.l+1;
		for (; this.border ? (i <= this.r) : (i < this.r); ++i) {
			aList.Push(i);
		}
		if (this.operate_reset) this.SetDefault();
	}
	
	void RemoveNumsFromList(ArrayList aList) {
		for (int i = 0; i < aList.Length; ++i) {
			if (this.Within(aList.Get(i))) {
				aList.Erase(i--);
			}
		}
		if (this.operate_reset) this.SetDefault();
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("IsStaticTankMap", Native_IsStaticTankMap);
	CreateNative("IsStaticWitchMap", Native_IsStaticWitchMap);
	CreateNative("IsTankPercentValid", Native_IsTankPercentValid);
	CreateNative("IsWitchPercentValid", Native_IsWitchPercentValid);
	CreateNative("SetTankPercent", Native_SetTankPercent);
	CreateNative("SetWitchPercent", Native_SetWitchPercent);
	RegPluginLibrary("witch_and_tankifier");
}

public void OnPluginStart() {
	g_hCvarDebug = CreateConVar("sm_tank_witch_debug", "0", "Tank and Witch ifier debug mode", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_hCvarWitchCanSpawn = CreateConVar("sm_witch_can_spawn", "1", "Tank and Witch ifier enables witches to spawn", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarWitchAvoidTank = CreateConVar("sm_witch_avoid_tank_spawn", "20", "Minimum flow amount witches should avoid tank spawns by, by half the value given on either side of the tank spawn", FCVAR_NOTIFY, true, 0.0, true, 100.0);

	g_hVsBossBuffer = FindConVar("versus_boss_buffer");
	g_hVsBossFlowMax = FindConVar("versus_boss_flow_max");
	g_hVsBossFlowMin = FindConVar("versus_boss_flow_min");

	hStaticTankMaps = new StringMap();
	hStaticWitchMaps = new StringMap();

	hValidTankFlows = new ArrayList();
	hValidWitchFlows = new ArrayList();

	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);

	RegServerCmd("static_tank_map", StaticTank_Command);
	RegServerCmd("static_witch_map", StaticWitch_Command);
	RegServerCmd("reset_static_maps", Reset_Command);

	RegAdminCmd("sm_tank_witch_debug_info", Info_Cmd, ADMFLAG_KICK, "Dump spawn state info");
	
#if DEBUG
	RegConsoleCmd("sm_tank_witch_debug_test", Test_Cmd);
#endif
}

public Action StaticTank_Command(int args) {
	char mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	StrToLower(mapname);
	hStaticTankMaps.SetValue(mapname, true);
#if DEBUG
	PrintDebug("[StaticTank_Command] Added: %s", mapname);
#endif
}

public Action StaticWitch_Command(int args) {
	char mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	StrToLower(mapname);
	hStaticWitchMaps.SetValue(mapname, true);
#if DEBUG
	PrintDebug("[StaticWitch_Command] Added: %s", mapname);
#endif
}

public Action Reset_Command(int args) {
	hStaticTankMaps.Clear();
	hStaticWitchMaps.Clear();
}

public Action Info_Cmd(int client, int args) {
	PrintDebugInfoDump();
}
#if DEBUG
public Action Test_Cmd(int client, int args) {
	PrintDebug("[Test_Cmd] Starting AdjustBossFlow timer...");
	CreateTimer(0.5, AdjustBossFlow, _, TIMER_FLAG_NO_MAPCHANGE);
}
#endif

public void OnMapStart() {
	GetCurrentMapLower(g_sCurrentMap, sizeof g_sCurrentMap);
}

public void RoundStartEvent(Event event, const char[] name, bool dontBroadcast) {
	CreateTimer(0.5, AdjustBossFlow, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action AdjustBossFlow(Handle timer) {
	if (InSecondHalfOfRound()) return;

	hValidTankFlows.Clear();
	hValidWitchFlows.Clear();
	
	int iCvarMinFlow = RoundToCeil(g_hVsBossFlowMin.FloatValue * 100);
	int iCvarMaxFlow = RoundToFloor(g_hVsBossFlowMax.FloatValue * 100);
	
	// mapinfo override
	iCvarMinFlow = LGO_GetMapValueInt("versus_boss_flow_min", iCvarMinFlow);
	iCvarMaxFlow = LGO_GetMapValueInt("versus_boss_flow_max", iCvarMaxFlow);
	PrintDebug("[AdjustBossFlow] flow: (%i, %i).", iCvarMinFlow, iCvarMaxFlow);
	
	Interval eIntv;
	eIntv.border = true;
	eIntv.operate_reset = true;
	eIntv.SetDefault(0, 100);
	
	if (!IsStaticTankMap(g_sCurrentMap)) {
		PrintDebug("[AdjustBossFlow] Not static tank map. Flow tank enabled.");
		
		eIntv.l = iCvarMinFlow;
		eIntv.r = iCvarMaxFlow;
		if (eIntv.Valid()) eIntv.ExtractToNumList(hValidTankFlows);
		
		KeyValues kv = new KeyValues("tank_ban_flow");
		LGO_CopyMapSubsection(kv, "tank_ban_flow");
		
		if (kv.GotoFirstSubKey()) {
			do {
				eIntv.l = kv.GetNum("min", -1);
				eIntv.r = kv.GetNum("max", -1);
				PrintDebug("[AdjustBossFlow] ban (%i, %i).", eIntv.l, eIntv.r);
				if (eIntv.Valid()) eIntv.RemoveNumsFromList(hValidTankFlows);
			} while (kv.GotoNextKey());
		}
		delete kv;
		
		// check each array index to see if it is within a ban range
		int iValidSpawnTotal = hValidTankFlows.Length;
		if (iValidSpawnTotal == 0) {
			SetTankPercent(0);
			PrintDebug("[AdjustBossFlow] Ban range covers entire flow range. Flow tank disabled.");
		}
		else {
			int iTankFlow = hValidTankFlows.Get(Math_GetRandomInt(1, iValidSpawnTotal) - 1);
			PrintDebug("[AdjustBossFlow] iTankFlow: %i. iValidSpawnTotal: %i", iTankFlow, iValidSpawnTotal);
			SetTankPercent(iTankFlow);
		}
	}
	else {
		SetTankPercent(0);
		PrintDebug("[AdjustBossFlow] Static tank map. Flow tank disabled.");
	}
	
	bool canWitchSpawn = GetConVarBool(g_hCvarWitchCanSpawn);
	if (!IsStaticWitchMap(g_sCurrentMap) && canWitchSpawn) {
		PrintDebug("[AdjustBossFlow] Not static witch map. Flow witch enabled.");

		eIntv.l = iCvarMinFlow;
		eIntv.r = iCvarMaxFlow;
		if (eIntv.Valid()) eIntv.ExtractToNumList(hValidWitchFlows);
		
		KeyValues kv = new KeyValues("witch_ban_flow");
		LGO_CopyMapSubsection(kv, "witch_ban_flow");
		
		if (kv.GotoFirstSubKey()) {
			do {
				eIntv.l = kv.GetNum("min", -1);
				eIntv.r = kv.GetNum("max", -1);
				PrintDebug("[AdjustBossFlow] ban %i (%i, %i).", eIntv.l, eIntv.r);
				if (eIntv.Valid()) eIntv.RemoveNumsFromList(hValidTankFlows);
			} while (kv.GotoNextKey());
		}
		delete kv;
		
		eIntv.l = RoundToFloor((L4D2Direct_GetVSTankFlowPercent(0) * 100) - (g_hCvarWitchAvoidTank.FloatValue / 2));
		eIntv.r = RoundToCeil((L4D2Direct_GetVSTankFlowPercent(0) * 100) + (g_hCvarWitchAvoidTank.FloatValue / 2));
		PrintDebug("[AdjustBossFlow] tank avoid (%i, %i)", eIntv.l, eIntv.r);
		if (eIntv.Valid()) eIntv.RemoveNumsFromList(hValidWitchFlows);
		
		// check each array index to see if it is within a ban range
		int iValidSpawnTotal = hValidWitchFlows.Length;
		if (iValidSpawnTotal == 0) {
			SetWitchPercent(0);
			PrintDebug("[AdjustBossFlow] Ban range covers entire flow range. Flow witch disabled.");
		}
		else {
			int iWitchFlow = hValidWitchFlows.Get(Math_GetRandomInt(1, iValidSpawnTotal) - 1);
			PrintDebug("[AdjustBossFlow] iWitchFlow: %i. iValidSpawnTotal: %i", iWitchFlow, iValidSpawnTotal);
			SetWitchPercent(iWitchFlow);
		}
	}
	else {
		SetWitchPercent(0);
		PrintDebug("[AdjustBossFlow] Static witch map or witch not enabled. Flow witch disabled.");
	}
	
	PrintDebugInfoDump();
}

public any Native_IsStaticTankMap(Handle plugin, int numParams) {
	int bytes = 0;
	
	char mapname[64];
	GetNativeString(1, mapname, sizeof mapname, bytes);
	
	if (bytes) {
		StrToLower(mapname);
		return IsStaticTankMap(mapname);
	} else {
		return IsStaticTankMap(g_sCurrentMap);
	}
}

public any Native_IsStaticWitchMap(Handle plugin, int numParams) {
	int bytes = 0;
	
	char mapname[64];
	GetNativeString(1, mapname, sizeof mapname, bytes);
	
	if (bytes) {
		StrToLower(mapname);
		return IsStaticWitchMap(mapname);
	} else {
		return IsStaticWitchMap(g_sCurrentMap);
	}
}

public any Native_IsTankPercentValid(Handle plugin, int numParams) {
	int flow = GetNativeCell(1);
	return IsTankPercentValid(flow);
}

public any Native_IsWitchPercentValid(Handle plugin, int numParams) {
	int flow = GetNativeCell(1);
	return IsWitchPercentValid(flow);
}

public any Native_SetTankPercent(Handle plugin, int numParams) {
	int flow = GetNativeCell(1);
	if (!IsTankPercentValid(flow)) return false;
	SetTankPercent(flow);
	return true;
}

public any Native_SetWitchPercent(Handle plugin, int numParams) {
	int flow = GetNativeCell(1);
	if (!IsWitchPercentValid(flow)) return false;
	SetWitchPercent(flow);
	return true;
}

bool IsStaticTankMap(const char[] map) {
	bool dummy;
	return hStaticWitchMaps.GetValue(map, dummy);
}

bool IsStaticWitchMap(const char[] map) {
	bool dummy;
	return hStaticWitchMaps.GetValue(map, dummy);
}

bool IsTankPercentValid(int flow) {
	return flow == 0 || hValidTankFlows.FindValue(flow) != -1;
}

bool IsWitchPercentValid(int flow){
	return flow == 0 || hValidWitchFlows.FindValue(flow) != -1;
}

void SetTankPercent(int percent) {
	if (percent == 0) {
		L4D2Direct_SetVSTankFlowPercent(0, 0.0);
		L4D2Direct_SetVSTankFlowPercent(1, 0.0);
		L4D2Direct_SetVSTankToSpawnThisRound(0, false);
		L4D2Direct_SetVSTankToSpawnThisRound(1, false);
	} else {
		float p_newPercent = (float(percent)/100);
		L4D2Direct_SetVSTankFlowPercent(0, p_newPercent);
		L4D2Direct_SetVSTankFlowPercent(1, p_newPercent);
		L4D2Direct_SetVSTankToSpawnThisRound(0, true);
		L4D2Direct_SetVSTankToSpawnThisRound(1, true);
	}
}

void SetWitchPercent(int percent) {
	if (percent == 0) {
		L4D2Direct_SetVSWitchFlowPercent(0, 0.0);
		L4D2Direct_SetVSWitchFlowPercent(1, 0.0);
		L4D2Direct_SetVSWitchToSpawnThisRound(0, false);
		L4D2Direct_SetVSWitchToSpawnThisRound(1, false);
	} else {
		float p_newPercent = (float(percent)/100);
		L4D2Direct_SetVSWitchFlowPercent(0, p_newPercent);
		L4D2Direct_SetVSWitchFlowPercent(1, p_newPercent);
		L4D2Direct_SetVSWitchToSpawnThisRound(0, true);
		L4D2Direct_SetVSWitchToSpawnThisRound(1, true);
	}
}

stock float GetTankProgressFlow(int round) {
	return L4D2Direct_GetVSTankFlowPercent(round) - GetBossBuffer();
}

stock float GetWitchProgressFlow(int round) {
	return L4D2Direct_GetVSWitchFlowPercent(round) - GetBossBuffer();
}

stock float GetBossBuffer() {
	return g_hVsBossBuffer.FloatValue / L4D2Direct_GetMapMaxFlowDistance();
}

stock void PrintDebugInfoDump() {
	if (g_hCvarDebug.BoolValue) {
		PrintDebug("[Round 1] tank enabled: %i, tank flow: %f, display: %f, witch enabled: %i, witch flow: %f, display: %f", L4D2Direct_GetVSTankToSpawnThisRound(0), L4D2Direct_GetVSTankFlowPercent(0), GetTankProgressFlow(0), L4D2Direct_GetVSWitchToSpawnThisRound(0), L4D2Direct_GetVSWitchFlowPercent(0), GetWitchProgressFlow(0));
		PrintDebug("[Round 2] tank enabled: %i, tank flow: %f, display: %f, witch enabled: %i, witch flow: %f, display: %f", L4D2Direct_GetVSTankToSpawnThisRound(1), L4D2Direct_GetVSTankFlowPercent(1), GetTankProgressFlow(1), L4D2Direct_GetVSWitchToSpawnThisRound(1), L4D2Direct_GetVSWitchFlowPercent(1), GetWitchProgressFlow(0));
	}
}

stock void PrintDebug(const char[] Message, any ...) {
	if (g_hCvarDebug.BoolValue) {
		char DebugBuff[256];
		VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
		LogMessage(DebugBuff);
#if DEBUG
		PrintToChatAll(DebugBuff);
#endif
	}
}

#define SIZE_OF_INT		 2147483647 // without 0
stock int Math_GetRandomInt(int min, int max)
{
	int random = GetURandomInt();

	if (random == 0) {
		random++;
	}

	return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}

stock void StrToLower(char[] arg) {
	int length = strlen(arg);
	for (int i = 0; i < length; i++) {
		arg[i] = CharToLower(arg[i]);
	}
}

stock int GetCurrentMapLower(char[] buffer, int buflen) {
	int iBytesWritten = GetCurrentMap(buffer, buflen);
	StrToLower(buffer);
	return iBytesWritten;
}
