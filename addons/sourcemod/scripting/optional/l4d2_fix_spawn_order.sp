#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>
#include <left4dhooks>
#include <l4d2util_infected>

#define PLUGIN_VERSION "4.4.3"

public Plugin myinfo = 
{
	name = "[L4D2] Proper Sack Order",
	author = "Sir, Forgetest",
	description = "Finally fix that pesky spawn rotation not being reliable",
	version = PLUGIN_VERSION,
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

enum
{
	OverLimit_OK = 0,
	OverLimit_Dominator,
	OverLimit_Class,
	
	MAX_OverLimitReason
};

stock const char g_sOverLimitReason[MAX_OverLimitReason][] = {
	"", "Dominator limit", "Class limit"
};

/* These class numbers are the same ones used internally in L4D2 */

#define SI_GENERIC_BEGIN L4D2Infected_Smoker
#define SI_GENERIC_END L4D2Infected_Witch
#define SI_MAX_SIZE L4D2Infected_Size
#define SI_None L4D2Infected_Common

ArrayList g_SpawnsArray;

bool g_isLive;

ConVar g_cvSILimits[SI_MAX_SIZE];
int g_iInitialSILimits[SI_MAX_SIZE];
int g_Dominators;

int g_iStoredClass[MAXPLAYERS+1];
bool g_bPlayerSpawned[MAXPLAYERS+1];

ConVar g_cvDebug;
ConVar director_allow_infected_bots, z_max_player_zombies;

public void OnPluginStart()
{
	LoadTranslations("l4d2_fix_spawn_order.phrases");
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	HookEvent("versus_round_start", Event_RealRoundStart);
	HookEvent("scavenge_round_start", Event_RealRoundStart);
	
	InitSILimits();
	g_cvDebug = CreateConVar("sackorder_debug", "0", "Debuggin the plugin.", FCVAR_SPONLY|FCVAR_HIDDEN, true, 0.0, true, 1.0);
	
	director_allow_infected_bots = FindConVar("director_allow_infected_bots");
	z_max_player_zombies = FindConVar("z_max_player_zombies");
	
	g_SpawnsArray = new ArrayList();
}

void InitSILimits()
{
	char buffer[64];
	for (int i = SI_GENERIC_BEGIN; i < SI_GENERIC_END; ++i)
	{
		FormatEx(buffer, sizeof(buffer), "z_versus_%c%s_limit", CharToLower(L4D2_InfectedNames[i][0]), L4D2_InfectedNames[i][1]);
		g_cvSILimits[i] = FindConVar(buffer);
	}
}

public void OnConfigsExecuted()
{
	g_Dominators = 53;
	ConVar hDominators = FindConVar("l4d2_dominators");
	if (hDominators != null) g_Dominators = hDominators.IntValue;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ToggleEvents(false);
	g_SpawnsArray.Clear();
	g_isLive = false;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ToggleEvents(false);
	g_SpawnsArray.Clear();
	g_isLive = false;
}

void Event_RealRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!L4D_HasPlayerControlledZombies())
		return;
	
	if (g_isLive)
		return;
	
	ToggleEvents(true);
	FillQueue();
	g_isLive = true;
}

void ToggleEvents(bool isEnable)
{
	static bool hasEnabled = false;
	
	if (isEnable == hasEnabled)
		return;
	
	if (isEnable)
	{
		HookEvent("player_team", Event_PlayerTeam);
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("bot_player_replace", Event_BotPlayerReplace);
		HookEvent("player_bot_replace", Event_PlayerBotReplace);
		
		hasEnabled = true;
	}
	else
	{
		UnhookEvent("player_team", Event_PlayerTeam);
		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("bot_player_replace", Event_BotPlayerReplace);
		UnhookEvent("player_bot_replace", Event_PlayerBotReplace);
		
		hasEnabled = false;
	}
}

