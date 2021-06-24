Msg("Initiating DTA Finale Rework Tank Helper\n");

// Credit: ProMod

// Used to fix Detour Ahead's Gauntlet Finale.
// Refer to the corresponding stripper file.

// For Detour Ahead, we consider a Y coord higher than -6900 (just before the bridge) to be "pushing the tank".
target_y <- -6900

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

function StartGauntletRework()
{
	Msg("Tank Helper Gauntlet Started\n");
	DirectorOptions <-
	{
		ProhibitBosses = true
		MobMaxPending = 15
		PreferredMobDirection = SPAWN_IN_FRONT_OF_SURVIVORS
		
		PanicForever = true
		PausePanicWhenRelaxing = true

		IntensityRelaxThreshold = 0.99
		RelaxMinInterval = 25
		RelaxMaxInterval = 35
		RelaxMaxFlowTravel = 400

		LockTempo = 0
		SpecialRespawnInterval = 20
		PreTankMobMax = 30
		ZombieSpawnRange = 3000
		ZombieSpawnInFog = true

		MobSpawnSize = 15
		CommonLimit = 20

		GauntletMovementThreshold = 500.0
		GauntletMovementTimerLength = 5.0
		GauntletMovementBonus = 2.0
		GauntletMovementBonusMax = 30.0
		
		// Set common limit recalculation values such that it will not change the limits base on speed
		BridgeSpan = 7500

		MobSpawnMinTime = 5
		MobSpawnMaxTime = 5

		MobSpawnSizeMin = 15
		MobSpawnSizeMax = 15

		minSpeed = 9999
		maxSpeed = 99999

		speedPenaltyZAdds = 0

		CommonLimitMax = 20
	}
}

function StopGauntletRework()
{
	Msg("Tank Helper Gauntlet Stopped\n");
	DirectorOptions <-
	{
		CommonLimit = 0
	}
}

if (Director.IsTankInPlay())
{
	if (FindFurthestSurvivorY() > target_y)
	{
		StartGauntletRework();
	}
	else
	{
		StopGauntletRework();
	}
}
else
{
	StartGauntletRework();
	
	if (FindFurthestSurvivorY() > target_y) 
	{
		// Kill the timer that keeps firing this script.
		EntFire( "tank_spawned_timer", "Disable", 0 );
	}
}