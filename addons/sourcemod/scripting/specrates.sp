#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <readyup>

enum L4D2Team
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected
};

new bool:readyUpIsAvailable;
new Handle:sv_mincmdrate;
new Handle:sv_maxcmdrate;
new Handle:sv_minupdaterate;
new Handle:sv_maxupdaterate;
new Handle:sv_minrate;
new Handle:sv_maxrate;
new Handle:sv_client_min_interp_ratio;
new Handle:sv_client_max_interp_ratio;

new String:netvars[8][8];

new Float:fLastAdjusted[MAXPLAYERS + 1];

public Plugin:myinfo =
{
    name = "Lightweight Spectating",
    author = "Visor",
    description = "Forces low rates on spectators",
    version = "1.2.1",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public OnPluginStart()
{
    sv_mincmdrate = FindConVar("sv_mincmdrate");
    sv_maxcmdrate = FindConVar("sv_maxcmdrate");
    sv_minupdaterate = FindConVar("sv_minupdaterate");
    sv_maxupdaterate = FindConVar("sv_maxupdaterate");
    sv_minrate = FindConVar("sv_minrate");
    sv_maxrate = FindConVar("sv_maxrate");
    sv_client_min_interp_ratio = FindConVar("sv_client_min_interp_ratio");
    sv_client_max_interp_ratio = FindConVar("sv_client_max_interp_ratio");

    HookEvent("player_team", OnTeamChange);
}

public OnPluginEnd()
{
    SetConVarString(sv_minupdaterate, netvars[2]);
    SetConVarString(sv_mincmdrate, netvars[0]);
}

public OnAllPluginsLoaded()
{
    readyUpIsAvailable = LibraryExists("readyup");
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "readyup", true))
    {
        readyUpIsAvailable = false;
    }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "readyup", true))
    {
        readyUpIsAvailable = true;
    }
}

public OnConfigsExecuted()
{
    GetConVarString(sv_mincmdrate, netvars[0], 8);
    GetConVarString(sv_maxcmdrate, netvars[1], 8);
    GetConVarString(sv_minupdaterate, netvars[2], 8);
    GetConVarString(sv_maxupdaterate, netvars[3], 8);
    GetConVarString(sv_minrate, netvars[4], 8);
    GetConVarString(sv_maxrate, netvars[5], 8);
    GetConVarString(sv_client_min_interp_ratio, netvars[6], 8);
    GetConVarString(sv_client_max_interp_ratio, netvars[7], 8);

    SetConVarInt(sv_minupdaterate, 30);
    SetConVarInt(sv_mincmdrate, 30);
}

public OnClientPutInServer(client)
{
    fLastAdjusted[client] = 0.0;
}

public OnTeamChange(Handle:event, String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    CreateTimer(10.0, TimerAdjustRates, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TimerAdjustRates(Handle:timer, any:client)
{
    AdjustRates(client);
    return Plugin_Handled;
}

public OnClientSettingsChanged(client) 
{
    AdjustRates(client);
}

AdjustRates(client)
{
    if (!IsValidClient(client))
        return;

    if (fLastAdjusted[client] < GetEngineTime() - 1.0)
    {
        fLastAdjusted[client] = GetEngineTime();

        new L4D2Team:team = L4D2Team:GetClientTeam(client);
        if (team == L4D2Team_Survivor || team == L4D2Team_Infected || (readyUpIsAvailable && IsClientCaster(client)))
        {
            ResetRates(client);
        }
        else if (team == L4D2Team_Spectator)
        {
            SetSpectatorRates(client);
        }
    }
}

SetSpectatorRates(client)
{
    SendConVarValue(client, sv_mincmdrate, "30");
    SendConVarValue(client, sv_maxcmdrate, "30");
    SendConVarValue(client, sv_minupdaterate, "30");
    SendConVarValue(client, sv_maxupdaterate, "30");
    SendConVarValue(client, sv_minrate, "10000");
    SendConVarValue(client, sv_maxrate, "10000");

    SetClientInfo(client, "cl_updaterate", "30");
    SetClientInfo(client, "cl_cmdrate", "30");
}

ResetRates(client)
{
    SendConVarValue(client, sv_mincmdrate, netvars[0]);
    SendConVarValue(client, sv_maxcmdrate, netvars[1]);
    SendConVarValue(client, sv_minupdaterate, netvars[2]);
    SendConVarValue(client, sv_maxupdaterate, netvars[3]);
    SendConVarValue(client, sv_minrate, netvars[4]);
    SendConVarValue(client, sv_maxrate, netvars[5]);

    SetClientInfo(client, "cl_updaterate", netvars[3]);
    SetClientInfo(client, "cl_cmdrate", netvars[1]);
}

bool:IsValidClient(client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}