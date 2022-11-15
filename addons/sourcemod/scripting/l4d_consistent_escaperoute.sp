#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D & 2] Consistent Escape Route",
	author = "Forgetest",
	description = "True L4D.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

int g_iOffs_m_nMainPathAreaCount, g_iOffs_m_id;
Handle g_hSDKCall_ResetPath, g_hSDKCall_AddArea, g_hSDKCall_FinishPath, g_hSDKCall_GetNavAreaByID;

methodmap CEscapeRoute
{
	public CEscapeRoute(Address addr) {
		return view_as<CEscapeRoute>(addr);
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
		return LoadFromAddress(view_as<Address>(this)
							+ view_as<Address>(g_iOffs_m_nMainPathAreaCount + 8)
							+ view_as<Address>(index * 4),
							NumberType_Int32);
	}
	
	property int m_nMainPathAreaCount {
		public get() { return LoadFromAddress(view_as<Address>(this)
										+ view_as<Address>(g_iOffs_m_nMainPathAreaCount),
										NumberType_Int32); }
	}
}

methodmap TerrorNavArea
{
	public TerrorNavArea(Address addr) {
		return view_as<TerrorNavArea>(addr);
	}
	
	public int GetID() {
		return LoadFromAddress(view_as<Address>(this)
							+ view_as<Address>(g_iOffs_m_id),
							NumberType_Int32);
	}
	
	public void RemoveSpawnAttributes(int flag) {
		int spawnAttributes = L4D_GetNavArea_SpawnAttributes(view_as<Address>(this));
		L4D_SetNavArea_SpawnAttributes(view_as<Address>(this), spawnAttributes & ~flag);
	}
}

CEscapeRoute g_spawnPath;
Address g_pSpawnPath;

ArrayList g_aSpawnPathAreas;

public void OnPluginStart()
{
	GameData conf = new GameData("l4d_consistent_escaperoute");
	if (conf == null)
		SetFailState("Missing gamedata \"l4d_consistent_escaperoute\"");
	
	g_pSpawnPath = conf.GetAddress("TheEscapeRoute");
	if (g_pSpawnPath == Address_Null)
		SetFailState("Missing address \"TheEscapeRoute\"");
	
	g_iOffs_m_nMainPathAreaCount = conf.GetOffset("CEscapeRoute::m_nMainPathAreaCount");
	if (g_iOffs_m_nMainPathAreaCount == -1)
		SetFailState("Missing offset \"CEscapeRoute::m_nMainPathAreaCount\"");
	
	g_iOffs_m_id = conf.GetOffset("CNavArea::m_id");
	if (g_iOffs_m_id == -1)
		SetFailState("Missing offset \"CNavArea::m_id\"");
	
	StartPrepSDKCall(SDKCall_Raw);
	if ( PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CEscapeRoute::ResetPath") == false )
		SetFailState("Missing signature \"CEscapeRoute::ResetPath\"");
	g_hSDKCall_ResetPath = EndPrepSDKCall();
	if (g_hSDKCall_ResetPath == null)
		SetFailState("Failed to create SDKCall \"CEscapeRoute::ResetPath\"");
	
	StartPrepSDKCall(SDKCall_Raw);
	if ( PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CEscapeRoute::AddArea") == false )
		SetFailState("Missing signature \"CEscapeRoute::AddArea\"");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // TerrorNavArea
	g_hSDKCall_AddArea = EndPrepSDKCall();
	if (g_hSDKCall_AddArea == null)
		SetFailState("Failed to create SDKCall \"CEscapeRoute::AddArea\"");
	
	StartPrepSDKCall(SDKCall_Raw);
	if ( PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CEscapeRoute::FinishPath") == false )
		SetFailState("Missing signature \"CEscapeRoute::FinishPath\"");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // TerrorNavArea
	g_hSDKCall_FinishPath = EndPrepSDKCall();
	if (g_hSDKCall_FinishPath == null)
		SetFailState("Failed to create SDKCall \"CEscapeRoute::FinishPath\"");
	
	StartPrepSDKCall(SDKCall_Raw);
	if ( PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CNavMesh::GetNavAreaByID") == false )
		SetFailState("Missing signature \"CNavMesh::GetNavAreaByID\"");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // id
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); // TerrorNavArea
	g_hSDKCall_GetNavAreaByID = EndPrepSDKCall();
	if (g_hSDKCall_GetNavAreaByID == null)
		SetFailState("Failed to create SDKCall \"CNavMesh::GetNavAreaByID\"");
	
	delete conf;
	
	g_aSpawnPathAreas = new ArrayList();
	
	HookEvent("round_start_post_nav", Event_RoundStartPostNav);
}

void Event_RoundStartPostNav(Event event, const char[] name, bool dontBroadcast)
{
	if (!L4D_IsVersusMode())
		return;
	
	g_spawnPath = LoadFromAddress(g_pSpawnPath, NumberType_Int32);
	if (InSecondHalfOfRound())
	{
		for (int i = 0; i < g_spawnPath.m_nMainPathAreaCount; ++i)
		{
			TerrorNavArea area = g_spawnPath.GetMainPathArea(i);
			area.RemoveSpawnAttributes(NAV_SPAWN_ESCAPE_ROUTE);
		}
		
		PrintToServer("[l4d_consistent_escaperoute] Second half (%i nav)", g_spawnPath.m_nMainPathAreaCount);
		
		g_spawnPath.ResetPath();
		
		for (int i = 0; i < g_aSpawnPathAreas.Length; ++i)
		{
			int id = g_aSpawnPathAreas.Get(i);
			
			TerrorNavArea area = GetNavAreaByID(id);
			g_spawnPath.AddArea(area);
		}
		
		PrintToServer("[l4d_consistent_escaperoute] Restored escape route from last half (%i nav)", g_aSpawnPathAreas.Length);
	}
	else
	{
		g_aSpawnPathAreas.Clear();
		
		for (int i = 0; i < g_spawnPath.m_nMainPathAreaCount; ++i)
		{
			TerrorNavArea area = g_spawnPath.GetMainPathArea(i);
			g_aSpawnPathAreas.Push(area.GetID());
		}
		
		PrintToServer("[l4d_consistent_escaperoute] Cached escape route of first half (%i nav)", g_aSpawnPathAreas.Length);
	}
}

TerrorNavArea GetNavAreaByID(int id)
{
	return SDKCall(g_hSDKCall_GetNavAreaByID, L4D_GetPointer(POINTER_NAVMESH), id);
}

stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound"));
}