/*
	SourcePawn is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2008 ITB CompuPhase.
	Source is Copyright (C) Valve Corporation.
	All trademarks are property of their respective owners.

	This program is free software: you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>
#include <builtinvotes>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>
#undef REQUIRE_PLUGIN
#include <readyup>

public Plugin myinfo =
{
	name = "Pause plugin",
	author = "CanadaRox, Sir, Forgetest", //Add support sm1.11 - A1m`
	description = "Adds pause functionality without breaking pauses, also prevents SI from spawning because of the Pause.",
	version = "6.5",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

// Game ConVar
ConVar
	sv_pausable,
	sv_noclipduringpause;

// Plugin Forwards
Handle
	pauseForward,
	unpauseForward;

// Plugin ConVar
ConVar
	pauseDelayCvar,
	initiatorReadyCvar,
	l4d_ready_delay,
	serverNamerCvar;

// Pause Handle
Handle
	readyCountdownTimer,
	deferredPauseTimer;
int
	readyDelay,
	pauseDelay;
bool
	isPaused,
	RoundEnd;

// Pause Info
int
	initiatorId;
bool
	adminPause,
	teamReady[view_as<int>(L4D2Team_Size)],
	initiatorReady;
char
	initiatorName[MAX_NAME_LENGTH];
float
	pauseTime;
L4D2_Team
	pauseTeam;

// Pause Panel
bool hiddenPanel[MAXPLAYERS+1];

// Ready Up Available
bool readyUpIsAvailable;

// Pause Fix
Handle SpecTimer[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("IsInPause", Native_IsInPause);
	pauseForward = CreateGlobalForward("OnPause", ET_Ignore);
	unpauseForward = CreateGlobalForward("OnUnpause", ET_Ignore);
	RegPluginLibrary("pause");
}

public void OnPluginStart()
{
	pauseDelayCvar = CreateConVar("sm_pausedelay", "0", "Delay to apply before a pause happens.  Could be used to prevent Tactical Pauses", FCVAR_NONE, true, 0.0);
	initiatorReadyCvar = CreateConVar("sm_initiatorready", "0", "Require or not the pause initiator should ready before unpausing the game", FCVAR_NONE, true, 0.0);
	l4d_ready_delay = FindConVar("l4d_ready_delay");
	
	FindServerNamer();
	
	sv_pausable = FindConVar("sv_pausable");
	sv_noclipduringpause = FindConVar("sv_noclipduringpause");

	RegConsoleCmd("sm_spectate", Spectate_Cmd, "Moves you to the spectator team");
	RegConsoleCmd("sm_spec", Spectate_Cmd, "Moves you to the spectator team");
	RegConsoleCmd("sm_s", Spectate_Cmd, "Moves you to the spectator team");
	
	RegConsoleCmd("sm_pause", Pause_Cmd, "Pauses the game");
	RegConsoleCmd("sm_unpause", Unpause_Cmd, "Marks your team as ready for an unpause");
	RegConsoleCmd("sm_ready", Unpause_Cmd, "Marks your team as ready for an unpause");
	RegConsoleCmd("sm_unready", Unready_Cmd, "Marks your team as ready for an unpause");
	RegConsoleCmd("sm_toggleready", ToggleReady_Cmd, "Toggles your team's ready status");
	
	RegAdminCmd("sm_forcepause", ForcePause_Cmd, ADMFLAG_BAN, "Pauses the game and only allows admins to unpause");
	RegAdminCmd("sm_forceunpause", ForceUnpause_Cmd, ADMFLAG_BAN, "Unpauses the game regardless of team ready status.  Must be used to unpause admin pauses");

	RegConsoleCmd("sm_show", Show_Cmd, "Hides the pause panel so other menus can be seen");
	RegConsoleCmd("sm_hide", Hide_Cmd, "Shows a hidden pause panel");

	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
}

// ======================================
// Readyup Available
// ======================================

public void OnAllPluginsLoaded() { readyUpIsAvailable = LibraryExists("readyup"); FindServerNamer(); }
public void OnLibraryAdded(const char[] name) { if (StrEqual(name, "readyup")) readyUpIsAvailable = true; FindServerNamer(); }
public void OnLibraryRemoved(const char[] name) { if (StrEqual(name, "readyup")) readyUpIsAvailable = false; FindServerNamer(); }

// ======================================
// Custom Server Namer
// ======================================

void FindServerNamer()
{
	if ((serverNamerCvar = FindConVar("l4d_ready_server_cvar")) != null)
	{
		char buffer[128];
		serverNamerCvar.GetString(buffer, sizeof buffer);
		serverNamerCvar = FindConVar(buffer);
	}
	
	if (serverNamerCvar == null)
	{
		serverNamerCvar = FindConVar("hostname");
	}
}

// ======================================
// Forwards
// ======================================

public void OnClientPutInServer(int client)
{
	if (isPaused)
	{
		if (!IsFakeClient(client))
		{
			CPrintToChatAll("{default}[{green}!{default}] {olive}%N {default}has fully loaded", client);
		}
	}
}

public void OnClientDisconnect_Post(int client)
{
	if (isPaused && !adminPause && CheckFullReady())
	{
		InitiateLiveCountdown();
	}

	hiddenPanel[client] = false;
}

public void OnMapEnd()
{
	RoundEnd = true;
	Unpause(false);
}

public void RoundEnd_Event(Event event, const char[] name, bool dontBroadcast)
{
	if (deferredPauseTimer != null)
	{
		delete deferredPauseTimer;
	}
	RoundEnd = true;
	Unpause(false);
}

public void RoundStart_Event(Event event, const char[] name, bool dontBroadcast)
{
	RoundEnd = false;
	initiatorId = 0;
}

// ======================================
// Commands
// ======================================

public Action Pause_Cmd(int client, int args)
{
	if (readyUpIsAvailable && IsInReady())
		return Plugin_Continue;
	
	if (!IsPlayer(client))
		return Plugin_Continue;
		
	if (RoundEnd)
		return Plugin_Continue;
		
	if (pauseDelay == 0 && !isPaused)
	{
		initiatorId = GetClientUserId(client);
		pauseTeam = view_as<L4D2_Team>(GetClientTeam(client));
		GetClientName(client, initiatorName, sizeof(initiatorName));
		
		CPrintToChatAll("{default}[{green}!{default}] {olive}%N {blue}Paused{default}.", client);
		
		pauseDelay = pauseDelayCvar.IntValue;
		if (pauseDelay == 0)
		{
			AttemptPause();
		}
		else
		{
			CreateTimer(1.0, PauseDelay_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Handled;
}

public Action PauseDelay_Timer(Handle timer)
{
	if (pauseDelay == 0)
	{
		CPrintToChatAll("{default}[{green}!{default}] {red}PAUSED");
		AttemptPause();
		return Plugin_Stop;
	}
	else
	{
		CPrintToChatAll("{default}[{green}!{default}] {blue}Pausing in{default}: {olive}%d", pauseDelay);
		pauseDelay--;
	}
	return Plugin_Continue;
}

public Action ForcePause_Cmd(int client, int args)
{
	if (!isPaused)
	{
		adminPause = true;
		initiatorId = GetClientUserId(client);
		GetClientName(client, initiatorName, sizeof(initiatorName));
		CPrintToChatAll("{default}[{green}!{default}] A {green}force pause {default}is issued by {blue}Admin {default}({olive}%N{default})", client);
		Pause();
	}
}

public Action Unpause_Cmd(int client, int args)
{
	if (isPaused && IsPlayer(client))
	{
		L4D2_Team clientTeam = view_as<L4D2_Team>(GetClientTeam(client));
		int initiator = GetClientOfUserId(initiatorId);
		if (!teamReady[clientTeam])
		{
			switch (clientTeam)
			{
				case L4D2Team_Survivor:
				{
					CPrintToChatAll("{default}[{green}!{default}] {olive}%N %s{default}marked {blue}%s{default}ready.", client, (initiatorReady && client == initiator) ? "{default}as {green}Initiator " : "", L4D2_TeamName[clientTeam]);
				}
				case L4D2Team_Infected:
				{
					CPrintToChatAll("{default}[{green}!{default}] {olive}%N %s{default}marked {red}%s{default}ready.", client, (initiatorReady && client == initiator) ? "{default}as {green}Initiator " : "", L4D2_TeamName[clientTeam]);					
				}
			}
		}
		if (initiatorReadyCvar.BoolValue)
		{
			if (client == initiator && !initiatorReady)
			{
				initiatorReady = true;
				if (teamReady[clientTeam])
				{
					CPrintToChatAll("{default}[{green}!{default}] {olive}%N {default}marked {green}Initiator {default}ready.", client);
				}
			}
		}
		teamReady[clientTeam] = true;
		if (CheckFullReady())
		{
			if (!adminPause)
			{
				InitiateLiveCountdown();
			}
			else
			{
				CPrintToChatAll("{default}[{green}!{default}] {olive}Teams {default}are ready. Wait for {blue}Admin {default}to {green}confirm{default}.");
			}
		}
	}
	return Plugin_Handled;
}

public Action Unready_Cmd(int client, int args)
{
	if (isPaused && IsPlayer(client))
	{
		int initiator = GetClientOfUserId(initiatorId);
		L4D2_Team clientTeam = view_as<L4D2_Team>(GetClientTeam(client));
		if (teamReady[clientTeam])
		{
			switch (clientTeam)
			{
				case L4D2Team_Survivor:
				{
					CPrintToChatAll("{default}[{green}!{default}] {olive}%N %s{default}marked {blue}%s {default}not ready.", client, (initiatorReady && client == initiator) ? "{default}as {green}Initiator " : "", L4D2_TeamName[clientTeam]);
				}
				case L4D2Team_Infected:
				{
					CPrintToChatAll("{default}[{green}!{default}] {olive}%N %s{default}marked {red}%s {default}not ready.", client, (initiatorReady && client == initiator) ? "{default}as {green}Initiator " : "", L4D2_TeamName[clientTeam]);
				}
			}
		}
		if (initiatorReadyCvar.BoolValue)
		{
			if (client == initiator && initiatorReady)
			{
				initiatorReady = false;
				if (!teamReady[clientTeam])
				{
					CPrintToChatAll("{default}[{green}!{default}] {olive}%N {default}marked {green}Initiator {default}not ready.", client);
				}
			}
		}
		teamReady[clientTeam] = false;
		
		if (!adminPause)
		{
			CancelFullReady(client);
		}
	}
	return Plugin_Handled;
}

public Action ForceUnpause_Cmd(int client, int args)
{
	if (isPaused)
	{
		adminPause = true;
		CPrintToChatAll("{default}[{green}!{default}] A {green}force unpause {default}is issued by {blue}Admin {default}({olive}%N{default})", client);
		InitiateLiveCountdown();
	}
}

public Action ToggleReady_Cmd(int client, int args)
{
	L4D2_Team clientTeam = view_as<L4D2_Team>(GetClientTeam(client));
	teamReady[clientTeam] ? Unready_Cmd(client, 0) : Unpause_Cmd(client, 0);
}

// ======================================
// Pause Process
// ======================================

void AttemptPause()
{
	if (deferredPauseTimer == null)
	{
		if (!IsSurvivorReviving())
		{
			Pause();
		}
		else
		{
			CPrintToChatAll("{default}[{green}!{default}] {red}Pause has been delayed due to a pick-up in progress!");
			deferredPauseTimer = CreateTimer(0.1, DeferredPause_Timer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action DeferredPause_Timer(Handle timer)
{
	if (!IsSurvivorReviving())
	{
		deferredPauseTimer = null;
		Pause();
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void Pause()
{
	for (int team; team < view_as<int>(L4D2Team_Size); team++)
	{
		teamReady[team] = false;
	}
	
	initiatorReady = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		hiddenPanel[i] = false;
	}

	isPaused = true;
	pauseTime = GetEngineTime();
	readyCountdownTimer = null;
	
	ToggleCommandListeners(true);
	
	CreateTimer(1.0, MenuRefresh_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	bool pauseProcessed = false;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			L4D2_Team team = view_as<L4D2_Team>(GetClientTeam(client));
			
			if (team == L4D2Team_Infected && IsInfectedGhost(client))
			{
				SetEntProp(client, Prop_Send, "m_hasVisibleThreats", 1);
				int buttons = GetClientButtons(client);
				if (buttons & IN_ATTACK)
				{
					buttons &= ~IN_ATTACK;
					SetClientButtons(client, buttons);
					CPrintToChat(client, "{default}[{green}!{default}] {default}Your {red}Spawn {default}has been prevented because of the Pause");
				}
			}
			
			if (!pauseProcessed)
			{
				sv_pausable.BoolValue = true;
				FakeClientCommand(client, "pause");
				sv_pausable.BoolValue = false;
				pauseProcessed = true;
			}
			
			if (team == L4D2Team_Spectator)
			{
				sv_noclipduringpause.ReplicateToClient(client, "1");
			}
		}
	}
	
	Call_StartForward(pauseForward);
	Call_Finish();
}

void Unpause(bool real = true)
{
	isPaused = false;
	adminPause = false;
	
	ToggleCommandListeners(false);

	pauseTeam = L4D2Team_None;
	initiatorId = 0;
	initiatorReady = false;
	initiatorName = "";
	
	readyCountdownTimer = null;
	
	if (real)
	{
		bool unpauseProcessed = false;
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && !IsFakeClient(client))
			{
				if(!unpauseProcessed)
				{
					sv_pausable.BoolValue = true;
					FakeClientCommand(client, "unpause");
					sv_pausable.BoolValue = false;
					unpauseProcessed = true;
				}
				
				if (view_as<L4D2_Team>(GetClientTeam(client)) == L4D2Team_Spectator)
				{
					sv_noclipduringpause.ReplicateToClient(client, "0");
				}
			}
		}
		
		Call_StartForward(unpauseForward);
		Call_Finish();
	}
}

// ======================================
// Pause Panel
// ======================================

public Action Show_Cmd(int client, int args)
{
	if (isPaused)
	{
		hiddenPanel[client] = false;
		CPrintToChat(client, "[{olive}Pause{default}] Panel is now {blue}on{default}.");
	}
}

public Action Hide_Cmd(int client, int args)
{
	if (isPaused)
	{
		hiddenPanel[client] = true;
		CPrintToChat(client, "[{olive}Pause{default}] Panel is now {red}off{default}.");
	}
}

public Action MenuRefresh_Timer(Handle timer)
{
	if (isPaused)
	{
		UpdatePanel();
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public int DummyHandler(Menu menu, MenuAction action, int param1, int param2) { }

void UpdatePanel()
{
	Panel menuPanel = new Panel();
	
	char info[512];
	serverNamerCvar.GetString(info, sizeof(info));
	
	Format(info, sizeof(info), "▸ Server: %s\n▸ Slots: %d/%d", info, GetSeriousClientCount(), FindConVar("sv_maxplayers").IntValue);
	menuPanel.DrawText(info);
	
	FormatTime(info, sizeof(info), "▸ %m/%d/%Y - %I:%M%p");
	menuPanel.DrawText(info);
	
	menuPanel.DrawText(" ");
	menuPanel.DrawText("▸ Ready Status");

	if (adminPause)
	{
		menuPanel.DrawText("->1. Require Admin to Unpause");
		menuPanel.DrawText(teamReady[L4D2Team_Survivor] ? "->2. Survivors: [√]" : "->2. Survivors: [X]");
		menuPanel.DrawText(teamReady[L4D2Team_Infected] ? "->3. Infected: [√]" : "->3. Infected: [X]");
	}
	else if (initiatorReadyCvar.BoolValue)
	{
		menuPanel.DrawText(initiatorReady ? "->1. Initiator: [√]" : "->1. Initiator: [X]");
		menuPanel.DrawText(teamReady[L4D2Team_Survivor] ? "->2. Survivors: [√]" : "->2. Survivors: [X]");
		menuPanel.DrawText(teamReady[L4D2Team_Infected] ? "->3. Infected: [√]" : "->3. Infected: [X]");
	} 
	else
	{
		menuPanel.DrawText(teamReady[L4D2Team_Survivor] ? "->1. Survivors: [√]" : "->1. Survivors: [X]");
		menuPanel.DrawText(teamReady[L4D2Team_Infected] ? "->2. Infected: [√]" : "->2. Infected: [X]");
	}

	menuPanel.DrawText(" ");
	
	char name[MAX_NAME_LENGTH];

	int initiator = GetClientOfUserId(initiatorId);
	if (initiator > 0)
	{
		GetClientName(initiator, name, sizeof(name));
	}

	if (adminPause)
	{
		Format(info, sizeof(info), "▸ Force Pause -> %s (Admin)", strlen(name) ? name : initiatorName);
	}
	else
	{
		Format(info, sizeof(info), "▸ Initiator -> %s (%s)", strlen(name) ? name : initiatorName, L4D2_TeamName[pauseTeam]);
	}
	
	menuPanel.DrawText(info);
		
	int duration = RoundToNearest(GetEngineTime() - pauseTime);
	FormatEx(info, sizeof(info), "▸ Duration: %02d:%02d", duration / 60, duration % 60);
	menuPanel.DrawText(info);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && !hiddenPanel[client])
		{
			if (!BuiltinVote_IsVoteInProgress() || !IsClientInBuiltinVotePool(client))
			{
				menuPanel.Send(client, DummyHandler, 1);
			}
		}
	}
	
	delete menuPanel;
}

// ======================================
// Unpause Process
// ======================================

void InitiateLiveCountdown()
{
	if (readyCountdownTimer == null)
	{
		CPrintToChatAll("{default}[{green}!{default}] Say {olive}!unready {default}to cancel");
		readyDelay = l4d_ready_delay.IntValue;
		readyCountdownTimer = CreateTimer(1.0, ReadyCountdownDelay_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action ReadyCountdownDelay_Timer(Handle timer)
{
	if (readyDelay == 0)
	{
		Unpause();
		PrintHintTextToAll("Game is live!");
		return Plugin_Stop;
	}
	else
	{
		CPrintToChatAll("{default}[{green}!{default}] {blue}Live in{default}: {olive}%d{default}...", readyDelay);
		readyDelay--;
	}
	return Plugin_Continue;
}

bool CheckFullReady()
{
	int InitiatorClient = GetClientOfUserId(initiatorId);

	return (teamReady[L4D2Team_Survivor] || GetTeamHumanCount(L4D2Team_Survivor) == 0)
		&& (teamReady[L4D2Team_Infected] || GetTeamHumanCount(L4D2Team_Infected) == 0)
		&& (!initiatorReadyCvar.BoolValue || initiatorReady || !IsPlayer(InitiatorClient));
}

void CancelFullReady(int client)
{
	if (readyCountdownTimer != null && !adminPause)
	{
		delete readyCountdownTimer;
		CPrintToChatAll("{default}[{green}!{default}] {olive}%N {default}cancelled the countdown!", client);
	}
}

// ======================================
// Spectate Fix
// ======================================

public Action Spectate_Cmd(int client, int args)
{
	if (SpecTimer[client] != null)
	{
		delete SpecTimer[client];
	}
	
	SpecTimer[client] = CreateTimer(3.0, SecureSpec, client);
}

public Action SecureSpec(Handle timer, any client)
{
	SpecTimer[client] = null;
	return Plugin_Stop;
}

// ======================================
// Command Listeners
// ======================================

void ToggleCommandListeners(bool enable)
{
	static bool listened = false;
	if (enable && !listened)
	{
		AddCommandListener(Say_Callback, "say");
		AddCommandListener(TeamSay_Callback, "say_team");
		AddCommandListener(Unpause_Callback, "unpause");
		AddCommandListener(Callvote_Callback, "callvote");
	}
	else if (!enable && listened)
	{
		RemoveCommandListener(Say_Callback, "say");
		RemoveCommandListener(TeamSay_Callback, "say_team");
		RemoveCommandListener(Unpause_Callback, "unpause");
		RemoveCommandListener(Callvote_Callback, "callvote");
	}
}

public Action Callvote_Callback(int client, char[] command, int argc)
{
	if (view_as<L4D2_Team>(GetClientTeam(client)) == L4D2Team_Spectator)
	{
		CPrintToChat(client, "{blue}[{green}!{blue}] {default}You're unable to call votes as a spectator.");
		return Plugin_Handled;
	}

	if (SpecTimer[client])
	{
		CPrintToChat(client, "{blue}[{green}!{blue}] {default}You've just switched Teams, you are unable to vote for a few seconds.");
		return Plugin_Handled;
	}
	
	// kick vote from client, "callvote %s \"%d %s\"\n;"
	if (argc < 2)
	{
		return Plugin_Continue;
	}
	
	char votereason[16];
	GetCmdArg(1, votereason, 16);
	if (!!strcmp(votereason, "kick", false))
	{
		return Plugin_Continue;
	}
	
	char therest[256];
	GetCmdArg(2, therest, sizeof(therest));
	
	int userid;
	int spacepos = FindCharInString(therest, ' ', false);
	if (spacepos > -1)
	{
		char temp[12];
		strcopy(temp, L4D2Util_GetMin(spacepos + 1, sizeof(temp)), therest);
		userid = StringToInt(temp);
	}
	else
	{
		userid = StringToInt(therest);
	}
	
	int target = GetClientOfUserId(userid);
	if (target < 1)
	{
		return Plugin_Continue;
	}
	
	AdminId clientAdmin = GetUserAdmin(client);
	AdminId targetAdmin = GetUserAdmin(target);
	if (clientAdmin == INVALID_ADMIN_ID && targetAdmin == INVALID_ADMIN_ID)
	{
		return Plugin_Continue;
	}
	
	if (CanAdminTarget(clientAdmin, targetAdmin))
	{
		return Plugin_Continue;
	}
	
	CPrintToChat(client, "{blue}[{green}!{blue}] {default}You may not kick Admins.", target);
	return Plugin_Handled;
}

public Action Say_Callback(int client, char[] command, int argc)
{
	if (isPaused)
	{
		char buffer[256];
		GetCmdArgString(buffer, sizeof(buffer));
		StripQuotes(buffer);
		if (IsChatTrigger() || buffer[0] == '!' || buffer[0] == '/')  // Hidden command or chat trigger
		{
			return Plugin_Handled;
		}
		if (client == 0)
		{
			PrintToChatAll("Console : %s", buffer);
		}
		else
		{
			CPrintToChatAllEx(client, "{teamcolor}%N{default} : %s", client, buffer);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action TeamSay_Callback(int client, char[] command, int argc)
{
	if (isPaused)
	{
		char buffer[256];
		GetCmdArgString(buffer, sizeof(buffer));
		StripQuotes(buffer);
		if (IsChatTrigger() || buffer[0] == '!' || buffer[0] == '/')  // Hidden command or chat trigger
		{
			return Plugin_Handled;
		}
		PrintToTeam(client, view_as<L4D2_Team>(GetClientTeam(client)), buffer);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Unpause_Callback(int client, char[] command, int argc)
{
	return (isPaused) ? Plugin_Handled : Plugin_Continue;
}

// ======================================
// Natives
// ======================================

public int Native_IsInPause(Handle plugin, int numParams)
{
	return isPaused;
}

// ======================================
// Helpers
// ======================================

stock bool IsPlayer(int client)
{
	if (!client) return false;
	
	L4D2_Team team = view_as<L4D2_Team>(GetClientTeam(client));
	return !SpecTimer[client] && (team == L4D2Team_Survivor || team == L4D2Team_Infected);
}

stock void PrintToTeam(int author, L4D2_Team team, const char[] buffer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && view_as<L4D2_Team>(GetClientTeam(client)) == team)
		{
			CPrintToChatEx(client, author, "(%s) {teamcolor}%N{default} :  %s", L4D2_TeamName[GetClientTeam(author)], author, buffer);
		}
	}
}

stock int GetSeriousClientCount()
{
	int clients = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			clients++;
		}
	}
	
	return clients;
}

stock int GetTeamHumanCount(L4D2_Team team)
{
	int humans = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && view_as<L4D2_Team>(GetClientTeam(client)) == team)
		{
			humans++;
		}
	}
	
	return humans;
}

stock bool IsSurvivorReviving()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && view_as<L4D2_Team>(GetClientTeam(client)) == L4D2Team_Survivor && IsPlayerAlive(client))
		{
			if (GetEntProp(client, Prop_Send, "m_reviveTarget") > 0)
			{
				return true;
			}
		}
	}
	return false;
}

stock void SetClientButtons(int client, int buttons)
{
	if (IsClientInGame(client))
	{
		SetEntProp(client, Prop_Data, "m_nButtons", buttons);
	}
}
