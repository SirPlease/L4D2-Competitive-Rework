Msg("Initiating DTA Finale Rework\n");

function StartGauntletRework()
{
	Msg("Gauntlet Started\n");
	DirectorOptions <-
	{
		ProhibitBosses = true
		MobMaxPending = 15
		PreferredMobDirection = SPAWN_IN_FRONT_OF_SURVIVORS
		
		PanicForever = true
		PausePanicWhenRelaxing = true

		IntensityRelaxThreshold = 0.99
		RelaxMinInterval = 25
		RelaxMaxInterval = 35
		RelaxMaxFlowTravel = 400

		LockTempo = 0
		SpecialRespawnInterval = 20
		PreTankMobMax = 30
		ZombieSpawnRange = 3000
		ZombieSpawnInFog = true

		MobSpawnSize = 15
		CommonLimit = 20

		GauntletMovementThreshold = 500.0
		GauntletMovementTimerLength = 5.0
		GauntletMovementBonus = 2.0
		GauntletMovementBonusMax = 30.0
		
		// Set common limit recalculation values such that it will not change the limits base on speed
		BridgeSpan = 7500

		MobSpawnMinTime = 5
		MobSpawnMaxTime = 5

		MobSpawnSizeMin = 15
		MobSpawnSizeMax = 15

		minSpeed = 9999
		maxSpeed = 99999

		speedPenaltyZAdds = 0

		CommonLimitMax = 20
	}
}

StartGauntletRework()