#include <sourcemod>

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
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));

    bool firstMap = StrContains(currentMap, "m1_", true) != -1;
    SetAllTalk(firstMap);
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