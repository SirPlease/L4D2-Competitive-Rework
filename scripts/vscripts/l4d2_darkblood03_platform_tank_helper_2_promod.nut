// Dark Blood 2 - Map 3
//
// - This is linked to a timer in the corresponding stripper file
// - If a tank spawns after the survivors start the event, this
//   script will teleport the tank to a 
//   reasonable distance away from the survivors.

tanks <-{
	tank1 = "models/infected/hulk.mdl",
    tank2 = "models/infected/hulk_dlc3.mdl"
}

function TeleTank()
{

	foreach (t, m in tanks)
	{
		tank <- Entities.FindByModel(null, m);
		if (tank)
		{
			pos <- tank.GetOrigin();
			
			// Coordinates to where we want to teleport the tank
			pos.x = -346.000000;
			pos.y = 586.000000;
			pos.z = 1006.000000;
			tank.SetOrigin(pos);
			
			// Kill the timer that keeps running this script
			EntFire( "late_tank_monitor", "Disable", 0 );
		}
	}
}

TeleTank();