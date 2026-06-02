#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

ConVar g_hCvarMaxZombies = null;

public Plugin myinfo =
{
	name = "Character Fix",
	author = "someone",
	version = "0.2",
	description = "Fixes character change exploit in 1v1, 2v2, 3v3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	AddCommandListener(TeamCmd, "jointeam");

	g_hCvarMaxZombies = FindConVar("z_max_player_zombies");
}

Action TeamCmd(int iClient, const char[] sCommand, int iArgc)
{
	if (iClient == 0 || iArgc < 1) {
		return Plugin_Continue;
	}

	char sBuffer[128];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));
	int iNewteam = StringToInt(sBuffer);

	if (GetClientTeam(iClient) == TEAM_SURVIVOR 
		&& (strcmp("Infected", sBuffer, false) == 0 
		|| iNewteam == TEAM_INFECTED)
	) {
		if (GetInfectedCount() >= g_hCvarMaxZombies.IntValue) {
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

int GetInfectedCount()
{
	int iZombies = 0;

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED) {
			iZombies++;
		}
	}

	return iZombies;
}
