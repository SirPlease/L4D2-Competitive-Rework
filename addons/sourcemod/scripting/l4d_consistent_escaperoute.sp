#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "1.1.3"

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

int g_iOffs_m_nMainPathAreaCount, g_iOffs_m_flowToGoal, g_iOffs_m_flMapMaxFlowDistance;
Handle g_hSDKCall_ResetPath, g_hSDKCall_AddArea, g_hSDKCall_FinishPath;

methodmap CEscapeRoute
{
	public CEscapeRoute(int entity) {
		return view_as<CEscapeRoute>(entity);
	}
	
	public void ResetPath() {
		SDKCall(g_hSDKCall_ResetPath, this);
	}
	
	public void AddArea(TerrorNavArea area) {
		SDKCall(g_hSDKCall_AddArea, this, area);
	}
	
	public void FinishPath() {
		SDKCall(g_hSDKCall_FinishPath, this);
	}
	
	public TerrorNavArea GetMainPathArea(int index) {
		return LoadFromAddress(GetEntityAddress(view_as<int>(this))
							+ view_as<Address>(g_iOffs_m_nMainPathAreaCount + 8)
							+ view_as<Address>(index * 4),
							NumberType_Int32);
	}
	
	property int m_nMainPathAreaCount {
		public get() { return LoadFromAddress(GetEntityAddress(view_as<int>(this))
										+ view_as<Address>(g_iOffs_m_nMainPathAreaCount),
										NumberType_Int32); }
	}
}

methodmap CUtlVector
{
	public int Size() {
		return LoadFromAddress(view_as<Address>(this) + view_as<Address>(12), NumberType_Int32);
	}
	
	property Address m_pElements {
		public get() { return LoadFromAddress(view_as<Address>(this), NumberType_Int32); }
	}
}

methodmap NavAreaVector < CUtlVector
{
	public NavAreaVector(Address addr) {
		return view_as<NavAreaVector>(addr);
	}
	
	public TerrorNavArea At(int index) {
		return LoadFromAddress(this.m_pElements + view_as<Address>(index * 4), NumberType_Int32);
	}
}

methodmap TerrorNavArea
{
	public TerrorNavArea(Address addr) {
		return view_as<TerrorNavArea>(addr);
	}
	
	public int GetID() {
		return L4D_GetNavAreaID(view_as<Address>(this));
	}
	
	public void RemoveSpawnAttributes(int flag) {
		int spawnAttributes = L4D_GetNavArea_SpawnAttributes(view_as<Address>(this));
		L4D_SetNavArea_SpawnAttributes(view_as<Address>(this), spawnAttributes & ~flag);
	}
	
	property float m_flowToGoal {
		public get() { return LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOffs_m_flowToGoal), NumberType_Int32); }
		public set(float flow) { StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iOffs_m_flowToGoal), flow, NumberType_Int32); }
	}
	
	property float m_flowFromStart {
		public get() { return LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOffs_m_flowToGoal + 4), NumberType_Int32); }
		public set(float flow) { StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iOffs_m_flowToGoal + 4), flow, NumberType_Int32); }
	}
}

methodmap TerrorNavMesh
{
	public TerrorNavArea GetNavAreaByID(int id) {
		return view_as<TerrorNavArea>(L4D_GetNavAreaByID(id));
	}
	
	property float m_flMapMaxFlowDistance {
		public get() { return LoadFromAddress(L4D_GetPointer(POINTER_NAVMESH) + view_as<Address>(g_iOffs_m_flMapMaxFlowDistance), NumberType_Int32); }
		public set(float flow) { StoreToAddress(L4D_GetPointer(POINTER_NAVMESH) + view_as<Address>(g_iOffs_m_flMapMaxFlowDistance), flow, NumberType_Int32); }
	}
}

NavAreaVector TheNavAreas;
TerrorNavMesh TheNavMesh;
CEscapeRoute TheEscapeRoute;

enum struct TerrorNavInfo
{
	int m_id;
	float m_flowToGoal;
	float m_flowFromStart;

	void Save(TerrorNavArea area) {
		this.m_id = area.GetID();
		this.m_flowToGoal = area.m_flowToGoal;
		this.m_flowFromStart = area.m_flowFromStart;
	}

	void Restore() {
		TerrorNavArea area = TheNavMesh.GetNavAreaByID(this.m_id);
		area.m_flowToGoal = this.m_flowToGoal;
		area.m_flowFromStart = this.m_flowFromStart;
	}
}

ArrayList g_aEscapeRouteAreas;
ArrayList g_aAreaFlows;

float g_flMapMaxFlowDistance;

