Msg("Initiating Onslaught\n");

DirectorOptions <-
{
	// This turns off tanks and witches.
	ProhibitBosses = true

	MobSpawnMinTime = 8
	MobSpawnMaxTime = 8
	MobMinSize = 20
	MobMaxSize = 30
	SustainPeakMinTime = 1
	SustainPeakMaxTime = 3
	IntensityRelaxThreshold = 0.90
	RelaxMinInterval = 5
	RelaxMaxInterval = 5
	RelaxMaxFlowTravel = 600
	
	// Limit max horde in queue
	MobMaxPending = 30
}

Director.ResetMobTimer()

// Control the horde when tank is alive
function OnGameEvent_tank_spawn(params)
{
	Msg("Tank Spawned\n");
	TankHordeParams()
}

function OnGameEvent_tank_killed(params)
{
	Msg("Tank Killed\n");
	ResetHordeParams()
}

function OnGameEvent_player_team(params)
{
	// Player is a disconnecting bot tank
	if (params.disconnect && params.isbot && GetPlayerFromUserID(params.userid).GetZombieType() == 8)
	{
		Msg("Tank Disconnected\n");
		ResetHordeParams()
	}
}

function TankHordeParams()
{
	DirectorOptions.MobSpawnMinTime = 20
	DirectorOptions.MobSpawnMaxTime = 20
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
	DirectorOptions.MobSpawnMinTime = 8
	DirectorOptions.MobSpawnMaxTime = 8
	DirectorOptions.MobMinSize = 20
	DirectorOptions.MobMaxSize = 30
	Director.ResetMobTimer()
	ClientPrint(null, 3, "\x05Ramping up the horde!")
	
	// Stop measuring flow
	EntFire("OnslaughtFlowChecker", "Kill")
}

__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener)
