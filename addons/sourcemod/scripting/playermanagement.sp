#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>

#define ZC_TANK 8

#define GAMEDATA "l4d2_si_ability"

public Plugin myinfo =
{
	name = "Player Management Plugin",
	author = "CanadaRox",
	description = "Player management!  Swap players/teams and spectate!",
	version = "7",
	url = ""
};

enum L4D2Team
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected
}

new const L4D2Team:oppositeTeamMap[] =
{
	L4D2Team_None,
	L4D2Team_Spectator,
	L4D2Team_Infected,
	L4D2Team_Survivor
};

public const char L4D2_AttackerNetProps[][] =
{
	"m_tongueOwner",	// Smoker
	"m_pounceAttacker",	// Hunter
	"m_jockeyAttacker",	// Jockey
	"m_carryAttacker",  // Charger carry
	"m_pummelAttacker",	// Charger pummel
};

Handle survivor_limit;
Handle z_max_player_zombies;

new L4D2Team:pendingSwaps[MAXPLAYERS+1];
bool blockVotes[MAXPLAYERS+1];
bool isMapActive;
Handle SpecTimer[MAXPLAYERS+1];

int TimerLive;
int m_queuedPummelAttacker = -1;

Handle l4d_pm_supress_spectate;

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_swap", Swap_Cmd, ADMFLAG_KICK, "sm_swap <player1> [player2] ... [playerN] - swap all listed players to opposite teams");
	RegAdminCmd("sm_swapto", SwapTo_Cmd, ADMFLAG_KICK, "sm_swapto [force] <teamnum> <player1> [player2] ... [playerN] - swap all listed players to <teamnum> (1,2, or 3)");
	RegAdminCmd("sm_swapteams", SwapTeams_Cmd, ADMFLAG_KICK, "sm_swapteams - swap the players between both teams");
	RegAdminCmd("sm_fixbots", FixBots_Cmd, ADMFLAG_BAN, "sm_fixbots - Spawns survivor bots to match survivor_limit");
	RegConsoleCmd("sm_spectate", Spectate_Cmd, "Moves you to the spectator team");
	RegConsoleCmd("sm_spec", Spectate_Cmd, "Moves you to the spectator team");
	RegConsoleCmd("sm_s", Spectate_Cmd, "Moves you to the spectator team");

	AddCommandListener(Vote_Listener, "vote");
	AddCommandListener(Vote_Listener, "callvote");
	AddCommandListener(TeamChange_Listener, "jointeam");

	survivor_limit = FindConVar("survivor_limit");
	HookConVarChange(survivor_limit, survivor_limitChanged);

	z_max_player_zombies = FindConVar("z_max_player_zombies");

	l4d_pm_supress_spectate = CreateConVar("l4d_pm_supress_spectate", "0", "Don't print messages when players spectate");
	
	
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);

	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}
	
	m_queuedPummelAttacker = GameConfGetOffset(hGamedata, "CTerrorPlayer->m_queuedPummelAttacker");
	if (m_queuedPummelAttacker == -1) {
		SetFailState("Failed to get offset 'CTerrorPlayer->m_queuedPummelAttacker'.");
	}
	
	delete hGamedata;
}

public void OnMapStart()
{
	isMapActive = true;
}

public void OnMapEnd()
{
	isMapActive = false;
}

public void OnRoundIsLive()
{
	TimerLive = 0;
}

public void OnTimerStart()
{
	if (TimerLive == 0) TimerLive = 1;
	else TimerLive = 0;
}

public Action FixBots_Cmd(int client, int args)
{
	if (client != 0)
	{
		PrintToChatAll("[SM] %N is attempting to fix bot counts", client);
	}
	else
	{
		PrintToChatAll("[SM] Console is attempting to fix bot counts");
	}
	FixBotCount();
	return Plugin_Handled;
}

void survivor_limitChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	FixBotCount();
}

public void OnClientAuthorized(int client, const char[] auth)
{
	char name[MAX_NAME_LENGTH];
	if (IsFakeClient(client) && GetClientName(client, name, sizeof(name)) && StrContains(name, "k9Q6CK42") > -1)
	{
		KickClient(client);
	}
}

