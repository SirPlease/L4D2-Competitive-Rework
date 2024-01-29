#if defined __map_info_included
	#endinput
#endif
#define __map_info_included

#define DEBUG_MI				false
#define MI_MODULE_NAME			"MapInfo"

static int
	iMapMaxDistance = 0,
	iIsInEditMode[MAXPLAYERS + 1] = {0, ...};

static bool
	MI_bDebugEnabled = DEBUG_MI,
	MapDataAvailable = false;

static float
	Start_Point[3] = {0.0, ...},
	End_Point[3] = {0.0, ...},
	Start_Dist = 0.0,
	Start_Extra_Dist = 0.0,
	End_Dist = 0.0,
	fLocTemp[MAXPLAYERS + 1][3];

static KeyValues
	kMIData = null;

void MI_APL()
{
	CreateNative("LGO_IsMapDataAvailable", _native_IsMapDataAvailable);
	CreateNative("LGO_GetMapValueInt", _native_GetMapValueInt);
	CreateNative("LGO_GetMapValueFloat", _native_GetMapValueFloat);
	CreateNative("LGO_GetMapValueVector", _native_GetMapValueVector);
	CreateNative("LGO_GetMapValueString", _native_GetMapValueString);
	CreateNative("LGO_CopyMapSubsection", _native_CopyMapSubsection);
}

void MI_OnModuleStart()
{
	MI_KV_Load();

	//RegAdminCmd("confogl_midata_reload", MI_KV_CmdReload, ADMFLAG_CONFIG);
	RegAdminCmd("confogl_midata_save", MI_KV_CmdSave, ADMFLAG_CONFIG);
	RegAdminCmd("confogl_save_location", MI_KV_CmdSaveLoc, ADMFLAG_CONFIG);

	HookEvent("player_disconnect", PlayerDisconnect_Event);
}

void MI_OnMapStart()
{
	MI_KV_UpdateMapInfo();
}

void MI_OnMapEnd()
{
	kMIData.Rewind();

	MapDataAvailable = false;

	// 0 - server index?
	for (int i = 0; i <= MaxClients; i++) {
		iIsInEditMode[i] = 0;
	}
}

void MI_OnModuleEnd()
{
	MI_KV_Close();
}

static void PlayerDisconnect_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (client > 0 && client <= MaxClients) {
		iIsInEditMode[client] = 0;
	}
}

static Action MI_KV_CmdSave(int client, int args)
{
	char sCurMap[128];
	GetCurrentMap(sCurMap, sizeof(sCurMap));

	if (kMIData.JumpToKey(sCurMap, true)) {
		kMIData.SetVector("start_point", Start_Point);
		kMIData.SetFloat("start_dist", Start_Dist);
		kMIData.SetFloat("start_extra_dist", Start_Extra_Dist);

		char sNameBuff[PLATFORM_MAX_PATH];
		BuildConfigPath(sNameBuff, sizeof(sNameBuff), "mapinfo.txt");

		kMIData.Rewind();
		kMIData.ExportToFile(sNameBuff);

		ReplyToCommand(client, "%s has been added to %s.", sCurMap, sNameBuff);
	}

	return Plugin_Handled;
}

