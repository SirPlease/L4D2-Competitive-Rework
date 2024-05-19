#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>

#define ZC_TANK	 8

#define GAMEDATA "l4d2_si_ability"

public Plugin myinfo =
{
	name		= "Player Management Plugin",
	author		= "CanadaRox",
	description = "Player management!  Swap players/teams and spectate!",
	version		= "7.1",
	url			= ""
};

enum L4D2Team
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected,
	L4D2Team_L4D1_Survivor,	   // Probably for maps that contain survivors from the first part and from part 2

	L4D2Team_Size	 // 5 size
}

static const L4D2Team oppositeTeamMap[view_as<int>(L4D2Team_Size)] = {
	L4D2Team_None,
	L4D2Team_Spectator,
	L4D2Team_Infected,
	L4D2Team_Survivor,
	L4D2Team_L4D1_Survivor
};

ConVar	 survivor_limit;
ConVar	 z_max_player_zombies;
ConVar	 sm_allow_spectate_command;
ConVar	 g_cvarBlockInTank;

L4D2Team pendingSwaps[MAXPLAYERS + 1];
bool	 blockVotes[MAXPLAYERS + 1];
bool	 isMapActive;
Handle	 SpecTimer[MAXPLAYERS + 1];

int		 m_queuedPummelAttacker = -1;
ConVar	 l4d_pm_supress_spectate;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	isMapActive = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadGamedata();

	LoadTranslation("common.phrases");
	LoadTranslation("playermanagement.phrases");

	RegAdminCmd("sm_swap", Swap_Cmd, ADMFLAG_KICK, "sm_swap <player1> [player2] ... [playerN] - swap all listed players to opposite teams");
	RegAdminCmd("sm_swapto", SwapTo_Cmd, ADMFLAG_KICK, "sm_swapto [force] <teamnum> <player1> [player2] ... [playerN] - swap all listed players to <teamnum> (1,2, or 3)");
	RegAdminCmd("sm_swapteams", SwapTeams_Cmd, ADMFLAG_KICK, "sm_swapteams - swap the players between both teams");
	RegAdminCmd("sm_fixbots", FixBots_Cmd, ADMFLAG_BAN, "sm_fixbots - Spawns survivor bots to match survivor_limit");
	RegConsoleCmd("sm_spectate", Spectate_Cmd, "Moves you to the spectator team");
	RegConsoleCmd("sm_spec", Spectate_Cmd, "Moves you to the spectator team");
	RegConsoleCmd("sm_s", Spectate_Cmd, "Moves you to the spectator team");

	sm_allow_spectate_command = CreateConVar("sm_allow_spectate_command", "1", "Allow players to use !spectate/!spec/!s");
	g_cvarBlockInTank		  = CreateConVar("sm_blockspecintank", "0", "Block suvivors from switching to spect while in tank", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AddCommandListener(TeamChange_Listener, "jointeam");

	survivor_limit = FindConVar("survivor_limit");
	survivor_limit.AddChangeHook(survivor_limitChanged);

	z_max_player_zombies	= FindConVar("z_max_player_zombies");

	l4d_pm_supress_spectate = CreateConVar("l4d_pm_supress_spectate", "0", "Don't print messages when players spectate");
}

void LoadGamedata()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);

	if (!hGamedata)
	{
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}

	m_queuedPummelAttacker = GameConfGetOffset(hGamedata, "CTerrorPlayer->m_queuedPummelAttacker");
	if (m_queuedPummelAttacker == -1)
	{
		SetFailState("Failed to get offset 'CTerrorPlayer->m_queuedPummelAttacker'.");
	}

	delete hGamedata;
}

