/*===========================================================================================================

	General Updates:

 *	26-02-2023 > Version 2.2: Added new cvar to prevent some commands from interfering with readup panel, and fix panel not closing after readyup time is over.
 *	25-02-2023 > Version 2.1: Remove repeated timer to display menu, added color support and fixes a bug where sometimes survivors doesn't get full hp when teleported.
 *	27-01-2023 > Version 2.0: Fixed a bug, doors close when players are connecting and survivros already left safe area - Thanks to official instruction.
 *	22-01-2023 > Version 1.9: Adding a warning cvar when players leave safe area while players are not ready - Thanks to official instruction.
 *	19-01-2023 > Version 1.8: Adding a different method to ready up in first chapters using teleport
 *	18-01-2023 > Version 1.7: Adding translation.
 *	15-01-2023 > Version 1.6: Some improvements, changing method to detect gamemode, and adding a new cvar.
 *	04-01-2023 > Version 1.5: Adding a mechanism to unlock safe area if admin got disconnected while controlling door lock.
 *	03-01-2023 > Version 1.4: General enhancements and bug fixed.
 *	31-12-2022 > Version 1.3: Connect and disconnect bug fixed - Thanks to Official Instruction.
 *	31-12-2022 > Version 1.2: Both teams need to be ready to start the round
 *	27-12-2022 > Version 1.1: General fixes and enhancements - Thanks to Silvers
 *	26-12-2022 > Version 1.0: Initial release

 *================================================================================================================ *
 *												Includes, Pragmas and Define			   						   *
 *================================================================================================================ */

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>
#include <colors>

#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "2.2"

/* =============================================================================================================== *
 *										Bools, Handles, Integers and ConVars				   			 		   *
 *================================================================================================================ */

bool g_bGameLeft4Dead;
bool g_bFirstScenario;
bool g_bAdminTakeover;
bool g_bSurvivorReady;
bool g_bInfectedReady;
bool g_bLockSafeAreas;
bool g_bIgnoreLoaders;
bool g_bLeftSafeAreas;
bool g_bClientIsReady [MAXPLAYERS+1];
bool g_bPanelIsOpened [MAXPLAYERS+1];

Handle g_hTimer_IgnoreLoaders;
Handle g_hTimer_PendingLoader;
Handle g_hTimer_WarmingUpTime;
Handle g_hTimer_CountdownTime;
Handle g_hTimer_UnreadyGiveUp;
Handle g_hTimer_ReadyUpChecks;
Handle g_hTimer_ForceVersusST;

int g_iUnlocksTime;
int g_iLoadersTime;
int g_iGiveUpsTime;
int g_iCurrentMaps;
int g_iUnrdyCounts [MAXPLAYERS+1];
int g_iClientDelay [MAXPLAYERS+1];

enum
{
	C1M1 = 1,
	C2M1,
	C3M1,
	C4M1,
	C5M1,
	C6M1,
	C7M1,
	C8M1,
	C9M1,
	C10M1,
	C11M1,
	C12M1,
	C13M1,
	C14M1
}

ConVar Cvar_DoorLock_AllowLock;
ConVar Cvar_DoorLock_GameModes;
ConVar Cvar_DoorLock_ModesType;
ConVar Cvar_DoorLock_AddCheats;
ConVar Cvar_DoorLock_Countdown;
ConVar Cvar_DoorLock_LoaderMax;
ConVar Cvar_DoorLock_AllowGlow;
ConVar Cvar_DoorLock_GlowRange;
ConVar Cvar_DoorLock_LockColor;
ConVar Cvar_DoorLock_OpenColor;
ConVar Cvar_DoorLock_EnableRdy;
ConVar Cvar_DoorLock_RdyTimeUp;
ConVar Cvar_DoorLock_RdyPercnt;
ConVar Cvar_DoorLock_UnrdyTime;
ConVar Cvar_DoorLock_Announces;
ConVar Cvar_DoorLock_LeaverMsg;
ConVar Cvar_DoorLock_EnableCmd;

ConVar Cvar_DoorLock_MPGameMod;
ConVar Cvar_DoorLock_NoBotMove;
ConVar Cvar_DoorLock_MaxesAmmo;
ConVar Cvar_DoorLock_ExitTimer;

/* =============================================================================================================== *
 *															Plugin Info				   							   *
 *================================================================================================================ */

public Plugin myinfo =
{
	name = "L4D2 Saferoom Locker",
	author = "alasfourom",
	description = "Lock Saferoom Door Until All Players Are Ready",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=341045"
};

/* =============================================================================================================== *
 *															L4D2 Engine				   							   *
 *================================================================================================================ */

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead2) g_bGameLeft4Dead = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead: 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

/* =============================================================================================================== *
 *													  Plugin Start			   									   *
 *================================================================================================================ */