static Action MI_KV_CmdSaveLoc(int client, int args)
{
	bool updateinfo = false;
	char sCurMap[128];
	GetCurrentMap(sCurMap, sizeof(sCurMap));

	if (!iIsInEditMode[client]) {
		if (!args) {
			ReplyToCommand(client, "Move to the location of the medkits, then enter the point type (start_point or end_point)");
			return Plugin_Handled;
		}

		char sBuffer[16];
		GetCmdArg(1, sBuffer, sizeof(sBuffer));

		if (strcmp(sBuffer, "start_point", true) == 0) {
			iIsInEditMode[client] = 1;
			ReplyToCommand(client, "Move a few feet from the medkits and enter this command again to set the start_dist for this point");
		} else if (strcmp(sBuffer, "end_point", true) == 0) {
			iIsInEditMode[client] = 2;
			ReplyToCommand(client, "Move to the farthest point in the saferoom and enter this command again to set the end_dist for this point");
		} else {
			ReplyToCommand(client, "Please enter the location type: start_point, end_point");
			return Plugin_Handled;
		}

		if (kMIData.JumpToKey(sCurMap, true)) {
			GetClientAbsOrigin(client, fLocTemp[client]);
			kMIData.SetVector(sBuffer, fLocTemp[client]);
		}

		updateinfo = true;
	} else if (iIsInEditMode[client] == 1) {
		iIsInEditMode[client] = 3;

		float fDistLoc[3], fDistance;
		GetClientAbsOrigin(client, fDistLoc);

		fDistance = GetVectorDistance(fDistLoc, fLocTemp[client]);
		if (kMIData.JumpToKey(sCurMap, true)) {
			kMIData.SetFloat("start_dist", fDistance);
		}

		ReplyToCommand(client, "Move to the farthest point in the saferoom and enter this command again to set start_extra_dist for this point");

		updateinfo = true;
	} else if (iIsInEditMode[client] == 2) {
		iIsInEditMode[client] = 0;

		float fDistLoc[3], fDistance;
		GetClientAbsOrigin(client, fDistLoc);

		fDistance = GetVectorDistance(fDistLoc, fLocTemp[client]);
		if (kMIData.JumpToKey(sCurMap, true)) {
			kMIData.SetFloat("end_dist", fDistance);
		}

		updateinfo = true;
	} else if (iIsInEditMode[client] == 3) {
		iIsInEditMode[client] = 0;

		float fDistLoc[3], fDistance;
		GetClientAbsOrigin(client, fDistLoc);

		fDistance = GetVectorDistance(fDistLoc, fLocTemp[client]);
		if (kMIData.JumpToKey(sCurMap, true)) {
			kMIData.SetFloat("start_extra_dist", fDistance);
		}

		updateinfo = true;
	}

	if (updateinfo) {
		char sNameBuff[PLATFORM_MAX_PATH];
		BuildConfigPath(sNameBuff, sizeof(sNameBuff), "mapinfo.txt");

		kMIData.Rewind();
		kMIData.ExportToFile(sNameBuff);

		ReplyToCommand(client, "mapinfo.txt has been updated!");
	}

	return Plugin_Handled;
}

static void MI_KV_Close()
{
	if (kMIData != null) {
		delete kMIData;
		kMIData = null;
	}
}

static void MI_KV_Load()
{
	char sNameBuff[PLATFORM_MAX_PATH];

	if (MI_bDebugEnabled || IsDebugEnabled()) {
		LogMessage("[%s] Loading MapInfo KeyValues", MI_MODULE_NAME);
	}

	kMIData = new KeyValues("MapInfo");
	BuildConfigPath(sNameBuff, sizeof(sNameBuff), "mapinfo.txt"); //Build our filepath
	if (!kMIData.ImportFromFile(sNameBuff)) {
		Debug_LogError(MI_MODULE_NAME, "Couldn't load MapInfo data!");
		MI_KV_Close();
		return;
	}
}

static void MI_KV_UpdateMapInfo()
{
	char sCurMap[128];
	GetCurrentMap(sCurMap, sizeof(sCurMap));

	if (kMIData.JumpToKey(sCurMap)) {
		kMIData.GetVector("start_point", Start_Point);
		kMIData.GetVector("end_point", End_Point);

		Start_Dist = kMIData.GetFloat("start_dist");
		Start_Extra_Dist = kMIData.GetFloat("start_extra_dist");
		End_Dist = kMIData.GetFloat("end_dist");

		iMapMaxDistance = kMIData.GetNum("max_distance", -1);

		// kMIData.Rewind();
		MapDataAvailable = true;
	} else {
		MapDataAvailable = false;
		Start_Dist = FindStartPointHeuristic(Start_Point);
		if (Start_Dist > 0.0) {
			// This is the largest Start Extra Dist we've encountered;
			// May be too much
			Start_Extra_Dist = 500.0;
		} else {
			ZeroVector(Start_Point);
			Start_Dist = -1.0;
			Start_Extra_Dist = -1.0;
		}

		ZeroVector(End_Point);
		End_Dist = -1.0;
		iMapMaxDistance = -1;
		LogMessage("[%s] MapInfo for %s is missing.", MI_MODULE_NAME, sCurMap);
	}

	// Let's leave MIData on the current map
	// kMIData.Rewind();
}

