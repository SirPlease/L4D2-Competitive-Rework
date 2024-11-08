#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define L4D2_TEAM_INFECTED 3

bool g_bBlocked[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name        = "L4D2 - Spitter Spec Acid Blocker",
    author      = "Altair Sossai",
    description = "Prevents Spitter acid from causing damage if the player switches to spectator mode before dying",
    version     = "1.0.0",
    url         = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
    AddCommandListener(Spectate_Callback, "sm_spectate");
    AddCommandListener(Spectate_Callback, "sm_spec");
    AddCommandListener(Spectate_Callback, "sm_s");
    AddCommandListener(JoinTeam_Callback, "jointeam");

    HookEvent("player_team", PlayerTeam_Event, EventHookMode_Post);
}

public void L4D_OnEnterGhostState(int client)
{
    g_bBlocked[client] = false;
}

Action Spectate_Callback(int client, char[] command, int args)
{
    g_bBlocked[client] = true;

    return Plugin_Continue; 
}

Action JoinTeam_Callback(int client, char[] command, int args)
{
    if (args == 0)
        return Plugin_Continue;

    int team = GetClientTeam(client);
    if (team != L4D2_TEAM_INFECTED)
        return Plugin_Continue;

    char buffer[128];
    GetCmdArg(1, buffer, sizeof(buffer));

    int newTeam = StringToInt(buffer);
    if (newTeam == L4D2_TEAM_INFECTED)
        return Plugin_Continue;

    g_bBlocked[client] = true;

    return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "insect_swarm"))
        SDKHook(entity, SDKHook_SpawnPost, SDK_OnSpawnPost);
}

void SDK_OnSpawnPost(int entity)
{
    int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
    if (owner < 1 || owner > MaxClients)
        return;

    if (g_bBlocked[owner])
        AcceptEntityInput(entity, "Kill");
}

void PlayerTeam_Event(Event event, const char[] name, bool dontBroadcast)
{
    if (GetEventInt(event, "team") != L4D2_TEAM_INFECTED)
        return;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    g_bBlocked[client] = false;
}