#pragma semicolon 1
#pragma newdecls required

#define DEBUG 0

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <l4d2_lagcomp_manager>

#if DEBUG
// 'l4d2_lagcompmanager_test' extension is required for debugging
// https://github.com/A1mDev/L4D2-LagCompensation-Manager
#include <l4d2_lagcompmanager_test>
#endif

#define GAMEDATA "l4d2_lagcomp_manager"

#define MAX_ENTITY_NAME_SIZE 64

int 
	g_iCUserCmdSize = -1;

ConVar
	g_hSvUnlag = null;

Address
	g_aLagCompensation = Address_Null;

Handle
	g_hLagCompAddEntity = null,
	g_hLagCompRemoveEntity = null,
	g_hStartLagComp = null,
	g_hFinishLagComp = null;

GlobalForward
	g_fwdWantsLagCompensationOnEntity = null;

public Plugin myinfo =
{
	name = "L4D2 Lag Compensation Manager",
	author = "ProdigySim, A1m`, Forgetest",
	description = "Provides lag compensation for entities in left 4 dead 2 (required enable sv_unlag).",
	version = "1.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead2: { }
		default:
		{
			strcopy(error, err_max, "Plugin supports L4D2 only.");
			return APLRes_SilentFailure;
		}
	}
	
	CreateNative("L4D2_LagComp_StartLagCompensation", Ntv_StartLagCompensation);
	CreateNative("L4D2_LagComp_FinishLagCompensation", Ntv_FinishLagCompensation);
	CreateNative("L4D2_LagComp_AddAdditionalEntity", Ntv_AddAdditionalEntity);
	CreateNative("L4D2_LagComp_RemoveAdditionalEntity", Ntv_RemoveAdditionalEntity);
	
	/* forward Action L4D2_LagComp_OnWantsLagCompensationOnEntity(int client, int entity, bool &result, int buttons, int impulse); */
	g_fwdWantsLagCompensationOnEntity = new GlobalForward("L4D2_LagComp_OnWantsLagCompensationOnEntity",
											ET_Event,
											Param_Cell,
											Param_Cell,
											Param_CellByRef,
											Param_Cell,
											Param_Cell);
	
	RegPluginLibrary("l4d2_lagcomp_manager");
	
	return APLRes_Success;
}

any Ntv_StartLagCompensation(Handle plugin, int numParams)
{
	int player = GetNativeCell(1);
	LagCompensationType lagCompensationType = GetNativeCell(2);
	
	float weaponPos[3], weaponAngles[3];
	
	GetNativeArray(3, weaponPos, sizeof(weaponPos));
	GetNativeArray(4, weaponAngles, sizeof(weaponAngles));
	
	float weaponRange = GetNativeCell(5);
	
	if (!LagComp_StartLagCompensation(player, lagCompensationType, weaponPos, weaponAngles, weaponRange))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "CLagCompensationManager::StartLagCompensation with NULL CUserCmd!!!");
	}
	
	return 1;
}

any Ntv_FinishLagCompensation(Handle plugin, int numParams)
{
	int player = GetNativeCell(1);
	LagComp_FinishLagCompensation(player);
	return 1;
}

any Ntv_AddAdditionalEntity(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);
	LagComp_AddAdditionalEntity(entity);
	return 1;
}

any Ntv_RemoveAdditionalEntity(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);
	LagComp_RemoveAdditionalEntity(entity);
	return 1;
}

