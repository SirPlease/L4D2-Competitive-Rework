#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>

bool 
	bTankAlive,
	bHooked;

int 
	iDistance;

ConVar 
	cvar_noTankRush,
	cvar_SpawnEnableSound,
	cvar_unfreezeSaferoom;

public Plugin myinfo =
{
	name = "L4D2 No Tank Rush",
	author = "Jahze, vintik, devilesk, Sir", //little fix A1m`
	version = "1.1.4",
	description = "Stops distance points accumulating whilst the tank is alive, with the option of unfreezing distance on reaching the Saferoom"
};

public void OnPluginStart()
{
	// ConVars
	cvar_noTankRush = CreateConVar("l4d_no_tank_rush", "1", "Prevents survivor team from accumulating points whilst the tank is alive", _, true, 0.0, true, 1.0);
	cvar_unfreezeSaferoom = CreateConVar("l4d_no_tank_rush_unfreeze_saferoom", "0", "Unfreezes Distance if a Survivor makes it to the end saferoom while the Tank is still up.", _, true, 0.0, true, 1.0);
	cvar_SpawnEnableSound = CreateConVar("l4d_no_tank_rush_spawn_sound", "0", "Turn on the sound when spawning a tank", _, true, 0.0, true, 1.0);
	
	// ChangeHook
	cvar_noTankRush.AddChangeHook(NoTankRushChange);

	if (cvar_noTankRush.BoolValue) {
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
	if (!bHooked) {
		HookEvent("round_start", view_as<EventHook>(RoundStart), EventHookMode_PostNoCopy); //no params pls
		HookEvent("tank_spawn", view_as<EventHook>(TankSpawn), EventHookMode_PostNoCopy); //no params pls
		HookEvent("player_death", PlayerDeath, EventHookMode_Post);
		
		if (IsTankActuallyInPlay()) {
			FreezePoints();
		}
		bHooked = true;
	}
}

public Action L4D2_OnEndVersusModeRound(bool countSurvivors)
{
	if (cvar_unfreezeSaferoom.IntValue == 1 && IsTankActuallyInPlay() && GetUprightSurvivors() > 0) {
		UnFreezePoints(true, 2);
	}
}

void PluginDisable()
{
	if (bHooked) {
		UnhookEvent("round_start", view_as<EventHook>(RoundStart), EventHookMode_PostNoCopy); //no params pls
		UnhookEvent("tank_spawn", view_as<EventHook>(TankSpawn), EventHookMode_PostNoCopy); //no params pls
		UnhookEvent("player_death", PlayerDeath, EventHookMode_Post);
		
		bHooked = false;
	}

	UnFreezePoints();
}

void NoTankRushChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 0) {
		PluginDisable();
	} else {
		PluginEnable();
	}
}

public void RoundStart()
{
	if (InSecondHalfOfRound()) {
		UnFreezePoints();
	}
}

public void TankSpawn()
{
	FreezePoints(true);
}

public void PlayerDeath(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (client > 0 && IsTank(client)) {
		CreateTimer(0.1, CheckForTanksDelay, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnClientDisconnect(int client)
{
	if (IsTank(client)) {
		CreateTimer(0.1, CheckForTanksDelay, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action CheckForTanksDelay(Handle timer)
{
	if (!IsTankActuallyInPlay()) {
		UnFreezePoints(true);
	}
}

void FreezePoints(bool show_message = false)
{
	if (!bTankAlive) {
		iDistance = L4D_GetVersusMaxCompletionScore();
		if (show_message) {
			CPrintToChatAll("{red}[{default}NoTankRush{red}] {red}Tank {default}spawned. {olive}Freezing {default}distance points!");
			if (cvar_SpawnEnableSound.BoolValue) {
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
			if (iMessage == 1) {
				CPrintToChatAll("{red}[{default}NoTankRush{red}] {red}Tank {default}is dead. {olive}Unfreezing {default}distance points!");
			} else {
				CPrintToChatAll("{red}[{default}NoTankRush{red}] {red}Survivors {default}made it to the saferoom. {olive}Unfreezing {default}distance points!");
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
	for (int i = 1; i <= MaxClients && survivorCount < iTeamSize; i++) {
		if (IsSurvivor(i)) {
			survivorCount++;
			if (IsPlayerAlive(i) && !IsIncapacitated(i) && !IsHangingFromLedge(i)) { //IsIncapacitated, IsHangingFromLedge - l4d2util 
				aliveCount++;
			}
		}
	}

	return aliveCount;
}

bool IsTankActuallyInPlay()
{
	int tank = FindTankClient(0);

	return tank != -1 && IsPlayerAlive(tank);
}