#include <colors>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)

const TANK_ZOMBIE_CLASS = 8;

bool bTankAlive;
bool bHooked;
int iDistance;
ConVar cvar_noTankRush;
ConVar cvar_unfreezeSaferoom;

public Plugin myinfo = {
    name = "L4D2 No Tank Rush",
    author = "Jahze, vintik, devilesk, Sir",
    version = "1.1.4",
    description = "Stops distance points accumulating whilst the tank is alive, with the option of unfreezing distance on reaching the Saferoom"
};

public void OnPluginStart() 
{
    // ConVars
    cvar_noTankRush = CreateConVar("l4d_no_tank_rush", "1", "Prevents survivor team from accumulating points whilst the tank is alive");
    cvar_unfreezeSaferoom = CreateConVar("l4d_no_tank_rush_unfreeze_saferoom", "0", "Unfreezes Distance if a Survivor makes it to the end saferoom while the Tank is still up.");

    // ChangeHook
    cvar_noTankRush.AddChangeHook(NoTankRushChange);

    if (GetConVarBool(cvar_noTankRush)) 
    {
        PluginEnable();
    }
}

public void OnPluginEnd() 
{
    bHooked = false;
    PluginDisable();
}

public void OnMapStart() 
{
    bTankAlive = false;
}

void PluginEnable() 
{
    if ( !bHooked ) 
    {
        HookEvent("round_start", RoundStart);
        HookEvent("tank_spawn", TankSpawn);
        HookEvent("player_death", PlayerDeath);
        
        if (FindTank() > 0) 
        {
            FreezePoints();
        }
        bHooked = true;
    }
}

public Action L4D2_OnEndVersusModeRound(bool countSurvivors)
{
    if (cvar_unfreezeSaferoom.IntValue == 1 && FindTank() != -1 && GetUprightSurvivors() > 0) 
    {
        UnFreezePoints(true, 2);
    }
}

void PluginDisable() 
{
    if (bHooked)
    {
        UnhookEvent("round_start", RoundStart);
        UnhookEvent("tank_spawn", TankSpawn);
        UnhookEvent("player_death", PlayerDeath);
        
        bHooked = false;
    }
    UnFreezePoints();
}

void NoTankRushChange(ConVar convar, const char[] oldValue, const char[] newValue) 
{
    if (StringToInt(newValue) == 0) 
    {
        PluginDisable();
    }
    else 
    {
        PluginEnable();
    }
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
    if (InSecondHalfOfRound()) 
    {
        UnFreezePoints();
    }
}

public Action TankSpawn(Event event, const char[] name, bool dontBroadcast) 
{
    FreezePoints(true);
}

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IS_VALID_CLIENT(client) && IsTank(client)) 
    {
        CreateTimer(0.1, CheckForTanksDelay, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public void OnClientDisconnect(int client) 
{
    if (IS_VALID_CLIENT(client) && IsTank(client) ) 
    {
        CreateTimer(0.1, CheckForTanksDelay, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action CheckForTanksDelay(Handle timer) 
{
    if (FindTank() == -1) 
    {
        UnFreezePoints(true);
    }
}

void FreezePoints(bool show_message = false) 
{
    if (!bTankAlive) 
    {
        iDistance = L4D_GetVersusMaxCompletionScore();
        if (show_message) CPrintToChatAll("{red}[{default}NoTankRush{red}] {red}Tank {default}spawned. {olive}Freezing {default}distance points!");
        L4D_SetVersusMaxCompletionScore(0);
        bTankAlive = true;
    }
}

void UnFreezePoints(bool show_message = false, int iMessage = 1) 
{
    if (bTankAlive) 
    {
        if (show_message) 
        {
            if (iMessage == 1) CPrintToChatAll("{red}[{default}NoTankRush{red}] {red}Tank {default}is dead. {olive}Unfreezing {default}distance points!");
            else CPrintToChatAll("{red}[{default}NoTankRush{red}] {red}Survivors {default}made it to the saferoom. {olive}Unfreezing {default}distance points!");
        }
        L4D_SetVersusMaxCompletionScore(iDistance);
        bTankAlive = false;
    }
}

int FindTank() {
    for (int i = 1; i <= MaxClients; i++) 
    {
        if (IsTank(i) && IsPlayerAlive(i)) 
        {
            return i;
        }
    }
    
    return -1;
}

int GetUprightSurvivors()
{
    int aliveCount;
    int survivorCount;
    int iTeamSize = GetConVarInt(FindConVar("survivor_limit"));
    for (int i = 1; i <= MaxClients && survivorCount < iTeamSize; i++)
    {
        if (IsSurvivor(i))
        {
            survivorCount++;
            if (IsPlayerAlive(i) && !IsPlayerIncap(i) && !IsPlayerLedged(i))
            {
                aliveCount++;
            }
        }
    }
    return aliveCount;
}

bool IsPlayerIncap(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isIncapacitated") ? true : false);
}

bool IsPlayerLedged(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}