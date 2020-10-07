#pragma semicolon 1

#define L4D2UTIL_STOCKS_ONLY

#include <sourcemod>
#include <sdktools>
#include <l4d2util>

new Float:fLedgeHangInterval;
new Handle:hCvarJockeyLedgeHang;

public Plugin:myinfo = {
    name = "L4D2 Jockey Ledge Hang Recharge",
    author = "Jahze",
    version = "1.0",
    description = "Adds a cvar to adjust the recharge timer of a jockey after he ledge hangs a survivor."
};

public OnPluginStart() {
    hCvarJockeyLedgeHang = CreateConVar("z_leap_interval_post_ledge_hang", "10", "How long before a jockey can leap again after a ledge hang");
    HookConVarChange(hCvarJockeyLedgeHang, JockeyLedgeHangChange);
    
    fLedgeHangInterval = GetConVarFloat(hCvarJockeyLedgeHang);
    
    PluginEnable();
}

PluginEnable() {
    HookEvent("jockey_ride_end", JockeyRideEnd);
}

public JockeyLedgeHangChange(Handle:hCvar, const String:oldValue[], const String:newValue[]) {
    fLedgeHangInterval = StringToFloat(newValue);
}

public Action:JockeyRideEnd(Handle:hEvent, const String:name[], bool:bDontBroadcast) {
    new jockeyAttacker = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    new jockeyVictim = GetClientOfUserId(GetEventInt(hEvent, "victim"));
    
    if (IsHangingFromLedge(jockeyVictim)) {
        FixupJockeyTimer(jockeyAttacker);
    }
}

FixupJockeyTimer(client) {
    new iEntity = -1;
    
    while ((iEntity = FindEntityByClassname(iEntity, "ability_leap")) != -1) {
        if (GetEntPropEnt(iEntity, Prop_Send, "m_owner") == client) {
            break;
        }
    }
    
    if (iEntity == -1) {
        return;
    }
    
    SetEntPropFloat(iEntity, Prop_Send, "m_timestamp", GetGameTime() + fLedgeHangInterval);
    SetEntPropFloat(iEntity, Prop_Send, "m_duration", fLedgeHangInterval);
}

