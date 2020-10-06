#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new bool:g_bIsTankAlive;

public Plugin:myinfo = 
{
	name = "L4D2 Tank Announcer",
	author = "Visor",
	description = "Announce in chat and via a sound when a Tank has spawned",
	version = "1.0",
	url = "https://github.com/Attano"
};

public OnMapStart()
{
	PrecacheSound("ui/pickup_secret01.wav");
}

public OnPluginStart()
{
	HookEvent("tank_spawn", EventHook:OnTankSpawn, EventHookMode_PostNoCopy);
	HookEvent("round_start", EventHook:OnRoundStart, EventHookMode_PostNoCopy);
}

public OnRoundStart()
{
	g_bIsTankAlive = false;
}

public OnTankSpawn()
{
	if (!g_bIsTankAlive)
	{
		g_bIsTankAlive = true;
		PrintToChatAll("\x04Tank\x01 has spawned!");
		EmitSoundToAll("ui/pickup_secret01.wav");
	}
}