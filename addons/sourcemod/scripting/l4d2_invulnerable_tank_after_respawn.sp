#include <sourcemod>
#include <left4dhooks>
#include <l4d2util>

float g_fSpawnTime;

bool g_bLateLoad = false;

ConVar g_cvInvulnerableTankAfterRespawnTime;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
    g_bLateLoad = bLate;
    return APLRes_Success;
}

public Plugin myinfo = 
{
    name = "[L4D2] Invulnerable tank after respawn",
    author = "Altair Sossai",
    description = "Prevent the tank from taking damage right after the player takes control of the tank",
    version = "1.0",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
    HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Post);

    g_cvInvulnerableTankAfterRespawnTime = CreateConVar("l4d2_invulnerable_tank_after_respawn_time", "2", "Invincibility time after respawn");

    for (int client = 1; g_bLateLoad && client <= MaxClients; client++) {
        if (IsClientInGame(client))
            OnClientPutInServer(client);
    }
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    g_fSpawnTime = GetGameTime();
}

public void OnClientPutInServer(int iClient)
{
    SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public void OnClientDisconnect(int iClient)
{
    SDKUnhook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public Action Hook_OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype)
{
    if (IsValidTank(iVictim) && GetGameTime() - g_fSpawnTime < g_cvInvulnerableTankAfterRespawnTime.FloatValue)
        return Plugin_Handled;

    return Plugin_Continue;
}