public void OnPluginStart()
{
	Handle hGameConf = LoadGameConfigFile(GAMEDATA);
	if (!hGameConf) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}
	
	g_aLagCompensation = GameConfGetAddress(hGameConf, "lagcompensation");

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CLagCompensationManager_AddAdditionalEntity");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hLagCompAddEntity = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CLagCompensationManager_RemoveAdditionalEntity");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hLagCompRemoveEntity = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CLagCompensationManager_StartLagCompensation");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	g_hStartLagComp = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CLagCompensationManager_FinishLagCompensation");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hFinishLagComp = EndPrepSDKCall();

	if (g_aLagCompensation == Address_Null || g_hLagCompAddEntity == null || g_hLagCompRemoveEntity == null || g_hStartLagComp == null || g_hFinishLagComp == null) {
		SetFailState("Failed to find LagComp addresses: 0x%08x, %08x, %08x, %08x, %08x", g_aLagCompensation, g_hLagCompAddEntity, g_hLagCompRemoveEntity, g_hStartLagComp, g_hFinishLagComp);
	}
	
	g_iCUserCmdSize = GameConfGetOffset(hGameConf, "sizeof(CUserCmd)");
	if (g_iCUserCmdSize == -1)
		SetFailState("Missing offset \"sizeof(CUserCmd)\"");
	
	DynamicDetour hDetour = DynamicDetour.FromConf(hGameConf, "CTerrorPlayer::WantsLagCompensationOnEntity");
	if (!hDetour)
		SetFailState("Missing detour setup \"CTerrorPlayer::WantsLagCompensationOnEntity\"");
	if (!hDetour.Enable(Hook_Post, DTR__CTerrorPlayer__WantsLagCompensationOnEntity_Post))
		SetFailState("Failed to detour \"CTerrorPlayer::WantsLagCompensationOnEntity\"");
	
	delete hDetour;
	
	delete hGameConf;
	
	#if DEBUG
		RegConsoleCmd("sm_show_lagcomp_list", Cmd_ShowLagCompList, "Basically this lagcomp array is always empty, so don't be surprised you won't see anything in the console");
	#endif

	g_hSvUnlag = FindConVar("sv_unlag");
	g_hSvUnlag.AddChangeHook(SvUnLag_Changed);
}

public void OnConfigsExecuted()
{
	CheckCvar();
}

public void SvUnLag_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	CheckCvar();
}

void CheckCvar()
{
	if (!g_hSvUnlag.BoolValue) {
		PrintToServer("[%s] This plugin can only work with 'sv_unlag' cvar enabled!", GAMEDATA);
		LogError("This plugin can only work with 'sv_unlag' cvar enabled!");
	}
}

MRESReturn DTR__CTerrorPlayer__WantsLagCompensationOnEntity_Post(int client, DHookReturn hReturn, DHookParam hParams)
{
	if (g_fwdWantsLagCompensationOnEntity.FunctionCount == 0)
		return MRES_Ignored;
	
	int entity = hParams.Get(1);
	bool result = hReturn.Value != 0;
	int buttons = hParams.GetObjectVar(2, 36, ObjectValueType_Int);
	int impulse = hParams.GetObjectVar(2, 40, ObjectValueType_Int) & 0x000000FF;
	
	Action ret = Plugin_Continue;
	
	Call_StartForward(g_fwdWantsLagCompensationOnEntity);
	Call_PushCell(client);
	Call_PushCell(entity);
	Call_PushCellRef(result);
	Call_PushCell(buttons);
	Call_PushCell(impulse);
	Call_Finish(ret);
	
	if (ret == Plugin_Handled)
	{
		hReturn.Value = result ? 1 : 0;
		return MRES_Override;
	}
	
	return MRES_Ignored;
}

public void OnEntityCreated(int iEntity, const char[] sClassName)
{
	if (sClassName[0] != 't') {
		return;
	}
	
	if (strcmp(sClassName, "tank_rock") == 0) {
		LagComp_AddAdditionalEntity(iEntity);
		
		#if DEBUG
			if (IsFindEntity(iEntity)) {
				PrintToChatAll("[Successfully] The entity '%s (%d)' was successfully added to the array for lag compensation!", sClassName, iEntity);
			} else {
				PrintToChatAll("[Error] Could not find the entity '%s (%d)' in the array for lag compensation!", sClassName, iEntity);
			}
		#endif
	}
}

