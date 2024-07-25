#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <caster_system>
#define REQUIRE_PLUGIN

enum L4DTeam
{
	L4DTeam_Unassigned = 0,
	L4DTeam_Spectator  = 1,
	L4DTeam_Survivor   = 2,
	L4DTeam_Infected   = 3
}

enum StatusRates
{
	RatesLimit = 0,
	RatesFree  = 1,
}

enum struct Player
{
	float		LastAdjusted;
	StatusRates Status;
}

bool
	g_bCasterSystem,
	g_bLateload;

ConVar
	sv_mincmdrate,
	sv_maxcmdrate,
	sv_minupdaterate,
	sv_maxupdaterate,
	sv_minrate,
	sv_maxrate,
	sv_client_min_interp_ratio,
	sv_client_max_interp_ratio;

char
	g_sNetVars[8][8];

Player
	g_Players[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name		= "Lightweight Spectating",
	author		= "Visor, lechuga",
	description = "Forces low rates on spectators",
	version		= "1.3",
	url			= "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("SetStatusRates", Native_SetStatusRates);
	CreateNative("GetStatusRates", Native_GetStatusRates);

	g_bLateload = late;
	RegPluginLibrary("specrates");
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	g_bCasterSystem = LibraryExists("caster_system");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "caster_system", true))
		g_bCasterSystem = false;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "caster_system", true))
		g_bCasterSystem = true;
}

public void OnPluginStart()
{
	sv_mincmdrate			   = FindConVar("sv_mincmdrate");
	sv_maxcmdrate			   = FindConVar("sv_maxcmdrate");
	sv_minupdaterate		   = FindConVar("sv_minupdaterate");
	sv_maxupdaterate		   = FindConVar("sv_maxupdaterate");
	sv_minrate				   = FindConVar("sv_minrate");
	sv_maxrate				   = FindConVar("sv_maxrate");
	sv_client_min_interp_ratio = FindConVar("sv_client_min_interp_ratio");
	sv_client_max_interp_ratio = FindConVar("sv_client_max_interp_ratio");

	HookEvent("player_team", OnTeamChange);

	if (!g_bLateload)
		return;

	g_bCasterSystem = LibraryExists("caster_system");
}

public void OnPluginEnd()
{
	sv_minupdaterate.SetString(g_sNetVars[2]);
	sv_mincmdrate.SetString(g_sNetVars[0]);
}

public void OnConfigsExecuted()
{
	sv_mincmdrate.GetString(g_sNetVars[0], 8);
	sv_maxcmdrate.GetString(g_sNetVars[1], 8);
	sv_minupdaterate.GetString(g_sNetVars[2], 8);
	sv_maxupdaterate.GetString(g_sNetVars[3], 8);
	sv_minrate.GetString(g_sNetVars[4], 8);
	sv_maxrate.GetString(g_sNetVars[5], 8);
	sv_client_min_interp_ratio.GetString(g_sNetVars[6], 8);
	sv_client_max_interp_ratio.GetString(g_sNetVars[7], 8);

	sv_minupdaterate.SetInt(30);
	sv_mincmdrate.SetInt(30);
}

public void OnClientPutInServer(int client)
{
	g_Players[client].LastAdjusted = 0.0;
	g_Players[client].Status	   = RatesLimit;
}

void OnTeamChange(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	CreateTimer(10.0, TimerAdjustRates, client, TIMER_FLAG_NO_MAPCHANGE);
}

Action TimerAdjustRates(Handle timer, any client)
{
	AdjustRates(client);
	return Plugin_Handled;
}

public void OnClientSettingsChanged(int client)
{
	AdjustRates(client);
}

void AdjustRates(int client)
{
	if (!IsValidClient(client))
		return;

	if (g_Players[client].LastAdjusted < GetEngineTime() - 1.0)
	{
		g_Players[client].LastAdjusted = GetEngineTime();

		L4DTeam team = L4D_GetClientTeam(client);
		if (team == L4DTeam_Survivor || team == L4DTeam_Infected || (g_bCasterSystem && IsClientCaster(client)))
			ResetRates(client);
		else if (team == L4DTeam_Spectator)
		{
			if (g_Players[client].Status == RatesLimit)
				SetSpectatorRates(client);
			else
				ResetRates(client);
		}
	}
}

void SetSpectatorRates(int client)
{
	sv_mincmdrate.ReplicateToClient(client, "30");
	sv_maxcmdrate.ReplicateToClient(client, "30");
	sv_minupdaterate.ReplicateToClient(client, "30");
	sv_maxupdaterate.ReplicateToClient(client, "30");
	sv_minrate.ReplicateToClient(client, "10000");
	sv_maxrate.ReplicateToClient(client, "10000");

	SetClientInfo(client, "cl_updaterate", "30");
	SetClientInfo(client, "cl_cmdrate", "30");
}

void ResetRates(int client)
{
	sv_mincmdrate.ReplicateToClient(client, g_sNetVars[0]);
	sv_maxcmdrate.ReplicateToClient(client, g_sNetVars[1]);
	sv_minupdaterate.ReplicateToClient(client, g_sNetVars[2]);
	sv_maxupdaterate.ReplicateToClient(client, g_sNetVars[3]);
	sv_minrate.ReplicateToClient(client, g_sNetVars[4]);
	sv_maxrate.ReplicateToClient(client, g_sNetVars[5]);

	SetClientInfo(client, "cl_updaterate", g_sNetVars[3]);
	SetClientInfo(client, "cl_cmdrate", g_sNetVars[1]);
}

// void SetStatusRates(int client, StatusRates Status);
int Native_SetStatusRates(Handle plugin, int numParams)
{
	int			client		 = GetNativeCell(1);
	StatusRates status		 = view_as<StatusRates>(GetNativeCell(2));

	g_Players[client].Status = status;
	AdjustRates(client);
	return 0;
}

// StatusRates GetStatusRates(int client);
any Native_GetStatusRates(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return g_Players[client].Status;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}

/**
 * Returns the clients team using L4DTeam.
 *
 * @param client		Player's index.
 * @return				Current L4DTeam of player.
 * @error				Invalid client index.
 */
stock L4DTeam L4D_GetClientTeam(int client)
{
	int team = GetClientTeam(client);
	return view_as<L4DTeam>(team);
}