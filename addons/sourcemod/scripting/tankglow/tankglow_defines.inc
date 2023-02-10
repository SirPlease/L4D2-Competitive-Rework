#if defined _TANKGLOW_DEFINES_included
 #endinput
#endif
#define _TANKGLOW_DEFINES_included

#define KEY_THEESCAPEROUTE "TheEscapeRoute"
#define KEY_GETPOSITIONONPATH "CEscapeRoute::GetPositionOnPath"
#define KEY_ISSPACEFORZOMBIEHERE "ZombieManager::IsSpaceForZombieHere"
#define KEY_GETNEXTESCAPESTEP "TerrorNavArea::GetNextEscapeStep"
#define KEY_ISVALIDFORWANDERINGPOPULATION "TerrorNavArea::IsValidForWanderingPopulation"
#define KEY_m_vecCenter "CNavArea::m_vecCenter"
#define KEY_m_bIsUnderwater "TerrorNavArea::m_bIsUnderwater"
#define KEY_m_activeSurvivors "TerrorNavArea::m_activeSurvivors"
#define KEY_m_connect "CNavArea::m_connect"

static Handle
	s_hSDKCall_GetPositionOnPath,
	s_hSDKCall_IsSpaceForZombieHere,
	s_hSDKCall_GetNextEscapeStep,
	s_hSDKCall_IsValidForWanderingPopulation;

static Address 
	s_addr_TheEscapeRoute;

static int 
	s_iOffs_m_vecCenter,
	s_iOffs_m_bIsUnderwater,
	s_iOffs_m_activeSurvivors/*,
	s_iOffs_m_connect*/;

methodmap CEscapeRoute
{
	public void GetPositionOnPath(float flow, float vPos[3]) {
		SDKCall(s_hSDKCall_GetPositionOnPath, this, flow, vPos);
	}
}

CEscapeRoute TheEscapeRoute()
{
	return view_as<CEscapeRoute>(LoadFromAddress(s_addr_TheEscapeRoute, NumberType_Int32));
}

/*methodmap NavConnectVector
{
	public TerrorNavArea Element(int i) {
		return LoadFromAddress(this.m_pData + view_as<Address>(8 * i + 4), NumberType_Int32);
	}
	public int Count() {
		return LoadFromAddress(this.m_pData, NumberType_Int32);
	}
	property Address m_pData {
		public get() { return LoadFromAddress(view_as<Address>(this), NumberType_Int32); }
	}
}*/

#define NULL_NAV_AREA view_as<TerrorNavArea>(0)
methodmap TerrorNavArea
{
	public TerrorNavArea(float vPos[3]) {
		return view_as<TerrorNavArea>(L4D2Direct_GetTerrorNavArea(vPos, 120.0));
	}
	public bool Valid() {
		return this != NULL_NAV_AREA;
	}
	public TerrorNavArea GetNextEscapeStep(int &traverse_type = 0) {
		return SDKCall(s_hSDKCall_GetNextEscapeStep, this, traverse_type);
	}
	public bool IsValidForWanderingPopulation() {
		return SDKCall(s_hSDKCall_IsValidForWanderingPopulation, this);
	}
	public void GetCenter(float vec[3]) {
		vec[0] = LoadFromAddress(view_as<Address>(this) + view_as<Address>(s_iOffs_m_vecCenter), NumberType_Int32);
		vec[1] = LoadFromAddress(view_as<Address>(this) + view_as<Address>(s_iOffs_m_vecCenter + 4), NumberType_Int32);
		vec[2] = LoadFromAddress(view_as<Address>(this) + view_as<Address>(s_iOffs_m_vecCenter + 8), NumberType_Int32);
	}
	property bool m_isUnderwater {
		public get() { return !!LoadFromAddress(view_as<Address>(this) + view_as<Address>(s_iOffs_m_bIsUnderwater), NumberType_Int8); }
	}
	property int m_activeSurvivors {
		public get() { return LoadFromAddress(view_as<Address>(this) + view_as<Address>(s_iOffs_m_activeSurvivors), NumberType_Int8); }
	}
	/*public NavConnectVector GetConnectVector(int dir) {
		if (g_bLeft4Dead2) {
			return LoadFromAddress(view_as<Address>(this) + view_as<Address>(s_iOffs_m_connect + 4 * dir), NumberType_Int32);
		}
	}*/
}

