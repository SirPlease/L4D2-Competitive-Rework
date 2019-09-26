// Used to lower horde and allow tanks during the event on
// Map 2 of The Bloody Moors

DirectorOptions <-
{
	ProhibitBosses = false
	MobSpawnMinTime = 5
	MobSpawnMaxTime = 5
	MobMinSize = 20
	MobMaxSize = 20
	MobMaxPending = 20
	SustainPeakMinTime = 7
	SustainPeakMaxTime = 7
	IntensityRelaxThreshold = 0.99
	RelaxMinInterval = 3
	RelaxMaxInterval = 3
	RelaxMaxFlowTravel = 100
	PreferredMobDirection = SPAWN_BEHIND_SURVIVORS
	ZombieSpawnRange = 2000
}

Director.ResetMobTimer()
Director.PlayMegaMobWarningSounds()