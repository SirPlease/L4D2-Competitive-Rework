#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define L4D2_TEAM_SPECTATOR 1
#define L4D2_TEAM_SURVIVOR 2
#define L4D2_TEAM_INFECTED 3

bool fixTeam = false;

ArrayList winners;
ArrayList losers;

int 
    g_iRoundStart, 
    g_iPlayerSpawn;


public Plugin myinfo =
{
	name = "L4D2 - Fix team shuffle",
	author = "Altair Sossai",
	description = "Fix teams shuffling during map switching",
	version = "1.0.1",
	url = "https://github.com/altair-sossai/l4d2-zone-server"
};

public void OnPluginStart()
{
	HookEvent("round_start", 			Event_RoundStart);
	HookEvent("player_spawn",           Event_PlayerSpawn);
	HookEvent("player_team", 			PlayerTeam_Event, EventHookMode_Post);
	HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("map_transition", 		Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("mission_lost", 			Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("finale_vehicle_leaving", Event_RoundEnd,		EventHookMode_PostNoCopy);


	winners = CreateArray(64);
	losers = CreateArray(64);
}

public void OnMapEnd()
{
    ClearDefault();
}

public void OnRoundIsLive()
{
	DisableFixTeam();
	ClearTeamsData();
}

public void L4D2_OnEndVersusModeRound_Post()
{
	SaveTeams();
}

void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(0.1, Timer_PluginStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{ 
    if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
        CreateTimer(0.1, Timer_PluginStart, _, TIMER_FLAG_NO_MAPCHANGE);
    g_iPlayerSpawn = 1;	
}

Action Timer_PluginStart(Handle timer)
{
	ClearDefault();

	DisableFixTeam();

	if (IsNewGame())
	{
		ClearTeamsData();
		return Plugin_Continue;
	}

	CreateTimer(1.0, EnableFixTeam_Timer);

	return Plugin_Continue;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	ClearDefault();
}

void PlayerTeam_Event(Event event, const char[] name, bool dontBroadcast)
{
	if (IsNewGame())
	{
		DisableFixTeam();
		ClearTeamsData();
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	int team = GetEventInt(event, "team");
	if (team == L4D2_TEAM_SPECTATOR)
		return;

	CreateTimer(1.0, FixTeam_Timer);
}

Action FixTeam_Timer(Handle timer)
{
	FixTeams();

	return Plugin_Continue;
}

Action EnableFixTeam_Timer(Handle timer)
{
	EnableFixTeam();
	FixTeams();
	CreateTimer(30.0, DisableFixTeam_Timer);

	return Plugin_Continue;
}

Action DisableFixTeam_Timer(Handle timer)
{
	DisableFixTeam();

	return Plugin_Continue;
}

void SaveTeams()
{
	ClearTeamsData();

	bool survivorsAreWinning = SurvivorsAreWinning();

	int winnerTeam = survivorsAreWinning ? L4D2_TEAM_SURVIVOR : L4D2_TEAM_INFECTED;
	int losersTeam = survivorsAreWinning ? L4D2_TEAM_INFECTED : L4D2_TEAM_SURVIVOR;

	CopyClientsToArray(winners, winnerTeam);
	CopyClientsToArray(losers, losersTeam);
}

void CopyClientsToArray(ArrayList arrayList, int team)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != team)
			continue;
		
		PushArrayCell(arrayList, client);
	}
}

void FixTeams()
{
	if (!MustFixTheTeams())
		return;

	DisableFixTeam();

	bool survivorsAreWinning = SurvivorsAreWinning();
	
	int winnerTeam = survivorsAreWinning ? L4D2_TEAM_SURVIVOR : L4D2_TEAM_INFECTED;
	int losersTeam = survivorsAreWinning ? L4D2_TEAM_INFECTED : L4D2_TEAM_SURVIVOR;

	MoveToSpectatorWhoIsNotInTheTeam(winners, winnerTeam);
	MoveToSpectatorWhoIsNotInTheTeam(losers, losersTeam);

	MoveSpectatorsToTheCorrectTeam(winners, winnerTeam);
	MoveSpectatorsToTheCorrectTeam(losers, losersTeam);

	bool winnersInCorrectTeam = PlayersInCorrectTeam(winners, winnerTeam);
	bool losersInCorrectTeam = PlayersInCorrectTeam(losers, losersTeam);
	
	if (winnersInCorrectTeam && losersInCorrectTeam)
		return;

	EnableFixTeam();
}

void MoveToSpectatorWhoIsNotInTheTeam(ArrayList arrayList, int team)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != team)
            continue;
		
        if (FindValueInArray(arrayList, client) == -1)
            MovePlayerToTeam(client, L4D2_TEAM_SPECTATOR);
    }
}

void MoveSpectatorsToTheCorrectTeam(ArrayList arrayList, int team)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != L4D2_TEAM_SPECTATOR)
            continue;

        if (FindValueInArray(arrayList, client) != -1)
            MovePlayerToTeam(client, team);
    }
}

bool PlayersInCorrectTeam(ArrayList arrayList, int team)
{
	int arraySize = GetArraySize(arrayList);

	for (int i = 0; i < arraySize; i++)
	{
		int client = GetArrayCell(arrayList, i);

		if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != team)
			return false;
	}

	return true;
}

bool SurvivorsAreWinning()
{
	int flipped = GameRules_GetProp("m_bAreTeamsFlipped");

	int survivorIndex = flipped ? 1 : 0;
	int infectedIndex = flipped ? 0 : 1;

	int survivorScore = L4D2Direct_GetVSCampaignScore(survivorIndex);
	int infectedScore = L4D2Direct_GetVSCampaignScore(infectedIndex);

	return survivorScore >= infectedScore;
}

bool MustFixTheTeams()
{
	return fixTeam && !TeamsDataIsEmpty();
}

void EnableFixTeam()
{
	fixTeam = true;
}

void DisableFixTeam()
{
	fixTeam = false;
}

void ClearTeamsData()
{
	winners.Clear();
	losers.Clear();
}

bool TeamsDataIsEmpty()
{
	return GetArraySize(winners) == 0 && GetArraySize(losers) == 0;
}

bool IsNewGame()
{
	int teamAScore = L4D2Direct_GetVSCampaignScore(0);
	int teamBScore = L4D2Direct_GetVSCampaignScore(1);

	return teamAScore == 0 && teamBScore == 0;
}

void MovePlayerToTeam(int client, int team)
{
    // No need to check multiple times if we're trying to move a player to a possibly full team.
    if (team != L4D2_TEAM_SPECTATOR && NumberOfPlayersInTheTeam(team) >= TeamSize())
        return;

    switch (team)
    {
        case L4D2_TEAM_SPECTATOR:
            ChangeClientTeam(client, L4D2_TEAM_SPECTATOR); 

        case L4D2_TEAM_SURVIVOR:
            FakeClientCommand(client, "jointeam 2");

        case L4D2_TEAM_INFECTED:
            ChangeClientTeam(client, L4D2_TEAM_INFECTED);
    }
}

int NumberOfPlayersInTheTeam(int team)
{
	int count = 0;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != team)
			continue;

		count++;
	}

	return count;
}

int TeamSize()
{
	return GetConVarInt(FindConVar("survivor_limit"));
}

void ClearDefault()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}