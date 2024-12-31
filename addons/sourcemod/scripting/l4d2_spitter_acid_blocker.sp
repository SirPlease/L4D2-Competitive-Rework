#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define L4D2_TEAM_INFECTED 3

bool g_bBlocked[MAXPLAYERS + 1];

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
    HookEvent("player_death", PlayerDeath_Event, EventHookMode_Post);
}

public void L4D_OnEnterGhostState(int client)
{
    g_bBlocked[client] = false;
}

public void L4D_OnSpawnSpecial_Post(int client, int zombieClass, const float vecPos[3], const float vecAng[3])
{
    g_bBlocked[client] = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "insect_swarm"))
        SDKHook(entity, SDKHook_SpawnPost, SDK_OnSpawnPost);
}

void SDK_OnSpawnPost(int entity)
{
    int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
    if (owner < 1 || owner > MaxClients || !g_bBlocked[owner])
        return;

    AcceptEntityInput(entity, "Kill");
    g_bBlocked[owner] = false;
}

void PlayerDeath_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int type = GetEventInt(event, "type");

    // I don't know why 6144, but it works    
    if (type == 0 || type == 6144)
        g_bBlocked[client] = true;
}