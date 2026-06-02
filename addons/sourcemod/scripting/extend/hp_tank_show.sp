#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>

#define MAXENTITIES                   2048
#define TEAM_INFECTED                        3
#define TEAM_SURVIVOR                        2
#define SPRITE_MODEL3            "materials/vgui/healthbar_white.vmt"
#define SPRITE_MODEL2            "materials/vgui/s_panel_healing_mini_prog.vmt"
#define SPRITE_MODEL             "materials/vgui/hud/zombieteamimage_tank.vmt"
#define SPRITE_MODEL4            "materials/vgui/healthbar_orange.vmt"
#define SPRITE_DEATH             "materials/sprites/death_icon.vmt"
#define CLASSNAME_TANK_ROCK           "tank_rock"
#define CLASSNAME_INFECTED            "infected"
#define CLASSNAME_WITCH               "witch"

//RIP DIMINUIR?

static bool   g_bL4D2Version;

static int TankSprite[MAXPLAYERS+1];
static int TankHealth[MAXPLAYERS+1];
static bool TankNow[MAXPLAYERS+1];
static bool TankIncapped[MAXPLAYERS+1];
static float LastUseTime[MAXPLAYERS+1];

static int AlgorithmType = 2;
static bool EnableGlow = false;
static int ZOMBIECLASS_TANK;
static bool   g_bConfigLoaded;
static bool   gc_bVisible[MAXPLAYERS+1][MAXPLAYERS+1];
static float  g_fVPlayerMins[3] = {-16.0, -16.0,  0.0};
static float  g_fVPlayerMaxs[3] = { 16.0,  16.0, 71.0};
static bool   ge_bInvalidTrace[MAXENTITIES+1];
static int    ge_iOwner[MAXENTITIES+1];

#define PLUGIN_NAME                   "[L4D1 & L4D2] Tank HP Sprite"
#define PLUGIN_AUTHOR                 "Mart & Harry (fork)"
#define PLUGIN_DESCRIPTION            "Shows a sprite at the tank head that goes from green to red based on its HP"
#define PLUGIN_VERSION                "1.3"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=330370"

public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test == Engine_Left4Dead )
	{
		ZOMBIECLASS_TANK = 5;
		g_bL4D2Version = false;
	}
	else if( test == Engine_Left4Dead2 )
	{
		ZOMBIECLASS_TANK = 8;
		g_bL4D2Version = true;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
    HookEvent("tank_spawn", Event_TankSpawn);
    HookEvent("tank_killed", event_TankKilled);
    HookEvent("player_hurt", OnPlayerHurt);

    CreateTimer(0.1, TimerVisible, _, TIMER_REPEAT);
}

public void OnConfigsExecuted()
{
    g_bConfigLoaded = true;
}

public void OnMapStart()
{
    PrecacheModel(SPRITE_MODEL, true);
    PrecacheModel(SPRITE_MODEL2, true);
    PrecacheModel(SPRITE_MODEL3, true);
    PrecacheModel(SPRITE_MODEL4, true);
    PrecacheModel(SPRITE_DEATH, true);
}

public void OnMapEnd()
{
	g_bConfigLoaded = false;
}

public void OnClientDisconnect(int client)
{
    if (!g_bConfigLoaded)
        return;

    TankSprite[client] = INVALID_ENT_REFERENCE;

    for (int target = 1; target <= MaxClients; target++)
    {
        gc_bVisible[target][client] = false;
    }
}

public void event_TankKilled( Event event, const char[] sName, bool bDontBroadcast )
{
    int target = GetClientOfUserId(GetEventInt(event, "userid"));

    if (target <= 0 || target > MaxClients|| !IsClientInGame(target))
        return;

    if (!TankIncapped[target])
    {
        TankHealth[target] = -1;
        int env_sprite = TankSprite[target];

        if (!IsValidEntRef(env_sprite))
            return;

        DispatchKeyValue(env_sprite, "model", SPRITE_DEATH);
        DispatchKeyValue(env_sprite, "rendercolor", "127 0 0");
        DispatchKeyValue(env_sprite, "renderamt", "240");
        DispatchSpawn(env_sprite);

        if (g_bL4D2Version && EnableGlow)
            L4D2_SetEntityGlow_Flashing(target, true);
    }

    for (int client = 1; client <= MaxClients; client++)
    {
        gc_bVisible[target][client] = false;
    }
}

