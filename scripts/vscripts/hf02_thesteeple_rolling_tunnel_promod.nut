// Used to lower the horde on the final event on map 2 of Haunted Forest
DirectorOptions <-
{
	// This turns off tanks and witches.
	ProhibitBosses = true

	PreferredMobDirection = SPAWN_IN_FRONT_OF_SURVIVORS
	MobSpawnMinTime = 4
	MobSpawnMaxTime = 4
	MobMaxPending = 12
	MobMinSize = 12
	MobMaxSize = 12
	MobSpawnSize = 12
	SustainPeakMinTime = 2
	SustainPeakMaxTime = 2
	IntensityRelaxThreshold = 0.90
	RelaxMinInterval = 3
	RelaxMaxInterval = 3
	RelaxMaxFlowTravel = 200
	CommonLimit = 16
}

Director.ResetMobTimer()
Director.PlayMegaMobWarningSounds()