public void OnClientDisconnect_Post(int client)
{
	if (isMapActive && GetHumanCount()) FixBotCount();
}

public Action Spectate_Cmd(int client, int args)
{
	new L4D2Team:team = GetClientTeamEx(client);

	if (team == L4D2Team_Survivor)
	{
		if ((IsSurvivorAttacked(client) && !IsSurvivorAndIncapacitated(client)) || GetPummelQueueAttacker(client) != -1)
		{
			CPrintToChat(client, "No spectating while capped!");
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
		if (TimerLive == 0)
		{
			blockVotes[client] = true;
			ChangeClientTeamEx(client, L4D2Team_Infected, true);
			CreateTimer(0.1, RespecDelay_Timer, client);
		}
	}
	
	if (!GetConVarBool(l4d_pm_supress_spectate) && team != L4D2Team_Spectator && SpecTimer[client] == INVALID_HANDLE)
	{
		CPrintToChatAllEx(client, "{teamcolor}%N{default} has become a spectator!", client);
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

public Action Vote_Listener(int client, const char[] command, int argc)
{
	return blockVotes[client] ? Plugin_Handled : Plugin_Continue;
}

public Action TeamChange_Listener(int client, const char[] command, int argc)
{
	// Invalid 
	if(!IsClientInGame(client) || argc < 1) 
		return Plugin_Handled;

	// Not a jockey with a victim, don't care
	if (GetClientTeam(client) != _:L4D2Team_Infected
	|| GetZombieClass(client) != 5
	|| GetEntProp(client, Prop_Send, "m_jockeyVictim") < 1)
		return Plugin_Continue;
 
 	// Block Jockey from switching team.
	return Plugin_Handled;
}

public Action SwapTeams_Cmd(int client, int args)
{
	for (int cli = 1; cli <= MaxClients; cli++)
	{
		if(IsClientInGame(cli) && !IsFakeClient(cli) && IsPlayer(cli))
		{
			pendingSwaps[cli] = oppositeTeamMap[GetClientTeamEx(cli)];
		}
	}
	ApplySwaps(client, false);
	return Plugin_Handled;
}

bool IsGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost", 1));
}

public Action Swap_Cmd(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_swap <player1> <player2> ... <playerN>");
		return Plugin_Handled;
	}

	char argbuf[MAX_NAME_LENGTH];

	new targets[MaxClients+1];
	int target;
	int targetCount;
	char target_name[MAX_TARGET_LENGTH];
	bool tn_is_ml;

	for (int i = 1; i <= args; i++)
	{
		GetCmdArg(i, argbuf, sizeof(argbuf));
		targetCount = ProcessTargetString(
				argbuf,
				0,
				targets,
				MaxClients+1,
				COMMAND_FILTER_NO_BOTS,
				target_name,
				sizeof(target_name),
				tn_is_ml);
		
		for (int j = 0; j < targetCount; j++)
		{
			target = targets[j];
			if(IsClientInGame(target))
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
		ReplyToCommand(client, "[SM] Usage: sm_swapto <teamnum> <player1> <player2> ... <playerN>\n%d = Spectators, %d = Survivors, %d = Infected", L4D2Team_Spectator, L4D2Team_Survivor, L4D2Team_Infected);
		ReplyToCommand(client, "[SM] Usage: sm_swapto force <teamnum> <player1> <player2> ... <playerN>\n%d = Spectators, %d = Survivors, %d = Infected", L4D2Team_Spectator, L4D2Team_Survivor, L4D2Team_Infected);
		return Plugin_Handled;
	}

	char argbuf[MAX_NAME_LENGTH];
	bool force;

	GetCmdArg(1, argbuf, sizeof(argbuf));
	if (StrEqual(argbuf, "force"))
	{
		force = true;
		GetCmdArg(2, argbuf, sizeof(argbuf));
	}

	new L4D2Team:team = L4D2Team:StringToInt(argbuf);
	if (team < L4D2Team_Spectator || team > L4D2Team_Infected)
	{
		ReplyToCommand(client, "[SM] Valid teams: %d = Spectators, %d = Survivors, %d = Infected", L4D2Team_Spectator, L4D2Team_Survivor, L4D2Team_Infected);
		return Plugin_Handled;
	}

	new targets[MaxClients+1];
	int target;
	int targetCount;
	char target_name[MAX_TARGET_LENGTH];
	bool tn_is_ml;

	for (int i = force?3:2; i <= args; i++)
	{
		GetCmdArg(i, argbuf, sizeof(argbuf));
		targetCount = ProcessTargetString(
				argbuf,
				0,
				targets,
				MaxClients+1,
				COMMAND_FILTER_NO_BOTS,
				target_name,
				sizeof(target_name),
				tn_is_ml);
		
		for (int j = 0; j < targetCount; j++)
		{
			target = targets[j];
			if(IsClientInGame(target))
			{
				pendingSwaps[target] = team;
			}
		}
	}

	ApplySwaps(client, force);

	return Plugin_Handled;
}

stock ApplySwaps(int sender, bool force)
{
	new L4D2Team:clientTeam;
	/* Swap everyone to spec first so we know the correct number of slots on the teams */
	for (int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
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
		if(IsClientInGame(client) && pendingSwaps[client] != L4D2Team_None)
		{
			if (!ChangeClientTeamEx(client, pendingSwaps[client], force))
			{
				if (sender > 0)
				{
					PrintToChat(sender, "%N could not be switched because the target team was full or has no bot to take over.", client);
				}
			}
			pendingSwaps[client] = L4D2Team_None;

		}
	}

	/* Just in case MaxClients ever changes */
	for (int i = MaxClients+1; i <= MAXPLAYERS; i++)
	{
		pendingSwaps[i] = L4D2Team_None;
	}
}

stock bool ChangeClientTeamEx(int client, L4D2Team:team, bool force)
{
	if (GetClientTeamEx(client) == team)
		return true;

	else if (!force && GetTeamHumanCount(team) == GetTeamMaxHumans(team))
		return false;

	if (team != L4D2Team_Survivor)
	{
		ChangeClientTeam(client, _:team);
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

stock GetTeamHumanCount(L4D2Team:team)
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

stock GetHumanCount()
{
	new humans = 0;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			humans++;
		}
	}
	
	return humans;
}

stock GetTeamMaxHumans(L4D2Team:team)
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
stock FindSurvivorBot()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsFakeClient(client) && GetClientTeamEx(client) == L4D2Team_Survivor)
		{
			return client;
		}
	}
	return -1;
}

