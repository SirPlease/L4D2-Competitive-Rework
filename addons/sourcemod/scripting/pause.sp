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

#include <sourcemod>
#include <colors>
#include <builtinvotes>
#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN

#define min(%0,%1) (((%0) < (%1)) ? (%0) : (%1))

public Plugin myinfo =
{
	name = "Pause plugin",
    author = "CanadaRox, Sir, Forgetest",
    description = "Adds pause functionality without breaking pauses, also prevents SI from spawning because of the Pause.",
    version = "6.2",
	url = ""
};

enum L4D2_Team
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected
}

static const char teamString[L4D2_Team][] =
{
	"None",
	"Spectator",
	"Survivors",
	"Infected"
};

// Game ConVar
ConVar sv_pausable, sv_noclipduringpause;

// Plugin Handle
GlobalForward pauseForward, unpauseForward;
Handle readyCountdownTimer, deferredPauseTimer;

// Plugin ConVar
ConVar pauseDelayCvar, l4d_ready_delay;

// Plugin Vars
int	readyDelay, pauseDelay;
bool adminPause, isPaused, RoundEnd, teamReady[L4D2_Team];

// Ready Up Available
bool readyUpIsAvailable;

// Pause Fix
Handle SpecTimer[MAXPLAYERS+1];
int IgnorePlayer[MAXPLAYERS+1];

// Pause Panel
Panel menuPanel;
float g_fPauseTime;
L4D2_Team g_PauseTeam;
bool hiddenPanel[MAXPLAYERS+1], hiddenManually[MAXPLAYERS+1];

// Initiator Struct
enum struct Player {
	int userid;
	void Set(int userid) {
		this.userid = userid;
	}
	int GetClient() {
		return GetClientOfUserId(this.userid);
	}
	bool InGame() {
		int client = GetClientOfUserId(this.userid);
		return client > 0 && IsClientInGame(client);
	}
	void Clear() {
		this.userid = 0;
	}
}
Player g_eInitiator;

// Initiator Vars
ConVar initiatorReadyCvar;
char g_szInitiatorName[MAX_NAME_LENGTH];
bool g_bEnableInitReady, g_bInitiatorReady;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("IsInPause", Native_IsInPause);
	pauseForward = new GlobalForward("OnPause", ET_Event);
	unpauseForward = new GlobalForward("OnUnpause", ET_Event);
	RegPluginLibrary("pause");

	MarkNativeAsOptional("IsInReady");
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_spectate", Spectate_Cmd, "Moves you to the spectator team");
	RegConsoleCmd("sm_spec", Spectate_Cmd, "Moves you to the spectator team");
	RegConsoleCmd("sm_s", Spectate_Cmd, "Moves you to the spectator team");
	
	RegConsoleCmd("sm_pause", Pause_Cmd, "Pauses the game");
	RegConsoleCmd("sm_unpause", Unpause_Cmd, "Marks your team as ready for an unpause");
	RegConsoleCmd("sm_ready", Unpause_Cmd, "Marks your team as ready for an unpause");
	RegConsoleCmd("sm_unready", Unready_Cmd, "Marks your team as ready for an unpause");
	RegConsoleCmd("sm_toggleready", ToggleReady_Cmd, "Toggles your team's ready status");

	RegConsoleCmd("sm_show", Show_Cmd, "Hides the pause panel so other menus can be seen");
	RegConsoleCmd("sm_hide", Hide_Cmd, "Shows a hidden pause panel");
	
	RegAdminCmd("sm_forcepause", ForcePause_Cmd, ADMFLAG_BAN, "Pauses the game and only allows admins to unpause");
	RegAdminCmd("sm_forceunpause", ForceUnpause_Cmd, ADMFLAG_BAN, "Unpauses the game regardless of team ready status.  Must be used to unpause admin pauses");

	AddCommandListener(Say_Callback, "say");
	AddCommandListener(TeamSay_Callback, "say_team");
	AddCommandListener(Unpause_Callback, "unpause");
	AddCommandListener(Callvote_Callback, "callvote");

	sv_pausable = FindConVar("sv_pausable");
	sv_noclipduringpause = FindConVar("sv_noclipduringpause");

	pauseDelayCvar = CreateConVar("sm_pausedelay", "0", "Delay to apply before a pause happens.  Could be used to prevent Tactical Pauses", FCVAR_NONE, true, 0.0);
	initiatorReadyCvar = CreateConVar("sm_initiatorready", "0", "Require or not the pause initiator should ready before unpausing the game", FCVAR_NONE, true, 0.0);
	l4d_ready_delay = FindConVar("l4d_ready_delay");
	
	g_bEnableInitReady = GetConVarBool(initiatorReadyCvar);
	HookConVarChange(initiatorReadyCvar, OnInitiatorReadyChanged);

	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
	HookEvent("round_start", RoundStart_Event);
}

