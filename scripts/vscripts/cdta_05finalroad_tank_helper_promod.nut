// Used to fix Detour Ahead's Gauntlet Finale.
// Refer to the corresponding stripper file.

// For Detour Ahead, we consider a Y coord higher than -5031 to be "pushing the tank".
// Its the first cluster of cars past the bridge.
target_y <- -5031

survivors <-{
   coach = "models/survivors/survivor_coach.mdl",
   ellis = "models/survivors/survivor_mechanic.mdl",
   nick = "models/survivors/survivor_gambler.mdl",
   rochelle = "models/survivors/survivor_producer.mdl"
}

function FindFurthestSurvivorY()
{
	// Initial value is some value lower than target_y
	furthest_y <- target_y - 100

	foreach(s, m in survivors)
	{
		survivor <- Entities.FindByModel(null, m);
		if (survivor)
		{
			pos <- survivor.GetOrigin();
			if (pos.y > furthest_y)
			{
				furthest_y = pos.y
			}
		}
	}
	
	return furthest_y;
}

function StartGauntlet()
{
	DirectorOptions <-
	{
		ProhibitBosses = true
		PreferredMobDirection = SPAWN_IN_FRONT_OF_SURVIVORS
		MobMaxPending = 20
		MobMinSize = 20
		MobMaxSize = 20
		MobRechargeRate = 0.003
		SustainPeakMinTime = 3
		SustainPeakMaxTime = 3

		PanicForever = true
		PausePanicWhenRelaxing = false

		IntensityRelaxThreshold = 0.90
		RelaxMinInterval = 2
		RelaxMaxInterval = 2
		RelaxMaxFlowTravel = 200

		LockTempo = 0
		SpecialRespawnInterval = 20
		PreTankMobMax = 20
		ZombieSpawnRange = 3000
		ZombieSpawnInFog = true

		MobSpawnSize = 20
		CommonLimit = 20

		// length of bridge to test progress against.
		BridgeSpan = 10000

		MobSpawnMinTime = 2
		MobSpawnMaxTime = 2

		MobSpawnSizeMin = 20
		MobSpawnSizeMax = 20
	}

	Director.ResetMobTimer();
}

function StopGauntlet()
{
	DirectorOptions <-
	{
		CommonLimit = 0
	}
}

if (Director.IsTankInPlay())
{
	if (FindFurthestSurvivorY() > target_y)
	{
		StartGauntlet();
	}
	else
	{
		StopGauntlet();
	}
}
else
{
	StartGauntlet();
	
	// There is assumed to be a generic_ambient entity named 'tank_music'
	// that was started when this script was initially kicked off.
	// Kill the music now.
	EntFire( "tank_music", "StopSound", 0 );
	
	
	if (FindFurthestSurvivorY() > target_y) 
	{
		// Kill the timer that keeps firing this script.
		EntFire( "tank_spawned_timer", "Disable", 0 );
	}
}
