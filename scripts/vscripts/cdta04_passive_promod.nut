Msg("DA4 Ambient\n");

DirectorOptions <-
{
	AlwaysAllowWanderers = true
	MobSpawnMinTime = 3500
	MobSpawnMaxTime = 3500
	MobMinSize = 10
	MobMaxSize = 35
	MobMaxPending = 30
	SustainPeakMinTime = 5
	SustainPeakMaxTime = 8
	IntensityRelaxThreshold = 0.6
	RelaxMinInterval = 31
	RelaxMaxInterval = 40
	RelaxMaxFlowTravel = 1400
	SmokerLimit = 2
	HunterLimit = 2
	ChargerLimit = 1
	SpecialRespawnInterval = 30.0
	ZombieSpawnRange = 2600
	NumReservedWanderers = 10
	ZombieSpawnInFog = true
	MaxSpecials = 3
}

Director.ResetMobTimer()