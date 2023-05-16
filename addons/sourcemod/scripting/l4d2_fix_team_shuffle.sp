#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define L4D2_TEAM_SPECTATOR 1
#define L4D2_TEAM_SURVIVOR 2
#define L4D2_TEAM_INFECTED 3

bool fixTeam = false;

ArrayList winners;
ArrayList losers;

public Plugin myinfo =
{
	name = "L4D2 - Fix team shuffle",
	author = "Altair Sossai",
	description = "Fix teams shuffling during map switching",
	version = "1.0.0",
	url = "https://github.com/altair-sossai/l4d2-zone-server"
};

public void OnPluginStart()
{
	HookEvent("round_start", RoundStart_Event);
	HookEvent("player_team", PlayerTeam_Event, EventHookMode_Post);

	winners = CreateArray(64);
	losers = CreateArray(64);
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

public void RoundStart_Event(Handle event, const char[] name, bool dontBroadcast)
{
	DisableFixTeam();

	if (IsNewGame())
	{
		ClearTeamsData();
		return;
	}

	CreateTimer(1.0, EnableFixTeam_Timer);
}

public void PlayerTeam_Event(Event event, const char[] name, bool dontBroadcast)
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

public Action FixTeam_Timer(Handle timer)
{
	FixTeams();

	return Plugin_Continue;
}

public Action EnableFixTeam_Timer(Handle timer)
{
	EnableFixTeam();
	FixTeams();
	CreateTimer(30.0, DisableFixTeam_Timer);

	return Plugin_Continue;
}

public Action DisableFixTeam_Timer(Handle timer)
{
	DisableFixTeam();

	return Plugin_Continue;
}

public void SaveTeams()
{
	ClearTeamsData();

	bool survivorsAreWinning = SurvivorsAreWinning();

	int winnerTeam = survivorsAreWinning ? L4D2_TEAM_SURVIVOR : L4D2_TEAM_INFECTED;
	int losersTeam = survivorsAreWinning ? L4D2_TEAM_INFECTED : L4D2_TEAM_SURVIVOR;

	CopyClientsToArray(winners, winnerTeam);
	CopyClientsToArray(losers, losersTeam);
}

public void CopyClientsToArray(ArrayList arrayList, int team)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != team)
			continue;
		
		PushArrayCell(arrayList, client);
	}
}

public void FixTeams()
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

public void MoveToSpectatorWhoIsNotInTheTeam(ArrayList arrayList, int team)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != team)
            continue;
		
        if (FindValueInArray(arrayList, client) == -1)
            MovePlayerToTeam(client, L4D2_TEAM_SPECTATOR);
    }
}

public void MoveSpectatorsToTheCorrectTeam(ArrayList arrayList, int team)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != L4D2_TEAM_SPECTATOR)
            continue;

        if (FindValueInArray(arrayList, client) != -1)
            MovePlayerToTeam(client, team);
    }
}

public bool PlayersInCorrectTeam(ArrayList arrayList, int team)
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

public bool SurvivorsAreWinning()
{
	int flipped = GameRules_GetProp("m_bAreTeamsFlipped");

	int survivorIndex = flipped ? 1 : 0;
	int infectedIndex = flipped ? 0 : 1;

	int survivorScore = L4D2Direct_GetVSCampaignScore(survivorIndex);
	int infectedScore = L4D2Direct_GetVSCampaignScore(infectedIndex);

	return survivorScore >= infectedScore;
}

public bool MustFixTheTeams()
{
	return fixTeam && !TeamsDataIsEmpty();
}

public void EnableFixTeam()
{
	fixTeam = true;
}

public void DisableFixTeam()
{
	fixTeam = false;
}

public void ClearTeamsData()
{
	winners.Clear();
	losers.Clear();
}

public bool TeamsDataIsEmpty()
{
	return GetArraySize(winners) == 0 && GetArraySize(losers) == 0;
}

public bool IsNewGame()
{
	int teamAScore = L4D2Direct_GetVSCampaignScore(0);
	int teamBScore = L4D2Direct_GetVSCampaignScore(1);

	return teamAScore == 0 && teamBScore == 0;
}

public void MovePlayerToTeam(int client, int team)
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

public int NumberOfPlayersInTheTeam(int team)
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

public int TeamSize()
{
	return GetConVarInt(FindConVar("survivor_limit"));
}