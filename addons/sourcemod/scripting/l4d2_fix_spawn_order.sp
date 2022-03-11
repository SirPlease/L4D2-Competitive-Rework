#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo = 
{
	name = "L4D2 Proper Sack Order",
	author = "Sir, Forgetest",
	description = "Finally fix that pesky spawn rotation not being reliable",
	version = "2.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

// Array
ArrayList g_SpawnsArray;

bool bLive;

// Get dem Cvars
ConVar hLimits[SI_MAX_SIZE];
int iLimits[SI_MAX_SIZE];
int dominators;

ConVar hDebug;

/* These class numbers are the same ones used internally in L4D2 */
enum /*SIClass*/
{
	SI_None=0,
	SI_Smoker=1,
	SI_Boomer,
	SI_Hunter,
	SI_Spitter,
	SI_Jockey,
	SI_Charger,
	SI_Witch,
	SI_Tank,
	
	SI_MAX_SIZE
};

stock const char g_sSIClassNames[SI_MAX_SIZE][] = 
{	"", "Smoker", "Boomer", "Hunter", "Spitter", "Jockey", "Charger", "Witch", "Tank" };

public void OnPluginStart()
{
	// Events
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea);

	hDebug = CreateConVar("sackorder_debug", "0", "Debuggin the plugin.", FCVAR_SPONLY|FCVAR_HIDDEN, true, 0.0, true, 1.0);

	// Array
	g_SpawnsArray = new ArrayList();

	char buffer[64];
	for (int i = SI_Smoker; i <= SI_Charger; ++i)
	{
		FormatEx(buffer, sizeof(buffer), "%c%s", CharToLower(g_sSIClassNames[i][0]), g_sSIClassNames[i][1]);
		Format(buffer, sizeof(buffer), "z_versus_%s_limit", buffer);
		hLimits[i] = FindConVar(buffer);
	}
	
	RegConsoleCmd("sm_uei", uei);
}

Action uei(int a, int b)
{
	for (int i = 0; i < g_SpawnsArray.Length; ++i)
	{
		PrintToChat(a, g_sSIClassNames[g_SpawnsArray.Get(i)]);
	}
	return Plugin_Handled;
}

public void OnConfigsExecuted()
{
	dominators = 53;
	ConVar hDominators = FindConVar("l4d2_dominators");
	if (hDominators != null) dominators = hDominators.IntValue;
}

// Events
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_SpawnsArray.Clear();
	bLive = false;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_SpawnsArray.Clear();
	bLive = false;
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (!bLive)
		return;
	
	int oldteam = event.GetInt("oldteam");
	if (oldteam != 3 || oldteam == event.GetInt("team"))
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || IsFakeClient(client))
		return;
	
	if (!GetEntProp(client, Prop_Send, "m_isGhost"))
		return;
	
	int SI = GetEntProp(client, Prop_Send, "m_zombieClass");
	if (IsClassAcceptable(SI, client))
	{
		QueueSI(SI, true);
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!bLive)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || IsFakeClient(client))
		return;
	
	if (GetClientTeam(client) != 3)
		return;
	
	int SI = GetEntProp(client, Prop_Send, "m_zombieClass");
	if (IsClassAcceptable(SI, client))
	{
		QueueSI(SI, false);
	}
}

public void L4D_OnEnterGhostState(int client)
{
	PrintDebug("L4D_OnEnterGhostState: IsGhost = %s", GetEntProp(client, Prop_Send, "m_isGhost") ? "true" : "false");
	
	if (GetEntProp(client, Prop_Send, "m_isGhost"))
	{
		int SI = PopQueuedSI(client);
		if (SI != SI_None)
		{
			L4D_SetClass(client, SI);
		}
	}
}

void Event_PlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	FillQueue();
	bLive = true;
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && !IsFakeClient(client) && GetClientTeam(client) == 3)
	{
		// Looks like resource data updates post changes happen, good.
		int resource = L4D_GetResourceEntity();
		
		if (GetEntProp(resource, Prop_Send, "m_bAlive", 4, client))
		{
			int SI = GetEntProp(resource, Prop_Send, "m_zombieClass", _, client);
			if (IsClassAcceptable(SI, client))
			{
				QueueSI(SI, false);
			}
		}
	}
}

//--------------------------------------------------------------------------------- Stocks & Such

void QueueSI(int SI, bool front, int skip_client = -1)
{
	if (front)
	{
		g_SpawnsArray.ShiftUp(0);
		g_SpawnsArray.Set(0, SI);
	}
	else
	{
		g_SpawnsArray.Push(SI);
	}
	
	PrintDebug("\x04[DEBUG] \x01Queuing (\x05%s\x01) to \x04%s", g_sSIClassNames[SI], front ? "the front" : "the end");
}

