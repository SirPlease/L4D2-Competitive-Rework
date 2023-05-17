#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>

#define PLUGIN_VERSION "1.4"

float CONTROL_DELAY_SAFETY             = 0.3;
float CONTROL_RETRY_DELAY              = 2.0;
int TEAM_INFECTED                          = 3;

ConVar cvar_SurrenderTimeLimit               = null;
ConVar cvar_SurrenderChoiceType              = null;
ConVar cvar_SurrenderGhostKill				 = null;
Handle surrenderMenu                         = null;

bool withinTimeLimit                         = false;
int primaryTankPlayer                            = -1;
int tankAttemptsFailed                         = 0;
bool g_bIsTankAlive;

public Plugin myinfo = 
{
	name = "L4D Tank Swap",
	author = "AtomicStryker, HarryPotter, Bred",
	description = " Allows a primary Tank Player to surrender control to one of his teammates",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=326155"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	if (GetEngineVersion() != Engine_Left4Dead2) 
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_tankpass", CallSurrenderMenu, "Shows who is becoming the tank.");
	
	cvar_SurrenderTimeLimit = CreateConVar("l4d_tankswap_timelimit", "15", " How many seconds can a primary Tank Player surrender control ", FCVAR_NOTIFY);
	cvar_SurrenderChoiceType = CreateConVar("l4d_tankswap_choicetype", "2", " 0 - Disabled; 1 - Type !tankpass Button to call Menu; 2 - Menu appears for every Tank ", FCVAR_NOTIFY);
	cvar_SurrenderGhostKill = CreateConVar("l4d_tankswap_ghostkill", "1", " 0 - Disabled, old tank will become the infected(ghost) the new tank was; 1 - kill the ghost when surrender", FCVAR_NOTIFY);
	
	LoadTranslations("common.phrases");
	LoadTranslations("l4d2_tank_swap.phrases");
	
	HookEvent("tank_spawn", TC_ev_TankSpawn);
	HookEvent("round_start", TC_ev_RoundStart);
	HookEvent("entity_killed", TC_ev_EntityKilled);

	AutoExecConfig(true, "l4d2_tank_swap");
}

public Action TC_ev_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	g_bIsTankAlive = false;
	
	return Plugin_Handled;
}

public Action TC_ev_TankSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	if(g_bIsTankAlive) return Plugin_Continue;
	
	int tankclientid = event.GetInt("userid");
	int tankclient = GetClientOfUserId(event.GetInt("userid"));
	g_bIsTankAlive = true;
	float PlayerControlDelay = FindConVar("director_tank_lottery_selection_time").FloatValue;
	//PrintToChatAll("tankclientid %d",tankclientid);
	if(IsFakeClient(tankclient))
	{
		switch (cvar_SurrenderChoiceType.IntValue)
		{
			case 0:     return Plugin_Continue;
			case 1:     CreateTimer(PlayerControlDelay + CONTROL_DELAY_SAFETY, TS_DisplayNotificationToTank, 0);
			case 2:     CreateTimer(PlayerControlDelay + CONTROL_DELAY_SAFETY, TS_Display_Auto_MenuToTank, 0);
		}
	}
	else
	{
		switch (cvar_SurrenderChoiceType.IntValue)
		{
			case 0:     return Plugin_Continue;
			case 1:     CreateTimer(CONTROL_DELAY_SAFETY, TS_DisplayNotificationToTank, tankclientid);
			case 2:     CreateTimer(CONTROL_DELAY_SAFETY, TS_Display_Auto_MenuToTank, tankclientid);
		}
	}
	return Plugin_Continue;
}

public Action TS_DisplayNotificationToTank(Handle timer, int clientid)
{
	primaryTankPlayer = GetClientOfUserId(clientid);
	if(primaryTankPlayer == 0 || !IsClientInGame(primaryTankPlayer))
		primaryTankPlayer = FindHumanTankPlayer();

	if (!primaryTankPlayer)
	{
		tankAttemptsFailed++;
		if (tankAttemptsFailed < 5)
		{
			CreateTimer(CONTROL_RETRY_DELAY, TS_DisplayNotificationToTank);
		}
		return Plugin_Stop;
	}
	
	withinTimeLimit = true;
	float SurrenderTimeLimit = cvar_SurrenderTimeLimit.FloatValue;
	CreateTimer(SurrenderTimeLimit, TS_TimeLimitIsOver);
	CPrintToChat(primaryTankPlayer, "%t", "Menu_Notice", RoundFloat(SurrenderTimeLimit));
	return Plugin_Stop;
}

public Action TS_TimeLimitIsOver(Handle timer)
{
	withinTimeLimit = false;
	if (surrenderMenu != null)
	{
		surrenderMenu = null;
	}
	
	return Plugin_Stop;
}

