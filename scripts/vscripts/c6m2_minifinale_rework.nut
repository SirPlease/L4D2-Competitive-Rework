Msg("Initiating Onslaught\n");

DirectorOptions <-
{
	//-----------------------------------------------------
	// Mob timers and sizes, and the max queue for zombies
	// beyond z_common_limit.
	//-----------------------------------------------------
	MobSpawnMinTime = 5  // 2
	MobSpawnMaxTime = 5  // 4
	MobMinSize = 14      // 25
	MobMaxSize = 14      // 25
	MobMaxPending = 15   // 15
	
	CommonLimit = 25
	

	//-----------------------------------------------------
	// Relax and Sustain Time
	// Influences the Tempo.
	//-----------------------------------------------------
	SustainPeakMinTime = 1
	SustainPeakMaxTime = 3
	IntensityRelaxThreshold = 1.0
	RelaxMinInterval = 5
	RelaxMaxInterval = 5


	//-----------------------------------------------------
	// Preferred Mob Direction, direction of the mob spawns.
	// And spawn range!
	//-----------------------------------------------------
	PreferredMobDirection = SPAWN_IN_FRONT_OF_SURVIVORS // 7

	ZombieSpawnRange = 3000

}

Director.ResetMobTimer()