int PopQueuedSI(int client)
{
	int size = g_SpawnsArray.Length;
	if (!size)
		return SI_None;
	
	int QueuedSI = g_SpawnsArray.Get(0);
	
	int loop_remain = size - 1;
	while (loop_remain > 0 && IsClassOverLimit(QueuedSI, client))
	{
		PrintDebug("\x04[DEBUG] \x01Popping (\x05%s\x01) but \x03over limit", g_sSIClassNames[QueuedSI]);
		g_SpawnsArray.Erase(0);
		QueueSI(QueuedSI, false);
		
		QueuedSI = g_SpawnsArray.Get(0);
		
		--loop_remain;
	}
	
	PrintDebug("\x04[DEBUG] \x01Popped (\x05%s\x01) after \x04%i \x01tries", g_sSIClassNames[QueuedSI], size - loop_remain);
	
	g_SpawnsArray.Erase(0);
	return QueuedSI;
}

void FillQueue()
{
	int zombies[SI_MAX_SIZE] = {0};
	CollectZombies(zombies);
	
	char classString[255] = "";
	for (int i = SI_Smoker; i <= SI_Charger; ++i)
	{
		for (int j = 0; j < (iLimits[i] = hLimits[i].IntValue) - zombies[i]; ++j)
		{
			g_SpawnsArray.Push(i);
			StrCat(classString, sizeof(classString), g_sSIClassNames[i]);
			StrCat(classString, sizeof(classString), ", ");
		}
	}
	
	int idx = strlen(classString) - 2;
	if (idx < 0) idx = 0;
	classString[idx] = '\0';
	PrintDebug("\x04[DEBUG] \x01Filled queue (%s)", classString);
}

bool IsClassAcceptable(int SI, int skip_client)
{
	if (SI >= SI_Smoker && SI <= SI_Charger)
	{
		int counts[SI_MAX_SIZE] = {0};
		
		// NOTE: We're checking after player actually spawns, it's necessary to ignore his class.
		CollectZombies(counts, skip_client);
		CollectQueuedZombies(counts);
		
		if (counts[SI] < iLimits[SI])
			return true;
	}
	
	PrintDebug("\x04[DEBUG] \x04Unexpected class \x01(\x05%s\x01)", g_sSIClassNames[SI]);
	return false;
}

/**
 * Check if specific class is over limit based on limit convars and dominator flags.
 */
bool IsClassOverLimit(int SI, int skip_client)
{
	if (!hLimits[SI])
		return false;
	
	int counts[SI_MAX_SIZE] = {0};
	
	// NOTE: We're checking after player actually spawns, it's necessary to ignore his class.
	CollectZombies(counts, skip_client);
	
	if (counts[SI] >= hLimits[SI].IntValue)
		return true;
	
	if (!IsDominator(SI))
		return false;
	
	int dominatorCount = 0;
	for (int i = SI_Smoker; i <= SI_Charger; ++i)
		if (IsDominator(i)) dominatorCount += counts[i];
	
	return dominatorCount > 2;
}

/**
 * Check if specific class is customized dominator.
 */
bool IsDominator(int SI)
{
	return !!(dominators & (1 << (SI-1)));
}

/**
 * Collect info of player zombies recorded by resource entity.
 */
int CollectZombies(int zombies[SI_MAX_SIZE], int skip_client = -1)
{
	int count = 0;
	int resource = L4D_GetResourceEntity();
	
	char classString[255] = "";
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (i != skip_client && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			++zombies[GetEntProp(i, Prop_Send, "m_zombieClass")];
			++count;
			StrCat(classString, sizeof(classString), g_sSIClassNames[GetEntProp(i, Prop_Send, "m_zombieClass")]);
			StrCat(classString, sizeof(classString), ", ");
		}
	}
	
	int idx = strlen(classString) - 2;
	if (idx < 0) idx = 0;
	classString[idx] = '\0';
	PrintDebug("\x04[DEBUG] \x01Collect zombies (%s)", classString);
	
	return count;
}

int CollectQueuedZombies(int zombies[SI_MAX_SIZE])
{
	int size = g_SpawnsArray.Length;
	
	for (int i = 0; i < size; ++i)
	{
		++zombies[g_SpawnsArray.Get(i)];
	}
	
	return size;
}

stock void PrintDebug(const char[] format, any ...)
{
	if (hDebug.BoolValue)
	{
		char msg[255];
		VFormat(msg, sizeof(msg), format, 2);
		PrintToChatAll("%s", msg);
	}
}