#pragma newdecls required
#include <sourcemod>

#define TEAM_SPECTATORS 1
#define TEAM_SURVIVORS  2

public Plugin myinfo = 
{
	name = "Duplicate Survivor Fix",
	author = "Sir",
	description = "As simple as the title.",
	version = "1.1",
	url = "Nope"
}

public void OnPluginStart()
{
	AddCommandListener(Listener_Join, "jointeam");
}

public Action Listener_Join(int client, char[] command, int args)
{
	// Only care if they're targeting a specific Character.
	if (IsValidClient(client) && args >= 2)
	{
		// Get Character they're trying to steal.
		char sJoinPlayer[128];
		char sJoin[32];
		GetCmdArg(1, sJoin, sizeof(sJoin));
		GetCmdArg(2, sJoinPlayer, sizeof(sJoinPlayer));

		// Are they trying to Join Survivors or nah?
		if (StringToInt(sJoin) != 2) return Plugin_Continue;

		// Convert Survivor names to Modelnames (Don't need Coach as his name and alternative name are one and the same)
		if (StrEqual(sJoinPlayer, "Nick", false)) Format(sJoinPlayer, sizeof(sJoinPlayer), "Gambler");
		else if (StrEqual(sJoinPlayer, "Rochelle", false)) Format(sJoinPlayer, sizeof(sJoinPlayer), "Producer");
		else if (StrEqual(sJoinPlayer, "Ellis", false)) Format(sJoinPlayer, sizeof(sJoinPlayer), "Mechanic");
		else if (StrEqual(sJoinPlayer, "Louis", false)) Format(sJoinPlayer, sizeof(sJoinPlayer), "Manager");
		else if (StrEqual(sJoinPlayer, "Zoey", false)) Format(sJoinPlayer, sizeof(sJoinPlayer), "Teenangst");
		else if (StrEqual(sJoinPlayer, "Bill", false)) Format(sJoinPlayer, sizeof(sJoinPlayer), "Namvet");
		else if (StrEqual(sJoinPlayer, "Francis", false)) Format(sJoinPlayer, sizeof(sJoinPlayer), "Biker");

		// Loop through Survivors to see if someone owns that Character.
		for(int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == TEAM_SURVIVORS)
			{
				// Only check actual Players or Bots that have an Idle player on them
				if (!IsFakeClient(i) || HasIdlePlayer(i))
				{
					char sModel[64];
					GetClientModel(i, sModel, sizeof(sModel));

					// Client is trying to take a Character that is already taken by a Player.
					// BLOCK.
					if (StrContains(sModel, sJoinPlayer, false) != -1) return Plugin_Handled;
				}
			}
		}
		// Client is not trying to Duplicate a Survivor.
		return Plugin_Continue;
	}
	// Meh.
	return Plugin_Continue;
}

stock bool IsValidClient(int client) 
{ 
	if (client <= 0 || client > MaxClients || !IsClientConnected(client)) return false; 
	return IsClientInGame(client); 
} 

stock bool HasIdlePlayer(int bot)
{
	int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))			
	if (IsValidClient(client) && !IsFakeClient(client) && GetClientTeam(client) == TEAM_SPECTATORS) return true;
	return false;
}