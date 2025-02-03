#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define L4D2_TEAM_INFECTED 3

public Plugin myinfo =
{
    name        = "L4D2 - Spitter Acid Blocker",
    author      = "Altair Sossai",
    description = "Prevents Spitter acid damage if the player controlling the Spitter enters spectator mode or switches teams before dying",
    version     = "1.0.0",
    url         = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
    HookEvent("player_team", PlayerTeam_Event, EventHookMode_Post);
}

void PlayerTeam_Event(Event event, const char[] name, bool dontBroadcast)
{
    int oldTeam = GetEventInt(event, "oldteam");
    if (oldTeam != L4D2_TEAM_INFECTED)
        return;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int entity = -1;

    while((entity = FindEntityByClassname(entity, "insect_swarm")) != INVALID_ENT_REFERENCE)
    {
        if(GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") != client)
            continue;

        AcceptEntityInput(entity, "Kill");
    }
}