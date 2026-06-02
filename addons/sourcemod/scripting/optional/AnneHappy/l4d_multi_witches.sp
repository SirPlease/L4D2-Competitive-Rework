#define PLUGIN_VERSION "1.5.4"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define DEBUG 0
#define CVAR_FLAGS	FCVAR_NOTIFY

int countRoundWitch;
int countAliveWitch;
int maxCountWitchInRound;
int maxCountWitchAlive;

float WitchTimeMin;
float WitchTimeMax;
float WitchDistance;

bool NotRemoveDirectorWitch;

ConVar g_hCvarCountWitchInRound;
ConVar g_hCvarCountAliveWitch;
ConVar g_hCvarWitchTimeMin;
ConVar g_hCvarWitchTimeMax;
ConVar g_hCvarWitchDistance;
ConVar g_hCvarDirectorWitch;

bool runTimer;
bool bWitchSpawnByPlugin;
bool g_bLateload;
bool g_bLeft4dead2;

public Plugin myinfo =
{
	name = "[L4D1 & L4D2] Multi witches",
	description = "Spawns more witches on the map",
	author = "Sheleu (Fork by Dragokas)",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/groups/Bloody_Witch"
};

/*
	Fork by Dragokas
	
	1.5.4 (28-May-2021)
	 - Prevented potential double Round Start glitch in L4D2.
	
	1.5.3 (24-11-2019)
	 - Code is optimized.
	 - Spawn rules and conditions are re-written / fixed.
	 - Prevented bug with bots duplication.
	 - Added new ConVars.
*/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead2 )
	{
		g_bLeft4dead2 = true;
	}
	g_bLateload = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_multi_witches_version", PLUGIN_VERSION, "Plugin Version", CVAR_FLAGS | FCVAR_DONTRECORD);

	g_hCvarCountWitchInRound 	= CreateConVar("l4d_witches_limit", 			"20", 		"Sets the limit for witches spawned. If 0, the plugin will not check count witches", CVAR_FLAGS);
	g_hCvarCountAliveWitch 		= CreateConVar("l4d_witches_limit_alive", 		"3", 		"Sets the limit alive witches. If 0, the plugin will not check count alive witches", CVAR_FLAGS);
	g_hCvarWitchTimeMin 		= CreateConVar("l4d_witches_spawn_time_min", 	"20.0", 	"Sets the min spawn time for witches spawned by the plugin in seconds", CVAR_FLAGS);
	g_hCvarWitchTimeMax 		= CreateConVar("l4d_witches_spawn_time_max", 	"35.0", 	"Sets the max spawn time for witches spawned by the plugin in seconds", CVAR_FLAGS);
	g_hCvarWitchDistance 		= CreateConVar("l4d_witches_distance", 			"1600.0", 	"The range from survivors that witch should be removed. If 0, the plugin will not remove witches", CVAR_FLAGS);
	g_hCvarDirectorWitch 		= CreateConVar("l4d_witches_director_witch", 	"1", 		"If 1, enable director's witch. If 0, disable director's witch", CVAR_FLAGS);
	
	//AutoExecConfig(true, "l4d_witches");
	
	GetCvars();
	
	g_hCvarCountWitchInRound.AddChangeHook(ConVarChanged);
	g_hCvarCountAliveWitch.AddChangeHook(ConVarChanged);
	g_hCvarWitchTimeMin.AddChangeHook(ConVarChanged);
	g_hCvarWitchTimeMax.AddChangeHook(ConVarChanged);
	g_hCvarWitchDistance.AddChangeHook(ConVarChanged);
	g_hCvarDirectorWitch.AddChangeHook(ConVarChanged);
	
	HookEvent("witch_spawn", Event_WitchSpawned);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	if( g_bLateload )
	{
		countAliveWitch = GetCountWitchesInRange();
		countRoundWitch = countAliveWitch;
		runTimer = true;
		Start_Timer();
	}
}

public void ConVarChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	maxCountWitchInRound = g_hCvarCountWitchInRound.IntValue;
	maxCountWitchAlive = g_hCvarCountAliveWitch.IntValue;
	WitchTimeMin = g_hCvarWitchTimeMin.FloatValue;
	WitchTimeMax = g_hCvarWitchTimeMax.FloatValue;
	WitchDistance = g_hCvarWitchDistance.FloatValue;
	NotRemoveDirectorWitch = g_hCvarDirectorWitch.BoolValue;
}