public void OnPluginStart()
{
	CreateConVar ("l4d2_door_lock_version", PLUGIN_VERSION, "L4D2 Door Lock", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	Cvar_DoorLock_AllowLock = CreateConVar("l4d2_doorlock_plugin_enable", "1", "如果为1，启用插件", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_DoorLock_GameModes = CreateConVar("l4d2_doorlock_game_mode", "versus,coop", "在这些模式中启用插件，用英文逗号隔开 (无空格, 无内容 = 全模式).", FCVAR_NOTIFY);
	Cvar_DoorLock_ModesType = CreateConVar("l4d2_doorlock_first_scenario_mode", "1", "地图第一关模式 (0 = 冻结生还者, 1 = 出安全区传送 Survivors)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_DoorLock_AddCheats = CreateConVar("l4d2_doorlock_add_cheats", "1", "安全区准备锁定模式 (0 = 无特殊锁定, 1 = 禁友伤, 2 = 无限弹药, 3 = 1和2)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	Cvar_DoorLock_Countdown = CreateConVar("l4d2_doorlock_countdown", "5", "你想设置多长时间的倒计时来解锁安全区？ (秒)", FCVAR_NOTIFY);
	Cvar_DoorLock_LoaderMax = CreateConVar("l4d2_doorlock_loaders_time", "40", "最多等待加载玩家多长时间 (秒)", FCVAR_NOTIFY);
	Cvar_DoorLock_AllowGlow = CreateConVar("l4d2_doorlock_glow_enable", "1", "如果为1，为安全室的门设置发光轮毂", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_DoorLock_GlowRange = CreateConVar("l4d2_doorlock_glow_range", "500", "设置安全门的发光范围", FCVAR_NOTIFY);
	Cvar_DoorLock_LockColor = CreateConVar("l4d2_doorlock_lock_glow_color",	"255 0 0", "设置安全门的发光颜色, (0-255RGB) 用空格隔开.", FCVAR_NOTIFY);
	Cvar_DoorLock_OpenColor = CreateConVar("l4d2_doorlock_unlock_glow_color", "0 255 0", "设置解锁安全门的发光颜色, (0-255) Separated By Spaces.", FCVAR_NOTIFY);
	Cvar_DoorLock_EnableRdy = CreateConVar("l4d2_doorlock_enable_ready_mode", "0", "如果为1，启用准备功能.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_DoorLock_UnrdyTime = CreateConVar("l4d2_doorlock_unready_counts", "2", "设置每轮允许玩家使用未准备的次数.", FCVAR_NOTIFY);
	Cvar_DoorLock_RdyTimeUp = CreateConVar("l4d2_doorlock_readyup_time", "120", "插件对未准备好的团队等待多长时间才会强制开始 (秒)", FCVAR_NOTIFY);
	Cvar_DoorLock_RdyPercnt = CreateConVar("l4d2_doorlock_readyup_percent", "75.0", "一方设置准备好开始游戏所需的最低百分比", FCVAR_NOTIFY);
	Cvar_DoorLock_Announces = CreateConVar("l4d2_doorlock_readyup_notify", "1", "团队准备就绪时显示聊天文本", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	Cvar_DoorLock_LeaverMsg = CreateConVar("l4d2_doorlock_leavers_notify", "2", "在被传送时向离开者显示聊天文本（0=禁用，1=聊天，2=中心文本）", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_DoorLock_EnableCmd = CreateConVar("l4d2_doorlock_add_commands", "!map,!buy,!shop", "添加你想要的命令以防止干扰ReadyUp面板 (无空格)", FCVAR_NOTIFY);
	//AutoExecConfig(true, "l4d2_door_lock");
	
	Cvar_DoorLock_MPGameMod = FindConVar("mp_gamemode");
	Cvar_DoorLock_NoBotMove = FindConVar("nb_player_stop");
	Cvar_DoorLock_MaxesAmmo = FindConVar("sv_infinite_ammo");
	Cvar_DoorLock_ExitTimer = FindConVar("versus_force_start_time");
	
	RegAdminCmd("sm_lock", Command_Lock, ADMFLAG_GENERIC, "Force Saferoom To Be Locked");
	RegAdminCmd("sm_unlock", Command_Unlock, ADMFLAG_GENERIC, "Force Saferoom To Be Unlocked");
	RegConsoleCmd("sm_ready", Command_Ready, "Set Player's Status To Ready");
	RegConsoleCmd("sm_unready", Command_Unready, "Set Player's Status To Unready");
	
	HookEvent("round_freeze_end", Event_RoundFreezeEnd, EventHookMode_Post);
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_ledge_grab", Event_PlayerIncapacitated, EventHookMode_Pre);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated, EventHookMode_Post);
	LoadTranslations("l4d2_door_lock.phrases");
}

public Action OnClientSayCommand(int client, const char[] command, const char[] message)
{
	if (strcmp(command, "say_team", false) == 0 || strcmp(command, "say", false) == 0)
	{
		char sCvarCommand[512];
		Cvar_DoorLock_EnableCmd.GetString(sCvarCommand, sizeof(sCvarCommand));
		if(StrContains(sCvarCommand, message) != -1)
		{
			g_bPanelIsOpened[client] = false;
			FakeClientCommand(client, message);
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

/* =============================================================================================================== *
 *													  Map Start			   										   *
 *================================================================================================================ */

public void OnMapStart()
{
	g_bFirstScenario = false;
	g_iCurrentMaps = 0;
	
	char sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));
	
	if(strcmp(sMap, "c1m1_hotel") == 0) g_iCurrentMaps = C1M1;
	else if(strcmp(sMap, "c2m1_highway") == 0) g_iCurrentMaps = C2M1;
	else if(strcmp(sMap, "c3m1_plankcountry") == 0) g_iCurrentMaps = C3M1;
	else if(strcmp(sMap, "c4m1_milltown_a") == 0) g_iCurrentMaps = C4M1;
	else if(strcmp(sMap, "c5m1_waterfront") == 0) g_iCurrentMaps = C5M1;
	else if(strcmp(sMap, "c6m1_riverbank") == 0) g_iCurrentMaps = C6M1;
	else if(strcmp(sMap, "c7m1_docks") == 0) g_iCurrentMaps = C7M1;
	else if(strcmp(sMap, "c8m1_apartment") == 0) g_iCurrentMaps = C8M1;
	else if(strcmp(sMap, "c9m1_alleys") == 0) g_iCurrentMaps = C9M1;
	else if(strcmp(sMap, "c10m1_caves") == 0) g_iCurrentMaps = C10M1;
	else if(strcmp(sMap, "c11m1_greenhouse") == 0) g_iCurrentMaps = C11M1;
	else if(strcmp(sMap, "c12m1_hilltop") == 0) g_iCurrentMaps = C12M1;
	else if(strcmp(sMap, "c13m1_alpinecreek") == 0) g_iCurrentMaps = C13M1;
	else if(strcmp(sMap, "c14m1_junkyard") == 0) g_iCurrentMaps = C14M1;
	
	if (L4D_IsFirstMapInScenario()) g_bFirstScenario = true;
	Cvar_DoorLock_ExitTimer.SetString("999999");
}

/* =============================================================================================================== *
 *													L4D2_DoorLock_Enable										   *
 *================================================================================================================ */

bool L4D2_DoorLock_Enable()
{
	if(!g_bGameLeft4Dead || !Cvar_DoorLock_AllowLock.BoolValue || !IsAllowedGameMode()) return false;
	return true;
}

/* =============================================================================================================== *
 *													IsAllowedGameMode											   *
 *================================================================================================================ */

bool IsAllowedGameMode()
{
	char sGameMode[64];
	char sGameInfo[64];
	
	Cvar_DoorLock_MPGameMod.GetString(sGameMode, sizeof(sGameMode));
	Cvar_DoorLock_GameModes.GetString(sGameInfo, sizeof(sGameInfo));
	
	if(StrContains(sGameInfo, sGameMode) != -1) return true;
	return false;
}

/* =============================================================================================================== *
 *															On Round Start										   *
 *================================================================================================================ */

void Event_RoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(!L4D2_DoorLock_Enable()) return;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		g_bClientIsReady[i] = false;
		g_bPanelIsOpened[i] = false;
		g_iUnrdyCounts[i] = Cvar_DoorLock_UnrdyTime.IntValue;
	}
	
	g_bAdminTakeover = false;
	g_bSurvivorReady = false;
	g_bInfectedReady = false;
	g_bLockSafeAreas = false;
	g_bIgnoreLoaders = false;
	g_bLeftSafeAreas = false;
	
	g_iLoadersTime = Cvar_DoorLock_LoaderMax.IntValue;
	g_iGiveUpsTime = Cvar_DoorLock_RdyTimeUp.IntValue;
	g_iUnlocksTime = Cvar_DoorLock_Countdown.IntValue;
	
	FreezePlayersInFirstChapters();
	LockAllRotatingSaferoomDoors();
	TriggerSafeAreaLocksFeatures();
	
	g_hTimer_IgnoreLoaders = CreateTimer(1.0, Timer_DisregardLoaders, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	g_hTimer_PendingLoader = CreateTimer(1.0, Timer_PendingLoaders, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	g_hTimer_ForceVersusST = CreateTimer(1.0, Timer_ForceRoundToStart, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

/* =============================================================================================================== *
 *												Checking Some Other Events										   *
 *================================================================================================================ */

void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(!L4D2_DoorLock_Enable()) return;
	
	delete g_hTimer_IgnoreLoaders;
	if(g_hTimer_PendingLoader != null) delete g_hTimer_PendingLoader;
	if(g_hTimer_WarmingUpTime != null) delete g_hTimer_WarmingUpTime;
	if(g_hTimer_UnreadyGiveUp != null) delete g_hTimer_UnreadyGiveUp;
	if(g_hTimer_CountdownTime != null) delete g_hTimer_CountdownTime;
	if(g_hTimer_ReadyUpChecks != null) delete g_hTimer_ReadyUpChecks;
	if(g_hTimer_ForceVersusST != null) delete g_hTimer_ForceVersusST;
}

/* =============================================================================================================== *
 *									First Chapters: Freezing Players When They Move								   *
 *================================================================================================================ */

public Action OnPlayerRunCmd (int client, int &buttons)
{
	if(!Cvar_DoorLock_ModesType.BoolValue && !g_bLeftSafeAreas && g_bLockSafeAreas)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == 2 && L4D2_DoorLock_Enable())
			if(IsValidEntity(client) && g_bFirstScenario) SetEntityMoveType(client, MOVETYPE_NONE);
	}
	return Plugin_Continue;
}

/* =============================================================================================================== *
 *													Timers: Waiting For Loaders									   *
 *================================================================================================================ */

Action Timer_DisregardLoaders(Handle timer)
{
	int Human = GetRealPlayers();
	
	if(Human < 1) return Plugin_Continue;
	else if(g_iLoadersTime > 0)
	{
		g_iLoadersTime -= 1;
		return Plugin_Continue;
	}
	
	g_hTimer_IgnoreLoaders = null;
	g_bIgnoreLoaders = true;
	return Plugin_Stop;
}

Action Timer_PendingLoaders(Handle timer)
{
	int Loaders = GetLoadingPlayers();
	int Human = GetRealPlayers();
	
	if(Human > 0 && (Loaders < 1 || g_bIgnoreLoaders || AreTheTeamsCurrentlyFull()))
	{
		g_hTimer_WarmingUpTime = CreateTimer(3.0, Timer_WarmingUpBeforeStartingCountdown, _, TIMER_FLAG_NO_MAPCHANGE);
		g_hTimer_PendingLoader = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

/* =============================================================================================================== *
 *										Warming Up To Start Countdown Until Doors Open							   *
 *================================================================================================================ */

Action Timer_WarmingUpBeforeStartingCountdown(Handle timer)
{
	if(Cvar_DoorLock_EnableRdy.BoolValue)
	{
		for(int i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != 1) Create_ShowTeamsReadyStatus(i);
		
		g_hTimer_UnreadyGiveUp = CreateTimer(1.0, Timer_WaitingForUnreadyPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		g_hTimer_ReadyUpChecks = CreateTimer(0.5, Timer_ReadyUpStatusChecker, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else g_hTimer_CountdownTime = CreateTimer(1.0, Timer_StartCountdownToUnlock, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	g_hTimer_WarmingUpTime = null;
	return Plugin_Handled;
}

Action Timer_StartCountdownToUnlock(Handle timer)
{
	if(Cvar_DoorLock_EnableRdy.BoolValue && (!TeamReadyUpPercentageReached(2) || !TeamReadyUpPercentageReached(3)))
	{	
		g_hTimer_CountdownTime = null;
		return Plugin_Stop;
	}
	
	if(g_iUnlocksTime <= 0 || g_bLeftSafeAreas)
	{
		PrintHintTextToAll("%t", "Move Out");
		g_hTimer_CountdownTime = null;
		
		UnFreezePlayersInFirstChapters();
		UnLockAllRotatingSaferoomDoors();
		UnTriggerSafeAreaLocksFeatures();
		return Plugin_Stop;
	}
	
	if(g_bAdminTakeover || !g_bLockSafeAreas)
	{
		g_hTimer_CountdownTime = null;
		return Plugin_Stop;
	}
	
	g_iUnlocksTime -= 1;
	PrintHintTextToAll("%t", "Round Begin Countdown", g_iUnlocksTime);
	return Plugin_Continue;
}

/* =============================================================================================================== *
 *                     							Timer_WaitingForUnreadyPlayers									   *
 *================================================================================================================ */

Action Timer_WaitingForUnreadyPlayers(Handle timer)
{
	if(g_iGiveUpsTime <= 0 || g_bLeftSafeAreas)
	{
		PrintHintTextToAll("%t", "Move Out");
		g_hTimer_UnreadyGiveUp = null;
		
		UnFreezePlayersInFirstChapters();
		UnLockAllRotatingSaferoomDoors();
		UnTriggerSafeAreaLocksFeatures();
		return Plugin_Stop;
	}
	
	if(g_bAdminTakeover || !g_bLockSafeAreas)
	{
		g_hTimer_UnreadyGiveUp = null;
		return Plugin_Stop;
	}
	
	g_iGiveUpsTime -= 1;
	PrintHintTextToAll("%t", "Ready Up Countdown", g_iGiveUpsTime);
	return Plugin_Continue;
}

/* =============================================================================================================== *
 *													Commands Lock/Unlock										   *
 *================================================================================================================ */

Action Command_Lock(int client, int args)
{
	if(!L4D2_DoorLock_Enable()) return Plugin_Handled;
	else if(g_bLeftSafeAreas) CPrintToChat(client, "%t", "Round Started");
	else if(g_bLockSafeAreas) CPrintToChat(client, "%t", "Saferoom Locked");
	else if(g_iGiveUpsTime <= 0) CPrintToChat(client, "%t", "Ready Up Time Ended");
	else
	{
		g_bAdminTakeover = true;
		FreezePlayersInFirstChapters();
		LockAllRotatingSaferoomDoors();
		TriggerSafeAreaLocksFeatures();
		CPrintToChatAll("%t", "Admin Locks", client);
	}
	return Plugin_Handled;
}

Action Command_Unlock(int client, int args)
{
	if (!L4D2_DoorLock_Enable()) return Plugin_Handled;
	else if(!g_bLockSafeAreas) CPrintToChat(client, "%t", "Saferoom Unlocked");
	else
	{
		g_bAdminTakeover = true;
		PrintHintTextToAll("%t", "Move Out");
		UnFreezePlayersInFirstChapters();
		UnLockAllRotatingSaferoomDoors();
		UnTriggerSafeAreaLocksFeatures();
		CPrintToChatAll("%t", "Admin Unlocks", client);
	}
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *													Commands Ready/Unready										   *
 *================================================================================================================ */

Action Command_Ready(int client, int args)
{
	if(!L4D2_DoorLock_Enable() || !Cvar_DoorLock_EnableRdy.BoolValue) return Plugin_Handled;
	else if(GetClientTeam(client) == 1) CPrintToChat(client, "%t", "Spectator Ready");
	else if(g_bLeftSafeAreas) CPrintToChat(client, "%t", "Round Started");
	else if(g_bClientIsReady[client])CPrintToChat(client, "%t", "You Are Ready");
	else if(g_iGiveUpsTime <= 0) CPrintToChat(client, "%t", "Ready Up Time Ended");
	else if(g_bAdminTakeover) CPrintToChat(client, "%t", "Admin Controls");
	else
	{
		g_bClientIsReady[client] = true;
		CPrintToChat(client, "%t", "Player Is Ready");
		
		if(TeamReadyUpPercentageReached(2) && TeamReadyUpPercentageReached(3))
		{
			if(g_hTimer_CountdownTime == null)
			{
				if(g_hTimer_UnreadyGiveUp != null) delete g_hTimer_UnreadyGiveUp;
				g_iUnlocksTime = Cvar_DoorLock_Countdown.IntValue;
				g_hTimer_CountdownTime = CreateTimer(1.0, Timer_StartCountdownToUnlock, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Handled;
}

Action Command_Unready(int client, int args)
{
	if(!L4D2_DoorLock_Enable() || !Cvar_DoorLock_EnableRdy.BoolValue) return Plugin_Handled;
	else if(GetClientTeam(client) == 1) CPrintToChat(client, "%t", "Spectator Ready");
	else if(g_bLeftSafeAreas) CPrintToChat(client, "%t", "Round Started");
	else if(!g_bClientIsReady[client]) CPrintToChat(client, "%t", "You Are Unready");
	else if(g_iUnrdyCounts[client] < 1) CPrintToChat(client, "%t", "Ready Up Limit");
	else if(g_iGiveUpsTime <= 0) CPrintToChat(client, "%t", "Ready Up Time Ended");
	else if(g_bAdminTakeover) CPrintToChat(client, "%t", "Admin Controls");
	else
	{
		g_iUnrdyCounts[client] -= 1;
		g_bClientIsReady[client] = false;
		CPrintToChat(client, "%t", "Player Is Unready");
	
		if(!TeamReadyUpPercentageReached(2) || !TeamReadyUpPercentageReached(3))
		{
			if(g_hTimer_UnreadyGiveUp == null)
				g_hTimer_UnreadyGiveUp = CreateTimer(1.0, Timer_WaitingForUnreadyPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *                     								Ready Up Status Checker										   *
 *================================================================================================================ */

Action Timer_ReadyUpStatusChecker(Handle timer)
{
	if(g_bLeftSafeAreas || g_iGiveUpsTime <= 0 || g_bAdminTakeover)
	{
		g_hTimer_ReadyUpChecks = null;
		return Plugin_Stop;
	}
	
	Notify_ReadyStatus();
	
	if(!TeamReadyUpPercentageReached(2) || !TeamReadyUpPercentageReached(3))
	{
		if(!g_bLockSafeAreas)
		{
			FreezePlayersInFirstChapters();
			LockAllRotatingSaferoomDoors();
			TriggerSafeAreaLocksFeatures();
		}
		
		if(g_hTimer_UnreadyGiveUp == null)
			g_hTimer_UnreadyGiveUp = CreateTimer(1.0, Timer_WaitingForUnreadyPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(TeamReadyUpPercentageReached(2) && TeamReadyUpPercentageReached(3))
	{
		if(!g_bLockSafeAreas || g_hTimer_CountdownTime != null) return Plugin_Continue;
		if(g_hTimer_UnreadyGiveUp != null) delete g_hTimer_UnreadyGiveUp;
		g_iUnlocksTime = Cvar_DoorLock_Countdown.IntValue;
		g_hTimer_CountdownTime = CreateTimer(1.0, Timer_StartCountdownToUnlock, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

void Notify_ReadyStatus()
{
	if(!Cvar_DoorLock_Announces.BoolValue) return;
	
	if(!g_bSurvivorReady && TeamReadyUpPercentageReached(2) && GetRealTeamCount(2) > 0)
	{
		g_bSurvivorReady = true;
		CPrintToChatAll("%t", "Notify Survivors Ready", GetReadyTeamCount(2), GetRealTeamCount(2), TeamReadyUpPercentage(2));
	}
	
	else if(!g_bInfectedReady && TeamReadyUpPercentageReached(3) && GetRealTeamCount(3) > 0)
	{
		g_bInfectedReady = true;
		CPrintToChatAll("%t", "Notify Infected Ready", GetReadyTeamCount(3), GetRealTeamCount(3), TeamReadyUpPercentage(3));
	}
	
	if(g_bSurvivorReady && !TeamReadyUpPercentageReached(2))
	{
		g_bSurvivorReady = false;
		CPrintToChatAll("%t", "Notify Survivors Unready", GetReadyTeamCount(2), GetRealTeamCount(2), TeamReadyUpPercentage(2));
	}
	
	else if(g_bInfectedReady && !TeamReadyUpPercentageReached(3))
	{
		g_bInfectedReady = false;
		CPrintToChatAll("%t", "Notify Infected Unready", GetReadyTeamCount(3), GetRealTeamCount(3), TeamReadyUpPercentage(3));
	}
}

/* =============================================================================================================== *
 *                     							Panel For Ready/Unready Status									   *
 *================================================================================================================ */

void Create_ShowTeamsReadyStatus(int client)
{
	g_bPanelIsOpened[client] = true;
	
	Panel panel = new Panel();
	static char sTemp[256];

	FormatEx(sTemp, sizeof(sTemp), "%t", "Menu Title");
	panel.DrawItem(sTemp, ITEMDRAW_RAWLINE);
	
	panel.DrawItem(" ", ITEMDRAW_RAWLINE);
	FormatEx(sTemp, sizeof(sTemp), "%t", "Menu Ready");
	panel.DrawItem(sTemp, !g_bClientIsReady[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	FormatEx(sTemp, sizeof(sTemp), "%t", "Menu Unready");
	panel.DrawItem(sTemp, g_bClientIsReady[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	panel.DrawItem(" ", ITEMDRAW_RAWLINE);
	if(GetRealTeamCount(2) > 0) FormatEx(sTemp, sizeof(sTemp), "%s %t: [%.1f%%]", TeamReadyUpPercentageReached(2) ? "▣" : "▢", "Menu Survivor", TeamReadyUpPercentage(2));
	else FormatEx(sTemp, sizeof(sTemp), "▣ %t: [100.0%%]", "Menu Survivor");
	panel.DrawItem(sTemp, ITEMDRAW_RAWLINE);
	
	if(GetRealTeamCount(3) > 0) FormatEx(sTemp, sizeof(sTemp), "%s %t: [%.1f%%]", TeamReadyUpPercentageReached(3) ? "▣" : "▢", "Menu Infected", TeamReadyUpPercentage(3));
	else FormatEx(sTemp, sizeof(sTemp), "▣ %t: [100.0%%]", "Menu Infected");
	panel.DrawItem(sTemp, ITEMDRAW_RAWLINE);
	
	panel.DrawItem(" ", ITEMDRAW_RAWLINE);
	FormatEx(sTemp, sizeof(sTemp), "%t", "Menu Close");
	panel.DrawItem(sTemp);
	
	panel.Send(client, Handle_ShowPlayersReadyStatus, 1);
	CreateTimer(0.1, Timer_ActivatePanel, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_ActivatePanel(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client == 0 || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) == 1 || !g_bPanelIsOpened[client]) return Plugin_Handled;
	
	if(g_bLockSafeAreas) Create_ShowTeamsReadyStatus(client);
	return Plugin_Handled;
}

int Handle_ShowPlayersReadyStatus(Menu panel, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select) 
	{
		if (param2 == 1) Command_Ready(param1, 0);
		else if (param2 == 2) Command_Unready(param1, 0);
		else if (param2 == 3) g_bPanelIsOpened[param1] = false;
	}
	return 0;
}

/* =============================================================================================================== *
 *										Adding Features While Safe Area Is Locked								   *
 *================================================================================================================ */

void TriggerSafeAreaLocksFeatures()
{
	g_bLockSafeAreas = true;
	Cvar_DoorLock_NoBotMove.SetString("1");
	
	if(Cvar_DoorLock_AddCheats.IntValue > 1) Cvar_DoorLock_MaxesAmmo.SetString("1");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(Cvar_DoorLock_AddCheats.IntValue == 1 || Cvar_DoorLock_AddCheats.IntValue == 3)
				SetEntProp(i, Prop_Data, "m_takedamage", 1);
				
			AcceptEntityInput(i, "DisableLedgeHang");
		}
	}
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client || !IsClientInGame(client) || !L4D2_DoorLock_Enable() || !g_bLockSafeAreas || g_bLeftSafeAreas) return;
	
	AcceptEntityInput(client, "DisableLedgeHang");
	
	if(Cvar_DoorLock_AddCheats.IntValue == 1 || Cvar_DoorLock_AddCheats.IntValue == 3)
		SetEntProp(client, Prop_Data, "m_takedamage", 1);
}

public void OnClientPutInServer(int client)
{
	if(!L4D2_DoorLock_Enable() || !IsClientInGame(client)) return;
	
	g_bClientIsReady[client] = false;
	
	if(Cvar_DoorLock_EnableRdy.BoolValue)
		CreateTimer(5.0, Timer_DisplayPanelOnConnect, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	
	if(g_bLockSafeAreas && !g_bLeftSafeAreas)
	{
		AcceptEntityInput(client, "DisableLedgeHang");
		
		if(Cvar_DoorLock_AddCheats.IntValue == 1 || Cvar_DoorLock_AddCheats.IntValue == 3)
			SetEntProp(client, Prop_Data, "m_takedamage", 1);
	}
}

Action Timer_DisplayPanelOnConnect(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) == 1 || !g_bLockSafeAreas || g_bLeftSafeAreas || g_hTimer_WarmingUpTime != null)
		return Plugin_Handled;
	
	Create_ShowTeamsReadyStatus(client);
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *										Removing Features While Safe Area Is Locked								   *
 *================================================================================================================ */

void UnTriggerSafeAreaLocksFeatures()
{
	g_bLockSafeAreas = false;
	ResetConVar(Cvar_DoorLock_NoBotMove);
	
	if(Cvar_DoorLock_AddCheats.IntValue > 1) ResetConVar(Cvar_DoorLock_MaxesAmmo);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			AcceptEntityInput(i, "EnableLedgeHang");
			
			if(Cvar_DoorLock_AddCheats.IntValue == 1 || Cvar_DoorLock_AddCheats.IntValue == 3)
				SetEntProp(i, Prop_Data, "m_takedamage", 2);
		}
	}
}

public void OnClientDisconnect(int client)
{
	if(!L4D2_DoorLock_Enable() || !IsClientInGame(client)) return;
	
	if(g_bAdminTakeover && g_bLockSafeAreas && IsClientGenericAdmin(client) && GetAdminsCount() == 1)
	{
		PrintHintTextToAll("%t", "Move Out");
		UnFreezePlayersInFirstChapters();
		UnLockAllRotatingSaferoomDoors();
		UnTriggerSafeAreaLocksFeatures();
	}
	
	if(!g_bLockSafeAreas || g_bLeftSafeAreas)
	{
		AcceptEntityInput(client, "EnableLedgeHang");
		
		if(Cvar_DoorLock_AddCheats.IntValue == 1 || Cvar_DoorLock_AddCheats.IntValue == 3)
			SetEntProp(client, Prop_Data, "m_takedamage", 2);
	}
}

/* =============================================================================================================== *
 *                     				Force Round To Start When Condition Is Triggered							   *
 *================================================================================================================ */

Action Timer_ForceRoundToStart(Handle timer)
{
	if(g_bLeftSafeAreas)
	{
		g_hTimer_ForceVersusST = null;
		return Plugin_Stop;
	}
	
	static int iTimes = 0;
	
	if(iTimes > 120 && !g_bLockSafeAreas)
	{
		iTimes = 0;
		g_bLeftSafeAreas = true;
		L4D_ForceVersusStart();
		
		g_hTimer_ForceVersusST = null;
		return Plugin_Stop;
	}
	
	++ iTimes;
	return Plugin_Continue;
}

/* =============================================================================================================== *
 *                     				Prevent Rounds From Starting Until All Players Are Ready					   *
 *================================================================================================================ */

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if(L4D2_DoorLock_Enable() && g_bLockSafeAreas && !g_bLeftSafeAreas && g_iGiveUpsTime > 0)
	{
		Activate_SurvivorTeleport(client);
		return Plugin_Handled;
	}
	
	g_bLeftSafeAreas = true;
	return Plugin_Continue;
}

/* =============================================================================================================== *
 *											Teleporting Survivors In First Chapters								   *
 *================================================================================================================ */

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!L4D2_DoorLock_Enable() || !g_bLockSafeAreas || !Cvar_DoorLock_ModesType.BoolValue || !g_bFirstScenario) return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client || !IsClientInGame(client) || GetClientTeam(client) != 2) return;
	
	Activate_SurvivorTeleport(client);
}

void Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	if(!L4D2_DoorLock_Enable() || !g_bLockSafeAreas || !Cvar_DoorLock_ModesType.BoolValue || !g_bFirstScenario) return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client || !IsClientInGame(client) || GetClientTeam(client) != 2) return;
	
	L4D2_VScriptWrapper_ReviveFromIncap(client);
	Activate_SurvivorTeleport(client);
}

/* =============================================================================================================== *
 *										Teleport Survivors + Display Warning Message							   *
 *================================================================================================================ */

void Activate_SurvivorTeleport(int client)
{
	if (!IsClientInGame(client) || !BlockClientRepetition(client) || GetClientTeam(client) != 2 || IsFakeClient(client)) return;
	
	if(Cvar_DoorLock_LeaverMsg.IntValue == 1) CPrintToChat(client, "%t", "Leavers Message");
	else if(Cvar_DoorLock_LeaverMsg.IntValue == 2) PrintCenterText(client, "%t", "Leavers Message");
	
	TeleportSurvivorsToSafeAreas(client);
	CreateTimer(0.1, Timer_HealSurvivor, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

bool BlockClientRepetition(int client)
{
	if (g_iClientDelay[client] != 0 && (g_iClientDelay[client] + 1 > GetTime())) return false;

	g_iClientDelay[client] = GetTime();
	return true;
}

/* =============================================================================================================== *
 *														Teleport Method											   *
 *================================================================================================================ */

void TeleportSurvivorsToSafeAreas(int client)
{
	char sMap[32];
	float vPos[3], vAng[3];
	GetCurrentMap(sMap, sizeof(sMap));
	
	if(g_iCurrentMaps == C1M1)
	{
		vPos[0] = 582.0;  vAng[0] = 0.0;
		vPos[1] = 5624.0; vAng[1] = 180.0;
		vPos[2] = 2944.0; vAng[2] = 0.0;	
		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
	}
	else if(g_iCurrentMaps == C2M1)
	{
		vPos[0] = 11005.0; vAng[0] = 0.0;
		vPos[1] = 7869.0;  vAng[1] = -180.0;
		vPos[2] = -490.0;  vAng[2] = 0.0;
		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
	}
	else if(g_iCurrentMaps == C3M1)
	{
		vPos[0] = -12573.0; vAng[0] = 0.0;
		vPos[1] = 10485.0;  vAng[1] = -30.0;
		vPos[2] = 280.0;    vAng[2] = 0.0;
		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
	}
	else if(g_iCurrentMaps == C4M1)
	{
		vPos[0] = -6963.0; vAng[0] = 0.0;
		vPos[1] = 7698.0;  vAng[1] = 0.0;
		vPos[2] = 167.0;   vAng[2] = 0.0;
		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
	}
	else if(g_iCurrentMaps == C5M1)
	{
		vPos[0] = 782.0;  vAng[0] = 3.0;
		vPos[1] = 667.0;  vAng[1] = -90.0;
		vPos[2] = -410.0; vAng[2] = 0.0;
		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
	}
	else if(g_iCurrentMaps == C6M1)
	{
		vPos[0] = 919.0;  vAng[0] = 3.0;
		vPos[1] = 3830.0; vAng[1] = -90.0;
		vPos[2] = 167.0;  vAng[2] = 0.0;
		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
	}
	else if(g_iCurrentMaps == C7M1)
	{
		vPos[0] = 13831.0; vAng[0] = 3.0;
		vPos[1] = 2743.0;  vAng[1] = -90.0;
		vPos[2] = 98.0;    vAng[2] = 0.0;
		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
	}
	else if(g_iCurrentMaps == C8M1)
	{
		vPos[0] = 2022.0; vAng[0] = 3.0;
		vPos[1] = 907.0;  vAng[1] = 180.0;
		vPos[2] = 505.0;  vAng[2] = 0.0;
		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
	}
	else if(g_iCurrentMaps == C9M1)
	{
		vPos[0] = -9891.0;  vAng[0] = 0.0;
		vPos[1] = -8668.0;  vAng[1] = 0.0;
		vPos[2] = 65.0; 	vAng[2] = 0.0;
		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
	}
	else if(g_iCurrentMaps == C10M1)
	{
		vPos[0] = -11698.0; vAng[0] = 0.0;
		vPos[1] = -14750.0; vAng[1] = 90.0;
		vPos[2] = -133.0; 	vAng[2] = 0.0;
		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
	}
	else if(g_iCurrentMaps == C11M1)
	{
		vPos[0] = 6821.0; vAng[0] = 0.0;
		vPos[1] = -611.0; vAng[1] = 180.0;
		vPos[2] = 840.0;  vAng[2] = 0.0;
		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
	}
	else if(g_iCurrentMaps == C12M1)
	{
		vPos[0] = -7972.0;  vAng[0] = 0.0;
		vPos[1] = -15136.0; vAng[1] = 168.0;
		vPos[2] = 345.0; 	vAng[2] = 0.0;
		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
	}
	else if(g_iCurrentMaps == C13M1)
	{
		vPos[0] = -2984.0; vAng[0] = 0.0;
		vPos[1] = -931.0;  vAng[1] = 90.0;
		vPos[2] = 144.0;   vAng[2] = 0.0;
		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
	}
	else if(g_iCurrentMaps == C14M1)
	{
		vPos[0] = -4183.0;  vAng[0] = 0.0;
		vPos[1] = -10682.0; vAng[1] = 90.0;
		vPos[2] = -221.0; 	vAng[2] = 0.0;
		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
	}
}

/* =============================================================================================================== *
 *													Healing Players												   *
 *================================================================================================================ */

Action Timer_HealSurvivor(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client == 0 || !IsClientInGame(client)) return Plugin_Handled;
	
	Heal_Survivor(client);
	return Plugin_Handled;
}

void Heal_Survivor(int client)
{
	if(!IsClientInGame(client) || GetClientTeam(client) != 2 || g_bLeftSafeAreas) return;
	int CmdFlags = GetCommandFlags("give");
	SetCommandFlags("give", CmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give health");
	SetCommandFlags("give", CmdFlags);
	L4D_SetTempHealth(client, 0.0);
}

/* =============================================================================================================== *
 *											Freezing Players In First Chapters									   *
 *================================================================================================================ */

void FreezePlayersInFirstChapters()
{
	if(!g_bFirstScenario || Cvar_DoorLock_ModesType.BoolValue) return;
	for (int i = 1; i <= MaxClients; i++)
		if(IsValidEntity(i) && IsClientInGame(i) && GetClientTeam(i) == 2)
			SetEntityMoveType(i, MOVETYPE_NONE);
}

/* =============================================================================================================== *
 *											Unfreezing Players In First Chapters								   *
 *================================================================================================================ */

void UnFreezePlayersInFirstChapters()
{
	if(!g_bFirstScenario || Cvar_DoorLock_ModesType.BoolValue) return;
	for (int i = 1; i <= MaxClients; i++)
		if(IsValidEntity(i) && IsClientInGame(i) && GetClientTeam(i) == 2)
			SetEntityMoveType(i, MOVETYPE_WALK);
}

/* =============================================================================================================== *
 *													Locking All Saferoom Dorrs									   *
 *================================================================================================================ */

void LockAllRotatingSaferoomDoors()
{
	int iCheckPointDoor = L4D_GetCheckpointFirst();
	if(!IsValidEnt(iCheckPointDoor)) return;
	
	AcceptEntityInput(iCheckPointDoor, "Close");
	AcceptEntityInput(iCheckPointDoor, "Lock");
	SetVariantString("spawnflags 40960");
	AcceptEntityInput(iCheckPointDoor, "AddOutput");

	int g_iDoorLockColors[3];
	char sColor[16];
	
	Cvar_DoorLock_LockColor.GetString(sColor, sizeof(sColor));
	GetColor(g_iDoorLockColors, sColor);
	if(Cvar_DoorLock_AllowGlow.BoolValue)
		L4D2_SetEntityGlow(iCheckPointDoor, L4D2Glow_Constant, Cvar_DoorLock_GlowRange.IntValue, 0, g_iDoorLockColors, false);
}

/* =============================================================================================================== *
 *													Unlocking All Saferoom Dorrs								   *
 *================================================================================================================ */

void UnLockAllRotatingSaferoomDoors()
{
	int iCheckPointDoor = L4D_GetCheckpointFirst();
	if(!IsValidEnt(iCheckPointDoor)) return;
	
	SetVariantString("spawnflags 8192");
	AcceptEntityInput(iCheckPointDoor, "AddOutput");
	AcceptEntityInput(iCheckPointDoor, "Unlock");
	AcceptEntityInput(iCheckPointDoor, "Open");
	AcceptEntityInput(iCheckPointDoor, "StartGlowing");
	
	int iDoorUnlockColors[3];
	char sColor[16];
	
	Cvar_DoorLock_OpenColor.GetString(sColor, sizeof(sColor));
	GetColor(iDoorUnlockColors, sColor);
	if(Cvar_DoorLock_AllowGlow.BoolValue)
		L4D2_SetEntityGlow(iCheckPointDoor, L4D2Glow_Constant, Cvar_DoorLock_GlowRange.IntValue, 0, iDoorUnlockColors, false);
}

/* =============================================================================================================== *
 *											Change Saferoom Doors Lock/Unlock Colors							   *
 *================================================================================================================ */

void GetColor(int[] array, char[] sTemp)
{
	if(StrEqual(sTemp, ""))
	{
		array[0] = array[1] = array[2] = 0;
		return;
	}
	
	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, 3, 4);
	
	if(color != 3)
	{
		array[0] = array[1] = array[2] = 0;
		return;
	}
	
	array[0] = StringToInt(sColors[0]);
	array[1] = StringToInt(sColors[1]);
	array[2] = StringToInt(sColors[2]);
}

/* =============================================================================================================== *
 *													Calculating ReadyUpPercentage								   *
 *================================================================================================================ */

bool TeamReadyUpPercentageReached(int team)
{
	int iReadyCount = GetReadyTeamCount(team);
	int iTotalHumanTeam = GetRealTeamCount(team);
	float fPercent = (float(iReadyCount) / float(iTotalHumanTeam)) * 100.0;
	if(fPercent < Cvar_DoorLock_RdyPercnt.FloatValue) return false;
	return true;
}

float TeamReadyUpPercentage(int team)
{
	int iReadyCount = GetReadyTeamCount(team);
	int iTotalHumanTeam = GetRealTeamCount(team);
	float fPercent = (float(iReadyCount) / float(iTotalHumanTeam)) * 100.0;
	return fPercent;
}

int GetReadyTeamCount(int team)
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team && g_bClientIsReady[i])
			number++;
	return number;
}

/* =============================================================================================================== *
 *											Some Other Checks And Counting Players								   *
 *================================================================================================================ */

bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}

/* =============================================================================================================== *
 *												  IsClientGenericAdmin											   *
 *================================================================================================================ */

bool IsClientGenericAdmin(int client)
{
	return CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false);
}

/* =============================================================================================================== *
 *												AreTheTeamsCurrentlyFull										   *
 *================================================================================================================ */

bool AreTheTeamsCurrentlyFull()
{
	if(GetTotalSlots() == (GetRealTeamCount(3) + GetRealTeamCount(2))) return true;
	return false;
}

/* =============================================================================================================== *
 *													Counting Players											   *
 *================================================================================================================ */

int GetAdminsCount()
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsClientGenericAdmin(i))
			number++;
	return number;
}

int GetTotalSlots()
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && GetClientTeam(i) == 2)
			number += 2;
	return number;
}

int GetLoadingPlayers()
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
		if(IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i))
			number++;
	return number;
}

int GetRealPlayers()
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != 1)
			number++;
	return number;
}

int GetRealTeamCount(int team)
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
			number++;
	return number;
}