public void OnInitiatorReadyChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bEnableInitReady = GetConVarBool(initiatorReadyCvar);
}

public void OnAllPluginsLoaded() { readyUpIsAvailable = LibraryExists("readyup"); }
public void OnLibraryRemoved(const char[] name) { if (StrEqual(name, "readyup")) readyUpIsAvailable = false; }
public void OnLibraryAdded(const char[] name) { if (StrEqual(name, "readyup")) readyUpIsAvailable = true; }

public int Native_IsInPause(Handle plugin, int numParams)
{
	return isPaused;
}

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
	if (isPaused && CheckFullReady())
	{
		InitiateLiveCountdown();
	}
	hiddenPanel[client] = false;
	hiddenManually[client] = false;
}

public void OnMapEnd()
{
	readyCountdownTimer = null;
	deferredPauseTimer = null;
}

public void RoundEnd_Event(Event event, const char[] name, bool dontBroadcast)
{
	if (deferredPauseTimer != null)
	{
		KillTimer(deferredPauseTimer);
		deferredPauseTimer = null;
	}
	RoundEnd = true;
}

public void RoundStart_Event(Event event, const char[] name, bool dontBroadcast)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			IgnorePlayer[client] = 0;
		}
	}
	RoundEnd = false;
}

public Action Spectate_Cmd(int client, int args)
{
	if (IgnorePlayer[client] <= 10) IgnorePlayer[client] += 2;
	if (SpecTimer[client] == null) SpecTimer[client] = CreateTimer(1.0, SecureSpec, client, TIMER_REPEAT);
}

public Action SecureSpec(Handle timer, int client)
{
	if (--IgnorePlayer[client] > 0) return Plugin_Continue;
	
	SpecTimer[client] = null;
	return Plugin_Stop;
}

