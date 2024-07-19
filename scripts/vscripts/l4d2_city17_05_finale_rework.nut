//-----------------------------------------------------
//
//-----------------------------------------------------
Msg("Initiating l4d2_city17_05 finale rework script\n");

//-----------------------------------------------------
PANIC <- 0
TANK <- 1
DELAY <- 2

DirectorOptions <-
{
	//-----------------------------------------------------

	 A_CustomFinale_StageCount = 6
	 
	 A_CustomFinale1 = PANIC
	 A_CustomFinaleValue1 = 2
	 
	 A_CustomFinale2 = DELAY
	 A_CustomFinaleValue2 = 12
	 
	 A_CustomFinale3 = TANK
	 A_CustomFinaleValue3 = 1
	 
	 A_CustomFinale4 = DELAY
	 A_CustomFinaleValue4 = 15

	 A_CustomFinale5 = PANIC
	 A_CustomFinaleValue5 = 1
	 
	 A_CustomFinale6 = DELAY
	 A_CustomFinaleValue6 = 10
	 
	//-----------------------------------------------------
	
	CommonLimit = 30
	SpecialRespawnInterval = 20
    ZombieSpawnRange = 1500
    PreferredMobDirection = SPAWN_ANYWHERE
    HordeEscapeCommonLimit = 30

}


