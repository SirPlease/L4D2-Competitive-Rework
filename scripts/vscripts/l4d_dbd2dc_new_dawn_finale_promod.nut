DirectorOptions <-
{
	ProhibitBosses = true
	PreferredMobDirection = SPAWN_IN_FRONT_OF_SURVIVORS
	MobMaxPending = 20
	MobMinSize = 20
	MobMaxSize = 20
	SustainPeakMinTime = 1
	SustainPeakMaxTime = 3

	PanicForever = true
	PausePanicWhenRelaxing = false

	IntensityRelaxThreshold = 0.90
	RelaxMinInterval = 3
	RelaxMaxInterval = 3
	RelaxMaxFlowTravel = 200

	LockTempo = 0
	SpecialRespawnInterval = 20
	PreTankMobMax = 20
	ZombieSpawnRange = 2000
	ZombieSpawnInFog = true

	MobSpawnSize = 20
	CommonLimit = 20

	// length of bridge to test progress against.
	BridgeSpan = 10000

	MobSpawnMinTime = 3
	MobSpawnMaxTime = 3

	MobSpawnSizeMin = 20
	MobSpawnSizeMax = 20
}

Director.ResetMobTimer();