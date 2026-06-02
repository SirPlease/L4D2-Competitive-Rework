#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
    name = "Common Ragdolls be gone",
    author = "Sir",
    description = "Make ragdolls for common infected vanish into thin air server-side on death.",
    version = "1.1",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

Action Event_PlayerDeath(Event hEvent, char[] name, bool dontBroadcast)
{
    int victimuserid = hEvent.GetInt("userid");

    if (victimuserid < 1) {
        int victimentityid = hEvent.GetInt("entityid");

        if (IsCommonInfected(victimentityid)) {
            RemoveEntity(victimentityid);
        }
    }
    
    return Plugin_Continue;
}

bool IsCommonInfected(int iEntity)
{
	if (iEntity <= MaxClients || !IsValidEdict(iEntity)) {
		return false;
	}

	char sClassName[64];
	GetEdictClassname(iEntity, sClassName, sizeof(sClassName));
	return (strcmp(sClassName, "infected") == 0);
}
