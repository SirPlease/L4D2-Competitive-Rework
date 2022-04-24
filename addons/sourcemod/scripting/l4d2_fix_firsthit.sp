#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools_gamerules>
#include <left4dhooks>

#define PLUGIN_VERSION "2.1"

public Plugin myinfo =
{
	name = "[L4D2] Fix First-Hit",
	author = "Forgetest",
	description = "Fix first hit classes varying between halves and in scavenge staying the same for rounds.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
}

int g_iOffs_FirstClassIndex;
ConVar g_cvAllow;

methodmap CDirector
{
	property int m_nFirstClassIndex {
		public get() { return LoadFromAddress(L4D_GetPointer(POINTER_DIRECTOR) + view_as<Address>(g_iOffs_FirstClassIndex), NumberType_Int32); }
		public set(int index) { StoreToAddress(L4D_GetPointer(POINTER_DIRECTOR) + view_as<Address>(g_iOffs_FirstClassIndex), index, NumberType_Int32); }
	}
}
CDirector TheDirector;

#define GAMEDATA_FILE "l4d2_fix_firsthit"
#define OFFS_FIRSTCLS "CDirector::m_nFirstClassIndex"
void LoadSDK()
{
	Handle conf = LoadGameConfigFile(GAMEDATA_FILE);
	if (!conf) SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	g_iOffs_FirstClassIndex = GameConfGetOffset(conf, OFFS_FIRSTCLS);
	if (g_iOffs_FirstClassIndex == -1) SetFailState("Missing offset \""...OFFS_FIRSTCLS..."\"");
	
	delete conf;
}

public void OnPluginStart()
{
	LoadSDK();
	
	g_cvAllow = CreateConVar("l4d2_scvng_firsthit_shuffle",
							"0",
							"Shuffle first hit classes. Affects only Scavenge mode.\n"
						...	"Value: 1 = Shuffle every round, 2 = Shuffle every match, 0 = Disable.",
							FCVAR_NOTIFY|FCVAR_SPONLY,
							true, 0.0, true, 2.0);
	
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_transitioned", Event_PlayerTransitioned);
	HookEvent("scavenge_round_finished", Event_ScavengeRoundFinished, EventHookMode_PostNoCopy);
	HookEvent("scavenge_match_finished", Event_ScavengeNatchFinished, EventHookMode_PostNoCopy);
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client)
	{
		int team = event.GetInt("team");
		if (team == 3 && team != event.GetInt("oldteam"))
		{
			ResetClassSpawnSystem(client);
		}
	}
}

void Event_PlayerTransitioned(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client) ResetClassSpawnSystem(client);
}

void Event_ScavengeRoundFinished(Event event, const char[] name, bool dontBroadcast)
{
	if (g_cvAllow.IntValue == 1 && GameRules_GetProp("m_bInSecondHalfOfRound", 1))
	{
		SetRandomSeed(GetTime());
		TheDirector.m_nFirstClassIndex = GetRandomInt(1, 6);
	}
}

void Event_ScavengeNatchFinished(Event event, const char[] name, bool dontBroadcast)
{
	if (g_cvAllow.IntValue > 0)
	{
		SetRandomSeed(GetTime());
		TheDirector.m_nFirstClassIndex = GetRandomInt(1, 6);
	}
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
