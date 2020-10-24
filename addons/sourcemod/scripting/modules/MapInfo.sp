#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define DEBUG_MI					0

new Handle:kMIData = INVALID_HANDLE;

static bool:MapDataAvailable;
static Float:Start_Point[3];
static Float:End_Point[3];
static Float:Start_Dist;
static Float:Start_Extra_Dist;
static Float:End_Dist;

static iMapMaxDistance;
static iIsInEditMode[MAXPLAYERS+1];
static Float:fLocTemp[MAXPLAYERS+1][3];

public MI_OnModuleStart()
{
	MI_KV_Load();
	
	// RegAdminCmd("confogl_midata_reload", MI_KV_CmdReload, ADMFLAG_CONFIG);
	RegAdminCmd("confogl_midata_save", MI_KV_CmdSave, ADMFLAG_CONFIG);
	RegAdminCmd("confogl_save_location", MI_KV_CmdSaveLoc, ADMFLAG_CONFIG);
	
	HookEvent("player_disconnect", PlayerDisconnect_Event);
}

MI_APL()
{
	CreateNative("LGO_IsMapDataAvailable", _native_IsMapDataAvailable);
	CreateNative("LGO_GetMapValueInt", _native_GetMapValueInt);
	CreateNative("LGO_GetMapValueFloat", _native_GetMapValueFloat);
	CreateNative("LGO_GetMapValueVector", _native_GetMapValueVector);
	CreateNative("LGO_GetMapValueString", _native_GetMapValueString);
	CreateNative("LGO_CopyMapSubsection", _native_CopyMapSubsection);
}

public MI_OnMapStart()
{
	MI_KV_UpdateMapInfo();
}

public MI_OnMapEnd()
{
	KvRewind(kMIData);
	MapDataAvailable = false;
	for (new i; i <= MAXPLAYERS; i++) iIsInEditMode[i] = 0;
}

public MI_OnModuleEnd()
{
	MI_KV_Close();
}

public PlayerDisconnect_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > -1 && client <= MAXPLAYERS) iIsInEditMode[client] = 0;
}

public Action:MI_KV_CmdSave(client, args)
{
	decl String:sCurMap[128];
	GetCurrentMap(sCurMap, sizeof(sCurMap));
	
	if (KvJumpToKey(kMIData, sCurMap, true))
	{
		KvSetVector(kMIData, "start_point", Start_Point);
		KvSetFloat(kMIData, "start_dist", Start_Dist);
		KvSetFloat(kMIData, "start_extra_dist", Start_Extra_Dist);
		
		decl String:sNameBuff[PLATFORM_MAX_PATH];
		BuildConfigPath(sNameBuff, sizeof(sNameBuff), "mapinfo.txt");
		
		KvRewind(kMIData);
		
		KeyValuesToFile(kMIData, sNameBuff);
		
		ReplyToCommand(client, "%s has been added to %s.", sCurMap, sNameBuff);
	}
}

public Action:MI_KV_CmdSaveLoc(client, args)
{
	new bool:updateinfo;
	decl String:sCurMap[128];
	GetCurrentMap(sCurMap, sizeof(sCurMap));
	
	if (!iIsInEditMode[client])
	{
		if (!args)
		{
			ReplyToCommand(client, "Move to the location of the medkits, then enter the point type (start_point or end_point)");
			return Plugin_Handled;
		}
		
		decl String:sBuffer[16];
		GetCmdArg(1, sBuffer, sizeof(sBuffer));
		
		if (StrEqual(sBuffer, "start_point", true))
		{
			iIsInEditMode[client] = 1;
			ReplyToCommand(client, "Move a few feet from the medkits and enter this command again to set the start_dist for this point");
		}
		else if (StrEqual(sBuffer, "end_point", true))
		{
			iIsInEditMode[client] = 2;
			ReplyToCommand(client, "Move to the farthest point in the saferoom and enter this command again to set the end_dist for this point");
		}
		else
		{
			ReplyToCommand(client, "Please enter the location type: start_point, end_point");
			return Plugin_Handled;
		}
		
		if (KvJumpToKey(kMIData, sCurMap, true))
		{
			GetClientAbsOrigin(client, fLocTemp[client]);
			KvSetVector(kMIData, sBuffer, fLocTemp[client]);
		}
		updateinfo = true;
	}
	else if (iIsInEditMode[client] == 1)
	{
		iIsInEditMode[client] = 3;
		decl Float:fDistLoc[3], Float:fDistance;
		GetClientAbsOrigin(client, fDistLoc);
		fDistance = GetVectorDistance(fDistLoc, fLocTemp[client]);
		if (KvJumpToKey(kMIData, sCurMap, true)) KvSetFloat(kMIData, "start_dist", fDistance);
		
		ReplyToCommand(client, "Move to the farthest point in the saferoom and enter this command again to set start_extra_dist for this point");
		
		updateinfo = true;
	}
	else if (iIsInEditMode[client] == 2)
	{
		iIsInEditMode[client] = 0;
		decl Float:fDistLoc[3], Float:fDistance;
		GetClientAbsOrigin(client, fDistLoc);
		fDistance = GetVectorDistance(fDistLoc, fLocTemp[client]);
		if (KvJumpToKey(kMIData, sCurMap, true)) KvSetFloat(kMIData, "end_dist", fDistance);
		
		updateinfo = true;
	}
	else if (iIsInEditMode[client] == 3)
	{
		iIsInEditMode[client] = 0;
		decl Float:fDistLoc[3], Float:fDistance;
		GetClientAbsOrigin(client, fDistLoc);
		fDistance = GetVectorDistance(fDistLoc, fLocTemp[client]);
		if (KvJumpToKey(kMIData, sCurMap, true)) KvSetFloat(kMIData, "start_extra_dist", fDistance);
		
		updateinfo = true;
	}
	
	if (updateinfo)
	{
		decl String:sNameBuff[PLATFORM_MAX_PATH];
		BuildConfigPath(sNameBuff, sizeof(sNameBuff), "mapinfo.txt");
		
		KvRewind(kMIData);
		KeyValuesToFile(kMIData, sNameBuff);
		
		ReplyToCommand(client, "mapinfo.txt has been updated!");
	}
	
	return Plugin_Handled;
}

