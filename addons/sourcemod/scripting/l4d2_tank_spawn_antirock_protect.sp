#include <sourcemod>
#include <left4dhooks>
#include <colors>

float g_fSpawnTime;

ConVar g_cvAntiRockProtectTime;

public Plugin myinfo = 
{
	name = "[L4D2] Tank Spawn Anti-Rock Protect",
	author = "B[R]UTUS",
	description = "Protects a Tank player from randomly rock attack at his spawn",
	version = "1.0",
	url = "https://steamcommunity.com/id/8ru7u5/"
}

public void OnPluginStart()
{
    HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Post);
    g_cvAntiRockProtectTime = CreateConVar("l4d2_antirock_protect_time", "1.5", "Protect time from randomly Tank's rock attack after his spawn");
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    g_fSpawnTime = GetGameTime();
}

public Action L4D_OnCThrowActivate(int ability)
{
    if (GetGameTime() - g_fSpawnTime < g_cvAntiRockProtectTime.FloatValue)
        return Plugin_Handled;

    return Plugin_Continue;
}