public Action Pause_Cmd(int client, int args)
{
	if ((!readyUpIsAvailable || !IsInReady()) && pauseDelay == 0 && !isPaused && IsPlayer(client) && !RoundEnd)
	{
		CPrintToChatAll("{default}[{green}!{default}] {olive}%N {blue}Paused{default}.", client);
		g_eInitiator.Set(GetClientUserId(client));
		g_PauseTeam = L4D2_Team:GetClientTeam(client);
		GetClientName(client, g_szInitiatorName, sizeof(g_szInitiatorName));
		
		pauseDelay = GetConVarInt(pauseDelayCvar);
		if (pauseDelay == 0)
			AttemptPause();
		else
			CreateTimer(1.0, PauseDelay_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
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

public Action Unpause_Cmd(int client, int args)
{
	if (isPaused && IsPlayer(client))
	{
		L4D2_Team clientTeam = L4D2_Team:GetClientTeam(client);
		int initiator = g_eInitiator.GetClient();
		if (!teamReady[clientTeam])
		{
			switch (clientTeam)
			{
				case L4D2Team_Survivor:
					CPrintToChatAll("{default}[{green}!{default}] {olive}%N %s{default}marked {blue}%s {default}ready.", client, (g_bEnableInitReady && client == initiator) ? "{default}as {green}Initiator " : "", teamString[clientTeam]);
				case L4D2Team_Infected:
					CPrintToChatAll("{default}[{green}!{default}] {olive}%N %s{default}marked {red}%s {default}ready.", client, (g_bEnableInitReady && client == initiator) ? "{default}as {green}Initiator " : "", teamString[clientTeam]);					
			}
		}
		if (g_bEnableInitReady)
		{
			if (client == initiator && !g_bInitiatorReady)
			{
				g_bInitiatorReady = true;
				if (teamReady[clientTeam])
				{
					CPrintToChatAll("{default}[{green}!{default}] {olive}%N {default}marked {green}Initiator {default}ready.", client);
				}
			}
		}
		teamReady[clientTeam] = true;
		if (CheckFullReady())
		{
			if (!adminPause) {
				InitiateLiveCountdown();
			} else {
				CPrintToChatAll("{default}[{green}!{default}] {olive}Teams {default}are ready. Wait for {blue}Admin {default}to {green}confirm{default}.");
			}
		}
	}
}

public Action Unready_Cmd(int client, int args)
{
	if (isPaused && IsPlayer(client))
	{
		L4D2_Team clientTeam = L4D2_Team:GetClientTeam(client);
		int initiator = g_eInitiator.GetClient();
		if (teamReady[clientTeam])
		{
			switch (clientTeam)
			{
				case L4D2Team_Survivor:
					CPrintToChatAll("{default}[{green}!{default}] {olive}%N %s{default}marked {blue}%s {default}not ready.", client, (g_bEnableInitReady && client == initiator) ? "{default}as {green}Initiator " : "", teamString[clientTeam]);
				case L4D2Team_Infected:
					CPrintToChatAll("{default}[{green}!{default}] {olive}%N %s{default}marked {red}%s {default}not ready.", client, (g_bEnableInitReady && client == initiator) ? "{default}as {green}Initiator " : "", teamString[clientTeam]);
			}
		}
		if (g_bEnableInitReady)
		{
			if (client == initiator && g_bInitiatorReady)
			{
				g_bInitiatorReady = false;
				if (!teamReady[clientTeam])
				{
					CPrintToChatAll("{default}[{green}!{default}] {olive}%N {default}marked {green}Initiator {default}not ready.", client);
				}
			}
		}
		teamReady[clientTeam] = false;
		
		if (!adminPause) CancelFullReady(client);
	}
}

public Action ToggleReady_Cmd(int client, int args)
{
	L4D2_Team clientTeam = L4D2_Team:GetClientTeam(client);
	teamReady[clientTeam] ? Unready_Cmd(client, 0) : Unpause_Cmd(client, 0);
}

public Action Show_Cmd(int client, int args)
{
	if (isPaused)
	{
		hiddenPanel[client] = false;
		hiddenManually[client] = false;
		CPrintToChat(client, "[{olive}Pause{default}] Panel is now {blue}on{default}.");
	}
}

public Action Hide_Cmd(int client, int args)
{
	if (isPaused)
	{
		hiddenPanel[client] = true;
		hiddenManually[client] = true;
		CPrintToChat(client, "[{olive}Pause{default}] Panel is now {red}off{default}.");
	}
}

public Action ForcePause_Cmd(int client, int args)
{
	if (!isPaused)
	{
		adminPause = true;
		g_eInitiator.Set(GetClientUserId(client));
		GetClientName(client, g_szInitiatorName, sizeof(g_szInitiatorName));
		Pause();
	}
}

public Action ForceUnpause_Cmd(int client, int args)
{
	if (isPaused)
	{
		adminPause = true;
		InitiateLiveCountdown();
	}
}

AttemptPause()
{
	if (deferredPauseTimer == null)
	{
		if (CanPause())
		{
			Pause();
		}
		else
		{
			CPrintToChatAll("{default}[{green}!{default}] {red}Pause has been delayed due to a pick-up in progress!");
			deferredPauseTimer = CreateTimer(0.1, DeferredPause_Timer, _, TIMER_REPEAT);
		}
	}
}

public Action DeferredPause_Timer(Handle timer)
{
	if (CanPause())
	{
		deferredPauseTimer = INVALID_HANDLE;
		Pause();
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

Pause()
{
	for (L4D2_Team team; team < L4D2_Team; team++)
	{
		teamReady[team] = false;
	}
	g_bInitiatorReady = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		hiddenPanel[i] = false;
		hiddenManually[i] = false;
	}

	g_fPauseTime = GetEngineTime();
	isPaused = true;
	readyCountdownTimer = INVALID_HANDLE;

	CreateTimer(1.0, MenuRefresh_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	bool pauseProcessed = false;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			if (L4D2_Team:GetClientTeam(client) == L4D2Team_Infected && IsGhost(client))
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
				sv_pausable.SetBool(true);
				FakeClientCommand(client, "pause");
				sv_pausable.SetBool(false);
				pauseProcessed = true;
			}
			if (L4D2_Team:GetClientTeam(client) == L4D2Team_Spectator)
			{
				sv_noclipduringpause.ReplicateToClient(client, "1");
			}
		}
	}
	
	Call_StartForward(pauseForward);
	Call_Finish();
}

Unpause()
{
	isPaused = false;
	adminPause = false;

	bool unpauseProcessed = false;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			if(!unpauseProcessed)
			{
				SetConVarBool(sv_pausable, true);
				FakeClientCommand(client, "unpause");
				SetConVarBool(sv_pausable, false);
				unpauseProcessed = true;
			}
			if (L4D2_Team:GetClientTeam(client) == L4D2Team_Spectator)
			{
				sv_noclipduringpause.ReplicateToClient(client, "0");
			}
		}
	}
	g_eInitiator.Clear();
	g_bInitiatorReady = false;
	g_szInitiatorName = "";
	g_PauseTeam = L4D2Team_None;
	
	Call_StartForward(unpauseForward);
	Call_Finish();
}

