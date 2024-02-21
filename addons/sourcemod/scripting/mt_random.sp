#pragma semicolon               1
#pragma newdecls                required

#include <sourcemod>
#include <mix_team>


public Plugin myinfo = { 
	name = "MixTeamRandom",
	author = "TouchMe",
	description = "Adds random mix",
	version = "build_0001",
	url = "https://github.com/TouchMe-Inc/l4d2_mix_team"
};


#define TRANSLATIONS            "mt_random.phrases"

#define MIN_PLAYERS             4


/**
 * Loads dictionary files. On failure, stops the plugin execution.
 */
void InitTranslations()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "translations/" ... TRANSLATIONS ... ".txt");

	if (FileExists(sPath)) {
		LoadTranslations(TRANSLATIONS);
	} else {
		SetFailState("Path %s not found", sPath);
	}
}

/**
 * Called when the plugin is fully initialized and all known external references are resolved.
 */
public void OnPluginStart() {
	InitTranslations();
}

public void OnAllPluginsLoaded() {
	AddMix("random", MIN_PLAYERS, 0);
}

public void GetVoteDisplayMessage(int iClient, char[] sTitle) {
	Format(sTitle, DISPLAY_MSG_SIZE, "%T", "VOTE_DISPLAY_MSG", iClient);
}

public void GetVoteEndMessage(int iClient, char[] sMsg) {
	Format(sMsg, VOTEEND_MSG_SIZE, "%T", "VOTE_END_MSG", iClient);
}

/**
 * Starting the mix.
 */
public Action OnMixInProgress()
{
	// save current player / team setup
	int g_iPreviousCount[4];
	int g_iPreviousTeams[4][MAXPLAYERS + 1];

	for (int iClient = 1, iTeam; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient) || IsFakeClient(iClient) || !IsMixMember(iClient)) {
			continue;
		}

		iTeam = GetLastTeam(iClient);

		g_iPreviousTeams[iTeam][g_iPreviousCount[iTeam]] = iClient;
		g_iPreviousCount[iTeam]++;
	}

	// if there are uneven players, move one to the other
	if ((g_iPreviousCount[TEAM_SURVIVOR] + g_iPreviousCount[TEAM_INFECTED]) < (2 * MIN_PLAYERS))
	{
		int tmpDif = g_iPreviousCount[TEAM_SURVIVOR] - g_iPreviousCount[TEAM_INFECTED];
		int iTeamA, iTeamB;

		while (tmpDif > 1 || tmpDif < -1) 
		{
			if (tmpDif > 1) {
				iTeamA = TEAM_SURVIVOR;
				iTeamB = TEAM_INFECTED;	
			}
			else if (tmpDif < -1) {
				iTeamA = TEAM_INFECTED;
				iTeamB = TEAM_SURVIVOR;	
			}

			g_iPreviousCount[iTeamA]--;
			g_iPreviousTeams[iTeamB][g_iPreviousCount[iTeamB]] = g_iPreviousTeams[iTeamA][g_iPreviousCount[iTeamA]];
			g_iPreviousCount[iTeamB]++;

			tmpDif = g_iPreviousCount[TEAM_SURVIVOR] - g_iPreviousCount[TEAM_INFECTED];
		}
	}

	// do shuffle: swap at least teamsize/2 rounded up players
	bool bShuffled[MAXPLAYERS + 1];
	int iShuffleCount = RoundToCeil(float(g_iPreviousCount[TEAM_INFECTED] > g_iPreviousCount[TEAM_SURVIVOR] ? g_iPreviousCount[TEAM_INFECTED] : g_iPreviousCount[TEAM_SURVIVOR]) / 2.0);

	int pickA, pickB;
	int spotA, spotB;

	for (int j = 0; j < iShuffleCount; j++ )
	{
		pickA = -1;
		pickB = -1;

		while (pickA == -1 || bShuffled[pickA]) {
			spotA = GetRandomInt(0, g_iPreviousCount[TEAM_SURVIVOR] - 1);
			pickA = g_iPreviousTeams[TEAM_SURVIVOR][spotA];
		}

		while (pickB == -1 || bShuffled[pickB]) {
			spotB = GetRandomInt(0, g_iPreviousCount[TEAM_INFECTED] - 1);
			pickB = g_iPreviousTeams[TEAM_INFECTED][spotB];
		}

		bShuffled[pickA] = true;
		bShuffled[pickB] = true;

		g_iPreviousTeams[TEAM_SURVIVOR][spotA] = pickB;
		g_iPreviousTeams[TEAM_INFECTED][spotB] = pickA;
	}

	// now place all the players in the teams according to previousteams (silly name now, but ok)
	for (int iTeam = TEAM_SURVIVOR, iPrevious; iTeam <= TEAM_INFECTED; iTeam++)
	{
		for (iPrevious = 0; iPrevious < g_iPreviousCount[iTeam]; iPrevious++)
		{
			SetClientTeam(g_iPreviousTeams[iTeam][iPrevious], iTeam);
		}
	}

	return Plugin_Continue;
}