public void OnPluginEnd()
{
	char name[MAX_NAME_LENGTH];
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientConnected(i) && IsFakeClient(i) && GetClientName(i, name, sizeof name) && StrContains(name, "k9Q6CK42") != -1)
		{
			KickClient(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	blockVotes[client] = false;
}

public void OnMapStart()
{
	isMapActive = true;
	HookEntityOutput("info_director", "OnGameplayStart", OnGameplayStart);
}

public void OnMapEnd()
{
	isMapActive = false;
}

void OnGameplayStart(const char[] output, int caller, int activator, float delay)
{
	if (GetHumanCount()) FixBotCount();
}

public Action FixBots_Cmd(int client, int args)
{
	if (client != 0)
	{
		PrintToChatAll("%t %t", "Tag", "FixBot", client);
	}
	else
	{
		PrintToChatAll("%t %t", "Tag", "FixBotConsole");
	}
	FixBotCount();
	return Plugin_Handled;
}

void survivor_limitChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (isMapActive && GetHumanCount()) FixBotCount();
}

public Action Spectate_Cmd(int client, int args)
{
	if (!sm_allow_spectate_command.BoolValue)
	{
		return Plugin_Handled;
	}

	L4D2Team team = GetClientTeamEx(client);
	if (team == L4D2Team_Survivor)
	{
		if (g_cvarBlockInTank.BoolValue && L4D2_IsTankInPlay())
		{
			CPrintToChat(client, "%t %t", "Tag", "NoSnoop");
			return Plugin_Handled;
		}

		if ((L4D2_GetInfectedAttacker(client) != -1 && !L4D_IsPlayerIncapacitated(client)) || GetPummelQueueAttacker(client) != -1)
		{
			CPrintToChat(client, "%t %t", "Tag", "WhileCapped");
			return Plugin_Handled;
		}
		else
		{
			ChangeClientTeamEx(client, L4D2Team_Spectator, true);
		}
	}
	else if (team == L4D2Team_Infected)
	{
		if (GetZombieClass(client) != ZC_TANK && !IsGhost(client))
		{
			ForcePlayerSuicide(client);
		}
		else if (GetZombieClass(client) == ZC_TANK) return Plugin_Handled;
		ChangeClientTeamEx(client, L4D2Team_Spectator, true);
	}
	else
	{
		blockVotes[client] = true;
		ChangeClientTeamEx(client, L4D2Team_Infected, true);
		CreateTimer(0.1, RespecDelay_Timer, client);
	}

	if (!GetConVarBool(l4d_pm_supress_spectate) && team != L4D2Team_Spectator && SpecTimer[client] == INVALID_HANDLE)
	{
		CPrintToChatAllEx(client, "%t %t", "Tag", "BecomeSpectator", client);
	}

	if (SpecTimer[client] == INVALID_HANDLE) SpecTimer[client] = CreateTimer(7.0, SecureSpec, client);
	return Plugin_Handled;
}

public Action SecureSpec(Handle timer, any client)
{
	KillTimer(SpecTimer[client]);
	SpecTimer[client] = INVALID_HANDLE;

	return Plugin_Stop;
}

public Action RespecDelay_Timer(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		ChangeClientTeamEx(client, L4D2Team_Spectator, true);
		blockVotes[client] = false;
	}

	return Plugin_Stop;
}

public Action L4D_OnEnterGhostStatePre(int client)
{
	return blockVotes[client] ? Plugin_Handled : Plugin_Continue;
}

public Action TeamChange_Listener(int client, const char[] command, int argc)
{
	// Invalid
	if (!IsClientInGame(client) || argc < 1)
		return Plugin_Handled;

	// Not a jockey with a victim, don't care
	if (GetClientTeamEx(client) != L4D2Team_Infected
		|| GetZombieClass(client) != 5
		|| GetEntProp(client, Prop_Send, "m_jockeyVictim") < 1)
		return Plugin_Continue;

	// Block Jockey from switching team.
	return Plugin_Handled;
}

public Action OnClientCommand(int client, int args)
{
	return blockVotes[client] ? Plugin_Handled : Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	return blockVotes[client] ? Plugin_Stop : Plugin_Continue;
}

