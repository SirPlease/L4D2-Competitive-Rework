#pragma semicolon 1
//強制1.7以後的新語法
#pragma newdecls required
#include <sourcemod>
#define PLUGIN_VERSION	"1.0.2"
#define WITCH_LEN		32
int witchCUR;
int witchID[WITCH_LEN];

public Plugin myinfo = 
{
	name 			= "l4d2_GetWitchNumber",
	author 			= "豆瓣酱な",
	description 	= "给女巫添加自定义编号,例如:witch(1)",
	version 		= PLUGIN_VERSION,
	url 			= "N/A"
}
/*
** 改功能嫖至作者 NiCo-op, Edited By Ernecio (Satanael) 的,链接没找到.
*/
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("GetWitchNumber", GetWitchNumberNative);
	RegPluginLibrary("l4d2_GetWitchNumber");
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("round_start",  Event_RoundStart, EventHookMode_Pre);//回合开始.
	HookEvent("witch_spawn",  Event_WitchSpawn, EventHookMode_Pre);//女巫出现.
	HookEvent("witch_killed", Event_Witchkilled, EventHookMode_Pre);//女巫死亡.
}

public void Event_RoundStart(Event event, const char[] sName, bool bDontBroadcast)
{
	witchCUR = 0;
	for(int i = 0; i < WITCH_LEN; i ++)
		witchID[i] = -1;
}

public void Event_WitchSpawn(Event event, const char[] sName, bool bDontBroadcast)
{
	int iWitchid = event.GetInt( "witchid");
	witchID[witchCUR] = iWitchid;
	witchCUR = (witchCUR + 1) % WITCH_LEN;
}

public void Event_Witchkilled(Event event, const char[] name, bool dontBroadcast)
{
	int iWitchid = event.GetInt("witchid" );
	
	for(int i = 0; i < WITCH_LEN; i ++)
	{
		if(witchID[i] == iWitchid)
		{
			witchID[i] = -1;
			break;
		}
	}
}

int GetWitchNumberNative(Handle plugin, int numParams)
{
	int iWitchid = GetNativeCell(1);
	return GetWitchID(iWitchid);
}

int GetWitchID(int entity)
{
	for(int i = 0; i < sizeof(witchID); i ++)
		if(witchID[i] == entity)
			return i;
	
	return -1;
}