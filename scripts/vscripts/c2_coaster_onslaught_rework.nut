Msg("Initiating Onslaught\n");

DirectorOptions <-
{
	//-----------------------------------------------------
	// Mob timers and sizes, and the max queue for zombies
	// beyond z_common_limit.
	//-----------------------------------------------------
	MobSpawnMinTime = 2  // 1
	MobSpawnMaxTime = 2  // 1
	MobMinSize = 6       // 5
	MobMaxSize = 6       // 8
	MobMaxPending = 30   // 30
	
	
	//-----------------------------------------------------
	// Relax and Sustain Time
	// Influences the Tempo.
	//-----------------------------------------------------
	SustainPeakMinTime = 5
	SustainPeakMaxTime = 10
	IntensityRelaxThreshold = 0.99
	RelaxMinInterval = 5
	RelaxMaxInterval = 15
	RelaxMaxFlowTravel = 200


	//-----------------------------------------------------
	// Preferred Mob Direction, direction of the mob spawns.
	// And spawn range!
	//-----------------------------------------------------
	PreferredMobDirection = SPAWN_ABOVE_SURVIVORS
	ZombieSpawnRange = 1000
}

Director.PlayMegaMobWarningSounds()
Director.ResetMobTimer()

