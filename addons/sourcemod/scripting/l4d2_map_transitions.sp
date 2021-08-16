#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <colors>

#define DEBUG 0

#define MAP_NAME_MAX_LENGTH 64
#define LEFT4FRAMEWORK_GAMEDATA "left4dhooks.l4d2"

StringMap hMapTransitionPair = null

Handle hSetCampaignScores

int g_iPointsTeamA = 0
int g_iPointsTeamB = 0
bool g_bHasTransitioned = false

public Plugin:myinfo = 
{
	name = "Map Transitions",
	author = "Derpduck",
	description = "Define map transitions to combine campaigns",
	version = "2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public OnPluginStart()
{
	CheckGame()
	LoadSDK()
	
	hMapTransitionPair = new StringMap()
	RegServerCmd("sm_add_map_transition", AddMapTransition)
	
	HookEvent("round_start", OnRoundStart_Event, EventHookMode_PostNoCopy)
}

void CheckGame()
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		SetFailState("Plugin 'Map Transitions' supports Left 4 Dead 2 only!")
	}
}

void LoadSDK()
{
	Handle conf = LoadGameConfigFile(LEFT4FRAMEWORK_GAMEDATA)
	if (conf == INVALID_HANDLE)
	{
		SetFailState("Could not load gamedata/%s.txt", LEFT4FRAMEWORK_GAMEDATA)
	}

	StartPrepSDKCall(SDKCall_GameRules)
	if (!PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "SetCampaignScores"))
	{
		SetFailState("Function 'SetCampaignScores' not found.")
	}
	
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain)
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain)
	hSetCampaignScores = EndPrepSDKCall()
	if (hSetCampaignScores == INVALID_HANDLE)
	{
		SetFailState("Function 'SetCampaignScores' found, but something went wrong.")
	}
	
	delete conf
}

public OnRoundEnd()
{
	int isSecondHalf = InSecondHalfOfRound()
	
	//If map is in last half, attempt a transition
	if (isSecondHalf == 1)
	{
		CreateTimer(15.0, OnRoundEnd_Post) 
	}
}

static Action:OnRoundEnd_Post(Handle timer)
{
	//Check if map has been registered for a map transition
	char currentMapName[MAP_NAME_MAX_LENGTH]
	char nextMapName[MAP_NAME_MAX_LENGTH]
	
	GetCurrentMap(currentMapName, sizeof(currentMapName))
	
	//We have a map to transition to
	if (hMapTransitionPair.GetString(currentMapName, nextMapName, sizeof(nextMapName)))
	{
		//Preserve scores between transitions
		g_iPointsTeamA = L4D2Direct_GetVSCampaignScore(0)
		g_iPointsTeamB = L4D2Direct_GetVSCampaignScore(1)
		g_bHasTransitioned = true
		
		#if DEBUG
			LogMessage("Map transitioned from: %s to: %s", currentMapName, nextMapName)
		#endif
		
		CPrintToChatAll("{olive}[MT]{default} Starting transition from: {blue}%s{default} to: {blue}%s", currentMapName, nextMapName)
		ForceChangeLevel(nextMapName, "Map Transitions")
	}
}

static void OnRoundStart_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int isSecondHalf = InSecondHalfOfRound()
	
	//Set scores after a modified transition
	if (g_bHasTransitioned && isSecondHalf == 0)
	{
		CreateTimer(5.0, SetScores) //We need to do this before l4d_tank_control_eq checks scores (at 10 seconds)
		g_bHasTransitioned = false
	}
}

static Action:SetScores(Handle timer)
{
	//Set scores on scoreboard
	SDKCall(hSetCampaignScores, g_iPointsTeamA, g_iPointsTeamB)
	
	//Set actual scores
	L4D2Direct_SetVSCampaignScore(0, g_iPointsTeamA)
	L4D2Direct_SetVSCampaignScore(1, g_iPointsTeamB)
	
	#if DEBUG
		LogMessage("Set scores to: (Survivors) %i vs (Infected) %i", g_iPointsTeamA, g_iPointsTeamB)
	#endif
	
	CreateTimer(10.0, PrintScores_Delay)
}

static Action:PrintScores_Delay(Handle timer)
{
	//Print scores, teams will not be flipped because the game thinks we have started a new match
	CPrintToChatAll("{olive}[MT]{default} Set scores to: {blue}(Survivors) %i{default} vs {blue}(Infected) %i{default}", g_iPointsTeamA, g_iPointsTeamB)
}

static Action:AddMapTransition(int args)
{
	if (args != 2)
	{
		PrintToServer("Usage: sm_add_map_transition <starting map name> <ending map name>")
		LogError("Usage: sm_add_map_transition <starting map name> <ending map name>")
		return Plugin_Handled;
	}
	
	//Read map pair names
	char mapStart[MAP_NAME_MAX_LENGTH]
	char mapEnd[MAP_NAME_MAX_LENGTH]
	GetCmdArg(1, mapStart, sizeof(mapStart))
	GetCmdArg(2, mapEnd, sizeof(mapEnd))
	
	hMapTransitionPair.SetString(mapStart, mapEnd, true)
	
	return Plugin_Handled;
}

//Return if round is first or second half
stock InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound");
}
