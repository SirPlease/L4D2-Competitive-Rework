#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo = 
{
	name = "Tank Punch Ceiling Stuck Fix",
	author = "Tabun, Visor, A1m`, Forgetest",
	description = "Fixes the problem where tank-punches get a survivor stuck in the roof.",
	version = "2.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

ConVar sv_lagcompensationforcerestore;

public void OnPluginStart()
{
	sv_lagcompensationforcerestore = FindConVar("sv_lagcompensationforcerestore");
}

public void L4D_TankClaw_OnPlayerHit_Post(int tank, int claw, int player)
{
	sv_lagcompensationforcerestore.BoolValue = false;
}

public void L4D_TankClaw_DoSwing_Post(int tank, int claw)
{
	if (!sv_lagcompensationforcerestore.BoolValue)
		sv_lagcompensationforcerestore.BoolValue = true;
}