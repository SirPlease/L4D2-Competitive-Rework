// Used to fix Carried Off's Gauntlet Finale.
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
			// "284.567841 668.269165 1406.031250"
			// -172.901581 515.258118 1406.031250;
			pos.x = -172.901581;
			pos.y = 515.258118;
			pos.z = 1406.031250;
			tank.SetOrigin(pos);
			
			// Kill the timer that keeps running this script
			EntFire( "tank_spawned_timer", "Disable", 0 );
		}
	}
}

TeleTank();