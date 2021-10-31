#pragma semicolon 1
#pragma newdecls required;

#include <sourcemod>
#include <left4dhooks>

#define TEAM_INFECTED 3
#define Z_TANK 8

bool
	g_bBlockStumble = false;

public Plugin myinfo =
{
	name = "Tank Rock Stumble Block",
	author = "Jacob",
	description = "Fixes rocks disappearing if tank gets stumbled while throwing.",
	version = "0.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public Action L4D_OnCThrowActivate()
{
	g_bBlockStumble = true;
	CreateTimer(2.0, UnblockStumble);
}

public Action UnblockStumble(Handle hTimer)
{
	g_bBlockStumble = false;
}

public Action L4D2_OnStagger(int iTarget)
{
	return (IsTank(iTarget) && g_bBlockStumble) ? Plugin_Handled : Plugin_Continue;
}

bool IsTank(int iClient)
{
	return (GetClientTeam(iClient) == TEAM_INFECTED && GetEntProp(iClient, Prop_Send, "m_zombieClass") == Z_TANK);
}
