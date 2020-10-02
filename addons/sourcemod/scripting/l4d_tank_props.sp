#pragma newdecls required

/******************************************************************
*
* v1.0 & v1.1 by Jahze.
* ------------------------
* ------- Details: -------
* ------------------------
* > Prevents Tank hittables from dissapearing while the Tank is alive.
* > Tank hittables are hooked, when punched they are put in an array and these entities will be killed briefly after the Tank dies.
*
* v1.2 by Sir
* ------------------------
* ------- Details: -------
* ------------------------
* > Updated the code to new Syntax.
* > Added a workaround for Hittables that were "created" while the Tank is alive, thus not being hooked. (DHook Entity listener)
*
******************************************************************/

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>

#define TANK_ZOMBIE_CLASS   8

bool tankSpawned;

int iTankClient = -1;

ConVar cvar_tankProps;
ConVar sv_tankpropfade;
Handle hTankProps;
Handle hTankPropsHit;

public Plugin myinfo = {
    name        = "L4D2 Tank Props",
    author      = "Jahze, Sir",
    version     = "1.2",
    description = "Stop tank props from fading whilst the tank is alive"
};

public void OnPluginStart() 
{
    sv_tankpropfade = FindConVar("sv_tankpropfade");
    cvar_tankProps = CreateConVar("l4d_tank_props", "1", "Prevent tank props from fading whilst the tank is alive");
    cvar_tankProps.AddChangeHook(TankPropsChange);
    
    PluginEnable();
}

void PluginEnable() 
{
    sv_tankpropfade.BoolValue = false;
    
    hTankProps = CreateArray();
    hTankPropsHit = CreateArray();
    
    HookEvent("round_start", TankPropRoundReset);
    HookEvent("round_end", TankPropRoundReset);
    HookEvent("tank_spawn", TankPropTankSpawn);
    HookEvent("player_death", TankPropTankKilled);
}

void PluginDisable() 
{
    sv_tankpropfade.BoolValue = true;
    
    CloseHandle(hTankProps);
    CloseHandle(hTankPropsHit);
    
    UnhookEvent("round_start", TankPropRoundReset);
    UnhookEvent("round_end", TankPropRoundReset);
    UnhookEvent("tank_spawn", TankPropTankSpawn);
    UnhookEvent("player_death", TankPropTankKilled);
}

public void TankPropsChange(Handle convar, const char[] oldValue, const char[] newValue)
{
    if (StringToInt(newValue) == 0)
      PluginDisable();

    else PluginEnable();
}

public void TankPropRoundReset(Event event, const char[] name, bool dontBroadcast) 
{
    tankSpawned = false;
    
    UnhookTankProps();
    ClearArray(hTankPropsHit);
}

public void TankPropTankSpawn(Event event, const char[] name, bool dontBroadcast) 
{
    if (!tankSpawned) 
    {
        UnhookTankProps();
        ClearArray(hTankPropsHit);
        
        // For already spawned hittables.
        HookTankProps();

        // Hittables that spawn while the Tank is live, rather on having OnEntityCreated running all the time, we'll only use this hook while the Tank is alive.
        DHookAddEntityListener(ListenType_Created, PossibleTankPropCreated);
        
        tankSpawned = true;
    }    
}

public void TankPropTankKilled(Event event, const char[] name, bool dontBroadcast)
{
    if (!tankSpawned) 
      return;
    
    int client = GetClientOfUserId(event.GetInt("userid"));
    if ( client != iTankClient) 
      return;
    
    CreateTimer(0.1, TankDeadCheck);
}

public Action TankDeadCheck(Handle timer) 
{
    if (GetTankClient() == -1 ) 
    {
        UnhookTankProps();
        CreateTimer(5.0, FadeTankProps);
        tankSpawned = false;
    }
}

public void PropDamaged(int victim, int attacker, int inflictor, float damage, int damageType) 
{
    if (attacker == GetTankClient() || FindValueInArray(hTankPropsHit, inflictor) != -1 ) 
    {
        if (FindValueInArray(hTankPropsHit, victim) == -1)
          PushArrayCell(hTankPropsHit, victim);
    }
}

public Action FadeTankProps(Handle timer) 
{
    for (int i = 0; i < GetArraySize(hTankPropsHit); i++) 
    {
        if (IsValidEdict(GetArrayCell(hTankPropsHit, i))) 
          RemoveEdict(GetArrayCell(hTankPropsHit, i));
    }
    
    ClearArray(hTankPropsHit);
}

bool IsTankProp(int iEntity) 
{
    if (!IsValidEdict(iEntity))
      return false;
    
    char className[64];
    
    GetEdictClassname(iEntity, className, sizeof(className));
    if (StrEqual(className, "prop_physics")) 
    {
        if (GetEntProp(iEntity, Prop_Send, "m_hasTankGlow", 1)) 
          return true;
    }

    else if (StrEqual(className, "prop_car_alarm"))
      return true;

    return false;
}

void HookTankProps() 
{
    int iEntCount = GetMaxEntities();
    
    for (int i = 1; i <= iEntCount; i++) 
    {
        if (IsTankProp(i)) 
        {
            SDKHook(i, SDKHook_OnTakeDamagePost, PropDamaged);
            PushArrayCell(hTankProps, i);
        }
    }
}

public void PossibleTankPropCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "prop_physics")) // Hooks onto c2m2_fairgrounds Forklift, c11m4_terminal World Sphere and Custom Campaign hittables.
    {
        // Use SpawnPost to just push it into the Array right away.
        // These entities get spawned after the Tank has punched them, so doing anything here will not work smoothly.
        SDKHook(entity, SDKHook_SpawnPost, PropSpawned);
    }
}

void PropSpawned(int entity)
{
    if (IsValidEntity(entity) && 
    GetEntProp(entity, Prop_Send, "m_hasTankGlow", 1)) // Just to be safe.
    {
        if (FindValueInArray(hTankPropsHit, entity) == -1)
          PushArrayCell(hTankPropsHit, entity);
    }
}

void UnhookTankProps() 
{
    for (int i = 0; i < GetArraySize(hTankProps); i++) 
    {
        SDKUnhook(GetArrayCell(hTankProps, i), SDKHook_OnTakeDamagePost, PropDamaged);
    }
    
    // Don't forget to remove the Hook.
    DHookRemoveEntityListener(ListenType_Created, PossibleTankPropCreated);
    ClearArray(hTankProps);
}

int GetTankClient() 
{
    if (iTankClient == -1 || !IsTank(iTankClient)) 
      iTankClient = FindTank();
    
    return iTankClient;
}

int FindTank() 
{
    for (int i = 1; i <= MaxClients; i++) 
    {
        if (IsTank(i)) 
          return i;
    }
    
    return -1;
}

bool IsTank(int client) 
{
    if (client < 0
    || !IsClientConnected(client)
    || !IsClientInGame(client)
    || GetClientTeam(client) != 3
    || !IsPlayerAlive(client))
      return false;
    
    int playerClass = GetEntProp(client, Prop_Send, "m_zombieClass");
    
    if (playerClass == TANK_ZOMBIE_CLASS)
      return true;
    
    return false;
}