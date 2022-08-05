#pragma semicolon 1
#pragma newdecls required

#define DEBUG 0
#define DEBUG_PROFILING 0

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <l4d2lib>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util_rounds>

#if DEBUG_PROFILING
#include <profiler>
#endif

public Plugin myinfo = {
	name = "Tank and Witch ifier!",
	author = "CanadaRox, Sir, devilesk, Derpduck, Forgetest",
	version = "2.4.2",
	description = "Sets a tank spawn and has the option to remove the witch spawn point on every map",
	url = "https://github.com/devilesk/rl4d2l-plugins"
};

// ======================================
// Variables
// ======================================

ConVar
	g_hVsBossBuffer,
	g_hVsBossFlowMax,
	g_hVsBossFlowMin;

StringMap
	hStaticTankMaps,
	hStaticWitchMaps;

ConVar
	g_hCvarDebug = null,
	g_hCvarTankCanSpawn = null,
	g_hCvarWitchCanSpawn = null,
	g_hCvarWitchAvoidTank = null;

char
	g_sCurrentMap[64];

int 
	g_iCvarMinFlow,
	g_iCvarMaxFlow;

ArrayList
	hBannedTankFlows,
	hValidTankFlows,
	hBannedWitchFlows,
	hValidWitchFlows;

// ======================================
// Plugin Setup
// ======================================

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("IsStaticTankMap", Native_IsStaticTankMap);
	CreateNative("IsStaticWitchMap", Native_IsStaticWitchMap);
	CreateNative("IsTankPercentValid", Native_IsTankPercentValid);
	CreateNative("IsWitchPercentValid", Native_IsWitchPercentValid);
	CreateNative("IsWitchPercentBlockedForTank", Native_IsWitchPercentBlockedForTank);
	CreateNative("SetTankPercent", Native_SetTankPercent);
	CreateNative("SetWitchPercent", Native_SetWitchPercent);

	RegPluginLibrary("witch_and_tankifier");
	return APLRes_Success;
}

