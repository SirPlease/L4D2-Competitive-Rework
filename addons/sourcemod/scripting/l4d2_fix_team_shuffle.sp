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
	name		= "L4D2 - Fix team shuffle",
	author		= "Altair Sossai",
	description = "Fix teams shuffling during map switching",
	version		= "1.0.0",
	url			= "https://github.com/altair-sossai/l4d2-zone-server"
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
}

public void L4D2_OnEndVersusModeRound_Post()
{
	SaveTeams();
}

public void RoundStart_Event(Handle event, const char[] name, bool dontBroadcast)
{
	DisableFixTeam();

	if (IsNewGame())
		return;

	CreateTimer(1.0, EnableFixTeam_Timer);
}

public void PlayerTeam_Event(Event event, const char[] name, bool dontBroadcast)
{
	FixTeams();
}

public Action EnableFixTeam_Timer(Handle timer)
{
	EnableFixTeam();
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
	int flipped = GameRules_GetProp("m_bAreTeamsFlipped");

	int survivorIndex = flipped ? 1 : 0;
	int infectedIndex = flipped ? 0 : 1;

	int survivorScore = L4D2Direct_GetVSCampaignScore(survivorIndex);
	int infectedScore = L4D2Direct_GetVSCampaignScore(infectedIndex);

	if (survivorScore > infectedScore)
	{
		SaveSurvivorsAsWinners();
		SaveInfectedsAsLosers();
	}
	else
	{
		SaveInfectedsAsWinners();
		SaveSurvivorsAsLosers();
	}
}

public void SaveSurvivorsAsWinners()
{
	AddSteamIdsToArray(winners, L4D2_TEAM_SURVIVOR);
}

public void SaveInfectedsAsWinners()
{
	AddSteamIdsToArray(winners, L4D2_TEAM_INFECTED);
}

public void SaveSurvivorsAsLosers()
{
	AddSteamIdsToArray(losers, L4D2_TEAM_SURVIVOR);
}

public void SaveInfectedsAsLosers()
{
	AddSteamIdsToArray(losers, L4D2_TEAM_INFECTED);
}

public void AddSteamIdsToArray(ArrayList arrayList, int team)
{
	arrayList.Clear();

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != team)
			continue;
		
		PushArrayCell(arrayList, client);
	}
}

public void FixTeams()
{
	if (!fixTeam)
		return;

	int flipped = GameRules_GetProp("m_bAreTeamsFlipped");

	int survivorIndex = flipped ? 1 : 0;
	int infectedIndex = flipped ? 0 : 1;

	int survivorScore = L4D2Direct_GetVSCampaignScore(survivorIndex);
	int infectedScore = L4D2Direct_GetVSCampaignScore(infectedIndex);

	if (survivorScore > infectedScore)
	{
		FixSurvivorTeamAsWinners();
		FixInfectedTeamAsLosers();
	}
	else
	{
		FixInfectedTeamAsWinners();
		FixSurvivorTeamAsLosers();
	}
}

public void FixSurvivorTeamAsWinners()
{
	FixTeam(winners, L4D2_TEAM_SURVIVOR);
}

public void FixInfectedTeamAsWinners()
{
	FixTeam(winners, L4D2_TEAM_INFECTED);
}

public void FixSurvivorTeamAsLosers()
{
	FixTeam(losers, L4D2_TEAM_SURVIVOR);
}

public void FixInfectedTeamAsLosers()
{
	FixTeam(losers, L4D2_TEAM_INFECTED);
}

public void FixTeam(ArrayList arrayList, int team)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != team)
			continue;

		bool correctTeam = false;

		for (int i = 0; !correctTeam && i < GetArraySize(arrayList); i++)
			correctTeam = GetArrayCell(arrayList, i) == client;

		if (correctTeam)
			continue;

		MovePlayerToSpectator(client);
	}

	MoveSpectatorsToTheCorrectTeam();
}

public void MoveSpectatorsToTheCorrectTeam()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != team)
			continue;

		bool correctTeam = false;

		for (int i = 0; !correctTeam && i < GetArraySize(arrayList); i++)
			correctTeam = GetArrayCell(arrayList, i) == client;

		if (correctTeam)
			continue;

		MovePlayerToSpectator(client);
	}
}

public void EnableFixTeam()
{
	fixTeam = true;
}

public void DisableFixTeam()
{
	fixTeam = false;
}

public bool IsNewGame()
{
	int teamAScore = L4D2Direct_GetVSCampaignScore(0);
	int teamBScore = L4D2Direct_GetVSCampaignScore(1);

	return teamAScore == 0 && teamBScore == 0;
}

public void MovePlayerToSpectator(int client)
{
	ChangeClientTeam(client, L4D2_TEAM_SPECTATOR);
}

public void MovePlayerToSurvivor(int client)
{
	int bot = FindSurvivorBot();
	if (bot <= 0)
		return;

	int flags = GetCommandFlags("sb_takecontrol");
	SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "sb_takecontrol");
	SetCommandFlags("sb_takecontrol", flags);
}

public void MovePlayerToInfected(int client)
{
	ChangeClientTeam(client, L4D2_TEAM_INFECTED);
}

public int FindSurvivorBot()
{
	for (int client = 1; client <= MaxClients; client++)
		if(IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == L4D2_TEAM_SURVIVOR)
			return client;

	return -1;
}