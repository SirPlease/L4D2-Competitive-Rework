#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_VERSION "2.6.1"

public Plugin myinfo = 
{
	name = "L4D2 Proper Sack Order",
	author = "Sir, Forgetest",
	description = "Finally fix that pesky spawn rotation not being reliable",
	version = PLUGIN_VERSION,
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

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

// Array
ArrayList g_SpawnsArray;

bool bLive;

// Get dem Cvars
ConVar hLimits[SI_MAX_SIZE];
int iLimits[SI_MAX_SIZE];
int dominators;

ConVar hDebug;

methodmap PlayerResource {
	public PlayerResource() {
		return view_as<PlayerResource>(L4D_GetResourceEntity());
	}
	public int QueryZombieClass(int client) {
		return GetEntProp(view_as<int>(this), Prop_Send, "m_zombieClass", _, client);
	}
	public int QueryTeamNum(int client) {
		return GetEntProp(view_as<int>(this), Prop_Send, "m_iTeam", _, client);
	}
	public bool WasGhost(int client) {
		return !!GetEntProp(view_as<int>(this), Prop_Send, "m_isGhost", _, client);
	}
	public bool WasAlive(int client) {
		return !!GetEntProp(view_as<int>(this), Prop_Send, "m_bAlive", _, client);
	}
}
PlayerResource g_Resource;

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
		FormatEx(buffer, sizeof(buffer), "z_versus_%c%s_limit", CharToLower(g_sSIClassNames[i][0]), g_sSIClassNames[i][1]);
		hLimits[i] = FindConVar(buffer);
	}
}

public void OnConfigsExecuted()
{
	dominators = 53;
	ConVar hDominators = FindConVar("l4d2_dominators");
	if (hDominators != null) dominators = hDominators.IntValue;
}

// Clean slates
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_Resource = PlayerResource();
	g_SpawnsArray.Clear();
	bLive = false;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_SpawnsArray.Clear();
	bLive = false;
}

void Event_PlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	FillQueue();
	bLive = true;
}

//--------------------------------------------------------------------------------- Player Actions
//
// Basic strategy:
//   1. Zombie classes is handled by a queue: pop the beginning, push to the end.
//   2. Return zombie class, based on the player state: ghost to the beginning, materialized to the end.
//

/**
 * Queue the class of whom switched team alive, to the front if ghost, to the end if materialized.
 */
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
	
	if (!IsPlayerAlive(client))
		return;
	
	int SI = GetEntProp(client, Prop_Send, "m_zombieClass");
	if (IsAbleToQueue(SI, client))
	{
		QueueSI(SI, !!GetEntProp(client, Prop_Send, "m_isGhost"));
	}
}

/**
 * Queue the class of whom died to the end.
 */
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
	if (IsAbleToQueue(SI, client))
	{
		QueueSI(SI, false);
	}
}

/**
 * Save the class of whom becomes the tank, to the front if ghost, to the end if materialized.
 */
void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && !IsFakeClient(client) && GetClientTeam(client) == 3)
	{
		// Looks like resource data updates post changes happen, good.
		if (g_Resource.WasAlive(client))
		{
			int SI = g_Resource.QueryZombieClass(client);
			if (IsAbleToQueue(SI, client))
			{
				QueueSI(SI, g_Resource.WasGhost(client));
			}
		}
	}
}

/**
 * Give spawned player an SI from queue.
 */
public void L4D_OnEnterGhostState(int client)
{
	// NOTE:
	// Left4DHooks 1.94 blocks post forwards if pre-hooks get superceded.
	// The following check will be unnecessary post-update.
	if (!GetEntProp(client, Prop_Send, "m_isGhost"))
		return;
	
	// 1. Not respawning
	// 2. Weird exception that instant spawn is offered if:
	//	   - First switch to Survivors during respawn count-down.
	//	   - Then switch back when the count-down expires.
	if (!g_Resource.WasAlive(client) || g_Resource.QueryTeamNum(client) == 2)
	{
		int SI = PopQueuedSI(client);
		if (SI != SI_None)
		{
			L4D_SetClass(client, SI);
		}
	}
}

//--------------------------------------------------------------------------------- Stocks & Such

/**
 * Queue an SI to the front/end.
 */
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
	
	PrintDebug("\x04[DEBUG] \x01Queuing (\x05%s\x01) to \x04%s", g_sSIClassNames[SI], front ? "the front" : "the end");
}

/**
 * Pop an SI from queue that is under limit.
 */
int PopQueuedSI(int skip_client)
{
	int size = g_SpawnsArray.Length;
	if (!size)
		return SI_None;
	
	// Loop through queue to get a valid class.
	for (int i = 0; i < size; ++i)
	{
		int QueuedSI = g_SpawnsArray.Get(i);
		if (!IsClassOverLimit(QueuedSI, skip_client))
		{
			g_SpawnsArray.Erase(i);
			PrintDebug("\x04[DEBUG] \x01Popped (\x05%s\x01) after \x04%i \x01tries", g_sSIClassNames[QueuedSI], i+1);
			return QueuedSI;
		}
		else
		{
			PrintDebug("\x04[DEBUG] \x01Popping (\x05%s\x01) but \x03over limit", g_sSIClassNames[QueuedSI]);
		}
	}
	
	PrintDebug("\x04[DEBUG] \x04Failed to pop queued SI! \x01(size = \x05%i\x01)", size);
	return SI_None;
}

/**
 * Fill up the spawn queue with available SIs.
 *
 * TODO:
 *   Ensure it begins with remaining first hit classes in case the Infected Team isn't full?
 * NOTE:
 *   Vanilla selects a random index as the beginning class of first hit
 *   (i.e. if random = 4  then first hit = Spitter,Jockey,Charger,Smoker)
 */
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

/**
 * Check if specific class can be queued based on initial SI pool.
 *
 * NOTE:
 *   Static limits used here.
 */
bool IsAbleToQueue(int SI, int skip_client)
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
	
	PrintDebug("\x04[DEBUG] \x04Unexpected class \x01(\x05%s\x01)", SI == -1 ? "INVALID" : g_sSIClassNames[SI]);
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
 * Collect zombie classes.
 */
int CollectZombies(int zombies[SI_MAX_SIZE], int skip_client = -1)
{
	int count = 0;
	
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

/**
 * Collect queued SI classes.
 */
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
