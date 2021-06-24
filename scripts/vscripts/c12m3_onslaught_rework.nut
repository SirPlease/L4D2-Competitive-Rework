Msg("Initiating Onslaught Rework\n");

DirectorOptions <-
{
	// This turns off tanks and witches.
	ProhibitBosses = true

	PreferredMobDirection = SPAWN_IN_FRONT_OF_SURVIVORS
	MobSpawnMinTime = 5
	MobSpawnMaxTime = 8
	MobMaxPending = 15
	MobMinSize = 10
	MobMaxSize = 10
	SustainPeakMinTime = 1
	SustainPeakMaxTime = 3
	IntensityRelaxThreshold = 0.99
	RelaxMinInterval = 5
	RelaxMaxInterval = 5
	RelaxMaxFlowTravel = 200
	
	CommonLimit = 20
}

Director.ResetMobTimer()
Director.PlayMegaMobWarningSounds()

