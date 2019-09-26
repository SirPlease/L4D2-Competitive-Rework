// Used to replace the custom mini-finale horde in map 3 of Diescraper
DirectorOptions <-
{
	ProhibitBosses = false
	PreferredMobDirection = SPAWN_ABOVE_SURVIVORS
	MobSpawnMinTime = 6
	MobSpawnMaxTime = 12
	MobMinSize = 12
	MobMaxSize = 17
	MobMaxPending = 20
	SustainPeakMinTime = 5
	SustainPeakMaxTime = 10
	IntensityRelaxThreshold = 0.99
	RelaxMinInterval = 1
	RelaxMaxInterval = 5
	RelaxMaxFlowTravel = 50
	SpecialRespawnInterval = 30
	ZombieSpawnRange = 1500
}

Director.ResetMobTimer()
Director.PlayMegaMobWarningSounds()