#pragma semicolon 1

#include <sourcemod>
#include <left4dhooks>
#include <colors>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)

const TANK_ZOMBIE_CLASS = 8;

new bool:bTankAlive = false;
new bool:bHooked = false;

new iDistance;

new Handle:cvar_noTankRush;

public Plugin:myinfo = {
    name = "L4D2 No Tank Rush",
    author = "Jahze, vintik, devilesk",
    version = "1.1.3",
    description = "Stops distance points accumulating whilst the tank is alive"
};

public OnPluginStart() {
    cvar_noTankRush = CreateConVar("l4d_no_tank_rush", "1", "Prevents survivor team from accumulating points whilst the tank is alive");
    HookConVarChange(cvar_noTankRush, NoTankRushChange);
    if (GetConVarBool(cvar_noTankRush)) {
        PluginEnable();
    }
}

public OnPluginEnd() {
    bHooked = false;
    PluginDisable();
}

public OnMapStart() {
    bTankAlive = false;
}

PluginEnable() {
    if ( !bHooked ) {
        HookEvent("round_start", RoundStart);
        HookEvent("tank_spawn", TankSpawn);
        HookEvent("player_death", PlayerDeath);
        
        if ( FindTank() > 0 ) {
            FreezePoints();
        }
        bHooked = true;
    }
}

PluginDisable() {
    if ( bHooked ) {
        UnhookEvent("round_start", RoundStart);
        UnhookEvent("tank_spawn", TankSpawn);
        UnhookEvent("player_death", PlayerDeath);
        
        bHooked = false;
    }
    UnFreezePoints();
}

public NoTankRushChange( Handle:cvar, const String:oldValue[], const String:newValue[] ) {
    if ( StringToInt(newValue) == 0 ) {
        PluginDisable();
    }
    else {
        PluginEnable();
    }
}

public Action:RoundStart( Handle:event, const String:name[], bool:dontBroadcast ) {
    if ( InSecondHalfOfRound() ) {
        UnFreezePoints();
    }
}

public Action:TankSpawn( Handle:event, const String:name[], bool:dontBroadcast ) {
    FreezePoints(true);
}

public Action:PlayerDeath( Handle:event, const String:name[], bool:dontBroadcast ) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if ( IS_VALID_CLIENT(client) && IsTank(client) ) {
        CreateTimer(0.1, CheckForTanksDelay, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public OnClientDisconnect( client ) {
    if ( IS_VALID_CLIENT(client) && IsTank(client) ) {
        CreateTimer(0.1, CheckForTanksDelay, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action:CheckForTanksDelay( Handle:timer ) {
    if ( FindTank() == -1 ) {
        UnFreezePoints(true);
    }
}

FreezePoints( bool:show_message = false ) {
    if ( !bTankAlive ) {
        iDistance = L4D_GetVersusMaxCompletionScore();
        if ( show_message ) CPrintToChatAll("{red}[{default}NoTankRush{red}] {red}Tank {default}spawned. {olive}Freezing {default}distance points!");
        L4D_SetVersusMaxCompletionScore(0);
        bTankAlive = true;
    }
}

UnFreezePoints( bool:show_message = false ) {
    if ( bTankAlive ) {
        if ( show_message ) CPrintToChatAll("{red}[{default}NoTankRush{red}] {red}Tank {default}is dead. {olive}Unfreezing {default}distance points!");
        L4D_SetVersusMaxCompletionScore(iDistance);
        bTankAlive = false;
    }
}

FindTank() {
    for ( new i = 1; i <= MaxClients; i++ ) {
        if ( IsTank(i) && IsPlayerAlive(i) ) {
            return i;
        }
    }
    
    return -1;
}