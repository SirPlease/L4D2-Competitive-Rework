#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo = {

    name = "Common Ragdolls be gone",
    author = "Sir",
    description = "Make ragdolls for common infected vanish into thin air server-side on death.",
    version = "1.0",
    url = "Nah"
};

public void OnPluginStart() {
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Action Event_PlayerDeath(Event hEvent, char[] name, bool dontBroadcast) {

    int victimuserid = hEvent.GetInt("userid");

    if(!victimuserid) {

        int victimentityid = hEvent.GetInt("entityid");

        if (IsCommonInfected(victimentityid)) {
            RemoveEntity(victimentityid);
        }
    }
    
    return Plugin_Continue;
}

bool IsCommonInfected(int iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        char strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "infected");
    }
    return false;
} 