Msg("Initiating Onslaught\n");

DirectorOptions <-
{
	// This turns off tanks and witches.
	ProhibitBosses = true

	PreferredMobDirection = SPAWN_BEHIND_SURVIVORS
	MobSpawnMinTime = 3
	MobSpawnMaxTime = 4
	MobMaxPending = 10
	MobMinSize = 10
	MobMaxSize = 20
	SustainPeakMinTime = 1
	SustainPeakMaxTime = 3
	IntensityRelaxThreshold = 0.90
	RelaxMinInterval = 5
	RelaxMaxInterval = 10
	RelaxMaxFlowTravel = 200

}

Director.ResetMobTimer()
Director.PlayMegaMobWarningSounds()
