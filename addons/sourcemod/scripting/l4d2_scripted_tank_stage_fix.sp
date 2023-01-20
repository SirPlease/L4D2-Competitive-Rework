#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define PLUGIN_VERSION "1.3"

public Plugin myinfo = 
{
	name = "[L4D2] Scripted Tank Stage Fix",
	author = "Forgetest",
	description = "Fix some issues of skipping stages regarding Tanks in finale.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "l4d2_scripted_tank_stage_fix"
#define FUNCTION_NAME "CDirectorScriptedEventManager::UpdateScriptedTankStage"
#define FUNCTION2_NAME "ZombieManager::ReplaceTank"
#define OFFSET_SPAWN "CDirectorScriptedEventManager::m_tankSpawning"

int g_iOffs_m_tankSpawning;

methodmap EventManager
{
	public EventManager(Address ptr) {
		return view_as<EventManager>(ptr);
	}
	
	property bool m_tankSpawning {
		public get() {
			return LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOffs_m_tankSpawning), NumberType_Int8);
		}
		public set(bool val) {
			StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iOffs_m_tankSpawning), val, NumberType_Int8);
		}
	}
};

bool isReplaceInProgress;

public void OnPluginStart()
{
	GameData gd = new GameData(GAMEDATA_FILE);
	if (!gd)
		SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	g_iOffs_m_tankSpawning = gd.GetOffset(OFFSET_SPAWN);
	if (g_iOffs_m_tankSpawning == -1)
		SetFailState("Missing offset \""...OFFSET_SPAWN..."\"");
	
	DynamicDetour hDetour = DynamicDetour.FromConf(gd, FUNCTION_NAME);
	if (!hDetour)
		SetFailState("Missing detour setup \""...FUNCTION_NAME..."\"");
	if (!hDetour.Enable(Hook_Pre, DTR_UpdateScriptedTankStage) || !hDetour.Enable(Hook_Post, DTR_UpdateScriptedTankStage_Post))
		SetFailState("Failed to detour \""...FUNCTION_NAME..."\"");
	
	delete hDetour;
	
	hDetour = DynamicDetour.FromConf(gd, FUNCTION2_NAME);
	if (!hDetour)
		SetFailState("Missing detour setup \""...FUNCTION2_NAME..."\"");
	if (!hDetour.Enable(Hook_Pre, DTR_ReplaceTank))
		SetFailState("Failed to detour \""...FUNCTION2_NAME..."\"");
	
	delete hDetour;
	delete gd;
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_bot_replace", Event_Player_BotReplace);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	isReplaceInProgress = false;
}

public void L4D_OnReplaceTank(int tank, int newtank)
{
	isReplaceInProgress = true;
	CreateTimer(0.1, Timer_ResetReplaceStatus, _, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_Player_BotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("bot"));
	if (!client)
		return;
	
	if (GetClientTeam(client) != 3)
		return;
	
	if (GetEntProp(client, Prop_Send, "m_zombieClass") != 8)
		return;
	
	isReplaceInProgress = true;
	CreateTimer(0.1, Timer_ResetReplaceStatus, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_ResetReplaceStatus(Handle timer)
{
	isReplaceInProgress = false;
	return Plugin_Stop;
}

int spawnCount = 0;
MRESReturn DTR_UpdateScriptedTankStage(Address pEventManager, DHookReturn hReturn, DHookParam hParams)
{
	spawnCount = LoadFromAddress(hParams.Get(1), NumberType_Int32);
	return MRES_Ignored;
}

MRESReturn DTR_UpdateScriptedTankStage_Post(Address pEventManager, DHookReturn hReturn, DHookParam hParams)
{
	EventManager eventMgr = EventManager(pEventManager);
	
	Address pCount = hParams.Get(1);
	
	int count = LoadFromAddress(pCount, NumberType_Int32);
	if (spawnCount == count + 1)
	{
		if (!eventMgr.m_tankSpawning)
		{
			StoreToAddress(pCount, spawnCount, NumberType_Int32);
		}
		
		return MRES_Ignored;
	}
	
	if (isReplaceInProgress)
	{
		if (hReturn.Value == 0)
		{
			hReturn.Value = 1;
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

MRESReturn DTR_ReplaceTank(DHookReturn hReturn, DHookParam hParams)
{
	int tank, newtank;
	if (!hParams.IsNull(1))
		tank = hParams.Get(1);
	if (!hParams.IsNull(2))
		newtank = hParams.Get(2);
	
	if (!tank || !newtank || tank != newtank)
		return MRES_Ignored;
	
	hReturn.Value = 0;
	return MRES_Supercede;
}
