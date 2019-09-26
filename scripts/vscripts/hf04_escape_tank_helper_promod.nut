// Used to ensure Haunted Forest finale tank spawn is consistent between teams
// Refer to the corresponding stripper file.

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
			// "-217.643219 2641.622803 -801.968750"
			pos.x = -217.643219;
			pos.y = 2641.622803;
			pos.z = -801.968750;
			tank.SetOrigin(pos);
			
			// Kill the timer that keeps running this script
			EntFire( "tank_spawned_timer", "Disable", 0 );
			
			// Start the timer that monitors whether the tank is in play or not
			// and resets the commonlimit once the tank dies
			EntFire( "tank_spawned_timer_2", "Enable", 0 );
		}
	}
}

TeleTank();