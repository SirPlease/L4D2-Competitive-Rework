#include <sourcemod>
#include <sdktools>

static Handle:hFwdOnTankPunchHittable;
static Handle:hFwdOnTankSpawn;
static Handle:hFwdOnTankPass;
static Handle:hFwdOnTankDeath;

static Handle:hTankClients;

static AddTankToArray(client) {
    PushArrayCell(hTankClients, client);
}

static RemoveTankFromArray(client) {
    for (new i = 0; i < GetArraySize(hTankClients); ++i) {
        if (GetArrayCell(hTankClients, i) == client) {
            RemoveFromArray(hTankClients, i);
        }
    }
}

static bool:FindTankInArray(client) {
    for (new i = 0; i < GetArraySize(hTankClients); ++i) {
        if (GetArrayCell(hTankClients, i) == client) {
            return true;
        }       
    }
    
    return false;
}

L4D2Util_Tanks_Init() {
    hTankClients = CreateArray();
}

L4D2Util_Tanks_OnRoundStart() {
    ClearArray(hTankClients);
    CreateTimer(0.1, L4D2Util_Tanks_HookProps);
}

public Action:L4D2Util_Tanks_HookProps(Handle:hTimer) {
     new iEntity = -1;
     
     while ((iEntity = FindEntityByClassname(iEntity, "prop_physics")) != -1) {
         if (IsTankHittable(iEntity)) {
             HookSingleEntityOutput(iEntity, "OnHitByTank", TankHittablePunched);
         }
     }
     
     iEntity = -1;
     
     while ((iEntity = FindEntityByClassname(iEntity, "prop_alarm_car")) != -1) {
         HookSingleEntityOutput(iEntity, "OnHitByTank", TankHittablePunched);
     }
}

public TankHittablePunched(const String:output[], caller, activator, Float:delay) {
    Call_StartForward(hFwdOnTankPunchHittable);
    Call_PushCell(activator);
    Call_PushCell(caller);
    Call_Finish();
}

// The tank_spawn hook is called when the tanks spawns(!), but also when the
// tank passes from AI to a player or from a player to AI.
L4D2Util_Tanks_TankSpawn(client) {
    new iNumTanks = NumTanksInPlay();
    
    if (GetArraySize(hTankClients) < iNumTanks) {
        AddTankToArray(client);
        Call_StartForward(hFwdOnTankSpawn);
        Call_PushCell(client);
        Call_Finish();
    }
}

L4D2Util_Tanks_PlayerDeath(client) {
    if (client == 0) {
        return;
    }
    
    if (!IsTank(client)) {
        return;
    }
    
    CreateTimer(0.1, L4D2Util_Tanks_TankDeathDelay, client);
}

public Action:L4D2Util_Tanks_TankDeathDelay(Handle:hTimer, any:iOldTankClient) {
    new iTankClient = -1;
    new client = -1;
    
    while ((client = FindTankClient(client)) != -1) {
        if (!FindTankInArray(client)) {
            iTankClient = client;
            break;
        }
    }
    
    RemoveTankFromArray(iOldTankClient);
    
    if (iTankClient != -1) {
        AddTankToArray(client);
        Call_StartForward(hFwdOnTankPass);
        Call_PushCell(iTankClient);
        Call_PushCell(iOldTankClient);
        Call_Finish();
        return;
    }
    
    Call_StartForward(hFwdOnTankDeath);
    Call_PushCell(iOldTankClient);
    Call_Finish();
}

L4D2Util_Tanks_CreateForwards() {
    hFwdOnTankPunchHittable = CreateGlobalForward("OnTankPunchHittable", ET_Ignore, Param_Cell, Param_Cell);
    hFwdOnTankSpawn = CreateGlobalForward("OnTankSpawn", ET_Ignore, Param_Cell);
    hFwdOnTankPass = CreateGlobalForward("OnTankPass", ET_Ignore, Param_Cell, Param_Cell);
    hFwdOnTankDeath = CreateGlobalForward("OnTankDeath", ET_Ignore, Param_Cell);
}
