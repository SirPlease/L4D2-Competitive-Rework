#pragma semicolon 1
#pragma newdecls required

#define DEBUG 1
#define PLUGIN_VERSION "2.1"
#define PLUGIN_TAG "l4d_consistent_escaperoute"

#include <sourcemod>
#include <dhooks>
#include <sourcescramble>
#include <sdktools>
#include <left4dhooks>

#if DEBUG
#include <sdktools_functions>
#endif

public Plugin myinfo =
{
	name = "[L4D & 2] Consistent Escape Route",
	author = "Forgetest",
	description = "True L4D.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

enum struct SDKCallParamsWrapper {
	SDKType type;
	SDKPassMethod pass;
	int decflags;
	int encflags;
}

methodmap GameDataWrapper < GameData {
	public GameDataWrapper(const char[] file) {
		GameData gd = new GameData(file);
		if (!gd) SetFailState("Missing gamedata \"%s\"", file);
		return view_as<GameDataWrapper>(gd);
	}
	property GameData Super {
		public get() { return view_as<GameData>(this); }
	}
	public int GetOffset(const char[] key) {
		int offset = this.Super.GetOffset(key);
		if (offset == -1) SetFailState("Missing offset \"%s\"", key);
		return offset;
	}
	public Address GetAddress(const char[] key) {
		Address ptr = this.Super.GetAddress(key);
		if (ptr == Address_Null) SetFailState("Missing address \"%s\"", key);
		return ptr;
	}
	public MemoryPatch CreatePatchOrFail(const char[] name, bool enable = false) {
		MemoryPatch hPatch = MemoryPatch.CreateFromConf(this, name);
		if (!(enable ? hPatch.Enable() : hPatch.Validate()))
			SetFailState("Failed to patch \"%s\"", name);
		return hPatch;
	}
	public DynamicDetour CreateDetourOrFail(
			const char[] name,
			DHookCallback preHook = INVALID_FUNCTION,
			DHookCallback postHook = INVALID_FUNCTION) {
		DynamicDetour hSetup = DynamicDetour.FromConf(this, name);
		if (!hSetup)
			SetFailState("Missing detour setup \"%s\"", name);
		if (preHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Pre, preHook))
			SetFailState("Failed to pre-detour \"%s\"", name);
		if (postHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Post, postHook))
			SetFailState("Failed to post-detour \"%s\"", name);
		return hSetup;
	}
	public Handle CreateSDKCallOrFail(
			SDKCallType type,
			SDKFuncConfSource src,
			const char[] name,
			const SDKCallParamsWrapper[] params = {},
			int numParams = 0,
			bool hasReturnValue = false,
			const SDKCallParamsWrapper ret = {}) {
		static const char k_sSDKFuncConfSource[SDKFuncConfSource][] = { "offset", "signature", "address" };
		Handle result;
		StartPrepSDKCall(type);
		if (!PrepSDKCall_SetFromConf(this, src, name))
			SetFailState("Missing %s \"%s\"", k_sSDKFuncConfSource[src], name);
		for (int i = 0; i < numParams; ++i)
			PrepSDKCall_AddParameter(params[i].type, params[i].pass, params[i].decflags, params[i].encflags);
		if (hasReturnValue)
			PrepSDKCall_SetReturnInfo(ret.type, ret.pass, ret.decflags, ret.encflags);
		if (!(result = EndPrepSDKCall()))
			SetFailState("Failed to prep sdkcall \"%s\"", name);
		return result;
	}
}

methodmap Address {}

#if DEBUG
int g_iOffs_m_nMainPathAreaCount;
methodmap CEscapeRoute < Address
{
	public CEscapeRoute(int entity) {
		return view_as<CEscapeRoute>(GetEntityAddress(entity));
	}
	
	public TerrorNavArea GetMainPathArea(int index) {
		return LoadFromAddress(this
							+ view_as<Address>(g_iOffs_m_nMainPathAreaCount + 8)
							+ view_as<Address>(index * 4),
							NumberType_Int32);
	}
	
	property int m_nMainPathAreaCount {
		public get() { return LoadFromAddress(this
										+ view_as<Address>(g_iOffs_m_nMainPathAreaCount),
										NumberType_Int32); }
	}
}
bool g_bEscapeRouteChecked = false;
ArrayList g_SavedEscapeRouteAreas;

