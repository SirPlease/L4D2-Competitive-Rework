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