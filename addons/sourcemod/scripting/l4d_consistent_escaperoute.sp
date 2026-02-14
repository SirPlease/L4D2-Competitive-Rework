#pragma semicolon 1
#pragma newdecls required

#define DEBUG 1
#define PLUGIN_VERSION "2.0"
#define PLUGIN_TAG "l4d_consistent_escaperoute"

#include <sourcemod>
#include <dhooks>
#include <sourcescramble>
#include <@Forgetest/gamedatawrapper>

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

public void OnPluginStart()
{
	GameDataWrapper gd = new GameDataWrapper("l4d_consistent_escaperoute");

#if DEBUG
	g_iOffs_m_nMainPathAreaCount = gd.GetOffset("CEscapeRoute::m_nMainPathAreaCount");
	g_offs_m_id = gd.GetOffset("CNavArea::m_id");
#endif

	g_patch_SkipSpawnPosIdx = gd.CreatePatchOrFail("skip_spawn_position_idx", false);

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
			PrintToServer("  Count mismatches (was %d, now %d)", PLUGIN_TAG, g_SavedEscapeRouteAreas.Length, TheEscapeRoute.m_nMainPathAreaCount);
			fullyMatched = false;
		}
		else
		{
			for (int i = 0, size = TheEscapeRoute.m_nMainPathAreaCount; i < size; ++i)
			{
				TerrorNavArea area = TheEscapeRoute.GetMainPathArea(i);
				if (area.GetID() != g_SavedEscapeRouteAreas.Get(i))
				{
					PrintToServer("  Area @ %d mismatches (was #%d, now #%d)", PLUGIN_TAG, i, g_SavedEscapeRouteAreas.Get(i), area.GetID());
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