static int FindHumanTankPlayer()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) != TEAM_INFECTED) continue;
		if (!IsPlayerTank(i)) continue;
		if (GetClientHealth(i) < 1 || !IsPlayerAlive(i)) continue;
		
		return i;
	}
	
	return 0;
}

bool IsPlayerTank (int client)
{
	return (GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

public Action CallSurrenderMenu(int client, int args)
{
	if (!IsPlayerTank || cvar_SurrenderChoiceType.IntValue != 1)
		return Plugin_Handled;
	if (!withinTimeLimit)
	{
		CPrintToChat(client, "%t", "Time_Over");
		return Plugin_Handled;
	}
	
	surrenderMenu = CreateMenu(TS_MenuCallBack);
	
	char buffer[256];
	Format(buffer, sizeof(buffer), "%T", "Menu_Title", client);
	SetMenuTitle(surrenderMenu, buffer);
	
	char name[MAX_NAME_LENGTH], number[10];
	int electables;
	
	Format(buffer, sizeof(buffer), "%T", "Anyone_But_Me", client);
	AddMenuItem(surrenderMenu, "0", buffer);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == primaryTankPlayer) continue;
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) != TEAM_INFECTED) continue;
		if (IsFakeClient(i)) continue;
		
		
		Format(name, sizeof(name), "%N", i);
		Format(number, sizeof(number), "%i", i);
		AddMenuItem(surrenderMenu, number, name);
		
		electables++;
	}

	
	if (electables > 0) //only do all that if there is someone to swap to
	{
		SetMenuExitButton(surrenderMenu, false);
		//FakeClientCommand(primaryTankPlayer, "sm_tankhud");
		DisplayMenu(surrenderMenu, primaryTankPlayer, cvar_SurrenderTimeLimit.IntValue);
	}
	
	return Plugin_Continue;
}

public int TS_MenuCallBack(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End) CloseHandle(menu);

	if (action != MenuAction_Select) return 0; // only allow a valid choice to pass
	
	char number[4];
	GetMenuItem(menu, param2, number, sizeof(number));
	
	int choice = StringToInt(number);
	if (!choice)
	{
		choice = GetRandomEligibleTank();
		if (GetClientHealth(choice) > 1 && !IsPlayerGhost(choice))
		{
			L4D_ReplaceWithBot(choice);
		}
		if (cvar_SurrenderGhostKill.IntValue && IsPlayerGhost(choice))
			ForcePlayerSuicide(choice);
		L4D_ReplaceTank(primaryTankPlayer, choice);
		
		if (!cvar_SurrenderGhostKill.IntValue && IsPlayerGhost(choice))
			L4D2_SetPlayerZombieClass(primaryTankPlayer, L4D2_GetPlayerZombieClass(choice));
		//FakeClientCommand(primaryTankPlayer, "sm_tankhud");
		CPrintToChatAll("%T", "Random_Surrend", choice);
	}
	else
	{
		if (GetClientHealth(choice) > 1 && !IsPlayerGhost(choice))
		{
			L4D_ReplaceWithBot(choice);
		}
		if (cvar_SurrenderGhostKill.IntValue && IsPlayerGhost(choice))
			ForcePlayerSuicide(choice);
		L4D_ReplaceTank(primaryTankPlayer, choice);
		
		if (!cvar_SurrenderGhostKill.IntValue && IsPlayerGhost(choice))
			L4D2_SetPlayerZombieClass(primaryTankPlayer, L4D2_GetPlayerZombieClass(choice));
		CPrintToChatAll("%T", "Surrend", choice);
	}
	
	return 0;
}