int g_offs_m_id;
methodmap TerrorNavArea < Address
{
	public int GetID() {
		return LoadFromAddress(this + view_as<Address>(g_offs_m_id), NumberType_Int32);
	}
}
#endif

MemoryPatch g_patch_SkipSpawnPosIdx;
Handle g_call_Checkpoint_GetLargestArea;

public void OnPluginStart()
{
	GameDataWrapper gd = new GameDataWrapper("l4d_consistent_escaperoute");

#if DEBUG
	g_iOffs_m_nMainPathAreaCount = gd.GetOffset("CEscapeRoute::m_nMainPathAreaCount");
	g_offs_m_id = gd.GetOffset("CNavArea::m_id");
#endif

	g_patch_SkipSpawnPosIdx = gd.CreatePatchOrFail("skip_spawn_position_idx", false);

	SDKCallParamsWrapper params[] = {
		{ SDKType_PlainOldData, SDKPass_Plain },
	};
	g_call_Checkpoint_GetLargestArea = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, "Checkpoint::GetLargestArea", _, 0, true, params[0]);

	delete gd.CreateDetourOrFail("l4d_consistent_escaperoute::Checkpoint::GetSpawnPosition", _, DTR_Checkpoint_GetSpawnPosition_Post);
	delete gd.CreateDetourOrFail("l4d_consistent_escaperoute::GetPlayerSpawnPosition", DTR_GetPlayerSpawnPosition, DTR_GetPlayerSpawnPosition_Post);
	delete gd.CreateDetourOrFail("l4d_consistent_escaperoute::TerrorNavMesh::ComputeFlowDistances", DTR_ComputeFlowDistances, DTR_ComputeFlowDistances_Post);
	delete gd;
	
#if DEBUG
	g_SavedEscapeRouteAreas = new ArrayList();

	HookEvent("round_start", Event_round_start);
#endif
}

public void OnMapEnd()
{
#if DEBUG
	g_SavedEscapeRouteAreas.Clear();
#endif
}

static bool g_bInComputeFlowDistances = false;
MRESReturn DTR_ComputeFlowDistances(DHookReturn hReturn)
{
	g_bInComputeFlowDistances = true;

	return MRES_Ignored;
}

// GetPlayerSpawnPosition(SurvivorCharacterType,Vector *,QAngle *,TerrorNavArea **)
MRESReturn DTR_GetPlayerSpawnPosition(DHookReturn hReturn, DHookParam hParams)
{
	if (!g_bInComputeFlowDistances)
		return MRES_Ignored;

// if ( iSurvPosCount )
// {
// 	static int idx = -1;
// 	if ( ++idx >= iSurvPosCount )
// 		idx = 0;
// 
// 	iPosIndexToUse = idx;
// 	pSurvPosEnt = vecSurvPositions.At(iPosIndexToUse);
// }
// 
// NOTE: The patch here transforms the original code to make "iPosIndexToUse" always zero
//       which forces the first survivor postion entity to be where the start area is.

	g_patch_SkipSpawnPosIdx.Enable();

	return MRES_Ignored;
}