public void OnEntityDestroyed(int iEntity)
{
	if (IsRock(iEntity)) {
		#if DEBUG
			bool IsFind = IsFindEntity(iEntity);
		#endif
		
		LagComp_RemoveAdditionalEntity(iEntity);
		
		#if DEBUG
			char sClassName[MAX_ENTITY_NAME_SIZE];
			GetEntityClassname(iEntity, sClassName, sizeof(sClassName));
			
			if (IsFind) {
				if (IsFindEntity(iEntity)) {
					PrintToChatAll("[Error] The entity '%s (%d)' is not removed after being destroyed from the array for lag compensation!", sClassName, iEntity);
				} else {
					PrintToChatAll("[Successfully] The entity '%s (%d)' was removed after being destroyed from the array for lag compensation!", sClassName, iEntity);
				}
			} else {
				PrintToChatAll("[Error] The entity '%s (%d)' has never been added to the array for lag compensation!", sClassName, iEntity);
			}
		#endif
	}
}

void LagComp_AddAdditionalEntity(int entity)
{
	SDKCall(g_hLagCompAddEntity, g_aLagCompensation, entity);
}

void LagComp_RemoveAdditionalEntity(int entity)
{
	SDKCall(g_hLagCompRemoveEntity, g_aLagCompensation, entity);
}

bool LagComp_StartLagCompensation(
	int player,
	LagCompensationType lagCompensationType,
	const float weaponPos[3] = NULL_VECTOR,
	const float weaponAngles[3] = NULL_VECTOR,
	float weaponRange = 0.0 )
{
	if (GetPlayerCurrentCommand(player) == Address_Null)
		return false;
	
	static float origin[3], angle[3];
	
	if (IsNullVector(weaponPos))
		origin = view_as<float>({0.0, 0.0, 0.0});
	else
		origin = weaponPos;
	
	if (IsNullVector(weaponAngles))
		angle = view_as<float>({0.0, 0.0, 0.0});
	else
		angle = weaponAngles;
	
	SDKCall(g_hStartLagComp, g_aLagCompensation, player, lagCompensationType, origin, angle, weaponRange);

	return true;
}

void LagComp_FinishLagCompensation(int player)
{
	SDKCall(g_hFinishLagComp, g_aLagCompensation, player);
}

Address GetPlayerCurrentCommand(int player)
{
	static int s_iOffs_m_pCurrentCommand = -1;
	if (s_iOffs_m_pCurrentCommand == -1)
		s_iOffs_m_pCurrentCommand = FindDataMapInfo(player, "m_hViewModel")
									+ 4*2 /* CHandle<CBaseViewModel> * MAX_VIEWMODELS */
									+ g_iCUserCmdSize /* m_LastCmd */;
	
	return view_as<Address>(GetEntData(player, s_iOffs_m_pCurrentCommand, 4));
}

bool IsRock(int iEntity)
{
	if (IsValidEntity(iEntity)) {
		char sClassName[MAX_ENTITY_NAME_SIZE];
		GetEntityClassname(iEntity, sClassName, sizeof(sClassName));
		return (strcmp(sClassName, "tank_rock") == 0);
	}

	return false;
}

#if DEBUG
bool IsFindEntity(int iEntity)
{
	int iFindEntity = 0;
	if (LagComp_FindEntity(iEntity, iFindEntity)) {
		return (iFindEntity != 0 && iFindEntity == iEntity);
	}
	
	return false;
}

/**
 * @brief Displays in the server console all entities that are in the array for the lag compensation
 * @remarks Basically this lagcomp array is always empty, so don't be surprised you won't see anything in the console
 * @remarks This works, for example, for melee weapons or for the boomer's ability, at this moment, entities should appear in this array
 */
public Action Cmd_ShowLagCompList(int client, int args)
{
	ReplyToCommand(client, "[%s] The lagcomp array should have been printed to the server console!", GAMEDATA);
	LagComp_ShowAllEntities();
	return Plugin_Handled;
}
#endif
