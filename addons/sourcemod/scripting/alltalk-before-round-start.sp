#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN

public Plugin myinfo =
{
	name		= "L4D2 - All Talk",
	author		= "Altair Sossai",
	description = "All talk ON before first round start",
	version		= "1.0.0",
	url			= "https://github.com/altair-sossai/l4d2-server-manager-client"
};

ConVar cvar_alltalk;

public void OnPluginStart()
{
    cvar_alltalk = FindConVar("sv_alltalk");
}

public void OnRoundIsLive()
{
    SetAllTalk(false);
}

public void OnMapStart()
{
    CreateTimer(10.0, OnMapStartTimer);
}

public Action OnMapStartTimer(Handle timer)
{
	EnableAlltalkIfFirstMap();

	return Plugin_Continue;
}

public void EnableAlltalkIfFirstMap()
{
    int teamAScore = L4D2Direct_GetVSCampaignScore(0);
    int teamBScore = L4D2Direct_GetVSCampaignScore(1);

    SetAllTalk(teamAScore == 0 && teamBScore == 0);
}

public void SetAllTalk(bool allTalk)
{
    if (allTalk == GetConVarBool(cvar_alltalk))
        return;

    SetConVarBool(cvar_alltalk, allTalk);

    if (allTalk)
        PrintToChatAll("\x01All talk: \x04ON");
    else
        PrintToChatAll("\x01All talk: \x04OFF");
}