#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <confogl.inc>

#if defined __mapinfo__
#endinput
#endif
#define __mapinfo__

new Handle:kMIData = INVALID_HANDLE;

enum Saferoom {
	Saferoom_Neither = 0,
	Saferoom_Start = 1,
	Saferoom_End = 2,
	Saferoom_Both = 3
};

static bool:MapDataAvailable;
static Float:Start_Point[3];
static Float:End_Point[3];
static Float:Start_Dist;
static Float:Start_Extra_Dist;
static Float:End_Dist;

static iIsInEditMode[MAXPLAYERS+1];
static Float:fLocTemp[MAXPLAYERS+1][3];

MapInfo_Init()
{
	MI_KV_Load();
	
	// RegAdminCmd("confogl_midata_reload", MI_KV_CmdReload, ADMFLAG_CONFIG);
	RegAdminCmd("confogl_midata_save", MI_KV_CmdSave, ADMFLAG_CONFIG);
	RegAdminCmd("confogl_save_location", MI_KV_CmdSaveLoc, ADMFLAG_CONFIG);
}

MapInfo_OnMapStart_Update()
{
	MI_KV_UpdateMapInfo();
}

MapInfo_OnMapEnd_Update()
{
	KvRewind(kMIData);
	MapDataAvailable = false;
	for (new i; i <= MAXPLAYERS; i++) iIsInEditMode[i] = 0;
}

MapInfo_OnPluginEnd()
{
	MI_KV_Close();
}

MapInfo_PlayerDisconnect_Event(Handle:event)
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
		LGO_BuildConfigPath(sNameBuff, sizeof(sNameBuff), "mapinfo.txt");
		
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
		LGO_BuildConfigPath(sNameBuff, sizeof(sNameBuff), "mapinfo.txt");
		
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

	kMIData = CreateKeyValues("MapInfo");
	LGO_BuildConfigPath(sNameBuff, sizeof(sNameBuff), "mapinfo.txt"); //Build our filepath
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
			Start_Point = NULL_VECTOR;
			Start_Dist = -1.0;
			Start_Extra_Dist = -1.0;
		}
		
		End_Point = NULL_VECTOR;
		End_Dist = -1.0;
		LogMessage("[MI] MapInfo for %s is missing.", sCurMap);
	}
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
			averageOrigin[0] += kitOrigin[kits][0];
			averageOrigin[1] += kitOrigin[kits][1];
			averageOrigin[2] += kitOrigin[kits][2];
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
	result = averageOrigin;
	return greatestDist+1.0;
}

/* NATIVE FUNCTIONS */
// New Super Awesome Functions!!!

stock bool:IsMapDataAvailable() return MapDataAvailable;

/**
 * Determines if an entity is in a start or end saferoom (based on mapinfo.txt or automatically generated info)
 *
 * @param ent			The entity to be checked
 * @return				Saferoom_Neither if entity is not in any saferoom
 *						Saferoom_Start if it is in the starting saferoom
 *						Saferoom_End if it is in the ending saferoom
 *						Saferoom_Start | Saferoom_End if it is in both saferooms (probably won't happen)
 */
stock Saferoom:IsEntityInSaferoom(ent)
{
	new Saferoom:result=Saferoom_Neither;
	decl Float:origins[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", origins);
	
	if ((GetVectorDistance(origins, Start_Point) <= (Start_Extra_Dist > Start_Dist ? Start_Extra_Dist : Start_Dist)))
	{
		result |= Saferoom_Start;
	}
	if (GetVectorDistance(origins, End_Point) <= End_Dist)
	{
		result |= Saferoom_End;
	}
	return result;
}

stock GetMapValueInt(const String:key[], const defvalue=0) 
{
	return KvGetNum(kMIData, key, defvalue); 
}
stock Float:GetMapValueFloat(const String:key[], const Float:defvalue=0.0) 
{
	return KvGetFloat(kMIData, key, defvalue); 
}
stock GetMapValueVector(const String:key[], Float:vector[3], const Float:defvalue[3]=NULL_VECTOR) 
{
	KvGetVector(kMIData, key, vector, defvalue);
}

stock GetMapValueString(const String:key[], String:value[], maxlength, const String:defvalue[]="")
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
	origin = Start_Point;
}

stock GetMapEndOrigin(Float:origin[3])
{
	origin = End_Point;
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