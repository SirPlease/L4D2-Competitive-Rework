#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools_gamerules>
#include <dhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "2.5"

public Plugin myinfo =
{
	name = "[L4D2] Fix First-Hit",
	author = "Forgetest",
	description = "Fix first hit classes varying between halves and in scavenge staying the same for rounds.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
}

ConVar g_cvAllow;

public void OnPluginStart()
{
	GameData gd = new GameData("left4dhooks.l4d2");
	if (!gd)
		SetFailState("Missing gamedata \"left4dhooks.l4d2\"");

	DynamicDetour hDetour = new DynamicDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_Ignore);
	if (!hDetour.SetFromConf(gd, SDKConf_Signature, "CDirector::SwapTeams"))
		SetFailState("Missing signature \"CDirector::SwapTeams\"");

	if (!hDetour.Enable(Hook_Pre, DTR_SwapTeams))
		SetFailState("Failed to detour \"CDirector::SwapTeams\"");

	delete hDetour;
	delete gd;

	g_cvAllow = CreateConVar("l4d2_scvng_firsthit_shuffle",
							"0",
							"Shuffle first hit classes. Affects only Scavenge mode.\n"
						...	"Value: 1 = Shuffle every round, 2 = Shuffle every match, 0 = Disable.",
							FCVAR_NOTIFY|FCVAR_SPONLY,
							true, 0.0, true, 2.0);

	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_transitioned", Event_PlayerTransitioned);
	HookEvent("scavenge_round_finished", Event_ScavengeRoundFinished, EventHookMode_PostNoCopy);
	HookEvent("scavenge_match_finished", Event_ScavengeNatchFinished, EventHookMode_PostNoCopy);
}

MRESReturn DTR_SwapTeams()
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3)
			ChangeClientTeam(i, 0);
	}

	return MRES_Ignored;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			ResetClassSpawnSystem(i);
	}
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int team = event.GetInt("team");
	if (team != 3 || team == event.GetInt("oldteam"))
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
		return;

	/**
	 * NOTE:
	 *
	 * Shoutout to elias (Solaris admin) for reporting, testing
	 * and a lot of his time for further info to help address this!
	 *
	 * `CDirector::SwapTeams` always fills the Survivor Team with 4 bots
	 * regardless of the limit. Extra bots might be moved to Infected Team
	 * when the limit is below 4, as a result human who is swapped to Infected
	 * may get incorrect SI of the first lineup.
	 *
	 * -----------------------------------------------------------
	 *
	 * if ( !(unsigned __int8)CDirector::NoSurvivorBots(this) )
	 * {
	 *   v22 = GetGlobalTeam(2);
	 *   v23 = v22;
	 *   if ( v22 )
	 *   {
	 *     if ( (*(int (__cdecl **)(int))(*(_DWORD *)v22 + 852))(v22) <= 3 )
	 *     {
	 *       v24 = 4 - (*(int (__cdecl **)(int))(*(_DWORD *)v23 + 852))(v23);
	 *       if ( v24 > 0 )
	 *       {
	 *         for ( j = 0; j != v24; ++j )
	 *         {
	 *           CDirector::AddSurvivorBot(this, 8);
	 *           Msg("Adding a survivor bot to fill out Survivor team\n");
	 *         }
	 *       }
	 *     }
	 *   }
	 * }
	 */
	if (IsFakeClient(client))
	{
		char netclass[64];
		GetEntityNetClass(client, netclass, sizeof(netclass));
		if (strcmp(netclass, "SurvivorBot") == 0)
		{
			SDKHook(client, SDKHook_SpawnPost, SDK_OnSpawn_Post);
			return;
		}
	}

	ResetClassSpawnSystem(client);
}

void SDK_OnSpawn_Post(int client)
{
	if (IsClientInGame(client))
	{
		SetEntProp(client, Prop_Send, "m_zombieClass", 9);
	}
}

void Event_PlayerTransitioned(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
		return;

	ResetClassSpawnSystem(client);
}

void Event_ScavengeRoundFinished(Event event, const char[] name, bool dontBroadcast)
{
	if (g_cvAllow.IntValue == 1 && GameRules_GetProp("m_bInSecondHalfOfRound", 1))
	{
		ResetFirstSpawnClass();
	}
}

void Event_ScavengeNatchFinished(Event event, const char[] name, bool dontBroadcast)
{
	if (g_cvAllow.IntValue > 0)
	{
		ResetFirstSpawnClass();
	}
}

void ResetFirstSpawnClass()
{
	SetRandomSeed(GetTime());
	L4D2_SetFirstSpawnClass(GetRandomInt(1, 6));
}

void ResetClassSpawnSystem(int client)
{
	static int s_iOffs_Time = -1, s_iOffs_Count = -1;
	if (s_iOffs_Count == -1)
	{
		s_iOffs_Count = FindSendPropInfo("CTerrorPlayer", "m_classSpawnCount");
		s_iOffs_Time = s_iOffs_Count - 9 * 4;
	}

	float fNow = GetGameTime();
	for (int i = 0; i <= 8; ++i)
	{
		SetEntData(client, s_iOffs_Count + i*4, 0, 4);
		SetEntDataFloat(client, s_iOffs_Time + i*4, fNow);
	}
}
