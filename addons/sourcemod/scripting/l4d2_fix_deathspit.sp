#pragma semicolon 1

#include <sourcemod>
#include <left4dhooks>
#include <sdktools>

public Plugin:myinfo = {
    name = "L4D2 Fix Death Spit",
    author = "Jahze",
    description = "Removes invisible death spit",
    version = "1.0",
    url = "https://github.com/Jahze/l4d2_plugins"
}
public OnPluginStart() {
    HookEvent("spitter_killed", SpitterKilledEvent, EventHookMode_PostNoCopy);
}

public SpitterKilledEvent(Handle:event, const String:name[], bool:dontBroadcast) {
    CreateTimer(1.0, FindDeathSpit);
}

public Action:FindDeathSpit(Handle:timer) {
    new entity = -1;

    while ((entity = FindEntityByClassname(entity, "insect_swarm")) != -1) {
        new maxFlames = L4D2Direct_GetInfernoMaxFlames(entity);
        new currentFlames = GetEntProp(entity, Prop_Send, "m_fireCount");

        if (maxFlames == 2 && currentFlames == 2) {
            SetEntProp(entity, Prop_Send, "m_fireCount", 1);
            L4D2Direct_SetInfernoMaxFlames(entity, 1);
        }
    }
}

