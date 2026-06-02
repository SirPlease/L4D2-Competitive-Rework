#include <sourcemod>
#include <dhooks>
#pragma semicolon 1
#pragma newdecls required

DynamicHook g_hWeapon_ShootPosition;
Handle g_hWeapon_ShootPosition_SDKCall;
float g_vecOldWeaponShootPos[MAXPLAYERS + 1][3];
bool g_bCallingWeapon_ShootPosition;
EngineVersion g_EngineVersion;

public Plugin myinfo =
{
    name = "Bullet position fix",
    author = "xutaxkamay", /* With some slight changes based on reports/suggestions by Krevik/HarryPotter from the same Alliedmodders thread */
    description = "Fixes shoot position",
    version = "1.0.3",
    url = "https://forums.alliedmods.net/showthread.php?p=2646571"
};

public void OnPluginStart()
{
    GameData gameData = new GameData("firebulletsfix.games");
    g_EngineVersion = GetEngineVersion();

    if (!gameData)
        SetFailState("[FireBullets Fix] No game data present");

    int offset = gameData.GetOffset("Weapon_ShootPosition");

    if (offset == -1)
        SetFailState("[FireBullets Fix] failed to find offset");

    LogMessage("Found offset for Weapon_ShootPosition %d", offset);


    StartPrepSDKCall(SDKCall_Player);

    if (!PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "Weapon_ShootPosition"))
        SetFailState("[FireBullets Fix] couldn't read config for preparing Weapon_ShootPosition SDKCall");

    PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
    g_hWeapon_ShootPosition_SDKCall = EndPrepSDKCall();

    if (g_hWeapon_ShootPosition_SDKCall == INVALID_HANDLE)
        SetFailState("[FireBullets Fix] couldn't prepare Weapon_ShootPosition SDKCall");

    g_hWeapon_ShootPosition = new DynamicHook(offset, HookType_Entity, ReturnType_Vector, ThisPointer_CBaseEntity);

    if (!g_hWeapon_ShootPosition)
        SetFailState("[FireBullets Fix] couldn't hook Weapon_ShootPosition");

    delete gameData;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
            OnClientPutInServer(i);
    }
}

public void OnClientPutInServer(int client)
{
    if (!IsFakeClient(client))
        g_hWeapon_ShootPosition.HookEntity(Hook_Post, client, Weapon_ShootPosition_Post);
}

public Action OnPlayerRunCmd(int client)
{
    if (IsPlayerAlive(client) && !IsFakeClient(client))
    {
        g_bCallingWeapon_ShootPosition = true;
        SDKCall(g_hWeapon_ShootPosition_SDKCall, client, g_vecOldWeaponShootPos[client]);
        g_bCallingWeapon_ShootPosition = false;
    }
    return Plugin_Continue;
}

public MRESReturn Weapon_ShootPosition_Post(int client, DHookReturn hReturn)
{
    if (!g_bCallingWeapon_ShootPosition)
    {
        switch(g_EngineVersion)
        {
            // Only care about Survivors in Left 4 Dead series due to issues with props hit by Tanks.
            case Engine_Left4Dead, Engine_Left4Dead2:
            {
                if (GetClientTeam(client) != 2)
                    return MRES_Ignored;
            }
            default: { /* Nothing? */ }
        }
        #if defined DEBUG
        float g_vecWeaponShootPos[3];
        hReturn.GetVector(g_vecWeaponShootPos);
        PrintToConsoleAll("[FireBullets Fix] Old Weapon_ShootPosition: %.2f, %.2f, %.2f", g_vecOldWeaponShootPos[client][0], g_vecOldWeaponShootPos[client][1], g_vecOldWeaponShootPos[client][2]);
        PrintToConsoleAll("[FireBullets Fix] New Weapon_ShootPosition: %.2f, %.2f, %.2f", g_vecWeaponShootPos[0], g_vecWeaponShootPos[1], g_vecWeaponShootPos[2]);
        #endif
        hReturn.SetVector(g_vecOldWeaponShootPos[client]);
        return MRES_Supercede;
    }
    return MRES_Ignored;
}