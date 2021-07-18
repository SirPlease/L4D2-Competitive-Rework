Msg("Initiating Onslaught Rework c10m4\n");

DirectorOptions <-
{
	// This turns off tanks and witches.
	ProhibitBosses = true

	PreferredMobDirection = SPAWN_IN_FRONT_OF_SURVIVORS
	MobSpawnMinTime = 3
	MobSpawnMaxTime = 5
	MobMaxPending = 30
	MobMinSize = 15
	MobMaxSize = 25
	SustainPeakMinTime = 1
	SustainPeakMaxTime = 3
	IntensityRelaxThreshold = 0.90
	RelaxMinInterval = 1
	RelaxMaxInterval = 5
	RelaxMaxFlowTravel = 200
	
	CommonLimit = 25
}

Director.ResetMobTimer()
Director.PlayMegaMobWarningSounds()

// Variables
local g_TankFirstSpawned = false

// Control the horde when tank is alive
// Bug: tank_spawn fires every time the tank switches control, it starts under AI control then switches to a player
function OnGameEvent_tank_spawn(params)
{
	if (g_TankFirstSpawned == false)
	{
		TankHordeParams()
		g_TankFirstSpawned = true
		
		if (developer() > 0)
		{
			Msg("Tank Spawned\n")
		}
	}
}

// Handle player tank deaths
// Bug: tank_killed only fires when an AI tank is killed
/*function OnGameEvent_tank_killed(params)
{
	if (g_TankFirstSpawned == true)
	{
		ResetHordeParams()
		
		if (developer() > 0)
		{
			Msg("Tank Killed Bot\n")
		}
	}
}*/

// Handle tank deaths
function OnGameEvent_player_death(params)
{
	if (g_TankFirstSpawned == true)
	{
		// Only check for tank deaths
		if (params.victimname == "Tank")
		{
			ResetHordeParams()
			
			if (developer() > 0)
			{
				Msg("Tank Killed\n")
			}
		}
	}
}

// Handle tanks being kicked
// Bug: This fires when the AI that started out controlling the tank passes control to players and "disconnects"
function OnGameEvent_player_team(params)
{
	if (g_TankFirstSpawned == true)
	{
		// Only check if the tank is no longer in play, luckily this is updated before player_team is called
		if (Director.IsTankInPlay() == false)
		{
			// Player is a disconnecting bot tank
			if (params.team == 0 && params.disconnect && params.isbot && GetPlayerFromUserID(params.userid).GetZombieType() == 8)
			{
				ResetHordeParams()
				
				if (developer() > 0)
				{
					Msg("Tank Disconnected\n")
					ClientPrint(null, 3, "\x05Tank was kicked")
				}
			}
		}
	}
}

function TankHordeParams()
{
	DirectorOptions.MobSpawnMinTime = 10
	DirectorOptions.MobSpawnMaxTime = 10
	DirectorOptions.MobMinSize = 10
	DirectorOptions.MobMaxSize = 10
	Director.ResetMobTimer()
	ClientPrint(null, 3, "\x05Relaxing horde...")
	
	// Measure survivor flow travel to determine when hordes are triggered
	EntFire("OnslaughtFlowChecker", "Enable")
	EntFire("OnslaughtFlowChecker", "FireUser1")
}

function ResetHordeParams()
{
	DirectorOptions.MobSpawnMinTime = 3
	DirectorOptions.MobSpawnMaxTime = 5
	DirectorOptions.MobMinSize = 15
	DirectorOptions.MobMaxSize = 25
	Director.ResetMobTimer()
	ClientPrint(null, 3, "\x05Ramping up the horde!")
	
	// Stop measuring flow
	EntFire("OnslaughtFlowChecker", "FireUser2")
	EntFire("OnslaughtFlowChecker", "Disable")
	g_TankFirstSpawned = false
}

__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener)
