#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.1"

public Plugin myinfo =
{
	name = "[L4D & 2] Ghost Checkpoint Spawn",
	author = "Forgetest",
	description = "Changes to conditions for ghost spawning in start areas.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "l4d_ghost_checkpoint_spawn"
#define OFFSET_LAST_SURVIVOR_LEFT_START_AREA "CDirector::m_bLastSurvivorLeftStartArea"

int g_iOffs_LastSurvivorLeftStartArea;
methodmap CDirector
{
	property bool m_bLastSurvivorLeftStartArea {
		public set(bool val) { StoreToAddress(L4D_GetPointer(POINTER_DIRECTOR) + view_as<Address>(g_iOffs_LastSurvivorLeftStartArea), view_as<int>(val), NumberType_Int32); }
	}
}
CDirector TheDirector;

bool g_bL4D1Spawn;
bool g_bIntroCondition, g_bGlobalStartCondition, g_bGlobalEndCondition;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	return APLRes_Success;
}

public void OnPluginStart()
{
	bool bLeft4Dead2;
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead: bLeft4Dead2 = false;
		case Engine_Left4Dead2: bLeft4Dead2 = true;
		default:
		{
			SetFailState("Plugin supports L4D & 2 only");
		}
	}
	
	GameData conf = new GameData(GAMEDATA_FILE);
	if (conf == null)
		SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	g_iOffs_LastSurvivorLeftStartArea = conf.GetOffset(OFFSET_LAST_SURVIVOR_LEFT_START_AREA);
	if (g_iOffs_LastSurvivorLeftStartArea == -1)
		SetFailState("Missing offset \""...OFFSET_LAST_SURVIVOR_LEFT_START_AREA..."\"");
	
	delete conf;
	
	ConVar cv;
	cv = CreateConVar("z_ghost_unrestricted_spawn_in_start",
							"0",
							"Allow ghost to materialize in start saferoom even if not all survivors leave.\n"
						...	"0 = Disable, 1 = Intro maps only, 2 = All maps",
							FCVAR_SPONLY|FCVAR_NOTIFY,
							true, 0.0, true, 2.0);
	CVarChg_UnrestrictedSpawnInStart(cv, "", "");
	cv.AddChangeHook(CVarChg_UnrestrictedSpawnInStart);
	
	cv = CreateConVar("z_ghost_unrestricted_spawn_in_end",
							"0",
							"Allow ghost to materialize in end saferoom.\n"
						...	"0 = Disable, 1 = All maps",
							FCVAR_SPONLY|FCVAR_NOTIFY,
							true, 0.0, true, 1.0);
	CVarChg_UnrestrictedSpawnInEnd(cv, "", "");
	cv.AddChangeHook(CVarChg_UnrestrictedSpawnInEnd);
	
	if (bLeft4Dead2)
		return;
	
	cv = CreateConVar("l4d1_ghost_spawn_in_start",
							"0",
							"L4D1 only. Allow ghost to materialize in start saferoom when all survivors leave.\n"
						...	"0 = Disable, 1 = Enable",
							FCVAR_SPONLY|FCVAR_NOTIFY,
							true, 0.0, true, 1.0);
	CVarChg_L4D1SpawnPatch(cv, "", "");
	cv.AddChangeHook(CVarChg_L4D1SpawnPatch);
}

void CVarChg_UnrestrictedSpawnInStart(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int val = convar.IntValue;
	
	g_bIntroCondition = val == 1;
	g_bGlobalStartCondition = val == 2;
}

void CVarChg_UnrestrictedSpawnInEnd(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bGlobalEndCondition = convar.BoolValue;
}

void CVarChg_L4D1SpawnPatch(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bL4D1Spawn = convar.BoolValue;
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	if (g_bGlobalStartCondition
		|| (L4D_IsFirstMapInScenario() && g_bIntroCondition)
	) {
		TheDirector.m_bLastSurvivorLeftStartArea = true;
	}
}

public void L4D_OnEnterGhostState(int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;
	
	if (g_bL4D1Spawn || g_bGlobalEndCondition)
		SDKHook(client, SDKHook_PreThinkPost, SDK_OnPreThink_Post);
}

void SDK_OnPreThink_Post(int client)
{
	if (!IsClientInGame(client))
		return;
	
	if (!L4D_IsPlayerGhost(client))
	{
		SDKUnhook(client, SDKHook_PreThinkPost, SDK_OnPreThink_Post);
	}
	else
	{
		int spawnstate = L4D_GetPlayerGhostSpawnState(client);
		if (~spawnstate & L4D_SPAWNFLAG_RESTRICTEDAREA)
			return;
		
		Address area = L4D_GetLastKnownArea(client);
		if (area == Address_Null)
			return;
		
		// Some stupid maps like Blood Harvest finale and The Passing finale have CHECKPOINT inside a FINALE marked area.
		int spawnattr = L4D_GetNavArea_SpawnAttributes(area);
		if (~spawnattr & NAV_SPAWN_CHECKPOINT || spawnattr & NAV_SPAWN_FINALE)
			return;
		
		float flow = L4D2Direct_GetTerrorNavAreaFlow(area);
		if (flow > 2500.0)
		{
			if (!g_bGlobalEndCondition)
				return;
		}
		else if (!g_bL4D1Spawn)
			return;
		
		L4D_SetPlayerGhostSpawnState(client, spawnstate & ~L4D_SPAWNFLAG_RESTRICTEDAREA);
	}
}