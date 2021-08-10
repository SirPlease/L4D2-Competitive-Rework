#pragma semicolon 1
#pragma newdecls required

#define DEBUG 0

#include <sourcemod>
#include <sdktools>

#if DEBUG
// 'l4d2_lagcompmanager_test' extension is required for debugging
// https://github.com/A1mDev/L4D2-LagCompensation-Manager
#include <l4d2_lagcompmanager_test>
#endif

#define GAMEDATA "l4d2_lagcomp_manager"

#define MAX_ENTITY_NAME_SIZE 64

ConVar
	g_hSvUnlag = null;

Address
	g_aLagCompensation = Address_Null;

Handle
	g_hLagCompAddEntity = null,
	g_hLagCompRemoveEntity = null;

public Plugin myinfo =
{
	name = "L4D2 Lag Compensation Manager",
	author = "ProdigySim, A1m`",
	description = "Provides lag compensation for entities in left 4 dead 2 (required enable sv_unlag).",
	version = "1.1.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

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

	if (g_aLagCompensation == Address_Null || g_hLagCompAddEntity == null || g_hLagCompRemoveEntity == null) {
		SetFailState("Failed to find LagComp addresses: 0x%08x, %08x, %08x", g_aLagCompensation, g_hLagCompAddEntity, g_hLagCompRemoveEntity);
	}
	
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

public void OnEntityCreated(int iEntity, const char[] sClassName)
{
	if (sClassName[0] != 't') {
		return;
	}
	
	if (strcmp(sClassName, "tank_rock") == 0) {
		SDKCall(g_hLagCompAddEntity, g_aLagCompensation, iEntity);
		
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
		
		SDKCall(g_hLagCompRemoveEntity, g_aLagCompensation, iEntity);
		
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
