#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "2.1"

public Plugin myinfo = 
{
	name = "[L4D & 2] Scripted Tank Stage Fix",
	author = "Forgetest",
	description = "Fix some issues of skipping stages regarding Tanks in finale.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "l4d2_scripted_tank_stage_fix"
#define FUNCTION_NAME "CDirectorScriptedEventManager::UpdateScriptedTankStage"
#define FUNCTION2_NAME "ZombieManager::ReplaceTank"
#define OFFSET_SPAWN "CDirectorScriptedEventManager::m_tankSpawning"
#define OFFSET_TANKCOUNT "m_iTankCount"

int g_iOffs_m_tankSpawning, g_iOffs_m_iTankCount;

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

methodmap CDirector
{
	public CDirector(Address ptr) {
		return view_as<CDirector>(ptr);
	}
	
	property int m_iTankCount {
		public get() {
			return LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOffs_m_iTankCount), NumberType_Int32);
		}
		public set(int val) {
			StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iOffs_m_iTankCount), val, NumberType_Int32);
		}
	}
};
CDirector TheDirector;

bool isReplaceInProgress, isLeft4Dead2;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
	case Engine_Left4Dead: isLeft4Dead2 = false;
	case Engine_Left4Dead2: isLeft4Dead2 = true;
	default:
		{
			strcopy(error, err_max, "Plugin supports L4D & 2 only");
			return APLRes_SilentFailure;
		}
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	GameData gd = new GameData(GAMEDATA_FILE);
	if (!gd)
		SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	g_iOffs_m_iTankCount = gd.GetOffset(OFFSET_TANKCOUNT);
	if (g_iOffs_m_iTankCount == -1)
		SetFailState("Missing offset \""...OFFSET_TANKCOUNT..."\"");
	
	DynamicDetour hDetour = DynamicDetour.FromConf(gd, FUNCTION2_NAME);
	if (!hDetour)
		SetFailState("Missing detour setup \""...FUNCTION2_NAME..."\"");
	if (!hDetour.Enable(Hook_Pre, DTR_ReplaceTank) || !hDetour.Enable(Hook_Post, DTR_ReplaceTank_Post))
		SetFailState("Failed to detour \""...FUNCTION2_NAME..."\"");
	
	delete hDetour;
	
	if (isLeft4Dead2)
	{
		g_iOffs_m_tankSpawning = gd.GetOffset(OFFSET_SPAWN);
		if (g_iOffs_m_tankSpawning == -1)
			SetFailState("Missing offset \""...OFFSET_SPAWN..."\"");
		
		hDetour = DynamicDetour.FromConf(gd, FUNCTION_NAME);
		if (!hDetour)
			SetFailState("Missing detour setup \""...FUNCTION_NAME..."\"");
		if (!hDetour.Enable(Hook_Pre, DTR_UpdateScriptedTankStage) || !hDetour.Enable(Hook_Post, DTR_UpdateScriptedTankStage_Post))
			SetFailState("Failed to detour \""...FUNCTION_NAME..."\"");
	
		delete hDetour;
	}
	
	delete gd;
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_bot_replace", Event_Player_BotReplace);
}

public void OnConfigsExecuted()
{
	TheDirector = CDirector(L4D_GetPointer(POINTER_DIRECTOR));
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	isReplaceInProgress = false;
}

MRESReturn DTR_ReplaceTank_Post(DHookReturn hReturn, DHookParam hParams)
{
	if (hReturn.Value == 0)
		return MRES_Ignored;
	
	int newtank;
	if (!hParams.IsNull(2))
		newtank = hParams.Get(2);
	
	if (!newtank || !IsClientInGame(newtank))
		return MRES_Ignored;
	
	isReplaceInProgress = true;
	CreateTimer(0.1, Timer_ResetReplaceStatus, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return MRES_Ignored;
}

void Event_Player_BotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("bot"));
	if (!client)
		return;
	
	if (GetClientTeam(client) != 3)
		return;
	
	if (GetEntProp(client, Prop_Send, "m_zombieClass") != (isLeft4Dead2 ? 8 : 5))
		return;
	
	isReplaceInProgress = true;
	CreateTimer(0.1, Timer_ResetReplaceStatus, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_ResetReplaceStatus(Handle timer)
{
	isReplaceInProgress = false;
	return Plugin_Stop;
}

public void OnGameFrame()
{
	if (!isReplaceInProgress)
		return;
	
	if (TheDirector.m_iTankCount == 0)
		TheDirector.m_iTankCount++;
}

bool tankSpawnCencalled = false;
public void L4D_OnSpawnTank_PostHandled(int client, const float vecPos[3], const float vecAng[3])
{
	tankSpawnCencalled = true;
}

int spawnCount = 0;
MRESReturn DTR_UpdateScriptedTankStage(Address pEventManager, DHookReturn hReturn, DHookParam hParams)
{
	spawnCount = LoadFromAddress(hParams.Get(1), NumberType_Int32);
	tankSpawnCencalled = false;
	return MRES_Ignored;
}

MRESReturn DTR_UpdateScriptedTankStage_Post(Address pEventManager, DHookReturn hReturn, DHookParam hParams)
{
	EventManager eventMgr = EventManager(pEventManager);
	
	Address pCount = hParams.Get(1);
	
	int count = LoadFromAddress(pCount, NumberType_Int32);
	if (spawnCount == count + 1)
	{
		if (!eventMgr.m_tankSpawning && !tankSpawnCencalled)
		{
			StoreToAddress(pCount, spawnCount, NumberType_Int32);
		}
		
		return MRES_Ignored;
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
