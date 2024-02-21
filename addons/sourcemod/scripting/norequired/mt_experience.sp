#pragma semicolon               1
#pragma newdecls                required

#include <sourcemod>
#include <colors>
#include <mix_team>
#include <steamworks>


public Plugin myinfo = { 
	name = "MixTeamExperience",
	author = "SirP, TouchMe",
	description = "Adds mix team by game experience",
	version = "build_0001"
};

#define TRANSLATIONS            "mt_experience.phrases"

#define MIN_PLAYERS             6

// Other
#define APP_L4D2                550

// Macros
#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_REAL_CLIENT(%1)      (IsClientInGame(%1) && !IsFakeClient(%1))

float g_fSurr, g_fInfr = 0.0;
enum struct PlayerInfo {
	int id;
	float rating;
}

enum struct PlayerStats {
	int playedTime;
	int tankRocks;
	int gamesWon;
	int gamesLost;
	int killBySilenced;
	int killBySmg;
	int killByChrome;
	int killByPump;
}


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
	AddMix("exp", MIN_PLAYERS, 0);
}

public void GetVoteDisplayMessage(int iClient, char[] sDisplayMsg) {
	Format(sDisplayMsg, DISPLAY_MSG_SIZE, "%T", "VOTE_DISPLAY_MSG", iClient);
}
public void GetVoteEndMessage(int iClient, char[] sMsg) {
    Format(sMsg, VOTEEND_MSG_SIZE, "%T", "VOTE_END_MSG", iClient);
}
/**
 * Starting the mix.
 */
public Action OnMixInProgress()
{
	Handle hPlayers = CreateArray(sizeof(PlayerInfo));
	PlayerInfo tPlayer;

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient) || IsFakeClient(iClient) || !IsMixMember(iClient)) {
			continue;
		}

		tPlayer.id = iClient;
		tPlayer.rating = CalculatePlayerRating(GetPlayerStats(iClient));

		if (tPlayer.rating <= 0.0)
		{
			CPrintToChatAll("%t", "FAIL_PLAYER_HIDE_INFO_STOP", iClient);
			Call_AbortMix();
			return Plugin_Handled;
		}

		PushArrayArray(hPlayers, tPlayer);
	}

	SortADTArrayCustom(hPlayers, SortPlayerByRating);

	// Balance
	int iPlayers = GetArraySize(hPlayers);
	int iHalfPlayers = iPlayers / 2;
	bool bIsSurvivorTeam = false;

	for (int iIndex = 0; iIndex < iHalfPlayers - 1; iIndex++)
	{
		bIsSurvivorTeam = (iIndex % 2 == 0);

		// Left
		GetArrayArray(hPlayers, iIndex, tPlayer);
		SetClientTeam(tPlayer.id, bIsSurvivorTeam ? TEAM_SURVIVOR : TEAM_INFECTED);
		if (bIsSurvivorTeam) {
			g_fSurr += tPlayer.rating;
		} else {
			g_fInfr += tPlayer.rating;
		}
		// Right
		GetArrayArray(hPlayers, iPlayers - iIndex - 1, tPlayer);
		SetClientTeam(tPlayer.id, bIsSurvivorTeam ? TEAM_SURVIVOR : TEAM_INFECTED);
		if (bIsSurvivorTeam) {
			g_fSurr += tPlayer.rating;
		} else {
			g_fInfr += tPlayer.rating;
		}
	}

	// Center
	{
		GetArrayArray(hPlayers, iHalfPlayers, tPlayer);
		SetClientTeam(tPlayer.id, TEAM_INFECTED);
		g_fInfr += tPlayer.rating;
		GetArrayArray(hPlayers, iHalfPlayers - 1, tPlayer);
		SetClientTeam(tPlayer.id, (iPlayers % 4 != 0) ? TEAM_SURVIVOR : TEAM_INFECTED);
		if (iPlayers % 4 != 0) {
			g_fSurr += tPlayer.rating;
		} else {
			g_fInfr += tPlayer.rating;
		}
	}

	CPrintToChatAll("生还%f / 特感%f", g_fSurr, g_fInfr);
	return Plugin_Continue;
}

public void SteamWorks_OnValidateClient(int iOwnerAuthId, int iAuthId)
{
	int iClient = GetClientFromSteamID(iAuthId);

	if(IS_VALID_CLIENT(iClient)) {
		SteamWorks_RequestStats(iClient, APP_L4D2);
	}
}

any[] GetPlayerStats(int iClient)
{
	PlayerStats tPlayerStats;

	SteamWorks_GetStatCell(iClient, "Stat.TotalPlayTime.Total", tPlayerStats.playedTime);
	SteamWorks_GetStatCell(iClient, "Stat.SpecAttack.Tank", tPlayerStats.tankRocks);
	SteamWorks_GetStatCell(iClient, "Stat.GamesWon.Versus", tPlayerStats.gamesWon);
	SteamWorks_GetStatCell(iClient, "Stat.GamesLost.Versus", tPlayerStats.gamesLost);
	SteamWorks_GetStatCell(iClient, "Stat.smg_silenced.Kills.Total", tPlayerStats.killBySilenced);
	SteamWorks_GetStatCell(iClient, "Stat.smg.Kills.Total", tPlayerStats.killBySmg);
	SteamWorks_GetStatCell(iClient, "Stat.shotgun_chrome.Kills.Total", tPlayerStats.killByChrome);
	SteamWorks_GetStatCell(iClient, "Stat.pumpshotgun.Kills.Total", tPlayerStats.killByPump);

	return tPlayerStats;
}

float CalculatePlayerRating(PlayerStats tPlayerStats)
{
	float fPlayedHours = SecToHours(tPlayerStats.playedTime);

	if (fPlayedHours <= 0.0) {
		return 0.0;
	}

	int iKillTotal = tPlayerStats.killByChrome + tPlayerStats.killByPump + tPlayerStats.killBySilenced + tPlayerStats.killBySmg;
	float fRockPerHours = float(tPlayerStats.tankRocks) / fPlayedHours;
	int iVersusGame = tPlayerStats.gamesWon + tPlayerStats.gamesLost;
	float fWinRounds = 0.5;

	if(iVersusGame >= 700) {
		fWinRounds = float(tPlayerStats.gamesWon) / float(iVersusGame);
	}

	return fWinRounds * (0.55 * fPlayedHours + fRockPerHours + float(iKillTotal) * 0.005);
}

/**
  * @param indexFirst    First index to compare.
  * @param indexSecond   Second index to compare.
  * @param hArrayList    Array that is being sorted (order is undefined).
  * @param hndl          Handle optionally passed in while sorting.
  *
  * @return              -1 if first should go before second
  *                      0 if first is equal to second
  *                      1 if first should go after second
  */
int SortPlayerByRating(int indexFirst, int indexSecond, Handle hArrayList, Handle hndl)
{
	PlayerInfo tPlayerFirst, tPlayerSecond;

	GetArrayArray(hArrayList, indexFirst, tPlayerFirst);
	GetArrayArray(hArrayList, indexSecond, tPlayerSecond);

	if (tPlayerFirst.rating < tPlayerSecond.rating) {
		return -1;
	}

	if (tPlayerFirst.rating > tPlayerSecond.rating) {
		return 1;
	}

	return 0;
}

float SecToHours(int iSeconds) {
	return float(iSeconds) / 3600.0;
}

int GetClientFromSteamID(int authid)
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(!IsClientConnected(iClient) || GetSteamAccountID(iClient) != authid) {
			continue;
		}

		return iClient;
	}

	return -1;
}