public Action OnPlayerHurt( Event event, const char[] sName, bool bDontBroadcast )
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!client || !IsClientConnected(client) || !IsClientInGame(client) || (!IsFakeClient(client) && !IsPlayerAlive(client)) || GetClientTeam(client) != TEAM_INFECTED || TankHealth[client] == -1)
        return Plugin_Continue;

    if(IsPlayerTank(client) == false)
    {
        return Plugin_Continue;
    }

    int nowHP = GetEventInt(event, "health");
    int maxHP = TankHealth[client];

    if (TankHealth[client] == -1)
         return Plugin_Continue;

    int env_sprite = TankSprite[client];

    if (!IsValidEntRef(env_sprite))
        return Plugin_Continue;

    if (IsPlayerIncapped(client))
    {
        if (!TankIncapped[client])
        {
            TankIncapped[client] = true;
            DispatchKeyValue(env_sprite, "targetname", "tanksprite");
            DispatchKeyValue(env_sprite, "model", SPRITE_DEATH);
            DispatchKeyValue(env_sprite, "rendercolor", "127 0 0");
            DispatchKeyValue(env_sprite, "renderamt", "240");
            DispatchSpawn(env_sprite);

            if (g_bL4D2Version && EnableGlow)
                L4D2_SetEntityGlow_Flashing(client, true);
        }

        return Plugin_Continue;
    }

    float fCountdownHeat = float(nowHP) / maxHP;

    char sTemp[12];

    bool bHalfHp = false;
    bHalfHp = fCountdownHeat <= 0.5 ? true : false;
    if (AlgorithmType == 1)
        Format(sTemp, sizeof(sTemp), "%i %i 0", bHalfHp ? 255 : RoundFloat(255.0 * ((1.0 - fCountdownHeat) * 2)), bHalfHp ? RoundFloat(255.0 * (fCountdownHeat) * 2) : 255);
    else
        Format(sTemp, sizeof(sTemp), "%i %i 0", RoundFloat(255 * (1 - fCountdownHeat)), RoundFloat(255 * fCountdownHeat));
    DispatchKeyValue(env_sprite, "rendercolor", sTemp);
    DispatchKeyValue(env_sprite, "model", SPRITE_MODEL3);
    DispatchKeyValue(env_sprite, "renderamt", "240");

    if (g_bL4D2Version && EnableGlow)
    {
        if (!TankNow[client])
        {
            L4D2_SetEntityGlow_Type(client, view_as<L4D2GlowType>(3));
            L4D2_SetEntityGlow_Range(client, 0);
            L4D2_SetEntityGlow_MinRange(client, 0);

            int color[3];
            if (AlgorithmType == 1)
            {
                color[0] = bHalfHp ? 255 : RoundFloat(255.0 * ((1.0 - fCountdownHeat) * 2));
                color[1] = bHalfHp ? RoundFloat(255.0 * (fCountdownHeat) * 2) : 255;
                color[2] = 0;
            }
            else if (AlgorithmType == 2)
            {
                color[0] = RoundFloat(255 * (1 - fCountdownHeat));
                color[1] = RoundFloat(255 * fCountdownHeat);
                color[2] = 0;
            }

            L4D2_SetEntityGlow_Color(client, color);
            if (fCountdownHeat <= 0.1)
                L4D2_SetEntityGlow_Flashing(client, true);
        }
    }

    LastUseTime[client] = GetEngineTime();

    return Plugin_Continue;
}

