#if defined _readyup_command_included
 #endinput
#endif
#define _readyup_command_included

void ToggleCommandListeners(bool hook)
{
	static bool hooked = false;
	if (hooked && !hook)
	{
		RemoveCommandListener(Vote_Callback, "Vote");
		hooked = false;
	}
	else if (!hooked && hook)
	{
		AddCommandListener(Vote_Callback, "Vote");
		hooked = true;
	}
}

// ========================
//  Ready Commands
// ========================

Action Ready_Cmd(int client, int args)
{
	if (inReadyUp && IsPlayer(client))
	{
		if (!SetPlayerReady(client, true))
			PlayNotifySound();
		if (l4d_ready_secret.BoolValue)
			DoSecrets(client);
		if (CheckFullReady())
			InitiateLiveCountdown();
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Action Unready_Cmd(int client, int args)
{
	if (inReadyUp && client)
	{
		AdminId id = GetUserAdmin(client);
		bool hasflag = (id != INVALID_ADMIN_ID && GetAdminFlag(id, Admin_Ban)); // Check for specific admin flag
		
		if (isForceStart)
		{
			if (!hasflag) return Plugin_Handled;
			CancelFullReady(client, adminAbort);
			isForceStart = false;
		}
		else
		{
			if (IsPlayer(client))
			{
				SetButtonTime(client);
				if (SetPlayerReady(client, false))
					PlayNotifySound();
			}
			else if (!hasflag)
			{
				return Plugin_Handled;
			}
			CancelFullReady(client, readyStatus);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Action ToggleReady_Cmd(int client, int args)
{
	if (inReadyUp)
	{
		return IsPlayerReady(client) ? Unready_Cmd(client, 0) : Ready_Cmd(client, 0);
	}
	return Plugin_Continue;
}

// ========================
//  Admin Commands
// ========================

Action ForceStart_Cmd(int client, int args)
{
	if (inReadyUp && readyUpMode != ReadyMode_AutoStart)
	{
		// Check if admin always allowed to do so
		AdminId id = GetUserAdmin(client);
		if (id != INVALID_ADMIN_ID && GetAdminFlag(id, Admin_Ban)) // Check for specific admin flag
		{
			isForceStart = true;
			InitiateLiveCountdown();
			CPrintToChatAll("%t", "ForceStartAdmin", client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

// ========================
//  Player Commands
// ========================

Action Hide_Cmd(int client, int args)
{
	if (inReadyUp)
	{
		SetPlayerHiddenPanel(client, true);
		CPrintToChat(client, "%t", "PanelHide");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Action Show_Cmd(int client, int args)
{
	if (inReadyUp)
	{
		SetPlayerHiddenPanel(client, false);
		CPrintToChat(client, "%t", "PanelShow");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Action Return_Cmd(int client, int args)
{
	if (inReadyUp
			&& client > 0
			&& GetClientTeam(client) == L4D2Team_Survivor)
	{
		ReturnPlayerToSaferoom(client, false);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