//--------------------------------------------------------------------------------- Player Actions
//
// Basic strategy:
//   1. Zombie classes is handled by a queue: pop the beginning, push to the end.
//   2. Return zombie class, based on the player state: ghost to the beginning, materialized to the end.
//

public Action L4D_OnMaterializeFromGhostPre(int client)
{
	PrintDebug("{olive}%N {olive}materialized {default}as ({green}%s{default})", client, L4D2_InfectedNames[GetInfectedClass(client)]);

	g_bPlayerSpawned[client] = true;
	return Plugin_Continue;
}

public void L4D_OnMaterializeFromGhost_PostHandled(int client)
{
	PrintDebug("{olive}%N {olive}got de-materialized because of other plugins' handling.", client);
	
	g_bPlayerSpawned[client] = false;
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int team = event.GetInt("team");
	int oldteam = event.GetInt("oldteam");
	if (team == oldteam)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
		return;
	
	if (team == 3)
	{
		if (!director_allow_infected_bots.BoolValue)
			return;
		
		if (IsFakeClient(client))
			return;
		
		if (GetSICount(false) + 1 <= z_max_player_zombies.IntValue)
			return;
		
		PrintDebug("Infected Team is {green}going over capacity {default}after {olive}%N {default}joined", client);
		
		int lastUserId = 0;
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
			
			if (!IsFakeClient(i))
				continue;
			
			if (GetClientTeam(i) != 3)
				continue;
			
			if (GetInfectedClass(i) == L4D2Infected_Tank)
				continue;
			
			int userid = GetClientUserId(i);
			if (lastUserId < userid)
				lastUserId = userid;
		}
		
		if (lastUserId > 0)
		{
			int lastBot = GetClientOfUserId(lastUserId);
			
			PrintDebug("{olive}%N is selected to cull", lastBot);
			ForcePlayerSuicide(lastBot);
		}
	}
	else if (oldteam == 3)
	{
		if (!IsPlayerAlive(client))
			return;
		
		PrintDebug("{olive}%N {default}left Infected Team {default}as ({green}%s{default})", client, L4D2_InfectedNames[GetInfectedClass(client)]);
		
		QueuePlayerSI(client);
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
		return;
	
	if (GetClientTeam(client) != 3)
		return;
	
	PrintDebug("{olive}%N {default}died {default}as ({green}%s{default})", client, L4D2_InfectedNames[GetInfectedClass(client)]);
	
	QueuePlayerSI(client);
}

void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	HandlePlayerReplace(GetClientOfUserId(event.GetInt("player")), GetClientOfUserId(event.GetInt("bot")));
}

void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	HandlePlayerReplace(GetClientOfUserId(event.GetInt("bot")), GetClientOfUserId(event.GetInt("player")));
}

void HandlePlayerReplace(int replacer, int replacee)
{
	// reported a compatibility issue with confoglcompmod BotKick module
	// well just dont use it which blocks client connection instead of slaying
	if (!replacer || !replacee || !IsClientInGame(replacer) || !IsClientInGame(replacee))
		return;
	
	if (GetClientTeam(replacer) != 3)
		return;
	
	PrintDebug("{olive}%N {default}replaced {olive}%N {default}as ({green}%s{default})", replacer, replacee, L4D2_InfectedNames[GetInfectedClass(replacer)]);
	
	if (GetInfectedClass(replacer) == L4D2Infected_Tank && !IsFakeClient(replacer))
	{
		PrintDebug("{olive}%N {default}({green}%s{default}) {default}replaced an {green}AI Tank", replacer, L4D2_InfectedNames[g_iStoredClass[replacer]]);
		
		QueuePlayerSI(replacer);
		return;
	}
	
	g_iStoredClass[replacer] = g_iStoredClass[replacee];
	g_bPlayerSpawned[replacer] = g_bPlayerSpawned[replacee]; // what if replacing ghost? :(
	
	g_iStoredClass[replacee] = SI_None;
	g_bPlayerSpawned[replacee] = false;
	
	if ( !IsPlayerAlive(replacer) // compatible with "l4d2_nosecondchances"
	  || (IsFakeClient(replacer) && !director_allow_infected_bots.BoolValue) ) 
	{
		QueuePlayerSI(replacer);
	}
}