int iSwitch = 0;
public void Event_TankSpawn( Event event, const char[] sName, bool bDontBroadcast )
{
    int client =    GetClientOfUserId(GetEventInt(event, "userid"));

    if (IsValidClient(client))
    {
        TankHealth[client] = -1;
        TankNow[client] = false;
        TankIncapped[client] = false;
        CreateTimer(0.5, Timer_TankSprite, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        CreateTimer(1.0, Timer_HealthModifierSet, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

        if (g_bL4D2Version && EnableGlow)
        {
            L4D2_SetEntityGlow_Type(client, view_as<L4D2GlowType>(3));
            L4D2_SetEntityGlow_Range(client, 0);
            L4D2_SetEntityGlow_MinRange(client, 0);
            L4D2_SetEntityGlow_Color(client, view_as<int>({0, 255, 0}));
            L4D2_SetEntityGlow_Flashing(client, false);
        }

        iSwitch = iSwitch +1;
        if (iSwitch > 4)
        iSwitch = 1;
        int env_sprite = CreateEntityByName("env_sprite");

        if (env_sprite == -1)
            return;

        // decl String:Buffer[64];
        // Format(Buffer, sizeof(Buffer), "client%i", client);
        // DispatchKeyValue(env_sprite, "targetname", Buffer);

        DispatchKeyValue(env_sprite, "model", SPRITE_MODEL3);
        DispatchKeyValue(env_sprite, "rendermode", "1");
        DispatchKeyValue(env_sprite, "rendercolor", "0 255 0");
        DispatchKeyValue(env_sprite, "renderamt", "240");
        DispatchKeyValue(env_sprite, "disablereceiveshadows", "1");
        DispatchKeyValue(env_sprite, "spawnflags", "1");
        DispatchKeyValueFloat(env_sprite, "fademindist", 1000.0);
        DispatchKeyValueFloat(env_sprite, "fademaxdist", 1000.0);

        DispatchSpawn(env_sprite);
        DispatchKeyValue(env_sprite, "renderamt", "0");

        SetVariantString("!activator");
        AcceptEntityInput(env_sprite, "SetParent", client);

        float vPos[3];
        // vPos[0] = 200.0;
        // vPos[1] = 200.0;
        vPos[2] = 100.0;

        TeleportEntity(env_sprite, vPos, NULL_VECTOR, NULL_VECTOR);

        TankSprite[client] =  EntIndexToEntRef(env_sprite);

        ge_iOwner[env_sprite] = client;
        SDKHook(env_sprite, SDKHook_SetTransmit, OnSetTransmit);
    }
}

public Action OnSetTransmit(int entity, int client)
{
    int owner = ge_iOwner[entity];

    if (owner == client)
        return Plugin_Handled;

    if (gc_bVisible[owner][client])
        return Plugin_Continue;

    return Plugin_Handled;
}

public Action Timer_HealthModifierSet(Handle timer, int client)
{
    if (IsValidClient(client) && !IsPlayerGhost(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_INFECTED && GetClientHealth(client) > 0 && TankHealth[client] == -1)
    {
       TankHealth[client] = GetClientHealth(client);
       return Plugin_Stop;
    }

    return Plugin_Continue;

}

public Action Timer_TankSprite(Handle timer, int client)
{
    int env_sprite = TankSprite[client];

    if (!IsValidEntRef(env_sprite))
    {
        return Plugin_Stop;
    }

    if (!IsClientInGame(client) || (!IsFakeClient(client) && !IsPlayerAlive(client)) || GetClientTeam(client) != 3)
	{
        AcceptEntityInput(env_sprite, "Kill");
        return Plugin_Stop;
	}
	
    if(IsPlayerTank(client) == false)
    {
        AcceptEntityInput(env_sprite, "Kill"); 
        return Plugin_Stop;
    }

    if (GetEngineTime()-LastUseTime[client] >= 2.0 && IsPlayerAlive(client) && !IsPlayerIncapped(client))
    {
        DispatchKeyValue(env_sprite, "model", SPRITE_MODEL3);
        DispatchKeyValue(env_sprite, "renderamt", "0");
    }

    return Plugin_Continue;
}

bool IsValidClient(int client)
{
    return (1 <= client <= MaxClients && IsClientInGame(client));
}

bool IsPlayerGhost(int client)
{
    return GetEntProp(client, Prop_Send, "m_isGhost", 1) == 1;
}

bool IsPlayerIncapped(int client)
{
    return GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1;
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE)
		return true;
	return false;
}

bool IsPlayerTank (int client)
{
	if(GetZombieClass(client) == ZOMBIECLASS_TANK)
		return true;
	return false;
}

int GetZombieClass(int client)
{
    return GetEntProp(client, Prop_Send, "m_zombieClass");
}

public Action TimerVisible(Handle timer)
{
    if (!g_bConfigLoaded)
        return Plugin_Continue;

    for (int target = 1; target <= MaxClients; target++)
    {
        if (TankSprite[target] == INVALID_ENT_REFERENCE)
            continue;

        if (!IsClientInGame(target))
            continue;

        for (int client = 1; client <= MaxClients; client++)
        {
            gc_bVisible[target][client] = false;

            if (!IsClientInGame(client))
                continue;

            if (IsFakeClient(client))
                continue;

            if (GetClientTeam(client) == TEAM_SURVIVOR && !IsVisibleTo(client, target))
                continue;

            gc_bVisible[target][client] = true;
        }
    }

    return Plugin_Continue;
}

bool IsVisibleTo(int client, int target)
{
    float vClientPos[3];
    float vEntityPos[3];
    float vLookAt[3];
    float vAng[3];

    GetClientEyePosition(client, vClientPos);
    GetClientEyePosition(target, vEntityPos);
    MakeVectorFromPoints(vClientPos, vEntityPos, vLookAt);
    GetVectorAngles(vLookAt, vAng);

    Handle trace = TR_TraceRayFilterEx(vClientPos, vAng, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter, target);

    bool isVisible;

    if (TR_DidHit(trace))
    {
        isVisible = (TR_GetEntityIndex(trace) == target);

        if (!isVisible)
        {
            vEntityPos[2] -= 62.0; // results the same as GetClientAbsOrigin

            delete trace;
            trace = TR_TraceHullFilterEx(vClientPos, vEntityPos, g_fVPlayerMins, g_fVPlayerMaxs, MASK_PLAYERSOLID, TraceFilter, target);

            if (TR_DidHit(trace))
                isVisible = (TR_GetEntityIndex(trace) == target);
        }
    }

    delete trace;

    return isVisible;
}

public bool TraceFilter(int entity, int contentsMask, int client)
{
    if (entity == client)
        return true;

    if (IsValidClientIndex(entity))
        return false;

    if( !IsValidEntityIndex(entity) )
        return false;

    return ge_bInvalidTrace[entity] ? false : true;
}

public void OnEntityDestroyed(int entity)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    ge_bInvalidTrace[entity] = false;
    ge_iOwner[entity] = 0;
}


public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    switch (classname[0])
    {
        case 't':
        {
            if (StrEqual(classname, CLASSNAME_TANK_ROCK))
                ge_bInvalidTrace[entity] = true;
        }
        case 'i':
        {
            if (StrEqual(classname, CLASSNAME_INFECTED))
                ge_bInvalidTrace[entity] = true;
        }
        case 'w':
        {
            if (StrEqual(classname, CLASSNAME_WITCH))
                ge_bInvalidTrace[entity] = true;
        }
    }
}

bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
}