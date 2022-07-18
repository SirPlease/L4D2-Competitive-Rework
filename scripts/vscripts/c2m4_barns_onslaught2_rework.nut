Msg("Initiating Onslaught\n");

DirectorOptions <-
{
	//-----------------------------------------------------
	// Mob timers and sizes, and the max queue for zombies
	// beyond z_common_limit.
	//-----------------------------------------------------
	MobSpawnMinTime = 6  // 3
	MobSpawnMaxTime = 6  // 7
	MobMinSize = 18      // 25
	MobMaxSize = 18      // 25
	MobMaxPending = 30   // 30

	CommonLimit = 25


	//-----------------------------------------------------
	// Relax and Sustain Time
	// Influences the Tempo.
	//-----------------------------------------------------
	SustainPeakMinTime = 5
	SustainPeakMaxTime = 10
	IntensityRelaxThreshold = 0.99
	RelaxMinInterval = 1
	RelaxMaxInterval = 5
	RelaxMaxFlowTravel = 50
	
	
	//-----------------------------------------------------
	// Preferred Mob Direction, direction of the mob spawns.
	// And spawn range!
	//-----------------------------------------------------
	PreferredMobDirection = SPAWN_IN_FRONT_OF_SURVIVORS
	ZombieSpawnRange = 2000
}

Director.ResetMobTimer()

