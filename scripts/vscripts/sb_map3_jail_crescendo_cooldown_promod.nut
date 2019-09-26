Msg("Resuming Normal Map3 Script\n");

local SPAWN_ANYWHERE = 0 

DirectorOptions <-
{
    MobSpawnMinTime = 3500
    MobSpawnMaxTime = 3500
    MobMinSize = 20
    MobMaxSize = 30
    MobMaxPending = 25
    SustainPeakMinTime = 5
    SustainPeakMaxTime = 8
    IntensityRelaxThreshold = 0.9
    RelaxMinInterval = 20
    RelaxMaxInterval = 45
    RelaxMaxFlowTravel = 1500
    TankLimit = 1
    WitchLimit = 1
    
    JockeyLimit = 1
    BoomerLimit = 1
    SpecialRespawnInterval = 30.0
    
    NumReservedWanderers = 5
    PreferredMobDirection = SPAWN_ANYWHERE

    FallenSurvivorPotentialQuantity = 6
        FallenSurvivorSpawnChance       = 0.75
}

Director.ResetMobTimer()