MI_KV_Close()
{
	if(kMIData == INVALID_HANDLE) return;
	CloseHandle(kMIData);
	kMIData = INVALID_HANDLE;
}

MI_KV_Load()
{
	decl String:sNameBuff[PLATFORM_MAX_PATH];
	
	if(DEBUG_MI || IsDebugEnabled())
		LogMessage("[MI] Loading MapInfo KeyValues");

	kMIData = CreateKeyValues("MapInfo");
	BuildConfigPath(sNameBuff, sizeof(sNameBuff), "mapinfo.txt"); //Build our filepath
	if (!FileToKeyValues(kMIData, sNameBuff))
	{
		LogError("[MI] Couldn't load MapInfo data!");
		MI_KV_Close();
		return;
	}
}

MI_KV_UpdateMapInfo()
{
	decl String:sCurMap[128];
	GetCurrentMap(sCurMap, sizeof(sCurMap));
	
	if (KvJumpToKey(kMIData, sCurMap))
	{
		KvGetVector(kMIData, "start_point", Start_Point);
		KvGetVector(kMIData, "end_point", End_Point);
		Start_Dist = KvGetFloat(kMIData, "start_dist");
		Start_Extra_Dist = KvGetFloat(kMIData, "start_extra_dist");
		End_Dist = KvGetFloat(kMIData, "end_dist");
		iMapMaxDistance = KvGetNum(kMIData, "max_distance", -1);
		
		// KvRewind(kMIData);
		MapDataAvailable = true;
	}
	else
	{
		MapDataAvailable = false;
		Start_Dist = FindStartPointHeuristic(Start_Point);
		if(Start_Dist > 0.0)
		{
			// This is the largest Start Extra Dist we've encountered;
			// May be too much
			Start_Extra_Dist = 500.0;
		}
		else
		{
			ZeroVector(Start_Point);
			Start_Dist = -1.0;
			Start_Extra_Dist = -1.0;
		}
		
		ZeroVector(End_Point);
		End_Dist = -1.0;
		iMapMaxDistance = -1;
		LogMessage("[MI] MapInfo for %s is missing.", sCurMap);
	}
	
	// Let's leave MIData on the current map
	//KvRewind(kMIData);
}

static stock Float:FindStartPointHeuristic(Float:result[3])
{
	new kits;
	new Float:kitOrigin[4][3];
	new Float:averageOrigin[3];
	new entcount = GetEntityCount();
	decl String:entclass[128];
	for(new iEntity = 1;iEntity<=entcount && kits <4;iEntity++)
	{
		if(!IsValidEdict(iEntity) || !IsValidEntity(iEntity)){continue;}
		GetEdictClassname(iEntity,entclass,sizeof(entclass));
		if(StrEqual(entclass, "weapon_first_aid_kit_spawn"))
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", kitOrigin[kits]);
			AddToVector(averageOrigin, kitOrigin[kits]);
			kits++;
		}
	}
	if(kits < 4) return -1.0;
	ScaleVector(averageOrigin, 0.25);
	
	new Float:greatestDist, Float:tempDist;
	for(new i; i < 4; i++)
	{
		tempDist = GetVectorDistance(averageOrigin, kitOrigin[i]);
		if (tempDist > greatestDist) greatestDist = tempDist;
	}
	CopyVector(result, averageOrigin);
	return greatestDist+1.0;
}

// Old Functions (Avoid using these, use the ones below)
stock Float:GetMapStartOriginX()
{
	return Start_Point[0];
}

stock Float:GetMapStartOriginY()
{
	return Start_Point[1];
}

stock Float:GetMapStartOriginZ()
{
	return Start_Point[2];
}

stock Float:GetMapEndOriginX()
{
	return End_Point[0];
}

stock Float:GetMapEndOriginY()
{
	return End_Point[1];
}

stock Float:GetMapEndOriginZ()
{
	return End_Point[2];
}

