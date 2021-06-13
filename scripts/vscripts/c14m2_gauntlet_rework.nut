Msg("Beginning Lighthouse Scavenge Base Rework.\n")

DirectorOptions <-
{
	CommonLimit = 20
	MobSpawnMinTime = 10
	MobSpawnMaxTime = 10
	MobSpawnSize = 6
	MobMaxPending = 15
	IntensityRelaxThreshold = 0.99
	RelaxMinInterval = 1
	RelaxMaxInterval = 1
	RelaxMaxFlowTravel = 1
	SpecialRespawnInterval = 30
	LockTempo = true
	PreferredMobDirection = SPAWN_ANYWHERE
	PanicForever = true
}

if ( Director.GetGameModeBase() == "versus" )
{
	DirectorOptions.MobSpawnSize = 4;
	//Rework
	DirectorOptions.CommonLimit = 15;
	DirectorOptions.MobSpawnMinTime = 12;
	DirectorOptions.MobSpawnMaxTime = 12;
}

Director.ResetMobTimer();