public void OnPluginStart()
{
	GameDataWrapper gd = new GameDataWrapper("l4d_consistent_escaperoute");
	
	g_iOffs_m_nMainPathAreaCount = gd.GetOffset("CEscapeRoute::m_nMainPathAreaCount");
	g_iOffs_m_flowToGoal = gd.GetOffset("TerrorNavArea::m_flowToGoal");
	g_iOffs_m_flMapMaxFlowDistance = gd.GetOffset("TerrorNavMesh::m_flMapMaxFlowDistance");
	
	g_hSDKCall_ResetPath = gd.CreateSDKCallOrFail(SDKCall_Entity, SDKConf_Signature, "CEscapeRoute::ResetPath");
	g_hSDKCall_FinishPath = gd.CreateSDKCallOrFail(SDKCall_Entity, SDKConf_Signature, "CEscapeRoute::FinishPath");

	SDKCallParamsWrapper params[] = {
		{SDKType_PlainOldData, SDKPass_Plain} // TerrorNavArea
	};
	g_hSDKCall_AddArea = gd.CreateSDKCallOrFail(SDKCall_Entity, SDKConf_Signature, "CEscapeRoute::AddArea", params, sizeof(params));
	
	delete gd;
	
	g_aEscapeRouteAreas = new ArrayList();
	g_aAreaFlows = new ArrayList(sizeof(TerrorNavInfo));
	
	HookEvent("round_start_post_nav", Event_RoundStartPostNav);
}

void Event_RoundStartPostNav(Event event, const char[] name, bool dontBroadcast)
{
	if (!L4D_IsVersusMode())
		return;
	
	// Uses a delay here in case GameRules han't been updated yet
	CreateTimer(0.1, Timer_RoundStartPostNav, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_RoundStartPostNav(Handle timer)
{
	int entity = FindEntityByClassname(MaxClients+1, "escape_route");
	TheEscapeRoute = CEscapeRoute(entity); 

	Address pTheNavAreas = L4D_GetPointer(POINTER_THENAVAREAS);
	TheNavAreas = NavAreaVector(pTheNavAreas);
	
	if (InSecondHalfOfRound())
	{
		RestoreFromFirstHalf();
	}
	else
	{
		InitFromFirstHalf();
	}

	return Plugin_Stop;
}

void InitFromFirstHalf()
{
	g_aEscapeRouteAreas.Clear();
	g_aAreaFlows.Clear();
	
	for (int i = 0, size = TheEscapeRoute.m_nMainPathAreaCount; i < size; ++i)
	{
		TerrorNavArea area = TheEscapeRoute.GetMainPathArea(i);
		g_aEscapeRouteAreas.Push(area.GetID());
	}
	
	TerrorNavInfo info;
	g_aAreaFlows.Resize(TheNavAreas.Size());
	for (int i = 0, size = TheNavAreas.Size(); i < size; ++i)
	{
		TerrorNavArea area = TheNavAreas.At(i);
		info.Save(area);
		g_aAreaFlows.SetArray(i, info);
	}
	
	g_flMapMaxFlowDistance = TheNavMesh.m_flMapMaxFlowDistance;
	
	PrintToServer("[l4d_consistent_escaperoute] Cached escape route of first half (%i / %i nav) (%.5f)", g_aEscapeRouteAreas.Length, TheNavAreas.Size(), g_flMapMaxFlowDistance);
}

void RestoreFromFirstHalf()
{
	if (g_aAreaFlows.Length)
	{
		TerrorNavInfo info;

		for (int i = 0, size = g_aAreaFlows.Length; i < size; ++i)
		{
			g_aAreaFlows.GetArray(i, info);
			info.Restore();
		}
		
		TheNavMesh.m_flMapMaxFlowDistance = g_flMapMaxFlowDistance;
	}
	
	if (g_aEscapeRouteAreas.Length)
	{
		for (int i = 0, size = TheEscapeRoute.m_nMainPathAreaCount; i < size; ++i)
		{
			TerrorNavArea area = TheEscapeRoute.GetMainPathArea(i);
			area.RemoveSpawnAttributes(NAV_SPAWN_ESCAPE_ROUTE);
		}
		
		PrintToServer("[l4d_consistent_escaperoute] Second half (%i / %i nav) (%.5f)", TheEscapeRoute.m_nMainPathAreaCount, TheNavAreas.Size(), g_flMapMaxFlowDistance);
		
		TheEscapeRoute.ResetPath();
		for (int i = 0, size = g_aEscapeRouteAreas.Length; i < size; ++i)
		{
			int id = g_aEscapeRouteAreas.Get(i);
			
			TerrorNavArea area = TheNavMesh.GetNavAreaByID(id);
			TheEscapeRoute.AddArea(area);
		}
		TheEscapeRoute.FinishPath();
	}
	
	PrintToServer("[l4d_consistent_escaperoute] Restored escape route from last half (%i / %i nav)", g_aEscapeRouteAreas.Length, TheNavAreas.Size());
}

stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound"));
}