public Action TS_Display_Auto_MenuToTank(Handle timer, int clientid)
{
	//PrintToChatAll("TS_Display_Auto_MenuToTank %d",clientid);
	primaryTankPlayer = GetClientOfUserId(clientid);
	if(primaryTankPlayer == 0 || !IsClientInGame(primaryTankPlayer))
		primaryTankPlayer = FindHumanTankPlayer();

	if (!primaryTankPlayer)
	{
		if (HasTeamHumanPlayers(3))
		{
			CreateTimer(CONTROL_RETRY_DELAY, TS_Display_Auto_MenuToTank);
			return Plugin_Stop;
		}
		else
		{
			return Plugin_Stop;
		}
	}

	surrenderMenu = CreateMenu(TS_Auto_MenuCallBack);
	char buffer[256];
	Format(buffer, sizeof(buffer), "%T", "Menu_Title", primaryTankPlayer);
	SetMenuTitle(surrenderMenu, buffer);
	
	char name[MAX_NAME_LENGTH], number[10];
	int electables;
	
	Format(buffer, sizeof(buffer), "%T", "Stay_Me", primaryTankPlayer);
	AddMenuItem(surrenderMenu, "0", buffer);
	Format(buffer, sizeof(buffer), "%T", "Anyone_But_Me", primaryTankPlayer);
	AddMenuItem(surrenderMenu, "99", buffer);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (IsFakeClient(i)) continue;
		if (GetClientTeam(i) != TEAM_INFECTED) continue;
		if (i == primaryTankPlayer || IsPlayerTank(i)) continue;

		Format(name, sizeof(name), "%N", i);
		Format(number, sizeof(number), "%i", i);
		AddMenuItem(surrenderMenu, number, name);
		
		electables++;
	}
	
	if (electables > 0) //only do all that if there is someone to swap to
	{
		SetMenuExitButton(surrenderMenu, false);
		//FakeClientCommand(primaryTankPlayer, "sm_tankhud");
		DisplayMenu(surrenderMenu, primaryTankPlayer, 2 * cvar_SurrenderTimeLimit.IntValue);
	}
	
	return Plugin_Stop;
}

bool HasTeamHumanPlayers(int team)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)
		&& GetClientTeam(i) == team
		&& !IsFakeClient(i))
		{
			return true;
		}
	}
	return false;
}

public int TS_Auto_MenuCallBack(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End) 
	{
		//FakeClientCommand(primaryTankPlayer, "sm_tankhud");
		CloseHandle(menu);
	} 
	
	if (action != MenuAction_Select) 
	{
		//FakeClientCommand(primaryTankPlayer, "sm_tankhud");
		return 0; // only allow a valid choice to pass
	}
	
	char number[4];
	GetMenuItem(menu, param2, number, sizeof(number));

	int choice = StringToInt(number);
	if (!choice) 
	{
		//FakeClientCommand(primaryTankPlayer, "sm_tankhud");
		//PrintToChatAll("\x04[Tank Swap]\x01 \x03%N\x01: I want to stay Tank\x01", primaryTankPlayer);
		return 0; // "I want to stay Tank"
	}
	else if (choice == 99)  // "Anyone but me"
	{
		choice = GetRandomEligibleTank();
		if (GetClientHealth(choice) > 1 && !IsPlayerGhost(choice))
		{
			L4D_ReplaceWithBot(choice);
		}
		if (IsPlayerGhost(choice))
		{
			ForcePlayerSuicide(choice);
		}
		L4D_ReplaceTank(primaryTankPlayer, choice);
		
		//FakeClientCommand(primaryTankPlayer, "sm_tankhud");
		CPrintToChatAll("%t", "Random_Surrend", choice);
	}
	else    // choice is a specific player id
	{
		if (GetClientHealth(choice) > 1 && !IsPlayerGhost(choice))
		{
			L4D_ReplaceWithBot(choice);
		}
		if (IsPlayerGhost(choice))
		{
			ForcePlayerSuicide(choice);
		}
		L4D_ReplaceTank(primaryTankPlayer, choice);
		
		//FakeClientCommand(primaryTankPlayer, "sm_tankhud");
		CPrintToChatAll("%t", "Surrend", choice);
	}
	
	return 0;
}

bool IsPlayerGhost (int client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost"))
		return true;
	return false;
}

static int GetRandomEligibleTank()
{
	int electables;
	int[] pool = new int[MaxClients/2];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == primaryTankPlayer) continue;
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) != TEAM_INFECTED) continue;
		if (IsFakeClient(i)) continue;
		
		electables++;
		pool[electables] = i;
	}
	
	return pool[ GetRandomInt(1, electables) ];
}

public Action TC_ev_EntityKilled(Event event, const char[] name, bool dontBroadcast) 
{
	int client;
	if (g_bIsTankAlive && IsPlayerTank((client = GetEventInt(event, "entindex_killed"))))
	{
		CreateTimer(1.5, FindAnyTank, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Handled;
}

public Action FindAnyTank(Handle timer, int client)
{
	if(!IsTankInGame()){
		g_bIsTankAlive = false;
		tankAttemptsFailed = 0;
	}
	
	return Plugin_Handled;
}

int IsTankInGame(int exclude = 0)
{
	for (int i = 1; i <= MaxClients; i++)
		if (exclude != i && IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerTank(i) && IsInfectedAlive(i) && !IsIncapacitated(i))
			return i;

	return 0;
}

stock bool IsIncapacitated(int client)
{
	if(GetEntProp(client, Prop_Send, "m_isIncapacitated"))
		return true;
	return false;
}

stock bool IsInfectedAlive(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth") > 1;
}