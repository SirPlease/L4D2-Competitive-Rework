#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <sourcemod>

bool
	Blocked[MAXPLAYERS + 1],
	bSkipPrint[MAXPLAYERS + 1];
float
	fSavedTime[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name        = "Death Cam Skip Fix",
	author      = "Jacob, Sir",
	description = "Blocks players skipping their death time by going spec",
	version     = "1.5",
	url         = "https://github.com/SirPlease/L4D2-Competitive-Rework"

}

public void OnPluginStart()
{
	LoadTranslation("nodeathcamskip.phrases");

	HookEvent("player_death", Event_PlayerDeath);
	AddCommandListener(Listener_Join, "jointeam");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			Blocked[i]    = false;
			bSkipPrint[i] = false;
			fSavedTime[i] = 0.0;
		}
	}
}

void LoadTranslation(char[] sTranslation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", sTranslation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file %s.txt", sTranslation);
	}
	LoadTranslations(sTranslation);
}

public Action Listener_Join(int client, const char[] command, int argc)
{
	// Only care if they're targeting a specific Character.
	if (client && argc)
	{
		// Only care about people trying to join Infected and are blocked.
		char sJoin[32];
		GetCmdArg(1, sJoin, sizeof(sJoin));

		if (StrEqual(sJoin, "Infected", false) || StringToInt(sJoin) == 3)
		{
			// Full.
			if (GetInfectedPlayers() == GetConVarInt(FindConVar("z_max_player_zombies"))) return Plugin_Handled;

			if (Blocked[client])
			{
				// Warn Others.
				if (!bSkipPrint[client])
				{
					CPrintToChatAll("%t %t", "Tag", "DeathTimer", client);
					bSkipPrint[client] = true;
				}

				// Tell Offender.
				CPrintToChat(client, "%t %t", "Tag", "UnableToJoin", (fSavedTime[client] + 6.0) - GetGameTime());
				CPrintToChat(client, "%t %t", "Tag", "Moved");

				return Plugin_Handled;
			}

			if (GetInfectedPlayers() + GetBlockedPlayers() == GetConVarInt(FindConVar("z_max_player_zombies")))
			{
				CPrintToChat(client, "%t %t", "Tag", "SlotsReserved");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

stock int GetInfectedPlayers()
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && !IsFakeClient(i))
		{
			count++;
		}
	}
	return count;
}

stock int GetBlockedPlayers()
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && bSkipPrint[i] && !IsFakeClient(i))
		{
			count++;
		}
	}
	return count;
}

public void OnClientPutInServer(int client)
{
	bSkipPrint[client] = false;
	Blocked[client]    = false;
	fSavedTime[client] = 0.0;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon)
{
	if (IsValidInfected(client) && Blocked[client])
	{
		if (IsPlayerAlive(client))
		{
			Blocked[client]    = false;
			fSavedTime[client] = 0.0;
			bSkipPrint[client] = false;
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidInfected(client) && fSavedTime[client] == 0.0)
	{
		Blocked[client]    = true;
		fSavedTime[client] = GetGameTime();
		CreateTimer(0.1, UnblockTimer, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action UnblockTimer(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		float Time = GetGameTime();
		if (Time >= fSavedTime[client] + 6.0)
		{
			Blocked[client]    = false;
			fSavedTime[client] = 0.0;
			if (bSkipPrint[client] && GetClientTeam(client) == 1)
			{
				ChangeClientTeam(client, 3);
			}
			bSkipPrint[client] = false;
			return Plugin_Stop;
		}
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client))
	{
		return false;
	}
	return IsClientInGame(client) && !IsFakeClient(client);
}

stock bool IsValidInfected(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client))
	{
		return false;
	}
	return IsClientInGame(client) && GetClientTeam(client) == 3 && !IsFakeClient(client);
}