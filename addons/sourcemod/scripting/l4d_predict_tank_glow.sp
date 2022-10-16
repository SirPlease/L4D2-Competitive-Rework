#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <l4d_boss_vote>
#define REQUIRE_PLUGIN

#tryinclude <l4d_info_editor>

#define PLUGIN_VERSION "1.4"

public Plugin myinfo = 
{
	name = "[L4D & 2] Predict Tank Glow",
	author = "Forgetest",
	description = "Predicts flow tank positions and fakes models with glow (mimic \"Dark Carnival: Remix\").",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

//=========================================================================================================

#define GAMEDATA_FILE "l4d_predict_tank_glow"
#include "tankglow/tankglow_defines.inc"

bool g_bLeft4Dead2;

CZombieManager ZombieManager;

// order is foreign referred in `PickTankVariant()`
#define TANK_VARIANT_SLOT (sizeof(g_sTankModels)-1)
#define TANK_MODEL_STRLEN 128
static const char g_sTankModels[][TANK_MODEL_STRLEN] = {
	"models/infected/hulk.mdl",
	"models/infected/hulk_dlc3.mdl",
	"models/infected/hulk_l4d1.mdl",
	"N/A" // TankVariant slot
};

int g_iPredictModel = INVALID_ENT_REFERENCE;
float g_vModelPos[3], g_vModelAng[3];

ConVar g_cvTeleport;

//=========================================================================================================

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead: g_bLeft4Dead2 = false;
		case Engine_Left4Dead2: g_bLeft4Dead2 = true;
		default:
		{
			strcopy(error, err_max, "Plugin supports Left 4 Dead & 2 only.");
			return APLRes_SilentFailure;
		}
	}
	
	MarkNativeAsOptional("InfoEditor_GetString");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadSDK();
	
	g_cvTeleport = CreateConVar("l4d_predict_glow_tp",
								"0",
								"Teleports tank to glow position for consistency.\n"
							...	"0 = Disable, 1 = Enable",
								FCVAR_SPONLY,
								true, 0.0, true, 1.0);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("tank_spawn", Event_TankSpawn);
}

//=========================================================================================================

/**
 * @brief Called when the boss percents are updated.
 * @remarks Triggered via boss votes, force tanks, force witches.
 * @remarks Special value: -1 indicates ignored in change, 0 disabled (no spawn).
 */
public void OnUpdateBosses(int iTankFlow, int iWitchFlow)
{
	if (iTankFlow > 0)
	{
		Event_RoundStart(null, "", false);
	}
}

//=========================================================================================================

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!L4D_IsVersusMode()) return;
	
	if (!GameRules_GetProp("m_bInSecondHalfOfRound", 1))
	{
		g_vModelPos = NULL_VECTOR;
		g_vModelAng = NULL_VECTOR;
	}
	
	// Need to delay a bit, seems crashing otherwise.
	CreateTimer(1.0, Timer_DelayProcess, .flags = TIMER_FLAG_NO_MAPCHANGE);
	
	// TODO: Is there a hook?
	CreateTimer(5.0, Timer_AccessTankWarp, false, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapStart()
{
	for (int i = 0; i < sizeof(g_sTankModels); ++i)
		PrecacheModel(g_sTankModels[i]);
}

public void OnMapEnd()
{
	strcopy(g_sTankModels[TANK_VARIANT_SLOT], TANK_MODEL_STRLEN, "N/A");
}

Action Timer_DelayProcess(Handle timer)
{
	if (!L4D_IsVersusMode()) return Plugin_Stop;
	
	if (IsValidEdict(g_iPredictModel))
	{
		RemoveEntity(g_iPredictModel);
		g_iPredictModel = INVALID_ENT_REFERENCE;
	}
	
	g_iPredictModel = ProcessPredictModel(g_vModelPos, g_vModelAng);
	if (g_iPredictModel != INVALID_ENT_REFERENCE)
		g_iPredictModel = EntIndexToEntRef(g_iPredictModel);
	
	return Plugin_Stop;
}

Action Timer_AccessTankWarp(Handle timer, bool isRetry)
{
	if (!L4D_IsVersusMode()) return Plugin_Stop;
	
	if (g_bLeft4Dead2 && IsValidEdict(g_iPredictModel))
	{
		char buffer[256];
		
		L4D2_GetVScriptOutput("ret <- ( \"anv_tankwarps\" in getroottable() );<RETURN>ret</RETURN>", buffer, sizeof(buffer));
		if (strcmp(buffer, "1") != 0)
		{
			// retry or seeu
			if (!isRetry) CreateTimer(15.0, Timer_AccessTankWarp, true, TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Stop;
		}
		
		/**
		 *	if ( "anv_tankwarps" in getroottable() )
		 *	{
		 *		::anv_tankwarps.OnGameEvent_tank_spawn(
		 *		{
		 *			userid = 0,
		 *			tankid = %d
		 *		} );
		 *		::anv_tankwarps.iTankCount--;
		 *	}
		 */
		FormatEx(buffer, sizeof(buffer),
			"::anv_tankwarps.OnGameEvent_tank_spawn(\
			{\
				userid = 0,\
				tankid = %d\
			} );\
			::anv_tankwarps.iTankCount--;",
			EntRefToEntIndex(g_iPredictModel)
		);
		
		/**
		 *	Code for re-organized community update. Commented for afterward use.
		 *
		 *	---------------------------------------------
		 *
		 *	if ( "CommunityUpdate" in getroottable() )
		 *	{
		 *		CommunityUpdate().OnGameEvent_tank_spawn(
		 *		{
		 *			userid = 0,
		 *			tankid = %d
		 *		} );
		 *		CommunityUpdate().m_iTankCount--;
		 *	}
		 */
	}
	
	return Plugin_Stop;
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!L4D_IsVersusMode()) return;
	
	if (!IsValidEdict(g_iPredictModel))
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client)
		return;
	
	if (IsFakeClient(client))
	{
		if (g_cvTeleport.BoolValue)
			TeleportEntity(client, g_vModelPos, g_vModelAng, NULL_VECTOR);
	}
	
	RemoveEntity(g_iPredictModel);
	g_iPredictModel = INVALID_ENT_REFERENCE;
}

