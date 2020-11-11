#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

#define BOOMER_ZOMBIE_CLASS     2
#define SPITTER_ZOMBIE_CLASS    4

new bool:bLateLoad;
new Handle:cvar_bashKills;

public Plugin:myinfo =
{
    name        = "L4D2 Bash Kills",
    author      = "Jahze",
    version     = "1.0",
    description = "Stop special infected getting bashed to death"
}

public APLRes:AskPluginLoad2( Handle:plugin, bool:late, String:error[], errMax) {
    bLateLoad = late;
    return APLRes_Success;
}

public OnPluginStart() {
    cvar_bashKills = CreateConVar("l4d_no_bash_kills", "1", "Prevent special infected from getting bashed to death", FCVAR_NONE);
    
    if ( bLateLoad ) {
        for ( new i = 1; i < MaxClients+1; i++ ) {
            if ( IsClientInGame(i) ) {
                SDKHook(i, SDKHook_OnTakeDamage, Hurt);
            }
        }
    }
}

public OnClientPutInServer( client ) {
    SDKHook(client, SDKHook_OnTakeDamage, Hurt);
}

public Action:Hurt( victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3] ) {
    if ( !GetConVarBool(cvar_bashKills) || !IsSI(victim) ) {
        return Plugin_Continue;
    }
    
    if ( damage == 250.0 && damageType == 128 && weapon == -1 && IsSurvivor(attacker) ) {
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

bool:IsSI( client ) {
    if ( GetClientTeam(client) != 3 || !IsPlayerAlive(client) ) {
        return false;
    }
    
    // Allow boomer and spitter m2 kills
    new playerClass = GetEntProp(client, Prop_Send, "m_zombieClass");
    
    if ( playerClass == BOOMER_ZOMBIE_CLASS || playerClass == SPITTER_ZOMBIE_CLASS ) {
        return false;
    }
    
    return true;
}

bool:IsSurvivor( client ) {
    if ( client < 1
    || !IsClientConnected(client)
    || !IsClientInGame(client)
    || GetClientTeam(client) != 2
    || !IsPlayerAlive(client) ) {
        return false;
    }
    
    return true;
}