// Checkpoint::GetSpawnPosition(Vector *, QAngle *, TerrorNavArea **)const
MRESReturn DTR_Checkpoint_GetSpawnPosition_Post(Address pThis, DHookReturn hReturn, DHookParam hParams)
{
	if (!g_bInComputeFlowDistances)
		return MRES_Ignored;
	
#if DEBUG
	PrintToServer("[%s] Overriding Checkpoint::GetSpawnPosition", PLUGIN_TAG);
#endif

	// NOTE:
	//   GetSpawnPosition always computes a random position within start safe area.
	//   The following makes it always return the largest area instead.
	TerrorNavArea area = SDKCall(g_call_Checkpoint_GetLargestArea, pThis);
	if (area == Address_Null)
		return MRES_Ignored;

#if DEBUG
	PrintToServer("[%s] Fixed player start area = %d", PLUGIN_TAG, area.GetID());
#endif

	if (!hParams.IsNull(1))
	{
		float pos[3];
		L4D_GetNavAreaCenter(area, pos);
		hParams.SetVector(1, pos);
	}

	if (!hParams.IsNull(2))
	{
		hParams.SetVector(2, {0.0, 0.0, 0.0});
	}

	if (!hParams.IsNull(3))
	{
		hParams.SetObjectVar(3, 0, ObjectValueType_Int, area);
	}

	hReturn.Value = true;
	return MRES_ChangedOverride;
}

// GetPlayerSpawnPosition(SurvivorCharacterType,Vector *,QAngle *,TerrorNavArea **)
MRESReturn DTR_GetPlayerSpawnPosition_Post(DHookReturn hReturn, DHookParam hParams)
{
	if (!g_bInComputeFlowDistances)
		return MRES_Ignored;

	g_patch_SkipSpawnPosIdx.Disable();

	return MRES_Ignored;
}

MRESReturn DTR_ComputeFlowDistances_Post(DHookReturn hReturn)
{
	g_bInComputeFlowDistances = false;

#if DEBUG
	RequestFrame(NextFrame_ComputeFlowDistance); // escape route is rebuilt a few calls after
#endif

	return MRES_Ignored;
}

#if DEBUG
void Event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	g_bEscapeRouteChecked = false;
}

void NextFrame_ComputeFlowDistance()
{
	if (g_bEscapeRouteChecked)
		return;

	int entity = FindEntityByClassname(INVALID_ENT_REFERENCE, "escape_route");
	if (entity == INVALID_ENT_REFERENCE)
		return;
	
	// Only check once eveny beginning of round
	g_bEscapeRouteChecked = true;

	CEscapeRoute TheEscapeRoute = CEscapeRoute(entity);

	if (g_SavedEscapeRouteAreas.Length)
	{
		bool fullyMatched = true;
		PrintToServer("[%s] Checking escape route", PLUGIN_TAG);

		if (g_SavedEscapeRouteAreas.Length != TheEscapeRoute.m_nMainPathAreaCount)
		{
			PrintToServer("  Count mismatches (was %d, now %d)", g_SavedEscapeRouteAreas.Length, TheEscapeRoute.m_nMainPathAreaCount);
			fullyMatched = false;
		}
		else
		{
			for (int i = 0, size = TheEscapeRoute.m_nMainPathAreaCount; i < size; ++i)
			{
				TerrorNavArea area = TheEscapeRoute.GetMainPathArea(i);
				if (area.GetID() != g_SavedEscapeRouteAreas.Get(i))
				{
					PrintToServer("  Area @ %d mismatches (was #%d, now #%d)", i, g_SavedEscapeRouteAreas.Get(i), area.GetID());
					fullyMatched = false;
					break;
				}
			}
		}

		PrintToServer("[%s] Finish checking escape route (success = %s)", PLUGIN_TAG, fullyMatched ? "yes" : "no");

		if (!fullyMatched)
		{
			LogError("Unexpected mismatching escape route. Please report to author.");
		}
	}
	else
	{
		PrintToServer("[%s] Saving escape route (count = %d)", PLUGIN_TAG, TheEscapeRoute.m_nMainPathAreaCount);
		for (int i = 0, size = TheEscapeRoute.m_nMainPathAreaCount; i < size; ++i)
		{
			TerrorNavArea area = TheEscapeRoute.GetMainPathArea(i);
			g_SavedEscapeRouteAreas.Push(area.GetID());
		}
	}
}
#endif