public void Event_WitchSpawned(Event event, char[] name, bool dontBroadcast)
{
	if( !bWitchSpawnByPlugin && !NotRemoveDirectorWitch )
	{
		int WitchID = event.GetInt("witchid");
		if( IsValidEdict(WitchID) )
		{
			AcceptEntityInput(WitchID, "Kill");
		}
	}
	else
	{
		if( bWitchSpawnByPlugin )
		{
			countRoundWitch++;
		}
		countAliveWitch++;
		
		#if DEBUG
		PrintToChatAll("%s Witch spawned # %d, max = %d, alive: %i", "[l4d_witches]", countRoundWitch, maxCountWitchInRound, countAliveWitch);
		#endif
	}
}

public void Event_WitchKilled(Event event, char[] name, bool dontBroadcast)
{
	countAliveWitch--;
}

public void OnMapStart()
{
	if( !IsModelPrecached("models/infected/witch.mdl") )
	{
		PrecacheModel("models/infected/witch.mdl", false);
	}
}

public void OnMapEnd()
{
	runTimer = false;
}

public void Event_RoundEnd(Event event, char[] name, bool dontBroadcast)
{
	runTimer = false;
}

public void Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
	countRoundWitch = 0;
	countAliveWitch = 0;
	if( !runTimer )
	{
		Start_Timer();
	}
	runTimer = true;
}

void Start_Timer()
{
	CreateTimer(GetRandomFloat(WitchTimeMin, WitchTimeMax), Timer_SpawnAWitch, _, TIMER_FLAG_NO_MAPCHANGE);
	
	#if DEBUG
	PrintToChatAll("[l4d_witches]: Start_Timer. Min: %f, Max: %f", WitchTimeMin, WitchTimeMax);
	#endif
}

// Kill witches out of range, and return total count of witches on the map
//
int GetCountWitchesInRange()
{
	int i;
	bool bInRange;
	float WitchPos[3];
	float PlayerPos[3];
	float distance;
	int countWitchAlive;
	int index = -1;
	while( (index = FindEntityByClassname(index, "witch")) != -1 )
	{
		countWitchAlive++;
		if( WitchDistance > 0.0 )
		{
			GetEntPropVector(index, Prop_Send, "m_vecOrigin", WitchPos);
			
			bInRange = false;
			
			for( i = 1; i <= MaxClients; i++ )
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
				{
					GetClientAbsOrigin(i, PlayerPos);
					distance = GetVectorDistance(WitchPos, PlayerPos);
					if (distance < WitchDistance)
					{
						bInRange = true;
						break;
					}
				}
			}
			if( !bInRange )
			{
				AcceptEntityInput(index, "Kill");
				countWitchAlive--;
				countRoundWitch--;
			}
		}
	}
	
	#if DEBUG
	PrintToChatAll("[l4d_witches]: Alive witches: %i", countWitchAlive);
	#endif
	
	return countWitchAlive;
}

public Action Timer_SpawnAWitch(Handle timer)
{
	#if DEBUG
	PrintToChatAll("[l4d_witches]: Timer triggered");
	#endif

	if( runTimer )
	{
		if( maxCountWitchInRound > 0 && countRoundWitch >= maxCountWitchInRound )
		{
			return Plugin_Continue;
		}
		if( maxCountWitchAlive > 0 && countAliveWitch >= maxCountWitchAlive )
		{
			// after removing witches out of range, count is still max => restart the timer, otherwise, spawn new witch
			countAliveWitch = GetCountWitchesInRange();
			
			if( countAliveWitch >= maxCountWitchAlive )
			{
				Start_Timer();
				return Plugin_Continue;
			}
		}
		int anyclient = GetAnyClient();
		if( !anyclient )
		{
			Start_Timer();
			return Plugin_Continue;
		}
		bWitchSpawnByPlugin = true;
		
		#if DEBUG
		PrintToChatAll("[l4d_witches]: Try to spawn");
		#endif
		
		if( g_bLeft4dead2 )
		{
			SpawnCommand(anyclient, "z_spawn_old", "witch auto");
		}
		else {
			SpawnCommand(anyclient, "z_spawn", "witch auto");
		}
		
		bWitchSpawnByPlugin = false;
		Start_Timer();
	}
	return Plugin_Stop;
}


void SpawnCommand(int client, char[] command, char[] arguments)
{
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags &~ FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
}

int GetAnyClient()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			return i;
		}
	}
	return 0;
}