public void L4D_OnReplaceTank(int tank, int newtank)
{
	if (newtank <= 0 || newtank > MaxClients)
		return;
	
	if (!IsClientInGame(newtank) || !IsPlayerAlive(newtank))
		return;
	
	if (GetClientTeam(newtank) != 3)
		return;
	
	PrintDebug("{olive}%N {default}({green}%s{default}) {default}is going to replace {olive}%N{default}'s {green}Tank", newtank, L4D2_InfectedNames[GetInfectedClass(newtank)], tank);
	
	QueuePlayerSI(newtank);
}

/**
 * Helper to check if the player entering ghost state has committed a despawn.
 */
bool isCulling = false;
public Action L4D_OnEnterGhostStatePre(int client)
{
	static int s_iOffs_m_bPZAbortedControl = -1;
	if (s_iOffs_m_bPZAbortedControl == -1)
		s_iOffs_m_bPZAbortedControl = FindSendPropInfo("CTerrorPlayer", "m_bSurvivorGlowEnabled") + 1;
	
	isCulling = GetEntData(client, s_iOffs_m_bPZAbortedControl, 1) != 0;
	
	return Plugin_Continue;
}

/**
 * Give spawned player an SI from queue and/or remember what their class is.
 */
public void L4D_OnEnterGhostState(int client)
{
	int SI = GetInfectedClass(client);
	
	// Don't mess up when player despawns or round restarts.
	if (!isCulling && g_isLive)
	{
		int temp = PopQueuedSI(client);
		if (temp != SI_None)
		{
			SI = temp;
			L4D_SetClass(client, SI);
		}
	}
	
	PrintDebug("%N %s {default}as ({green}%s{default})", client, isCulling ? "{olive}respawned" : "{default}spawned", L4D2_InfectedNames[SI]);
	
	g_iStoredClass[client] = SI;
	g_bPlayerSpawned[client] = false;
}

//--------------------------------------------------------------------------------- Bot Spawning
//
// Change the bot's class on spawn to the one popped from queue
//

int g_ZombieClass = SI_None;
public Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3])
{
	PrintDebug("Director attempting to spawn ({green}%s{default})", L4D2_InfectedNames[zombieClass]);
	
	if (!director_allow_infected_bots.BoolValue)
		return Plugin_Continue;
	
	if (GetSICount(false) + 1 > z_max_player_zombies.IntValue)
	{
		PrintDebug("Blocking director spawn for {lightgreen}going over player limit{default}.");
		return Plugin_Handled;
	}
	
	g_ZombieClass = PopQueuedSI(-1);
	if (g_ZombieClass == SI_None)
	{
		PrintDebug("Blocking director spawn for {green}running out of available SI{default}.");
		return Plugin_Handled;
	}
	
	zombieClass = g_ZombieClass;
	PrintDebug("Overriding director spawn to ({green}%s{default})", L4D2_InfectedNames[g_ZombieClass]);
	
	return Plugin_Changed;
}

public void L4D_OnSpawnSpecial_Post(int client, int zombieClass, const float vecPos[3], const float vecAng[3])
{
	PrintDebug("Director spawned a bot (expected {olive}%s{default}, got %s%s{default})", L4D2_InfectedNames[g_ZombieClass], g_ZombieClass == zombieClass ? "{olive}" : "{green}", L4D2_InfectedNames[zombieClass]);
	
	if (!director_allow_infected_bots.BoolValue)
		return;
	
	g_ZombieClass = SI_None;
	g_iStoredClass[client] = zombieClass;
	g_bPlayerSpawned[client] = true;
}

