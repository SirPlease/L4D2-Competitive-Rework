#include <sourcemod>

#define TEAM_SPECTATORS 1
#define TEAM_SURVIVORS  2

public Plugin:myinfo = 
{
	name = "Duplicate Survivor Fix",
	author = "Sir",
	description = "As simple as the title.",
	version = "1.0",
	url = "Nope"
}

public OnPluginStart()
{
	AddCommandListener(Listener_Join, "jointeam");
}

public Action:Listener_Join(client, const String:command[], argc)
{
	// Only care if they're targeting a specific Character.
	if (IsValidClient(client) && argc >= 2)
	{
		// Get Character they're trying to steal.
		new String:sJoinPlayer[128];
		new String:sJoin[32];
		GetCmdArg(1, sJoin, sizeof(sJoin));
		GetCmdArg(2, sJoinPlayer, sizeof(sJoinPlayer));

		// Are they trying to Join Survivors or nah?
		if (StringToInt(sJoin) != 2) return Plugin_Continue;

		// Loop through Survivors to see if someone owns that Character.
		for(new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == TEAM_SURVIVORS)
			{
				if (!IsFakeClient(i))
				{
					new String:sModel[64];
					new String:sPlayer[64];
					GetClientModel(i, sModel, sizeof(sModel));

					if (StrEqual(sModel, "models/survivors/survivor_coach.mdl")) Format(sPlayer, sizeof(sPlayer), "Coach");
					else if (StrEqual(sModel, "models/survivors/survivor_gambler.mdl")) Format(sPlayer, sizeof(sPlayer), "Nick");
					else if (StrEqual(sModel, "models/survivors/survivor_producer.mdl")) Format(sPlayer, sizeof(sPlayer), "Rochelle");
					else if (StrEqual(sModel, "models/survivors/survivor_mechanic.mdl")) Format(sPlayer, sizeof(sPlayer), "Ellis");
					else if (StrEqual(sModel, "models/survivors/survivor_manager.mdl")) Format(sPlayer, sizeof(sPlayer), "Louis");
					else if (StrEqual(sModel, "models/survivors/survivor_teenangst.mdl")) Format(sPlayer, sizeof(sPlayer), "Zoey");
					else if (StrEqual(sModel, "models/survivors/survivor_namvet.mdl")) Format(sPlayer, sizeof(sPlayer), "Bill");
					else if (StrEqual(sModel, "models/survivors/survivor_biker.mdl")) Format(sPlayer, sizeof(sPlayer), "Francis");

					// Client is trying to take a Character that is already taken by a Player.
					// BLOCK.
					if (StrEqual(sJoinPlayer, sPlayer, false)) 
					{
						return Plugin_Handled;
					}
				}
				else
				{
					if (HasIdlePlayer(i))
					{
						new String:sModel[64];
						new String:sPlayer[64];
						GetClientModel(i, sModel, sizeof(sModel));

						if (StrEqual(sModel, "models/survivors/survivor_coach.mdl")) Format(sPlayer, sizeof(sPlayer), "Coach");
						else if (StrEqual(sModel, "models/survivors/survivor_gambler.mdl")) Format(sPlayer, sizeof(sPlayer), "Nick");
						else if (StrEqual(sModel, "models/survivors/survivor_producer.mdl")) Format(sPlayer, sizeof(sPlayer), "Rochelle");
						else if (StrEqual(sModel, "models/survivors/survivor_mechanic.mdl")) Format(sPlayer, sizeof(sPlayer), "Ellis");
						else if (StrEqual(sModel, "models/survivors/survivor_manager.mdl")) Format(sPlayer, sizeof(sPlayer), "Louis");
						else if (StrEqual(sModel, "models/survivors/survivor_teenangst.mdl")) Format(sPlayer, sizeof(sPlayer), "Zoey");
						else if (StrEqual(sModel, "models/survivors/survivor_namvet.mdl")) Format(sPlayer, sizeof(sPlayer), "Bill");
						else if (StrEqual(sModel, "models/survivors/survivor_biker.mdl")) Format(sPlayer, sizeof(sPlayer), "Francis");

						// Client is trying to take a Character that is already taken by an IDLE Player.
						// BLOCK.
						if (StrEqual(sJoinPlayer, sPlayer, false)) 
						{
							return Plugin_Handled;
						}
					}
				}
			}
		}

		// Client is not trying to Duplicate a Survivor.
		return Plugin_Continue;
	}
	// Meh.
	return Plugin_Continue;
}

bool:IsValidClient(client) { 
	if (client <= 0 || client > MaxClients || !IsClientConnected(client)) return false; 
	return IsClientInGame(client); 
} 

bool:HasIdlePlayer(bot)
{
	new client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))			
	if (client)
	{
		if (IsValidClient(client) && !IsFakeClient(client) && GetClientTeam(client) == TEAM_SPECTATORS) return true
	}
	return false
}