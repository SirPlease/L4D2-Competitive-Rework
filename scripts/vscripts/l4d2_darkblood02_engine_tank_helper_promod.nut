// Dark Blood 2 - Map 2
//
// - This is linked to a timer in the corresponding stripper file
// - If a tank spawns before the survivors start the elevator event, this
//   script will disable the timer that is used later on to teleport the tank to a 
//   reasonable distance away from the survivors.

tanks <-{
	tank1 = "models/infected/hulk.mdl",
    tank2 = "models/infected/hulk_dlc3.mdl"
}

function DetectEarlyTank()
{
	foreach (t, m in tanks)
	{
		tank <- Entities.FindByModel(null, m);
		if (tank)
		{
			// A tank has spawned.  Kill the next timer
			EntFire( "late_tank_monitor", "Kill", 0 );

			// Kill this scripts corresponding timer as well
			EntFire( "early_tank_monitor", "Kill", 0 );
		}
	}
}

DetectEarlyTank();