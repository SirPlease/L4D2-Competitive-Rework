#include <sourcemod>
#include <left4dhooks>

#define L4D2_TEAM_NONE      0
#define L4D2_TEAM_SPECTATOR 1
#define L4D2_TEAM_SURVIVOR  2
#define L4D2_TEAM_INFECTED  3

bool fixTeam = false;

ArrayList winners;
ArrayList losers;

public Plugin myinfo =
{
	name = "L4D2 - Fix team shuffle",
	author = "Altair Sossai",
	description = "Fix teams shuffling during map switching",
	version = "1.0.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("player_team", PlayerTeam_Event);

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

void RoundStart_Event(Handle event, const char[] name, bool dontBroadcast)
{
	DisableFixTeam();

	if (L4D_HasMapStarted() && IsNewGame())
	{
		ClearTeamsData();
		return;
	}

	CreateTimer(1.0, EnableFixTeam_Timer);
}

void PlayerTeam_Event(Event event, const char[] name, bool dontBroadcast)
{
	if (!L4D_HasMapStarted())
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	int team = event.GetInt("team");
	if (team == L4D2_TEAM_SPECTATOR)
	{
		int oldteam = event.GetInt("oldteam");
		if (oldteam == L4D2_TEAM_NONE)
			CreateTimer(0.5, ReSpec_Timer, client);

		return;
	}

	if (IsNewGame())
	{
		DisableFixTeam();
		ClearTeamsData();
		return;
	}

	CreateTimer(1.0, FixTeam_Timer);
}

Action ReSpec_Timer(Handle timer, any client)
{
	if (IsClientInGame(client) 
	&& GetClientTeam(client) == L4D2_TEAM_SPECTATOR
	&& FindValueInArray(winners, client) == -1 
	&& FindValueInArray(losers, client) == -1)
	{
		FakeClientCommand(client, "sm_spectate");
	}
	return Plugin_Stop;
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