#pragma semicolon 1

#include <sourcemod>
#include <left4dhooks>

new bool:blockStumble = false;

public Plugin:myinfo = 
{
    name = "Tank Rock Stumble Block",
    author = "Jacob",
    description = "Fixes rocks disappearing if tank gets stumbled while throwing.",
    version = "0.1",
    url = "github.com/jacob404/myplugins"
}

public Action:L4D_OnCThrowActivate()
{
    blockStumble = true;
    CreateTimer(2.0, UnblockStumble);
}

public Action:UnblockStumble(Handle:timer)
{
    blockStumble = false;
}

public Action:L4D2_OnStagger(target)
{
    if (GetClientTeam(target) != 3) return Plugin_Continue;
    if (GetInfectedClass(target) != 8 || !blockStumble) return Plugin_Continue;
    return Plugin_Handled;
}

GetInfectedClass(client)
{
    if (client > 0 && client <= MaxClients && IsClientInGame(client))
    {
        return GetEntProp(client, Prop_Send, "m_zombieClass");
    }
    return -1;
}