static float FindStartPointHeuristic(float result[3])
{
	char entclass[MAX_ENTITY_NAME_LENGTH];
	float kitOrigin[4][3], averageOrigin[3];
	int kits = 0, entcount = GetEntityCount();

	for (int iEntity = (MaxClients + 1); iEntity <= entcount && kits < 4; iEntity++) {
		if (!IsValidEdict(iEntity)) {
			continue;
		}

		GetEdictClassname(iEntity, entclass, sizeof(entclass));
		if (strcmp(entclass, "weapon_first_aid_kit_spawn") == 0) {
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", kitOrigin[kits]);
			AddToVector(averageOrigin, kitOrigin[kits]);
			kits++;
		}
	}

	if (kits < 4) {
		return -1.0;
	}

	ScaleVector(averageOrigin, 0.25);

	float greatestDist, tempDist;
	for (int i = 0; i < 4; i++) {
		tempDist = GetVectorDistance(averageOrigin, kitOrigin[i]);

		if (tempDist > greatestDist) {
			greatestDist = tempDist;
		}
	}

	CopyVector(result, averageOrigin);
	return (greatestDist + 1.0);
}

// Old Functions (Avoid using these, use the ones below)
stock float GetMapStartOriginX()
{
	return Start_Point[0];
}

stock float GetMapStartOriginY()
{
	return Start_Point[1];
}

stock float GetMapStartOriginZ()
{
	return Start_Point[2];
}

stock float GetMapEndOriginX()
{
	return End_Point[0];
}

stock float GetMapEndOriginY()
{
	return End_Point[1];
}

stock float GetMapEndOriginZ()
{
	return End_Point[2];
}

// New Super Awesome Functions!!!
stock int GetCustomMapMaxScore()
{
	return iMapMaxDistance;
}

stock bool IsMapDataAvailable()
{
	return MapDataAvailable;
}

/**
 * Determines if an entity is in a start or end saferoom (based on mapinfo.txt or automatically generated info)
 *
 * @param ent			The entity to be checked
 * @param saferoom		START_SAFEROOM (1) = Start saferoom, END_SAFEROOM (2) = End saferoom (including finale area), 3 = both
 * @return				True if it is one of the specified saferoom(s)
 *						False if it is not in the specified saferoom(s)
 *						False if no saferoom specified
 */