public void OnPluginStart() {
	g_hCvarDebug = CreateConVar("sm_tank_witch_debug", "0", "Tank and Witch ifier debug mode", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_hCvarTankCanSpawn = CreateConVar("sm_tank_can_spawn", "1", "Tank and Witch ifier enables tanks to spawn", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarWitchCanSpawn = CreateConVar("sm_witch_can_spawn", "1", "Tank and Witch ifier enables witches to spawn", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarWitchAvoidTank = CreateConVar("sm_witch_avoid_tank_spawn", "20", "Minimum flow amount witches should avoid tank spawns by, by half the value given on either side of the tank spawn", FCVAR_NOTIFY, true, 0.0, true, 100.0);

	g_hVsBossBuffer = FindConVar("versus_boss_buffer");
	g_hVsBossFlowMax = FindConVar("versus_boss_flow_max");
	g_hVsBossFlowMin = FindConVar("versus_boss_flow_min");

	hStaticTankMaps = new StringMap();
	hStaticWitchMaps = new StringMap();

	hBannedTankFlows = new ArrayList(2);
	hValidTankFlows = new ArrayList(2);
	hBannedWitchFlows = new ArrayList(2);
	hValidWitchFlows = new ArrayList(2);

	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);

	RegServerCmd("static_tank_map", StaticTank_Command);
	RegServerCmd("static_witch_map", StaticWitch_Command);
	RegServerCmd("reset_static_maps", Reset_Command);

	RegAdminCmd("sm_tank_witch_debug_info", Info_Cmd, ADMFLAG_KICK, "Dump spawn state info");
	
#if DEBUG
	RegConsoleCmd("sm_tank_witch_debug_test", Test_Cmd);
#endif
#if DEBUG_PROFILING
	RegConsoleCmd("sm_tank_witch_debug_profiler", Profiler_Cmd);
#endif
}

// ======================================
// Boss Spawn Control
// ======================================

public Action L4D_OnSpawnTank(const float vecPos[3], const float vecAng[3])
{
	return g_hCvarTankCanSpawn.BoolValue ? Plugin_Continue : Plugin_Handled;
}

public Action L4D_OnSpawnWitch(const float vecPos[3], const float vecAng[3])
{
	return g_hCvarWitchCanSpawn.BoolValue ? Plugin_Continue : Plugin_Handled;
}

public Action L4D2_OnSpawnWitchBride(const float vecPos[3], const float vecAng[3])
{
	return g_hCvarWitchCanSpawn.BoolValue ? Plugin_Continue : Plugin_Handled;
}

// ======================================
// Current Map Cache
// ======================================

public void OnMapStart() {
	GetCurrentMapLower(g_sCurrentMap, sizeof g_sCurrentMap);
}

// ======================================
// Flow Handling
// ======================================

void RoundStartEvent(Event event, const char[] name, bool dontBroadcast) {
	CreateTimer(0.5, AdjustBossFlow, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action AdjustBossFlow(Handle timer) {
	if (InSecondHalfOfRound()) {
		return Plugin_Stop;
	}
	
	g_iCvarMinFlow = RoundToCeil(g_hVsBossFlowMin.FloatValue * 100);
	g_iCvarMaxFlow = RoundToFloor(g_hVsBossFlowMax.FloatValue * 100);
	
	// mapinfo override
	g_iCvarMinFlow = L4D2_GetMapValueInt("versus_boss_flow_min", g_iCvarMinFlow);
	g_iCvarMaxFlow = L4D2_GetMapValueInt("versus_boss_flow_max", g_iCvarMaxFlow);
	PrintDebug("[AdjustBossFlow] flow: (%i, %i).", g_iCvarMinFlow, g_iCvarMaxFlow);
	
	ProcessTankFlow();
	ProcessWitchFlow();
	
	PrintDebugInfoDump();
	return Plugin_Stop;
}

void ProcessTankFlow(bool bInit = true) {
	if (!IsStaticTankMap(g_sCurrentMap) && g_hCvarTankCanSpawn.BoolValue) {
		PrintDebug("[AdjustBossFlow] Not static tank map. Flow tank enabled.");
		
		if (bInit) {
			hValidTankFlows.Clear();
			hBannedTankFlows.Clear();
			
			SharedBannedFlows(hBannedTankFlows, "tank_ban_flow");
			MergeIntervals(hBannedTankFlows, hBannedTankFlows);
		}
		
		MakeComplementaryIntervals(hBannedTankFlows, hValidTankFlows);
		
		// check each array index to see if it is within a ban range
		int iValidSpawnTotal = hValidTankFlows.Length;
		if (iValidSpawnTotal == 0) {
			SetTankPercent(0);
			PrintDebug("[AdjustBossFlow] Ban range covers entire flow range. Flow tank disabled.");
		}
		else {
			int iTankFlow = GetRandomIntervalNum(hValidTankFlows);
			SetTankPercent(iTankFlow);
			PrintDebug("[AdjustBossFlow] iTankFlow: %i. iValidSpawnTotal: %i", iTankFlow, iValidSpawnTotal);
		}
	}
	else {
		SetTankPercent(0);
		PrintDebug("[AdjustBossFlow] Static tank map. Flow tank disabled.");
	}
}

void ProcessWitchFlow(bool bInit = true) {
	if (!IsStaticWitchMap(g_sCurrentMap) && g_hCvarWitchCanSpawn.BoolValue) {
		PrintDebug("[AdjustBossFlow] Not static witch map. Flow witch enabled.");
		
		if (bInit) {
			hValidWitchFlows.Clear();
			hBannedWitchFlows.Clear();
			
			SharedBannedFlows(hBannedWitchFlows, "witch_ban_flow");
			MergeIntervals(hBannedWitchFlows, hBannedWitchFlows);
		}
		
		// Support for "ignoreBlock"
		ArrayList aTemp = hBannedWitchFlows.Clone();
		
		// Avoid within a range of tank percent
		int interval[2];
		if (GetTankAvoidInterval(interval) && IsValidInterval(interval)) {
			aTemp.PushArray(interval);
			PrintDebug("[AdjustBossFlow] tank avoid (%i, %i)", interval[0], interval[1]);
		}
		
		MergeIntervals(aTemp, aTemp);
		MakeComplementaryIntervals(aTemp, hValidWitchFlows);
		
		delete aTemp;
		
		// check each array index to see if it is within a ban range
		int iValidSpawnTotal = hValidWitchFlows.Length;
		if (iValidSpawnTotal == 0) {
			SetWitchPercent(0);
			PrintDebug("[AdjustBossFlow] Ban range covers entire flow range. Flow witch disabled.");
		}
		else {
			int iWitchFlow = GetRandomIntervalNum(hValidWitchFlows);
			SetWitchPercent(iWitchFlow);
			PrintDebug("[AdjustBossFlow] iWitchFlow: %i. iValidSpawnTotal: %i", iWitchFlow, iValidSpawnTotal);
		}
	}
	else {
		SetWitchPercent(0);
		PrintDebug("[AdjustBossFlow] Static witch map or witch not enabled. Flow witch disabled.");
	}
}

void SharedBannedFlows(ArrayList hBannedFlows, const char[] sMapinfoKey) {
	int interval[2];
	interval[0] = 0, interval[1] = g_iCvarMinFlow - 1;
	if (IsValidInterval(interval)) hBannedFlows.PushArray(interval);
	interval[0] = g_iCvarMaxFlow + 1, interval[1] = 100;
	if (IsValidInterval(interval)) hBannedFlows.PushArray(interval);
	
	KeyValues kv = new KeyValues(sMapinfoKey);
	L4D2_CopyMapSubsection(kv, sMapinfoKey);
	
	if (kv.GotoFirstSubKey()) {
		do {
			interval[0] = kv.GetNum("min", -1);
			interval[1] = kv.GetNum("max", -1);
			PrintDebug("[AdjustBossFlow] ban (%i, %i).", interval[0], interval[1]);
			if (IsValidInterval(interval)) hBannedFlows.PushArray(interval);
		} while (kv.GotoNextKey());
	}
	delete kv;
}

// ======================================
// Dynamic Adjust Witch
// ======================================

// Adjust the witch percent when the tank percent is changed.
void DynamicAdjustWitchFlow() {
	int percent = GetWitchPercent();
	if (IsWitchPercentBlockedForTank(percent)) {
		ProcessWitchFlow(false);
	}
}

// ======================================
// Tank Avoid Flow
// ======================================

bool GetTankAvoidInterval(int interval[2]) {
	int iAvoid = g_hCvarWitchAvoidTank.IntValue;
	if (iAvoid == 0) {
		return false;
	}
	
	int percent = GetTankPercent();
	if (percent == 0) {
		return false;
	}
	
	interval[0] = percent - iAvoid / 2;
	if (interval[0] < g_iCvarMinFlow) interval[0] = g_iCvarMinFlow;
	interval[1] = percent + iAvoid / 2;
	if (interval[1] > g_iCvarMaxFlow) interval[1] = g_iCvarMaxFlow;
	
	return true;
}

// ======================================
// Interval Methods
//   - based on ArrayList and int[2]
//   - all intervals are closed within [0, 100]
// ======================================

/**
 * Validate the interval and check within a valid range.
 *
 * @param interval		Interval input.
 *
 * @return bool
 */
bool IsValidInterval(int interval[2]) {
	return interval[1] >= interval[0] && interval[0] > -1 && interval[1] <= 100;
}

/**
 * Merge intervals from source and load to dest.
 * i.e. Input [0, 30] and [25, 45] -> Output [0, 45]
 * NOTE: The input ArrayList can be the same as the output ArrayList.
 *
 * @param src			Intervals input.
 * @param dest			Merged intervals output.
 *
 * @noreturn
 */
void MergeIntervals(ArrayList src, ArrayList dest) {
	if (src.Length < 2) return;
	
	ArrayList intervals = src.Clone();
	intervals.Sort(Sort_Ascending, Sort_Integer);
	
	dest.Clear();
	
	int current[2];
	intervals.GetArray(0, current);
	dest.PushArray(current);
	
	int intv_size = intervals.Length;
	for (int i = 1; i < intv_size; ++i) {
		intervals.GetArray(i, current);
		
		int back_index = dest.Length - 1;
		int back_R = dest.Get(back_index, 1);
		
		if (back_R < current[0] - 1) { // not connect-able
			#if DEBUG && !DEBUG_PROFILING
				PrintDebug("\x05[MergeIntv] Try merging [%i, %i] with [%i, %i] but not connect-able", dest.Get(back_index, 0), back_R, current[0], current[1]);
			#endif
			dest.PushArray(current);
		} else {
			#if DEBUG && !DEBUG_PROFILING
				PrintDebug("\x05[MergeIntv] Merging [%i, %i] with [%i, %i]", dest.Get(back_index, 0), back_R, current[0], current[1]);
			#endif
			back_R = (back_R > current[1] ? back_R : current[1]); // override the right value with maximum
			dest.Set(back_index, back_R, 1);
		}
	}
	
	delete intervals;
}

/**
 * Fill the gaps of intervals from source and load to dest.
 * NOTE: The input ArrayList can be the same as the output ArrayList.
 *
 * @param src			Intervals input.
 * @param dest			Complementary intervals output.
 *
 * @noreturn
 */
void MakeComplementaryIntervals(ArrayList src, ArrayList dest) {
	int intv_size = src.Length;
	if (intv_size < 2) return;
	
	ArrayList intervals = src.Clone();
	
	dest.Clear();
	
	int intv[2];
	
	// left border
	intv[0] = 0;
	intv[1] = intervals.Get(0, 0) - 1;
	#if DEBUG && !DEBUG_PROFILING
		PrintDebug("\x05[Complementary] left border [%i, %i] valid = %s", intv[0], intv[1], IsValidInterval(intv) ? "true" : "false");
	#endif
	if (IsValidInterval(intv)) dest.PushArray(intv);
	
	// right border
	intv[0] = intervals.Get(intv_size - 1, 1) + 1;
	intv[1] = 100;
	#if DEBUG && !DEBUG_PROFILING
		PrintDebug("\x05[Complementary] right border [%i, %i] valid = %s", intv[0], intv[1], IsValidInterval(intv) ? "true" : "false");
	#endif
	if (IsValidInterval(intv)) dest.PushArray(intv);
	
	// between intervals
	for (int i = 1; i < intv_size; ++i) {
		intv[0] = intervals.Get(i-1, 1) + 1;
		intv[1] = intervals.Get(i, 0) - 1;
		#if DEBUG && !DEBUG_PROFILING
			PrintDebug("\x05[Complementary] between intervals [%i, %i] valid = %s", intv[0], intv[1], IsValidInterval(intv) ? "true" : "false");
		#endif
		if (IsValidInterval(intv)) dest.PushArray(intv);
	}
	
	delete intervals;
}

int GetRandomIntervalNum(ArrayList aList) {
	int total_length = 0, size = aList.Length;
	int[] arrLength = new int[size];
	for (int i = 0; i < size; ++i) {
		arrLength[i] = aList.Get(i, 1) - aList.Get(i, 0) + 1;
		total_length += arrLength[i];
	}
	
	int random = Math_GetRandomInt(0, total_length-1);
	
	#if DEBUG && !DEBUG_PROFILING
		PrintDebug("GetRandomIntervalNum - random: %i, total_length: %i", random, total_length);
	#endif
	
	for (int i = 0; i < size; ++i) {
		if (random < arrLength[i]) {
			return aList.Get(i, 0) + random;
		} else {
			random -= arrLength[i];
		}
	}
	return 0;
}

// ======================================
// Boss Spawn Scheme Commands
// ======================================

Action StaticTank_Command(int args) {
	char mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	StrToLower(mapname);
	hStaticTankMaps.SetValue(mapname, true);
#if DEBUG
	PrintDebug("[StaticTank_Command] Added: %s", mapname);
#endif
	return Plugin_Handled;
}

Action StaticWitch_Command(int args) {
	char mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	StrToLower(mapname);
	hStaticWitchMaps.SetValue(mapname, true);
#if DEBUG
	PrintDebug("[StaticWitch_Command] Added: %s", mapname);
#endif
	return Plugin_Handled;
}

Action Reset_Command(int args) {
	hStaticTankMaps.Clear();
	hStaticWitchMaps.Clear();
	return Plugin_Handled;
}

// ======================================
// Debug Commands
// ======================================

Action Info_Cmd(int client, int args) {
	PrintDebugInfoDump();
	return Plugin_Handled;
}

#if DEBUG
Action Test_Cmd(int client, int args) {
	PrintDebug("[Test_Cmd] Starting AdjustBossFlow timer...");
	CreateTimer(0.5, AdjustBossFlow, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}
#endif

#if DEBUG_PROFILING
Action Profiler_Cmd(int client, int args) {
	if (args != 1) {
		ReplyToCommand(client, "[SM] Usage: sm_tank_witch_debug_profiler <times>");
		return Plugin_Handled;
	}
	char buffer[32];
	GetCmdArg(1, buffer, sizeof buffer);
	
	int times = StringToInt(buffer);
	FormatEx(buffer, sizeof buffer, "%i time%s", times, times > 1 ? "s" : "");
	PrintDebug("[Profiler_Cmd] Starting AdjustBossFlow profiler (%s)...", buffer);
	
	bool temp = g_hCvarDebug.BoolValue;
	g_hCvarDebug.BoolValue = false;
	
	Profiler profiler = new Profiler();
	
	profiler.Start();
	for (int i = 0; i < times; ++i) {
		AdjustBossFlow(null);
	}
	profiler.Stop();
	
	g_hCvarDebug.BoolValue = temp;
	PrintDebug("[Profiler_Cmd] Spent %f seconds (%s)...", profiler.Time, buffer);
	
	delete profiler;
	return Plugin_Handled;
}
#endif

// ======================================
// Natives
// ======================================

any Native_IsStaticTankMap(Handle plugin, int numParams) {
	int bytes = 0;
	
	char mapname[64];
	GetNativeString(1, mapname, sizeof(mapname), bytes);
	
	if (bytes) {
		StrToLower(mapname);
		return IsStaticTankMap(mapname);
	} else {
		return IsStaticTankMap(g_sCurrentMap);
	}
}

any Native_IsStaticWitchMap(Handle plugin, int numParams) {
	int bytes = 0;
	
	char mapname[64];
	GetNativeString(1, mapname, sizeof(mapname), bytes);
	
	if (bytes) {
		StrToLower(mapname);
		return IsStaticWitchMap(mapname);
	} else {
		return IsStaticWitchMap(g_sCurrentMap);
	}
}

any Native_IsTankPercentValid(Handle plugin, int numParams) {
	int flow = GetNativeCell(1);
	return IsTankPercentValid(flow);
}

any Native_IsWitchPercentValid(Handle plugin, int numParams) {
	int flow = GetNativeCell(1);
	if (!IsWitchPercentValid(flow)) {
		return false;
	}
	
	bool ignoreBlock = GetNativeCell(2);
	if (!ignoreBlock) {
		return !IsWitchPercentBlockedForTank(flow);
	}
		
	return true;
}

any Native_IsWitchPercentBlockedForTank(Handle plugin, int numParams) {
	int flow = GetNativeCell(1);
	return IsWitchPercentBlockedForTank(flow);
}

any Native_SetTankPercent(Handle plugin, int numParams) {
	int flow = GetNativeCell(1);
	if (!IsTankPercentValid(flow)) return false;
	SetTankPercent(flow);
	DynamicAdjustWitchFlow();
	return true;
}

any Native_SetWitchPercent(Handle plugin, int numParams) {
	int flow = GetNativeCell(1);
	if (!IsWitchPercentValid(flow)) return false;
	SetWitchPercent(flow);
	return true;
}

// ======================================
// Helper Functions
// ======================================

bool IsStaticTankMap(const char[] map) {
	bool dummy;
	return hStaticTankMaps.GetValue(map, dummy);
}

bool IsStaticWitchMap(const char[] map) {
	bool dummy;
	return hStaticWitchMaps.GetValue(map, dummy);
}

bool IsTankPercentValid(int flow) {
	if (flow == 0) {
		return true;
	}
	int size = hBannedTankFlows.Length;
	if (!size) {
		return true;
	}
	for (int i = 0; i < size; ++i) {
		if (flow <= hBannedTankFlows.Get(i, 1)) {
			return flow < hBannedTankFlows.Get(i, 0);
		}
	}
	return true;
}

bool IsWitchPercentValid(int flow) {
	if (flow == 0) {
		return true;
	}
	int size = hBannedWitchFlows.Length;
	if (!size) {
		return true;
	}
	for (int i = 0; i < size; ++i) {
		if (flow <= hBannedWitchFlows.Get(i, 1)) {
			return flow < hBannedWitchFlows.Get(i, 0);
		}
	}
	return false;
}

bool IsWitchPercentBlockedForTank(int flow) {
	int interval[2];
	if (GetTankAvoidInterval(interval) && IsValidInterval(interval)) {
		return interval[0] <= flow && flow <= interval[1];
	}
	return false;
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

// ======================================
// Stock Functions
// ======================================

stock int GetTankPercent() {
	return RoundFloat(L4D2Direct_GetVSTankFlowPercent(0) * 100.0);
}

stock int GetWitchPercent() {
	return RoundFloat(L4D2Direct_GetVSWitchFlowPercent(0) * 100.0);
}

stock float GetTankProgressPercent(int round) {
	return L4D2Direct_GetVSTankFlowPercent(round) - GetBossBufferPercent();
}

stock float GetWitchProgressPercent(int round) {
	return L4D2Direct_GetVSWitchFlowPercent(round) - GetBossBufferPercent();
}

stock float GetBossBufferPercent() {
	return g_hVsBossBuffer.FloatValue / L4D2Direct_GetMapMaxFlowDistance();
}

stock void PrintDebugInfoDump() {
	if (g_hCvarDebug.BoolValue) {
		for (int i = 0; i < 2; ++i) {
			PrintDebug("[Round %i] tank enabled: %i, tank flow: %f, display: %f, witch enabled: %i, witch flow: %f, display: %f",
					i + 1,
					L4D2Direct_GetVSTankToSpawnThisRound(i),
					L4D2Direct_GetVSTankFlowPercent(i),
					GetTankProgressPercent(i),
					L4D2Direct_GetVSWitchToSpawnThisRound(i),
					L4D2Direct_GetVSWitchFlowPercent(i),
					GetWitchProgressPercent(i));
		}
		
		char buffer[256] = "Valid Tank Intervals: ";
		
		int size = hValidTankFlows.Length;
		for (int i = 0; i < size; ++i) {
			char sInterval[16];
			FormatEx(sInterval, 16, "[%i, %i]", hValidTankFlows.Get(i, 0), hValidTankFlows.Get(i, 1));
			StrCat(buffer, 256, sInterval);
			if (i != size - 1) StrCat(buffer, 256, ", ");
		}
		PrintDebug(buffer);
		
		strcopy(buffer, 256, "Valid Witch Intervals: ");
		
		size = hValidWitchFlows.Length;
		for (int i = 0; i < size; ++i) {
			char sInterval[16];
			FormatEx(sInterval, 16, "[%i, %i]", hValidWitchFlows.Get(i, 0), hValidWitchFlows.Get(i, 1));
			StrCat(buffer, 256, sInterval);
			if (i != size - 1) StrCat(buffer, 256, ", ");
		}
		PrintDebug(buffer);
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
