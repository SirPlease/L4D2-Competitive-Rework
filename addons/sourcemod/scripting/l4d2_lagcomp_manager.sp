#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "L4D2 Lag Compensation Manager",
	author = "ProdigySim",
	description = "Provides lag compensation for stuff in left four dead two",
	version = "One",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

Address g_lagcompensation = Address_Null;
Handle g_hLagCompAddEntity = null;
Handle g_hLagCompRemoveEntity = null;

public void OnPluginStart()
{
	Handle hGameConf = LoadGameConfigFile("l4d2_lagcomp_manager");

	g_lagcompensation = GameConfGetAddress(hGameConf, "lagcompensation");
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CLagCompensationManager_AddAdditionaEntity");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hLagCompAddEntity = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CLagCompensationManager_RemoveAdditionaEntity");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hLagCompRemoveEntity = EndPrepSDKCall();
	if (g_lagcompensation == Address_Null || g_hLagCompAddEntity == null || g_hLagCompRemoveEntity == null) {
		SetFailState("Failed to find LagComp addresses: 0x%08x, %08x, %08x", g_lagcompensation, g_hLagCompAddEntity, g_hLagCompRemoveEntity);
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "tank_rock")) {
		SDKCall(g_hLagCompAddEntity, g_lagcompensation, entity);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (IsRock(entity)) {
		SDKCall(g_hLagCompRemoveEntity, g_lagcompensation, entity);
	}
}

public bool IsRock(int entity)
{
    if (IsValidEntity(entity)) {
        new String:classname[32];
        GetEntityClassname(entity, classname, 32);
        return StrEqual(classname, "tank_rock");
    }
    return false;
}