methodmap CZombieManager 
{
	public bool IsSpaceForZombieHere(const float vPos[3]) {
		return SDKCall(s_hSDKCall_IsSpaceForZombieHere, L4D_GetPointer(POINTER_ZOMBIEMANAGER), vPos);
	}
}

void LoadSDK()
{
	Handle conf = LoadGameConfigFile(GAMEDATA_FILE);
	if (!conf)
		SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(conf, SDKConf_Signature, KEY_GETPOSITIONONPATH))
		SetFailState("Missing signature "...KEY_GETPOSITIONONPATH..."");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	s_hSDKCall_GetPositionOnPath = EndPrepSDKCall();
	if (s_hSDKCall_GetPositionOnPath == null)
		SetFailState("Failed to prepare SDKCall for \""...KEY_GETPOSITIONONPATH..."\"");
	
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(conf, SDKConf_Signature, KEY_ISVALIDFORWANDERINGPOPULATION))
		SetFailState("Missing signature "...KEY_ISVALIDFORWANDERINGPOPULATION..."");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	s_hSDKCall_IsValidForWanderingPopulation = EndPrepSDKCall();
	if (s_hSDKCall_IsValidForWanderingPopulation == null)
		SetFailState("Failed to prepare SDKCall for \""...KEY_ISVALIDFORWANDERINGPOPULATION..."\"");
	
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(conf, SDKConf_Signature, KEY_ISSPACEFORZOMBIEHERE))
		SetFailState("Missing signature "...KEY_ISSPACEFORZOMBIEHERE..."");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	s_hSDKCall_IsSpaceForZombieHere = EndPrepSDKCall();
	if (s_hSDKCall_IsSpaceForZombieHere == null)
		SetFailState("Failed to prepare SDKCall for \""...KEY_ISSPACEFORZOMBIEHERE..."\"");
	
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(conf, SDKConf_Signature, KEY_GETNEXTESCAPESTEP))
		SetFailState("Missing signature "...KEY_GETNEXTESCAPESTEP..."");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	s_hSDKCall_GetNextEscapeStep = EndPrepSDKCall();
	if (s_hSDKCall_GetNextEscapeStep == null)
		SetFailState("Failed to prepare SDKCall for \""...KEY_GETNEXTESCAPESTEP..."\"");
	
	s_addr_TheEscapeRoute = GameConfGetAddress(conf, KEY_THEESCAPEROUTE);
	if (s_addr_TheEscapeRoute == Address_Null)
		SetFailState("Missing address \""...KEY_THEESCAPEROUTE..."\"");
	
	s_iOffs_m_vecCenter = GameConfGetOffset(conf, KEY_m_vecCenter);
	if (s_iOffs_m_vecCenter == -1)
		SetFailState("Missing offset \""...KEY_m_vecCenter..."\"");
	
	s_iOffs_m_bIsUnderwater = GameConfGetOffset(conf, KEY_m_bIsUnderwater);
	if (s_iOffs_m_bIsUnderwater == -1)
		SetFailState("Missing offset \""...KEY_m_bIsUnderwater..."\"");
	
	s_iOffs_m_activeSurvivors = GameConfGetOffset(conf, KEY_m_activeSurvivors);
	if (s_iOffs_m_activeSurvivors == -1)
		SetFailState("Missing offset \""...KEY_m_activeSurvivors..."\"");
	
	/*if (g_bLeft4Dead2)
	{
		s_iOffs_m_connect = GameConfGetOffset(conf, KEY_m_connect);
		if (s_iOffs_m_connect == -1)
			SetFailState("Missing offset \""...KEY_m_connect..."\"");
	}*/
	
	delete conf;
}
