#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <left4dhooks>
#include <sourcemod>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define TEAM_INFECTED 3
#define Z_TANK        8

bool
	bTankAlive,
	bHooked;

int
	iDistance;

ConVar
	cvar_noTankRush,
	cvar_SpawnEnableSound,
	cvar_unfreezeSaferoom,
	cvar_unfreezeAI;

public Plugin myinfo =
{
	name        = "L4D2 No Tank Rush",
	author      = "Jahze, vintik, devilesk, Sir",
	version     = "1.1.4",
	description = "Stops distance points accumulating whilst the tank is alive, with the option of unfreezing distance on reaching the Saferoom"
};

public void OnPluginStart()
{
	LoadTranslations("tank_rush.phrases");

	// ConVars
	cvar_noTankRush       = CreateConVar("l4d_no_tank_rush", "1", "Prevents survivor team from accumulating points whilst the tank is alive", _, true, 0.0, true, 1.0);
	cvar_unfreezeSaferoom = CreateConVar("l4d_no_tank_rush_unfreeze_saferoom", "0", "Unfreezes Distance if a Survivor makes it to the end saferoom while the Tank is still up.", _, true, 0.0, true, 1.0);
	cvar_unfreezeAI       = CreateConVar("l4d_no_tank_rush_unfreeze_ai", "0", "Unfreeze distance if the Tank goes AI", _, true, 0.0, true, 1.0);
	cvar_SpawnEnableSound = CreateConVar("l4d_no_tank_rush_spawn_sound", "0", "Turn on the sound when spawning a tank", _, true, 0.0, true, 1.0);

	// ChangeHook
	cvar_noTankRush.AddChangeHook(NoTankRushChange);

	if (cvar_noTankRush.BoolValue)
	{
		PluginEnable();
	}
}

public void OnPluginEnd()
{
	bHooked = false;
	PluginDisable();
}

public void OnMapStart()
{
	PrecacheSound("ui/pickup_secret01.wav");
	bTankAlive = false;
}

void PluginEnable()
{
	if (!bHooked)
	{
		HookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);    // no params pls
		HookEvent("tank_spawn", TankSpawn, EventHookMode_PostNoCopy);      // no params pls
		HookEvent("player_death", PlayerDeath, EventHookMode_Post);
		HookEvent("player_bot_replace", OnTankGoneAI);

		if (IsTankActuallyInPlay())
		{
			FreezePoints();
		}
		bHooked = true;
	}
}

public Action L4D2_OnEndVersusModeRound(bool countSurvivors)
{
	if (cvar_unfreezeSaferoom.IntValue == 1 && IsTankActuallyInPlay() && GetUprightSurvivors() > 0)
	{
		UnFreezePoints(true, 2);
	}

	return Plugin_Continue;
}

void PluginDisable()
{
	if (bHooked)
	{
		UnhookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);    // no params pls
		UnhookEvent("tank_spawn", TankSpawn, EventHookMode_PostNoCopy);      // no params pls
		UnhookEvent("player_death", PlayerDeath, EventHookMode_Post);
		UnhookEvent("player_bot_replace", OnTankGoneAI, EventHookMode_Post);

		bHooked = false;
	}

	UnFreezePoints();
}

public void OnTankGoneAI(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!cvar_unfreezeAI.BoolValue)
	{
		return;
	}

	int iNewTank = GetClientOfUserId(hEvent.GetInt("bot"));

	if (GetClientTeam(iNewTank) == TEAM_INFECTED && GetEntProp(iNewTank, Prop_Send, "m_zombieClass") == Z_TANK)
	{
		UnFreezePoints();
	}
}

public void NoTankRushChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 0)
	{
		PluginDisable();
	}
	else {
		PluginEnable();
	}
}

public void RoundStart(Event hEvent, const char[] eName, bool dontBroadcast)
{
	if (InSecondHalfOfRound())
	{
		UnFreezePoints();
	}
}

public void TankSpawn(Event hEvent, const char[] eName, bool dontBroadcast)
{
	FreezePoints(true);
}

public void PlayerDeath(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (client > 0 && IsTank(client))
	{
		CreateTimer(0.1, CheckForTanksDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnClientDisconnect(int client)
{
	if (IsTank(client))
	{
		CreateTimer(0.1, CheckForTanksDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action CheckForTanksDelay(Handle timer)
{
	if (!IsTankActuallyInPlay())
	{
		UnFreezePoints(true);
	}

	return Plugin_Stop;
}

void FreezePoints(bool show_message = false)
{
	if (!bTankAlive)
	{
		iDistance = L4D_GetVersusMaxCompletionScore();
		if (show_message)
		{
			CPrintToChatAll("%t %t", "Tag", "freeze");
			if (cvar_SpawnEnableSound.BoolValue)
			{
				EmitSoundToAll("ui/pickup_secret01.wav");
			}
		}

		L4D_SetVersusMaxCompletionScore(0);
		bTankAlive = true;
	}
}

void UnFreezePoints(bool show_message = false, int iMessage = 1)
{
	if (bTankAlive)
	{
		if (show_message)
		{
			if (iMessage == 1)
			{
				CPrintToChatAll("%t %t", "Tag", "unfreeze");
			}
			else {
				CPrintToChatAll("%t %t", "Tag", "saferoom");
			}
		}
		L4D_SetVersusMaxCompletionScore(iDistance);
		bTankAlive = false;
	}
}

int GetUprightSurvivors()
{
	int aliveCount;
	int survivorCount;
	int iTeamSize = (FindConVar("survivor_limit")).IntValue;
	for (int i = 1; i <= MaxClients && survivorCount < iTeamSize; i++)
	{
		if (IsSurvivor(i))
		{
			survivorCount++;
			if (IsPlayerAlive(i) && !IsIncapacitated(i) && !IsHangingFromLedge(i))
			{    // IsIncapacitated, IsHangingFromLedge - l4d2util
				aliveCount++;
			}
		}
	}

	return aliveCount;
}

bool IsTankActuallyInPlay()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsTank(i) && IsPlayerAlive(i))
		{
			return true;
		}
	}

	return false;
}