public Action MenuRefresh_Timer(Handle timer)
{
	if (isPaused)
	{
		UpdatePanel();
		return Plugin_Continue;
	}
	if (menuPanel != null) delete menuPanel;
	return Plugin_Stop;
}

UpdatePanel()
{
	if (menuPanel != null)
	{
		delete menuPanel;
	}
	
	if (BuiltinVote_IsVoteInProgress())
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsClientInBuiltinVotePool(i)) hiddenPanel[i] = true;
		}
	}
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !hiddenManually[i]) hiddenPanel[i] = false;
		}
	}

	char info[512];
	menuPanel = new Panel();
	
	ConVar sn_main_name = FindConVar("sn_main_name");
	if (sn_main_name != null)
		sn_main_name.GetString(info, sizeof(info));
	else FindConVar("hostname").GetString(info, sizeof(info));
	
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
	else if (g_bEnableInitReady)
	{
		menuPanel.DrawText(g_bInitiatorReady ? "->1. Initiator: [√]" : "->1. Initiator: [X]");
		menuPanel.DrawText(teamReady[L4D2Team_Survivor] ? "->2. Survivors: [√]" : "->2. Survivors: [X]");
		menuPanel.DrawText(teamReady[L4D2Team_Infected] ? "->3. Infected: [√]" : "->3. Infected: [X]");
	} 
	else
	{
		menuPanel.DrawText(teamReady[L4D2Team_Survivor] ? "->1. Survivors: [√]" : "->1. Survivors: [X]");
		menuPanel.DrawText(teamReady[L4D2Team_Infected] ? "->2. Infected: [√]" : "->2. Infected: [X]");
	}

	menuPanel.DrawText(" ");

	int initiator = g_eInitiator.GetClient();
	char name[MAX_NAME_LENGTH];
	if (g_eInitiator.InGame())
	{
		GetClientName(initiator, name, sizeof(name));
	}

	if (adminPause)
	{
		FormatEx(info, sizeof(info), "▸ Force Pause -> %s (Admin)", (name[0] == '\0') ? g_szInitiatorName : name);
	}
	else FormatEx(info, sizeof(info), "▸ Initiator -> %s (%s)", (name[0] == '\0') ? g_szInitiatorName : name, teamString[g_PauseTeam]);

	menuPanel.DrawText(info);
		
	int duration = RoundToNearest(GetEngineTime() - g_fPauseTime);
	FormatEx(info, sizeof(info), "▸ Duration: %s%d:%s%d", duration / 60 < 10 ? "0" : "", duration / 60, duration % 60 < 10 ? "0" : "", duration % 60);
	menuPanel.DrawText(info);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && !hiddenPanel[client])
		{
			menuPanel.Send(client, DummyHandler, 1);
		}
	}
}

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