stock IsPlayer(client)
{
	new L4D2Team:team = GetClientTeamEx(client);
	return (team == L4D2Team_Survivor || team == L4D2Team_Infected);
}

stock GetZombieClass(int client) return GetEntProp(client, Prop_Send, "m_zombieClass");

stock FixBotCount()
{
	int survivor_count = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeamEx(client) == L4D2Team_Survivor)
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
				ChangeClientTeam(bot, _:L4D2Team_Survivor);
			}
		}
	}
	else if (survivor_count > limit)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && GetClientTeamEx(client) == L4D2Team_Survivor)
			{
				if (IsFakeClient(client))
				{
					KickClient(client);
				}
			}
		}
	}
}

stock L4D2Team:GetClientTeamEx(int client)
{
	return L4D2Team:GetClientTeam(client);
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsSurvivor(int client)
{
	return (IsValidClient(client) && L4D2Team:GetClientTeam(client) == L4D2Team_Survivor);
}

stock bool IsSurvivorAndIncapacitated(int client)
{
	if (IsSurvivor(client)) {
		if (GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0) {
			return true;
		}

		if (!IsPlayerAlive(client)) {
			return true;
		}
	}

	return false;
}

stock bool IsSurvivorAttacked(int client)
{
	if (IsSurvivor(client)) {
		for (int i = 0; i < sizeof(L4D2_AttackerNetProps); i++) {
			if (GetEntPropEnt(client, Prop_Send, L4D2_AttackerNetProps[i]) != -1) {
				return true;
			}
		}
	}

	return false;
}

stock int GetPummelQueueAttacker(int client)
{
	return GetEntDataEnt2(client, m_queuedPummelAttacker);
}