public void L4D_OnSpawnSpecial_PostHandled(int client, int zombieClass, const float vecPos[3], const float vecAng[3])
{
	PrintDebug("Director's spawn was {green}blocked {default}(expected {olive}%s{default}, got %s%s{default})", L4D2_InfectedNames[g_ZombieClass], g_ZombieClass == zombieClass ? "{olive}" : "{green}", L4D2_InfectedNames[zombieClass]);
	
	if (!director_allow_infected_bots.BoolValue)
		return;
	
	if (g_ZombieClass != SI_None)
	{
		QueueSI(g_ZombieClass, true);
		g_ZombieClass = SI_None;
	}
}

//--------------------------------------------------------------------------------- Stocks & Such

void QueuePlayerSI(int client)
{
	int SI = g_iStoredClass[client];
	if (IsAbleToQueue(SI, client))
	{
		QueueSI(SI, !g_bPlayerSpawned[client]);
	}
	
	g_iStoredClass[client] = SI_None;
	g_bPlayerSpawned[client] = false;
}

void QueueSI(int SI, bool front)
{
	if (front && g_SpawnsArray.Length)
	{
		g_SpawnsArray.ShiftUp(0);
		g_SpawnsArray.Set(0, SI);
	}
	else
	{
		g_SpawnsArray.Push(SI);
	}
	
	PrintDebug("Queuing ({olive}%s{default}) to {green}%s", L4D2_InfectedNames[SI], front ? "the front" : "the end");
}

int PopQueuedSI(int skip_client)
{
	int size = g_SpawnsArray.Length;
	if (!size)
		return SI_None;
	
	for (int i = 0; i < size; ++i)
	{
		int QueuedSI = g_SpawnsArray.Get(i);
		
		int status = IsClassOverLimit(QueuedSI, skip_client);
		if (status == OverLimit_OK)
		{
			g_SpawnsArray.Erase(i);
			PrintDebug("Popped ({olive}%s{default}) after {green}%i {default}%s", L4D2_InfectedNames[QueuedSI], i+1, i+1 > 1 ? "tries" : "try");
			return QueuedSI;
		}
		else
		{
			PrintDebug("Popping ({olive}%s{default}) but {lightgreen}over limit {default}({lightgreen}reason: %s{default})", L4D2_InfectedNames[QueuedSI], g_sOverLimitReason[status]);
		}
	}
	
	PrintDebug("{green}Failed to pop queued SI! {default}(size = {olive}%i{default})", size);
	return SI_None;
}

/**
 * TODO:
 *   Fill with the remaining first hit classes when the Infected Team isn't full?
 * NOTE:
 *   Director randomly picks a beginning index for the first hit
 *   i.e. if pick is 4, then first hit setup will be Spitter(4),Jockey(5),Charger(6),Smoker(1)
 */
void FillQueue()
{
	int zombies[SI_MAX_SIZE] = {0};
	CollectZombies(zombies);
	
	char classString[255] = "";
	for (int SI = SI_GENERIC_BEGIN; SI < SI_GENERIC_END; ++SI)
	{
		g_iInitialSILimits[SI] = g_cvSILimits[SI].IntValue;
		
		for (int j = 0; j < g_iInitialSILimits[SI] - zombies[SI]; ++j)
		{
			g_SpawnsArray.Push(SI);
			
			StrCat(classString, sizeof(classString), L4D2_InfectedNames[SI]);
			StrCat(classString, sizeof(classString), ", ");
		}
	}
	
	int idx = strlen(classString) - 2;
	if (idx < 0) idx = 0;
	classString[idx] = '\0';
	PrintDebug("Filled queue (%s)", classString);
}

/**
 * Check if specific class can be queued based on initial SI pool.
 *
 * NOTE:
 *   Static limits used here.
 */