public Action SwapTeams_Cmd(int client, int args)
{
	for (int cli = 1; cli <= MaxClients; cli++)
	{
		if (IsClientInGame(cli) && !IsFakeClient(cli) && IsPlayer(cli))
		{
			pendingSwaps[cli] = oppositeTeamMap[GetClientTeam(cli)];
		}
	}
	ApplySwaps(client, false);
	return Plugin_Handled;
}

bool IsGhost(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isGhost", 1);
}

public Action Swap_Cmd(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "%t %t: sm_swap <player1> <player2> ... <playerN>", "Tag", "Usage");
		return Plugin_Handled;
	}

	char argbuf[MAX_NAME_LENGTH], target_name[MAX_TARGET_LENGTH];
	int[] targets = new int[MaxClients + 1];
	int	 target, targetCount;
	bool tn_is_ml;

	for (int i = 1; i <= args; i++)
	{
		GetCmdArg(i, argbuf, sizeof(argbuf));
		targetCount = ProcessTargetString(
			argbuf,
			0,
			targets,
			MaxClients + 1,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml);

		for (int j = 0; j < targetCount; j++)
		{
			target = targets[j];
			if (IsClientInGame(target))
			{
				pendingSwaps[target] = oppositeTeamMap[GetClientTeamEx(target)];
			}
		}
	}

	ApplySwaps(client, false);

	return Plugin_Handled;
}

public Action SwapTo_Cmd(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "%t %t: sm_swapto <teamnum> <player1> <player2> ... <playerN>\n%d = Spectators, %d = Survivors, %d = Infected", "Tag", "Usage", L4D2Team_Spectator, L4D2Team_Survivor, L4D2Team_Infected);
		ReplyToCommand(client, "%t %t: sm_swapto force <teamnum> <player1> <player2> ... <playerN>\n%d = Spectators, %d = Survivors, %d = Infected", "Tag", "Usage", L4D2Team_Spectator, L4D2Team_Survivor, L4D2Team_Infected);
		return Plugin_Handled;
	}

	char argbuf[MAX_NAME_LENGTH];
	bool force = false;

	GetCmdArg(1, argbuf, sizeof(argbuf));
	if (StrEqual(argbuf, "force"))
	{
		force = true;
		GetCmdArg(2, argbuf, sizeof(argbuf));
	}

	L4D2Team team = view_as<L4D2Team>(StringToInt(argbuf));
	if (team < L4D2Team_Spectator || team > L4D2Team_Infected)
	{
		ReplyToCommand(client, "%t %t", "Tag", "ValidTeams", L4D2Team_Spectator, L4D2Team_Survivor, L4D2Team_Infected);
		return Plugin_Handled;
	}

	int[] targets = new int[MaxClients + 1];
	int	 target, targetCount;
	char target_name[MAX_TARGET_LENGTH];
	bool tn_is_ml;

	for (int i = force ? 3 : 2; i <= args; i++)
	{
		GetCmdArg(i, argbuf, sizeof(argbuf));
		targetCount = ProcessTargetString(
			argbuf,
			0,
			targets,
			MaxClients + 1,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml);

		for (int j = 0; j < targetCount; j++)
		{
			target = targets[j];
			if (IsClientInGame(target))
			{
				pendingSwaps[target] = team;
			}
		}
	}

	ApplySwaps(client, force);

	return Plugin_Handled;
}