stock bool IsEntityInSaferoom(int ent, int saferoom = 3) //ItemTracking (commented out)
{
	float origins[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", origins);

	if ((saferoom & START_SAFEROOM)
		&& (GetVectorDistance(origins, Start_Point) <= ((Start_Extra_Dist > Start_Dist) ? Start_Extra_Dist : Start_Dist))
	) {
		return true;
	} else if ((saferoom & END_SAFEROOM) && (GetVectorDistance(origins, End_Point) <= End_Dist)) {
		return true;
	} else {
		return false;
	}

//	return ((GetVectorDistance(origins, Start_Point) <= ((Start_Extra_Dist > Start_Dist) ? Start_Extra_Dist : Start_Dist))
//		|| (GetVectorDistance(origins, End_Point) <= End_Dist));
}

stock int GetMapValueInt(const char[] key, int defvalue = 0) //BossSpawning
{
	return kMIData.GetNum(key, defvalue);
}

stock float GetMapValueFloat(const char[] key, float defvalue = 0.0) //BossSpawning
{
	return kMIData.GetFloat(key, defvalue);
}

stock void GetMapValueVector(const char[] key, float vector[3], float defvalue[3] = NULL_VECTOR) //BossSpawning
{
	kMIData.GetVector(key, vector, defvalue);
}

stock void GetMapValueString(const char[] key, char[] value, const int maxlength, const char[] defvalue)
{
	kMIData.GetString(key, value, maxlength, defvalue);
}

stock void CopyMapSubsection(KeyValues kv, const char[] section) //ItemTracking
{
	if (kMIData.JumpToKey(section, false)) {
		kv.Import(kMIData); // KvCopySubkeys(kMIData, kv);
		kMIData.GoBack();
	}
}

stock void GetMapStartOrigin(float origin[3]) //not used
{
	origin[0] = Start_Point[0];
	origin[1] = Start_Point[1];
	origin[2] = Start_Point[2];
}

stock void GetMapEndOrigin(float origin[3]) //not used
{
	origin[0] = End_Point[0];
	origin[1] = End_Point[1];
	origin[2] = End_Point[2];
}

stock float GetMapEndDist() //WeaponInformation use it
{
	return End_Dist;
}

stock float GetMapStartDist() //WeaponInformation use it
{
	return Start_Dist;
}

stock float GetMapStartExtraDist() //WeaponInformation use it
{
	return Start_Extra_Dist;
}

// Natives
static int _native_IsMapDataAvailable(Handle plugin, int numParams)
{
	return IsMapDataAvailable();
}

static int _native_GetMapValueInt(Handle plugin, int numParams)
{
	int iLen = 0;
	GetNativeStringLength(1, iLen);

	int iNewLen = iLen + 1;
	char[] sKey = new char[iNewLen];
	GetNativeString(1, sKey, iNewLen);

	int iDefVal = GetNativeCell(2);
	return GetMapValueInt(sKey, iDefVal);
}

#if SOURCEMOD_V_MINOR > 9
static any _native_GetMapValueFloat(Handle plugin, int numParams)
#else
static int _native_GetMapValueFloat(Handle plugin, int numParams)
#endif
{
	int iLen = 0;
	GetNativeStringLength(1, iLen);

	int iNewLen = iLen + 1;
	char[] sKey = new char[iNewLen];
	GetNativeString(1, sKey, iNewLen);

	float iDefVal = GetNativeCell(2);

#if SOURCEMOD_V_MINOR > 9
	return GetMapValueFloat(sKey, iDefVal);
#else
	return view_as<int>(GetMapValueFloat(sKey, iDefVal));
#endif
}

static int _native_GetMapValueVector(Handle plugin, int numParams)
{
	int iLen = 0;
	GetNativeStringLength(1, iLen);

	int iNewLen = iLen + 1;
	char[] sKey = new char[iNewLen];
	GetNativeString(1, sKey, iNewLen);

	float fDefVal[3], fValue[3];
	GetNativeArray(3, fDefVal, sizeof(fDefVal));
	GetMapValueVector(sKey, fValue, fDefVal);

	SetNativeArray(2, fValue, sizeof(fValue));
	return 1;
}

static int _native_GetMapValueString(Handle plugin, int numParams)
{
	int iLen = 0;
	GetNativeStringLength(1, iLen);

	int iNewLen = iLen + 1;
	char[] sKey = new char[iNewLen];
	GetNativeString(1, sKey, iNewLen);

	GetNativeStringLength(4, iLen);

	iNewLen = iLen + 1;
	char[] sDefVal = new char[iNewLen];
	GetNativeString(4, sDefVal, iNewLen);

	iLen = GetNativeCell(3);

	iNewLen = iLen + 1;
	char[] sBuf = new char[iNewLen];
	GetMapValueString(sKey, sBuf, iNewLen, sDefVal);

	SetNativeString(2, sBuf, iNewLen);
	return 1;
}

static int _native_CopyMapSubsection(Handle plugin, int numParams)
{
	int iLen = 0;
	GetNativeStringLength(2, iLen);

	int iNewLen = iLen + 1;
	char[] sKey = new char[iNewLen];
	GetNativeString(2, sKey, iNewLen);

	KeyValues hKv = GetNativeCell(1);
	CopyMapSubsection(hKv, sKey);

	return 1;
}
