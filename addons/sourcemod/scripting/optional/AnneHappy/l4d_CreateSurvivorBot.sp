#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION 				"1.0"

public Plugin myinfo = 
{
	name 			= "[L4D1 & L4D2] CreateSurvivorBot",
	author 			= "MicroLeo (port by Dragokas)",
	description 	= "Provides CreateSurvivorBot Native",
	version 		= PLUGIN_VERSION,
	url 			= "https://github.com/dragokas"
}

Handle g_hSDK_RespawnPlayer;
Handle g_hSDK_NextBotCreatePlayerBot;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("NextBotCreatePlayerBotSurvivorBot", NATIVE_NextBotCreatePlayerBotSurvivorBot);
	CreateNative("CTerrorPlayerRoundRespawn", NATIVE_CTerrorPlayerRoundRespawn);
	return APLRes_Success;
}

public void OnPluginStart()
{
	GameData hGameData = LoadGameConfigFile("CreateSurvivorBot");
	if( hGameData == null ) SetFailState("Could not find gamedata file at addons/sourcemod/gamedata/CreateSurvivorBot.txt , you FAILED AT INSTALLING");
	
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::RoundRespawn") == false )
		SetFailState("Failed to find signature: CTerrorPlayer::RoundRespawn");
	g_hSDK_RespawnPlayer = EndPrepSDKCall();
	if( g_hSDK_RespawnPlayer == null ) SetFailState("Failed to create SDKCall: CTerrorPlayer::RoundRespawn");
	
	StartPrepSDKCall(SDKCall_Static);
	Address addr = hGameData.GetAddress("NextBotCreatePlayerBot<SurvivorBot>");
	if( addr == Address_Null ) SetFailState("Failed to find signature: NextBotCreatePlayerBot<SurvivorBot> in CDirector::AddSurvivorBot");
	int iOS = hGameData.GetOffset("OS"); // 1 - windows, 2 - linux
	if( iOS == 1 ) // it's hard to get uniq. sig in windows => will use XRef.
	{
		Address offset = view_as<Address>(LoadFromAddress(addr + view_as<Address>(1), NumberType_Int32));
		addr += offset + view_as<Address>(5); // sizeof(instruction)
	}
	if( PrepSDKCall_SetAddress(addr) == false )	SetFailState("Failed to find signature: NextBotCreatePlayerBot<SurvivorBot>");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_NextBotCreatePlayerBot = EndPrepSDKCall();
	if( g_hSDK_NextBotCreatePlayerBot == null ) SetFailState("Failed to create SDKCall: NextBotCreatePlayerBot<SurvivorBot>");
	
	delete hGameData;
}

public int NATIVE_NextBotCreatePlayerBotSurvivorBot(Handle plugin, int numParams)
{
	char szName[MAX_NAME_LENGTH];
	
	if( numParams == 1 )
		GetNativeString(1, szName, sizeof(szName));
	
	return SDKCall(g_hSDK_NextBotCreatePlayerBot, NULL_STRING);
}

public int NATIVE_CTerrorPlayerRoundRespawn(Handle plugin, int numParams)
{
	if( numParams < 1 )
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	int bot = GetNativeCell(1);
	SDKCall(g_hSDK_RespawnPlayer, bot);
	return true;
}

/* // All-in-one sample:

stock int CreateSurvivorBot()
{
	int bot = SDKCall(g_hSDK_NextBotCreatePlayerBot, NULL_STRING);
	if( IsValidEntity(bot) )
	{
		ChangeClientTeam(bot, 2);
		
		if( !IsPlayerAlive(bot) )
		{
			SDKCall(g_hSDK_RespawnPlayer, bot);
		}
		return bot;
	}
	return -1;
}
*/