// New Super Awesome Functions!!!

stock bool:IsMapFinale() return L4D_IsMissionFinalMap();

stock GetCustomMapMaxScore() return iMapMaxDistance;

stock GetMapMaxScore() return L4D_GetVersusMaxCompletionScore();

stock SetMapMaxScore(score) L4D_SetVersusMaxCompletionScore(score);

stock bool:IsMapDataAvailable() return MapDataAvailable;


/**
 * Determines if an entity is in a start or end saferoom (based on mapinfo.txt or automatically generated info)
 *
 * @param ent			The entity to be checked
 * @param saferoom		START_SAFEROOM (1) = Start saferoom, END_SAFEROOM (2) = End saferoom (including finale area), 3 = both
 * @return				True if it is one of the specified saferoom(s)
 *						False if it is not in the specified saferoom(s)
 *						False if no saferoom specified
 */
stock bool:IsEntityInSaferoom(ent, saferoom = 3)
{
	decl Float:origins[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", origins);
	
	if ((saferoom & START_SAFEROOM) && (GetVectorDistance(origins, Start_Point) <= (Start_Extra_Dist > Start_Dist ? Start_Extra_Dist : Start_Dist))) return true;
	else if ((saferoom & END_SAFEROOM) && (GetVectorDistance(origins, End_Point) <= End_Dist)) return true;
	else return false;
//	return ((GetVectorDistance(origins, Start_Point) <= (Start_Extra_Dist > Start_Dist ? Start_Extra_Dist : Start_Dist)) 
//		|| (GetVectorDistance(origins, End_Point) <= End_Dist));
}

stock GetMapValueInt(const String:key[], defvalue=0) 
{
	return KvGetNum(kMIData, key, defvalue); 
}
stock Float:GetMapValueFloat(const String:key[], Float:defvalue=0.0) 
{
	return KvGetFloat(kMIData, key, defvalue); 
}
stock GetMapValueVector(const String:key[], Float:vector[3], Float:defvalue[3]=NULL_VECTOR) 
{
	KvGetVector(kMIData, key, vector, defvalue);
}
stock GetMapValueString(const String:key[], String:value[], maxlength, const String:defvalue[])
{
	KvGetString(kMIData, key, value, maxlength, defvalue);
}

stock CopyMapSubsection(Handle:kv, const String:section[])
{
	if(KvJumpToKey(kMIData, section, false))
	{
		KvCopySubkeys(kMIData, kv);
		KvGoBack(kMIData);
	}
}

stock GetMapStartOrigin(Float:origin[3])
{
	origin[0] = Start_Point[0];
	origin[1] = Start_Point[1];
	origin[2] = Start_Point[2];
}

stock GetMapEndOrigin(Float:origin[3])
{
	origin[0] = End_Point[0];
	origin[1] = End_Point[1];
	origin[2] = End_Point[2];
}

stock Float:GetMapEndDist()
{
	return End_Dist;
}

stock Float:GetMapStartDist()
{
	return Start_Dist;
}

stock Float:GetMapStartExtraDist()
{
	return Start_Extra_Dist;
}

public _native_IsMapDataAvailable(Handle:plugin, numParams)
{
	return IsMapDataAvailable();
}

public _native_GetMapValueInt(Handle:plugin, numParams)
{
	decl len, defval;
	
	GetNativeStringLength(1, len);
	new String:key[len+1];
	GetNativeString(1, key, len+1);
	
	defval = GetNativeCellRef(2);
	
	return GetMapValueInt(key, defval);
}

public _native_GetMapValueFloat(Handle:plugin, numParams)
{
	decl len, Float:defval;
	
	GetNativeStringLength(1, len);
	new String:key[len+1];
	GetNativeString(1, key, len+1);
	
	defval = GetNativeCellRef(2);
	
	return _:GetMapValueFloat(key, defval);
}

public _native_GetMapValueVector(Handle:plugin, numParams)
{
	decl len, Float:defval[3], Float:value[3];
	
	GetNativeStringLength(1, len);
	new String:key[len+1];
	GetNativeString(1, key, len+1);
	
	GetNativeArray(3, defval, 3);
	
	GetMapValueVector(key, value, defval);
	
	SetNativeArray(2, value, 3);
}

public _native_GetMapValueString(Handle:plugin, numParams)
{
	decl len;
	GetNativeStringLength(1, len);
	new String:key[len+1];
	GetNativeString(1, key, len+1);
	
	GetNativeStringLength(4, len);
	new String:defval[len+1];
	GetNativeString(4, defval, len+1);
	
	len = GetNativeCell(3);
	new String:buf[len+1];
	
	GetMapValueString(key, buf, len, defval);
	
	SetNativeString(2, buf, len);
}

public _native_CopyMapSubsection(Handle:plugin, numParams)
{
	decl len, Handle:kv;
	GetNativeStringLength(2, len);
	new String:key[len+1];
	GetNativeString(2, key, len+1);
	
	kv = GetNativeCell(1);
	
	CopyMapSubsection(kv, key);
}
