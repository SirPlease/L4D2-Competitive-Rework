#if defined _readyup_util_included
 #endinput
#endif
#define _readyup_util_included

#include "player.inc"

int GetMaxAllowedPlayers()
{
	int survLimit = survivor_limit.IntValue;
	
	if (L4D_GetGameModeType() & (GAMEMODE_VERSUS|GAMEMODE_SCAVENGE))
	{
		return survLimit + z_max_player_zombies.IntValue;
	}
	
	return survLimit;
}

bool IsTeamReady(int team)
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team && IsPlayerReady(i))
		{
			return true;
		}
	}
	return false;
}

void UTIL_WrapperForward(GlobalForward fw)
{
	if (fw.FunctionCount)
	{
		Call_StartForward(fw);
		Call_Finish();
	}
}

bool IsEmptyString(const char[] str, int maxlength)
{
	int len = strlen(str);
	if (len == 0)
		return true;
	
	if (len > maxlength)
		len = maxlength;
	
	for (int i = 0; i < len; ++i)
	{
		if (IsCharSpace(str[i]))
			continue;
		
		if (str[i] == '\r' || str[i] == '\n')
			continue;
		
		return false;
	}
	
	return true;
}

bool IsAnyPlayerLoading()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && (!IsClientInGame(i) || GetClientTeam(i) == L4D2Team_None))
		{
			return true;
		}
	}
	return false;
}

int GetSeriousClientCount(bool inGame = false)
{
	int clients = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (inGame)
		{
			if (IsClientInGame(i) && !IsFakeClient(i)) clients++;
		}
		else
		{
			if (IsClientConnected(i) && !IsFakeClient(i)) clients++;
		}
	}
	
	return clients;
}

void ReturnTeamToSaferoom(int team)
{
	int warp_flags = GetCommandFlags("warp_to_start_area");
	SetCommandFlags("warp_to_start_area", warp_flags & ~FCVAR_CHEAT);

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team)
		{
			ReturnPlayerToSaferoom(client, true);
		}
	}

	SetCommandFlags("warp_to_start_area", warp_flags);
}

void SetTeamFrozen(int team, bool freezeStatus)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team)
		{
			SetClientFrozen(client, freezeStatus);
		}
	}
}

int GetTeamHumanCount(int team)
{
	int humans = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == team)
		{
			humans++;
		}
	}
	
	return humans;
}