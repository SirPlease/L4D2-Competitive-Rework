#if defined _readyup_player_included
 #endinput
#endif
#define _readyup_player_included

static bool
	isPlayerReady[MAXPLAYERS+1],
	hiddenPanel[MAXPLAYERS+1];

static float
	buttonTime[MAXPLAYERS+1];

bool IsPlayerReady(int client)
{
	return isPlayerReady[client];
}

bool SetPlayerReady(int client, bool ready)
{
	bool prev = isPlayerReady[client];
	isPlayerReady[client] = ready;
	
	if (prev && !ready)
	{
		if (g_hPlayerReadyForward.FunctionCount)
		{
			Call_StartForward(g_hPlayerReadyForward);
			Call_PushCell(client);
			Call_Finish();
		}
	}
	else if (!prev && ready)
	{
		if (g_hPlayerUnreadyForward.FunctionCount)
		{
			Call_StartForward(g_hPlayerUnreadyForward);
			Call_PushCell(client);
			Call_Finish();
		}
	}
	
	return prev;
}

bool IsPlayerHiddenPanel(int client)
{
	return hiddenPanel[client];
}

bool SetPlayerHiddenPanel(int client, bool hidden)
{
	bool prev = hiddenPanel[client];
	hiddenPanel[client] = hidden;
	return prev;
}

void SetButtonTime(int client)
{
	buttonTime[client] = GetEngineTime();
}

#define AFK_DURATION 15.0
bool IsPlayerAfk(int client)
{
	return GetEngineTime() - buttonTime[client] > AFK_DURATION;
}

void GetClientFixedName(int client, char[] name, int length)
{
	GetClientName(client, name, length);

	if (name[0] == '[')
	{
		char temp[MAX_NAME_LENGTH];
		strcopy(temp, sizeof(temp), name);
		temp[sizeof(temp)-2] = 0;
		strcopy(name[1], length-1, temp);
		name[0] = ' ';
	}
}

void SetClientFrozen(int client, bool freeze)
{
	SetEntityMoveType(client, freeze ? MOVETYPE_NONE : (GetClientTeam(client) == L4D2Team_Spectator ? MOVETYPE_NOCLIP : MOVETYPE_WALK));
}

bool IsPlayer(int client)
{
	int team = GetClientTeam(client);
	return (team == L4D2Team_Survivor || team == L4D2Team_Infected);
}

void ReturnPlayerToSaferoom(int client, bool flagsSet = true)
{
	int warp_flags;
	if (!flagsSet)
	{
		warp_flags = GetCommandFlags("warp_to_start_area");
		SetCommandFlags("warp_to_start_area", warp_flags & ~FCVAR_CHEAT);
	}

	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
	{
		L4D_ReviveSurvivor(client);
	}

	FakeClientCommand(client, "warp_to_start_area");

	if (!flagsSet)
	{
		SetCommandFlags("warp_to_start_area", warp_flags);
	}
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VELOCITY);
	SetEntPropFloat(client, Prop_Send, "m_flFallVelocity", 0.0);
}
