#pragma newdecls required
#include <sourcemod>
#include <l4d2util_infected>
#include <sdkhooks>

/* NOTES:
- Make bots/replacing players get hooked if they're currently pulled (bot_replace, player_replace)
- Check for Capper on OnNextFrame on Tongue Release Event for additional scenario?
- No support for more than 1 smoker. (Add?)
*/

bool bLateLoad;
bool bPlayerPulled[MAXPLAYERS + 1];
ConVar convarTongueDelayTank;
ConVar convarTongueDelaySurvivor;
float fTongueDelayTank;
float fTongueDelaySurvivor;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLateLoad = late;

	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "Tongue Timer",
	author = "Sir",
	description = "Modify the Smoker's tongue ability timer in certain scenarios.",
	version = "1.2",
	url = "Nope"
}

public void OnPluginStart()
{
	// ConVars
	convarTongueDelayTank = CreateConVar("l4d2_tongue_delay_tank", "8.0", "How long of a cooldown does the Smoker get on a quick clear by Tank punch/rock? (Vanilla = ~0.5s)");
	convarTongueDelaySurvivor = CreateConVar("l4d2_tongue_delay_survivor", "4.0", "How long of a cooldown does the Smoker get on a quick clear by Survivors? (Vanilla = ~0.5s)");
	fTongueDelayTank = convarTongueDelayTank.FloatValue;
	fTongueDelaySurvivor = convarTongueDelaySurvivor.FloatValue;
	convarTongueDelayTank.AddChangeHook(ConvarChanged);
	convarTongueDelaySurvivor.AddChangeHook(ConvarChanged);

	// Events
	HookEvent("round_start", Event_TongueRelease)
	HookEvent("player_bot_replace", Event_Replace);
	HookEvent("bot_player_replace", Event_Replace);
	HookEvent("tongue_grab", Event_TongueGrab);
	HookEvent("tongue_release", Event_TongueRelease);
	HookEvent("tongue_pull_stopped", Event_TonguePullStopped);

	if (bLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i)) OnClientPutInServer(i);
		}
	}
}

// ----------------------------------------------
//             SDKHOOKS STUFF
// ----------------------------------------------
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!IsValidClient(victim)) return Plugin_Continue;
	if (!IsValidClient(attacker)) return Plugin_Continue;
	if (GetClientTeam(victim) != 2) return Plugin_Continue;
	if (GetClientTeam(attacker) != 3) return Plugin_Continue;
	if (!bPlayerPulled[victim]) return Plugin_Continue;
	if (GetEntProp(attacker, Prop_Send, "m_zombieClass") != 8) return Plugin_Continue;

	// Find and Store smoker.
	int iSmoker = FindSmoker();
	ClearPulls();
	if (iSmoker == 0) return Plugin_Continue;

	float time = GetGameTime();
	float timestamp;
	float duration;

	// Couldn't retrieve the ability timer.
	if (!GetInfectedAbilityTimer(iSmoker, timestamp, duration)) return Plugin_Continue;

	// Duration will be used as the new "m_timestamp"
	// If the smoker's pull delay is already longer than what we want it to be, don't bother.
	duration = time + fTongueDelayTank;
	if (duration > timestamp) 
	{
		SetInfectedAbilityTimer(iSmoker, duration, fTongueDelayTank);
	}
	return Plugin_Continue;
}

// ----------------------------------------------
//
//                    EVENTS
//
// ----------------------------------------------
public void Event_TongueGrab(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if (IsValidClient(victim) && GetClientTeam(victim) == 2)
	{
		bPlayerPulled[victim] = true;
	}
}

public void Event_TonguePullStopped(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	int smoker = GetClientOfUserId(event.GetInt("smoker"));

	if (IsValidClient(victim) && IsValidAliveSmoker(smoker) && GetClientTeam(victim) == 2)
	{
		RequestFrame(OnSmokerSurvivorClear, smoker);
	}
}

public void Event_TongueRelease(Event event, const char[] name, bool dontBroadcast)
{
	RequestFrame(OnNextFrame);
}

public void Event_Replace(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));
	int player = GetClientOfUserId(event.GetInt("player"));

	// Bot replaced a player.
	if (StrEqual(name, "player_bot_replace", false))
	{
		if (bPlayerPulled[player])
		{
			bPlayerPulled[bot] = true;
			bPlayerPulled[player] = false;
		}
	}
	// Player replaced a bot.
	else if (bPlayerPulled[bot])
	{
		bPlayerPulled[player] = true;
		bPlayerPulled[bot] = false;
	}
}

public void ClearPulls()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		bPlayerPulled[i] = false;
	}
}


// ----------------------------------------------
//
//             REQUESTFRAMES (Next Frame)
//
// ----------------------------------------------
void OnNextFrame(any victim)
{
	ClearPulls();
}

public void OnSmokerSurvivorClear(any smoker)
{
	if (IsValidAliveSmoker(smoker))
	{
		float time = GetGameTime();
		float timestamp;
		float duration;

		// Couldn't retrieve the ability timer.
		if (!GetInfectedAbilityTimer(smoker, timestamp, duration)) return;

		// Duration will be used as the new "m_timestamp"
		// If the smoker's pull delay is already longer than what we want it to be, don't bother.
		duration = time + fTongueDelaySurvivor;

		if (duration > timestamp) 
		{
			SetInfectedAbilityTimer(smoker, duration, fTongueDelaySurvivor);
		}
	}
}

// ----------------------------------------------
//
//                 CONVARS
//
// ----------------------------------------------
public void ConvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	fTongueDelayTank = convarTongueDelayTank.FloatValue;
	fTongueDelaySurvivor = convarTongueDelaySurvivor.FloatValue;
}

// ----------------------------------------------
//
//                 STOCKS 
//
// ----------------------------------------------
bool IsValidClient(int client)
{ 
	if (client <= 0
		|| client > MaxClients
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
	) {
		return false;
	}
	return true;
}

bool IsValidAliveSmoker(int client)
{
	if (!IsValidClient(client)
		|| GetClientTeam(client) != 3
	) {
		return false; 
	}
	return GetEntProp(client, Prop_Send, "m_zombieClass") == 1; 
}

int FindSmoker()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidAliveSmoker(i))
		{
			return i;
		}
	}
	return 0;
}