bool IsAbleToQueue(int SI, int skip_client)
{
	if (SI >= SI_GENERIC_BEGIN && SI < SI_GENERIC_END)
	{
		int counts[SI_MAX_SIZE] = {0};
		
		// NOTE: We're checking after player actually spawns, it's necessary to ignore his class.
		CollectZombies(counts, skip_client);
		CollectQueuedZombies(counts);
		
		if (counts[SI] < g_iInitialSILimits[SI])
			return true;
	}
	
	PrintDebug("{green}Unexpected class {default}({olive}%s{default})", SI == -1 ? "INVALID" : L4D2_InfectedNames[SI]);
	return false;
}

/**
 * Check if specific class is over limit based on limit convars and dominator flags.
 *  1.	< class limit
 *  2a.	not dominator
 *  2b.	is dominator
 *  3b.	total dominators < 3
 *
 * NOTE:
 *   Dynamic limits used here.
 *
 * TODO: 
 *   No more redundant collecting zombies in the same frame?
 */
int IsClassOverLimit(int SI, int skip_client)
{
	if (!g_cvSILimits[SI])
		return OverLimit_OK;
	
	int counts[SI_MAX_SIZE] = {0};
	
	// NOTE: We're checking after player actually spawns, it's necessary to ignore his class.
	CollectZombies(counts, skip_client);
	
	if (counts[SI] >= g_cvSILimits[SI].IntValue)
		return OverLimit_Class;
	
	if (!IsDominator(SI))
		return OverLimit_OK;
	
	int dominatorCount = 0;
	for (int i = SI_GENERIC_BEGIN; i < SI_GENERIC_END; ++i)
		if (IsDominator(i)) dominatorCount += counts[i];
	
	if (dominatorCount >= 3)
		return OverLimit_Dominator;
	
	return OverLimit_OK;
}

bool IsDominator(int SI)
{
	return g_Dominators & (1 << (SI-1)) > 0;
}

int CollectZombies(int zombies[SI_MAX_SIZE], int skip_client = -1)
{
	int count = 0;
	
	char classString[255] = "";
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (i == skip_client)
			continue;
		
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if (GetClientTeam(i) != 3)
			continue;
		
		int SI = g_iStoredClass[i];
		if (SI == SI_None)
			continue;
		
		++zombies[SI];
		++count;
		StrCat(classString, sizeof(classString), L4D2_InfectedNames[SI]);
		StrCat(classString, sizeof(classString), ", ");
	}
	
	int idx = strlen(classString) - 2;
	if (idx < 0) idx = 0;
	classString[idx] = '\0';
	PrintDebug("Collect zombies (%s)", classString);
	
	return count;
}

int CollectQueuedZombies(int zombies[SI_MAX_SIZE])
{
	int size = g_SpawnsArray.Length;
	
	char classString[255] = "";
	for (int i = 0; i < size; ++i)
	{
		int SI = g_SpawnsArray.Get(i);
		
		++zombies[SI];
		StrCat(classString, sizeof(classString), L4D2_InfectedNames[SI]);
		StrCat(classString, sizeof(classString), ", ");
	}
	
	int idx = strlen(classString) - 2;
	if (idx < 0) idx = 0;
	classString[idx] = '\0';
	PrintDebug("Collect queued zombies (%s)", classString);
	
	return size;
}

int GetSICount(bool isHumanOnly = true)
{
	int count = 0;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i))
			continue;
		
		if (GetClientTeam(i) != 3)
			continue;
		
		if (IsFakeClient(i))
		{
			if (isHumanOnly)
				continue;
			
			if (GetInfectedClass(i) == L4D2Infected_Tank)
				continue;
			
			if (!IsPlayerAlive(i))
				continue;
		}
		
		count++;
	}
	
	return count;
}

stock void PrintDebug(const char[] format, any ...)
{
	if (g_cvDebug.BoolValue)
	{
		char msg[255];
		VFormat(msg, sizeof(msg), format, 2);
		CPrintToChatAll("%t", "L4D2FixSpawnOrder_DebugMessage", msg);
	}
}