//=========================================================================================================

int ProcessPredictModel(float vPos[3], float vAng[3])
{
	if (GetVectorLength(vPos) == 0.0)
	{
		if (L4D2Direct_GetVSTankToSpawnThisRound(0))
		{
			for (float p = L4D2Direct_GetVSTankFlowPercent(0); p < 1.0; p += 0.01)
			{
				TerrorNavArea nav = GetBossSpawnAreaForFlow(p);
				if (nav.Valid())
				{
					L4D_FindRandomSpot(view_as<int>(nav), vPos);
					vPos[2] -= 8.0; // less floating off ground
					
					vAng[0] = 0.0;
					vAng[1] = GetRandomFloat(0.0, 360.0);
					vAng[2] = 0.0;
					
					break;
				}
			}
		}
	}
	
	if (GetVectorLength(vPos) == 0.0)
		return -1;
	
	return CreateTankGlowModel(vPos, vAng);
}

TerrorNavArea GetBossSpawnAreaForFlow(float flow)
{
	float vPos[3];
	TheEscapeRoute().GetPositionOnPath(flow, vPos);
	
	TerrorNavArea nav = TerrorNavArea(vPos);
	if (!nav.Valid())
		return NULL_NAV_AREA;
	
	ArrayList aList = new ArrayList();
	while( !nav.IsValidForWanderingPopulation()
		|| nav.m_isUnderwater
		|| (nav.GetCenter(vPos), vPos[2] += 10.0, !ZombieManager.IsSpaceForZombieHere(vPos))
		|| nav.m_activeSurvivors )
	{
		if (aList.FindValue(nav) != -1)
		{
			delete aList;
			return NULL_NAV_AREA;
		}
		
		if (nav.Valid())
			aList.Push(nav);
		
		nav = nav.GetNextEscapeStep();
	}
	
	delete aList;
	return nav;
}

//=========================================================================================================

int CreateTankGlowModel(const float vPos[3], const float vAng[3])
{
	int entity = CreateEntityByName("prop_dynamic");
	if (entity == -1)
		return -1;
	
	SetEntityModel(entity, g_sTankModels[PickTankVariant()]);
	DispatchKeyValue(entity, "disableshadows", "1");
	DispatchKeyValue(entity, "DefaultAnim", "idle");
	DispatchSpawn(entity);
	
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
	SetEntProp(entity, Prop_Send, "m_nSolidType", 0);
	L4D2_SetEntityGlow(entity, L4D2Glow_Constant, 0, 0, {77, 102, 255}, false);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	
	return entity;
}

//=========================================================================================================

public void OnGetMissionInfo(int pThis)
{
	if (strcmp(g_sTankModels[TANK_VARIANT_SLOT], "N/A") == 0)
	{
		static char buffer[64];
		FormatEx(buffer, sizeof(buffer), "modes/versus/%i/TankVariant", L4D_GetCurrentChapter());
		InfoEditor_GetString(pThis, buffer, g_sTankModels[TANK_VARIANT_SLOT], TANK_MODEL_STRLEN);
	}
}

int PickTankVariant()
{
	if (strcmp(g_sTankModels[TANK_VARIANT_SLOT], "N/A") != 0)
		return TANK_VARIANT_SLOT;
	
	if (!g_bLeft4Dead2 || L4D2_GetSurvivorSetMod() == 2)
		return 0;
	
	// in case some characteristic configs enables flow tank
	char sCurrentMap[64];
	GetCurrentMap(sCurrentMap, 6);
	if (strcmp(sCurrentMap, "c7m1_docks") == 0)
		return 1;
	
	return 2;
}