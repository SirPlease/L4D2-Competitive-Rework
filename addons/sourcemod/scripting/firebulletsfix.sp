#pragma newdecls required
#pragma semicolon 1 

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

Handle g_hWeapon_ShootPosition = INVALID_HANDLE;
// Handle g_hWeapon_ShootPosition_SDKCall = INVALID_HANDLE;
float  g_vecOldWeaponShootPos[MAXPLAYERS + 1][3];
// bool   g_bCallingWeapon_ShootPosition = false;

public Plugin myinfo =
{
	name = "Bullet position fix",
	author = "xutaxkamay",
	description = "Fixes shoot position",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2646571"
};

public void OnPluginStart()
{
	Handle gameData = LoadGameConfigFile("dhooks.weapon_shootposition");
	
	if (gameData == INVALID_HANDLE)
	{
		SetFailState("[FireBullets Fix] No game data present");
	}

	/*
	StartPrepSDKCall(SDKCall_Player);

	if (!PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "Weapon_ShootPosition"))
	{
		SetFailState("[FireBullets Fix] couldn't read config for preparing Weapon_ShootPosition SDKCall");
	}

	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
	// Crashes the game...
	g_hWeapon_ShootPosition_SDKCall = EndPrepSDKCall();
	
	if (g_hWeapon_ShootPosition_SDKCall == INVALID_HANDLE)
	{
		SetFailState("[FireBullets Fix] couldn't prepare Weapon_ShootPosition SDKCall");
	}
	*/
			
	int offset = GameConfGetOffset(gameData, "Weapon_ShootPosition");

	if (offset == -1)
	{
		SetFailState("[FireBullets Fix] failed to find offset");
	}

	LogMessage("Found offset for Weapon_ShootPosition %d", offset);

	g_hWeapon_ShootPosition = DHookCreate(offset, HookType_Entity, ReturnType_Vector, ThisPointer_CBaseEntity);

	if (g_hWeapon_ShootPosition == INVALID_HANDLE)
	{
		SetFailState("[FireBullets Fix] couldn't hook Weapon_ShootPosition");
	}

	CloseHandle(gameData);

	for (int client = 1; client <= MaxClients; client++)
		OnClientPutInServer(client);
}

public void OnClientPutInServer(int client)
{
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		DHookEntity(g_hWeapon_ShootPosition, true, client, _, Weapon_ShootPosition_Post);
	}
}

public Action OnPlayerRunCmd(int client)
{	
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		GetClientEyePosition(client, g_vecOldWeaponShootPos[client]);
		/*
		g_bCallingWeapon_ShootPosition = true;
		SDKCall(g_hWeapon_ShootPosition_SDKCall, client, g_vecOldWeaponShootPos[client]); 
		g_bCallingWeapon_ShootPosition = false;
		*/
	}
		
	return Plugin_Continue;
}

public MRESReturn Weapon_ShootPosition_Post(int client, Handle hReturn)
{
	/*
	if (!g_bCallingWeapon_ShootPosition)
	{
	*/
		// At this point we always want to use our old origin.
		DHookSetReturnVector(hReturn, g_vecOldWeaponShootPos[client]);
		return MRES_Supercede;
	/*
	}
	else 
	{
		// Otherwhise we just let it call.
		return MRES_Ignored;
	}
	*/
}

