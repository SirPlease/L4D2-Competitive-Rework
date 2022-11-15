#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.4"
#define MAXENTITY 2048

public Plugin myinfo =
{
    name = "Block Rocket Jump Exploit",
    author = "DJ_WEST, HarryPotter",
    description = "Block rocket jump exploit (with grenade launcher/vomitjar/pipebomb/molotov/common/spit/rock)",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=122371"
}

bool g_bRocketJumpExploit[MAXENTITY+1];
bool g_bStepOnEntitiy[MAXPLAYERS + 1];

bool g_bL4D2Version;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
    EngineVersion test = GetEngineVersion();
    if( test == Engine_Left4Dead)
        g_bL4D2Version = false;
    else if (test == Engine_Left4Dead2 )
        g_bL4D2Version = true;
    else
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
        return APLRes_SilentFailure;
    }
	
    return APLRes_Success;
}

public void OnPluginStart()
{
    CreateConVar("block_rocketjump_version", PLUGIN_VERSION, "Block Rocket Jump Exploit version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!IsValidEntityIndex(entity))
        return;

    switch (classname[0])
    {
        case 'i', // infected
                'm', // molotov_projectile
                'p', // pipe_bomb_projectile
                't', // tank_rock
                'v', // vomitjar_projectile
                'g', // grenade_launcher_projectile
                's', // spitter_projectile
                'w': // witch
        {
            if (strcmp(classname, "infected") == 0 ||
                strcmp(classname, "molotov_projectile") == 0 ||
                strcmp(classname, "pipe_bomb_projectile") == 0 ||
                strcmp(classname, "tank_rock") == 0 ||
                strcmp(classname, "witch") == 0 ||
                (g_bL4D2Version && (strcmp(classname, "vomitjar_projectile") == 0 ||
                                    strcmp(classname, "grenade_launcher_projectile") == 0 ||
                                    strcmp(classname, "spitter_projectile") == 0)) )
            {
                g_bRocketJumpExploit[entity] = true;
            }						
        }
    }
}

public void OnEntityDestroyed(int entity)
{
    if (!IsValidEntityIndex(entity))
        return;

    g_bRocketJumpExploit[entity] = false;
}

bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if(IsClientInGame(client) && GetClientTeam(client) != 1 && IsPlayerAlive(client))
    {
        if(IsFakeClient(client)) return Plugin_Continue;
			
        int entity = GetEntPropEnt(client, Prop_Data, "m_hGroundEntity");
        if (entity > MaxClients && g_bRocketJumpExploit[entity])
        {
            //PrintToChatAll("%N step on entity - %d", client, entity);
            g_bStepOnEntitiy[client] = true;
            return Plugin_Continue;
        }

        if(g_bStepOnEntitiy[client])
        {
            float flVel[3];
            GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", flVel);
            //PrintToChatAll("%N m_vecAbsVelocity - %.2f %.2f %.2f", client, flVel[0], flVel[1], flVel[2]);

            flVel[2] = 0.0; //velocity height zero
            TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, flVel);
        }
    }

    g_bStepOnEntitiy[client] = false;
    return Plugin_Continue;
}