stock void ApplySwaps(int sender, bool force)
{
	L4D2Team clientTeam;
	/* Swap everyone to spec first so we know the correct number of slots on the teams */
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			clientTeam = GetClientTeamEx(client);
			if (clientTeam != pendingSwaps[client] && pendingSwaps[client] != L4D2Team_None)
			{
				if (clientTeam == L4D2Team_Infected && GetZombieClass(client) != ZC_TANK)
					ForcePlayerSuicide(client);
				ChangeClientTeamEx(client, L4D2Team_Spectator, true);
			}
		}
	}

	/* Now lets try to put them on teams */
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && pendingSwaps[client] != L4D2Team_None)
		{
			if (!ChangeClientTeamEx(client, pendingSwaps[client], force))
			{
				if (sender > 0)
				{
					CPrintToChat(sender, "%t %t", "Tag", "CouldNotSwitched", client);
				}
			}
			pendingSwaps[client] = L4D2Team_None;
		}
	}

	/* Just in case MaxClients ever changes */
	for (int i = MaxClients + 1; i <= MAXPLAYERS; i++)
	{
		pendingSwaps[i] = L4D2Team_None;
	}
}

stock bool ChangeClientTeamEx(int client, L4D2Team team, bool force)
{
	if (GetClientTeamEx(client) == team)
		return true;

	else if (!force && GetTeamHumanCount(team) == GetTeamMaxHumans(team))
		return false;

	if (team != L4D2Team_Survivor)
	{
		ChangeClientTeam(client, view_as<int>(team));
		return true;
	}

	else
	{
		int bot = FindSurvivorBot();
		if (bot > 0)
		{
			int flags = GetCommandFlags("sb_takecontrol");
			SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "sb_takecontrol");
			SetCommandFlags("sb_takecontrol", flags);
			return true;
		}
	}
	return false;
}

stock int GetTeamHumanCount(L4D2Team team)
{
	int humans = 0;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeamEx(client) == team)
		{
			humans++;
		}
	}

	return humans;
}

stock int GetHumanCount()
{
	int humans = 0;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && !IsFakeClient(client))
		{
			humans++;
		}
	}

	return humans;
}

stock int GetTeamMaxHumans(L4D2Team team)
{
	if (team == L4D2Team_Survivor)
	{
		return GetConVarInt(survivor_limit);
	}
	else if (team == L4D2Team_Infected)
	{
		return GetConVarInt(z_max_player_zombies);
	}
	return MaxClients;
}

/* return -1 if no bot found, clientid otherwise */
stock int FindSurvivorBot()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsFakeClient(client) && GetClientTeamEx(client) == L4D2Team_Survivor)
		{
			return client;
		}
	}
	return -1;
}

stock bool IsPlayer(int client)
{
	L4D2Team team = GetClientTeamEx(client);
	return (team == L4D2Team_Survivor || team == L4D2Team_Infected);
}

stock int  GetZombieClass(int client) { return GetEntProp(client, Prop_Send, "m_zombieClass"); }

stock void FixBotCount()
{
	int survivor_count = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeamEx(client) == L4D2Team_Survivor)
		{
			survivor_count++;
		}
	}
	int limit = GetConVarInt(survivor_limit);
	if (survivor_count < limit)
	{
		int bot;
		for (; survivor_count < limit; survivor_count++)
		{
			bot = CreateFakeClient("k9Q6CK42");
			if (bot != 0)
			{
				ChangeClientTeam(bot, view_as<int>(L4D2Team_Survivor));
				RequestFrame(OnFrame_KickBot, GetClientUserId(bot));
			}
		}
	}
	else if (survivor_count > limit)
	{
		for (int client = 1; client <= MaxClients && survivor_count > limit; client++)
		{
			if (IsClientInGame(client) && GetClientTeamEx(client) == L4D2Team_Survivor)
			{
				if (IsFakeClient(client))
				{
					survivor_count--;
					KickClient(client);
				}
			}
		}
	}
}

public void OnFrame_KickBot(int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0) KickClient(client);
}

stock int GetPummelQueueAttacker(int client)
{
	return GetEntDataEnt2(client, m_queuedPummelAttacker);
}

stock L4D2Team GetClientTeamEx(int client)
{
	return view_as<L4D2Team>(GetClientTeam(client));
}

/**
 * Check if the translation file exists
 *
 * @param translation       translation file name
 */
stock void LoadTranslation(const char[] translation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file %s.txt", translation);
	}
	LoadTranslations(translation);
}