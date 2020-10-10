#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>

new bool:g_bIsTankAlive;

public Plugin:myinfo = 
{
	name = "L4D2 Tank Announcer",
	author = "Visor",
	description = "Announce in chat and via a sound when a Tank has spawned",
	version = "1.1.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public OnMapStart()
{
	PrecacheSound("ui/pickup_secret01.wav");
}

public OnPluginStart()
{
	HookEvent("tank_spawn", EventHook:TankSpawnEvent, EventHookMode_PostNoCopy);
	HookEvent("round_start", EventHook:RoundStartEvent, EventHookMode_PostNoCopy);
}

public RoundStartEvent()
{
	g_bIsTankAlive = false;
}

public TankSpawnEvent()
{
	if (!g_bIsTankAlive)
	{
		g_bIsTankAlive = true;
		CPrintToChatAll("{red}[{default}!{red}] {olive}Tank {default}has spawned!");
		EmitSoundToAll("ui/pickup_secret01.wav");
	}
}
