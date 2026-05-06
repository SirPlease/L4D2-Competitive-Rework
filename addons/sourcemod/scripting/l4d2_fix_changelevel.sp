#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.2"

public Plugin myinfo =
{
	name = "[L4D2] Fix Changelevel",
	author = "Lux (for \"l4d2_changelevel\"), Forgetest",
	description = "Fix issues due to forced changelevel (i.e. No gascans in scavenge, incorrect behavior of \"OnGameplayStart\").",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
}

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
	public Address GetAddressOrFail(const char[] key) {
		Address ptr = this.GetAddress(key);
		if (ptr == Address_Null) SetFailState("Missing address \"%s\"", key);
		return ptr;
	}
	public int GetOffsetOrFail(const char[] key) {
		int offset = this.GetOffset(key);
		if (offset == -1) SetFailState("Missing offset \"%s\"", key);
		return offset;
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

Handle g_CallClearTeamScores;
Handle g_CallOnBeginTransition;
Handle g_CallOnBeginChangeLevel;
int g_iOffs_m_mapDurationTimer;
int g_iOffs_m_flTotalMissionElaspedTime;
int g_iOffs_m_szOriginalMap;
Address gp_m_isTransitioning;
Address gp_s_landmarkName;
Address gp_s_landmarkPosition;

methodmap CDirector {
	public void ClearTeamScores(bool newCampaign) {
		SDKCall(g_CallClearTeamScores, this, newCampaign);
	}
	public void OnBeginTransition(bool bTransitionToNextMap) {
		SDKCall(g_CallOnBeginTransition, this, bTransitionToNextMap);
	}
	property IntervalTimer m_mapDurationTimer {
		public get() { return view_as<IntervalTimer>(view_as<Address>(this) + view_as<Address>(g_iOffs_m_mapDurationTimer)); }
	}
	property float m_flTotalMissionElaspedTime {
		public set(float flTotalMissionElaspedTime) { StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iOffs_m_flTotalMissionElaspedTime), flTotalMissionElaspedTime, NumberType_Int32); }
	}
	property Address m_szOriginalMap {
		public get() { return view_as<Address>(this) + view_as<Address>(g_iOffs_m_szOriginalMap); }
	}
	public bool IsTransitioning() {
		return LoadFromAddress(gp_m_isTransitioning, NumberType_Int8);
	}
	public void SetOriginalMap(const char[] map) {
		UTIL_StoreToAddressString(this.m_szOriginalMap, map, 32);
	}
}
CDirector TheDirector;

public void OnPluginStart()
{
	GameDataWrapper gd = new GameDataWrapper("l4d2_fix_changelevel");

	SDKCallParamsWrapper params[] = {
		{SDKType_Bool, SDKPass_Plain}
	};
	g_CallClearTeamScores = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, "CDirector::ClearTeamScores", params, sizeof(params), false);
	
	SDKCallParamsWrapper params2[] = {
		{SDKType_Bool, SDKPass_Plain}
	};
	g_CallOnBeginTransition = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, "CDirector::OnBeginTransition", params2, sizeof(params2), false);
	
	SDKCallParamsWrapper params3[] = {
		{SDKType_String, SDKPass_Pointer}
	};
	g_CallOnBeginChangeLevel = gd.CreateSDKCallOrFail(SDKCall_GameRules, SDKConf_Signature, "CTerrorGameRules::OnBeginChangeLevel", params3, sizeof(params3), false);
	
	g_iOffs_m_mapDurationTimer = gd.GetOffsetOrFail("CDirector::m_mapDurationTimer");
	g_iOffs_m_flTotalMissionElaspedTime = gd.GetOffsetOrFail("CDirector::m_flTotalMissionElaspedTime");
	g_iOffs_m_szOriginalMap = gd.GetOffsetOrFail("CDirector::m_szOriginalMap");
	gp_m_isTransitioning = gd.GetAddressOrFail("CDirector::m_isTransitioning");
	gp_s_landmarkName = gd.GetAddressOrFail("s_landmarkName");
	gp_s_landmarkPosition = gd.GetAddressOrFail("s_landmarkPosition");

	delete gd.CreateDetourOrFail("CVEngineServer::ChangeLevel", DTR__CVEngineServer__ChangeLevel);
	delete gd;
}

public void OnAllPluginsLoaded()
{
	TheDirector = view_as<CDirector>(L4D_GetPointer(POINTER_DIRECTOR));
	if (!TheDirector)
	{
		LogError("Failed to retrieve TheDirector pointer from left4dhooks");
	}
}

MRESReturn DTR__CVEngineServer__ChangeLevel(DHookParam hParams)
{
	if (!TheDirector)
		return MRES_Ignored;
	
	char map[64]/*, reason[64]*/;
	hParams.GetString(1, map, sizeof(map));
	// if (!hParams.IsNull(2))
	//	hParams.GetString(2, reason, sizeof(reason));
	
	if (TheDirector.IsTransitioning())
		return MRES_Ignored;
	
	TheDirector.ClearTeamScores(true);
	
	ITimer_Start(TheDirector.m_mapDurationTimer);
	TheDirector.m_flTotalMissionElaspedTime = 0.0;

	TheDirector.SetOriginalMap(map);
	ClearTransitionedLandmarkName();
	TheDirector.OnBeginTransition(false);
	GameRules__OnBeginChangeLevel(map);

	return MRES_Ignored;
}

void GameRules__OnBeginChangeLevel(const char[] map)
{
	SDKCall(g_CallOnBeginChangeLevel, map);
}

void ClearTransitionedLandmarkName()
{
	StoreToAddress(gp_s_landmarkName, 0, NumberType_Int8);
	StoreToAddress(gp_s_landmarkPosition, 0.0, NumberType_Int32);
	StoreToAddress(gp_s_landmarkPosition + view_as<Address>(4), 0.0, NumberType_Int32);
	StoreToAddress(gp_s_landmarkPosition + view_as<Address>(8), 0.0, NumberType_Int32);
}

void UTIL_StoreToAddressString(Address dest, const char[] src, int maxlength)
{
	int len = strlen(src);
	if (len > maxlength - 1)
		len = maxlength - 1;
	for (int i = 0; i < len; ++i) {
		StoreToAddress(dest + view_as<Address>(i), src[i], NumberType_Int8);
	}
	StoreToAddress(dest + view_as<Address>(len), 0, NumberType_Int8);
}