CancelFullReady(client)
{
	if (readyCountdownTimer != null && !adminPause)
	{
		KillTimer(readyCountdownTimer);
		readyCountdownTimer = null;
		CPrintToChatAll("{default}[{green}!{default}] {olive}%N {default}cancelled the countdown!", client);
	}
}

public Action Callvote_Callback(int client, char[] command, int argc)
{
	if (L4D2_Team:GetClientTeam(client) == L4D2Team_Spectator)
	{
		CPrintToChat(client, "{blue}[{green}!{blue}] {default}You're unable to call votes as a spectator.");
		return Plugin_Handled;
	}
	if (IgnorePlayer[client] > 0)
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
	GetCmdArg(2, therest, 256);
	
	int userid;
	int spacepos = FindCharInString(therest, ' ', false);
	if (spacepos > -1)
	{
		char temp[12];
		strcopy(temp, min(spacepos + 1, sizeof(temp)), therest);
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
		return Plugin_Continue;
		
	if (CanAdminTarget(clientAdmin, targetAdmin))
		return Plugin_Continue;
		
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
		PrintToTeam(client, L4D2_Team:GetClientTeam(client), buffer);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Unpause_Callback(int client, char[] command, int argc)
{
	if (isPaused)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool CheckFullReady()
{
	return (teamReady[L4D2Team_Survivor] || GetTeamHumanCount(L4D2Team_Survivor) == 0)
		&& (teamReady[L4D2Team_Infected] || GetTeamHumanCount(L4D2Team_Infected) == 0)
		&& (!g_bEnableInitReady || g_bInitiatorReady || !g_eInitiator.InGame() || !IsPlayer(g_eInitiator.GetClient()));
}

stock bool IsPlayer(client)
{
	L4D2_Team team = L4D2_Team:GetClientTeam(client);
	return (client && IgnorePlayer[client] <= 0 && (team == L4D2Team_Survivor || team == L4D2Team_Infected));
}

stock void PrintToTeam(int author, L4D2_Team team, const char[] buffer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && L4D2_Team:GetClientTeam(client) == team)
		{
			CPrintToChatEx(client, author, "(%s) {teamcolor}%N{default} :  %s", teamString[L4D2_Team:GetClientTeam(author)], author, buffer);
		}
	}
}

public DummyHandler(Menu menu, MenuAction action, int param1, int param2) { }

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

stock int GetTeamHumanCount(L4D2_Team:team)
{
	int humans = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && L4D2_Team:GetClientTeam(client) == team)
		{
			humans++;
		}
	}
	
	return humans;
}

stock bool IsPlayerIncap(client) { return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated")); }

bool CanPause()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && L4D2_Team:GetClientTeam(client) == L4D2Team_Survivor)
		{
			if (IsPlayerIncap(client))
			{
				if (GetEntProp(client, Prop_Send, "m_reviveOwner") > 0)
				{
					return false;
				}
			}
			else
			{
				if (GetEntProp(client, Prop_Send, "m_reviveTarget") > 0)
				{
					return false;
				}
			}
		}
	}
	return true;
}

bool IsGhost(client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}

void SetClientButtons(int client, int buttons)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		SetEntProp(client, Prop_Data, "m_nButtons", buttons);
	}
}

