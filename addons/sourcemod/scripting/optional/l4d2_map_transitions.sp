#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
//#include <l4d2_direct>
//#include <left4downtown>
#include <left4dhooks>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>
#include <colors>

#define DEBUG 0

#define MAP_NAME_MAX_LENGTH 64

StringMap
	g_hMapTransitionPair = null;

int
	g_iPointsTeamA = 0,
	g_iPointsTeamB = 0;

bool
	g_bHasTransitioned = false;

Handle
	g_hTransitionTimer;

public Plugin myinfo =
{
	name = "Map Transitions",
	author = "Derpduck, Forgetest",
	description = "Define map transitions to combine campaigns",
	version = "3.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	CheckGame();

	g_hMapTransitionPair = new StringMap();

	RegServerCmd("sm_add_map_transition", AddMapTransition);
}

void CheckGame()
{
	if (GetEngineVersion() != Engine_Left4Dead2) {
		SetFailState("Plugin 'Map Transitions' supports Left 4 Dead 2 only!");
	}
}

public void L4D2_OnEndVersusModeRound_Post() //left4dhooks
{
	//If map is in last half, attempt a transition
	if (InSecondHalfOfRound()) {
		g_hTransitionTimer = CreateTimer(15.0, OnRoundEnd_Post);

		#if DEBUG
			PrintToChatAll("L4D2_OnEndVersusModeRound_Post");
		#endif
	}
}

Action OnRoundEnd_Post(Handle hTimer)
{
	g_hTransitionTimer = null;
	
	//Check if map has been registered for a map transition
	char sCurrentMapName[MAP_NAME_MAX_LENGTH], sNextMapName[MAP_NAME_MAX_LENGTH];
	GetCurrentMapLower(sCurrentMapName, sizeof(sCurrentMapName));

	//We have a map to transition to
	if (g_hMapTransitionPair.GetString(sCurrentMapName, sNextMapName, sizeof(sNextMapName))) {
		//Preserve scores between transitions
		g_iPointsTeamA = L4D2Direct_GetVSCampaignScore(0);
		g_iPointsTeamB = L4D2Direct_GetVSCampaignScore(1);
		g_bHasTransitioned = true;

		#if DEBUG
			LogMessage("Map transitioned from: %s to: %s", sCurrentMapName, sNextMapName);
		#endif

		CPrintToChatAll("{olive}[MT]{default} Starting transition from: {blue}%s{default} to: {blue}%s", sCurrentMapName, sNextMapName);
		ForceChangeLevel(sNextMapName, "Map Transitions");
	}

	return Plugin_Stop;
}

public void OnMapEnd()
{
	//In case map is force-chenged before custom transition takes place
	if (g_hTransitionTimer != null) {
		g_bHasTransitioned = false;
		delete g_hTransitionTimer;
	}
}

public void OnMapStart()
{
	//Set scores after a modified transition
	if (g_bHasTransitioned) {
		CreateTimer(1.0, Timer_OnMapStartDelay, _, TIMER_FLAG_NO_MAPCHANGE); //Clients have issues connecting if team swap happens exactly on map start, so we delay it
		g_bHasTransitioned = false;
	}
}

Action Timer_OnMapStartDelay(Handle hTimer)
{
	SetScores();

	return Plugin_Stop;
}

void SetScores()
{
	//If team B is winning, swap teams. Does not change how scores are set
	if (g_iPointsTeamA < g_iPointsTeamB) {
		L4D2_SwapTeams();

		#if DEBUG
			LogMessage("Teams swapped");
		#endif
	}

	//Set actual scores
	L4D2Direct_SetVSCampaignScore(0, g_iPointsTeamA);
	L4D2Direct_SetVSCampaignScore(1, g_iPointsTeamB);
	GameRules_SetProp("m_iCampaignScore", g_iPointsTeamA, _, 0);
	GameRules_SetProp("m_iCampaignScore", g_iPointsTeamB, _, 1);

	#if DEBUG
		LogMessage("Set scores to: (Survivors) %i vs (Infected) %i", g_iPointsTeamA, g_iPointsTeamB);
	#endif
}

Action AddMapTransition(int iArgs)
{
	if (iArgs != 2) {
		PrintToServer("Usage: sm_add_map_transition <starting map name> <ending map name>");
		LogError("Usage: sm_add_map_transition <starting map name> <ending map name>");
		return Plugin_Handled;
	}

	//Read map pair names
	char sMapStart[MAP_NAME_MAX_LENGTH], sMapEnd[MAP_NAME_MAX_LENGTH];
	GetCmdArg(1, sMapStart, sizeof(sMapStart));
	GetCmdArg(2, sMapEnd, sizeof(sMapEnd));
	String_ToLower(sMapStart, sizeof(sMapStart));
	String_ToLower(sMapEnd, sizeof(sMapEnd));

	g_hMapTransitionPair.SetString(sMapStart, sMapEnd, true);
	return Plugin_Handled;
}

int GetCurrentMapLower(char[] buffer, int maxlength)
{
	int bytes = GetCurrentMap(buffer, maxlength);
	if (bytes) String_ToLower(buffer, maxlength);
	return bytes;
}
